// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: miXSR_FC_image_aware_coherence-1
// Capability: Live image-aware coherence denoiser using temporal accumulation, edge-aware spatial filtering, and detector-driven handling for legacy stipple/hatch transparency patterns.

#include "ReShade.fxh"
#include "miXSR_FC_PostHarmonize.fxh"
#include "miXSR_FC_ShaderSharedMaskControls.fxh"

#define FIAC_EPS 0.000010

texture2D FIAC_HistoryTex
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

texture2D FIAC_OutputTex
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

sampler2D FIAC_HistorySampler
{
    Texture = FIAC_HistoryTex;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = NONE;
};

sampler2D FIAC_OutputSampler
{
    Texture = FIAC_OutputTex;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = NONE;
};

uniform int FIAC_DebugView <
    ui_type = "combo";
 ui_label = "Debug View";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 00 Debug"; ui_category_closed = true;
    ui_items = "Final\0Denoise Mask\0Pattern Mask\0Reflective Dot Mask\0Stipple Mask\0Hatch Mask\0History Weight\0Edge Guard\0Computed Mask\0";
 ui_tooltip = "Shows final output or denoiser diagnostics, including legacy transparency pattern detection.";
> = 0;

uniform int FIAC_PresetTier <
    ui_type = "combo";
 ui_label = "Preset Tier";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 02 Main Settings";
    ui_items = "Performance\0Balanced\0Quality\0";
 ui_tooltip = "Performance favors speed, Balanced is default, Quality increases denoise stability and reconstruction strength.";
> = 2;

uniform float FIAC_MasterIntensity <
    ui_type = "slider";
 ui_label = "Master Intensity";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 02 Main Settings";
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.001;
 ui_tooltip = "Global denoise intensity multiplier.";
> = 1.271000;

uniform float FIAC_DenoiseStrength <
    ui_type = "slider";
 ui_label = "Denoise Strength";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 02 Main Settings";
    ui_min = 0.0; ui_max = 2.3; ui_step = 0.001;
 ui_tooltip = "How strongly filtered reconstruction replaces source noise.";
> = 1.522000;

uniform float FIAC_EdgePreserve <
    ui_type = "slider";
 ui_label = "Edge Preserve";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 02 Main Settings";
    ui_min = 0.0; ui_max = 1.15; ui_step = 0.001;
 ui_tooltip = "Protects high-contrast edges from over-smoothing.";
> = 0.900000;

uniform float FIAC_HistoryBlend <
    ui_type = "slider";
 ui_label = "History Blend";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.127; ui_step = 0.001;
 ui_tooltip = "Base temporal accumulation strength.";
> = 0.860000;

uniform float FIAC_HistoryClamp <
    ui_type = "slider";
 ui_label = "History Clamp";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 0.250; ui_step = 0.0001;
 ui_tooltip = "Neighborhood clamp radius used to suppress ghosting from stale history.";
> = 0.011400;

uniform float FIAC_DepthRejectStart <
    ui_type = "slider";
 ui_label = "Depth Reject Start";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0001; ui_max = 0.1000; ui_step = 0.0001;
 ui_tooltip = "Depth disagreement where history rejection begins.";
> = 0.002500;

uniform float FIAC_DepthRejectEnd <
    ui_type = "slider";
 ui_label = "Depth Reject End";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0002; ui_max = 0.2000; ui_step = 0.0001;
 ui_tooltip = "Depth disagreement where history is fully rejected.";
> = 0.018000;

uniform float FIAC_LumaRejectStart <
    ui_type = "slider";
 ui_label = "Luma Reject Start";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0001; ui_max = 0.2000; ui_step = 0.0001;
 ui_tooltip = "Luminance disagreement where history rejection begins.";
> = 0.006000;

uniform float FIAC_LumaRejectEnd <
    ui_type = "slider";
 ui_label = "Luma Reject End";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0002; ui_max = 0.5000; ui_step = 0.0001;
 ui_tooltip = "Luminance disagreement where history is fully rejected.";
