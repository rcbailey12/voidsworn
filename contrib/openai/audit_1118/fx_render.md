# Battle effects and rendering audit: issue 1089

Main reviewed: `95e9e4f1a3f2ad01004a1ebc14965a8d608a5262`. The resumed checkpoint `4c85185d` had no file changes. The in-scope directories match this main commit in the merged checkout. I prioritized comfort, cleanup, and incorrect pictures on current hulls. I left out model-specific defects on replaced A4 hulls (R323).

## Top ten

1. Near the edge of the screen, the flash counter can let a fourth large flash through.
2. Turning on Reduce Flashing can leave a bright hit already on its way.
3. Leaving a battle can strand work that was cutting a ship into wreck pieces.
4. An Eclipse ship can come back while its old wreck is still on the board.
5. A broadside can start from the guns on the far side of the ship.
6. A resting shield never shows which sides are covered and which are open.
7. One torpedo hitting a shield can spend a flash slot by counting itself twice.
8. A ship that jumps away can still be struck by drifting wreckage.
9. A flying chip can take its paint from the wrong part of a damaged hull.
10. Heavy-ship slow motion can play before the actual explosion.

## Files read

All 136 tracked text files, 31,669 lines in total. This includes all 68 GDScript files (27,460 lines), the shaders embedded in them, tests, probes, launchers, metadata and the checked-in logs. No standalone shader files are tracked in these directories. The raw local checkout is pinned above. Ranges are inclusive, and the last-line prefixes are quoted as strings so tabs are visible.

