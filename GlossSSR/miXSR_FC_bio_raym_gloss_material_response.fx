// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: miXSR_FC_organic_ray_marched_gloss-1
// Capability: Portable Fibonacci bio --Ray-M gloss from SSR-style tracing and bloom-style highlight diffusion and shared-mask orchestration.



#include "ReShade.fxh"
#include "miXSR_FC_ShaderSharedMaskControls.fxh"
#include "miXSR_FC_Lens55Bounded.fxh"

texture2D FDRMGLOSS_HistoryTex
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

sampler2D FDRMGLOSS_HistorySampler
{
    Texture = FDRMGLOSS_HistoryTex;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = NONE;
};

uniform int FDRMGLOSS_PresetTier < ui_type = "combo"; ui_label = "Preset Tier"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 02 Main Settings"; ui_items = "Basic Conservative\0Liberal Coverage\0Aggressive Aggregate\0High Fidelity\0Ultra Fidelity\0"; ui_tooltip = "High Fidelity is the base standard; Ultra raises bounded Lens55 ray direction coverage while keeping ray steps compact."; > = 3;
uniform int FDRMGLOSS_DebugView < ui_type = "combo"; ui_label = "Debug View"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 00 Debug"; ui_category_closed = true; ui_items = "Final\0Application Mask\0Gloss Color\0Normal\0Depth Gate\0Ray Budget\0Computed Mask\0"; ui_tooltip = "Shows the final output or diagnostic masks."; > = 0;
uniform float FDRMGLOSS_DebugExposure < ui_type = "slider"; ui_label = "Debug Exposure"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 00 Debug"; ui_category_closed = true; ui_min = 0.25; ui_max = 8.0; ui_step = 0.01; ui_tooltip = "Scales diagnostic intensity for low-signal debug views."; > = 1.000000;
uniform float FDRMGLOSS_MasterIntensity < ui_type = "slider"; ui_label = "Master Intensity"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Overall multiplier for --Ray-M gloss."; > = 1.000000;
uniform float FDRMGLOSS_GlossStrength < ui_type = "slider"; ui_label = "Gloss Strength"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "How strongly traced glossy hits blend into the scene."; > = 0.480000;
uniform float FDRMGLOSS_BloomStrength < ui_type = "slider"; ui_label = "Bloom Diffusion"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Soft bloom-style diffusion around traced highlights."; > = 0.140000;
uniform float FDRMGLOSS_Threshold < ui_type = "slider"; ui_label = "Highlight Threshold"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Brightness where ray gloss extraction starts."; > = 0.700000;
uniform float FDRMGLOSS_Softness < ui_type = "slider"; ui_label = "Highlight Softness"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.001; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Soft knee around the gloss threshold."; > = 0.260000;
uniform float FDRMGLOSS_RayLengthPixels < ui_type = "slider"; ui_label = "Ray Length"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.5; ui_max = 64.0; ui_step = 0.01; ui_tooltip = "Maximum length of each gloss ray in screen pixels before tier scaling."; > = 11.000000;
uniform int FDRMGLOSS_RaySteps < ui_type = "slider"; ui_label = "Ray Steps"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 2; ui_max = 12; ui_step = 1; ui_tooltip = "Maximum compact ray steps available to the active tier. High Fidelity defaults to the full 8-step body."; > = 8;
uniform int FDRMGLOSS_TapCount < ui_type = "slider"; ui_label = "Tap Budget"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 4; ui_max = FDREAM_LENS55_TAP_COUNT; ui_step = 1; ui_tooltip = "Bounded Lens55 ray direction budget. High and Ultra fidelity increase tap coverage without expanding ray-step bodies."; > = 34;
uniform float FDRMGLOSS_Thickness < ui_type = "slider"; ui_label = "Depth Thickness"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0001; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Depth hit tolerance for accepting glossy ray samples."; > = 0.012000;
uniform float FDRMGLOSS_DepthBias < ui_type = "slider"; ui_label = "Depth Bias"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Self-intersection bias for glossy ray hits."; > = 0.001000;
uniform float FDRMGLOSS_DepthFalloff < ui_type = "slider"; ui_label = "Depth Falloff"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.01; ui_max = 256.0; ui_step = 0.01; ui_tooltip = "Distance falloff applied along accepted ray hits."; > = 48.000000;
uniform float FDRMGLOSS_DepthGate < ui_type = "slider"; ui_label = "Depth Gate"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Suppresses gloss when depth is unstable."; > = 0.650000;
uniform float FDRMGLOSS_NormalStrength < ui_type = "slider"; ui_label = "Normal Strength"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.1; ui_max = 24.0; ui_step = 0.1; ui_tooltip = "Strength multiplier for depth-derived normals."; > = 5.000000;
uniform float FDRMGLOSS_FibAnchor < ui_type = "slider"; ui_label = "Fibonacci Anchor"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 987.0; ui_max = 4181.0; ui_step = 1.0; ui_tooltip = "Anchor index for bio Fibonacci ray directions."; > = 2584.000000;
uniform float FDRMGLOSS_OrganicFlow < ui_type = "slider"; ui_label = "bio Flow"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Phase drift for Fibonacci-derived ray direction."; > = 1.400000;
uniform float FDRMGLOSS_Roughness < ui_type = "slider"; ui_label = "Roughness Spread"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Broadens reflected ray direction for softer gloss."; > = 0.300000;
uniform float FDRMGLOSS_Saturation < ui_type = "slider"; ui_label = "Gloss Saturation"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Saturation of glossy highlight color."; > = 1.080000;
uniform float FDRMGLOSS_EdgeCrispness < ui_type = "slider"; ui_label = "Edge Crispness"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.5; ui_max = 6.0; ui_step = 0.01; ui_tooltip = "Pre-apply edge gate. Higher values keep gloss off unstable silhouettes before blending."; > = 2.250000;
uniform float FDRMGLOSS_BlendSoftness < ui_type = "slider"; ui_label = "Blend Softness"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "Softens application mask roll-in for less harsh transitions while preserving detail."; > = 0.720000;
uniform float FDRMGLOSS_PronouncedLift < ui_type = "slider"; ui_label = "Pronounced Lift"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.5; ui_step = 0.001; ui_tooltip = "Boosts gloss presence after edge gating without flattening the scene."; > = 0.500000;
uniform int FDRMGLOSS_RespectFog < ui_type = "combo"; ui_label = "Respect Fog"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Bypasses gloss in fog-dominant regions."; > = 1;
uniform int FDRMGLOSS_RespectLight < ui_type = "combo"; ui_label = "Respect Light Emission"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Protects emissive pixels from being altered."; > = 1;
uniform float FDRMGLOSS_LightProtectStrength < ui_type = "slider"; ui_label = "Light Protect Strength"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "How strongly protected lights return to source color."; > = 0.850000;
uniform float FDRMGLOSS_HistoryStrength < ui_type = "slider"; ui_label = "History Strength"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.127; ui_step = 0.001; ui_tooltip = "Temporal blend amount used to suppress shimmer in gloss highlights."; > = 0.780000;
uniform float FDRMGLOSS_HistoryClamp < ui_type = "slider"; ui_label = "History Clamp"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 0.500; ui_step = 0.001; ui_tooltip = "Color clamp radius around current frame to avoid ghosting trails."; > = 0.120000;
uniform float FDRMGLOSS_HistoryReject < ui_type = "slider"; ui_label = "History Reject"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Rejects history when current frame diverges strongly (camera cuts, hard disocclusion)."; > = 0.240000;
uniform float FDRMGLOSS_HistoryDepthReject < ui_type = "slider"; ui_label = "History Depth Reject"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.000; ui_max = 0.200; ui_step = 0.0001; ui_tooltip = "Depth disagreement threshold used to drop stale history."; > = 0.010000;
uniform int FDRMGLOSS_HistoryReset < ui_type = "combo"; ui_label = "History Reset"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask / 03 Sub Settings"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Temporarily disables history accumulation to flush stale shimmer state."; > = 0;
float2 FDRMGLOSS_Pixel() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
float3 FDRMGLOSS_Source(float2 uv) { return tex2D(ReShade::BackBuffer, saturate(uv)).rgb; }
float FDRMGLOSS_RawDepth(float2 uv) { return tex2D(ReShade::DepthBuffer, saturate(uv)).r; }
float FDRMGLOSS_Depth(float2 uv) { return saturate(ReShade::GetLinearizedDepth(saturate(uv))); }
float FDRMGLOSS_Luma(float3 color) { return dot(color, float3(0.2126, 0.7152, 0.0722)); }
float3 FDRMGLOSS_SaturateAroundLuma(float3 color, float amount) { float luma = FDRMGLOSS_Luma(color); return lerp(luma.xxx, color, amount); }
float FDRMGLOSS_DebugScalar(float value) { return pow(saturate(value * max(1.0, FDRMGLOSS_DebugExposure)), 0.65); }

