// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: RC-1
// Capability: bio --Ray-M ambient occlusion using depth --Ray-M and bilateral cleanup.


// miXSR FC AO-only bio --Ray-M shader.
// Design intent: --Ray-M ambient occlusion using Lens55 directional taps.

#include "ReShade.fxh"
#include "miXSR_FC_FogGate.fxh"
#include "miXSR_FC_LightRespect.fxh"
#include "miXSR_FC_OrganicSampling_Lens55.fxh"

#pragma reshade skipoptimization

#define ORAO_COMPILE_TAP_CAP 24
#define ORAO_COMPILE_STEP_CAP 16

uniform int ORAO_DebugView <
    ui_type = "combo";
    ui_label = "Debug View";
    ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 00 Debug"; ui_category_closed = true;
    ui_items = "Final\0Raw AO\0Clean AO\0Hit Mask\0Depth Gate\0Derived Normal\0Linear Depth\0Raw Depth\0Raw Depth Inverted\0Depth Edges\0Ray Budget\0Depth Status\0Composite AO\0Fallback AO Raw\0";
    ui_tooltip = "Shows final output or diagnostic buffers.";
> = 0;

uniform float ORAO_DebugExposure <
    ui_type = "slider";
    ui_label = "Debug Exposure";
    ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 00 Debug"; ui_category_closed = true;
    ui_min = 1.0; ui_max = 32.0; ui_step = 0.1;
    ui_tooltip = "Boosts debug buffer visibility without changing final shading.";
> = 8.000000;

uniform float ORAO_DebugGamma <
    ui_type = "slider";
    ui_label = "Debug Gamma";
    ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 00 Debug"; ui_category_closed = true;
    ui_min = 0.25; ui_max = 2.0; ui_step = 0.01;
    ui_tooltip = "Tonemaps lifted debug buffers. Lower values lift dark details.";
> = 0.650000;

uniform float ORAO_DepthDebugScale <
    ui_type = "slider";
    ui_label = "Depth Debug Scale";
    ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 00 Debug"; ui_category_closed = true;
    ui_min = 1.0; ui_max = 4096.0; ui_step = 1.0;
    ui_tooltip = "Lifts very small depth-buffer values in depth debug views.";
> = 512.000000;

uniform float ORAO_NumericFloor < ui_type = "slider"; ui_label = "Numeric Floor"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.000001; ui_max = 0.001000; ui_step = 0.000001; ui_tooltip = "Small epsilon used to avoid divide-by-zero and unstable math."; > = 0.000010;
uniform float ORAO_LumaRed < ui_type = "slider"; ui_label = "Luma Red"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.0001; ui_tooltip = "Red channel weight used for luminance calculations."; > = 0.212600;
uniform float ORAO_LumaGreen < ui_type = "slider"; ui_label = "Luma Green"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.0001; ui_tooltip = "Green channel weight used for luminance calculations."; > = 0.715200;
uniform float ORAO_LumaBlue < ui_type = "slider"; ui_label = "Luma Blue"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.0001; ui_tooltip = "Blue channel weight used for luminance calculations."; > = 0.072200;

uniform float ORAO_MasterIntensity < ui_type = "slider"; ui_label = "Master Intensity"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Overall intensity multiplier for AO output."; > = 1.317000;
uniform float ORAO_AOStrength < ui_type = "slider"; ui_label = "AO Strength"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 02 Main Settings"; ui_min = 0.0; ui_max = 3.0; ui_step = 0.001; ui_tooltip = "Controls how strongly occlusion darkens nearby geometry."; > = 1.115000;
uniform float ORAO_AOPower < ui_type = "slider"; ui_label = "AO Power"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 02 Main Settings"; ui_min = 0.25; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Power shaping of AO response before final blend."; > = 1.540000;
uniform float ORAO_FinalVisibilityGain < ui_type = "slider"; ui_label = "Final Visibility Gain"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 02 Main Settings"; ui_min = 0.1; ui_max = 16.0; ui_step = 0.01; ui_tooltip = "Boosts low-amplitude AO into visible final shading without requiring excessive debug exposure."; > = 8.760000;
uniform float ORAO_MaxDarkening < ui_type = "slider"; ui_label = "Max Darkening"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 02 Main Settings"; ui_min = 0.0; ui_max = 1.17125; ui_step = 0.001; ui_tooltip = "Clamps the maximum darkening applied by AO."; > = 0.937000;

