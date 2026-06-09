// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: RC-1
// Capability: Fibonacci Superfine AO: depth-derived normals plus bio Fibonacci AO with conservative composite.


// Fibonacci Superfine AO: gated depth normalization -> robust normal derivation -> deterministic bio Fibonacci AO -> bilateral cleanup -> conservative composite.

#include "ReShade.fxh"
#include "miXSR_FC_OrganicSampling_Lens55.fxh"
#include "miXSR_FC_ShaderSharedMaskControls.fxh"

uniform float PRTAO_DepthValidityGate <
    ui_type = "slider";
    ui_label = "Depth Validity Gate";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Strength of depth validity gating. Higher values suppress AO when depth is unstable or unavailable.";
> = 0.650000;

uniform int PRTAO_DepthLinearizationMode <
    ui_type = "combo";
    ui_label = "Depth Linearization Mode";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_items = "ReShade Linearized\0Raw Depth\0Raw Inverted\0";
    ui_tooltip = "Selects how depth is interpreted before normalization.";
> = 0;

uniform float PRTAO_LinearDepthTraceScale <
    ui_type = "slider";
    ui_label = "Linear Depth Trace Scale";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 1.0; ui_max = 4096.0; ui_step = 1.0;
    ui_tooltip = "Amplifies tiny linearized-depth deltas so AO remains visible at distance.";
> = 512.000000;

uniform float PRTAO_DepthAvailabilityThreshold <
    ui_type = "slider";
    ui_label = "Depth Availability Threshold";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.00001; ui_max = 0.10000; ui_step = 0.00001;
    ui_tooltip = "How much local depth change is required before depth is considered usable.";
> = 0.002500;

uniform float PRTAO_DepthFallbackStrength <
    ui_type = "slider";
    ui_label = "Depth Fallback Strength";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Uses conservative luma-based fallback AO when depth is unavailable.";
> = 0.350000;

uniform float PRTAO_NormalReconstructionStrength <
    ui_type = "slider";
    ui_label = "Normal Reconstruction Strength";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.1; ui_max = 24.0; ui_step = 0.1;
    ui_tooltip = "Strength multiplier for derived normals reconstructed from depth.";
> = 6.000000;

uniform float PRTAO_NormalEdgeFade <
    ui_type = "slider";
    ui_label = "Normal Edge Fade";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Fades normal influence at depth edges to reduce halo artifacts.";
> = 0.550000;

uniform float PRTAO_AORadius <
    ui_type = "slider";
    ui_label = "AO Radius";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.25; ui_max = 24.0; ui_step = 0.01;
    ui_tooltip = "Screen-space radius in pixels for AO sampling.";
> = 0.250000;

uniform int PRTAO_AOSampleCount <
    ui_type = "slider";
    ui_label = "AO Sample Count (Legacy Compatibility)";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 4; ui_max = FCOH_LENS55_TAP_COUNT; ui_step = 1;
    ui_tooltip = "Legacy preset compatibility input. Non-default values map to tier tap caps.";
> = 24;

uniform int PRTAO_QualityTier <
    ui_type = "combo";
    ui_label = "Quality Tier";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_items = "Performance (8)\0Low (16)\0Balanced (24)\0High (32)\0Ultra (40)\0Max (55)\0";
    ui_tooltip = "Primary performance control. Lower tiers execute fewer taps and reduce GPU cost.";
> = 2;

uniform float PRTAO_QualityFine <
    ui_type = "slider";
    ui_label = "Quality Fine";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Look-only shaping within a tier. Does not change tap count or expected GPU cost tier.";
> = 0.500000;

uniform int PRTAO_AOTapMaskMode <
    ui_type = "combo";
    ui_label = "AO Tap Mask";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_items = "Full Progressive\0Odd Taps\0Even Taps\0Center Bias\0";
    ui_tooltip = "Deterministic mask mode applied to Fibonacci taps.";
> = 0;

