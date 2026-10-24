# Acceptance Test Measurability Synthesis (chair, TWO LEGS)

Legs: contrib/qwen/reviews/acceptance_measurability_qwen38max_draft.md
(Qwen3.8-Max) and
contrib/deepseek/reviews/acceptance_measurability_deepseek_draft.md
(DeepSeek). Both legs are PROPOSED draft options only. Nothing here is
a ruling.

Chair verdict: GO WITH CONDITIONS. The merged spec below is adoptable
as a whole, with the conditions at the end. The panel numbers in the
merged table are the chair's scaling (DeepSeek's per-unit structure at
Qwen's scale), labeled as such wherever they appear, and Ryan rules
them.

## Adopted from DeepSeek (structure)
- Global viewer definition: a person not on the design, art, or QA
  team for the hull or faction under test, who has not seen the
  specific acceptance shot before judging it. This replaces Qwen's
  per-test restatements.
- Per-unit structure: silhouette judged per same-faction pair (all
  unordered pairs), at-a-glance per hull, gold per comparison, colourblind
  per simulated shot. Per-unit attribution is what makes a failure
  actionable; Qwen's per-batch silhouette panel cannot attribute a
  confusion to a pair.
- Provisional state is hold for retest, not conditional pass. Qwen's
  conditional passes mostly convert to failure if unmet in one cycle,
  which is a hold wearing a pass's name, and a conditional pass that
  ships is how over-cap plates accumulate. Qwen's named-condition
  discipline is kept as the hold's required fields: test, shot or hull
  ID, exact threshold miss, fix owner, retest date, exact re-run
  scope. A hold never overrides an OBSERVED manifest-return finding:
  wrong faction, indistinguishable same-faction hull, gold trim
  reading as Command gold, luminance cap exceedance.
