# Faction shape and roster expansion design review - Rey leg (Oct 29 program)

Blind leg written from the evidence pack and direct code reads at main 264f441d only.

## 1. Proof of reading

Pack sections read: the EVIDENCE PACK title line ("faction shape and roster expansion design review"); THE COMMISSIONER'S QUESTION; the RULINGS AND FACTS IN FORCE and CHAIR CENSUS material (faction identities, the Oct 29 battleship ruling, roster counts, CP ladders, the verified duplicates list); WHAT TO JUDGE (items 1 to 5); and the code slices: data.js 61-131 (HULLS, MOVE_RULES, FACTIONS), data.js 538-544 (FAC_PRICE, FAC_GATES), battle.js 139-165 (genEnemyFleet), and core.js 330-336 (cpCap growth). Code reads beyond the pack, all at the same pin: effArch (battle.js:138), the RAMP table (battle.js:136), the hull cost fallback and FAC_PRICE application loop (data.js:544-546), runDefaults and newRun cpCap (core.js:66, 324), and genSector's column count (core.js:251).

Overall verdict: SHAPES PARTIAL - the six shapes are real in stats, movement rules and credit prices, but the one currency that limits fleet size (CP) is flat where shape should speak loudest, and the designer's newest ruling is mispriced by a missing table key.

## 2. Findings

1. [BLOCKER] The ruled Eclipse battleship prices below its own cruiser. READ: FAC_PRICE for deathless is {Frigate:1.45, Destroyer:1.5, Cruiser:1.55} with no Battleship key, and the application loop defaults a missing class key to 1 ("(FAC_PRICE[fid]||{})[h.cls]||1"). READ: hull cost falls back to round((60*cp+10)/5)*5, so a cp6 battleship costs 370 credits at the default multiplier while the cp4 cruiser costs 390 after its 1.55 multiplier. The elite faction's price ladder inverts at exactly the hull the Oct 29 ruling added. Any battleship design is broken until a Battleship key (about 1.6) exists.

2. [BLOCKER] CP, the only fleet-size currency, is symmetric at the ladder bottom where most ships live. READ: all six frigates cost 1 CP and all six destroyers cost 2 CP. READ: genEnemyFleet spends a CP budget only; FAC_PRICE never enters enemy generation, so credit asymmetry shapes the player's shopping and nothing else. Elite versus swarm therefore exists in stats and in player credits, and is invisible in the currency that decides how many hulls take the field. The roster screen's CP column reads identically across factions.

3. [FIX] Stats per CP already bend shape, and nothing prices the bend. READ: at 1 CP the Eclipse frigate carries hp 56, armor .2, regen 3 and reanimate; the Chorus frigate at the same 1 CP carries hp 46, armor .05, regen 4 and no reanimate. READ: RAMP.light weights (4 in sector 2, 5 in sector 3) push enemy budgets toward 1 to 2 CP hulls, exactly where the per-CP gap is widest. INFERRED: equal-CP enemy fleets are not equal threat, the generator has no term that can see this, and the imbalance grows as sectors push fleets lighter.

4. [FIX] The Eclipse boss breaks its own faction's defining trait. READ: d_scythe, d_jackal and d_harvester all carry reanimate:true; d_boss does not, making the Tomb-ark the only Deathless hull that does not rebuild itself. READ: its gun kit is the cruiser's kit recycled (two gauss turrets and a doom prow gun), with flak swapped in for the gsentry. The showcase hull of the elite attrition faction is the one hull in the faction that cannot do the faction's thing.

5. [FIX] The board ceiling silently defeats any swarm discount. READ: genEnemyFleet caps the enemy list at RAMP.ceil for the sector (14 in sector 2, 20 in sector 3) minus living player ships, and the RAMP comment calls that ceiling "a soft ceiling for performance, not a design cap". INFERRED: once the ceiling binds, cheaper swarm hulls convert into heavier hulls rather than more hulls, so CP or budget discounts make the Chorus taller, not wider. Swarm asymmetry has to be negotiated with the ceiling, not just with prices.

