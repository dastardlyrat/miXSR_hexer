// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: dream-hatchlens-gloss-1
// Capability: Portable Fibonacci bio --Ray-M gloss that uses an bio hatch


// lens for sampling and applies highlights with a more traditional composite.

#include "ReShade.fxh"
#include "FineCell_FogGate.fxh"
#include "FineCell_LightRespect.fxh"
#include "FineDream_Lens55Bounded.fxh"

#define FDRMHLGLOSS_EPS 0.000010

uniform int FDRMHLGLOSS_PresetTier < ui_type = "combo"; ui_label = "Preset Tier"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 02 Main Settings"; ui_items = "Basic Conservative\0Liberal Coverage\0Aggressive Aggregate\0High Fidelity\0Ultra Fidelity\0"; ui_tooltip = "High Fidelity is the base standard; Ultra raises bounded Lens55 direction coverage while keeping compact ray bodies."; > = 2;
uniform int FDRMHLGLOSS_DebugView < ui_type = "combo"; ui_label = "Debug View"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 00 Debug"; ui_category_closed = true; ui_items = "Final\0Application Mask\0Gloss Color\0Hatch Lens\0Depth Gate\0Ray Budget\0"; ui_tooltip = "Shows final output or diagnostic buffers."; > = 0;

uniform float FDRMHLGLOSS_MasterIntensity < ui_type = "slider"; ui_label = "Master Intensity"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Overall intensity for hatch-lens --Ray-M gloss."; > = 0.410000;
uniform float FDRMHLGLOSS_GlossStrength < ui_type = "slider"; ui_label = "Gloss Strength"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Strength of traced glossy highlights."; > = 0.000000;
uniform float FDRMHLGLOSS_BloomStrength < ui_type = "slider"; ui_label = "Bloom Diffusion"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 02 Main Settings"; ui_min = 0.0; ui_max = 2.3; ui_step = 0.001; ui_tooltip = "Soft diffusion around traced highlights."; > = 1.676000;
uniform float FDRMHLGLOSS_TraditionalBlend < ui_type = "slider"; ui_label = "Traditional Blend"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 02 Main Settings"; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "0 keeps additive gloss; 1 favors classic screen-style gloss application."; > = 0.780000;

uniform float FDRMHLGLOSS_Threshold < ui_type = "slider"; ui_label = "Highlight Threshold"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Brightness where gloss extraction starts."; > = 0.373000;
uniform float FDRMHLGLOSS_Softness < ui_type = "slider"; ui_label = "Highlight Softness"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.001; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Soft knee around gloss threshold."; > = 0.190000;

uniform float FDRMHLGLOSS_RayLengthPixels < ui_type = "slider"; ui_label = "Ray Length"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.5; ui_max = 64.0; ui_step = 0.01; ui_tooltip = "Maximum gloss ray length in pixels before tier scaling."; > = 11.500000;
uniform int FDRMHLGLOSS_RaySteps < ui_type = "slider"; ui_label = "Ray Steps"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 2; ui_max = 11; ui_step = 1; ui_tooltip = "Maximum compact ray steps available to the active tier."; > = 8;
uniform int FDRMHLGLOSS_TapCount < ui_type = "slider"; ui_label = "Tap Budget"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 4; ui_max = FDREAM_LENS55_TAP_COUNT; ui_step = 1; ui_tooltip = "Bounded Lens55 ray direction budget."; > = 34;
uniform float FDRMHLGLOSS_Thickness < ui_type = "slider"; ui_label = "Depth Thickness"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0001; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Depth hit tolerance for glossy ray samples."; > = 0.012000;
uniform float FDRMHLGLOSS_DepthBias < ui_type = "slider"; ui_label = "Depth Bias"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Self-intersection bias for glossy ray hits."; > = 0.001000;
uniform float FDRMHLGLOSS_DepthFalloff < ui_type = "slider"; ui_label = "Depth Falloff"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.01; ui_max = 256.0; ui_step = 0.01; ui_tooltip = "Distance falloff applied along accepted ray hits."; > = 48.000000;
uniform float FDRMHLGLOSS_DepthGate < ui_type = "slider"; ui_label = "Depth Gate"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Suppresses gloss when depth is unstable."; > = 0.650000;
uniform float FDRMHLGLOSS_NormalStrength < ui_type = "slider"; ui_label = "Normal Strength"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.1; ui_max = 24.0; ui_step = 0.1; ui_tooltip = "Strength multiplier for depth-derived normals."; > = 5.000000;

