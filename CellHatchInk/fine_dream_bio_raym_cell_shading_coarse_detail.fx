// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: dream-cell-shader-1
// Capability: Broad portable Fibonacci bio --Ray-M cell-shader.



#include "FineDream_Lens55Bounded.fxh"
#include "FineDream_CellularShared_bio_raym_coarse.fxh"

float4 FDORCB_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    int tapCount = min(clamp(FDREAM_CELL_TapCount, 1, FDREAM_LENS55_TAP_COUNT), FDREAM_CELL_TapCap());
    int raySteps = min(clamp(FDREAM_CELL_RaySteps, 1, 8), FDREAM_CELL_StepCap8());
    float3 sourceColor = FDREAM_CELL_Source(uv);
    float centerDepth = FDREAM_CELL_Depth(uv);
    float centerLuma = FDREAM_CELL_Luma(sourceColor);
    float hitSum = 0.0;
    float weightSum = 0.0;
    float3 colorSum = 0.0;

    [loop]
    for (int tapIndex = 0; tapIndex < FDREAM_LENS55_TAP_COUNT; ++tapIndex)
    {
        if (tapIndex < tapCount)
        {
            FDREAM_CELL_AccumulateRayTap(uv, centerDepth, centerLuma, FDREAM_Lens55Offset(tapIndex), tapIndex, tapCount, raySteps, hitSum, weightSum, colorSum);
        }
    }

    float hitMask = saturate(hitSum / max(FDREAM_CELL_EPS, weightSum));
    hitMask = 1.0 - exp(-hitMask * 3.5);
    float depthGate = FDREAM_CELL_DepthGateMask(uv, centerDepth);
    float edge = FDREAM_CELL_StabilizeScalar(uv, FDREAM_CELL_Edge(uv), centerDepth) * depthGate;
    float budgetView = saturate(float(tapCount * raySteps) / float(FDREAM_LENS55_TAP_COUNT * 8));
    float3 tracedSupport = (hitSum > FDREAM_CELL_EPS) ? (colorSum / max(FDREAM_CELL_EPS, hitSum)) : sourceColor;
    float3 celColor = FDREAM_CELL_Cel(lerp(sourceColor, tracedSupport, 0.35), 0.75);
    float edgeAmplifier = lerp(1.0, 1.0 + hitMask, 0.75);
    float3 shadedColor = lerp(sourceColor, celColor, saturate(FDREAM_CELL_CelStrength * FDREAM_CELL_MasterIntensity * FDREAM_CELL_TierScale()));
    shadedColor = lerp(shadedColor, float3(0.0, 0.0, 0.0), saturate(edge * edgeAmplifier * FDREAM_CELL_EdgeStrength * FDREAM_CELL_MasterIntensity));
    float3 finalColor = FDREAM_CELL_ApplyGuards(uv, sourceColor, shadedColor);

    if (FDREAM_CELL_DebugView == 1) return float4(celColor, 1.0);
    if (FDREAM_CELL_DebugView == 2) return float4(edge.xxx, 1.0);
    if (FDREAM_CELL_DebugView == 3) return float4(hitMask.xxx, 1.0);
    if (FDREAM_CELL_DebugView == 4) return float4(depthGate.xxx, 1.0);
    if (FDREAM_CELL_DebugView == 5) return float4(budgetView.xxx, 1.0);
    return float4(saturate(finalColor), 1.0);
}
technique fine_dream_bio_raym_cell_shading_coarse_detail < ui_label = "Fine Cell - Cell Shading - Bio Ray-M Coarse Detail"; ui_tooltip = "Broad compact --Ray-M bio cell-shader."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FDORCB_MainPS;
    }
}