uniform float PRTAO_AODepthFalloff <
    ui_type = "slider";
    ui_label = "AO Depth Falloff";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.01; ui_max = 128.0; ui_step = 0.01;
    ui_tooltip = "Controls how quickly AO influence decays with depth difference.";
> = 42.000000;

uniform float PRTAO_AONormalFalloff <
    ui_type = "slider";
    ui_label = "AO Normal Falloff";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.1; ui_max = 16.0; ui_step = 0.1;
    ui_tooltip = "Controls how strongly normal disagreement suppresses AO contribution.";
> = 4.000000;

uniform float PRTAO_AOEdgeFade <
    ui_type = "slider";
    ui_label = "AO Edge Fade";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Fades AO near strong depth edges to reduce shimmering and line haloing.";
> = 0.600000;

uniform float PRTAO_AOContrast <
    ui_type = "slider";
    ui_label = "AO Contrast";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.25; ui_max = 4.0; ui_step = 0.001;
    ui_tooltip = "Contrast shaping of AO response before cleanup.";
> = 1.100000;

uniform float PRTAO_AODistanceFade <
    ui_type = "slider";
    ui_label = "AO Distance Fade";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 4.0; ui_step = 0.001;
    ui_tooltip = "Fades AO by scene depth to keep distant regions conservative.";
> = 1.150000;

uniform float PRTAO_AOBilateralCleanupStrength <
    ui_type = "slider";
    ui_label = "AO Bilateral Cleanup Strength";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Strength of bilateral cleanup pass for AO stability.";
> = 0.650000;

uniform float PRTAO_FinalAOIntensity <
    ui_type = "slider";
    ui_label = "Final AO Intensity";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 4.6525; ui_step = 0.001;
    ui_tooltip = "Scales cleaned AO in the final composite stage. Increase when debug AO is visible but final shading is too subtle.";
> = 3.722000;

uniform float PRTAO_FinalVisibilityGain <
    ui_type = "slider";
    ui_label = "Final Visibility Gain";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.1; ui_max = 16.0; ui_step = 0.01;
    ui_tooltip = "Boosts low-amplitude AO into visible final shading without forcing extreme intensity.";
> = 3.500000;

uniform float PRTAO_GateStrength <
    ui_type = "slider";
    ui_label = "Gate Strength";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.15; ui_step = 0.001;
    ui_tooltip = "How strongly depth validity gate attenuates final AO. Lower values preserve more of the detected AO.";
> = 0.700000;

uniform float PRTAO_FinalCompositeWeight <
    ui_type = "slider";
    ui_label = "Final Composite Weight";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.25; ui_step = 0.001;
    ui_tooltip = "Blends between source color and AO-darkened color in the final pass.";
> = 1.000000;

uniform float PRTAO_FinalAOClamp <
    ui_type = "slider";
    ui_label = "Final AO Clamp";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.05; ui_max = 1.127; ui_step = 0.001;
    ui_tooltip = "Upper bound for final AO darkening to prevent over-crushing.";
> = 0.900000;

uniform int PRTAO_RespectFog <
    ui_type = "combo";
    ui_label = "Respect Fog";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_items = "No\0Yes\0";
    ui_tooltip = "Bypasses AO in fog-dominant regions.";
> = 1;

uniform int PRTAO_RespectLight <
    ui_type = "combo";
    ui_label = "Respect Light Emission";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_items = "No\0Yes\0";
    ui_tooltip = "Protects bright emissive pixels from being darkened by the AO composite.";
> = 1;

uniform float PRTAO_LightProtectStrength <
    ui_type = "slider";
    ui_label = "Light Protect Strength";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.15; ui_step = 0.001;
    ui_tooltip = "How strongly emissive pixels are restored back to source color.";
> = 0.900000;

uniform float PRTAO_LightThreshold <
    ui_type = "slider";
    ui_label = "Light Threshold";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Brightness level where the emission protection begins.";