uniform float FDRMHLGLOSS_FibAnchor < ui_type = "slider"; ui_label = "Fibonacci Anchor"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 987.0; ui_max = 4181.0; ui_step = 1.0; ui_tooltip = "Anchor index for bio Fibonacci directions."; > = 2584.000000;
uniform float FDRMHLGLOSS_OrganicFlow < ui_type = "slider"; ui_label = "bio Flow"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Phase drift for Fibonacci-derived ray direction."; > = 1.500000;
uniform float FDRMHLGLOSS_Roughness < ui_type = "slider"; ui_label = "Roughness Spread"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Broadens reflected ray direction for softer gloss."; > = 0.300000;
uniform float FDRMHLGLOSS_HatchPatternScale < ui_type = "slider"; ui_label = "Hatch Scale"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 40.0; ui_max = 1200.0; ui_step = 0.1; ui_tooltip = "UV scale for hatch lens synthesis."; > = 620.000000;
uniform float FDRMHLGLOSS_HatchDensity < ui_type = "slider"; ui_label = "Hatch Density"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.1; ui_max = 3.5; ui_step = 0.001; ui_tooltip = "Line density used by hatch lens synthesis."; > = 2.050000;
uniform float FDRMHLGLOSS_HatchTapSpread < ui_type = "slider"; ui_label = "Hatch Tap Spread"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 8.0; ui_max = 180.0; ui_step = 0.01; ui_tooltip = "Spatial spread used to phase hatch lens taps."; > = 96.000000;
uniform float FDRMHLGLOSS_HatchContrast < ui_type = "slider"; ui_label = "Hatch Contrast"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.1; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Contrast shaping of hatch lens values."; > = 1.400000;
uniform float FDRMHLGLOSS_HatchLensStrength < ui_type = "slider"; ui_label = "Hatch Lens Strength"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "How strongly hatch values bend ray directions and weighting."; > = 1.000000;
uniform float FDRMHLGLOSS_OrganicPreference < ui_type = "slider"; ui_label = "bio Preference"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "Biases gloss placement toward hatch-bio regions."; > = 0.700000;

uniform float FDRMHLGLOSS_Saturation < ui_type = "slider"; ui_label = "Gloss Saturation"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Saturation of glossy highlight color."; > = 1.080000;
uniform int FDRMHLGLOSS_RespectFog < ui_type = "combo"; ui_label = "Respect Fog"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Bypasses gloss in fog-dominant regions."; > = 1;
uniform int FDRMHLGLOSS_RespectLight < ui_type = "combo"; ui_label = "Respect Light Emission"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Protects emissive pixels from being altered."; > = 1;
uniform float FDRMHLGLOSS_LightProtectStrength < ui_type = "slider"; ui_label = "Light Protect Strength"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "How strongly protected lights return to source color."; > = 0.850000;
uniform float FDRMHLGLOSS_DebugExposure < ui_type = "slider"; ui_label = "Debug Exposure"; ui_category = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens / 00 Debug"; ui_category_closed = true; ui_min = 1.0; ui_max = 32.0; ui_step = 0.1; ui_tooltip = "Boosts debug buffer visibility."; > = 8.000000;

