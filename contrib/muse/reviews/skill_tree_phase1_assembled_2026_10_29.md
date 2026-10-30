# Skill tree Phase 1, assembled texts (Oct 29, 2026)

Status: COMPLETE. All six faction sections assembled from the three draft prongs in hand (DeepSeek, Qwen, Rey). The Argon draft prong (rate-limit retry) files separately as a fourth verbatim draft when it lands; see the assembly notes at the end.

What this is: the Phase 1 skill texts for the admiral leveling tree ruled Oct 28-29, 2026 (design: skill_tree_proposal_final_2026_10_28.md). Phase 1 scope: for each of the 24 admirals, Branch A tiers 1-3 with two picks per tier plus two capstone evolutions (Kassar was authored in the proposal itself and is carried over unchanged), and per faction the shared Branch B tier-1 pair and Branch C tier-1 pair. Total at completion: 216 texts.

Method: four-prong drafting (DeepSeek, Qwen, Argon, and a blind Rey leg), each working holistically from all six factions in one pack with current display names only. Chair assembly: the Rey draft is the primary text source where its picks pass the design rules; DeepSeek and Qwen picks replace individual slots where they are mechanically stronger. Every swap is noted on the admiral's provenance line. The three filed drafts are the record and are not edited: contrib/deepseek/reviews/tree_phase1_2026_10_29.md, contrib/qwen/reviews/tree_phase1_2026_10_29.md, contrib/muse/reviews/tree_phase1_rey_2026_10_29.md.

Assembly fixes applied throughout, from the chair screenings:
- Shared tier-1 sets that converged on one frame across factions (reserve entry; flagship reroll) were diversified per faction.
- Capstones built on the repeated chassis "use the Command a second time / without spending Command" were re-chassised or replaced; at most one such capstone survives per Command family.
- Loss-triggered catastrophe conversions were rescoped to banked, single-ship forms prepared before the loss.
- Pure numeric picks below the 15 percent floor, and standalone numeric picks on Branch A, were replaced with decision-changing mechanics.
- The cross-draft pattern of an "add one extra ship" Branch B pick in every faction was dropped; it reaches into fleet composition and the CP economy and is noted for Opus as a design question instead.

Rules in force (from the final proposal): Branch A authors against the primary Command only; every skill changes a decision; pure numeric only at 15 percent or stronger and at most one in three picks; nothing rewards losing, dying, or retreating (catastrophe conversion allowed); no duplication of the LEGACY doctrine effects.

## Sunward Crusade

### Admiral Roderic Vex (Sunward Crusade) - Command: Fire for effect
Branch A - The Inherited Line
T1: Ledger of Arcs - a ship firing its volley from a broadside arc may split that volley between two targets in the same arc. || Held in the Account - you may hold one ship's volley when the Command is declared and fire it after that ship moves this round.
T2: Named in the Ledger - before the volley, name one enemy; every ship may aim its volley at the named enemy even if another target is closer. || Inherited Aim - a ship that has not moved this round fires its volley at +15% damage.
T3: Every Gun Sworn - each ship chooses its own volley target freely, ignoring the best-target rule, and ships that choose the same target gain +10 aim against it. || Debt Comes Due - you may delay the whole volley to the start of next round, when it fires before any enemy ship acts.
Capstone: The Grand Ledger - once per battle, when Fire for effect is used, choose one enemy; every ship that can reach it fires, all damage is summed, and the target's shields are applied once to the total. || The Last Account - Fire for effect fires at the very start of the round, before movement, and each ship picks its own target.
Provenance: Rey draft, with the first capstone swapped to DeepSeek's summed-volley mechanic (a distinct payoff from the timing play in the second slot).

