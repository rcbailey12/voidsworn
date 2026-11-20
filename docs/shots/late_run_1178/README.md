# Issue 1178: a harder Sector 3, late money sinks, and three faction economies

Base: main a07f4a20 (issues 1160, 1175, 1176 and 1177 merged). Both twins: the browser rules (core.js, battle.js,
campaign_run.js, campaign3d.js) and the Godot game (campaign.gd, rules.gd, campaign_ui.gd, campaign_view.gd, map_intel.gd),
with the generated tables re-exported.

## What changed

| Change | Where | Numbers |
| --- | --- | --- |
| Sector 3 enemy fleets are bigger, per AI level | RAMP.late in battle.js, read by rules.gd and the map intel | 1.4x budget at Standard, 1.25x at Veteran (Veteran already has its 1.1x edge everywhere) |
| Late market at Sector 3 shipyards | lateStock / lateShopOffers / ACT.lateBuy, both twins | two relics at 120 credits, +1 command point at 130 (one per yard, two a run); prices times the usual price multiplier |
| Chorus biomass | hullKey / hullFunds / hullPay, factionWinEcon, BIO_KILL | win pay is banked as biomass plus 8 per kill (at most 50 a battle); repairs, new hulls and Marks cost biomass; credits buy refits, class refits, events and the late market |
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
that same policy. "After" is this branch at bc1826bb, the final settings (Chorus kill bonus 8, at most 50), rerun in full
after the bonus change (Artoo on PR 1276). Bot rates, not player rates.

### Where runs are lost

| Level | Arm | Win | Lost in S1 / S2 / S3 (per run) | Share of losses S1 / S2 / S3 | Win once in S3 |
| --- | --- | ---: | --- | --- | ---: |
| Standard | before | 77.5% | 12.7% / 8.3% / 1.5% | 56.5% / 37.0% / 6.5% | 98.2% |
| Standard | after | 71.9% | 12.5% / 7.3% / 8.3% | 44.4% / 25.9% / 29.6% | 89.6% |
| Veteran | before | 44.8% | 34.6% / 17.9% / 2.7% | 62.6% / 32.5% / 4.9% | 94.3% |
| Veteran | after | 40.0% | 34.4% / 17.5% / 8.1% | 57.3% / 29.2% / 13.5% | 83.1% |

Sector 1 and 2 loss rates move by at most 1.0 point (limit 3). Sector 3's share of losses passes Sector 2's at Standard
and halfway toward it at Veteran. Raising Veteran's 1.25 is the one-number lever if the Board wants more.

### Credits on entering the final boss

| Level | Seeds reaching the boss in both arms | Before | After | Change (95%) | Boss reached before / after | Late market spend on those seeds |
| --- | ---: | ---: | ---: | --- | --- | ---: |
| Standard | 350 | 292.2 | 162.2 | -130.0 (-148 to -112), -44.5% | 377 / 362 | 217 a run |
| Veteran | 185 | 242.3 | 148.9 | -93.4 (-119 to -68), -38.6% | 220 / 198 | 195 a run |

The first try priced relics at 150 and the command point at 160: Standard fell 34.9% but Veteran only 29.4%, so the prices
came down to 120 and 130. Evidence strength (Artoo): at Veteran a one-third drop is 80.8 credits, inside the 95%
interval (-119 to -68), so the point estimate clears the target but this sample does not show it clears it reliably; at Standard both the
estimate and the interval clear it. Timeouts: Standard 6 before, 6 after; Veteran 11 before, 11 after (final rerun: Standard 6, Veteran 11); no driver errors. All-seed
survival above keeps every run; timeouts resolve as the harness always has (a non-boss timeout is a retreat, a boss
timeout a loss).

### By faction (run win rate)

| Level | Arm | Crusade | Hegemony | Hullbreakers | Chorus | Glasswrights | Eclipse |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Standard | before | 75.0% | 77.5% | 83.8% | 78.8% | 60.0% | 90.0% |
| Standard | after | 67.5% | 70.0% | 76.3% | 73.8% | 53.8% | 90.0% |
| Veteran | before | 37.5% | 40.0% | 43.8% | 58.8% | 33.8% | 55.0% |
| Veteran | after | 32.5% | 30.0% | 38.8% | 52.5% | 33.8% | 52.5% |

80 runs per cell, so each cell is about plus or minus 10 points. Economy counters (after): Chorus earn about 1,950
biomass a run at Standard and 1,500 at Veteran; Glasswrights about 92 and 69 cullet credits; Eclipse recover 1.6 and 2.4 cores
and regrow 0.65 and 1.2. The Eclipse hold steady while the others drop 5 to 10, which is the core
recovery doing what 1086 measured.