int FDRMGLOSS_TierTapCap() { return FDREAM_Lens55TierTapCap(FDRMGLOSS_PresetTier); }
int FDRMGLOSS_TierStepCap() { if (FDRMGLOSS_PresetTier == 0) return 4; if (FDRMGLOSS_PresetTier == 1) return 6; return 8; }
float FDRMGLOSS_TierLengthScale() { return FDREAM_Lens55TierScale(FDRMGLOSS_PresetTier); }
float FDRMGLOSS_TierStrengthScale() { if (FDRMGLOSS_PresetTier == 0) return 0.72; if (FDRMGLOSS_PresetTier == 1) return 1.00; if (FDRMGLOSS_PresetTier == 2) return 1.18; if (FDRMGLOSS_PresetTier == 3) return 1.25; return 1.32; }

float FDRMGLOSS_LightEmissionMask(float2 uv, float3 sourceColor)
{
    if (FDRMGLOSS_RespectLight == 0)
    {
        return 0.0;
    }

    return MIXSR_SHARED_SharedLightMask(uv, sourceColor, FDRMGLOSS_Luma(sourceColor), 0.680000, 0.180000, 0.700000, 0.350000, 0.220000, 0.000010);
}

float FDRMGLOSS_LocalLightZone(float2 uv, float3 sourceColor, float centerLightMask)
{
    if (FDRMGLOSS_RespectLight == 0)
    {
        return 0.0;
    }

    float2 px = FDRMGLOSS_Pixel() * 2.0;
    float zone = centerLightMask;
    zone = max(zone, FDRMGLOSS_LightEmissionMask(uv + float2(px.x, 0.0), FDRMGLOSS_Source(uv + float2(px.x, 0.0))));
    zone = max(zone, FDRMGLOSS_LightEmissionMask(uv - float2(px.x, 0.0), FDRMGLOSS_Source(uv - float2(px.x, 0.0))));
    zone = max(zone, FDRMGLOSS_LightEmissionMask(uv + float2(0.0, px.y), FDRMGLOSS_Source(uv + float2(0.0, px.y))));
    zone = max(zone, FDRMGLOSS_LightEmissionMask(uv - float2(0.0, px.y), FDRMGLOSS_Source(uv - float2(0.0, px.y))));
    return saturate(zone * FDRMGLOSS_LightProtectStrength);
}

