# Leg: Qwen (Qwen3.8-Max), issue 2060

Gate record: New Chat, selector set to Qwen3.8-Max and verified showing Qwen3.8-Max before pasting (it had opened on Qwen3.7-Plus) and the header still showed Qwen3.8-Max after generation. Brief pasted as plain text, no file attached. Single response (not comparison mode). No limit notice. Chat: "Faction Command Sets Design", https://chat.qwen.ai/c/c8797da4-8e08-4465-a545-efbb0e5442e9
Chair note on the pack: the copy of the brief pasted into this leg's chat carried a garbled Ashfall admiral line with an inline correction (the correct four names, Grax, Sable, Mott, Vesh, were stated in the same sentence). The leg's Ashfall set uses the correct admirals, so the chair treats the leg as valid and records the deviation here.

Response verbatim:

Leg Brief Response: Faction Command Sets, Deployment, and Called Shots

Question 1: Faction Command Sets

Structural choice: four distinct commands per faction, each anchored to one of the six existing template slots

I recommend keeping the current structure of four admirals per faction, each holding one command, rather than collapsing to a single signature command with four variants. Three reasons. First, each admiral already carries a unique rider, so the command-plus-rider pair is the real unit of identity; four distinct commands give four distinct pairs, and four variants of one command would flatten that. Second, the once-per-battle charge-and-hold mechanic means the player only ever fires one command per battle, so variety across the roster matters more than depth within one command. Third, balance is easier to audit when each command maps to a known template budget. Every command below is anchored to the template it replaces. Where I add a small faction-specific bonus, it is conditional on that faction's battle rule, so it is worth roughly the same as the base template for this faction without being strictly better in a mirror or crossover test.

All tier shapes below use three tiers. Where I do not describe a tier change, the command inherits the base template's tier curve unchanged. Numbers are tuning starting points.

1. Sunward Crusade. Theme: "The line fires as one and does not break."

Vex: Broadside Consecration (barrage slot).
Free volley as base barrage. Bonus: any side-gun shot in the volley that came from a ship that moved at least 2 hexes this round gains +20% damage, matching the Line of Battle condition the faction already tracks. Tier shape: T1 free volley only. T2 adds the movement-conditional +20%. T3 also extends side-gun range by 1 hex for the volley. Reuses the barrage engine call and the existing Line of Battle movement check. No new rule.

Malek: Lance Purge (hunt slot).
Torpedoes reload, +30% damage as base hunt. Bonus: each lance weapon also fires one free shot at its current target this round. Tier shape: T1 reload and damage buff. T2 adds the lance free shot. T3 lance shots ignore 20% of target armor. Reuses the hunt reload and damage-buff systems. The lance free shot reuses the existing lance fire routine with a free-fire trigger flag. No new rule, just a new trigger.

Ashgrove: Wing Screen (scramble slot).
Extra wing launched if there is room, squadrons strike again at +50% as base scramble. Bonus: this round, each squadron in the air grants its parent ship 15% less incoming damage (interceptor screen). Tier shape: T1 extra wing. T2 squadron re-strike at +50%. T3 adds the 15% damage reduction to parent ships. Reuses scramble. The parent-ship damage reduction from squadrons is a small new rule: the engine needs a squadron-tagged aura that feeds into the damage-reduction calculation. Flag: new rule, small scope. One boolean per squadron (screening yes/no) feeding one multiplier in the damage pipeline.

Thale: Iron Litany (iron slot).
All shields refill, 40% less hull damage as base iron. Bonus: this round, Brace covers two adjacent allies facing the same way instead of one. Tier shape: T1 shield refill. T2 the 40% damage reduction. T3 Brace extends to two adjacent allies. Reuses iron and the existing Brace adjacency check; the count changes from 1 to 2 for the round. No new rule, just a parameter change.

