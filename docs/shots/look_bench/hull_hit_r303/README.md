R303 replaces the bare-hull impact with a hot baked core, a fast spark fan, tumbling thin fragments and compact dark soot. The flat torpedo ring and the energy-hit disc are removed. The existing bloom, event lights and hull breach marks are reused. No new post-process pass or textures.

Changed game files: `godot/fx/fx_weapons.gd` and `godot/fx/fx.gd`. The latter adds the bounded torn-plate pool, fading material and warm-up. Metal afterglow now follows the actual hull frame while it recoils and turns. Glass keeps iridescent fragments and its native wound; Chorus keeps tissue, green droplets and fumes. Energy contacts retain their weapon colour.

Before: main `820cbaca88b8`. After: the same base plus working diff `67aa4415398eb41e3d6e188341bcfd38a1ceb1176c4304ec2f569ed30cca45bf`. Every sheet carries its source revision and the stage `installed in game`. Board visual review is pending.

All sheets are 1280 by 660. Camera 170 cells preserve 1080p source pixels at 1:1; camera 60 uses a 640 by 450 source crop shown at 40 percent. Columns are the exact impact anchor, +0.1, +0.3, +0.6 and +1.5 s. Pre-hit, +0.033 s and +3.5 s cooling frames remain in the input strips. One shot, no shield, fixed 60 Hz clock and seeds. Torpedo and heavy battery fire from a Sunward cruiser; the physical light autocannon fires from a Hegemony cruiser.

| Target | Weapon | Camera 170 | Camera 60 |
|---|---|---|---|
| C15s_23, Ashfall Hullbreakers | torpedo | [Strip](C15s_23_torpedo_before_after_c170.png) | [Strip](C15s_23_torpedo_before_after_c60.png) |
| C15s_23, Ashfall Hullbreakers | heavy | [Strip](C15s_23_heavy_before_after_c170.png) | [Strip](C15s_23_heavy_before_after_c60.png) |
| C15s_23, Ashfall Hullbreakers | light | [Strip](C15s_23_light_before_after_c170.png) | [Strip](C15s_23_light_before_after_c60.png) |
| H9_23, Hegemony Navy | torpedo | [Strip](H9_23_torpedo_before_after_c170.png) | [Strip](H9_23_torpedo_before_after_c60.png) |
| H9_23, Hegemony Navy | heavy | [Strip](H9_23_heavy_before_after_c170.png) | [Strip](H9_23_heavy_before_after_c60.png) |
| H9_23, Hegemony Navy | light | [Strip](H9_23_light_before_after_c170.png) | [Strip](H9_23_light_before_after_c60.png) |
| D21_23, Eclipse | torpedo | [Strip](D21_23_torpedo_before_after_c170.png) | [Strip](D21_23_torpedo_before_after_c60.png) |
| D21_23, Eclipse | heavy | [Strip](D21_23_heavy_before_after_c170.png) | [Strip](D21_23_heavy_before_after_c60.png) |
| D21_23, Eclipse | light | [Strip](D21_23_light_before_after_c170.png) | [Strip](D21_23_light_before_after_c60.png) |
| I15_11, Glasswrights | torpedo material proof | [Strip](I15_11_torpedo_before_after_c170.png) | [Strip](I15_11_torpedo_before_after_c60.png) |
| B21_11, Chorus | torpedo material proof | [Strip](B21_11_torpedo_before_after_c170.png) | [Strip](B21_11_torpedo_before_after_c60.png) |

| Scene gate | 1080p frame median, ms | 4K GPU median, ms |
|---|---|---|
| Main, one session | 6.202 | 5.397 |
| After, three sessions | 4.500 to 5.660 | 5.335 to 5.455 |

PASS against 12.5 ms. The standing #207 20-ship storm scene ran through the watchdog with an exclusive GPU claim, 120 warm-up frames and 720 measured frames per mode and session. `res_2160` draws the 3D scene at 3840 by 2160 with the standing 1080p HUD. These small differences do not establish a speed gain. Raw measurements: [main](gate_before.json), [after](gate_after.json).

The flash rungs remain 140 px torpedo, 64 px heavy shell and 44 px light shell at 1080p on a cruiser. Normal flashes last 0.16 / 0.12 / 0.12 s; the baked bodies last 0.65 / 0.46 / 0.46 s. Full white heat ends before 0.25 s. Physical-hit spark fans use 0.6 to 1.15 s, plates 3.5 to 6 s with a final fade, soot 2 to 2.6 s and attached metal heat 2.5 to 4 s. Reduced flashing softens both flash and body.

Measured visible hot-core widths at camera 170 follow. These are the largest connected warm component above the stated luminance and pre-hit difference thresholds, over impact, +0.033 and +0.1 s. They exclude faint bloom and disconnected sparks and can be clipped by hull occlusion, so they are not the full flash diameter. [Method and all frames](measurements.json).

| Target and weapon | Before, px | After, px |
|---|---|---|
| C15s_23_torpedo | 19 | 79 |
| C15s_23_heavy | 16 | 27 |
| C15s_23_light | 17 | 17 |
| H9_23_torpedo | 41 | 102 |
| H9_23_heavy | 36 | 55 |
| H9_23_light | 27 | 35 |
| D21_23_torpedo | 46 | 115 |
| D21_23_heavy | 46 | 60 |
| D21_23_light | 45 | 46 |

Checks: standing suite 60 PASS, 2 recorded KNOWN results, zero new failures; full `godot/fx/test/check_destruction.bat` PASS; focused R303 check 51 cases PASS, including metal, glass, tissue, low quality, reduced flashing, outward matter, fixed plate strides and attached heat; scale check PASS with its six existing known rows; all 22 sheets pass provenance and size verification. [Check evidence and file hashes](checks.json), [capture settings](capture_settings.json), [moments](moments.json), [focused cases](hull_hit_checks.json).

All 22 final after strips and all 22 baseline strips repeat pixel for pixel. [Repeat comparisons](repeatability.json).

Existing diagnostics: the spawn guard prints two missing `spawn_frame` metadata messages on unchanged main and on this change; both runs still return PASS with 33 recorded pictures and zero stray spawns. The existing `exterior_alpha` hull shader is the only late shader in both baseline and final captures and the scene gate. The new impact and plate shaders are warmed. The standing known results are seven listed findings and twelve constant differences. None was changed in this effects job.

The identical sheets and reports, raw kept input strips and check logs are saved in `C:\Users\rcbai\Downloads\voidsworn_test\board\issue-928\shots`. Inputs are under `sources/before_r2`, `sources/before_light_r2` and `sources/after_final_r2`; camera-60 inputs are `sources/before_wide_r2` and `sources/after_wide_r2`. Earlier tuning runs are excluded. Scratch checks and warm passes remain in TEMP. No requested capture or check was skipped. No commit or push was made.
