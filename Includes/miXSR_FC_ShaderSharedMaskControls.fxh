// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
#ifndef MIXSR_SHARED_SHARED_MASK_CONTROLS_FXH
#define MIXSR_SHARED_SHARED_MASK_CONTROLS_FXH

#ifndef MIXSR_SHARED_SHARED_MASK_BUILT_IN_TECHNIQUE
#define MIXSR_SHARED_SHARED_MASK_BUILT_IN_TECHNIQUE 0
#endif

#ifndef MIXSR_UI_SHARED_CACHE_CATEGORY
#define MIXSR_UI_SHARED_CACHE_CATEGORY "Fine Cell - Shared Mask Controls / 04 Respect / Shared Cache"
#endif

#ifndef MIXSR_UI_SHARED_FOG_CATEGORY
#define MIXSR_UI_SHARED_FOG_CATEGORY "Fine Cell - Shared Mask Controls / 04 Respect / Fog"
#endif

#ifndef MIXSR_UI_SHARED_LIGHT_CATEGORY
#define MIXSR_UI_SHARED_LIGHT_CATEGORY "Fine Cell - Shared Mask Controls / 04 Respect / Light"
#endif

#ifndef MIXSR_UI_SHARED_GUARDS_CATEGORY
#define MIXSR_UI_SHARED_GUARDS_CATEGORY "Fine Cell - Shared Mask Controls / 04 Respect / Guards"
#endif

#ifndef MIXSR_UI_SHARED_CLOSED
#define MIXSR_UI_SHARED_CLOSED true
#endif

#include "miXSR_FC_FogGate.fxh"
#include "miXSR_FC_LightRespect.fxh"

texture2D MIXSR_SHARED_SharedGateTex
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

sampler2D MIXSR_SHARED_SharedGateSampler
{
    Texture = MIXSR_SHARED_SharedGateTex;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = NONE;
};

uniform int MIXSR_SHARED_SharedMaskCacheMode <
    ui_type = "combo";
 ui_label = "Shared Mask Cache Mode";
 ui_category = MIXSR_UI_SHARED_CACHE_CATEGORY; ui_category_closed = MIXSR_UI_SHARED_CLOSED;
    ui_items = "Raw Only\0Prefer Shared Cache\0Shared Cache Only\0";
 ui_tooltip = "Controls whether effects recompute masks, prefer a populated orchestrator cache, or trust the cache even where its value is zero.\nThe integrated core chain automatically trusts its built cache; use Shared Cache Only for downstream effects ordered after an external orchestrator.";
> = 1;

uniform int MIXSR_SHARED_MasterFogMaskEnable <
    ui_type = "combo";
 ui_label = "Master Fog Mask";
 ui_category = MIXSR_UI_SHARED_FOG_CATEGORY; ui_category_closed = MIXSR_UI_SHARED_CLOSED;
    ui_items = "Off\0On\0";
 ui_tooltip = "Global fog-mask authority for effects.";
> = 1;

uniform float MIXSR_SHARED_MasterFogMaskStrength <
    ui_type = "slider";
 ui_label = "Master Fog Strength";
 ui_category = MIXSR_UI_SHARED_FOG_CATEGORY; ui_category_closed = MIXSR_UI_SHARED_CLOSED;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Scales shared fog-mask bypass returned to downstream effects.";
> = 1.000000;

uniform float MIXSR_SHARED_FogEvidenceThreshold <
    ui_type = "slider";
 ui_label = "Fog Evidence Threshold";
 ui_category = MIXSR_UI_SHARED_FOG_CATEGORY; ui_category_closed = MIXSR_UI_SHARED_CLOSED;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Minimum local fog evidence before shared Respect Fog can suppress an effect.\nPrevents false suppression when the scene has no visible fog.";
> = 0.080000;

uniform float MIXSR_SHARED_FogEvidenceSoftness <
    ui_type = "slider";
 ui_label = "Fog Evidence Softness";
 ui_category = MIXSR_UI_SHARED_FOG_CATEGORY; ui_category_closed = MIXSR_UI_SHARED_CLOSED;
    ui_min = 0.001; ui_max = 0.500; ui_step = 0.001;
 ui_tooltip = "Softness of the fog-evidence transition.";
> = 0.060000;