float3 FDRMGLOSS_Normal(float2 uv, out float edgeFactor)
{
    float2 px = FDRMGLOSS_Pixel();
    float dC = FDRMGLOSS_Depth(uv);
    float dR = FDRMGLOSS_Depth(uv + float2(px.x, 0.0));
    float dL = FDRMGLOSS_Depth(uv - float2(px.x, 0.0));
    float dU = FDRMGLOSS_Depth(uv + float2(0.0, px.y));
    float dD = FDRMGLOSS_Depth(uv - float2(0.0, px.y));
    float gradX = (abs(dR - dC) < abs(dC - dL)) ? (dR - dC) : (dC - dL);
    float gradY = (abs(dU - dC) < abs(dC - dD)) ? (dU - dC) : (dC - dD);
    edgeFactor = saturate((abs(gradX) + abs(gradY)) * 64.0);
    float3 n = normalize(float3(-gradX * FDRMGLOSS_NormalStrength, -gradY * FDRMGLOSS_NormalStrength, 1.0));
    n.z = abs(n.z);
    return normalize(n);
}

float FDRMGLOSS_DepthGateMask(float2 uv, float centerDepth)
{
    float2 px = FDRMGLOSS_Pixel();
    float dR = FDRMGLOSS_Depth(uv + float2(px.x, 0.0));
    float dL = FDRMGLOSS_Depth(uv - float2(px.x, 0.0));
    float dU = FDRMGLOSS_Depth(uv + float2(0.0, px.y));
    float dD = FDRMGLOSS_Depth(uv - float2(0.0, px.y));
    float rawDepth = FDRMGLOSS_RawDepth(uv);
    float rangeMask = step(0.000010, rawDepth) * step(rawDepth, 0.999990);
    float slope = abs(dR - dL) + abs(dU - dD);
    float fit = abs(dR - centerDepth) + abs(dL - centerDepth) + abs(dU - centerDepth) + abs(dD - centerDepth);
    float continuity = 1.0 - saturate((slope + fit * 0.25) * 30.0);
    float tierBias = (FDRMGLOSS_PresetTier == 0) ? 0.12 : ((FDRMGLOSS_PresetTier == 1) ? 0.0 : -0.08);
    return saturate(lerp(1.0, rangeMask * continuity, saturate(FDRMGLOSS_DepthGate + tierBias)));
}