> = 0.050000;

uniform float FIAC_SpatialLumaSigma <
    ui_type = "slider";
 ui_label = "Spatial Luma Sigma";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 2.0; ui_max = 128.0; ui_step = 0.1;
 ui_tooltip = "Luminance similarity strength for edge-aware spatial filtering.";
> = 30.000000;

uniform float FIAC_SpatialDepthSigma <
    ui_type = "slider";
 ui_label = "Spatial Depth Sigma";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 2.0; ui_max = 256.0; ui_step = 0.1;
 ui_tooltip = "Depth similarity strength for edge-aware spatial filtering.";
> = 88.000000;

uniform float FIAC_DetailRestore <
    ui_type = "slider";
 ui_label = "Detail Restore";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.15; ui_step = 0.001;
 ui_tooltip = "Restores controlled high-frequency detail after denoising.";
> = 0.767000;

uniform float FIAC_PatternSensitivity <
    ui_type = "slider";
 ui_label = "Pattern Sensitivity";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 4.6; ui_step = 0.001;
 ui_tooltip = "Sensitivity for legacy stipple/hatch transparency pattern detection.";
> = 3.520000;

uniform float FIAC_PatternThreshold <
    ui_type = "slider";
 ui_label = "Pattern Threshold";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Minimum detector confidence before pattern-aware handling activates.";
> = 0.260000;

uniform int FIAC_PatternMode <
    ui_type = "combo";
 ui_label = "Pattern Mode";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_items = "Preserve Pattern\0Soften Pattern\0";
 ui_tooltip = "Preserve reduces denoise over detected stipple/hatch patterns; Soften increases denoise to smooth them.";
> = 1;

uniform float FIAC_PatternInfluence <
    ui_type = "slider";
 ui_label = "Pattern Influence";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.15; ui_step = 0.001;
 ui_tooltip = "Strength of pattern-aware preservation or softening behavior.";
> = 0.868000;

uniform float FIAC_DotExpandRadiusPixels <
    ui_type = "slider";
 ui_label = "Dot Expand Radius";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.5; ui_max = 4.0; ui_step = 0.01;
 ui_tooltip = "Expands detected stipple/hatch regions outward before dot-pattern synthesis.";
> = 0.500000;

uniform float FIAC_DotCellPixels <
    ui_type = "slider";
 ui_label = "Dot Cell Pixels";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 1.0; ui_max = 8.0; ui_step = 0.01;
 ui_tooltip = "Cell size in pixels for synthesized legacy dot/checker transparency pattern.";
> = 4.690000;

uniform float FIAC_DotRadius <
    ui_type = "slider";
 ui_label = "Dot Radius";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.05; ui_max = 0.70; ui_step = 0.001;
 ui_tooltip = "Roundness/radius of synthesized dot pattern inside each cell.";
> = 0.320000;

uniform float FIAC_DotCheckerMix <
    ui_type = "slider";
 ui_label = "Dot Checker Mix";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Mix between round-dot and checker-style legacy transparency structure.";
> = 0.217000;

uniform float FIAC_PartialReflectiveStrength <
    ui_type = "slider";
 ui_label = "Partial Reflective Strength";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.15; ui_step = 0.001;
 ui_tooltip = "How strongly expanded pattern regions are treated as partially reflective during smoothing.";
> = 0.887000;

uniform float FIAC_ReflectiveSmoothBoost <
    ui_type = "slider";
 ui_label = "Reflective Smooth Boost";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.15; ui_step = 0.001;
 ui_tooltip = "Extra smoothing bias applied inside reflective-pattern regions.";
> = 0.916000;

uniform float FIAC_ReflectiveSheen <
    ui_type = "slider";
 ui_label = "Reflective Sheen";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Small highlight sheen used to mark pattern regions as partially reflective.";
> = 0.066000;

uniform int FIAC_RespectFog <
    ui_type = "combo";
 ui_label = "Respect Fog";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_items = "No\0Yes\0";
 ui_tooltip = "Bypasses denoising in fog-dominant regions.";
