# voidsworn_S10 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/voidsworn/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/voidsworn_S10_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| spearhead | the blade's point and its forward armour, carrying the lance | hull | the forged spearhead: one point at mid height, diamond in section, its facets running back into the hull and forward into the lance collar | 1 | bow/top, bow/side, bow/below | the upper and lower facets meeting at the knuckle, a crowned deck, a chamfered deck edge, the centre ridge | picture |
| lance | the Oath lance (lance F, 1 shot, 20 damage, range 7): the cruiser's signature weapon | lance | one emitter in the spearhead's point (designs.md: "single emitter set in the spearhead face, station 4 percent") (the beauty draws a big glowing disc between fork tines; the table and the Board's brief: one emitter in the point, never a big disc) | 1 | bow/top, bow/side | breech collars, a banded capacitor housing, a diamond muzzle collar, a rolled lip, a deep dark bore, focusing rings, a small ember lens | picture |
| trunk | the dorsal ridge: the lance's power trunk to station 30 percent, then the reactor feeds on to the spire block | spine | a raised armoured ridge along the centreline from the lance to the spine block (the concept's strongest line) | 1 | bow/top, bow/side, mid/top | a stepped block with bands across it | picture |
| trunk_plates | armour over the dorsal ridge | plate | forged plates over the ridge's faces | 1 | bow/top, mid/top | slabs with bevels, reinforcing steps and rivet lines | picture |
| bow_plates | armour over the spearhead and the cheek housings: forged plates in sleek triangles (R243) | plate | the cheek housings' and bow facets' plating | 1 | bow/top, bow/side | slabs with bevels, reinforcing steps and rivet lines | picture |
| cheek_vents | the capacitor banks shed their charge heat | vent | three small louvres on each cheek housing (the beauty's ember slits along the bow facets) | 6 | bow/top, bow/side | a forged frame, slanted slats over an ember-lit recess | picture |
| blade | carries everything: the gun deck, the galleries, the reactor and the drives | hull | the long faceted hull: a crowned deck, upper facets out to the knuckle, the vertical broadside band, lower facets, a flat worked belly; widest at the stern third | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | angled facets and chamfers (never a flat wall, R244), the knuckle line, a deck-edge chamfer, a chine | picture |
| deck_plates | deck armour over the galleries | plate | ordered rows of forged plates over the deck | 1 | bow/top, mid/top, stern/top | slabs with bevels, reinforcing steps and rivet lines | picture |
| flank_plates | side armour: the facets and the broadside band | plate | ordered rows of forged plates over the facets and the band | 1 | bow/side, mid/side, stern/side | slabs with bevels, reinforcing steps and rivet lines | picture |
| belly_plates | belly armour | plate | forged plates over the belly and the armour step | 1 | bow/below, mid/below, stern/below | slabs with bevels, reinforcing steps and rivet lines | designed |
| gun_deck | the old manual gun deck: armoured shelves over and under the ports | belt | the broadside band with its upper and lower lips, both flanks | 1 | mid/side, mid/top | a band along the hull with angled ends, plates on it | picture |
| broadside | the Sear battery (battery P and battery S, 4 shots each): the cruiser's broadside | gun | guns in deep round ports, four a side at 38 / 47 / 56 / 65 percent (data.js battery P, battery S) | 8 | mid/side, mid/top | a square riveted surround, a deep round port collar with a rolled lip, a dark throat, a ball mantlet, a finned heat jacket, a barrel, a flared muzzle, an ember bore (R221) | picture |
| gallery_slits | the gun galleries' vision slits | slit | ember slits in the band between two pairs of ports (the sheet's ember gallery slits between the ports) | 4 | mid/side | a forged frame round a recessed ember pane, a brow | picture |
| hatches | crew and stores access: deck hatches and belly hatches | hatch | forged round hatches on the deck and the belly step | 8 | bow/top, mid/top, mid/below, stern/below | a studded rim, a door with a bar, a seam, hinges | designed |
| lift_heads | the hoist head over the gun deck: shells up from the shell rooms | hatchbox | a low armoured deck housing on the centreline | 1 | mid/top | a chamfered frame, an inset lid with a stacked plate, side ribs | designed |
| spine | the spire line's base: it carries the spires and the command deck's windows, and snaps off with the spires (B-4) | spine | the forged spine block along the centreline aft, its forward face | 1 | stern/top, stern/side, mid/top | a chamfered block, a stepped face, the window slits | picture |
| spine_plates | armour over the spine block | plate | forged plates over the spine block | 1 | stern/top, stern/side | slabs with bevels, reinforcing steps and rivet lines | designed |
| bridge_slits | the command deck's windows (designs.md: ember slits in the spine block face, station 60 percent) | slit | three ember slits in the spine block's forward face | 3 | mid/top, stern/top | a forged frame round a recessed ember pane, a brow | picture |
| spires | shed the reactor's heat: the ember radiator spires | radiator | five radiator spires along the spine at 64 to 88 percent, tallest (1.2, R331: 70 percent of the table's 1.7) in the middle, four profiles | 5 | stern/top, stern/side, mid/top | a forged root socket, iron posts fore and aft, iron fins out to each side with the ember core glowing between them, a forged cap, gusset braces | picture |
| vents | reactor heat louvres over the reactor room | vent | heat louvres on the upper facets aft | 6 | stern/side, stern/top | a forged frame, slanted slats over an ember-lit recess | designed |
| engines | drive (sp 3): two ember bells, deep-set | engine | two engine bells, 1.2 across, offsets 0.8, on riveted drums | 2 | stern/top, stern/side, stern/below | a drum of forged plate courses, riveted bands, a mount collar, struts, a deep bell with stiffener rings and a rolled lip, an ember lining, a hot throat, a glowing plug cone | picture |
| thrusters | attitude control at the bow and the stern (tn 2) | thruster | attitude thrusters, two forward on the lower facets and two aft on the upper facets | 4 | bow/side, stern/side | a forged block, round nozzle throats with depth (R244) | designed |
| lamps | frost-white running points on the blade's edge (paint direction sunward.md 5) | lamp | small frost lamps along the knuckle forward and the deck edge aft | 14 | bow/side, mid/side, stern/side | a low housing, a hood, a round lens | designed |

