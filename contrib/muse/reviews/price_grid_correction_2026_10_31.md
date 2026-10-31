# Voidsworn: Price Grid Correction Addendum

Date: Oct 31, 2026. Chair: Rey (Muse). Companion to tuning_grids_2026_10_30.md. This addendum corrects grid (a) of that document (faction price and CP rows). Grids (b) and (c) are untouched by this correction. Game pin unchanged: 264f441d43a54e3679950dcc4457133b40811807.

## The bug and the fix

The price rows in the original grid were run with a harness defect: in driver.js, function mcRunOne applied the price multiplier by mutating the shared HULLS table in place (h.cost scaled by cfg.priceMult for the target faction), and nothing restored the shipped costs afterward. A shard process runs 300 campaigns in one process, so the multiplier compounded run over run: at x1.25 a 100-credit hull cost 125 in run 1, 155 in run 2, 195 in run 3, and kept climbing, while at x0.8 prices sank further below the stated multiplier every run. Only the first run of each original price shard was run at the stated price. The fix, applied in a copy of the harness (the original folder and its evidence are untouched), snapshots the shipped hull costs once at harness load and restores them at the start of every run, before the multiplier line runs; the multiplier line itself, including its rounding and floor, is unchanged. A probe in one process ran four consecutive Eclipse campaigns at x1.25 and printed the cost of d_scythe (base 100) after every run: 125, 125, 125, 125. Under the bug the same probe reads 125, 155, 195, 245.

## Corrected table (grid (a) rows)

All rows: Veteran, n = 300, same seeds as the original shards (paired seeds), same bot policy, same aggregation (Wilson 95 percent intervals; ships is the mean fleet size at the last post-battle snapshot of sector 1, the definition that reproduces every figure in the original document from its raw files).

| Row | Change | Seeds | Original win rate | Original ships, end of S1 | Corrected win rate (95% CI) | Corrected ships, end of S1 |
|---|---|---|---|---|---|---|
| A1 | Chorus: CP cap +4 only (control, priceMult 1) | 22000 | 87.0% [82.7, 90.3] | 3.84 | 87.0% [82.7, 90.3] | 3.84 |
| A2 | Chorus: hull prices x0.8 only | 20000 | 88.0% [83.8, 91.2] | 3.41 | 85.0% [80.5, 88.6] | 3.37 |
| A3 | Chorus: prices x0.8 AND CP cap +4 | 21000 | 91.3% [87.6, 94.0] | 4.53 | 89.3% [85.3, 92.3] | 4.21 |
| A4 | Eclipse: hull prices x1.25 | 23000 | 32.3% [27.3, 37.8] | 2.33 | 60.7% [55.0, 66.0] | 3.13 |
| A5 | Eclipse: prices x1.25 AND CP cap -2 | 24000 | 29.0% [24.2, 34.4] | 2.34 | 61.7% [56.1, 67.0] | 2.99 |

Baselines (main batch, n = 1,800, not rerun): Chorus 85.0% [83.0, 87.0], Eclipse 68.0% [65.0, 70.0]. Eclipse rows were run under the harness faction id deathless. Zero runs with harness errors in any corrected shard.

## Verdicts on the two withdrawn conclusions

1. "Eclipse collapses at x1.25" is WITHDRAWN; it does not survive correction. At a true, constant x1.25, Eclipse wins 60.7% [55.0, 66.0], about 7 points below its 68.0% baseline with intervals just touching, and fields 3.13 ships at the end of sector 1, not 2.33. There is no affordability cliff at +25 percent; there is a moderate, affordable cost. Row A5 (adding CP cap -2) is indistinguishable from A4 (61.7%, 2.99 ships), reversing the original read that the CP cut added pain. Consequence for the Oct 29 principle: the expensive half for Eclipse does not have to be "much gentler than +25 percent" on price evidence; +25 percent is a live candidate, and the pairing question is back to the stat side, which these rows never measured. A gentler step (x1.10) is still unmeasured, but it is now an option, not a necessity.

2. "Chorus x0.8 + CP +4 is the only Chorus row that clearly works" is WEAKENED, not reversed. A3 remains the best Chorus row and the mechanism still shows: 4.21 ships at the end of sector 1 against 3.37 for price alone and 3.84 for CP alone, so the discount still expresses as more hulls when the ceiling allows them. But at true prices A3 is 89.3% [85.3, 92.3], which overlaps the baseline interval (85.0% [83.0, 87.0]); at n = 300 "clearly moves" overstates the separation, and the original 91.3% / 4.53 figures were flattered by prices that kept sinking below x0.8. The single knobs, corrected: prices x0.8 alone does nothing measurable (85.0%, dead on baseline, 3.37 ships); CP cap +4 alone does nothing reliable (87.0%, the control row, bit-identical to its original run). If the Chorus side of the principle needs a firmer read, A3 is the row to rerun at higher n; the direction and the hull-count mechanism are not in doubt, the size is.

## Method note

Paired seeds throughout: every corrected shard used the exact seed base, run count, faction, difficulty, admiral rotation and bot policy of its original shard (configs recovered from grid_shards.sh and confirmed against the meta blocks of the original raw shard files; no discrepancies found). The only harness change is the cost snapshot-and-restore in driver.js; the control row proves the change is inert when no price knob is active: rerun A1 (Chorus, CP +4, priceMult 1) reproduces the original shard exactly, 261 of 300 wins, 87.0% [82.7, 90.3], 3.84 ships, even the same timeout count (3). Aggregation for this addendum reproduces all five original rows' published figures from the original raw files before being applied to the corrected shards. Corrected raw outputs: raw/fix_chorus_p80.json, raw/fix_chorus_p80cp.json, raw/fix_chorus_cp.json, raw/fix_eclipse_p125.json, raw/fix_eclipse_p125cp.json in the correction workdir (voidsworn-montecarlo-fix).

## What is NOT affected

The defect fired only when a price multiplier other than 1 was configured, and only inside grid (a)'s price shards. NOT affected, and not rerun: the baseline Monte Carlo (montecarlo_evidence_2026_10_30.md, all factions at shipped prices), the policy sensitivity program (policy_sensitivity_2026_10_30.md), grid (b) healing rows (source replacements, no price multiplier), grid (c) boon and favour results (direct offer sampling), and every economy and regroup figure in the evidence pack. cpDelta and credMult were always applied to fresh per-run state and never compounded; the A1 control row's exact reproduction confirms it.