uniform int ORAO_DepthLinearizationMode < ui_type = "combo"; ui_label = "Depth Linearization Mode"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_items = "ReShade Linearized\0Raw Depth\0Raw Inverted\0"; ui_tooltip = "Selects how depth is interpreted before normalization."; > = 0;
uniform int ORAO_DepthPolarityMode < ui_type = "combo"; ui_label = "Depth Polarity"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_items = "Auto\0Front Occluders\0Back Creases\0"; ui_tooltip = "Selects which depth-direction occlusion is used. Auto picks the stronger of front/back responses per pixel."; > = 0;
uniform float ORAO_DepthValidityGate < ui_type = "slider"; ui_label = "Depth Validity Gate"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Strength of depth validity gating. Higher values suppress AO when depth is unstable or unavailable."; > = 0.650000;
uniform float ORAO_LinearDepthTraceScale < ui_type = "slider"; ui_label = "Linear Depth Trace Scale"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 1.0; ui_max = 4096.0; ui_step = 1.0; ui_tooltip = "Amplifies ReShade linearized-depth deltas for --Ray-M. Raw depth modes ignore this scale."; > = 512.000000;
uniform float ORAO_DepthFallbackStrength < ui_type = "slider"; ui_label = "Depth Fallback Strength"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Uses a conservative screen-luma fallback when no usable depth buffer is visible."; > = 0.250000;
uniform float ORAO_DepthAvailabilityThreshold < ui_type = "slider"; ui_label = "Depth Availability Threshold"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.00001; ui_max = 0.10000; ui_step = 0.00001; ui_tooltip = "How much local depth change is required before depth is considered usable."; > = 0.002500;
uniform float ORAO_NormalReconstructionStrength < ui_type = "slider"; ui_label = "Normal Reconstruction Strength"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.1; ui_max = 24.0; ui_step = 0.1; ui_tooltip = "Strength multiplier for derived normals reconstructed from depth."; > = 6.000000;
uniform float ORAO_NormalEdgeFade < ui_type = "slider"; ui_label = "Normal Edge Fade"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Fades normal influence at depth edges to reduce halo artifacts."; > = 0.550000;

uniform float ORAO_RayLengthPixels < ui_type = "slider"; ui_label = "Ray Length"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.5; ui_max = 64.0; ui_step = 0.01; ui_tooltip = "Maximum length of each AO ray in pixel units."; > = 9.500000;
uniform int ORAO_RaySteps < ui_type = "slider"; ui_label = "Ray Steps"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 2; ui_max = ORAO_COMPILE_STEP_CAP; ui_step = 1; ui_tooltip = "Number of march steps taken along each ray."; > = 16;
uniform int ORAO_TapCount < ui_type = "slider"; ui_label = "Tap Count"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 8; ui_max = ORAO_COMPILE_TAP_CAP; ui_step = 1; ui_tooltip = "Number of directional taps used to launch rays."; > = 24;
uniform float ORAO_RayBudgetScale < ui_type = "slider"; ui_label = "Ray Budget Scale"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.05; ui_max = 1.00; ui_step = 0.01; ui_tooltip = "Scales executed tap/step workload. Lower values reduce GPU cost."; > = 0.550000;
uniform int ORAO_RayEarlyOutEnable < ui_type = "combo"; ui_label = "Ray Early-Out"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Stops marching remaining steps when a ray already reached strong near-occlusion. Improves performance."; > = 1;
uniform float ORAO_RayEarlyOutOccThreshold < ui_type = "slider"; ui_label = "Early-Out Occlusion Threshold"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.500; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "Near-occlusion level that triggers per-ray early termination."; > = 0.880000;
uniform float ORAO_RayEarlyOutMinTravel < ui_type = "slider"; ui_label = "Early-Out Min Travel"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.000; ui_max = 1.000; ui_step = 0.001; ui_tooltip = "Normalized ray travel required before early-out can trigger."; > = 0.220000;
uniform float ORAO_Thickness < ui_type = "slider"; ui_label = "Depth Thickness"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0001; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Depth hit tolerance used when accepting ray samples."; > = 0.010000;
uniform float ORAO_DepthBias < ui_type = "slider"; ui_label = "Depth Bias"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0000; ui_max = 0.1000; ui_step = 0.0001; ui_tooltip = "Bias applied to reduce self-occlusion artifacts."; > = 0.001500;
uniform float ORAO_DepthResponse < ui_type = "slider"; ui_label = "Depth Response"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 1.0; ui_max = 64.0; ui_step = 0.01; ui_tooltip = "Occlusion sensitivity to depth separation along rays."; > = 36.000000;
uniform float ORAO_DepthCreaseResponse < ui_type = "slider"; ui_label = "Depth Crease Response"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Optional background-side depth crease shading.\nLeave at 0 for front-occluder ambient occlusion; raise only when intentionally restoring edge stylization."; > = 0.000000;
uniform float ORAO_DistanceFalloff < ui_type = "slider"; ui_label = "Distance Falloff"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 256.0; ui_step = 0.01; ui_tooltip = "Distance falloff shaping for ray contribution."; > = 56.000000;
uniform float ORAO_FibAnchor < ui_type = "slider"; ui_label = "Fibonacci Anchor"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 1597.0; ui_max = 4181.0; ui_step = 1.0; ui_tooltip = "Anchor index used by Fibonacci bio direction generation."; > = 2584.000000;
uniform float ORAO_Flow < ui_type = "slider"; ui_label = "bio Flow"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 4.6; ui_step = 0.001; ui_tooltip = "Controls phase drift for bio ray orientation."; > = 3.250000;
uniform float ORAO_Density < ui_type = "slider"; ui_label = "bio Density"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.1; ui_max = 3.5; ui_step = 0.001; ui_tooltip = "Density of bio phase modulation for tap directions."; > = 0.120000;
uniform float ORAO_NormalInfluence < ui_type = "slider"; ui_label = "Normal Influence"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "How strongly derived normals modulate directional AO response."; > = 0.500000;