### Chorus biomass tuning (Board ask on PR 1276)

The first bonus (2 per kill, at most 12) dropped Chorus at Veteran from 53.8% to 37.9% on 240 runs (seeds 1 to 240), far more
than any other faction. Kill bonus tried on the same Chorus seeds, everything else fixed:

| Kill bonus (per kill, cap) | Veteran, 240 runs | Veteran losses S1 / S2 / S3 | Standard, 240 runs | Standard, seeds 1 to 80 |
| --- | ---: | --- | ---: | ---: |
| before (main, no biomass, no Sector 3 change) | 53.8% (129) | 61 / 42 / 8 | 85.0% (204) | 78.8% (63) |
| 2, 12 (first build) | 37.9% (91) | 68 / 49 / 32 | 77.9% (187) | 76.3% (61) |
| 5, 30 | 37.1% (89) | 66 / 50 / 35 | | 66.3% (53) |
| **8, 50 (shipped)** | **47.5% (114)** | 66 / 41 / 19 | 76.3% (183) | 73.8% (59) |
| 10, 70 | 45.8% (110) | 66 / 40 / 24 | | 72.5% (58) |
| 12, 80 | 45.4% (109) | 66 / 41 / 24 | | 75.0% (60) |

Gains stop at 8: 10 and 12 land within noise of it (about plus or minus 3 points at 240 runs). Standard does not move with
the bonus at all; its drop is all in Sector 3 (losses 3 to 22 or 23 of 240, Sector 1 and 2 unchanged), which is the shared
fleet change.

