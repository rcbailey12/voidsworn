# Board Audit: Recent, Current and Planned Work, with Storage and Performance (Nov 25, 14:00 UTC)

- **Seat / Model:** Neon (`Gemini 4 Neon`, read-only audit; zero code changes outside `contrib/neon/`)
- **Issue / Branch:** `#2143` / `neon/issue-2143`
- **Commit SHA reviewed:** `bf01e577d4e74262a22c4296c0846952ccf0d4a8` (`origin/main`, Merge PR `#1904` Acid Thorns)
- **Live GitHub snapshot:** Nov 25 2026 ~14:00 UTC (94 open issues, 45 open PRs, 11 PRs merged since Nov 25 09:00 UTC)
- **PC evidence included:** PC disk space map and PC memory/crash notes posted on `#2143` at 13:58 UTC
- **Baseline:** Follow-up to issue `#2107` (`contrib/neon/reviews/board_audit_1125_0900.md`) under `docs/REVIEW_PROTOCOL.md`

---

## Executive Verdict

Between 09:00 and 14:00 UTC, the Board cleared 11 PRs (fixing `#2107`'s top three blockers: `runner_selftest.js`, Eclipse `legionRise()`, and the PR `#2127` backup regex, plus merging LOAD37 `#2053`, R01 relief `#2054`, LOAD38 `#2099`, Sonnet `#2102`, and Acid Thorns `#1904`). Four acute bottlenecks now dominate delivery and reliability:

1. **PC C: drive storage (165.6 GB free on 1.86 TB; 111 GB at 12:54 UTC) and 57 GB Windows commit ceiling:** The janitor freed only 0.6 GB because 2,091 Codex sandbox-owned folders block `Clear-KeptCheckout` and `Complete-RunScratch` (~150-200 GB stuck), `C:\Users\rcbai\.t3` holds 89.9 GB of unpruned Neon worktrees, `look_bench` holds 59.3 GB outside the janitor's scan, and `Test-RelayedResults` ignores `skipped_over_10MB.txt` and `skipped_cache_folders.txt` so relayed GPU jobs with videos/caches can never be deleted (~140 GB stuck). Meanwhile, the fixed 25.1 GB `pagefile.sys` caps Windows commit at ~57 GB (32 GB RAM + 25 GB pagefile), causing TRELLIS stage-2 host OOMs (`H7N`, `H8`, `S9A`, `H7P` even solo with 1.2 GB VRAM used) AND the `#2142` Lane D PowerShell pipeline crash while `codex.exe` kept running as an orphan.
2. **Delivered FX ID collisions and merge breaks:** `#2107`'s predicted FX pileup materialized. Sprite kinds `30-36` collide across `#2133`, `#2132`, `#2084`, and `#2069`; wound style `16` collides between `#2136` (`S_NULL_BURN`) and `#1755` (`S_PRISM`); `#2049` and `#2021` have mismatched bio-spark argument slots; `#2021` is conflicting and RED against newly merged `#1904`; `#2007` is conflicting and RED on a `lane_tools_refresh_selftest.js:128` race; and `#2142` contradicts `acid_thorn_check.gd`.
3. **AAA UI / binary-save bottleneck still open:** `#2105` (`#2078` + `#2080`) is now green and mergeable, but `#2119` (SY-A Gantry, still RED on `audio_check`, 77 behind `main`) blocks the flagship decommission, and `#2121`, `#2020`, `#2122` remain stacked behind it.
4. **High-value performance wins sitting on the table:** `#1852` (round-2 150-190 ms pipeline hitch fix) is green and held only by a stale `[HOLD: 1445]` title; `#2135` (Wounds V2) still lacks a valid candidate frame-time measurement and has an unguarded live Chorus interior shader bug; `#2134` (LOAD39) has a main-thread-object-on-worker race; and GitHub CI runs ~55 Godot tests serially per shard on a 4-vCPU runner while `run_checks.sh:114` hides real failures behind `placeholder hull:` spam.

---

## Top 5 Fixes First

1. **Reclaim 380-430 GB on C: and raise the 57 GB commit ceiling (Storage + Stability, immediate):**
   - *One-time PC actions (Ryan):* switch `pagefile.sys` from fixed 25 GB to system-managed (or 64-96 GB min) so TRELLIS and 6-lane runs stop hitting commit exhaustion; run an elevated ownership-reset + prune `.bat` on the 2,091 sandbox-owned folders in `TEMP\voidsworn-run-*` and `repo-kept-*` (~150-200 GB) and closed T3 thread worktrees in `C:\Users\rcbai\.t3` (up to ~90 GB).
   - *Tool fixes (one Codex/Board PR):* stop passing `%PC_RUN_SCRATCH%` as Codex sandbox `TEMP` or run cleanup inside the sandbox/helper; make `Clear-KeptCheckout` handle unreadable folders instead of aborting the whole checkout; make `janitor.ps1` `Test-RelayedResults` honor `skipped_over_10MB.txt` and `skipped_cache_folders.txt` (matching `opus_job_head.ps1`); auto-relay then immediately drop checkouts at `opus_job_head.bat` job end; add `look_bench` and `work217` cleanup to `janitor.ps1`.
2. **Freeze new FX branches and serialize FX merges behind an explicit ID/API table:**
   - Assign disjoint `fx_shaders.gd` sprite kind ranges (`#2133` vs `#2132` vs `#2084` vs `#2069`) and fix `#2136` `S_NULL_BURN` colliding with `#1755` `S_PRISM := 16`; rebase `#2021` onto `#1904` (preserving `#1904`'s 2.5 s acid-etch shader, not reverting to 300 s); align `#2049`/`#2021` bio-spark params; reconcile `#2142`'s brief with `acid_thorn_check.gd` before re-running.
3. **Clear the AAA UI and binary-save merge train (`#2105` -> `#2119` -> `#2121` -> `#2020` -> `#2122`):**
   - Merge green `#2105` (`0f9a3bae`) now; fix `#2119`'s `audio_check: FAIL` and rebase it onto `#2105` so flagship decommission unblocks; then rebase and land `#2121`, `#2020`, `#2122` in order.
4. **Land the 4 fastest performance wins (Game + PC pipeline):**
   - Re-verify and merge already-green `#1852` (round-2 150-190 ms pipeline hitch); fix `#2135` (Wounds V2 Chorus live-hull gate + pre-cut wreck shader split + valid V2-on control/candidate solo timing); land `#2134` (LOAD39) only after snapshotting plain arrays on main so worker threads never touch `Node3D`/`_hull_geometry`; parallelize `godot/tools/ci/run_checks.sh` (`xargs -P 2` or `-P 3`) and filter `placeholder hull:` out of line 114's 8-line failure tail.
5. **Execute a 15-minute Board housekeeping sweep (Bugs, R288, Docs, CI flakes):**
   - Merge green `#2052` (Sound Gate 3), then rebase `#2071` and fix Artoo's still-open `last[name] = t` cooldown bug; fix `#2140`'s occupied-hex relay hover bug (`battle.gd:5948-5952`); fix `lane_tools_refresh_selftest.js:128` file-read race (unblocking `#2007`); close newly merged R288 issues (`#2085` once merged-pin proof noted, `#2027`, `#2023`; link Acid Thorns rename/sound follow-up before closing `#1877`) plus older R288 issues (`#1887`, `#1572`, `#1328`, `#1779`, `#1943`) and superseded PRs (`#1881`, `#1896`, `#1718`, `#1163`, `#2000`); roll `LOOP.md` (now 89 LATEST lines) and sync `HANDOFF.md`/`PROGRAM.md` with R449 and live mirror layout.

---

## Ranked Findings (Most Urgent First)

Categories match `#2107`: **Problem**, **Priority**, **Bug**, **Speed**.

| Rank | Tag | Where | Exact Quote | Observed / Inferred | Why It Matters | One-Line Fix | Confidence |
|---:|---|---|---|---|---|---|---|
| 1 | Problem | `tools/pc/runner_common.ps1:781,961`, `tools/pc/disk_space.ps1:98-103`, `#2143` PC map | `if (-not $allowUnreadable) { throw "folder another account owns: $($folder.FullName)" }` | OBSERVED | One Codex sandbox-owned subfolder aborts `Clear-KeptCheckout` and `Complete-RunScratch`, leaving 2,091 folders and ~150-200 GB permanently undeletable while janitor freed only 0.6 GB. | Stop pointing Codex sandbox `TEMP` at host `PC_RUN_SCRATCH` (or delete inside sandbox), pass `-AllowUnreadable` / salvage-first in `Clear-KeptCheckout`, and give Ryan a one-click elevated ACL-reset `.bat`. | High |
| 2 | Bug | `tools/pc/janitor.ps1:313-327` vs `tools/pc/relay_push.ps1:178,192` | `if (-not $receipts.Contains($hashes[$i])) {` / `if ($missing) { throw "results not all relayed: ..."` | OBSERVED | `relay_push.ps1` intentionally skips files >10 MB and `profile`/`shader_cache`/`.godot`, and `opus_job_head.ps1:511-549` accepts both manifests, but `janitor.ps1` does not, permanently trapping relayed 10-19 GB GPU job folders on disk. | Port `opus_job_head.ps1:511-549`'s `skipped_over_10MB.txt` and `skipped_cache_folders.txt` manifest checks into `janitor.ps1` `Test-RelayedResults`. | High |
| 3 | Problem | `#2143` PC notes, `tools/pc/trellis_fleet.py:58-66`, `tools/recipe/2_shape_ref.bat:21-22`, `tools/pc/codex_issue.ps1` | `Windows commit near its 57 GB limit with a fixed 25 GB pagefile` / `H7P ran solo on a quiet PC with nvidia-smi showing 1.2 GB used` | OBSERVED | Fixed 25.1 GB `pagefile.sys` + 32 GB RAM caps commit at ~57 GB, causing TRELLIS stage-2 host OOMs (`H7N`, `H8`, `S9A`, `H7P`) AND the `#2142` Lane D PowerShell pipeline crash that left `codex.exe` running as an orphan. | Raise Windows pagefile to system-managed (or 64-96 GB), claim `PC_GPU_MODE=solo` + preflight free commit in `2_shape_ref.bat`, free `pipe` before `to_glb` in `trellis_fleet.py`, and kill child process trees on wrapper `RuntimeException`. | High |
| 4 | Problem | `tools/pc/janitor.ps1:445-446`, `tools/pc/jobs/look_bench.bat:7-8`, `#2143` PC map | `$helperJobName = '\Aopus(?<issue>[1-9][0-9]*)(?:[A-Za-z_-][A-Za-z0-9_-]*)?\z'` / `look_bench 59.3` / `C:\Users\rcbai\.t3 89.9` | OBSERVED | `look_bench` (59.3 GB) and `.t3` Neon worktrees (89.9 GB + 28.3 GB `t3_neon`) account for 177.5 GB and are completely outside `janitor.ps1`'s scan; `look_bench.bat` never calls `relay_push.bat` and explicitly deletes nothing. | Relay `look_bench\runs\<commit>` at run end and prune bench checkouts/runs older than 24 h in `janitor.ps1`; add a T3-closed prune script for pushed `.t3` worktrees. | High |
| 5 | Bug | PRs `#2133`, `#2132`, `#2084`, `#2069`, `#2136`, `#1755`, `#2049`, `#2021` | `const S_NULL_BURN := 16` (`#2136`) vs `const S_PRISM := 16` (`#1755`); `k >= 30 && k <= 36` (`#2133`) vs `30/31` (`#2132`), `30` (`#2084`), `34` (`#2069`) | OBSERVED | Merging these open FX PRs silently corrupts sprite shaders, overwrites prism wounds with null-lance wounds, and miswires bio-spark arguments (`#2049` `hull_contact, with_sparks` vs `#2021` `sparks`). | Publish one reserved ID registry in `fx_shaders.gd` / `fx_breach.gd`, renumber colliding PRs before merge, and standardize `fx_weapons.gd` bio-spark params. | High |
| 6 | Bug | PR `#2021` (`codex/issue-1693`, `207f5d71`) vs merged `#1904` (`bf01e577`) | `checksState: failing` / conflicts in `fx_shaders.gd` after `#1904` Acid Thorns merged | OBSERVED | `#2021` is RED and conflicting; taking `#2021`'s `fx_shaders.gd` wholesale would revert `#1904`'s crazed-pit acid etch and 2.5 s decay back to 300 s emission. | Rebase `#2021` onto `main` (`bf01e577`), keeping `#1904`'s acid-etch shader, and re-run checks before any GPU capture. | High |
| 7 | Bug | PR `#2135` (`codex/issue-2125`, Wounds V2), `LOOP.md:91` | `keys on wound_v2 == 3 without gating on the wreck transition` (Artoo); `PROOF_A` failed `DAMAGE_PROFILE` on before arm | OBSERVED | Run 2 overrides live Chorus breach interiors (not just wrecks), and `PROOF_A` never recorded candidate frame time (`DEFAULT_B` was 19.49 ms p99 on older `2a479682`). | Gate Chorus interior override on wreck state, combine `#1997`'s pre-cut wreck shader split, and re-run solo timing with `DAMAGE_PROFILE` only on V2-on arms. | High |
| 8 | Priority | PR `#2119` (`codex/issue-2038`, SY-A Gantry) + stacked `#2105`, `#2121`, `#2020`, `#2122` | `audio_check: FAIL` / `77` behind `main`, conflicting; blocks flagship decommission | OBSERVED | `#2105` is now green and ready, but `#2119` remains RED and conflicting, stalling the entire AAA shipyard/flagship/campaign-HUD merge train (`#2121`, `#2020`, `#2122`). | Merge `#2105` first, fix `#2119`'s `audio_check` failure and rebase onto `#2105`, then rebase `#2121` -> `#2020` -> `#2122`. | High |
| 9 | Bug | PR `#2140` (`work/issue-1403-opus`, battle teaching) | `_attack_tip` returns early when a ship occupies the relay hex (`battle.gd:5948-5952,5966-5975`, Artoo) | OBSERVED | Players hovering an occupied relay hex lose the relay rule and score explanation, directly breaking `#1403`'s teaching goal. | Append the relay-hex rule/score line to `_attack_tip` (or show both) before merging `#2140`. | High |
| 10 | Bug | `tools/pc/lane_tools_refresh_selftest.js:128-129`, PR `#2007` (`codex/issue-1991`) | `assert.ok(until(() => fs.existsSync(ready), 30000), ...);` / `assert.equal(fs.readFileSync(ready, 'utf8'), '14', ...)` | OBSERVED | Non-atomic `WriteAllText` in the test causes `readFileSync` to read `''` instead of `'14'`, making `#2007` RED on `Standing checks` (and flaking local Windows checks). | Write to `ready + '.tmp'` then `Move-Item`/rename (or poll until file content is non-empty) in `lane_tools_refresh_selftest.js:125-129`, then rebase `#2007`. | High |
| 11 | Speed | `godot/tools/ci/run_checks.sh:83-117`, `contrib/codex/issue-2078/NOTES.md` run 3 | `while IFS='|' read -r cls script setup args reason; do` / `grep -E 'SCRIPT ERROR\|FAIL\|ERROR' "$T/logs/$name.log" ... \| head -8` | OBSERVED | Serial one-process-per-test runs waste ~200 s/shard in cold Godot startup on 4-vCPU runners (noisy runners hit the 600 s budget and cascade-fail), and 24 `placeholder hull:` lines hid the real `plan_commit_check` failure, wasting a full `xhigh` Codex run (`#2078` run 3). | Run 2-3 checks concurrently per shard with per-job `$T/xdg/$name`, filter `placeholder hull:` (or show `FAIL` before `ERROR`) at line 114, and refresh `godot_check_times.txt`. | High |
| 12 | Speed | PR `#1852` (`codex/issue-1843`, round-2 pipeline hitch) | `[HOLD: contains an old 1445 head; rebase after 1445 merges]` | OBSERVED | Already green and mergeable on `main` (eliminates 150-190 ms round-2 first-firing-arc hitch), but stalled by a stale title and a pre-LOAD38 control pin (`3131184b`). | Drop the stale HOLD title, run one short solo A/B against post-`#2099` `main`, and merge `#1852`. | High |
| 13 | Bug | Issue `#2134` (LOAD39), `godot/fx/fx_hull.gd:567-593,713-751`, `godot/render/ship_view.gd:129-139` | `faces_of()` reads live `Node3D` transforms; `_geometry()` mutates `_hull_geometry`; `drain_build()` joins synchronously | OBSERVED | Moving `hull.analyse` off the main thread as-is risks worker crashes/races on `Node3D` and `_hull_geometry` and can shift exit stalls into `drain_build()`. | Snapshot plain vertex/transform arrays on main, build BVH on worker, publish on main if generation still matches, and drop/cancel on quit. | High |
| 14 | Bug | Issue `#2142` (torpedoes/Acid Thorns end on impact) vs `acid_thorn_check.gd:67-82` | `acid_thorn_check.gd` requires hull-hit thorns to stay embedded (Artoo preflight) | OBSERVED | `#2142`'s brief contradicts the merged `#1904` unit test; Lane D also crashed (`PARTIAL RUN`) under commit pressure before pushing a full PR. | Clarify whether Acid Thorns embed or vanish on hull hit, update the brief/test together, and re-run on a clean lane. | High |
| 15 | Bug | PR `#2071` (`work/issue-2034-sonnet`, AAA sound mix) & PR `#2052` (`codex/issue-2039`) | PR `#2071` body explicitly notes Artoo's `last[name] = t` cooldown-reservation bug is still unfixed; overlaps `#2052` | OBSERVED | `#2052` run 5 fixed the Brisk cue and is green/mergeable; `#2071` is CI green but still drops audio cues on blocked attempts because cooldown stamps before play succeeds. | Merge green `#2052` now, then rebase `#2071` onto `#2052` and only stamp `last[name] = t` after playback actually starts. | High |
| 16 | Bug | PR `#1960` (`codex/issue-1780`) vs PR `#2106` (`neon/issue-2103`) vs merged `#2054`/`#2099` | Both `#1960` and `#2106` conflict with `main` and disagree on 4-arg vs 5-arg R01 relief contract | OBSERVED | `#1960` caches 48 `Shader.new()` calls + BC7 + FSR 2.2 + fog gate (big VRAM/stutter win), but cannot land cleanly until rebased onto `#2054`/`#2099` and reconciled with `#2106` (plus strengthening `performance_1780.gd:193-219` fog assertion). | Rebase `#1960` onto `main`, agree one R01 signature with `#2106`, and extend `shader_pow_2092.js` to scan `.gdshaderinc` files. | High |
| 17 | Bug | `tools/pc/runner_common.ps1:579-587` vs `HANDOFF.md:14-17` & `contrib/opus/LOOP.md:49` | `'board_e' { 'repo-mirror-e.git' }` / `'board_f' { 'repo-mirror-f.git' }` / `default { 'repo-mirror.git' }` | OBSERVED | Main, B, C, D, all 7 `work217` slots, `ship_job.bat`, `helper_clone.ps1`, `opus_job_head.ps1`, and `janitor.ps1` all contend on ONE `repo-mirror.git.lock`, contradicting both `HANDOFF.md` and `LOOP.md`. | Stop holding `repo-mirror.git.lock` during multi-minute janitor deletes, align docs with code, and either use `--reference` / per-group read-only mirrors or short lock-around-fetch only. | High |
| 18 | Bug | PR `#1725` (`opus/issue-1412`), PR `#1763` (`opus/issue-1743`), PR `#2017` (`codex/issue-2001`), PR `#1980` (`codex/issue-1974`) | `#1725` RED (`585` behind `main`); `#1763` `interior_kit.py:697-709` scans `bpy.context.scene.objects`; `#1980` plays `hit_heavy` on 0-damage crit (`battle.gd:3435-3438`) | OBSERVED | Four long-running open PRs have known unresolved defects (`#2017` also conflicts 84 behind `main` with confirmed `terran_c26` band 2 miss `0.255`/`0.267`). | Fix `#1980`'s `if dmg > 0` guard (quick win), scope `#1763` to hull collections and update stale `Merge order: PR 1724`, rebase `#2017`, and rebuild `#1725` after pagefile fix. | High |
| 19 | Priority | Open issues `#2085`, `#2027`, `#2023`, `#1877`, `#1887`, `#1572`, `#1328`, `#1779`, `#1943` & PRs `#1881`, `#1896`, `#1718`, `#1163`, `#2000` | `Close an issue in the same step as its merge when its scope is done (R288)` (`AGENTS.md`); `tables.json` still has `"n":"Boarding tendrils"` (`#1877` Artoo) | OBSERVED | 4 more merged issues were left open since 09:00 UTC (making 9+ open-but-merged issues and 5 superseded open PRs), inflating the 94-issue / 45-PR board; `#1877` also lacks a tracked rename/sound follow-up ticket. | Close `#2027`, `#2023`, `#1887`, `#1572`, `#1328`, `#1779`, `#1943` and superseded PRs; file Acid Thorns rename+sound issue then close `#1877`; close `#2085` once merged-pin proof is linked. | High |
| 20 | Priority | `contrib/opus/LOOP.md:46-49,84-172`, `docs/playbooks/PROGRAM.md:77-80`, `#1401`, `#1405` | `LATEST line count: 89 (first=84, last=172)`; `PROGRAM.md:77` `Opus 5.5 worker threads, not capped`; `PROGRAM.md:80` `Muse (Ryan starts every run)` | OBSERVED | `LOOP.md` grew from 84 to 89 LATEST lines (lock still frozen Nov 16 16:00), `PROGRAM.md` contradicts R449 (API cap/route) and Nov 17 self-starting Muse, and `#1401`/`#1405` still say `queued after PR 1445 merges` even though `#1445` merged Nov 24. | Archive older LATEST lines into `LOOP_ARCHIVE`, update `PROGRAM.md` and `LOOP.md` seat rules to R449/live lanes, and queue or re-scope `#1401` slice B and `#1405`. | High |

---

## Separate Section: Storage Audit (Why C: Keeps Running Low & How to Fix Tools and Workflow)

### 1. Where the 1,699.2 GB Used on C: Actually Lives (PC Disk Space Map, Nov 25 13:58 UTC)

On Ryan's 1,859.9 GB C: SSD, free space dropped to **111 GB at 12:54 UTC** (`114 GB` before today's cleanup; `160.7 GB` at map time; `165.6 GB` after removing `opus1743jointh/jointg`). The map accounts for **960.6 GB** inside Voidsworn/T3/cache paths (each hard-linked file counted once); ~740 GB sits outside scanned folders (Windows, Program Files, other AppData/user files).

| Bucket (from `#2143` PC disk map) | Size (GB) | Count / Breakdown | Reclaimable Now? | Why Janitor Missed It (Observed in Code) |
|---|---:|---|---|---|
| **Job folders** (`opus/astra/neon/codex/look_bench`) | **231.6** | 263 folders: `look_bench` 59.3, `opus1373probe11` 18.9, `opus1262` 17.6, `opus1434u` 10.9, `opus1434w` 10.8, `opus1743fleete` 10.1, `opus1433pp2` 10.0 | **~140 GB** (after relay) | `janitor.ps1:445` never scans `look_bench`; `Test-RelayedResults` (`janitor.ps1:313-327`) ignores `skipped_over_10MB.txt` & `skipped_cache_folders.txt`; `opus_job_head.bat` never auto-relays. |
| **Lane checkouts** (`repo`, `repo-kept-*`, `work217` slots) | **195.9** | 45 folders across 6 Codex lanes + 7 Workhorse slots | **~100-140 GB** | `Clear-KeptCheckout` (`runner_common.ps1:961`) calls `Measure-CleanupDirectory` without `-AllowUnreadable` -> one sandbox-owned folder aborts entire removal; `finish` skips `unverified`/`partial`/`failed` and `work217` (`runner_common.ps1:2248-2256`). |
| **T3 Code caches/worktrees** (`C:\Users\rcbai\.t3`) | **89.9** (of 97.7) | Neon thread worktrees and T3 session data | **Up to ~90 GB** | Completely outside `janitor.ps1`; every T3 worktree checks out a full non-hardlinked working tree and persists after branch push. |
| **TEMP run scratch** (`voidsworn-run-*`) | **61.2** | 191 folders | **~55-60 GB** | `codex_issue.bat:134-136,154` sets sandbox `TEMP/TMP` to `PC_RUN_SCRATCH`; `Complete-RunScratch` (`runner_common.ps1:695-699,722`) throws on first sandbox folder and abandons the rest; janitor skips all 2,091 sandbox-owned folders. |
| **`voidsworn_test` other** | **119.7** | `t3_neon` 28.3, `recipe` 26.2, `sync_old` 18.3, `board` 13.6, `board_b` 12.7 | **~44 GB** (`sync_old` + verified `recipe`) | Legacy folders (`sync_old`, old `recipe` scratch) are outside `janitor.ps1` scope. |
| **Tools & engines** | **87.4** | `build` 48.1 (game build), `slots` 20.5 | Partial (`slots` trims with `OJ_SLOTS`) | `opus_job_head.ps1:1109` re-copies `godot/gen` + `assets/ships` per slot; `lane_tools_refresh.ps1:352-358` never prunes old `export-*.zip` or `<40-hex>` snapshots. |
| **Trellis & HF models** | **54.3** | `Downloads\trellis2` 31.1 (keep), `.cache\huggingface` 23.2 | 23.2 GB (re-downloads) | Keep `trellis2`; HF cache only if Ryan approves. |
| **Mirrors & clones** | **38.8** | `repo-mirror.git` 26.2 + mirror-e/f + `relay-mirror.git` | Keep (GC saves ~5-10 GB) | 4 separate bare mirrors (`runner_common.ps1:581-585`), never `git gc --prune=now` by janitor. |
| **Windows / Downloads / Claude temp / Board** | **73.9** | `pagefile.sys` 25.1 (needs to GROW), `voidsworn_sfx` 13.9, Claude temp 12.3, Board 8.9 | Keep (raise pagefile!) | Do NOT shrink `pagefile.sys` (already causing OOMs). |

**Math to 400+ GB free:** Starting from `165.6 GB`, reclaiming (1) sandbox-owned kept checkouts + TEMP scratch (`+150 to 200 GB`), (2) finished `.t3` thread worktrees (`+70 to 90 GB`), and (3) `look_bench` + relayed `opus*` job folders (`+140 GB`) adds **360 to 430 GB**, putting C: at **525 to 595 GB free** even after giving `pagefile.sys` an extra 40-60 GB!

### 2. Seven Root Causes Observed in `tools/pc/` (Why Janitor Only Freed 0.6 GB)

1. **Codex sandbox SID ownership poisons both `TEMP` scratch and `repo-kept-*` checkouts (`OBSERVED`):**
   - `tools/pc/codex_issue.bat:134-136,154` sets `TEMP`, `TMP`, `TMPDIR` to `%PC_RUN_SCRATCH%` before launching `codex.cmd exec`. Everything the Codex Windows sandbox writes into `TEMP` or the checkout is owned by the Codex sandbox account SID.
   - `tools/pc/disk_space.ps1:98-103` (`Test-OtherAccountFolder`) flags any folder whose owner SID is not in `Get-CurrentAccountIds` (`runner_common.ps1:777-783`).
   - `Complete-RunScratch` (`runner_common.ps1:695-699,722`) and `Clear-KeptCheckout` (`runner_common.ps1:961`, calling `Measure-CleanupDirectory $copy -Checkout` **without** `-AllowUnreadable`) throw on the FIRST sandbox-owned folder and abort deleting the entire checkout/scratch folder!
   - `janitor.ps1:45` installs the scheduled task at `-RunLevel Limited`, so janitor can neither `takeown` nor reset ACLs, and `Remove-CleanupReadable` (`runner_common.ps1:809-831`) preserves every sandbox folder and its entire parent chain (2,091 folders stuck today).
   - `tools/pc/pysite/sitecustomize.py` (which inherits ACLs on Python `tempfile` dirs) is injected only by `ship_job.bat` and `look_bench.bat`, NOT by `codex_issue.bat` or `work_issue.bat`.
2. **`Test-RelayedResults` in `janitor.ps1` contradicts `relay_push.ps1` and `opus_job_head.ps1` (`OBSERVED`):**
   - `relay_push.ps1:178,192` skips `profile`/`shader_cache`/`.godot` (`relay_manifest/skipped_cache_folders.txt`) and files `> 10 MB` (`relay_manifest/skipped_over_10MB.txt`).
   - `opus_job_head.ps1:511-549` reads BOTH manifest files when verifying relay completeness.
   - `janitor.ps1:313-327` ignores BOTH manifests! Any job whose `out*` contains a `>10 MB` `.avi`/`.mp4`/`.png`/`.glb` or an in-`out*` `profile`/`shader_cache`/`.godot` folder permanently fails `"results not all relayed"` and stays on disk forever.
3. **GPU jobs do not relay-then-trim at job end, and `OJ_SLOTS=1` is opt-in (`OBSERVED`):**
   - `opus_job_head.bat:74` disables after-job janitor by default (`if not "%OPUS_JOB_JANITOR%"=="1" set "JW_NO_JANITOR=1"`).
   - `opus_job_head.bat:183-209` calls `dropcheckouts` immediately at `:oj_tail`, which always fails because the job itself never called `relay_push.bat`, then spawns a hidden `dropwait` loop polling every 5 min for up to 12 hours waiting for someone else to push the relay.
   - `opus_job_head.bat:112` only uses warm reusable slots when `OJ_SLOTS=1` is set per `.bat`; otherwise each job creates a fresh ~10 GB checkout+assets copy kept for at least 6-24 h. Even with warm slots, `opus_job_head.ps1:1109` (`git clean -q -ffdx -e /godot/.godot/ -e '*.import'`) wipes `godot/gen` and `godot/assets/ships` and robocopies them fresh every run.
   - When janitor does run (`janitor.ps1:724,803-808`), ANY non-empty shared GPU slot defers the ENTIRE job-folder cleanup pass, and `--after-job` and `--low-space` share a 1-hour lockout (`janitor.ps1:145`). Also `janitor.ps1:46` registers the task without explicit idle-disable / battery-allow flags (`LOOP.md:87`: `"janitor task refused (idle condition)"`).
4. **`look_bench` (59.3 GB) and `player_path` videos are invisible to janitor and never relay (`OBSERVED`):**
   - `janitor.ps1:445-446,796-798` only scans `opus<N>*` and `pt<MMDD>*`; `look_bench` and `shots\player_path_*` are skipped completely.
   - `tools/pc/jobs/look_bench.bat:7-8,147-160` explicitly keeps every commit's uncompressed PNGs and bench checkout forever (`"Nothing on the PC is deleted"`) and never calls `relay_push.bat`; `runner_common.ps1:1150` also leaves `*-kept-<guid>` renames behind.
   - `contrib/codex/player_path_1119/run.ps1:10,49,64` records raw uncompressed 1080p 30 fps `--write-movie seed-N.avi` files (multi-GB each, >10 MB -> never relayed -> never cleaned).
5. **Kept-checkout retention and `finish` leaks (`OBSERVED`):**
   - `runner_common.ps1:2248-2256` (`finish`) only calls `Remove-OlderKeptRepos` when `$status -eq 'checked_push'` (skipping `unverified`, `partial`, `failed`!) AND only for `board(_[b-f])?` (never `work217\slot_*`).
   - `runner_common.ps1:1013` always keeps the newest `repo-kept-*` on EVERY lane (up to 13 kept checkouts across 6 Codex lanes + 7 Workhorse slots!).
   - `runner_common.ps1:365` (PR `#2127`) preserves any checkout containing flat `manifest.json.bak_*` forever in removal mode (`$forRemoval = $true`).
6. **Dead cleanup markers and unpruned tool snapshots (`OBSERVED`):**
   - `tools/pc/jobs/ship_job.bat:127` writes `out_before_for_janitor.txt`, which ZERO scripts in `tools/pc/` ever read.
   - `tools/pc/lane_tools_refresh.ps1:352-358` leaves every `export-*.zip` and every historical `<40-hex>` folder in `lane_tools_source\` forever.
7. **The "28 GB" hard-link reporting illusion and double Win32 scan slowness (`OBSERVED`):**
   - `git clone --local` hardlinks `.git/objects/pack/*` (~16-22 GB) from `repo-mirror.git`. Windows Explorer and `Warn-KeptRepos` (`runner_common.ps1:248-255`, which sums raw `$item.Length` instead of calling `disk_space.ps1`) report ~28 GB per checkout even when unique bytes are 2-10 GB.
   - Meanwhile, `Clear-KeptCheckout` calls `Measure-CleanupDirectory` TWICE (`runner_common.ps1:961,994`), running Win32 `CreateFileW` on every file and pushing janitor toward its 2700 s cap (`janitor.ps1:732`).

### 3. Concrete Tool and Workflow Fixes (No New Rules)

| # | Target Tool / Workflow | Concrete Change | Estimated Space / Impact |
|---:|---|---|---|
| S1 | **Codex sandbox ownership** (`codex_issue.bat`, `runner_common.ps1`, new `tools/pc/reclaim_sandbox.bat`) | (a) Give Ryan one double-click elevated `reclaim_sandbox.bat` (`takeown /F ... /R /D Y` + `icacls ... /grant %USERNAME%:F /T` + delete) for existing `TEMP\voidsworn-run-*` and `repo-kept-*` folders. (b) In `codex_issue.bat`, do NOT point Codex sandbox `TEMP` at host `PC_RUN_SCRATCH`; run an in-sandbox post-step (`cmd /c rd /s /q` inside the sandbox) or clean repo scratch before exiting sandbox, and inherit `PYTHONPATH=tools\pc\pysite` on Codex/Workhorse lanes too. (c) In `runner_common.ps1:961` (`Clear-KeptCheckout`), measure/delete readable files first (`-AllowUnreadable` + `Remove-CleanupReadable`) instead of aborting the whole 10-20 GB checkout on one sandbox folder, and log only the remaining unreadable list. | **150-200 GB immediate** + prevents recurrence permanently |
| S2 | **Auto-relay-then-trim at GPU job end** (`opus_job_head.bat`, `opus_job_head.ps1`) | At `:oj_tail` (after job finishes), automatically run `relay_push.bat <job_dir>` when `OJ_AUTO_RELAY` is enabled (default `1`), verify the push, and immediately drop the job's `repo`/`work` checkout on the spot instead of leaving 10 GB for 12-24 h waiting on `dropwait`. Make `OJ_SLOTS=1` the default in `opus_job_head.bat` and preserve hash-verified `godot/gen` + `godot/assets/ships` across slot resets instead of wiping and re-copying. | **Eliminates ~10 GB/job buildup** (keeps active GPU working set under ~25 GB total) |
| S3 | **Fix `janitor.ps1` relay check & Task Scheduler idle bug** (`tools/pc/janitor.ps1`) | (a) Copy `opus_job_head.ps1:511-549`'s handling of `skipped_over_10MB.txt` and `skipped_cache_folders.txt` into `janitor.ps1:313-327` (`Test-RelayedResults`). (b) Allow deleting already-relayed job folders (`mtime > 6 h`) even while a shared GPU slot is busy (only pause on `solo` timing claims). (c) Pass `-AllowStartIfOnBatteries -DontStopIfGoingOnBatteries` and explicitly set `$settings.IdleSettings.StopOnIdleEnd = $false; $settings.RunOnlyIfIdle = $false` in `Install-JanitorTask`. (d) Fix `Warn-KeptRepos` (`runner_common.ps1:248-255`) to use `disk_space.ps1` unique-bytes and remove the duplicate `Measure-CleanupDirectory` call at `runner_common.ps1:994`. | **~80 GB from trapped `opus*` folders** + janitor stops stalling/refusing |
| S4 | **`look_bench` relay & prune** (`look_bench.bat`, `janitor.ps1`) | Make `look_bench.bat` call `relay_push.bat` on `look_bench\runs\<commit>` at run end, store bench contacts as JPEG (q=88) or PNG-8 instead of full-res uncompressed PNG strips (60-80% smaller), and add `look_bench\runs\*` (once relayed) + `look_bench\*-kept-*` to `janitor.ps1` (keep newest 2 runs max). | **~50-55 GB immediate** + caps `look_bench` under 8 GB |
| S5 | **T3 Code worktree pruner** (new `tools/pc/prune_t3_worktrees.bat`) | Double-click `.bat` (run with T3 closed) that runs `git -C t3_neon worktree list --porcelain`, checks which `C:\Users\rcbai\.t3\worktrees\t3_neon\*` branches are already pushed to `origin` or merged into `origin/main` with a clean working tree, and removes them via `git worktree remove` + `git worktree prune`. | **~70-85 GB immediate** (out of 89.9 GB `.t3`) |
| S6 | **Zero-kept-on-clean-push & `work217` / snapshot cleanup** (`runner_common.ps1`, `lane_tools_refresh.ps1`, `ship_job.bat`) | In `runner_common.ps1:2248-2256`, call `Remove-OlderKeptRepos` on `unverified`/`partial`/`failed` too (when the branch was pushed or superseded) AND include `work217\slot_*`; drop `KeepNewest = 1` to `0` once `checked_push` is verified. In `lane_tools_refresh.ps1:352-358`, delete `export-*.zip` after extraction and keep only the newest 2 `<40-hex>` snapshots. Wire `out_before_for_janitor.txt` in `janitor.ps1` (or stop writing it). | **~30-50 GB steady-state reduction** |
| S7 | **Smaller capture output + per-job disk budget** (`run.ps1`, `job_wrap.bat`) | In `contrib/codex/player_path_1119/run.ps1`, transcode `--write-movie seed-N.avi` to H.264 MP4 (CRF 24, <10 MB so it relays cleanly!) and immediately delete the multi-GB `.avi`. In `job_wrap.bat`, check free space (`< 150 GB` triggers `--low-space` before launch) and enforce a per-job output cap (warn/abort if a single job writes >5 GB unique bytes outside warm slots). | **Prevents single runs from burning 10-20 GB** |

---

## Separate Section: Performance Audit (Game & PC Pipeline)

### A. Game Performance (Ranked Biggest Wins)

1. **Win #1 (Near-Free, Ready Now): Merge `#1852` (`codex/issue-1843`) to kill the 150-190 ms Round-2 Pipeline Hitch (`OBSERVED`):**
   - `#1852` is already CI green and mergeable; it warms the unshaded additive firing-arc `StandardMaterial3D` under load cover. Only a stale `[HOLD: contains an old 1445 head]` title and pre-LOAD38 control pin (`3131184b`) hold it back. One quick solo A/B on post-`#2099` `main` unlocks an immediate in-battle stutter fix.
2. **Win #2 (High Impact, Active): Fix Wounds V2 Frame-Time p99 (`#2125` / PR `#2135`) & Stage Rebuild Stalls (`OBSERVED`):**
   - `DEFAULT_B` missed RULEBOOK 3.9 (`<= 12.5 ms` p99) with V2 on: stage 3 p99 `19.49 ms` (off `10.27`), stage 4 p99 `14.55 ms` (off `7.18`), plus `115.5 s` and `218.3 s` stage rebuild waits in `fleet.json`.
   - `PROOF_A` (`f2281b5a`) failed to produce candidate timing at all because `DAMAGE_PROFILE` aborted on the before arm (`ERROR: DAMAGE_PROFILE requires the real Wounds V2 interior and mouth passes`), and run 2 introduced Artoo's unguarded live-Chorus interior override (`wound_v2 == 3`).
   - **Biggest levers:** (a) keep `#1997`'s pre-cut wreck shader split (skipping the mouth cut/discard loop on pre-cut wrecks) alongside `#2135`'s loop optimization and `#2109`'s `_regrade_marks()` batching; (b) gate `DAMAGE_PROFILE` strictly on V2-on arms and separate stills from solo timing so we get clean p99 numbers; (c) cap or simplify dense hull mesh geometry where rebuilds took 100-218 s (`LOOP.md:91`).
3. **Win #3 (High Impact, Active): Land Title Loading under 500 ms (`#2134` LOAD39 + `#1519` Battle-to-Title) (`OBSERVED`):**
   - Merged `#2099` (LOAD38) already cut title worst frame from `1890 / 1379 ms` (`main`) down to `502 / 454 ms` (cold/warm), just 2 ms over 500 ms. The dominant remaining spike is CPU `"ships"` (`326 ms` cold / `269 ms` warm), specifically `effects work add:analyse 257 ms` (`fx_hull.gd:567-605,713-752`, synchronous `TriangleMesh` BVH build on main thread).
   - **Safe fix for `#2134`:** Snapshot plain vertex/transform arrays on the main thread, run BVH build on `WorkerThreadPool`, publish into `_hull_geometry` on main thread only if generation still matches, and cancel/drop (never synchronously block-join) in `drain_build()` on exit.
   - **Battle-to-title (`#1519`, currently running on `opus` arm):** Closes the `551-591 ms` battle-to-title frame by porting sliced battle retirement + stale-gen guards onto `#2099` `main`.
4. **Win #4 (High Impact, Blocked on Rebase): Rebase & Land `#1960` (`#1780`) + `#2106` (`#2103`) VRAM & Shader Stutter Pack (`OBSERVED`):**
   - `#1960` caches 48 `Shader.new()` allocations, adds BC7 world VRAM compression, FSR 2.2 AA option, and empty volumetric fog gating. Rebase onto `#2054`/`#2099`, unify the 4-arg vs 5-arg R01 relief contract with `#2106`, fix `performance_1780.gd:193-219`'s weak belt-fog assertion, and extend `shader_pow_2092.js:79` to scan `.gdshaderinc` includes.

### B. PC Pipeline Performance (Ranked Biggest Wins)

1. **Win #1 (Unblocks Ships + Stops Lane Crashes): Fix the 57 GB Windows Commit Ceiling for TRELLIS & 6-Lane Runs (`OBSERVED`):**
   - **Root cause:** PC logs on `#2143` prove `H7N`, `H8`, `S9A`, and `H7P` failed TRELLIS stage 2 with CUDA OOM + host `MemoryError` while `11-15.7 GB VRAM` was free (`H7P` ran solo on a quiet PC with `1.2 GB` VRAM used!), and `#2142` Lane D crashed PowerShell pipeline creation while `codex.exe` kept running. The culprit is the fixed `25.1 GB` `pagefile.sys` + 32 GB RAM (~57 GB commit ceiling) colliding with `tools/pc/trellis_fleet.py:41,58-66` (`1536_cascade` + `mesh.attrs.float()` FP32 volume + `o_voxel.postprocess.to_glb(decimation_target=600000, texture_size=2048, remesh=True)`) while `2_shape_ref.bat:21-22` only claims `PC_GPU_MODE=shared`, `PC_GPU_WEIGHT=2`.
   - **Fixes:**
     1. Raise Windows `pagefile.sys` to system-managed (or 64-96 GB) after reclaiming C: space (Ryan one-time setting).
     2. In `tools/recipe/2_shape_ref.bat:21-22`, switch to `PC_GPU_MODE=solo` and add a commit-headroom preflight (`GlobalMemoryStatusEx` requiring >=24 GB free commit before starting).
     3. In `tools/pc/trellis_fleet.py:58-66`, start at `1024_cascade` unless commit headroom is >=35 GB, keep `mesh.attrs` in `float16`/`bfloat16` where supported, and explicitly `del pipe; torch.cuda.empty_cache(); gc.collect()` BEFORE CPU `to_glb(remesh=True)` so model weights and remesh buffers do not overlap in RAM/commit!
2. **Win #2 (50-65% Faster CI + Zero Wasted `xhigh` Runs): Parallelize Godot CI Shards & Fix Error Truncation (`OBSERVED`):**
   - **Root cause (`godot/tools/ci/run_checks.sh:83-117` + `contrib/codex/issue-2078/NOTES.md` run 3):** Each of the 3 GitHub Actions shards runs ~55 headless checks **serially**, spawning a fresh Godot process per test (~3.6 s startup + sound bank load x 55 = ~200 s pure startup overhead per shard) on a 4-vCPU `ubuntu-latest` runner while 3 cores sit idle. On a noisy runner (`#2078` run 3, shard 3), 4-7x slowdown (`load_all` 88 s, `volley_voice_check` 68 s, `map_trial_test` 53 s) burned the shared 600 s `GODOT_CHECKS_BUDGET` (`checks.yml:264`), starving `hit_timing_check` to 34 s and cascade-failing the rest. Worse, `run_checks.sh:114` (`grep -E 'SCRIPT ERROR|FAIL|ERROR' ... | head -8`) printed 8 of 24 benign `ERROR: placeholder hull:` lines on `plan_commit_check`, hiding the real failure and wasting an entire `xhigh` Codex run!
   - **Fixes:**
     1. Run 2-3 checks concurrently per shard via `xargs -P 2` (or `-P 3`) with isolated `$T/xdg/$name` and `$T/out/$name.log` (cuts shard wall time ~50-65% with zero extra runners).
     2. In `run_checks.sh:114`, filter out `placeholder hull:` (or print `FAIL`/`SCRIPT ERROR` lines first, then `ERROR`, plus the last 10 lines of the log on non-zero exit).
     3. Refresh `godot/tools/ci/godot_check_times.txt` (new checks default to 10 s, skewing shard balance) and raise `GODOT_CHECKS_BUDGET` to 900 s inside the 25-min job timeout.
3. **Win #3 (Less Lane Idling & Fewer Local Flakes): Break Mirror Lock Contention & Trim Redundant Local Full Suites (`OBSERVED`):**
   - **Mirror lock (`runner_common.ps1:579-587`, `janitor.ps1:388,742`):** Main, B, C, D, all 7 Workhorse slots, `ship_job.bat`, `helper_clone.ps1`, `opus_job_head.ps1`, and `janitor.ps1` all serialize on ONE `repo-mirror.git.lock`, and janitor holds that lock across multi-minute directory deletions! Fix: never hold `repo-mirror.git.lock` while deleting directories (only during `git fetch`/pack updates).
   - **Workhorse tools refresh (`lane_tools_refresh.ps1:304`):** Locks ALL 14 Workhorse slot locks at once, refusing whenever any single API arm (`opus`, `sonnet`, `deepseek`) is running. Fix: switch `work217` to the versioned immutable `tools_live\<hash>` pointer model (atomic pointer swap, zero global lock) instead of mutating shared tools in place.
   - **Local full checks (`codex_issue.bat:283`, `work_issue.bat:429`):** Every lane runs the full `run_all_checks.js` (up to 3600-5400 s) + `parity.bat` locally across 6 concurrent lanes, triggering CPU/memory contention and 4-5 recurring Windows harness/cert-store/timeout flakes (`godot_shard_tests`, `pc_jobs_1194_tests`, `runner_selftest`, `pc_daemon_selftest`, `lane_tools_refresh_selftest`) even though GitHub CI is the merge gate. Fix: run fast targeted checks locally (em-dash + changed-area tests + `check_rules` if `godot/rules` touched) and let GitHub CI run the full suite (plus fix the `lane_tools_refresh_selftest.js:128` race).

---

## Quick-Reference Tables

### A. Status of Issue `#2107` Findings (09:00 UTC -> 14:00 UTC)

| #2107 Rank | Topic | Status at 14:00 UTC | Evidence |
|---:|---|---|---|
| 1 | `runner_selftest.js:1396` regression (PR `#2113`) | **FIXED** | PR `#2131` merged; verified `runner_selftest.js:1397` on `main`. |
| 2 | Eclipse `legionRise()` `splashKill` leak (PR `#2123`) | **FIXED** | PR `#2141` merged (12:57 UTC); `#2095` closed; `#2105` re-combined (`0f9a3bae`) & green. |
| 3 | PR `#2127` destructive `manifest.json.bak_*` janitor regex | **FIXED** | PR `#2127` merged (11:36 UTC) with `if (-not $forRemoval ...)` guard at `runner_common.ps1:365`. |
| 4 | FX pileup & sprite/style ID collisions | **WORSENED (CONFIRMED)** | Exact collisions delivered across `#2133`/`#2132`/`#2084`/`#2069`, `#2136`/`#1755`, `#2049`/`#2021`; `#2021` RED/conflicting on `#1904`; `#2142` crashed & contradicts `acid_thorn_check.gd`. |
| 5 | PR `#2007` RED + `#2001`/`#1725` RED | **STILL OPEN** | `#2007` still RED (`lane_tools_refresh_selftest.js:128` race) & conflicting; `#2017` conflicting; `#1725` RED (`585` behind `main`). |
| 6 | Sonnet `#2029` bottleneck & 5-way binary-save pileup | **PARTIAL** | `#2102` (`#2029`) merged; `#2105` green; `#2119`, `#2121`, `#2020`, `#2122` still open (`#2119`/`#2121` conflicting). |
| 7 | PR `#2119` (SY-A Gantry) RED + flagship blocker | **STILL OPEN** | Still RED (`audio_check: FAIL`) and `77` behind `main`. |
| 8 | 9-PR Loading cluster | **PARTIAL** | `#2099`, `#2053`, `#2054` merged; `#2089`/`#2064`/`#2111`/`#2112`/`#1950` closed; `#1960` & `#2106` still conflict with `main` & each other; `#2085`/`#2027`/`#2023` still open. |
| 9 | PR `#2071` sound mix RED & `#2052` Brisk cue | **PARTIAL** | `#2052` run 5 fixed & green; `#2071` CI green now, but Artoo's `last[name] = t` cooldown bug explicitly unfixed and still overlaps `#2052`. |
| 10 | Unresolved Artoo bugs on green PRs | **STILL OPEN + NEW** | Existing items on `#2049`, `#1980`, `#1763`, `#2128`, `#2104`, `#2122`, `#1852` remain; new Artoo bugs on `#2140` (`battle.gd:5948-5952`) and `#2135` (Chorus live interior). |
| 11 | `Repo-Mirror` doc vs code drift (`runner_common.ps1:579`) | **STILL OPEN** | Only `board_e`/`board_f` isolated; contradicts `LOOP.md:49` and `HANDOFF.md:14-17`. |
| 12 | Windows local `run_all_checks.js` flakes (4-5 checks) | **STILL OPEN** | Recurring across `#2078`, `#2022`, `#2047`, `#2043`, `#2046`, `#1991`, `#1974`, `#2039`, `#1843`. |
| 13 | `LOOP.md` bloat & R449 drift | **WORSENED** | Grew from 84 to 89 LATEST lines (`84-172`); `PROGRAM.md:77-80` also contradicts R449 & Nov 17 Muse. |
| 14 | `PC` / `GPU` / `Trellis` backlog bottlenecks | **STILL OPEN** | Root-caused today to 57 GB Windows commit ceiling (`#2143` PC notes). |
| 15 | R288 open-after-merge issues & superseded PRs | **WORSENED** | 4 new merged issues left open (`#1877`, `#2085`, `#2027`, `#2023`) on top of `#1887`, `#1572`, `#1328`, `#1779`, `#1943` & 5 superseded PRs. |
| 16 | Stale `running` labels | **IMPROVED** | `#2103` & `#2035` cleared; `#2094` (run 2 started 13:31 UTC) and `#2143` are legitimately active. |
| 17 | `#2093` & API arm utilization | **IMPROVED** | `#2093` merged; `opus` arm delivered `#2140` (`#1403`) and is running `#1519`. |

### B. Audit of All 11 PRs Merged Since Nov 25 09:00 UTC

| PR | Issue | Merged (UTC) | Summary | Follow-up / Fallout Observed |
|---:|---:|---|---|---|
| `#2093` | `#2092` | 09:10 | Shader `pow()` negative-base audit + guard | Clean; note `shader_pow_2092.js:79` does not yet scan `.gdshaderinc` includes. |
| `#2099` | `#2085` | 09:20 | LOAD38 title analyse cache + debris warm | Clean (cut title to 502/454 ms); issue `#2085` still open (R288) and `#1960`/`#2106` now conflict. |
| `#2053` | `#2027` | 09:20 | LOAD37 material warm + exit hang | Clean; issue `#2027` still open (R288). |
| `#2054` | `#2023` | 09:21 | R01 relief RF+RG8 + single rocky sample | Clean; issue `#2023` still open (R288); `#1960` & `#2106` must align on its new R01 contract. |
| `#2130` | `#2107` | 09:42 | Neon 09:00 audit report | Clean. |
| `#2131` | `#2113` | 09:45 | Fix `runner_selftest.js:1397` regression | Clean; verified on `main`. |
| `#2102` | `#2029` | 09:57 | Sonnet UI polish (`#2029`) | Clean; unblocked UI queue. |
| `#2138` | `#2114` | 11:02 | Small fix / housekeeping | Clean. |
| `#2127` | `#2116` | 11:36 | Janitor `manifest.json.bak_*` + CRLF test fix | Fixed `#2107` #3 destructive regex; note flat `manifest.json.bak_*` still keeps checkouts forever in removal mode (`runner_common.ps1:365`). |
| `#2141` | `#2095` | 12:57 | Eclipse `legionRise()` `splashKill` fix | Clean; closed `#2095` and unblocked `#2105`. |
| `#1904` | `#1877` | 13:33 | Acid Thorns visuals (replaces tendril lash) | Broke/conflicted `#2021` (`fx_shaders.gd`); `tables.json` still says `"Boarding tendrils"` and `#1877` lacks a rename/sound follow-up ticket before closing. |

### C. Conflicting or Failing Open PRs Snapshot (Nov 25 ~14:00 UTC)

| PR | Branch | Checks | Mergeable | Blocking Issue |
|---:|---|---|---|---|
| `#2021` | `codex/issue-1693` | **FAIL** | Conflicting | Conflicts with `#1904` (`fx_shaders.gd`); bio-spark mismatch with `#2049`. |
| `#2007` | `codex/issue-1991` | **FAIL** | Conflicting | `Standing checks` fail on `lane_tools_refresh_selftest.js:128` race. |
| `#2119` | `codex/issue-2038` | **FAIL** | Conflicting | `audio_check: FAIL`; 77 behind `main`; blocks flagship decommission. |
| `#1725` | `opus/issue-1412` | **FAIL** | Behind (585) | `Godot game checks 1 & 3` fail; H7N/H8 failed TRELLIS commit OOM. |
| `#2121` | `codex/issue-2035` | PASS | Conflicting | Stacked on `#2105`/`#2119` binary-save UI train. |
| `#2128` | `codex/issue-2032` | PASS | Conflicting | Conflicts with `main`; needs rebase after UI train. |
| `#2132` | `codex/issue-2046` | PASS | Conflicting | Conflicts with `main`; sprite IDs `30/31` collide with `#2133`/`#2084`. |
| `#1960` | `codex/issue-1780` | PASS | Conflicting | Conflicts with `#2054`/`#2099` and `#2106` R01 relief contract. |
| `#2106` | `neon/issue-2103` | PASS | Conflicting | Conflicts with `#2054`/`#2099` and `#1960` R01 relief contract. |
| `#2017` | `codex/issue-2001` | PASS | Conflicting | 84 behind `main`; `MM_TRIAL4` showed `terran_c26` band 2 miss. |

### D. File Read Receipts (`docs/REVIEW_PROTOCOL.md` Section 1)

| File | Total Lines | First 40 Chars of Last Line | Ranges Read (if >1,500 lines) |
|---|---:|---|---|
| `docs/REVIEW_PROTOCOL.md` | 35 | `- Claude checks every claim against the ` | Full |
| `docs/RULEBOOK.md` | 735 | `draws meshes at full detail. Set: Ryan, ` | 200-735 |
| `.claude/rules/pc-harness.md` | 50 | `3.7 **Clone on the PC with \`git -c core.` | Full |
| `HANDOFF.md` | 32 | `builds 868, 869). Effects round 3 (815),` | Full |
| `contrib/opus/LOOP.md` | 232 | `Check ship files are unchanged first (gi` | 1-172 + tail check |
| `docs/playbooks/PROGRAM.md` | 227 | `   flares. 9. The sound listening page. ` | Full |
| `contrib/neon/reviews/board_audit_1125_0900.md` | 136 | `- Full line-by-line diffs of every older` | Full |
| `tools/pc/janitor.ps1` | 837 | `exit 0` | Full |
| `tools/pc/janitor_task.bat` | 7 | `exit /b %JANITOR_TASK_EXIT%` | Full |
| `tools/pc/janitor_salvage.ps1` | 212 | `}` | Full |
| `tools/pc/disk_space.ps1` | 162 | `}` | Full |
| `tools/pc/relay_push.ps1` | 341 | `if ($pics.Count -eq 30) { Write-Output '` | Full |
| `tools/pc/scratch_done.ps1` | 75 | `exit 0` | Full |
| `tools/pc/helper_clone.ps1` | 250 | `}` | Full |
| `tools/pc/lane_tools_refresh.ps1` | 437 | `}` | Full |
| `tools/pc/lane_tools_refresh_selftest.js` | 202 | `console.log('PASS: lane tools refresh ke` | 100-202 |
| `tools/pc/runner_common.ps1` | 2278 | `exit 0` | 1-2278 (full in chunks) |
| `tools/pc/runner_selftest.js` | 1585 | `} })();` | 1380-1420 |
| `tools/pc/run_timeout.ps1` | 926 | `}` | 1-778 |
| `tools/pc/codex_issue.bat` | 291 | `endlocal & set "NODE_EXIT=%NODE_EXIT%" &` | Full |
| `tools/pc/codex_issue.ps1` | 162 | `} else { Write-Host 'usage: codex_issue.` | Full |
| `tools/pc/work_issue.bat` | 516 | `exit /b %RC%` | Full |
| `tools/pc/work_issue.ps1` | 898 | `else { Write-Host 'usage: work_issue.ps1` | 1-692 |
| `tools/pc/job_wrap.bat` | 235 | `exit /b 0` | Full |
| `tools/pc/watcher.bat` | 68 | `goto loop` | Full |
| `tools/pc/pysite/sitecustomize.py` | 75 | `    tempfile._voidsworn_inherited_acl = ` | Full |
| `tools/pc/jobs/look_bench.bat` | 199 | `exit /b %ERRORLEVEL%` | Full |
| `tools/pc/jobs/look_bench_sheets.py` | 317 | `    sys.exit(main())` | Full |
| `tools/pc/jobs/opus_job_head.bat` | 210 | `exit /b %OJ_RC%` | Full |
| `tools/pc/jobs/opus_job_head.ps1` | 1659 | `}` | 1-1388 |
| `tools/pc/jobs/opus_job_template.bat` | 51 | `exit /b 0` | Full |
| `tools/pc/jobs/ship_job.bat` | 369 | `exit /b 0` | Full |
| `tools/pc/jobs/player_path.bat` | 12 | `exit /b %RESULT%` | Full |
| `contrib/codex/player_path_1119/run.ps1` | 105 | `Write-Host "Review clips and sheets: $Re` | 1-80 |
| `tools/pc/trellis_fleet.py` | 72 | `log('TRELLIS BAKEOFF DONE')` | Full |
| `tools/recipe/2_shape_ref.bat` | 36 | `exit /b 1` | Full |
| `.github/workflows/checks.yml` | 356 | `          echo "PASS" \| tee -a "$GITHUB_` | Full |
| `godot/tools/ci/run_checks.sh` | 119 | `if [ $F -eq 0 ]; then echo "PASS: every ` | Full |
| `godot/tools/ci/godot_check_times.txt` | 208 | `wreck_hex_check 27` | Full |
| `godot/fx/fx_hull.gd` | 2057 | `				(lb["node"] as Node3D).transform = (` | 555-605, 710-760 |
| `godot/render/ship_view.gd` | 2315 | `		ring.rotation.y = -rotation.y` | 115-160 |

---

## Recommended Next Step

1. **Immediate (Ryan PC, 1 double-click session):** Run an elevated cleanup `.bat` for the 2,091 sandbox-owned folders + closed `.t3` worktrees (~230-290 GB reclaimed) and switch Windows `pagefile.sys` from fixed 25 GB to system-managed (or 64-96 GB) so TRELLIS and 6-lane Codex runs stop OOMing.
2. **Board next dispatch (1 PC-tools Codex job + 1 CI-speed PR):** Land storage fixes S1-S4 + S6 (`janitor.ps1` relay manifest fix, `Clear-KeptCheckout` readable-first, `opus_job_head.bat` auto-relay-then-trim + `OJ_SLOTS=1` default, `look_bench` relay/prune, `lane_tools_refresh_selftest.js:128` race) and CI speed fixes (`run_checks.sh` `-P 2`/`-P 3` parallel shards + `placeholder hull:` filter).
3. **Board merge train (zero GPU wait):** Merge `#2105`, `#2052`, and (after one solo A/B) `#1852`; fix `#2119` (`audio_check`), `#2140` (occupied relay hover), `#2071` (`last[name] = t`), and `#1980` (`dmg > 0`); serialize FX merges behind an explicit sprite/wound ID table; close the 9+ R288 merged issues and 5 superseded PRs.

---

## Not checked:

- The ~740 GB on C: outside the folders scanned by the PC disk space map (Program Files, Windows OS, other AppData/user directories).
- Direct live inspection of Windows Task Scheduler XML or Windows Event Viewer on Ryan's PC (the idle-condition refusal and 57 GB commit-limit notes come from `LOOP.md:87` and the PC comment posted on `#2143`).
- Rendered visual screenshots, audio playback, or the installed Windows game build.
- Full line-by-line diffs of every older open PR outside the 30 active/conflicting/FX/UI/perf PRs inspected in detail, or the unpushed worktree of `codex/issue-2142-partial` (which had not opened a PR at snapshot time).
- Exact byte sizes of individual files inside the private `voidsworn-relay` repository.
