# Hull-hit fragments, issue 1000 run 2

Macro hits emit about 30 percent more solid pieces at Max and High. A few large buckled plates and broken ribs tumble slowly near the wound. Smaller jagged pieces spread along the skip direction. The two lead pieces get the strongest size boost at battle distance. The smallest pieces keep their world size.

The outer faces use the target faction's paint. Steel and rust-red armour have burned undersides and ember rims that cool in about one second. The Glasswright shards catch pale glints as they turn. The existing impact light illuminates the debris. The fire body has a slightly larger footprint and keeps its original timing. Soot retains its seeded placement, density and lifetime.

## Before and after

The sheets show main and the updated working tree at +0.35 s and +1.20 s after contact. Each panel uses 1080p source pixels at 1:1. The look bench uses the same installed ship assets, launch seed and fixed 60 Hz clock in both runs. The close Hullbreaker sheet uses a wider source crop to keep the area beside the turret visible.

| Target | Hit | Battle camera 170 | Closest camera 26 |
| --- | --- | --- | --- |
| H9_23, Hegemony Navy | Macro | [Battle](H9_23_macro_fragments_c170.png) | [Close](H9_23_macro_fragments_c26.png) |
| C19_51, Ashfall Hullbreakers | Macro | [Battle](C19_51_macro_fragments_c170.png) | [Close](C19_51_macro_fragments_c26.png) |
| I15_11, Glasswrights | Macro | [Battle](I15_11_macro_fragments_c170.png) | [Close](I15_11_macro_fragments_c26.png) |
| H9_23, Hegemony Navy | Torpedo | [Battle overview](hull_fragments_c170.png) | [Close](H9_23_torpedo_fragments_c26.png) |

The Hegemony torpedo close-up shows the thickness, black undersides and hot rims most clearly. At camera 170 the heavier pieces are visible next to the wound. The smallest cooled pieces are faint against the starfield at +1.20 s.

Both main and the updated project ran twice at cameras 170, 60 and 26. The second runs supplied the pictures. The largest repeat difference was 0.217 mean RGB levels, against the 2.0-level tolerance. The pre-hit frames matched exactly, and the shield and las controls differed by at most 0.00003 levels. The one frame above tolerance was the H9_23 torpedo at camera 26, +0.35 s. Both revisions hit the same Windows teardown fault after saving every multi-row strip. The wide Hullbreaker captures exited normally. All eight picture stamps verified. [Frame comparisons](look_differences.json)

## Scene 207

The three-session medians were below the 12.5 ms gate in both updated batches. One 1080p session in each batch exceeded 12.5 ms, including main. The updated peaks were 15.199 ms in the first batch and 13.998 ms on repeat. The range of observed frame times is larger than the difference between the before and after medians.

The RTX 5080 ran the same 20-ship storm scene under exclusive watchdog claims. Each mode used 120 warm-up frames and 720 measured frames per session. The 4K mode draws the scene at 3840 by 2160 with the HUD at 1080p. Values in the median columns are medians of the three session medians.

| Run | 1080p frame median, ms | Highest 1080p session, ms | 4K GPU median, ms | Highest 4K session, ms |
| --- | ---: | ---: | ---: | ---: |
| [Main](gate_before.json) | 11.108 | 12.900 | 5.909 | 5.933 |
| [Updated, first batch](gate_after_first.json) | 12.383 | 15.199 | 5.840 | 5.842 |
| [Updated, repeat](gate_after.json) | 10.928 | 13.998 | 5.841 | 5.975 |

## Checks

The fragment check lives in godot/fx/test/ and runs through godot/tools/ci/godot_checks.txt. It checks closed meshes with real volume, outward flight, faction paint and glass, larger macro bursts, lead-piece size and motion, bounded pools and the seeded sequence used by later effects.

The CI manifest passed with 105 registered scripts. The fragment, hit recipe, flash area, late shader and effects smoke checks passed. Standing checks returned 64 PASS, two KNOWN and zero FAIL. The two known rows cover seven listed findings and twelve oracle constant differences.

## Run 3. Detailed hull fragments and crisp sparks

The twelve plates, ribs and glass shards have 30 jagged rim points, 482 vertices and 600 triangles each. Rounded bevels catch the light along the bent faces. The exposed edges show paint, scratched alloy and a ribbed lining. The larger pieces still tumble near the wound, with hot edges cooling over about a second.

Each burst looks up the struck triangle and samples a patch of the ship's own colour, ORM and normal maps at their installed resolution. C19_51 uses the same baked hull and parts finish as issue 1016. Unpainted fittings can borrow paint from an adjacent hull face. Hits without a usable texture patch or beyond the eight simultaneous finish bindings use a procedural finish in the same faction colours. Compatibility mode has three bindings.

