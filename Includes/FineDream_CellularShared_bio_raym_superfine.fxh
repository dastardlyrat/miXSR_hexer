// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Shared compile-safe cell-shader helpers for fine_dream drivers.

#ifndef FINE_DREAM_CELLULAR_SHARED_FXH
#define FINE_DREAM_CELLULAR_SHARED_FXH

#include "ReShade.fxh"
#include "FineCell_FogGate.fxh"
#include "FineCell_LightRespect.fxh"
#include "FineDream_Lens55Bounded.fxh"

#define FDREAM_CELL_EPS 0.000010

uniform int FDREAM_CELL_PresetTier < ui_type = "combo"; ui_label = "Preset Tier"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 00 Driver"; ui_items = "Basic Conservative\0Liberal Coverage\0Aggressive Aggregate\0High Fidelity\0Ultra Fidelity\0"; ui_tooltip = "High Fidelity is the base standard; Ultra uses all bounded Lens55 taps without expanding cell-shader bodies."; > = 2;
uniform int FDREAM_CELL_DebugView < ui_type = "combo"; ui_label = "Debug View"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 08 Debug"; ui_items = "Final\0Cel\0Edge\0Hit Or Detail\0Depth Gate\0Ray Budget\0"; ui_tooltip = "Shows final output or diagnostic masks."; > = 0;
uniform float FDREAM_CELL_MasterIntensity < ui_type = "slider"; ui_label = "Master Intensity"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 01 Main"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Overall cell-shader strength multiplier."; > = 0.550000;
uniform float FDREAM_CELL_CelStrength < ui_type = "slider"; ui_label = "Cel Strength"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 01 Main"; ui_min = 0.0; ui_max = 2.3; ui_step = 0.001; ui_tooltip = "Blend amount of cel banding."; > = 1.431000;
uniform float FDREAM_CELL_EdgeStrength < ui_type = "slider"; ui_label = "Edge Strength"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 01 Main"; ui_min = 0.0; ui_max = 3.0; ui_step = 0.001; ui_tooltip = "Darkening amount for edge inking."; > = 0.000000;
uniform float FDREAM_CELL_SuperfineStrength < ui_type = "slider"; ui_label = "Superfine Strength"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 01 Main"; ui_min = 0.0; ui_max = 3.0; ui_step = 0.001; ui_tooltip = "Micro-detail enhancement for superfine drivers."; > = 0.736000;
uniform int FDREAM_CELL_CelBands < ui_type = "slider"; ui_label = "Cel Bands"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 02 Cel"; ui_min = 2; ui_max = 21; ui_step = 1; ui_tooltip = "Number of luminance bands used for cel quantization."; > = 16;
uniform float FDREAM_CELL_FineBandContrast < ui_type = "slider"; ui_label = "Fine Band Contrast"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 02 Cel"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Contrast shaping for banded luminance."; > = 1.029000;
uniform float FDREAM_CELL_RadiusPixels < ui_type = "slider"; ui_label = "bio Radius"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 03 Sampling"; ui_min = 0.25; ui_max = 16.0; ui_step = 0.01; ui_tooltip = "bio sample radius in screen pixels."; > = 2.000000;
uniform int FDREAM_CELL_TapCount < ui_type = "slider"; ui_label = "Tap Budget"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 03 Sampling"; ui_min = 4; ui_max = FDREAM_LENS55_TAP_COUNT; ui_step = 1; ui_tooltip = "Bounded Lens55 tap budget shared by broad, superfine, and --Ray-M cell-shader drivers."; > = 34;
uniform float FDREAM_CELL_EdgeRadiusPixels < ui_type = "slider"; ui_label = "Edge Radius"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 04 Edge"; ui_min = 0.25; ui_max = 8.0; ui_step = 0.01; ui_tooltip = "Sampling radius for edge detection."; > = 0.760000;
uniform float FDREAM_CELL_EdgeLumaGain < ui_type = "slider"; ui_label = "Luma Edge Gain"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 04 Edge"; ui_min = 0.0; ui_max = 32.0; ui_step = 0.01; ui_tooltip = "Gain applied to luminance edge signal."; > = 6.000000;
uniform float FDREAM_CELL_EdgeDepthGain < ui_type = "slider"; ui_label = "Depth Edge Gain"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 04 Edge"; ui_min = 0.0; ui_max = 300.0; ui_step = 0.1; ui_tooltip = "Gain applied to depth edge signal."; > = 110.000000;
uniform float FDREAM_CELL_EdgeThreshold < ui_type = "slider"; ui_label = "Edge Threshold"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 04 Edge"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Threshold where edge response starts."; > = 0.160000;
uniform float FDREAM_CELL_EdgeSoftness < ui_type = "slider"; ui_label = "Edge Softness"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 04 Edge"; ui_min = 0.01; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Soft transition width around edge threshold."; > = 0.260000;
uniform float FDREAM_CELL_DepthGate < ui_type = "slider"; ui_label = "Depth Gate"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 05 Stability"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Gates stylization in unstable depth regions."; > = 0.650000;
uniform float FDREAM_CELL_CleanupStrength < ui_type = "slider"; ui_label = "Cleanup Strength"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 05 Stability"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Depth-aware stabilization for edge/detail masks."; > = 0.500000;
uniform float FDREAM_CELL_ChromaStability < ui_type = "slider"; ui_label = "Chroma Stability"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 05 Stability"; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "Suppresses static tint by biasing stable superfine detail toward luminance."; > = 0.750000;
uniform float FDREAM_CELL_ChromaClamp < ui_type = "slider"; ui_label = "Chroma Clamp"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 05 Stability"; ui_min = 0.0; ui_max = 0.250; ui_step = 0.001; ui_tooltip = "Clamps chroma-only superfine detail after stability suppression."; > = 0.060000;
uniform float FDREAM_CELL_RayLengthPixels < ui_type = "slider"; ui_label = "Ray Length"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 06 Trace"; ui_min = 0.5; ui_max = 32.0; ui_step = 0.01; ui_tooltip = "Ray length in screen pixels for --Ray-M cell-shader drivers."; > = 10.000000;
uniform int FDREAM_CELL_RaySteps < ui_type = "slider"; ui_label = "Ray Steps"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 06 Trace"; ui_min = 2; ui_max = 11; ui_step = 1; ui_tooltip = "Compact ray step budget. High Fidelity defaults to the full 8-step body."; > = 8;
uniform float FDREAM_CELL_Thickness < ui_type = "slider"; ui_label = "Hit Thickness"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 06 Trace"; ui_min = 0.0001; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Depth hit tolerance for --Ray-M drivers."; > = 0.010000;
uniform float FDREAM_CELL_DepthBias < ui_type = "slider"; ui_label = "Depth Bias"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 06 Trace"; ui_min = 0.0; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Self-hit bias for --Ray-M drivers."; > = 0.001000;
uniform float FDREAM_CELL_DepthFalloff < ui_type = "slider"; ui_label = "Depth Falloff"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 06 Trace"; ui_min = 0.01; ui_max = 256.0; ui_step = 0.01; ui_tooltip = "Distance falloff shaping for ray contribution."; > = 48.000000;
uniform float FDREAM_CELL_FibAnchor < ui_type = "slider"; ui_label = "Fibonacci Anchor"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 07 bio"; ui_min = 987.0; ui_max = 4181.0; ui_step = 1.0; ui_tooltip = "Anchor index for Fibonacci bio direction generation."; > = 2584.000000;
uniform float FDREAM_CELL_OrganicFlow < ui_type = "slider"; ui_label = "bio Flow"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 07 bio"; ui_min = 0.0; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Phase drift for bio sample directions."; > = 1.250000;
uniform int FDREAM_CELL_RespectFog < ui_type = "combo"; ui_label = "Respect Fog"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 09 Guards"; ui_items = "No\0Yes\0"; ui_tooltip = "Bypasses cell-shader in fog-dominant regions."; > = 1;
uniform int FDREAM_CELL_RespectLight < ui_type = "combo"; ui_label = "Respect Light"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 09 Guards"; ui_items = "No\0Yes\0"; ui_tooltip = "Protects emissive pixels from cell-shader."; > = 1;
uniform float FDREAM_CELL_LightProtectStrength < ui_type = "slider"; ui_label = "Light Protect Strength"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 09 Guards"; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "How strongly protected lights return to source color."; > = 0.900000;
uniform float FDREAM_CELL_FogBypassCap < ui_type = "slider"; ui_label = "Fog Bypass Cap"; ui_category = "Fine Cell - Cell Shading - Shared Driver / 09 Guards"; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "Caps fog bypass so FD cell shading remains visible in fog-heavy scenes."; > = 0.850000;

