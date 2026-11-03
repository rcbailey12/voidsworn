# Pyre-Barge surface bake-off, round 2

My pick is **A+ rich surface**. Its plates, mounts, conduits and worn edges are controlled shapes. The copied-detail bake removes broad normal-map waves, but still ghosts medium-scale donor machinery onto some panels. Reused chunks preserve irregular detail, but a flat mounting face does not cure a soft source part. A+ is still more regular and blocky than today's ship. The [nine-cell verdicts](SWEEP.md) name the remaining work. These are the requested roughly 80-percent route prototypes, not replacement game assets.

Open the [four-way battle, close and detail sheet](comparison_C19_51.webp), [actual in-game sheet](ingame_C19_51.webp), [head-on and grazing panel proof](wavy_panel_proof.webp), and [top, side and below sweep](sweep_C19_51.webp). The battle row is a labelled 1:1 centre crop of the r=170 frame, without enlargement. Full 1920x1080 frames are retained in `C:\Users\rcbai\Downloads\voidsworn_test\board\issue-111\shots`. The close row uses round 1's direction and distance, 49.92. The detail crop is exactly round 1's `(600,340,1320,660)` rectangle.

All three use the same [Hullbreaker trim sheet](Hullbreaker_trim.png), with bone, rust, soot, steel, vent and marking bands. No concept paint is projected and no donor colour is copied. Four clean masses now follow the carrier, port capture, starboard capture and centred upper capture. Flat armoured bellies, vertical bow faces, chines, radiators, antenna arrays, service trunks, engine hardware and ventral thrusters replace the boat-like round 1 treatment. A+ has 348 surface clusters; the other two have 235 plus their route-specific detail. Shared geometry includes forward/outward guns, flanges, bevels, weighted normals, bolts, hatches, vents, pipes and registration markings.

The final variants have identical exported bounds. At the same 41.6 game-unit length, height is 6.3 percent and beam 9.5 percent above today's donor. They are close mass matches, not exact silhouette copies. The exporter applies the joined kit's transform before measuring bounds; otherwise its rotated local box falsely enlarges the ship. The verifier rejects a relative beam or height error above 15 percent. No shipping hull, map or packed scene was replaced.

The copied-detail variant selected-to-active bakes normals, AO and Cycles geometry pointiness from today's donor on OPTIX. Pointiness is a curvature estimate, baked through emission. Its normal filter removes the low-frequency deviation from `(0,0,1)`, adds that flat tangent normal back, caps tilt and renormalizes. It never recentres the complete map to grey. Low-frequency vector RMS falls from 0.56947 to 0.05322 after filtering and the tilt cap; mean normal Z is 0.98158. This is a map statistic, not whole-hull visual approval. The proof shows both angles and the sweep flags the remaining ghost shapes. Fine detail is also softened. The shared trim is resampled into the unique bake atlas so all exported textures use UV0 reliably in Godot.

The reused-parts variant has 14 small sensor, machinery, service and engine-housing chunks, each no larger than 0.062 donor units, about six percent of the ship length. Coincident vertices, collapsed triangles and tiny loose islands are cleaned with array operations. Explicit flat bottom faces and visible mounted skirts seat them on the clean shell. Exposed cuts and soft source edges still need individual finishing. No large AI hull section is retained.

| Route | Triangles | GPU ms, 1 ship | GPU ms, 20 ships | Frame ms, 20 ships / p99 |
|---|---:|---:|---:|---:|
| Today | 256,468 | 0.566 | 3.036 | 3.652 / 3.905 |
| 1: A+ rich surface | 613,864 | 0.682 | 5.687 | 6.262 / 6.611 |
| 2: Clean shell plus bake | 438,732 | 0.609 | 4.232 | 4.887 / 5.155 |
| 3: Clean hull plus reused parts | 456,460 | 0.611 | 4.397 | 5.037 / 5.428 |

RTX 5080, Godot 4.7.2 Forward+, 1920x1080, G4 max lights, AgX, MSAA 4x, compressed mipmapped maps, no vsync. Each case uses 100 warm-up and 360 measured frames. Twenty shared copies sit in a non-overlapping 5 by 4 layout, exactly as round 1. These figures include the isolated scene, without battle rules, effects, terrain or damage. A+ costs more than today; no triangle limit or decimation was used. Frame p99 is a short sampled percentile, not a sustained 1% low. [Raw measurements](measurements.json) retain the empty-scene control and CPU figures.

| Route | Focused hours to finish this Pyre-Barge | First mid-size machine hull using these tools |
|---|---|---|
| A+ | 4 to 8: distinctive upper fittings, rear machinery, more varied armour and final review | 6 to 10: measure clean masses, place the faction's kit and review all nine cells |
| Copied detail | 8 to 14: isolate bake sources, tune cages and frequency bands, remove ghost forms, finish shared fittings | 8 to 14: author the clean shell, tune that donor's transfer, then review |
| Reused parts | 8 to 12: finish cut edges, planarize or replace soft chunks, refine mounts and shared fittings | 8 to 14: select and clean a new set of useful parts, author the clean shell and review |

These are estimates of human authoring and review, not automatic build times. The retained builds took 24.5 / 67.2 / 17.8 seconds for A+ / copied detail / reused parts, excluding shared trim generation and captures. The hour estimates exclude damage, wrecks, rotating weapons, fleet rollout and later owner design changes. A mid-size hull was not built in this job.

Validation: three export/reimport round trips, Godot triangle counts, final proportion checks, 36 captures, shared trim and source hashes, mounted root anchors, forward gun directions and unchanged live ship/maps passed. The contact check covers the raycast roots, not every child fitting. All 24 standing checks passed against the recorded baseline. CI's Node 22 parity passed three 10,000-draw PRNG checks, all 316,090 math values, all 50 seeded battles, three threat maps, worker threads and the hard stop. The initial Node 24 math mismatch was resolved by using the CI Node version. [Check summary](checks.json), [parity transcript](parity.txt), [build records](builds.json), [source hashes](sources.json) and [artifact verification](verification.json) are retained.

The in-game shots run this checkout's actual battle scene, HUD, board, ShipView and G4 lighting in a TEMP copy. A review capital is inserted in memory; nearby ships are moved out of the crop. This proves visual integration, not a played combat encounter. No player save is used. Full-battle timing, 4K, damage and production integration are outside this bake-off.

Rebuild by double-clicking [RUN_SURFACE_ROUND2.bat](../../../../tools/blender/surface_bakeoff/RUN_SURFACE_ROUND2.bat). [Tool notes](../../../../tools/blender/surface_bakeoff/ROUND2.md) describe the isolated runner and limits. Everything linked as an image is also saved in the issue-111 shots folder for Opus. No commit or push was made.
