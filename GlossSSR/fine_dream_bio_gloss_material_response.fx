// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: dream-gloss-1
// Capability: Portable Fibonacci bio gloss from SSR-style normals and bloom-style highlight diffusion.



#include "ReShade.fxh"
#include "FineCell_FogGate.fxh"
#include "FineCell_LightRespect.fxh"
#include "FineDream_Lens55Bounded.fxh"

uniform int FDGLOSS_PresetTier < ui_type = "combo"; ui_label = "Preset Tier"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 02 Main Settings"; ui_items = "Basic Conservative\0Liberal Coverage\0Aggressive Aggregate\0High Fidelity\0Ultra Fidelity\0"; ui_tooltip = "High Fidelity is the base standard; Ultra increases bounded Lens55 gloss coverage."; > = 1;
uniform int FDGLOSS_DebugView < ui_type = "combo"; ui_label = "Debug View"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 00 Debug"; ui_category_closed = true; ui_items = "Final\0Application Mask\0Diffuse Gloss\0Normal\0Depth Gate\0"; ui_tooltip = "Shows the final output or diagnostic masks."; > = 0;
uniform float FDGLOSS_MasterIntensity < ui_type = "slider"; ui_label = "Master Intensity"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 02 Main Settings"; ui_min = 0.0; ui_max = 2.3725; ui_step = 0.001; ui_tooltip = "Overall multiplier for gloss."; > = 1.898000;
uniform float FDGLOSS_GlossStrength < ui_type = "slider"; ui_label = "Gloss Strength"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 02 Main Settings"; ui_min = 0.0; ui_max = 2.3; ui_step = 0.001; ui_tooltip = "How strongly glossy color is added."; > = 1.527000;
uniform float FDGLOSS_BloomStrength < ui_type = "slider"; ui_label = "Bloom Diffusion"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 02 Main Settings"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Soft highlight diffusion borrowed from bloom behavior."; > = 1.024000;
uniform float FDGLOSS_Threshold < ui_type = "slider"; ui_label = "Highlight Threshold"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Brightness where gloss extraction starts."; > = 0.720000;
uniform float FDGLOSS_Softness < ui_type = "slider"; ui_label = "Highlight Softness"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.001; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Soft knee around the gloss threshold."; > = 0.280000;
uniform float FDGLOSS_RadiusPixels < ui_type = "slider"; ui_label = "Gloss Radius"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.25; ui_max = 32.0; ui_step = 0.01; ui_tooltip = "Base screen-space radius in pixels before tier scaling."; > = 4.500000;
uniform int FDGLOSS_TapCount < ui_type = "slider"; ui_label = "Tap Budget"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 4; ui_max = FDREAM_LENS55_TAP_COUNT; ui_step = 1; ui_tooltip = "Bounded Lens55 tap budget. High and Ultra fidelity increase coverage without expanding the tap body."; > = 34;
uniform float FDGLOSS_NormalStrength < ui_type = "slider"; ui_label = "Normal Strength"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.1; ui_max = 24.0; ui_step = 0.1; ui_tooltip = "Strength multiplier for depth-derived normals."; > = 5.000000;
uniform float FDGLOSS_DepthGate < ui_type = "slider"; ui_label = "Depth Gate"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_tooltip = "Suppresses gloss when depth is unstable."; > = 0.600000;
uniform float FDGLOSS_DepthReject < ui_type = "slider"; ui_label = "Depth Reject"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0001; ui_max = 0.2000; ui_step = 0.0001; ui_tooltip = "Depth mismatch threshold for nearby glossy taps."; > = 0.020000;
uniform float FDGLOSS_FibAnchor < ui_type = "slider"; ui_label = "Fibonacci Anchor"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 987.0; ui_max = 4181.0; ui_step = 1.0; ui_tooltip = "Anchor index for bio Fibonacci gloss."; > = 2584.000000;
uniform float FDGLOSS_OrganicFlow < ui_type = "slider"; ui_label = "bio Flow"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 4.0; ui_step = 0.001; ui_tooltip = "Phase drift for bio gloss direction."; > = 1.100000;
uniform float FDGLOSS_Saturation < ui_type = "slider"; ui_label = "Gloss Saturation"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 03 Sub Settings"; ui_category_closed = true; ui_min = 0.0; ui_max = 2.0; ui_step = 0.001; ui_tooltip = "Saturation of glossy highlight color."; > = 1.080000;
uniform int FDGLOSS_RespectFog < ui_type = "combo"; ui_label = "Respect Fog"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Bypasses gloss in fog-dominant regions."; > = 1;
uniform int FDGLOSS_RespectLight < ui_type = "combo"; ui_label = "Respect Light Emission"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_items = "No\0Yes\0"; ui_tooltip = "Protects emissive pixels from being altered."; > = 1;
uniform float FDGLOSS_LightProtectStrength < ui_type = "slider"; ui_label = "Light Protect Strength"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 01 Guards (Respect Fog/Light)"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.15; ui_step = 0.001; ui_tooltip = "How strongly protected lights return to source color."; > = 0.850000;
uniform float FDGLOSS_DebugExposure < ui_type = "slider"; ui_label = "Debug Exposure"; ui_category = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion / 00 Debug"; ui_category_closed = true; ui_min = 1.0; ui_max = 32.0; ui_step = 0.1; ui_tooltip = "Boosts debug buffer visibility."; > = 1.000000;

