# Outside audit pass 3: issue scoping (Nov 2026)

Scoper: a fresh Fable 5.2 session with no history on this project (FINDINGS R154). It fixed nothing and filed nothing. It turns the confirmed findings of pass 1 (code health) and pass 2 (graphics and effects), and the five misses from the outside check, into ready-to-file jobs.

- Pinned commit: main `34565f32596b24c83384a85a1c6d005dbbede6ca` (short `34565f3`), "Board: FINDINGS R160". Every file and line named below was re-checked at this commit.
- Companion file: `contrib/claude_fable/reviews/audit_pass3_issues.json`, one object per proposed issue, in filing order. The Board files from it.
- 28 proposed jobs, P3-01 to P3-28. 6 questions for Ryan. Nothing here is filed yet.

## Board review (Fable 5.2 Board, Nov 10 2026, 05:35 UTC)

The Board read the whole file and the JSON, re-ran spot checks at the pin on the references that carry the jobs (P3-01, P3-05, P3-08, P3-11, P3-15, the workflow steps, the tree functions) and found each one where the scoper said. Verdict: ACCEPTED. 26 jobs are filed as written and 2 with a change (P3-02, P3-14); a verdict line sits under each job heading. No job is held or dropped.

- The scoper's order changes are accepted (section 5): the placeholder stop first beside the bench, death puffs and the readability pass right after the bench, trails and beams ahead of shields, the copy deletion between tree jobs.
- Old issues (section 8): 233, 235, 236, 237, 333, 139 and 199 are retired with a pointer to the job that replaces each. 140 stays open until Ryan answers question 5. 234 and 238 move from the codex label to opus and stay as filler. 92 is relabelled when UI rollout group 2 is filed.
- Could-not-decide list (section 11), Board calls: 1 file it small; 2 the "not active yet" mark goes with UI rollout group 4; 3 and 4 seats as proposed, with the stated fallback; 5 keep 234 as filler; 6 no sky job now (it is not a numbered finding; recorded in LOOP.md); 7 no light map rebakes for old hulls; 8 shields on one recipe ship first; 9 two explosion routes, not three; 10 the Board applies both workflow patches.
- Questions for Ryan (section 7): question 1, the Board goes with A (ship files stay on the PC, one copy step) until the first recipe ships are in the game, since it costs nothing; questions 3, 5 and 6 are put to Ryan; 2 and 4 are picked on their sheets.
- What the Board did not check: it did not re-trace every line number in jobs 16 to 28 (all blocked behind earlier jobs; each is re-read at its pin when it is released).

## 1. Summary (plain words)

- **28 jobs.** 11 for the cheap coder (the DeepSeek workhorse), 15 for Opus worker threads (12 of them need the PC), 1 for Muse, 1 for the Board itself. 11 can be filed open today. 17 are filed blocked, each behind a named job, a pick or the ship round.
- **Three things the audits found are already repaired on main.** Tree skills picked in a real run now reach the battle (PR 346). The copies of the rules files match again and a hard check guards them (PR 346). The missing bake scripts are back (PR 340). I checked all three at the pin.
- **The first five, in order, and what you will see:**
  1. P3-01 Placeholder hulls fail loudly, and one get-ship-files step for every capture job. On screen: nothing. A capture run with no ship files stops and says so, instead of sending you pictures of grey blocks.
  2. P3-02 Look bench: one standing capture set at the three real cameras (replaces issue 333). On screen: two sheets. Every weapon, shield and death at the cameras you play from, and all 36 ships at their real battle size. Every later looks job comes with the same sheet, before and after.
  3. P3-03 Hit and death staging table: sizes in pixels and times in seconds for every big moment. On screen: nothing yet. A one-page table from Muse that says how big and how long each hit and death should be.
  4. P3-04 Explosion pictures, step 1: bake two routes, measure the bake time, one sheet for the pick. On screen: one sheet with today's explosion beside two better ones, and how long each takes to make. You pick one.
  5. P3-05 Death puffs sit on the plating, and the stray puff check covers every death kind. On screen: no more pale balls floating beside a dying ship.
- **What waits on you:**
  - GPU windows. One GPU job at a time. The look bench needs the first one.
  - Six picks, listed in section 7 with my recommended option. Two of them come later, on a sheet.
  - Money: 11 workhorse jobs, so about 11 to 15 runs. Past runs cost 0.05 to 0.57 USD each. The DeepSeek balance was about 3.40 USD on Nov 10, so a top-up is likely.
  - Claude threads: the limit of three was in use at the pin (Board, ship round 7, UI rollout 1). Opus jobs here start as slots free up.
- **Biggest change to the looks order:** none to the start (bench first, then explosions). I would move the trails and beams job ahead of the shield jobs, because shields wait on a new ship and a pick, and trails do not. Section 5 lists every change.

## 2. What I read and checked

- Read in full: CLAUDE.md, AGENTS.md, HANDOFF.md section 0, contrib/opus/LOOP.md, FINDINGS rows R154 to R160 and the rows the audits cite (R88, R99, R111, R113, R116, R118, R121, R127, R129, R132, R134, R138, R145, R151, R153), both audit files with every Board verdict, the outside check of both (contrib/muse/reviews/audit_pass1_holes_2026_11.md) and the outside check of the ship recipe (contrib/muse/reviews/opus_check_336.md).
- Board: all 31 open issues listed through the REST API on Nov 10; bodies read for 92, 100, 139, 140, 194 (start only), 199, 209 (start only), 211, 216 (start only), 221, 230, 233 to 238, 250, 256, 271, 276, 305, 333, 343, 344, 347. Pull request 341 (ship round 7): text and comments read, not the diff.
- Ran at the pin: `node contrib/opus/tools/run_all_checks.js` (Node 22.23.4): 37 rows, 37 PASS, exit 0, work tree left clean. One count script of my own through the repo's loader (godot/campaign/test/node/env.js) for the tree table. grep and wc for every cited line and count.
- "Checked" in the coverage table means I opened the file at the pin and the line or the check result was there.

## 3. Coverage: every finding and miss, one row each

