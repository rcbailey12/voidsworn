# Battle scene, board and world audit (issue 1090)

Main reviewed: `dfbb5ef6f3cd4922e2eb97a283357118582de513`. The resumed checkout had the partial commit in its history and no saved audit files. Its five scoped trees matched that main commit. I treated the five named directories as the scope, followed their callers when needed for proof, and used code and headless checks while issue 1070 owned frame timing. Replaced A4 hulls received no individual hull review (R323); shared loaders and tracked asset records were in scope.

## Top ten

1. Clicking a marked hex never fires Nova or Blink.
2. Title settings buttons can leave the label unchanged and the new choice unsaved.
3. After the camera moves, a click can land on the hex that used to be under the pointer.
4. The flash check can pass four full-screen flashes in one second.
5. Changing the selected gun can leave an old burn-and-fire preview on screen.
6. The title offers Continue even when the player has a profile but no run to resume.
7. A missing wreck piece can break the fallback that draws blocked hexes.
8. The danger overlay can keep warning about guns that were just knocked out.
9. The look bench leaves the volume fog off even for its Max storm row.
10. The nebula bench builds the fleet twice and reports the first build's time for the second one.

## Confirmed findings, ranked

### 1. Targeted abilities reject every clicked hex

**Confirmed / OBSERVED, high.** `godot/scenes/battle/battle.gd:3208-3214`: `mode = ""`; `godot/scenes/battle/battle.gd:2889-2891`: `if sel == "" or not (mode in ["nova", "blink"]):`.

**Show it:** `_on_action("ability")` enters `nova` or `blink` mode and `_overlay()` gets the marked hexes through `_ability_hexes()`. `_on_click()` then clears `mode` before asking the same helper to validate the click. The helper returns `[]` and `api.ability()` never runs, even for a legal hex. `targeted_ability.gd` calls that handler with a legal hex and a rules spy and fails for both abilities.

**Fix (1 agent run):** Validate against the active ability's legal hexes before leaving the mode. Add both valid-click and invalid-click cases to the scene check.

### 2. Title settings buttons abort before saving or applying

**Confirmed / OBSERVED, high.** `godot/main/title.gd:453-460`: `b.text = "On" if main.settings[key] else "Off"`; `godot/main/title.gd:468-483`: `b.text = label_of.call()`.

**Show it:** Both `_toggle()` and `_choice()` create the pressed callback while the local `b` still holds null. The callback changes `main.settings`, then tries to change the text of that captured null value. It aborts before `main.save_settings()`, which also applies live settings in `godot/main/main.gd:162-170`. Done can save the changed values later, so the bug is a stale label and failure to save or apply on the press. Teaching tips also has a separate write before the failing line. `title_settings.gd` emits the real Sound and Graphics button signals: the values change, the labels stay old, and neither save is called.

**Fix (1 agent run):** Create the button first, then wire its callback with the button already assigned. Keep one save/apply step per successful press and test a toggle and a choice.

### 3. A stationary pointer keeps the old hex after camera motion

**Confirmed / OBSERVED, high.** `godot/scenes/battle/battle.gd:2918-2923`: `_on_click()`; `godot/scenes/battle/battle.gd:3204-3206`: `var u := _unit_at(hover.x, hover.y)`.

**Show it:** Only mouse motion sends its position to `_on_hover()` and updates `hover` (`3184-3189`). Wheel zoom, key pan, and a camera glide can change the hex at that same screen position. The unhandled left release ignores its position and reuses `hover` for selection, move planning, or confirmation; it can also reuse an old target. `click_after_camera_move.gd` projects the viewport center, moves the real rig, then sends a release at that same point. The handler gets `(0, 0)` when the current ray hits `(2, 0)`.

**Fix (1 agent run):** Pick from the release position and current camera before dispatching the board click. Make sure a consumed UI or drag gesture cannot become a board click.

### 4. The flash meter can report a false pass

**Confirmed / OBSERVED, high.** `godot/bench/scene_gate.gd:559-570`: `if t - last < 0.33:`; `godot/bench/scene_gate.gd:441-445`: `"pass": bool(stats["mean_max"] <= 3 and stats["block_max"] <= 3)`.

