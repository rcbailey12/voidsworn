# voidsworn_S9 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/voidsworn/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/voidsworn_S9_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| spearhead | the blade's point and its forward armour: the knife the frigate leads with (factions.md: a black iron blade) | hull | the forged spearhead: one point at mid height, diamond in section, its facets running back into the hull | 1 | bow/top, bow/side, bow/below | the upper and lower facets meeting at the knuckle, a crowned deck, a chamfered deck edge, a raised centre ridge, a layer of cheek plates | picture |
| bow_plates | armour over the spearhead: forged plates in sleek triangles (R243) | plate | cheek plates and the bow facets' plating | 1 | bow/top, bow/side | slabs with bevels, reinforcing steps and rivet lines | picture |
| bow_gun | the Sear repeater (autocannon F, 3 shots): the frigate's main gun, fixed forward | gun | a compact forged casemate at the spearhead root, station 14 percent, a three-barrel rotary cluster | 1 | bow/top, bow/side | a riveted footing, an armoured housing with cheek plates and a sloped glacis, a round port collar, a ball mantlet, a heat jacket, clamp bands, three barrels, a muzzle ring, dark bores with ember lenses | picture |
| casemate | the bow gun's housing on the deck | tier | the casemate block (its face, roof and the port opening) | 1 | bow/top, bow/side | a face, a stepped roof, the port opening | picture |
| blade | carries everything: the crew deck, the magazines, the reactor and the drives | hull | the narrow faceted hull: a crowned deck, upper facets sloping out to the knuckle, the plated band, lower facets, a flat worked belly; widest at the stern third | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | angled facets and chamfers (never a flat wall, R244), the knuckle line, a deck-edge chamfer, a chine | picture |
| deck_plates | deck armour over the crew deck and the magazines | plate | ordered rows of forged plates over the deck | 1 | bow/top, mid/top, stern/top | slabs with bevels, reinforcing steps and rivet lines | picture |
| flank_plates | side armour: the facets and the band | plate | ordered rows of forged plates over the facets and the band | 1 | bow/side, mid/side, stern/side | slabs with bevels, reinforcing steps and rivet lines | picture |
| belly_plates | belly armour | plate | forged plates over the belly and the armour step | 1 | bow/below, mid/below, stern/below | slabs with bevels, reinforcing steps and rivet lines | designed |
| trunk | the dorsal power trunk: armoured conduits from the reactor to the bow gun | spine | a low banded trunk along the deck's centreline (the concept's long centre rail) | 1 | bow/top, mid/top | a stepped block with bands across it | picture |
| gun_deck | the hull's armoured belt: the plated band with its lips (no ports: no broadside slot) | belt | the plated band with its upper and lower lips, both flanks | 1 | mid/side, mid/top | a band along the hull with angled ends, plates on it | picture |
| band_louvres | heat louvres in the band: the crew spaces and the magazines breathe out here | vent | louvres in the plated band, four a side (the concept's lit marks along the band) | 8 | mid/side, stern/side | a forged frame, slanted slats over an ember-lit recess | picture |
| flak | the spark flak (flak T, 3 shots): point defence against craft | gun | two low drum turrets on tubs at the deck edges, two barrels each, station 60 percent | 2 | mid/top, mid/side | a riveted ring, a squat forged drum, a cradle, two ammunition drums, slotted cooling sleeves, squared muzzle brakes (R221) | picture |
| barbettes | the flak tubs: they carry the turret rings at the deck edges | tier | low forged tubs under the two flak turrets | 1 | mid/top, mid/side | a face, a roof that takes the ring, the ring opening | picture |
| hatches | crew and stores access: deck hatches and belly hatches | hatch | forged round hatches on the deck and the belly step | 4 | bow/top, mid/below | a studded rim, a door with a bar, a seam, hinges | designed |
| spine | the spire line's base: it carries the spires and the command deck's windows, and snaps off with the spires (B-3) | spine | the forged spine block along the centreline aft, its forward face | 1 | stern/top, stern/side, mid/top | a chamfered block, a stepped face, the window slits | picture |
| spine_plates | armour over the spine block | plate | forged plates over the spine block | 1 | stern/top, stern/side | slabs with bevels, reinforcing steps and rivet lines | designed |
| bridge_slits | the command deck's windows (factions.md: ember windows) | slit | three ember slits in the spine block's forward face (the concept's lit spine block face) | 3 | mid/top, stern/top | a forged frame round a recessed ember pane, a brow | picture |
| spires | shed the reactor's heat (lore 2.5): the ember radiator spires, smaller per R331 | radiator | three radiator spires along the spine block, the middle one tallest (0.65), three profiles (raked, stepped, blade) | 3 | stern/top, stern/side | a forged root socket, a column (iron posts fore and aft round a glowing core), a stack of horizontal iron fins with the ember in the slats between, a forged cap, gusset braces | picture |
| vents | reactor heat louvres over the reactor room | vent | heat louvres on the upper facets aft | 4 | stern/side, stern/top | a forged frame, slanted slats over an ember-lit recess | designed |
| engines | drive (sp 5, the fastest Sunward hull): two ember bells, deep-set | engine | two engine bells 0.55 across on riveted drums | 2 | stern/top, stern/side, stern/below | a 16-sided drum of forged plate courses, riveted bands, a mount collar, struts, a deep bell with stiffener rings and a rolled lip, an ember lining, a hot throat, a glowing plug cone | picture |
| thrusters | attitude control at the bow and the stern (tn 3: the frigate turns its bow gun onto targets) | thruster | attitude thrusters on the upper facets, two forward and two aft | 4 | bow/side, stern/side | a forged block, round nozzle throats with depth (R244) | designed |
| lamps | frost-white running points on the blade's edge (paint direction sunward.md 5) | lamp | small frost lamps along the knuckle forward and the deck edge aft | 10 | bow/side, mid/side, stern/side | a low housing, a hood, a round lens | designed |

Kit sub-parts per type (what DETAILED checks):

- belt: band, plate
- engine: housing, band, collar, bell, lining, throat, plug, bellring
- gun: ring|port, mantlet, barrel, jacket, muzzle, bore
- hatch: rim, door, seam, hinge
- hull: facet, step, chamfer
- lamp: housing, lens
- plate: slab, step, bevel, rivet
- radiator: root, column, cap, fin, bar, brace
- slit: frame, glass
- spine: block, step, slit
- thruster: block, nozzle
- tier: face, roof, opening
- vent: frame, slat

Left as surface, and why:

- Frost-white markings, the half-sun crest, soot and wear: surface texture, painted by the Sunward paint stack (stage 5), not modelled.
- The concept's small panels and window dots along the hull are the paint stack's plate pattern and the band louvres; no portholes (factions.md).

## Every built part has a job (R221)

Built kit parts: 58; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, voidsworn_S9_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spearhead | the forged spearhead: one point at mid height, diamond in section, its | 1 / 1 | Y | Y | Y |
| bow_plates | cheek plates and the bow facets' plating | 2 / 1 | Y | Y | n | the cheek plates are themselves the forged layer on the spearhead (built, shaped, with bevels); their faces are too narrow for a second plate course except at the root, which the casemate and the Q1 thrusters claim, so no rivet plates are laid on them
| bow_gun | a compact forged casemate at the spearhead root, station 14 percent, a | 1 / 1 | Y | Y | Y |
| casemate | the casemate block (its face, roof and the port opening) | 1 / 1 | Y | Y | Y |
| blade | the narrow faceted hull: a crowned deck, upper facets sloping out to t | 1 / 1 | Y | Y | Y |
| deck_plates | ordered rows of forged plates over the deck | 1 / 1 | Y | Y | Y |
| trunk | a low banded trunk along the deck's centreline (the concept's long cen | 1 / 1 | Y | Y | Y |
| hatches | forged round hatches on the deck and the belly step | 4 / 4 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spearhead | the forged spearhead: one point at mid height, diamond in section, its | 1 / 1 | Y | Y | Y |
| bow_plates | cheek plates and the bow facets' plating | 2 / 1 | Y | Y | n | the cheek plates are themselves the forged layer on the spearhead (built, shaped, with bevels); their faces are too narrow for a second plate course except at the root, which the casemate and the Q1 thrusters claim, so no rivet plates are laid on them
| bow_gun | a compact forged casemate at the spearhead root, station 14 percent, a | 1 / 1 | Y | Y | Y |
| casemate | the casemate block (its face, roof and the port opening) | 1 / 1 | Y | Y | Y |
| blade | the narrow faceted hull: a crowned deck, upper facets sloping out to t | 1 / 1 | Y | Y | Y |
| flank_plates | ordered rows of forged plates over the facets and the band | 4 / 1 | Y | Y | Y |
| thrusters | attitude thrusters on the upper facets, two forward and two aft | 4 / 4 | Y | Y | Y |
| lamps | small frost lamps along the knuckle forward and the deck edge aft | 10 / 10 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spearhead | the forged spearhead: one point at mid height, diamond in section, its | 1 / 1 | Y | Y | Y |
| blade | the narrow faceted hull: a crowned deck, upper facets sloping out to t | 1 / 1 | Y | Y | Y |
| belly_plates | forged plates over the belly and the armour step | 2 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the narrow faceted hull: a crowned deck, upper facets sloping out to t | 1 / 1 | Y | Y | Y |
| deck_plates | ordered rows of forged plates over the deck | 1 / 1 | Y | Y | Y |
| trunk | a low banded trunk along the deck's centreline (the concept's long cen | 1 / 1 | Y | Y | Y |
| gun_deck | the plated band with its upper and lower lips, both flanks | 1 / 1 | Y | Y | Y |
| flak | two low drum turrets on tubs at the deck edges, two barrels each, stat | 2 / 2 | Y | Y | Y |
| barbettes | low forged tubs under the two flak turrets | 1 / 1 | Y | Y | Y |
| spine | the forged spine block along the centreline aft, its forward face | 1 / 1 | Y | Y | Y |
| bridge_slits | three ember slits in the spine block's forward face | 3 / 3 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the narrow faceted hull: a crowned deck, upper facets sloping out to t | 1 / 1 | Y | Y | Y |
| flank_plates | ordered rows of forged plates over the facets and the band | 4 / 1 | Y | Y | Y |
| gun_deck | the plated band with its upper and lower lips, both flanks | 1 / 1 | Y | Y | Y |
| band_louvres | louvres in the plated band, four a side | 8 / 8 | Y | Y | Y |
| flak | two low drum turrets on tubs at the deck edges, two barrels each, stat | 2 / 2 | Y | Y | Y |
| barbettes | low forged tubs under the two flak turrets | 1 / 1 | Y | Y | Y |
| lamps | small frost lamps along the knuckle forward and the deck edge aft | 10 / 10 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the narrow faceted hull: a crowned deck, upper facets sloping out to t | 1 / 1 | Y | Y | Y |
| belly_plates | forged plates over the belly and the armour step | 2 / 1 | Y | Y | Y |
| hatches | forged round hatches on the deck and the belly step | 4 / 4 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the narrow faceted hull: a crowned deck, upper facets sloping out to t | 1 / 1 | Y | Y | Y |
| deck_plates | ordered rows of forged plates over the deck | 1 / 1 | Y | Y | Y |
| spine | the forged spine block along the centreline aft, its forward face | 1 / 1 | Y | Y | Y |
| spine_plates | forged plates over the spine block | 1 / 1 | Y | Y | Y |
| bridge_slits | three ember slits in the spine block's forward face | 3 / 3 | Y | Y | Y |
| spires | three radiator spires along the spine block, the middle one tallest (0 | 3 / 3 | Y | Y | Y |
| vents | heat louvres on the upper facets aft | 4 / 4 | Y | Y | Y |
| engines | two engine bells 0.55 across on riveted drums | 2 / 2 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the narrow faceted hull: a crowned deck, upper facets sloping out to t | 1 / 1 | Y | Y | Y |
| flank_plates | ordered rows of forged plates over the facets and the band | 4 / 1 | Y | Y | Y |
| band_louvres | louvres in the plated band, four a side | 8 / 8 | Y | Y | Y |
| spine | the forged spine block along the centreline aft, its forward face | 1 / 1 | Y | Y | Y |
| spine_plates | forged plates over the spine block | 1 / 1 | Y | Y | Y |
| spires | three radiator spires along the spine block, the middle one tallest (0 | 3 / 3 | Y | Y | Y |
| vents | heat louvres on the upper facets aft | 4 / 4 | Y | Y | Y |
| engines | two engine bells 0.55 across on riveted drums | 2 / 2 | Y | Y | Y |
| thrusters | attitude thrusters on the upper facets, two forward and two aft | 4 / 4 | Y | Y | Y |
| lamps | small frost lamps along the knuckle forward and the deck edge aft | 10 / 10 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the narrow faceted hull: a crowned deck, upper facets sloping out to t | 1 / 1 | Y | Y | Y |
| belly_plates | forged plates over the belly and the armour step | 2 / 1 | Y | Y | Y |
| engines | two engine bells 0.55 across on riveted drums | 2 / 2 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (Warden sheet: bow, the spearhead, its centre ridge and the casemate; midships, the body, the centre rail and the two flak tub pairs (one pair tabled); stern, the body, the spine block, the spires, the two drums and bells); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 3 | 10 | Hull: the blade; Bow ridge; Bow cheek plates, port; Bow cheek plates, starboard; Band upper lip, port; Band lower lip, port; Band upper lip, starboard; Band lower lip, starboard; Belly armour step; Dorsal power trunk |
| bow/side | 3 | 6 | Hull: the blade; Bow ridge; Bow cheek plates, port; Band upper lip, port; Band lower lip, port; Belly armour step |
| bow/below | no view | 10 | Hull: the blade; Bow ridge; Bow cheek plates, port; Bow cheek plates, starboard; Band upper lip, port; Band lower lip, port; Band upper lip, starboard; Band lower lip, starboard; Belly armour step; Dorsal power trunk |
| mid/top | 4 | 10 | Hull: the blade; Band upper lip, port; Band lower lip, port; Band upper lip, starboard; Band lower lip, starboard; Flak tub, port; Flak tub, starboard; Spine block (the spire line's base); Belly armour step; Dorsal power trunk |
| mid/side | 4 | 6 | Hull: the blade; Band upper lip, port; Band lower lip, port; Flak tub, port; Spine block (the spire line's base); Belly armour step |
| mid/below | no view | 10 | Hull: the blade; Band upper lip, port; Band lower lip, port; Band upper lip, starboard; Band lower lip, starboard; Flak tub, port; Flak tub, starboard; Spine block (the spire line's base); Belly armour step; Dorsal power trunk |
| stern/top | 5 | 10 | Hull: the blade; Band upper lip, port; Band lower lip, port; Band upper lip, starboard; Band lower lip, starboard; Spine block (the spire line's base); Radiator spire R1 (raked, 0.47 tall); Radiator spire R2 (stepped, 0.65 tall); Radiator s |
| stern/side | 6 | 5 | Hull: the blade; Band upper lip, port; Band lower lip, port; Spine block (the spire line's base); Belly armour step |
| stern/below | no view | 7 | Hull: the blade; Band upper lip, port; Band lower lip, port; Band upper lip, starboard; Band lower lip, starboard; Spine block (the spire line's base); Belly armour step |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 5.74 | 5.22 | 9.03 | 10.99 |
| build | 4.37 | 4.04 | 4.95 | 7.89 |

Lines not present, shaped and detailed without a reason: 0.
