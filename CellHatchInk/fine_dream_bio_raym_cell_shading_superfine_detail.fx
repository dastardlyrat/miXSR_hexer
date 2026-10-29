// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: dream-cell-shader-1
// Capability: Superfine portable Fibonacci bio --Ray-M cell-shader micro-detail.



#include "FineDream_Lens55Bounded.fxh"
#include "FineDream_CellularShared_bio_raym_superfine.fxh"

float4 FDORCS_MainPS(float4 position : SV_Position, float2 uv : TEXCOORD) : SV_Target
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
    float3 localDetail = FDREAM_CELL_LocalDetail(uv, 0.40);
    float3 directionalDetail = sourceColor - tracedSupport;
    float3 detailColor = clamp(localDetail * 1.10 + directionalDetail * (0.45 + 0.55 * hitMask), float3(-0.18, -0.18, -0.18), float3(0.18, 0.18, 0.18));
    float detailMask = saturate((length(detailColor) * 5.0 + hitMask * 0.35 + edge * 0.35) * depthGate);
    detailColor = FDREAM_CELL_ChromaSafeDetail(detailColor, depthGate * saturate(0.5 * (edge + hitMask)));
    float3 celColor = FDREAM_CELL_Cel(sourceColor, 1.25);
    float3 shadedColor = lerp(sourceColor, celColor, saturate(FDREAM_CELL_CelStrength * FDREAM_CELL_MasterIntensity * 0.60));
    shadedColor = saturate(shadedColor + detailColor * detailMask * FDREAM_CELL_SuperfineStrength * FDREAM_CELL_MasterIntensity * FDREAM_CELL_TierScale());
    shadedColor = lerp(shadedColor, float3(0.0, 0.0, 0.0), saturate(edge * (1.0 + hitMask) * FDREAM_CELL_EdgeStrength * FDREAM_CELL_MasterIntensity * 0.65));
    float3 finalColor = FDREAM_CELL_ApplyGuards(uv, sourceColor, shadedColor);

    if (FDREAM_CELL_DebugView == 1) return float4(celColor, 1.0);
    if (FDREAM_CELL_DebugView == 2) return float4(edge.xxx, 1.0);
    if (FDREAM_CELL_DebugView == 3) return float4(saturate(detailColor * 2.0 + 0.5), 1.0);
    if (FDREAM_CELL_DebugView == 4) return float4(depthGate.xxx, 1.0);
    if (FDREAM_CELL_DebugView == 5) return float4(budgetView.xxx, 1.0);
    return float4(saturate(finalColor), 1.0);
}
technique fine_dream_bio_raym_cell_shading_superfine_detail < ui_label = "Fine Cell - Cell Shading - Bio Ray-M Superfine Detail"; ui_tooltip = "Superfine compact --Ray-M bio cell-shader detail."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FDORCS_MainPS;
    }
}





