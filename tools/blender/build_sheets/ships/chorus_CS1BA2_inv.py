# chorus_CS1BA2 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling, plus what the
# designer adds with its job (R221). Read from contrib/muse/design/squadron_concepts_2026_11/chorus/round_4/CS1BA2.jpg (one
# three-quarter view from above: the bow lower left, the stern upper right) and design_notes_785_round4.md (the CS1B-A2 sheet, the
# proportion guards, the production notes and the owner's ruling). The concept has no underside and no true views. Grown, not
# built: the Chorus carries its detail as ridges, pores, veins and creases (R224), never panels or metal.
# Fields: id, job (what the part does on the craft, R221), type (tools/blender/kits/chorus/parts.py SUBPARTS), what, count, cells,
# reads (the sub-parts that make it read as that thing), src (picture or designed).
KIT = 'chorus'
INVENTORY = [
    # ---------------- bow (point to 33 percent): the bone fork, the sense pores ----------------
    dict(id='body', job='the craft\'s one grown body: it carries the acid glands, the ganglion, the gut and the pulse muscle', type='hull',
         what='one sleek grown spindle, drawn out and low: a smooth blunt bow, the stern tapering to a blunt end behind the orifice cluster',
         count=1, cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='the bone ridge, the creases, the pores (grown, never panels)', src='picture'),
    dict(id='hide', job='the callused hide over the body', type='plate', what='scattered callus pads of hide', count=1,
         cells=['bow/top', 'bow/side', 'mid/top', 'mid/below', 'stern/top', 'stern/side'], reads='domed pads sunk at their edges (never a panel)', src='picture',
         note='the concept\'s stippled skin'),
    dict(id='spine', job='the bone line: the craft\'s keel of bone from the stern to the bow, splitting into the short blunt fork', type='welt',
         what='one long low bone ridge along the back, a short low fork at the bow, chitin growth knuckles along it', count=1,
         cells=['bow/top', 'mid/top', 'stern/top'], reads='the raised bone welt, the fork, the growth knuckles', src='picture'),
    dict(id='sense_pores', job='the swarm\'s senses: it tastes the dark (factions.md: no eyes)', type='pore',
         what='two rows of sense pores along the bow ridge', count=1, cells=['bow/top'], reads='a raised rim round a sunk pit', src='picture',
         note='the concept\'s eye-spots, made pores'),
    # ---------------- midships (33 to 66 percent): the sealed gill bladders ----------------
    dict(id='gill_bladders', job='the acid sacs (data.js sporeb T, 2 shots): the swarm\'s only weapon, one per flank, both bursting every volley', type='acid_sac',
         what='two sealed gill bladders lying along the upper flanks either side of the bone line, each with a closed sphincter at its front', count=2,
         cells=['bow/top', 'mid/top', 'mid/side', 'stern/top'],
         reads='the long swell, its root roll, raised gill bands, a muted amber blush in the valleys, the closed puckered sphincter (R221)', src='picture',
         note='the concept\'s two banded bladders'),
    dict(id='veins', job='the veins that carry bile to the glands and the pulse muscle', type='vein', what='a few raised veins over the flanks and the belly', count=1,
         cells=['mid/side', 'mid/below', 'stern/side'], reads='raised veins and their branches', src='designed'),
    # ---------------- stern (66 to 100 percent): the orifice cluster ----------------
    dict(id='orifices', job='drive (sp 5): the muscle-ringed orifice cluster squeezes pulses of bile gas aft (no nozzle, factions.md)', type='engine',
         what='four orifices in a cluster on the blunt stern', count=4, cells=['stern/top', 'stern/side'],
         reads='a muscle cone, radial folds, a sphincter ring, an inner membrane, a dark throat, bile glow deep inside', src='picture'),
    dict(id='stern_folds', job='the creases where the stern draws in behind the bladders (the flesh gathering toward the cluster)', type='welt',
         what='short creases either side of the stern taper', count=1, cells=['stern/top', 'stern/side'], reads='raised crease welts', src='designed'),
]
STRUCTURE = {'bow/top': 3, 'bow/side': 2, 'mid/top': 3, 'mid/side': 2, 'stern/top': 3, 'stern/side': 2}
STRUCTURE_NOTE = ('CS1B-A2 render, by eye (no true views): bow, the body, the bone fork and the spots; midships, the body, the bone line and the '
                  'two bladders; stern, the body, the bladders\' ends and the orifice cluster')
LEFT_PLAIN = [
    'The flesh tones, the stipple and the amber\'s depth: the Chorus has no paint stack yet; the sheet carries schematic colour zones.',
    'Trailing membranes from the orifices (the capital ships\' veils): they would hang far behind a 3.84 unit craft and read as a tail; not built.',
]
INV_NOTES = {}
