# PR 1669 review

Main and merge base `8a3c5d026f82b921675ab09b111e59417fb7bb8b`. Reviewed PR head `3140f68cda3625b65fa93577cc43d855a02bfac0`.

Evidence comes from the raw Git blobs at that head. The archive sections report their decompressed contents.

**Hold for fixes.** The clean PR reproduces the saved campaigns, and changing real battle or campaign rules makes the corresponding comparison fail against untouched results. The campaign checks can still accept a broken replacement baseline or a failing read test.


| # | Finding | OBSERVED/INFERRED | File and line | Exact quote | Why it matters | Fix | Confidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | High · The campaign baseline updater accepts truncated runs | OBSERVED | `godot/campaign/test/node/saved_campaign.js:40` | <code>if (!fs.existsSync(file) &#124;&#124; !fs.statSync(file).size)</code> | In a temporary copy, seed 2 wrote only `start` and `end` and exited 0. The original baseline rejected it, `update 2 2` accepted it, then `check 2 2` passed with 2 records instead of 84. The shipped archives themselves are complete. | Validate record shape and order, a real `startRun`, at least one resolved `battle`, and a legitimate terminal record before comparing or replacing an archive. Validate all records before writing any archive, and add the truncated-run regression case. | high |
| 2 | Medium · Two campaign subchecks can exit nonzero while the job passes | OBSERVED | `godot/campaign/test/run_campaign_checks.sh:10` | <code>"$G" --headless --path "$P" --script res://campaign/test/nem_read_test.gd</code> | The commands on lines 10 and 12 discard the process status and grep for PASS. The unchanged shell wrapper exited 0 with stand-ins that printed the PASS markers and returned 7 and 8. The previous wrapper required an exit of 0 and a PASS marker. | Require both a zero exit and the expected PASS marker for both scripts. Report the script exit and log when either condition fails. | high |
| 3 | Medium · The ship exception misses weapon definitions the active build check reads | INFERRED | `docs/RULEBOOK.md:290` | <code>a change to a ship's weapon list or hull entry also goes into data.js,</code> | `tools/blender/build_sheets/weapon_match.py:283` reads `gamedata.weapon_stats(wk)`. `tools/recipe/gamedata.py:65-80` gets weapon kind, shots and name from the global `W` in frozen data.js. A Godot-only shot-count or kind change leaves that build check grading old mounts. A newly assigned weapon missing from frozen W raises an error even if its ship list was mirrored. | Move the active `weapon_stats` reader to the Godot W table in the retirement change, or explicitly gate those weapon-definition changes on #1667. | high |
| 4 | Medium · The Build Variety instructions still send workers to the frozen sim | OBSERVED | `contrib/opus/design/build_variety_1453/PLAN.md:340` | <code>in `node sim3d.js campaign`</code> | The detailed measurement step contradicts the new Godot-only line 45. `sim3d.js:3` reads the frozen rules. Line 160 still assigns effects to `battle.js`, and lines 221 and 254 still require both copies to agree. | Use the #1656 simulator for all current balance measurements and mark that work pending until it lands. Replace the remaining browser edit instructions with the Godot targets. | high |
| 5 | Medium · The baseline report silently treats lookup or parse errors as new baselines | OBSERVED | `godot/rules/test/saved/diff_vs_main.js:16` | <code>catch { return null; }</code> | An invalid ref returned 0 and reported 328 additions. The pinned main ref correctly reported 31 campaign additions. The same catch swallows malformed JSON and Git read errors. | Resolve the base commit up front, require the base rules manifest, and allow only a genuinely absent campaign manifest for a pre-retirement base. | high |
| 6 | Medium · The documented PC entry point still compares live campaign rules to frozen JS | INFERRED | `godot/rules/test/saved/README.md:20` | <code>launcher. The ordinary `parity.bat` keeps its campaign hand-off.</code> | `tools/pc/parity.bat:31` calls `parity_campaign.bat`, which exports the frozen campaign table at line 49 and compares to the live table at lines 50 to 51. A legitimate Godot-only campaign change can make the usual PC check fail while the replacement CI gate passes with reviewed results. | Point the ordinary PC launcher at the Godot saved campaign check. Mark the older browser launcher as historical in the README. The artifact snippet at README lines 119 to 134 can now point to the actual workflow step. | high |
| 7 | Low · Live Rulebook sections still require the retired workflow | OBSERVED | `docs/RULEBOOK.md:993` | <code>A change to data.js or battle.js names every copy it must refresh, and rules parity passes.</code> | 3.1 correctly sets the new authority and CI command. 12.4 still mandates rules parity and 2.12 at line 250 still describes rules or data changes as mirrored into Godot. Both are live instructions for future work. | Bring 2.12 and 12.4 into line with 3.1 and keep the #1667 ship exception in 3.1. | high |

