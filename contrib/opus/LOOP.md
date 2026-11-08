# Board loop state (LOOP.md)

**Board owner (Nov 8 2026, R119): the Board thread in the Claude Code Project "Embers of the Hollow Sun"; Ryan, Nov 8 06:39 CST: "you're the owner now" (merge calls are the Board thread's; worker threads never merge their own PRs).** Earlier: (Nov 7 2026, 19:20 CST, R114) Opus in the project (pilot). The Nov 7 lead chat has handed over and only reads.** If the pilot fails, the board goes back to a lead chat. Any other Claude chat on this repo works one named area or only reads.

**The hourly scheduled task "Voidsworn board loop" is DELETED (Ryan, Nov 7 22:06 CST, after the Projects pilot passed, R114).** The board is run from the Claude Code Project. If an unattended loop is ever wanted again, the choice is an event-driven run (fires when a PR opens), not an hourly poll.

## Lock

Running: no
Running since (UTC): 2026-11-08 12:35
Last run finished (UTC): 2026-11-08 12:50

If "Running: no" and the start time is under 90 minutes old, another run is working: stop without changes. If it is older, the last run died: take over and say so in the log.

## Seats right now (Nov 7)

- Opus: board owner, reviewer, merges, visual calls, issue writing, messages to Ryan; builds the opus jobs below. Sonnet subagents for routine checks, logs, staging.
- Codex: DOWN until Ryan says. The PC watcher (codex_board.ps1) still queues any unblocked `codex` issue; those runs die on the usage limit. Keep every codex issue `blocked` until a live seat takes it.
- Workhorse (#217, R127): LIVE. OpenCode on the PC through tools/pc/work_issue.bat (copy in Downloads\voidsworn_test\work217\tools). DeepSeek V4.1 Flash is the primary model ($0.09 and one review pass on #26). Kimi K3.1 Pro on pay-as-you-go (Moonshot paid total $10, Tier 1) pending the #120 head-to-head that decides the subscription. #224 guard and the Node 22 fix copied to the PC Nov 8; free dry run started 08:39 CST. Start a run: write a one-line .bat (set WORK_CAP if needed, call work217\tools\work_issue.bat <issue> <arm>) in Downloads\voidsworn_test and double-click it through computer use (R126).
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

## Current state (2026-11-08 12:50 UTC)

- Board thread (Nov 8 morning, R119): Ryan set it up as the board owner in the project; worker threads never merge their own PRs. #223 reviewed by diff and MERGED (4b6c365), #220 closed. #222 reviewed after the fact: sound, one gap (the agent could push through a chained or `git -c` command and could delete anywhere on the PC); fix PR #224 merged on Ryan's word ("you're the owner now").

- #220 DONE (project thread, Nov 7 night; merged Nov 8): R118. The stalls were the death pieces' meshes built on the main thread when a cut finished (20 to 85 ms), the damage shader source remade per surface (5 to 11 ms) and the first torpedo's shader compiles (53 to 59 ms). After: frame p99 9.3 to 10.9 ms in all 12 base and deaths sessions, 0 of 8,640 frames over 16.7 ms; median 6.0 ms at 1080p, 4K GPU 5.45 ms (gate 12.5). Stills before and after match within run-to-run noise. Report docs/shots/ship_pipeline/bench207/stalls/README.md. PC output Downloads\voidsworn_test\opus220\out. Flag for #210: a pale square effect sprite in battle (on main too).

- #217 runner DONE (project thread, Nov 7 night): PR #222 merged, R117. Dry run on the PC passed both arms. Ryan's files: Downloads\voidsworn_test\WORKHORSE_SETUP.bat and WORKHORSE_TRIAL.bat (scripts in work217\tools). #26 relabelled opus as the trial job. When the trial lands: review both PRs by diff (one pass each), merge the better, close the other, write the results note in contrib/opus/ with the measurement set and the decision rules from #217.

- #207 DONE (Projects pilot thread, Nov 7 evening): PR #219 merged, report docs/shots/ship_pipeline/bench207/README.md, FINDINGS R115 (measurement) and R116 (gate). Gate scene at 1080p: frame median 6.9 ms (42%), GPU 2.4 ms (14%); 4K GPU 5.4 ms. **The gate (R116): 12.5 ms on the frame median at 1080p and on GPU ms with the 3D at 4K.** Binder: CPU, the game's own per-frame work per ship on screen and for effects (fixable in Godot; no engine probe). Flag: frame p99 14 to 53 ms from effects spawns.
- Merged Nov 7: #204, #203, #205 (reviewed by diff, retitled). FINDINGS R110 to R115.
- #198 and #199 re-specced against R111, R113 and R116 (Nov 7 night): costs reported, no triangle caps; Opus reruns the gate scene before any swap ships. Still blocked until a coding seat is live.
- Filed Nov 7 night: #220 (effects spawn stalls) and #221 (per-ship per-frame CPU trim), both opus.
- PC: Downloads\voidsworn_test attached to the project thread. The device shell does not start on this PC (hardware virtualization off), so PC work goes through file staging and the watcher queue. Opus's own clone: Downloads\voidsworn_test\opus207\repo. A stale a4_rbs2_acd9ef1.bat sits in queue\running since Nov 1 (its watcher died mid-job); harmless, leave it.
- Latest playtest exe: g2_pt_d03ac22. The next build folds in #185, #190, #143, #197 (checklist in contrib/muse/reviews/playtest_checklist_2026_11/).

## Queue (Opus's order, Nov 8 morning)

Ryan, Nov 8 06:50 CST: the board thread is the orchestrator; be proactive and keep pushing everything forward.

Opus jobs, in order:
1. #217 done (R127). Next: the dry run must refuse the chained push and the delete; then the #120 head-to-head, DeepSeek arm then Kimi arm, WORK_CAP 5400, judged on the #201 check pack. Then the coding queue goes to DeepSeek one job at a time (Kimi too if it wins #120). Small follow-up for the next progression job: take Kimi's loss back-fill from the run log (#242) so an existing profile with losses opens Heat.
2. #221 scene gate binder (PC thread, after the trial frees the PC; not urgent at 6.0 of 12.5 ms).
3. #228 movement spec, #230 environment reconciliation (before #100), #231 UI spec. All need #227's audit records. (#229 done Nov 8: gravity well parity holds, no fix.)
4. #216 first pass: rest of AGENTS.md, demote NEXT.md, confirm the council memory file placement for Rey (record Grok in the seat map).
5. #48 Glasswright species design; record #43's unblock condition. (#96, #98, #206, #214 closed Nov 8.)
Done Nov 8: #201 edits applied to #120 to #122 (R120); settlements triaged (R121 to R125: #208 closed with PR #226 merged; #210, #212, #213, #215 closed with board homes; jobs #227 to #238 filed).

Muse: #227 files the five Nov 6 audit records (item definitions every settlement job needs).

Coding seat queue (released one at a time to the workhorse once #217 picks a winner; Opus takes one itself only if the workhorse fails and Ryan wants speed):
1. #120, #121, #122 Nemesis redesign (with the #201 check pack).
2. #24, #26 (unless the trial arm merged it), #27, #29, #30 progression steps.
3. #232 effects stress pack (salvo flash safety test first).
4. #236 environment sheets, then #235 camera and UI calibration (one Ryan sitting), both before the terrain jobs.
5. #198 Pyre-Barge round 7 and #199 station detail, #139 nebulas, #140 planets, #100 terrain fx 2 (after #230).
6. #233 destruction captures, #237 campaign captures, #92 debrief screen (after #24, #122 and #231's debrief spec).
7. #169 breakable Pyre-Barge (after Ryan's round 7 pick).
8. Filler when a seat idles: #234 probe and ram Monte Carlo, #238 reporting scripts.
9. Later: #41, #42, #44.

## Holds

- #198 and #199: re-specced (R116), blocked until a coding seat is live. When they land: hold #198 for Ryan's round 7 pick (comparison sheet, blurred greyscale check, cost numbers), hold #199 for Ryan's look.
- #193: local first (its free local probe leg plus #209's free local route), after #207. Tripo only if those leave the question open; Opus runs that evaluation (paid exception granted for it only, R110).
- #194: behind #209.

## Waiting on Ryan

- Nothing right now.
- #221: OK to start a PC thread for the per-ship CPU trim (not urgent; the scene sits at 6.0 ms of the 12.5 ms gate).
- S15 sound listen pass: one sitting, best once the #211 probe clips exist.
- Round 7 pick and station look: when #198 and #199 land.

## Projects pilot (R114)

#207 runs as one Claude Code Project thread on the PC. Judge it on: did it run Godot on the 5080 without stalling on approvals, did it report numbers into the repo, how much plan usage it took, and could Ryan follow it from his phone. If yes, the lead conversation moves into the project and Opus asks Ryan before deleting the old hourly task. If no, the board stays in a lead chat and #207 runs through the PC queue. Limits checked Nov 7 (code.claude.com/docs/en/claude-projects): threads use Anthropic models only (the workhorse stays on the board), every thread draws the plan (default Opus high), cloud threads skip the repo's .claude skills and settings, a PC thread needs the desktop app's Remote Control setting and the PC awake.

Result (Opus, Nov 7 night): PASS on three of four. (1) Godot ran on the 5080 through the watcher queue with no approval stalls after the one folder grant; the device shell itself does not start on this PC (hardware virtualization off in the BIOS), so the thread drives the PC by staging files and queue jobs, which is enough. (2) Numbers went into the repo (bench207 report, raw JSON, FINDINGS R115). (3) Plan usage was not measured; it was one long thread with several waits on the PC. (4) Ryan followed and steered it from chat (paused it for gaming with a go-file wait, resumed it). Lessons: the A4 ship files exist only in build\godot\assets\ships on the PC, so a fresh clone must copy them before its first import (the #207 job does); a queued job can wait on a go file to keep the GPU free for Ryan.

## Muse

- No open Muse PRs. #200 to #202 are merged and closed.

## Known traps

- Never list queue\logs, queue_b\logs, queue\done or big shots folders recursively; they are huge. Stage the one file you need.
- Computer use (R126): File Explorer at click tier; double-click a .bat in Downloads\voidsworn_test, then computer_release_lock straight away (it hides Ryan's other windows while held). Never while he is gaming.
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

- 2026-11-08 14:40 UTC board thread: #217 trial closed out (R127): #241 DeepSeek merged (closes #26), #242 Kimi closed (one-hour cap, $4.95). Results note and runner fixes in PR #243. Guard and runner copied to the PC; free dry run started through computer use. Computer use access lapses after 30 idle minutes and Ryan re-approves; a Razer window can sit in front and block clicks (open File Explorer first).
- 2026-11-08 13:30 UTC board thread: first Kimi rerun (07:18 CST) refused again, 3 requests a minute, because the $5 had not posted (balance still 9.98). Ryan fixed it (balance 15.96); the board started WORKHORSE_KIMI_RERUN.bat itself through computer use at 07:28 CST, first use of R126. Run 20261108_072823 is working.
- 2026-11-08 13:20 UTC board thread: Ryan added $5 on Moonshot and started the Kimi rerun. Computer use set up for the board (File Explorer, click tier, R126): the board double-clicks PC .bat files itself from now on; payments stay Ryan's.
- 2026-11-08 13:30 UTC board thread: #217 Kimi arm stopped 11 s in, no changes: Moonshot 429 "max organization concurrency: 1" (starter tier, msh-gid free; OpenCode sends parallel requests) and opencode exited. Not a model result. Fallback as planned (R117): Ryan adds $5 on Moonshot (paid total $10, next tier), then double-clicks Downloads\voidsworn_test\WORKHORSE_KIMI_RERUN.bat (Kimi arm only, same runner and #222 config as the DeepSeek arm). #241 held until then.
- 2026-11-08 13:20 UTC board thread: #217 DeepSeek arm done (36.7 min, 116 model calls, real charge $0.09, opencode exit 0), PR #241 reviewed by diff: Heat gate moves to the first real loss (abandoned runs do not count, older winners keep it), R63 payout +2 XP per point to the flown line and +1 to the shadow pool with cap overflow, browser and Godot together, oracle identical, new heat_tests.js and Godot test, two 4K shots; a first-review pass candidate, held until the Kimi arm lands. Merged #239 (harness note, closes #206 and #214) and #240 (#229 reads; merged a minute before its parity check finished, which then passed; docs only). Closed #96 (superseded by R83, R86, R96) and #98 (R82).
- 2026-11-08 12:56 UTC board thread: Ryan asked for a proactive orchestrator. Folder access to voidsworn_test granted (the Godot user folder was refused by the auto classifier; device shell still off). DeepSeek arm checked live: about 90 commands and 6 cents in at 06:46 CST. #201 applied (R120). Settlements triaged (R121 to R125), jobs #227 to #238 filed, five audit issues closed; PRs #225 (G6) and #226 (#208 close-out) merged after green checks.
- 2026-11-08 12:50 UTC board thread: Ryan said merge and "you're the owner now"; #224 merged after green checks.
- 2026-11-08 12:50 UTC board thread: #223 reviewed by diff (traces recounted, stills checked) and merged, #220 closed. #222 reviewed after the fact: guard gap found, PR #224 opened and held; the live trial keeps #222's config (no change mid-run). R119. No trial branches yet.
- 2026-11-08 06:35 CST #217 thread: Ryan topped up (DeepSeek $2; Moonshot $5 paid plus the $5 voucher, so still Tier0 by the docs, his call to try it before adding $5) and ran WORKHORSE_SETUP.bat: OpenCode, both keys, both balance endpoints, both models READY through OpenCode, all PASS. WORKHORSE_TRIAL.bat started 06:30, DeepSeek arm first. If the Kimi arm stalls on 429s (Tier0: 3 requests a minute, 1.5M tokens a day), Ryan adds $5 and only the Kimi arm reruns (work_issue.bat 26 kimi). Ryan is moving the board to a single Board thread; the trial PRs and the results note go to it. #222 (the runner) was merged by its own author without a checker leg: the Board thread reviews it after the fact.
- 2026-11-08 05:25 project thread (#220): traced the gate scene per frame on the 5080, named the stall (death piece meshes on the main thread), fixed it and two smaller ones, before and after gate runs and stills; PR #223 open, R118.
