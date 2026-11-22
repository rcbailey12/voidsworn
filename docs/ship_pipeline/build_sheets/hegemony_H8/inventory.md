# hegemony_H8 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/hegemony/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/hegemony_H8_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| ion_block | the deep forward block: it carries the ion cannon, its capacitors, the command deck and the lance turret (designs.md: the anvil) | hull | slab sides at the full beam, deep; a flat deck, chamfered deck edges, upper facets, a tall flank band in two tiers, lower facets, a flat belly; the bow corners chamfered in plan | 1 | bow/top, bow/side, mid/top, mid/side | facets and chamfers round a vertical band (never a flat wall, R244), the two-tier band | picture |
| bow_face | the blunt armoured bow round the ion trench (R183 (1)) | hull | the blunt bow face, chamfered corners, armour plates and a trim frame round the trench mouth | 1 | bow/top, bow/side | the block's facets running to an upright face, plates round the mouth | picture |
| step | the hard step between the ion block and the aft body: plan and profile step in the same transverse face (designs.md) | hull | the ion block's aft face, the aft body set in 0.65 a side and its deck dropped | 1 | mid/top, mid/side | a flat transverse face, its edges chamfered | picture |
| aft_body | the narrower aft body: crew decks, plant rooms and the drives | hull | one narrower hull, sides parallel to a flat stern transom; the same faceted section, one flank band | 1 | mid/top, mid/side, stern/top, stern/side | facets and chamfers round a vertical band | picture |
| module_bands | the bulkhead rings between hull modules: the hull gives way here (factions.md "How it breaks"); the breach anchors sit on them | band | raised trim rings with a deep seam: one on the ion block, the step itself, one on the aft body | 1 | bow/top, mid/top, stern/top, bow/side, mid/side, stern/side | two trim rings and a dark seam ring between them | picture |
| blue_line | the implant-blue running lights (factions.md) | band | blue strips along the flank bands, two rows on the ion block, one on the aft body | 1 | bow/side, mid/side, stern/side | a raised strip that glows | picture |
| deck_panels | deck armour in the even grid of two module sizes | plate | flush deck panels | 1 | bow/top, mid/top, stern/top | machined slabs with seams, the small-module cells | picture |
| flank_panels | side armour on the facets | plate | flush panels on the upper and lower facets | 1 | bow/side, mid/side, stern/side | machined slabs with seams, two module sizes | picture |
| belly_panels | belly armour | plate | flush panels on the belly and its armour step | 1 | bow/side, mid/side | machined slabs with seams | designed |
| ion_trench | the ion cannon (ion F, 1 shot): strips shields head on; the Cordon's ionpulse | ion_trench | the emitter trench recessed in the blunt bow face, about 1.1 by 0.6, three stepped capacitor rings, a blue lens, an inset lip | 1 | bow/top, bow/side | lined walls, stepped capacitor rings, an emitter block, a blue lens, an inner glow | picture |
| lance | the Plasma lance (turbo T, 2 shots): one low turret on the centreline | gun | one low wide lance turret, two short thick barrels | 1 | mid/top | a flush ring, a faceted housing with a sloped glacis, armoured cheeks, a capacitor bustle, a mantlet, breeches, barrels with coil rings, vented shrouds, blue-lit bores | picture |
| sensor_fin | the ship's sensors: one low sensor fin, aft of the step so it clears the lance's fire (designs.md) | antenna | a low swept fin on the aft body's centreline | 1 | mid/top, mid/side | a root plinth, the fin, sensor windows, a lens strip, a trim band | picture |
| engines | the main drives: two rectangular blue-white nozzles in one flat row (designs.md; the top view's third pod is a slip) | engine | two nozzle pods on the aft transom | 2 | stern/top, stern/side | a thick lip, inner walls tapering to a blue-white throat, guide vanes, a sleeve with trim bands | picture |
| thrusters | retro thrusters on the bow face corners (the concept's four small blocks there) and attitude thrusters on the facets | thruster | rectangular nozzle blocks | 8 | bow/side, stern/side | a block, rectangular nozzles with depth | picture |
| drone_doors | the faction's small drone bays (designs.md: flush flank doors only; no hangar in the rules, so no craft fly) | bay | flush armoured doors on the aft body's upper facets | 2 | stern/side | a trim frame, two door leaves with ribs, the centre seam, blue guide lamps | picture |
| latches | lock the hull modules together across each module band | latch | rows of clamp heads beside the bands | 8 | bow/top, mid/top, stern/top | a base plate, machined clamps | picture |
| vents | heat louvres over the ion capacitors, the reactor and the engine room (the concept's many ladder louvres) | vent | long louvres on the decks | 8 | bow/top, mid/top, stern/top | a machined frame, straight slats over a dark recess | picture |
| windows | blue-white windows of the crew decks (lore 3.3) | slit | window slits on the block's flank band | 12 | bow/side, mid/side, stern/side | a trim frame round a recessed pane | picture |
| hatches | crew and stores access: deck, belly and flank hatches | hatch | flush rectangular armoured hatches | 9 | bow/top, mid/top, stern/top, mid/side | a trim rim, a flush door, a seam, a recessed grip | picture |

Kit sub-parts per type (what DETAILED checks):

- antenna: root, fin, window, lens
- band: band, seam, strip
- bay: frame, door, seam
- engine: housing, lip, lining, throat, vane, band
- gun: ring, housing, mantlet, barrel, coil, muzzle, bore
- hatch: rim, door, seam, grip
- hull: facet, step, chamfer
- ion_trench: liner, coil, emitter, lens
- latch: base, clamp
- plate: panel, seam, module
- slit: frame, glass
- thruster: block, nozzle
- vent: frame, slat

Left as surface, and why:

- The flank bands carry only the blue lines, the windows and the breach anchors.
- The concept's scattered greebles are not built one for one: the even Navy panel grid and the fittings with a job stand in for them (R221).
- Stencil marks are paint, not modelled (the Hegemony stack).

## Every built part has a job (R221)

Built kit parts: 65; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, hegemony_H8_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| ion_block | slab sides at the full beam, deep; a flat deck, chamfered deck edges,  | 1 / 1 | Y | Y | Y |
| bow_face | the blunt bow face, chamfered corners, armour plates and a trim frame  | 1 / 1 | Y | Y | Y |
| module_bands | raised trim rings with a deep seam: one on the ion block, the step its | 1 / 1 | Y | Y | Y |
| deck_panels | flush deck panels | 2 / 1 | Y | Y | Y |
| ion_trench | the emitter trench recessed in the blunt bow face, about 1.1 by 0.6, t | 1 / 1 | Y | Y | Y |
| latches | rows of clamp heads beside the bands | 8 / 8 | Y | Y | Y |
| vents | long louvres on the decks | 8 / 8 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 9 / 9 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| ion_block | slab sides at the full beam, deep; a flat deck, chamfered deck edges,  | 1 / 1 | Y | Y | Y |
| bow_face | the blunt bow face, chamfered corners, armour plates and a trim frame  | 1 / 1 | Y | Y | Y |
| module_bands | raised trim rings with a deep seam: one on the ion block, the step its | 1 / 1 | Y | Y | Y |
| blue_line | blue strips along the flank bands, two rows on the ion block, one on t | 1 / 1 | Y | Y | Y |
| flank_panels | flush panels on the upper and lower facets | 2 / 1 | Y | Y | Y |
| belly_panels | flush panels on the belly and its armour step | 3 / 1 | Y | Y | Y |
| ion_trench | the emitter trench recessed in the blunt bow face, about 1.1 by 0.6, t | 1 / 1 | Y | Y | Y |
| thrusters | rectangular nozzle blocks | 8 / 8 | Y | Y | Y |
| windows | window slits on the block's flank band | 12 / 12 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| - | nothing listed in this cell | | | | |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| ion_block | slab sides at the full beam, deep; a flat deck, chamfered deck edges,  | 1 / 1 | Y | Y | Y |
| step | the ion block's aft face, the aft body set in 0.65 a side and its deck | 1 / 1 | Y | Y | Y |
| aft_body | one narrower hull, sides parallel to a flat stern transom; the same fa | 1 / 1 | Y | Y | Y |
| module_bands | raised trim rings with a deep seam: one on the ion block, the step its | 1 / 1 | Y | Y | Y |
| deck_panels | flush deck panels | 2 / 1 | Y | Y | Y |
| lance | one low wide lance turret, two short thick barrels | 1 / 1 | Y | Y | Y |
| sensor_fin | a low swept fin on the aft body's centreline | 1 / 1 | Y | Y | Y |
| latches | rows of clamp heads beside the bands | 8 / 8 | Y | Y | Y |
| vents | long louvres on the decks | 8 / 8 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 9 / 9 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| ion_block | slab sides at the full beam, deep; a flat deck, chamfered deck edges,  | 1 / 1 | Y | Y | Y |
| step | the ion block's aft face, the aft body set in 0.65 a side and its deck | 1 / 1 | Y | Y | Y |
| aft_body | one narrower hull, sides parallel to a flat stern transom; the same fa | 1 / 1 | Y | Y | Y |
| module_bands | raised trim rings with a deep seam: one on the ion block, the step its | 1 / 1 | Y | Y | Y |
| blue_line | blue strips along the flank bands, two rows on the ion block, one on t | 1 / 1 | Y | Y | Y |
| flank_panels | flush panels on the upper and lower facets | 2 / 1 | Y | Y | Y |
| belly_panels | flush panels on the belly and its armour step | 3 / 1 | Y | Y | Y |
| sensor_fin | a low swept fin on the aft body's centreline | 1 / 1 | Y | Y | Y |
| windows | window slits on the block's flank band | 12 / 12 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 9 / 9 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| - | nothing listed in this cell | | | | |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| aft_body | one narrower hull, sides parallel to a flat stern transom; the same fa | 1 / 1 | Y | Y | Y |
| module_bands | raised trim rings with a deep seam: one on the ion block, the step its | 1 / 1 | Y | Y | Y |
| deck_panels | flush deck panels | 2 / 1 | Y | Y | Y |
| engines | two nozzle pods on the aft transom | 2 / 2 | Y | Y | Y |
| latches | rows of clamp heads beside the bands | 8 / 8 | Y | Y | Y |
| vents | long louvres on the decks | 8 / 8 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 9 / 9 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| aft_body | one narrower hull, sides parallel to a flat stern transom; the same fa | 1 / 1 | Y | Y | Y |
| module_bands | raised trim rings with a deep seam: one on the ion block, the step its | 1 / 1 | Y | Y | Y |
| blue_line | blue strips along the flank bands, two rows on the ion block, one on t | 1 / 1 | Y | Y | Y |
| flank_panels | flush panels on the upper and lower facets | 2 / 1 | Y | Y | Y |
| engines | two nozzle pods on the aft transom | 2 / 2 | Y | Y | Y |
| thrusters | rectangular nozzle blocks | 8 / 8 | Y | Y | Y |
| drone_doors | flush armoured doors on the aft body's upper facets | 2 / 2 | Y | Y | Y |
| windows | window slits on the block's flank band | 12 / 12 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| - | nothing listed in this cell | | | | |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (Cordon run 3: bow, the deep ion block and the trench; midships, the lance turret, the step, the fin on the aft body; stern, the aft body, the transom and the two nozzle pods); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 2 | 3 | Hull: the ion block; Bow face round the ion trench; Belly armour step |
| bow/side | 2 | 3 | Hull: the ion block; Bow face round the ion trench; Belly armour step |
| bow/below | no view | 3 | Hull: the ion block; Bow face round the ion trench; Belly armour step |
| mid/top | 4 | 3 | Hull: the ion block; Hull: the aft body; Belly armour step |
| mid/side | 3 | 3 | Hull: the ion block; Hull: the aft body; Belly armour step |
| mid/below | no view | 3 | Hull: the ion block; Hull: the aft body; Belly armour step |
| stern/top | 2 | 1 | Hull: the aft body |
| stern/side | 3 | 1 | Hull: the aft body |
| stern/below | no view | 1 | Hull: the aft body |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 2.55 | 5.22 | 2.93 | 6.39 |
| build | 2.99 | 4.85 | 4.88 | 7.48 |

Lines not present, shaped and detailed without a reason: 0.
