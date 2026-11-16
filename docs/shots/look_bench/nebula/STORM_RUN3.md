# Ion storm, run 3: R282

Refs #368. Ready for Ryan to judge the storm. This is the R282 storm-only redo on the resumed PR 717 source; the accepted nebula is preserved.

Start with [camera 170](N368A_storm_c170_before_after.jpg), then [camera 60](N368A_storm_c60_before_after.jpg). The warm contour pattern is replaced by layered blue-violet gas, pale cyan charge, and brief raised forks. The two native center crops use original screenshot pixels. No image is enlarged or sharpened. Class stills share camera targets and class lengths; live wing idle phases can differ between runs. Native hull gas/clear measurements use a frozen cruiser pair.

[Native 4K camera 170](N368A_storm_c170_native_4k.png), [native 4K camera 60](N368A_storm_c60_native_4k.png), [cloud and hull light](N368A_storm_light_c60.jpg), and [quality tiers](N368A_storm_run3_tiers.jpg). All 34 sheets are 1280 by 720. The shared folder also holds `N368A_storm_motion.gif`, a fixed-clock 30 fps study of one flash envelope, not a recording of the random strike schedule.

Evidence root: `C:/Users/rcbai/Downloads/voidsworn_test/board/issue-368/shots/`. Raw before and after captures are `run3_before/` and `run3_after/`; both include camera poses, hull masks and real scenario/class metadata. Every sheet linked here is also saved directly in that shared root.

Measured with the existing #207 scene gate and the unchanged issue-368 adapter, Forward+ on the RTX 5080. Timing runs used a solo GPU claim, 120 warmup frames and 720 measured frames per mode. Each batch ran twice and kept the second. Baseline and max have three sessions each; high and low have one kept session each. Values below are medians of the session medians.

| Storm | Sessions | Frame at 1080p, ms | GPU at 4K, ms | Gate |
|---|---:|---:|---:|---|
| before | 3 | 4.809 | 7.456 | PASS, every session below 12.5 ms |
| max | 3 | 6.669 | 7.331 | PASS, every session below 12.5 ms |
| high | 1 | 5.007 | 5.007 | PASS, every session below 12.5 ms |
| low | 1 | 3.103 | 3.581 | PASS, every session below 12.5 ms |

Observed max-minus-before delta: frame +1.860 ms; GPU -0.125 ms. The max frame-session medians are 6.141, 8.070, 6.669 ms. [Full timing summary](storm_gate_summary.json) includes all session values, counts and unchanged probe hashes; original reports are its named `run3_gate_*_keep/scene_gate.json` files under the shared root.

| Storm | Visible draw calls | Visible primitives | Shadow draw calls | Shadow primitives |
|---|---:|---:|---:|---:|
| before | 419 | 6,889,443 | 304 | 3,790,930 |
| max | 423 | 6,887,829 | 304 | 3,791,838 |
| high | 246 | 5,267,960 | 448 | 5,004,461 |
| low | 240 | 4,089,282 | 453 | 5,004,341 |

Native 4K hull measurements compare gas on with the same hull and lighting while only gas is hidden. Masks use the real hull triangles, eroded by two pixels to exclude raster edges. Contrast is the standard deviation of luminance on those pixels divided by the clear-frame value; no sky rectangle is used.

| Camera | Hull pixels | Contrast retained | Mean luma change, /255 | p95 RGB difference, /255 |
|---|---:|---:|---:|---:|
| 170 | 9,238 | 99.68% | -0.070 | 0.0 |
| 60 | 84,422 | 99.44% | -0.151 | 0.0 |

With ribbons hidden, switching the real nearest lightning light on adds 0.946/255 mean hull luminance at camera 60 (p95 3.076/255): a faint flicker. A separate pair holds direct light and shader charge fixed and switches only `light_volumetric_fog_energy`; 255,878 pixels change. That proves renderer light injection into the gas, independently of a ribbon or shader flash. Raw pairs are `storm_fog_c60_charge_*` and `storm_fog_c60_scattering_*` in `run3_after/`. [Measurements](storm_readability.json).

The real scenario generator produces storm patches of 13, 5 and 5 hexes. The isolated mask spans 83 units; max has three fog volumes, 38.5 units tall, with 52 card instances. High has 121 card instances and low 75, with no volumes. These sizes and the nebula mask are unchanged from the accepted build. [Actual geometry check](storm_geometry.json), [one scale table](../../../playbooks/scale.md).

