// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: RC-1
#ifndef FINECELL_FOG_GATE_FXH
#define FINECELL_FOG_GATE_FXH

uniform int AIGX_FOG_Enable <
    ui_type = "combo";
    ui_label = "Enable Unified Fog Gate";
    ui_category = "Fine Cell - Shared Fog Gate - Unified";
    ui_items = "No\0Yes\0";
> = 1;

uniform float AIGX_FOG_RespectStrength <
    ui_type = "slider";
    ui_label = "Respect Strength";
    ui_category = "Fine Cell - Shared Fog Gate - Unified";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
> = 1.000000;

uniform float AIGX_FOG_Sensitivity <
    ui_type = "slider";
    ui_label = "Fog Sensitivity";
    ui_category = "Fine Cell - Shared Fog Gate - Unified";
    ui_min = 0.0; ui_max = 4.0; ui_step = 0.001;
> = 0.800000;

uniform float AIGX_FOG_BrightnessFloor <
    ui_type = "slider";
    ui_label = "Brightness Floor";
    ui_category = "Fine Cell - Shared Fog Gate - Unified";
    ui_min = 0.0000; ui_max = 0.1000; ui_step = 0.0001;
> = 0.000600;

uniform float AIGX_FOG_Desaturation <
    ui_type = "slider";
    ui_label = "Desaturation";
    ui_category = "Fine Cell - Shared Fog Gate - Unified";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
> = 0.110000;

uniform float AIGX_FOG_LowContrast <
    ui_type = "slider";
    ui_label = "Low Contrast";
    ui_category = "Fine Cell - Shared Fog Gate - Unified";
    ui_min = 0.0; ui_max = 0.2500; ui_step = 0.00001;
> = 0.040000;

uniform float AIGX_FOG_MaskThreshold <
    ui_type = "slider";
    ui_label = "Mask Threshold";
    ui_category = "Fine Cell - Shared Fog Gate - Unified";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
> = 0.250000;

uniform float AIGX_FOG_MaskSoftness <
    ui_type = "slider";
    ui_label = "Mask Softness";
    ui_category = "Fine Cell - Shared Fog Gate - Unified";
    ui_min = 0.001; ui_max = 1.0; ui_step = 0.001;
> = 0.010000;

uniform float AIGX_FOG_MaskGamma <
    ui_type = "slider";
    ui_label = "Mask Gamma";
    ui_category = "Fine Cell - Shared Fog Gate - Unified";
    ui_min = 0.050; ui_max = 4.0; ui_step = 0.001;
> = 0.200000;

uniform float AIGX_FOG_RadiusPixels <
    ui_type = "slider";
    ui_label = "Probe Radius";
    ui_category = "Fine Cell - Shared Fog Gate - Unified";
    ui_min = 0.25; ui_max = 16.0; ui_step = 0.01;
> = 3.500000;

uniform float AIGX_FOG_DepthStart <
    ui_type = "slider";
    ui_label = "Depth Start";
    ui_category = "Fine Cell - Shared Fog Gate - Unified";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.0001;
> = 0.000000;

uniform float AIGX_FOG_DepthEnd <
    ui_type = "slider";
    ui_label = "Depth End";
    ui_category = "Fine Cell - Shared Fog Gate - Unified";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.0001;
> = 1.000000;

uniform int AIGX_FOG_DepthInvert <
    ui_type = "combo";
    ui_label = "Depth Invert";
    ui_category = "Fine Cell - Shared Fog Gate - Unified";
    ui_items = "No\0Yes\0";
> = 0;

uniform bool AIGX_FOG_HungryRespect <
    ui_type = "checkbox";
    ui_label = "Hungry Respect Fog";
    ui_category = "Fine Cell - Shared Fog Gate - Unified";
> = false;

uniform float AIGX_FOG_HungryBridgeThreshold <
    ui_type = "slider";
    ui_label = "Hungry Bridge Threshold";
    ui_category = "Fine Cell - Shared Fog Gate - Unified";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
> = 0.650000;

uniform float AIGX_FOG_HungryBridgeStrength <
    ui_type = "slider";
    ui_label = "Hungry Bridge Strength";
    ui_category = "Fine Cell - Shared Fog Gate - Unified";
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.001;
> = 1.000000;