Balance argument. Broadside Consecration is barrage plus a bonus the faction is already built to trigger, so it is worth the same as barrage for Sunward without being worth more for anyone else. Lance Purge adds one free lance shot to hunt, roughly a 10-15% value bump that is offset by Sunward's slower speed making the lance window narrower. Wing Screen trades a small amount of scramble's raw damage for a defensive layer, netting out. Iron Litany adds one extra Brace target at T3, a minor bump. Total set value sits within the current template budget.

Least-sure decision. Whether the Wing Screen damage reduction should be 15% or 10%. At 15% it starts to overlap with iron's 40% in feel, and a player might stack both in the same round by using Wing Screen on a turn they also Brace.

Biggest risk. Broadside Consecration at T3 with +1 range could let Sunward volley from outside the hex range where most factions can answer, creating a standoff that feels bad to play against. Watch the range number carefully.

2. Meridian Directorate. Theme: "The link makes every gun a battery."

Kassar: Sync Volley (barrage slot).
Free volley as base barrage. Bonus: ships within 3 hexes of the command ship apply the existing Synchronized fire bonus (aim and damage) to their volley shots. Tier shape: T1 free volley. T2 sync bonus applies to volley. T3 synced ships also get +10% crit on volley shots. Reuses barrage and the existing sync range and bonus checks. No new rule.

Vorn: Ion Cascade (hunt slot).
Torpedoes reload, +30% damage as base hunt. Bonus: ion weapons this round strip 50% more shield than normal. Tier shape: T1 reload and damage. T2 ion strip bonus. T3 the ion strip bonus also carries into the next round. Reuses hunt and the existing ion shield-strip mechanic. No new rule.

Reyes: Drone Bloom (scramble slot).
Extra wing, squadrons re-strike at +50% as base scramble. Bonus: drone-type squadrons apply a 10% accuracy debuff to their target this round. Tier shape: T1 extra wing. T2 re-strike at +50%. T3 drone debuff. Reuses scramble. The squadron-applied accuracy debuff is a small new rule: a per-target accuracy modifier sourced from a squadron hit. Flag: new rule, small scope. One debuff field on the target, cleared at round end.

Maren: Sync Shield (iron slot).
All shields refill, 40% less hull damage as base iron. Bonus: if the command ship is alive, ships within 3 hexes of it take an additional 10% less hull damage (total 50%). If the command ship is destroyed, the bonus falls away and the command reverts to standard iron. Tier shape: T1 shield refill. T2 the 40% reduction. T3 the extra 10% for synced ships. Reuses iron and the existing sync range check. No new rule, but the conditional fallback (command ship dead, bonus gone) needs a simple alive-check gate.

Balance argument. Sync Volley is barrage gated by a condition the faction already plays around. Ion Cascade adds a small shield-strip rider to hunt, relevant mainly against shielded opponents and roughly equivalent to the base damage buff. Drone Bloom's 10% accuracy debuff is minor and single-target. Sync Shield's extra 10% is conditional on the command ship surviving, which is the faction's existing tension point; losing the command ship already strips sync, so this does not add new fragility. Total set value matches the current templates.

Least-sure decision. Whether the Drone Bloom accuracy debuff should be 10% or 5%. At 10% it is noticeable in a single round; at 5% it might feel pointless.

Biggest risk. Sync Volley at T3 with +10% crit on top of sync aim and damage could spike burst damage in a way that makes Meridian feel like a one-shot faction. The crit number needs playtest.

3. Ashfall Hullbreakers. Theme: "Close the gap before they can breathe."

Grax: Rush (surge slot).
+2 movement, +1 turn, enemy fire loses 20 accuracy as base surge. Bonus: boarding attempts this round get +25% crew strength. Tier shape: T1 surge. T2 boarding bonus. T3 a successful boarding also deals 5% hull damage to the target. Reuses surge and the existing boarding resolution. No new rule; the boarding modifier is a one-round stat change.

Sable: Rocket Storm (hunt slot).
Rocket pods reload (using the torpedo reload system), +30% damage as base hunt. Bonus: rocket salvos this round cannot be thinned by point defense. Tier shape: T1 reload and damage. T2 PD immunity for rockets. T3 rockets also get +1 hex range. Reuses hunt. The PD bypass reuses the existing point-defense thinning step with a skip flag for the round. No new rule.