uniform int ORAO_RespectFog < ui_type = "combo"; ui_label = "Respect Fog"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Bypasses AO in fog-dominant regions."; > = 1;
uniform float ORAO_FogEvidenceThreshold < ui_type = "slider"; ui_label = "Fog Evidence Threshold"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Minimum fog evidence required before Respect Fog can bypass AO."; > = 0.080000;
uniform float ORAO_FogEvidenceSoftness < ui_type = "slider"; ui_label = "Fog Evidence Softness"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.001; ui_max = 0.500; ui_step = 0.001; ui_tooltip = "Softness of fog-evidence transition for AO bypass."; > = 0.060000;
uniform int ORAO_RespectLight < ui_type = "combo"; ui_label = "Respect Light Emission"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Protects bright emissive pixels from being altered by this pass."; > = 1;
uniform float ORAO_LightProtectStrength < ui_type = "slider"; ui_label = "Light Protect Strength"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "How strongly emissive pixels are restored back to source color."; > = 0.900000;
uniform float ORAO_LightThreshold < ui_type = "slider"; ui_label = "Light Threshold"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Brightness level where the emission protection begins."; > = 0.680000;
uniform float ORAO_LightSoftness < ui_type = "slider"; ui_label = "Light Softness"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.001; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Soft transition width for the light protection gate."; > = 0.180000;
uniform float ORAO_LightPeakInfluence < ui_type = "slider"; ui_label = "Peak Influence"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "Raises protection when one channel is much hotter than the rest."; > = 0.700000;
uniform float ORAO_LightSaturationInfluence < ui_type = "slider"; ui_label = "Saturation Influence"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Adds extra protection for colored emissive lights and neon accents."; > = 0.350000;
uniform float ORAO_LightSaturationThreshold < ui_type = "slider"; ui_label = "Saturation Threshold"; ui_category = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Minimum saturation needed before colored emission gets extra protection."; > = 0.220000;

float2 ORAO_Pixel() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
float3 ORAO_Source(float2 uv) { return tex2D(ReShade::BackBuffer, saturate(uv)).rgb; }
float ORAO_RawDepth(float2 uv) { return tex2D(ReShade::DepthBuffer, saturate(uv)).r; }
float ORAO_Luma(float3 c) { return dot(c, normalize(float3(ORAO_LumaRed, ORAO_LumaGreen, ORAO_LumaBlue))); }

