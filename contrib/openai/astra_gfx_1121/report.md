# Astra pass 2: graphics, effects and physics

Reviewed `20f34d013acc7629c142925c1948a2e8c36029e8` for issue 1456. Eight new findings. Start with #3: the same moving hull displaced a resting plate by 4 world units with physics active and by exactly 0 with the battle's idle gate. The headless probes below also confirmed the scale mismatch in #1 and the timing mechanisms in #4 and #5. Player-visible consequences in the table are INFERRED; no rendered battle was used.

| # | Finding | Evidence | What the player sees | Smallest fix | Known-item check |
|---|---|---|---|---|---|
| 1 | A shrinking wreck keeps its full-size collider. | INFERRED, high. `godot/fx/fx_death.gd:3295-3300` attaches a collision shape to the body. Shrink starts at 1.5 effect seconds (:3775); the body can collide for four seconds after release (:26, :3576). `_draw_in` scales only mesh children: `if not (ch is MeshInstance3D): continue` (:3884-3887). The hull collision mask stays on (:3892-3894). | On a physics tier, a blocking wreck that has to shrink can get shoved by a passing hull before the hull touches any visible metal. | When a section first shrinks, use the existing handoff to scripted drift before resizing it, or resize its collision shape along with its mesh if contact is still wanted. | New: contact outside a visible section, not small-triangle picking, debris readability or cost at death. |
| 2 | Loose plates miss the kill slow motion. | INFERRED, high. The death beat caps the effect speed at 0.35 (`godot/fx/fx.gd:374-380`) without changing engine time (:111). The same breakup throws pooled plates (`godot/fx/fx_death.gd:3243-3245`) and releases sections. Only sections get `node.linear_velocity = vel * fx.anim_speed()` (:3574) and subsequent speed ratios (:3703-3717). Plates get unscaled launch and spin (:568-572); even their settle deadline runs on the slower clock (:578, :604-613). | During a large kill with slow motion enabled, loose metal can race ahead of the slowing hull, then keep flying while its settle timer catches up. | Apply the same launch multiplier and speed-change ratio to awake plates as to sections. Keep the existing effect-time settle deadline. | New: two clocks in the same shot, not how large or bright the debris looks. |
| 3 | A moving ship cannot wake settled plates once Jolt is switched off. | INFERRED, high. `godot/fx/fx_death.gd:586-588` expects a hull contact to wake a sleeping plate. In `godot/fx/fx.gd:431-444`, only an already-awake, unfrozen rigid body keeps the space active: `_set_physics_awake(awake)`. Normal hull movement is not among the callers of `wake_physics()`; the live hull collider at `godot/fx/fx_death.gd:743-755` is not a rigid body that can pass this gate. | Once the last piece rests, a ship crossing loose plates can pass straight through them. Make the same crossing while another breakup keeps physics alive and the plates can be knocked aside. | Wake the space for a moving hull near settled debris, for the duration of its crossing. Keep the idle gate for an empty board. | New: missed contact after sleep, not Jolt worker exhaustion or death-frame cost. |
| 4 | Hull recoil loses time below 30 frames per effect second. | INFERRED, high. `godot/fx/fx_ship.gd:370` calls the reaction once per update. `var h := minf(dt, 1.0 / 30.0)` (:1201) feeds the kick, braking and final displacement (:1203-1232), but brake onset and shudder use the full clock (:1209, :1233-1235). At normal speed, 15 frames of 1/15 s advance one second of shudder and only half a second of recoil. | In a slow frame or a low-FPS close-up, the target moves less before its braking jets kick in; recovery lags the shudder. | Consume the elapsed time in substeps no larger than 1/30 s, evaluating brake onset at each substep time. | New: time lost in hull motion, not trail-mesh cost or the existing damage-material hitch. |
| 5 | Torpedo exhaust drops part of each emission interval. | INFERRED, high. `godot/fx/fx_weapons.gd:1024-1033` counts whole intervals but then writes `p["last"] = fx.now`. At 30 FPS and the requested 14 puffs/s, it takes three frames to accrue one puff; the unused time is discarded. In steady flight the result is 10/s rather than 14/s, even without hitting the three-puff catch-up cap. | The same torpedo leaves wider gaps between puffs at some frame rates than at others. | Keep the fractional remainder; timestamp puffs on the original interval grid. Drop only whole overdue puffs beyond the existing cap. | New: projectile emission spacing, not the ship trail mesh or storm overdraw. |
| 6 | One side of the galaxy band relies on an undefined shader result. | INFERRED, medium. In `godot/world/world_sky.gd:276-288`, `float y = dot(d, band_n);` changes sign across the band. The core, outer glow and dust rift all use `pow` on that signed value with floating exponent 2.0. GLSL leaves negative bases undefined even for 2.0. The live sky also uses this pattern (:446). | A driver that does not optimize the power to a multiply can lose the band or produce invalid colours on just one side. No vendor-specific failure was observed. | Square the normalized distance with `x * x` in both sky paths. | New: invalid pixel math even with a successful bake, not the known bake fallback, shader packaging or sky tint. |
| 7 | Baked planet relief flips direction on the far hemisphere. | INFERRED, high. The general sphere shader samples height offsets along fixed object X and Y (`godot/world/world_planet.gd:381-384`), then treats the X sample as a slope along `cross(vec3(0.0, 1.0, 0.0), N)` (:385-387). On an unrotated sphere at +Z that tangent is +X; at -Z it is -X, although the sample is still toward +X. At either X pole the X offset yields no change in direction at all. `godot/world/world.gd:614` selects this shader. | On a textured planet or moon, the same kind of ridge can catch light on the wrong side or lose relief as the view moves around it. | Take both height samples along the local tangent and bitangent used to build the bumped normal, transforming those axes consistently with the texture spin. | New: relief direction on the general sphere, not rocky-world cache size, lighting cost or faction sky colour. |
| 8 | One live hit fragment can cause a full pool upload each time another fragment expires. | INFERRED, high for the allocation; frame cost unmeasured. `godot/fx/fx_fragments.gd:344-361` rebuilds all live rows on emission or the next expiry, then calls `data.resize(cap * DATA_COLUMNS * 4)` and makes a new byte array and Image for a full texture update. With nine RGBA float texels per row (:17), `godot/fx/fx.gd:282` gives 55,296 bytes at 384 rows, even if just one row survives. No upload when the last piece expires. | A staggered salvo can keep doing CPU copies and texture uploads between hits while the last few chips cool. This can add frame-time spikes; the byte count is not a hitch measurement. | Keep stable instance rows and let expiry hide them in the shader. Rebuild on emission only; when all have expired, set the visible count to zero without an upload. | New: CPU allocation and full-texture upload on expiry, not the Nov 18 measurement of steady GPU time with fragments masked. |
## Probe results