```text
Path | Lines | First 40 characters of last line
godot/fx/API.md | 614 | "neither these tools nor their pictures r"
godot/fx/atlases/death/.gitignore | 2 | "!**/*.png.import"
godot/fx/atlases/death/bake_manifest.json | 81 | "}"
godot/fx/atlases/death/capital/cool_color.png.import | 41 | "detect_3d/compress_to=0"
godot/fx/atlases/death/capital/cool_flow.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/death/capital/cool_thickness.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/death/capital/flash_color.png.import | 41 | "detect_3d/compress_to=0"
godot/fx/atlases/death/capital/flash_flow.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/death/capital/flash_thickness.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/death/capital/vent_color.png.import | 41 | "detect_3d/compress_to=0"
godot/fx/atlases/death/capital/vent_flow.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/death/capital/vent_thickness.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/death/cruiser/cool_color.png.import | 41 | "detect_3d/compress_to=0"
godot/fx/atlases/death/cruiser/cool_flow.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/death/cruiser/cool_thickness.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/death/cruiser/flash_color.png.import | 41 | "detect_3d/compress_to=0"
godot/fx/atlases/death/cruiser/flash_flow.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/death/cruiser/flash_thickness.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/death/cruiser/vent_color.png.import | 41 | "detect_3d/compress_to=0"
godot/fx/atlases/death/cruiser/vent_flow.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/death/cruiser/vent_thickness.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/death/small/cool_color.png.import | 41 | "detect_3d/compress_to=0"
godot/fx/atlases/death/small/cool_flow.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/death/small/cool_thickness.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/death/small/flash_color.png.import | 41 | "detect_3d/compress_to=0"
godot/fx/atlases/death/small/flash_flow.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/death/small/flash_thickness.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/death/small/vent_color.png.import | 41 | "detect_3d/compress_to=0"
godot/fx/atlases/death/small/vent_flow.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/death/small/vent_thickness.png.import | 17 | "detect_3d/compress_to=0"
godot/fx/atlases/rebake/route_manifest.json | 364 | "}"
godot/fx/atlases/weapons/.gitignore | 2 | "!**/*.png.import"
godot/fx/atlases/weapons/bake_manifest.json | 54 | "}"
godot/fx/atlases/weapons/impact/impact_color.png.import | 41 | "detect_3d/compress_to=0"
godot/fx/atlases/weapons/impact/impact_flow.png.import | 40 | "detect_3d/compress_to=0"
godot/fx/atlases/weapons/impact/impact_thickness.png.import | 40 | "detect_3d/compress_to=0"
godot/fx/atlases/weapons/muzzle/muzzle_color.png.import | 41 | "detect_3d/compress_to=0"
godot/fx/atlases/weapons/muzzle/muzzle_flow.png.import | 40 | "detect_3d/compress_to=0"
godot/fx/atlases/weapons/muzzle/muzzle_thickness.png.import | 40 | "detect_3d/compress_to=0"
godot/fx/faction_look.gd | 69 | "\t_cache = {}"
godot/fx/faction_looks.json | 101 | "}"
godot/fx/fx.gd | 1564 | "\tHULL.start_late_watch()"
godot/fx/fx_breach.gd | 1869 | "\t\t_tube(pt, points, e.R * 0.06, e.R * 0."
godot/fx/fx_death.gd | 3073 | "\t\t\tl[\"base\"] = 0.7 * gate"
godot/fx/fx_fragments.gd | 364 | "\t\t\t_data.update(Image.create_from_data(D"
godot/fx/fx_hull.gd | 1475 | "\t\t(n as Node3D).transform = (tt[\"rest\"] "
godot/fx/fx_pool.gd | 255 | "\treturn [v, n, idx]"
godot/fx/fx_shaders.gd | 2423 | "\"\"\""
godot/fx/fx_ship.gd | 1565 | "\t\t_dmg_request(fx)"
godot/fx/fx_weapons.gd | 2020 | "\t\t\t(m as ShaderMaterial).set_shader_para"
godot/fx/gallery/README.md | 118 | "Pipeline compiles during the measured fi"
godot/fx/gallery/gallery.gd | 717 | "\treturn RenderingServer.frame_post_draw"
godot/fx/gallery/gallery.tscn | 6 | "script = ExtResource(\"1\")"
godot/fx/gallery/pc/g4_gallery.bat | 102 | "exit /b 0"
godot/fx/gallery/tonemap_check.py | 136 | "            np.mean([x[3] for x in hu]),"
godot/fx/test/DAMAGE_SURFACE.md | 36 | "table, and counts include equivalent spo"
godot/fx/test/attach_check.gd | 523 | "\treturn n"
godot/fx/test/authored_interiors_bench.gd | 16 | "\troot.add_child(load(\"res://bench/scene_"
godot/fx/test/authored_interiors_check.gd | 180 | "\treturn a"
godot/fx/test/authored_interiors_probe.gd | 135 | "\t\tpreload(\"res://tools/picture_provenanc"
godot/fx/test/check_damage_surface.bat | 49 | "exit /b 1"
godot/fx/test/check_destruction.bat | 53 | "exit /b 1"
godot/fx/test/check_squadrons.bat | 40 | "exit /b 1"
godot/fx/test/damage_alpha_check.gd | 97 | "\tquit(1 if failures else 0)"
godot/fx/test/damage_alpha_probe.gd | 137 | "\tPG.finish(0)"
godot/fx/test/damage_surface_check.gd | 136 | "\tquit(1 if failures else 0)"
godot/fx/test/damage_surface_probe.gd | 183 | "\tFileAccess.open(out.path_join(\"fleet.js"
godot/fx/test/damage_surface_sheets.py | 60 | "PICTURES.save(sheet, output / f\"{label}_"
godot/fx/test/death_leap_check.gd | 87 | "\tquit(1 if failures else 0)"
godot/fx/test/death_leap_probe.gd | 169 | "\treturn {\"frames\": samples.size(), \"mean"
godot/fx/test/death_plane_check.gd | 100 | "\tquit(1 if failures else 0)"
godot/fx/test/death_seam_check.gd | 270 | "\tquit(1 if failures else 0)"
godot/fx/test/death_spawn_check.gd | 202 | "\treturn best"
godot/fx/test/death_vent_strip_probe.gd | 188 | "\treturn c"
godot/fx/test/destruction_fleet_probe.gd | 89 | "\tPG.finish(0)"
godot/fx/test/destruction_staging_check.gd | 304 | "\tquit(1 if failures > 0 else 0)"
godot/fx/test/destruction_steps_check.gd | 209 | "\t\t\tedges[key] = int(edges.get(key, 0)) +"
godot/fx/test/fixtures/C19_51_unbaked.sheet.txt | 13 | "{\"cls\":\"Battle-barge\",\"fac\":\"corsair\",\"h"
godot/fx/test/flash_area_check.gd | 238 | "\treturn best"
godot/fx/test/fx_breach_probe.gd | 107 | "\tPG.finish(0)"
godot/fx/test/fx_cost_probe.gd | 86 | "\tPG.finish(0)"
godot/fx/test/fx_inside_probe.gd | 263 | "\tfx.camera = cam"
godot/fx/test/fx_marks_probe.gd | 216 | "\tPG.finish(0)"
godot/fx/test/fx_nozzle_probe.gd | 87 | "\tPG.finish(0)"
godot/fx/test/fx_probe.gd | 81 | "\tPG.finish(0)"
godot/fx/test/fx_proj_probe.gd | 68 | "\tPG.finish(0)"
godot/fx/test/fx_range_probe.gd | 356 | "\tprint(\"[range] wrote %s\" % path)"
godot/fx/test/fx_react_probe.gd | 133 | "\tPG.finish(0)"
godot/fx/test/fx_smoke.gd | 159 | "\tquit(1 if errors > 0 else 0)"
godot/fx/test/hit_fragments_check.gd | 197 | "\tquit(0 if failures == 0 else 1)"
godot/fx/test/hit_recipe_check.gd | 322 | "\tawait process_frame"
godot/fx/test/kill_slowmo_check.gd | 83 | "\tquit(1 if failures > 0 else 0)"
godot/fx/test/late_shader_check.gd | 88 | "\tquit(1 if failures else 0)"
godot/fx/test/playtest_batch1_check.gd | 179 | "\tcamera.position = organic.to_world(Vect"
godot/fx/test/playtest_batch3_check.gd | 94 | "\tquit(1 if failures else 0)"
godot/fx/test/results/.gitignore | 1 | "**/.runtime/"
godot/fx/test/results/dst4/box/probe.log | 26 | "[inside] voidsworn_frigate L=10.40 holes"
godot/fx/test/results/dst4/calm/probe.log | 26 | "[inside] done"
godot/fx/test/results/dst4/fleet/fleet.txt | 1 | "DESTRUCTION_FLEET ships=20 renderer=forw"
godot/fx/test/results/dst4/fleet/probe.log | 6 | "DESTRUCTION_FLEET ships=20 renderer=forw"
godot/fx/test/results/dst4/geometry.log | 9 | "DESTRUCTION_STEPS failures=0"
godot/fx/test/results/dst4/hulk/probe.log | 26 | "[inside] done"
godot/fx/test/results/dst4/low/probe.log | 24 | "[inside] done"
godot/fx/test/results/dst4/smoke.log | 6 | "FX_SMOKE particles=14856 lights=1 wrecks"
godot/fx/test/results/dst4/staging.log | 20 | "DESTRUCTION_STAGING failures=0"
godot/fx/test/ship_fire_probe.gd | 175 | "\tframe_i += 1"
godot/fx/test/squadron_check.gd | 122 | "\tquit(0 if failures == 0 else 1)"
godot/fx/test/squadron_probe.gd | 167 | "\tawait process_frame"
godot/fx/test/squadron_sheets.py | 62 | "    main()"
godot/fx/test/vent_clip.py | 172 | "    main()"
godot/fx/test/vent_look_probe.gd | 337 | "\tcam.snap()"
godot/fx/textures/README.md | 14 | "palettes; runtime faction colours still "
godot/fx/textures/make_kit.py | 73 | "    flake()"
godot/render/backdrop.gd | 67 | "\t_update()"
godot/render/board.gd | 923 | "\t\tBV.outline(blocker_highlights, hex_wor"
godot/render/build_assets.gd | 513 | "\t\t\t\treturn"
godot/render/camera_rig.gd | 208 | "\th_offset = -screen_shift / maxf(vh * 0."
godot/render/hull_table.gd | 67 | "\treturn Color(hex).srgb_to_linear()"
godot/render/look.gd | 227 | "\treturn m"
godot/render/look_rim.gd | 134 | "\treturn false"
godot/render/placeholder_guard.gd | 41 | "\t\t(loop as SceneTree).quit(exit_code)"
godot/render/ship_view.gd | 1516 | "\t\tring.rotation.y = -rotation.y"
godot/render/squadron_craft.gd | 206 | "\t_orb(Vector3(0.12, 0.11, 0), Vector3(0."
godot/render/squadron_wing.gd | 341 | "\tmesh.surface_end()"
godot/render/station_debris.gd | 39 | "\t_next_pose = _time + POSE_INTERVAL"
godot/render/test/fixtures/.gdignore | 1 | ""
godot/render/test/fixtures/T560_fx/T560_fx_check.json | 385 | "}"
godot/render/test/fixtures/T560_fx/T560_fx_export.json | 585 | "}"
godot/render/test/fixtures/T560_fx/manifest_entry.json | 24 | "}"
godot/render/test/formation_check.gd | 200 | "\tquit(0 if failures == 0 else 1)"
godot/render/test/hull_lift_check.gd | 136 | "\tquit(1 if fails else 0)"
godot/render/test/install_refresh_check.gd | 115 | "\tquit(0 if fails == 0 else 1)"
godot/render/test/installed_ship_check.gd | 80 | "\tquit(0 if fails.is_empty() else 1)"
godot/render/test/scale_check.gd | 223 | "\tquit(1)"
godot/render/test/turret_check.gd | 315 | "\tquit(1 if failures > 0 else 0)"
godot/render/test/variant_ship_check.gd | 132 | "\tquit(0 if fails == 0 else 1)"
```

