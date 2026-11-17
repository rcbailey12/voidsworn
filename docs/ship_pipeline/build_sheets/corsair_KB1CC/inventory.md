# corsair_KB1CC parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/hullbreakers/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/corsair_KB1CC_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| body | the craft's main body: the glacis ramp armour over the reactor and the crew, the stern housing over the drives | hull | R294: tapered bow toe, rising glacis, level upper deck, raised stern housing; a flat belly with chines | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | tapered toe and chamfers, rising glacis then level deck, stern housing | picture |
| glacis_plates | the glacis ramp's armour: the Hullbreaker patchwork of big uneven plates (R275) | plate | a patchwork of big plates of mixed size and angle over the ramp and the flanks, lapping one another | 1 | bow/top, bow/side, mid/top, mid/side, stern/top | slabs with bevels, plates at their own heights and angles, patches on some, rivets on a few | picture |
| belly_plates | the belly's armour | plate | patched plates over the flat belly (the concept shows no underside) | 1 | bow/below, mid/below, stern/below | slabs with bevels and steps | designed |
| bomb_tubes | the bomb payload (data.js bombs T, 2 shots): the wing's only weapon, one tube a corner, both firing every volley | bomb_tube | two large forward bomb tubes at the shoulders' front corners, each in a dark armoured collar on an eight-sided drum (R299: broad dark collars and deep red-lined bores are the forward weapons; smaller orange flared drive nacelles sit aft) | 2 | bow/top, bow/side, bow/below | the dark collar with welded bolts, the bore, the bomb nose seated deep inside a dim red liner, the blended corner drum, two riveted bands, a welded patch (R221) | designed |
| rails | the armoured edge frames that stiffen the glacis plate and guard the ramp's edges | rib | a raised rail along each top edge of the body, running diagonally up the ramp from the bow toe to the stern housing, with bolted clamps (the concept's raised glacis edges) | 1 | bow/top, mid/top, stern/top | the rail, its clamp brackets | picture |
| lip | the armoured lip that ends the glacis (against the ramp read) and carries the crew's vision slit | tier | an armoured lip across the top of the glacis ramp, against the stern housing (the round 3 sheet (DeepSeek)) | 1 | stern/top | its sloped face, its roof, the slit opening | picture |
| vision_slit | the crew's view out (no canopy, R254): the bombardier aims the craft | slit | one vision slit in the lip's face, a little to port, looking forward down the ramp | 1 | stern/top | a welded frame round a dark pane | designed |
| shoulders | the side bodies behind the corner pods: each holds a bomb row (the magazine) and its hoist | tier | a shoulder either side, its top sloping down and out to a thin edge; the starboard one a touch lower and shorter (lopsided) | 1 | bow/top, mid/top, mid/side, mid/below, stern/top, stern/side | the sloped top, the thin outer edge, the chamfered belly | picture |
| shoulder_plates | the shoulders' armour | plate | a patchwork of big uneven plates over the shoulders | 1 | mid/top, mid/side, stern/top | slabs with bevels, plates at their own heights and angles, patches on some | picture |
| hoist_bays | the bomb hoists: they walk the next bomb from the magazine row into its tube, behind armoured doors | machbay | R294: one real sunken machinery well cut through each shoulder, with three coupled pipes, hoist and hinged partial cover (the concept's recessed side bays with armoured doors) | 2 | mid/top, mid/side | a heavy frame, a dark back, pipes, the hoist block, the door on hinges (two-tone so it survives 32 px, Qwen) | picture |
| nacelles | the two main drives, separate from the small stern thrusters and forward bomb tubes | engine | two round aft-facing nacelles, reduced and lowered in R299, one a little larger, with armoured drums welded into the shoulders (R294: aft-facing drive mouths; the front paint_full view shows their housings, rear proof shows the throats) | 2 | mid/top, stern/top, stern/side, stern/below | round bell and dark lip, deep red-orange lining and throat, hot plug, cooling ring, armoured drum, bands and gimbal struts | picture |
| drives | drive (sp 5): the stern thruster bank, nozzle clusters inside an armoured block (the owner's rule for craft) | engine | five mismatched salvaged bells, the centre one the largest | 5 | stern/top, stern/side, stern/below | a bell with a lip, an ember lining, a glowing throat and plug, a cooling ring, a drum with a collar and a band, gimbal struts | picture |
| bank_recess | the armoured recess round the thruster bank | pylon | a hood over the bank, cheeks at its sides, a sill under it (the concept's recessed stern bank) | 1 | stern/top, stern/side | the welded web plates and their faces | picture |

Kit sub-parts per type (what DETAILED checks):

- bomb_tube: (hull shaping, checked by eye on the side-by-side)
- engine: housing, collar, band, bell, lining, throat_glow, cone, cool, strut
- hull: bevel, step, overhang
- machbay: (hull shaping, checked by eye on the side-by-side)
- plate: slab, step, bevel, rivet
- pylon: web, plate
- rib: rib
- slit: frame, glass
- tier: face, roof, opening

Left as surface, and why:

- The plate colours (rust, soot, dried blood, the trophy greys and violets), wear and the red running lights: the Hullbreaker paint stack (applied later); the sheet models the plates.
- Dishes, claws, antennas and lamps: nothing hangs off (factions.md), and below what the battle camera shows on a 3.84 unit craft; not built.

## Every built part has a job (R221)

Built kit parts: 21; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, corsair_KB1CC_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | R294: tapered bow toe, rising glacis, level upper deck, raised stern h | 1 / 1 | Y | Y | Y |
| glacis_plates | a patchwork of big plates of mixed size and angle over the ramp and th | 1 / 1 | Y | Y | Y |
| bomb_tubes | two large forward bomb tubes at the shoulders' front corners, each in  | 2 / 2 | Y | Y | Y |
| rails | a raised rail along each top edge of the body, running diagonally up t | 1 / 1 | Y | Y | Y |
| shoulders | a shoulder either side, its top sloping down and out to a thin edge; t | 1 / 1 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | R294: tapered bow toe, rising glacis, level upper deck, raised stern h | 1 / 1 | Y | Y | Y |
| glacis_plates | a patchwork of big plates of mixed size and angle over the ramp and th | 1 / 1 | Y | Y | Y |
| bomb_tubes | two large forward bomb tubes at the shoulders' front corners, each in  | 2 / 2 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | R294: tapered bow toe, rising glacis, level upper deck, raised stern h | 1 / 1 | Y | Y | Y |
| belly_plates | patched plates over the flat belly | 1 / 1 | Y | Y | Y |
| bomb_tubes | two large forward bomb tubes at the shoulders' front corners, each in  | 2 / 2 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | R294: tapered bow toe, rising glacis, level upper deck, raised stern h | 1 / 1 | Y | Y | Y |
| glacis_plates | a patchwork of big plates of mixed size and angle over the ramp and th | 1 / 1 | Y | Y | Y |
| rails | a raised rail along each top edge of the body, running diagonally up t | 1 / 1 | Y | Y | Y |
| shoulders | a shoulder either side, its top sloping down and out to a thin edge; t | 1 / 1 | Y | Y | Y |
| shoulder_plates | a patchwork of big uneven plates over the shoulders | 2 / 1 | Y | Y | Y |
| hoist_bays | R294: one real sunken machinery well cut through each shoulder, with t | 2 / 2 | Y | Y | Y |
| nacelles | two round aft-facing nacelles, reduced and lowered in R299, one a litt | 2 / 2 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | R294: tapered bow toe, rising glacis, level upper deck, raised stern h | 1 / 1 | Y | Y | Y |
| glacis_plates | a patchwork of big plates of mixed size and angle over the ramp and th | 1 / 1 | Y | Y | Y |
| shoulders | a shoulder either side, its top sloping down and out to a thin edge; t | 1 / 1 | Y | Y | Y |
| shoulder_plates | a patchwork of big uneven plates over the shoulders | 2 / 1 | Y | Y | Y |
| hoist_bays | R294: one real sunken machinery well cut through each shoulder, with t | 2 / 2 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | R294: tapered bow toe, rising glacis, level upper deck, raised stern h | 1 / 1 | Y | Y | Y |
| belly_plates | patched plates over the flat belly | 1 / 1 | Y | Y | Y |
| shoulders | a shoulder either side, its top sloping down and out to a thin edge; t | 1 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | R294: tapered bow toe, rising glacis, level upper deck, raised stern h | 1 / 1 | Y | Y | Y |
| glacis_plates | a patchwork of big plates of mixed size and angle over the ramp and th | 1 / 1 | Y | Y | Y |
| rails | a raised rail along each top edge of the body, running diagonally up t | 1 / 1 | Y | Y | Y |
| lip | an armoured lip across the top of the glacis ramp, against the stern h | 1 / 1 | Y | Y | Y |
| vision_slit | one vision slit in the lip's face, a little to port, looking forward d | 1 / 1 | Y | Y | Y |
| shoulders | a shoulder either side, its top sloping down and out to a thin edge; t | 1 / 1 | Y | Y | Y |
| shoulder_plates | a patchwork of big uneven plates over the shoulders | 2 / 1 | Y | Y | Y |
| nacelles | two round aft-facing nacelles, reduced and lowered in R299, one a litt | 2 / 2 | Y | Y | Y |
| drives | five mismatched salvaged bells, the centre one the largest | 5 / 5 | Y | Y | Y |
| bank_recess | a hood over the bank, cheeks at its sides, a sill under it | 1 / 1 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | R294: tapered bow toe, rising glacis, level upper deck, raised stern h | 1 / 1 | Y | Y | Y |
| shoulders | a shoulder either side, its top sloping down and out to a thin edge; t | 1 / 1 | Y | Y | Y |
| nacelles | two round aft-facing nacelles, reduced and lowered in R299, one a litt | 2 / 2 | Y | Y | Y |
| drives | five mismatched salvaged bells, the centre one the largest | 5 / 5 | Y | Y | Y |
| bank_recess | a hood over the bank, cheeks at its sides, a sill under it | 1 / 1 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | R294: tapered bow toe, rising glacis, level upper deck, raised stern h | 1 / 1 | Y | Y | Y |
| belly_plates | patched plates over the flat belly | 1 / 1 | Y | Y | Y |
| nacelles | two round aft-facing nacelles, reduced and lowered in R299, one a litt | 2 / 2 | Y | Y | Y |
| drives | five mismatched salvaged bells, the centre one the largest | 5 / 5 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (KB1C-C render, by eye (no true views): bow, the glacis, its two rails and the two corner mouths; midships, the ramp, the rails, the side bays and the shoulders; stern, the top of the ramp, the raised housing and the thruster row); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 4 | 3 | Hull: the central body (the glacis ramp and the stern housing); Shoulder, port; Shoulder, starboard |
| bow/side | 3 | 2 | Hull: the central body (the glacis ramp and the stern housing); Shoulder, port |
| bow/below | no view | 3 | Hull: the central body (the glacis ramp and the stern housing); Shoulder, port; Shoulder, starboard |
| mid/top | 4 | 3 | Hull: the central body (the glacis ramp and the stern housing); Shoulder, port; Shoulder, starboard |
| mid/side | 3 | 2 | Hull: the central body (the glacis ramp and the stern housing); Shoulder, port |
| mid/below | no view | 3 | Hull: the central body (the glacis ramp and the stern housing); Shoulder, port; Shoulder, starboard |
| stern/top | 3 | 4 | Hull: the central body (the glacis ramp and the stern housing); Shoulder, port; Shoulder, starboard; The armoured lip |
| stern/side | 3 | 3 | Hull: the central body (the glacis ramp and the stern housing); Shoulder, port; The armoured lip |
| stern/below | no view | 4 | Hull: the central body (the glacis ramp and the stern housing); Shoulder, port; Shoulder, starboard; The armoured lip |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 2.10 | 2.10 | 2.54 | 2.54 |
| build | 0.83 | 4.04 | 0.83 | 4.68 |

Lines not present, shaped and detailed without a reason: 0.
