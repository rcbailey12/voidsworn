# hegemony_H7 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/hegemony/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/hegemony_H7_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| dart | the whole ship: one long tapering dart that carries the casemate, the barbette, the crew decks and the drives (designs.md: the only escort with no rails) | hull | nine lofted cross-sections: a clipped nose, broad aft shoulders, a flat deck, one broad upper bevel, the flank band, a lower bevel, a chine and a flat sole; three modules | 1 | bow/top, mid/top, stern/top, bow/side, mid/side, stern/side | bevels round a vertical band (never a flat wall, R244), the taper in plan | picture |
| bow_face | the blunt armoured bow round the casemate (R183 (1)): it meets fire head on | hull | the blunt gun face with cheek webs, a sill and a lintel round the mouth, armour plates above and below it | 1 | bow/top, bow/side | the dart's bevels running to an upright face, plates round the mouth | picture |
| belly_floor | Ryan's flat worked belly in place of the concept's V keel: the service trunk | hull | five removable centreline covers with paired runners along the flat sole | 1 | mid/side | a flat sole, bolted covers and runners on it | designed |
| module_bands | the joints between hull modules: the hull gives way here (factions.md "How it breaks"); the breach anchors sit on them | band | two collars, each a pair of trim rings round a dark seam, at 27 and 74 percent from the stern | 1 | bow/top, mid/top, stern/top, bow/side, mid/side, stern/side | two trim rings and a dark seam ring between them | picture |
| blue_line | the implant-blue running lights (factions.md: a line of blue light) | band | a trim race with a blue light along each flank band, broken at the joints and the boarding doors | 1 | bow/side, mid/side, stern/side | a raised strip that glows | picture |
| deck_panels | deck armour: module plates with deep plate-line cuts (R443) | plate | deck plates in two module sizes | 1 | bow/top, mid/top, stern/top | machined slabs with deep seams round them | picture |
| flank_panels | side armour on the bevels and the chines | plate | plates on the upper and lower bevels and the chines | 1 | bow/side, mid/side, stern/side | machined slabs with deep seams, two module sizes | picture |
| belly_panels | belly armour | plate | plates on the flat sole either side of the service trunk | 1 | mid/side | machined slabs with deep seams | designed |
| casemate | the Plasma cannon (laser F, 2 shots): the Picket's forward gun | gun | a fixed casemate inside the bow face, two short bores side by side, recessed so they barely protrude (never the ion trench) | 1 | bow/top, bow/side | a lined recess, a trim frame, a mantlet, breeches, barrels with coil rings, muzzles, blue-lit bores | picture |
| barbette | the Picket lasers (flak T, 3 shots): point defence all round | gun | one low dorsal turret on an eight-sided plinth, three short emitters | 1 | mid/top | a faceted plinth, a flush ring, a faceted housing, three emitters with coil collars | picture |
| sensor_fin | the ship's sensors: one low swept receiver (factions.md) | antenna | a low swept receiver on the centreline, ahead of the barbette | 1 | bow/top, bow/side | a root plinth, the fin, sensor windows, a lens strip | picture |
| engines | the main drives: two rectangular blue-white nozzles in one flat row (designs.md) | engine | two nozzle pods seated in the stern | 2 | stern/top, stern/side | a thick lip, inner walls tapering to a blue-white throat, guide vanes, a sleeve with trim bands (R244: an opening with depth) | picture |
| coolers | heat rejection for the reactor and the drives (Astra: the radiator grills Ryan picked, R442) | vent | slatted cooler cassettes on the belly, five a side | 10 | mid/side | a machined frame, straight slats over a dark recess | designed |
| thrusters | retro thrusters on the bow face (lore 3.4: backing off is cheap; ability evasive) and attitude thrusters on the bevels | thruster | rectangular nozzle blocks | 6 | bow/side, stern/side | a block, rectangular nozzles with depth | designed |
| latches | lock the hull modules together across each joint | latch | rows of clamp heads against the joint collars, running along them | 8 | bow/top, mid/top, stern/top | a base plate, machined clamps | designed |
| vents | heat louvres over the drive feeds | vent | louvres on the aft deck | 2 | bow/top, mid/top, stern/top | a machined frame, straight slats over a dark recess | picture |
| hatches | crew access: deck hatches and the boarding doors at the waist | hatch | flush rectangular armoured hatches | 5 | bow/top, mid/top, stern/top, mid/side | a trim rim, a flush door, a seam, a recessed grip | picture |

Kit sub-parts per type (what DETAILED checks):

- antenna: root, fin, window, lens
- band: band, seam, strip
- engine: housing, lip, lining, throat, vane, band
- gun: ring, housing, mantlet, barrel, coil, muzzle, bore
- hatch: rim, door, seam, grip
- hull: facet, step, chamfer
- latch: base, clamp
- plate: panel, seam, module
- thruster: block, nozzle
- vent: frame, slat

Left as surface, and why:

- The flank band carries only the light race, the boarding doors and the breach anchors.
- No drone doors, window slits or capacitor louvres (Ryan, Nov 23 2026: the added fittings read as patched on); the light races and the boarding doors do those jobs.
- The concept's scattered surface greebles are not built one for one: the deep-cut module plates and the fittings with a job stand in for them (R221).
- Stencil marks are paint, not modelled (the Hegemony stack).

## Every built part has a job (R221)

