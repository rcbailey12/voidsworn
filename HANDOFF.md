# Voidsworn (Embers of the Hollow Sun): handoff (updated Nov 7, 2026, 22:05 CST)

## 0. Status at Nov 7, 2026, 22:05 CST (read this first)

**Board:** Opus owns it (R110), now from the Claude Code Project "Embers of the Hollow Sun" (R114 pilot; it passed on the #207 thread, see LOOP.md). The hourly task stays off; why, and the restart test, are at the top of [contrib/opus/LOOP.md](contrib/opus/LOOP.md). LOOP.md holds the seats, queue, holds and what waits on Ryan.

**Seats:** Codex down until Ryan says. ChatGPT down until about Nov 10. The #217 workhorse (OpenCode on the PC, Kimi primary, DeepSeek second) is decided but not set up; its two-arm trial runs first, pay-as-you-go, $30 cap. Grok joined the council as a free leg. Muse runs on its own.

**#207 measured (R115):** the gate scene (20 ships, all six factions, A4 hulls uncapped, storm map, effects, HUD) runs 6.9 ms a frame (42% of 60 fps) on 2.4 ms of GPU at 1080p; 4K GPU 5.4 ms. The binder is CPU: the game's own per-frame work per ship on screen and for effects, fixable inside Godot (no engine probe). Frame p99 spikes of 14 to 53 ms come from effects spawns. Report: docs/shots/ship_pipeline/bench207/README.md. Gate (Ryan, R116): 12.5 ms (75% of the frame) on this scene's frame median at 1080p and its GPU ms with the 3D at 4K; today 6.9 ms and 5.4 ms.

**Done Nov 7:** repo state audit accepted (contrib/muse/reviews/repo_state_2026_11/ on branch muse/repo-state-2026-11); PRs #203 to #205 merged by diff; #198 and #199 blocked (their done-whens target the retired R96 ceiling); R110 to R112 recorded; auto_pr title bug and the stale AGENTS.md opening fixed.

**Rules that changed this week:** R111 retires the R96 triangle ceiling: triangles, draw calls and surfaces are reported, never capped; one measured scene gate in ms on the RTX 5080 is the only binding performance limit, its share set by Ryan after the #207 benchmark. Anything older that says "inside the R96 ceiling" means "report the cost".

**Next:** re-spec #198 and #199 against the gate (R116), the two jobs #207 found (per-ship per-frame CPU work; effects spawn stalls behind the p99 spikes), then the #217 runner and trial (job #26), then the #201 edits to #120 to #122 and the settlement triage. Full order in LOOP.md.

## 0b. Status at Nov 5, 2026, 22:30 CST (superseded by section 0 where they differ)

**Who runs the board now (Ryan, Nov 5):** Claude's weekly usage resets and **Codex is out of ChatGPT weekly usage for a while** (Ryan will say when it is back). Until then **Opus owns the board and does the Codex jobs itself**. The hourly "Voidsworn board loop" scheduled task (trig_01AYQAMdwD6BZHsizYS6EZdE) stays disabled; revisit it once things are steady (R102 setup; it failed on folder access and on "merge without review"). One lead chat owns the board; LOOP.md is its state file.

**How Opus works while Codex is out:**
- Take codex-labelled issues yourself, one at a time, in the LOOP.md queue order. Push `opus/issue-<n>` branches and open PRs; checks run by themselves. Use Sonnet subagents for routine coding, log reading and capture jobs (R102); Opus keeps merge calls, claim checks, visual judgment and messages to Ryan.
- Heavy work (Blender bakes, renders, closeshots, GPU probes, Godot exports) still runs on Ryan's PC through the test runner (HANDOFF "PC test runner", LOOP.md Known traps). The sandbox is for code and small conversions.
- The PC Codex watcher (codex_board.ps1) keeps queueing unblocked codex issues; while usage is out those runs end with "usage limit hit, left on the board to retry". Harmless, but before you start a job yourself, label it `opus` (remove `codex`) so the watcher skips it and no duplicate PR appears when Codex comes back.
- Muse still runs on its own (muse label, its own watcher). Review and merge its PRs.
- Ryan's look first for anything visual: hold those PRs and send him the sheet in two lines.

**Open right now:**
- Muse PRs to review: #203 (#200 close-range surface detail standard), #204 (#201 Nemesis redesign test checks; feeds edits to #120 to #122), #205 (#202 playtest checklist for the next build). Titles on #203 and #204 were copied from a commit; judge the content.
- #198 Pyre-Barge round 7 (R108): released, no PR yet (Codex ran out). V3 gets mounted detail back up to the R96 ceiling plus the reference's outline features; V1 and V3 both get red-brown plate paint (R105). Hold for Ryan's pick; send the comparison sheet, the blurred greyscale check and both ceiling numbers.
- #199 station surface detail (R109): Ryan said the #197 repaint is "super plain, just regular shapes" and wants WAY more detail. #197 is merged as the base paint. Hold for Ryan's look. Use #200's standard once merged.
- Then the LOOP.md queue: #139 nebulas, #140 planets, #120 to #122 Nemesis redesign, #24, #26, #27, #29, #30, #92, #100, #169 (after the round 7 pick), later #41, #42, #44.
- Parked: #193 (Tripo test; paid cloud service, needs Ryan's call; house rule is free and local only) and #194 (five pipeline options).
- Next playtest exe: fold in #185, #190, #143, #197 and whatever lands next; recipe in LOOP.md. Last build g2_pt_d03ac22.

**Rulings this week:** FINDINGS R98 (breakable by design), R99 (no human-hour estimates), R102 to R109. Check FINDINGS before trusting any older doc.

**Ryan's rules that bite:** plain words, lead with the answer, no em dashes, picks not lists, screenshots of results, double-click .bat files, ask 3 to 5 plain questions before anything big unless he says "just build it", never delete anything on his PC, never put |, &, < or > in job arguments, git identity Ryan Bailey <rcbailey12@gmail.com>.

## Older status (Nov 1, 2026, 19:15 CDT)

**Board loop (Ryan, Nov 4 2026, FINDINGS R102):** the job board is run by one hourly scheduled task, "Voidsworn board loop", which starts fresh, reads this section and [contrib/opus/LOOP.md](contrib/opus/LOOP.md), runs one loop, rewrites LOOP.md, pushes and stops. LOOP.md holds the current state, queue order, holds, questions waiting on Ryan, the run lock and the known traps. The loop is the only board owner; any other Claude chat on this repo works one named area or only reads. Opus does merge calls, PR claim checks, visual judgment, planning and messages to Ryan; Sonnet subagents do board checks, log reading, renames and capture jobs. send_later is only for one-off timed checks (for example just after a Codex usage reset). LOOP.md is committed straight to main (docs-only exception).

**How we work now (Ryan, Nov 1 19:11):** Claude's weekly usage is low until about Nov 6, so Claude is the orchestrator and final reviewer only. Coding, tests and read-heavy reports go to **Codex** on Ryan's PC (tools/pc/codex_run.bat; the flow is in contrib/opus/briefs/feel_pass_2026-11-01.md, "Codex worker"; Ryan's ChatGPT plan has plenty of room). Multi-model research, drafting and reviews go to **Muse** (Muse takes muse-labeled issues from the job board, runs its models and opens a pull request into contrib/muse/). Claude writes briefs, reviews patches and shots, runs parity, and signs off. Launch a Claude helper only for visual work that needs repeated PC captures, and keep it lean. Helper transcripts that grow too large cannot be resumed: launch a takeover instead.

**Job board (Ryan, Nov 2, FINDINGS R75):** the open GitHub issues are the to-do list; every issue starts with the fixed job block (AGENTS.md) and a label for who has it (codex, muse, opus, blocked). Agents push `codex/issue-<n>` or `muse/issue-<n>` branches, never main; GitHub opens the PR and runs the checks by itself (.github/workflows). Codex runs itself: `codex_board.bat` on Ryan's PC polls the board every 10 minutes and queues new codex issues on lane B (results in Downloads\voidsworn_test\board\issue-<n>\). Muse runs itself too (its own watcher, standing rule in contrib/opus/briefs/muse_standing_rule.md) and asks Ryan in its chat, never on GitHub. Opus writes issues, reviews PRs and merges; start every session with the open PRs, then the open issues. No Codex cloud (older model).

**Current phase: the feel pass** ([contrib/opus/briefs/feel_pass_2026-11-01.md](contrib/opus/briefs/feel_pass_2026-11-01.md)), from Ryan's first Godot playtests (FINDINGS R64 to R72).

**Done on main:** turn flow and play log (F1), movement twice as slow and smooth (F2, R67: enemy at Ryan's pace), effects rounds 1 and 2 (F3; hollow interiors partly addressed), backdrops and asteroids (F4), board look C as default (R72), ships painted for real plus the 28-ship rebuild and H4 livery (A4), rules batch steps 13 and 14 with re-pins (R1: Codex five, confirmed bugs, boon fix, no dead star in sector 1, Daybreak speed 2, no Decapitation for bosses), the playtest "everything unlocked" switch (R69), varied portraits for all six factions (P, R68), screen layout fix and Credits (ui/4935f72), naming lint, one runner for all standing checks (contrib/opus/tools/run_all_checks.js, 16 PASS), the coverage triage of 572 review files. Exe e991dc6 is on Ryan's PC; a rebuild with the layout fix is in progress.

**Open, in order:**
1. Ryan's playtest tonight on the rebuilt exe. Read it with contrib/opus/tools/playlog_report.js (Codex job cx_plog1) on %APPDATA%\Godot\app_userdata\Voidsworn\play_logs.
2. Codex batch 2 is reviewed and on main (c54be4a): playlog_report.js, coverage_gaps_verified.md, text_accuracy_2026_11_01.md (54 description fixes to apply), content_lint_2026_11_01.md (179 lines for the progression phase), run_montecarlo.js (bot full-run wins 61%: Crusade 34%, Chorus 80%). The ion pulse fix waits on branch codex/ion1: merge it with the next rules batch and re-pin.
3. Board look C refinement (Claude helper, docs/shots/board/).
4. After the playtest: a destruction-focused effects pass (Muse research brief muse_2026-11-01_destruction_research.md first), the hover-tip range mismatch in battle.gd _tip, balance with the Monte Carlo runner plus play data (Grax 49% boss sim, Crusade 47.5%), the Eclipse battleship hull, verified review gaps, Hegemony belly darker (Ryan's call), 4K frame budget, Godot save fixtures. Hullbreaker portraits round 2 is on the backlog (R71).
5. Then the progression phase (contrib/opus/briefs/progression_next_2026-11-01.md): per-faction design packages first; Muse drafts them from muse_2026-11-01_faction_packages.md for Ryan's review. Glasswrights get a full rework there.

**PC rules learned today:** jobs wait while the game is open (Codex jobs excepted); never put |, &, < or > in job arguments (a4_rbs2 hung lane A; it still sits harmlessly in queue\running); re-sending a file to the same PC path can deliver a stale copy, so stage from a fresh folder and check the size; Ryan's main monitor is 4K and the game opens maximised there.

**The game:** *Embers of the Hollow Sun* (repo name voidsworn). The Godot 4 port is the product; the browser JS game is the rules oracle and is frozen except for rules fixes. Lore round 8 is approved and rolled out everywhere (R59 to R61).

**State of main (final commit: see the G-14 row in FINDINGS):**
- **Rules.** Frozen at 8e81d75 (stream B step 9b). The browser check pack has 0 FAIL, and every unit test passes, including the new campaign start test.
- **Godot rules parity.** 48 of 48 goldens and 2,100 random battles with 0 differences (G1, a166af8, oracle e80a6a0). Final re-pin to 8e81d75 (step 9b) at 7b7f398: cloud 48 of 48.
- **Godot campaign parity.** 30 of 30, PC and cloud, oracle 8e81d75 (G3, 65797bc). Nemesis, save and arc tests pass.
- **Godot game (G2).**
  - Title "Embers of the Hollow Sun".
  - Thruster-true movement with smooth stops (flip-and-burn off).
  - Battle pace under 15 s per round even at 28 ships.
  - 36 of 36 six-faction bot campaigns clean.
  - The playtest exe was built Nov 1 00:41 CDT from d78cce0 (lore strings plus the refreshed ships) by the fail-closed export job: exit 0, package check passed, bot smoke clean. To play, double-click play_godot.bat in Downloads\voidsworn_test (play_godot_safe.bat if it won't start); the previous build is in build\export\previous.
- **Effects (G4).**
  - At 20 ships the 1% low is 43 to 65 fps on Forward+, and the death freeze is gone.
  - Weapon marks read at battle distance; round 8 palettes are in.
  - Engine glow drops right after a burn.
- **Ships (A4).**
  - All 36 repainted to round 8.
  - The PC build's ship assets are refreshed (they were stale since Oct 26; `a4_regen.bat` keeps them fresh).
  - V1b bow fixed; waviness partly fixed.
- **Portraits.** Seven admirals, 36 Nemesis with scars, six faction crests.
- **Story.** Six arcs rewritten to round 8 (L). The story tests pass.

**First human playtest:** Nov 1, part of one run (R65). The next one waits for the feel pass.

**Known issues:**
- **Art:**
  - The Eclipse seam-glow rebuild hasn't been checked.
  - The converted ship files are about a tenth of their old size (pck 3.9 GB, was 5.5 GB). Check textures in play.
  - The Hegemony super-dreadnought (H4) is still lumpy.
  - One Crusade Nemesis portrait has glitched scars.
  - Crusade Nemesis can earn an implant scar, which contradicts the lore.
  - The V1b deck-fan fix needs an in-game re-shoot.
- **Balance:** full-run wins are known only for bots (19% in stream B's sim, 63% in Muse's campaign driver). The skirmish mode favours the player-side bot.
- **Rules bugs:** about 20 small confirmed ones, listed in the recommendation, section 3. None crashes.
- **Owner decisions:** recommendation section 7 answered Nov 1 (R64).

**External material** (Oct 28 to 31: Muse, ChatGPT/Codex PR #1, Qwen, DeepSeek, Argon) has been reviewed. The verdicts are in the recommendation, sections 3 and 4.
- **PR #1** only adds contrib files; it isn't merged. The useful parts are named and the stale parts discarded.
- **Ryan's rulings made in Muse sessions** are now FINDINGS R61 to R63.

**Helpers.** All finished their queues. They were Opus's background agents and don't carry over to a new chat. Relaunch streams with [contrib/opus/briefs/takeover_2026-10-27.md](contrib/opus/briefs/takeover_2026-10-27.md) plus the next-phase step they own.

**Process rules learned this sprint:**
- Never use `git stash` in the shared worktrees; it swapped two helpers' work. Use WIP commits.
- Don't bulk-delete the shared scratchpad while helpers run.
- The cloud disk fills up; clean your own scratch.
- After every rules step, G1 and G3 re-pin their oracles.
- Helpers watch port_notes.md for steps rather than waiting for a ping.

**PC runner.** Lane A (GPU) and lane B (CPU), always through tools\pc\tmo.bat, which now waits while Ryan has the game open (Nov 1). Inspect only through device_list_dir and device_stage_files. Never drive the PC by computer control. Large downloads need Ryan's OK.

## 1. What and where

*Sections 1 to 6 are the Oct 26 to 27 record, kept for history; section 0 and the feel pass brief are current. Agent ids and the Babylon details below are stale.*

**The game.** Voidsworn: Fleet Tactics, a Babylon.js 8.20 single-HTML hex fleet-tactics roguelite. PC-only: the phone target was dropped Oct 24.

**Live game** (one link only): https://claude.ai/artifact/QZ7pVvYuupUHFZkFGwxsaH. Publish `voidsworn-3d.html` from `python3 build.py publish`. The hull sidecars (`hulls/`, `hulls_hi/`) are uploaded as artifact files.

**Repo:** github.com/rcbailey12/voidsworn. **Public on purpose.** Work goes straight to `main`.

**Read in this order:**
1. This file.
2. `contrib/opus/go-forward-plan.md`: the APPROVED build plan, two tracks, phases with entry and exit checks.
3. `contrib/opus/FINDINGS.md`: the findings registry, the single list of what is true, wrong or open.

**Behind those:**
- `contrib/opus/verification-report-2026-10-24.md`: the full check of Rey's (Muse's) and the outside models' work.
- `contrib/opus/evidence/`: detailed per-area check reports with file:line quotes.

**Other places:**
- `contrib/muse/`: Rey's work (design docs, reviews, research). It is reference, not instructions. Read it through the plan's section 3 map, and treat any claim as unverified until it is in FINDINGS.md.
- `BACKLOG.md`: everything planned, tagged with plan phases, plus the near backlog.
- `NEXT.md`: the old queue. Superseded, but still holds the per-weapon effects brief.
- `PROGRESS.md`: history.
- `docs/archive/HANDOFF_2026-10-22.md`: the previous handoff (barge v12 to v14 history).
- **Ryan's PC:** see the plan, section 10. Test runner `Downloads\voidsworn_test`; Blender portable 4.5.14; ComfyUI portable.

## 2. Current state

- **Phase status** (top of the plan): A0, B0, A1, A2 DONE. B1 and B2 wait only on Ryan's fuller playtest. A3 DECIDED with a proof running (R28). A4, A5 and B3 to B5 not started.
- **Last recorded publish:** v53.8 (artifact Version 65, Oct 21). Nothing since is published; the playtest build is `index_test.html` from `build.py test`, run on the PC with `voidsworn_test\play.bat` (opens Edge).
- **Barge (C19_51) v15:** shape and paint approved as steps (R13, R14); final sign-off with its effects in A5 (R16). Source of truth: `tools/blender/a1/barge_v15.py` plus `assets/ships/C19_51/`.
- **B1:** every listed fix in main with scripted checks (`contrib/opus/tools/b1_tests.js`, 39 ok). PC smoke passed.
- **B2:** built and PC-checked (contrib/opus/compute/b2/pc_checks_2026-10-25.txt): one PACE table, faster enemy turns, Enter or Space to hurry, the size ramp (about 9 / 13 / 18 ships by sector), capture on one batched prize screen (R23), admiral fixes in data.js (sector 1 boss spread 57 to 89%, inside the 50 to 90 band, S6 FIXED; 96 runs per admiral for admiral calls, S10). Ryan's first short playtest (2 encounters, in Edge): turns a bit quicker, bigger enemies fine, occasional hitches (B-17; `hitchprobe.py` is ready for a PC run, lower priority now that the game may move to Godot).
- **Slow-play fix:** Ryan's Chrome had fallen back to software rendering. play.bat now opens Edge, and the game shows a red banner when the browser is not using the graphics card (scene3d.js, 6dd31d4).
- **A2 engine test DONE:** `contrib/opus/enginetest/RESULTS.md` (numbers, blind reads, port cost). Blind page: https://claude.ai/artifact/LtFoz3Fyatn2bVGLSL9FjE (A = Babylon, B = Godot). Godot won lighting, detail and asteroids; Babylon won effects clearly; Godot's shield is not visible; Chorus and Deathless too dark in Godot; Ithar broken in both (asset).
- **A3 DONE: the game moves to Godot 4.7 (R32).** Proof passed: rules parity at every activation in 5 battles on the PC plus 60 seeds (R29); enemy think worst 0.33 s in 10-a-side fights (R30); Babylon's effects ported into Godot, frame times about even with Babylon (R31). Open side-by-side page: https://claude.ai/artifact/Vum3uvpPPKPTkGRTVjSZyB. Ryan: "Godot seems way better. It's very noticeable now." Effects still need a big pass (G4).
- **The move (R33, plan section 4 "G"):** first playable = one full battle; today's browser version frozen (fixes only); effects pass after a battle plays; done = Godot does everything today's does. Phases G1 to G5. Running now:
  - G1 battle rules complete: agent a373165be9bedd0f7, moving the rules port to `godot/rules/` with `godot/rules/API.md` first, then the rest of battle.js, each feature behind a golden scenario in `tools/pc/parity.bat`;
  - G2 first playable battle: agent ad36c07a1a9f9cf41, in `godot/` (scenes, render, ui, audio), against the API; Ryan runs it from `tools/pc/play_godot.bat`.
- **Muse audit of the proof:** DeepSeek leg filed and applied (RESULTS.md corrections; the 8K rerun JSONs are now in the repo; board sheets at 8K both sides). Qwen leg and the Muse synthesis not filed yet.
- **Outside models:** Muse runs DeepSeek and Qwen from briefs in `contrib/opus/briefs/`. Done: engine choice and B2 syntheses (picked up, X13), Muse's audit of Opus (accepted, X15). Also done: `muse_2026-10-25b_while_opus_paused.md` (A5 effects sheets, B3 admiral levers, port plan, FINDINGS follow-up pass; registry edits applied).
- **Project skills** now exist in `.claude/skills/` (ship-kit, screenshot-verdict, playtest-and-balance). Use them.

## 3. Decisions

**Ryan decided** (Oct 24, full list in FINDINGS.md, R1 to R11):
1. Battles grow over a run: about 10, 14, then 20 ships, with Ryan's fleet small and elite. 20 is a guide, not a cap.
2. The dead-star gravity-well board stays. Its painting is the backdrop.
3. Shields keep faction colours. The cyan-only rule is retired.
4. Capture: add, strip or ransom after a win. A full fleet auto-scraps. Flagships cannot be captured.
5. The barge is built engine-neutral. A 6-flagship engine test runs in Babylon and Godot. The engine call happens before ship 2.
6. Acceptance is Ryan's eye plus automatic checks. No viewer panels.
7. One enemy commander per run is both the Nemesis and the story rival.
8. The barge gets rust and bone. No naval read anywhere, including hull shape.
9. Portraits and 3D height bands go on the near backlog.
10. The repo stays public, and the sound stays as is.
11. The plan is approved.

**Earlier, still standing:** the OPUS_HANDOFF.md section 1 rulings: PC-only, Hegemony sync with flagship anchor, Ithar shield charge, Chorus feed, Deathless attrition, crits soft and temporary, strip-and-ransom capture, ship-five approved, guns never backward, space not naval.

**Claude decided** (technical, reported, vetoable): the list in verification-report section A10. Examples:
- the mega sim resumes in the cloud;
- a 12 s target and 15 s limit per round;
- torpedo range stays 6, with a next-turn impact lane;
- Voidsworn keep carriers;
- the Corsair gate is "no lance weapons";
- the 1.32 GB figure is retired;
- no triangle caps.

## Ryan traveling (Oct 26 to about Oct 30)

Ryan is away from his PC for about 4 days and works from his phone at the usual pace; he won't play builds. His PC stays on with watcher.bat running; `voidsworn_test\autostart_on.bat` (tools/pc/) restarts the watcher at login. Send screenshots to his phone; playtests and visual sign-offs wait for his return. Travel sprint (R34, plan section 4 "Travel sprint"): six streams, one helper each, folder ownership in the plan. Agent ids (restarted Oct 27 02:45 UTC after Ryan's chat interrupt at 23:25 stopped every helper; brief contrib/opus/briefs/takeover_2026-10-27.md): G1 rules a2fcec4812d63553e (worktree .claude/worktrees/g1-rules-2); G2 battle and integration a9d00919887842fac (/home/claude/vs_g2); G3 campaign a5c861647dc80efec (g3b; top priority R51 map visual upgrade); G4 look ab228ebd03e89dc25 (g4b); A4 ships aee63f07b81a53b35 (a4-resume); B game rules ae68d8fc77338c24e (streamb2); music and portraits a9e1f7c8ca0a13d01. Story and career, and naming and lore, are paused: both wait on Ryan's lore sign-off (doc https://claude.ai/artifact/SKyQf2QcJSXGmXfmxKxFpJ, round 3). Note: a chat interrupt from Ryan stops all background helpers; check them after any interrupt. When a usage limit stops helpers, resume each with SendMessage after the reset; if one is reported stopped by the user, launch a replacement with a takeover brief (Ryan allowed this, Oct 26). PC jobs go through the queue (`voidsworn_test\queue\`, watcher window "VS job queue"). Opus check-ins every 6 hours via send_later.

## 4. Open questions for Ryan

None blocking. He weighs in next at:
- the proof results (side-by-side effects sheets plus parity PASS or FAIL), then the final switch;
- a fuller B1 plus B2 playtest when convenient (reward-screen reloads, the retreat dialog, boarding a flagship, a full Corsair fleet, the one-screen prize choice);
- visual sign-offs (plan section 9).

## 5. Next tasks

1. **G1 and G2:** run each helper's milestone on the PC when it reports (fresh staging folder, verify job.bat, separate run.request; `parity.bat` must print PASS). Show Ryan G2 screenshots, then his first Godot battle is the G2 exit.
2. **Muse:** fold in the Qwen leg and the synthesis of `contrib/opus/briefs/muse_2026-10-25c_engine_proof_audit.md` when filed.
3. **Later:** G3 (whole run), G4 (effects pass, Ryan expects big gains), G5 (switch over, Windows build), then Steam (check X18, the GodotSteam licence). K1 before A4. B3 balance lands in data.js and flows to Godot. Fix the Ithar source mesh.

## 6. Gotchas

**Cloud and helpers:**
- The cloud clone with write access lives at `/home/claude/voidsworn`. Game JS has very long lines: use `grep -n` and `sed -n 'Np' f | cut -c1-600`.
- Many `contrib/muse/` files are base64 text, not plain: the check pack and every compute CSV. Decode before use.
- Helpers: run them in the background and keep working. A blocking wait that Ryan interrupts kills every running helper. The two-helper limit is retired.

**The PC bridge:**
- Oct 24 evening: folder listing worked after Ryan granted `Downloads\voidsworn_test`, but the remote shell failed ("Workspace unavailable"). Use file staging and commits plus the watcher .bat jobs.

**PC test runner** (from the Oct 22 handoff, still true):
- `Downloads\voidsworn_test` with `watcher.bat` running.
- Never write job.bat while a run is going (run_smoke deletes job.bat after it finishes).
- Commit files with device_commit_files, then commit `run.request` in a separate, later call.
- Give every job its own staged name (`outputs/job_<tag>.bat`, `run_<tag>.request`), and stage `build\job.bat` back to check it before sending run.request.
- `build\job.bat` runs once instead of the smoke test, and a job must `cd` back to `build` or it re-runs.
- Scripts are in `tools/pc/`.

**Driving the PC (Oct 25):**
- Ryan wants Claude to click things itself when the PC is linked (for example starting watcher.bat), not ask him.
- Computer control works: File Explorer and Command Prompt are click-only (no typing). Path: Explorer, Downloads, voidsworn_test, double-click watcher.bat. Explorer opens on the second monitor (27GL850).
- The remote shell still fails ("Workspace unavailable"). Staging, commits and the watcher jobs work.
- Cloud closeshot times out loading the game (no GPU). Take game screenshots on the PC.

**Cloud Blender (Oct 25):** `pip install --break-system-packages bpy` (5.2, about 400 MB) runs Blender headless in the sandbox, good for clay renders and shape work (`tools/blender/a1/clay.py`). The game's .vsm hull stores the bow at +x; the kit scripts and the a1 builder use bow at -x, so clay.py turns imported game hulls with FLIP=1.

**Sims (Oct 25):** `bossmatrix` covers sector 1 only unless `BS=2` or `BS=3` is set. Rebuild the baseline CSVs with `python3 contrib/opus/tools/mega_report.py`. Running sims rewrite their logs constantly; commit them when they finish.

**PC tools:**
- PS 5.1 Invoke-WebRequest is slow for big files: set `$ProgressPreference='SilentlyContinue'`.
- Hunyuan: `C:\AI\HY3D2\Hunyuan3D2_WinPortable`.
- xatlas crashes inside Blender on Windows: prepare UVs in the sandbox (`tools/blender/uvprep.py`), then bake with `hullbake.py`.
- download.blender.org blocks scripted downloads; the Berkeley mirror works.

**Oct 25 lessons:**
- Re-using a staged path with device_commit_files can write a stale earlier copy: stage every job from a fresh folder and compare `build\job.bat` byte for byte before sending run.request.
- `pkill -f <pattern>` or `pgrep -f` inside a Bash call matches that call's own command line and kills the shell (exit 144). Find node PIDs with `ps` and filter instead.
- Bigger B2 battles make `fuzz 2000` take about an hour on the PC.
- Effects that look fine in software rendering can show black squares on the real GPU (NaN); guard shaders (screenshot-verdict skill).

**Oct 25 night lessons:**
- The watcher window gets closed sometimes; if a job does not start in a minute, restart it by computer control (grants expire after 30 minutes idle: resolve_access, then request_access again).
- A slow game on Ryan's PC: check the WebGL renderer first (Claude in Chrome javascript_tool). "Microsoft Basic Render Driver" means software rendering.
- Depth of field in test stills made Ryan think the ship detail was blurry; keep it off except mild on hero shots.
- Messaging a finished helper by its agent id resumes it with its context.

**Checks and the game:**
- closeshot's local server needs a big backlog (request_queue_size 256), or desktop shots silently lack the kit.
- Full smoke takes about 4 min on the PC. Smoke does not catch invisible hulls: add a PC closeshot plus console capture (`errprobe.py`).
- Transfers cap at about 25 MB per file and 100 MB per call, so split zips. Artifact publishes cap at 64 MB.
- The game has no glTF loader: hulls are its own JSON plus WebP (`.vsm` for C19_51). Babylon 8.20 has no AgX tonemapper. The official Blender MCP needs Blender 5.1 (the PC has 4.5.14).

**Writing and committing:**
- Older Muse docs carry retired rules (cyan-only shield tests, phone framing, glTF recipes). FINDINGS.md section "The record" lists them.
- Git commits: `-c user.name="Ryan Bailey" -c user.email="rcbailey12@gmail.com"`, with the Co-Authored-By and Claude-Session lines.
- No em dashes anywhere (grep count must be 0).
- WebFetch needs URLs that came from a search or the user, and Reddit is blocked.

Starter line:
```
Read HANDOFF.md section 0 in github.com/rcbailey12/voidsworn (main), then FINDINGS R64 to R75. You are orchestrator and final reviewer only: send coding to Codex on my PC, research and drafting to Muse, and review what comes back. Start with the open issues and open pull requests on the repo's job board.
```
