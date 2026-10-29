Chair header: Argon High leg (Gemini 4 Argon, Thinking High, verified before and after sending) for the squadrons and carriers audit, Oct 29, 2026 program, pack pinned to main 264f441d. Filed verbatim below except em dashes and en dashes are normalized to hyphens. Browser method notes and citation chips are excluded per house rules and recorded in the screening note.

1. Proof of Reading

Pack Sections Read:

EVIDENCE PACK: squadrons and carriers audit (code slices from the shipped browser build, main 264f441d; the Godot port mirrors this design)

THE COMMISSIONER'S QUESTION

CHAIR CENSUS (verified from the code in this pack)

WHAT TO JUDGE

Code slices:

=== data.js: squadron hulls and every launch/hangar hull line ===

=== data.js 132-152: ABILITIES (launch and the rest) ===

=== data.js 506-520: WING_STANCES, WING_PERKS, WING_XP ===

=== battle.js 612-616: wing constants and stance changes ===

=== battle.js 149-165: how the enemy generator treats carriers ===

Overall Verdict: DUPLICATES WITH PAINT - spore is literally coded as sq:'bomber' with identical speed, turn, and evasion (sp:5,tn:9,ev:25) and 2 less HP, while the generator caps carrier fleets at a single launch hull (roster=roster.filter(x=>!x.car)), turning carrier encounters into standard gun lines with 1-3 wings attached.

2. Findings

[BLOCKER] arch==='carrier' lacks a guard for sq:null, generating wingless "carrier" fleets for Deathless and explaining false anti-wing previews.

READ: Deathless has roster:['d_scythe','d_jackal','d_harvester'],boss:'d_boss',sq:null and no hull with ab:'launch'. The census notes the preview layer "sometimes advises anti-wing play against factions with no wings". In battle.js, if(arch==='carrier'&&kind!=='boss') looks up const cr=roster.filter(x=>x.car&&x.cp<=budget+.3) and only modifies the fleet if(cr).

INFERRED: When arch==='carrier' is rolled for Deathless before entering this slice, cr is undefined, so genEnemyFleet silently falls through to the generic while loop and builds a wingless gun line while retaining the carrier archetype tag that drives the preview warning.

[BLOCKER] Tagging both Hegemony heavy hulls (h_vanguard and h_dominion) with ab:'launch' breaks Hegemony's heavy and carrier fleet generation.

READ: Hegemony's roster is ['h_picket','h_interdictor','h_vanguard','h_dominion'], where both h_vanguard (cp:4, hangar:1) and h_dominion (cp:6, hangar:1) have ab:'launch', setting car:HULLS[id].ab==='launch' to true. In battle.js, arch==='heavy' filters for x.cp>=2&&(!x.car||!roster.some(y=>y.cp>=3&&!y.car)), and arch==='carrier' picks the highest-CP carrier (sort((a,b)=>b.cp-a.cp)[0]) then runs roster=roster.filter(x=>!x.car).

INFERRED: In arch==='heavy', if h_interdictor has cp>=3, both h_vanguard (Cruiser) and h_dominion (Battleship) are banned from Hegemony heavy fleets; if h_interdictor has cp<3, heavy spawns h_dominion or h_vanguard just like carrier does. Meanwhile, in arch==='carrier' at budget>=5.7, the generator selects h_dominion (cp:6, hangar:1) and strips h_vanguard out of the escort pool, leaving a "carrier archetype" fleet with only a single fighter wing on the board.

[FIX] spore is a 2-HP-weaker clone of bomber that literally sets sq:'bomber', collapsing three squadron hulls into two.

READ: bomber is {size:.34,cp:0,hp:28,sh:0,rg:0,ar:0,sp:5,tn:9,ev:25,w:[['bombs','T']],sq:'bomber'} and spore is {fac:'chorus',size:.34,cp:0,hp:26,sh:0,rg:0,ar:0,sp:5,tn:9,ev:25,w:[['sporeb','T']],sq:'bomber'}. Even Chorus's faction line declares sq:'spore', yet the spore hull itself declares sq:'bomber'.

INFERRED: Unless sporeb behaves fundamentally differently from bombs in the omitted weapon table, spore and bomber make identical movement, evasion, durability, and target-priority ("ships first for bombers") decisions, making spore a reskinned bomber with -2 HP.

