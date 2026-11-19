# Mechanics test results, Nov 17, 2026

Method: flag-driven test copy of the sim (34x24, belt map, open shape, strip arena, rout, mirror Hegemony fleets, 1.25 speed and range whole numbers, 24 seeds per config, medians). New step 0 metrics: netDisp = net displacement per post-contact activation, multiDisp = displacement over a two-activation window (catches oscillation), bearDiv = distinct firing bearings per target. Base line: win% 21 (player seat), rounds 9.5, netDisp 3.08, multiDisp 3.81, bearDiv 2.38, distance per move 3.25, move-only 16.2%, post-contact move-and-fire 85.3%, mean firing range 3.40, coverage 0.15, shot cluster 0.33, no timeouts anywhere.

Correction to the round's framing: the bot already prices movement evasion per candidate. stateView stamps the candidate view with the path length, so motionHit (still +10, evade -5 at 3+ hexes) is inside the threat estimate for every destination. The gap is magnitude, not blindness: a few points of threat against offense swings of tens. The earlier claim that every candidate is priced as sat still was wrong.

## Verdicts

1. Two-pass selection (combat budget 10%): PASS on behavior. netDisp 3.73 (+21%), distance per move 3.83 (+18%), multiDisp 4.31 (+13%), cluster 0.29, rounds 10.0, no timeouts. The clearest movement-feel win in the set, and it is a bot change only, no rules change. Caveat: mirror win% is not readable in this setup (the two bot implementations respond asymmetrically; two-pass alone showed 8% player wins, the stack showed 50%, same behavior numbers). Balance needs an asymmetric check before adoption.
2. Multiplicative scoring: PASS on spread, different goal. Coverage 0.17 (the only config to move it), cluster 0.22 (biggest drop), mean range 3.91, multiDisp 4.46 (+17%), netDisp 3.34 (+8%), rounds 11.0. Ships fight further apart and further out. This is the structural option if spread is the goal; it is not primarily a movement-feel change.
3. Momentum (straight-line 4+ hexes, +15% damage): modest positive. netDisp 3.26 (+6%), multiDisp 4.21 (+10%), bearDiv 2.57. Small, cheap, real. Better than the synthesis expected.
4. Long-gun close weakness (-20 to hit at range 2 or less for range 5+ guns): works as designed. Mean firing range 3.74 (+10%), everything else near base. Long guns keep their distance. Adoption is a design call, not a metrics call.
5. Range falloff, damage-band form (accuracy falloff off, damage tapers to 60% at max range past optimal): mirror test null, as expected with identical range profiles. Asymmetric test (CP-matched Hegemony gun line vs Corsair brawlers, both seats, 48 battles per ruleset): Hegemony wins 33 of 48 under the shipped accuracy falloff, 29 of 48 under the damage band. Both direction cells moved the same way (Hegemony as player 62% to 54%; Corsair as player 25% to 33%). Direction matches the design intent (closing pays more under the band), size is modest and inside noise at this count. Promising, not proven. First fleet attempt was CP-mismatched (13 vs 16) and swept 48 of 48; discarded.
6. Evasion strength (evade 5 to 12; also evadeAt 2 variant): battles stretch (rounds 9.5 to 11.0), movement shape unchanged. A defensive tuning dial, not a feel lever.
7. Rear-quarter hit bonus (+10): null. Bots do not chase rear shots more; the existing rear package (armor halved, crit) already prices the incentive.
8. Deconfliction (destination repulsion): null at tested weights.
9. Coarse fields (opportunity minus threat count, weight 3): weak to null. multiDisp 4.09, rest flat.
10. Persistent course (continuity bonus): NEGATIVE. netDisp 2.55 (-17%), distance per move 2.77, cluster up. Anchoring ships to their last destination shrinks movement. Reject as implemented.
11. Turn-rate limit (one hexside per activation): null. Large facing changes are rare or cheap to give up.
12. Spinal arcs on long turret guns: null to negative. bearDiv down to 2.25, rest flat.
13. Torpedo forecasting: UNTESTED, not a null. The mirror fleets field no torpedoes (torp launches 0 in every battle), so the flag never engaged. Needs a torpedo-armed fleet to test.
14. Stack (two-pass plus evade 12): behavior equals two-pass alone (netDisp 3.70). Evasion strength adds nothing on top.

## Recommended order from the evidence

Adopt-test two-pass first (bot only, asymmetric balance check next). Hold multiplicative as the spread option if the positional goal returns. Keep momentum and long-gun weakness as cheap design-call rules. Run the falloff asymmetric test at higher count only if the faction texture is wanted. Drop course, deconfliction at these weights, rear-hit bonus, turn limit, spinal arcs. Retest torpedo forecasting with a torpedo fleet before judging it.
