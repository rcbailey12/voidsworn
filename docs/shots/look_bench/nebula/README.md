# Issue 368: route A built, awaiting Ryan's look approval

Refs #368. Continued the merged partial after Ryan picked A, fog (R270). Max now uses baked-noise FogVolumes with reduced edge cards. High and low use cards. The 83-unit soft footprint and 38.5-unit height pass the shared scale check; the default gas rows have left KNOWN. No route B work was done in this round.

Start with [nebula at camera 170](N368A_nebula_c170.jpg) and [storm at camera 170](N368A_storm_c170.jpg). Each sheet puts step 1's Today beside the built route, with native 4K gas-on and gas-hidden hull crops below. The other views are [nebula 60](N368A_nebula_c60.jpg), [nebula 26](N368A_nebula_c26.jpg), [storm 60](N368A_storm_c60.jpg), [storm 26](N368A_storm_c26.jpg), [top-down](N368A_topdown.jpg), and the unchanged [campaign sector context](N368_campaign.jpg). All new sheets are 1280 by 720.

The shared evidence root is `C:/Users/rcbai/Downloads/voidsworn_test/board/issue-368/shots/`. Every N368A sheet and this report are copied there for the Board. Native captures and poses are in `step2_<map>_<tier>_keep_captures`; raw timing sessions are in `step2_<map>_<tier>_keep/scene_gate.json`. The first invocation for each map and tier is discarded in the matching `warm` folder.

GPU: Ryan's RTX 5080, Godot 4.7.2 Forward+, vsync off. Each kept row is the median of three session medians, 120 warmup frames and 720 measured frames per mode. Session 2 reverses the mode order. The engagement camera is the real scene gate camera, not the presentation camera. 4K is the gate's `res_2160` mode, 3D at 3840 by 2160 in a 1080p window. Stills use a native 3840 by 2160 window. GPU jobs ran one at a time after checking the Board go file.

| Map | Tier | 1080p frame ms | 4K GPU ms | Gate 12.5 ms |
|---|---|---:|---:|---|
| nebula | max | 8.116 | 6.555 | PASS |
| nebula | high | 6.815 | 5.209 | PASS |
| nebula | low | 3.600 | 3.655 | PASS |
| storm | max | 4.558 | 7.547 | PASS |
| storm | high | 4.107 | 5.055 | PASS |
| storm | low | 4.320 | 3.493 | PASS |

Max-tier deltas against the saved step 1 Today reference (historical, not a paired cost isolation on this revision):
- nebula: 1080p frame +3.391 ms; 4K GPU +0.335 ms.
- storm: 1080p frame -0.495 ms; 4K GPU +1.876 ms.

The [measurement file](step2_measurements.json) retains every session, actual fog/card counts, draw calls, visible primitives, VRAM, camera, adapter and source hashes. Draw calls and triangles are reported, not capped. The real generated multi-patch fixtures and fleet are unchanged: nebula seed 4207 has six nebula hexes in three patches; storm has 23 storm hexes in three patches and four nebula hexes. The gate uses live volleys. Before/after views can differ in incidental debris placement because each route consumes the living-terrain RNG differently. The gas/clear hull pair instead uses one fixed scene. The raw logs retain the existing late `exterior_alpha` compile notice (issue 376); this report measures the frame and GPU medians, not a claim that compilation stalls are gone.

R82 hull check: hull materials skip volumetric fog, including shared damage shaders, and foreground cards reject opaque hull pixels. Paired stills hold pose, direct lights and debris fixed while hiding only gas. A separate render of the real hull triangles supplies the pixel mask; the measurement erodes its silhouette by one pixel. sRGB luma contrast is the hull's 95th minus 5th percentile; edge contrast is the mean adjacent-pixel sRGB luma difference inside that mask. Ratios compare inside gas with the same hull outside gas. No enlargement, sharpening or recolouring enters the measurement.

| Map | Camera | sRGB luma contrast retained | Edge contrast retained | Mean RGB difference / 255 |
|---|---:|---:|---:|---:|
| nebula | 170 | 94.79% | 99.24% | 0.574 |
| nebula | 60 | 98.29% | 99.93% | 0.603 |
| nebula | 26 | 98.84% | 99.96% | 0.266 |
| storm | 170 | 95.33% | 99.19% | 0.662 |
| storm | 60 | 98.59% | 99.98% | 0.617 |
| storm | 26 | 99.36% | 99.98% | 0.301 |