float2 FDREAM_CELL_Pixel() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
float3 FDREAM_CELL_Source(float2 uv) { return tex2D(ReShade::BackBuffer, saturate(uv)).rgb; }
float FDREAM_CELL_Depth(float2 uv) { return saturate(ReShade::GetLinearizedDepth(saturate(uv))); }
float FDREAM_CELL_Luma(float3 color) { return dot(color, float3(0.2126, 0.7152, 0.0722)); }

int FDREAM_CELL_TapCap()
{
    return FDREAM_Lens55TierTapCap(FDREAM_CELL_PresetTier);
}

int FDREAM_CELL_StepCap8()
{
    if (FDREAM_CELL_PresetTier == 0) return 4;
    if (FDREAM_CELL_PresetTier == 1) return 6;
    return 8;
}

float FDREAM_CELL_TierScale()
{
    return FDREAM_Lens55TierScale(FDREAM_CELL_PresetTier);
}

float FDREAM_CELL_LightMask(float3 sourceColor)
{
    if (FDREAM_CELL_RespectLight == 0)
    {
        return 0.0;
    }

    return FC_LIGHT_EmissionMask(sourceColor, FDREAM_CELL_Luma(sourceColor), 0.680000, 0.180000, 0.700000, 0.350000, 0.220000, FDREAM_CELL_EPS);
}