**Recommended next step.** Fix the two campaign gate paths before merging, and align the active worker instructions and the temporary ship-data exception with the new source of truth.

## `.github/workflows/checks.yml`

**Sound | OBSERVED.** The renamed job retains its `godot-parity` id and runs the battle, campaign and tree hand-off gates. Lines 338 and 348 still require every job and reject failures, cancellations and unexpected skips. The matrix contributes one aggregate result, so any failed shard keeps `All checks` red. Findings 1 and 2 concern the scripts this workflow runs.

Source has 350 lines. Last-line prefix `"          echo \"PASS\" | tee -a \"$GITHUB_"`.

## `AGENTS.md`

**Sound | OBSERVED.** The game summary now identifies Godot as the rules source and points to RULEBOOK 3.1 for the temporary ship exception.

Source has 101 lines. Last-line prefix `"(seat table, ship sections, PC notes) is"`.

## `CLAUDE.md`

**Sound | OBSERVED.** It directs rules work to Godot and expressly records the temporary issue 1667 exception.

Source has 17 lines. Last-line prefix `"  their own PRs. LOOP.md holds the live "`.

## `battle.js`

**Sound | OBSERVED.** Only the first-line comment changed. The executable browser code is byte-identical to main.

Source has 2403 lines. Last-line prefix `"}"`. Line ranges 1 to 500, 501 to 1000, 1001 to 1500, 1501 to 2000, 2001 to 2403.

## `campaign3d.js`

**Sound | OBSERVED.** Only the first-line comment changed. The executable browser code is byte-identical to main.

Source has 158 lines. Last-line prefix `""`.

## `campaign_meta.js`

**Sound | OBSERVED.** Only the first-line comment changed. The executable browser code is byte-identical to main.

Source has 435 lines. Last-line prefix `"ACT.nextFac=f=>{ pickedFaction=f; META.o"`. Line ranges 1 to 435.

## `campaign_run.js`

**Sound | OBSERVED.** Only the first-line comment changed. The executable browser code is byte-identical to main.

Source has 868 lines. Last-line prefix `"}"`. Line ranges 1 to 500, 501 to 868.

## `contrib/opus/FINDINGS.md`

**Sound | OBSERVED.** R405 records the owner approval, the saved-results design and the two migration tickets.

Source has 586 lines. Last-line prefix `"| X17 | Muse follow-up pass over unasses"`. Line ranges 1 to 500, 501 to 586.

## `contrib/opus/design/build_variety_1453/PLAN.md`

**Defect | OBSERVED | Finding 4.** The new top-level direction and the detailed worker instructions disagree.

Source has 357 lines. Last-line prefix `"cloud sim is too slow."`.

## `contrib/opus/tools/nemesis_122_tests.js`

**Sound | OBSERVED.** This is a comment-only change. The existing JavaScript assertions are historical coverage. The revised comment points to the Godot saved-results check for live behavior.

Source has 160 lines. Last-line prefix `"})();"`.

## `contrib/opus/tools/oracle_copy_test.js`

**Sound | OBSERVED.** It keeps the missing-table and retired-folder checks. Table content validation moves to the Godot checksum check.

Source has 31 lines. Last-line prefix `"console.log('PASS: no oracle folders exi"`.

## `contrib/opus/tools/ui_spec_tests.js`

**Sound | OBSERVED.** The source assertion points to the new script, which does invoke the Godot map read-only harness.

Source has 278 lines. Last-line prefix `"process.exitCode = fail ? 1 : 0;"`.

## `core.js`

**Sound | OBSERVED.** Only the first-line comment changed. The executable browser code is byte-identical to main.

Source has 543 lines. Last-line prefix `"function findNode(id){ for(const c of RU"`.

## `data.js`

**Sound | OBSERVED.** Only the first-line comment changed. The executable browser code is byte-identical to main.