| Finding | What | Board verdict | Job, or no job and why |
|---|---|---|---|
| pass 1 F1 | Tree picks never reach the battle | CONFIRMED, live | No job for the defect: repaired on main by PR 346. Checked: battle.js:1312 builds the long key from the short pick; godot/rules/rules.gd:3694 to :3706; tree_handoff_test PASS in my run; the Godot hand-off step is in checks.yml:55 to :57. The real-save addition from the outside check is in P3-25. |
| pass 1 F2 | GitHub's checks never open the game | CONFIRMED | P3-10. The two cheap gate probes that had to come first are in (PR 346). No load-everything step, list file or bot battle at the pin. |
| pass 1 F3 | Three copies of the rules files | CONFIRMED, live | Drift repaired on main by the pin; the hard check came in PR 346 (checked: every copy matches its root file; "Ram First" has 0 hits in data.js and both tables; oracle_copy_test is a hard row). The copies still exist: P3-11 deletes them (the Board's pick). The drift guard row wording is in P3-09. |
| pass 1 F4 | PASS printed over failures | CONFIRMED | P3-06 (sort the list, Board work) then P3-09 (the runner). Order per R160. |
| pass 1 F5 | Missing ship becomes a silent block | CONFIRMED | P3-01 for parts (a) and (b). Part (c), where the ship files live, is question 1 for Ryan. |
| pass 1 F6 | Effects placed by box guesses | CONFIRMED | P3-14 (the contract, in the recipe) then P3-21 (the service). The braking puff case is already repaired on main (PR 327; checked fx_ship.gd:691 to :700). |
| pass 1 F7 | Tree check proves a counter | CONFIRMED | P3-12 for (a) and the data half of (b). The on-screen mark rides the UI rollout job for the tree screens. Part (c) is already the rule in new tree briefs (checked in issue 347). |
| pass 1 F8 | Runner commits everything | CONFIRMED | P3-07 first (check lines, task text), P3-08 (pull request text refreshed), P3-28 (partial runs, refuse list, safe push). |
| pass 1 F9 | Traps written down, not removed | CONFIRMED | P3-08. The closing word inside the runner is in P3-07. |
| pass 1 F10 | No standing capture set | CONFIRMED | P3-02. Filed once with pass 2 finding 8 (R160). |
| pass 1 F11 | Hand-kept shader warm-up | CANNOT TELL | P3-27, the small flag-and-log part only, as the Board ruled. The rest: no job unless the trace shows a hitch. |
| pass 1 F12 | Screens read save data directly | PARTLY CONFIRMED | P3-15 (the small job at the four readers). The view API: no separate job, it is built with the UI rollout and is already a rule in issue 344. |
| pass 1 F13 | Status facts hand-copied | CONFIRMED | P3-26. HANDOFF.md section 0 and LOOP.md are trimmed by the Board itself when the audit closes. |
| pass 2 P1 | Every explosion is one tiny smoke puff | CONFIRMED | P3-04 (price two routes, Ryan picks) then P3-16 (the build). |
| pass 2 P2 | Biggest moments have no weight | CONFIRMED | P3-03 (Muse: sizes and times) then P3-17 (the build). |
| pass 2 P3 | Ship paint is one flat colour | CONFIRMED | No new paint job: in flight under issue 209 round 7 (PR 341, step 2; the Board sent the layered route on Nov 10). P3-14 keeps the far side and underside stills and the per-texture licence lines in the recipe. Per-faction paint recipes come with issue 276. |
| pass 2 P4 | Dark ships vanish, pale ships burn out | CONFIRMED | P3-02 (the standing fleet sheet) and P3-13 (the readability pass). |
| pass 2 P5 | Thin ruler lines in hits | CONFIRMED | P3-18, with P7. |
| pass 2 P6 | Shields: no resting state, one balloon | CONFIRMED | P3-22, with a cost report (R160). |
| pass 2 P7 | Shells, bolts and beams are plain shapes | CONFIRMED | P3-18, with P5. |
| pass 2 P8 | Looks judged from the wrong cameras | PARTLY (confirmed on the facts) | P3-02 (the bench, and the two capture defects). The bake scripts are back on main (PR 340; checked: tools/blender/vfx/bake_weapons.py and pack_weapons.py exist). Look numbers into data and the end of the shader text patch are in P3-16. |
| pass 2 P9 | Death puffs off the hull | CONFIRMED | P3-05, widened to every death kind (R160). |
| pass 2 P10 | Nebula and storm hexes are flat puffs | CONFIRMED | P3-19 (replaces issue 139): measure first, fallback priced beside the fog. |
| pass 2 P11 | Planet and rocks are smooth noise | CONFIRMED | P3-20 (replaces issue 140). |
| pass 2 P12 | Station reads as a low slab | PARTLY CONFIRMED | P3-24 (replaces issue 199), blocked until the recipe is merged with its conditions met. |
| pass 2 P13 | Outline gate passes a wrong front | CONFIRMED | No new hull job: the per-third score, inner edge check and blink sheet were sent to round 7 (issue 209). P3-14 makes them standing recipe stages and adds the second camera. |
| pass 2 P14 | Three factions need their own materials | PARTLY CONFIRMED | No job now. Waits on the concept redo (issue 276, R138), as the Board ruled. Add one line to issue 276 so it is not lost. |
| pass 2 P15 | Shield surfaces read as line art | CONFIRMED | P3-23, after P3-22. |
| M1 | Unreproduced numbers would size jobs | accepted (R160) | No job. Re-measured here at the pin; see section 4. The job sizes use my numbers. |
| M2 | The fire ruling was cited as R158, which was not at either audit pin | accepted (R160) | No job. R158 is on main at the pin (FINDINGS line 185). Every job here that touches fire cites R88 beside R158. |
| M3 | A save made by one twin and loaded by the other is untested | accepted (R160) | P3-25. See "could not decide": the Godot save is a fresh format by ruling R33. |
| M4 | Pass 2's captures were not inside its pin | accepted (R160) | No job. Checked: all 43 images are on main at my pin in docs/shots/audit_2026_11/. |
| M5 | Deleting the copies must update export_campaign.js | accepted (R160) | P3-11 names that file and the other ten that mention the folders. |

## 4. Numbers re-measured at the pin (miss M1)

The outside check asked that counts nobody had reproduced be measured again before they size a job. Mine, at 34565f3:

| Claim | In the audit (its pin) | At 34565f3 | How |
|---|---|---|---|
| F2: GDScript lines under godot/ | 56,242 | 57,293 | wc over every .gd file |
| F2: outside test folders | 49,151 | 49,799 | same, without */test/* |
| F2: lines in the four files GitHub loads | 10,395 | 10,858 | jsm.gd, rules.gd, battle_api.gd, campaign.gd |
| F2: scripts under godot/**/test | 58 | 60 .gd files (90 with .js and .sh) | find |
| F3: copies that differ from the root | 2 files | 0 | oracle_copy_test PASS |
| F4: failing findings tests | 46 of 80 | 47 of 80 | run_all_checks.js; ADM-2 fails again |
| F4: ids on the known list | 50 | 50; 3 of them pass (ADM-5, ADM-6, EVT-3) | checks_baseline.json |
| F4: CHECK count ignored | 14 | 14 | the checks row |
| F7: rows in LINEAGE_TREES | 288 | 288 | the repo loader |
| F7: rows with an effect | 191 | 239 | after the Hullbreakers and Hegemony jobs |
| F7: rows with no effect | 97 | 49 | the INERT list |
| F7: fixtures that fire | 137 | 173 | tree_effects_test PASS line |
| F7: effect rows named by no fixture | 54 | 66 | not named in tree_effects_test.js or scenarios.json |
| F10: probe and shot scripts | 25 | 26 | *_probe.gd and *_shots.gd |
| F10: job files in tools/pc/jobs | 48 | 48 | ls |
| F11: shader creation sites outside fx | 63 | 63 | grep |
| F12: direct save reads in story, scenes, ui | 66, 44, 86 | 54, 32, 71 (plus main 13, render 9, world 1) | my pattern differs: RUN, run.get(, run[, Bs.get(, Bs[ |
| F12: direct readers of the cached Nemesis field | not counted | 4 | story.gd:141, :261, :295; battle.gd:4149 |
| F13: scenarios against "48 of 48" | 193 | 229 | scenarios.json keys |

Lines that moved since the audit pins (the jobs use the new numbers): run_all_checks.js 85 is now 87 and 94 is now 96; fx.gd 849 is now 888, 888 is now 927, 202 is now 210 to 213; fx_weapons.gd 134 is now 136 and 973 is now 1096; rules.gd 3570 is now 3702. Every pass 2 line I checked is where the audit said.

## 5. Order, lanes and what can run side by side

**The Board's order, which I follow:**
- R157 for looks: the look bench first, then the rebake and the big hits (pass 2 findings 1, 2, 9), paint and the battle camera pass (3, 4, 13), shields (6, 15), lines and beams (5, 7), maps (10, 11, 12), materials with the concept redo (14).
- R160 for code health: the two gate probes before any load-everything job (done, PR 346); sort the known-failure list before any shrink rule; the runner pastes its check lines first; the small alias job for F12, the view API with the screen rollout.
- R155: fixture state from real functions; name every copy.

**Where I would change it, and why:**
1. P3-01 (the placeholder stop) is filed ahead of the bench. The outside check asked for it to be named first, and R157 says bench first. They do not compete: one is a workhorse job, the other an Opus thread, and they start together.
2. P3-05 (death puffs) goes right after the bench, before the rebake. R157 groups it with the rebake. It is small, visible, and does not wait on Ryan's pick. Its one number is redone in P3-16.
3. P3-13 (battle camera readability) goes right after the bench too. R157 puts it after the big hits. It needs only the fleet sheet, and it is limited to light and look data, so it does not touch the paint work in the ship round.
4. P3-18 (trails and beams) goes ahead of the shield jobs. R157 has shields first. Shields wait on a recipe ship in the game, the contract and a pick. Trails wait only on the new explosion pictures.
5. P3-11 (delete the copies) is slotted between tree jobs, right after issue 347, so job 7b's brief no longer names copies.
6. P3-03 (Muse's staging table) starts now. It is text, costs no GPU and gates P3-17.

**Lanes.**

| Lane | Rule | Jobs, in order |
|---|---|---|
| Tree lane (touches data.js, battle.js, the tree tests) | one at a time | issue 347, then P3-11, then job 7b, then P3-12, then the mastery and balance jobs already planned |
| GPU lane (Ryan's PC, RTX 5080) | one GPU job at a time; each waits for a go file | ship round 7 and UI rollout captures (already waiting), P3-02, P3-04, P3-05 captures, P3-13, P3-27 trace, then P3-16, P3-17, P3-18, P3-19, P3-20, P3-21, P3-22, P3-23, P3-24 |
| Workhorse lane (not tree) | two runs can share the PC; never two jobs on the same files | P3-01, P3-07, P3-08, P3-15, P3-25, P3-26 can each run beside a tree job. P3-07 and P3-28 share files. P3-10 and P3-15 share battle.gd. P3-09 waits on P3-06 |
| Claude threads | two or three at once, the Board included | P3-02 first when a slot frees; then P3-10 (cloud) or P3-04 |
| Muse | its own watcher | P3-03 after the ledger job (issue 343) or beside it |
| Board | its own sittings | P3-06; applying workflow patches from P3-08 and P3-28; swapping the PC runner copy after P3-07 and P3-28 |

**Can start today with no wait:** P3-01, P3-03, P3-06, P3-07, P3-08, P3-15, P3-25, P3-26, and the contract half of P3-14. P3-02 and P3-10 need only a thread slot (and, for P3-02, a GPU window).

## 6. The ranked job list

Filing order is rank. The fixed block is the one AGENTS.md defines, in the wording the live issues use (issue 347 for a workhorse job, issue 344 for a worker thread, issue 343 for Muse). The done test is the "Done when" line. Full issue text, with the standing rules, is in the JSON file. Jobs name each other by P3 key; the Board swaps in the issue numbers as it files them.

Sizes are in agent runs and review rounds, from the board's own history: a small workhorse job is one run (issue 246: 20 minutes; issue 26: 38; issue 335: one run, 0.08 USD); a larger one is one or two (the Hullbreakers tree took two runs, the Hegemony tree one); a workhorse job with captures took one run of 81 minutes (issue 232); an Opus thread job is one thread run, one outside check and one Board round (issues 121, 122, 231); looks jobs have taken many rounds (gun smoke: seven runs; the ship route: seven rounds). No hours anywhere.

### The top 15

### 1. P3-01: Placeholder hulls fail loudly, and one get-ship-files step for every capture job

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN. Checked: godot/render/ship_view.gd has no error call on a missing hull. Released to the workhorse beside the tree job (different files).**

Seat: DeepSeek workhorse (label opus). Labels: opus. Covers: pass1 F5.

```
Owner: opus (released to the DeepSeek workhorse)
Brief: below; contrib/claude_fable/reviews/audit_pass1_code_health_2026_11.md finding 5 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (F5); FINDINGS R144, R153, R155, R160; LOOP.md Known traps (fresh checkout has no hulls)
Deliver to: godot/render/ship_view.gd; one shared helper for capture scripts under godot/render/ or godot/bench/; the capture, probe, shot and bench scripts under godot/ that draw ships (godot/fx/test/, godot/fx/gallery/, godot/bench/, godot/world/, godot/scenes/battle/ shot paths, godot/campaign/test/ shot scripts); tools/pc/get_ship_files.bat (new) and the one line in tools/pc/work_issue.bat that calls it; docs/shots/issue-<number>-deepseek/
Branch: work/issue-<number>-deepseek
Effort: DeepSeek workhorse, cap 90 minutes
Done when: a missing hull prints one error line naming the hull and is counted; every capture, probe, shot and bench script exits non-zero with "placeholder hull: <code>" and writes no picture when any ship on screen is a placeholder (proved by running one capture script on a fresh clone with no hulls: non-zero exit, no image; and with hulls copied in: pass); tools/pc/get_ship_files.bat copies godot\gen and godot\assets\ships from a named source folder (copy only), checks every file against the sha256 values in godot/assets/ships/manifest.json and exits non-zero with the list of mismatches; the game itself and GitHub's checks still run without hulls (the stop is for capture runs only); Ryan sees nothing new in the game, and never again gets a sheet of grey blocks
```

- **Start from (re-checked at 34565f3):**
  - godot/render/ship_view.gd:117 (the plain block fallback) and :30 to :35 (manifest() returns an empty table when res://gen/manifest.json is missing). The file has no push_error, push_warning or printerr at the pin (0 hits).
  - godot/.gitignore lines 2 and 5 (gen/ and assets/ships/*/ are out of git by design).
  - tools/pc/work_issue.bat:69 (fresh clone; no step copies or builds ship files).
  - tools/pc/jobs/bench207_scene_gate.bat:34 (the one existing copy step, a robocopy from build\godot\assets\ships).
  - godot/assets/ships/manifest.json (36 ships; every file has bytes and sha256).
  - godot/fx/test/vent_look_probe.gd:161 (an existing "if not sv.a4" placeholder test to copy).
  - Counted at the pin: 26 files named *_probe.gd or *_shots.gd under godot/. Use one shared helper so each script change is one line.

- **Notes for the build:**
  - ship_view.gd: when it falls back to the block, print one error line with the hull code and raise a static counter. Do not change what is drawn.
  - One helper: "stop if any placeholder" (reads the counter, prints the codes, quits with a non-zero exit code). Call it from every script that saves pictures or measures a scene, before the first picture is written.
  - get_ship_files.bat: source folder as the first argument, with a default; copy only, never delete; verify sha256 against the manifest; non-zero exit on any missing or wrong file. Call it from work_issue.bat before the agent starts, and say in the task text where the hulls came from.
  - Prove both ways on the PC and paste the two outputs in the report.

- **What Ryan will see:** Nothing changes on screen. A capture run with no ship files now stops and says "placeholder hull" instead of sending pictures of blocks.

- **Size:** 1 workhorse run (history: issue 246 took 20 minutes, issue 26 took 38, issue 335 one run), 1 Board review round, 0 owner rounds. What drives it: the number of scripts to touch (26) and one fresh-clone proof on the PC.

- **Waits on:** Nothing. Can run beside a tree job (no shared files) and beside P3-02.

- **Risk if done badly:** If the stop is too eager the game or GitHub's parity run stops wherever hulls are absent (GitHub has none). If it is too weak, a scene with some hulls missing still passes. A copy step that deletes or mirrors could remove files on Ryan's PC: copy only.

### 2. P3-02: Look bench: one standing capture set at the three real cameras (replaces issue 333)

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE WITH A CHANGE. The GPU is the Board's for the night of Nov 9 to 10 (R160), so no go file is needed tonight; on any other day it waits for Ryan's window. It runs as a helper inside the Board thread, which has the PC folder (R160 lesson), after the ship round 7 sheets.**

Seat: Opus worker thread with PC work through the queue (label opus), then the outside check on issue 256. Labels: opus. Covers: pass1 F10, pass2 P8, pass2 P4 (the standing fleet sheet).

```
Owner: opus (a Claude worker thread started by the Board; PC work through the queue while Codex is parked)
Brief: below; contrib/claude_fable/reviews/audit_pass1_code_health_2026_11.md finding 10 and contrib/claude_fable/reviews/audit_pass2_graphics_effects_2026_11.md findings 4 and 8 with their Board verdicts; contrib/muse/reviews/audit_pass1_holes_2026_11.md (F10, P4, P8); FINDINGS R118, R153, R155, R157, R160; docs/shots/audit_2026_11/README.md (how the auditor's probe made its sheets)
Deliver to: godot/bench/look_bench.gd and look_bench.tscn (new), godot/bench/README.md, tools/pc/jobs/look_bench.bat (new, double-click), a sheet maker script beside it, docs/shots/look_bench/ (baseline sheets made from main, with a README), .claude/skills/screenshot-verdict/SKILL.md (rewritten around the bench), and two small capture repairs only: godot/world/world_bake.gd and godot/scenes/campaign/campaign_scene.gd
Branch: opus/issue-<number>
Effort: one worker thread; one GPU window for the baseline and the repeat run
Done when: one double-click .bat makes, from any commit: (a) the moments sheet: each weapon on a hull and on a shield, each shield state (hit, low, break), each death class, plus the eight looks PR 327 changed that nobody has seen (las muzzle, prism muzzle, missile launch, torpedo on a shield, lance burn, Chorus bile hit, gauss exit, crit), each at the three real cameras (170, 60, 26) as 30 frames a second strips; (b) the fleet sheet: all 36 ships at true pixel size at camera 170 over the darkest sky, the brightest sky and a storm map; (c) a before and after mode: two commits side by side plus one difference number per still; fixed seed and fixed effect clock; two runs on the same commit match within a stated tolerance, and the README says how wreck physics (real time, R118) is pinned or which stills are exempt; one deliberate one-number change to one effect shows a difference only in the stills that contain that effect; the .bat stops with "placeholder hull" if any ship is a block; baseline sheets from main are in docs/shots/look_bench/; Ryan sees the moments sheet and the fleet sheet
```

- **Start from (re-checked at 34565f3):**
  - godot/bench/scene_gate.gd:39 to :42 (the --still mode: fixed effect clock, every worker job waited for) and :206 (_still_run, seed 2070). This is the repeatable pattern.
  - godot/fx/test/vent_look_probe.gd (the probe pattern; :137 reads the stray puff check, :161 tests for a placeholder).
  - The auditor's probe (audit_probe.gd) is not in git. It lives on the PC in Downloads\voidsworn_test\audit2\repo. Copy it in as the starting point. It made every weapon, shield and death strip in under two minutes of GPU time.
  - godot/render/camera_rig.gd:9 (r 170, the battle camera) and :15 (min_r 26, the closest the game allows). The middle camera is 60.
  - godot/fx/gallery/ (the effects reel: a free camera closer than the game allows; keep it out of the bench or pin its camera).
  - godot/world/world_bake.gd:24 (pass 2: the reel printed "Parent node is busy setting up children" and drew no nebula) and godot/scenes/campaign/campaign_scene.gd:114 (pass 2: the map tool's last still was the loading screen). Both lines are there at the pin; I did not run them.
  - tools/pc/jobs/ui271_build_shots.bat (the queue job pattern).
  - .claude/skills/screenshot-verdict/SKILL.md describes the frozen browser build and never mentions Godot.

- **Notes for the build:**
  - Build the bench scene from the scene gate still mode and the probe pattern. Three cameras only: 170, 60, 26.
  - Moments list in one data file, so a later job adds a moment by adding a row.
  - Sheet maker: strips at 30 frames a second, before and after side by side, one difference number per still.
  - Run it twice on main. State the tolerance. List any still that cannot be made to repeat and why.
  - Fold in from retired issue 233: capital and frigate deaths at the shipped numbers side by side, and one ship per weight class hit by the same weapon.
  - If the late-shader counter of P3-27 exists, print it at the end of the run.
  - Rewrite the screenshot-verdict skill: "run look_bench.bat, compare with the baseline, report what differs".
  - PC job: write the .bat so it waits for Downloads\voidsworn_test\look_bench\go.txt. The Board queues it and commits the go file when Ryan gives a GPU window. Never delete anything on the PC.

- **What Ryan will see:** Two sheets he can read on a phone: every weapon, shield and death at the cameras he plays from, and all 36 ships at the size they really are in a battle. From then on every effects or ship change comes with the same sheet, before and after.

- **Size:** 1 thread run, 1 GPU window (the audit made 41 captures in about 23 minutes on Nov 10), 1 outside check on issue 256, 1 Board review round, 1 owner look. A second run is likely if the moments do not repeat. What drives it: making the moments repeat (wreck physics, worker timing).

- **Waits on:** A free Claude thread slot (the limit is three and all three were in use at the pin) and a GPU window from Ryan. Nothing else. One GPU job at a time.

- **Risk if done badly:** A bench that does not repeat cries wolf on every pull request and gets ignored. A bench at the wrong cameras repeats the old mistake. A bench that quietly draws blocks repeats issue 281 run 6.

### 3. P3-03: Hit and death staging table: sizes in pixels and times in seconds for every big moment

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN. Muse takes it after the ledger (issue 343). It does not wait for question 6: Muse picks its own reference games and Ryan's names fold in when he gives them.**

Seat: Muse (label muse). Labels: muse. Covers: pass2 P2, pass2 P1 (fire limits), M2.

```
Owner: muse
Brief: below; contrib/claude_fable/reviews/audit_pass2_graphics_effects_2026_11.md findings 1 and 2 with their Board verdicts; contrib/muse/reviews/audit_pass1_holes_2026_11.md (P1, P2); FINDINGS R88, R90, R157, R158, R160; godot/fx/API.md line 116 (what a capital death already promises); docs/shots/audit_2026_11/ sheets fx_01, fx_08, fx_18, fx_19, fx_20 and ships_04
Deliver to: contrib/muse/design/hit_staging_2026_11/synthesis.md (plus the legs)
Branch: muse/issue-<number>
Models (Muse): Rey writes a blind leg first, DeepSeek and Qwen write, Flash and Grok ideation only, Rey chairs; Argon blocked since Nov 5
Done when: one table with a row per event (las hit, macro hit, lance hit, torpedo on a hull, torpedo on a shield, frigate death, cruiser death, capital death); for each of three beats (flash, body, aftermath) the size on screen in pixels at the battle camera at 1080p and the time in seconds; each step of the ladder clearly bigger than the one before, with the ratio stated; the longest any flame may live, inside R88 and R158 (flash and snuff out); a reduce-flashing variant per row (slower glow, same size); which parts of the capital death text in godot/fx/API.md line 116 do not read on screen today; a reference list per event (links to public clips or stills, one line on what to take from each; links only, no copied frames in the repo); open questions for Ryan as multiple choice with a pick; Ryan gets a one-page read
```

- **Start from (re-checked at 34565f3):**
  - Sizes to work from (audit sheet ships_04, camera 170 at 1080p): a frigate is about 60 to 80 pixels long, a cruiser about 150 to 180.
  - godot/fx/fx_weapons.gd:1055 (the torpedo flash lives 0.32 s) and :1059 (its gas 0.42 s). Both lines hold at the pin.
  - godot/fx/API.md:116 (the capital death sequence as written: jets, a tear, a split, later blasts, cooling coals).
  - godot/render/camera_rig.gd:9 (r 170) and :15 (min_r 26).

- **Notes for the build:**
  - Blind Rey leg first, from the captures and the cited lines only.
  - The chair checks every cited line against the repo. In the holes check one leg's pass 2 text was rejected as invented; do not carry an unchecked number into the table.
  - Ask Ryan (through the Board) for three to five games whose hits he likes, if he has not named them yet.

- **What Ryan will see:** A one-page table: how big and how long each hit and death should be, in the units he can check on a sheet.

- **Size:** 1 Muse run, 1 Board read, 1 short owner read. What drives it: the chair's citation check.

- **Waits on:** Nothing. It is text, so it runs now beside everything else.

- **Risk if done badly:** Sizes invented without looking at the captures cannot be built, or break R88. Then P3-17 builds to the wrong targets.

### 4. P3-04: Explosion pictures, step 1: bake two routes, measure the bake time, one sheet for the pick

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN. Two routes, as R160 says; no third route.**

Seat: Opus worker thread with PC work through the queue (label opus), then the outside check on issue 256. Labels: opus, blocked. Covers: pass2 P1 (step 1: price the routes).

```
Owner: opus (a Claude worker thread started by the Board; PC work through the queue while Codex is parked)
Brief: below; contrib/claude_fable/reviews/audit_pass2_graphics_effects_2026_11.md finding 1 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (P1: the hybrid route); FINDINGS R88, R116, R146, R157, R158, R160 point (c); tools/blender/vfx/README.md
Deliver to: tools/blender/vfx/ (the two bake variants and their .bat files; every bake keeps its script), tools/pc/jobs/ (the queue job), docs/shots/look_bench/explosion_routes/ (the sheet and a README with the numbers). No look change in the shipped game in this job: the candidates load behind a test switch only
Branch: opus/issue-<number>
Effort: one worker thread; one or two GPU bake windows
Done when: two candidate routes exist for the weapon impact and the capital death flash, each baked by a script in the repo: route A, a 256 cell fire and smoke simulation with the detail noise on and the gas filling about four fifths of each cell; route B, the hybrid: a grid of about 128 for the smoke body plus authored hot cores, colour ramps and spark overlays, with two or more source shapes and three seeds; for each route the measured wall-clock bake time per effect on the RTX 5080, the file sizes and any gate scene cost change (R116); one bench sheet at cameras 170, 60 and 26 with today, A and B side by side for a torpedo hit and a cruiser death, each in two fire amounts inside R88 (flash only; flash plus a short hot core that is gone within a stated fraction of a second); Ryan picks the route and the fire amount on that sheet
```

- **Start from (re-checked at 34565f3):**
  - tools/blender/vfx/bake_death.py:11 (--resolution default 64), :20 (use_noise False), :26 (flow type SMOKE, temperature 0).
  - tools/blender/vfx/bake_weapons.py:19, :40 and :46 (the same three settings). The file is back on main since PR 340.
  - godot/fx/atlases/weapons/bake_manifest.json:22 and :37 ("resolution": 64).
  - godot/fx/fx_death.gd:171 to :173 (the crop that works round the small puff).
  - Measured fill today: 55 of 256 pixels (weapon impact) and 91 of 512 (capital death flash), by the Board; about 52 and 92 by the outside check.

- **Notes for the build:**
  - Bake the smallest fair sample of each route first and write down the time. A 256 grid has about 64 times the cells of the 64 grid per frame.
  - Use the bench (P3-02) for the sheet. Battle camera first.
  - Stop for Ryan's pick. Do not start the full rebake here (that is P3-16).

- **What Ryan will see:** One sheet: today's explosion beside two better ones, at the size he plays at and close up, with how long each takes to make. He picks one, and how much fire.

- **Size:** 1 thread run, 1 to 2 GPU bake windows (the bake time is the unknown this job measures), 1 outside check on issue 256 (tools only, as for PR 336), 1 Board round, 1 owner pick.

- **Waits on:** P3-02 (the bench makes the sheet), a GPU window, a free thread slot. One GPU job at a time.

- **Risk if done badly:** Pricing one route only, or without real bake times, sends P3-16 down the dear road. Showing fire that breaks R88 wastes Ryan's round.

### 5. P3-05: Death puffs sit on the plating, and the stray puff check covers every death kind

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN. Checked: record_spawn has 0 hits in godot/fx/fx_death.gd; the vent offset is at line 179.**

Seat: DeepSeek workhorse (label opus). Labels: opus, blocked. Covers: pass2 P9.

```
Owner: opus (released to the DeepSeek workhorse)
Brief: below; contrib/claude_fable/reviews/audit_pass2_graphics_effects_2026_11.md finding 9 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (P9: record_spawn is never called from fx_death); FINDINGS R153 (the same defect in the braking puffs, and how run 7 proved its repair), R157, R160 point (e)
Deliver to: godot/fx/fx_death.gd, godot/fx/fx.gd (record_spawn use only), godot/fx/test/ (the check), docs/shots/issue-<number>-deepseek/
Branch: work/issue-<number>-deepseek
Effort: DeepSeek workhorse, cap 90 minutes
Done when: every picture fx_death spawns (the vent kind, the flash kind and any other) records its spawn with fx.record_spawn; the stray puff check FAILS on main first for a cruiser death on a hull that does not fill its box (paste the failing output), then passes after the change; the root of the gas sits on the plating, found with the hull ray the braking puffs use since PR 327, not the middle of the picture pushed out by a fixed share of the ship's length; bench strips before and after of a frigate, a cruiser and a capital death at cameras 170 and 26 with no pale ball in empty space in any frame; the flash safety test and fx_smoke pass; Ryan sees the strip
```

- **Start from (re-checked at 34565f3):**
  - godot/fx/fx_death.gd:179 (the offset: n * size * 0.42 for the vent kind) and :1045 (size is hull.L * 0.85). Both hold at the pin.
  - godot/fx/fx.gd:725 (record_spawn) and :739 (stray_spawns). Callers at the pin: fx_weapons.gd:456 and :501, fx_ship.gd:709. None in fx_death.gd.
  - godot/fx/fx_ship.gd:691 to :700 (the PR 327 pattern: a ray from outside back to the hull, skip when it misses).
  - godot/fx/test/fx_smoke.gd:153 and vent_look_probe.gd:137 (where the check is read).
  - Evidence: docs/shots/audit_2026_11/fx_18_death_cruiser_close.jpg cell 2 and map_02_battle_scene_close_dying_ship.jpg.

- **Notes for the build:**
  - Make the check fail on main first. A check that allows a whole hull-box radius passes while the puff floats: that was the run 6 mistake in R153.
  - Take the offset from the real size of the gas in today's pictures and say so in a comment: P3-16 changes the pictures and must redo this number.
  - Captures need the PC-built hulls. Use get_ship_files.bat from P3-01. If the probe shows blocks, stop and say so.

- **What Ryan will see:** No pale balls in empty space next to a dying ship.

- **Size:** 1 to 2 workhorse runs (the same kind of repair, issue 281 run 7, took one run once the hull copy step was in the brief), 1 Board round frame by frame, 1 owner look.

- **Waits on:** P3-01 (the hull copy step) and P3-02 (the strips). If the bench is late, use the vent_look_probe pattern and say so. A short GPU slot for the captures.

- **Risk if done badly:** A loose check passes while the puff still floats. Moving the puff into the hull hides it instead.

### 6. P3-06: Sort the known-failure list into bug, opinion, ruled-not-built or stale (before any shrink rule)

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN. The Board does it. ADM-2 (passing at the audit pin, failing at 34565f3 behind a PASS row) is sorted here first.**

Seat: the Board thread itself (label opus). Labels: opus. Covers: pass1 F4 (step 1: sort the list), M1 (the 46).

```
Owner: opus (the Board thread itself: judgment, not a coder job)
Brief: below; contrib/claude_fable/reviews/audit_pass1_code_health_2026_11.md finding 4 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (F4: sort first, then shrink); FINDINGS R155, R160 point (a); contrib/opus/tools/checks_baseline.json; contrib/muse/tools/findings_tests/findings_tests.js
Deliver to: contrib/opus/tools/checks_baseline.json (a tag and one line of reason per id), contrib/opus/reviews/known_failures_triage_2026_11.md, and one new issue per real bug
Branch: opus/issue-<number>
Effort: one Board sitting in the cloud (node only); an optional Muse second read, since the suite is Muse work
Done when: each of the 50 listed ids carries one tag (bug, opinion, ruled-not-built, stale), one line of reason and, for a bug, an issue number; the 3 ids that pass today (ADM-5, ADM-6, EVT-3) leave the list; ADM-2 is explained (it passed at the audit pin da01a7a and fails at 34565f3 with no signal); the opinion tests are named for removal from the gate (the removal itself is P3-09); the standing checks still exit 0; nothing shrinks before this merges
```

- **Start from (re-checked at 34565f3):**
  - contrib/opus/tools/checks_baseline.json (recordedDate 2026-11-01; 50 ids; the note says 72 assertions = 11 bugs, 9 probable, 11 ruled, 41 opinions).
  - Re-measured at 34565f3 with node contrib/opus/tools/run_all_checks.js: 80 tests, 33 pass, 47 fail. The audit pin had 46. The extra one is ADM-2 ("hunt Command text consistent across admirals": Vorn's Command no longer promises the torpedo reload the other three do). I did not check whether that is a bug or the R145 pick (Vorn's Command became Interdiction strike).
  - contrib/muse/tools/findings_tests/findings_tests.js: ADM-2 at line 88, NEM-3 at 671, UI-5 at 1060. NEM-3 ("at most one adaptation is earned per sector") and UI-5 ("cancel paths clear the sticky wing selection") read like real defects.

- **Notes for the build:**
  - Run the suite, read each failing test and the code it points at, tag it.
  - For each bug: file an issue with the fixed block and a done test. Do not repair it here.

- **What Ryan will see:** Nothing on screen. He gets a short list: which of the 47 known failures are real bugs, each with its job.

- **Size:** 1 Board sitting, 0 to 1 Muse read, 0 owner rounds. What drives it: 50 judgments.

- **Waits on:** Nothing.

- **Risk if done badly:** Tagging a real defect as opinion removes it from the gate for good.

### 7. P3-07: Runner 1: the runner runs the checks itself and pastes the real lines into every pull request

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN.**

Seat: DeepSeek workhorse (label opus). Labels: opus. Covers: pass1 F8 (check lines, task text), pass1 F9 (closing word in the runner).

```
Owner: opus (released to the DeepSeek workhorse)
Brief: below; contrib/claude_fable/reviews/audit_pass1_code_health_2026_11.md findings 8 and 9 with their Board verdicts; contrib/muse/reviews/audit_pass1_holes_2026_11.md (F8: the pasted check lines are the highest-value item, file them first); FINDINGS R129, R155, R160 point (a); LOOP.md Known traps
Deliver to: tools/pc/work_issue.bat and tools/pc/work_issue.ps1 only. No workflow file (the PC token cannot push workflow files)
Branch: work/issue-<number>-deepseek
Effort: DeepSeek workhorse, cap 90 minutes, plus one dry run
Done when: after the agent stops, the runner itself runs node contrib/opus/tools/run_all_checks.js and tools\pc\parity.bat nopause, each under its own time limit, and pastes their result rows word for word under the agent's report in a section headed "Checks run by the runner" (the rows, not a summary; a timeout is printed as a timeout); the task text names the real twins: battle.js, data.js and core.js with both oracle folders and both exported tables (or the root files only, once P3-11 has landed); the commit text says Refs, not Closes; proved by a dry run (the runner's dryrun mode) whose commit text shows the pasted rows, and by a second dry run with one check broken on purpose that shows a FAIL row in the commit text; a failed check never stops the push; the Board swaps the PC copy of the runner when no run is active
```

- **Start from (re-checked at 34565f3):**
  - tools/pc/work_issue.bat:83 (the agent's exit code is written down and not used), :93 (git add -A), :99 (git push -q -f).
  - tools/pc/work_issue.ps1:59 ("That report becomes the pull request description"), :64 (the twins line names core.js and campaign_meta.js only), :159 (the commit text ends with "Closes" and the issue number).
  - tools/pc/work_issue.bat:22 (Node 22 is put first on PATH; keep it).

- **Notes for the build:**
  - Add the check step after the agent stops and before the commit text is built.
  - Keep every byte of a run that fails its checks: the push still happens, with the FAIL rows in the text.
  - Leave the push mode, the exit code handling and the refuse list alone. They are P3-28.

- **What Ryan will see:** Nothing on screen. Every workhorse pull request ends with check lines the runner wrote, so "all checks pass" can no longer be only the agent's word.

- **Size:** 1 workhorse run plus 2 free dry runs on the PC, 1 Board review round, then the Board's swap of the PC copy (as with PR 320).

- **Waits on:** Nothing. Do not run beside P3-28 (same files).

- **Risk if done badly:** A check step that hangs eats the run's time cap. A runner that stops after the agent finished loses a paid run's work.

### 8. P3-08: Three known traps removed in code: line endings, closing words, Node version

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN. Checked: there is no .gitattributes at the pin. The Board applies the workflow patch.**

Seat: DeepSeek workhorse (label opus). Labels: opus. Covers: pass1 F9, pass1 F8 (pull request text refreshed on each push).

```
Owner: opus (released to the DeepSeek workhorse)
Brief: below; contrib/claude_fable/reviews/audit_pass1_code_health_2026_11.md finding 9 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (F9: check renormalising before adding .gitattributes); LOOP.md Known traps; FINDINGS R155
Deliver to: .gitattributes (new), package.json (engines), godot/rules/test/run_parity.sh, godot/campaign/test/run_parity_campaign.sh, tools/pc/parity.bat, tools/pc/parity_campaign.bat, contrib/opus/tools/run_all_checks.js (the Node guard only), tools/pc/codex_issue.bat (line order only), and a patch file for .github/workflows/auto_pr.yml named in the report (the Board applies it; the PC token cannot push workflow files)
Branch: work/issue-<number>-deepseek
Effort: DeepSeek workhorse, cap 60 minutes
Done when: .gitattributes sets LF for .js, .gd, .json, .sh, .md and .py and CRLF for .bat; a renormalising check is run and reported (git add --renormalize . then git status): either no file changes, or every file that would change is listed in the report and handled on purpose, never swept into this pull request unseen; a plain git clone on the PC with no autocrlf flag passes campaign parity (paste the lines); run_parity.sh, parity.bat and run_all_checks.js stop with one clear line on a Node major other than 22; the auto_pr patch writes Refs instead of Closes, says the Board reviews and merges, and rewrites the pull request text on every later push; after the merge the Board deletes the three matching lines from LOOP.md Known traps
```

- **Start from (re-checked at 34565f3):**
  - No .gitattributes at the pin.
  - .github/workflows/auto_pr.yml:37 ("Opus reviews and merges."), :38 (appends "Closes" and the issue number), :41 ("PR already open": the text is not refreshed).
  - tools/pc/codex_issue.bat:19 (the clone) and :22 (autocrlf set after it).
  - tools/pc/jobs/bench207_scene_gate.bat:21 and tools/pc/jobs/ui231_shots.bat:15 (clones without the flag).
  - tools/test_onboarding.js:10 (an existing Node 22 guard to copy). package.json has no engines field.

- **Notes for the build:**
  - Check the renormalising result before committing .gitattributes. A .bat file stored with LF must not be flipped unseen, and cmd needs CRLF.
  - Deliver the workflow change as a patch file, not as a pushed change.

- **What Ryan will see:** Nothing on screen. Fewer jobs die for no reason on his PC, and merged work stops shutting the wrong issue.

- **Size:** 1 workhorse run, 1 Board review round plus the Board applying the workflow patch. What drives it: the renormalising check and one fresh-clone parity run on the PC.

- **Waits on:** Nothing. Can run beside P3-07 (no shared files).

- **Risk if done badly:** .gitattributes can renormalise every .bat in the repo into one huge whitespace diff. A wrong Node guard blocks GitHub's checks for every pull request.

### 9. P3-09: The checks table tells the truth: no PASS over failures, a known list that can only shrink

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN.**

Seat: DeepSeek workhorse (label opus). Labels: opus, blocked. Covers: pass1 F4 (step 2: the runner), pass1 F3 (the drift guard row).

```
Owner: opus (released to the DeepSeek workhorse)
Brief: below; contrib/claude_fable/reviews/audit_pass1_code_health_2026_11.md finding 4 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (F4); the triage file from P3-06; FINDINGS R155, R160 point (a)
Deliver to: contrib/opus/tools/run_all_checks.js, contrib/opus/tools/checks_baseline.json, a small self-test beside them (named so the runner picks it up), contrib/muse/tools/findings_tests/ (only to take the opinion-tagged tests out of the gate), contrib/muse/tools/oracle_drift/oracle_drift_guard.js (its summary line only)
Branch: work/issue-<number>-deepseek
Effort: DeepSeek workhorse, cap 60 minutes
Done when: the table has four words: PASS (zero failures inside the row), KNOWN (only listed failures, with the count), FAIL and SKIP; no PASS row carries a failure count, a CHECK count or a "differed" count; the check pack row holds its CHECK count against a ceiling in the baseline file that can only go down (14 at the pin); a listed id that passes is an error until it is taken off the list; opinion-tagged tests are out of the gate; the drift guard row is KNOWN, not PASS, while constants differ (12 at the pin); a skipped optional check is named in the last line; exit code 0 for PASS, KNOWN and SKIP, 1 for FAIL; every row's detail is its own PASS or FAIL line; a self-test proves three cases: a listed id made to pass gives FAIL, a new failure gives FAIL, a CHECK count of 15 gives FAIL
```

- **Start from (re-checked at 34565f3):**
  - contrib/opus/tools/run_all_checks.js:87 (the pack rule reads the FAIL count only; this was line 85 at the audit pin), :94 to :96 (the findings rule; was :94), :98 to :99 (optional checks turn into SKIP), :126 (the exit code).
  - My run at 34565f3: "findings_tests | PASS | 33 passed, 47 failed", "checks | PASS | 0 FAIL, 14 CHECK", "oracle_drift_guard | PASS | ... 12 differed".
  - Seen in the same run: the tree_handoff_test row shows a data line ("deathless nekhet: ...") as its detail, because the runner takes the last output line.

- **Notes for the build:**
  - Land the runner change and the baseline update in one pull request, so main never goes red for every open pull request at once.
  - Do not change what any check tests. Only how the result is worded and gated.

- **What Ryan will see:** Nothing on screen. The checks table on every pull request stops saying PASS when something inside failed.

- **Size:** 1 workhorse run, 1 Board review round.

- **Waits on:** P3-06 (the sorted list). Do not start before it merges.

- **Risk if done badly:** A shrink rule before the sort deletes real defects. A wording change that flips GitHub's checks red on main blocks every open pull request.

### 10. P3-10: GitHub's checks open the game: load every script, run the headless checks, play one bot battle

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN. An Opus cloud thread when a slot frees; if slots stay full, part (a) alone goes to the workhorse.**

Seat: Opus worker thread, cloud only (label opus), then the outside check on issue 256. Labels: opus. Covers: pass1 F2, M1 (F2 totals).

```
Owner: opus (a Claude worker thread started by the Board) (cloud only; the cloud sandbox has Godot 4.7.2 headless)
Brief: below; contrib/claude_fable/reviews/audit_pass1_code_health_2026_11.md finding 2 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (F2: the two gate probes came first and are in since PR 346; this is the second step); FINDINGS R129, R155, R160 point (a)
Deliver to: godot/tools/ci/ (new: the load-everything script, the list file, the bot battle driver), the scripts under godot/**/test/ that need a small repair to run headless, godot/scenes/battle/battle.gd (the default branch of the event switch only), .github/workflows/checks.yml, tools/pc/jobs/godot_gpu_checks.bat (one .bat for the GPU-only checks, one results file)
Branch: opus/issue-<number>
Effort: one worker thread in the cloud
Done when: (a) a step imports the Godot project headless and loads every .gd file under godot/, and fails on any script error; proved by a throwaway commit that breaks one line in godot/ui/battle/hud.gd turning the pull request red (link the run), then removed; (b) one list file names every script under godot/**/test/ as headless, GPU or retired, with one line of reason each; the headless ones run on GitHub from that list; the GPU ones run from one PC .bat that writes one results file; (c) one bot battle, reached from a real campaign start through the campaign's own functions and never a typed state, plays to its end headless on GitHub; the step fails on any script error and on any "unknown event" line; the battle scene's event switch gets a default branch that logs an unknown event kind once; the checks summary lists the Godot game checks by name; the added run time is stated (the job has a 30 minute limit)
```

- **Start from (re-checked at 34565f3):**
  - .github/workflows/checks.yml:30 to :31 (the standing checks) and :49 to :60 (four Godot test steps at the pin: rules parity, campaign parity, tree hand-off, Nemesis scenarios).
  - Re-measured at 34565f3: 57,293 lines of GDScript under godot/, 49,799 outside test folders, 10,858 in the four files GitHub loads (jsm.gd, rules.gd, battle_api.gd, campaign.gd). So about 38,900 lines are never loaded there. 60 .gd files sit in test folders (90 files with .js and .sh).
  - godot/scenes/battle/battle.gd:1220 (match e["t"]: with no default branch, per the Board verdict).
  - contrib/opus/tools/ui_spec_tests.js (the one UI check on GitHub reads source text, not the screen).
  - GitHub has no ship files, so every ship there is a placeholder block: part (c) runs with the capture stop of P3-01 off, and says so.

- **Notes for the build:**
  - Three commits in this order: (a), then (b), then (c). (a) can merge on its own if (b) or (c) drags.
  - A script that cannot load headless is repaired or marked GPU with the reason. Never skipped "for now": that is how the known-failure list grew.
  - The bot battle uses a fixed seed. If it flakes twice, stop and report instead of adding a retry.

- **What Ryan will see:** Nothing on screen. A broken line in the battle screen or the HUD now turns the pull request red before it reaches his PC.

- **Size:** 1 thread run, a second if many test scripts have rotted; 1 outside check on issue 256; 1 Board review round; 0 owner rounds. History: issue 264 (campaign parity and the Nemesis scenarios into GitHub's checks) was one cloud thread and one pull request (PR 283). What drives it: sorting 60 scripts and repairing the ones that no longer run.

- **Waits on:** A free Claude thread slot. P3-01 first is better (the capture stop it must switch off), not required. Do not run beside P3-15 (both touch battle.gd).

- **Risk if done badly:** A flaky headless battle turns every pull request red (a Godot download flake was already seen on Nov 9). A load step that skips files recreates the known-failure list under a new name.

### 11. P3-11: One copy of the rules files: delete both oracle folders and point every harness at the root

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN. Checked: export_campaign.js, campaign.gd, oracle_copy_test.js, the drift guard and tools/test_onboarding.js all name the oracle folders.**

Seat: DeepSeek workhorse (label opus). Labels: opus, blocked. Covers: pass1 F3, M5.

```
Owner: opus (released to the DeepSeek workhorse)
Brief: below; contrib/claude_fable/reviews/audit_pass1_code_health_2026_11.md finding 3 with its Board verdict (the Board's pick: delete the copies); contrib/muse/reviews/audit_pass1_holes_2026_11.md (F3 and miss M5: the deletion must update export_campaign.js); FINDINGS R155, R160 point (g); contrib/opus/tools/oracle_copy_test.js (PR 346)
Deliver to: godot/rules/test/node/ (golden.js, export_data.js; campaign_hooks.js and fnames.js move here), godot/campaign/test/node/ (env.js, export_campaign.js), godot/rules/test/oracle/ and godot/campaign/test/oracle/ (deleted; any still-true README note moves to the test README), godot/rules/test/run_parity.sh, godot/campaign/test/run_parity_campaign.sh, godot/campaign/test/run_nem_scenarios.sh, tools/pc/parity.bat, tools/pc/parity_campaign.bat, tools/test_onboarding.js, contrib/opus/tools/oracle_copy_test.js, contrib/muse/tools/oracle_drift/oracle_drift_guard.js, godot/campaign/campaign.gd (the comment at line 3 only), godot/campaign/data/campaign_tables.json and godot/rules/data/tables.json (re-export only)
Branch: work/issue-<number>-deepseek
Effort: DeepSeek workhorse, cap 90 minutes
Done when: no oracle folder exists; both parity harnesses, the Nemesis scenarios and both exporters read the root game files by default; rules parity, campaign parity (30 seeds), the tree hand-off check and the Nemesis scenarios are green on GitHub; proof that parity still bites: one number changed in the root battle.js on a throwaway commit makes rules parity FAIL (paste the output), then it is reverted; a hard check row fails when either committed table differs from a fresh export; a search for "test/oracle" over .js, .sh, .bat, .gd, .ps1, .py and .yml files finds nothing live; FNAMES and TIPS are read from the root ui3d.js
```

- **Start from (re-checked at 34565f3):**
  - godot/rules/test/node/golden.js:16 and export_data.js:11 (ROOT defaults to ../oracle; the VS_ORACLE variable already overrides it).
  - godot/campaign/test/node/env.js:13 (the same default) and export_campaign.js:1 and :44 (writes "oracle": "godot/campaign/test/oracle" into the table file).
  - godot/campaign/test/run_parity_campaign.sh:4 and :10; tools/pc/parity.bat:14; tools/pc/parity_campaign.bat:3; tools/test_onboarding.js:44 to :46.
  - Files in the rules oracle folder with no root twin: campaign_hooks.js, fnames.js, README.md. In the campaign one: README.md.
  - Checked at 34565f3: every copy matches its root file (oracle_copy_test PASS in my run) and "Ram First" has 0 hits in data.js and in both table files.

- **Notes for the build:**
  - Change the defaults to the repo root, move the two Godot-only helper files, delete the folders, re-export both tables.
  - Turn oracle_copy_test.js into: the folders must not exist, and the committed tables equal a fresh export.
  - Run tools\pc\parity.bat on the PC: the workhorse's own self-check depends on it.

- **What Ryan will see:** Nothing on screen. The class of bug where the tree screen and the battle disagree about a skill cannot come back through a stale copy.

- **Size:** 1 workhorse run, 2 if the PC .bat files need a second pass; 1 Board review round with the R129 sweep. History: issue 335, in the same files, was one Flash run.

- **Waits on:** Issue 347 merged. This job is in the tree lane: never beside a tree job. The best slot is right after 347 and before job 7b, so 7b's brief no longer names copies.

- **Risk if done badly:** A harness that quietly falls back, or compares the root with itself, makes parity pass on nothing. A broken parity.bat breaks the self-check of every later workhorse job.

### 12. P3-12: Tree table walk: every skill row is tested or on a dated waiting list, and waiting rows are flagged

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN.**

Seat: DeepSeek workhorse (label opus). Labels: opus, blocked. Covers: pass1 F7.

```
Owner: opus (released to the DeepSeek workhorse)
Brief: below; contrib/claude_fable/reviews/audit_pass1_code_health_2026_11.md finding 7 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (F7); FINDINGS R155; contrib/opus/tools/tree_effects_test.js and tree_handoff_test.js
Deliver to: contrib/opus/tools/ (a generated walk check, added to run_all_checks.js), godot/campaign/campaign.gd (lineageNodes: a "waiting" flag), core.js lineageNodes only if campaign parity compares node records (then the re-export too), godot/campaign/test/ (one Godot check of the flag)
Branch: work/issue-<number>-deepseek
Effort: DeepSeek workhorse, cap 90 minutes
Done when: one generated check walks LINEAGE_TREES and fails by name unless every row either has a TREE_FX entry and at least one check that reaches it through the real functions (lineagePick, newRun, startBattle; the skill must be in B.tree), or sits on a waiting list with a date; the list can only shrink; deleting one TREE_FX line makes the check fail by name (paste it); lineageNodes marks a row with no effect as waiting, in the Godot campaign layer, read from the same table the battle reads; behaviour checks (the number the text names) stay the rule for new and changed rows only; the on-screen "Not active yet" mark is NOT in this job: it is one line in the done test of the UI rollout job for the admiral tree screens (group 4)
```

- **Start from (re-checked at 34565f3):**
  - Re-measured at 34565f3 with the repo's own loader: 288 rows in LINEAGE_TREES; 239 have a TREE_FX entry (191 at the audit pin); 49 do not (the INERT list, contrib/opus/tools/tree_effects_test.js:70); 173 fixtures fire; 66 rows with an effect are named by no fixture in tree_effects_test.js or godot/rules/test/scenarios.json.
  - contrib/opus/tools/tree_effects_test.js:106 (the only inert-row test: an inert key must have no TREE_FX entry) and :219 (the PASS line).
  - contrib/opus/tools/tree_handoff_test.js (PR 346): the shape for a check that starts from real picks.
  - godot/campaign/campaign.gd:1008 to :1023 (lineageNodes builds every node the same way) and core.js:376 (its JS twin).
  - Issue 347 (26 of the 49 waiting rows) and job 7b (the other 23) are filling the list now.

- **Notes for the build:**
  - Give each of the 66 untested effect rows the hand-off level check in a loop. That is presence, not behaviour, and the report says so.
  - A waiting row needs a date and a one-line reason. No date, no entry.

- **What Ryan will see:** Nothing yet. When the admiral tree screens are restyled, a skill that does nothing is greyed and says "Not active yet" instead of promising an effect.

- **Size:** 1 workhorse run (the walk over 288 rows takes about two minutes of check time today), 1 Board review round.

- **Waits on:** Tree lane, one at a time: after issue 347 (it edits the same INERT list). Better after P3-11, so no copies need a refresh.

- **Risk if done badly:** A waiting list anyone can add to becomes the next known-failure list. A flag computed differently in the two twins breaks campaign parity.

### 13. P3-13: Battle camera readability pass: every faction readable at the size it is really played

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN. Light map rebakes for the old hulls stay out (R158).**

Seat: Opus worker thread with PC work through the queue (label opus), then the outside check on issue 256. Labels: opus, blocked. Covers: pass2 P4.

```
Owner: opus (a Claude worker thread started by the Board; PC work through the queue while Codex is parked)
Brief: below; contrib/claude_fable/reviews/audit_pass2_graphics_effects_2026_11.md finding 4 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (P4: add a storm map to the sheet); FINDINGS R116, R157, R158; the bench fleet sheet from P3-02
Deliver to: godot/render/look.gd, the light rig under godot/render/, the Glasswright hull material parameters in Godot (no rebakes), docs/shots/look_bench/readability/
Branch: opus/issue-<number>
Effort: one worker thread; one or two GPU capture windows
Done when: on the bench fleet sheet (all 36 ships, true pixel size, camera 170, darkest sky, brightest sky, storm map) every faction's lit side sits inside one stated brightness band, measured per ship from the sheet and listed; no hull is lost against the darkest sky (a rim light gives each dark hull an edge); the Glasswright hull keeps visible lines (no clipped white area above a stated share of the hull); before and after sheets side by side; the bench moments sheet is rerun and shows no effect or shield look changed by accident; gate scene cost before and after (R116: 12.5 ms, frame median at 1080p and GPU at 4K); no close-up is used as evidence; Ryan can tell every faction apart on the sheet without the name tags
```

- **Start from (re-checked at 34565f3):**
  - godot/render/camera_rig.gd:9 (r 170).
  - godot/render/look.gd:19 (KEY_ENERGY 2.0) and :52 (glow_hdr_threshold 0.8).
  - tools/blender/a4/bakemat4.py:22 (the Glasswright finish is baked near-mirror: met .55, rgh .10). Cap it in the Godot material; do not rebake.
  - Evidence: docs/shots/audit_2026_11/ships_04_battle_camera_1to1_crops.jpg, map_01 and map_16.

- **Notes for the build:**
  - Scope limit, my call as scoper: look data and the light rig only. No light map rebakes for the 36 old AI hulls (R158: stop polishing them). Window and trim light sizes for a 70 pixel ship go into the ship recipe (P3-14 carries that line).
  - State the brightness band before changing anything, then measure before and after.

- **What Ryan will see:** At the default zoom he can tell every ship and faction apart without reading the tags. Dark ships have an edge. The Glasswright ships stop glowing white.

- **Size:** 1 to 2 thread runs, 1 to 2 GPU capture windows, 1 outside check on issue 256, 1 to 2 owner rounds (it is a looks call).

- **Waits on:** P3-02 (the fleet sheet), a GPU window, a free thread slot.

- **Risk if done badly:** A global light change shifts every accepted look at once (effects, shields, the UI panels over the scene). Raising glow to brighten dark hulls brings the burn-out back.

### 14. P3-14: Hard point contract, and the audit items the ship recipe must keep for every ship

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE WITH A CHANGE. Round 7 has pushed the stage 7 export with hard points and its check (steps 3 and 4 on opus/issue-209-r7, PC run started Nov 10 04:48 UTC). This job starts after PR 341 merges and builds only what is still missing.**

Seat: Opus worker thread (label opus), then the outside check on issue 256. Labels: opus. Covers: pass1 F6 (the contract), pass2 P13 (second camera), pass2 P3 (far side and underside stills, licences), pass2 P4 (light sizes for new ships).

```
Owner: opus (a Claude worker thread started by the Board)
Brief: below; contrib/claude_fable/reviews/audit_pass1_code_health_2026_11.md finding 6 and contrib/claude_fable/reviews/audit_pass2_graphics_effects_2026_11.md findings 3, 4 and 13 with their Board verdicts; contrib/muse/reviews/audit_pass1_holes_2026_11.md (F6, P3, P13); contrib/muse/reviews/opus_check_336.md; FINDINGS R151, R155, R156, R157, R158, R160 point (f); the Board's comments of Nov 10 on issue 209 and on PR 341; tools/blender/a4/K1_DECISIONS.md
Deliver to: docs/ship_pipeline/HARDPOINTS.md (new: the contract), docs/ship_pipeline/RECIPE.md and tools/recipe/ (once PR 341 has put them on main), tools/blender/kits/shared/ (the export of points only)
Branch: opus/issue-<number>
Effort: one worker thread (cloud; a PC run only to re-export the one recipe ship)
Done when: (1) the contract names every point type the game needs and its axes: weapon points per slot, engine exits, bays and launch points, breach anchors, the core, and new types for braking puff origins and boarding origins; it says what the effects do when shots outnumber points (cycle through the points, then a surface ray; never a box point), what a missing required point does (the export fails; the game logs and skips the effect), the smallest required set per ship class, and names the shield surface file if P3-22 needs one; (2) recipe stage 7 fails the export when a required point is missing and writes the point counts into the ship's manifest entry, proved on the round 7 ship; (3) the recipe keeps, as standing stages for every ship: the outline score per third (front, middle, back), the inner edge check, the blink sheet, and the outline score from a second camera, the battle camera (r 170); paint is judged on far side and underside stills as well as the concept side; every downloaded texture has its licence line recorded per texture as used; window and trim lights are sized to read on a 70 pixel ship; for each item the report says whether round 7 already delivered it, with the file, and builds only what is missing
```

- **Start from (re-checked at 34565f3):**
  - tools/blender/a4/K1_DECISIONS.md:102 to :106 (the point names: hp_w<slot>_<kind>_<arc>_<n>, hp_eng, hp_bay, hp_breach; no launch, braking or boarding type).
  - godot/assets/ships/manifest.json (hard point counts per ship, for example gun 4, engine 2, breach 10, core 1; counts, not names. The node names were checked only in a PC file that is not in git).
  - godot/fx/fx_hull.gd:460 (the only reader in godot/: hp_eng*).
  - PR 341 (round 7, a draft at the pin: steps 3 to 5 open; stage 7, the export with hard points, not yet written). tools/recipe/ and docs/ship_pipeline/RECIPE.md are not on main at 34565f3. I read the pull request text and comments, not its diff.

- **Notes for the build:**
  - The contract document can be written now, beside round 7. The recipe edits wait for PR 341 to merge.
  - Ask the Board before adding a point type the K1 decisions do not have.

- **What Ryan will see:** Nothing on screen yet. Later: guns fire from the gun barrels of every new ship, and the next ship's front is checked against the concept before he sees it.

- **Size:** 1 thread run, 1 outside check on issue 256, 1 Board review round, 0 owner rounds.

- **Waits on:** Issue 209 round 7 (PR 341) merged, for everything but the contract document.

- **Risk if done badly:** A contract that covers guns only reopens detached effects ship by ship (wing launches, braking puffs, boarding). A gate that keeps one number lets the next wrong bow through.

### 15. P3-15: Nemesis readers ask the campaign, so a stale cached commander cannot reach a screen

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN. Checked: story.gd lines 141, 261, 295 and battle.gd line 4149 read the cached field.**

Seat: DeepSeek workhorse (label opus). Labels: opus. Covers: pass1 F12 (the small job), M1 (F12 counts).

```
Owner: opus (released to the DeepSeek workhorse)
Brief: below; contrib/claude_fable/reviews/audit_pass1_code_health_2026_11.md finding 12 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (F12: the smallest change is at the alias, not at 200 sites); FINDINGS R130, R134, R155, R160 point (a); contrib/muse/reviews/ (the outside check of PR 248: keep RUN.nem as a maintained alias)
Deliver to: godot/story/story.gd, godot/scenes/battle/battle.gd (the block at line 4149 only), godot/campaign/campaign.gd (only to add one small read-only function, if needed), godot/campaign/test/ (one check), contrib/opus/tools/ (one report-only count)
Branch: work/issue-<number>-deepseek
Effort: DeepSeek workhorse, cap 60 minutes
Done when: the four direct readers of the cached field (godot/story/story.gd lines 141, 261 and 295; godot/scenes/battle/battle.gd line 4149) get the current Nemesis from the campaign layer through a read-only function with no side effect; a check built from the real functions proves it: start a run, advance into sector 2 through the campaign's own functions, then ask the story layer for the Nemesis before anything else calls nemActive: it must be the sector 2 commander; the check FAILS on main first, or the report says plainly that the stale read could not be reproduced and the reader change is kept anyway; the RUN["nem"] alias stays; a report-only row prints the count of direct save reads outside godot/campaign/ so the UI rollout can watch it fall; rules parity, campaign parity and the Nemesis scenarios are green; no rule changes; the JS twin is untouched
```

- **Start from (re-checked at 34565f3):**
  - godot/campaign/campaign.gd:1945 to :1954 (nemActive: refreshes RUN["nem"] at :1953, and creates a Nemesis for the slot at :1952 if there is none) and :1905 (the registry changes and the cache is set to null).
  - The four readers: godot/story/story.gd:141, :261, :295 and godot/scenes/battle/battle.gd:4149. The other "nem" reads I found go through a context the caller builds (story/arc.gd, tokens.gd, battle_voice.gd) or the battle state.
  - Counts, re-measured at 34565f3 with the pattern RUN, run.get(, run[, Bs.get(, Bs[ outside test folders: story 54, scenes 32, ui 71, main 13, render 9, world 1, about 180 in all. The audit's own pattern gave 66, 44 and 86. So "about 200 sites" holds as a size, and the two counts differ by pattern.
  - campaign_run.js:296 (the JS twin of nemActive; do not touch).

- **Notes for the build:**
  - Prefer a pure read function. Calling nemActive from a reader has a side effect and could change a seeded run.
  - Do not start the 200-site move. Only the four readers.

- **What Ryan will see:** Nothing new when it works: the Nemesis named on the story and battle screens is always the one he is really fighting.

- **Size:** 1 workhorse run (issue 246, the same size, took 20 minutes), 1 Board review round.

- **Waits on:** Nothing. Do not run beside P3-10 (both touch battle.gd).

- **Risk if done badly:** A reader that calls a function with a side effect can change a seeded run and break campaign parity.

### Jobs 16 to 28

### 16. P3-16: Explosion pictures, step 2: rebake every explosion by the picked route

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN.**

Seat: Opus worker thread with PC work through the queue (label opus), then the outside check on issue 256. Labels: opus, blocked. Covers: pass2 P1 (step 2: the build), pass2 P8 (look numbers in data, no shader text patch).

```
Owner: opus (a Claude worker thread started by the Board; PC work through the queue while Codex is parked)
Brief: below; contrib/claude_fable/reviews/audit_pass2_graphics_effects_2026_11.md findings 1 and 8 with their Board verdicts; contrib/muse/reviews/audit_pass1_holes_2026_11.md (P1, P8); the P3-04 sheet and Ryan's pick; FINDINGS R88, R116, R118, R146, R157, R158, R160
Deliver to: tools/blender/vfx/ (final bake scripts and .bat files), godot/fx/atlases/ (pictures and manifests), godot/fx/fx_death.gd, godot/fx/fx_weapons.gd, godot/fx/fx_shaders.gd, godot/fx/fx.gd (warm-up entries), one data file for the look numbers under godot/fx/, godot/fx/API.md, docs/shots/look_bench/explosions/
Branch: opus/issue-<number>
Effort: worker thread runs with GPU bake windows; Ryan review rounds on the bench sheet
Done when: every explosion picture the game plays (weapon impact, muzzle gas, death vent, death flash per class) is rebaked by the picked route; the gas fills about four fifths of each cell and the crop at godot/fx/fx_death.gd lines 171 to 173 is gone; three or more seeds per kind, picked at random per hit; a heat channel colours the core; a source shape per event (forward jet for muzzles, flat splash for hull hits, ring for torpedoes, long tear for deaths); the weapon gas shader is no longer made by patching the death shader's text while the game runs (godot/fx/fx_weapons.gd line 382); the look numbers live in one data file; fire stays inside R88 and R158 at the amount Ryan picked; bench before and after at cameras 170, 60 and 26: no square blocks at 26, no pale ball at any camera; the death puff offset of P3-05 is redone for the new pictures; gate cost before and after (R116); the flash safety test, the stray puff check and the late-shader count pass; every picture's bake script and manifest are in the repo; Ryan approves on the bench sheet
```

- **Start from (re-checked at 34565f3):**
  - tools/blender/vfx/bake_death.py and bake_weapons.py (64 cells, noise off, smoke only; lines as in P3-04).
  - godot/fx/fx_death.gd:171 to :173 (the crop) and :179 (the vent offset).
  - godot/fx/fx_weapons.gd:382 (code.replace on the death shader's text) and :495 (the run 4 comment: sizes cut to a third to hide the pale ball). Run 5 and 6 comments sit elsewhere in the file.
  - godot/fx/fx.gd:888 (warmup; new materials must be added, R118).

- **Notes for the build:**
  - One event kind at a time, each with its bench strip, so a bad bake is caught early.
  - Undo the "shrink to hide it" numbers only together with the new pictures, and show each on the bench.

- **What Ryan will see:** Explosions with a white-hot heart that flashes and snuffs out, that hold their detail at the closest zoom, and no two hits that look the same.

- **Size:** 2 to 3 thread runs with 2 or more GPU bake windows, 1 outside check on issue 256, 2 to 3 owner rounds. History: gun smoke (issue 281) took 7 runs for one effect with no bench; the bench and the pick should cut that. What drives it: bake time per effect and review rounds.

- **Waits on:** P3-04 and Ryan's pick on its sheet; P3-02; GPU windows.

- **Risk if done badly:** Rolling fire that breaks R88. Atlas memory, or a missed warm-up entry, brings first-use hitches back (R118). New pictures under old offsets float off the hull.

### 17. P3-17: Big hits and ship deaths restaged in three beats, built to the staging table

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN.**

Seat: Opus worker thread with PC work through the queue (label opus), then the outside check on issue 256. Labels: opus, blocked. Covers: pass2 P2 (the build).

```
Owner: opus (a Claude worker thread started by the Board; PC work through the queue while Codex is parked)
Brief: below; contrib/claude_fable/reviews/audit_pass2_graphics_effects_2026_11.md finding 2 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (P2); the staging table from P3-03; FINDINGS R88, R116, R157, R158, R160 point (c); retired issue 233 (the death variants)
Deliver to: godot/fx/fx_weapons.gd, godot/fx/fx_death.gd, godot/fx/fx_ship.gd, godot/fx/fx_hull.gd (the wound glow), godot/fx/API.md, docs/shots/look_bench/big_hits/
Branch: opus/issue-<number>
Effort: worker thread runs with GPU capture windows; Ryan review rounds on the bench sheet
Done when: each event in the staging table is built to its size in pixels at camera 170 and its time in seconds, measured from the bench strips and listed beside the target; the ladder las, macro, lance, torpedo, ship death is clearly bigger at each step at camera 170; a torpedo hit lights the hulls near it and leaves a glowing wound that cools; a death gets a chain of smaller blasts along the break line before the hull parts, venting gas and a longer break-up (R88); the reduce-flashing option swaps the white flash for a slower glow without shrinking the event; the camera is never taken for a capital death; the three capital death variants from retired issue 233 (frozen as shipped, unfrozen, authored drift) are shown once on one sheet if Ryan wants that pick; gate cost before and after (R116); the flash safety test passes; Ryan approves on the bench sheet
```

- **Start from (re-checked at 34565f3):**
  - godot/fx/fx_weapons.gd:1055 (torpedo flash 0.32 s) and :1059 (torpedo gas 0.42 s).
  - godot/fx/API.md:116 (the capital death sequence as written; the outside check notes it already describes a longer chain that does not read on screen).
  - Evidence: docs/shots/audit_2026_11/ fx_01, fx_08, fx_18, fx_19, fx_20.

- **Notes for the build:**
  - Build to the table. Where a target cannot be met, say so with the measured number; do not quietly shrink it.
  - Check a 20 ship battle on the bench: big hits must not hide the fight.

- **What Ryan will see:** A torpedo strike that is the biggest thing on screen for a moment and leaves a glowing wound. A ship death that reads as an event from the default camera.

- **Size:** 2 to 3 thread runs, GPU capture windows, 1 outside check on issue 256, 2 owner rounds.

- **Waits on:** P3-16 (the new pictures) and P3-03 (the table).

- **Risk if done badly:** The shrink ratchet in reverse: everything huge, and a 20 ship battle becomes unreadable. Flash safety.

### 18. P3-18: One kit of trails, beams and flares: no bare hairlines, plain cones, bars or tubes

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN. The Board accepts moving it ahead of the shield jobs.**

Seat: Opus worker thread with PC work through the queue (label opus), then the outside check on issue 256. Labels: opus, blocked. Covers: pass2 P5, pass2 P7.

```
Owner: opus (a Claude worker thread started by the Board; PC work through the queue while Codex is parked)
Brief: below; contrib/claude_fable/reviews/audit_pass2_graphics_effects_2026_11.md findings 5 and 7 with their Board verdicts; contrib/muse/reviews/audit_pass1_holes_2026_11.md (P5, P7); FINDINGS R116, R153, R157
Deliver to: godot/fx/fx_shaders.gd, godot/fx/fx_weapons.gd, godot/fx/fx.gd, godot/fx/textures/ (authored textures, each with the file or script that made it), godot/fx/API.md, docs/shots/look_bench/kit/
Branch: opus/issue-<number>
Effort: worker thread runs with GPU capture windows; Ryan review rounds on the bench sheet
Done when: no bare hairline in any bench still; sparks have a bright head and a short tapered tail capped in screen pixels (the cap is stated); the gauss wake is a brief shimmer plus a thick tracer for two frames, not one line the length of the shot; shield shards are small lit flakes; beams have a hot core, a soft sheath, a flare at the muzzle and a glow where they land; shells have a small bright head, a short trail and a real muzzle flash; about eight looks rebuilt, each on the bench at cameras 170, 60 and 26; one shape language per faction in a table, picked by Ryan on the sheet; textures are made with free tools and the source file or script is in the repo; a licence line is recorded for any downloaded sprite, per pack, as used; gate cost before and after (R116); Ryan approves
```

- **Start from (re-checked at 34565f3):**
  - godot/fx/fx_weapons.gd:216 (the shell is one streak call), :352 (the gauss wake: one line the full length of the shot), :530 (a line per spark).
  - godot/fx/fx_shaders.gd:291 (every sprite kind is a disc), :433 (line length grows with speed and ship size), :457 (lines held at about 2 pixels wide at any distance).
  - Evidence: docs/shots/audit_2026_11/ fx_02, fx_03, fx_04, fx_06, fx_10 to fx_13 and sh_06. Which call draws which line was not traced by the auditor; trace it before replacing.

- **Notes for the build:**
  - Trace each hairline in the evidence to its call first, and list them.
  - One look at a time on the bench. PR 327 changed eight looks through one shared helper with no captures; do not repeat that.

- **What Ryan will see:** No hairlines anywhere. Sparks that look like hot metal thrown off. Weapons he can tell apart by shape, with a visible muzzle, flight and landing.

- **Size:** 2 thread runs, GPU capture windows, 1 outside check on issue 256, 2 owner rounds. What drives it: about eight looks, each at three cameras.

- **Waits on:** P3-16 (the muzzle flash comes from the new pictures) and P3-02.

- **Risk if done badly:** Eight looks changed at once with side effects nobody captured.

### 19. P3-19: Nebula and ion storm hexes with depth: measure two routes against the gate, pick, build (replaces issue 139)

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN.**

Seat: Opus worker thread with PC work through the queue (label opus), then the outside check on issue 256. Labels: opus, blocked. Covers: pass2 P10.

```
Owner: opus (a Claude worker thread started by the Board; PC work through the queue while Codex is parked)
Brief: below; contrib/claude_fable/reviews/audit_pass2_graphics_effects_2026_11.md finding 10 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (P10: measure the gate first; price denser billboards beside the fog); FINDINGS R82, R88, R90, R116, R157, R160 point (d); contrib/muse/research/vfx_leap_2026_11/synthesis.md section 4 (build steps N1 to N5); issue 139 (the earlier brief this replaces)
Deliver to: godot/world/world_living.gd, godot/render/camera_rig.gd (near plane per zoom band), godot/render/backdrop.gd, a baked 3D noise texture with its bake script, the quality tiers in godot/scenes/battle/battle.gd, docs/shots/look_bench/nebula/
Branch: opus/issue-<number>
Effort: worker thread runs with two GPU windows; one stop for Ryan in the middle
Done when: step 1, then stop for Ryan's pick: the gate scene on a multi-patch nebula map and on a storm map with (A) fog volume patches at the max tier and (B) hex-sized, denser billboards from the existing 3D noise field; for each the frame median at 1080p and the GPU ms at 4K against 12.5 ms (R116); one bench sheet at cameras 170, 60 and 26 with today beside them. Step 2: the picked route built: clouds one to two hexes tall with a soft edge past the hex, so ships sit inside; storm lightning as light inside the gas; lower tiers fall back to cards; ships inside gas stay crisp at 4K; faction tint capped per R82; cost reported; Ryan approves
```

- **Start from (re-checked at 34565f3):**
  - godot/world/world_living.gd:4 (nebula: billboards that sample one 3D noise field) and :8 (ion storm: the same gas with veins).
  - Issue 139's body (froxel preparation first with no visual change; split colour ramp; a thinned billboard edge layer).
  - Issue 230 has a draft pull request (PR 286, the nebula motion spec) open since Nov 8. Rule on it first: merge it or shut it.
  - Evidence: docs/shots/audit_2026_11/ map_05, map_06, map_07.

- **Notes for the build:**
  - Step 1 is a measurement and one sheet. Do not polish either route before the pick.
  - Issue 100 (terrain fx 2) stays blocked behind this job and is re-scoped when it lands.

- **What Ryan will see:** Ships sliding into glowing gas that has depth, and storms that flash from inside.

- **Size:** 2 to 3 thread runs, 2 GPU windows, 1 outside check on issue 256, 2 owner rounds (the pick, then the approval).

- **Waits on:** P3-02, a GPU window, a ruling on PR 286, a free thread slot.

- **Risk if done badly:** Full-screen fog breaks the 12.5 ms gate on a multi-patch map at 4K. Fog hides the ships.

### 20. P3-20: Board planet and rocks from real data (replaces issue 140)

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN. Waits on Ryan's answer to question 5.**

Seat: Opus worker thread with PC work through the queue (label opus), then the outside check on issue 256. Labels: opus, blocked. Covers: pass2 P11.

```
Owner: opus (a Claude worker thread started by the Board; PC work through the queue while Codex is parked)
Brief: below; contrib/claude_fable/reviews/audit_pass2_graphics_effects_2026_11.md finding 11 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (P11: check each source's terms at download time); FINDINGS R88, R90, R116, R157; issue 140 (the earlier brief this replaces)
Deliver to: godot/world/world_planet.gd, godot/world/world_bake.gd, godot/world/world_rocks.gd, godot/world/rocks/, tools/pc/jobs/ (download and remix jobs, each a .bat), a licence file listing every source file with its credit line and the date it was read, docs/shots/look_bench/planets/
Branch: opus/issue-<number>
Effort: worker thread runs with GPU and download windows; Ryan approves the first planet before the rest
Done when: the board planet is built from two public domain sources mixed, warped and recoloured so it is not a plain copy: an 8K set (colour, relief, roughness), an air glow shell and a moving cloud layer with shadows; each source's credit line is read on the source page at download time and recorded per file; eight to twelve scanned rocks with detail levels, tinted per biome, with the rock generator kept for dust-size pieces; one planet type at a time, a rocky or terran one first; bench before and after at cameras 170 and 26, plus the planet shot; cold bake time and gate cost at 4K reported (R116); gas and ice giants unchanged; Ryan approves the first planet before the others are made
```

- **Start from (re-checked at 34565f3):**
  - godot/world/world_planet.gd:5 (each surface is baked once on the GPU into two pictures) and godot/world/world_rocks.gd:2 (the rock library made by world/tools/rockgen.py).
  - The planet shot tool used by the audit: battle.tscn with --map planet --seed 5 --planet-shot.
  - tools/pc/jobs/tex_download.bat (the repo already downloads from ambientCG).
  - Issue 140 specifies a different route (procedural geology inside the GPU bake). The Board verdict on finding 11 takes the real-data route. Build one, not both; the owner question in the pass 3 file asks Ryan to confirm.
  - Evidence: docs/shots/audit_2026_11/ map_08, map_11.

- **Notes for the build:**
  - Licences first: no file enters the repo without its line. Most NASA and USGS material is public domain, but some hosted sets carry other terms, and remixing does not change a licence.
  - Watch GPU memory with 20 ships on a 16 GB card.

- **What Ryan will see:** A planet with real terrain when he zooms to it, and asteroid fields with sharp, varied rock.

- **Size:** 2 to 3 thread runs, GPU and download windows, 1 outside check on issue 256, 2 owner rounds.

- **Waits on:** P3-02, a GPU window, Ryan's word on the route, a free thread slot.

- **Risk if done badly:** A licence mistake ships someone else's data. An 8K set that does not fit beside 20 ships.

### 21. P3-21: Attach point service: effects start on the ship, never on a guessed box point

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN.**

Seat: Opus worker thread with PC work through the queue (label opus), then the outside check on issue 256. Labels: opus, blocked. Covers: pass1 F6 (the build).

```
Owner: opus (a Claude worker thread started by the Board; PC work through the queue while Codex is parked)
Brief: below; contrib/claude_fable/reviews/audit_pass1_code_health_2026_11.md finding 6 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (F6); docs/ship_pipeline/HARDPOINTS.md (from P3-14); FINDINGS R153, R155, R160 point (f)
Deliver to: godot/fx/fx_hull.gd, godot/fx/fx_weapons.gd, godot/fx/fx_ship.gd, godot/fx/test/ (an attach check), docs/shots/look_bench/attach/
Branch: opus/issue-<number>
Effort: worker thread runs with GPU capture windows
Done when: one attach point service in fx_hull with this order of trust: an authored hard point for that weapon slot, bay or core; else a surface ray hit; else nothing, and then the effect is skipped and one line is logged and counted; no fallback returns a box point; when shots outnumber points the contract's rule applies; wing launches, braking puffs and boarding origins read the service; a check walks every hull that is present and fails if any attach point lies further than a stated small distance from the hull's triangles (on the PC for all 36; headless wherever hulls are present); bench close strips on a slab hull, a ring hull and a tower hull show no muzzle flash, launch or puff starting in empty space; the count of skipped effects per battle is reported and is 0 on a recipe ship
```

- **Start from (re-checked at 34565f3):**
  - godot/fx/fx_weapons.gd:136 (every shot comes from A.hull.mounts_for; this was line 134 at the audit pin) and :1096 (wing launch from hull.c plus H * 0.3; was :973).
  - godot/fx/fx_hull.gd:460 (reads hp_eng* only) and :496 (the box point fallback).
  - godot/fx/fx_ship.gd:680 (braking puff corners; since PR 327 lines 691 to 700 cast a ray and skip on a miss, so this one case is already repaired on main).
  - No reader for hp_w, hp_bay, hp_breach or hp_core anywhere under godot/ at the pin.
  - The audit counted 25 lines in fx_ship.gd that place something at a fraction of the hull box. I did not re-count that.

- **Notes for the build:**
  - Build to the contract. Do not fit old hulls one by one: they are being replaced.
  - List every call site moved (about 30) and bench each on the three hull shapes.

- **What Ryan will see:** On thin, ring and tower ships, no shot, launch or puff starts in empty space.

- **Size:** 2 thread runs (about 30 call sites), GPU capture windows, 1 outside check on issue 256, 1 to 2 owner looks.

- **Waits on:** P3-14 (the contract), P3-02 (the bench) and at least one recipe ship in the game with real points (issue 209 round 7).

- **Risk if done badly:** Quietly skipped effects make weapons invisible on the old hulls. Thirty moved call sites change looks nobody recaptures.

### 22. P3-22: Shield model: a skin that hugs the hull, shows its four sides and has a resting state

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN. One recipe ship first; the old hulls keep the fallback.**

Seat: Opus worker thread with PC work through the queue (label opus), then the outside check on issue 256. Labels: opus, blocked. Covers: pass2 P6.

```
Owner: opus (a Claude worker thread started by the Board; PC work through the queue while Codex is parked)
Brief: below; contrib/claude_fable/reviews/audit_pass2_graphics_effects_2026_11.md finding 6 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (P6: a cost report; one surface with facing data is allowed); FINDINGS R3 (shields keep faction colours), R116, R118, R157, R160 point (d)
Deliver to: godot/fx/fx_ship.gd, godot/fx/fx_hull.gd, godot/fx/fx_shaders.gd, the recipe's shield surface output (as the contract in P3-14 names it), godot/fx/API.md, docs/shots/look_bench/shields/
Branch: opus/issue-<number>
Effort: worker thread runs with GPU capture windows; Ryan review rounds on the bench sheet
Done when: the shield is a surface built from the ship's own shape, pushed out a little, carrying the four facings the rules already use as data (one surface with facing data is allowed; four meshes are not required); each facing is drawn by its own strength: steady when full, flickering when low, dark when down; a break opens only that facing and it stays open; a hit ripples near the impact, not over the whole surface; the resting state is the one Ryan picked; shields keep faction colours; Eclipse ships have none; the facing values come from a real battle state reached by play, never a typed one; a gate scene cost report at rest and with 20 ships hit at once (R116: 12.5 ms; the scene sat at 6.0 ms frame median at 1080p and 5.45 ms GPU at 4K in R118); bench strips at cameras 170, 60 and 26 for two factions; Ryan can say which side of a ship is open from the camera 170 strip
```

- **Start from (re-checked at 34565f3):**
  - godot/fx/fx_ship.gd:315 (the shield is visible only for a moment after a hit), :388 (one SphereMesh), :464 to :466 (a break shows the whole bubble for 1.45 s; a direction is passed to the shader), :752 (the four facings are summed; that line sits in regen detection).
  - godot/fx/fx_hull.gd:569 (the bubble is the ship's box made 10 to 35 percent larger).
  - Evidence: docs/shots/audit_2026_11/ sh_01, sh_02, sh_05.

- **Notes for the build:**
  - Build it first on the one recipe ship in the game. For the 36 old hulls say plainly which fallback is used (a surface made at load from the hull mesh, or today's bubble with facing data).
  - Measure the hit state cost before polishing the look.

- **What Ryan will see:** At a glance, which side of a ship is open. Hits that splash on a skin close to the hull instead of a balloon.

- **Size:** 2 to 3 thread runs, GPU capture windows, 1 outside check on issue 256, 2 owner rounds.

- **Waits on:** P3-14 (the shield surface in the contract), issue 209 round 7 (a recipe ship in the game), P3-02, and Ryan's pick of the resting state.

- **Risk if done badly:** Draw calls multiply with 20 ships. The shield hides the ship. The drawn facings disagree with the rules' facings.

### 23. P3-23: Shield surface look: energy with depth instead of flat line art

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN.**

Seat: Opus worker thread with PC work through the queue (label opus), then the outside check on issue 256. Labels: opus, blocked. Covers: pass2 P15.

```
Owner: opus (a Claude worker thread started by the Board; PC work through the queue while Codex is parked)
Brief: below; contrib/claude_fable/reviews/audit_pass2_graphics_effects_2026_11.md finding 15 with its Board verdict; FINDINGS R3, R116, R157; the shield model from P3-22
Deliver to: godot/fx/fx_shaders.gd, godot/fx/fx_ship.gd, godot/fx/atlases/ or godot/fx/textures/ (the shield splash picture with its bake script or source file), tools/blender/vfx/ if it is baked, docs/shots/look_bench/shields/
Branch: opus/issue-<number>
Effort: one or two worker thread runs with GPU capture windows
Done when: the pattern shows only near a hit and fades with distance; the background bends at the ripple; a glow shows where the shield meets a hull or a rock; brightness is capped so the ship stays visible through a lit shield (the cap is stated and measured on the bench); a shield hit has its own splash picture, an energy crackle, not the smoke puff a hull hit uses; the four faction patterns stay, as masks; gate cost before and after (R116); bench strips at cameras 170, 60 and 26; Ryan approves
```

- **Start from (re-checked at 34565f3):**
  - godot/fx/fx_shaders.gd:859 (render_mode unshaded, blend_add: it does not bend what is behind it).
  - godot/fx/API.md:320 ("A hit lights the whole bubble faintly in its faction colour and pattern").
  - Evidence: docs/shots/audit_2026_11/ sh_06, sh_07, fx_12, sh_01.

- **Notes for the build:**
  - Build on the P3-22 surface. Do not add detail to the old bubble patterns.

- **What Ryan will see:** A shield that looks like energy with depth, and a ship he can still see through it.

- **Size:** 1 to 2 thread runs, GPU capture windows, 1 outside check on issue 256, 1 to 2 owner rounds.

- **Waits on:** P3-22.

- **Risk if done badly:** A screen-bending pass costs on every shield hit in a 20 ship volley.

### 24. P3-24: The station as one built set piece through the ship recipe (replaces issue 199)

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN.**

Seat: Opus worker thread with PC work through the queue (label opus), then the outside check on issue 256. Labels: opus, blocked. Covers: pass2 P12.

```
Owner: opus (a Claude worker thread started by the Board; PC work through the queue while Codex is parked)
Brief: below; contrib/claude_fable/reviews/audit_pass2_graphics_effects_2026_11.md finding 12 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (P12: not ahead of the recipe maturing); FINDINGS R98, R109, R113, R116, R151, R157; contrib/muse/reviews/opus_check_336.md; issue 199 (the earlier brief this replaces)
Deliver to: a station parts kit under tools/blender/kits/, a station entry for the recipe, godot/world/blocker_visuals.gd, docs/shots/look_bench/station/
Branch: opus/issue-<number>
Effort: worker thread runs with GPU bake windows; Ryan review rounds on sheets, battle camera first
Done when: one station built through the ship recipe with its own parts kit: at least three hexes wide and taller than any ship; a core, a ring or docking arms, towers; lights and one slow moving part; break lines and insides (R98); sized from the hexes it blocks, so the orange outlines are not needed to explain it; no triangle cap, cost reported (R113); the gate scene run on a station map before the swap ships (R116); bench sheets at camera 170 and at a low camera beside a cruiser; the report says which station kind comes first (fleet or refinery); Ryan's look before the swap
```

- **Start from (re-checked at 34565f3):**
  - godot/world/blocker_visuals.gd:32 (A4P.station(14.0): each blocked station cell gets a piece 14 units across).
  - godot/render/hull_table.gd:26 (SHIP_K 1.6) and the Cruiser entry 14.5 on the next line: 23.2 units.
  - The recipe's own outside check (PR 342) returned five conditions; stage 5 was still tied to one ship. Do not start before they are met and merged.
  - The Board did not open the three station images (map_03, map_04, map_15); the cause is the auditor's inference.

- **Notes for the build:**
  - Open the three station captures first and confirm the read at the battle camera.

- **What Ryan will see:** A station that looms over the fleets and is worth fighting round.

- **Size:** 2 to 4 thread runs with GPU bakes, 1 outside check on issue 256, 2 to 3 owner rounds. History: the ship route needed seven rounds to reach round 7; the station starts with the recipe already built.

- **Waits on:** Issue 209 merged with the recipe's five conditions met, and P3-14.

- **Risk if done badly:** The recipe is not ready for something that is not a ship. A model that disagrees with the hexes it blocks misleads the player.

### 25. P3-25: Save hand-offs: a real save and load in the tree hand-off check, and one cross-twin load check

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN. Small; "cannot by design, recorded" is an allowed outcome for the cross-twin half (R33).**

Seat: DeepSeek workhorse (label opus). Labels: opus. Covers: M3, pass1 F1 (the outside check addition: a real save).

```
Owner: opus (released to the DeepSeek workhorse)
Brief: below; contrib/muse/reviews/audit_pass1_holes_2026_11.md (F1 and miss M3); FINDINGS R155, R160 point (g); contrib/opus/tools/tree_handoff_test.js and godot/campaign/test/tree_handoff_test.gd (PR 346)
Deliver to: contrib/opus/tools/tree_handoff_test.js, godot/campaign/test/tree_handoff_test.gd, godot/campaign/test/node/ and godot/campaign/test/ (the cross-twin check), contrib/opus/tools/run_all_checks.js or the parity scripts (to register it)
Branch: work/issue-<number>-deepseek
Effort: DeepSeek workhorse, cap 60 minutes
Done when: (1) in each twin the hand-off check saves with the game's real save function and loads through the real load path before the battle starts, instead of a JSON copy of the run, and still gets four skills; (2) one cross-twin check: a run and profile made by the JS twin's own functions after a fixed number of seeded steps is loaded by the Godot twin, and the next steps match the JS twin record by record; (3) if the twins cannot read each other's saves by design, the check says so in one line, tests the hand-off the parity harness really uses, and the report asks the Board to record that ruling; green on GitHub
```

- **Start from (re-checked at 34565f3):**
  - contrib/opus/tools/tree_handoff_test.js:31 (RUN = JSON.parse(JSON.stringify(RUN)) stands in for a save and load).
  - godot/campaign/campaign.gd:375 ("The Godot save (a fresh format; browser saves are not carried over, R33)"), :419 (load_save_text), :1152 (saveRun).
  - godot/campaign/test/node/golden_campaign.js:74 (the page reload step of campaign parity: save to JSON, load it back).

- **Notes for the build:**
  - Do part (1) first. Part (2) may end as the one-line finding in (3): that is an acceptable result.

- **What Ryan will see:** Nothing on screen.

- **Size:** 1 workhorse run, 1 Board review round.

- **Waits on:** Nothing. It does not edit the tree tables, so it can run beside a tree job.

- **Risk if done badly:** Low. The danger is a check that looks like a save test and still copies the run in memory.

### 26. P3-26: Entry documents: one source per fact, and a doc check in the standing checks

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN.**

Seat: DeepSeek workhorse (label opus). Labels: opus. Covers: pass1 F13.

```
Owner: opus (released to the DeepSeek workhorse)
Brief: below; contrib/claude_fable/reviews/audit_pass1_code_health_2026_11.md finding 13 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (F13); FINDINGS R102, R155; issue 216 (ask 1, the consolidation pass)
Deliver to: contrib/opus/tools/doc_check_tests.js (new; the runner picks up files that end in _tests.js), AGENTS.md (the auditing pointer at line 8 only), contrib/README.md, godot/rules/test/README.md. HANDOFF.md and LOOP.md are the Board's own files (R102) and are out of scope here
Branch: work/issue-<number>-deepseek
Effort: DeepSeek workhorse, cap 60 minutes
Done when: a doc check row in the standing checks: every repo path named in AGENTS.md, CLAUDE.md, HANDOFF.md section 0 and the three skills under .claude/skills/ exists; a README may not state a scenario or battle count that differs from godot/rules/test/scenarios.json; the check FAILS on main first (paste the output), then passes; AGENTS.md no longer calls docs/ship_pipeline/TEXTURE_PASS.md current; contrib/README.md no longer says nothing in contrib/ is run by the gate; counts and "latest record" lines in READMEs are generated or deleted; Refs #216
```

- **Start from (re-checked at 34565f3):**
  - AGENTS.md:8 (sends auditors to docs/ship_pipeline/TEXTURE_PASS.md and calls it current; that file is an Oct 22 brief about the browser game's tools).
  - godot/rules/test/README.md:66 ("48 of 48 golden battles"); godot/rules/test/scenarios.json holds 229 scenarios at 34565f3 (193 at the audit pin).
  - contrib/README.md:3 ("Nothing in contrib/ is built into the game or run by the"); the pull request gate is contrib/opus/tools/run_all_checks.js.
  - For the Board, not this job: HANDOFF.md section 0 (old "no PRs yet" lines, two "Waiting on Ryan" blocks) and contrib/opus/LOOP.md line 15 ("Seats right now (Nov 7)" over later content) and its lock wording.

- **Notes for the build:**
  - Scope the path check to the four entry files and the skills. History files name many paths that are gone on purpose.

- **What Ryan will see:** Nothing on screen. New agent threads stop starting from stale facts.

- **Size:** 1 workhorse run, 1 Board review round, plus the Board's own trim of HANDOFF.md section 0 when the audit closes.

- **Waits on:** Nothing.

- **Risk if done badly:** A doc check that fails on every old path blocks all pull requests.

### 27. P3-27: Late shader log: name any shader that is first built in the middle of a battle

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN.**

Seat: DeepSeek workhorse (label opus). Labels: opus, blocked. Covers: pass1 F11 (the flag and log only).

```
Owner: opus (released to the DeepSeek workhorse)
Brief: below; contrib/claude_fable/reviews/audit_pass1_code_health_2026_11.md finding 11 with its Board verdict (CANNOT TELL without a PC trace; keep the small flag-and-log part only); contrib/muse/reviews/audit_pass1_holes_2026_11.md (F11); FINDINGS R118
Deliver to: godot/fx/fx.gd, the hull and death helpers that create materials (godot/fx/fx_hull.gd, godot/fx/fx_death.gd), godot/fx/test/ (one check), godot/bench/ (print the count), docs/shots/issue-<number>-deepseek/ (the trace result)
Branch: work/issue-<number>-deepseek
Effort: DeepSeek workhorse, cap 60 minutes, plus one short PC trace
Done when: after warm-up ends a flag is set; any shader or material created later through _mat or the hull and death helpers logs one line with its name and the frame time, and a counter can be read by tests; the look bench and the scene gate print the count; one PC run of the gate scene with --trace on current main reports the list; if the list is not empty, the named entries are added to the warm-up in this job and the trace is rerun; no frame over 16.7 ms at the first use of each weapon in that trace; nothing else changes on screen
```

- **Start from (re-checked at 34565f3):**
  - godot/fx/fx.gd:888 (func warmup; this was line 849 at the audit pin), :927 (the note on a past miss: "their first launch or hit compiled them mid-fight"; was :888), :210 to :213 (_mat creates and caches a shader on first use with no signal; was :202).
  - Re-counted at 34565f3: 63 ShaderMaterial.new() or Shader.new() sites in godot/world, godot/render and godot/scenes/battle (same as the audit).
  - godot/bench/scene_gate.gd:35 (--trace, from issue 220).

- **Notes for the build:**
  - Log and count only. Do not move or rewrite the warm-up list unless the trace names a miss.

- **What Ryan will see:** Nothing, unless the trace finds a miss: then one first-shot hitch goes away.

- **Size:** 1 workhorse run plus one PC trace of a few minutes on the GPU, 1 Board review round.

- **Waits on:** P3-02 (so the bench prints the count) and a short GPU slot. Low priority.

- **Risk if done badly:** Low. A log line inside a hot path could itself cost frame time: log once per name.

### 28. P3-28: Runner 2: a failed run opens no pull request, unwanted files are refused, pushes do not erase earlier runs

**Board verdict (Fable 5.2 Board, Nov 10 2026): FILE AS WRITTEN.**

Seat: Opus worker thread (label opus), then the outside check on issue 256. Labels: opus, blocked. Covers: pass1 F8 (partial runs, refuse list, safe push).

```
Owner: opus (a Claude worker thread started by the Board)
Brief: below; contrib/claude_fable/reviews/audit_pass1_code_health_2026_11.md finding 8 with its Board verdict; contrib/muse/reviews/audit_pass1_holes_2026_11.md (F8: pushing without force breaks reruns; use force-with-lease or run-numbered commits); FINDINGS R144, R155
Deliver to: tools/pc/work_issue.bat, tools/pc/work_issue.ps1, tools/pc/codex_issue.bat, a patch file for .github/workflows/auto_pr.yml if partial branches need it
Branch: opus/issue-<number>
Effort: one worker thread, plus three free dry runs on the PC
Done when: (a) a run whose agent exit code is not 0 pushes to work/issue-N-arm-partial, which opens no pull request; (b) the runner refuses to commit a file over a stated size, a file under godot/gen or godot/assets/ships/<hull>/, a new .uid or a re-saved .import, and writes the refused list to result.txt; a changed file outside the issue's Deliver to folders is listed as a warning; refused files are kept in the run's out folder, never deleted; (c) pushes use force-with-lease or run-numbered commits, so a second run on the same job cannot erase the first without trace and reruns on the same branch still work; each proved by a dry run: a run stopped at the time cap opens no pull request; a run that copies ship files in is refused with the file list; after a rerun the first run's commit can still be reached
```

- **Start from (re-checked at 34565f3):**
  - tools/pc/work_issue.bat:83 (exit code written, not used), :93 (git add -A), :99 (git push -q -f).
  - tools/pc/codex_issue.bat:38 and :69 (git add -A).
  - .github/workflows/auto_pr.yml:29 to :32 (how a branch name becomes a pull request).
  - godot/.gitignore (PR 310 already keeps gen/, assets/ships/*/ and .uid files out; the refuse list is the second line of defence).

- **Notes for the build:**
  - One change, one dry run. The Board swaps the PC copy only when no run is active.
  - Never throw refused work away: a paid run's output stays on disk.

- **What Ryan will see:** Nothing on screen. Half-finished runs stop arriving as finished pull requests.

- **Size:** 1 thread run, 3 free dry runs on the PC, 1 outside check on issue 256, 1 Board review round.

- **Waits on:** P3-07 and P3-08 merged (same files). A free thread slot.

- **Risk if done badly:** A refuse rule that is too strict throws away a paid run's work. A push rule that is too strict blocks the reruns the board relies on.

## 7. Questions for Ryan (picks, looks and money are his; these are not jobs)

1. **Where should the built ship files live?** (pass 1 F5, part c)
   - A. Stay on your PC only. Every capture job copies and checks them with one step (P3-01). **My pick, for now:** the 36 old hulls are being replaced, so paying to store them is money spent on files with a short life.
   - B. GitHub release files with a double-click fetch .bat. No cost that I know of (not checked), but roughly 10 to 30 MB per ship and an upload step per ship.
   - C. Large-file storage in the repo. Simplest for agents, may cost money each month.
   - Ask again when the first recipe ships are in the game.
2. **Which explosion route, and how much fire?** (pass 2 P1) You pick on the P3-04 sheet, not now. **My pick going in:** the hybrid (a medium simulation plus hand-made hot cores and sparks), unless the full 256 bake turns out quick; and "flash plus a short hot core that snuffs out", which is inside your R88 ruling.
3. **What should a shield look like when nothing is hitting it?** (pass 2 P6)
   - A. Invisible at rest; a faint edge glow when you zoom in, hover the ship, or it was just hit. A side that is down shows as a dark gap whenever the shield is visible. **My pick:** it keeps a 20 ship battle clean.
   - B. Always faintly visible on every ship.
   - C. Nothing on the ship at rest; the open side is shown on the interface only.
4. **Nebula and storm route.** (pass 2 P10) You pick on the P3-19 sheet. **My pick going in:** real fog at the top quality setting if it fits the 12.5 ms gate at 4K; if not, the denser cards.
5. **Planet route.** (pass 2 P11) The audit and the Board take real NASA and USGS planet data, remixed. The older job (issue 140) planned computed geology. **My pick: real data**, one planet first for your look. Say so and issue 140 is retired.
6. **Which games' hits, shields and beams do you like?** Name three to five. Muse links them per effect in P3-03 so workers build to a target you chose. No copied frames go into the repo.

Also waiting on you, not picks: GPU windows (the bench first), a DeepSeek top-up when the balance drops under 2 USD, and your read of the staging table when Muse lands it.

## 8. Old issues: fold, keep or retire

| Issue | What | Call | Reason |
|---|---|---|---|
| 233 | Destruction and reaction capture round | RETIRE | The captures fold into P3-02 (deaths at the shipped numbers, one ship per weight class). The three capital death variants fold into P3-17. It was blocked on the parked Codex seat. |
| 234 | Destruction probe and ram Monte Carlo | KEEP as filler | No finding touches it. Move the label from codex to opus: the ram Monte Carlo is a JS sim job for the workhorse; the physics half needs a short GPU slot. Unsure: see "could not decide". |
| 235 | Camera calibration harness and UI calibration captures | RETIRE | The UI captures are overtaken by the rebuilt battle screen (PR 314) and the rollout's own screenshots (issue 344). The bench uses the three real cameras. The camera logger for a play session becomes one line on the next playtest build checklist. |
| 236 | Environment sheets | RETIRE | Planet and region contact sheets become the before sheets of P3-20; nebula sheets those of P3-19. The loom turntable and the density sweep are dropped: pass 2 found the rock count fine and the surfaces weak. The sky bake comparison is not covered by any job here (see "could not decide"). |
| 237 | Campaign map capture round and colour-vision pass | RETIRE | Issue 344 makes real screenshots of every campaign page. Add the colour-vision simulation as one done-when line on the last UI rollout job so it is not lost. |
| 238 | Reporting scripts | KEEP as filler | R132 already names it a Flash job. Move the label from codex to opus and unblock it. No finding touches it. |
| 333 | Weapon gas follow-up (the eight unseen looks) | RETIRE | Replaced by P3-02 (R157). The eight looks are named in its done test. |
| 139 | Nebulas and ion storms as real volumes | RETIRE | Replaced by P3-19, which keeps its build steps and adds the measure-first step and the priced fallback (R160). |
| 140 | Planets with real geology | RETIRE if Ryan confirms question 5 | Replaced by P3-20 (real data instead of computed geology). |
| 199 | Station surface detail pass | RETIRE | Replaced by P3-24, one built set piece (Board verdict on P12). |
| 100 | Terrain fx 2 | KEEP, blocked | Now behind P3-19 instead of issue 139. Re-scope it when P3-19 lands. Its second block (issue 60 debris) is unchanged. |
| 92 | Debrief screen | KEEP | It becomes UI rollout group 2 (R159). Move the label from codex to opus when that job is filed. The F12 view API rule applies to it. |
| 230 | Environment reconciliation and nebula motion spec | KEEP | Its draft pull request 286 has been open since Nov 8. The Board should merge it or shut it before P3-19 starts. |
| 221 | Scene gate binder (per-ship CPU trim) | KEEP | Not urgent. It is the room P3-19 and P3-22 will spend. The P3-27 trace can share its PC run. |
| 209 | Ship build route (round 7 in flight) | KEEP | Round 7 carries pass 2 findings 3 and 13 and the hard point export. P3-14 follows it. |
| 276 | Ship design and concept redo | KEEP, blocked | Add two lines: the three faction materials (pass 2 P14) and a paint recipe per faction (P3) are designed here, once. |
| 250 | Glasswright concept sheet | KEEP | Already folds into 276 (R138). No finding touches it. |
| 271 and 344 | UI redesign parent and rollout group 1 | KEEP | Running. The F12 view API rule is already in 344. Add the "Not active yet" mark (pass 1 F7) to the group 4 job when it is filed. |
| 305 and 347 | Tree skills in battle; job 7a | KEEP | Running. P3-11 and P3-12 take slots in the same lane. |
| 256 | Standing outside check | KEEP | Every Opus thread job here ends there. |
| 343 | Muse findings ledger | KEEP | Section 3 of this file gives it the status of all 28 audit findings and 5 misses. |
| 216 | Repo memory hygiene | KEEP | P3-26 does part of its ask 1 and says Refs. |

**I would retire: 233, 235, 236, 237, 333, 139, 199, and 140 once Ryan confirms question 5.** Not touched by any finding and left as they are: 41, 42, 43, 44, 193, 194, 211.

## 9. The standing rules every coding job carries

Each coding job body in the JSON file ends with these, from R155, R157 and R160:

1. Fixture state comes from the real functions, never typed by hand.
2. Name every copy the job must refresh (both oracle folders and both exported tables, until P3-11 removes the folders).
3. A behaviour check proves the effect, not a counter. Where it says "fails on main first", the failing output is pasted.
4. Battle camera first for anything visual (r 170, true pixel size).
5. The scope line lists every folder the job may touch. No ship assets, no .uid files, every baked picture keeps its bake script, workflow changes arrive as a patch.
6. Refs, never a closing word, in front of an issue number. Plain ASCII. No hours.
7. For capture jobs: copy the PC-built hulls first, stop on placeholder blocks, wait for the go file, one GPU job at a time, delete nothing on the PC.
8. For Opus-built work: the outside check on issue 256 before the merge.

The Muse job carries Muse's own standing rule, the blind Rey leg and the chair's citation check instead.

## 10. Tripped over while scoping (not new findings; each blocks or shapes a job)

- **VERIFIED: ADM-2 went from pass to fail between the audit pin and mine, with no signal.** At da01a7a the audit lists ADM-2 as passing though still on the known list. At 34565f3 it fails ("one 'hunt' Command id, two effects": Vorn no longer promises the torpedo reload) and the row still prints PASS, because the id is on the list. It may be the intended result of the R145 pick (Vorn's Command became Interdiction strike) or a text miss. I did not decide which. It goes to P3-06.
- **VERIFIED: the tree_handoff_test row shows a data line as its detail** ("deathless nekhet: ..."), because the runner prints the last output line. Folded into P3-09.
- **VERIFIED: the Godot save is a fresh format by ruling** (godot/campaign/campaign.gd:375 cites R33: browser saves are not carried over). That limits what miss M3 can mean. Shaped P3-25.
- **UNVERIFIED: whether round 7 already built the gate items and the hard point export.** Pull request 341 was a draft with steps 3 to 5 open when I read its text. P3-14 is written to build only what is missing.
- **UNVERIFIED: the two capture defects from pass 2 finding 8** (the reel error at world_bake.gd:24, the loading-screen still at campaign_scene.gd:114). The lines are there; I did not run either tool. Folded into P3-02.

## 11. What I could not decide

1. **Is the cross-twin half of P3-25 worth a run?** R160 says file miss M3. R33 says the twins do not share saves. I filed it small, with an allowed outcome of "cannot by design, recorded".
2. **The "Not active yet" mark on the tree screen: now, or with the tree screen restyle?** I put it with the restyle (UI rollout group 4), because no playtest build goes out before the new UI and it would collide with issue 344's files. If a build goes out sooner, pull it forward as a small workhorse job.
3. **Seat for P3-10.** I gave it to an Opus cloud thread because sorting 60 test scripts is judgment. Part (a) alone, the load-everything step, would fit the workhorse.
4. **Seat for P3-05, P3-27 and P3-01.** I gave them to the workhorse with a hull copy step. The workhorse's record on GPU jobs is one clean run (issue 232) and one seven-run job (issue 281). If the first of these needs a second run for captures, move the rest to a PC thread.
5. **Issue 234: keep or retire.** It is reporting only and no finding touches it. I kept it as filler. LOOP.md says pass 3 folds or retires the Nov 6 capture jobs; the Board may prefer to retire it.
6. **The sky.** Pass 2 mentions sharper skies as "also worth doing, smaller", outside its 15 findings, and issue 236's sky bake comparison is retired here. No job covers the sky. I did not add one because it is not a numbered finding.
7. **Should the readability pass (P3-13) rebake light maps for the old hulls?** The audit says that is the larger part. I scoped it out under R158 (stop polishing the old hulls). If the old hulls will stay on screen for many weeks, the Board may want it back.
8. **Shields on the 36 old hulls.** P3-22 builds on the one recipe ship first and leaves the fallback for old hulls to the thread. That choice changes its size a lot.
9. **A third explosion route.** The outside check also names painted or computed flipbooks with no simulation at all. P3-04 prices two routes, as R160 says. A third would add a bake window.
10. **Whether the workflow file patches (P3-08, P3-28) should be one Board sitting instead.** The PC token cannot push workflow files, so both arrive as patches the Board applies.

## 12. Not checked

- **Godot was not run.** No parity, no headless scene, no capture. Every statement about Godot behaviour comes from reading the code at the pin and from the two audits.
- **Nothing on the PC was looked at.** Not the queue, the runner copy, the run folders, the ship files or the auditor's probe.
- **The 43 audit captures were counted, not opened.** Every "what Ryan will see" line rests on the auditor's and the Board's viewing.
- **Pull request diffs were not read**: 341 (round 7), 336, 286, and the other open drafts. Only 341's text and comments.
- **Issue bodies not read**: 41 to 44, 193, and the rest of 194, 209 and 216 past their first screen. Issue comments were read only on 209, 256 and 341.
- **Whether each of the 47 failing findings tests is a real bug.** That is P3-06.
- **Bake times, fog cost, shield cost, texture licences and DeepSeek prices today.** Each job that depends on one measures it. I had no reason to look anything up online and did not.
- **The audit's count of 25 box-fraction lines in fx_ship.gd** (pass 1 F6) and which call draws which hairline (pass 2 P5) were not re-traced.
- **The Muse findings ledger (issue 343)** had not landed at my pin. It may name lost items this file does not cover.
- **Labels on the live board** beyond what the issue list returned on Nov 10.

## Self-check

- Plain ASCII, no em dashes: checked by script on both files.
- No closing word in front of an issue number in either file: checked by script.
- The JSON file parses and holds 28 objects with the keys key, title, labels, body, waits_on, covers: checked with node.
- Every finding of pass 1 (13), pass 2 (15) and every miss (5) has one row in section 3.