float ORAO_LinearDepth(float2 uv)
{
    float rawDepth = ORAO_RawDepth(uv);
    if (ORAO_DepthLinearizationMode == 1)
    {
        return saturate(rawDepth);
    }
    if (ORAO_DepthLinearizationMode == 2)
    {
        return saturate(1.0 - rawDepth);
    }
    return saturate(ReShade::GetLinearizedDepth(saturate(uv)));
}

float ORAO_DepthTraceScale()
{
    return (ORAO_DepthLinearizationMode == 0) ? max(1.0, ORAO_LinearDepthTraceScale) : 1.0;
}

float ORAO_DebugScalar(float value)
{
    float exposure = max(1.0, ORAO_DebugExposure);
    float gamma = max(0.25, ORAO_DebugGamma);
    return pow(saturate(value * exposure), gamma);
}

float ORAO_DebugDepthScalar(float value)
{
    float scale = max(1.0, ORAO_DepthDebugScale);
    float gamma = max(0.25, ORAO_DebugGamma);
    return pow(saturate(1.0 - exp(-saturate(value) * scale)), gamma);
}

float3 ORAO_DebugColor(float3 color)
{
    float exposure = max(1.0, ORAO_DebugExposure);
    float gamma = max(0.25, ORAO_DebugGamma);
    return pow(saturate(color * exposure), float3(gamma, gamma, gamma));
}

float ORAO_LightEmissionMask(float3 sourceColor)
{
    if (ORAO_RespectLight == 0)
    {
        return 0.0;
    }

    return FC_LIGHT_EmissionMask(
        sourceColor,
        ORAO_Luma(sourceColor),
        ORAO_LightThreshold,
        ORAO_LightSoftness,
        ORAO_LightPeakInfluence,
        ORAO_LightSaturationInfluence,
        ORAO_LightSaturationThreshold,
        ORAO_NumericFloor);
}

float ORAO_DepthGradient(float2 uv, float centerDepth)
{
    float2 px = ORAO_Pixel();
    float traceScale = ORAO_DepthTraceScale();
    float dR = ORAO_LinearDepth(uv + float2(px.x, 0.0));
    float dL = ORAO_LinearDepth(uv - float2(px.x, 0.0));
    float dU = ORAO_LinearDepth(uv + float2(0.0, px.y));
    float dD = ORAO_LinearDepth(uv - float2(0.0, px.y));

    float slope = (abs(dR - dL) + abs(dU - dD)) * traceScale;
    float centerFit = (abs(dR - centerDepth) + abs(dL - centerDepth) + abs(dU - centerDepth) + abs(dD - centerDepth)) * traceScale;
    return 0.5 * slope + 0.125 * centerFit;
}

float ORAO_RawDepthActivity(float2 uv)
{
    float2 px = ORAO_Pixel();
    float dR = ORAO_RawDepth(uv + float2(px.x, 0.0));
    float dL = ORAO_RawDepth(uv - float2(px.x, 0.0));
    float dU = ORAO_RawDepth(uv + float2(0.0, px.y));
    float dD = ORAO_RawDepth(uv - float2(0.0, px.y));
    return abs(dR - dL) + abs(dU - dD);
}

float ORAO_DepthAvailability(float2 uv, float centerDepth)
{
    float2 px = ORAO_Pixel();
    float traceScale = ORAO_DepthTraceScale();
    float rawDepth = ORAO_RawDepth(uv);
    float rawR = ORAO_RawDepth(uv + float2(px.x, 0.0));
    float rawL = ORAO_RawDepth(uv - float2(px.x, 0.0));
    float rawU = ORAO_RawDepth(uv + float2(0.0, px.y));
    float rawD = ORAO_RawDepth(uv - float2(0.0, px.y));
    float linR = ORAO_LinearDepth(uv + float2(px.x, 0.0));
    float linL = ORAO_LinearDepth(uv - float2(px.x, 0.0));
    float linU = ORAO_LinearDepth(uv + float2(0.0, px.y));
    float linD = ORAO_LinearDepth(uv - float2(0.0, px.y));

    float rawSpan = max(max(abs(rawDepth - rawR), abs(rawDepth - rawL)), max(abs(rawDepth - rawU), abs(rawDepth - rawD)));
    float linSpan = max(max(abs(centerDepth - linR), abs(centerDepth - linL)), max(abs(centerDepth - linU), abs(centerDepth - linD)));
    float scaledActivity = max(rawSpan, linSpan) * traceScale;
    float threshold = max(0.00001, ORAO_DepthAvailabilityThreshold);
    float availability = smoothstep(threshold, threshold * 4.0, scaledActivity);

    // Hard-reject known flat invalid sentinel values.
    float validRange = step(0.000001, rawDepth) * step(rawDepth, 0.999999);
    return saturate(availability * validRange);
}

