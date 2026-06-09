// Copyright (c) 2026 Alia June, Dastardly Rat, Verminis, and Maufus
// Private release on the ReShade forum.
// Not for distribution.
// Not for production.
// Licensed under LICENSE-SOURCE-AVAILABLE-RESHADE-ONLY.txt (ReShade-only; no other engines).
// Version: RC-1
// Generated from Lens/fibonacci_fractal_from3_coordinates_normalized.json
// Source mask: L07_55_base_samples, fractal_depth == 0
// Normalization: offsets centered at (0.5, 0.5) and scaled by max radius

#ifndef MIXSR_FC_ORGANIC_SAMPLING_LENS55_FXH
#define MIXSR_FC_ORGANIC_SAMPLING_LENS55_FXH

#define FCOH_LENS55_TAP_COUNT 55
#define FCOH_LENS55_TAPS(APPLY) \
    APPLY(float2(0.100754, 0.004535), 0) \
    APPLY(float2(-0.118351, 0.117109), 1) \
    APPLY(float2(0.023345, -0.209792), 2) \
    APPLY(float2(0.159426, 0.206563), 3) \
    APPLY(float2(-0.279708, -0.045743), 4) \
    APPLY(float2(0.273795, -0.166746), 5) \
    APPLY(float2(-0.085527, 0.339562), 6) \
    APPLY(float2(-0.167223, -0.326175), 7) \
    APPLY(float2(0.377182, 0.140625), 8) \
    APPLY(float2(-0.383142, 0.164563), 9) \
    APPLY(float2(0.191421, -0.394829), 10) \
    APPLY(float2(0.142639, 0.444833), 11) \
    APPLY(float2(-0.411712, -0.236688), 12) \
    APPLY(float2(0.492841, -0.102817), 13) \
    APPLY(float2(-0.293470, 0.428417), 14) \
    APPLY(float2(-0.064311, -0.526745), 15) \
    APPLY(float2(0.427183, 0.360743), 16) \
    APPLY(float2(-0.564215, 0.028055), 17) \
    APPLY(float2(0.419395, -0.408306), 18) \
    APPLY(float2(-0.023220, 0.604779), 19) \
    APPLY(float2(-0.390205, -0.468496), 20) \
    APPLY(float2(0.629848, 0.088670), 21) \
    APPLY(float2(-0.525291, 0.373175), 22) \
    APPLY(float2(0.149314, -0.639022), 23) \
    APPLY(float2(0.339402, 0.588922), 24) \
    APPLY(float2(-0.650096, -0.204310), 25) \
    APPLY(float2(0.640427, -0.289263), 26) \
    APPLY(float2(-0.270949, 0.662790), 27) \
    APPLY(float2(-0.241328, -0.679028), 28) \
    APPLY(float2(0.658752, 0.348373), 29) \
    APPLY(float2(-0.722134, 0.196083), 30) \
    APPLY(float2(0.417579, -0.637843), 31) \
    APPLY(float2(0.135927, 0.769066), 32) \
    APPLY(float2(-0.618146, -0.477704), 33) \
    APPLY(float2(0.801058, -0.061455), 34) \
    APPLY(float2(-0.546030, 0.599680), 35) \
    APPLY(float2(0.008546, -0.817547), 36) \
    APPLY(float2(0.564402, 0.621707), 37) \
    APPLY(float2(-0.836176, -0.073382), 38) \
    APPLY(float2(0.685761, -0.512490), 39) \
    APPLY(float2(-0.150459, 0.856519), 40) \
    APPLY(float2(-0.462343, -0.737381), 41) \
    APPLY(float2(0.860079, 0.239005), 42) \
    APPLY(float2(-0.793929, 0.414294), 43) \
    APPLY(float2(0.320076, -0.846580), 44) \
    APPLY(float2(0.350610, 0.854660), 45) \
    APPLY(float2(-0.833966, -0.392846), 46) \
    APPLY(float2(0.900731, -0.271771), 47) \
    APPLY(float2(-0.474614, 0.822119), 48) \
    APPLY(float2(-0.196465, -0.931490), 49) \
    APPLY(float2(0.792867, 0.564529), 50) \
    APPLY(float2(-0.964480, 0.125302), 51) \
    APPLY(float2(0.643596, -0.746259), 52) \
    APPLY(float2(0.040807, 0.999167), 53) \
    APPLY(float2(-0.700573, -0.710969), 54)

#endif // MIXSR_FC_ORGANIC_SAMPLING_LENS55_FXH