float2 FDRMHLGLOSS_Pixel() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
float3 FDRMHLGLOSS_Source(float2 uv) { return tex2D(ReShade::BackBuffer, saturate(uv)).rgb; }
float FDRMHLGLOSS_RawDepth(float2 uv) { return tex2D(ReShade::DepthBuffer, saturate(uv)).r; }
float FDRMHLGLOSS_Depth(float2 uv) { return saturate(ReShade::GetLinearizedDepth(saturate(uv))); }
float FDRMHLGLOSS_Luma(float3 color) { return dot(color, float3(0.2126, 0.7152, 0.0722)); }
float3 FDRMHLGLOSS_SaturateAroundLuma(float3 color, float amount) { float luma = FDRMHLGLOSS_Luma(color); return lerp(luma.xxx, color, amount); }
float FDRMHLGLOSS_DebugScalar(float value) { return pow(saturate(value * max(1.0, FDRMHLGLOSS_DebugExposure)), 0.65); }

int FDRMHLGLOSS_TierTapCap() { return FDREAM_Lens55TierTapCap(FDRMHLGLOSS_PresetTier); }
int FDRMHLGLOSS_TierStepCap() { if (FDRMHLGLOSS_PresetTier == 0) return 4; if (FDRMHLGLOSS_PresetTier == 1) return 6; return 8; }
float FDRMHLGLOSS_TierLengthScale() { return FDREAM_Lens55TierScale(FDRMHLGLOSS_PresetTier); }
float FDRMHLGLOSS_TierStrengthScale() { if (FDRMHLGLOSS_PresetTier == 0) return 0.72; if (FDRMHLGLOSS_PresetTier == 1) return 1.00; if (FDRMHLGLOSS_PresetTier == 2) return 1.18; if (FDRMHLGLOSS_PresetTier == 3) return 1.25; return 1.32; }

float FDRMHLGLOSS_LightEmissionMask(float3 sourceColor)
{
    if (FDRMHLGLOSS_RespectLight == 0)
    {
        return 0.0;
    }

    return FC_LIGHT_EmissionMask(sourceColor, FDRMHLGLOSS_Luma(sourceColor), 0.680000, 0.180000, 0.700000, 0.350000, 0.220000, FDRMHLGLOSS_EPS);
}

float FDRMHLGLOSS_LocalLightZone(float2 uv, float3 sourceColor, float centerLightMask)
{
    if (FDRMHLGLOSS_RespectLight == 0)
    {
        return 0.0;
    }

    float2 px = FDRMHLGLOSS_Pixel() * 2.0;
    float zone = centerLightMask;
    zone = max(zone, FDRMHLGLOSS_LightEmissionMask(FDRMHLGLOSS_Source(uv + float2(px.x, 0.0))));
    zone = max(zone, FDRMHLGLOSS_LightEmissionMask(FDRMHLGLOSS_Source(uv - float2(px.x, 0.0))));
    zone = max(zone, FDRMHLGLOSS_LightEmissionMask(FDRMHLGLOSS_Source(uv + float2(0.0, px.y))));
    zone = max(zone, FDRMHLGLOSS_LightEmissionMask(FDRMHLGLOSS_Source(uv - float2(0.0, px.y))));
    return saturate(zone * FDRMHLGLOSS_LightProtectStrength);
}

float3 FDRMHLGLOSS_Normal(float2 uv, out float edgeFactor)
{
    float2 px = FDRMHLGLOSS_Pixel();
    float dC = FDRMHLGLOSS_Depth(uv);
    float dR = FDRMHLGLOSS_Depth(uv + float2(px.x, 0.0));
    float dL = FDRMHLGLOSS_Depth(uv - float2(px.x, 0.0));
    float dU = FDRMHLGLOSS_Depth(uv + float2(0.0, px.y));
    float dD = FDRMHLGLOSS_Depth(uv - float2(0.0, px.y));
    float gradX = (abs(dR - dC) < abs(dC - dL)) ? (dR - dC) : (dC - dL);
    float gradY = (abs(dU - dC) < abs(dC - dD)) ? (dU - dC) : (dC - dD);
    edgeFactor = saturate((abs(gradX) + abs(gradY)) * 64.0);
    float3 n = normalize(float3(-gradX * FDRMHLGLOSS_NormalStrength, -gradY * FDRMHLGLOSS_NormalStrength, 1.0));
    n.z = abs(n.z);
    return normalize(n);
}