Source has 5350 lines. Last-line prefix `"};"`. Line ranges 1 to 500, 501 to 1000, 1001 to 1500, 1501 to 2000, 2001 to 2500, 2501 to 3000, 3001 to 3500, 3501 to 4000, 4001 to 4500, 4501 to 5000, 5001 to 5350.

## `docs/RULEBOOK.md`

**Defect | INFERRED and OBSERVED | Findings 3 and 7.** 3.1 states the intended Godot authority and the live CI coverage. The temporary ship exception does not cover one live weapon-table reader, and two operative rules still describe the old workflow.

Source has 1004 lines. Last-line prefix `"draws meshes at full detail. Set: Ryan, "`. Line ranges 1 to 500, 501 to 1000, 1001 to 1004.

## `godot/campaign/test/node/saved_campaign.js`

**Defect | OBSERVED | Finding 1.** A real table change failed with the original archive. A replacement two-record run passed after update.

Source has 71 lines. Last-line prefix `"process.exit(fails ? 1 : 0);"`.

## `godot/campaign/test/run_campaign_checks.sh`

**Defect | OBSERVED | Finding 2.** Two subchecks can print PASS and return errors while the wrapper returns 0.

Source has 14 lines. Last-line prefix `"if [ $F -eq 0 ]; then echo \"PASS: campai"`.

## `godot/campaign/test/saved/c1.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 188 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 188 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":187}"`. Line ranges 1 to 188.

## `godot/campaign/test/saved/c10.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 102 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 102 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":101}"`. Line ranges 1 to 102.

## `godot/campaign/test/saved/c11.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 20 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 20 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":19}"`.

## `godot/campaign/test/saved/c12.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 202 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 202 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":201}"`. Line ranges 1 to 202.

## `godot/campaign/test/saved/c13.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 42 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 42 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":41}"`. Line ranges 1 to 42.

## `godot/campaign/test/saved/c14.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 33 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 33 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":32}"`. Line ranges 1 to 33.

## `godot/campaign/test/saved/c15.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 221 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 221 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":220}"`. Line ranges 1 to 221.

## `godot/campaign/test/saved/c16.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 93 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 93 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":92}"`. Line ranges 1 to 93.

## `godot/campaign/test/saved/c17.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 36 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 36 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":35}"`. Line ranges 1 to 36.

## `godot/campaign/test/saved/c18.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 245 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 245 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":244}"`. Line ranges 1 to 245.

## `godot/campaign/test/saved/c19.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 215 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 215 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":214}"`. Line ranges 1 to 215.

## `godot/campaign/test/saved/c2.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 84 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 84 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":83}"`. Line ranges 1 to 84.

## `godot/campaign/test/saved/c20.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 268 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 268 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":267}"`. Line ranges 1 to 268.

## `godot/campaign/test/saved/c21.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 24 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 24 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":23}"`. Line ranges 1 to 24.

## `godot/campaign/test/saved/c22.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 204 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 204 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":203}"`. Line ranges 1 to 204.

## `godot/campaign/test/saved/c23.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 177 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 177 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":176}"`. Line ranges 1 to 177.

## `godot/campaign/test/saved/c24.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 156 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 156 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":155}"`. Line ranges 1 to 156.

## `godot/campaign/test/saved/c25.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 171 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 171 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":170}"`. Line ranges 1 to 171.

## `godot/campaign/test/saved/c26.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 207 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 207 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":206}"`. Line ranges 1 to 207.

## `godot/campaign/test/saved/c27.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 140 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 140 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":139}"`. Line ranges 1 to 140.

## `godot/campaign/test/saved/c28.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 209 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 209 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":208}"`. Line ranges 1 to 209.

## `godot/campaign/test/saved/c29.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 205 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 205 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":204}"`. Line ranges 1 to 205.

## `godot/campaign/test/saved/c3.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 168 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 168 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":167}"`. Line ranges 1 to 168.

## `godot/campaign/test/saved/c30.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 119 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 119 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":118}"`. Line ranges 1 to 119.

## `godot/campaign/test/saved/c4.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 202 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 202 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":201}"`. Line ranges 1 to 202.

## `godot/campaign/test/saved/c5.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 228 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 228 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":227}"`. Line ranges 1 to 228.

## `godot/campaign/test/saved/c6.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 199 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 199 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":198}"`. Line ranges 1 to 199.

## `godot/campaign/test/saved/c7.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 62 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 62 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":61}"`. Line ranges 1 to 62.

