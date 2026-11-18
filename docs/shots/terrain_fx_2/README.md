# Terrain effects 2: issue 100

The four cine comparisons show the same seeded maps before and after the debris and well pass. The default camera is c170, beta 0.98, with a small detail crop underneath. Every sheet is 1280 by 720 and keeps both input revisions in its provenance sidecar.

| Picture | What to inspect |
|---|---|
| [graveyard](graveyard.jpg) | Wreck sub-clumps, open ship centres, lower silhouettes and restrained metal glints. |
| [station](station.jpg) | The station's surrounding debris follows the same cover layout. The station itself is unchanged. |
| [planet](planet.jpg) | Clumped rim debris. The planet and its rocks are unchanged. |
| [deadstar](deadstar.jpg) | A thin cold rim around the well, a restrained warm hint and tangential ring wreckage. The existing bright sky disc is unchanged. |
| [storm, old looks](storm_old_looks.jpg) | Today and holo before and after the minimal legacy colour-ramp port. |
| [belt, old looks](belt_old_looks.jpg) | Violet legacy nebula colour without the old grey smoke mid-tones. |
| [graveyard quality](graveyard_quality.jpg) | Low reduces small rocks and dust while keeping the hero wrecks, clumps, glints and tan colour. |
| [deadstar quality](deadstar_quality.jpg) | Low keeps the new rim, warm hint and ripples, with fewer infall particles. |
| [well and ship](well_ship_guard.jpg) | The well pass on and off around a real cruiser placed at its inner rim. |

[Frame times and light counts](frame_times.md). [Measured results](frame_times.json).

Changes and scope

- `godot/world/world_living.gd`: debris in two or three sub-clumps per hex; a four-unit clear radius at every hex centre, including neighbouring centres; full tumble bounds used for clearance; most geometry below the ship midline; one raised anchor per connected patch. Existing rock and wreck counts and the 0.10 / max(1, scale) tumble law remain. Every hex retains a 4 to 7.6 unit hero wreck. No piece grows beyond 8.66 units.
- Debris dust uses tan linear #d4bf86 and alpha 0.06 to 0.10, with a darker bottom and thinner top. Its analytic hex mask clips the full billboard footprint, including drift. Drift is 0.0385 units per second, one fifth of the recorded gas rate. It adds no gas volumes or lights.
- Wreck glints use `world.gd SUN`, which is opposite `look.gd KEY_DIR`. Three separated points on each kit mesh's authored torn edges bound the hot emission. Unheated pieces remain cold. Painted hull chunks retain their source paint and fit inside the same reserved slot bounds. Their weathered cut caps are cold; fresh-death heat remains confined to the death effect, not the static field.
- The well setup is `_well`. Its shader keeps the lens and slow twist, adds a 3.5-second ripple cycle with two-second inward travel, a cold inner rim, 1.5-pixel edge chroma separation, and a 45-second warm accretion hint. Infall uses radial speed 3 - 2r/R units per second and a tangential component one fifth as fast. Ring wrecks start tangent and share the orbital tumble direction.
- The old well shader had only a borrowed-pixel distance check. The revised pass tests opaque world height at the destination and all three borrowed colour samples. Opaque hulls and board debris above y -20 are protected. Transparent hulls and hex UI draw later. The separate backdrop lens already checks near source and destination pixels and is unchanged.
- `godot/world/world_rocks.gd`: the new sun glint is enabled only on a duplicated living-debris material. Other rocks keep their existing finish. The shared debris batching helper now tags the legacy scatter with its own copied material. That scatter previously remained under the living field and defeated the clear zone. Its colour, depth and shadow fragments are suppressed only while the living node is visible, and restored in today/holo. Far-field materials are unchanged. The geometry check also exercises both visibility transitions and verifies that the original far-rock material is untouched.
- `godot/world/world.gd`: only `CLOUD_SHADER` and `cloud_hexes` changed. The additive today/holo path now uses a density colour ramp and yellow-family internal storm flashes. No extra layers or occlusion were added.
- `board.gd` needs no edit: `_well_info` and the world both read the map's deadstar q/r. Their x/z centres match. The world's y -10 offset places the star below the board and is intentional.

Re-scoped work already delivered by 368 and 369

The cine nebula and ion storm shaders, `_gas`, `_bolts`, mask generation, flash timing, gas quality tiers, tactical tints, planet and scan-rock selection are unchanged. Their existing quality ladder and four-bolt-light budget are retained. This job extends low/max to the new debris and well detail: 16 versus 48 dust motes per hex, the same two or three haze cards, 91 versus 182 well motes, and reduced fine wreck pitting at low. Both tiers retain the colour, glints, rim and ripple structure. The optional blinking wreck light was omitted; no new point lights were needed.

Capture method

The real battle scene uses the existing world_shots seeds 4107, 4102, 4105, 4110, 4103 and 4101. A real cruiser is placed at the review hex for the cover comparison, changing presentation only. Screenshots are rendered at native 3840 by 2160, then composed without colour edits. World shader TIME is held at zero in memory and the living presentation clock at 0.08; the capture harness resets anti-aliasing explicitly between quality tiers. The backdrop/effects global clock is unchanged. Native c170 frames are preserved in the job's stamped capture folder. Performance runs keep live time.

The capture and sheet sources are [capture.gd](capture.gd) and [compose.py](compose.py). [geometry_check.gd](geometry_check.gd) reproduces the generated-geometry checks using the GPU renderer. Headless MultiMesh getters return dummy transforms and are not evidence of generated placement.

The PC's installed gen and ship assets are required; the placeholder guard refuses incomplete captures. Run `capture.gd` with the Godot project as `--path`, through `tools/pc/tmo.bat`. Its first user argument is an output folder; `timing` selects the solo benchmark, `quality-shots` adds low-tier stills, and `guard-proof` adds the well on/off pair. `FX100_ONLY` filters map code names. Use the same script against the original source for `before`, and the changed source for `after_verified`. Run the compositor with `--repo`, `--shots` and `--out`; it reads `before`, `after_verified` below the capture folder and preserves their stamped revisions. Set `PC_GPU_MODE=solo` for timing. The watchdog must observe `GPU cleared`.

Verification

The GPU geometry check passes 1,589 checks across five rock kinds and both quality tiers, including the painted-hull replacement and cold-cap integration, actual mesh bounds, hero spans, full tumble clearances, count ranges, orbital axes, hot-point positions and particle presence. Environment reconciliation passes 54 checks. All 281 seeded battle scenarios match the browser oracle exactly; PRNG, math, threat-map and threaded-AI parity also pass. The affected world, blocker, scale and finale checks were rerun after the legacy-layer correction. All review capture runs finish without script or shader errors.

Standing checks: 62 PASS, 2 KNOWN, 1 FAIL out of 65 rows. The failure is the unchanged station capture at `tools/blender/kits/hegemony_station/capture.gd:169` and `:203`, whose image saves bypass picture provenance. No workflow change is needed; the station capture needs the shared stamped writer.

Listed Godot checks: 61 pass and three do not pass. The onboarding check refuses the live Windows player-data folder, so it was left unrun rather than pointed at Ryan's profile. The story check prints a nil-access script error in `ui/campaign/map3d.gd:793`; the attachment check reports 17 failures across the installed real hulls. Both failures reproduce with the original three source files restored, using the same assets. They are outside this presentation task's delivery scope.

No rules, oracle data, workflows or rule numbers changed. Nothing was committed or pushed.
