# Job 7 synthesis: the progression plan, ready to build

Chair synthesis of four legs: DeepSeek, Qwen (Qwen3.8-Max, both model gates passed), Argon (Gemini Argon High, both gates passed), and a blind Rey leg. Legs are filed verbatim in the legs folder. Ryan rulings R62 and R63, plus Q3 to Q6, Q13 and Q14, override every leg and every earlier synthesis. Code anchors are the ones the chair verified for the pack: core.js:171 and core.js:217, campaign_meta.js:143 to 144, campaign_run.js:293, and the nemNodeIs function in campaign_run.js.

## Verdict

GO WITH CONDITIONS. The plan shape is settled and buildable: cap the effect pool first, prove the tree on one faction, then rebuild the debrief so every run visibly pays the next one. Three of four legs agree on that shape almost step for step. The conditions are the screening notes below: the Argon leg is screened out as a source, two DeepSeek details are corrected, and one real disagreement (the elite and boss double count) goes to Ryan as Question 1 with the chair pick marked.

## Screening notes

1. Argon leg: screened out, filed as a record only. It rebuilds the job around systems the pack never describes and rulings contradict. Examples: a gold currency for respec (the ruled price is renown); renown tiers that unlock admirals, Heat and story (admirals are ruled style choices, R62 direction, and the playtest switch is R69); Heat as levels 1 to 5 paying percentage bonuses (R63 rules a flat rate: plus 2 XP per Heat point to the flown admiral, plus 1 to the shadow pool); shadow XP as a spendable pool with a purchase penalty and a gold conversion (the ruled design is per admiral shadow earnings at 25 percent, with overflow past a cap routing into shadow XP, Q13); cores as attunement boons (core sync is a protocol clock with tier ups at 4, 12 and 25 protocols); a Nemesis rematch bought with renown (no such system exists); a respec ladder doubling to a 1000 cap (no such cap is ruled); file paths in a different project structure and language than this project uses; Saro skill names invented instead of taken from the worked tree; and a Phase 1 count that gives the Glasswrights five remaining admirals when the faction has four admirals in total. It also attributes several of these inventions to an owner preference the owner never stated. Nothing in the plan below relies on it. Its one usable instinct, that later content should change the world and not only the numbers, was already the third layer of the loop repair in the pack and is kept on that basis, not on Argon's.

2. DeepSeek leg: sound in shape, three details corrected. First, its respec step prices the increase per additional line with a 75 renown cap; the ruled pricing is 25 renown for a line's first respec plus 10 per prior respec of that same line, with no cap stated. Second, its Nemesis step says an adaptation may only fire on a clash; Q4 says the opposite shape: an adaptation may not directly counter a weakness the player has already revealed. Third, its loop page says a win or intel event removes a weakness; the ruled system is that wins, intel events and triggering a weakness in battle reveal weaknesses, and a lost meeting still teaches one (Q5). Its build order also splits the Saro slice down to Branch A and the capstone only; the slice in the plan below is the full tree machinery, because a slice that cannot show a branch pick locking its alternative does not prove the tree.

3. Qwen leg: sound in shape, one position not adopted and one step demoted. Its position that the elite and boss double count is an accident to remove is a genuine reading, and it is the minority one: DeepSeek and the Rey leg both keep it. The chair pick is to keep it for now and put the decision to Ryan (Question 1), because removing it changes every pacing trace the plan is built on and pushes the first tree pick later, into exactly the stretch where the loop is known to leak. Its free exit step is kept, but as a verification step, since R62 rules the free exit and the pack does not establish whether the shipped code already has it.

4. Rey leg (blind): adopted as the spine of this synthesis. It is the only leg that caught the respec wording conflict between the tree proposal (per line pricing with numbers) and Q14 (escalating per pick wording). That conflict is real, the plan follows the per line reading, and it goes to Ryan as Question 2.

## 1. The player loop on one page

You pick an admiral and launch a run. Every admiral is available from the start: an admiral is a style choice, not a purchase. After your first loss you can also choose Heat, your own difficulty setting: harder runs pay more later.

A run is three sectors of fights, events and choices, ending at a boss. Fights pay credits and sometimes salvage. Events offer trades and risks, and every fight start event has a free exit, so you are never forced into a fight you did not choose (R62). After each boss comes the regroup: repair, upgrade, or buy ships; repair always beats scrapping one damaged hull (R63). Once per sector you meet the Nemesis, a hunter who is learning you; the meeting is mandatory, and the sector clock can only bring it sooner (Q3).

Runs are meant to be lost. Winning your first run is near impossible, and that is the design, not a failure of it (R62). You will probably die three or four times before your first completion, around runs 4 to 5.