Mott: Swarm Dive (scramble slot).
Extra wing, squadrons re-strike at +50% as base scramble. Bonus: fighter squadrons this round gain +2 hexes of movement before their strike run. Tier shape: T1 extra wing. T2 re-strike at +50% and +1 squadron move. T3 +2 squadron move. Reuses scramble. Squadron movement before striking needs a move phase in the squadron resolution order. If squadrons currently move only as part of deployment or repositioning, this is a small new rule. Flag: possibly new rule depending on whether the squadron system already has a pre-strike move step. If it does, just extend the range. If not, add one.

Vesh: Patch and Burn (restore slot).
25% hull repair, patch damaged sections as base restore. Bonus: this round all Ashfall weapons get +10% damage, flavored as repair energy vented into gun capacitors. Tier shape: T1 repair. T2 patch sections and +10% damage. T3 repair rises to 30% and damage bonus to 15%. Reuses restore and the existing global damage modifier. No new rule.

Balance argument. Rush is surge with a boarding rider that only pays off if Ashfall ships are already adjacent, which is the faction's whole plan anyway. Rocket Storm removes PD thinning, which is strong for Ashfall since they cannot field lances and rockets are their primary ranged tool; the value is roughly equal to the base hunt damage buff because PD was already shaving a fixed percentage. Swarm Dive's extra squadron movement is a small range extension. Patch and Burn trades a little repair value for a small damage window. The set stays within budget.

Least-sure decision. Whether Swarm Dive's squadron move should be +1 or +2 at T2. At +2 it lets Ashfall fighters cross the board in one turn, which might trivialize range.

Biggest risk. Rocket Storm's PD immunity at T2 combined with the +30% damage at T1 means Ashfall's main damage source gets two multiplicative boosts in one round. If rocket base damage is already high, this spike could overshoot the balance window.

4. The Chorus. Theme: "Every wound feeds the swarm; every kill feeds the ship."

The Chorus has no shields, so no shield-based command appears in this set. The four template slots used are scramble, surge, restore, and barrage, matching the current admiral assignments.

Matriarch: Spore Burst (scramble slot).
Extra wing (spore swarm), squadrons re-strike at +50% as base scramble. Bonus: any squadron kill this round triggers the existing Feed rule for the killer ship, causing hull regrowth. Tier shape: T1 extra wing. T2 re-strike at +50% and Feed on squadron kill. T3 Feed on squadron kill heals 50% more than the base Feed value. Reuses scramble and the existing Feed trigger. No new rule; the Feed system already fires on kills, this just extends the trigger to squadron kills if it does not already.

Razormaw: Predator Lunge (surge slot).
+2 movement, +1 turn, enemy -20 accuracy as base surge. Bonus: this round, any Chorus ship that destroys an enemy ship regrows 10% hull immediately. Tier shape: T1 surge. T2 kill-trigger regrow. T3 the regrow also applies to allies within 2 hexes of the killer. Reuses surge and the existing kill-detection and regrow systems. No new rule.

Mending: Deep Regrowth (restore slot).
25% hull repair, patch damaged and destroyed sections as base restore. Bonus: any section repaired by this command gains +10% damage resistance for the rest of the battle (the flesh grows back thicker). Tier shape: T1 repair. T2 patch sections and apply the resistance buff. T3 repair rises to 30% and resistance to 15%. Reuses restore. The per-section resistance buff that persists beyond the round is a new rule. Flag: new rule, moderate scope. The engine needs a per-section damage-resistance modifier that persists until battle end. Three hull sections per ship, so up to three float values per ship. Small in memory, but the damage pipeline needs to check it.

