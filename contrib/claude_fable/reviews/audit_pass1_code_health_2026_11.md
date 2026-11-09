# Outside audit, pass 1: code health and repeat problems (Nov 2026)

## Summary (plain words)

- The checks test hand-made test data and the rules files. They almost never test the game the way a player reaches it. That is the main reason problems come back.
- A live example at this commit: an admiral tree skill picked in a real run does not reach the battle. Only the capstone does. All 137 skill fixtures still pass, because they feed the battle a key the real game never writes (finding 1).
- A second live example: the Godot tree screen still shows the old Hullbreaker skill texts ("Ram First") while the battle runs the new boarding rules. The standing checks are all green (finding 3).
- GitHub's checks never open the battle scene, the HUD, the effects or the world. About 38,800 lines of game code are never even loaded there (finding 2).
- Several checks print PASS while they report failures or differences inside the same line (finding 4).
- Missing ship files turn into plain blocks with no error, and the real ship files live only on one PC. Capture runs can pass or push with nothing real on screen (finding 5).
- Effects find their place on a ship by guessing from the ship's bounding box. The gun and hangar points that the ship files are specified to carry are not read (finding 6).
- 13 findings follow, most important first. I changed nothing. Two findings (1 and 3) are live defects that anyone can reproduce with the commands given.

## Pinned commit

- Audited commit: `da01a7a1ca8c1936d297375dfb9398a7497ec4d5` (short `da01a7a`), "Tree skills in battle, job 5: the Ashfall Hullbreakers full tree (PR 331)".
- All files were read from the local checkout at that commit, not from GitHub pages. No newer commit was fetched.
- Read first, in order: CLAUDE.md (12 lines, all), AGENTS.md (121, all), HANDOFF.md (31, all), contrib/opus/FINDINGS.md (326 lines, all, in ranges 1 to 110, 111 to 160, 161 to 200, 201 to 260, 261 to 326), contrib/opus/LOOP.md (189, all), docs/REVIEW_PROTOCOL.md (35, all).
- Evidence I produced myself at this commit:
  - `node contrib/opus/tools/run_all_checks.js` (Node 22.23.4): 35 rows, 35 PASS, exit 0. Nothing was left in the work tree.
  - `node contrib/muse/tools/oracle_drift/oracle_drift_guard.js .`: exit 0, with the differences quoted in finding 3.
  - One probe script of my own, kept outside the repo and not committed (finding 1 says exactly what it did).
- Open pull requests 327, 325, 316, 309, 303, 301, 295, 291, 287 and 286 were not read. Work in flight under issues 305 and 209 is not reported as "unfinished" anywhere below.
- "OBSERVED" means I saw it in the code or in a run. "INFERRED" means my reasoning, with the reason given.

## Findings (ranked by how many repeat problems the change would stop)

### 1. Tree skills picked in a real run never reach the battle; the fixtures use a key the game never writes

- Explains symptoms: 1, 2.
- Status: OBSERVED (the JS side by running it; the Godot side by reading the matching lines).
- Where and what:
  - `core.js:391` stores a pick without the admiral's name: `else build.picks.push(key.slice(id.length+1));`. A stored pick looks like `A:0:0`. `core.js:369` rejects any stored pick that does not have exactly three parts.
  - `core.js:436` copies those short picks into the run: `RUN.lineage={id:admiralId,picks:b.picks.slice(),capstone:b.capstone};`
  - `battle.js:1267` looks the pick up as it is: `const fx=TREE_FX[key]; if(fx) out.push(Object.assign({key},fx));`
  - `data.js:2772` shows the table is keyed with the admiral's name: `"aelith:A:0:1":{k:"castTwice",n:.5},`
  - So `TREE_FX["A:0:0"]` finds nothing, and `if(fx)` skips it without a word. Only the capstone is built with the name in front (`battle.js:1268`), so only the capstone works.
  - The fixtures hide this. `godot/rules/test/scenarios.json:1881` feeds the long key straight in: `"aelith:A:0:1"`. `godot/rules/test/node/golden.js:153` copies it into the run unchanged.
  - Godot has the same two lines: `godot/campaign/campaign.gd:1031` `else: build["picks"].append(str(key).substr(id.length() + 1))` and `godot/rules/rules.gd:3570` `if TREE_FX.has(key):`. `godot/main/campaign_host.gd:132` hands the run to the rules as it is.
- How I checked: I loaded the root data.js, core.js, battle.js and campaign files with the repo's own loader (`godot/campaign/test/node/env.js`, `VS_ORACLE` set to the repo root, the same way `contrib/opus/tools/lineage_tests.js` does). I called `lineagePick` for `vaelen:A:0:0`, `vaelen:A:1:1`, `vaelen:A:2:0` and `vaelen:cap:1` (all returned true), then `newRun('vaelen','ithar')`, then `treeBuild()`. Result: `RUN.lineage` was `{"id":"vaelen","picks":["A:0:0","A:1:1","A:2:0"],"capstone":1}` and `treeBuild()` returned one skill only, `vaelen:cap:1`. With the same picks rewritten as long keys it returned all four.
- How sure: high for the browser rules (reproduced). High for Godot by reading; not run, because this sandbox has no Godot.
- Why it keeps happening: every tree check starts from a hand-written run snapshot. No check makes a pick through the campaign and then starts a battle. The hand-off between the two halves is the one place nobody tests.
- Fix approach: pick one key shape and use it on both sides of the hand-off, in both twins (either store long keys, or build the long key inside `treeBuild`). Old saves hold short keys, so the reader must accept them. Then add one end-to-end check per twin: pick through `lineagePick`, start a run, start a battle, and require the skill in `B.tree`. As a rule for later jobs: a fixture's starting state should be produced by the real functions, not typed by hand.
- Size: small for the key change (two lines per twin plus the oracle re-copy and parity). Medium for the end-to-end check, driven by needing it in JS and in Godot.
- How to know it worked: the probe above returns four skills. In the game, a run with a tier 1 pick shows its "Lineage:" callout and log line in the first battle where it applies.

