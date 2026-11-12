# Voidsworn (Embers of the Hollow Sun): handoff (updated Nov 11, 2026, 20:30 CST)

## 0. Status at Nov 11, 2026, about 20:30 CST (Nov 12 02:30 UTC; read this first)

**Read in this order:** this section; contrib/opus/LOOP.md ("The Board's standing duties", "The seats", the LATEST lines of
"Current state"); contrib/opus/OPEN_WORK.md (one row per open issue and parked pull request); the playbook for your area
(docs/playbooks/, PROGRAM.md first); FINDINGS R183 to R215 for Ryan's words. docs/RULEBOOK.md (issue 492) becomes the one
live list of rules when it merges. Section 0a below is this morning's state: where it disagrees with this section, this
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
- PR 549: the build method in ships.md, RECIPE.md and AGENTS.md (R214, R215). Merge when green.
- PR 548 / issue 541: environment follow-up (workhorse; the Board recovered its edits). Merge when green.
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