float FDRMHLGLOSS_DepthGateMask(float2 uv, float centerDepth)
{
    float2 px = FDRMHLGLOSS_Pixel();
    float dR = FDRMHLGLOSS_Depth(uv + float2(px.x, 0.0));
    float dL = FDRMHLGLOSS_Depth(uv - float2(px.x, 0.0));
    float dU = FDRMHLGLOSS_Depth(uv + float2(0.0, px.y));
    float dD = FDRMHLGLOSS_Depth(uv - float2(0.0, px.y));
    float rawDepth = FDRMHLGLOSS_RawDepth(uv);
    float rangeMask = step(FDRMHLGLOSS_EPS, rawDepth) * step(rawDepth, 0.999990);
    float slope = abs(dR - dL) + abs(dU - dD);
    float fit = abs(dR - centerDepth) + abs(dL - centerDepth) + abs(dU - centerDepth) + abs(dD - centerDepth);
    float continuity = 1.0 - saturate((slope + fit * 0.25) * 30.0);
    float tierBias = (FDRMHLGLOSS_PresetTier == 0) ? 0.12 : ((FDRMHLGLOSS_PresetTier == 1) ? 0.0 : -0.08);
    return saturate(lerp(1.0, rangeMask * continuity, saturate(FDRMHLGLOSS_DepthGate + tierBias)));
}

float FDRMHLGLOSS_BrightMask(float3 color)
{
    return smoothstep(FDRMHLGLOSS_Threshold, FDRMHLGLOSS_Threshold + max(FDRMHLGLOSS_EPS, FDRMHLGLOSS_Softness), FDRMHLGLOSS_Luma(color));
}

float2 FDRMHLGLOSS_FibonacciDirection(float fibIndex)
{
    const float goldenAngle = 2.39996323;
    float angle = fibIndex * goldenAngle;
    return float2(cos(angle), sin(angle));
}

float2 FDRMHLGLOSS_OrganicDirection(float2 lensOffset, float fibIndex, float2 uv, float3 centerNormal, float tapNorm)
{
    float2 fibDir = FDRMHLGLOSS_FibonacciDirection(fibIndex);
    float2 lensDir = normalize(float2(0.23 - lensOffset.y, 0.17 + lensOffset.x + frac(fibIndex * 0.000618)));
    float2 normalSlide = normalize(centerNormal.xy + float2(0.0001, 0.0001));
    float2 baseDir = normalize(lerp(lerp(lensDir, fibDir, 0.45 + 0.20 * tapNorm), normalSlide, 0.25 + FDRMHLGLOSS_Roughness * 0.35));
    float phase = fibIndex * 0.013 + FDRMHLGLOSS_OrganicFlow * 0.18 + dot(uv * 80.0, float2(0.754, 0.569));
    float cs = cos(phase);
    float sn = sin(phase);
    return normalize(float2(baseDir.x * cs - baseDir.y * sn, baseDir.x * sn + baseDir.y * cs));
}

float FDRMHLGLOSS_HatchLine(float2 p, float2 dir, float phase, float density)
{
    float value = sin(dot(p, dir) * density + phase);
    return smoothstep(0.72, 0.96, value);
}