### 2. GitHub's checks never open the game the player sees

- Explains symptoms: 1, 2, 3, 4, 6.
- Status: OBSERVED.
- Where and what:
  - `.github/workflows/checks.yml:31`, `:51`, `:54` and `:57` are the only test steps: `run: node contrib/opus/tools/run_all_checks.js`, `run: sh godot/rules/test/run_parity.sh`, the campaign parity script and the Nemesis scenario script.
  - Those three Godot scripts load only the rules and campaign layers: `godot/rules/test/parity_main.gd:10` `const RulesScript = preload("res://rules/rules.gd")` and `godot/campaign/test/parity_campaign.gd:8` `const CampaignScript = preload("res://campaign/campaign.gd")`.
  - Counted at this commit: 56,242 lines of GDScript in `godot/`, 49,151 outside test folders. CI loads `jsm.gd`, `rules.gd`, `battle_api.gd` and `campaign.gd`, 10,395 lines. The other 38,756 lines (battle scene, HUD, effects, world, render, story, main) are never parsed or run by CI. A typing mistake in `godot/scenes/battle/battle.gd` would pass every check.
  - 58 test, check, probe and shot scripts sit under `godot/**/test/`. CI runs 4 of them. The rest run only when a person or agent starts a one-off .bat on the PC.
  - The one UI check in CI reads source text, not the screen: `contrib/opus/tools/ui_spec_tests.js:4` `These are code-structure checks, not numeric gates`. Example at line 50: it passes if hud.gd contains the text `_button("Continue", "continue", null, true, true)` (written there as a regular expression).
  - The rules send the screen its instructions as events, and no parity record contains them: `godot/rules/rules.gd:38` `Emitted where the JS game calls its presentation hooks; never read by the rules.` The battle scene's event switch (`godot/scenes/battle/battle.gd:1220`, `match e["t"]:`) has no default branch, so an event kind it does not know is dropped silently.
- How sure: high. The workflow file and the preload lines are short and complete.
- Fix approach: add one CI job that (a) imports the Godot project headless and loads every .gd file, failing on any script error, (b) runs the Godot checks that need no GPU through one list file (the campaign `*_test.gd` set, `effect_caps_test.gd`, `api_smoke.gd`, the headless fx checks), and (c) starts one headless bot battle and fails on any script error in the log. For GPU-only checks, keep one named PC .bat that writes one results file, and make "results file attached" part of every visual job's done test.
- Size: medium. The parse and headless list are small; the driver is sorting 54 existing scripts into "headless, GPU, retired" and fixing the ones that have rotted.
- How to know it worked: a pull request that breaks a line in hud.gd goes red on GitHub. The checks summary lists Godot game checks by name.

### 3. Three copies of the rules files, and nothing fails when one is left behind

- Explains symptoms: 1, 2, 5, 8.
- Status: OBSERVED.
- Where and what:
  - battle.js, data.js and core.js exist at the repo root, in `godot/rules/test/oracle/` and in `godot/campaign/test/oracle/`. Each copy is refreshed by hand. No script does the copy (searched every .bat, .sh, .ps1, .py, .js and .yml for `test/oracle`).
  - At this commit the campaign copy is behind. The drift guard's own output: `root vs campaign-oracle: DIFFER (added 29, removed 120` for battle.js and `DIFFER (added 23, removed 60` for data.js.
  - The guard cannot fail: `contrib/muse/tools/oracle_drift/oracle_drift_guard.js:24` `it exits 0 on a completed run` and line 25 `even when drift is found`. It is registered as `'optional'` at `contrib/opus/tools/run_all_checks.js:29`, and the runner printed `oracle_drift_guard | PASS`.
  - The Godot campaign text comes from the stale copy: `godot/campaign/test/node/export_campaign.js:1` `writes every data table the campaign uses, from the pinned oracle files`. Result: `godot/campaign/data/campaign_tables.json` (one long line) still holds `"n":"Ram First"` and "may ram with no accuracy penalty", while `data.js:1830` says `"n": "First Over the Rail",` and the battle rules now do boarding. `godot/rules/data/tables.json` has the new name. So in Godot the tree screen and the battle callout disagree about the same skill.
  - Campaign parity cannot see this, because it compares Godot with the stale copy: `godot/campaign/test/run_parity_campaign.sh:4` `checks the campaign tables still match the pinned oracle`.
  - A check that would catch it already exists and is not part of the gate. `tools/test_onboarding.js:44` asserts that the root files equal the campaign copies, and line 46 prints `PASS: exact approved browser copy and oracle copies`. It is started only by `RUN_ONBOARDING_CHECKS.bat` (line 9), not by `run_all_checks.js` or the workflow. By reading, it would fail at this commit (battle.js differs); I did not run it because it needs Godot.
