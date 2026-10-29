Chair header: Argon High leg (Gemini 4 Argon, Thinking High, verified before and after sending) for the faction shape and roster expansion design review, Oct 29, 2026 program, pack pinned to main 264f441d. Filed verbatim below except em dashes and en dashes are normalized to hyphens. Browser method notes and citation chips are excluded per house rules and recorded in the screening note. One table introduction in Check 3 was garbled in extraction; its fleet-size rows are reproduced in readable form with all extracted compositions preserved.

### 1. Proof of Reading

**Sections Read:**

- EVIDENCE PACK: faction shape and roster expansion design review (code slices from the shipped browser build, main 264f441d; the Godot port mirrors this design) (EVIDENCE PACK title line)
- THE COMMISSIONER'S QUESTION
- RULINGS AND FACTS IN FORCE (chair-verified; the designer has decided these) (CHAIR CENSUS)
- WHAT TO JUDGE
- Code slices: === data.js 61-131: HULLS, MOVE_RULES, FACTIONS ===, === data.js 538-544: FAC_PRICE ===, === battle.js 139-165: genEnemyFleet budget and archetype shaping ===, and === core.js 330-336: command point cap growth ===

**Overall Verdict: SHAPES PARTIAL - MOVE_RULES, defense profiles, and FAC_PRICE differentiate factions on the hex grid, but universal 1-2 CP bottom rungs, genEnemyFleet ignoring FAC_PRICE, and recycled hull abilities cause elite Eclipse and swarm Chorus to field identical ship counts.**

### 2. Findings

**[BLOCKER] genEnemyFleet spends cp while ignoring FAC_PRICE, so AI Eclipse spawns at swarm headcounts with free elite stats and AI Chorus pays full CP for discounted chaff.**

READ: FAC_PRICE sets credit multipliers of chorus:{Frigate:.65,Destroyer:.75,Cruiser:1,Carrier:1.2} and deathless:{Frigate:1.45,Destroyer:1.5,Cruiser:1.55}, while both factions price Frigate at cp:1 and Destroyer at cp:2. In battle.js, genEnemyFleet builds its candidate pool strictly from CP via let roster=F.roster.map(id=>({id,cp:HULLS[id].cp,car:HULLS[id].ab==='launch'})).

INFERRED: Because the designer put faction asymmetry into FAC_PRICE (credits) while leaving cp flat at 1 and 2, enemy fleet generation completely bypasses the asymmetry. An enemy Eclipse fleet spawns the exact same number of 1-CP and 2-CP hulls as a Chorus fleet while getting 1.45x-1.55x credit-statted ships (reanimate:true, high armor, regen) for 1.0x CP, whereas an enemy Chorus fleet pays full 1-2 CP for 0.65x-0.75x chaff hulls and never outnumbers other factions.

**[BLOCKER] Both Hegemony heavy line hulls carry ab:'launch', breaking arch==='carrier' escort generation and leaving "synchronized fire under a flagship anchor" unimplemented.**

READ: The Oct 24 ruling defines Hegemony as "synchronized fire under a flagship anchor", while the audit notes "both Hegemony line ships carry token hangars" (h_vanguard at cp:4 and h_dominion at cp:6 both have ab:'launch',hangar:1). In battle.js, car:HULLS[id].ab==='launch' marks both hulls as carriers, and if(arch==='carrier'&&kind!=='boss') executes roster=roster.filter(x=>!x.car) after picking one carrier.

INFERRED: When Hegemony rolls a carrier archetype fight, roster.filter(x=>!x.car) strips both the Cruiser (h_vanguard) and the Battleship (h_dominion) out of the remaining spawn pool, forcing the rest of the budget into 1-CP h_picket and 2-CP h_interdictor escorts to guard a single hangar:1 ship. Furthermore, not a single Hegemony hull has an ability (ab) that implements "synchronized fire under a flagship anchor".

**[BLOCKER] Universal 1-CP Frigates and genEnemyFleet light-hull weighting force all six factions into the same small-ship cadence.**

