# Duet ways-of-working audit, Nov 25 2026 (outside reviewer evidence, not a ruling)

Ryan pasted this list and the patch zip on Nov 25 18:17 UTC. Patches are against main 96149fb; each fix job must verify the claim on current main first. Files under this folder sit at the repo path they would replace.

F1 Storage: delete the 348 board/pc-out-* branches (PRUNE_RELAY_BRANCHES_LIVE.bat), then tools/pc/compact_repos.ps1 dry run, then -Live; add '^refs/heads/board/pc-out-*' to the lane fetch in runner_common.ps1 ~1592. Needs git 2.29+.
F2 Missing work: add stale_work.js, stale_work_tests.js, .github/workflows/stale_work.yml; add workflow_dispatch and the dispatch title step to auto_pr.yml; make the stale-work issue and set repo variable STALE_ISSUE. Resend codex/issue-2148, 2149, muse/loom-notes.
F3 Queue B runs twice: watcher lock, checked move and cmd /d /c call in watcher.bat and watcher_b.bat (watchers.diff).
F4 Board pause fails queued jobs: hold both queues on the gpu_go.txt pause line; default PC_GPU_WAIT_SECONDS=3600 in job_wrap.bat.
F5 Retired codex_board still autostarts: delete autostart_on.bat lines 10-12; wrap Get-Content in @() at codex_issue.bat line 266.
F6 LOOP.md 115 KB: add contrib/opus/tools/loop_roll.js and LOOP_HARD=25 in memory_lint_tests.js; Board runs the roll after each lane check.
F7 Janitor inside the GPU queue: remove the per-minute janitor call from watcher.bat; warn when the Voidsworn Janitor task is missing.
F8 Main never tested: workflow_call in checks.yml plus new main_checks.yml.
F9 Board log pushes redden main: guard.patch runs memory_lint and doc_check on the pushed tip; new board_logs.yml. Land after F6.
F10 Godot budget: 5 shards in checks.yml; run_checks.patch raises the budget for old 3-shard branches.
F11 PR text wiped on merge-main: auto_pr.patch keeps the body on a merge head and keeps text under the kept marker.
W1 Seat rules drift: one seats table in LOOP.md; add seat_facts_tests.js in the same PR as the doc fixes: R449, gpt-6.2-sol, neon, SUPERSEDED marks.
W2 Built but off: add wired_check.js as a report row; give Ryan one switch-on/wire/delete list; schedule godot_gpu_checks.bat nightly.
W3 Stale running label: let the PC clear its own dead claim at runner_common.ps1 line 1735.
W4 Stall watchdog blind to Codex: count process-tree CPU as progress in run_timeout.ps1.
W5 False success: q_*.bat run the job and pass its exit code; a2_detail.bat keeps tmo's exit code.
W6 Push can hang on a sign-in window: GIT_TERMINAL_PROMPT=0, GCM_INTERACTIVE=never, http.lowSpeedLimit/Time on pushes and lane_tools_refresh.ps1 line 92.
W7 Mirrors keep 1,282 PR heads: heads and tags refspecs only, delete refs/pull, nightly gc under the mirror lock, prune janitor logs past 30 days.
W8 Lane list in 9 files: hashcheck strict in codex_issue.bat line 103; later one tools_live\lanes.txt.
W9 False red runs: !cancelled() and deletion guards in checks.yml and auto_pr.yml; skip Godot jobs when nothing is ahead of main.
W10 Push guard gaps: refuse wildcard refspecs, alias pushes and gh api merges (guard.patch, guard_test.patch).
W11 Full 2.3 GB checkouts: sparse checkout for standing-checks and a16-fixture; switch memory_lint line 175 to sparse_check_inputs first.
W12 Missing check passes as SKIP: SKIP fails in CI (run_all_checks.patch).
W13 Hook tests never run: guard_test.patch plus a run_all_checks row for guard.test.cjs.
W14 claude/** branches unchecked: add 'claude/**' to checks.yml push branches.
W15 Merge-main conflicts: merge=union for godot_checks.txt and godot_check_times.txt; one merge-tree conflict probe in the changes job.
N1 Rerun wipes the last record: keep prev_* copies in codex_issue.bat; write the patch into the job folder.
N2 Off-PC self-tests: Windows-only skip in runner_openai_resume_selftest.js; clean pcd-test-* folders in pc_daemon_selftest.js.
N3 Unchecked toolchain downloads: sha256sum -c after the Godot and Blender downloads.
N4 Monday seed rotation can redden the same commit: pin the seed in the rotating commit.
N5 Hard-coded paths in 112 files: one paths file read by every PC script.
N6 Job limits (inferred): watch for queued jobs once 5 shards land.
