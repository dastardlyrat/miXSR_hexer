// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: miXSR_FC_organic_ray_marched_ink_stylized-1
// Capability: --Ray-M bio ink-edge stylization with compact --Ray-M support, cel-band tone remap, and light/fog guards and shared-mask orchestration.


// Function: traces compact Fibonacci rays through luma/depth ink support, then
// applies guarded cel-style tone bands and stable ray-guided ink darkening.

#include "ReShade.fxh"
#include "miXSR_FC_ShaderSharedMaskControls.fxh"
#include "miXSR_FC_Lens55Bounded.fxh"

#define FDRMINK_EPS 0.000010

uniform int FDRMINK_PresetTier < ui_type = "combo"; ui_label = "Preset Tier"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 02 Main Settings"; ui_items = "Basic Conservative\0Liberal Coverage\0Aggressive Aggregate\0High Fidelity\0Ultra Fidelity\0"; ui_tooltip = "High Fidelity is the base standard; Ultra raises bounded Lens55 ray direction coverage while keeping ray steps compact."; > = 0;
uniform int FDRMINK_DebugView < ui_type = "combo"; ui_label = "Debug View"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 00 Debug"; ui_category_closed = true; ui_items = "Final\0Ink Mask\0Cel Tone\0Ray Support\0Depth Gate\0Light Zone\0Ray Budget\0Computed Mask\0"; ui_tooltip = "Shows final output or diagnostic buffers."; > = 0;
uniform float FDRMINK_MasterIntensity < ui_type = "slider"; ui_label = "Master Intensity"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Overall multiplier for --Ray-M ink stylization."; > = 1.000000;
uniform float FDRMINK_InkStrength < ui_type = "slider"; ui_label = "Ink Strength"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "How strongly traced ink support darkens the image."; > = 0.230000;
uniform float FDRMINK_StylizeStrength < ui_type = "slider"; ui_label = "Stylize Strength"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 02 Main Settings"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "How strongly cel bands reshape source luminance."; > = 0.430000;
uniform int FDRMINK_CelBands < ui_type = "slider"; ui_label = "Cel Bands"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 2; ui_max = 12; ui_step = 1; ui_tooltip = "Number of tonal bands used by the stylized pass."; > = 5;
uniform float FDRMINK_BandSoftness < ui_type = "slider"; ui_label = "Band Softness"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Blends hard cel bands back toward the source image."; > = 0.420000;
uniform float FDRMINK_EdgeThreshold < ui_type = "slider"; ui_label = "Edge Threshold"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.001; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Minimum combined luma/depth edge response before ink appears."; > = 0.090000;
uniform float FDRMINK_EdgeSoftness < ui_type = "slider"; ui_label = "Edge Softness"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.001; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Soft knee around the edge threshold."; > = 0.115000;
uniform float FDRMINK_LumaEdgeGain < ui_type = "slider"; ui_label = "Luma Edge Gain"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 8.0; ui_step = 0.001; ui_tooltip = "Weight of luminance discontinuities."; > = 2.150000;
uniform float FDRMINK_DepthEdgeGain < ui_type = "slider"; ui_label = "Depth Edge Gain"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 128.0; ui_step = 0.01; ui_tooltip = "Weight of depth discontinuities."; > = 40.000000;
uniform float FDRMINK_RayLengthPixels < ui_type = "slider"; ui_label = "Ray Length"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.5; ui_max = 48.0; ui_step = 0.01; ui_tooltip = "Maximum length of each ink support ray before tier scaling."; > = 7.500000;
uniform int FDRMINK_RaySteps < ui_type = "slider"; ui_label = "Ray Steps"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 2; ui_max = 12; ui_step = 1; ui_tooltip = "Compact ray step budget. High Fidelity defaults to the full 8-step body."; > = 8;
uniform int FDRMINK_TapCount < ui_type = "slider"; ui_label = "Tap Budget"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 4; ui_max = FDREAM_LENS55_TAP_COUNT; ui_step = 1; ui_tooltip = "Bounded Lens55 ray direction budget. High and Ultra fidelity increase coverage without expanding ray-step bodies."; > = 34;
uniform float FDRMINK_TraceStrength < ui_type = "slider"; ui_label = "Trace Strength"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "How strongly ray support reinforces the base ink edge."; > = 0.560000;
uniform float FDRMINK_Thickness < ui_type = "slider"; ui_label = "Depth Thickness"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0001; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Depth hit tolerance for accepting traced ink samples."; > = 0.014000;
uniform float FDRMINK_DepthBias < ui_type = "slider"; ui_label = "Depth Bias"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Self-intersection bias for traced support."; > = 0.001000;
uniform float FDRMINK_DepthGate < ui_type = "slider"; ui_label = "Depth Gate"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Suppresses stylization when depth is unstable."; > = 0.650000;
uniform float FDRMINK_DepthFalloff < ui_type = "slider"; ui_label = "Depth Falloff"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.01; ui_max = 256.0; ui_step = 0.01; ui_tooltip = "Distance falloff shaping for traced ink support."; > = 42.000000;
uniform float FDRMINK_FibAnchor < ui_type = "slider"; ui_label = "Fibonacci Anchor"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 987.0; ui_max = 4181.0; ui_step = 1.0; ui_tooltip = "Anchor index for bio Fibonacci ray directions."; > = 2584.000000;
uniform float FDRMINK_OrganicFlow < ui_type = "slider"; ui_label = "bio Flow"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Stable phase drift for Fibonacci-derived ray direction."; > = 1.350000;
uniform int FDRMINK_RespectFog < ui_type = "combo"; ui_label = "Respect Fog"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Bypasses ink stylization in fog-dominant regions."; > = 1;
uniform int FDRMINK_RespectLight < ui_type = "combo"; ui_label = "Respect Light"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Protects emissive pixels from ink darkening."; > = 1;
uniform float FDRMINK_LightProtectStrength < ui_type = "slider"; ui_label = "Light Protect Strength"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "How strongly protected lights return to source color."; > = 0.900000;
uniform float3 FDRMINK_InkColor < ui_type = "color"; ui_label = "Ink Color"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_tooltip = "Line color used for stylized ink edges."; > = float3(0.020000, 0.018000, 0.015000);
uniform float FDRMINK_DebugExposure < ui_type = "slider"; ui_label = "Debug Exposure"; ui_category = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands / 00 Debug"; ui_category_closed = true; ui_min = 1.0; ui_max = 32.0; ui_step = 0.1; ui_tooltip = "Boosts debug buffer visibility."; > = 8.000000;

