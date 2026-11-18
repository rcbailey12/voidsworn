# Mission Control r3

The deck reads six PC lanes and four GitHub sources. **Now** shows Needs Ryan, followed by each lane's **Now**, **Next** and **Needs attention**. **Queue** shows the same flight plans together. Open a job for the issue, the runner and delivery records, and a copyable check-in. Chain files, timestamps and history are under **Details**. **Crew** shows Codex, DeepSeek and OpenAI PC records, and last-seen GitHub activity for Claude, Muse/Rey and Artoo. OpenAI PR activity also appears as a dated GitHub observation.

## Start and phone link

Double-click `tools\pc\mission\start.bat` and keep its window open. The PC page is **http://127.0.0.1:8918**. The publisher uses Node 22.

For the Pixel, keep Tailscale connected on both devices and double-click `PHONE_ON.bat`. `PHONE_OFF.bat` turns off this private endpoint. The local publisher and Tailscale sign-in stay running.

The listener initially serves a **starting** response with no snapshot time or lane claims. A worker thread reads the PC files while GitHub reads proceed independently. The page polls every three seconds until a full snapshot arrives and then every minute. If a later scan fails, the listener keeps serving the last good snapshot. The `--once` command writes a snapshot and exits.

The deck accepts schemas 1 and 2. Schema 1, a missing build block or `build.stale` shows a coral banner with the PHONE_ON restart instruction. PHONE_ON also compares the loaded hash with the files on disk. It offers to restart when these differ and requires an explicit Y. Before stopping one PID, it identifies the Node process whose script argument is this folder's exact publisher path and rechecks that identity.

### Board deployment

From a clean main checkout on the PC, run `powershell.exe -NoProfile -File tools\pc\mission\deploy.ps1 -MainCheckout <main checkout>`. The tool stages the publisher, its queue code, the page and its assets as a set, writes the checkout commit to `build.json`, and backs up the installed set before stopping the installed publisher. A hidden Node process serves the new set on the existing loopback address used by the private phone link.

The tool has 150 seconds after launch to check the loaded hash, disk hash, revision and latest runtime file timestamp through `GET /status.json`. It also checks the bytes and content type of the page and each asset, and waits for a fresh PC scan with matching lane refresh timestamps. Individual source gaps still appear on the deck. A failed check restores the previous installation and restarts its publisher if it was running. The dated backup folder keeps the copies and `deploy.log`.

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
| PC snapshot over three minutes old, or a refresh request fails | **PC feed lost** or **PC link interrupted**, with lane and GitHub facts labelled last known |
| GitHub source older than twice its interval or incomplete | The affected evidence is marked last known or unavailable |
| PC claim over ten minutes without a matching runner | **Claim not confirmed** |
| Run activity at least thirty minutes old | **Quiet**, with the process unconfirmed |

Each observation carries its source and age. **Sources & version** shows the last successful read and a safe diagnostic for each incomplete GitHub or PC source. A fresh PC scan proves the feed is reading. Live process state and installation on Ryan's PC are untracked.

### Queue and runs

A Board text chain releases successors after `all done`, regardless of the runner's check result. Waits use the bat's literal `findstr` or `Select-String -Path` target when present, otherwise the text's wait target. A separate chain keeps its own order. When the script lists several jobs, a chain waiting for `all done` points to the predecessor chain's final listed job. Inside a started chain, the remaining jobs follow its current or most recently ended job. Queue groups and history carry `sourceAt` from their latest chain text or script write.

| Parser state | What the flight plan can say |
| --- | --- |
| `started` | The chain has a start record. The runner record establishes the current job's state. Only the remaining assignments show in Next. |
| `linked` | A predecessor is recorded and has no confirmed ending. The queue records a dependency. A blocked or old predecessor is called out. |
| `starting` | The predecessor wrote `all done`. The successor has no start record. After three minutes the gap is flagged. |
| `stuck` | The predecessor was paused or cancelled. |
| `unknown` | The source, target or order cannot be resolved. Resolved groups on the same lane remain visible. |
| `ended`, `cancelled`, `paused`, `superseded` | The record remains in History. |

