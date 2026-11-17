# MC-951: Mission Control

A read-only phone page for the five PC lanes. The layout follows the approved Mission Control mockups: feed times, counts, Attention, compact lane cards, a lane details sheet, then Crew. The page uses the game's Chakra Petch, Barlow and Azeret Mono fonts and the approved static Artoo droid.

## Start, phone link and stop

1. Double-click `tools\pc\mission\start.bat` in this checkout. Keep its window open and visit **http://127.0.0.1:8918** on the PC.
2. For the Pixel, keep Tailscale installed, signed in to the same account and connected on both devices. Double-click `tools\pc\mission\PHONE_ON.bat`, then open the printed private HTTPS address on the phone. Its existing Serve and first-use HTTPS steps are unchanged.
3. `PHONE_OFF.bat` disables only this private Serve endpoint. The local page and Tailscale sign-in stay available. Close the publisher window or press Ctrl+C to stop the publisher itself.

Node 22 is already installed on the PC. No npm install, API key or GPU is needed. This change does not install or restart the live publisher. Run the launcher from the updated checkout after Board review to use this version.

The existing phone setup refuses public Funnel and conflicting Serve settings. Its endpoint remains `tailscale serve --bg --https=443 http://127.0.0.1:8918`. Host and proxy-header checks, loopback binding, port and phone launchers are unchanged. No public status upload or remote control is provided.

## What the page means

The PC feed shows the snapshot time and age. GitHub check shows its own successful read time and age. After a failed or rate-limited read it says **GitHub check: not read since HH:MM**, retaining the last good information and its time. With no successful read, **For you: not checked** appears and the tally is `?`.

Attention comes before the lanes. **Needs you** means the Board marked a question for Ryan. Failed, Blocked, Stale, Leftover record and Ended without a push each explain what happened and what it means for him. The Board handles technical failures; the page does not ask Ryan to repair a runner. An empty Attention list never prints an all-clear claim.

Each lane shows its role, status, short title, small issue number, start or end time, last activity and one Next line. Tap anywhere on the card to open the sheet: full title, issue and PR links, actual runner state, log time, chain, all queued titles and source evidence. Escape or Close returns focus to the lane. Minute refreshes preserve the open sheet, its scroll and keyboard focus.

| Word | Evidence |
| --- | --- |
| Working | The selected runner says running, with activity younger than 30 minutes. |
| Waiting | A live chain is waiting on its predecessor, or the runner explicitly reports a predecessor wait. |
| Idle | The displayed job finished with a checked push, or the chain and terminal retry output prove the run ended. The sheet keeps the exact runner state. |
| Failed / Blocked | A known failure, refusal, usage limit, stopped predecessor or unverified result. None means Ryan must answer. |
| Stale | An active job has no activity write for at least 30 minutes. It may be hung or quietly working. |
| Leftover record | A different running job folder is outside the live chain's issue list and has no activity for 30 minutes. It does not replace the chain's current job. |
| Ended without a push | DeepSeek's chain wrote `all done` and its selected retry output ended with clone failed, push stopped or all done. This proves an end, never a checked success. A matching merged PR is reported separately. |
| Unknown | Evidence is missing, unreadable or conflicting. The page does not infer a successful finish. |

After three minutes without a new PC snapshot, **PC FEED LOST** appears. Last-known lane styling and the old report time remain. A lost fetch never erases the last good report. Power off, sleep, a stopped publisher and a lost link look the same to this page. A new phone visit still needs the PC awake and reachable.

Crew shows **NO LIVE FEED** on Claude, Muse and Artoo. These are last records from GitHub, not claims that another agent is currently working. Claude records opus branch updates and Board merge commits visible on PRs; Muse records muse branch updates/merges; Artoo records comments starting exactly `Artoo (technical review):`. Comment bodies are never displayed. Direct Board commits with no PR are not available through the three permitted endpoints.

## Sources and privacy

The publisher reads only the existing top-level lane `.txt` files, matching `.bat` issue lists and fixed files under the five job roots. It does not walk checkouts, shots, queues or archives, execute scripts, inspect processes or write to any source. Paused-by-the-Board and stopped chains feed no queue and never count as waiting. A newer waiting chain cannot hide a started chain. A started chain's current issue wins over an unrelated newer job folder. In a gap, the ended job and remaining queue stay visible until a newer run replaces them.

Activity is the newest write time of `status.json`, `log.txt`, `result.txt`, `checks_node.txt` and `checks_parity.txt`. A publisher refresh or chain text write cannot revive a runner. DeepSeek's valid `latest.txt` selects a direct timestamped child only. A pointer to the job folder, a missing pointer or an invalid pointer compares the newest timestamped run's `out` with the top-level `out`, using their activity write times. Arbitrary pointer paths are never followed. An older runner writing only `events.jsonl` can still appear stale; adding that source or changing runners is outside this brief.

Every five minutes the publisher makes at most three unauthenticated, read-only GET requests to the public repository:

- Issues: `state=all`, sorted by updated descending, 100 per page, including titles and labels.
- Pulls: `state=all`, sorted by updated descending, 100 per page; PR state is matched to the exact delivery branch and repository, excluding forks.
- Repository issue comments: sorted by updated descending, since the last successful read; the initial window is seven days.

There are no extra pages, retries or token lookups in a round. Requests are bounded by a timeout and response size. Overlapping refreshes share one reader. A failed round keeps the last successful data and timestamp. Titles fall back to GitHub only when runner titles are unavailable or withheld, and always pass through `cleanTitle`.

