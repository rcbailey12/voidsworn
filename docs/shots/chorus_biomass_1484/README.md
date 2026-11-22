# Issue 1484: Chorus biomass pays at the shipyard (R382, RULEBOOK 11.9)

**What changed.** A Chorus run pays for refits, class refits, protocol rerolls and the Sector 3 late market in biomass when
biomass covers the price, otherwise in credits. One purse per purchase, never split. Every other fleet still pays credits.
Buttons name the purse that will pay. Repairs, new hulls and Marks stay biomass only (issue 1178).

**Why both purses.** The brief assumed credits barely reach a Chorus run. The sim says otherwise: on main the Chorus bot
spends about 350 (Veteran) to 485 (Standard) credits a run on refits alone, from repair stipends, ransoms, scrap and declined
protocols. Biomass only would have stranded those credits, so biomass pays first and credits still work.

## Pictures

Built by `godot/campaign/test/chorus_biomass_1484_shots.gd` (cloud, compatibility renderer, 640 biomass and 0 credits):

- CHO-1_chorus_late_market.png: the shipyard top, the biomass note and the late market priced in biomass.
- CHO-2_chorus_refits_tracks.png: hulls, refits for sale and class refits, all priced in biomass.

## Measured (tools/late_run_1484/sim_1484.js, Chorus, seeds 1 to 240, admirals rotated)

Before = main 1b6744c3, after = this branch. Same bot in both arms: each purchase reads the purse its tree actually charges,
the bot also buys class refits and rerolls, and every purchase is checked by its effect. No run errors in either arm.

| | Veteran before | Veteran after | Standard before | Standard after |
|---|---|---|---|---|
| Win rate | 48.8% | 47.9% | 76.3% | 78.3% |
| Paired flips (lost to won / won to lost) | | 22 / 24 | | 20 / 15 |
| Losses S1 / S2 / S3 | 56 / 42 / 25 | 56 / 45 / 24 | 22 / 14 / 21 | 23 / 14 / 15 |
| Refits bought per run (fitted) | 4.59 (4.17) | 3.62 (3.25) | 6.33 (5.72) | 5.26 (4.67) |
| Refit spend per run, biomass / credits | 0 / 351 | 159 / 119 | 0 / 485 | 279 / 123 |
| Late market buys per run | 0.91 | 2.75 | 1.48 | 4.65 |
| Late market spend per run, biomass / credits | 0 / 114 | 83 / 269 | 0 / 181 | 163 / 426 |
| Class refits per run | 0.13 | 0.12 | 0.21 | 0.12 |
| Biomass / credits on entering the final boss | 457 / 122 | 150 / 164 | 445 / 112 | 161 / 211 |

Reading: the win rate does not move beyond noise (about plus or minus 3 points at 240 runs; the paired flips balance). The
Chorus now spend their biomass at the shop and buy far more from the late market. Protocol rerolls: **untested by the sim**
(the bot rerolls only an offer it would decline, and it never declined one); the twin tests cover them.

Rebuild: on each tree run `FAC=chorus node tools/late_run_1484/sim_1484.js <tree> veteran 240 1 <out.json>` (and
`standard`), then `node tools/late_run_1484/summarize_1484.js Veteran <before> <after> Standard <before> <after>`. The sim
stubs `torpThreat` to 0: the Muse bot still calls the function issue 1379 removed, which ended every sim_1178 run at its first
battle since Nov 20.
