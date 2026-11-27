# Runner fix verification and Windows unelevated sandbox root-cause notes (PR #2261)

Date: 2026-11-26 (local CST / 2026-11-27 UTC)
Branch: `neon/runner-fix-stage`
Reviewed base commit (six files left byte-for-byte unchanged): `cf5c12573585c02128e2b1be847385ae0a32600f`

## 1. Executive verdict

- **Exact reruns on `cf5c1257` PASSED:**
  - Outside-write sandbox probe (`run_outside_write_probe.ps1`): `exit=0`, `9.01 s`, `inside_ok=True` (`IN`), `outside_created=False` (`Access denied`, exit 1). Log: `logs/a1_outside_write_probe_rerun.log`.
  - Controlled `codex_issue.bat 9991` dry pilot (`run_codex_issue_pilot.js` on bundled Node 22.11.0): `exit=0`, `27.15 s`, `pilot_result.txt="RUNNER_PILOT_OK\r\n"`, fake GitHub running flag cleared (`false`), zero pushes to remote. Log: `logs/a2_codex_issue_9991_pilot_rerun.log`.
  - Controlled `codex_issue.bat 9991` dry pilot launched via WMI `Win32_Process Create` with default Windows `TEMP=C:\Users\rcbai\AppData\Local\Temp`: `exit=0`, `33.61 s`, `pilot_result.txt="RUNNER_PILOT_OK\r\n"`, fake GitHub running flag cleared (`false`). Log: `logs/d5_codex_issue_9991_pilot_via_wmi.log`.
- **Root cause of PC Claude's 3/3 outside-write probe hangs PROVEN:**
  - It is NOT WMI, NOT `Downloads\voidsworn_test`, NOT `cmd /c`, and NOT `codex-windows-sandbox-service`.
  - It is **`TEMP` / `TMP` pointing at `C:\Users\rcbai\AppData\Local\Temp`**, which currently holds **8,825 top-level entries (5,589 subdirectories and 3,236 files)**.
  - Under `-c windows.sandbox=unelevated` + `workspace-write`, `codex.exe` treats `%TEMP%` as a writable root and grants the capability SID recorded in `C:\Users\rcbai\.codex\cap_sid` (`c:/users/rcbai/appdata/local/temp` -> `S-1-5-21-3468974702-3029577100-785373452-1517145167`) using `(OI)(CI)(M)` via `SetNamedSecurityInfoW`.
  - Because that capability SID is NOT on `C:\Users\rcbai\AppData\Local\Temp`'s DACL (confirmed via `icacls`), Windows `advapi32` synchronously propagates the ACE across all 5,589 subdirectories and hundreds of thousands of files inside `AppData\Local\Temp` on the first shell command.
  - While stuck after `START:` in `C:\Users\rcbai\.codex\.sandbox\sandbox.2026-11-27.log`, `codex.exe` never reaches `CreateProcessAsUserW` (zero child `powershell.exe` spawned), burns ~95% kernel CPU, and issues ~50,000+ `OtherOps`/sec (`180,720 -> 466,828 -> 763,401` in 20 s on a direct launch; `969,907` in 21.1 s in an earlier check) while `ReadOps` and `WriteOps` remain flat. Killing `codex.exe` aborts the walk before the ACE commits to `AppData\Local\Temp`, so every subsequent run restarts the walk from file 0.
- **Why live `codex_issue.bat` runs are already immune:**
  - `tools/pc/codex_issue.bat` lines 129-137 create a brand-new empty per-run directory (`%PC_RUN_SCRATCH%` = `<TEMP>\voidsworn-run-<N>-<guid>`) and set `TEMP`, `TMP`, and `TMPDIR` to `%PC_RUN_SCRATCH%` BEFORE both `preflight` (line 145) and `tmo.bat ... codex.cmd` (line 158).
  - Verified live under WMI `Win32_Process Create` starting from default `TEMP=C:\Users\rcbai\AppData\Local\Temp`: `codex_issue.bat 9991` created `voidsworn-run-9991-...`, redirected `TEMP`/`TMP`/`TMPDIR`, and completed cleanly in `33.61 s` (`logs/d5_codex_issue_9991_pilot_via_wmi.log`).
  - No edit to the six reviewed files on PR #2261 is required for this issue.

## 2. Controlled experiment matrix (all on `cf5c1257`)

