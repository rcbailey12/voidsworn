# chorus_C14 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/chorus/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/chorus_C14_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| spine_pore | the Spine volley (bioplasma F): one small throat spits spine-laden bile forward | throat | a puckered dark sphincter at the centre of the front folds (deliberately modest: the carrier is all chamber (designs.md)) | 1 | bow/top, bow/side, bow/below | a thick lumpy lip, the folds puckered in to it, an inner sphincter, a ring of chitin spines, a dark bore, the bile gland glowing deep inside | picture |
| front_lobes | the front's muscle: the folds draw shut over the spine pore and take the first hits | welt | the front's skin folds, parted by deep creases that start at the rim and sink in toward the mouth (Board v1 note 1: creases cut in, not lobes added) | 1 | bow/top, bow/side, bow/below | swollen folds between cut creases, uneven in width and reach | picture |
| pore_fields | sense: it tastes the dark through pore fields (no eyes; lore 5.8) | pore | pore fields over the front folds and the shoulders, and one small eye-hole above the mouth | 3 | bow/top, bow/side, mid/top | a raised rim round a sunk pit | picture |
| siphons | attitude: squirt to swing the front and the stern | thruster | puckered jet siphons, a pair forward and a pair aft (the picture shows none) | 4 | bow/side, stern/side | a muscle collar, a puckered lip, a dark bore | designed |
| launch_mouths | the hangar (hangar 3, ability launch): spore squadrons grown in the chambers below leave through them | launch | five launch openings on thick necks round the rim, drawn empty, dark with a warm glow deep inside (Ryan, Nov 13: no pods shown) | 5 | bow/top, bow/side, bow/below, mid/top, mid/side, stern/top, stern/side | a neck of flesh flaring into the body, one fat round rolled lip standing off the body, creases, stretch wrinkles down the neck, a deep dark bore, a dim glow at its floor | picture |
| spore_patch | the Spore cloud (spores T): puffs flak spores at craft all round | spore | a ragged cluster of big pores at the front of the honeycomb field, off the centre line | 1 | bow/top, mid/top | a low hide mound, a honeycomb of pores of mixed size, raised walls round the bigger ones, dim veins | picture |
| spore_field | the Spore cloud's field: its pores ripen the spores the cluster at its front puffs out | pore | a honeycomb of pores over the upper front, about a fifth of the top, sunk in a raised roll of skin (body_folds) (Board v1 note 4) | 1 | bow/top, mid/top, mid/side | a raised rim round a sunk pit, packed into a honeycomb | picture |
| stretch_folds | the skin drawn up into each neck: the muscle that squeezes a squadron out | welt | wrinkles converging on each opening | 5 | bow/side, mid/top, mid/side, stern/top | raised welts | picture |
| body_folds | the sac's muscle: it swells and folds as the brood grows | welt | broken fold rolls over the sac between the openings, and the roll of skin round the honeycomb field | 2 | mid/top, mid/side, mid/below, stern/side | raised welts in broken runs | picture |
| scars | regrowth (regen 6): wounds knitting shut | scar | scarred patches on the back and flanks | 6 | bow/top, mid/top, mid/side, stern/top | a raised irregular patch, knit ridges across it | picture |
| teardrop_sacs | spore feed storage for the squadrons and regrowth flesh (regen 6); they rupture first | sac | a fringe of big teardrop sacs on soft necks, low on the belly's edge, hanging below the outline (Board v1 note 5: bigger and longer) | 18 | bow/side, bow/below, mid/side, mid/below, stern/below | a soft neck, a pendulous sac, creases, veins, a glow window | picture |
| veins | carry spore feed from the belly sacs up to the brood chambers | vein | vein runs up the flanks (the veins say what the sacs are for) | 2 | mid/side, mid/below | a raised vein, branches | designed |
| body | the body: one giant sac, its chambers the hangar, the heart vat and the guts | hull | a vast sac of folded, scarred flesh, as long as it is wide | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | fold rolls, wrinkles, pore fields | picture |
| hide | the hide: hard chitin plates over the sac, the first thing a hit tears | plate | the hide over the whole body | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | callus pads, sense pores on them | picture |
| vents | drive (sp 2): four pulse vents push the sac; no nozzles (factions.md) | engine | the membranes streaming from the stern, lit from within | 4 | stern/top, stern/side, stern/below | a muscle cone, radial folds, a sphincter mouth, a dark throat, bile glow, trailing membrane veils | picture |

