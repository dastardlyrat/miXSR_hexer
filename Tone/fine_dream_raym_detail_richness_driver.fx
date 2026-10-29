// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: dream-wake-no-longer-dreaming-fourth-gate-1
// Capability: --Ray-M detail richness driver with stability gating, guarded compositing, and diagnostic tuning views.


// fine_dream gate shader\n// Wake No Longer Dreaming: --Ray-M-guided tonal enrichment for The Fourth Gate.

#include "ReShade.fxh"
#include "FineCell_FogGate.fxh"
#include "FineCell_LightRespect.fxh"

uniform int PRTRI_DebugView <
    ui_type = "combo";
    ui_label = "Debug View";
    ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 00 Debug"; ui_category_closed = true;
    ui_items = "Final\0Rich Shading\0--Ray-M Hit Mask\0Tone Mask\0";
    ui_tooltip = "Shows final output or diagnostic buffers.";
> = 0;

uniform float PRTRI_NumericFloor < ui_type = "slider"; ui_label = "Numeric Floor"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.000001; ui_max = 0.001000; ui_step = 0.000001; ui_tooltip = "Small epsilon used to avoid divide-by-zero and unstable math."; > = 0.000010;
uniform float PRTRI_LumaRed < ui_type = "slider"; ui_label = "Luma Red"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.0001; ui_tooltip = "Red channel weight used for luminance calculations."; > = 0.212600;
uniform float PRTRI_LumaGreen < ui_type = "slider"; ui_label = "Luma Green"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 1.15; ui_step = 0.0001; ui_tooltip = "Green channel weight used for luminance calculations."; > = 0.715200;
uniform float PRTRI_LumaBlue < ui_type = "slider"; ui_label = "Luma Blue"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.0001; ui_tooltip = "Blue channel weight used for luminance calculations."; > = 0.072200;

uniform float PRTRI_MasterIntensity < ui_type = "slider"; ui_label = "Master Intensity"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Overall intensity multiplier for richness shading."; > = 0.460000;
uniform float PRTRI_RichnessStrength < ui_type = "slider"; ui_label = "Richness Strength"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 3.45; ui_step = 0.001; ui_tooltip = "Strength of the final tonal shading enrichment."; > = 2.460000;
uniform float PRTRI_LocalContrast < ui_type = "slider"; ui_label = "Local Contrast"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Weight of immediate local tone contrast."; > = 1.027000;
uniform float PRTRI_xRTShadeGain < ui_type = "slider"; ui_label = "--Ray-M Shade Gain"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 4.6; ui_step = 0.001; ui_tooltip = "Weight of --Ray-M-derived directional shading support."; > = 3.674000;
uniform float PRTRI_TonePivot < ui_type = "slider"; ui_label = "Tone Pivot"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Luminance pivot around which richness shaping is emphasized."; > = 0.500000;
uniform float PRTRI_ToneWidth < ui_type = "slider"; ui_label = "Tone Width"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.01; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Width of the tonal region emphasized around the tone pivot."; > = 0.420000;
uniform float PRTRI_ShadowLift < ui_type = "slider"; ui_label = "Shadow Lift"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Reduces deep shadow crushing in the richness pass."; > = 0.250000;
uniform float PRTRI_HighlightCompression < ui_type = "slider"; ui_label = "Highlight Compression"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Reduces highlight over-expansion in the richness pass."; > = 0.350000;
uniform float PRTRI_PreserveColor < ui_type = "slider"; ui_label = "Preserve Color"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 1.25; ui_step = 0.001; ui_tooltip = "Preserves source chroma while applying tonal shading."; > = 1.000000;
uniform int PRTRI_RespectFog < ui_type = "combo"; ui_label = "Respect Fog"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Reduces richness shading where fog gate marks the scene as fog-dominant."; > = 1;
uniform int PRTRI_RespectLight < ui_type = "combo"; ui_label = "Respect Light Emission"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Protects bright emissive pixels from being altered by this pass."; > = 1;
uniform float PRTRI_LightProtectStrength < ui_type = "slider"; ui_label = "Light Protect Strength"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "How strongly emissive pixels are restored back to source color."; > = 0.900000;
uniform float PRTRI_LightThreshold < ui_type = "slider"; ui_label = "Light Threshold"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Brightness level where the emission protection begins."; > = 0.680000;
uniform float PRTRI_LightSoftness < ui_type = "slider"; ui_label = "Light Softness"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.001; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Soft transition width for the light protection gate."; > = 0.180000;
uniform float PRTRI_LightPeakInfluence < ui_type = "slider"; ui_label = "Peak Influence"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "Raises protection when one channel is much hotter than the rest."; > = 0.700000;
uniform float PRTRI_LightSaturationInfluence < ui_type = "slider"; ui_label = "Saturation Influence"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Adds extra protection for colored emissive lights and neon accents."; > = 0.350000;
uniform float PRTRI_LightSaturationThreshold < ui_type = "slider"; ui_label = "Saturation Threshold"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Minimum saturation needed before colored emission gets extra protection."; > = 0.220000;

