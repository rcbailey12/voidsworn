# chorus_C10 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling.
# Read from the WHOLE pictures first (R229): contrib/muse/design/concept_round8b_2026_11/chorus_C10_beauty.jpg (from above,
# port and ahead, the bow on the left) and chorus_C10_sheet.jpg (plan above, side view below, BOW ON THE LEFT; the smaller
# ship at the right of each view is the escort, not this hull). The sheet has no underside view; the side view shows the
# belly row. Fields: id, job (what it does on the ship, R221), type (the Chorus kit type, tools/blender/kits/chorus/parts.py
# SUBPARTS), what, count, cells (bow, mid, stern thirds by top, side, below), reads (the sub-parts that make it read as that
# thing), src (picture or designed), note.
KIT = 'chorus'
INVENTORY = [
    # ---------------- bow (the mouth mass to 33 percent) ----------------
    dict(id='throats', job='the two bile spitters (bioplasma F, F: the Spine volley): spit spine-laden bile forward', type='throat',
         what='the folded double mouth: two throats side by side in heavy rolled fold lips, glowing deep inside', count=2,
         cells=['bow/top', 'bow/side', 'bow/below'],
         reads='a muscular root, rolled fold lips with fold wrinkles running back over the head, an inner sphincter, a ring of chitin '
               'spines, a dark bore, the bile gland glowing at its back', src='picture'),
    dict(id='head_folds', job='the muscle that opens and closes the double mouth, and the head\'s armour', type='welt',
         what='heavy fold rolls running back from the mouths over the head to the shoulders', count=2, cells=['bow/top', 'bow/side'],
         reads='raised fold rolls, swelling at the mouth and fading back', src='picture'),
    dict(id='head_pores', job='sense: the Chorus has no eyes, it tastes the dark through pore fields (lore 5.8: tasting the air before the hunt)',
         type='pore', what='pore fields over the head behind the mouths, and round the vent crown', count=2,
         cells=['bow/top', 'bow/side', 'stern/top', 'stern/side'], reads='a raised rim round a sunk pit', src='picture',
         note='the beauty shows a fine pore grain all over; the build gathers it into fields where the ship senses'),
    dict(id='brood_sacs', job='the hangar (hangar 3, ability launch): spore swarms grow in them and are born through the slit',
         type='brood', what='three big sacs a side bulging from the lower flanks, largest forward, each with a crease', count=6,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below'],
         reads='a socket of wrinkle rolls, the sac, creases, surface veins, the birth slit between two lip rolls', src='picture',
         note='the picture\'s crease on each sac is the birth slit'),
    dict(id='siphons', job='attitude: squirt to swing the head and the tail (no nozzles, factions.md)', type='thruster',
         what='puckered jet siphons, a pair behind the mouths and a pair on the tail', count=4, cells=['bow/side', 'stern/side'],
         reads='a muscle collar, a puckered lip, a dark bore', src='designed', note='the picture shows none; a ship in space must turn'),
    # ---------------- midships ----------------
    dict(id='crown', job='boarding tendrils (tendril T): lash and hold an enemy hull, the acid pores eat through its armour', type='tendril',
         what='the dorsal tendril cluster amidships, curling up in profile, splayed in plan', count=1, cells=['mid/top', 'mid/side'],
         reads='a muscle mound with radial welts, a sphincter, hooked tendrils with grip rings, chitin barbs and acid pores', src='picture'),
    dict(id='spore_glands', job='the Spore cloud (spores T): point defence against craft, puffing spore clouds', type='spore',
         what='the row of small sacs hanging under the belly on short necks', count=5, cells=['mid/side', 'mid/below'],
         reads='a neck collar, a veined sac, a spout curling forward, a rosette of pores', src='picture'),
    dict(id='flank_fold', job='armour strake over the flank organs, and the line the hide tears along first (how it breaks)', type='welt',
         what='the long raised ridge down each flank from behind the head to the tail', count=2,
         cells=['bow/top', 'bow/side', 'mid/top', 'mid/side', 'stern/top', 'stern/side'],
         reads='a raised fold of membrane with height, its edge armoured with ochre chitin', src='picture',
         note='the picture draws a long raised fold; the lore gives the Chorus ochre chitin trim, here on its edge'),
    dict(id='veins', job='carry bile from the heart vat to the throat glands and the sacs; their dim light is the lore\'s light inside the body',
         type='vein', what='branching vein runs along both flanks', count=2, cells=['bow/side', 'mid/side'],
         reads='a raised vein, branches', src='picture', note='the C9 tracery the round 8b pass faded (README); built back faintly'),
    dict(id='scars', job='regrowth (regen 20, the Mending): wounds knitting shut', type='scar',
         what='pale scarred patches on the back and flanks', count=8, cells=['bow/top', 'mid/top', 'mid/side', 'stern/top'],
         reads='a raised irregular patch, knit ridges across it', src='picture'),
    # ---------------- the whole body ----------------
    dict(id='body', job='the body: holds the organs, the heart vat and the brood chambers', type='hull',
         what='the long body: broad flat back, rounder belly, tapering to the tail', count=1,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='the shoulder ridges, fold wrinkles, pore fields', src='picture'),
    dict(id='hide', job='the hide: callused armour pads with sense pores, the first thing a hit tears', type='plate',
         what='the hide over the whole body', count=1,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='callus pads (irregular low domes), sense pores on them', src='picture'),
    # ---------------- stern ----------------
    dict(id='tail_folds', job='the muscle that squeezes the vent crown (the pulse)', type='welt',
         what='wrinkle folds converging on the tail end', count=1, cells=['stern/top', 'stern/side'], reads='raised welts', src='picture'),
    dict(id='vents', job='drive (sp 2): pulse vents push the body; no nozzles (factions.md)', type='engine',
         what='the tail\'s glowing end with streaming membranes', count=3, cells=['stern/top', 'stern/side', 'stern/below'],
         reads='a muscle cone into the body, radial folds, a sphincter mouth, a dark throat, bile glow, trailing membrane veils',
         src='picture', note='the picture draws a spike with three or four glow points and long wisps; the build makes them a crown of three vents'),
]

LEFT_PLAIN = [
    'Fine wrinkle grain, wet sheen, mottling and the colour of the hide: surface texture and paint (recipe stages 4 and 5), not modelled.',
    'The escort beside the flagship in both pictures is its own ship (a later fleet brief), not part of this hull.',
]

# distinct masses per cell, read off the concept sheet by eye (top and side views; no underside view, the side view's lower
# edge stands in for below)
STRUCTURE = {'bow/top': 4, 'bow/side': 4, 'bow/below': 3, 'mid/top': 6, 'mid/side': 7, 'mid/below': 6, 'stern/top': 3, 'stern/side': 3,
             'stern/below': 2}
STRUCTURE_NOTE = 'C10 sheet: bow = the two mouth lobes, the head, the first sac pair; mid = body, crown, sacs, belly row; stern = tail, glow end, membranes'
