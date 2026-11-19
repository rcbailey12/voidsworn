# Codex job: issue #1192, "PC jobs: inner stall watchdog, fatal-line abort, per-step caps (hung GPU steps)"

You are Codex, working one job from the Voidsworn job board (github.com/rcbailey12/voidsworn/issues/1192).
This folder is a fresh checkout of main on the branch codex/issue-1192. Follow AGENTS.md and CLAUDE.md in this folder.
Base already merged by the runner: origin/main (ec807cc1d120452b7b6c67d3713c072503fbf9b6). The merge is committed; do not merge it yourself.

Rules:
- Do exactly what the job below asks. Change nothing else. Read the brief it names first.
- Run the check the job's "Done when" line names. The standing checks run with: node contrib/opus/tools/run_all_checks.js
  Godot, if a check needs it: C:\Users\rcbai\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe (use --headless).
- No em dashes in anything you write. Plain words.
- Do not commit and do not push: the runner does that after you finish.
- Never edit anything under .github/workflows (the PC token has no workflow scope, so the push is refused): if CI needs a change, say exactly what in your report.
- The runner handles Base and resume merges before you start. Do not run git merge; report a missing base in your report.
- GPU work must use tools/pc/tmo.bat <seconds> <exe> [args]. Shared capacity comes from Downloads\voidsworn_test\gpu_slots.json (default 2).
  Captures weigh 1, Blender weighs 2; set PC_GPU_WEIGHT=2 for other heavy bakes, or the Board's chosen weight;
  frame-time scripts take solo automatically. For a new timing script set PC_GPU_MODE=solo before calling tmo.bat.
  gpu_go.txt must say GPU cleared. Lane C is code only. Never launch GPU executables directly.
- Keep scratch output (logs, temp checks) in %TEMP%, not in this folder.
- Save review pictures and their .provenance.json sidecars in C:\Users\rcbai\Downloads\voidsworn_test\board_d\issue-1192\shots (create it). Link them as shots/<file> so the
  runner can copy them into docs/shots/issue-1192-codex and rewrite the links before publishing.
- Link pictures already in the checkout by repo-relative path, and keep every picture link relative.
- Finish with a short report: what you changed (files), the checks you ran and their result, anything you skipped and why.
  That report becomes the pull request description, so write it for a reviewer.

## The job

Owner: codex
Brief: below; Neon's PC pipeline audit (Nov 19, summary below, checked by the Board at main 7bc332b4); tools/pc/run_timeout.ps1, tools/pc/tmo.bat, tools/pc/jobs/ship_job.bat, tools/recipe/4_parts_kit.bat to 7_export.bat, tools/pc/codex_issue.bat, tools/pc/work_issue.bat, RULEBOOK 3.4
Deliver to: tools/pc/run_timeout.ps1, tools/pc/tmo.bat, tools/pc/jobs/ship_job.bat, tools/recipe/*.bat, tools/pc/codex_issue.bat, tools/pc/work_issue.bat, contrib/opus/tools/runner_stall_tests.js (new, in the standing checks), docs/RULEBOOK.md 3.4
Branch: codex/issue-1192
Base: main
Effort (Codex): xhigh
Done when: a child that stops writing output for its idle limit, or prints a known fatal line, is killed with its whole tree and the step fails with a clear reason in timeouts.log; every ship and recipe step has a cap sized to the step instead of 21600 s; the tests below pass in the standing checks; a PC proof with a fake hanging Godot step shows the kill within the idle limit and the GPU claim released only after the tree is gone.

## THIS IS THE JOB NOW: run 1 brief (Board, Nov 19 2026)

Why. On Nov 19 the 1078 shield probe hung on "Jolt Physics job system exceeded the maximum number of jobs ... Waiting for jobs" at 10:07 CT, logged nothing more, and held the GPU solo until its 3600 s cap at 11:03; every other GPU step on the PC timed out behind it (exit 126), and the Board could not kill it. Neon's audit (Ryan shared it 17:20 UTC) traced why, and the Board checked it in code: run_timeout.ps1 watches for stalls only on the outer agent (TMO_REPO, TMO_OUT and TMO_LOG, line 171) and clears those variables before every child (line 251), so an inner Godot or Blender step just waits out its ceiling; ship_job.bat passes 21600 s to every step, even 10-second checks.

1. Inner idle watchdog in run_timeout.ps1 for every child: redirect or tee the child's stdout and stderr to a log the watchdog can read, and kill the tree when there is no new output, no new file in its out folder and no CPU growth for TMO_IDLE_S (defaults: Godot 300 s, Blender 600 s, others 600 s; a step may raise it, never turn it off). Exit 124 and a timeouts.log line naming the step and the reason.
2. Fatal-line fast abort: when the child prints a line matching a short shared list (start with "Jolt Physics job system exceeded", "Out of memory", "Assertion failed", and the same error line 50 times with no other output), kill the tree within 15 s, exit 124, reason logged.
3. Solo claims: a single solo claim may last at most PC_GPU_SOLO_MAX_S (default 1200 s); a bench that genuinely needs longer sets it explicitly in its own step. This is per claim, not per job: a perf job with many timed sessions claims solo once per session.
4. Per-step caps in ship_job.bat and tools/recipe/*.bat sized to the step (suggested: import 900, checks and shots 600, stages 4, 6, 7 1800, stage 5 bake 3600), each named in one place.
5. Raise the default PC_GPU_WAIT_SECONDS in codex_issue.bat and work_issue.bat to 1800 (ship_job keeps 3600).
6. Never lose work: a kill writes what it can of the child's log first; nothing in the repo or out folder is removed.
7. Tests (runner_stall_tests.js): a fake child that goes silent is killed within a short test idle limit; one that prints the Jolt line is killed at once; a solo claim over its cap is ended; the GPU slot is released only after the tree is verified gone.


---
_Generated by [Claude Code](https://claude.ai/code)_