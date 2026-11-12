# Build sheets, issue 532: corsair_A16 and corsair_A17, round 2 (Opus worker, Nov 11 2026)

Round 1 failed Ryan's review (R213): "The guns look randomly placed ... it looks flatter than the concept ... the builds look
like square blocks basically." Ryan, 19:40 CST: "The concept should inform and guide but it's not a final play by play guide."
Round 2 designs each ship as a warship from the picture's identity (R207) and keeps one model for every view.

| Ship | Length (game / model) | Hull beam | Depth: slab / to top tier | L:B | L:H (to top tier) | Outline at the beauty camera |
|---|---|---:|---|---:|---:|---:|
| corsair_A16 | 26.0 / 25.94 | 8.7 | 4.9 / 6.5 (bridge 7.1) | 3.0 | 4.0 | 84.3 percent |
| corsair_A17 | 14.5 / 14.50 | 5.15 | 3.35 / 5.0 | 2.8 | 2.9 | 83.7 percent |

## What changed from round 1

1. **Massing from true readings, not one camera.** The round 8 sheets' side and top views (measured at their own scale) give
   the profile and plan; the TRELLIS shape reference checked A16's massing (it over-reads beam, 11 units, the old "egg").
   Each hull now has tiers and slopes: A16 chin, slab, tier 2, castle, bridge, stern deck, pods; A17 head and brow, pinched
   neck, hump and crest, engine cluster.
2. **Detail.** Hull and tier faces carry armour slabs of mixed size and thickness, a third stacked on a second slab (kit.py
   `_plates`), belt strakes, sponsons, pylons, scoop cowls, claw blades with joints, attitude thrusters. Still a blockout.
3. **Guns by slot**, mirrored batteries, one mount family per tier, turrets on the spine; details in each ship README.
4. **INSIDE:** decks, frames, numbered spaces along the whole length (R215: interiors throughout, hidden until a piece
   breaks); break lines drawn as uneven seam paths (R186; Hullbreakers part at the chained patch seams): A16 three, A17 two;
   breach anchors 7 and 5 (PR 530 contract). The R99 two-plus-one note was retracted by Ryan (R215) before delivery.
5. **manifest.json** per ship (R214): every part with its route (fittings `kit`, hull masses `hand-built`) and the break
   pieces, each with a full interior.

## The standard's fail list (both ships)

1. Views: true side, top, underside, bow-on, engine end are orthographic renders; the beauty is the identity view, first on
   the sheet beside the blockout at the fitted camera. PASS.
2. No view re-projected from the three-quarter. PASS.
3. Length side vs top 0.00 percent (both); model vs game 0.23 and 0.01 percent; beam top vs bow-on 0.24 and 0.00; height 0.
   PASS.
4. One model writes every view and the table. PASS.
5. No gun aft (kit.py refuses past 100 degrees); broadside guns rest 15 to 55 degrees off the bow; far-side guns grey. PASS.
6. Belly items noted on the top view, drawn on the underside; engine end has its own view. PASS.
7. Length, 5-unit bars, feature table on the sheet and in full. PASS.
8. No sea-ship tells (flat chined bellies, no keel or masts). PASS as I read it.

Outline gate: 84.3 and 83.7 percent, under the recipe's 90. The misses are the designed corrections (chains, claws, guns
retrained, the matched layouts the picture lacks). The gate measures overlap with one picture, not design.

## Honest read of beauty against blockout

Both are plainly the same ships side by side: the silhouette, the tiers, the scoops, dishes, rack, claws and jaws, the big
engines, the colour zones. Neither has the picture's density of small plates, rivets, grime and lights; that is the kit and
paint stages (recipe 4 and 5), not something a blockout sheet can carry. If Ryan wants more detail before the build, the
next step is the faction kit parts on these sockets, not more boxes.

## PC: the C: drive is FULL (needs Ryan)

The round 2 renders on the PC stopped half way: PNGs and the A17 model json were truncated at 64 KB boundaries, and
device_commit_files now refuses with "device disk full". Nothing was deleted. The round 2 sheets were rendered in the cloud
sandbox instead (Blender 5.3 bpy, Cycles CPU, 12 samples with denoise); the PC .blend files under
`C:\Users\rcbai\Downloads\voidsworn_test\opus532\<ship>\` are still round 1. Once space is freed,
`tools\blender\build_sheets\render_sheets.bat corsair_A16 corsair_A17` rebuilds both round 2 blockouts and .blend files in
about a minute each. Two more PC traps: (1) re-committing the same container path can deliver a stale copy: commit from a
fresh path and checksum the PC copy; (2) staging can return a truncated file without an error: open every staged image.
