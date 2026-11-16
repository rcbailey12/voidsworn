# chorus_CS1BA2 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/chorus/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/chorus_CS1BA2_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| body | the craft's one grown body: it carries the acid glands, the ganglion, the gut and the pulse muscle | hull | one sleek grown spindle, drawn out and low: a smooth blunt bow, the stern tapering to a blunt end behind the orifice cluster | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | the bone ridge, the creases, the pores (grown, never panels) | picture |
| hide | the callused hide over the body | plate | scattered callus pads of hide (the concept's stippled skin) | 1 | bow/top, bow/side, mid/top, mid/below, stern/top, stern/side | domed pads sunk at their edges (never a panel) | picture |
| spine | the bone line: the craft's keel of bone from the stern to the bow, splitting into the short blunt fork | welt | one long low bone ridge along the back, a short low fork at the bow, chitin growth knuckles along it | 1 | bow/top, mid/top, stern/top | the raised bone welt, the fork, the growth knuckles | picture |
| sense_pores | the swarm's senses: it tastes the dark (factions.md: no eyes) | pore | two rows of sense pores along the bow ridge (the concept's eye-spots, made pores) | 1 | bow/top | a raised rim round a sunk pit | picture |
| gill_bladders | the acid sacs (data.js sporeb T, 2 shots): the swarm's only weapon, one per flank, both bursting every volley | acid_sac | two sealed gill bladders lying along the upper flanks either side of the bone line, each with a closed sphincter at its front (the concept's two banded bladders) | 2 | bow/top, mid/top, mid/side, stern/top | the long swell, its root roll, raised gill bands, a muted amber blush in the valleys, the closed puckered sphincter (R221) | picture |
| veins | the veins that carry bile to the glands and the pulse muscle | vein | a few raised veins over the flanks and the belly | 1 | mid/side, mid/below, stern/side | raised veins and their branches | designed |
| orifices | drive (sp 5): the muscle-ringed orifice cluster squeezes pulses of bile gas aft (no nozzle, factions.md) | engine | four orifices in a cluster on the blunt stern | 4 | stern/top, stern/side | a muscle cone, radial folds, a sphincter ring, an inner membrane, a dark throat, bile glow deep inside | picture |
| stern_folds | the creases where the stern draws in behind the bladders (the flesh gathering toward the cluster) | welt | short creases either side of the stern taper | 1 | stern/top, stern/side | raised crease welts | designed |

Kit sub-parts per type (what DETAILED checks):

- acid_sac: (hull shaping, checked by eye on the side-by-side)
- engine: root, fold, sphincter, throat, glow, membrane|filament
- hull: ridge, fold, pore
- plate: pad, pore
- pore: rim, pit
- vein: vein, branch
- welt: welt

Left as surface, and why:

- The flesh tones, the stipple and the amber's depth: the Chorus has no paint stack yet; the sheet carries schematic colour zones.
- Trailing membranes from the orifices (the capital ships' veils): they would hang far behind a 3.84 unit craft and read as a tail; not built.

## Every built part has a job (R221)

Built kit parts: 15; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, chorus_CS1BA2_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | one sleek grown spindle, drawn out and low: a smooth blunt bow, the st | 1 / 1 | Y | Y | Y |
| hide | scattered callus pads of hide | 1 / 1 | Y | Y | Y |
| spine | one long low bone ridge along the back, a short low fork at the bow, c | 4 / 1 | Y | Y | Y |
| sense_pores | two rows of sense pores along the bow ridge | 1 / 1 | Y | Y | Y |
| gill_bladders | two sealed gill bladders lying along the upper flanks either side of t | 2 / 2 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | one sleek grown spindle, drawn out and low: a smooth blunt bow, the st | 1 / 1 | Y | Y | Y |
| hide | scattered callus pads of hide | 1 / 1 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | one sleek grown spindle, drawn out and low: a smooth blunt bow, the st | 1 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | one sleek grown spindle, drawn out and low: a smooth blunt bow, the st | 1 / 1 | Y | Y | Y |
| hide | scattered callus pads of hide | 1 / 1 | Y | Y | Y |
| spine | one long low bone ridge along the back, a short low fork at the bow, c | 4 / 1 | Y | Y | Y |
| gill_bladders | two sealed gill bladders lying along the upper flanks either side of t | 2 / 2 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | one sleek grown spindle, drawn out and low: a smooth blunt bow, the st | 1 / 1 | Y | Y | Y |
| gill_bladders | two sealed gill bladders lying along the upper flanks either side of t | 2 / 2 | Y | Y | Y |
| veins | a few raised veins over the flanks and the belly | 1 / 1 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | one sleek grown spindle, drawn out and low: a smooth blunt bow, the st | 1 / 1 | Y | Y | Y |
| hide | scattered callus pads of hide | 1 / 1 | Y | Y | Y |
| veins | a few raised veins over the flanks and the belly | 1 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | one sleek grown spindle, drawn out and low: a smooth blunt bow, the st | 1 / 1 | Y | Y | Y |
| hide | scattered callus pads of hide | 1 / 1 | Y | Y | Y |
| spine | one long low bone ridge along the back, a short low fork at the bow, c | 4 / 1 | Y | Y | Y |
| gill_bladders | two sealed gill bladders lying along the upper flanks either side of t | 2 / 2 | Y | Y | Y |
| orifices | four orifices in a cluster on the blunt stern | 4 / 4 | Y | Y | Y |
| stern_folds | short creases either side of the stern taper | 1 / 1 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | one sleek grown spindle, drawn out and low: a smooth blunt bow, the st | 1 / 1 | Y | Y | Y |
| hide | scattered callus pads of hide | 1 / 1 | Y | Y | Y |
| veins | a few raised veins over the flanks and the belly | 1 / 1 | Y | Y | Y |
| orifices | four orifices in a cluster on the blunt stern | 4 / 4 | Y | Y | Y |
| stern_folds | short creases either side of the stern taper | 1 / 1 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | one sleek grown spindle, drawn out and low: a smooth blunt bow, the st | 1 / 1 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (CS1B-A2 render, by eye (no true views): bow, the body, the bone fork and the spots; midships, the body, the bone line and the two bladders; stern, the body, the bladders' ends and the orifice cluster); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 3 | 1 | Hull: the grown spindle |
| bow/side | 2 | 1 | Hull: the grown spindle |
| bow/below | no view | 1 | Hull: the grown spindle |
| mid/top | 3 | 1 | Hull: the grown spindle |
| mid/side | 2 | 1 | Hull: the grown spindle |
| mid/below | no view | 1 | Hull: the grown spindle |
| stern/top | 3 | 1 | Hull: the grown spindle |
| stern/side | 2 | 1 | Hull: the grown spindle |
| stern/below | no view | 1 | Hull: the grown spindle |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 1.67 | 1.67 | 3.16 | 3.16 |
| build | 3.47 | 6.70 | 3.76 | 7.35 |

Lines not present, shaped and detailed without a reason: 0.
