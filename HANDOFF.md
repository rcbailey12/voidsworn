# Voidsworn (Embers of the Hollow Sun): handoff (updated Nov 10, 2026, 19:30 CST)

## 0. Status at Nov 11, 2026, 07:30 CST (13:30 UTC; read this first)

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
- Ship concepts (state after Ryan's 07:31 and 07:56 CST reviews, R183 and R184; the table is in docs/playbooks/factions.md): SETTLED: the Eclipse crescent flagship (E4) and the Chorus flagship (C9, the old leviathan; C8's bone-through-skin becomes the bladeback cruiser). Sunward and Hegemony have their bodies but are being redrawn at the bow (no more big gun on the tip of every nose; Hegemony heavier), the Eclipse ring cruiser is being redrawn with the ring lying flat, and Codex tries its own Hullbreaker with rockets on top: Codex issue 475. Hullbreakers are close: Ryan wants a mix of Muse's A7 and A9 without A7's grey block (Muse issue 477). Glasswrights: G9, the glass Wedge, is the best so far and the picture to beat; three fresh routes from the lore are with Muse (issue 476). Then the Sunward and Eclipse fleets.
- Rules: the workhorse cleared the known-bug batches; protocol values are ruled (R179); checks on main are green.
- Sound: sources and palettes studied (contrib/muse/design/sound_sources_2026_11/synthesis.md); the listening page for Ryan is still to build.

**Checks.** Every push to a codex/, muse/, work/ or opus/ branch gets one real run: the standing checks (a truthful table: PASS, KNOWN, FAIL, SKIP), no em dashes, rules parity, and the Godot game checks (every script loads, the headless checks, one bot battle). A script under godot/**/test/ needs its line in godot/tools/ci/godot_checks.txt. Merge only on green. Only contrib/opus/LOOP.md and FINDINGS.md go straight to main.

**The outside audit (R154 to R161) is done.** Its three root causes are standing rules for every job: a check's state comes from the real functions, never typed by hand; missing things fail loudly; one source per fact.

The Oct 26 to Nov 7 history (sections 0a to 6 and the Nov 1 block, including "Gotchas" and "PC test runner") is in docs/archive/handoff_history_2026_11.md.
