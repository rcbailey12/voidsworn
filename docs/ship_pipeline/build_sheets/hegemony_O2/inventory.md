# hegemony_O2 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/hegemony/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/hegemony_O2_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| wedge | carries the bridge, the holds, the reactor and the drives: the plain wedge bow and the drive section | hull | a flat deck, chamfered deck edges, upper facets out to the knuckle, the flank band, lower facets, a chine, a flat belly | 1 | bow/top, bow/side, bow/below, mid/side, mid/below, stern/top, stern/side, stern/below | facets and chamfers round a vertical band (never a flat wall, R244) | picture |
| rails | the rails either side of the cargo well: the corridors and the air plant run in them | rail | the raised rail decks either side of the well | 1 | mid/top, mid/side | a deck edge, a chamfer, the blue strip on the band below | picture |
| cargo_well | holds the cargo modules: an open well between the rails, its floor over the lower holds | tier | the open well amidships, its end walls lipped | 1 | mid/top | a floor, end walls with trim lips, the opening | picture |
| bow_face | the solid armoured bumper: the bow meets a dock head on (designs.md: no trench, no gun) | hull | the wedge's blunt face with a bumper plate and trim | 1 | bow/top, bow/side | facets running to an upright face, a bumper slab, trim bars | picture |
| docking_clamps | mate the transport to a station or a tug | latch | two clamp rows on the bumper | 2 | bow/side | a base plate, machined clamp heads | picture |
| cargo | the cargo: the thing the convoy carries (designs.md: four identical container modules) | container | four identical cargo modules in a row in the well | 4 | mid/top, mid/side, stern/top, stern/side | a plain slab box, an inset lid with a seam, stiffener ribs, corner castings, mooring clamps | picture |
| mooring | hold each module's lifting eyes on the rail decks | latch | a clamp pair beside each module, both rails | 8 | mid/top | a base plate, machined clamp heads | picture |
| module_bands | the joints between hull modules: the hull gives way here; the breach anchors sit on them | band | raised trim rings with a deep seam at 28, 50 and 72 percent | 1 | bow/top, mid/top, stern/top, bow/side, mid/side, stern/side | two trim rings and a dark seam ring | picture |
| blue_line | the implant-blue running lights along the flanks (factions.md: a line of blue light) | band | a blue strip along each flank band, broken at the bands | 1 | bow/side, mid/side, stern/side | a raised strip that glows | picture |
| sensor_fin | navigation and the convoy link to its escorts | antenna | one low sensor fin on the bow deck ahead of the well | 1 | bow/top, bow/side | a root plinth, a raked fin, sensor windows, a lens strip | picture |
| engines | drive: four rectangular nozzle pods in one flat row | engine | four nozzle pods at the stern | 4 | stern/top, stern/side | a housing, a thick lip, a lining, a glowing throat, guide vanes, trim bands | picture |
| deck_panels | deck armour: flush panels in the even grid | plate | flush deck panels on the bow deck, the rail decks and the drive deck | 1 | bow/top, mid/top, stern/top | machined slabs with seams, two module sizes | picture |
| flank_panels | side armour on the facets | plate | flush panels on the upper and lower facets | 1 | bow/side, mid/side, stern/side | machined slabs with seams, two module sizes | picture |
| belly_panels | belly armour | plate | flush panels on the belly and the armour step | 1 | bow/below, mid/below, stern/below | machined slabs with seams | designed |
| windows | the crew deck's blue-white windows (lore 3.3) | slit | three window slits each side forward | 6 | bow/side | a machined frame round a recessed pane | picture |
| vents | the reactor's and the holds' air and heat louvres | vent | louvres on the drive deck and the rail decks | 10 | mid/top, stern/top | a machined frame, straight slats over a dark recess | picture |
| hatches | crew and stores access | hatch | flank hatches on the band, deck hatches, a belly hatch | 11 | bow/top, mid/side, stern/top, mid/below | a rim, a flush door, a seam, a grip | designed |
| thrusters | braking into a dock and attitude control | thruster | two retro thrusters on the bow face, two attitude thrusters aft | 4 | bow/side, stern/side | a machined block, rectangular nozzle throats with depth | designed |

Kit sub-parts per type (what DETAILED checks):

- antenna: root, fin, window, lens
- band: band, seam, strip
- container: frame, lid, seam, rib, clamp
- engine: housing, lip, lining, throat, vane, band
- hatch: rim, door, seam, grip
- hull: facet, step, chamfer
- latch: base, clamp
- plate: panel, seam, module
- rail: facet, step, strip
- slit: frame, glass
- thruster: block, nozzle
- tier: face, roof, opening
- vent: frame, slat

Left as surface, and why:

- Stencil marks and the steel-blue trim tone: paint (the Hegemony stack), not modelled.
- The beauty's three modules: designs.md tables four.

## Every built part has a job (R221)

