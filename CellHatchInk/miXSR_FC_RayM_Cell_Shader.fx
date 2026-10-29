// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: RC-1
// Capability: --Ray-M-guided cel shading with edge inking and hit-mask amplification.


// --Ray-M Cell-shader: cel + edge stylization with pseudo-ray-traced hit guidance.

#include "ReShade.fxh"
#include "miXSR_FC_ShaderSharedMaskControls.fxh"

uniform int PRTCEL_DebugView <
    ui_type = "combo";
    ui_label = "Debug View";
    ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 00 Debug"; ui_category_closed = true;
    ui_items = "Final\0Cel\0Edge\0--Ray-M Hit Mask\0";
    ui_tooltip = "Shows final output or diagnostic buffers.";
> = 0;

uniform float PRTCEL_NumericFloor < ui_type = "slider"; ui_label = "Numeric Floor"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.000001; ui_max = 0.001000; ui_step = 0.000001; ui_tooltip = "Small epsilon used to avoid divide-by-zero and unstable math."; > = 0.000010;
uniform float PRTCEL_LumaRed < ui_type = "slider"; ui_label = "Luma Red"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.0001; ui_tooltip = "Red channel weight used for luminance calculations."; > = 0.212600;
uniform float PRTCEL_LumaGreen < ui_type = "slider"; ui_label = "Luma Green"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.0001; ui_tooltip = "Green channel weight used for luminance calculations."; > = 0.715200;
uniform float PRTCEL_LumaBlue < ui_type = "slider"; ui_label = "Luma Blue"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.0001; ui_tooltip = "Blue channel weight used for luminance calculations."; > = 0.072200;

uniform float PRTCEL_MasterIntensity < ui_type = "slider"; ui_label = "Master Intensity"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Overall intensity multiplier for cell-shader stylization."; > = 0.594000;
uniform float PRTCEL_CelStrength < ui_type = "slider"; ui_label = "Cel Strength"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Blend amount of cel banding into source color."; > = 0.857000;
uniform int PRTCEL_CelBands < ui_type = "slider"; ui_label = "Cel Bands"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 02 Main Settings"; ui_min = 2; ui_max = 24; ui_step = 1; ui_tooltip = "Number of luminance bands used for cel quantization."; > = 16;
uniform float PRTCEL_FineBandContrast < ui_type = "slider"; ui_label = "Fine Band Contrast"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.005; ui_tooltip = "Contrast shaping for banded luminance."; > = 0.975000;
uniform float PRTCEL_EdgeStrength < ui_type = "slider"; ui_label = "Edge Strength"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 02 Main Settings"; ui_min = 0.0; ui_max = 3.0; ui_step = 0.001; ui_tooltip = "Darkening amount for edge inking."; > = 0.509000;
uniform int PRTCEL_RespectFog < ui_type = "combo"; ui_label = "Respect Fog"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Reduces stylization where fog gate marks the scene as fog-dominant."; > = 1;
uniform int PRTCEL_RespectLight < ui_type = "combo"; ui_label = "Respect Light Emission"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Protects bright emissive pixels from being altered by this pass."; > = 1;
uniform float PRTCEL_LightProtectStrength < ui_type = "slider"; ui_label = "Light Protect Strength"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "How strongly emissive pixels are restored back to source color."; > = 0.900000;
uniform float PRTCEL_LightThreshold < ui_type = "slider"; ui_label = "Light Threshold"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Brightness level where the emission protection begins."; > = 0.680000;
uniform float PRTCEL_LightSoftness < ui_type = "slider"; ui_label = "Light Softness"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.001; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Soft transition width for the light protection gate."; > = 0.180000;
uniform float PRTCEL_LightPeakInfluence < ui_type = "slider"; ui_label = "Peak Influence"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "Raises protection when one channel is much hotter than the rest."; > = 0.700000;
uniform float PRTCEL_LightSaturationInfluence < ui_type = "slider"; ui_label = "Saturation Influence"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Adds extra protection for colored emissive lights and neon accents."; > = 0.350000;
uniform float PRTCEL_LightSaturationThreshold < ui_type = "slider"; ui_label = "Saturation Threshold"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Minimum saturation needed before colored emission gets extra protection."; > = 0.220000;

