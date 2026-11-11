# Issue 456: remove harness detection from the newRun ownership gate

## What changed

- `core.js` `newRun`: deleted the Node `process` check (`nodeHarness`). An unowned admiral now always refuses, so the gate is live in every Node harness too.
- `godot/campaign/campaign.gd` `newRun`: deleted `scriptHarness()` and its `--script` check. The function is gone. An unowned admiral now always refuses.
- Every harness that used the escape and flies an admiral it does not own now grants that ownership in its own setup, through `META.admirals[id] = true` (the same field the purchase path writes). No `opt.fixture` escape was added, because every caller can own its admiral.
- `campaign_run.js` needed no edit: it has no `newRun` and no gate. The gate lives in `core.js`; the UI path `ACT.startRun` in `campaign_meta.js` and `ACT_startRun` in `campaign.gd` already checked `admiralOwned` before calling `newRun`.

Harness setup edits:

- JS: `contrib/opus/tools/b4_tests.js`, `capstone_mastery_tests.js`, `heat_tests.js`, `inheritance_tests.js`, `progression_telemetry_test.js`, `shadow_xp_tests.js`, `story_beat3_tests.js`, `tree_handoff_test.js`, `tree_table_walk_test.js`; `contrib/muse/tools/montecarlo/driver.js`; `sim3d.js`; `cmdshot.py`; `yardcheck.py`.
- Godot: `godot/campaign/test/capstone_mastery_test.gd`, `heat_test.gd`, `inheritance_test.gd`, `shadow_xp_test.gd`, `story_beat3_test.gd`, `tree_handoff_test.gd`.

## Caller list and what each now does

Game and UI callers, unchanged and already gated:

- `campaign_meta.js` `ACT.startRun`: checks `admiralOwned(pickedAdmiral)` before `newRun`; picks only owned admirals.
- `main3d.js` wrapper: forwards to `newRun` with `teachingGate`; the caller comes through the owned UI path.
- `campaign.gd` `ACT_startRun`: checks `admiralOwned(picked_admiral)` before `newRun`; `admiralScreen` picks an owned admiral.

Harnesses that now grant ownership before starting:

- `b4_tests.js` `fresh()`: every faction and every named admiral uses `META.admirals[pick] = true` first. Covers `ashgrove` and the every-admiral start fleet walk.
- `heat_tests.js`: grants `vaelen` after each `defaultMeta()` reset (four setups).
- `capstone_mastery_tests.js`: grants `vaelen` before both real runs.
- `shadow_xp_tests.js`: grants `vaelen` before the first run; vex stays the free starter.
- `inheritance_tests.js`: grants `flown` in each fixture loop (vaelen, or vex for empty).
- `progression_telemetry_test.js`: grants `vaelen` before the batch.
- `tree_handoff_test.js`: grants the one admiral per faction before `newRun`.
- `tree_table_walk_test.js`: grants each row's admiral before `newRun` (281 rows).
- `story_beat3_tests.js`: its `start()` owns the admiral it flies before `newRun`.
- `sim3d.js` rule check: grants `reyes` for the alternate-fleet check and `sekhmar` for the mastery check.
- `contrib/muse/tools/montecarlo/driver.js`: grants `cfg.admiral` in both `mcRunOne` and `mcSampleBoons`.
- `cmdshot.py`: grants `reyes`.
- `yardcheck.py`: grants its six capture admirals (`aelith`, `matriarch`, `reyes`, `mott`, `nekhet`, `vex`).
- Godot `capstone_mastery_test.gd`: grants `vaelen` after both fresh `defaultMeta()` resets.
- Godot `heat_test.gd`: grants `vaelen` after each fresh `defaultMeta()` reset.
- Godot `shadow_xp_test.gd`: grants `vaelen` after tables load.
- Godot `inheritance_test.gd`: grants each fixture's `flown` admiral.
- Godot `story_beat3_test.gd`: grants each admiral before all four run starts.
- Godot `tree_handoff_test.gd`: grants the one admiral per faction before `newRun`.

Callers that needed no ownership grant:

- `free_exit_tests.js` and `free_exit_test.gd`: each faction's first admiral costs 0, so `admiralOwned` is already true.
- `lineage_tests.js` / `lineage_test.gd`: already owns `vaelen`.
- `campaign_start_test.js`, `core_sync_tests.js` / `core_sync_test.gd`, `nem_assign_enum.js`, `recapshot.py`, `tools/test_onboarding_gate.js`, `debrief_mock_shots.gd`, `onboarding_test.gd`: use `vex`, the free starter.
- Nemesis tests (`nemesis_121`, `122`, `395`, `teach`): `pickAdm` returns each faction's cost-0 first admiral.
- Scene probes and UI shot scripts: start through the campaign buttons, which pick an owned admiral.
- `findings_tests.js` PROG-6: intentionally keeps `malek` unowned and now proves the real gate refuses the launch.

## Checks run

Standing checks, `node contrib/opus/tools/run_all_checks.js`:

