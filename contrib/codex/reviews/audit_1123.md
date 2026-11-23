# Codex (audit): Nov 23 UTC merges

Main reviewed: `cbb6165a12540fdd6e7e9ca544d5f087e95e5fcc`. Each PR was read as the diff from its merge or squash commit's first parent. Findings use lines on main.

| # | Finding | Evidence | File:line | Exact quote | Why it matters | Fix | Confidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | **BLOCKING · #1804.** A clean rerun can leave its new main merge local and exit 7. | OBSERVED | `tools/pc/codex_issue.bat:186` | `findstr /c:"Resumed by merging" /c:"Base already merged" "%O%\resume.txt" >nul` | The runner commits the main merge and writes a `Continued from the earlier tip` note. With an empty index, a Windows probe of the batch branch returned 7 for that note and reached the checks for the older Base note. A rerun with no explicit Base or unmerged partial therefore leaves the PR on its old tip, and its successor cannot get a verified handoff. Workhorse has the same filter at `tools/pc/work_issue.bat:412`. | Compare HEAD with the recorded delivery tip in both batch entry points and the shared commit step. Test a no-edit rerun after main advances. | High |
| 2 | **BLOCKING · #1807.** The saved-results checker rejects completed battles when the Windows worker cannot read its certificate store. | OBSERVED | `godot/rules/test/saved/records.js:65` | `!/SCRIPT ERROR\|Parse Error\|NOT PORTED:\|^ERROR:/m.test(log);` | All four Godot workers exited 0 and logged every battle result. Their only error line was `ERROR: Failed to read the root certificate store.` The saved checker rejected all 354 results. A separate hash and record-count comparison verified all 354 fresh outputs. Full onboarding and hull repair now call this checker at `tools/test_onboarding.js:57` and `tools/blender/hull_repair/checks.py:55`. | Keep the worker exit, completion markers, byte checks and script-error gate. Allow only this exact offline Windows diagnostic and cover it with a fixture. | High |
| 3 | **SHOULD-FIX · #1812.** The dry-run total misses files shared only among folders it plans to remove. | OBSERVED | `tools/pc/runner_common.ps1:727` | `$script:wouldFreeBytes += [long]$stats.FreeBytes` | A Windows fixture with one 65,536-byte file and its two hard links in separate folders gave zero for both folders and the summed total. Measuring both folders together gave 65,536. A live pass can count the last link after the first vanishes, so the two totals can disagree with stable inputs. | Keep the per-folder sizes and aggregate link identities across approved dry-run candidates for the closing total. | High |
| 4 | **SHOULD-FIX · #1793.** The nested-TEMP workaround can stop the Windows fault matrix before its first case. | OBSERVED | `tools/pc/runner_selftest.js:97` | `const root = fs.mkdtempSync(path.join(fixtureTemp(), 'runner687 proof '));` | The audit lane's writable TEMP matches the GUID naming rule, so `fixtureTemp` returns its parent. The actual root-creation code then fails with `EPERM` because the parent is outside the lane's writable roots. The standing suite launched inside the worker cannot exercise this matrix. | Use a fixture root explicitly writable by the worker and keep the compiler TEMP short. Exercise the nested-TEMP case with the same write limits as the worker. | High |
| 5 | **SHOULD-FIX · #1808.** The current manifest still carries Wave B instructions tied to two different acceptance gates. | OBSERVED | `contrib/opus/sound/elevenlabs_pilot_v2.json:5` | `Wave B stays held until Wave A2 (10 items / 20 takes) clears ear sign-off.` | The same note later requires Ryan's Wave A3 ear check, while the plan's command section still prescribes A2. A reader can follow the older release instruction and spend credits before the current gate clears. Running the old A2 recipe from main also uses several replacement A3 prompts. | Mark A2 commands historical and point the manifest and Wave B command at the current release gate. Keep the A2 recipe tied to its original manifest revision. | High |
| 6 | **NOTE · #1804.** The sparse fixture stops before the fleet-list code that originally failed. | OBSERVED | `contrib/opus/tools/lean_checkout_1739_tests.js:45` | `both concept checks use the helper` | The fixture proves the helper can read an omitted concept from the index. Its fleet-list check only counts matching source expressions, so it can pass while `fleet_list.build()` still rejects a lean checkout. | Run the fleet-list builder on the sparse fixture with a tracked-but-omitted concept and a genuinely missing one. | High |

## PR coverage

### #1792 · `087b61018`

Read the five-row Wave A rewrite and its plan change. A2 and A3 superseded all five prompt strings on main. The five cue IDs still exist, and the current generator dry run validates the full list before applying `--only`.