float FDRMHLGLOSS_HatchLensField(float2 uv, float2 lensOffset, float fibIndex, float tapNorm)
{
    float2 p = uv * FDRMHLGLOSS_HatchPatternScale;
    float phaseBase = fibIndex * 0.013 + FDRMHLGLOSS_OrganicFlow * 0.15;
    float2 dirA = normalize(float2(0.23 - lensOffset.y, 0.17 + lensOffset.x + frac(fibIndex * 0.000618)));
    float2 dirB = float2(-dirA.y, dirA.x);
    float growth = 0.45 + 0.55 * tapNorm;
    float2 spread = lensOffset * FDRMHLGLOSS_HatchTapSpread * growth;
    float lineA = FDRMHLGLOSS_HatchLine(p + spread, dirA, phaseBase, FDRMHLGLOSS_HatchDensity);
    float lineB = FDRMHLGLOSS_HatchLine(p - spread.yx, dirB, phaseBase * 1.13 + 1.7, FDRMHLGLOSS_HatchDensity * 1.10);
    float mask = saturate(lineA * 0.65 + lineB * 0.35);
    return saturate((mask - 0.5) * FDRMHLGLOSS_HatchContrast + 0.5);
}

float2 FDRMHLGLOSS_Rotate(float2 v, float radians)
{
    float cs = cos(radians);
    float sn = sin(radians);
    return float2(v.x * cs - v.y * sn, v.x * sn + v.y * cs);
}

void FDRMHLGLOSS_AccumulateRayStep(
    float2 uv,
    float centerDepth,
    float2 rayStep,
    int stepIndex,
    int raySteps,
    float invRaySteps,
    float thickness,
    float depthEdge,
    float depthFalloff,
    float hatchLens,
    inout float3 tightColor,
    inout float tightWeight,
    inout float3 broadColor,
    inout float broadWeight)
{
    if (stepIndex <= raySteps)
    {
        float t = float(stepIndex) * invRaySteps;
        float2 sampleUv = uv + rayStep * t;
        float3 sampleColor = FDRMHLGLOSS_Source(sampleUv);
        float sampleDepth = FDRMHLGLOSS_Depth(sampleUv);
        float depthDelta = sampleDepth - centerDepth;
        float depthMatch = 1.0 - smoothstep(thickness, depthEdge, abs(depthDelta));
        float behindMask = step(centerDepth - FDRMHLGLOSS_DepthBias, sampleDepth);
        float brightMask = FDRMHLGLOSS_BrightMask(sampleColor);
        float tightDistance = exp(-t * depthFalloff * 0.0125);
        float broadDistance = exp(-t * depthFalloff * 0.0060);
        float organicBias = lerp(1.0, lerp(0.75, 1.35, hatchLens), FDRMHLGLOSS_OrganicPreference);
        float tightHit = saturate(depthMatch * behindMask * brightMask * tightDistance * organicBias);
        float broadHit = saturate((depthMatch * 0.65 + 0.35 * behindMask) * brightMask * broadDistance * organicBias);
        tightColor += sampleColor * tightHit;
        tightWeight += tightHit;
        broadColor += sampleColor * broadHit;
        broadWeight += broadHit;
    }
}

void FDRMHLGLOSS_RayMarchDirection(float2 uv, float centerDepth, float2 direction, int raySteps, float rayGrowth, float hatchLens, out float3 tightColor, out float tightWeight, out float3 broadColor, out float broadWeight)
{
    float2 rayStep = direction * FDRMHLGLOSS_Pixel() * FDRMHLGLOSS_RayLengthPixels * FDRMHLGLOSS_TierLengthScale() * rayGrowth;
    float invRaySteps = rcp(max(1.0, float(raySteps)));
    float thickness = max(0.0001, FDRMHLGLOSS_Thickness);
    float depthEdge = thickness * 2.0 + FDRMHLGLOSS_EPS;
    float depthFalloff = max(0.01, FDRMHLGLOSS_DepthFalloff);
    tightColor = 0.0;
    tightWeight = 0.0;
    broadColor = 0.0;
    broadWeight = 0.0;

    #define FDRMHLGLOSS_RAY_STEP(STEP_INDEX) FDRMHLGLOSS_AccumulateRayStep(uv, centerDepth, rayStep, (STEP_INDEX), raySteps, invRaySteps, thickness, depthEdge, depthFalloff, hatchLens, tightColor, tightWeight, broadColor, broadWeight);
    FDRMHLGLOSS_RAY_STEP(1)
    FDRMHLGLOSS_RAY_STEP(2)
    FDRMHLGLOSS_RAY_STEP(3)
    FDRMHLGLOSS_RAY_STEP(4)
    FDRMHLGLOSS_RAY_STEP(5)
    FDRMHLGLOSS_RAY_STEP(6)
    FDRMHLGLOSS_RAY_STEP(7)
    FDRMHLGLOSS_RAY_STEP(8)
    #undef FDRMHLGLOSS_RAY_STEP
}

