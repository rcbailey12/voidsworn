# Backlog check of queued Codex jobs: chair synthesis (issue 189)

Verdict: GO WITH CONDITIONS. All 18 issues were checked against FINDINGS R82 to R103 and the LOOP.md queue state in the pack. Thirteen run as written. Five need edits before they run: #24, #27, #92, #100 and #169. No issue is closed and none is merged into another; the two scope collisions are handled as edits to the loser, not merges, because both losing issues keep real work of their own.

Legs: blind Rey leg first (legs/rey_blind.md, written from the pack before the other legs), DeepSeek (legs/deepseek.md, DeepThink and Search ON), Qwen (legs/qwen.md, gates PASS on Qwen3.8-Max before submission and after generation), Argon review (legs/argon_review.md, Argon High before and after). Where legs disagreed, section 6 says what the chair took and why.

## 1. Verdict table

| Issue | Verdict | Reason |
|---|---|---|
| #24 Progression step 7, Nemesis teaching loop | needs edits | Written against the single-Nemesis model; R85 keys lessons per commander (Q3) and puts the clock on the active commander (Q5) |
| #26 Progression step 10, un-gate Heat | current | No R82 to R103 row touches Heat or the R63 payout rates |
| #27 Progression step 11, telemetry | needs edits | Its Nemesis counters collide with #122, which owns them under R85 |
| #29 Progression step 13, tree rollout | current | No R82 to R103 row touches tree content or the rollout |
| #30 Progression step 14, capstone mastery | current | No R82 to R103 row touches the 320/440/600 XP thresholds |
| #41 Crusade captured hulls from run 3 | current | R78 Q9 stands; its unnamed dependency is a queue finding, not a text edit |
| #42 Chorus core eating in sector 3 | current | R78 Q15 stands; its blocker #22 is missing from the queue, flagged below |
| #44 Run 5 finale board brightens | current | R78 Q18 stands; its blocker step 12 is missing from the queue, flagged below |
| #92 Debrief screen | needs edits | Blocker line only: it omits the data dependency on #24 and #122 (R85 Q3) |
| #100 Terrain fx 2 | needs edits | Its blocker #60 is parked, and it has no note for #139's supersession of shared gas work |
| #120 Nemesis redesign 1, registry | current | Matches R85 Q1, Q2 and Q4 (the clock, Q5, belongs to #121, not #120; see section 6) |
| #121 Nemesis redesign 2, meetings and clock | current | Matches R85 Q2, Q3 and Q5, and already carries the R101 NEM_VOICE addition |
| #122 Nemesis redesign 3, telemetry and panel | current | Matches R85; it is the rightful home of the counters #27 also claims |
| #139 Graphics leap 3, nebulas and storms | current | Matches R88 and R90; the deaths and weapons queue question is a finding, not a text defect |
| #140 Graphics leap 4, planets | current | Matches R88 and R90 order and scope |
| #169 Breakable Pyre-Barge | needs edits | Its gate and build spec still say round 5; R103 moved the pick to round 6, and R99 replaced the interior spec |
| #183 Station detail pass | current | Matches R94, R96, R98, R100 and R99 as written; it has already run, PR #190 open and held for Ryan's look |
| #187 Pyre-Barge round 6 | current | Matches R103, R96, R97, R98 and R99; the #188 conditional covers the paint standard either way |

## 2. Exact edits for the five issues

### #24 Progression step 7

Edit 1, blocker. Stale text: "Blocked until the feel-pass fixes merge; Opus unblocks steps in order."
Replacement text: "Blocked until the feel-pass fixes merge and Nemesis redesign part 2 (#121) merges; Opus unblocks steps in order. This step builds on the per-commander model from R85, not the single-Nemesis model it was written against."
R rows: R85 Q1, Q3, Q5, plus the queue fact that LOOP.md runs progression before the Nemesis build.

