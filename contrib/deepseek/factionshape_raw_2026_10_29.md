Chair note: filed verbatim from the DeepSeek DeepThink run of Oct 29, 2026 (toggles verified on; first chat attempt hung in generation and was abandoned, second chat completed), except em dashes in the model's text are normalized to hyphens.

Proof of reading

Sections read: EVIDENCE PACK title line; THE COMMISSIONER'S QUESTION; RULINGS AND FACTS IN FORCE (the chair-verified census); WHAT TO JUDGE; code slices data.js 61-131 (HULLS, MOVE_RULES, FACTIONS, SECTOR_POOL), data.js 538-544 (FAC_PRICE, FAC_GATES), battle.js 139-165 (genEnemyFleet), core.js 330-336 (CP cap growth).

Verdict: SHAPES PARTIAL. The factions already differ in credit price, movement rules, gates, and shield/armor profile, but Eclipse lacks its ruled battleship, the roster has verified duplicates, and CP is universal while credits are asymmetric - the roster screen tells two different stories.

Findings

[BLOCKER] Eclipse's ladder is 1-2-4 and has no heavy anchor. The ruled battleship is the right fix, but it must be elite (high HP/armor, regen/reanimate, no hangar - "Eclipse gets NO carrier, ever, by ruling"). [READ]

[BLOCKER] The two 1-CP frigates are "near-identical" (warden hp45/sh10/ev20/autocannon vs h_picket hp40/sh10/ev18/laser). Fix by differentiation, not addition. [READ]

[FIX] Both Hegemony line ships carry "token hangars" (h_vanguard and h_dominion both ab:'launch', hangar:1). Strip or commit; the half-measure flattens the "synchronized fire" identity. [READ]

[FIX] CP is universal - "1 CP buys the same slot of budget in every faction" - while FAC_PRICE is asymmetric (Chorus 0.65, Eclipse 1.45-1.55). The credit price says elite/swarm; CP says identical. [READ]

[FIX] genEnemyFleet uses HULLS[id].cp directly; any CP asymmetry must be applied there or enemy fleets will be mispriced (Chorus ~30% small, Eclipse ~50% large under the multipliers I propose). [READ/INFERRED]

[NOTE] Boss hulls "recycle carrier and cruiser kits" (c_boss hangar:2, b_boss hangar:3, h_boss nova). Not a blocker, but boss identity is thin. [READ]

[NOTE] Eclipse and Chorus are both shieldless (sh:0) but differentiate by armor (Eclipse .2-.35) vs evasion/speed/regen (Chorus ev8-15, sp4-5, regen4-20). That is a real shape difference CP should reflect. [READ]

[NOTE] Ithar already breaks the shared ladder: no battleship, carrier at cp5, boss is an "Ark." Precedent for allowing breaks. [READ]

[NOTE] The 20-ship cap is "designer leaning, not locked"; under CP asymmetry the hull cap binds for the swarm (20 Chorus frigates at 0.7 = 14 CP) but never for Eclipse (20 at 1.5 = 30 CP). [INFERRED]

[NOTE] Voidsworn is the only faction with a full 5-slot ladder (1-2-3-4-5); every other faction already has a gap. The "shared ladder" is already not shared. [READ]

Explicit checks

1. NEW HULLS

I would add none beyond the ruled Eclipse battleship. The audit's duplicates are a differentiation problem, not a hull-count problem; the Hegemony token hangars are a commitment problem, not a missing hull; Corsair/Ithar/Chorus already have the top-end hull their identities need (carrier for Corsair and Chorus, ark for Ithar). The Eclipse battleship fills the one real job gap: a durable, self-rebuilding anvil for an elite attrition faction.

Eclipse battleship (proposed "Eclipse Nadir-class battleship"): cls:'Battleship', fac:'deathless', cp:6 (base; effective 9 under a 1.5x elite multiplier), hp:280, sh:0, rg:0, ar:.35, sp:1, tn:1, ev:0; w:[['gauss','P'],['gauss','S'],['doom','F'],['flak','T']] - no hangar, per the ruling; ab:'reclaim', regen:5, reanimate:true. Credit price at the deathless multiplier (~1.6x) would be roughly 545 against the Voidsworn cathedral's 340; mark INFERRED because non-Voidsworn base costs are not in the pack. Job: park it on an objective; it grinds, rebuilds, and forces the enemy to commit. It is slower than the d_harvester (sp1 vs sp2) and has no evasion (ev0) - the opposite of the Chorus's fast, evasive, regenerating swarm.

2. CLASS DIFFERENTIATION

Yes, break the ladder at the top end, sparingly. Breaks I would make:

Eclipse: no carrier (ruled). Ladder becomes frigate-destroyer-cruiser-battleship-boss. Readability cost: low, because the ruling is explicit.

Hegemony: no dedicated carrier; strip the token hangars and make it a pure gun line (frigate-destroyer-cruiser-battleship). Readability cost: moderate - players expecting a carrier slot must learn the Hegemony has no air wing.

Chorus: top hull is the carrier (b_brood cp5), not a battleship. Readability cost: low-moderate.

Corsair: no battleship; top is carrier (c_hulk cp4). Readability cost: low.

Ithar: no battleship; top is carrier (i_carrier cp5). Readability cost: low.

The shared frigate-to-cruiser spine (1-2-3 or 1-2-4) is worth keeping for readability. Identity lives at the top slot - battleship vs carrier vs ark. That is where the breaks should be.

