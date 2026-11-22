# hegemony_H7 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/hegemony/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/hegemony_H7_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| dart | the whole ship: one solid dart that carries the casemate, the barbette, the crew decks and the drives (designs.md: the only escort with no rails) | hull | a single solid body: a blunt bow face, straight flanks out to the widest point at 58 percent, closing to a flat stern transom; a flat deck, chamfered deck edges, upper facets, the flank band, short lower facets, a flat belly | 1 | bow/top, mid/top, stern/top, bow/side, mid/side, stern/side | facets and chamfers round a vertical band (never a flat wall, R244), the stern chamfer in the top line | picture |
| bow_face | the blunt armoured bow round the casemate (R183 (1)): it meets fire head on | hull | the blunt bow face, chamfered corners, armour plates round the casemate mouth | 1 | bow/top, bow/side | the dart's facets running to an upright face, plates round the mouth | picture |
| belly_step | belly armour: Ryan's flat worked belly in place of the concept's V keel | hull | a flat belly with a second armour layer, stepped at its edges | 1 | mid/side | a flat plate, a step round it, panels and hatches on it | designed |
| module_bands | the bulkhead rings between hull modules: the hull gives way here (factions.md "How it breaks"); the breach anchors sit on them | band | two raised trim rings with a deep seam, at 35 and 70 percent | 1 | bow/top, mid/top, stern/top, bow/side, mid/side, stern/side | two trim rings and a dark seam ring between them | picture |
| blue_line | the implant-blue running lights (factions.md: a line of blue light) | band | a blue strip along each flank band, broken at the module bands | 1 | bow/side, mid/side, stern/side | a raised strip that glows | picture |
| deck_panels | deck armour: flush panels in the even grid of two module sizes (paint direction hegemony.md) | plate | flush deck panels | 1 | bow/top, mid/top, stern/top | machined slabs with seams round them, the small-module cells | picture |
| flank_panels | side armour on the facets | plate | flush panels on the upper and lower facets | 1 | bow/side, mid/side, stern/side | machined slabs with seams, two module sizes | picture |
| belly_panels | belly armour | plate | flush panels on the flat belly and its armour step | 1 | mid/side | machined slabs with seams | designed |
| casemate | the Plasma cannon (laser F, 2 shots): the Picket's forward gun | gun | a low casemate inside the bow face, two short thick barrels side by side, recessed so they barely protrude (never the ion trench) | 1 | bow/top, bow/side | a lined recess, a trim frame, a mantlet, breeches, barrels with coil rings, vented muzzle shrouds, blue-lit bores | picture |
| barbette | the Picket lasers (flak T, 3 shots): point defence all round | gun | one low faceted dorsal barbette, three short emitters | 1 | mid/top | a faceted plinth, a flush ring, an eight-sided housing, a sensor eye, three emitters with coil collars and lens tips | picture |
| sensor_fin | the ship's sensors: the one low sensor fin (factions.md) | antenna | a low swept fin on the centreline, forward of the barbette | 1 | bow/top, bow/side | a root plinth, the fin, sensor windows, a lens strip, a trim band | picture |
| engines | the main drives: two rectangular blue-white nozzles in one flat row (designs.md) | engine | two nozzle pods in the stern block | 2 | stern/top, stern/side | a thick lip, inner walls tapering to a blue-white throat, guide vanes, a sleeve with trim bands (R244: an opening with depth) | picture |
| thrusters | retro thrusters on the bow face (lore 3.4: backing off is cheap; ability evasive) and attitude thrusters on the facets | thruster | rectangular nozzle blocks | 6 | bow/side, stern/side | a block, rectangular nozzles with depth | picture |
| drone_doors | the faction's small drone bays (designs.md: flush flank doors only; no hangar in the rules, so no craft fly) | bay | flush armoured doors on each flank band aft | 2 | stern/side | a trim frame, two door leaves with ribs, the centre seam, blue guide lamps | picture |
| latches | lock the hull modules together across each module band | latch | rows of clamp heads beside the bands | 8 | bow/top, mid/top, stern/top | a base plate, machined clamps | designed |
| vents | heat louvres over the cannon's capacitors, the reactor and the engine room | vent | long louvres on the deck and the belly | 8 | bow/top, mid/top, stern/top, mid/side | a machined frame, straight slats over a dark recess | picture |
| windows | blue-white windows of the crew deck (lore 3.3) | slit | window slits on the flank band aft | 4 | stern/side | a trim frame round a recessed pane | picture |
| hatches | crew and stores access: deck, belly and flank hatches | hatch | flush rectangular armoured hatches | 6 | bow/top, mid/top, stern/top, mid/side | a trim rim, a flush door, a seam, a recessed grip | picture |

Kit sub-parts per type (what DETAILED checks):

- antenna: root, fin, window, lens
- band: band, seam, strip
- bay: frame, door, seam
- engine: housing, lip, lining, throat, vane, band
- gun: ring, housing, mantlet, barrel, coil, muzzle, bore
- hatch: rim, door, seam, grip
- hull: facet, step, chamfer
- latch: base, clamp
- plate: panel, seam, module
- slit: frame, glass
- thruster: block, nozzle
- vent: frame, slat

Left as surface, and why:

- The flank band carries only the blue line, the windows, the drone doors and the breach anchors.
- The concept's scattered surface greebles are not built one for one: the even Navy panel grid and the fittings with a job stand in for them (R221).
- Stencil marks are paint, not modelled (the Hegemony stack).

## Every built part has a job (R221)