> = 1;

uniform int FIAC_RespectLight <
    ui_type = "combo";
 ui_label = "Respect Light";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_items = "No\0Yes\0";
 ui_tooltip = "Protects emissive pixels from denoise smoothing.";
> = 1;

uniform float FIAC_LightProtectStrength <
    ui_type = "slider";
 ui_label = "Light Protect Strength";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.15; ui_step = 0.001;
 ui_tooltip = "How strongly protected lights return toward source color.";
> = 0.900000;

uniform float FIAC_PostToneBalance <
    ui_type = "slider";
 ui_label = "Post Tone Balance";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Post harmonization tone-balance strength.";
> = 0.020000;

uniform float FIAC_PostSaturationGuard <
    ui_type = "slider";
 ui_label = "Post Saturation Guard";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Post harmonization saturation guard strength.";
> = 0.020000;

uniform float FIAC_PostClipGuard <
    ui_type = "slider";
 ui_label = "Post Clip Guard";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Post harmonization clipping guard strength.";
> = 0.015000;

uniform float FIAC_PostArtifactCleanup <
    ui_type = "slider";
 ui_label = "Post Artifact Cleanup";
 ui_category = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Post harmonization cleanup strength for minor fringe/leak artifacts.";
> = 0.015000;

float2 FIAC_Pixel() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
float3 FIAC_Source(float2 uv) { return tex2D(ReShade::BackBuffer, saturate(uv)).rgb; }
float FIAC_Depth(float2 uv) { return saturate(ReShade::GetLinearizedDepth(saturate(uv))); }
float FIAC_Luma(float3 c) { return dot(c, float3(0.2126, 0.7152, 0.0722)); }

float FIAC_EdgeMask(float2 uv, float3 center)
{
    float2 px = FIAC_Pixel();
    float lC = FIAC_Luma(center);
    float lR = FIAC_Luma(FIAC_Source(uv + float2(px.x, 0.0)));
    float lL = FIAC_Luma(FIAC_Source(uv - float2(px.x, 0.0)));
    float lU = FIAC_Luma(FIAC_Source(uv + float2(0.0, px.y)));
    float lD = FIAC_Luma(FIAC_Source(uv - float2(0.0, px.y)));
    float grad = abs(lR - lL) + abs(lU - lD);
    float start = lerp(0.014, 0.006, saturate(FIAC_EdgePreserve));
    return smoothstep(start, start * 4.0, grad);
}

float FIAC_StippleMask(float2 uv, float lC)
{
    float2 px = FIAC_Pixel();
    float lR = FIAC_Luma(FIAC_Source(uv + float2(px.x, 0.0)));
    float lL = FIAC_Luma(FIAC_Source(uv - float2(px.x, 0.0)));
    float lU = FIAC_Luma(FIAC_Source(uv + float2(0.0, px.y)));
    float lD = FIAC_Luma(FIAC_Source(uv - float2(0.0, px.y)));
    float lNE = FIAC_Luma(FIAC_Source(uv + float2(px.x, -px.y)));
    float lNW = FIAC_Luma(FIAC_Source(uv + float2(-px.x, -px.y)));
    float lSE = FIAC_Luma(FIAC_Source(uv + float2(px.x, px.y)));
    float lSW = FIAC_Luma(FIAC_Source(uv + float2(-px.x, px.y)));

    float altH = step(0.0, -(lC - lR) * (lC - lL));
    float altV = step(0.0, -(lC - lU) * (lC - lD));
    float altD1 = step(0.0, -(lC - lNE) * (lC - lSW));
    float altD2 = step(0.0, -(lC - lNW) * (lC - lSE));

    float hf = abs(lR - lL) + abs(lU - lD) + abs(lNE - lSW) + abs(lNW - lSE);
    float hfMask = saturate(hf * (2.5 + FIAC_PatternSensitivity * 1.5));
    return saturate((altH + altV + altD1 + altD2) * 0.25 * hfMask);
}