The cruiser no longer has the prototype's violet wash. Faction ramp-end tint remains clamped to 0.25. Some background glow still reaches hull pixels through postprocessing; the measured differences above expose that remaining contribution.

The [storm-light pair](N368A_storm_light.jpg) hides ribbons and suppresses card flashes in both frames, with identical direct light. Only fog scattering toggles: 84,105 pixels change by more than 2/255, with a peak channel difference of 140/255. Two bolt lights can enter max-tier fog. The 128-cubed froxel grid has temporal reprojection off so short flashes leave no history trail.

[Nebula tier sheet](N368A_nebula_tiers.jpg) and [storm tier sheet](N368A_storm_tiers.jpg) show the fallbacks. The JSON asserts that actual max scenes contain volumes with fog enabled, and high/low scenes contain no volumes with fog disabled. The camera near plane uses 15, 5 and 1 unit zoom bands; fog length follows the camera to keep distant clouds in range.

Class scale, with the asset code printed on each sheet:

| Class | Camera 170 | Camera 60 |
|---|---|---|
| Frigate (V14_23) | [170](N368A_scale_frigate_c170.jpg) | [60](N368A_scale_frigate_c60.jpg) |
| Destroyer (V15_37) | [170](N368A_scale_destroyer_c170.jpg) | [60](N368A_scale_destroyer_c60.jpg) |
| Cruiser (V16_37) | [170](N368A_scale_cruiser_c170.jpg) | [60](N368A_scale_cruiser_c60.jpg) |
| Carrier (V18_51) | [170](N368A_scale_carrier_c170.jpg) | [60](N368A_scale_carrier_c60.jpg) |
| Battleship (V17_37) | [170](N368A_scale_battleship_c170.jpg) | [60](N368A_scale_battleship_c60.jpg) |
| Dreadnought (V1b_r_23) | [170](N368A_scale_dreadnought_c170.jpg) | [60](N368A_scale_dreadnought_c60.jpg) |
| Super-dreadnought (H4_11) | [170](N368A_scale_super-dreadnought_c170.jpg) | [60](N368A_scale_super-dreadnought_c60.jpg) |
| Battle-barge (C19_51) | [170](N368A_scale_battle-barge_c170.jpg) | [60](N368A_scale_battle-barge_c60.jpg) |
| Bio-titan (B16_23) | [170](N368A_scale_bio-titan_c170.jpg) | [60](N368A_scale_bio-titan_c60.jpg) |
| Ark (I8_37) | [170](N368A_scale_ark_c170.jpg) | [60](N368A_scale_ark_c60.jpg) |
| Tomb-ark (D22_23) | [170](N368A_scale_tomb-ark_c170.jpg) | [60](N368A_scale_tomb-ark_c60.jpg) |
| Squadron_bomber (voidsworn|bomber) | [170](N368A_scale_squadron_bomber_c170.jpg) | [60](N368A_scale_squadron_bomber_c60.jpg) |
| Squadron_spore (chorus|spore) | [170](N368A_scale_squadron_spore_c170.jpg) | [60](N368A_scale_squadron_spore_c60.jpg) |
| Transport (O2_37) | [170](N368A_scale_transport_c170.jpg) | [60](N368A_scale_transport_c60.jpg) |

These use real scenario-generated units, with presentation placement only. Transport is the built O2_37 objective prop at the hull table length. The existing N368_context class sheets below retain the unchanged asteroid, debris and wreck sizes; fresh context captures are also retained in the new max capture folders. Station and asteroid scale work stays with issues 373 and 369.

PC assets: copied gen, built ship files and the existing import cache from `C:/Users/rcbai/Downloads/voidsworn_test/build/godot` before import; all 252 manifest files match. Captures stop on placeholder hulls. No ship assets, gen files, UID files or rewritten import metadata are delivered. The existing 128-cubed R8 noise bake is unchanged, SHA256 `92c69b3254aa015cd577bced12f694bfa764e4b8d3d5e2b2a332628f11dc5691`; its source is `godot/world/nebula_noise_bake.gd`.