> = 0.680000;

uniform float PRTAO_LightSoftness <
    ui_type = "slider";
    ui_label = "Light Softness";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.001; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Soft transition width for the light protection gate.";
> = 0.180000;

uniform float PRTAO_LightPeakInfluence <
    ui_type = "slider";
    ui_label = "Peak Influence";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.15; ui_step = 0.001;
    ui_tooltip = "Raises protection when one channel is much hotter than the rest.";
> = 0.700000;

uniform float PRTAO_LightSaturationInfluence <
    ui_type = "slider";
    ui_label = "Saturation Influence";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Adds extra protection for colored emissive lights and neon accents.";
> = 0.350000;

uniform float PRTAO_LightSaturationThreshold <
    ui_type = "slider";
    ui_label = "Saturation Threshold";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Minimum saturation needed before colored emission gets extra protection.";
> = 0.220000;

uniform int PRTAO_DebugView <
    ui_type = "combo";
    ui_label = "Debug View";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 00 Debug"; ui_category_closed = true;
    ui_items = "Final\0Raw AO\0Clean AO\0Depth Gate\0Derived Normal\0Composite AO\0Final Delta\0Depth Availability\0Linear Depth\0Raw Depth\0Fallback AO\0Fallback AO Raw\0Light Protect Mask\0Fog Bypass\0Composite Gate\0";
    ui_tooltip = "Shows final composite or diagnostics. Fallback AO Raw ignores availability gating for troubleshooting.";
> = 0;

uniform float PRTAO_DebugExposure <
    ui_type = "slider";
    ui_label = "Debug Exposure";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 00 Debug"; ui_category_closed = true;
    ui_min = 1.0; ui_max = 32.0; ui_step = 0.1;
    ui_tooltip = "Boosts debug buffer visibility without changing final shading.";
> = 1.000000;

uniform float PRTAO_DebugGamma <
    ui_type = "slider";
    ui_label = "Debug Gamma";
    ui_category = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling / 00 Debug"; ui_category_closed = true;
    ui_min = 0.25; ui_max = 2.0; ui_step = 0.01;
    ui_tooltip = "Tonemaps lifted debug buffers. Lower values lift dark details.";
> = 0.250000;

texture2D PRTAO_AORawTex
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

sampler2D PRTAO_AORawSampler
{
    Texture = PRTAO_AORawTex;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = NONE;
};

float2 PRTAO_PixelSize()
{
    return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
}

float PRTAO_DebugScalar(float value)
{
    float exposure = max(1.0, PRTAO_DebugExposure);
    float gamma = max(0.25, PRTAO_DebugGamma);
    return pow(saturate(value * exposure), gamma);
}

float3 PRTAO_Source(float2 uv)
{
    return tex2D(ReShade::BackBuffer, saturate(uv)).rgb;
}

float PRTAO_Luma(float3 color)
{
    return dot(color, float3(0.2126, 0.7152, 0.0722));
}

float PRTAO_LightEmissionMask(float3 sourceColor)
{
    if (PRTAO_RespectLight == 0)
    {
        return 0.0;
    }

    return FC_LIGHT_EmissionMask(
        sourceColor,
        PRTAO_Luma(sourceColor),
        PRTAO_LightThreshold,
        PRTAO_LightSoftness,
        PRTAO_LightPeakInfluence,
        PRTAO_LightSaturationInfluence,
        PRTAO_LightSaturationThreshold,
        0.000010);
}

float PRTAO_RawDepth(float2 uv)
{
    return tex2D(ReShade::DepthBuffer, saturate(uv)).r;
}

float PRTAO_DepthTraceScale()
{
    return (PRTAO_DepthLinearizationMode == 0) ? max(1.0, PRTAO_LinearDepthTraceScale) : 1.0;
}

