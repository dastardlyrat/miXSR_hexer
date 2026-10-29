// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: dream-Global Illumination-1
// Capability: Portable Fibonacci bio --Ray-M global illumination driver with preset-tier budgeting.



#include "ReShade.fxh"
#include "FineCell_FogGate.fxh"
#include "FineCell_LightRespect.fxh"
#include "FineDream_Lens55Bounded.fxh"

uniform int FDRMGI_PresetTier <
    ui_type = "combo";
    ui_label = "Preset Tier";
    ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 02 Main Settings";
    ui_items = "Basic Conservative\0Liberal Coverage\0Aggressive Aggregate\0High Fidelity\0Ultra Fidelity\0";
    ui_tooltip = "High Fidelity is the base standard; Ultra raises bounded Lens55 ray direction coverage while keeping ray steps compact.";
> = 3;

uniform int FDRMGI_DebugView <
    ui_type = "combo";
    ui_label = "Debug View";
    ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 00 Debug"; ui_category_closed = true;
    ui_items = "Final\0Local Light\0Application Mask\0Depth Gate\0Ray Budget\0";
    ui_tooltip = "Shows the final output or diagnostic masks.";
> = 0;

uniform float FDRMGI_MasterIntensity < ui_type = "slider"; ui_label = "Master Intensity"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Overall multiplier for --Ray-M Global Illumination."; > = 1.000000;
uniform float FDRMGI_GIStrength < ui_type = "slider"; ui_label = "Global Illumination Strength"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 02 Main Settings"; ui_min = 0.0; ui_max = 3.0; ui_step = 0.001; ui_tooltip = "How strongly ray hits add bounced light."; > = 0.420000;
uniform float FDRMGI_RayLengthPixels < ui_type = "slider"; ui_label = "Ray Length"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.5; ui_max = 64.0; ui_step = 0.01; ui_tooltip = "Maximum length of each ray in screen pixels before tier scaling."; > = 12.000000;
uniform int FDRMGI_RaySteps < ui_type = "slider"; ui_label = "Ray Steps"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 03 Sub Settings"; ui_category_closed = true; ui_min = 2; ui_max = 11; ui_step = 1; ui_tooltip = "Maximum compact ray steps available to the active tier. High Fidelity defaults to the full 8-step body."; > = 8;
uniform int FDRMGI_TapCount < ui_type = "slider"; ui_label = "Tap Budget"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 03 Sub Settings"; ui_category_closed = true; ui_min = 4; ui_max = FDREAM_LENS55_TAP_COUNT; ui_step = 1; ui_tooltip = "Bounded Lens55 ray direction budget. High and Ultra fidelity increase tap coverage without expanding ray-step bodies."; > = 34;
uniform float FDRMGI_Thickness < ui_type = "slider"; ui_label = "Depth Thickness"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0001; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Depth hit tolerance for accepting ray samples."; > = 0.010000;
uniform float FDRMGI_DepthBias < ui_type = "slider"; ui_label = "Depth Bias"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Self-intersection bias for ray hits."; > = 0.001000;
uniform float FDRMGI_DepthFalloff < ui_type = "slider"; ui_label = "Depth Falloff"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.01; ui_max = 256.0; ui_step = 0.01; ui_tooltip = "Distance falloff applied along accepted ray hits."; > = 48.000000;
uniform float FDRMGI_DepthGate < ui_type = "slider"; ui_label = "Depth Gate"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Suppresses ray Global Illumination when depth has weak signal or harsh discontinuities."; > = 0.650000;
uniform float FDRMGI_FibAnchor < ui_type = "slider"; ui_label = "Fibonacci Anchor"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 03 Sub Settings"; ui_category_closed = true; ui_min = 987.0; ui_max = 4181.0; ui_step = 1.0; ui_tooltip = "Anchor index for bio Fibonacci ray directions."; > = 2584.000000;
uniform float FDRMGI_OrganicFlow < ui_type = "slider"; ui_label = "bio Flow"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Phase drift for Fibonacci-derived ray direction."; > = 1.600000;
uniform float FDRMGI_ColorBleedSaturation < ui_type = "slider"; ui_label = "Bleed Saturation"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Saturation of ray-hit indirect color."; > = 1.100000;
uniform float FDRMGI_MaxContribution < ui_type = "slider"; ui_label = "Max Contribution"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Upper cap for bounced light contribution."; > = 1.600000;
uniform int FDRMGI_RespectFog < ui_type = "combo"; ui_label = "Respect Fog"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Bypasses Global Illumination in fog-dominant regions."; > = 1;
uniform int FDRMGI_RespectLight < ui_type = "combo"; ui_label = "Respect Light Emission"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Protects emissive pixels from being dimmed or recolored."; > = 1;
uniform float FDRMGI_LightProtectStrength < ui_type = "slider"; ui_label = "Light Protect Strength"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "How strongly protected lights return to the source color."; > = 0.900000;
uniform float FDRMGI_DebugExposure < ui_type = "slider"; ui_label = "Debug Exposure"; ui_category = "Fine Cell - Global Illumination - Bio Ray-M Bounce / 00 Debug"; ui_category_closed = true; ui_min = 1.0; ui_max = 32.0; ui_step = 0.1; ui_tooltip = "Boosts debug buffer visibility."; > = 8.000000;

