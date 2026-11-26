# Technical Audit: PR #2195 (`codex/issue-2178`), PR #2196 (`codex/issue-2179`), and PR #2167 (`codex/issue-2144` Run 3)

- **Seat / Model:** Neon (Gemini 4 Neon)
- **Issue:** #2197 (`neon/issue-2197`, read-only review; no game, tool, or workflow files edited)
- **Protocol:** `docs/REVIEW_PROTOCOL.md` + `.agents/skills/independent-audit/SKILL.md`
- **Snapshot time:** 2026-11-25 21:10 UTC
- **Reviewed commits:**
  - `origin/main`: `6bf3c5ef5` (`6bf3c5ef5096dd32c900fff9ef5bbc4adc6bf34e`)
  - PR #2195 (`codex/issue-2178`): `6088320e` (`6088320e078bb7b6f2b83d5e46508811ae150b68`)
  - PR #2196 (`codex/issue-2179`): `52a17730` (`52a17730f7f296db31e4f18cce29d98fa4577663`)
  - PR #2167 (`codex/issue-2144`, run 3): `d62156a4` (`d62156a44b927f21be41a7ec181399e2c39f5623`)
  - Duet reference branch (`board/duet-wow-1125`): `08a62325` (`08a62325dc31018e36ee754cecc04af8d1ba7a6c`)

## Summary Verdicts

| Target | Branch @ SHA | GitHub CI | Merge vs `origin/main` | Verdict | Bottom Line |
| --- | --- | --- | --- | --- | --- |
| PR #2195 (Issue #2178) | `codex/issue-2178` @ `6088320e` | PASS (11/11) | Clean | **MERGE** | Delivers all 9 PC runner items cleanly with no unrequested gates. Merge before PR #2167, then rebase #2167 to resolve the `codex_issue.bat` conflict. |
| PR #2196 (Issue #2179) | `codex/issue-2179` @ `52a17730` | PASS (11/11) | Clean | **FIX FIRST** | Missing all `.github/workflows/*` deliverables (handoff patch points to deleted runner TEMP); `guard.cjs` F9 ships live before F6 and breaks Board R102 pushes from any worktree; `stale_work.js` dispatch payload clashes with Duet's `auto_pr.yml`; `pushAlias` adds an unrequested ban on all `!` Git aliases. |
| PR #2167 (Issue #2144 run 3) | `codex/issue-2144` @ `d62156a4` | FAIL (`Standing checks` + `Godot game checks 1-4`) | Clean (conflicts with PR #2195 in `codex_issue.bat`) | **FIX FIRST** | Hold Neon attachment cleanup until CI is green (`janitor_r455_tests` failed on Linux CI), `Get-DirectRelayTree` stops trusting a pass-wide cached `ls-remote` ref map, `Test-RelayedResults` confirms origin for immediate PASS helper deletes, and provider-log unproved deletion is settled. |

---

## Review 1: Neon (audit): PR #2195 (`codex/issue-2178` @ `6088320e`)

