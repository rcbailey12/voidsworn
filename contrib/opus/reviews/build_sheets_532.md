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

# Round 3 (Opus worker, Nov 11 2026, after R217, R218 and R219)

Ryan, 21:24 CST (R217): the A16 front tubes were "just circles", "the guns are visibly blocking the rockets and appear to be
in front of an engine", "the engines look like big tubes, the weapons look so simple"; A17's "front is also just a flat
block". 21:34 CST (R218): carry it through the whole model. R219: turret guns turn to face their target.

## What was built, in order

1. **Parts inventory first** (R218): `tools/blender/build_sheets/ships/corsair_A16_inv.py` (41 lines) and `corsair_A17_inv.py`
   (29 lines), read from the beauty and the round 8 sheet region by region, each line with its kit part type, count, blob-sweep
   cells and the sub-parts that make it read. Pushed before any modelling (commit 5e2a6fb1). `inventory.py` ticks each line per
   cell from the model: present, shaped, detailed. Both ships: every line Y.
2. **Kit part shapes** (R217, R218): `tools/blender/kits/hullbreakers/parts.py`, pure geometry (mathutils only) so the sheet
   and the real build call the same builders: engine bell, gun (turret and casemate), launch tube, rocket rack, dish, claw,
   chain, hatch, framed deck box, louvre vent, lamp, thruster quad, antenna array, pipe run, bay door, slit, armour plate.
   `SUBPARTS` names each type's sub-parts; `detail_ok` is the DETAILED tick.
3. **The fit check** (RULEBOOK 5.15): `tools/blender/build_sheets/clash.py`, inside every render and on its own
   (`build.py <code> <out> fit`): CLASH, MOUNT, ARC (data.js slot arcs from core.js inArc), SWEEP (R219: each turret turned
   through its arc, and turret pairs both turning), EXHAUST, EXIT, on every part of every type.
4. **Turrets turn** (R219): each turret is an empty `<id>_turret` at the ring centre (local +Z = mount normal) with custom
   properties `turret=1`, `slot`, `weapon`, `arc_lo`, `arc_hi`, `arc_deg`, `rest_yaw`, `rest_pitch`; children
   `<id>_turn_<material>` carry the turning pieces in the pivot's frame; the ring stays fixed. Casemates: `turret=0`,
   `gun_fixed=1`. The manifest lists `pivot_object` and the arc per turret.
5. **The two ships redesigned** until the check found nothing, then judged part by part beside the concept
   (`side_by_side.jpg`), which caught two more things the check could not: A16's tubes still hidden behind cheek boxes (the
   prow was shortened so they jut out) and A17's red deck stripes reading as bricks (now thin plates).

## Fit check, before and after

| Ship | Round 2 layout | Round 3 |
|---|---|---|
| corsair_A16 | 38: clash 16, sweep 11, exhaust 10, exit 1 (the rack's cells covered by the bunker turret T1) | 0 |
| corsair_A17 | 43: clash 20, mount 2, arc 6, sweep 7, exhaust 8 (bells inside each other, P2 and S2 barrels into the hump) | 0 |

The "before" column is the round 2 layout (`ships/r2/`, kept only for this) built with the round 3 part shapes; each fix is
in the ship's `fit_report.md`. The PC run (Blender 4.5) and the sandbox (bpy 5.3) give the same counts.

## Honest read beside the concept

Both now read as built objects with parts that are what they are, and the bows carry the concept's shaping. What still
differs is listed in each ship's README: surface density (plates coarser than the concept's, flat colour: paint stage and a
kit setting), A16's engine fin ring and tube-bundle rack, A17's mandible jaws drawn as segmented claws, fewer boxes on the
castle and hump. None is a fit fault.

## Notes for the Board