Voice: Hunger Volley (barrage slot).
Free volley as base barrage. Bonus: each ship heals for 5% of the damage it deals during the volley. Tier shape: T1 free volley. T2 lifesteal at 5%. T3 lifesteal at 8%. Reuses barrage. The lifesteal is a heal-on-damage-dealt trigger, which the engine likely already has in some form for the Feed rule or for weapon effects. If not, it is a small new hook: after damage resolution, apply a percentage as healing to the source. Flag: possibly new rule depending on whether a generic lifesteal hook exists.

Balance argument. The Chorus never used iron because it has no shields, so losing iron is not a loss. Spore Burst and Predator Lunge add Feed synergies to scramble and surge, which are small bonuses that only activate on kills. Deep Regrowth's persistent resistance is the strongest addition, but at 10% per section it is a modest long-fight bonus and the Chorus already regrows hull every round, so the marginal value is lower than it appears. Hunger Volley's 5% lifesteal is small per ship and only fires during the one volley. Total set value matches the current templates.

Least-sure decision. The lifesteal percentage on Hunger Volley. At 5% it is barely felt. At 8% (T3) with a full Chorus fleet firing a volley, the total healing could be significant. Needs playtest data.

Biggest risk. Deep Regrowth's persistent resistance stacks with the Chorus's passive Feed regrowth. Over a long battle, a Chorus fleet that uses Deep Regrowth early could become very hard to kill section by section. The resistance should probably cap or only apply to sections that were actually damaged, not to undamaged sections.

5. The Glasswrights. Theme: "Be somewhere else before the hit lands."

The Glasswrights cannot Brace, so no command in this set references Brace.

Aelith: Prism Scatter (scramble slot).
Extra wing, squadrons re-strike at +50% as base scramble. Bonus: this round, all Glasswright ships can use their slip-away-after-firing ability at no movement cost (normally it costs movement or an action). Tier shape: T1 extra wing. T2 re-strike at +50% and free slip-away. T3 free slip-away also grants +1 bonus movement after the slip. Reuses scramble and the existing slip-away mechanic. No new rule; just a cost waiver for the round.

Vaelen: Focused Beam (barrage slot).
Free volley as base barrage. Bonus: beam weapons this round deal +25% damage and pierce 10% of the target's shield pool. Tier shape: T1 free volley. T2 beam bonus. T3 beam bonus and +1 hex range on beams. Reuses barrage. The shield pierce is a small modifier on the beam damage step. No new rule if the damage pipeline already supports a shield-pierce percentage; flag if it does not.

Thorne: Glass Slip (surge slot).
+2 movement, +1 turn, enemy -20 accuracy as base surge. Bonus: this round, Prism Charge triggers even if the ship was hit since its last turn, overriding the normal "untouched" condition. Tier shape: T1 surge. T2 Prism Charge override. T3 also grants +1 extra movement. Reuses surge and the existing Prism Charge condition check. No new rule; the condition check gets a bypass flag for the round.

Mirelle: Crystal Aegis (iron slot).
All shields refill, 40% less hull damage as base iron. Bonus: any ship whose shields were already full at the start of the round gets an additional 10% less hull damage this round. Tier shape: T1 shield refill. T2 the 40% reduction. T3 the extra 10% for full-shield ships. Reuses iron. The conditional check on shield-full-at-round-start is a small addition to the iron resolution. No new rule if the engine tracks shield state at round start; flag if it does not.

Balance argument. Prism Scatter's free slip-away is a mobility bonus that fits the faction's hit-and-run identity but does not add raw damage. Focused Beam's +25% beam damage is a meaningful but single-weapon-type bonus, roughly equivalent to the base barrage value since Glasswrights lean on beams. Glass Slip's Prism Charge override removes a condition rather than adding a number, so its value depends on how often Glasswright ships get hit; in practice it is a modest bonus. Crystal Aegis's extra 10% for full-shield ships rewards the faction's existing shield-management play. Total set value matches the current templates.

Least-sure decision. Whether Focused Beam's shield pierce should be 10% or 5%. At 10%, Glasswright beams start to feel like ion weapons, which steps on Meridian's identity.

