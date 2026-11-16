# corsair_KB1CC parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling, plus what the
# designer adds with its job (R221). Read from contrib/muse/design/squadron_concepts_2026_11/hullbreakers/round_3/KB1CC.jpg (one
# three-quarter view from ahead and above: the glacis toward the viewer, the corner mouths left and right, the thruster row at the
# back) and design_notes_785_round3.md (the KB1C-C sheet, the production notes and the owner's ruling). The concept has no
# underside and no true views. A craft is bold and simple: fine greeble reads as a shrunken capital ship, so every line has a job.
# Fields: id, job (what the part does on the craft, R221), type (tools/blender/kits/hullbreakers/parts.py SUBPARTS, plus the craft
# parts in craft.py), what, count, cells, reads (the sub-parts that make it read as that thing), src (picture or designed).
KIT = 'hullbreakers'
INVENTORY = [
    # ---------------- bow (toe to 33 percent): the glacis and the corner mouths ----------------
    dict(id='body', job='the craft\'s main body: the glacis armour over the crew, the lid over the reactor, the stern housing over the drives', type='hull',
         what='one wide low body: a continuous shallow glacis from the bow toe up to the lip, the flat lid, a step up to the stern housing; a flat belly with chines',
         count=1, cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='the glacis slope and its step to the lid, the chamfers, the stern housing\'s step up', src='picture'),
    dict(id='glacis_plates', job='the glacis and lid armour: scrap plate in uneven courses, patches over the joints', type='plate',
         what='patched plates in courses over the glacis, the lid and the flanks', count=1, cells=['bow/top', 'bow/side', 'mid/top', 'mid/side', 'stern/top'],
         reads='slabs with bevels, thickness steps, patches over joints, rivets on a share', src='picture'),
    dict(id='belly_plates', job='the belly\'s armour', type='plate', what='patched plates over the flat belly', count=1, cells=['bow/below', 'mid/below', 'stern/below'],
         reads='slabs with bevels and steps', src='designed', note='the concept shows no underside'),
    dict(id='bomb_tubes', job='the bomb payload (data.js bombs T, 2 shots): the wing\'s only weapon, one tube a corner, both firing every volley', type='bomb_tube',
         what='two bomb tubes at the glacis\'s extreme corners, each in a dark armoured collar on an eight-sided drum', count=2, cells=['bow/top', 'bow/side', 'bow/below'],
         reads='the dark collar with welded bolts, the bore, the bomb nose seated deep inside, the drum, two riveted bands, a welded patch (R221)',
         src='picture', note='the concept\'s two round corner mouths'),
    dict(id='rails', job='the armoured edge frames that stiffen the glacis plate and guard the lid\'s edges', type='rib',
         what='a raised rail along each top edge of the body, from the bow toe up the glacis and along the lid, with bolted clamps', count=1,
         cells=['bow/top', 'mid/top', 'stern/top'], reads='the rail, its clamp brackets', src='picture', note='the concept\'s raised glacis edges'),
    dict(id='lip', job='the armoured lip that ends the glacis (against the ramp read) and carries the crew\'s vision slit', type='tier',
         what='a shallow armoured lip across the top of the glacis', count=1, cells=['bow/top', 'mid/top'], reads='its sloped face, its roof, the slit opening',
         src='picture', note='the round 3 sheet (DeepSeek)'),
    dict(id='vision_slit', job='the crew\'s view out (no canopy, R254): the bombardier aims the craft', type='slit',
         what='one vision slit in the lip\'s face, a little to port', count=1, cells=['bow/top'], reads='a welded frame round a dark pane', src='designed'),
    # ---------------- midships (33 to 66 percent): the shoulders and the hoist bays ----------------
    dict(id='shoulders', job='the side bodies behind the corner pods: each holds a bomb row (the magazine) and its hoist', type='tier',
         what='a shoulder either side, its top sloping down and out to a thin edge; the starboard one a touch lower and shorter (lopsided)', count=1,
         cells=['bow/top', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side'], reads='the sloped top, the thin outer edge, the chamfered belly', src='picture'),
    dict(id='shoulder_plates', job='the shoulders\' armour', type='plate', what='patched plates in courses over the shoulders', count=1, cells=['mid/top', 'mid/side', 'stern/top'],
         reads='slabs with bevels, thickness steps, patches over joints', src='picture'),
    dict(id='hoist_bays', job='the bomb hoists: they walk the next bomb from the magazine row into its tube, behind armoured doors', type='machbay',
         what='one machinery bay in each shoulder\'s sloped top, a door in a second tone over its fore part', count=2, cells=['mid/top', 'mid/side'],
         reads='a heavy frame, a dark back, pipes, the hoist block, the door on hinges (two-tone so it survives 32 px, Qwen)', src='picture',
         note='the concept\'s recessed side bays with armoured doors'),
    # ---------------- stern (66 to 100 percent): the thruster bank ----------------
    dict(id='drives', job='drive (sp 5): the stern thruster bank, nozzle clusters inside an armoured block (the owner\'s rule for craft)', type='engine',
         what='five mismatched salvaged bells, the centre one the largest', count=5, cells=['stern/top', 'stern/side', 'stern/below'],
         reads='a bell with a lip, an ember lining, a glowing throat and plug, a cooling ring, a drum with a collar and a band, gimbal struts', src='picture'),
    dict(id='bank_recess', job='the armoured recess round the thruster bank', type='pylon', what='a hood over the bank, cheeks at its sides, a sill under it', count=1,
         cells=['stern/top', 'stern/side'], reads='the welded web plates and their faces', src='picture', note='the concept\'s recessed stern bank'),
]
STRUCTURE = {'bow/top': 4, 'bow/side': 3, 'mid/top': 4, 'mid/side': 3, 'stern/top': 3, 'stern/side': 3}
STRUCTURE_NOTE = ('KB1C-C render, by eye (no true views): bow, the glacis, its two rails and the two corner mouths; midships, the lid, the rails, '
                  'the side bays and the shoulders; stern, the lid, the raised housing and the thruster row')
LEFT_PLAIN = [
    'The plate colours (rust, soot, dried blood, the trophy greys and violets), wear and the red running lights: the Hullbreaker paint stack (applied later); the sheet models the plates.',
    'Dishes, claws, antennas and lamps: nothing hangs off (factions.md), and below what the battle camera shows on a 3.84 unit craft; not built.',
]
INV_NOTES = {}