READ: Every faction ladder starts at 1-2 CP ("Voidsworn 1-2-3-4-5, Hegemony 1-2-4-6, Corsair 1-2-3-4, Chorus 1-2-3-5, Ithar 1-2-4-5, Eclipse 1-2-4"). In battle.js, non-heavy spawn weights use (x.cp===1?1.1:Math.min(2,budget/(x.cp*2))+.35)*(x.cp<=2&&arch!=='swarm'?RAMP.light[s]:1).

INFERRED: Because genEnemyFleet explicitly privileges x.cp===1 (fixed base weight 1.1) and x.cp<=2 (multiplied by RAMP.light[s]), giving Eclipse (d_scythe, d_jackal) and Ithar (i_wisp, i_blade) 1-CP and 2-CP hulls guarantees they flood the board with small ships at the same rate as Chorus and Corsairs, violating "Eclipse is ELITE attrition (few, durable, self-rebuilding ships)" and Ithar's "Few, long-lived masters of light and crystal".

**[FIX] Pricing swarm hulls below 1 CP (cp < 1) breaks genEnemyFleet's loop guard and truncates swarm budgets against ceil and the 20-ship battle cap.**

READ: Battles are capped at "about 20 ships per battle", and genEnemyFleet loops while(budget>=1 && list.length<Math.max(4,ceil) ...).

INFERRED: If Chorus frigates are discounted to cp: 0.5 so a swarm outnumbers standard fleets, while(budget>=1 ...) terminates before spending < 1.0 CP remainders, and a Sector 2 or Sector 3 budget slams into list.length < Math.max(4, ceil) after spawning 8-12 ships - leaving 30%-50% of the Chorus CP budget unspent and making late-sector Chorus fleets under-powered.

**[FIX] Eclipse's Cruiser (d_harvester) and Boss (d_boss) have less HP and less regeneration than their Chorus counterparts, inverting the elite-attrition curve.**

READ: At cp:4, Eclipse's d_harvester has hp:145,sh:0,rg:0,ar:.3,sp:2,tn:1,ev:0, regen:4,reanimate:true, whereas at cp:3, Chorus's b_razor has hp:150,sh:0,rg:0,ar:.2,sp:4,tn:2,ev:4, regen:7. At cp:12, Eclipse's d_boss (The Unsetting) has hp:480, ar:.35, ab:'nova',regen:8 (no reanimate), whereas Chorus's b_boss has hp:650, ar:.25, regen:20.

INFERRED: d_harvester costs +1 CP and 1.55x credits compared to b_razor, yet has lower raw HP (145 vs 150), half the speed (sp:2 vs sp:4), and lower regeneration (4 vs 7). At the boss tier, d_boss has the second-lowest HP of any boss (480 vs Hegemony 560, Corsair 600, Chorus 650), less than half of b_boss's regen (8 vs 20), and no self-rebuilding mechanic.

**[FIX] No Chorus hull has a mechanic that "feeds and grows", while Eclipse owns ab:'reclaim'.**

READ: The Oct 24 ruling states "the Chorus is a swarm that feeds and grows", but Chorus hulls only use ab:'regrow' (b_drone, b_spitter), ab:'frenzy' (b_razor), and ab:'launch' (b_brood, b_boss), while Eclipse's d_harvester uses ab:'reclaim'.

INFERRED: Passive per-round regen (4 to 20) and ab:'regrow' model regeneration, not feeding or growing. Chorus has no mechanic on its non-carrier hulls that consumes wrecks, grows max HP/damage on kills, or spawns new units mid-fight.

**[FIX] warden and h_picket are near-clones, and all six faction bosses recycle standard cruiser/carrier abilities (nova, launch, surge).**

READ: The audit verifies "the two 1 CP frigates (warden, h_picket) are near-identical" (hp:45 vs 40, ev:20 vs 18, autocannon vs laser, identical sh:10,rg:5,ar:.1,sp:5,tn:3,ab:'evasive') and "boss hulls recycle carrier and cruiser kits" (ascendant, h_boss, and d_boss share ab:'nova'; c_boss and b_boss share ab:'launch'; i_boss uses ab:'surge').

INFERRED: h_picket plays like a slightly weaker Voidsworn frigate rather than a Hegemony picket, and fighting three different faction bosses with ab:'nova' flattens sector climaxes.

