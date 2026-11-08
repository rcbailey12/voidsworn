# Board loop state (LOOP.md)

**Board owner (Nov 7 2026, 19:20 CST, R114): Opus in the Claude Code Project "Embers of the Hollow Sun" (pilot). The Nov 7 lead chat has handed over and only reads.** If the pilot fails, the board goes back to a lead chat. Any other Claude chat on this repo works one named area or only reads.

**The hourly scheduled task "Voidsworn board loop" is DELETED (Ryan, Nov 7 22:06 CST, after the Projects pilot passed, R114).** The board is run from the Claude Code Project. If an unattended loop is ever wanted again, the choice is an event-driven run (fires when a PR opens), not an hourly poll.

## Lock

Running: no
Running since (UTC): 2026-11-08 00:05
Last run finished (UTC): 2026-11-08 00:50

If "Running: yes" and the start time is under 90 minutes old, another run is working: stop without changes. If it is older, the last run died: take over and say so in the log.

## Seats right now (Nov 7)

- Opus: board owner, reviewer, merges, visual calls, issue writing, messages to Ryan; builds the opus jobs below. Sonnet subagents for routine checks, logs, staging.
- Codex: DOWN until Ryan says. The PC watcher (codex_board.ps1) still queues any unblocked `codex` issue; those runs die on the usage limit. Keep every codex issue `blocked` until a live seat takes it.
- Workhorse (#217, decided Nov 7): OpenCode on the PC, Kimi primary, DeepSeek second. NOT LIVE: waits on Ryan's setup steps, then the two-arm trial. Branch pattern `work/issue-<n>` or `work/issue-<n>-<arm>` (auto_pr opens the PR).
- Muse: runs on its own watcher (muse label). Council seats: Rey, DeepSeek, Qwen, Flash (ideation only), Grok (new free leg, Nov 7). ChatGPT down until about Nov 10; Argon blocked since Nov 5. For an independent checker leg on an Opus merge while ChatGPT is down, ask Ryan in the main chat and Rey runs it.

## How a run works

1. Read HANDOFF.md section 0 and this file. Set the lock and push it first.
2. Board check: open PRs, open issues and labels (gh api REST, never GraphQL). PC queue folders only when a PC job is running.
3. Review each new PR yourself, by diff, never by title. Check claims against the diff and the done-when, look at the shots. Merge if good; hold what Holds lists.
4. Release the next job only to a live seat, one at a time. Before releasing, check it is not already queued or running.
5. Anything for Ryan goes under "Waiting on Ryan" with a pick and plain trade-offs. In an unattended run use one PushNotification, never AskUserQuestion.
6. Tell Ryan only when something lands or needs him: two lines and one image.
7. Rewrite this file, set "Running: no", commit straight to main (this file and FINDINGS only, docs-only exception), push with timeout 90. Stop.
8. One send_later check only when a job or a limit reset lands well before the next look. Never chain them.

## Current state (2026-11-08 03:50 UTC)

- #207 DONE (Projects pilot thread, Nov 7 evening): PR #219 merged, report docs/shots/ship_pipeline/bench207/README.md, FINDINGS R115 (measurement) and R116 (gate). Gate scene at 1080p: frame median 6.9 ms (42%), GPU 2.4 ms (14%); 4K GPU 5.4 ms. **The gate (R116): 12.5 ms on the frame median at 1080p and on GPU ms with the 3D at 4K.** Binder: CPU, the game's own per-frame work per ship on screen and for effects (fixable in Godot; no engine probe). Flag: frame p99 14 to 53 ms from effects spawns.
- Merged Nov 7: #204, #203, #205 (reviewed by diff, retitled). FINDINGS R110 to R115.
- #198 and #199 re-specced against R111, R113 and R116 (Nov 7 night): costs reported, no triangle caps; Opus reruns the gate scene before any swap ships. Still blocked until a coding seat is live.
- Filed Nov 7 night: #220 (effects spawn stalls) and #221 (per-ship per-frame CPU trim), both opus.
- PC: Downloads\voidsworn_test attached to the project thread. The device shell does not start on this PC (hardware virtualization off), so PC work goes through file staging and the watcher queue. Opus's own clone: Downloads\voidsworn_test\opus207\repo. A stale a4_rbs2_acd9ef1.bat sits in queue\running since Nov 1 (its watcher died mid-job); harmless, leave it.
- Latest playtest exe: g2_pt_d03ac22. The next build folds in #185, #190, #143, #197 (checklist in contrib/muse/reviews/playtest_checklist_2026_11/).

## Queue (Opus's order, Nov 7 night)

Opus jobs, in order (Nov 7 night, after #207):
1. #217 runner: build the OpenCode setup .bat (installs OpenCode, takes each key once, does-it-start test) and the one trial .bat (DeepSeek arm then Kimi arm on #26, pushes work/issue-26-<arm>; backup: a synthetic spec of the same shape). Every coding job waits on a live seat, so this comes first. The trial itself waits on Ryan's top-ups.
2. #220 effects spawn stalls (frame p99 14 to 65 ms in battle; PC thread). Visible stutter, so ahead of the CPU trim.
3. Apply #201 edits G2 to G6 to #120, #121, #122 (G1 withdrawn) before any of them is released.
4. Triage settlements into named jobs with fixed top blocks: #208 (also the only home of the station assert fixes), #210, #212, #213, #215. Writing only; ceiling-dependent builds now follow R116.
5. #221 scene gate binder: profile and trim the per-ship per-frame work (PC thread; not urgent at 42% of the frame).
6. #216 first pass: rest of AGENTS.md, demote NEXT.md, confirm the council memory file placement for Rey (record Grok in the seat map).
7. Close #96 and #98 if FINDINGS already carries them; absorb #206 and #214 into the working docs and close; #48 after settlements move; record #43's unblock condition.

Coding seat queue (released one at a time to the workhorse once #217 picks a winner; Opus takes one itself only if the workhorse fails and Ryan wants speed):
1. #120, #121, #122 Nemesis redesign (with the #201 check pack).
2. #24, #26 (unless the trial arm merged it), #27, #29, #30 progression steps.
3. #92 debrief screen (after #24 and #122).
4. #198 Pyre-Barge round 7 and #199 station detail (re-specced Nov 7 to R116), #139 nebulas, #140 planets, #100 terrain fx 2.
5. #169 breakable Pyre-Barge (after Ryan's round 7 pick).
6. Later: #41, #42, #44.

## Holds


- #198 and #199: re-specced (R116), blocked until a coding seat is live. When they land: hold #198 for Ryan's round 7 pick (comparison sheet, blurred greyscale check, cost numbers), hold #199 for Ryan's look.
- #193: local first (its free local probe leg plus #209's free local route), after #207. Tripo only if those leave the question open; Opus runs that evaluation (paid exception granted for it only, R110).
- #194: behind #209.

## Waiting on Ryan

- #217 money: about $10 on Moonshot and $2 on DeepSeek, no OpenRouter for the trial (R114). Setup itself is one double-click once Opus has built the runner.
- S15 sound listen pass: one sitting, best once the #211 probe clips exist.
- Round 7 pick and station look: when #198 and #199 land.

## Projects pilot (R114)

#207 runs as one Claude Code Project thread on the PC. Judge it on: did it run Godot on the 5080 without stalling on approvals, did it report numbers into the repo, how much plan usage it took, and could Ryan follow it from his phone. If yes, the lead conversation moves into the project and Opus asks Ryan before deleting the old hourly task. If no, the board stays in a lead chat and #207 runs through the PC queue. Limits checked Nov 7 (code.claude.com/docs/en/claude-projects): threads use Anthropic models only (the workhorse stays on the board), every thread draws the plan (default Opus high), cloud threads skip the repo's .claude skills and settings, a PC thread needs the desktop app's Remote Control setting and the PC awake.

Result (Opus, Nov 7 night): PASS on three of four. (1) Godot ran on the 5080 through the watcher queue with no approval stalls after the one folder grant; the device shell itself does not start on this PC (hardware virtualization off in the BIOS), so the thread drives the PC by staging files and queue jobs, which is enough. (2) Numbers went into the repo (bench207 report, raw JSON, FINDINGS R115). (3) Plan usage was not measured; it was one long thread with several waits on the PC. (4) Ryan followed and steered it from chat (paused it for gaming with a go-file wait, resumed it). Lessons: the A4 ship files exist only in build\godot\assets\ships on the PC, so a fresh clone must copy them before its first import (the #207 job does); a queued job can wait on a go file to keep the GPU free for Ryan.

## Muse

- No open Muse PRs. #200 to #202 are merged and closed.

## Known traps

- Never list queue\logs, queue_b\logs, queue\done or big shots folders recursively; they are huge. Stage the one file you need.
- PC access is device_list_dir, device_stage_files and device_commit_files inside the attached folders (Downloads\voidsworn_test, the Godot app_userdata\Voidsworn folder). Never delete anything on the PC; ask Ryan.
- Duplicate runs: the board (codex_board.ps1, every 10 minutes) queues any unblocked open codex issue that is not in board\queued.txt and has no open PR from codex/issue-N. If you also write a job file, it runs twice. Keep finished issues in queued.txt.
- A duplicate run of an already merged job force-pushes the branch and auto_pr opens a new PR: close it with a note, do not merge.
- Usage limit: result.txt says "usage limit hit, left on the board to retry"; grep log.txt for "try again at" (Central time). Do not requeue by hand.
- Codex has a one-hour cap per run (tmo 3600). Heavy GPU bake-offs can need two runs: back up the branch (git push origin origin/codex/issue-N:refs/heads/opus/issue-N-run1), add a resume note to the issue body, close the PR, drop N from queued.txt.
- GitHub's PR list can lag a few minutes after a close, and the board then re-adds the number to queued.txt. Check on the next run.
- Never put |, &, < or > in job arguments. Job .bat files are CRLF.
- A4 ship files (glb and maps) live only in build\godot\assets\ships\<code>\ on the PC, out of git by design. A fresh clone builds textureless or old hulls unless they are copied in before its Godot import (tools/pc/jobs/bench207_scene_gate.bat shows the copy, import and rebuild order).
- Ryan may want the GPU while a job is queued: write the job to wait for a go file (opus207\go.txt in the #207 job) and commit the file when he says go.
- git push from the sandbox can hang: wrap in timeout 90 and retry once.
- gh GraphQL is blocked: use gh api REST (pulls, issues, merges). Branch deletion and repo settings are refused by the proxy.
- auto_pr (Nov 7): PR titles come from the issue title, with "[arm arm]" added for work/issue-N-arm branches. Branches outside codex/, muse/ and work/issue-* do not auto-open a PR; open it with gh api.
- Questions for Ryan go in chat or this file, never as GitHub tags. Plain words, no em dashes, no human-hour estimates (R99).

## Playtest exe recipe (lane A)

Check ship files are unchanged first (git diff --stat <last build hash> origin/main -- godot/assets/ships). Zips from origin/main with git archive: src1 = godot portraits; src2 = godot audio world; src3 = godot campaign fx main render rules scenes story ui; tools = tools/pc (prefix kept). Copy manifest and mcheck from the last build (build\g2_pt_<hash>_*). Copy the last bat (queue\done\g2_pt_<hash>.bat), replace the hash, rewrite line 2, CRLF. Zips to Downloads\voidsworn_test\build\, bat to Downloads\voidsworn_test\queue\. Results in shots\g2_pt_<hash>\result.txt (expect MANIFEST OK, export exit 0, title and battle exits 0). About 20 minutes.

## Log (newest first, keep about 10)

- 2026-11-08 04:15 project thread: #198 and #199 re-specced against R111, R113, R116; filed #220 (effects stalls) and #221 (per-ship CPU trim); Opus queue reordered (#217 runner first).
- 2026-11-08 04:08 project thread: Ryan OK'd deleting the old hourly board task; deleted. The board runs from the project (R114).
- 2026-11-08 04:05 project thread: Ryan set the gate, 12.5 ms (75%) on frame at 1080p and GPU at 4K (R116). PR #219 merged; #207 closed.
- 2026-11-08 03:50 project thread (#207): fresh clone on the PC, A4 files copied (252 of 252 match), mixed-fleet gate scene built and measured on the 5080 (5 launches: turn view, gate view twice, 1440p and 4K). Result R115; PR #219 opened, held for Ryan's share pick. Ryan paused the GPU work for gaming 20:15 to 20:49 CST.
- 2026-11-08 01:25 lead chat: Ryan created the project and started the #207 thread; Remote Control on for Downloads\voidsworn_test, keep-awake on. Board ownership handed to the project.
- 2026-11-08 00:50 lead chat: Ryan answered: Projects pilot on #207, both triangle caps dropped (R113), one double-click trial, cheaper spend (R114). #217 spec fixes posted on the issue.
- 2026-11-08 00:40 lead chat (Opus back from the weekly cap): audit conditions 1 to 3 done. Merged #204, #203, #205 by diff, retitled. Blocked #198 and #199. FINDINGS R110 to R112. auto_pr title fix, AGENTS.md opening fix. Hourly task left off. Next: #207, then the #217 runner.
- 2026-11-07 13:30 Rey (lead chat while Opus was capped): repo state audit delivered on muse/repo-state-2026-11; Ryan ruled board to Opus, #193 local first, queue order to Opus. #217 filed (workhorse trial). #216 filed Nov 7 morning.
- 2026-11-06 Rey: Nov 6 audit stack filed and ruled by Ryan as #206 to #215. #200 synthesis corrected twice on PR #203; #201 rulings pushed to PR #204.
- 2026-11-05 22:30 lead chat: handoff written. Codex out of usage; Opus takes the board after the Claude weekly reset. Muse PRs #203 to #205 open.