The debrief is the most important screen in the game. It shows what the Nemesis learned from you, which stays hidden during the run and is revealed only here (R62). Lose a Nemesis meeting and it still teaches you one of its weaknesses (Q5). Then the debrief names your inheritance: what the next generation carries forward because this run happened. That inheritance has five parts.

Doctrine is your faction's written lessons, bought between runs with renown, the currency runs pay out: fleet wide lessons and hull variants every future run starts with. Renown also pays for respec, priced higher the more one line is reworked (Q14).

Lineage is your admiral's line. The admiral you fly earns experience: about 43 for a winning run, 10 for a lost one, double weight for elite fights and bosses, plus 2 per point of Heat paid to the flown admiral and 1 per point to the shadow pool (R63, Q13). Early levels grant four fixed perks in order: an alternate starting fleet, wider counsel, a second Command option, a veteran flag captain. Past those, the line grows a tree. At each of three tree levels you pick a branch and take one of its two skills; the unchosen skill locks until you pay renown to respec between runs. Branches deepen your Command, shape your fleet, or strengthen your flagship and line. At the top sits a capstone, one of two evolutions of the Command, and experience past it keeps deepening that evolution through three mastery levels. Benched admirals of your faction still earn shadow experience at a quarter rate, and naming an heir at the debrief doubles that line's shadow earnings. Crews are the learners (R62).

Core sync is your faction's attunement to the six Lattice cores. Protocols tied to a core tick its sync upward toward its next tier, at 4, 12 and 25 protocols. All six cores are equal; none is a grand prize (R62). Sync is a clock, not a currency: you never spend it.

The Nemesis carries over too: its adaptations persist, but it may never adapt to directly counter a weakness you have revealed (Q4), and revealed weaknesses stay revealed.

Story carries over last. Each faction learns in its own idiom, and the fiction is that learning: each generation launches carrying the lessons, the trained crews, the deepened sync, the scars. Hegemony's version travels at courier speed, written and carried by hand (R62). The Crusade's inheritance never reads like the Glasswrights'.

Why start the next run? Because the debrief just told you what this death bought: a doctrine now affordable, a tree level one fight away, a core near its next tier, a Nemesis weakness learned, an heir already earning. The next run is not a retry. It is the next generation, starting richer than the last in named ways.

## 2. Reconciled design

Thread 1, the three loop repairs. Chair pick: stack them, in the order screen, gate, content. All three research legs found the same leak, a death that does not visibly buy anything, and the debrief is the cheapest fix that makes every later system legible. The Heat gate goes second: un-gating Heat after the first loss starts the difficulty climb while the first win is still ahead, and it changes who can earn the ruled Heat payout and when, not what Heat pays. Content that changes the world goes last because it carries the largest authorship and code cost. Cost: runs in the middle of the campaign get a fixed screen and a difficulty ladder before they get a changing world.

Thread 2, mastery pooling. Chair pick: per admiral lineage wins; pooling per faction is rejected. R62 rules that crews are the learners; the tree authors branches and capstones per admiral; heir naming is a property of a line. Pooling would quietly rewrite all three. Cost: spreading play across many admirals grows each line slowly, softened by shadow XP at 25 percent, doubled for a named heir's line. The 25 percent rate is a flagged tuning guess and telemetry (Step 11) is the check on it.

Thread 3, the elite and boss double count. Chair pick: keep it, write it down as intended, and confirm with Ryan (Question 1). Elites and bosses are the fights that should teach the most, every pacing trace in the research (first tree pick at run 5, capstone around runs 14 to 15) was calculated with the shipped formula as it stands, and removing the weighting pushes the first real choice to about run 6 or 7, past the stretch where the loop leaks. Cost: top end lines level slightly fast, absorbed by the capstone mastery thresholds at 320, 440 and 600 XP. If Ryan picks removal, it is one small formula task plus fresh traces, and it must land before Step 13 rollout, not after.

Thread 4, the dead admiral shop. Chair pick: schedule the cleanup, not a shop. The direction is ruled: admirals are style choices, not purchases. The build removes the purchase handlers at campaign_meta.js:143 to 144 and the unreachable toggle, and replaces the locked card. The replacement text is a style line: the admiral's name, home faction, Command name, and one plain sentence about how that admiral fights. No lock, no price. Cost: none to the player; he loses nothing he could ever reach. The honest renown sinks that remain are 885 across LEGACY doctrine items and hull variants, plus respec.

