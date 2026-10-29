// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: dream-ink-stylized-1
// Capability: bio Fibonacci ink-edge stylization with cel-band tone remap and light/fog guards.


// Function: extracts luma/depth ink edges, blends them with Fibonacci bio
// support, then applies guarded cel-style tone bands and stable ink darkening.

#include "ReShade.fxh"
#include "FineCell_FogGate.fxh"
#include "FineCell_LightRespect.fxh"
#include "FineDream_Lens55Bounded.fxh"

#define FDINK_EPS 0.000010

uniform int FDINK_PresetTier < ui_type = "combo"; ui_label = "Preset Tier"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 02 Main Settings"; ui_items = "Basic Conservative\0Liberal Coverage\0Aggressive Aggregate\0High Fidelity\0Ultra Fidelity\0"; ui_tooltip = "High Fidelity is the base standard; Ultra uses all bounded Lens55 taps without expanding the tap body."; > = 1;
uniform int FDINK_DebugView < ui_type = "combo"; ui_label = "Debug View"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 00 Debug"; ui_category_closed = true; ui_items = "Final\0Ink Mask\0Cel Tone\0Organic Support\0Depth Gate\0Light Zone\0"; ui_tooltip = "Shows final output or diagnostic buffers."; > = 0;
uniform float FDINK_MasterIntensity < ui_type = "slider"; ui_label = "Master Intensity"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Overall multiplier for ink stylization."; > = 0.402000;
uniform float FDINK_InkStrength < ui_type = "slider"; ui_label = "Ink Strength"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "How strongly detected ink lines darken the image."; > = 0.614000;
uniform float FDINK_StylizeStrength < ui_type = "slider"; ui_label = "Stylize Strength"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 02 Main Settings"; ui_min = 0.0; ui_max = 1.25; ui_step = 0.001; ui_tooltip = "How strongly cel bands reshape source luminance."; > = 1.000000;
uniform int FDINK_CelBands < ui_type = "slider"; ui_label = "Cel Bands"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 2; ui_max = 12; ui_step = 1; ui_tooltip = "Number of tonal bands used by the stylized pass."; > = 5;
uniform float FDINK_BandSoftness < ui_type = "slider"; ui_label = "Band Softness"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Blends hard cel bands back toward the source image."; > = 0.380000;
uniform float FDINK_EdgeThreshold < ui_type = "slider"; ui_label = "Edge Threshold"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.001; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Minimum combined luma/depth edge response before ink appears."; > = 0.085000;
uniform float FDINK_EdgeSoftness < ui_type = "slider"; ui_label = "Edge Softness"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.001; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Soft knee around the edge threshold."; > = 0.105000;
uniform float FDINK_LumaEdgeGain < ui_type = "slider"; ui_label = "Luma Edge Gain"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 8.0; ui_step = 0.001; ui_tooltip = "Weight of luminance discontinuities."; > = 2.250000;
uniform float FDINK_DepthEdgeGain < ui_type = "slider"; ui_label = "Depth Edge Gain"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 128.0; ui_step = 0.01; ui_tooltip = "Weight of depth discontinuities."; > = 42.000000;
uniform float FDINK_RadiusPixels < ui_type = "slider"; ui_label = "bio Radius"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.25; ui_max = 24.0; ui_step = 0.01; ui_tooltip = "Screen-space radius for Fibonacci bio ink support."; > = 2.200000;
uniform int FDINK_TapCount < ui_type = "slider"; ui_label = "Tap Budget"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 4; ui_max = FDREAM_LENS55_TAP_COUNT; ui_step = 1; ui_tooltip = "Bounded Lens55 tap budget. High and Ultra fidelity increase coverage without expanding the tap body."; > = 34;
uniform float FDINK_OrganicStrength < ui_type = "slider"; ui_label = "bio Strength"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "How strongly Fibonacci support reinforces the base ink edge."; > = 0.520000;
uniform float FDINK_FibAnchor < ui_type = "slider"; ui_label = "Fibonacci Anchor"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 987.0; ui_max = 4181.0; ui_step = 1.0; ui_tooltip = "Anchor index for bio Fibonacci direction generation."; > = 2584.000000;
uniform float FDINK_OrganicFlow < ui_type = "slider"; ui_label = "bio Flow"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Stable phase drift for bio ink hatching."; > = 1.150000;
uniform float FDINK_DepthGate < ui_type = "slider"; ui_label = "Depth Gate"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Suppresses stylization when depth is unstable."; > = 0.640000;
uniform float FDINK_DepthReject < ui_type = "slider"; ui_label = "Depth Reject"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0001; ui_max = 0.2000; ui_step = 0.0001; ui_tooltip = "Depth mismatch threshold for bio ink taps."; > = 0.018000;
uniform int FDINK_RespectFog < ui_type = "combo"; ui_label = "Respect Fog"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Bypasses ink stylization in fog-dominant regions."; > = 1;
uniform int FDINK_RespectLight < ui_type = "combo"; ui_label = "Respect Light"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Protects emissive pixels from ink darkening."; > = 1;
uniform float FDINK_LightProtectStrength < ui_type = "slider"; ui_label = "Light Protect Strength"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "How strongly protected lights return to source color."; > = 0.900000;
uniform float3 FDINK_InkColor < ui_type = "color"; ui_label = "Ink Color"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 03 Sub Settings"; ui_category_closed = true; ui_tooltip = "Line color used for stylized ink edges."; > = float3(0.020000, 0.018000, 0.015000);
uniform float FDINK_DebugExposure < ui_type = "slider"; ui_label = "Debug Exposure"; ui_category = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands / 00 Debug"; ui_category_closed = true; ui_min = 1.0; ui_max = 32.0; ui_step = 0.1; ui_tooltip = "Boosts debug buffer visibility."; > = 8.000000;