Edit 2, content. Stale text: "Adds the debrief weakness teaching on a lost meeting (Q5), and rewrites meeting fiction and UI language to own the mandatory once per sector status, with the clock as accelerant only (Q3)."
Replacement text: "Adds the debrief weakness teaching on a lost meeting, keyed to the active commander the meeting was with (R85 Q3; the per-commander lessons themselves land in #121). Rewrites sector map and meeting UI language to own the mandatory once per sector status for the sector's assigned hunter, with the one run-level clock paced by the active commander (R85 Q5). Commander spoken lines are not rewritten here: they are the adopted NEM_VOICE table, wired in #121 (R101)."
R rows: R85 Q3 and Q5; R101.

Edit 3, test. Stale text: "Test: a lost meeting still adds one taught weakness to the debrief, and the sector map names the meeting as certain rather than chance."
Replacement text: "Test: a lost meeting still adds one taught weakness to the debrief, recorded against the commander who fought it, and the sector map names the meeting with the sector's assigned hunter as certain rather than chance."
R rows: R85 Q1 and Q3.

Edit 4, outcome line. Stale text: "Ryan sees: losing to the Nemesis still teaches him something, and the map stops pretending the meeting might not happen."
Replacement text: "Ryan sees: losing to the sector's assigned hunter still teaches him something, recorded against that commander, and the map stops pretending the meeting might not happen."
R rows: R85 Q1 and Q3.

### #27 Progression step 11

Edit 1, scope. Stale text: "Adds Nemesis escape and compounding counters (Q6) and per run XP earnings by line to the campaign save, extending the existing per battle play log."
Replacement text: "Adds per run XP earnings by line to the campaign save, extending the existing per battle play log. The Nemesis escape and compounding counters are not built here: they are built in #122, a run-level escape counter and a per-commander compounding counter under R85, and a second counter set here would be replaced by that work."
R rows: R85; #122's Done when as the queue fact. Correction to the blind leg, which wrote both counters as per-commander: only the compounding counter is per-commander; the escape counter in #122 is run-level. The verdict does not change.

Edit 2, test. Stale text: "Test: a simulated batch of runs produces a summary with an escape rate, a compounding rate, and median XP per run per line."
Replacement text: "Test: a simulated batch of runs produces a summary with median XP per run per line. Escape and compounding rates are read from the counters #122 builds, not from a second counter set here."
R row: R85.

### #92 Debrief screen

Edit 1, blocker (the only edit). Stale text: "Blocked behind the feel-pass fixes in the queue."
Replacement text: "Blocked behind the feel-pass fixes in the queue, and behind #24 and #122: the loss debrief must show the taught weakness from #24 and the per-commander lessons from #122 (R85 Q3), so this screen is finished after that data exists."
R row: R85 Q3, plus the queue fact (LOOP.md items 5, 7 and 8).
No Done when edit: Qwen and Argon are right that the existing conditional ("every panel the design lists that is already backed by data") covers the panels once the queue moves, so no copy text is stale. The blind leg's Done when edit and its inference about the unseen debrief synthesis are dropped.

### #100 Terrain fx 2

Edit 1, blocker. Stale text: "Blocked until the gas half and the backdrops debris pass (#60) merge, since all three touch the debris and gas code."
Replacement text: "Blocked until the gas half merges and Ryan decides the backdrops debris pass (#60): its PR #143 is parked under his hold and cannot merge until he unparks it. If he closes #60 instead, the debris tasks are re-scoped against the current code before this runs. Blocked behind #139 as well: any task here that the #139 FogVolume build supersedes is dropped, per the note in #139."
Facts: the LOOP.md hold on PR #143; R88 and R90 for the #139 scope.

