// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: miXSR_FC_shared_mask_orchestrator-1
// Capability: [ > first < ] orchestrator and cache for true screen color, depth, fog mask, light shield, and unified protection diagnostics.



#include "ReShade.fxh"
#include "miXSR_FC_ShaderSharedMaskControls.fxh"

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

texture2D FDGATE_PreviousFrameColor
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

sampler2D FDGATE_PreviousFrameColorSampler
{
    Texture = FDGATE_PreviousFrameColor;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = NONE;
};

texture2D FDGATE_SharedGateHistory
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

sampler2D FDGATE_SharedGateHistorySampler
{
    Texture = FDGATE_SharedGateHistory;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = NONE;
};

texture2D FDGATE_MaskReuseDecision
{
    Width = 1;
    Height = 1;
    Format = RGBA8;
};

sampler2D FDGATE_MaskReuseDecisionSampler
{
    Texture = FDGATE_MaskReuseDecision;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    MipFilter = NONE;
};

uniform int FDGATE_DebugView <
    ui_type = "combo";
 ui_label = "Diagnostic View";
 ui_category = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics / 03 Sub Settings"; ui_category_closed = true;
    ui_items = "Diagnostic Tier Shading\0Locked Screen Color\0Screen Size\0Depth\0Fog Mask\0Light Shield\0Line Guard\0Pixel Guard\0Exclusion Zone\0Local Contrast\0Computed Mask\0Mask Reuse Decision\0Mask Stage 1 Stable\0Mask Stage 2 Structured\0Mask Stage 3 GUI Candidate\0Mask Stage 4 Noise Candidate\0";
 ui_tooltip = "Selects diagnostic output for orchestrator/cache.\nAdded staged gui/noise masks: Stable -> Structured -> GUI -> Noise.";
> = 1;

uniform int FDGATE_ShadingTier <
    ui_type = "combo";
 ui_label = "Diagnostic Shading Stage";
 ui_category = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics / 03 Sub Settings"; ui_category_closed = true;
    ui_items = "Near (bio Hatch)\0Forward (Hatch Blend)\0Center (Bridge)\0Back (Cell Blend)\0Far (Cell Shader)\0Final (Combined All Tiers)\0";
 ui_tooltip = "Controls six-stage diagnostic shading outside the exclusion zone, with Final blending near+forward+center+back+far.";
> = 5;

uniform float FDGATE_LocalGateSensitivity <
    ui_type = "slider";
 ui_label = "Local Mask Sensitivity";
 ui_category = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 4.0; ui_step = 0.001;
 ui_tooltip = "Single sensitivity control shared by fog, light, and the combined exclusion zone.";
> = 1.000000;

uniform float FDGATE_ExclusionStrength <
    ui_type = "slider";
 ui_label = "Exclusion Strength";
 ui_category = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.25; ui_step = 0.001;
 ui_tooltip = "How strongly the exclusion zone preserves the locked source image.";
> = 1.000000;

uniform float FDGATE_DepthStart <
    ui_type = "slider";
 ui_label = "Depth Start";
 ui_category = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Near edge of the diagnostic depth window.";
> = 0.000000;

uniform float FDGATE_DepthEnd <
    ui_type = "slider";
 ui_label = "Depth End";
 ui_category = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.25; ui_step = 0.001;
 ui_tooltip = "Far edge of the diagnostic depth window.";
> = 1.000000;

uniform int FDGATE_InvertDepth <
    ui_type = "combo";
 ui_label = "Invert Depth";
 ui_category = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics / 03 Sub Settings"; ui_category_closed = true;
    ui_items = "No\0Yes\0";
 ui_tooltip = "Inverts depth interpretation for reversed depth buffers.";
> = 0;

uniform float FDGATE_FogBrightnessFloor <
    ui_type = "slider";
 ui_label = "Fog Brightness Floor";
 ui_category = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 0.25; ui_step = 0.0001;
 ui_tooltip = "Minimum brightness needed before fog can enter the exclusion zone.";
> = 0.004000;

uniform float FDGATE_FogDesaturation <
    ui_type = "slider";
 ui_label = "Fog Desaturation";
 ui_category = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "How desaturated the locked source must be before fog is detected.";