[FIX] WING_XP=[3,8,15] requires kill counts that enemy carriers cannot reach in a single battle and forces tedious kill-feeding for player carriers.

READ: const WING_XP=[3,8,15]; // wing kills a carrier's wings need for their first, second and third perk. Simultaneously, battle.js caps total fleet size via list.length<Math.max(4,ceil) 7 ceil player ships subtracts to up where>sh.hp>0).length)`).

INFERRED: Because enemy fleets are generated per battle with 4 to ~6 ships and player fleets hold at most ~7 ships, an enemy carrier's wings can almost never score 3 kills in a battle to unlock even Tier 1, and can mathematically never reach 8 or 15 kills. For a player carrier across a run, requiring 8 and 15 wing killing blows incentivizes stalling battles and holding capital-ship fire so squadrons can last-hit crippled hulls.

[FIX] ab:'launch' consumes the sole active ability slot on all 8 launch hulls but does nothing until a wing is destroyed.

READ: Every hull has a single ab key, and launch states: "Carriers start each battle with their wings in flight. This launches a replacement for a lost wing" with cd:1. Faction line ships instead get active abilities like ionpulse ("loses half of each shield facing"), frenzy ("+30% damage"), regrow ("Regrow 25% of this ship's hull"), or blink ("Jump to any open hex within 3").

INFERRED: Because wings start already deployed, a carrier has no active button to press on opening turns when fights are decided. On 1-hangar capital ships like h_dominion (cp:6) and h_vanguard (cp:4), trading an AOE shield strip (ionpulse) or focus (+30% damage on 3-4 weapons) for a single spare 18-HP fighter is a net downgrade.

[FIX] Hangar pricing across CP 4-6 hulls is badly skewed: h_dominion and i_carrier overpay while b_brood and c_hulk get massive value.

READ: At CP 5, b_brood gets hp:200, ar:.2, regen:8, hangar:3 (launching three 26-HP spore bombers + 3 spares = 156 total wing HP), whereas i_carrier (also CP 5) gets hp:140, sh:28, rg:10, ar:.05, sp:4, tn:2, ev:12, hangar:2 (launching two 18-HP fighter wings + 2 spares = 72 total wing HP). At CP 4, c_hulk (hp:170, sh:16, rg:6, ar:.2, hangar:2, two turret mounts, bomber wings) out-stats reliquary (hp:130, sh:22, rg:9, ar:.15, hangar:2, one turret + one flak).

INFERRED: i_carrier pays +1 CP over c_hulk while losing 30 HP, 0.15 armor, and 20 in-flight wing HP, and forfeiting Ithar's blink/phase abilities on a fragile (ar:.05) hull.

[FIX] WING_SCREEN_R=2 tethers screening wings to sp:2 carriers, preventing them from screening front-line ships and making the pickets perk self-contradictory.

READ: WING_SCREEN_R=2 and screen states: "Wings stay within 2 hexes of their carrier, hunt enemy craft first, and shoot down torpedoes aimed at ships beside them". Six of the eight launch hulls (reliquary, h_dominion, c_hulk, c_boss, b_brood, b_boss) have sp:2. The pickets perk states: "Screening wings shoot down torpedoes more often".

INFERRED: Because sp:2 carriers lag behind sp:3-4 escorts, wings leashed within 2 hexes of the carrier cannot reach front-line ships to intercept torpedoes aimed at them unless the entire fleet clumps around the slow carrier. Furthermore, wings kept in screen within 2 hexes of a rear carrier will not earn the [3,8,15] kills needed to unlock pickets.

[FIX] arch==='carrier' forces a 1-carrier ceiling (roster=roster.filter(x=>!x.car)) and fills the rest of the budget with standard gun-line weights.

READ: In battle.js, arch==='carrier' pushes a single carrier cr, executes roster=roster.filter(x=>!x.car), and uses the default while loop weights wts to buy non-carrier ships.

INFERRED: An enemy "carrier fleet" can never field two carriers (e.g., two c_hulks or h_dominion + h_vanguard) and has no escort-specific weighting (such as preferring point-defense or torpedo ships), making it play like a normal gun line with 1-3 wings attached.

[NOTE] WING_SCREEN_TORP=.45 turns high-cooldown torpedoes into a high-variance coin flip.