float FDRMGLOSS_BrightMask(float3 color)
{
    return smoothstep(FDRMGLOSS_Threshold, FDRMGLOSS_Threshold + max(0.000010, FDRMGLOSS_Softness), FDRMGLOSS_Luma(color));
}

float2 FDRMGLOSS_FibonacciDirection(float fibIndex)
{
    const float goldenAngle = 2.39996323;
    float angle = fibIndex * goldenAngle;
    return float2(cos(angle), sin(angle));
}

float2 FDRMGLOSS_OrganicDirection(float2 lensOffset, float fibIndex, float2 uv, float3 centerNormal, float tapNorm)
{
    float2 normalSlide = normalize(centerNormal.xy + float2(0.0001, 0.0001));
    float2 dir = normalize(FDRMGLOSS_FibonacciDirection(fibIndex));
    float phaseBase = fibIndex * 0.013 + FDRMGLOSS_OrganicFlow * 0.18 + dot(uv * 80.0, float2(0.754, 0.569));

    [unroll]
    for (int recursion = 0; recursion < 3; ++recursion)
    {
        float recursionF = float(recursion);
        float recursiveIndex = fibIndex + (recursionF + 1.0) * (1.6180339 + tapNorm * 0.5);
        float2 fibStep = normalize(FDRMGLOSS_FibonacciDirection(recursiveIndex));
        float angle = 2.39996323 * (0.33 + 0.21 * recursionF) + phaseBase * (0.55 + 0.18 * recursionF);
        float cs = cos(angle);
        float sn = sin(angle);
        float2 rotated = float2(dir.x * cs - dir.y * sn, dir.x * sn + dir.y * cs);
        dir = normalize(lerp(rotated, fibStep, 0.42 + 0.08 * recursionF));
    }

    float normalMix = 0.18 + FDRMGLOSS_Roughness * 0.32;
    return normalize(lerp(dir, normalSlide, normalMix));
}

