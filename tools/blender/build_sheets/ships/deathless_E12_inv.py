# deathless_E12 parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling.
# Read from contrib/muse/design/concept_round8c_2026_11/deathless_E12_beauty.jpg (from above, port and a little aft, the
# bow on the right) and deathless_E12_sheet.jpg (plan above, side view below, BOW ON THE RIGHT; the smaller ship at the right
# of each view is the escort, not this hull). The concept has no underside view. Fields as deathless_E11_inv.py.
KIT = 'eclipse'
INVENTORY = [
    # ---------------- bow (prow tip to 33 percent) ----------------
    dict(id='arcs', type='arc', what='the broken shade ring: flat box-section arcs on an oval round the spine, open at the bow and stern, '
         'an outer armoured wall with plates, the inner bay open on frames and machinery, a green-white corona line on every outer rim',
         count=8, cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='a channel section, a corona line, frames across the bay, machinery and conduits in it, plates', src='picture',
         note='the picture draws seven (one stern arc, starboard); the build has the matching port one'),
    dict(id='arc_plates', type='plate', what='plates over the arcs\' upper faces and outer walls', count=1, cells=['bow/top', 'mid/top', 'stern/top'],
         reads='chamfered slabs with steps and fasteners', src='picture'),
    dict(id='struts', type='strut', what='truss struts from the spine to the arcs (four in the picture; every arc gets its own, R207)', count=8,
         cells=['bow/top', 'mid/top', 'stern/top'], reads='two rails, a zigzag web, end lugs', src='picture',
         note='the picture shows four struts; the arcs it leaves floating get theirs (R207)'),
    dict(id='spine', type='hull', what='the spine: a long plated beam, stepped where it meets each fitting, overhanging the emitter housing', count=1,
         cells=['bow/top', 'bow/side', 'mid/top', 'mid/side', 'stern/top', 'stern/side'], reads='bevels, steps, an overhang', src='picture'),
    dict(id='spine_plates', type='plate', what='plate blocks along the spine', count=1, cells=['bow/top', 'mid/top', 'stern/top', 'bow/side', 'mid/side'],
         reads='chamfered slabs with steps and fasteners', src='picture'),
    dict(id='emitter', type='spinal', what='the bow emitter: a collared housing with a green lens (data.js doom F, the corona arc)', count=1,
         cells=['bow/top', 'bow/side'], reads='breech collars, segments, bands, rails, a muzzle block, a dark bore, a green lens', src='picture'),
    dict(id='main_guns', type='gun', what='two twin turrets on oval saddles on the spine, one either side of the core (data.js gauss T, gauss T)',
         count=2, cells=['bow/top', 'bow/side', 'mid/top', 'mid/side'],
         reads='hex plinths, faceted housings under stacked shade plates, mantlets, breeches, coiled barrels, ringed muzzles', src='picture'),
    dict(id='saddles', type='pylon', what='the oval saddles the turrets stand on', count=2, cells=['bow/side', 'mid/side'], reads='a stepped web, plates',
         src='picture'),
    # ---------------- midships ----------------
    dict(id='core', type='core', what='the caged green core at the centre of the ring', count=1, cells=['mid/top', 'mid/side', 'mid/below'],
         reads='hub collars, a bright sphere, gimbal rings, meridian bars', src='picture'),
    # ---------------- stern ----------------
    dict(id='stern_block', type='tier', what='the stern block: a broad faceted block tapering forward into the spine, the engines in its face', count=1,
         cells=['stern/top', 'stern/side', 'stern/below'], reads='faceted faces, a stepped roof, openings (lights, vents, hatches)', src='picture'),
    dict(id='engines', type='engine', what='three engines side by side in the stern block', count=3, cells=['stern/top', 'stern/side', 'stern/below'],
         reads='faceted ribbed drums, mount collars, vanes, short bells, a corona ring round a black shade disc (no flame)', src='picture'),
    dict(id='sentry', type='gun', what='the small turret on the stern block roof with green sights (data.js gsentry T, the null spire)', count=1,
         cells=['stern/top', 'stern/side'], reads='as the turrets, smaller', src='picture'),
    dict(id='block_lights', type='lamp', what='the green light panel on the stern block flanks', count=6, cells=['stern/side'],
         reads='a housing, a green-white bar lens', src='picture', note='the picture shows three on the near flank; matched on the far one'),
    dict(id='block_vents', type='vent', what='heat slot panels on the stern block flanks', count=2, cells=['stern/side'], reads='a frame, slats',
         src='designed'),
    dict(id='block_hatches', type='hatch', what='hatches on the stern block roof', count=2, cells=['stern/top'], reads='a rim, a door, a seam, hinges',
         src='designed'),
    dict(id='thrusters', type='thruster', what='attitude thrusters on the stern block and the spine head', count=4, cells=['bow/side', 'stern/side'],
         reads='a block, slot nozzles', src='designed'),
]
STRUCTURE = {'bow/top': 5, 'bow/side': 4, 'mid/top': 5, 'mid/side': 4, 'stern/top': 6, 'stern/side': 5}
STRUCTURE_NOTE = ('E12 sheet: bow, the two fore arcs, the emitter housing, the spine, the fore turret saddle; midships, the two centre arcs, the '
                  'core cage, the spine, the aft turret saddle; stern, the aft arcs and the stern arc, the stern block and its forward taper, the '
                  'sentry turret')
LEFT_PLAIN = [
    'Grime, scuffs and decals: surface texture, painted in the build (recipe stages 4 and 5), not modelled.',
    'The escort beside the cruiser in every picture is its own ship (a later fleet brief), not part of this hull.',
]