Thread 5, core sync's place. Chair pick: core sync is purely a clock, never spendable, visible in the run and reported on the debrief. Making it spendable would create a second currency competing with renown and reopen economy questions R63 closed. Debrief only reporting would waste the mid run ticks. So ticks stay visible in the run, tier ups announce there, and the debrief reports sync as inheritance, showing the cores that ticked this run (Question 4 covers the display choice). Cost: one fewer sink, acceptable against 885 renown sinks plus escalating respec.

Thread 6, the playtest switch. Chair pick: everything in this plan builds underneath the R69 switch, which stays on by default. The earliest meaningful flip is after Step 2 and Step 4 pass: one faction under real progression with a debrief that explains it. The recommended flip is after Step 13 and the Step 11 telemetry check: all six factions have trees, and the pacing numbers exist before Ryan judges the loop. Nothing in this plan flips the switch; R69 says it stays on until Ryan says progression is ready to test.

Further flags. One wording conflict needs Ryan's word before the respec part of Step 2 is built: the tree proposal prices respec per line (25 renown, plus 10 per prior respec of that line), while Q14 describes escalating per pick pricing. This plan follows the per line reading because it carries actual numbers and because per pick pricing taxes exactly the experimentation Q14 says renown exists to fund. It is Question 2 below. One design smell, not a contradiction: the regroup repair decision rarely binds, because free healing shrinks the paid decision; R63 accepts the economy as is, so the plan does not touch it. Nothing else in the legs or the pack contradicts the verified code anchors or a ruling, beyond the Argon material screened above.

## 3. Build order

Each step is sized as one task for the coding agent. Steps that join two systems were split, per the brief.

Step 1. Cap the effect pool. Files: core.js:171 (sumFx), core.js:217 (derive). Adds a per kind ceiling inside sumFx, with cap values in one data table, ending unlimited same kind stacking everywhere derive consumes it: relics, admiral effects, protocol effects, module and perk effects. Test: a fixture stacking one effect kind past its cap returns the capped total, and a fixture below the cap returns the uncapped total. Ryan sees: nothing on screen; extreme stacked bonuses stop producing absurd combat numbers.

Step 2. Build the Glasswrights test slice. Files: campaign_meta.js (mastery and respec), the phase 1 assembled trees document as the content source. Adds the full tree machinery for the Glasswrights only, seeded by Saro of Long Focus's worked tree: trunk levels 1 to 4 unchanged, branch picks at levels 5 to 7 with the unchosen skill locking, a capstone choice at level 8, and between runs respec at the per line price. Test: a scripted line earns XP across simulated runs, picks a branch at level 5, sees the unchosen skill locked, and respecs at 25 renown. Ryan sees: one faction with a real tree he can click through and reset, while the other factions still show fixed perks.

Step 3. Wire shadow XP and heir naming. Files: campaign_meta.js (mastery earnings), the debrief heir choice. Adds shadow earnings at 25 percent for benched admirals of the flown faction, heir naming as a debrief choice, double shadow rate for a named heir's line, and Q13 overflow routing so XP past any cap flows into shadow XP instead of vanishing. Test: flying one admiral through a paid run credits a benched same faction admiral at a quarter rate, and at double rate after that admiral is named heir. Ryan sees: his benched admirals quietly growing, and a reason to care which one he names.

Step 4. Rebuild the debrief as the inheritance screen. Files: campaign_run.js (run end), the debrief screen. Adds an inheritance panel to the post run summary: renown earned, what is now affordable, tree progress on the flown line, shadow earnings on benched lines, and the Nemesis lesson from Step 7 when it lands. Test: finishing a run, win or loss, produces a debrief whose panel matches the profile state the run actually created. Ryan sees: every run ending on a screen that tells him what that death or victory bought.

Step 5. Make core sync visible at its payoff. Files: campaign_run.js (run summary), the protocol pick flow. Adds each core's sync progress to the debrief inheritance panel, limited to cores that ticked this run, and makes tier ups at 4, 12 and 25 protocols announce in the run. Test: a run that crosses a sync tier shows the tier up in the run and the new tier on that run's debrief. Ryan sees: the third progression clock finally reported where he decides whether to run again.

Step 6. Verify the Nemesis clash check. Files: campaign_run.js:293 (nemAdapt). Adds whatever is missing so no adaptation directly counters a revealed weakness (Q4), or proves by test that the shipped code already enforces it. Test: with a weakness revealed, many simulated adaptation rolls never produce the forbidden counter. Ryan sees: nothing directly, except a Nemesis that never feels like it cheated his scouting.

