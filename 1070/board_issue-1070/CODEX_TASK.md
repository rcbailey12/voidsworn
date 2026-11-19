# Codex job: issue #1070, "Performance pass: find where the frame goes and win back room (fitted shield, ships, storm, large battle)"

You are Codex, working one job from the Voidsworn job board (github.com/rcbailey12/voidsworn/issues/1070).
This folder is a fresh checkout of main on the branch codex/issue-1070. Follow AGENTS.md and CLAUDE.md in this folder.
Base already merged by the runner: origin/main (0c41f332c956040112361444597d02be99a40b75). The merge is committed; do not merge it yourself.

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
- Save review pictures and their .provenance.json sidecars in C:\Users\rcbai\Downloads\voidsworn_test\board\issue-1070\shots (create it). Link them as shots/<file> so the
  runner can copy them into docs/shots/issue-1070-codex and rewrite the links before publishing.
- Link pictures already in the checkout by repo-relative path, and keep every picture link relative.
- Finish with a short report: what you changed (files), the checks you ran and their result, anything you skipped and why.
  That report becomes the pull request description, so write it for a reviewer.

## The job

Owner: codex
Brief: below; tools/pc/jobs/bench207_scene_gate.bat, bench207_scene_gate_repeat.bat, bench207_scene_gate_res.bat (scene 207, the 20-ship gate), docs/shots/storm_cost/ (README and frame_times.md: the storm optimisation of PR 994, the dense-storm fixture and its method), PR 1060's shield numbers (fitted 11.92 ms, egg 10.06 ms at 1080p, one session of each over 12.5), godot/project.godot (anti_aliasing/quality/msaa_3d and the other rendering settings), godot/fx/fx_ship.gd (_build_shield, _shield_skin), godot/fx/, godot/world/world_living.gd (fog, dust, storm), godot/render/, RULEBOOK 3.4 (GPU slots; frame-time work claims the GPU solo; gpu_go.txt wins)
Deliver to: the code fixes in godot/ (fx, battle and render scripts), contrib/codex/perf_1118/run2/ (README with the before and after numbers, the raw runs), docs/shots/perf_1118/run2/ (the identical-look proof sheets)
Branch: codex/issue-1070
Base: main
Effort (Codex): xhigh
Done when (run 2): on run 1's baseline method, the first shield hit and first death on a cold start each peak under 50 ms at 1080p Max (run 1: 168 and 205 ms), the scene 207 worst frame over three sessions stays under 50 ms, frame medians are no worse than run 1, and the look is identical at radius 170 and 26. What Ryan will see: one short before-and-after list of the stutters, and one proof sheet showing the look did not change.

## THIS IS THE JOB NOW (Board, Nov 19 2026, 15:10 UTC): run 3, re-time on main and set the cost baseline

Base main. Run 2 met its targets (first shield hit 167.8 to 8.0 ms, first death 205.5 to 12.9 ms, scene 207 worst frame 206 to 40 ms at 1080p), but the Board took 1130's content-keyed shield skin cache over run 2's per-battle cache when merging, so the first shield hit was never re-timed on main.

1. On main, cold start, same set-ups as run 2: time the first shield hit, the first death and scene 207's steady and worst frame. If the first shield hit is above 20 ms, find why and fix it without a look change.
2. Answer run 2's open storm item if it is still open: High must never cost more than Max for the same look as today's High.
3. Write the numbers into docs/shots/ (the run 2 folder's README, a run 3 section) as the cost baseline that the three Opus prototypes (1077 flagship death, 1078 shield failure, 1079 nebula wake) measure against. GPU timing solo (R293).