<img width="2560" height="1440" alt="XCom2 2026-06-09 10-51-28_240" src="https://github.com/user-attachments/assets/b80b9892-3f78-4548-9fff-0fe1c54e338e" />
# miXSR_hexer

## INTO THE LOOKING GLASS

All is not what it seems.

This repository is a working mirror, a shader cabinet, and a caution sign. It is not a clean product surface. It is not a promise that every header comment, capability line, UI label, or technique name is already telling the full truth.

The purpose of this README is to mark the entrance plainly:

> Treat every claimed function as provisional until the shader has been compiled, inspected, debug-viewed, and matched against what the code actually does.

There are roughly one hundred suspected or possible false claims of function across this lineage that still need to be audited and backported into corrected descriptions, corrected code paths, or both. Some of those claims may be simple overstatements. Some may be stale names left behind by rapid iteration. Some may point to a real idea that is only partially implemented. Some may be wrong enough that the safest repair is to preserve the artifact as history and rebuild the behavior elsewhere.

That is the looking glass: names, comments, and UI can look finished before the function is finished.

So this repo should be read in three layers:

1. **What the files claim.**
   Header comments, UI labels, technique names, and folder placement.
2. **What the code appears to do.**
   Includes, passes, samplers, debug views, masks, guards, and math paths.
3. **What runtime proves.**
   ReShade compile logs, debug output, actual visual behavior, and comparison against the intended effect.

If those three layers disagree, runtime and code win. The README does not promote a claim to truth. It records the current map so the claims can be checked without losing the trail.

## Current Status

`miXSR_hexer` is an RC3-era ReShade shader snapshot built around stylization, image shaping, shared mask orchestration, fog and light protection, Ray-M style tracing, Fibonacci sampling, tonal response, and preview-stage diagnostics.

Current repository state from the walked tree:

| Item | Count |
|---|---:|
| Effect folders | 10 |
| `.fx` files | 29 |
| `.fxh` include files | 15 |
| `.fx.disabled` historical variants | 5 |
| Markdown documents | 2 |

The repo is best treated as:

- a restricted ReShade preview snapshot;
- a mine of working patterns and failed assumptions;
- a backport/audit source for later cleaner systems;
- a historical record of shader-family iteration;
- not a finished production release.

## Usage Rights

This repository is restricted to private ReShade preview, evaluation, and testing only.

It is not for production use.
It is not for distribution.
It is not a general-purpose shader asset source.

See [LICENSE.md](LICENSE.md) for the restriction notice.

## First Rule

Start with the orchestrator, then inspect dependent effects one family at a time.

The intended first file is:

```text
Orchestrator/miXSR_FC_shared_mask_orchestrator.fx
```

That shader is the central diagnostic and cache layer for true screen color, depth, fog mask, light shield, guards, exclusion logic, and shared protection state. Effects that include shared mask controls may expect this logic to be available or conceptually upstream.

## Recommended Run Order

For preview and evaluation:

1. Run `Orchestrator/miXSR_FC_shared_mask_orchestrator.fx`.
2. Inspect orchestrator diagnostic views before enabling dependent effects.
3. Add one family at a time: `AA`, `AO`, `Bloom`, `CellHatchInk`, `GI`, `GlossSSR`, `Tone`, or selected `Other` files.
4. Keep disabled files disabled unless you are doing historical comparison.
5. Record compile errors and visual mismatches before patching.

## Repository Walk

| Folder | Files | Purpose |
|---|---:|---|
| `AA` | 2 | Anti-aliasing and coherence filtering. |
| `AO` | 2 | Ambient occlusion experiments using depth, Ray-M style taps, Fibonacci sampling, and cleanup. |
| `Bloom` | 1 | Multi-pass white-gold bloom model. |
| `CellHatchInk` | 8 | Cel shading, hatch synthesis, ink, edge stylization, and Ray-M guided surface treatment. |
| `GI` | 4 | Global illumination drivers with bio/Fibonacci/Ray-M variants. |
| `GlossSSR` | 4 | Gloss, material response, SSR-style highlight behavior, and hatch-lens variants. |
| `Includes` | 15 | Shared fog, light, lens, mask, sampling, cellular, and post-harmonize helpers. |
| `Orchestrator` | 2 | Shared mask orchestration plus a diagnostic debugger. |
| `Other` | 6 | Alternate, transitional, and disabled gate-era artifacts. |
| `Tone` | 5 | Tone shaping, reflection enrichment, shadow lift, deep balance, and detail richness. |