## `godot/campaign/test/saved/c8.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 201 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 201 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":200}"`. Line ranges 1 to 201.

## `godot/campaign/test/saved/c9.jsonl.br`

**Sound | OBSERVED.** The archive decompresses to 202 sequential JSON records, reaches `startRun` and a battle outcome, and ends in `end`. Its SHA-256 and byte count match the manifest. A fresh frozen browser run matches its steps under the old comparator.

Decompressed evidence has 202 lines. Last-line prefix `"{\"act\":\"end\",\"arg\":\"\",\"i\":201}"`. Line ranges 1 to 202.

## `godot/campaign/test/saved/nem.txt.br`

**Sound | OBSERVED.** The archive decompresses to 223 records, matches the recorded SHA-256 and byte count, and is byte-identical to the fresh frozen browser Nemesis transcript.

Decompressed evidence has 223 lines. Last-line prefix `"rr3 {\"parked\":false,\"same\":true}"`. Line ranges 1 to 223.

## `godot/campaign/test/saved/results.json`

**Sound | OBSERVED.** The manifest accounts for all 30 expected campaign seeds and the Nemesis transcript. All 31 decompressed payloads agree with their recorded SHA-256 and size.

Source has 161 lines. Last-line prefix `"}"`.

## `godot/rules/test/node/run_parity.js`

**Sound | OBSERVED.** The default run feeds original Godot records to the saved checker at lines 247 to 249, adds its failure count, and returns a failing exit at line 255. Battle records also have completeness checks. Browser history mode exports into its temporary run directory and checks the live table hash before proceeding.

Source has 264 lines. Last-line prefix `"if (require.main === module) run().then("`.

## `godot/rules/test/saved/README.md`

**Defect | INFERRED | Finding 6.** The current Linux commands and history mode are accurately described at the top. The ordinary PC launcher still invokes the old campaign oracle.

Source has 136 lines. Last-line prefix `"This upload is for access to the files; "`.

## `godot/rules/test/saved/diff_vs_main.js`

**Defect | OBSERVED | Finding 5.** Main produced the expected 31 campaign additions. An invalid base produced 328 additions and a green exit.

Source has 31 lines. Last-line prefix `"if (process.env.GITHUB_STEP_SUMMARY) fs."`.

## `godot/rules/tools/reseal_tables.gd`

**Sound | OBSERVED.** It computes the checksum from the Godot-decoded tables and leaves files untouched in check mode. The clean check reported both checksums current.

Source has 35 lines. Last-line prefix `"\tquit(1 if bad else 0)"`.

## Checks

- [GitHub Actions checks at the reviewed head](https://github.com/rcbailey12/voidsworn/actions/runs/45024469078) passed, including the standing job, all three Godot game shards, Rules safety net, A16, Godot rules (saved results), and All checks.
- Fresh Godot output matched all 30 committed campaign archives and the 223-record Nemesis transcript byte for byte. A fresh frozen browser run matched all 30 archives under the old step comparator, and its Nemesis transcript was byte-identical. The campaign harness runs the real campaign flow with scripted battle outcomes.
- The local UI assertions passed 182 of 182, the legacy Nemesis assertions passed 18 of 18, and the oracle-folder/table presence check passed. The source diff passed `git diff --check`. The two table JSON blobs, the existing battle baseline and the Godot rules and campaign implementations are unchanged against main.
- The Godot game-check fixture at `contrib/opus/tools/effect_caps_tests.js:8` still loads frozen `data.js` and `core.js` for expected values. A Godot-only change to a covered effect could conflict with those expectations. #1667 tracks migrating this fixture, and #1656 tracks the simulator port.
- In a temporary copy, changing Autocannon damage from 5 to 6 and campaign rank XP from 30 to 25 made the checksum check fail before resealing. After reseal, the battle check exited 1 for s1, s4 and threat_s4, and the campaign check exited 1 at seed 2, step 10. The truncated baseline and the read-test exit checks reproduced Findings 1 and 2.
- The independent Windows battle check passed all 289 battles and the eight auxiliary files, with zero changes or failures.
- The separate sparse Windows standing run reported missing local fixtures and Windows harness failures. The full GitHub Actions standing job passed at the reviewed head.

## Not checked

Manual play, GPU captures, and the full inventory of legacy JS readers. Local Windows Godot checks used an isolated profile and a certificate-bundle override in the temporary copy to avoid a certificate-store startup error.
