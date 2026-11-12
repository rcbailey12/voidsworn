# Cinematic capture audit, issue 487

Reviewed game commit **156236a2f63c282a5e66009209d1c1556324c4e4**, on Ryan's RTX 5080, Godot 4.7.2, Forward+. No game changes. No commit or push.

My first pick is **M1: make engine light describe force rather than speed**. It is the clearest visible mismatch with space flight. Overall priority: M1, F1, M2, F2, F3, M3. These are proposals for Ryan's pick, not an implementation brief approved for building.

## Capture record

The production battle scene played both sides through its normal bot commands. The six-ship s1 battle, seed 1001, ended after ten rounds and 133.22 captured game seconds. The large battle used the scene gate's ten-versus-ten hull mix, seed 487, on a belt: 180 seconds, two complete rounds, then the start of round three. Four squadrons were already present in its first recorded view. Twenty here means twenty full ships, with strike craft in addition.

The first evidence reviewed was the running battle frames. Source inspection followed those observations. The look bench then supplied controlled comparisons: all 216 fleet tiles across six skies, including f1 world, f2 frontier and f3 storm, plus six selected weapon rows at cameras 170, 60 and 26 after the bench's warm pass. Its manifest reports 234 strips/tiles, no warnings and `LOOK_BENCH_DONE`.

Capture controls matter: bot mode suppresses automatic cinematic cut-ins. The small battle retained its HUD at camera 170; the large battle hid the HUD and used camera 240 to show the whole engagement. Those two source recordings are 3840 x 2066 because the window opened maximized. Controlled movement sources are 1920 x 1080 at camera 170, after waiting out the opening camera move. The bench has its own 1920 x 1080 viewport. Do not compare raw pixel measurements between these views without normalizing them. Crops and labels are the only image edits.

The delivered media mirror is **`C:/Users/rcbai/Downloads/voidsworn_test/board/issue-487/shots/`**. It contains every JPG below, `small.mp4`, `large.mp4`, motion recordings, source telemetry, cue logs and the bench manifest. Videos are silent; audio statements below come from cue logging and the cue/clip tables. Raw scratch frames and intermediate logs remain in TEMP.

## Ranked evidence table

| Rank within area | Finding | Evidence | File:line and exact quote | Why it matters / proposed change | Confidence |
|---|---|---|---|---|---|
| F1 | Heavy battery impacts remain small beside a capital | OBSERVED appearance; INFERRED judgment | godot/fx/fx_weapons.gd:1072, `var flash_px: float = (154.0 if torpedo else 56.0) * target_scale` | Build a broader, lingering hit body and light response within the comfort budget | Medium |
| F2 | Short gun bursts repeat a rigid rhythm | OBSERVED | godot/fx/fx_weapons.gd:233, `tf = T0 + 0.05 + i * 0.12` | Seed small differences in muzzle timing and tracer shape | High for timing, medium for visual priority |
| F3 | Weapon identities collapse into a shared hull-hit sound family | OBSERVED routing and cue starts; INFERRED audible effect | godot/audio/sfx.gd:394, `play("hit_heavy" if heavy else "hit", {"pos": pos})` | Choose impact family by weapon and material, preserving existing variation | High for routing, medium for audible effect |
| M1 LOOK | Ships slow without a visible braking burn | OBSERVED | godot/render/ship_view.gd:1146, `thrust = clampf((d[1] as Vector3).length() / maxf(gl_vpk, 1e-4), 0.0, 1.0)` | Drive engine and retro jets from acceleration | High |
| M2 LOOK | Heading changes are folded into departure and arrival | OBSERVED | godot/render/ship_view.gd:1067, `yaw = lerpf(yaw, gl_final_yaw, smoothstep(0.76, 1.0, p))` | Give heading its own thruster-driven animation, with the same endpoint and final facing | High |
| M3 LOOK | One fixed rock-hop height gives the capital a crowded pass | OBSERVED silhouette overlap; INFERRED clearance concern | godot/scenes/battle/battle.gd:1618, `p.y = (9.0 if ov > 0 else -7.5) if ov != 0.0 else 0.0` | Calculate visual clearance from the actual hull and obstacle | Medium; mesh intersection not proved |

## Battle findings

### F1. Heavy hits need more body around the contact point

