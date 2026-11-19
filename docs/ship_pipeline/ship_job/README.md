# The shared ship job and the A16 fixture in CI (issue 1174)

Why (Board, Nov 19 2026): Ryan, 15:51 UTC: "I'm getting a lot of failed GitHub pushes emails too". From 14:00 to 15:51 UTC 8
check runs failed on helper branches; 6 of them only because the A16 death fixture record was stale after a shared kit edit.
The same sweep found runners that took ship pictures after a failed build (C12 in PR 1165, C13 paint in PR 1167, S9's first
run), and three helper jobs (1155, 1157, 1158) failed a stage when GPU admission gave up after 300 seconds.

What Ryan will see: far fewer failed-check emails, and no ship picture that came from a failed build.

## 1. The shared ship job: `tools/pc/jobs/ship_job.bat`

Every helper's ship run is now three lines. The wrapper sets the inputs and calls the shared copy:

```bat
@echo off
set "SHIP=voidsworn_S10" & set "CODE=V16_37" & set "BRANCH=opus/issue-1157" & set "JOB_DIR=opus1174"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
```

Optional inputs go on the second line the same way: `STAGES` (default all seven, `1_concept_in` to `7_export`; a front run
sets `"STAGES=1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit"`), `SETS` (a4_shots sets, default `battle,close`), `FACS`
(default the part of SHIP before its first underscore), `PAINT_BASE` (a branch merged in after the checkout; the pictures are
then a labelled PREVIEW of that paint stack) and `PC_GPU_WAIT_SECONDS` (default 3600).

