# Balance synthesis: closing the 46-point faction spread

Chair synthesis of four legs (DeepSeek, Qwen, Argon, Rey), screened and then tested in the shipped full-run simulator. All measured figures are in sim_results.md. Ryan's rulings R62 and R63 govern throughout: a high bot win rate is not the target, a human first run stays very hard, Eclipse stays stronger and more expensive, the Chorus stays the cheap opposite.

## Verdict

GO WITH CONDITIONS. One package of 18 small data.js number changes, measured twice with identical results, takes the spread from 46 points (34 to 80) to 12 points (60 to 72) and puts both measured outliers, the Crusade and the Chorus, mid-pack at 64 percent. Four of its levers touch things the legs flagged as the owner's call; those are listed at the end and can be struck from the package without breaking it, at the cost of a wider spread. A second package (v3) was built and measured to test whether the top of v2 could be shaved; it produced the same 12-point spread with a worse shape, so v2 is the recommendation.

## 1. The baseline, and a caution about its fine detail

The baseline was executed three times before any leg was written. All three executions produced identical faction win totals: Crusade 34, Hegemony 54, Hullbreakers 62, Chorus 80, Glasswrights 64, Eclipse 72, overall 61. Two of the three also agreed on every per-admiral split and every death split. The first execution did not (it showed Crusade deaths concentrated in sector 2, Reyes at 92, Voice at 91), and DeepSeek and the Rey leg were written against a pack built from that first execution. Where their admiral-level or sector-level claims conflict with the agreed execution, this synthesis follows the agreed execution. Qwen's leg used the corrected pack and its diagnosis matches the agreed numbers throughout.

The agreed baseline's loudest fact: the Crusade loses 22 of its 33 lost runs in sector 1, against Hullbreakers and Hegemony only. Whatever is wrong with the Crusade is wrong in its opening fights, not in late-game scaling.

## 2. Why each faction lands where it does (reconciled)

1. Sunward Crusade, 34 percent. Deaths concentrate in sector 1 (22 of 33). The starting hulls are fragile where it matters (warden hp 45, harrow hp 78), the broadside identity needs movement the slow hulls struggle to buy, and the veteran brace fix is measured in the pack as costing the Crusade row about 8 points because braced enemies live longer against a faction whose bonus is offensive. The admiral split is the widest in the game (Thale 83.3 against Ashgrove 8.3, small samples), which says fleet shape matters, but the faction-level problem is sector 1 survival. DeepSeek and Rey both diagnosed a sector 2 torpedo problem from the anomalous first execution; the torpedo half of that diagnosis was tested directly and failed (finding 4), and the sector half is superseded by the agreed splits.
2. Hegemony Navy, 54 percent. The control faction: no price modifier either way, mid hulls, and it lands mid-table. Ion's 2.5 shield multiplier is dead weight against the shieldless Chorus and Eclipse in sectors 2 and 3, which caps its late game. Its deaths spread across sectors with a sector 2 lean (11 of 23).
3. Ashfall Hullbreakers, 62 percent. Cheap fast hulls (Frigate .8, Destroyer .85; raider speed 6, evasion 28) and cheap repairs. Nothing in the legs or the tests found a Hullbreaker-specific lever worth pulling; their rate moves mostly when other factions' numbers change around them.
4. The Chorus, 80 percent. The legs agreed the cause is free per-round hull regeneration stacked on the cheapest hulls in the game, so attrition never lands. The isolation tests refined that: regen trims alone moved the Chorus not at all (84 percent), and neither did a price rise (86 percent). What moved it was damage: cutting tendril and bioplasma damage took the Chorus to 72 percent alone, with sector 1 deaths rising from 2 to 10. The Chorus's edge is that it kills fast enough that its regen rarely has to carry a long fight. Regen is part of the story, but outgoing damage is the load-bearing half.
5. The Glasswrights, 64 percent. Evasion 16 to 28 plus the minus 18 movement rule plus deep shields relative to hull protect the lowest hull points in the game. Their strength is defensive mechanics, not economy (their frigates and destroyers are the dearest after Eclipse).
6. Eclipse, 72 percent. Reanimate once per battle at 35 percent hull, armour .20 to .35, hull regen 3 to 4, and pierce .6 weapons make effective hull far larger than printed hull. Partly by design under R63: they are already the most expensive faction. The question is the size of the gap, not its existence.

## 3. What the isolation tests killed

7. The torpedo evasion lever is dead. Three legs proposed softening torp evMult 2 (to 1.5 or 1.7) as a headline Crusade fix. Tested alone at 1.7: Crusade 32 percent (baseline 34), Hullbreakers 60, Glasswrights 66. No benefit to anyone. It is not in the recommended package.
8. Chorus regen trims and Chorus price rises, the two most-proposed Chorus levers, are both weak alone (84 and 86 percent against an 80 baseline). They are in the package only as support for the damage cuts, not as the mechanism.
9. Leg effect-size predictions were unreliable in both directions. The Crusade stack (hull points, rake, carrier price) was predicted at plus 9 to 18 across the legs and measured at plus 26 alone, plus 30 in the full package. Enemy-side cross-effects are large: every faction is also an enemy in someone else's sectors, so a trim aimed at one faction moves its opponents too. Package v3 proved the point in reverse (finding 11).

## 4. Argon screening

10. The Argon leg is filed as a record and was not relied on. It invents weapon names and stats that are not in the pack or the data (named guns with accuracy figures, a brace value), invents per-sector win rates, repeats one templated admiral paragraph across all six factions with false starting-fleet claims, credits the Chorus with reanimation (an Eclipse-only mechanic), and proposes system changes where the brief asked for data.js numbers. Its one sound intuition, that regeneration and reanimate bypass the repair economy, is established with evidence by the other three legs.

