# Voidsworn: Chorus A3 High-n Confirmation

Date: Oct 31, 2026. Chair: Rey (Muse). Companion to price_grid_correction_2026_10_31.md, which corrected grid (a) of tuning_grids_2026_10_30.md after the harness compounding bug. Game pin unchanged: 264f441d43a54e3679950dcc4457133b40811807. Harness: the fixed copy in voidsworn-montecarlo-fix (driver.js restores shipped HULLS costs at the start of every run); the harness was not modified further for this run.

## The question

Grid row A3 is the Chorus side of Ryan's Oct 29, 2026 faction principle: hull prices x0.8 AND CP cap +4. The corrected n = 300 measurement read 89.3% [85.3, 92.3] with 4.21 ships at end of sector 1, against the Chorus baseline of 85.0% [83.0, 87.0] at n = 1,800. The intervals overlapped, so whether the combined knob truly beats baseline was not firm. This run answers that one question at n = 1,800.

## Method

shard.js assigns seeds sequentially (seed = seed0 + i, shard.js line 37) and rotates admirals in fixed order, so a single run at seed0 21000 with n = 1,800 (Veteran, faction chorus, priceMult 0.8, cpDelta +4, baseline policy, the original A3 configuration in every other respect) contains the corrected n = 300 shard as its first 300 runs and adds 1,500 fresh runs on seeds 21300 to 22799, a range no earlier Chorus row used. Aggregation is the grid method throughout: Wilson 95 percent intervals on wins; ships is the mean fleet size at the last post-battle snapshot of sector 1. Aggregates were computed from the final shard file (meta done = 1800, seeds 21000 to 22799 contiguous, zero runs with harness errors, 26 timeouts total). Raw output: raw/fix_chorus_p80cp_n1800.json in this workdir.

## Results

| Sample | Seeds | Wins | Win rate (95% CI) | Ships at end of S1 |
|---|---|---|---|---|
| Subset, runs 1-300 (reproduction) | 21000-21299 | 268/300 | 89.3% [85.3, 92.3] | 4.21 |
| Fresh sample, runs 301-1800 | 21300-22799 | 1338/1500 | 89.2% [87.5, 90.7] | 4.14 |
| Full sample, runs 1-1800 (headline) | 21000-22799 | 1606/1800 | 89.2% [87.7, 90.6] | 4.15 |
| Chorus baseline (main batch, shipped prices and CP) | n = 1,800 | - | 85.0% [83.0, 87.0] | not singled out |

Subset verification: the first 300 runs reproduce the corrected n = 300 shard field for field (win flag, end-of-sector-1 ship count, and seed compared per run; zero mismatches), so the high-n run is a strict extension of the corrected measurement, not a new sample of a different setup. The fresh 1,500 runs, on seeds never used before, read 89.2% on their own, so the headline is not carried by the original 300.

## Verdict: CONFIRMED

At n = 1,800 the A3 interval [87.7, 90.6] clears the baseline interval [83.0, 87.0] entirely: the A3 lower bound sits above the baseline upper bound, and the point estimate is 4.2 points above the baseline point estimate (89.2% against 85.0%). The combined knob, prices x0.8 plus CP cap +4, truly beats baseline for the Chorus under this bot policy. Neither knob alone did anything reliable in the corrected grid (price alone 85.0%, dead on baseline; CP alone 87.0%, no reliable change), so the gain belongs to the combination, exactly the shape the Oct 29 principle predicted.

The hull-count figure holds at scale: 4.15 ships at end of sector 1 across the full 1,800 (subset 4.21, fresh sample 4.14), against 3.37 for price alone and 3.84 for CP alone in the corrected grid. The discount still expresses as more hulls when the ceiling allows them, and at this n the extra hulls come with a real win-rate gain, not just a reshuffle.

Scope note: this confirms A3 against the Chorus baseline only. It does not re-measure any other row, and it says nothing about the stat side of the Oct 29 principle, which no grid row has ever moved.
