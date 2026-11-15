# voidsworn_SB4 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/voidsworn/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/voidsworn_SB4_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| bomb_cassette | the bomb payload (data.js bombs T, 2 shots): the wing's only weapon, the bomber's bow face | bomb_tube | a deep armoured cassette with two big tube mouths, heavy shaped rims, the next bomb seated in each bore, the bombardier's sight slit between (the concept's two bow mouths on a traverse cassette) | 1 | bow/top, bow/side | a front plate with two round mouths, a housing round the bores, dark bores with a bomb nose deep inside, twelve-sided rims with forged lugs and studs, the sight slit (R221, R244) | picture |
| block | the craft's one body, built round the bomb magazine: the hull IS the magazine | hull | one massive faceted block: deck, deck chamfers, the vertical flank band, lower chamfers, a flat belly; the bow face set back for the cassette | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | angled chamfers round the flank band (never a flat wall, R244), a stepped bow face | picture |
| block_plates | armour over the block | plate | forged plates over the deck, the chamfers, the band and the belly, sleek triangles on the deck chamfers (R243) | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | slabs with bevels, reinforcing steps and rivet lines | picture |
| ridges | armoured roofs over the two bomb rows, one row feeding each tube | spine | two raised armour ridges along the deck, chamfered, their ends tapered (the concept's two raised dorsal blocks) | 2 | bow/top, mid/top, stern/top, mid/side | a chamfered block with stepped ends and plates on it | picture |
| ridge_plates | armour over the ridges | plate | forged plates over the ridges | 1 | mid/top, stern/top | slabs with bevels, reinforcing steps and rivet lines | picture |
| belts | a second forged layer over each flank where the bomb rows lie | belt | a raised armour belt along each flank band, its ends angled (the concept's heavy flank armour panels) | 2 | mid/side, bow/side, stern/side | a band along the hull with angled ends, plates on it | picture |
| belt_plates | armour over the belts | plate | forged plates over the belts | 1 | mid/side | slabs with bevels, reinforcing steps and rivet lines | picture |
| drives | drive (sp 5): four deep bells, nozzle clusters inside armoured blocks (the owner's rule for craft) | engine | two pairs of deep bells sunk in eight-sided armoured cowls in the stern face (the concept's ember bell clusters in the stern faces) | 4 | stern/top, stern/side, stern/below | an eight-sided cowl with a riveted face, a band and a collar, the bell sunk in it with a lip and a stiffener ring, an ember lining, a hot throat, a glowing plug cone | picture |
| louvres | the drive room's heat louvres | vent | one heat louvre on the aft end of each ridge (the concept's ember roof slits) | 2 | stern/top | a forged frame, slanted slats over an ember-lit recess | picture |

Kit sub-parts per type (what DETAILED checks):

- belt: band, plate
- bomb_tube: (hull shaping, checked by eye on the side-by-side)
- engine: housing, band, collar, bell, lining, throat, plug, bellring
- hull: facet, step, chamfer
- plate: slab, step, bevel, rivet
- spine: block, step, slit
- vent: frame, slat

Left as surface, and why:

- The frost-white oath band across one shoulder, the ember trim lines and wear: paint, by the Sunward paint stack (issue 756, applied later), not modelled.
- The concept's small panels, grilles and boxes on the flanks: fine greeble that reads as a shrunken capital ship at this size (production notes); the belts and plates carry the flanks.
- Hatches, lamps and attitude thrusters: below what the battle camera shows on a 3.84 unit craft, and the drives turn it; not built.

## Every built part has a job (R221)

Built kit parts: 21; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, voidsworn_SB4_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| bomb_cassette | a deep armoured cassette with two big tube mouths, heavy shaped rims,  | 1 / 1 | Y | Y | Y |
| block | one massive faceted block: deck, deck chamfers, the vertical flank ban | 1 / 1 | Y | Y | Y |
| block_plates | forged plates over the deck, the chamfers, the band and the belly, sle | 5 / 1 | Y | Y | Y |
| ridges | two raised armour ridges along the deck, chamfered, their ends tapered | 2 / 2 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| bomb_cassette | a deep armoured cassette with two big tube mouths, heavy shaped rims,  | 1 / 1 | Y | Y | Y |
| block | one massive faceted block: deck, deck chamfers, the vertical flank ban | 1 / 1 | Y | Y | Y |
| block_plates | forged plates over the deck, the chamfers, the band and the belly, sle | 5 / 1 | Y | Y | Y |
| belts | a raised armour belt along each flank band, its ends angled | 2 / 2 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| block | one massive faceted block: deck, deck chamfers, the vertical flank ban | 1 / 1 | Y | Y | Y |
| block_plates | forged plates over the deck, the chamfers, the band and the belly, sle | 5 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| block | one massive faceted block: deck, deck chamfers, the vertical flank ban | 1 / 1 | Y | Y | Y |
| block_plates | forged plates over the deck, the chamfers, the band and the belly, sle | 5 / 1 | Y | Y | Y |
| ridges | two raised armour ridges along the deck, chamfered, their ends tapered | 2 / 2 | Y | Y | Y |
| ridge_plates | forged plates over the ridges | 2 / 1 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| block | one massive faceted block: deck, deck chamfers, the vertical flank ban | 1 / 1 | Y | Y | Y |
| block_plates | forged plates over the deck, the chamfers, the band and the belly, sle | 5 / 1 | Y | Y | Y |
| ridges | two raised armour ridges along the deck, chamfered, their ends tapered | 2 / 2 | Y | Y | Y |
| belts | a raised armour belt along each flank band, its ends angled | 2 / 2 | Y | Y | Y |
| belt_plates | forged plates over the belts | 2 / 1 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| block | one massive faceted block: deck, deck chamfers, the vertical flank ban | 1 / 1 | Y | Y | Y |
| block_plates | forged plates over the deck, the chamfers, the band and the belly, sle | 5 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| block | one massive faceted block: deck, deck chamfers, the vertical flank ban | 1 / 1 | Y | Y | Y |
| block_plates | forged plates over the deck, the chamfers, the band and the belly, sle | 5 / 1 | Y | Y | Y |
| ridges | two raised armour ridges along the deck, chamfered, their ends tapered | 2 / 2 | Y | Y | Y |
| ridge_plates | forged plates over the ridges | 2 / 1 | Y | Y | Y |
| drives | two pairs of deep bells sunk in eight-sided armoured cowls in the ster | 4 / 4 | Y | Y | Y |
| louvres | one heat louvre on the aft end of each ridge | 2 / 2 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| block | one massive faceted block: deck, deck chamfers, the vertical flank ban | 1 / 1 | Y | Y | Y |
| block_plates | forged plates over the deck, the chamfers, the band and the belly, sle | 5 / 1 | Y | Y | Y |
| belts | a raised armour belt along each flank band, its ends angled | 2 / 2 | Y | Y | Y |
| drives | two pairs of deep bells sunk in eight-sided armoured cowls in the ster | 4 / 4 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| block | one massive faceted block: deck, deck chamfers, the vertical flank ban | 1 / 1 | Y | Y | Y |
| block_plates | forged plates over the deck, the chamfers, the band and the belly, sle | 5 / 1 | Y | Y | Y |
| drives | two pairs of deep bells sunk in eight-sided armoured cowls in the ster | 4 / 4 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (SB4 beauty, by eye (no true views): bow, the block, the bow face and the two rims; midships, the block, the two ridges, the flank panels; stern, the block, the ridges, the drive pods and their glow); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 4 | 5 | Hull: the magazine block; Magazine ridge, port; Magazine ridge, starboard; Magazine belt, port; Magazine belt, starboard |
| bow/side | 3 | 3 | Hull: the magazine block; Magazine ridge, port; Magazine belt, port |
| bow/below | no view | 5 | Hull: the magazine block; Magazine ridge, port; Magazine ridge, starboard; Magazine belt, port; Magazine belt, starboard |
| mid/top | 5 | 5 | Hull: the magazine block; Magazine ridge, port; Magazine ridge, starboard; Magazine belt, port; Magazine belt, starboard |
| mid/side | 4 | 3 | Hull: the magazine block; Magazine ridge, port; Magazine belt, port |
| mid/below | no view | 5 | Hull: the magazine block; Magazine ridge, port; Magazine ridge, starboard; Magazine belt, port; Magazine belt, starboard |
| stern/top | 5 | 5 | Hull: the magazine block; Magazine ridge, port; Magazine ridge, starboard; Magazine belt, port; Magazine belt, starboard |
| stern/side | 4 | 3 | Hull: the magazine block; Magazine ridge, port; Magazine belt, port |
| stern/below | no view | 5 | Hull: the magazine block; Magazine ridge, port; Magazine ridge, starboard; Magazine belt, port; Magazine belt, starboard |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 1.59 | 1.59 | 2.22 | 2.22 |
| build | 1.87 | 3.22 | 1.88 | 3.31 |

Lines not present, shaped and detailed without a reason: 0.