| Case | Log file | Launch | Workdir | Effective `TEMP`/`TMP` | Prompt | Result | Elapsed | `inside_ok` | `outside_created` | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| A1 | `logs/a1_outside_write_probe_rerun.log` | Direct (T3 child) | `%TEMP%\neon-sbx-real-*\repo` | Private T3 run temp | `direct_ps` | PASS (`exit=0`) | 9.01 s | True (`IN`) | False | `t=8.1s`: `KernelMs=391`, `OtherOps=26,273` |
| A2 | `logs/a2_codex_issue_9991_pilot_rerun.log` | Direct (Node 22) | Temp dry pilot repo | Runner `%PC_RUN_SCRATCH%` | `CODEX_TASK.md` | PASS (`exit=0`) | 27.15 s | `RUNNER_PILOT_OK` | n/a | Full `codex_issue.bat 9991` dry path, fake GH |
| D1 | `logs/d1_downloads_fresh_temp_direct.log` | Direct (T3 child) | `Downloads\voidsworn_test\neon_clean_d1` | Fresh empty dir | `claude_cmd` | PASS (`exit=0`) | 8.04 s | True (`ok`) | False | Proves `Downloads\voidsworn_test` + `cmd /c` pass |
| D2 | `logs/d2_downloads_fresh_temp_wmi.log` | WMI `Win32_Process Create` | `Downloads\voidsworn_test\neon_clean_d2` | Fresh empty dir | `claude_cmd` | PASS (`exit=0`) | 8.44 s | True (`ok`) | False | Proves WMI + `Downloads\voidsworn_test` + `cmd /c` pass |
| D3 | `logs/d3_downloads_stdtemp_direct_hang.log` | Direct (T3 child) | `Downloads\voidsworn_test\neon_clean_d3` | `C:\Users\rcbai\AppData\Local\Temp` | `direct_ps` | HANG (`exit=124` cap) | 25.38 s | False | False | `t=20.0s`: `KernelMs=14,391`, `OtherOps=763,401`, no `powershell.exe` |
| D4 | `logs/d4_downloads_stdtemp_wmi_hang.log` | WMI `Win32_Process Create` | `Downloads\voidsworn_test\neon_clean_d4` | `C:\Users\rcbai\AppData\Local\Temp` | `claude_cmd` | HANG (`exit=124` cap) | 25.59 s | False | False | `t=20.1s`: `KernelMs=14,703`, `OtherOps=807,125`, no `powershell.exe` |
| D5 | `logs/d5_codex_issue_9991_pilot_via_wmi.log` | WMI `Win32_Process Create` | Dry pilot repo under `AppData\Local\Temp` | Starts as `AppData\Local\Temp`, runner sets `%PC_RUN_SCRATCH%` | `CODEX_TASK.md` | PASS (`exit=0`) | 33.61 s | `RUNNER_PILOT_OK` | n/a | Proves `codex_issue.bat` is immune even from WMI + default `TEMP` |

## 3. Exact launch comparison: Neon (T3) vs PC Claude (Direct and WMI)

