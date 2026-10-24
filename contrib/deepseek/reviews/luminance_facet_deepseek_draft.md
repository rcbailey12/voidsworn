# DRAFT PROPOSAL - Luminance Reference Facet Spec (Voidsworn, PC-only)

Model: DeepSeek, DeepThink ON, Search OFF. Filed verbatim from the DeepSeek chat report (chat titled "Luminance facet spec draft"); em dashes normalized to hyphens if any, wording otherwise unchanged. The granted brief file was attached to the chat. Process note from the run: a first attempt stalled during generation for 12+ minutes and its chat was not persisted, so a fresh chat was started, the brief re-attached, and re-sent; DeepSeek completed the draft.

Status: draft for Ryan and Opus. This is not a ruling. Nothing here is decided until Ryan rules. Claims about existing docs are marked OBSERVED. Spec choices and numbers are marked PROPOSED.

## 1. Facet spec

OBSERVED: The art pack states the cap once: no background pixel inside the board area may exceed 40% of the luminance of an unlit hull facet.

OBSERVED: The current beauty corner procedure renders one unlit hull facet as a reference swatch, measures its luminance, samples background pixels inside the board area across all six anchor plates at at least 20 points per plate, records the maximum per plate, and fails any plate over cap regardless of beauty.

OBSERVED: The Pack J audit verified that the reference facet is unnamed: hull, facet, lighting, and swatch location are unspecified, so two people can get different caps.

OBSERVED: The chair recommends a fixed mid-grey swatch, not a ruling.

PROPOSED: Choose the fixed mid-grey swatch, not a named hull facet.

Defense: A fixed swatch makes the cap one stable number. A named hull facet would reintroduce dependency on hull art, facet choice, and render lighting, and would drift when hull art changes. The fixed swatch is a calibration asset, not a hull facet, and that is the point: it removes the hull variable entirely.

PROPOSED swatch grey value: sRGB 8-bit (128, 128, 128). Rationale: neutral mid-grey is easy to reproduce and is independent of hull art.

PROPOSED swatch size: 64 x 64 pixels. Rationale: large enough to inspect, small enough to keep the asset trivial.

PROPOSED swatch lighting: none. The swatch is unlit. The Babylon reference scene uses no lights, no tone mapping, no post-processing, and no color grading. The swatch is displayed as a screen-space asset, not a lit 3D material.

PROPOSED swatch location in the repo: assets/reference/luminance/luminance_swatch_64_srgb128.png. PROPOSED doc location: docs/luminance_spec.md. PROPOSED code constant: LUMINANCE_SWATCH_SRGB8 = 128 in src/reference/luminance.ts.

PROPOSED derived reference luminance: sRGB 128 has relative luminance 0.2159 in linear light. Rationale: computed with the standard sRGB linearization and relative luminance weights.

PROPOSED pass/fail threshold, one number: 0.0863 relative luminance, linear. This is 40% of 0.2159. Pass if the maximum measured background pixel is less than or equal to 0.0863. Fail if it is greater than 0.0863. Rationale: direct application of the observed 40% cap to the proposed fixed swatch.

## 2. Measurement procedure

PROPOSED tool: a PC-only script at tools/luminance_measure.py, using Pillow and numpy, with its version or commit recorded in the output. No browser-specific or device-specific acceptance check is part of this procedure.

Step 1. Inputs. For each plate, collect the delivered plate PNG at native resolution, a same-size 1-bit background mask PNG, and the luminance spec version.

Step 2. Validate inputs. The plate PNG must be opaque. If it has an embedded ICC profile, convert to sRGB before measurement. If the plate is not opaque, or the mask is missing or size-mismatched, return the plate as unmeasurable. Do not guess.

PROPOSED mask authority: in the background mask, white means background inside the board area. Black means ship, UI, or outside board area. Rationale: the cap applies to background pixels, not ships, so a deterministic background mask is required for two people to get the same result.

Step 3. Sample set. The pass/fail sample set is every pixel where the background mask is white. This is a full scan and therefore includes at least 20 points per plate when the mask has at least 20 white pixels. The full scan covers corners, centre, plate edges, and the brightest visible feature. The script reports the maximum-luminance pixel and its coordinates, so the brightest feature is deterministic and not a human judgement call.

Step 4. Compute luminance. For each sampled pixel, decode the 8-bit sRGB channels to [0, 1], linearize with the sRGB EOTF, then compute relative luminance:

Y = 0.2126 * R_linear + 0.7152 * G_linear + 0.0722 * B_linear

Step 5. Reduce per plate. Record max_Y for the plate and the coordinates of the max pixel.

Step 6. Pass/fail. A plate passes if max_Y <= 0.0863. A plate fails if max_Y > 0.0863. Equality passes. Use the unrounded computed value for comparison and report the value to at least four decimal places.

Step 7. Output. Write one JSON or CSV row per plate with plate id, mask id, spec version, max_Y, max pixel coordinates, and pass/fail. Store the result in the audit document.

## 3. Re-measurement plan for the existing 18 plates

OBSERVED: There are 18 existing plates across six anchor plates.

Step 1. After Ryan rules, freeze the spec version, for example luminance-v1. Until then, this document remains a draft.

Step 2. For each of the 18 plates, the art owner supplies a same-size background mask. If a mask is missing, Opus returns that plate to the art owner as unmeasurable. It is not silently measured against a guessed mask.

Step 3. Opus runs the measurement procedure on all 18 plate PNGs with their masks and writes the results to docs/luminance_audit_v1.md.

Step 4. For any plate over cap, the default change is the plate, not the cap and not the spec. The art owner darkens the background, reduces the far-gradient region tint, or otherwise brings the plate under cap. Opus re-measures the revised plate.

Step 5. If the failure is caused by a bad mask, the mask changes and the plate is re-measured. If the art owner believes the cap or spec is wrong, Ryan decides. The cap and spec do not change automatically because a plate failed.

Decision ownership: Ryan owns cap and spec rulings. Art owner owns plate fixes. Opus owns measurement and verification.

## 4. Failure handling for future plates

PROPOSED gate: no future plate enters acceptance without a plate PNG, a same-size background mask, and the current luminance spec version.

Opus runs the measurement procedure. If max_Y > 0.0863, the plate is rejected. It is not accepted conditionally and it does not enter the build. The art owner may fix the plate and resubmit. Opus re-measures the resubmission.

If the submitter disputes the result, Ryan rules. Until Ryan rules, the plate remains failed. Cap or spec changes require a Ryan ruling and a new spec version. They are not triggered automatically by a failed plate.

Weakest point of this spec: the new background mask is a manual authored artifact, so reproducibility depends on mask correctness more than on the luminance formula. What would settle it: Ryan approving the mask requirement, then Opus running a blind two-person test on one plate with independently authored masks to confirm the same pass/fail result.
