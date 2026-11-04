Qwen leg (reader), issue #125. Model gate: Qwen3.8-Max verified in the selector before sending and in the chat header after generation (both gates passed). Single complete response returned.

---

Qwen Reader Leg - Issue #125 Admiral Balance (200-Run Monte Carlo)

1. Outlier Screen (applied independently)
Test as stated: A clear outlier is an admiral whose Wilson 95% interval does not overlap their own faction's interval at all (entirely above or entirely below). Intervals that overlap by a few points are leaning, not outliers.

Clear outliers
Admiral | Faction | Admiral CI | Faction CI | Verdict
Commodore Sera Ashgrove | Crusade | 29.4 to 55.8% | 57.1 to 70.3% | Entirely below. Clear outlier (low).
High Admiral Oryn Thale | Crusade | 71.5 to 91.7% | 57.1 to 70.3% | Entirely above. Clear outlier (high).

Leaning near-misses (overlap 6 points or less)
Admiral | Faction | Admiral CI | Faction CI | Overlap | Direction
Admiral Roderic Vex | Crusade | 67.0 to 88.8 | 57.1 to 70.3 | 3.3 pts | Leaning high
Vesh the Collector | Hullbreakers | 71.5 to 91.7 | 60.2 to 73.1 | 1.6 pts | Leaning high
Tamsa / Aelith | Glasswrights | 64.8 to 87.2 | 54.1 to 67.5 | 2.7 pts | Leaning high
Nadir / Nekhet | Eclipse | 71.5 to 91.7 | 61.2 to 74.1 | 2.6 pts | Leaning high
Vell / Thorne | Glasswrights | 33.0 to 59.6 | 54.1 to 67.5 | 5.5 pts | Leaning low
Seveth / Khepra | Eclipse | 40.4 to 67.0 | 61.2 to 74.1 | 5.8 pts | Leaning low
Malek Draven | Crusade | 36.6 to 63.4 | 57.1 to 70.3 | 6.3 pts | Leaning low (borderline)

All other admirals overlap their faction interval comfortably and are not flagged.

2. Clear-Outlier Kit Drivers, Sector Deaths, and Template Comparisons

2a. Ashgrove - Crusade (42.0%, clear low outlier)
Kit drivers (data.js excerpts):
Carrier doctrine: sqPct .4, hangar 1, sqHp .25 (data.js:207).
Starting fleet: reliquary (data.js:66 - hp 130, sh 22, sp 2, ev 0, hangar 2, turret + flak only, cost 260), harrow (data.js:64 - hp 85, torp + turret, cost 130), warden (data.js:63 - hp 50, sh 10, cost 70).
Command scramble (data.js:214): extra wing per launch ship, then all squadrons strike again at +50% this round.
Sector death split: S1 = 16, S2 = 8, S3 = 5 (29 losses total). 55% of all losses occur in sector 1. She averages only 9.52 battles, the lowest in Crusade, confirming early elimination before the squadron engine can compound.
Template-family comparison (scramble/carrier):
Admiral | Faction | Win %
Aelith / Tamsa | Glasswrights | 78.0
Matriarch | Chorus | 70.0
Reyes | Hegemony | 68.0
Mott | Hullbreakers | 64.0
Ashgrove | Crusade | 42.0
Ashgrove sits 22 to 36 points below every other member of the scramble/carrier family. The driver story is sharp: the reliquary (ev 0, turret + flak only, speed 2) is the weakest carrier platform in the family, and the starting escort (one harrow, one warden) is thinner than what other scramble admirals field. The high sqPct (.4) cannot compensate when the launch platform dies in S1.

2b. Thale - Crusade (84.0%, clear high outlier)
Kit drivers (data.js excerpts):
Iron doctrine: hpPct .15, shPct .1 (data.js:208).
Starting fleet: cathedral (data.js:67 - hp 220, sh 30, ar .3, two hbattery + lance + flak, cost 340), warden (data.js:63).
Command iron (data.js:215): shields refill, 40% less hull damage this round.
Sector death split: S1 = 1, S2 = 3, S3 = 4 (8 losses total). Losses are minimal and spread evenly. He averages 12.88 battles, the highest in Crusade, meaning he consistently reaches deep content.
Template-family comparison (iron/passive-tank):
Admiral | Faction | Win %
Thale | Crusade | 84.0
Mirelle / Brin | Glasswrights | 54.0
Maren | Hegemony | 50.0
Thale is 30 to 34 points above the other iron admirals. The cathedral (hp 220, sh 30, ar .3) is a far more dominant hull than the equivalents Maren and Mirelle field. Stacking hpPct .15 and shPct .1 on top of that hull, then triggering iron (shield refill + 40% hull damage reduction), makes the cathedral functionally unkillable in the mid-game. The kit is doing exactly what the numbers say: the passive bonuses are redundant on a hull that already outclasses the field, and the active command removes the one window (shield-down) where opponents could trade.