float FIAC_HatchMask(float2 uv, float lC)
{
    float2 px = FIAC_Pixel();
    float lR = FIAC_Luma(FIAC_Source(uv + float2(px.x, 0.0)));
    float lL = FIAC_Luma(FIAC_Source(uv - float2(px.x, 0.0)));
    float lU = FIAC_Luma(FIAC_Source(uv + float2(0.0, px.y)));
    float lD = FIAC_Luma(FIAC_Source(uv - float2(0.0, px.y)));
    float lNE = FIAC_Luma(FIAC_Source(uv + float2(px.x, -px.y)));
    float lNW = FIAC_Luma(FIAC_Source(uv + float2(-px.x, -px.y)));
    float lSE = FIAC_Luma(FIAC_Source(uv + float2(px.x, px.y)));
    float lSW = FIAC_Luma(FIAC_Source(uv + float2(-px.x, px.y)));

    float oscX = step(0.0, -(lR - lC) * (lC - lL)) * saturate((abs(lR - lC) + abs(lC - lL)) * 4.0);
    float oscY = step(0.0, -(lU - lC) * (lC - lD)) * saturate((abs(lU - lC) + abs(lC - lD)) * 4.0);
    float oscD1 = step(0.0, -(lNE - lC) * (lC - lSW)) * saturate((abs(lNE - lC) + abs(lC - lSW)) * 4.0);
    float oscD2 = step(0.0, -(lNW - lC) * (lC - lSE)) * saturate((abs(lNW - lC) + abs(lC - lSE)) * 4.0);

    float directional = max(max(oscX, oscY), max(oscD1, oscD2));
    float coherence = 1.0 - saturate(abs(oscX - oscY) + abs(oscD1 - oscD2));
    float hatch = directional * (0.65 + 0.35 * coherence);
    return saturate(hatch * (0.55 + FIAC_PatternSensitivity * 0.45));
}

float FIAC_PatternSeedAtUV(float2 uv)
{
    float3 c = FIAC_Source(uv);
    float l = FIAC_Luma(c);
    return max(FIAC_StippleMask(uv, l), FIAC_HatchMask(uv, l));
}

float FIAC_ExpandPatternMask(float2 uv, float seed)
{
    float2 px = FIAC_Pixel() * max(0.5, FIAC_DotExpandRadiusPixels);
    float p0 = seed;
    float p1 = FIAC_PatternSeedAtUV(uv + float2(px.x, 0.0));
    float p2 = FIAC_PatternSeedAtUV(uv - float2(px.x, 0.0));
    float p3 = FIAC_PatternSeedAtUV(uv + float2(0.0, px.y));
    float p4 = FIAC_PatternSeedAtUV(uv - float2(0.0, px.y));
    float p5 = FIAC_PatternSeedAtUV(uv + float2(px.x, px.y));
    float p6 = FIAC_PatternSeedAtUV(uv + float2(-px.x, px.y));
    float p7 = FIAC_PatternSeedAtUV(uv + float2(px.x, -px.y));
    float p8 = FIAC_PatternSeedAtUV(uv + float2(-px.x, -px.y));
    float ring1 = max(max(max(p1, p2), max(p3, p4)), max(max(p5, p6), max(p7, p8)));

    float2 px2 = px * 2.0;
    float q1 = FIAC_PatternSeedAtUV(uv + float2(px2.x, 0.0));
    float q2 = FIAC_PatternSeedAtUV(uv - float2(px2.x, 0.0));
    float q3 = FIAC_PatternSeedAtUV(uv + float2(0.0, px2.y));
    float q4 = FIAC_PatternSeedAtUV(uv - float2(0.0, px2.y));
    float ring2 = max(max(q1, q2), max(q3, q4)) * 0.75;

    return saturate(max(ring1, max(p0, ring2)));
}