**Show it:** `_flash_stats()` counts swings between extrema, then `_rolling_max()` suppresses any swing within 0.33 seconds of a counted one. That can erase separate rise-and-fall pairs before the rolling-second check sees them. `flash_count.gd` feeds the real counter four 0.1-to-0.7-to-0.1 full-screen pulses, 0.2 seconds apart at 60 Hz. It reports two. Independently, `_run()` calls `PG.finish(0)` after `_flash_run()` even when the report's `pass` value is false (`172-175`, `441-455`). This proves a bench fault, not that the shipped effects exceed the limit.

**Fix (2 agent runs):** Count distinct opposing threshold pairs from frame timestamps without a fixed dead time, test known pass and fail fixtures, and return a nonzero exit status for a failed flash check. Have the frame/effects seat validate the screen-area method separately from the effect budget's own counters.

### 5. Changing guns leaves a stale attack-move plan

**Confirmed / OBSERVED, high.** `godot/scenes/battle/battle.gd:3022-3028`: `armed = -1 if armed == i else i`; `godot/scenes/battle/battle.gd:3355-3361`: `_cmd(func(): return api.attack_move(id, tid, wsel))`.

**Show it:** Target an enemy out of range with a valid burn-and-fire plan, then use a number key to arm a different gun. `_target()` set `atk` using the old weapon set (`3303-3323`, `2462-2469`). `_arm()` refreshes the UI but leaves `atk` alone. `_overlay()` and `_card_info()` still show its old path, cost and gun count (`2637-2647`, `4256-4260`). Confirm builds `wsel` from the new `armed` value. `godot/rules/battle_api.gd:329-365` shows the commit recomputes the route with that set; picking a flak-only slot, for example, makes the planner return null even as the card still offers Burn and fire for the prior set.

**Fix (1 agent run):** Recompute or clear the targeted plan when the gun selection changes, and use the same validated selection for the ghost, card and confirm path.

### 6. A profile file is mistaken for a resumable run

**Confirmed / OBSERVED, high.** `godot/main/campaign_host.gd:104-105`: `return FileAccess.file_exists("user://voidsworn_campaign.json")`.

**Show it:** Finish a run. `godot/campaign/campaign.gd:1674` clears `SAVED_RUN` and persists the profile; `417-418` writes `run: {"none": true}`. The main title still adds and focuses Continue via `title.gd:128-132` and `main.gd:319-320`. Pressing it goes through `campaign_host.gd:64-76`, which loads the file and calls `continueRun` directly. The campaign title correctly omits that act when there is no run, but `ACT_continueRun()` itself dereferences the result of cloning `SAVED_RUN` (`godot/campaign/campaign.gd:1408-1419`). The same mismatch can affect a bad save after the loader rejects its run.

**Fix (1 agent run):** Derive the title button from the same loaded and migrated run state the campaign uses. Guard the handoff too, and check a profile-only save and a resumable old save.

### 7. A wreck-kit file gap breaks the fallback itself

**Confirmed / OBSERVED, high for a missing or empty asset.** `godot/world/world_living.gd:1207-1226`: `assert(node != null, "Missing wreck kit: " + path)`; `godot/world/blocker_visuals.gd:199-203`: `_wreck_meshes[rng.randi() % _wreck_meshes.size()]`.

**Show it:** Follow `godot/render/board.gd:794-804` when a painted derelict cannot load, or the hulk-hole branch at `blocker_visuals.gd:57-64`. Both reach `hulk_fallback()` and `_shard_meshes()`. If the first wreck kit scene is missing, debug builds stop the loader at the assertion; exported builds omit assertions and proceed with no node. The latter can enter `world_rocks.gd:385-392` with null; neither path yields usable kit geometry. A later missing part can leave a partial static cache because the loader appends as it goes and treats any nonempty cache as complete. The same loader is used for ordinary debris (`world_living.gd:901-929`, `971-986`). All six tracked kit files were present here; this is a broken error path.

**Fix (1 agent run):** Validate the load result and mesh, build the cache only after validation, and use a simple solid procedural fallback if the kit is unusable. Test the first piece missing and a later piece missing with isolated fixture resources.

### 8. Danger overlays miss changes that do not move an enemy

**Confirmed / OBSERVED, high.** `godot/scenes/battle/battle.gd:2798-2807`: `key = "%d|%d|%s" % [int(V.get("round", 0)), batches.size(), ",".join(ek)]`.