uniform int MIXSR_SHARED_MasterLightShieldEnable <
    ui_type = "combo";
 ui_label = "Master Light Shield";
 ui_category = MIXSR_UI_SHARED_LIGHT_CATEGORY; ui_category_closed = MIXSR_UI_SHARED_CLOSED;
    ui_items = "Off\0On\0";
 ui_tooltip = "Global light-shield authority for effects.";
> = 1;

uniform float MIXSR_SHARED_MasterLightShieldStrength <
    ui_type = "slider";
 ui_label = "Master Light Strength";
 ui_category = MIXSR_UI_SHARED_LIGHT_CATEGORY; ui_category_closed = MIXSR_UI_SHARED_CLOSED;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Scales shared light-shield mask strength.";
> = 1.000000;

uniform int MIXSR_SHARED_UniversalLineGuardEnable <
    ui_type = "combo";
 ui_label = "Universal Line Guard";
 ui_category = MIXSR_UI_SHARED_GUARDS_CATEGORY; ui_category_closed = MIXSR_UI_SHARED_CLOSED;
    ui_items = "Off\0On\0";
 ui_tooltip = "Protects thin line structures from downstream alteration.";
> = 0;

uniform float MIXSR_SHARED_UniversalLineGuardThreshold <
    ui_type = "slider";
 ui_label = "Line Guard Threshold";
 ui_category = MIXSR_UI_SHARED_GUARDS_CATEGORY; ui_category_closed = MIXSR_UI_SHARED_CLOSED;
    ui_min = 0.001; ui_max = 0.250; ui_step = 0.001;
 ui_tooltip = "Gradient threshold where line protection starts.";
> = 0.018000;

uniform float MIXSR_SHARED_UniversalLineGuardStrength <
    ui_type = "slider";
 ui_label = "Line Guard Strength";
 ui_category = MIXSR_UI_SHARED_GUARDS_CATEGORY; ui_category_closed = MIXSR_UI_SHARED_CLOSED;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "How strongly line structures are preserved.";
> = 0.850000;

uniform int MIXSR_SHARED_UniversalPixelGuardEnable <
    ui_type = "combo";
 ui_label = "Universal Pixel Guard";
 ui_category = MIXSR_UI_SHARED_GUARDS_CATEGORY; ui_category_closed = MIXSR_UI_SHARED_CLOSED;
    ui_items = "Off\0On\0";
 ui_tooltip = "Protects hot or saturated micro pixels from downstream alteration.";
> = 0;

uniform float MIXSR_SHARED_UniversalPixelGuardThreshold <
    ui_type = "slider";
 ui_label = "Pixel Guard Threshold";
 ui_category = MIXSR_UI_SHARED_GUARDS_CATEGORY; ui_category_closed = MIXSR_UI_SHARED_CLOSED;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Brightness threshold where pixel guard starts.";
> = 0.700000;

uniform float MIXSR_SHARED_UniversalPixelGuardSaturation <
    ui_type = "slider";
 ui_label = "Pixel Guard Saturation";
 ui_category = MIXSR_UI_SHARED_GUARDS_CATEGORY; ui_category_closed = MIXSR_UI_SHARED_CLOSED;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "Saturation threshold for colored hot-pixel protection.";
> = 0.250000;

uniform float MIXSR_SHARED_UniversalPixelGuardStrength <
    ui_type = "slider";
 ui_label = "Pixel Guard Strength";
 ui_category = MIXSR_UI_SHARED_GUARDS_CATEGORY; ui_category_closed = MIXSR_UI_SHARED_CLOSED;
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
 ui_tooltip = "How strongly hot or saturated pixels are preserved.";
> = 0.900000;

