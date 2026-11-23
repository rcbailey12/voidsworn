# Codex (audit): November 22 merges

Refs #1723. Reviewed main `fedabee80d8f24c8c732b32612fcc9264b28529c`. All 13 PRs were present at the start. The runner checkout and `origin/main` have the same Git tree. File and line references below use that tree.

The Board has three blocking findings to file. A planned target can consume Enter without firing, the bottom ship sheet can return during the final volley, and an acid-killed fighter emits the smoke the death rules suppress.

## Findings on main

| # | Finding | Evidence | File:line | Exact quote | Why it matters | Proposed fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | **BLOCKING** (1643). Enter can accept a target and fire nothing. | OBSERVED | `godot/scenes/battle/battle.gd:4603` | `if st == null and rot == 0 and picks.is_empty():` | Plan a move that takes an enemy out of the selected gun's arc while it is still in arc from the real ship. Clicking the enemy clears the ghost at 4470. At 4555 the real-position check saves the target alone. In the battle probe, gun 0 on x04 selected x07 with an empty plan and no picks. Enter left the rules unchanged and queued zero batches. | Keep the ghost on refusal, or record the real-position shot as an explicit replacement pick. Test this click followed by Enter. | High |
| 2 | **BLOCKING** (1709, 1643). The ship sheet can cover the battle's final volley. | OBSERVED | `godot/scenes/battle/battle.gd:5506` | `busy and not ended and api.phase != "over"` | The rules resolve the command before its animation (1014-1025). The rules API sets the phase to over when it emits the end event. The runner waits for the batch before opening the end screen (970-985). In the real HUD with that finishing state supplied, the sheet still occupied its click-blocking rectangle while playback was busy. This contradicts the promise for every event in screens.md:119. | Let playback own sheet visibility until the event finishes. Cover a winning command as well as an ordinary move. | High |
| 3 | **BLOCKING** (1646, 1666). An acid-killed strike craft still emits the smoky corkscrew. | OBSERVED | `godot/fx/fx_death.gd:2267` | `return _wing_death(fx, s)` | The squadron returns one line before the melt flag is set. The wing calls the new corkscrew at 2369, whose smoke guard reads that flag. A headless acid-killed Navy fighter emitted six smoke sprites on the death call. The playbook excludes smoke from acid deaths at deaths_and_hits.md:233. | Pass the kill cause through the wing path before scheduling either the corkscrew or the delayed smoke puff. Add an acid-killed metal wing to the death fixture. | High |
| 4 | **SHOULD-FIX** (1698, 1714). Changed geometry or embedded paint can keep the old installed scene. | OBSERVED | `godot/render/build_assets.gd:379` | `sources[file_name] = [FileAccess.get_modified_time(glb), file.get_length()]` | The new hash covers external maps only. Two valid 384-byte GLBs with different vertex positions and the same timestamp gave the identical production stamp. The builder's warm-cache test at 352-357 and the install readback both accept that stamp. The same gap applies to damage and wreck GLBs. | Include GLB contents in the stamp and use a changed vertex or embedded image in the install readback test. | High |
| 5 | **SHOULD-FIX** (1666). Squadron debris still uses hot metal on flesh and glass. | OBSERVED | `godot/fx/fx_death_beats.gd:350` | `fx.shd(p, fx.now, 1.2,` | The ordinary wing corkscrew calls the default shard twice with heat 0.4. The next line colours the streak, leaving the shard on its default metal tint. Main already supplies a faction-aware debris helper at 173-182 for the larger hulls. A Chorus spore has a real roster entry. | Use the existing debris helper for wing flecks. Check the emitted particle kind and tint on Chorus and Glasswright wings. | High |
| 6 | **SHOULD-FIX** (1631, 1699, 1719). Metal wear still darkens damaged glass and flesh. | OBSERVED | `godot/fx/fx_ship.gd:1536` | `HULL.set_wear(entry[1], hull_wear, patches)` | A fall below the wear threshold can now create damage surfaces even before a breach (1510-1522). Every eligible hull then gets the same weather and scorch uniforms. The shader multiplies hull colour by both at fx_hull.gd:338. The material rule in deaths_and_hits.md:366-368 reserves soot and wear patches for metal. | In the R402 material work, select plating weather and scorch by hull material, keeping the separate electrical dip for all eligible ships. | High |
| 7 | **SHOULD-FIX** (1714, 1698). A timed refresh can repeatedly miss the same ships. | INFERRED | `godot/render/build_assets.gd:340` | `for code in da.get_directories():` | The time check breaks the loop at 347-349. Each retry hashes external maps in the same directory prefix before testing whether a ship is current (351-356, 386). If that prefix takes the entire allowance, later repaints can remain stale on every retry. The Windows play launcher gives it 120 seconds. This is the outstanding retry case also identified in the Fable review. | Resume at the first unexamined ship. Test two bounded runs with a stale ship late in the directory order. | High on the retry path |
| 8 | **SHOULD-FIX** (1706). A clean prompt in a dirty checkout can trigger a Godot failure from an earlier turn. | INFERRED | `.claude/hooks/guard.cjs:409` | `git(root, ['diff', '--name-only', '--no-renames', '-z', start, '--', 'godot']),` | The prompt records only HEAD at 398. Stop compares the worktree to that commit and adds all untracked Godot files. A pre-existing broken script therefore enters the check even if this turn only reads docs. The clean-turn fixture starts from a clean checkout. | Record the starting state of already-dirty Godot paths and compare it at Stop. Keep coverage for a script edited and committed within the turn. | High |
| 9 | **NOTE** (1715). Extra rockets can hide a missing launch in the flat-flight check. | OBSERVED | `godot/fx/test/torpedo_flat_flight_check.gd:53` | `check(checked >= 18,` | The six launch cases each use three targets. A rocket case emits four rounds for each target, so a healthy run counts 27. Lose the entire three-target star case and 24 still clears the threshold. The 41 height samples check only projectiles that exist. | Assert the expected count inside each launch case before sampling its trajectory. | High |
| 10 | **NOTE** (1646, 1666). The death test misses smoke emitted on the death frame. | OBSERVED | `godot/fx/test/death_variety_1586_check.gd:286` | `var spr0 := _kinds(fx)` | The fixture calls fx.death at 283 and only then samples its starting counters. On the acid-wing probe it saw six smoke sprites in both samples and reported zero. A new smoke burst during the death call would also escape the cruiser assertions. | Sample the counters before fx.death and keep the current per-kind deltas through the end of the effect. | High |

