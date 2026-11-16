# chorus_C11 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling.
# Read from the WHOLE pictures first (R229): contrib/muse/design/concept_round8b_2026_11/chorus_C11_beauty.jpg (from above,
# port and ahead, the bow on the left) and chorus_C11_sheet.jpg (plan above, side view below, BOW ON THE LEFT; the two smaller
# ships at the right are the escort, not this hull). No underside view. Fields as chorus_C10_inv.py.
KIT = 'chorus'
INVENTORY = [
    # ---------------- bow ----------------
    dict(id='throats', job='the Spine volley (bioplasma F): two throats spit spine-laden bile forward as one battery', type='throat',
         what='two separate open throats side by side at the bow, flared rims, glowing deep inside', count=2, cells=['bow/top', 'bow/side', 'bow/below'],
         reads='a muscular root, a flared rim with radial creases, wrinkles running back, an inner sphincter, a ring of chitin spines, a dark '
               'bore, the bile gland glowing at its back', src='picture'),
    dict(id='pore_fields', job='sense: it tastes the dark through pore fields (no eyes; lore 5.8)', type='pore',
         what='dense pore fields over the head and the upper flanks', count=2, cells=['bow/top', 'bow/side', 'mid/top', 'mid/side'],
         reads='a raised rim round a sunk pit', src='picture'),
    dict(id='siphons', job='attitude: squirt to swing the head and the tail', type='thruster', what='puckered jet siphons, a pair forward and a pair aft',
         count=4, cells=['bow/side', 'stern/side'], reads='a muscle collar, a puckered lip, a dark bore', src='designed', note='the picture shows none'),
    # ---------------- the back ----------------
    dict(id='blade_row', job='ram blades: the bladeback closes fast and cuts into a hull with them (Razormaw, blood frenzy)', type='spine',
         what='the pale bone blade row down the centre of the back, tallest forward', count=1, cells=['bow/top', 'bow/side', 'mid/top', 'mid/side'],
         reads='transition tissue collars, raked blades with growth lines and serrated edges', src='picture'),
    dict(id='side_blades', job='guard the bile sacs and the upper flanks; they cut as the body rolls into a target', type='spine',
         what='smaller bone blades along each shoulder (the plan\'s separate pale plates)', count=2, cells=['bow/top', 'mid/top', 'mid/side'],
         reads='collars, raked blades with growth lines and serrated edges', src='picture'),
    dict(id='wound', job='the open groove the blades grow from: new bone pushes up through it (regrowth, regen 6)', type='wound',
         what='the raw channel along the spine with the blades in it', count=1, cells=['bow/top', 'mid/top'],
         reads='a channel of raw tissue between two lips', src='picture'),
    dict(id='mane', job='boarding tendrils (tendril T): lash and hold a hull at close range, the acid pores eat through its armour', type='mane',
         what='the plume of long tendrils rising from the back behind the blades and streaming aft', count=1, cells=['mid/top', 'mid/side', 'stern/top', 'stern/side'],
         reads='a muscle crest, hooked tendrils with grip rings, chitin barbs and acid pores', src='picture'),
    # ---------------- flanks ----------------
    dict(id='bile_sacs', job='bile reservoirs: store the bile the throats spit, fed forward by the veins', type='sac',
         what='three domed sacs a side on the flanks, in wrinkled sockets', count=6, cells=['bow/top', 'bow/side', 'mid/top', 'mid/side'],
         reads='a socket of wrinkle rolls, the dome, creases, veins, glow windows', src='picture'),
    dict(id='veins', job='carry bile from the sacs forward to the throat glands', type='vein', what='vein runs from the sacs to the throats', count=2,
         cells=['bow/side', 'mid/side'], reads='a raised vein, branches', src='designed', note='the picture shows the hide\'s grain; the veins say what the sacs are for'),
    dict(id='flank_folds', job='the body\'s muscle: it flexes the hull to turn and to bite', type='welt',
         what='long wrinkle folds along the flanks converging on the throats', count=1, cells=['bow/side', 'mid/side', 'stern/side', 'bow/below', 'mid/below'],
         reads='raised welts', src='picture'),
    dict(id='scars', job='regrowth (regen 6): wounds knitting shut', type='scar', what='scarred patches on the back and flanks', count=5,
         cells=['bow/top', 'mid/top', 'mid/side', 'stern/top'], reads='a raised irregular patch, knit ridges across it', src='picture'),
    # ---------------- the whole body ----------------
    dict(id='body', job='the body: holds the organs, the heart vat and the bile glands', type='hull',
         what='the short broad body, blunt at the bow, tapering to the stern', count=1,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='the wound ridge, flank folds, pore fields', src='picture'),
    dict(id='hide', job='the hide: callused pads with sense pores, the first thing a hit tears', type='plate', what='the hide over the whole body', count=1,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='callus pads, sense pores on them', src='picture'),
    # ---------------- stern ----------------
    dict(id='vents', job='drive (sp 4): six pulse vents push the body; no nozzles (factions.md)', type='engine',
         what='the stern filament plume with its glowing nodes', count=6, cells=['stern/top', 'stern/side', 'stern/below'],
         reads='a muscle cone, radial folds, a sphincter mouth, a dark throat, bile glow, filaments with glowing nodes', src='picture',
         note='the picture\'s amber nodes are the vent mouths'),
]

LEFT_PLAIN = [
    'Fine wrinkle grain, wet sheen, mottling and the colour of the hide: surface texture and paint (recipe stages 4 and 5), not modelled.',
    'The two escorts beside the cruiser in both pictures are their own ships, not part of this hull.',
    'The small spines along the lower stern in the side view are cut: they have no job (R221).',
]

STRUCTURE = {'bow/top': 4, 'bow/side': 3, 'bow/below': 2, 'mid/top': 6, 'mid/side': 5, 'mid/below': 3, 'stern/top': 3, 'stern/side': 3,
             'stern/below': 2}
STRUCTURE_NOTE = 'C11 sheet: bow = the two throats, the head, the first dome pair; mid = body, blade row, domes, mane; stern = taper, nodes, filaments'
