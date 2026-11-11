# Issue 443: rarity balance of the eight rescaled protocols (R175)

Workhorse: DeepSeek. Branch `work/issue-443-deepseek`. 2026-11-10.
Report only. No game files changed. Nothing in this job changes what Ryan sees on screen, so there are no screenshots.

## Answer first

One of the eight breaks the exit rule. **Swarm Hatch** is far too strong as it scales: Rare adds 24.0 points of win rate over Common and Epic adds 37.7 in an even carrier fight. **Hot Tubes** is the opposite problem: Rare and Epic do exactly nothing over Common because every torpedo already reloads in 2 turns and the rule floors at 1. The other six are inside the ten point guide.

| Protocol | Common win | Rare win | Epic win | Rare delta | Epic delta | Verdict |
|---|---|---|---|---|---|---|
| Shield Wall `i_wall` | 51.7% | 51.7% | 51.7% | +0.0 | +0.0 | keep (bot never braces; direct rule scales) |
| Chain Lightning `s_chain` | 57.7% | 57.0% | 60.0% | -0.7 | +2.3 | keep |
| Brood Harvest `h_brood` | 50.0% | 52.3% | 52.3% | +2.3 | +2.3 | keep |
| Marked for Death `a_mark` | 61.0% | 62.0% | 59.0% | +1.0 | -2.0 | keep (95% hit cap eats the top tier) |
| Slip the Net `r_slip` | 59.3% | 59.3% | 59.3% | +0.0 | +0.0 | keep (bot never keeps movement to use it) |
| Spread Pattern `e_spread` | 41.7% | 45.3% | 48.7% | +3.7 | +7.0 | keep |
| Swarm Hatch `h_hatch` | 53.7% | 77.7% | 91.3% | +24.0 | +37.7 | **change** |
| Hot Tubes `e_reload` | 59.0% | 59.0% | 59.0% | +0.0 | +0.0 | **change for distinctness** |

Sample: 300 battles per cell, 24 cells, 7,200 battles. Cell standard error 1.6 to 2.9 points; delta standard error 3.3 to 4.1. A delta under about 8 points is inside two standard errors and is not a real difference. Every cell is 15 chunks of 20 battles with the same seed set for Common, Rare and Epic; seeds ran from 100000 to 210866 in every cell.

## How it was measured

- Driver: `contrib/deepseek/tools/protocol_balance.js`. It calls the shipped `sim3d.js` generic mode (`node sim3d.js '<json>' <sector> <n>`), which loads `data.js`, `core.js` and `battle.js` and runs the shipped player bot against the veteran enemy AI in the mode's classic turn order. The helper only picks fleets, sets the sim's own `boons` field (`<id>:0`, `:1`, `:2`), seeds the runs and adds up the results. It copies no rule.
- Rarity: the sim passes the boon index through the game's own `RARITY` table, so 0/1/2 becomes m = 1 / 1.5 / 2 in each boon's `fx(m)`.
- Every cell uses the same player fleet, the same enemy fleet, sector 1, and one protocol at one rarity. Common is the comparison base. All fleets are Voidsworn; the enemy is Hegemony (it carries four shield facings, which Chain Lightning and Shield Wall need).

Fleets per protocol (the baseline is Common win rate):

| Protocol | Player fleet | Enemy fleet | Common |
|---|---|---|---|
| i_wall | cathedral, penitent, penitent, warden | h_dominion, h_vanguard, h_vanguard, h_picket | 51.7% |
| s_chain | penitent, penitent, harrow, warden | h_vanguard, h_interdictor, h_interdictor, h_picket | 57.7% |
| h_brood | reliquary, reliquary, penitent, warden | h_vanguard, h_dominion, h_picket | 50.0% |
| a_mark | cathedral, penitent, penitent, warden | h_dominion, h_dominion, h_vanguard | 61.0% |
| r_slip | penitent, penitent, harrow, warden | h_dominion, h_dominion | 59.3% |
| e_spread | harrow, harrow, harrow, cathedral | h_dominion, h_dominion | 41.7% |
| h_hatch | reliquary, reliquary, penitent, warden | h_dominion, h_dominion | 53.7% |
| e_reload | harrow, harrow, harrow, cathedral | h_dominion, h_dominion | 59.0% |

Seven of the eight cells sit between 50.0 and 61.0; Spread Pattern (41.7) is the only harder baseline. The guide's ten point test is best read on i_wall, h_hatch and s_chain, which sit within four points of 50. A delta that large would still show on the other baselines.

## Direct rule probes

The fleet bot does not use every protocol (it almost never braces, and it spends all movement before firing), so I also called the game's own functions at each rarity (`contrib/deepseek/tools/protocol_mechanics.js`). This proves what the rarity actually changes, independent of bot habits.