What it does, in order (each step's exit code goes to `JOB_DIR\out\result.txt`, each log to `JOB_DIR\out\log_<step>.txt`):

1. Runs from its own copy, `JOB_DIR\ship_job_running.bat`: cmd reads a .bat as it goes, so a checkout must never rewrite the
   file that is running.
2. Refreshes `Downloads\voidsworn_test\repo-mirror.git` under the same lock as the PC runner. A fresh
   `JOB_DIR\repo` uses `git clone --local`, which hardlinks Git objects on the same drive. The job fetches `BRANCH`
   and optional `PAINT_BASE` from the refreshed mirror. Every tracked change in the clone is listed and saved first
   (`out\clone_changes_before_checkout.txt` and `.patch`). A tracked change outside `godot/assets/ships/` (a hand fix left
   in the clone) stops the job with nothing reset. Only `godot/assets/ships/` (what stage 7's install writes, manifest.json
   among it) is restored from the clone's own commit. Tracked `godot/**/*.import` files, which the headless import rewrites (Nov 19: the S9 rerun stopped on 18 of them), are restored the same way after the patch is saved. The checkout itself is never forced and refuses to overwrite untracked
   or ignored files (`--no-overwrite-ignore`), so a local file the branch now tracks stops the job instead of being replaced
   (Artoo on PR 1179, two rounds). Then `PAINT_BASE` merged if set (a failed merge is aborted
   and stops the job), then a `commit=` line.
3. The headless import, then each stage in its own cmd, logged with its exit code. A failed stage skips every later stage.
   Stage 7 installs into the clone's own godot folder, never into Ryan's game.
4. The installed glb must be this run's: written after the run started. An older one counts as a failed install.
5. The GPU readback, the authored interiors check and the death seam check on the installed glb. All three must pass (the old
   S10_RUN_1157.bat let a failed death seam through to the shots).
6. The in-game shots at camera 170 and 60, only when everything above passed.
7. Collects deliverables into `out\recipe` on a pass or a fail. It copies `*.txt`, `*.json`, `*.md` and `*.jpg`,
   the review images from `clay`, `r`, `close`, `surface`, `godot`, and `shots` or `shots_*`, and the requested
   `export\<CODE>\` folder. In-game shots still go straight to `out\shots`.

Blender files, loose PNG bake maps, other export codes, the `godot\proj` cache, `sil\`, and `b0.npz` stay under
`Downloads\voidsworn_test\recipe\<SHIP>` for reruns and diagnosis.

The last two lines of `result.txt` are always `done PASS` or `done FAILED: <step>`, then `all done`.

An earlier run's `out` folder is renamed `out_before_<time>`. The newest two backups are kept off the janitor list.
Older backups are recorded by full path in `out\out_before_for_janitor.txt`. All backup files stay on disk until the
janitor can establish that the older files also exist in newer output. Every GPU step waits up to 3600 seconds for its claim, the
most gpu_slots.js accepts (waiting never spends a command's time limit). The stages and tmo.bat run from the ship branch's own
checkout, so a longer cap would only work once every ship branch carries it (Artoo on PR 1179: the S10 head rejects 21600).

Two runs of the same SHIP at once share `recipe\SHIP` and would overwrite each other, as before: the Board queues one at a time
per ship.

Static test: `contrib/opus/tools/ship_job_tests.js` (in the standing checks, fast): the FAILED guard after every step that
can fail and right before the shots, all three checks counted, the installed glb's age checked before the checks, the 3600
default before the first GPU step, `done` then `all done` on every way out, no delete or move, logs only under `out`,
the mirror refresh and local clones, the deliverable filters, the two backups protected from the janitor list, and every
wrapper in `wrappers/` three lines long. Removing a guard line or the death seam's CHECKFAIL line makes it fail.

`tools\pc\jobs\look_bench.bat` uses the same mirror for its separate tool and game checkouts. It refreshes the mirror
once per launch, then fetches from it into both checkouts, including when reusing existing clones.

### The proof port: S10 (issue 1157)

`wrappers/OPUS1157_S10_RUN.bat` is S10_RUN_1157.bat as a wrapper. Step for step:

| S10_RUN_1157.bat | ship_job.bat |
|---|---|
| clone `opus1157\repo` depth 1, check out opus/issue-1157 | own clone from the shared mirror, full history for PAINT_BASE, same branch |
| import, exit logged, not checked | import, a failure stops the job |
| stages 1 to 7 in a fresh cmd, a failed stage skips the rest | the same |
| (no check that the install is this run's) | the installed glb must be newer than the run's start |
| readback and interiors gate the shots; death seam logged only | all three gate the shots |
| shots at 170 and 60, `--facs voidsworn --sets battle,close` | the same (FACS from SHIP, SETS default) |
| recipe copied to `out\recipe`, export glb present | deliverables copied to `out\recipe`, export glb present |
| last lines `done` or `done FAILED`, `all done` | `done PASS` or `done FAILED: <step>`, `all done` |
| GPU wait: whatever the launcher set (300 s unless set) | 3600 s by default |

The proof wrapper uses `JOB_DIR=opus1174`, so it never touches 1157's own clone or out folder. It does rebuild
`recipe\voidsworn_S10`, so queue it only when 1157 is not running. Not run on the PC from this thread (R334): the Board queues it.

### For the Board: putting it on the PC and the LOOP note

The shared copy lives at `Downloads\voidsworn_test\ship_job\ship_job.bat`. After a merge that changes
`tools/pc/jobs/ship_job.bat`, copy main's file there (one `device_commit_files`; a running job is safe, it runs its own copy).

LOOP.md PC notes line to add (after the R334 line):

> - Ship build runs use the shared job (issue 1174): a helper's OPUS<N>_RUN.bat is three lines (`@echo off`; one `set` line
>   with SHIP, CODE, BRANCH, JOB_DIR and any of STAGES, SETS, FACS, PAINT_BASE; `call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"`),
>   docs/ship_pipeline/ship_job/README.md. It stops after a failed stage, shoots only this run's checked install, waits 3600 s
>   for the GPU, and ends "done PASS" or "done FAILED: <step>", then "all done". The Board refreshes the shared copy after
>   each merge that changes it.

## 2. The A16 fixture in CI

`sheet_fixture_hash.py --check` hashes the files that make A16's geometry, and seven of them are shared kit files (kit.py,
export7.py, contract.py, variants.py, gamedata.py, shared hardpoints.py and turrets.py). Every cohesive shared kit fix (R333)
made the record stale, and two places failed on that alone: the "A16 death fixture is fresh" step and `death_seam_check.gd`
in the list step (it checks the same record when it runs on the fixture).

The design (the Board's pick, kept because it is the smallest one that still tests the seam on the geometry the branch
really makes): `checks_a16_fresh_bake.patch` (the Board applies it; workers never edit `.github/workflows`).