6. [FIX] The shared 1 CP frigate slot is bought with duplication. READ: warden and h_picket share shields 10, range 5, armor .1, speed 5, turn 3, a flak turret and the evasive ability; the entire difference is 5 hp, 2 evasion and autocannon versus laser. Two of six factions open with the same ship wearing different paint, at the slot every player reads first.

7. [NOTE] Hegemony's ruled identity has no hull-level expression in these slices. READ: both Hegemony line capitals spend kit on token hangars (h_vanguard hangar:1 with the launch ability on a cruiser, h_dominion hangar:1), and no Hegemony hull in the table carries an anchor or link mechanic, though the faction is ruled as "synchronized fire under a flagship anchor". INFERRED: the anchor may live in battle code outside these slices; inside the roster table, Hegemony reads as the carrier faction it is not supposed to be.

8. [NOTE] Player-side CP pressure is front-loaded only. READ: cpCap starts at 10 and at sector transitions becomes "RUN.cpCap=Math.max(RUN.cpCap, fleetCP()+3)", so the cap rises to fit whatever fleet the player already owns. INFERRED: CP asymmetry aimed at the player binds in sector 1 and then chases the fleet; by sector 3 the binding constraints are credits and the board ceiling, not CP.

9. [NOTE] The Chorus's second identity verb is unbuilt in the hull table. READ: the faction is ruled as "a swarm that feeds and grows", and every Chorus hull carries regen, but no Chorus hull in the table converts kills, damage or time into growth; frenzy on b_razor is the only aggressive verb. The swarm knits, which the table supports, but it does not feed.

10. [NOTE] If CP ever bends, integer steps are the only safe unit. READ: the generator buys whole hulls in a loop guarded by "while(budget>=1" with options filtered at cp at or below budget + .3. INFERRED: fractional hull costs (a 0.75 CP drone) strand remainders the loop can never spend and interact badly with the + .3 option filter; bending the ladder by whole CP steps avoids the arithmetic entirely.

## 3. Explicit checks

### Check 1: NEW HULLS

Two additions, one of them ruled, and an argument against the rest.

(a) Eclipse battleship (ruled Oct 29; elite attrition, no carrier). Design against the pack tables: cp 6, size 1.02, hp 240, shields 0, regen 6, armor .35, speed 1, turn 1, evasion 0, weapons gauss T, gauss T, doom F, gsentry T, reanimate:true, slots 3. It sits above the cp4 cruiser the way h_dominion (cp6, hp 230) sits above h_vanguard, and below the cp12 boss. Its job is to be the hardest hull in the game to permanently remove per CP spent against it: 240 hp behind .35 armor, 6 regen a round, and one reanimate, where d_boss currently fails the same test. Ability: do not recycle the cruiser's reclaim; give it a rebuild aura (Deathless allies within 2 hexes gain +2 regen), marked INFERRED as a proposal, because every other faction's top line hull carries a distinct ability and a second reclaim hull blurs the cruiser. Price: requires the Finding 1 fix, a FAC_PRICE deathless Battleship key at about 1.6, giving about 590 credits. INFERRED: with reanimate restored to the line's top, d_boss should also regain reanimate or the boss stays the faction's one non-rebuilding hull.

(b) Chorus heavy cruiser, cp 4 (cls Cruiser, FAC_PRICE chorus Cruiser is 1, so about 250 credits): hp 185, shields 0, regen 7, armor .2, speed 3, turn 1, weapons tendril T, bioplasma F, bioplasma F, ability frenzy. The gap is real and generator-visible: in the heavy archetype the Chorus tops out at the cp3 razor, because its cp5 top hull is a carrier, so Chorus heavy fleets have no heavy gun hull. This gives the swarm a non-carrier heavy option and a cp4 rung its ladder currently skips (1-2-3-5).

Against the rest: no Ithar cp3 (a few-and-fast faction does not need ladder filler, and its 1-2-4-5 spacing is its shape), no new Hegemony hulls (four hulls plus boss is the cleanest enemy read in the game, and the cp gaps are the point of a top-heavy navy), nothing for Corsairs (a complete 1-2-3-4 ladder with a carrier top that fits a raider mothership), nothing for the Crusade (the only complete 1-2-3-4-5 ladder). New hulls argued from jobs: two. Everything else is symmetry shopping.