- How sure: high. Reproduce with `grep -c "Ram First" data.js godot/campaign/data/campaign_tables.json` (0 and 1).
- Fix approach: either delete the copies and point both parity harnesses at the root files (the browser game is frozen, so a "pin" protects little), or keep them and add one sync script plus a hard check: the three copies must be byte-identical and both exported table files must match a fresh export, or the pull request fails. Split the drift guard in two: copies (must fail) and hand-copied look constants (report only).
- Size: small. One script and one failing check; the driver is re-exporting the campaign tables once and re-running parity.
- How to know it worked: `grep -c "Ram First" godot/campaign/data/campaign_tables.json` prints 0, and a pull request that edits data.js without the copies goes red.

### 4. Several checks print PASS while they report failures in the same line

- Explains symptoms: 2.
- Status: OBSERVED.
- Where and what (all from my run of the standing checks at this commit):
  - `findings_tests | PASS | 1.02 | 34 passed, 46 failed`. The rule is at `contrib/opus/tools/run_all_checks.js:94`: `[0, 1].includes(run.code) && failures.length === row.failed && !row.unexpectedFailures.length`. Any failure whose id is on the list is accepted.
  - The list has 50 ids and never shrinks: `contrib/opus/tools/checks_baseline.json:2` `"recordedDate": "2026-11-01",` and line 56 `the check fails only on a new failure`. Today 46 fail. ADM-2, ADM-5, ADM-6 and EVT-3 now pass but are still on the list, so they can break again unseen.
  - The same note says the list mixes kinds: `72 assertions = 11 bugs, 9 probable, 11 ruled, 41 opinions`. The PASS line cannot tell a known bug from an opinion. Some entries read like real defects, for example `FAIL NEM-3 at most one adaptation is earned per sector` and `FAIL UI-5 cancel paths clear the sticky wing selection`.
  - `checks | PASS | 0.10 | 0 FAIL, 14 CHECK`: line 85 reads only the FAIL count; the CHECK count is printed and ignored.
  - `oracle_drift_guard | PASS | ... 12 differed`: see finding 3.
  - `'optional'` checks turn into SKIP, not FAIL, when a dependency is missing (line 96 and 97), and a SKIP does not fail the run (line 124).
- How sure: high.
- Fix approach: give the runner a fourth word. PASS means zero failures. KNOWN means only listed failures, and it is shown in its own colour with the count. Make the list shrink by itself (a listed id that passes is an error until it is removed). Tag each listed id as bug, opinion or stale and delete the opinion tests from the gate. Put a ceiling on the pack's CHECK count so it can only go down.
- Size: small for the runner; medium for triaging the 46 ids one by one (that is judgment work, not typing).
- How to know it worked: the checks table shows no PASS row with a failure count in it, and the known list is shorter each week.

### 5. A missing ship turns into a plain block with no error, and the real ship files exist on one PC only

- Explains symptoms: 2, 3, 7, 9.
- Status: OBSERVED for the code; INFERRED for the link to wasted effect rounds (the record, LOOP.md:141, says a run pushed with no real captures for this reason).
- Where and what:
  - `godot/render/ship_view.gd:117`: `no built hull (a copy of the project without gen/): a plain block`. The three load attempts above it fail quietly, and the file has no `push_error`, `push_warning` or `printerr` anywhere. `manifest()` at line 33 returns an empty table when `res://gen/manifest.json` is missing, so every ship becomes a block.
  - The files that prevent this are not in git: `godot/.gitignore:2` `gen/` and line 5 `assets/ships/*/`. `godot/assets/ships/README.md:9`: `stay **out of the repo** until Ryan decides on large-file storage`.
  - The workhorse runner clones fresh (`tools/pc/work_issue.bat:69`) and has no step that copies or builds ship files; the words `gen` and `assets` do not appear in work_issue.bat or work_issue.ps1. One older job does the copy by hand (`tools/pc/jobs/bench207_scene_gate.bat:34`, a robocopy from `build\godot\assets\ships`), and its build step needs two more PC-only folders (`--hi` and `--env` under `enginetest\assets`).
  - The record names the cost: `contrib/opus/LOOP.md:141` `capture probes draw placeholder blocks`.
- How sure: high on the mechanism.
- Fix approach: (a) make the fallback loud: when a hull is missing, print one error line and count it; every capture, probe and bench script exits non-zero if any ship on screen is a placeholder (some probes already look at `sv.a4`). (b) Give the runner one "get ship files" step used by every job: copy from the PC build folder and verify against the sha256 values already in `godot/assets/ships/manifest.json`. (c) Longer term, put the built ship files somewhere a fresh copy can fetch (release assets or large-file storage), with a double-click fetch .bat.
- Size: small for (a) and (b). Large for (c), driven by about 10 MB per ship for 36 ships plus the high-detail sets, and Ryan's storage call.
- How to know it worked: run any capture job on a fresh clone with the copy step removed; it stops with "placeholder hull" instead of producing pictures of blocks.

