// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: dream---Ray-M-hatchlens-Global Illumination-1
// Capability: Portable Fibonacci bio --Ray-M Global Illumination that uses an bio hatch lens for guarded Global Illumination compositing


// for sampling while applying light with a Global Illumination-only composite.

#include "ReShade.fxh"
#include "FineCell_FogGate.fxh"
#include "FineCell_LightRespect.fxh"
#include "FineDream_Lens55Bounded.fxh"

#define FDRMHLGI_EPS 0.000010

uniform int FDRMHLGI_PresetTier <
    ui_type = "combo";
    ui_label = "Preset Tier";
    ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 02 Main Settings";
    ui_items = "Basic Conservative\0Liberal Coverage\0Aggressive Aggregate\0High Fidelity\0Ultra Fidelity\0";
    ui_tooltip = "High Fidelity is the base standard; Ultra raises bounded Lens55 direction coverage while keeping compact ray bodies.";
> = 2;

uniform int FDRMHLGI_DebugView <
    ui_type = "combo";
    ui_label = "Debug View";
    ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 00 Debug"; ui_category_closed = true;
    ui_items = "Final\0Local Indirect\0Lens Field\0Application Mask\0Ray Budget\0Coverage Mask\0Computed Mask\0";
    ui_tooltip = "Shows final output or diagnostic buffers.\nCoverage Mask shows confidence in ray-hit support; Computed Mask shows final Global Illumination application after guards and fog restore.";
> = 0;