float ORAO_DepthValidityMask(float2 uv, float centerDepth)
{
    float gradient = ORAO_DepthGradient(uv, centerDepth);
    float continuity = 1.0 - saturate(gradient * 32.0);
    float availability = ORAO_DepthAvailability(uv, centerDepth);
    float gate = saturate(ORAO_DepthValidityGate);
    return saturate(availability * lerp(1.0, continuity, gate));
}

float3 ORAO_DerivedNormal(float2 uv, out float edgeFactor)
{
    float2 px = ORAO_Pixel();

    float dC = ORAO_LinearDepth(uv);
    float dR = ORAO_LinearDepth(uv + float2(px.x, 0.0));
    float dL = ORAO_LinearDepth(uv - float2(px.x, 0.0));
    float dU = ORAO_LinearDepth(uv + float2(0.0, px.y));
    float dD = ORAO_LinearDepth(uv - float2(0.0, px.y));
    float traceScale = ORAO_DepthTraceScale();

    float gradX = ((abs(dR - dC) < abs(dC - dL)) ? (dR - dC) : (dC - dL)) * traceScale;
    float gradY = ((abs(dU - dC) < abs(dC - dD)) ? (dU - dC) : (dC - dD)) * traceScale;

    float edgeRaw = abs(gradX) + abs(gradY);
    edgeFactor = saturate(edgeRaw * 64.0);

    float edgeFade = saturate(ORAO_NormalEdgeFade);
    float strength = lerp(ORAO_NormalReconstructionStrength, ORAO_NormalReconstructionStrength * 0.20, edgeFactor * edgeFade);

    float3 n = normalize(float3(-gradX * strength, -gradY * strength, 1.0));
    n.z = abs(n.z);
    return normalize(n);
}

float ORAO_LumaFallbackAO(float2 uv)
{
    float2 px = ORAO_Pixel() * max(1.0, ORAO_RayLengthPixels * 0.35);
    float center = ORAO_Luma(ORAO_Source(uv));
    float sR = ORAO_Luma(ORAO_Source(uv + float2(px.x, 0.0)));
    float sL = ORAO_Luma(ORAO_Source(uv - float2(px.x, 0.0)));
    float sU = ORAO_Luma(ORAO_Source(uv + float2(0.0, px.y)));
    float sD = ORAO_Luma(ORAO_Source(uv - float2(0.0, px.y)));
    float neighborMean = (sR + sL + sU + sD) * 0.25;
    float localContrast = (abs(center - sR) + abs(center - sL) + abs(center - sU) + abs(center - sD)) * 0.25;
    return saturate(max(center - neighborMean, 0.0) * 1.50 + localContrast * 0.50);
}

float2 ORAO_FibonacciSpiralDirection(float fibIndex)
{
    const float goldenAngle = 2.39996323;
    float angle = fibIndex * goldenAngle;
    return float2(cos(angle), sin(angle));
}

float2 ORAO_OrganicDirection(float2 lensOffset, float fibIndex, float2 uv, float tapNorm)
{
    float flow = ORAO_Flow;
    float density = ORAO_Density;
    float2 fibDir = ORAO_FibonacciSpiralDirection(fibIndex);
    float2 lensDir = normalize(float2(0.23 - lensOffset.y, 0.17 + lensOffset.x + frac(fibIndex * 0.000618)));
    float2 baseDir = normalize(lerp(fibDir, lensDir, 0.35 + 0.30 * tapNorm));
    float phase = fibIndex * 0.013 + flow * 0.125 + dot(uv * (density * 64.0), float2(0.754, 0.569));
    float cs = cos(phase);
    float sn = sin(phase);
    return normalize(float2(baseDir.x * cs - baseDir.y * sn, baseDir.x * sn + baseDir.y * cs));
}