float FDREAM_CELL_DepthGateMask(float2 uv, float centerDepth)
{
    float2 px = FDREAM_CELL_Pixel();
    float dR = FDREAM_CELL_Depth(uv + float2(px.x, 0.0));
    float dL = FDREAM_CELL_Depth(uv - float2(px.x, 0.0));
    float dU = FDREAM_CELL_Depth(uv + float2(0.0, px.y));
    float dD = FDREAM_CELL_Depth(uv - float2(0.0, px.y));
    float slope = abs(dR - dL) + abs(dU - dD);
    float fit = abs(dR - centerDepth) + abs(dL - centerDepth) + abs(dU - centerDepth) + abs(dD - centerDepth);
    float continuity = 1.0 - saturate((slope + fit * 0.25) * 32.0);
    float tierBias = (FDREAM_CELL_PresetTier == 0) ? 0.10 : ((FDREAM_CELL_PresetTier == 1) ? 0.0 : -0.08);
    return saturate(lerp(1.0, continuity, saturate(FDREAM_CELL_DepthGate + tierBias)));
}

float FDREAM_CELL_Edge(float2 uv)
{
    float2 px = FDREAM_CELL_Pixel() * FDREAM_CELL_EdgeRadiusPixels;
    float centerDepth = FDREAM_CELL_Depth(uv);
    float centerLuma = FDREAM_CELL_Luma(FDREAM_CELL_Source(uv));
    float lumaEdge = abs(centerLuma - FDREAM_CELL_Luma(FDREAM_CELL_Source(uv + float2(px.x, 0.0)))) +
                     abs(centerLuma - FDREAM_CELL_Luma(FDREAM_CELL_Source(uv - float2(px.x, 0.0)))) +
                     abs(centerLuma - FDREAM_CELL_Luma(FDREAM_CELL_Source(uv + float2(0.0, px.y)))) +
                     abs(centerLuma - FDREAM_CELL_Luma(FDREAM_CELL_Source(uv - float2(0.0, px.y))));
    float depthEdge = abs(centerDepth - FDREAM_CELL_Depth(uv + float2(px.x, 0.0))) +
                      abs(centerDepth - FDREAM_CELL_Depth(uv - float2(px.x, 0.0))) +
                      abs(centerDepth - FDREAM_CELL_Depth(uv + float2(0.0, px.y))) +
                      abs(centerDepth - FDREAM_CELL_Depth(uv - float2(0.0, px.y)));
    float edgeScore = lumaEdge * FDREAM_CELL_EdgeLumaGain + depthEdge * FDREAM_CELL_EdgeDepthGain;
    return smoothstep(FDREAM_CELL_EdgeThreshold, FDREAM_CELL_EdgeThreshold + max(FDREAM_CELL_EPS, FDREAM_CELL_EdgeSoftness), edgeScore);
}

