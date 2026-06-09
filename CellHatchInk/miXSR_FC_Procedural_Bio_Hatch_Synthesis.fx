// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: RC-1
// Capability: Procedural bio hatch pattern synthesis and scene blending.



#include "ReShade.fxh"
#include "miXSR_FC_ShaderSharedMaskControls.fxh"
#include "miXSR_FC_OrganicSampling_Lens55.fxh"

uniform int FCOH_DebugView <
    ui_type = "combo";
    ui_label = "Debug View";
    ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 00 Debug"; ui_category_closed = true;
    ui_items = "Final\0Hatch Raw\0Hatch Stabilized\0Mask Raw\0Mask Final\0Depth Gate\0Light Protect Mask\0Fog Bypass\0Computed Mask\0";
ui_tooltip = "Shows final output or diagnostic buffers for hatch synthesis and guard gates.";
> = 0;
uniform float FCOH_DebugExposure < ui_type = "slider"; ui_label = "Debug Exposure"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 00 Debug"; ui_category_closed = true; ui_min = 1.0; ui_max = 32.0; ui_step = 0.1;  ui_tooltip = "Boosts low-signal debug buffers for easier inspection."; > = 1.000000;

uniform float FCOH_NumericFloor < ui_type = "slider"; ui_label = "Numeric Floor"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.000001; ui_max = 0.001000; ui_step = 0.000001;  ui_tooltip = "Controls Numeric Floor."; > = 0.000010;
uniform float FCOH_LumaRed < ui_type = "slider"; ui_label = "Luma Red"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.0001;  ui_tooltip = "Controls Luma Red."; > = 0.212600;
uniform float FCOH_LumaGreen < ui_type = "slider"; ui_label = "Luma Green"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.0001;  ui_tooltip = "Controls Luma Green."; > = 0.715200;
uniform float FCOH_LumaBlue < ui_type = "slider"; ui_label = "Luma Blue"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.0001;  ui_tooltip = "Controls Luma Blue."; > = 0.072200;

