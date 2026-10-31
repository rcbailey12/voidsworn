# Current-source acceptance and campaign repair

Source main: **355a2ac70860db4446f040a5787b19c2d746d779**, following PR #1 **4651c690**. All work remains under Contrib. Runtime/main, player saves and the cutover baseline remain unchanged.

The live browser campaign could throw on its first battle because a line comment swallowed `prepBattle()` and the declaration of `setupMs`. Its older vendored campaign oracle kept the statements active, masking the bug. The new candidate restores those two statements, then re-pins all seven campaign oracle files and regenerates the entire campaign table export from the combined repaired browser source. It does not invent new balance or content rules.

## Verified work

- Randomized current-source rules sweep: **200 / 200 battles, 36,462 exact state and PRNG records, zero differences**. Both engines execute the same complete sequence, with the earlier repairs and battle refresh in place.
- Current-source campaign/save-reload parity: **30 seeds, 4,520 exact records, 55 reloads**. The strengthened comparator reconstructs and compares every captured state part, verifies the stored hashes and requires contiguous steps and a successful terminal marker. Its nine adversarial cases pass. The existing campaign harness deliberately uses stub battles and excludes telemetry and rendered UI.
- Actual native campaign integration: **all six factions reach run end through 42 real battles**, with real battle API results passed through `finish_battle` into rewards and progression. No stub battle outcomes are used in this smoke. It is API-level integration, not a JS parity comparison, play-balance forecast or rendered scene test.
- Current native threading and hard-stop checks: the s4 and s23 battles finish identically with enemy work on a worker thread while the main thread reads the API. The intentional NOT PORTED and invalid-config probes halt and block commands as required.
- Focused battle-entry control: unchanged browser source reproduces `ReferenceError: setupMs is not defined`; the candidate initializes four real rule units, calls the presentation preparation once and records finite setup time.
- Campaign table refresh: **352 changed leaves across 45 tables**, including existing current-game tuning and current names. The 51 hull prices, all 102 `cost`/`cost0` fields, `FAC_PRICE` and `BOON_NEED` are preserved exactly relative to the preceding repaired packet.
- Optional Saro remains compatible after the full campaign re-pin: see `evidence/saro_compatibility.json` for 707 model/fitting and 96 pilot comparisons, including zero native fitting differences.

The 200-battle sweep's complete result is in **`evidence/sweep_summary.json`**. While a run is in progress its status is INCOMPLETE; only a successful complete comparison changes it to PASS. Its input is filed in `evidence/sweep_scenarios.json`. Each engine executes one identical 200-battle sequence; no scenario, state field, log text or numeric difference is filtered out. `end none` records are explicit round limits, not wins.

## Adopt without stacking old copies

1. Existing `../pre_opus/patches/integration.patch`.
2. `../finalization/patches/campaign_hulls_after_integration.patch`.
3. `../finalization/patches/battle_refresh.patch`.
4. **`patches/campaign_current.patch`**, this packet's full campaign re-pin and battle-entry repair.
5. Optional existing `../pre_opus/patches/saro.patch`, using its small hunks. Historical Saro full-file copies do not contain these refreshes.

`patches/campaign_manifest.json` names the base and resulting hashes. Full candidate copies are under `candidates/current_campaign/` to satisfy the repository's contribution rule; review the one-line browser statement fix and generated semantic table deltas before adopting them. Do not overwrite later main wholesale.

The proposed gate adapter from the preceding finalization packet remains available. No gate baseline is refreshed here, and 64 remaining ledger failures do not become either confirmed defects or accepted release exceptions through these checks.

## Windows and graphics execution

**NOT RUN.** No PC staging/commit bridge is exposed in this session, and plugin discovery found no relevant PC/Blender integration. This Linux environment has no Windows/PowerShell runtime, Blender runtime or GPU device. A cloud attempt to locate an installable `bpy` distribution returned no matching distribution. These limits do not establish anything about the state of Ryan's PC.

The existing Windows export job has a separate fail-open problem: it ignores timeout-wrapper return codes after import/export/package validation/smoke and ends with exit 0. **`candidates/pc_export/tools/pc/jobs/g2_export.bat`** is a full-copy candidate that stops on those failures and rejects a missing output executable. It preserves the existing export/template-download behavior and does not delete an earlier build. Its Windows execution is unverified. `NOTES.md` gives the exact changed behavior.

For automated checks on a Windows LF checkout, double-click **`pc/run_acceptance.bat`** or drag Godot onto it. Node, Git and Godot are required. This launcher runs isolated candidate checks; it does not install runtime patches, stage a watcher job or perform graphics acceptance. Its orchestration is syntax-checked here and constituent checks were executed individually.

The remaining machine steps are the existing Blender fixture and actual Pyre-Barge QA, production-material/mount inspection, Windows export/launch, roughly 20-ship GPU measurement, and the rendered phased-battle interaction capture. Follow `../finalization/PC_ACCEPTANCE.md` and the watcher staging rules in `HANDOFF.md`. No screenshots or timing numbers are fabricated from the headless checks.

## Reproduce individual checks

```sh
node contrib/codex/acceptance/tools/run_campaign.js --godot /path/to/godot
node contrib/codex/acceptance/tools/check_campaign_patch.js
node contrib/codex/acceptance/tools/entry_checks.js
node contrib/codex/acceptance/tools/campaign_comparator_checks.js
node contrib/codex/acceptance/tools/run_threads.js --godot /path/to/godot
node contrib/codex/acceptance/tools/run_real_campaigns.js --godot /path/to/godot
node contrib/codex/acceptance/tools/check_saro_current.js --godot /path/to/godot
node contrib/codex/acceptance/tools/run_sweep.js --godot /path/to/godot
```

The campaign preparation command creates isolated temporary projects and refreshes owned Contrib candidates. Run campaign preparation before the checks that consume `evidence/campaign_preparation.json`. No command writes the player's native save. The aggregate command is `tools/run_all.js --godot /path/to/godot`; Windows/Blender/GPU acceptance remains a separate outcome even if every automated check passes.

R33 shipping intent remains a distinct decision. The located fresh-save plan default, later importer audit and reference converter are documented in `../finalization/R33_BOUNDARY.md`. This packet does not authorize a browser-save wipe, import, testing-grant strip or cloud overwrite.