float2 FDRMGI_Pixel() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
float3 FDRMGI_Source(float2 uv) { return tex2D(ReShade::BackBuffer, saturate(uv)).rgb; }
float FDRMGI_RawDepth(float2 uv) { return tex2D(ReShade::DepthBuffer, saturate(uv)).r; }
float FDRMGI_Depth(float2 uv) { return saturate(ReShade::GetLinearizedDepth(saturate(uv))); }
float FDRMGI_Luma(float3 color) { return dot(color, float3(0.2126, 0.7152, 0.0722)); }
float3 FDRMGI_SaturateAroundLuma(float3 color, float amount) { float luma = FDRMGI_Luma(color); return lerp(luma.xxx, color, amount); }

int FDRMGI_TierTapCap()
{
    return FDREAM_Lens55TierTapCap(FDRMGI_PresetTier);
}

int FDRMGI_TierStepCap()
{
    if (FDRMGI_PresetTier == 0) return 4;
    if (FDRMGI_PresetTier == 1) return 6;
    return 8;
}

float FDRMGI_TierLengthScale()
{
    return FDREAM_Lens55TierScale(FDRMGI_PresetTier);
}

float FDRMGI_TierStrengthScale()
{
    if (FDRMGI_PresetTier == 0) return 0.72;
    if (FDRMGI_PresetTier == 1) return 1.00;
    if (FDRMGI_PresetTier == 2) return 1.18;
    if (FDRMGI_PresetTier == 3) return 1.25;
    return 1.32;
}

float FDRMGI_DebugScalar(float value)
{
    return pow(saturate(value * max(1.0, FDRMGI_DebugExposure)), 0.65);
}

float FDRMGI_LightEmissionMask(float3 sourceColor)
{
    if (FDRMGI_RespectLight == 0)
    {
        return 0.0;
    }

    return FC_LIGHT_EmissionMask(
        sourceColor,
        FDRMGI_Luma(sourceColor),
        0.680000,
        0.180000,
        0.700000,
        0.350000,
        0.220000,
        0.000010);
}

float FDRMGI_LocalLightZone(float2 uv, float3 sourceColor, float centerLightMask)
{
    if (FDRMGI_RespectLight == 0)
    {
        return 0.0;
    }

    float2 px = FDRMGI_Pixel() * 2.0;
    float zone = centerLightMask;
    zone = max(zone, FDRMGI_LightEmissionMask(FDRMGI_Source(uv + float2(px.x, 0.0))));
    zone = max(zone, FDRMGI_LightEmissionMask(FDRMGI_Source(uv - float2(px.x, 0.0))));
    zone = max(zone, FDRMGI_LightEmissionMask(FDRMGI_Source(uv + float2(0.0, px.y))));
    zone = max(zone, FDRMGI_LightEmissionMask(FDRMGI_Source(uv - float2(0.0, px.y))));
    return saturate(zone * FDRMGI_LightProtectStrength);
}

float FDRMGI_DepthActivity(float2 uv, float centerDepth)
{
    float2 px = FDRMGI_Pixel();
    float dR = FDRMGI_Depth(uv + float2(px.x, 0.0));
    float dL = FDRMGI_Depth(uv - float2(px.x, 0.0));
    float dU = FDRMGI_Depth(uv + float2(0.0, px.y));
    float dD = FDRMGI_Depth(uv - float2(0.0, px.y));
    float rawDepth = FDRMGI_RawDepth(uv);
    float rangeMask = step(0.000010, rawDepth) * step(rawDepth, 0.999990);
    float slope = abs(dR - dL) + abs(dU - dD);
    float centerFit = abs(dR - centerDepth) + abs(dL - centerDepth) + abs(dU - centerDepth) + abs(dD - centerDepth);
    float continuity = 1.0 - saturate((slope + centerFit * 0.25) * 30.0);
    float tierBias = (FDRMGI_PresetTier == 0) ? 0.12 : ((FDRMGI_PresetTier == 1) ? 0.0 : -0.08);
    return saturate(lerp(1.0, rangeMask * continuity, saturate(FDRMGI_DepthGate + tierBias)));
}