Recorded waits establish assignments. Current runner activity comes from the matching runner's evidence. The waiting count covers distinct, actionable waiting issues per lane from `started`, `linked` and `starting` groups. It omits legacy listings, closed-issue conflicts and waits blocked by a stopped predecessor. **No successor recorded** refers to the lane's known chain records. **Successor order unverified** covers legacy or unresolved records. A closed issue still in a chain appears as a conflict.

Runner-managed waits use a checked push and commit and stop on changed or failed predecessors. Codex results match the full run ID internally. Only the eight-character prefix reaches the page. An untagged conflicting result or an unproved run relationship stays unknown. DeepSeek and OpenAI use separate `latest.txt` pointers to timestamped run directories inside `work217`. DeepSeek accepts the `deepseek` and `deepseekpro` arms. OpenAI accepts its `openai` arm with a matching branch and run ID. An untagged result can be associated by its verified run directory. Old activity never revives a newer run. The real Nov 17 file reconstruction remains in `tools/pc/mission/fixtures/nov17.json`.

**Last listed, queue unverified** identifies legacy listings such as #922. **Checked push confirmed** requires the current PC runner's checked-push state. **PR recorded** gives the PR number and GitHub state independently. An Artoo technical review comment on that PR naming the recorded head commit can show **Technical review recorded**. Its date and source appear in the job view.

### Picture activity

The publisher checks PNG, JPG and WebP files up to 3 MiB under each lane checkout's `repo/docs/shots` and `repo/docs/ship_pipeline`. The sidecar supplies stage, capture date, source revision and the image SHA-256.

A **this run** picture has a capture after the run started plus a matching sidecar, a fresh run diff, a confirmed-push diff or a first-parent run commit after the starting revision. A matched picture write can count as run activity. A job view shows its latest verified run picture once the image loads, below the job heading. A Board question can have a separate picture link.

The private `GET /pic/<id>` route uses the opaque id from the latest index built by the same publisher. The server checks the unchanged sidecar and image bytes before responding. The route refuses links, unknown ids, query parameters, invalid files and over-limit files. Image responses have fixed content and privacy headers. Filesystem paths and filenames stay inside the publisher.

### GitHub reads

One budget governs every scheduled read, next page and retry. The planned rate is 24 an hour with a ceiling of 30 per rolling hour and three per minute during a cold read. Questions, issues and pull requests are scheduled every ten minutes. Comments are scheduled every thirty. The cold-start reads are spread across the first four minutes. The server's remaining quota and reset time can pause the whole budget. Failed sources back off independently. The deck's Sources view shows read ages, retry timing and the shared budget.

A readable question requires the open issue's `ryan` label and an unfenced `Ask Ryan: <question>` line. The ` | Picture: <link>` suffix is optional. A labelled open issue with an unreadable or missing marker stays visible as **Needs Ryan flagged; question unavailable**, with its issue link. The page confirms an empty list only after a complete, fresh questions read. A failed or partial read keeps the last successful results and their read time. Successful paginated reads save a watermark with overlap and deduplicate records by id and update time.

### Version and privacy

The build id hashes the page, served fonts and artwork, publisher, queue, budget, phone and Tailscale files and optional build manifest. `startedAt` dates the loaded process, `sourceAt` dates the latest runtime file and `sourceRevision` records the Git revision when known.

The snapshot uses an allowlist of metadata. PC paths, local user and machine names, credentials, raw logs and comments, and the status file's `folder` and `marker` fields stay private. The server binds to loopback and uses the existing private Serve and Host checks.

## Checks and review pictures

Run `tools\pc\mission\selftest.bat nopause` or `node tools/pc/mission/selftest.js`, then `node tools/pc/mission/browser_test.js`. The fixture tests use temporary folders and loopback. Edge runs headlessly with GPU disabled. The checks cover installation safeguards, asset routes, both schema versions, startup, feed loss, per-source errors, legacy queues, PR-only jobs, navigation, touch targets, contrast, privacy and layout. The standing command is `node contrib/opus/tools/run_all_checks.js`.

To refresh stamped review pictures, set `MISSION_STAMP_PYTHON` to a local Python with Pillow. Run `node tools/pc/mission/browser_test.js docs/shots/mission_1118`. The six 412 px Pixel captures show running, queued, blocked, unknown, offline and Needs Ryan. Each image is 720 px tall and shows its revision and the **Sample data** label.

The Board's live PC and Pixel checks follow merge.