Checks: required Node standing suite exits 0 (51 PASS, two KNOWN baseline rows: seven findings and 12 oracle differences). Scale check exits 0 (53 objects, four unrelated KNOWN rows). Both headless map dry runs exit 0 and prove the 83-unit footprint, 38.5-unit height and max/high/low route split. All retained GPU invocations exit 0 without shader errors or placeholders. Evidence logs and the CPU dry-run JSON are in the shared folder. Import completed; its sandbox-only certificate/settings-write notices did not prevent import or the later elevated GPU runs.

R129: world build callers and rules APIs are unchanged. No saves, JS rules, oracle copies or exported tables changed, so no oracle refresh was needed. Existing Graphics choices remain, with fog at max and cards at high/low. GitHub runs standing checks, the em-dash scan, rules parity and Godot game checks; the manual GPU bench is outside test folders.

Reproduction for workers: run `res://world/nebula_bench.tscn` with Forward+, `--go-file <PC gpu_go.txt> --map-case nebula --terrain-tier max --sessions 3 --warmup 120 --frames 720 --modes base,res_2160 --out <folder>`, then repeat for storm and the other tiers. Leave VS_NEBULA_ROUTE unset for the shipped default. Discard the first invocation and keep the second. For stills run `res://world/nebula_capture.tscn` with `--captures --four-k --scale-captures`; use `--captures` alone for high/low. Compose with `python docs/shots/look_bench/nebula/render_step2.py --source <shared shots root>`. The go file must start with `GPU cleared`; headless timing is refused.

Stopped for Ryan's final look approval. The outside check on issue 256 is still required before merge. No hand-play recording or route B rebuild was made; acceptance here uses the requested still sheets and live scene-gate timings. No commit or push was made by the agent.

---

## Historical step 1 evidence

The following comparison records the prior route pick. Its default/status statements and route B commands apply to that earlier revision only; the live route is A as documented above.
# Issue 368: route comparison before Ryan's pick

Refs #368. Step 1 compares two opt-in prototypes against today's gas. No route has been selected and the shipped default is unchanged. The route build and Ryan's final approval remain step 2.

The comparison sheet is [N368_route_comparison.jpg](N368_route_comparison.jpg). Read the default camera first: [nebula 170](N368_nebula_c170.jpg), [storm 170](N368_storm_c170.jpg), and the [native 4K hull pairs](N368_native_4k.png). The camera sheets include a native 1080p center crop. The 4K sheet keeps native pixels, with no enlargement or sharpening.

The other cameras are [nebula 60](N368_nebula_c60.jpg), [nebula 26](N368_nebula_c26.jpg), [storm 60](N368_storm_c60.jpg), and [storm 26](N368_storm_c26.jpg). Camera 26 is the game's minimum. [N368_topdown.jpg](N368_topdown.jpg) shows both generated maps from the game's top-down angle. Class scale sheets use the B candidate, with separate current rock, debris and wreck context sheets. Ship lengths come from the real generated units and hull table, not typed unit fixtures. The one scale table remains [scale.md](../../../playbooks/scale.md).

GPU measurements on Ryan's RTX 5080, Godot 4.7.2 Forward+, max quality, MSAA 4x, vsync off. Each kept reading is the median of three session medians, 120 warmup frames and 720 measured frames per mode. The first invocation is discarded: three sessions for today, one for each final candidate. Both modes run in each invocation; their order reverses in session 2. The gate is 12.5 ms on each reading.

| Map | Route | 1080p frame ms | Delta | 4K GPU ms | Delta | Gate |
|---|---|---:|---:|---:|---:|---|
| nebula | Today | 4.725 | +0.000 | 6.220 | +0.000 | PASS |
| nebula | A: fog + edge cards | 5.498 | +0.773 | 6.680 | +0.460 | PASS |
| nebula | B: denser cards | 4.120 | -0.605 | 6.734 | +0.514 | PASS |
| storm | Today | 5.053 | +0.000 | 5.671 | +0.000 | PASS |
| storm | A: fog + edge cards | 4.183 | -0.870 | 7.531 | +1.860 | PASS |
| storm | B: denser cards | 5.704 | +0.651 | 16.157 | +10.486 | OVER at 4K |