Large files, ranges read:

| Path | Ranges |
| --- | --- |
| `godot/fx/API.md` | 1-306, 307-614 |
| `godot/fx/fx.gd` | 1-438, 439-848, 849-1564 |
| `godot/fx/fx_breach.gd` | 1-600, 601-1189, 1190-1609, 1610-1869 |
| `godot/fx/fx_death.gd` | 1-176, 177-611, 612-1048, 1049-1263, 1264-1661, 1662-1869, 1870-2229, 2230-2530, 2531-3073 |
| `godot/fx/fx_hull.gd` | 1-497, 498-990, 991-1475 |
| `godot/fx/fx_shaders.gd` | 1-439, 440-961, 962-1392, 1393-1921, 1922-2423 |
| `godot/fx/fx_ship.gd` | 1-420, 421-937, 938-1310, 1311-1565 |
| `godot/fx/fx_weapons.gd` | 1-525, 526-999, 1000-1479, 1480-2020 |
| `godot/render/ship_view.gd` | 1-550, 551-1075, 1076-1516 |

The 202 tracked binaries have no line counts. I checked every header; the two GLB fixtures' embedded JSON chunks also parsed. The following groups cover the full binary inventory (`git ls-tree -r --name-only 95e9e4f1 -- godot/fx godot/render` gives the expanded paths). In these groups braces indicate the literal alternatives in a path, and stars match tracked files only.