float2 FDGLOSS_Pixel() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
float3 FDGLOSS_Source(float2 uv) { return tex2D(ReShade::BackBuffer, saturate(uv)).rgb; }
float FDGLOSS_RawDepth(float2 uv) { return tex2D(ReShade::DepthBuffer, saturate(uv)).r; }
float FDGLOSS_Depth(float2 uv) { return saturate(ReShade::GetLinearizedDepth(saturate(uv))); }
float FDGLOSS_Luma(float3 color) { return dot(color, float3(0.2126, 0.7152, 0.0722)); }
float3 FDGLOSS_SaturateAroundLuma(float3 color, float amount) { float luma = FDGLOSS_Luma(color); return lerp(luma.xxx, color, amount); }
float FDGLOSS_DebugScalar(float value) { return pow(saturate(value * max(1.0, FDGLOSS_DebugExposure)), 0.65); }

int FDGLOSS_TierTapCap()
{
    return FDREAM_Lens55TierTapCap(FDGLOSS_PresetTier);
}

float FDGLOSS_TierRadiusScale()
{
    return FDREAM_Lens55TierScale(FDGLOSS_PresetTier);
}

float FDGLOSS_TierStrengthScale()
{
    if (FDGLOSS_PresetTier == 0) return 0.72;
    if (FDGLOSS_PresetTier == 1) return 1.00;
    if (FDGLOSS_PresetTier == 2) return 1.20;
    if (FDGLOSS_PresetTier == 3) return 1.28;
    return 1.36;
}

float FDGLOSS_LightEmissionMask(float3 sourceColor)
{
    if (FDGLOSS_RespectLight == 0)
    {
        return 0.0;
    }

    return FC_LIGHT_EmissionMask(sourceColor, FDGLOSS_Luma(sourceColor), 0.680000, 0.180000, 0.700000, 0.350000, 0.220000, 0.000010);
}

float FDGLOSS_LocalLightZone(float2 uv, float3 sourceColor, float centerLightMask)
{
    if (FDGLOSS_RespectLight == 0)
    {
        return 0.0;
    }

    float2 px = FDGLOSS_Pixel() * 2.0;
    float zone = centerLightMask;
    zone = max(zone, FDGLOSS_LightEmissionMask(FDGLOSS_Source(uv + float2(px.x, 0.0))));
    zone = max(zone, FDGLOSS_LightEmissionMask(FDGLOSS_Source(uv - float2(px.x, 0.0))));
    zone = max(zone, FDGLOSS_LightEmissionMask(FDGLOSS_Source(uv + float2(0.0, px.y))));
    zone = max(zone, FDGLOSS_LightEmissionMask(FDGLOSS_Source(uv - float2(0.0, px.y))));
    return saturate(zone * FDGLOSS_LightProtectStrength);
}

float3 FDGLOSS_Normal(float2 uv, out float edgeFactor)
{
    float2 px = FDGLOSS_Pixel();
    float dC = FDGLOSS_Depth(uv);
    float dR = FDGLOSS_Depth(uv + float2(px.x, 0.0));
    float dL = FDGLOSS_Depth(uv - float2(px.x, 0.0));
    float dU = FDGLOSS_Depth(uv + float2(0.0, px.y));
    float dD = FDGLOSS_Depth(uv - float2(0.0, px.y));
    float gradX = (abs(dR - dC) < abs(dC - dL)) ? (dR - dC) : (dC - dL);
    float gradY = (abs(dU - dC) < abs(dC - dD)) ? (dU - dC) : (dC - dD);
    edgeFactor = saturate((abs(gradX) + abs(gradY)) * 64.0);
    float3 n = normalize(float3(-gradX * FDGLOSS_NormalStrength, -gradY * FDGLOSS_NormalStrength, 1.0));
    n.z = abs(n.z);
    return normalize(n);
}