1. **Now:** the battleship battery's hit reads as a small hot spot and a passing white stroke beside the Tomb-ark. The ship dominates the picture. This is a judgment from the captured camera-170 strip, not a claim that the shader's flash calibration is broken.
2. **On film:** the heavy round would throw matter, venting gas and light over a substantial part of the victim, leaving a cooling wound after the initial flash.
3. **Limit:** fx_weapons.gd:1071-1079 gives target scales `0.8`, `1.0`, `1.2`; a macro flash setting of `56.0` and body setting of `48.0`; body lifetime `0.50`. Thus the nominal flash settings are 44.8, 56 and 67.2 pixels in these three target bands. These are settings, not measured lit extents. The same firing battleship is used in all three captures. The legacy hit table at lines 64-69 was explicitly tuned below the flash counter's 65-pixel threshold. The newer capital macro setting can exceed that threshold.
4. **Reason:** the code records a distance-readability and flash-budget rationale. That is real context, but hitting a size row does not prove the moment has weight in a running fight.
5. **Proposal:** keep a brief, budgeted flash; broaden directional ejecta and non-flashing gas, hold a low hot wound for a few seconds and let nearby hulls catch the light. Judge the result beside the current running fight. Keep the reduce-flashing version and the flash budget.
6. **Size/cost:** two or three agent runs, including an A/B capture and frame-time check, plus one Ryan review. Longer gas and light raise live effect counts and overdraw. This capture run did not benchmark that proposed cost.
7. **Picture:** [f01_heavy_hits.jpg](../../../docs/shots/cinematic_audit/f01_heavy_hits.jpg). These are native 384 x 216 bench crops, with the same weapon on three target sizes. The settings printed on the sheet are not measured flash diameters. The small and large recordings show how quickly contacts disappear inside actual turns.

### F2. The burst has a metronome underneath it

1. **Now:** the short las burst repeats compact, similarly shaped strokes with the same spacing. It is already a ripple, not an entire salvo fired on one frame.
2. **On film:** individual barrels would catch at slightly different times and produce slightly different strokes, while still feeling like one trained crew firing a burst.
3. **Limit:** fx_weapons.gd:233 fixes las launches at `0.05 + i * 0.12`; lines 235-236 reuse the same muzzle and streak recipe. The macro launch interval at line 212 defaults to `0.08`. The kept bench samples are 1/30 second apart, so a 0.12-second separation can only be visually resolved to roughly one such sample. The exact period comes from the cited recipe.
4. **Reason:** a simple weapon signature and an easily scheduled ripple. I found no stated comfort reason for identical spacing. This is not evidence that all aim points are identical: the target code at lines 171-195 includes miss offsets and hull-section hit points, and the bench's macro impact times are unequal.
5. **Proposal:** add small seeded offsets around the launch schedule and modest variation in tracer length and intensity. Keep hit count, damage, target, outcomes and the turn boundary unchanged. Keep the burst's overall duration bounded.
6. **Size/cost:** one agent run and one Ryan review. The same number of streaks can be used; added random scalar work should be small, but no timing claim is measured here.
7. **Picture:** [f02_salvo.jpg](../../../docs/shots/cinematic_audit/f02_salvo.jpg), small battle t16.62-17.12. The full recording and the las bench strip distinguish a short burst from an instantaneous salvo.

### F3. The guns differ more than their hull-hit sounds

1. **Now:** the log records distinct las, plasma and ion firing cues, but ordinary hull contacts repeatedly enter `hit`, with critical contacts using `hit_heavy`. I cannot give a listening verdict.
2. **On film:** a burning energy contact, a penetrating round and a violent pressure release would have different material bodies beneath their common hull impact.
3. **Limit:** battle.gd:1780-1796 passes each successful contact to `sfx.hit(_pos(t_id), h["crit"])`; sfx.gd:393-394 chooses just the ordinary/critical family. The small fight logged **40 hit, 5 hit_heavy, 18 gun_las, 17 gun_plasma and 9 lance_ion** starts. Its first three complete rounds logged respectively **18/10, 24/10 and 27/12 total starts/distinct cue names**. Per-round counts are in [audio_counts.json](../../../docs/shots/cinematic_audit/audio_counts.json).
4. **Reason:** a shared event adapter. There is already real take variation: `hullHit` has six sampled clips and `hullTick` four. sfx.gd:138-145 avoids immediately repeating a selected member within a pool. The four synth takes listed for `hit` are not necessarily played: lines 151-170 prefer available sampled layers unless a synth layer is requested. This is not a one-file-per-hit defect. Exact selected clip paths and their repeat counts were not logged in the retained fight.
5. **Proposal:** pass weapon family and struck material into the impact sound selection, then use the appropriate existing cue family with its own sample rotation. Keep voice limits and ducking. Make the listening comparison before replacing sources.
6. **Size/cost:** one agent run for routing, then a listening review. Existing assets can be reused. Extra simultaneous layers would need a voice-budget measurement; routing alone need not add voices.
7. **Picture/log:** [f03_generic_hit_audio.jpg](../../../docs/shots/cinematic_audit/f03_generic_hit_audio.jpg), plus `small_telemetry.json` in the media mirror. The picture is a running-game capture with an honest log annotation, not invented audio evidence.