float FC_FOG_Luma(float3 c)
{
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

float FC_FOG_Saturation(float3 c)
{
    float cMax = max(c.r, max(c.g, c.b));
    float cMin = min(c.r, min(c.g, c.b));
    return (cMax > 1e-6) ? ((cMax - cMin) / cMax) : 0.0;
}

float FC_FOG_DepthMask(float rawDepth)
{
    float depth = (AIGX_FOG_DepthInvert != 0) ? (1.0 - rawDepth) : rawDepth;
    float d0 = min(AIGX_FOG_DepthStart, AIGX_FOG_DepthEnd);
    float d1 = max(AIGX_FOG_DepthStart, AIGX_FOG_DepthEnd);
    float soft = max(1e-5, AIGX_FOG_MaskSoftness);

    float beginMask = smoothstep(d0 - soft, d0 + soft, depth);
    float endMask = 1.0 - smoothstep(d1 - soft, d1 + soft, depth);
    return saturate(beginMask * endMask);
}

float FC_FOG_LocalContrast(float2 uv)
{
    float2 px = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT) * AIGX_FOG_RadiusPixels;
    float c = FC_FOG_Luma(tex2D(ReShade::BackBuffer, saturate(uv)).rgb);
    float s1 = FC_FOG_Luma(tex2D(ReShade::BackBuffer, saturate(uv + float2(px.x, 0.0))).rgb);
    float s2 = FC_FOG_Luma(tex2D(ReShade::BackBuffer, saturate(uv + float2(-px.x, 0.0))).rgb);
    float s3 = FC_FOG_Luma(tex2D(ReShade::BackBuffer, saturate(uv + float2(0.0, px.y))).rgb);
    float s4 = FC_FOG_Luma(tex2D(ReShade::BackBuffer, saturate(uv + float2(0.0, -px.y))).rgb);
    return (abs(c - s1) + abs(c - s2) + abs(c - s3) + abs(c - s4)) * 0.25;
}

float FC_FOG_Core(float2 uv, float3 sourceColor)
{
    float luma = FC_FOG_Luma(sourceColor);
    float saturation = FC_FOG_Saturation(sourceColor);
    float desaturation = 1.0 - saturation;
    float contrast = FC_FOG_LocalContrast(uv);

    float soft = max(1e-5, AIGX_FOG_MaskSoftness);

    float brightMask = smoothstep(AIGX_FOG_BrightnessFloor, AIGX_FOG_BrightnessFloor + soft, luma);
    float desatMask = smoothstep(AIGX_FOG_Desaturation - soft, AIGX_FOG_Desaturation + soft, desaturation);
    float lowContrastMask = 1.0 - smoothstep(AIGX_FOG_LowContrast, AIGX_FOG_LowContrast + soft, contrast);

    float depthMask = FC_FOG_DepthMask(ReShade::GetLinearizedDepth(saturate(uv)));
    return saturate(brightMask * desatMask * lowContrastMask * depthMask);
}

float FC_FOG_CoreAtUV(float2 uv)
{
    float3 sourceColor = tex2D(ReShade::BackBuffer, saturate(uv)).rgb;
    return FC_FOG_Core(uv, sourceColor);
}

float FC_FOG_HungryBridge(float2 uv, float centerCore)
{
    if (!AIGX_FOG_HungryRespect)
        return 0.0;

    float2 basePx = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
    float span = max(0.50, AIGX_FOG_RadiusPixels * 0.75);
    float2 px = basePx * span;

    float pairX = min(FC_FOG_CoreAtUV(uv + float2( px.x, 0.0)), FC_FOG_CoreAtUV(uv + float2(-px.x, 0.0)));
    float pairY = min(FC_FOG_CoreAtUV(uv + float2(0.0,  px.y)), FC_FOG_CoreAtUV(uv + float2(0.0, -px.y)));
    float pairD1 = min(FC_FOG_CoreAtUV(uv + float2( px.x,  px.y)), FC_FOG_CoreAtUV(uv + float2(-px.x, -px.y)));
    float pairD2 = min(FC_FOG_CoreAtUV(uv + float2(-px.x,  px.y)), FC_FOG_CoreAtUV(uv + float2( px.x, -px.y)));

    float surroundingFog = max(max(pairX, pairY), max(pairD1, pairD2));
    float bridgePresence = smoothstep(AIGX_FOG_HungryBridgeThreshold, 1.0, surroundingFog);
    float thinLineGap = saturate(surroundingFog - centerCore);
    return saturate(bridgePresence * thinLineGap * AIGX_FOG_HungryBridgeStrength);
}

float FC_FOG_Mask(float2 uv, float3 sourceColor)
{
    if (AIGX_FOG_Enable == 0)
        return 0.0;

    float fogCore = FC_FOG_Core(uv, sourceColor);
    fogCore = max(fogCore, FC_FOG_HungryBridge(uv, fogCore));

    float soft = max(1e-5, AIGX_FOG_MaskSoftness);
    float fogThresholded = smoothstep(AIGX_FOG_MaskThreshold - soft, AIGX_FOG_MaskThreshold + soft, fogCore);
    float fogShaped = pow(saturate(fogThresholded), max(0.05, AIGX_FOG_MaskGamma));

    return saturate(fogShaped * AIGX_FOG_Sensitivity);
}

float FC_FOG_BypassMask(float2 uv, float3 sourceColor, int respectFogToggle)
{
    if (respectFogToggle == 0)
        return 0.0;

    return saturate(FC_FOG_Mask(uv, sourceColor) * AIGX_FOG_RespectStrength);
}

#endif
