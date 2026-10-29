Chair note: filed verbatim from the Qwen3.8-Max run of Oct 29, 2026 (both model gates passed, single response), except em dashes and en dashes in the model's text are normalized to hyphens.

# FACTION SHAPE AND ROSTER EXPANSION - DESIGN REVIEW

## 1. PROOF OF READING

Sections read: EVIDENCE PACK title and header (commissioner's question, code provenance "main 264f441d"); THE COMMISSIONER'S QUESTION; RULINGS AND FACTS IN FORCE (five bullet groups: faction identities Oct 24, Eclipse rulings Oct 29, roster counts, fleet caps, CP universality, roster-audit duplicates); WHAT TO JUDGE (five numbered prompts); code slices data.js 61-131 (HULLS, MOVE_RULES, FACTIONS, SECTOR_POOL), data.js 538-544 (FAC_PRICE, FAC_GATES), battle.js 139-165 (genEnemyFleet), core.js 330-336 (CP cap growth and admiral startup).

Overall verdict: SHAPES PARTIAL.

Each faction has a legible mechanical signature (regen/reanimate, blink, overburn, broadside rake, retro thrusters, ion-sync), but the CP ladder, the 20-ship cap, and three roster gaps (Eclipse's missing mid-line, the warden/h_picket duplicate, token Hegemony hangars) mean the shapes are asserted in stats and abilities rather than earned by the fleet-building decisions the player actually makes.

## 2. FINDINGS (ranked most severe first)

F1. [FIX] Eclipse's 3-hull roster creates an 8-CP dead zone between its cruiser and its boss. READ. The ladder is 1-2-4-(boss 12). The ruled battleship fills part of this, but as shipped the faction has "no option between 4 CP and 12 CP." A player at CP cap 10 can field at most two cruisers and a frigate, or five destroyers. There is no mid-line anchor, no second ship type to build around. Every other faction has at least four base hulls. INFERRED: this is the single largest roster gap in the game; the battleship ruling is necessary but the class slot it fills still leaves Eclipse with the thinnest ladder.

F2. [FIX] Universal CP does not enforce faction shape at the fleet-building screen. READ. "1 CP buys the same slot of budget in every faction." FAC_PRICE bends credits (Chorus frigate ×0.65, Eclipse frigate ×1.45) but CP is symmetric. INFERRED: the strategic resource that governs fleet composition - CP - is blind to the elite/swarm/raider distinction. A player can field ten Eclipse frigates at 1 CP each and call it a swarm, which contradicts the ruling that Eclipse is "few, durable, self-rebuilding."

F3. [FIX] The warden / h_picket duplicate undermines the claim that factions "feel unique and different" at the entry hull. READ. The audit calls them "near-identical": both 1 CP, both Frigate, both size .5, both evasive, both carrying an autocannon/laser forward and flak turret. warden: hp 45, sh 10, ar .1, ev 20. h_picket: hp 40, sh 10, ar .1, ev 18. INFERRED: a player comparing rosters at the start of a run sees two nearly interchangeable frigates in two factions that are supposed to be ideologically opposed (frontier gothic vs. Registry navy). This is the most visible place the "six paints" criticism lands.

F4. [FIX] Chorus swarm identity is present in stats but not in fleet-building arithmetic. READ. Chorus frigates cost 1 CP like every other frigate. The swarm fantasy requires numerical superiority, but at 10 CP the Chorus player fields the same count of 1-CP hulls as the Eclipse player. The regen and no-shield kit makes each drone feel swarmy in combat, but the roster screen does not. INFERRED: the 20-ship cap is the only mechanism that currently limits swarm size, and it limits it identically for every faction.

F5. [NOTE] Hegemony's two token hangars (h_vanguard hangar:1, h_dominion hangar:1) are vestigial. READ. Both line ships carry ab:'launch',hangar:1. The faction identity is "synchronized fire under a flagship anchor," not carrier operations. INFERRED: a single-bay hangar on a cruiser and a battleship adds a squadron without creating a carrier doctrine; it dilutes the Hegemony's ion-and-turbo identity and overlaps with the Voidsworn and Corsair carrier roles.

F6. [NOTE] Boss hulls recycle carrier and cruiser kits, flattening each faction's climax. READ. The audit states "boss hulls recycle carrier and cruiser kits." INFERRED: at 8-12 CP the boss should be a unique mechanical experience, but if the kit is assembled from existing parts the player has already seen, the boss reads as a stat bump rather than a new puzzle.

F7. [NOTE] Eclipse's FAC_PRICE multipliers (1.45 / 1.5 / 1.55) are the steepest in the game but have no CP-side counterpart. READ. No other faction exceeds ×1.3. INFERRED: the credit penalty signals "elite" in the economy layer, but because CP is symmetric the fleet-composition layer doesn't reinforce it. The two pricing systems tell different stories.

F8. [FIX] The enemy budget builder's archetype reshaping (swarm / heavy / carrier) gives enemy fleets a shape knob that player fleets lack. READ. genEnemyFleet filters the roster by archetype: if(arch==='swarm'){ ... roster=light; }. The player's own fleet has no equivalent constraint or incentive. INFERRED: enemy Chorus can be forced into a swarm shape by the AI director; the player's Chorus fleet is shaped only by their own CP choices, which are universal.

F9. [NOTE] The Ithar ladder skips 3 CP (1-2-4-5), creating a dead zone at the most common mid-game budget. READ. i_wisp 1, i_blade 2, i_song 4, i_carrier 5. INFERRED: at CP cap 7-8 (typical sector 2), an Ithar player cannot field a 3-CP cruiser because none exists; they must either double up on destroyers or jump to the 4-CP prism. This is a smaller gap than Eclipse's but it pinches at the exact moment the run is ramping.

F10. [NOTE] MOVE_RULES differentiation is strong but invisible at the roster screen. READ. Each faction has a distinct movement rule (fold drive, living hull, crystal vanes, broadside doctrine, retro thrusters, bolted burners). INFERRED: these are the best shape differentiators in the pack, but they only manifest in battle. A player choosing a fleet composition before deployment sees CP costs, hull stats, and weapon loadouts - not the movement rule. The shape is earned in play but not at the decision point the question asks about.

## 3. EXPLICIT CHECKS

### 3A. NEW HULLS

Hulls I would add (beyond the ruled Eclipse battleship):

| Faction | Class | Job (one line) | Gap filled |
|---|---|---|---|
| Eclipse | Battleship (ruled) | Slow, unkillable attrition wall that grinds fleets down through regen and reanimation | The 8-CP void between d_harvester (4 CP) and d_boss (12 CP); Eclipse currently has no mid-line anchor |
| Chorus | Destroyer variant (not a new hull ID, a roster slot) | Cheap 1-CP "feeder" that dies and buffs adjacent Chorus hulls' regen | The swarm fantasy needs a hull whose death is productive, giving the Chorus player a reason to field more hulls than the opponent. Currently every Chorus hull wants to survive (regen), which is the opposite of swarm logic |
| Hegemony | None | - | Hegemony's 4-hull ladder (1-2-4-6) is coherent. The token hangars should be removed from h_vanguard, not papered over with a fifth hull |
| Corsair | None | - | The 1-2-3-4 ladder covers raider, gutship, wrecker, hulk-carrier. The identity is complete |
| Ithar | None (but re-cost i_song to 3 CP) | - | The gap is a pricing problem, not a hull-count problem. A 3-CP prism fits the ladder; a new hull at 3 CP would duplicate it |
| Voidsworn | None | - | Five base hulls plus a dreadnought boss is the fullest roster. No gap |

Eclipse battleship design (elite attrition, no carrier):
The ruling says: elite attrition, few durable self-rebuilding ships, no carrier ever. The battleship must be the doctrinal centre of an Eclipse fleet - the ship the player protects and the enemy cannot kill.

d_sovereign: {
  n: 'Eclipse sovereign', cls: 'Battleship', fac: 'deathless',
  size: .94, cp: 7,
  hp: 250, sh: 0, rg: 0, ar: .40,
  sp: 2, tn: 1, ev: 0,
  w: [['hgauss','P'],['hgauss','S'],['doom','F'],['gsentry','T']],
  ab: 'reclaim', regen: 6, reanimate: true,
  slots: 3, cost: 420
}

Justification against the tables:
- CP 7 slots between d_harvester (4) and d_boss (12), mirroring h_dominion's CP 6 and cathedral's CP 5 but priced higher to reflect the elite premium. At CP cap 10, an Eclipse player fields one sovereign (7) plus one destroyer (2) plus one frigate (1): exactly three ships. That is the elite fantasy.
- HP 250, armor .40: higher HP than cathedral (220, ar .30) and h_dominion (230, ar .25). The armor is the highest non-boss value in the game. Combined with regen 6 and reanimate, the sovereign effectively has ~300+ HP per engagement. It is a wall.
- No shields, no evasion, speed 2: the trade-off for the armor. It cannot dodge, cannot run. It advances and absorbs. This is the opposite of the Chorus (fast, regenerating, numerous) and the Ithar (fast, shielded, fragile).
- Weapons: heavy gauss port/starboard (broadside analog but in the Eclipse null-weapon family), doom cannon forward (the existing anti-capital weapon), gauss sentry turret. No hangar, no fighter bay, by ruling.
- ab:'reclaim': carries forward from d_harvester. INFERRED: reclaim should let the sovereign recover a destroyed adjacent Eclipse hull as a wreck that reanimates at reduced HP next round, making the sovereign a mobile resurrection engine. This is the elite-attrition fantasy in one ability: your fleet does not shrink.
- FAC_PRICE: add deathless: { Battleship: 1.6 } to the existing table. The credit cost should sting.

### 3B. CLASS DIFFERENTIATION

Should any faction's ladder break the shared frigate-to-boss shape?
Yes, in two places. No, in the general case.

Break 1 - Eclipse: no carrier, ever (already ruled). Extend the principle: Eclipse should also skip the Dreadnought class. Its ladder should read Frigate → Destroyer → Cruiser → Battleship → Boss (Tomb-ark). The Voidsworn have a Dreadnought (ascendant, 8 CP); Eclipse should not. The Tomb-ark at 12 CP is the capital. This makes Eclipse the only faction whose top of ladder is a Battleship, not a Dreadnought or Super-dreadnought. Readability cost: low. The player sees five classes across all factions and Eclipse simply lacks one. The absence is the identity.

Break 2 - Chorus: the top of the ladder should be the brood-sac carrier, not a battleship. The Chorus currently has Frigate → Destroyer → Cruiser → Carrier → Bio-titan boss. This is already non-standard (the carrier is the 5-CP capstone hull, not a battleship). Keep it. The brood-sac is the Chorus battleship: a huge, slow, regenerating spore factory. Do not add a Chorus battleship. Readability cost: moderate. A player scanning class columns will see that the Chorus has no battleship row. That is acceptable if the carrier is visually and mechanically clearly the "big ship."

Where the shared ladder helps readability: the 1-CP frigate as the universal entry point. Every faction starts with a cheap scout/screen. This is the on-ramp. Removing it from any faction would break the first-turn experience. Keep it universal.

Where the shared ladder flattens identity: the assumption that every faction needs a destroyer, a cruiser, and a carrier. Corsairs with no battleship (their hulk-carrier at 4 CP is their biggest non-boss hull) already break this, and it works. Eclipse with no carrier will break it further. The shape of the ladder is the faction identity. Let it be uneven.

### 3C. CP ASYMMETRY

Judgement: bend CP, but only at the extremes. Keep the mid-ladder universal.

The current system (universal CP) means 1 CP buys the same quantity of fleet in every faction. The elite/swarm distinction exists only in stats. This is wrong for a game that rules Eclipse as "few, durable" and Chorus as "feeds and grows."

Proposal: introduce a faction CP multiplier applied at the fleet-building screen, separate from the FAC_PRICE credit multiplier.

| Faction | CP multiplier | Effect |
|---|---|---|
| Eclipse | ×1.5 | A 1-CP frigate costs 1.5 CP. A 7-CP battleship costs 10.5 CP. |
| Chorus | ×0.75 | A 1-CP drone costs 0.75 CP. A 5-CP brood-sac costs 3.75 CP. |
| Others | ×1.0 | Unchanged. |

Round up to the nearest 0.5 CP for display.

Fleet-size consequences, Sector 2, CP cap 10, one fight each way:

Universal CP (current):
- Eclipse at 10 CP: 2 cruisers (4+4) + 1 destroyer (2) = 3 ships, 10 CP spent. Or 5 destroyers = 5 ships. The player can swarm with Eclipse frigates (10 × 1 CP = 10 ships), which breaks the fantasy.
- Chorus at 10 CP: 1 carrier (5) + 1 cruiser (3) + 1 destroyer (2) = 3 ships + 3 spore squadrons. Or 10 drones = 10 ships. Same count range as Eclipse. No swarm advantage at the CP level.

Asymmetric CP (proposed):
- Eclipse at 10 CP: frigate costs 1.5, destroyer 3, cruiser 6, battleship 10.5. The player can field: 1 cruiser (6) + 1 destroyer (3) = 2 ships, 9 CP. Or 1 destroyer (3) + 4 frigates (6) = 5 ships, 9 CP. Or 1 battleship at 10.5 CP: 1 ship. The elite shape is enforced by arithmetic. You cannot field 10 Eclipse frigates; they cost 15 CP.
- Chorus at 10 CP: drone costs 0.75, spitter 1.5, razor 2.25, brood-sac 3.75. The player can field: 1 brood-sac (3.75) + 1 razor (2.25) + 2 spitters (3) + 1 drone (0.75) = 5 ships + 3 spores, 9.75 CP. Or 13 drones = 13 ships, 9.75 CP. The swarm shape is enforced: you can flood the board.

Against the 20-ship cap: with asymmetric CP, the Chorus can approach the 20-ship cap (13 drones + squadrons + the enemy's complement). Eclipse will field 2-5 ships. The cap is not a constraint on Eclipse; the CP multiplier is. The cap constrains the Chorus, which is correct: the swarm should hit the ceiling and feel capped, not the elite faction.

Against the enemy budget builder: genEnemyFleet uses CP directly (x.cp<=budget+.3). If CP becomes asymmetric, the budget builder must use effective CP (base CP × faction multiplier) for roster filtering and budget subtraction. The archetype reshaping (swarm filters to cp<=mn+1) will naturally produce larger Chorus fleets and smaller Eclipse fleets without additional code, because the effective CP spread changes. INFERRED: this is roughly 15 lines of change in genEnemyFleet.

### 3D. ELITE VERSUS SWARM, PRICED

As built:

|  | Eclipse frigate (d_scythe) | Chorus frigate (b_drone) |
|---|---|---|
| CP | 1 | 1 |
| HP | 56 | 46 |
| Shield | 0 | 0 |
| Armor | .20 | .05 |
| Speed | 4 | 5 |
| Evasion | 14 | 15 |
| Regen | 3 | 4 |
| Special | phase, reanimate | regrow |
| Weapon | gauss T | tendril T |
| Credit cost | 70 × 1.45 = ~102 | 70 × 0.65 = ~46 |

|  | Eclipse destroyer (d_jackal) | Chorus destroyer (b_spitter) |
|---|---|---|
| CP | 2 | 2 |
| HP | 110 | 82 |
| Armor | .25 | .10 |
| Speed | 3 | 4 |
| Regen | 3 | 5 |
| Special | phase, reanimate | regrow |
| Weapons | gauss T + gauss F | bioplasma T + bioplasma F |

What I would change:
1. CP (per 3C above): Eclipse frigate → 1.5 CP effective. Chorus drone → 0.75 CP effective. This is the single most important change. At the roster screen, the player sees that Eclipse costs more per hull and Chorus costs less. The elite/swarm distinction is now legible before the battle starts.
2. Eclipse frigate stat adjustment: reduce HP from 56 to 50, raise armor from .20 to .25, reduce regen from 3 to 2. The Eclipse frigate should not be a brawler; it should be a survivor. Lower HP + higher armor + reanimate means it is very hard to actually destroy (you must get through armor, and then it reanimates), but it is not a damage sponge. The phase ability already gives it an "I was not here" escape. The fantasy is: you hit it, it phases, it comes back, it is still there.
3. Chorus drone stat adjustment: reduce HP from 46 to 38, raise regen from 4 to 6, add a feedOnDeath: 2 field (INFERRED: when a Chorus hull dies, adjacent Chorus hulls gain +2 regen for the rest of the battle). The drone should be disposable. It is cheap, it dies, and its death makes the swarm stronger. Currently the drone is a small tank with regen, which is the Eclipse fantasy in a bio skin.
4. Eclipse destroyer: raise armor to .30, reduce speed to 2. It should be a slow, grinding duellist. Two gauss weapons and reanimate make it a 1v1 monster. It does not chase; it advances.
5. Chorus spitter: raise speed to 5, reduce armor to .05, raise regen to 6. It should be fast, fragile, and self-healing. It swarms in, spits bioplasma, and regenerates. It is not a line-of-battle ship.
6. Credit prices: keep FAC_PRICE as is. The Eclipse ×1.45-1.55 multipliers and Chorus ×0.65-0.75 multipliers already tell the right economic story. The CP multiplier is the new lever.

What the player sees at the roster screen after these changes:
Eclipse column: 1.5 CP / 3 CP / 6 CP / 10.5 CP / 18 CP (boss). Few, expensive, each hull a fortress.
Chorus column: 0.75 CP / 1.5 CP / 2.25 CP / 3.75 CP / 9 CP (boss). Many, cheap, each hull expendable.
The shape is visible in the numbers before a single shot is fired.

### 3E. THE RISK CASE

The strongest argument against new hulls and asymmetric CP:
Every new hull is a balance surface. The Eclipse battleship must be tested against every weapon in the game, every enemy archetype, every sector's budget curve. Asymmetric CP multiplies the balance surface by the number of factions: the enemy budget builder, the RAMP tables, the fleet-power scaling in genEnemyFleet (Math.pow(fleetPower()/RAMP.refP[s], RAMP.pw)), and the CP cap growth in core.js all assume universal CP. Changing CP semantics means re-validating every sector's difficulty curve for six factions instead of one. The 20-ship cap, "designer leaning, not locked," becomes load-bearing: if it shifts, the Chorus swarm arithmetic changes. The player's mental model ("I have 10 CP, I can buy ten frigates") breaks in two factions. The codex, the UI, the tutorial all must explain why 1 CP is not 1 CP. This is a readability tax on every new player and a balance tax on every patch.

Furthermore, the existing shapes are already legible in play. Eclipse's reanimate, phase, and fold drive make it feel elite. The Chorus's regen, no-shields, and living-hull movement make it feel like a swarm. The MOVE_RULES do the identity work that CP asymmetry would do at the roster screen. Adding CP asymmetry is solving a problem that the tactical layer has already solved.

Does this argument win?
No. It wins on cost but loses on design intent. The commissioner's question is whether the factions should "feel different in shape," and the ruling is that they should. The current system delivers that difference in combat but not in composition. A player building a fleet at the start of sector 2 sees the same CP ladder shape for Eclipse and Chorus. The elite/swarm distinction is a fleet-building fantasy, not just a combat fantasy. The tactical layer solves the in-battle feel; the CP layer must solve the pre-battle feel. Without it, the roster screen - the place where the player makes strategic decisions - is faction-blind.

The balance tax is real but bounded: six factions, one multiplier each, and the enemy budget builder already has archetype reshaping that can absorb the change. The readability tax is a one-time tutorial cost. The design gain is permanent.

I would build it.

## 4. NOT CHECKED

- Weapon balance tables. The pack references weapons (gauss, doom, bioplasma, tendril, shard, pulsar, etc.) but does not include the weapon data table (presumably W in data.js). I cannot judge whether Eclipse gauss weapons do enough more damage than Chorus tendrils to justify the CP premium, or whether the doom cannon is appropriately devastating for a battleship's forward mount.
- RAMP table values. genEnemyFleet references RAMP.grow[s], RAMP.ceil[s], RAMP.refP[s], RAMP.pw, RAMP.light[s], RAMP.boss[s], RAMP.pwMin, RAMP.pwMax, RAMP.std. None of these values are in the pack. I cannot verify the sector-2 budget number I estimated, nor the fleet-ceiling arithmetic.
- The 18 variants. The pack states "18 variants on top" of the base hulls but does not list them. I cannot judge whether variants fill any of the gaps I identified, or whether they create new duplicates.
- Captain, perk, and mod systems. core.js references cap.rank, cap.xp, RANK_XP, PERKS, mods, mastery levels, and admiral plans. These interact with fleet power and CP cap growth but are not included. I cannot judge whether a modded Eclipse cruiser at mk2 with a veteran captain changes the CP calculus.
- Multiplayer or asymmetric campaign structure. SECTOR_POOL shows three sector pools with fixed faction matchups. I cannot judge whether CP asymmetry would create matchup-specific balance problems (e.g., Eclipse vs. Chorus in sector 3) without knowing the full campaign arc.
- The "equivalent hull" function. core.js calls equivHull(t,fac) for admiral fleet conversion. Its logic is not in the pack. I cannot judge whether it would handle CP-multiplied hulls correctly.

## 5. QUESTIONS FOR THE DESIGNER

1. The 20-ship cap: is it per side or total, and is it a hard cap or a soft ceiling? The genEnemyFleet code computes ceil = RAMP.ceil[s] - min(7, playerFleetSize), which reads like a total board cap that shrinks the enemy's allowance as the player's fleet grows. If it is total, a 13-ship Chorus swarm leaves only 7 enemy ships, which may be too few for an interesting opposing force. If it is per-side, the Chorus can hit 20 and the enemy still fields its full complement. The answer determines whether CP asymmetry creates a board-presence problem or not.
2. Should the Eclipse battleship's 'reclaim' ability resurrect other Eclipse hulls, or only self-repair? I designed it as a mobile resurrection engine (adjacent wrecks reanimate at reduced HP) because that is the "self-rebuilding" fantasy in the ruling. But if reclaim is self-only, the battleship is just a stat wall and the fleet's attrition identity depends entirely on per-hull regen. The stakes: a fleet-wide resurrection mechanic is more powerful and harder to balance, but it is the thing that makes Eclipse feel like Eclipse rather than "Hegemony but slower and greener."
3. Is the warden / h_picket duplicate a problem to fix or a feature to keep? Both are 1-CP evasive frigates with a forward gun and a flak turret. If the design intent is that every faction's first hull should be a recognisable "picket/frigate" archetype for tutorial readability, the near-duplicate is intentional and I should not change it. If the intent is that each faction's 1-CP entry should be distinctive, one of them needs a rework (h_picket should lean into ion and Hegemony sync-fire; warden should lean into the broadside rake bonus). The stakes: this is the first hull a player sees in two of the six factions, and it sets the expectation for whether the rosters will feel different or not.