## Movement

The rules provide reachable paths with hex positions and facing steps. The capture harness chose legal entries returned by `reach`, then used the production move command and playback. The playback turns those entries into one curved journey with a smooth speed profile. The bow blends toward the flight course near departure and toward the chosen final facing near arrival. The main drive follows speed; steering puffs follow yaw rate. Larger ships do accelerate and brake more slowly in the measured straight examples. These captures do not establish that every class, faction or AI route has the same behavior.

For the obstacle fixture only, three rocks were placed directly ahead of the initial player fleet before the battle scene was built. No rules or movement functions were replaced. Each chosen path was returned by `reach` and contains a real `over: 1` step. This is controlled starting terrain, not a naturally generated AI obstacle encounter.

### Measured movement

World displacement and angles were sampled with the rendered frames at 60 Hz. JPGs were kept every sixth frame, so picture timestamps are about 0.10 seconds apart before selection. Each motion strip takes six times spread evenly over the move, rounded to the nearest kept frame. Measurement precision is therefore better than the presentation strip's precision. Full speed means 95% of the **observed peak**; stopping means the interval from the last 95% sample to the first following 5% sample. These are not configured cruise-speed guarantees. `movement_measurements.json` records the other maneuvers as well.

| Class, straight example | Travel steps | To 95% peak | 95% to 5% stop | Peak speed, world units/s | Peak pixels/s at source camera | Move plus short settle |
|---|---:|---:|---:|---:|---:|---:|
| Frigate | 4 | 0.52 s | 0.43 s | 36.21 | 238.37 | 2.55 s |
| Cruiser | 4 | 1.07 s | 0.85 s | 27.55 | 174.21 | 3.95 s |
| Dreadnought | 3 | 1.55 s | 1.22 s | 23.28 | 133.82 | 4.25 s |

The final-facing examples peak at **211.2, 100.7 and 90.2 degrees/s**, respectively. The turn-containing examples peak at **178.6, 191.7 and 60.9 degrees/s**. These are peaks on different legal paths, not controlled one-hex angular-speed ratings. The highest measured turn bank in those three examples is **2.12, 2.95 and 2.96 degrees**. Straight examples stay below 0.001 degree of roll. No large heading teleport was demonstrated: 211.2 degrees/s is about 3.52 degrees per 60-Hz frame.

The main plume is low at rest, bright at maximum speed and fades while speed falls. No forward braking jet is visible in the straight strips. The rock crossings reach approximately **9.00 world units** above the plane in all three classes. The examples finish at their requested destinations and visually follow the displayed route corridor. I did not prove exact pixel agreement with the preview spline, or validate every obstacle's physical clearance. No RULE finding is established by these captures.

| Move | Frigate | Cruiser | Capital |
|---|---|---|---|
| Straight, rest to rest | [m01](../../../docs/shots/cinematic_audit/m01_frigate_straight.jpg) | [m02](../../../docs/shots/cinematic_audit/m02_cruiser_straight.jpg) | [m03](../../../docs/shots/cinematic_audit/m03_dreadnought_straight.jpg) |
| Move containing a turn | [m04](../../../docs/shots/cinematic_audit/m04_frigate_turn.jpg) | [m05](../../../docs/shots/cinematic_audit/m05_cruiser_turn.jpg) | [m06](../../../docs/shots/cinematic_audit/m06_dreadnought_turn.jpg) |
| Turn to final facing | [m07](../../../docs/shots/cinematic_audit/m07_frigate_final.jpg) | [m08](../../../docs/shots/cinematic_audit/m08_cruiser_final.jpg) | [m09](../../../docs/shots/cinematic_audit/m09_dreadnought_final.jpg) |
| Real rock overflight | [m10](../../../docs/shots/cinematic_audit/m10_frigate_obstacle.jpg) | [m11](../../../docs/shots/cinematic_audit/m11_cruiser_obstacle.jpg) | [m12](../../../docs/shots/cinematic_audit/m12_dreadnought_obstacle.jpg) |

