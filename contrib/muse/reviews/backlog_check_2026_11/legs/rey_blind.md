# Backlog check of queued Codex jobs (issue 189): blind Rey leg

Scope: the 18 open codex issues named in the pack, judged against FINDINGS R82 to R103 and the LOOP.md queue state in the pack. Verdicts rest on the pack texts only.

## 1. Verdict table

| Issue | Verdict | Reason (R row or queue fact) |
|---|---|---|
| #24 Progression step 7, Nemesis teaching loop | needs edits | Written against the single-Nemesis model; R85 keys lessons per commander and R101 puts the spoken lines in #121, and #121 rewrites the same nemNodeIs and debrief data |
| #26 Progression step 10, un-gate Heat | current | No R82 to R103 row touches Heat or XP payout rates; its authority (R63 Q13) is pre-R82 context that no yardstick row supersedes |
| #27 Progression step 11, telemetry | needs edits | Its Nemesis escape and compounding counters are the same counters #122 builds per commander under R85; two builds of one counter set |
| #29 Progression step 13, tree rollout | current | No R82 to R103 row changes the tree shape or faction tree texts; R93 and R95 change fleets and doctrine numbers, not trees |
| #30 Progression step 14, capstone mastery | current | No R82 to R103 row sets XP thresholds or mastery rules; queue orders it after #29, which its content depends on |
| #41 Crusade captured hulls from run 3 | current | R78 Q9 stands; no R82 to R103 row restates capture or ransom; its unnamed dependency is flagged in section 4 |
| #42 Chorus core eating in sector 3 | current | R78 Q15 stands; no R82 to R103 row touches core eating; its blocker #22 is missing from the queue, flagged in section 4 |
| #44 Run 5 finale board brightens | current | R78 Q18 stands; R85 Q4 governs the finale draw, not board lighting; unscheduled "later" slot means no queue clash today |
| #92 Debrief screen | needs edits | Queue runs it (item 5) before the debrief data it must show exists: the taught weakness from #24 and the per-commander lessons from #122 (R85 Q3) land at items 7 and 8 |
| #100 Terrain fx 2 | needs edits | Its named blocker #60 cannot merge: PR #143 is parked under the owner's hold (queue fact); and #139's supersede note over shared gas work has no matching note in #100 |
| #120 Nemesis redesign 1, registry | current | Matches R85 Q1, Q2 and Q5 point for point, including the SP1 at SP3 rate and save migration |
| #121 Nemesis redesign 2, meetings and clock | current | Matches R85 Q2, Q3 and Q5, and the Nov 4 addendum already carries the R101 NEM_VOICE paste and nemSay wiring |
| #122 Nemesis redesign 3, telemetry and panel | current | Matches R85 Q3; it is the rightful home of the counters #27 also claims |
| #139 Graphics leap 3, nebulas and storms | current | Matches R82 Q1 and Q2, R88 and R90 (fog volumes, tint cap, lights in fog at max tier only) |
| #140 Graphics leap 4, planets | current | Matches R88 and R90 order and scope: terran and rocky first, then volcanic desert, giants unchanged |
| #169 Breakable Pyre-Barge | needs edits | Its gate and build spec still say round 5; R103 rejected the round 5 paint and sent the hull pick to round 6 (#187), and R99 Q1 and Q2 replaced the blanket decks and bulkheads spec |
| #183 Station detail pass | current | Matches R94, R96, R98, R100 and R99 as written; it has already run, PR #190 open and held for Ryan's look (queue fact) |
| #187 Pyre-Barge round 6 | current | Matches R103 (both variants, the simple paint spec), R96 ceiling and R99 reporting; the #188 conditional covers the paint standard either way |

No issue earns a merge or close verdict outright. One scope transfer comes close: the Nemesis counters move out of #27 into #122, handled as an edit to #27 because #27 keeps real work of its own (per run XP by line).

## 2. Per-issue sections for issues not marked current

