# Codex job: issue #1192, "PC jobs: inner stall watchdog, fatal-line abort, per-step caps (hung GPU steps)"

You are Codex, working one job from the Voidsworn job board (github.com/rcbailey12/voidsworn/issues/1192).
This folder is a fresh checkout of main on the branch codex/issue-1192. Follow AGENTS.md and CLAUDE.md in this folder.
Base already merged by the runner: origin/main (8cf0e800a3c7fb305ec51387fc1586e39d0b0ac1). The merge is committed; do not merge it yourself.

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

## THIS IS THE JOB NOW: run 2 brief (Board, Nov 19 2026, 19:00 UTC)

Run 1 is PR 1200 at 9557ecc1. The outside review found no early claim release, but several ways it can kill healthy jobs. Fix on the same branch; Base main (main now has PR 1173, which edits tmo.bat and four recipe stage files: merge it and keep both). PR 1198 (issue 1193) also edits run_timeout.ps1; if it has merged by the time you run, merge it too.

1. **Fatal lines: Jolt only by default.** "Out of memory" and "Assertion failed" are fatal in every wrapped step, including run_all_checks, where tests print them on purpose. Keep only the Jolt job-system line as a default fatal pattern. Any other pattern is opt-in per step (an env var or an argument), and none is set for check runs.
2. **No stop on repeated error lines.** Drop the 50-identical-lines rule (runs that used to pass noisily would now die), or make it opt-in and unset everywhere.
3. **Solo cap.** Solo claims die at 1200 s and no bench file sets PC_GPU_SOLO_MAX_S, while the scene gate has 2400 and 1800 ceilings. Default the solo cap to the step's own cap (no separate 1200 s), and keep PC_GPU_SOLO_MAX_S as an override.
4. **Admission under the stall limit.** The 1800 s admission default for Codex and work runners equals the agents' 30 minute stall limit. Make it 1500 s.
5. **Unkillable child.** If the tree cannot be killed, log the surviving PIDs every minute and keep the claim (do not loop silently), and end the step with a clear line in the log.
6. **Import cap.** Check the 900 s import cap against a first Godot import on the PC (the board
epo log of the last fresh import says how long it took); set the cap to at least twice that.
7. Keep the PR body to "Refs #1192".