[m13_whole_side.jpg](../../../docs/shots/cinematic_audit/m13_whole_side.jpg) shows a side moving through the large battle at t0, 18, 36, 54, 72 and 90. Yellow lines are annotated **observed tracks**, not invented move previews. The camera is 240 for this wider view.

### M1. LOOK: braking has no visible opposing force

1. **Now:** the capital carries its brightest main plume while traveling fastest, then slows as that plume fades. Nothing visibly pushes forward to brake it. The smaller classes do the same. The approved dim pilot glow at rest remains visible.
2. **On film:** keep that pilot glow, burn hard to gain speed, coast with the main plume low, and show forward-facing jets during the smooth stop.
3. **Limit:** ship_view.gd:1146 uses velocity divided by peak velocity for `thrust`. Lines 1147-1149 emit turn puffs on yaw rate. battle.gd:1540-1541 explicitly maps the drive from flight speed. This is the default glide path, not the older segments mode with its different thruster behavior.
4. **Reason:** the continuous-flight implementation's speed-following drive and sparse turn puffs. R189 clarifies that Ryan never intended to prohibit braking or sliding jets; he wanted to avoid sudden, jerky motion.
5. **Proposal:** use longitudinal acceleration to drive the main plume, opposing longitudinal acceleration for retro jets and lateral acceleration for side/vertical jets. Use angular acceleration and counter-torque for turns. Keep the current smooth position/time curve and rule outcomes. Keep the pilot glow.
6. **Size/cost:** two or three agent runs with all-class captures, plus one Ryan review. Reuse the existing puff system and bound its emissions. More active puffs and overdraw need a measured frame-time comparison.
7. **Picture:** [m03_dreadnought_straight.jpg](../../../docs/shots/cinematic_audit/m03_dreadnought_straight.jpg), especially full drive during travel followed by a fade through braking. The frigate and cruiser strips are the controls.

### M2. LOOK: the bow is steered onto the route, then steered onto the final answer

1. **Now:** departure and arrival absorb heading changes into the curved move. In the final-facing examples, a frigate can swing at 211 degrees/s and the capital at 90 degrees/s, with limited visible thruster explanation. It is smooth numerically, but the large last swing feels commanded by the path.
2. **On film:** the hull's heading would have its own build, coast and counter-burn, while its velocity could continue along a different direction.
3. **Limit:** ship_view.gd:1066 blends heading over the first `0.18` of the move; line 1067 blends to final heading over `0.76` to `1.0`. Lines 1147-1149 puff in the sign of yaw velocity, rather than describing a full torque and counter-torque cycle.
4. **Reason:** an economical way to make old path and facing steps look continuous. The comments at lines 763-768 describe bow-following and final-facing easing. R189 permits smooth slides when they make physical sense.
5. **Proposal:** animate heading independently, retaining the exact commanded final facing and destination. Give short and long yaw changes their own mass-sensitive time windows, and allow a smooth sideways drift on the existing route with the matching jets. Do not change the AI's chosen hex or facing.
6. **Size/cost:** two or three agent runs and one Ryan review. Curve and scalar work should remain small; actual costs would chiefly be additional jet emissions. Benchmark the result.
7. **Picture:** [m09_dreadnought_final.jpg](../../../docs/shots/cinematic_audit/m09_dreadnought_final.jpg), with [m07](../../../docs/shots/cinematic_audit/m07_frigate_final.jpg) as the fast comparison. This is a LOOK finding, not a request to change facing rules.

### M3. LOOK: give the rock hop clearance appropriate to the actual ship

