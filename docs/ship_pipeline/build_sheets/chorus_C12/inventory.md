# chorus_C12 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/chorus/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/chorus_C12_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| knoll | the Spine volley (bioplasma F): the knoll spits bile laden with bone spines forward | throat | the head's round puckered mouth of pink flesh, a big dark open bore ringed by short spines | 1 | bow/top, bow/side, bow/below | a muscular root, a puckered lip with creases and pores, short bone hooks, an inner sphincter, a deep dark bore, the bile gland deep at its back | picture |
| siphons | attitude: squirt to swing the prow and the stern | thruster | puckered jet siphons, a pair forward and a pair aft (the picture shows none) | 4 | bow/side, stern/side | a muscle collar, a puckered lip, a dark bore | designed |
| tendril_knot | boarding tendrils (tendril T): lash and hold a hull at close range, the acid pores at the blunt tips eat through its armour | drape | a low mound of knotted muscle amidships on top holding five heavy tendrils that drape back over the hull and down the flanks | 1 | mid/top, mid/side, stern/top, stern/side, mid/below | a muscle mound, knotted cords over it, heavy tendrils with grip rings, blunt rounded tips with an acid pore | picture |
| back_folds | the back's muscle: long folds that flex the body and carry the knot's pull to the prow | welt | long fleshy folds and ridges running bow to stern over the back, under the tendrils (seven runs, one built item) | 1 | bow/top, mid/top, stern/top, mid/side | raised welts of uneven width | picture |
| pore_fields | sense: it tastes the dark through pore fields (no eyes; lore 5.8) | pore | pitted pore patches over the back and the upper flanks | 2 | bow/top, mid/top, mid/side | a raised rim round a sunk pit | picture |
| bile_domes | bile stores: hold the bile the knoll spits, fed forward by the veins | sac | three domes a side on the flanks, in wrinkled sockets | 6 | bow/side, mid/side, stern/side, mid/top | a socket of wrinkle rolls, the dome, creases, veins, glow windows | picture |
| reserve_sacs | the regrow reserve (regen 3): flesh the body draws on to close its wounds | sac | two small sacs hanging below the hull | 2 | mid/side, mid/below, stern/below | a neck, a teardrop sac, creases, veins, a glow window | picture |
| veins | carry bile from the domes forward to the knoll | vein | vein runs from the domes to the prow (the picture shows the hide's grain; the veins say what the domes are for) | 2 | bow/side, mid/side | a raised vein, branches | designed |
| folds | the body's muscle: it flexes the hull to turn and to strike | welt | wrinkle folds swept back from the knoll over the prow and along the flanks | 1 | bow/top, bow/side, mid/side, bow/below | raised welts | picture |
| scars | regrowth (regen 3): wounds knitting shut | scar | scarred patches on the back and flanks | 3 | bow/top, mid/top, stern/top | a raised irregular patch, knit ridges across it | picture |
| body | the body: holds the organs, the heart vat and the bile gland | hull | the compact knot of lumpy grown flesh, narrow at the prow, widest a little aft of the middle | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | the spine ridge, the folds, the pore fields | picture |
| hide | the hide: callused pads with sense pores, the first thing a hit tears | plate | the hide over the whole body | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | callus pads, sense pores on them | picture |
| vents | drive (sp 5, the fastest in the faction): four pulse vents push the body; no nozzles (factions.md) | engine | the stern's layered trailing membranes, soft veils lit faintly from within (the picture shows the veils; the vents they stream from are designed (no fins, no bulb, no nozzle: designs.md)) | 4 | stern/top, stern/side, stern/below | a muscle cone, radial folds, a sphincter mouth, a dark throat, bile glow, wide cupped veils with veins of light | picture |

Kit sub-parts per type (what DETAILED checks):

- drape: root, knot, stalk, ring, tip
- engine: root, fold, sphincter, throat, glow, membrane|filament
- hull: ridge, fold, pore
- plate: pad, pore
- pore: rim, pit
- sac: root, sac, crease, vein, glow
- scar: patch, knit
- throat: root, fold|lip, sphincter, tooth, bore, gland
- thruster: collar, lip, bore
- vein: vein, branch
- welt: welt

Left as surface, and why:

- Fine wrinkle grain, wet sheen, mottling and the colour of the hide: surface texture and paint (recipe stages 4 and 5), not modelled.
- The ragged fringes and the many thin strands at the membranes' edges: the veils are built as broad strips; the fringe is paint.

## Every built part has a job (R221)

Built kit parts: 29; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, chorus_C12_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| knoll | the head's round puckered mouth of pink flesh, a big dark open bore ri | 1 / 1 | Y | Y | Y |
| back_folds | long fleshy folds and ridges running bow to stern over the back, under | 1 / 1 | Y | Y | Y |
| pore_fields | pitted pore patches over the back and the upper flanks | 2 / 2 | Y | Y | Y |
| folds | wrinkle folds swept back from the knoll over the prow and along the fl | 1 / 1 | Y | Y | Y |
| scars | scarred patches on the back and flanks | 3 / 3 | Y | Y | Y |
| body | the compact knot of lumpy grown flesh, narrow at the prow, widest a li | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| knoll | the head's round puckered mouth of pink flesh, a big dark open bore ri | 1 / 1 | Y | Y | Y |
| siphons | puckered jet siphons, a pair forward and a pair aft | 4 / 4 | Y | Y | Y |
| bile_domes | three domes a side on the flanks, in wrinkled sockets | 6 / 6 | Y | Y | Y |
| veins | vein runs from the domes to the prow | 2 / 2 | Y | Y | Y |
| folds | wrinkle folds swept back from the knoll over the prow and along the fl | 1 / 1 | Y | Y | Y |
| body | the compact knot of lumpy grown flesh, narrow at the prow, widest a li | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| knoll | the head's round puckered mouth of pink flesh, a big dark open bore ri | 1 / 1 | Y | Y | Y |
| folds | wrinkle folds swept back from the knoll over the prow and along the fl | 1 / 1 | Y | Y | Y |
| body | the compact knot of lumpy grown flesh, narrow at the prow, widest a li | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| tendril_knot | a low mound of knotted muscle amidships on top holding five heavy tend | 1 / 1 | Y | Y | Y |
| back_folds | long fleshy folds and ridges running bow to stern over the back, under | 1 / 1 | Y | Y | Y |
| pore_fields | pitted pore patches over the back and the upper flanks | 2 / 2 | Y | Y | Y |
| bile_domes | three domes a side on the flanks, in wrinkled sockets | 6 / 6 | Y | Y | Y |
| scars | scarred patches on the back and flanks | 3 / 3 | Y | Y | Y |
| body | the compact knot of lumpy grown flesh, narrow at the prow, widest a li | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| tendril_knot | a low mound of knotted muscle amidships on top holding five heavy tend | 1 / 1 | Y | Y | Y |
| back_folds | long fleshy folds and ridges running bow to stern over the back, under | 1 / 1 | Y | Y | Y |
| pore_fields | pitted pore patches over the back and the upper flanks | 2 / 2 | Y | Y | Y |
| bile_domes | three domes a side on the flanks, in wrinkled sockets | 6 / 6 | Y | Y | Y |
| reserve_sacs | two small sacs hanging below the hull | 2 / 2 | Y | Y | Y |
| veins | vein runs from the domes to the prow | 2 / 2 | Y | Y | Y |
| folds | wrinkle folds swept back from the knoll over the prow and along the fl | 1 / 1 | Y | Y | Y |
| body | the compact knot of lumpy grown flesh, narrow at the prow, widest a li | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| tendril_knot | a low mound of knotted muscle amidships on top holding five heavy tend | 1 / 1 | Y | Y | Y |
| reserve_sacs | two small sacs hanging below the hull | 2 / 2 | Y | Y | Y |
| body | the compact knot of lumpy grown flesh, narrow at the prow, widest a li | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| tendril_knot | a low mound of knotted muscle amidships on top holding five heavy tend | 1 / 1 | Y | Y | Y |
| back_folds | long fleshy folds and ridges running bow to stern over the back, under | 1 / 1 | Y | Y | Y |
| scars | scarred patches on the back and flanks | 3 / 3 | Y | Y | Y |
| body | the compact knot of lumpy grown flesh, narrow at the prow, widest a li | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |
| vents | the stern's layered trailing membranes, soft veils lit faintly from wi | 4 / 4 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| siphons | puckered jet siphons, a pair forward and a pair aft | 4 / 4 | Y | Y | Y |
| tendril_knot | a low mound of knotted muscle amidships on top holding five heavy tend | 1 / 1 | Y | Y | Y |
| bile_domes | three domes a side on the flanks, in wrinkled sockets | 6 / 6 | Y | Y | Y |
| body | the compact knot of lumpy grown flesh, narrow at the prow, widest a li | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |
| vents | the stern's layered trailing membranes, soft veils lit faintly from wi | 4 / 4 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| reserve_sacs | two small sacs hanging below the hull | 2 / 2 | Y | Y | Y |
| body | the compact knot of lumpy grown flesh, narrow at the prow, widest a li | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |
| vents | the stern's layered trailing membranes, soft veils lit faintly from wi | 4 / 4 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (C12 sheet: bow = the knoll, the crown, the narrow prow; mid = body, knot, tendrils, domes, sacs; stern = taper, membranes); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 3 | 6 | Hull: the compact knot of flesh; Prow knoll; Bile dome 1 (port); Bile dome 1 (starboard); Bile dome 2 (port); Bile dome 2 (starboard) |
| bow/side | 3 | 4 | Hull: the compact knot of flesh; Prow knoll; Bile dome 1 (port); Bile dome 2 (port) |
| bow/below | 2 | 2 | Hull: the compact knot of flesh; Prow knoll |
| mid/top | 4 | 8 | Hull: the compact knot of flesh; Tendril knot; Bile dome 2 (port); Bile dome 2 (starboard); Bile dome 3 (port); Bile dome 3 (starboard); Reserve sac 1 (port); Reserve sac 2 (starboard) |
| mid/side | 4 | 5 | Hull: the compact knot of flesh; Tendril knot; Bile dome 2 (port); Bile dome 3 (port); Reserve sac 1 (port) |
| mid/below | 2 | 3 | Hull: the compact knot of flesh; Reserve sac 1 (port); Reserve sac 2 (starboard) |
| stern/top | 2 | 5 | Hull: the compact knot of flesh; Tendril knot; Bile dome 3 (port); Bile dome 3 (starboard); Vent ring |
| stern/side | 3 | 4 | Hull: the compact knot of flesh; Tendril knot; Bile dome 3 (port); Vent ring |
| stern/below | 2 | 1 | Hull: the compact knot of flesh |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 1.90 | 2.22 | 2.45 | 3.43 |
| build | 2.03 | 2.19 | 2.69 | 3.76 |

Lines not present, shaped and detailed without a reason: 0.
