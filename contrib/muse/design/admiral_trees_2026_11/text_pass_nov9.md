# Tree text pass, Nov 9 2026 (issue #311)

Every change this pass makes to the finalized faction files, old text and new text, with the effect key or hook each rewrite rides on. Ruled by FINDINGS R145: every pick changes a battle, rewrites use the plan's existing effect keys (tree_effects_plan.md section 1) or listed hooks (section 3), no new mechanics. Chaired by Rey from five legs: blind Rey, DeepSeek and Qwen (writers), Flash and Grok (ideation).

This file grows faction by faction. The Glasswrights pilot is first because board job #312 waits on its Glasswright rewrites.

## Glasswrights (pilot, delivered first)

### Rewrites: rows that did nothing (bucket x) or needed a new mechanic (bucket c)

**Tamsa T1a, Flight Paths in the Glass** (x)
Old: record each extra wing strike path before launching; a wing that follows its recorded path exactly strikes at +15% damage
New: an extra wing that strikes the target its carrier last fired at gains +15% damage
Rides on: dmgPct / sqPct room; the carrier's last-fired target is the tracked condition (the plan's own suggested rewrite; all five legs converged on it).

**Tamsa T2a, The Replay Corrects** (x)
Old: after the first strike resolves, each extra wing may be retargeted freely for its strike again, using what the glass recorded
New: an extra wing's strike again against a target already hit this round gains +10% damage
Rides on: H2 hits-per-target counter, sqPct room. (DeepSeek and Qwen form; the blind leg's +10 aim variant lost to damage on a known target, which is what a replay corrects.)

**Tamsa T2b, Starlings in Formation** (x)
Old: extra wings that strike in the same order as their carriers are arranged gain +10 aim
New: extra wings that strike the same target as another extra wing gain +10 aim
Rides on: aim key; convergence condition from wing orders. (DeepSeek form; Flash and Qwen's within-3-hexes-of-carrier variant dropped, formation is about the target, not the carrier.)

**Tamsa Cap1, Flight Cast Perfectly** (c, C1)
Old: during Starling flight, all wings striking the same target combine their attacks into a single simultaneous strike that ignores point defence and deals +25% damage to the target's most damaged section
New: during Starling flight, wings striking the same target ignore its flak, its shields stop only the first wing hit, and wing hits after the first deal +25% damage to its most damaged section
Rides on: H2 counter; the plan section 4 drop-to-b rewrite for C1 (shields stop only the first hit) carrying the original's flak ignore and +25% to the most damaged section. No summed-hit mechanic.

**Tamsa Cap2, The Forge Casts Ahead** (x to b)
Old: after the Command, one extra wing per carrier stays aloft and repeats its recorded strike at the start of next round
New: after the Command, one extra wing per carrier strikes the same target again at the start of next round, at +15% damage
Rides on: H3 next round plus H6 wing tag; the recorded target is the only new part (wings already stay and strike every round), priced at +15%.

**Saro T1b, One Lens, One Target** (x; the plan left the reading to Muse)
Old: a ship may fire its volley as a single shot at +25% damage instead of firing every gun
New: choose one of your ships: it fires its whole volley at a single target you name, and its shots gain +25% damage against that target
Rides on: H1 choice, H5 Command targeting, dmgPct room. The one-gun reading is a strict downgrade and the merged-hit reading is C1; concentration plus the draft's +25% is the honest middle. (Blind Rey form; DeepSeek's concentration variant agreed at +15%.)

**Saro T2a, Light Arrives Together** (x)
Old: you may hold the volley until all your ships have moved, and fire lance shots in any order you choose
New: during the volley, a shot at a target already hit by one of your other ships this round gains +15% damage
Rides on: H2 hits-per-target counter, dmgPct room. (Blind Rey form. Three legs priced the already-free timing instead, which is plan pattern 1; Qwen's ships-that-did-not-move variant was the strongest alternative.)

**Saro Cap1, Sun Through One Lens** (c, C1)
Old: Burning glass may concentrate every ship's volley on one target, resolving as a single combined strike that ignores range penalties
New: Burning glass may concentrate every ship's volley on one target; its shields stop only the first hit, and no shot suffers range falloff
Rides on: H1 choice, H2 counter; the plan section 4 C1 rewrite, keeping the original's no-falloff term. (Qwen form; DeepSeek's agreed with a +10% on later hits added, dropped to keep the capstone at its promised terms.)

**Vell T2a, The Mirror Steps Aside** (x to b)
Old: during the scatter, a ship may pass through one enemy-held hex without stopping
New: during the scatter, a ship may dive under one enemy-held hex at no extra cost
Rides on: H11; waives the existing +1 movement surcharge once. All five legs agreed.

**Vell T2b, Light Split Three Ways** (x to b)
Old: during the scatter, a ship may split its movement, half before it fires and half after
New: during the scatter, a ship may move its full remaining movement after it fires
Rides on: H11; raises the faction's built-in half to full for the scatter. All five legs agreed.

**Vell Cap1, The Fleet Is Elsewhere** (c, C2)
Old: Scatter the light may be declared after the first enemy ship fires; your ships move immediately, interrupting the enemy turn
New: the first time an enemy fires at your fleet this battle, every ship gains +2 movement and may turn once for free
Rides on: H2 first-fire trigger, speed key, H11 free facing; the plan section 4 automatic form of C2, keeping the original's movement payoff (+2 is the surge Command's own low tier). (Qwen form; Grok's agreed, DeepSeek's evasion-only variant dropped the movement the skill is named for.)