Raw session readings, draw calls, visible primitives, VRAM and source hashes are in [measurements.json](measurements.json). Frame times vary more than GPU times; the session readings are retained so a frame delta is not mistaken for a precise isolated shader cost. Triangles and draw calls are reported, not capped.

The shared evidence root is `C:/Users/rcbai/Downloads/voidsworn_test/board/issue-368/shots/`. Each final candidate has `<map>_<route>_final_keep/scene_gate.json`, with its discarded first pass in `final_warm`. Today's kept baseline is `<map>_today_keep/scene_gate.json`. Today was measured before the candidate-only resize; its code path, dimensions and inputs did not change. The earlier `fog_keep`, `cards_keep` and `scaled_*` prototype runs are superseded and are not used in this report.

The nebula fixture is the gate's real scenario with terrain made by `genTerrain("graveyard", "open", {cond: {terr: "neb"}})`: six nebula hexes in three patches (1, 4, 1). The storm fixture is the original gate scenario: 23 storm hexes in three patches (13, 5, 5), plus four nebula hexes. Both use seed 4207 and the gate's original mixed-faction fleet, automatic wings and live volleys. The measured view is the engagement camera. The stills use cameras 170, 60, 26 and top-down, focused on the same real cruiser moved for presentation. The capture helper locks its pose through resize callbacks, records the projected subject position, and hides gas by material identity for the clear pair. The sheet builder verifies every 4K pair shares its target and centers the cruiser at pixel (1920, 1080). Gas time is fixed for stills; timing runs retain live motion. Incidental debris and bolt placement can differ because changing card count consumes the living-terrain RNG differently.

A is `VS_NEBULA_ROUTE=fog`: one baked-noise FogVolume per patch at max, with reduced edge cards and fog-active storm lights. B is `VS_NEBULA_ROUTE=cards`: denser cards sampling the existing world-space 3D noise field. High and low use cards. Neither changes the player settings or becomes the default before the pick.

Both candidates now have an 83-unit sampled soft footprint for an isolated hex, inside the scale table's 74.4 to 297.6 target. The enclosing fog box is 96 units across; the height is 38.5. Cards are 72 to 102 units across, veils 108 to 138, with their culling margin expanded to cover the vertex-generated size. The original prototypes were below the merged scale target; they were enlarged and measured again before this comparison. The normal default remains at its existing scale and stays a KNOWN row until the chosen route is built. This comparison does not retire those default rows early.

My pick is A for the top tier: it supplies actual volume depth and its storm GPU reading is 7.531 ms. B reaches 16.157 ms there, 3.657 ms over the gate. A currently washes violet over the opaque cruiser, so it does not yet meet R82. B keeps that cruiser crisp. The native 4K pairs show this directly. The selected build must protect hulls and finish the gas silhouette and internal lighting before approval. High and low fallbacks have CPU geometry coverage here; their final look and cost, motion recordings, and final approval remain behind the pick.

The [campaign sector map](N368_campaign.jpg) is scale context from the real mapshots run. Current rocks, debris and wrecks are included in the class context sheets. Rock resizing remains issue 369. Transport is drawn from its real built O2_37 objective prop at the hull table length; the other hulls and wings come from the real scenario factory.

PC hulls were copied with `tools/pc/get_ship_files.bat` from `C:/Users/rcbai/Downloads/voidsworn_test/build/godot` before import. All 252 shipped manifest files matched. The existing PC import cache was copied and validated by Godot to avoid recompressing unrelated art. No ship assets, generated hull files, UID files or import metadata are included in the change. Capture runs stop on any placeholder hull.

Checks: the required Node 22 standing suite exits 0, with 50 PASS rows and its two KNOWN baselines (seven findings and 12 oracle differences). Godot parser and both headless map dry runs exit 0. The dry runs build today, A and B at max, high and low and sample the actual mask: both candidate spans are 83 units. The shared scale check exits 0: zero of 53 objects fail outside six existing KNOWN rows. The default gas rows remain KNOWN until a route is selected. The baked noise SHA256 is unchanged: `92c69b3254aa015cd577bced12f694bfa764e4b8d3d5e2b2a332628f11dc5691`. Every retained timing invocation completed without shader or placeholder failures. The report uses only today_keep and final_keep. Detailed check records are in the shared evidence folder.