uniform float PRTCEL_EdgeRadiusPixels < ui_type = "slider"; ui_label = "Edge Radius Pixels"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.25; ui_max = 8.0; ui_step = 0.01; ui_tooltip = "Sampling radius for edge detection."; > = 0.760000;
uniform float PRTCEL_EdgeLumaGain < ui_type = "slider"; ui_label = "Luma Edge Gain"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 32.0; ui_step = 0.01; ui_tooltip = "Gain applied to luminance edge signal."; > = 6.000000;
uniform float PRTCEL_EdgeDepthGain < ui_type = "slider"; ui_label = "Depth Edge Gain"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 300.0; ui_step = 0.1; ui_tooltip = "Gain applied to depth edge signal."; > = 110.000000;
uniform float PRTCEL_EdgeThreshold < ui_type = "slider"; ui_label = "Edge Threshold"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.005; ui_tooltip = "Threshold where edge response starts."; > = 0.160000;
uniform float PRTCEL_EdgeSoftness < ui_type = "slider"; ui_label = "Edge Softness"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.01; ui_max = 1.0; ui_step = 0.005; ui_tooltip = "Soft transition width around the edge threshold."; > = 0.260000;

uniform float PRTCEL_RayLengthPixels < ui_type = "slider"; ui_label = "Ray Length"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.5; ui_max = 64.0; ui_step = 0.01; ui_tooltip = "Maximum length of each --Ray-M ray in pixel units."; > = 12.000000;
uniform int PRTCEL_RaySteps < ui_type = "slider"; ui_label = "Ray Steps"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 2; ui_max = 24; ui_step = 1; ui_tooltip = "Number of march steps taken along each ray."; > = 16;
uniform int PRTCEL_TapCount < ui_type = "slider"; ui_label = "Tap Count"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 4; ui_max = 64; ui_step = 1; ui_tooltip = "Number of radial ray directions used for --Ray-M tracing."; > = 21;
uniform float PRTCEL_RayBudgetScale < ui_type = "slider"; ui_label = "Ray Budget Scale"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.05; ui_max = 1.00; ui_step = 0.01; ui_tooltip = "Scales executed tap/step workload. Lower values reduce GPU cost."; > = 0.220000;
uniform float PRTCEL_Thickness < ui_type = "slider"; ui_label = "Depth Hit Thickness"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0001; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Depth tolerance for hit acceptance during --Ray-M tracing."; > = 0.010000;
uniform float PRTCEL_DepthBias < ui_type = "slider"; ui_label = "Depth Bias"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0000; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Bias applied to reduce self-hits near the source pixel."; > = 0.001000;
uniform float PRTCEL_DepthFalloff < ui_type = "slider"; ui_label = "Depth Falloff"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 256.0; ui_step = 0.01; ui_tooltip = "Distance falloff shaping for --Ray-M hit contribution."; > = 48.000000;
uniform float PRTCEL_LumaHitGain < ui_type = "slider"; ui_label = "Luma Hit Gain"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 8.0; ui_step = 0.01; ui_tooltip = "Gain applied to luminance-based hit signal along rays."; > = 2.200000;
uniform float PRTCEL_xRTInfluence < ui_type = "slider"; ui_label = "--Ray-M Influence"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 02 Main Settings"; ui_min = 0.0; ui_max = 1.25; ui_step = 0.001; ui_tooltip = "How strongly --Ray-M hit mask amplifies edge inking."; > = 1.000000;
uniform float PRTCEL_DepthValidityGate < ui_type = "slider"; ui_label = "Depth Validity Gate"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Gates stylization in unstable depth regions."; > = 0.650000;
uniform float PRTCEL_BilateralCleanupStrength < ui_type = "slider"; ui_label = "Bilateral Cleanup Strength"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Stabilizes edge and hit masks using depth-aware neighbor cleanup."; > = 0.550000;
uniform float PRTCEL_ConservativeComposite < ui_type = "slider"; ui_label = "Conservative Composite"; ui_category = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "Limits final stylization intensity for flicker-safe output."; > = 0.850000;