float FIAC_DotLatticeMask(float2 uv)
{
    float cell = max(1.0, FIAC_DotCellPixels);
    float2 p = uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT) / cell;
    float2 local = frac(p) - 0.5;
    float dist = length(local);
    float dot = 1.0 - smoothstep(FIAC_DotRadius, FIAC_DotRadius + 0.18, dist);

    float sumFloor = floor(p.x) + floor(p.y);
    float parity = sumFloor - 2.0 * floor(sumFloor * 0.5);
    float checker = parity;

    return saturate(lerp(dot, checker, FIAC_DotCheckerMix));
}

float3 FIAC_ReflectivePatternSmooth(float2 uv, float3 baseColor, float3 spatial, float3 temporal, float patternReflectMask)
{
    float2 px = FIAC_Pixel();
    float3 sR = FIAC_Source(uv + float2(px.x, 0.0));
    float3 sL = FIAC_Source(uv - float2(px.x, 0.0));
    float3 sU = FIAC_Source(uv + float2(0.0, px.y));
    float3 sD = FIAC_Source(uv - float2(0.0, px.y));

    float3 localAvg = (baseColor + sR + sL + sU + sD) * 0.2;
    float3 smoothBase = lerp(spatial, temporal, 0.30 + 0.55 * FIAC_ReflectiveSmoothBoost);
    smoothBase = lerp(smoothBase, localAvg, 0.25 + 0.35 * FIAC_ReflectiveSmoothBoost);

    float lMax = max(FIAC_Luma(baseColor), max(max(FIAC_Luma(sR), FIAC_Luma(sL)), max(FIAC_Luma(sU), FIAC_Luma(sD))));
    float sheen = lMax * lMax * FIAC_ReflectiveSheen * patternReflectMask;
    float3 reflective = smoothBase + sheen.xxx * (0.65 + 0.35 * baseColor);

    return lerp(baseColor, reflective, saturate(patternReflectMask * FIAC_PartialReflectiveStrength));
}

float3 FIAC_SpatialFilter(float2 uv, float centerDepth, float centerLuma)
{
    float2 px = FIAC_Pixel();

    float3 c0 = FIAC_Source(uv);
    float3 cR1 = FIAC_Source(uv + float2(px.x, 0.0));
    float3 cL1 = FIAC_Source(uv - float2(px.x, 0.0));
    float3 cU1 = FIAC_Source(uv + float2(0.0, px.y));
    float3 cD1 = FIAC_Source(uv - float2(0.0, px.y));
    float3 cR2 = FIAC_Source(uv + float2(px.x * 2.0, 0.0));
    float3 cL2 = FIAC_Source(uv - float2(px.x * 2.0, 0.0));
    float3 cU2 = FIAC_Source(uv + float2(0.0, px.y * 2.0));
    float3 cD2 = FIAC_Source(uv - float2(0.0, px.y * 2.0));

    float d0 = centerDepth;
    float dR1 = FIAC_Depth(uv + float2(px.x, 0.0));
    float dL1 = FIAC_Depth(uv - float2(px.x, 0.0));
    float dU1 = FIAC_Depth(uv + float2(0.0, px.y));
    float dD1 = FIAC_Depth(uv - float2(0.0, px.y));
    float dR2 = FIAC_Depth(uv + float2(px.x * 2.0, 0.0));
    float dL2 = FIAC_Depth(uv - float2(px.x * 2.0, 0.0));
    float dU2 = FIAC_Depth(uv + float2(0.0, px.y * 2.0));
    float dD2 = FIAC_Depth(uv - float2(0.0, px.y * 2.0));

    float w0 = 1.0;

    float lR1 = FIAC_Luma(cR1);
    float lL1 = FIAC_Luma(cL1);
    float lU1 = FIAC_Luma(cU1);
    float lD1 = FIAC_Luma(cD1);
    float lR2 = FIAC_Luma(cR2);
    float lL2 = FIAC_Luma(cL2);
    float lU2 = FIAC_Luma(cU2);
    float lD2 = FIAC_Luma(cD2);

    float wR1 = exp(-abs(lR1 - centerLuma) * FIAC_SpatialLumaSigma) * exp(-abs(dR1 - d0) * FIAC_SpatialDepthSigma) * 0.90;
    float wL1 = exp(-abs(lL1 - centerLuma) * FIAC_SpatialLumaSigma) * exp(-abs(dL1 - d0) * FIAC_SpatialDepthSigma) * 0.90;
    float wU1 = exp(-abs(lU1 - centerLuma) * FIAC_SpatialLumaSigma) * exp(-abs(dU1 - d0) * FIAC_SpatialDepthSigma) * 0.90;
    float wD1 = exp(-abs(lD1 - centerLuma) * FIAC_SpatialLumaSigma) * exp(-abs(dD1 - d0) * FIAC_SpatialDepthSigma) * 0.90;
    float wR2 = exp(-abs(lR2 - centerLuma) * FIAC_SpatialLumaSigma) * exp(-abs(dR2 - d0) * FIAC_SpatialDepthSigma) * 0.55;
    float wL2 = exp(-abs(lL2 - centerLuma) * FIAC_SpatialLumaSigma) * exp(-abs(dL2 - d0) * FIAC_SpatialDepthSigma) * 0.55;
    float wU2 = exp(-abs(lU2 - centerLuma) * FIAC_SpatialLumaSigma) * exp(-abs(dU2 - d0) * FIAC_SpatialDepthSigma) * 0.55;
    float wD2 = exp(-abs(lD2 - centerLuma) * FIAC_SpatialLumaSigma) * exp(-abs(dD2 - d0) * FIAC_SpatialDepthSigma) * 0.55;

    float3 sum = c0 * w0 + cR1 * wR1 + cL1 * wL1 + cU1 * wU1 + cD1 * wD1 + cR2 * wR2 + cL2 * wL2 + cU2 * wU2 + cD2 * wD2;
    float wsum = w0 + wR1 + wL1 + wU1 + wD1 + wR2 + wL2 + wU2 + wD2;
    return sum / max(FIAC_EPS, wsum);
}

