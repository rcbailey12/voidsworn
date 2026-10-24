# Luminance Reference Facet Synthesis (chair, TWO LEGS)

Legs: contrib/qwen/reviews/luminance_facet_qwen38max_draft.md
(Qwen3.8-Max) and
contrib/deepseek/reviews/luminance_facet_deepseek_draft.md
(DeepSeek). Both legs are PROPOSED draft options only. Nothing here is
a ruling.

Chair verdict: GO WITH CONDITIONS. The merged spec below is adoptable
as a whole, with the conditions at the end. This synthesis also
supersedes the acceptance measurability synthesis's luminance section
on both points (see cross-spec note).

## Adopted from both legs (convergence)
- Reference: a fixed mid-grey swatch, not a named hull facet. A named
  facet couples the cap to ship art and adds render-condition
  divergence; the swatch is a calibration asset, and removing the hull
  variable is the point.
- Swatch: sRGB 8-bit (128, 128, 128), hex 808080, 64 x 64 px, unlit
  (no lights, no tone mapping, no post-processing, no colour grading).
- Reference luminance: 0.2159 in linear light (standard sRGB
  linearization, weights 0.2126 / 0.7152 / 0.0722).
- Formula for every pixel: linearize 8-bit sRGB channels to [0, 1]
  with the sRGB EOTF, then Y = 0.2126R + 0.7152G + 0.0722B.
- Re-measurement philosophy: the plate changes, never the cap or the
  spec, when a plate fails. Only Ryan moves the cap or the swatch, and
  any change ships as a new spec version. No conditional acceptance,
  no partial acceptance.
- Ownership split (DeepSeek): Ryan owns cap and spec rulings, the art
  owner owns plate fixes, Opus owns measurement and verification.

## Cap number (chair's ruling on a rounding variant)
- Adopted cap: 0.0864 linear luminance. Derivation: 0.40 x 0.2159 =
  0.08636, rounded to four decimals. It derives directly from the
  published reference value both legs agree on, so anyone can verify
  it with one multiplication.
- DeepSeek's draft uses 0.0863, which is the same number computed from
  the unrounded reference (0.40 x 0.21586 = 0.086344, rounded to four
  decimals). The difference is 0.0001 and immaterial in practice, but
  the spec carries one number: 0.0864. Comparisons use the unrounded
  computed pixel value against the published cap. Equality passes.
  Report max values to at least four decimal places.

## Measurement procedure (DeepSeek's, adopted)
- Tool: a PC-only script (Pillow/numpy class of tool; DeepSeek's
  proposed path is PROPOSED, Opus places it), with its version or
  commit recorded in every output row.
- Inputs per plate: the delivered plate PNG at native resolution, a
  same-size 1-bit background mask PNG, and the luminance spec version.
  Mask authority: white means background inside the board area; black
  means ship, UI, or outside board area.
- Validation: the plate PNG must be opaque; an embedded ICC profile
  is converted to sRGB before measurement. If the plate is not opaque,
  or the mask is missing or size-mismatched, the plate is returned as
  unmeasurable. Do not guess.
- Sample set: every pixel where the mask is white. This is a full
  scan, not a sample: it trivially includes the beauty spec's
  at-least-20-points minimum, covers corners, centre, plate edges,
  and the brightest visible feature, and the brightest feature is
  deterministic (reported as max pixel + coordinates), not a human
  judgement call.
- Pass/fail: a plate passes if its max_Y is at or below 0.0864; it
  fails if max_Y is above 0.0864. No borderline for a numeric cap.
- Output: one JSON or CSV row per plate (plate id, mask id, spec
  version, max_Y, max pixel coordinates, pass/fail), stored in the
  audit document.
- Why this over Qwen's frame script: Qwen's Babylon inspector script
  reads the final composited frame at 1920x1080, which is the right
  check for what a player sees but varies with render conditions,
  resolution, camera, and post-processing. The PNG-plus-mask scan is
  reproducible offline, and its outputs are archivable. Qwen's frame
  script is kept as an optional in-game cross-check, not the
  acceptance procedure. Qwen's fixed-point count error (21 claimed,
  19 fixed points listed, 20 total) is moot under a full scan.