READ: WING_SCREEN_TORP=.45 and reload has cd:3 ("Torpedo tubes are ready to fire again immediately").

INFERRED: Because torpedo weapons require long reloads, a 45% probabilistic delete per shot (or ~70-83% if rolled multiplicatively per wing across 2-3 wings) creates binary feast-or-famine outcomes rather than predictable attrition.

[NOTE] Hunt stance applies its -10 evasion penalty ("10 easier to hit") even when no enemy ship is below half hull.

READ: hunt states: "Wings range 4 hexes further and go for crippled ships (+20% damage below half hull), but fly exposed (10 easier to hit)" and WING_HUNT_LEASH=4.

INFERRED: Using hunt early in a battle solely for the +4 hex leash extension strips 10 evasion from unshielded, unarmored wings (ev:35 -> 25 on fighters; ev:25 -> 15 on bombers/spores) for zero damage gain until an enemy drops below 50% hull.

3. Explicit Checks
1. WING JOBS

Fighter (fighter): Fast, high-evasion, low-HP interceptor and torpedo-screener (hp:18, sp:6, tn:9, ev:35, w:[['guns','T']], sq:'fighter').

Bomber (bomber): Slower, higher-HP anti-ship strike wing that prioritizes capital ships in Strike stance (hp:28, sp:5, tn:9, ev:25, w:[['bombs','T']], sq:'bomber').

Spore (spore): Slower, higher-HP anti-ship strike wing that prioritizes capital ships in Strike stance (hp:26, sp:5, tn:9, ev:25, w:[['sporeb','T']], sq:'bomber').

Flagged Pair: Bomber and Spore come out the same (READ: identical size:.34, cp:0, sh:0, rg:0, ar:0, sp:5, tn:9, ev:25, turret arc 'T', and sq:'bomber' tag, differing only by 2 HP and weapon key 'bombs' vs 'sporeb').

2. HANGAR ECONOMY

(Note: Non-launch faction sibling hull stats are omitted from the pack; comparisons below use the 8 launch hulls across CP tiers and the faction ABILITIES table as READ, with sibling comparisons marked INFERRED.)

reliquary (Voidsworn Carrier, CP 4, hangar:2):

Cost: Gives up an active player ability (focus, surge, reclaim, nova) for ab:'launch', drops to hp:130, sh:22, ar:.15, sp:2, ev:0, and carries only 1 offensive weapon (['turret','T']) plus 1 defensive ['flak','T'].

Fairness: Underpowered at CP 4 (INFERRED). Compared to c_hulk (also CP 4, hangar:2), reliquary has -40 HP, -0.05 armor, and gives up a second offensive turret for flak.

h_vanguard (Hegemony Cruiser, CP 4, hangar:1):

Cost: Retains full Cruiser stats (hp:140, sh:24, rg:10, ar:.2, sp:3, ev:4) and 3 offensive mounts (2x turbo ['T'], 1x ion ['F']), paying primarily with its ability slot (ab:'launch' instead of ionpulse or focus) for 1 fighter wing.

Fairness: Fair chassis, weak ability trade (INFERRED). It keeps a complete 3-gun cruiser loadout at CP 4, so the single fighter wing effectively replaces ionpulse.

h_dominion (Hegemony Battleship, CP 6, hangar:1):

Cost: Keeps Battleship durability (hp:230, sh:32, rg:12, ar:.25, sp:2) and 4 mounts (hturbo ['P'], hturbo ['S'], ion ['F'], flak ['T']), but trades a Battleship-scale active ability (ionpulse, surge, focus, nova) for ab:'launch' with only hangar:1, while getting tagged car:true in the generator.

Fairness: Unfair / Bad trade (INFERRED). Spending a 6-CP Battleship's active ability slot (and breaking its generator archetype tag) for a single 18-HP fighter wing is the worst carrier value in the game.

c_hulk (Corsair Carrier, CP 4, hangar:2):

Cost: Trades Corsair active abilities (overburn or frenzy) and some shield capacity (sh:16, rg:6) for hp:170, ar:.2, sp:2, two ['turret','T'] mounts, and hangar:2 launching 28-HP bomber wings.

Fairness: Very strong / Fair-to-generous (INFERRED). At CP 4, 170 HP + .20 armor + two turrets + two 28-HP bomber wings (56 wing HP in flight, 56 in reserve) outclasses reliquary and i_carrier per CP.