uniform float FCOH_MasterIntensity < ui_type = "slider"; ui_label = "Master Intensity"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 02 Main Settings"; ui_min = 0.0; ui_max = 2.5; ui_step = 0.001;  ui_tooltip = "Controls Master Intensity."; > = 2.000000;
uniform float FCOH_Strength < ui_type = "slider"; ui_label = "Hatch Strength"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 02 Main Settings"; ui_min = 0.0; ui_max = 2.5; ui_step = 0.001;  ui_tooltip = "Controls Hatch Strength."; > = 2.000000;
uniform float FCOH_ShadowThreshold < ui_type = "slider"; ui_label = "Shadow Threshold"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 02 Main Settings"; ui_min = 0.0; ui_max = 1.25; ui_step = 0.001;  ui_tooltip = "Controls Shadow Threshold."; > = 1.000000;
uniform float FCOH_ShadowSoftness < ui_type = "slider"; ui_label = "Shadow Softness"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 02 Main Settings"; ui_min = 0.01; ui_max = 1.25; ui_step = 0.001;  ui_tooltip = "Controls Shadow Softness."; > = 1.000000;
uniform float FCOH_PatternScale < ui_type = "slider"; ui_label = "Pattern Scale"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 02 Main Settings"; ui_min = 40.0; ui_max = 1380; ui_step = 0.1;  ui_tooltip = "Controls Pattern Scale."; > = 1042.800049;
uniform float FCOH_Flow < ui_type = "slider"; ui_label = "Pattern Flow"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 02 Main Settings"; ui_min = 0.0; ui_max = 6.0; ui_step = 0.001;  ui_tooltip = "Controls Pattern Flow."; > = 3.740000;
uniform float FCOH_Density < ui_type = "slider"; ui_label = "Line Density"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 02 Main Settings"; ui_min = 0.1; ui_max = 3.5; ui_step = 0.001;  ui_tooltip = "Controls Line Density."; > = 2.098000;
uniform float FCOH_TapSpread < ui_type = "slider"; ui_label = "Tap Spread"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 02 Main Settings"; ui_min = 8.0; ui_max = 180.0; ui_step = 0.01;  ui_tooltip = "Controls Tap Spread."; > = 108.180000;
uniform float FCOH_FibAnchor < ui_type = "slider"; ui_label = "Fibonacci Anchor"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 02 Main Settings"; ui_min = 1597.0; ui_max = 4808.15; ui_step = 1.0;  ui_tooltip = "Controls Fibonacci Anchor."; > = 3575.000000;
uniform float FCOH_DepthAssist < ui_type = "slider"; ui_label = "Depth Assist"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 02 Main Settings"; ui_min = 0.0; ui_max = 1.25; ui_step = 0.001;  ui_tooltip = "Controls Depth Assist."; > = 1.000000;
uniform float FCOH_EdgeAssist < ui_type = "slider"; ui_label = "Edge Assist"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 02 Main Settings"; ui_min = 0.0; ui_max = 1.25; ui_step = 0.001;  ui_tooltip = "Controls Edge Assist."; > = 1.000000;
uniform float FCOH_EdgeRadiusPixels < ui_type = "slider"; ui_label = "Edge Radius"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 02 Main Settings"; ui_min = 0.25; ui_max = 8.0; ui_step = 0.01;  ui_tooltip = "Controls Edge Radius."; > = 0.250000;
uniform float FCOH_EdgeGain < ui_type = "slider"; ui_label = "Edge Gain"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 02 Main Settings"; ui_min = 0.0; ui_max = 128.0; ui_step = 0.01;  ui_tooltip = "Controls Edge Gain."; > = 0.000000;
uniform float FCOH_InkDarken < ui_type = "slider"; ui_label = "Ink Darken"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 02 Main Settings"; ui_min = 0.0; ui_max = 1.1975; ui_step = 0.001;  ui_tooltip = "Controls Ink Darken."; > = 0.958000;
uniform int FCOH_Mode < ui_type = "combo"; ui_label = "Blend Mode"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 02 Main Settings"; ui_items = "Darken\0Multiply\0Overlay\0";  ui_tooltip = "Controls Blend Mode."; > = 0;
uniform int FCOH_RespectFog < ui_type = "combo"; ui_label = "Respect Fog"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0";  ui_tooltip = "Controls Respect Fog."; > = 1;
uniform int FCOH_RespectLight < ui_type = "combo"; ui_label = "Respect Light Emission"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Protects bright emissive pixels from being altered by this pass."; > = 1;
uniform float FCOH_LightProtectStrength < ui_type = "slider"; ui_label = "Light Protect Strength"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "How strongly emissive pixels are restored back to source color."; > = 0.900000;
uniform float FCOH_LightThreshold < ui_type = "slider"; ui_label = "Light Threshold"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Brightness level where the emission protection begins."; > = 0.680000;
uniform float FCOH_LightSoftness < ui_type = "slider"; ui_label = "Light Softness"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.001; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Soft transition width for the light protection gate."; > = 0.180000;
uniform float FCOH_LightPeakInfluence < ui_type = "slider"; ui_label = "Peak Influence"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "Raises protection when one channel is much hotter than the rest."; > = 0.700000;
uniform float FCOH_LightSaturationInfluence < ui_type = "slider"; ui_label = "Saturation Influence"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Adds extra protection for colored emissive lights and neon accents."; > = 0.350000;
uniform float FCOH_LightSaturationThreshold < ui_type = "slider"; ui_label = "Saturation Threshold"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Minimum saturation needed before colored emission gets extra protection."; > = 0.220000;
uniform float FCOH_DepthValidityGate < ui_type = "slider"; ui_label = "Depth Validity Gate"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;  ui_tooltip = "Controls Depth Validity Gate."; > = 0.650000;
uniform float FCOH_BilateralCleanupStrength < ui_type = "slider"; ui_label = "Bilateral Cleanup Strength"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;  ui_tooltip = "Controls Bilateral Cleanup Strength."; > = 0.550000;
uniform float FCOH_ConservativeComposite < ui_type = "slider"; ui_label = "Conservative Composite"; ui_category = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001;  ui_tooltip = "Controls Conservative Composite."; > = 0.850000;

float2 FCOH_Pixel() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
float3 FCOH_Source(float2 uv) { return tex2D(ReShade::BackBuffer, saturate(uv)).rgb; }
float FCOH_Depth(float2 uv) { return ReShade::GetLinearizedDepth(saturate(uv)); }
float FCOH_Luma(float3 c) { return dot(c, normalize(float3(FCOH_LumaRed, FCOH_LumaGreen, FCOH_LumaBlue))); }
float FCOH_DebugScalar(float value) { return pow(saturate(value * max(1.0, FCOH_DebugExposure)), 0.65); }


float FCOH_LightEmissionMask(float3 sourceColor)
{
    if (FCOH_RespectLight == 0)
    {
        return 0.0;
    }

    return FC_LIGHT_EmissionMask(
        sourceColor,
        FCOH_Luma(sourceColor),
        FCOH_LightThreshold,
        FCOH_LightSoftness,
        FCOH_LightPeakInfluence,
        FCOH_LightSaturationInfluence,
        FCOH_LightSaturationThreshold,
        FCOH_NumericFloor);
}