float FDREAM_CELL_StabilizeScalar(float2 uv, float centerValue, float centerDepth)
{
    float strength = saturate(FDREAM_CELL_CleanupStrength);
    float2 px = FDREAM_CELL_Pixel();
    float2 uvR = saturate(uv + float2(px.x, 0.0));
    float2 uvL = saturate(uv - float2(px.x, 0.0));
    float2 uvU = saturate(uv + float2(0.0, px.y));
    float2 uvD = saturate(uv - float2(0.0, px.y));
    float wR = exp(-abs(FDREAM_CELL_Depth(uvR) - centerDepth) * 48.0);
    float wL = exp(-abs(FDREAM_CELL_Depth(uvL) - centerDepth) * 48.0);
    float wU = exp(-abs(FDREAM_CELL_Depth(uvU) - centerDepth) * 48.0);
    float wD = exp(-abs(FDREAM_CELL_Depth(uvD) - centerDepth) * 48.0);
    float sum = centerValue + FDREAM_CELL_Edge(uvR) * wR + FDREAM_CELL_Edge(uvL) * wL + FDREAM_CELL_Edge(uvU) * wU + FDREAM_CELL_Edge(uvD) * wD;
    float weight = 1.0 + wR + wL + wU + wD;
    return lerp(centerValue, saturate(sum / max(FDREAM_CELL_EPS, weight)), strength);
}

float3 FDREAM_CELL_Cel(float3 sourceColor, float bandScale)
{
    float luma = FDREAM_CELL_Luma(sourceColor);
    float bandCount = max(2.0, float(FDREAM_CELL_CelBands) * bandScale);
    float bandedLuma = floor(luma * bandCount) / max(FDREAM_CELL_EPS, bandCount - 1.0);
    float contrastLuma = lerp(luma, saturate(bandedLuma), FDREAM_CELL_FineBandContrast);
    return saturate(sourceColor * (contrastLuma / max(FDREAM_CELL_EPS, luma)));
}

float2 FDREAM_CELL_FibonacciDirection(float fibIndex)
{
    const float goldenAngle = 2.39996323;
    float angle = fibIndex * goldenAngle;
    return float2(cos(angle), sin(angle));
}

float2 FDREAM_CELL_OrganicDirection(float2 lensOffset, float fibIndex, float2 uv, float tapNorm)
{
    float2 fibDir = FDREAM_CELL_FibonacciDirection(fibIndex);
    float2 lensDir = normalize(float2(0.23 - lensOffset.y, 0.17 + lensOffset.x + frac(fibIndex * 0.000618)));
    float2 baseDir = normalize(lerp(lensDir, fibDir, 0.45 + 0.24 * tapNorm));
    float phase = fibIndex * 0.013 + FDREAM_CELL_OrganicFlow * 0.18 + dot(uv * 72.0, float2(0.754, 0.569));
    float cs = cos(phase);
    float sn = sin(phase);
    return normalize(float2(baseDir.x * cs - baseDir.y * sn, baseDir.x * sn + baseDir.y * cs));
}

