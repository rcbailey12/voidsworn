# deathless_E13 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling (issue 739).
# Read from the WHOLE concept first (R229): contrib/muse/design/class_family_deathless_2026_11/deathless_E13_mote.jpg (from
# above and ahead of the port beam: the dart's nose lower left, the engine's pale ring upper right), deathless_E13_mote_sheet.jpg
# (left: the plan, BOW ON THE LEFT, the engine ring on the right; middle: the side view, bow left; right: a front view that does
# not agree with the other two) and the round 1 Fan direction (contrib/muse/design/concept_directions_2026_11/deathless_B.jpg).
# The pictures agree with each other and not with designs.md on one point: the plates gather at the STERN, by the engine
# collar, and their tips reach FORWARD past the nose's flanks (designs.md says rooted at the bow); the build follows the
# accepted pictures and says so on the sheet. The concept has no underside view. Fields as deathless_E11_inv.py.
KIT = 'eclipse'
INVENTORY = [
    # ---------------- bow (nose tip to 33 percent) ----------------
    dict(id='fan', job='the shade: five layered plates held forward over the body, the faction\'s sunshade toward the enemy; they peel first when hit',
         type='shade', what='the fan: five long overlapping shade plates (a crest plate on the spine, two a side), gathered at the stern by the engine collar and '
         'fanning forward over the body, their tips reaching past the nose\'s flanks; each a separate slab with a stepped second layer on its root half and '
         'a thin green-white corona line along its outer rim', count=5,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side'],
         reads='a broad curved band, a stepped layer, a corona line on the rim, even panels', src='picture',
         note='designs.md says five; the beauty and the sheet show more blade edges, which here are the plates\' stepped layers'),
    dict(id='fan_plates', job='armour over the shade plates', type='plate', what='even, aligned panels over the plates\' upper faces (R243)', count=1,
         cells=['bow/top', 'mid/top', 'stern/top'], reads='chamfered slabs with steps and flush fasteners', src='picture'),
    dict(id='body', job='the dart: carries the core, the crew decks and the archive vault under the fan', type='hull',
         what='the short dart body under the fan: a chamfered faceted section, a pointed nose ahead of the plate tips', count=1,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/side', 'mid/below'], reads='bevels, steps, an overhang', src='picture'),
    dict(id='body_plates', job='armour over the dart', type='plate', what='even, aligned panels along the dart', count=1,
         cells=['bow/side', 'bow/below', 'mid/below'], reads='chamfered slabs with steps and flush fasteners', src='picture'),
    dict(id='nose_thrusters', job='attitude control at the bow: turn the frigate quickly (speed 4, evasion 14)', type='thruster',
         what='attitude thrusters on the dart\'s nose flanks', count=2, cells=['bow/side'], reads='a block, slot nozzles', src='designed'),
    # ---------------- midships ----------------
    dict(id='core', job='the trapped light core: powers the ship and its phase and regeneration (data.js ab phase, regen 2)', type='core',
         what='the bright core in the gap between the crest plate and the inner plates, partly covered', count=1, cells=['mid/top', 'mid/side'],
         reads='hub collars, a bright sphere, gimbal rings, meridian bars', src='picture'),
    dict(id='lamps', job='the corona strip lights along the dart: the faction\'s only lights besides the corona, the core and the engine ring', type='lamp',
         what='corona strip lights low on the dart\'s flanks', count=4, cells=['mid/side', 'bow/side'], reads='a housing, a green-white bar lens', src='designed'),
    # ---------------- stern ----------------
    dict(id='stern_block', job='holds the engine, the engine room, the gun\'s magazine and the fan\'s roots', type='tier',
         what='the stern block: a faceted chamfered block behind the core, a stepped roof under the gun', count=1,
         cells=['stern/top', 'stern/side', 'stern/below'], reads='faceted faces, a stepped roof, openings (vents, hatches)', src='picture'),
    dict(id='root_collar', job='gathers and carries the five plates\' roots on the stern block', type='pylon',
         what='the root collar: a stepped band round the stern block where the plates gather', count=1, cells=['stern/top', 'stern/side'],
         reads='a stepped web, plates', src='picture'),
    dict(id='main_gun', job='the null cannon (gauss T): the frigate\'s one weapon, an armour-piercing rail gun that turns all round', type='nullcannon',
         what='the one gun: a low housing on the spine at the fan\'s root, firing forward over the plates (data.js gauss T)', count=1,
         cells=['stern/top', 'stern/side'],
         reads='a thin round foot, a small oval shell, an arched crescent shade of seamed bevelled plates with a second layer and a corona crest, '
               'rod yokes, crescent capacitor fins, two slim round rail pairs with banded collars and shock rings (R221)', src='picture',
         note='the beauty underplays it (designs.md); the sheet draws it on the spine at the fan\'s root'),
    dict(id='engine', job='drive (sp 4, the fastest Eclipse hull): one eclipse-ring engine, no flame', type='engine',
         what='one engine at the stern: the small thin eclipse ring of pale light', count=1, cells=['stern/top', 'stern/side', 'stern/below'],
         reads='a faceted ribbed drum, a mount collar, vanes, a short bell, a corona ring round a black shade disc (no flame)', src='picture'),
    dict(id='stern_thrusters', job='attitude control at the stern', type='thruster', what='attitude thrusters on the stern block\'s flanks', count=2,
         cells=['stern/side'], reads='a block, slot nozzles', src='designed'),
    dict(id='vents', job='dump heat from the engine room', type='vent', what='heat slot panels on the stern block\'s flanks', count=2,
         cells=['stern/side'], reads='a frame, slats', src='designed'),
    dict(id='hatches', job='crew and drone access to the stern block', type='hatch', what='hatches on the stern block\'s belly', count=2,
         cells=['stern/below'], reads='a rim, a door, a seam, hinges', src='designed'),
]
STRUCTURE = {'bow/top': 4, 'bow/side': 3, 'mid/top': 5, 'mid/side': 4, 'stern/top': 4, 'stern/side': 4}
STRUCTURE_NOTE = ('E13 concept: bow, the plate tips (two a side) and the nose; midships, the crest plate, two plates a side and the core '
                  'gap, the dart; stern, the stern block, the plates\' roots gathering, the gun housing and the engine ring')
LEFT_PLAIN = [
    'Grime, scuffs and decals: surface texture, painted in the build (recipe stages 4 and 5), not modelled.',
    'The concept sheet\'s front view (a tall pinwheel of blades) does not agree with its own plan and side view; the build follows the plan, the side view and the beauty.',
]
