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
- Tool preflight lookup (issue 1352): `ffmpeg` is `FFMPEG_EXE`, `voidsworn_test\ffmpeg\bin`, PATH, then `imageio_ffmpeg` asked from each candidate Python, then `site-packages\imageio_ffmpeg\binaries`; `pil` is `PIL_PYTHON`, ComfyUI's Python, `py -0p` (newest first), then `python` on PATH, skipping the WindowsApps stub; each probe has one 20 s deadline covering its exit and its output pipes (a probe that misses it has its process tree stopped and the next candidate is tried), `preflight.txt` names the source that won, and `tools.cmd` keeps non-ASCII paths intact (UTF-8 between two `chcp` lines, only when a path needs it).
- `checkout <name> <sha>`: a fresh checkout of that exact commit inside the attempt folder, from the shared
  `repo-mirror.git`; HEAD must equal the pin. With `OJ_SLOTS=1` (issue 1659, Ryan Nov 22; the template sets it to 1 since the Windows slot proofs passed, Board Nov 23; a bat sets 0 to opt out) it
  resets a warm slot instead: `voidsworn_test\slots\slot_gpu_1`, `slot_gpu_2` (`OJ_SLOT_KIND=gpu`) or `slot_cpu` (`cpu`),
  each one reused `clone --local` of the mirror. The first checkout takes a free slot (waits up to `OJ_SLOT_WAIT_MINUTES`,
  360) and a hidden holder keeps its lease until the tail lets it go or the job's cmd ends. Every later checkout of the job
  proves its holder still runs, owner.txt names its token and the lease is locked, or fails without touching the slot.
  Each reset also holds the slot's own `.slot-reset` lock and proves the lease again before letting go, so a claimant that
  gets the lease from a holder that died mid-reset waits for that reset, which then fails. A new holder also refuses a slot
  while owner.txt's job process still runs and its tail has not released it, so a dead holder never frees a busy slot.
  The tail writes that released line itself for its own token, so a dead holder under the long-lived watcher shell still
  frees the slot when the job ends; a job that dies before its tail keeps its slot until the watcher exits. Before each reset, anything
  the last job left there that is not proven rebuildable is saved into that job's `out_<name>\slot_leftovers`; when it
  cannot be (over 200 MB, a staged change, a nested repo) the slot gets `hold.txt` and is skipped until the Board has
  looked and removed it, and a job that just took it moves on to the next free slot. The reset is a forced checkout of the pin and `git clean -ffdx` that keeps only `godot\.godot`
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
  the same job repeats the check. The janitor (nightly, on low space, and after enabled jobs) runs the same proof over every PASS attempt that still lists
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
  as a new `relay_found.txt` in the attempt (never over a file it already has; issue 1739: the `relay_branch.txt` the head
  writes at init no longer stops the search, so a job the Board relayed to `board/pc-out-*` instead clears too, and
  `relay_found.txt` wins over that init guess). It removes nothing: the waiter
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
  one-off. A second publish from the same job folder needs a new ship run; it also writes `manifest_patch_<CODE>.json`
  in its publish folder, which the Board applies with `publish_ship.py apply-patch` and commits with the publish so
  `godot/assets/ships/manifest.json` follows every publish (issue 1357).
- `opus_job_head.ps1 survey` lists every job checkout and ship clone on the PC with its size and state, read only, for
  a Board one-off cleanup request to Ryan.

Ryan double-clicks `janitor_task.bat` once from the current `tools_live\<version>\pc` folder after the tools update
(read `tools_live\current.txt` for the version). It installs or updates the **Voidsworn Janitor** task for his signed-in
Windows account with limited privileges. Windows starts `janitor.bat --nightly` at 3:30 AM Central each day, using the
tools version current at launch. The task can wake the PC and retries every 15 minutes for two hours if a pause or another
cleanup delays it. A GPU solo claim also defers the nightly run without spending the date. Shared GPU claims allow the
nightly run. Leave the Windows account signed in overnight so the task can use its Git credentials. The nightly date
and lock prevent a second cleanup if the old watcher is running too. `janitor_task.bat --dry-run` previews the task and
prints the exact action Windows will run.
`janitor.bat --dry-run` previews cleanup.

### Git cache upkeep (issue 2181)

Mirror writers fetch heads and tags only. A new or reused agent lane does not fetch
`board/pc-out-*` heads, but old copies are not removed when a job starts. The nightly
janitor runs Git GC under each available mirror's writer lock with a two-week grace
period and leaves reflogs intact. It drops only its own timestamped logs older than
30 days, respecting the keep list. Preview both with `janitor.bat --dry-run`.

The Board can run `prune_relay_branches.ps1 audit` to list every legacy relay head
and its proof against the live private relay. `audit-cached` is read-only and does
not clear any branch for deletion. A matching tip, or every tip path matching by
mode and object ID on its named counterpart, is required in addition to the old
keep rules. Any missing, changed or unreadable counterpart keeps the branch.
Preview local Git caches with `compact_repos.ps1`. Only the Board's `-Live` run
with idle lanes drops cached pull refs and legacy copies proven elsewhere.
Mirrored legacy heads also have to be gone from the game repo first. The compactor
never deletes an upstream branch.