### 6. Effects find their place by guessing from the ship's box; the ship's own gun and hangar points are not read

- Explains symptoms: 3, 4.
- Status: OBSERVED for the code. INFERRED that this is the main cause of the detached-effect reports (the record confirms one case, R153, and the same pattern is used widely).
- Where and what:
  - Gun positions are four fixed stations found by a ray, not the modelled guns: `godot/fx/fx_hull.gd:7` `mounts: the outermost hull point on a side at four stations along the length`. `godot/fx/fx_weapons.gd:134` takes every shot from them: `for m in A.hull.mounts_for(tl, maxi(shots.size(), 1)):`
  - When the ray misses, the code falls back to a point on the box with no warning: `godot/fx/fx_hull.gd:496` `else box.end.y, c.z - dir.z * W * 0.5), "n": -dir}` (the "p" point of the fallback). On a hull that does not fill its box, that point is empty space.
  - The ship files are specified to carry real points: `tools/blender/a4/K1_DECISIONS.md:102` `hp_w<slot>_<kind>_<arc>_<n>` (weapons) and line 105 `hp_bay_<n>` (hangar mouths). The effects read only the engine ones: `godot/fx/fx_hull.gd:460` `for nd in root.find_children("hp_eng*", "Node3D", true, false):`. A search of all of `godot/` finds no reader for `hp_w`, `hp_bay`, `hp_breach` or `hp_core`.
  - Wings launch from the box centre plus a height guess: `godot/fx/fx_weapons.gd:973` `var from: Vector3 = C.to_world(C.hull.c + Vector3(0, C.hull.H * 0.3, 0))`.
  - Braking puffs sit on box corners (the known R153 case): `godot/fx/fx_ship.gd:680` `var rp: Vector3 = hull.c + Vector3(sx * L, sy * H, sz * W)`.
  - By count: fx_ship.gd has 25 lines that place something at a fraction of the hull box (pattern `hull.L * number`, `sx * L`, `box.size`) and no call to the hull's surface ray.
  - One-shot particles are fixed in the world once spawned: `godot/fx/fx_pool.gd:6` `a fixed-size ring buffer in world space for one-shot particles`. Anything long-lived that is spawned on a ship stays behind when the ship is pushed or moves.
- How sure: high that the code works this way. Medium that fixing it removes most "detached" reports, because I could not open the ship files (they are not in git) to confirm they carry the `hp_w` nodes.
- Fix approach: one "attach point" service in fx_hull. Order of trust: an authored hard point for that weapon slot, bay or core; else a surface ray hit; else nothing (skip the effect and log it). Remove every fallback that returns a box point. Move the `_rcs`, wing launch and boarding origins onto it. Add one headless-capable check: for each hull, every attach point lies within a small distance of the hull's triangles.
- Size: medium. The service is small; the driver is moving about 30 call sites and re-capturing each effect on thin, ring and tower hulls.
- How to know it worked: the attach check passes for all 36 hulls, and on the Eclipse cruiser no puff, muzzle flash or launch starts in empty space in a close capture.

### 7. The tree check proves a counter went up, not that the skill does what its text says; rows with text and no effect are allowed silently

- Explains symptoms: 1, 2.
- Status: OBSERVED. This is about the structure of the check, not about rows still in flight under issue 305.
- Where and what:
  - `data.js:2770`: `A row with no entry is inert`. A skill with a name and a description and no effect is a legal state, and the game shows it like any other skill (`godot/campaign/campaign.gd:1019` builds every node the same way; there is no "does nothing yet" mark).
  - The check asks one thing per fixture: `contrib/opus/tools/tree_effects_test.js:92` `if (!(stats[key] >= 1))`. That counter is raised by the callout helper (`battle.js:1275`, `B.treeStats[s.key]=(B.treeStats[s.key]||0)+1;`). The file says so itself at line 97: `prove the effect, not just the callout.` That stronger kind of test exists for three rows only, added after a review caught three rows that did not match their text (LOOP.md:41).
  - The lists are typed by hand. Counted at this commit: 288 rows in `LINEAGE_TREES`, 191 with a `TREE_FX` entry, 97 without. The test names 137 fixtures and 49 inert rows. 54 rows with an effect are not named by any fixture (the shared B and C rows of other admirals). Nothing walks the table and requires every row to be either tested or listed as waiting.
  - Parity does not help here: it proves Godot equals the browser rules, not that either equals the text.
- How sure: high on the facts. Medium on impact, because I did not read each of the 191 effects against its text.
- Fix approach: (a) one generated check that walks `LINEAGE_TREES` and fails unless every row has an effect or sits on a dated waiting list, and that fails any fixture-less effect row. (b) In the game, mark waiting rows on the tree screen (greyed, "not active yet") from the same list, so text can never promise what the rules do not do. (c) For new rows, the fixture asserts one number the text names (the +25%, the one turn), not the callout.
- Size: small for (a) and (b). Large for (c) across all rows; do it only for new and changed rows.
- How to know it worked: deleting one `TREE_FX` line makes the check fail by name, and the tree screen greys that skill.

