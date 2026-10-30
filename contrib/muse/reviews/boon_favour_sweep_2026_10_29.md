# Boon offer tax: six-level favour sweep (wave 5 follow-up, Oct 30, 2026)

Follow-up to measurement 2 in measurements.md, which quantified the off-patron rarity tax at favour 0, 4 and 25 only. This sweep fills in the favour axis. Same pin (browser code at main 264f441d), same shipped rollBoonOffer, Opus can re-run it with boon_favour_sweep.js.

Method: the shipped rollBoonOffer run headlessly on the harness loader, with cross-run favour (META.favour) set uniformly across all six patrons to 0, 2, 4, 8, 15 or 25, in the same backfill states part 2 used: a broad fleet covering every boon kit at sector 3 with 4 or 5 of the patron's useful boons held, and a narrow gun-only fleet at sector 3 with 1 held. Each cell rolls 13,200 offers per favour level (2,200 per patron), 237,600 offers in total, and the RNG seed is paired across favour levels within a cell, so the only thing that changes along a row is favour itself. Rarity effect multipliers: Common 1, Rare 1.5, Epic 2, Legendary 1 (data.js RARITY), so mean m is the expected effect size of a pick.

Favour tiers for reference (data.js FAVOUR_TIERS): tier 0 Listening at 0, tier 1 Partial sync at 4, tier 2 Synced at 12, tier 3 Full sync at 25. So the six levels land as tier 0, 0, 1, 1, 2, 3.

## Broad fleet, sector 3, 4 held (the part 2 tax cell, 1 off-patron pick per offer)

| favour (tier) | on-patron C/R/E % | off-patron C/R/E % | on Rare or better | off Rare or better | tax (points) | on mean m | off mean m | tax (mean m) |
|---|---|---|---|---|---|---|---|---|
| 0 (0) | 51.7 / 36.4 / 12.0 | 51.9 / 36.0 / 12.1 | 48.3% | 48.1% | 0.2 | 1.302 | 1.301 | 0.001 |
| 2 (0) | 51.7 / 36.4 / 12.0 | 51.9 / 36.0 / 12.1 | 48.3% | 48.1% | 0.2 | 1.302 | 1.301 | 0.001 |
| 4 (1) | 37.0 / 48.0 / 15.0 | 51.9 / 36.0 / 12.1 | 63.0% | 48.1% | 14.9 | 1.390 | 1.301 | 0.089 |
| 8 (1) | 37.0 / 48.0 / 15.0 | 51.9 / 36.0 / 12.1 | 63.0% | 48.1% | 14.9 | 1.390 | 1.301 | 0.089 |
| 15 (2) | 37.0 / 48.0 / 15.0 | 51.9 / 36.0 / 12.1 | 63.0% | 48.1% | 14.9 | 1.390 | 1.301 | 0.089 |
| 25 (3) | 0.0 / 85.0 / 15.0 | 51.9 / 36.0 / 12.1 | 100.0% | 48.1% | 51.9 | 1.575 | 1.301 | 0.274 |

## Broad fleet, sector 3, 5 held (2 off-patron picks per offer)

| favour (tier) | on Rare or better | off Rare or better | tax (points) | on mean m | off mean m | tax (mean m) |
|---|---|---|---|---|---|---|
| 0 (0) | 48.3% | 47.8% | 0.5 | 1.302 | 1.298 | 0.004 |
| 2 (0) | 48.3% | 47.8% | 0.5 | 1.302 | 1.298 | 0.004 |
| 4 (1) | 63.3% | 47.8% | 15.5 | 1.392 | 1.298 | 0.094 |
| 8 (1) | 63.3% | 47.8% | 15.5 | 1.392 | 1.298 | 0.094 |
| 15 (2) | 63.3% | 47.8% | 15.5 | 1.392 | 1.298 | 0.094 |
| 25 (3) | 100.0% | 47.8% | 52.2 | 1.575 | 1.298 | 0.277 |

## Narrow gun-only fleet, sector 3, 1 held (0.667 off-patron picks per offer)

| favour (tier) | on Rare or better | off Rare or better | tax (points) | on mean m | off mean m | tax (mean m) |
|---|---|---|---|---|---|---|
| 0 (0) | 48.4% | 48.2% | 0.2 | 1.304 | 1.301 | 0.003 |
| 2 (0) | 48.4% | 48.2% | 0.2 | 1.304 | 1.301 | 0.003 |
| 4 (1) | 63.3% | 48.2% | 15.1 | 1.393 | 1.301 | 0.092 |
| 8 (1) | 63.3% | 48.2% | 15.1 | 1.393 | 1.301 | 0.092 |
| 15 (2) | 63.3% | 48.2% | 15.1 | 1.393 | 1.301 | 0.092 |
| 25 (3) | 100.0% | 48.2% | 51.8 | 1.576 | 1.301 | 0.275 |

## Verdict: THE TAX IS A TWO-STEP STAIRCASE IN FAVOUR, FLAT WITHIN EACH STEP.

The tax does not grow linearly with favour, and it does not step at every favour tier either. It takes exactly two steps, and both are visible in all three cells at the same heights:

1. No tax below favour 4. At favour 0 and 2 the on and off distributions are the same to within noise (gap 0.2 to 0.5 points, mean m gap at most 0.004), the negative control from part 2 extended one level up.
2. A flat step of about 15 points from favour 4 through favour 24. Favour 4, 8 and 15 return identical distributions in every cell (on-patron 63.0 to 63.3% Rare or better, mean m 1.390 to 1.393), because the paired seeds make the comparison exact: within a step, extra favour changes literally nothing. This step spans tier 1 (Partial sync, at 4) and tier 2 (Synced, at 12) without moving at the tier 2 boundary, because tier 2's perk is a starting protocol, not a rarity change, and rollRarity (core.js:177) only tests tier at least 1 (plus 12 points of Rare chance, plus 3 of Epic) and tier at least 3 (the Rare floor).
3. A jump to about 52 points at favour 25. At Full sync the on-patron side hits the tier 3 floor (100.0% Rare or better, mean m 1.575) while the filler side stays at the tier 0 distribution (about 48% Rare or better, mean m about 1.30), so the whole of the tier 3 promise becomes tax: 51.8 to 52.2 points of Rare or better and 0.274 to 0.277 of mean m, about 17% less expected effect per filler pick.

Two supporting facts. First, backfill incidence never moves with favour: off-patron picks per offer are constant per cell at every level (1.000 at 4 held, 2.000 at 5 held, 0.667 for the narrow fleet), so favour changes only what a filler rolls, never how often one appears. Second, the step heights are the formula, not sampling luck: rollRarity at sector 3 gives Rare or better of 48% at tier 0 (36 Rare plus 12 Epic), 63% at tier 1 or 2 (48 plus 15), and 100% at tier 3, and every measured row sits on those values within noise. The sweep also reproduces part 2's three points in the shared cell (62.9% at favour 4 there, 63.0% here; 100.0% at favour 25 in both), so the two runs agree.

Practical reading for the Q7 fix: there is no gradual slope to soften. A player crosses the whole first step the moment a patron reaches Partial sync, and the second the moment one reaches Full sync, and the filler picks in that patron's offers stay at the tier 0 distribution in both cases. Any fix that applies the offering patron's favour to every pick in the offer (as the Q7 fix spec already proposes) removes both steps at once.