int PRTAO_TierTapCap()
{
    if (PRTAO_QualityTier == 0) return 8;
    if (PRTAO_QualityTier == 1) return 16;
    if (PRTAO_QualityTier == 2) return 24;
    if (PRTAO_QualityTier == 3) return 32;
    if (PRTAO_QualityTier == 4) return 40;
    return 55;
}

int PRTAO_MapLegacyTapCap(int legacyTapCount)
{
    int legacy = clamp(legacyTapCount, 1, FCOH_LENS55_TAP_COUNT);
    if (legacy <= 11) return 8;
    if (legacy <= 19) return 16;
    if (legacy <= 27) return 24;
    if (legacy <= 35) return 32;
    if (legacy <= 47) return 40;
    return 55;
}

int PRTAO_EffectiveTapCap()
{
    int cap = 24;
    if (PRTAO_AOSampleCount != 24)
    {
        cap = PRTAO_MapLegacyTapCap(PRTAO_AOSampleCount);
    }
    else
    {
        cap = PRTAO_TierTapCap();
    }
    return cap;
}

float PRTAO_LinearDepth(float2 uv)
{
    float rawDepth = PRTAO_RawDepth(uv);
    if (PRTAO_DepthLinearizationMode == 1)
    {
        return saturate(rawDepth);
    }
    if (PRTAO_DepthLinearizationMode == 2)
    {
        return saturate(1.0 - rawDepth);
    }
    return saturate(ReShade::GetLinearizedDepth(saturate(uv)));
}

float PRTAO_DepthGradient(float2 uv, float centerDepth)
{
    float2 px = PRTAO_PixelSize();
    float traceScale = PRTAO_DepthTraceScale();
    float dR = PRTAO_LinearDepth(uv + float2(px.x, 0.0));
    float dL = PRTAO_LinearDepth(uv - float2(px.x, 0.0));
    float dU = PRTAO_LinearDepth(uv + float2(0.0, px.y));
    float dD = PRTAO_LinearDepth(uv - float2(0.0, px.y));

    float slope = (abs(dR - dL) + abs(dU - dD)) * traceScale;
    float centerFit = (abs(dR - centerDepth) + abs(dL - centerDepth) + abs(dU - centerDepth) + abs(dD - centerDepth)) * traceScale;
    return 0.5 * slope + 0.125 * centerFit;
}

float PRTAO_RawDepthActivity(float2 uv)
{
    float2 px = PRTAO_PixelSize();
    float dR = PRTAO_RawDepth(uv + float2(px.x, 0.0));
    float dL = PRTAO_RawDepth(uv - float2(px.x, 0.0));
    float dU = PRTAO_RawDepth(uv + float2(0.0, px.y));
    float dD = PRTAO_RawDepth(uv - float2(0.0, px.y));
    return abs(dR - dL) + abs(dU - dD);
}

float PRTAO_DepthAvailability(float2 uv, float centerDepth)
{
    float2 px = PRTAO_PixelSize();
    float traceScale = PRTAO_DepthTraceScale();
    float rawDepth = PRTAO_RawDepth(uv);
    float rawR = PRTAO_RawDepth(uv + float2(px.x, 0.0));
    float rawL = PRTAO_RawDepth(uv - float2(px.x, 0.0));
    float rawU = PRTAO_RawDepth(uv + float2(0.0, px.y));
    float rawD = PRTAO_RawDepth(uv - float2(0.0, px.y));
    float linR = PRTAO_LinearDepth(uv + float2(px.x, 0.0));
    float linL = PRTAO_LinearDepth(uv - float2(px.x, 0.0));
    float linU = PRTAO_LinearDepth(uv + float2(0.0, px.y));
    float linD = PRTAO_LinearDepth(uv - float2(0.0, px.y));

    float rawSpan = max(max(abs(rawDepth - rawR), abs(rawDepth - rawL)), max(abs(rawDepth - rawU), abs(rawDepth - rawD)));
    float linSpan = max(max(abs(centerDepth - linR), abs(centerDepth - linL)), max(abs(centerDepth - linU), abs(centerDepth - linD)));
    float scaledActivity = max(rawSpan, linSpan) * traceScale;
    float threshold = max(0.00001, PRTAO_DepthAvailabilityThreshold);
    float availability = smoothstep(threshold, threshold * 4.0, scaledActivity);
    float validRange = step(0.000010, rawDepth) * step(rawDepth, 0.999990);
    return saturate(availability * validRange);
}