1. **Now:** a rock passes across the capital's hull silhouette during the hop. The big hull makes the pass look crowded. The image alone does not prove mesh penetration; this is a clearance concern for the builder to check.
2. **On film:** the visible belly and obstacle would separate clearly, with a broad climb and settle explained by vertical jets.
3. **Limit:** battle.gd:1618 assigns every positive overflight `9.0` world units and every negative crossing `-7.5`. The three measured rock crossings all peak at about 9.0, regardless of hull size.
4. **Reason:** a simple shared visual height for the rules' over/under step. No hull- or rock-bound measurement is present in that conversion.
5. **Proposal:** derive a visual rise from obstacle top and hull bottom, with a margin, while keeping the selected legal hex route and move result. Check actual geometry first. If resolving it requires a different legal route, that becomes RULE and needs Ryan's ruling instead.
6. **Size/cost:** one agent run for clearance verification and a prototype, another if obstacle bounds need a service, plus one Ryan review. Cached bounds should avoid per-frame mesh scans; no measured millisecond cost is available.
7. **Picture:** [m12_dreadnought_obstacle.jpg](../../../docs/shots/cinematic_audit/m12_dreadnought_obstacle.jpg); m10 and m11 show the same fixed rise on smaller hulls. These are controlled rock placements, disclosed above.

## Protected limits and checks

`FLASH_CAP := 3` and `FLASH_SCREEN := 0.06` are present at fx.gd:23-25. This audit does not recommend removing the flash budget, and did not log flash-budget rejection events. A weak-looking hit is not proof that this budget rejected it. The safer visual proposals above use sustained lower light, matter and sound. Reduce flashing and frame rate stay protected.

`node contrib/opus/tools/run_all_checks.js`: exit 0, 41 PASS and 2 KNOWN, no FAIL or SKIP. The known baselines are seven listed findings-test failures and twelve oracle constant differences. Capture validation checks image dimensions, referenced files, telemetry, completion markers, and absence of placeholder hull reports. No production code changed. Godot did emit resource/RID cleanup errors at shutdown; those logs are retained. The completed capture markers and manifests must not be described as a completely clean engine run.

One recommended next step: put **M1's capital strip** beside the Board's code finding and ask Ryan to pick a force-driven engine/jet prototype before broader movement changes.

## Read receipt

Local commit above is the reviewed source of truth. Raw main views were also opened through the GitHub connector for the cited code and playbooks. Main can advance independently. This is a capture audit with targeted code attribution, not a claim to have audited every line. The [read receipt](cinematic_capture/read_receipt.json) records SHA-256 hashes and the exact inspected ranges, including ranges for large files. Last-line strings below use JSON escaping for tabs or an empty line.

| File | Total lines | First 40 characters of last line |
|---|---:|---|
| godot/scenes/battle/battle.gd | 5120 | `"\tget_tree().quit(code)"` |
| godot/render/ship_view.gd | 1295 | `"\t\tring.rotation.y = -rotation.y"` |
| godot/fx/fx_weapons.gd | 1349 | `"\t\t\t(m as ShaderMaterial).set_shader_para"` |
| godot/audio/sfx.gd | 450 | `"\tcreate_tween().tween_property(_amb, \"vo"` |
| godot/fx/fx.gd | 1136 | `"\ttmp.queue_free()"` |
| godot/fx/fx_death.gd | 1914 | `"\t\t\tl[\"base\"] = 0.7 * gate"` |
| godot/bench/look_bench.gd | 615 | `"\treturn true"` |
| docs/playbooks/effects.md | 92 | `"and checks from outside. The Board makes"` |
| docs/playbooks/deaths_and_hits.md | 153 | `"Each is one or two Codex runs and one lo"` |
| docs/playbooks/sound.md | 39 | `"ladder and judges with Ryan's picks. Rya"` |
| docs/REVIEW_PROTOCOL.md | 35 | `"- Claude checks every claim against the "` |
| docs/ship_pipeline/AUDIT_BRIEF.md | 105 | `"- The heavy steps only run on the owner'"` |
| CODEX_TASK.md | 93 | `"_Generated by [Claude Code](https://clau"` |
| godot/audio/cues.json | 1997 | `"}"` |
| godot/audio/clips/index.json | 316 | `"}"` |

## Not checked

No listening judgment; exact sampled clip repeat counts in the retained fights; a true frigate-versus-capital comparison of the same firing weapon; gameplay camera cut-ins, since bot mode suppresses them; all-faction motion; continuous-momentum rule changes; precise mesh penetration; exhaustive route optimality or final-facing AI choices; a performance benchmark of any proposed change; a full source audit outside the ranges in the read receipt. No wreck-break finding is included: issue 484 owns that work. The small-ship death frames and both full battle recordings are retained as evidence, without attributing their appearance to an unverified cause.
