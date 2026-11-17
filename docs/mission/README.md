# Mission Control: schema 2 data contract

Issue 989, run 1. The publisher reads evidence from the five PC lanes and public GitHub metadata. The current phone layout remains in place. Run 2 owns the new layout and the picture route.

## Start and phone link

Double-click `tools\pc\mission\start.bat` and keep its window open. The PC page is **http://127.0.0.1:8918**. Node 22 is already installed; no npm install, key or GPU is needed.

For the Pixel, keep Tailscale connected on both devices and double-click `PHONE_ON.bat`. Its private Serve endpoint and first-use HTTPS steps are unchanged. `PHONE_OFF.bat` disables only that endpoint. It leaves the publisher and Tailscale sign-in running.

PHONE_ON accepts schema 1 and 2. A schema 1 publisher, a missing build block, a different content hash or `build.stale` causes an offer to restart. Only an explicit Y permits the restart. It identifies exactly one `node.exe` whose script argument is this folder's exact `publisher.js`, checks that identity again, then stops only that PID. A different folder, an agent process, an unknown port owner or multiple matches are refused. No process tree is stopped. These changes do not restart or deploy the live publisher by themselves.

Run 1 is forbidden to edit `index.html`. The publisher therefore widens its schema check in the served HTML copy only. All existing snapshot fields remain, and the served page reads either schema. The disk HTML and its design are unchanged. Opening that HTML directly bypasses this compatibility step; use the publisher. Run 2 can replace the adapter with the page's own schema support.

## Queue evidence

`queue.js` contains pure parsing and resolution functions. A chain's `.txt` and matching `.bat` provide its assignment and issue order; neither proves a process is alive.

States are decided in this order:

1. Its last nonblank line says cancelled or paused by the Board, or stopped: `cancelled` or `paused`.
2. It wrote `all done`: `ended`.
3. It wrote its own start: `started`.
4. It explicitly says `superseded by <file>.txt`, or a newer bat on the same lane shares an issue and has a `rem replaces <file>.txt` line: `superseded`.
5. Otherwise resolve its wait. The bat's `Select-String -Path` wins over the log. Exact filenames and the older `lane C32` and `chain 16F` forms are supported. Every matching target is retained; zero means target not found, multiple means ambiguous, and cycles remain unknown for the resolution.

A started or waiting predecessor gives `linked`. An ended predecessor gives `starting`; after three minutes the waiter remains listed, amber, saying the waiting window may be closed. A cancelled or paused predecessor gives `stuck: waits on a cancelled chain`. Cancellation does not release this text wait. Two waiters on one predecessor both remain, with the branching note. Separate chains have no implied order.

`lane.queue.groups` preserves each chain, its jobs in bat order, targets, wait source, state and reason. `lane.queue.history` records ended, cancelled, paused and explicitly superseded chains. A newer start selects the lane's latest assignment; it never cancels an older chain or removes its remaining jobs. Earlier start records remain evidence. If equally recent starts disagree, the current assignment is unknown. Any unknown chain or unreadable active issue list makes the lane queue unknown. Legacy `next` is a compatibility listing of the groups, not a promise of order between separate chains.

Closed GitHub issues stay listed in running and waiting chains, marked **closed on GitHub; the chain still lists it**. Issue state is last seen on GitHub and has its own source age.

Board bats release on the words `all done`, regardless of checked-push status. In the real Nov 17 file set, #978 ended unverified at 16:42 UTC and C33 started #985 at 16:43. `pause_all.ps1` step 2 closes waiting windows and appends a pause line. It leaves a running chain window open while ending its agent, allowing the runner to preserve partial work. That chain can then write `all done`, releasing an open successor within its roughly one-minute polling interval. Pause also closes successors already waiting when it runs; the data does not assert that a window is still open.

Runner-managed waits (`chain_issue.bat`, `PC_WAIT_FOR`, `runner_common.ps1`) are separate: they release only on `checked_push` plus a commit and stop on another terminal status or changed run. Matching result evidence reports this mechanism only when it occurs. The publisher does not impose it on Board text chains.

## One result belongs to one run

Internally, run ids are compared as all 32 characters. Only the first eight escape into the snapshot. The Codex result's `job claimed: ... run ...` line must match `status.json`. Untagged conflicting results mean unknown. A differing tag with evidence of an earlier start is previous-run evidence and never changes the current state. A differing tag without proof that it is earlier stays unknown. A result can prove failure without a status; text alone never proves a checked push.