float FCOH_Edge(float2 uv)
{
    float edgeRadius = FCOH_EdgeRadiusPixels;
    float edgeGain = FCOH_EdgeGain;
    float2 px = FCOH_Pixel() * edgeRadius;
    float d0 = FCOH_Depth(uv);
    float d1 = FCOH_Depth(uv + float2( px.x, 0.0));
    float d2 = FCOH_Depth(uv + float2(-px.x, 0.0));
    float d3 = FCOH_Depth(uv + float2(0.0,  px.y));
    float d4 = FCOH_Depth(uv + float2(0.0, -px.y));
    float edgeSum = abs(d0 - d1) + abs(d0 - d2) + abs(d0 - d3) + abs(d0 - d4);
    return saturate(edgeSum * edgeGain);
}

float FCOH_Line(float2 p, float2 dir, float phase, float density)
{
    float v = sin(dot(p, dir) * density + phase);
    return smoothstep(0.72, 0.96, v);
}

float FCOH_OrganicPattern(float2 uv)
{
    float patternScale = FCOH_PatternScale;
    float flow = FCOH_Flow;
    float density = FCOH_Density;
    float tapSpread = FCOH_TapSpread;
    float fibAnchor = FCOH_FibAnchor;

    float2 p = uv * patternScale;
    float t = flow * 0.125;
    float sum = 0.0;
    float weight = 0.0;

    #define FCOH_APPLY_TAP(OFFSET, INDEX) { \
        float2 o = (OFFSET); \
        float fi = fibAnchor + float(INDEX); \
        float2 dir = normalize(float2(0.23 - o.y, 0.17 + o.x + frac(fi * 0.000618))); \
        float phase = fi * 0.013 + t * (0.8 + frac(fi * 0.019)); \
        sum += FCOH_Line(p + o * tapSpread, dir, phase, density); \
        weight += 1.0; \
    }
    FCOH_LENS55_TAPS(FCOH_APPLY_TAP)
    #undef FCOH_APPLY_TAP

    return saturate(sum / max(weight, FCOH_NumericFloor));
}

float FCOH_Mask(float2 uv, float3 src)
{
    float shadowThreshold = FCOH_ShadowThreshold;
    float shadowSoftness = FCOH_ShadowSoftness;
    float depthAssist = FCOH_DepthAssist;
    float edgeAssist = FCOH_EdgeAssist;

    float luma = FCOH_Luma(src);
    float shadow = 1.0 - smoothstep(shadowThreshold, min(1.0, shadowThreshold + shadowSoftness), luma);
    float depth = FCOH_Depth(uv);
    float depthUse = step(FCOH_NumericFloor, depth) * (1.0 - step(1.0 - FCOH_NumericFloor, depth));
    float depthFactor = lerp(0.5, saturate(depth), depthUse);
    float edge = FCOH_Edge(uv);
    float mask = shadow;
    mask *= lerp(1.0, saturate(0.35 + depthFactor * 0.65), depthAssist);
    mask *= lerp(1.0, saturate(0.45 + edge * 0.55), edgeAssist);
    return saturate(mask);
}

float FCOH_DepthValidityMask(float2 uv, float centerDepth)
{
    float2 px = FCOH_Pixel();
    float dR = FCOH_Depth(uv + float2(px.x, 0.0));
    float dL = FCOH_Depth(uv - float2(px.x, 0.0));
    float dU = FCOH_Depth(uv + float2(0.0, px.y));
    float dD = FCOH_Depth(uv - float2(0.0, px.y));
    float slope = abs(dR - dL) + abs(dU - dD);
    float continuity = 1.0 - saturate(slope * 32.0);
    float presence = saturate((abs(dR - centerDepth) + abs(dL - centerDepth) + abs(dU - centerDepth) + abs(dD - centerDepth)) * 64.0);
    float strictMask = continuity * max(0.10, presence);
    return saturate(lerp(1.0, strictMask, saturate(FCOH_DepthValidityGate)));
}