### #24 Progression step 7: Finish the Nemesis teaching loop

The step was written when one Nemesis followed the player. R85 replaced that model: a hunter drawn per story point (Q1), adaptations and lessons per commander (Q2, Q3), one run-level clock paced by the active commander (Q5). Issue #121 then rebuilds the exact ground this step stands on: its Done when names "the once-per-sector meeting targets the active commander (nemNodeIs)" and "weaknesses, scars, epithets and debrief lessons attach to the commander". This step's own file list is "campaign_run.js (nemNodeIs, run end debrief data)". Same files, same functions, older model. Run in the current queue order (progression at item 7, Nemesis at item 8), step 7 builds teaching on the single-Nemesis data shape and #121 rewrites it a step later.

Edit 1, dependency and model. Stale text: "Blocked until the feel-pass fixes merge; Opus unblocks steps in order."
Replacement text: "Blocked until the feel-pass fixes merge and Nemesis redesign part 2 (#121) merges; Opus unblocks. This step builds on the per-commander model from R85, not the single-Nemesis model it was written against."
R row: R85 (Q1, Q3, Q5), plus the queue fact that LOOP.md runs progression before the Nemesis build.

Edit 2, lessons keyed per commander. Stale text: "Adds the debrief weakness teaching on a lost meeting (Q5), and rewrites meeting fiction and UI language to own the mandatory once per sector status, with the clock as accelerant only (Q3)."
Replacement text: "Adds the debrief weakness teaching on a lost meeting, keyed to the active commander the meeting was with (R85 Q3; the per-commander lessons themselves land in #121). Rewrites sector map and meeting UI language to own the mandatory once per sector status for the sector's assigned hunter, with the one run-level clock paced by the active commander (R85 Q5). Commander spoken lines are not rewritten here: they are the adopted NEM_VOICE table, wired in #121 (R101)."
R rows: R85 Q3 and Q5; R101.

Edit 3, the test. Stale text: "Test: a lost meeting still adds one taught weakness to the debrief, and the sector map names the meeting as certain rather than chance."
Replacement text: "Test: a lost meeting still adds one taught weakness to the debrief, recorded against the commander who fought it, and the sector map names the meeting with the sector's assigned hunter as certain rather than chance."
R row: R85 Q1 and Q3.

### #27 Progression step 11: Extend telemetry for Nemesis rates and pacing

Half of this step duplicates #122. The redesign's part 3 Done when reads: "a run-level escape counter and a per-commander compounding counter", with "nemSignature tags events with the commander's faction". Those are the counters this step proposes to build, except built per commander, which is what R85 requires (lessons and adaptation state are per commander, Q2 and Q3). If step 11 runs first in the current queue order, it builds run-level counters on the old model and #122 replaces them. The step's other half, per run XP earnings by line, appears in no other issue and stays.

Edit 1, scope. Stale text: "Adds Nemesis escape and compounding counters (Q6) and per run XP earnings by line to the campaign save, extending the existing per battle play log."
Replacement text: "Adds per run XP earnings by line to the campaign save, extending the existing per battle play log. The Nemesis escape and compounding counters are not built here: they are built per commander in #122 under R85, and a second run-level version here would be replaced by that work."
R row: R85 (Q2, Q3), with #122's Done when as the queue fact.

Edit 2, the test. Stale text: "Test: a simulated batch of runs produces a summary with an escape rate, a compounding rate, and median XP per run per line."
Replacement text: "Test: a simulated batch of runs produces a summary with median XP per run per line. Escape and compounding rates are read from the counters #122 builds, not from a second counter set here."
R row: R85.

### #92 Debrief screen: apply the Muse layout and copy on top of step 4