c_boss (Corsair Battle-barge, CP 10 Boss, hangar:2):

Cost: Retains full boss stats (hp:600, sh:30, rg:8, ar:.25, 4 weapons) and gets hangar:2 (bombers), paying only its ab slot (launch instead of frenzy/overburn).

Fairness: Fair for a boss, though passive (INFERRED). Giving up frenzy (+30% damage on 4 boss weapons) keeps burst damage in check while adding two bomber wings.

b_brood (Chorus Carrier, CP 5, hangar:3):

Cost: Trades regrow (25% instant heal) and shields (sh:0) for hp:200, ar:.2, regen:8, two weapons (bioplasma ['F'], spores ['T']), and hangar:3 launching three 26-HP spore bombers (78 HP in flight + 78 HP in reserve).

Fairness: Over-tuned in its favor - the best carrier value in the game (INFERRED). For 5 CP, it puts 3 bomber-equivalent wings on the board Turn 1 (plus 3 spares) on a 200-HP regenerating hull.

b_boss (Chorus Bio-titan, CP 12 Boss, hangar:3):

Cost: Full boss statblock (hp:650, ar:.25, regen:20, 4 weapons) plus hangar:3, trading regrow (162.5 HP instant heal on cd:3) for ab:'launch'.

Fairness: Fair (INFERRED). Replacing a 162-HP burst heal every 3 turns with 3 replaceable spore wings creates a distinct swarm-titan encounter.

i_carrier (Ithar Carrier, CP 5, hangar:2):

Cost: Pays 5 CP for hp:140, sh:28, rg:10, ar:.05, sp:4, tn:2, ev:12, two weapons (pulsar ['F'], turret ['T']), and hangar:2 launching 18-HP fighter wings, while losing Ithar's blink / phase abilities.

Fairness: Unfair / Overpriced (Worst dedicated Carrier hull, second worst overall after h_dominion) (INFERRED). At the same 5 CP as b_brood, it has 60 less HP, 0.15 less armor, 1 fewer hangar slot, and launches 18-HP fighters instead of 26-HP bombers.

3. STANCES AND VETERANCY

Do stances create decisions a player plans around? Partially reactive, not multi-turn planning (INFERRED). Because setStance is free and gated only by u.stanceRound!==B.round, players reactively flip stances at the start of a round rather than planning turns ahead. However, because canStance locks the stance for the entire round (u.stanceRound!==B.round), choosing hunt on your turn leaves wings at -10 evasion during the enemy turn.

Do kill-perks create decisions a player plans around? No (INFERRED). With WING_XP=[3,8,15] requiring wing kills, enemy carriers never interact with the ladder, and players can only reach 8 or 15 kills late in a run or by artificially feeding last hits to wings.

Dead weight stance: Screen on bomber/spore carriers (c_hulk, c_boss, b_brood, b_boss) and on rear-line sp:2 carriers when no enemy torpedoes/wings are within 2 hexes (INFERRED). Because WING_SCREEN_R=2 tethers wings within 2 hexes of a sp:2 carrier, screening wings cannot protect front-line ships advancing ahead of the carrier.

Dead weight perks: pickets ("Screening wings shoot down torpedoes more often") and armored ("Wings have 25% more hull") (INFERRED). pickets requires kill XP ([3,8,15]) that defensive screening wings do not earn and does nothing against fleets without torpedoes. armored adds only +4.5 HP to an 18-HP unshielded/unarmored fighter (hp:18, sh:0, ar:0), which rarely changes shots-to-kill.

4. COUNTERPLAY

Is point defense a real answer at the mount counts in the pack? Chassis coverage exists (11 flak, 1 gsentry across the roster, plus 2 spores turrets on Chorus carriers), but weapon efficacy cannot be verified from the pack (READ/INFERRED). Within the 8 launch hulls, only 3 carry flak (reliquary, h_dominion, c_boss). On a 2-mount ship like reliquary (w:[['turret','T'],['flak','T']]), dedicating 50% of weapon mounts to flak is a heavy offensive tax when facing wingless fleets (especially when the preview false-positives on Deathless).