float2 FDRMGI_FibonacciDirection(float fibIndex)
{
    const float goldenAngle = 2.39996323;
    float angle = fibIndex * goldenAngle;
    return float2(cos(angle), sin(angle));
}

float2 FDRMGI_OrganicDirection(float2 lensOffset, float fibIndex, float2 uv, float tapNorm)
{
    float2 fibDir = FDRMGI_FibonacciDirection(fibIndex);
    float2 lensDir = normalize(float2(0.23 - lensOffset.y, 0.17 + lensOffset.x + frac(fibIndex * 0.000618)));
    float2 baseDir = normalize(lerp(lensDir, fibDir, 0.40 + 0.30 * tapNorm));
    float phase = fibIndex * 0.013 + FDRMGI_OrganicFlow * 0.19 + dot(uv * 80.0, float2(0.754, 0.569));
    float cs = cos(phase);
    float sn = sin(phase);
    return normalize(float2(baseDir.x * cs - baseDir.y * sn, baseDir.x * sn + baseDir.y * cs));
}

void FDRMGI_AccumulateRayStep(
    float2 uv,
    float centerDepth,
    float2 rayStep,
    int stepIndex,
    int raySteps,
    float invRaySteps,
    float thickness,
    float depthEdge,
    float depthFalloff,
    inout float3 conservativeColor,
    inout float conservativeWeight,
    inout float3 liberalColor,
    inout float liberalWeight)
{
    if (stepIndex <= raySteps)
    {
        float t = float(stepIndex) * invRaySteps;
        float2 sampleUv = uv + rayStep * t;
        float3 sampleColor = FDRMGI_Source(sampleUv);
        float sampleDepth = FDRMGI_Depth(sampleUv);
        float depthDelta = sampleDepth - centerDepth;
        float depthMatch = 1.0 - smoothstep(thickness, depthEdge, abs(depthDelta));
        float behindMask = step(centerDepth - FDRMGI_DepthBias, sampleDepth);
        float conservativeDistance = exp(-t * depthFalloff * 0.0125);
        float liberalDistance = exp(-t * depthFalloff * 0.0060);
        float conservativeHit = saturate(depthMatch * behindMask * conservativeDistance);
        float liberalHit = saturate((depthMatch * 0.65 + 0.35 * behindMask) * liberalDistance);

        conservativeColor += sampleColor * conservativeHit;
        conservativeWeight += conservativeHit;
        liberalColor += sampleColor * liberalHit;
        liberalWeight += liberalHit;
    }
}

void FDRMGI_RayMarchDirection(
    float2 uv,
    float centerDepth,
    float2 direction,
    int raySteps,
    float rayGrowth,
    out float3 conservativeColor,
    out float conservativeWeight,
    out float3 liberalColor,
    out float liberalWeight)
{
    float2 rayStep = direction * FDRMGI_Pixel() * FDRMGI_RayLengthPixels * FDRMGI_TierLengthScale() * rayGrowth;
    float invRaySteps = rcp(max(1.0, float(raySteps)));
    float thickness = max(0.0001, FDRMGI_Thickness);
    float depthEdge = thickness * 2.0 + 0.000010;
    float depthFalloff = max(0.01, FDRMGI_DepthFalloff);

    conservativeColor = 0.0;
    conservativeWeight = 0.0;
    liberalColor = 0.0;
    liberalWeight = 0.0;

    #define FDRMGI_RAY_STEP(STEP_INDEX) \
        FDRMGI_AccumulateRayStep(uv, centerDepth, rayStep, (STEP_INDEX), raySteps, invRaySteps, thickness, depthEdge, depthFalloff, conservativeColor, conservativeWeight, liberalColor, liberalWeight);
    FDRMGI_RAY_STEP(1)
    FDRMGI_RAY_STEP(2)
    FDRMGI_RAY_STEP(3)
    FDRMGI_RAY_STEP(4)
    FDRMGI_RAY_STEP(5)
    FDRMGI_RAY_STEP(6)
    FDRMGI_RAY_STEP(7)
    FDRMGI_RAY_STEP(8)
    #undef FDRMGI_RAY_STEP
}