float2 FDINK_Pixel() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
float3 FDINK_Source(float2 uv) { return tex2D(ReShade::BackBuffer, saturate(uv)).rgb; }
float FDINK_RawDepth(float2 uv) { return tex2D(ReShade::DepthBuffer, saturate(uv)).r; }
float FDINK_Depth(float2 uv) { return saturate(ReShade::GetLinearizedDepth(saturate(uv))); }
float FDINK_Luma(float3 color) { return dot(color, float3(0.2126, 0.7152, 0.0722)); }
float FDINK_DebugScalar(float value) { return pow(saturate(value * max(1.0, FDINK_DebugExposure)), 0.65); }

int FDINK_TierTapCap() { return FDREAM_Lens55TierTapCap(FDINK_PresetTier); }
float FDINK_TierScale() { return FDREAM_Lens55TierScale(FDINK_PresetTier); }
float FDINK_TierStrength() { if (FDINK_PresetTier == 0) return 0.72; if (FDINK_PresetTier == 1) return 1.00; if (FDINK_PresetTier == 2) return 1.16; if (FDINK_PresetTier == 3) return 1.24; return 1.32; }

float FDINK_LightMask(float3 sourceColor)
{
    if (FDINK_RespectLight == 0)
    {
        return 0.0;
    }

    return FC_LIGHT_EmissionMask(sourceColor, FDINK_Luma(sourceColor), 0.680000, 0.180000, 0.700000, 0.350000, 0.220000, FDINK_EPS);
}

float FDINK_LocalLightZone(float2 uv, float3 sourceColor, float centerLightMask)
{
    if (FDINK_RespectLight == 0)
    {
        return 0.0;
    }

    float2 px = FDINK_Pixel() * 2.0;
    float zone = centerLightMask;
    zone = max(zone, FDINK_LightMask(FDINK_Source(uv + float2(px.x, 0.0))));
    zone = max(zone, FDINK_LightMask(FDINK_Source(uv - float2(px.x, 0.0))));
    zone = max(zone, FDINK_LightMask(FDINK_Source(uv + float2(0.0, px.y))));
    zone = max(zone, FDINK_LightMask(FDINK_Source(uv - float2(0.0, px.y))));
    return saturate(zone * FDINK_LightProtectStrength);
}

float FDINK_DepthGateMask(float2 uv, float centerDepth)
{
    float2 px = FDINK_Pixel();
    float dR = FDINK_Depth(uv + float2(px.x, 0.0));
    float dL = FDINK_Depth(uv - float2(px.x, 0.0));
    float dU = FDINK_Depth(uv + float2(0.0, px.y));
    float dD = FDINK_Depth(uv - float2(0.0, px.y));
    float rawDepth = FDINK_RawDepth(uv);
    float rangeMask = step(FDINK_EPS, rawDepth) * step(rawDepth, 0.999990);
    float slope = abs(dR - dL) + abs(dU - dD);
    float fit = abs(dR - centerDepth) + abs(dL - centerDepth) + abs(dU - centerDepth) + abs(dD - centerDepth);
    float continuity = 1.0 - saturate((slope + fit * 0.25) * 32.0);
    float tierBias = (FDINK_PresetTier == 0) ? 0.12 : ((FDINK_PresetTier == 1) ? 0.0 : -0.08);
    return saturate(lerp(1.0, rangeMask * continuity, saturate(FDINK_DepthGate + tierBias)));
}

