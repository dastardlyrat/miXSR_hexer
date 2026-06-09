// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: dream-richness-1
// Capability: bio Fibonacci deep-tone shaping with guarded color expansion and stability controls.


// Function: compares source luminance against compact bio local tone support,
// shapes midtone contrast with shadow/highlight restraint, then reapplies the
// shaped luminance while preserving source chroma.

#include "ReShade.fxh"
#include "miXSR_FC_ShaderSharedMaskControls.fxh"
#include "miXSR_FC_Lens55Bounded.fxh"

#define FDRICH_EPS 0.000010

uniform int FDRICH_PresetTier < ui_type = "combo"; ui_label = "Preset Tier"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 02 Main Settings"; ui_items = "Basic Conservative\0Liberal Coverage\0Aggressive Aggregate\0High Fidelity\0Ultra Fidelity\0"; ui_tooltip = "High Fidelity is the base standard; Ultra uses all bounded Lens55 taps without expanding the tap body."; > = 2;
uniform int FDRICH_DebugView < ui_type = "combo"; ui_label = "Debug View"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 00 Debug"; ui_category_closed = true; ui_items = "Final\0Shaped Tone\0Organic Support\0Tone Mask\0Depth Gate\0Saturation\0Computed Mask\0"; ui_tooltip = "Shows final output or diagnostic buffers."; > = 0;
uniform float FDRICH_MasterIntensity < ui_type = "slider"; ui_label = "Master Intensity"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 02 Main Settings"; ui_min = 0.0; ui_max = 3.0; ui_step = 0.001; ui_tooltip = "Overall multiplier for tonal richness."; > = 1.000000;
uniform float FDRICH_RichnessStrength < ui_type = "slider"; ui_label = "Richness Strength"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 02 Main Settings"; ui_min = -1.0; ui_max = 3.0; ui_step = 0.001; ui_tooltip = "Strength of local tone shaping."; > = 0.650000;
uniform float FDRICH_ColorfulnessStrength < ui_type = "slider"; ui_label = "Colorfulness Strength"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 02 Main Settings"; ui_min = -1.0; ui_max = 3.0; ui_step = 0.001; ui_tooltip = "Optional chroma expansion after tonal shaping."; > = 0.280000;
uniform float FDRICH_TonePivot < ui_type = "slider"; ui_label = "Tone Pivot"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Luminance pivot where richness shaping is strongest."; > = 0.369000;
uniform float FDRICH_ToneWidth < ui_type = "slider"; ui_label = "Tone Width"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.01; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Width of the tonal region emphasized around the pivot."; > = 0.314000;
uniform float FDRICH_LocalContrast < ui_type = "slider"; ui_label = "Local Contrast"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Weight of immediate local tone contrast."; > = 2.631000;
uniform float FDRICH_ShadowLift < ui_type = "slider"; ui_label = "Shadow Lift"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Reduces deep shadow crushing."; > = 0.348000;
uniform float FDRICH_HighlightCompression < ui_type = "slider"; ui_label = "Highlight Compression"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Reduces highlight over-expansion."; > = 0.660000;
uniform float FDRICH_RadiusPixels < ui_type = "slider"; ui_label = "bio Radius"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.25; ui_max = 32.0; ui_step = 0.01; ui_tooltip = "Screen-space radius for bio tone support."; > = 2.400000;
uniform int FDRICH_TapCount < ui_type = "slider"; ui_label = "Tap Budget"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 03 Sub Settings"; ui_category_closed = true; ui_min = 4; ui_max = FDREAM_LENS55_TAP_COUNT; ui_step = 1; ui_tooltip = "Bounded Lens55 tap budget. High and Ultra fidelity increase tap coverage without expanding the tap body."; > = 12;
uniform float FDRICH_FibAnchor < ui_type = "slider"; ui_label = "Fibonacci Anchor"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 03 Sub Settings"; ui_category_closed = true; ui_min = 987.0; ui_max = 4181.0; ui_step = 1.0; ui_tooltip = "Anchor index for bio Fibonacci direction generation."; > = 2584.000000;
uniform float FDRICH_OrganicFlow < ui_type = "slider"; ui_label = "bio Flow"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Phase drift for bio tone support."; > = 1.250000;
uniform float FDRICH_DepthGate < ui_type = "slider"; ui_label = "Depth Gate"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Suppresses shaping when depth is unstable."; > = 0.650000;
uniform int FDRICH_RespectFog < ui_type = "combo"; ui_label = "Respect Fog"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Bypasses deep-tone shaping in fog-dominant regions."; > = 1;
uniform int FDRICH_RespectLight < ui_type = "combo"; ui_label = "Respect Light"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Protects emissive pixels from deep-tone shaping."; > = 1;
uniform float FDRICH_LightProtectStrength < ui_type = "slider"; ui_label = "Light Protect Strength"; ui_category = "Fine Cell - Deep Tone - Bio Fibonacci Shaping / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "How strongly protected lights return to source color."; > = 0.900000;

