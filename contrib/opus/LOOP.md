# Board loop state (LOOP.md)

**Board owner right now: the lead chat (Ryan, Nov 4 21:33 CST).** The hourly scheduled task "Voidsworn board loop" is switched off until the weekly Claude usage reset: its runs kept stopping for approvals and were refused merges. The lead chat runs the board with one-off send_later checks until Ryan revisits it. When the hourly task is back on, it becomes the only owner again (R102). Any other Claude chat on this repo works one named area or only reads.

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

## Current state (2026-11-05 03:50 UTC)

- Codex: #187 (Pyre-Barge round 6) running since 03:29Z. It started before the paint standard merged, so it may not follow #188 exactly.
- Merged tonight: #186 (round 5 tools), #190 (#183 station detail shapes), #191 (#188 readable-paint standard), #192 (#189 backlog check), plus FINDINGS R103 to R106.
- Latest playtest exe: g2_pt_d03ac22 (no deaths 2, no station detail yet).
- PC disk: about 100 GB free.

## Queue order (Codex)

From the backlog check (R106, synthesis section 5), with the station repaint added (R104):

1. #187 Pyre-Barge round 6 (running). HOLD its PR for Ryan.
2. #195 station repaint (blocked; release after #187). Stop for Ryan's look.
3. #139 nebulas and ion storms (deaths #137 and weapons #138 are already merged, so R88's order is met).
4. #140 rocky and terran planets.
5. #120 Nemesis redesign 1.
6. #121 Nemesis redesign 2 (NEM_VOICE from contrib/muse/design/nemesis_writing_2026_11/text_table.md, R101).
7. #122 Nemesis redesign 3.
8. #24 progression step 7 (edited, after #121).
9. #26 progression step 10.
10. #27 progression step 11 (edited: XP by line only).
11. #29 progression step 13.
12. #30 progression step 14.
13. #92 debrief screen (edited, after #24 and #122).
14. #100 terrain fx 2 (edited; #60 merged as PR #143 on Nov 5, R107, so build on its wreckage kit).
15. #169 breakable Pyre-Barge (edited; after Ryan's round 6 pick and #167, which is merged).
16. Later: #41, then #42, then #44.

## Holds

- PR from #187 (round 6): hold for Ryan's pick; send the comparison sheet, the blurred greyscale check and both ceiling numbers.
- PR from #195 (station repaint): hold for Ryan's look.
- Issues #193 (Tripo per-part test) and #194 (five ship-pipeline options): Muse proposals labelled opus, parked until the weekly reset. Note: Tripo is a paid cloud service; the house rule is free and local tools only, so #193 needs Ryan's call before any work.

## Waiting on Ryan

- Round 6 pick when #187 lands.

## Muse

- Open: none. #188 and #189 delivered and ruled (R105, R106).

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

- 2026-11-05 03:50 lead chat: took the board back (hourly task switched off by Ryan until the weekly reset). Merged #190, #191, #192. Recorded R104 to R106, applied the backlog edits to #24, #27, #92, #100, #169, filed #195 (station repaint), rewrote the queue.

- 2026-11-05 03:40 loop: took over a stale 01:38 lock. PC folders not connected to the run, worked from GitHub only. Reviewed Muse PRs #191 and #192 (good); merge refused by the scheduled run's approval check, left for Ryan. Released #187. PR #190 stations held for Ryan. #193 and #194 not triaged.
- 2026-11-05 02:00 lead chat: the hourly task had no PC folders attached, so every run asked Ryan for access. Replaced it with an identical task (runs at :58, first 02:58 UTC) with Downloads\voidsworn_test and the Godot app_userdata\Voidsworn folder attached. Runs must not request other folders.

- 2026-11-05 00:25 lead chat: hourly runs at 22:37 and 23:37 sat pending until Ryan approved the task in the desktop app; he says it now runs. Merged #186 (round 5 tools), filed #187 (R103), released #183.

- 2026-11-05 00:22 loop: #163 done, PR #186 reviewed and held, round 5 pick sent to Ryan; #183 found already unblocked, waiting for the board to queue it.
- 2026-11-04 21:40 lead chat: loop moved to this file and the hourly scheduled task "Voidsworn board loop" (runs at :37 each hour, first run 22:37 UTC, auto approval, needs Ryan's PC) (R102). #163 running. No send_later checks pending.
