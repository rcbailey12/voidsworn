# hegemony_IM5 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/hegemony/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/hegemony_IM5_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| hull | the one broad wedge hull: two raised armoured ridges carrying the crew decks and the shoulder lances, the canyon between them carrying the plant, the lower hull the reactor and the racks (R255: IM5, one vessel) | hull | the broad wedge with the canyon cut down its spine: ridge decks, chamfered deck edges, upper facets, the flank band, lower facets, a chine, a flat belly; the canyon's floor, stepped walls and lips; the shoulder pits | 1 | bow/top, mid/top, stern/top, bow/side, mid/side, stern/side, bow/below, mid/below, stern/below | facets and chamfers round a vertical band (never a flat wall, R244), the canyon walls stepped by a ledge, the pit steps | picture |
| bow_face | the blunt armoured bow round the ion trench at the canyon's mouth: it meets fire head on (R183 (1)) | hull | the blunt bow face, the ridge ends and the bow deck running to it, armour plates and a trim frame round the trench mouth | 1 | bow/top, bow/side, bow/below | the facets running to an upright face, the ridge ends standing over the bow deck, plates round the mouth | picture |
| bridges | the three bridge decks tie the ridges across the canyon, carry the crew between them and seat the bridge turrets | tier | three low bridge decks flush with the ridge decks (bow, midships, stern), chamfered undersides, girders, a trim band and a blue strip on each face | 1 | bow/top, mid/top, stern/top | a face with trim and a blue strip, a panelled roof flush with the decks, the canyon opening under it | picture |
| module_bands | the joints between hull modules: the hull gives way here (factions.md "How it breaks"); the breach anchors sit on them | band | six raised trim rings round the whole section, canyon included, with a deep double seam between their halves | 1 | bow/top, mid/top, stern/top, bow/side, mid/side, stern/side | two trim rings and a dark seam ring between them | picture |
| blue_line | the implant-blue light strips: the fleet's running lights, pulsing in time (factions.md: a line of blue light) | band | a blue strip along each flank band, broken at the module bands, and one on each face of each bridge | 1 | bow/side, mid/side, stern/side, bow/top, mid/top, stern/top | a raised strip that glows | picture |
| deck_panels | deck armour: flush panels in the even grid of two module sizes (paint direction hegemony.md) | plate | flush panels on the ridge decks, the pit floors, the bow and stern decks and the bridge roofs | 1 | bow/top, mid/top, stern/top | machined slabs with seams round them, the small-module cells | picture |
| canyon_panels | the canyon's armour: the floor and the stepped walls that shield the plant | plate | flush panels on the canyon floor, its walls and ledges | 1 | bow/top, mid/top, stern/top | machined slabs with seams, two module sizes | picture |
| flank_panels | side armour on the facets | plate | flush panels on the upper and lower facets | 1 | bow/side, mid/side, stern/side | machined slabs with seams, two module sizes | picture |
| belly_panels | belly armour | plate | flush panels on the belly and the belly armour step | 1 | bow/below, mid/below, stern/below | machined slabs with seams | designed |
| lances | the heavy plasma lances (hturbo P and hturbo S, 3 shots each): the main broadside fire, one turret a side | gun | two low wide lance turrets sunk in the shoulder pits, two short thick barrels each | 2 | mid/top, mid/side | a flush ring, a faceted housing with a sloped glacis, armoured cheeks, a capacitor bustle, a mantlet, breeches, barrels with coil rings, vented muzzle shrouds, blue-lit bores (R221) | picture |
| bridge_lance | the plasma lance (turbo T, 2 shots): all-round fire from the midships bridge | gun | the lance turret at a smaller size on the midships bridge, two barrels | 1 | mid/top | a flush ring, a faceted housing, a glacis, cheeks, a bustle, a mantlet, barrels with coil rings, shrouds, blue bores | picture |
| pickets | the picket lasers (flak T, 3 shots): point defence against craft over the stern | gun | one twin picket turret on the stern bridge | 1 | stern/top | a flush ring, an eight-sided housing, a sensor eye, two short emitters with coil collars and lens tips (R221) | picture |
| ion_trench | the ion cannon (ion F, 1 shot): strips shields head on (lore 3.4) | ion_trench | the emitter trench recessed in the blunt bow face at the canyon's mouth (R183 (1)) | 1 | bow/top, bow/side | lined walls, stacked field coil plates, an emitter block, a blue lens, feed conduits | picture |
| sensor_fin | the ship's sensors: the one low sensor fin (factions.md), on the bow deck | antenna | a low swept fin on the centreline of the bow deck | 1 | bow/top, bow/side | a root plinth, the fin, sensor windows, a lens strip, a trim band | picture |
| engines | the main drives: a flat row of six rectangular blue-white nozzles (factions.md) | engine | six nozzle pods in one row across the stern | 6 | stern/top, stern/side | a thick lip, inner walls tapering to a blue-white throat, guide vanes, a sleeve with trim bands and panels (R244: an opening with depth) | picture |
| thrusters | retro thrusters on the bow face (lore 3.4: backing off is cheap) and attitude thrusters on the facets | thruster | rectangular nozzle blocks | 6 | bow/side, stern/side | a block, rectangular nozzles with depth | designed |
| capbanks | the ion cannon's charge banks on the canyon floor, forward | capbank | two capacitor banks of identical cells | 2 | bow/top, mid/top | a plinth, identical cells, trim caps, blue charge strips, bus bars, terminals | picture |
| exchangers | the reactor's and the drives' heat exchangers: their heat leaves the hull in the open canyon | exchanger | four heat exchangers on the canyon floor | 4 | mid/top, stern/top | a plinth, a housing, a stack of cooling fins in a frame, inlet and outlet ports | picture |
| trunks | armoured power trunks: the reactor's power forward to the ion cannon and aft to the drives | pipe | two trunks along the canyon floor, one length per module, coupled at the bands | 10 | bow/top, mid/top, stern/top | an eight-sided trunk, trim collars, end flanges, saddles | picture |
| coolant_lines | coolant lines: the exchangers' loops out to the ridges' plant rooms, along the canyon's ledges | pipe | two lines along the ledges, one length per stretch between the bands and the bridges | 14 | bow/top, mid/top, stern/top | a trunk, trim collars, end flanges, saddles | picture |
| latches | lock the hull modules together across each module band | latch | rows of four clamp heads beside the bands on the ridge decks | 24 | bow/top, mid/top, stern/top | a base plate, four machined clamps | designed |
| vents | heat louvres over the crew decks, the drive coolant plant and the engine room | vent | long louvres on the ridge decks and the stern deck | 8 | bow/top, mid/top, stern/top | a machined frame, straight slats over a dark recess | picture |
| windows | blue-white windows of the ridges' crew decks (lore 3.3) | slit | window slits on the flank band, and the engine room's control windows facing up the canyon | 24 | bow/side, mid/side, stern/side | a trim frame round a recessed pane | picture |
| hatches | crew and stores access: deck, belly and flank hatches | hatch | flush rectangular armoured hatches | 9 | bow/top, bow/below, mid/below, stern/below, bow/side, stern/side | a trim rim, a flush door, a seam, a recessed grip | picture |
| lift_heads | the stern lift head: stores up to the engine room | hatchbox | a low module housing on the stern deck | 1 | stern/top | a chamfered frame, an inset lid with a seam, a blue strip | designed |