float2 FDRICH_Pixel() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
float3 FDRICH_Source(float2 uv) { return tex2D(ReShade::BackBuffer, saturate(uv)).rgb; }
float FDRICH_Depth(float2 uv) { return saturate(ReShade::GetLinearizedDepth(saturate(uv))); }
float FDRICH_Luma(float3 color) { return dot(color, float3(0.2126, 0.7152, 0.0722)); }
float FDRICH_Saturation(float3 color) { float peak = max(color.r, max(color.g, color.b)); float trough = min(color.r, min(color.g, color.b)); return saturate((peak - trough) / max(FDRICH_EPS, peak)); }

int FDRICH_TierTapCap() { return FDREAM_Lens55TierTapCap(FDRICH_PresetTier); }
float FDRICH_TierScale() { return FDREAM_Lens55TierScale(FDRICH_PresetTier); }

float FDRICH_LightMask(float2 uv, float3 sourceColor)
{
    if (FDRICH_RespectLight == 0) return 0.0;
    return MIXSR_SHARED_SharedLightMask(uv, sourceColor, FDRICH_Luma(sourceColor), 0.680000, 0.180000, 0.700000, 0.350000, 0.220000, FDRICH_EPS);
}

float FDRICH_DepthGateMask(float2 uv, float centerDepth)
{
    float2 px = FDRICH_Pixel();
    float dR = FDRICH_Depth(uv + float2(px.x, 0.0));
    float dL = FDRICH_Depth(uv - float2(px.x, 0.0));
    float dU = FDRICH_Depth(uv + float2(0.0, px.y));
    float dD = FDRICH_Depth(uv - float2(0.0, px.y));
    float slope = abs(dR - dL) + abs(dU - dD);
    float fit = abs(dR - centerDepth) + abs(dL - centerDepth) + abs(dU - centerDepth) + abs(dD - centerDepth);
    float continuity = 1.0 - saturate((slope + fit * 0.25) * 32.0);
    float tierBias = (FDRICH_PresetTier == 0) ? 0.10 : ((FDRICH_PresetTier == 1) ? 0.0 : -0.08);
    return saturate(lerp(1.0, continuity, saturate(FDRICH_DepthGate + tierBias)));
}

float2 FDRICH_FibonacciDirection(float fibIndex)
{
    const float goldenAngle = 2.39996323;
    float angle = fibIndex * goldenAngle;
    return float2(cos(angle), sin(angle));
}

float2 FDRICH_OrganicDirection(float2 lensOffset, float fibIndex, float2 uv, float tapNorm)
{
    float2 fibDir = FDRICH_FibonacciDirection(fibIndex);
    float2 lensDir = normalize(float2(0.23 - lensOffset.y, 0.17 + lensOffset.x + frac(fibIndex * 0.000618)));
    float2 baseDir = normalize(lerp(lensDir, fibDir, 0.45 + 0.24 * tapNorm));
    float phase = fibIndex * 0.013 + FDRICH_OrganicFlow * 0.18 + dot(uv * 72.0, float2(0.754, 0.569));
    float cs = cos(phase);
    float sn = sin(phase);
    return normalize(float2(baseDir.x * cs - baseDir.y * sn, baseDir.x * sn + baseDir.y * cs));
}

void FDRICH_AccumulateTap(float2 uv, float centerDepth, float2 offset, int index, int tapCount, inout float lumaSum, inout float weightSum, inout float chromaSum)
{
    if (index < tapCount)
    {
        float tapNorm = (float(index) + 0.5) / max(1.0, float(tapCount));
        float fibIndex = FDRICH_FibAnchor + float(index);
        float2 dir = FDRICH_OrganicDirection(offset, fibIndex, uv, tapNorm);
        float2 sampleUv = uv + dir * FDRICH_Pixel() * FDRICH_RadiusPixels * FDREAM_Lens55FibonacciGrowth(index, tapCount) * FDRICH_TierScale();
        float3 sampleColor = FDRICH_Source(sampleUv);
        float sampleDepth = FDRICH_Depth(sampleUv);
        float depthWeight = exp(-abs(sampleDepth - centerDepth) * 48.0);
        lumaSum += FDRICH_Luma(sampleColor) * depthWeight;
        chromaSum += FDRICH_Saturation(sampleColor) * depthWeight;
        weightSum += depthWeight;
    }
}

