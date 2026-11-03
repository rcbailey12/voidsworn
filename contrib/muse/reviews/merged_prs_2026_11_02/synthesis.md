# Merged PRs of Nov 2, 2026: second review (Issue #86)

Chair: Rey (Muse). Base: main at 80307a2 (includes all 15 merges and FINDINGS R81).
Scope: PRs #10, #14, #32, #35, #36, #38, #39, #46, #47, #63, #64, #68, #69, #83, #85.

## Headline

GO WITH CONDITIONS. No shipped-code bug was found that breaks a rule or a save.
Two small certain fixes are made on this branch (one save-sanity gap, two stale
doc passages). One item needs an in-engine check by Opus (listed under Bigger
items). The DeepSeek, Qwen and Argon legs named in the issue block have since
run from the main chat (Nov 3, 2026) and are filed under legs/ in this folder;
the Leg outcomes section below gives the chair's response to each. The verdict
stands unchanged. DeepSeek's headline attack on the saneMeta fix was checked
against the code and is rebutted with file evidence; Qwen confirmed every
verdict and the fix, and added one design question, now Bigger item 3; Argon
(ideas and risks only, R81) converged with the chair's notes and added risks
of its own.

## Evidence run by the chair

- Full standing checks on current main in this VM: `node contrib/opus/tools/run_all_checks.js`
  exited 0. findings_tests shows only the 46 baselined known failures, none unexpected.
- The five new suites were also run one by one and pass: effect_caps_tests
  (215 sum fixtures, 4 derive fixtures), nemesis_clash_tests (12,330 cases),
  free_exit_tests (32 exits), lineage_tests, shadow_xp_tests.
- Oracle copies are byte-identical to their sources at HEAD (cmp): battle.js,
  core.js, data.js and campaign_meta.js against both oracle folders.
- Godot was not run in this VM (no Godot binary here). Godot-side claims rest on
  code reads plus the PC check results in the PR bodies, and are marked INFERRED
  where that matters.

## Verdicts, one per PR

1. PR #10 (issue #5, Command wording): CLEAN. Text only, and the new wording
   matches the rules it describes. Mirrored correctly: godot/rules/rules.gd
   cmdDesc uses "launch ship" and "if there are open adjacent hexes, even past
   its hangar limit", and both regenerated tables (godot/rules/data/tables.json,
   godot/campaign/data/campaign_tables.json) carry the new scramble text and
   not the old carrier text (checked by string search, OBSERVED).
2. PR #14 (issue #11, price tests for balance v2): CLEAN. Test values match
   data.js at HEAD (b3_tests and r1_tests pass). Note: the r1 FS-2 check now
   computes the Eclipse battleship price from FAC_PRICE through the shipyard
   rounding instead of comparing table entries directly. It still pins 590
   against the 415 cruiser, so the guard holds, but it would not catch a
   FAC_PRICE edit that kept the product at 590. Chair judges that acceptable.
3. PR #32 (issue #16, playtest fixes batch 1, resumed from a partial patch):
   FINDINGS, one item for Opus (Bigger items, item 1) and the batch 1 section
   of godot/fx/API.md was later superseded by PR #85 (docs fixed on this
   branch, see Fixes). The rest reads clean: blocker coverage is presentation
   only, the world bake cache keys include seed, settings, shader source and
   dimensions, and hull debris cuts real loaded hulls on a worker that is
   joined at tree exit (per godot/fx/API.md batch 1 section and the diff).
4. PR #35 (issue #17, playtest fixes batch 2): CLEAN, one note. The glide
   rewrite keeps F2 timing (gl_ds rescaled to the new curve length in
   godot/render/ship_view.gd play_glide) and the removed peak-acceleration
   fields (gl_apk, gl_ypk, gl_fpk, gl_spk) have no remaining references
   (grep, OBSERVED). Note: godot/fx/fx_weapons.gd torp_strike now clamps
   torpedo flight time to 0.85 to 1.25 s, so a point-blank torpedo flies
   longer than its distance implies. That is a pacing change wearing a
   clarity fix's clothes; the chair accepts it, Opus may veto.
