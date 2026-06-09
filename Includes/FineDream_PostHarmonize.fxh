// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
#ifndef FINE_DREAM_POST_HARMONIZE_FXH
#define FINE_DREAM_POST_HARMONIZE_FXH

float FDPOST_Luma(float3 color)
{
    return dot(color, float3(0.2126, 0.7152, 0.0722));
}

float3 FDPOST_ArtifactCleanup(float3 color, float strength)
{
    float s = saturate(strength);
    float luma = FDPOST_Luma(color);
    float3 chroma = color - luma.xxx;
    float3 cleaned = luma.xxx + chroma / (1.0 + abs(chroma) * (2.0 + s * 6.0));
    return lerp(color, cleaned, s);
}

float3 FDPOST_ToneBalance(float3 color, float strength)
{
    float s = saturate(strength);
    float luma = FDPOST_Luma(color);
    float pivot = 0.5;
    float shapedLuma = saturate(luma + (luma - pivot) * (0.35 * s));
    float scale = shapedLuma / max(0.000010, luma);
    return saturate(color * scale);
}

float3 FDPOST_SaturationGuard(float3 color, float strength)
{
    float s = saturate(strength);
    float peak = max(color.r, max(color.g, color.b));
    float trough = min(color.r, min(color.g, color.b));
    float sat = (peak - trough) / max(0.000010, peak);
    float keep = 1.0 / (1.0 + sat * sat * (1.5 + s * 4.0));
    float3 lumaColor = FDPOST_Luma(color).xxx;
    return lerp(color, lumaColor + (color - lumaColor) * keep, s);
}

float3 FDPOST_ClipGuard(float3 color, float strength)
{
    float s = saturate(strength);
    float3 c = saturate(color);
    float3 shadowLift = c + (1.0 - c) * (0.03 * s);
    float3 highlightCompression = 1.0 - ((1.0 - shadowLift) / (1.0 + shadowLift * (1.5 * s)));
    return saturate(lerp(c, highlightCompression, s));
}

float3 FDPOST_Apply(float3 color, float toneStrength, float saturationGuard, float clipGuard, float artifactCleanup)
{
    float3 outColor = saturate(color);
    outColor = FDPOST_ArtifactCleanup(outColor, artifactCleanup);
    outColor = FDPOST_ToneBalance(outColor, toneStrength);
    outColor = FDPOST_SaturationGuard(outColor, saturationGuard);
    outColor = FDPOST_ClipGuard(outColor, clipGuard);
    return saturate(outColor);
}

#endif
