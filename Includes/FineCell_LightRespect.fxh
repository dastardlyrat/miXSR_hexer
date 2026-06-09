// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
#ifndef FINECELL_LIGHT_RESPECT_FXH
#define FINECELL_LIGHT_RESPECT_FXH

uniform int FC_LIGHT_GlobalChromaStabilityEnable <
    ui_type = "combo";
    ui_label = "Global Chroma Stability";
    ui_category = "Fine Cell - Shared Light Respect - Chroma Stability";
    ui_items = "Off\0On\0";
> = 1;

uniform float FC_LIGHT_GlobalChromaStability <
    ui_type = "slider";
    ui_label = "Chroma Suppress";
    ui_category = "Fine Cell - Shared Light Respect - Chroma Stability";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
> = 0.650000;

uniform float FC_LIGHT_GlobalChromaClamp <
    ui_type = "slider";
    ui_label = "Chroma Clamp";
    ui_category = "Fine Cell - Shared Light Respect - Chroma Stability";
    ui_min = 0.0; ui_max = 0.250; ui_step = 0.001;
> = 0.035000;

float FC_LIGHT_Max3(float3 c)
{
    return max(c.r, max(c.g, c.b));
}

float FC_LIGHT_Min3(float3 c)
{
    return min(c.r, min(c.g, c.b));
}

float FC_LIGHT_Saturation(float3 c, float numericFloor)
{
    float peak = FC_LIGHT_Max3(c);
    float trough = FC_LIGHT_Min3(c);
    return saturate((peak - trough) / max(numericFloor, peak));
}

float FC_LIGHT_EmissionMask(
    float3 color,
    float luma,
    float threshold,
    float softness,
    float peakInfluence,
    float saturationInfluence,
    float saturationThreshold,
    float numericFloor)
{
    float safeSoftness = max(numericFloor, softness);
    float peak = FC_LIGHT_Max3(color);
    float saturationMask = smoothstep(saturationThreshold, 1.0, FC_LIGHT_Saturation(color, numericFloor));
    float lumaMask = smoothstep(threshold, threshold + safeSoftness, luma);
    float peakMask = smoothstep(threshold, threshold + safeSoftness, peak);
    float brightMask = lerp(lumaMask, max(lumaMask, peakMask), saturate(peakInfluence));
    float emissionMask = saturate(brightMask + saturationMask * peakMask * saturate(saturationInfluence));
    return emissionMask;
}

float3 FC_LIGHT_ProtectColor(float3 processedColor, float3 sourceColor, float preserveMask, float preserveStrength)
{
    float3 stabilizedColor = processedColor;

    if (FC_LIGHT_GlobalChromaStabilityEnable != 0)
    {
        const float numericFloor = 0.000010;
        float3 delta = processedColor - sourceColor;
        float deltaLuma = dot(delta, float3(0.2126, 0.7152, 0.0722));
        float3 lumaDelta = deltaLuma.xxx;
        float3 chromaDelta = delta - lumaDelta;

        float chromaMag = length(chromaDelta);
        float lumaMag = abs(deltaLuma);
        float chromaDominance = chromaMag / max(numericFloor, chromaMag + lumaMag);
        float chromaSuppress = saturate(FC_LIGHT_GlobalChromaStability) * saturate(chromaDominance);
        float3 suppressedChroma = chromaDelta * (1.0 - chromaSuppress);
        float chromaClamp = max(0.0, FC_LIGHT_GlobalChromaClamp);
        suppressedChroma = clamp(suppressedChroma, -chromaClamp, chromaClamp);

        stabilizedColor = sourceColor + lumaDelta + suppressedChroma;
    }

    return lerp(stabilizedColor, sourceColor, saturate(preserveMask * preserveStrength));
}

#endif
