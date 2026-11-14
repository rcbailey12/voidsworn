# opus_check_643: PR 643 (issue 642), the Eclipse paint stack on E11 and E12

Refs #256

**Verdict: GO WITH CONDITIONS, no BLOCKING against PR 643.** Council: blind Rey, DeepSeek, Qwen, Flash, all GO WITH CONDITIONS; Grok's seat is empty (grok.com bot wall, two windows across the evening, recorded here rather than filled). PR 643 is merged (head 3be6d6a045, merge 8022b031). Two legs (DeepSeek, and the second of Qwen's two responses) reach for a BLOCKING grade on condition 1; both scope it fix-forward, and Qwen's second response states it plainly: it does not block this PR's output, it blocks the next reliance on check_export clearance. The chair adopts that scope as the condition's wording.

## What the chair verified directly

- The glow_vertex fix is in the merged code exactly as the arm described (tools/blender/kits/eclipse/stack.py lines 206-235): ps_glow and ps_kind are both created first, then re-looked-up by name and written with one foreach_set each, with the hazard comment at the fix. The cause account (handle taken, second attribute added, storage reallocated, 5.3 survived and 4.5 crashed later in the bake) is consistent with the opus642out_b crash signature.
- check_export.py's classification (tools/recipe/check_export.py, line ~164): a primitive whose material extras carry hull_surface is skipped from the parts set PT (breach clearance, BREACH_CLEAR 0.030) but stays in T, so points on the trim still count as on the mesh.
- Who sets the marker: the Eclipse stack's GLOW_HULL path is narrow (GLOW_HULL = ('corona',); glow_material(hull=True) marks only that zone's hull material). The wide path is shared: paint_stack.py line ~813 marks the whole merged engine glow surface hull_surface when any object in the engine glow group has role 'hull' and GLOW_HULL is non-empty. Eclipse's ENGINE_GLOW extra_zones ('corona', 'ecore', 'lens') put the engine rings, the core and the lens in that group alongside the hull rim strips, so all of them leave PT.
- check_export_selftest.py has no hull_surface case (grep-verified; its broken cases are no_slot, off_mesh, backward, wrong_side, no_core).
- The shared hooks sit behind hasattr/getattr guards with the old defaults, engine_glow_nodes falling back to _throat_glow, GLOW_HULL defaulting to empty (paint_stack.py, read on main).
- The ps_glow classification question two legs raised is closed: the ps_glow MATERIAL flag is set only by the Eclipse stack's glow_material (eclipse/stack.py line 201); the shared machinery sets it on no material, and Hullbreaker glow surfaces were already classified by name (p3_glow, p3_ember) before this PR. So the new ps_glow branches in surface_check.py (line 31) and density.py (line 58) change nothing for A16 or A17.
- The stale job files E11_E12_PAINT_642.bat and q_paint_642.bat are both still on main (raw fetch 200) next to the 642c pair.

## Conditions

1. **The hull_surface exemption is wider than its intent, and the widening is unpinned.** The rim line exemption itself is right: painting split the line out of the hull material and turned a passing ship into a failing one (3 anchors at 0.011 to 0.023 against 0.030), and the marker restores the pre-paint classification. But the merged-surface marking also exempts the engine rings, the core and the lens, which the unpainted export measured as parts, under a comment that says only "the hull's own glowing trim". Fix: mark per material as the GLOW_HULL path already does, or split the hull-role glow surface out of the merged engine surface; if the Board prefers the merged behaviour, write the wider rule down where the marker is defined so it is a decision. Until this is narrowed or ruled on, treat it as blocking the next export or paint job that relies on check_export clearance, and any other stack adopting GLOW_HULL. It does not touch the paint, and a fix confined to the GLOW_HULL-gated branch cannot disturb the Hullbreaker byte proof.
2. **Pin it in the selftest, and re-prove E11.** Add the pair to check_export_selftest.py: a hull_surface trim primitive within BREACH_CLEAR of an anchor passes; an unmarked part primitive within BREACH_CLEAR fails. Then re-run check_export on E11 and E12 with the narrowed marker and confirm the 3 anchors still pass on the rim-line exemption alone.
3. **Delete or re-point the stale 642 job files** (E11_E12_PAINT_642.bat, q_paint_642.bat), which point at the pre-fix branch that crashes Blender 4.5. Unanimous across the council; the arm's "do not queue them" note is not a guard.

## Notes

- Hullbreaker unchanged: A16 byte-compared twice, on the pass-2 code under 5.3 (256 atlases, 2 samples) and on the FINAL code under Blender 4.5 by the PC arm (512 atlases, 2 samples), all 8 maps plus emission identical both times. A17 cannot be byte-proven because its build varies run to run on main itself (131 vs 130 hull objects, disclosed by the arm); its unchanged claim rests on the defaults reading, which this check verified. The A17 nondeterminism is main's own and worth its own investigation; it is not PR 643's defect.
- opus642out_c is the load-bearing PC proof (same PC and Blender 4.5.14 that crashed twice on out_b; stages 4 to 7 and every check passing on both ships; Ryan's in-game reads followed, R243). Its files live on the PC, not in the repo. Cheap improvement for next time (Qwen): drop the run's commit SHA, Blender version, log tail and check summaries into the issue, so the proof is re-openable evidence rather than a report.
- Three gates now special-case the glow class (surface_check counts ps_glow as glow, density skips ps_glow, check_export exempts hull_surface). Each is defensible alone; one short table in RECIPE.md saying which gates apply to glow surfaces would make the total coverage visible (Qwen).
- The corona-at-170, E12 ring-segment lines, core-green and aligned-panels items are round 3 scope under R243, already briefed, and were not graded here.

## Leg record

- Blind Rey: GO WITH CONDITIONS (marker width, selftest, stale bats as a note).
- DeepSeek: GO WITH CONDITIONS; it heads its two items "BLOCKING items / conditions" (the marker width, the stale bats). Slips recorded: the arm's A16 compare ran at 512 atlases and 2 samples, not "512/4"; its opus642out_c section invents details not in the evidence ("3.171 crash-free run", a docs/status outcome file, a SHIP/PAINT/PT/PC list). Nothing rests on them.
- Qwen: returned TWO complete responses to one prompt (an A/B preference prompt; neither was selected). Both GO WITH CONDITIONS. Response 1 grades the marker a condition; response 2 grades it a fix-forward BLOCKING scoped to the next reliance, which the chair adopted as condition 1's wording. Slips recorded: response 1's "glow_vertex.py" (it is a function in eclipse/stack.py); response 2's "fixed at the marking site in check_export" (the marking site is paint_stack.py; check_export only reads the flag). Both responses are filed with the check's working papers.
- Flash: GO WITH CONDITIONS, conditions matching 1 to 3. One slip: it credits opus642out_c with the arm's own 4096-atlas / 64-sample settings; the pack attributes those numbers to the arm's run, and out_c's settings are not in the evidence.
- Grok: seat empty. Both of its windows on Nov 13 were stopped by grok.com's bot wall ("Your request was blocked") before any sign-in; the pack was never sent. Not a skip and not a substitution.

## Not checked by the chair

- sheet_fixture_hash.py --check re-run (PASS claimed by both workers; no repo checkout in the sandbox).
- opus642out_c logs and outputs (on Ryan's PC only).
- The stage logs behind the PR body's sandbox proof (no Blender in the sandbox).
- Whether E12's anchors pass on the rim-line exemption alone; that is condition 2's re-run.