float FDGLOSS_DepthGateMask(float2 uv, float centerDepth)
{
    float2 px = FDGLOSS_Pixel();
    float dR = FDGLOSS_Depth(uv + float2(px.x, 0.0));
    float dL = FDGLOSS_Depth(uv - float2(px.x, 0.0));
    float dU = FDGLOSS_Depth(uv + float2(0.0, px.y));
    float dD = FDGLOSS_Depth(uv - float2(0.0, px.y));
    float rawDepth = FDGLOSS_RawDepth(uv);
    float rangeMask = step(0.000010, rawDepth) * step(rawDepth, 0.999990);
    float slope = abs(dR - dL) + abs(dU - dD);
    float fit = abs(dR - centerDepth) + abs(dL - centerDepth) + abs(dU - centerDepth) + abs(dD - centerDepth);
    float continuity = 1.0 - saturate((slope + fit * 0.25) * 30.0);
    float tierBias = (FDGLOSS_PresetTier == 0) ? 0.12 : ((FDGLOSS_PresetTier == 1) ? 0.0 : -0.08);
    return saturate(lerp(1.0, rangeMask * continuity, saturate(FDGLOSS_DepthGate + tierBias)));
}

float FDGLOSS_BrightMask(float3 color)
{
    return smoothstep(FDGLOSS_Threshold, FDGLOSS_Threshold + max(0.000010, FDGLOSS_Softness), FDGLOSS_Luma(color));
}

float2 FDGLOSS_FibonacciDirection(float fibIndex)
{
    const float goldenAngle = 2.39996323;
    float angle = fibIndex * goldenAngle;
    return float2(cos(angle), sin(angle));
}

float2 FDGLOSS_OrganicDirection(float2 lensOffset, float fibIndex, float2 uv, float tapNorm)
{
    float2 fibDir = FDGLOSS_FibonacciDirection(fibIndex);
    float2 lensDir = normalize(float2(0.23 - lensOffset.y, 0.17 + lensOffset.x + frac(fibIndex * 0.000618)));
    float2 baseDir = normalize(lerp(lensDir, fibDir, 0.42 + 0.24 * tapNorm));
    float phase = fibIndex * 0.013 + FDGLOSS_OrganicFlow * 0.17 + dot(uv * 72.0, float2(0.754, 0.569));
    float cs = cos(phase);
    float sn = sin(phase);
    return normalize(float2(baseDir.x * cs - baseDir.y * sn, baseDir.x * sn + baseDir.y * cs));
}

void FDGLOSS_AccumulateTap(float2 uv, float centerDepth, float3 centerNormal, float2 lensOffset, int tapIndex, int tapCount, inout float3 tightSum, inout float tightWeight, inout float3 bloomSum, inout float bloomWeight)
{
    if (tapIndex < tapCount)
    {
        float tapNorm = (float(tapIndex) + 0.5) / max(1.0, float(tapCount));
        float fibIndex = FDGLOSS_FibAnchor + float(tapIndex);
        float2 direction = FDGLOSS_OrganicDirection(lensOffset, fibIndex, uv, tapNorm);
        float radial = FDREAM_Lens55FibonacciGrowth(tapIndex, tapCount);
        float2 sampleUv = uv + direction * FDGLOSS_Pixel() * FDGLOSS_RadiusPixels * FDGLOSS_TierRadiusScale() * radial;
        float3 sampleColor = FDGLOSS_Source(sampleUv);
        float sampleDepth = FDGLOSS_Depth(sampleUv);
        float sampleEdge = 0.0;
        float3 sampleNormal = FDGLOSS_Normal(sampleUv, sampleEdge);
        float depthWeight = 1.0 - smoothstep(FDGLOSS_DepthReject, FDGLOSS_DepthReject * 2.5, abs(sampleDepth - centerDepth));
        float normalWeight = pow(max(0.0001, saturate(dot(centerNormal, sampleNormal))), 4.0);
        float brightWeight = FDGLOSS_BrightMask(sampleColor);
        float tightTap = depthWeight * normalWeight * brightWeight * (1.0 - 0.30 * tapNorm);
        float bloomTap = depthWeight * brightWeight * (0.65 + 0.35 * (1.0 - tapNorm));
        tightSum += sampleColor * tightTap;
        tightWeight += tightTap;
        bloomSum += sampleColor * bloomTap;
        bloomWeight += bloomTap;
    }
}