## What each merged PR does on main

**PR 1631, Live hull wounds** (`50241fef1`). The nozzle split, stage transition and turret jam use the ship's section state. The new pre-breach material path also carries wear (finding 6). PR 1731 already routes the blowout through faction debris.

Not checked: No installed-hull footage of a wound opening or a turret repairing.

**PR 1646, Acid cook-off** (`f30ed2576`). On a non-squadron metal hull the melt marker suppresses smoke, and the cook-off temporarily selects faction colours. The wing dispatch bypasses that marker (finding 3).

Not checked: No camera comparison of blast colour, wreck heat or plume size.

**PR 1666, Death variety** (`d5669056b`). The ram and boarding marks are matched to the dying unit within the action batch. The later ram cone and faction-debris fixes are in main. The separate wing branch still matters (findings 3, 5 and 10).

Not checked: No timed multi-kill scene, sound playback or GPU measurement.

**PR 1699, Wave 1A hits** (`3721c12a4`). A shield-only ion, lance or crit is filtered before transient light dips and engine stutter. The marker and ring remain outside the reacting hull pivot. Reduced hit impulse still moves a shielded hull.

Not checked: No listening comparison or measured camera-distance visibility for recoil and misses.

**PR 1719, One brownout path** (`68381fc49`). The hit dip and wound flicker multiply on fx_flick. The permanent wear uses fx_power. The subsequent death-material fix at fx_death.gd:2516 resets the copied flicker. Revive restores the view's saved hull poses and materials.

Not checked: No rendered comparison of a dip immediately followed by death or revival.

**PR 1709, Hide the bottom sheet** (`2b36f6e2e`). Ledger layout returns before adding the shelf blocker during ordinary playback. The rules phase ends sooner than the last batch finishes, exposing the shelf in that interval (finding 2).

Not checked: No visual capture of the terminal batch or mouse-drag playtest.

**PR 1715, Flat torpedoes** (`bb4f4314d`). The launch limits deck rise to 0.34 and removes vertical midpoint scatter in the current path. The check sampled 27 trajectories. Its combined count can mask a missing weapon case (finding 9).

Not checked: No before/after clip from installed tube or rocket-rack models.