float FDINK_EdgeAt(float2 uv)
{
    float2 px = FDINK_Pixel();
    float3 cC = FDINK_Source(uv);
    float lC = FDINK_Luma(cC);
    float lR = FDINK_Luma(FDINK_Source(uv + float2(px.x, 0.0)));
    float lL = FDINK_Luma(FDINK_Source(uv - float2(px.x, 0.0)));
    float lU = FDINK_Luma(FDINK_Source(uv + float2(0.0, px.y)));
    float lD = FDINK_Luma(FDINK_Source(uv - float2(0.0, px.y)));
    float dC = FDINK_Depth(uv);
    float dR = FDINK_Depth(uv + float2(px.x, 0.0));
    float dL = FDINK_Depth(uv - float2(px.x, 0.0));
    float dU = FDINK_Depth(uv + float2(0.0, px.y));
    float dD = FDINK_Depth(uv - float2(0.0, px.y));
    float lumaEdge = max(max(abs(lR - lC), abs(lL - lC)), max(abs(lU - lC), abs(lD - lC))) * FDINK_LumaEdgeGain;
    float depthEdge = max(max(abs(dR - dC), abs(dL - dC)), max(abs(dU - dC), abs(dD - dC))) * FDINK_DepthEdgeGain;
    return smoothstep(FDINK_EdgeThreshold, FDINK_EdgeThreshold + FDINK_EdgeSoftness, lumaEdge + depthEdge);
}

float FDINK_CleanEdge(float2 uv, float edge)
{
    float2 px = FDINK_Pixel();
    float eR = FDINK_EdgeAt(uv + float2(px.x, 0.0));
    float eL = FDINK_EdgeAt(uv - float2(px.x, 0.0));
    float eU = FDINK_EdgeAt(uv + float2(0.0, px.y));
    float eD = FDINK_EdgeAt(uv - float2(0.0, px.y));
    float neighbor = (eR + eL + eU + eD) * 0.25;
    return saturate(max(edge * 0.72, neighbor));
}

float2 FDINK_FibonacciDirection(float fibIndex)
{
    const float goldenAngle = 2.39996323;
    float angle = fibIndex * goldenAngle;
    return float2(cos(angle), sin(angle));
}

float2 FDINK_OrganicDirection(float2 lensOffset, float fibIndex, float2 uv, float tapNorm)
{
    float2 fibDir = FDINK_FibonacciDirection(fibIndex);
    float2 lensDir = normalize(float2(0.23 - lensOffset.y, 0.17 + lensOffset.x + frac(fibIndex * 0.000618)));
    float2 baseDir = normalize(lerp(lensDir, fibDir, 0.44 + 0.24 * tapNorm));
    float phase = fibIndex * 0.013 + FDINK_OrganicFlow * 0.17 + dot(uv * 72.0, float2(0.754, 0.569));
    float cs = cos(phase);
    float sn = sin(phase);
    return normalize(float2(baseDir.x * cs - baseDir.y * sn, baseDir.x * sn + baseDir.y * cs));
}