float FCOH_StabilizePattern(float2 uv, float centerDepth, float centerValue)
{
    float strength = saturate(FCOH_BilateralCleanupStrength);
    if (strength <= 0.0001) return centerValue;

    float2 px = FCOH_Pixel();
    float2 uvR = saturate(uv + float2(px.x, 0.0));
    float2 uvL = saturate(uv - float2(px.x, 0.0));
    float2 uvU = saturate(uv + float2(0.0, px.y));
    float2 uvD = saturate(uv - float2(0.0, px.y));

    float dR = FCOH_Depth(uvR);
    float dL = FCOH_Depth(uvL);
    float dU = FCOH_Depth(uvU);
    float dD = FCOH_Depth(uvD);

    float wR = exp(-abs(dR - centerDepth) * 48.0);
    float wL = exp(-abs(dL - centerDepth) * 48.0);
    float wU = exp(-abs(dU - centerDepth) * 48.0);
    float wD = exp(-abs(dD - centerDepth) * 48.0);

    float sumValue = centerValue + FCOH_OrganicPattern(uvR) * wR + FCOH_OrganicPattern(uvL) * wL + FCOH_OrganicPattern(uvU) * wU + FCOH_OrganicPattern(uvD) * wD;
    float sumWeight = 1.0 + wR + wL + wU + wD;
    float filtered = saturate(sumValue / max(FCOH_NumericFloor, sumWeight));
    return lerp(centerValue, filtered, strength);
}
float3 FCOH_Apply(float3 src, float hatch, float mask)
{
    float masterIntensity = FCOH_MasterIntensity;
    float strength = FCOH_Strength;
    float inkDarken = FCOH_InkDarken;
    int mode = FCOH_Mode;

    float blendAmount = saturate(mask * strength * masterIntensity);
    float ink = saturate(hatch * inkDarken);

    if (mode == 1)
    {
        float3 mult = lerp(float3(1.0, 1.0, 1.0), float3(1.0 - ink, 1.0 - ink, 1.0 - ink), blendAmount);
        return src * mult;
    }

    if (mode == 2)
    {
        float3 overlay = lerp(src, src * (1.0 - ink), step(0.5, src));
        return lerp(src, overlay, blendAmount);
    }

    return src * (1.0 - ink * blendAmount);
}

float4 FCOH_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 sourceColor = FCOH_Source(uv);
    float centerDepth = FCOH_Depth(uv);
    float depthGate = FCOH_DepthValidityMask(uv, centerDepth);
    float hatchRaw = FCOH_OrganicPattern(uv);
    float hatch = FCOH_StabilizePattern(uv, centerDepth, hatchRaw);
    float maskRaw = FCOH_Mask(uv, sourceColor);
    float mask = saturate(lerp(maskRaw, maskRaw * depthGate, saturate(FCOH_BilateralCleanupStrength)) * saturate(FCOH_ConservativeComposite));
    float3 outputColor = FCOH_Apply(sourceColor, hatch, mask);
    float lightProtectMask = FCOH_LightEmissionMask(sourceColor);
    outputColor = MIXSR_SHARED_ProtectColor(uv, outputColor, sourceColor, lightProtectMask, FCOH_LightProtectStrength);
    // Use direct fog gate to avoid stale shared-cache ghosting in fog-heavy regions.
    float fogBypass = FC_FOG_BypassMask(uv, sourceColor, FCOH_RespectFog);
    float3 fogRespectedColor = lerp(outputColor, sourceColor, fogBypass);
    float computedMask = saturate(mask * (1.0 - lightProtectMask * 0.75) * (1.0 - fogBypass));

    if (FCOH_DebugView == 1) return float4(FCOH_DebugScalar(hatchRaw).xxx, 1.0);
    if (FCOH_DebugView == 2) return float4(FCOH_DebugScalar(hatch).xxx, 1.0);
    if (FCOH_DebugView == 3) return float4(FCOH_DebugScalar(maskRaw).xxx, 1.0);
    if (FCOH_DebugView == 4) return float4(FCOH_DebugScalar(mask).xxx, 1.0);
    if (FCOH_DebugView == 5) return float4(FCOH_DebugScalar(depthGate).xxx, 1.0);
    if (FCOH_DebugView == 6) return float4(FCOH_DebugScalar(lightProtectMask).xxx, 1.0);
    if (FCOH_DebugView == 7) return float4(FCOH_DebugScalar(fogBypass).xxx, 1.0);
    if (FCOH_DebugView == 8) return float4(FCOH_DebugScalar(computedMask).xxx, 1.0);
    return float4(fogRespectedColor, 1.0);
}
technique miXSR_FC_Procedural_Bio_Hatch_Synthesis < ui_label = "Fine Cell - Hatch Synthesis - Procedural Bio Pattern";  ui_tooltip = "Procedural bio Hatch Synthesis with scene blending controls."; >
{
    pass { VertexShader = PostProcessVS; PixelShader = FCOH_MainPS; }
}