uniform float FDRMHLGI_MasterIntensity < ui_type = "slider"; ui_label = "Master Intensity"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 02 Main Settings"; ui_min = 0.0; ui_max = 2.31; ui_step = 0.001; ui_tooltip = "Overall multiplier for hatch-lens Global Illumination."; > = 1.848000;
uniform float FDRMHLGI_GIStrength < ui_type = "slider"; ui_label = "Global Illumination Strength"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 02 Main Settings"; ui_min = 0.0; ui_max = 3.0; ui_step = 0.001; ui_tooltip = "Strength of indirect light contribution."; > = 0.430000;
uniform float FDRMHLGI_RayLengthPixels < ui_type = "slider"; ui_label = "Ray Length"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.5; ui_max = 64.0; ui_step = 0.01; ui_tooltip = "Maximum length of each ray in screen pixels before tier scaling."; > = 3.670000;
uniform int FDRMHLGI_RaySteps < ui_type = "slider"; ui_label = "Ray Steps"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 2; ui_max = 8; ui_step = 1; ui_tooltip = "Maximum compact ray steps available to the active tier."; > = 2;
uniform int FDRMHLGI_TapCount < ui_type = "slider"; ui_label = "Tap Budget"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 4; ui_max = FDREAM_LENS55_TAP_COUNT; ui_step = 1; ui_tooltip = "Bounded Lens55 ray direction budget."; > = 13;
uniform float FDRMHLGI_Thickness < ui_type = "slider"; ui_label = "Depth Thickness"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0001; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Depth hit tolerance for accepting ray samples."; > = 0.010000;
uniform float FDRMHLGI_DepthBias < ui_type = "slider"; ui_label = "Depth Bias"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Self-intersection bias for ray hits."; > = 0.001000;
uniform float FDRMHLGI_DepthFalloff < ui_type = "slider"; ui_label = "Depth Falloff"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.01; ui_max = 256.0; ui_step = 0.01; ui_tooltip = "Distance falloff applied along accepted ray hits."; > = 52.000000;
uniform float FDRMHLGI_DepthGate < ui_type = "slider"; ui_label = "Depth Gate"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Suppresses Global Illumination when depth has weak signal or harsh discontinuities."; > = 0.650000;
uniform float FDRMHLGI_FibAnchor < ui_type = "slider"; ui_label = "Fibonacci Anchor"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 987.0; ui_max = 4181.0; ui_step = 1.0; ui_tooltip = "Anchor index for bio Fibonacci directions."; > = 2584.000000;
uniform float FDRMHLGI_OrganicFlow < ui_type = "slider"; ui_label = "bio Flow"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 5; ui_step = 0.001; ui_tooltip = "Phase drift for Fibonacci-derived ray orientation."; > = 4.000000;
uniform float FDRMHLGI_HatchPatternScale < ui_type = "slider"; ui_label = "Hatch Scale"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 40.0; ui_max = 1380; ui_step = 0.1; ui_tooltip = "UV scale for hatch lens synthesis."; > = 1083.500000;
uniform float FDRMHLGI_HatchDensity < ui_type = "slider"; ui_label = "Hatch Density"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.1; ui_max = 4.375; ui_step = 0.001; ui_tooltip = "Line density used by hatch lens synthesis."; > = 3.500000;
uniform float FDRMHLGI_HatchTapSpread < ui_type = "slider"; ui_label = "Hatch Tap Spread"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 8.0; ui_max = 207; ui_step = 0.01; ui_tooltip = "Spatial spread used to phase hatch lens taps."; > = 156.029999;
uniform float FDRMHLGI_HatchContrast < ui_type = "slider"; ui_label = "Hatch Contrast"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.1; ui_max = 5; ui_step = 0.001; ui_tooltip = "Contrast shaping of hatch lens values."; > = 4.000000;
uniform float FDRMHLGI_HatchLensStrength < ui_type = "slider"; ui_label = "Hatch Lens Strength"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "How strongly hatch values bend ray directions and ray growth."; > = 0.984000;
uniform float FDRMHLGI_OrganicPreference < ui_type = "slider"; ui_label = "bio Preference"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "Biases hit weighting and application masks toward hatch-bio regions."; > = 0.700000;
uniform float FDRMHLGI_ColorBleedSaturation < ui_type = "slider"; ui_label = "Bleed Saturation"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Saturation of ray-hit indirect color."; > = 1.050000;
uniform float FDRMHLGI_MaxContribution < ui_type = "slider"; ui_label = "Max Contribution"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Upper cap for bounced light contribution."; > = 1.450000;
uniform int FDRMHLGI_RespectFog < ui_type = "combo"; ui_label = "Respect Fog"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Bypasses Global Illumination in fog-dominant regions."; > = 1;
uniform int FDRMHLGI_RespectLight < ui_type = "combo"; ui_label = "Respect Light Emission"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Protects emissive pixels from being dimmed or recolored."; > = 1;
uniform float FDRMHLGI_LightProtectStrength < ui_type = "slider"; ui_label = "Light Protect Strength"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "How strongly protected lights return to source color."; > = 0.900000;
uniform float FDRMHLGI_DebugExposure < ui_type = "slider"; ui_label = "Debug Exposure"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens / 00 Debug"; ui_category_closed = true; ui_min = 1.0; ui_max = 32.0; ui_step = 0.1; ui_tooltip = "Boosts debug buffer visibility."; > = 8.000000;

float2 FDRMHLGI_Pixel() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
float3 FDRMHLGI_Source(float2 uv) { return tex2D(ReShade::BackBuffer, saturate(uv)).rgb; }
float FDRMHLGI_RawDepth(float2 uv) { return tex2D(ReShade::DepthBuffer, saturate(uv)).r; }
float FDRMHLGI_Depth(float2 uv) { return saturate(ReShade::GetLinearizedDepth(saturate(uv))); }
float FDRMHLGI_Luma(float3 color) { return dot(color, float3(0.2126, 0.7152, 0.0722)); }
float3 FDRMHLGI_SaturateAroundLuma(float3 color, float amount) { float luma = FDRMHLGI_Luma(color); return lerp(luma.xxx, color, amount); }

int FDRMHLGI_TierTapCap()
{
    return FDREAM_Lens55TierTapCap(FDRMHLGI_PresetTier);
}

int FDRMHLGI_TierStepCap()
{
    if (FDRMHLGI_PresetTier == 0) return 4;
    if (FDRMHLGI_PresetTier == 1) return 6;
    return 8;
}