float MIXSR_SHARED_Luma(float3 c)
{
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

float MIXSR_SHARED_Saturation(float3 c)
{
    float peak = max(c.r, max(c.g, c.b));
    float trough = min(c.r, min(c.g, c.b));
    return saturate((peak - trough) / max(0.000010, peak));
}

float MIXSR_SHARED_RawLineGuardMask(float3 sourceColor)
{
    float luma = MIXSR_SHARED_Luma(sourceColor);
    float grad = abs(ddx(luma)) + abs(ddy(luma));
    return smoothstep(MIXSR_SHARED_UniversalLineGuardThreshold, MIXSR_SHARED_UniversalLineGuardThreshold * 3.0, grad);
}

float MIXSR_SHARED_RawPixelGuardMask(float3 sourceColor)
{
    float luma = MIXSR_SHARED_Luma(sourceColor);
    float sat = MIXSR_SHARED_Saturation(sourceColor);
    float brightMask = smoothstep(MIXSR_SHARED_UniversalPixelGuardThreshold, 1.0, luma);
    float satMask = smoothstep(MIXSR_SHARED_UniversalPixelGuardSaturation, 1.0, sat);
    return saturate(max(brightMask, satMask));
}

float MIXSR_SHARED_RawFogMask(float2 uv, float3 sourceColor, int respectFogToggle)
{
    if (respectFogToggle == 0)
        return 0.0;

    return saturate(FC_FOG_BypassMask(uv, sourceColor, 1));
}

float MIXSR_SHARED_RawLightMask(
    float3 color,
    float luma,
    float threshold,
    float softness,
    float peakInfluence,
    float saturationInfluence,
    float saturationThreshold,
    float numericFloor)
{
    return FC_LIGHT_EmissionMask(
        color,
        luma,
        threshold,
        softness,
        peakInfluence,
        saturationInfluence,
        saturationThreshold,
        numericFloor);
}

float4 MIXSR_SHARED_SampleSharedGate(float2 uv)
{
    return tex2D(MIXSR_SHARED_SharedGateSampler, saturate(uv));
}

float MIXSR_SHARED_HasSharedGateCache(float2 uv)
{
    float4 gate = MIXSR_SHARED_SampleSharedGate(uv);
    return step(0.0005, max(max(gate.r, gate.g), max(gate.b, gate.a)));
}

float MIXSR_SHARED_UseSharedGateCache(float2 uv)
{
    if (MIXSR_SHARED_SharedMaskCacheMode == 0)
        return 0.0;

    if (MIXSR_SHARED_SHARED_MASK_BUILT_IN_TECHNIQUE != 0 || MIXSR_SHARED_SharedMaskCacheMode == 2)
        return 1.0;

    // Stabilize runtime cost: in "Prefer Shared Cache" mode, avoid per-pixel
    // cache-presence branching that can cause scene-dependent workload spikes.
    return 1.0;
}

float MIXSR_SHARED_SampleSharedFogMask(float2 uv)
{
    if (MIXSR_SHARED_MasterFogMaskEnable == 0)
        return 0.0;

    return saturate(MIXSR_SHARED_SampleSharedGate(uv).r * MIXSR_SHARED_MasterFogMaskStrength);
}

float MIXSR_SHARED_SampleSharedLightMask(float2 uv)
{
    if (MIXSR_SHARED_MasterLightShieldEnable == 0)
        return 0.0;

    return saturate(MIXSR_SHARED_SampleSharedGate(uv).g * MIXSR_SHARED_MasterLightShieldStrength);
}

float MIXSR_SHARED_SampleSharedLineGuard(float2 uv)
{
    if (MIXSR_SHARED_UniversalLineGuardEnable == 0)
        return 0.0;

    return saturate(MIXSR_SHARED_SampleSharedGate(uv).b * MIXSR_SHARED_UniversalLineGuardStrength);
}

float MIXSR_SHARED_SampleSharedPixelGuard(float2 uv)
{
    if (MIXSR_SHARED_UniversalPixelGuardEnable == 0)
        return 0.0;

    return saturate(MIXSR_SHARED_SampleSharedGate(uv).a * MIXSR_SHARED_UniversalPixelGuardStrength);
}

float MIXSR_SHARED_SharedFogBypass(float2 uv, float3 sourceColor, int respectFogToggle)
{
    if (respectFogToggle == 0 || MIXSR_SHARED_MasterFogMaskEnable == 0)
        return 0.0;

    float sharedBypass = 0.0;
    if (MIXSR_SHARED_UseSharedGateCache(uv) > 0.0)
        sharedBypass = MIXSR_SHARED_SampleSharedFogMask(uv);
    else
        sharedBypass = saturate(MIXSR_SHARED_RawFogMask(uv, sourceColor, 1) * MIXSR_SHARED_MasterFogMaskStrength);

    float fogEvidenceCore = FC_FOG_Core(uv, sourceColor);
    float fogEvidenceMask = smoothstep(
        MIXSR_SHARED_FogEvidenceThreshold,
        MIXSR_SHARED_FogEvidenceThreshold + max(0.000010, MIXSR_SHARED_FogEvidenceSoftness),
        fogEvidenceCore);

    return saturate(sharedBypass * fogEvidenceMask);
}

float MIXSR_SHARED_SharedLightMask(
    float2 uv,
    float3 color,
    float luma,
    float threshold,
    float softness,
    float peakInfluence,
    float saturationInfluence,
    float saturationThreshold,
    float numericFloor)
{
    if (MIXSR_SHARED_MasterLightShieldEnable == 0)
        return 0.0;

    if (MIXSR_SHARED_UseSharedGateCache(uv) > 0.0)
        return MIXSR_SHARED_SampleSharedLightMask(uv);

    float mask = MIXSR_SHARED_RawLightMask(
        color,
        luma,
        threshold,
        softness,
        peakInfluence,
        saturationInfluence,
        saturationThreshold,
        numericFloor);
    return saturate(mask * MIXSR_SHARED_MasterLightShieldStrength);
}

float MIXSR_SHARED_SharedLightMask(
    float3 color,
    float luma,
    float threshold,
    float softness,
    float peakInfluence,
    float saturationInfluence,
    float saturationThreshold,
    float numericFloor)
{
    if (MIXSR_SHARED_MasterLightShieldEnable == 0)
        return 0.0;

    float mask = MIXSR_SHARED_RawLightMask(
        color,
        luma,
        threshold,
        softness,
        peakInfluence,
        saturationInfluence,
        saturationThreshold,
        numericFloor);
    return saturate(mask * MIXSR_SHARED_MasterLightShieldStrength);
}

float3 MIXSR_SHARED_ProtectColor(float2 uv, float3 processedColor, float3 sourceColor, float preserveMask, float preserveStrength)
{
    float3 lightProtected = FC_LIGHT_ProtectColor(processedColor, sourceColor, preserveMask, preserveStrength);

    float useCache = MIXSR_SHARED_UseSharedGateCache(uv);
    float lineGuard = 0.0;
    float pixelGuard = 0.0;

    if (useCache > 0.0)
    {
        lineGuard = MIXSR_SHARED_SampleSharedLineGuard(uv);
        pixelGuard = MIXSR_SHARED_SampleSharedPixelGuard(uv);
    }
    else
    {
        lineGuard = saturate(MIXSR_SHARED_RawLineGuardMask(sourceColor) * MIXSR_SHARED_UniversalLineGuardStrength * MIXSR_SHARED_UniversalLineGuardEnable);
        pixelGuard = saturate(MIXSR_SHARED_RawPixelGuardMask(sourceColor) * MIXSR_SHARED_UniversalPixelGuardStrength * MIXSR_SHARED_UniversalPixelGuardEnable);
    }
    float guardMask = saturate(max(lineGuard, pixelGuard));
    return lerp(lightProtected, sourceColor, guardMask);
}

float3 MIXSR_SHARED_ProtectColor(float3 processedColor, float3 sourceColor, float preserveMask, float preserveStrength)
{
    float3 lightProtected = FC_LIGHT_ProtectColor(processedColor, sourceColor, preserveMask, preserveStrength);
    float lineGuard = saturate(MIXSR_SHARED_RawLineGuardMask(sourceColor) * MIXSR_SHARED_UniversalLineGuardStrength * MIXSR_SHARED_UniversalLineGuardEnable);
    float pixelGuard = saturate(MIXSR_SHARED_RawPixelGuardMask(sourceColor) * MIXSR_SHARED_UniversalPixelGuardStrength * MIXSR_SHARED_UniversalPixelGuardEnable);
    float guardMask = saturate(max(lineGuard, pixelGuard));
    return lerp(lightProtected, sourceColor, guardMask);
}

float MIXSR_SHARED_LegacyComputedMask(float2 uv)
{
    float fog = MIXSR_SHARED_SampleSharedFogMask(uv);
    float light = MIXSR_SHARED_SampleSharedLightMask(uv);
    float line = MIXSR_SHARED_SampleSharedLineGuard(uv);
    float pixel = MIXSR_SHARED_SampleSharedPixelGuard(uv);
    return saturate(max(max(fog, light), max(line, pixel)));
}

// Compatibility helpers for dependent effects that still call the shared hatch/lens accessors.
// These helpers now resolve to the current shared mask implementation.
float MIXSR_SHARED_DebugHatchLensPattern(float2 uv)
{
    return MIXSR_SHARED_LegacyComputedMask(uv);
}

float Mixsr_Shared_debughactchlenspattern(float2 uv)
{
    return MIXSR_SHARED_LegacyComputedMask(uv);
}

#endif