void FDRMHLGLOSS_AccumulateTap(float2 uv, float centerDepth, float3 centerNormal, float2 lensOffset, int tapIndex, int tapCount, int raySteps, inout float3 tightSum, inout float tightWeight, inout float3 broadSum, inout float broadWeight, inout float hatchSum, inout float hatchWeight)
{
    if (tapIndex < tapCount)
    {
        float tapNorm = (float(tapIndex) + 0.5) / max(1.0, float(tapCount));
        float fibIndex = FDRMHLGLOSS_FibAnchor + float(tapIndex);
        float hatchLens = FDRMHLGLOSS_HatchLensField(uv, lensOffset, fibIndex, tapNorm);

        float2 baseDirection = FDRMHLGLOSS_OrganicDirection(lensOffset, fibIndex, uv, centerNormal, tapNorm);
        float bend = (hatchLens - 0.5) * FDRMHLGLOSS_HatchLensStrength * 1.5707963;
        float2 direction = normalize(FDRMHLGLOSS_Rotate(baseDirection, bend));
        float rayGrowth = FDREAM_Lens55FibonacciGrowth(tapIndex, tapCount) * lerp(0.75, 1.35, hatchLens * FDRMHLGLOSS_HatchLensStrength);

        float3 tightColor = 0.0;
        float tightHit = 0.0;
        float3 broadColor = 0.0;
        float broadHit = 0.0;
        FDRMHLGLOSS_RayMarchDirection(uv, centerDepth, direction, raySteps, rayGrowth, hatchLens, tightColor, tightHit, broadColor, broadHit);
        tightSum += tightColor;
        tightWeight += tightHit;
        broadSum += broadColor;
        broadWeight += broadHit;
        hatchSum += hatchLens;
        hatchWeight += 1.0;
    }
}

