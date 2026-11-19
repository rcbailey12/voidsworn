# chorus_C14 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling.
# Read from the WHOLE pictures first (R229): contrib/muse/design/class_family_chorus_2026_11/chorus_C14_brood_sac_v11.jpg (three
# quarter from ahead and below, the front on the left) and chorus_C14_brood_sac_sheet_v5.jpg (plan with the bow DOWN, side view
# with the bow LEFT, front view). No underside view. Fields as chorus_C10_inv.py.
KIT = 'chorus'
INVENTORY = [
    # ---------------- bow ----------------
    dict(id='spine_pore', job='the Spine volley (bioplasma F): one small throat spits spine-laden bile forward', type='throat',
         what='one small glowing pore set in the front folds', count=1, cells=['bow/top', 'bow/side', 'bow/below'],
         reads='a thick lumpy lip flush in the front, an inner sphincter, a ring of chitin spines, a dark bore, the bile gland glowing deep inside',
         src='picture', note='deliberately modest: the carrier is all chamber (designs.md)'),
    dict(id='front_lobes', job='the front\'s muscle: the lobes close over the spine pore and take the first hits', type='welt',
         what='swollen pillows of flesh radiating from the pore over the front quarter', count=1, cells=['bow/top', 'bow/side', 'bow/below'],
         reads='raised welts, uneven in width and reach', src='picture'),
    dict(id='pore_fields', job='sense: it tastes the dark through pore fields (no eyes; lore 5.8)', type='pore',
         what='pore fields round the front and over the shoulders', count=2, cells=['bow/top', 'bow/side', 'mid/top'],
         reads='a raised rim round a sunk pit', src='picture'),
    dict(id='siphons', job='attitude: squirt to swing the front and the stern', type='thruster', what='puckered jet siphons, a pair forward and a pair aft',
         count=4, cells=['bow/side', 'stern/side'], reads='a muscle collar, a puckered lip, a dark bore', src='designed', note='the picture shows none'),
    # ---------------- the back and the rim ----------------
    dict(id='launch_mouths', job='the hangar (hangar 3, ability launch): spore squadrons grown in the chambers below leave through them', type='launch',
         what='five launch openings on thick necks round the rim, drawn empty, dark with a warm glow deep inside', count=5,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'stern/top', 'stern/side'],
         reads='a neck of flesh flaring into the body, one thick rolled lip with creases, stretch wrinkles down the neck, a deep dark bore, a dim glow at its floor',
         src='picture', note='Ryan, Nov 13: no pods shown'),
    dict(id='spore_patch', job='the Spore cloud (spores T): puffs flak spores at craft all round', type='spore',
         what='a ragged patch of pores on top of the sac, off the centre line', count=1, cells=['mid/top', 'mid/side'],
         reads='a low hide mound, a honeycomb of pores of mixed size, raised walls round the bigger ones, dim veins', src='picture'),
    dict(id='stretch_folds', job='the skin drawn up into each neck: the muscle that squeezes a squadron out', type='welt',
         what='wrinkles converging on each opening', count=5, cells=['bow/side', 'mid/top', 'mid/side', 'stern/top'], reads='raised welts', src='picture'),
    dict(id='body_folds', job='the sac\'s muscle: it swells and folds as the brood grows', type='welt',
         what='broken fold rolls over the sac between the openings', count=1, cells=['mid/top', 'mid/side', 'mid/below', 'stern/side'],
         reads='raised welts in broken runs', src='picture'),
    dict(id='scars', job='regrowth (regen 6): wounds knitting shut', type='scar', what='scarred patches on the back and flanks', count=6,
         cells=['bow/top', 'mid/top', 'mid/side', 'stern/top'], reads='a raised irregular patch, knit ridges across it', src='picture'),
    # ---------------- below ----------------
    dict(id='teardrop_sacs', job='spore feed storage for the squadrons and regrowth flesh (regen 6); they rupture first', type='sac',
         what='a fringe of teardrop sacs hanging below the hull', count=18, cells=['bow/side', 'bow/below', 'mid/side', 'mid/below', 'stern/below'],
         reads='a soft neck, a pendulous sac, creases, veins, a glow window', src='picture'),
    dict(id='veins', job='carry spore feed from the belly sacs up to the brood chambers', type='vein', what='vein runs up the flanks', count=2,
         cells=['mid/side', 'mid/below'], reads='a raised vein, branches', src='designed', note='the veins say what the sacs are for'),
    # ---------------- the whole body ----------------
    dict(id='body', job='the body: one giant sac, its chambers the hangar, the heart vat and the guts', type='hull',
         what='a vast sac of folded, scarred flesh, as long as it is wide', count=1,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='fold rolls, wrinkles, pore fields', src='picture'),
    dict(id='hide', job='the hide: hard chitin plates over the sac, the first thing a hit tears', type='plate', what='the hide over the whole body', count=1,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='callus pads, sense pores on them', src='picture'),
    # ---------------- stern ----------------
    dict(id='vents', job='drive (sp 2): four pulse vents push the sac; no nozzles (factions.md)', type='engine',
         what='the membranes streaming from the stern, lit from within', count=4, cells=['stern/top', 'stern/side', 'stern/below'],
         reads='a muscle cone, radial folds, a sphincter mouth, a dark throat, bile glow, trailing membrane veils', src='picture'),
]

LEFT_PLAIN = [
    'Fine wrinkle grain, wet sheen, mottling and the grown chitin plates of the hide: surface texture and paint (recipe stage 5), not modelled.',
    'The squadron pods of earlier takes: removed from the art by Ryan (Nov 13); the openings are drawn empty.',
    'The small spines round the stern in the side view: no job (R221), cut.',
]

STRUCTURE = {'bow/top': 4, 'bow/side': 4, 'bow/below': 3, 'mid/top': 5, 'mid/side': 5, 'mid/below': 3, 'stern/top': 3, 'stern/side': 3,
             'stern/below': 2}
STRUCTURE_NOTE = 'C14 sheet: bow = the front lobes, the pore, the two low openings; mid = the sac, the dorsal and shoulder openings, the patch, the sacs; stern = taper, vents, membranes'
