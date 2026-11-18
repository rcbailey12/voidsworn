# Painted metal across the Navy and Hullbreaker fleet

Refs #1016, run 3. The pictures compare the installed main build at 7d6e76c with the isolated review build. Each
sheet shows the battle camera at radius 170 at native pixel size and a matched crop at radius 26. The three
ships approved in run 2 have their own comparisons. [Run 2 review sheets](../README.md)

## Method

The four Hullbreaker rebuilds use their existing build sheets. Stages 5 and 6 baked the two 4096 px OptiX
atlases at 64 samples and measured LOD0. The stage 7 export passed the hard-point check and its planted faults.
The review bundles keep the published GLBs, after comparing the rebuilt exterior triangles and atlas UVs. The
existing 2048 px hull albedo, ORM and normal and the fittings albedo and ORM carry the new finish. The fittings
albedo uses 65 percent of the new bake over the original paint to keep adjacent pieces within the colour limit.
The roughness maps carry the full new bake. Red oxidation, uneven repair plates and trophy colours stay visible.
[A18](../../../ship_pipeline/build_sheets/corsair_A18/README.md),
[A19](../../../ship_pipeline/build_sheets/corsair_A19/README.md),
[A17](../../../ship_pipeline/build_sheets/corsair_A17/README.md),
[A20](../../../ship_pipeline/build_sheets/corsair_A20/README.md)

The Navy frigate, destroyer, cruiser, convoy transport, relay beacon, fighter and bomber use the A4 finish
route. The geometry supplies convex edges and recesses, and the existing maps supply the livery, seams and
relief. The bake adds the approved satin roughness and wears the raised edges using the same Navy stack. The
Defence station O1_37 is outside the rollout. The fighter and bomber images use their manifest models through
the look bench. Launched squadrons use Godot's procedural craft. [Ship recipe](../../../ship_pipeline/RECIPE.md)

The ship manifest records the new image bytes and hashes. GLBs and emission retain their main hashes, including
the separate Navy break and wreck GLBs. Each ship keeps its texture count and dimensions. [Ship
manifest](../../../../godot/assets/ships/manifest.json) [Budgets and stage 6 draw calls](budgets.csv)

## Battle-camera comparison

The change is mean absolute RGB difference on the ship silhouette, in 8-bit levels. The close crop uses the same
view on both sides. The sheets preserve native battle-camera scale, so the smaller craft occupy only a few
pixels.

| Ship and review sheet | Battle change | Manifest size change | Visible change |
|---|---:|---:|---|
| [C13s_23](C13s_23_finish.jpg) | 7.25 | +374,313 B | Brighter fitting rims and more visible steel along the bow. |
| [C14s_23](C14s_23_finish.jpg) | 6.71 | +308,540 B | Bow and turret edges separate more clearly from the rust and violet plates. |
| [C15s_23](C15s_23_finish.jpg) | 9.51 | +417,004 B | Raised deck rims catch more light and the turret bases read more clearly. |
| [C16s_23](C16s_23_finish.jpg) | 10.21 | +286,451 B | The deck has brighter plate edges and deeper gaps around the fittings. |
| [H7_23](H7_23_finish.jpg) | 16.95 | -312,780 B | The pale deck darkens slightly and the blue bands remain easy to see. |
| [H8_23](H8_23_finish.jpg) | 16.21 | -353,339 B | The deck has a brighter local glint and stronger shadows around its raised blocks. |
| [H9_23](H9_23_finish.jpg) | 17.23 | -396,292 B | The lower flank deepens and the lines between the pale plates become clearer. |
| [O2_37](O2_37_finish.jpg) | 15.31 | -692,975 B | The cargo body darkens and the amber stripe keeps its contrast. |
| [O3_11](O3_11_finish.jpg) | 11.05 | -560,801 B | A stronger glint runs along the base of the tower and its supports. |
| [S1_51](S1_51_finish.jpg) | 10.99 | -145,240 B | Shading across the wings is stronger. The craft covers 112 pixels at radius 170. |
| [S2_23](S2_23_finish.jpg) | 9.64 | -99,987 B | The wings and fuselage separate more clearly at close zoom. The battle-camera change is subtle. |

[Battle and close crop measurements](battle_comparison.csv)

## Checks

- Both fleet runs used the current main project code. The second before and second after runs each drew 36 hulls in six skies. All 150 views outside the rollout matched pixel for pixel. [Fleet comparison](fleet_comparison.csv)
- All 15 exterior atlases passed paint lint. The largest share of adjacent pairs at or above 18 dE76 was 9.02% on H9_23, under the 10% threshold. The Hullbreaker reports retain the existing flags for flat interior materials. [Paint lint](paint_lint.csv)
- Scene 207 ran alone on the RTX 5080 in Forward+ with 24 units. It measured **5.89 ms** median frame time at 1080p and **5.77 ms** median GPU time at 4K. All three sessions at each resolution passed the 12.5 ms limit. [Scene 207 timing](scene_gate.csv)
- Godot read back all 11 ships in the isolated review build and its manifest matched all 255 listed files. The 41 updated textures reduce the manifest's total file bytes by 1,175,106 B. The Board's checked bundles are in the issue output folder under `finish_1118_fleet_exports`.
- The shared build passed the main manifest check for all 255 files after installing H4_11, H10_23 and C19_51. All 30 sampled material slots matched the approved run 2 import. The standing suite reported 66 passes and two known baselines. The turret, install refresh and A16 death-seam checks passed and the fixture hash matches.
