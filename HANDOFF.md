# Voidsworn (Embers of the Hollow Sun): handoff (updated Nov 13, 2026, 08:30 CST)

## 0. Status at Nov 14, 2026, 17:10 CST (23:10 UTC; read this first)

**Rules versus one-off calls.** Only Ryan's words make a standing rule (FINDINGS quotes them). Board choices made for one day or one job (effort levels, caps, job order, which seat took a job, wrappers like RUN_RETRY.bat) are operating notes in LOOP.md, not rules: change them freely when the situation changes. When a FINDINGS row extends Ryan's words beyond what he named, it says so and asks him.

**First clean-up for the new Board (R251, RULEBOOK 0.10):** move HANDOFF sections 0c, 0b and 0a to docs/archive; roll LOOP.md LATEST lines before Nov 14 into one dated summary; mark superseded FINDINGS rows (R163 item 2 by R246; the Nov 12 Kimi 30 minute figure by R250). Then let Muse check the result for conflicts.

**What to trust.** This section, FINDINGS (R236 to R251 are the newest) and LOOP.md's Nov 14 LATEST lines and its "Nov 14 update" in The seats are live. Sections 0c, 0b and 0a below, and LATEST lines before Nov 13, are history: where they differ from this section, this section wins. Older seat text in RULEBOOK 2.6 is overridden by its Nov 14 paragraph (PR on branch opus/issue-545, with the PROGRAM.md shield fix; merge it first). Nothing under docs/archive/ is followed.

A fresh Board thread starts here after the Claude plan reset (about 18:00 CST Nov 14). The last Board thread (Nov 13 08:30 to Nov 14 17:10) ran at 2 percent of the weekly plan from Nov 14 morning, so it queued work and merged only small things. Everything below is in LOOP.md's LATEST lines (Nov 14) and FINDINGS R236 to R251.

**Seats today (LOOP.md "The seats").** Codex is the main builder (fast; about 3 or 4 big jobs per 5 hour window, so on Nov 14 the Board set build briefs to Effort (Codex): high; an operating note, set effort per job). Kimi (Kimi CLI arm, kimicode) does mid-size code, rules and balance jobs; about 2.5 hours of agent time per 5 hour window; on Nov 14 it skipped the balance pack on 41, so the Board tried listing required outputs (a practice, not a rule). DeepSeek takes small exact jobs (runs slow; give 120 min caps). Muse does design, outside checks (issue 256) and audits. The Claude API credit is OUT until its monthly refresh (about Nov 21); Ryan will not add credit, so the opus and sonnet API arms are off. Ryan said no to Gemini 4 Hydrogen for now (Codex is the better buy).

**PC jobs.** Everything runs through Downloads\voidsworn_test\queue on DESKTOP-D5CTOET; long waits go in start-ed windows. Wrappers written Nov 14: RUN_RETRY.bat <issue> <arm> <cap> [kimi] (clone retry, Kimi quota preflight every 15 min), CODEX_CHAIN_14*.bat, LANES_14*.bat, GPU_CHAIN_14.bat. Logs: codex_chain_14h2.txt, retry_<issue>_<arm>.txt. No heavy jobs while Ryan games: ask, and stop only what loses nothing.