Step 7. Finish the Nemesis teaching loop. Files: campaign_run.js (nemNodeIs, run end debrief data), the sector map and meeting text. Adds the debrief weakness teaching on a lost meeting (Q5), and rewrites meeting fiction and UI language to own the mandatory once per sector status, with the clock as accelerant only (Q3). Test: a lost meeting still adds one taught weakness to the debrief, and the sector map names the meeting as certain rather than chance. Ryan sees: losing to the Nemesis still teaches him something, and the map stops pretending the meeting might not happen.

Step 8. Verify the free exits. Files: the haven flow and the fight start event flow in campaign_run.js. Adds a free exit to any haven or fight start event that lacks one, per R62, or proves by test that both already have it. Test: entering a haven and a fight start event both offer a no cost exit that returns to the sector map. Ryan sees: he is never trapped into a fight or a scene he did not choose.

Step 9. Clean up the dead admiral shop. Files: campaign_meta.js:143 to 144 (purchase handlers), the admiral card rendering. Removes the buy handlers and the unreachable shop toggle, and replaces the locked card text with the style line from Thread 4. Test: every admiral card renders with its style line, no card shows a lock or a price, and no code path references the removed handlers. Ryan sees: an admiral select screen where every card reads as a style choice, nothing greyed out behind a shop that never existed.

Step 10. Un-gate Heat after the first loss. Files: campaign_meta.js (Heat availability), the run setup screen. Adds Heat selection to run setup for any profile with at least one recorded loss, paying the ruled rate of plus 2 XP per Heat point to the flown admiral and plus 1 to the shadow pool (R63, Q13). Test: a fresh profile sees no Heat control, a profile with one loss does, and payouts match the ruled amounts. Ryan sees: a difficulty dial appear after his first death, offering harder fights that pay his admiral faster.

Step 11. Extend telemetry for Nemesis rates and pacing. Files: campaign_run.js, the F1 play log pipeline. Adds Nemesis escape and compounding counters (Q6) and per run XP earnings by line to the campaign save, extending the existing per battle play log. Test: a simulated batch of runs produces a summary with an escape rate, a compounding rate, and median XP per run per line. Ryan sees: nothing in the game; he gets numbers for tuning judgements before anyone touches a cap.

Step 12. Author the story beat 3 pieces. Files: the story pack content files. Adds beat 3's core decisions, the per faction learning lines, and the admiral spotlights, leaving finales for later steps of their own, one at a time. Test: each learning line and spotlight renders in its screen with no placeholder text. Ryan sees: debrief and faction screens speaking in each faction's own idiom instead of neutral system text.

Step 13. Roll the tree out to the remaining factions. Files: campaign_meta.js, per faction tree content. Adds Branch A plus capstones for the other five factions (the remaining phase 1 texts) and each faction's tier 1 Branch B and Branch C sets, on Step 2's machinery. Test: one admiral per faction takes a branch pick and a capstone through the same flow the Glasswrights slice proved. Ryan sees: every faction's admirals offering real choices, in their own words.

Step 14. Add capstone mastery. Files: campaign_meta.js (mastery). Adds the three mastery levels on a chosen capstone evolution at 320, 440 and 600 XP, so experience past 230 keeps deepening a favourite line. Test: a line at 320 XP on its evolution shows mastery level 1 and its effect, and XP below 230 cannot buy it. Ryan sees: his most flown admiral still visibly growing past run 15 instead of topping out.

Authorship note, not a step: the tree texts are the long pole. The full budget is 360 texts (288 unique plus 72 shared set), Phase 1 is 192 Branch A and capstone texts plus 24 faction tier 1 texts. Step 2 needs only the Glasswrights share drafted; Step 13 cannot start until the other factions' Phase 1 texts exist. Drafting should run ahead of the code steps, in parallel, or Step 13 stalls on writing rather than building.

## 4. Art and sound needs

Grouped by build step. Each line is one asset or element the plan requires in a new form; what already exists was not audited, so treat this as a needs list, not a gap list.

Step 2 (test slice):
- A tree screen layout: trunk column, three branch columns, one node per skill tier.
- Three Glasswrights branch glyphs: Command, fleet, flagship and line.
- A capstone node treatment distinct from ordinary nodes.
- Locked and available states for skill nodes, plus a pick confirmation state.
- Sound: a short confirmation tone when a tree pick locks in.

Step 3 (shadow XP and heirs):
- A small shadow earnings marker for benched admiral cards.
- An heir marker that can sit on an admiral card and on the debrief.

Step 4 (debrief):
- An inheritance panel layout: one row per track (doctrine, lineage, core sync, Nemesis, story).
- A small icon set for the five inheritance rows.
- Sound: a quiet closing sting for the debrief, in a win version and a loss version.