float PRTAO_DepthValidityMask(float2 uv, float centerDepth)
{
    float gradient = PRTAO_DepthGradient(uv, centerDepth);
    float continuity = 1.0 - saturate(gradient * 32.0);
    float availability = PRTAO_DepthAvailability(uv, centerDepth);
    float gate = saturate(PRTAO_DepthValidityGate);
    return saturate(availability * lerp(1.0, continuity, gate));
}

float3 PRTAO_DerivedNormalFromCenterDepth(float2 uv, float centerDepth, out float edgeFactor)
{
    float2 px = PRTAO_PixelSize();

    float dC = centerDepth;
    float dR = PRTAO_LinearDepth(uv + float2(px.x, 0.0));
    float dL = PRTAO_LinearDepth(uv - float2(px.x, 0.0));
    float dU = PRTAO_LinearDepth(uv + float2(0.0, px.y));
    float dD = PRTAO_LinearDepth(uv - float2(0.0, px.y));

    float gradX = (abs(dR - dC) < abs(dC - dL)) ? (dR - dC) : (dC - dL);
    float gradY = (abs(dU - dC) < abs(dC - dD)) ? (dU - dC) : (dC - dD);

    float edgeRaw = abs(gradX) + abs(gradY);
    edgeFactor = saturate(edgeRaw * 64.0);

    float edgeFade = saturate(PRTAO_NormalEdgeFade);
    float strength = lerp(PRTAO_NormalReconstructionStrength, PRTAO_NormalReconstructionStrength * 0.20, edgeFactor * edgeFade);

    float3 n = normalize(float3(-gradX * strength, -gradY * strength, 1.0));
    n.z = abs(n.z);
    return normalize(n);
}

float3 PRTAO_DerivedNormal(float2 uv, out float edgeFactor)
{
    return PRTAO_DerivedNormalFromCenterDepth(uv, PRTAO_LinearDepth(uv), edgeFactor);
}

float2 PRTAO_FibonacciDirection(float fibIndex)
{
    const float goldenAngle = 2.39996323;
    float angle = fibIndex * goldenAngle;
    return float2(cos(angle), sin(angle));
}

float PRTAO_LumaFallbackAO(float2 uv)
{
    float2 px = PRTAO_PixelSize() * max(1.0, PRTAO_AORadius * 2.0);
    float center = PRTAO_Luma(PRTAO_Source(uv));
    float sR = PRTAO_Luma(PRTAO_Source(uv + float2(px.x, 0.0)));
    float sL = PRTAO_Luma(PRTAO_Source(uv - float2(px.x, 0.0)));
    float sU = PRTAO_Luma(PRTAO_Source(uv + float2(0.0, px.y)));
    float sD = PRTAO_Luma(PRTAO_Source(uv - float2(0.0, px.y)));
    float neighborMean = (sR + sL + sU + sD) * 0.25;
    float localContrast = (abs(center - sR) + abs(center - sL) + abs(center - sU) + abs(center - sD)) * 0.25;
    return saturate(max(center - neighborMean, 0.0) * 1.5 + localContrast * 0.5);
}

float PRTAO_TapMask(float2 uv, float2 offset, float fibIndex)
{
    float2 fibDir = PRTAO_FibonacciDirection(fibIndex);
    float2 baseDir = normalize(float2(0.23 - offset.y, 0.17 + offset.x + frac(fibIndex * 0.000618)));
    float2 organicDir = normalize(lerp(baseDir, fibDir, 0.5));

    float phase = fibIndex * 0.013 + dot(uv * 128.0, float2(0.754, 0.569));
    float waveA = sin(dot(uv * 96.0 + offset * 16.0, organicDir) + phase);
    float waveB = cos(dot(uv * 64.0 - offset * 11.0, float2(-organicDir.y, organicDir.x)) + phase * 0.7);

    return saturate(0.5 + 0.25 * waveA + 0.25 * waveB);
}