### 8. The agent runner commits everything it finds, even after a timeout, and the pull request text is the agent's own word

- Explains symptoms: 1, 7, 8.
- Status: OBSERVED.
- Where and what:
  - `tools/pc/work_issue.bat:93`: `git add -A`. The only protection is the ignore file (a deny list), which is how 254 ship files were pushed once (FINDINGS R144). Nothing checks the size of the change or that changed files sit inside the job's "Deliver to" folders. `tools/pc/codex_issue.bat:38` does the same.
  - The exit code is written down and not used: line 83 `echo opencode exit %OCX% at %time% >> "%O%\result.txt"`, then the script goes straight on to add, commit and push. A run killed at the time cap still pushes its half-done tree.
  - Line 99 force-pushes: `git push -q -f origin %BR%`. A second run on the same job replaces the first run's branch.
  - The pull request text is whatever the agent said last: `tools/pc/work_issue.ps1:59` `That report becomes the pull request description, so write it for a reviewer.` The runner itself runs no check and adds no result of its own.
  - Later runs do not refresh that text: `.github/workflows/auto_pr.yml:41` `echo "PR already open for $BRANCH"`. LOOP.md:142 records the effect: a PR body `not rewritten by later runs`.
  - The task text names the wrong twins: `tools/pc/work_issue.ps1:64` `rules that exist in both the JS (core.js, campaign_meta.js) and Godot`. battle.js, data.js and the two oracle folders are not named.
- How sure: high.
- Fix approach: in the runner, after the agent stops: (a) if the exit code is not 0, push to a `-partial` branch that does not open a pull request; (b) refuse to commit when the change includes files over a size limit, files under ignored-by-policy folders, or tracked `.import` and `.uid` re-saves, and write the list to result.txt; (c) run the standing checks and parity itself and paste the real PASS and FAIL lines under the agent's report; (d) update the PR body on every push; (e) push without force and keep each run as its own commit.
- Size: medium. Driven by batch-file work on Windows and one dry run per change.
- How to know it worked: a dry run that is killed at the cap opens no pull request; a run that copies ship files in is refused with the file list; each PR body ends with check lines written by the runner.

### 9. Known traps are written into LOOP.md instead of being removed in the code

- Explains symptoms: 7, 8.
- Status: OBSERVED.
- Where and what:
  - Line endings. `contrib/opus/LOOP.md:145`: `Always clone with git -c core.autocrlf=false clone.` The repo has no `.gitattributes` file, so the rule lives in each script. Some scripts have it (`tools/pc/work_issue.bat:69`), some do not (`tools/pc/jobs/bench207_scene_gate.bat:21`, `tools/pc/jobs/ui231_shots.bat:15`), and `tools/pc/codex_issue.bat` sets it at line 22, after the clone at line 19 has already written the files.
  - Closing words. `.github/workflows/auto_pr.yml:38` adds the trap itself: `grep -q "Closes #$n" body.md || printf '\nCloses #%s\n' "$n" >> body.md`, and so does `tools/pc/work_issue.ps1:159`. The handoff then asks for a hand repair every time: `HANDOFF.md:5` `change it to Refs on #256 PRs before merging`.
  - Node version. `tools/pc/work_issue.bat:22`: `the shell's Node 24 gives a false 4,048 pow differences in the parity math sweep`. The fix is a PATH line in one runner. `package.json` has no `engines` field and the parity scripts do not check the Node version, so any other route gets the false failure again.
  - Stale labels in the automation: `.github/workflows/auto_pr.yml:37` still writes `Opus reviews and merges.` into every PR body.
- How sure: high.
- Fix approach: add `.gitattributes` with LF for .js, .gd, .json, .sh and CRLF for .bat; make auto_pr and the runner write "Refs" and let the board close issues on merge; make `run_parity.sh`, `parity.bat` and `run_all_checks.js` stop with a clear message on a Node major other than 22. Then delete the matching lines from "Known traps".
- Size: small. Three short edits; the driver is one fresh clone on the PC to confirm.
- How to know it worked: a plain `git clone` on the PC passes campaign parity, and the "Known traps" list in LOOP.md loses three entries.

### 10. Every visual job writes its own capture script; there is no standing before and after set for the Godot game

- Explains symptoms: 3, 8.
- Status: INFERRED. Reason: I can see the tools and instructions; I cannot see the seven gun smoke runs themselves (PR 327 is out of scope).
- Where and what:
  - The runner tells each agent to make its own: `tools/pc/work_issue.ps1:77` `Copy its pattern for your own shot script.`
  - The result is many one-off scripts and no fixed set: 25 `*_probe.gd` and `*_shots.gd` files under `godot/`, 48 job files under `tools/pc/jobs/`. A full effects reel exists (`godot/fx/gallery/README.md:3`, `a scripted reel that plays every effect`), but no job, check or current board note runs it as the standard comparison.
  - The project's own "how to verify visuals" skill describes the frozen browser game: `.claude/skills/screenshot-verdict/SKILL.md:14` `Build first: `python build.py test` writes `index_test.html`.` It does not mention Godot once. The ship-kit skill has the same age.
  - With no fixed set, a change to one effect is judged on new angles each round, and side effects on other effects are not captured at all (R153 notes eight looks changed by a shared helper "with no captures").