## 5. The recommended package (v2): 18 data.js edits

Weapon table:
1. ion shield multiplier 2.5 to 2.7 (data.js:13). Hegemony's late-game strip tool, slightly less dead against shielded fleets.
2. tendril damage 13 to 11 (data.js:16).
3. bioplasma damage 12 to 10 (data.js:17). Items 2 and 3 are the measured Chorus lever.

Crusade hulls and rule:
4. warden hp 45 to 50 (data.js:63).
5. harrow hp 78 to 85 (data.js:64).
6. penitent hp 120 to 135 (data.js:65).
7. MOVE_RULES broadside bonus after moving 2 or more hexes, 40 percent to 45 percent (rake .4 to .45, data.js:106, with its description text updated to match).
8. FAC_PRICE Crusade Carrier 1.25 to 1.1 (data.js:539).

Chorus hulls:
9. b_drone regen 4 to 3 (data.js:86).
10. b_spitter regen 5 to 4 (data.js:87).
11. b_razor hp 150 to 135 and regen 7 to 6 (data.js:88).
12. b_brood hp 200 to 180 and regen 8 to 6 (data.js:89).

Eclipse:
13. d_scythe regen 3 to 2 (data.js:98).
14. d_jackal regen 3 to 2 (data.js:99).
15. d_harvester regen 4 to 3 (data.js:100).
16. FAC_PRICE Eclipse Frigate 1.45 to 1.55, Destroyer 1.5 to 1.6, Cruiser 1.55 to 1.65 (data.js:540).

Glasswrights:
17. i_blade shields 16 to 15 (data.js:93).

Measured result (two executions, identical): Crusade 64, Hegemony 70, Hullbreakers 60, Chorus 64, Glasswrights 68, Eclipse 72. Overall 66.3, spread 12 points. Two honest caveats. First, Eclipse did not move: its price and regen trims were fully offset by weaker Chorus and Glasswright enemies in its own sectors 2 and 3, and R63 says Eclipse should sit near the top, so the chair accepts 72 as the top of a 12-point band rather than a failure. Second, the overall bot rate rose from 61 to 66.3. Under R62 that is not a defect by itself (the bot is far stronger than a first-time human, and earlier policy measurement put a rushing human-style policy near 37 percent on the old numbers), but it is the owner's call whether the centre should sit lower; striking the Crusade hull lifts (items 4 to 6) is the clean way to lower it, at the cost of the Crusade falling back toward the low 50s.

## 6. Package v3: tested, not recommended

11. V3 took v2 and reverted ion to 2.5, deepened the Eclipse regen trims (1, 1, 2), and trimmed Glasswright evasion (wisp 28 to 25, blade 24 to 21), aiming at v2's top. Measured twice: Crusade 62, Hegemony 66, Hullbreakers 60, Chorus 72, Glasswrights 60, Eclipse 66. Same 12-point spread, lower overall (64.0), worse shape: the Glasswright and Eclipse trims weakened the enemies in Chorus runs and handed the top spot back to the faction the brief most wanted pulled in. The lesson is structural: at this spread width, further compression with data.js numbers alone mostly rearranges which faction sits on top, because the cross-effects through the sector enemy pools are as large as the direct effects. The chair stopped after two fully measured packages rather than tuning to noise at n of 50 per faction (95 percent intervals are roughly plus or minus 13 points).

## 7. Changes that need Ryan's call

1. Chorus regeneration cuts (package items 9 to 12). Qwen flagged these as an owner's call because regen is the core mechanic R63 uses to define the Chorus as Eclipse's opposite. Every leg still proposed them, the cuts are small (1 to 2 points per hull), and the Chorus remains the strongest regenerator in the game by a wide margin. But they edit an identity mechanic, not just a stat.
2. Eclipse price rises (item 16). DeepSeek flagged the size as an owner's call: R63 fixes the direction (stronger, more expensive) but not the amount. The package uses plus .10 per class, gentler than DeepSeek's proposed plus .15.
3. Whether the overall centre should sit lower (see the caveat in section 5). This is the R62 judgement in concrete form: bot 66 percent overall against a human first run that should stay near impossible.
4. Ashgrove's starting fleet. Qwen flagged her recomposition (reliquary, harrow, warden) as structural rather than a number, and the legs were barred from doctrine and roster surgery on n of 12 smoke. Her 8.3 percent is the single worst admiral figure in the baseline. The package lifts her only indirectly, through the harrow and carrier price changes.

## 8. Reserve and rejected levers

Reserve, if Ryan wants the Glasswrights lower without touching evasion stats: MOVE_RULES Glasswright post-move penalty minus 18 to minus 15 (Qwen's proposal, flagged by Qwen as an owner's call because it edits a faction-defining rule). Not in either measured package.
Rejected with measurements: torpedo evMult softening (finding 7); Chorus price rises as a primary lever (86 percent alone; also leans against R63).
Rejected on scope: the RAMP budget curve and the brace interaction (battle.js, out of scope per the brief); reanimate's 35 percent (battle.js); boss hull tuning (shared enemy content, moves every faction at once); admiral doctrine numbers (per-admiral samples of 12 or 13 cannot carry them, and two of the four legs' admiral-level premises came from the anomalous first execution).

## Not checked

No human playtesting exists for any of this; every figure is one bot under one policy, and earlier work in this repo shows the absolute rate is policy-sensitive even when ordering holds. Per-admiral results under the packages were not separately analysed beyond the faction totals the runner reports. The six baseline battle timeouts were never attributed to a faction. Whether the package changes the boss matrix or the faction-versus-faction matrix was not measured; the full-run sim is the only instrument used. Longer runs (n of 200 or more per faction) would narrow the intervals and are the obvious next measurement if Ryan wants the 12-point spread certified rather than indicated.