The screen is fine as a design target; its place in the queue is not. LOOP.md runs #92 at item 5. The data a loss debrief must show lands later: the taught weakness from #24 (progression, item 7) and the per-commander lessons from #121 and #122 (Nemesis, item 8), under R85 Q3 ("debrief lessons keyed per commander"). Built at item 5, the screen ships before its most important panel has data, and someone pays for a second pass. INFERRED: the debrief design synthesis predates R85, so its copy set (win, loss, first-ever loss) was written for a single Nemesis and does not name the per-commander teaching block at all.

Edit 1, blocker. Stale text: "Blocked behind the feel-pass fixes in the queue."
Replacement text: "Blocked behind the feel-pass fixes in the queue, and behind #24 and #122: the loss debrief must show the taught weakness from #24 and the per-commander lessons from #122 (R85 Q3), so this screen is finished after that data exists."
R row: R85 Q3, plus the queue fact (LOOP.md items 5, 7 and 8).

Edit 2, Done when. Stale text: "the debrief built in #91 matches the Muse design: its layout at 1920x1080 and 3840x2160, the exact copy for a win, a loss and a first-ever loss, and every panel the design lists that is already backed by data"
Replacement text: "the debrief built in #91 matches the Muse design: its layout at 1920x1080 and 3840x2160, the exact copy for a win, a loss and a first-ever loss, every panel the design lists that is already backed by data, and the Nemesis teaching block on a loss (the weakness the meeting taught, keyed to the commander who taught it, per #24 and R85 Q3)"
R row: R85 Q3.

### #100 Terrain fx 2: debris, dead star well, old looks and the quality ladder

Two defects. First, its gate cannot open: the issue waits on #60 merging, and #60's PR #143 is parked under the owner's hold, with LOOP.md stating "Unpark only if Ryan asks". A parked PR does not merge, so as written this issue waits forever unless Ryan acts; the issue text should say the gate is his decision, not a merge. Second, #139 carries the note "Check #100 (terrain fx 2) against this before it runs; anything here supersedes the matching #100 task", and both issues deliver into godot/world/world_living.gd and the gas code. #100's text has no matching note, so a runner working from #100 alone would rebuild gas work #139 already replaced.

Edit 1, blocker. Stale text: "Blocked until the gas half and the backdrops debris pass (#60) merge, since all three touch the debris and gas code."
Replacement text: "Blocked until the gas half merges and Ryan decides the backdrops debris pass (#60): its PR #143 is parked under his hold and cannot merge until he unparks it. If he closes #60 instead, the debris tasks are re-scoped against the current code before this runs. Blocked behind #139 as well: any task here that the #139 FogVolume build supersedes is dropped, per the note in #139."
R rows and facts: the LOOP.md hold on PR #143 (queue fact); R88 and R90 for the #139 scope.

Edit 2, the wreckage kit line. Stale text: "Build on the ship-derived wreckage kit from #60 rather than replacing it."
Replacement text: "If #60 lands, build on the ship-derived wreckage kit from #60 rather than replacing it. If #60 is closed, say so in the PR and build the debris tasks on the current wreckage code instead."
Fact: the same parked PR #143.

### #169 Breakable by design: Pyre-Barge hull thickness, decks and authored break lines