- How sure: medium.
- Fix approach: one standing capture set for Godot (the gallery reel plus about ten fixed battle moments, fixed seed, fixed clock, fixed cameras, three hull shapes: slab, ring, tower). One PC .bat makes "before" from main and "after" from the branch and writes one contact sheet plus a per-still difference number. Every effects job's done test is "the standing sheet, plus the one new still for this job". Rewrite the screenshot-verdict skill around that .bat.
- Size: medium. Driven by making the reel deterministic (wreck physics runs on real time, per R118) and by GPU time on the PC.
- How to know it worked: two runs of the .bat on the same commit give matching sheets, and a gun smoke change shows up as a difference only in the stills that contain gun smoke.

### 11. The shader warm-up is a hand-kept list, and nothing reports a shader that compiles mid-battle

- Explains symptoms: 6.
- Status: INFERRED. Reason: the list is complete as far as I could match it at this commit, so the weakness is in how it is kept, not in a missing entry I can point at.
- Where and what:
  - `godot/fx/fx.gd:849` to `:1012` is one long function that draws each effect material once, by hand, in each mesh format it will later use. Example of the style at line 858: `for k in [0, 1, 2, 3, 4, 5, 7, 8, 11, 12,` (the list runs on to 23).
  - The code records what happens when an entry is forgotten: `godot/fx/fx.gd:888` `their first launch or hit compiled them mid-fight`.
  - New shaders are created on first use with no signal: `godot/fx/fx.gd:202`, `if s == null:` then compile and cache. There is no flag for "created after warm-up finished".
  - Outside fx, 63 more `ShaderMaterial.new()` or `Shader.new()` sites exist in `godot/world/`, `godot/render/` and `godot/scenes/battle/` (grep count); they rely on the load screen drawing the real scene once.
- How sure: medium.
- Fix approach: after warm-up ends, set a flag; any shader or material created later through `_mat` (and the hull and death helpers) logs one line with its name and the frame time. Add a headless-capable check that plays the gallery reel and fails if that log is not empty. Then the warm-up list fixes itself: the log names what to add.
- Size: small for the flag and log. Medium for the check, because pipeline compiles only happen on a real GPU, so the gate half must run on the PC.
- How to know it worked: the frame trace of a first battle (the `--trace` bench from R118) shows no frame over 16.7 ms at the first use of each weapon, and the log is empty.

### 12. Screens and story code read the save data directly by name, with a hand-kept "current Nemesis" alias

- Explains symptoms: 1.
- Status: OBSERVED for the reads; INFERRED that this is why screens kept old Nemesis data (the record, R130 and R134, describes exactly this for four UI readers).
- Where and what:
  - The redesign keeps the old field alive as a cache that is only refreshed when someone calls the new function: `godot/campaign/campaign.gd:1953` `RUN["nem"] = reg[fac]`.
  - The campaign UI was moved to the function. The story layer was not: `godot/story/story.gd:141` `var nem = run.get("nem")` (also lines 261 and 295), and the battle scene at `godot/scenes/battle/battle.gd:4149`.
  - By count (pattern `C.RUN`, `run.get(`, `RUN[`, `Bs.get(`): `godot/story/` has 66 direct reads against 8 calls to campaign functions; `godot/scenes/` 44 against 36; `godot/ui/` 86 against 382.
  - Because these are dictionary reads by text key, a renamed or reshaped field gives no error anywhere. It just reads null or the old value.
- How sure: medium. The story reads are correct today as long as some other code called `nemActive()` first.
- Fix approach: give the campaign a small read-only "view" API for screens (current Nemesis, lineage, fleet, flags) and move the story and battle readers to it. Add a text check that fails on `RUN[` or `run.get(` outside `godot/campaign/`. When a data shape changes, the old field is removed in the same change (after save migration), not kept as an alias.
- Size: medium. Driven by about 200 read sites, most of them one-line swaps.
- How to know it worked: the text check passes, and deleting the `RUN["nem"]` alias breaks no screen.

### 13. Status facts are copied by hand into many documents, so the "read this first" pages disagree with the code and with each other

- Explains symptoms: 8.
- Status: OBSERVED.
- Where and what:
  - `HANDOFF.md:27`, inside section 0 ("read this first"): `and #121 Nemesis behaviour (since 14:24, branched from #120); no PRs yet.` `contrib/opus/LOOP.md:65` says `#120, #121 (PR #274) and #231 (PR #269) MERGED after Muse's outside checks`. Section 0 also has two "Waiting on Ryan" blocks (lines 23 and 29).
  - `godot/rules/test/README.md:66`, under "Latest record": `48 of 48 golden battles`. `godot/rules/test/scenarios.json` holds 193 scenarios at this commit.
  - `contrib/README.md:3`: `Nothing in `contrib/` is built into the game or run by the`. The pull request gate is `contrib/opus/tools/run_all_checks.js` (checks.yml:31).
  - `AGENTS.md:8` sends auditors to `docs/ship_pipeline/TEXTURE_PASS.md` and calls it `(current)`. That file's first line is `# Texture pass: brief for auditors and builders (Oct 22, 2026)` and it describes the browser game's tools (line 10: `light shader layer (`gfx3d.js`, HullFx)`).
  - `contrib/opus/LOOP.md:15`: `## Seats right now (Nov 7)` over Nov 9 content. Lines 9 and 10 say `Running: no` with a start time, and line 13 then reads "Running: no" as "another run is working".
  - The newest oracle note in `godot/rules/test/oracle/README.md` is for issue 319, but the files were re-copied again by the pinned commit (PR 331) with no note.