float4 FIAC_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 sourceColor = FIAC_Source(uv);
    float sourceLuma = FIAC_Luma(sourceColor);
    float sourceDepth = FIAC_Depth(uv);

    float tierScale = (FIAC_PresetTier == 0) ? 0.80 : ((FIAC_PresetTier == 2) ? 1.20 : 1.00);

    float edgeMask = FIAC_EdgeMask(uv, sourceColor);

    float stippleRaw = FIAC_StippleMask(uv, sourceLuma);
    float hatchRaw = FIAC_HatchMask(uv, sourceLuma);
    float patternRaw = max(stippleRaw, hatchRaw);
    float patternExpanded = FIAC_ExpandPatternMask(uv, patternRaw);
    float patternMask = smoothstep(FIAC_PatternThreshold, FIAC_PatternThreshold + 0.25, patternExpanded);
    float dotLattice = FIAC_DotLatticeMask(uv);
    float reflectiveDotMask = saturate(patternMask * dotLattice);

    float3 spatial = FIAC_SpatialFilter(uv, sourceDepth, sourceLuma);

    float3 historySample = tex2D(FIAC_HistorySampler, uv).rgb;
    float historyDepth = tex2D(FIAC_HistorySampler, uv).a;
    float historyLuma = FIAC_Luma(historySample);

    float depthReject = smoothstep(FIAC_DepthRejectStart, FIAC_DepthRejectEnd, abs(sourceDepth - historyDepth));
    float lumaReject = smoothstep(FIAC_LumaRejectStart, FIAC_LumaRejectEnd, abs(sourceLuma - historyLuma));
    float edgeReject = edgeMask * FIAC_EdgePreserve;

    float historyWeight = FIAC_HistoryBlend * (1.0 - max(max(depthReject, lumaReject), edgeReject));

    float2 px = FIAC_Pixel();
    float3 nR = FIAC_Source(uv + float2(px.x, 0.0));
    float3 nL = FIAC_Source(uv - float2(px.x, 0.0));
    float3 nU = FIAC_Source(uv + float2(0.0, px.y));
    float3 nD = FIAC_Source(uv - float2(0.0, px.y));
    float3 nMin = min(sourceColor, min(min(nR, nL), min(nU, nD)));
    float3 nMax = max(sourceColor, max(max(nR, nL), max(nU, nD)));
    float3 clampedHistory = clamp(historySample, nMin - FIAC_HistoryClamp.xxx, nMax + FIAC_HistoryClamp.xxx);

    float3 temporal = lerp(spatial, clampedHistory, historyWeight);

    float preserveBias = (FIAC_PatternMode == 0) ? (1.0 - patternMask * FIAC_PatternInfluence) : (1.0 + patternMask * FIAC_PatternInfluence * 0.75);
    float denoiseMask = saturate(FIAC_MasterIntensity * FIAC_DenoiseStrength * tierScale * (1.0 - edgeMask * FIAC_EdgePreserve) * preserveBias);

    float3 denoised = lerp(sourceColor, temporal, denoiseMask);

    float3 detail = sourceColor - spatial;
    denoised += detail * FIAC_DetailRestore * (1.0 - denoiseMask * 0.75);
    denoised = FIAC_ReflectivePatternSmooth(uv, denoised, spatial, temporal, reflectiveDotMask);

    float lightMask = 0.0;
    if (FIAC_RespectLight != 0)
    {
        lightMask = MIXSR_SHARED_SharedLightMask(uv, sourceColor, sourceLuma, 0.700000, 0.150000, 0.780000, 0.550000, 0.180000, FIAC_EPS);
    }
    denoised = MIXSR_SHARED_ProtectColor(uv, denoised, sourceColor, lightMask, FIAC_LightProtectStrength);

    float fogBypass = MIXSR_SHARED_SharedFogBypass(uv, sourceColor, FIAC_RespectFog);
    float3 finalColor = lerp(denoised, sourceColor, fogBypass);

    finalColor = FDPOST_Apply(finalColor, FIAC_PostToneBalance, FIAC_PostSaturationGuard, FIAC_PostClipGuard, FIAC_PostArtifactCleanup);

    float candidateDelta = length(temporal - sourceColor) * denoiseMask + length(reflectiveDotMask.xxx) * 0.01;
    float appliedDelta = length(finalColor - sourceColor);
    float computedMask = saturate(appliedDelta / max(FIAC_EPS, candidateDelta));

    if (FIAC_DebugView == 1) return float4(denoiseMask.xxx, sourceDepth);
    if (FIAC_DebugView == 2) return float4(patternMask.xxx, sourceDepth);
    if (FIAC_DebugView == 3) return float4(reflectiveDotMask.xxx, sourceDepth);
    if (FIAC_DebugView == 4) return float4(stippleRaw.xxx, sourceDepth);
    if (FIAC_DebugView == 5) return float4(hatchRaw.xxx, sourceDepth);
    if (FIAC_DebugView == 6) return float4(historyWeight.xxx, sourceDepth);
    if (FIAC_DebugView == 7) return float4(edgeMask.xxx, sourceDepth);
    if (FIAC_DebugView == 8) return float4(computedMask.xxx, sourceDepth);

    return float4(saturate(finalColor), sourceDepth);
}

float4 FIAC_PresentPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    return float4(tex2D(FIAC_OutputSampler, saturate(uv)).rgb, 1.0);
}

float4 FIAC_StoreHistoryPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    return tex2D(FIAC_OutputSampler, saturate(uv));
}

technique miXSR_FC_image_aware_coherence <
 ui_label = "Fine Cell - Image Coherence - Adaptive Temporal Spatial Denoiser";
 ui_tooltip = "Live temporal+spatial denoiser with image-aware coherence reconstruction and legacy stipple/hatch transparency pattern detection.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FIAC_MainPS;
        RenderTarget = FIAC_OutputTex;
    }
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FIAC_PresentPS;
    }
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FIAC_StoreHistoryPS;
        RenderTarget = FIAC_HistoryTex;
    }
}