Built kit parts: 49; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, hegemony_H7_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| dart | a single solid body: a blunt bow face, straight flanks out to the wide | 1 / 1 | Y | Y | Y |
| bow_face | the blunt bow face, chamfered corners, armour plates round the casemat | 1 / 1 | Y | Y | Y |
| module_bands | two raised trim rings with a deep seam, at 35 and 70 percent | 1 / 1 | Y | Y | Y |
| deck_panels | flush deck panels | 1 / 1 | Y | Y | Y |
| casemate | a low casemate inside the bow face, two short thick barrels side by si | 1 / 1 | Y | Y | Y |
| sensor_fin | a low swept fin on the centreline, forward of the barbette | 1 / 1 | Y | Y | Y |
| latches | rows of clamp heads beside the bands | 8 / 8 | Y | Y | Y |
| vents | long louvres on the deck and the belly | 8 / 8 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 6 / 6 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| dart | a single solid body: a blunt bow face, straight flanks out to the wide | 1 / 1 | Y | Y | Y |
| bow_face | the blunt bow face, chamfered corners, armour plates round the casemat | 1 / 1 | Y | Y | Y |
| module_bands | two raised trim rings with a deep seam, at 35 and 70 percent | 1 / 1 | Y | Y | Y |
| blue_line | a blue strip along each flank band, broken at the module bands | 1 / 1 | Y | Y | Y |
| flank_panels | flush panels on the upper and lower facets | 1 / 1 | Y | Y | Y |
| casemate | a low casemate inside the bow face, two short thick barrels side by si | 1 / 1 | Y | Y | Y |
| sensor_fin | a low swept fin on the centreline, forward of the barbette | 1 / 1 | Y | Y | Y |
| thrusters | rectangular nozzle blocks | 6 / 6 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| - | nothing listed in this cell | | | | |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| dart | a single solid body: a blunt bow face, straight flanks out to the wide | 1 / 1 | Y | Y | Y |
| module_bands | two raised trim rings with a deep seam, at 35 and 70 percent | 1 / 1 | Y | Y | Y |
| deck_panels | flush deck panels | 1 / 1 | Y | Y | Y |
| barbette | one low faceted dorsal barbette, three short emitters | 2 / 1 | Y | Y | Y |
| latches | rows of clamp heads beside the bands | 8 / 8 | Y | Y | Y |
| vents | long louvres on the deck and the belly | 8 / 8 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 6 / 6 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| dart | a single solid body: a blunt bow face, straight flanks out to the wide | 1 / 1 | Y | Y | Y |
| belly_step | a flat belly with a second armour layer, stepped at its edges | 1 / 1 | Y | Y | Y |
| module_bands | two raised trim rings with a deep seam, at 35 and 70 percent | 1 / 1 | Y | Y | Y |
| blue_line | a blue strip along each flank band, broken at the module bands | 1 / 1 | Y | Y | Y |
| flank_panels | flush panels on the upper and lower facets | 1 / 1 | Y | Y | Y |
| belly_panels | flush panels on the flat belly and its armour step | 2 / 1 | Y | Y | Y |
| vents | long louvres on the deck and the belly | 8 / 8 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 6 / 6 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| - | nothing listed in this cell | | | | |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| dart | a single solid body: a blunt bow face, straight flanks out to the wide | 1 / 1 | Y | Y | Y |
| module_bands | two raised trim rings with a deep seam, at 35 and 70 percent | 1 / 1 | Y | Y | Y |
| deck_panels | flush deck panels | 1 / 1 | Y | Y | Y |
| engines | two nozzle pods in the stern block | 2 / 2 | Y | Y | Y |
| latches | rows of clamp heads beside the bands | 8 / 8 | Y | Y | Y |
| vents | long louvres on the deck and the belly | 8 / 8 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 6 / 6 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| dart | a single solid body: a blunt bow face, straight flanks out to the wide | 1 / 1 | Y | Y | Y |
| module_bands | two raised trim rings with a deep seam, at 35 and 70 percent | 1 / 1 | Y | Y | Y |
| blue_line | a blue strip along each flank band, broken at the module bands | 1 / 1 | Y | Y | Y |
| flank_panels | flush panels on the upper and lower facets | 1 / 1 | Y | Y | Y |
| engines | two nozzle pods in the stern block | 2 / 2 | Y | Y | Y |
| thrusters | rectangular nozzle blocks | 6 / 6 | Y | Y | Y |
| drone_doors | flush armoured doors on each flank band aft | 2 / 2 | Y | Y | Y |
| windows | window slits on the flank band aft | 4 / 4 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| - | nothing listed in this cell | | | | |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (Picket run 3: bow, the blunt face and the casemate; midships, the dart's widest part, the fin and the barbette; stern, the chamfer and the transom with the two nozzle pods seated flush in it (the side view shows them as one block)); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 2 | 3 | Hull: the dart; Bow face round the casemate; Belly armour step |
| bow/side | 2 | 3 | Hull: the dart; Bow face round the casemate; Belly armour step |
| bow/below | no view | 3 | Hull: the dart; Bow face round the casemate; Belly armour step |
| mid/top | 3 | 3 | Hull: the dart; Flak barbette plinth; Belly armour step |
| mid/side | 2 | 3 | Hull: the dart; Flak barbette plinth; Belly armour step |
| mid/below | no view | 2 | Hull: the dart; Belly armour step |
| stern/top | 2 | 2 | Hull: the dart; Belly armour step |
| stern/side | 2 | 2 | Hull: the dart; Belly armour step |
| stern/below | no view | 2 | Hull: the dart; Belly armour step |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 2.77 | 5.18 | 2.81 | 6.59 |
| build | 3.08 | 4.72 | 3.28 | 6.52 |

Lines not present, shaped and detailed without a reason: 0.