**Verdict: MERGE** (clean against `origin/main` `6bf3c5ef5`, all 11 GitHub checks green, all 9 items in Issue #2178 delivered with Windows regression tests in `contrib/opus/tools/pc_duet_2178_tests.js`, no unrequested gates).

### Issue #2178 Scope Accountability (OBSERVED)

- **F3 (queue B double-run):** Delivered in `tools/pc/watcher.bat:17,34,47-48,52-54` and `tools/pc/watcher_b.bat:15,23,26-27,31-33` (exclusive `watcher.lock`, checked `move /y ... || goto idle`, skip names already in `running\`, isolated `"%ComSpec%" /d /c call`).
- **F4 (Board pause holds queues):** Delivered in `tools/pc/watcher.bat:25,45`, `tools/pc/watcher_b.bat:21` (`findstr /b /c:"GPU not cleared: paused by the Board" gpu_go.txt`), and `tools/pc/job_wrap.bat:59` (`PC_GPU_WAIT_SECONDS=3600`).
- **F5 (retired `codex_board` autostart + single-line `queued.txt`):** Delivered in `tools/pc/autostart_on.bat:12-13,15` and `tools/pc/codex_issue.bat:266` (`@(Get-Content -LiteralPath $f)`).
- **F7 (janitor out of GPU watcher):** Delivered in `tools/pc/watcher.bat:20` (per-minute `janitor.bat --nightly` removed; warns when `Voidsworn Janitor` task is missing; R455/2144 cleanup rules untouched).
- **W3 (PC clears its own dead `running` claim):** Delivered in `tools/pc/runner_common.ps1:1441-1476,1544-1551,1558-1568,1824-1835,1859-1870,1882,1893` (atomic `.claim.json` receipt plus legacy `prior_claim`, requires held issue lock + exact comment/run/branch match + no other live running comment, validates job before clearing).
- **W4 (stall watchdog counts process-tree CPU):** Delivered in `tools/pc/run_timeout.ps1:343-355,892,901`. Verified live on Windows PowerShell 5.1 that `Process.TotalProcessorTime.Ticks` advances without calling `.Refresh()`.
- **W5 (false success in `q_*.bat` and `a2_detail.bat`):** Delivered in `tools/pc/jobs/q_a633.bat:1-7`, `q_c1153.bat:1-7`, `q_paint_642.bat:1-7`, and `a2_detail.bat:1-76`. Verified live against real `tmo.bat` + `run_timeout.ps1` (exit code `37` propagated).
- **W6 (no push sign-in window hangs):** Delivered in `tools/pc/runner_common.ps1:70-79,1903-1915`, `codex_issue.bat:211`, `work_issue.bat:449`, `work_issue.ps1:770-772,869-872`, `relay_push.ps1:29-31`, `prune_relay_branches.ps1:26-28,151`, and `lane_tools_refresh.ps1:92-93,328-330`.
- **N1 (rerun keeps prior evidence + failed push patch by job):** Delivered in `tools/pc/runner_common.ps1:1477-1498,1556` (`Archive-CodexRecord`, keeping `status.json` intact for `prior_claim`) and `codex_issue.bat:93,223-224` (`%O%\push_failed.patch`).

### Findings (High / Medium / Low; Zero Blocking Against Current `main`)

| # | finding | OBSERVED/INFERRED | file:line | exact quote | why it matters | your fix | confidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | **[High, cross-PR] Exact merge conflict with PR #2167 (`codex/issue-2144`) at `:pushfail` and `%COMMON% finish`** | OBSERVED | PR #2195 `tools/pc/codex_issue.bat:223-225`; PR #2167 `tools/pc/codex_issue.bat:228-230` | `git diff --binary --output="%O%\push_failed.patch" %PRE% HEAD` | `git merge-tree --write-tree origin/codex/issue-2178 origin/codex/issue-2144` exits 1 with a conflict in `tools/pc/codex_issue.bat` (confirms Artoo on PR #2195). PR #2167 also adds `"%R%"`, `:scratch_handoff`, and `:relayshots` on the same exits. | Merge PR #2195 first (clean on `main`), then rebase PR #2167 onto post-#2195 `main` preserving `%O%\push_failed.patch`, `%COMMON% push`, `"%R%"`, `:scratch_handoff`, and `:relayshots`. | high |
| 2 | **[Medium] `q_*.bat` outer `tmo.bat 10800` runs in step mode (600 s idle cap, 3 h ceiling) around multi-ship 6 h GPU jobs** | OBSERVED | PR #2195 `tools/pc/jobs/q_a633.bat:6` (same in `q_c1153.bat:6`, `q_paint_642.bat:6`); `run_timeout.ps1:646,817` | `call "%V%\work217\tools\tmo.bat" 10800 "%ComSpec%" /d /s /c ""%V%\A18_A20_RUN_633.bat""` | Inner steps in `A18_A20_RUN_633.bat`, `C12_RUN_1153.bat`, and `E11_E12_PAINT_642.bat` allow 21600 s, and `job_wrap.bat:59` sets `PC_GPU_WAIT_SECONDS=3600`. If a wrapped job waits >600 s for GPU admission with 0 CPU or runs >3 h across multiple ships, the outer `tmo.bat` kills it as `IDLE` or `CEILING`. | If these legacy `q_*.bat` wrappers are reused, raise the outer ceiling (e.g. `21600`) and set `TMO_IDLE_S=3660` before calling `tmo.bat`. | high |
| 3 | **[Medium] `Test-TreeCpuProgress` treats any nonzero CPU tick delta as progress, masking busy-spin hangs until the 6 h ceiling** | INFERRED (from `run_timeout.ps1:348-350,901`) | PR #2195 `tools/pc/run_timeout.ps1:349,901` | `if ($ticks -gt [long]$CpuTicks[$child.Id]) { $advanced = $true }` | Fixes W4 for silent Codex runs, but a hung child stuck in a spin loop or periodic timer tick (>0 ticks every 5 s) will keep resetting `$lastProgress` and skip the 30-min `STALLED` stop until the 6 h ceiling. | Acceptable for W4 now; if spin-loop hangs appear on the PC, require a minimum CPU delta or log/file heartbeat after a longer grace window. | med |
| 4 | **[Low] `watcher.bat:10` starts `watcher_b.bat` before acquiring `queue\watcher.lock`** | OBSERVED | PR #2195 `tools/pc/watcher.bat:10,17` | `if exist watcher_b.bat start "" /min "%~dp0watcher_b.bat"` | Double-clicking `watcher.bat` while one is already open still flashes a second `watcher_b.bat` window briefly before it hits `queue_b\watcher.lock` and exits. | Move line 10 inside `:watch` after acquiring `queue\watcher.lock` (optional cleanup). | high |

### Ready / Verified (PR #2195)

- `git merge-tree --write-tree origin/main origin/codex/issue-2178` exits 0; all 11 GitHub checks pass; `pc_duet_2178_tests.js` is auto-discovered by `run_all_checks.js:167` and prints `PASS` (not `SKIP`) on Linux CI; `work_issue.ps1:734,869` dot-sources `runner_common.ps1 publication-library` before both `Set-PCGitNonInteractive` calls; `codex_issue.ps1:25` calls `Invoke-LockedRunner` which sets `PC_RUNNER_LOCKED_ISSUE` matching `codex_issue.bat:78`.

### Recommended Next Step (PR #2195)

Merge PR #2195 to `main`, restart both PC watcher windows together, rerun `autostart_on.bat` to remove the retired Startup entry, and rebase PR #2167 onto post-#2195 `main`.

---

## Review 2: Neon (audit): PR #2196 (`codex/issue-2179` @ `52a17730`)

**Verdict: FIX FIRST** (do not merge as-is; keep Issue #2179 open).

### Issue #2179 Scope Accountability (OBSERVED)

Because `tools/pc/codex_issue.ps1:115` forbids Codex from editing `.github/workflows/*` (the PC token lacks `workflow` scope), PR #2196 touched **0** files under `.github/workflows/`. Of the 13 items in Issue #2179:
- **Delivered in diff (with findings below):** `W10` (`guard.cjs`, `guard.test.cjs`), `W12` (`run_all_checks.js`, partial), `W13` (`run_all_checks.js:192`), `W15` `.gitattributes` half (`godot_checks.txt`, `godot_check_times.txt`), `F10` `run_checks.sh` headroom half, `F2` script half (`stale_work.js`, `stale_work_tests.js`), `F9` `guard.cjs` half (shipped live prematurely), `N3` (`setup-godot/action.yml`, `setup-blender/action.yml`).
- **NOT delivered in diff (missing all `.github/workflows/*` changes):** `F2` (`stale_work.yml` + `auto_pr.yml` `workflow_dispatch`), `F8` (`main_checks.yml` + `checks.yml` `workflow_call`), `F9` (`board_logs.yml`), `F10` (5 shards in `checks.yml`), `F11` (`auto_pr.yml` preserve PR text on merge-main + kept marker), `W9` (`!cancelled()` + deletion + zero-ahead guards in `checks.yml`/`auto_pr.yml`), `W14` (`claude/**` in `checks.yml`), `W15` (merge-tree conflict probe in `checks.yml`), `N4` (pinned bot seed in `checks.yml`).

### Findings (Blocking, then High / Medium)

| # | finding | OBSERVED/INFERRED | file:line | exact quote | why it matters | your fix | confidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | **[Blocking] Zero `.github/workflows/*` deliverables are in PR #2196, and the handoff patch path points to runner TEMP scratch deleted on `checked_push`** | OBSERVED | PR #2196 `.github/workflows/checks.yml:13-20`; PR #2196 body (`Board handoff`); `tools/pc/runner_common.ps1:696-701` | `Nothing was committed or pushed, and .github/workflows is unchanged.` | Merging PR #2196 leaves 8+ requested items undelivered (including `main_checks.yml`, 5 shards, F11, W9, W14, N4, `stale_work.yml`, and `auto_pr.yml` dispatch). The body links `sandbox:/%USERPROFILE%\AppData/Local/Temp/voidsworn-run-2179-.../board-workflows.patch`, which `Complete-RunScratch` deletes after `checked_push` (confirms Artoo finding 1). | Have the Board land the workflow changes directly (starting from `origin/board/duet-wow-1125` plus the `inputs.branch` dispatch fix below) in the same rollout or before closing #2179, and verify a real `main_checks` run on a code merge to `main`. | high |
| 2 | **[Blocking] `F9` in `guard.cjs:172-180` ships live before `F6` AND blocks Board R102 pushes to `main` from any Git worktree** | OBSERVED | PR #2196 `.claude/hooks/guard.cjs:172-178`; `origin/main` `docs/playbooks/pc.md:152` | `for (const lint of ['memory_lint_tests.js', 'doc_check_tests.js']) {` | Issue #2179 explicitly specifies `F9 (after F6 lands; ship it but leave a note)` and `W10: the guard must still allow the Board's documented pushes (LOOP.md and FINDINGS.md to main, R102)`. Observed live on `origin/main` (`6bf3c5ef5`) in this Git worktree: `node contrib/opus/tools/doc_check_tests.js` exits `1` (`FAIL a path named in an entry document does not exist: .git/info/exclude`) because `.git` is a file in worktrees. Also `LOOP.md` still has 94 LATEST lines until F6 rolls it. | Fix `doc_check_tests.js` to accept worktree `.git` (or ignore `.git/info/exclude` via `GENERATED`), and either wait until F6 + `LOOP.md` roll land before enabling F9 in `guard.cjs` or gate F9 behind the F6 landing PR. | high |
| 3 | **[Blocking] `stale_work.js:168-169` dispatches `auto_pr.yml` with `-f ref=main -f inputs[branch]=...`, which clashes with Duet's `auto_pr.yml` (HTTP 422)** | OBSERVED | PR #2196 `contrib/opus/tools/stale_work.js:168-169`; `board/duet-wow-1125` `contrib/duet/wow_1125/auto_pr_combined.diff:14-16` | `'-f', \`ref=${defaultBranch}\`, '-f', \`inputs[branch]=${x.branch}\`, '--silent']);` | Current `main`'s `auto_pr.yml` has no `workflow_dispatch`, and Duet's `auto_pr_combined.diff` defines bare `workflow_dispatch:` with no `inputs:` block (expecting `ref=<branch>`). Sending `inputs[branch]` against Duet's workflow returns HTTP 422 (`Unexpected inputs provided`), silently breaking F2 orphan recovery. | Keep `stale_work.js`'s safer `ref=main` + `inputs[branch]` contract, and define `workflow_dispatch.inputs.branch` in `.github/workflows/auto_pr.yml` (reading `inputs.branch` when dispatched) in the Board workflow PR, covered by `workflow_config_tests.js`. | high |
| 4 | **[High] Unrequested gate: `guard.cjs:274` blocks EVERY Git `!` shell alias (including read-only aliases) as a push** | OBSERVED | PR #2196 `.claude/hooks/guard.cjs:274,305-306` | `if (expansion.startsWith('!')) return true;` | `pushPolicy` runs `pushAlias` on every non-`push` git subcommand (`line 306`). Any `!` alias (e.g. `alias.lg = !git log ...`) returns `true` and is blocked with `Run pushes as plain git push commands, not through an alias.`, a gate Ryan did not ask for. It also spawns `git config --get alias.<subcommand>` on every `git status`/`diff`/`log` call. | Only block `!` shell aliases whose expansion mentions `push`, `send-pack`, `gh api`, or a variable/command substitution, or limit `pushAlias` lookups to non-builtin git subcommands. | high |
| 5 | **[High] `stale_work.js:66` hides stranded `-partial` branches after any PR edit without proving recovery** | OBSERVED | PR #2196 `contrib/opus/tools/stale_work.js:65-67` | `const prLater = localPulls.some(p => p.head === b.name.slice(0, -8) && Date.parse(p.updated_at) > Date.parse(b.date));` | Any comment, label change, or body edit updates `p.updated_at` and suppresses the `-partial` branch from the report even if the full branch has no newer commit (confirms Artoo finding 2). | Require proof that the full branch or PR head moved past the partial (equal SHA, newer commit date on the head SHA, or ancestry via `/compare`), and add a negative test where `updated_at` moves on an unchanged head SHA. | high |
| 6 | **[Medium] `run_all_checks.js:332-335` (`W12`) only catches `kind === 'optional'` (`fixture_check.js`), not standing tests that print `SKIP` and exit 0** | OBSERVED | PR #2196 `contrib/opus/tools/run_all_checks.js:111-119,198,332-335` | `if (row.result === 'SKIP' && (c.gate || process.env.CI)) {` | `classifyGeneric` (`lines 111-119`) returns `PASS` for exit 0 regardless of `SKIP ...` stdout. Only `fixture_check.js` (`line 198`) uses `kind: 'optional'` and ever produces `row.result === 'SKIP'`, so ~15 standing scripts that print `SKIP` and exit 0 on missing tools (e.g. `janitor_r455_tests.js:11,16`) still pass silently in CI. | Decide explicitly which rows may skip on Linux CI (Windows-only rows) vs must run on Linux CI (`pwsh`, `sqlite`, `python3`), and make `classifyGeneric` treat unexpected leading `SKIP` lines as `SKIP` (thus `FAIL` in CI). | high |
| 7 | **[Medium] `guard.cjs:354` (`ghApiPolicy`) scans the entire command string for `/merges`, causing false positives on comment bodies** | OBSERVED | PR #2196 `.claude/hooks/guard.cjs:354-355` | `if (/\/merges(?:[/?\s"']|$)/i.test(command)) {` | A `gh api repos/.../issues/1/comments -f body="blocks /merges endpoint"` write command matches `/\/merges/` inside the body text and is falsely rejected as a direct branch merge. | Extract the endpoint positional argument of `gh api` (ignoring `-f`/`-F`/`--field`/`--raw-field` values) before testing `/merges`, `/contents`, and `/git/refs`. | high |
| 8 | **[Medium] `setup-blender/action.yml:23-24` fetches the SHA-256 dynamically from the same server instead of pinning the digest in-repo, and was not exercised by PR #2196 CI** | OBSERVED | PR #2196 `.github/actions/setup-blender/action.yml:23-24`; `checks.yml:320` | `curl -fsSL --retry 3 --retry-all-errors -o "$RUNNER_TEMP/blender.sha256" "$release/blender-4.5.14.sha256"` | Catches download corruption, but unlike `setup-godot/action.yml:21` (pinned SHA-256), a compromised mirror could serve a matching archive + `.sha256`. Also `A16 death seam` took the fresh-fixture fast path on PR #2196, leaving `setup-blender` untested live. | Pin Blender 4.5.14's Linux x64 SHA-256 directly in `setup-blender/action.yml` (like `setup-godot`) and verify once on a cache-miss run. | med |

### Ready / Verified (PR #2196)

- `.gitattributes:20-21` (`merge=union` for `godot_checks.txt` and `godot_check_times.txt`), `godot/tools/ci/run_checks.sh:62-71` (headroom budget bump capped at 1080 s for older shard branches), `contrib/opus/tools/godot_shard_tests.js` (including the real `git merge-tree` union + ordinary-conflict fixture), and `.github/actions/setup-godot/action.yml:20-21` (pinned digest verified live on cache miss across all 6 Godot CI jobs on PR #2196) all passed cleanly.

### Recommended Next Step (PR #2196)

Fix findings 2, 4, 5, 6, and 7 on `codex/issue-2179` (or fold them into a Board PR that also adds the missing `.github/workflows/*` files with `workflow_dispatch.inputs.branch` matching `stale_work.js:169`), land F6 + `LOOP.md` roll before turning F9 on, and confirm `main_checks.yml` runs on the next code merge to `main`.

---

## Review 3: Neon (audit): PR #2167 (`codex/issue-2144` Run 3 @ `d62156a4`)

**Verdict: FIX FIRST (DO NOT re-allow Neon attachment cleanup or merge PR #2167 yet).**

### Relay-Proof Correctness Summary (Strict Check)

What `Assert-DirectRelayProof` (`tools/pc/janitor_relay.ps1:36-76`) gets **right** for Neon attachments (`-RequireAllFiles` at `janitor_neon.ps1:64`):
- Disables the `.godot`/`shader_cache` waiver (`janitor_relay.ps1:41`).
- Walks every entry in `attachments/$id`, rejects symlinks/reparse points (`line 52`), `.git` dirs (`line 53`), ElevenLabs take folders (`line 50`), files >100 MB (`line 65`), and empty folders (`line 69`).
- Uses case-sensitive `Ordinal` tree lookup (`line 27`), sets non-blob tree entries (`tree`/`symlink`/`commit`) to `''` so they never match a 40-hex hash (`line 32`), and compares every local file's `git hash-object --no-filters` blob SHA byte-for-byte against `$tree[$key]` (`lines 70-75`).

Where the branch **still fails strict deletion safety or CI** (blocking live rollout):

### Findings (Blocking, then High / Medium)

| # | finding | OBSERVED/INFERRED | file:line | exact quote | why it matters | your fix | confidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | **[Blocking] GitHub CI is RED on PR #2167's own new test `janitor_r455_tests` (`FAIL: exit 1`, 35.27 s) as well as stale pre-`f881c1207` `Godot game checks 1-4`** | OBSERVED | PR #2167 CI job `139479910089` (`Standing checks`); CI job `139479972799` (`Godot game checks`) | `janitor_r455_tests \| FAIL \| 35.27 \| FAIL: exit 1` | RULEBOOK 2.3 forbids merging on red checks. `Godot game checks 1-4` failed on `res://fx/test/weapon_layers_check.gd:36` (already fixed on `origin/main` at `f881c1207`), but `janitor_r455_tests` passed locally on Windows in our isolated test while failing on hosted Ubuntu `pwsh` CI. | Rebase onto `origin/main` (`6bf3c5ef5`), inspect the full `janitor_r455_tests` stdout on Linux `pwsh`, fix the Linux failure, and get `All checks` green before merging. | high |
| 2 | **[Blocking] `Get-DirectRelayTree` caches `ls-remote` origin refs once per janitor pass, allowing a wrong pass if a relay branch is deleted or moved mid-pass** | OBSERVED | PR #2167 `tools/pc/janitor_relay.ps1:15-26`; `tools/pc/janitor_neon.ps1:62-64` | `if ($null -eq $script:directRelayRefs) {` | `Get-DirectRelayTree` fetches `ls-remote --heads` from `voidsworn-relay` once per janitor pass (never refreshed under `$relayLock`, and `relay-mirror.git` is not fetched). If `prune_relay_branches` or another job deletes/replaces `pc-out-<branch>` on origin after `$script:directRelayRefs` was populated earlier in the pass, the stale cache still matches `$local[0]` in `relay-mirror.git` and approves deletion of an unbacked folder. | In live mode (`-not $dryRun`), query `ls-remote --heads $url $ref` fresh for that exact ref **while holding `$relayLock`**, right before hashing and deletion (keep the pass-wide cache for `--dry-run` only). | high |
| 3 | **[Blocking] Neighboring Neon provider logs (`logs/provider/events.$id.log`) are still deleted with zero backup proof, even when the worktree is already gone** | OBSERVED | PR #2167 `tools/pc/janitor_neon.ps1:39,61-65,75,124,159` | `else { Remove-Item -LiteralPath $item.FullName -Force -ErrorAction Stop }` | Confirms Artoo's finding 1 on `d62156a4`: `Assert-DirectRelayProof` runs only `if ($attachment)` (`lines 61-65`), while `logs/provider/events.$id.log` is deleted by age alone (`line 75`). Also `Clear-NeonThreadData` (`line 159`) runs after `if ($dir)` (`line 124`), so if the worktree was already removed, all Git history checks are skipped and the provider log is still deleted unproved. | Keep `logs/provider/events.$id.log` by default (add a keep-case test) unless the Board explicitly records in RULEBOOK 3.3 that provider event logs are disposable without relay proof. | high |
| 4 | **[High] Post-proof TOCTOU recheck compares only `Latest` and `Bytes`, missing zero-byte or preserved-mtime additions, and skips re-checking `Assert-NoProcessUses`** | OBSERVED | PR #2167 `tools/pc/janitor_neon.ps1:53,72-73`; `tools/pc/janitor_relay.ps1:99-100,110-111` | `if ($current.Latest -ne $stats.Latest -or $current.Bytes -ne $stats.Bytes) { throw 'attachments changed during relay proof' }` | A 0-byte file or a file added/replaced with an older mtime and matching byte count passes `Latest`/`Bytes` equality and is deleted unproved. In `Clear-DirectRelayResult` (`janitor_relay.ps1:99-113`), `Assert-NoProcessUses` runs before the network `ls-remote` + hash loop and is never re-checked before `Remove-CleanupDirectory`. | Track file count (and exact relative path + size + mtime snapshot) in `Measure-CleanupDirectory` or re-verify the entry list and re-run `Assert-NoProcessUses` (refreshed process list) immediately before `Remove-CleanupDirectory`. | high |
| 5 | **[High] Whole-folder helper cleanup (`Test-RelayedResults`) drops the 24-hour age gate for `PASS` helpers without confirming `relay-mirror.git` refs on `voidsworn-relay` origin** | OBSERVED | PR #2167 `tools/pc/janitor.ps1:215,228,399-400,424` | `if (-not $finishedHelper -and $stats.Latest -gt $now.AddHours(-$hours)) {` | Unlike `Assert-DirectRelayProof`, `Test-RelayedResults` -> `Get-RelayReceipts` (`janitor.ps1:205-232`) reads only local `relay-mirror.git` refs (`for-each-ref` / `rev-list`) with no `ls-remote` check on origin. Removing the 24 h age gate for `done.txt == PASS` helpers (`line 424`) lets a stale local `relay-mirror.git` branch approve immediate deletion of a helper folder whose relay branch was pruned on GitHub. | Require live origin confirmation (same as `Get-DirectRelayTree`) for `relay-mirror.git` refs in `Get-RelayReceipts` before deleting any `PASS` helper folder. | high |
| 6 | **[High, cross-PR] Direct Git merge conflict with PR #2195 (`codex/issue-2178`) in `tools/pc/codex_issue.bat`** | OBSERVED | PR #2167 `tools/pc/codex_issue.bat:220-230`; PR #2195 `tools/pc/codex_issue.bat:221-225` | `git diff --binary --output="%B%\cx_issue%N%.patch" %PRE% HEAD` | `git merge-tree --write-tree origin/codex/issue-2178 origin/codex/issue-2144` fails on `tools/pc/codex_issue.bat`. PR #2167's run 3 also still saves failed push patches to `%B%\cx_issue%N%.patch` and omits PR #2195's `%COMMON% push`. | Rebase PR #2167 onto post-#2195 `main`, keeping both PR #2195's `%COMMON% push` + `%O%\push_failed.patch` and PR #2167's `"%R%"` + `:scratch_handoff` + `:relayshots`, then test both push exits on Windows. | high |
| 7 | **[Medium] Issue #2144 Run 2 items (GPU slot hold release in `opus_job_head.ps1` `Reset-Slot`, janitor held-slot release, bat-path in-use check) are absent from PR #2167** | OBSERVED | PR #2167 `tools/pc/jobs/opus_job_head.ps1` diff (21 lines) vs Issue #2144 Run 2 brief | `git clean -ffdx that keeps only godot\.godot (the warm import cache) and *.import sidecars` | Issue #2144 marks Run 2 "(done)", yet `opus_job_head.ps1` on both `origin/main` and PR #2167 still keeps only `godot/.godot` and `*.import` in `Reset-Slot` and contains no janitor held-slot release step. | Confirm whether Run 2 landed on another branch/PR or needs a separate follow-up issue before closing #2144. | high |

### Ready / Verified (PR #2167)

- Core byte-for-byte hash proof inside `Assert-DirectRelayProof` (`tools/pc/janitor_relay.ps1:27-76`) is solid for Neon attachments when `-RequireAllFiles` is set (`janitor_neon.ps1:64`): case-sensitive `Ordinal` paths, non-blob entries rejected, symlinks/`.git`/ElevenLabs take folders/>100 MB files/empty folders rejected, `hash-object --no-filters` verified per file.
- `contrib/opus/tools/janitor_r455_tests.js` passed locally on Windows (`WIN_EXIT=0`, isolated temp fixture) covering relayed, un-relayed, modified, partial (`nested/extra.png`), and deleted-on-origin Neon attachments, plus paid takes, skipped >10 MB media, active processes, and keep-list entries.

### Recommended Next Step (PR #2167)

Keep Neon attachment cleanup disabled for now. Rebase `codex/issue-2144` onto post-#2195 `main`, fix the Linux `janitor_r455_tests` CI failure, replace the pass-wide `$script:directRelayRefs` cache with a live per-target `ls-remote` check under `$relayLock` (and in `Get-RelayReceipts`), tighten the post-proof TOCTOU recheck, settle provider-log deletion with a keep-case fixture, and re-verify green `All checks` before merging.

---

## File Read Receipts (`docs/REVIEW_PROTOCOL.md` Section 1)

| File (branch @ short SHA) | Total lines | First 40 chars of LAST line | Line ranges read (if >1,500 lines) |
| --- | ---: | --- | --- |
| `tools/pc/autostart_on.bat` (PR #2195 `6088320e`) | 17 | `pause` | full |
| `tools/pc/codex_issue.bat` (PR #2195 `6088320e`) | 291 | `endlocal & set "NODE_EXIT=%NODE_EXIT%" &` | full (diff + 191-291) |
| `tools/pc/codex_issue.ps1` (PR #2195 `6088320e`) | 162 | `} else { Write-Host 'usage: codex_issue.` | full |
| `tools/pc/job_wrap.bat` (PR #2195 `6088320e`) | 236 | `exit /b 0` | diff + 56-61 |
| `tools/pc/jobs/a2_detail.bat` (PR #2195 `6088320e`) | 76 | `exit /b %A2_RC%` | full |
| `tools/pc/jobs/q_a633.bat` (PR #2195 `6088320e`) | 7 | `exit /b %ERRORLEVEL%` | full |
| `tools/pc/jobs/q_c1153.bat` (PR #2195 `6088320e`) | 7 | `exit /b %ERRORLEVEL%` | full |
| `tools/pc/jobs/q_paint_642.bat` (PR #2195 `6088320e`) | 7 | `exit /b %ERRORLEVEL%` | full |
| `tools/pc/lane_tools_refresh.ps1` (PR #2195 `6088320e`) | 441 | `}` | diff hunks |
| `tools/pc/prune_relay_branches.ps1` (PR #2195 `6088320e`) | 166 | `Say "log: $log"` | diff hunks |
| `tools/pc/relay_push.ps1` (PR #2195 `6088320e`) | 343 | `if ($pics.Count -eq 30) { Write-Output '` | diff hunks |
| `tools/pc/run_timeout.ps1` (PR #2195 `6088320e`) | 941 | `}` | 1-120, 316-365, 431-904 |
| `tools/pc/runner_common.ps1` (PR #2195 `6088320e`) | 2403 | `exit 0` | diff hunks + 66-80, 715-739, 1427-1915 |
| `tools/pc/watcher.bat` (PR #2195 `6088320e`) | 73 | `goto loop` | full |
| `tools/pc/watcher_b.bat` (PR #2195 `6088320e`) | 43 | `goto loop` | full |
| `tools/pc/work_issue.bat` (PR #2195 `6088320e`) | 516 | `exit /b %RC%` | diff hunks |
| `tools/pc/work_issue.ps1` (PR #2195 `6088320e`) | 903 | `else { Write-Host 'usage: work_issue.ps1` | diff hunks + mode/sourcing scan |
| `contrib/opus/tools/pc_duet_2178_tests.js` (PR #2195 `6088320e`) | 313 | `});` | full |
| `contrib/opus/tools/pc_jobs_1194_tests.js` (PR #2195 `6088320e`) | 557 | `console.log(\`PASS PC jobs 1194 checks ($` | diff hunk |
| `.claude/hooks/README.md` (PR #2196 `52a17730`) | 42 | `runs the real Godot loader on a small te` | diff hunk |
| `.claude/hooks/guard.cjs` (PR #2196 `52a17730`) | 533 | `}` | full |
| `.claude/hooks/guard.test.cjs` (PR #2196 `52a17730`) | 292 | `}` | diff hunks |
| `.gitattributes` (PR #2196 `52a17730`) | 21 | `godot/tools/ci/godot_check_times.txt mer` | diff hunk |
| `.github/actions/setup-blender/action.yml` (PR #2196 `52a17730`) | 41 | `        ~/blender-4.5.14/blender --versi` | full diff + 14-24 |
| `.github/actions/setup-godot/action.yml` (PR #2196 `52a17730`) | 34 | `        "$HOME/godot-4.7.2/Godot_v4.7.2-` | full diff + 16-24 |
| `contrib/opus/tools/godot_shard_tests.js` (PR #2196 `52a17730`) | 133 | `console.log('PASS godot_shard_tests: ' +` | diff hunks |
| `contrib/opus/tools/run_all_checks.js` (PR #2196 `52a17730`) | 367 | `module.exports = { rowEnv, classifyFindi` | full |
| `contrib/opus/tools/run_all_checks_live_tests.js` (PR #2196 `52a17730`) | 148 | `console.log('Evidence: ' + root);` | diff hunks |
| `contrib/opus/tools/stale_work.js` (PR #2196 `52a17730`) | 208 | `module.exports = { analyze, branchPatter` | full |
| `contrib/opus/tools/stale_work_tests.js` (PR #2196 `52a17730`) | 98 | `console.log('stale_work_tests: PASS (7 r` | full |
| `contrib/opus/tools/workflow_config_tests.js` (PR #2196 `52a17730`) | 85 | `console.log('PASS workflow_config_tests:` | diff hunk |
| `godot/tools/ci/run_checks.sh` (PR #2196 `52a17730`) | 132 | `if [ $F -eq 0 ]; then echo "PASS: every ` | diff hunks |
| `.github/workflows/checks.yml` (PR #2196 `52a17730`) | 356 | `          echo "PASS" \| tee -a "$GITHUB_` | 13-31, 276-340 (verified unchanged vs `main`) |
| `.github/workflows/auto_pr.yml` (PR #2196 `52a17730`) | 204 | `          fi` | verified unchanged vs `main` |
| `tools/pc/janitor_neon.ps1` (PR #2167 `d62156a4`) | 164 | `}` | full |
| `tools/pc/janitor_relay.ps1` (PR #2167 `d62156a4`) | 123 | `}` | full |
| `tools/pc/neon_idle_threads.js` (PR #2167 `d62156a4`) | 56 | `}` | full |
| `tools/pc/janitor.ps1` (PR #2167 `d62156a4`) | 933 | `exit 0` | 1-80, 136-232, 388-430, 681-795 + full diff |
| `tools/pc/janitor_salvage.ps1` (PR #2167 `d62156a4`) | 212 | `}` | full |
| `tools/pc/relay_push.ps1` (PR #2167 `d62156a4`) | 346 | `if ($pics.Count -eq 30) { Write-Output '` | 1-60, 285-346 + full diff |
| `tools/pc/relay_push.bat` (PR #2167 `d62156a4`) | 8 | `exit /b %ERRORLEVEL%` | full |
| `tools/pc/codex_issue.bat` (PR #2167 `d62156a4`) | 321 | `endlocal & set "NODE_EXIT=%NODE_EXIT%" &` | full diff + 215-233 |
| `tools/pc/runner_common.ps1` (PR #2167 `d62156a4`) | 2292 | `exit 0` | 123-167, 588-815, 850-1120 + full diff |
| `tools/pc/sandbox_handoff.ps1` (PR #2167 `d62156a4`) | 75 | `Write-Host 'sandbox scratch and checkout` | full |
| `tools/pc/disk_space.ps1` (PR #2167 `d62156a4`) | 183 | `}` | full diff |
| `tools/pc/jobs/look_bench.bat` (PR #2167 `d62156a4`) | 214 | `exit /b %ERRORLEVEL%` | full diff |
| `tools/pc/jobs/opus_job_head.bat` (PR #2167 `d62156a4`) | 216 | `exit /b %OJ_RC%` | full diff |
| `tools/pc/jobs/opus_job_head.ps1` (PR #2167 `d62156a4`) | 1668 | `}` | full diff + `Reset-Slot` / `hold.txt` scan |
| `contrib/opus/tools/janitor_r455_tests.js` (PR #2167 `d62156a4`) | 218 | `}` | full |

## Not checked:

- The earlier stdout lines of `janitor_r455_tests` inside PR #2167's hosted Linux `Standing checks` job (`139479910089`): `ci_logs` truncated the job log to its final 259 lines, showing `janitor_r455_tests | FAIL | 35.27 | FAIL: exit 1` in the summary table but not the assertion text that failed on Ubuntu `pwsh` (the same test passed locally on Windows in an isolated temp copy).
- Live execution of PR #2195's `pc_duet_2178_tests.js` or a combined merged build of PR #2195 + PR #2167 on Windows.
- Live execution of PR #2196's `.github/actions/setup-blender/action.yml` download and SHA-256 verification path (PR #2196's `A16 death seam` job hit the fresh fixture fast path and skipped `setup-blender`).
- Contents of Codex's runner-local `board-workflows.patch` referenced in PR #2196's body (not committed to git and inside `PC_RUN_SCRATCH`).
- Live PC scheduled janitor execution, `tools_live` installation, or live `voidsworn-relay` pushes/deletes.
