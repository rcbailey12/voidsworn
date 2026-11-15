# deathless_E14 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling (issue 739;
# rewritten for the upright redesign, issue 782). Read from the WHOLE concept first (R229):
# contrib/muse/design/class_family_deathless_2026_11/deathless_E14_flare.jpg (from ahead and to port: the ring upright and nearly
# face-on, the gun heart's big muzzle at its centre lower left, the spar running aft to the engine's pale ring upper right),
# deathless_E14_flare_sheet.jpg (middle: the ring upright and edge-on from the beam; right: the ring face-on from ahead with the
# muzzle at its centre; left: the ring drawn face-on across the spar, which does not agree with the other two) and the line-up
# (contrib/muse/design/class_family_deathless_2026_11/deathless_family_lineup.jpg).
# Design rulings that bind: one closed ring (R233); R256 (Ryan, Nov 15): the ring stands upright as in the concept and the ship
# is built round one larger gun at the ring's centre, "like a glass cannon"; data.js d_jackal after issue 784: one null lance,
# nlance F. The concept has no underside view. Fields as deathless_E11_inv.py.
KIT = 'eclipse'
VARIANT_INVENTORY = {
    'd_jackal_h': [dict(id='guard_spire', job='shoot down squadrons and boarding craft on every side (gsentry T)',
                       type='spire', what='a turning null spire on the capacitor housing', count=1, cells=['mid/top', 'mid/side'],
                       reads='a bearing foot, banded spire, sight slits, head shade and twin needle rails', src='designed')],
}
INVENTORY = [
    # ---------------- bow (the nose to 33 percent) ----------------
    dict(id='ring', job='the shade held forward at the enemy and the lance\'s focusing ring: one closed ring of curved shade plates round the gun\'s muzzle; its plates peel first when hit',
         type='shade', what='the ring: twelve large curved shade plates on one closed hoop, narrow even gaps between them, standing upright across the bow, '
         'each plate a deep block with a dished front, a stepped second layer and green-white corona lines on its rim\'s front and back edges', count=12,
         cells=['bow/top', 'bow/side', 'bow/below'],
         reads='a deep curved block, an inner and an outer armour block on its face, a rim band, corona lines on its rim and down its sides, even panels', src='picture',
         note='the beauty and the sheet draw twelve; R233 closes the ring all the way round; R256 stands it upright'),
    dict(id='ring_plates', job='armour over the shade plates', type='plate', what='even, aligned panels over the shade plates\' fronts, backs and rims (R243)', count=1,
         cells=['bow/top', 'bow/side'], reads='chamfered slabs with steps and flush fasteners', src='picture'),
    dict(id='hoop', job='the closed structural ring that carries the twelve plates (R233, R207)', type='belt',
         what='the hoop: one closed box-section ring under the plates\' inner edges', count=1,
         cells=['bow/side', 'bow/top'], reads='a band, plates', src='designed',
         note='the picture leaves the plates floating; R207: every shade has a structural connection'),
    dict(id='spokes', job='carry the hoop to the gun heart\'s focus collar (R207)', type='strut', what='truss spokes from the focus collar to the hoop, in an X', count=4,
         cells=['bow/side', 'bow/top'], reads='two rails, a zigzag web, end lugs', src='designed'),
    dict(id='gun_heart', job='the lance\'s breech casing: carries the lance through the ring\'s centre, its capacitors and magazine, and the focus collar the spokes land on', type='tier',
         what='the gun heart: a faceted drum from the core forward through the ring\'s centre, a capacitor band and the focus collar round it', count=1,
         cells=['bow/top', 'bow/side', 'mid/top', 'mid/side'], reads='faceted faces, a stepped roof, openings (the lance\'s seat)', src='picture'),
    dict(id='lance', job='the null lance (data.js nlance F, issue 784): the one big gun, firing forward through the ring\'s centre (the glass cannon, R256)',
         type='nullcannon', what='the null lance on the gun heart\'s face, its muzzle the ship\'s bow at the ring\'s centre', count=1, cells=['bow/top', 'bow/side'],
         reads='a seat ring, an eight-sided armoured housing with a layer sleeve, capacitor discs, four accelerator rails on yokes with banded collars, '
               'a steel muzzle lip, a green focus ring, a recessed bore with a black shade disc and a glowing lens (R221, designs.md)', src='picture',
         note='the beauty\'s big round muzzle at the ring\'s heart; designs.md: a fixed forward housing with a recessed aperture and a thin green focus ring, never a protruding tube'),
    dict(id='nose_thrusters', job='attitude control forward', type='thruster', what='attitude thrusters under the spar behind the core', count=2,
         cells=['mid/side'], reads='a block, slot nozzles', src='designed', note='on the gun heart they would fire into the ring\'s lower plates'),
    # ---------------- midships ----------------
    dict(id='core', job='the trapped light core: powers the ship and its phase and regeneration (data.js ab phase, regen 2)', type='core',
         what='the bright core just aft of the ring\'s centre, the spar and the gun heart entering its hub collars', count=1, cells=['mid/top', 'mid/side', 'mid/below'],
         reads='hub collars, a bright sphere, gimbal rings, meridian bars', src='picture'),
    dict(id='cage', job='the broken cage of small shade plates that shields the core (designs.md)', type='feather',
         what='small curved shade plates round the core\'s hub, broken by gaps the light shows through', count=6, cells=['mid/top', 'mid/side'],
         reads='a blade, a thickness step', src='picture'),
    dict(id='spar', job='the keel beam: carries the core, the capacitor housing and the stern block', type='hull',
         what='the body: a chunky faceted beam in steps from the core to the stern block (R266: never a stick)', count=1,
         cells=['mid/top', 'mid/side', 'stern/top', 'stern/side'], reads='bevels, steps, an overhang', src='picture'),
    dict(id='flank_armour', job='armour the body\'s flanks and keel in layers (R266: a plated, stepped body)', type='hull',
         what='layered armour slabs down both flanks with a second step on each, a keel along the belly, collars at the body\'s steps', count=1,
         cells=['mid/side', 'mid/top', 'stern/side'], reads='bevels, steps, an overhang', src='picture', note='the beauty\'s heavy plated body'),
    dict(id='core_windows', job='show the core\'s glow from ahead, through the gun heart (R266)', type='corewin',
         what='four armoured core windows on the gun heart\'s forward shoulder', count=4, cells=['bow/top', 'bow/side'],
         reads='a rim, set-back glass that glows, grille bars', src='picture', note='the beauty\'s core glowing in the heart behind the muzzle'),
    dict(id='hoop_lights', job='light the ring\'s open middle (R266)', type='lamp',
         what='twelve small lights on the hoop\'s inner face, one behind each plate, and a light strip round it', count=12, cells=['bow/top', 'bow/side'],
         reads='a housing, a green-white bar lens', src='picture', note='the beauty\'s lit middle with its small drone lights'),
    dict(id='spar_plates', job='armour over the spar', type='plate', what='even, aligned panels along the spar', count=1,
         cells=['mid/top', 'mid/side', 'stern/top'], reads='chamfered slabs with steps and flush fasteners', src='picture'),
    dict(id='drone_docks', job='dock the repair drones that mend the ring (data.js regen 2, reanimate)', type='hatchbox',
         what='repair drone cradles docked on the hoop\'s front face', count=4, cells=['bow/top', 'bow/side'], reads='a frame, a lid, ribs',
         src='picture', note='the picture shows drones hovering in the gaps; built docked, so every part sits on the ship'),
    dict(id='drone_lights', job='the drones\' green work lights', type='lamp', what='a green light on each drone cradle', count=4,
         cells=['bow/top', 'bow/side'], reads='a housing, a green-white bar lens', src='picture'),
    # ---------------- stern ----------------
    dict(id='capbank', job='store the core\'s charge for the lance\'s one big shot (the glass cannon)', type='pylon',
         what='the stepped capacitor housing on the spar\'s dorsal line aft of the core, three ribs across it', count=1,
         cells=['mid/top', 'mid/side', 'stern/side'], reads='a stepped web, plates', src='picture',
         note='the beauty\'s low dorsal housing on the spar; the first sheet seated the aft gun there, gone with issue 784'),
    dict(id='stern_block', job='holds the engine, the engine room and the archive vault', type='tier',
         what='the stern block: a faceted chamfered block where the spar thickens before the engine', count=1,
         cells=['stern/top', 'stern/side', 'stern/below'], reads='faceted faces, a stepped roof, openings (vents, hatches, lights)', src='picture'),
    dict(id='engine', job='drive (sp 3): one eclipse-ring engine, larger than the frigate\'s, no flame', type='engine',
         what='one engine at the stern: the broad eclipse ring of pale light', count=1, cells=['stern/top', 'stern/side', 'stern/below'],
         reads='a faceted ribbed drum, a mount collar, vanes, a short bell, a corona ring round a black shade disc (no flame), a free halo ring of pale light on four arms', src='picture',
         note='R266: the beauty\'s big glowing ring at the end of the body is the engine\'s halo'),
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
STRUCTURE = {'bow/top': 3, 'bow/side': 3, 'mid/top': 3, 'mid/side': 3, 'stern/top': 3, 'stern/side': 3}
STRUCTURE_NOTE = ('E14 concept: bow, the ring\'s plates, the hoop and spokes, the gun heart and its muzzle; midships, the core in its cage, the '
                  'spar, the dorsal housing; stern, the spar, the stern block and the engine ring')
LEFT_PLAIN = [
    'Grime, scuffs and decals: surface texture, painted in the build (recipe stages 4 and 5), not modelled.',
    'The concept sheet\'s left view draws the ring face-on across the spar; it does not agree with the beauty or the sheet\'s other two views, which stand the ring upright (R256).',
]
