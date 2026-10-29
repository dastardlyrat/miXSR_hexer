// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: miXSR_FC_organic_fibonacci_fxaa_smaa-1
// Capability: Loop-free hybrid anti-aliasing with FXAA-style directional smoothing, SMAA-style neighborhood blending, and bio Fibonacci recursive weighting.

#include "ReShade.fxh"
#include "miXSR_FC_PostHarmonize.fxh"
#include "miXSR_FC_ShaderSharedMaskControls.fxh"

uniform int FDOAA_DebugView <
    ui_type = "combo";
 ui_label = "Debug View";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 00 Debug"; ui_category_closed = true;
    ui_items = "Final\0Edge Luma\0FXAA Blend\0SMAA Blend\0Organic Recursive Mask\0Combined Weight\0Computed Mask\0";
 ui_tooltip = "Shows final output or diagnostic anti-alias masks.";
> = 0;

uniform float FDOAA_MasterIntensity <
    ui_type = "slider";
 ui_label = "Master Intensity";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 02 Main Settings";
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.001;
 ui_tooltip = "Global blend strength for the anti-alias result.";
> = 1.000000;

uniform float FDOAA_EdgeThreshold <
    ui_type = "slider";
 ui_label = "Edge Threshold";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 02 Main Settings";
    ui_min = 0.0001; ui_max = 0.5000; ui_step = 0.0001;
 ui_tooltip = "Minimum luma range required before anti-aliasing is applied.";
> = 0.035000;

uniform float FDOAA_EdgeSoftness <
    ui_type = "slider";
 ui_label = "Edge Softness";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 02 Main Settings";
    ui_min = 0.0001; ui_max = 0.5000; ui_step = 0.0001;
 ui_tooltip = "Soft transition width above threshold.";
> = 0.040000;

uniform float FDOAA_FXAA_Strength <
    ui_type = "slider";
 ui_label = "FXAA Strength";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.001;
 ui_tooltip = "Weight of directional FXAA-style smoothing.";
> = 0.850000;

uniform float FDOAA_FXAA_SpanPixels <
    ui_type = "slider";
 ui_label = "FXAA Span Pixels";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.25; ui_max = 4.0; ui_step = 0.01;
 ui_tooltip = "Sampling span along the detected edge direction.";
> = 1.450000;

uniform float FDOAA_FXAA_Subpix <
    ui_type = "slider";
 ui_label = "FXAA Subpixel";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Subpixel refinement amount for FXAA direction sampling.";
> = 0.650000;

uniform float FDOAA_SMAA_Strength <
    ui_type = "slider";
 ui_label = "SMAA Strength";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.001;
 ui_tooltip = "Weight of neighborhood SMAA-style blending.";
> = 0.900000;

uniform float FDOAA_SMAA_ContrastThreshold <
    ui_type = "slider";
 ui_label = "SMAA Contrast Threshold";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0001; ui_max = 0.5000; ui_step = 0.0001;
 ui_tooltip = "Contrast gate for SMAA neighborhood blending.";
> = 0.022000;

uniform float FDOAA_SMAA_DiagonalWeight <
    ui_type = "slider";
 ui_label = "SMAA Diagonal Weight";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.001;
 ui_tooltip = "How strongly diagonal neighbors contribute.";
> = 0.700000;

uniform float FDOAA_OrganicRadiusPixels <
    ui_type = "slider";
 ui_label = "bio Radius Pixels";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.25; ui_max = 4.0; ui_step = 0.01;
 ui_tooltip = "Radius for the bio recursive Fibonacci samples.";
> = 1.250000;

uniform float FDOAA_OrganicInfluence <
    ui_type = "slider";
 ui_label = "bio Influence";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.001;
 ui_tooltip = "How much recursive bio weighting contributes to anti-aliasing.";
> = 0.850000;

uniform float FDOAA_OrganicAnisotropy <
    ui_type = "slider";
 ui_label = "bio Anisotropy";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Biases recursive offsets toward detected edge direction.";
> = 0.580000;

uniform int FDOAA_RespectFog <
    ui_type = "combo";
 ui_label = "Respect Fog";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_items = "No\0Yes\0";
 ui_tooltip = "Bypasses anti-aliasing where shared fog mask marks heavy fog regions.";
> = 1;

uniform int FDOAA_RespectLight <
    ui_type = "combo";
 ui_label = "Respect Light";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_items = "No\0Yes\0";
 ui_tooltip = "Preserves emissive highlights when applying anti-aliasing.";
> = 1;

uniform float FDOAA_LightProtectStrength <
    ui_type = "slider";
 ui_label = "Light Protect Strength";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.15; ui_step = 0.001;
 ui_tooltip = "Strength of emissive preservation.";
> = 0.900000;

uniform float FDOAA_PostToneBalance <
    ui_type = "slider";
 ui_label = "Post Tone Balance";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Post harmonization tone-balance strength.";