### Check 2: CLASS DIFFERENTIATION

Keep the frigate, destroyer, cruiser spine shared in every faction. Those three classes are the game's tutorial language: a new player who learns what a destroyer is in one faction can read five others, and the enemy generator's archetype filters lean on the same rungs. The differentiation should live, and mostly already lives, at the top and in the CP spacing: Chorus and Corsair and Ithar top out at carriers, Hegemony and the Crusade at battleships, Eclipse at the ruled battleship and never a carrier (already enforced in code, READ: effArch remaps a carrier archetype roll to heavy for any faction with no launch hull). The CP ladders already break step in four different rhythms (1-2-3-4-5, 1-2-4-6, 1-2-3-5, 1-2-4-5, 1-2-4 becoming 1-2-4-6); that spacing is differentiation a player can feel without relearning class names. Readability cost of the existing divergence, READ from the tables: class name no longer predicts hangar (h_dominion is class Battleship with hangar:1, b_brood is class Carrier at cp5 while c_hulk is class Carrier at cp4), so the roster row must always show hangar count explicitly. That is a one-column cost and it is already owed. I would make no further ladder breaks; a faction with two cruisers and no battleship, for example, buys a novelty and pays for it in every archetype filter and every player's mental model.

### Check 3: CP ASYMMETRY

Worked example, one sector 2 fight each way. READ from the pack and code: the sector 2 base budget is 9.5 plus the column (0 to 6 across 7 columns), times RAMP.grow 1.24; at the middle column that is (9.5+3) x 1.24 = 15.5 CP before power scaling, and at reference fleet power the power factor is 1. The enemy list is capped at 14 minus living player ships; assume a 5-ship player fleet, so at most 9 enemy hulls.

Universal CP (as built): a Chorus fleet spends 15.5 CP under light weights of 4 and fields about 9 hulls, ceiling-bound, mostly drones and spitters with a razor or two. An Eclipse fleet spends the same 15.5 CP and fields about 6 to 7 hulls (a harvester, jackals, scythes). The board already shows a shape difference of roughly 9 versus 7, produced by roster composition and weights, not by CP.

Shape-bent CP (hull costs bent in the generator, Chorus x 0.75, Eclipse x 1.5): the Chorus budget buys about 20 CP of hulls but still fields 9, because the ceiling binds; the surplus converts into razors and a brood-sac, so the swarm becomes a medium fleet and the bend inverts its own intent. The Eclipse budget buys about 10 CP of hulls: a harvester, a jackal and a scythe, 3 to 4 hulls on the board. The bend works exactly once, on the elite side, where fewer ships is the goal.

Judgment: do not bend hull CP. Bend the two things that actually bind. For the swarm, the ceiling: if the Chorus is meant to outnumber, genEnemyFleet's ceiling has to be faction-aware (the Chorus fights under a higher hull ceiling), because no price mechanism can put a tenth hull past a nine-hull cap. For the elite, nothing needs bending at all in the generator, because Finding 3 cuts the other way: Eclipse hulls are already stronger per CP, so if anything the generator owes the player a small Eclipse budget trim (about 0.85x, INFERRED, sims to confirm) to keep equal-CP fights equal-threat. Player side: keep CP universal there too, and let the priced proposal in check 4 carry the elite feel without touching the shared currency.

### Check 4: ELITE VERSUS SWARM, PRICED

As built (READ, costs computed from the fallback formula and FAC_PRICE): the frigate row reads Chorus drone 1 CP / 45 credits (hp 46, armor .05, regen 4, one tendril) against Eclipse scythe 1 CP / 100 credits (hp 56, armor .2, regen 3, reanimate, one gauss). Credits already say elite versus swarm at 2.2 to 1; CP says nothing. The destroyer row: spitter 2 CP / 100 credits against jackal 2 CP / 195 credits, same story.

What I would change, so the roster screen alone teaches the shape:

