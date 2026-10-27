# Campaign test record (G3)

The evidence behind "G3 campaign rules: done, with parity". Every run below can be repeated with the command next to it.
Newest first. Each row names the commit the run used and where its log lives.

## What the oracle is

- The game's own JS campaign files, pinned and unchanged except one comment fix: `godot/campaign/test/oracle/`, copied from **d8b47c6** (Oct 26 2026, stream B steps 0 to 4). See `oracle/README.md`.
- The campaign rules in Godot last changed at **ae6073b** (port of stream B step 4, oracle d8b47c6). Everything after that in `godot/campaign/` is the test harness or notes; the screens (`godot/ui/campaign/`) never change campaign state (every button calls `campaign.act()`), so map and panel work cannot move parity.
- The tables (`data/campaign_tables.json`) are exported from the oracle by `node/export_campaign.js`; every parity run first re-exports them and checks the checksum.

## Runs

| When (UTC) | Commit | Where | Check | Result | Log |
|---|---|---|---|---|---|
| Oct 27 | 9711a7e | Ryan's PC (RTX 5080), lane A job `queue\g3_r51i_9711a7e.bat` | `tools\pc\parity_campaign.bat`, 30 seeded runs | **PASS, 30 of 30** (tables PASS; same step counts as the cloud run, seed by seed) | `voidsworn_test\shots\g3_r51i_9711a7e\parity_campaign_log.txt`, copied to `docs/shots/g3_campaign/9711a7e/` |
| Oct 27 | 9711a7e (rules as at ae6073b) | cloud sandbox, Godot 4.7.2 Linux headless | `run_parity_campaign.sh 1 30` | **PASS, 30 of 30** (tables PASS; seeds 1 to 30, 10 to 239 steps each) | below |
| Oct 27 | 9711a7e | cloud | `run_nem_scenarios.sh` | **PASS** (64 records identical) | below |
| Oct 27 | 9711a7e | cloud | `save_test.gd` | **PASS** | below |
| Oct 27 | 9711a7e | cloud | `arc_hook_test.gd` | **PASS** | below |
| Oct 27 | 9711a7e | cloud | headless bot through every screen, `campaign.tscn -- bot 2` | 2 runs ended, 0 campaign errors (one story.gd error at the time, fixed by Opus in e08b871) | |
| Oct 27 | 9ef9b85 | cloud | `run_parity_campaign.sh 1 6` | **PASS, 6 of 6** | session log only |
| Oct 26 | ae6073b (oracle d8b47c6) | cloud | `run_parity_campaign.sh` 60 seeds, Nemesis scenarios | **PASS, 60 of 60**; Nemesis scenarios 64 records identical (commit message) | commit message |
| Oct 26 | 06b96d7 (oracle c88567c) | cloud | `run_parity_campaign.sh` 60 seeds | **PASS, 60 of 60** (commit message) | commit message |
| Oct 26 | c4face2 (first port) | cloud | 60 seeds | **PASS, 60 of 60** (commit message) | commit message |
| Oct 26 08:36 | 41f2eb2 (oracle c7b1a78, before the Nemesis v2 port) | Ryan's PC, job `g3_parity_41f2eb2.bat` | `parity_campaign.bat`, 30 seeded runs | **PASS, 30 of 30** | `voidsworn_test\queue\logs\g3_parity_41f2eb2.bat.log` |

### Cloud parity, Oct 27, 30 seeds (verbatim)

```
  tables: PASS (match the pinned oracle)
  seed 1: PASS: 178 steps identical, ended with "end"
  seed 2: PASS: 215 steps identical, ended with "end"
  seed 3: PASS: 212 steps identical, ended with "end"
  seed 4: PASS: 159 steps identical, ended with "end"
  seed 5: PASS: 190 steps identical, ended with "end"
  seed 6: PASS: 239 steps identical, ended with "end"
  seed 7: PASS: 28 steps identical, ended with "end"
  seed 8: PASS: 190 steps identical, ended with "end"
  seed 9: PASS: 189 steps identical, ended with "end"
  seed 10: PASS: 143 steps identical, ended with "end"
  seed 11: PASS: 20 steps identical, ended with "end"
  seed 12: PASS: 43 steps identical, ended with "end"
  seed 13: PASS: 42 steps identical, ended with "end"
  seed 14: PASS: 218 steps identical, ended with "end"
  seed 15: PASS: 226 steps identical, ended with "end"
  seed 16: PASS: 160 steps identical, ended with "end"
  seed 17: PASS: 167 steps identical, ended with "end"
  seed 18: PASS: 203 steps identical, ended with "end"
  seed 19: PASS: 215 steps identical, ended with "end"
  seed 20: PASS: 209 steps identical, ended with "end"
  seed 21: PASS: 225 steps identical, ended with "end"
  seed 22: PASS: 218 steps identical, ended with "end"
  seed 23: PASS: 174 steps identical, ended with "end"
  seed 24: PASS: 10 steps identical, ended with "end"
  seed 25: PASS: 183 steps identical, ended with "end"
  seed 26: PASS: 235 steps identical, ended with "end"
  seed 27: PASS: 13 steps identical, ended with "end"
  seed 28: PASS: 200 steps identical, ended with "end"
  seed 29: PASS: 215 steps identical, ended with "end"
  seed 30: PASS: 84 steps identical, ended with "end"
PASS: the Godot campaign matches the game on all 30 seeded runs.
```