- How sure: high.
- Fix approach: one source per fact. Board state lives only in LOOP.md; HANDOFF section 0 becomes a short pointer plus rulings that do not age. Counts and "latest record" lines in READMEs are either generated by the script that produces them or deleted. Add a cheap doc check to the standing checks: every repo path named in AGENTS.md, CLAUDE.md, HANDOFF.md and the three skills must exist, and a README may not state a scenario count that differs from scenarios.json.
- Size: small. Driven by trimming, not writing.
- How to know it worked: HANDOFF section 0 fits on one screen and has no job numbers older than a day; the doc check is a row in the checks table.

## Patterns (root causes shared by several findings)

1. **Checks start from made-up state and test one layer.** Fixtures inject a run snapshot (finding 1), parity compares against a copy (3), the UI check reads source text (2), the tree check reads a counter (7). Each layer passes alone. The hand-offs between layers (campaign to battle, rules to screen, data text to rule, repo to PC files) are where the repeat problems live, and no check crosses them. One end-to-end check per hand-off would have caught findings 1, 3 and 5.
2. **When something is missing, the code carries on quietly.** No effect for a pick: skip (1, 7). No hull file: a block (5). Ray missed the hull: a box point (6). Copies differ: exit 0 (3). Test fails: on the list (4). Agent timed out: push anyway (8). Each quiet fallback was reasonable alone; together they mean a broken state looks like a working one until Ryan sees it on screen. The cheap cure is the same everywhere: fall back if you must, but say so in a line that a check counts.
3. **Facts are kept in several hand-synced places.** Three copies of the rules files (3), two shapes for one pick key (1), an alias beside the real Nemesis field (12), gun positions in the ship files and again as guesses in the effects (6), status in HANDOFF, LOOP and READMEs (13), traps in LOOP instead of in code (9). Agents that start fresh each run update the copy in front of them and not the others.

## Not checked

- **Godot was not run.** This sandbox has no Godot binary and I did not download one. Rules parity, campaign parity and the Nemesis scenarios were not executed. Finding 1's Godot half and every statement about Godot behaviour come from reading the code.
- **The real ship files** (glb and maps) are not in git, so I could not confirm that they carry `hp_w`, `hp_bay` or `hp_core` nodes (finding 6), or look at any effect on screen. No screenshots or clips were opened; pass 2 owns that.
- **Nothing on the PC** was looked at: the watcher, queue folders, the copy of the runner in `work217\tools`, run logs.
- **Big files were read in parts, the rest only searched.** Ranges actually read:
  - battle.js: 1255 to 1300, plus single lines found by search (327, 1266 to 1268, 1275).
  - core.js: 365 to 398, 430 to 438.
  - data.js: 1830 to 1831, 2760 to 2790; the tables themselves were loaded and counted by script.
  - godot/rules/rules.gd: 36 to 46, 3563 to 3576, plus search hits.
  - godot/rules/battle_api.gd: 85 to 130, 168 to 180.
  - godot/campaign/campaign.gd: 992 to 1040, 1139 to 1140, 1943 to 1956, plus search hits.
  - godot/scenes/battle/battle.gd: 798 to 808, 1216 to 1232, 1437 to 1450, 4145 to 4150, plus the list of event names 1220 to 1440.
  - godot/fx/fx.gd: 1 to 80, 199 to 236, 776 to 790, 843 to 960. fx_hull.gd: 1 to 60, 335 to 360, 440 to 576. fx_ship.gd: 661 to 689, 1222 to 1232. fx_weapons.gd: 120 to 150, 968 to 976.
  - godot/render/ship_view.gd: 30 to 44, 80 to 140.
  - godot/rules/test/scenarios.json: 1877 to 1883; keys counted by script.
  - contrib/muse/tools/oracle_drift/oracle_drift_guard.js: 1 to 120, then run.
- **Not read at all:** godot/ui (except search counts), godot/world, godot/audio, godot/music, godot/story beyond the cited lines, godot/bench, sim3d.js, campaign3d.js, campaign_meta.js, campaign_run.js (searched only), every file under tools/blender, the muse harness checks, tools/pc/codex_board.ps1 and the watchers, docs/archive, contrib/muse reviews.
- **Not verified:** whether each of the 191 tree effects matches its text; whether any of the 46 known failures is a live bug in the Godot game; whether a shader is missing from the warm-up on real hardware; the counts in finding 12 are grep counts and include some reads inside the campaign's own helper screens.
- **Symptom 6** (first-use hitches) has only an INFERRED finding (11). I found no missing warm-up entry at this commit.

### Files cited (review protocol section 1: total lines by `wc -l`, and the first 40 characters of the last line; `\t` is a tab)