void FDRMGI_AccumulateTap(
    float2 uv,
    float centerDepth,
    float2 lensOffset,
    int tapIndex,
    int tapCount,
    int raySteps,
    inout float3 conservativeLight,
    inout float conservativeWeight,
    inout float3 liberalLight,
    inout float liberalWeight)
{
    float3 conservativeColor = 0.0;
    float conservativeHit = 0.0;
    float3 liberalColor = 0.0;
    float liberalHit = 0.0;

    if (tapIndex < tapCount)
    {
        float tapNorm = (float(tapIndex) + 0.5) / max(1.0, float(tapCount));
        float fibIndex = FDRMGI_FibAnchor + float(tapIndex);
        float2 direction = FDRMGI_OrganicDirection(lensOffset, fibIndex, uv, tapNorm);
        float rayGrowth = FDREAM_Lens55FibonacciGrowth(tapIndex, tapCount);

        FDRMGI_RayMarchDirection(uv, centerDepth, direction, raySteps, rayGrowth, conservativeColor, conservativeHit, liberalColor, liberalHit);
        conservativeLight += conservativeColor;
        conservativeWeight += conservativeHit;
        liberalLight += liberalColor;
        liberalWeight += liberalHit;
    }
}

float4 FDRMGI_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    int tapCount = min(clamp(FDRMGI_TapCount, 1, FDREAM_LENS55_TAP_COUNT), FDRMGI_TierTapCap());
    int raySteps = min(clamp(FDRMGI_RaySteps, 1, 8), FDRMGI_TierStepCap());
    float3 sourceColor = FDRMGI_Source(uv);
    float centerDepth = FDRMGI_Depth(uv);
    float depthGate = FDRMGI_DepthActivity(uv, centerDepth);

    float3 conservativeLight = sourceColor;
    float conservativeWeight = 1.0;
    float3 liberalLight = sourceColor;
    float liberalWeight = 1.0;

    [loop]
    for (int tapIndex = 0; tapIndex < FDREAM_LENS55_TAP_COUNT; ++tapIndex)
    {
        if (tapIndex < tapCount)
        {
            FDRMGI_AccumulateTap(uv, centerDepth, FDREAM_Lens55Offset(tapIndex), tapIndex, tapCount, raySteps, conservativeLight, conservativeWeight, liberalLight, liberalWeight);
        }
    }

    float3 conservativeLocal = conservativeLight / max(0.000010, conservativeWeight);
    float3 liberalLocal = liberalLight / max(0.000010, liberalWeight);
    float aggregateBlend = (FDRMGI_PresetTier >= 4) ? 0.72 : ((FDRMGI_PresetTier == 3) ? 0.64 : ((FDRMGI_PresetTier == 2) ? 0.60 : ((FDRMGI_PresetTier == 1) ? 0.38 : 0.18)));
    float3 localLight = lerp(conservativeLocal, liberalLocal, aggregateBlend);
    localLight = FDRMGI_SaturateAroundLuma(localLight, FDRMGI_ColorBleedSaturation);

    float hitCoverage = saturate((conservativeWeight + liberalWeight) / max(1.0, float(tapCount * raySteps)));
    float hitMask = lerp(hitCoverage, 1.0 - exp(-hitCoverage * 4.0), 0.25);
    float lightProtectMask = FDRMGI_LightEmissionMask(sourceColor);
    float lightZone = FDRMGI_LocalLightZone(uv, sourceColor, lightProtectMask);
    float applicationMask = saturate(hitMask * depthGate * (1.0 - lightZone * 0.75));

    float3 bounce = saturate(localLight - sourceColor);
    float strength = FDRMGI_GIStrength * FDRMGI_MasterIntensity * FDRMGI_TierStrengthScale();
    float3 giColor = saturate(sourceColor + bounce * strength * FDRMGI_MaxContribution * applicationMask);
    giColor = FC_LIGHT_ProtectColor(giColor, sourceColor, lightProtectMask, FDRMGI_LightProtectStrength);
    float fogBypass = FC_FOG_BypassMask(uv, sourceColor, FDRMGI_RespectFog);
    float3 finalColor = lerp(giColor, sourceColor, fogBypass);
    float budgetView = saturate(float(tapCount * raySteps) / float(FDREAM_LENS55_TAP_COUNT * 8));

    if (FDRMGI_DebugView == 1) return float4(saturate(localLight), 1.0);
    if (FDRMGI_DebugView == 2) return float4(FDRMGI_DebugScalar(applicationMask).xxx, 1.0);
    if (FDRMGI_DebugView == 3) return float4(FDRMGI_DebugScalar(depthGate).xxx, 1.0);
    if (FDRMGI_DebugView == 4) return float4(FDRMGI_DebugScalar(budgetView).xxx, 1.0);
    return float4(saturate(finalColor), 1.0);
}
technique fine_dream_bio_raym_global_illumination < ui_label = "Fine Cell - Global Illumination - Bio Ray-M Bounce"; ui_tooltip = "Portable Fibonacci bio --Ray-M Global Illumination with bounded Lens55 high/ultra fidelity tiers."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FDRMGI_MainPS;
    }
}