- Eclipse frigate: CP 1 to 2, hp 56 to 64, regen 3 to 4. Its cost follows the formula to about 190 credits. The first row of the Eclipse roster then reads 2 CP / 190 credits against the drone's 1 CP / 45: a starting Eclipse fleet at the 10 CP cap is five hulls, a starting Chorus fleet is ten, and nobody needs a tooltip to feel it.
- Eclipse destroyer: CP 2 to 3 (hp 110 and armor .25 was always rich for 2 CP next to the spitter's 82 and .1). The Eclipse ladder becomes 2-3-4-6, visibly compressed against the Chorus 1-2-3-5.
- Chorus: no CP change to any hull. Instead the Chorus gets the ceiling allowance from check 3 (its fleets, player and enemy, may field up to 3 more hulls than the shared ceiling), because width is the swarm's whole claim and CP discounts cannot deliver width.
- Add the missing FAC_PRICE deathless Battleship key at about 1.6 (Finding 1) so the top of the elite ladder prices like the rest of it.

INFERRED risks, stated plainly: Eclipse sector 1 enemy budgets (about 5 to 10 CP after growth) would field 2 to 4 hulls, which concentrates fire and may spike early difficulty; the RAMP table was tuned against the current ladders, so this change is a sims-first change, not a ship-it change. The alternative of leaving frigate CP alone and letting credits carry the whole signal is defensible, and it is the fallback if sims reject the CP step.

### Check 5: THE RISK CASE

Strongest case against all of this: the roster already has 48 hulls counting variants and carries verified duplicates the audits keep tripping over; every added hull multiplies variant surface, archetype interactions, Godot port work and balance load, and the RAMP numbers were tuned in October against the current ladders, so any CP or ladder change reopens a balance settlement that cost real sims to reach. Asymmetric CP additionally breaks the one number the player, the shipyard, the prize screen and the enemy generator all share, and the board ceiling already controls the thing CP asymmetry claims to control, which is how many ships are on the board. On that argument the correct program is: fix duplicates, add nothing, bend nothing.

Ruling: the risk case beats broad expansion and beats hull-CP bending, and my own checks 1 and 3 concede both points (two new hulls argued from jobs, not six factions times a new rung; hull CP stays universal). It does not beat the battleship, because the Eclipse ladder hole is not symmetry shopping: Eclipse tops out at cp4 against every other faction's cp5 or cp6 top hull, the designer has already ruled the hull in, and Finding 1 shows the pricing table actively punishes it. And it does not beat the ceiling observation, because the ceiling is the mechanism that decides whether "swarm" is a fact or a flavor word. Net: build the battleship and the Chorus heavy cruiser, fix the price key, leave CP alone, and let the ceiling carry the swarm.

## 4. Not checked

- The 18 variant hulls (not in the pack's slices); variant-level duplication or ladder effects are out of scope for this leg.
- Battle resolution code: how armor, regen, reanimate and evasion convert table stats into actual time-to-kill, so all per-CP threat comparisons here are table arithmetic, not measured combat outcomes.
- Admiral, boon, module and relic interactions with hull choice (the pack carries none), including whether any admiral already bends CP or fleet size.
- The player starting fleets per faction beyond the cpCap facts read in core.js, and equivHull's mapping of starter hulls across factions.
- The Godot port's roster and generator code; all generator claims are from the browser build the pack pins.
- Playtest or simulation evidence for the proposed numbers in checks 1, 3 and 4; each is marked INFERRED where it appears and needs sims before adoption.

## 5. Questions for the designer

1. Is the roughly 20-ship board ceiling a design cap or only a performance cap (the code comment says performance)? Stakes: if it is a hard design cap, Chorus width must come from wings, respawns and the ceiling allowance in check 3, and no pricing change can ever make the swarm outnumber anyone.
2. Should the Eclipse battleship price at the top of the faction's credit ladder (a new FAC_PRICE Battleship key near 1.6, about 590 credits) or is a cheaper-than-cruiser battleship an acceptable accident? Stakes: as built it costs 370 against the cruiser's 390, and the inversion ships the moment the ruled hull lands.
3. At equal CP, should an Eclipse fleet and a Chorus fleet be equal threat, or is Eclipse allowed to be stronger per CP as the elite fantasy itself? Stakes: this decides whether the stats-per-CP gap in Finding 3 gets priced (a generator budget trim for Eclipse) or protected as the identity, and every later balance pass inherits the answer.