Not checked: Listening to the historical Wave A takes.

### #1793 · `c9596825d`

The Windows fixture moves beside a matching lane scratch path when its TEMP has the runner's GUID name. The cases still use fake runners under their fixture root. This changes where the fixture is created and leaves its assertions in place. Finding 4 covers the worker's restricted TEMP.

Not checked: Repeating the Board's production-lane diagnostic under the original deeply nested compiler TEMP.

### #1794 · `f767f45cd`

Checked prompt, model and take changes against the A2 plan and current manifest. The A2 merge had two over-limit prompts (461 and 480 characters). #1799 brought both back under the cap and added a guard. Main uses v2 for nine shell-gun rows. The two same-prompt heavy impact rows now both resolve to v3, consistent with keeping the v3 result as the earlier comparison's winner.

Not checked: Listening to the A2 takes or scoring every Wave B prompt for sound quality.

### #1796 · `ec1cf8c73`

This changed the comment explaining the fixture placement and left `fixtureTemp` intact. The comment records the Board's PowerShell `Add-Type` failure and distinguishes compiler TEMP depth from the longest discovered file path.

Not checked: Re-running the original `CHECKS_DIAG_1739_E` diagnostic.

### #1797 · `485c4d7c5`

Checked the plan's model restriction against the effective model on every SFX row. Rail, energy, impact, death and Eclipse all resolve to v3. Shell guns retain the v2 exception and the Sunward battery keeps its v3 twin.

Not checked: Vendor retirement dates or audio differences between the models.

### #1798 · `da55a939d`

The short-lock fixture now unlocks when it sees the retry, and it still requires the retry message and actual checkout removal. The permanent-lock fixture remains. This replaces a timing race in the test without removing the retry or failure cases.

Not checked: The chmod-driven retry fixture on a non-root Unix host. The Windows standing row uses static coverage for this case.

### #1799 · `025ee1e4d`

The guard rejects SFX prompts above 450 characters before the selection filter and before key or account access. Music keeps its own path. The offline generator self-test passed. All 72 SFX rows on main fit the cap, with a maximum of 436 characters.

Not checked: Live ElevenLabs rejection or billing. The generator used its loopback server and an offline dry run.

### #1800 · `39c5b6087`

Traced PR creation, runner-body refresh and commit sanitization on main. The new rules handle short issue references, owner/repo references and full issue URLs. Existing Opus PR bodies are deliberately preserved by their refresh path. The workflow test exercises generated bodies with fake GitHub calls. The commit test executes the extracted PowerShell sanitizer, and its check that the commit path calls it is a source-text assertion.

Not checked: Creating or refreshing a live PR, or cleaning up manually authored bodies.

### #1804 · `de943c787`

Traced fetch and prune, sparse profile reuse, earlier-tip checkout, main/Base/partial merges, exit 15 and the final non-force push. A normal edited rerun starts on its earlier tip. The exit-15 ancestry check closes the former path that attached the old branch as a parent without using its tree. The checked-in runner fixtures exercise ancestry, file retention, rejected wrong-base work and a pruned delivery ref. My run timed out earlier in the fixture, during its fake GitHub setup tests. The Windows lane refresh and lean-checkout tests passed. The clean-index rerun with only the automatic main merge is finding 1, and the fleet-builder assertion is finding 6.

Not checked: Pushing a live delivery or partial branch, or moving a remote ref during a real lane run.

### #1807 · `2315e684e`

The changed tree checks inspect saved Godot records, require the scenario hash to match and keep their fire-count or behavior assertions. CI regenerates the records and checks them against the reviewed baseline. The saved baseline replaces four Eclipse records. Each scenario edit changes only its seed. Both tree checks passed, including the 222 fire-count fixtures. Quick onboarding passed on the Windows executable with an isolated TEMP profile. The strict worker-log filter in finding 2 predates this PR. The two changed wrappers now use the affected checker. Each of the four reseeded battles matched its saved record in the separate byte and input-hash comparison.

Not checked: A full Blender build, the visual onboarding path, or the 30 saved campaign runs after onboarding's rules step. Legacy browser-only tests were outside the gameplay audit.

### #1808 · `87c831a00`

The current Wave A3 command planned nine IDs, 18 takes and 800 estimated credits under the 900 cap. The lance twin keeps the same prompt and changes influence, the Directorate twin keeps the same settings and changes prompt, and the Eclipse control retains the A2 prompt. Finding 5 covers the superseded release directions still present alongside section 8.

