# Board loop state (LOOP.md)

**This loop is the only owner of the job board** (Ryan, Nov 4 2026, FINDINGS R102). Only the hourly scheduled task "Voidsworn board loop" (and a one-off send_later check it schedules) queues jobs, merges PRs and releases blocked issues. Any other Claude chat on this repo works one named area or only reads.

## Lock

Running: yes
Running since (UTC): 2026-11-05 01:38
Last run finished (UTC): 2026-11-05 00:22

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

## Current state (2026-11-05 00:22 UTC)

- Codex: #163 finished 22:25Z (exit 0), PR #186 open and HELD for Ryan's pick. #183 unblocked at 00:11Z (blocked label already removed when this run looked); queue_b and running were empty at 00:20Z, so the board should queue it on its next poll. Check next run that it is running and not doubled.
- PR #186 review (Opus): files are round5 tools plus docs/shots only, no shipping asset touched, matches the done-when list. Paint is now soot-dominant and much closer to the reference (largest colour gap 9.35 points). Both hulls still 0/9 clean. V1 307,477 tris, 4.175 ms GPU (over 3.9; the round 4 V1 control also measured 4.23 this session, so part is session drift). V2 289,047 tris, 3.248 ms. Codex picks V1.
- Latest playtest exe: g2_pt_d03ac22 at Downloads\voidsworn_test\build\export\Voidsworn.exe (passed). Not in it yet: #185 deaths 2.
- PC disk: about 100 GB free after Ryan's cleanup (sync_old holds only g2_pt_d03ac22). Skip new playtest builds if free space drops under 60 GB and ask Ryan to clean sync_old.
- PC shell (device_bash) is unavailable on this PC (hypervisor off); use list_dir and stage only. voidsworn_test had to be re-granted this run (granted automatically).

## Queue order (Codex)

1. #163 Pyre-Barge round 5: done; PR #186 merged as tools only (lead chat, R103: paint rejected).
2. #183 station detail pass (released 00:11Z, waiting for the board to queue it). Stop for Ryan's look.
3. #187 Pyre-Barge round 6 (R103: V3 cut to the ceiling and V1, both with simple paint). Blocked; release after #183. HOLD its PR for Ryan.
3. #139 nebulas and ion storms (blocked).
4. #140 rocky and terran planets (blocked).
5. #92 debrief screen.
6. #100 terrain fx 2 (needs #60 decided; see Holds).
7. Progression #24, #26, #27, #29, #30.
8. Nemesis #120, #121 (uses contrib/muse/design/nemesis_writing_2026_11/text_table.md, R101), #122.
9. #169 breakable Pyre-Barge: only after Ryan picks a round 6 hull (R98, R99, R103).
10. Later, not yet scheduled: #41, #42, #44.

## Holds

- PR from #187 (round 6): hold for Ryan's pick; send the comparison sheet, the blurred greyscale readability check and both ceiling numbers. (#186 round 5 merged by the lead chat; Ryan rejected its paint, R103.)
- PR from #183 (stations): hold for Ryan's look.
- PR #143 (#60 debris): parked. Unpark only if Ryan asks; then close #143 and drop 60 from queued.txt.

## Waiting on Ryan

- Pyre-Barge round 5 pick (asked 2026-11-05 00:22, sheet: docs/shots/ship_pipeline/pyre_round5/comparison.webp on PR #186). Recommended: V1 goes on to the repair and breakable pass (#169), with a triangle cut in that pass to get under the 3.9 ms ceiling. V1 has the hand-built engine, guns and bridge; it is about 7% over the GPU budget. V2 is under budget but has floating blocks, fused machinery and a slab bow, so it needs more geometry rebuilding. Other option: keep today's ship and park the barge rebuild. Once he picks: record an R row, merge #186, and write the #169 brief for that hull.

## Muse

- Open: #188 readable ship paint standard (feeds #187 round 6), #189 backlog check of queued Codex jobs (apply its edits to the issues and the queue here after Ryan rules on its questions). Review and merge their PRs; owner questions go under Waiting on Ryan.

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

- 2026-11-05 00:25 lead chat: hourly runs at 22:37 and 23:37 sat pending until Ryan approved the task in the desktop app; he says it now runs. Merged #186 (round 5 tools), filed #187 (R103), released #183.

- 2026-11-05 00:22 loop: #163 done, PR #186 reviewed and held, round 5 pick sent to Ryan; #183 found already unblocked, waiting for the board to queue it.
- 2026-11-04 21:40 lead chat: loop moved to this file and the hourly scheduled task "Voidsworn board loop" (runs at :37 each hour, first run 22:37 UTC, auto approval, needs Ryan's PC) (R102). #163 running. No send_later checks pending.
