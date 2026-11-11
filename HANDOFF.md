# Voidsworn (Embers of the Hollow Sun): handoff (updated Nov 11, 2026, 11:44 CST)

## 0. Status at Nov 11, 2026, 11:44 CST (17:44 UTC; read this first)

**For the next Board thread (Opus 5.5).** The morning added three things on top of section 0a below. Read contrib/opus/LOOP.md "Current state" top lines for the live detail and FINDINGS R183 to R193 for Ryan's words.

**1. Your first job: the rulebook (issue 492, R190).** Ryan: "Those old hard coded rules with no context or detail artifically restricing us are exactly what I'm worried about across the board... All this old context and decisions living in GitHub is something I want to ensure we have in a clean state moving forward". All four sweep legs are delivered and nothing is decided yet:
- contrib/opus/reviews/rules_sweep/register_findings.json and .md (the findings log as 514 rules) and register_docs.json and .md (playbooks, briefs, plans and agent files as 313 rules, with a LIVE, PARTLY STALE or HISTORY verdict per document). Every quote in both was checked word for word; `said_by` in the first is NOT reliable (it marked the Board's R123 as Ryan's): re-check who set a rule before asking Ryan about it.
- Muse's outside sweep, the report named rules_sweep_2026_11 under contrib/muse/reviews (the outside sweep: thirty rules to challenge, contradictions, stale documents, the shape of the rulebook, and where the Board itself is the problem). It arrives with PR 509 (merge when green); its five leg files are named rules_sweep_2026_11_leg_ and the model's name.
- contrib/codex/reviews/rules_sweep_checks.md and .json (the rules that live in checks, tests and code comments, and which checks each audit fix would trip). Merged.
What to do is written in issue 492: decide every REWORD, RETIRE and contradiction against its source; Board-written and agent-written rules you fix without asking; Ryan's own calls that would change go to him in short batches, his words beside the proposed wording (his first batch is R191); write the rulebook (one new file in docs, named RULEBOOK) by area, each rule with its reason; move superseded briefs, plans and specs to docs/archive/ with a note of what replaced each (nothing is deleted; FINDINGS.md stays as history with a header); bring the playbooks, AGENTS.md, CLAUDE.md, this file, the three skills and the checks into line; then a second Muse run and a Codex check of the result.

**2. The cinematic audit is done and its builds are running (R186 to R193).** The list Ryan picked from: contrib/opus/reviews/cinematic_audit_top10.md (five root causes, ten items, pictures in docs/shots/cinematic_audit/top10/). His picks (R193): the flash counter counts by area as its guideline does; the kill camera holds and slow motion plays; the 0.70 s cap is for flame only; build in the Board's order. Movement is to be read by R189: never sudden, jerky or stop-start, and it must feel like space; thrusters and slides wherever a ship in space would use them.
- MERGED: death beats (issue 462) and blown-apart wrecks (issue 484).
- RUNNING: issue 504 (flash counter) and issue 505 (movement), two Opus workers launched from the previous Board thread; that thread reviews and merges those two and then goes quiet. Issue 506 (sound routing) is with the DeepSeek workhorse on the PC (branch work/issue-506-deepseek).
- HELD in issue 507: hits (after 504 merges), the kill moment (after 505 merges), sound weight. Then shields, once Ryan has picked a shield look. Small-ship deaths are issue 463; the hit ladder is issue 461.

**3. Ship concepts (R183 to R185, R192).** SETTLED: Sunward S8, the Eclipse crescent flagship E4 and ring cruiser E8, the Chorus flagship C9 (C8 becomes the bladeback cruiser). OPEN, with Muse issue 500 drawing them by image-to-image edit: the Hullbreaker flagship is the ORIGINAL concept (docs/ship_pipeline/concepts/C19_51.webp) with only its three sea parts changed; the Glasswright flagship is the G13 base made beautiful ("artistic, thoughtful in creation and looking to create beauty with function"); Hegemony H9 re-rendered in a realistic style. When it lands: look at every picture, send Ryan named pictures with an honest read.

**What this morning taught the Board (carry these into the rulebook).**
- Record the problem Ryan was reacting to, in his words, beside every rule. A bare "never X" gets built to the letter (R189).
- When Ryan likes a picture, the next job edits that picture. Never brief a liked design in words alone (R192).
- A number in a playbook is a starting point judged by eye in a moving fight, not a gate. Checks protect crashes, saves, comfort and frame rate.
- A rule that says the game does something needs a capture or a check that proves it, or the words "not built yet".
- Put the code name on every picture sent to Ryan; send pictures one per item, none taller than 720 px.
- Check the arithmetic yourself: the Board told Ryan the flash counter was "13 times" too strict; by viewing angle it is 5 to 7 (R193).

**Usage.** The Claude five-hour limit was hit at 11:25 CST with the Board and three Opus workers running; run two workers at most. Codex gives about 100 minutes of work per five-hour window. Muse is started by Ryan.

**Starter line for the new thread:** "You are the Board for rcbailey12/voidsworn. Read HANDOFF.md section 0, then contrib/opus/LOOP.md 'Current state', then FINDINGS from R183 on. Your first job is the rulebook, issue 492. Run a board check and tell me what needs my pick."

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