void FDINK_AccumulateTap(float2 uv, float centerDepth, float centerLuma, float2 offset, int index, int tapCount, inout float supportSum, inout float weightSum)
{
    if (index < tapCount)
    {
        float tapNorm = (float(index) + 0.5) / max(1.0, float(tapCount));
        float fibIndex = FDINK_FibAnchor + float(index);
        float2 direction = FDINK_OrganicDirection(offset, fibIndex, uv, tapNorm);
        float radial = FDREAM_Lens55FibonacciGrowth(index, tapCount);
        float2 sampleUv = uv + direction * FDINK_Pixel() * FDINK_RadiusPixels * FDINK_TierScale() * radial;
        float3 sampleColor = FDINK_Source(sampleUv);
        float sampleLuma = FDINK_Luma(sampleColor);
        float sampleDepth = FDINK_Depth(sampleUv);
        float sampleEdge = FDINK_EdgeAt(sampleUv);
        float depthWeight = 1.0 - smoothstep(FDINK_DepthReject, FDINK_DepthReject * 2.5, abs(sampleDepth - centerDepth));
        float toneMark = saturate(abs(sampleLuma - centerLuma) * FDINK_LumaEdgeGain);
        float hatch = 0.5 + 0.5 * sin(fibIndex * 0.233 + dot(sampleUv * 144.0, float2(0.618, 0.382)));
        float support = saturate(sampleEdge + toneMark * 0.35) * depthWeight * (0.84 + 0.16 * hatch);
        supportSum += support * (1.0 - tapNorm * 0.18);
        weightSum += depthWeight;
    }
}

float3 FDINK_ApplyCelTone(float3 sourceColor, float sourceLuma)
{
    float bands = max(2.0, float(FDINK_CelBands));
    float hardBand = floor(sourceLuma * bands + 0.5) / bands;
    float softBand = lerp(hardBand, sourceLuma, saturate(FDINK_BandSoftness));
    float3 celColor = saturate(sourceColor * (softBand / max(FDINK_EPS, sourceLuma)));
    return lerp(sourceColor, celColor, FDINK_StylizeStrength);
}

float4 FDINK_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    int tapCount = min(clamp(FDINK_TapCount, 1, FDREAM_LENS55_TAP_COUNT), FDINK_TierTapCap());
    float3 sourceColor = FDINK_Source(uv);
    float sourceLuma = FDINK_Luma(sourceColor);
    float centerDepth = FDINK_Depth(uv);
    float depthGate = FDINK_DepthGateMask(uv, centerDepth);
    float baseEdge = FDINK_CleanEdge(uv, FDINK_EdgeAt(uv));
    float supportSum = baseEdge;
    float weightSum = 1.0;

    [loop]
    for (int tapIndex = 0; tapIndex < FDREAM_LENS55_TAP_COUNT; ++tapIndex)
    {
        if (tapIndex < tapCount)
        {
            FDINK_AccumulateTap(uv, centerDepth, sourceLuma, FDREAM_Lens55Offset(tapIndex), tapIndex, tapCount, supportSum, weightSum);
        }
    }

    float organicSupport = supportSum / max(FDINK_EPS, weightSum);
    float lightMask = FDINK_LightMask(sourceColor);
    float lightZone = FDINK_LocalLightZone(uv, sourceColor, lightMask);
    float inkMask = saturate((baseEdge + organicSupport * FDINK_OrganicStrength) * depthGate * (1.0 - lightZone * 0.75));
    inkMask = saturate(inkMask * FDINK_InkStrength * FDINK_MasterIntensity * FDINK_TierStrength());

    float3 stylizedColor = FDINK_ApplyCelTone(sourceColor, sourceLuma);
    stylizedColor = lerp(sourceColor, stylizedColor, depthGate * (1.0 - lightZone * 0.65));
    float3 effectColor = lerp(stylizedColor, FDINK_InkColor, inkMask);

    effectColor = FC_LIGHT_ProtectColor(effectColor, sourceColor, lightMask, FDINK_LightProtectStrength);
    float fogBypass = FC_FOG_BypassMask(uv, sourceColor, FDINK_RespectFog);
    effectColor = lerp(effectColor, sourceColor, fogBypass);

    if (FDINK_DebugView == 1) return float4(FDINK_DebugScalar(inkMask).xxx, 1.0);
    if (FDINK_DebugView == 2) return float4(FDINK_Luma(stylizedColor).xxx, 1.0);
    if (FDINK_DebugView == 3) return float4(FDINK_DebugScalar(organicSupport).xxx, 1.0);
    if (FDINK_DebugView == 4) return float4(FDINK_DebugScalar(depthGate).xxx, 1.0);
    if (FDINK_DebugView == 5) return float4(FDINK_DebugScalar(lightZone).xxx, 1.0);
    return float4(saturate(effectColor), 1.0);
}
technique fine_dream_bio_ink_stylized < ui_label = "Fine Cell - Ink Stylization - Bio Fibonacci Edge Bands"; ui_tooltip = "Fibonacci bio ink edge stylization with cel tone bands, depth stability, and light/fog guards."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FDINK_MainPS;
    }
}






