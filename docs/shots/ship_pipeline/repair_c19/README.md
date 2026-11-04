# Pyre-Barge repair in place, issue 129

My pick is stage 5 with hand-built guns, engine and bridge. Repair in place keeps today's busy silhouette, and the replacement parts read more clearly. This test does **not** reach the concept's shape or pass the final blob sweep. Do not ship this prototype or roll it across the fleet yet.

The five stages are built, with stage 4 shown as both 4a and 4b. Today's packed game scene is the control. Repairs start from today's intact `a4/out/C19_51/C19_51_ship.npz`, not the clean shell from round 2. No shipping asset, game source, player save or setting was changed. Nothing was committed or pushed.

The scripts and double-click runner are in [hull_repair](../../../../tools/blender/hull_repair/README.md). These sheets, this report, full-size PNGs, AI crops, prompts, histories and measurement records are also saved in `C:\Users\rcbai\Downloads\voidsworn_test\board\issue-129\shots` for Opus.

| Evidence | What it shows |
|---|---|
| [All stages and concept](stages_and_concept.webp) | Battle r=170 at 1:1 crop, close zoom, round 1 detail crop, front, side and approximate concept-quarter direction |
| [Readable page 1](stages_readable_1.webp), [page 2](stages_readable_2.webp) | The same panels with fewer columns |
| [Actual game](ingame_stages.webp) | Every stage at battle distance and close zoom, with the real board, HUD, ShipView and G4 lighting |
| [Panel and blob crops](panel_and_blob_crops.webp) | The same selected wavy plate head-on and grazing, plus the same fused bridge region, for every stage |
| [Hand versus AI parts](hand_vs_ai_parts.webp) | Engine, matched gun pair and bridge, with reference crops and machine times |
| [Midships join trial](midships_join_trial.webp) | An independently generated section between two cuts; excluded from stage 5 |
| [Final nine cells](final_nine_cells.webp) | Top, side and underside thirds beside the relevant side-reference regions |

What each step changed:

1. **Strip maps:** removes both the projected concept albedo and the AI normal map. The round 2 Hullbreaker trim is byte-identical to the committed reference. The remaining lumps are visible geometry. Colour and much of the painted detail disappear too, so this is not a free visual improvement.
2. **Flatten:** moves 2,572 vertices on 42 large wavy panels; all selected borders stay fixed. Mean panel RMS deviation falls from 0.001631 to 0.001535 ship lengths, about 6 percent. Small details are retained. The grazing crop still shows broad waviness.
3. **Separate:** identifies 176 large regions, splits their crease topology and shading, sinks narrow grooves, adds dark groove floors and thin worn-edge strips, and varies each region's trim value. This helps some plate boundaries. It cannot turn a fused gun or tank into a correctly shaped separate part. The resumed whole-triangle wear mask was replaced because it produced large patchy areas.
4. **Replace:** cuts the original engine, one gun pair and upper bridge region, closes the cuts and seats replacements on measured flanges. Hand parts have bevels, seams, fasteners, cooling fins, recessed bores and trim wear. The AI alternative uses isolated Qwen crops and full-resolution Pixal3D parts. Raw inward winding, the conditioning camera's axes and glTF trim V orientation are corrected. No decimation is used.
5. **Final:** selects the hand parts and adds weighted normals. Hull plus parts keep the same length bounds and 41.6 game length. The new gun axes are forward or outward, and paired mounts are checked against the repaired hull. Remaining source protrusions are listed as unresolved below.

The AI engine crop expands into a compact stern assembly with neighbouring structures. The bridge retry still invents a tall stepped tower instead of preserving the low wide bridge. The gun has a more distinct outline than the fused source, but still reads as disconnected masses with broken-looking surface detail after basic cleanup and mount fitting. None earns its native geometry cost here. The midships section has independent end contours and does not join cleanly to both neighbours. Its joins remain unwelded; it is not hidden inside the final ship.

<!-- performance-start -->
| Stage | Triangles per ship | 20 ships GPU ms | Frame median ms | Frame p99 ms |
|---|---:|---:|---:|---:|
| today | 256,468 | 2.683 | 2.749 | 3.281 |
| S1 | 256,428 | 3.486 | 3.567 | 4.269 |
| S2 | 256,428 | 3.556 | 3.639 | 4.350 |
| S3 | 293,308 | 4.038 | 4.108 | 4.812 |
| S4a | 305,857 | 3.836 | 3.917 | 4.608 |
| S4b | 83,207,937 | 243.417 | 243.605 | 244.804 |
| S5 | 305,857 | 3.917 | 4.000 | 4.706 |
<!-- performance-end -->

