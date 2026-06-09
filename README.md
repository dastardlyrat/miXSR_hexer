# miXSR_hexer

`miXSR_hexer` is an RC3 snapshot of a ReShade-oriented shader collection centered on stylization, image shaping, shared mask orchestration, and preview-stage effect development.

The intended starting point is the shared mask orchestrator. `Orchestrator/miXSR_FC_shared_mask_orchestrator.fx` should run first so dependent effects can work from the same cached screen, depth, fog, light, and exclusion-state logic.

The repository groups together multiple effect families that appear to share a common visual language:

- anti-aliasing
- ambient occlusion
- bloom
- cel and ink shading
- global illumination
- gloss and material response
- tone and balance control
- shared fog, light, and protection masks

## Usage Rights

This repository is restricted to ReShade preview use only, and only to the extent allowed by ReShade.

- not for production use
- not for distribution

See [LICENSE.md](LICENSE.md) for the full restriction notice.

## Status

This repo is a standalone snapshot created from `RC3/production`.

It is best understood as:

- a preview-stage shader library
- a source snapshot for evaluation and iteration
- a private, restricted repository rather than a public release package

It is not presented here as a finished production distribution.

## What’s Inside

The repository is organized by effect family:

| Folder | Purpose |
| --- | --- |
| `AA` | Anti-aliasing shaders, including hybrid FXAA/SMAA-style work with Fibonacci weighting. |
| `AO` | Ambient occlusion shaders with Ray-M and bilateral cleanup patterns. |
| `Bloom` | Bloom and glow shaping passes. |
| `CellHatchInk` | Cel shading, hatch synthesis, edge ink, and stylized surface treatment. |
| `GI` | Global illumination drivers with preset-tier budgeting and shared-mask integration. |
| `GlossSSR` | Gloss and material-response shaders. |
| `Orchestrator` | Shared-mask orchestration and diagnostic/cache control. This should run first. |
| `Includes` | Shared `.fxh` include files for fog gates, light respect, mask controls, bounded sampling, and post harmonization. |
| `Other` | Supporting or alternate effects, including disabled variants. |
| `Tone` | Tone shaping, shadow lift, detail richness, and reflection-oriented controls. |

## Architectural Notes

Several files point to a common structure across the shader set:

- `Orchestrator/miXSR_FC_shared_mask_orchestrator.fx` is the top-level coordination layer and should run first
- shared include files in `Includes` provide reusable fog, light, mask, and sampling logic
- `Orchestrator/miXSR_FC_shared_mask_orchestrator.fx` acts as a central diagnostic and cache layer for screen color, depth, fog masking, light shielding, and exclusion logic
- many shaders expose detailed ReShade UI metadata, suggesting the collection is meant to be tuned interactively during preview and evaluation
- file headers consistently mark the code as a private ReShade-only release with non-production and non-distribution restrictions

## Recommended Run Order

For preview and evaluation, use this order:

1. Run `Orchestrator/miXSR_FC_shared_mask_orchestrator.fx` first.
2. Let the shared include-driven effects read from that orchestrated state.
3. Add effect families such as `AA`, `AO`, `GI`, `GlossSSR`, `CellHatchInk`, and `Tone` after the orchestrator is active.

If the orchestrator is not active first, dependent shaders may not be working from the intended shared protection, fog, light, and diagnostic state.

## Representative Components

Some representative files in this snapshot:

- `AA/miXSR_FC_bio_fibonacci_fxaa_smaa.fx`
  Hybrid anti-aliasing with FXAA-style directional smoothing, SMAA-style neighborhood blending, and recursive Fibonacci weighting.
- `AO/miXSR_FC_Bio_RayM_AO.fx`
  Ray-M ambient occlusion with directional taps and cleanup passes.
- `CellHatchInk/miXSR_FC_RayM_Cell_Shader.fx`
  Ray-M-guided cel shading with edge inking and hit-mask amplification.
- `GI/miXSR_FC_bio_raym_global_illumination.fx`
  Portable global illumination driver with preset tiers and shared-mask orchestration.
- `Orchestrator/miXSR_FC_shared_mask_orchestrator.fx`
  Shared mask cache and diagnostics for true screen color, fog, light shielding, and related protection layers.
- `Includes/miXSR_FC_ShaderSharedMaskControls.fxh`
  Shared control surface for mask, fog, light, and guard configuration used across multiple effects.

## Working With This Repo

If you are reviewing or testing this snapshot:

1. Start with `Includes` and `Orchestrator` to understand the shared control model.
2. Run `Orchestrator/miXSR_FC_shared_mask_orchestrator.fx` first before evaluating the effect families.
3. Move into one effect family at a time such as `AA`, `AO`, `GI`, or `CellHatchInk`.
4. Treat files in `Other` and `.disabled` variants as supporting material rather than the main entry point.
5. Keep any use within private ReShade preview and evaluation boundaries.

## Restrictions Summary

Unless separate written permission is granted by the copyright holder, you may not:

- use these contents in production
- distribute or republish these contents
- bundle these contents into presets, packs, installers, or products
- treat this repository as a general-purpose shader asset source outside the allowed ReShade preview scope

## Source

This repository was created from:

- `RC3/production`

## Credits

File headers in this snapshot attribute copyright to:

- Alia June
- Dastardly Rat
- Verminis
- Maufus
