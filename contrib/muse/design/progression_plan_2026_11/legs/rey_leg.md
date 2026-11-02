## 1. Headline

Build the cap first, then one faction's tree, then the screen that explains everything: close the uncapped effect pool at sumFx, prove the progression shape on the Glasswrights as a playable slice, then rebuild the debrief so every loss visibly buys the next run something. What the player feels change is that death stops being a wall and becomes a receipt: each run ends by naming what the next generation inherits. The single biggest risk is not code. It is authorship volume: 360 skill texts in six faction idioms, under rules that forbid filler, and the build order treats text as a deliverable, not end polish.

## 2. The player loop on one page

You pick an admiral and launch a run. Every admiral is available from the start: an admiral is a style choice, not a purchase. You also choose a Heat level, your own difficulty setting: harder runs pay more later.

A run is three sectors of fights, events, and choices, ending at a boss. Fights pay credits and sometimes salvage. Events offer trades and risks, and every fight-start event has a free exit, so you are never forced into a fight you did not choose (R62). After each boss comes the regroup: repair, upgrade, or buy ships; repair always beats scrapping one damaged hull (R63). Once per sector you meet the Nemesis, a hunter learning you; the meeting is mandatory, the clock can only bring it sooner.

Runs are meant to be lost. Winning your first run is near impossible, and that is the design, not a failure of it (R62). You will probably die three or four times before your first completion, around runs 4 to 5.

The debrief is the most important screen in the game. It shows what the Nemesis learned from you, which stays hidden during the run and is revealed only here (R62). Lose a Nemesis meeting and it still teaches you one of its weaknesses (Q5). Then it names your inheritance: what the next generation carries forward because this run happened. That inheritance has five parts.

Doctrine is your faction's written lessons, bought between runs with renown, the currency runs pay out: fleet-wide lessons and hull variants every future run starts with. Renown also pays for respec, priced higher the more a line is reworked (Q14).

Lineage is your admiral's line. The admiral you fly earns experience: about 43 for a winning run, 10 for a lost one, double weight for elite fights and bosses, plus 2 per point of Heat (R63). Early levels grant four fixed perks in order: an alternate starting fleet, wider counsel, a second Command option, a veteran flag captain. Past those, the line grows a tree. At each of three tree levels you pick a branch and take one of its two skills; the unchosen skill locks until you pay renown to respec between runs. Branches deepen your Command, shape your fleet, or strengthen your flagship and line. At the top sits a capstone, one of two evolutions of the Command, and experience past it keeps deepening that evolution. Benched admirals of your faction still earn shadow experience at a quarter rate, and naming an heir at the debrief doubles that line's shadow earnings. Crews are the learners (R62).

Core sync is your faction's attunement to the six Lattice cores. Protocols tied to a core tick its sync upward toward its next tier. All six cores are equal; none is a grand prize (R62). Sync is a clock, not a currency: you never spend it.

The Nemesis carries over too: its adaptations persist, but it may never adapt to directly counter a weakness you have revealed (Q4), and revealed weaknesses stay revealed.

Story carries over last. Each faction learns in its own idiom, and the fiction is that learning: each generation launches carrying the lessons, the trained crews, the deepened sync, the scars. Hegemony's version travels at courier speed, written and carried by hand (R62). Texts follow the idiom: the Crusade's inheritance never reads like the Glasswrights'.

Why start the next run? Because the debrief just told you what this death bought: a doctrine now affordable, a tree level one fight away, a core near its next tier, a Nemesis weakness learned, an heir already earning. The next run is not a retry. It is the next generation, starting richer than the last in named ways.

## 3. Reconciled design

**Thread 1, the three loop repairs.** Stack them in the chair's order: debrief screen first, Heat gate second, world-changing content third. The screen goes first: all three legs found the same leak, a death that does not visibly buy anything, and it is the cheapest fix that makes later systems legible. The gate goes second: un-gate Heat after the first loss, per DeepSeek, so the difficulty climb begins while the first win is still ahead. Un-gating changes who can earn the ruled Heat payout (R63, Q13), and when, not what Heat pays. Content goes last: it carries the largest authorship and code cost. Cost: runs 6 to 12 get a fixed screen and a ladder before they get a changing world.