5. PR #36 (issue #33, b1 onboarding tests): CLEAN. The tests now evaluate the
   real TIPS table instead of regex-scraping ui3d.js, which is stricter than
   what they replaced. b1_tests passes, 39 ok.
6. PR #38 (issue #18, progression step 1, effect caps): CLEAN. The cap clamp
   landed in all three ports: core.js:189 (sumFx), godot/rules/rules.gd:301
   and godot/campaign/campaign.gd:486 (sumFx), with FX_CAPS added to the
   campaign REQUIRED_TABLES. Clamping after summing means penalties offset
   bonuses in any order (fixture cases cover both orders). Single effects
   stay intact per the fixture suite.
7. PR #39 (issue #37, flaky b4 Nemesis check): CLEAN. Root cause is real:
   nemAfterBattle can reveal the torp weakness at random, and a revealed
   torp weakness correctly blocks the pd adaptation the test then asserted.
   The fix seeds the RNG (rndSeed(37), exported for the test) and pins
   N.weak to ['flank','slow']. b4_tests passes, 29 ok.
8. PR #46 (issue #23, progression step 6, Nemesis clash): CLEAN. Tests only,
   no shipped code changed (OBSERVED from the diff: two new test files).
   12,330 browser cases pass here; the Godot fixture replay exists at
   godot/campaign/test/nemesis_clash_test.gd.
9. PR #47 (issue #40, export smoke fails closed): CLEAN. godot/render/ship_view.gd
   gains _exit_tree, which detaches render instances only under the headless
   or dummy renderer, the exact case the issue describes, and returns early
   otherwise. `meshes` is the view's own array (ship_view.gd, OBSERVED).
10. PR #63 (issue #19, progression step 2, Glasswright lineage slice): CLEAN.
    This is one of the two PRs where Codex was cut off; the chair read the
    full browser and Godot implementations side by side. lineageBuild
    validates stored picks the same way in both ports (sequential per
    branch, tier exists, choice is 0 or 1, capped by level), respec pricing
    and between-runs gating match, and lineage_tests passes, including save
    round-trip and the other factions staying at level 4. The trunk display
    uses MASTERY_XP thresholds, which equal LINEAGE_XP for levels 1 to 4
    (0, 6, 16, 30, 50 in data.js:583 and the LINEAGE_XP table), so no
    visible mismatch (OBSERVED).
11. PR #64 (issue #25, progression step 8, free exits): CLEAN. Tests only
    (two new files). The browser suite drives the real event picker and the
    real ACT handlers for every fight event and faction at 0 and 120
    credits, and passes here.
12. PR #68 (issue #49, playtest fixes batch 3): CLEAN, one note. Damage
    staging now matches FINDINGS R80 (open break only at stage 4) in
    godot/fx/fx_ship.gd, engine trails are world-space per the fb3 brief, and
    no references to the removed TRAIL_LEN, TRAIL_RELAX or trail "dirty"
    flag remain (grep, OBSERVED). Note: the campaign map backdrop no longer
    uses the NEB_SHEET shader; the shader string remains defined in
    godot/ui/campaign/map3d_shaders.gd, unused. Harmless; Opus can delete
    it whenever.
13. PR #69 (issue #50, unguarded fxText): CLEAN. The guards are systematic
    typeof checks on every fx and animation entry point in battle.js (the
    acid tick that caused the flake is battle.js:393 at HEAD). After this
    PR, a grep of battle.js finds no remaining unguarded call to fxText,
    fxShield, fxShieldBreak, fxCrit, fxWithdraw, fxRam, fxBoard, animWeapon,
    animMove or animRotate outside try blocks and definitions (OBSERVED).
    Both oracle copies updated in step.
14. PR #83 (issue #20, progression step 3, shadow XP and heir naming):
    FINDINGS, one small bug, fixed on this branch (Fixes, item 1). The rest
    reads clean and mirrors well: the overflow pool redistribution
    terminates (each pass either spends the pool or caps at least one
    benched line), heir naming is gated to the debrief state in both ports
    (heirDebrief in campaign_meta.js, page kind and RUN null check in
    godot/campaign/campaign.gd ACT_nameHeir), duplicate endRun calls can no
    longer pay twice, and the importer fixtures under
    contrib/muse/tools/importer_fixtures were updated in step, which is
    correct and easy to miss.
