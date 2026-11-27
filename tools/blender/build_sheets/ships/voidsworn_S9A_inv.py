"""Astra Warden inventory from the two approved concept views and the frigate table."""
KIT = 'voidsworn'


def part(key, kind, count, cells, what, job, reads, source='picture'):
    return dict(id=key, type=kind, count=count, cells=cells.split(), what=what,
                job=job, reads=reads, src=source)


INVENTORY = [
    part('blade', 'hull', 1, 'bow/top bow/side mid/top mid/side stern/side',
         'Forged spearhead flowing into low shoulders', 'Protect the pressure hull', 'Facets, stepped belt and lower chamfer'),
    part('armour', 'plate', 1, 'bow/top bow/side bow/below mid/top mid/side mid/below stern/top stern/side stern/below',
         'Arrow plates forward, long plates amidships', 'Deflect hits', 'Bevels, straps and edge rivets'),
    part('repeater', 'gun', 1, 'bow/top bow/side', 'One three-barrel casemate', 'Fire the forward volley',
         'Forged port and mantlet, jacket, three muzzle bores'),
    part('feed', 'rib', 1, 'mid/top', 'Low dorsal service rail', 'Protect the repeater feed', 'Tapered rail with splice straps'),
    part('flak', 'gun', 2, 'mid/top mid/side', 'Two twin flak tubs', 'Cover craft approaches',
         'Traverse ring, cheek drums, mantlet and sleeved barrels'),
    part('band', 'vent', 8, 'mid/side stern/side', 'Four shutter banks per side', 'Vent the flank galleries',
         'Recess, forged frame and slanted blades'),
    part('raft', 'spine', 1, 'mid/top stern/top stern/side', 'Single raised radiator carrier',
         'Connect all three heat exchangers to one plenum', 'Stepped block, bridge face and ember slits'),
    part('bridge', 'slit', 2, 'mid/top', 'Two lights on the command face', 'Give the bridge a forward view', 'Recessed glass under an iron brow'),
    part('spires', 'radiator', 3, 'stern/top stern/side', 'Three tapered slatted columns',
         'Shed heat from the reactor', 'Root braces, columns, fins, core and cap'),
    part('drives', 'engine', 2, 'stern/top stern/side stern/below', 'Two deep-set bells',
         'Main thrust', 'Collar, struts, rings, lining and recessed plug'),
    part('access', 'hatch', 3, 'bow/below mid/below stern/below', 'Access covers on the lower service flat',
         'Reach feed, galleries and pumps', 'Rim, hinge, seam and door', 'designed'),
    part('jets', 'thruster', 2, 'bow/side', 'Paired steering nozzles', 'Turn the ship',
         'Recessed throats on a forged block', 'designed'),
    part('lights', 'lamp', 6, 'bow/top mid/top stern/top', 'Small frost lights on the shoulders',
         'Mark the outline', 'Hood and inset lens', 'designed'),
]
STRUCTURE = {'bow/top': 2, 'bow/side': 2, 'mid/top': 5, 'mid/side': 3, 'stern/top': 7, 'stern/side': 6}
STRUCTURE_NOTE = 'Read by eye from the approved top and side views with the count corrections in the feature table.'
LEFT_PLAIN = ['The Sunward stack supplies frost markings, worn edges and soot. The game supplies the exhaust plume.']