| Protocol | Common | Rare | Epic |
|---|---|---|---|
| Shield Wall: hull cut on a covered neighbour (`braceMul`) | 0.60 | 0.55 | 0.50 |
| Chain Lightning: neighbour shield left after a facing breaks | 67% | 50% | 33% |
| Brood Harvest: repair per free wing | 0% | 5% | 10% |
| Marked for Death: stored aim | +10 | +15 | +20 |
| Marked for Death: hit chance, same 82% unmarked shot | 92% | 95% | 95% |
| Slip the Net: movement kept after firing, out of 6 | 3 | 4 | 6 |
| Spread Pattern: splash of one torpedo | 30% | 45% | 60% |
| Swarm Hatch: reliquary hangar (base 2) | 3 | 4 | 5 |
| Hot Tubes: torpedo cooldown the game builds | 1 | 1 | 1 |

Two of these matter:

- Hot Tubes is a dead scaling. `data.js` gives every torpedo cooldown 2, and `core.js` builds it as `Math.max(1, cd - torpCd)`. Common (-1) already reaches the floor of 1, so Rare (-2) and Epic (-3) change nothing. The description's line "Current torpedoes reload N turns sooner" is not implemented anywhere.
- Marked for Death hits the 95% hit ceiling. Rare (+15) and Epic (+20) both read 95% on the probe shot, so the top tier is usually wasted aim. The values are still distinct as numbers and the win rate does not break anything.

## Campaign before and after PR 433

I checked out the commit before PR 433 (`12d6f97`) in a worktree and ran `SEED=777 node sim3d.js campaign 20` on both sides: 20 battles in each of the 12 sector and node cells (240 battles per side). The result lines are identical on every cell, so every delta is 0.0:

| Cell | Before | After | Delta |
|---|---|---|---|
| s1 battle | 100 / 3.3 rounds / 86% hull / 0.2 lost | same | 0 |
| s1 battle | 95 / 4.9 / 60% / 1.1 | same | 0 |
| s1 elite | 85 / 5.6 / 48% / 1.6 | same | 0 |
| s1 boss | 90 / 9.1 / 46% / 1.6 | same | 0 |
| s2 battle | 100 / 4.1 / 76% / 0.9 | same | 0 |
| s2 battle | 100 / 6.2 / 56% / 1.9 | same | 0 |
| s2 elite | 85 / 6.0 / 51% / 2.5 | same | 0 |
| s2 boss | 100 / 9.1 / 42% / 2.8 | same | 0 |
| s3 battle | 95 / 4.8 / 79% / 1.1 | same | 0 |
| s3 battle | 100 / 5.3 / 73% / 1.4 | same | 0 |
| s3 elite | 80 / 5.3 / 66% / 1.8 | same | 0 |
| s3 boss | 100 / 9.8 / 63% / 1.6 | same | 0 |

This is expected, not a mistake: `campaignSim` builds `RUN` directly with no boons, so it never contains any of the eight protocols; it also does not call `newRun` (PROG-6) and does not use prize ransom (ECO-4). None of the three rule paths PR 433 touched is reachable there. The protocols still need the fleet measurement above.

## Exit criteria

1. **A single Epic protocol adds at most about ten points in an even fight.** Swarm Hatch breaks it: +37.7 at Epic and +24.0 at Rare. Spread Pattern is the next highest at +7.0 at Epic; Brood Harvest is +2.3 at Epic and +2.3 at Rare on its even cell; no other Epic is above +7.0.
2. **No admiral below 50% or above 90% against a sector 1 flagship.** This is a run-level check on starting fleets. I changed no game file, so it is untouched by this job; the published baseline in `contrib/opus/compute/balance_reference.md` already has grax at 36% and voice and vesh at 94% at sector 1, before PR 433. It is a pre-existing finding, not a protocol result. I did not rerun `bossmatrix`, because its starting fleets carry no boons and would not exercise the eight protocols.
3. **No crashes.** All 7,200 protocol battles and 480 campaign battles finished with 0 crashes, 0 timeouts and 0 unparseable runs.

## Recommendations

**Swarm Hatch `h_hatch`: change.** The whole-wing jump is the driver: Rare adds one launched wing to every carrier and Epic adds two, and one extra wing is worth about 24 points in this fight. Whole launched wings cannot meet a ten point bar. Keep the launched count where Common is and scale the reserve instead (the `spare` count a carrier uses to replace a lost wing):

- Common: hangar +1 (keep, unchanged).
- Rare: hangar +1, reserve +1.
- Epic: hangar +1, reserve +2.

This keeps the numeric rarity scaling and makes every tier distinct, keeps Epic from giving more launched wings than the Hunger legendary (`hangar +2`), and should land well under ten points because the board on turn one is the same as Common. It needs one new effect key (`spareWings` or similar) read where `u.spare` is set in `battle.js:1934` and in the Godot twin `godot/rules/rules.gd`, then both tables re-exported. If the Board will not add a key, the no-code fallback is to keep hangar +1 on all three tiers and scale a second stat instead (but squad hull or damage overlaps Hardened Chitin and Ravenous Wings). Do not keep +2 / +3: they measure +24 / +37.7.

