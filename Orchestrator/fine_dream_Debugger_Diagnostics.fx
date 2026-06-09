// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: dream-fog-lightshield-gate-1
// Capability: Diagnostic control surface for true screen color, depth, fog, and light masks.



#include "ReShade.fxh"
#include "FineCell_LightRespect.fxh"

texture2D FDGATE_TrueScreenColor : COLOR;

sampler2D FDGATE_TrueScreenColorSampler
{
    Texture = FDGATE_TrueScreenColor;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = NONE;
};

texture2D FDGATE_StableBackBuffer
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

sampler2D FDGATE_StableBackBufferSampler
{
    Texture = FDGATE_StableBackBuffer;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = NONE;
};

uniform int FDGATE_DebugView <
    ui_type = "combo";
    ui_label = "Diagnostic View";
    ui_category = "Fine Cell - Diagnostics - Gate and Mask Debugger / 00 Debug"; ui_category_closed = true;
    ui_items = "Diagnostic Tier Shading\0Locked Screen Color\0Screen Size\0Depth\0Debugger Diagnostics\0Light Shield\0Exclusion Zone\0Local Contrast\0";
    ui_tooltip = "Selects the diagnostic output for the stable first gate.";
> = 1;

uniform int FDGATE_ShadingTier <
    ui_type = "combo";
    ui_label = "Diagnostic Shading Stage";
    ui_category = "Fine Cell - Diagnostics - Gate and Mask Debugger / 00 Debug"; ui_category_closed = true;
    ui_items = "Near (bio Hatch)\0Forward (Hatch Blend)\0Center (Bridge)\0Back (Cell Blend)\0Far (Cell Shader)\0Final (Combined All Tiers)\0";
    ui_tooltip = "Controls six-stage diagnostic shading outside the exclusion zone, with Final blending near+forward+center+back+far.";
> = 0;

uniform float FDGATE_LocalGateSensitivity <
    ui_type = "slider";
    ui_label = "Local Gate Sensitivity";
    ui_category = "Fine Cell - Diagnostics - Gate and Mask Debugger / 00 Debug"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 4.0; ui_step = 0.001;
    ui_tooltip = "Single sensitivity control shared by fog, light, and the combined exclusion zone.";
> = 1.500000;

uniform float FDGATE_ExclusionStrength <
    ui_type = "slider";
    ui_label = "Exclusion Strength";
    ui_category = "Fine Cell - Diagnostics - Gate and Mask Debugger / 00 Debug"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.25; ui_step = 0.001;
    ui_tooltip = "How strongly the exclusion zone preserves the locked source image.";
> = 1.000000;

uniform float FDGATE_DepthStart <
    ui_type = "slider";
    ui_label = "Depth Start";
    ui_category = "Fine Cell - Diagnostics - Gate and Mask Debugger / 00 Debug"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Near edge of the diagnostic depth window.";
> = 0.000000;

uniform float FDGATE_DepthEnd <
    ui_type = "slider";
    ui_label = "Depth End";
    ui_category = "Fine Cell - Diagnostics - Gate and Mask Debugger / 00 Debug"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.25; ui_step = 0.001;
    ui_tooltip = "Far edge of the diagnostic depth window.";
> = 1.000000;

uniform int FDGATE_InvertDepth <
    ui_type = "combo";
    ui_label = "Invert Depth";
    ui_category = "Fine Cell - Diagnostics - Gate and Mask Debugger / 00 Debug"; ui_category_closed = true;
    ui_items = "No\0Yes\0";
    ui_tooltip = "Inverts depth interpretation for reversed depth buffers.";
> = 0;

uniform float FDGATE_FogBrightnessFloor <
    ui_type = "slider";
    ui_label = "Fog Brightness Floor";
    ui_category = "Fine Cell - Diagnostics - Gate and Mask Debugger / 00 Debug"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 0.25; ui_step = 0.0001;
    ui_tooltip = "Minimum brightness needed before fog can enter the exclusion zone.";
> = 0.004000;

uniform float FDGATE_FogDesaturation <
    ui_type = "slider";
    ui_label = "Fog Desaturation";
    ui_category = "Fine Cell - Diagnostics - Gate and Mask Debugger / 00 Debug"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "How desaturated the locked source must be before fog is detected.";
