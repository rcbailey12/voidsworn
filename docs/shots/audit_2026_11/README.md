# Outside audit pass 2 (graphics and effects): evidence images

Evidence for `contrib/claude_fable/reviews/audit_pass2_graphics_effects_2026_11.md`.

- Game commit: `70e87f2345adf171f4dd7a1a5aa52ac1d43e8338` (main), cloned on Ryan's PC into `Downloads\voidsworn_test\audit2\repo`.
- Ship files, `godot\gen` and the import cache were copied (copy only) from `work217\issue-281-deepseekpro\20261109_153014\repo`.
- Machine: Ryan's PC, RTX 5080, Godot 4.7.2, Forward+, quality max. Captured Nov 10 2026, 00:20 to 00:43 UTC.
- 43 images. 41 are fresh captures from that run. `ships_05` puts repo concept art next to fresh captures. `fx_17` is built from files in the repo and is not a capture.
- Stills were saved as PNG or JPG at 1920x1080 or more, then shrunk to JPG here (each under 600 KB).

## How each group was made

| Group | Tool | Notes |
|---|---|---|
| `*_gallery_*` | `godot/fx/gallery/gallery.tscn -- --shots DIR --res 2560x1440 --quality max` | The repo's own effects reel. Free camera, closer than the game allows. |
| `ships_01` to `ships_04`, `fx_01` to `fx_09`, `fx_18`, `fx_19`, `sh_01`, `sh_02`, `sh_05` | `audit_probe.gd` (auditor's probe, PC checkout only, copied from the pattern of `godot/fx/test/vent_look_probe.gd`) | Real ShipView hulls, real world, real effects code on a fixed effect clock. Two ships 68 units apart. Sheets read left to right, top to bottom. |
| `map_01`, `map_02` | `godot/bench/scene_gate.tscn -- --still` | The real battle scene, 20 ships, HUD on. |
| `map_03` to `map_10`, `map_14` | `godot/world/world_shots.tscn` (default run, and `--looks cine --terrain`) | The real battle scene, HUD hidden. |
| `map_11` | `battle.tscn -- --map planet --seed 5 --planet-shot` | The board planet. |
| `map_12` | `campaign.tscn -- mapshots` | Campaign sector map. |
| `map_15`, `map_16` | `battle.tscn -- --scenario s2 --shots` and `-- --fac chorus --map storm --seed 11 --shots` | A whole battle played by the bot, with the game's own fixed screenshot moments. |

Camera notes for the probe images:

- "closest zoom" is the game camera at its nearest allowed distance (`camera_rig.gd` `min_r` 26). The probe asked for less and the rig clamped it.
- "battle camera" in `ships_04` is the default distance (170). The cells are 1 to 1 pixel crops of a 1080p frame.
- "battle view crop" (`fx_07`, `fx_08`, `fx_19`, `sh_05`) is the camera 120 units out, middle 60 percent of the frame.
- `fx_18` is 46 units out, `sh_01` and `sh_02` 38 units, `fx_09` 30 units.
- "30fps" sheets hold 16 frames, one every 1/30 s, starting 0.07 s before the first impact.

## The images

| File | What it shows |
|---|---|
| ships_01_cruisers_closest_zoom.jpg | The six faction cruisers at the closest zoom the game allows. |
| ships_02_flagships.jpg | The six flagships. |
| ships_03_frigates_destroyers.jpg | Six frigates (rows 1 and 2) and six destroyers (rows 3 and 4). |
| ships_04_battle_camera_1to1_crops.jpg | Cruisers and frigates at the default battle camera, true pixel size. |
| ships_05_concept_vs_game_cruisers.jpg | Concept art from `docs/ship_pipeline/concepts/` next to the same ship in the game. |
| ships_06_gallery_six_flagships.jpg | Gallery still g01: the six flagships together. |
| fx_01_torpedo_hit_30fps_closest_zoom.jpg | Sunward torpedo on a Hegemony cruiser hull. |
| fx_02_macro_hit_30fps_closest_zoom.jpg | Heavy macro battery, four shells, on a Chorus cruiser. |
| fx_03_gauss_hit_30fps_closest_zoom.jpg | Eclipse gauss on a Sunward cruiser. |
| fx_04_las_hit_30fps_closest_zoom.jpg | Sunward turret (las) on an Eclipse cruiser. |
| fx_06_lance_hit_30fps_closest_zoom.jpg | Sunward lance on a Hullbreaker cruiser. |
| fx_07_macro_battle_view_crop.jpg | The macro volley from the battle view, 13 moments. |
| fx_08_torpedo_battle_view_crop.jpg | The torpedo from the battle view, 13 moments. |
| fx_09_macro_muzzle.jpg | Macro battery muzzle, 8 moments. |
| fx_10_gallery_gauss_lines.jpg | Gallery g09: gauss. |
| fx_11_gallery_bio_splash_lines.jpg | Gallery g10b: Chorus bio splash. |
| fx_12_gallery_prism_bars_on_shield.jpg | Gallery g04: Glasswright prism needles on the Hegemony shield. |
| fx_13_gallery_ion_beam.jpg | Gallery g08: Hegemony ion beam on the Glasswright shield. |
| fx_16_gallery_torpedo_hit.jpg | Gallery g13: torpedo hit. |
| fx_17_flipbook_atlas_fill_from_repo.jpg | NOT a capture. `godot/fx/atlases/weapons/impact/impact_color.png` (left) and `death/capital/flash_color.png` (right) from the pinned commit, drawn on dark grey. |
| fx_18_death_cruiser_close.jpg | Sunward cruiser death, cause "big", 13 moments over 7 s. |
| fx_19_death_frigate_battle_view_crop.jpg | Hullbreaker frigate death from the battle view. |
| fx_20_gallery_deaths.jpg | Gallery g21a, g21, g21b, g22, g23, g24. |
| sh_01_hegemony_hit_and_break.jpg | Hegemony cruiser shield: idle, two gauss hits, then the break. 15 moments. |
| sh_02_voidsworn_hit_and_break.jpg | The same for a Sunward cruiser. |
| sh_05_hegemony_battle_view_crop.jpg | The Hegemony shield sequence from the battle view. |
| sh_06_gallery_break_hegemony.jpg | Gallery g17. |
| sh_07_gallery_break_voidsworn.jpg | Gallery g16. |
| map_01_battle_scene_20_ships_wide.jpg | The gate scene, wide, at effect step 300. |
| map_02_battle_scene_close_dying_ship.jpg | The gate scene, close on the third dying ship, step 400. |
| map_03_station_default_camera.jpg | Station map, default camera. |
| map_04_station_low_camera.jpg | Station map, low camera. |
| map_05_nebula_storm_default_camera.jpg | Storm map, default camera. |
| map_06_nebula_hex_close.jpg | Close on nebula hexes. |
| map_07_ion_storm_hex_close.jpg | Close on ion storm hexes. |
| map_08_rocks_close.jpg | Close on rock and debris hexes. |
| map_09_backdrops_sheet_a.jpg | Planet map, graveyard, dead star. |
| map_10_backdrops_sheet_b.jpg | Crystal belt, deep storm, storm rocks, planet map rocks, ice belt. |
| map_11_board_planet.jpg | The board planet. |
| map_12_campaign_map.jpg | Campaign sector map, start of a run. |
| map_14_board_close_look.jpg | The board close up with a move preview. |
| map_15_real_battle_station_map_bot_play.jpg | Bot battle on the station map: start, two fire moments, end. |
| map_16_real_battle_chorus_storm_bot_play.jpg | Bot battle against the Chorus on a storm map: start and three fire moments. |

## Known limits

- The gallery printed a sky bake error at start (`world_bake.gd` line 24, "Parent node is busy setting up children"). Its stills have stars but no nebula.
- The `mapshots` tool's fifth still came out as the "Preparing the sector..." loading screen and is not included.
- The probe turns camera shake off. It does not flag any ship as a flagship.