Kit sub-parts per type (what DETAILED checks):

- belt: band, plate
- engine: housing, band, collar, bell, lining, throat, plug, bellring
- gun: ring|port, mantlet, barrel, jacket, muzzle, bore
- hatch: rim, door, seam, hinge
- hatchbox: frame, lid, rib
- hull: facet, step, chamfer
- lamp: housing, lens
- lance: breech, housing, band, collar, lip, bore, focus, lens
- plate: slab, step, bevel, rivet
- radiator: root, column, cap, fin, bar, brace
- slit: frame, glass
- spine: block, step, slit
- thruster: block, nozzle
- vent: frame, slat

Left as surface, and why:

- Frost-white markings, the half-sun crest, soot and wear: surface texture, painted by the Sunward paint stack, not modelled.
- The flame plumes the sheet draws at the bells: in game the bells glow ember and the game draws the plume.

## Every built part has a job (R221)

Built kit parts: 78; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, voidsworn_S10_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spearhead | the forged spearhead: one point at mid height, diamond in section, its | 1 / 1 | Y | Y | Y |
| lance | one emitter in the spearhead's point (designs.md: "single emitter set  | 1 / 1 | Y | Y | Y |
| trunk | a raised armoured ridge along the centreline from the lance to the spi | 1 / 1 | Y | Y | Y |
| trunk_plates | forged plates over the ridge's faces | 1 / 1 | Y | Y | Y |
| bow_plates | the cheek housings' and bow facets' plating | 2 / 1 | Y | Y | Y |
| cheek_vents | three small louvres on each cheek housing | 6 / 6 | Y | Y | Y |
| blade | the long faceted hull: a crowned deck, upper facets out to the knuckle | 1 / 1 | Y | Y | Y |
| deck_plates | ordered rows of forged plates over the deck | 1 / 1 | Y | Y | Y |
| hatches | forged round hatches on the deck and the belly step | 8 / 8 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spearhead | the forged spearhead: one point at mid height, diamond in section, its | 1 / 1 | Y | Y | Y |
| lance | one emitter in the spearhead's point (designs.md: "single emitter set  | 1 / 1 | Y | Y | Y |
| trunk | a raised armoured ridge along the centreline from the lance to the spi | 1 / 1 | Y | Y | Y |
| bow_plates | the cheek housings' and bow facets' plating | 2 / 1 | Y | Y | Y |
| cheek_vents | three small louvres on each cheek housing | 6 / 6 | Y | Y | Y |
| blade | the long faceted hull: a crowned deck, upper facets out to the knuckle | 1 / 1 | Y | Y | Y |
| flank_plates | ordered rows of forged plates over the facets and the band | 4 / 1 | Y | Y | Y |
| thrusters | attitude thrusters, two forward on the lower facets and two aft on the | 4 / 4 | Y | Y | Y |
| lamps | small frost lamps along the knuckle forward and the deck edge aft | 14 / 14 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spearhead | the forged spearhead: one point at mid height, diamond in section, its | 1 / 1 | Y | Y | Y |
| blade | the long faceted hull: a crowned deck, upper facets out to the knuckle | 1 / 1 | Y | Y | Y |
| belly_plates | forged plates over the belly and the armour step | 2 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| trunk | a raised armoured ridge along the centreline from the lance to the spi | 1 / 1 | Y | Y | Y |
| trunk_plates | forged plates over the ridge's faces | 1 / 1 | Y | Y | Y |
| blade | the long faceted hull: a crowned deck, upper facets out to the knuckle | 1 / 1 | Y | Y | Y |
| deck_plates | ordered rows of forged plates over the deck | 1 / 1 | Y | Y | Y |
| gun_deck | the broadside band with its upper and lower lips, both flanks | 1 / 1 | Y | Y | Y |
| broadside | guns in deep round ports, four a side at 38 / 47 / 56 / 65 percent (da | 8 / 8 | Y | Y | Y |
| hatches | forged round hatches on the deck and the belly step | 8 / 8 | Y | Y | Y |
| lift_heads | a low armoured deck housing on the centreline | 1 / 1 | Y | Y | Y |
| spine | the forged spine block along the centreline aft, its forward face | 1 / 1 | Y | Y | Y |
| bridge_slits | three ember slits in the spine block's forward face | 3 / 3 | Y | Y | Y |
| spires | five radiator spires along the spine at 64 to 88 percent, tallest (1.2 | 5 / 5 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the long faceted hull: a crowned deck, upper facets out to the knuckle | 1 / 1 | Y | Y | Y |
| flank_plates | ordered rows of forged plates over the facets and the band | 4 / 1 | Y | Y | Y |
| gun_deck | the broadside band with its upper and lower lips, both flanks | 1 / 1 | Y | Y | Y |
| broadside | guns in deep round ports, four a side at 38 / 47 / 56 / 65 percent (da | 8 / 8 | Y | Y | Y |
| gallery_slits | ember slits in the band between two pairs of ports | 4 / 4 | Y | Y | Y |
| lamps | small frost lamps along the knuckle forward and the deck edge aft | 14 / 14 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the long faceted hull: a crowned deck, upper facets out to the knuckle | 1 / 1 | Y | Y | Y |
| belly_plates | forged plates over the belly and the armour step | 2 / 1 | Y | Y | Y |
| hatches | forged round hatches on the deck and the belly step | 8 / 8 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the long faceted hull: a crowned deck, upper facets out to the knuckle | 1 / 1 | Y | Y | Y |
| deck_plates | ordered rows of forged plates over the deck | 1 / 1 | Y | Y | Y |
| spine | the forged spine block along the centreline aft, its forward face | 1 / 1 | Y | Y | Y |
| spine_plates | forged plates over the spine block | 1 / 1 | Y | Y | Y |
| bridge_slits | three ember slits in the spine block's forward face | 3 / 3 | Y | Y | Y |
| spires | five radiator spires along the spine at 64 to 88 percent, tallest (1.2 | 5 / 5 | Y | Y | Y |
| vents | heat louvres on the upper facets aft | 6 / 6 | Y | Y | Y |
| engines | two engine bells, 1.2 across, offsets 0.8, on riveted drums | 2 / 2 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the long faceted hull: a crowned deck, upper facets out to the knuckle | 1 / 1 | Y | Y | Y |
| flank_plates | ordered rows of forged plates over the facets and the band | 4 / 1 | Y | Y | Y |
| spine | the forged spine block along the centreline aft, its forward face | 1 / 1 | Y | Y | Y |
| spine_plates | forged plates over the spine block | 1 / 1 | Y | Y | Y |
| spires | five radiator spires along the spine at 64 to 88 percent, tallest (1.2 | 5 / 5 | Y | Y | Y |
| vents | heat louvres on the upper facets aft | 6 / 6 | Y | Y | Y |
| engines | two engine bells, 1.2 across, offsets 0.8, on riveted drums | 2 / 2 | Y | Y | Y |
| thrusters | attitude thrusters, two forward on the lower facets and two aft on the | 4 / 4 | Y | Y | Y |
| lamps | small frost lamps along the knuckle forward and the deck edge aft | 14 / 14 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | the long faceted hull: a crowned deck, upper facets out to the knuckle | 1 / 1 | Y | Y | Y |
| belly_plates | forged plates over the belly and the armour step | 2 / 1 | Y | Y | Y |
| hatches | forged round hatches on the deck and the belly step | 8 / 8 | Y | Y | Y |
| engines | two engine bells, 1.2 across, offsets 0.8, on riveted drums | 2 / 2 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (Vigil sheet: bow, the spearhead, the centre ridge and the lance; midships, the body, the two gun rows and the centre ridge; stern, the body, the spine block, the spires, the two drums and bells); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 3 | 9 | Hull: the blade; Dorsal ridge (the lance power trunk forward); Lance capacitor housing, port; Lance capacitor housing, starboard; Gun deck upper lip, port; Gun deck lower lip, port; Gun deck upper lip, starboard; Gun deck lower lip, starboa |
| bow/side | 2 | 6 | Hull: the blade; Dorsal ridge (the lance power trunk forward); Lance capacitor housing, port; Gun deck upper lip, port; Gun deck lower lip, port; Belly armour step |
| bow/below | no view | 4 | Hull: the blade; Gun deck lower lip, port; Gun deck lower lip, starboard; Belly armour step |
| mid/top | 4 | 9 | Hull: the blade; Dorsal ridge (the lance power trunk forward); Gun deck upper lip, port; Gun deck lower lip, port; Gun deck upper lip, starboard; Gun deck lower lip, starboard; Spine block (the spire line's base); Radiator spire R1 (blade,  |
| mid/side | 4 | 7 | Hull: the blade; Dorsal ridge (the lance power trunk forward); Gun deck upper lip, port; Gun deck lower lip, port; Spine block (the spire line's base); Radiator spire R1 (blade, 0.80 tall); Belly armour step |
| mid/below | no view | 4 | Hull: the blade; Gun deck lower lip, port; Gun deck lower lip, starboard; Belly armour step |
| stern/top | 6 | 12 | Hull: the blade; Gun deck upper lip, port; Gun deck lower lip, port; Gun deck upper lip, starboard; Gun deck lower lip, starboard; Spine block (the spire line's base); Radiator spire R1 (blade, 0.80 tall); Radiator spire R2 (raked, 1.02 tal |
| stern/side | 7 | 9 | Hull: the blade; Gun deck upper lip, port; Gun deck lower lip, port; Spine block (the spire line's base); Radiator spire R1 (blade, 0.80 tall); Radiator spire R2 (raked, 1.02 tall); Radiator spire R4 (stepped, 1.00 tall); Radiator spire R5  |
| stern/below | no view | 4 | Hull: the blade; Gun deck lower lip, port; Gun deck lower lip, starboard; Belly armour step |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 4.63 | 4.07 | 8.23 | 7.29 |
| build | 3.28 | 4.11 | 4.90 | 6.94 |

Lines not present, shaped and detailed without a reason: 0.
