# Hull-hit fragments, issue 1000

Hull hits throw buckled armour, snapped ribs and tapered glass fractures. Larger pieces roll away from the wound and stay close to it. Smaller pieces race along the skip direction or drift between the two groups. Only up to two pieces get a screen-size floor.

Each of the six templates has two caps and six walls. The caps carry worn hull paint in the target faction's colours. The fracture walls catch the existing impact light and cool from orange to bare alloy or glass. The templates are built once and share one draw and the original 384-slot Max / 192-slot lower-quality pool. Chorus retains the tissue sprites.

## Before and after

Start at [battle camera 170](hull_fragments_c170.png) for the size of the pieces in play. The closer sheets use the closest battle camera, 26. Each panel is a 1:1 crop from a 1920 by 1080 frame and shows the same hit about 0.35 and 1.20 seconds after contact.

| Target | Hit | Closest battle camera |
| --- | --- | --- |
| H9_23, Hegemony Navy | Macro | [Steel plate and rib](H9_23_macro_fragments_c26.png) |
| C19_51, Ashfall Hullbreakers | Macro | [Painted armour](C19_51_macro_fragments_c26.png) |
| I15_11, Glasswrights | Macro | [Tapered glass](I15_11_macro_fragments_c26.png) |
| H9_23, Hegemony Navy | Torpedo | [Heavy hit](H9_23_torpedo_fragments_c26.png) |

The look bench plays one round per row on the fixed 60 Hz effects clock, with one shared launch seed and the same installed ship assets on both revisions. The C19_51 row uses a wider native source crop so it includes the fragments beside the turret. The sheets carry both source revisions and the in-game stage.

The torpedo's later frame shows the fracture walls and bent faces most clearly. At camera 170 the lighter chips disappear sooner, and the larger pieces stay nearer the hull. The Glasswright fragments read as short pale glints at that distance. Their pointed shapes are clearest in the camera 26 crop.

Both revisions ran the look bench twice. The second captures are shown here. All pre-hit frames matched within the standing tolerance, and the shield and las controls differed by at most 0.00002 mean RGB levels. The largest difference between repeats was 0.216 levels against a tolerance of 2.0. The multi-row look bench hit a Windows teardown error on both revisions after saving the complete capture sets. The reports and picture stamps verified. [Frame comparisons](look_differences.json)

## Scene 207

All six updated gate measurements passed 12.5 ms. The RTX 5080 ran the 20-ship storm scene through the solo watchdog claim at both resolutions. Each revision ran three sessions and each mode used 120 warm-up frames and 720 measured frames. The 4K mode draws the 3D scene at 3840 by 2160 with the HUD at 1080p.

| Gate measure | Before, ms | After, ms | Change, ms | Highest after, ms |
| --- | ---: | ---: | ---: | ---: |
| 1080p frame median | 9.554 | 10.415 | +0.861 | 12.216 |
| 4K GPU median | 5.929 | 5.894 | -0.035 | 5.954 |

The table uses the median across sessions. At 1080p the GPU median moved from 2.700 to 2.619 ms. Run-to-run variation covers the GPU changes at both resolutions. The updated full-frame medians at 4K were 9.751 to 12.716 ms. The gate uses GPU time in that mode. [Baseline report](gate_before.json) · [Updated report](gate_after.json)

## Checks

The focused Godot check welds the cap and wall vertices and checks that each edge has two opposite uses, with real volume and outward shading normals. It also checks the pool caps, the seven-piece test burst, the glass and Chorus paths, the lead-piece floor and the random draw order. The existing hit-recipe check covers the approved staging, outward travel and flash comfort.

Both Godot checks passed. The standing suite returned 64 PASS, two KNOWN and zero FAIL. The known rows are the seven listed findings and twelve oracle constant differences.

```text
godot --headless --path godot --script res://tests/hit_fragments_check.gd
godot --headless --path godot --script res://fx/test/hit_recipe_check.gd
node contrib/opus/tools/run_all_checks.js
```
