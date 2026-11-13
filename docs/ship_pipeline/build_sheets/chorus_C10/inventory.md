# chorus_C10 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/chorus/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/chorus_C10_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| throats | the two bile spitters (bioplasma F, F: the Spine volley): spit spine-laden bile forward | throat | the folded double mouth: two throats side by side in heavy rolled fold lips, glowing deep inside | 2 | bow/top, bow/side, bow/below | a muscular root, rolled fold lips with fold wrinkles running back over the head, an inner sphincter, a ring of chitin spines, a dark bore, the bile gland glowing at its back | picture |
| head_folds | the muscle that opens and closes the double mouth, and the head's armour | welt | heavy fold rolls running back from the mouths over the head to the shoulders | 2 | bow/top, bow/side | raised fold rolls, swelling at the mouth and fading back | picture |
| head_pores | sense: the Chorus has no eyes, it tastes the dark through pore fields (lore 5.8: tasting the air before the hunt) | pore | pore fields over the head behind the mouths, and round the vent crown (the beauty shows a fine pore grain all over; the build gathers it into fields where the ship senses) | 2 | bow/top, bow/side, stern/top, stern/side | a raised rim round a sunk pit | picture |
| brood_sacs | the hangar (hangar 3, ability launch): spore swarms grow in them and are born through the slit | brood | three big sacs a side bulging from the lower flanks, largest forward, each with a crease (the picture's crease on each sac is the birth slit) | 6 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below | a socket of wrinkle rolls, the sac, creases, surface veins, the birth slit between two lip rolls | picture |
| siphons | attitude: squirt to swing the head and the tail (no nozzles, factions.md) | thruster | puckered jet siphons, a pair behind the mouths and a pair on the tail (the picture shows none; a ship in space must turn) | 4 | bow/side, stern/side | a muscle collar, a puckered lip, a dark bore | designed |
| crown | boarding tendrils (tendril T): lash and hold an enemy hull, the acid pores eat through its armour | tendril | the dorsal tendril cluster amidships, curling up in profile, splayed in plan | 1 | mid/top, mid/side | a muscle mound with radial welts, a sphincter, hooked tendrils with grip rings, chitin barbs and acid pores | picture |
| spore_glands | the Spore cloud (spores T): point defence against craft, puffing spore clouds | spore | the row of small sacs hanging under the belly on short necks | 5 | mid/side, mid/below | a neck collar, a veined sac, a spout curling forward, a rosette of pores | picture |
| flank_fold | armour strake over the flank organs, and the line the hide tears along first (how it breaks) | welt | the long raised ridge down each flank from behind the head to the tail (the picture draws a long raised fold; the lore gives the Chorus ochre chitin trim, here on its edge) | 2 | bow/top, bow/side, mid/top, mid/side, stern/top, stern/side | a raised fold of membrane with height, its edge armoured with ochre chitin | picture |
| veins | carry bile from the heart vat to the throat glands and the sacs; their dim light is the lore's light inside the body | vein | branching vein runs along both flanks (the C9 tracery the round 8b pass faded (README); built back faintly) | 2 | bow/side, mid/side | a raised vein, branches | picture |
| scars | regrowth (regen 20, the Mending): wounds knitting shut | scar | pale scarred patches on the back and flanks | 8 | bow/top, mid/top, mid/side, stern/top | a raised irregular patch, knit ridges across it | picture |
| body | the body: holds the organs, the heart vat and the brood chambers | hull | the long body: broad flat back, rounder belly, tapering to the tail | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | the shoulder ridges, fold wrinkles, pore fields | picture |
| hide | the hide: callused armour pads with sense pores, the first thing a hit tears | plate | the hide over the whole body | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | callus pads (irregular low domes), sense pores on them | picture |
| tail_folds | the muscle that squeezes the vent crown (the pulse) | welt | wrinkle folds converging on the tail end | 1 | stern/top, stern/side | raised welts | picture |
| vents | drive (sp 2): pulse vents push the body; no nozzles (factions.md) | engine | the tail's glowing end with streaming membranes (the picture draws a spike with three or four glow points and long wisps; the build makes them a crown of three vents) | 3 | stern/top, stern/side, stern/below | a muscle cone into the body, radial folds, a sphincter mouth, a dark throat, bile glow, trailing membrane veils | picture |

Kit sub-parts per type (what DETAILED checks):

- brood: root, sac, crease, slit, lip, vein
- engine: root, fold, sphincter, throat, glow, membrane|filament
- hull: ridge, fold, pore
- plate: pad, pore
- pore: rim, pit
- scar: patch, knit
- spore: root, sac, vein, spout, pore
- tendril: root, sphincter, stalk, ring, barb, pore
- throat: root, fold|lip, sphincter, tooth, bore, gland
- thruster: collar, lip, bore
- vein: vein, branch
- welt: welt

Left as surface, and why:

- Fine wrinkle grain, wet sheen, mottling and the colour of the hide: surface texture and paint (recipe stages 4 and 5), not modelled.
- The escort beside the flagship in both pictures is its own ship (a later fleet brief), not part of this hull.

## Every built part has a job (R221)

Built kit parts: 40; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, chorus_C10_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| throats | the folded double mouth: two throats side by side in heavy rolled fold | 2 / 2 | Y | Y | Y |
| head_folds | heavy fold rolls running back from the mouths over the head to the sho | 2 / 2 | Y | Y | Y |
| head_pores | pore fields over the head behind the mouths, and round the vent crown | 2 / 2 | Y | Y | Y |
| brood_sacs | three big sacs a side bulging from the lower flanks, largest forward,  | 6 / 6 | Y | Y | Y |
| flank_fold | the long raised ridge down each flank from behind the head to the tail | 2 / 2 | Y | Y | Y |
| scars | pale scarred patches on the back and flanks | 8 / 8 | Y | Y | Y |
| body | the long body: broad flat back, rounder belly, tapering to the tail | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| throats | the folded double mouth: two throats side by side in heavy rolled fold | 2 / 2 | Y | Y | Y |
| head_folds | heavy fold rolls running back from the mouths over the head to the sho | 2 / 2 | Y | Y | Y |
| head_pores | pore fields over the head behind the mouths, and round the vent crown | 2 / 2 | Y | Y | Y |
| brood_sacs | three big sacs a side bulging from the lower flanks, largest forward,  | 6 / 6 | Y | Y | Y |
| siphons | puckered jet siphons, a pair behind the mouths and a pair on the tail | 4 / 4 | Y | Y | Y |
| flank_fold | the long raised ridge down each flank from behind the head to the tail | 2 / 2 | Y | Y | Y |
| veins | branching vein runs along both flanks | 2 / 2 | Y | Y | Y |
| body | the long body: broad flat back, rounder belly, tapering to the tail | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| throats | the folded double mouth: two throats side by side in heavy rolled fold | 2 / 2 | Y | Y | Y |
| brood_sacs | three big sacs a side bulging from the lower flanks, largest forward,  | 6 / 6 | Y | Y | Y |
| body | the long body: broad flat back, rounder belly, tapering to the tail | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| brood_sacs | three big sacs a side bulging from the lower flanks, largest forward,  | 6 / 6 | Y | Y | Y |
| crown | the dorsal tendril cluster amidships, curling up in profile, splayed i | 1 / 1 | Y | Y | Y |
| flank_fold | the long raised ridge down each flank from behind the head to the tail | 2 / 2 | Y | Y | Y |
| scars | pale scarred patches on the back and flanks | 8 / 8 | Y | Y | Y |
| body | the long body: broad flat back, rounder belly, tapering to the tail | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| brood_sacs | three big sacs a side bulging from the lower flanks, largest forward,  | 6 / 6 | Y | Y | Y |
| crown | the dorsal tendril cluster amidships, curling up in profile, splayed i | 1 / 1 | Y | Y | Y |
| spore_glands | the row of small sacs hanging under the belly on short necks | 5 / 5 | Y | Y | Y |
| flank_fold | the long raised ridge down each flank from behind the head to the tail | 2 / 2 | Y | Y | Y |
| veins | branching vein runs along both flanks | 2 / 2 | Y | Y | Y |
| scars | pale scarred patches on the back and flanks | 8 / 8 | Y | Y | Y |
| body | the long body: broad flat back, rounder belly, tapering to the tail | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| brood_sacs | three big sacs a side bulging from the lower flanks, largest forward,  | 6 / 6 | Y | Y | Y |
| spore_glands | the row of small sacs hanging under the belly on short necks | 5 / 5 | Y | Y | Y |
| body | the long body: broad flat back, rounder belly, tapering to the tail | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| head_pores | pore fields over the head behind the mouths, and round the vent crown | 2 / 2 | Y | Y | Y |
| flank_fold | the long raised ridge down each flank from behind the head to the tail | 2 / 2 | Y | Y | Y |
| scars | pale scarred patches on the back and flanks | 8 / 8 | Y | Y | Y |
| body | the long body: broad flat back, rounder belly, tapering to the tail | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |
| tail_folds | wrinkle folds converging on the tail end | 1 / 1 | Y | Y | Y |
| vents | the tail's glowing end with streaming membranes | 3 / 3 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| head_pores | pore fields over the head behind the mouths, and round the vent crown | 2 / 2 | Y | Y | Y |
| siphons | puckered jet siphons, a pair behind the mouths and a pair on the tail | 4 / 4 | Y | Y | Y |
| flank_fold | the long raised ridge down each flank from behind the head to the tail | 2 / 2 | Y | Y | Y |
| body | the long body: broad flat back, rounder belly, tapering to the tail | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |
| tail_folds | wrinkle folds converging on the tail end | 1 / 1 | Y | Y | Y |
| vents | the tail's glowing end with streaming membranes | 3 / 3 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | the long body: broad flat back, rounder belly, tapering to the tail | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |
| vents | the tail's glowing end with streaming membranes | 3 / 3 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (C10 sheet: bow = the two mouth lobes, the head, the first sac pair; mid = body, crown, sacs, belly row; stern = tail, glow end, membranes); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 4 | 10 | Hull: the long body; Mouth, port throat; Mouth, starboard throat; Spore gland 1; Brood sac 1 (port); Brood sac 1 (starboard); Flank fold (port); Flank fold (starboard); Head folds (port); Head folds (starboard) |
| bow/side | 4 | 6 | Hull: the long body; Mouth, port throat; Spore gland 1; Brood sac 1 (port); Flank fold (port); Head folds (port) |
| bow/below | 3 | 3 | Spore gland 1; Brood sac 1 (port); Brood sac 1 (starboard) |
| mid/top | 6 | 15 | Hull: the long body; Tendril crown; Spore gland 1; Spore gland 2; Spore gland 3; Spore gland 4; Spore gland 5; Brood sac 1 (port); Brood sac 1 (starboard); Brood sac 2 (port); Brood sac 2 (starboard); Brood sac 3 (port); Brood sac 3 (starbo |
| mid/side | 7 | 11 | Hull: the long body; Tendril crown; Spore gland 1; Spore gland 2; Spore gland 3; Spore gland 4; Spore gland 5; Brood sac 1 (port); Brood sac 2 (port); Brood sac 3 (port); Flank fold (port) |
| mid/below | 6 | 6 | Spore gland 1; Spore gland 2; Spore gland 3; Brood sac 1 (port); Brood sac 1 (starboard); Brood sac 2 (starboard) |
| stern/top | 3 | 5 | Hull: the long body; Spore gland 5; Vent crown; Flank fold (port); Flank fold (starboard) |
| stern/side | 3 | 4 | Hull: the long body; Spore gland 5; Vent crown; Flank fold (port) |
| stern/below | 2 | 0 |  |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 3.08 | 3.18 | 5.74 | 6.21 |
| build | 4.07 | 3.27 | 6.04 | 5.62 |

Lines not present, shaped and detailed without a reason: 0.
