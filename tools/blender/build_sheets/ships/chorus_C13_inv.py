# chorus_C13 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling.
# Read from the WHOLE pictures first (R229): contrib/muse/design/class_family_chorus_2026_11/chorus_C13_spitter_v7.jpg (from
# above, port and ahead, the bow lower left) and chorus_C13_spitter_sheet_v1.jpg (top view, side view and bow-on view, BOW ON
# THE LEFT). designs.md governs where a picture differs. Fields as chorus_C11_inv.py.
KIT = 'chorus'
INVENTORY = [
    # ---------------- bow ----------------
    dict(id='glands_f', job='the forward Spine volley (bioplasma F): the prow gland spits spine-laden bile ahead', type='throat',
         what='the prow spine gland: a puckered vent in the rounded nose bulb, short spines round it', count=1, cells=['bow/top', 'bow/side'],
         reads='a knoll, pucker folds and a lip round the vent, a sphincter, a ring of chitin teeth, a dark bore, the bile gland glowing at '
               'its back, short bone spines out of the knoll', src='picture'),
    dict(id='pore_fields', job='sense: it tastes the dark through pore fields (no eyes; lore 5.8)', type='pore',
         what='pore fields over the nose bulb and the upper flanks', count=2, cells=['bow/top', 'bow/side', 'mid/side'],
         reads='a raised rim round a sunk pit', src='picture'),
    dict(id='siphons', job='attitude: squirt to swing the bow and the stern', type='thruster', what='puckered jet siphons, a pair forward and a pair aft',
         count=4, cells=['bow/side', 'stern/side'], reads='a muscle collar, a puckered lip, a dark bore', src='designed', note='the picture shows none'),
    # ---------------- the back ----------------
    dict(id='glands_t', job='the all-round Spine volley (bioplasma T): two dorsal glands spit every way, one muzzle each for the slot\'s two shots',
         type='throat', what='two dorsal spine glands at the crowns of knolls on the back, short spines round each', count=2,
         cells=['bow/top', 'mid/top', 'mid/side'],
         reads='a knoll, pucker folds and a lip round the vent, a sphincter, chitin teeth, a dark bore, the bile gland, bone spines', src='picture'),
    dict(id='spine_bed', job='regrowth of spent spines (regrow, regen 4): new spines grow here before they move to the glands', type='spine_bed',
         what='a knoll aft of the dorsal glands studded with growing spines', count=1, cells=['mid/top', 'mid/side', 'stern/top'],
         reads='a knoll, bone spines with knuckle tips and tissue collars, pores', src='picture'),
    dict(id='knolls', job='the body\'s muscle and fat: lumps of grown flesh that carry the glands\' spine sacs and soak hits', type='knoll',
         what='lumps of flesh over the back and shoulders', count=1, cells=['bow/top', 'mid/top', 'mid/side', 'stern/top'],
         reads='a lumpy dome, wrinkle rolls round its foot, pores', src='picture'),
    dict(id='scars', job='regrowth (regen 4): ragged regrown hide on the shoulders and flanks', type='scar', what='scarred patches on the shoulders and flanks', count=6,
         cells=['bow/top', 'mid/top', 'mid/side'], reads='a raised irregular patch, knit ridges across it', src='picture'),
    # ---------------- flanks and belly ----------------
    dict(id='bile_sacs', job='bile reservoirs: store the bile the glands spit; they swell before a volley', type='sac',
         what='four round sacs a side along the lower flanks, at uneven sizes', count=8, cells=['bow/side', 'mid/side', 'mid/below', 'stern/side'],
         reads='a socket of wrinkle rolls, the dome, creases, veins, glow windows', src='picture'),
    dict(id='hanging_sacs', job='the deep bile reserve under the belly', type='sac', what='three sacs hanging under the belly', count=3,
         cells=['bow/below', 'mid/below', 'mid/side'], reads='a socket, the hanging sac, creases, veins, glow', src='picture'),
    dict(id='veins', job='carry bile from the sacs forward and up to the glands', type='vein', what='vein runs from the sacs to the glands', count=2,
         cells=['bow/side', 'mid/side'], reads='a raised vein, branches', src='designed', note='the picture shows the hide\'s grain; the veins say what the sacs are for'),
    dict(id='skin_folds', job='the body\'s muscle: it flexes the hull to turn and to squeeze the sacs', type='welt',
         what='wrinkle folds swept back from the nose and wrapping the knolls', count=1, cells=['bow/side', 'mid/side', 'stern/side', 'bow/below', 'mid/below'],
         reads='raised welts', src='picture'),
    # ---------------- the whole body ----------------
    dict(id='body', job='the body: holds the organs, the heart vat and the spine sacs', type='hull',
         what='the broad lumpy body: rounded nose bulb, broad in the middle, short at the tail', count=1,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='skin folds, pore fields, scars', src='picture'),
    dict(id='hide', job='the hide: callused pads with sense pores, the first thing a hit tears', type='plate', what='the hide over the whole body', count=1,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='callus pads, sense pores on them', src='picture'),
    # ---------------- stern ----------------
    dict(id='vents', job='drive (sp 4): three pulse vents push the body; no nozzles (factions.md)', type='engine',
         what='three glowing vents at the short stern with ragged trailing membranes', count=3, cells=['stern/top', 'stern/side', 'stern/below'],
         reads='a muscle cone, radial folds, a sphincter mouth, a dark throat, bile glow, membrane veils', src='picture'),
]

LEFT_PLAIN = [
    'Fine wrinkle grain, wet sheen, mottling and the colour of the hide: surface texture and paint (recipe stages 4 and 5), not modelled.',
    'The long quills at the stern quarter and under the stern are cut: they have no job (R221) and would sit in the vents\' wash.',
    'The torn membrane flecks floating behind the stern in the pictures are an effect, not part of the hull.',
]

STRUCTURE = {'bow/top': 3, 'bow/side': 3, 'bow/below': 2, 'mid/top': 6, 'mid/side': 6, 'mid/below': 4, 'stern/top': 3, 'stern/side': 3,
             'stern/below': 2}
STRUCTURE_NOTE = 'C13 sheet: bow = the nose bulb and its gland, the waist, the first knoll; mid = the dorsal knolls and glands, the flank and hanging sacs; stern = spine bed, taper, vents and membranes'