- Hard-return findings: any wrong-faction naming sends the manifest
  back and cannot be averaged away (DeepSeek's reading of the OBSERVED
  pack language, which Qwen's 6-of-7 at-a-glance pass contradicts).
  The same hard logic applies to gold naming (see gold panel below).

## Merged table (chair's scaling, Ryan rules)
- Silhouette sheet: 7 viewers per same-faction pair. Pass 6 of 7
  report the two silhouettes as different hulls. Borderline exactly 5
  of 7: hold for retest. Fail 4 or fewer of 7, or any viewer reporting
  the pair as the same hull after retest: manifest return. Retest:
  re-shoot only the changed hull's sheet, re-judge every pair
  containing that hull with fresh viewers; if shared faction
  silhouette language changed, re-run all pairs in the faction.
  Session cap 8 hulls (DeepSeek); same viewer never judges the same
  hull twice (both legs).
- Faction at a glance: 7 viewers per hull. Correctness hard return:
  any wrong-faction naming fails the hull, no averaging. Timing: at
  least 6 of 7 name the correct faction in under 3 seconds (OBSERVED
  window). Timing-only miss (all correct, exactly 5 of 7 under 3
  seconds): hold for retest. Timing method: on-screen timer, Opus
  logs timestamps, no stopwatch-by-eye (Qwen). Vision: normal or
  corrected acuity and normal or corrected colour vision (DeepSeek),
  plus Qwen's diagnostic: at least 1 viewer with documented mild
  colour-vision deficiency as a flag, not counted in pass, to catch
  faction identity leaning too heavily on one hue. Diagnostic
  addition from Qwen: record spoken reasoning (think-aloud) alongside
  the binary and timestamp, so a 2.9-second pass by elimination is
  visible as guessing, not recognition. Retest: re-shoot only the lit
  hero shot, fresh viewers; shared faction cue changes re-run the
  faction. Session cap 6 hulls (DeepSeek).
- Gold-trim confusion: 7 viewers per comparison. Pass 7 of 7 do NOT
  name the trim as Command gold. Exactly 1 confusion: hold for retest,
  and the confusion remains a finding against the rationing rule, not
  a pass. Fail 2 or more confusions, or repeated naming after retest.
  Test conditions merged from the gold-law synthesis: blind to spec
  names, 3 scenes (one per faction trim context, one with epic-rarity
  loot visible, one with Belt or Stellar Nursery background), each
  frame containing at least one Command gold element, 1920x1080, 100%
  UI scale, default combat camera, no close inspection, 5 seconds per
  plate, 1 Command gold reference crop shown once before the block
  (DeepSeek). Vision: normal or corrected colour vision (both legs
  agree in substance; Qwen's Ishihara screening is the concrete
  method). Retest: re-shoot only changed trims plus the same reference
  crop, fresh viewers; shared trim material changes re-run every shot
  using it. Session cap 10 comparisons (DeepSeek); 5-minute break
  after the reference swatch (Qwen). This panel decision settles the
  three-way gold question (see conditions): it supersedes the gold-law
  merged 2-reviewer panel and both measurability legs' panels for the
  gold test, on the grounds that Qwen's 6-of-7 lets a hard finding
  through as a pass and the 2-reviewer panel is statistically
  thinnest, while 12 per comparison is the high-rigor variant Ryan
  can rule up to.
- Luminance cap sampling: 0 viewers; instrumental. Coverage: every
  acceptance shot with a board area (both shots per hull, DeepSeek).
  Procedure: the luminance facet synthesis (landed, two legs)
  supersedes this section's grid and reference. Measurement is that
  spec's full scan of the plate PNG against a same-size background
  mask, reference fixed mid-grey swatch sRGB 128 (0.2159), cap 0.0864.
  Do not use Qwen's silhouette-sheet reference here: a flat-black
  sheet has luminance near zero and would fail every background.
  Do not use the 49-point grid as acceptance either; it was a
  screening sample, and the facet spec's full scan is the procedure.
  Pass: max pixel at or below 0.0864 on every shot; no borderline
  for a numeric cap. Retest: re-run the full scan on the re-shot
  board area. The sampling-vs-proof question is settled by the facet
  spec: full scan is the acceptance procedure, and a sampling screen
  during iteration does not constitute acceptance.
- Colourblind shield check: layered. Layer 1 (screen): DeepSeek's
  8-viewer simulated panel per shot, both simulations, pass 7 of 8
  correctly identifying the shield-hit feedback per simulation,
  borderline exactly 6 of 8 on one simulation with no wrong event
  named (hold), fail 5 or fewer or any wrong event on both
  simulations after retest. Layer 2 (confirmation): Qwen's 3 viewers
  with documented deuteranopia or protanopia, 100% of shield-hit
  shots, pass = distinguishable by at least one non-colour channel
  (brightness, shape, motion, outline) with all 3 confirming, 1
  failure fails the shot. Simulations: deuteranopia and protanopia,
  Brettel-Vienot-Mollon model or equivalent, never simple
  desaturation (Qwen). Qwen's team exception carries: team members
  with the relevant deficiency may serve as layer-2 viewers, since
  the condition is rare and the bias is low for a "can you see this
  flash" task. Burden flagged: 11 judgements per shot, though
  shield-hit shots are few, and shield-hit readability is
  gameplay-critical, which is why Qwen's 100% real-viewer coverage
  stands rather than a flagged-shots-only sample. Retest: re-shoot
  only changed feedback, re-run both simulations and both layers;
  shared VFX or material changes re-run every shot using it. Session
  cap 12 simulated images (DeepSeek).

## Cross-test rules (both legs agree)
PNG only, no JPEG. In-game only, never Blender. Desktop frame only,
PC-only ruling. Acceptance log per faction batch: date, anonymised
viewer IDs, shot filenames, per-viewer results, timestamps for the
three-second test, findings. Ryan receives the log with the manifest.

## Worst-handled tests (both kept, different weaknesses)
- Luminance (DeepSeek): a grid sample cannot prove "no pixel." The
  settler is a full-board pixel scan of decoded PNGs with a fixed
  formula, plus Ryan's ruling on whether sampling may stand as
  acceptance (condition 2).
- Faction at a glance (Qwen): the 3-second window flattens hesitation
  into pass and guessing into pass, and panel composition (genre
  familiarity) swings the rate. The think-aloud diagnostic above and
  the proposed 15-viewer / 5-second comparison study are the
  settlers; until that study runs, the at-a-glance numbers are
  provisional scaffolding.

## Conditions
1. Panel scale: the merged table's 7-viewer scaling is the chair's
   proposal, not a measured standard. Ryan rules it, or rules up to
   DeepSeek's 12s (high rigor) or down to Qwen's 5s (lightest). The
   structure (per-unit, hard returns, hold) stands regardless of
   scale.
2. Luminance acceptance basis: SETTLED by the landed luminance facet
   synthesis. Full scan is the acceptance procedure; a sampling
   screen during iteration does not constitute acceptance.
3. Gold reference crop source: Ryan names the 1 already-accepted PC
   desktop PNG crop (DeepSeek's requirement). Without it the gold
   test cannot run.
4. Facet-spec reference: SETTLED by the landed luminance facet
   synthesis. Its swatch reference (sRGB 128, 0.2159) and full-scan
   procedure replace both this spec's 49-point grid and its
   provisional 3-patch reference. There is one luminance procedure.
5. Provisional state: hold for retest, not conditional pass, per the
   structure section above. If Ryan keeps conditional pass, it takes
   DeepSeek's strict naming requirements and still cannot override
   an OBSERVED manifest-return finding.

## Recommended next step
Ryan rules the two owner questions: panel scale (chair recommends
the merged 7-viewer table) and provisional state (chair recommends
hold, not conditional pass), and names the gold reference crop
source. Opus cannot make these calls; everything else in this spec is
ready to implement once they are ruled.

## Not checked
- The 18-plate luminance audit (enabled by the facet spec, not yet
  run).
- Actual reviewer availability at any panel scale.
- Full-scan tooling (decoder, formula implementation, operator).
- The at-a-glance 15-viewer / 5-second comparison study.
