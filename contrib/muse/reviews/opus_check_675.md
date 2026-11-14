# opus_check_675: PR 682 (issue 675), the R240 Hullbreaker fixes

Refs #256. Outside check by the council: blind Rey leg first, then DeepSeek, Qwen
and Flash legs on the same pack, Rey chairing. Grok's seat is empty (see the leg
record at the end). PR 682 is merged: merge sha
737c8cf0fe37dedb7b6ae53d6a04bddbc61b3097, head
50c8e74ddc3608cac654546212e6ebf9eea8bfbf, 118 files, +487 -238. Five commits:
the API Opus arm's build (ae778adb3a), a merge of main, the Board's A16 fixture
rebuild (211338cdf7), the Board review commit (45d9d0db14) and the final merge.

Ryan's three R240 notes (Nov 13, 2026): guns still sat behind or facing
satellite dishes and antennae; the armour plates and patchwork sometimes read
super even and ordered; a weird paint pattern sat in the opening of the
carrier. The PR answers all three: a new SENSOR clash check plus design fixes
on all five ships, an opt-in patchwork warp in the shared paint stack, and a
rebuilt A20 hangar mouth.

## Verdict: GO WITH CONDITIONS, no BLOCKING

All four legs land GO WITH CONDITIONS; no leg found a defect in the merged
output. DeepSeek grades two evidence gaps "BLOCKING for sign-off" and Flash
files one gap under a "Blocking / Defect Items" heading while calling it a
fix-forward operational condition in the same breath; the chair grades all of
them as conditions below, for the reasons each condition states. The PR is
merged and issue 675 is closed; these conditions are for the Board's
acceptance record and its follow-on work, not a request to reopen the merge.

## Conditions

1. Done-when (4) still needs its evidence. The brief asked for sandbox proof
   stages 4-7 passing for all five ships with the surface check at 0 px, and
   paint pictures re-rendered with before and after of patchwork and mouth.
   The pictures are in the PR; no stage log or surface-check record for the
   five paint runs is anywhere in the repo. The PC paint job is Board-queued
   separately, so this is not a defect in the PR's output, but the R240 work
   should not be called fully done until those logs land. (All four legs.)

