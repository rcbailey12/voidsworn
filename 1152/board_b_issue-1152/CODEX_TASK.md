# Codex job: issue #1152, "Ship pipeline: safe speed fixes from the GPU audit"

You are Codex, working one job from the Voidsworn job board (github.com/rcbailey12/voidsworn/issues/1152).
This folder is a fresh checkout of main on the branch codex/issue-1152. Follow AGENTS.md and CLAUDE.md in this folder.
Base already merged by the runner: origin/codex/issue-1152 (f9bb494863aab518543e33a77b2351114a5a7751). The merge is committed; do not merge it yourself.

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
- Save review pictures and their .provenance.json sidecars in C:\Users\rcbai\Downloads\voidsworn_test\board_b\issue-1152\shots (create it). Link them as shots/<file> so the
  runner can copy them into docs/shots/issue-1152-codex and rewrite the links before publishing.
- Link pictures already in the checkout by repo-relative path, and keep every picture link relative.
- Finish with a short report: what you changed (files), the checks you ran and their result, anything you skipped and why.
  That report becomes the pull request description, so write it for a reviewer.

## The job

Owner: codex
Brief: below; the outside audit is summarised here (Ryan's upload, Nov 19, checked by the Board against main eb9094e2)
Deliver to: tools/blender/kits/shared/paint_stack.py, tools/blender/build_sheets/build.py, tools/blender/build_sheets/paint_sheet.py, tools/blender/r209/*.py (device setup only), tools/pc/gpu_slots.js and tools/pc/tmo.bat with their tests, tools/recipe/4_parts_kit.bat, 5_paint_bake.bat, 6_lod.bat, 7_export.bat, tools/recipe/export7.py, contrib/codex/pipeline_1119/README.md
Branch: codex/issue-1152
Base: codex/issue-1152
Effort (Codex): high
Done when: one sheet ship (C19_51) goes through stages 4 to 7 on this branch and on main, the README gives each stage's time and the Cycles device line from both runs, the two concept-camera renders sit side by side in contrib/codex/pipeline_1119/ and look the same, the CPU-only Blender steps show no GPU claim in their logs, and the standing and Godot game checks pass. What Ryan will see: the same ship pictures, made faster, with two lanes no longer queueing behind each other for steps that never touch the GPU.

## THIS IS THE JOB NOW (Board, Nov 19 2026, 16:15 UTC): prove the speed fixes in game, and finish the PNG switch

Why. The first run pushed PR 1173 but its own checks did not pass. The Fable reviewer (16:05, on f9bb4948): the "looks the same" picture is the Blender render made before export, so the JPEG to PNG map switch has no in-game before and after; tools/pc/jobs/check_damage_surface.bat and check_squadrons.bat copy only *.jpg and would drop the new PNG maps; the PR gives no size numbers for the PNG maps (the PC disk is under its floor today); stages 6 and 7 measured slower because of GPU waits, not faster. The Godot game checks are red because export7.py changed and the A16 fixture record hashes it (Artoo, 14:56).

1. Claim first. Rebake the A16 fixture with python tools/recipe/sheet_fixture_hash.py --bake on the PC Blender and commit the fixture and its record, so the game checks pass on this branch.
2. In-game before and after for C19_51: install main's export and this branch's export into two isolated copies (never the shared build), take a4_shots battle and close for C19_51 in each, and put them side by side (one picture per camera, code name on each, no taller than 720 px).
3. Every PC job that copies baked maps copies the PNG maps too (check_damage_surface.bat, check_squadrons.bat, and any other *.jpg copy you find with a search); list them.
3b. tools/recipe/manifest_merge.py still accepts only `<code>_*.jpg` map names (lines 96 and 135), so a ship exported with the new PNG maps cannot install (outside triage, Nov 19 16:02). Accept the `_normal.png` and `_orm.png` names too, with a test that installs a PNG-map export and still rejects a stray name.
3c. Stage 7 export7.py took 36.8 s against 14.4 s before (resize_atlas plus PNG encoding). Time stage 7 alone, with nothing else on the PC GPU, and say whether the PNG step is the cause; if PNG encoding costs more than about 10 s per ship, use a faster PNG setting (compress_level) and report both numbers.
4. Report the map sizes on disk before and after for C19_51 and per ship on average, and the stage timings with the GPU wait split out from the work time.
5. Do not touch .github/workflows. Commits say "Refs #1152".