uniform float PRTRI_LocalRadiusPixels < ui_type = "slider"; ui_label = "Local Radius Pixels"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.25; ui_max = 4.0; ui_step = 0.01; ui_tooltip = "Radius used for local tonal support sampling."; > = 0.700000;
uniform float PRTRI_CenterWeight < ui_type = "slider"; ui_label = "Center Weight"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Center sample weight used by the local tonal support filter."; > = 1.000000;
uniform float PRTRI_AxisWeight < ui_type = "slider"; ui_label = "Axis Weight"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Axis neighbor weight used by the local tonal support filter."; > = 1.000000;
uniform float PRTRI_DiagonalWeight < ui_type = "slider"; ui_label = "Diagonal Weight"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Diagonal neighbor weight used by the local tonal support filter."; > = 0.750000;

uniform float PRTRI_RayLengthPixels < ui_type = "slider"; ui_label = "Ray Length"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.5; ui_max = 64.0; ui_step = 0.01; ui_tooltip = "Maximum length of each --Ray-M ray in pixel units."; > = 12.000000;
uniform int PRTRI_RaySteps < ui_type = "slider"; ui_label = "Ray Steps"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 2; ui_max = 24; ui_step = 1; ui_tooltip = "Number of march steps taken along each ray."; > = 16;
uniform int PRTRI_TapCount < ui_type = "slider"; ui_label = "Tap Count"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 4; ui_max = 64; ui_step = 1; ui_tooltip = "Number of radial ray directions used for --Ray-M tracing."; > = 21;
uniform float PRTRI_RayBudgetScale < ui_type = "slider"; ui_label = "Ray Budget Scale"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.05; ui_max = 1.00; ui_step = 0.01; ui_tooltip = "Scales executed tap/step workload. Lower values reduce GPU cost."; > = 0.220000;
uniform float PRTRI_HitThickness < ui_type = "slider"; ui_label = "Depth Hit Thickness"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0001; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Depth tolerance for hit acceptance during --Ray-M tracing."; > = 0.008000;
uniform float PRTRI_DepthBias < ui_type = "slider"; ui_label = "Depth Bias"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0000; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Bias applied to reduce self-hits near the source pixel."; > = 0.001000;
uniform float PRTRI_DepthFalloff < ui_type = "slider"; ui_label = "Depth Falloff"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 256.0; ui_step = 0.01; ui_tooltip = "Distance falloff shaping for --Ray-M hit contribution."; > = 42.000000;
uniform float PRTRI_LumaHitGain < ui_type = "slider"; ui_label = "Luma Hit Gain"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 8.0; ui_step = 0.01; ui_tooltip = "Gain applied to luminance difference when evaluating directional shading support."; > = 2.000000;

uniform float PRTRI_DepthValidityGate < ui_type = "slider"; ui_label = "Depth Validity Gate"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Gates richness shading in unstable depth regions."; > = 0.650000;
uniform float PRTRI_BilateralCleanupStrength < ui_type = "slider"; ui_label = "Bilateral Cleanup Strength"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Stabilizes tone and hit masks using depth-aware neighbor cleanup."; > = 0.550000;
uniform float PRTRI_ConservativeComposite < ui_type = "slider"; ui_label = "Conservative Composite"; ui_category = "Fine Cell - Detail Richness - Ray-M Driver / 02 Main Settings"; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "Limits final richness intensity for flicker-safe output."; > = 0.850000;