> = 0.180000;

uniform float FDGATE_FogLowContrast <
    ui_type = "slider";
    ui_label = "Fog Low Contrast";
    ui_category = "Fine Cell - Diagnostics - Gate and Mask Debugger / 00 Debug"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 0.25; ui_step = 0.0001;
    ui_tooltip = "Local contrast below this value contributes to fog exclusion.";
> = 0.080000;

uniform float FDGATE_LightThreshold <
    ui_type = "slider";
    ui_label = "Light Threshold";
    ui_category = "Fine Cell - Diagnostics - Gate and Mask Debugger / 00 Debug"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.001;
    ui_tooltip = "Brightness threshold for light exclusion.";
> = 0.680000;

uniform float FDGATE_LightSoftness <
    ui_type = "slider";
    ui_label = "Light Softness";
    ui_category = "Fine Cell - Diagnostics - Gate and Mask Debugger / 00 Debug"; ui_category_closed = true;
    ui_min = 0.001; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Soft transition width for light exclusion.";
> = 0.180000;

uniform float FDGATE_ShadeStrength <
    ui_type = "slider";
    ui_label = "Shade Strength";
    ui_category = "Fine Cell - Diagnostics - Gate and Mask Debugger / 00 Debug"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
    ui_tooltip = "Strength of six-stage diagnostic shading outside the exclusion zone.";
> = 0.180000;

uniform float FDGATE_DebugExposure <
    ui_type = "slider";
    ui_label = "Debug Exposure";
    ui_category = "Fine Cell - Diagnostics - Gate and Mask Debugger / 00 Debug"; ui_category_closed = true;
    ui_min = 1.0; ui_max = 32.0; ui_step = 0.1;
    ui_tooltip = "Boosts scalar diagnostic visibility.";
> = 4.000000;

float2 FDGATE_Pixel()
{
    return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
}

float3 FDGATE_Source(float2 uv)
{
    return tex2D(FDGATE_StableBackBufferSampler, saturate(uv)).rgb;
}

float3 FDGATE_TrueSource(float2 uv)
{
    return tex2D(FDGATE_TrueScreenColorSampler, saturate(uv)).rgb;
}

float FDGATE_RawDepth(float2 uv)
{
    return tex2D(ReShade::DepthBuffer, saturate(uv)).r;
}

float FDGATE_Depth(float2 uv)
{
    float depth = saturate(ReShade::GetLinearizedDepth(saturate(uv)));
    return (FDGATE_InvertDepth != 0) ? (1.0 - depth) : depth;
}

float FDGATE_Luma(float3 color)
{
    return dot(color, float3(0.2126, 0.7152, 0.0722));
}

float FDGATE_Saturation(float3 color)
{
    float peak = max(color.r, max(color.g, color.b));
    float trough = min(color.r, min(color.g, color.b));
    return saturate((peak - trough) / max(0.000010, peak));
}

float FDGATE_DebugScalar(float value)
{
    return pow(saturate(value * max(1.0, FDGATE_DebugExposure)), 0.65);
}

float4 FDGATE_CopyBackBufferPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    return tex2D(FDGATE_TrueScreenColorSampler, saturate(uv));
}

float FDGATE_LocalContrast(float2 uv)
{
    float2 px = FDGATE_Pixel() * (1.0 + FDGATE_LocalGateSensitivity * 2.0);
    float center = FDGATE_Luma(FDGATE_Source(uv));
    float right = FDGATE_Luma(FDGATE_Source(uv + float2(px.x, 0.0)));
    float left = FDGATE_Luma(FDGATE_Source(uv - float2(px.x, 0.0)));
    float up = FDGATE_Luma(FDGATE_Source(uv + float2(0.0, px.y)));
    float down = FDGATE_Luma(FDGATE_Source(uv - float2(0.0, px.y)));
    return (abs(center - right) + abs(center - left) + abs(center - up) + abs(center - down)) * 0.25;
}