**PR 1643, Plan then commit** (`750a50a2e`). The battle check covers planning, backing up and sending a move plus volleys in one batch. The extra probe uses the opposite firing-arc case and reproduces the empty commit (finding 1).

Not checked: No full player campaign or keyboard-only usability pass.

**PR 1698, Ship import** (`fa7ca5ffa`). The builder generates LODs and reuses compressed textures. The install fixture inspects saved scene materials and LOD indices. Geometry and external paint have different stamp coverage (finding 4).

Not checked: No inspection of every installed ship or GPU memory measurement.

**PR 1706, Claude hooks and scoped rules** (`513731da1`). All 94 numbered rules checked in sections 3 through 9 are present after the move, and the four scoped files resolve their local Markdown links. The Windows hook selects the installed Godot console and checks the loader summary. The prompt baseline misses pre-existing edits (finding 8). The later board.key false-positive fix is present.

Not checked: No live Claude session, hosted branch-protection change or cloud hook-registration check.

**PR 1710, Godot tables in the pipeline** (`7f66627f3`). The live Python recipe reader returned all 128 weapon slots across 51 Godot hull entries in order. The saved free-exit and Nemesis archives decoded to 32 and 12,482 cases. The Windows sweep passes the Godot binary and returns the child exit code.

Not checked: No Blender export or full generated sweep on Windows.

**PR 1714, Install refresh budget** (`943dff315`). External maps now include SHA-256, so equal map sizes and times no longer collide. The GLB metadata and restart-at-first-directory cases remain (findings 4 and 7).

Not checked: No timed production fleet install on Ryan's machine.

**PR 1721, R414 option C** (`cfd4be058`). Both live Godot tables agree on HULLS, RAMP and all six shop multipliers. Decoded Standard is 0.95 and Veteran is 1.15. The Godot map-trial check matched 336 saved battles and pinned fleets across 14 encounters.

Not checked: No full-run faction win-rate measurement or live shop playthrough. The percentages in the balance playbook are projections.

## Checks and reproductions

- The real battle scene, scenario s1, seed 1001: x04 gun 0 selected x07 with no move, attack-move or picks. Enter produced zero batches and left the rules view identical. Supplying the finishing state (busy, rules over, end screen still closed) produced a visible shelf blocker in the ledger layout. That second probe checked the UI state, without playing a match to victory.
- A Navy fighter killed by acid produced the corkscrew beat, six smoke particles (kind 3) and two shards on the death call. The existing fixture reported zero smoke because its before and after samples both contained those six particles.
- The production ship stamp returned the same key for two 384-byte GLBs with different positions in the vertex buffer, each timestamped 1700000000. The external-map SHA covers a different input.
- The Godot map trial passed all 336 cases across 14 encounters. The Python recipe-reader check matched all 51 hulls and 128 weapon slots to the live table. The campaign and battle tables agreed on all six faction prices and both difficulty values. Comparing parents also found 43 changed hull costs and zero changed command-point costs.
- The Godot-only saved-results check passed all 289 battles with zero changed results. It also passed the random-number, math and threat-map comparisons.
- After importing the project in a temporary copy, the torpedo, Wave 1A, melt, live-wounds and install-refresh checks passed with no engine errors in their logs. The plan check passed its assertions with placeholder hulls V14_23, H8_23 and H7_23 and a resource warning at exit. Death variety reported zero failed assertions alongside 29 null-material errors in the headless dummy renderer. Those two runs verify state and counters only.

- The full Windows standing suite exited 1. Of 114 checks, 101 passed, 11 failed, and two reported known baseline differences (findings_tests and oracle_drift_guard). The failures were auto_pr_body_tests, godot_profile_tests, gpu_slots_tests, picture_provenance_tests, publish_ship_tests, pysite_1535_tests, relay_push_tests, runner_cleanup_tests, saved_campaign_update_tests, runner_selftest and stage5_fail_selftest. This run did not establish which merge, if any, caused those failures.

## Source receipts

Raw Git objects provide the pinned main text and each first-parent merge diff. The inventory covers the 85 changed text paths plus the supporting sources below. Binary records have no source lines. The merges also changed 35 Brotli archives and three gzip fixture files.

<details><summary>Line counts, last lines and large-file ranges</summary>

The last column gives up to 40 characters of the final line as a JSON string, including tabs and blank lines. The ranges are the changed lines that survive on main in large files. Additional source ranges follow the table. A one-line JSON table was decoded by key. A receipt identifies a file, without implying every unrelated function was evaluated.