Biggest risk. Glass Slip at T3 with +3 total movement and free Prism Charge could let Glasswright ships kite indefinitely, making them very hard for slower factions to catch. The movement numbers need tuning against the slowest faction's average speed.

6. Eclipse. Theme: "The Archive remembers; the void does not forgive."

Eclipse has no shields, so the iron slot is reworked. The four template slots used are restore, barrage, hunt, and iron (reworked).

Nekhet: Archive Recall (restore slot).
25% hull repair, patch damaged and destroyed sections as base restore. Bonus: this round, if any Eclipse ship would be destroyed (hull reaches 0), it instead survives at 1 hull and is flagged as archived, triggering the existing Archive restore rule at the start of the next round (reassembles at 35% hull). Tier shape: T1 repair. T2 patch sections and the death-save. T3 repair rises to 30% and the death-save also applies to the ship's captain (captain survives). Reuses restore and the existing Archive restore system. The death-save (hull hits 0, set to 1, flag as archived) is a new rule. Flag: new rule, moderate scope. It hooks into the destruction check, intercepts it once per battle (since the command is once-per-battle), and feeds into the existing Archive pipeline. The engine needs a "pending archive" state between destruction and removal.

Sekhmar: Null Salvo (barrage slot).
Free volley as base barrage. Bonus: null weapons this round ignore 20% of the target's armor value. Tier shape: T1 free volley. T2 armor pierce at 20%. T3 armor pierce at 30%. Reuses barrage and the existing armor value in the damage pipeline. No new rule; the armor-pierce modifier is a standard damage-pipeline step.

Anuket: Fold Strike (hunt slot).
Torpedoes reload, +30% damage as base hunt. Bonus: this round, any Eclipse ship that uses its fold drive to pass through a hex occupied by an enemy ship deals 10% of its own hull value as damage to that enemy. Tier shape: T1 reload and damage. T2 fold-drive damage. T3 fold-drive damage rises to 15%. Reuses hunt. The fold-drive-through-enemy damage is a new rule. Flag: new rule, moderate scope. The engine has fold drive movement; this adds a damage trigger when the fold path crosses an occupied enemy hex. Needs a path-check during fold resolution.

Khepra: Void Plate (iron slot, reworked for no shields).
Since Eclipse has no shields, the shield-refill component is replaced. Effect: all Eclipse ships take 40% less hull damage this round, and all armor values are treated as 20% higher for the round. Tier shape: T1 the 40% damage reduction. T2 armor boost at 20%. T3 damage reduction rises to 50%. Reuses the damage-reduction half of iron. The armor boost is a temporary modifier on existing armor values. No new rule.

Balance argument. Archive Recall's death-save is the most powerful addition in this set, but it is once per battle and only saves a ship for one round (it still reassembles at 35% hull, which is fragile). Null Salvo's armor pierce is a modest damage bonus that fits the null-weapon identity. Fold Strike's fold damage is a small bonus that requires spending movement to trigger. Void Plate replaces shield refill with armor, which is equivalent value for a shieldless faction; the 40% damage reduction is the same as base iron. Total set value matches the current templates, with the caveat that Archive Recall's death-save is the highest-variance element.

Least-sure decision. Whether the Archive Recall death-save should trigger once (saving one ship) or apply to all ships that would die this round. Once is safer for balance but feels less epic. All-ships risks making Eclipse unkillable in the round it fires.

Biggest risk. Archive Recall combined with the faction's existing Archive restore (35% hull reassembly) creates a loop where a ship effectively gets two lives in consecutive rounds. In a long battle, this could let Eclipse grind down opponents through attrition. The death-save should probably only trigger once per battle total, not once per ship.

New rules summary

Rule - Faction - Scope
Squadron damage-reduction aura on parent - Sunward - Small
Squadron accuracy debuff on target - Meridian - Small
Per-section persistent resistance buff - Chorus - Moderate
Lifesteal hook on damage dealt - Chorus - Small, possibly exists
Squadron pre-strike move phase - Ashfall - Small, possibly exists
Death-save intercepting destruction into Archive - Eclipse - Moderate
Fold-drive damage on passing through enemy hex - Eclipse - Moderate