float PRTAO_TapEnable(int tapIndex, int sampleCount)
{
    if (tapIndex >= sampleCount)
    {
        return 0.0;
    }

    if (PRTAO_AOTapMaskMode == 1)
    {
        return ((tapIndex % 2) == 1) ? 1.0 : 0.0;
    }
    if (PRTAO_AOTapMaskMode == 2)
    {
        return ((tapIndex % 2) == 0) ? 1.0 : 0.0;
    }
    if (PRTAO_AOTapMaskMode == 3)
    {
        float centerLimit = float(sampleCount) * 0.55;
        return (float(tapIndex) < centerLimit) ? 1.0 : 0.0;
    }

    return 1.0;
}

float PRTAO_AORaw(float2 uv, out float centerDepth, out float centerEdge, out float gateMask)
{
    centerDepth = PRTAO_LinearDepth(uv);

    float3 centerNormal = PRTAO_DerivedNormalFromCenterDepth(uv, centerDepth, centerEdge);
    gateMask = PRTAO_DepthValidityMask(uv, centerDepth);
    if (gateMask <= 0.0001)
    {
        return 0.0;
    }

    int sampleCount = clamp(PRTAO_EffectiveTapCap(), 1, FCOH_LENS55_TAP_COUNT);
    float2 px = PRTAO_PixelSize();
    float2 aoRadiusPx = PRTAO_AORadius * px;
    float depthFalloff = max(0.01, PRTAO_AODepthFalloff) * PRTAO_DepthTraceScale();
    float depthWeightScale = depthFalloff * 0.20;
    float normalFalloff = max(0.1, PRTAO_AONormalFalloff);
    float invSampleCount = rcp(float(sampleCount));
    float qualityFine = saturate(PRTAO_QualityFine);
    float perTapNormalEnable = step(31.5, float(sampleCount));

    float occlusionSum = 0.0;
    float weightSum = 0.0;

    #define PRTAO_AO_TAP(OFFSET, INDEX) { \
        float enabled = PRTAO_TapEnable((INDEX), sampleCount); \
        if (((INDEX) < sampleCount) && (enabled > 0.0)) { \
            float2 baseOffset = (OFFSET); \
            float fibIndex = 2584.0 + float(INDEX); \
            float2 fibDir = PRTAO_FibonacciDirection(fibIndex); \
            float2 organicDir = normalize(lerp(normalize(baseOffset + 0.00001), fibDir, 0.5)); \
            float radial = 0.35 + 0.65 * sqrt((float(INDEX) + 1.0) * invSampleCount); \
            float radiusShape = lerp(0.85, 1.25, qualityFine); \
            float2 sampleOffset = organicDir * radial * radiusShape * aoRadiusPx; \
            float2 sampleUv = saturate(uv + sampleOffset); \
            float sampleDepth = PRTAO_LinearDepth(sampleUv); \
            float depthDelta = centerDepth - sampleDepth; \
            float depthOcc = saturate(depthDelta * depthFalloff); \
            float depthWeight = exp(-abs(depthDelta) * depthWeightScale); \
            float sampleEdge = centerEdge; \
            float3 sampleNormal = centerNormal; \
            if ((perTapNormalEnable > 0.5) && (depthOcc > 0.0001)) { \
                sampleNormal = PRTAO_DerivedNormalFromCenterDepth(sampleUv, sampleDepth, sampleEdge); \
            } \
            float normalDot = saturate(dot(centerNormal, sampleNormal)); \
            float normalWeight = pow(max(0.0001, normalDot), normalFalloff); \
            float edgeWeight = 1.0 - saturate((centerEdge + sampleEdge) * 0.5 * PRTAO_AOEdgeFade); \
            float maskWeight = PRTAO_TapMask(uv, baseOffset, fibIndex); \
            float tapWeight = enabled * depthWeight * normalWeight * edgeWeight * maskWeight; \
            occlusionSum += depthOcc * tapWeight; \
            weightSum += tapWeight; \
        } \
    }
    FCOH_LENS55_TAPS(PRTAO_AO_TAP)
    #undef PRTAO_AO_TAP

    float ao = occlusionSum / max(0.000010, weightSum);
    ao = pow(saturate(ao), max(0.25, PRTAO_AOContrast));

    float distanceFade = exp(-centerDepth * max(0.0, PRTAO_AODistanceFade) * 6.0);
    ao *= distanceFade;

    return saturate(ao);
}