| Binary files | Count | Lines |
| --- | ---: | --- |
| `godot/fx/atlases/death/{capital,cruiser,small}/{cool,flash,vent}_{color,flow,thickness}.png` | 27 | n/a |
| `godot/fx/atlases/weapons/impact/impact_{color,flow,thickness}.png` | 3 | n/a |
| `godot/fx/atlases/weapons/muzzle/muzzle_{color,flow,thickness}.png` | 3 | n/a |
| `godot/fx/atlases/rebake/preview_{flash,impact}_{s0,s1,s2}.png` | 6 | n/a |
| `godot/fx/atlases/rebake/{s0,s1,s2}/death/{capital,cruiser,small}/flash_{color,flow,thickness}.png` | 27 | n/a |
| `godot/fx/atlases/rebake/{s0,s1,s2}/weapons/{impact,macro}/{flash,impact}_{color,flow,thickness}.png` | 36 | n/a |
| `godot/fx/textures/{beam_flow,hot_tail,lit_flake}.png` | 3 | n/a |
| `godot/fx/test/results/dst4/box/*.jpg` | 46 | n/a |
| `godot/fx/test/results/dst4/calm/*.jpg` | 16 | n/a |
| `godot/fx/test/results/dst4/hulk/*.jpg` | 16 | n/a |
| `godot/fx/test/results/dst4/low/*.jpg` | 14 | n/a |
| `godot/fx/test/results/dst4/fleet/fleet_{180,380,580}.png` | 3 | n/a |
| `godot/fx/test/fixtures/C19_51_unbaked.glb.gz` | 1 | n/a |
| `godot/render/test/fixtures/T560_fx/T560_fx.glb` | 1 | n/a |

## Confirmed findings

Each finding follows the live code path unless it is labelled as an isolated headless reproduction. The flash tests check the game's booking math and do not measure light output, photosensitivity compliance, or frame cost.

### 1. The counter undersizes flashes away from the camera's centre

- **Confirmed, OBSERVED, high confidence.** `godot/fx/fx.gd:718`: `camera.global_position.distance_to(p)`. The CPU uses the slant distance. The billboard projects its width at view depth (`godot/fx/fx_shaders.gd:117-128`, `251-306`). At equal depth the flash keeps its width as it moves sideways, while the counter shrinks its estimate. `fx.pop`, `fx.spr`, and the weapon hit paths call `flash_at`; the death-core path uses unconditional `flash_ok` and does not depend on this area test to book its own slot.
- **Show it:** `flash_projection.gd` projects a 151 px billboard entirely inside a 1920 x 1080 view at FOV 45, then calls `flash_at` four times with separate starts. It books 123 px and allows all four. The projected disc is 17,908 px2 against a 15,606 px2 limit. The existing `godot/fx/test/flash_area_check.gd:155,192-218` uses the diameter already supplied by the counter, so its independent area sum cannot see this size error.
- **Fix, 1 agent run:** Use the same camera projection and view-space depth as the draw path. Include a centre and edge case with pixel floors both on and off, and use projected geometry to check the booked size.

### 2. Mid-battle Reduce Flashing misses already queued baked hits

