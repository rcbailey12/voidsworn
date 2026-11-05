# Board loop state (LOOP.md)

**This loop is the only owner of the job board** (Ryan, Nov 4 2026, FINDINGS R102). Only the hourly scheduled task "Voidsworn board loop" (and a one-off send_later check it schedules) queues jobs, merges PRs and releases blocked issues. Any other Claude chat on this repo works one named area or only reads.

## Lock

Running: no
Running since (UTC): 2026-11-05 03:27
Last run finished (UTC): 2026-11-05 03:40

If "Running: yes" and the start time is under 90 minutes old, another loop is working: stop without changes. If it is older, the last run died: take over and say so in the log.

## How a run works

**Usage is low (Ryan, Nov 4 15:43: about 3% of the weekly Claude usage left, keep the loop hourly).** Keep runs short: if nothing changed since the last run (same running job, no new PRs, no new answers from Ryan), do not take the lock, do not rewrite this file, just stop. Only read the files and screenshots a decision needs.

1. Read HANDOFF.md section 0 and this file. Set the lock (Running: yes, time) and push it before doing anything else.
2. Board check (Sonnet subagent is fine): queue_b and queue_b\running on the PC, board\issue-N result.txt and log tails for running or finished jobs, open PRs, open issues and labels.
3. Review each new PR yourself (Opus): read the claims, look at the shots in board\issue-N\shots, check the claims against the diff and the done-when list. Merge if good. Hold the ones listed under Holds.
4. Release the next job in the queue order below (remove its blocked label, one at a time), but only when nothing is running or queued for Codex. Before writing any job file, check queue_b, queue_b\running and board\queued.txt for that number, to avoid duplicate runs.
5. Anything that needs Ryan goes under "Waiting on Ryan", with a recommended option and plain-word trade-offs, and gets one PushNotification. Never ask with AskUserQuestion from a scheduled run (nobody is there). If Ryan answered in chat or in this file, record it in FINDINGS and act on it.
6. Tell Ryan only when something lands or needs him: two lines and one image, by PushNotification.
7. Rewrite this file (state, queue, holds, waiting, log), set "Running: no", commit straight to main (this file only, docs-only exception) and push with timeout 90. Stop.
8. If a job will finish or a usage limit will reset well before the next hourly run, schedule one send_later check for just after it. Never chain send_later loops.

## Current state (2026-11-05 03:40 UTC)

- **PC folders not reachable from the scheduled run.** The 03:27 run's device connection listed no connected folders (get_device_info connectedFolders empty), so queue_b, board\issue-N and shots could not be read. The run did not request access (that would prompt Ryan). Until fixed, the loop works from GitHub only and cannot see running jobs, logs or shots.
- **Merges refused in the scheduled run.** The auto approval check denied gh api PUT .../merge on #191 and #192 ("merge without review"), even after an Opus review. Do not route around it with another merge tool. Merges wait for Ryan (one click on GitHub) or for a chat he is in.
- Codex: #183 finished; PR #190 open (checks pass, tools only: station_kit.py, station_check.gd, station_sheets.py; fleet 11,636 tris, refinery 6,656, about 0.04 ms at 4K; shipping swap not done). HELD for Ryan's look; shots are on the PC at board\issue-183\shots\station_overview.jpg and DELIVERY_NOTES.md (flags unchanged baseline turret pivots).
- #187 round 6 released 03:35Z (blocked label removed). The board should queue it on its next poll. The #188 paint standard is not on main yet (PR #191 unmerged), so round 6 may run without it; its issue allows that.
- Muse: PR #191 (#188 readable paint standard) and PR #192 (#189 backlog check) reviewed by Opus: contrib/muse only, checks pass (#192's open-pr job failed, which is only the auto PR opener). Both good to merge.
- New opus issues #193 (Tripo per-part challenger test) and #194 (five ideation options for the ship look pipeline), filed 02:40Z and 03:23Z as proposals. Not triaged yet (usage is low); triage in a chat with Ryan or a later run.
- Latest playtest exe: g2_pt_d03ac22 (passed). Not in it yet: #185 deaths 2.
- PC disk: about 100 GB free at last look.

