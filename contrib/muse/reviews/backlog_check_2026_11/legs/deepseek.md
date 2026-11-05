# DeepSeek leg (writer), issue 189

Chair screening note (added at filing): raw DeepSeek copy, dash-normalized only. Chair flags, worked through in the synthesis: its #92 verdict (current) misses the per-commander lessons data problem the blind leg catches; its queue puts #92 after #139 and #140 on the claim that those are the "feel-pass fixes", which misreads the blocker (the feel-pass fixes are a separate body of work, itemised nowhere in the queue); its #100 edit names section 7 task 10 as the quality ladder owned by #139, which is plausible but not verifiable from the pack (the terrain fx synthesis is not in it); its #27 replacement text both keeps the counters in #27 and defers them to #122; its #169 edits miss the R99 spec replacement the blind leg catches.

1. Verdict table

| Issue | Verdict | One-line reason |
|---|---|---|
| #24 | needs edits | Step 7's debrief lesson assumes one Nemesis; R85 Q3 keys lessons per commander. |
| #26 | current | Heat gating and payout rates are untouched by R82 to R103; R63 is context, not superseded. |
| #27 | needs edits | Nemesis counters must be per commander under R85 Q2, and the same counters are owned by #122. |
| #29 | current | Tree rollout has no Nemesis, squadron, breakable or paint conflict in R82 to R103. |
| #30 | current | Capstone mastery thresholds are independent of R85, R88 and R98. |
| #41 | current | R78 Q9 capture text is not stale; the vague blocker is a queue finding, not a text edit. |
| #42 | current | R78 Q15 text is not stale; the named blocker #22 is missing from the queue. |
| #44 | current | R78 Q18 text is not stale; the named blocker (step 12) is missing from the queue. |
| #92 | current | Debrief layout and copy are presentation only; step 4 (#91) is landed. |
| #100 | needs edits | Its quality ladder is superseded by #139, which runs first (R88). Blocker #60 is parked. |
| #120 | current | Matches R85 Q1, Q2, Q4 and Q5 exactly. |
| #121 | current | Matches R85 and includes the R101 NEM_VOICE addition. |
| #122 | current | Matches R85; scope collision with #27 noted, but its own text is correct. |
| #139 | current | Matches R88 and R90; queue omits the deaths and weapons step R88 puts before it. |
| #140 | current | Matches R88 and R90; correctly depends on #139. |
| #169 | needs edits | Still waits for round 5; R103 moved the pick to round 6 (#187). |
| #183 | current | Matches R94, R100, R98, R96 and R99; has already run as PR #190. |
| #187 | current | Built directly from R103, R96, R97, R98 and R99; conditional on #188 is handled. |

2. Per-issue sections for every issue not marked current

#24 Progression step 7: Finish the Nemesis teaching loop

Stale text (in the quoted Step 7):

Adds the debrief weakness teaching on a lost meeting (Q5)

Replacement:

