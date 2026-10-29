// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: dream-deep-shade-second-gate-1
// Capability: Standalone five-stage bio hatch shading pipeline.


// Stage model: near -> forward -> center -> back -> far (multi-stage depth-blended by default).

#include "ReShade.fxh"
#include "FineDream_PostHarmonize.fxh"

uniform int FDSG2_Stage <
    ui_type = "combo";
    ui_label = "Stage View";
    ui_category = "Fine Cell - Hatch Shading - Five-Stage Bio / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_items = "Blended (All Stages)\0Near (Hatch Light Small)\0Forward (Hatch Med-Small Light)\0Center (Hatch Very-Small Light-Dark)\0Back (Hatch Med-Small Light)\0Far (Hatch Light Small)\0";
    ui_tooltip = "Default blends all five stages by depth; other modes isolate a single stage for inspection.";
> = 0;

uniform int FDSG2_DebugView <
    ui_type = "combo";
    ui_label = "Debug View";
    ui_category = "Fine Cell - Hatch Shading - Five-Stage Bio / 00 Debug"; ui_category_closed = true;
    ui_items = "Final\0Hatch Mask\0Very-Small Pattern\0Depth Near\0Edge\0Local Contrast\0";
    ui_tooltip = "Shows final output or diagnostics.\nVery-Small Pattern is the center-stage hatch carrier.";
> = 0;

uniform float FDSG2_MasterIntensity <
    ui_type = "slider";
    ui_label = "Master Intensity";
    ui_category = "Fine Cell - Hatch Shading - Five-Stage Bio / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.001;
    ui_tooltip = "Global effect intensity.";
> = 1.000000;

uniform float FDSG2_ShadeStrength <
    ui_type = "slider";
    ui_label = "Shade Strength";
    ui_category = "Fine Cell - Hatch Shading - Five-Stage Bio / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Strength of hatch shading relative to source color.";
> = 0.180000;

uniform float FDSG2_HatchPatternScale <
    ui_type = "slider";
    ui_label = "Hatch Pattern Scale";
    ui_category = "Fine Cell - Hatch Shading - Five-Stage Bio / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 40.0; ui_max = 1600.0; ui_step = 0.1;
    ui_tooltip = "UV scale used by the hatch pattern.";
> = 860.000000;

uniform float FDSG2_HatchContrast <
    ui_type = "slider";
    ui_label = "Hatch Contrast";
    ui_category = "Fine Cell - Hatch Shading - Five-Stage Bio / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.1; ui_max = 4.0; ui_step = 0.001;
    ui_tooltip = "Contrast shaping for the hatch pattern.";
> = 1.000000;

uniform int FDSG2_InvertDepth <
    ui_type = "combo";
    ui_label = "Invert Depth";
    ui_category = "Fine Cell - Hatch Shading - Five-Stage Bio / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_items = "No\0Yes\0";
    ui_tooltip = "Inverts near/far interpretation for reversed depth buffers.";
> = 0;

uniform float FDSG2_PostToneBalance <
    ui_type = "slider";
    ui_label = "Post Tone Balance";
    ui_category = "Fine Cell - Hatch Shading - Five-Stage Bio / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Final shared tone harmonization strength.";
> = 0.180000;

uniform float FDSG2_PostSaturationGuard <
    ui_type = "slider";
    ui_label = "Post Saturation Guard";
    ui_category = "Fine Cell - Hatch Shading - Five-Stage Bio / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Final shared saturation guard strength.";
> = 0.250000;

uniform float FDSG2_PostClipGuard <
    ui_type = "slider";
    ui_label = "Post Clip Guard";
    ui_category = "Fine Cell - Hatch Shading - Five-Stage Bio / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Final shared clip-guard compression near black/white limits.";
> = 0.200000;

uniform float FDSG2_PostArtifactCleanup <
    ui_type = "slider";
    ui_label = "Post Artifact Cleanup";
    ui_category = "Fine Cell - Hatch Shading - Five-Stage Bio / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Final shared fringe/leak cleanup strength.";
> = 0.150000;