These are isolated rendering measurements on RTX 5080, Godot 4.7.2 Forward+, 1920x1080, MSAA 4x, identical G4 studio lights and compressed mipmapped maps. Each case warms for 100 frames and measures 360. Twenty non-overlapping ships share mesh resources in the same 5 by 4 layout. Frame time is measured elapsed frame time; GPU time comes from Godot's viewport timer. These figures are not a 4K whole-battle benchmark, a 20-distinct-asset memory test or an animation test. Actual-game screenshots are separate evidence. The part comparison alone adds the same 0.9-energy camera-direction inspection light to both versions; it is removed before measurements.

<!-- timing-start -->
| Part | Qwen isolation s | Pixal3D generation s | Native triangles | Array cleanup and scale s | Hand construction and detail s |
|---|---:|---:|---:|---:|---:|
| engine | 51.1 | 150.1 | 22,812,022 | 10.8 | 0.436 |
| gun | 48.1 | 84.1 | 17,530,382 | 8.2 | 0.561 |
| bridge | 45.0 | 102.3 | 25,057,318 | 11.9 | 0.320 |
| midships | 45.1 | 87.1 | 19,964,626 | 9.3 | not used |

The gun is generated once and instanced as a pair. Hand gun construction includes both guns. Bridge times show the retained retry; the first attempt additionally took 42.0 s isolation and 45.2 s generation. Array cleanup includes winding, normals, UVs and uniform scale. Hand topology cleanup is zero because the parts are authored; neither column includes manual design time.
<!-- timing-end -->

Times in the part sheet and table are **machine execution only**. They exclude writing the scripts, looking at failures and correcting fits. The first bridge attempt is retained alongside its targeted retry. Generation histories and cleanup records are in `ai_parts.json` and `ai_packed.json`.

Final blob sweep, from the retained stage 5 renders:

| Region | Top | Side | Below |
|---|---|---|---|
| Bow | **Rebuild by hand:** crossed prongs and fused upper fittings | **Rebuild by hand:** rounded front armour and merged sponson shapes | **Rebuild by hand:** claw-like debris and blended belly transitions |
| Midship | **Rebuild by hand:** fused tank and weapon-base clusters | **Rebuild by hand:** wavy flank panels and merged pipe roots | **Rebuild by hand:** blended belly panels and machinery blocks |
| Stern | **Rebuild by hand:** ragged sensor/fin cluster behind the new bridge | **Rebuild by hand:** old piping and stubs around the new engine | **Rebuild by hand:** fused engine-root and pipe joins |

The new hero parts are clearer, but no complete region is clean. Top and underside concept views were not supplied; side references locate the intended parts and cannot prove hidden geometry. The retained hull's broad masses also differ from the concept. I have not marked the shipping ship queue complete.

My rollout estimate is **8 to 12 focused hours for one mid-size mechanical hull to reach nine clean cells**, once these tools and a useful faction kit exist. Allow roughly 2 hours for the concept and cut map, 3 to 5 for replacement and fitting, 1 to 2 for materials and seams, and 2 to 3 for captures and corrections. This is an estimate, not measured production throughput. A first comparison is much faster than a finished hull; native part generation in minutes does not remove the manual review work.

**Use AI part generation to propose a reviewed per-faction part library.** Generate and repair a good gun, engine or sensor once, then reuse the approved part with shared materials and measured mounts. Do not make these four raw candidates the library, or regenerate every bolt-on for every ship. Hand-built parts remain the default until an AI candidate wins shape, mounting and frame checks. Do not apply a mechanical kit blindly to Chorus or Glasswrights.

Checks: all 25 standing checks pass with Node 22.11.0, with no unexpected findings-test failures. Godot headless parity passes all 54 scenarios, three 10,000-draw PRNG cases, math, three threat maps, threads and the hard stop. Export/reimport counts, source and trim hashes, stage differences, screenshot sizes, selected border positions, new gun axes, mount anchors and unchanged shipping files are checked by the experiment verifier. See [checks](checks.json), [verification](verification.json), [measurements](gpu.json), [build records](builds.json) and [parity transcript](parity.txt).

Not checked: damage breakup, rotating turrets, multiple maps, 4K performance, distinct fleet memory and final owner approval. Shipping integration and a complete manual rebuild of every failed cell are outside this comparison. The visual sweep is a failure even though the experiment and PR checks pass.
