// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: dream-balanced-shadow-richness-lift-1
// Capability: Shadow lift with highlight restraint and chroma-preserving deep color balance.
// Function: lifts shadows based on luminance and local tone support, preserves
// highlight headroom, and reapplies chroma with balanced saturation control.

#include "ReShade.fxh"
#include "FineCell_FogGate.fxh"
#include "FineCell_LightRespect.fxh"

#define FDBSL_EPS 0.000010

uniform int FDBSL_DebugView <
    ui_type = "combo";
    ui_label = "Debug View";
    ui_category = "Fine Cell - Shadow Balance - Lift and Deep Color / 00 Debug"; ui_category_closed = true;
    ui_items = "Final\0Shadow Mask\0Local Support\0Lift Delta\0Color Gate\0";
    ui_tooltip = "Shows final output or internal masks used by shadow brightening and color balance.";
> = 0;

uniform float FDBSL_MasterIntensity <
    ui_type = "slider";
    ui_label = "Master Intensity";
    ui_category = "Fine Cell - Shadow Balance - Lift and Deep Color / 02 Main Settings";
    ui_min = 0.0; ui_max = 2.3; ui_step = 0.001;
    ui_tooltip = "Global multiplier for the full effect.";
> = 1.680000;

uniform float FDBSL_ShadowLift <
    ui_type = "slider";
    ui_label = "Shadow Lift";
    ui_category = "Fine Cell - Shadow Balance - Lift and Deep Color / 02 Main Settings";
    ui_min = 0.0; ui_max = 1.5; ui_step = 0.001;
    ui_tooltip = "How strongly dark regions are brightened.";
> = 0.461000;

uniform float FDBSL_MaxLift <
    ui_type = "slider";
    ui_label = "Max Lift";
    ui_category = "Fine Cell - Shadow Balance - Lift and Deep Color / 02 Main Settings";
    ui_min = 0.0; ui_max = 0.600; ui_step = 0.001;
    ui_tooltip = "Hard cap on per-pixel luminance lift to prevent over-brightening.";
> = 0.053000;

uniform float FDBSL_HighlightProtect <
    ui_type = "slider";
    ui_label = "Highlight Protect";
    ui_category = "Fine Cell - Shadow Balance - Lift and Deep Color / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.15; ui_step = 0.001;
    ui_tooltip = "Suppresses lift in bright regions to keep highlight headroom.";
> = 0.850000;

uniform float FDBSL_HighlightStart <
    ui_type = "slider";
    ui_label = "Highlight Start";
    ui_category = "Fine Cell - Shadow Balance - Lift and Deep Color / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.3; ui_max = 0.98; ui_step = 0.001;
    ui_tooltip = "Luminance where highlight protection begins.";
> = 0.620000;

uniform float FDBSL_ShadowStart <
    ui_type = "slider";
    ui_label = "Shadow Start";
    ui_category = "Fine Cell - Shadow Balance - Lift and Deep Color / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 0.7; ui_step = 0.001;
    ui_tooltip = "Luminance center for shadow-targeted lifting.";
> = 0.420000;

uniform float FDBSL_ShadowSoftness <
    ui_type = "slider";
    ui_label = "Shadow Softness";
    ui_category = "Fine Cell - Shadow Balance - Lift and Deep Color / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.01; ui_max = 0.8; ui_step = 0.001;
    ui_tooltip = "Transition width around the shadow range.";
> = 0.260000;

uniform float FDBSL_LocalRadiusPixels <
    ui_type = "slider";
    ui_label = "Local Radius";
    ui_category = "Fine Cell - Shadow Balance - Lift and Deep Color / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.25; ui_max = 6.0; ui_step = 0.01;
    ui_tooltip = "Neighborhood radius used to estimate local tone support.";
> = 1.000000;

uniform float FDBSL_LocalContrastKeep <
    ui_type = "slider";
    ui_label = "Local Contrast Keep";
    ui_category = "Fine Cell - Shadow Balance - Lift and Deep Color / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.5; ui_step = 0.001;
    ui_tooltip = "Preserves local tonal detail while lifting shadows.";
> = 0.450000;

uniform float FDBSL_ColorBalance <
    ui_type = "slider";
    ui_label = "Color Balance";
    ui_category = "Fine Cell - Shadow Balance - Lift and Deep Color / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.5; ui_step = 0.001;
    ui_tooltip = "Keeps chroma balanced after luminance lift.";
> = 0.850000;

uniform float FDBSL_SaturationGuard <
    ui_type = "slider";
    ui_label = "Saturation Guard";
    ui_category = "Fine Cell - Shadow Balance - Lift and Deep Color / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Reduces extra chroma push on already saturated colors.";
> = 0.600000;

uniform int FDBSL_RespectFog <
    ui_type = "combo";
    ui_label = "Respect Fog";
    ui_category = "Fine Cell - Shadow Balance - Lift and Deep Color / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_items = "No\0Yes\0";
    ui_tooltip = "Bypasses the effect in fog-dominant regions.";
> = 1;

uniform int FDBSL_RespectLight <
    ui_type = "combo";
    ui_label = "Respect Light Emission";
    ui_category = "Fine Cell - Shadow Balance - Lift and Deep Color / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_items = "No\0Yes\0";
    ui_tooltip = "Protects emissive highlights from being altered.";