> = 0.180000;

uniform float FDGATE_FogLowContrast <
    ui_type = "slider";
 ui_label = "Fog Low Contrast";
 ui_category = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.0001;
 ui_tooltip = "Local contrast below this value contributes to fog exclusion.";
> = 0.040000;

uniform float FDGATE_LightThreshold <
    ui_type = "slider";
 ui_label = "Light Threshold";
 ui_category = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.001;
 ui_tooltip = "Brightness threshold for light exclusion.";
> = 0.680000;

uniform float FDGATE_LightSoftness <
    ui_type = "slider";
 ui_label = "Light Softness";
 ui_category = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics / 01 Guards (Respect Fog/Light)"; ui_category_closed = true;
    ui_min = 0.001; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Soft transition width for light exclusion.";
> = 0.180000;

uniform float FDGATE_ShadeStrength <
    ui_type = "slider";
 ui_label = "Shade Strength";
 ui_category = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Strength of six-stage diagnostic shading outside the exclusion zone.";
> = 0.180000;

uniform float FDGATE_DebugExposure <
    ui_type = "slider";
 ui_label = "Debug Exposure";
 ui_category = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 1.0; ui_max = 32.0; ui_step = 0.1;
 ui_tooltip = "Boosts scalar diagnostic visibility.";
> = 4.000000;

uniform int FDGATE_MaskReuseEnable <
    ui_type = "combo";
 ui_label = "Mask Reuse";
 ui_category = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics / 02 Main Settings";
    ui_items = "Off\0On\0";
 ui_tooltip = "When On, quickly tests frame stability and reuses previous shared mask where unchanged.";
> = 1;

uniform float FDGATE_MaskReuseColorDelta <
    ui_type = "slider";
 ui_label = "Reuse Color Delta";
 ui_category = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.00001; ui_max = 0.05000; ui_step = 0.00001;
 ui_tooltip = "Color-delta threshold below which prior mask is reused.";
> = 0.003500;

uniform float FDGATE_MaskReuseSoftness <
    ui_type = "slider";
 ui_label = "Reuse Softness";
 ui_category = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics / 03 Sub Settings"; ui_category_closed = true;
    ui_min = 0.00001; ui_max = 0.05000; ui_step = 0.00001;
 ui_tooltip = "Soft transition around reuse threshold.";
> = 0.001500;

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

float4 FDGATE_CopyPreviousFrameColorPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    return tex2D(FDGATE_StableBackBufferSampler, saturate(uv));
}

float4 FDGATE_CopySharedGateHistoryPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    return MIXSR_SHARED_SampleSharedGate(saturate(uv));
}

float FDGATE_ColorDeltaAt(float2 uv)
{
    float3 curr = tex2D(FDGATE_StableBackBufferSampler, saturate(uv)).rgb;
    float3 prev = tex2D(FDGATE_PreviousFrameColorSampler, saturate(uv)).rgb;
    float lumaDelta = abs(FDGATE_Luma(curr) - FDGATE_Luma(prev));
    float chromaDelta = length(curr - prev) * 0.25;
    return lumaDelta + chromaDelta;
}

float4 FDGATE_BuildMaskReuseDecisionPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float reuseThreshold = max(0.00001, FDGATE_MaskReuseColorDelta);
    float reuseSoftness = max(0.00001, FDGATE_MaskReuseSoftness);

    float d0 = FDGATE_ColorDeltaAt(float2(0.50, 0.50));
    float d1 = FDGATE_ColorDeltaAt(float2(0.25, 0.25));
    float d2 = FDGATE_ColorDeltaAt(float2(0.75, 0.25));
    float d3 = FDGATE_ColorDeltaAt(float2(0.25, 0.75));
    float d4 = FDGATE_ColorDeltaAt(float2(0.75, 0.75));
    float maxDelta = max(max(d0, d1), max(max(d2, d3), d4));
    float stableMask = 1.0 - smoothstep(reuseThreshold, reuseThreshold + reuseSoftness, maxDelta);

    float4 prevGateCenter = tex2D(FDGATE_SharedGateHistorySampler, float2(0.50, 0.50));
    float prevGateEnergy = max(max(prevGateCenter.r, prevGateCenter.g), max(prevGateCenter.b, prevGateCenter.a));
    float hasPrevGate = step(0.0005, prevGateEnergy);

    float allowReuse = (FDGATE_MaskReuseEnable != 0) ? (stableMask * hasPrevGate) : 0.0;
    return float4(allowReuse, maxDelta, hasPrevGate, 1.0);
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