Kit sub-parts per type (what DETAILED checks):

- antenna: root, fin, window, lens
- band: band, seam, strip
- capbank: base, cell, cap, bus, strip
- engine: housing, lip, lining, throat, vane, band
- exchanger: base, housing, fin, frame, port
- gun: ring, housing, mantlet, barrel, coil, muzzle, bore
- hatch: rim, door, seam, grip
- hatchbox: frame, lid, seam
- hull: facet, step, chamfer
- ion_trench: liner, coil, emitter, lens
- latch: base, clamp
- pipe: trunk, collar, flange, saddle
- plate: panel, seam, module
- slit: frame, glass
- thruster: block, nozzle
- tier: face, roof, opening
- vent: frame, slat

Left as surface, and why:

- IM5 has no side view and no underside view: the side and below cells have no concept picture to tick against, and the concept's length to height is not measured.
- IM5_top.jpg's own "IM5 TOP" label covers the bow tip, so the concept top view's length is measured short (to the label's edge); the bow is read from the three-quarter.
- The flank band carries only the blue line, the windows and the breach anchors: IM5 draws it as a plain band under the light strip.
- Stencil marks are paint, not modelled (the Hegemony stack, a later job).

## Every built part has a job (R221)

Built kit parts: 124; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, hegemony_IM5_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull | the broad wedge with the canyon cut down its spine: ridge decks, chamf | 1 / 1 | Y | Y | Y |
| bow_face | the blunt bow face, the ridge ends and the bow deck running to it, arm | 1 / 1 | Y | Y | Y |
| bridges | three low bridge decks flush with the ridge decks (bow, midships, ster | 1 / 1 | Y | Y | Y |
| module_bands | six raised trim rings round the whole section, canyon included, with a | 1 / 1 | Y | Y | Y |
| blue_line | a blue strip along each flank band, broken at the module bands, and on | 1 / 1 | Y | Y | Y |
| deck_panels | flush panels on the ridge decks, the pit floors, the bow and stern dec | 1 / 1 | Y | Y | Y |
| canyon_panels | flush panels on the canyon floor, its walls and ledges | 1 / 1 | Y | Y | Y |
| ion_trench | the emitter trench recessed in the blunt bow face at the canyon's mout | 1 / 1 | Y | Y | Y |
| sensor_fin | a low swept fin on the centreline of the bow deck | 1 / 1 | Y | Y | Y |
| capbanks | two capacitor banks of identical cells | 2 / 2 | Y | Y | Y |
| trunks | two trunks along the canyon floor, one length per module, coupled at t | 10 / 10 | Y | Y | Y |
| coolant_lines | two lines along the ledges, one length per stretch between the bands a | 14 / 14 | Y | Y | Y |
| latches | rows of four clamp heads beside the bands on the ridge decks | 24 / 24 | Y | Y | Y |
| vents | long louvres on the ridge decks and the stern deck | 8 / 8 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 9 / 9 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull | the broad wedge with the canyon cut down its spine: ridge decks, chamf | 1 / 1 | Y | Y | Y |
| bow_face | the blunt bow face, the ridge ends and the bow deck running to it, arm | 1 / 1 | Y | Y | Y |
| module_bands | six raised trim rings round the whole section, canyon included, with a | 1 / 1 | Y | Y | Y |
| blue_line | a blue strip along each flank band, broken at the module bands, and on | 1 / 1 | Y | Y | Y |
| flank_panels | flush panels on the upper and lower facets | 1 / 1 | Y | Y | Y |
| ion_trench | the emitter trench recessed in the blunt bow face at the canyon's mout | 1 / 1 | Y | Y | Y |
| sensor_fin | a low swept fin on the centreline of the bow deck | 1 / 1 | Y | Y | Y |
| thrusters | rectangular nozzle blocks | 6 / 6 | Y | Y | Y |
| windows | window slits on the flank band, and the engine room's control windows  | 24 / 24 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 9 / 9 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull | the broad wedge with the canyon cut down its spine: ridge decks, chamf | 1 / 1 | Y | Y | Y |
| bow_face | the blunt bow face, the ridge ends and the bow deck running to it, arm | 1 / 1 | Y | Y | Y |
| belly_panels | flush panels on the belly and the belly armour step | 2 / 1 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 9 / 9 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull | the broad wedge with the canyon cut down its spine: ridge decks, chamf | 1 / 1 | Y | Y | Y |
| bridges | three low bridge decks flush with the ridge decks (bow, midships, ster | 1 / 1 | Y | Y | Y |
| module_bands | six raised trim rings round the whole section, canyon included, with a | 1 / 1 | Y | Y | Y |
| blue_line | a blue strip along each flank band, broken at the module bands, and on | 1 / 1 | Y | Y | Y |
| deck_panels | flush panels on the ridge decks, the pit floors, the bow and stern dec | 1 / 1 | Y | Y | Y |
| canyon_panels | flush panels on the canyon floor, its walls and ledges | 1 / 1 | Y | Y | Y |
| lances | two low wide lance turrets sunk in the shoulder pits, two short thick  | 2 / 2 | Y | Y | Y |
| bridge_lance | the lance turret at a smaller size on the midships bridge, two barrels | 1 / 1 | Y | Y | Y |
| capbanks | two capacitor banks of identical cells | 2 / 2 | Y | Y | Y |
| exchangers | four heat exchangers on the canyon floor | 4 / 4 | Y | Y | Y |
| trunks | two trunks along the canyon floor, one length per module, coupled at t | 10 / 10 | Y | Y | Y |
| coolant_lines | two lines along the ledges, one length per stretch between the bands a | 14 / 14 | Y | Y | Y |
| latches | rows of four clamp heads beside the bands on the ridge decks | 24 / 24 | Y | Y | Y |
| vents | long louvres on the ridge decks and the stern deck | 8 / 8 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull | the broad wedge with the canyon cut down its spine: ridge decks, chamf | 1 / 1 | Y | Y | Y |
| module_bands | six raised trim rings round the whole section, canyon included, with a | 1 / 1 | Y | Y | Y |
| blue_line | a blue strip along each flank band, broken at the module bands, and on | 1 / 1 | Y | Y | Y |
| flank_panels | flush panels on the upper and lower facets | 1 / 1 | Y | Y | Y |
| lances | two low wide lance turrets sunk in the shoulder pits, two short thick  | 2 / 2 | Y | Y | Y |
| windows | window slits on the flank band, and the engine room's control windows  | 24 / 24 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull | the broad wedge with the canyon cut down its spine: ridge decks, chamf | 1 / 1 | Y | Y | Y |
| belly_panels | flush panels on the belly and the belly armour step | 2 / 1 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 9 / 9 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull | the broad wedge with the canyon cut down its spine: ridge decks, chamf | 1 / 1 | Y | Y | Y |
| bridges | three low bridge decks flush with the ridge decks (bow, midships, ster | 1 / 1 | Y | Y | Y |
| module_bands | six raised trim rings round the whole section, canyon included, with a | 1 / 1 | Y | Y | Y |
| blue_line | a blue strip along each flank band, broken at the module bands, and on | 1 / 1 | Y | Y | Y |
| deck_panels | flush panels on the ridge decks, the pit floors, the bow and stern dec | 1 / 1 | Y | Y | Y |
| canyon_panels | flush panels on the canyon floor, its walls and ledges | 1 / 1 | Y | Y | Y |
| pickets | one twin picket turret on the stern bridge | 1 / 1 | Y | Y | Y |
| engines | six nozzle pods in one row across the stern | 6 / 6 | Y | Y | Y |
| exchangers | four heat exchangers on the canyon floor | 4 / 4 | Y | Y | Y |
| trunks | two trunks along the canyon floor, one length per module, coupled at t | 10 / 10 | Y | Y | Y |
| coolant_lines | two lines along the ledges, one length per stretch between the bands a | 14 / 14 | Y | Y | Y |
| latches | rows of four clamp heads beside the bands on the ridge decks | 24 / 24 | Y | Y | Y |
| vents | long louvres on the ridge decks and the stern deck | 8 / 8 | Y | Y | Y |
| lift_heads | a low module housing on the stern deck | 1 / 1 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull | the broad wedge with the canyon cut down its spine: ridge decks, chamf | 1 / 1 | Y | Y | Y |
| module_bands | six raised trim rings round the whole section, canyon included, with a | 1 / 1 | Y | Y | Y |
| blue_line | a blue strip along each flank band, broken at the module bands, and on | 1 / 1 | Y | Y | Y |
| flank_panels | flush panels on the upper and lower facets | 1 / 1 | Y | Y | Y |
| engines | six nozzle pods in one row across the stern | 6 / 6 | Y | Y | Y |
| thrusters | rectangular nozzle blocks | 6 / 6 | Y | Y | Y |
| windows | window slits on the flank band, and the engine room's control windows  | 24 / 24 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 9 / 9 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull | the broad wedge with the canyon cut down its spine: ridge decks, chamf | 1 / 1 | Y | Y | Y |
| belly_panels | flush panels on the belly and the belly armour step | 2 / 1 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 9 / 9 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (IM5 top view by eye: bow, the two ridge ends and the bow deck with the fin; midships, the two ridges, the canyon, the bow and midships bridges, the shoulder turrets; stern, the two ridges, the canyon, the stern bridge, the stern block with the nozzles; no side or underside view); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 3 | 4 | Hull: the broad wedge with its canyon; Bow face round the ion trench; Bridge deck, bow; Belly armour step |
| bow/side | no view | 4 | Hull: the broad wedge with its canyon; Bow face round the ion trench; Bridge deck, bow; Belly armour step |
| bow/below | no view | 3 | Hull: the broad wedge with its canyon; Bow face round the ion trench; Belly armour step |
| mid/top | 6 | 4 | Hull: the broad wedge with its canyon; Bridge deck, bow; Bridge deck, mid; Belly armour step |
| mid/side | no view | 4 | Hull: the broad wedge with its canyon; Bridge deck, bow; Bridge deck, mid; Belly armour step |
| mid/below | no view | 2 | Hull: the broad wedge with its canyon; Belly armour step |
| stern/top | 5 | 3 | Hull: the broad wedge with its canyon; Bridge deck, stern; Belly armour step |
| stern/side | no view | 3 | Hull: the broad wedge with its canyon; Bridge deck, stern; Belly armour step |
| stern/below | no view | 2 | Hull: the broad wedge with its canyon; Belly armour step |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 2.33 | no side view | 2.33 | no side view |
| build | 2.45 | 6.97 | 2.66 | 7.88 |

Lines not present, shaped and detailed without a reason: 0.
