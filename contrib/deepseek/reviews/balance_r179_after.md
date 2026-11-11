# Issue 448: the three protocol values after the R179 ruling

Workhorse: DeepSeek. Branch `work/issue-448-deepseek`. 2026-11-10.
This job changes only the three protocols the Board ruled on. Nothing on screen changes except their descriptions, so there are no screenshots.

## Answer first

The three protocols now carry exactly the R179 values in both twins and in their descriptions. Swarm Hatch no longer breaks the ten point guide: measured against Common it adds +2.7 points at Rare and +7.3 at Epic (was +24.0 and +37.7). Hot Tubes is now distinct at every tier through torpedo damage, not reload, and measures inside noise. Slip the Net still measures 0.0 because the bot never keeps movement to spend after firing, so only the direct rule probe shows its change.

Re-measure, same fleets and seeds as the issue 443 report, 300 battles per cell:

| Protocol | Common win | Rare win | Epic win | Rare delta | Epic delta |
|---|---|---|---|---|---|
| Swarm Hatch `h_hatch` | 53.7% | 56.3% | 61.0% | +2.7 | +7.3 |
| Hot Tubes `e_reload` | 59.0% | 56.0% | 60.0% | -3.0 | +1.0 |
| Slip the Net `r_slip` | 59.3% | 59.3% | 59.3% | +0.0 | +0.0 |

Cell standard error 2.8 to 2.9 points, delta standard error about 4.0. A delta under about 8 points is inside two standard errors. Common win rates match the earlier report exactly (53.7, 59.0, 59.3), so the same seeds were used.

Direct rule probes, calling the game's own functions:

| Value | Common | Rare | Epic |
|---|---|---|---|
| Swarm Hatch: carrier spare wings (`u.spare`, reliquary) | 3 | 4 | 5 |
| Hot Tubes: torpedo cooldown the game builds | 1 | 1 | 1 |
| Hot Tubes: `torpPct` stored | 0 | 0.10 | 0.20 |
| Slip the Net: movement kept after firing, out of 6 | 3 | 4 | 5 |

## What changed

- `data.js`: `h_hatch`, `e_reload` and `r_slip` text and `fx(m)`. No other protocol touched.
- `core.js`: `FX_CAPS` gains `spareWings: 2`.
- `battle.js`: the battle-start spare count in `deployWings` adds `fx.spareWings` on the normal branch only. The sector flagship branch and the Endless Swarm `endless` 99 branch are unchanged.
- `godot/rules/rules.gd`: the same three `boon_fx` entries, plus the same `spareWings` term in `deployWings`.
- `godot/rules/data/tables.json` and `godot/campaign/data/campaign_tables.json`: re-exported from the root files.

## How the change reaches the rest of the game

- **Callers:** searched the whole repo for `spareWings`, `torpPct`, `torpCd` and `fade`. The new key is read only in `battle.js` `deployWings` and its `rules.gd` twin; `FX_CAPS` clamps it everywhere through `sumFx`/`derive`. No other caller, constant or save field was changed.
- **Saves:** old saves store boons as `{id, r}`; `fleetFxList` and `BOON_FX` recompute `fx` from id and rarity, so a profile or run written before this change loads and behaves with the new values and needs no migration. Checked the load paths in `core.js` and `godot/campaign/campaign.gd`, and `save_fuzz`, `b1_tests` and `softlock_sweep` pass.
- **Twins:** both sides changed and both tables re-exported. `oracle_copy_test` passes and both rules parity and campaign parity pass. I also ran a custom scenario with `h_hatch` at Epic, `e_reload` at Rare and `r_slip` at Epic through both twins: 259 activation records identical.
- **UI:** every boon card reads the description from `BOONS[id].d` in the JS and from `BOON_D` in the campaign tables in Godot. Both were re-exported, so the three texts update together. No screen shows the raw `fx` numbers.
- **CI:** no new test file, so `run_all_checks.js` needs no new entry. GitHub runs the standing checks, the no em dashes check, Godot rules parity and Godot game checks.

## Checks run

- `node contrib/opus/tools/run_all_checks.js`: every row PASS or KNOWN, no FAIL. The KNOWN rows are the seven listed `findings_tests` failures (KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5) and the twelve baseline `oracle_drift_guard` differences, both present before this job.
- `PASS RWD-2 rarity multiplier scales every core protocol`
- `PASS: 227 sum fixtures, 4 derive fixtures, all effect kinds covered and single effects unchanged.`
- `PASS: no oracle folders exist and both committed tables equal a fresh export from the root game files`
- `cmd.exe //c "tools\\pc\\parity.bat nopause"`: `PASS: the Godot port matches the game's rules exactly.` (all 271 seeded scenarios), `PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.`
- Extra twin check with `h_hatch` r2, `e_reload` r1 and `r_slip` r2: `259 records identical (state hash and PRNG state after every action, activation and round), result: end win`
- Re-measure, 2,700 battles (three protocols, three rarities, 300 per cell), 0 crashes, 0 timeouts.
- Em dash scan: 0 in the changed game files and this report.

## What I skipped and why

- I did not re-run the full 24-cell eight-protocol matrix. The Board ruled only these three and the other five are untouched, so re-measuring them would only repeat the issue 443 numbers.
- `i_wall`, `s_chain`, `h_brood`, `a_mark` and `e_spread` are unchanged, and Slip the Net's fleet cell is bot-blind as before; the direct probe covers its rule.

## Measurement note

The driver is the issue 443 report's `contrib/deepseek/tools/protocol_balance.js` (PR 447, head 0506450), run unchanged from a temp copy so it stays out of this diff. Command: `node protocol_balance.js --full --protocol <id> --n 300 --chunk 20 --conc 14`, default seed base 100000, the same fleets and seed set (100000 to 210866) as the earlier run.