void FDRMGLOSS_AccumulateRayStep(float2 uv, float centerDepth, float2 rayStep, int stepIndex, int raySteps, float invRaySteps, float thickness, float depthEdge, float depthFalloff, inout float3 tightColor, inout float tightWeight, inout float3 broadColor, inout float broadWeight)
{
    if (stepIndex <= raySteps)
    {
        float t = float(stepIndex) * invRaySteps;
        float2 sampleUv = uv + rayStep * t;
        float3 sampleColor = FDRMGLOSS_Source(sampleUv);
        float sampleDepth = FDRMGLOSS_Depth(sampleUv);
        float depthDelta = sampleDepth - centerDepth;
        float depthMatch = 1.0 - smoothstep(thickness, depthEdge, abs(depthDelta));
        float behindMask = step(centerDepth - FDRMGLOSS_DepthBias, sampleDepth);
        float brightMask = FDRMGLOSS_BrightMask(sampleColor);
        float tightDistance = exp(-t * depthFalloff * 0.0125);
        float broadDistance = exp(-t * depthFalloff * 0.0060);
        float tightHit = saturate(depthMatch * behindMask * brightMask * tightDistance);
        float broadHit = saturate((depthMatch * 0.65 + 0.35 * behindMask) * brightMask * broadDistance);
        tightColor += sampleColor * tightHit;
        tightWeight += tightHit;
        broadColor += sampleColor * broadHit;
        broadWeight += broadHit;
    }
}

void FDRMGLOSS_RayMarchDirection(float2 uv, float centerDepth, float2 direction, int raySteps, float rayGrowth, out float3 tightColor, out float tightWeight, out float3 broadColor, out float broadWeight)
{
    float2 rayStep = direction * FDRMGLOSS_Pixel() * FDRMGLOSS_RayLengthPixels * FDRMGLOSS_TierLengthScale() * rayGrowth;
    float invRaySteps = rcp(max(1.0, float(raySteps)));
    float thickness = max(0.0001, FDRMGLOSS_Thickness);
    float depthEdge = thickness * 2.0 + 0.000010;
    float depthFalloff = max(0.01, FDRMGLOSS_DepthFalloff);
    tightColor = 0.0;
    tightWeight = 0.0;
    broadColor = 0.0;
    broadWeight = 0.0;

    #define FDRMGLOSS_RAY_STEP(STEP_INDEX) FDRMGLOSS_AccumulateRayStep(uv, centerDepth, rayStep, (STEP_INDEX), raySteps, invRaySteps, thickness, depthEdge, depthFalloff, tightColor, tightWeight, broadColor, broadWeight);
    FDRMGLOSS_RAY_STEP(1)
    FDRMGLOSS_RAY_STEP(2)
    FDRMGLOSS_RAY_STEP(3)
    FDRMGLOSS_RAY_STEP(4)
    FDRMGLOSS_RAY_STEP(5)
    FDRMGLOSS_RAY_STEP(6)
    FDRMGLOSS_RAY_STEP(7)
    FDRMGLOSS_RAY_STEP(8)
    #undef FDRMGLOSS_RAY_STEP
}

void FDRMGLOSS_AccumulateTap(float2 uv, float centerDepth, float3 centerNormal, float2 lensOffset, int tapIndex, int tapCount, int raySteps, inout float3 tightSum, inout float tightWeight, inout float3 broadSum, inout float broadWeight)
{
    float3 tightColor = 0.0;
    float tightHit = 0.0;
    float3 broadColor = 0.0;
    float broadHit = 0.0;

    if (tapIndex < tapCount)
    {
        float tapNorm = (float(tapIndex) + 0.5) / max(1.0, float(tapCount));
        float fibIndex = FDRMGLOSS_FibAnchor + float(tapIndex);
        float2 direction = FDRMGLOSS_OrganicDirection(lensOffset, fibIndex, uv, centerNormal, tapNorm);
        float rayGrowth = FDREAM_Lens55FibonacciGrowth(tapIndex, tapCount);
        FDRMGLOSS_RayMarchDirection(uv, centerDepth, direction, raySteps, rayGrowth, tightColor, tightHit, broadColor, broadHit);
        tightSum += tightColor;
        tightWeight += tightHit;
        broadSum += broadColor;
        broadWeight += broadHit;
    }
}

