# Mission Control r3

The deck reads five PC lanes and four GitHub sources. **Now** shows questions, work and failures. **Queue** shows chains, predecessors and history. **Crew** shows PC lane activity for Codex and DeepSeek and last-seen GitHub activity for Claude, Muse/Rey, OpenAI and Artoo. Open a job to see its stages, next step and evidence.

## Start and phone link

Double-click `tools\pc\mission\start.bat` and keep its window open. The PC page is **http://127.0.0.1:8918**. The publisher uses Node 22.

For the Pixel, keep Tailscale connected on both devices and double-click `PHONE_ON.bat`. `PHONE_OFF.bat` turns off this private endpoint. The local publisher and Tailscale sign-in stay running.

The listener initially serves a **starting** response with no snapshot time or lane claims. A worker thread reads the PC files while GitHub reads proceed independently. The page polls every three seconds until a full snapshot arrives and then every minute. If a later scan fails, the listener keeps serving the last good snapshot. The `--once` command writes a snapshot and exits.

The deck accepts schemas 1 and 2. Schema 1, a missing build block or `build.stale` shows a coral banner with the PHONE_ON restart instruction. PHONE_ON also compares the loaded hash with the files on disk. It offers to restart when these differ and requires an explicit Y. Before stopping one PID, it identifies the Node process whose script argument is this folder's exact publisher path and rechecks that identity.

### Board deployment

From a clean main checkout on the PC, run `powershell.exe -NoProfile -File tools\pc\mission\deploy.ps1 -MainCheckout <main checkout>`. The tool stages the publisher and page together, writes the checkout commit to `build.json`, and backs up the installed pair before stopping the installed publisher. A hidden Node process serves the new pair at the same loopback address. The existing private phone link continues to use that address.

The tool has 60 seconds after launch to verify the build through `GET /status.json` and check the bytes and content type for the page and every served asset. A correctly versioned starting response is valid while the first lane scan runs. A failed check restores the previous installation and restarts its publisher if it was running. The dated backup folder keeps the copies and one `deploy.log` with the rollout and rollback steps.

## How to read a status

| Source | What it establishes |
| --- | --- |
| Chain text and bat files | Assignments, waiting targets and the order within a chain |
| PC runner status and result | The run ID, recorded state and result proved for that run |
| Run log, checks, events and verified picture writes | Work activity after the run started |
| Picture sidecar | Stage, revision, capture time and optionally a job or option link |
| GitHub issues | Issue title and state, plus questions marked by the Board |
| GitHub pull requests and comments | Branch updates, PR state and last-seen crew activity |

| Age | What the deck shows |
| --- | --- |
| PC snapshot over three minutes old | **PC feed lost** and past-tense lane states |
| GitHub source older than twice its interval or incomplete | The affected evidence is marked last known or unavailable |
| PC claim over ten minutes without a matching runner | **Claim not confirmed** |
| Run activity at least thirty minutes old | **Quiet**, with the process unconfirmed |

Each observation carries its source and age. **Sources & version** shows the last successful read and a safe diagnostic for each incomplete GitHub or PC source. A fresh PC scan proves the feed is reading. Live process state and installation on Ryan's PC are untracked.

### Queue and runs

A Board text chain releases successors after `all done`, regardless of the runner's check result. Waits use the bat's `Select-String -Path` when present, otherwise the text's wait target. The publisher preserves branches and the order within each chain. Ready jobs stay listed while awaiting their own start, with an amber note after three minutes. Paused or cancelled predecessors leave their waiters stuck. Missing targets, ambiguous matches and cycles have an explicit unknown reason. Cancelled, paused, ended and explicitly replaced chains go to history. Closed GitHub issues stay in the queue while a chain lists them. Queue groups and history carry `sourceAt` from their latest chain text or script write.

Runner-managed waits use a checked push and commit and stop on changed or failed predecessors. Codex results match the full run ID internally. Only the eight-character prefix reaches the page. An untagged conflicting result or an unproved run relationship stays unknown. DeepSeek's `latest.txt` selects a timestamped run directory, and an untagged result can be associated by that directory. Old activity never revives a newer run. The real Nov 17 file reconstruction remains in `tools/pc/mission/fixtures/nov17.json`.

Now shows **On the queue** for an active chain, a recorded predecessor wait or a ready chain with a start pending. Legacy and unknown listings can show **Last listed, queue unverified**. The **Pushed** stage requires PC runner evidence of a checked push. The next stage shows the PR number and its GitHub state when the pulls source confirms it.

### Picture activity

The publisher checks PNG, JPG and WebP files up to 3 MiB under each lane checkout's `repo/docs/shots` and `repo/docs/ship_pipeline`. The sidecar supplies stage, capture date, source revision and the image SHA-256.

A **this run** picture has a capture after the run started plus a matching sidecar, a fresh run diff, a confirmed-push diff or a first-parent run commit after the starting revision. A matched picture write can count as run activity. Questions with a Board picture link show the link as text.

The private `GET /pic/<id>` route uses the opaque id from the latest index built by the same publisher. The server checks the unchanged sidecar and image bytes before responding. The route refuses links, unknown ids, query parameters, invalid files and over-limit files. Image responses have fixed content and privacy headers. Filesystem paths and filenames stay inside the publisher.

### GitHub reads

One budget governs every scheduled read, next page and retry. The planned rate is 24 an hour with a ceiling of 30 per rolling hour and three per minute during a cold read. Questions, issues and pull requests are scheduled every ten minutes. Comments are scheduled every thirty. The cold-start reads are spread across the first four minutes. The server's remaining quota and reset time can pause the whole budget. Failed sources back off independently. The deck's Sources view shows read ages, retry timing and the shared budget.

A question requires the open issue's `ryan` label and an unfenced `Ask Ryan: <question> | Picture: <link>` line. The page confirms an empty list only after a complete, fresh read of that source. Each partial read keeps the last successful evidence. Successful paginated reads save a watermark with overlap and deduplicate records by id and update time.

### Version and privacy

The build id hashes the page, served fonts and artwork, publisher, queue, budget, phone and Tailscale files and optional build manifest. The timestamp dates the loaded build. `sourceRevision` records its Git revision when known.

The snapshot uses an allowlist of metadata. PC paths, local user and machine names, credentials, raw logs and comments, and the status file's `folder` and `marker` fields stay private. The server binds to loopback and uses the existing private Serve and Host checks.

## Checks and review pictures

Run `tools\pc\mission\selftest.bat nopause` or `node tools/pc/mission/selftest.js`, then `node tools/pc/mission/browser_test.js`. The fixture tests use temporary folders and loopback. Edge runs headlessly with GPU disabled. The checks cover installation safeguards, asset routes, both schema versions, startup, feed loss, per-source errors, legacy queues, PR-only jobs, navigation, touch targets, contrast, privacy and layout. The standing command is `node contrib/opus/tools/run_all_checks.js`.

To refresh stamped review pictures, set `MISSION_STAMP_PYTHON` to a local Python with Pillow. Run `node tools/pc/mission/browser_test.js docs/shots/mission_1117`. The Now, Queue and Crew captures use a 448 px Pixel 10 Pro XL viewport and a 1440 px desktop viewport. Each image is 720 px tall with its revision visible. Crew has a second crop for its lower rows.

The Board's live PC and Pixel checks follow merge.