Kit sub-parts per type (what DETAILED checks):

- engine: root, fold, sphincter, throat, glow, membrane|filament
- hull: ridge, fold, pore
- launch: root, lip, crease, bore, glow
- plate: pad, pore
- pore: rim, pit
- sac: root, sac, crease, vein, glow
- scar: patch, knit
- spore: root, sac, vein, spout, pore
- throat: root, fold|lip, sphincter, tooth, bore, gland
- thruster: collar, lip, bore
- vein: vein, branch
- welt: welt

Left as surface, and why:

- Fine wrinkle grain, wet sheen, mottling and the grown chitin plates of the hide: surface texture and paint (recipe stage 5), not modelled.
- The squadron pods of earlier takes: removed from the art by Ryan (Nov 13); the openings are drawn empty.
- The small spines round the stern in the side view: no job (R221), cut.

## Every built part has a job (R221)

Built kit parts: 55; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, chorus_C14_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spine_pore | a puckered dark sphincter at the centre of the front folds | 1 / 1 | Y | Y | Y |
| front_lobes | the front's skin folds, parted by deep creases that start at the rim a | 1 / 1 | Y | Y | Y |
| pore_fields | pore fields over the front folds and the shoulders, and one small eye- | 3 / 3 | Y | Y | Y |
| launch_mouths | five launch openings on thick necks round the rim, drawn empty, dark w | 5 / 5 | Y | Y | Y |
| spore_patch | a ragged cluster of big pores at the front of the honeycomb field, off | 1 / 1 | Y | Y | Y |
| spore_field | a honeycomb of pores over the upper front, about a fifth of the top, s | 1 / 1 | Y | Y | Y |
| scars | scarred patches on the back and flanks | 6 / 6 | Y | Y | Y |
| body | a vast sac of folded, scarred flesh, as long as it is wide | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spine_pore | a puckered dark sphincter at the centre of the front folds | 1 / 1 | Y | Y | Y |
| front_lobes | the front's skin folds, parted by deep creases that start at the rim a | 1 / 1 | Y | Y | Y |
| pore_fields | pore fields over the front folds and the shoulders, and one small eye- | 3 / 3 | Y | Y | Y |
| siphons | puckered jet siphons, a pair forward and a pair aft | 4 / 4 | Y | Y | Y |
| launch_mouths | five launch openings on thick necks round the rim, drawn empty, dark w | 5 / 5 | Y | Y | Y |
| stretch_folds | wrinkles converging on each opening | 5 / 5 | Y | Y | Y |
| teardrop_sacs | a fringe of big teardrop sacs on soft necks, low on the belly's edge,  | 18 / 18 | Y | Y | Y |
| body | a vast sac of folded, scarred flesh, as long as it is wide | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spine_pore | a puckered dark sphincter at the centre of the front folds | 1 / 1 | Y | Y | Y |
| front_lobes | the front's skin folds, parted by deep creases that start at the rim a | 1 / 1 | Y | Y | Y |
| launch_mouths | five launch openings on thick necks round the rim, drawn empty, dark w | 5 / 5 | Y | Y | Y |
| teardrop_sacs | a fringe of big teardrop sacs on soft necks, low on the belly's edge,  | 18 / 18 | Y | Y | Y |
| body | a vast sac of folded, scarred flesh, as long as it is wide | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| pore_fields | pore fields over the front folds and the shoulders, and one small eye- | 3 / 3 | Y | Y | Y |
| launch_mouths | five launch openings on thick necks round the rim, drawn empty, dark w | 5 / 5 | Y | Y | Y |
| spore_patch | a ragged cluster of big pores at the front of the honeycomb field, off | 1 / 1 | Y | Y | Y |
| spore_field | a honeycomb of pores over the upper front, about a fifth of the top, s | 1 / 1 | Y | Y | Y |
| stretch_folds | wrinkles converging on each opening | 5 / 5 | Y | Y | Y |
| body_folds | broken fold rolls over the sac between the openings, and the roll of s | 2 / 2 | Y | Y | Y |
| scars | scarred patches on the back and flanks | 6 / 6 | Y | Y | Y |
| body | a vast sac of folded, scarred flesh, as long as it is wide | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| launch_mouths | five launch openings on thick necks round the rim, drawn empty, dark w | 5 / 5 | Y | Y | Y |
| spore_field | a honeycomb of pores over the upper front, about a fifth of the top, s | 1 / 1 | Y | Y | Y |
| stretch_folds | wrinkles converging on each opening | 5 / 5 | Y | Y | Y |
| body_folds | broken fold rolls over the sac between the openings, and the roll of s | 2 / 2 | Y | Y | Y |
| scars | scarred patches on the back and flanks | 6 / 6 | Y | Y | Y |
| teardrop_sacs | a fringe of big teardrop sacs on soft necks, low on the belly's edge,  | 18 / 18 | Y | Y | Y |
| veins | vein runs up the flanks | 2 / 2 | Y | Y | Y |
| body | a vast sac of folded, scarred flesh, as long as it is wide | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body_folds | broken fold rolls over the sac between the openings, and the roll of s | 2 / 2 | Y | Y | Y |
| teardrop_sacs | a fringe of big teardrop sacs on soft necks, low on the belly's edge,  | 18 / 18 | Y | Y | Y |
| veins | vein runs up the flanks | 2 / 2 | Y | Y | Y |
| body | a vast sac of folded, scarred flesh, as long as it is wide | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| launch_mouths | five launch openings on thick necks round the rim, drawn empty, dark w | 5 / 5 | Y | Y | Y |
| stretch_folds | wrinkles converging on each opening | 5 / 5 | Y | Y | Y |
| scars | scarred patches on the back and flanks | 6 / 6 | Y | Y | Y |
| body | a vast sac of folded, scarred flesh, as long as it is wide | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |
| vents | the membranes streaming from the stern, lit from within | 4 / 4 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| siphons | puckered jet siphons, a pair forward and a pair aft | 4 / 4 | Y | Y | Y |
| launch_mouths | five launch openings on thick necks round the rim, drawn empty, dark w | 5 / 5 | Y | Y | Y |
| body_folds | broken fold rolls over the sac between the openings, and the roll of s | 2 / 2 | Y | Y | Y |
| body | a vast sac of folded, scarred flesh, as long as it is wide | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |
| vents | the membranes streaming from the stern, lit from within | 4 / 4 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| teardrop_sacs | a fringe of big teardrop sacs on soft necks, low on the belly's edge,  | 18 / 18 | Y | Y | Y |
| body | a vast sac of folded, scarred flesh, as long as it is wide | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |
| vents | the membranes streaming from the stern, lit from within | 4 / 4 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (C14 sheet: bow = the front lobes, the pore, the two low openings; mid = the sac, the dorsal and shoulder openings, the patch, the sacs; stern = taper, vents, membranes); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 4 | 6 | Hull: the giant sac; Front: the puckered face; Front folds; Spore field and patch; Launch opening L4; Launch opening L5 |
| bow/side | 4 | 5 | Hull: the giant sac; Front: the puckered face; Front folds; Spore field and patch; Launch opening L4 |
| bow/below | 3 | 0 |  |
| mid/top | 5 | 8 | Hull: the giant sac; Launch opening L1; Launch opening L2; Launch opening L3; Launch opening L4; Launch opening L5; Teardrop sacs; Vents |
| mid/side | 5 | 6 | Hull: the giant sac; Launch opening L1; Launch opening L2; Launch opening L4; Teardrop sacs; Vents |
| mid/below | 3 | 1 | Teardrop sacs |
| stern/top | 3 | 3 | Hull: the giant sac; Launch opening L1; Vents |
| stern/side | 3 | 3 | Hull: the giant sac; Launch opening L1; Vents |
| stern/below | 2 | 0 |  |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 1.12 | 0.99 | 1.17 | 0.99 |
| build | 1.28 | 1.65 | 1.63 | 2.08 |

Lines not present, shaped and detailed without a reason: 0.