DeepSeek is different: `latest.txt` must name an existing timestamped direct child, and that child's `out/status.json` selects the run. Its result has no run-id line on the inspected PC. A result in that selected run's `out` can describe the run by location, explicitly labelled that way. Invalid or missing pointers give unknown; they never fall back to another run. Codex's lane checkout is shared across jobs, so location alone cannot associate its result.

Activity is a status, matching result, log, checks, events or verified current-run picture write newer than the selected run's start. Old checks, old logs and old pictures do not revive it. `events.jsonl` counts, including DeepSeek runs with no `log.txt`. Activity proves a write, not process liveness. After 30 minutes the state is **quiet N min, process not confirmed**, amber through the legacy page's stale flag. It never becomes idle or working solely because time passed.

Named thresholds live once in the data implementation and are published under `thresholds`:

| Name | Threshold |
| --- | --- |
| PC feed | Over 3 minutes since snapshot generation |
| Claim without matching runner | 10 minutes |
| Work activity | 30 minutes without a qualifying write |
| GitHub source age | Over twice that source's interval |

The old page retains its existing labels and aggregate feed presentation until run 2. In particular, its stale label represents the new quiet data state.

## Picture index

The publisher indexes only `.png`, `.jpg` and `.webp` images at most 3 MiB under each lane checkout's `repo/docs/shots` or `repo/docs/ship_pipeline`. Junctions and symbolic links are excluded. Each image needs a parseable `<file>.provenance.json`, recognized stage, capture date, source revision and matching `image_sha256`. Unstamped or changed images are excluded.

Each entry carries an opaque SHA-256 id, stage, capture time, write time, revision (12 characters, plus `+ working tree` when dirty), association and evidence. No filesystem path or picture filename escapes. There is no picture-serving route in this run.

**This run** needs a capture after the run started and one of:

- The image path is in this run's fresh `diffstat.txt`, or in its recorded commit's diff.
- The sidecar's `source_commit` equals the run's fresh `base_commit.txt`.
- That revision is on this run's currently checked-out branch and was committed after the run started.

Both Codex and DeepSeek use `runner_common.ps1` checkout mode, which records `base_commit.txt` before partial/Base merges. Codex keeps it in `board*/issue-N/base_commit.txt`; DeepSeek keeps it in `work217/issue-N-deepseek/<stamp>/out/base_commit.txt`. Later run-branch merge commits can provide the third form of evidence. `pre_commit.txt` is written at delivery time; it is not the starting revision. Shared checkout location and a recent timestamp alone are insufficient.

A capture before the run start is **older**, even when its path occurs in the diff. Other unlinked captures are **association unverified**. Missing evidence is never promoted into a current picture. A stage of **installed in game** means captured in the game build. Installed on Ryan's PC and accepted by Ryan both remain **not tracked**.

## GitHub reads and budget

One `Budget` instance guards every scheduled request, extra page and retry. Reads use unauthenticated GET requests only, with response size and time limits. No token, cookie, GraphQL call or phone-side GitHub request is used.

| Source | Interval | Read |
| --- | --- | --- |
| questions | 10 minutes | Open issues with `ryan`, every page |
| issues | 10 minutes | All states changed since its last successful read, every page |
| pulls | 10 minutes | All states sorted by update, through the previous successful-read boundary |
| comments | 30 minutes | Repository comments since its last successful read, every page |

Cold reads start at minutes 0, 1, 2 and 3, questions first. The recurring first pages cost about 20 requests an hour, leaving room around the planned 24 and a hard ceiling of 30 in a rolling hour. Every page costs one request; retrying a failed source also spends from that same object. A three-request minute ceiling also covers cold pagination. A paused paginated read keeps its next page internally and remains incomplete until resumed; it does not restart page one every minute. A Link header can only advance a page on the fixed repository endpoint.

At `x-ratelimit-remaining <= 15`, all reads pause until `x-ratelimit-reset`. A 403 or 429 pauses until reset plus a minute. Missing reset information uses a conservative hour plus a minute. Source failures back off 10, 20, 40 and then 60 minutes. Restarting a publisher starts a new local counter; the server's shared-IP remaining/reset headers still apply.

Each `github.sources` record has last successful read, last attempt, completeness, reason, next attempt, interval and staleness. A failed or partial read retains last good values and their original date. A questions query that fails on page two remains **not fully checked**. Legacy `coverageComplete` follows that dedicated query, so the current page never reports zero questions from an incomplete read. The aggregate last-read time is the oldest successful source time once all four have completed at least once.