float FDGATE_RawFogMask(float2 uv, float3 sourceColor, float depth)
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

float FDGATE_RawLightMask(float3 sourceColor)
{
    float sensitivity = max(0.0001, FDGATE_LocalGateSensitivity);
    float softness = max(0.001, FDGATE_LightSoftness / sensitivity);
    float mask = MIXSR_SHARED_RawLightMask(
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

float FDGATE_ExclusionMask(float fogMask, float lightMask, float lineGuard, float pixelGuard)
{
    float structureMask = max(max(fogMask, lightMask), max(lineGuard, pixelGuard));
    return saturate(structureMask * FDGATE_ExclusionStrength);
}

void FDGATE_TextGuiNoiseSeries(
    float2 uv,
    float3 sourceColor,
    float localContrast,
    float lineGuard,
    float pixelGuard,
    out float stageStable,
    out float stageStructured,
    out float stageGuiCandidate,
    out float stageNoiseCandidate)
{
    float3 prevColor = tex2D(FDGATE_PreviousFrameColorSampler, saturate(uv)).rgb;
    float colorDelta = abs(FDGATE_Luma(sourceColor) - FDGATE_Luma(prevColor)) + length(sourceColor - prevColor) * 0.25;
    float stableThreshold = max(0.00001, FDGATE_MaskReuseColorDelta);
    float stableSoftness = max(0.00001, FDGATE_MaskReuseSoftness);
    stageStable = 1.0 - smoothstep(stableThreshold, stableThreshold + stableSoftness * 2.0, colorDelta);

    float structureCore = lineGuard;
    float noisePenalty = saturate(pixelGuard * 0.65);
    stageStructured = saturate(structureCore * stageStable * (1.0 - noisePenalty * 0.35));

    float contrastGui = 1.0 - smoothstep(0.035, 0.220, localContrast);

    float guiCore = stageStructured * contrastGui * (1.0 - pixelGuard * 0.20);
    stageGuiCandidate = saturate(guiCore);

    float classified = stageGuiCandidate;
    float residual = saturate(1.0 - classified);
    float instabilityNoise = (1.0 - stageStable) * (0.40 + 0.60 * pixelGuard);
    float sparkleNoise = pixelGuard * (1.0 - structureCore);
    stageNoiseCandidate = saturate(max(instabilityNoise, residual * (0.35 + 0.65 * sparkleNoise)));
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

float4 FDGATE_BuildSharedGatePS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 sourceColor = FDGATE_Source(uv);
    float depth = FDGATE_Depth(uv);

    float allowReuse = tex2D(FDGATE_MaskReuseDecisionSampler, float2(0.50, 0.50)).r;
    if (allowReuse > 0.5)
        return tex2D(FDGATE_SharedGateHistorySampler, saturate(uv));

    float rawFog = FDGATE_RawFogMask(uv, sourceColor, depth);
    float rawLight = FDGATE_RawLightMask(sourceColor);
    float rawLine = MIXSR_SHARED_RawLineGuardMask(sourceColor);
    float rawPixel = MIXSR_SHARED_RawPixelGuardMask(sourceColor);
    return float4(rawFog, rawLight, rawLine, rawPixel);
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
    float fogMask = MIXSR_SHARED_SampleSharedFogMask(uv);
    float lightMask = MIXSR_SHARED_SampleSharedLightMask(uv);
    float lineGuard = MIXSR_SHARED_SampleSharedLineGuard(uv);
    float pixelGuard = MIXSR_SHARED_SampleSharedPixelGuard(uv);
    float stageStable = 0.0;
    float stageStructured = 0.0;
    float stageGuiCandidate = 0.0;
    float stageNoiseCandidate = 0.0;
    FDGATE_TextGuiNoiseSeries(
        uv,
        sourceColor,
        localContrast,
        lineGuard,
        pixelGuard,
        stageStable,
        stageStructured,
        stageGuiCandidate,
        stageNoiseCandidate);
    float exclusionMask = FDGATE_ExclusionMask(fogMask, lightMask, lineGuard, pixelGuard);
    float3 tierShade = FDGATE_TierShade(uv, sourceColor, depth, localContrast);
    float3 gatedColor = lerp(tierShade, sourceColor, exclusionMask);

    if (FDGATE_DebugView == 1) return float4(sourceColor, 1.0);
    if (FDGATE_DebugView == 2) return float4(FDGATE_ScreenSizeDiagnostic(uv), 1.0);
    if (FDGATE_DebugView == 3) return float4(FDGATE_DebugScalar(depth).xxx, 1.0);
    if (FDGATE_DebugView == 4) return float4(FDGATE_DebugScalar(fogMask).xxx, 1.0);
    if (FDGATE_DebugView == 5) return float4(FDGATE_DebugScalar(lightMask).xxx, 1.0);
    if (FDGATE_DebugView == 6) return float4(FDGATE_DebugScalar(lineGuard).xxx, 1.0);
    if (FDGATE_DebugView == 7) return float4(FDGATE_DebugScalar(pixelGuard).xxx, 1.0);
    if (FDGATE_DebugView == 8) return float4(saturate(float3(lightMask, fogMask, exclusionMask)), 1.0);
    if (FDGATE_DebugView == 9) return float4(FDGATE_DebugScalar(localContrast).xxx, 1.0);
    if (FDGATE_DebugView == 10) return float4(FDGATE_DebugScalar(exclusionMask).xxx, 1.0);
    if (FDGATE_DebugView == 11)
    {
        float4 reuseData = tex2D(FDGATE_MaskReuseDecisionSampler, float2(0.50, 0.50));
        float reuseFlag = step(0.5, reuseData.r);
        float deltaViz = FDGATE_DebugScalar(reuseData.g * 8.0);
        return float4(reuseFlag, deltaViz, reuseData.b, 1.0);
    }
    if (FDGATE_DebugView == 12) return float4(FDGATE_DebugScalar(stageStable).xxx, 1.0);
    if (FDGATE_DebugView == 13) return float4(FDGATE_DebugScalar(stageStructured).xxx, 1.0);
    if (FDGATE_DebugView == 14) return float4(FDGATE_DebugScalar(stageGuiCandidate).xxx, 1.0);
    if (FDGATE_DebugView == 15) return float4(FDGATE_DebugScalar(stageNoiseCandidate).xxx, 1.0);
    return float4(saturate(gatedColor), 1.0);
}

technique miXSR_FC_shared_mask_orchestrator < ui_label = "Fine Cell - Shared Mask Orchestrator - Cached Protection Diagnostics"; ui_tooltip = "[ > first < ] Orchestrator and Cache: locked true screen color, screen dimensions, depth, fog mask, light shield, and unified exclusion-tier diagnostics."; >
{
    pass SnapshotPreviousFrameColor
    {
        VertexShader = PostProcessVS;
        PixelShader = FDGATE_CopyPreviousFrameColorPS;
        RenderTarget = FDGATE_PreviousFrameColor;
    }
    pass SnapshotSharedGateHistory
    {
        VertexShader = PostProcessVS;
        PixelShader = FDGATE_CopySharedGateHistoryPS;
        RenderTarget = FDGATE_SharedGateHistory;
    }
    pass LockInitialBackBuffer
    {
        VertexShader = PostProcessVS;
        PixelShader = FDGATE_CopyBackBufferPS;
        RenderTarget = FDGATE_StableBackBuffer;
    }
    pass BuildMaskReuseDecision
    {
        VertexShader = PostProcessVS;
        PixelShader = FDGATE_BuildMaskReuseDecisionPS;
        RenderTarget = FDGATE_MaskReuseDecision;
    }
    pass BuildSharedGateCache
    {
        VertexShader = PostProcessVS;
        PixelShader = FDGATE_BuildSharedGatePS;
        RenderTarget = MIXSR_SHARED_SharedGateTex;
    }
    pass RespectLightAndShadowDiagnostics
    {
        VertexShader = PostProcessVS;
        PixelShader = FDGATE_MainPS;
    }
}


