| Dimension | Neon (T3 / Antigravity shell) | PC Claude (Direct session) | WMI `Win32_Process Create` | Live lane (`codex_issue.bat`) |
|---|---|---|---|---|
| Windows user | `desktop-d5ctoet\rcbai` (`S-1-5-21-2418975514-3104082165-80353168-1001`) | Same (`rcbai`) | Same (`rcbai`) | Same (`rcbai`) |
| Token / elevation | Medium Mandatory Level (`S-1-16-8192`), `Administrators` deny-only (unelevated) | Same | Identical (`whoami /all` matches byte-for-byte) | Same |
| Session / WinSta / Desktop | `SessionId=1`, `WinSta0\exebox-2N5GEORTEYSSFV32RR3OLE7ZNQ`, `ConsoleHwnd=0` | `SessionId=1`, `WinSta0\Default` | `SessionId=1`, `WinSta0\Default`, `ConsoleHwnd!=0` | `SessionId=1`, `WinSta0\Default` (`cmd.exe /K watcher*.bat`) |
| `CODEX_HOME` | Unset (uses `C:\Users\rcbai\.codex`) | Unset (uses `C:\Users\rcbai\.codex`) | Unset (uses `C:\Users\rcbai\.codex`) | Unset (uses `C:\Users\rcbai\.codex`) |
| `TEMP` / `TMP` | **Private per-run dir** (`C:\Users\rcbai\.t3\userdata\antigravity-tmp\ac0a3dfd6ddd\run-kbVP88`, <10 files) | **Default `C:\Users\rcbai\AppData\Local\Temp` (8,825 top-level items, 5,589 dirs)** | **Default `C:\Users\rcbai\AppData\Local\Temp` (8,825 top-level items, 5,589 dirs)** | **Redirected to fresh empty `%PC_RUN_SCRATCH%` (`voidsworn-run-<N>-<guid>`) at `codex_issue.bat:135-137`** |
| `SESSIONNAME` | `Console` | `Console` | Unset (proved irrelevant: setting `SESSIONNAME=Console` alone still hung at 25.45 s) | `Console` |
| Working folder | `%TEMP%\neon-sbx-real-*\repo` | `C:\Users\rcbai\Downloads\voidsworn_test\rf2261_sbx` | `Downloads\voidsworn_test\...` | `C:\Users\rcbai\Downloads\voidsworn_test\board*\repo` |
| Network | Normal local PC network (`chatgpt.com` reachable) | Same | Same | Same |
| `CodexSandboxService.OpenAI.Codex` | Running (`Auto`, `LocalSystem`, `OpenAI.Codex_26.1120.6357.0_x64__2p2nqsd0c76g0\...\codex-windows-sandbox-service.exe`), `CodexSandboxOffline`/`CodexSandboxOnline` local users enabled, `setup_marker.json` v5 (2026-11-26T15:25:27Z). NOT used by `unelevated`. Under `elevated`, `codex.exe` 0.171.0 logged `sandbox setup required: sandbox users missing or incompatible with marker version` and stalled. | Same service | Same service | Same service (unused by `unelevated`) |

## 4. Lane checkout ACL check (`board\repo` through `board_f\repo`)

Checked `icacls` against `C:\Users\rcbai\.codex\cap_sid` for all six lane checkouts:
- `board\repo`, `board_b\repo`, `board_d\repo`, `board_e\repo`, `board_f\repo`: BOTH `workspace_by_cwd` and `writable_root_by_path` capability SIDs are already present on their DACLs (`hasCwdSid=True, hasWrtSid=True`).
- `board_c\repo`: `hasCwdSid=False, hasWrtSid=False` (fresh checkout). A Voidsworn working tree has 13,849 tracked files (`git ls-files`), so its first unelevated ACL grant takes a few seconds, not minutes, and persists on disk thereafter.

## 5. Additional batch pitfall noted during testing

`%APPDATA%\npm\codex.cmd` uses `endLocal & goto #_undefined_# 2>NUL` on line 17. If a wrapper `.bat` runs `setlocal`, sets `TEMP=...`, and invokes `"%APPDATA%\npm\codex.cmd"` WITHOUT `call`, `cmd.exe` pops the caller's `setlocal` and reverts `TEMP` back to the parent environment before `node` / `codex.exe` starts. Always invoke `codex.cmd` with `call` (or without a caller `setlocal`). `tools/pc/codex_issue.bat` is safe because it invokes `call "%TP%tmo.bat" ...` which starts `codex.cmd` via PowerShell `Start-Process` inheriting the modified environment.

## 6. Smallest fix / operational guidance

1. **No change needed to the six reviewed files on PR #2261 (`cf5c1257`):** `codex_issue.bat` already isolates `TEMP`, `TMP`, and `TMPDIR` to a fresh empty `%PC_RUN_SCRATCH%` before `preflight` and `codex.cmd`.
2. **For PC Claude to confirm outside-write on `rf2261` right now:** set `TEMP`, `TMP`, and `TMPDIR` to a fresh empty temp folder before invoking `codex exec --ignore-user-config -c windows.sandbox=unelevated ...` (or run `contrib/neon/runner_fix/run_outside_write_probe.ps1 -OverrideTemp <fresh empty dir>`).
3. **Optional PC hygiene (requires Ryan's OK per RULEBOOK 3.3):** purge stale temp folders under `C:\Users\rcbai\AppData\Local\Temp` (8,825 top-level entries, 5,589 dirs) so any future ad-hoc `codex exec -c windows.sandbox=unelevated` invocation without `TEMP` redirection does not stall in `SetNamedSecurityInfoW`.
4. **Optional future follow-up (not needed to merge PR #2261):** if `runner_common.ps1 preflight` is ever invoked directly outside `codex_issue.bat`, redirect `TEMP`/`TMP`/`TMPDIR` to a fresh subfolder under `$out` before starting `codex.cmd`.
