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
  then `all done`, and exit 0 only on PASS. Then the checkout step (`opus_job_head.ps1 dropcheckouts <attempt>`) runs
  for this attempt and the same job's earlier ones. An attempt's pinned checkouts (rebuildable from their pins, up to
  22 GB each) go only when its `done.txt` says PASS and its `relay_receipt.txt` (`<board/pc-out branch> <tree folder>`)
  names a relay branch whose tree holds every file of its `out_*` folders at `<tree folder>/out_<name>/<path>` with the
  same bytes (the mirror is fetched when it does not). The Board relays an attempt in that layout (the attempt folder
  itself, as board/pc-out-1211r6 does) and then runs `dropcheckouts <attempt> <branch> <tree folder>`, which writes the
  receipt; a later tail of the same job repeats the check. No receipt or any difference keeps everything. A failed or unfinished attempt is never
  touched by this step (the janitor's rules cover it). Per checkout: listed in `checkouts.txt` by the head, `.git\HEAD`
  still the pin, every local branch in the mirror (a local merge only when git rebuilds its exact tree from its two mirror parents),
  no stash, nothing staged, and no link or junction anywhere between `voidsworn_test` and the folder. Proven leftovers go as they are: the import
  cache, a ships copy whose sha256 matches the ships step's copy-time record (`<checkout>_ships_copied.txt`, written right after the copy
  and only for files whose bytes match `build\\godot` then, so a publish
  later in the night no longer makes every copy look changed) or the shared build, a byte copy of a tracked file, and a
  `.import`/`.uid` sidecar of one of those. Anything else the job left (a `build_info.json`, a changed `.import` file, a
  new ship file) is saved first into `out_<name>\checkout_leftovers` (working-file changes as `changes.patch`, other files
  copied and read back by sha256, `leftovers.txt` lists them); more than 200 MB, a staged change or a nested repo keeps
  the checkout and is logged. Issue 1497: on Nov 21 every passing job kept its whole checkout for one such small file and
  C: fell from 176 to 55 GB in three hours. The step ends with `disk: checkouts freed <GB> in all, C: <GB> free`. Links go
  as links, nothing goes during the Board's PC pause, `out_*`, the logs and the ship records stay, and
  `OJ_KEEP_CHECKOUTS=1` skips the step at the tail. Known and accepted: clearing read-only on git packs also clears it on
  the mirror's hard-linked copies, the logged GB counts hard-linked bytes the mirror still holds, and an error
  mid-removal leaves a half-removed checkout behind.
- Ship jobs (`ship_job.bat`): after a PASS the clone's Godot import cache `repo\godot\.godot` goes before the done line
  (`opus_job_head.ps1 dropcache`); the clone stays because the publish installs with its tools. `publish_ship.bat`
  removes the clone after a published PASS (`droprepo`: HEAD must be the published commit, every file in the job's
  `out` relayed per `out\\relay_receipt.txt`, which the Board writes when it relays out, or passes as `droprepo <job>
  <commit> <code> <branch> <tree folder>`, every local commit in the shared mirror or a merge of mirror commits, no stash or staged change;
  installed files matching the collected export count as
  rebuildable, anything else is saved into `out\checkout_leftovers_repo` first). A ship build that is never published
  keeps its slimmer clone for the janitor (issue 1396). A second publish from the same job folder needs a new ship run.
- `opus_job_head.ps1 survey` lists every job checkout and ship clone on the PC with its size and state, read only, for
  a Board one-off cleanup request to Ryan.

Nothing else is deleted (RULEBOOK 3.3, R326). The after-job janitor stays off unless `OPUS_JOB_JANITOR=1`, which needs Ryan's approval.

## What the Board checks

Only that the bat calls the head (`init`, `checkout`, `ships` when it needs hulls, `tail`) and runs every Godot start
through `"%JW%" run`. The head and `contrib/opus/tools/opus_job_head_tests.js` hold the rest.
