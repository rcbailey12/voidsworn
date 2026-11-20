# Issue 1178: a harder Sector 3, late money sinks, and three faction economies

Base: main a07f4a20 (issues 1160, 1175, 1176 and 1177 merged). Both twins: the browser rules (core.js, battle.js,
campaign_run.js, campaign3d.js) and the Godot game (campaign.gd, rules.gd, campaign_ui.gd, campaign_view.gd, map_intel.gd),
with the generated tables re-exported.

## What changed

| Change | Where | Numbers |
| --- | --- | --- |
| Sector 3 enemy fleets are bigger, per AI level | RAMP.late in battle.js, read by rules.gd and the map intel | 1.4x budget at Standard, 1.25x at Veteran (Veteran already has its 1.1x edge everywhere) |
| Late market at Sector 3 shipyards | lateStock / lateShopOffers / ACT.lateBuy, both twins | two relics at 120 credits, +1 command point at 130 (one per yard, two a run); prices times the usual price multiplier |
| Chorus biomass | hullKey / hullFunds / hullPay, factionWinEcon | win pay is banked as biomass plus 2 per kill (at most 12); repairs, new hulls and Marks cost biomass; credits buy refits, class refits, events and the late market |
| Glasswright cullet | factionWinEcon | a win refunds credits for your own lost hulls: Frigate 15, Destroyer 30, Cruiser 45, Carrier 50, Battleship 60, at most 60 |
| Eclipse core recovery | factionWinEcon, ACT.restoreCore | a win recovers the core of the most valuable ship lost (one a battle); a shipyard regrows it at Mk I, full hull, no refits, for 20% of its value |

Paid repair prices are unchanged (Oct 29 ruling). G-C commissions and E-A Archive slots are not built. A Chorus save from
before this change moves its credits to biomass on load, the same as a new Chorus run starts.

## Pictures (installed in game, Godot campaign UI, 1280x720)

| Code | What it shows |
| --- | --- |
| [L1178_late_market](L1178_late_market.png) | Sector 3 shipyard: Late market with two relics and Command expansion |
| [B1178_chorus_biomass](B1178_chorus_biomass.png) | Chorus shipyard: biomass and credits in the header, every hull button priced in biomass |
| [E1178_eclipse_cores](E1178_eclipse_cores.png) | Eclipse shipyard: Recovered cores with the regrow button |
| [C1178_glass_cullet](C1178_glass_cullet.png) | Glasswright victory card: the lost ship and the cullet line |

Rebuild: `godot --path godot --rendering-method gl_compatibility --resolution 1280x720 --script res://campaign/test/late_run_shots.gd -- <folder>`
(headless, the same script only checks the four pages build; it is in godot_checks.txt).

## Measured (tools/late_run_1178/sim_1178.js)

480 runs per AI level per arm: seeds 1 to 80 for each of the six factions, admirals rotated, Muse's unmodified Monte Carlo
driver. The same bot policy in both arms (Artoo on PR 1276): the issue 1177 repair-stop pick, and in Sector 3 with 300 or
more credits a preference for shipyard stops. On the new tree only, the bot also buys the best late-market offer it can
afford while keeping enough for a full repair, and regrows recovered cores it can afford. "Before" is main a07f4a20 with
that same policy. Bot rates, not player rates.

### Where runs are lost

| Level | Arm | Win | Lost in S1 / S2 / S3 (per run) | Share of losses S1 / S2 / S3 | Win once in S3 |
| --- | --- | ---: | --- | --- | ---: |
| Standard | before | 77.5% | 12.7% / 8.3% / 1.5% | 56.5% / 37.0% / 6.5% | 98.2% |
| Standard | after | 72.3% | 12.3% / 7.5% / 7.9% | 44.4% / 27.1% / 28.6% | 90.1% |
| Veteran | before | 44.8% | 34.6% / 17.9% / 2.7% | 62.6% / 32.5% / 4.9% | 94.3% |
| Veteran | after | 37.7% | 34.8% / 18.3% / 9.2% | 55.9% / 29.4% / 14.7% | 80.4% |

Sector 1 and 2 loss rates move by at most 0.8 points (limit 3). Sector 3's share of losses rises to Sector 2's at Standard
and halfway toward it at Veteran. Raising Veteran's 1.25 is the one-number lever if the Board wants more.

### Credits on entering the final boss

| Level | Seeds reaching the boss in both arms | Before | After | Change (95%) | Boss reached before / after | Late market spend on those seeds |
| --- | ---: | ---: | ---: | --- | --- | ---: |
| Standard | 352 | 291.0 | 163.3 | -127.7 (-146 to -109), -43.9% | 377 / 363 | 212 a run |
| Veteran | 177 | 241.4 | 157.2 | -84.2 (-110 to -59), -34.9% | 220 / 188 | 183 a run |

The first try priced relics at 150 and the command point at 160: Standard fell 34.9% but Veteran only 29.4%, so the prices
came down to 120 and 130. Timeouts: Standard 6 before, 6 after; Veteran 11 before, 11 after; no driver errors. All-seed
survival above keeps every run; timeouts resolve as the harness always has (a non-boss timeout is a retreat, a boss
timeout a loss).

### By faction (run win rate)

| Level | Arm | Crusade | Hegemony | Hullbreakers | Chorus | Glasswrights | Eclipse |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Standard | before | 75.0% | 77.5% | 83.8% | 78.8% | 60.0% | 90.0% |
| Standard | after | 67.5% | 70.0% | 76.3% | 76.3% | 53.8% | 90.0% |
| Veteran | before | 37.5% | 40.0% | 43.8% | 58.8% | 33.8% | 55.0% |
| Veteran | after | 32.5% | 30.0% | 38.8% | 38.8% | 33.8% | 52.5% |

80 runs per cell, so each cell is about plus or minus 10 points. Economy counters (after): Chorus earn about 1,660 biomass
a run at Standard and 1,140 at Veteran; Glasswrights about 92 and 67 cullet credits; Eclipse recover 1.6 and 2.4 cores and
regrow 0.65 and 1.2.

**Watch: Chorus at Veteran** drops 20 points (47 to 31 wins of 80), far more than the 1085 sim's 4 to 6. Biomass cannot buy
refits and credits cannot buy hull work, and the harder Sector 3 lands on that. The Eclipse hold steady while every other
faction drops 5 to 10, which is the core recovery doing what 1086 measured.

## Checks run (cloud, Godot 4.7.2, Node 22)

- Campaign parity: PASS on 30 seeds plus the cross-twin hand-off (both twins play the late market and the core regrow).
- Rules parity: PASS; saved Godot results refreshed for the four Sector 3 battles the fleet change moves (godot/rules/test/saved/changes.txt).
- Map trial: PASS, pin refreshed. late_run_shots.gd: PASS. fleet_invariants, fixture_check: PASS. b1_tests 40 ok.
- Rebuild the numbers: run sim_1178.js on main and on this branch, then `node tools/late_run_1178/summarize_1178.js --paired <before files> <after files>`.
