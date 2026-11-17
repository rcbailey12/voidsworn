# Mission Control upgrade: plan r3 (Nov 17 2026, design and plan only)

This revises r2 (`../r2/UPGRADE_PLAN.md`) after your 16:21 UTC review. Nothing is built, and no settings or PC changes were made. I checked it against main `fb42f85e`, the PC runner files for #975, and the r2 findings. Every mockup beside this file is labelled SAMPLE. The pictures in them are real game pictures, each labelled with its own issue, revision and stage.

## 0. Pick, and what's possible now

**Pick:** keep r2's data foundation with the five corrections below, and ship the new deck look *with* real pictures in the same release (Run 2). The publisher restart stays a separate one-step decision.

| | Possible now from existing data | Needs new data or a new habit |
| --- | --- | --- |
| Codex lanes (4) and DeepSeek | Live state from the runner's own files: claimed, working, quiet, ended, failed, with matching run ids | none |
| Claude, Muse/Rey, Artoo | "Last seen on GitHub" (PR updates, comments, merges), drawn with a dashed ring and never called working | Real-time status: each agent would have to write a small status record. Not proposed. |
| Pictures | Stamped pictures (sidecar with stage and revision) from the lane's checkout on the PC and from main | Pictures with no sidecar are never shown |
| Your questions | `ryan` label plus the "Ask Ryan: … \| Picture: …" line (approved in r1) | none |
| Installed on your PC / your OK | Shown as "not tracked" | A label or habit, if you want it later |
| History and timeline | Last-known values only | A stored history. Still out. |

**What changed since r2:**
- The Board already landed the chain habit. Main `fb42f85e` makes waiting chains write `waiting for <exact file>.txt` and stopped chains write "cancelled by the Board" or "paused by the Board" (LOOP.md duty 10). Step B is done.
- The restart is still not approved and stays separate. It fixes "runner unknown" and "GitHub not read" today. It does **not** fix the queue bugs: those are in main's code and need Run 1.

## 1. The new look (mockups)

- `MC_r3_side_by_side.png`: the current page, the new overview and the new task view.
- `MC_r3_states.png`: decision, failure, GitHub unavailable and PC offline.
- Single frames are `MC_r3_*_mockup.png`, each 412 x 720. The HTML source is `mockup_source.html`.

**Direction: an operations deck from the game, not a dashboard of boxes.**
- **Game palette and type.** The palette comes from the game's own theme (`godot/ui/theme`): iron-black ground, bone text, and one lime accent kept for things that need you. Green means live work, amber means quiet or partial, coral means failure. The type is the game's: Big Shoulders for the compact header, Chakra Petch for titles and labels, Barlow for reading, Azeret Mono for evidence.
- **Depth without gauges.** There is a faint hex-grid texture, a soft vignette, and one tick-mark rule under the header. There are no dials, and nothing moves (reduced motion is respected by having no motion).
- **Varied composition.**
  - The most important active art job gets a full-bleed hero picture with its stage chip, and its title sits over the picture.
  - A slim five-step track shows the real stage.
  - The crew sits as five emblems: a solid ring means the evidence comes from PC files, a dashed ring means GitHub only.
  - Code jobs are compact rows with hairline dividers, no outlined boxes.
  - A missing picture is a deliberate hatched tile reading "no picture yet".
- **Crew identities.** Five original glyphs:
  - Claude: a hollow sun ring, sand.
  - Codex: a nested hex, steel teal.
  - DeepSeek: stacked chevrons, blue.
  - Muse/Rey: a crescent, violet.
  - Artoo: the white and blue droid you approved.
- **Your question takes over the top.** It shows the actual question in large type, and the two options at full phone width (A and B, about 380 x 150 px each). Each option carries its issue, revision and stage. The page says to answer the Board in chat, because the page stays read-only.
- **Failure in plain English.** The failure view says what happened, what it means, and who acts next. Evidence opens inline. An older picture is badged "OLDER PICTURE · run 2 · not this run".
- **Unavailable source.**
  - Only the parts that came from the missing source change. They get an amber stripe and "last known at …".
  - With the PC offline, everything greys, the hero picture desaturates, and every state becomes "was working, last known 15:58".