Built kit parts: 45; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, hegemony_H7_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| dart | nine lofted cross-sections: a clipped nose, broad aft shoulders, a fla | 1 / 1 | Y | Y | Y |
| bow_face | the blunt gun face with cheek webs, a sill and a lintel round the mout | 1 / 1 | Y | Y | Y |
| module_bands | two collars, each a pair of trim rings round a dark seam, at 27 and 74 | 1 / 1 | Y | Y | Y |
| deck_panels | deck plates in two module sizes | 1 / 1 | Y | Y | Y |
| casemate | a fixed casemate inside the bow face, two short bores side by side, re | 1 / 1 | Y | Y | Y |
| sensor_fin | a low swept receiver on the centreline, ahead of the barbette | 1 / 1 | Y | Y | Y |
| latches | rows of clamp heads against the joint collars, running along them | 8 / 8 | Y | Y | Y |
| vents | louvres on the aft deck | 2 / 2 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 5 / 5 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| dart | nine lofted cross-sections: a clipped nose, broad aft shoulders, a fla | 1 / 1 | Y | Y | Y |
| bow_face | the blunt gun face with cheek webs, a sill and a lintel round the mout | 1 / 1 | Y | Y | Y |
| module_bands | two collars, each a pair of trim rings round a dark seam, at 27 and 74 | 1 / 1 | Y | Y | Y |
| blue_line | a trim race with a blue light along each flank band, broken at the joi | 1 / 1 | Y | Y | Y |
| flank_panels | plates on the upper and lower bevels and the chines | 1 / 1 | Y | Y | Y |
| casemate | a fixed casemate inside the bow face, two short bores side by side, re | 1 / 1 | Y | Y | Y |
| sensor_fin | a low swept receiver on the centreline, ahead of the barbette | 1 / 1 | Y | Y | Y |
| thrusters | rectangular nozzle blocks | 6 / 6 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| - | nothing listed in this cell | | | | |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| dart | nine lofted cross-sections: a clipped nose, broad aft shoulders, a fla | 1 / 1 | Y | Y | Y |
| module_bands | two collars, each a pair of trim rings round a dark seam, at 27 and 74 | 1 / 1 | Y | Y | Y |
| deck_panels | deck plates in two module sizes | 1 / 1 | Y | Y | Y |
| barbette | one low dorsal turret on an eight-sided plinth, three short emitters | 2 / 1 | Y | Y | Y |
| latches | rows of clamp heads against the joint collars, running along them | 8 / 8 | Y | Y | Y |
| vents | louvres on the aft deck | 2 / 2 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 5 / 5 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| dart | nine lofted cross-sections: a clipped nose, broad aft shoulders, a fla | 1 / 1 | Y | Y | Y |
| belly_floor | five removable centreline covers with paired runners along the flat so | 1 / 1 | Y | Y | Y |
| module_bands | two collars, each a pair of trim rings round a dark seam, at 27 and 74 | 1 / 1 | Y | Y | Y |
| blue_line | a trim race with a blue light along each flank band, broken at the joi | 1 / 1 | Y | Y | Y |
| flank_panels | plates on the upper and lower bevels and the chines | 1 / 1 | Y | Y | Y |
| belly_panels | plates on the flat sole either side of the service trunk | 1 / 1 | Y | Y | Y |
| coolers | slatted cooler cassettes on the belly, five a side | 10 / 10 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 5 / 5 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| - | nothing listed in this cell | | | | |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| dart | nine lofted cross-sections: a clipped nose, broad aft shoulders, a fla | 1 / 1 | Y | Y | Y |
| module_bands | two collars, each a pair of trim rings round a dark seam, at 27 and 74 | 1 / 1 | Y | Y | Y |
| deck_panels | deck plates in two module sizes | 1 / 1 | Y | Y | Y |
| engines | two nozzle pods seated in the stern | 2 / 2 | Y | Y | Y |
| latches | rows of clamp heads against the joint collars, running along them | 8 / 8 | Y | Y | Y |
| vents | louvres on the aft deck | 2 / 2 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 5 / 5 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| dart | nine lofted cross-sections: a clipped nose, broad aft shoulders, a fla | 1 / 1 | Y | Y | Y |
| module_bands | two collars, each a pair of trim rings round a dark seam, at 27 and 74 | 1 / 1 | Y | Y | Y |
| blue_line | a trim race with a blue light along each flank band, broken at the joi | 1 / 1 | Y | Y | Y |
| flank_panels | plates on the upper and lower bevels and the chines | 1 / 1 | Y | Y | Y |
| engines | two nozzle pods seated in the stern | 2 / 2 | Y | Y | Y |
| thrusters | rectangular nozzle blocks | 6 / 6 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| - | nothing listed in this cell | | | | |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (Picket, merged build: bow, the clipped nose, the gun face and the casemate; midships, the broad shoulders, the receiver and the barbette; stern, the taper in and the two nozzle pods); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 2 | 3 | Hull: the dart, mission module; Dart: fore module; Dart: casemate module |
| bow/side | 2 | 3 | Hull: the dart, mission module; Dart: fore module; Dart: casemate module |
| bow/below | no view | 3 | Hull: the dart, mission module; Dart: fore module; Dart: casemate module |
| mid/top | 3 | 2 | Hull: the dart, mission module; Flak barbette plinth |
| mid/side | 2 | 2 | Hull: the dart, mission module; Flak barbette plinth |
| mid/below | no view | 2 | Hull: the dart, mission module; Flak barbette plinth |
| stern/top | 2 | 3 | Dart: drive module; Hull: the dart, mission module; Flak barbette plinth |
| stern/side | 2 | 3 | Dart: drive module; Hull: the dart, mission module; Flak barbette plinth |
| stern/below | no view | 3 | Dart: drive module; Hull: the dart, mission module; Flak barbette plinth |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 2.77 | 5.18 | 2.81 | 6.59 |
| build | 2.71 | 5.62 | 2.83 | 8.30 |

Lines not present, shaped and detailed without a reason: 0.