- Cameras refit to the round 3 blockouts against a concept mask (outline 80.5 and 75.5 percent; reported, not a bar).
- The round 3 renders: `C:\Users\rcbai\Downloads\voidsworn_test\opus532\r3d\` (r3, r3b, r3c are earlier passes of this round,
  kept, nothing deleted).
- R219's arc test samples the barrels at their rest elevation for the sweep; the fire-line test covers elevations.

# Round 3b (Opus worker, Nov 11 to 12 2026): massing first

The Board on round 3: the parts, fit check and turret marking were right, but the hull massing did not match the concept, the
first thing Ryan sees (his round 1 and 2 words: "flatter than the concept... the builds look like square blocks"; "the front is
also just a flat block"). The inventory ticks had passed because they counted listed parts, not structure (RULEBOOK 5.7).

## Measured, then built to the numbers

`tools/blender/build_sheets/inventory.py` now measures length to beam and length to height the same way on the concept sheet's
true top and side views and on the blockout's top and side renders (whole outline, and hull: length over the median beam or
height across the middle 60 percent of the length), and counts distinct masses per blob-sweep cell, concept (by eye, written in
the ship's `_inv.py` as STRUCTURE) against build (the model's registered masses). Both go in each ship's inventory.md and
cells.json.

| Ship | Concept hull L:B / L:H | Round 3 build | Round 3b build |
|---|---|---|---|
| corsair_A16 | 3.04 / 4.45 | 2.74 / 3.39 | 3.01 / 4.18 |
| corsair_A17 | 2.75 / 4.06 | 2.62 / 2.84 | 2.82 / 3.84 |

- **A17:** rebuilt long and low. A base hull with flank blocks; six top blocks stepping up toward the stern with gaps and
  undercut bases; a big chamfered head with two roof steps over a cut-in mouth, the scoop drums under its corners; four long
  flat prongs with hooked tips (a new kit part, `prong`); squat engine drums in two columns a side. About 30 percent lower.
- **A16:** a slab about 4 deep with tier 2 and the castle as low steps; the bow tapers in plan from the tube cluster; the flank
  in layered belts (upper armour belt, a recessed band of lights, vents and bow casemates, a lower belt); the engine pods
  close in; curved pincers under the bow tip; short grabbers under the stern instead of legs under midships.
- Cameras: view angles held from the round 3 fit (a free refit chose a 47 degree view to make the lower hull fill the
  concept's outline, which would hide exactly what the Board flagged); framing refit to the new blockouts.
- Renders: `opus532\r3e\corsair_A17` and `opus532\r3f\corsair_A16` (Blender 4.5, GPU); zero clashes on both, both pass the
  standard (lengths 26.14 and 14.49).
- Judged beside the concept at the same size: A17 is now the concept's long, low, stepped hunter with forward prongs; A16 the
  long armoured slab with the twin tubes as its face. What still differs (each README): A16's nose more faceted than round,
  A17's head a little smaller than the beauty's, and on both the surface density and colour that the paint stage carries.

# Round 3c (Opus worker, Nov 12 2026): the three things Ryan would notice first

- **A16 cross-section and plan.** The hull is now a rounded wedge in section (a new kit loft option: a superellipse, flatter on
  the deck, round in the flanks and belly, still plated), tapering more toward a broad rounded nose; the armour belts follow
  the hull's curve (new kit `band`: the flank between two heights pushed out along the surface normal) instead of square
  boxes; every flank part is seated on the curve (`surf`, `surf_n`, `deck_z`). Bulkheads inset to stay inside the round hull.
- **A17 head to the beauty.** A big, tall, boxy front block over the neck, big ear dishes standing out at its upper corners
  on brackets, broad flat prongs; the neck turrets and rocket pod lifted to clear it.
- **Rounder shoulder (A16, after r3h).** The r3h three-quarter view still read flat-sided, so the section's deck exponent came
  down (kit `P_TOP` 6.0 to 3.5, flanks and belly 2.3). That pushed four parts into the curve (deck boxes HB1 and HB2 into the
  hull, casemates PM and SM into the upper belt); the boxes moved inboard onto the deck and the casemates now take the
  surface normal (`surf_n`), so the fit check is back to zero. A17 does not use the rounded loft and stays at zero.
- **Every rule kept**: zero clashes on both (PC runs r3g for A17, r3i for A16, Blender 4.5), inventory ticks all Y (failing
  0), ratios and structure counts on both sheets, the side-by-sides redone.

| Ship | Hull L:B concept / build | Hull L:H concept / build | Envelope L:B concept / build | Envelope L:H concept / build |
|---|---|---|---|---|
| A16 | 3.04 / 3.02 | 4.45 / 4.18 | 2.46 / 2.13 | 3.17 / 2.80 |
| A17 | 2.75 / 2.83 | 4.06 / 3.79 | 2.04 / 1.92 | 3.54 / 2.71 |

Structure counts (concept / build, top and side per third): A16 bow 5/7 and 6/7, mid 6/8 and 7/7, stern 7/10 and 7/8; A17 bow
5/9 and 5/7, mid 7/13 and 7/10, stern 5/9 and 6/7. Every cell at or above the concept's count.

**Would Ryan say it looks like the concept?** A17: yes on the head now (the big boxy block with ear dishes is the first thing
you see in both). A16: closer (bow-on it reads round, the plan tapers into the tubes) but not yet the same: the concept's hull
is fuller and more bulbous below the belts, and its surface is many small overlapping plates. Both are the next build's work,
not another blockout round (the Board said stop after 3c).

# Eclipse E11 and E12, first sheets (Opus worker, Nov 12 2026)

Branch opus/issue-532-eclipse, from main with PR 547's tools brought in (`git checkout origin/opus/issue-532 --
tools/blender/build_sheets tools/blender/kits/hullbreakers`). Deliveries: docs/ship_pipeline/build_sheets/deathless_E11/ and
deathless_E12/ (the corsair_A16 file set). Hull ids: E11 = data.js `d_boss` (The Unsetting, Tomb-ark, 28.0; gauss T, gauss T,
doom F, flak T), E12 = `d_harvester` (Eclipse zenith, Cruiser, 14.5; gauss T, gauss T, doom F, gsentry T); lengths from
godot/render/hull_table.gd CLS_LEN, slots also in godot/rules/data/tables.json HULLS.

## Method, in the order the playbook asks

1. **Inventories before modelling** (R218): `ships/deathless_E11_inv.py` (21 lines) and `deathless_E12_inv.py` (16), read
   region by region from the 8c beauty and sheet (both sheets draw the bow on the right, with the escort in every view);
   pushed first (commit 884ae8b8).
2. **The Eclipse kit** (RULEBOOK 4.5, every faction its own kit): `tools/blender/kits/eclipse/parts.py`, no Hullbreaker
   shapes: eclipse engines (faceted ribbed drums, vanes, a short bell, a pale corona ring round a black shade disc, no flame),
   null cannon turrets (two-step hex plinth, faceted housing under two stacked shade plates, slotted mantlet, coiled barrels,
   ringed muzzles; four or more barrels make a clustered shredder), the corona arc projector, the caged core, truss struts, a
   hex core port, octagonal hatches, shade-generator housings, heat slot panels, corona strip lights, slot thrusters,
   machine-cut plates with flush fasteners. Geometry primitives moved to `tools/blender/kits/shared/geom.py` (plumbing only;
   the Hullbreaker kit keeps its own copy, unchanged).
3. **Tools made faction-aware, Hullbreaker behaviour unchanged**: the ship file names its KIT; kit.py loads it; new
   placements (spinal, core, strut, corewin, ring lofts, rim strips); clash.py treats a fixed spinal weapon like a casemate
   (arc tested, not swept); inventory, extras and layout read each ship's concept sheet, view boxes (bow-right, escort left
   out), crops and version label; two opt-in plate settings (`stride`, `keep3d`) so closely spaced lofts and narrow rounded
   faces get plates. A16 and A17 still check at zero with these tools.
4. **Massing first, measured** (ships.md 2c): both concepts measured on their true views, the builds iterated against them
   (E11 four massing passes: taller body, the crescent raised over the nose and made a flatter brim, bigger engines, the stern
   feathers laid closer; E12: the stern block made shorter and rounder).

| Ship | Hull L:B concept / build | Hull L:H concept / build | Envelope L:B concept / build | Envelope L:H concept / build | Outline at the beauty camera |
|---|---|---|---|---|---:|
| E11 | 5.72 / 5.59 | 7.00 / 6.47 | 2.49 / 2.59 | 4.49 / 4.32 | 82.9 percent |
| E12 | 1.94 / 1.89 | 15.57 / 11.21 | 1.77 / 1.72 | 5.94 / 5.98 | 53.9 percent |

Structure counts: every cell at or above the concept's (E11 bow 6/7 and 5/7, mid 8/9 and 8/9, stern 8/17 and 8/12; E12 bow
5/9 and 4/7, mid 5/8 and 4/6, stern 6/7 and 5/5).

5. **The fit check**: first full layouts E11 3 findings, E12 15 (each with its fix in the ship's fit_report.md), then zero on
   both, in the sandbox and on the PC (Blender 4.5). Turrets marked as pivots with arcs (R219).
6. **Renders** on Ryan's PC through the queue (opus532e\e1 to e6; GPU read twice under 15 percent before each; nothing
   deleted). The first PC render showed what the workbench preview hid: colours washed to lilac, corona lines blown to white,
   no plates on the crescent's upper layers. All three fixed before delivery.

## Would Ryan say it looks like the concept?

Judged beside each concept at the same size and camera (side_by_side.jpg):
- **E11: yes.** The crescent brim with green rims round the projector, the long plated body with two big twins and the small
  aft twin, the band collar, the stern cluster all sit where the picture puts them, at the picture's proportions. Still
  different: surface (the concept's plate courses and weathering are the paint stage), the crescent a little narrower and less
  domed, the projector a little lighter, the engines a little smaller.
- **E12: yes on identity, weaker on the picture match.** The broken oval ring of open box arcs with green rims, the caged
  core, the spine with its two twins and the bow emitter, the three-engine block, all at the plan's numbers. The camera fit is
  only 53.9 percent because the beauty draws the ring larger and nearer the block than its own plan and sees the block from
  aft; the plan wins for placement (standard.md). Still different: the block reads plainer from above, the struts run straight
  where the concept's lean, surface and colour depth.

## Notes for the Board

- The branch carries copies of PR 547's tools with my changes; merging 547 first gives add/add conflicts in those files and in
  this review file: take this branch's versions (they are 547's plus the Eclipse changes and behave the same for A16 and A17).
- The changes text and fix column were added after the last PC render (text only) and merged into the model and fit json
  from a sandbox run that gives the same zero (each README says so).
- PC folder: `voidsworn_test\opus532e` (e1 to e6 renders and .blend files, about 120 MB), nothing deleted.

## E12 second sheet (after the Board's review, Nov 12 2026)

The Board passed E11 and sent E12 back on four points; E11 unchanged.
1. **Camera**: refit to the beauty's aft three-quarter angle (azimuth -122, elevation 58), framing only fitted, 45.5 percent
   outline. The beauty is not one consistent camera (bells facing the viewer, an aft view; stern higher in frame than bow, a
   forward view), so at a true aft angle the block is the near end and lands low and large. The side-by-side adds the
   forward camera (53.8 percent) as its last row: judge the stern on the first, the ring on the last. New `build.py ...
   beauty` mode renders a second camera (`SHEET_CAMERA`); sheet_extras shows any `beauty_cam_<name>.png` as an extra row.
2. **Spine** slimmed to a rod, 0.36 by 0.32 (was 0.6 by 0.48), collars and saddles with it.
3. **Stern block** compact and low (1.4 tall, was 1.9), three 0.92 bells filling its aft face, standing out 0.95.
4. **Arcs** unchanged (one matched ellipse); the concept's slightly different radii are noted, not copied.

Fit check zero (PC e8 and sandbox), inventory 0 failing, every cell at or above the concept. Ratios: hull L:B 1.89 (concept
1.94), hull L:H 11.32 (15.57), envelope L:B 1.72 (1.77), envelope L:H 7.02 (5.94: the lower block drops the stern height).
My read: on the aft view the bells, slim spine and open arcs read as the concept, but the near block still fills the lower left
of the frame, where the beauty puts it far and high; that comes from the picture itself, not from the model.
