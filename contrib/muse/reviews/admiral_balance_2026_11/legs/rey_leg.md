# Issue #125: blind Rey leg (reader)

Written blind from the issue #125 pack alone: the runner tables, the stated outlier test, and the chair's data.js excerpts. No other leg, no synthesis, and no file outside the pack was read. All win-rate shifts proposed below are estimates, marked as such. No data.js edits are made or implied; every proposal is an owner question.

## 1. Outlier screen (test applied by hand)

Test: an admiral is a clear outlier when their Wilson 95 percent interval does not overlap their own faction's interval at all. Overlaps of a few points are leaning, not outliers.

Clear outliers (2, both in the Sunward Crusade):

- Commodore Sera Ashgrove (ashgrove), BELOW. 42.0 percent, interval 29.4 to 55.8, against the Crusade interval 57.1 to 70.3. Her upper bound sits 1.3 points under the faction lower bound. No overlap.
- High Admiral Oryn Thale (thale), ABOVE. 84.0 percent, interval 71.5 to 91.7, against the Crusade interval 57.1 to 70.3. His lower bound sits 1.2 points over the faction upper bound. No overlap.

Both clears are narrow, roughly one run's worth of interval movement at n = 50. They pass the stated test as written, but the chair should treat them as clear-and-close, and any re-screen after a change should use the same test.

Leaning near misses (intervals overlap the faction interval by a few points):

- Vesh the Collector (vesh), leaning high. 84.0 percent, interval 71.5 to 91.7, Hullbreakers interval 60.2 to 73.1. Overlap 1.6 points, the closest near miss in the whole table.
- Nadir Aurex, Ninth Frame (nekhet), leaning high. 84.0 percent, interval 71.5 to 91.7, Eclipse interval 61.2 to 74.1. Overlap 2.6 points.
- Tamsa of the Clear Aperture (aelith), leaning high. 78.0 percent, interval 64.8 to 87.2, Glasswrights interval 54.1 to 67.5. Overlap 2.7 points.
- Admiral Roderic Vex (vex), leaning high. 80.0 percent, interval 67.0 to 88.8, Crusade interval 57.1 to 70.3. Overlap 3.3 points.

Soft low-side watch list (point estimates well under their faction, but overlaps of 5.5 to 6.3 points, wider than the high-side leans, so not called leaning under a strict few-points reading): Oath-Captain Malek Draven (malek) 50.0 percent against Crusade 64.0; Vell of the Third Mirror (thorne) 46.0 percent against Glasswrights 61.0, the lowest point estimate of any admiral outside the clear outlier; Seveth, Twice-Restored (khepra) 54.0 percent against Eclipse 68.0.

Everyone else overlaps their faction interval comfortably. No faction is itself a clear outlier: the six faction intervals (61.0 to 68.0 on point estimates) all overlap each other.

## 2. Clear outlier below: Ashgrove (Crusade, 42.0 percent)

Kit drivers (pack excerpts):

- Carrier doctrine at data.js:207: sqPct .4, hangar 1, sqHp .25. Her damage is squadron damage; the doctrine numbers themselves are mid-pack (aelith carries the same hangar 1 and sqHp .25 at data.js:229-232 with a lower sqPct .25 and runs 78.0 percent).
- Starting fleet at data.js:207: reliquary, harrow, warden. Three hulls. The reliquary (data.js:66) is a carrier with hp 130, sh 22, sp 2, ev 0, hangar 2, and turret plus flak only: it has no real anti-ship gun. So her starting line is one weapons-light carrier, one destroyer (harrow, data.js:64), and one frigate (warden, data.js:63), and the carrier is slow (sp 2) with no evasion.
- Command scramble at data.js:214: extra wing per launch ship, then all squadrons strike again at +50 percent this round. A scaling command that pays off once she has launch ships and living squadrons, which is exactly what her early game struggles to protect.

Sector death split: S1 16, S2 8, S3 5, for 29 losses in 50 runs. The S1 count of 16 is the highest sector 1 death count of any admiral in the table (next: malek and voice at 14). Fifty-five percent of her losses happen in sector 1. Her conditional late game is fine: 26 of her runs reached sector 3 and 21 of those won (about 81 percent). She does not have a scaling problem; she has a getting-out-of-sector-1 problem. Her average battles, 9.52, is the lowest of all 24 admirals, consistent with early death rather than late collapse.

Template-family comparison: the scramble/carrier family is ashgrove 42.0, reyes 68.0, mott 64.0, matriarch 70.0, aelith 78.0. Ashgrove is the family floor by 22 points, so scramble and the carrier template are exonerated; the same Command is at or above faction rate in four other hands. What is unique to her in the pack: the only starting carrier whose listed armament is turret plus flak only, in a three-hull start, in the faction where her stablemate malek starts four hulls. The honest counterpoint: aelith starts two hulls and thrives, so hull count alone is not a sufficient explanation. The sharpest driver the pack supports is the combination: a slow, gunless carrier anchor plus the thinnest gun line in her faction, asked to survive the sector where she has the least squadron mass to show for the doctrine.