A Ryan question still needs both the `ryan` label and an unfenced issue-body line `Ask Ryan: <question> | Picture: <link>`. Dispatch locks are not questions. Titles and that one question line are cleaned; raw bodies and comments never escape. Picture links accept only HTTPS within this GitHub repository, without credentials, queries or fragments.

Claude, Muse and Artoo are **last seen on GitHub**, kept separate from PC activity. Records cover opus/muse PR updates, merge commits visible on PRs and comments starting `Artoo (technical review):`. Direct Board commits without a PR are not read. Neither these records nor GitHub running labels prove that a worker is alive.

## Running version and privacy

`build.id` hashes the runtime files at module load; `build.diskId` hashes them again at each snapshot. `stale` is true if they differ. `RUNTIME_FILES` includes publisher, queue, budget, phone, tailscale, page, all fixed served fonts/art and the optional build manifest. The page body is captured when serving starts. `build.startedAt` dates the loaded module; `sourceRevision` is separate, from `build.json` (`{"revision":"<full commit>"}`) or the checkout's local Git revision when known. A Git revision does not imply a clean working tree or replace the content hash.

The snapshot is an allowlist of metadata. It excludes PC paths, PC account/machine names, credentials, raw logs/results/comments and the status file's `folder` and `marker` fields. Runner reasons are recognized fixed messages. Source files are read-only. The HTTP server keeps only the existing page, status, art and font routes, loopback bind and Host/Funnel checks. It has no uploads, job controls, directory listing, public exposure or picture route.

## Checks and observed differences

Run `tools\pc\mission\selftest.bat nopause` or `node tools/pc/mission/selftest.js`, then `node tools/pc/mission/browser_test.js`. All test fixtures and scratch output use TEMP; no live lane files or Tailscale configuration are changed. The browser runs Edge headlessly with GPU disabled. Its display fixtures are generated through the publisher's real state functions. They exercise schema 2, schema 1 compatibility, every old page state, focus, escaping, feed loss and 320/412 px overflow. The standing command is `node contrib/opus/tools/run_all_checks.js`.

`fixtures/nov17.json` contains 132 real PC chain text/bat shapes and five scrubbed current-run excerpts. Later events were cut off at 16:45 UTC on Nov 17; later terminal statuses were restored to their then-running state. This is a reconstruction from file evidence, not a claim that a historical snapshot was saved then. Tests show main #982 and nothing after it, B #975 without #903 or #922, C #985, D #984 and DeepSeek #983. Older chain starts without end lines remain evidence, not silently superseded. The actual D12 file records #984 starting at 16:40 UTC, later than D11; this differs from the brief's chain name but confirms its issue assignment.

Ryan's eight findings, checked against local files and runner code:

| Point | Checked and now represented | Still unknown |
| --- | --- | --- |
| 1. Board text waits | `Select-String` path, `all done`, #978 unverified and C33 #985 start; success is not a release condition | Whether any particular waiting window remains open |
| 2. Cancelled waiting window | Stop/pause log endings; predecessor cancellation leaves a successor stuck | A silent closed window without a log marker |
| 3. Pause running jobs | Pause closes waiting windows, keeps running chain windows; `all done` can still release an open successor after partial work | Whether that successor was also closed during the pause |
| 4. Runner-managed wait | `runner_common.ps1` requires checked_push and commit; changed/other terminal runs stop it | No such wait is inferred without matching run evidence |
| 5. Old wait wording | Old lane/chain forms and exact-file forms resolve; bat Path takes precedence | Missing or ambiguous target files stay unknown |
| 6. DeepSeek | Selected timestamped run, full status id, untagged result, events activity | Result has no intrinsic run id; location is its evidence |
| 7. Codex | Full status/result id match; shared lane checkout; base_commit and run diff/branch proof for pictures | Unlinked pictures and conflicting run evidence stay unverified |
| 8. Deployed version | Live read at 17:34 UTC was schema 1 with no build block, but now had GitHub data; build hashing and restart offer detect drift | Exact loaded code of that old process cannot be recovered from schema 1 |

This run does not deploy or restart Mission Control, change the Tailscale setup, run GPU work, or add the run 2 page/picture route. The Board's PC deployment and Ryan's Pixel check remain later steps.
