# Five pre-merge decisions for the Board

Codex (audit): Issue 1832, Nov 23. Send back all five heads for the items below. GitHub reported **All checks** successful on each pinned head. Main advanced from the runner's base, `0fd3b2861`, to `cdeda68fc` during the audit. I fetched the update and repeated the comparison. All five PR refs still matched the brief.

| PR | Head | Common ancestor | Later commits on main | What the Board needs before merge |
|---|---|---|---:|---|
| [1735](https://github.com/rcbailey12/voidsworn/actions/runs/45058896033/job/137323007127) | `88d266f6` | `fedabee80` | 103 | Keep the record for each paired battle. |
| [1734](https://github.com/rcbailey12/voidsworn/actions/runs/45120673018/job/137516573093) | `fd6a0f6a` | `cbb6165a1` | 23 | Run both fleet-page checks in the production workflow. |
| [1805](https://github.com/rcbailey12/voidsworn/actions/runs/45104044420/job/137463927521) | `212adbd5` | `39c5b6087` | 52 | Refuse an older publish receipt for the same hull. |
| [1806](https://github.com/rcbailey12/voidsworn/actions/runs/45105117243/job/137467163108) | `5d061445` | `39c5b6087` | 52 | Enforce the 20-second deadline through output collection. |
| [1814](https://github.com/rcbailey12/voidsworn/actions/runs/45114112415/job/137496286887) | `b32d3eaf` | `98ad5e892` | 46 | Record the asset the renderer actually loaded. |

I compared each diff from its common ancestor and applied a read-only three-way text comparison to overlapping files against current main and the other PRs. All 22 distinct changed paths combined cleanly against both main revisions. Both Godot checks survive in `godot_checks.txt`, both PC playbook edits survive, and main's runner edits leave the new preflight block intact. One dependency matters across PRs: the manifest row emitted by 1805 is an input to both the fleet page in 1734 and the layout label in 1814.

## PR 1735 at `88d266f6` | Balance simulation

The fixed-seed Godot test passed on Windows. Eclipse fired phase five times in an ordinary battle and six times against a boss. Chorus fired frenzy twice in the rewards battle. In a separate sector 1 battle for each faction, all four player ships matched the selected faction in all six cases. The simulator reads the player's rules usage after the fight and counts replacement wings at launch. Meridian's row recorded one launch. This satisfies issue 1705's narrower Run 1 firing check. Issue 1832 also asks whether the output supports Artoo's paired measurements.

| # | Finding | Evidence | File:line | Exact quote | Why it matters | Proposed fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | BLOCKING for paired balance evidence: individual battle rows are lost | OBSERVED | `godot/rules/sim/balance_sim.gd:192` | `_print_campaign(player_faction, cell, count, totals, carried if carry_rewards else {})` | The report keeps faction and cell but pools wins, timeouts and ability counts. It omits difficulty, seed, arm and each trial's terminal reason. A positive total cannot identify which seed fired the treatment. | Emit one keyed record per trial before aggregation. Compare the key sets before reporting paired deltas. | High |

Not checked: full campaign progression or the effect size of a future ability change. Issue 1705 assigns full runs to a later job.

## PR 1734 at `fd6a0f6a` | Generated fleet page

The committed page passed `--check-page` with 36 slots and 27 new-format builds. Main had changed none of its generator inputs since the common ancestor. All 11 fleet checks passed, including two different faction edits and the case where independently correct pages combine into a stale page. In that fixture, comparing regenerated output to the committed tree catches the drift. Checking just the rewritten copy passes. The production fleet test currently compares the combined page without rewriting it.

| # | Finding | Evidence | File:line | Exact quote | Why it matters | Proposed fix | Confidence |
|---|---|---|---|---|---|---|---|
| 2 | BLOCKING: production CI skips the branch-only check | OBSERVED | `.github/workflows/checks.yml:95` | `- uses: ./.github/actions/merge-main` | Standing checks first combine the branch with main. The later fleet test checks the combined page. An incorrect committed branch page that main happens to correct escapes that first gate. The fixture tests both states, but its commands run in a scratch repo. | Check the untouched branch with `--check-page` before merge-main. Check the combined committed page again before any scratch rewrite. A stale combined page needs a regenerated page committed on the branch. | High |

The other GH-06 changes are already present: read-only permissions and both branch exclusions in `checks.yml` (27, 31, 40), timeout, standing issue 906 and REST calls in `auto_pr.yml` (39, 48, 156), a sparse checkout in `main_commit_lint.yml` (22) with the compare API in `main_commit_lint.js` (48), and the four requested file extensions in `check_em_dashes.js` (9).

Not checked: two live successive Board merges. The CI workflow is reviewed here, with any edit left to the Board.

## PR 1805 at `212adbd5` | Ship manifest receipt

The publish checks passed on Windows (10 Node checks, including 34 Python cases). The batch job emits the receipt after the second seal, stops on failure, then takes the pictures. The new step introduces no delete. The existing successful-publish cleanup still delegates checkout removal to `droprepo` at `tools/pc/jobs/publish_ship.bat:233`.

| # | Finding | Evidence | File:line | Exact quote | Why it matters | Proposed fix | Confidence |
|---|---|---|---|---|---|---|---|
| 3 | BLOCKING: a late receipt restores a stale hull row | OBSERVED | `tools/recipe/publish_ship.py:116` | `whole.setdefault('ships', {})[code] = data` | I generated two valid receipts for one hull. Applying B then A succeeded twice. The installed file kept B's hash prefix `df7e70e50215` while the target manifest ended at A's `559aead08264`. | Bind application to the intended publish or verify the live seal under the install lock. Reject A and preserve B in the target. | High |
| 4 | SHOULD-FIX: the replacement test starts with the desired row | OBSERVED | `tools/recipe/test/publish_ship_selftest.py:358` | `keep = {k: rows[k] for k in ('A1_11', 'B2_22')}` | The target already contains the same A1_11 row as the patch. A command that reports success while leaving that row alone satisfies the equality assertions. | Start the target with an older A1_11 hash, verify it changes on the first apply, then check the second apply and the other ship byte for byte. | High |

Not checked: publishing to Ryan's shared install, undoing a real publish, or sourcing the playtest manifest from its build pin. All receipt tests used temporary game folders.

## PR 1806 at `5d061445` | Windows tool discovery

All 15 PC test groups passed under Windows PowerShell 5.1. With both overrides unset, the normal PC preflight found the bundled ffmpeg and system Python with Pillow. With a scratch user profile hiding the bundle, it found imageio's binary via Python 3.12 and the reported executable printed ffmpeg 9.0.2. The new production lookup probes candidates and writes the handoff. It adds no file deletion.

| # | Finding | Evidence | File:line | Exact quote | Why it matters | Proposed fix | Confidence |
|---|---|---|---|---|---|---|---|
| 5 | BLOCKING: the output wait exceeds the documented probe deadline | OBSERVED | `tools/pc/runner_common.ps1:1565` | `$r.out = [string]$outTask.Result` | A temporary wrapper exited after starting a child that held stdout open for 23 seconds. Preflight accepted it and returned after 23.59 seconds. A child keeping the pipe open can stall the entire preflight. | Share one deadline across process exit and pipe reads. Bound cleanup of the probe's children and continue to the next candidate on timeout. | High |
| 6 | SHOULD-FIX: a valid Windows path is lost in the batch handoff | OBSERVED | `tools/pc/runner_common.ps1:1692` | `(New-Object Text.ASCIIEncoding)` | Preflight accepted an executable in `café tools` and exited 0. The existing writer put `caf? tools` in `tools.cmd`. That path did not exist. The new Python lookup uses this same handoff. | Pass paths losslessly to the job and execute the handed-off path in the Windows fixture. | High |

Not checked: Linux PowerShell, every Python Launcher version, or the last-resort directory scan with a broken imageio import. No package install or tools_live update ran.

## PR 1814 at `b32d3eaf` | Hull capture provenance

The pinned headless hull check passed. The unknown-code placeholder diagnostic was expected. The tracked manifest distinguishes V14_23 (NEW), H7_23 (OLD), and a missing code (UNLISTED). The guard allows the O1_37 teaching exception. The player-path recorder labels fleets without stopping. The squadron probe guards its carrier hulls before capture. Wiring the look bench is explicitly deferred by issue 1410.

| # | Finding | Evidence | File:line | Exact quote | Why it matters | Proposed fix | Confidence |
|---|---|---|---|---|---|---|---|
| 7 | BLOCKING: the recorded hull can differ from the one on screen | OBSERVED | `godot/render/hull_age.gd:55` | `if section is Dictionary and section.has(code):` | In a headless known-code fixture, the preferred entry loaded a mesh where a scene was required. ShipView drew the valid lower-tier scene named `ACTUAL_HI` with `a4=false`. The recorder helper reported `ships` and the rejected resource path. The unknown-code check misses this case. | Record source and resource in the successful ShipView load branch. Use both values for the player-path row and retain the fallback fixture. | High |
| 8 | SHOULD-FIX: an allowed old carrier loses its label in the reference picture | OBSERVED | `godot/fx/test/squadron_probe.gd:164` | `launch hull for context` | With the old-hull override, the guard returns an empty string. The battle-camera caption identifies neither the carrier code nor its layout, so an intentionally old reference can circulate without that information. | Include the drawn carrier's code and layout in the caption or the picture's provenance. Keep the override available. | High |

Not checked: GPU rendering, installed Battles 1 to 3, approved model hashes or the deferred look-bench wiring. The wrong-source case was reproduced with real Godot resource loading in a temporary project.


The full standing suite on the audit checkout at `0fd3b2861` exited 0 with 117 PASS and two KNOWN rows (`findings_tests` and `oracle_drift_guard`). Each of the eight quoted findings was also checked against its line in the pinned Git blob.

<details>
<summary>Raw source read receipts</summary>

All 33 file revisions below were retrieved through GitHub's raw Contents API and matched the fetched Git blobs byte for byte. Each entry gives the total lines and the first 40 characters of the last line, or the whole line if shorter. The quoted prefixes use JSON escaping to preserve tabs, spaces and empty lines.

**PR 1735 at `88d266f6`**

```text
docs/playbooks/balance.md  36  "these numbers, until a full-run Godot si"
godot/rules/sim/README.md  40  "on matching seeds and report the sample "
godot/rules/sim/balance_sim.gd  348  "\treturn fleet"
godot/rules/sim/sim_battle.gd  418  "\treturn report"
godot/rules/test/balance_sim_abilities_test.gd  59  "\tsuper._print_campaign(player_faction, c"
godot/tools/ci/godot_checks.txt  240  "headless|main/test/player_path_map_ready"
tools/pc/balance_sim.bat  34  "endlocal & exit /b %BALANCE_RESULT%"
godot/campaign/campaign.gd  4080  "\t\t\"events\": tel_log.slice(max(0, tel_log"
godot/rules/rules.gd  7332  "\tB[\"aiActive\"] = null; u[\"activated\"] = "
```

**PR 1734 at `fd6a0f6a`**

```text
contrib/opus/tools/fleet_list.js  205  "module.exports = { build, render, pagePr"
contrib/opus/tools/fleet_list_tests.js  207  "}"
docs/ship_pipeline/FLEET.md  98  "| Eclipse battleship (Totality) | `death"
.github/workflows/checks.yml  350  "          echo \"PASS\" | tee -a \"$GITHUB_"
.github/actions/merge-main/action.yml  27  "        fi"
.github/workflows/auto_pr.yml  204  "          fi"
.github/workflows/main_commit_lint.yml  31  "        run: node contrib/opus/tools/mai"
contrib/opus/tools/check_em_dashes.js  24  "if (!process.exitCode) console.log('No e"
contrib/opus/tools/main_commit_lint.js  71  "module.exports = { standingFrom, lint, p"
```

**PR 1805 at `212adbd5`**

```text
contrib/opus/tools/publish_ship_tests.js  110  "console.log(`publish_ship_tests: ${passe"
docs/playbooks/pc.md  131  "through `\"%JW%\" run`. The head and `cont"
tools/pc/jobs/publish_ship.bat  269  "exit /b 0"
tools/recipe/publish_ship.py  398  "        sys.exit(f'{label}: {exc}')"
tools/recipe/test/publish_ship_selftest.py  405  "    sys.exit(main())"
```

**PR 1806 at `5d061445`**

```text
contrib/opus/tools/pc_jobs_1194_tests.js  458  "console.log(`PASS PC jobs 1194 checks ($"
docs/playbooks/pc.md  130  "through `\"%JW%\" run`. The head and `cont"
tools/pc/runner_common.ps1  1769  "exit 0"
```

**PR 1814 at `b32d3eaf`**

```text
docs/playbooks/ships.md  610  ""
godot/fx/test/squadron_probe.gd  333  "\tWING.ship_manifest_path = out_path"
godot/main/player_path.gd  628  "\t\t_event(\"click_pending_timeout\", {\"hex\""
godot/render/hull_age.gd  83  "\treturn \"old or unlisted hull in a refer"
godot/render/test/hull_age_check.gd  56  "\tquit(0 if fails == 0 else 1)"
godot/tools/ci/godot_checks.txt  247  "headless|render/test/hull_age_check.gd|-"
godot/render/ship_view.gd  1788  "\t\tring.rotation.y = -rotation.y"
```

Large-file review ranges (inclusive): `campaign.gd` 941-984 and 4080, `rules.gd` 1514, 6451-6620 and 7332, `runner_common.ps1` 1512-1700 and 1769, `ships.md` 464-473 and 610, and `ship_view.gd` 41-55, 79-166 and 1788. The EOF reads establish file identity. The behavioral findings use the indicated production paths.

</details>

**Recommended next step:** Return each pinned head with its blocking row and the smallest reproducer above. Recheck the corrected heads against the main revision the Board will merge.

Not checked: a live GitHub merge, an installed ship publish or a GPU capture. The review used read-only Git comparisons, temporary fixtures and headless Godot 4.7.2.