> = 1;

uniform float FDBSL_LightProtectStrength <
    ui_type = "slider";
    ui_label = "Light Protect Strength";
    ui_category = "Fine Cell - Shadow Balance - Lift and Deep Color / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.15; ui_step = 0.001;
    ui_tooltip = "How strongly emissive pixels return to source color.";
> = 0.900000;

float3 FDBSL_Source(float2 uv) { return tex2D(ReShade::BackBuffer, saturate(uv)).rgb; }
float FDBSL_Luma(float3 c) { return dot(c, float3(0.2126, 0.7152, 0.0722)); }

float FDBSL_Saturation(float3 c)
{
    float peak = max(c.r, max(c.g, c.b));
    float trough = min(c.r, min(c.g, c.b));
    return saturate((peak - trough) / max(FDBSL_EPS, peak));
}

float FDBSL_LightMask(float3 sourceColor)
{
    if (FDBSL_RespectLight == 0) return 0.0;
    return FC_LIGHT_EmissionMask(sourceColor, FDBSL_Luma(sourceColor), 0.680000, 0.180000, 0.700000, 0.350000, 0.220000, FDBSL_EPS);
}

float FDBSL_LocalSupportLuma(float2 uv)
{
    float2 px = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT) * FDBSL_LocalRadiusPixels;
    float center = FDBSL_Luma(FDBSL_Source(uv)) * 2.0;
    float axis = FDBSL_Luma(FDBSL_Source(uv + float2(px.x, 0.0)))
               + FDBSL_Luma(FDBSL_Source(uv - float2(px.x, 0.0)))
               + FDBSL_Luma(FDBSL_Source(uv + float2(0.0, px.y)))
               + FDBSL_Luma(FDBSL_Source(uv - float2(0.0, px.y)));
    float diagonal = FDBSL_Luma(FDBSL_Source(uv + float2(px.x, px.y)))
                   + FDBSL_Luma(FDBSL_Source(uv + float2(-px.x, px.y)))
                   + FDBSL_Luma(FDBSL_Source(uv + float2(px.x, -px.y)))
                   + FDBSL_Luma(FDBSL_Source(uv + float2(-px.x, -px.y)));
    return (center + axis + diagonal * 0.75) / (2.0 + 4.0 + 3.0);
}

float4 FDBSL_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 sourceColor = FDBSL_Source(uv);
    float sourceLuma = FDBSL_Luma(sourceColor);
    float supportLuma = FDBSL_LocalSupportLuma(uv);

    float shadowLow = max(0.0, FDBSL_ShadowStart - FDBSL_ShadowSoftness);
    float shadowHigh = min(1.0, FDBSL_ShadowStart + FDBSL_ShadowSoftness);
    float shadowMask = 1.0 - smoothstep(shadowLow, shadowHigh, sourceLuma);

    float highlightMask = smoothstep(FDBSL_HighlightStart, 1.0, sourceLuma);
    float liftGate = saturate(shadowMask * (1.0 - highlightMask * FDBSL_HighlightProtect));

    float localDelta = sourceLuma - supportLuma;
    float contrastKeep = localDelta * FDBSL_LocalContrastKeep * (0.35 + 0.65 * shadowMask);
    float rawLift = FDBSL_ShadowLift * liftGate * FDBSL_MasterIntensity;
    float lift = min(rawLift, FDBSL_MaxLift);

    float targetLuma = saturate(sourceLuma + lift + contrastKeep);
    float liftDelta = targetLuma - sourceLuma;

    float lumaScale = targetLuma / max(FDBSL_EPS, sourceLuma);
    float3 scaledColor = sourceColor * lumaScale;
    float3 centered = sourceColor - sourceLuma.xxx;
    float sat = FDBSL_Saturation(sourceColor);
    float colorGate = saturate(1.0 - sat * FDBSL_SaturationGuard);
    float chromaGain = 1.0 + FDBSL_ColorBalance * colorGate * shadowMask;
    float3 balancedColor = targetLuma.xxx + centered * chromaGain;

    float3 effectColor = saturate(lerp(scaledColor, balancedColor, 0.65));

    float lightMask = FDBSL_LightMask(sourceColor);
    effectColor = FC_LIGHT_ProtectColor(effectColor, sourceColor, lightMask, FDBSL_LightProtectStrength);
    float fogBypass = FC_FOG_BypassMask(uv, sourceColor, FDBSL_RespectFog);
    effectColor = lerp(effectColor, sourceColor, fogBypass);

    if (FDBSL_DebugView == 1) return float4(shadowMask.xxx, 1.0);
    if (FDBSL_DebugView == 2) return float4(supportLuma.xxx, 1.0);
    if (FDBSL_DebugView == 3) return float4(saturate(liftDelta * 4.0 + 0.5).xxx, 1.0);
    if (FDBSL_DebugView == 4) return float4(colorGate.xxx, 1.0);
    return float4(effectColor, 1.0);
}

technique fine_dream_shadow_lift_and_deep_balance < ui_label = "Fine Cell - Shadow Balance - Lift and Deep Color"; ui_tooltip = "Lifts dark regions while protecting highlights and preserving deep color balance."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FDBSL_MainPS;
    }
}






