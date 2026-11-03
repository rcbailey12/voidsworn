# Ship surface bake-off: decision and effort

My pick is **route A for mechanical hulls, route B as a base for organic sculpting**. The Pyre-Barge rebuild has straight armour, defined mounts and predictable seams. It is also visibly sparse and changes the donor-hull proportions. More authored detail is necessary. Route B removes the projected paint and costs much less to draw, but it rounds the armour and merges small fittings. It does not solve the remaining mechanical shape work. The Maw now has olive flesh, ochre chitin, wet highlights and veins, with zero metal. Its mouths, tendrils and crest still need sculpting.

Open the matching battle/close sheets: [Pyre-Barge](comparison_C19_51.webp), [Eclipse zenith](comparison_D21_23.webp), [Ninefold Maw](comparison_B16_23.webp). Each includes the same central detail crop. [Shape sweep and verdicts](SWEEP.md) cover bow, middle and stern from top, side and below. These are route prototypes, not shipping replacements.

| Hull | Route B: clean mesh and PBR | Route A: authored rebuild |
|---|---|---|
| Pyre-Barge | 6 to 10 hours: rebuild fittings and hard edges | 12 to 20 hours: match masses, add dense kit and trim detail |
| Eclipse zenith | 3 to 6 hours: clean tower and emitter housings | 8 to 14 hours, estimated; A was not built |
| Ninefold Maw | 8 to 16 hours: sculpt mouths, crest and tendrils | Mechanical kit is unsuitable; a full organic sculpt is 16 to 24 hours, estimated |

These are estimates of focused authoring and review after the shared tools exist, excluding damage, rotating turrets and owner revisions. Actual automated prototype builds took 32.3 / 27.8 / 23.6 seconds for B and 3.6 seconds for A, including maps and export checks. Those times are not the labour needed to finish a hull.

| Hull / route | Triangles | GPU ms, 1 ship | GPU ms, 20 ships | Frame ms, 20 ships / p99 |
|---|---:|---:|---:|---:|
| Pyre today | 256,468 | 0.564 | 2.684 | 2.766 / 3.290 |
| Pyre B | 20,888 | 0.477 | 0.759 | 0.828 / 1.184 |
| Pyre A | 14,920 | 0.431 | 0.634 | 0.697 / 0.996 |
| Zenith today | 132,080 | 0.518 | 1.744 | 1.826 / 2.336 |
| Zenith B | 17,978 | 0.466 | 0.749 | 0.814 / 1.113 |
| Maw today | 165,616 | 0.562 | 2.429 | 2.515 / 3.075 |
| Maw B | 15,270 | 0.443 | 0.734 | 0.800 / 1.083 |

RTX 5080, Godot 4.7.2 Forward+, 1920x1080, G4 max lighting, AgX, MSAA 4x, no vsync. Each short sample has 100 warm-up and 360 measured frames. Twenty shared copies use a non-overlapping 5 by 4 layout. Figures include the scene; empty-scene GPU cost is 0.390 ms. They measure the complete asset routes, including their different surface/draw counts, without battle rules, effects, terrain or damage. Both use mipmaps and compressed maps. These are not full-battle frame times or a sustained 1% low.

Four export round trips, 35 captures, seven variants, forward-gun/contact checks and unchanged live ship hashes passed. All 23 standing checks passed against their recorded baseline. [Raw measurements](measurements.json), [build checks](builds.json), [source hashes](sources.json), [verification](verification.json), [standing-check summary](checks.json), and [double-click runner](../../../../tools/blender/surface_bakeoff/RUN_SURFACE_BAKEOFF.bat) are retained. Full battles, damage, 4K performance and fleet rollout were outside this prototype.