- **Confirmed, OBSERVED, high confidence.** `godot/fx/fx_weapons.gd:1705`: `var soft: bool = fx.reduce_flashing or not fx.flash_at`. `_staged_hit` makes the decision when a shot is booked, captures it in the delayed `l_staged_hit`, and writes the old `intensity` and `soft_flash` on arrival (`1713-1740`). The routed flash shader uses those material values, with no live `fx_calm` term on this branch (`godot/fx/fx_shaders.gd:133-172`). `_burst` has the same early decision for muzzle flashes (`godot/fx/fx_weapons.gd:605-622`).
- **Show it:** `godot/scenes/battle/battle.gd:1951` schedules the volley; `godot/fx/fx_weapons.gd:511-515,1357-1401,1755-1760` schedules its hit. The travelling-torpedo path also schedules ahead at `fx_weapons.gd:1965-1980`. Toggle through the battle menu (`godot/scenes/battle/battle.gd:4031,4088-4089` to `1074-1079`) before impact. The setter in `godot/fx/fx.gd:69-72` only updates `fx_calm`; a queued normal torpedo hull flash still receives 5.2 intensity and 0.16 s lifetime. `godot/fx/test/hit_recipe_check.gd:63-111` sets calm before scheduling and does not exercise this transition.
- **Fix, 1 agent run:** Recheck comfort when the flash appears and give in-flight and already-visible effects a shared live calm override. Keep the permit and the colour, peak and timing of the rendered fallback in one place.

### 3. Scene exit can discard the only handle to a death-cut worker

- **Confirmed, OBSERVED, high confidence for the missed join.** `godot/fx/fx_death.gd:1154`: `fx.later(fx.now + 0.25, func l_collect() -> void: _collect_later(fx, tid))`. The worker task owns the cut job, which contains arrays and materials (`1098-1146`). `_lance_recut` detaches its old task (`1052-1057`); `_break_up_inner` also detaches a newer task if it uses a previous cut (`2625-2635`). In either case, when the task is still running, its only cleanup is a pending callback.
- **Show it:** Trigger either branch with a running cut, then leave the battle before the collector calls `WorkerThreadPool.wait_for_task_completion`. `godot/fx/fx.gd:172-202` joins only tasks still named on ships, then clears `_later`. The detached task is never joined, even if it finished after the callback was queued. `remove_ship` also does not join the ship's regular cut: it erases the registry entry after a teardown that joins only damage work (`fx.gd:1140-1145`, `godot/fx/fx_ship.gd:185-201,1310-1313`). `_prebuild` will normally collect that cut later, but release cannot discover it after removal. The confirmed fault is the lost cleanup and retained task data; no shutdown crash was reproduced.
- **Fix, 1 agent run:** Have the FX session own a set of every outstanding cut ID from submission until one successful join. Finish or hand off on ship removal and drain the set during release before clearing callbacks.

### 4. An Eclipse ship reassembles without taking its wreck back

- **Confirmed, OBSERVED, high confidence.** `godot/render/ship_view.gd:379`: `gi.material_override = null`. `revive()` unhides the original mesh but does not clear the death overlay or restore transforms and per-surface overrides. `_tell` writes a tear overlay and `_power_down_step` writes the per-surface power-down materials (`godot/fx/fx_death.gd:2064-2067,2251-2256`). The separate wreck nodes are put under `phys_root` (`2703-2725`) and stay registered independently (`2780-2783`).
- **Show it:** Eclipse `legionRise` emits `risen` (`godot/rules/rules.gd:1902-1915`). `godot/scenes/battle/battle.gd:1319-1333` calls `revive`, removes and re-adds the FX ship on the same root, and erases the rules-side wreck marker. It never calls `clear_wreck`, and `fx_ship.teardown` removes attached effects only. The old pieces can keep moving and playing their remaining secondaries while the reassembled ship is visible, with the first death's materials still installed. `godot/fx/test/death_plane_check.gd:83-92` checks visible/dead flags and deliberately expects an independent wreck to survive removal; it does not cover reassembly.
- **Fix, 1 agent run:** Give the risen event a single reassembly path that clears its old wreck and rebuilds or restores the live mesh pose and materials before registering and syncing it at the revived health.

### 5. Exact slot matches can fire from the wrong flank

