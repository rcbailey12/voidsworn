# Board loop state (LOOP.md)

**Board owner (Ryan, Nov 7 2026, FINDINGS R110): Opus, run from one lead chat.** Any other Claude chat on this repo works one named area or only reads.

**The hourly scheduled task "Voidsworn board loop" (trig_01AYQAMdwD6BZHsizYS6EZdE) stays OFF (Opus, Nov 7).** Ryan made restarting it Opus's call. Reasons it stays off for now: almost nothing arrives to poll (Codex is down, the #217 workhorse is not set up yet, Muse PRs come a few a day), and its two failure modes from Nov 4 to 5 (folder access prompts, merges refused in unattended runs) are not fixed. Idle hourly runs would spend Claude usage that the reviewer and builder needs. Restart test: the workhorse is producing PRs. At that point the choice is an event-driven run (fires when a PR opens) or a Claude Code Project as the lead conversation; see "Open decisions" below.

## Lock

Running: no
Running since (UTC): 2026-11-08 00:05
Last run finished (UTC): 2026-11-08 00:40

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

## Current state (2026-11-08 00:40 UTC)

- Merged Nov 7: #204 (#201 Nemesis checks), #203 (#200 surface detail standard), #205 (#202 playtest checklist), all retitled and reviewed by diff. FINDINGS R110 to R112 recorded.
- Fixed Nov 7: auto_pr titles PRs from the issue (the #203 and #204 wrong-title bug); AGENTS.md opening (Babylon and phone lines were stale).
- Blocked Nov 7: #198 and #199 (Codex down, and both done-whens target the retired R96 ceiling; re-spec after #207).
- PC queue folders not checked this session (no PC folders attached to this chat). Unknown whether the watcher queued #198 or #199 before the block; harmless while Codex is down.
- Latest playtest exe: g2_pt_d03ac22. The next build folds in #185, #190, #143, #197 (checklist in contrib/muse/reviews/playtest_checklist_2026_11/).

## Queue (Opus's order, Nov 7)

Opus jobs, in order:
1. #207 benchmark scene on the RTX 5080. It gates the scene-gate share (Ryan sets it after seeing the numbers), the #198 and #199 re-spec, #209, #139, #140 and every ceiling-dependent settlement job. Name the binder (shadow/surface/post vs geometry submission vs CPU submission) and report headroom, not compliance.
2. #217 trial: build the OpenCode runner .bat files once Ryan answers the setup questions; trial job is #26 (Heat un-gate: multi-file, browser plus Godot, parity checks run locally, a visible control to screenshot, cheap to throw away). Backup: a synthetic spec of the same shape.
3. Apply #201 edits G2 to G6 to #120, #121, #122 (G1 withdrawn) before any of them is released.
4. Triage settlements into named jobs with fixed top blocks: #208 (also the only home of the station assert fixes), #210, #212, #213, #215. Writing only; ceiling-dependent builds wait for #207.
5. #216 first pass: rest of AGENTS.md, demote NEXT.md, confirm the council memory file placement for Rey (record Grok in the seat map).
6. Close #96 and #98 if FINDINGS already carries them; absorb #206 and #214 into the working docs and close; #48 after settlements move; record #43's unblock condition.

Coding seat queue (released one at a time to the workhorse once #217 picks a winner; Opus takes one itself only if the workhorse fails and Ryan wants speed):
1. #120, #121, #122 Nemesis redesign (with the #201 check pack).
2. #24, #26 (unless the trial arm merged it), #27, #29, #30 progression steps.
3. #92 debrief screen (after #24 and #122).
4. After #207: #198 Pyre-Barge round 7 and #199 station detail (re-specced), #139 nebulas, #140 planets, #100 terrain fx 2.
5. #169 breakable Pyre-Barge (after Ryan's round 7 pick).
6. Later: #41, #42, #44.

## Holds

- #198 and #199: blocked until re-specced after #207. When they land: hold #198 for Ryan's round 7 pick (comparison sheet, blurred greyscale check, cost numbers), hold #199 for Ryan's look.
- #193: local first (its free local probe leg plus #209's free local route), after #207. Tripo only if those leave the question open; Opus runs that evaluation (paid exception granted for it only, R110).
- #194: behind #209.

## Waiting on Ryan

- #217 setup: OpenCode on the PC, a Moonshot API key and a DeepSeek API key (small prepaid balances), optional OpenRouter key. Opus asked how he wants the setup and run done (Nov 7 chat).
- Station triangle ceiling: #200 D20 (40k to 45k hard ceiling) and D18 (detail share caps) still cap triangles, against R111. Opus pick: make both reported figures and price stations in ms on the scene gate. Asked Nov 7.
- Scene-gate share: after #207's first measurement.
- S15 sound listen pass: one sitting, best once the #211 probe clips exist.
- Round 7 pick and station look: when #198 and #199 land.

## Open decisions (Opus)

- Lead conversation: a Claude Code Project (public beta) could replace both the lead chat and the hourly task. Upside: one conversation that keeps its memory, a phone overview of what is waiting, and threads that run on the PC through Remote Control. Limits checked Nov 7 (code.claude.com/docs/en/claude-projects): threads use Anthropic models only (the workhorse stays on the board), every thread draws the plan (default Opus high), cloud threads skip the repo's .claude skills and settings, a PC thread needs the desktop app's Remote Control setting and the PC awake. The repo stays the record either way. Proposed pilot: #207 as one PC thread, if Ryan's account has Projects.

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
- git push from the sandbox can hang: wrap in timeout 90 and retry once.
- gh GraphQL is blocked: use gh api REST (pulls, issues, merges). Branch deletion and repo settings are refused by the proxy.
- auto_pr (Nov 7): PR titles come from the issue title, with "[arm arm]" added for work/issue-N-arm branches. Branches outside codex/, muse/ and work/issue-* do not auto-open a PR; open it with gh api.
- Questions for Ryan go in chat or this file, never as GitHub tags. Plain words, no em dashes, no human-hour estimates (R99).

## Playtest exe recipe (lane A)

Check ship files are unchanged first (git diff --stat <last build hash> origin/main -- godot/assets/ships). Zips from origin/main with git archive: src1 = godot portraits; src2 = godot audio world; src3 = godot campaign fx main render rules scenes story ui; tools = tools/pc (prefix kept). Copy manifest and mcheck from the last build (build\g2_pt_<hash>_*). Copy the last bat (queue\done\g2_pt_<hash>.bat), replace the hash, rewrite line 2, CRLF. Zips to Downloads\voidsworn_test\build\, bat to Downloads\voidsworn_test\queue\. Results in shots\g2_pt_<hash>\result.txt (expect MANIFEST OK, export exit 0, title and battle exits 0). About 20 minutes.

## Log (newest first, keep about 10)

- 2026-11-08 00:40 lead chat (Opus back from the weekly cap): audit conditions 1 to 3 done. Merged #204, #203, #205 by diff, retitled. Blocked #198 and #199. FINDINGS R110 to R112. auto_pr title fix, AGENTS.md opening fix. Hourly task left off. Next: #207, then the #217 runner.
- 2026-11-07 13:30 Rey (lead chat while Opus was capped): repo state audit delivered on muse/repo-state-2026-11; Ryan ruled board to Opus, #193 local first, queue order to Opus. #217 filed (workhorse trial). #216 filed Nov 7 morning.
- 2026-11-06 Rey: Nov 6 audit stack filed and ruled by Ryan as #206 to #215. #200 synthesis corrected twice on PR #203; #201 rulings pushed to PR #204.
- 2026-11-05 22:30 lead chat: handoff written. Codex out of usage; Opus takes the board after the Claude weekly reset. Muse PRs #203 to #205 open.
- 2026-11-05 14:40 lead chat: Ryan R109, station needs way more detail. Merged #197 as base, filed #199 (codex) and #200 to #202 (muse).
- 2026-11-05 14:32 lead chat: #195 PR #197 reviewed, held for Ryan. Released #198 round 7.
- 2026-11-05 04:50 lead chat: #187 round 6 done (PR #196, merged as tools); Ryan ruled R108, round 7 filed as #198. Released #195 station repaint.
- 2026-11-05 03:50 lead chat: took the board back (hourly task switched off by Ryan until the weekly reset). Merged #190, #191, #192. Recorded R104 to R106.
- 2026-11-05 02:00 lead chat: replaced the hourly task with an identical one (runs at :58) with the two PC folders attached.
- 2026-11-04 21:40 lead chat: loop moved to this file and the hourly scheduled task (R102).