The one-page limit matters: a full first issues page may omit older questions. In that case For you stays **not checked**, even after a successful read. Known marked questions still appear, and their original update times remain visible. PRs or Crew activity outside the read window may be unavailable; the sheet offers a branch search instead of claiming there is no PR. The current public repository fills this window. This deliberate unknown avoids a false zero without exceeding Ryan's three-request budget.

The needs-Ryan contract is RULEBOOK 2.4: an open issue must have both the `ryan` label and an unfenced body line `Ask Ryan: <one question> | Picture: <link>`. Removing either removes the question on the next successful read of that issue. Dispatch `blocked` labels never become personal questions. Only the question line escapes the body. Picture links accept HTTPS links within this repository on GitHub or raw.githubusercontent.com; unsafe links are withheld. The page links to pictures without fetching external thumbnails.

Published fields are fixed metadata: issue numbers, cleaned titles/questions, fixed GitHub links, PR state, recognized status reasons, logical source filenames and timestamps. No absolute PC paths, account or machine names, raw logs/results/comments, command lines or credentials are copied. GitHub is read by the PC publisher; the phone makes no GitHub API calls.

The server has fixed routes for the page, sanitized `status.json`, `artoo.svg` and the three bundled fonts. Font licenses sit beside them in the checkout. It has no directory, log, upload, fixture or arbitrary-file endpoint. The derived snapshot is local; never commit a live snapshot.

For a read-only operator check:

```powershell
node tools/pc/mission/publisher.js --root "C:\path\to\voidsworn_test" --out "$env:TEMP\mission-local" --once
```

Output inside job, build or queue folders, or through a junction, is refused. **Open a status file** imports a saved snapshot in the browser. Imported data ages in real time and says Saved PC snapshot; Refresh reconnects to the publisher.

Endpoint contracts: [repository issues](https://docs.github.com/en/rest/issues/issues#list-repository-issues), [pull requests](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests), [repository comments](https://docs.github.com/en/rest/issues/comments#list-issue-comments-for-a-repository). Existing phone setup: [Tailscale Serve](https://tailscale.com/docs/reference/tailscale-cli/serve).

## Checks and pictures

`tools\pc\mission\selftest.bat nopause` exercises real publisher scans over temporary copies of committed fixtures, the public-read adapter with fake responses, read-only source fingerprints, privacy, request budgets, failed-read retention, fixed HTTP routes, process shutdown and the existing phone setup tests. No real lane or Tailscale configuration is changed. The test's publisher processes use fake GitHub responses.

`node tools/pc/mission/browser_test.js [shots folder]` uses installed Edge headlessly with GPU disabled. It checks all states, exact issue/queue links, sheets, escaping, offline aging after a failed fetch, GitHub uncertainty, Crew tags/art, focus retention and overflow at 320 and 412 px with larger type. Its profile, payloads and logs stay in TEMP. Ordinary publishers expose no fixture routes.

The Nov 16 22:38 fixture uses real publisher inputs: main chain 16B on #928, the newer #944 stub, paused 15H/15Z/16A and B23/B25, lane B's #936, and DeepSeek #932's ended top-level retry. It must show #928 Working, Next **929 912 930 920 921**, #944 as a leftover, nothing next on B and DeepSeek Idle/ended with merged PR 937 separate from the failed run.

All pictures are **412 x 720 fixture proof**, MC-951 revision r1 from the working tree, with revision/stage sidecars. They are compared against the approved mockups, not claimed as Ryan's visual acceptance. The implementation adds explicit Close and picture/issue links, retains lane D, and leaves the full queue and source rows scrollable within the sheet. The question card uses a picture link instead of an externally fetched thumbnail.

Views: [Now](../shots/mission/MC-951-night.png), [lanes](../shots/mission/MC-951-lanes.png), [details](../shots/mission/MC-951-detail.png), [full queue and sources](../shots/mission/MC-951-detail-queue.png), [Crew](../shots/mission/MC-951-crew.png).

States: [overview](../shots/mission/MC-951-overview.png), [running](../shots/mission/MC-951-running.png), [waiting](../shots/mission/MC-951-waiting.png), [blocked](../shots/mission/MC-951-blocked.png), [failed](../shots/mission/MC-951-failed.png), [finished](../shots/mission/MC-951-finished.png), [between jobs](../shots/mission/MC-951-gap.png), [stale](../shots/mission/MC-951-stale.png), [leftover record](../shots/mission/MC-951-leftover.png), [ended without push](../shots/mission/MC-951-ended.png), [PC offline](../shots/mission/MC-951-offline.png), [unknown](../shots/mission/MC-951-unknown.png), [GitHub not read](../shots/mission/MC-951-github-unread.png), [needs Ryan](../shots/mission/MC-951-needs-ryan.png), [no marked question](../shots/mission/MC-951-no-needs-ryan.png).

Live read, Nov 17 05:54 UTC: main #929, Next 912/930/920/921; B #936, Next 922/368; C #951; D #957; DeepSeek #953 with stale recorded activity. The chain files confirm each current issue and queue. LOOP's 04:55 line has main on #928 before its 22:55 local end/start transition to #929; the newer C/D chains likewise supersede LOOP's older jobs. GitHub's three public reads succeeded, supplied all six checked titles and PR 955 for the ended #928 run, plus Crew records. Old #944 and #945 main-lane stubs appear as leftovers. No needs-Ryan marker was found in the latest 100 issues, so For you stays not checked. The live JSON stays in TEMP and is not published in this PR.

Verification for this working tree: the Windows publisher self-test passes 55 checks. The headless Edge check passes all 16 state fixtures and behavior checks and saves 20 views, including lane, sheet, queue and Crew captures. The standing suite result is included in the delivery report. The real Pixel link was not reconfigured or exercised in this code-only job.