Adds the debrief weakness teaching on a lost meeting, keyed to the active commander (R85 Q3, which supersedes Q5's single-Nemesis lesson)

Why: R85 Q3 rules that debrief lessons are keyed per commander. Step 7 still assumes one Nemesis lesson for the run. The rest of Step 7 (the mandatory once-per-sector status and the sector map naming the meeting as certain) remains valid under R85; only the lesson attachment needs the commander key.

#27 Progression step 11: Extend telemetry for Nemesis rates and pacing

Stale text (in the quoted Step 11):

Adds Nemesis escape and compounding counters (Q6)

Replacement:

Adds a run-level Nemesis escape counter and a per-commander compounding counter (R85 Q2, which supersedes Q6's single-Nemesis counters); any Nemesis telemetry also required by #122 is deferred to #122, leaving this step to add per run XP earnings by line

Why: R85 separates the escape counter (run level) from the compounding counter (per commander). Step 11's "counters (Q6)" is the older single-Nemesis shape. Separately, #122 already builds "a run-level escape counter and a per-commander compounding counter" on the same files; keeping both would be duplicate work, so #122 should own the Nemesis counters and #27 should keep the XP-by-line telemetry.

#100 Terrain fx 2: debris, dead star well, old looks and the quality ladder

Stale text (in the Brief):

section 7 tasks 6, 7, 9 and 10

Replacement:

section 7 tasks 6, 7 and 9; task 10 (the quality ladder) is owned by #139 and is removed

Stale text (in the Done when):

the quality ladder in place

Replacement:

the quality tiers owned by #139 (the local quality ladder task is removed)

Why: #139 is "Graphics leap 3: nebulas and ion storms as real volumes (R88)" and its brief says "Check #100 (terrain fx 2) against this before it runs; anything here supersedes the matching #100 task." #139 owns "quality tiers in godot/scenes/battle/battle.gd" and the low, high and max paths. The queue places #139 before #100, so #100 must be trimmed before it runs. The rest of #100's terrain tasks remain current. The blocker #60 is parked, which is a dependency finding below, not a text edit.

#169 Breakable by design: Pyre-Barge hull thickness, decks and authored break lines (R98)

Stale text (in the Brief):

Blocked until round 5 (#163) picks the hull, the game-side fallback (#167) lands, and the Muse method (#171) merges.

Replacement:

Blocked until round 6 (#187) picks the hull (R103: round 5 paint rejected, round 6 filed), the game-side fallback (#167) lands, and the Muse method (#171) merges.

Stale text (in the Done when):

the kept round 5 Pyre-Barge hull

Replacement:

the kept round 6 Pyre-Barge hull

Why: R103 rejects the round 5 paint and files #187 as round 6, and R103 says explicitly that "#169 waits for the round 6 pick." The old text still points at #163. The #167 and #171 dependencies remain correct but are missing from the queue (see findings).

3. Issues marked current: what was checked

#26: Checked against R63 (Heat payout rates, pre-R82 context) and R82 to R103. No row changes Heat availability or the plus 2 XP to the admiral and plus 1 to the shadow pool.

#29: Checked against R85 and R88. Tree rollout touches campaign_meta.js and faction tree content, not Nemesis assignment, squadrons, breakable hulls or paint.

#30: Checked against R85 and R88. Capstone mastery thresholds at 320, 440 and 600 XP are independent of the Nemesis redesign and the squadron rule.

#41: Checked against R78 Q9 and R98. R98's breakable rule applies to new or rebuilt hulls, not to a captured hull kept through the Cinder Line yards. The blocker is vague, which is a queue finding.

#42: Checked against R78 Q15 and R85. The core-eating rule is not touched by the Nemesis redesign. The named blocker #22 is missing from the queue.

#44: Checked against R78 Q18 and R88. The finale board brightening is a world and battle-setup presentation task, not a Nemesis, squadron or breakable task. The named blocker (step 12) is missing from the queue.

#92: Checked against R82 to R103. Debrief layout and copy are presentation only. #91 (step 4) is described as landed in the issue itself. No ruling changes the debrief design.

#120: Checked against R85 Q1, Q2, Q4 and Q5. The hunter draw, commander registry, active-commander lookup, old-save migration and seed marginals all match the ruling.

#121: Checked against R85 and R101. The once-per-sector meeting targeting the active commander, the run-level clock paced by the active commander, per-commander adaptation, per-commander lessons and the added NEM_VOICE instruction all match.

#122: Checked against R85. The run-level escape counter, per-commander compounding counter, Nemesis panel and tests match. Its scope overlaps #27, but its own text is correct.

#139: Checked against R88 and R90. The FogVolume build, split colour ramp, faction tint cap and quality tiers match. The queue omission of deaths and weapons is a finding, not a text problem.

#140: Checked against R88 and R90. The GPU bake for rocky and terran planets matches, and it correctly depends on #139.

#183: Checked against R94, R100, R98, R96 and R99. The additions-only doctrine, triangle and frame-time targets, R98 breakable rule with the R100 truss decal exemption and the no-human-hours line all match. It has already run as PR #190; the PR hold is a board state, not a verdict change.

#187: Checked against R103, R96, R97, R98 and R99. Both variants, the simple paint rules, the V3 cut-down ceiling and the effort reporting all match. The conditional reference to #188 is already written into the issue.

4. Dependency and order findings

#100 is blocked by a parked PR. #100 says it waits for #60. LOOP.md holds say PR #143 (#60) is "parked; unpark only if Ryan asks". This is a parked blocker, not a normal merge dependency.

#100 is partly superseded by #139, which runs first. #139 says "anything here supersedes the matching #100 task." #139 is queue position 3; #100 is queue position 6. #100 must be edited before it runs.

R88's deaths-and-weapons step is missing from the queue. R88 rules: "after the ship work, deaths and weapons come first, then nebulas and storms, then planets." The queue goes from #183 and #187 (ship work) straight to #139 (nebulas) and #140 (planets). No deaths-and-weapons issue appears between them. #139 and #140 therefore run too early against R88.

#169 waits for #167 and #171, neither of which is in the queue. #169's own brief names both blockers. LOOP.md only mentions the round 6 pick. These are missing dependencies.

#42 waits for #22, which is not in the queue. #42 says "Blocked behind core sync (progression step 5, #22)." #22 does not appear in LOOP.md's queue order at all.

#44 waits for progression step 12, which is not in the queue. The queue's progression block is steps 7, 10, 11, 13 and 14 (#24, #26, #27, #29, #30). Step 12 is absent, so #44 has no scheduled unlock path.

#41 names no specific blocker. It says "Blocked until the progression steps it depends on land" without naming a step. LOOP.md parks it under "Later, not yet scheduled." This is an underspecified dependency.

#24 and #27 are Nemesis-related progression steps scheduled before the Nemesis redesign. #24 teaches the Nemesis loop; #27 measures Nemesis counters. Both were written before R85. Running them before #120, #121 and #122 means teaching and measuring the old single-Nemesis system, then reworking both after the redesign lands. This is a wrong order.

#27 and #122 share the same telemetry scope. Both add escape and compounding counters on campaign_run.js and data.js. #122 is the Nemesis redesign's dedicated telemetry issue and has the per-commander shape from R85. #27 should defer the Nemesis counters to #122.

The progression steps must run in order, so moving #24 after #122 moves the whole block after #122. Each progression issue says "Opus unblocks steps in order." If #24 (step 7) waits for the Nemesis redesign, #26 (step 10), #27 (step 11), #29 (step 13) and #30 (step 14) must also wait. This is a dependency chain, not just a local edit.

#183 has run and its PR is held; #187 is correctly after it but also held. This is consistent with LOOP.md, but the holds mean neither PR releases without Ryan. The queue's "release after #183" for #187 is correct.

5. Proposed corrected queue order

The following order covers the 18 issues plus the #60 decision where it bears on #100.

#183 station detail pass. Already run; hold PR #190 for Ryan's look. No change.

#187 Pyre-Barge round 6. After #183, as the queue says; hold its PR for Ryan. No change.

Insert the deaths-and-weapons work (not in the 18) before #139. R88 requires deaths and weapons before nebulas and storms. This is a missing step, not a move of an existing issue.

#139 nebulas and ion storms. Still after the ship work; now also after the deaths-and-weapons step required by R88.

#140 rocky and terran planets. After #139, per R88 and the issue's own dependency.

#92 debrief screen. After the feel-pass fixes, as its own blocker text says; #139 and #140 are those fixes.

Decide #60 (PR #143) and then run #100. #100 cannot run while #60 is parked. If #60 is unparked and merged, #100 can run with the edits in section 2.

#100 terrain fx 2, edited. After #139 has run, so the quality-ladder task is removed; after #60 is decided.

#120 Nemesis redesign 1. Moved before the progression block so the new assignment and commander registry exist first.

#121 Nemesis redesign 2. After #120; includes the R101 NEM_VOICE paste.

#122 Nemesis redesign 3. After #121; owns the per-commander telemetry that #27 would otherwise duplicate.

#24 progression step 7, edited. After #122 so the teaching loop describes the redesigned Nemesis and the per-commander lesson (R85 Q3).

#26 progression step 10. After #24, preserving step order.

#27 progression step 11, edited. After #26; Nemesis counters are deferred to #122, so this step keeps only XP-by-line telemetry.

#29 progression step 13. After #27, preserving step order.

#30 progression step 14. After #29, preserving step order.

#169 breakable Pyre-Barge, edited. After #187 picks the round 6 hull, and after #167 and #171 (both missing from the queue) land.

#41, #42 and #44 remain later, not yet scheduled. #42 needs #22 (core sync) in the queue; #44 needs step 12 in the queue; #41 needs a named progression step before it can be scheduled.

Reasoning per move: moves 1 and 2 keep the ship work first and honor the holds. Move 3 fills the R88 gap. Moves 4 and 5 keep the graphics leap in R88 order. Move 6 keeps #92 after the feel-pass fixes. Moves 7 and 8 resolve the #60 park and the #139 supersession before #100 runs. Moves 9 to 11 put the Nemesis redesign before the steps that teach and measure it, which is the core R85 fix. Moves 12 to 16 keep the progression steps in their required order after the redesign. Move 17 puts #169 after the round 6 pick and names its missing blockers. Move 18 keeps the later issues parked until their missing dependencies exist.

6. Owner questions, at most five, with chair picks

#60 park: unpark PR #143 so #100 can run, or keep it parked?
Pick: unpark, merge #60, then close #143 and drop 60 from queued.txt. Why: #100 is blocked by the park, and #139 has already superseded part of #100's task list.

Deaths and weapons: insert the deaths-and-weapons issues before #139?
Pick: yes. Why: R88 explicitly orders deaths and weapons before nebulas and storms, and the queue currently skips from ship work to #139.

#167 and #171: add both to the queue before #169?
Pick: yes. Why: #169 names them as blockers and LOOP.md omits them, so #169 cannot be scheduled honestly without them.

#27 and #122 telemetry: merge #27's Nemesis counters into #122 and leave #27 with XP telemetry only?
Pick: yes. Why: both issues build the same escape and compounding counters on the same files; #122 owns the per-commander shape, so one owner avoids double work.

Progression order: move the Nemesis redesign (#120 to #122) before the progression steps (#24 to #30)?
Pick: yes. Why: #24 teaches the Nemesis loop and #27 measures the Nemesis counters, and both assume the old single-Nemesis design that R85 supersedes; the steps must still run in order, so the whole block moves after the redesign.
