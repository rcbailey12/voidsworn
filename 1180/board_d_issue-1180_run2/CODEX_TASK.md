# Codex job: issue #1180, "PC disk stays above 150 GB on its own: nightly janitor, wider safe list, cleanup on every job ending (R336)"

You are Codex, working one job from the Voidsworn job board (github.com/rcbailey12/voidsworn/issues/1180).
This folder is a fresh checkout of main on the branch codex/issue-1180. Follow AGENTS.md and CLAUDE.md in this folder.
Base already merged by the runner: origin/main (f39399f00f80b6f362d86d6c8d19f98ebef9199b). The merge is committed; do not merge it yourself.

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
- Save review pictures and their .provenance.json sidecars in C:\Users\rcbai\Downloads\voidsworn_test\board_d\issue-1180\shots (create it). Link them as shots/<file> so the
  runner can copy them into docs/shots/issue-1180-codex and rewrite the links before publishing.
- Link pictures already in the checkout by repo-relative path, and keep every picture link relative.
- Finish with a short report: what you changed (files), the checks you ran and their result, anything you skipped and why.
  That report becomes the pull request description, so write it for a reviewer.

## The job

Owner: codex
Brief: below
Deliver to: tools/pc/ (new janitor files, runner cleanup changes), contrib/opus/tools/ (tests), docs/RULEBOOK.md 3.3
Branch: codex/issue-1180
Base: main
Effort (Codex): xhigh
Done when: the new tests pass in checks; a dry run on the PC lists every cleanup candidate with its size and reason and removes nothing; the Board reads that list before the live run. Ryan sees free space stay above 150 GB without double-clicking a cleanup.

## THIS IS THE JOB NOW: run 2 brief (Board, Nov 19 2026, 17:05 UTC; marker moved 17:50 UTC after PR 1196)

Why. An outside storage audit Ryan shared (Neon, Nov 19 16:58 UTC, pinned at main aa3eae59) found gaps the Board checked in code at main 39e0eed7. Each one below held. Add to run 1's work on the same branch:

1. **godot/gen/ is rebuildable.** tools/pc/get_ship_files.bat copies `build\godot\gen` into every Godot checkout, but Reuse-Caches in runner_common.ps1 only accepts `godot/assets/ships/` (line 262), so every Godot job's checkout fails reuse and is kept. Add `godot/gen/` to the one shared list, checked byte for byte against `build\godot\gen\` the way issue 1107 checks ships. Also `godot/.stage7-replaced-*` and `godot/assets/ships/manifest.bak_*` (left by tools/recipe/manifest_merge.py lines 76 and 125).
2. **work217 run copies.** tools/pc/work_issue.bat makes a new `work217\issue-<N>-<arm>\<STAMP>\repo` per run and work_issue.ps1 removes it only after a checked push with `remove_repo_copy_after_push=yes`. Let the janitor remove finished `work217\*\*\repo` folders under the same checks as repo-kept copies (Git shows only rebuildable files, all history in the mirror, no live lock, untouched 3 hours). Never touch `out\`, runner_settings.txt, runner_hashes.txt or a live run.
3. **Dirty or unreadable kept copies: salvage, check, then remove (R339).** For a repo-kept copy (and a work217 run repo) older than a day that holds real work (tracked edits, untracked non-ignored files, local-only commits), write `voidsworn_test\salvage\<lane>_<name>\` with `salvage.patch` (git diff --binary), `salvage.bundle` (git bundle of local-only commits) and a zip of untracked non-ignored files. Check each one opens and matches (apply the patch with --check against the copy's HEAD in a scratch worktree, `git bundle verify`, list the zip), log the sizes, and only then remove the copy. Ryan, Nov 19 17:01 UTC (decision card): "Yes, after a checked backup". Any check that fails keeps the copy and logs why. Copies Git cannot read are listed and kept. Salvage folders are never removed by the janitor. Write the rule into RULEBOOK 3.3.
4. **stage7-checked temp.** manifest_merge.py line 210 makes `%TEMP%\stage7-checked-<code>-*` and never removes it. Remove it at the end of a successful install, and add `stage7-checked-*` (3 hours untouched) to the janitor's TEMP list.
5. **Private TEMP for helper jobs.** tools/pc/jobs/ship_job.bat and look_bench.bat set `TEMP` and `TMP` to `%TEMP%\voidsworn-run-<id>` (with the `.voidsworn-run-owner` file) so Blender and Godot scratch lands where the janitor can identify it.

6. **Nightly window.** janitor.ps1 --nightly runs whenever the Central clock is past 3 AM, so a watcher started at 2 PM cleans at 2 PM (Fable on PR 1196). Run nightly only between 3:00 and 6:00 AM Central; outside that window exit 0.
7. **Helper folders wait longer.** opus<N> folders go with their out\ folder, and the Board relays results back by hand. Raise their untouched age from 1 day to 3 days.
8. **PR body.** Say "Refs #1180", not a closing word (run 2 is the rest of the job).

Tests for each, in the standing checks. The PC part is still a dry run first; the Board reads the list before any live run.


---
_Generated by [Claude Code](https://claude.ai/code)_