float2 FDRMINK_Pixel() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
float3 FDRMINK_Source(float2 uv) { return tex2D(ReShade::BackBuffer, saturate(uv)).rgb; }
float FDRMINK_RawDepth(float2 uv) { return tex2D(ReShade::DepthBuffer, saturate(uv)).r; }
float FDRMINK_Depth(float2 uv) { return saturate(ReShade::GetLinearizedDepth(saturate(uv))); }
float FDRMINK_Luma(float3 color) { return dot(color, float3(0.2126, 0.7152, 0.0722)); }
float FDRMINK_DebugScalar(float value) { return pow(saturate(value * max(1.0, FDRMINK_DebugExposure)), 0.65); }

int FDRMINK_TierTapCap() { return FDREAM_Lens55TierTapCap(FDRMINK_PresetTier); }
int FDRMINK_TierStepCap() { if (FDRMINK_PresetTier == 0) return 4; if (FDRMINK_PresetTier == 1) return 6; return 8; }
float FDRMINK_TierScale() { return FDREAM_Lens55TierScale(FDRMINK_PresetTier); }
float FDRMINK_TierStrength() { if (FDRMINK_PresetTier == 0) return 0.72; if (FDRMINK_PresetTier == 1) return 1.00; if (FDRMINK_PresetTier == 2) return 1.16; if (FDRMINK_PresetTier == 3) return 1.24; return 1.32; }

float FDRMINK_LightMask(float2 uv, float3 sourceColor)
{
    if (FDRMINK_RespectLight == 0)
    {
        return 0.0;
    }

    return MIXSR_SHARED_SharedLightMask(uv, sourceColor, FDRMINK_Luma(sourceColor), 0.680000, 0.180000, 0.700000, 0.350000, 0.220000, FDRMINK_EPS);
}