**Show it:** In a player's activation, hit a stationary enemy hard enough to disable its only eligible gun without killing it. A disabled gun has `off` greater than 1 (`godot/rules/rules.gd:2819`, `2883-2886`, `2906`), so a fresh `threat_both()` omits it (`godot/rules/battle_api.gd:579-590`, `612-620`). But when the batch is done the same round, queue length and enemy positions/facings produce the same scene key. `_threat_request()` skips the API call; `_danger_bands()` and `_danger_at()` keep the previous count. Moving your own ship can also affect enemy reach through occupancy (`godot/rules/rules.gd:1607`, `1649-1659`). With R enabled, the alternate key uses HUD log line count, which is also not a rules revision.

**Fix (1 agent run):** Key the scene result by the rules revision of the view it describes and reject a completion for an older revision. Use the API's existing versioned cache and keep the worker off the main thread.

### 9. The Max look bench omits the volume fog it is meant to show

**Confirmed / OBSERVED, high for the configuration.** `godot/bench/look_bench.gd:259`: `LOOK.apply(env, key, fill, {"quality": "max"})`; `godot/bench/look_bench.gd:305-306`: `"environment": env, "quality": "max", "seed": 7`.

**Show it:** `_setup_view()` creates a private `Environment`; `godot/render/look.gd:102-137` sets tone, lighting and post effects but does not enable volume fog. `_fleet_part()` sends the storm hexes to `World.build()`; `world_living.gd:424-432`, `515-517` builds the reduced card layer plus FogVolumes on Max. The production battle enables the environment's fog separately in `battle.gd:368-378`. The look bench never makes that call or sets `volumetric_fog_enabled`, and the camera only updates fog length when fog is already on (`godot/render/camera_rig.gd:193-200`). Its Max storm row therefore covers the reduced cards without the volume. No claim about pixel differences was measured.

**Fix (1 agent run plus visual review):** Use the same terrain renderer setup for the battle and the Max bench, including the hull fog policy. Assert that the Max storm row actually has an enabled fog environment.

### 10. The nebula bench times a different build from the one it uses

**Confirmed / OBSERVED, high.** `godot/world/nebula_bench.gd:161-177`: `await super._build(mode, seed)` and `b.begin_with(b.api)`.

**Show it:** The base gate builds and warms a full Max battle and records `build_ms` (`godot/bench/scene_gate.gd:587-627`). For the nebula case or any lower terrain tier, the adapter changes the inputs and calls `begin_with()` on the same battle again. That requeues the old views, replaces the world and makes/registers every ship again (`battle.gd:530-536`, `565-594`, `820-837`). The base report still emits the first `build_ms` (`scene_gate.gd:892`); the adapter adds the second scene's terrain and camera but never replaces that value (`nebula_bench.gd:178-195`). The base battle also set up FX and lighting before the terrain tier switched. These are test setup and reporting mismatches; no frame delta was measured.

**Fix (1 agent run):** Let the adapter set terrain and tier before the base gate does its one build. Report the actual terrain tier, scene inputs, and build interval from that one scene.

## Suspected, not confirmed

- **INFERRED, medium:** `godot/world/world_bake.gd:114-116`, `270-280`: `if _thread != null: _thread.wait_to_finish()`. The loading cover has a timeout, but shutdown still joins the worker, which may be inside `rd.sync()`. If a driver call gets stuck, dismissing the cover may still leave Quit stuck. I did not reproduce a driver stall. **Potential fix (2 agent runs):** First reproduce with a controlled slow worker; then give shutdown a bounded handoff or isolate work that cannot be cancelled in-process.
- **INFERRED, medium:** `godot/world/blocker_visuals.gd:85-96`: `if kind == "station" and not solid_at(get_parent(), p):`. The coverage predicate accepts any intersecting mesh AABB in XZ, without an owner, visibility, or height check. A different prop's box could suppress a station dock. I did not establish such an overlap in a shipped seed. **Potential fix (1 agent run):** If a seed or fixture confirms it, restrict coverage to solid station parts and test the uncovered edge cell directly.

## Frame-cost suspects for issue 1070