Not checked: Listening to the takes on the installed build, live generation or Ryan's ear sign-off.

### #1812 · `2a8091b5b`

The Windows fixture exercised the native file ID and link count, including the 52-byte structure layout, all-inside links and an outside link. The separate two-folder fixture reproduced finding 3. The foreign-owner case in the Windows standing fixture substitutes owner selection. The janitor dry-run fixture checks whether the printed total is the sum of its rows. Finding 3 shows how both the rows and their sum can miss a file.

Not checked: Running the live janitor, or testing real cross-account delete permissions under the janitor's Windows account.

### #1813 · `60b246a6f`

Both lane entry points now allow 3,600 seconds for the standing Node suite. The parity cap, per-check watchdogs and requirement for both checks to succeed before marking a push verified stay in place. The cap assertions inspect batch source text. The same test exercises suite failure detail and exit propagation through a fixture.

Not checked: Two live lanes running through the 1,800-second boundary or timing out at 3,600 seconds.

## Raw file receipt

GitHub REST raw content was compared with the matching `origin/main` git blobs at the pinned SHA. The browser raw URL was unavailable. The additional `records.js` dependency was read from the pinned git blob after the REST rate limit. Binary rows were verified by blob ID. Counts and last-line prefixes below are from the raw text, with up to 40 characters per prefix.

