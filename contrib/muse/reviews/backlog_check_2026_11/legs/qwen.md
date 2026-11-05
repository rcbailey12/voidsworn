# Qwen leg (writer), issue 189

Chair gate note: Gate 1 PASS (Qwen3.8-Max selected and verified in the header before submission), Gate 2 PASS (chat header still showed Qwen3.8-Max after generation). Raw Qwen copy below, dash-normalized and table layout flattened only. Chair flags, worked through in the synthesis: its #92 verdict (current) rests on the done-when conditional and it still recommends moving #92 in the queue, so the split with the blind leg is narrower than the labels suggest; its Q1 pick (keep #60 parked until #139 lands) is the one the chair adopts; its Finding 7 correctly identifies the deaths and weapons gap in the queue and labels the #137 and #138 identification INFERRED.

Backlog Check: 18 Queued Codex Issues (Issue 189)
Qwen leg (writer). Checked every issue against FINDINGS R82 to R103, the LOOP.md queue state, and the board state at pack time. Extra weight on dependency chains, scope collisions, and corrected queue order.

1. Verdict Table

| Issue | Verdict | One-line reason |
|---|---|---|
| #24 | NEEDS EDITS | R85 redesigns Nemesis to per-commander (meetings, debrief lessons, clock); the step's Nemesis teaching text still uses the pre-R85 single-Nemesis shape |
| #26 | CURRENT | No R82-R103 row touches Heat gating or the R63 payout rates |
| #27 | NEEDS EDITS | R85 makes Nemesis telemetry per-commander; the escape and compounding counters collide with #122's identical scope |
| #29 | CURRENT | No R82-R103 row touches faction tree content or Branch B/C rollout |
| #30 | CURRENT | No R82-R103 row touches capstone mastery or the 320/440/600 XP thresholds |
| #41 | CURRENT | R78 Q9 is pre-R82 context; no R82-R103 row restates or supersedes captured-hull rules |
| #42 | CURRENT | R78 Q15 is pre-R82 context; R99 Q4 (Chorus flesh) is about breakable ship visuals, not core-eating mechanics |
| #44 | CURRENT | R78 Q18 is pre-R82 context; no R82-R103 row touches the finale board brightening |
| #92 | CURRENT | Presentation and copy only; the conditional "every panel already backed by data" absorbs the per-commander change from R85 without stale text |
| #100 | NEEDS EDITS | #139 (R88) explicitly supersedes matching #100 tasks, but #100's text has no supersession note; also #60 is parked |
| #120 | CURRENT | Text matches R85 Q1 (hunter per story point, no consecutive repeats, SP1 returns at SP3 about 1 in 4) |
| #121 | CURRENT | Text matches R85 Q2/Q3/Q5 and already carries the R101 NEM_VOICE addition |
| #122 | CURRENT | Text matches R85 per-commander telemetry and panel requirements |
| #139 | CURRENT | Text matches R88, R90 picks (fog volumes, split colour ramp, faction tint capped per R82, lights at max tier only) |
| #140 | CURRENT | Text matches R88 and R90 (terran/rocky first, volcanic desert next, gas/ice unchanged) |
| #169 | NEEDS EDITS | R103 supersedes the round 5 blocker: round 6 (#187) now picks the hull; three references to "round 5 (#163)" are stale |
| #183 | CURRENT | Text matches R94, R96, R98, R100; PR #190 is open and the issue is running |
| #187 | CURRENT | Text matches R103 (V3 cut to ceiling plus V1, simple paint); the #188 conditional is correct since #188 has not merged at pack time |

2. Per-Issue Sections: Issues Needing Edits