**Hot Tubes `e_reload`: change for distinctness, not for power.** Rare and Epic are mechanically identical to Common today, which breaks the "every tier distinct" rule even though it cannot break a win rate. Suggested values, using keys that already exist:

- Common: `{torpCd:1}` (keep).
- Rare: `{torpCd:2, torpPct:0.10}`.
- Epic: `{torpCd:3, torpPct:0.20}`.

The cooldown itself cannot go below 1, so the added torpedo damage is what makes the tiers different in play. `torpPct` is already implemented in `battle.js:767`; it does overlap Ember's Incendiary Warheads, which is acceptable but worth a look. Also fix the description: the "current torpedoes reload sooner" sentence describes an effect that does not exist.

**The other six: keep.** Shield Wall, Chain Lightning, Brood Harvest, Marked for Death, Slip the Net and Spread Pattern are inside the exit rule. Brood Harvest also held at 35.7 / 35.0 / 36.0 in an earlier 300-battle run against a harder enemy, so its small positive delta is robust. Notes:

- Shield Wall's direct rule scales properly (0.60 / 0.55 / 0.50 covered hull cut). The fleet bot never braced in a way that changed any of the 300 battles (Common, Rare and Epic are byte-identical), so the 0.0 delta measures the bot, not the boon. A human who braces will see the scaling.
- Slip the Net also measured 0.0 because the bot moves first and fires second, so it did not fade in a way that changed any of the 300 battles. The direct rule scales (3 / 4 / 6 of 6). Epic does equal the admiral tree's full-fade capstone; that is a design overlap, not a measured power break. If the Board wants the capstone kept unique, the least disruptive change is Rare 0.7 and Epic 0.9 (still distinct and still numeric); I recommend keeping 0.5 / 0.75 / 1.0 because nothing measured breaks.
- Marked for Death's Epic +20 is often lost to the 95% hit cap. If the Board wants the top tier to feel different, give Epic a small crit or damage rider rather than a 20th point of aim. A second 300-battle run on a different enemy (Common 69.0%) gave +2.7 Rare and +3.7 Epic, which is the largest a_mark delta I saw and still inside the guide.

## How this change reaches the rest of the game

- **Callers:** no game function, constant or save field was changed. The two new files under `contrib/deepseek/tools/` call only existing entry points (`sim3d.js` generic mode; `startBattle`, `derive`, `hitChance`, `braceMul`, `fireWeapon`, `ownerFx` in the probe). Nothing in the game calls the helpers.
- **Saves:** no save field was touched, so a profile or run written before this job loads unchanged. The standing save checks (`save_fuzz`, `b1_tests`, `softlock_sweep`) pass.
- **Twins:** no rule lives in both the JS root files and the Godot port was changed, so no tables were re-exported. `oracle_copy_test` still passes. The Swarm Hatch and Hot Tubes proposals above, if accepted, must change `data.js` and `godot/rules/rules.gd` together and re-export `godot/rules/data/tables.json` and `godot/campaign/data/campaign_tables.json`.
- **UI:** no screen shows a changed value in this job. If the Swarm Hatch or Hot Tubes proposals are accepted, their descriptions (`data.js` boon text) and the Godot rule text change together.
- **CI:** no new test file was added, so `contrib/opus/tools/run_all_checks.js` did not need an entry. The two helpers are measurement tools, not tests, and are not run by CI. GitHub runs the standing pack from `.github/workflows/checks.yml`: standing checks, no em dashes in changed files, Godot rules parity, and Godot game checks. The runner adds the real rows under this report.

## Checks run

- `node contrib/opus/tools/run_all_checks.js`: every row PASS or KNOWN, no FAIL. The KNOWN rows are the nine listed `findings_tests` failures and the twelve baseline `oracle_drift_guard` differences, both present before this job.
- `node contrib/deepseek/tools/protocol_balance.js --full --n 300 --chunk 20 --conc 14`: 7,200 battles, 0 crashes.
- `SEED=777 node sim3d.js campaign 20` before and after PR 433: 240 battles per side, all 12 cells identical, delta 0.
- `node contrib/deepseek/tools/protocol_mechanics.js`: direct rule numbers in the table above.
- Em dash scan: 0 in the files written.

## What I skipped and why

- `bossmatrix` sector 1: its starting fleets carry no boons, so it cannot measure the eight protocols, and its admiral band is already published in `balance_reference.md`. The ten point rule is covered by the 7,200 fleet battles.
- `fuzz`: the 7,200 seeded battles plus 480 campaign battles already show 0 crashes, 0 timeouts.
- No game files changed, so there was nothing to re-export, no save migration to write and no UI screenshot to take.

## Files written

- `contrib/deepseek/reviews/balance_r175_protocols.md` (this report).
- `contrib/deepseek/tools/protocol_balance.js` (fleet driver, calls `sim3d.js` generic mode).
- `contrib/deepseek/tools/protocol_mechanics.js` (direct rule probe).