Step 5 (core sync):
- Six core icons, one per Lattice core, drawn as equals.
- A tier marker treatment that reads as progress, never as a price.

Step 7 (Nemesis teaching):
- A weakness icon set: one icon per Nemesis weakness kind.
- A taught weakness treatment on the debrief, distinct from a weakness revealed by winning.
- Sound: a short weakness learned cue, distinct from the win reveal cue if one exists.

Step 10 (Heat):
- A Heat control for run setup: stepped pips or a dial that reads as difficulty chosen, not suffered.

Step 12 (story):
- Spotlight art slots, one per admiral, sized for debrief and faction screens.

Step 14 (capstone mastery):
- A mastery marker layered on Step 2's capstone node treatment.

No new portraits are required by this plan beyond the Step 12 spotlight slots; admiral portraits are covered by the portrait workstream.

## 5. Owner questions

Question 1. Should elite fights and bosses keep paying double experience toward admiral levels?
Option A (chair pick): Keep the double weight. Hard fights teach the most, the first tree pick stays at about run 5 where the loop needs it, and every pacing trace already assumes it.
Option B: Remove it. Levels arrive more evenly, but the first real tree choice moves to about run 6 or 7, past the stretch where players drift away, and all the pacing traces need redoing.
Option C: Keep it for bosses only. A middle pace, and boss fights stay special, at the cost of one more rule to explain.

Question 2. How should respec be priced: per line or per pick?
Option A (chair pick): Per line: 25 renown the first time a line is respecced, plus 10 each later time that same line is respecced. Trying many admirals stays cheap; reworking one line over and over gets expensive.
Option B: Per pick: every skill changed inside a respec raises the price, so reworking a whole tree costs far more than touching one skill. This matches one phrase in Q14, but it taxes experimenting itself, and renown is ruled to be the experimentation currency.

Question 3. When should the "Playtest: everything unlocked" switch first be turned off for a real test?
Option A: After the Glasswrights slice and the new debrief pass (Steps 2 and 4). You play one faction under real progression and five still unlocked: enough to judge whether a death feels like it bought something.
Option B (chair pick): After all six factions have trees and the telemetry check passes (Steps 11 and 13). You judge the whole game at once, with pacing numbers already showing whether picks land on the planned runs.
Option C: Leave it on until the story pieces land too (Step 12 and beyond). You judge progression and fiction together, at the cost of testing the loop itself last.

Question 4. What should the debrief show for core sync?
Option A (chair pick): Only the cores that ticked this run. The panel stays short, and a core appears exactly when it moved, with its distance to the next tier.
Option B: All six cores every time. You always see the full picture, at the cost of a busier screen and six mostly unchanged lines per run.
Option C: One combined Lattice progress number. Simplest screen, but you cannot see which core is close to a tier up, which is the useful part.

Question 5. Where should naming an heir live?
Option A (chair pick): On the debrief, offered whenever a run ends, win or loss. Naming an heir doubles that benched line's shadow learning, and the debrief is where inheritance is named, so the choice sits next to its consequences.
Option B: Only on a loss debrief. Heir naming joins the death fiction, and a winning run offers no heir choice.
Option C: On the admiral select screen, as roster housekeeping. Calmer, but separated from the run that earned it.

## Owner rulings (Ryan, Nov 2, 2026)

Ryan agreed with the chair picks on all five owner questions. These are now rulings and govern the build:

1. Elite and boss double count: KEPT. The double weight is intended weighting, locked with a test; the pacing traces stand.
2. Respec pricing: PER LINE. 25 renown for a line's first respec, plus 10 per prior respec of that same line. This settles the conflict with Q14's per pick wording in favour of the per line reading; Q14's standing point, that renown is the respec and experimentation currency, is unchanged.
3. Playtest switch: the first flip off comes after all six factions have trees and the telemetry pacing check passes (Steps 11 and 13), not after the Glasswrights slice alone.
4. Core sync on the debrief: only the cores that ticked this run are shown.
5. Heir naming: on the debrief, offered whenever a run ends, win or loss.

## Not checked

The chair did not re-read every source synthesis behind the pack for this job; the pack's chair verified summaries, the governing rulings in FINDINGS (R62, R63, and the Q items as carried in the pack), and the code anchors named above are the basis. Whether nemAdapt already implements the Q4 clash check, and whether havens and fight start events already carry free exits, are deliberately left as verification steps (Steps 6 and 8) rather than asserted. Cap values for Step 1 do not exist yet in any source the chair read; setting them is part of that step's task, and the plan takes no position on the numbers. The 25 percent shadow rate remains a flagged tuning guess. Art and sound needs are requirements, not an audit of assets already on hand.