## Orchestrator

### `Orchestrator/miXSR_FC_shared_mask_orchestrator.fx`

Claimed role:

- first-run orchestrator;
- true screen color cache;
- depth diagnostics;
- fog mask;
- light shield;
- line and pixel guards;
- exclusion zone;
- local contrast;
- staged mask diagnostics;
- shared reuse decision.

What to inspect:

- `Diagnostic View`
- `Diagnostic Shading Stage`
- `Local Mask Sensitivity`
- `Exclusion Strength`
- depth-window controls
- shared cache behavior

This is the entry point for understanding the protection model. It should be treated as the center of the old system.

### `Orchestrator/fine_dream_Debugger_Diagnostics.fx`

Claimed role:

- standalone diagnostic control surface;
- true screen color, depth, fog, and light masks.

Use this as a diagnostic reference, especially when separating old `FineDream` helper patterns from the newer `miXSR_FC` shared-mask path.

## Includes

The include folder is where most of the reusable architecture lives.

| Include | Observed role |
|---|---|
| `miXSR_FC_ShaderSharedMaskControls.fxh` | Shared cache mode, fog authority, light shield authority, line guard, pixel guard, and compatibility helpers. |
| `miXSR_FC_FogGate.fxh` | Unified fog gate controls and fog bypass mask construction. |
| `miXSR_FC_LightRespect.fxh` | Shared light/chroma respect controls. |
| `miXSR_FC_Lens55Bounded.fxh` | Bounded Lens55 lookup. |
| `miXSR_FC_OrganicSampling_Lens55.fxh` | Lens55 sampling offsets generated from a normalized Fibonacci/fractal source. |
| `miXSR_FC_PostHarmonize.fxh` | Post harmonization helpers. |
| `FineCell_FogGate.fxh` | Older FineCell fog gate path. |
| `FineCell_LightRespect.fxh` | Older FineCell light respect path. |
| `FineDream_Lens55Bounded.fxh` | Older FineDream bounded Lens55 lookup. |
| `FineDream_PostHarmonize.fxh` | Older FineDream post harmonize helpers. |
| `FineDream_CellularShared*.fxh` | Shared cellular/cel shader helpers for coarse, superfine, bio, and Ray-M variants. |

Backport warning:

The include set contains overlapping generations of the same ideas. Do not assume `FineCell`, `FineDream`, and `miXSR_FC` names mean identical behavior. Audit helpers by call site before migrating them.

## AA

### `AA/miXSR_FC_bio_fibonacci_fxaa_smaa.fx`

Claimed role:

- loop-free hybrid anti-aliasing;
- FXAA-style directional smoothing;
- SMAA-style neighborhood blending;
- Fibonacci recursive weighting;
- shared-mask orchestration.

Audit focus:

- verify whether each AA claim is actually present in code;
- inspect edge direction, blend weights, mask gates, and post harmonization;
- confirm whether "recursive" means actual recurrence or a static Fibonacci weighting pattern.

### `AA/miXSR_FC_image_aware_coherence.fx`

Claimed role:

- image-aware coherence denoiser;
- temporal accumulation;
- edge-aware spatial filtering;
- detector-driven handling for legacy stipple/hatch transparency patterns.

Audit focus:

- temporal history behavior;
- whether the detector path matches the claimed legacy pattern handling;
- whether the filter is safe around UI, line art, and animated depth edges.

## AO

### `AO/miXSR_FC_Bio_RayM_AO.fx`

Claimed role:

- Ray-M ambient occlusion;
- depth-guided tracing;
- bilateral cleanup;
- fog and light respect.

Audit focus:

- depth linearization mode;
- depth polarity;
- ray length, steps, taps, budget scale, and early-out behavior;
- whether bilateral cleanup is real, effective, and bounded.

### `AO/miXSR_FC_SuperfineFibonacciAO.fx`

Claimed role:

- Fibonacci superfine AO;
- depth-derived normals;
- conservative composite;
- shared-mask orchestration.

Audit focus:

- derived normal stability;
- whether superfine sampling improves signal or only increases texture chatter;
- how conservative composite behaves with weak depth.

## Bloom

