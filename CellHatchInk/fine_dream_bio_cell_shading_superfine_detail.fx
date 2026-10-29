// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: dream-cell-shader-1
// Capability: Superfine portable Fibonacci bio cell-shader micro-detail.



#include "FineDream_Lens55Bounded.fxh"
#include "FineDream_CellularShared_bio_superfine.fxh"

float4 FDOCS_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    int tapCount = min(clamp(FDREAM_CELL_TapCount, 1, FDREAM_LENS55_TAP_COUNT), FDREAM_CELL_TapCap());
    float3 sourceColor = FDREAM_CELL_Source(uv);
    float centerDepth = FDREAM_CELL_Depth(uv);
    float centerLuma = FDREAM_CELL_Luma(sourceColor);
    float depthGate = FDREAM_CELL_DepthGateMask(uv, centerDepth);
    float edgeBase = FDREAM_CELL_Edge(uv);
    float organicEdgeSum = edgeBase;
    float organicEdgeWeight = 1.0;
    float3 supportSum = sourceColor;
    float supportWeight = 1.0;

    [loop]
    for (int tapIndex = 0; tapIndex < FDREAM_LENS55_TAP_COUNT; ++tapIndex)
    {
        if (tapIndex < tapCount)
        {
            FDREAM_CELL_AccumulateOrganicTap(uv, centerDepth, centerLuma, FDREAM_Lens55Offset(tapIndex), tapIndex, tapCount, organicEdgeSum, organicEdgeWeight, supportSum, supportWeight);
        }
    }

    float organicEdge = saturate(organicEdgeSum / max(FDREAM_CELL_EPS, organicEdgeWeight));
    float stableEdge = FDREAM_CELL_StabilizeScalar(uv, max(edgeBase, organicEdge), centerDepth) * depthGate;
    float3 organicSupport = supportSum / max(FDREAM_CELL_EPS, supportWeight);
    float3 localDetail = sourceColor - FDREAM_CELL_LocalSupport(uv, 0.45);
    float3 organicDetail = sourceColor - organicSupport;
    float detailMask = saturate((length(localDetail) + length(organicDetail)) * 4.0 + stableEdge * 0.50);
    float3 detailColor = clamp(localDetail * 1.15 + organicDetail * 0.65, float3(-0.18, -0.18, -0.18), float3(0.18, 0.18, 0.18));
    detailColor = FDREAM_CELL_ChromaSafeDetail(detailColor, depthGate * stableEdge);
    float3 celColor = FDREAM_CELL_Cel(sourceColor, 1.25);
    float3 shadedColor = lerp(sourceColor, celColor, saturate(FDREAM_CELL_CelStrength * FDREAM_CELL_MasterIntensity * 0.65));
    shadedColor = saturate(shadedColor + detailColor * detailMask * FDREAM_CELL_SuperfineStrength * FDREAM_CELL_MasterIntensity * depthGate * FDREAM_CELL_TierScale());
    shadedColor = lerp(shadedColor, float3(0.0, 0.0, 0.0), saturate(stableEdge * FDREAM_CELL_EdgeStrength * FDREAM_CELL_MasterIntensity * 0.65));
    float3 finalColor = FDREAM_CELL_ApplyGuards(uv, sourceColor, shadedColor);

    if (FDREAM_CELL_DebugView == 1) return float4(celColor, 1.0);
    if (FDREAM_CELL_DebugView == 2) return float4(stableEdge.xxx, 1.0);
    if (FDREAM_CELL_DebugView == 3) return float4(saturate(detailColor * 2.0 + 0.5), 1.0);
    if (FDREAM_CELL_DebugView == 4) return float4(depthGate.xxx, 1.0);
    return float4(saturate(finalColor), 1.0);
}
technique fine_dream_bio_cell_shading_superfine_detail < ui_label = "Fine Cell - Cell Shading - Bio Superfine Fibonacci Detail"; ui_tooltip = "Superfine Fibonacci bio cell-shader detail with compact support."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FDOCS_MainPS;
    }
}