### Oath-Captain Malek Draven (Sunward Crusade) - Command: Hunter's salvo
Branch A - The Hunter's Ledger
T1: Prey Entered by Name - when the salvo begins, mark one enemy; torpedoes fired at the mark this round gain +15% damage. || Salvo in Two Hands - you may hold the damage bonus for up to half your ships and spend it next round instead of this one.
T2: Torpedoes Run First - during the salvo round, torpedoes resolve before all gun fire, so their kills open lanes for the fleet's guns. || Rear Arc Reckoning - during the salvo round, rear-arc hits from any weapon, not only torpedoes, gain the hunter-killer rear-arc bonus.
T3: The Debt Hunts - during the salvo round, a ship that lands a rear-arc hit immediately reloads one torpedo tube. || Two Salvos Sworn - the salvo's damage bonus also covers the first torpedo each ship fires next round.
Capstone: Salvo Without End - Hunter's salvo reloads all torpedoes a second time at the end of the round. || The Named Prey Falls - when the salvo is declared, choose one enemy; every torpedo in the fleet may retarget to it, and it takes +25% damage from all hits this round.
Provenance: Rey draft throughout.

### Commodore Sera Ashgrove (Sunward Crusade) - Command: Scramble all wings
Branch A - Wings on the Ledger
T1: Escort Sworn to a Name - an extra wing may be assigned as escort to one named friendly ship instead of striking, intercepting fire aimed at it this round. || First Wave Owes the Second - choose the launch order carrier by carrier; the last carrier to launch has its extra wing strike at +20%.
T2: The Account Splits - each extra wing may strike a different target than the rest of its carrier's wings. || Held in Reserve - you may keep one extra wing unlaunched; it launches free at the start of next round and strikes then.
T3: Every Generation Aloft - a carrier that has not moved this round launches one additional extra wing. || Wings Settle the Debt - an extra wing striking the same target as its carrier's guns gains +30% and is screened at half effect, once per carrier.
Capstone: The Sky Keeps the Ledger - Scramble all wings resolves in two waves in the same round: wings launch and strike, then the extra wings launch and strike again. || Oath of Open Sky - the extra wings stay launched when the Command ends and strike once more at the start of next round.
Provenance: Rey draft throughout.

### High Admiral Oryn Thale (Sunward Crusade) - Command: Iron wall
Branch A - The Iron Account
T1: Hold and Be Counted - a ship that does not move during Iron wall keeps the damage reduction for one extra round. || Shields Where the Debt Falls - you may move up to half of one ship's shield refill to a different ship before the wall resolves.
T2: Wall Declared Early - Iron wall may be declared at the start of the round, before any ship moves or fires. || Oath of Stillness - during Iron wall, a ship that holds its position refills its shields again at half strength at round end.
T3: Unpaid and Unbroken - during Iron wall, ships below half hull take 60% less hull damage instead of 40%. || The Wall Answers - while Iron wall is active, a ship whose shields are emptied by a hit fires its smallest weapon at the attacker, once per ship per battle.
Capstone: Iron Testament - Iron wall lasts two rounds, and shields refill again at half strength at the start of the second round. || The Wall That Sails - during Iron wall, your ships may move at full speed without losing the damage reduction.
Provenance: Rey draft throughout.

### Sunward Crusade shared tier-1 sets
Branch B T1: Sworn Deployment - after seeing the enemy deployment, place one of your ships anywhere in your deployment zone. || Debts in Reserve - hold one ship off the field; it enters at full strength at the start of round 2 at any edge of your deployment zone.
Branch C T1: Flagship Keeps the Ledger - once per battle, the flagship may order one other ship that has already fired to fire one weapon again at half damage. || Standard of the First Crusade - once per round, one ship within 2 hexes of the flagship may reroll a missed shot.
Provenance: Rey draft.

## Hegemony

### First Admiral Ilsa Kassar (Hegemony) - Command: Synchronized broadside
Branch A - Synchrony
T1: Wide Net - synchronized fire radius +1 hex. || Second Volley - the first synced target each round may be fired on by one additional ship out of arc.
T2: Shared Solution - synced ships share their best aim modifier. || Cold Drill - sync forms at round start even if the flagship has not moved.
T3: Rolling Fire - a kill by a synced ship lets another synced ship fire immediately, once per round. || Iron Tempo - sync survives the flagship's first crippling hit each battle.
Capstone: Living Relay - the flagship projects sync from its position at double radius, and sync no longer requires line of sight to the anchor. || One Voice - once per battle, every synced ship fires at one target simultaneously, resolving as a single combined strike.
Provenance: authored in the final proposal (skill_tree_proposal_final_2026_10_28.md) as the worked example; carried over unchanged. Note for implementation: her data doctrine is Fire discipline (data.js:217); the sync framing above is the ruled design layer for her tree, flagged in the naming QA synthesis (D1).