float FDRMINK_LocalLightZone(float2 uv, float3 sourceColor, float centerLightMask)
{
    if (FDRMINK_RespectLight == 0)
    {
        return 0.0;
    }

    float2 px = FDRMINK_Pixel() * 2.0;
    float zone = centerLightMask;
    zone = max(zone, FDRMINK_LightMask(uv + float2(px.x, 0.0), FDRMINK_Source(uv + float2(px.x, 0.0))));
    zone = max(zone, FDRMINK_LightMask(uv - float2(px.x, 0.0), FDRMINK_Source(uv - float2(px.x, 0.0))));
    zone = max(zone, FDRMINK_LightMask(uv + float2(0.0, px.y), FDRMINK_Source(uv + float2(0.0, px.y))));
    zone = max(zone, FDRMINK_LightMask(uv - float2(0.0, px.y), FDRMINK_Source(uv - float2(0.0, px.y))));
    return saturate(zone * FDRMINK_LightProtectStrength);
}

float FDRMINK_DepthGateMask(float2 uv, float centerDepth)
{
    float2 px = FDRMINK_Pixel();
    float dR = FDRMINK_Depth(uv + float2(px.x, 0.0));
    float dL = FDRMINK_Depth(uv - float2(px.x, 0.0));
    float dU = FDRMINK_Depth(uv + float2(0.0, px.y));
    float dD = FDRMINK_Depth(uv - float2(0.0, px.y));
    float rawDepth = FDRMINK_RawDepth(uv);
    float rangeMask = step(FDRMINK_EPS, rawDepth) * step(rawDepth, 0.999990);
    float slope = abs(dR - dL) + abs(dU - dD);
    float fit = abs(dR - centerDepth) + abs(dL - centerDepth) + abs(dU - centerDepth) + abs(dD - centerDepth);
    float continuity = 1.0 - saturate((slope + fit * 0.25) * 32.0);
    float tierBias = (FDRMINK_PresetTier == 0) ? 0.12 : ((FDRMINK_PresetTier == 1) ? 0.0 : -0.08);
    return saturate(lerp(1.0, rangeMask * continuity, saturate(FDRMINK_DepthGate + tierBias)));
}

float FDRMINK_EdgeAt(float2 uv)
{
    float2 px = FDRMINK_Pixel();
    float3 cC = FDRMINK_Source(uv);
    float lC = FDRMINK_Luma(cC);
    float lR = FDRMINK_Luma(FDRMINK_Source(uv + float2(px.x, 0.0)));
    float lL = FDRMINK_Luma(FDRMINK_Source(uv - float2(px.x, 0.0)));
    float lU = FDRMINK_Luma(FDRMINK_Source(uv + float2(0.0, px.y)));
    float lD = FDRMINK_Luma(FDRMINK_Source(uv - float2(0.0, px.y)));
    float dC = FDRMINK_Depth(uv);
    float dR = FDRMINK_Depth(uv + float2(px.x, 0.0));
    float dL = FDRMINK_Depth(uv - float2(px.x, 0.0));
    float dU = FDRMINK_Depth(uv + float2(0.0, px.y));
    float dD = FDRMINK_Depth(uv - float2(0.0, px.y));
    float lumaEdge = max(max(abs(lR - lC), abs(lL - lC)), max(abs(lU - lC), abs(lD - lC))) * FDRMINK_LumaEdgeGain;
    float depthEdge = max(max(abs(dR - dC), abs(dL - dC)), max(abs(dU - dC), abs(dD - dC))) * FDRMINK_DepthEdgeGain;
    return smoothstep(FDRMINK_EdgeThreshold, FDRMINK_EdgeThreshold + FDRMINK_EdgeSoftness, lumaEdge + depthEdge);
}

float FDRMINK_CleanEdge(float2 uv, float edge)
{
    float2 px = FDRMINK_Pixel();
    float eR = FDRMINK_EdgeAt(uv + float2(px.x, 0.0));
    float eL = FDRMINK_EdgeAt(uv - float2(px.x, 0.0));
    float eU = FDRMINK_EdgeAt(uv + float2(0.0, px.y));
    float eD = FDRMINK_EdgeAt(uv - float2(0.0, px.y));
    float neighbor = (eR + eL + eU + eD) * 0.25;
    return saturate(max(edge * 0.72, neighbor));
}

float2 FDRMINK_FibonacciDirection(float fibIndex)
{
    const float goldenAngle = 2.39996323;
    float angle = fibIndex * goldenAngle;
    return float2(cos(angle), sin(angle));
}