Built kit parts: 60; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, hegemony_O2_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | a flat deck, chamfered deck edges, upper facets out to the knuckle, th | 1 / 1 | Y | Y | Y |
| bow_face | the wedge's blunt face with a bumper plate and trim | 1 / 1 | Y | Y | Y |
| module_bands | raised trim rings with a deep seam at 28, 50 and 72 percent | 1 / 1 | Y | Y | Y |
| sensor_fin | one low sensor fin on the bow deck ahead of the well | 1 / 1 | Y | Y | Y |
| deck_panels | flush deck panels on the bow deck, the rail decks and the drive deck | 1 / 1 | Y | Y | Y |
| hatches | flank hatches on the band, deck hatches, a belly hatch | 11 / 11 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | a flat deck, chamfered deck edges, upper facets out to the knuckle, th | 1 / 1 | Y | Y | Y |
| bow_face | the wedge's blunt face with a bumper plate and trim | 1 / 1 | Y | Y | Y |
| docking_clamps | two clamp rows on the bumper | 2 / 2 | Y | Y | Y |
| module_bands | raised trim rings with a deep seam at 28, 50 and 72 percent | 1 / 1 | Y | Y | Y |
| blue_line | a blue strip along each flank band, broken at the bands | 1 / 1 | Y | Y | Y |
| sensor_fin | one low sensor fin on the bow deck ahead of the well | 1 / 1 | Y | Y | Y |
| flank_panels | flush panels on the upper and lower facets | 1 / 1 | Y | Y | Y |
| windows | three window slits each side forward | 6 / 6 | Y | Y | Y |
| thrusters | two retro thrusters on the bow face, two attitude thrusters aft | 4 / 4 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | a flat deck, chamfered deck edges, upper facets out to the knuckle, th | 1 / 1 | Y | Y | Y |
| belly_panels | flush panels on the belly and the armour step | 2 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| rails | the raised rail decks either side of the well | 1 / 1 | Y | Y | Y |
| cargo_well | the open well amidships, its end walls lipped | 1 / 1 | Y | Y | Y |
| cargo | four identical cargo modules in a row in the well | 4 / 4 | Y | Y | Y |
| mooring | a clamp pair beside each module, both rails | 8 / 8 | Y | Y | Y |
| module_bands | raised trim rings with a deep seam at 28, 50 and 72 percent | 1 / 1 | Y | Y | Y |
| deck_panels | flush deck panels on the bow deck, the rail decks and the drive deck | 1 / 1 | Y | Y | Y |
| vents | louvres on the drive deck and the rail decks | 10 / 10 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | a flat deck, chamfered deck edges, upper facets out to the knuckle, th | 1 / 1 | Y | Y | Y |
| rails | the raised rail decks either side of the well | 1 / 1 | Y | Y | Y |
| cargo | four identical cargo modules in a row in the well | 4 / 4 | Y | Y | Y |
| module_bands | raised trim rings with a deep seam at 28, 50 and 72 percent | 1 / 1 | Y | Y | Y |
| blue_line | a blue strip along each flank band, broken at the bands | 1 / 1 | Y | Y | Y |
| flank_panels | flush panels on the upper and lower facets | 1 / 1 | Y | Y | Y |
| hatches | flank hatches on the band, deck hatches, a belly hatch | 11 / 11 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | a flat deck, chamfered deck edges, upper facets out to the knuckle, th | 1 / 1 | Y | Y | Y |
| belly_panels | flush panels on the belly and the armour step | 2 / 1 | Y | Y | Y |
| hatches | flank hatches on the band, deck hatches, a belly hatch | 11 / 11 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | a flat deck, chamfered deck edges, upper facets out to the knuckle, th | 1 / 1 | Y | Y | Y |
| cargo | four identical cargo modules in a row in the well | 4 / 4 | Y | Y | Y |
| module_bands | raised trim rings with a deep seam at 28, 50 and 72 percent | 1 / 1 | Y | Y | Y |
| engines | four nozzle pods at the stern | 4 / 4 | Y | Y | Y |
| deck_panels | flush deck panels on the bow deck, the rail decks and the drive deck | 1 / 1 | Y | Y | Y |
| vents | louvres on the drive deck and the rail decks | 10 / 10 | Y | Y | Y |
| hatches | flank hatches on the band, deck hatches, a belly hatch | 11 / 11 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | a flat deck, chamfered deck edges, upper facets out to the knuckle, th | 1 / 1 | Y | Y | Y |
| cargo | four identical cargo modules in a row in the well | 4 / 4 | Y | Y | Y |
| module_bands | raised trim rings with a deep seam at 28, 50 and 72 percent | 1 / 1 | Y | Y | Y |
| blue_line | a blue strip along each flank band, broken at the bands | 1 / 1 | Y | Y | Y |
| engines | four nozzle pods at the stern | 4 / 4 | Y | Y | Y |
| flank_panels | flush panels on the upper and lower facets | 1 / 1 | Y | Y | Y |
| thrusters | two retro thrusters on the bow face, two attitude thrusters aft | 4 / 4 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | a flat deck, chamfered deck edges, upper facets out to the knuckle, th | 1 / 1 | Y | Y | Y |
| belly_panels | flush panels on the belly and the armour step | 2 / 1 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (Convoy sheet: bow, the wedge and the fin; midships, the rails and the modules; stern, the last modules, the drive block and the nozzle pods); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 2 | 2 | Hull: the wedge and the rails; Belly armour step |
| bow/side | 2 | 2 | Hull: the wedge and the rails; Belly armour step |
| bow/below | no view | 2 | Hull: the wedge and the rails; Belly armour step |
| mid/top | 5 | 2 | Hull: the wedge and the rails; Belly armour step |
| mid/side | 5 | 2 | Hull: the wedge and the rails; Belly armour step |
| mid/below | no view | 2 | Hull: the wedge and the rails; Belly armour step |
| stern/top | 4 | 2 | Hull: the wedge and the rails; Belly armour step |
| stern/side | 3 | 2 | Hull: the wedge and the rails; Belly armour step |
| stern/below | no view | 2 | Hull: the wedge and the rails; Belly armour step |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 3.06 | 9.13 | 3.59 | 15.74 |
| build | 3.02 | 5.52 | 3.14 | 5.73 |

Lines not present, shaped and detailed without a reason: 0.