15. PR #85 (issue #77, deaths): FINDINGS, docs only, fixed on this branch
    (Fixes, item 2). The code matches the issue: Chorus ruptures instead of
    deflating, ordinary blast kills always break up (hulks are only the
    dark and hulk causes), debris and wreck pieces are locked to the board
    plane, and the new death_plane_check.gd is wired into
    godot/fx/test/check_destruction.bat. The docs did not keep up.

## Fixes made on this branch

1. Save sanity gap from PR #83 (small, certain). defaultMeta gained heirs
   and shadowPool in core.js:50, but saneMeta never learned them, in either
   port. PR #63 set the precedent by adding lineage to the same lists.
   Failure case, reproduced in Node against the shipped code: a meta with
   heirs as a string and shadowPool as a number passes saneSave today, is
   not repaired by migrateMeta, and then shadow XP silently stops
   persisting (the pool write in awardLineageXP no-ops on a number, heir
   naming no-ops on a string). Fix: heirs and shadowPool added to the
   saneMeta key lists in core.js:102, both oracle copies of core.js
   (re-copied, byte-identical), and godot/campaign/campaign.gd:354.
   Regression assertions added to contrib/opus/tools/shadow_xp_tests.js;
   the suite passes with the fix and the malformed meta is now rejected.
2. Stale destruction docs from PR #85 (docs only). godot/fx/API.md:118
   claimed a deterministic fifth of blast deaths become whole hulks; the
   code and death_plane_check say ordinary blast kills always split.
   godot/fx/API.md:360 still described the old Chorus deflate death, and
   the batch 1 check description still said "organic collapse" after the
   check was rewritten for rupture. All four passages now match the code.

## Bigger items for Opus (not fixed here)

1. PR #32, godot/world/blocker_visuals.gd:105 (INFERRED, needs the engine):
   outline() calls mi.look_at_from_position(mi.position, b, ...) with
   local coordinates. look_at_from_position works in global space. If
   build() runs after the blocker node is inside the tree, each outline
   segment gets its global origin set from a local value and lands near
   the world origin instead of on its hex; if build() runs before tree
   entry, the call is harmless and the segments land right. Failure case:
   a set-piece map (planet or station footprint) whose rim segments appear
   at the wrong place. One in-engine screenshot of a station map settles
   it. If it is wrong, the fix is to set the rotation from the edge
   direction directly.
2. Godot fixture replays for the progression steps (effect caps, Nemesis
   clash, free exits, lineage, shadow XP) exist as .gd files but were not
   re-run for this review; there is no Godot binary in Rey's environment.
   They passed on the PC at merge time per the PR bodies. A single
   checkpack run on the PC would close this for the record.
3. PR #83, repair versus reject (raised by the Qwen leg, Finding 4). The
   saneMeta fix rejects a meta whose heirs or shadowPool has the wrong type,
   but migrateMeta does not repair one. A save written during the window
   between the PR #83 merge and this fix, if it somehow carries the wrong
   types, falls back rather than being healed. Chair position: rejection
   matches how saneMeta treats every other malformed container today, and
   the only saves in that window are the owner's own playtest saves, so no
   repair step was added here; it is a design call, not a small certain fix.
   If Opus wants graceful repair, the shape is a migrateMeta step that
   coerces heirs and shadowPool to empty objects when they are not objects.

## Leg outcomes and chair responses

All three legs ran from the main chat on Nov 3, 2026, under the gates in
pack.md (DeepSeek DeepThink plus Search; Qwen on Qwen3.8-Max, both gates
passed; Argon High, verified before and after). The full reports are filed
under legs/ in this folder. Nothing in the chair sections above is a leg's
words.