### Commodore Dace Vorn (Hegemony) - Command: Interdiction strike
Branch A - Filed Interdiction
T1: Target Filed in Triplicate - when the strike begins, file one enemy as the interdicted target; your hits on it gain +10 crit chance. || Strike by the Book - during the strike round, ships that fire in ascending speed order gain +15% damage.
T2: Cross-Referenced Fire - during the strike round, the second and later hits on the same target gain +15% damage. || Filed Before Movement - the strike may be declared before movement, and ships that move into range during the round keep the full bonus.
T3: Total Interdiction - during the strike round, your ships may split their fire freely, and any target hit by three or more ships takes +30% damage from every hit that round. || Standard Seven Breach - during the strike round, a critical hit also shuts down the struck section's weapons for one round.
Capstone: Interdiction, Permanent File - any target hit during Interdiction strike takes the strike's damage bonus again from all your fire next round. || One Order, Every Gun - Interdiction strike may be declared at the start of a round, and your ships fire before the fastest enemy ship that round.
Provenance: Rey draft throughout.

### Fleet Marshal Corin Reyes (Hegemony) - Command: Launch the strike group
Branch A - Strike Group Procedure
T1: Cruisers Filed as Carriers - during the launch, choose one cruiser; it launches a wing as if it were a carrier, in addition to the carriers' extra wings. || Launch Order Published - publish the strike order before launching; the first wing to strike gains +20%.
T2: Second Wave on Schedule - you may hold all extra wings and launch them at the start of next round instead, striking then at full effect. || Procedure Rehearsed - after the first strike resolves, each extra wing may be reassigned to a new target for its strike-again.
T3: Full Group Assembled - if every carrier launches an extra wing, each carrier launches one more, but all extra wings must strike the single filed target. || Registry of Escorts - extra wings may instead form a screen over your fleet, cutting enemy wing damage by 25% this round.
Capstone: The Group Flies the File - after the strike group resolves, all wings return and strike a second time at half damage. || Standing Strike Group - after the Command, one extra wing per carrier stays on patrol and strikes the first enemy that enters its carrier's range each round.
Provenance: Rey draft throughout. (Qwen's draft independently proposed cruiser launches and staggered waves; convergence noted, Rey text kept.)

### Line Admiral Oskar Maren (Hegemony) - Command: Shield wall order
Branch A - Column Standard
T1: Column Filed Straight - during the wall, ships in a line of three or more adjacent friendly ships refill +25% more shield. || Overflow by Regulation - during the wall, shield refill beyond a ship's maximum flows to the adjacent friendly ship with the lowest shields.
T2: Wall at the Bell - the wall may be declared at the very start of the round, before any ship moves or fires. || Standard Rotation - during the wall, a ship may swap hexes with an adjacent friendly ship without losing the damage reduction.
T3: The Column Endures - while the wall is active, the first ship each round to have its shields emptied immediately refills to 25%. || Filed in Armor - during the wall, a ship that does not fire this round reduces hull damage by a further 15%.
Capstone: Wall Without End of File - the wall lasts into next round, refilling shields again at half strength at its start. || The Anchor Holds the Standard - while the wall is active, half the hull damage the flagship would take is taken instead by the nearest friendly ship in its line.
Provenance: Rey draft throughout.

### Hegemony shared tier-1 sets
Branch B T1: Formation Filed Before Battle - choose one standard formation at battle start; ships that end their movement inside it gain +10 aim that round. || Drill Revision One - once per battle, after the enemy has moved, reposition one of your ships up to 2 hexes.
Branch C T1: Flagship Registry Beacon - once per round, the flagship may stamp one enemy; your ships gain +10 aim against the stamped enemy. || Standard Borne Forward - ships that move toward the flagship this round gain +1 movement.
Provenance: Rey draft.

## Ashfall Hullbreakers

### Warlord Grax Ironmaw (Ashfall Hullbreakers) - Command: Full burn
Branch A - The Scar Run
T1: Run at the Biggest Thing - ships that end their burn movement closer to the largest enemy than they started gain +15% damage this round. || Teeth First - a ship that moves at least 4 hexes during the burn may ram with no accuracy penalty.
T2: The Pack Closes - during the burn, your ships may pass through hexes held by friendly ships. || Boarding Rush - a ship that ends its burn movement adjacent to an enemy may board it immediately instead of firing this round.
T3: All Scars Forward - during the burn, a ship gains +1 movement for each enemy ship it passes adjacent to, up to +2. || The Maw Opens - during the burn, the first ram or boarding action by each ship deals +30% damage.
Capstone: Burn Until the Teeth Meet - Full burn's movement and accuracy protection carry into next round's movement phase. || The Warlord's Own Run - when Full burn is declared, the flagship may move twice, and may ram or board after each move.
Provenance: Rey draft throughout. Note: Boarding Rush and the boarding references in The Maw Opens propose a boarding action the current battle rules do not have; flagged for Opus as a new-mechanic decision, not assumed to exist.

### Sable the Smiling Knife (Ashfall Hullbreakers) - Command: Knife in the dark
Branch A - Scars Behind the Prey
T1: Knife Finds the Back - during the Command round, rear-arc hits gain +15% damage on top of the Command bonus. || Torpedoes in the Dark - torpedoes fired this round are screened at -20 effect, as if the firing ships were never seen.
T2: Cut and Turn - a ship that lands a rear-arc hit this round may turn once for free after firing. || Second Knife - torpedoes that miss this round reload one turn sooner than normal.
T3: The Smile Before the Cut - during the Command round, ships that begin their activation behind an enemy act before that enemy. || Every Knife at Once - if three or more of your ships hit the same target's rear arc this round, that target's weapons lose 20 accuracy next round.
Capstone: Dark Full of Knives - the Command's damage bonus also applies to the first shot each ship fires next round, if that shot comes from a rear arc. || The Cut That Feeds the Pack - when the Command is declared, every ship may immediately move 2 hexes toward the nearest enemy's rear arc.
Provenance: Rey draft throughout.

### Old Mott (Ashfall Hullbreakers) - Command: Release the swarm
Branch A - Junkyard Wings
T1: Patched Wing - choose one carrier; its extra wing is patched together from scrap, strikes at +25%, and is removed after its strike. || Hulk Holds More - one of your largest ships may launch an extra wing during the Command even though it is not a carrier, using its held wing space.
T2: Re-Tasked Mid-Flight - after the first strike resolves, each extra wing may switch to a new target for its strike-again. || Launched from the Wreck Line - carriers that did not move this round launch their extra wings at +15% damage.
T3: The Whole Yard Flies - every ship with any hangar space launches an extra wing during the Command, not only carriers. || Wings Come Back Screaming - the strike-again keeps the full +50% bonus even when it hits a new target across the field.
Capstone: Swarm Over the Scrap Field - Release the swarm launches the extra wings twice, once at the start of your turn and once at its end. || Old Mott's Private Wing - choose one carrier; its extra wing stays launched for the rest of the battle and strikes at half damage at the start of each round.
Provenance: Rey draft throughout.

### Vesh the Collector (Ashfall Hullbreakers) - Command: Patch and weld
Branch A - Scar Welding
T1: Weld What Matters - instead of spreading the repair evenly, you may put one ship's entire repair share onto its single most damaged section. || Patch Over the Guns - each repaired ship chooses where its repair lands first: weapon sections or engine sections.
T2: Scrap to the Front - you may take the flagship's repair share and give it to any one other ship, doubled. || Welded While Fighting - a section patched by the Command works at full effect in the same round it is patched.
T3: Armor Remembers the Shape - a section patched by the Command gains +20% section hull for the rest of the battle. || The Pack Bites On - a ship that the Command brings back above half hull gains +15% damage next round.
Capstone: Welded Whole - Patch and weld restores one destroyed section on every ship to full strength, not merely patched function. || Nothing Stays Broken - Patch and weld may be declared at the start of the enemy turn, landing before the first hit that would cripple one of your ships that turn.
Provenance: Rey draft throughout.

### Ashfall Hullbreakers shared tier-1 sets
Branch B T1: Prey Chosen by Scent - at battle start, name the pack's prey; your ships gain +10 aim against it. || Loose Pack, Wide Teeth - your ships never block each other's movement or firing lanes.
Branch C T1: The Flagship Takes the First Scar - once per battle, the flagship may take a hit aimed at an adjacent friendly ship onto itself. || Trophy Standard - after the flagship lands a kill, every friendly ship may turn once for free.
Provenance: Rey draft.

## The Chorus

### The Matriarch of Nine Throats (The Chorus) - Command: Spawning surge
Branch A - The Verse of Too Many Mouths
T1: Choose the Brood That Swells - one brood releases two extra swarms instead of one, and the other broods release none extra. || Spores on the Tide - extra swarms may be placed up to 2 hexes from their brood instead of adjacent to it.
T2: The Song Splits - each extra swarm may strike a different target than the rest of its brood's swarms. || Sung Before the Strike - spawning happens before your ships move, so the new swarms can screen your movement this round.
T3: Every Throat Opens - a brood that did not move this round releases one more extra swarm. || The Verse Bites Twice - a swarm striking a target already hit by another swarm this round gains +25% damage.
Capstone: Nine Throats, One Verse - Spawning surge releases an extra swarm from every ship that carries swarms, not only from broods. || The Song Does Not End - the extra swarms remain after the Command and strike once more at the start of next round before fading.
Provenance: Rey draft throughout.

### Razormaw (The Chorus) - Command: Blood frenzy
Branch A - The Hunting Verse
T1: Run Down the Slowest - during the frenzy, your ships gain +20% damage against targets slower than themselves. || Teeth at the Throat - a ship that ends its frenzy movement behind an enemy strikes that enemy's rear arc with its first shot this round.
T2: The Pack Sings One Prey - name one prey when the frenzy begins; ships moving toward the prey gain +1 movement. || Blood in the Water - during the frenzy, a ship may change targets freely after each kill without losing the frenzy's accuracy protection.
T3: Frenzy Feeds the Verse - a ship that lands a rear-arc hit during the frenzy may immediately move 2 more hexes. || Howl Before the Bite - during the frenzy, an enemy adjacent to two or more of your ships loses a further 20 accuracy.
Capstone: The Verse Turns Red - the frenzy's movement and accuracy protection last through next round, but only for ships that end this round adjacent to an enemy. || One Prey, Every Mouth - when the frenzy is declared, every ship may move directly toward the named prey, ignoring its turn limit once.
Provenance: Rey draft throughout.

### The Mending Throng (The Chorus) - Command: Regrowth tide
Branch A - The Mending Verse
T1: Grow Where It Hurts - you may assign one ship's entire regrowth to a single damaged section. || Skin Before Song - a ship may take its regrowth as temporary extra hull, up to +15%, instead of repairing damage.
T2: The Tide Comes Early - Regrowth tide may be sung at the start of the round, before any fire is taken. || Growth Remembers the Wound - a section healed by the tide regrows at double rate again next round.
T3: Flesh Knit for War - a ship the tide brings above three quarters hull gains +20% damage next round. || The Verse Refuses Holes - while any of your ships is below half hull, the most damaged ship regrows 10% at each round start until it passes half.
Capstone: Tide Without a Shore - Regrowth tide heals a second time at the end of the round, at half strength. || What Was Sung Grows Back - the tide restores destroyed sections to full function, and a section restored this way cannot be destroyed again this battle.
Provenance: Rey draft throughout.

### Voice of the Deep (The Chorus) - Command: Spitting volley
Branch A - The Acid Verse
T1: Acid Before Aim - each ship may spit its volley at the nearest enemy instead of the best target. || Every Throat Spits - a ship whose guns cannot bear may still spit once at half damage at the nearest enemy in range.
T2: The Burn Stays - an enemy hit by the volley takes acid damage at the start of next round equal to 15% of the volley damage it took. || Sung in Rounds - you may fire the volley in two halves, the second half after your ships move.
T3: Acid Finds the Seams - volley hits ignore armor on targets below half hull. || Chorus of Mouths - before the volley resolves, each ship may switch its target once; if four or more ships spit at one target, that target loses 20 accuracy next round as acid eats at its sensors.
Capstone: The Volley That Grows - after the volley, every ship that hit with its first spit spits again at half damage. || Mouth of the Deep - choose one ship; it spits with every weapon it carries, twice, at any single target in range.
Provenance: Rey draft throughout.

### The Chorus shared tier-1 sets
Branch B T1: Verses Assigned at Hatching - at battle start, give each ship a verse (strike, screen, or mend); a ship may change its verse once per battle. || Broods in Reserve - hold one brood off the field; it enters, grown and ready, at the start of round 2.
Branch C T1: The Flagship Sings First - once per battle, one other ship may act immediately after the flagship finishes its activation. || Throat of the Deep Song - ships within 2 hexes of the flagship gain +10 aim.
Provenance: Rey draft.

## The Glasswrights

### Tamsa of the Clear Aperture (The Glasswrights) - Command: Starling flight
Branch A - Recorded Flight
T1: Flight Paths in the Glass - record each extra wing's strike path before launching; a wing that follows its recorded path exactly strikes at +15%. || Cast Twice in Light - one carrier's extra wing strikes, is recorded, and strikes the same target again at half damage if that target has not moved.
T2: The Replay Corrects - after the first strike resolves, each extra wing may be retargeted freely for its strike-again, using what the glass recorded. || Starlings in Formation - extra wings that strike in the same order as their carriers are arranged gain +10 aim.
T3: Flaw in the Flight Removed - extra wings ignore the point defense of one chosen enemy ship for this Command. || Every Lens Aloft - a carrier that held still this round launches one extra wing whose strike is also recorded for next round.
Capstone: Flight Remembered Perfectly - the extra wings strike three times: the recorded strike, a corrected strike at full effect, and a final strike at half damage. || The Forge Casts Ahead - after the Command, one extra wing per carrier stays aloft and repeats its recorded strike at the start of next round.
Provenance: Rey draft throughout.

### Saro of Long Focus (The Glasswrights) - Command: Burning glass
Branch A - Long Focus
T1: Focus Drawn Long - volley shots at targets beyond half the firing ship's range gain +20% damage. || One Lens, One Target - a ship may fire its volley as a single shot at +25% damage instead of firing every gun.
T2: Light Arrives Together - you may hold the volley until all your ships have moved, and fire lance shots in any order you choose. || The Recorded Angle - before the volley, each ship may turn once to bring its best lance to bear.
T3: Burning the Flaw Out - volley hits on one target stack; the third and later hits on that target ignore its shields. || Long Light - lance weapons in the volley gain +2 hexes of range.
Capstone: Sun Through One Lens - Burning glass may concentrate every ship's volley on one target, resolving as a single combined strike that ignores range penalties. || The Flaw, Corrected Forever - after Burning glass, your lances keep +15% damage against the target the volley hit most, for the rest of the battle.
Provenance: Rey draft throughout. (DeepSeek's summed-strike idea appears here in Rey's own form and in Vex's swapped capstone; the two are deliberately different in scope, fleet-wide once per battle versus the volley target.)

### Vell of the Third Mirror (The Glasswrights) - Command: Scatter the light
Branch A - Refraction
T1: Two Images Appear - during the scatter, the first enemy shot at each of your ships each round is aimed at a false image and loses a further 20 accuracy. || Angles Recorded - a ship that ends its scatter movement facing a different direction than it started gains +10 evasion until next round.
T2: The Mirror Steps Aside - during the scatter, a ship may pass through one enemy-held hex without stopping. || Light Split Three Ways - during the scatter, a ship may split its movement, half before it fires and half after.
T3: Refraction Deepens - during the scatter, a ship that moves its full distance cannot be targeted by weapons fired from beyond range 6 until next round. || Every Mirror Turns - at the end of scatter movement, every ship may face any direction at no cost.
Capstone: The Fleet Is Elsewhere - Scatter the light may be declared after the first enemy ship fires; your ships move immediately, interrupting the enemy turn. || A Hundred False Hulls - during the scatter round, the first two enemy volleys fired each round are wasted on false images.
Provenance: Rey draft throughout.

### Brin of the Fourth Lens (The Glasswrights) - Command: Prism ward
Branch A - Prism Recasting
T1: Light Bent to the Weak Side - you may give one ship's shield refill to the friendly ship with the lowest shields instead. || Prisms Face the Fire - a ship facing its nearest enemy refills +25% more shield during the ward.
T2: Recharge While Lit - during the ward, shields recharge a second time at round end, at the prism recharge rate. || The Lens Rotates - during the ward, a ship may change its facing after moving without losing the damage reduction.
T3: Flaw in the Glass Corrected - while the ward is active, the first ship whose shields fall to zero refills to 15%, once per battle. || Hard Light - during the ward, a ship's remaining shields also block the first section damage it would take.
Capstone: Ward of Clear Glass - Prism ward lasts two rounds, and shields refill again at the start of the second round. || Every Facet Lit - during the ward, shield strength refilled beyond a ship's maximum becomes temporary hull of hard light, up to +20%.
Provenance: Rey draft throughout. (Qwen's oversized-hit splitting for Brin was the strongest single Qwen mechanic in this family; it is not in the assembled text because it changes how damage is allocated across ships, a rules decision for Opus. It is preserved in the filed Qwen draft and flagged here.)

### The Glasswrights shared tier-1 sets
Branch B T1: Deployment Read from the Shards - after seeing the enemy deployment, reposition one of your ships anywhere in your deployment zone. || Casting Corrected Before Battle - after deployment, swap the positions of any two of your ships.
Branch C T1: The Flagship Lens - once per round, the flagship may focus one enemy; your lance shots against it gain +10 aim. || First Light Recorded - the flagship records the first enemy ship that fires each battle; your fleet gains +10 evasion against that ship for the battle.
Provenance: Rey draft.

## Eclipse

### Nadir Aurex, Ninth Frame (Eclipse) - Command: Release the repair swarms
Branch A - Iteration of the Whole Hull
T1: Restore from the Ninth Frame - restore one ship from its archived state for the full repair amount, and every other ship receives half the normal swarm repair. || Copies Triage the Damage - assign the repair section by section in any order you choose; a section restored to full also clears all of its damage effects.
T2: Iteration Runs During Fire - a ship being rebuilt by the swarms may act normally this round; the rebuild never delays its fire. || The Archive Answers First - the swarms may be released at the very start of the round, before any ship moves or fires.
T3: Restored Beyond the Original - a section rebuilt by the swarms carries the next iteration's plating, gaining +20% section hull for the rest of the battle. || Every Copy Contributes - the flagship's repair share may be divided among any number of friendly ships.
Capstone: Tenth Frame - the repair swarms rebuild every ship a second time at the end of the round, at half strength. || The Earlier Iteration Returns - choose one damaged ship; it is restored to the exact state the Archive recorded for it at this battle's start, sections and all.
Provenance: Rey draft throughout.

### Umbra Vessane, Third-Housed (Eclipse) - Command: Noon volley
Branch A - Corona Iteration
T1: Arcs Written Bright - a volley hit from a corona arc splashes 25% of its damage onto one enemy adjacent to the target. || Noon Is a Choice - you may fire the volley at the start of the round, before movement, at +15% damage.
T2: The Copy Fires Again - a ship whose volley destroys its target may fire one weapon at a new target. || Light Archived Mid-Flight - before the volley resolves, each ship may switch its target once.
T3: Corona Without Shadow - the volley ignores evasion granted by terrain and cover. || Every Frame at Noon - a ship that did not move fires its volley twice, the second time at half damage.
Capstone: Noon That Does Not Pass - Noon volley fires again next round, at half damage, from every ship. || One Sun, Copied - every ship's volley is also copied onto the enemy with the least remaining hull, at half damage.
Provenance: Rey draft throughout.

### Ostrel of the Long Copy (Eclipse) - Command: Out of the shadow
Branch A - The Long Copy's Hunt
T1: Copied from Behind - during the Command round, rear-arc hits gain +20% damage on top of the Command bonus. || Never Filed as a Target - during the Command round, a ship that was not targeted last round gains a further +15% damage.
T2: The Shadow Is a Position - the Command round may be declared after movement, once you can see where your ships stand. || Strike the Uncopied Target - during the Command round, hits on an enemy that has not yet been hit this battle gain +15%.
T3: Iteration of the Kill - during the Command round, when one of your ships lands a rear-arc hit, the next hit on that target this round gains +20%. || Silent in the Archive - during the Command round, enemy accuracy against your ships falls by 10 until next round.
Capstone: Out of Every Shadow - the Command's bonus covers two consecutive rounds for any ship that ends each round in a rear arc or unobserved. || The Long Copy Strikes - when the Command is declared, each ship may first move 2 hexes toward an enemy's rear arc.
Provenance: Rey draft throughout.

### Seveth, Twice-Restored (Eclipse) - Command: Sunshade wall
Branch A - Layered Iterations
T1: Plates over Light - you may convert up to half of one ship's shield refill into hull plating that lasts the rest of the battle. || The Twice-Restored Order - a ship that has already been repaired earlier in this battle refills +25% more shield during the wall.
T2: Wall Filed in Advance - the wall may be declared at the start of the round, and its reduction applies from the first enemy shot of the round. || Layers Shift - during the wall, a ship may pass up to a quarter of its current shields to an adjacent friendly ship.
T3: No Layer Falls Alone - while the wall is active, the first time each ship's shields reach zero, its layered plates absorb the hit that emptied them. || Stillness in the Copy - during the wall, a ship that does not move keeps the damage reduction for one extra round.
Capstone: Wall of Ten Thousand Copies - Sunshade wall lasts two rounds, and shields refill again at half strength at the start of the second round. || The Restored Fleet - while the wall is active, shield refill beyond a ship's maximum overflows into the next friendly ship's shields.
Provenance: Rey draft throughout.

### Eclipse shared tier-1 sets
Branch B T1: Formation Loaded from Archive - choose one archived formation at battle start; ships that end their movement inside it gain +10 evasion that round. || Iteration Swap - once per battle, swap the positions of two of your ships, as the Archive substitutes a corrected version of the plan.
Branch C T1: The Flagship Hosts the Index - once per round, the flagship may copy another friendly ship's target and fire at it at +15%. || Frame Zero - the flagship's first missed shot each battle is recorded and fired again at half damage.
Provenance: Rey draft.

## Assembly notes for Opus

- Two proposals in the assembled text reach beyond current mechanics and need a technical decision rather than a text edit: boarding (Ironmaw Branch A) and cross-ship damage splitting (noted at Brin, held in the Qwen draft rather than assembled).
- The dropped cross-draft pattern (an extra-ship Branch B pick in all six factions, from the Qwen draft, echoed in DeepSeek's reserve frames) is recorded here as a design question: whether any tree pick may touch fleet composition at all.
- The Argon draft prong, when it lands, files as a fourth verbatim draft. If it contains picks stronger than the assembled text, treat them as an addendum source; the assembled text above is the chair's recommended Phase 1.