The short runs (7, 11, 12, 13, 24, 27) are runs the scripted player abandons or loses early; they still check the title, admiral, aspect, intro and first fights.

## Scenarios

### Parity runs (seeds 1 to 30)

Each seed is a whole run, title screen to the end screen, played by the same scripted player in the JS game and in Godot. After every click both sides write the buttons on screen, the PRNG state and the full campaign state (run, map, profile, screen transients, the saved copy); `node/compare_campaign.js` names the first step and field that differ, with no tolerance (exact doubles). The player also reloads the page now and then (save, load, continue).

What the 24-seed set exercised (`node node/coverage.js`): 3873 steps; 16 runs won, 8 lost or abandoned; deepest sector S1 5, S2 0, S3 19. Clicks: enterNode 426, takePerk 355, prizeSet 264, battle 221 (win 192, partial 21, loss 8), takeSalvage 212 (credits 144, refit 68), closeModal 168, equip 135, prizeConfirm 120, prizeStep 120, takeBoon 118, sellShip 112, takeRelic 103, upgradeMk 100, leaveYard 96, salvageStep 91, continueRun 89, buyHull 83, buyMod 78, sellConfirm 51, buyTrack 49, reload 47, unequip 44, saveQuit 42, backMap 39, progTab 39, yardFleet 39, boonDecline 36, eventChoice 36, fleetScreen 36, pickFaction 36, factionVerb 34, repair 33, boonReroll 32, buyVariant 32, newRunScreen 32, title 30, repairAll 28, pickAdmiral 26, end 24, legacy 24, pickAspect 24, start 24, startRun 24, takeMod 21, optHeat 14, c3retreat 12 (yes 6, no 6), fleetFromModal 6, help 6, optAlt 6, optCmd 6.

### Nemesis scenarios (`run_nem_scenarios.sh`, 64 records)

1. Deathless: a sector II kill scars him; the first sector III kill brings him back once; the second kills him and unlocks the arc hull.
2. Corsair: 10 credits and a crippled ship; a full clock tows her; he flees and keeps her; killed in sector III he gives her and the loot back; the tithe with 200 credits.
3. Ithar: he flees: honed, no riches; his battle config.
4. Chorus: feeding and its cap; a loss with your flagship dead; fast adaptation with its reason; his battle config.
5. Voidsworn: beaten with lances, his next adaptation is the counter.
6. Weaknesses found in battle merge (duplicates and unknown ids dropped); pronouns for a she and an it.
7. Every faction's warning line at a full clock, and the tithe.

### Other checks

- `save_test.gd`: atomic writes (tmp file, size check, rename), the backup one save behind, a damaged save falling back to the backup.
- `arc_hook_test.gd`: the story arc hook off, on with no arc file, and on with a test card (a run with the flag off or with no arc file is identical step by step).

## Files in godot/campaign/ (Oct 27, 9711a7e; bytes)

| File | Bytes | What |
|---|---|---|
| `campaign.gd` | 150939 | the campaign rules and screen flow |
| `data/campaign_tables.json` | 134414 | every table, exported from the oracle |
| `README.md` | about 16000 | how it works, the map look, saves, parity |
| `test/README.md` | 3892 | the parity record format |
| `test/RECORD.md` | | this file |
| `test/parity_campaign.gd` | 8555 | the Godot side of parity |
| `test/run_parity_campaign.sh` | 1959 | cloud parity runner |
| `test/nem_scenarios.gd` | 3609 | Nemesis scenarios, Godot side |
| `test/run_nem_scenarios.sh` | 844 | Nemesis scenarios runner |
| `test/save_test.gd` | 1798 | saves |
| `test/arc_hook_test.gd` | 5429 | the story arc hook |
| `test/node/env.js` | 4059 | loads the oracle headless |
| `test/node/golden_campaign.js` | 11792 | the JS side of parity |
| `test/node/compare_campaign.js` | 3072 | the comparer |
| `test/node/export_campaign.js` | 5369 | the table exporter |
| `test/node/coverage.js` | 1669 | what the runs exercised |
| `test/node/nem_scenarios.js` | 4230 | Nemesis scenarios, JS side |
| `test/oracle/*.js` | 551318 in all | the pinned JS game files (battle, campaign3d, campaign_meta, campaign_run, core, data, ui3d) and their README |

The screens live in `godot/ui/campaign/` (campaign_ui.gd, map3d.gd, map3d_system.gd, map3d_props.gd, map3d_shaders.gd, map_intel.gd, choice_button.gd, fonts/) and the test scenes in `godot/scenes/campaign/` (campaign.tscn with the `shots`, `mapshots` and `bot` modes, map3d_probe.tscn, stops_probe.tscn).
