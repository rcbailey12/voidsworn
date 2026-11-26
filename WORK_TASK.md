# Workhorse job: issue #2161, "Dropped-work fixes A: boss objective, Acid Thorns name, rival memory lines, Eclipse embers, title 3D restore, sfx double parse"

You are the coding seat on the Voidsworn job board (github.com/rcbailey12/voidsworn/issues/2161), doing the job Codex used to do.
This folder is a fresh checkout on the branch work/issue-2161-sonnet (main, or its earlier tip with main merged in; see below). Follow AGENTS.md and CLAUDE.md, except the
"work in your own folder" rule: you are the main coding seat for this job, so edit the game files the job names.
Nobody is watching this run and nobody can answer questions. Make the sensible call, say what you chose in your report, and keep going.
Resumed by merging work/issue-2161-sonnet-partial (7aa9458074c36cd5c168f6f36596181afdeb7a98). Inspect and finish this work; do not restart it from main.
Base already merged by the runner: origin/work/issue-2161-sonnet-partial (7aa9458074c36cd5c168f6f36596181afdeb7a98). The merge is committed; do not merge it yourself.

Rules:
- Do exactly what the job below asks. Change nothing else. Read the brief it names first.
- No em dashes in anything you write. Plain words, plain ASCII.
- Do not commit and do not push: the runner does that after you finish.
- The runner handles Base and resume merges before you start. Do not run git merge; report a missing base in your report.
- GPU work must use tools/pc/tmo.bat <seconds> <exe> [args]. Shared capacity comes from Downloads\voidsworn_test\gpu_slots.json (default 2).
  Captures weigh 1, Blender weighs 2; set PC_GPU_WEIGHT=2 for other heavy bakes, or the Board's chosen weight;
  frame-time scripts take solo automatically. For a new timing script set PC_GPU_MODE=solo before calling tmo.bat.
  gpu_go.txt must say GPU cleared. Codex lanes C to F are code only. Never launch GPU executables directly.
- Keep scratch output (logs, temp files) out of this folder, in the system temp folder.
- Save review pictures and their .provenance.json sidecars in C:\Users\rcbai\Downloads\voidsworn_test\work217\issue-2161-sonnet\20261125_205538\out\shots (create it). Link them as shots/<file> so the
  runner can copy them into docs/shots/issue-2161-sonnet and rewrite the links before publishing.
- Link pictures already in the checkout by repo-relative path, and keep every picture link relative.
- Finish with a short report: what you changed (files), each check you ran and its result (paste the PASS or FAIL lines),
  anything you skipped and why. Your report goes at the top of the pull request description; the runner runs the standing
  checks and parity itself after you stop and adds their real rows under it, so write it for a reviewer.

Before you finish, check how your change reaches the rest of the game (the reviewer checks all five, so do it first):
- Callers: search the whole repo for every function, constant and save field you changed or added, and check or fix each use.
- Saves: a player profile or run save written before your change must still load and behave; say how you checked.
- Rules (R405): change Godot and its tables. Reseal edited tables with res://rules/tools/reseal_tables.gd and check the saved Godot results. Keep the browser rules frozen. Follow RULEBOOK 3.1 for the current ship-data exception.
- UI: every screen that shows what you changed (campaign map, intel, panels, HUD) must read the new value the same way.
- CI: a new test file must be added to contrib/opus/tools/run_all_checks.js, or GitHub never runs it; say which checks GitHub runs.
Put one line per item in your report with what you found.

How to run things on this PC (Windows 10; your shell is Git Bash):
- Standing checks: node contrib/opus/tools/run_all_checks.js
- Rules parity and campaign parity (needs Godot, a few minutes): cmd.exe //c "tools\\pc\\parity.bat nopause"
  It prints PASS or FAIL per check; campaign parity runs at the end. Both must PASS. One shell command may run up to
  30 minutes, so run parity in the foreground and wait for it.
- Godot 4 console exe: C:\Users\rcbai\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe
  Before any Godot run that loads scenes, UI or textures, import once: "C:\Users\rcbai\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path godot --import
- Screenshots of the campaign UI: godot/campaign/test/r1_ui_shots.gd is a worked example of a script that builds a campaign
  screen and saves a PNG (run it without --headless so it can capture). Copy its pattern for your own shot script.

## The job

Owner: sonnet
Brief: below
Deliver to: godot/scenes/battle/battle.gd, godot/rules/data/tables.json (names only), godot/audio (one cue), godot/story/data/rival_lines.json, godot/fx/fx_shaders.gd, godot/main/main.gd, godot/audio/sfx.gd, with a focused check for each item
Branch: work/issue-2161-sonnet
Base: work/issue-2161-sonnet-partial
Done when: each of the six items below has its fix and a check that fails before and passes after; All checks is green.

## THIS IS THE JOB NOW (run 1, Board Nov 25 2026; Neon dropped-work audit 2157)

Ryan asked for a check of approved work that never landed (contrib/neon/reviews/dropped_work_1125.md). These six were asked for, then dropped. Fix each one, smallest change:
1. Row 12 (R440, issue 1885): boss fights still say "Objective: break their fleet". In godot/scenes/battle/battle.gd `_objective()` (about lines 6867 to 6886), add a "boss" case worded like the flagship one, so the player is told to destroy the boss.
2. Row 13 (R437, issue 1877): Acid Thorns are still named "Boarding tendrils". Rename the display names `W.tendril` and `FAC_WNAMES.chorus.tendril` in godot/rules/data/tables.json to Acid Thorns. Keep the id `tendril`; names only, no numbers. Godot saved results must still match. Wire the Acid Thorns launch and impact to the existing thorn sound keepers if they exist in godot/audio (contrib/opus/sound/elevenlabs_1877_thorns.json); if none are mastered, say so in the PR and leave the cue unwired.
3. Row 16 (R436 C40, issue 1407): godot/story/data/rival_lines.json lines 79, 83, 186, 189, 289 and 294 still use the old "last time" memory text. Rewrite those memory entries in the updated C40 rival voice (see issue 1407 and PR 1880).
4. Row 20 (R412 Wave 1B, Artoo on PR 1736): godot/fx/fx_shaders.gd around lines 458 to 460 (`k == 19`) mixes warm yellow-white `vec3(1.0, 0.85, 0.5)` into Eclipse impact embers. Keep Eclipse embers violet-white (R372, RULEBOOK 10.9).
5. Row 32 (Artoo on PR 2154): godot/main/main.gd `_free_after_title_draws` (about lines 803 to 840). Leaving the title before its first draw can leave `vp.disable_3d = true`. Make every exit path restore the 3D setting, and extend godot/main/test/retire_scene_check.gd for the draws == 0 exit.
6. Row 33 (Artoo on PR 2010): godot/audio/sfx.gd parses cues.json and clips/index.json in `prefetch()` (lines 105 to 110), then again in `_load_catalog()` (lines 164 to 174). Parse once and reuse.
Rules in Godot only (R405). Commits say "Refs #2161". No em dashes.


---
_Generated by [Claude Code](https://claude.ai/code)_