- **unmeasured guess** `godot/scenes/battle/battle.gd:4728-4773`: the battle loop updates plates for all ships and runs decluttering every frame; the title showcase still enters this loop with a hidden HUD. Compare a showcase with plate work disabled, and separate position updates from changed text or status in battles.
- **unmeasured guess** `godot/scenes/battle/battle.gd:2637-2657`, `2683-2702`, `3184-3189`: changing the hovered hex can rebuild the already-planned path mesh even when its route and facing did not change. Check a long move preview with a fixed plan and moving pointer.
- **unmeasured guess** `godot/world/world_living.gd:812-859`: the living terrain uploads zero flash and flare state on idle frames and scans the floating texts to infer a storm tick. Separate active from idle patch updates in a profile before changing it.

## Checks and impact

From the repo root, run `godot --headless --path godot --script ../contrib/openai/audit_1118/tests/world_scenes/<file>.gd` with Godot 4.7.2. These four scripts instantiate only the needed script objects and do not load scenes or imported textures. They intentionally fail on the audited commit:

```text
FAIL: nova click on a highlighted hex sent no ability command
FAIL: blink click on a highlighted hex sent no ability command
FAIL: Sound=On (false), Graphics=Max (high), saves=0; expected Off, High, 2 saves
FAIL: click after camera moved picked (0, 0), cursor is over (2, 0)
FAIL: four full-screen flashes in one second counted as 2
```

The title probe also reports the expected null `text` assignments at `title.gd:459` and `:480`. The tests are `targeted_ability.gd`, `title_settings.gd`, `click_after_camera_move.gd`, and `flash_count.gd`, in that order. Node checks of the source inventory, asset headers, JSON rows and terrain receipts reported:

```text
PASS scope asset scan (287 tracked files)
PASS scope text and data ledger
PASS world receipts: 48 R01 resources and 16 scanned rock meshes match recorded hashes and available counts
```

- **Callers:** Searched the repository for the cited handlers, loader and view functions and followed the affected callers; there are no changed production symbols.
- **Saves:** Read the settings load/write path and campaign profile-only, backup and migration paths; the title defect occurs across an existing profile with no run. The settings check uses an in-memory stub and the audit did not read a player profile or modify saved fields.
- **Twins:** Checked the Godot rules API called by the scene. Nothing changes in the rules port, browser oracle, or exported tables; parity and oracle-copy checks were not run.
- **UI:** Traced title Continue and settings, the ability highlights, board click, ghost, activation card, danger hatching and fleet badges. The audit changes no screens.
- **CI:** `.github/workflows/checks.yml` runs the standing checks, rules and campaign parity, Godot-only rules safety net, and Godot game checks from `godot/tools/ci/godot_checks.txt`. The old wing, fan, station, onboarding and ledger checks stay there. These evidence-only failures are under `contrib/` and are not added to CI.

Recommended next step: file the targeted-ability, settings and camera input fixes first, and use the flash fixture before trusting another flash-gate pass.

## Read ledger

All 287 tracked paths in scope are recorded below: 100 text files, 28,633 lines, and 187 binaries. Text line counts include a final blank line if one is stored; the last column gives the first 40 characters of that last line, quoted with tabs escaped as `\t`. Scripts and docs were read as source. JSON data were parsed in full, with all moment rows, ship entries and terrain manifests inspected as structured data. Asset coverage for binary files means file-level inspection: JPEG dimensions and markers, GLB headers and JSON/buffer bounds, and Godot resource signatures with the available terrain receipt hashes. Binaries have no text line count.

Ranges read for the large files: `godot/scenes/battle/battle.gd` 1-700, 701-1500, 1501-2300, 2301-3100, 3101-3900, 3901-4750, 4751-5601; `godot/world/world.gd` 1-730, 731-1460; `godot/world/world_living.gd` 1-675, 676-1349; `godot/bench/scene_gate.gd` 1-525, 526-1048. Full structured reads also covered lines 1-1766 of `godot/assets/ships/manifest.json` and 1-2335 of `godot/bench/look_moments.json`.