3. Proposed Owner-Question Number Changes (NO data.js edits)
Ashgrove (two proposals, max)
Q1 - Raise sqHp from .25 to .35 (data.js:207).
Expected shift: +4 to +6% win rate (estimate).
Reasoning: Her squadrons are the payoff mechanic, but they die too quickly in S1 to accumulate value. A 10-point bump to squadron HP lets them survive one extra exchange, which is where the 55%-S1-loss pattern bites hardest. This is the smallest lever that directly addresses the early-death problem without changing her identity.
Q2 - Raise the reliquary's speed from 2 to 3 (data.js:66).
Expected shift: +2 to +4% win rate (estimate).
Reasoning: The reliquary's ev 0 and speed 2 make it a static target in S1 when the enemy fleet is freshest. One point of speed lets it reposition out of concentrated fire and reach the S2 fights where its hangar 2 and turret/flak suite are more relevant. This is a hull-line change, not an admiral-kit change, so the owner may prefer to keep it in reserve.
Thale (two proposals, max)
Q1 - Reduce hpPct from .15 to .10 (data.js:208).
Expected shift: -4 to -6% win rate (estimate).
Reasoning: The cathedral's base 220 hp + ar .3 is already the most durable hull in the pack. The hpPct bonus stacks multiplicatively with the iron command's 40% damage reduction, pushing effective durability past the point where any opponent can break through. Trimming 5 points of hull percentage brings him closer to the maren/mirelle band without gutting the iron fantasy.
Q2 - Reduce shPct from .10 to .05 (data.js:208).
Expected shift: -2 to -3% win rate (estimate).
Reasoning: The iron command refills shields entirely. Any passive shield bonus is therefore multiplied by the number of times iron fires per run. Halving the passive shield contribution is the smaller, cleaner lever and preserves the "shields come back" fantasy that defines the command.
All shifts are estimates derived from the interval widths and template-family spacing in this pack. They are not measurements.

4. Faction-Level Movement: Signal or Noise?
Faction | v2 / #87 | Issue #125 | Delta | Assessment
Hegemony | 70 / 70 | 61 | -9 | Likely noise
Glasswrights | 68 / 68 | 61 | -7 | Likely noise
Hullbreakers | 60 / 58 | 67 | +7 to +9 | Likely noise, Vesh-driven
Reasoning. The baselines were n = 50 per faction. A 50-run Wilson interval at 70% spans roughly 55 to 82%; at 68% it spans roughly 54 to 80%. The 200-run intervals (all about 13 to 14 points wide) fall well inside those 50-run bands. No faction's 200-run interval excludes the old point estimate. The apparent 7 to 9-point moves are within the noise of the small baseline samples.
What would settle it. A second 200-run block per faction using seeds 201 to 400 (same settings, same code). If the two blocks' intervals overlap tightly around the same centre, the 200-run estimate is stable and the old 50-run numbers were simply noisy. If they diverge, there is a seed-range or code-path issue to chase. A combined 400-run pool would halve the interval width to about 7 points and make 5-point faction differences detectable.
Hullbreakers caveat. The +7-to-9 rise is substantially driven by Vesh (84%, 50 runs). The other three Hullbreakers average (58 + 62 + 64) / 3 = 61.3%, which is almost exactly the old baseline. The faction "rise" is one admiral, not a faction-wide shift.

5. Additional Flags for the Chair
Seed reuse across factions. Seeds 1 to 200 are reused for every faction. This controls for seed difficulty in faction-vs-faction comparisons, but it means the pooled 64.2% (770/1,200) is not an estimate from 1,200 independent trials. Effective independence is closer to 200 seed-slots x 6 factions. The pooled interval is tighter than it should be if treated as a single binomial.
Timeout scoring. 13 battle timeouts are logged (Crusade 3, Hegemony 5, Hullbreakers 0, Chorus 2, Glasswrights 1, Eclipse 2). The pack does not state whether a timeout counts as a loss. If it does, Hegemony's 5 timeouts could account for up to 2.5 percentage points of its 61% figure. The chair should confirm the runner's timeout-scoring rule before the numbers are treated as final.
Crusade is not a faction; it is two admirals and two others. Crusade's four admirals span 42 to 84%, a 42-point spread. The faction average (64%) is an artefact of averaging two extreme outliers. Any faction-level balance decision for Crusade should be deferred until the two outliers are addressed individually.
Three admirals at exactly 84%. Thale (Crusade), Vesh (Hullbreakers), and Nekhet/Nadir (Eclipse) all land at 42/50 = 84.0%. At n = 50, 42 wins is the nearest integer to 84%, so three independent admirals hitting it is a rounding coincidence, not a signal. But it does mean all three share the same Wilson interval (71.5 to 91.7), which makes them look more tightly clustered than they may truly be. At 200 runs per admiral (if the owner ever splits a second block), this artefact disappears.
Ashgrove's sector pattern vs. Aelith's. Ashgrove loses 55% of her games in S1; Aelith (the best scramble admiral) loses only 2 in S1 and concentrates losses in S3 (5). This is consistent with the "frail carrier dies before squadrons matter" story and argues that any Ashgrove fix should target S1 survivability specifically, not late-game scaling.
Avg-battles column as a sanity check. Winning admirals fight more battles (Thale 12.88, Vesh 12.66, Vex 12.12) while losing admirals fight fewer (Ashgrove 9.52, Voice 10.22, Vell 10.22). This is internally consistent: winning means surviving longer. No anomaly here, but it confirms that the low win rates are driven by early elimination, not by late-game collapse.
No data.js edits proposed or made. All number changes are framed as owner questions. All expected shifts are marked as estimates. This leg was written independently from the pack alone, without reference to any other reader's screen.
