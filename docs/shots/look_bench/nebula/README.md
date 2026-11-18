# Issue 368: nebula and ion storm

Current build and evidence: [Run 6, forked multi-strike storms](RUN6.md).
Read [camera 170](N368A_R6_lightning_c170.jpg) first, then
[camera 60](N368A_R6_lightning_c60.jpg) and the [six-frame strip](N368A_R6_strike_c170.jpg).
Run 6 keeps the accepted calm purple nebula from run 5, with 2 to 4 strikes per
storm patch, tapered branches, cyan cloud light and violet/cyan bloom fringes.
Low and High retain cards; Max retains fog plus cards. Ryan approval is pending.
[Run 5](RUN5.md) and [Run 4](RUN4.md) are the prior review records.

The Step 1 route comparison below is a historical record, before the route pick.

## Step 1: route comparison before Ryan's pick

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