float4 PRTAO_RawPassPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float centerDepth = 0.0;
    float centerEdge = 0.0;
    float gateMask = 1.0;
    float aoRaw = PRTAO_AORaw(uv, centerDepth, centerEdge, gateMask);

    return float4(aoRaw, centerDepth, centerEdge, gateMask);
}

float PRTAO_BilateralCleanup(float2 uv)
{
    float4 center = tex2D(PRTAO_AORawSampler, saturate(uv));
    float centerAo = center.r;
    float centerDepth = center.g;
    float centerEdge = center.b;

    float cleanupStrength = saturate(PRTAO_AOBilateralCleanupStrength);
    if (cleanupStrength <= 0.0001)
    {
        return centerAo;
    }

    float2 px = PRTAO_PixelSize();
    float depthBilateralScale = 12.0 + PRTAO_AODepthFalloff * 0.25;

    float aoSum = centerAo;
    float weightSum = 1.0;

    #define PRTAO_FILTER_TAP(DX, DY, W) { \
        float2 suv = saturate(uv + float2((DX), (DY)) * px); \
        float4 s = tex2D(PRTAO_AORawSampler, suv); \
        float depthWeight = exp(-abs(s.g - centerDepth) * depthBilateralScale); \
        float edgeWeight = exp(-abs(s.b - centerEdge) * 6.0); \
        float bilateral = lerp(1.0, depthWeight * edgeWeight, cleanupStrength); \
        float tapWeight = (W) * bilateral; \
        aoSum += s.r * tapWeight; \
        weightSum += tapWeight; \
    }

    PRTAO_FILTER_TAP(-1.0, -1.0, 1.0)
    PRTAO_FILTER_TAP( 0.0, -1.0, 2.0)
    PRTAO_FILTER_TAP( 1.0, -1.0, 1.0)
    PRTAO_FILTER_TAP(-1.0,  0.0, 2.0)
    PRTAO_FILTER_TAP( 1.0,  0.0, 2.0)
    PRTAO_FILTER_TAP(-1.0,  1.0, 1.0)
    PRTAO_FILTER_TAP( 0.0,  1.0, 2.0)
    PRTAO_FILTER_TAP( 1.0,  1.0, 1.0)

    #undef PRTAO_FILTER_TAP

    return saturate(aoSum / max(0.000010, weightSum));
}