**Brin T1a, Light Bent to the Weak Side** (x)
Old: you may give one ship's shield refill to the friendly ship with the lowest shields instead
New: during the ward, the friendly ship with the lowest shields takes 20% less hull damage until the start of next round
Rides on: H8 hull cut family, treeHullCut room. (Blind Rey form; Flash's lowest-hull variant agreed on the mechanism. Overcharge and temporary-hull variants lost: both duplicate the sibling picks T1b and Cap2.)

**Brin T1b, Prisms Face the Fire** (x to b)
Old: a ship facing its nearest enemy refills +25% more shield during the ward
New: a ship facing its nearest enemy gains shields above its maximum equal to 25% of its maximum shields during the ward
Rides on: H7 overcharge, treeShOver cap (.25). All five legs agreed on the mechanism; the new text states what the 25% is of.

**Brin T2b, The Lens Rotates** (x)
Old: during the ward, a ship may change its facing after moving without losing the damage reduction
New: during the ward, a ship that changes its facing gains +10 evasion until its next turn
Rides on: ev key through evBuff, whose own duration is until the ship's next turn. Four legs converged on this form.

**Brin Cap2, Every Facet Lit** (x to b)
Old: during the ward, shield strength refilled beyond a ship's maximum becomes temporary hull of hard light, up to +20%
New: during the ward, each warded ship gains temporary hull equal to 20% of its maximum shields
Rides on: H10 temporary hull, treeTempHp cap (.2). All five legs agreed, near-verbatim.

### Wording fixes on rows that already work

**Tamsa T3a, Flaw in the Flight Removed**: "point defence" becomes "flak", the game's one term. New: extra wings ignore the flak of one chosen enemy ship for this Command.
**Saro T1a, Focus Drawn Long**: "the firing ship's range" becomes "the weapon's range". New: volley shots at targets beyond half the weapon's range gain +20% damage.
**Vell T3a, Refraction Deepens**: "moves its full distance" becomes "spends all its movement".
**Brin T3a, Flaw in the Glass Corrected**: shields are four facings. New: while the ward is active, the first ship that has a shield facing emptied refills that facing to 15%, once per battle.
**Brin T3b, Hard Light**: names the facing. New: during the ward, a ship with shield left on the struck facing takes no section damage from its first hit.

### Chair notes

- The pack header and the blind leg first scoped this pass as 12 x rows and 1 c row. The sort table and the plan's counts say 3 c rows (Tamsa Cap1, Saro Cap1, Vell Cap1). DeepSeek and Grok caught it; the pass covers all 15 rows. No row was left unrewritten.
- One leg proposed respelling "defence" to match data.js instead of using "flak". Rejected: the plan rules one term, the flak gauntlet.
- The five stale data.js Glasswrights texts (Tamsa T3b and Cap1, Saro T3b, Vell Cap2, Brin Cap1) are unchanged by this pass; copying the final texts into data.js is the pilot build job's data step (#312), as is wiring these rewrites into TREE_FX.

## Sunward Crusade

### Rewrites: rows that did nothing (bucket x) or needed a new mechanic (bucket c)

**Vex T1a, Ledger of Arcs** (x)
Old: a ship firing its volley from a broadside arc may split that volley between two targets in the same arc
New: a ship firing its volley from a broadside arc gains +15% damage
Rides on: broadPct room; the broadside arc was already the condition, the split permission was the dead half. (DeepSeek form; Qwen agreed at +15%.)

**Vex T3b, Debt Comes Due** (x)
Old: you may delay the whole volley to the start of next round, when it fires before any enemy ship acts
New: you may delay the whole volley to the start of next round; when it fires, every ship gains +20% damage
Rides on: H3 next-round hold, dmgPct. The old timing clause priced a free action; the interest is the payoff.

**Vex Cap1, The Grand Ledger** (c, C1)
Old: once per battle, when Fire for effect is used, choose one enemy; every ship that can reach it fires, all damage is summed, and the target's shields are applied once to the total
New: once per battle, when Fire for effect is used, choose one enemy; every ship that can reach it fires at it, and its shields stop only the first hit
Rides on: The plan section 4 C1 drop-to-b form (H1, H2: shields stop only the first hit). All legs converged.

**Vex Cap2, The Last Account** (x)
Old: Fire for effect fires at the very start of the round, before movement, and each ship picks its own target
New: after Fire for effect resolves, each ship that destroyed its target with the free volley fires one weapon again at a new target
Rides on: H4 second firing on a kill (H2 kill counter). (DeepSeek form; it replaces the blind leg's early-declaration form, which duplicated Vex T3b's timing theme.)

**Malek T2a, Torpedoes Run First** (x to b)
Old: during the salvo round, torpedoes resolve before all gun fire, so their kills open lanes for the fleet guns
New: torpedoes fired during the salvo round strike at once instead of travelling
Rides on: H4; the plan's own form. Torpedoes normally travel; striking at once is the payoff.

**Malek T2b, Rear Arc Reckoning** (x to a)
Old: during the salvo round, rear arc hits from any weapon, not only torpedoes, gain the hunter-killer rear arc bonus
New: during the salvo round, rear arc hits from any weapon gain +15% damage
Rides on: rearPct room. The final text circled this; the rewrite states the number.

**Malek Cap1, Salvo Without End** (x to b)
Old: Hunter's salvo reloads all torpedoes a second time at the end of the round
New: during the salvo round, each ship may fire one torpedo a second time at half damage
Rides on: H4 second firing at half damage. Reloads already happen every round under Malek; a second firing is the payoff.

**Ashgrove T2a, The Account Splits** (x)
Old: each extra wing may strike a different target than the rest of its carrier's wings
New: an extra wing that strikes a different target than its carrier's other wings gains +15% damage
Rides on: sqPct room, H2 per-wing target tracking.

**Thale T1b, Screens Where the Debt Falls** (x)
Old: you may move up to half of one ship screen refill to a different friendly ship before the wall resolves
New: you may shift the wall's protection: one chosen ship takes 20 points more hull damage reduction, and one other ship takes 20 points less
Rides on: H8 stacked cut, pointed by the player. The old text moved a refill the wall already grants in full.

**Thale T2a, Wall Declared Early** (x)
Old: Iron wall may be declared at the start of the round, before any ship moves or fires
New: if Iron wall is declared before any of your ships has moved or fired this round, its damage reduction is 10 points stronger this round
Rides on: cmdTaken variant on a tracked declaration condition. (Flash's free-timing trap is why the number rides on the declaration, not the timing alone.)

**Thale Cap2, The Wall That Moves** (x)
Old: during Iron wall, your ships may move at full speed without losing the damage reduction
New: while Iron wall is active, your ships gain +1 movement
Rides on: speed key. Moving never cancelled the cut; the wall itself now pays speed.

### Wording fixes on rows that already work

**Ashgrove T1b, First Wave Owes the Second**: H1 choice. Launch order has no mechanical meaning; the +20% moves to a chosen carrier.
Old: choose the launch order carrier by carrier; the last carrier to launch has its extra wing strike at +20% damage
New: choose one carrier; its extra wing strikes at +20% damage

**Ashgrove T3b, Wings Settle the Debt**: Drops the undefined 'screened at half effect' clause; the +30% and the per-carrier limit stay.
Old: an extra wing striking the same target as its carrier guns gains +30% damage and is screened at half effect, once per carrier
New: an extra wing striking the same target as its carrier's guns gains +30% damage, once per carrier

**Ashgrove Cap1, The Roll of Wings**: sqIgnite, H15. Fire burns a ship, not a section; point defence becomes flak, the game's one term.
Old: during Scramble all wings, every squadron strike ignites the struck enemy section and reduces the target point defence by 1 for the rest of the battle
New: during Scramble all wings, every squadron strike ignites the struck ship and reduces the struck ship's flak by 1 for the rest of the battle

**Ashgrove Cap2, Oath of Unbroken Wings**: H16. States what the refill is (25% of maximum shields) instead of a bare +25% screen refill.
Old: during Scramble all wings, extra wings may form an escort wall across the fleet, granting every friendly ship within 2 hexes of a carrier +25% screen refill and intercepting the first torpedo fired at each escorted ship this round
New: during Scramble all wings, extra wings may form an escort wall across the fleet, granting every friendly ship within 2 hexes of a carrier a screen refill equal to 25% of its maximum shields, and intercepting the first torpedo fired at each escorted ship this round

**Thale T3a, Unpaid and Unbroken**: cmdTaken in points, the wall's own units, scaled to the wall's tier instead of a second percentage scale.
Old: during Iron wall, ships below half hull take 60% less hull damage instead of 40%
New: during Iron wall, ships below half hull take 20 points more hull damage reduction than the wall normally gives

**Thale T3b, The Wall Answers**: H4, H2. Names the facing and the order: the return shot resolves after the hit that emptied it.
Old: while Iron wall is active, a ship whose shields are emptied by a hit fires its smallest weapon at the attacker, once per ship per battle
New: while Iron wall is active, a ship whose shield facing is emptied by a hit fires its smallest weapon at the attacker once that shot has resolved, once per ship per battle

## Hegemony Navy

### Rewrites: rows that did nothing (bucket x) or needed a new mechanic (bucket c)

**Kassar T2a, Shared Solution** (x to b)
Old: synced ships share their best aim modifier
New: each synced ship fires with the best aim modifier any synced ship has
Rides on: The plan's own fix, stated as a rule the build can read.

**Kassar T2b, Cold Drill** (x)
Old: sync forms at round start even if the flagship has not moved
New: a synced ship that has not moved this round fires at +10 aim
Rides on: aim room on an unmoved condition. Sync never waited on the flagship; a cold gun line is the drill.

**Kassar T3b, Iron Tempo** (x to b)
Old: sync survives the flagship's first crippling hit each battle
New: the first time the sync anchor is destroyed or captured, the largest remaining Hegemony ship becomes the new anchor for the rest of the battle
Rides on: Sync is lost only when the anchor is destroyed or captured (the plan's trigger); 'crippling hit' is dropped.

**Kassar Cap2, One Voice** (c, C1)
Old: once per battle, every synced ship fires at one target simultaneously, resolving as a single combined strike
New: once per battle, every synced ship fires at one named target, and its shields stop only the first hit
Rides on: The plan section 4 C1 drop-to-b form (H1, H2).

**Vorn T2b, Filed Before Movement** (x)
Old: the strike may be declared before movement, and ships that move into range during the round keep the full bonus
New: during Interdiction strike, a ship that fires before it has moved this round gains +10 crit chance
Rides on: crit room on an unmoved condition, in Vorn's filing idiom. (The Command name is already Interdiction strike in this file; no Vorn text reloads torpedoes, verified line by line, per R145 question 5.)

**Vorn Cap2, One Order, Every Gun** (x)
Old: Interdiction strike may be declared at the start of a round, and your ships fire before the fastest enemy ship that round
New: during Interdiction strike, every ship may fire one weapon a second time at half damage
Rides on: H4 second firing at half damage. One order, every gun, twice.

**Reyes T1a, Cruisers Filed as Carriers** (x to b)
Old: during the launch, choose one cruiser; it launches a wing as if it were a carrier, in addition to the carriers extra wings
New: during the launch, choose one ship without a hangar; it launches one wing this Command
Rides on: H6. The cruiser and battleship classes already are launch ships, so the pick goes to a ship with no hangar.

**Reyes T2b, Procedure Rehearsed** (x)
Old: after the first strike resolves, each extra wing may be reassigned to a new target for its strike again
New: every extra wing's strike again this Command gains +10 aim
Rides on: aim room, H2 strike-again window. Reassignment was already free.

**Reyes Cap2, Standing Strike Group** (c, C2)
Old: after the Command, one extra wing per carrier stays on patrol and strikes the first enemy that enters its carrier range each round
New: after the Command, one extra wing per launch ship stays on patrol; the first time an enemy ship moves within its launch ship's range each round, it strikes that enemy at once
Rides on: H2 automatic trigger (the plan section 4 C2 form). The trigger is the enemy entering the launch ship's range, not the wing's; the rewrite also fixes this file's carrier wording to launch ship.

**Maren T1a, Column Filed Straight** (x to b)
Old: during the wall, ships in a line of three or more adjacent friendly ships refill +25% more shield
New: during the wall, ships that end their movement in a straight line of three or more friendly ships gain shields above their maximum equal to 25% of their maximum shields
Rides on: H7 overcharge, treeShOver cap (.25); the line is now a movement outcome.

**Maren T1b, Overflow by Regulation** (x)
Old: during the wall, shield refill beyond a ship's maximum flows to the adjacent friendly ship with the lowest shields
New: during the wall, a ship that is at full shields gains +10 evasion until its next turn
Rides on: ev key through evBuff. A refill to full cannot overflow; regulation converts the surplus to evasion.

**Maren T2a, Wall at the Bell** (x)
Old: the wall may be declared at the very start of the round, before any ship moves or fires
New: while the wall is active, the first hit against your fleet each round deals no hull damage
Rides on: H8 absorb on an H2 per-round counter. The bell marks the first blow, and the wall eats it.

**Maren Cap1, The Standard Covers All** (x)
Old: Shield wall order also refills the shields of each ship adjacent to a ship in the column at half strength, even if that ship is not in the line
New: while Shield wall order is active, every ship takes a further 20% less hull damage
Rides on: H8 stacked cut. The old text refilled ships the wall already refills to full.

**Maren Cap2, The Flagship Holds the Standard** (x to b)
Old: while the wall is active, the flagship counts as part of every friendly line for column effects, and ships in a line with the flagship refill +10% more shield
New: while the wall is active, the flagship counts as part of any friendly line, and ships in a line with the flagship gain shields above their maximum equal to 10% of their maximum shields
Rides on: The plan's own x-to-b form: the flagship counts as part of any line, and ships in its line gain +10% overcharge (H7).

**Hegemony shared B1a, Formation Filed Before Battle** (c, C3)
Old: choose one standard formation at battle start; ships that end their movement inside it gain +10 aim that round
New: ships that end their movement next to two friendly ships gain +10 aim that round
Rides on: The plan section 4 C3 bucket-a rewrite, verbatim.

### Wording fixes on rows that already work

**Kassar T3a, Rolling Fire**: H4. Says which ship (one that has not yet fired) and that it fires at once.
Old: a kill by a synced ship lets another synced ship fire immediately, once per round
New: once per round, when a synced ship kills an enemy, another synced ship that has not yet fired this round may fire one weapon at once at a new target

**Kassar Cap1, Living Relay**: Drops the line-of-sight half; sync never required sight to the flagship.
Old: the flagship projects sync from its position at double radius, and sync no longer requires line of sight to the flagship
New: the flagship projects sync from its position at double radius

**Vorn T1b, Strike by the Book**: Clarification with the same mechanic: 'ascending speed order' restated as a comparison the build can check. (DeepSeek form.)
Old: during the strike round, ships that fire in ascending speed order gain +15% damage
New: during the strike round, a ship gains +15% damage if its speed is at least the speed of the last ship that fired this round

**Vorn T3a, Total Interdiction**: Drops 'split their fire freely' (ships already choose targets); the three-hit +30% stands.
Old: during the strike round, your ships may split their fire freely, and any target hit by three or more ships takes +30% damage from every hit that round
New: during Interdiction strike, any target hit by three or more of your ships takes +30% damage from every hit that round

**Reyes T2a, Second Wave on Schedule**: The plan asked the text to say whether the bonus carries. Chair ruling: it does not carry; the held wings strike at normal damage. (DeepSeek's ruling, adopted over the blind leg's.)
Old: you may hold all extra wings and launch them at the start of next round instead, striking then at full effect
New: you may hold all extra wings and launch them at the start of next round instead; they strike then at normal damage, and the Command's strike bonus does not carry over

**Reyes T3a, Full Group Assembled**: Terminology: Hegemony has launch ships, not carriers (two places).
Old: if every carrier launches an extra wing, each carrier launches one more, but all extra wings must strike the single filed target
New: if every launch ship launches an extra wing, each launch ship launches one more, but all extra wings must strike the single filed target

**Maren T2b, Standard Rotation**: Drops 'without losing the damage reduction' (nothing loses it); the swap is once per ship.
Old: during the wall, a ship may swap hexes with an adjacent friendly ship without losing the damage reduction
New: during the wall, once per ship, a ship may swap hexes with an adjacent friendly ship

**Maren T3a, The Column Endures**: Names the facing and its owner.
Old: while the wall is active, the first ship each round to have its shields emptied immediately refills to 25%
New: while the wall is active, the first ship each round to have a shield facing emptied immediately refills that facing to 25%

**Maren T3b, Filed in Armor**: The plan's Alternating wording (has not fired yet when hit) and its units: 15 points (cmdTaken).
Old: during the wall, a ship that does not fire this round reduces hull damage by a further 15%
New: during the wall, a ship that has not fired yet when it is hit takes 15 points less hull damage

## Ashfall Hullbreakers

### Rewrites: rows that did nothing (bucket x) or needed a new mechanic (bucket c)

**Grax T1b, Ram First, renamed First Over the Rail** (x to a, boarding)
Old: a ship that moves at least 4 hexes during the burn may ram with no accuracy penalty
New: a ship that moves at least 4 hexes during the burn boards at +25% strength
Rides on: boardPct room, per R145 question 3 A: three Grax skills go to boarding. Rams never roll to hit, so the old text paid nothing. (Rename is DeepSeek's, adopted over the blind leg's Board First.)

**Grax T2a, The Pack Closes** (x)
Old: during the burn, your ships may pass through hexes held by friendly ships
New: during the burn, a ship that ends its movement next to a friendly ship gains +10 aim this round
Rides on: aim room. Friendly ships never blocked movement; the pack closing pays in aim.

**Grax T2b, Ram Rush, renamed Rush the Rail** (x to b, boarding)
Old: a ship that ends its burn movement adjacent to an enemy may ram it immediately instead of firing this round
New: a ship that ends its burn movement adjacent to an enemy may board it even if it has already fired this round
Rides on: boardTargets relaxed, per question 3 A (the questions file's own example). (Rename is DeepSeek's.)

**Grax Cap2, Run of the Warlord** (b, boarding)
Old: when Full burn is declared, the flagship may move twice, and may ram after each move
New: when Full burn is declared, the flagship may move twice, and may board after each move
Rides on: H11, per question 3 A: the second move is a boarding run now. The Maw Opens stays a ram, unchanged.

**Sable T1b, Torpedoes in the Dark** (x to b)
Old: torpedoes fired this round are screened at -20 effect, as if the firing ships were never seen
New: torpedoes fired this round are intercepted at half the usual chance: enemy flak and screen wings roll at half effect
Rides on: H15. 'Screened at -20 effect' is defined as half interception.

**Sable T3a, The Smile Before the Cut** (x)
Old: during the Command round, ships that begin their activation behind an enemy act before that enemy
New: each round during the Command, the first of your ships to activate gains +20% damage on its first shot
Rides on: H2 first-activation counter, dmgPct room. Acting before an enemy is free in Alternating; the first activation now pays.

**Mott T2a, Re-Tasked Mid-Flight** (x)
Old: after the first strike resolves, each extra wing may switch to a new target for its strike again
New: an extra wing that strikes a target no other wing struck this round gains +20% damage
Rides on: sqPct room, H2. A fresh target pays +20%. (DeepSeek form and number.)

**Mott T3a, The Whole Yard Flies** (x)
Old: every ship with any hangar space launches an extra wing during the Command, not only carriers
New: a launch ship that launches all its wings this Command launches one more extra wing
Rides on: H6. The old text restated the base Command; launching everything now launches one more.

**Mott T3b, Wings Come Back Screaming** (x)
Old: the strike again keeps the full +50% bonus even when it hits a new target across the field
New: an extra wing's strike again gains +15% damage when it hits a target already hit this round
Rides on: sqPct room, H2. The +50% already applies to any target; the scream pays on the second helping.

**Mott Cap2, Old Mott Private Wing** (x)
Old: choose one carrier; its extra wing stays launched for the rest of the battle and strikes at half damage at the start of each round
New: choose one launch ship; its extra wing stays for the battle and gains +20% damage on its first strike each round
Rides on: H6. As written the private wing struck at half damage, a penalty; it now stays and its first strike each round pays +20%. (DeepSeek form.)

**Vesh T1b, Patch Over the Guns** (x)
Old: each repaired ship chooses where its repair lands first: weapon sections or engine sections
New: a ship whose weapons section is repaired by the Command gains +10 aim this round
Rides on: aim room. Narrows the repair choice to the weapons section, which is what the name promises. (DeepSeek form.)

**Vesh T2b, Welded While Fighting** (x)
Old: a section patched by the Command works at full effect in the same round it is patched
New: a ship repaired by the Command may fire one weapon at half damage at once
Rides on: H4. A repaired section already works; the payoff is a shot at half damage while the weld is hot.

**Vesh Cap2, Nothing Stays Broken** (c, C2)
Old: Patch and weld may be declared at the start of the enemy turn, landing before the first hit that would cripple one of your ships that turn
New: the first time one of your ships would lose a section this battle, that section is not broken and is restored to full
Rides on: H9 on the plan section 4 C2 automatic trigger; the section is restored to full. (DeepSeek and Grok agreed on full; the blind leg's half lost.)

**Hullbreakers shared B1b, Loose Pack, Wide Lanes** (x)
Old: your ships never block each other's movement or firing lanes
New: a ship gains +1 movement on a move that ends with no friendly ship within 2 hexes
Rides on: speed key, H11 spacing condition. Loose pack pays for spreading out; friendly ships never blocked lanes.

### Wording fixes on rows that already work

**Grax Cap1, Burn Until the Hulls Meet**: H3. 'Movement phase' does not exist; the burn's granted turns are now named.
Old: Full burn movement and accuracy protection carry into next round movement phase
New: Full burn movement, turns and accuracy protection carry into the next round

**Mott T1b, Hulk Holds More**: H6. The wing comes off the Hulk's spare racks; the launching ship is the chosen large non-carrier.
Old: one of your largest ships may launch an extra wing during the Command even though it is not a carrier, using its held wing space
New: choose one of your largest ships that is not a carrier; it launches one extra wing during the Command, from the Hulk's spare racks

**Mott Cap1, Swarm Over the Scrap Field**: H6. Alternating wording: the second launch follows your last activation.
Old: Release the swarm launches the extra wings twice, once at the start of your turn and once at its end
New: Release the swarm launches the extra wings twice: once when the Command is used, and once after your last activation this round

## The Chorus

### Rewrites: rows that did nothing (bucket x) or needed a new mechanic (bucket c)

**Matriarch T2a, The Brood Splits** (x)
Old: each extra swarm may strike a different target than the rest of its brood's swarms
New: an extra swarm that strikes a different target than its brood's other swarms gains +15% damage
Rides on: sqPct room, H2 per-swarm target tracking.

**Matriarch T2b, Spawned Before the Strike** (x)
Old: spawning happens before your ships move, so the new swarms can screen your movement this round
New: a brood that moved this round has its extra swarms strike at +15% damage
Rides on: sqPct room. The unmoved brood is T3a's +25%; the moved brood gets the smaller, earlier bite.

**Matriarch Cap1, Nine Throats, One Hunger** (x)
Old: Spawning surge releases an extra swarm from every ship that carries swarms, not only from broods
New: when Spawning surge is used, choose one enemy; every extra swarm strikes it, and it takes +25% damage from swarm hits this round
Rides on: H1, H6. Only broods carry swarms, so the old text was the base Command restated; concentration is the payoff.

**Matriarch Cap2, The Brood Does Not Stop** (x)
Old: the extra swarms remain after the Command and strike once more at the start of next round before fading
New: an extra swarm that destroys its target strikes another enemy at half damage in the same round
Rides on: H4 chain. Extra swarms already stay; the payoff is the second mouthful at half damage.

**Razormaw T1b, Teeth at the Throat** (x to a)
Old: a ship that ends its frenzy movement behind an enemy strikes that enemy rear arc with its first shot this round
New: a ship's first rear arc hit in the frenzy round gains +25% damage
Rides on: rearPct room, H2 first-hit counter. Ending behind an enemy already grants the rear arc; the number was missing.

**Razormaw T2b, Scent in the Dark** (x)
Old: during the frenzy, a ship may change targets freely after each kill without losing the frenzy accuracy protection
New: during the frenzy, a ship that changes targets after a kill gains +10 aim on its next shot
Rides on: aim room on an H2 kill trigger, in the original text's own shape. (DeepSeek form; the accuracy protection is never lost, so it cannot be the payoff.)

**Mending T2a, The Tide Comes Early** (x)
Old: Regrowth tide may be used at the start of the round, before any fire is taken
New: if Regrowth tide is used before any of your ships has taken damage this round, every repair is 10 points stronger
Rides on: H9 variant on a tracked round condition: the tide used before any damage is taken.

**Mending T2b, Growth Holds the Wound** (x to b)
Old: a section healed by the tide regrows at double rate again next round
New: a section healed by the tide heals again at the next round start, for the same amount
Rides on: H3; the plan's form. 'Double rate' had no base; the same amount again is the number.

**Voice T2b, Spat in Two Rounds** (x to b)
Old: you may fire the volley in two halves, the second half after your ships move
New: choose up to half your ships: they hold their spit in the volley and fire it at the start of next round at half damage
Rides on: H3 plus H4. The text now matches the name: the held half fires next round, at half damage.

**Chorus shared B1a, Roles Assigned at Hatching** (c, C4)
Old: at battle start, give each ship a role (strike, screen, or mend); a ship may change its role once per battle
New: at battle start, give each ship a role: strike (its shots gain +10 aim), screen (it gains +10 evasion), or mend (its repair and regrowth effects are 10% stronger); a ship may change its role once per battle
Rides on: The plan section 4 C4 rule: one number per role. Strike aim and screen evasion by three-leg convergence; mend keeps the repair and regrowth wording.

### Wording fixes on rows that already work

**Matriarch T1a, Choose the Brood That Swells**: H1, H6. The plan's count wording: one more than the Command gives.
Old: one brood releases two extra swarms instead of one, and the other broods release none extra
New: choose one brood: it releases one more extra swarm than the Command gives, and the other broods release none extra

**Voice T1a, Acid Before Aim**: dmgPct room. The nearest-target choice now pays +15%.
Old: each ship may spit its volley at the nearest enemy instead of the best target
New: each ship may spit its volley at the nearest enemy instead of the best target, and those shots gain +15% damage

**Voice T3b, Many Mouths at Once**: H2, H15. Drops 'switch its target once' (volley targets are automatic); the four-ship acid penalty stands.
Old: before the volley resolves, each ship may switch its target once; if four or more ships spit at one target, that target loses 20 accuracy next round as acid eats at its scanners
New: if four or more of your ships spit at one target in the volley, that target loses 20 accuracy next round as acid eats at its scanners

**Voice Cap2, Mouth of the Deep**: States that arcs apply to the double spit, as the blind leg and DeepSeek both required.
Old: choose one ship; it spits with every weapon it carries, twice, at any single target in range
New: choose one ship; it spits with every weapon it carries, twice, at one target in range and in arc

**Chorus shared B1b, Broods in Reserve**: Defines the entry (deployment edge, with its swarms) instead of 'grown and ready'.
Old: hold one brood off the field; it enters, grown and ready, at the start of round 2
New: hold one brood off the field; it enters at the start of round 2 at the deployment edge, with its swarms

## Eclipse

### Rewrites: rows that did nothing (bucket x) or needed a new mechanic (bucket c)

**Nadir T1b, Copies Triage the Damage** (x to b)
Old: assign the repair section by section in any order you choose; a section restored to full also clears all of its damage effects
New: a section the Command repairs to full also clears its ship's fire and acid
Rides on: H15. Fire and acid are ship statuses; the text now says the ship clears them when a section is repaired to full.

**Nadir T2a, Iteration Runs During Fire** (x)
Old: a ship being rebuilt by the swarms may act normally this round; the rebuild never delays its fire
New: a ship repaired by the Command gains +15% damage on its next shot this round
Rides on: dmgPct room, H2 next-shot counter. Repair never delayed fire; firing during the iteration now pays.

**Nadir T2b, The Archive Answers First** (x)
Old: the swarms may be released at the very start of the round, before any ship moves or fires
New: if Release the repair swarms is used before any of your ships has acted this round, every repair is 10 points stronger
Rides on: H9 variant. Restore-family parallel to Mending T2a, kept on purpose: both originals were the same empty timing claim.

**Umbra T2b, Target Archived Mid-Flight** (x to b)
Old: before the volley resolves, each ship may switch its target once
New: before the volley resolves, each ship may choose its own target; a ship that chooses a target no other ship chose gains +10 aim against it
Rides on: H5 per-ship choice plus an unshared-target aim bonus. This is the adopted split from Vex T3a, which keeps its shared-target bonus (see the duplicate calls in the chair notes). (DeepSeek form.)

**Ostrel T2a, The Shadow Is a Position** (x)
Old: the Command round may be declared after movement, once you can see where your ships stand
New: a ship that ends its movement in an enemy's rear arc gains +20% damage in the hunt round
Rides on: dmgPct room on an end-position condition. The shadow is a position: behind them.

**Seveth T2a, Wall Archived in Advance** (x)
Old: the wall may be declared at the start of the round, and its reduction applies from the first enemy shot of the round
New: if Sunshade wall is declared before any of your ships has moved this round, its damage reduction is 10 points stronger this round
Rides on: cmdTaken variant on a tracked declaration condition. Wall-family parallel to Thale T2a, kept on purpose.

**Eclipse shared B1a, Formation Loaded from Archive** (c, C3)
Old: choose one archived formation at battle start; ships that end their movement inside it gain +10 evasion that round
New: ships that end their movement next to two friendly ships gain +10 evasion that round
Rides on: The plan section 4 C3 bucket-a rewrite, verbatim.

**Nadir Cap2, The Earlier Copy Returns** (shield correction)
Old: choose one damaged ship; it is repaired for the full repair amount on every section, all its damaged sections are patched, and its shields refill
New: choose one damaged ship; it is repaired for the full repair amount on every section, and all its damaged sections are patched
Rides on: Shield correction from the issue's done-when: Eclipse has no shields and data.js is already right; the refill clause is dropped.

**Seveth T3a, No Layer Falls Alone** (shield correction)
Old: while the wall is active, the first time each ship shields reach zero, its layered plates absorb the hit that emptied them
New: while the wall is active, the first hit each ship takes is absorbed, once per ship
Rides on: Shield correction: the data.js sense (the first hit absorbed), reworded to 'while the wall is active' per the issue. H8 absorb.

### Wording fixes on rows that already work

**Seveth T1a, Plates over Shadow**: Points, matching the wall's units, instead of a fixed tier split that ignores the wall's tier.
Old: during the wall, you may stack the wall on one ship: that ship takes 75% less hull damage this round, and every other ship takes 25% less instead of 50%
New: during the wall, you may stack the wall on one ship: that ship takes 25 points more reduction than the wall gives, and every other ship takes 25 points less

**Seveth T1b, The Twice-Restored Order**: Says what counts as repaired; reassembly does not count.
Old: a ship that has already been repaired earlier in this battle takes a further 15% less hull damage during the wall
New: a ship that has been repaired by a Command or a repair skill earlier in this battle takes a further 15% less hull damage during the wall

**Seveth T2b, Layers Shift**: H3, H11. The plan places the shift at the next round start; drops 'without losing the wall damage reduction' (nothing loses it).
Old: during the wall, at round end each ship may shift 1 hex toward the flagship without losing the wall damage reduction
New: during the wall, at the next round start each ship may shift 1 hex toward the flagship

**Nadir T1a, Restore from the Ninth Frame**: H1, H9. Drops the archived-state snapshot wording, which the pack vocabulary does not contain; the amounts were already the final text's.
Old: restore one ship from its archived state for the full repair amount, and every other ship receives half the normal swarm repair
New: restore one ship for the full repair amount, and every other ship receives half the normal swarm repair

**Nadir T3b, Every Copy Contributes**: H1, H9. The share divides evenly. (DeepSeek form.)
Old: the flagship repair share may be divided among any number of friendly ships
New: the flagship's repair share may be divided evenly among any number of friendly ships

**Nadir T3a, Restored Beyond the Original**: Scope split from Vesh T3a, which keeps any patched section: Nadir's plating applies to sections rebuilt from broken. (DeepSeek's split, applied as wording only.)
Old: a section rebuilt by the swarms carries the next iteration plating, gaining +20% section hull for the rest of the battle
New: a section rebuilt from broken by the swarms carries the next iteration plating, gaining +20% section hull for the rest of the battle

**Ostrel Cap1, Out of Every Shadow**: Names whose rear arc, and matches the tense of the not-targeted clause.
Old: the Command bonus covers two consecutive rounds for any ship that ends each round in a rear arc or not targeted that round
New: the Command bonus covers two consecutive rounds for any ship that ends each round in an enemy's rear arc or was not targeted that round

**Umbra Cap2, One Sun, Copied**: States whether range and arc apply to the copy: they do.
Old: every ship's volley is also copied onto the enemy with the least remaining hull, at half damage
New: every ship's volley is also copied onto the enemy with the least remaining hull, at half damage; range and arc apply to the copy as normal

## Capstone mastery texts (the 144)

Delivered in capstone_mastery_texts.md in this folder: 48 capstones x Mastery I, II and III, each line tied to the capstone's final effect after this pass, no new numbers (the build step that replaces the PR #306 placeholders owns the numbers). Four lines were adjusted at the merge to match adopted rewrite forms: Vex Cap2 (kill chain, rewritten outright), Malek Cap1 line I (one torpedo per ship), Maren Cap2 line I (ships in the flagship's line), Vesh Cap2 line I (restored to full).

## Chair notes for the remainder

- Full council, per Ryan's Nov 9 full-council rule: blind Rey (spine), DeepSeek and Qwen (writers), Flash and Grok (ideation). Argon blocked. DeepSeek was the strongest leg and supplied nine adopted forms (listed in the Rides on lines); Grok converged on the Grax boarding rows, the Maren Cap2 line dependency and the Chorus B1a numbers; Flash's trap list served as a merge checklist.
- Qwen's writer leg derailed: after a partial first section it invented a torpedo-counting exercise that appears nowhere in the pack, invented rows (an 'Aurelian' capstone), and truncated mid-sentence. Only chair-verified fragments were used (the Vex T1a +15% convergence, the Mending T2b convergence, its mastery pattern statement). Its sections 2 to 4 were discarded entire.
- Duplicate calls (plan section 7): Vex T3a and Umbra T2b are split by the Umbra rewrite (shared target pays there, unshared target pays here). Vesh T3a and Nadir T3a are split by wording scope only (Nadir: rebuilt from broken). Sable Cap2 and Ostrel Cap2 are kept as a shipped pair; both are bucket b and neither text was defective.
- Reyes T2a was the one ruling that flipped at the merge: the held wings strike at normal damage and the Command's bonus does not carry. The text now says so, which is what the plan asked for.
- The eclipse.md shield corrections cover every skill text in the file. The file's Changes lines keep their historical mentions of the removed shield mechanics; they are provenance for the Oct 29 draft fixes, not skill text.
- Grax renames: Ram First becomes First Over the Rail and Ram Rush becomes Rush the Rail. The Maw Opens is unchanged and stays a ram, per R145 question 3 A.
- Dace Vorn's Command is Interdiction strike in the finalized file already, and no Vorn skill text reloads torpedoes (verified line by line), so the done-when rename needed no edit in this file; the stray torpedo-reload wording lives in data.js and belongs to the build wiring step.
- Copying these final texts into data.js and wiring the rewrites into TREE_FX is the build step, as with the pilot (#312).