```text
path | lines | last line prefix
godot/assets/ships/README.md | 125 | "- Nothing here depends on the old `hulls"
godot/assets/ships/a4_props.gd | 96 | "\treturn n"
godot/assets/ships/manifest.json | 1766 | "}"
godot/assets/ships/test/a4_shots.gd | 407 | "\t\t\tmi.set_surface_override_material(s, b"
godot/assets/ships/test/a4_shots.tscn | 6 | "script = ExtResource(\"1\")"
godot/assets/ships/test/station_size_check.gd | 58 | "\tprint(\"%s: %s\" % [\"PASS\" if ok else \"FA"
godot/bench/README.md | 83 | "- The late-shader counter of issue 376 d"
godot/bench/death_small_measure.gd | 143 | "\tquit()"
godot/bench/look_bench.gd | 672 | "\treturn true"
godot/bench/look_bench.tscn | 6 | "script = ExtResource(\"1\")"
godot/bench/look_moments.json | 2335 | "}"
godot/bench/look_moments_attach.json | 663 | "}"
godot/bench/look_moments_deaths_small.json | 692 | "}"
godot/bench/look_moments_hits2.json | 916 | "}"
godot/bench/look_moments_hits2_deaths.json | 96 | "}"
godot/bench/look_moments_turrets.json | 240 | "}"
godot/bench/rebake_measure.gd | 112 | "\tquit()"
godot/bench/scene_gate.gd | 1048 | "\t\t\t\"volumetric_fog\": b.env.volumetric_fo"
godot/bench/scene_gate.tscn | 6 | "script = ExtResource(\"1\")"
godot/main/FEATURES.md | 101 | "| Engine cues on moves | done |"
godot/main/README.md | 137 | "- The new game name (Embers of the Hollo"
godot/main/campaign_fallback_ui.gd | 134 | "\treturn l"
godot/main/campaign_host.gd | 369 | "\trun_over.emit({\"result\": \"win\" if won e"
godot/main/load_screen.gd | 58 | "\t\tlast = now"
godot/main/main.gd | 518 | "\treturn out"
godot/main/main.tscn | 6 | "script = ExtResource(\"1\")"
godot/main/test_loading.gd | 106 | "\tprint(\"BAKE %s pixel error: max=%f mean"
godot/main/title.gd | 576 | "\t_reveal_tw.tween_property(_shade, \"colo"
godot/scenes/battle/battle.gd | 5601 | "\tget_tree().quit(code)"
godot/scenes/battle/battle.tscn | 6 | "script = ExtResource(\"1\")"
godot/scenes/battle/f1_trace.gd | 436 | "\tPG.finish(1 if fails > 0 else 0)"
godot/scenes/battle/fx_stub.gd | 167 | "\titems.clear()"
godot/scenes/battle/lineup.gd | 136 | "\tPG.finish(0)"
godot/scenes/battle/lineup.tscn | 6 | "script = ExtResource(\"1\")"
godot/scenes/battle/play_log.gd | 87 | "\treturn {\"v\": 1, \"result\": result, \"roun"
godot/scenes/battle/test/fan_range_test.gd | 72 | "\treturn Vector2(v.x, v.z)"
godot/scenes/battle/test/movement_flight_check.gd | 217 | "\t\t\t\tfails.append(\"%s: the turn is not st"
godot/scenes/battle/test/nose_first_check.gd | 177 | "\t\tfails.append(\"%s: flown on thrusters, "
godot/scenes/battle/test/wing_cancel_test.gd | 104 | "\tquit(1 if fails > 0 else 0)"
godot/scenes/campaign/.gitignore | 1 | "*.uid"
godot/scenes/campaign/campaign.tscn | 6 | "script = ExtResource(\"1\")"
godot/scenes/campaign/campaign_scene.gd | 406 | ""
godot/scenes/campaign/map3d_probe.gd | 39 | "\tPG.finish(0)"
godot/scenes/campaign/map3d_probe.tscn | 6 | "script = ExtResource(\"1\")"
godot/scenes/campaign/stops_probe.gd | 54 | "\tpreload(\"res://tools/picture_provenance"
godot/scenes/campaign/stops_probe.tscn | 6 | "script = ExtResource(\"1\")"
godot/world/blocker_visuals.gd | 223 | "\tnode.global_position = centre + Vector3"
godot/world/board_look.gd | 69 | "\treturn {\"plate\": true, \"underlay\": 1.0,"
godot/world/board_look.gd.uid | 1 | "uid://8xwp1rw1s3qi"
godot/world/distinct_capture.gd | 78 | "\tb = null"
godot/world/distinct_capture.tscn | 6 | "script = ExtResource(\"1\")"
godot/world/finale_shots.gd | 173 | "\treturn error / float(a.get_width() * a."
godot/world/hull_debris.gd | 51 | "\treturn out"
godot/world/ion_storm.gd | 107 | "\"\"\""
godot/world/lightning_capture.gd | 113 | "\t_bolt_screen_rows.append(row)"
godot/world/lightning_capture.tscn | 6 | "script = ExtResource(\"1\")"
godot/world/nebula_bench.gd | 328 | "\tfile.close()"
godot/world/nebula_bench.tscn | 6 | "script = ExtResource(\"1\")"
godot/world/nebula_capture.gd | 136 | "\tfile.close()"
godot/world/nebula_capture.tscn | 6 | "script = ExtResource(\"1\")"
godot/world/nebula_hulls.gd | 37 | "\tif mat.next_pass != null: _material(mat"
godot/world/nebula_noise_bake.gd | 36 | "\tquit(0 if error == OK else 1)"
godot/world/nebula_noise_data.gd | 16 | "\treturn result"
godot/world/rocks/LICENCE_369.md | 142 | "count. Full original PNGs stay in TEMP. "
godot/world/rocks/SOURCES_369.json | 417 | "}"
godot/world/rocks/r01/bake.json | 224 | "}"
godot/world/rocks/r01/colour.json | 161 | "}"
godot/world/rocks/r01/relief.json | 164 | "}"
godot/world/rocks/r01/roughness.json | 159 | "}"
godot/world/rocks/rocks.json | 235 | "}"
godot/world/rocks/scans.json | 198 | "}"
godot/world/storm_capture.gd | 105 | "\tlight_file.close()"
godot/world/storm_capture.tscn | 6 | "script = ExtResource(\"1\")"
godot/world/storm_lightning_check.gd | 75 | "\tquit(0)"
godot/world/test/finale_check.gd | 51 | "\tquit(0 if failed == 0 else 1)"
godot/world/test_blockers.gd | 87 | "\tquit(1 if failures else 0)"
godot/world/test_world.gd | 45 | "\tquit(errs)"
godot/world/test_world.gd.uid | 1 | "uid://cpdx1twarm4al"
godot/world/tools/bake_preview.gd | 62 | "\tquit(0)"
godot/world/tools/bake_preview.gd.uid | 1 | "uid://4d8hsqj6gblr"
godot/world/tools/board_sheet.py | 127 | "    main()"
godot/world/tools/rockgen.py | 393 | "    main()"
godot/world/world.gd | 1460 | "\tif _living != null: _living.use_ship_de"
godot/world/world.gd.uid | 1 | "uid://cpxylag4stlqo"
godot/world/world_bake.gd | 339 | "\treturn true"
godot/world/world_bake.gd.uid | 1 | "uid://bxwp8ut7afdcc"
godot/world/world_living.gd | 1349 | "\t\t_chunk_task = -1"
godot/world/world_living.gd.uid | 1 | "uid://bmmkq4a2363nh"
godot/world/world_planet.gd | 509 | "\"\"\""
godot/world/world_planet.gd.uid | 1 | "uid://nwmi1mmcgocy"
godot/world/world_rocks.gd | 529 | "\t\treturn n"
godot/world/world_rocks.gd.uid | 1 | "uid://bk6fg5ou0rwee"
godot/world/world_shaders.gd | 459 | "\"\"\""
godot/world/world_shaders.gd.uid | 1 | "uid://cks0d6lqs4ck7"
godot/world/world_shots.gd | 501 | "\tprint(\"[world_shots] \", p)"
godot/world/world_shots.gd.uid | 1 | "uid://bdxfg0brighsk"
godot/world/world_shots.tscn | 6 | "script = ExtResource(\"1\")"
godot/world/world_sky.gd | 391 | "\treturn out"
godot/world/world_sky.gd.uid | 1 | "uid://ibnwssrvj0y8"
godot/world/wreckage/kit.json | 35 | "}"
```

Binary paths are recorded as directory plus exact basenames (each entry: lines N/A).

```text
godot/assets/ships/previews/ (69)
B16_23.jpg B16_23_damage.jpg B19_11.jpg B19_11_damage.jpg B20_11.jpg B20_11_damage.jpg
B21_11.jpg B21_11_damage.jpg B22_11.jpg B22_11_damage.jpg B23_51.jpg
C13s_23.jpg C13s_23_damage.jpg C14s_23.jpg C14s_23_damage.jpg C15s_23.jpg C15s_23_damage.jpg
C16s_23.jpg C16s_23_damage.jpg C19_51.jpg C19_51_damage.jpg
D20_23.jpg D20_23_damage.jpg D21_23.jpg D21_23_damage.jpg D22_23.jpg D22_23_damage.jpg D9_23.jpg D9_23_damage.jpg
H10_23.jpg H10_23_damage.jpg H4_11.jpg H4_11_damage.jpg H7_23.jpg H7_23_damage.jpg
H8_23.jpg H8_23_damage.jpg H9_23.jpg H9_23_damage.jpg
I11_37.jpg I11_37_damage.jpg I14_23.jpg I14_23_damage.jpg I15_11.jpg I15_11_damage.jpg
I16_11.jpg I16_11_damage.jpg I8_37.jpg I8_37_damage.jpg
O1_37.jpg O1_37_damage.jpg O2_37.jpg O2_37_damage.jpg O3_11.jpg O3_11_damage.jpg S1_51.jpg S2_23.jpg
V14_23.jpg V14_23_damage.jpg V15_37.jpg V15_37_damage.jpg V16_37.jpg V16_37_damage.jpg
V17_37.jpg V17_37_damage.jpg V18_51.jpg V18_51_damage.jpg V1b_r_23.jpg V1b_r_23_damage.jpg