````text
path | lines | final line prefix
.claude/hooks/README.md | 42 | "runs the real Godot loader on a small te"
.claude/hooks/guard.cjs | 459 | "}"
.claude/hooks/guard.test.cjs | 234 | "}"
.claude/rules/godot-battle.md | 144 | "R37). Set: Ryan (R37, R40). Ids: R37b, R"
.claude/rules/godot-ui.md | 106 | "come as a design pack first (issue 1453)"
.claude/rules/pc-harness.md | 50 | "3.7 **Clone on the PC with `git -c core."
.claude/rules/ships.md | 176 | "stage 6's hand chain stays an analysis p"
.claude/settings.json | 124 | "}"
AGENTS.md | 108 | "(seat table, ship sections, PC notes) is"
contrib/fable/reviews/audit_1122.md | 89 | "large files end to end (see the table); "
contrib/opus/FINDINGS.md | 594 | "| X17 | Muse follow-up pass over unasses"
docs/RULEBOOK.md | 658 | "draws meshes at full detail. Set: Ryan, "
docs/playbooks/balance.md | 29 | "these numbers, until a full-run Godot si"
docs/playbooks/deaths_and_hits.md | 398 | "Each is one or two Codex runs and one lo"
docs/playbooks/screens.md | 307 | "well-specified follow-ups (a string, a t"
docs/playbooks/ships.md | 594 | ""
godot/audio/sfx.gd | 631 | "\tcreate_tween().tween_property(_amb, \"vo"
godot/audio/test/audio_check.gd | 520 | "\t\tawait process_frame"
godot/bench/look_bench.gd | 747 | "\treturn true"
godot/bench/look_moments_1586.json | 854 | "}"
godot/bench/look_moments_1587.json | 872 | "}"
godot/campaign/campaign.gd | 4080 | "\t\t\"events\": tel_log.slice(max(0, tel_log"
godot/campaign/data/campaign_tables.json | 1 | "{\"sha256\":\"905ba44eb5476b76fbd60ed0b2a1b"
godot/campaign/test/core_sync_cases.json | 12 | "]"
godot/campaign/test/core_sync_test.gd | 66 | "\tquit(0 if failures == 0 else 1)"
godot/campaign/test/free_exit_test.gd | 61 | "\tquit()"
godot/campaign/test/inheritance_cases.json | 9 | "]"
godot/campaign/test/inheritance_test.gd | 40 | "\tquit(0 if failures == 0 else 1)"
godot/campaign/test/nemesis_clash_test.gd | 41 | "\tquit()"
godot/campaign/test/nemesis_teach_cases.json | 4 | "]"
godot/campaign/test/nemesis_teach_test.gd | 46 | "\tquit(0 if failures == 0 else 1)"
godot/campaign/test/round_save_entry_test.gd | 167 | "\tquit(1 if fails > 0 else 0)"
godot/campaign/test/saved/results.json | 161 | "}"
godot/campaign/test/shadow_xp_cases.json | 9 | "]"
godot/campaign/test/shadow_xp_test.gd | 50 | "\tquit(0 if failures == 0 else 1)"
godot/fx/API.md | 610 | "neither these tools nor their pictures r"
godot/fx/fx.gd | 2264 | "\treturn hk"
godot/fx/fx_breach.gd | 1926 | "\t\t_tube(pt, points, e.R * 0.06, e.R * 0."
godot/fx/fx_death.gd | 4246 | "\t\tnd.global_position -= back"
godot/fx/fx_death_beats.gd | 592 | "\t\t\t_implode(fx, s, p, T - 0.25)"
godot/fx/fx_hull.gd | 1881 | "\t\t\t\t(lb[\"node\"] as Node3D).transform = ("
godot/fx/fx_shaders.gd | 2469 | "\"\"\""
godot/fx/fx_ship.gd | 2574 | "\t\t_dmg_request(fx)"
godot/fx/fx_weapons.gd | 2603 | ""
godot/fx/test/approved_effects.json | 27 | "}"
godot/fx/test/death_plane_check.gd | 332 | "\tquit(1 if failures else 0)"
godot/fx/test/death_variety_1586_check.gd | 340 | "\treturn (fx.spr_kinds as Dictionary).dup"
godot/fx/test/live_wounds_1587_check.gd | 363 | "\tquit(1 if failures > 0 else 0)"
godot/fx/test/melt_death_check.gd | 201 | "\treturn out"
godot/fx/test/torpedo_flat_flight_check.gd | 61 | "\tquit(1 if failures else 0)"
godot/fx/test/wave_1a_check.gd | 360 | "\tquit(0 if failures == 0 else 1)"
godot/render/build_assets.gd | 577 | "\t\t\t\treturn"
godot/render/ship_view.gd | 1788 | "\t\tring.rotation.y = -rotation.y"
godot/render/test/hold_beacon_check.gd | 139 | "\tquit(1 if failures > 0 else 0)"
godot/render/test/install_refresh_check.gd | 303 | "\tquit(0 if fails == 0 else 1)"
godot/render/test/installed_ship_check.gd | 103 | "\tquit(0 if fails.is_empty() else 1)"
godot/rules/battle_api.gd | 1213 | "\treturn why"
godot/rules/data/tables.json | 1 | "{\"sha256\":\"5afc47785c4854e6ebcdd616e7c21"
godot/rules/rules.gd | 7332 | "\tB[\"aiActive\"] = null; u[\"activated\"] = "
godot/rules/test/README.md | 132 | "  - `tr` is taken by `Object.tr`."
godot/rules/test/effect_caps_cases.json | 237 | "}"
godot/rules/test/effect_caps_test.gd | 32 | "\tquit(1 if bad > 0 else 0)"
godot/rules/test/map_trial_test.gd | 108 | "\tquit(0)"
godot/rules/test/node/map_trial_pinned.json | 1 | "{\"revision\":\"Godot rules (map_trial_test"
godot/rules/test/node/sweep_gen.js | 59 | "module.exports = { generate };"
godot/rules/test/run_sweep.sh | 5 | "exec node \"$HERE/safety/run_cache_check."
godot/rules/test/safety/run_cache_check.js | 194 | "main().catch(e => { console.error('FAIL:"
godot/rules/test/saved/changes.txt | 46 | "FAIL: saved Godot results; 289 battles c"
godot/rules/test/saved/results.json | 2071 | "}"
godot/rules/test/shield_pool_cases.json | 43 | "}"
godot/rules/test/shield_pool_test.gd | 50 | "\tquit(1 if bad > 0 else 0)"
godot/rules/test/undo_test.gd | 217 | "\t\t\t\tif api.can_undo(u[\"id\"]) or api.undo"
godot/scenes/battle/battle.gd | 7036 | "\tget_tree().quit(code)"
godot/scenes/battle/test/plan_commit_check.gd | 363 | "\tquit(0 if fails == 0 else 1)"
godot/tools/ci/godot_checks.txt | 239 | "headless|main/test/player_path_map_ready"
godot/tools/probes/plan_commit_1589_shots.gd | 324 | "\tquit(0 if failed == \"\" else 1)"
godot/ui/battle/hud.gd | 1530 | "\tledger.mark()"
godot/ui/battle/ledger.gd | 1020 | "\t\t\t\tact.emit(h.act, h.arg)"
godot/ui/campaign/campaign_ui.gd | 2598 | "\t\t\t\tKit.play(Kit.press_cue(cue_role(str("
tools/blender/build_sheets/build.py | 336 | "print('WROTE', blend)"
tools/blender/build_sheets/contract.py | 204 | "                slots=[f'{i} {wk} {arc}'"
tools/blender/build_sheets/variants.py | 43 | "    return K"
tools/blender/build_sheets/weapon_match.py | 289 | "    return result, probs"
tools/pc/parity_sweep.bat | 36 | "endlocal & exit /b %RESULT%"
tools/pc/play_godot.bat | 45 | "exit /b 0"
tools/pc/work_issue.ps1 | 838 | "else { Write-Host 'usage: work_issue.ps1"
tools/recipe/7_export.bat | 62 | "exit /b 1"
tools/recipe/check_export.py | 401 | "    main()"
tools/recipe/export7.py | 652 | "print('[export7] written', OUT, flush=Tr"
tools/recipe/gamedata.py | 81 | "    print(weapons(sys.argv[1]))"
tools/recipe/sheet_contract_selftest.py | 107 | "sys.exit(1 if bad else 0)"
tools/recipe/sheet_fixture_hash.py | 153 | "    sys.exit(main())"
````

