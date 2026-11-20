# voidsworn_S11 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/voidsworn/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/voidsworn_S11_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| spearhead | the blade's point and its forward armour (factions.md: a black iron blade) | hull | the forged point: one long leaf taper to a point at mid height, diamond in section | 1 | bow/top, bow/side, bow/below | the upper and lower facets meeting at the knuckle, a crowned deck, a chamfered deck edge, the centre ridge | picture |
| tube_cowls | carries the torpedo tubes: raised armoured houses on the deck, either side of the centreline | tier | two tube cowls on the deck at about 22 percent, their mouths forward, tapering aft into the deck | 1 | bow/top, bow/side | a forward face, a roof sloping back into the deck, the tube openings in it | picture |
| tubes | the Cinder torpedo salvo (torp F, 1 shot): the destroyer's reason to exist (designs.md: the torpedo bow) | launcher | twin torpedo tubes in raised deck cowls, one each side of the centreline | 2 | bow/top, bow/side | a tube house standing on the deck, a square riveted surround, a heavy forged collar with a rolled lip, a deep dark bore, the next torpedo's nose inside (R221) | picture |
| magazine_vents | the torpedo magazine sheds its reload heat (designs.md: ember heat-vent slits; data.js ability reload) | vent | three louvres on each upper facet over the magazine (the round 2 beauty's ember slits on the magazine section) | 6 | bow/top, bow/side, mid/top | a forged frame, slanted slats over an ember-lit recess | picture |
| blade | carries everything: the magazine, the crew deck, the reactor and the drives | hull | the faceted hull: a crowned deck, upper facets out to the knuckle, the vertical broadside band, lower facets, a flat worked belly | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | angled facets and chamfers (never a flat wall, R244), the knuckle line, a deck-edge chamfer, a chine | picture |
| deck_plates | deck armour over the magazine and the crew deck | plate | ordered rows of forged plates over the deck | 1 | bow/top, mid/top, stern/top | slabs with bevels, reinforcing steps and rivet lines | picture |
| flank_plates | side armour: the facets and the broadside band | plate | ordered rows of forged plates over the facets and the band | 1 | bow/side, mid/side, stern/side | slabs with bevels, reinforcing steps and rivet lines | picture |
| belly_plates | belly armour | plate | forged plates over the belly and the armour step | 1 | bow/below, mid/below, stern/below | slabs with bevels, reinforcing steps and rivet lines | designed |
| trunk | the dorsal power trunk: the reactor's feed forward to the turrets and the tube room | spine | a banded armoured ridge along the centreline from the spine block's face to the tube cowls (the concept's centre stripe) | 1 | bow/top, mid/top | a stepped block with bands across it | picture |
| gun_deck | the hull's belt: armoured shelves over and under the plated band | belt | the broadside band with its upper and lower lips, both flanks | 1 | bow/side, mid/side, stern/side | a band along the hull with angled ends, plates on it | picture |
| band_louvres | the gallery spaces behind the band breathe out here | vent | small louvres in the plated band (the round 2 sheet's small ember slits along the flank) | 10 | bow/side, mid/side, stern/side | a forged frame, slanted slats over an ember-lit recess | picture |
| turrets | the sear turret (turret T, 2 shots): the destroyer's guns against escorts | gun | one pair of single-emitter turrets on low tubs at the deck edges, station 46 percent | 2 | mid/top, mid/side | a riveted ring, a faceted forged dome, a block mantlet, one heavy emitter with cooling rings, an ember lens, a radiator bustle (R221) | picture |
| barbettes | the turrets' footing at the deck edges | tier | two octagonal forged tubs | 2 | mid/top, mid/side | a skirt down the facet, a flat roof, the turret ring in it | picture |
| hatches | crew and stores access: deck hatches and belly hatches | hatch | forged round hatches on the deck and the belly step | 6 | bow/top, mid/top, mid/below | a studded rim, a door with a bar, a seam, hinges | designed |
| spine | the spire line's base: it carries the spires and the command deck's windows, and snaps off with the spires (B-3) | spine | the forged spine block along the centreline aft, its forward face | 1 | stern/top, stern/side, mid/top | a chamfered block, a stepped face, the window slits | picture |
| spine_plates | armour over the spine block | plate | forged plates over the spine block | 1 | stern/top, stern/side | slabs with bevels, reinforcing steps and rivet lines | designed |
| bridge_slits | the command deck's windows | slit | three ember slits in the spine block's forward face | 3 | mid/top, stern/top | a forged frame round a recessed ember pane, a brow | picture |
| spires | shed the reactor's heat: the ember radiator spires | radiator | four radiator spires along the spine at 66 to 87 percent, tallest 0.85 (the final table), four profiles | 4 | stern/top, stern/side, mid/top | a forged root socket, iron posts fore and aft, iron fins out to each side with the ember core glowing between them, a forged cap, gusset braces | picture |
| vents | reactor heat louvres over the reactor room | vent | heat louvres on the upper facets aft | 4 | stern/side, stern/top | a forged frame, slanted slats over an ember-lit recess | designed |
| engines | drive (sp 4): two ember bells, deep-set | engine | two engine bells, 0.8 across, offsets 0.55, on riveted drums | 2 | stern/top, stern/side, stern/below | a drum of forged plate courses, riveted bands, a mount collar, struts, a deep bell with stiffener rings and a rolled lip, an ember lining, a hot throat, a glowing plug cone | picture |
| thrusters | attitude control at the bow and the stern (tn 2) | thruster | attitude thrusters on the upper facets fore and aft | 4 | bow/side, stern/side | a forged block, round nozzle throats with depth (R244) | designed |
| lamps | frost-white running points on the blade's edge (paint direction sunward.md 5) | lamp | small frost lamps along the knuckle forward and the deck edge aft | 12 | bow/side, mid/side, stern/side | a low housing, a hood, a round lens | designed |

Kit sub-parts per type (what DETAILED checks):

- belt: band, plate
- engine: housing, band, collar, bell, lining, throat, plug, bellring
- gun: ring|port, mantlet, barrel, jacket, muzzle, bore
- hatch: rim, door, seam, hinge
- hull: facet, step, chamfer
- lamp: housing, lens
- launcher: housing, surround, collar, bore, nose
- plate: slab, step, bevel, rivet
- radiator: root, column, cap, fin, bar, brace
- slit: frame, glass
- spine: block, step, slit
- thruster: block, nozzle
- tier: face, roof, opening
- vent: frame, slat

Left as surface, and why:

- Frost-white markings (one thin stripe, a small sigil), soot and wear: surface texture, painted by the Sunward paint stack (stage 5), not modelled.
- The fifth spire the round 2 pictures draw: designs.md tables four.

## Every built part has a job (R221)

Built kit parts: 73; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, voidsworn_S11_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spearhead | the forged point: one long leaf taper to a point at mid height, diamon | 1 / 1 | Y | Y | Y |
| tube_cowls | two tube cowls on the deck at about 22 percent, their mouths forward,  | 1 / 1 | Y | Y | Y |
| tubes | twin torpedo tubes in raised deck cowls, one each side of the centreli | 1 / 2 | n | Y | Y | both tubes are built, as ONE launcher part with two bores (T1): data.js gives the Harrow one torp slot of 1 shot, and weapon_match fails a pair of mounts on a 1-shot slot (SPLIT), so the two tubes are one mount that fires every volley
| magazine_vents | three louvres on each upper facet over the magazine | 6 / 6 | Y | Y | Y |
| blade | the faceted hull: a crowned deck, upper facets out to the knuckle, the | 1 / 1 | Y | Y | Y |
| deck_plates | ordered rows of forged plates over the deck | 2 / 1 | Y | Y | Y |
| trunk | a banded armoured ridge along the centreline from the spine block's fa | 1 / 1 | Y | Y | Y |
| hatches | forged round hatches on the deck and the belly step | 6 / 6 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spearhead | the forged point: one long leaf taper to a point at mid height, diamon | 1 / 1 | Y | Y | Y |
| tube_cowls | two tube cowls on the deck at about 22 percent, their mouths forward,  | 1 / 1 | Y | Y | Y |
| tubes | twin torpedo tubes in raised deck cowls, one each side of the centreli | 1 / 2 | n | Y | Y | both tubes are built, as ONE launcher part with two bores (T1): data.js gives the Harrow one torp slot of 1 shot, and weapon_match fails a pair of mounts on a 1-shot slot (SPLIT), so the two tubes are one mount that fires every volley
| magazine_vents | three louvres on each upper facet over the magazine | 6 / 6 | Y | Y | Y |
| blade | the faceted hull: a crowned deck, upper facets out to the knuckle, the | 1 / 1 | Y | Y | Y |
| flank_plates | ordered rows of forged plates over the facets and the band | 6 / 1 | Y | Y | Y |
| gun_deck | the broadside band with its upper and lower lips, both flanks | 1 / 1 | Y | Y | Y |
| band_louvres | small louvres in the plated band | 10 / 10 | Y | Y | Y |
| thrusters | attitude thrusters on the upper facets fore and aft | 4 / 4 | Y | Y | Y |
| lamps | small frost lamps along the knuckle forward and the deck edge aft | 12 / 12 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spearhead | the forged point: one long leaf taper to a point at mid height, diamon | 1 / 1 | Y | Y | Y |
| blade | the faceted hull: a crowned deck, upper facets out to the knuckle, the | 1 / 1 | Y | Y | Y |
| belly_plates | forged plates over the belly and the armour step | 3 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| magazine_vents | three louvres on each upper facet over the magazine | 6 / 6 | Y | Y | Y |
| blade | the faceted hull: a crowned deck, upper facets out to the knuckle, the | 1 / 1 | Y | Y | Y |
| deck_plates | ordered rows of forged plates over the deck | 2 / 1 | Y | Y | Y |
| trunk | a banded armoured ridge along the centreline from the spine block's fa | 1 / 1 | Y | Y | Y |
| turrets | one pair of single-emitter turrets on low tubs at the deck edges, stat | 2 / 2 | Y | Y | Y |
| barbettes | two octagonal forged tubs | 1 / 2 | Y | Y | Y |
| hatches | forged round hatches on the deck and the belly step | 6 / 6 | Y | Y | Y |
| spine | the forged spine block along the centreline aft, its forward face | 1 / 1 | Y | Y | Y |
| bridge_slits | three ember slits in the spine block's forward face | 3 / 3 | Y | Y | Y |
| spires | four radiator spires along the spine at 66 to 87 percent, tallest 0.85 | 4 / 4 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the faceted hull: a crowned deck, upper facets out to the knuckle, the | 1 / 1 | Y | Y | Y |
| flank_plates | ordered rows of forged plates over the facets and the band | 6 / 1 | Y | Y | Y |
| gun_deck | the broadside band with its upper and lower lips, both flanks | 1 / 1 | Y | Y | Y |
| band_louvres | small louvres in the plated band | 10 / 10 | Y | Y | Y |
| turrets | one pair of single-emitter turrets on low tubs at the deck edges, stat | 2 / 2 | Y | Y | Y |
| barbettes | two octagonal forged tubs | 1 / 2 | Y | Y | Y |
| lamps | small frost lamps along the knuckle forward and the deck edge aft | 12 / 12 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the faceted hull: a crowned deck, upper facets out to the knuckle, the | 1 / 1 | Y | Y | Y |
| belly_plates | forged plates over the belly and the armour step | 3 / 1 | Y | Y | Y |
| hatches | forged round hatches on the deck and the belly step | 6 / 6 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the faceted hull: a crowned deck, upper facets out to the knuckle, the | 1 / 1 | Y | Y | Y |
| deck_plates | ordered rows of forged plates over the deck | 2 / 1 | Y | Y | Y |
| spine | the forged spine block along the centreline aft, its forward face | 1 / 1 | Y | Y | Y |
| spine_plates | forged plates over the spine block | 1 / 1 | Y | Y | Y |
| bridge_slits | three ember slits in the spine block's forward face | 3 / 3 | Y | Y | Y |
| spires | four radiator spires along the spine at 66 to 87 percent, tallest 0.85 | 4 / 4 | Y | Y | Y |
| vents | heat louvres on the upper facets aft | 4 / 4 | Y | Y | Y |
| engines | two engine bells, 0.8 across, offsets 0.55, on riveted drums | 2 / 2 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the faceted hull: a crowned deck, upper facets out to the knuckle, the | 1 / 1 | Y | Y | Y |
| flank_plates | ordered rows of forged plates over the facets and the band | 6 / 1 | Y | Y | Y |
| gun_deck | the broadside band with its upper and lower lips, both flanks | 1 / 1 | Y | Y | Y |
| band_louvres | small louvres in the plated band | 10 / 10 | Y | Y | Y |
| spine | the forged spine block along the centreline aft, its forward face | 1 / 1 | Y | Y | Y |
| spine_plates | forged plates over the spine block | 1 / 1 | Y | Y | Y |
| spires | four radiator spires along the spine at 66 to 87 percent, tallest 0.85 | 4 / 4 | Y | Y | Y |
| vents | heat louvres on the upper facets aft | 4 / 4 | Y | Y | Y |
| engines | two engine bells, 0.8 across, offsets 0.55, on riveted drums | 2 / 2 | Y | Y | Y |
| thrusters | attitude thrusters on the upper facets fore and aft | 4 / 4 | Y | Y | Y |
| lamps | small frost lamps along the knuckle forward and the deck edge aft | 12 / 12 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the faceted hull: a crowned deck, upper facets out to the knuckle, the | 1 / 1 | Y | Y | Y |
| belly_plates | forged plates over the belly and the armour step | 3 / 1 | Y | Y | Y |
| engines | two engine bells, 0.8 across, offsets 0.55, on riveted drums | 2 / 2 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (Harrow round 2 sheet: bow, the spearhead, its ridge and the two tube mouths; midships, the body, the centre stripe and the turret pair; stern, the body, the spine block, the spires, the two drums and bells); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 4 | 8 | Hull: the blade; Bow ridge; Band upper lip, port; Band lower lip, port; Band upper lip, starboard; Band lower lip, starboard; Belly armour step; Dorsal power trunk |
| bow/side | 3 | 6 | Hull: the blade; Bow ridge; Band upper lip, port; Band lower lip, port; Belly armour step; Dorsal power trunk |
| bow/below | no view | 8 | Hull: the blade; Bow ridge; Band upper lip, port; Band lower lip, port; Band upper lip, starboard; Band lower lip, starboard; Belly armour step; Dorsal power trunk |
| mid/top | 4 | 11 | Hull: the blade; Band upper lip, port; Band lower lip, port; Band upper lip, starboard; Band lower lip, starboard; Turret tub, port; Turret tub, starboard; Spine block (the spire line's base); Radiator spire R1 (raked, 0.66 tall); Belly arm |
| mid/side | 4 | 8 | Hull: the blade; Band upper lip, port; Band lower lip, port; Turret tub, port; Spine block (the spire line's base); Radiator spire R1 (raked, 0.66 tall); Belly armour step; Dorsal power trunk |
| mid/below | no view | 9 | Hull: the blade; Band upper lip, port; Band lower lip, port; Band upper lip, starboard; Band lower lip, starboard; Turret tub, port; Turret tub, starboard; Belly armour step; Dorsal power trunk |
| stern/top | 6 | 11 | Hull: the blade; Band upper lip, port; Band lower lip, port; Band upper lip, starboard; Band lower lip, starboard; Spine block (the spire line's base); Radiator spire R1 (raked, 0.66 tall); Radiator spire R2 (stepped, 0.85 tall); Radiator s |
| stern/side | 7 | 8 | Hull: the blade; Band upper lip, port; Band lower lip, port; Spine block (the spire line's base); Radiator spire R1 (raked, 0.66 tall); Radiator spire R2 (stepped, 0.85 tall); Radiator spire R3 (blade, 0.76 tall); Belly armour step |
| stern/below | no view | 6 | Hull: the blade; Band upper lip, port; Band lower lip, port; Band upper lip, starboard; Band lower lip, starboard; Belly armour step |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 4.47 | 6.64 | 5.20 | 13.02 |
| build | 4.29 | 4.69 | 4.88 | 8.64 |

Lines not present, shaped and detailed without a reason: 0.