## Queue order (Codex)

1. #163 Pyre-Barge round 5: done; PR #186 merged as tools only (lead chat, R103: paint rejected).
2. #183 station detail pass: done, PR #190 held for Ryan's look.
3. #187 Pyre-Barge round 6 (R103). Released 03:35Z. HOLD its PR for Ryan.
4. #139 nebulas and ion storms (blocked).
5. #140 rocky and terran planets (blocked).
6. #92 debrief screen.
7. #100 terrain fx 2 (needs #60 decided; see Holds).
8. Progression #24, #26, #27, #29, #30.
9. Nemesis #120, #121 (uses contrib/muse/design/nemesis_writing_2026_11/text_table.md, R101), #122.
10. #169 breakable Pyre-Barge: only after Ryan picks a round 6 hull (R98, R99, R103).
11. Later, not yet scheduled: #41, #42, #44.

Muse #189 (PR #192) proposes a new order: Nemesis #120 to #122 before progression, #92 after #24 and #122, #60 decision as a gate before #100, #169 also gated on #167 (already merged as #185). Apply it and its five issue edits once Ryan answers its questions (Waiting on Ryan).

## Holds

- PR #190 (#183 stations): hold for Ryan's look.
- PR from #187 (round 6): hold for Ryan's pick; send the comparison sheet, the blurred greyscale readability check and both ceiling numbers.
- PR #143 (#60 debris): parked. Unpark only if Ryan asks; then close #143 and drop 60 from queued.txt.

## Waiting on Ryan