#24 Progression step 7: Finish the Nemesis teaching loop
R85 (Nov 3) supersedes the single-Nemesis design that this step was written against. R85 Q1 draws a hunter per story point. R85 Q3 keys debrief lessons per commander. R85 Q5 gives one run-level clock paced by the active commander. The step's text still describes a generic Nemesis meeting and a generic debrief.
Edit 1. Stale text:
"Adds the debrief weakness teaching on a lost meeting (Q5), and rewrites meeting fiction and UI language to own the mandatory once per sector status, with the clock as accelerant only (Q3)."
Replacement text:
"Adds the debrief weakness teaching on a lost meeting with the active commander, keyed to that commander's record (R85 Q3), and rewrites meeting fiction and UI language to own the mandatory once per sector status and name the sector's assigned hunter, with the run-level clock paced by the active commander as accelerant (R85 Q5)."
R85 Q3 and Q5 make the old generic phrasing wrong: lessons and clock now attach to the active commander, not to a single RUN.nem.
Edit 2. Stale text:
"Test: a lost meeting still adds one taught weakness to the debrief, and the sector map names the meeting as certain rather than chance."
Replacement text:
"Test: a lost meeting with the active commander still adds one taught weakness to that commander's debrief record, and the sector map names the meeting as certain rather than chance and shows the assigned hunter's faction."
R85 Q1 makes the meeting target a specific drawn commander; the map must name that commander, not a generic encounter.
Edit 3. Stale text:
"Ryan sees: losing to the Nemesis still teaches him something, and the map stops pretending the meeting might not happen."
Replacement text:
"Ryan sees: losing to the sector's assigned hunter still teaches him something, recorded against that commander, and the map stops pretending the meeting might not happen."
R85 Q1 and Q3 together make the old "the Nemesis" phrasing wrong: the hunter is now per-story-point and the lesson is per-commander.

#27 Progression step 11: Extend telemetry for Nemesis rates and pacing
R85 moves all Nemesis state to per-commander. #122 (Nemesis redesign part 3) already owns "a run-level escape counter and a per-commander compounding counter" in campaign_run.js. #27's text adds the same counters under the old single-Nemesis shape. This is a scope collision on campaign_run.js telemetry: if #27 runs first, #122 must rip out and redo the counters; if #122 runs first, #27's counters are already built and #27's text is redundant.
Edit 1. Stale text:
"Adds Nemesis escape and compounding counters (Q6) and per run XP earnings by line to the campaign save, extending the existing per battle play log."
Replacement text:
"Adds per run XP earnings by line to the campaign save, extending the existing per battle play log. Nemesis escape and compounding telemetry is deferred to #122, which builds the run-level escape counter and per-commander compounding counter under the R85 architecture."
R85 and #122's done-when make the old text wrong: the counters are per-commander, and #122 owns them.
Edit 2. Stale text:
"Test: a simulated batch of runs produces a summary with an escape rate, a compounding rate, and median XP per run per line."
Replacement text:
"Test: a simulated batch of runs produces a summary with median XP per run per line. Nemesis escape and compounding rates are tested in #122."
Same R85 and #122 reasoning.
The "Ryan sees" line ("nothing in the game; he gets numbers for tuning judgements before anyone touches a cap") remains valid for the XP earnings scope and needs no edit.