float3 FDRMGLOSS_Temporal(float2 uv, float3 currentColor, float3 sourceColor, float centerDepth, float applicationMask)
{
    if (FDRMGLOSS_HistoryReset != 0)
    {
        return currentColor;
    }

    float3 historyColor = tex2D(FDRMGLOSS_HistorySampler, saturate(uv)).rgb;
    float3 lo = currentColor - FDRMGLOSS_HistoryClamp;
    float3 hi = currentColor + FDRMGLOSS_HistoryClamp;
    float3 clampedHistory = clamp(historyColor, lo, hi);

    float historyDelta = abs(dot(currentColor - historyColor, float3(0.2126, 0.7152, 0.0722)));
    float depthDelta = abs(FDRMGLOSS_Depth(uv) - centerDepth);
    float rejectColor = smoothstep(FDRMGLOSS_HistoryReject, FDRMGLOSS_HistoryReject + 0.150000, historyDelta);
    float rejectDepth = smoothstep(FDRMGLOSS_HistoryDepthReject, FDRMGLOSS_HistoryDepthReject + 0.030000, depthDelta);
    float reject = saturate(max(rejectColor, rejectDepth));

    float blend = saturate(FDRMGLOSS_HistoryStrength * (1.0 - reject) * (0.35 + 0.65 * saturate(applicationMask)));
    float3 stabilized = lerp(currentColor, clampedHistory, blend);
    return saturate(stabilized);
}

float4 FDRMGLOSS_HistoryStorePS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    return float4(tex2D(ReShade::BackBuffer, saturate(uv)).rgb, 1.0);
}