- **Reconnect the PC folders for the hourly task** (asked 03:40). The 03:27 run saw no connected folders. Recommended: open the "Voidsworn board loop" task in the desktop app and re-add Downloads\voidsworn_test and the Godot app_userdata\Voidsworn folder, with the desktop app left open. Without it the loop cannot see jobs, logs or shots.
- **Merge PR #191 and PR #192** (asked 03:40). Both reviewed, Muse docs only, checks pass. The scheduled run is not allowed to merge on its own. Recommended: merge both on GitHub, #191 first so round 6 can use the paint standard. Trade-off: none known; they add files under contrib/muse only.
- **Station look, PR #190** (asked 03:40): open board\issue-183\shots\station_overview.jpg on the PC. Recommended: approve if the stations read better at battle distance; the shipping swap is a separate step after that.
- **#188 paint standard questions** (PR #191, synthesis section 6). Chair picks, recommended as is: Q1 1080p binds (a plate that passes at 1080p passes at 4K). Q2 two value step tiers, not a flat 25 everywhere (a flat step pushes Hegemony out of its own colours). Q3 Hullbreaker rust may form full plates inside the rust budget (break-up only is the stricter option). Q4 close-range paint rules come after two hulls pass the battle test. Q5 seven of nine clean cells is the paint sign-off bar, for any hull however it was built.
- **#189 backlog check questions** (PR #192, synthesis section 7). Chair picks, recommended as is: Q1 unpark #60 (PR #143) for one look, since #100 builds on its debris kit. Q2 run Nemesis #120 to #122 before the progression steps, so the work is not done twice. Q3 keep #24 as its own step after #121. Q4 move #92 debrief behind #24 and #122. Q5 let Opus apply the issue edits and the new queue order.
- Pyre-Barge round 5 pick: superseded by R103 (round 6, #187). Nothing to answer.

## Muse

- #188 and #189 delivered as PR #191 and #192; reviewed, waiting only on the merge click. No Muse jobs open after those.

## Known traps

- Never list queue\logs, queue_b\logs, queue\done or big shots folders recursively; they are huge. Stage the one file you need.
- PC access is only device_list_dir, device_stage_files and device_commit_files. Never delete anything on the PC; ask Ryan.
- Duplicate runs: the board (codex_board.ps1, every 10 minutes) queues any unblocked open codex issue that is not in board\queued.txt and has no open PR from codex/issue-N. If you also write a job file, it runs twice. Prefer letting the board queue it; write cx_issue<N>_job.bat yourself only if a poll has passed with nothing queued. Keep finished issues in queued.txt.
- A duplicate run of an already merged job force-pushes the branch and auto_pr opens a new PR: close it with a note, do not merge.
- Usage limit: result.txt says "usage limit hit, left on the board to retry"; grep log.txt for "try again at" (Central time). The runner drops the number from queued.txt, so the board retries every poll until the reset. Do not requeue by hand; schedule one send_later check just after the reset.
- Codex has a one-hour cap per run (tmo 3600). Heavy GPU bake-offs can need two runs: back up the branch (git push origin origin/codex/issue-N:refs/heads/opus/issue-N-run1), add a resume note to the issue body, close the PR, drop N from queued.txt.
- GitHub's PR list can lag a few minutes after a close, and the board then re-adds the number to queued.txt. Check on the next run.
- Never put |, &, < or > in job arguments. Job .bat files are CRLF.
- git push from the sandbox can hang: wrap in timeout 90 and retry once.
- gh GraphQL is blocked: use gh api REST (pulls, issues, merges). Branch deletion and repo settings are refused by the proxy.
- Questions for Ryan go in chat or this file, never as GitHub tags. Plain words, no em dashes, no human-hour estimates (R99).

## Playtest exe recipe (lane A)

Check ship files are unchanged first (git diff --stat <last build hash> origin/main -- godot/assets/ships). Zips from origin/main with git archive: src1 = godot portraits; src2 = godot audio world; src3 = godot campaign fx main render rules scenes story ui; tools = tools/pc (prefix kept). Copy manifest and mcheck from the last build (build\g2_pt_<hash>_*). Copy the last bat (queue\done\g2_pt_<hash>.bat), replace the hash, rewrite line 2, CRLF. Zips to Downloads\voidsworn_test\build\, bat to Downloads\voidsworn_test\queue\. Results in shots\g2_pt_<hash>\result.txt (expect MANIFEST OK, export exit 0, title and battle exits 0). About 20 minutes.

## Who does what

- Opus: merge calls, PR claim checks against the diff, visual judgment, planning, issue writing, messages to Ryan.
- Sonnet subagents: board checks, log reading, renames, staging files, capture jobs.
- Codex: coding jobs from the board (local on Ryan's PC). Muse: research, design text, low-code PRs.

## Log (newest first, keep about 10)

- 2026-11-05 03:40 loop: took over a stale 01:38 lock. PC folders not connected to the run, worked from GitHub only. Reviewed Muse PRs #191 and #192 (good); merge refused by the scheduled run's approval check, left for Ryan. Released #187. PR #190 stations held for Ryan. #193 and #194 not triaged.
- 2026-11-05 02:00 lead chat: the hourly task had no PC folders attached, so every run asked Ryan for access. Replaced it with an identical task (runs at :58, first 02:58 UTC) with Downloads\voidsworn_test and the Godot app_userdata\Voidsworn folder attached. Runs must not request other folders.

- 2026-11-05 00:25 lead chat: hourly runs at 22:37 and 23:37 sat pending until Ryan approved the task in the desktop app; he says it now runs. Merged #186 (round 5 tools), filed #187 (R103), released #183.

- 2026-11-05 00:22 loop: #163 done, PR #186 reviewed and held, round 5 pick sent to Ryan; #183 found already unblocked, waiting for the board to queue it.
- 2026-11-04 21:40 lead chat: loop moved to this file and the hourly scheduled task "Voidsworn board loop" (runs at :37 each hour, first run 22:37 UTC, auto approval, needs Ryan's PC) (R102). #163 running. No send_later checks pending.