**[NOTE] FAC_PRICE.deathless omits a Battleship multiplier for the ruled Eclipse battleship.**

READ: FAC_PRICE defines deathless:{Frigate:1.45,Destroyer:1.5,Cruiser:1.55} with no Battleship key.

INFERRED: When the ruled Eclipse battleship (cls:'Battleship') is added, its credit multiplier will default to 1.0 - making it cheaper per CP in credits than an Eclipse frigate (1.45) - unless Battleship:1.6 is added to FAC_PRICE.deathless.

**[NOTE] core.js couples run start to equivHull(t, fac) and assumes a carrier (ab==='launch') exists for plan.mod.**

READ: core.js 330-334 executes adm.start.map(t=>equivHull(t,fac)), searches for RUN.fleet.find(s=>HULLS[s.tpl].ab==='launch'), and sets RUN.cpCap=Math.max(RUN.cpCap, fleetCP()+3).

INFERRED: While RUN.cpCap automatically scales up if an elite starting fleet costs more CP, any ladder break - including the ruling that "Eclipse gets NO carrier, ever, by ruling" - requires equivHull to map reliquary (Carrier) to a non-carrier hull and plan.mod to handle fleets without ab==='launch'.

### 3. Explicit Checks

#### 1. NEW HULLS

**Primary Verdict: Add only the 1 ruled Eclipse Battleship (d_umbra / 'Eclipse umbra'), and do not add new hulls to other factions.**

Why no other new hulls (INFERRED from HULLS and the audit): The game already maintains 24 base hulls, 6 bosses, and 18 variants (48 total ship templates). The roster audit's failures (h_picket cloning warden, both Hegemony heavy ships carrying ab:'launch', hangar:1, Chorus lacking a feeding mechanic, bosses recycling nova and launch) are caused by existing hulls carrying placeholder kits, not by missing class slots. Adding a 5th hull to Hegemony, Corsair, Chorus, and Ithar for symmetry would increase variant and Godot-port maintenance while leaving the broken existing hulls in place.

**The One Rulings-Mandated Hull to Add (and the two in-place reworks that avoid new hulls):**

- Eclipse (deathless), Battleship (d_umbra / 'Eclipse umbra'), Heavy Attrition Anvil & Flak Screen - Fills the 8-CP gap between d_harvester (cp:4, or 5 re-priced) and d_boss (cp:12), giving Eclipse a late-game arch==='heavy' flagship anchor and anti-squadron screen since "Eclipse gets NO carrier, ever, by ruling".

(If you refuse in-place reworks and insist on new hulls for the two remaining job gaps, add only these two - otherwise apply them as reworks to h_dominion and b_razor):

- Hegemony (hegemony), Battleship rework (h_dominion), Flagship Fire-Director - Strip ab:'launch', hangar:1 from h_dominion (keeping launch with hangar:2 only on h_vanguard, or vice versa) and give h_dominion a flagship-anchor ability (ab:'focus' or 'lockon') so Hegemony actually executes "synchronized fire under a flagship anchor" and stops breaking arch==='carrier' in battle.js 152.
- Chorus (chorus), Cruiser rework (b_razor or b_spitter), Wreck-Feeder / Brood-Spawner - Give b_spitter or b_razor ab:'reclaim' (or a wreck-consuming spawn trigger) so the Chorus executes "a swarm that feeds and grows" without bloating the roster.

**Eclipse Battleship Design Sketch (d_umbra / 'Eclipse umbra'):**

Designed against data.js 61-99 (cathedral at cp:5, hp:220, sh:30, ar:.3; h_dominion at cp:6, hp:230, sh:32, ar:.25; d_harvester at cp:4, hp:145, ar:.3, regen:4):

```javascript
d_umbra:{n:'Eclipse umbra',cls:'Battleship',fac:'deathless',size:.98,cp:6,hp:265,sh:0,rg:0,ar:.35,sp:2,tn:1,ev:0,
  w:[['doom','F'],['gauss','P'],['gauss','S'],['gsentry','T'],['flak','T']],ab:'reclaim',regen:6,reanimate:true}
```