Seven flags total. Four are small. Three are moderate. None require reworking the damage pipeline from scratch; they all hook into existing resolution steps.

Question 2: Deployment Step

Scoring

I will score each option from 1 (poor) to 5 (strong) on the four axes.

Option A: None. Fleets start where the game places them.
Player value: 2. The player has no say in starting positions. For a hex tactics game where positioning matters (Line of Battle needs a line, Synchronized fire needs clustering, Ashfall needs to close distance), this is a real gap. The player's first meaningful decision happens after the game has already decided something important.
AI handling: 5. The AI does nothing extra. Placement is fixed by the scenario.
Teaching load: 5. No new step, no new UI, no new explanation.
Build cost (agent runs): 5. Zero additional runs. Every scenario plays out from a fixed start.

Option B: Place-in-zone. Before round 1, the player drags each ship anywhere inside a deployment zone on their side of the board. The enemy is already placed or places by its own rules.
Player value: 5. Full agency over starting positions. This is the single decision that most rewards understanding of your fleet composition. A Sunward player sets up a line. A Meridian player clusters around the command ship. An Ashfall player staggers for a rush. A Glasswright player spreads out for Prism Charge. The decision is meaningful every battle because the board layout, enemy composition, and your own roster change in a roguelite.
AI handling: 3. The AI needs a placement heuristic. This can be simple (command ship in the back row, escorts adjacent, strikers forward, squadrons on carriers) and does not need to be optimal. The risk is that a bad AI placement makes the fight too easy or too hard. Mitigation: test three or four AI placement presets per faction and pick the one that lands closest to the target win rate.
Teaching load: 3. One new step before round 1. The player needs to understand the zone, that they can drag ships, and that the enemy is already set. A short tutorial prompt covers it. Not zero, but not heavy.
Build cost (agent runs): 3. Every faction-versus-faction pairing now has a variable starting state. To validate balance at the 3-percentage-point window, agent runs need to sample multiple deployment configurations. Estimate roughly 3x the current number of runs per pairing to cover the variance. This is the main cost.

Option C: Formation pick. The player picks one of several named formations and ships auto-arrange.
Player value: 4. A meaningful choice, but less granular than B. The player picks "Line," "Wedge," "Rush," "Spread," or something similar, and the game places ships. Good for speed, weaker for expression. A player who wants to put one specific ship in a specific hex cannot.
AI handling: 4. The AI picks a formation from the list. Simple selection logic. No per-ship placement needed.
Teaching load: 4. "Pick a formation." The player needs to see what each formation looks like, which means a small preview UI. Lighter than B because there is no dragging.
Build cost (agent runs): 3. Each formation is a fixed layout, so the number of starting states is bounded by the number of formations (say 4 to 6). Fewer than B, more than A. Estimate roughly 1.5x the current number of runs.

Pick: Option B, place-in-zone, with one mitigation.
The mitigation is a saved deployment layout. After the player arranges ships for the first time in a given roster, the game remembers the layout and offers "use last deployment" as a one-click option for subsequent battles with the same ships. This addresses the roguelite friction concern (many battles per run) without removing the option to rearrange when the situation calls for it.

Strongest argument against B.
In a roguelite with 10 to 20 battles per run, even with a saved layout, the deployment step adds 15 to 30 seconds per battle. Over a run, that is 3 to 10 extra minutes of non-combat interaction. If the player always uses the saved layout, the step becomes a confirmation dialog with extra steps, and they will resent it. If they always rearrange, the run drags. Option C avoids this by making the decision one click. The counter-counter-argument is that hex tactics players chose this genre for positioning decisions, and 15 seconds of meaningful setup is cheaper than 15 seconds of watching an auto-resolve. But the friction is real and should not be dismissed.