float4 FDRMGLOSS_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    int tapCount = min(clamp(FDRMGLOSS_TapCount, 1, FDREAM_LENS55_TAP_COUNT), FDRMGLOSS_TierTapCap());
    int raySteps = min(clamp(FDRMGLOSS_RaySteps, 1, 8), FDRMGLOSS_TierStepCap());
    float3 sourceColor = FDRMGLOSS_Source(uv);
    float centerDepth = FDRMGLOSS_Depth(uv);
    float edgeFactor = 0.0;
    float3 centerNormal = FDRMGLOSS_Normal(uv, edgeFactor);
    float depthGate = FDRMGLOSS_DepthGateMask(uv, centerDepth);
    float centerMask = FDRMGLOSS_BrightMask(sourceColor);
    float3 tightSum = sourceColor * centerMask;
    float tightWeight = max(0.000010, centerMask);
    float3 broadSum = sourceColor * centerMask;
    float broadWeight = max(0.000010, centerMask);

    [loop]
    for (int tapIndex = 0; tapIndex < FDREAM_LENS55_TAP_COUNT; ++tapIndex)
    {
        if (tapIndex < tapCount)
        {
            FDRMGLOSS_AccumulateTap(uv, centerDepth, centerNormal, FDREAM_Lens55Offset(tapIndex), tapIndex, tapCount, raySteps, tightSum, tightWeight, broadSum, broadWeight);
        }
    }

    float3 tightGloss = tightSum / max(0.000010, tightWeight);
    float3 broadGloss = broadSum / max(0.000010, broadWeight);
    float aggregateBlend = (FDRMGLOSS_PresetTier >= 4) ? 0.72 : ((FDRMGLOSS_PresetTier == 3) ? 0.64 : ((FDRMGLOSS_PresetTier == 2) ? 0.60 : ((FDRMGLOSS_PresetTier == 1) ? 0.38 : 0.18)));
    float3 glossColor = lerp(tightGloss, broadGloss, aggregateBlend);
    glossColor = FDRMGLOSS_SaturateAroundLuma(glossColor, FDRMGLOSS_Saturation);
    float hitCoverage = saturate((tightWeight + broadWeight) / max(1.0, float(tapCount * raySteps)));
    float edgeGate = pow(saturate(1.0 - edgeFactor), max(0.50, FDRMGLOSS_EdgeCrispness));
    float hitMask = hitCoverage * depthGate * edgeGate;
    float lightProtectMask = FDRMGLOSS_LightEmissionMask(uv, sourceColor);
    float lightZone = FDRMGLOSS_LocalLightZone(uv, sourceColor, lightProtectMask);
    float applicationMaskRaw = saturate(hitMask * (1.0 - lightZone * 0.75));
    float softPower = lerp(1.40, 0.72, saturate(FDRMGLOSS_BlendSoftness));
    float applicationMask = pow(applicationMaskRaw, softPower);

    float glossGain = applicationMask * FDRMGLOSS_GlossStrength * FDRMGLOSS_MasterIntensity * FDRMGLOSS_TierStrengthScale() * (1.0 + 0.85 * FDRMGLOSS_PronouncedLift);
    float computedMask = saturate(glossGain);
    float3 glossLift = saturate(glossColor - sourceColor);
    float3 additiveGloss = sourceColor + glossLift * glossGain;
    float3 screenGloss = 1.0 - (1.0 - sourceColor) * (1.0 - saturate(glossColor * glossGain));
    float3 effectColor = lerp(additiveGloss, screenGloss, 0.58 + 0.22 * saturate(FDRMGLOSS_BlendSoftness));
    effectColor += broadGloss * applicationMask * FDRMGLOSS_BloomStrength * FDRMGLOSS_MasterIntensity * (1.0 + 0.50 * FDRMGLOSS_PronouncedLift);

    effectColor = MIXSR_SHARED_ProtectColor(uv, effectColor, sourceColor, lightProtectMask, FDRMGLOSS_LightProtectStrength);
    float fogBypass = MIXSR_SHARED_SharedFogBypass(uv, sourceColor, FDRMGLOSS_RespectFog);
    effectColor = lerp(effectColor, sourceColor, fogBypass);
    float tierMaxBudget = max(1.0, float(FDRMGLOSS_TierTapCap() * FDRMGLOSS_TierStepCap()));
    float budgetView = saturate(float(tapCount * raySteps) / tierMaxBudget);

    if (FDRMGLOSS_DebugView == 1) return float4(FDRMGLOSS_DebugScalar(applicationMask).xxx, 1.0);
    if (FDRMGLOSS_DebugView == 2) return float4(saturate(glossColor), 1.0);
    if (FDRMGLOSS_DebugView == 3) return float4(centerNormal * 0.5 + 0.5, 1.0);
    if (FDRMGLOSS_DebugView == 4) return float4(FDRMGLOSS_DebugScalar(depthGate).xxx, 1.0);
    if (FDRMGLOSS_DebugView == 5) return float4(FDRMGLOSS_DebugScalar(budgetView).xxx, 1.0);
    if (FDRMGLOSS_DebugView == 6) return float4(FDRMGLOSS_DebugScalar(computedMask).xxx, 1.0);
    float3 temporalColor = FDRMGLOSS_Temporal(uv, effectColor, sourceColor, centerDepth, applicationMask);
    return float4(saturate(temporalColor), 1.0);
}
technique miXSR_FC_bio_raym_gloss_material_response < ui_label = "Fine Cell - Gloss Reflection - Bio Ray-M Shared Mask"; ui_tooltip = "Portable Fibonacci bio --Ray-M gloss using SSR-style tracing and bloom-style highlight diffusion."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FDRMGLOSS_MainPS;
    }

    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FDRMGLOSS_HistoryStorePS;
        RenderTarget = FDRMGLOSS_HistoryTex;
    }
}