**What causes the drop (Artoo's split, Chorus Veteran, same 240 seeds, late market and bot policy fixed):**

| Biomass | Sector 3 fleets 1.25x | Win | Losses S1 / S2 / S3 |
| --- | --- | ---: | --- |
| off | off | 53.8% (129) | 61 / 42 / 8 |
| off | on | 47.9% (115) | 61 / 42 / 22 |
| on (2, 12) | off | 46.3% (111) | 68 / 49 / 12 |
| on (2, 12) | on | 37.9% (91) | 68 / 49 / 32 |
| on (8, 50) | on | 47.5% (114) | 66 / 41 / 19 |

Both causes are real and about the same size (6 to 8 points each), and they stack. The 8 per kill bonus removes the biomass
cost: with it, Chorus at Veteran (47.5%) matches the biomass-off arm (47.9%) and its Sector 1 and 2 losses return to near
before. What is left, about 6 points, is the Sector 3 fleet change every faction takes (the others fall 0 to 10 points at
Veteran). That is 1.3 points outside the Board's 5-point line at Veteran; Standard sits on the line on the 80-seed set (5.0)
and 8.7 below on 240 seeds. A larger kill bonus does not close it. The remaining levers are not biomass: a smaller Veteran
1.25, or a Chorus-only Sector 3 easing.

**How each arm was built** (all on a detached checkout, Chorus only, `FAC=chorus node tools/late_run_1178/sim_1178.js <dir> veteran 240 1 <out>`;
Standard the same with `standard 240 1` or `standard 80 1`):

- Biomass off, fleets off: main a07f4a20 unchanged (the "before" arm).
- Biomass on, fleets on: this branch at the stated BIO_KILL (1671b7aa for 2/12; bc1826bb for 8/50).
- Biomass off, fleets on: 1671b7aa with three edits. core.js: `function hullKey(){ return 'credits'; }` and the newRun line
  `if(fac==='chorus'){ RUN.bio=RUN.credits; RUN.credits=0; }` removed; campaign_run.js factionWinEcon: the Chorus test
  `if(RUN.fac==='chorus')` replaced by `if(false)`, so win pay goes to credits. Late market, cullet and cores untouched.
- Biomass on, fleets off: 1671b7aa with battle.js `late:{standard:1.4,veteran:1.25}` changed to `late:{standard:1,veteran:1}`.
- Kill bonus arms: 1671b7aa plus the BIO_KILL table edit of bc1826bb, with `const BIO_KILL={per:N,cap:M};` set in core.js.

The sim's Chorus shipyard shim skips its biomass pass when hullKey() is not 'bio', so the biomass-off arm runs the plain
credits shipyard.

## Issue 1290: fixes from the outside review of PR 1276

Evidence: /mnt/project-files/reviews/1276_late_balance/findings.md (review read at 1888a1b3). Both twins, tables re-exported.

| Fix | Where | What changes for the player |
| --- | --- | --- |
| Dead late relics out | LATE_SHOP.skip in core.js; lateStock and lateShopOffers (both twins) | The late market never offers the Smuggler's ledger, the logbook or the Scrap rig, so both relic slots are combat relics. A yard saved before this change still lists them in its stock; they are filtered when listed and bought, and a skipped relic already bought stays shown as bought (Artoo on PR 1294; fixture godot/campaign/test/fixtures/issue_1290/old_yard.json, checked by contrib/opus/tools/late_stock_1290_tests.js and late_fixes_1290.gd) |
| Regrown ships sell for 0 until they fight | sellValue in core.js and campaign.gd; restoreCore marks the ship, rewardFlow clears it | Regrow for 20% then decommission for 35% no longer makes credits (Zenith +62, Flare +32 before) |
| Chorus decommission pays biomass | ACT.sellConfirm and its twin use the hull purse | No more biomass-to-credits side door; the button and the dialog say biomass |
| Bigger Glasswright cullet | CULLET: Frigate 25, Destroyer 45, Cruiser 70, Carrier 85, Battleship 100, cap 100 | About 25% of a lost hull's price back, still under the 35% decommission value |

Scrap rig check (the Board asked): it pays 15 credits and repairs 8% hull per win. The mean fleet at the final boss holds 707
hull, so 8% is 57 hull, worth 28 credits at the repair price of 1 per 2 hull, about 43 a battle at most. A Sector 3 run has 4.1
battles counting the boss, so a relic bought at a Sector 3 yard has 2 or 3 fights left that still matter: about 85 to 130 at
best, usually less because the fleet is not always damaged. It does not reliably earn back 120, so it is out too.

Pictures (installed in game, 1280x720): [D1290_regrown_decommission](D1290_regrown_decommission.png) (a regrown Eclipse flare:
"You receive 0 credits. A regrown ship has nothing to strip until it has fought.") and
[B1290_chorus_decommission](B1290_chorus_decommission.png) (Chorus: "You receive 16 biomass", buttons say biomass). Check:
`godot --headless --path godot --script res://campaign/test/late_fixes_1290.gd` (in godot_checks.txt).

### Measured (Veteran, 240 paired seeds per faction)

Seeds 1 to 240 for each faction, admirals rotated, same bot and harness as above. Before = main ab6b3258 (PR 1276 merged),
after = a04bff21. The bot never decommissions, so the sell fixes cannot show here; the market and cullet changes can.

| Faction | Win before | Win after | Change | Seeds flipped win to loss / loss to win | Losses S1 / S2 / S3 before | after | Credits at the boss, paired (change, 95%) |
| --- | ---: | ---: | ---: | --- | --- | --- | --- |
| Crusade | 32.9% (79) | 33.3% (80) | +0.4 | 2 / 3 | 95 / 41 / 25 | 95 / 41 / 24 | 175 to 176 (0, -5 to 6) |
| Hegemony | 30.0% (72) | 30.0% (72) | 0.0 | 1 / 1 | 92 / 48 / 28 | 92 / 48 / 28 | 135 to 138 (+3, -2 to 8) |
| Hullbreakers | 38.3% (92) | 38.3% (92) | 0.0 | 1 / 1 | 94 / 38 / 16 | 94 / 38 / 16 | 145 to 153 (+8, -13 to 28) |
| Chorus | 47.5% (114) | 44.2% (106) | -3.3 | 9 / 1 | 66 / 41 / 19 | 66 / 41 / 27 | 109 to 118 (+10, 2 to 18) |
| Glasswrights | 27.5% (66) | 26.7% (64) | -0.8 | 14 / 12 | 102 / 55 / 17 | 100 / 58 / 18 | 144 to 133 (-11, -42 to 20) |
| Eclipse | 52.1% (125) | 52.9% (127) | +0.8 | 1 / 3 | 71 / 28 / 16 | 71 / 28 / 14 | 160 to 155 (-5, -15 to 6) |

No driver errors; timeouts 26 before, 29 after. Late market buys: 905 relics and 20 command points before, 894 and 22
after; ledger, logbook and Scrap rig went from 119 buys to 0, and armourweave, martyr, compass, coils and banner took them.

- **Five factions do not move** beyond 1 point, which is what the fixes intend.
- **Chorus: -3.3 points**, all of it in Sector 3 (losses 19 to 27; 9 seeds flip to a loss, 1 the other way). It is about one
  standard error of a 240-run rate, but the flips lean one way, so treat it as probably real and small. The likely cause:
  Chorus buy the most late relics (1.8 a Sector 3 run) and the Scrap rig was their heal. A first after arm that kept the Scrap
  rig gave -1.7 (5 / 1 flips). Chorus still sit second of six, with Eclipse, so no further fix is proposed; the 5-point line
  is retired (Board, issue 1290).
- **Glasswrights: the cullet does not move the win rate.** Cullet paid rises from about 72 to 118 credits a run, the win rate
  is flat (27.5% to 26.7%), and the flips nearly cancel (14 wins became losses, 12 losses became wins), which is noise. The
  Board's keep rule is "no win-rate change beyond noise" (issue 1290 body), so it stays. The cullet does not fix the
  Glasswright win rate; their 27.5% before this change is a separate question, below.

### Evidence only: what holds the Glasswrights back at Veteran (no change proposed here)

Read from the same 240-seed "before" arm (main ab6b3258) and the hull tables in data.js. Bot rates, not player rates.

| | Crusade | Hegemony | Hullbreakers | Chorus | Glasswrights | Eclipse |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Run losses S1 / S2 / S3 (of 240) | 95 / 41 / 25 | 92 / 48 / 28 | 94 / 38 / 16 | 66 / 41 / 19 | 102 / 55 / 17 | 71 / 28 / 16 |
| Fight loss rate: S1 boss | 13% | 8% | 11% | 5% | **18%** | 10% |
| Fight loss rate: S2 elite / S2 boss | 19% / 7% | 20% / 9% | 11% / 6% | 15% / 4% | **24% / 14%** | 15% / 3% |
| Fight loss rate: ordinary S1 / S2 battles | 5% / 7% | 5% / 12% | 4% / 5% | 3% / 6% | 5% / 10% | 5% / 6% |
| Fleet max hull at the final boss | 703 | 595 | 684 | 830 | **433** | 825 |
| Ships at the final boss | 5.4 | 4.8 | 6.3 | 5.8 | 5.2 | 7.2 |
| Own vs enemy CP in S1 fights | 5.9 / 8.4 | 5.9 / 8.4 | 6.2 / 8.7 | 6.0 / 8.6 | 5.9 / 8.4 | 6.1 / 8.2 |
| Shop hulls: hull per command point | 42.8 | 37.6 | 40.6 | 42.0 | **27.6** | 47.4 |
| Shop hulls: armour | 18% | 17% | 13% | 14% | **3%** | 25% |
| Shop hulls: evasion | 7 | 8 | 12 | 7 | **20** | 7 |
| Shop hulls: price per command point | 68 | 65 | 62 | 58 | **79** | 106 |
| Shop hulls: hull plus shields per 100 credits | 73 | 70 | 75 | 76 | 45 | 44 |
| Shop hulls: expected damage a turn per 100 credits | 22.2 | 18.4 | 27.2 | 32.1 | 16.4 | 14.5 |

What it shows:
- **Not the fleet budget.** Enemy fleets in Sector 1 are the same size against every faction (8.2 to 8.7 enemy CP against
  5.9 to 6.2 of their own), so the Glasswrights are not drawing bigger fights.
- **They lose the big fights, not the ordinary ones.** Ordinary battles go about like everyone else's. The gap is the
  Sector 1 boss (18% lost, next worst 13%), the Sector 2 elites (24%, next 20%) and the Sector 2 boss (14%, next 9%): long
  fights against heavy hitters.
- **Glass hulls.** Their ships carry the least hull per command point (27.6, against 37.6 to 47.4), almost no armour (3%),
  and lean on evasion 20 instead. They also cost the most per command point after the Eclipse. They reach the final boss
  with 433 total hull, against 595 to 830 for everyone else. Evasion does not stop the big single shots and area damage that
  bosses and elites bring (likely, not measured per weapon).
- **Not only Veteran.** At Standard they were also last (60.0% against 75 to 90%, PR 1276 before arm), so this is the faction's
  build, not the Veteran AI edge.

Levers for a later issue, cheapest first (untested): Glasswright hull prices nearer the field (79 a CP to about 68), a little
more hull on the wisp and blade, or an evasion rule that also softens area hits. Which one is a design call.

## Checks run (cloud, Godot 4.7.2, Node 22)

- Campaign parity: PASS on 30 seeds plus the cross-twin hand-off (both twins play the late market and the core regrow).
- Rules parity: PASS; saved Godot results refreshed for the four Sector 3 battles the fleet change moves (godot/rules/test/saved/changes.txt).
- Map trial: PASS, pin refreshed. late_run_shots.gd: PASS. fleet_invariants, fixture_check: PASS. b1_tests 40 ok.
- Rebuild the numbers: run sim_1178.js on main and on this branch, then `node tools/late_run_1178/summarize_1178.js --paired <before files> <after files>`.