float FDRMHLGI_TierLengthScale()
{
    return FDREAM_Lens55TierScale(FDRMHLGI_PresetTier);
}

float FDRMHLGI_TierStrengthScale()
{
    if (FDRMHLGI_PresetTier == 0) return 0.72;
    if (FDRMHLGI_PresetTier == 1) return 1.00;
    if (FDRMHLGI_PresetTier == 2) return 1.18;
    if (FDRMHLGI_PresetTier == 3) return 1.25;
    return 1.32;
}

float FDRMHLGI_DebugScalar(float value)
{
    return pow(saturate(value * max(1.0, FDRMHLGI_DebugExposure)), 0.65);
}

float FDRMHLGI_LightEmissionMask(float3 sourceColor)
{
    if (FDRMHLGI_RespectLight == 0)
    {
        return 0.0;
    }

    return FC_LIGHT_EmissionMask(
        sourceColor,
        FDRMHLGI_Luma(sourceColor),
        0.680000,
        0.180000,
        0.700000,
        0.350000,
        0.220000,
        FDRMHLGI_EPS);
}

float FDRMHLGI_LocalLightZone(float2 uv, float3 sourceColor, float centerLightMask)
{
    if (FDRMHLGI_RespectLight == 0)
    {
        return 0.0;
    }

    float2 px = FDRMHLGI_Pixel() * 2.0;
    float zone = centerLightMask;
    zone = max(zone, FDRMHLGI_LightEmissionMask(FDRMHLGI_Source(uv + float2(px.x, 0.0))));
    zone = max(zone, FDRMHLGI_LightEmissionMask(FDRMHLGI_Source(uv - float2(px.x, 0.0))));
    zone = max(zone, FDRMHLGI_LightEmissionMask(FDRMHLGI_Source(uv + float2(0.0, px.y))));
    zone = max(zone, FDRMHLGI_LightEmissionMask(FDRMHLGI_Source(uv - float2(0.0, px.y))));
    return saturate(zone * FDRMHLGI_LightProtectStrength);
}

float FDRMHLGI_DepthActivity(float2 uv, float centerDepth)
{
    float2 px = FDRMHLGI_Pixel();
    float dR = FDRMHLGI_Depth(uv + float2(px.x, 0.0));
    float dL = FDRMHLGI_Depth(uv - float2(px.x, 0.0));
    float dU = FDRMHLGI_Depth(uv + float2(0.0, px.y));
    float dD = FDRMHLGI_Depth(uv - float2(0.0, px.y));
    float rawDepth = FDRMHLGI_RawDepth(uv);
    float rangeMask = step(FDRMHLGI_EPS, rawDepth) * step(rawDepth, 0.999990);
    float slope = abs(dR - dL) + abs(dU - dD);
    float centerFit = abs(dR - centerDepth) + abs(dL - centerDepth) + abs(dU - centerDepth) + abs(dD - centerDepth);
    float continuity = 1.0 - saturate((slope + centerFit * 0.25) * 30.0);
    float tierBias = (FDRMHLGI_PresetTier == 0) ? 0.12 : ((FDRMHLGI_PresetTier == 1) ? 0.0 : -0.08);
    return saturate(lerp(1.0, rangeMask * continuity, saturate(FDRMHLGI_DepthGate + tierBias)));
}

float3 FDRMHLGI_PseudoNormal(float2 uv)
{
    float2 px = FDRMHLGI_Pixel();
    float dR = FDRMHLGI_Depth(uv + float2(px.x, 0.0));
    float dL = FDRMHLGI_Depth(uv - float2(px.x, 0.0));
    float dU = FDRMHLGI_Depth(uv + float2(0.0, px.y));
    float dD = FDRMHLGI_Depth(uv - float2(0.0, px.y));
    float zScale = max(px.x, px.y) * 64.0 + 0.05;
    return normalize(float3(dL - dR, dD - dU, zScale));
}