### `Bloom/miXSR_FC_three_pass_source_bloom.fx`

Claimed role:

- standalone white-gold bloom;
- core, photosphere halo, and eruptive corona;
- three staged bloom targets with final composite.

Audit focus:

- verify pass structure and render target separation;
- check whether "source bloom" respects masks as claimed;
- inspect cost gates around photosphere and corona sampling.

## Cell, Hatch, And Ink

This is the densest stylization folder.

### `CellHatchInk/miXSR_FC_RayM_Cell_Shader.fx`

Claimed role:

- Ray-M guided cel shading;
- edge inking;
- hit-mask amplification.

Audit focus:

- whether Ray-M hit masks are stable;
- whether inking is line evidence or just contrast amplification;
- whether fog/light/shared masks actually restrain the final composite.

### `CellHatchInk/miXSR_FC_bio_raym_ink_stylized.fx`

Claimed role:

- Ray-M bio ink edge stylization;
- compact Ray-M support;
- cel-band tone remap;
- light/fog guards;
- shared-mask orchestration.

Audit focus:

- edge source;
- detail source;
- tone remap;
- guard masking;
- whether "compact Ray-M support" is an actual reduced-cost trace path.

### `CellHatchInk/miXSR_FC_Procedural_Bio_Hatch_Synthesis.fx`

Claimed role:

- procedural bio hatch pattern synthesis;
- scene blending;
- shared mask and Lens55 sampling.

Audit focus:

- pattern stability;
- scene blending authority;
- whether hatching follows surfaces or drifts in screen space.

### `CellHatchInk/fine_dream_*`

Claimed role:

- older portable bio and bio-Ray-M cell shading variants;
- coarse and superfine detail variants;
- older ink stylization path.

Audit focus:

- separate portable helper behavior from current shared-mask behavior;
- identify which variants are useful historical references and which are superseded.

## GI

### `GI/miXSR_FC_bio_raym_global_illumination.fx`

Claimed role:

- portable Fibonacci bio Ray-M global illumination;
- preset-tier budgeting;
- shared-mask orchestration.

Audit focus:

- whether the effect produces true GI-like transport, local color bleeding, or a stylized indirect-light approximation;
- whether preset tiers change cost and quality predictably;
- how it handles missing or noisy depth.

### `GI/fine_dream_*`

Claimed role:

- older global illumination variants;
- bio, Ray-M, and hatch-lens paths.

Audit focus:

- compare against the `miXSR_FC` path;
- identify useful control shapes;
- mark stale claims before backport.

## Gloss And SSR-Like Material Response

### `GlossSSR/miXSR_FC_bio_raym_gloss_material_response.fx`

Claimed role:

- portable Fibonacci bio Ray-M gloss;
- SSR-style tracing;
- bloom-style highlight diffusion;
- shared-mask orchestration.

Audit focus:

- distinguish actual reflection tracing from gloss shaping;
- check whether highlight diffusion is bounded;
- verify mask protection around UI, fog, and bright emissive regions.

### `GlossSSR/fine_dream_*`

Claimed role:

- older gloss/material response variants;
- bio, Ray-M, and hatch-lens paths.

Audit focus:

- compare names against actual behavior;
- identify which pieces should be backported as controls and which should remain historical.

## Tone

### `Tone/miXSR_FC_bio_deep_tone.fx`

Claimed role:

- bio Fibonacci deep-tone shaping;
- guarded color expansion;
- stability controls.

Audit focus:

- whether color expansion is hue-stable;
- whether shadows stay protected;
- whether shared mask gates work as intended.

### `Tone/miXSR_FC_bio_reflection.fx`

Claimed role:

- reflection enrichment;
- stability guards;
- shared-mask orchestration.

Audit focus:

- determine whether it is reflection, gloss enrichment, contrast recovery, or a blend of all three;
- inspect actual contribution path.

### `Tone/fine_dream_*`

Claimed role:

- deep shade;
- detail richness;
- shadow lift;
- deep balance.

Audit focus:

- useful tonal-control patterns;
- stale gate-era naming;
- mismatch between poetic file names and actual shader behavior.

## Other

`Other` contains one active `.fx` file and five disabled historical variants.

### Active

`Other/fine_dream_raym_guided_directional_tonal_shading.fx`

Claimed role:

- Ray-M guided directional tonal shading;
- local support;
- stability cleanup;
- guarded compositing.