Refresh each Codex lane's tools before the next job. The launcher refuses to
claim an issue if the lane's `runner_hashes.txt` is missing, incomplete or no
longer matches. Lane refresh writes the manifest. The separate tools_live
watchdog check still applies.

Low space triggers `--low-space` from the runner, and enabled job tails trigger `--after-job`. They share one run per hour.
Helper jobs enable their after-job trigger with Ryan's approval via `OPUS_JOB_JANITOR=1`. An admitted after-job run logs
a deferral and skips the job-folder pass while shared GPU claims are active. It can still check lane and TEMP leftovers.
A solo GPU claim defers after-job and low-space disk scans and leaves the hourly run available, since disk reads can skew
frame-time measurements.

Each janitor run has a 45 minute budget checked between items, not a hard timeout: the board lanes and the Workhorse runs (one lane at a time) until a quarter of it, the TEMP folders until half, the job folders until the end. A lane or folder already started runs to its end. Past a stop point the run starts no new item of that kind, says where it stopped, and a live run writes that name to `janitor_resume.txt` (replaced whole, never through a link), so the next run starts there and wraps around; it never removes more for stopping early. Folders that take 10 s or more get a `folder time` line (issue 1396: the first full dry run ran 1 h 47 min unfinished).
Janitor sizes say what removal would really free (issue 1739: the Nov 23 dry run said 49.9 GB, about 4.6 GB came back). A file counts once, and only when every hard link to it is inside the folder, so a checkout's links shared with the mirror count nothing. A folder another account owns (the Codex sandbox scratch) is logged as `cannot remove` and never counted. Each row reads `<N> bytes would be freed, <M> listed, ...`, and the run closes with `space would be freed: <total>`, the sum of its would-remove rows (`tools/pc/disk_space.ps1`).
Dry runs also print `legacy job repo (inventory only)` for the older `<job>\repo` and `<job>\out\run_*\repo` layouts in helper and playtest jobs. Any new removal for these layouts needs Ryan's yes (RULEBOOK 3.3).
Nothing else is deleted (RULEBOOK 3.3, R326).

## What the Board checks

Only that the bat calls the head (`init`, `checkout`, `ships` when it needs hulls, `tail`) and runs every Godot start
through `"%JW%" run`. The head and `contrib/opus/tools/opus_job_head_tests.js` hold the rest.

Workhorse arms and Codex lanes send empty or checkout-local `LOCALAPPDATA` and `PSModuleAnalysisCachePath` to per-run TEMP before the probe and append `/Microsoft/` once to each clone's `.git/info/exclude` (issue 1945).

## The Node PC daemon (issue 1662, built; not live until the Board's PC proof)

`tools/pc/mission/pc_daemon.js` runs PC jobs straight from pull requests, one at a time. `PC_DAEMON.bat` (double-click)
is a dry run: it reads GitHub once and prints what it would run. `PC_DAEMON.bat live` runs jobs.

A pull request runs when it is open, from this repo (never a fork), labelled `pc-ready`, its "All checks" run from
`.github/workflows/checks.yml` on GitHub Actions is green at its head commit, and the newest owner comment that starts
"PC go" names that head commit and is well formed (RULEBOOK 3.12). A newer malformed one holds the job; an older good one
never wins. The Board writes that comment after the review, one comment per run:

```
PC go: <40-character head commit>
reviewed: <who passed the diff at that commit>
job: <name: a-z, 0-9, _>
flow: godot | blender
script: res://<path>.gd (godot, optional) | <repo path>.py (blender)
args: <arguments; {out} is the results folder, {repo} the slot checkout>
expect: <paths under the results folder that must exist and not be empty>
```

