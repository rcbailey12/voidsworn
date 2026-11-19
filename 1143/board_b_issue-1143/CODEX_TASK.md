# Codex job: issue #1143, "Record the first three battles the way a player sees them"

You are Codex, working one job from the Voidsworn job board (github.com/rcbailey12/voidsworn/issues/1143).
This folder is a fresh checkout of main on the branch codex/issue-1143. Follow AGENTS.md and CLAUDE.md in this folder.
Base already merged by the runner: origin/main (0b82eaa0e43c43d822b2db72b08404fb890dbc91). The merge is committed; do not merge it yourself.

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
- Save review pictures and their .provenance.json sidecars in C:\Users\rcbai\Downloads\voidsworn_test\board_b\issue-1143\shots (create it). Link them as shots/<file> so the
  runner can copy them into docs/shots/issue-1143-codex and rewrite the links before publishing.
- Link pictures already in the checkout by repo-relative path, and keep every picture link relative.
- Finish with a short report: what you changed (files), the checks you ran and their result, anything you skipped and why.
  That report becomes the pull request description, so write it for a reviewer.

## The job

Owner: codex
Brief: below; the review "Embers: what would most improve the game" (Finding 1, approved by Ryan Nov 19 12:45 UTC, R328); godot/scenes/battle/battle.gd (the mode switches at lines about 186 to 200, 202, 615, 1820, 2815, 4173, 5047, 5081), godot/main/main.gd (option defaults), bench/scene_gate.gd (line about 694, mesh_lod_threshold), .claude/skills/screenshot-verdict/SKILL.md, docs/RULEBOOK.md section 12
Deliver to: the player-path recording mode (godot/ where the mode lives, plus tools/pc/jobs/player_path.bat), docs/shots/player_path_1119/ (README, clips, one contact sheet per battle), docs/RULEBOOK.md (a new rule in section 12), .claude/skills/screenshot-verdict/SKILL.md, contrib/codex/player_path_1119/
Branch: codex/issue-1143
Base: main
Effort (Codex): xhigh
Done when: Battles 1 to 3 of a new Sunward run are recorded on the shared installed build with every player default on, once against each Sector I enemy (Ashfall Hullbreakers and Hegemony Navy), each clip stamped with the commit, build hash and manifest hash; the README lists what a player sees that no earlier capture showed; RULEBOOK and the screenshot-verdict skill make this recording the acceptance check for visual and teaching work. What Ryan will see: his own first three battles as a new player sees them.

## THIS IS THE JOB NOW (Board, Nov 19 2026, 14:50 UTC): run 2, commit first, then record

The first run recorded both Sunward runs (seed 10 and seed 121, all three battles won, 18 clips, six contact sheets), but the runner refused to push: the pictures were made from a build exported from uncommitted work, so their provenance stamps say "working-tree state" (tools/picture_provenance.py, issue 889). Nothing was committed or pushed. That run's uncommitted work survives in this lane's newest repo-kept copy (the next run's result.txt names it); reuse its files rather than rewriting them.

1. Bring over run 1's tools/pc/jobs/player_path.bat, the RULEBOOK 12.6 and screenshot-verdict edits and the README, check them, and **commit them before you export the Windows build**, so every picture and clip is stamped from a clean commit.
2. Artoo (issue comment, 13:53): the normal game host loads and saves campaign and story state in the fixed user:// folder. Make the recorder use its own fresh, isolated profile (the game's real defaults, but not Ryan's saves or settings), and have the README show it neither reads nor writes his normal profile. Also say plainly whether run 1 touched his profile (saves, settings, story state), and if it did, what changed; do not delete or overwrite anything to undo it, report it.
3. Record again as run 1 did (shared installed assets, every player default on), stamp everything, and push. Keep run 1's review notes (the overlapping reinforcement banner, the target tooltip that stays up during a cut-in) if run 2 still shows them.
4. Done when the same as below, plus: every picture and clip passes picture_provenance verify, and the profile isolation is shown.