godot/world/ (1)
nebula_noise.res

godot/world/rocks/ (63)
binary_00.glb binary_00_lo.glb binary_01.glb binary_01_lo.glb binary_02.glb binary_02_lo.glb binary_03.glb binary_03_lo.glb
crystal_00.glb crystal_01.glb crystal_02.glb
frag_00.glb frag_00_lo.glb frag_01.glb frag_01_lo.glb frag_02.glb frag_02_lo.glb
frag_03.glb frag_03_lo.glb frag_04.glb frag_04_lo.glb frag_05.glb frag_05_lo.glb
rubble_00.glb rubble_00_lo.glb rubble_01.glb rubble_01_lo.glb rubble_02.glb rubble_02_lo.glb
rubble_03.glb rubble_03_lo.glb rubble_04.glb rubble_04_lo.glb
scan_00.glb scan_00_lo.glb scan_01.glb scan_01_lo.glb scan_02.glb scan_02_lo.glb scan_03.glb scan_03_lo.glb
scan_04.glb scan_04_lo.glb scan_05.glb scan_05_lo.glb scan_06.glb scan_06_lo.glb scan_07.glb scan_07_lo.glb
shard_00.glb shard_00_lo.glb shard_01.glb shard_01_lo.glb shard_02.glb shard_02_lo.glb shard_03.glb shard_03_lo.glb
slab_00.glb slab_00_lo.glb slab_01.glb slab_01_lo.glb slab_02.glb slab_02_lo.glb