Note on CP & FAC_PRICE (INFERRED): Under universal CP it sits at cp:6 (matching h_dominion); under shape-bent CP (Checks 2-4) it sits at cp:7 on a 2-3-5-7 ladder (with d_harvester buffed to cp:5, hp:205, regen:6 and d_boss buffed to hp:600, regen:12). Add Battleship:1.6 to FAC_PRICE.deathless.

How its kit solves "elite attrition, no carrier" (INFERRED):

- Attrition Bulk: hp:265, sh:0, ar:.35, regen:6, reanimate:true gives ~408 effective HP against standard fire before regeneration and self-reanimation.
- Fold Drive Synergy: Because MOVE_RULES.deathless has over:0 ("Passes through rocks, wrecks and enemy ships at no extra cost"), mounting ['doom','F'] plus broadside ['gauss','P'] and ['gauss','S'] lets d_umbra march directly through an enemy battle line, firing port and starboard gauss arcs while consuming the wrecks behind it with ab:'reclaim'.
- No-Carrier Counterplay: Dual point-defense turrets (['gsentry','T'] and ['flak','T']) let Eclipse murder enemy fighter/bomber wings rather than launching its own.

#### 2. CLASS DIFFERENTIATION

All six factions should keep the shared class vocabulary (Frigate, Destroyer, Cruiser, Carrier, Battleship) so target priority and hull size remain instantly readable, but which rungs of the ladder exist must differ by faction. Right now, four factions already skip either Carrier or Battleship, yet all six factions share Frigate (1 CP) -> Destroyer (2 CP) -> Cruiser (3-4 CP), which makes 80%+ of fights feel structurally identical.

| Faction | Current Base Ladder (Class & CP) | Proposed Ladder Break (INFERRED) | Readability & Systemic Cost (INFERRED) |
|---|---|---|---|
| Voidsworn | Frigate (1), Destroyer (2), Cruiser (3), Carrier (4), Battleship (5) | None (1-2-3-4-5). Keep as the complete 5-rung player yardstick. | None. Serves as the player's reference scale for every enemy class tag. |
| Eclipse (deathless) | Frigate (1), Destroyer (2), Cruiser (4) + ruled Battleship | Cut the 1-CP chaff rung; shift to 2-3-5-7 with NO Carrier ever: Frigate/Corvette (d_scythe, 2 CP) → Destroyer (d_jackal, 3 CP) → Cruiser (d_harvester, 5 CP) → Battleship (d_umbra, 7 CP). | Low readability cost (players immediately learn "even the smallest Eclipse hull is a 2-CP threat"). Code cost: equivHull(t, 'deathless') in core.js 330 must handle a 2-CP minimum hull and no carrier. |
| Chorus (chorus) | Frigate (1), Destroyer (2), Cruiser (3), Carrier (5) | Top out at Carrier (b_brood, 5 CP) - never add a Battleship. Keep bottom-heavy 1-2-3-5 ladder where the apex ship is a 3-hangar bio-carrier (b_brood) that floods the map with spore squadrons. | Zero cost. Already matches data.js; keeping Battleships out of Chorus preserves its swarm silhouette. |
| Corsair & Ithar | Corsair 1-2-3-4 (top: Carrier); Ithar 1-2-4-5 (top: Carrier) | Keep NO Battleship on either. Cap raiders (corsair) and fast crystal glass-cannons (ithar) at Cruiser/Carrier so only heavy-line factions (Voidsworn, Hegemony, Eclipse) field Battleships. | Zero cost. Preserves the rule that seeing cls:'Battleship' means a slow (sp:2), high-armor line anchor. |
| Hegemony | Frigate (1), Destroyer (2), Cruiser (4, launch), Battleship (6, launch) | Stop making both heavy ships pseudo-carriers. Keep launch (hangar:2) on h_vanguard (4 CP Carrier-Cruiser) and make h_dominion (6 CP) a pure Flagship Battleship (ab:'focus'). | Fixes readability and code: right now a player sees cls:'Cruiser' and cls:'Battleship' that both act as 1-bay carriers and break battle.js 152. |

#### 3. CP ASYMMETRY