| Class | Built code | Length | Camera 170 | Camera 60 |
|---|---|---:|---|---|
| Frigate | V14_23 | 10.40 | [170](N368A_storm_scale_frigate_c170.jpg) | [60](N368A_storm_scale_frigate_c60.jpg) |
| Destroyer | V15_37 | 15.20 | [170](N368A_storm_scale_destroyer_c170.jpg) | [60](N368A_storm_scale_destroyer_c60.jpg) |
| Cruiser | V16_37 | 23.20 | [170](N368A_storm_scale_cruiser_c170.jpg) | [60](N368A_storm_scale_cruiser_c60.jpg) |
| Carrier | V18_51 | 26.40 | [170](N368A_storm_scale_carrier_c170.jpg) | [60](N368A_storm_scale_carrier_c60.jpg) |
| Battleship | V17_37 | 33.60 | [170](N368A_storm_scale_battleship_c170.jpg) | [60](N368A_storm_scale_battleship_c60.jpg) |
| Dreadnought | V1b_r_23 | 43.20 | [170](N368A_storm_scale_dreadnought_c170.jpg) | [60](N368A_storm_scale_dreadnought_c60.jpg) |
| Super-dreadnought | H4_11 | 49.60 | [170](N368A_storm_scale_super-dreadnought_c170.jpg) | [60](N368A_storm_scale_super-dreadnought_c60.jpg) |
| Battle-barge | C19_51 | 41.60 | [170](N368A_storm_scale_battle-barge_c170.jpg) | [60](N368A_storm_scale_battle-barge_c60.jpg) |
| Bio-titan | B16_23 | 44.80 | [170](N368A_storm_scale_bio-titan_c170.jpg) | [60](N368A_storm_scale_bio-titan_c60.jpg) |
| Ark | I8_37 | 41.60 | [170](N368A_storm_scale_ark_c170.jpg) | [60](N368A_storm_scale_ark_c60.jpg) |
| Tomb-ark | D22_23 | 44.80 | [170](N368A_storm_scale_tomb-ark_c170.jpg) | [60](N368A_storm_scale_tomb-ark_c60.jpg) |
| Squadron_bomber | voidsworn|bomber | 3.84 | [170](N368A_storm_scale_squadron_bomber_c170.jpg) | [60](N368A_storm_scale_squadron_bomber_c60.jpg) |
| Squadron_spore | chorus|spore | 3.84 | [170](N368A_storm_scale_squadron_spore_c170.jpg) | [60](N368A_storm_scale_squadron_spore_c60.jpg) |
| Transport | O2_37 | 17.60 | [170](N368A_storm_scale_transport_c170.jpg) | [60](N368A_storm_scale_transport_c60.jpg) |

Changed files: `godot/world/world_living.gd` routes only storms to the new `ion_storm.gd`, raises storm forks and sends real tick/strike light into storm materials. `storm_capture.gd` and `.tscn` add the dedicated evidence capture. `render_storm.py`, this report, the 34 sheets and four JSON evidence files live here. No ship assets, gen files or uid files are deliverables.

Method: reuse the existing 128-cubed baked noise without rebaking; world-space storm mass and charge shaders; max fog plus edge cards, high/low cards; four existing lightning lights, with two allowed into max fog. Ship fog exclusion and the nebula faction cap remain as accepted. Both nebula shader strings and the mask are unchanged; nine accepted nebula/camera/tier input files match HEAD by SHA256 in [checks](storm_checks.json).

Checks: all standing checks completed, 57 PASS and two KNOWN baseline rows (seven listed finding failures and 12 listed oracle differences). Final scale check passed, 53 objects, four existing exceptions and no new failure. The real-state CPU geometry check passed across both routes and all three tiers. All captured shaders compiled and no capture log contains an error or placeholder hull. The source ship manifest matched all 252 copied files. GPU gate results are above. `git diff --check` passed.

R129: traced the world build and battle quality callers, storm material/volume setup, lightning updates and actual Ion storm tick presentation. No save, rule-twin, campaign or UI data changed. The full Godot parity suite was not repeated for this visual-only change; GitHub standing, parity and Godot checks run when the runner pushes. Broader nebula, planet, rock and campaign changes/captures were skipped under Run 3's storm-only scope.

Reproduce the sheets with `python docs/shots/look_bench/nebula/render_storm.py --before <shots>/run3_before --after <shots>/run3_after --output <shots> --repo-output docs/shots/look_bench/nebula --tiers --measurements`. Captures use `res://world/storm_capture.tscn -- --captures --four-k --scale-captures --map-case storm --go-file <gpu_go.txt> --out <dir>` through `tools/pc/tmo.bat`. Timings use the unchanged `res://world/nebula_bench.tscn`, modes `base,res_2160`, the tier, session count and frame counts above.

No commit or push was made. Stop here for Ryan's approval; the final look is not marked accepted. Outside check: Refs #256.