Audit focus:

- whether it is a tonal pass, directional shade pass, or stylized normal/edge response;
- whether local support and cleanup match the output.

### Disabled historical variants

These files are intentionally not part of the normal run path:

| Disabled file | Claimed role |
|---|---|
| `fine_dream_Fog_Gate_and_Light_Shield_The_First_Gate.fx.disabled` | First-gate diagnostic fog and light shield. |
| `fine_dream_morning_light_Third_Gate.fx.disabled` | Older global illumination driver. |
| `fine_dream_miday_sun_Repose_After_the_Third_Gate.fx.disabled` | Hatch-lens Ray-M global illumination. |
| `fine_dream_mirage_visions_in_light_after_the_Third_Gate.fx.disabled` | Ray-M gloss and guarded compositing. |
| `fine_dream_vision_of_gold_after_the_Fourth_Gate_visions_of_the_Fifth_Gate.fx.disabled` | Three-pass bloom model. |

Keep these disabled unless the task is historical comparison, lineage recovery, or backport mining.

## Backport Audit Protocol

Use this protocol for every claim that may be false, stale, inflated, or incomplete.

| Step | Question | Result |
|---|---|---|
| 1 | What does the file claim? | Record header capability, technique label, UI text, and README description. |
| 2 | What does the code do? | Trace includes, textures, samplers, passes, masks, gates, and math. |
| 3 | Does it compile? | Check ReShade logs before visual judgment. |
| 4 | What do debug views show? | Inspect masks, depth, guards, contribution, and final composite separately. |
| 5 | Is the claim true? | Mark true, partial, stale, false, or unknown. |
| 6 | What is the repair? | Backport code, backport wording, quarantine the artifact, or rebuild elsewhere. |

Do not fix a claim by making the sentence prettier. Fix it by matching the sentence to the behavior, or by changing the behavior and then proving it.

## Claim States

Use these labels while mining and backporting:

| State | Meaning |
|---|---|
| `verified` | Code, compile, debug, and runtime behavior match the claim. |
| `partial` | The idea exists, but the claim overstates completeness or scope. |
| `stale` | The claim describes an older version or naming lineage. |
| `false` | The behavior is not present or contradicts the claim. |
| `unknown` | Evidence is insufficient. Do not promote. |
| `historical` | Useful for lineage, not intended as current behavior. |

## Practical Test Order

When testing a shader from this repo:

1. Read the file header and technique name.
2. Confirm required includes exist.
3. Compile in ReShade.
4. Check the ReShade log before trusting output.
5. Run the orchestrator if the file depends on shared masks.
6. Inspect debug views first.
7. Inspect final composite last.
8. Write down mismatches between name, UI, debug, and final image.

## Common Failure Patterns

| Symptom | Likely meaning |
|---|---|
| Compiles but output is black | Missing depth, failed mask authority, wrong run order, or an output path gated to zero. |
| Debug view is vivid but final is subtle | Contribution ceiling or final composite gate is conservative. |
| Whole image changes | Mask admission is too broad or protection gates are not active. |
| Lines crawl or shimmer | Screen-space support, depth instability, or unguarded high-frequency sampling. |
| Claims sound stronger than output | Header/UI language may be ahead of implementation. Add to audit list. |
| Disabled file looks more promising than active file | Treat as historical evidence, not a drop-in replacement. |

## Migration Notes

This repo is valuable because it shows where the system has been:

- shared-mask orchestration;
- fog and light respect;
- line and pixel guards;
- Lens55 sampling;
- Fibonacci tap patterns;
- Ray-M style trace language;
- cel, hatch, ink, AO, GI, gloss, bloom, tone, and reflection experiments;
- diagnostic-first shader development.

It is also dangerous if copied blindly. Some names are better than their implementation. Some implementations are better than their names. Some are only useful as negative examples.

When migrating to a cleaner API or public OpenSurface line:

- mine shapes, not branding;
- verify behavior before preserving names;
- prefer small, inspectable services;
- centralize debug vocabulary;
- keep historical claims out of production docs unless verified;
- record every mismatch.

## Source

This repository was created from:

```text
RC3/production
```

## Credits

File headers in this snapshot attribute copyright to:

- Alia June
- Dastardly Rat
- Verminis
- Maufus

Repository restriction notice attributes the repository to:

- dastardlyrat