**Thread 2, mastery pooling.** Per-admiral lineage wins; pooling per faction is rejected. R62 rules that crews are the learners (Memory track option A); the tree authors branches and capstones per admiral, and heir naming is a property of a line. Pooling would quietly rewrite all three. Cost: spreading play across many admirals grows each line slowly, mitigated by shadow XP (25 percent, doubled for a named heir's line).

**Thread 3, the mastery double-count.** Keep it, and write it down as intended. Elites and bosses teach the most, so the double weight is defensible, and every research trace (first pick at run 5, capstone around runs 14 to 15) already assumes it. Removing it would push the first tree pick to about run 6 or 7, breaking the R62 pacing story where the loop is known to leak. Cost: none in code. The risk, top-end lines levelling slightly fast, is absorbed by the capstone mastery thresholds (320, 440, 600 XP) and can be revisited on step 9 telemetry.

**Thread 4, the dead admiral shop.** Schedule the cleanup, not a shop. The direction is ruled: admirals are early style choices, not purchases. The build removes the purchase handlers at campaign_meta.js:143-144 and the unreachable toggle, and rewrites the locked card. The replacement text is a style line: name, home faction, and one plain sentence about how that admiral fights, with no lock and no price. Cost: none; the player loses nothing he could ever reach. The remaining renown sinks are the honest ones: 885 across LEGACY items and hull variants, plus respec.

**Thread 5, core sync's place.** Core sync is purely a clock, never spendable, and it belongs on the debrief. Making it spendable would create a second currency competing with renown and reopen economy questions R63 closed. Debrief-only folding wastes the mid-run favour ticks. So ticks stay visible in the run, tier-ups announce there, and the debrief reports sync as inheritance. Cost: one fewer sink, acceptable given renown's 885 sinks plus escalating respec pricing (Q14).

**Thread 6, the playtest switch.** The plan builds everything underneath the R69 switch, which stays on by default. The earliest meaningful flip is after the test slice and the debrief rebuild both pass: a Glasswrights run with doctrine unbought and picks on the ruled traces, five factions still on fixed-perk mastery. The safer flip point is after the full rollout and the pacing telemetry check. Nothing here recommends flipping it before the plan's own tests pass, per R69.

**Further flags.** One wording conflict needs settling before the respec step is built. The tree section prices respec per line: 25 renown for a line's first respec, +10 per prior respec of that line. Q14 describes the sink as escalating per-pick respec pricing. Those are different prices for the same act. This plan follows the per-line reading, because it carries actual numbers and because per-pick pricing taxes exactly the experimentation Q14 says renown exists to fund; it is also put to the owner below. A smaller tension, the regroup repair decision rarely binding, is a design smell, not a contradiction, and R63 accepts the economy as is. Nothing else in the pack contradicts the code anchors it cites or a ruling.

## 4. Build order

**Step 1. Cap the effect pool.** Files: core.js:171 (sumFx), core.js:217 (derive). Adds a per-kind ceiling inside sumFx, cap values in one data table, ending unlimited same-kind stacking everywhere derive() consumes it. Test: a fixture stacking one effect kind past its cap returns the capped total, and a fixture below the cap returns the uncapped total. Owner sees: nothing on screen; extreme stacked bonuses stop producing absurd combat log numbers.

**Step 2. Build the Glasswrights test slice.** Files: campaign_meta.js (mastery), the assembled phase 1 trees document as content source. Adds the tree machinery for the Glasswrights only (trunk 1 to 4 unchanged, branch picks at 5 to 7, capstone at 8), seeded by Saro of Long Focus's worked tree, playable end to end including between-runs respec. Test: a scripted line earns XP across simulated runs, picks a branch at level 5, locks the unchosen skill, and respecs at 25 renown. Owner sees: one faction with a real tree he can click through and reset, while the other factions still show fixed perks.

**Step 3. Rebuild the debrief as the inheritance screen.** Files: campaign_run.js (run end), the debrief screen. Adds an inheritance panel to the post-run summary: renown earned, tree progress on the flown line, shadow earnings on benched lines, what is now affordable. Test: finishing a run, win or loss, produces a debrief whose panel matches the profile state the run actually created. Owner sees: every run ending on a screen that tells him what that death or victory bought.

**Step 4. Make core sync visible at its payoff.** Files: campaign_run.js (summary), the protocol pick flow. Adds each core's sync progress and tier to the debrief inheritance panel, and makes tier-ups at 4, 12, and 25 protocols announce in the run. Test: a run that crosses a sync tier shows the tier-up in the run and the new tier on that run's debrief. Owner sees: the third progression clock finally reported where he decides whether to run again.

**Step 5. Verify the Nemesis clash check.** Files: campaign_run.js:293 (nemAdapt). Adds whatever is missing so no adaptation directly counters a revealed weakness (Q4), or proves by test that the shipped code already enforces it. Test: with a weakness revealed, many simulated adaptation rolls never produce the forbidden counter. Owner sees: nothing directly, except a Nemesis that never feels like it cheated his scouting.

**Step 6. Finish the Nemesis teaching loop.** Files: campaign_run.js (nemNodeIs, debrief). Adds the debrief weakness teaching on a lost meeting (Q5) and rewrites meeting fiction and UI language to own its mandatory once-per-sector status, clock as accelerant (Q3). Test: a lost meeting still adds one taught weakness to the debrief, and the sector map names the meeting as certain rather than chance. Owner sees: losing to the Nemesis still teaches him something, and the map stops pretending the meeting might not happen.

**Step 7. Clean up the dead admiral shop.** Files: campaign_meta.js:143-144 (purchase handlers), admiral card rendering. Removes the buy handlers and the unreachable shop toggle, and replaces locked-card text with the style line from section 3. Test: every admiral card renders with its style line, no card shows a lock or a price, and no code path references the removed handlers. Owner sees: an admiral select screen where every card reads as a style choice, nothing greyed out behind a shop that never existed.

**Step 8. Un-gate Heat after the first loss.** Files: campaign_meta.js (Heat availability), run setup screen. Adds Heat selection to run setup for any profile with at least one recorded loss, paying the ruled +2 XP per point to the flown admiral and +1 to the shadow pool (R63, Q13), with overflow past a cap flowing to the line's shadow XP. Test: a fresh profile sees no Heat control, a profile with one loss does, and payouts match the ruled amounts. Owner sees: a difficulty dial appear after his first death, offering harder fights that pay his admiral faster.

**Step 9. Extend telemetry for Nemesis rates and pacing.** Files: campaign_run.js, the F1 play log pipeline. Adds Nemesis escape and compounding counters (Q6) and per-run XP earnings by line to the campaign save, extending the F1 play log. Test: a simulated batch of runs produces a summary with escape rate, compounding rate, and median XP per run per line. Owner sees: nothing in the game; he gets numbers for tuning judgements before anyone touches a cap.

**Step 10. Author the story beat 3 pieces.** Files: the story pack content files. Adds beat 3's core decisions, the per-faction learning lines, and the admiral spotlights, leaving finales for later steps of their own, one at a time. Test: each learning line and spotlight renders in its screen with no placeholder text. Owner sees: debrief and faction screens speaking in each faction's own idiom instead of neutral system text.

**Step 11. Roll the tree out to the remaining factions.** Files: campaign_meta.js, per-faction tree content. Adds Branch A plus capstones for the other five factions (remaining phase 1 texts) and each faction's tier-1 B and C sets, on step 2's machinery. Test: one admiral per faction takes a branch pick and a capstone through the Glasswrights flow. Owner sees: every faction's admirals offering real choices, in their own words.

**Step 12. Add capstone mastery.** Files: campaign_meta.js (mastery). Adds the three mastery levels on a chosen capstone evolution at 320, 440, and 600 XP, so experience past 230 keeps deepening a favourite line. Test: a line at 320 XP on its evolution shows mastery level 1 and its effect, and XP below 230 cannot buy it. Owner sees: his most flown admiral still visibly growing past run 15 instead of topping out.

## 5. Art and sound needs

Grouped by build step; each line is one asset the plan requires in a new form.

Step 2 (test slice):
- A tree screen layout: trunk column, three branch columns, one node per skill tier.
- Three Glasswrights branch glyphs: Command, fleet, and flagship and line.
- A capstone node treatment distinct from ordinary nodes.
- Pick confirmation and locked states for skill nodes.
- Sound cue: a short confirmation tone when a tree pick is locked in.

Step 3 (debrief):
- An inheritance panel layout: one row per track (doctrine, lineage, core sync, Nemesis, story), showing a gained item or a progress amount.
- A small icon set for the five inheritance rows.
- Sound cue: a quiet closing sting for the debrief, distinct on a win and on a loss.

Step 4 (core sync):
- Six core icons, one per Lattice core, drawn as equals.
- A tier marker treatment showing sync progress without reading as a price or currency.

Step 6 (Nemesis teaching):
- A weakness icon set: one icon per Nemesis weakness kind.
- A taught-weakness debrief treatment, distinct from a weakness revealed by winning.

Step 8 (Heat):
- A Heat control for run setup: a stepped dial or pips reading as difficulty chosen, not suffered.

Step 10 (story):
- Spotlight art slots, one per admiral, sized for debrief and faction screens.

Step 12 (capstone mastery):
- A mastery marker layered on step 2's capstone node treatment.

## 6. Owner questions

**Question 1. When should the "Playtest: everything unlocked" switch first be turned off for a real test?**
Option A: After the Glasswrights slice and the new debrief pass their tests. You play one faction under real progression and five still unlocked: enough to judge the loop's feel.
Option B (recommended): After all six factions have trees and telemetry confirms pacing. You judge the whole game at once, with step 9 numbers already showing whether picks land on the ruled runs.
Option C: Leave it on until the story pieces land too. You judge progression and fiction together, at the cost of testing the loop itself last.
Recommended: B, because the loop is the thing being tested, and a one-faction test mostly tests the Glasswrights.

**Question 2. The respec price conflict: per line or per pick?**
Option A (recommended): Per line: 25 renown for a line's first respec, +10 each later time that line respecs. Trying many admirals stays cheap; repeatedly reworking one gets expensive.
Option B: Per pick, as Q14's wording suggests: each skill change inside a respec raises the price, so reworking a whole tree costs far more than touching one skill.
Recommended: A: renown is ruled the experimentation currency (Q14), and per-pick pricing taxes experimenting itself.

**Question 3. How fast should the first real choice arrive?**
Option A (recommended): Keep the ruled traces: the first tree pick lands around run 5, after three or four deaths. The fixed perks carry the early runs; the first choice arrives where the loop legs say attention is at risk.
Option B: Lower the tree thresholds so the first pick lands around run 3. Choices arrive sooner, but the trunk perks compress and lines top out earlier.
Option C: Raise them, first pick around run 7. Early runs stay simpler, at the cost of the exact stretch where the loop leaks.
Recommended: A: the traces were calculated against the ruled loss rate and leak point, and step 9 telemetry can reopen this with data.

**Question 4. Where should naming an heir live?**
Option A (recommended): On the debrief, offered whenever a run ends. Naming an heir doubles that benched line's shadow learning, and the debrief is where inheritance is named, so the choice sits with its consequences in view.
Option B: Only on a loss debrief: heir naming joins the death fiction, and a winning run offers no heir choice.
Option C: In the admiral select screen, as roster management: calmer, but separated from the run that earned it.
Recommended: A, because the debrief is the plan's centre of gravity, and a win should be able to name an heir too.

## 7. Not checked

I did not read the shipped code. Every file and line claim beyond the pack's anchors (core.js:171, core.js:217, campaign_meta.js:143-144, campaign_run.js:293, and the nemNodeIs function) is an inference from the pack's summaries, including which screens exist. I took the pack's numbers on trust: the XP payouts (about 43 for a win, 10 for a loss), the thresholds (6, 16, 30, 50, 75, 110, 160, 230, 320, 440, 600), the sync tiers (4, 12, 25 protocols), the 885 renown sinks, the 25 percent shadow rate (which the pack itself flags as a tuning guess), and the run traces. Whether nemAdapt already implements the clash check is unestablished in the pack; hence step 5 verifies rather than fixes. I did not verify that Saro's worked tree exists in the assembled document in the form step 2 assumes, nor which art and sound assets already exist; some section 5 items may already be on hand.
