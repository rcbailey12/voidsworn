# voidsworn_S8 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/voidsworn/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/voidsworn_S8_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| spearhead | the blade's point and its forward armour: it meets fire head on as the line closes (factions.md: a black iron blade) | hull | the forged spearhead: one point at mid height, diamond in section, its facets running back into the hull (replaces S8's fork, R232) | 1 | bow/top, bow/side, bow/below | the upper and lower facets meeting at the knuckle, a crowned deck, a chamfered deck edge, a raised centre ridge, two layers of cheek plates | picture |
| bow_plates | armour over the spearhead: forged plates in sleek triangles (R243) | plate | cheek plates and the bow facets' plating | 1 | bow/top, bow/side | slabs with bevels, reinforcing steps and rivet lines | picture |
| blade | carries everything: the gun deck, the galleries, the reactor and the drives | hull | the long faceted hull: a crowned deck, big upper facets sloping out to the knuckle, the vertical broadside band, lower facets, a flat worked belly; widest at the stern third | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | angled facets and chamfers (never a flat wall, R244), the knuckle line, a deck-edge chamfer, a chine | picture |
| deck_plates | deck armour over the galleries and the turret wells | plate | ordered rows of forged plates over the deck | 1 | bow/top, mid/top, stern/top | slabs with bevels, reinforcing steps and rivet lines | picture |
| flank_plates | side armour: the facets and the broadside band | plate | ordered rows of forged plates over the facets and the band | 1 | bow/side, mid/side, stern/side | slabs with bevels, reinforcing steps and rivet lines | picture |
| belly_plates | belly armour | plate | forged plates over the belly and the armour step | 1 | bow/below, mid/below, stern/below | slabs with bevels, reinforcing steps and rivet lines | designed |
| lift_heads | armoured lift heads: stores up to the forward decks (HB1), power cells up to the Sear turrets (HB2) | hatchbox | low armoured deck housings on the centreline | 2 | bow/top, mid/top | a chamfered frame, an inset lid with a stacked plate, side ribs | designed |
| trunk | the dorsal power trunk: armoured conduits from the reactor to the turrets and the bow | spine | a low banded trunk along the deck's centreline (S8's long centre strip) | 1 | bow/top, mid/top | a stepped block with bands across it | picture |
| gun_deck | the old manual gun deck: armoured shelves over and under the ports, the band they open in | belt | the broadside band with its upper and lower lips, both flanks (S8's recessed gun deck) | 1 | mid/side, mid/top | a band along the hull with angled ends, plates on it | picture |
| broadside | the heavy sear broadside (hbattery P and hbattery S, 5 shots each): the ship's main fire, a line of battle broadside | gun | heavy short guns in deep round ports, five a side (data.js hbattery P, hbattery S) | 10 | mid/side, mid/top | a square riveted surround, a deep round port collar with a rolled lip, a dark throat, a ball mantlet, a finned heat jacket, a banded barrel, a flared muzzle, a dark bore with an ember glow (R221) | picture |
| gallery_slits | the gun galleries' vision slits: the crews behind the ports look out | slit | ember slits in the band between the ports | 4 | mid/side | a forged frame round a recessed ember pane, a brow | designed |
| sear_turrets | the Sear turret (turret T, 2 shots): a las weapon that turns all round | gun | two low domed turrets forward on tubs at the deck edges, one heavy emitter each | 2 | mid/top, mid/side | a flush riveted ring, a faceted forged dome with a banded skirt and a hatch, a radiator bustle with ember fins, a block mantlet, a finned jacket, a focusing tube, a lens collar, an ember lens (R221) | picture |
| flak | the spark flak (flak T, 3 shots): point defence against craft | gun | two low drum turrets aft on tubs at the deck edges, two barrels each | 2 | mid/top, mid/side | a riveted ring, a squat forged drum, a cradle, two ammunition drums, slotted cooling sleeves, squared muzzle brakes (R221) | picture |
| barbettes | the turret tubs: they raise the Sear pair over the flak and carry the turret rings | tier | low forged tubs under the four turrets | 1 | mid/top, mid/side | a face with ribs, a roof that takes the ring, the ring opening | designed |
| hatches | crew and stores access: deck hatches and belly hatches | hatch | forged round hatches on the deck and the belly step | 8 | bow/top, mid/top, mid/below, stern/below | a studded rim, a door with a bar, a seam, hinges | designed |
| spine | the spire line's base: it carries the spires and the command deck's windows, and snaps off with the spires (B-4) | spine | the forged spine block along the centreline aft, its stepped forward face | 1 | stern/top, stern/side | a chamfered block, a stepped face, the window slits | picture |
| spine_plates | armour over the spine block | plate | forged plates over the spine block | 1 | stern/top, stern/side | slabs with bevels, reinforcing steps and rivet lines | designed |
| bridge_slits | the command deck's windows (factions.md: ember windows) | slit | three ember slits in the spine block's forward face (S8's lit block before the radiators) | 3 | stern/top, mid/top | a forged frame round a recessed ember pane, a brow | picture |
| spires | shed the reactor's heat (a hot reactor in vacuum must shed it somewhere, lore 2.5): the ember radiator spires | radiator | seven radiator spires along the spine, tallest at the middle of the row, four profiles (blade, raked, stepped, twin) | 7 | stern/top, stern/side, mid/top | a forged root socket, a column (iron posts fore and aft round a dark core), a stack of horizontal radiator fins out to each side glowing ember, a forged cap, gusset braces | picture |
| vents | reactor heat louvres over the reactor room | vent | heat louvres on the upper facets aft | 6 | stern/side, stern/top | a forged frame, slanted slats over an ember-lit recess | designed |
| engines | drive (sp 2): two big ember bells, deep-set | engine | two big engine bells on riveted drums (S8's two bells) | 2 | stern/top, stern/side, stern/below | a 16-sided drum of forged plate courses, riveted bands, a mount collar, struts, a deep bell with stiffener rings and a rolled lip, an ember lining, a hot throat, a glowing plug cone | picture |
| thrusters | attitude control at the bow and the stern, to turn the long hull (tn 1) | thruster | attitude thrusters on the upper facets, two forward and two aft | 4 | bow/side, stern/side | a forged block, round nozzle throats with depth (R244) | designed |
| lamps | frost-white running points on the blade's edge (paint direction sunward.md 5) | lamp | small frost lamps along the knuckle forward and the deck edge aft | 14 | bow/side, mid/side, stern/side | a low housing, a hood, a round lens | designed |

Kit sub-parts per type (what DETAILED checks):

- belt: band, plate
- engine: housing, band, collar, bell, lining, throat, plug, bellring
- gun: ring|port, mantlet, barrel, jacket, muzzle, bore
- hatch: rim, door, seam, hinge
- hatchbox: frame, lid, rib
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

- Frost-white markings, the half-sun crest, chalked names, soot and wear: surface texture, painted by the Sunward paint stack (a later job, paint_direction_2026_11/sunward.md), not modelled.
- The escort beside the flagship in the beauty is its own ship (a later fleet brief), not part of this hull.

## Every built part has a job (R221)

Built kit parts: 82; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, voidsworn_S8_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spearhead | the forged spearhead: one point at mid height, diamond in section, its | 1 / 1 | Y | Y | Y |
| bow_plates | cheek plates and the bow facets' plating | 4 / 1 | Y | Y | Y |
| blade | the long faceted hull: a crowned deck, big upper facets sloping out to | 1 / 1 | Y | Y | Y |
| deck_plates | ordered rows of forged plates over the deck | 1 / 1 | Y | Y | Y |
| lift_heads | low armoured deck housings on the centreline | 2 / 2 | Y | Y | Y |
| trunk | a low banded trunk along the deck's centreline (S8's long centre strip | 1 / 1 | Y | Y | Y |
| hatches | forged round hatches on the deck and the belly step | 8 / 8 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spearhead | the forged spearhead: one point at mid height, diamond in section, its | 1 / 1 | Y | Y | Y |
| bow_plates | cheek plates and the bow facets' plating | 4 / 1 | Y | Y | Y |
| blade | the long faceted hull: a crowned deck, big upper facets sloping out to | 1 / 1 | Y | Y | Y |
| flank_plates | ordered rows of forged plates over the facets and the band | 4 / 1 | Y | Y | Y |
| thrusters | attitude thrusters on the upper facets, two forward and two aft | 4 / 4 | Y | Y | Y |
| lamps | small frost lamps along the knuckle forward and the deck edge aft | 14 / 14 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spearhead | the forged spearhead: one point at mid height, diamond in section, its | 1 / 1 | Y | Y | Y |
| blade | the long faceted hull: a crowned deck, big upper facets sloping out to | 1 / 1 | Y | Y | Y |
| belly_plates | forged plates over the belly and the armour step | 2 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the long faceted hull: a crowned deck, big upper facets sloping out to | 1 / 1 | Y | Y | Y |
| deck_plates | ordered rows of forged plates over the deck | 1 / 1 | Y | Y | Y |
| lift_heads | low armoured deck housings on the centreline | 2 / 2 | Y | Y | Y |
| trunk | a low banded trunk along the deck's centreline (S8's long centre strip | 1 / 1 | Y | Y | Y |
| gun_deck | the broadside band with its upper and lower lips, both flanks (S8's re | 1 / 1 | Y | Y | Y |
| broadside | heavy short guns in deep round ports, five a side (data.js hbattery P, | 10 / 10 | Y | Y | Y |
| sear_turrets | two low domed turrets forward on tubs at the deck edges, one heavy emi | 2 / 2 | Y | Y | Y |
| flak | two low drum turrets aft on tubs at the deck edges, two barrels each | 2 / 2 | Y | Y | Y |
| barbettes | low forged tubs under the four turrets | 1 / 1 | Y | Y | Y |
| hatches | forged round hatches on the deck and the belly step | 8 / 8 | Y | Y | Y |
| bridge_slits | three ember slits in the spine block's forward face | 3 / 3 | Y | Y | Y |
| spires | seven radiator spires along the spine, tallest at the middle of the ro | 7 / 7 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the long faceted hull: a crowned deck, big upper facets sloping out to | 1 / 1 | Y | Y | Y |
| flank_plates | ordered rows of forged plates over the facets and the band | 4 / 1 | Y | Y | Y |
| gun_deck | the broadside band with its upper and lower lips, both flanks (S8's re | 1 / 1 | Y | Y | Y |
| broadside | heavy short guns in deep round ports, five a side (data.js hbattery P, | 10 / 10 | Y | Y | Y |
| gallery_slits | ember slits in the band between the ports | 4 / 4 | Y | Y | Y |
| sear_turrets | two low domed turrets forward on tubs at the deck edges, one heavy emi | 2 / 2 | Y | Y | Y |
| flak | two low drum turrets aft on tubs at the deck edges, two barrels each | 2 / 2 | Y | Y | Y |
| barbettes | low forged tubs under the four turrets | 1 / 1 | Y | Y | Y |
| lamps | small frost lamps along the knuckle forward and the deck edge aft | 14 / 14 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the long faceted hull: a crowned deck, big upper facets sloping out to | 1 / 1 | Y | Y | Y |
| belly_plates | forged plates over the belly and the armour step | 2 / 1 | Y | Y | Y |
| hatches | forged round hatches on the deck and the belly step | 8 / 8 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the long faceted hull: a crowned deck, big upper facets sloping out to | 1 / 1 | Y | Y | Y |
| deck_plates | ordered rows of forged plates over the deck | 1 / 1 | Y | Y | Y |
| spine | the forged spine block along the centreline aft, its stepped forward f | 1 / 1 | Y | Y | Y |
| spine_plates | forged plates over the spine block | 1 / 1 | Y | Y | Y |
| bridge_slits | three ember slits in the spine block's forward face | 3 / 3 | Y | Y | Y |
| spires | seven radiator spires along the spine, tallest at the middle of the ro | 7 / 7 | Y | Y | Y |
| vents | heat louvres on the upper facets aft | 6 / 6 | Y | Y | Y |
| engines | two big engine bells on riveted drums (S8's two bells) | 2 / 2 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the long faceted hull: a crowned deck, big upper facets sloping out to | 1 / 1 | Y | Y | Y |
| flank_plates | ordered rows of forged plates over the facets and the band | 4 / 1 | Y | Y | Y |
| spine | the forged spine block along the centreline aft, its stepped forward f | 1 / 1 | Y | Y | Y |
| spine_plates | forged plates over the spine block | 1 / 1 | Y | Y | Y |
| spires | seven radiator spires along the spine, tallest at the middle of the ro | 7 / 7 | Y | Y | Y |
| vents | heat louvres on the upper facets aft | 6 / 6 | Y | Y | Y |
| engines | two big engine bells on riveted drums (S8's two bells) | 2 / 2 | Y | Y | Y |
| thrusters | attitude thrusters on the upper facets, two forward and two aft | 4 / 4 | Y | Y | Y |
| lamps | small frost lamps along the knuckle forward and the deck edge aft | 14 / 14 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the long faceted hull: a crowned deck, big upper facets sloping out to | 1 / 1 | Y | Y | Y |
| belly_plates | forged plates over the belly and the armour step | 2 / 1 | Y | Y | Y |
| hatches | forged round hatches on the deck and the belly step | 8 / 8 | Y | Y | Y |
| engines | two big engine bells on riveted drums (S8's two bells) | 2 / 2 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (S8 sheet: bow, the two fork blades, the slot between them and the centre strip; midships, the body, the two gun rows, the four turret domes and the centre strip; stern, the body, the radiator bank (two halves), the lit block, the two drums and bells); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 4 | 6 | Hull: the blade; Bow ridge; Bow cheek plates, port; Bow cheek plates, starboard; Belly armour step; Dorsal power trunk |
| bow/side | 2 | 5 | Hull: the blade; Bow ridge; Bow cheek plates, port; Belly armour step; Dorsal power trunk |
| bow/below | no view | 2 | Hull: the blade; Belly armour step |
| mid/top | 8 | 14 | Hull: the blade; Gun deck upper lip, port; Gun deck lower lip, port; Gun deck upper lip, starboard; Gun deck lower lip, starboard; Sear turret tub, port; Flak tub, port; Sear turret tub, starboard; Flak tub, starboard; Spine block (the spir |
| mid/side | 5 | 10 | Hull: the blade; Gun deck upper lip, port; Gun deck lower lip, port; Sear turret tub, port; Flak tub, port; Spine block (the spire line's base); Radiator spire R1 (blade, 1.6 tall); Radiator spire R2 (raked, 2.0 tall); Belly armour step; Do |
| mid/below | no view | 2 | Hull: the blade; Belly armour step |
| stern/top | 7 | 9 | Hull: the blade; Spine block (the spire line's base); Radiator spire R2 (raked, 2.0 tall); Radiator spire R3 (stepped, 2.4 tall); Radiator spire R4 (twin, 2.6 tall); Radiator spire R5 (stepped, 2.4 tall); Radiator spire R6 (raked, 2.0 tall) |
| stern/side | 6 | 9 | Hull: the blade; Spine block (the spire line's base); Radiator spire R2 (raked, 2.0 tall); Radiator spire R3 (stepped, 2.4 tall); Radiator spire R4 (twin, 2.6 tall); Radiator spire R5 (stepped, 2.4 tall); Radiator spire R6 (raked, 2.0 tall) |
| stern/below | no view | 2 | Hull: the blade; Belly armour step |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 4.95 | 6.73 | 6.38 | 12.11 |
| build | 3.79 | 4.30 | 5.22 | 8.03 |

Lines not present, shaped and detailed without a reason: 0.