- A new job, "A16 death seam (fixture or fresh bake)", owns the seam check. It runs beside the Godot game checks, so the
  Blender download never eats into that job's 30 minute limit; `godot_checks.txt` marks `death_seam_check.gd` `step:` so the
  list step no longer runs it a second time. The old step (d) is removed.
- Fresh record: the seam check runs on the committed fixture, as before.
- Stale record (`--check --quiet-stale` exits 3): pinned Blender 4.5.14 for Linux is fetched (cached by version), A16 is
  baked with `--bake BLENDER --out $RUNNER_TEMP/a16` (the committed fixture is never touched), and the seam check runs on
  that bake. A clean seam passes, with "fixture record stale: refresh before merge" in the step summary. A seam failure on
  the fresh bake fails.
- A broken record (missing or unreadable fixture, exit 1) still fails: a rebake alone would not repair it.

Why not the alternatives: dropping the shared files from the hash would let a real kit change reach the seam check untested;
rebaking on the PC for every shared kit edit is the queue cost we are removing; a warning-only stale check would stop testing
the seam on the branch's geometry at all.

The record still has to be refreshed before merge (the summary says so). The Board can do that on the PC as before
(`--bake` without `--out`), or later from this same CI bake if it wants one.

`sheet_fixture_hash.py` changes: `--out DIR` (bake into DIR, leave the committed pair alone) and `--quiet-stale` (exit 3 for a
stale record only). Its selftest covers both.

### What was run here (cloud, Godot 4.7.2.stable.official.ed1daf0bf, Linux)

download.blender.org is blocked from this cloud container, so the bake here used the `bpy` 4.5.14 wheel from PyPI through a
small stand-in for `blender -b ... -P script -- args`. GitHub's runners reach download.blender.org; the real Blender path in
the patch has not run yet and runs on the first push after the Board applies it.

- `sheet_fixture_hash.py --check` on main: PASS. `sheet_fixture_hash_selftest.py`: PASS (both groups).
- Bake into a temp folder: 5 s, `BAKED .../C19_51_unbaked.glb.gz`; the committed fixture unchanged.
- `death_seam_check.gd` on that fresh bake: exit 0, `machines_split=0`, `inside_outside_hull=0`, `failures=0`, no SCRIPT ERROR.
  The same numbers as on the committed fixture.
- A stale record (an A16 input edited): `--check --quiet-stale` exit 3, bake exit 0, seam exit 0.
- A real seam break (the cutter told to ignore the machine boxes, `fx_death.gd` line 1018, reverted after): seam check on the
  fresh bake exit 1, `machines_split=10`, `failures=1`. So a seam break on the fresh bake still fails the job.
- The patch: `git apply --check` clean on main at b3cec823; the changed workflow parses as YAML.

## 3. gpu_slots_tests

The flake (run 44549955914, Nov 19 15:02 UTC): `gpu_slots_tests.js:159` expected "admission timed out" and got "GPU slot lock
timed out". Cause: the lock loop read the clock twice; when the admission check read it just before the deadline and the
lock's own reading landed on it (a timer can wake a fraction of a millisecond early), the lock's message won. Fixed in
`tools/pc/gpu_slots.js`: past the deadline, the loop runs the admission check once more, so it always reports the admission
timeout. The admission wait moved into `admit()` with an injectable clock, and the three one-second timeout tests (go gate
closed, busy slot lock, pending solo) now run on a fake clock that moves only when the code sleeps: no wall-clock race. One
more test pins the exact race (the check reads 999, the lock reads 1000). `gpu_slots_runs.txt` holds the 20 runs in a row.

## 4. Runner hashes (gpu_slots.js changed)

`tools/pc/gpu_slots.js` is one of the nine runner files that `runner_common.ps1 hashcheck` compares with the Board's
`work217\runner_hashes.txt`. That list lives only on the PC (written by `hashwrite` after a copy; nothing in the repo holds
it), so this PR cannot ship it. After merge, when the Board copies main's runner files to each lane's tools folder, run
`hashwrite` as usual; the new line for this file (LF endings, as `.gitattributes` checks it out) is:

```
3764e59dcf73b83f56103db89b4d8dad9ab94c4fc87651a778912d5b83277d73  gpu_slots.js
```

The other eight runner files are unchanged by this PR.
