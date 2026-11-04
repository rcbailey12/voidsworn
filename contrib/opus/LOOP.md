# Board loop state (LOOP.md)

**This loop is the only owner of the job board** (Ryan, Nov 4 2026, FINDINGS R102). Only the hourly scheduled task "Voidsworn board loop" (and a one-off send_later check it schedules) queues jobs, merges PRs and releases blocked issues. Any other Claude chat on this repo works one named area or only reads.

## Lock

Running: no
Running since (UTC): -
Last run finished (UTC): 2026-11-04 21:40 (set up by the lead chat)

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

## Current state (2026-11-04 21:40 UTC)

- Codex: #163 (Pyre-Barge round 5) running since 21:28Z, after a usage limit that reset at 21:28Z.
- Latest playtest exe: g2_pt_d03ac22 at Downloads\voidsworn_test\build\export\Voidsworn.exe (passed). Not in it yet: #185 deaths 2.
- PC disk: about 100 GB free after Ryan's cleanup (sync_old holds only g2_pt_d03ac22). Skip new playtest builds if free space drops under 60 GB and ask Ryan to clean sync_old.
- Merged today: #149 #150 #151 #153 #154 #155 #157 #158 #159 #160 #161 #164 #165 #170 #174 #175 #176 #177 #178 #179 #180 #181 #185 and the R-row PRs.

## Queue order (Codex)

1. #163 Pyre-Barge round 5 (running). HOLD its PR for Ryan.
2. #183 station detail pass (blocked; release after #163). Stop for Ryan's look.
3. #139 nebulas and ion storms (blocked).
4. #140 rocky and terran planets (blocked).
5. #92 debrief screen.
6. #100 terrain fx 2 (needs #60 decided; see Holds).
7. Progression #24, #26, #27, #29, #30.
8. Nemesis #120, #121 (uses contrib/muse/design/nemesis_writing_2026_11/text_table.md, R101), #122.
9. #169 breakable Pyre-Barge: only after Ryan picks a round 5 hull (R98, R99).
10. Later, not yet scheduled: #41, #42, #44.

## Holds

- PR from #163 (round 5): hold for Ryan's pick; send the V1/V2 comparison sheet and colour-balance numbers, check both against the R96 ceiling (about 306k tris, 3.9 ms at 20 ships).
- PR from #183 (stations): hold for Ryan's look.
- PR #143 (#60 debris): parked. Unpark only if Ryan asks; then close #143 and drop 60 from queued.txt.

## Waiting on Ryan

- Nothing right now.

## Muse

- Open: none. Muse owner-ruling issues for Opus (label opus) are recorded in FINDINGS and closed.

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

- 2026-11-04 21:40 lead chat: loop moved to this file and the hourly scheduled task "Voidsworn board loop" (runs at :37 each hour, first run 22:37 UTC, auto approval, needs Ryan's PC) (R102). #163 running. No send_later checks pending.