Proposed changes (owner questions, at most two, both small):

1. Starting fleet: add one warden, so the start reads reliquary, harrow, warden, warden (matching malek's four-hull start shape at data.js:206). Expected shift: estimate +5 to +9 points, concentrated in sector 1 losses. Reasoning: her failure mode is measured and located (16 S1 deaths), and this is the only proposal aimed directly at it.
2. sqHp .25 to .40 at data.js:207. Expected shift: estimate +3 to +5 points. Reasoning: squadrons are her only real damage source; squadron hit points buy extra strikes per launch across the whole run, and the change touches her alone (the other sqHp .25 carriers keep their own lines).

Note for the chair: her unlock cost (45) is invisible to this measurement, since the driver bypasses ownership. Any cost-side fix would be unmeasurable by this runner and should not be justified with these numbers.

## 3. Clear outlier above: Thale (Crusade, 84.0 percent)

Kit drivers (pack excerpts):

- Iron doctrine at data.js:208: hpPct .15, shPct .1.
- Starting fleet at data.js:208: cathedral, warden. Two hulls, but the cathedral (data.js:67) is a battleship: hp 220, sh 30, ar .3, two hbattery plus lance plus flak, cost 340. It is the largest starting hull in the pack excerpts, and it carries his doctrine multipliers on top of the biggest base numbers: roughly hp 253 and sh 33 before the warden is counted.
- Command iron at data.js:215: shields refill, 40 percent less hull damage this round. On a battleship hull this is a full shield reset plus a large damage cut, stacked on ar .3 and the hpPct/shPct line.

Sector death split: S1 1, S2 3, S3 4, for only 8 losses in 50 runs. The S1 count of 1 is the lowest in the entire table; 49 of his 50 runs survive sector 1. Half of his rare losses come in sector 3, which means the early and mid run are close to solved and he only dies deep, against sector 3 opposition. His average battles, 12.88, is the highest of all 24 admirals.

Template-family comparison: the iron/passive-tank family is thale 84.0, maren 50.0, mirelle 54.0. Maren carries the identical hpPct .15 and shPct .1 numbers and the same iron Command (data.js:220) and sits at the bottom of Hegemony. So the passive percentages alone cannot be the driver; if they were, maren would lean high too. The driver the pack supports is the interaction: those percentages and that Command applied to a 220 hp, ar .3 battleship from turn one. Thale is the only admiral in the excerpts who starts on a battleship hull, and the family comparison says the hull is doing the work, with the doctrine multiplying it.

Proposed changes (owner questions, at most two, both small):

1. hpPct .15 to .10 for thale only, at data.js:208. Expected shift: estimate -3 to -5 points. Reasoning: trims the multiplier where it stacks on the largest base hull, without touching maren's identical line, which the family comparison says is not the problem.
2. Iron Command hull damage reduction 40 percent to 30 percent, at data.js:215. Expected shift: estimate -2 to -4 points. Reasoning: the shield refill is the identity of the Command and stays; the reduction percentage is the part that scales hardest on a battleship's hull pool.

Taken together the two are an estimated -5 to -8 points, which would land him near vex (80.0) rather than at faction rate. If the owner wants him at faction rate, the pack suggests the honest lever is the cathedral start itself, which is a composition change, not a small number change, and is outside this proposal budget.

## 4. Faction-level movement: signal or noise

Verdict: mostly noise, on the pack's own facts. The code is identical across v2, issue #87, and this run (main at cad86f04), so no movement can be a code effect; all of it is sampling. And the sample geometry matters: this run reuses seeds 1 to 200 per faction, and issue #87 used seeds 1 to 50 with identical settings, so the first 50 runs of each faction here should be the #87 runs themselves. The right way to read the movement is the marginal rate over the 150 fresh runs:

- Hegemony: 70.0 percent at 50 (35 wins) to 61.0 at 200 (122 wins) implies 87 wins in runs 51 to 200, a marginal 58.0 percent.
- Glasswrights: 68.0 at 50 (34) to 61.0 at 200 (122) implies a marginal 58.7 percent.
- Hullbreakers: 58.0 at 50 in #87 (29) to 67.0 at 200 (134) implies a marginal 70.0 percent.
- Eclipse: 72.0 at 50 (36) to 68.0 at 200 (136) implies a marginal 66.7 percent.
- Crusade and Chorus: flat at 64.0, marginal 64.0.

At n = 50 a faction Wilson interval is roughly plus or minus 13 to 14 points, so swings of 7 to 9 points between a 50-run baseline and a 200-run rerun are well inside one standard error of the difference. The spread narrowing from 12 to 14 points down to 7 when n quadruples is exactly the signature of small-sample spread collapsing, not of factions converging. Hegemony's marginal 58.0 over 150 fresh runs is the strongest single hint of a real below-baseline rate, and even it sits inside the v2 baseline interval.

What would settle it: a second 200-per-faction run on a disjoint seed range (for example seeds 1001 to 1200), pooled with this one for 400 per faction on non-overlapping seeds. If Hegemony and Glasswrights again land at or under about 61 with pooled intervals clearing the old 68 to 70 baselines, that is signal. Until then, no faction-level number change is justified by this movement, and the issue's own 15-point spread trigger is nowhere near tripped (spread 7).

One caveat the chair should carry: the same seed range is reused for every faction, so the six faction samples are paired, not independent. Cross-faction gaps are somewhat more meaningful than the intervals suggest, and same-faction comparisons across runs are less independent than they look.

## 5. Anything else in the tables

1. The admiral problem is a Crusade problem. Faction spread is 7 points; the Crusade internal spread is 42 points (42.0 to 84.0), the widest of any faction (Glasswrights 32, Eclipse 30, Hullbreakers 26, Hegemony 24, Chorus 20). Both clear outliers live in one faction. Reporting this job as a faction balance pass would bury the finding.
2. The paid-unlock problem in Crusade. The free starter vex runs 80.0 percent (leaning high) while the two paid Crusade admirals under him run 50.0 (malek, cost 30) and 42.0 (ashgrove, cost 45). Against the owner's cheap-and-stylish goal (R77), a player who pays renown for malek or ashgrove is buying a worse win rate than the free default. That is the sharpest R77 tension in the table, sharper than the outlier test alone shows.
3. Cost predicts almost nothing at the top end either. The six cost-80 admirals: thale 84.0, vesh 84.0, maren 50.0, voice 54.0, mirelle 54.0, khepra 54.0. Two faction-toppers and four faction-floor-or-near results on the same price. Whatever pricing is doing, it is not tracking power in either direction.
4. Free starters are strong almost everywhere. Cost-0 admirals: vex 80.0, kassar 74.0, matriarch 70.0, aelith 78.0, nekhet 84.0, grax 58.0. Five of six run at or above their faction rate. Good for a new player's first runs; it also compresses the value story of every paid admiral beneath them.
5. A sector 2 wall for the two falling factions. Hegemony (S1 25, S2 38) and Glasswrights (S1 26, S2 35) are the only factions that die more in sector 2 than sector 1, and they are the two factions that fell. The pattern is admiral-concentrated: vorn S2 14 and maren S2 12 for Hegemony; thorne S2 15 for Glasswrights, the highest single sector-2 count in the table. If the chair looks anywhere for a faction-level story, it is mid-run, not early. The pack does not include sector pools, so this is a pattern flag only, not a cause.
6. Timeouts need a scoring answer. There were 13 battle timeouts, and Hegemony holds 5 of them. The pack does not state whether a timeout scores as a loss. If it does, up to 2.5 points of Hegemony's 61.0 is timeout artifact, which would further weaken the faction-movement story. The chair should state the timeout rule in the synthesis.
7. Sustain plus a heavy start is the recurring top-end recipe. The three 84.0 percent admirals: thale (battleship start, iron sustain), nekhet (repair swarm kit, start includes the faction battleship line per the pack note), vesh (hulk start, hullRegenPct .05, armor .1, restore Command). Three different factions, same shape: a big hull that also heals or refuses damage. If one pattern gets watched next run, it is that one. Vesh in particular is the most likely next clear outlier: he misses the test by 1.6 points of overlap and his restore Command (repairs 25 percent hull, patches destroyed sections) is unique in the set.
8. Average battles is not independent evidence. It tracks win rate almost perfectly (top: thale 12.88, vesh 12.66, aelith 12.52; bottom: ashgrove 9.52). It is survival time restated. Useful as a consistency check, worthless as a second argument.
9. Thorne is the quiet worry. 46.0 percent with the worst sector 2 count in the table (15) on an ev 8 kit (data.js:231) with a four-hull start. He does not screen as a clear outlier, but if any leaning admiral gets a second look in the next run, the evasion kit dying mid-run at that rate is the one whose kit story (evasion that stops scaling) is worth testing directly.

## Scope note

Read: the pack only. Not read: the runner's raw output files, data.js itself beyond the pack excerpts (Eclipse kits are therefore discussed at doctrine level only, as the pack instructs), any other leg, and any synthesis. Sector pool composition is not in the pack, so no claim above depends on which factions appear in which sector.