float2 ORAO_Lens55Offset(int tapIndex)
{
    int clampedIndex = clamp(tapIndex, 0, FCOH_LENS55_TAP_COUNT - 1);
    switch (clampedIndex)
    {
        #define ORAO_LENS55_CASE(OFFSET, INDEX) case INDEX: return OFFSET;
        FCOH_LENS55_TAPS(ORAO_LENS55_CASE)
        #undef ORAO_LENS55_CASE
        default: return float2(0.0, 0.0);
    }
}

void ORAO_RayMarchDirection(float2 uv, float centerDepth, float3 centerNormal, float2 dir, int raySteps, out float rayOcclusion, out float rayHit)
{
    float2 px = ORAO_Pixel();
    float2 rayStep = dir * px * ORAO_RayLengthPixels;
    int safeRaySteps = max(raySteps, 1);
    float invRaySteps = rcp(float(safeRaySteps));
    float thickness = max(0.0001, ORAO_Thickness);
    float depthBias = max(0.0, ORAO_DepthBias);
    float depthResponse = max(1.0, ORAO_DepthResponse);
    float distanceFalloffScale = max(0.0, ORAO_DistanceFalloff) * 0.01;
    float traceScale = ORAO_DepthTraceScale();
    float3 dir3 = normalize(float3(dir, 0.0));
    float normalFacing = 1.0 - abs(dot(centerNormal, dir3));
    float normalWeight = lerp(1.0, normalFacing, saturate(ORAO_NormalInfluence));
    float earlyOutEnable = (ORAO_RayEarlyOutEnable != 0) ? 1.0 : 0.0;
    float earlyOutThreshold = saturate(ORAO_RayEarlyOutOccThreshold);
    float earlyOutMinTravel = saturate(ORAO_RayEarlyOutMinTravel);

    float nearOcclusionSum = 0.0;
    float farOcclusionSum = 0.0;
    float nearHitSum = 0.0;
    float farHitSum = 0.0;
    float weightSum = 0.0;
    float activeRay = 1.0;

    #define ORAO_TRACE_STEP(STEP_INDEX) { \
        if (((STEP_INDEX) <= safeRaySteps) && (activeRay > 0.5)) { \
            float t = float(STEP_INDEX) * invRaySteps; \
            float2 sampleUv = uv + rayStep * t; \
            float sampleDepth = ORAO_LinearDepth(sampleUv); \
            float deltaNear = (centerDepth - sampleDepth) * traceScale; \
            float deltaFar = (sampleDepth - centerDepth) * traceScale; \
            float occNear = saturate((deltaNear - depthBias) * depthResponse); \
            float occFar = saturate((deltaFar - (depthBias + thickness * 0.25)) * (depthResponse * 0.35)); \
            float distanceWeight = exp(-t * distanceFalloffScale); \
            float sampleWeight = distanceWeight * normalWeight; \
            nearOcclusionSum += occNear * sampleWeight; \
            farOcclusionSum += occFar * sampleWeight; \
            nearHitSum += step(0.0001, occNear) * sampleWeight; \
            farHitSum += step(0.0001, occFar) * sampleWeight; \
            weightSum += sampleWeight; \
            if (earlyOutEnable > 0.5) { \
                float travelReady = step(earlyOutMinTravel, t); \
                float occlusionReady = step(earlyOutThreshold, occNear); \
                activeRay *= (1.0 - travelReady * occlusionReady); \
            } \
        } \
    }
    ORAO_TRACE_STEP(1)
    ORAO_TRACE_STEP(2)
    ORAO_TRACE_STEP(3)
    ORAO_TRACE_STEP(4)
    ORAO_TRACE_STEP(5)
    ORAO_TRACE_STEP(6)
    ORAO_TRACE_STEP(7)
    ORAO_TRACE_STEP(8)
    ORAO_TRACE_STEP(9)
    ORAO_TRACE_STEP(10)
    ORAO_TRACE_STEP(11)
    ORAO_TRACE_STEP(12)
    ORAO_TRACE_STEP(13)
    ORAO_TRACE_STEP(14)
    ORAO_TRACE_STEP(15)
    ORAO_TRACE_STEP(16)
    #undef ORAO_TRACE_STEP

    float nearAvg = nearOcclusionSum / max(ORAO_NumericFloor, weightSum);
    float farAvg = farOcclusionSum / max(ORAO_NumericFloor, weightSum);
    float nearHit = nearHitSum / max(ORAO_NumericFloor, weightSum);
    float farHit = farHitSum / max(ORAO_NumericFloor, weightSum);

    if (ORAO_DepthPolarityMode == 1)
    {
        rayOcclusion = max(nearAvg, farAvg * saturate(ORAO_DepthCreaseResponse));
        rayHit = max(nearHit, farHit * saturate(ORAO_DepthCreaseResponse));
    }
    else if (ORAO_DepthPolarityMode == 2)
    {
        rayOcclusion = farAvg;
        rayHit = farHit;
    }
    else
    {
        // Auto mode picks the stronger response to avoid black output when depth polarity differs per title.
        if (farAvg > nearAvg)
        {
            rayOcclusion = farAvg;
            rayHit = farHit;
        }
        else
        {
            rayOcclusion = nearAvg;
            rayHit = nearHit;
        }
    }
}

