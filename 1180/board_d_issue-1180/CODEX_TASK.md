# Codex job: issue #1180, "PC disk stays above 150 GB on its own: nightly janitor, wider safe list, cleanup on every job ending (R336)"

You are Codex, working one job from the Voidsworn job board (github.com/rcbailey12/voidsworn/issues/1180).
This folder is a fresh checkout of main on the branch codex/issue-1180. Follow AGENTS.md and CLAUDE.md in this folder.
Base already merged by the runner: origin/main (163c91a7e97cfe0801344310e9b67ebdfa9a2e40). The merge is committed; do not merge it yourself.

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

## THIS IS THE JOB NOW: run 1 brief (Board, Nov 19 2026)

**Why.** The PC disk keeps filling (about 350 GB lost in one busy day, Nov 19: 392 GB free after the Nov 18 cleanup, 41 GB the next morning). Every job takes its own full copy of the repo (code, Godot import cache, ship files, 2 to 10 GB each). Today a copy is removed only after a checked push (RULEBOOK 3.3, issue 1108), so timeouts, kills, failed runs and stray files leak copies forever. Ryan has run two cleanup .bat files by hand in two days.

**Ryan's ruling R336 (Nov 19, 16:30 UTC, Board thread).** He agreed to: an automatic nightly cleanup that may remove any job's leftovers (not only its own) under the same safe rules; an extra run whenever free space drops under 150 GB; a wider list of files that count as rebuildable; cleanup on every job ending. There is no second drive, so nothing moves off C:.

**Build these four things.**

1. **A janitor** (`tools/pc/janitor.ps1` plus a `janitor.bat` wrapper). Same safe rules as the hand cleanup the Board wrote on Nov 19 (copy below), with sizes logged:
   - `repo-kept-*` in `board`, `board_b`, `board_c`, `board_d`: keep the newest in each lane folder, remove older ones only when Git status shows nothing but rebuildable files AND all local history is in the mirror (reuse the checks in `Can-ReuseRepo` / `Get-RebuildableRepoFiles` in runner_common.ps1, do not write a second copy of them).
   - Widen the rebuildable list (shared with the runner's reuse check, one list in one place) to also cover the ignored files that kept 26 of 42 copies on Nov 19: campaign test outputs under `godot/campaign/test/` that the tests regenerate (check the exact ignored paths: golden and log outputs), `*.uid` under `godot/audio/build/`, and `.onboarding_checks/`. Anything tracked, staged or untracked-not-ignored still keeps the copy.
   - Runner scratch `voidsworn-run-*` (it carries `.voidsworn-run-owner`) whose job is not running (its issue lock is free), untouched for 3 hours, pass or fail.
   - Job scratch in `%TEMP%` named `voidsworn*`, `issue*`, `tune2-*`, untouched for 3 hours (newest file inside, not just the folder date), and not for an issue whose lock is held. Parity copies `voidsworn-parity-*` the same way.
   - Helper folders `opus<N>` and `opus<N>out*` in voidsworn_test with no file newer than 1 day.
   - Never touch: any live `repo`, `build*`, `work217`, `repo-mirror*.git`, `recipe`, `runner_backups`, anything else in voidsworn_test, anything outside voidsworn_test and `%TEMP%`.
   - A folder it cannot fully remove (in use) is logged and left; never retried in a loop.
   - Writes `janitor_<yyyymmdd-HHmm>.txt` in voidsworn_test: free space before and after, each folder with size, reason and kept/removed, then a final `all done` line. Exit code 0 even when some folders were in use.
   - `--dry-run` lists the same decisions and removes nothing.
2. **When it runs.** (a) Nightly at about 3:00 AM Central, from the existing queue watcher (no new Windows scheduled task; Ryan should not have to set anything up). (b) At each runner start, when C: is under 150 GB free, run the janitor first (at most once an hour across all lanes, use a lock file) and then do the existing 60 GB floor check. Put 150 next to `min_free_gb` in runner_settings.txt as `janitor_free_gb=150`.
3. **Runners clean on every ending.** After a failed, timed-out or cancelled run, once its out\ logs and result.txt are written, remove that run's own scratch, except keep the newest failed scratch per issue for one day (for a retry). A pause still removes nothing (RULEBOOK 3.11).
4. **RULEBOOK 3.3** edit landing R336 (replace the "after a checked push" paragraph; keep the Why line and add the Nov 19 numbers), and a FINDINGS-ready line in the PR body (the Board commits FINDINGS).

**Tests.** Extend `contrib/opus/tools/runner_cleanup_tests.js` (or a new `janitor_tests.js` wired into the standing checks): a kept copy with only the new rebuildable files is removed; one with a hand edit, a staged file or an untracked file is kept; a copy with a local commit missing from the mirror is kept; scratch for a running issue is kept; a folder touched 2 hours ago is kept; dry run removes nothing; the never-touch list is never a candidate. Run `tools/pc/runner_selftest.js` too. Runner files are hashed: list the new hash lines for runner_hashes.txt in the PR body (the Board runs hashwrite).

**Do not** delete anything on the PC during this job; the PC run is a dry run only. Do not edit .github/workflows.

**The Nov 19 hand cleanup, for reference** (Board-written, Ryan double-clicked it):
```
SAFE kept copy: git status --porcelain=v1 --untracked-files=all --ignored lines all match
  ^!! (godot/\.godot/.*|godot/[^"]+\.import|([^"]*/)?__pycache__/[^"]+|[^"]+\.pyc|godot/assets/ships/[^"]+|godot/gen/[^"]+)$
kept copies: newest per lane kept, older removed when SAFE
opus<N> folders: no file newer than 1 day
TEMP: voidsworn* | issue* | tune2-* folders older than 3 h, skipping live issue numbers
Result Nov 19: 41 GB to 199 GB free; 173 folders removed; 42 copies kept (13 campaign test leftovers, 10 audio .uid, 3 .onboarding_checks, about 8 with real work, 7 Git could not read).
```


---
_Generated by [Claude Code](https://claude.ai/code)_