DeepSeek (hostile code review, legs/deepseek_leg.md). Its headline attack
(F1) claims the saneMeta fix cites the wrong lines and may have edited the
wrong function: core.js:102 is said to be inside repairRunIds, and the Godot
saneMeta is said to sit at campaign.gd:285-289 without the new keys. The
chair re-checked both files directly. REBUTTED: in core.js, repairRunIds is
defined at line 76 and saneMeta is defined at line 102 itself, with heirs and
shadowPool present in its key list on this branch. In
godot/campaign/campaign.gd, repairRunIds starts at line 274 (lines 285-289
are inside it) and saneMeta is defined at line 352, its key list at line 354,
again with the new keys on this branch. DeepSeek read the public tree at
80307a2, which does not carry this branch's fix, and its line reads do not
match the file at that commit either. Its related claim that the regression
test may exercise only the Godot path is also wrong: contrib/opus/tools/
shadow_xp_tests.js is a Node suite over the browser code, and the chair
re-ran it on Nov 3 with the fix in place (PASS). F4 (threshold tables)
ANSWERED with the full comparison DeepSeek asked for: MASTERY_XP at
data.js:583 is [0, 6, 16, 30, 50] and LINEAGE_XP at data.js:591 is
[0, 6, 16, 30, 50, 75, 110, 160, 230]; the two tables agree on every entry
MASTERY_XP has, which is the whole trunk range the display reads, and the
levels 5 to 8 thresholds exist only in LINEAGE_XP, where the branch and
capstone logic reads them. F6 (overflow loop termination) ANSWERED from the
code: the loop is at campaign_meta.js:226-231; each pass zeroes the pool and
returns only capped overflow, a pass with no open line breaks out, and the
shadow rates are the constants 0.25 and 0.5 (heir), never zero, so the
zero-rate case DeepSeek posits cannot occur in shipped data. F7 (FX_CAPS
floors) ANSWERED for the current table: every entry in FX_CAPS
(core.js:175-189) is a positive maximum for an additive effect key; no entry
is a floor. Its latent-trap note is recorded for Opus. F2 agrees with Bigger
item 1. F3, F5, F9 and F10 restate, as findings, four points the chair had
already recorded as notes (the weaker FS-2 guard, the torpedo clamp as an
unowned pacing change, the b4 test making the test deterministic rather than
the game, and the dead NEB_SHEET string); the chair records the disagreement
on grading and holds its verdicts, because none of the four is a shipped-code
defect. F8 (a hypothetical real-renderer CI smoke path) is recorded as a
note for Opus; the PR #47 guard matches the issue as written.

Qwen (code review with weight on PR #63 and PR #83, legs/qwen_leg.md).
Confirms all 15 verdicts and, on the question it was specifically set, finds
the saneMeta fix complete across the ports that exist and no other
defaultMeta container in this batch missing the same treatment. It worked
from the pack and this synthesis rather than an independent repo read, and
says so; its line citations are the chair's. Its one addition is Finding 4,
the migrateMeta repair question, now Bigger item 3 above.

Argon (ideas and risks only per R81, legs/argon_leg.md). Used in full within
its lane; every item cites the pack or this synthesis and it invented
nothing the chair could catch. Most items converge with the chair's notes
(the five-way saneMeta sync, blocker_visuals, the dead NEB_SHEET shader, the
torpedo clamp, the price-test and b4-test caveats, FX API doc drift). Its
additions: the PR #47 cleanup only ever runs under the headless renderer, so
normal sessions get zero coverage from the smoke check; run_all_checks
passing with 46 baselined failures is a false-confidence risk; FINDINGS
rulings and local module docs have no mechanism keeping them in step; PR #10
wording lives in four places that must move together; PR #85's board-plane
locking and always-breakup deaths carry feel risks (flatter explosions, less
silhouette variety) worth the owner's eye on the next playtest.

Branch state note. The review base was main at 80307a2. Main has since
advanced (PRs #89, #90 and #91 merged). Of the six fix files, only
godot/campaign/campaign.gd changed on main in the meantime (PR #91, the
debrief rebuild, working around lines 1408 and later; no overlap with the
saneMeta fix at line 354). The fix was re-applied on top of the current main
version of that file, and the branch diff for it is still the single
saneMeta line. The other five fix files are unchanged on main since
80307a2.

## Not checked

- Godot runtime behavior of any .gd change (no Godot binary in this VM);
  visual results of PRs #32, #35, #68 and #85 beyond their own check files.
- The PC-only checks (Godot parity, campaign parity) were not re-run here;
  the browser-side suites above were.
- PRs merged Nov 2 that are not code PRs in the issue's list (docs and
  design merges such as #73, #74, #84) are out of scope by the block.