Large-file changed lines on main and additional source ranges:

- `contrib/opus/FINDINGS.md` 428,431,442; merged ruling hunks only
- `docs/RULEBOOK.md` 3,33-35,83-86,478,523,527,531,535,537,539,543; 1-90, 289-309
- `docs/playbooks/ships.md` 565-567; PR 1715 flight paragraph
- `godot/campaign/campaign.gd` 219-225, 2166-2172, 2198
- `godot/campaign/data/campaign_tables.json` 1
- `godot/fx/API.md` 139,143-145,149,151-153; PR 1699 hit-reaction contract
- `godot/fx/fx.gd` 67,232,354-355,725-728,731-732,752-768,788-789,1610-1611,1799; 723-748, 795-806
- `godot/fx/fx_breach.gd` 1748-1775
- `godot/fx/fx_death.gd` 13,305-319,325,347,2269-2271,2281-2283,2293,2301,2304-2305,2346,2369,2407,2413-2415,2573-2574,2577-2582,2601-2610,2900-2901,2905,2946-2951,3064,3094-3095,3097-3100,3126-3131,3136,3351,3396-3397,3399,3413,3453-3457,3595-3598,3627,3663-3669,3780-3785,3847; 315-346, 2250-2390, 2410-2446, 2497-2527
- `godot/fx/fx_hull.gd` 121,268-270,273,275,339,1087-1090,1300,1530-1533,1556-1558,1602-1603,1652-1712,1725-1731,1733-1769; 265-286, 312-339
- `godot/fx/fx_shaders.gd` 1751-1752; 1072-1093
- `godot/fx/fx_ship.gd` 29,48-60,117-118,130-134,158-160,273-275,334-342,383-391,418,422-425,449-458,473-477,482-483,486-488,493,495,1027,1223-1224,1235,1239-1241,1248-1249,1254-1255,1264-1265,1318-1324,1329-1332,1335-1338,1340,1347-1360,1363,1365,1409,1411-1466,1511-1512,1516-1526,1530,1536,1589-1591,1670,1676-1680,1682,2191-2195,2218-2220,2298-2491,2493-2496; 139-161, 248-275, 419-466, 1425-1467, 1494-1572, 2310-2500
- `godot/fx/fx_weapons.gd` 57-58,292-307,335-356,605,861,877-880,919-925,1995-1998,2007-2013,2015-2016,2019-2029,2036,2039,2222,2298,2309-2335,2520-2567; 246-402, 860-944, 1985-2070, 2174-2227
- `godot/render/ship_view.gd` 18-19,92-94,104,124,271,422-423,572,1629-1630,1634-1635,1651-1653,1664-1672,1701,1756-1757,1760,1762,1769,1778; 418-440
- `godot/rules/battle_api.gd` 286-304, 1099
- `godot/rules/data/tables.json` 1
- `godot/rules/rules.gd` 2708-2734, 3955-3961, 4058
- `godot/rules/test/node/map_trial_pinned.json` 1
- `godot/rules/test/saved/results.json` 48-49,51,62-63,65,167-168,170,230-231,233,237-238,240,251-252,254,258-259,261,265-266,268,286-287,289,2022-2023,2025
- `godot/scenes/battle/battle.gd` 12,100-106,204-208,488-491,579,1021,1025,1275,2754-2801,2811,2856,3001,3053-3055,3060-3061,3063-3070,3072-3077,3082-3089,3222-3225,3257-3261,3272-3273,3276-3282,3284,3286,3401-3402,3404,3417-3420,3472-3475,3494-3502,3784,4001,4019,4069-4070,4079-4100,4105,4107,4116-4140,4142-4161,4177,4249,4260-4267,4277,4391-4393,4416,4431,4434-4435,4437,4442,4451-4452,4456-4462,4464-4481,4483,4487-4552,4565,4569,4584,4587,4592-4603,4605-4615,4618-4625,4627-4646,4648-4651,5003-5005,5011-5013,5032-5033,5041-5045,5056,5061,5506,5528-5572,5636,5665-5673,5703-5706,5710,6418; 932-1035, 1273-1291, 2753-2819, 2884-2907, 3039-3089, 4390-4484, 4547-4656, 5486-5517
- `godot/ui/battle/hud.gd` 445-453,490,767-769; 443-457, 756-775
- `godot/ui/campaign/campaign_ui.gd` 1944,1946,1948,1955; PR 1643 changed hunk

</details>

**Recommended next step.** The Board should file findings 1 to 3 as issues with the probe conditions above.

Not checked: rendered or audible results on the installed build, player judgment at camera 170, and GPU frame times. Lane C ran code-only checks.