- **Confirmed, OBSERVED, high confidence.** `godot/fx/fx_hull.gd:988`: `same.append(pt)`. `_gun_points` checks `_bears` for the by-weapon fallback but not for an exact slot and weapon match or for the slot-only fallback (`983-1001`). `guns` then rotates through that full list (`937-958`); `_volley` takes the chosen origin and builds the shot to the target (`godot/fx/fx_weapons.gd:214-227,257-268`). The live battle passes the slot at `godot/scenes/battle/battle.gd:1951`.
- **Show it:** `broadside_mount.gd` feeds the production reader a stand-in with port and starboard hard points assigned to the same slot. Four of eight selected barrels face away from the target. The same selection issue can choose a turret outside its reach; `turret_aim` clamps the pose, but the effect still travels to the requested target. No installed hull is claimed to match the stand-in's exact slot layout.
- **Fix, 1 agent run:** Apply bearing and reachable-arc checks in every authored candidate tier, keeping the existing preference for the correct slot among usable muzzles. Define an explicit fallback for a legal rules shot with no usable socket.

### 6. The shield skin never learns which sides are open

- **Confirmed, OBSERVED, high confidence.** `godot/fx/fx_ship.gd:341`: `_shield_mi.visible = fx.now < _shield_until`. Only hit, break and regen timers keep it visible. `sync` sums `sh` for the regen cue and drops the individual sides (`969-977`). `godot/fx/fx_shaders.gd:1197-1208,1244-1285,1324-1382` has transient hits, break and regen uniforms, with no resting coverage term. Both fitted and egg modes use this shader (`fx_ship.gd:421-426`).
- **Show it:** Follow a quiet shielded ship from `godot/scenes/battle/battle.gd:830-835,892-896` into `fx_ship.sync` and `update`, or wait out any transient. The rules view has the pool and facing state (`godot/rules/battle_api.gd:224-225`); the HUD can show values, but the 3D shield draws neither the live rim nor the dark gaps from RULEBOOK 6.11.
- **Fix, 2 agent runs:** Pass the existing effective coverage state to the shader in the same quadrant order as the HUD. Keep the quiet rim active only where the shield works, for both meshes, and verify the share of the skin hidden by an open side.

### 7. A torpedo shield crackle books its own picture twice

- **Confirmed, OBSERVED, high confidence.** `godot/fx/fx_weapons.gd:1555`: `fx.spr(p + n * 0.15 * k, t, life, col, power`. `_shield_crackle` first calls `flash_at` (`1552`), then submits a kind 13 sprite at power 4.2 for a normal torpedo. `spr` rebooks short, bright kind 13 sprites (`godot/fx/fx.gd:31-34,448-457`). The first booking's disc is remembered and contributes to the area test of the second. One 110 px picture becomes two overlapping 110 px entries in the budget.
- **Show it:** `shield_flash_booking.gd` calls the production crackle with the cruiser-size 110 px floor (one disc is about 9,503 px2). It logs two bookings and one counted flash. `godot/fx/test/hit_recipe_check.gd:308-319` compares the largest logged diameter and therefore cannot catch two entries of the same width.
- **Fix, 1 agent run:** Book the final position and extent once, then emit the already-approved sprite through the same unchecked emission path as `fx.pop`. Verify the normal and soft paths share that contract.

### 8. A jump can leave an invisible collider behind

- **Confirmed, OBSERVED, high confidence.** `godot/fx/fx_ship.gd:1537`: `gone = true`. The jump callback hides the hull, engine and trails (`1536-1544`), but never removes the body under the root. On High and Max, `godot/fx/fx_death.gd:593-607` creates that body on `HULL_LAYER`; flying death debris collides with that layer (`436-458,2688-2691`). The death path explicitly frees the body (`1889-1891`), the exit path does not.
- **Show it:** In `godot/scenes/battle/battle.gd:1472-1481`, let a ship leave using G4 FX. The battle marks the view dead but keeps that view root; `fx_ship.update` skips it once `gone` is set (`304-306`). Wreck pieces travelling through that hex still meet the hidden ship's shape. The rules do not use this collider for hit or movement decisions.
- **Fix, 1 agent run:** Share the collider and attached-effect shutdown across jump, death and removal. Free the body when the ship disappears and let only already emitted effects with finite lives finish.

### 9. Fragment material lookup uses the pre-damage hit index on the post-damage mesh

- **Confirmed, OBSERVED, high confidence for the index mismatch.** `godot/fx/fx_fragments.gd:201`: `var corners := mesh.surface_get_array_index_len(s)`. The ray hits the original BVH (`godot/fx/fx_hull.gd:441-469,490-494`). The hit face number is decoded against the current `mi.mesh` and its UV arrays (`fx_fragments.gd:188-237`). The damage rebuild can add triangles to an earlier surface (`godot/fx/fx_breach.gd:687-704,1055-1068`) and swaps the whole mesh (`1660-1667`) without rebuilding that BVH.
- **Show it:** Make a two-surface hull with separate paints. Hit the second surface before and after a dent refines the first. If the first had one triangle and now has two, original face 1 (the second surface) is decoded as a triangle on the first; even its UV interpolation is now in the wrong surface. `godot/fx/test/hit_fragments_check.gd:131-172` exercises an intact two-surface mesh only. The live callers are `_throw_debris` and the hits that call it (`godot/fx/fx_weapons.gd:1245-1263`).
- **Fix, 1 agent run:** Resolve the face ID against the geometry and surface offsets used when the BVH was built, including original UV triplets, or replace the BVH and mapping together when geometry changes.

