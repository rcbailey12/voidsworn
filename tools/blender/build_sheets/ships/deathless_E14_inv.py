# deathless_E14 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling (issue 739).
# Read from the WHOLE concept first (R229): contrib/muse/design/class_family_deathless_2026_11/deathless_E14_flare.jpg (from
# ahead and above: the gun heart lower left, the spar running aft to the engine's pale ring upper right),
# deathless_E14_flare_sheet.jpg (left: the ring flat round the spar, BOW ON THE LEFT; middle and right: views that do not agree
# with the left one or with each other) and the line-up (contrib/muse/design/class_family_deathless_2026_11/deathless_family_lineup.jpg).
# Design rulings that bind: one closed ring (R233), never read from above as a small zenith (E12, the split oval ring); the
# ring's plane is the Board's study (tools/blender/build_sheets/studies/e14_ring_study.py): flat in plan reads as one closed
# ring from above and at every battle camera bearing. The concept has no underside view. Fields as deathless_E11_inv.py.
KIT = 'eclipse'
INVENTORY = [
    # ---------------- bow (the nose to 33 percent) ----------------
    dict(id='ring', job='the shade: one closed ring of curved shade plates round the gun heart, the faction\'s sunshade; its plates peel first when hit',
         type='shade', what='the ring: twelve large curved shade plates on one closed hoop, narrow even gaps between them, flat in plan round the spar, '
         'each plate a slab with a stepped second layer and a thin green-white corona line along its outer rim', count=12,
         cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='a broad curved band, a stepped layer, a corona line on the rim, even panels', src='picture',
         note='the beauty and the plan draw twelve; R233 closes the ring all the way round'),
    dict(id='ring_plates', job='armour over the shade plates', type='plate', what='even, aligned panels over the shade plates (R243)', count=1,
         cells=['bow/top', 'mid/top', 'stern/top'], reads='chamfered slabs with steps and flush fasteners', src='picture'),
    dict(id='hoop', job='the closed structural ring that carries the twelve plates and joins the spar at the bow and stern (R233, R207)', type='belt',
         what='the hoop: one closed box-section ring under the plates\' inner edges', count=1,
         cells=['bow/top', 'bow/below', 'mid/top', 'mid/below', 'stern/top', 'stern/below'], reads='a band, plates', src='designed',
         note='the picture leaves the plates floating; R207: every shade has a structural connection'),
    dict(id='spokes', job='carry the hoop to the gun heart at the beams (R207)', type='strut', what='truss spokes from the heart\'s hub collars to the hoop', count=4,
         cells=['mid/top', 'mid/below'], reads='two rails, a zigzag web, end lugs', src='designed'),
    dict(id='gun_heart', job='the heart at the ring\'s centre: carries the forward gun, the core and the capacitor bank', type='tier',
         what='the gun heart: a faceted drum on the spar at the ring\'s centre, stepped down to the spar at both ends', count=1,
         cells=['bow/top', 'bow/side', 'mid/top', 'mid/side'], reads='faceted faces, a stepped roof, openings (core gaps)', src='picture'),
    dict(id='fwd_gun', job='the forward null cannon (gauss F): an armour-piercing rail gun over the ring\'s bow plates, turning only through the data arc F',
         type='nullcannon', what='the forward gun on the gun heart\'s roof (data.js gauss F)', count=1, cells=['bow/top', 'bow/side'],
         reads='a thin round foot, a small oval shell, an arched crescent shade of seamed bevelled plates with a second layer and a corona crest, '
               'rod yokes, crescent capacitor fins, two slim round rail pairs with banded collars and shock rings (R221)', src='picture',
         note='designs.md: a recessed housing; the game\'s gauss is the null cannon on a turret (weapon_match.FITS), limited here to the F arc'),
    dict(id='nose_thrusters', job='attitude control at the bow', type='thruster', what='attitude thrusters on the spar\'s nose flanks', count=2,
         cells=['bow/side'], reads='a block, slot nozzles', src='designed'),
    # ---------------- midships ----------------
    dict(id='core', job='the trapped light core: powers the ship and its phase and regeneration (data.js ab phase, regen 2)', type='core',
         what='the bright core at the ring\'s centre, the spar entering its hub collars', count=1, cells=['mid/top', 'mid/side', 'mid/below'],
         reads='hub collars, a bright sphere, gimbal rings, meridian bars', src='picture'),
    dict(id='cage', job='the broken cage of small shade plates that shields the core (designs.md)', type='feather',
         what='small curved shade plates round the core\'s hub, broken by gaps the light shows through', count=4, cells=['mid/top', 'mid/side'],
         reads='a blade, a thickness step', src='picture'),
    dict(id='spar', job='the keel beam: carries the heart, the gun saddle and the stern block', type='hull',
         what='the layered spar: a slim chamfered beam from the nose to the stern block', count=1,
         cells=['bow/side', 'mid/top', 'mid/side', 'stern/top', 'stern/side'], reads='bevels, steps, an overhang', src='picture'),
    dict(id='spar_plates', job='armour over the spar', type='plate', what='even, aligned panels along the spar', count=1,
         cells=['mid/top', 'mid/side', 'stern/top'], reads='chamfered slabs with steps and flush fasteners', src='picture'),
    dict(id='drone_docks', job='dock the repair drones that mend the ring (data.js regen 2, reanimate)', type='hatchbox',
         what='repair drone cradles docked on the hoop\'s inner face', count=4, cells=['mid/top', 'bow/top', 'stern/top'], reads='a frame, a lid, ribs',
         src='picture', note='the picture shows drones hovering in the gaps; built docked, so every part sits on the ship'),
    dict(id='drone_lights', job='the drones\' green work lights', type='lamp', what='a green light on each drone cradle', count=4,
         cells=['mid/top', 'bow/top', 'stern/top'], reads='a housing, a green-white bar lens', src='picture'),
    # ---------------- stern ----------------
    dict(id='aft_gun', job='the aft null cannon (gauss T): an armour-piercing rail gun that turns all round, firing over the ring', type='nullcannon',
         what='the low gun housing on the spar\'s dorsal line aft of the ring (data.js gauss T)', count=1, cells=['stern/top', 'stern/side'],
         reads='a thin round foot, a small oval shell, an arched crescent shade of seamed bevelled plates with a second layer and a corona crest, '
               'rod yokes, crescent capacitor fins, two slim round rail pairs with banded collars and shock rings (R221)', src='picture'),
    dict(id='saddle', job='seat the aft gun on the slim spar and carry its feed', type='pylon', what='the stepped saddle under the aft gun', count=1,
         cells=['stern/side'], reads='a stepped web, plates', src='designed'),
    dict(id='stern_block', job='holds the engine, the engine room and the archive vault', type='tier',
         what='the stern block: a faceted chamfered block where the spar thickens before the engine', count=1,
         cells=['stern/top', 'stern/side', 'stern/below'], reads='faceted faces, a stepped roof, openings (vents, hatches, lights)', src='picture'),
    dict(id='engine', job='drive (sp 3): one eclipse-ring engine, larger than the frigate\'s, no flame', type='engine',
         what='one engine at the stern: the broad eclipse ring of pale light', count=1, cells=['stern/top', 'stern/side', 'stern/below'],
         reads='a faceted ribbed drum, a mount collar, vanes, a short bell, a corona ring round a black shade disc (no flame)', src='picture'),
    dict(id='stern_thrusters', job='attitude control at the stern', type='thruster', what='attitude thrusters on the stern block\'s flanks', count=2,
         cells=['stern/side'], reads='a block, slot nozzles', src='designed'),
    dict(id='lamps', job='the corona strip lights along the spar: the faction\'s only lights besides the corona, the core and the engine ring', type='lamp',
         what='corona strip lights on the stern block\'s flanks (the beauty\'s green lights along the spar)', count=4, cells=['stern/side'],
         reads='a housing, a green-white bar lens', src='picture'),
    dict(id='vents', job='dump heat from the engine room', type='vent', what='heat slot panels on the stern block\'s flanks', count=2,
         cells=['stern/side'], reads='a frame, slats', src='designed'),
    dict(id='hatches', job='crew access to the stern block', type='hatch', what='hatches on the stern block\'s belly', count=2,
         cells=['stern/below'], reads='a rim, a door, a seam, hinges', src='designed'),
]
STRUCTURE = {'bow/top': 4, 'bow/side': 3, 'mid/top': 5, 'mid/side': 4, 'stern/top': 4, 'stern/side': 4}
STRUCTURE_NOTE = ('E14 concept: bow, the ring\'s bow plates, the gun heart and its gun, the nose; midships, the ring\'s side plates, the core '
                  'in its cage, the spar; stern, the ring\'s stern plates, the spar, the dorsal gun housing, the stern block and the engine ring')
LEFT_PLAIN = [
    'Grime, scuffs and decals: surface texture, painted in the build (recipe stages 4 and 5), not modelled.',
    'The concept sheet\'s middle and right views (the ring edge-on and upright) do not agree with its plan or the beauty; the ring\'s plane is the study\'s pick.',
]