2. The arm's run record ends at exit 1 with no explanation, and there is no
   final report. The arm's run_all_checks shows every suite PASS except
   tree_effects_test, "FAIL: timed out after 300 s". That is a JS rules test
   and PR 682 touches no JS or rules code, so the timeout does not read as
   caused by this PR; but the arm left no final report ("see board log on the
   PC"), so nothing in the repo ties the five commits to the done-when
   criteria or explains the one failing suite, and the Board merged on an
   exit-1 record. The Board should rerun tree_effects_test or record it as
   known baseline noise, so the next reader does not have to take the
   unrelatedness on faith. (All four legs; Qwen puts the missing final report
   itself under this condition.)

3. Two small hardening items on the new checks, both cheap. (a) The SENSOR
   check's header in clash.py reads as an exact volume test; the test is
   sampled (a 5x5x5 lattice over each padded sensor box), and the header
   should say sampled so a future reader does not over-trust a pass. (b) The
   patchwork warp is opt-in by design, which is right for faction isolation,
   but a future Hullbreaker-like stack that forgets patch_warp silently gets
   the even grid the R240 note complained about. A stack guard (a check that
   fails when the Hullbreaker stack loses the key, or an assertion at stack
   load) closes that hole. RECIPE.md now names the three keys and states that
   zero gives the old grid, which covers the documentation half. (Rey and
   DeepSeek raise both halves; Flash notes the silent fallback; Qwen grades
   the opt-in correct and the forget-risk a documentation concern, and the
   chair agrees the shape is right and asks only for the guard.)

4. The two texts state different cell-size ranges for the same warp. The
   _warp docstring in paint_stack.py says cells run between about a third and
   three times the mean size; the Hullbreaker LAYERS comment says patch_warp
   .55 makes plates roughly two thirds to twice the mean. The chair checked
   the construction: the warp displaces each cell coordinate by
   (noise - 0.5) x 2 x amp, so at amp .55 a boundary moves at most 0.55 cells,
   and neither stated range is derivable from the code without the noise
   gradient. One text should be corrected to match what the Board intends the
   setting to mean. (DeepSeek.)

## The SENSOR check

The check is sound, and its conservatism points the right way. Chair-verified
against the merged code on main:

- Records now carry kind (clash.py line 60), and kit.py line 652 stamps
  part_kind on every part object, so the sensor set (dish, antenna, mast) is
  complete by construction rather than by name-matching.
- Per gun it takes the slot arc from ARCS, the elevation band from the fit
  data, forces up to +Z for casemate and spinal mounts, pads the sensor box
  by the gun's calibre, and tests out to env = 0.6 x ship length (line 153).
  It samples a 5x5x5 lattice over the padded box and records a hit per
  5-degree bearing bucket. Testing the box rather than the mesh errs toward
  flagging, which is the safe bias for this rule.
- What it can still miss: a thin sliver of firing volume threading between
  lattice points (the pad widens the target and keeps this unlikely, not
  impossible), sensors in the gun's own group (skipped by design), and a gun
  barrel physically fouling a sensor without its firing volume crossing it,
  which is outside the stated rule. What it over-flags is box corners and
  empty dish volume, accepted by all legs as the right trade for a gate.
- The five fixes are design fixes, not check-gaming, and the pass is
  measured, not asserted. Chair-read from each ship's fit.json on main:
  A16 SENSOR 0 over 192 tested pairs and 16 guns; A17 0 over 96 pairs, 8
  guns; A18 0 over 6 pairs, 1 gun; A19 0 over 45 pairs, 5 guns; A20 0 over 18
  pairs, 2 guns; every other clash count 0 on all five. The fixes: A16's AN1
  antenna cut 1.8 to 1.5 tall; A17's neck barbettes raised 0.14, T1 lifted
  onto a new 0.55 barbette (1.52 to 2.07) and both saddle antennas cut; A18's
  T1 onto a 0.4 barbette and AN1 cut 0.66 to 0.45; A19's D2 dish moved inboard
  (y -0.55 to -0.3), out of S5's aft arc; A20's both dorsal turrets onto
  barbettes (rings at deck +1.05 fore, +0.92 aft, from guns at deck +0.34 and
  +0.36) and AN1 moved off the aft deck tier and cut 1.3 to 1.0. No threshold,
  arc or pad was loosened anywhere. (All four legs agree.)

One cosmetic note (Rey): entries are recorded per bearing bucket, so one
physical intrusion can read as several clash lines. It overstates counts in a
failure report, never a pass; worth a dedupe only if the Board finds the
reports noisy.

## The patchwork

The construction is the right attack on the note and the opt-in shape is
right. Chair-verified: the pre-R240 grid survives verbatim as _grid_even in
shared paint_stack.py; the new _grid returns it whenever patch_warp is absent
from the stack's LAYERS, so the Eclipse stack, which defines no patch_warp,
paints exactly as before (the Board review commit 45d9d0db14 states the same,
and the chair confirmed no other caller of _grid or _seams exists outside
paint_stack.py). When the key is present, the grid warps each axis by 1D
noise, cuts z into patch_band bands whose edges step every few columns, shifts
x columns per band and per y strip, shifts y cells per x column and z rows per
(x, y) column, and splits a patch_split share of cells once more at a random
place. Hullbreaker sets patch_warp .55, patch_band 2.3, patch_split .55.

On the brief's word "never": no leg, and not the chair, will certify that no
viewer could ever spot a locally regular run in a seeded-random grid. What the
construction does is remove every systematic source of evenness the old grid
had, on five independent axes at once. The catch for a chance alignment is the
re-rendered sheet pictures and the queued PC paint job, which is where
condition 1's evidence lands anyway. (DeepSeek and Qwen both make this point;
the chair adopts it as the honest scope of the claim, not as a defect.)

## The A20 mouths

The patterned fit-out is gone. Chair-verified from the diff: the rail ties
(the ladder pattern) are deleted; rails, ceiling beams, side ribs and the
inner door frame are built in the dark material; ribs and beams are spaced by
random.Random(seed=7) amounts with early termination at the back wall; the two
evenly placed ceiling lamps are replaced by three small lamp pieces at uneven
seeded depths by the floor edge. The mouth zone moves from the striped
iron_bay to a new iron_edge zone (base iron, rust .45, metal .55, rough .62,
wear 1.0, scuff 1.0, no trim, no patchwork) while the ('bay', 'iron') mapping
still points at iron_bay, so striping survives where it belongs and only the
mouths lose it. The sheet text now reads "a dark deep bay, worn torn plate
rim, dark launch rails, beams and ribs, three warm deck lights, an inner
blast door", which matches the code. The parallel launch rails read as
structure once the ties are gone (Qwen). The lamp arithmetic checks out:
LAMP_RGB (232, 150, 74), strength .9, linear red 0.80 x 0.9 = 0.72, under the
0.8 glow threshold and beside the running lights' 0.77; surface_check.py's
GLOW tuple gains p3_lamp so the surface check classifies lamp pixels as glow.