float2 FDSG2_Pixel() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
float3 FDSG2_Source(float2 uv) { return tex2D(ReShade::BackBuffer, saturate(uv)).rgb; }
float FDSG2_Luma(float3 color) { return dot(color, float3(0.2126, 0.7152, 0.0722)); }

float FDSG2_Depth(float2 uv)
{
    float depth = saturate(ReShade::GetLinearizedDepth(saturate(uv)));
    return (FDSG2_InvertDepth != 0) ? (1.0 - depth) : depth;
}

float FDSG2_LocalContrast(float2 uv)
{
    float2 px = FDSG2_Pixel() * 2.0;
    float c = FDSG2_Luma(FDSG2_Source(uv));
    float r = FDSG2_Luma(FDSG2_Source(uv + float2(px.x, 0.0)));
    float l = FDSG2_Luma(FDSG2_Source(uv - float2(px.x, 0.0)));
    float u = FDSG2_Luma(FDSG2_Source(uv + float2(0.0, px.y)));
    float d = FDSG2_Luma(FDSG2_Source(uv - float2(0.0, px.y)));
    return (abs(c - r) + abs(c - l) + abs(c - u) + abs(c - d)) * 0.25;
}

float3 FDSG2_Shade(float2 uv, float3 sourceColor, float depth, float localContrast, out float hatchMaskOut, out float verySmallPatternOut, out float edgeOut, out float depthNearOut)
{
    float2 px = FDSG2_Pixel();
    float lR = FDSG2_Luma(FDSG2_Source(uv + float2(px.x, 0.0)));
    float lL = FDSG2_Luma(FDSG2_Source(uv - float2(px.x, 0.0)));
    float lU = FDSG2_Luma(FDSG2_Source(uv + float2(0.0, px.y)));
    float lD = FDSG2_Luma(FDSG2_Source(uv - float2(0.0, px.y)));
    float edge = saturate((abs(lR - lL) + abs(lU - lD)) * 4.0);
    float depthNear = saturate(1.0 - depth);

    float smallScale = FDSG2_HatchPatternScale * 1.30;
    float medSmallScale = FDSG2_HatchPatternScale * 1.00;
    float verySmallScale = FDSG2_HatchPatternScale * 1.70;

    float smallWaveA = sin((uv.x + uv.y) * smallScale + depth * 21.0);
    float smallWaveB = sin((uv.x - uv.y) * (smallScale * 0.825) - depth * 17.0);
    float smallPattern = saturate((saturate(smallWaveA * smallWaveB * 0.5 + 0.5) - 0.5) * FDSG2_HatchContrast + 0.5);
    float smallMask = saturate(edge * 0.42 + localContrast * 2.40 + depthNear * 0.18);

    float medWaveA = sin((uv.x + uv.y) * medSmallScale + depth * 19.0);
    float medWaveB = sin((uv.x - uv.y) * (medSmallScale * 0.810) - depth * 15.0);
    float medSmallPattern = saturate((saturate(medWaveA * medWaveB * 0.5 + 0.5) - 0.5) * FDSG2_HatchContrast + 0.5);
    float medSmallMask = saturate(edge * 0.46 + localContrast * 2.70 + depthNear * 0.16);

    float vSmallWaveA = sin((uv.x + uv.y) * verySmallScale + depth * 23.0);
    float vSmallWaveB = sin((uv.x - uv.y) * (verySmallScale * 0.840) - depth * 19.0);
    float verySmallPattern = saturate((saturate(vSmallWaveA * vSmallWaveB * 0.5 + 0.5) - 0.5) * FDSG2_HatchContrast + 0.5);
    float verySmallMask = saturate(edge * 0.50 + localContrast * 3.00 + depthNear * 0.20);

    // near/far: hatch light and small
    float3 nearShade = sourceColor * (1.0 - (0.16 + 0.28 * smallMask) * FDSG2_ShadeStrength);
    nearShade = saturate(nearShade + float3(0.012, 0.009, 0.006) * smallPattern * FDSG2_ShadeStrength);

    float3 farShade = sourceColor * (1.0 - (0.17 + 0.29 * smallMask) * FDSG2_ShadeStrength);
    farShade = saturate(farShade + float3(0.011, 0.008, 0.005) * smallPattern * FDSG2_ShadeStrength);

    // forward/back: hatch med-small and light
    float3 forwardShade = sourceColor * (1.0 - (0.20 + 0.34 * medSmallMask) * FDSG2_ShadeStrength);
    forwardShade = saturate(forwardShade + float3(0.010, 0.008, 0.005) * medSmallPattern * FDSG2_ShadeStrength);

    float3 backShade = sourceColor * (1.0 - (0.20 + 0.34 * medSmallMask) * FDSG2_ShadeStrength);
    backShade = saturate(backShade + float3(0.010, 0.008, 0.005) * medSmallPattern * FDSG2_ShadeStrength);

    // center: hatch very-small with light-dark character
    float3 centerShade = sourceColor * (1.0 - (0.26 + 0.48 * verySmallMask) * FDSG2_ShadeStrength);
    centerShade = saturate(centerShade + float3(0.009, 0.006, 0.004) * verySmallPattern * FDSG2_ShadeStrength);
    centerShade *= (1.0 - (0.10 + 0.12 * (1.0 - verySmallPattern)) * FDSG2_ShadeStrength);

    hatchMaskOut = smallMask;
    verySmallPatternOut = verySmallPattern;
    edgeOut = edge;
    depthNearOut = depthNear;

    float stagePos = saturate(depth);
    float blendWidth = 0.30;
    float wNear = 1.0 - saturate(abs(stagePos - 0.00) / blendWidth);
    float wForward = 1.0 - saturate(abs(stagePos - 0.25) / blendWidth);
    float wCenter = 1.0 - saturate(abs(stagePos - 0.50) / blendWidth);
    float wBack = 1.0 - saturate(abs(stagePos - 0.75) / blendWidth);
    float wFar = 1.0 - saturate(abs(stagePos - 1.00) / blendWidth);
    float wSum = max(0.000010, wNear + wForward + wCenter + wBack + wFar);
    float3 blendedShade =
        (nearShade * wNear +
         forwardShade * wForward +
         centerShade * wCenter +
         backShade * wBack +
         farShade * wFar) / wSum;

    if (FDSG2_Stage == 1) return nearShade;
    if (FDSG2_Stage == 2) return forwardShade;
    if (FDSG2_Stage == 3) return centerShade;
    if (FDSG2_Stage == 4) return backShade;
    if (FDSG2_Stage == 5) return farShade;
    return blendedShade;
}

