# hegemony_O3 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling, plus what
# the designer adds with its job (R221). Read from contrib/muse/design/class_family_hegemony_2026_11/relay_sheet.webp (top view
# upper left drawn lens down, side view upper right lens left, front view below) and relay_beauty.webp (the lens toward the
# viewer), PR 1168. designs.md "RELAY BEACON" governs (picture slip: the front view draws the rails sideways).
# Fields: id, job, type (tools/blender/kits/hegemony/parts.py SUBPARTS), what, count, cells, reads, src (picture or designed).
KIT = 'hegemony'
ALL_TOP = ['bow/top', 'mid/top', 'stern/top']
ALL_SIDE = ['bow/side', 'mid/side', 'stern/side']
INVENTORY = [
    dict(id='module', job='holds the relay core, the emitter and the cooling plant', type='hull',
         what='one square relay module with chamfered edges', count=1, cells=['mid/top', 'mid/side'],
         reads='flat faces, chamfered edges, a stepped rear edge', src='picture'),
    dict(id='lens', job='the relay itself: the objective the fleets fight over (designs.md: ONE oversized recessed blue lens)', type='relay_lens',
         what='a recessed lens in the forward face, stepped machined rings, a thin blue ring at the mouth', count=1, cells=['bow/top', 'bow/side'],
         reads='a square face block, stepped rings, a glowing lens, corner bolts', src='picture'),
    dict(id='module_bands', job='the relay-ring module joints: the relay breaks into modules here', type='band',
         what='two raised trim rings with a deep seam', count=1, cells=['mid/top', 'mid/side'], reads='two trim rings and a dark seam ring', src='picture'),
    dict(id='rails', job='the twin-rail cradle frame: tenders moor on it and it carries the relay\'s power and signal lines', type='rail',
         what='four rails, two either side at two heights, running along the module', count=1, cells=ALL_TOP + ALL_SIDE,
         reads='a long chamfered beam, flush panels, end caps, blue light strips', src='picture'),
    dict(id='blue_line', job='implant-blue running lights along the rails (factions.md: a line of blue light)', type='band',
         what='short blue strips along each rail\'s outer face', count=1, cells=ALL_SIDE, reads='raised strips that glow', src='picture'),
    dict(id='cradle', job='clamps the rails to the module (designs.md: an open twin-rail cradle)', type='rail',
         what='a saddle on each side of the module\'s middle, an arm and a clamp round each rail', count=1, cells=['mid/top', 'mid/side'],
         reads='a saddle block, arms, clamp blocks with trim bands', src='picture'),
    dict(id='cradle_latches', job='lock each cradle clamp round its rail', type='latch', what='a latch pair on each rail clamp', count=4,
         cells=['mid/side'], reads='a base plate, machined clamp heads', src='designed'),
    dict(id='mooring', job='tugs and tenders make fast to the relay (designs.md: four mooring collars on the rails)', type='latch',
         what='a mooring collar with a latch on each rail', count=4, cells=['bow/side', 'stern/side'], reads='a trim sleeve round the rail, clamp heads', src='picture'),
    dict(id='mooring_collars', job='the collar sleeves the mooring latches sit on', type='band', what='a trim sleeve round each rail', count=1,
         cells=['bow/side', 'stern/side'], reads='a raised trim ring round the rail', src='picture'),
    dict(id='sensor_fin', job='the relay\'s own fleet link and station-keeping sensors', type='antenna', what='one low sensor fin aft on the module top', count=1,
         cells=['mid/top', 'mid/side'], reads='a root plinth, a raked fin, sensor windows, a lens strip', src='picture'),
    dict(id='thrusters', job='station keeping: the relay holds its place (designs.md: no propulsion)', type='thruster',
         what='eight small thruster pads on the module\'s chamfered edges', count=8, cells=['mid/side'],
         reads='a machined block, rectangular nozzle throats with depth', src='picture'),
    dict(id='module_panels', job='module armour: flush panels in the even grid', type='plate', what='flush panels on the module\'s flat faces', count=1,
         cells=['mid/top', 'mid/side'], reads='machined slabs with seams, two module sizes', src='picture'),
    dict(id='hatches', job='maintenance access to the relay core and the stores', type='hatch', what='a deck hatch and a belly hatch', count=2,
         cells=['mid/top'], reads='a rim, a flush door, a seam, a grip', src='designed'),
    dict(id='vents', job='the relay core\'s and the emitter\'s heat louvres', type='vent', what='louvres on the module top', count=4,
         cells=['mid/top'], reads='a machined frame, straight slats over a dark recess', src='designed'),
]
STRUCTURE = {'bow/top': 2, 'bow/side': 2, 'mid/top': 5, 'mid/side': 4, 'stern/top': 2, 'stern/side': 2}
STRUCTURE_NOTE = ('Relay sheet: forward, the lens face and the rail ends; midships, the module, the cradle and the fin; aft, the rail ends (the top view shows two rails, the upper over the lower)')
LEFT_PLAIN = [
    'Stencil marks and the steel-blue trim tone: paint (the Hegemony stack), not modelled.',
    'The lens ring\'s pulse: a game effect.',
]
INV_NOTES = {}