float3 FDREAM_CELL_LocalSupport(float2 uv, float radiusScale)
{
    float2 px = FDREAM_CELL_Pixel() * FDREAM_CELL_RadiusPixels * radiusScale;
    float3 center = FDREAM_CELL_Source(uv) * 2.0;
    float3 axis = FDREAM_CELL_Source(uv + float2(px.x, 0.0)) +
                  FDREAM_CELL_Source(uv - float2(px.x, 0.0)) +
                  FDREAM_CELL_Source(uv + float2(0.0, px.y)) +
                  FDREAM_CELL_Source(uv - float2(0.0, px.y));
    float3 diagonal = FDREAM_CELL_Source(uv + float2(px.x, px.y)) +
                      FDREAM_CELL_Source(uv - float2(px.x, px.y)) +
                      FDREAM_CELL_Source(uv + float2(px.x, -px.y)) +
                      FDREAM_CELL_Source(uv - float2(px.x, -px.y));
    return (center + axis + diagonal * 0.75) / 9.0;
}

float3 FDREAM_CELL_LocalDetail(float2 uv, float radiusScale)
{
    return FDREAM_CELL_Source(uv) - FDREAM_CELL_LocalSupport(uv, radiusScale);
}

float3 FDREAM_CELL_ChromaSafeDetail(float3 detailColor, float stableMask)
{
    float detailLuma = FDREAM_CELL_Luma(detailColor);
    float3 lumaOnly = detailLuma.xxx;
    float3 chroma = detailColor - lumaOnly;
    float chromaClamp = max(0.0, FDREAM_CELL_ChromaClamp);
    float3 clampedChroma = clamp(chroma, -chromaClamp, chromaClamp);
    float suppress = saturate(FDREAM_CELL_ChromaStability) * saturate(stableMask);
    return lumaOnly + lerp(chroma, clampedChroma, suppress);
}

void FDREAM_CELL_AccumulateOrganicTap(float2 uv, float centerDepth, float centerLuma, float2 offset, int index, int tapCount, inout float edgeSum, inout float edgeWeight, inout float3 supportSum, inout float supportWeight)
{
    if (index < tapCount)
    {
        float tapNorm = (float(index) + 0.5) / max(1.0, float(tapCount));
        float fibIndex = FDREAM_CELL_FibAnchor + float(index);
        float2 dir = FDREAM_CELL_OrganicDirection(offset, fibIndex, uv, tapNorm);
        float2 sampleUv = uv + dir * FDREAM_CELL_Pixel() * FDREAM_CELL_RadiusPixels * FDREAM_Lens55FibonacciGrowth(index, tapCount) * FDREAM_CELL_TierScale();
        float sampleDepth = FDREAM_CELL_Depth(sampleUv);
        float3 sampleColor = FDREAM_CELL_Source(sampleUv);
        float depthWeight = exp(-abs(sampleDepth - centerDepth) * 48.0);
        float lumaDelta = abs(FDREAM_CELL_Luma(sampleColor) - centerLuma);
        float tapEdge = saturate(max(lumaDelta * 4.0, abs(sampleDepth - centerDepth) * 96.0));
        edgeSum += tapEdge * depthWeight;
        edgeWeight += depthWeight;
        supportSum += sampleColor * depthWeight;
        supportWeight += depthWeight;
    }
}