float2 PRTCEL_Pixel() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
float3 PRTCEL_Source(float2 uv) { return tex2D(ReShade::BackBuffer, saturate(uv)).rgb; }
float PRTCEL_Depth(float2 uv) { return ReShade::GetLinearizedDepth(saturate(uv)); }
float PRTCEL_Luma(float3 c) { return dot(c, normalize(float3(PRTCEL_LumaRed, PRTCEL_LumaGreen, PRTCEL_LumaBlue))); }


float PRTCEL_LightEmissionMask(float3 sourceColor)
{
    if (PRTCEL_RespectLight == 0)
    {
        return 0.0;
    }

    return FC_LIGHT_EmissionMask(
        sourceColor,
        PRTCEL_Luma(sourceColor),
        PRTCEL_LightThreshold,
        PRTCEL_LightSoftness,
        PRTCEL_LightPeakInfluence,
        PRTCEL_LightSaturationInfluence,
        PRTCEL_LightSaturationThreshold,
        PRTCEL_NumericFloor);
}

float PRTCEL_GetRayBudgetScale()
{
    return saturate(PRTCEL_RayBudgetScale);
}

float2 PRTCEL_TraditionalDirection(int tapIndex, int tapCount)
{
    const float twoPi = 6.28318530718;
    float angle = (float(tapIndex) + 0.5) * (twoPi / max(1.0, float(tapCount)));
    return float2(cos(angle), sin(angle));
}

float PRTCEL_Edge(float2 uv)
{
    float2 px = PRTCEL_Pixel() * PRTCEL_EdgeRadiusPixels;
    float centerDepth = PRTCEL_Depth(uv);
    float centerLuma = PRTCEL_Luma(PRTCEL_Source(uv));

    float lumaEdge = abs(centerLuma - PRTCEL_Luma(PRTCEL_Source(uv + float2(px.x, 0.0)))) +
                     abs(centerLuma - PRTCEL_Luma(PRTCEL_Source(uv + float2(-px.x, 0.0)))) +
                     abs(centerLuma - PRTCEL_Luma(PRTCEL_Source(uv + float2(0.0, px.y)))) +
                     abs(centerLuma - PRTCEL_Luma(PRTCEL_Source(uv + float2(0.0, -px.y))));

    float depthEdge = abs(centerDepth - PRTCEL_Depth(uv + float2(px.x, 0.0))) +
                      abs(centerDepth - PRTCEL_Depth(uv + float2(-px.x, 0.0))) +
                      abs(centerDepth - PRTCEL_Depth(uv + float2(0.0, px.y))) +
                      abs(centerDepth - PRTCEL_Depth(uv + float2(0.0, -px.y)));

    float edgeScore = lumaEdge * PRTCEL_EdgeLumaGain + depthEdge * PRTCEL_EdgeDepthGain;
    return smoothstep(PRTCEL_EdgeThreshold, PRTCEL_EdgeThreshold + max(PRTCEL_NumericFloor, PRTCEL_EdgeSoftness), edgeScore);
}