float4 ORAO_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float masterIntensity = ORAO_MasterIntensity;
    float aoStrength = ORAO_AOStrength;
    float aoPower = ORAO_AOPower;
    float maxDarkening = ORAO_MaxDarkening;
    int baseTapCount = clamp(ORAO_TapCount, 1, ORAO_COMPILE_TAP_CAP);
    int baseRaySteps = clamp(ORAO_RaySteps, 1, ORAO_COMPILE_STEP_CAP);
    float budgetScale = saturate(ORAO_RayBudgetScale);
    int tapCount = max(1, (int)floor(float(baseTapCount) * budgetScale + 0.5));
    int raySteps = max(1, (int)floor(float(baseRaySteps) * budgetScale + 0.5));

    float3 sourceColor = ORAO_Source(uv);
    if (ORAO_DebugView == 0 && (masterIntensity <= ORAO_NumericFloor || aoStrength <= ORAO_NumericFloor || budgetScale <= ORAO_NumericFloor))
    {
        return float4(saturate(sourceColor), 1.0);
    }

    float centerDepth = ORAO_LinearDepth(uv);
    float rawDepth = ORAO_RawDepth(uv);
    float depthAvailable = ORAO_DepthAvailability(uv, centerDepth);
    float gateMask = ORAO_DepthValidityMask(uv, centerDepth);
    float fallbackAoRaw = ORAO_LumaFallbackAO(uv) * ORAO_DepthFallbackStrength;
    float fallbackAo = fallbackAoRaw * (1.0 - depthAvailable);
    if (ORAO_DebugView == 0 && gateMask <= ORAO_NumericFloor && fallbackAo <= ORAO_NumericFloor)
    {
        return float4(saturate(sourceColor), 1.0);
    }

    float edgeFactor = 0.0;
    float3 centerNormal = ORAO_DerivedNormal(uv, edgeFactor);

    float occlusionSum = 0.0;
    float hitSum = 0.0;

    #define ORAO_APPLY_TAP(INDEX) { \
        if ((INDEX) < tapCount) { \
            float fibIndex = ORAO_FibAnchor + float(INDEX); \
            float tapNorm = (float(INDEX) + 0.5) / float(ORAO_COMPILE_TAP_CAP); \
            float2 lensOffset = ORAO_Lens55Offset(INDEX); \
            float2 dir = ORAO_OrganicDirection(lensOffset, fibIndex, uv, tapNorm); \
            float rayOcclusion = 0.0; \
            float rayHit = 0.0; \
            ORAO_RayMarchDirection(uv, centerDepth, centerNormal, dir, raySteps, rayOcclusion, rayHit); \
            occlusionSum += rayOcclusion; \
            hitSum += rayHit; \
        } \
    }
    ORAO_APPLY_TAP(0)
    ORAO_APPLY_TAP(1)
    ORAO_APPLY_TAP(2)
    ORAO_APPLY_TAP(3)
    ORAO_APPLY_TAP(4)
    ORAO_APPLY_TAP(5)
    ORAO_APPLY_TAP(6)
    ORAO_APPLY_TAP(7)
    ORAO_APPLY_TAP(8)
    ORAO_APPLY_TAP(9)
    ORAO_APPLY_TAP(10)
    ORAO_APPLY_TAP(11)
    ORAO_APPLY_TAP(12)
    ORAO_APPLY_TAP(13)
    ORAO_APPLY_TAP(14)
    ORAO_APPLY_TAP(15)
    ORAO_APPLY_TAP(16)
    ORAO_APPLY_TAP(17)
    ORAO_APPLY_TAP(18)
    ORAO_APPLY_TAP(19)
    ORAO_APPLY_TAP(20)
    ORAO_APPLY_TAP(21)
    ORAO_APPLY_TAP(22)
    ORAO_APPLY_TAP(23)
    #undef ORAO_APPLY_TAP

    float rawAoRay = occlusionSum / max(ORAO_NumericFloor, float(tapCount));
    float rawAo = rawAoRay * gateMask;
    rawAo = max(rawAo, fallbackAo);
    rawAo = saturate(rawAo);
    float hitMask = max(hitSum / max(ORAO_NumericFloor, float(tapCount)), fallbackAo);

    float cleanAo = pow(rawAo, max(0.25, aoPower));
    float visibilityGain = max(0.1, ORAO_FinalVisibilityGain);
    float compositeDriver = cleanAo * aoStrength * masterIntensity * visibilityGain;
    float compositeAo = saturate(1.0 - exp(-compositeDriver));
    compositeAo = min(compositeAo, maxDarkening);

    float3 aoColor = sourceColor * (1.0 - compositeAo);
    float lightProtectMask = ORAO_LightEmissionMask(sourceColor);
    aoColor = FC_LIGHT_ProtectColor(aoColor, sourceColor, lightProtectMask, ORAO_LightProtectStrength);

    float fogBypass = FC_FOG_BypassMask(uv, sourceColor, ORAO_RespectFog);
    float fogEvidence = smoothstep(
        ORAO_FogEvidenceThreshold,
        ORAO_FogEvidenceThreshold + max(ORAO_NumericFloor, ORAO_FogEvidenceSoftness),
        FC_FOG_Core(uv, sourceColor));
    fogBypass *= fogEvidence;
    float3 fogRespectedColor = lerp(aoColor, sourceColor, fogBypass);

    if (ORAO_DebugView == 1) return float4(ORAO_DebugScalar(max(rawAoRay, fallbackAo)).xxx, 1.0);
    if (ORAO_DebugView == 2) return float4(ORAO_DebugScalar(cleanAo).xxx, 1.0);
    if (ORAO_DebugView == 3) return float4(ORAO_DebugScalar(hitMask).xxx, 1.0);
    if (ORAO_DebugView == 4) return float4(ORAO_DebugScalar(gateMask).xxx, 1.0);
    if (ORAO_DebugView == 5) return float4(centerNormal * 0.5 + 0.5, 1.0);
    if (ORAO_DebugView == 6) return (depthAvailable > 0.001) ? float4(ORAO_DebugDepthScalar(centerDepth).xxx, 1.0) : float4(0.35, 0.0, 0.0, 1.0);
    if (ORAO_DebugView == 7) return (depthAvailable > 0.001) ? float4(ORAO_DebugScalar(rawDepth).xxx, 1.0) : float4(0.35, 0.0, 0.0, 1.0);
    if (ORAO_DebugView == 8) return (depthAvailable > 0.001) ? float4(ORAO_DebugScalar(1.0 - rawDepth).xxx, 1.0) : float4(0.35, 0.0, 0.0, 1.0);
    if (ORAO_DebugView == 9) return float4(ORAO_DebugScalar(ORAO_DepthGradient(uv, centerDepth)).xxx, 1.0);
    if (ORAO_DebugView == 10) return float4(saturate(float(tapCount * raySteps) / float(ORAO_COMPILE_TAP_CAP * ORAO_COMPILE_STEP_CAP)).xxx, 1.0);
    if (ORAO_DebugView == 11) return float4(lerp(float3(0.45, 0.0, 0.0), float3(0.0, 0.65, 0.15), depthAvailable), 1.0);
    if (ORAO_DebugView == 12) return float4(ORAO_DebugScalar(compositeAo).xxx, 1.0);
    if (ORAO_DebugView == 13) return float4(ORAO_DebugScalar(fallbackAoRaw).xxx, 1.0);
    return float4(saturate(fogRespectedColor), 1.0);
}
technique miXSR_FC_Bio_RayM_AO < ui_label = "Fine Cell - Ambient Occlusion - Bio Ray-M Trace";  ui_tooltip = "bio --Ray-M ambient occlusion using depth --Ray-M and bilateral cleanup."; >
{
    pass { VertexShader = PostProcessVS; PixelShader = ORAO_MainPS; }
}