| File | Lines | Last line prefix |
| --- | ---: | --- |
| `.github/workflows/auto_pr.yml` | 204 | `          fi` |
| `contrib/opus/plans/cohesive_audio_v2.md` | 184 | `  - Both are tried with the A3 takes bef` |
| `contrib/opus/reviews/sound_wavea3_fable_1752.md` | 243 | `7. Apply the Wave B block and the missed` |
| `contrib/opus/sound/elevenlabs_pilot_v2.json` | 839 | `}` |
| `contrib/opus/sound/README.md` | 59 | `  updates it with the first wired pick.` |
| `contrib/opus/tools/auto_pr_body_tests.js` | 205 | `console.log('PASS auto_pr_body_tests: cr` |
| `contrib/opus/tools/closing_words_tests.js` | 32 | `console.log('PASS closing_words_tests: a` |
| `contrib/opus/tools/fleet_list.js` | 195 | `module.exports = { build, render, pickLi` |
| `contrib/opus/tools/janitor_free_space_1739_tests.js` | 93 | `console.log('PASS janitor_free_space_173` |
| `contrib/opus/tools/lean_checkout_1739_tests.js` | 46 | `console.log('PASS lean_checkout_1739_tes` |
| `contrib/opus/tools/mirror_cache_1396_tests.js` | 85 | `console.log('PASS mirror_cache_1396_test` |
| `contrib/opus/tools/opus_job_head_tests.js` | 899 | `console.log('PASS ps1 fixtures: current ` |
| `contrib/opus/tools/run_all_checks_live_tests.js` | 105 | `console.log('Evidence: ' + root);` |
| `contrib/opus/tools/runner_cleanup_tests.js` | 851 | `}` |
| `contrib/opus/tools/runner_job_tests.js` | 874 | `})().catch(e => { console.error(e.stack)` |
| `contrib/opus/tools/sound/elevenlabs_gen.js` | 339 | `module.exports = { plan, args };` |
| `contrib/opus/tools/sound/elevenlabs_gen_selftest.js` | 206 | `});` |
| `contrib/opus/tools/sparse_check_inputs.js` | 34 | `};` |
| `contrib/opus/tools/tree_effects_test.js` | 318 | `console.log('PASS: ' + Object.keys(WANT)` |
| `contrib/opus/tools/tree_last_rows_test.js` | 175 | `})().catch(e => { console.log('FAIL: ' +` |
| `docs/playbooks/pc.md` | 130 | `` through `"%JW%" run`. The head and `cont `` |
| `godot/campaign/test/onboarding_test.gd` | 204 | `	quit(0 if fails == 0 else 1)` |
| `godot/rules/test/saved/changes.txt` | 22 | `FAIL: saved Godot results; 354 battles c` |
| `godot/rules/test/saved/records.js` | 144 | `module.exports = { HOME, SCENARIOS, FILE` |
| `godot/rules/test/saved/results.json` | 2526 | `}` |
| `godot/rules/test/scenarios.json` | 11317 | `}` |
| `godot/tools/ci/godot_checks.txt` | 246 | `headless\|main/test/player_path_map_ready` |
| `tools/blender/hull_repair/checks.py` | 62 | `if __name__=='__main__':main()` |
| `tools/blender/hull_repair/README.md` | 27 | `The outcome and remaining visual work be` |
| `tools/pc/codex_issue.bat` | 263 | `exit /b 9` |
| `tools/pc/codex_issue.ps1` | 162 | `} else { Write-Host 'usage: codex_issue.` |
| `tools/pc/disk_space.ps1` | 149 | `}` |
| `tools/pc/janitor.ps1` | 747 | `exit 0` |
| `tools/pc/jobs/opus_job_head.ps1` | 1549 | `}` |
| `tools/pc/lane_tools_refresh.ps1` | 437 | `}` |
| `tools/pc/lane_tools_refresh_selftest.js` | 196 | `console.log('PASS: lane tools refresh ke` |
| `tools/pc/runner_common.ps1` | 1777 | `exit 0` |
| `tools/pc/runner_selftest.js` | 1490 | `} })();` |
| `tools/pc/work/README.md` | 276 | `  variants written in, it goes out with ` |
| `tools/pc/work_issue.bat` | 508 | `exit /b %RC%` |
| `tools/pc/work_issue.ps1` | 858 | `else { Write-Host 'usage: work_issue.ps1` |
| `tools/test_onboarding.js` | 82 | `fs.writeFileSync(path.join(out, 'PASS.tx` |

Large-file ranges used for the review:

- `tools/pc/runner_common.ps1` lines 1-600, 601-1200, 1201-1777.
- `tools/pc/jobs/opus_job_head.ps1` lines 1-450, 451-900, 901-1350, 1351-1549.
- `tools/pc/runner_selftest.js` lines 1-500, 501-1000, 1001-1490.
- `contrib/opus/tools/opus_job_head_tests.js` lines 1-500, 501-899.
- `contrib/opus/tools/runner_cleanup_tests.js` lines 1-500, 501-851.
- `contrib/opus/tools/runner_job_tests.js` lines 1-500, 501-874.
- `godot/rules/test/saved/results.json` lines 1-600, 601-1200, 1201-1800, 1801-2400, 2401-2526.
- `godot/rules/test/scenarios.json` lines 1-1450, 1451-2900, 2901-4350, 4351-5800, 5801-7250, 7251-8700, 8701-10150, 10151-11317.

Verified compressed records under `godot/rules/test/saved/records/`:

| File | Git blob | Decompressed lines | Last line prefix |
| --- | --- | ---: | --- |
| `t_ecl_twicerestored.jsonl.br` | `4392dc31b1a1eba1b298986d1b2288e21dbf302b` | 110 | `{"actor":"end none","hash":"5cce0f05b6ad` |
| `t7b_ecl_formation_b.jsonl.br` | `810252c320f563adce002d1fc4f8d3a1ba75e227` | 82 | `{"actor":"end win","hash":"df8988544dc95` |
| `t7b_ecl_targetarchived.jsonl.br` | `0fc7c75630f2548dc51f890fe539c19aae82bea1` | 50 | `{"actor":"end win","hash":"14b811b976e8e` |
| `t7b_ecl_triage.jsonl.br` | `0e15307c63e34f4bdc48fb8a5e0ed2731b0d6b34` | 119 | `{"actor":"end none","hash":"1406f9ccc53c` |

## Check results

- `node contrib/opus/tools/run_all_checks.js`, Windows PowerShell 5.1 and Node 22: exit 1, with 110 PASS, 2 KNOWN and 6 FAIL. `godot_shard_tests` could not create its plan directory through Git Bash. `runner_cleanup_tests` and `runner_job_tests` timed out in PowerShell fixtures. `runner_stall_tests` got exit 1 where it expected 7. `runner_selftest` hit finding 4. `g2_export_selftest` could not hard-link the bundled Node executable inside its fixture.
- Godot rules saved-results command, Windows headless: FAIL. All four battle workers exited 0. The checker rejected 354 battle results because of the Windows certificate-store diagnostic in finding 2. A focused rerun of the four Eclipse scenarios reproduced the same rejection. The independent comparison matched all 354 fresh records to the saved record hashes, record counts and scenario hashes.
- Quick onboarding, `tree_effects_test.js`, `tree_last_rows_test.js`, the ElevenLabs offline self-test and the Wave A3 dry run passed. The NTFS cross-folder probe and the clean-index branch probe reproduced findings 3 and 1 respectively.

Recommended next step: File the two blockers for the PC runner and the saved-results checker, with the Windows probes as acceptance cases.

Not checked: Live GitHub writes, live janitor removals, GPU capture, or listening and sign-off for paid sound takes.
