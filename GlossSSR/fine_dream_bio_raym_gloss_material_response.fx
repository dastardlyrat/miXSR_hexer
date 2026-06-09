// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: dream-gloss-1
// Capability: Portable Fibonacci bio --Ray-M gloss from SSR-style tracing and bloom-style highlight diffusion.



#include "ReShade.fxh"
#include "FineCell_FogGate.fxh"
#include "FineCell_LightRespect.fxh"
#include "FineDream_Lens55Bounded.fxh"

uniform int FDRMGLOSS_PresetTier < ui_type = "combo"; ui_label = "Preset Tier"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 02 Main Settings"; ui_items = "Basic Conservative\0Liberal Coverage\0Aggressive Aggregate\0High Fidelity\0Ultra Fidelity\0"; ui_tooltip = "High Fidelity is the base standard; Ultra raises bounded Lens55 ray direction coverage while keeping ray steps compact."; > = 2;
uniform int FDRMGLOSS_DebugView < ui_type = "combo"; ui_label = "Debug View"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 00 Debug"; ui_category_closed = true; ui_items = "Final\0Application Mask\0Gloss Color\0Normal\0Depth Gate\0Ray Budget\0"; ui_tooltip = "Shows the final output or diagnostic masks."; > = 0;
uniform float FDRMGLOSS_MasterIntensity < ui_type = "slider"; ui_label = "Master Intensity"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 02 Main Settings"; ui_min = 0.0; ui_max = 2.4225; ui_step = 0.001; ui_tooltip = "Overall multiplier for --Ray-M gloss."; > = 1.938000;
uniform float FDRMGLOSS_GlossStrength < ui_type = "slider"; ui_label = "Gloss Strength"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "How strongly traced glossy hits blend into the scene."; > = 0.716000;
uniform float FDRMGLOSS_BloomStrength < ui_type = "slider"; ui_label = "Bloom Diffusion"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Soft bloom-style diffusion around traced highlights."; > = 0.545000;
uniform float FDRMGLOSS_Threshold < ui_type = "slider"; ui_label = "Highlight Threshold"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Brightness where ray gloss extraction starts."; > = 0.643000;
uniform float FDRMGLOSS_Softness < ui_type = "slider"; ui_label = "Highlight Softness"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.001; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Soft knee around the gloss threshold."; > = 0.128000;
uniform float FDRMGLOSS_RayLengthPixels < ui_type = "slider"; ui_label = "Ray Length"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.5; ui_max = 64.0; ui_step = 0.01; ui_tooltip = "Maximum length of each gloss ray in screen pixels before tier scaling."; > = 2.450000;
uniform int FDRMGLOSS_RaySteps < ui_type = "slider"; ui_label = "Ray Steps"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 2; ui_max = 8; ui_step = 1; ui_tooltip = "Maximum compact ray steps available to the active tier. High Fidelity defaults to the full 8-step body."; > = 3;
uniform int FDRMGLOSS_TapCount < ui_type = "slider"; ui_label = "Tap Budget"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 4; ui_max = FDREAM_LENS55_TAP_COUNT; ui_step = 1; ui_tooltip = "Bounded Lens55 ray direction budget. High and Ultra fidelity increase tap coverage without expanding ray-step bodies."; > = 13;
uniform float FDRMGLOSS_Thickness < ui_type = "slider"; ui_label = "Depth Thickness"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0001; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Depth hit tolerance for accepting glossy ray samples."; > = 0.012000;
uniform float FDRMGLOSS_DepthBias < ui_type = "slider"; ui_label = "Depth Bias"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Self-intersection bias for glossy ray hits."; > = 0.001000;
uniform float FDRMGLOSS_DepthFalloff < ui_type = "slider"; ui_label = "Depth Falloff"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.01; ui_max = 256.0; ui_step = 0.01; ui_tooltip = "Distance falloff applied along accepted ray hits."; > = 48.000000;
uniform float FDRMGLOSS_DepthGate < ui_type = "slider"; ui_label = "Depth Gate"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Suppresses gloss when depth is unstable."; > = 0.650000;
uniform float FDRMGLOSS_NormalStrength < ui_type = "slider"; ui_label = "Normal Strength"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.1; ui_max = 24.0; ui_step = 0.1; ui_tooltip = "Strength multiplier for depth-derived normals."; > = 5.000000;
uniform float FDRMGLOSS_FibAnchor < ui_type = "slider"; ui_label = "Fibonacci Anchor"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 987.0; ui_max = 4181.0; ui_step = 1.0; ui_tooltip = "Anchor index for bio Fibonacci ray directions."; > = 2584.000000;
uniform float FDRMGLOSS_OrganicFlow < ui_type = "slider"; ui_label = "bio Flow"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Phase drift for Fibonacci-derived ray direction."; > = 1.400000;
uniform float FDRMGLOSS_Roughness < ui_type = "slider"; ui_label = "Roughness Spread"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Broadens reflected ray direction for softer gloss."; > = 0.300000;
uniform float FDRMGLOSS_Saturation < ui_type = "slider"; ui_label = "Gloss Saturation"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Saturation of glossy highlight color."; > = 1.080000;
uniform int FDRMGLOSS_RespectFog < ui_type = "combo"; ui_label = "Respect Fog"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Bypasses gloss in fog-dominant regions."; > = 1;
uniform int FDRMGLOSS_RespectLight < ui_type = "combo"; ui_label = "Respect Light Emission"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Protects emissive pixels from being altered."; > = 1;
uniform float FDRMGLOSS_LightProtectStrength < ui_type = "slider"; ui_label = "Light Protect Strength"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "How strongly protected lights return to source color."; > = 0.850000;
uniform float FDRMGLOSS_DebugExposure < ui_type = "slider"; ui_label = "Debug Exposure"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion / 00 Debug"; ui_category_closed = true; ui_min = 1.0; ui_max = 32.0; ui_step = 0.1; ui_tooltip = "Boosts debug buffer visibility."; > = 8.000000;

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

