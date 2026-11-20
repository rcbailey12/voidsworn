# PC proof jobs from helper threads

Helper threads (Opus workers) never touch Ryan's PC themselves. They write a proof bat and the Board queues it (R334).
This page is how to write that bat so the Board accepts it first time (issue 1303).

## Start from the template

1. Copy `tools/pc/jobs/opus_job_template.bat` to `/mnt/project-files/board/<issue>/pc/<NAME>.bat`.
2. Fill the five lines marked FILL: the job folder name, the GPU label (the issue number), the tools the preflight
   must find, and the pins (`PIN_NEW`, and `PIN_OLD` for a before and after job). Pins are full 40-character commits,
   never a branch.
3. Replace the example step with the job's own steps. Every Godot start is a job_wrap step:
   `set "JW_STEP=<name>" & set "JW_EXPECT=<output>" & call "%JW%" run <seconds> "%JW_GODOT%" ...`
4. Send the path to the Board. Once the Board has queued a bat, it is never edited: a change ships under a new name.

## What the head does for you

`tools/pc/jobs/opus_job_head.bat`, called from the installed main copy in `tools_live` (it refuses to run from
anywhere else, except a smoke before merge that sets `OPUS_JOB_HEAD_PREMERGE=1`, which it logs):

- `init`: a new attempt folder `Downloads\voidsworn_test\<job>\out_<stamp>_<n>` (never reused); `job_wrap.bat init`
  (the tools_live watchdog with its strict hash check, the GPU label, the tool preflight); the path and sha256 of
  `tmo.bat` and `run_timeout.ps1` in `status.txt` (fail closed when either is missing); the watchdog's throwaway Godot
  profile kept on (issue 1228); Ryan's real `battle_opts.json` and `board_look.cfg` hashed.
- `checkout <name> <sha>`: a fresh checkout of that exact commit inside the attempt folder, from the shared
  `repo-mirror.git`; HEAD must equal the pin.
- `ships`: built hulls from `build\godot`: `gen` whole with plain `/E`, no skip flags, so the source wins (its
  `manifest.json` is how the game finds the hulls, and the job fails without it), `assets\ships` with `/E /XC /XN /XO /XF
  manifest.json README.md a4_props.gd *.uid /XD test previews`; robocopy 8 or more fails; then any tracked file that
  differs from the pin fails the job (a stale `a4_props.gd` broke 1236 RUN3), and so does any copied ship whose glb time
  and size differ from its cache's `src` stamp (a publish between the two copies). The measured hulls are listed in
  `<checkout>_ships_identity.txt`, and every later checkout in the job must list the same hulls as the first (so OLD and
  NEW arms measure one fleet). Set `OJ_NEED_HULLS` to the codes your fixtures draw and each must be a matching ship.
- `tail`: hashes Ryan's options again (a change fails the job), then `job_wrap end`: `done PASS` or `done FAILED`,
  then `all done`, and exit 0 only on PASS.

Nothing is deleted. The after-job janitor stays off unless `OPUS_JOB_JANITOR=1`, which needs Ryan's approval.

## What the Board checks

Only that the bat calls the head (`init`, `checkout`, `ships` when it needs hulls, `tail`) and runs every Godot start
through `"%JW%" run`. The head and `contrib/opus/tools/opus_job_head_tests.js` hold the rest.