Edit 2, wreckage kit line. Stale text: "Build on the ship-derived wreckage kit from #60 rather than replacing it."
Replacement text: "If #60 lands, build on the ship-derived wreckage kit from #60 rather than replacing it. If #60 is closed, say so in the PR and build the debris tasks on the current wreckage code instead."
Fact: the same parked PR #143.
Explicitly not adopted: DeepSeek's claim that section 7 task 10 is the quality ladder owned by #139 (the terrain synthesis is not in the pack and nothing there says so; R82 Q5 calls the colour-ramp port the last task), and Qwen's claim that #139 could supersede or replace #60's debris kit (#139's deliver-to list has no world_rocks.gd and no debris work; its supersession covers the shared gas and world_living work only).

### #169 Breakable by design

Edit 1, brief. Stale text: "the round 5 result (#163) for which Pyre-Barge hull is kept"
Replacement text: "the round 6 result (#187) for which Pyre-Barge hull Ryan picks"
R row: R103.

Edit 2, blocker. Stale text: "Blocked until round 5 (#163) picks the hull, the game-side fallback (#167) lands, and the Muse method (#171) merges."
Replacement text: "Blocked until Ryan picks a hull from round 6 (#187) and the game-side fallback (#167) lands. The Muse method (#171) has merged (R99), so that condition is already met."
R rows: R103, R99. Correction to DeepSeek and Qwen, which both treat #171 as an unmerged queue item: R99 ruled on #171's delivered synthesis (PR #174). Only #167 is a Codex build blocker missing from the queue.

Edit 3, Done when. Stale text: "the kept round 5 Pyre-Barge hull gets real hull thickness, a few internal decks and bulkheads, and two or three authored break lines with matching interior faces and damage textures (soot, scorched structure, glowing torn edges handled by the #167 shader)"
Replacement text: "the Pyre-Barge hull Ryan picks from round 6 (#187) gets the R99 build: rim bands at the break lines and openings plus a dark inner liner on the intact ship, which stays inside the R96 ceiling; full decks and bulkheads only inside the break pieces; and two transverse break lines plus one longitudinal, with matching interior faces and damage textures (soot, scorched structure, glowing torn edges handled by the #167 shader); damage masks live inside the R96 paint graph (R99 Q3)"
R rows: R99 Q1, Q2 and Q3; R103.
Cosmetic: the brief line cites only R97 and R98; add R99 and R103 to that citation when the edits are applied.

## 3. What the current verdicts were checked against

- #26: all of R82 to R103 for any row touching Heat, difficulty dials or XP payouts (none does); its authority R63 Q13 is pre-R82 context no yardstick row supersedes.
- #29: R93 and R95 (they change Ashgrove's opening fleet and Thale's fleet composition and doctrine numbers, not tree content), R85 (no Nemesis scope), and its dependency on Step 2's machinery, which the progression order preserves.
- #30: R82 to R103 for XP economy changes (none; R93 is win-rate balance), and the queue, which runs #29 before it as its capstone content requires.
- #41: R98 (breakable by design binds new or rebuilt hulls; a captured hull kept through the Cinder Line yards is an existing hull, INFERRED no conflict), R85 and R101 (no Nemesis scope), and R78 Q9, which no yardstick row restates.
- #42: R99 Q4 (Chorus bone and flesh is a hull build rule for break pieces, not the core-eating mechanic), R85, and R78 Q15.
- #44: R85 Q4 (the finale uses the same SP3 draw; that governs which commander appears, not the board brightening), R88's effects order, and R78 Q18.
- #120: line by line against R85 Q1 (draw per story point from the five non-player factions, no consecutive repeats, SP1 returns at SP3 about 1 in 4), Q2 (per-commander state) and Q4 (no arch-nemesis rule). The clock, Q5, is #121's, not #120's; the blind leg and DeepSeek both miscited it there and the synthesis corrects the citation, not the verdict.
- #121: R85 Q2, Q3 and Q5 (per-commander adaptation with the clash check preserved, lessons on the commander, one clock paced by the active commander, a strike brings the meeting forward), and R101: the Nov 4 addendum already contains the NEM_VOICE paste, the nemSay wiring and the Eclipse fall_final key.
- #122: R85 Q3 (on a return, the panel shows that commander's scars and lessons) and #27: #122 is the per-commander home for the escape and compounding counters, which is why the fix lands on #27 and not here.
- #139: R82 Q1 and Q2 (fixed violet family, faction tint capped at about 25 percent on the ramp ends, hulls crisp inside gas), R88 (engine volumetrics route) and R90 (storm and explosion lights in fog at max tier only, density pulse at high, none at low). Its "the current path at low" reads as R90's "none at low" meaning no fog-light effect at low tier, INFERRED, not a conflict.
- #140: R88 and R90 (terran and barren or rocky first, then volcanic desert, gas and ice giants unchanged) and the queue, which runs it after #139, matching the R88 order of nebulas and storms before planets.
- #183: R94 (locked shapes, additions only), R96 (the paint stack), R98 as qualified by R100 (truss and gantry members take damage decals instead of interior faces), R100 (the about 20k triangles and 0.35 ms target, 40k to 45k and 1.0 ms hard ceiling, counted first), and R99 (its footer already reports effort in Codex runs). "Current" here means the run was specified correctly: PR #190 is open and held for Ryan's look per LOOP.md.
- #187: R103 (both variants ordered by the ruling, the simple paint spec matching Ryan's words: big plates, two or three tones, dark recesses, red for trim and light only, grain cut), R96 (the about 306k triangles and 3.9 ms ceiling, both numbers to be reported), R97 (V3 parked unless cut to the ceiling; R103 is the later ruling that orders exactly that cut), R99 (effort in Codex runs; the one-hour line in the text is the run cap R99 itself sets, not an estimate), and the closing conditional, which correctly defers to the #188 readable-paint standard if it has merged and stands without it if not.