Does the torpedo-screen interaction make carriers defensive assets? Only for the carrier itself and ships parked within 2 hexes of it (INFERRED). Because WING_SCREEN_R=2 forces screening wings to stay within 2 hexes of their carrier and intercept torpedoes "aimed at ships beside them", a slow sp:2 carrier cannot project a torpedo screen over advancing brawlers without forcing the whole fleet into an AoE-vulnerable clump.

Is 0.45 (WING_SCREEN_TORP=.45) the right kind of number? No (INFERRED). A flat 45% roll per torpedo is too swingy for high-cooldown ordnance (reload is cd:3): if rolled once per torpedo, 1 wing is as good as 3 wings; if rolled multiplicatively per wing, 2-3 wings plus pickets nullify torpedo ships via RNG rather than positioning or ammo/interception limits.

5. THE CARRIER FIGHT

From the generator slice, does a carrier-archetype fleet fight differently from a gun line? No - it is a gun line with 1-3 wings attached (and 0 wings for Deathless) (READ/INFERRED).

READ: if(arch==='carrier'&&kind!=='boss') selects at most one carrier (const cr=roster.filter(x=>x.car&&x.cp<=budget+.3).sort((a,b)=>b.cp-a.cp)[0]), immediately bans all other carriers from the fleet (roster=roster.filter(x=>!x.car)), and spends the remaining budget in the exact same while loop with the exact same light/medium ship weights (wts) as a standard fleet.

INFERRED: Because only 1 carrier can spawn per carrier fleet, Hegemony spawns a single 1-wing ship (h_dominion or h_vanguard), Corsair and Ithar spawn a single 2-wing ship (c_hulk or i_carrier), Deathless spawns 0 carriers, and only Chorus (b_brood) spawns 3 wings. With 4+ ships on the board and only 1-2 wings for three of the four carrier factions, the encounter plays as a standard gun line with a minor squadron attachment.

4. Not Checked

This pack does not include the code required to judge:

Weapon definitions (WEAPONS in data.js): Damage, range, accuracy, cooldowns, and anti-squadron modifiers for guns, bombs, sporeb, flak, gsentry, spores, and capital ship weapons (including whether sporeb has any special effect that differentiates spore from bomber, or whether flak is viable against capital ships).

Non-launch faction sibling hulls in data.js: The exact stats, CP costs, weapon mounts, and ab assignments of h_picket, h_interdictor, c_raider, c_reaver, c_marauder, b_drone, b_spitter, b_razor, i_wisp, i_blade, i_song, d_scythe, d_jackal, d_harvester, the non-carrier bosses (h_boss, i_boss, d_boss), and non-carrier voidsworn player hulls.

Wing combat and movement execution in battle.js: The base leash radius in strike stance, how wings move/act during a turn, whether WING_SCREEN_TORP=.45 rolls once per torpedo or once per screening wing, the exact numerical bonus of pickets, how fx.hive works (u.fx&&u.fx.hive), and how the player's reliquary chooses between fighter and bomber squadrons.

Wing XP persistence and perk selection: Whether WING_XP=[3,8,15] counts only wing killing blows or assists, whether XP persists across battles in a run, and whether perks are chosen by the player or rolled randomly.

Encounter archetype selection and preview logic: Where arch is rolled before genEnemyFleet and how the UI preview decides to warn the player about enemy wings.

5. Questions for the Designer

Should h_dominion (a 6-CP Battleship with hangar:1) really be tagged as a carrier (ab:'launch') instead of a heavy line ship with a faction ability?

Stakes: As written, ab:'launch' on h_dominion hijacks Hegemony's carrier archetype into spawning a 1-wing Battleship while excluding h_dominion and h_vanguard from heavy fleets whenever h_interdictor is CP 3+.

What is spore (sq:'bomber', w:[['sporeb','T']]) supposed to do differently from bomber (sq:'bomber', w:[['bombs','T']])?

Stakes: If sporeb does not apply a distinct mechanic (such as hull corrosion, self-destruct on impact, or bio-regen suppression), Chorus's signature squadron is just a bomber with 2 less HP.

Is WING_XP=[3,8,15] intended to track wing last-hit kills across an entire run, or damage/participation per battle?

Stakes: If it tracks last-hit kills, enemy carriers never use the perk system at all and players are rewarded for stalling fights to feed killing blows to squadrons instead of finishing enemies with capital guns.