3. CP ASYMMETRY

Keep the integer hull table but add a faction CP multiplier applied at fleet-building time (one system change, not per-hull edits). Proposed: Eclipse 1.5x, Chorus 0.7x, all others 1.0x; exclude bosses (their CP is already faction-tuned at 8-12).

Sector 2 fight (budget ≈ 9.5 CP from the formula, assuming col 1 and RAMP.grow[2] = 1; mark INFERRED because RAMP values are not in the pack):

Universal CP: Chorus 9 frigates (9 CP) vs Eclipse 9 frigates (9 CP). Board: 9 vs 9, but each Eclipse hull has ~1.2-1.5x the HP and ~4x the armor.

Bent CP: Chorus 9.5/0.7 ≈ 13 frigates (13 ships) vs Eclipse 9.5/1.5 ≈ 6 frigates (6 ships). Board: 13 vs 6.

Consequences: the swarm outnumbers ~2:1, which is the point. The 20-ship cap binds for Chorus at 14 effective CP (20 × 0.7); Eclipse never hits it (20 × 1.5 = 30 CP). So the swarm's late-game growth is capped by hull count, while the elite is always CP-limited. That is a healthy asymmetry, but it means the hull cap should be treated as a per-faction tuning lever, not a single global number. genEnemyFleet must apply the multiplier (finding 5) or enemy Chorus fleets will be ~30% too small.

4. ELITE VERSUS SWARM, PRICED

As built:

d_scythe: cp1, hp56, sh0, ar.2, sp4, ev14, regen3, reanimate, gauss, credit 1.45x.

b_drone: cp1, hp46, sh0, ar.05, sp5, ev15, regen4, tendril, credit 0.65x.

d_jackal: cp2, hp110, ar.25, sp3, ev6, regen3, reanimate, 2x gauss, credit 1.5x.

b_spitter: cp2, hp82, ar.1, sp4, ev8, regen5, 2x bioplasma, credit 0.75x.

Changes I would make (effective CP under the multiplier):

Eclipse frigate: effective CP 1.5 (1 × 1.5), hp 56, ar .2, regen 3, reanimate. Job: the anvil that rebuilds - the ship you leave on the point.

Chorus frigate: effective CP 0.7 (1 × 0.7), hp 46, ar .05, regen 4. Job: the tarpit that heals - the ship you spend freely.

Eclipse destroyer: effective CP 3 (2 × 1.5), hp 110, ar .25, regen 3, reanimate. Job: line breaker that comes back.

Chorus destroyer: effective CP 1.4 (2 × 0.7), hp 82, ar .1, regen 5. Job: volume of fire that regenerates.

From the roster screen alone, the player sees a 2:1 CP ratio and a ~2.2:1 credit ratio at the frigate tier (1.5/0.7 vs 1.45/0.65). That is consistent: the elite ship is visibly dearer and visibly tougher; the swarm ship is visibly cheaper and visibly more numerous. The current build already has the credit half of that story; CP is the missing half.

5. THE RISK CASE

Strongest argument against: more hulls and asymmetric CP are a balance and readability tax. The roster already has verified duplicates ("near-identical" frigates), "token hangars" on two Hegemony line ships, and boss kits that "recycle carrier and cruiser kits." Adding hulls before fixing those compounds the problem. Asymmetric CP means the roster screen lies: a 4-CP Eclipse cruiser is not a 4-CP Voidsworn cruiser. The enemy builder already reshapes by archetype (swarm/heavy/carrier); adding CP asymmetry makes it harder to predict and balance.

Ruling: the risk case wins against "more hulls" - I would not add any hull beyond the ruled Eclipse battleship. It does not win against the ruled battleship, against fixing the duplicates, or against one CP multiplier. The multiplier is a single system change that makes the existing credit asymmetry legible in the fleet builder; it is cheaper than per-hull CP edits and does not add a hull. So: the risk case beats expansion, but loses to the minimal repair.

Not checked

RAMP values (grow, refP, pw, light, ceil, boss, std) are absent, so exact fleet sizes and budget scaling cannot be computed.

Base credit costs for non-Voidsworn hulls are absent (only Voidsworn has cost fields), so exact Eclipse/Chorus credit prices cannot be computed; only FAC_PRICE multipliers are visible.

The W weapon table is absent, so I cannot judge whether gauss vs tendril vs bioplasma are balanced against each other.

The 20-ship cap is "designer leaning, not locked," so it is not a rule I can treat as fixed.

The altFleetPlan/equivHull/adm.start logic in core.js is truncated, so starting-fleet composition and admiral alternates cannot be judged.

RAMP.ceil and fleetPower() are not fully shown, so the enemy soft ceiling cannot be computed exactly.

Questions for the designer

Is the 20-ship cap locked? Stakes: under CP asymmetry the hull cap becomes the swarm's binding constraint at ~14 effective CP, so if it is not locked it should be tuned per faction rather than globally.

Should the Hegemony's token hangars be stripped (pure gun line) or committed to (a real carrier)? Stakes: this decides whether the Hegemony's identity is "synchronized fire" or a hybrid, and it is the difference between a differentiation fix and a new hull.

Should CP asymmetry be a faction multiplier (one system change) or per-hull CP edits (many data changes)? Stakes: the multiplier is cheaper to balance and preserves the integer ladder, but it makes effective CP fractional on the roster screen.
