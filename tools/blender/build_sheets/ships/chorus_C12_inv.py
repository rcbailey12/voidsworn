# chorus_C12 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling.
# Read from the WHOLE pictures first (R229): contrib/muse/design/class_family_chorus_2026_11/chorus_C12_drone_spawn_v10.jpg (from
# ahead, port and a little above, the bow on the left) and chorus_C12_drone_spawn_sheet_v2.jpg (plan at the left with the BOW
# DOWN, side view at the right with the bow LEFT, bow-on view below). designs.md governs where a picture differs. Fields as
# chorus_C11_inv.py.
KIT = 'chorus'
INVENTORY = [
    # ---------------- bow ----------------
    dict(id='knoll', job='the Spine volley (bioplasma F): the knoll spits bile laden with bone spines forward', type='throat',
         what='the head\'s round puckered mouth of pink flesh, a big dark open bore ringed by short spines',
         count=1, cells=['bow/top', 'bow/side', 'bow/below'],
         reads='a muscular root, a puckered lip with creases and pores, short bone hooks, an inner sphincter, a deep dark bore, the bile gland deep at its back',
         src='picture'),
    dict(id='siphons', job='attitude: squirt to swing the prow and the stern', type='thruster', what='puckered jet siphons, a pair forward and a pair aft',
         count=4, cells=['bow/side', 'stern/side'], reads='a muscle collar, a puckered lip, a dark bore', src='designed', note='the picture shows none'),
    # ---------------- the back ----------------
    dict(id='tendril_knot', job='boarding tendrils (tendril T): lash and hold a hull at close range, the acid pores at the blunt tips eat through its armour',
         type='drape', what='a low mound of knotted muscle amidships on top holding five heavy tendrils that drape back over the hull and down the flanks',
         count=1, cells=['mid/top', 'mid/side', 'stern/top', 'stern/side', 'mid/below'],
         reads='a muscle mound, knotted cords over it, heavy tendrils with grip rings, blunt rounded tips with an acid pore', src='picture'),
    dict(id='back_folds', job='the back\'s muscle: long folds that flex the body and carry the knot\'s pull to the prow', type='welt',
         what='long fleshy folds and ridges running bow to stern over the back, under the tendrils (seven runs, one built item)', count=1, cells=['bow/top', 'mid/top', 'stern/top', 'mid/side'],
         reads='raised welts of uneven width', src='picture'),
    dict(id='pore_fields', job='sense: it tastes the dark through pore fields (no eyes; lore 5.8)', type='pore',
         what='pitted pore patches over the back and the upper flanks', count=2, cells=['bow/top', 'mid/top', 'mid/side'],
         reads='a raised rim round a sunk pit', src='picture'),
    # ---------------- flanks and below ----------------
    dict(id='bile_domes', job='bile stores: hold the bile the knoll spits, fed forward by the veins', type='sac',
         what='three domes a side on the flanks, in wrinkled sockets', count=6, cells=['bow/side', 'mid/side', 'stern/side', 'mid/top'],
         reads='a socket of wrinkle rolls, the dome, creases, veins, glow windows', src='picture'),
    dict(id='reserve_sacs', job='the regrow reserve (regen 3): flesh the body draws on to close its wounds', type='sac',
         what='two small sacs hanging below the hull', count=2, cells=['mid/side', 'mid/below', 'stern/below'],
         reads='a neck, a teardrop sac, creases, veins, a glow window', src='picture'),
    dict(id='veins', job='carry bile from the domes forward to the knoll', type='vein', what='vein runs from the domes to the prow', count=2,
         cells=['bow/side', 'mid/side'], reads='a raised vein, branches', src='designed', note='the picture shows the hide\'s grain; the veins say what the domes are for'),
    dict(id='folds', job='the body\'s muscle: it flexes the hull to turn and to strike', type='welt',
         what='wrinkle folds swept back from the knoll over the prow and along the flanks', count=1, cells=['bow/top', 'bow/side', 'mid/side', 'bow/below'],
         reads='raised welts', src='picture'),
    dict(id='scars', job='regrowth (regen 3): wounds knitting shut', type='scar', what='scarred patches on the back and flanks', count=3,
         cells=['bow/top', 'mid/top', 'stern/top'], reads='a raised irregular patch, knit ridges across it', src='picture'),
    # ---------------- the whole body ----------------
    dict(id='body', job='the body: holds the organs, the heart vat and the bile gland', type='hull',
         what='the compact knot of lumpy grown flesh, narrow at the prow, widest a little aft of the middle', count=1,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='the spine ridge, the folds, the pore fields', src='picture'),
    dict(id='hide', job='the hide: callused pads with sense pores, the first thing a hit tears', type='plate', what='the hide over the whole body', count=1,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='callus pads, sense pores on them', src='picture'),
    # ---------------- stern ----------------
    dict(id='vents', job='drive (sp 5, the fastest in the faction): four pulse vents push the body; no nozzles (factions.md)', type='engine',
         what='the stern\'s layered trailing membranes, soft veils lit faintly from within', count=4, cells=['stern/top', 'stern/side', 'stern/below'],
         reads='a muscle cone, radial folds, a sphincter mouth, a dark throat, bile glow, wide cupped veils with veins of light', src='picture',
         note='the picture shows the veils; the vents they stream from are designed (no fins, no bulb, no nozzle: designs.md)'),
]

LEFT_PLAIN = [
    'Fine wrinkle grain, wet sheen, mottling and the colour of the hide: surface texture and paint (recipe stages 4 and 5), not modelled.',
    'The ragged fringes and the many thin strands at the membranes\' edges: the veils are built as broad strips; the fringe is paint.',
]

STRUCTURE = {'bow/top': 3, 'bow/side': 3, 'bow/below': 2, 'mid/top': 4, 'mid/side': 4, 'mid/below': 2, 'stern/top': 2, 'stern/side': 3,
             'stern/below': 2}
STRUCTURE_NOTE = 'C12 sheet: bow = the knoll, the crown, the narrow prow; mid = body, knot, tendrils, domes, sacs; stern = taper, membranes'