Two notes. The kit-view lamp entry in kit.py (colour (1.0, 0.55, 0.22) at
strength 2) is a different surface from the stack's render material at .9;
nobody found it subject to the 0.8 threshold, but one comment line saying so
would stop the next reader asking (Rey, Qwen). And the inner blast door's
surface treatment beyond "dark" is not described in the diff; nothing in the
code patterns it, and the render under condition 1 is the check (Qwen).

## A16 and A17 confinement

Done-when (2) holds. The chair compared the Hullbreaker LAYERS before and
after: no colour, tone or other LAYERS value changed; the additions are the
three patch_warp keys and the new iron_edge zone for A20's mouths. A16 and
A17's paint change is the grid order only, and their sensor fixes are geometry
(antenna heights, barbettes), so Ryan's "a bit dark, keep tone and colours,
change only the order" is respected as far as code evidence goes. Visual
confirmation rides on the same pictures and paint job as condition 1. (All
four legs.)

## Anything else the evidence shows

- The A16 fixture rebuild (211338cdf7) follows from the antenna change: the
  unpainted fixture C19_51 is the ship's own geometry, and the Board rebuilt
  it by the sheet_fixture_hash steps. Issue 683 (stable seeds, the A17
  run-to-run variance first noted in opus_check_643) was closed separately by
  PR 685 and is out of this check's scope.
- Documentation landed with the change (R214): ships.md gains the R240
  paragraph and the SENSOR rule; RECIPE.md stage text and the kinds list are
  updated to match.
- The arm left no final report for the second check running (665's arm filed
  one). Not a condition on this PR beyond condition 2's record point, but the
  Board may want the standing expectation from opus_check_665 (arms flag what
  they change and report) extended to reports themselves.

## Leg record

- Blind Rey: GO WITH CONDITIONS, no BLOCKING. Raised the sampled-header
  wording, the silent opt-in fallback, the _warp "never turns back" claim
  being asserted rather than proven, the kit lamp strength split, the
  tree_effects baseline confirmation and done-when (4) as NOT CHECKED.
- DeepSeek (DeepThink on, Search off, verified before and after): GO WITH
  CONDITIONS, no confirmed defect; grades done-when (4) and the tree_effects
  timeout as "BLOCKING for sign-off" evidence gaps, chaired as conditions 1
  and 2. Caught the two-range inconsistency in condition 4.
- Qwen (Qwen3.8-Max verified in the selector before sending and in the header
  after; single response, no preference pair this run): GO WITH CONDITIONS,
  no BLOCKING. Conditions: the stage 4-7 evidence and the missing final
  report; the tree_effects timeout recorded as an observation only.
- Flash (Gemini, "Quick answers 3.5 Flash-Lite" verified in the picker before
  and after; pack pasted as text, since Gemini's upload control does not open
  a file dialog in this browser): GO WITH CONDITIONS. One wording slip: it
  says the mouth fit-out uses "the dark liner zone (iron_edge)", conflating
  the dark fit-out material with the iron_edge rim zone; the pack and the code
  keep them distinct and nothing in its verdict rests on the conflation.
- Grok: seat empty. grok.com showed its bot wall ("Your request was blocked")
  on the cloud browser; the runner waited, reloaded once and stopped per its
  instructions, and the pack was never sent. Third consecutive empty Grok
  seat (issues 670 and 643 before this one). Recorded as an empty seat, not
  substituted.

## NOT CHECKED

- The stage 4-7 paint runs and the surface-check 0 px result for the five
  ships (condition 1; the Board's queued PC job is the source).
- The rendered look of the new patchwork and the A20 mouths beyond the
  re-rendered build-sheet pictures in the PR; whether any local patch run or
  door face still reads as patterned is a judgement for those pictures and
  the paint job.
- The cause of the tree_effects_test timeout (condition 2); the chair
  verified only that PR 682 touches no JS or rules files.
- The board log on Ryan's PC, which the arm's commit points to in place of a
  final report.
- The Board's Eclipse round 3 job (corona at camera 170, real panels, core
  colour), briefed separately on Nov 13, 2026; nothing in this check speaks
  to it.
