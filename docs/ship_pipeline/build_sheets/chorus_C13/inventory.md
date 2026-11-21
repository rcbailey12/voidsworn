# chorus_C13 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/chorus/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/chorus_C13_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| glands_f | the forward Spine volley (bioplasma F): the prow gland spits spine-laden bile ahead | throat | the prow spine gland: a puckered vent in the rounded nose bulb, short spines round it | 1 | bow/top, bow/side | a knoll, pucker folds and a lip round the vent, a sphincter, a ring of chitin teeth, a dark bore, the bile gland glowing at its back, short bone spines out of the knoll | picture |
| pore_fields | sense: it tastes the dark through pore fields (no eyes; lore 5.8) | pore | pore fields over the nose bulb and the upper flanks | 2 | bow/top, bow/side, mid/side | a raised rim round a sunk pit | picture |
| siphons | attitude: squirt to swing the bow and the stern | thruster | puckered jet siphons, a pair forward and a pair aft (the picture shows none) | 4 | bow/side, stern/side | a muscle collar, a puckered lip, a dark bore | designed |
| glands_t | the all-round Spine volley (bioplasma T): two dorsal glands spit every way, one muzzle each for the slot's two shots | throat | two dorsal spine glands at the crowns of knolls on the back, short spines round each | 2 | bow/top, mid/top, mid/side | a knoll, pucker folds and a lip round the vent, a sphincter, chitin teeth, a dark bore, the bile gland, bone spines | picture |
| spine_bed | regrowth of spent spines (regrow, regen 4): new spines grow here before they move to the glands | spine_bed | a knoll aft of the dorsal glands studded with growing spines | 1 | mid/top, mid/side, stern/top | a knoll, bone spines with knuckle tips and tissue collars, pores | picture |
| knolls | the body's muscle and fat: lumps of grown flesh that carry the glands' spine sacs and soak hits | knoll | lumps of flesh over the back and shoulders | 1 | bow/top, mid/top, mid/side, stern/top | a lumpy dome, wrinkle rolls round its foot, pores | picture |
| scars | regrowth (regen 4): ragged regrown hide on the shoulders and flanks | scar | scarred patches on the shoulders and flanks | 6 | bow/top, mid/top, mid/side | a raised irregular patch, knit ridges across it | picture |
| bile_sacs | bile reservoirs: store the bile the glands spit; they swell before a volley | sac | four round sacs a side along the lower flanks, at uneven sizes | 8 | bow/side, mid/side, mid/below, stern/side | a socket of wrinkle rolls, the dome, creases, veins, glow windows | picture |
| hanging_sacs | the deep bile reserve under the belly | sac | three sacs hanging under the belly | 3 | bow/below, mid/below, mid/side | a socket, the hanging sac, creases, veins, glow | picture |
| veins | carry bile from the sacs forward and up to the glands | vein | vein runs from the sacs to the glands (the picture shows the hide's grain; the veins say what the sacs are for) | 2 | bow/side, mid/side | a raised vein, branches | designed |
| skin_folds | the body's muscle: it flexes the hull to turn and to squeeze the sacs | welt | wrinkle folds swept back from the nose and wrapping the knolls | 1 | bow/side, mid/side, stern/side, bow/below, mid/below | raised welts | picture |
| body | the body: holds the organs, the heart vat and the spine sacs | hull | the broad lumpy body: rounded nose bulb, broad in the middle, short at the tail | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | skin folds, pore fields, scars | picture |
| hide | the hide: callused pads with sense pores, the first thing a hit tears | plate | the hide over the whole body | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | callus pads, sense pores on them | picture |
| vents | drive (sp 4): three pulse vents push the body; no nozzles (factions.md) | engine | three glowing vents at the short stern with ragged trailing membranes | 3 | stern/top, stern/side, stern/below | a muscle cone, radial folds, a sphincter mouth, a dark throat, bile glow, membrane veils | picture |

Kit sub-parts per type (what DETAILED checks):

- engine: root, fold, sphincter, throat, glow, membrane|filament
- hull: ridge, fold, pore
- knoll: dome, roll, pore
- plate: pad, pore
- pore: rim, pit
- sac: root, sac, crease, vein, glow
- scar: patch, knit
- spine_bed: knoll, spine, knollp
- throat: root, fold|lip, sphincter, tooth, bore, gland
- thruster: collar, lip, bore
- vein: vein, branch
- welt: welt

Left as surface, and why:

- Fine wrinkle grain, wet sheen, mottling and the colour of the hide: surface texture and paint (recipe stages 4 and 5), not modelled.
- The long quills at the stern quarter and under the stern are cut: they have no job (R221) and would sit in the vents' wash.
- The torn membrane flecks floating behind the stern in the pictures are an effect, not part of the hull.

## Every built part has a job (R221)

Built kit parts: 36; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, chorus_C13_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| glands_f | the prow spine gland: a puckered vent in the rounded nose bulb, short  | 1 / 1 | Y | Y | Y |
| pore_fields | pore fields over the nose bulb and the upper flanks | 2 / 2 | Y | Y | Y |
| glands_t | two dorsal spine glands at the crowns of knolls on the back, short spi | 2 / 2 | Y | Y | Y |
| knolls | lumps of flesh over the back and shoulders | 1 / 1 | Y | Y | Y |
| scars | scarred patches on the shoulders and flanks | 6 / 6 | Y | Y | Y |
| body | the broad lumpy body: rounded nose bulb, broad in the middle, short at | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| glands_f | the prow spine gland: a puckered vent in the rounded nose bulb, short  | 1 / 1 | Y | Y | Y |
| pore_fields | pore fields over the nose bulb and the upper flanks | 2 / 2 | Y | Y | Y |
| siphons | puckered jet siphons, a pair forward and a pair aft | 4 / 4 | Y | Y | Y |
| bile_sacs | four round sacs a side along the lower flanks, at uneven sizes | 8 / 8 | Y | Y | Y |
| veins | vein runs from the sacs to the glands | 2 / 2 | Y | Y | Y |
| skin_folds | wrinkle folds swept back from the nose and wrapping the knolls | 1 / 1 | Y | Y | Y |
| body | the broad lumpy body: rounded nose bulb, broad in the middle, short at | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hanging_sacs | three sacs hanging under the belly | 3 / 3 | Y | Y | Y |
| skin_folds | wrinkle folds swept back from the nose and wrapping the knolls | 1 / 1 | Y | Y | Y |
| body | the broad lumpy body: rounded nose bulb, broad in the middle, short at | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| glands_t | two dorsal spine glands at the crowns of knolls on the back, short spi | 2 / 2 | Y | Y | Y |
| spine_bed | a knoll aft of the dorsal glands studded with growing spines | 1 / 1 | Y | Y | Y |
| knolls | lumps of flesh over the back and shoulders | 1 / 1 | Y | Y | Y |
| scars | scarred patches on the shoulders and flanks | 6 / 6 | Y | Y | Y |
| body | the broad lumpy body: rounded nose bulb, broad in the middle, short at | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| pore_fields | pore fields over the nose bulb and the upper flanks | 2 / 2 | Y | Y | Y |
| glands_t | two dorsal spine glands at the crowns of knolls on the back, short spi | 2 / 2 | Y | Y | Y |
| spine_bed | a knoll aft of the dorsal glands studded with growing spines | 1 / 1 | Y | Y | Y |
| knolls | lumps of flesh over the back and shoulders | 1 / 1 | Y | Y | Y |
| scars | scarred patches on the shoulders and flanks | 6 / 6 | Y | Y | Y |
| bile_sacs | four round sacs a side along the lower flanks, at uneven sizes | 8 / 8 | Y | Y | Y |
| hanging_sacs | three sacs hanging under the belly | 3 / 3 | Y | Y | Y |
| veins | vein runs from the sacs to the glands | 2 / 2 | Y | Y | Y |
| skin_folds | wrinkle folds swept back from the nose and wrapping the knolls | 1 / 1 | Y | Y | Y |
| body | the broad lumpy body: rounded nose bulb, broad in the middle, short at | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| bile_sacs | four round sacs a side along the lower flanks, at uneven sizes | 8 / 8 | Y | Y | Y |
| hanging_sacs | three sacs hanging under the belly | 3 / 3 | Y | Y | Y |
| skin_folds | wrinkle folds swept back from the nose and wrapping the knolls | 1 / 1 | Y | Y | Y |
| body | the broad lumpy body: rounded nose bulb, broad in the middle, short at | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spine_bed | a knoll aft of the dorsal glands studded with growing spines | 1 / 1 | Y | Y | Y |
| knolls | lumps of flesh over the back and shoulders | 1 / 1 | Y | Y | Y |
| body | the broad lumpy body: rounded nose bulb, broad in the middle, short at | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |
| vents | three glowing vents at the short stern with ragged trailing membranes | 3 / 3 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| siphons | puckered jet siphons, a pair forward and a pair aft | 4 / 4 | Y | Y | Y |
| bile_sacs | four round sacs a side along the lower flanks, at uneven sizes | 8 / 8 | Y | Y | Y |
| skin_folds | wrinkle folds swept back from the nose and wrapping the knolls | 1 / 1 | Y | Y | Y |
| body | the broad lumpy body: rounded nose bulb, broad in the middle, short at | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |
| vents | three glowing vents at the short stern with ragged trailing membranes | 3 / 3 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | the broad lumpy body: rounded nose bulb, broad in the middle, short at | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |
| vents | three glowing vents at the short stern with ragged trailing membranes | 3 / 3 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (C13 sheet: bow = the nose bulb and its gland, the waist, the first knoll; mid = the dorsal knolls and glands, the flank and hanging sacs; stern = spine bed, taper, vents and membranes); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 3 | 8 | Hull: the broad lumpy body; Spine gland W1; Spine gland W2; Back and shoulder knolls; Bile sac 1 (port); Bile sac 2 (port); Bile sac 1 (starboard); Hanging sac 1 |
| bow/side | 3 | 7 | Hull: the broad lumpy body; Spine gland W1; Spine gland W2; Back and shoulder knolls; Bile sac 1 (port); Bile sac 2 (port); Hanging sac 1 |
| bow/below | 2 | 4 | Hull: the broad lumpy body; Bile sac 1 (port); Bile sac 2 (port); Hanging sac 1 |
| mid/top | 6 | 13 | Hull: the broad lumpy body; Spine gland W2; Spine gland W3; Spine bed; Back and shoulder knolls; Bile sac 2 (port); Bile sac 3 (port); Bile sac 4 (port); Bile sac 2 (starboard); Bile sac 3 (starboard); Hanging sac 1; Hanging sac 2; Hanging  |
| mid/side | 6 | 11 | Hull: the broad lumpy body; Spine gland W2; Spine gland W3; Spine bed; Back and shoulder knolls; Bile sac 2 (port); Bile sac 3 (port); Bile sac 4 (port); Hanging sac 1; Hanging sac 2; Hanging sac 3 |
| mid/below | 4 | 8 | Hull: the broad lumpy body; Bile sac 2 (port); Bile sac 3 (port); Bile sac 2 (starboard); Bile sac 3 (starboard); Hanging sac 1; Hanging sac 2; Hanging sac 3 |
| stern/top | 3 | 8 | Hull: the broad lumpy body; Spine bed; Back and shoulder knolls; Bile sac 4 (port); Bile sac 3 (starboard); Bile sac 4 (starboard); Hanging sac 3; Vents |
| stern/side | 3 | 6 | Hull: the broad lumpy body; Spine bed; Back and shoulder knolls; Bile sac 4 (port); Hanging sac 3; Vents |
| stern/below | 2 | 4 | Hull: the broad lumpy body; Bile sac 3 (starboard); Bile sac 4 (starboard); Hanging sac 3 |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 2.02 | 2.57 | 2.95 | 3.84 |
| build | 2.40 | 2.60 | 3.02 | 3.29 |

Lines not present, shaped and detailed without a reason: 0.