float2 PRTRI_Pixel() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
float3 PRTRI_Source(float2 uv) { return tex2D(ReShade::BackBuffer, saturate(uv)).rgb; }
float PRTRI_Depth(float2 uv) { return ReShade::GetLinearizedDepth(saturate(uv)); }
float PRTRI_Luma(float3 c) { return dot(c, normalize(float3(PRTRI_LumaRed, PRTRI_LumaGreen, PRTRI_LumaBlue))); }


float PRTRI_LightEmissionMask(float3 sourceColor)
{
    if (PRTRI_RespectLight == 0)
    {
        return 0.0;
    }

    return FC_LIGHT_EmissionMask(
        sourceColor,
        PRTRI_Luma(sourceColor),
        PRTRI_LightThreshold,
        PRTRI_LightSoftness,
        PRTRI_LightPeakInfluence,
        PRTRI_LightSaturationInfluence,
        PRTRI_LightSaturationThreshold,
        PRTRI_NumericFloor);
}

float PRTRI_GetRayBudgetScale()
{
    return saturate(PRTRI_RayBudgetScale);
}

float2 PRTRI_TraditionalDirection(int tapIndex, int tapCount)
{
    const float twoPi = 6.28318530718;
    float angle = (float(tapIndex) + 0.5) * (twoPi / max(1.0, float(tapCount)));
    return float2(cos(angle), sin(angle));
}