float2 FDRMHLGI_FibonacciDirection(float fibIndex)
{
    const float goldenAngle = 2.39996323;
    float angle = fibIndex * goldenAngle;
    return float2(cos(angle), sin(angle));
}

float2 FDRMHLGI_OrganicDirection(float2 lensOffset, float fibIndex, float2 uv, float tapNorm)
{
    float2 fibDir = FDRMHLGI_FibonacciDirection(fibIndex);
    float2 lensDir = normalize(float2(0.23 - lensOffset.y, 0.17 + lensOffset.x + frac(fibIndex * 0.000618)));
    float2 baseDir = normalize(lerp(lensDir, fibDir, 0.40 + 0.30 * tapNorm));
    float phase = fibIndex * 0.013 + FDRMHLGI_OrganicFlow * 0.19 + dot(uv * 80.0, float2(0.754, 0.569));
    float cs = cos(phase);
    float sn = sin(phase);
    return normalize(float2(baseDir.x * cs - baseDir.y * sn, baseDir.x * sn + baseDir.y * cs));
}

float FDRMHLGI_HatchLine(float2 p, float2 dir, float phase, float density)
{
    float value = sin(dot(p, dir) * density + phase);
    return smoothstep(0.72, 0.96, value);
}

float FDRMHLGI_HatchLensField(float2 uv, float2 lensOffset, float fibIndex, float tapNorm)
{
    float2 p = uv * FDRMHLGI_HatchPatternScale;
    float phaseBase = fibIndex * 0.013 + FDRMHLGI_OrganicFlow * 0.15;
    float2 dirA = normalize(float2(0.23 - lensOffset.y, 0.17 + lensOffset.x + frac(fibIndex * 0.000618)));
    float2 dirB = float2(-dirA.y, dirA.x);

    float growth = 0.45 + 0.55 * tapNorm;
    float2 spread = lensOffset * FDRMHLGI_HatchTapSpread * growth;
    float lineA = FDRMHLGI_HatchLine(p + spread, dirA, phaseBase, FDRMHLGI_HatchDensity);
    float lineB = FDRMHLGI_HatchLine(p - spread.yx, dirB, phaseBase * 1.13 + 1.7, FDRMHLGI_HatchDensity * 1.10);
    float mask = saturate(lineA * 0.65 + lineB * 0.35);
    return saturate((mask - 0.5) * FDRMHLGI_HatchContrast + 0.5);
}

float2 FDRMHLGI_Rotate(float2 v, float radians)
{
    float cs = cos(radians);
    float sn = sin(radians);
    return float2(v.x * cs - v.y * sn, v.x * sn + v.y * cs);
}

void FDRMHLGI_AccumulateRayStep(
    float2 uv,
    float centerDepth,
    float2 rayStep,
    int stepIndex,
    int raySteps,
    float invRaySteps,
    float thickness,
    float depthEdge,
    float depthFalloff,
    float diffuseWeight,
    float hatchLens,
    inout float3 lightColor,
    inout float lightWeight)
{
    if (stepIndex <= raySteps)
    {
        float t = float(stepIndex) * invRaySteps;
        float2 sampleUv = uv + rayStep * t;
        float3 sampleColor = FDRMHLGI_Source(sampleUv);
        float sampleDepth = FDRMHLGI_Depth(sampleUv);
        float depthDelta = sampleDepth - centerDepth;
        float depthMatch = 1.0 - smoothstep(thickness, depthEdge, abs(depthDelta));
        float behindMask = step(centerDepth - FDRMHLGI_DepthBias, sampleDepth);
        float distanceWeight = exp(-t * depthFalloff * 0.0100);
        float hitWeight = saturate(depthMatch * behindMask * distanceWeight);

        float organicBias = lerp(1.0, lerp(0.75, 1.35, hatchLens), FDRMHLGI_OrganicPreference);
        float classicBias = lerp(0.80, 1.25, diffuseWeight);
        float finalWeight = hitWeight * organicBias * classicBias;
        lightColor += sampleColor * finalWeight;
        lightWeight += finalWeight;
    }
}

