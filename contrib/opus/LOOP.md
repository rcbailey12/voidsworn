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
- Workhorse (#217, R127, R134): LIVE. OpenCode on the PC through tools/pc/work_issue.bat (copy in Downloads\voidsworn_test\work217\tools). DeepSeek V4 Flash for coding jobs, hard ones included (R134: beat V4 Pro and Kimi on #120); the hardest still go to Opus threads while the plan has room (R132). V4 Pro only as a second try on a job Flash fails; Kimi off. Start a run: drop a one-line queue job in Downloads\voidsworn_test\queue\ that `start`s a WORKHORSE_*.bat (see Known traps); two runs can share the PC. Every task now carries the R129 self-check list (PR #253).
- Muse: runs on its own watcher (muse label). Council seats: Rey, DeepSeek, Qwen, Flash (ideation only), Grok (new free leg, Nov 7). ChatGPT down until about Nov 10; Argon blocked since Nov 5. For an independent checker leg on an Opus merge while ChatGPT is down, ask Ryan in the main chat and Rey runs it.

## How a run works

1. Read HANDOFF.md section 0 and this file. Set the lock and push it first.
2. Board check: open PRs, open issues and labels (gh api REST, never GraphQL). PC queue folders only when a PC job is running.
3. Review each new PR yourself, by diff, never by title, then sweep its impact (R129): every caller of each changed function, save and old-profile behaviour, the JS and Godot twins, every UI path that shows it, which tests actually ran in CI. Check claims against the done-when, look at the shots. Merge if good; hold what Holds lists; file a follow-up for anything the sweep finds.
4. Release the next job only to a live seat, one at a time. Before releasing, check it is not already queued or running.
5. Anything for Ryan goes under "Waiting on Ryan" with a pick and plain trade-offs. In an unattended run use one PushNotification, never AskUserQuestion.
6. Tell Ryan only when something lands or needs him: two lines and one image.
7. Rewrite this file, set "Running: no", commit straight to main (this file and FINDINGS only, docs-only exception), push with timeout 90. Stop.
8. One send_later check only when a job or a limit reset lands well before the next look. Never chain them.

## Current state (2026-11-09 17:40 UTC)

- Tree effects (#305): job 1 Glasswrights MERGED (PR #313), job 2 Sunward Crusade MERGED (PR #317, 25 skills, hooks H4 H6 H12 H13 H16; 46 fixtures fire, 26 rows inert). Job 3 Eclipse #318 and job 4 the Chorus #319 queued on DeepSeek 16:52 UTC (they touch the same files: merge one, then merge main into the other). Jobs 5 Hullbreakers and 6 Hegemony after those. Muse text pass #311 not started.
- UI #271: Ryan (R148) agrees with the two fixes and says it "still feels very similar": the identity (font, palette, panels) is the old UI's. Cloud thread trig_01PeNYUnfk7jt3z12Wvekx72 (16:50 UTC) on branch opus/issue-271-build: the fix pass plus three distinct identity variants as mockups (docs/shots/ui_redesign/identity/). Then PC captures rerun, Ryan picks a variant, Rey checks, merge.
- Gun smoke #281: run 4 (Flash, PR #309) removed the ball but keeps straight line sparks (R146): fallback only. Run 5 (Pro) died in 3 seconds at 15:21 UTC: the runner mapped deepseekpro to deepseek/deepseek-pro, not a model id (fix: PR #320, deepseek-v4-pro). Relaunched 17:37 UTC with WORK_MODEL=deepseek/deepseek-v4-pro (baked flipbooks, branch work/issue-281-deepseekpro).
- Ships #209: round 4 in draft PR #316 (82.5 percent outline). Round 5 PC thread since 15:52 UTC (hull traced from B0, 90 percent gate, hand-rebuilt casemates, R147).
- Muse: still idle after Ryan's 07:51 CST bump (#311, #296, #256 with the #314 check request).

## Earlier state (2026-11-09 06:50 UTC)

- Nov 9 early: #24 MERGED (PR #298). #27 (DeepSeek, PR #302) reviewed by diff plus R129 sweep: sound (one run_xp event per finished run, both twins, play log capped at 600, old saves report "no run_xp events", no Nemesis counter of its own). Board stripped a stray CR in run_all_checks.js; first parity failure was a Godot download flake (corrupt zip), rerun. Merge when parity is green, then #29. #271 round 2 mockups in draft PR #301 (A Solid Slab, B Glass Cards, C Glass Shell; board pick C bold), contact sheet sent to Ryan, waiting on his pick. #209 round 3 still on the PC (opus209_r3c job 06:22 UTC). Muse: #296 and #256's check of #286 no comment yet. #281 waits for the GPU. The PC Linux shell is down (virtualization off): read the PC with device_list_dir and staging only.

## Earlier state (2026-11-09 04:05 UTC)

- Nov 8 late: Nemesis redesign DONE (#120 to #122 merged; #282 follow-ups merged as PR #294). #283 CI now runs campaign parity and the Nemesis scenarios. Ships: #209 round 1 (PR #287) and round 2 (PR #295) judged by Ryan (R140 structure first); round 3 (Ab3 plus the hybrid with AI hero parts) running on the PC since 03:50 UTC; #287, #295 and round 3 merge together as the record when the route is ruled. UI: R141 one consistent modern UI (Glass Bridge bold plus Chart Room, action-first); #271 round 1 mockups (PR #291) judged (2B best so far, R142); Muse #292 researches best tactics, strategy and roguelike UIs before round 2. Running: DeepSeek on #24 (Nemesis teaching loop); Muse #292, #296 (Crusade voice), #256 check of #286. Waiting for the GPU: #281 (vent puff options). Ryan: no playtest build until the new UI and first new hulls land.

- Nov 8 evening: #120, #121 (PR #274) and #231 (PR #269) MERGED after Muse's outside checks (board fixed the cheap conditions; rest in #282). #232 merged (PR #275). #122 PR #280: PC checks all PASS on 30fc86d9 (board merged main into it), waiting on Muse #256 (also queued: #283, the #264 CI change). Threads: #209 round 1 on the PC (since 23:36 UTC); #230 plus #264 in the cloud (since 01:10 UTC; #283 is its first PR). Muse: #256 (checks), #270 (UI concepts, R137). Blocked behind GPU or merges: #281 (vent puff options, after #209), #282 (after #280), #271 (after #270 and Ryan's pick), #276 (after #209). The cloud sandbox has Godot 4.7.2 headless, so cloud threads can run parity themselves; the board still runs captures on the PC.

- Nov 8 afternoon: #120 MERGED (PR #248) after Muse's outside check (PR #261, GO, ten notes: keep RUN.nem as a maintained alias; campaign parity and Nemesis scenarios are not in CI, filed #264). #246 merged (PR #254). Muse #257 merged (entry-doc audit, COUNCIL.md; Ryan ruled NR1 to NR5 all A) and applied by Flash in #265 (PR #266 merged: CLAUDE.md now a pointer that imports AGENTS.md; HANDOFF history in docs/archive). Muse #258 merged (Foley licence and plan: XL with offload, US-only outputs; the GPU probe #211 is next when a GPU seat is free). Opus threads running: #231 (since 19:45 UTC), #121 (since 20:24 UTC, from the #120 branch; #120 has merged since, its PR must merge main). #256 waits blocked for their PRs.

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
1. #217 done (R127). Dry run passed 08:48 CST (Node 22 parity PASS; push, chained push and delete refused). #120 head-to-head RUNNING since 08:49 CST (WORKHORSE_H2H_120.bat, summary work217\h2h_120_summary.txt), DeepSeek arm then Kimi arm, WORK_CAP 5400, judged on the #201 check pack. Then the coding queue goes to DeepSeek one job at a time (Kimi too if it wins #120). Small follow-up for the next progression job: take Kimi's loss back-fill from the run log (#242) so an existing profile with losses opens Heat.
2. #221 scene gate binder (PC thread, after the trial frees the PC; not urgent at 6.0 of 12.5 ms).
3. #228 movement spec DONE (PR #251, R131). Next: #230 environment reconciliation (before #100), #231 UI spec. Records now in (R130). (#229 done Nov 8: gravity well parity holds, no fix.)
4. #216 first pass: rest of AGENTS.md, demote NEXT.md, confirm the council memory file placement for Rey (record Grok in the seat map).
5. Record #43's unblock condition. (#48 moved to Muse, R128.) (#96, #98, #206, #214 closed Nov 8.)
Done Nov 8: #201 edits applied to #120 to #122 (R120); settlements triaged (R121 to R125: #208 closed with PR #226 merged; #210, #212, #213, #215 closed with board homes; jobs #227 to #238 filed).

Muse: #227 DONE (PR #247 merged, R130: five audit records plus the stack review). #48 DONE (PR #249 merged: species design text; Rey's concept images failed consistency, visual work handed to Opus as #250). Next for Muse: Glasswright species design (moved to Muse, R128).

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

- UI redesign (R137): pick one of Muse's three warship-console directions when #270 lands; then #271's battle screen review round.

- #48 Glasswright design (contrib/muse/design/glasswright_species_2026_11/design.md): his read of the design text; Brin's pronoun (one word); close faction package question 2 on the design's youth-to-old gradient (yes or no).
- Nothing right now.
- #221: OK to start a PC thread for the per-ship CPU trim (not urgent; the scene sits at 6.0 ms of the 12.5 ms gate).
- S15 sound listen pass: one sitting, best once the #211 probe clips exist.
- Round 7 pick and station look: when #198 and #199 land.

## Projects pilot (R114) and spin-offs (R133)

R133: the board spins off threads itself. Route 1: the Project's main chat starts its own threads, but Ryan's account still has the older session-list Projects (checked Nov 8 12:37 from his screenshots), so not yet. Route 2 (in use, from the Board chat): one-shot scheduled tasks, cloud-only since R135 (PC-bound ones stalled on a silent first-run approval), one per job, each with a full standalone brief (job, branch, checks, who reviews). Live: #231 UI spec thread (fires 13:45 CST Nov 8, auto approval, push to Ryan). Next: #121 after #120 merges. Keep 2 or 3 live at once.


#207 runs as one Claude Code Project thread on the PC. Judge it on: did it run Godot on the 5080 without stalling on approvals, did it report numbers into the repo, how much plan usage it took, and could Ryan follow it from his phone. If yes, the lead conversation moves into the project and Opus asks Ryan before deleting the old hourly task. If no, the board stays in a lead chat and #207 runs through the PC queue. Limits checked Nov 7 (code.claude.com/docs/en/claude-projects): threads use Anthropic models only (the workhorse stays on the board), every thread draws the plan (default Opus high), cloud threads skip the repo's .claude skills and settings, a PC thread needs the desktop app's Remote Control setting and the PC awake.

Result (Opus, Nov 7 night): PASS on three of four. (1) Godot ran on the 5080 through the watcher queue with no approval stalls after the one folder grant; the device shell itself does not start on this PC (hardware virtualization off in the BIOS), so the thread drives the PC by staging files and queue jobs, which is enough. (2) Numbers went into the repo (bench207 report, raw JSON, FINDINGS R115). (3) Plan usage was not measured; it was one long thread with several waits on the PC. (4) Ryan followed and steered it from chat (paused it for gaming with a go-file wait, resumed it). Lessons: the A4 ship files exist only in build\godot\assets\ships on the PC, so a fresh clone must copy them before its first import (the #207 job does); a queued job can wait on a go file to keep the GPU free for Ryan.

## Muse

- Nov 8 13:40: #257 (stale-claim audit of the entry docs plus contrib/muse/COUNCIL.md, from #216 asks 1 and 4) and #258 (#211 HunyuanVideo-Foley licence and run plan) released to Muse. #256 is the standing outside check on Opus-coded PRs (R132): it stays blocked until an Opus PR is ready; then comment the PR number on #256 and remove blocked.

- No open Muse PRs. #200 to #202 are merged and closed.

## Known traps

- CRLF clone trap on the PC (found by the #121 thread, Nov 8): a plain git clone there checks files out with CRLF (core.autocrlf), and then the campaign table export cannot read FNAMES from oracle\ui3d.js, so campaign parity and b1_tests fail for no reason. Always clone with git -c core.autocrlf=false clone.
- Standing issue #256 (Muse outside check) gets closed by any PR that says 'Closes #256'; reopen it and ask for 'Refs #256'.

- Starting a PC job without clicks (Nov 8): drop a .bat into Downloads\voidsworn_test\queue\ with device_commit_files; watcher_q.bat runs it from build\ within seconds and logs to queue\logs\. For a long run the queue job should only `start` the real .bat in its own window, so the queue stays free (q_flash246.bat is the example). Computer control on Explorer misfired again Nov 8 (dark masked screen), so prefer the queue.

- Never list queue\logs, queue_b\logs, queue\done or big shots folders recursively; they are huge. Stage the one file you need.
- Computer use (R126): File Explorer at click tier; double-click a .bat in Downloads\voidsworn_test, then computer_release_lock straight away (it hides Ryan's other windows while held). Never while he is gaming. Take a screenshot before EVERY click (never chain clicks blind; a vanished window put a double-click on the desktop). Access lapses after 30 idle minutes (re-request). Explorer opens on the 27GL850 monitor.
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

- 2026-11-09 04:05 UTC board thread: merged #280 (#122), #283 (#264 CI), #285 and #288 (Muse), #294 (#282). Ryan judged #209 rounds 1 and 2 and the UI concepts and mockups (R140 to R142). Started #209 rounds 2 and 3, #271 mockups, #24 on DeepSeek; filed #292, #296.
- 2026-11-09 01:45 UTC board thread: merged #274 (#121) and #269 (#231) after Muse checks plus board fixes (Godot modal pronouns, 0.35 hull-low line); PC parity re-run PASS; merged main into #280 (#122) and ran its PC checks (all PASS, panel shots fine); Muse #279 merged (it closed #256 again; reopened). Filed #281 (vent puff options), #282 (Nemesis and UI follow-ups). Started the #230/#264 cloud thread.
- 2026-11-08 23:55 UTC board thread: #232 merged (PR #275, DeepSeek Flash, first GPU job for the workhorse: 81 min, $0.20; pale square fixed, caps at the measured 4x step, flash test passes; timing sheets wait for Ryan's review round). #121 PR #274 and #231 PR #269 wait on Muse #256 (reopened). Threads running: #122 (cloud, R135), #209 round 1 (PC; it started without a Needs input stop). Filed #276 (ship design redo, R138), #270 and #271 (UI redesign, R137).
- 2026-11-08 21:55 UTC board thread: merged #261 (Muse check of #248, GO), #248 (#120 done), #262 (#257 audit), #263 (#258 Foley research), #266 (#265 docs cleanup by Flash, board added the @AGENTS.md import). Filed #264 and #265. Times: the current_time tool runs about 20 minutes behind; use date -u.
- 2026-11-08 20:05 UTC board thread: #120 V4 Pro arm in (PR #255, $1.49, 81 min, same UI-reader gap plus RUN.nem never set for new runs): closed; Flash wins (R134). #254 (#246 Heat back-fill, Flash, 20 min) merged. #256 unblocked for #248. Muse got #257 and #258. PC jobs now start through the queue folder instead of clicks.
- 2026-11-08 18:07 UTC board thread: Ryan added $10 on DeepSeek. V4 Pro arm on #120 started 12:05 CST through computer use (model id deepseek/deepseek-v4-pro; deepseek/deepseek-pro is not in OpenCode 1.19.5's catalog). An earlier attempt misfired: two chained double-clicks without a screenshot between them opened Ryan's FilterFactory desktop folder (no program ran). Rule: one screenshot before every click. Ryan away until mid-afternoon; Opus-codes-hard-jobs plan confirmed (R132).
- 2026-11-08 17:05 UTC board thread: #120 Kimi arm ended at 84 min on a Moonshot low-credit 429 ($8.68 real charge, balance $1.62), no report, push refused (it edited checks.yml; the token has no workflow scope); about 100 Godot .uid files in its diff. Its UI and CI catches match the board's sweep of #248; the board pushed both fixes onto work/issue-120-deepseek (b45b973). #248 held until the V4 Pro arm runs (it must start from a main without #120). Pro arm waits on a DeepSeek top-up.
- 2026-11-08 16:10 UTC board thread: #249 (Muse, #48 species design) merged after replacing em dashes in four raw legs; #250 filed (consistent concept sheet, Opus, scope questions first). #120 Kimi arm 38 min in, 29 model calls, about $2 so far.
- 2026-11-08 15:50 UTC board thread: #120 Flash arm landed (PR #248, held; R130 findings), Kimi arm running since 09:24 CST. #247 (audit records and stack review) merged. Checks every 25 min while runs are active.
- 2026-11-08 15:20 UTC board thread: R129: V4 Pro arm for #120 (PR #245), impact-sweep review standard, #246 filed (Heat back-fill for existing profiles, found by sweeping #241). Seat map #244 merged.
- 2026-11-08 15:00 UTC board thread: seat map (R128, PR #244, part of #216); #48 moved to Muse. Muse has not started #227 yet.
- 2026-11-08 14:50 UTC board thread: PR #243 merged (results note, runner fixes). Free dry run on the PC passed. #120 relabelled opus and the head-to-head started through computer use (DeepSeek then Kimi, 90 min each). Check scheduled 10:25 CST.
- 2026-11-08 14:40 UTC board thread: #217 trial closed out (R127): #241 DeepSeek merged (closes #26), #242 Kimi closed (one-hour cap, $4.95). Results note and runner fixes in PR #243. Guard and runner copied to the PC; free dry run started through computer use. Computer use access lapses after 30 idle minutes and Ryan re-approves; a Razer window can sit in front and block clicks (open File Explorer first).
- 2026-11-08 13:30 UTC board thread: first Kimi rerun (07:18 CST) refused again, 3 requests a minute, because the $5 had not posted (balance still 9.98). Ryan fixed it (balance 15.96); the board started WORKHORSE_KIMI_RERUN.bat itself through computer use at 07:28 CST, first use of R126. Run 20261108_072823 is working.
- 2026-11-08 13:20 UTC board thread: Ryan added $5 on Moonshot and started the Kimi rerun. Computer use set up for the board (File Explorer, click tier, R126): the board double-clicks PC .bat files itself from now on; payments stay Ryan's.