float FDGATE_DepthWindow(float depth)
{
    float d0 = min(FDGATE_DepthStart, FDGATE_DepthEnd);
    float d1 = max(FDGATE_DepthStart, FDGATE_DepthEnd);
    float soft = 0.004 + 0.006 * saturate(FDGATE_LocalGateSensitivity);
    float beginMask = smoothstep(d0 - soft, d0 + soft, depth);
    float endMask = 1.0 - smoothstep(d1 - soft, d1 + soft, depth);
    return saturate(beginMask * endMask);
}

float FDGATE_FogMask(float2 uv, float3 sourceColor, float depth)
{
    float luma = FDGATE_Luma(sourceColor);
    float desaturation = 1.0 - FDGATE_Saturation(sourceColor);
    float contrast = FDGATE_LocalContrast(uv);
    float sensitivity = max(0.0001, FDGATE_LocalGateSensitivity);
    float soft = 0.010 + 0.030 / sensitivity;
    float brightMask = smoothstep(FDGATE_FogBrightnessFloor, FDGATE_FogBrightnessFloor + soft, luma);
    float desatMask = smoothstep(FDGATE_FogDesaturation - soft, FDGATE_FogDesaturation + soft, desaturation);
    float lowContrastMask = 1.0 - smoothstep(FDGATE_FogLowContrast, FDGATE_FogLowContrast + soft, contrast);
    return saturate(brightMask * desatMask * lowContrastMask * FDGATE_DepthWindow(depth) * sensitivity);
}

float FDGATE_LightMask(float3 sourceColor)
{
    float sensitivity = max(0.0001, FDGATE_LocalGateSensitivity);
    float softness = max(0.001, FDGATE_LightSoftness / sensitivity);
    float mask = FC_LIGHT_EmissionMask(
        sourceColor,
        FDGATE_Luma(sourceColor),
        FDGATE_LightThreshold,
        softness,
        0.700000,
        0.350000,
        0.220000,
        0.000010);
    return saturate(mask * sensitivity);
}

float FDGATE_ExclusionMask(float fogMask, float lightMask)
{
    return saturate(max(fogMask, lightMask) * FDGATE_ExclusionStrength);
}

float3 FDGATE_TierShade(float2 uv, float3 sourceColor, float depth, float localContrast)
{
    float2 px = FDGATE_Pixel();
    float lR = FDGATE_Luma(FDGATE_Source(uv + float2(px.x, 0.0)));
    float lL = FDGATE_Luma(FDGATE_Source(uv - float2(px.x, 0.0)));
    float lU = FDGATE_Luma(FDGATE_Source(uv + float2(0.0, px.y)));
    float lD = FDGATE_Luma(FDGATE_Source(uv - float2(0.0, px.y)));
    float edge = saturate((abs(lR - lL) + abs(lU - lD)) * 4.0);
    float depthNear = saturate(1.0 - depth);
    float luma = FDGATE_Luma(sourceColor);

    // Near-side bio hatch response.
    float hatchWaveA = sin((uv.x + uv.y) * 860.0 + depth * 21.0);
    float hatchWaveB = sin((uv.x - uv.y) * 710.0 - depth * 17.0);
    float hatchPattern = smoothstep(0.35, 0.85, saturate(hatchWaveA * hatchWaveB * 0.5 + 0.5));
    float hatchMask = saturate(edge * 0.50 + localContrast * 3.20 + depthNear * 0.22);
    float3 hatchBase = sourceColor * (1.0 - (0.30 + 0.58 * hatchMask) * FDGATE_ShadeStrength);
    float3 hatchShade = saturate(hatchBase + float3(0.016, 0.012, 0.007) * hatchPattern * FDGATE_ShadeStrength);

    // Far-side cell response.
    float bandCount = 5.0;
    float quantLuma = floor(saturate(luma) * (bandCount - 1.0) + 0.5) / (bandCount - 1.0);
    float3 cellBase = sourceColor * (0.36 + quantLuma * 0.74);
    float inkMask = saturate(edge * 1.30 + localContrast * 2.00);
    float3 cellShadow = cellBase * (1.0 - inkMask * 0.82 * FDGATE_ShadeStrength);
    float3 cellLift = cellBase + float3(0.020, 0.015, 0.009) * quantLuma * FDGATE_ShadeStrength;
    float3 cellShade = saturate(lerp(cellShadow, cellLift, 0.22 + quantLuma * 0.28));

    float3 nearShade = hatchShade;
    float3 forwardShade = saturate(lerp(hatchShade, sourceColor, 0.20));
    float3 centerShade = saturate(lerp(hatchShade, cellShade, 0.50));
    float3 backShade = saturate(lerp(hatchShade, cellShade, 0.78));
    float3 farShade = cellShade;
    float3 finalCombinedShade = saturate((nearShade + forwardShade + centerShade + backShade + farShade) * 0.200000);

    if (FDGATE_ShadingTier <= 0) return nearShade;    // near
    if (FDGATE_ShadingTier == 1) return forwardShade; // forward
    if (FDGATE_ShadingTier == 2) return centerShade;  // center
    if (FDGATE_ShadingTier == 3) return backShade;    // back
    if (FDGATE_ShadingTier == 4) return farShade;     // far
    return finalCombinedShade;                         // final combined
}

