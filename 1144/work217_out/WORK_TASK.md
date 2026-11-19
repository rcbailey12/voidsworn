# Workhorse job: issue #1144, "Truth pass: previews and text that match the rules, with checks"

You are the coding seat on the Voidsworn job board (github.com/rcbailey12/voidsworn/issues/1144), doing the job Codex used to do.
This folder is a fresh checkout of main on the branch work/issue-1144-deepseek. Follow AGENTS.md and CLAUDE.md, except the
"work in your own folder" rule: you are the main coding seat for this job, so edit the game files the job names.
Nobody is watching this run and nobody can answer questions. Make the sensible call, say what you chose in your report, and keep going.
Base already merged by the runner: origin/work/issue-1144-openai (0116d6a48984da8dfee78f47b6064fc410c654de). The merge is committed; do not merge it yourself.

Rules:
- Do exactly what the job below asks. Change nothing else. Read the brief it names first.
- No em dashes in anything you write. Plain words, plain ASCII.
- Do not commit and do not push: the runner does that after you finish.
- The runner handles Base and resume merges before you start. Do not run git merge; report a missing base in your report.
- GPU work must use tools/pc/tmo.bat <seconds> <exe> [args]. Shared capacity comes from Downloads\voidsworn_test\gpu_slots.json (default 2).
  Captures weigh 1, Blender weighs 2; set PC_GPU_WEIGHT=2 for other heavy bakes, or the Board's chosen weight;
  frame-time scripts take solo automatically. For a new timing script set PC_GPU_MODE=solo before calling tmo.bat.
  gpu_go.txt must say GPU cleared. Lane C is code only. Never launch GPU executables directly.
- Keep scratch output (logs, temp files) out of this folder, in the system temp folder.
- Save review pictures and their .provenance.json sidecars in C:\Users\rcbai\Downloads\voidsworn_test\work217\issue-1144-deepseek\20261119_091640\out\shots (create it). Link them as shots/<file> so the
  runner can copy them into docs/shots/issue-1144-deepseek and rewrite the links before publishing.
- Link pictures already in the checkout by repo-relative path, and keep every picture link relative.
- Finish with a short report: what you changed (files), each check you ran and its result (paste the PASS or FAIL lines),
  anything you skipped and why. Your report goes at the top of the pull request description; the runner runs the standing
  checks and parity itself after you stop and adds their real rows under it, so write it for a reviewer.

Before you finish, check how your change reaches the rest of the game (the reviewer checks all five, so do it first):
- Callers: search the whole repo for every function, constant and save field you changed or added, and check or fix each use.
- Saves: a player profile or run save written before your change must still load and behave; say how you checked.
- Twins: rules that live in both the JS root files (battle.js, data.js and core.js) and the Godot port must change on both sides. The root files are the only copy (the oracle folders were deleted in PR 381). If you change one of them, re-export both tables (godot/rules/data/tables.json and godot/campaign/data/campaign_tables.json) and run contrib/opus/tools/oracle_copy_test.js last; rules parity and campaign parity prove the two sides match.
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

Owner: codex
Brief: below; the review "Embers: what would most improve the game" (Finding 2, approved by Ryan Nov 19 12:45 UTC, R328); tools/test_onboarding.js; godot/scenes/battle/battle.gd (_target_info, lines about 4991 to 5001); godot/rules/rules.gd (_expectedVs_raw, line about 2899); godot/campaign/campaign.gd (the reinforcement at line about 3361); godot/ui/campaign/campaign_ui.gd (Placeholder mastery text, line about 1818; the Nemesis "ADAPTED TO YOU" banner, line about 1856); campaign_run.js and data.js only if parity needs the same rules fix
Deliver to: the files above that each fix needs, the new checks under godot/**/test/ with their lines in godot/tools/ci/godot_checks.txt, contrib/openai/truth_pass_1119/README.md (and the checks.yml patch as text, since runners may not edit workflow files)
Branch: work/issue-1144-deepseek
Base: work/issue-1144-openai
Effort: DeepSeek workhorse (deepseek arm), cap 10800 s; run 1 was the OpenAI seat
Done when: the onboarding test passes and a patch adds it to the checks; a new preview-versus-result check fails on today's main and passes after the fix; each item below is fixed or explained with a test where one fits; rules parity, the standing checks and the Godot game checks pass. What Ryan will see: the damage preview matches what a volley does, no placeholder text, the right reinforcement for his faction, a Nemesis banner that only promises what happens.

## THIS IS THE JOB NOW (Board, Nov 19 2026, 15:25 UTC): run 2, shield routing only on landed hits in the preview

Base work/issue-1144-openai (run 1, PR 1162). One exact fix in the volley preview; nothing else changes.

Artoo (PR 1162, technical): the new preview applies shield routing after any positive expected drain (godot/rules/rules.gd, the preview recurrence near lines 2948 to 2961), but in combat routing follows an actual landed hit (near lines 2979 to 2981). Worked case: four independent 30 percent hit shots, each strong enough to fill the facing, a 60 point pool with 25 percent starting coverage: combat absorbs 19.14 shield on average, the preview says 23.4, so the card moves damage from hull to shields.

1. Make the preview's expected shield and hull match combat's own rule: routing happens only on a landed hit. Compute the expectation over the hit and miss branches (or an exact equivalent); do not change combat.
2. Extend godot/scenes/battle/test/volley_preview_test.gd with a low-odds, high-pool case (Artoo's numbers above) that fails on run 1's code and passes after the fix, beside the existing 85 percent cases, which must still pass. Compare against seeded volleys as run 1's test does.
3. Rules parity, the standing checks and the Godot game checks pass. The README in contrib/openai/truth_pass_1119/ gets a run 2 section with the before and after numbers.