The R99 rulings block was pasted into this issue on Nov 4, but the older text around it still gates and specifies the job by round 5. R103 rejected the round 5 paint, adopted no round 5 hull, and filed round 6 (#187) to make the pick; LOOP.md item 9 already states the corrected gate ("only after Ryan picks a round 6 hull"). The issue text and the queue disagree, and under the standing rule the R row wins. Separately, the Done when still specifies "a few internal decks and bulkheads" for the hull as a whole, which R99 Q1 replaced: full interiors only in the break pieces, rim bands and a dark inner liner on the intact ship.

Edit 1, brief. Stale text: "the round 5 result (#163) for which Pyre-Barge hull is kept"
Replacement text: "the round 6 result (#187) for which Pyre-Barge hull Ryan picks"
R row: R103.

Edit 2, blocker. Stale text: "Blocked until round 5 (#163) picks the hull, the game-side fallback (#167) lands, and the Muse method (#171) merges."
Replacement text: "Blocked until Ryan picks a hull from round 6 (#187) and the game-side fallback (#167) lands. The Muse method (#171) has merged (R99), so that condition is already met."
R rows: R103, R99. The claim that #171 has merged is INFERRED from R99 ruling on its delivered synthesis (PR #174).

Edit 3, Done when. Stale text: "the kept round 5 Pyre-Barge hull gets real hull thickness, a few internal decks and bulkheads, and two or three authored break lines with matching interior faces and damage textures (soot, scorched structure, glowing torn edges handled by the #167 shader)"
Replacement text: "the Pyre-Barge hull Ryan picks from round 6 (#187) gets the R99 build: rim bands at the break lines and openings plus a dark inner liner on the intact ship, which stays inside the R96 ceiling; full decks and bulkheads only inside the break pieces; and two transverse break lines plus one longitudinal, with matching interior faces and damage textures (soot, scorched structure, glowing torn edges handled by the #167 shader); damage masks live inside the R96 paint graph (R99 Q3)"
R rows: R99 Q1, Q2 and Q3; R103.

## 3. What the current verdicts were checked against

- #26: checked against all of R82 to R103 for any row touching Heat, difficulty dials or XP payouts (none does), against its step position inside the progression group in LOOP.md, and against R99 (no time estimates in the text).
- #29: checked against R93 and R95 (they change Ashgrove's opening fleet and Thale's fleet composition and doctrine numbers, not tree content), R85 (no Nemesis scope), and its dependency on Step 2's machinery, which the progression order preserves.
- #30: checked against R82 to R103 for XP economy changes (none; R93 is win-rate balance), and against the queue, which runs #29 before it as its capstone content requires.
- #41: checked against R98 (breakable by design binds new or rebuilt hulls; a captured Hegemony or Eclipse hull is an existing hull, INFERRED no conflict), R85 and R101 (no Nemesis scope), and R78 Q9, which no yardstick row restates.
- #42: checked against R99 Q4 (Chorus bone and flesh is a hull build rule for break pieces, not the core-eating mechanic), R85, and R78 Q15, which no yardstick row restates.
- #44: checked against R85 Q4 (the finale uses the same SP3 draw; that governs which commander appears, not the board brightening), R88's effects order (deaths and weapons, then nebulas and storms, then planets; #44 sits unscheduled in "later", so no clash today), and R78 Q18.
- #120: checked line by line against R85 Q1 (draw per story point from the five non-player factions, no consecutive repeats, SP1 returns at SP3 about 1 in 4), Q2 (per-commander state) and Q5 (run-level clock), plus the save migration and seed enumeration test in its Done when. R101 does not touch it; the lines are #121's job.
- #121: checked against R85 Q2, Q3 and Q5 (per-commander adaptation with the clash check preserved, lessons on the commander, one clock paced by the active commander, a strike brings the meeting forward), and against R101: the Nov 4 addendum already contains the NEM_VOICE paste, the nemSay wiring and the Eclipse fall_final key, so the newest ruling is inside the text rather than missing from it.
- #122: checked against R85 Q3 (on a return, the panel shows that commander's scars and lessons) and against #27: #122 is the per-commander home for the escape and compounding counters, which is why the fix lands on #27 and not here.
- #139: checked against R82 Q1 and Q2 (fixed violet family, faction tint capped at about 25 percent on the ramp ends, hulls crisp inside gas), R88 (engine volumetrics route) and R90 (storm and explosion lights in fog at max tier only, density pulse at high, none at low). Its "the current path at low" reads as R90's "none at low" meaning no fog-light effect at low tier, INFERRED, not a conflict.
- #140: checked against R88 and R90 (terran and barren or rocky first, then volcanic desert, gas and ice giants unchanged) and against the queue, which runs it after #139, matching the R88 order of nebulas and storms before planets.
- #183: checked against R94 (locked shapes, additions only), R96 (the paint stack), R98 as qualified by R100 (truss and gantry members take damage decals instead of interior faces), R100 (the about 20k triangles and 0.35 ms target, 40k to 45k and 1.0 ms hard ceiling, counted first), and R99 (its footer already reports effort in Codex runs). "Current" here means the run was specified correctly: PR #190 is open and held for Ryan's look per LOOP.md.
- #187: checked against R103 (both variants ordered by the ruling, the simple paint spec matching Ryan's words: big plates, two or three tones, dark recesses, red for trim and light only, grain cut), R96 (the about 306k triangles and 3.9 ms ceiling, both numbers to be reported), R97 (V3 parked unless cut to the ceiling; R103 is the later ruling that orders exactly that cut), R99 (effort in Codex runs; the one-hour line in the text is the run cap R99 itself sets, not an estimate), and the closing conditional, which correctly defers to the #188 readable-paint standard if it has merged and stands without it if not. Pack state says the #188 synthesis is delivered and awaiting merge, and the conditional covers both outcomes.

## 4. Dependency and order findings

1. The Nemesis group is queued after the work it replaces. LOOP.md item 7 runs progression steps #24, #26, #27, #29, #30 before item 8 runs #120, #121, #122. But #24 and #27 were written against the pre-R85 Nemesis and touch the same files and functions (#121 names nemNodeIs and campaign_run.js; so does #24). Affects #24, #27, #120, #121, #122. Fix: run the Nemesis block first (see section 5); the progression steps keep their relative order behind it.
2. #92 is queued before its data exists. LOOP.md item 5 finishes the debrief screen; the taught weakness (#24, item 7) and per-commander lessons (#122, item 8) land after it. Affects #92, #24, #122. Fix: move #92 behind both.
3. #100's blocker is parked, not pending. PR #143 (#60 debris) is open and parked under the owner's hold ("Unpark only if Ryan asks"); LOOP.md item 6 already notes "#100 terrain fx 2 (needs #60 decided)". Until Ryan decides, #100's debris half has no start condition. Affects #100 and #60. Fix: put the #60 decision in the queue as a gate in front of #100 (section 5) and ask the owner question (section 6).
4. The "feel-pass fixes" blocker is named by six issues and itemised nowhere. #24, #26, #27, #29, #30 and #92 all block on "the feel-pass fixes", but the LOOP.md queue order in this pack contains no entry with that name, so no queued item visibly releases them. Affects all six. INFERRED from the queue text supplied; if the feel-pass fixes live inside another queued issue, LOOP.md should say which one.
5. The tail group's blockers sit outside the queue. #42 blocks on core sync (progression step 5, #22); #44 blocks on progression step 12 and later; #41 blocks on "the progression steps it depends on" without naming them. None of #22, step 12, or #41's steps appears in the LOOP.md queue order, and steps 8, 9 and 12 are likewise absent from the check list while step 13 (#29) is queued behind in-order unblocking. Affects #41, #42, #44 and #29. Tolerable while the three sit in "later, not yet scheduled", but when any of them is scheduled, its blocker must be verified landed or added to the queue first. Whether step 12 has landed is load-bearing for both #29 and #44 and is not stated in the pack, INFERRED gap.
6. #169's text and the queue cite different gates. LOOP.md item 9 gates #169 on Ryan picking a round 6 hull; #169's own text gates on round 5 (#163), which picked nothing (R103). The corrected text is in section 2. Affects #169 and #187 (whose held PR is the pick #169 waits on, which is correct and should stay).
7. Shared scope in godot/world/world_living.gd and the gas code: #139 (FogVolumes) and #100 (terrain fx tasks) both build there. The queue order (#139 at item 3, #100 at item 6) is the right order; the defect is only that #100's text lacks #139's supersede note. Fixed by the #100 edits in section 2.
8. Shared scope in campaign_run.js and the debrief data: #24 (teaching), #92 (screen) and #120 to #122 (model, behaviour, panel) all land in the Nemesis and debrief area. The corrected order in section 5 sequences model first (#120, #121, #122), teaching second (#24), screen last (#92), so no layer is built on a shape the next layer replaces.
9. Minor: LOOP.md numbers two consecutive entries "3" (#187 and #139) in the extract supplied. Cosmetic, but the queue is the loop's single source of order (R102), so the numbering should be clean. Affects nothing's position.
10. Minor: the check list itself is one step behind the board. It names #183 among jobs "that have not run yet"; PR #190 shows it has run and is held for Ryan's look. No action beyond noting it, since its text checked out as current.

## 5. Proposed corrected queue order

1. #183 station detail (already running; PR #190 held for Ryan's look)
2. #187 Pyre-Barge round 6 (PR held for Ryan's pick)
3. #139 nebulas and ion storms
4. #140 rocky and terran planets
5. #120 Nemesis redesign 1
6. #121 Nemesis redesign 2
7. #122 Nemesis redesign 3
8. #24 progression step 7, as edited
9. #26 progression step 10
10. #27 progression step 11, as edited (XP by line only)
11. #29 progression step 13
12. #30 progression step 14
13. #92 debrief screen, as edited
14. Ryan decides #60 (unpark PR #143 or close it), then #100 terrain fx 2, as edited
15. #169 breakable Pyre-Barge, as edited (after Ryan picks the round 6 hull from #187)
16. #41, then #42, then #44 (later group, relative order unchanged)

Moves from the current order, one line each:

- #120, #121, #122 move from after the progression group (item 8) to before it: R85 rebuilds the Nemesis model that #24 and #27 assume, so the steps must build on the new model instead of being rewritten by it.
- #24 keeps first place inside the progression group but now lands after #121: its teaching has to key to the active commander and the per-commander lessons #121 creates (R85 Q3).
- #27 does not move; it shrinks. Its Nemesis counters transfer to #122, which already builds them per commander, and #27 keeps only the XP by line work nobody else owns.
- #92 moves from item 5 to after #24 and #122: the screen's loss layout needs the taught weakness and the commander lessons as data, and building it earlier guarantees a second pass.
- #100 keeps its place after #139 but gains an explicit gate: Ryan's #60 decision (PR #143 is parked, so "wait for the merge" is not a condition that can ever fire on its own).
- #169 does not move; only its text changes, from the round 5 gate R103 overtook to the round 6 pick the queue already states.
- #41, #42, #44 do not move: nothing in R82 to R103 disturbs them, and their blockers get verified when they are scheduled, not before.
- #183, #187, #139, #140 do not move: their order already matches R103 (#187 after #183), R88 (storms before planets) and the two PR holds.

## 6. Owner questions (four, each with a pick)

1. The #60 debris pass (PR #143) is parked under your hold, and #100 is written to build on its wreckage kit. Unpark it for a look, or close it and let #100 re-scope debris on the current code? Pick: unpark it for a look. #100's brief assumes the kit exists; closing #60 unread forces a re-scope of #100's debris tasks, while a look costs one review round.
2. Approve running the Nemesis build (#120, #121, #122) ahead of the progression steps, so steps 7 and 11 build on the R85 per-commander model instead of the old single Nemesis? Pick: yes. The alternative is paying for the same nemNodeIs and debrief work twice, once on each model.
3. Keep #24 (the Nemesis teaching loop) as its own step after #121, or fold it into #121? Pick: keep it separate. Its sector map language and teaching test are a distinct, testable step, and #121 already carries behaviour, adaptation and the R101 voice table.
4. Approve #92 (debrief screen) sliding behind #24 and #122, which delays the finished debrief screen until its Nemesis data exists? Pick: yes. The screen built first would need a second pass the moment per-commander lessons land, and the design's copy set predates R85.