float3 FDRICH_ApplyShapedLuma(float3 sourceColor, float sourceLuma, float shadedLuma)
{
    float3 chromaPreserved = saturate(sourceColor * (shadedLuma / max(FDRICH_EPS, sourceLuma)));
    float3 lumaOnly = shadedLuma.xxx;
    return lerp(lumaOnly, chromaPreserved, 0.92);
}

float4 FDRICH_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    int tapCount = min(clamp(FDRICH_TapCount, 1, FDREAM_LENS55_TAP_COUNT), FDRICH_TierTapCap());
    float3 sourceColor = FDRICH_Source(uv);
    float sourceLuma = FDRICH_Luma(sourceColor);
    float centerDepth = FDRICH_Depth(uv);
    float depthGate = FDRICH_DepthGateMask(uv, centerDepth);
    float lumaSum = sourceLuma;
    float chromaSum = FDRICH_Saturation(sourceColor);
    float weightSum = 1.0;

    [loop]
    for (int tapIndex = 0; tapIndex < FDREAM_LENS55_TAP_COUNT; ++tapIndex)
    {
        if (tapIndex < tapCount)
        {
            float2 offset = FDREAM_Lens55Offset(tapIndex);
            FDRICH_AccumulateTap(uv, centerDepth, offset, tapIndex, tapCount, lumaSum, weightSum, chromaSum);
        }
    }

    float supportLuma = lumaSum / max(FDRICH_EPS, weightSum);
    float supportSaturation = chromaSum / max(FDRICH_EPS, weightSum);
    float localShade = sourceLuma - supportLuma;
    float toneMask = 1.0 - saturate(abs(sourceLuma - FDRICH_TonePivot) / max(FDRICH_EPS, FDRICH_ToneWidth));
    float shadowTerm = min(localShade, 0.0) * (1.0 - FDRICH_ShadowLift);
    // Deep-tone intent: compress highlights and deepen mids/shadows instead of lifting bright regions.
    float highlightTerm = -max(localShade, 0.0) * FDRICH_HighlightCompression;
    float shapedShade = (shadowTerm + highlightTerm) * toneMask * FDRICH_LocalContrast;
    float computedMask = saturate(abs(shapedShade) * FDRICH_RichnessStrength * FDRICH_MasterIntensity * depthGate * FDRICH_TierScale());
    float shadedLuma = saturate(sourceLuma + shapedShade * FDRICH_RichnessStrength * FDRICH_MasterIntensity * depthGate * FDRICH_TierScale());
    float3 effectColor = FDRICH_ApplyShapedLuma(sourceColor, sourceLuma, shadedLuma);

    float saturation = FDRICH_Saturation(sourceColor);
    float vibranceGate = 1.0 - saturate(saturation / 1.75);
    float colorfulness = FDRICH_ColorfulnessStrength * FDRICH_MasterIntensity * depthGate * toneMask * lerp(1.0, vibranceGate, 0.65);
    float3 centered = effectColor - FDRICH_Luma(effectColor).xxx;
    effectColor = saturate(FDRICH_Luma(effectColor).xxx + centered * (1.0 + colorfulness * max(0.25, supportSaturation + 0.25)));

    float lightMask = FDRICH_LightMask(uv, sourceColor);
    effectColor = MIXSR_SHARED_ProtectColor(uv, effectColor, sourceColor, lightMask, FDRICH_LightProtectStrength);
    float fogBypass = MIXSR_SHARED_SharedFogBypass(uv, sourceColor, FDRICH_RespectFog);
    effectColor = lerp(effectColor, sourceColor, fogBypass);

    if (FDRICH_DebugView == 1) return float4(saturate(shapedShade * 4.0 + 0.5).xxx, 1.0);
    if (FDRICH_DebugView == 2) return float4(supportLuma.xxx, 1.0);
    if (FDRICH_DebugView == 3) return float4(toneMask.xxx, 1.0);
    if (FDRICH_DebugView == 4) return float4(depthGate.xxx, 1.0);
    if (FDRICH_DebugView == 5) return float4(saturation.xxx, 1.0);
    if (FDRICH_DebugView == 6) return float4(computedMask.xxx, 1.0);
    return float4(saturate(effectColor), 1.0);
}

technique miXSR_FC_bio_deep_tone < ui_label = "Fine Cell - Deep Tone - Bio Fibonacci Shaping"; ui_tooltip = "bio local deep-tone support with chroma-preserving remap and guarded color expansion."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FDRICH_MainPS;
    }
}






