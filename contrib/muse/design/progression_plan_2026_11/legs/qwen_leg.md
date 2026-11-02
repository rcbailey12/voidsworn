Headline
The plan builds the effect-pool cap first because every progression number downstream is meaningless if stacked effects can grow without limit, then immediately proves the whole tree system on one admiral (Saro of Long Focus, Glasswrights) so the owner can play a real level-up within two tasks. What the player feels change is the debrief: after a loss, the screen names what the next generation inherits—tree progress, core sync ticks, a new Nemesis weakness learned—instead of dumping two currency totals. The single biggest risk is the 360-text authorship budget for skills written in faction idiom; if those texts are not drafted before the tree UI is wired, the build stalls on content and the code sits untested.
The Player Loop on One Page
You pick an admiral. Each admiral is a style choice, not a purchase—every one is available from the start (R69 keeps the playtest switch on; the progression underneath is real but hidden until you say otherwise). You launch into a sector of hex encounters: fights, events, a mandatory Nemesis meeting once per sector. You will probably lose. Run 1 is designed to be near-impossible (R62). You lose, and that is the game working.
When the run ends, win or lose, you land on the debrief screen. It shows you what the next generation inherits: which tree level your admiral reached, what core sync ticked up, what weakness the Nemesis revealed (even on a loss, per Q5), what is now affordable in renown, and what story beat you unlocked. It names the inheritance in plain words. You are not staring at two numbers. You are reading a short obituary that doubles as a shopping list for the next attempt.
Between runs, five tracks carry forward:
Doctrine (renown track). You spend renown to respec skill lines or experiment with new picks. After run 15, renown becomes the experimentation currency with escalating respec pricing (Q14). New doctrine content is future content, not a currency fix.
Lineage (admiral XP track). Your admiral earns XP each run—about 43 for a win, 10 for a loss. Levels 1 through 4 are fixed perks. Levels 5 through 7 are tree picks: choose a branch, then one of two skills. Level 8 is a capstone. Benched admirals of the same faction earn shadow XP at 25 percent rate. Naming an heir doubles that shadow rate.
Core sync (the Lattice clock). Favour ticks mid-run when you pick protocols. Tier-ups land at 4, 12, and 25 protocols per core. All six cores are peers (R62). This track is a clock, not a spendable currency.
The Nemesis (the adaptation track). It learns what you do. It meets you once per sector, mandatory. If you lose the meeting, the debrief still teaches you a weakness it has (Q5). Its adaptations may not directly counter a weakness you have already revealed (Q4). You do not see its adaptation during the run; you see it at the debrief (R62).
Story (the beat track). Beat 3 core decisions, per-faction learning lines, and admiral spotlights land in phases. Finales come one at a time.
You start the next run because the debrief just showed you that your admiral is one fight away from a tree pick, that a new Nemesis weakness is loaded, and that the core sync is two protocols from a tier-up. The loss bought something visible. You run again to spend it.
Reconciled Design
Thread 1: The three loop repairs. Stack them in the chair's order—debrief screen first, Heat gate second, content third—but treat the Heat gate as a configuration flag, not a system rewrite. Rationale: R62 fixes the Heat payout (+2 XP to the flown admiral, +1 to the faction shadow pool), so un-gating Heat after the first loss changes timing, not amount. The debrief rebuild is the highest-leverage fix because all three legs agreed the loop leaks at run 4 and the debrief is where the player decides whether to run again. The gate is a one-line condition change. Content (new Nemesis behaviours, new sector conditions) is the most expensive and should land after telemetry confirms the first two held. Cost: the debrief rebuild touches the post-run summary screen and needs new data plumbing from the save; the gate is trivial; content is open-ended.
Thread 2: Mastery pooling. Per-admiral, full stop. The lineage fiction, the tree design, the heir mechanic, and the shadow-XP routing all assume per-admiral mastery. Argon's faction-pooling suggestion contradicts the ruled fiction (R62: "crews are the learners," Memory track option A) and the tree's per-admiral branch structure. Cost of this position: none additional; it is what the code already does. The faction-pool variant is dropped.
Thread 3: Elite and boss double-count in mastery XP. I take the position that it is an accident of the formula, not an intended weighting, because no ruling or design document justifies it, and it distorts every pacing trace in section 3 (run 5 reaches the first tree pick earlier than intended if elites are frequent). The fix is to remove the multiplier from the XP formula. Cost: all traces shift slightly later; the owner should re-check that run 5 still lands the first tree pick after the fix. I flag this as my inference—the pack says the double-count exists but does not show the formula line.
Thread 4: Dead admiral-shop schema. Schedule the cleanup. The direction is ruled: admirals are style choices, not purchases. The buy handlers at campaign_meta.js:143-144 become dead code; the locked-card text and the pointer to a nonexistent shop screen are removed. Replace locked-card text with the admiral's faction, Command name, and a one-line flavour line. The 885 renown sinks (635 LEGACY + 250 hull variants) remain as the economy's standing expenditure. Cost: small; it is deletion and text replacement.
Thread 5: Core sync's place. Core sync is a clock, not a spendable currency. It ticks, it gates tier-ups at 4/12/25 protocols, and it is reported at the debrief alongside lineage and doctrine. It is not spent, respec'd, or traded. Rationale: making it spendable would create a third currency competing with renown and XP for player attention, and R62's "all six cores are equal" argues against a mechanic that lets players prioritise one core's spend over another. Cost: the debrief must display sync progress per core, which is a UI addition but no new economy logic.
Thread 6: Playtest switch timing. The owner can first flip the R69 switch off after the Glasswrights test slice (build step 2) is playable end to end and the debrief rebuild (step 3) is live. At that point he would see: admirals still all selectable (style choices), the tree progressing from level 1, renown accruing, and the debrief naming inheritance. He would not yet see full Nemesis teaching or story beats. I do not recommend flipping it before step 5 (Nemesis verification) passes, because the teaching-on-loss path (Q5) is untested until then.
Additional contradictions found. None beyond section 4. The pack's file:line anchors (core.js:171, core.js:217, campaign_meta.js:143-144, campaign_run.js:293, nemNodeIs) are consistent with the descriptions given. I note that the pack says "885 renown sinks" but the arithmetic (635 + 250) checks out.
Build Order
Step 1: Effect pool cap at sumFx.
Files: core.js:171 (sumFx), core.js:217 (derive).
Adds: a configurable ceiling per effect type inside sumFx; effects that would exceed the cap clamp and log a warning to the console.
Test: stack six identical +10% damage effects and confirm the total does not exceed the configured cap.
Owner sees: nothing visible yet; the console log confirms the cap is active, and no existing run behaviour changes because current stacks are below the cap.
Step 2: Glasswrights test slice—Saro of Long Focus tree, playable end to end.
Files: new tree data file (Glasswrights_Saro.json or equivalent), the admiral XP handler, the post-run summary call site.
Adds: Saro's four fixed perks at levels 1–4, Branch A skills at levels 5–7, and the level 8 capstone, all authored from the worked tree document; the XP thresholds (6, 16, 30, 50, 75, 110, 160, 230 XP) wired to the existing admiral XP counter; a respec option between runs at 25 renown first cost, +10 per prior respec of that line.
Test: simulate 15 runs of mixed wins and losses for Saro, confirm levels unlock in order, confirm the tree pick at level 5 presents two Branch A options, confirm respec deducts renown correctly.
Owner sees: after enough runs, Saro's card shows a tree with a pick to make; choosing one skill locks the other; the debrief names the new level reached.
Step 3: Debrief rebuild—name the inheritance.
Files: the post-run summary screen (my inference: a summary component in the campaign UI layer; the pack does not give a file:line here), the save-write routine.
Adds: the debrief now displays, in order: (a) admiral XP gained and new level or progress toward next; (b) core sync ticks per core this run; (c) Nemesis weakness revealed or taught; (d) renown balance and what is now affordable; (e) story beat advanced, if any. Each line is one sentence in plain words.
Test: lose a run at sector 2 and confirm the debrief shows XP gained, sync ticks, a Nemesis weakness line, and renown total.
Owner sees: the end-of-run screen reads like a short letter from the next generation, not a receipt.
Step 4: Heat gate—un-gate after first loss.
Files: the Heat-award condition (my inference: near the run-end XP payout; the pack cites the +2/+1 rule from R63/Q13 but not the gate's file:line).
Adds: a boolean check—Heat XP is awarded only after the player has recorded at least one run loss in the save. Before that first loss, Heat is withheld.
Test: start a fresh save, win run 1 (if possible via debug), confirm no Heat XP; lose once, confirm the next run's Heat pays +2/+1.
Owner sees: run 1 feels identical; after the first death, the difficulty climb and the XP flow begin together.
Step 5: Nemesis clash-check verification (Q4).
Files: campaign_run.js:293 (nemAdapt).
Adds: a guard inside nemAdapt that reads the set of revealed weaknesses for the current successor and rejects any adaptation that directly counters one. If the current code already does this, the step is a test-only confirmation.
Test: reveal weakness X via a win, trigger the next adaptation roll, and confirm the result is never "counter X."
Owner sees: nothing new on screen; the Nemesis stops feeling cheap when it adapts around something you just learned.
Step 6: Nemesis teaching on loss (Q5) and debrief language (Q3).
Files: the debrief screen (touched in step 3), the nemNodeIs function in campaign_run.js, the Nemesis encounter UI text.
Adds: on a lost Nemesis meeting, the debrief displays one weakness the successor now knows; the encounter's intro text says the meeting is mandatory once per sector and the clock accelerates it, in fiction language.
Test: lose a Nemesis meeting and confirm the debrief shows a weakness line; confirm the encounter intro uses the mandatory-meeting language.
Owner sees: losing the hunter still teaches you something, and the game stops pretending you could skip the meeting.
Step 7: Dead-schema cleanup—admiral shop removal.
Files: campaign_meta.js:143-144 (buy handlers), the admiral card component, the locked-card text strings.
Adds: delete the buy handlers; remove the shop pointer from locked cards; replace locked-card text with "[Admiral name], [Faction], Command: [Command name]" and one flavour line. Confirm the R69 switch still governs visibility.
Test: boot a fresh save with the playtest switch off and confirm all 24 admiral cards are selectable with no purchase prompt.
Owner sees: the admiral roster is a clean grid of style choices; no lock icon, no shop arrow.
Step 8: Core sync display on debrief.
Files: the debrief screen (step 3 component), the save-read routine for protocol counts.
Adds: a per-core progress bar or fraction (e.g., "Astra: 7/12 protocols") on the debrief, visible only when sync ticked this run.
Test: pick four protocols for one core in a run and confirm the debrief shows "4/12—tier up."
Owner sees: the Lattice clock is no longer invisible; you can see which core is close to its next tier.
Step 9: Telemetry extension—Nemesis measurement (Q6).
Files: the F1 per-battle play log (campaign save), the Nemesis encounter handler.
Adds: log each Nemesis meeting's outcome (escape, loss, win), the adaptation chosen, and the compounding count; store in the campaign save alongside the existing battle log.
Test: play three sectors, confirm the save contains three Nemesis meeting records with outcome and adaptation fields.
Owner sees: nothing in-game; the owner reads a small exported log to judge escape and compounding rates before any cap tuning.
Step 10: Story beat 3—core decisions and learning lines, first faction.
Files: new story data file, the event-node display, the faction learning-line text table.
Adds: beat 3's core decision nodes for one faction (Glasswrights, to match the test slice), the learning-line texts in that faction's idiom, and one admiral spotlight. Reward labels hidden on event nodes per R62.
Test: reach beat 3 in a Glasswrights run and confirm the decision node appears, the choice persists to the save, and the learning line displays in faction idiom.
Owner sees: the world starts talking back in the faction's voice; a decision you make changes what the next run's events say.
Step 11: Escape-exit on haven and fight-start events (R62).
Files: the haven node component, the fight-start event component.
Adds: a visible "Leave" or "Walk away" button on every haven entry and every fight-start event, no cost, no penalty.
Test: enter a haven and a fight-start event; confirm the exit button is present and functional in both.
Owner sees: you are never trapped into a fight or a scene you did not choose to enter.
Step 12: Shadow XP and heir naming.
Files: the post-run XP distribution routine, the debrief screen.
Adds: benched admirals of the flown faction earn 25 percent of the flown admiral's XP as shadow XP; the debrief offers a "Name an heir" choice for one benched admiral per run; a named heir's shadow rate doubles.
Test: fly Saro for 10 XP, confirm a benched Glasswrights admiral gains 2.5 shadow XP; name an heir, confirm the next run grants 5.
Owner sees: the debrief asks "Who carries the line forward?" and the answer speeds that admiral's growth while they wait.
Art and Sound Needs
Step 2 (Glasswrights tree):
Tree-branch icon set for Branches A, B, C (3 icons, Glasswrights idiom: glass, lens, flame motifs).
Saro portrait, level-8 capstone variant.
Skill-node icon, locked-skill overlay, respec confirmation glyph.
Step 3 (Debrief rebuild):
Debrief screen layout: five labelled rows, inheritance-letter styling.
Small per-core sync pip or fraction bar (6 cores × 1 graphic).
Nemesis weakness-reveal icon (a cracked seal or opened eye).
Step 6 (Nemesis teaching/language):
Nemesis meeting intro card (one illustration, faction-neutral).
"Weakness learned" debrief stamp.
Step 7 (Schema cleanup):
24 admiral card portraits if not already present (confirm with existing assets).
Remove lock-icon and shop-arrow assets from the card template.
Step 8 (Core sync display):
Six core sigils at two states (below tier, at tier).
Step 10 (Story beat 3):
One faction event-node illustration (Glasswrights).
Decision-node frame with two/three choice slots.
Admiral spotlight portrait (Saro or chosen Glasswright).
Step 11 (Escape exit):
"Walk away" button icon, haven-exit glyph.
Sound (grouped by step):
Step 3: debrief sting, a short resolving chord.
Step 6: Nemesis meeting drone, weakness-reveal chime.
Step 10: faction event ambience loop (Glasswrights: glass-harmonica texture), decision-confirm tone.
Step 11: haven-exit soft cue.
Owner Questions
Q1. Elite and boss double-count in mastery XP.
The current formula counts elite and boss kills twice when calculating admiral XP. This makes levels come a little faster than the traces assume.
(a) Remove the double-count. Consequence: levels arrive slightly later; run 5 still reaches the first tree pick, but the margin is thinner. Recommended. Reason: no ruling justifies the weighting, and the traces were authored without it.
(b) Keep it. Consequence: progression stays a touch faster; the traces in the pack shift by roughly one run earlier at every threshold.
(c) Keep it for bosses only, remove it for elites. Consequence: boss fights feel extra rewarding; pacing sits between (a) and (b).
Q2. Core sync display style on the debrief.
(a) Show all six cores every debrief, even ones that did not tick. Consequence: the debrief is busier but the player always sees the full Lattice picture.
(b) Show only cores that ticked this run. Consequence: the debrief stays lean; cores that did not tick are invisible until they matter. Recommended. Reason: R62 says all cores are peers, but showing six static bars every run trains the player to ignore them.
(c) Show a single aggregate "Lattice progress" number. Consequence: simplest screen, but hides which core is close to a tier-up.
Q3. When to flip the R69 playtest switch off.
(a) After step 2 (Glasswrights tree playable). Consequence: you see the tree and XP working, but the debrief is still the old two-number version.
(b) After step 5 (Nemesis clash-check verified). Consequence: you see the full early loop—tree, debrief, Heat gate, Nemesis teaching—before progression is live. Recommended. Reason: flipping earlier means testing progression while the Nemesis path is unverified, which could produce confusing losses.
(c) After step 10 (first story beat). Consequence: the richest first-impression, but delays all progression testing by several build steps.
Q4. Faction for the second test slice after Glasswrights.
(a) Chorus (fleet-shaping focus, cheaper ships). Consequence: tests Branch B and the fleet-composition skills next; the player sees a very different tree feel. Recommended. Reason: Chorus is the mechanical opposite of Glasswrights, so it stress-tests the branch system widest.
(b) Eclipse (stronger, dearer ships). Consequence: tests Branch C numerics and the high-cost economy interaction.
(c) Let the data from Glasswrights playtesting decide. Consequence: no second slice is scheduled yet; the build order pauses after step 12 for a playtest review.
Not Checked
I did not read the actual code at core.js, campaign_meta.js, or campaign_run.js. All file:line references are taken from the pack. The debrief screen's file path, the Heat-gate condition's location, and the XP formula's exact line are my inferences; the coding agent must locate them.
The 25 percent shadow-XP rate is flagged in the pack as a tuning guess. I have used it as-is; no ruling confirms or adjusts it.
The worked Glasswrights tree for Saro of Long Focus is referenced as existing in a "phase 1 assembled trees document" that I have not read. I assume its Branch A skills and capstone are fully authored and ready to data-enter.
The "360 texts" authorship budget and the 192-text phase 1 scope are taken from the pack without verifying that the texts are written.
The F1 telemetry spec and the story pack's beat 3 content are referenced but not attached; I assume they exist in the form described.
The 885-renown-sink figure (635 + 250) is arithmetic from the pack; I did not audit the individual item prices.
Whether the current nemAdapt function already implements the Q4 clash check is explicitly unresolved in the pack; step 5 is written to handle both outcomes.