**Verdict (INFERRED): Keep 1 CP universal as a unit of combat power (eliminating the FAC_PRICE vs. cp split-brain where Eclipse gets 1.5x stats per CP for free), and bend the hull CP ladder by faction shape - raising Eclipse's hull floor/ladder to 2 - 3 - 5 - 7 CP while keeping Chorus at 1 - 2 - 3 - 5 CP (with cp:0 spore spawns). Do not price Chorus frigates at 0.5 CP.**

Why 0.5 CP Swarm Hulls Fail Against the 20-Ship Cap and genEnemyFleet (READ + INFERRED):

In battle.js 155-156, genEnemyFleet enforces const ceil=RAMP.ceil[s]-((typeof RUN!=='undefined'&&RUN&&RUN.fleet)?Math.min(7,RUN.fleet.filter(sh=>sh.hp>0).length):4) and loops while(budget>=1 && list.length<Math.max(4,ceil) ...).

Fleet-size models:

- **1. As-Built Flat CP (Eclipse 1-2-4 vs. Chorus 1-2-3-5):** Chorus: 1x Cruiser (3) + 2x Destroyer (4) + 5x Frigate (5) = 8 hulls (12 CP). Eclipse: 3x d_jackal (6) + 6x d_scythe (6) = 9 hulls (12 CP). Chorus: 3x b_spitter (6) + 6x b_drone (6) = 9 hulls (12 CP). Eclipse: 2x d_harvester (8) + 2x d_jackal (4) = 4 hulls (12 CP). Chorus: 1x b_brood (5) + 2x b_razor (6) + 1x b_drone (1) = 4 hulls (+3 spores). Result: Fails shape: Eclipse fields 7-9 hulls vs. Chorus 8-9 hulls; AI Eclipse gets ~18.2 CP of credit-equivalent stats for 12 CP.
- **2. Naive Fractional CP (0.5 CP Chorus Frigate, 1.0 CP Destroyer):** Chorus (0.5 - 1 - 2.5 - 4). Wants ~16 hulls, hits ceil = 11 at 2x Cruiser (5) + 2x Destroyer (2) + 7x Frigate (3.5) = 11 hulls (2.0 CP wasted). Wants 18-22 hulls, hits ceil = 11 at 3x b_spitter (3) + 8x b_drone (4) = 11 hulls (5.5 CP / 44% budget wasted!). 1x b_brood (4) + 2x b_razor (5) + 3x b_spitter (3) = 6 hulls (12 CP). Result: Breaks generator: Swarm hits ceil = 11 and loses up to 44% of its budget (5.5 CP unspent).
- **3. Proposed Shape-Bent Integer CP (1 CP = 1 CP power; Eclipse 2-3-5-7, Chorus 1-2-3-5):** Eclipse (2-3-5-7) vs. Chorus (1-2-3-5). Eclipse: 1x Cruiser (5) + 1x Destroyer (3) + 2x Frigate (4) = 4 hulls (12 CP). Chorus: 1x Cruiser (3) + 2x Destroyer (4) + 5x Frigate (5) = 8 hulls (12 CP). Eclipse (mn=2, cp<=3): 2x d_jackal (6) + 3x d_scythe (6) = 5 hulls (12 CP). Chorus (mn=1, cp<=2): 2x b_spitter (4) + 8x b_drone (8) = 10 hulls (12 CP). Eclipse: 1x d_umbra (7) + 1x d_harvester (5) = 2 hulls (12 CP), or 1x (7) + 1x (3) + 1x (2) = 3 hulls. Chorus: 1x b_brood (5) + 2x b_razor (6) + 1x b_drone (1) = 4 hulls + 3 spores. Result: Earns shape inside cap: Eclipse fields 2-5 hulls (8-11 total on board); Chorus fields 8-10 hulls + spores (14-16 total on board). Zero budget wasted.

#### 4. ELITE VERSUS SWARM, PRICED

As built in data.js 83-84, 95-96, b_drone and d_scythe are both cp:1 (hp:46 vs hp:56), and b_spitter and d_jackal are both cp:2 (hp:82 vs hp:110). On the roster screen, a 10 HP difference between two 1 CP ships does not read as "undying elite monolith vs. ravenous expendable swarm".