- **Navigation: Now / Queue / Crew** as a thumb bar. Now holds everything urgent, so nothing important needs a tab. Queue holds full chains and history, and Crew holds each agent's last-seen detail. Without them, Now would grow long.
- **Contrast.** Measured on the deck ground `#090c09`:
  - Body text 16.6:1, secondary 8.7:1, dim 5.2:1.
  - Lime 15.5:1, green 10.9:1, amber 10.9:1, coral 8.5:1.
  - Dim text drops to 4.4:1 on the lighter iron panel, so the build must keep dim text off that panel. The browser test checks this.

**Sample changes since r2:**
- The sample now uses jobs that have real stamped pictures:
  - #970 Iron Mandate (installed in game, rev 23a9f63)
  - #929 shields egg vs fitted skin (installed in game, rev d5ee38b plus working tree)
  - #928 hull hit (installed in game, rev 67aa441)
- The question, status and times are still sample. Each state frame is its own sample moment.

## 2. The five data corrections

### 2.1 Waiting successors are kept until they start, are cancelled, or are explicitly superseded

r2 was wrong: it sent a waiter to history when its predecessor finished, which is exactly when it becomes ready. It also hid closed issues, but a chain's `.bat` will still run a closed issue, so hiding it would misstate what the PC will do.

Each waiting chain gets one of these states:

| State | Evidence | Shown as |
| --- | --- | --- |
| linked | Its `waiting for <file>.txt` names exactly one chain or lane file, and that chain is live | "Up next after #N" |
| ready | The named predecessor has ended (all done, a terminal result, or a cancelled or paused line), and this chain has no start line yet | "Ready since 16:02, not started yet". After 15 min it turns amber: "Ready 40 min, not started. The waiting script may not be running." It is never archived. |
| started | It has its own start line | It becomes the lane's current job |
| cancelled / paused | Its own log says cancelled or paused by the Board, or stopped | Moves to history, with that reason |
| superseded | An explicit line only: "superseded by <file>.txt" in its log, or a newer chain for the same lane whose bat lists the same issue *and* says "replaces <file>.txt" in its rem line | Moves to history: "replaced by …" |
| unknown | The target matches no file, more than one file, or a cycle | Lane queue shows "Queue unknown", with the reason in evidence |

Two more rules:
- **Closed on GitHub:** an issue that is closed but still listed in a waiting or running chain stays in the queue, marked "closed on GitHub; the chain still lists it". Only the Board's cancel line removes it.
- **Branches:** when two chains wait on the same predecessor, both stay in the queue in bat order, with the note "2 chains wait on 16F".

```
resolveQueue(chains, now):
  byFile = map lower(chain.txtName) -> chain
  for c in chains where c.waitTarget:
     t = normalise(c.waitTarget)          // exact file; old "chain 16F"/"lane D10" forms still parsed
     hits = byFile[t] ? [byFile[t]] : []
     c.pred = hits.length == 1 ? hits[0] : null
     c.why  = hits.length == 0 ? 'unresolved' : null
  for c in chains: if inCycle(c) -> c.state='unknown', c.why='cycle'
  for c in chains:
     if c.started                     -> 'started'
     elif c.terminal                  -> c.terminal          // cancelled|paused|stopped -> history
     elif supersededExplicitly(c)     -> 'superseded'        // history
     elif !c.pred                     -> 'unknown'
     elif c.pred.state in live        -> 'linked'
     elif c.pred.ended                -> 'ready', readySince = c.pred.endedAt
     else                             -> 'unknown', why='predecessor state unknown'
  queue(lane) = active.remaining ++ walk(linked|ready successors, bat order)
  queue.status = any unknown on this lane ? 'unknown' : 'known'
  each item: github = issueState(n) ?? 'unverified'   // open | closed (still listed) | unverified
```

### 2.2 A result only counts for the run it names

Verified on the PC:
- The runner writes the full run id in `status.json` (`"run": "2399d27b4eb74e3588a7e8242dae9961"`).
- It also writes the same full id in `result.txt` ("job claimed: issue #975 by codex, run 2399d27b…").
- The lane checkout is `<lane>\repo`, which is shared across that lane's jobs.