> = 0.080000;

uniform float FDOAA_PostSaturationGuard <
    ui_type = "slider";
 ui_label = "Post Saturation Guard";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Post harmonization saturation guard strength.";
> = 0.080000;

uniform float FDOAA_PostClipGuard <
    ui_type = "slider";
 ui_label = "Post Clip Guard";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Post harmonization highlight/shadow clip guard strength.";
> = 0.050000;

uniform float FDOAA_PostArtifactCleanup <
    ui_type = "slider";
 ui_label = "Post Artifact Cleanup";
 ui_category = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Post harmonization chroma artifact cleanup strength.";
> = 0.050000;

float FDOAA_Luma(float3 color)
{
    return dot(color, float3(0.2126, 0.7152, 0.0722));
}

float2 FDOAA_Pixel()
{
    return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
}

float3 FDOAA_Source(float2 uv)
{
    return tex2D(ReShade::BackBuffer, saturate(uv)).rgb;
}

float2 FDOAA_FibDir(float index)
{
    const float goldenAngle = 2.39996323;
    float angle = index * goldenAngle;
    return float2(cos(angle), sin(angle));
}

float2 FDOAA_OrganicRecursiveOffset(float2 uv, float2 edgeDir, float radiusPixels)
{
    float phase = dot(uv, float2(173.31, 91.77));
    float2 seedDir = normalize(FDOAA_FibDir(1.0 + phase));
    float2 dir0 = normalize(lerp(seedDir, edgeDir, saturate(FDOAA_OrganicAnisotropy)));
    float2 perp0 = float2(-dir0.y, dir0.x);
    float2 dir1 = normalize(dir0 * 0.6180339 + perp0 * 0.3819660);
    float2 perp1 = float2(-dir1.y, dir1.x);
    float2 dir2 = normalize(dir1 * 0.6180339 + perp1 * 0.3819660);
    float2 dir3 = normalize(lerp(dir2, edgeDir, 0.5));

    float2 mixedDir = (dir0 * 1.0) + (dir1 * 0.6180339) + (dir2 * 0.3819660) + (dir3 * 0.2360680);
    float2 finalDir = normalize(mixedDir + float2(0.00001, 0.00001));
    float2 pixel = FDOAA_Pixel();
    float2 offset = finalDir * (radiusPixels * pixel);
    return offset;
}

