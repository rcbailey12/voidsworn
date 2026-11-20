# C11 Bladeback, run 7

Refs #1058. This is a paint proof in an isolated Godot review build. The
shared build awaits Ryan's decision on the finish.

Run 7 grows 18 separate scutes with raised, scalloped lips and wet gaps. It
keeps the matte shell dark and the maws amber. Pale backswept spines now
rise above the dorsal sockets. [Build sheet and kit calls](../../ship_pipeline/build_sheets/chorus_C11/README.md)

The sheet places the archived run 6 beside run 7 and the accepted C19_51
at radii 170 and 26. Run 7 and C19_51 were captured together with the same
camera and light at both radii. The bottom row shows the dorsal sockets
and amber maws. [1280 by 720 paint proof](C11_finish_run7.jpg)

The recipe selects the shared Chorus paint stack. Stage 5 uses 4096-pixel
hull and parts atlases at 64 samples. Stage 6 reads that painted blend.
Stage 7 exports 2048-pixel maps and installs into the isolated project.
The bake used main at `cebebdd6` as its base, which includes PR 1173
(`8cf0e800`, lossless ORM and normal maps) and PR 1179 (`aa3eae59`, shared
ship job). C11 uses the primary hull and parts atlases, so the base's
texture-role export route applies directly. [Recipe](../../../tools/recipe/ships/chorus_C11.json)

The proof used a fresh scratch copy of the base plus the C11 changes.
The tested source input list has SHA-256
`46bd36415a8bde6c6c90e652c8e937189c518bb0bcbd13acb331ab66ddd0fb10`.
The source is uncommitted, so the paint proof records the base and tested
snapshot.

## Checks

- Stage 4 contract, audit and outline records passed. The fit and weapon
  checks found zero problems after clearing the aft siphons. Blender
  verified 18 closed scutes. Concept-camera outline overlap was 59.7%,
  against 59.9% for the earlier recipe proof using the same camera.
- Stage 5 used OptiX at the recipe's full bake settings. The six-view surface
  check found zero exposed room-colour or unpainted pixels. The three
  diagnostic angles for the standing checks used Blender's CPU preview.
  Fitting texel density was 0.67 to 0.69 of the hull's density. R224 reports
  five paint-density flags and zero mesh-density flags.
- Stage 6 passed the Godot LOD bench. LOD 0 through 3 contain 182,348,
  167,940, 86,726 and 42,028 triangles. At 1080p, 20 full-detail copies
  used 150 draws, up from 130 in the run 6 bench.
- The Stage 7 export and planted-fault checks passed. The isolated install
  read back all 22 hard points headlessly and on the GPU. The authored damage
  route and both tear paths passed with 13 machines, zero splits and zero
  interior triangles outside their wreck pieces.
- The standing suite returned 75 passes, two known baselines, and one
  Windows runner self-test failure. The direct retry reproduced
  `mock agent never reached its checkout`.

## Cruiser cost

The export has 182,348 triangles across 16 surfaces. That includes 14,408
triangles in nine interior surfaces. Run 6 exported 186,548 triangles
across 14 surfaces. The original scene 207 cruiser-tier reference peaked
at 171,919 hull triangles and 20 surfaces per ship. C11 has 167,940
exterior triangles. The measured frame time is the binding budget.
[Scene 207 reference](../ship_pipeline/bench207/README.md)

The `B21_11` manifest records four breach anchors and two authored seams.
The exported GLB has SHA-256
`ee26567eb5661bdd1e32ae101c343d261586ac6dd147f27cffa92fbd98259083`.
Both atlases have JPG albedo and lossless PNG normal and ORM maps. Fifteen
materials carry `authored_look`, including both amber maw materials.
The precheck and Stage 7 export produced identical GLB and map hashes.

### Scene 207

The isolated storm battle used C11 in the Spitter slot, as in run 6. The
report counted 24 ships including strike craft and confirmed that C11
loaded from the ship cache. Its runtime hull counted 182,576 triangles
and 18 surfaces.

Godot 4.7.2 ran Forward+ on the RTX 5080 under a solo GPU claim. Each
session warmed up for 180 frames and measured 720 frames at 1080p and
with 3D at 4K. The retry gave the cold terrain bake more time before the
warm-up and measurements.

| Session | 1080p frame median | 1080p GPU median | 1080p visible + shadow draws | 4K GPU median |
| --- | ---: | ---: | ---: | ---: |
| 1 | 5.848 ms | 2.712 ms | 476 + 301 | 5.952 ms |
| 2 | 6.752 ms | 2.676 ms | 507 + 322 | 5.898 ms |
| 3 | 6.286 ms | 2.703 ms | 442 + 299 | 5.943 ms |

All three sessions passed the 12.5 ms gate. Across sessions, the 1080p
frame median was 6.286 ms and the 4K GPU median was 5.943 ms.
