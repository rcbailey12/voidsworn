# chorus_C11 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/chorus/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/chorus_C11_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| throats | the Spine volley (bioplasma F): two throats spit spine-laden bile forward as one battery | throat | two separate open throats side by side at the bow, flared rims, glowing deep inside | 2 | bow/top, bow/side, bow/below | a muscular root, a flared rim with radial creases, wrinkles running back, an inner sphincter, a ring of chitin spines, a dark bore, the bile gland glowing at its back | picture |
| pore_fields | sense: it tastes the dark through pore fields (no eyes; lore 5.8) | pore | dense pore fields over the head and the upper flanks | 2 | bow/top, bow/side, mid/top, mid/side | a raised rim round a sunk pit | picture |
| siphons | attitude: squirt to swing the head and the tail | thruster | puckered jet siphons, a pair forward and a pair aft (the picture shows none) | 4 | bow/side, stern/side | a muscle collar, a puckered lip, a dark bore | designed |
| blade_row | ram blades: the bladeback closes fast and cuts into a hull with them (Razormaw, blood frenzy) | spine | the pale bone blade row down the centre of the back, tallest forward | 1 | bow/top, bow/side, mid/top, mid/side | transition tissue collars, raked blades with growth lines and serrated edges | picture |
| side_blades | guard the bile sacs and the upper flanks; they cut as the body rolls into a target | spine | smaller bone blades along each shoulder (the plan's separate pale plates) | 2 | bow/top, mid/top, mid/side | collars, raked blades with growth lines and serrated edges | picture |
| wound | the open groove the blades grow from: new bone pushes up through it (regrowth, regen 6) | wound | the raw channel along the spine with the blades in it | 1 | bow/top, mid/top | a channel of raw tissue between two lips | picture |
| mane | boarding tendrils (tendril T): lash and hold a hull at close range, the acid pores eat through its armour | mane | the plume of long tendrils rising from the back behind the blades and streaming aft | 1 | mid/top, mid/side, stern/top, stern/side | a muscle crest, hooked tendrils with grip rings, chitin barbs and acid pores | picture |
| bile_sacs | bile reservoirs: store the bile the throats spit, fed forward by the veins | sac | three domed sacs a side on the flanks, in wrinkled sockets | 6 | bow/top, bow/side, mid/top, mid/side | a socket of wrinkle rolls, the dome, creases, veins, glow windows | picture |
| veins | carry bile from the sacs forward to the throat glands | vein | vein runs from the sacs to the throats (the picture shows the hide's grain; the veins say what the sacs are for) | 2 | bow/side, mid/side | a raised vein, branches | designed |
| flank_folds | the body's muscle: it flexes the hull to turn and to bite | welt | long wrinkle folds along the flanks converging on the throats | 1 | bow/side, mid/side, stern/side, bow/below, mid/below | raised welts | picture |
| scars | regrowth (regen 6): wounds knitting shut | scar | scarred patches on the back and flanks | 5 | bow/top, mid/top, mid/side, stern/top | a raised irregular patch, knit ridges across it | picture |
| body | the body: holds the organs, the heart vat and the bile glands | hull | the short broad body, blunt at the bow, tapering to the stern | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | the wound ridge, flank folds, pore fields | picture |
| hide | the hide: callused pads with sense pores, the first thing a hit tears | plate | the hide over the whole body | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | callus pads, sense pores on them | picture |
| vents | drive (sp 4): six pulse vents push the body; no nozzles (factions.md) | engine | the stern filament plume with its glowing nodes (the picture's amber nodes are the vent mouths) | 6 | stern/top, stern/side, stern/below | a muscle cone, radial folds, a sphincter mouth, a dark throat, bile glow, filaments with glowing nodes | picture |

Kit sub-parts per type (what DETAILED checks):

- engine: root, fold, sphincter, throat, glow, membrane|filament
- hull: ridge, fold, pore
- mane: root, crest, stalk, ring, barb
- plate: pad, pore
- pore: rim, pit
- sac: root, sac, crease, vein, glow
- scar: patch, knit
- spine: collar, blade, growth, edge
- throat: root, fold|lip, sphincter, tooth, bore, gland
- thruster: collar, lip, bore
- vein: vein, branch
- welt: welt
- wound: channel, lip, tissue

Left as surface, and why:

- Fine wrinkle grain, wet sheen, mottling and the colour of the hide: surface texture and paint (recipe stages 4 and 5), not modelled.
- The two escorts beside the cruiser in both pictures are their own ships, not part of this hull.
- The small spines along the lower stern in the side view are cut: they have no job (R221).

## Every built part has a job (R221)

Built kit parts: 35; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, chorus_C11_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| throats | two separate open throats side by side at the bow, flared rims, glowin | 2 / 2 | Y | Y | Y |
| pore_fields | dense pore fields over the head and the upper flanks | 2 / 2 | Y | Y | Y |
| blade_row | the pale bone blade row down the centre of the back, tallest forward | 1 / 1 | Y | Y | Y |
| side_blades | smaller bone blades along each shoulder (the plan's separate pale plat | 2 / 2 | Y | Y | Y |
| wound | the raw channel along the spine with the blades in it | 1 / 1 | Y | Y | Y |
| bile_sacs | three domed sacs a side on the flanks, in wrinkled sockets | 6 / 6 | Y | Y | Y |
| scars | scarred patches on the back and flanks | 5 / 5 | Y | Y | Y |
| body | the short broad body, blunt at the bow, tapering to the stern | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| throats | two separate open throats side by side at the bow, flared rims, glowin | 2 / 2 | Y | Y | Y |
| pore_fields | dense pore fields over the head and the upper flanks | 2 / 2 | Y | Y | Y |
| siphons | puckered jet siphons, a pair forward and a pair aft | 4 / 4 | Y | Y | Y |
| blade_row | the pale bone blade row down the centre of the back, tallest forward | 1 / 1 | Y | Y | Y |
| bile_sacs | three domed sacs a side on the flanks, in wrinkled sockets | 6 / 6 | Y | Y | Y |
| veins | vein runs from the sacs to the throats | 2 / 2 | Y | Y | Y |
| flank_folds | long wrinkle folds along the flanks converging on the throats | 1 / 1 | Y | Y | Y |
| body | the short broad body, blunt at the bow, tapering to the stern | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| throats | two separate open throats side by side at the bow, flared rims, glowin | 2 / 2 | Y | Y | Y |
| flank_folds | long wrinkle folds along the flanks converging on the throats | 1 / 1 | Y | Y | Y |
| body | the short broad body, blunt at the bow, tapering to the stern | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| pore_fields | dense pore fields over the head and the upper flanks | 2 / 2 | Y | Y | Y |
| blade_row | the pale bone blade row down the centre of the back, tallest forward | 1 / 1 | Y | Y | Y |
| side_blades | smaller bone blades along each shoulder (the plan's separate pale plat | 2 / 2 | Y | Y | Y |
| wound | the raw channel along the spine with the blades in it | 1 / 1 | Y | Y | Y |
| mane | the plume of long tendrils rising from the back behind the blades and  | 1 / 1 | Y | Y | Y |
| bile_sacs | three domed sacs a side on the flanks, in wrinkled sockets | 6 / 6 | Y | Y | Y |
| scars | scarred patches on the back and flanks | 5 / 5 | Y | Y | Y |
| body | the short broad body, blunt at the bow, tapering to the stern | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| pore_fields | dense pore fields over the head and the upper flanks | 2 / 2 | Y | Y | Y |
| blade_row | the pale bone blade row down the centre of the back, tallest forward | 1 / 1 | Y | Y | Y |
| side_blades | smaller bone blades along each shoulder (the plan's separate pale plat | 2 / 2 | Y | Y | Y |
| mane | the plume of long tendrils rising from the back behind the blades and  | 1 / 1 | Y | Y | Y |
| bile_sacs | three domed sacs a side on the flanks, in wrinkled sockets | 6 / 6 | Y | Y | Y |
| veins | vein runs from the sacs to the throats | 2 / 2 | Y | Y | Y |
| flank_folds | long wrinkle folds along the flanks converging on the throats | 1 / 1 | Y | Y | Y |
| scars | scarred patches on the back and flanks | 5 / 5 | Y | Y | Y |
| body | the short broad body, blunt at the bow, tapering to the stern | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| flank_folds | long wrinkle folds along the flanks converging on the throats | 1 / 1 | Y | Y | Y |
| body | the short broad body, blunt at the bow, tapering to the stern | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| mane | the plume of long tendrils rising from the back behind the blades and  | 1 / 1 | Y | Y | Y |
| scars | scarred patches on the back and flanks | 5 / 5 | Y | Y | Y |
| body | the short broad body, blunt at the bow, tapering to the stern | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |
| vents | the stern filament plume with its glowing nodes | 6 / 6 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| siphons | puckered jet siphons, a pair forward and a pair aft | 4 / 4 | Y | Y | Y |
| mane | the plume of long tendrils rising from the back behind the blades and  | 1 / 1 | Y | Y | Y |
| flank_folds | long wrinkle folds along the flanks converging on the throats | 1 / 1 | Y | Y | Y |
| body | the short broad body, blunt at the bow, tapering to the stern | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |
| vents | the stern filament plume with its glowing nodes | 6 / 6 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | the short broad body, blunt at the bow, tapering to the stern | 1 / 1 | Y | Y | Y |
| hide | the hide over the whole body | 1 / 1 | Y | Y | Y |
| vents | the stern filament plume with its glowing nodes | 6 / 6 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (C11 sheet: bow = the two throats, the head, the first dome pair; mid = body, blade row, domes, mane; stern = taper, nodes, filaments); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 4 | 7 | Hull: the short broad body; Head: the face; Bile sac 1 (port); Bile sac 1 (starboard); Bone crest; Shoulder crests (port); Shoulder crests (starboard) |
| bow/side | 3 | 5 | Hull: the short broad body; Head: the face; Bile sac 1 (port); Bone crest; Shoulder crests (port) |
| bow/below | 2 | 4 | Hull: the short broad body; Head: the face; Bile sac 1 (port); Bile sac 1 (starboard) |
| mid/top | 6 | 11 | Hull: the short broad body; Mane; Bile sac 1 (port); Bile sac 1 (starboard); Bile sac 2 (port); Bile sac 2 (starboard); Bile sac 3 (port); Bile sac 3 (starboard); Bone crest; Shoulder crests (port); Shoulder crests (starboard) |
| mid/side | 5 | 7 | Hull: the short broad body; Mane; Bile sac 1 (port); Bile sac 2 (port); Bile sac 3 (port); Bone crest; Shoulder crests (port) |
| mid/below | 3 | 5 | Hull: the short broad body; Bile sac 1 (port); Bile sac 1 (starboard); Bile sac 2 (port); Bile sac 2 (starboard) |
| stern/top | 3 | 5 | Hull: the short broad body; Mane; Bile sac 3 (port); Bile sac 3 (starboard); Vent ring |
| stern/side | 3 | 4 | Hull: the short broad body; Mane; Bile sac 3 (port); Vent ring |
| stern/below | 2 | 1 | Hull: the short broad body |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 2.27 | 2.88 | 2.78 | 3.44 |
| build | 1.95 | 2.00 | 2.43 | 2.83 |

Lines not present, shaped and detailed without a reason: 0.