| File | Lines | Last line starts |
|---|---|---|
| CLAUDE.md | 12 | `- The Board thread in the Claude Code Pr` |
| AGENTS.md | 121 | `Time estimates (Ryan, Nov 4 10:40 CST, F` |
| HANDOFF.md | 31 | `The Oct 26 to Nov 7 history (sections 0a` |
| contrib/opus/FINDINGS.md | 326 | `\| X17 \| Muse follow-up pass over unasses` |
| contrib/opus/LOOP.md | 189 | `- 2026-11-08 13:20 UTC board thread: Rya` |
| docs/REVIEW_PROTOCOL.md | 35 | `- Claude checks every claim against the ` |
| .github/workflows/checks.yml | 57 | `        run: sh godot/campaign/test/run_` |
| .github/workflows/auto_pr.yml | 43 | `          gh workflow run checks.yml -R ` |
| contrib/opus/tools/run_all_checks.js | 127 | (empty line) |
| contrib/opus/tools/checks_baseline.json | 57 | `}` |
| contrib/opus/tools/tree_effects_test.js | 163 | `console.log('PASS: ' + Object.keys(WANT)` |
| contrib/opus/tools/ui_spec_tests.js | 74 | `process.exitCode = fail ? 1 : 0;` |
| contrib/muse/tools/oracle_drift/oracle_drift_guard.js | 833 | `main();` |
| battle.js | 1912 | `}` |
| core.js | 450 | `function findNode(id){ for(const c of RU` |
| data.js | 3236 | `};` |
| godot/rules/rules.gd | 5480 | `\tB["aiActive"] = null; u["activated"] = ` |
| godot/rules/battle_api.gd | 943 | `\treturn why` |
| godot/rules/test/run_parity.sh | 18 | `if [ $F -eq 0 ]; then echo "PASS: the Go` |
| godot/rules/test/README.md | 96 | `  - `tr` is taken by `Object.tr`.` |
| godot/rules/test/scenarios.json | 6136 | `}` |
| godot/rules/test/node/golden.js | 257 | `})().catch(e => { console.error(e); proc` |
| godot/rules/test/parity_main.gd | 206 | `\treturn 0` |
| godot/campaign/test/parity_campaign.gd | 148 | `\tlines.append(JSON.stringify({"i": 4001,` |
| godot/campaign/test/node/env.js | 51 | `module.exports = { load, ORACLE, FILES }` |
| godot/rules/test/oracle/README.md | 74 | `Nov 8 2026, issue 121: re-copied data.js` |
| contrib/opus/tools/lineage_tests.js | 101 | `console.log('PASS: every faction\'s XP, ` |
| tools/test_onboarding.js | 107 | `fs.writeFileSync(path.join(out, 'PASS.tx` |
| tools/pc/jobs/ui231_shots.bat | 36 | `exit /b 0` |
| docs/ship_pipeline/TEXTURE_PASS.md | 43 | `pick. Free tools and CC0 assets only.` |
| godot/fx/gallery/README.md | 118 | `Pipeline compiles during the measured fi` |
| package.json | 5 | `}` |
| godot/campaign/campaign.gd | 3318 | `\t\t"events": tel_log.slice(max(0, tel_log` |
| godot/campaign/test/run_parity_campaign.sh | 20 | `if [ $F -eq 0 ]; then echo "PASS: the Go` |
| godot/campaign/test/node/export_campaign.js | 48 | `console.log('  code fields left out (car` |
| godot/campaign/data/campaign_tables.json | 0 (one line, no newline) | `{"sha256":"c64ebc09b10912bdde2da514e8b29` |
| godot/scenes/battle/battle.gd | 5095 | `\tget_tree().quit(code)` |
| godot/render/ship_view.gd | 1291 | `\t\tring.rotation.y = -rotation.y` |
| godot/fx/fx.gd | 1012 | `\ttmp.queue_free()` |
| godot/fx/fx_hull.gd | 576 | `\treturn Vector3(r * cos(an), r * sin(an)` |
| godot/fx/fx_ship.gd | 1306 | `\t\t_dmg_request(fx)` |
| godot/fx/fx_weapons.gd | 1176 | `\t\t\t(m as ShaderMaterial).set_shader_para` |
| godot/fx/fx_pool.gd | 255 | `\treturn [v, n, idx]` |
| godot/story/story.gd | 370 | `\treturn s` |
| godot/main/campaign_host.gd | 369 | `\trun_over.emit({"result": "win" if won e` |
| godot/assets/ships/README.md | 116 | `- Nothing here depends on the old `hulls` |
| godot/.gitignore | 9 | `*.uid` |
| tools/blender/a4/K1_DECISIONS.md | 143 | `` `godot/assets/ships/README.md`. `` |
| tools/pc/work_issue.bat | 122 | `exit /b 6` |
| tools/pc/work_issue.ps1 | 162 | `else { Write-Host 'usage: work_issue.ps1` |
| tools/pc/codex_issue.bat | 76 | `exit /b 9` |
| tools/pc/jobs/bench207_scene_gate.bat | 60 | `exit /b 0` |
| contrib/README.md | 30 | `credits the folder they came from.` |
| .claude/skills/screenshot-verdict/SKILL.md | 27 | `- Blind comparisons (engine test): keep ` |