Godot 4.7.2 headless, via `tools/pc/tmo.bat`, in a temporary Jolt project. PASS means the probe reproduced the condition. It does not mean the game passed a regression test.

- **#1, OBSERVED:** Ran the checkout's `_draw_in` and `leash_centre` on a rigid body with a mesh and a collision box, shrinking from 1 to 0.5. Compared both child scales.
- **#3, OBSERVED:** Ran the checkout's `_gate_physics`, `_set_physics_awake` and `wake_physics`. Moved an animatable hull box through a sleeping rigid plate in 30 physics steps of 0.2 units. Repeated with the space awake and the same layers, masks and path.
- **#4 and #5, OBSERVED arithmetic:** Ran the actual recoil step-size line and the exhaust interval/count/reset lines with one second of synthetic frame times. Counted emissions without drawing them. Neither run needed a project asset import.

```text
PASS shrink: mesh scale 0.50, collider scale 1.00
PASS hull crossing: sleeping space plate x 0.000, active control x 4.000
PASS 15 FPS, one effect second: 7 exhaust puffs, 0.50 s recoil integration
PASS 30 FPS, one effect second: 10 exhaust puffs, 1.00 s recoil integration
PASS 144 FPS, one effect second: 13 exhaust puffs, 1.00 s recoil integration
PASS 8 finding quotes match their source lines
PASS report is ASCII and contains 8 findings
```

## Source record

Local pinned checkout. Files below are under `godot/`. The last column is the first 40 characters of the last line, with tabs written as `\t`. Ranges are targeted reads; search hits elsewhere were used to trace callers, not counted as a full-file review.

| File | Lines | Read or searched | Last line prefix |
|---|---:|---|---|
| fx/fx_death.gd | 3978 | 508-623, 740-761, 3266-3306, 3531-3759, 3770-3914; launch sites and timing constants | `\t\tnd.global_position -= back` |
| fx/fx.gd | 1937 | 370-449, 461-523, 916-987; pool setup and wake callers | `\treturn hk` |
| fx/fx_fragments.gd | 361 | 1-220, 266-361 | `\t\t\t_data.update(Image.create_from_data(D` |
| fx/fx_weapons.gd | 1929 | 811-881, 973-1052, 1144-1218; projectile and particle callers | empty |
| fx/fx_ship.gd | 1960 | 1195-1237; update and timing sites | `\t\t_dmg_request(fx)` |
| fx/fx_hull.gd | 1595 | 1014-1117; attach and cache sites | `\t\t(n as Node3D).transform = (tt["rest"] ` |
| fx/fx_breach.gd | 1869 | 1630-1710; apply and cleanup sites | `\t\t_tube(pt, points, e.R * 0.06, e.R * 0.` |
| fx/fx_shaders.gd | 2396 | 60-116, 744-765, 1490-1523; fragment texture and depth sites | `"""` |
| world/world.gd | 1490 | 595-649, 667-702; lens and ring assignments | `\tif _living != null: _living.use_ship_de` |
| world/world_sky.gd | 494 | 263-295, 426-453 | `\treturn out` |
| world/world_planet.gd | 509 | 67-131, 191-204, 361-424, 428-506 | `"""` |
| world/world_shaders.gd | 484 | 209-323 | `"""` |
| world/world_living.gd | 1496 | 335-392; tier and depth sites | `\t\tif c != null: m.set_shader_parameter(p` |
| world/nebula_wake.gd | 337 | 55-129, 150-264 | `\t\t(m as ShaderMaterial).set_shader_param` |
| render/look.gd | 254 | quality, ambient, tonemap and light assignments | `\treturn m` |
| render/ship_view.gd | 1573 | 367-456, 1508-1573; movement and puff update sites | `\t\tring.rotation.y = -rotation.y` |

## Not checked

No rendered captures, GPU timings, driver comparison or full battle playback. #6 is a shader portability risk, not an observed failure on AMD or Intel. #8 has an exact upload size but no measured frame cost. Deduplication used the first Astra report, the council ranked list, the Nov 18 sweep and the exclusions in the issue brief. Standing checks and rules/campaign parity are left to the runner for this report-only change.
