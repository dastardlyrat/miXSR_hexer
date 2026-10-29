// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Bounded Lens55 tap lookup for high-fidelity dream drivers.

#ifndef MIXSR_FC_LENS55_BOUNDED_FXH
#define MIXSR_FC_LENS55_BOUNDED_FXH

#define FDREAM_LENS55_TAP_COUNT 55

int FDREAM_Lens55TierTapCap(int tier)
{
    if (tier == 0) return 5;
    if (tier == 1) return 9;
    if (tier == 2) return 13;
    if (tier == 3) return 34;
    return 55;
}

float FDREAM_Lens55TierScale(int tier)
{
    if (tier == 0) return 0.72;
    if (tier == 1) return 1.00;
    if (tier == 2) return 1.18;
    if (tier == 3) return 1.32;
    return 1.48;
}

float FDREAM_Lens55FibonacciGrowth(int index, int tapCount)
{
    float fib = 3.0;
    if (index >= 3) fib = 5.0;
    if (index >= 5) fib = 8.0;
    if (index >= 8) fib = 13.0;
    if (index >= 13) fib = 21.0;
    if (index >= 21) fib = 34.0;
    if (index >= 34) fib = 55.0;

    float activeMax = max(8.0, float(tapCount));
    return 0.28 + 0.72 * saturate(fib / activeMax);
}

float2 FDREAM_Lens55Offset(int index)
{
    float2 offset = float2(0.100754, 0.004535);
    if (index == 1) offset = float2(-0.118351, 0.117109);
    else if (index == 2) offset = float2(0.023345, -0.209792);
    else if (index == 3) offset = float2(0.159426, 0.206563);
    else if (index == 4) offset = float2(-0.279708, -0.045743);
    else if (index == 5) offset = float2(0.273795, -0.166746);
    else if (index == 6) offset = float2(-0.085527, 0.339562);
    else if (index == 7) offset = float2(-0.167223, -0.326175);
    else if (index == 8) offset = float2(0.377182, 0.140625);
    else if (index == 9) offset = float2(-0.383142, 0.164563);
    else if (index == 10) offset = float2(0.191421, -0.394829);
    else if (index == 11) offset = float2(0.142639, 0.444833);
    else if (index == 12) offset = float2(-0.411712, -0.236688);
    else if (index == 13) offset = float2(0.492841, -0.102817);
    else if (index == 14) offset = float2(-0.293470, 0.428417);
    else if (index == 15) offset = float2(-0.064311, -0.526745);
    else if (index == 16) offset = float2(0.427183, 0.360743);
    else if (index == 17) offset = float2(-0.564215, 0.028055);
    else if (index == 18) offset = float2(0.419395, -0.408306);
    else if (index == 19) offset = float2(-0.023220, 0.604779);
    else if (index == 20) offset = float2(-0.390205, -0.468496);
    else if (index == 21) offset = float2(0.629848, 0.088670);
    else if (index == 22) offset = float2(-0.525291, 0.373175);
    else if (index == 23) offset = float2(0.149314, -0.639022);
    else if (index == 24) offset = float2(0.339402, 0.588922);
    else if (index == 25) offset = float2(-0.650096, -0.204310);
    else if (index == 26) offset = float2(0.640427, -0.289263);
    else if (index == 27) offset = float2(-0.270949, 0.662790);
    else if (index == 28) offset = float2(-0.241328, -0.679028);
    else if (index == 29) offset = float2(0.658752, 0.348373);
    else if (index == 30) offset = float2(-0.722134, 0.196083);
    else if (index == 31) offset = float2(0.417579, -0.637843);
    else if (index == 32) offset = float2(0.135927, 0.769066);
    else if (index == 33) offset = float2(-0.618146, -0.477704);
    else if (index == 34) offset = float2(0.801058, -0.061455);
    else if (index == 35) offset = float2(-0.546030, 0.599680);
    else if (index == 36) offset = float2(0.008546, -0.817547);
    else if (index == 37) offset = float2(0.564402, 0.621707);
    else if (index == 38) offset = float2(-0.836176, -0.073382);
    else if (index == 39) offset = float2(0.685761, -0.512490);
    else if (index == 40) offset = float2(-0.150459, 0.856519);
    else if (index == 41) offset = float2(-0.462343, -0.737381);
    else if (index == 42) offset = float2(0.860079, 0.239005);
    else if (index == 43) offset = float2(-0.793929, 0.414294);
    else if (index == 44) offset = float2(0.320076, -0.846580);
    else if (index == 45) offset = float2(0.350610, 0.854660);
    else if (index == 46) offset = float2(-0.833966, -0.392846);
    else if (index == 47) offset = float2(0.900731, -0.271771);
    else if (index == 48) offset = float2(-0.474614, 0.822119);
    else if (index == 49) offset = float2(-0.196465, -0.931490);
    else if (index == 50) offset = float2(0.792867, 0.564529);
    else if (index == 51) offset = float2(-0.964480, 0.125302);
    else if (index == 52) offset = float2(0.643596, -0.746259);
    else if (index == 53) offset = float2(0.040807, 0.999167);
    else if (index == 54) offset = float2(-0.700573, -0.710969);
    return offset;
}

#endif