float4 PRTAO_CompositePS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 sourceColor = PRTAO_Source(uv);
    float4 rawPack = tex2D(PRTAO_AORawSampler, saturate(uv));

    float rawAo = rawPack.r;
    float cleanAo = PRTAO_BilateralCleanup(uv);
    float gateMask = rawPack.a;
    float depthAvailable = PRTAO_DepthAvailability(uv, rawPack.g);
    float fallbackAoRaw = PRTAO_LumaFallbackAO(uv) * saturate(PRTAO_DepthFallbackStrength);
    float fallbackAo = fallbackAoRaw * (1.0 - depthAvailable);
    float rawAoCombined = max(rawAo, fallbackAo);
    cleanAo = max(cleanAo, fallbackAo);

    // Use a smarter composite gate so fallback AO is not crushed when depth is unavailable.
    float fallbackGate = 1.0 - depthAvailable;
    float compositeGate = max(gateMask, fallbackGate);
    compositeGate = lerp(1.0, compositeGate, saturate(PRTAO_GateStrength));

    float compositeDrive = cleanAo * compositeGate;
    compositeDrive *= max(0.0, PRTAO_FinalAOIntensity);
    compositeDrive *= max(0.1, PRTAO_FinalVisibilityGain);

    float conservativeAo = saturate(1.0 - exp(-compositeDrive));
    conservativeAo = min(conservativeAo, PRTAO_FinalAOClamp);

    float compositeWeight = saturate(PRTAO_FinalCompositeWeight);
    float3 aoColor = sourceColor * (1.0 - conservativeAo);
    float3 composite = lerp(sourceColor, aoColor, compositeWeight);
    float lightProtectMask = PRTAO_LightEmissionMask(sourceColor);
    composite = MIXSR_SHARED_ProtectColor(uv, composite, sourceColor, lightProtectMask, PRTAO_LightProtectStrength);

    float fogBypass = MIXSR_SHARED_SharedFogBypass(uv, sourceColor, PRTAO_RespectFog);
    float3 fogRespected = lerp(composite, sourceColor, fogBypass);

    if (PRTAO_DebugView == 1) return float4(PRTAO_DebugScalar(rawAoCombined).xxx, 1.0);
    if (PRTAO_DebugView == 2) return float4(PRTAO_DebugScalar(cleanAo).xxx, 1.0);
    if (PRTAO_DebugView == 3) return float4(PRTAO_DebugScalar(gateMask).xxx, 1.0);
    if (PRTAO_DebugView == 4)
    {
        float edgeFactor = 0.0;
        float3 n = PRTAO_DerivedNormal(uv, edgeFactor);
        return float4(n * 0.5 + 0.5, 1.0);
    }
    if (PRTAO_DebugView == 5) return float4(PRTAO_DebugScalar(conservativeAo).xxx, 1.0);
    if (PRTAO_DebugView == 6)
    {
        float3 delta = abs(sourceColor - fogRespected);
        return float4(saturate(delta * max(1.0, PRTAO_DebugExposure)), 1.0);
    }
    if (PRTAO_DebugView == 7) return float4(PRTAO_DebugScalar(depthAvailable).xxx, 1.0);
    if (PRTAO_DebugView == 8) return float4(PRTAO_DebugScalar(rawPack.g).xxx, 1.0);
    if (PRTAO_DebugView == 9) return float4(PRTAO_DebugScalar(PRTAO_RawDepth(uv)).xxx, 1.0);
    if (PRTAO_DebugView == 10) return float4(PRTAO_DebugScalar(fallbackAo).xxx, 1.0);
    if (PRTAO_DebugView == 11) return float4(PRTAO_DebugScalar(fallbackAoRaw).xxx, 1.0);
    if (PRTAO_DebugView == 12) return float4(PRTAO_DebugScalar(lightProtectMask).xxx, 1.0);
    if (PRTAO_DebugView == 13) return float4(PRTAO_DebugScalar(fogBypass).xxx, 1.0);
    if (PRTAO_DebugView == 14) return float4(PRTAO_DebugScalar(compositeGate).xxx, 1.0);

    return float4(saturate(fogRespected), 1.0);
}
technique miXSR_FC_SuperfineFibonacciAO < ui_label = "Fine Cell - Ambient Occlusion - Superfine Fibonacci Sampling";  ui_tooltip = "Fibonacci Superfine AO: depth-derived normals plus bio Fibonacci AO with conservative compositing."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PRTAO_RawPassPS;
        RenderTarget = PRTAO_AORawTex;
    }
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PRTAO_CompositePS;
    }
}





