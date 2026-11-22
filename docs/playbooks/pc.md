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
  `repo-mirror.git`; HEAD must equal the pin. With `OJ_SLOTS=1` (the template's default since issue 1659, Ryan Nov 22) it
  resets a warm slot instead: `voidsworn_test\slots\slot_gpu_1`, `slot_gpu_2` (`OJ_SLOT_KIND=gpu`) or `slot_cpu` (`cpu`),
  each one reused `clone --local` of the mirror. The first checkout takes a free slot (waits up to `OJ_SLOT_WAIT_MINUTES`,
  360) and a hidden holder keeps its lease until the tail lets it go or the job's cmd ends. Before each reset, anything
  the last job left there that is not proven rebuildable is saved into that job's `out_<name>\slot_leftovers`; when it
  cannot be (over 200 MB, a staged change, a nested repo) the slot gets `hold.txt` and is skipped until the Board has
  looked and removed it. The reset is a forced checkout of the pin and `git clean -ffdx` that keeps only `godot\.godot`
  and `*.import` sidecars warm; it deletes only inside `slots`. The ships step then copies into the slot as below (its
  side files go to `<attempt>\<name>_ships_*.txt`), so a publish during a job changes nothing under it. A slot job has no
  checkout of its own for the tail to remove. Codex lanes move onto the slots later, after a Windows log of two slot jobs.
- `ships`: built hulls from `build\godot`: `gen` whole with plain `/E`, no skip flags, so the source wins (its
  `manifest.json` is how the game finds the hulls, and the job fails without it), `assets\ships` with `/E /XC /XN /XO /XF
  manifest.json README.md a4_props.gd *.uid /XD test previews`; robocopy 8 or more fails; then any tracked file that
  differs from the pin fails the job (a stale `a4_props.gd` broke 1236 RUN3), and so does any copied ship whose glb time
  and size differ from its cache's `src` stamp (a publish between the two copies). The measured hulls are listed in
  `<checkout>_ships_identity.txt`, and every later checkout in the job must list the same hulls as the first (so OLD and
  NEW arms measure one fleet). Set `OJ_NEED_HULLS` to the codes your fixtures draw and each must be a matching ship.
- `tail`: hashes Ryan's options again (a change fails the job), then `job_wrap end`: `done PASS` or `done FAILED`,
  then `all done`, and exit 0 only on PASS. Then the checkout step (`opus_job_head.ps1 dropcheckouts <attempt>`) runs
  for this attempt only (earlier attempts go through their own waiter or the janitor; review of PR 1644). An attempt's pinned checkouts (rebuildable from their pins, up to
  22 GB each) go only when its `done.txt` says PASS and a relay branch on origin holds every file of its `out_*` folders
  at `<tree folder>/out_<name>/<path>` with the same bytes. The head proves the relay itself (issue 1535, Nov 22): no
  session writes a receipt by hand. Where to look is, in order, an older `relay_receipt.txt` (`<board/pc-out branch> <tree
  folder>`), the attempt's `relay_branch.txt` that init writes before any result exists (`relay/pc-out-<job> <attempt
  folder name>` since issue 1657: branch `pc-out-<job>` of the private relay repo `rcbailey12/voidsworn-relay`, held in
  its own `relay-mirror.git`; older attempts name `board/pc-out-<job>` on the main repo, also printed in status.txt), or
  else by the job name, the relay repo's `pc-out-<job>` when its mirror has it, else `board/pc-out-<job>`; `git ls-remote`
  must show origin holding that branch at the commit checked in the shared mirror (the mirror is fetched once when it
  does not). The Board relays an attempt in that layout with `tools\pc\relay_push.bat <job> <attempt folder>` (the attempt
  folder at the tree's root on the relay repo's `pc-out-<job>`, adding to the branch for later attempts; RULEBOOK 3.3a) and then runs `dropcheckouts <attempt>`; a later tail of
  the same job repeats the check. The janitor (hourly and after jobs) runs the same proof over every PASS attempt that still lists
  checkouts (`opus_job_head.ps1 dropjobs <job>`, `dry` on a janitor dry run), so no hand step is needed after a relay. Ship jobs' `droprepo` looks the same way for `board/pc-out-<job>` with `<job>_out`. A file over 10 MB the relay left out counts only when it is
  absent from the tree and the relay's own `<tree folder>/skipped_over_10MB.txt` lists that exact path (with `\`) and its
  size in MB; it stays on the PC, since out folders are never removed here. No receipt or any other difference keeps
  everything, and the log names the first files that differ or are missing. A proven checkout is first recorded in its folder's
  `removing.txt` (`<name>.removing <commit>`), renamed whole to `<name>.removing`, then removed; a file that stays locked
  (Defender, a survey) is retried for about 30 s, and what a lasting lock leaves is that recorded folder, which the next
  run of the same step finishes only for a listed checkout (or `repo`) whose HEAD, if still there, is the recorded
  commit. Any other `.removing` folder is left alone (issue 1497, Nov 21). A failed or unfinished attempt is never
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
- The relay lands after a job's tail, so the tail also starts a hidden waiter (`opus_job_head.ps1 dropwait`, the
  attempt in `OJ_DROPWAIT_ATTEMPT`, never on its command line; log `<job>\dropwait_<attempt>.txt`; a launch that fails
  is logged as one in status.txt). For a passed attempt only, it asks origin (`git ls-remote`, no prompts, 120 s limit)
  for the attempt's relay branch every 5 minutes. With the branch there it takes the job lease and the issue lock,
  then the janitor's checks (the Board keep list, no running process naming the job folder, no PC pause), then the
  same drop as `dropcheckouts`: the mirror writers' lock, a fresh relay proof (each result root a plain folder), any
  recorded unfinished removal of a listed checkout at its listed pin, then each checkout with the checks repeated
  right before its rename. Any refusal is tried again: at once when the branch moves, else after a wait that doubles
  from 5 minutes to an hour. Nothing new starts after 12 hours, and the mirror lock wait ends there too; only a
  removal already under way finishes, and a Git fetch inside the proof can still run past it (it has Git's
  low-speed limit, not a hard one). The janitor's relay sweep covers anything later. `dropwait <attempt> dry` looks
  once and runs the dry proof: no lock, lease, log, fetch or removal. `OJ_NO_DROPWAIT=1` skips the waiter (issue
  1396; Nov 22, with a new job name every night no later attempt cleared the last one: 20 checkouts, about 8 GB each).
- Attempts relayed before that under another branch name or folder (board/pc-out-1547c and so on) name no place the
  proof finds. `opus_job_head.ps1 relayfind <attempt>|all [dry]` looks through every `board/pc-out-*` branch in the
  shared mirror for the folder that holds all of a passed attempt's result files byte for byte, and writes only that,
  as a new `relay_branch.txt` in the attempt (never over its own receipt or branch file). It removes nothing: the waiter
  and the janitor's relay sweep still prove the bytes under the mirror lock before any drop. dry writes and fetches
  nothing (issue 1695). A job that was never relayed is not found and keeps its checkouts.
- Every live removal that rests on the shared mirror (the job head's relay sweep and `droprepo`, the janitor's helper
  folders and kept checkouts) holds the mirror writers' lock `repo-mirror.git.lock` from its last proof through the
  delete, so no lane's fetch or prune can drop a ref the proof read in between (issue 1396, Artoo on PR 1592). A lane
  fetch waits meanwhile; the janitor waits up to 10 minutes for the lock, then keeps the folder. Dry runs never take it.
- Ship jobs (`ship_job.bat`): after a PASS the clone's Godot import cache `repo\godot\.godot` goes before the done line
  (`opus_job_head.ps1 dropcache`); the clone stays because the publish installs with its tools. `publish_ship.bat`
  removes the clone after a published PASS (`droprepo`: HEAD must be the published commit, every file in the job's
  `out` relayed per `out\\relay_receipt.txt`, which the Board writes when it relays out, or passes as `droprepo <job>
  <commit> <code> <branch> <tree folder>`, every local commit in the shared mirror or a merge of mirror commits, every tag or other non-branch ref in the mirror under the same name and object, no stash or staged change;
  installed files matching the collected export count as
  rebuildable, anything else is saved into `out\checkout_leftovers_repo` first). A ship build that is never published
  keeps its slimmer clone: the janitor never removes a ship clone (issue 1396); an abandoned one goes to the Board as a
  one-off. A second publish from the same job folder needs a new ship run.
- `opus_job_head.ps1 survey` lists every job checkout and ship clone on the PC with its size and state, read only, for
  a Board one-off cleanup request to Ryan.

Each janitor run has a 45 minute budget checked between items, not a hard timeout: the board lanes and the Workhorse runs (one lane at a time) until a quarter of it, the TEMP folders until half, the job folders until the end. A lane or folder already started runs to its end. Past a stop point the run starts no new item of that kind, says where it stopped, and a live run writes that name to `janitor_resume.txt` (replaced whole, never through a link), so the next run starts there and wraps around; it never removes more for stopping early. Folders that take 10 s or more get a `folder time` line (issue 1396: the first full dry run ran 1 h 47 min unfinished).
Nothing else is deleted (RULEBOOK 3.3, R326). The after-job janitor stays off unless `OPUS_JOB_JANITOR=1`, which needs Ryan's approval.

## What the Board checks

Only that the bat calls the head (`init`, `checkout`, `ships` when it needs hulls, `tail`) and runs every Godot start
through `"%JW%" run`. The head and `contrib/opus/tools/opus_job_head_tests.js` hold the rest.