void FDRMHLGI_RayMarchDirection(
    float2 uv,
    float centerDepth,
    float2 direction,
    int raySteps,
    float rayGrowth,
    float diffuseWeight,
    float hatchLens,
    out float3 lightColor,
    out float lightWeight)
{
    float2 rayStep = direction * FDRMHLGI_Pixel() * FDRMHLGI_RayLengthPixels * FDRMHLGI_TierLengthScale() * rayGrowth;
    float invRaySteps = rcp(max(1.0, float(raySteps)));
    float thickness = max(0.0001, FDRMHLGI_Thickness);
    float depthEdge = thickness * 2.0 + FDRMHLGI_EPS;
    float depthFalloff = max(0.01, FDRMHLGI_DepthFalloff);

    lightColor = 0.0;
    lightWeight = 0.0;

    #define FDRMHLGI_RAY_STEP(STEP_INDEX) \
        FDRMHLGI_AccumulateRayStep(uv, centerDepth, rayStep, (STEP_INDEX), raySteps, invRaySteps, thickness, depthEdge, depthFalloff, diffuseWeight, hatchLens, lightColor, lightWeight);
    FDRMHLGI_RAY_STEP(1)
    FDRMHLGI_RAY_STEP(2)
    FDRMHLGI_RAY_STEP(3)
    FDRMHLGI_RAY_STEP(4)
    FDRMHLGI_RAY_STEP(5)
    FDRMHLGI_RAY_STEP(6)
    FDRMHLGI_RAY_STEP(7)
    FDRMHLGI_RAY_STEP(8)
    #undef FDRMHLGI_RAY_STEP
}

void FDRMHLGI_AccumulateTap(
    float2 uv,
    float centerDepth,
    float3 centerNormal,
    float2 lensOffset,
    int tapIndex,
    int tapCount,
    int raySteps,
    inout float3 lightColor,
    inout float lightWeight,
    inout float hatchSum,
    inout float hatchWeight)
{
    if (tapIndex < tapCount)
    {
        float tapNorm = (float(tapIndex) + 0.5) / max(1.0, float(tapCount));
        float fibIndex = FDRMHLGI_FibAnchor + float(tapIndex);
        float hatchLens = FDRMHLGI_HatchLensField(uv, lensOffset, fibIndex, tapNorm);

        float2 baseDir = FDRMHLGI_OrganicDirection(lensOffset, fibIndex, uv, tapNorm);
        float bend = (hatchLens - 0.5) * FDRMHLGI_HatchLensStrength * 1.5707963;
        float2 direction = normalize(FDRMHLGI_Rotate(baseDir, bend));
        float rayGrowth = FDREAM_Lens55FibonacciGrowth(tapIndex, tapCount) * lerp(0.75, 1.35, hatchLens * FDRMHLGI_HatchLensStrength);
        float3 dir3 = normalize(float3(direction.xy, 0.45));
        float diffuseWeight = saturate(dot(centerNormal, dir3) * 0.5 + 0.5);

        float3 tapLight = 0.0;
        float tapWeight = 0.0;
        FDRMHLGI_RayMarchDirection(uv, centerDepth, direction, raySteps, rayGrowth, diffuseWeight, hatchLens, tapLight, tapWeight);

        lightColor += tapLight;
        lightWeight += tapWeight;
        hatchSum += hatchLens;
        hatchWeight += 1.0;
    }
}