float PRTRI_Hash12(float2 p)
{
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

float PRTRI_DepthValidityMask(float2 uv, float centerDepth)
{
    float2 px = PRTRI_Pixel();
    float dR = PRTRI_Depth(uv + float2(px.x, 0.0));
    float dL = PRTRI_Depth(uv - float2(px.x, 0.0));
    float dU = PRTRI_Depth(uv + float2(0.0, px.y));
    float dD = PRTRI_Depth(uv - float2(0.0, px.y));

    float slope = abs(dR - dL) + abs(dU - dD);
    float continuity = 1.0 - saturate(slope * 32.0);
    float presence = saturate((abs(dR - centerDepth) + abs(dL - centerDepth) + abs(dU - centerDepth) + abs(dD - centerDepth)) * 64.0);
    float strictMask = continuity * max(0.10, presence);
    return saturate(lerp(1.0, strictMask, saturate(PRTRI_DepthValidityGate)));
}

float PRTRI_LocalSupportLuma(float2 uv)
{
    float2 px = PRTRI_Pixel() * PRTRI_LocalRadiusPixels;
    float centerWeight = PRTRI_CenterWeight;
    float axisWeight = PRTRI_AxisWeight;
    float diagonalWeight = PRTRI_DiagonalWeight;

    float center = PRTRI_Luma(PRTRI_Source(uv)) * centerWeight;
    float axis = (PRTRI_Luma(PRTRI_Source(uv + float2(px.x, 0.0))) +
                  PRTRI_Luma(PRTRI_Source(uv + float2(-px.x, 0.0))) +
                  PRTRI_Luma(PRTRI_Source(uv + float2(0.0, px.y))) +
                  PRTRI_Luma(PRTRI_Source(uv + float2(0.0, -px.y)))) * axisWeight;
    float diagonal = (PRTRI_Luma(PRTRI_Source(uv + float2(px.x, px.y))) +
                      PRTRI_Luma(PRTRI_Source(uv + float2(-px.x, px.y))) +
                      PRTRI_Luma(PRTRI_Source(uv + float2(px.x, -px.y))) +
                      PRTRI_Luma(PRTRI_Source(uv + float2(-px.x, -px.y)))) * diagonalWeight;

    float normalizer = max(PRTRI_NumericFloor, centerWeight + axisWeight * 4.0 + diagonalWeight * 4.0);
    return (center + axis + diagonal) / normalizer;
}

float PRTRI_StabilizeScalar(float2 uv, float centerValue, float centerDepth)
{
    float strength = saturate(PRTRI_BilateralCleanupStrength);
    if (strength <= 0.0001)
    {
        return centerValue;
    }

    float2 px = PRTRI_Pixel();
    float2 uvR = saturate(uv + float2(px.x, 0.0));
    float2 uvL = saturate(uv - float2(px.x, 0.0));
    float2 uvU = saturate(uv + float2(0.0, px.y));
    float2 uvD = saturate(uv - float2(0.0, px.y));

    float dR = PRTRI_Depth(uvR);
    float dL = PRTRI_Depth(uvL);
    float dU = PRTRI_Depth(uvU);
    float dD = PRTRI_Depth(uvD);

    float wR = exp(-abs(dR - centerDepth) * 48.0);
    float wL = exp(-abs(dL - centerDepth) * 48.0);
    float wU = exp(-abs(dU - centerDepth) * 48.0);
    float wD = exp(-abs(dD - centerDepth) * 48.0);

    float weightedSum = centerValue;
    float weightSum = 1.0;
    weightedSum += PRTRI_LocalSupportLuma(uvR) * wR;
    weightedSum += PRTRI_LocalSupportLuma(uvL) * wL;
    weightedSum += PRTRI_LocalSupportLuma(uvU) * wU;
    weightedSum += PRTRI_LocalSupportLuma(uvD) * wD;
    weightSum += wR + wL + wU + wD;

    float filtered = weightedSum / max(PRTRI_NumericFloor, weightSum);
    return lerp(centerValue, filtered, strength);
}

void PRTRI_RayMarchDirection(float2 uv, float centerDepth, float centerLuma, float2 dir, int raySteps, out float tracedLumaSum, out float tracedWeightSum, out float distanceWeightSum)
{
    float2 px = PRTRI_Pixel();
    float2 rayStep = dir * px * PRTRI_RayLengthPixels;
    float invRaySteps = rcp(float(raySteps));
    float depthFalloffScale = PRTRI_DepthFalloff * 0.01;
    tracedLumaSum = 0.0;
    tracedWeightSum = 0.0;
    distanceWeightSum = 0.0;

    [loop]
    for (int stepIndex = 1; stepIndex <= 24; ++stepIndex)
    {
        [branch]
        if (stepIndex <= raySteps)
        {
            float t = float(stepIndex) * invRaySteps;
            float2 sampleUv = uv + rayStep * t;
            float sampleDepth = PRTRI_Depth(sampleUv);
            float sampleLuma = PRTRI_Luma(PRTRI_Source(sampleUv));

            float depthDelta = max(0.0, abs(sampleDepth - centerDepth) - PRTRI_DepthBias);
            float depthMatch = 1.0 - smoothstep(PRTRI_HitThickness, PRTRI_HitThickness * 2.0 + PRTRI_NumericFloor, depthDelta);
            float lumaHit = saturate(abs(sampleLuma - centerLuma) * PRTRI_LumaHitGain);
            float distanceWeight = exp(-t * depthFalloffScale);
            float stepWeight = saturate(max(depthMatch, lumaHit) * distanceWeight);

            tracedLumaSum += sampleLuma * stepWeight;
            tracedWeightSum += stepWeight;
            distanceWeightSum += distanceWeight;
        }
    }
}

float3 PRTRI_ApplyShadedLuma(float3 sourceColor, float sourceLuma, float shadedLuma)
{
    float scale = shadedLuma / max(PRTRI_NumericFloor, sourceLuma);
    float3 shadedColor = saturate(sourceColor * scale);
    return lerp(shadedLuma.xxx, shadedColor, PRTRI_PreserveColor);
}

float4 PRTRI_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    int baseTapCount = clamp(PRTRI_TapCount, 1, 64);
    int baseRaySteps = clamp(PRTRI_RaySteps, 1, 24);
    float budgetScale = PRTRI_GetRayBudgetScale();
    int tapCount = max(1, (int)floor(float(baseTapCount) * budgetScale + 0.5));
    int raySteps = max(1, (int)floor(float(baseRaySteps) * budgetScale + 0.5));

    float3 sourceColor = PRTRI_Source(uv);
    float centerDepth = PRTRI_Depth(uv);
    float sourceLuma = PRTRI_Luma(sourceColor);
    float depthGate = PRTRI_DepthValidityMask(uv, centerDepth);

    float localSupportLuma = PRTRI_LocalSupportLuma(uv);
    float stableSupportLuma = PRTRI_StabilizeScalar(uv, localSupportLuma, centerDepth);
    float cleanupStrength = saturate(PRTRI_BilateralCleanupStrength);
    float ditherScale = 1.0 / 255.0;

    float tracedLumaSum = 0.0;
    float tracedWeightSum = 0.0;
    float distanceWeightSum = 0.0;

    [loop]
    for (int tapIndex = 0; tapIndex < 64; ++tapIndex)
    {
        [branch]
        if (tapIndex < tapCount)
        {
            float2 dir = PRTRI_TraditionalDirection(tapIndex, tapCount);
            float tapLumaSum = 0.0;
            float tapWeightSum = 0.0;
            float tapDistanceWeightSum = 0.0;
            PRTRI_RayMarchDirection(uv, centerDepth, sourceLuma, dir, raySteps, tapLumaSum, tapWeightSum, tapDistanceWeightSum);
            tracedLumaSum += tapLumaSum;
            tracedWeightSum += tapWeightSum;
            distanceWeightSum += tapDistanceWeightSum;
        }
    }

    float tracedSupportLuma = (tracedWeightSum > PRTRI_NumericFloor) ? (tracedLumaSum / tracedWeightSum) : sourceLuma;
    float hitRaw = tracedWeightSum / max(PRTRI_NumericFloor, distanceWeightSum);
    float hitSmooth = 1.0 - exp(-hitRaw * 3.500000);
    float hitDither = PRTRI_Hash12(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
    float hitMask = saturate(hitSmooth + (hitDither - 0.5) * ditherScale);
    float stableHit = lerp(hitMask, saturate(0.5 * (hitMask + abs(sourceLuma - stableSupportLuma) * 6.0)), cleanupStrength);
    stableHit *= depthGate;

    float localShade = sourceLuma - stableSupportLuma;
    float tracedShade = sourceLuma - tracedSupportLuma;
    float toneMask = 1.0 - saturate(abs(sourceLuma - PRTRI_TonePivot) / max(PRTRI_NumericFloor, PRTRI_ToneWidth));
    float rawShade = localShade * PRTRI_LocalContrast + tracedShade * (PRTRI_xRTShadeGain * (0.35 + 0.65 * stableHit));

    float shadowTerm = min(rawShade, 0.0) * (1.0 - PRTRI_ShadowLift);
    float highlightTerm = max(rawShade, 0.0) * (1.0 - PRTRI_HighlightCompression);
    float shapedShade = (shadowTerm + highlightTerm) * toneMask;
    float shadeAmount = shapedShade * PRTRI_RichnessStrength * PRTRI_MasterIntensity * depthGate * saturate(PRTRI_ConservativeComposite);
    float shadedLuma = saturate(sourceLuma + shadeAmount);
    float3 effectColor = PRTRI_ApplyShadedLuma(sourceColor, sourceLuma, shadedLuma);

    float lightProtectMask = PRTRI_LightEmissionMask(sourceColor);
    effectColor = FC_LIGHT_ProtectColor(effectColor, sourceColor, lightProtectMask, PRTRI_LightProtectStrength);
    float fogBypass = FC_FOG_BypassMask(uv, sourceColor, PRTRI_RespectFog);
    float3 finalColor = lerp(effectColor, sourceColor, fogBypass);

    if (PRTRI_DebugView == 1) return float4(saturate((shapedShade * 4.0) + 0.5).xxx, 1.0);
    if (PRTRI_DebugView == 2) return float4(stableHit.xxx, 1.0);
    if (PRTRI_DebugView == 3) return float4(toneMask.xxx, 1.0);
    return float4(finalColor, 1.0);
}

technique fine_dream_raym_detail_richness_driver < ui_label = "Fine Cell - Detail Richness - Ray-M Driver";  ui_tooltip = "Driver for --Ray-M detail richness with stability and guarded compositing."; >
{
    pass { VertexShader = PostProcessVS; PixelShader = PRTRI_MainPS; }
}