#100 Terrain fx 2: debris, dead star well, old looks and the quality ladder
Two problems. First, #139's own text says "Check #100 (terrain fx 2) against this before it runs; anything here supersedes the matching #100 task." But #100's text has no corresponding note. Since #139 is queued ahead of #100 (position 3 vs position 6), #139 will land first and may invalidate parts of #100's gas and debris tasks. Second, #100 is blocked on #60, and #60's PR (#143) is parked with the owner hold "Unpark only if Ryan asks." The queue lists #100 at position 6 as though it will run, but its blocker is indefinitely parked.
Edit 1. Stale text:
"Second half of the terrain effects build (FINDINGS R82). Blocked until the gas half and the backdrops debris pass (#60) merge, since all three touch the debris and gas code. Build on the ship-derived wreckage kit from #60 rather than replacing it."
Replacement text:
"Second half of the terrain effects build (FINDINGS R82). Blocked until the gas half and the backdrops debris pass (#60) merge, since all three touch the debris and gas code. Build on the ship-derived wreckage kit from #60 rather than replacing it. Note: #139 (nebulas and ion storms, R88) supersedes any matching task in this issue; after #139 lands, re-scope this issue against what #139 delivered before running. #60 (PR #143) is parked by owner hold; this issue cannot start unless Ryan unparks it."
R88 (which drives #139) and the LOOP.md hold on PR #143 make the old text incomplete: it does not warn the runner about supersession or the parked blocker.

#169 Breakable by design: Pyre-Barge hull thickness, decks and authored break lines (R98)
R103 (Nov 4) rejected the round 5 paint and filed round 6 as #187. R103 states: "#169 waits for the round 6 pick." The issue text still references round 5 (#163) as the hull-deciding blocker in three places.
Edit 1. Stale text (Brief line):
"the round 5 result (#163) for which Pyre-Barge hull is kept"
Replacement text:
"the round 6 result (#187) for which Pyre-Barge hull is kept (R103)"
R103 supersedes round 5 as the hull-deciding step.
Edit 2. Stale text (Done when):
"the kept round 5 Pyre-Barge hull gets real hull thickness"
Replacement text:
"the kept round 6 Pyre-Barge hull (R103) gets real hull thickness"
Same R103 ruling.
Edit 3. Stale text (blocker line at the bottom):
"Blocked until round 5 (#163) picks the hull, the game-side fallback (#167) lands, and the Muse method (#171) merges."
Replacement text:
"Blocked until round 6 (#187) picks the hull (R103), the game-side fallback (#167) lands, and the Muse method (#171) merges."
R103 makes "round 5 (#163)" the wrong blocker.

3. Verification Lines for Current Issues
#26. Checked against all of R82 to R103. No row mentions Heat, Heat gating, the R63 payout rates, or the run setup screen. The issue's own text carries no estimates and references only R63 Q13, which is pre-R82 context and not restated or superseded. The "Rules for every progression step" boilerplate (browser plus Godot, oracles, parity, R69 switch) is unchanged by any R82-R103 row.
#29. Checked against R82 to R103. No row touches faction tree content, Branch A/B/C rollout, capstones, or campaign_meta.js tree data. The step references "Step 2's machinery," which is pre-R82 and unaffected. Boilerplate rules unchanged.
#30. Checked against R82 to R103. No row touches capstone mastery, the 320/440/600 XP thresholds, or campaign_meta.js mastery data. Boilerplate rules unchanged.
#41. Checked against R82 to R103. R78 Q9 is pre-R82 context. No R82-R103 row restates or supersedes captured-hull rules, Cinder Line yards, or the run 3 gate. R96 (ship pipeline) affects visual build methods, not the campaign mechanic of keeping a hull. The issue is in "Later, not yet scheduled," which is consistent with its progression dependency.
#42. Checked against R82 to R103. R78 Q15 is pre-R82 context. R99 Q4 (Chorus bone ribs and membranes) is about breakable ship visuals, not the core-eating campaign mechanic. No conflict. The issue is in "Later" and blocked behind #22 (core sync, progression step 5), which is not in this check list. INFERRED: #22 is either done or tracked elsewhere; the blocker is outside this pack's scope.
#44. Checked against R82 to R103. R78 Q18 is pre-R82 context. No R82-R103 row touches the finale board brightening. R88's visual rulings target deaths, nebulas, planets, and squadrons, not the finale board. The issue is in "Later" and blocked behind progression step 12, which is not in this check list.
#92. Checked against R82 to R103. R85 Q3 keys debrief lessons per commander, which will eventually change what data the debrief shows. But #92 is scoped as "presentation and copy only" and its done-when says "every panel the design lists that is already backed by data." Panels whose data does not exist yet (per-commander lessons, pre-Nemesis-redesign) are simply excluded by that conditional. No text in the issue is stale. The dependency is noted in section 4 below.
#120. Checked line by line against R85 Q1. Hunter drawn per story point from five non-player factions, no consecutive repeats, SP1 may return at SP3 (1 in 4): all present in the done-when. Faction-keyed commander registry replacing RUN.nem, lazy creation through newNemesis(fac), old-save migration, seed enumeration test: all match R85 and the synthesis. No R82-R103 row beyond R85 touches this issue.
#121. Checked against R85 Q2, Q3, Q5 and R101. Per-commander adaptation on sector advance, once-per-sector meeting with met-this-sector flag, run-level clock paced by active commander's beh.clock, debrief lessons per commander, clash check preserved: all present. The R101 addition (NEM_VOICE from text_table.md, nemSay wiring, Eclipse fall_final key) is already in the issue text as the "Added Nov 4" paragraph. No stale text.
#122. Checked against R85 Q2 and the synthesis section 4. nemSignature faction tagging, run-level escape counter, per-commander compounding counter, Nemesis panel with current hunter and returning commander history: all match R85. No R82-R103 row beyond R85 touches this issue.
#139. Checked against R88 and R90. Froxel preparation, FogVolume with split colour ramp (dark stops in EMISSION, lit stops in ALBEDO), faction tint capped per R82, thinned billboard edge layer, ships crisp at 4K inside gas, bolt and explosion lights at max tier only, density pulse at high, current path at low: all match R90's picks. The "Check #100 against this" note is present. Effort label is xhigh, no human-hour estimates. No stale text.
#140. Checked against R88 and R90. Terran and rocky planets first, volcanic desert next, gas and ice giants unchanged: matches R90. Domain-warped continents, Voronoi plates, pseudo-erosion, biomes, normals and roughness on the sphere, slope-blended micro-detail: matches the synthesis. CC0 textures with licence lines filed: no R82-R103 conflict. No stale text.
#183. Checked against R91, R94, R96, R98, R100. Additions-only doctrine (R94, R100), height and asymmetry from additions at least 2 units proud (R94 note), R96 paint stack, breakable per R98 with R100 truss decal exemption, triangle and frame-time targets matching R100 (about 20k tris, 0.35 ms, 40k-45k and 1.0 ms ceiling), effort in Codex runs not hours (R99): all present and consistent. PR #190 is open per the board state. The issue is running. No stale text.
#187. Checked against R96, R97, R98, R99, R103. Two variants (V3 cut to ceiling, V1 with simple paint), simple paint spec (few big plates, two or three tones, dark recesses, red for trim and light only, grain cut), value-structure check, nine-cell sweep, effort in Codex runs: all match R103 and R99. The #188 conditional ("If the Muse readable-paint standard has merged by the time this runs, follow it") is correct: #188 is delivered on branch muse/issue-188 but has not merged at pack time. No stale text.

4. Dependency and Order Findings
Finding 1: #60 is parked, blocking #100 indefinitely.
PR #143 (#60, debris detail) is open and PARKED by the owner's hold in LOOP.md: "Unpark only if Ryan asks." #100 is blocked until #60 merges. The queue lists #100 at position 6 as though it will run, but its sole blocker is indefinitely parked. Unless Ryan asks to unpark #143, #100 cannot start. Affects: #100.
Finding 2: #139 supersedes parts of #100, but #100 does not say so.
#139's text includes "Check #100 (terrain fx 2) against this before it runs; anything here supersedes the matching #100 task." #139 is queued at position 3, #100 at position 6, so #139 lands first. But #100's own text has no supersession note. A Codex runner picking up #100 after #139 merges would not know which of its tasks are already superseded. Affects: #100, #139.
Finding 3: Scope collision between #27 and #122 on Nemesis telemetry.
Both issues add Nemesis escape and compounding counters to campaign_run.js. #27 says "Adds Nemesis escape and compounding counters (Q6)." #122 says "a run-level escape counter and a per-commander compounding counter." Under R85, the counters are per-commander. If #27 runs first (queue position 7 before position 8), it builds the old single-Nemesis counters and #122 must rip them out. If #122 runs first, #27's counters are redundant. The shared scope is campaign_run.js Nemesis telemetry. #122 should own it. Affects: #27, #122.
Finding 4: Scope collision between #24 and #120/#121 on Nemesis meeting and debrief code.
#24 touches campaign_run.js (nemNodeIs, run end debrief data) and meeting text. #121 also touches campaign_run.js and redesigns nemNodeIs to target the active commander with a per-commander met-this-sector flag. If #24 runs first (position 7 before position 8), it builds the teaching loop on the old single-Nemesis nemNodeIs, and #121 must migrate that work. The shared scope is campaign_run.js nemNodeIs and debrief data. #120/#121 should own the Nemesis architecture; #24 should build on top. Affects: #24, #120, #121.
Finding 5: #169's blocker text references round 5 (#163), superseded by round 6 (#187).
R103 rejected round 5's paint and filed round 6 as #187. R103 states "#169 waits for the round 6 pick." The queue correctly places #169 at position 9 after #187 at position 3, but #169's text still says "round 5 (#163)" in three places. Affects: #169.
Finding 6: LOOP.md has a duplicate position 3.
The queue lists "#187 Pyre-Barge round 6" as item 3 and then "#139 nebulas and ion storms" also as item 3 ("3 (as numbered in LOOP.md)"). This is a numbering error. #139 should be position 4 and all subsequent items renumbered. Affects: queue clarity for all items from #139 onward.
Finding 7: R88's "deaths and weapons come first" is not represented in the 18-issue check list.
R88 rules: "after the ship work, deaths and weapons come first, then nebulas and storms, then planets." #139 (nebulas/storms) and #140 (planets) are in the queue. But no issue in the 18-issue check list covers deaths and weapons. INFERRED: the deaths and weapons work is in issues #137 and #138 (the graphics leap series runs #137 to #140 per R90), which are not in this check list. If #137 and #138 are not yet filed or queued, #139 is missing a dependency that R88 requires. Affects: #139, and potentially #140.
Finding 8: #92 runs before Nemesis redesign in the current queue.
#92 is at position 5, Nemesis redesign at position 8. #92 is presentation and copy only, and its conditional "every panel already backed by data" protects it from building panels without data. But if #92 runs before #120-122, the debrief screen will be built and captured without per-commander data. When #120-122 land, the debrief data shape changes and #92's captures may need a follow-up pass. This is not a text error in #92 but an ordering inefficiency. Affects: #92, #120-122.
Finding 9: #42's blocker (#22) is not in the queue or the check list.
#42 says "Blocked behind core sync (progression step 5, #22)." #22 is not among the 18 checked issues and does not appear in the LOOP.md queue order. INFERRED: #22 is either already merged or tracked outside the visible queue. If it is not done and not queued, #42's blocker is missing. Affects: #42.
Finding 10: #44's blocker (progression step 12) is not in the queue or the check list.
#44 says "Blocked behind the story and finale work (progression step 12 and later)." Progression step 12 is not among the 18 checked issues. INFERRED: step 12 is in a separate issue not yet filed or not in this queue. If it is not queued, #44's blocker is missing. Affects: #44.

5. Proposed Corrected Queue Order
Below is the corrected order for the 18 issues, plus the #60 question where it bears on #100. One line of reasoning per move from the current order.
1. #183. No change. Already running, PR #190 open, HOLD for Ryan's look. First because it is in flight.
2. #187. No change. Blocked on #183 merging. HOLD PR for Ryan's pick. Must land before #169 can start.
3. #139. Was duplicate-3. Now sole position 3. R88 orders nebulas/storms before planets. INFERRED: verify #137/#138 (deaths/weapons) are done or queued first, since R88 puts them before nebulas. Supersedes matching #100 tasks, so must run before #100.
4. #140. Was 4. R88 and R90 order planets after nebulas/storms. No change in relative position.
5. #120. Moved up from position 8. R85 architecture (commander registry, hunter draw) must land before any progression step that touches nemNodeIs or debrief data. No feel-pass blocker on #120 itself.
6. #121. Moved up from position 8. After #120 (its stated blocker). Owns nemNodeIs per-commander, clock, adaptation. Must land before #24 builds the teaching loop.
7. #122. Moved up from position 8. After #121. Owns Nemesis telemetry (escape, compounding counters). Must land before #27 to avoid the scope collision.
8. #24. Moved down from position 7. Now after #120-122 so the teaching loop builds on the per-commander architecture instead of the old single-Nemesis shape. Still blocked on feel-pass.
9. #26. Was in position 7 group. Stays in progression step order (step 10 after step 7). No Nemesis dependency, so its relative position among progression steps is unchanged.
10. #27. Was in position 7 group. Now after #122 to avoid the telemetry collision. Nemesis counters deferred to #122; #27 keeps XP earnings only. Still in progression step order (step 11 after step 10).
11. #29. Was in position 7 group. Stays in progression step order (step 13 after step 11). No Nemesis dependency.
12. #30. Was in position 7 group. Stays in progression step order (step 14 after step 13). No Nemesis dependency.
13. #92. Moved down from position 5. Now after #120-122 so the debrief screen can present per-commander data if the design calls for it, avoiding a follow-up pass.
14. #100. Moved down from position 6. Cannot start until #60 is unparked (Ryan's call) and #139 has landed (supersession). Effectively deferred. Re-scope after #139.
15. #169. Was 9. Now after #187 pick (R103) and after #167 and #171. Position relative to #187 is unchanged; the text fix (section 2) corrects the blocker reference.
16. #41, #42, #44. No change. "Later, not yet scheduled." Each has blockers outside the current queue (#41 on progression, #42 on #22, #44 on step 12). No R82-R103 urgency moves them forward.
#60 question: #100 cannot run while PR #143 is parked. If Ryan does not ask to unpark #143, #100 should be dropped from the active queue and moved to "Later" or closed pending Ryan's decision. If Ryan does unpark #143, #60 merges, and #100 can start after #139 lands and the supersession re-scope is done.

6. Owner Questions (five, with chair picks)
Q1. Should #60 be unparked to unblock #100?
PR #143 (#60, debris detail) is parked with "Unpark only if Ryan asks." #100 is stuck behind it. Meanwhile #139 will supersede some of #100's gas and debris tasks.
Pick: keep #60 parked for now. Let #139 land first, re-scope #100 against what #139 delivered, and then decide whether #60's debris kit is still needed or whether #139's volumes cover it. Unparking #60 before knowing #139's output risks building debris code that #139 replaces.
Q2. Should Nemesis redesign (#120-122) run before the Nemesis-touching progression steps (#24, #27)?
R85 is ruled. The per-commander architecture is decided. If #24 and #27 run first, they build on the old RUN.nem shape and #120-122 must migrate or redo that work.
Pick: yes, run #120-122 before #24 and #27. The progression steps that do not touch Nemesis (#26, #29, #30) keep their step order and are unaffected.
Q3. Are the deaths and weapons issues (#137, #138) filed and queued ahead of #139?
R88 rules "deaths and weapons come first, then nebulas and storms, then planets." #139 and #140 are queued. No deaths-and-weapons issue appears in the 18-issue check list. INFERRED: they are #137 and #138 from the graphics leap series.
Pick: verify #137 and #138 exist and are queued before #139. If they are not filed, file them before releasing #139, since R88's ordering is a ruling, not a suggestion.
Q4. Should #169's text be updated now to reference round 6 (#187), or wait until #187's pick is made?
R103 already changed the blocker from round 5 to round 6. The issue text still says "round 5 (#163)" in three places. #169 is at position 15 and will not run soon.
Pick: update now. The edit is mechanical (three string replacements, section 2 above) and prevents a Codex runner from misreading the blocker when #169 eventually unblocks. No reason to wait.
Q5. Should #92 move after Nemesis redesign, or stay in its current position and accept a possible follow-up pass?
#92 is presentation and copy only, and its "already backed by data" conditional protects it. But if it runs before #120-122, the debrief captures will show the old single-Nemesis layout, and a follow-up pass may be needed for per-commander panels.
Pick: move #92 after #120-122. The cost is a small queue shift. The benefit is that the debrief screen is built and captured once, against the final per-commander data shape, avoiding a second capture round.