## Re-measurement plan for the existing 18 plates
1. After Ryan rules, freeze the spec version (e.g. luminance-v1).
   Until then this document remains a draft.
2. The art owner supplies a same-size background mask for each of the
   18 plates. A missing mask means that plate is unmeasurable and is
   returned, not silently measured against a guessed mask.
3. Opus runs the procedure on all 18 plate PNGs with their masks
   within one working week of approval (Qwen's clock) and writes the
   results to the audit document.
4. For any plate over cap, the default change is the plate: darken
   the background, reduce the far-gradient region tint, or otherwise
   bring it under cap. Opus re-measures the revised plate. Failing
   plates get a two-week fix window (Qwen's clock).
5. If the failure is caused by a bad mask, the mask changes and the
   plate is re-measured. If the art owner believes the cap or spec is
   wrong, Ryan decides; the cap and spec do not change automatically
   because a plate failed.

## Failure handling for future plates
- Gate: no future plate enters acceptance without a plate PNG, a
  same-size background mask, and the current luminance spec version.
- If max_Y is above 0.0864, the plate is rejected. It is not accepted
  conditionally and it does not enter the build. The art owner may
  fix the plate and resubmit; Opus re-measures the resubmission.
- If the submitter disputes the result: one manual re-measure
  (Qwen's dispute procedure), both logs escalated to Ryan, and until
  Ryan rules the plate remains failed. Cap or spec changes require a
  Ryan ruling and a new spec version.

## Locations (PROPOSED, Opus places)
- Qwen proposed /art/ref/luminance_swatch_808080.png plus a code
  constant LUMINANCE_REF_LINEAR = 0.2159. DeepSeek proposed
  assets/reference/luminance/luminance_swatch_64_srgb128.png, a spec
  doc, a code constant, a measure script, and an audit doc. The repo
  has none of these directories today (single-file game plus
  contrib), so both path sets are invented. The requirement stands
  regardless of path: swatch file, code constant, measure script,
  and audit doc, all updated together on any cap change. Opus picks
  one home; do not adopt both path sets.

## Weakest points (both kept)
- Qwen's: the 128 grey is arbitrary, not derived from any actual hull
  facet, so 0.0864 may be too lenient or too strict against the
  original intent. What settles it: Ryan reviewing the 18 plates under
  the cap once measured.
- DeepSeek's: the background mask is a manual authored artifact, so
  reproducibility depends on mask correctness more than on the
  luminance formula. What settles it: Ryan approving the mask
  requirement, then Opus running a blind two-person mask test on one
  plate (independently authored masks, same pass/fail required).

## Cross-spec note (read with the acceptance synthesis)
- This spec supersedes the acceptance measurability synthesis's
  luminance section on both points: its 49-point 7x7 grid (a screening
  sample) and its provisional reference (3 unlit facet patches per
  hull). The acceptance spec keeps its coverage rule (every
  acceptance shot with a board area, both shots per hull); the
  measurement itself is this spec's full scan against the swatch.
  There is one luminance procedure, not two.

## Conditions
1. Cap pinned to 0.0864 as derived above; DeepSeek's 0.0863 is the
   recorded rounding variant, not a second cap.
2. Mask requirement: Ryan approves that every plate (existing 18 and
   future) carries a same-size background mask, and that a missing
   mask means unmeasurable, not guessed. This is a new artifact
   burden; it is also what makes the procedure reproducible.
3. Mask settler: Opus runs the blind two-person mask test on one
   plate before the 18-plate run is treated as settled.
4. Locations: Opus picks one home for the swatch, constant, script,
   and audit doc (see locations section).
5. Clocks: one working week to measure the 18 after approval,
   two-week fix window for failing plates.

## Recommended next step
Ryan rules the spec: swatch (128 grey, 0.2159, 0.0864 cap), full-scan
procedure, and the mask requirement. Once ruled, Opus builds the
measure script, authors the 18 masks, and runs the 18-plate audit
within the week.

## Not checked
- Whether any of the 18 plates currently passes or fails under the
  cap (that is the audit this spec enables, not a claim in it).
- The mask authoring workflow (who draws masks, in what tool).
- The in-game frame cross-check (Qwen's script) as an implemented tool.
