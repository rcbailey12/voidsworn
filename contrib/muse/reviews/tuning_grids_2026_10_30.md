# Voidsworn: Tuning Grids for the Ruled-but-Untuned Knobs

Date: Oct 30, 2026. Chair: Rey (Muse). Game pin: 264f441d43a54e3679950dcc4457133b40811807. Companion to montecarlo_evidence_2026_10_30.md (same harness, same stated bot policy; methodology and approximations live there and are not repeated here).

How the grids were run: each row is 300 full campaign runs (Veteran, fixed seeds, recorded in ~/workspace/voidsworn-montecarlo/raw/grid_*.json), with one knob moved at a time. Price rows scale the target faction's hull costs in the harness after data load; CP rows adjust the run's CP cap by the stated delta; healing rows are exact-once in-memory source replacements in the harness's copy of the campaign files (the files on disk were never edited; the loader throws if a pattern does not occur exactly once). Win rates carry Wilson 95 percent intervals; at n = 300 an interval is about plus or minus 5.5 points, so small gaps between rows are not decisions. Baselines are the main batch's Veteran figures at n = 1,800 per faction.

## Grid (a): faction price and CP multipliers (Ryan's Oct 29 principle)

The principle as ruled: Eclipse ships stronger but more expensive, Chorus the opposite, faction appropriate across stats, price, and CP. These rows move price and CP only; the stat side is a data-table change for Opus to pair with whichever row is picked. Baselines: Chorus 85.0 percent [83.0, 87.0], Eclipse 68.0 percent [65.0, 70.0].

| Row | Change | Win rate (n = 300) | Mean ships at end of sector 1 | Read |
|---|---|---|---|---|
| A0 | Baseline (shipped prices and CP) | Chorus 85.0%, Eclipse 68.0% (n = 1,800) | not singled out | The spread the principle has to fix: 17 points between these two, 35 across all six factions |
| A1 | Chorus: CP cap +4 only | 87.0% [82.7, 90.3] | 3.84 | No reliable change. The ceiling alone is not the binding constraint |
| A2 | Chorus: hull prices x0.8 only | 88.0% [83.8, 91.2] | 3.41 | No reliable change on its own either |
| A3 | Chorus: prices x0.8 AND CP cap +4 | 91.3% [87.6, 94.0] | 4.53 | The only Chorus row that clearly moves, and it expresses exactly as the Oct 29 mapping predicted: the discount becomes more hulls (4.53 ships vs 3.41 to 3.84 in the single-knob rows), not heavier ones. This is the budget-multiplier + ceiling-allowance configuration the earlier sims favored, now confirmed in full campaign runs |
| A4 | Eclipse: hull prices x1.25 | 32.3% [27.3, 37.8] | 2.33 | Collapse. A 36-point fall from baseline, far outside any interval overlap |
| A5 | Eclipse: prices x1.25 AND CP cap -2 | 29.0% [24.2, 34.4] | 2.34 | Worse. The CP cut adds nothing but pain |

Pick-a-row guidance: A3 is the Chorus row. For Eclipse, do NOT pick A4 or A5: at +25 percent price the faction falls off an affordability cliff (the fleet shrinks to about 2.3 ships by the end of sector 1 because replacements and growth hulls stop being affordable, and no plausible stat buff compensates for having half a fleet). If Eclipse is to be stronger but more expensive, the expensive half has to be much gentler than +25 percent, or the stat buff has to ship in the same change and the pair re-measured. A +10 percent price row was not run; it is the obvious next cell if Opus wants the Eclipse side of the principle quantified before touching stats. One more caution: Chorus at A3 reaches 91.3 percent under this pilot, which widens the faction spread further unless the other factions get their own side of the principle in the same pass. The principle is a spread compressor only if it is applied across the board at once.

## Grid (b): healing-stack levers (the lever table for later; Ryan ruled accept as is)

Framing, per the Oct 29 ruling: repair economics stay generous; this grid exists so the knobs are measured if real play ever says the regroup feels flat. Baseline for this grid is the Sunward Crusade on Veteran: 50.0 percent [48.0, 52.0] at n = 1,800, with regroup binding at 0.42 percent of shipyard visits across the main batch (all factions). Binding uses the evidence pack's operationalization (fleet missing at least 25 percent of max hull AND credits below full repair plus the cheapest useful purchase).

| Row | Lever | Win rate (n = 300) | Regroup binding | Read |
|---|---|---|---|---|
| B0 | Shipped stack (post-win patch 15%, transit patch 40%, battle pay x1.0) | 50.0% (n = 1,800) | 0.42% | Accept as is (ruled) |
| B1 | Post-win patch to 0% | 40.7% [35.3, 46.3] | 1.25% (11 of 877 visits) | The post-win patch is the strongest single healing lever: worth about 9 to 10 points of win rate |
| B2 | Post-win patch to 30% | 52.7% [47.0, 58.2] | 0.10% (1 of 1,001) | Doubling the patch adds nothing measurable over shipped: the lever is saturated at 15% |
| B3 | Transit patch to 0% | 45.0% [39.5, 50.7] | 0.58% (5 of 857) | Worth about 5 points |
| B4 | Transit patch to 20% | 46.3% [40.8, 52.0] | 0.71% (7 of 990) | Indistinguishable from 0% at this n; the transit patch's value sits in its top half, or below this grid's resolution |
| B5 | Battle pay x0.7 | 45.3% [39.8, 51.0] | 0.96% (9 of 940) | Worth about 5 points against B0, about 8 against B6 |
| B6 | Battle pay x1.5 | 53.7% [48.0, 59.2] | 0.21% (2 of 938) | More pay mostly buys more hulls; binding falls |