Least-sure decision. How large the deployment zone should be. A zone that is 3 hexes deep and the full width of the board gives real choice. A zone that is 1 hex deep is barely different from fixed placement. The zone size interacts with board size and fleet size and needs its own tuning pass.

Biggest risk. AI placement quality. If the AI always uses the same heuristic, players will learn to exploit it (for example, always rushing the AI's exposed flank). If the AI varies placement randomly, balance testing becomes noisy. The fix is 3 to 4 hand-tuned AI placements per faction, selected based on the player's fleet composition, but this adds design and testing work.

Question 3: Called Shots Interaction

Commands that produce free volleys (all barrage-slot commands: Broadside Consecration, Sync Volley, Hunger Volley, Focused Beam, Null Salvo) should honor the player's called-shot setting if one is active. The free volley is still the player's ships firing their weapons, and the called-shot section priority is a targeting order the player set. Each ship in the volley routes its shots to the called section, gets the +15 crit, and forces system damage as normal. The small trade-off cost of called shots was already paid when the player set the priority. No extra cost per ship in the volley. This is the simplest ruling and the one players will expect.

Hunt-slot commands (Lance Purge, Ion Cascade, Rocket Storm, Fold Strike) need a split ruling. Torpedoes and rockets are unguided area weapons in most fleet games, and the engine's torpedo and rocket systems likely resolve damage against hull without section targeting. I recommend that torpedoes and rockets from hunt commands do NOT receive the called-shot bonus. They get the command's +30% damage but not the +15 crit, not the section routing, and not the forced system damage. Fold Strike's fold-drive damage is hull damage, not a weapon shot, so it also ignores called shots. This keeps called shots as a gun-and-beam mechanic and avoids the odd image of a torpedo carefully aiming for an engine block.

Scramble-slot commands (Wing Screen, Drone Bloom, Swarm Dive, Spore Burst, Prism Scatter) produce squadron strikes. Squadrons in this game appear to deal hull damage directly and do not interact with the weapon-targeting system. I recommend that called shots do not apply to squadron damage. Squadrons hit the hull pool. This is clean and avoids adding section-routing logic to the squadron resolution step. Defensive and mobility commands (iron slot, restore slot, surge slot) have no interaction with called shots since they do not produce attacks. One combo to watch: Chorus Hunger Volley's lifesteal is based on damage dealt. If a called shot routes damage to a section with low remaining hull, the actual damage dealt may be lower (overkill is wasted), which reduces the lifesteal. This is correct behavior and needs no special ruling, but it should be documented so players understand why the heal was smaller than expected.

Least-sure decision. Whether barrage-slot commands should let each ship pick its own called section or force the whole volley onto one section. Forcing one section is simpler and matches the "priority" framing. Letting each ship pick is more tactical but adds UI complexity to the free-volley resolution.

Biggest risk. Null Salvo's 20 to 30% armor pierce stacking with a called shot's +15 crit and forced system damage against a single section could delete a ship's prow or engines in one volley. This is a once-per-battle spike, so it may be acceptable, but it needs a damage-cap check in the agent runs to confirm it does not exceed the one-round kill threshold on standard-difficulty targets.

Single Strongest Objection to This Brief

The brief asks for faction command sets that make "playing a faction feel like its battle rule." But battle rules are passive, continuous effects that shape every round. Commands are once-per-battle active abilities that shape one round. There is a structural mismatch. A command can reward the battle rule for one round (as most of my proposals do), but it cannot make the player feel the battle rule in the way that, say, managing sync range every turn makes Meridian feel like Meridian. The command will always be a highlight moment, not an identity. The risk is that players perceive the command as a bonus button rather than as an expression of their faction, and the faction identity continues to rest almost entirely on the battle rule and ship stats. If the council wants commands to carry more identity weight, the brief should consider letting the command interact with the battle rule across multiple rounds (for example, "for the next 3 rounds" instead of "this round"), but that changes the power budget significantly and would need a fresh balance pass beyond the PR 2038 window. This is worth discussing before locking the set.

END OF MODEL RESPONSE