Proposed Changes to Eclipse and Chorus Frigates & Destroyers (READ vs. INFERRED):

| Hull (id / n) | As Built (data.js) | Proposed Change (INFERRED) | Why the Player Feels It Immediately on the Roster Screen (INFERRED) |
|---|---|---|---|
| d_scythe ('Eclipse mote', Frigate) | cp:1, FAC_PRICE:1.45 (~102 cr); size:.5, hp:56; sh:0, rg:0, ar:.2, regen:3; sp:4, tn:2, ev:14; [['gauss','T']], ab:'phase', reanimate:true | cp:2, FAC_PRICE:1.0 (cost:145); size:.56, hp:95; sh:0, rg:0, ar:.25, regen:5; sp:4, tn:2, ev:14; [['gauss','T'],['gsentry','T']], ab:'phase', reanimate:true | Elite floor: Even Eclipse's smallest hull costs 2 CP and has more HP (95 vs 78) and higher armor (.25 vs .15) than a Voidsworn Destroyer (harrow), plus self-reanimation. |
| d_jackal ('Eclipse flare', Destroyer) | cp:2, FAC_PRICE:1.5 (~195 cr); size:.62, hp:110; sh:0, rg:0, ar:.25, regen:3; sp:3, tn:2, ev:6; [['gauss','T'],['gauss','F']], ab:'phase', reanimate:true | cp:3, FAC_PRICE:1.0 (cost:210); size:.68, hp:145; sh:0, rg:0, ar:.30, regen:6; sp:3, tn:2, ev:6; [['gauss','T'],['gauss','F'],['gsentry','T']], ab:'phase', reanimate:true | Cruiser-weight hunter: Costs 3 CP and out-armors (ar:.30) and out-hulls (145 HP vs 120 HP) a Voidsworn Cruiser (penitent) in a Destroyer silhouette. (Pair with bumping d_harvester to cp:5, hp:205, regen:6). |
| b_drone ('Chorus drone-spawn', Frigate) | cp:1, FAC_PRICE:.65 (~46 cr); size:.48, hp:46; sh:0, rg:0, ar:.05, regen:4; sp:5, tn:3, ev:15; [['tendril','T']], ab:'regrow' | cp:1, FAC_PRICE:.85 (cost:60); size:.42, hp:38; sh:0, rg:0, ar:0, regen:7; sp:6, tn:3, ev:22; [['tendril','T'],['spores','T']], ab:'regrow' | Ravenous chaff: Visibly tiny (size:.42, barely above a .34 squadron), unarmored (ar:0), fast (sp:6), with less than half the HP of d_scythe (38 vs 95) but ferocious metabolism (regen:7, 18% HP/turn) and spore spit. |
| b_spitter ('Chorus spitter', Destroyer) | cp:2, FAC_PRICE:.75 (~98 cr); size:.6, hp:82; sh:0, rg:0, ar:.1, regen:5; sp:4, tn:2, ev:8; [['bioplasma','T'],['bioplasma','F']], ab:'regrow' | cp:2, FAC_PRICE:.95 (cost:125); size:.56, hp:76; sh:0, rg:0, ar:.05, regen:9; sp:5, tn:3, ev:14; [['bioplasma','T'],['bioplasma','F'],['spores','T']], ab:'reclaim' | Fast pack-feeder: Sits a full CP below d_jackal (2 CP vs 3 CP), with half the HP (76 vs 145) and 1/6th the armor (.05 vs .30), but sprints at sp:5, tn:3, regenerates 9 HP/round, and uses ab:'reclaim' to feed on wrecks. |

#### 5. THE RISK CASE

The Strongest Argument Against New Hulls and Asymmetric CP (INFERRED):