The opaque fragments share the ships' viewport and 4x MSAA. The pool uses one instanced draw and submits only live or scheduled pieces. Scene 207 passed with the same dense geometry at every camera distance.

The old hull spark paired a soft, premultiplied glow sprite with a 4.5 px minimum diameter at 1080p and an additive streak filtered from a 256 by 96 texture. Both drew in the main 3D viewport. Each hull-hit spark now uses one additive streak with tapered edges calculated at scene resolution. Speed and age set its length. A white-hot head cools to the target faction's colour, with a small halo at the head.

### Run 3 pictures

The look bench used the same installed ships on `12c4ce674` and `7e070846`. It ran twice on each at cameras 170, 60 and 26, with separate native 4K passes. The sheets show the second passes at +0.23 s and +0.75 s after contact. Every panel keeps the source pixels at 1:1.

| Target | Hit | Battle camera 170 | Closest camera 26 |
| --- | --- | --- | --- |
| H9_23, Hegemony Navy | Macro | [Battle](../issue-1000-codex/run3-final/run3_H9_23_macro_fragments_c170.png) | [Close](../issue-1000-codex/run3-final/run3_H9_23_macro_fragments_c26.png) |
| H9_23, Hegemony Navy | Torpedo | [Battle](../issue-1000-codex/run3-final/run3_H9_23_torpedo_fragments_c170.png) | [Close](../issue-1000-codex/run3-final/run3_H9_23_torpedo_fragments_c26.png) |
| C19_51, Ashfall Hullbreakers | Macro | [Battle](../issue-1000-codex/run3-final/run3_C19_51_macro_fragments_c170.png) | [Close](../issue-1000-codex/run3-final/run3_C19_51_macro_fragments_c26.png) |
| C19_51, Ashfall Hullbreakers | Torpedo | [Battle](../issue-1000-codex/run3-final/run3_C19_51_torpedo_fragments_c170.png) | [Close](../issue-1000-codex/run3-final/run3_C19_51_torpedo_fragments_c26.png) |
| I15_11, Glasswrights | Macro | [Battle](../issue-1000-codex/run3-final/run3_I15_11_macro_fragments_c170.png) | [Close](../issue-1000-codex/run3-final/run3_I15_11_macro_fragments_c26.png) |
| I15_11, Glasswrights | Torpedo | [Battle](../issue-1000-codex/run3-final/run3_I15_11_torpedo_fragments_c170.png) | [Close](../issue-1000-codex/run3-final/run3_I15_11_torpedo_fragments_c26.png) |

At the battle camera, the spark fan is clearest on the Hullbreaker macro hit. The heavier pieces stay visible near the wound, and the smallest cooled flecks blend into the starfield. The Hullbreaker close-up shows red paint around the torn alloy. Glasswright shards keep their pale glints. The Hegemony torpedo crop shows the rolled metal edge and lining at full size. [Native 4K crop](../issue-1000-codex/run3-final/run3_H9_23_torpedo_fragments_c26_4k.png)

All 13 picture stamps verified. The repeat captures matched to the recorded precision. The largest difference before contact was 0.059 mean RGB levels. The las and shield controls differed by at most 0.057 levels, within the bench tolerance of 2.0. Both updated 1080p captures saved all their strips before the Windows renderer teardown fault. Both updated native 4K captures exited normally. [Run 3 frame comparisons](look_differences_run3.json)

### Run 3 Scene 207

The RTX 5080 ran the 20-ship storm battle under solo GPU claims, with active fragments and sparks. Each resolution used three sessions with 120 warm-up frames and 720 measured frames apiece. The 4K mode draws the 3D scene at 3840 by 2160 with the HUD at 1080p. The number of volleys varied with elapsed time across the samples.

| Run | 1080p frame sessions, ms | 1080p median, ms | 4K GPU sessions, ms | 4K median, ms |
| --- | ---: | ---: | ---: | ---: |
| [Before](gate_before_run3.json) | 9.875, 9.942, 8.906 | 9.875 | 6.522, 6.598, 6.533 | 6.533 |
| [After](gate_after_run3.json) | 10.083, 6.953, 6.924 | 6.953 | 5.804, 5.691, 5.783 | 5.783 |

All three updated 1080p sessions passed the 12.5 ms gate.

### Run 3 checks

The fragment, hit recipe, flash area, late shader and effects smoke checks passed. The Godot CI list matched all 105 registered scripts. The standing suite returned 64 passes and two known results. The Windows runner self-test timed out at its 600 s limit.
