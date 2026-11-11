# Outside check: PR #336 (issue 209 round 6, the ship recipe)

Refs #256. Head checked: opus/issue-209-r6 at fabe653d. Scope: the board's four questions on the recipe, the shared plumbing and the one-pass audit. Council: blind Rey leg first, then DeepSeek, Qwen (Qwen3.8-Max, gate verified before and after), Flash and Grok legs on the same evidence pack; the chair verified every decisive citation against the PR head before adopting it. Verdicts across the council: blind Rey GO WITH CONDITIONS, Qwen GO WITH CONDITIONS, Grok GO WITH CONDITIONS, DeepSeek NO-GO, Flash NO-GO. The two NO-GO verdicts rest on the same audit findings as conditions 1 and 2 below (Flash also on stage 5 genericity, which the chair treats as question 4 scope). The chair's verdict follows.

## Verdict: GO WITH CONDITIONS

The plumbing split is real and the recipe is a genuine step: one shared module with no look of its own, one faction kit, seven stages with a worked example. What does not hold yet is the audit's evidentiary chain. The PR's sentence "Audit: 1,207 parts, none floating, none across a break line, 12 barrels, none aimed backward or into the ship" is stronger than what the recipe's own audit run can show, for two independent reasons (conditions 1 and 2). Both fixes are small and the data for both is already written into the blend at build time.

## Question 1: can the recipe run from a fresh clone on the PC?

Mostly, on this PC. OBSERVED: env.bat hardcodes three installs outside git (Blender 4.5.14 and Godot 4.7.2 under Downloads\voidsworn_test, the TRELLIS.2 venv under Downloads\trellis2) and no stage checks that they exist; RECIPE.md never names them as prerequisites. On Ryan's PC they are installed, so the run works; the "runs from any clone" sentence in RECIPE.md is true only with that footnote.

One real ordering defect, OBSERVED: stage 1 runs ship.py's concept command, which needs Pillow (tools/recipe/ship.py lines 22 to 24: on a missing PIL it prints "Pillow missing" and exits 1). Pillow is installed only by stage 3's guard line in 3_trace_hull.bat. On a fresh Blender Python, stage 1 therefore fails, and 1_concept_in.bat does not check the error level: it echoes "Stage 1 done" unconditionally. Stage 3 runs the same concept command after its install guard, so the design intent is visible; stage 1 is simply ahead of the bootstrap. Latent on this PC (Pillow is already installed there), live on any fresh one. See condition 3.

Quiet carry-ons, OBSERVED across the council's lists, chair-verified on the load-bearing ones: env.bat leaves HULL, CELL and the tune path as empty strings when the ship json or its fields are missing (ship.py's get prints an empty string); stage 2 prints "Stage 2 FAILED" when the shape reference is still missing but does not exit with a failure code (2_shape_ref.bat, final lines); stage 3 calls sil_dump.py on the shape reference path %B0% with no existence check, so a skipped or failed stage 2 surfaces only inside log_b0dump.txt while the bat continues into tracing and tuning; stage 4 never checks that the build produced %JOB%\build\%CELL%.blend before opening it for the audit (4_parts_kit.bat lines 6 to 7), and types audit.json without gating on its contents; stage 6 echoes done without checking the export or the glb. The good half stands too: stage 1 refuses loudly on a missing concept webp, stage 3 refuses loudly on a missing hull module name, stage 5 checks the baked blend exists.

## Question 2: is the R151 rule kept?

Yes, unanimously across the council and the chair's own read. OBSERVED: tools/blender/kits/shared/plumbing.py holds scale classes, the Socket/Seat/resolve seating machinery, frame and size helpers, the tag and gun registries, and the audit. It creates no meshes, defines no materials and names no colours; the shape primitives it relies on (box, cyl, loft) come from the older shared hs_lib. The Hullbreaker kit (kits/hullbreakers/kit.py and paint.py) holds the shapes and the paint; it is imported only by the Hullbreaker hull module and bake path; no other faction kit exists yet to need it. paint.py imports r209's paint3 helpers, which is shared tooling, not another faction's look.

One structural NOTE: plumbing.audit() imports common from tools/blender/r209 for its break-line defaults and bvh helper (plumbing.py, audit body). The shared module therefore silently depends on the round-209 module and on defaults that belong to an earlier ship. That dependency is the root of condition 1.

## Question 3: does the audit test what the PR claims?

Partly. Backward aim is tested as claimed, and the floating and break-line machinery exists and runs. Two halves of the claim do not survive contact with the recipe's own audit path.

BLOCKING (condition 1): the recipe audit checks crossings at break lines this ship does not have. OBSERVED: plumbing.audit(hull_objs, part_objs, guns, t_lines=None, l_line=None) falls back to common's module defaults when the caller passes nothing: T_LINES = (.10, -.22) and L_LINE = (-.02, -.22, .10). OBSERVED: the C15s hull's own break data (the BREAK chain in tools/blender/r209/armA6.py, from armA5) is t_lines (.178, -.125) and l_line (-.045, -.125, .178). OBSERVED: the bake path is safe, because bakeAb6.py calls PB.audit in the same Blender process after set_break ran (armA6.py line 88), and set_break also writes the ship's lines into scene properties r209_t_lines and r209_l_line. OBSERVED: tools/recipe/audit.py (stage 4, a fresh process) calls PB.audit(hull, parts, guns) at its line 13 with no t_lines, and it already reads one scene property (r209_guns, line 12) while ignoring the two break-line properties sitting beside it. So the audit.json of record certifies "none across a break line" against x = .10 and -.22, lines that are not this ship's breaks (.178 and -.125 are never tested). The numbers in the PR body came from the bake run and are probably right; the recipe's standalone audit cannot reproduce them.