### 10. A delayed fracture leaves slow motion on the old schedule

- **Confirmed, OBSERVED, high confidence given the late cut branch.** `godot/fx/fx.gd:1239`: `var core := float(s.get_meta("death_start")) + float(tl.cut) + float(tl.core_delay)`. `death` schedules the slowdown from that nominal timestamp (`1237-1244`). When the first cut is still running and no previous cut exists, `_break_up_when_ready` retries every 0.05 FX s and never consumes its passed `deadline` (`godot/fx/fx_death.gd:2170-2177`). The real flash gets scheduled at actual break time plus `core_delay` (`2619,2784-2803`).
- **Show it:** Kill a cruiser whose first cut is still running at its split and keep the worker pending past the nominal core. The slowdown fires at the old time; the real core cannot fire then because its wreck node does not exist. The battle's camera hold is based on that same nominal time (`godot/scenes/battle/battle.gd:2197-2206,2245-2254`). `godot/fx/test/kill_slowmo_check.gd:47-60` compares against the advertised time, not actual flash birth. How often real installed hulls hit this branch was not measured.
- **Fix, 1 agent run:** Tie the beat and camera hold to actual FX core readiness, with a bounded wait or defined fallback when geometry misses its deadline. Use a deliberately delayed cut to check the cue and picture stay together.

## Suspected correctness and lifetime issues

- **Suspected, INFERRED, medium confidence.** `godot/fx/fx_ship.gd:461`: `var key := str([hull.code, hull.box, hull.core, hull.tri_count])`. The fitted shield's process-wide cache has no bound, and the key can vary with root-frame rounding, bob pose at re-registration, or a changed mesh that happens to retain the same bounds and triangle count. Exact impact on current installed hulls is unverified. Show it by registering the same fitted ship at multiple turns and bob phases across battles and checking cache entries and generated contour equality. Key it by stable, canonical mesh/version and transforms; give the cache a lifetime or cap. **1 agent run.**
- **Suspected, INFERRED, medium confidence.** `godot/render/ship_view.gd:1422`: `static var _pm: StandardMaterial3D = null`. `_puff_mat` owns a texture-backed cached material, and `clear_static` clears `_gt` but leaves `_pm` (`48-51,1426-1438`). The same cleanup contract describes an earlier Windows shutdown crash from GPU resources held in statics; this exact resource's effect on exit was not reproduced. Show it with ship movement followed by normal quit and inspect resource release before the renderer shuts down. Drop the puff material before its texture in `clear_static`. **1 agent run.**

## Frame-cost suspects for issue 1070

1. **unmeasured guess, INFERRED, high confidence in repeated work.** `godot/fx/fx_ship.gd:406`: `am.clear_surfaces()`. `_update_trails` calls `_trail_mesh` for every nozzle every step, rebuilding arrays and uploading a surface even between samples (`344-408`). Contrast with `godot/render/squadron_wing.gd:311-316`, which rebuilds only for changed history. Isolate the ship trail pass with the same history and a shader-age variant. Update only changed geometry and carry birth times in the mesh. **1 agent run.**
2. **unmeasured guess, INFERRED, high confidence in repeated work.** `godot/fx/fx_death.gd:3037`: `(nd as RigidBody3D).linear_velocity *= speed / prev`. Every rigid wreck piece gets two velocity writes each frame, even when the speed ratio is one or heat is cold; `godot/fx/fx_death.gd:436-475` also keeps up to 360 pooled debris bodies in the physics world until scene exit. Isolate Jolt with long-cooled wreck fields and check awake body counts with unchanged writes removed. Write on speed changes only and give spent small pieces a bounded active-physics phase if the measurement warrants it. **1 agent run.**
3. **unmeasured guess, INFERRED, high confidence in repeated work.** `godot/fx/fx.gd:897`: `ev.sort_custom(func(a: Array, b: Array)`. The light pool allocates and sorts a full list per step, even to choose a few lights on Low; the same step scans and partitions the complete pending callback queue (`415-429,860-908`). Isolate light selection from callback scheduling under dense salvos. Reuse buffers and select only the visible pool's best candidates; make pending work cheap when nothing is due. **1 agent run.**
4. **unmeasured guess, INFERRED, medium confidence.** `godot/fx/fx_pool.gd:137`: `var n = cap * vpp`. Its fixed-capacity draw is set up at `109-156` and expired vertices are clipped in the shaders, e.g. `godot/fx/fx_shaders.gd:230-231`. A sparse battle still submits the full visible pool meshes. Compare quiet-frame vertex work with the same scene and only active particle ranges. If it matters, keep a compact live draw range while preserving the existing total capacity. **2 agent runs.**
5. **unmeasured guess, INFERRED, high confidence in repeated work.** `godot/fx/fx_weapons.gd:1675`: `var code: String = SH.DEATH_FLIPBOOK.replace`. Two staged-hit pictures generate the same derived shader string repeatedly, create new meshes/materials, then queue frees (`1713-1747`). Cached compiled shaders do not avoid this assembly. Count first-use and steady hit CPU work separately; cache the derived source and shared quad before considering a bounded node pool. **1 agent run.**
6. **unmeasured guess for frame impact, OBSERVED setting mismatch, high confidence.** `godot/fx/gallery/gallery.gd:164`: `vp.msaa_3d = Viewport.MSAA_4X if quality != "low"`. Gallery `--quality high` uses 4x MSAA even though in-game High uses 2x (`godot/scenes/battle/battle.gd:358-363`). Compare the viewport's selected MSAA between the two entry points before using the gallery as a High-quality control. Share the tier-to-MSAA mapping. **1 agent run.**