float4 FDGLOSS_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    int tapCount = min(clamp(FDGLOSS_TapCount, 1, FDREAM_LENS55_TAP_COUNT), FDGLOSS_TierTapCap());
    float3 sourceColor = FDGLOSS_Source(uv);
    float centerDepth = FDGLOSS_Depth(uv);
    float edgeFactor = 0.0;
    float3 centerNormal = FDGLOSS_Normal(uv, edgeFactor);
    float depthGate = FDGLOSS_DepthGateMask(uv, centerDepth);
    float centerMask = FDGLOSS_BrightMask(sourceColor);
    float3 tightSum = sourceColor * centerMask;
    float tightWeight = max(0.000010, centerMask);
    float3 bloomSum = sourceColor * centerMask;
    float bloomWeight = max(0.000010, centerMask);

    [loop]
    for (int tapIndex = 0; tapIndex < FDREAM_LENS55_TAP_COUNT; ++tapIndex)
    {
        if (tapIndex < tapCount)
        {
            FDGLOSS_AccumulateTap(uv, centerDepth, centerNormal, FDREAM_Lens55Offset(tapIndex), tapIndex, tapCount, tightSum, tightWeight, bloomSum, bloomWeight);
        }
    }

    float3 tightGloss = tightSum / max(0.000010, tightWeight);
    float3 bloomGloss = bloomSum / max(0.000010, bloomWeight);
    float aggregateBlend = (FDGLOSS_PresetTier >= 4) ? 0.70 : ((FDGLOSS_PresetTier == 3) ? 0.62 : ((FDGLOSS_PresetTier == 2) ? 0.55 : ((FDGLOSS_PresetTier == 1) ? 0.35 : 0.15)));
    float3 glossColor = lerp(tightGloss, bloomGloss, aggregateBlend);
    glossColor = FDGLOSS_SaturateAroundLuma(glossColor, FDGLOSS_Saturation);
    float glossMask = saturate((tightWeight + bloomWeight) / max(1.0, float(tapCount) * 2.0));
    glossMask *= depthGate * (1.0 - edgeFactor * 0.35);
    float lightProtectMask = FDGLOSS_LightEmissionMask(sourceColor);
    float lightZone = FDGLOSS_LocalLightZone(uv, sourceColor, lightProtectMask);
    float applicationMask = saturate(glossMask * (1.0 - lightZone * 0.75));
    float3 effectColor = sourceColor + (glossColor - sourceColor) * applicationMask * FDGLOSS_GlossStrength * FDGLOSS_MasterIntensity * FDGLOSS_TierStrengthScale();
    effectColor += bloomGloss * applicationMask * FDGLOSS_BloomStrength * FDGLOSS_MasterIntensity;

    effectColor = FC_LIGHT_ProtectColor(effectColor, sourceColor, lightProtectMask, FDGLOSS_LightProtectStrength);
    float fogBypass = FC_FOG_BypassMask(uv, sourceColor, FDGLOSS_RespectFog);
    effectColor = lerp(effectColor, sourceColor, fogBypass);

    if (FDGLOSS_DebugView == 1) return float4(FDGLOSS_DebugScalar(applicationMask).xxx, 1.0);
    if (FDGLOSS_DebugView == 2) return float4(saturate(glossColor), 1.0);
    if (FDGLOSS_DebugView == 3) return float4(centerNormal * 0.5 + 0.5, 1.0);
    if (FDGLOSS_DebugView == 4) return float4(FDGLOSS_DebugScalar(depthGate).xxx, 1.0);
    return float4(saturate(effectColor), 1.0);
}
technique fine_dream_bio_gloss_material_response < ui_label = "Fine Cell - Gloss Reflection - Bio Fibonacci Diffusion"; ui_tooltip = "Portable Fibonacci bio gloss using SSR-style depth normals and bloom-style highlight diffusion."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FDGLOSS_MainPS;
    }
}