```
b1_tests | PASS
b3_tests | PASS
b4_tests | PASS
backlog_tests | PASS
campaign_start_test | PASS
capstone_mastery_tests | PASS
checks_truth_tests | PASS
core_sync_tests | PASS
doc_check_tests | PASS
effect_caps_tests | PASS
free_exit_tests | PASS
fx_death_spawn_tests | PASS
heat_tests | PASS
inheritance_tests | PASS
ion_tests | PASS
lineage_tests | PASS
nemesis_121_tests | PASS
nemesis_122_tests | PASS
nemesis_395_tests | PASS
nemesis_clash_tests | PASS
nemesis_teach_tests | PASS
r1_tests | PASS
shadow_xp_tests | PASS
squadron_auto_tests | PASS
story_beat3_tests | PASS
ui_spec_tests | PASS
progression_telemetry_test | PASS
tree_effects_test | PASS
tree_handoff_test | PASS
tree_table_walk_test | PASS
oracle_copy_test | PASS
nem_assign_enum | PASS
nem_direct_reads_report | PASS
naming_lint_game.test | PASS
naming_lint_game | PASS
checks | PASS
fleet_invariants | PASS
save_fuzz | PASS
softlock_sweep | PASS
table_xref | PASS
findings_tests | KNOWN: 7 listed failure(s): KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5
oracle_drift_guard | KNOWN: 12 constant difference(s) within the baseline
fixture_check | PASS
```

Findings PROG-6 line:

```
PASS PROG-6 an unowned admiral cannot be launched
```

Rules parity and campaign parity, `cmd.exe //c "tools\\pc\\parity.bat nopause"`:

```
  seed 1001: PASS
  seed 7: PASS
  seed 4242424242: PASS
  PASS (math)
  battle ...: PASS (every scenario line)
  threat map s4: PASS
  threat map s19: PASS
  threat map s23: PASS
thread test s4: PASS (over after round 6, 958 events, 59 reads during enemy steps on a worker)
thread test s23: PASS (over after round 11, 1998 events, 111 reads during enemy steps on a worker)
PASS: the Godot port matches the game's rules exactly.
[1/4] Campaign tables still match the root JS files... PASS
  run 1: PASS ... run 30: PASS
  PASS (cross-twin save hand-off)
PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.
```

Nemesis scenarios, `GODOT=... sh godot/campaign/test/run_nem_scenarios.sh`:

```
PASS: Nemesis scenarios identical (219 records)
Nemesis read: PASS
Map read-only: PASS (42 checks)
```

Bot battle, `godot --headless --path godot --script res://tools/ci/bot_battle.gd -- --seed 359`:

```
bot battle: seed 359, voidsworn run as vex, 4 clicks to the first battle (battle against corsair, node 0-0)
bot battle: result win after 3 rounds, 3 enemy ships destroyed, 0 of ours lost
bot battle: PASS
```

Godot checks rerun one by one (same scripts GitHub runs):

```
PASS: capstone mastery opens at 320, 440 and 600 XP only after the level 8 evolution, and shows its effect.
PASS: Heat opens after the first loss and pays 2 XP per point to the flown line and 1 to the shadow pool.
PASS: every faction's XP, tiers, locks, capstones, saves and per-line resets.
PASS: shadow XP, debrief heirs, saves and exact browser overflow parity.
PASS: inheritance receipts match browser payouts and resulting profiles on all end paths.
PASS: 32 free exits match the live browser at entry, result and sector map.
PASS: core sync announcements and inheritance match browser fixtures.
PASS: beat 3 screens, all five rewards, exact damage, round 1 sync, free core offers, reloads, all battle kinds and win/loss/retreat expiry.
PASS: real campaign picks reach the battle for all six factions (four skills each), each run saved with saveRun and read back through load_save_text before the battle
playtest switch: PASS
ONBOARDING PASS
```

## The five reach checks

- Callers: searched the whole repo for `newRun`, `scriptHarness`, and `admiralOwned`. Every `newRun` caller is in the list above; every unowned-admiral caller now owns its admiral in setup, and the UI callers already gated. No `scriptHarness` or Node process check remains.
- Saves: no save field was added or changed. `admiralOwned` still reads the same `META.admirals` field the purchase path writes, so old profiles load as before. Checked with `save_fuzz` PASS, the lineage save round trip (PASS), inheritance fixtures from old metas (PASS), shadow save round trip (PASS), and the campaign parity cross-twin save hand-off (PASS). A run saved before this change continues to load; only starting a new run with an unowned admiral is refused, which was already the product rule.
- Twins: the change is on both sides (`core.js` and `godot/campaign/campaign.gd`). Random draws did not move: rules parity and campaign parity both PASS on every seed and battle. Both tables were re-exported by the parity runners and `node contrib/opus/tools/oracle_copy_test.js` was run last and PASSed.
- UI: no screen shows a new value. The campaign admiral screen, launch button, purchase path, and Godot `admiralScreen` already read ownership through `admiralOwned`; no UI file passes a test-only option because none was added.
- CI: no new test file was added, so `contrib/opus/tools/run_all_checks.js` needed no list change. GitHub runs the standing checks (including findings PROG-6), rules parity, campaign parity, tree hand-off, Nemesis scenarios, the Godot game check list and the bot battle; all are green above.

## Skipped

- No screenshots: the job's "what Ryan will see" is nothing, and no screen or visual value changed. The shots folder was created and left empty.
- No new Godot-only refusal test was added because the done-when names findings PROG-6 as the gate proof. All Godot runs now pass through the live gate, and only the admirals each harness owns are launched.