void FDREAM_CELL_AccumulateRayStep(float2 uv, float centerDepth, float centerLuma, float2 rayStep, int stepIndex, int raySteps, float invRaySteps, inout float hitSum, inout float weightSum, inout float3 colorSum)
{
    if (stepIndex <= raySteps)
    {
        float t = float(stepIndex) * invRaySteps;
        float2 sampleUv = uv + rayStep * t;
        float3 sampleColor = FDREAM_CELL_Source(sampleUv);
        float sampleDepth = FDREAM_CELL_Depth(sampleUv);
        float depthDelta = max(0.0, abs(sampleDepth - centerDepth) - FDREAM_CELL_DepthBias);
        float depthHit = 1.0 - smoothstep(FDREAM_CELL_Thickness, FDREAM_CELL_Thickness * 2.0 + FDREAM_CELL_EPS, depthDelta);
        float lumaHit = saturate(abs(FDREAM_CELL_Luma(sampleColor) - centerLuma) * 2.4);
        float distanceWeight = exp(-t * FDREAM_CELL_DepthFalloff * 0.01);
        float stepHit = saturate(max(depthHit, lumaHit) * distanceWeight);
        hitSum += stepHit;
        weightSum += distanceWeight;
        colorSum += sampleColor * stepHit;
    }
}

void FDREAM_CELL_RayMarchDirection(float2 uv, float centerDepth, float centerLuma, float2 dir, int raySteps, out float hitSum, out float weightSum, out float3 colorSum)
{
    float2 rayStep = dir * FDREAM_CELL_Pixel() * FDREAM_CELL_RayLengthPixels * FDREAM_CELL_TierScale();
    float invRaySteps = rcp(max(1.0, float(raySteps)));
    hitSum = 0.0;
    weightSum = 0.0;
    colorSum = 0.0;

    #define FDREAM_CELL_RAY_STEP(STEP_INDEX) FDREAM_CELL_AccumulateRayStep(uv, centerDepth, centerLuma, rayStep, (STEP_INDEX), raySteps, invRaySteps, hitSum, weightSum, colorSum);
    FDREAM_CELL_RAY_STEP(1)
    FDREAM_CELL_RAY_STEP(2)
    FDREAM_CELL_RAY_STEP(3)
    FDREAM_CELL_RAY_STEP(4)
    FDREAM_CELL_RAY_STEP(5)
    FDREAM_CELL_RAY_STEP(6)
    FDREAM_CELL_RAY_STEP(7)
    FDREAM_CELL_RAY_STEP(8)
    #undef FDREAM_CELL_RAY_STEP
}

void FDREAM_CELL_AccumulateRayTap(float2 uv, float centerDepth, float centerLuma, float2 offset, int index, int tapCount, int raySteps, inout float hitSum, inout float weightSum, inout float3 colorSum)
{
    if (index < tapCount)
    {
        float tapNorm = (float(index) + 0.5) / max(1.0, float(tapCount));
        float fibIndex = FDREAM_CELL_FibAnchor + float(index);
        float2 dir = FDREAM_CELL_OrganicDirection(offset, fibIndex, uv, tapNorm);
        float tapHit = 0.0;
        float tapWeight = 0.0;
        float3 tapColor = 0.0;
        FDREAM_CELL_RayMarchDirection(uv, centerDepth, centerLuma, dir, raySteps, tapHit, tapWeight, tapColor);
        hitSum += tapHit;
        weightSum += tapWeight;
        colorSum += tapColor;
    }
}

float3 FDREAM_CELL_ApplyGuards(float2 uv, float3 sourceColor, float3 effectColor)
{
    float lightMask = FDREAM_CELL_LightMask(sourceColor);
    effectColor = FC_LIGHT_ProtectColor(effectColor, sourceColor, lightMask, FDREAM_CELL_LightProtectStrength);
    float fogBypass = FC_FOG_BypassMask(uv, sourceColor, FDREAM_CELL_RespectFog);
    fogBypass = min(fogBypass, saturate(FDREAM_CELL_FogBypassCap));
    return lerp(effectColor, sourceColor, fogBypass);
}

#endif



