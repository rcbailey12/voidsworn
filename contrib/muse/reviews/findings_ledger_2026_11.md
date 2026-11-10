# Findings ledger, Oct 28 to Nov 10 2026 (issue #343)

One table for every finding, condition and recommendation raised between Oct 28 and Nov 10 2026, marked LANDED (proof in the code at main, or the Board's record where that is all that exists), OPEN (the issue that holds it, or the standing the issue block names), RULED OUT (the ruling), or LOST (raised, never ruled out, in no issue and not in the code). Built by Muse in one run: a blind Rey sample of twenty items verified against main directly, table legs from DeepSeek (DeepThink on, Search off) and Qwen (Qwen3.8-Max, both gates passed), a Grok re-check of one third of the LANDED rows, and the chair's own code checks curing the re-check's weak spots. The Flash re-check of the other third did not run (a Google sign-in code step on a sleeping phone); its rows overlap the chair's blind sample and are marked as chair-verified instead. Sources: FINDINGS R110 to R159, contrib/muse/reviews/ (every outside check and synthesis in the window), the five Nov 6 audit syntheses and their settlements, the two outside audits (standing only, per the block), LOOP.md at Nov 10 01:40 UTC and the open and closed issue listings of Nov 10.

## The table

| ID | Item | Mark and proof |
|---|---|---|
| A1 | Check 269 cond 1: HD9 hull-low line at the nameplate site | LANDED. godot/ui/battle/hud.gd:1053 and :2181 both read f < 0.35, with HD9 comments; :2181 cites this check |
| A2 | Check 269 cond 2: debrief layout not re-asked; texts corrected at merge | LANDED (Board record: applied at the PR #269 merge) |
| A3 | Check 274 cond 1a: sector modal twin divergence | LANDED. The named raw call no longer exists in campaign_ui.gd at main; follow-up bucket #282 verified closed during chairing |
| A4 | Check 274 cond 1b: strike line raw pronouns | LANDED in the JS twin: campaign_run.js:321 wraps the line in nemSay. The Godot twin string was not located by search; #282 verified closed |
| A5 | Check 274 cond 1c: clock-full message raw pronouns | LANDED in the JS twin: campaign_run.js:319 wraps the message in nemSay with a comment naming the defect class. Same Godot caveat as A4 |
| A6 | Check 274 cond 2: carry wording plus a real-advance test | LANDED (Board record: named for the #274 PR; #282 verified closed). The test half rests on the record, not re-derived here |
| A7 | Check 280: Riches and Comeback panel lines | LANDED. godot/ui/campaign/campaign_ui.gd:765 and :774 wrap both lines in C.nemSay |
| A8 | Check 286 cond 1: document-side assertions in the env test | OPEN, #230. The PR that carries it is unmerged; the test file is not on main |
| A9 | Check 286 cond 2: three fail-open holes | OPEN, #230, same as A8 |
| A10 | Check 286 cond 3: flat storm veil sentence in the spec | OPEN, #230, same as A8 |
| A11 | Check 314 cond 1: text backing at three sites | LANDED. hud.gd:994 to :996 puts roster rows on the well at WELL_A with a comment citing this condition; wells and strips throughout |
| A12 | Check 314 cond 2: route card header guard | LANDED. hud.gd:364 names the number label step_no ("a head without a number has none"); :1684 guards the enemy table |
| A13 | Check 314 cond 3: "Likely kill." wording | LANDED by removal. The string does not appear in hud.gd at main; the Board dropped the words. The call itself was never written down, which the re-check flagged |
| A14 | Check 314 cond 4: duplicate focus stylebox | LANDED. hud.gd:274 to :275: the ring comes from the theme alone, citing this condition |
| A15 | Check 336 conds 1 to 5 (recipe audit) | OPEN. Given to the round 7 thread on PR #341 (R158, LOOP); PR #336 does not merge on its own |
| A16 | Check 248 NOTE 1: modal alias readers | LANDED by rewrite. The fragile alias pattern is absent at main; campaign_ui.gd:730 and :812 read C.nemActive(). Closed by the modal's rebuild, not by the hardening edit the NOTE proposed |
| A17 | Check 248 NOTE 2: story.gd alias contract | LOST. The contract exists only in the check file; no issue, no code marker |
| A18 | Check 248 NOTE 3: statistics behind --full only | LOST. A weights change still passes the PR gate silently |
| A19 | Check 248 NOTE 4: --fast SKIPs the R-Q1 gate | LOST, and verified live at main: contrib/opus/tools/run_all_checks.js:40 still SKIP-marks any check over 120 seconds under --fast. Whether any gating path runs --fast was never established |
| A20 | Check 248 NOTE 5: shared failure counter and label | LOST |
| A21 | Check 248 NOTE 6: gate covers the JS draw only | LOST |
| A22 | Check 248 NOTE 7: scenario twins not a runner row | LOST, verified at main: run_all_checks.js has no scenario row |
| A23 | Check 248 NOTE 8: render paths can mutate run state | LOST. The lazy creation is by design (B4); the RNG stream question was never established and nothing tracks it |
| A24 | Check 248 NOTE 9: no shots for four switched UI paths | LOST |
| A25 | Check 248 NOTE 10: rival.gd stale comment | LOST (cosmetic) |
| A26 | Check 283: GO, questions verified in the check | LANDED (the check itself is the proof) |
| B1 | Job #227: five audit records filed | LANDED. PR #247 merged (R130); the records are on main |
| B2 | Job #228 | LANDED (Board record: PR #251 merged). The re-check marked this WEAK: no diff proof in the pack |
| B3 | Job #229 | LANDED (Board record: PR #240 merged). Same WEAK note as B2 |
| B4 | Job #230: environment reconciliation | OPEN, #230. Its done-when is broader than the checked PR (AS14, AS16, AS18, BD16, NB11, ST10, ST3) |
| B5 | Job #231: UI specification | LANDED. PR #269 merged after its check; follow-ups live at C5 |
| B6a | Job #232: effects stress pack | LANDED (closed; state verified during chairing) |
| B6b | Jobs #233 to #238: capture and measurement | OPEN, all six, blocked on the parked Codex seat. LOOP: pass 3 folds them into the look bench or retires them |
| B7.1 | Graphics settlement questions (caps, shares, bars, hero) | RULED OUT. R113 drops D18 and D20 by name; R116 sets the gate; R121 confirms the removals |
| B7.2 | FX S2: Sonniss licence read | RULED OUT. Ryan closed it Nov 6 with the risk knowingly carried; the read stands as record |
| B7.3 | Graphics section 5: Argon's two pack inventory gaps | LOST. No later pack picks the numbers up and no issue holds them |
| B7.4 | Settlement programs #208, #210, #212, #213, #215 | LANDED as filed. All five parents verified closed during chairing; their work stands in the job rows |
| B7.5 | FX consolidated movement specification | OPEN, #230 (the motion spec PR is its vehicle, unmerged) |
| B7.6 | Graphics C57: settles on the first Chorus hull | OPEN, rides #209 |
| B7.7 | Graphics C6: MSAA isolation runs, not yet run | LOST. Named inside the ceiling work that became the finished #207 gate; no live holder |
| B7.8 | Environment BD17 process rule (sheets state their board look) | LANDED (Board record: stated as effective in the synthesis; a process rule, no build proof applies) |
| C1 | R110: D18 and D20 still cap triangles | RULED OUT. R113 retires both by name and R121 confirms; the station assert became a report in PR #226. One leg's OPEN reading rests on the env audit's older ST5 line, which predates that conversion |
| C2 | R115: gate share open | LANDED. R116 answers it: 12.5 ms, 75 percent of the frame |
| C3 | R130 gap 1: four Godot readers on RUN.nem | LANDED. PR #248 switched them; its check gives the per-reader dispositions |
| C4 | R130 gap 2: R-Q1 quick gate not wired | LANDED. run_all_checks.js:25 registers the enum check with the R-Q1 comment. Its --fast hole is A19 |
| C5 | R136: UI spec follow-up jobs A to G; provisional values | OPEN, #235, #237, #238 (the U-A, U-C and U-D inputs), all blocked |
| C6 | R136: endRun pays Heat twice | LOST. Flagged for the Board inside R136; no issue, no ruling, no fix in the record |
| C7 | R136: defaults block (ui_spec.md 7.5) is Ryan's to see | OPEN (Ryan; lives in the #271 family, no standalone issue) |
| C8 | R143 and #305: tree picks were text only | OPEN. #305 jobs 5 and 6 merged, repair #335 running, jobs 7 and 8 unfiled |
| C9 | R144: worker restores tracked .import re-saves | LOST. It survives only as a sentence in FINDINGS; it is in no runner, template or issue boilerplate the packs show. One leg read R144 itself as the home and dissented; the chair holds that a rule nobody is pointed at is lost in practice |
| C10 | R153: vent-changed looks with no captures | OPEN, #333, blocked; the pass 3 look bench replaces it |
| C11 | R158 item 2: #198 and #169 | RULED OUT. Retired by Ryan, verified closed |
| C12 | R159: UI rollout groups 2 to 4 | OPEN. Group 1 is #344, running; groups 2 (end screen and debrief, #92), 3 and 4 unfiled; parent #271 open |
| C13 | Pass 3 starts when #337 lands | OPEN (Board). #337 landed Nov 9; pass 3 was unfiled at the Nov 10 01:40 UTC board state |
| D1 | Audit pass 1 F1: tree picks | OPEN, #335, running |
| D2 | Audit pass 1 F3: oracle copies | OPEN, #335. Its brief repairs by re-sync plus a hard check; the Board's R155 deletion preference was not the route taken, and the ledger records the route, not the preference |
| D3 | Audit pass 1 F2, F4, F5, F7, F8, F9, F10, F13 | OPEN, waiting for pass 3 |
| D4 | Audit pass 1 F6: hard points | OPEN, the running ship round (PR #341, stage 7 export) |
| D5 | Audit pass 1 F11: shader warm-up | OPEN (Board-held; a PC frame trace comes first; no issue) |
| D6 | Audit pass 1 F12: read-only view API | OPEN, the UI rollout (#344 onward, per R159) |
| D7 | Audit pass 2 F1, F2, F9: rebake, big moments, death puffs | OPEN, waiting for pass 3 |
| D8 | Audit pass 2 F3, F4, F13: paint, battle camera, outline gate | OPEN, the running ship round (PR #341, Board guidance given) |
| D9 | Audit pass 2 F5, F7: lines and beams kit | OPEN, waiting for pass 3 |
| D10 | Audit pass 2 F6, F15: shields | OPEN, waiting for pass 3, sequenced after the recipe emits a shield surface |
| D11 | Audit pass 2 F8: look bench | OPEN, pass 3's first item; replaces #333 |
| D12 | Audit pass 2 F10 | OPEN, rewrites #139 (blocked) |
| D13 | Audit pass 2 F11 | OPEN, rewrites #140 (blocked) |
| D14 | Audit pass 2 F12 | OPEN, replaces #199 (blocked) |
| D15 | Audit pass 2 F14 | OPEN, with the R138 concept redo, #276 (blocked) |
| E1 | #292: rulings S1 to S6 and the 18 round 2 changes | LANDED (Board record: built in PR #314, merged with conditions met; the four conditions are A11 to A14, each code-verified above). S2 was Ryan's own ruling (no undo after a confirmed move) |
| E2 | #270: concept directions | RULED OUT. R141 picks one direction (D6 bold blended with D3 discipline) and retires the rest |
| E3 | #311: tree texts | LANDED. PR #324 merged, issue closed; the wiring of the final texts is C8 |
| E4a | #296: Crusade voice text | LANDED. PR #328 merged |
| E4b | Crusade voice wiring into data.js NEM_VOICE | LOST. Verified at main: data.js:501 opens NEM_VOICE with hegemony and no voidsworn block exists in the table. LOOP names it as a small job after the tree jobs, so the Board has not forgotten it, but it has no issue and is not in the code, which is the block's definition. One leg marked it OPEN on the LOOP line; the chair follows the definitions |
| E5a | #48 Q1: Nemesis chair pick (Chorus Elder Throat) | LOST (no holder; a content pick, not a defect). Ryan closed the sibling questions on Nov 9; this one was not among them |
| E5b | #48 Q2 | RULED OUT. Closed by Ryan Nov 9 2026 without a ruling, together with the design text pick and Brin's pronoun |
| E5c | #48 Q3: gatherer hulls, story only | LOST (no holder; same note as E5a) |
| E5d | #48 Q4: Astra, one scripted shot | LOST (no holder; same note as E5a) |
| E6a | Stack review: ChatGPT sign-in inside OpenCode as a third workhorse | LOST (informational; no action was ever requested. ChatGPT's return makes it a live option the Board can still take) |
| E6b | Stack review: Kimi subscription key in other harnesses | RULED OUT in practice. Ryan cancelled the Kimi purchase Nov 9 2026; the harness fact remains a note |
| E6c | Stack review: DeepSeek's own harness (dsh) | LOST (informational note only) |
| E7 | FX S15 listen pass | OPEN, #211 (Ryan's pass, after the Foley probe clips) |
| E8 | #230 rocks turn (A, B or C; Opus pick B) | OPEN, #230. The PC capture the question waits on is not confirmed run in the record |

## LOST rows, ranked by what the owner would notice

1. C6, Heat paid twice at endRun. A live economy error in the shipped rules: every finished run pays the bonus twice. Found inside the #231 spec work, flagged for the Board in R136, and never filed.
2. E4b, the Crusade voice is written and merged as a text file and never wired into data.js, so the Crusade Nemesis has no voice in the system the other factions use. LOOP carries it as a sentence; no issue does.
3. A19 and A22, the gate integrity pair. Under --fast the R-Q1 assignment gate reports SKIP and passes, and the scenario twins are not a row in the runner at all. Both were NOTEs on a GO check, so neither was ever owed a follow-up.
4. A23, render paths creating run state. Raised as a question in check 248 and never answered; if creation draws on the run's RNG stream, rendering order can change outcomes.
5. A18, the statistical assignment checks run only behind --full, so a change to the draw's weights passes the PR gate silently.
6. A17, the story.gd alias contract. Three readers are safe only while RUN.nem stays fresh; the contract that protects them lives in one check file.
7. E5a, E5c, E5d, the three #48 chair picks. Content the Glasswright package still waits on, recorded on a merged delivery and nowhere else.
8. C9, the .import restore rule. The next capture run that forgets it repeats the #281 run 1 accident (300 MB of assets committed by the runner).
9. A21, A20, A24, A25, the hygiene tail: a JS-only gate, a shared failure label, missing shots, a stale comment.
10. B7.3, B7.7, E6a, E6c, records and notes with no next home: Argon's pack inventory gaps, the MSAA isolation runs, and two harness notes. No player ever sees these; they are here so the next pack does not inherit unnamed numbers.

## Counts and method notes

Rows: 83 table rows. LANDED 26, OPEN 31, RULED OUT 7, LOST 19. Several rows bundle siblings and are counted once: A15 is five conditions, B6b is six jobs, B7.1 is four settlement questions, D3 is eight findings, D7 is three, D9 and D10 are two each, and E1 is six rulings plus the 18 numbered changes.

Where the legs disagreed, the chair followed the block's definitions and code at main, and the disagreements are named in the rows (C1, C9, E4b, E5). LANDED rows that rest on the Board's record alone: A2, A6, B2, B3, B7.8, E1; the Grok re-check marked the pack proof for B2 and B3 WEAK, and the chair accepts that: their PR numbers are named, their diffs were not re-read in this run. Not covered: the Nov 6 audits' evidence packs and legs (the syntheses are the records audited here), reviews in contrib/muse/reviews/ subdirectories other than the five audits, and anything raised before Oct 28 or after the Nov 10 01:40 UTC board state. Issue #343's own delivery is not a row.