Reproduction for workers: set `VS_NEBULA_ROUTE` to `today`, `fog` or `cards`. Use the console Godot executable with `--path godot --rendering-method forward_plus --resolution 1920x1080 res://world/nebula_bench.tscn -- --go-file C:/Users/rcbai/Downloads/voidsworn_test/gpu_go.txt --out DIR --map-case nebula --sessions 3 --warmup 120 --frames 720 --modes base,res_2160`; repeat for storm, run twice and keep the second. The go file's first line must start with `GPU cleared`. Headless timing is refused. Use `res://world/nebula_capture.tscn` with `--captures --four-k` for stills, adding `--scale-captures` for B's class and terrain context views. Compose sheets with `python docs/shots/look_bench/nebula/render_comparison.py --source SHARED_SHOTS_ROOT`. Its inputs are real captures and JSON, never generated timings.

R129 review: the normal world build API and rule state are unchanged. No saves, JS rules or exported tables changed, so no oracle refresh is needed. Candidates remain opt-in; the camera near plane uses zoom bands only for those candidates. Existing Graphics choices remain. GitHub runs standing checks, the em-dash scan, rules parity and Godot game checks. The manual GPU bench is outside test folders. Ryan's route pick comes next, then the selected build and final look approval. The outside check on issue 256 is required before merge.

Scale index. Gas views use both B map folders. Other terrain views use `nebula_cards_captures` and the board's `hex_world` coordinates.

| Class | Asset code | Camera 170 | Camera 60 | Rock, debris, wreck |
|---|---|---|---|---|
| Frigate | V14_23 | [170](N368_scale_frigate_c170.jpg) | [60](N368_scale_frigate_c60.jpg) | [Context](N368_context_frigate.jpg) |
| Destroyer | V15_37 | [170](N368_scale_destroyer_c170.jpg) | [60](N368_scale_destroyer_c60.jpg) | [Context](N368_context_destroyer.jpg) |
| Cruiser | V16_37 | [170](N368_scale_cruiser_c170.jpg) | [60](N368_scale_cruiser_c60.jpg) | [Context](N368_context_cruiser.jpg) |
| Carrier | V18_51 | [170](N368_scale_carrier_c170.jpg) | [60](N368_scale_carrier_c60.jpg) | [Context](N368_context_carrier.jpg) |
| Battleship | V17_37 | [170](N368_scale_battleship_c170.jpg) | [60](N368_scale_battleship_c60.jpg) | [Context](N368_context_battleship.jpg) |
| Dreadnought | V1b_r_23 | [170](N368_scale_dreadnought_c170.jpg) | [60](N368_scale_dreadnought_c60.jpg) | [Context](N368_context_dreadnought.jpg) |
| Super-dreadnought | H4_11 | [170](N368_scale_super-dreadnought_c170.jpg) | [60](N368_scale_super-dreadnought_c60.jpg) | [Context](N368_context_super-dreadnought.jpg) |
| Battle-barge | C19_51 | [170](N368_scale_battle-barge_c170.jpg) | [60](N368_scale_battle-barge_c60.jpg) | [Context](N368_context_battle-barge.jpg) |
| Bio-titan | B16_23 | [170](N368_scale_bio-titan_c170.jpg) | [60](N368_scale_bio-titan_c60.jpg) | [Context](N368_context_bio-titan.jpg) |
| Ark | I8_37 | [170](N368_scale_ark_c170.jpg) | [60](N368_scale_ark_c60.jpg) | [Context](N368_context_ark.jpg) |
| Tomb-ark | D22_23 | [170](N368_scale_tomb-ark_c170.jpg) | [60](N368_scale_tomb-ark_c60.jpg) | [Context](N368_context_tomb-ark.jpg) |
| Bomber wing | voidsworn\|bomber | [170](N368_scale_squadron_bomber_c170.jpg) | [60](N368_scale_squadron_bomber_c60.jpg) | [Context](N368_context_squadron_bomber.jpg) |
| Squadron_spore | chorus\|spore | [170](N368_scale_squadron_spore_c170.jpg) | [60](N368_scale_squadron_spore_c60.jpg) | [Context](N368_context_squadron_spore.jpg) |
| Transport | O2_37 | [170](N368_scale_transport_c170.jpg) | [60](N368_scale_transport_c60.jpg) | [Context](N368_context_transport.jpg) |