## Recommended first job

Fix the flash permit path first: match the draw projection, enforce live Reduce Flashing and book each visual once. These are shared paths with headless evidence for the projection and double-booking faults. Follow with worker ownership and Eclipse reassembly.

## Impact sweep

- **Callers:** No production function, constant or field changed. Repo-wide searches traced the reported paths through battle fire (including travelling torpedoes), live options, death, jump, reassembly and scene exit, plus their gallery and check callers. The three new scripts have independent `SceneTree` entry points.
- **Saves:** Verified by source comparison and tracing `godot/campaign/campaign.gd:417-466` and `godot/main/main.gd:154-169`. Neither format, migration nor default changed, and the probes do not open or write a player save. No old profile was loaded for this read-only audit.
- **Twins:** Compared `battle.js`, `core.js`, `data.js` and both Godot table files against main. They match. The reported fixes would consume existing rule results in presentation. No table export or parity run was needed for an audit-only diff.
- **UI:** Traced Reduce Flashing from title and battle menu to `main.gd:204-226` and `battle.gd:1074-1081`. The battle ledger already reads the existing pool and side values (`godot/ui/battle/ledger.gd:443,606-612`); the campaign map, fleet panels and intel need no new field for these findings.
- **CI:** `.github/workflows/checks.yml` runs standing checks, JS/Godot rules and campaign parity, the Godot-only rules safety net, and Godot game load/list/bot-battle/fixture checks. The three intentionally red repros are under `contrib/openai/audit_1118/tests/fx_render/` and run by hand. The brief permits no edits to the standing runner or Godot list; wire passing regressions in with the fixes.

## Checks run

From the repo root, use the Godot 4.7.2 console executable as `godot`:

```text
godot --headless --path godot --script ../contrib/openai/audit_1118/tests/fx_render/flash_projection.gd
FAIL flash projection: 151.0 px shown, 123 px booked, 17908 px2 shown, 15606 px2 limit, 4 bright in one second (expected 3)

godot --headless --path godot --script ../contrib/openai/audit_1118/tests/fx_render/broadside_mount.gd
FAIL broadside mounts: 4 of 8 shots did not use an authored muzzle facing the target (expected 0)

godot --headless --path godot --script ../contrib/openai/audit_1118/tests/fx_render/shield_flash_booking.gd
FAIL shield torpedo flash: 2 bookings, 1 counted (expected 1 booking, 0 counted)

godot --headless --path godot --script res://fx/test/late_shader_check.gd
LATE_SHADER failures=0
```

All three repros exited 1 as expected. The existing late shader check passed. Node readbacks compared the inventory to Git's tracked list, checked atlas import sources and binary headers, and verified the deliverable and its source quotes. Results:

```text
PASS inventory: 136 text files, 31669 lines, 27460 GDScript lines and 202 binaries
PASS atlas import sources and binary headers
PASS deliverable scope, ASCII, whitespace and 18 source quotes
```

## Not checked

No visual captures, image-pixel verdicts, windowed Godot, performance timings, full checks or parity run. The brief reserves the PC for issue 1070 and allows focused headless checks. Cached build hulls and replaced A4 ship looks were not used as evidence; paths outside the audited folders were read only to verify callers, saves, UI and CI.
