# MC-918: mission control

The Pixel gets this page through Tailscale's signed-in private network. The publisher stays on this PC, with no status stored on a public site. The phone link is optional; the local page works without Tailscale.

## Phone

1. Install [Tailscale](https://tailscale.com/download) on the PC and the Pixel. Sign in with the same account on both, and connect both devices.
2. Double-click `tools\pc\mission\PHONE_ON.bat`. It starts mission control if needed, turns on the private link and prints an `https://...ts.net/` address. If Tailscale asks you to enable Serve or HTTPS, follow its link and approve private Serve, then run PHONE_ON again.
3. Open that address on the Pixel and bookmark it. Keep this PC awake and Tailscale connected on both devices. You can close the phone launcher's window.
4. Double-click `tools\pc\mission\PHONE_OFF.bat` to turn the phone link off. It leaves Tailscale signed in and the local PC page working.

The link is for authorized devices in your tailnet. These files never enable Funnel or a public listener. Do not enable Funnel for mission control. A new visit needs the PC online; an already-open page shows PC offline when updates stop. Serve's background setting survives a PC restart, so use PHONE_OFF when you want the link disabled. After a restart, run PHONE_ON to start the publisher again.

PHONE_ON finds Tailscale in its Windows install folder even if it is missing from PATH. A cold start can take over a minute; the launcher waits up to 90 seconds for the local page. If Tailscale is missing or signed out, the window explains what to do. If the local publisher was already running before Tailscale signed in, close its window and run PHONE_ON again. If it has no window, restart the PC and run PHONE_ON. The launchers refuse to replace another service on the same HTTPS address or proceed while an existing public Funnel is enabled. They print any first-use Serve or HTTPS setup instructions from Tailscale.

Operator details: private `tailscale serve --bg --https=443 http://127.0.0.1:8918`; PHONE_OFF uses the same flags and target with `off`, never a global reset, logout or uninstall. The publisher reads `tailscale status --json` once at startup, allowing only `Self.DNSName` for a connected, signed-in PC. That name (with optional `:443`) additionally needs a loopback connection and Serve's HTTPS, matching forwarded Host and tailnet source-IP headers. Funnel-marked requests are refused. Local processes are trusted; proxy headers do not authenticate software already running on this PC. Missing, stopped or unreadable Tailscale keeps the original two local hosts only. The startup lookup is bounded to five seconds. A background publisher started by PHONE_ON logs to `%TEMP%\voidsworn-mission-phone-*.log`.

The commands and Windows port-forwarding behavior follow Tailscale's [Serve reference](https://tailscale.com/docs/reference/tailscale-cli/serve), [Windows localhost examples](https://tailscale.com/docs/reference/examples/serve) and [Windows install guide](https://tailscale.com/docs/install/windows). Proxy checks follow [Tailscale's Serve header implementation](https://github.com/tailscale/tailscale/blob/main/ipn/ipnlocal/serve.go).

## Start and stop

1. In this checkout, double-click `tools\pc\mission\start.bat`.
2. Keep its window open. On the PC, open **http://127.0.0.1:8918**. It reads the existing `Downloads\voidsworn_test` sources and refreshes once a minute.
3. Close that window or press Ctrl+C to stop both the publisher and local server. There is no service, startup task, child publisher or scheduled job to stop.

Node 22 is already part of the PC tool setup. No Python, npm install, key or GPU is needed to run the publisher locally. The launcher finds the installed Node executable. If the port is taken it stops with a message.

The output is `Downloads\voidsworn_test\mission_local\status.json`. This is a derived snapshot, not another job board. Nothing in a source lane, job, queue or chain script is written, run, renamed or deleted. Only the output snapshot is replaced. The server binds to `127.0.0.1` and exposes exactly the page and status file, with no upload or directory endpoint. It rejects unexpected Host headers and sends no CORS permission. It does not serve source logs.

The Board can use a different local folder or a one-shot read:

```powershell
node tools/pc/mission/publisher.js --root "C:\path\to\voidsworn_test" --out "$env:TEMP\mission-local" --once
```

These are operator options, not steps Ryan needs to type. Output inside job, build or queue folders is refused. There is deliberately no public bind or upload option. To inspect an exported snapshot without a server, open `docs/mission/index.html`, tap **Open a status file**, and select the local `status.json`. Imported files say **Saved PC snapshot** and keep aging, without pretending to update. Tap Refresh to reconnect to the local publisher.

## What Ryan sees

A short vertical orders sheet: dark space, restrained glowing lane lines, readable type, square controls, and a status light beside each seat. All five seats always appear: Codex main, B, C, D and DeepSeek. There are no invented Claude, Muse or Artoo feeds.

Each row shows the current issue and title when the source contains it, start time, last activity, next two queued issues, source and refresh time. **Evidence and links** opens source change times, all source names, the remaining queue and **Find pull request**. PR links search the exact delivery branch, because these runner sources do not reliably carry a PR number. Issue and PR destinations are restricted to this project's GitHub pages.

| State | Meaning |
| --- | --- |
| Running | The current runner says running. Activity is shown separately; the word alone is never proof of life. |
| Waiting | A chain says it is queued behind its named predecessor, or the runner result says it is waiting for a checked push. The waiting jobs appear in Next. |
| Blocked | A predecessor stopped, a job was refused, usage ran out, or the result is partial, unverified or no changes. These do not count as a checked finish. |
| Failed | The runner reports a failure. A recognized, safe version of its reason is shown, including exit codes. |
| Finished | `status.json` says `checked_push`: a non-partial push was confirmed and runner checks passed. `all done` alone cannot prove success. |
| Unknown | Missing, unreadable, unrecognized or conflicting evidence. A missing title says unavailable; the page does not invent one. |
| Stale | An active current job has had no log or status write for at least 30 minutes. It may be hung or quietly working; no process inspection or automatic stop is performed. |

At three minutes after the last publisher report, the whole page says **PC offline (last heard HH:MM)**. Last known rows remain visible. This means no recent report reached the page; power off, sleep, a stopped publisher and a lost connection are indistinguishable. A failed fetch preserves the last good data and its old timestamp. The page also ages while disconnected and recalculates when the phone tab becomes visible. A never-connected page says Waiting for PC status. A fresh file is not proof that a job is alive.

Every row's Refreshed time is when the publisher last inspected it. Evidence shows when its underlying source last changed. Finished jobs do not become stale merely because they finished long ago. A chain-only current job with no usable runner status becomes stale after its observed start has aged 30 minutes.

## Source contract and limits

The only task inputs are the existing top-level `codex_chain_*.txt`, `codex_lane_[bcd]*.txt`, `ds_*.txt`, their matching `.bat` issue lists, and each job's `status.json`, `result.txt`, `log.txt`. DeepSeek's existing `latest.txt` pointer selects a direct timestamped run under `work217`; arbitrary pointer paths are never followed. Missing or invalid pointers fall back to the newest direct run folder. No GitHub API calls or worker changes are needed.

Codex maps to `board`, `board_b`, `board_c`, `board_d`; DeepSeek maps to `work217\issue-N-deepseek[pro]\<timestamp>\out`. No recursive walk of checkouts, shots, queues or log archives takes place. Script text is parsed, never executed. Recognized lists are `for %%N in (...) do call :one %%N` and direct numeric calls to the issue/retry runners. An unstarted `.bat` by itself is not evidence of a live queue. Unknown formats stay unknown.

The newest started chain wins over a newer waiting chain. Between an issue's `end` line and the next `start`, that chain stays live: the row keeps the ended job's runner result, its chain source and every remaining issue in Next. A job finishing is separate from a chain writing `all done`. An end line alone cannot prove a checked push. Queues follow predecessor order. A newer started chain, including one that has already written `all done`, or a newer standalone job supersedes an old abandoned chain. A rerun's old success cannot be reused after a new chain start. Only log and status write times count as life, including file metadata when contents cannot be read. A result write, a lane text update, a page fetch or a publisher tick cannot revive a dead job.

Each minute does one bounded local scan and one small local snapshot replacement. Unchanged text is cached by size and write time. Status/lane/script reads are limited to 64 KiB each, result tails to 8 KiB, and log prefixes to 16 KiB for a task-header title. There are no snapshot uploads. The runtime has no external packages. At server startup it queries the installed Tailscale CLI once; it does not start Tailscale or sign in. The optional headless browser test is CPU-only.

The installed older DeepSeek runner may have `events.jsonl` instead of `log.txt`. This pilot does not treat that as an extra source. Its row can therefore say title unavailable and become stale until the common runner is installed. Likewise a queued job with no task header has only its issue number. Updating those runners is outside this job. Fixture evidence below has all required current titles from actual task-header log inputs.

The payload contains issue numbers, job titles, fixed GitHub links, state, safe reason categories, logical source names and timestamps. It contains no absolute PC paths, account names, raw result/log text, run command lines, model credentials or arbitrary status fields. Titles resembling paths, email addresses or tokens are withheld. Reasons use a fixed vocabulary derived from the runner's known messages; an unrecognized reason explicitly asks for local inspection. Do not add a raw reason/log fallback when extending this contract.

## Secure access options

Tailscale is the selected route, implemented by the Phone launchers above (issue 934, R305). Other rows remain alternatives from the November 16, 2026 pilot review. No Pages site, private repo or upload token was created. The game repository stays public; live snapshots must never be committed to it. Send only the derived status payload.

| Route | Setup Ryan would do in that run | Cost | PC off | Outsider sees |
| --- | --- | --- | --- | --- |
| **Pick: Tailscale, private network** | Install Tailscale on Windows and Pixel; sign both into the same personal tailnet; approve the two devices. The Board supplies a double-click launcher for Tailscale Serve to forward this localhost page over private HTTPS. Restrict its grant to Ryan's devices. Bookmark the tailnet URL. Do not enable Funnel. | Personal plan is $0 for personal use within its limits. No domain needed. | An already-open page ages into PC offline. A new visit cannot reach a powered-off PC, so the browser shows a connection error. No independent cloud history. | No reachable page without an authorized tailnet device. The identity provider and Tailscale still handle network/account metadata. |
| **Private status-only GitHub repo** | Create a separate private repo, keep Ryan as its sole reader, then create a fine-grained credential limited to its contents. In a later run the Board supplies the uploader and launcher. Sign into the GitHub app on Pixel and bookmark the current status file. Do not turn on ordinary GitHub Pages. | GitHub Free supports private repos at $0. Avoid Actions builds every minute. Frequent commits add status history and need periodic policy review. | Last committed file remains available with its report timestamp. The GitHub app file viewer does not run this HTML, so it cannot calculate an automatic offline banner; Ryan reads the timestamp. | No file contents without repo read permission. GitHub hosts the status and its commit history. A private repo does not automatically make a Pages site private. |
| **Cloudflare Pages plus Access email sign-in** | Create an empty Direct Upload project with a harmless placeholder. Enable Access for the production `project.pages.dev` hostname and all preview hostnames; allow only Ryan's email via one-time PIN, with no bypass rule. Verify unsigned access to both HTML and JSON is denied before the first status upload. Create an account-scoped Pages Edit token with no unrelated permissions. The Board later supplies its double-click uploader. | Access has a free small-team tier; Pages Free is a candidate, plus a domain if wanted. Confirm sustained minute Direct Upload limits before selection. Git-based builds have a 500/month Free allowance, which cannot support one build a minute. | Hosted last snapshot stays available after email sign-in; this page computes PC offline after 3 minutes even on a new visit. | The sign-in screen and public hostname, but no protected HTML, JSON or activity. Cloudflare stores the status. Access must cover direct production, preview and any custom-domain routes. |

Tailscale has the fewest credentials and moving parts for a local pilot. It keeps the live activity on the PC and meets the sign-in requirement through device authorization. If Ryan needs to open a working status page while the PC is off, choose Cloudflare Access after an access-denial and upload-cadence proof. Private GitHub is a useful signed-in file archive, but it loses this phone interface and automatic offline calculation in the app.

Tailscale details: [Personal plan](https://tailscale.com/docs/account/manage-plans/free-plans-discounts), [private Serve](https://tailscale.com/docs/reference/tailscale-cli/serve), [Windows and localhost examples](https://tailscale.com/docs/reference/examples/serve). The Phone launchers proxy `http://127.0.0.1:8918` and the publisher accepts this PC's own discovered tailnet Host with Serve headers. A real PC-to-Pixel check still needs Ryan's install and sign-in on both devices.

GitHub details: [Free private repositories](https://docs.github.com/en/get-started/learning-about-github/types-of-github-accounts), [private Pages access is a separate enterprise feature](https://docs.github.com/en/enterprise-cloud@latest/pages/getting-started-with-github-pages/about-privately-published-github-pages-sites). A repo login must never be replaced by a public raw-file URL or a token embedded in the phone HTML.

Cloudflare details: [Access email PIN](https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/one-time-pin/), [Access plans](https://www.cloudflare.com/sase/products/access/), [protect production and preview hostnames](https://developers.cloudflare.com/pages/platform/known-issues/#enable-access-on-your-pagesdev-domain), [Direct Upload](https://developers.cloudflare.com/pages/get-started/direct-upload/), [Pages limits](https://developers.cloudflare.com/pages/platform/limits/). The default preview protection alone is insufficient. A standard Pages Edit API token is scoped to an account, not assumed to be restricted to one project. A dedicated account and strict local storage reduce that write scope. Tokens must never travel to the phone.

## Checks and phone proof

Double-click `tools\pc\mission\selftest.bat`. It copies the committed fixture lane folders into a new `%TEMP%` folder, sets controlled write times, and runs the real publisher there. It verifies states, title/issue links, ordered queues, reruns, corrupt/missing sources, privacy, activity boundaries, unchanged inputs, output guards, real HTTP routes and process shutdown. Nothing is deleted, including test output.

Issue 934 adds deterministic Tailscale lookup and sign-in failures, Host checks over real localhost HTTP, proxy-header checks and simulated PHONE_ON/OFF commands. No test enables Serve or changes Tailscale. After Ryan signs in on the PC and Pixel, the remaining manual check is: PHONE_ON, open and refresh the printed address on Pixel with Tailscale connected, disconnect Pixel Tailscale and confirm a new request cannot connect, reconnect, then PHONE_OFF and confirm the phone link stops while `http://127.0.0.1:8918` still works. This manual phone proof is not claimed by the fixture tests.

Issue 934 resume verification: the Windows self-test passes 42 checks, including a slow cold start and a bounded failed start. The real PHONE_ON launcher started the local publisher and reached Tailscale's first-use Serve approval link on the signed-in PC. No Serve endpoint was enabled; that account step and the Pixel check remain for Ryan. The real PHONE_OFF launcher exits 0. With the background publisher running, the local page returns 200 after PHONE_OFF, while direct requests using the tailnet Host without Serve headers and an unrelated Host return 403. The page itself is unchanged, so no new pictures or GPU capture are needed.

Issue 934 standing checks: `node contrib/opus/tools/run_all_checks.js` exits 1 with 59 PASS, 2 KNOWN, 1 FAIL and no SKIP rows. `runner_selftest` exceeded its 600-second limit while still creating fixtures. No runner code was changed in this job. The stage-5 fault check passes all 37 checks with fake executables. The two KNOWN rows are the seven listed findings failures and 12 baseline oracle constant differences.

The optional browser proof is `node tools/pc/mission/browser_test.js [local shots folder]`, using installed Edge, Node's built-in WebSocket and headless CPU rendering. It creates fixture payloads from the same publisher, captures 412 x 720 PNGs, and checks offline aging after a lost fetch, fixed links, text escaping, all five rows and overflow at 320 and 412 px. `MISSION_BROWSER` can select another existing Chromium executable. Its browser profile and temporary inputs stay in `%TEMP%`. Screenshots are fixture proof from the working tree, not live activity or visual acceptance by Ryan.

The ordinary publisher serves no fixture endpoints. The browser check's temporary localhost server is the only server for the `?fixture=` proof links. Imported files use real time; fixture captures use the controlled test clock.

Pictures: [overview](../shots/mission/MC-918-overview.png), [running](../shots/mission/MC-918-running.png), [waiting](../shots/mission/MC-918-waiting.png), [blocked](../shots/mission/MC-918-blocked.png), [failed](../shots/mission/MC-918-failed.png), [finished](../shots/mission/MC-918-finished.png), [between jobs](../shots/mission/MC-918-gap.png), [stale](../shots/mission/MC-918-stale.png), [PC offline](../shots/mission/MC-918-offline.png), [unknown](../shots/mission/MC-918-unknown.png).

Run 2 verification: the Windows self-test launcher exits 0 with 31 passing checks. The gap fixture first failed on the run 1 publisher because #920 and #921 vanished. It now keeps the finished #918 result, #920 and #921 plus the waiting successor queue, and the chain source. Regression checks cover the next start, unsuccessful results, replacement by a newer live or completed chain, and replacement by a standalone runner. All ten 412 x 720 phone fixtures and browser behavior checks pass. Pictures are regenerated from this run's working tree.

Run 2 standing checks: `node contrib/opus/tools/run_all_checks.js` exits 0 with 60 PASS, 2 KNOWN and no FAIL or SKIP rows. The two KNOWN rows are the seven listed findings failures and the 12 baseline oracle constant differences. The Windows runner self-test passes 82 checks, and the stage-5 fault test passes 16. All ten picture revision/stage sidecars verify, and matching copies are saved in the issue's PC shots folder.

Run 1 verification, retained as history: both launchers exited 0; the publisher self-test passed 25 checks and nine phone fixtures passed. A real read-only scan found all five seats, took 615 ms and read about 2.2 MiB on first load. An unchanged repeat scan reread zero text bytes. Its standing command reported 58 PASS, 2 KNOWN and 2 FAIL rows (a sandbox hard-link refusal in the GPU-slot fixture and the stage-5 success fixture's `bakeAb6.py` failure, tracked separately in issue 916). No game code changes or additional Godot captures are part of run 2. Remote setup and sign-in tests remain deferred as the brief requires.