float4 FDOAA_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 pixel = FDOAA_Pixel();
    float2 uvN = saturate(uv + float2(0.0, -pixel.y));
    float2 uvS = saturate(uv + float2(0.0,  pixel.y));
    float2 uvW = saturate(uv + float2(-pixel.x, 0.0));
    float2 uvE = saturate(uv + float2( pixel.x, 0.0));
    float2 uvNW = saturate(uv + float2(-pixel.x, -pixel.y));
    float2 uvNE = saturate(uv + float2( pixel.x, -pixel.y));
    float2 uvSW = saturate(uv + float2(-pixel.x,  pixel.y));
    float2 uvSE = saturate(uv + float2( pixel.x,  pixel.y));

    float3 c = FDOAA_Source(uv);
    float3 n = FDOAA_Source(uvN);
    float3 s = FDOAA_Source(uvS);
    float3 w = FDOAA_Source(uvW);
    float3 e = FDOAA_Source(uvE);
    float3 nw = FDOAA_Source(uvNW);
    float3 ne = FDOAA_Source(uvNE);
    float3 sw = FDOAA_Source(uvSW);
    float3 se = FDOAA_Source(uvSE);

    float lC = FDOAA_Luma(c);
    float lN = FDOAA_Luma(n);
    float lS = FDOAA_Luma(s);
    float lW = FDOAA_Luma(w);
    float lE = FDOAA_Luma(e);
    float lNW = FDOAA_Luma(nw);
    float lNE = FDOAA_Luma(ne);
    float lSW = FDOAA_Luma(sw);
    float lSE = FDOAA_Luma(se);

    float lMin = min(lC, min(min(lN, lS), min(lW, lE)));
    float lMax = max(lC, max(max(lN, lS), max(lW, lE)));
    float edgeRange = lMax - lMin;
    float edgeMask = smoothstep(FDOAA_EdgeThreshold, FDOAA_EdgeThreshold + max(0.0001, FDOAA_EdgeSoftness), edgeRange);

    float dirX = -((lNW + lNE) - (lSW + lSE));
    float dirY =  ((lNW + lSW) - (lNE + lSE));
    float2 fxaaDir = normalize(float2(dirX, dirY) + float2(0.00001, 0.00001));

    float2 organicOffset = FDOAA_OrganicRecursiveOffset(uv, fxaaDir, FDOAA_OrganicRadiusPixels);
    float2 fxaaSpan = fxaaDir * (FDOAA_FXAA_SpanPixels * (0.4 + 0.6 * FDOAA_FXAA_Subpix)) * pixel;
    float2 fxaaStepA = fxaaSpan * (1.0 / 3.0) + organicOffset * 0.25;
    float2 fxaaStepB = fxaaSpan * (2.0 / 3.0) + organicOffset * 0.50;

    float3 fxaaP1 = FDOAA_Source(saturate(uv + fxaaStepA));
    float3 fxaaN1 = FDOAA_Source(saturate(uv - fxaaStepA));
    float3 fxaaP2 = FDOAA_Source(saturate(uv + fxaaStepB));
    float3 fxaaN2 = FDOAA_Source(saturate(uv - fxaaStepB));
    float3 fxaaColor = (fxaaP1 + fxaaN1 + fxaaP2 + fxaaN2) * 0.25;

    float hEdge = abs(lN - lS);
    float vEdge = abs(lW - lE);
    float dEdge = (abs(lNW - lSE) + abs(lNE - lSW)) * 0.5;
    float smaaEdge = max(hEdge, max(vEdge, dEdge));
    float smaaMask = smoothstep(FDOAA_SMAA_ContrastThreshold, FDOAA_SMAA_ContrastThreshold + max(0.0001, FDOAA_EdgeSoftness), smaaEdge);

    float sumEdge = hEdge + vEdge + dEdge + 0.00001;
    float wH = hEdge / sumEdge;
    float wV = vEdge / sumEdge;
    float wD = (dEdge / sumEdge) * FDOAA_SMAA_DiagonalWeight;
    float wNorm = max(0.00001, wH + wV + wD);

    float3 hBlend = (w + e) * 0.5;
    float3 vBlend = (n + s) * 0.5;
    float3 dBlend = (nw + ne + sw + se) * 0.25;
    float3 smaaColor = ((hBlend * wH) + (vBlend * wV) + (dBlend * wD)) / wNorm;

    float3 organicP = FDOAA_Source(saturate(uv + organicOffset));
    float3 organicN = FDOAA_Source(saturate(uv - organicOffset));
    float3 organicHP = FDOAA_Source(saturate(uv + organicOffset * 0.5));
    float3 organicHN = FDOAA_Source(saturate(uv - organicOffset * 0.5));
    float3 organicColor = (organicP + organicN + organicHP + organicHN) * 0.25;

    float fxaaBlend = saturate(edgeMask * FDOAA_FXAA_Strength);
    float smaaBlend = saturate(edgeMask * smaaMask * FDOAA_SMAA_Strength);
    float organicBlend = saturate(edgeMask * FDOAA_OrganicInfluence * (0.35 + 0.65 * smaaMask));

    float3 hybridAA = lerp(c, fxaaColor, fxaaBlend);
    hybridAA = lerp(hybridAA, smaaColor, smaaBlend);
    hybridAA = lerp(hybridAA, organicColor, organicBlend);

    float combinedWeight = saturate((fxaaBlend + smaaBlend + organicBlend) / 3.0);
    float computedMask = saturate(combinedWeight * FDOAA_MasterIntensity);
    float3 mixedColor = lerp(c, hybridAA, computedMask);

    float lightProtectMask = 0.0;
    if (FDOAA_RespectLight != 0)
    {
        lightProtectMask = MIXSR_SHARED_SharedLightMask(
            uv,
            c,
            lC,
            0.72,
            0.12,
            0.80,
            0.70,
            0.18,
            0.000100);
    }

    float3 protectedColor = MIXSR_SHARED_ProtectColor(uv, mixedColor, c, lightProtectMask, FDOAA_LightProtectStrength);
    float fogBypass = MIXSR_SHARED_SharedFogBypass(uv, c, FDOAA_RespectFog);
    float3 finalColor = lerp(protectedColor, c, fogBypass);
    finalColor = FDPOST_Apply(finalColor, FDOAA_PostToneBalance, FDOAA_PostSaturationGuard, FDOAA_PostClipGuard, FDOAA_PostArtifactCleanup);

    if (FDOAA_DebugView == 1) return float4(edgeRange.xxx, 1.0);
    if (FDOAA_DebugView == 2) return float4(fxaaBlend.xxx, 1.0);
    if (FDOAA_DebugView == 3) return float4(smaaBlend.xxx, 1.0);
    if (FDOAA_DebugView == 4) return float4(organicBlend.xxx, 1.0);
    if (FDOAA_DebugView == 5) return float4(combinedWeight.xxx, 1.0);
    if (FDOAA_DebugView == 6) return float4(computedMask.xxx, 1.0);
    return float4(saturate(finalColor), 1.0);
}
technique miXSR_FC_bio_fibonacci_fxaa_smaa <
 ui_label = "Fine Cell - Anti-Aliasing - FXAA SMAA Bio Fibonacci Blend";
 ui_tooltip = "Loop-free hybrid anti-aliasing: FXAA directional smoothing + SMAA neighborhood blending + bio Fibonacci recursive weighting.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FDOAA_MainPS;
    }
}