BLOCKING (condition 2): the "or into the ship" half is never tested by any audit artifact. OBSERVED: plumbing.aim_ok (lines 48 to 53) carries the mount-normal test, and kit.build returns PB.audit_guns() applying it, which the hull module records as the build note guns_badly_aimed. OBSERVED: plumbing.audit() itself tests guns only for a backward aim (d.x < -.05). OBSERVED: the recipe path cannot test it at all, because armA6.py line 93 converts the registry's (name, aim, normal) triples into (name, aim) pairs, line 107 serialises only those pairs into r209_guns, and audit.py rebuilds exactly those pairs. The into-the-ship result therefore lives only in an ungated build note that never reaches audit.json. A reader of audit.json sees a gun count and a backward check, and the PR sentence claims more.

NOTE on floating: a part is excused from the hull-distance test if it overlaps any other part (plumbing.py: "if k in touching or T.overlap(...): continue"), so a cluster of parts bolted to a floating base passes unmeasured; the distance test itself samples about 150 vertices per part against a .002 threshold. "None floating" is stronger than this test; worth a sentence in the round 6 README or a tightening of the test.

NOTE on the barrel count: plumbing.audit() does not count guns; audit.py line 13 adds the count itself (au['guns'] = len(guns)). The "12 barrels" figure is the caller's, not the audit's. Harmless, but the PR sentence attributes it to the audit.

## Question 4: what would a second ship of another faction need?

Beyond the two items RECIPE's own table names (the hull block table still per-ship Python, and the A4 game export), OBSERVED:

1. The faction's own kit and paint. Only kits/hullbreakers/ exists; RECIPE's table lists the other five kits as next work. This is the largest single item.
2. A generic stage 5. 5_paint_bake.bat calls tools/blender/r209/bakeAb6.py by name for every ship, and bakeAb6 wires the Ab6 geometry and imports the Hullbreaker paint module. As written, a second faction's ship cannot run stage 5, which sits awkwardly beside RECIPE's stage table presenting stage 5 as generic plumbing. Either the table or the stage needs the correction.
3. Its break lines carried as data into the audit (condition 1 generalises): today they live in the hull module's BREAK plus common.py's stale defaults.
4. The admitted per-ship data: a sockets json measured off its concept, the concept webp in docs/ship_pipeline/concepts/, a TRELLIS shape reference, a fitted concept camera and tune numbers (stage 3 creates both when empty), and a shape_ref_yaw; the ship template ships C15s's 22.0 as every new ship's default, which should be labelled as such.

## Conditions

1. audit.py must test the ship's own break lines: read r209_t_lines and r209_l_line from the blend (they are already written by set_break) and pass them to PB.audit, or pass the ship's BREAK explicitly. Until then the recipe's audit.json does not support the break-line half of the PR's audit sentence.
2. The into-the-ship test must land in the audited artifact: carry the mount normals in r209_guns and run aim_ok inside the audit path, or write the build's guns_badly_aimed result into audit.json and gate stage 4 on it. Until then "none aimed into the ship" rests on an ungated build note.
3. Move the Pillow and scipy install guard ahead of stage 1's concept call (env.bat or 1_concept_in.bat), so stage 1 cannot report done on a failed concept write and the fresh-clone claim holds on a machine without them.
4. Stage 4 should stop on its own failures: check the build blend exists before auditing, and treat a non-empty problems list or crossing list in audit.json as a failed stage rather than typing the file and continuing. Stage 3 should likewise refuse to run the b0 dump when the shape reference is missing.
5. Reconcile RECIPE's generic stage table with stage 5's hardcoded bakeAb6 (name the step per-ship, or make the bake script ship-selected).

Standing board practice applies as usual: the board runs the PC capture before merge; nothing in this check ran the recipe or the game.

## Screening notes (chair)

Two leg claims were checked against the sources and rejected, recorded here so the board does not chase them. (a) A suggested tuple-shape crash in bakeAb6's audit call: armA6.py line 93 converts the gun registry to (name, aim) pairs before bakeAb6.py line 150 passes them, so the call is shape-correct. (b) Two batch-file transcription claims (a doubled redirect token in 5_paint_bake.bat, a malformed copy line in 7_export.bat): the files at the PR head read correctly (an append redirect, and copy /y "%JOB%\glb\%CELL%*.*"); both were artefacts of the evidence pack's rendering. One leg did not compare the audit's break-line defaults against the ship's BREAK values; conditions 1 and 2 rest on the chair's reading plus three concurring legs.

## Not checked

- silhouette4.py's gate maths and the 90.0 percent outline figure; tune5 and b0trace internals.
- The Godot bench numbers (twenty ships at 1.19 ms GPU at 4K) and the 125,616 triangle / 4 surface figures for Ab6.
- The round 6 sheets' visual claims; the owner already ruled on the sheets.
- Whether every r209 helper script the stages call is in git; the stages were read, not run.
- hs_lib's primitive library and trellis_fleet.py internals.
- Any faction kit other than Hullbreakers; none exists in the PR.