## 4. Dependency and order findings

1. The Nemesis group is queued after the work it replaces. LOOP.md item 7 runs progression steps #24, #26, #27, #29, #30 before item 8 runs #120, #121, #122. But #24 and #27 were written against the pre-R85 Nemesis and touch the same files and functions (#121 names nemNodeIs and campaign_run.js; so does #24). Affects #24, #27, #120, #121, #122. Fix: run the Nemesis block first (section 5); the progression steps keep their relative order behind it.
2. #92 is queued before its data exists. LOOP.md item 5 finishes the debrief screen; the taught weakness (#24, item 7) and per-commander lessons (#122, item 8) land after it. Affects #92, #24, #122. Fix: move #92 behind both.
3. #100's blocker is parked, not pending. PR #143 (#60 debris) is open and parked under the owner's hold ("Unpark only if Ryan asks"); LOOP.md item 6 already notes "#100 terrain fx 2 (needs #60 decided)". Until Ryan decides, #100's debris half has no start condition. Affects #100 and #60. Fix: put the #60 decision in the queue as a gate in front of #100 (section 5) and ask the owner question (section 7).
4. The "feel-pass fixes" blocker is named by six issues and itemised nowhere. #24, #26, #27, #29, #30 and #92 all block on "the feel-pass fixes", but the LOOP.md queue order in this pack contains no entry with that name, so no queued item visibly releases them. Affects all six. INFERRED from the queue text supplied; if the feel-pass fixes live inside another queued issue, LOOP.md should say which one. DeepSeek's claim that #139 and #140 are the feel-pass fixes is not backed by anything in the pack and is cut.
5. The tail group's blockers sit outside the queue. #42 blocks on core sync (progression step 5, #22); #44 blocks on progression step 12 and later; #41 blocks on "the progression steps it depends on" without naming them. None of #22, step 12, or #41's steps appears in the LOOP.md queue order, and steps 8, 9 and 12 are likewise absent from the check list while step 13 (#29) is queued behind in-order unblocking. Affects #41, #42, #44 and #29. Tolerable while the three sit in "later, not yet scheduled", but when any of them is scheduled, its blocker must be verified landed or added to the queue first.
6. #169's text and the queue cite different gates, and the queue omits #167. LOOP.md item 9 gates #169 on Ryan picking a round 6 hull; #169's own text gates on round 5 (#163), which picked nothing (R103). The corrected text is in section 2. Separately, #169 also blocks on the game-side fallback #167, which LOOP.md omits from the queue and the gate. Affects #169 and #187 (whose held PR is the pick #169 waits on, which is correct and should stay). #171 is not a missing dependency: it merged and was ruled on as R99.
7. Shared scope in godot/world/world_living.gd and the gas code: #139 (FogVolumes) and #100 (terrain fx tasks) both build there. The queue order (#139 before #100) is the right order; the defect is only that #100's text lacks #139's supersede note. Fixed by the #100 edits in section 2. #139 does not touch debris or world_rocks.gd, so its supersession does not cover #100's debris tasks or #60's wreckage kit.
8. Shared scope in campaign_run.js and the debrief data: #24 (teaching), #92 (screen) and #120 to #122 (model, behaviour, panel) all land in the Nemesis and debrief area. The corrected order in section 5 sequences model first (#120, #121, #122), teaching second (#24), screen last (#92), so no layer is built on a shape the next layer replaces.
9. Deaths and weapons are missing from the queue ahead of #139. R88 orders deaths and weapons before nebulas and storms; R90 names the graphics leap builds #137 to #140. The LOOP.md queue order jumps from ship work (#183, #187) straight to #139 with no deaths and weapons step. This is a queue-completeness check for Opus, not a verdict change on #139 or #140: LOOP.md state elsewhere shows deaths work in flight as #185, so Opus confirms whether #137 and #138 are done or queued before #139 is released.
10. Minor: LOOP.md numbers two consecutive entries "3" (#187 and #139) in the extract supplied. Cosmetic, but the queue is the loop's single source of order (R102), so the numbering should be clean. Affects nothing's position.
11. Minor: the check list itself is one step behind the board. It names #183 among jobs "that have not run yet"; PR #190 shows it has run and is held for Ryan's look. No action beyond noting it, since its text checked out as current.

## 5. Proposed corrected queue order

1. #183 station detail (already running; PR #190 held for Ryan's look)
2. #187 Pyre-Barge round 6 (PR held for Ryan's pick)
3. #139 nebulas and ion storms (after the deaths and weapons check in finding 9)
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
15. #169 breakable Pyre-Barge, as edited (after Ryan picks the round 6 hull from #187, and after #167)
16. #41, then #42, then #44 (later group, relative order unchanged)

Moves from the current order, one line each:

- #120, #121, #122 move from after the progression group (item 8) to before it: R85 rebuilds the Nemesis model that #24 and #27 assume, so the steps must build on the new model instead of being rewritten by it.
- #24 keeps first place inside the progression group but now lands after #121: its teaching has to key to the active commander and the per-commander lessons #121 creates (R85 Q3).
- #27 does not move; it shrinks. Its Nemesis counters transfer to #122, which already builds them per commander, and #27 keeps only the XP by line work nobody else owns.
- #92 moves from item 5 to after #24 and #122: the screen's loss layout needs the taught weakness and the commander lessons as data, and building it earlier guarantees a second pass.
- #100 keeps its place after #139 but gains an explicit gate: Ryan's #60 decision (PR #143 is parked, so "wait for the merge" is not a condition that can ever fire on its own).
- #169 does not move; only its text changes, from the round 5 gate R103 overtook to the round 6 pick the queue already states, and its queue entry gains #167.
- #41, #42, #44 do not move: nothing in R82 to R103 disturbs them, and their blockers get verified when they are scheduled, not before.
- #183, #187, #139, #140 do not move: their order already matches R103 (#187 after #183) and R88 (storms before planets) and the two PR holds, subject to finding 9.

## 6. Where the legs agreed and disagreed

Agreement: all three writer legs mark #24, #27, #100 and #169 as needing edits, #26, #29, #30, #41, #42, #44, #120, #121, #122, #139, #140, #183 and #187 as current, and the Nemesis block as needing to run before the progression steps. All three agree #100 is gated on the parked #60 and needs a supersession note for #139.

Disagreements, resolved here:

- #92: the blind leg says needs edits (blocker plus Done when); DeepSeek and Qwen say current, because the Done when conditional ("every panel the design lists that is already backed by data") absorbs the per-commander change. The chair sides with Qwen on the Done when and with the blind leg on the blocker: verdict needs edits, one edit only, the blocker line. Both Qwen and DeepSeek still recommend moving #92 behind the Nemesis block in the queue.
- #27's replacement text: DeepSeek's version both adds the counters in #27 and defers them to #122; the chair takes the blind and Qwen versions (counters out, XP by line stays), with Argon's correction that the escape counter is run-level and only the compounding counter is per-commander.
- #100's supersession scope: DeepSeek removes a "quality ladder" task it cannot name from the pack (cut); Qwen lets #139 supersede debris work #139 never touches (cut). The chair takes the blind version: supersession covers shared gas and world_living work, debris stays with #60.
- #169's blockers: DeepSeek and Qwen both list #171 as unmerged and missing from the queue (cut; R99 ruled on its merged synthesis). Only #167 is missing.
- #60's pick: the blind leg says unpark for a look, DeepSeek says unpark and merge, Qwen says keep parked until #139 lands. The chair takes the blind pick, with Qwen's caution as the condition (section 7, Q1): #139 does not touch debris, so waiting for it tells Ryan nothing about the debris kit, and the look is what unblocks #100's scoping.
- Argon quotations: two Argon quotations do not match the filed legs, and one does not match the filed issue text. The blind leg's queue bullet reads "R88 (storms before planets)", not the longer wording Argon quotes; #24's line reads "the map stops pretending the meeting might not happen", not "was a one-off"; and #24's issue text reads "with the clock as accelerant only (Q3)", not the longer phrase Argon quotes. The underlying points (the deaths and weapons queue gap, the stale "the Nemesis" line, the NEM_VOICE warning) are carried on other legs' evidence, but the quotations themselves are flagged here so nobody cites them.

## 7. Owner questions (five, with chair picks)

1. The #60 debris pass (PR #143) is parked under your hold, and #100 is written to build on its wreckage kit. Unpark it for a look, or keep it parked and leave #100 parked with it? Pick: unpark it for a look. #139 will not change the debris picture (it touches no debris code), so waiting for #139 buys nothing on this question, and the look is one review round that decides whether #100's debris half has a kit to build on or needs re-scoping.
2. Approve running the Nemesis build (#120, #121, #122) ahead of the progression steps, so steps 7 and 11 build on the R85 per-commander model instead of the old single Nemesis? Pick: yes. The alternative is paying for the same nemNodeIs and debrief work twice, once on each model.
3. Keep #24 (the Nemesis teaching loop) as its own step after #121, or fold it into #121? Pick: keep it separate. Its sector map language and teaching test are a distinct, testable step, and #121 already carries behaviour, adaptation and the R101 voice table.
4. Approve #92 (debrief screen) sliding behind #24 and #122, which delays the finished debrief screen until its Nemesis data exists? Pick: yes. The screen built first would need a second pass the moment per-commander lessons land, and the design's copy set predates R85.
5. Apply the section 2 edits and the section 5 queue order now, via Opus (issue edits are Opus's lane under this job's block)? Pick: yes. The edits are mechanical and rest on rulings already made (R85, R99, R101, R103); nothing in them needs a new owner call.

## Not checked

- The terrain fx synthesis and the debrief screen synthesis themselves: neither is in the pack, so no claim about their internal section numbers is carried into this synthesis.
- The live states of #137, #138 and #167 beyond the pack's LOOP.md extract: finding 9 is a queue-completeness check for Opus, not a claim about their current state.
- Live board state after pack time: PR #190, PR #191 and the LOOP.md holds are as stated in the pack; Opus verifies them when applying the edits.