Rules (internal comparison uses the full 32 characters, and the page shows 8):
- A terminal result counts only if its run id **equals** status.json's run id. File time is never enough.
- **Untagged result** (no "job claimed … run" line): it never overrides a status that has a run id. If they conflict, the state is Unknown: "result has no run id".
- **Old result arriving late** (a tagged run that isn't the current one): ignored for state, and listed in evidence as "previous run 7c1e04b2 ended 15:20".
- **New run with stale files:** log, checks and picture writes count as activity only when they are newer than this run's `started` time. Older files show as "from an earlier run".
- **No status.json** (older runners): a result may prove failure, never a checked success. That keeps today's rule from `publisher.js:209`.
- **DeepSeek's runner** may not tag results the same way. *Unsure: I have not read a DeepSeek result file.* Run 1 checks this first. If the tag is missing, DeepSeek conflicts show Unknown. Adding a tag would be a small runner change, which belongs to the Board's runner work.

### 2.3 One shared GitHub budget, well under the limit

54 of 60 was too close. The unauthenticated limit is per network address, so anything else on your network reading the API without a key shares it. *Unsure how often anything else does.*

- **One budget object** guards every request: scheduled reads, extra pages, retries, targeted lookups and the cold start. Nothing calls GitHub around it.
- **Planned use is about 24 an hour; the hard ceiling is 30 an hour.**
  - Your questions (`ryan` label, open): every 10 min = 6
  - Issues changed since the last read: every 10 min = 6
  - Pull requests: every 10 min = 6
  - Comments and main commits: every 30 min = 4
  - Targeted issue lookups: at most 2 an hour
- **The server's own counter wins.** When `x-ratelimit-remaining` reads 15 or fewer (left for other tools), every read pauses until the reset time.
- **Backoff.** A failing source doubles its interval (10, 20, 40, then 60 min), with a little random spread. A 403 or 429 rate-limit reply pauses everything until reset plus 1 min.
- **Cold start.** Reads are spread over 3 minutes, questions first. The page says "checking" until each source has a first good read.
- **Paging.** Each page costs one request. If the budget runs out mid-list, that source is "not fully checked", and the page never shows "no questions".
- The page shows each source's age, and the budget sits under Sources in evidence.

### 2.4 One set of thresholds, each with its own name

| Name | Measures | Threshold | Page says |
| --- | --- | --- | --- |
| PC feed | The publisher's own snapshot time (it ticks each minute) | Over 3 min (today's `OFFLINE_SECONDS`) | "PC feed lost · N min". Everything becomes last known. |
| GitHub source | That source's last good read | Over twice its interval | "GitHub not read since HH:MM" |
| Claim check | Chain start or running label, with no runner status for this run | 10 min | "Claimed, not started" for up to 10 min, then amber "Claim not confirmed" |
| Work activity | The newest log, checks or result write for **this run** | 30 min (today's `STALE_SECONDS`) | Within 30 min: "Working · log N min ago". Over 30: amber "Quiet N min, process not confirmed". It is never shown as idle. |

A fresh PC feed proves only that the publisher is reading. It says nothing about whether the job is working.

### 2.5 Honest coverage, and pictures brought forward

The first release shows:
- Codex and DeepSeek from their PC files.
- Claude, Muse/Rey and Artoo only as "last seen on GitHub". No imaginary feed, and no second queue.

Pictures move into Run 2:
- **This run's picture.** The newest picture under `<lane>\repo\docs\` whose sidecar exists **and** whose sidecar date is after this run's start. Its badge shows stage and revision from the sidecar.
- **Otherwise, the newest stamped picture on main for that issue.** It is badged "OLDER PICTURE · from main · not this run".
- **Otherwise,** the hatched "no picture yet" tile.
- A concept or paint proof is never labelled as in game: the stage chip comes only from the sidecar's stage field.

## 3. Running version, kept separate from the fixes

- **Step A (needs your OK):** restart the publisher once. It reads files only, and no jobs are touched.
- **The build block** goes in the snapshot: `{id, diskId, startedAt, stale}`.
  - `id` is a hash of `publisher.js`, `index.html` and `phone.js` at start. `diskId` is the same hash of the files on disk now.
  - The process id stays local to `phone.js` and is not shown on the page.
- **On the page:** the Sources sheet shows "version fb42f8 · running since 06:50". When `stale` is set, or the snapshot is schema 1, a coral bar reads "Mission Control is running an older version. Restart with PHONE_ON."
- **`phone.js`** offers "Restart now? Y/N" when the build differs. It stops only the publisher process whose command line ends in `mission\tools\pc\mission\publisher.js`, and only after Y.

## 4. Build sequence and size

| Step | What | Where | Size |
| --- | --- | --- | --- |
| A | Restart the old publisher | You say yes; the Board runs it | no run |
| B | Waiting and cancelled line habit | Done on main `fb42f85e` | done |
| 1 | Data: queue, run-id matching, budget, thresholds, build block, picture index | Codex code lane (C or D), no GPU | 1 run, about 2 review rounds (logic heavy) |
| 2 | Page: new deck, task view, states, picture route, browser tests, labelled pictures | Codex code lane | 1 run, 1 to 2 review rounds |
| 3 | Real PC and Pixel check (section 8) | Board, then you on the Pixel | no run |

Both runs go in one issue with two run briefs, after Step A or alongside it. Neither touches files used by #978, #979, #980 or #984.

## 5. Files and changes

| File | Change |
| --- | --- |
| `tools/pc/mission/queue.js` (new) | `resolveQueue`, `normalise`, `inCycle`, `supersededExplicitly` (2.1). Pure functions, easy to test. |
| `tools/pc/mission/budget.js` (new) | The shared budget: `canSpend()`, `spend()`, header update, backoff, pause until reset (2.3) |
| `tools/pc/mission/publisher.js` | `readChain` records the wait target, start and terminal lines, and the bat's rem text. `jobInfo` and `classify` (`:150-212`) apply the run-id rules (2.2) and named thresholds (2.4). The GitHub reader (`:244-309`) gets per-source records and stores issue `state`. The needs-Ryan query follows pages through the budget. Adds the `build` block, `pictureIndex(lane)` and snapshot schema 2. |
| `tools/pc/mission/phone.js` | `probe` reads schema 1 or 2. `ensurePublisher` compares builds and offers the restart (section 3). |
| `docs/mission/index.html` | Rewritten as the deck: Now / Queue / Crew, task view, states. Renders schema 1 with the old-version bar. |
| `docs/mission/fonts/` | Add Big Shoulders Display, Chakra Petch Medium and Bold, and Barlow Medium, copied from `godot/ui/theme/fonts` with their OFL licence files |
| `docs/mission/crew/*.svg` | The five glyphs. Artoo reuses `artoo.svg`. |
| `tools/pc/mission/selftest.js`, `phone_selftest.js`, `browser_test.js`, `fixtures/` | Tests in section 7 |
| `docs/mission/README.md` | The source contract (section 6), state and threshold tables |

**New read-only route: `GET /pic/<id>`.** The `id` is an opaque hash from the snapshot's picture index, never a path.
- The server serves only files it indexed itself. Each must sit under `<lane>\repo\docs\shots\` or `docs\ship_pipeline\`, have a valid sidecar, have a `.png`, `.jpg` or `.webp` extension, and be at most 3 MB.
- The response is fixed, with no directory listing and no query parameters. Everything else returns 404.
- This is a new route, though not a control route, so it is one of your decisions (section 9).

## 6. Source contract (what each source may claim)

| Source | Read | May claim | Never claims |
| --- | --- | --- | --- |
| Chain `.txt` and `.bat` | Wait target, start, end, cancel and pause lines; issue list | Assignment, queue order, ready | That a process is alive |
| Job `status.json` | Run id, started, status, finished | Runner state for that run | Anything about another run |
| Job `result.txt` | Run id line, terminal line | Result for the matching run | Success without status.json |
| Log, checks and picture times | Modified time after the run start | Work activity | Progress percentage or ETA |
| Picture sidecar | Stage, revision, date | The picture's stage and revision | That it is current, unless it is newer than the run start |
| GitHub issues | Title, state, labels, Ask Ryan line | Open or closed, the running claim, your questions | That a worker is alive |
| GitHub PRs, comments, commits | Branch to PR link, state, times | "Last seen on GitHub" | Installed on your PC, your OK, live activity |

**Never on the page:** tokens, `C:\` paths, user names, the status file's `folder` or `marker` fields, raw log or comment text, or run ids longer than 8 characters.

## 7. Tests

**Your real screenshot (the Nov 17 15:54 file set I staged, with real times).**
- Old publisher plus new page: the schema 1 bar shows.
- With the new code:
  - Main shows #863, then #982 via 16G.
  - Lane B shows #975, with no #922 (B25 is cancelled).
  - Lane D lists #984 via D11.
  - Paused and cancelled 15H, 15Z, 16A and B25 are in history.

**Queue:**
- Between jobs: the predecessor ended 2 minutes ago and the successor has no start line, so the item shows "Ready". At 40 minutes it is still listed, now amber.
- Cancelled and paused chains go to history.
- Explicit supersede goes to history; an implicit newer bat does **not**.
- Ambiguous target (two files match), unresolved target, and a 2-chain cycle all show Queue unknown.
- Two chains waiting on one predecessor are both listed, in order.
- A closed issue still in a chain stays listed, marked closed.

**Run ids:**
- A tagged terminal result for the same run means Failed or Ended, even while the GitHub label still says running.
- An old tagged result arriving after the new run's start is ignored and listed as previous.
- An untagged newer result against a running status shows Unknown.
- On a new run, logs, checks and pictures older than its start do not count as activity.
- The run id is truncated on the page, and the full id never reaches the snapshot.

**Budget:**
- Cold start stays within 3 requests per minute.
- A 3-page question list costs 3 requests. If page 2 fails, the questions show "not fully checked".
- Retries draw from the same budget.
- An hour of simulated reads stays at 30 or fewer.
- A header showing 15 or fewer remaining pauses all reads.
- A 403 with a reset time pauses everything, then recovers.

**Per-source outages, one at a time:**
- The PC feed is 4 minutes old.
- Each GitHub source down alone, while the others update.
- One lane's status.json is unreadable: that lane shows Unknown and the others are unaffected.
- A picture file is missing or its sidecar is invalid: "no picture yet".

**Thresholds:**
- Claimed with no runner status: "Claimed" at 9 minutes, "not confirmed" at 11.
- A fresh PC feed with a 31-minute-old log shows Quiet, never Working and never idle.

**Privacy:**
- The snapshot and HTML contain no `C:\`, user name, token pattern, `folder` or `marker`, or log text.
- `/pic/` rejects `..`, encoded slashes, unindexed ids and non-image files.
- No route accepts POST.

**Page, in the browser:**
- 320 and 412 px widths with no sideways scroll.
- A 240-character title.
- Each state in the mockups, rendered from fixtures.
- 44 px touch targets.
- Computed contrast of at least 4.5:1, including dim text on panels.
- Reduced motion: nothing animates.
- Pictures labelled with issue, revision and stage, and the older-picture badge where it applies.

## 8. Real PC and Pixel check (after merge)

1. The Board copies the merged files and runs `publisher.js --once` to a temp folder. For each lane, it compares the card with the newest chain txt, the bat list, status.json, log time and GitHub state. Any difference blocks.
2. The Board compares your questions with GitHub's own `label:ryan is:open` list.
3. Restart through PHONE_ON. The header's version must equal the merged files' hash.
4. You, on the Pixel over Tailscale:
   - Times move each minute.
   - Open one job and check its story and picture label.
   - Turn Tailscale off and on: the page should not load while off and should recover after.
   - Run PHONE_OFF: the local page still works.
5. The PR carries 412 px screenshots of the live page, labelled with revision and stage.

## 9. Your decisions

1. **Restart the old publisher now?** It is read-only and touches no jobs. **My pick: yes.** It fixes "runner unknown" and "GitHub not read" today. The queue fixes still need Run 1.
2. **Picture route.**
   - **My pick:** the new read-only `/pic/` route, so the hero shows this run's picture before it is pushed.
   - The alternative: no new route, and pictures only once they reach main. That is safer to reason about, but pictures arrive later.
3. **Now / Queue / Crew bar.** **My pick: yes.** Everything urgent stays on Now.
4. **GitHub key.** **My pick: still no key.** The new budget plans about 24 an hour, with a hard ceiling of 30.

Unchanged defaults, unless you say otherwise:
- Installed and your OK show as "not tracked".
- Timeline and stored history stay out.