The decision-relevant fact in this grid is what does NOT happen: binding never exceeds 1.25 percent in any row, even with the entire post-win patch deleted. No single lever makes the repair-versus-buy tradeoff bind, because the tradeoff is not what these levers govern: they govern survival (win rate moves up to 13 points across the grid) while fleets still arrive at yards nearly whole or dead, rarely in the damaged-and-poor middle where the tradeoff lives. If a future change ever wants the tradeoff to bind, this grid says it takes combined cuts (patch removal plus a pay cut together), and it prices each lever's survival cost before anyone pulls two at once.

## Grid (c): boon offer and favour rarity curves

Method: direct sampling of the shipped rollBoonOffer (900,000 offers per variant; every patron, sectors 1 to 3, favour tiers 0 to 3, minR 0 and 1, with held-boon scaffolding for duo and legendary eligibility). What-if variants are exact-once in-memory source replacements in the harness only; no game file was edited.

The shipped tax, measured (minR 0, no held boons; Rare-or-better share of picks):

| Sector | Favour tier | Patron picks | Off-patron backfill picks | Tax |
|---|---|---|---|---|
| 1 | 0 | 29.7% | 30.8% | none |
| 1 | 1 | 45.0% | 30.6% | 14.4 pp |
| 1 | 2 | 45.1% | 29.8% | 15.3 pp |
| 1 | 3 | 100.0% | 30.5% | 69.5 pp |
| 2 | 1 | 54.4% | 38.5% | 15.9 pp |
| 2 | 3 | 100.0% | 37.7% | 62.3 pp |
| 3 | 1 | 63.0% | 48.0% | 15.0 pp |
| 3 | 3 | 100.0% | 49.6% | 50.4 pp |

The staircase has two steps, both in rollRarity (core.js): the favour bonus (+.12 Rare, +.03 Epic) switches on at tier 1 and is simply never passed for backfill picks (the two rollRarity(minR, s) calls in rollBoonOffer omit the patron argument); at tier 3 the Rare floor (r at least 1) applies to patron picks only, so the tax becomes total. Backfill incidence itself is favour-independent (about 5,000 of 45,000 picks per cell here; in real runs it rises as the patron pool drains, per the filed favour sweep).

Pick-a-row fixes, measured on the same sampler:

| Row | Change | Backfill Rare+ after | Verdict |
|---|---|---|---|
| C0 | Ship as is | 30 to 50% by sector, tax 14 to 70 pp by tier | The defect Ryan ruled on Oct 28 (Q7): off-patron picks must retain real value |
| C1 | Backfill rolls pass the patron argument (one argument, one call site: the extra-pool line) | Matches patron within 1 pp at every tier (46.0 vs 45.0 at S1 t1; 100 vs 100 at t3) | Closes the measured tax |
| C2 | C1 plus the same argument on the junk-pool line | No measurable change vs C1 (junk backfill is too rare in these cells to move the share) | Harmless completeness; bundle with C1 or skip |
| C3 | Duo boons roll rarity (the same rollRarity call as patron picks) instead of entering at fixed Common | Duo incidence unchanged (about 30% of eligible offers); duo rarity distribution becomes the patron distribution by construction | Separate defect from the tax (a skipped roll, not a missing argument); the Q7 fix spec must name it separately, as the chair already flagged |

Residual: at minR 1 (elite and boss rewards), a smaller Epic-step tax remains under C0 (backfill Epic share 5.7 to 12.0 percent vs patron 8.7 to 15.3 percent at tiers 1 to 3); C1 closes it by the same mechanism. Legendary behaviour is clean: with two of a patron's boons held and minR at least 1, the legendary takes a slot in about 62 percent of offers, replacing the third slot.

## The three most decision-relevant rows

1. Grid (a) row A4: Eclipse hull prices x1.25 craters the faction to 32.3 percent [27.3, 37.8] from 68.0 percent. The expensive half of the Oct 29 principle cannot be implemented price-first at this size; it needs a gentler price step or a simultaneous stat buff, re-measured.
2. Grid (a) row A3: Chorus prices x0.8 plus CP cap +4 is the only Chorus configuration that clearly works (91.3 percent [87.6, 94.0], 4.53 ships at end of sector 1), and it works by hull count, exactly the expression the ruling wanted. Neither knob alone does anything reliable.
3. Grid (b) row B1: deleting the post-win patch is the strongest single healing lever (win rate 40.7 percent vs 50.0 baseline) and still only lifts regroup binding to 1.25 percent. If the regroup ever needs teeth, single levers will not give it any; that is a combined-cut decision, priced here in advance.