float PRTCEL_Hash12(float2 p)
{
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

float PRTCEL_DepthValidityMask(float2 uv, float centerDepth)
{
    float2 px = PRTCEL_Pixel();
    float dR = PRTCEL_Depth(uv + float2(px.x, 0.0));
    float dL = PRTCEL_Depth(uv - float2(px.x, 0.0));
    float dU = PRTCEL_Depth(uv + float2(0.0, px.y));
    float dD = PRTCEL_Depth(uv - float2(0.0, px.y));

    float slope = abs(dR - dL) + abs(dU - dD);
    float continuity = 1.0 - saturate(slope * 32.0);
    float presence = saturate((abs(dR - centerDepth) + abs(dL - centerDepth) + abs(dU - centerDepth) + abs(dD - centerDepth)) * 64.0);
    float strictMask = continuity * max(0.10, presence);
    return saturate(lerp(1.0, strictMask, saturate(PRTCEL_DepthValidityGate)));
}

float PRTCEL_StabilizeScalar(float2 uv, float centerValue, float centerDepth)
{
    float strength = saturate(PRTCEL_BilateralCleanupStrength);
    if (strength <= 0.0001)
    {
        return centerValue;
    }

    float2 px = PRTCEL_Pixel();
    float weightedSum = centerValue;
    float weightSum = 1.0;

    float2 uvR = saturate(uv + float2(px.x, 0.0));
    float2 uvL = saturate(uv - float2(px.x, 0.0));
    float2 uvU = saturate(uv + float2(0.0, px.y));
    float2 uvD = saturate(uv - float2(0.0, px.y));

    float dR = PRTCEL_Depth(uvR);
    float dL = PRTCEL_Depth(uvL);
    float dU = PRTCEL_Depth(uvU);
    float dD = PRTCEL_Depth(uvD);

    float wR = exp(-abs(dR - centerDepth) * 48.0);
    float wL = exp(-abs(dL - centerDepth) * 48.0);
    float wU = exp(-abs(dU - centerDepth) * 48.0);
    float wD = exp(-abs(dD - centerDepth) * 48.0);

    float sR = centerValue;
    float sL = centerValue;
    float sU = centerValue;
    float sD = centerValue;

    sR = PRTCEL_Edge(uvR);
    sL = PRTCEL_Edge(uvL);
    sU = PRTCEL_Edge(uvU);
    sD = PRTCEL_Edge(uvD);

    weightedSum += sR * wR;
    weightedSum += sL * wL;
    weightedSum += sU * wU;
    weightedSum += sD * wD;
    weightSum += wR + wL + wU + wD;

    float filtered = saturate(weightedSum / max(PRTCEL_NumericFloor, weightSum));
    return lerp(centerValue, filtered, strength);
}


void PRTCEL_RayMarchDirection(float2 uv, float centerDepth, float centerLuma, float2 dir, int raySteps, out float hitSum, out float weightSum)
{
    float2 px = PRTCEL_Pixel();
    float2 rayStep = dir * px * PRTCEL_RayLengthPixels;
    float invRaySteps = rcp(float(raySteps));
    float depthFalloffScale = PRTCEL_DepthFalloff * 0.01;
    hitSum = 0.0;
    weightSum = 0.0;

    [loop]
    for (int stepIndex = 1; stepIndex <= 24; ++stepIndex)
    {
        if (stepIndex > raySteps)
            break;

        float t = float(stepIndex) * invRaySteps;
        float2 sampleUv = uv + rayStep * t;
        float sampleDepth = PRTCEL_Depth(sampleUv);
        float sampleLuma = PRTCEL_Luma(PRTCEL_Source(sampleUv));

        float depthDelta = abs(sampleDepth - centerDepth);
        float lumaDelta = abs(sampleLuma - centerLuma);
        float depthHit = smoothstep(PRTCEL_Thickness, PRTCEL_Thickness * 2.0 + PRTCEL_NumericFloor, depthDelta + PRTCEL_DepthBias);
        float lumaHit = saturate(lumaDelta * PRTCEL_LumaHitGain);
        float distanceWeight = exp(-t * depthFalloffScale);
        float stepHit = saturate(max(depthHit, lumaHit) * distanceWeight);

        hitSum += stepHit;
        weightSum += distanceWeight;
    }
}

float3 PRTCEL_Cel(float3 sourceColor)
{
    float luma = PRTCEL_Luma(sourceColor);
    float bandCount = max(2.0, float(PRTCEL_CelBands));
    float bandedLuma = floor(luma * bandCount) / max(PRTCEL_NumericFloor, bandCount - 1.0);
    float contrastLuma = lerp(luma, saturate(bandedLuma), PRTCEL_FineBandContrast);
    float scale = contrastLuma / max(PRTCEL_NumericFloor, luma);
    return saturate(sourceColor * scale);
}

float4 PRTCEL_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    int baseTapCount = clamp(PRTCEL_TapCount, 1, 64);
    int baseRaySteps = clamp(PRTCEL_RaySteps, 1, 24);
    float budgetScale = PRTCEL_GetRayBudgetScale();
    int tapCount = max(1, (int)floor(float(baseTapCount) * budgetScale + 0.5));
    int raySteps = max(1, (int)floor(float(baseRaySteps) * budgetScale + 0.5));

    float3 sourceColor = PRTCEL_Source(uv);
    float centerDepth = PRTCEL_Depth(uv);
    float centerLuma = PRTCEL_Luma(sourceColor);
    float cleanupStrength = saturate(PRTCEL_BilateralCleanupStrength);
    float ditherScale = 1.0 / 255.0;

    float hitSum = 0.0;
    float weightSum = 0.0;

    [loop]
    for (int tapIndex = 0; tapIndex < 64; ++tapIndex)
    {
        if (tapIndex >= tapCount)
            break;

        float2 dir = PRTCEL_TraditionalDirection(tapIndex, tapCount);
        float tapHit = 0.0;
        float tapWeight = 0.0;
        PRTCEL_RayMarchDirection(uv, centerDepth, centerLuma, dir, raySteps, tapHit, tapWeight);
        hitSum += tapHit;
        weightSum += tapWeight;
    }

    float hitRaw = saturate(hitSum / max(PRTCEL_NumericFloor, weightSum));
    float hitSmooth = 1.0 - exp(-hitRaw * 3.500000);
    float hitDither = PRTCEL_Hash12(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
    float hitMask = saturate(hitSmooth + (hitDither - 0.5) * ditherScale);
    float depthGate = PRTCEL_DepthValidityMask(uv, centerDepth);
    float edge = PRTCEL_Edge(uv);
    float stableEdge = PRTCEL_StabilizeScalar(uv, edge, centerDepth);
    float stableHit = lerp(hitMask, saturate(0.5 * (hitMask + stableEdge)), cleanupStrength);
    edge = stableEdge * depthGate;
    hitMask = stableHit * depthGate;
    float3 celColor = PRTCEL_Cel(sourceColor);

    float edgeAmplifier = lerp(1.0, 1.0 + hitMask, saturate(PRTCEL_xRTInfluence));
    float3 shadedColor = lerp(sourceColor, celColor, saturate(PRTCEL_CelStrength * PRTCEL_MasterIntensity));
    float conservative = saturate(PRTCEL_ConservativeComposite);
    shadedColor = lerp(shadedColor, float3(0.0, 0.0, 0.0), saturate(edge * edgeAmplifier * PRTCEL_EdgeStrength * PRTCEL_MasterIntensity * conservative));

    float lightProtectMask = PRTCEL_LightEmissionMask(sourceColor);
    shadedColor = MIXSR_SHARED_ProtectColor(uv, shadedColor, sourceColor, lightProtectMask, PRTCEL_LightProtectStrength);
    // Use direct fog gate to avoid stale shared-cache ghosting in fog-heavy regions.
    float fogBypass = FC_FOG_BypassMask(uv, sourceColor, PRTCEL_RespectFog);
    float3 finalColor = lerp(shadedColor, sourceColor, fogBypass);

    if (PRTCEL_DebugView == 1) return float4(celColor, 1.0);
    if (PRTCEL_DebugView == 2) return float4(edge.xxx, 1.0);
    if (PRTCEL_DebugView == 3) return float4(hitMask.xxx, 1.0);
    return float4(saturate(finalColor), 1.0);
}
technique miXSR_FC_RayM_Cell_Shader < ui_label = "Fine Cell - Cell Shading - Ray-M Guided Cel and Ink";  ui_tooltip = "--Ray-M-guided cel shading with edge inking and hit-mask amplification."; >
{
    pass { VertexShader = PostProcessVS; PixelShader = PRTCEL_MainPS; }
}