float FDRMGLOSS_LightEmissionMask(float3 sourceColor)
{
    if (FDRMGLOSS_RespectLight == 0)
    {
        return 0.0;
    }

    return FC_LIGHT_EmissionMask(sourceColor, FDRMGLOSS_Luma(sourceColor), 0.680000, 0.180000, 0.700000, 0.350000, 0.220000, 0.000010);
}

float FDRMGLOSS_LocalLightZone(float2 uv, float3 sourceColor, float centerLightMask)
{
    if (FDRMGLOSS_RespectLight == 0)
    {
        return 0.0;
    }

    float2 px = FDRMGLOSS_Pixel() * 2.0;
    float zone = centerLightMask;
    zone = max(zone, FDRMGLOSS_LightEmissionMask(FDRMGLOSS_Source(uv + float2(px.x, 0.0))));
    zone = max(zone, FDRMGLOSS_LightEmissionMask(FDRMGLOSS_Source(uv - float2(px.x, 0.0))));
    zone = max(zone, FDRMGLOSS_LightEmissionMask(FDRMGLOSS_Source(uv + float2(0.0, px.y))));
    zone = max(zone, FDRMGLOSS_LightEmissionMask(FDRMGLOSS_Source(uv - float2(0.0, px.y))));
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
    float2 fibDir = FDRMGLOSS_FibonacciDirection(fibIndex);
    float2 lensDir = normalize(float2(0.23 - lensOffset.y, 0.17 + lensOffset.x + frac(fibIndex * 0.000618)));
    float2 normalSlide = normalize(centerNormal.xy + float2(0.0001, 0.0001));
    float2 baseDir = normalize(lerp(lerp(lensDir, fibDir, 0.45 + 0.20 * tapNorm), normalSlide, 0.25 + FDRMGLOSS_Roughness * 0.35));
    float phase = fibIndex * 0.013 + FDRMGLOSS_OrganicFlow * 0.18 + dot(uv * 80.0, float2(0.754, 0.569));
    float cs = cos(phase);
    float sn = sin(phase);
    return normalize(float2(baseDir.x * cs - baseDir.y * sn, baseDir.x * sn + baseDir.y * cs));
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
    float hitMask = hitCoverage * depthGate * (1.0 - edgeFactor * 0.35);
    float lightProtectMask = FDRMGLOSS_LightEmissionMask(sourceColor);
    float lightZone = FDRMGLOSS_LocalLightZone(uv, sourceColor, lightProtectMask);
    float applicationMask = saturate(hitMask * (1.0 - lightZone * 0.75));

    float3 effectColor = lerp(sourceColor, glossColor, applicationMask * FDRMGLOSS_GlossStrength * FDRMGLOSS_MasterIntensity * FDRMGLOSS_TierStrengthScale());
    effectColor += broadGloss * applicationMask * FDRMGLOSS_BloomStrength * FDRMGLOSS_MasterIntensity;

    effectColor = FC_LIGHT_ProtectColor(effectColor, sourceColor, lightProtectMask, FDRMGLOSS_LightProtectStrength);
    float fogBypass = FC_FOG_BypassMask(uv, sourceColor, FDRMGLOSS_RespectFog);
    effectColor = lerp(effectColor, sourceColor, fogBypass);
    float tierMaxBudget = max(1.0, float(FDRMGLOSS_TierTapCap() * FDRMGLOSS_TierStepCap()));
    float budgetView = saturate(float(tapCount * raySteps) / tierMaxBudget);

    if (FDRMGLOSS_DebugView == 1) return float4(FDRMGLOSS_DebugScalar(applicationMask).xxx, 1.0);
    if (FDRMGLOSS_DebugView == 2) return float4(saturate(glossColor), 1.0);
    if (FDRMGLOSS_DebugView == 3) return float4(centerNormal * 0.5 + 0.5, 1.0);
    if (FDRMGLOSS_DebugView == 4) return float4(FDRMGLOSS_DebugScalar(depthGate).xxx, 1.0);
    if (FDRMGLOSS_DebugView == 5) return float4(FDRMGLOSS_DebugScalar(budgetView).xxx, 1.0);
    return float4(saturate(effectColor), 1.0);
}
technique fine_dream_bio_raym_gloss_material_response < ui_label = "Fine Cell - Gloss Reflection - Bio Ray-M Diffusion"; ui_tooltip = "Portable Fibonacci bio --Ray-M gloss using SSR-style tracing and bloom-style highlight diffusion."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FDRMGLOSS_MainPS;
    }
}