float4 FDSG2_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 sourceColor = FDSG2_Source(uv);
    float depth = FDSG2_Depth(uv);
    float localContrast = FDSG2_LocalContrast(uv);

    float hatchMask = 0.0;
    float verySmallPattern = 0.0;
    float edge = 0.0;
    float depthNear = 0.0;
    float3 stageShade = FDSG2_Shade(uv, sourceColor, depth, localContrast, hatchMask, verySmallPattern, edge, depthNear);

    float effectMix = saturate(FDSG2_MasterIntensity);
    float3 finalColor = lerp(sourceColor, stageShade, effectMix);
    finalColor = FDPOST_Apply(finalColor, FDSG2_PostToneBalance, FDSG2_PostSaturationGuard, FDSG2_PostClipGuard, FDSG2_PostArtifactCleanup);

    if (FDSG2_DebugView == 1) return float4(hatchMask.xxx, 1.0);
    if (FDSG2_DebugView == 2) return float4(verySmallPattern.xxx, 1.0);
    if (FDSG2_DebugView == 3) return float4(depthNear.xxx, 1.0);
    if (FDSG2_DebugView == 4) return float4(edge.xxx, 1.0);
    if (FDSG2_DebugView == 5) return float4(saturate(localContrast * 6.0).xxx, 1.0);
    return float4(saturate(finalColor), 1.0);
}

technique fine_dream_deep_shade_Second_Gate < ui_label = "Fine Cell - Hatch Shading - Five-Stage Bio"; ui_tooltip = "Standalone five-stage bio hatch progression.\nDefault mode blends all stages: near -> forward -> center -> back -> far."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FDSG2_MainPS;
    }
}