float4 FDRMHLGLOSS_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    int tapCount = min(clamp(FDRMHLGLOSS_TapCount, 1, FDREAM_LENS55_TAP_COUNT), FDRMHLGLOSS_TierTapCap());
    int raySteps = min(clamp(FDRMHLGLOSS_RaySteps, 1, 8), FDRMHLGLOSS_TierStepCap());
    float3 sourceColor = FDRMHLGLOSS_Source(uv);
    float centerDepth = FDRMHLGLOSS_Depth(uv);
    float edgeFactor = 0.0;
    float3 centerNormal = FDRMHLGLOSS_Normal(uv, edgeFactor);
    float depthGate = FDRMHLGLOSS_DepthGateMask(uv, centerDepth);
    float centerMask = FDRMHLGLOSS_BrightMask(sourceColor);

    float3 tightSum = sourceColor * centerMask;
    float tightWeight = max(FDRMHLGLOSS_EPS, centerMask);
    float3 broadSum = sourceColor * centerMask;
    float broadWeight = max(FDRMHLGLOSS_EPS, centerMask);
    float hatchSum = 0.0;
    float hatchWeight = 0.0;

    [loop]
    for (int tapIndex = 0; tapIndex < FDREAM_LENS55_TAP_COUNT; ++tapIndex)
    {
        if (tapIndex < tapCount)
        {
            FDRMHLGLOSS_AccumulateTap(uv, centerDepth, centerNormal, FDREAM_Lens55Offset(tapIndex), tapIndex, tapCount, raySteps, tightSum, tightWeight, broadSum, broadWeight, hatchSum, hatchWeight);
        }
    }

    float3 tightGloss = tightSum / max(FDRMHLGLOSS_EPS, tightWeight);
    float3 broadGloss = broadSum / max(FDRMHLGLOSS_EPS, broadWeight);
    float aggregateBlend = (FDRMHLGLOSS_PresetTier >= 4) ? 0.72 : ((FDRMHLGLOSS_PresetTier == 3) ? 0.64 : ((FDRMHLGLOSS_PresetTier == 2) ? 0.60 : ((FDRMHLGLOSS_PresetTier == 1) ? 0.38 : 0.18)));
    float3 glossColor = lerp(tightGloss, broadGloss, aggregateBlend);
    glossColor = FDRMHLGLOSS_SaturateAroundLuma(glossColor, FDRMHLGLOSS_Saturation);

    float hatchLens = hatchSum / max(1.0, hatchWeight);
    float hitCoverage = saturate((tightWeight + broadWeight) / max(1.0, float(tapCount * raySteps)));
    float organicMask = lerp(1.0, saturate(0.35 + 0.65 * hatchLens), FDRMHLGLOSS_OrganicPreference);
    float hitMask = hitCoverage * depthGate * (1.0 - edgeFactor * 0.35) * organicMask;
    float lightProtectMask = FDRMHLGLOSS_LightEmissionMask(sourceColor);
    float lightZone = FDRMHLGLOSS_LocalLightZone(uv, sourceColor, lightProtectMask);
    float applicationMask = saturate(hitMask * (1.0 - lightZone * 0.75));

    float glossGain = applicationMask * FDRMHLGLOSS_GlossStrength * FDRMHLGLOSS_MasterIntensity * FDRMHLGLOSS_TierStrengthScale();
    float3 glossLift = saturate(glossColor - sourceColor);
    float3 additiveGloss = saturate(sourceColor + glossLift * glossGain);
    float3 screenGloss = 1.0 - (1.0 - sourceColor) * (1.0 - saturate(glossColor * glossGain));
    float3 mixedGloss = lerp(additiveGloss, screenGloss, saturate(FDRMHLGLOSS_TraditionalBlend));
    mixedGloss += broadGloss * applicationMask * FDRMHLGLOSS_BloomStrength * FDRMHLGLOSS_MasterIntensity * organicMask;

    mixedGloss = FC_LIGHT_ProtectColor(mixedGloss, sourceColor, lightProtectMask, FDRMHLGLOSS_LightProtectStrength);
    float fogBypass = FC_FOG_BypassMask(uv, sourceColor, FDRMHLGLOSS_RespectFog);
    float3 finalColor = lerp(mixedGloss, sourceColor, fogBypass);
    float tierMaxBudget = max(1.0, float(FDRMHLGLOSS_TierTapCap() * FDRMHLGLOSS_TierStepCap()));
    float budgetView = saturate(float(tapCount * raySteps) / tierMaxBudget);

    if (FDRMHLGLOSS_DebugView == 1) return float4(FDRMHLGLOSS_DebugScalar(applicationMask).xxx, 1.0);
    if (FDRMHLGLOSS_DebugView == 2) return float4(saturate(glossColor), 1.0);
    if (FDRMHLGLOSS_DebugView == 3) return float4(FDRMHLGLOSS_DebugScalar(hatchLens).xxx, 1.0);
    if (FDRMHLGLOSS_DebugView == 4) return float4(FDRMHLGLOSS_DebugScalar(depthGate).xxx, 1.0);
    if (FDRMHLGLOSS_DebugView == 5) return float4(FDRMHLGLOSS_DebugScalar(budgetView).xxx, 1.0);
    return float4(saturate(finalColor), 1.0);
}
technique fine_dream_bio_raym_hatch_lens_gloss_material_response < ui_label = "Fine Cell - Gloss Reflection - Bio Ray-M Hatch Lens"; ui_tooltip = "--Ray-M gloss that uses an bio hatch lens for sampling and a traditional highlight composite biased toward bio regions."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FDRMHLGLOSS_MainPS;
    }
}






