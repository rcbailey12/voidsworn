# hegemony_HF1D parts inventory (R218): every feature the concept shows, region by region, written BEFORE modelling, plus what the
# designer adds with its job (R221). Read from contrib/muse/design/squadron_concepts_2026_11/hegemony/round_3/HF1D.jpg (the slimmed
# render: one three-quarter view from above and to port of the prow, the stern upper right) and design_notes_785_round3.md (the
# sheet, the production notes and the owner's rulings). The concept has no underside and no true views. A craft is bold and simple:
# fine greeble reads as a shrunken capital ship, so the list is short and every line has a job.
# Fields: id, job (what the part does on the craft, R221), type (tools/blender/kits/hegemony/parts.py SUBPARTS), what, count,
# cells, reads (the sub-parts that make it read as that thing), src (picture or designed).
KIT = 'hegemony'
INVENTORY = [
    # ---------------- bow (point to 33 percent): the slim prow, the framed recess and the cassette ----------------
    dict(id='wedge', job='the craft\'s one body: it carries the guns, the pilot, the reactor and the drive, and meets fire point first', type='hull',
         what='one sleek machined wedge: a flat deck, a stepped flank, a flat belly; a slim prow point widening to the stern third, the stern corners cut',
         count=1, cells=['bow/top', 'bow/side', 'bow/below', 'mid/top', 'mid/side', 'mid/below', 'stern/top', 'stern/side', 'stern/below'],
         reads='the deck chamfer, the three flank layers, the belly chamfer (no wing: the hull keeps HF1C\'s depth)', src='picture'),
    dict(id='wedge_panels', job='the hull\'s armour: flush machined panels in an even grid (two module sizes)', type='plate',
         what='flush panels over the deck and the flank layers', count=1, cells=['bow/top', 'bow/side', 'mid/top', 'mid/side', 'stern/top', 'stern/side'],
         reads='flush slabs with machined chamfers and seam gaps, every third row split in four', src='picture'),
    dict(id='belly_panels', job='the belly\'s armour', type='plate', what='flush panels over the flat belly', count=1, cells=['bow/below', 'mid/below', 'stern/below'],
         reads='flush slabs with machined chamfers and seam gaps', src='designed', note='the concept shows no underside'),
    dict(id='guns', job='the interceptor guns (data.js guns T, 3 shots): the wing\'s only weapon', type='gun',
         what='three barrels grouped tight in one cassette on a flush ring, sunk in a framed recess at the prow', count=1, cells=['bow/top', 'bow/side'],
         reads='the framed recess, a flush ring, a low flat housing, a mantlet, the cassette box with coil bands and a trim mouth, three barrels with coil rings, muzzles, dark bores and blue lenses (R221)',
         src='picture', note='the concept\'s cassette of three grouped muzzles in one framed recess'),
    dict(id='sensor_slit', job='the pilot\'s view out: no canopy (Ryan, R254), a slit in its own slot above the recess', type='slit',
         what='one dark sensor slit in the ridge\'s sloped front face', count=1, cells=['bow/top'],
         reads='a machined trim frame round a recessed pane', src='picture', note='the render lights it blue; the sheet keeps it dark (round 3 notes)'),
    # ---------------- midships (33 to 66 percent): the ridge and the edging ----------------
    dict(id='ridge', job='the spine: the armoured run that carries power and the pilot\'s cell from the bow block to the reactor', type='spine',
         what='a low broad flat-topped ridge, squared in section, no taller than the stern block', count=1, cells=['bow/top', 'mid/top', 'mid/side', 'stern/top'],
         reads='the flat top and its chamfers, the sloped front face, the side walls', src='picture'),
    dict(id='ridge_panels', job='the ridge\'s armour', type='plate', what='flush panels over the ridge\'s top and sides', count=1, cells=['mid/top', 'stern/top'],
         reads='flush slabs with machined chamfers and seam gaps', src='picture'),
    dict(id='edging', job='the stepped plate edging (HF1B): the flank armour laid in three stepped layers, each over the one above it', type='rail',
         what='three stepped flank layers along the whole hull, flush and shallow', count=1, cells=['bow/side', 'mid/side', 'stern/side'],
         reads='the steps between layers, each layer\'s face, the blue line on the upper step', src='picture'),
    dict(id='blue_line', job='the faction\'s running light: the implant-blue line that pulses in time across the fleet (factions.md)', type='band',
         what='implant-blue strips along the upper edging step and the ridge\'s foot', count=1, cells=['bow/side', 'mid/side', 'mid/top', 'stern/side'],
         reads='thin raised light strips', src='picture', note='the concept\'s blue glow along the edging and the ridge'),
    dict(id='module_bands', job='the joints between the craft\'s modules, where it gives way (factions.md: in modules)', type='band',
         what='three trim bands round the hull: at the bow block, midships and the stern block', count=1, cells=['bow/top', 'mid/top', 'stern/top', 'mid/side'],
         reads='a raised trim band, its seam', src='designed', note='the concept\'s cross seams in the panel grid'),
    # ---------------- stern (66 to 100 percent): the stern block and the drive ----------------
    dict(id='stern_block', job='the armoured block across the stern: it holds the reactor and the drive', type='tier',
         what='a raised block across the stern, a sloped front face, chamfered top edges', count=1, cells=['stern/top', 'stern/side'],
         reads='its sloped front face, its flat roof, the drive pod standing out of its aft face', src='picture'),
    dict(id='block_panels', job='the stern block\'s armour', type='plate', what='flush panels over the block\'s roof and sides', count=1, cells=['stern/top'],
         reads='flush slabs with machined chamfers and seam gaps', src='picture'),
    dict(id='drive', job='drive (sp 6): the one recessed ion-blue slit, a row of three cells inside an armoured pod (the owner\'s rule for craft)', type='engine',
         what='one rectangular slit across the stern, three cells behind upright guide vanes, in an armoured pod', count=1, cells=['stern/top', 'stern/side'],
         reads='a machined lip, the tapering blue lining, the blue-white throat plate, the vanes, the pod\'s walls and trim band', src='picture'),
]
STRUCTURE = {'bow/top': 3, 'bow/side': 2, 'mid/top': 3, 'mid/side': 3, 'stern/top': 4, 'stern/side': 4}
STRUCTURE_NOTE = ('HF1D slim render, by eye (no true views): bow, the slim point, the framed recess and the ridge\'s front; midships, the deck, the '
                  'ridge and the stepped edging; stern, the deck, the ridge, the stern block and the drive slit')
LEFT_PLAIN = [
    'The panel grid\'s small seams and stencils: the Hegemony paint stack (issue 780, applied later) draws the fine seams; the sheet models the panels.',
    'Hatches, thrusters and lamps: below what the battle camera shows on a 3.84 unit craft, and the drive turns it; not built.',
]
INV_NOTES = {}