float4 FDRMHLGI_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    int tapCount = min(clamp(FDRMHLGI_TapCount, 1, FDREAM_LENS55_TAP_COUNT), FDRMHLGI_TierTapCap());
    int raySteps = min(clamp(FDRMHLGI_RaySteps, 1, 8), FDRMHLGI_TierStepCap());
    float3 sourceColor = FDRMHLGI_Source(uv);
    float centerDepth = FDRMHLGI_Depth(uv);
    float depthGate = FDRMHLGI_DepthActivity(uv, centerDepth);
    float3 centerNormal = FDRMHLGI_PseudoNormal(uv);

    float3 lightColor = sourceColor;
    float lightWeight = 1.0;
    float hatchSum = 0.0;
    float hatchWeight = 0.0;

    [loop]
    for (int tapIndex = 0; tapIndex < FDREAM_LENS55_TAP_COUNT; ++tapIndex)
    {
        if (tapIndex < tapCount)
        {
            FDRMHLGI_AccumulateTap(uv, centerDepth, centerNormal, FDREAM_Lens55Offset(tapIndex), tapIndex, tapCount, raySteps, lightColor, lightWeight, hatchSum, hatchWeight);
        }
    }

    float3 localIndirect = lightColor / max(FDRMHLGI_EPS, lightWeight);
    localIndirect = FDRMHLGI_SaturateAroundLuma(localIndirect, FDRMHLGI_ColorBleedSaturation);

    float hatchLens = hatchSum / max(1.0, hatchWeight);
    float coverage = saturate(lightWeight / max(1.0, float(tapCount * raySteps)));
    float organicCoverage = lerp(coverage, coverage * (0.65 + 0.35 * hatchLens), FDRMHLGI_OrganicPreference);

    float3 bounce = saturate(localIndirect - sourceColor);
    float strength = FDRMHLGI_GIStrength * FDRMHLGI_MasterIntensity * FDRMHLGI_TierStrengthScale();
    float3 additiveGI = saturate(sourceColor + bounce * strength * FDRMHLGI_MaxContribution);

    float lightProtectMask = FDRMHLGI_LightEmissionMask(sourceColor);
    float lightZone = FDRMHLGI_LocalLightZone(uv, sourceColor, lightProtectMask);
    float hatchApply = lerp(1.0, saturate(0.40 + 0.60 * hatchLens), FDRMHLGI_OrganicPreference);
    float applicationMask = saturate(depthGate * hatchApply * organicCoverage * (1.0 - lightZone * 0.75));
    float3 giColor = lerp(sourceColor, additiveGI, saturate(applicationMask * FDRMHLGI_MasterIntensity));
    giColor = FC_LIGHT_ProtectColor(giColor, sourceColor, lightProtectMask, FDRMHLGI_LightProtectStrength);
    float fogBypass = FC_FOG_BypassMask(uv, sourceColor, FDRMHLGI_RespectFog);
    float3 finalColor = lerp(giColor, sourceColor, fogBypass);
    float computedMask = applicationMask;
    float tierMaxBudget = max(1.0, float(FDRMHLGI_TierTapCap() * FDRMHLGI_TierStepCap()));
    float budgetView = saturate(float(tapCount * raySteps) / tierMaxBudget);
    if (FDRMHLGI_DebugView == 1) return float4(saturate(localIndirect), 1.0);
    if (FDRMHLGI_DebugView == 2) return float4(FDRMHLGI_DebugScalar(hatchLens).xxx, 1.0);
    if (FDRMHLGI_DebugView == 3) return float4(FDRMHLGI_DebugScalar(applicationMask).xxx, 1.0);
    if (FDRMHLGI_DebugView == 4) return float4(FDRMHLGI_DebugScalar(budgetView).xxx, 1.0);
    if (FDRMHLGI_DebugView == 5) return float4(FDRMHLGI_DebugScalar(organicCoverage).xxx, 1.0);
    if (FDRMHLGI_DebugView == 6) return float4(FDRMHLGI_DebugScalar(computedMask).xxx, 1.0);
    return float4(saturate(finalColor), 1.0);
}
technique fine_dream_bio_raym_hatch_lens_global_illumination < ui_label = "Fine Cell - Global Illumination - Bio Ray-M Hatch Lens"; ui_tooltip = "--Ray-M Global Illumination that uses an bio hatch lens for sampling and applies Global Illumination-only shading."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FDRMHLGI_MainPS;
    }
}