Optional lines: `slot: gpu|cpu`, `gpu: auto|solo|none` (auto: the watchdog's classifier picks; none is for Blender only),
`ships: yes|no`, `hulls: <codes>`, `headless: yes|no`, `timeout: <seconds, at most 21600>`, `stall: <minutes with no
output, 5 to 360>`. A cpu slot job does no GPU work: a headless Godot, or a Blender that says `gpu: none` itself (no
Blender job defaults to no claim). A push after the go comment refuses the run (the label comes off with a note); a new
go comment and the label start it again. The checks that count are the newest `checks.yml` run at the head commit, its
newest attempt, and that attempt's own "All checks" job; an older green run, or an earlier attempt of a rerun, never
stands in.

Per job: `pc-ready` must come off (else nothing starts), `running` on, a new attempt `voidsworn_test\<job>\out_<stamp>_<n>`
with results in `out_<job>` (the job reads it as `VS_OUT`), the attempt's tools version checked against its own
`hashes.txt` (the head's `bundle` check), refused unless its `run_timeout.ps1` carries the `# pc-step-settings: 1` line
(an older watchdog lacks the settings below), and used for the whole attempt through the first relay, the tool preflight, Ryan's options hashed, a warm
slot reset to the head commit (its receipt must match the head's own lease record, `slot.txt`, `owner.txt` and the slot
kind, and the head's `slotcheck` must prove the lease live: holder process, owner token, lease file locked; the head skips a
slot holding `hold.txt` or `hold.txt.*.clearing`, checks both again once its holder owns the lease, and its reset stops
without touching the slot if either appeared while it waited) and the built ships copied in. Then the daemon reads the pull request, the whole go comment, the
checks, the pause, the holds and the game again; any change, or a GitHub it cannot read, aborts the job (nothing ran, the
run key stays free, the slot is let go). Before the step it makes the slot's `run_scratch` folder, proves the lease live again, then writes the
slot's `hold.txt` as an in-flight marker, so a daemon that stops mid-step leaves the slot set aside instead of free.

The step runs through the installed watchdog `run_timeout.ps1` in step mode (RULEBOOK 3.5: hard ceiling, idle stop, Job
Object kill with proof, GPU admission by its classifier, the game-open wait) with five settings only the daemon sets
(`PC_STEP_*`; unset, the watchdog behaves as before, except that its game wait now also counts compatibility play, below, for
ordinary jobs too): after its game wait and GPU admission it calls the daemon's
`--recheck` once more, bound to the attempt, the pinned tools folder, the slot and the lease token (it refuses the go when
any is missing, or when `pc_daemon_tools.txt` or the slot's `slot.txt` no longer match them), and starts nothing unless that says go (the GitHub reads first, then the pause, an unreadable `gpu_go.txt` counting as
paused, the holds, and the game read as the watchdog reads it: any Voidsworn, or a windowed Godot with no job arguments, a renderer choice such as
`play_godot_safe.bat`'s `--rendering-method gl_compatibility` still counting as play; the slot lease still proven live;
an unreadable process list counts as playing); the step
ends only when its whole Job Object is empty, so a child that outlives the job is still timed and killed; every program,
Blender included, gets a throwaway profile (APPDATA, LOCALAPPDATA and Blender's user folders) inside the slot's
`run_scratch` folder, with the child logs, and the watchdog removes both; and it writes `watchdog_record.json` with the
exit, whether the tree was seen empty, and the profile. The daemon reads the tree state from that record only, never from
the job's output. Then the outputs and options are checked, the in-flight marker cleared (only while `slotcheck` still
proves the lease live and the marker is exactly what the daemon wrote; it is renamed aside to `hold.txt.<token>.clearing`
before the compare, and the head's slot allocator skips a slot with that file as with `hold.txt`; a changed marker is
linked back, never over a newer `hold.txt`), `done.txt`, the slot let go (bound to the lease the attempt was given: the head releases only while `slot.txt` is there and exactly
that lease and `owner.txt` names this attempt and token, and otherwise keeps the slot: a job that ran is then `FAILED: slot release` with its outputs kept and
delivered, never PASS, and a job stopped before launch says the slot was not let go), the relay push, a result comment with the links, `running` off.

The done marker goes on only with the relay links: a failed relay is retried every 30 minutes from the kept attempt,
never a rerun. Its ledger `voidsworn_test\pc_daemon\ran.txt` keeps start, aborted, the result and delivered apart, each
with its attempt; only a result blocks a new go for that commit and job. A start with no end line from an earlier daemon
process means it stopped mid-job: the daemon records it as interrupted and sets `pc_daemon\hold.txt`. Once the Board has checked that attempt's
process tree is gone, `node tools\pc\mission\pc_daemon.js --clear <attempt folder>` records that (only for an interruption a
live daemon recorded), and the Board removes the two hold files (in the slot: `hold.txt`, or `hold.txt.<token>.clearing` if the daemon stopped
while clearing it; `--clear` names the file, and a newer `hold.txt` beside it is checked first; an unreadable `slot.txt` is refused with
nothing recorded, and an attempt with no `slot.txt` took no slot, so only `pc_daemon\hold.txt` goes). A result whose tools failed their check is kept on the
PC and relayed later, only from a verified tools version. One live daemon per PC (an exclusive localhost
bind on port 47662 the system frees when the process ends), only on `%USERPROFILE%\Downloads\voidsworn_test` with no link
anywhere on that path. A step the watchdog record does not prove gone (no record, survivors, or no end within the
ceiling plus the waits) is a quarantine: the slot's in-flight `hold.txt` stays with the reason, the slot is not let go,
the daemon writes `pc_daemon\hold.txt` and starts nothing, even after a restart, until the Board has looked and removed
both. Nothing starts during the Board pause or while Voidsworn runs. The only file the daemon removes on the PC is its
own in-flight marker. Stop it between jobs with `voidsworn_test\pc_daemon\stop.txt`. Run 1 still calls the tools_live
PowerShell for the slot lease, the ships checks, the preflight, the watchdog and the relay; later runs move each one into
Node and retire its wrapper. The selftest's Windows group runs the real watchdog with a Node stand-in.
