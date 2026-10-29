Chair note: this Qwen3.8-Max run (Oct 29, 2026, both model gates passed) returned TWO parallel complete responses (the UI's "which response do you prefer" state). Both are filed in full below, neither was selected. Response 1 verdict: DUPLICATES WITH PAINT. Response 2 verdict: MOSTLY DISTINCT. Em dashes, en dashes, and unicode minus signs in the model's text are normalized to hyphens; wording otherwise verbatim.

=== RESPONSE 1 ===

Proof of reading
Read, in order:
EVIDENCE PACK title line - "squadrons and carriers audit (code slices from the shipped browser build, main 264f441d; the Godot port mirrors this design)".
THE COMMISSIONER'S QUESTION - judge the wing arm, the hangar-vs-gun economy, and whether the layer earns its complexity.
CHAIR CENSUS - three squadron hulls, eight launch hulls, Deathless/Eclipse excluded by the Oct 29, 2026 ruling, stances/perks at 3/8/15, torpedo screen at 0.45, carrier generator archetype, 11 flak + 1 gsentry mounts, preview anti-wing advice against wingless factions.
WHAT TO JUDGE - items 1-5.
Code slices - data.js squadron/launch hull lines and faction rosters; data.js 132-152 ABILITIES/ORDERS/fx keys; data.js 506-520 WING_STANCES/WING_PERKS/WING_XP; battle.js 612-616 wing constants and stance functions; battle.js 149-165 genEnemyFleet archetypes and fill loop.
Verdict: DUPLICATES WITH PAINT - the third wing is literally tagged as a bomber, and the "carrier fight" is the ordinary fleet fill loop with one carrier prepended.

Findings
[BLOCKER] The spore wing is a bomber with a different weapon key.
READ: spore carries sq:'bomber', w:[['sporeb','T']], hp 26, sp 5, ev 25; bomber is sq:'bomber', w:[['bombs','T']], hp 28, sp 5, ev 25.
INFERRED: the Chorus "third job" is a reskin, not a third decision; the roster supports two wing jobs, not three.
[BLOCKER] The perk ladder cannot be judged as written.
READ: six entries in WING_PERKS against const WING_XP=[3,8,15];, with no threshold→perk mapping, no selection rule, and no perk-application code in the pack.
INFERRED: "earn veterancy perks from kills" is a promise, not a plannable build path; which perk arrives at which kill count is undefined in the evidence.
[FIX] A hangar buys attrition insurance, not a firing slot.
READ: "Carriers start each battle with their wings in flight." and "launches a replacement for a lost wing"; launch has cd:1.
INFERRED: the hangar's marginal value is the second life of an arm, so pricing it against a gun requires wing damage and loss rates, neither of which is in the pack. Any "hangar = X guns" claim would be invented.
[FIX] The preview layer recommends a counter to an arm that cannot exist.
READ: Deathless/Eclipse "has no launch hull at all", sq:null, and the preview "sometimes advises anti-wing play against factions with no wings"; the no-carrier ruling is explicit.
INFERRED: that advice is a straight-up false readout, and it poisons the player's loadout decision rather than merely being suboptimal.
[FIX] The carrier archetype is an assembly rule, not a battle doctrine.
READ: the carrier branch pushes one carrier, then roster=roster.filter(x=>!x.car); and falls into the same while(budget>=1 …) fill loop as every other archetype.
INFERRED: there is no escort-selection, screening, or positioning rule specific to carriers; the fight is a gun line with one wing platform inside it.
[FIX] The torpedo screen is a real hook with an unbounded-looking number behind it.
READ: WING_SCREEN_R=2, WING_HUNT_LEASH=4, WING_SCREEN_TORP=.45;; pickets only says "shoot down torpedoes more often".
INFERRED: without per-attempt vs per-salvo semantics, stacking across wings, or a cap, 0.45 cannot be certified as balanced; two screening carriers could plausibly compound into near-immunity.
[FIX] The reliquary loses an identical-budget comparison to the corsair carrier.
READ: both are cp:4, hangar:2; reliquary is hp:130, w:[['turret','T'],['flak','T']], cost:260; c_hulk is hp:170, two turret mounts.
INFERRED: assuming flak and turret are not wildly unequal, the Voidsworn carrier pays the same CP for 40 less hull and less direct gunpower; it is the weakest visible dedicated-carrier purchase.
[NOTE] Hunt is a gamble the fighter wing is least able to survive.
READ: hunt gives "10 easier to hit"; fighter is hp:18 … ev:35.
INFERRED: on an 18-hull craft, trading 10 evasion for +4 range and "+20% damage below half hull" is likely a poor default on anything but a already-crippling target; the perk jinkers ("8 harder to hit") partly refunds the same currency it spends.
[NOTE] The launch-hull census is not necessarily the wing-source census.
READ: canStance accepts u.ab==='launch'||(u.fx&&u.fx.hive).
INFERRED: hive-flagged units can command wings without being launch hulls, so "8 hulls carry launch" does not establish an eight-hull ceiling on the wing arm.

Explicit checks
WING JOBS
Fighter: fast, fragile gun wing - 18 hull, speed 6, evasion 35, guns; inferred job is a survivable skirmishing/interception screen, not a ship-killer.
Bomber: slow, tough ship-first wing - 28 hull, speed 5, evasion 25, bombs; Strike explicitly hits "ships first for bombers".
Spore: Chorus bomber - 26 hull, speed 5, evasion 25, sporeb, and sq:'bomber'.
Flagged pair: bomber / spore. Their one-liners come out the same job; only the weapon key and 2 hull differ. There is no spore-specific stance, targeting, or role rule in the pack. Fighter vs bomber is a genuine fragility/damage trade; the third slot is not.

HANGAR ECONOMY
Assumption (INFERRED): the hangar is paid for in CP, hull budget and the ab slot; the pack contains no non-launch sibling stat lines to diff, so no exact "one gun removed" claim is supportable. Only reliquary has a cost field in the slice.

Launch hull | Hangar / CP | Visible loadout and price paid | Fair?
reliquary (voidsworn) | 2 / 4, cost:260 | turret + flak; 130 hp, 22 sh, rg 9, ar .15 | Not as printed. Same CP and hangar as c_hulk with 40 less hull and one fewer direct gun; only range/shields/flak argue for it. No Voidsworn sibling line exists to defend it.
h_vanguard (hegemony) | 1 / 4 | turbo, turbo, ion; 140 hp, 24 sh, ev 4 | Plausible hybrid. Keeps a three-gun cruiser loadout and buys only one reserve; a light escort-carrier, not a carrier economy.
h_dominion (hegemony) | 1 / 6 | hturbo P, hturbo S, ion F, flak T; 230 hp, 32 sh | Poor hangar value. Worst slots-per-CP on the roster (1/6) versus c_hulk's 2/4; defensible only as a gunship that happens to carry a spare.
c_hulk (corsair) | 2 / 4 | two turrets; 170 hp, 16 sh, rg 6, no flak | Fair, and the cleanest baseline. Two guns plus two wings at 4 CP; pays in armour, short range and zero PD.
c_boss (corsair) | 2 / 10 | scatter P/S, htorp F, flak T; 600 hp | Fair as a boss package. The hangar is additive on a 600-hull barge; not a normal economy comparison point.
b_brood (chorus) | 3 / 5 | bioplasma F, spores T; 200 hp, 0 sh, regen:8 | Best value. Three slots plus self-repair at 5 CP; the regen directly protects the replacement pool.
b_boss (chorus) | 3 / 12 | two bioplasma, tendril, spores; 650 hp, regen:20 | Strongest raw package, but a boss; excluded from normal value ranking.
i_carrier (ithar) | 2 / 5 | pulsar F, turret T; 140 hp, 28 sh, ar .05, sp 4, ev 12 | Fair only as a mobile glass screen. Buys speed, turns and shields instead of hull/armor; 0.05 armor means the wing reserve is doing real survival work.

Best carrier value: b_brood (INFERRED - 3 hangar + 8 regen at 5 CP).
Worst dedicated-carrier value: reliquary (INFERRED - same 4 CP / hangar 2 as c_hulk, weaker visible hull and gun budget, and the only listed price, 260). h_dominion is the worst hangar-per-CP purchase overall.

STANCES AND VETERANCY
Stances: yes, real decisions, one per round. READ: canStance gates on u.stanceRound!==B.round. The three options are genuinely different positional contracts: Strike is reach-and-priority automation; Screen trades freedom for a 2-hex leash, craft-first targeting and torpedo interception; Hunt buys +4 range and +20% vs sub-half-hull targets at "10 easier to hit". A player can plan a screen-the-brood turn versus a hunt-the-cripple turn. The pack does not show an action cost, so I do not claim one.
Veterancy: not yet a decision system. Six perks, three thresholds, no mapping (Finding 2). You cannot plan a 3/8/15-kill build when the reward order is absent.
Dead weight: reserve ("The carrier holds one more spare wing") is the weakest perk (INFERRED): it pays only after a wing is already lost, on a hull whose launch is already defined as one spare per slot, and the pack never shows it modifying that count - although an hangar fx key exists. pickets is a close second, being inert outside Screen and unquantified even inside it. Strike is a default, not a dead stance.

COUNTERPLAY
Point defense: unproven, and thinly spread. READ: "flak (11 mounts across the roster) and gsentry (1 mount)" - 12 PD mounts total, against wings of 18/28/26 hull and 35/25/25 evasion. Only three flak mounts are visible in the launch lines, two of them on carrier-side hulls (reliquary, h_dominion, c_boss). INFERRED: with no flak damage, hit chance, vs-craft rule or per-faction distribution, "11 mounts" is a count, not an answer; and carriers partly carry their own counter. The concrete failure is the preview advising anti-wing loadouts against Deathless, which cannot launch (Finding 4).
Torpedo screen: yes, it makes carriers defensive assets. READ: Screen wings "stay within 2 hexes", "hunt enemy craft first", and intercept torpedoes "aimed at ships beside them" at .45. That converts a carrier from a damage dealer into a mobile escort shield - a genuinely different job from a gun line.
Is 0.45 the right kind of number? Yes in shape: a bounded 0-1 per-attempt interception probability is the correct instrument for a screen, not a flat damage discount. No as a certified balance value: the pack gives no torpedo damage, salvo size, hit roll, stacking rule or cap, and pickets supplies no delta. INFERRED: 0.45 is plausible as a single-wing hook and dangerous as an uncapacitated multiplier.

THE CARRIER FIGHT
From the generator slice: a gun line with wings attached. READ: the carrier archetype selects the costliest affordable carrier, subtracts its CP, strips other carriers from the roster, then hands the remainder to the same weighted fill loop used by the default line; only heavy gets its own Math.pow(x.cp,1.6) weighting. There is no escort tag, no screen formation, no wing-aware budget reservation and no carrier-specific positioning. INFERRED: the fight differs in composition (one fragile high-value node plus cheap escorts via the shared RAMP.light bias) but not in doctrine. Also READ: arch==='carrier'&&kind!=='boss', so boss fights do not use this branch, and Deathless's carrier archetype silently degrades to a normal line because it has no car entry.

Not checked
Wing weapon damage, range, attack timing, and whether wings act as independent units - guns/bombs/sporeb stat lines are absent.
Flak/gsentry damage, accuracy, vs-craft rules, and which hulls hold the 11/1 mounts.
Perk-to-threshold mapping, perk selection, XP attribution, and effect wiring (including the hangar, sqPct, sqHp, flakPlus, huntPct fx keys).
Non-launch sibling hull stats and every price except reliquary's 260; therefore no true like-for-like hangar-vs-gun invoice.
Torpedo damage/salvo/hit rules, screen stacking and caps, and stance action cost.
Actual AI stance quality beyond the one-line comment, run length, drafting, carrier survival rates, and player win rates.
Deathless carrier balance (excluded by ruling), hive-wing sources, and Godot parity beyond the title claim.

Questions for the designer
Will spore get its own sq key and a distinct job rule, or should the roster admit two wing types? Right now the Chorus pays for a third identity and receives a second bomber.
Where is the perk→threshold map and the wing/flak combat math? Without them, 3/8/15 kills buys an unverifiable promise and no player can build toward a payoff.
Will you invoice reliquary against c_hulk at 4 CP / hangar 2 on matched sibling hulls? Players are spending a carrier's whole budget on replacement insurance whose return is currently unmeasured.

=== RESPONSE 2 ===

SQUADRONS AND CARRIERS AUDIT REPORT

Proof of Reading
Sections read: EVIDENCE PACK title line ("EVIDENCE PACK: squadrons and carriers audit (code slices from the shipped browser build, main 264f441d…)"); THE COMMISSIONER'S QUESTION; CHAIR CENSUS; WHAT TO JUDGE (items 1-5); data.js squadron hulls and every launch/hangar hull line; data.js 132-152 ABILITIES and ORDERS; data.js 506-520 WING_STANCES, WING_PERKS, WING_XP; battle.js 612-616 wing constants and stance functions; battle.js 149-165 genEnemyFleet carrier-archetype slice.
Verdict: MOSTLY DISTINCT. Fighter and bomber are genuinely different combat roles; spore is a bomber with a name change; the carrier layer creates real tactical decisions through stances and the torpedo screen, but the generator and perk pipeline are too thin to sustain the complexity they introduce.

Findings
1. [BLOCKER] Spore is a bomber reskin, not a third role.
READ: The spore hull carries sq:'bomber', hp:26, sp:5, ev:25, weapon ['sporeb','T']. The bomber hull carries sq:'bomber', hp:28, sp:5, ev:25, weapon ['bombs','T']. The only deltas are 2 hp and a weapon key. Because both are tagged sq:'bomber', the strike stance's "ships first for bombers" logic applies identically. INFERRED: unless the sporeb weapon table (not in the pack) encodes a fundamentally different delivery (area, DoT, anti-shield), the Chorus variant changes nothing a player plans around. The commissioner asked for three jobs; the pack delivers two jobs and a palette swap.
2. [FIX] The perk ladder has no visible selection mechanism.
READ: WING_PERKS lists six perks and WING_XP=[3,8,15] sets thresholds, but no code slice shows a player choosing among perks or a deterministic assignment rule. INFERRED: perks are either auto-assigned (removing player agency from the "ladder") or the selection logic lives outside this pack. Either way the pack cannot confirm the ladder "create[s] decisions a player plans around."
3. [FIX] "Picket pilots" perk has no number.
READ: The perk reads "Screening wings shoot down torpedoes more often." The base intercept is WING_SCREEN_TORP=.45. No additive or multiplicative bonus is stated anywhere in the pack. INFERRED: without a number, the perk is un-tunable and the player cannot weigh it against "Jinkers" (+8 evasion) or "Aces" (+10 aim). It is currently dead weight in the perk pool.
4. [FIX] The carrier-archetype generator is one line of selection, not a doctrine.
READ: The generator slice does roster.filter(x=>x.car&&x.cp<=budget+.3).sort((a,b)=>b.cp-a.cp)[0], pushes that hull, subtracts its CP, then removes all carriers from the remaining pool and falls into the generic weighted loop. INFERRED: the "escort" is whatever the standard randomiser draws. There is no escort-shape logic (no screen-weighting, no flak preference, no minimum escort count). A carrier fleet and a gun line differ only in that one slot is a carrier; the composition around it is statistically identical.
5. [FIX] The reliquary is the worst carrier value in the game.
READ: reliquary at cp:4 carries w:[['turret','T'],['flak','T']],ab:'launch',hangar:2. One offensive mount (turret) and one point-defense mount (flak). INFERRED: compared to h_vanguard at the same cp:4 with turbo, turbo, ion plus hangar:1, the reliquary trades two offensive mounts for one extra hangar slot and a flak gun it may never need in a voidsworn mirror. The hangar costs the reliquary roughly 60% of its broadside.
6. [NOTE] Hunt stance is a trap for fighters.
READ: Hunt makes wings "10 easier to hit." Fighter evasion is 35; hunt drops it to 25. Bomber/spore evasion is 25; hunt drops it to 15. INFERRED: a hunting fighter is now easier to hit than a striking bomber. The +20% damage below half hull does not compensate for a 28% relative survivability loss on the squishiest wing. Rational play is to hunt with bombers/spores only, collapsing the stance decision for fighter carriers.
7. [NOTE] Deep reserves is the weakest perk in the ladder.
READ: "The carrier holds one more spare wing." The launch ability already grants "one spare wing per hangar slot" at cd:1. INFERRED: Deep reserves is a one-shot band-aid that only triggers after a wing dies, while Aces (+10 aim), Armored (+25% hp), and Ship killers (+15% damage) are permanent combat modifiers. At the 15-kill threshold, a player who reaches it gets the least impactful option unless the pool is random.
8. [NOTE] The Deathless/Eclipse faction is fully locked out and the UI leaks.
READ: The roster line shows sq:null for Deathless. The CHAIR CENSUS records the designer's Oct 29, 2026 ruling: "it stays that way (no carrier)." The census also states "the preview layer sometimes advises anti-wing play against factions with no wings." INFERRED: the advisory bug means Deathless players see flak recommendations for a threat that does not exist, undermining trust in the tool.
9. [NOTE] The 0.45 torpedo-screen rate is flat and unscaled.
READ: WING_SCREEN_TORP=.45 is a single constant. No interaction with torpedo speed, wing hp, number of screening wings, or torpedo type is shown. INFERRED: three screening wings from a b_brood (hangar:3) each roll 0.45 independently, giving a cumulative ~83% intercept. That is very strong and may make Chorus carriers torpedo-immune without any counterplay scaling. The number is the right kind (a probability), but the flatness removes the carrier's vulnerability arc.
10. [NOTE] i_carrier is the only launch hull that plays as a skirmisher.
READ: i_carrier has sp:4, tn:2, ev:12, ar:.05. Every other carrier has sp:2, tn:1, ev:0. INFERRED: the Glasswright aperture is a genuine design outlier - fast, evasive, fragile - and justifies its cp:5 cost through mobility rather than raw wing count. It is the best argument that launch hulls can occupy distinct tactical niches beyond "more hangar."

Explicit Checks
WING JOBS
Fighter: Fast interceptor (sp:6, ev:35, hp:18), guns, fragile - jobs: screen, dogfight, hunt lightly armoured targets.
Bomber: Slow bruiser (sp:5, ev:25, hp:28), bombs, targets ships first in strike - job: anti-hull damage.
Spore: Slow bruiser (sp:5, ev:25, hp:26), sporeb weapon, tagged sq:'bomber' - job: identical to bomber by every behavioural flag in the pack.
FLAG: Bomber and spore one-liners come out the same. The spore is a Chorus-flavoured bomber with 2 fewer hit points and a different weapon key. The pack does not contain the weapon table to prove sporeb differs from bombs in damage type or delivery, so I cannot clear it. As presented, two of three wings are one wing with two skins.

HANGAR ECONOMY
Hull | Faction | CP | Guns carried alongside launch | Hangar | Cost assessment
h_vanguard | Hegemony | 4 | turbo T, turbo T, ion F (3 mounts) | 1 | Hangar is nearly free; full gun complement retained
h_dominion | Hegemony | 6 | hturbo P, hturbo S, ion F, flak T (4 mounts) | 1 | Hangar bolted onto a dreadnought; negligible trade
c_hulk | Corsair | 4 | turret T, turret T (2 mounts) | 2 | Trades ~2 offensive mounts for a second wing; thin
c_boss | Corsair | 10 | scatter P, scatter S, htorp F, flak T (4 mounts) | 2 | Boss budget absorbs the hangar easily
b_brood | Chorus | 5 | bioplasma F, spores T (2 mounts) | 3 | Three wings for two guns and no shields; wing-dense
b_boss | Chorus | 12 | bioplasma F×2, tendril T, spores T (4 mounts) | 3 | Boss; regen:20 offsets the gun gap
i_carrier | Ithar | 5 | pulsar F, turret T (2 mounts) | 2 | Pays in armor (ar:.05); buys speed and evasion instead
reliquary | Voidsworn | 4 | turret T, flak T (1 offensive, 1 PD) | 2 | Pays the most: one offensive gun for two wings

Best carrier value: h_vanguard. It keeps three offensive mounts and an ion cannon while carrying a wing. The hangar costs effectively nothing against its faction siblings. READ (stats); INFERRED (value judgement, since h_picket and h_interdictor stats are not in the pack).
Worst carrier value: reliquary. At cp:4 it fields one turret and one flak gun. The flak is defensive; the turret is a single medium mount. A player choosing the reliquary over a gun hull is paying 4 CP for two wings and a turret. INFERRED: the voidsworn faction's only carrier is its weakest cp:4 option unless the wings consistently outperform a second gun mount, which the pack cannot confirm without damage tables.
Caveat: The non-carrier siblings (h_picket, h_interdictor, c_raider, c_reaver, c_marauder, b_drone, b_spitter, b_razor, i_wisp, i_blade, i_song) are not in the pack. I cannot complete the sibling comparison the commissioner requested. All faction-relative cost judgements above are INFERRED from the launch hulls alone.

STANCES AND VETERANCY
Stances: Yes, they create decisions. Strike is the default; Screen trades 4+ hexes of leash for torpedo interception and craft-hunting; Hunt trades 10 evasion for +4 hex range and +20% execute damage. The once-per-round lock (u.stanceRound!==B.round) means the player commits each turn and cannot micro-toggle. The AI comment confirms the enemy uses the same three-way read ("screen against torpedoes or many craft, hunt a crippled ship, else strike"). This is a real decision triangle.
Perk ladder: The 3/8/15 kill thresholds create a progression arc across a roguelite run. However, no selection UI or assignment logic is in the pack (Finding 2). If perks are auto-assigned, the ladder is decoration. If they are chosen, the pack does not show it. INFERRED: as shipped in these slices, the ladder is at risk of being a stat bump the player watches rather than plans around.
Dead weight: "Deep reserves" (one spare wing) is the weakest perk - situational, one-shot, and redundant with the base launch ability's spare-wing mechanic. "Picket pilots" is dead weight by omission: it has no number (Finding 3).

COUNTERPLAY
Flak and gsentry mounts: 11 flak + 1 gsentry = 12 point-defense mounts across the entire roster. INFERRED: against a b_boss with hangar:3, a fleet with 1-2 flak mounts is outgunned by wings. The 12 mounts are spread across factions and hull classes, so any single engagement may face 0-3 flak guns. Point defense is a real answer in kind but sparse in count. The roster audit's bug (advising anti-wing play against wingless factions) further muddies the player's ability to plan around flak.
Torpedo-screen interaction: Yes, it makes carriers defensive assets. A screening wing intercepts torpedoes at 0.45 within 2 hexes of its carrier, and also covers "ships beside them." A b_brood with 3 screening wings approaches ~83% cumulative intercept (INFERRED: assuming independent rolls). This is a real defensive layer.
Is 0.45 the right kind of number? It is the right kind - a probability per torpedo, applied within a radius, gated by stance. But it is flat. It does not scale with wing veterancy, wing hp, torpedo size, or the number of wings already screening. The pickets perk promises to raise it but provides no delta. INFERRED: 0.45 is a reasonable starting constant, but the design needs at least one scaling axis (veterancy or perk) to keep the interaction from being binary (screen on = torpedoes mostly die; screen off = they don't).

THE CARRIER FIGHT
From the generator slice: the carrier archetype picks the single most expensive carrier that fits the budget, removes all carriers from the remaining roster, and fills the rest with the standard weighted-random loop. There is no escort doctrine - no minimum screen count, no flak preference, no formation shape. The "carrier with its escort" described in the CHAIR CENSUS is, in code, "one carrier plus whatever the generic generator draws."
INFERRED: the fight does differ from a gun line, but only because the carrier's wings introduce a second damage source with its own movement, stances, and interception rules. The fleet composition around the carrier is statistically indistinguishable from a gun line of the same budget. The carrier layer's complexity lives entirely in the wing micro-management (stance toggles, torpedo screens, perk tracking), not in how the enemy fleet is built. The generator does not make the player fight a carrier doctrine; it makes them fight a gun line with a wing spawner attached.

Not Checked
Weapon tables. The pack names guns, bombs, sporeb, bioplasma, spores, pulsar, turbo, hturbo, ion, flak, gsentry, scatter, htorp, tendril, turret, but does not include damage, range, or type values. I cannot judge whether sporeb differs from bombs, whether fighter guns outscale bomber bombs, or whether flak actually kills wings at the mount counts listed.
Non-carrier sibling hulls. h_picket, h_interdictor, c_raider, c_reaver, c_marauder, b_drone, b_spitter, b_razor, i_wisp, i_blade, i_song are absent. The hangar-economy comparison against faction siblings is incomplete.
Perk selection and assignment logic. No UI code, no auto-assignment rule, no perk-pool filtering is in the pack.
Wing movement and targeting AI. The stance descriptions state behaviour, but the pathfinding, target-priority, and leash-enforcement code is not included.
Damage resolution for wings. How wing hp interacts with flak fire, how bombs apply damage, whether wings can be targeted by player weapons - none of this is in the pack.
The fx key system. Keys like sqPct, sqHp, battShots, flakPlus, torpCd, hangar, hullRegen appear in the fx list but no modification logic is shown.
Multi-battle persistence. Whether wing kills, perks, and stances carry across battles in a roguelite run is not addressed.
The Godot port. The pack header says "the Godot port mirrors this design" but no Godot code is included.

Questions for the Designer
What does sporeb do that bombs does not? If the answer is "different damage type" or "slightly different number," the spore should be folded into the bomber with a faction skin; if it is "area denial" or "DoT," that needs to be in the hull description and the stance logic, because right now sq:'bomber' erases any behavioural difference. Stakes: a third wing type that plays identically to the second is dead complexity that the audit will flag in every future pass.
Is the perk ladder auto-assigned or player-chosen, and where is that code? The pack shows six perks and three thresholds but no selection mechanism. Stakes: if perks are automatic, the veterancy system is a stat ramp, not a decision layer, and the commissioner's question ("do wings create real decisions?") loses a pillar.
Should the carrier archetype generator shape escorts, or is "carrier plus generic filler" the intended design? The current code removes carriers from the pool and runs the standard weighted loop. Stakes: if carrier fleets are meant to feel doctrinally different - screen ships, flak escorts, torpedo boats - the generator needs escort-weighting logic; if they are not, the CHAIR CENSUS's "carrier with its escort" language overpromises what the code delivers.
Assumptions stated: all sibling-hull comparisons are INFERRED from launch-hull stats alone, since non-carrier siblings are absent from the pack. Cumulative torpedo-intercept probability (~83% for three screening wings) assumes independent rolls per wing, which is INFERRED. Weapon damage and type comparisons are impossible without the weapon table. All verdicts on "fairness" of hangar costs assume that weapon mounts are the primary alternative use of a hull's weapon slots, which is INFERRED from the ability system's structure.