**First job for the new Board: the review.** Review by diff, Muse's opus_check files on muse/issue-256 first, then merge in this order:
0. PR 712 (this hand-over, RULEBOOK 0.10 and the 2.6 Nov 14 paragraph, the PROGRAM.md shield fix; the Board that wrote it cannot merge it) and Muse's audit PR from issue 706. Then do the clean-up above.
1. PR 690 (Codex 687, the five runner fixes Ryan approved: shared local repo copy, clone retry, preflight, safe chains, resume from partial). Muse: GO WITH CONDITIONS (retry count wording, the run_all_checks registration, the Refs #N commit trailer). After merging, copy tools/pc/work_issue.bat, work_issue.ps1 and codex_issue.bat to the PC copies (work217\tools and build_b\tools\pc). Clone failures happened all day Nov 13 and 14 until this lands.
2. PR 691 (Codex 676, weapon match R241, 253 files). Painted proof in the PC folder hb676out. Muse conditions: ratify the A19 bow launcher cut, ratify SAME and SPLIT as R241's reading, add a PASS guard to publish.py.
3. PR 694 (Codex 642, Eclipse round 3, R243). Painted proof in ecl642r3out. Muse: ratify the RULEBOOK 0.5 rewrite (check it quotes R243 and does not stretch past Ryan's words, R251) and the brighter core (send Ryan the picture: the brighter glow is his call), close the stale 642 job files (never delete on the PC).
4. PR 696 (Codex 688, A20 per R244: real bow openings, angular flanks). After 691: rule 11 numbering clash, render_R244.py string search breaks on 691's SHEET_DEVICE line, sheet.jpg was over the 8 MB cap. Then a GPU paint run of A20.
5. PR 700 (Codex 373 station T2): check R247 (the station dwarfs every ship class at the battle camera). PR 701 (Codex 463 deaths). PR 702 (Codex 92 debrief).
6. PR 704 (Kimi 41 captured hulls): Muse GO WITH CONDITIONS, one NO-GO leg: the balance pack is missing; the prize Add path bypasses the ripped rule. Needs a second run or a Board fix. PR 707 (Kimi 43 Eclipse portraits): unanimous GO WITH CONDITIONS; ratify drawing the frames in code instead of ComfyUI.
7. PR 705 (DeepSeek 44 finale board). PR 709 (DeepSeek 644 text floor report; PR 698 closed as superseded). PR 703 (Muse 250 Glasswright sheet, for Ryan to pick). PR 695 (Muse 689 paint directions, for Ryan). PR 692 (Muse checks on 256).
Send Ryan one picture per landed visual change, two lines each.

**Landed between 17:10 and 17:55 CST (check these too).** PR 713 (Muse 708 fleet inventory), PR 714 (DeepSeek 710 scale table and scale_check), PR 715 (Codex 538 hits pass 2), PR 716 (Codex 367 every weapon effect), and Muse's audit PR from muse/issue-706. CI facts at 17:55: (a) every branch fails the standing doc check because main's HANDOFF.md names the scale playbook path before it exists (the Board's slip); merging PR 712 first fixes it for all; (b) PR 714's scale_check fails on purpose, it reports today's undersized objects (the station is 26 units against a target of 99 to 297); merge it with those rows as known failures that the station, terrain and planet jobs must clear, or it blocks every PR; (c) PR 702 (Codex 92 debrief) fails core_sync_test and inheritance_test: a real failure, fix before merge; (d) auto-pr failures on muse branches are a second push to a branch that already has its PR: harmless.

**Running or queued at handoff.** Codex chain H2: 538 (hits pass 2), then 367 (every weapon effect muzzle to impact, R248 and R249), 368 (nebula and storm hexes, R247 scale), 369 (planet and rocks from real data, nothing recognisable, R245). DeepSeek: 710 (one scale table in the scale playbook (scale.md, written by issue 710) plus godot/render/test/scale_check.gd, R247 and R249). Kimi: 371 (shield model, R246: one pool, coverage, lossy routing; rules first, balance pack) resumes from its partial when the Kimi quota returns. Muse: 706 (outside audit since Nov 10), 708 (fleet inventory and concept gaps: 49 hulls plus fighter and bomber, only 9 build sheets; Sunward, Hegemony, Glasswrights have none), checks of 700, 701, 702, 705, 709.

**Muse audit 706 (delivered on muse/issue-706, commit 8b0c01aa; review and merge it early).** Top five: (1) HANDOFF section 0 was stale at its pin (fixed by this rewrite) and the doc check cannot tell a stale status; (2) PROGRAM.md still ordered the old four-strength shield model (fixed on opus/issue-545); (3) the scale playbook (scale.md, written by issue 710) does not exist yet while the station build proceeds against R247: the PR 700 review checks R247 at the battle camera directly, and issue 710 (DeepSeek) writes scale.md and scale_check; (4) commit messages landing on main can still close issues (only PR bodies are guarded): file a check; (5) geometry has almost no CI surface (placeholder blocks, one A16 fixture). 11 findings plus 2 notes in the file: turn the confirmed ones into jobs.

**Muse fleet inventory 708 (draft, re-checks running).** 51 hulls: 5 built, 4 sheeted awaiting PC runs, 5 concept only, 3 shapes settled (S8, H10, G15), 12 design pack only; the Iron Mandate still needs its own concept; d_totality is ruled but not in data.js yet. Plan the next concept and build rounds from its gaps file.

**Carry-overs, so nothing from Nov 13 and 14 drops.**
- Design standing rules: Muse concepts are inspiration and the Board is the final designer (R236); every ship fits the lore bible and the game's ship details; A18 and A19 broaden toward their concepts' proportions so the family varies in width (R239); weapons on every model match the game's weapon slots, two mounts per slot allowed if consistent (R241); R247 to R249 apply to everything because Ryan said so; R244 (bow openings with depth, angular flanks) is A20 only until Ryan confirms it for every ship.
- Open follow-ups: Kimi 41 needs a second pass (balance pack, the prize Add path bypassing the ripped rule); A20 needs a GPU paint run after PR 696 merges; issue 545 (sweep follow-ups from 540, incl. branch clean-up and closing 532) is still the Board's own list; the Hullbreaker fixture C19_51 must be rebuilt (steps in tools/recipe/sheet_fixture_hash.py) whenever the Hullbreaker kit or paint stack changes; the Eclipse E12 core was measured at saturation 0.2 to 0.3 (Ryan saw white); a lesson, not a rule: measure colours as well as looking.
- Done, do not redo: the Hullbreaker paint after PR 682 on all five ships (PC folder hb682out, all checks passed); Ryan saw the A20 bow picture and ruled R244 from it. The hb676out (weapon match) and ecl642r3out (Eclipse round 3) paint runs were made from PR branches before review: judge them as proof for those PRs, then rerun from main after merging.
- Paint runs on the PC: copy HB_PAINT_R240.bat (Hullbreakers) or ECL_PAINT_642R3.bat (Eclipse) and change the branch and output folder; stages 4 to 7, checks, in-game shots at cameras 170 and 60, painted pictures beside the concept (lift 1.25 Hullbreakers, 2.2 Eclipse).
- Fleet: 49 hulls plus fighter and bomber in data.js; only 9 build sheets (Hullbreakers A16 to A20, Eclipse E11 and E12, Chorus C10 and C11); Sunward, Hegemony and Glasswrights have none; squadrons have a written design (contrib/muse/design/squadrons_2026_11) and no concept art. Muse issue 708 answers what concepts are missing; plan the next concept and build rounds from it.
- Muse reads only issue 256 for briefs: when a muse-labelled issue opens, post it on 256 too (Muse missed 706 and 708 until briefed there).
- PC facts: the bridge has file tools only (device_bash fails: hardware virtualisation is off in the BIOS; Ryan may change it later if needed); git show prints LF, so copy .bat files from the working tree (CRLF by .gitattributes); never delete on the PC (stale job files are listed, not removed); Kimi says "no credential configured" when its login expires: Ryan runs KIMI_CLI_LOGIN.bat; jobs that run the full checks need a cap of 90 minutes or more; when Ryan games, stop only what loses nothing and restart when he says.
- Ryan's open picks: the brighter Eclipse core (PR 694 picture), the Glasswright species sheet (PR 703), the faction paint directions (PR 695), and whether the Hullbreaker plates should read bigger and lighter like the concept (the Board raised it on the A20 bow picture; Ryan only ruled the bow openings and flanks).

**Rulings landed Nov 13 and 14 (FINDINGS).** R236 to R243 (seats, design rulings; R243 surface order per faction: Hullbreakers patchwork, Eclipse precise, Glasswrights blown glass, Sunward triangular, Hegemony rigid), R244 (no flat disc openings, no flat-box hulls: A20 first, every ship since Ryan's "Yes, agreed" at 17:22 CST), R245 (planet from real data, nothing recognisable), R246 (shields Rim and Gap, one pool), R247 (scale of everything against ships and hexes, on the sector map too), R248 (doom arc and every effect: core, glow, motion, fade), R249 (scale and effect bar cover every projectile and weapon effect), R250 (seats and spend on Nov 14: API arms off till the monthly refresh, runner fixes approved, Codex aggressive, Kimi kept, no Fable advisor or Hydrogen, Muse as auditor, fresh Board thread). R243 is still OPEN until its RULEBOOK 0.5 and playbook edits land (PR 694).

## 0c. Status at Nov 13, 2026, 08:30 CST (14:30 UTC; read this first)

**Read in this order:** this section; contrib/opus/LOOP.md ("The seats", the LATEST lines); docs/RULEBOOK.md (wins over every
other doc); FINDINGS R225 to R235 for this stretch's rulings. Section 0b below is the Nov 11 state: where it disagrees, this
section wins.

**Landed Nov 12 to 13.** Hullbreakers A16 and A17 built, painted and accepted (R235: "looks good but maybe a bit dark", judged in
play; PR 610). Eclipse E11 and E12 (PR 620) and Chorus C10 and C11 (PR 628) through the recipe and in game, unpainted. Muse's
design packs for Sunward, Hegemony and Glasswrights (PR 626, R232) and the Hullbreaker and Eclipse class family concepts (PRs 625,
629). Build manifest check (PR 637), scene gate 4.87 to 3.29 ms (PR 638), check guard on every Godot test (PR 639), Chorus eats a
core (PR 612). New rules: R233 the Board is the final designer and director, Muse concepts; R234 Codex only for what no other
seat can do; Kimi Code plan for short reviews only (about 30 minutes of agent work per 5 hours); R231 Muse legs include Grok and
Google Flash.

**Seats today.** Opus workers in the Board thread (2 to 3 at once). The API workhorse arm `opus` on Ryan's Claude API credit
($100, expires Nov 22): `work_issue.bat <n> opus`. Codex idle except for running-game captures and benches. DeepSeek off
(cost). Muse runs when Ryan points it at an issue.

**Open, in order.**
1. PR 635 (issue 633): A18 Sniffer, A19 Mauler, A20 Den sheets passed round 2; the worker is adding the recipe half and a PC job.
2. Eclipse paint stack for E11 and E12 (next, Ryan agreed), then Chorus paint, then the Eclipse mote and flare (E13, E14; the
   flare carries one closed ring, R233), then the Sunward, Hegemony and Glasswright flagships from their packs.
3. Muse: 631 (Chorus class family), then opus_check_620 (brief on issue 256).
4. Text floor 17 (RULEBOOK 9.4): 165 font sizes fall under it (issue 632 report), a visible UI job.

**Traps found this stretch.** A q_ file that sets a variable must use setlocal (a leaked WORK_MODEL sent three opus runs to
Kimi; the runner now guards it, PR 636, copy tools/pc/work_issue.bat to work217\tools when no run is going). Give every new
version of a PC file a new staged file name (the bridge resent an old upload). One cmd per ship in a two-ship PC job (stage 3
kept the first ship's CAMJ). Never merge on a wait loop that timed out.

## 0b. Status at Nov 11, 2026, about 20:30 CST (Nov 12 02:30 UTC; read this first)

**Read in this order:** this section; contrib/opus/LOOP.md ("The Board's standing duties", "The seats", the LATEST lines of
"Current state"); contrib/opus/OPEN_WORK.md (one row per open issue and parked pull request); the playbook for your area
(docs/playbooks/, PROGRAM.md first); FINDINGS R183 to R215 for Ryan's words. docs/RULEBOOK.md (issue 492, merged as PR 551) is the one
live list of rules; anything under docs/archive/ is history, never followed (the issue 492 clean-up moved the stale briefs
there, contrib/opus/reviews/cleanup_492.md). Section 0a below is this morning's state: where it disagrees with this section, this
section wins.

**The Board** is one Claude thread in the Project, Opus 5.5 since Nov 11 afternoon. It owns the whole board, starts agreed work
on its own and asks Ryan only for design, key decisions, reviews of what he will see, and conflicts (R194, R202). New standing
rule (R214): a ruling that changes a working method is not landed until the same pull request edits the working document a
worker reads. Ryan, Nov 11, 20:05 CST: "Let's ensure we're documenting all these decisions and approaches. I don't want this
drift to keep happening or where we get confused on how we're doing things."

**Decided today (each is now in its playbook).**
- Ship concepts: one realistic style, the round 1 Scrap Brick picture (R197). Build references accepted: Hullbreakers A16 and
  A17, Chorus C10 and C11, Eclipse E11 and E12, the station T2 (R201, R204, R206). Sunward (S8 shape), Hegemony (H10 shape) and
  the Glasswrights (G15 shape) go through the Opus build-sheet route, no more image rounds (R204, R206). Colour is fixed in the
  build (R204). Where: docs/playbooks/factions.md, concepts_round2.md.
- Ship builds: a build sheet that passes the concept standard before any build (R203); the concept guides, it is not traced
  (R207, R213); every Blender model is an Opus worker's (R205); insides through the whole hull (R209, R215); the settled build
  method is binding (R214). Where: docs/playbooks/ships.md, docs/ship_pipeline/RECIPE.md (PR 549).
- Battle look: wrecks blown apart (R186); the flash counter counts by area (R193); the 0.70 s cap is for flame only (R193); the
  kill moment holds and slows (R193); hits pushed harder, torpedo 140 px, neighbour light faint for now (R208). Where:
  docs/playbooks/deaths_and_hits.md, effects.md.
- Movement: never sudden, feels like space (R189); the main engine does the travelling, one-hex slides on thrusters (R195).
  Where: contrib/opus/briefs/movement_spec.md.
- Screens: lime retired, ember orders sheet everywhere (R191); battle screen E1 Ledger, Glacier #92b8e8 for shield readouts
  only, 3D shields keep faction colours (R210). Where: docs/playbooks/screens.md (PR 544 carries the update).
- Sound: weapons dry, big moments get tails and weight (R193; docs/playbooks/sound.md).
- Rocks turn slowly by default (R212).

**Running or waiting on review now.**
- PR 547 / issue 532: Hullbreaker build sheets, round 2 (Opus worker). PR 536 (Codex's try) stays open as the reference only.
- PR 544 / issue 271 step 2: the battle screen built as E1 Ledger (Opus worker).
- PR 524 / issue 461: hits, waiting on Muse's re-check (opus_check_524b); then 538 (hits pass 2).
- Merged at 20:50 CST: PR 549 (the build method, R214, R215), PR 548 (issue 541, rocks turn by default), PR 551 (the rulebook).
- PR 543 / issue 357: code traps; conflicts with main, to be redone on current main once 524, 544 and 547 land.
- This pull request (issue 492): Part A carries the Nov 11 rulings into their working documents; Part B is docs/RULEBOOK.md, with contrib/opus/reviews/rulebook_board_notes.md for the Board.

**Next, in order.** Merge what is green. A16 and A17 round 2 to Ryan beside the concepts; then the manifest check (550). Build
sheets for E11, E12, C10, C11 and the station; then S8, H10 and G15 by the shape-locked route. Hits pass 2 (538), small-ship
deaths (463), sound weight (507). The rulebook's batches of Ryan's own calls (contrib/opus/reviews/rulebook_ryan_batch.md).
Then clean the issue board: every open issue kept and rewritten, folded, or closed with one line (OPEN_WORK.md has a verdict
for each).

**Every open issue, by track.**

| Track | Playbook | Open issues |
|---|---|---|
| Rules of the project | docs/RULEBOOK.md (issue 492), AGENTS.md | 492, 545, 216 |
| Battle effects | docs/playbooks/effects.md, deaths_and_hits.md | 461, 538, 463, 507, 370, 367, 371, 372, 362 |
| Movement | contrib/opus/briefs/movement_spec.md | 507 (smaller movement items) |
| Sound | docs/playbooks/sound.md | 507 (sound weight), 211 |
| Ship concepts | docs/playbooks/factions.md, concepts_round2.md | 515 (record), 276, 250 |
| Ship builds | docs/playbooks/ships.md, docs/ship_pipeline/RECIPE.md | 532, 550, 373, 209 |
| Space and the board | PROGRAM.md track 3 (no playbook yet) | 541, 369, 368, 100 |
| Screens | docs/playbooks/screens.md | 271, 546, 92 |
| Campaign and story content | the browser oracle, godot/rules | 41, 42, 43, 44 |
| Tooling, checks, performance | AGENTS.md, .github/workflows | 357, 377, 376, 238, 234, 221 |
| The program itself | docs/playbooks/PROGRAM.md | 405 |

**Usage.** Two Opus workers at most while the Board thread is active; one Codex job and one GPU job at a time; Muse is started
by Ryan; never delete anything on his PC.

**What the day taught (now in the rulebook).** Record the problem Ryan was reacting to, in his words, beside every rule (R189).
When Ryan likes a picture, the next job edits that picture (R192). A number in a playbook is a starting point judged by eye;
checks protect comfort, frame rate, saves and crashes (R187). Show Ryan the picture he means, with its code name, before
building on it (R196). Check the arithmetic yourself (R193).

## 0a. Status at Nov 11, 2026, 07:30 CST (13:30 UTC; still true except where section 0 above says otherwise)

**Read in this order:** this section; contrib/opus/LOOP.md "Current state" (the live board: what is running, what waits on Ryan, how each seat is launched); docs/playbooks/PROGRAM.md (the plan and the decisions made and owed); the playbook for the area you are working in; contrib/opus/FINDINGS.md from R170 on (Ryan's rulings of Nov 10 and 11, in his words).

**The plan (R167, issue 405): one finished battle, and a playbook per area that any model can run.** Ryan: "codebase is yours with my direction and vision, you bring it to life with the decisions needed from me. I want this to end with something that opus or other models can run from". The finished battle is Sunward Crusade against Eclipse on the dead-star board (R180). Every item flows the same way: the Board makes options, Ryan picks from a picture, a worker builds it, a real capture proves it, the recipe goes into a playbook.
- docs/playbooks/PROGRAM.md: the end state, the tracks, who does what, decisions made and owed.
- docs/playbooks/factions.md: a sheet per faction, where each flagship stands with its reference picture, and the concept method that works.
- docs/playbooks/concepts_round2.md: the twelve-line gate every ship concept must pass (it must read as a space warship, armed, from above).
- docs/playbooks/ships.md, effects.md, deaths_and_hits.md, screens.md, sound.md: target, inputs, steps, the checks that prove it, traps, a job template.
- contrib/opus/briefs/campaign_rail_orders_sheet.md and the "Orders sheet" section of contrib/opus/briefs/ui_style.md: the interface look every screen now follows.

**The Board.** The Board thread in the Claude Code Project owns the design, the final technical call and every merge (R119, R167); no merge waits on Ryan. He sees options before a new look is built and a picture when it lands. Every pull request is reviewed by its diff and, for anything visual, by its pictures. The Board through Nov 11 was Fable 5.2 (the design window: map, rail, concepts, playbooks); from the next Board thread it is Opus (R169, R180).

**Seats (R180).**
- Design, picture reviews, picks put to Ryan, specs, merges: the Board.
- Hard or visual builds: Opus worker threads (a background agent with its own worktree, branch opus/issue-N, medium effort, captures through the look bench on the PC). No Fable helpers: Ryan's Fable allowance is spent.
- GPU and pipeline builds, and concept pictures with its built-in image tool: Codex on the PC. It gives about 100 to 110 minutes of work per five-hour window and then stops with 'usage limit hit'; LOOP.md says how to queue it and how to relaunch after a reset.
- Well-specified rules and test work: the DeepSeek workhorse on the PC.
- Variety in pictures, organic subjects, research, design text, outside checks: Muse (Rey chairs; a blind Rey leg first).
- Picks, looks, money: Ryan. Plain words, the answer first, his pick asked with the Board's pick stated. He often cannot see a tall or large image: send pictures one per item, about 1280 px wide, never one long stacked sheet.

**Where things stand.**
- Campaign map: rounds 3, 4a and 4b are in the game (the approach to the star over three sectors, routes only, fight stops show the enemy, five region landmarks and emblems). Round 4c (issue 470) answers Ryan's four notes of R181. The left rail is the orders sheet (PR 464). Next screen: the battle screen.
- Effects: every explosion is rebaked by route B (PR 455). Next: deaths in three beats (issue 462, an Opus worker), then the hit ladder (461) and small-ship deaths (463).
- Ship concepts (state after Ryan's 08:33 CST review, R185; the table is in docs/playbooks/factions.md): SETTLED: Sunward S8 (forked prow), the Eclipse crescent flagship E4 and ring cruiser E8 (struts to add), the Chorus flagship C9 (C8 becomes the bladeback cruiser). In refinement, direction agreed ("the direction and inspiration is right"): Hegemony H8 (guns "almost cartoonish": redraw them low and sunk in), Hullbreakers A11 (nothing hanging off, not naval), Glasswrights the Mirror Deck G11 made prismatic and not a boat. Ryan asked for a NAVAL PASS on every ship of every faction: gate line 11 in docs/playbooks/concepts_round2.md now lists the tells; run it on every sheet. Put the code name on every picture sent to him. Then the Sunward and Eclipse fleets.
- Rules: the workhorse cleared the known-bug batches; protocol values are ruled (R179); checks on main are green.
- Sound: sources and palettes studied (contrib/muse/design/sound_sources_2026_11/synthesis.md); the listening page for Ryan is still to build.

**Checks.** Every push to a codex/, muse/, work/ or opus/ branch gets one real run: the standing checks (a truthful table: PASS, KNOWN, FAIL, SKIP), no em dashes, rules parity, and the Godot game checks (every script loads, the headless checks, one bot battle). A script under godot/**/test/ needs its line in godot/tools/ci/godot_checks.txt. Merge only on green. Only contrib/opus/LOOP.md and FINDINGS.md go straight to main.

**The outside audit (R154 to R161) is done.** Its three root causes are standing rules for every job: a check's state comes from the real functions, never typed by hand; missing things fail loudly; one source per fact.

The Oct 26 to Nov 7 history (sections 0a to 6 and the Nov 1 block, including "Gotchas" and "PC test runner") is in docs/archive/handoff_history_2026_11.md.