godot/world/rocks/r01/ (48)
colour_0_0.res colour_0_1.res colour_0_2.res colour_0_3.res
colour_1_0.res colour_1_1.res colour_1_2.res colour_1_3.res
colour_2_0.res colour_2_1.res colour_2_2.res colour_2_3.res
colour_3_0.res colour_3_1.res colour_3_2.res colour_3_3.res
relief_0_0.res relief_0_1.res relief_0_2.res relief_0_3.res
relief_1_0.res relief_1_1.res relief_1_2.res relief_1_3.res
relief_2_0.res relief_2_1.res relief_2_2.res relief_2_3.res
relief_3_0.res relief_3_1.res relief_3_2.res relief_3_3.res
roughness_0_0.res roughness_0_1.res roughness_0_2.res roughness_0_3.res
roughness_1_0.res roughness_1_1.res roughness_1_2.res roughness_1_3.res
roughness_2_0.res roughness_2_1.res roughness_2_2.res roughness_2_3.res
roughness_3_0.res roughness_3_1.res roughness_3_2.res roughness_3_3.res

godot/world/wreckage/ (6)
broken_frame.glb engine_bell.glb hull_fragment.glb hull_section.glb truss.glb weapon_sponson.glb
```

**Not checked:** Installed ship caches and replacement hull internals are outside this checkout and were not loaded. No windowed Godot, captures, frame measurements, or full check suite during issue 1070's work. The rendered symptoms and driver-stall suspicion were not tested on the GPU. No replay of a player save was needed for this read-only audit.