float2 FDRMINK_OrganicDirection(float2 lensOffset, float fibIndex, float2 uv, float tapNorm)
{
    float2 fibDir = FDRMINK_FibonacciDirection(fibIndex);
    float2 lensDir = normalize(float2(0.23 - lensOffset.y, 0.17 + lensOffset.x + frac(fibIndex * 0.000618)));
    float2 baseDir = normalize(lerp(lensDir, fibDir, 0.46 + 0.22 * tapNorm));
    float phase = fibIndex * 0.013 + FDRMINK_OrganicFlow * 0.18 + dot(uv * 80.0, float2(0.754, 0.569));
    float cs = cos(phase);
    float sn = sin(phase);
    return normalize(float2(baseDir.x * cs - baseDir.y * sn, baseDir.x * sn + baseDir.y * cs));
}

void FDRMINK_AccumulateRayStep(float2 uv, float centerDepth, float centerLuma, float2 rayStep, int stepIndex, int raySteps, float invRaySteps, float thickness, float depthEdge, float depthFalloff, inout float supportSum, inout float weightSum)
{
    if (stepIndex <= raySteps)
    {
        float t = float(stepIndex) * invRaySteps;
        float2 sampleUv = uv + rayStep * t;
        float3 sampleColor = FDRMINK_Source(sampleUv);
        float sampleLuma = FDRMINK_Luma(sampleColor);
        float sampleDepth = FDRMINK_Depth(sampleUv);
        float depthDelta = abs(sampleDepth - centerDepth);
        float depthMatch = 1.0 - smoothstep(thickness, depthEdge, depthDelta);
        float behindMask = step(centerDepth - FDRMINK_DepthBias, sampleDepth);
        float edge = FDRMINK_EdgeAt(sampleUv);
        float toneMark = saturate(abs(sampleLuma - centerLuma) * FDRMINK_LumaEdgeGain);
        float distanceWeight = exp(-t * depthFalloff * 0.0100);
        float hit = saturate((edge + toneMark * 0.32) * (depthMatch * 0.75 + behindMask * 0.25) * distanceWeight);
        supportSum += hit;
        weightSum += distanceWeight;
    }
}

void FDRMINK_RayMarchDirection(float2 uv, float centerDepth, float centerLuma, float2 direction, int raySteps, float rayGrowth, out float support, out float weight)
{
    float2 rayStep = direction * FDRMINK_Pixel() * FDRMINK_RayLengthPixels * FDRMINK_TierScale() * rayGrowth;
    float invRaySteps = rcp(max(1.0, float(raySteps)));
    float thickness = max(0.0001, FDRMINK_Thickness);
    float depthEdge = thickness * 2.0 + FDRMINK_EPS;
    float depthFalloff = max(0.01, FDRMINK_DepthFalloff);
    support = 0.0;
    weight = 0.0;

    #define FDRMINK_RAY_STEP(STEP_INDEX) FDRMINK_AccumulateRayStep(uv, centerDepth, centerLuma, rayStep, (STEP_INDEX), raySteps, invRaySteps, thickness, depthEdge, depthFalloff, support, weight);
    FDRMINK_RAY_STEP(1)
    FDRMINK_RAY_STEP(2)
    FDRMINK_RAY_STEP(3)
    FDRMINK_RAY_STEP(4)
    FDRMINK_RAY_STEP(5)
    FDRMINK_RAY_STEP(6)
    FDRMINK_RAY_STEP(7)
    FDRMINK_RAY_STEP(8)
    #undef FDRMINK_RAY_STEP
}

void FDRMINK_AccumulateTap(float2 uv, float centerDepth, float centerLuma, float2 offset, int index, int tapCount, int raySteps, inout float supportSum, inout float weightSum)
{
    if (index < tapCount)
    {
        float tapNorm = (float(index) + 0.5) / max(1.0, float(tapCount));
        float fibIndex = FDRMINK_FibAnchor + float(index);
        float2 direction = FDRMINK_OrganicDirection(offset, fibIndex, uv, tapNorm);
        float rayGrowth = FDREAM_Lens55FibonacciGrowth(index, tapCount);
        float support = 0.0;
        float weight = 0.0;
        FDRMINK_RayMarchDirection(uv, centerDepth, centerLuma, direction, raySteps, rayGrowth, support, weight);
        supportSum += support * (1.0 - tapNorm * 0.12);
        weightSum += weight;
    }
}