float3 FDGATE_ScreenSizeDiagnostic(float2 uv)
{
    float widthNorm = saturate(float(BUFFER_WIDTH) / 3840.0);
    float heightNorm = saturate(float(BUFFER_HEIGHT) / 2160.0);
    float aspectNorm = saturate((float(BUFFER_WIDTH) / max(1.0, float(BUFFER_HEIGHT))) / 2.4);
    float gridX = step(frac(uv.x * 16.0), 0.035);
    float gridY = step(frac(uv.y * 9.0), 0.035);
    float grid = saturate(max(gridX, gridY) * 0.30);
    return saturate(float3(widthNorm, heightNorm, aspectNorm) + grid.xxx);
}

float4 FDGATE_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 sourceColor = FDGATE_Source(uv);
    float3 trueColor = FDGATE_TrueSource(uv);
    float depth = FDGATE_Depth(uv);
    float localContrast = FDGATE_LocalContrast(uv);
    float staticMask = saturate((1.0 - localContrast * 10.0) * FDGATE_DepthWindow(depth));
    float3 drift = sourceColor - trueColor;
    float driftLuma = abs(FDGATE_Luma(drift));
    float driftChroma = length(drift - driftLuma.xxx);
    float driftAmount = saturate((driftLuma + driftChroma) * 8.0);
    sourceColor = lerp(sourceColor, trueColor, staticMask * driftAmount);
    float fogMask = FDGATE_FogMask(uv, sourceColor, depth);
    float lightMask = FDGATE_LightMask(sourceColor);
    float exclusionMask = FDGATE_ExclusionMask(fogMask, lightMask);
    float3 tierShade = FDGATE_TierShade(uv, sourceColor, depth, localContrast);
    float3 gatedColor = lerp(tierShade, sourceColor, exclusionMask);

    if (FDGATE_DebugView == 1) return float4(sourceColor, 1.0);
    if (FDGATE_DebugView == 2) return float4(FDGATE_ScreenSizeDiagnostic(uv), 1.0);
    if (FDGATE_DebugView == 3) return float4(FDGATE_DebugScalar(depth).xxx, 1.0);
    if (FDGATE_DebugView == 4) return float4(FDGATE_DebugScalar(fogMask).xxx, 1.0);
    if (FDGATE_DebugView == 5) return float4(FDGATE_DebugScalar(lightMask).xxx, 1.0);
    if (FDGATE_DebugView == 6) return float4(saturate(float3(lightMask, fogMask, exclusionMask)), 1.0);
    if (FDGATE_DebugView == 7) return float4(FDGATE_DebugScalar(localContrast).xxx, 1.0);
    return float4(saturate(gatedColor), 1.0);
}

technique fine_dream_Debugger_Diagnostics < ui_label = "Fine Cell - Diagnostics - Gate and Mask Debugger"; ui_tooltip = "Diagnostic first gate: locked true screen color, screen dimensions, depth, Debugger Diagnostics, light shield, and unified exclusion-tier diagnostics."; >
{
    pass LockInitialBackBuffer
    {
        VertexShader = PostProcessVS;
        PixelShader = FDGATE_CopyBackBufferPS;
        RenderTarget = FDGATE_StableBackBuffer;
    }
    pass RespectLightAndShadowDiagnostics
    {
        VertexShader = PostProcessVS;
        PixelShader = FDGATE_MainPS;
    }
}