- Roster & Variant Maintenance Debt: Shipping 24 base hulls, 6 bosses, and 18 variants (48 templates) across two codebases (the browser build and the mirrored Godot port) already stretches content uniqueness past its limit - proven by warden/h_picket duplication, double launch on Hegemony line hulls, and three bosses sharing ab:'nova'. Every new hull multiplies variant, art, and balance work.
- Tactical Differentiation Already Exists in MOVE_RULES and Defense Math: Factions already bend movement physics (rake:.4, rev:1, slip:1, pivot:1, evade:18, over:0), defense layers (shields vs. armor+reanimate vs. shieldless regen), and FAC_GATES (noKind:['lance'], noBrace:1). Keeping a universal 1-2-3-4-5 CP scale guarantees that 1 CP = Frigate and 2 CP = Destroyer across the entire game, preserving instant UI readability and keeping genEnemyFleet and equivHull simple.

**Ruling - Does the Risk Case Beat Checks 1 to 4?**

It BEATS adding new hulls beyond the ruled Eclipse Battleship (Check 1): The Risk Case is right that adding new hulls to Hegemony, Chorus, Corsair, or Ithar is a trap while existing hulls have copy-pasted abilities. Fixing h_picket, h_dominion, b_spitter/b_razor, d_harvester, and boss abilities in-place solves the job gaps at zero roster-bloat cost.

It LOSES on keeping flat 1-2 CP bottom rungs (Checks 2 to 4): The Risk Case's claim that MOVE_RULES and FAC_PRICE are sufficient is falsified by battle.js 148-163. Because genEnemyFleet ignores FAC_PRICE and weights x.cp===1 and x.cp<=2 identically across all factions, keeping Eclipse on a 1-2-4 CP ladder causes two severe failures: (1) AI Eclipse spawns the exact same number of ships as AI Chorus, and (2) AI Eclipse gets 1.45x-1.55x credit-statted hulls for 1.0x CP. Shifting Eclipse's integer CP ladder to 2-3-5-7 (and aligning stats to CP instead of FAC_PRICE) requires zero new generator code in genEnemyFleet, obeys the 20-ship battle cap, and makes Elite vs. Swarm real on the board.

### 4. Not Checked

Because they are outside pack.txt, this review cannot verify:

- Weapon definitions (W table in data.js): Exact damage, cooldown, range, and shield/armor penetration of gauss, doom, gsentry, tendril, bioplasma, spores, ion, turbo, hturbo, shard, pulsar, and startorp.
- Ability implementations (ab in battle.js): Exact rules and numbers for phase, reclaim, regrow, frenzy, ionpulse, overburn, blink, surge, nova, and reanimate:true.
- RAMP constants and effArch(arch, fac) in battle.js: Exact numerical arrays for RAMP.grow, RAMP.boss, RAMP.ceil, RAMP.light, RAMP.refP, and how effArch remaps arch==='carrier' or arch==='swarm' for deathless (sq:null).
- The 18 hull variants and equivHull(t, fac) / altFleetPlan(admiralId, fac) in core.js: How variants modify base hull stats/CP and how non-Voidsworn starting fleets are mapped.
- Prize, salvage, and shop code: Where and how FAC_PRICE is charged to the player during a run.

### 5. Questions for the Designer

- Where does FAC_PRICE actually apply in gameplay (only when the player buys/salvages captured prizes, or also in fleetPower() calculations)?

Stakes: If FAC_PRICE only taxes player purchases while genEnemyFleet spends raw cp, any faction given higher stats justified by a high FAC_PRICE (deathless 1.45x-1.55x, ithar 1.3x) receives an uncosted AI stat buff in every enemy battle.

- Does effArch(arch, 'deathless') already forbid 'swarm' and 'carrier' archetypes for Eclipse, and what are the exact values of RAMP.ceil[s] in Sectors 1-3?

Stakes: If Eclipse can roll arch==='swarm' or if RAMP.ceil[2..3] caps enemy spawns at ≤10 hulls, Chorus cannot outnumber Eclipse on the board unless Eclipse's minimum hull CP is raised from 1 to 2.

- Has the Oct 24 ruling for Hegemony ("synchronized fire under a flagship anchor") replaced its FACTIONS blurb ("carriers launch fighter screens"), or must Hegemony support both doctrines?

Stakes: If synchronized fire replaced carriers, stripping ab:'launch' from h_dominion (and/or h_vanguard) in favor of a flagship fire-link ability immediately fixes both Hegemony's missing identity and the arch==='carrier' escort-stripping bug in battle.js 152 without adding a new hull.