float3 FDRMINK_ApplyCelTone(float3 sourceColor, float sourceLuma)
{
    float bands = max(2.0, float(FDRMINK_CelBands));
    float hardBand = floor(sourceLuma * bands + 0.5) / bands;
    float softBand = lerp(hardBand, sourceLuma, saturate(FDRMINK_BandSoftness));
    float3 celColor = saturate(sourceColor * (softBand / max(FDRMINK_EPS, sourceLuma)));
    return lerp(sourceColor, celColor, FDRMINK_StylizeStrength);
}

float4 FDRMINK_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    int tapCount = min(clamp(FDRMINK_TapCount, 1, FDREAM_LENS55_TAP_COUNT), FDRMINK_TierTapCap());
    int raySteps = min(clamp(FDRMINK_RaySteps, 1, 8), FDRMINK_TierStepCap());
    float3 sourceColor = FDRMINK_Source(uv);
    float sourceLuma = FDRMINK_Luma(sourceColor);
    float centerDepth = FDRMINK_Depth(uv);
    float depthGate = FDRMINK_DepthGateMask(uv, centerDepth);
    float baseEdge = FDRMINK_CleanEdge(uv, FDRMINK_EdgeAt(uv));
    float supportSum = baseEdge;
    float weightSum = 1.0;

    [loop]
    for (int tapIndex = 0; tapIndex < FDREAM_LENS55_TAP_COUNT; ++tapIndex)
    {
        if (tapIndex < tapCount)
        {
            FDRMINK_AccumulateTap(uv, centerDepth, sourceLuma, FDREAM_Lens55Offset(tapIndex), tapIndex, tapCount, raySteps, supportSum, weightSum);
        }
    }

    float raySupport = supportSum / max(FDRMINK_EPS, weightSum);
    float lightMask = FDRMINK_LightMask(uv, sourceColor);
    float lightZone = FDRMINK_LocalLightZone(uv, sourceColor, lightMask);
    float computedMask = saturate((baseEdge + raySupport * FDRMINK_TraceStrength) * depthGate * (1.0 - lightZone * 0.75));
    float inkMask = saturate(computedMask * FDRMINK_InkStrength * FDRMINK_MasterIntensity * FDRMINK_TierStrength());

    float3 stylizedColor = FDRMINK_ApplyCelTone(sourceColor, sourceLuma);
    stylizedColor = lerp(sourceColor, stylizedColor, depthGate * (1.0 - lightZone * 0.65));
    float3 effectColor = lerp(stylizedColor, FDRMINK_InkColor, inkMask);

    effectColor = MIXSR_SHARED_ProtectColor(uv, effectColor, sourceColor, lightMask, FDRMINK_LightProtectStrength);
    // Use direct fog gate to avoid stale shared-cache ghosting in fog-heavy regions.
    float fogBypass = FC_FOG_BypassMask(uv, sourceColor, FDRMINK_RespectFog);
    effectColor = lerp(effectColor, sourceColor, fogBypass);
    float budgetView = saturate(float(tapCount * raySteps) / float(FDREAM_LENS55_TAP_COUNT * 8));

    if (FDRMINK_DebugView == 1) return float4(FDRMINK_DebugScalar(inkMask).xxx, 1.0);
    if (FDRMINK_DebugView == 2) return float4(FDRMINK_Luma(stylizedColor).xxx, 1.0);
    if (FDRMINK_DebugView == 3) return float4(FDRMINK_DebugScalar(raySupport).xxx, 1.0);
    if (FDRMINK_DebugView == 4) return float4(FDRMINK_DebugScalar(depthGate).xxx, 1.0);
    if (FDRMINK_DebugView == 5) return float4(FDRMINK_DebugScalar(lightZone).xxx, 1.0);
    if (FDRMINK_DebugView == 6) return float4(FDRMINK_DebugScalar(budgetView).xxx, 1.0);
    if (FDRMINK_DebugView == 7) return float4(FDRMINK_DebugScalar(computedMask).xxx, 1.0);
    return float4(saturate(effectColor), 1.0);
}
technique miXSR_FC_bio_raym_ink_stylized < ui_label = "Fine Cell - Ink Stylization - Bio Ray-M Edge Bands"; ui_tooltip = "Fibonacci bio --Ray-M ink edge stylization with cel tone bands, compact 8-step traces, and light/fog guards."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FDRMINK_MainPS;
    }
}




















