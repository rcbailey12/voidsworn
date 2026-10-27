# A4 ship files: one entry per hull, the "ship template as data" (K1 decision 6). Blender working frame (frame.py): x bow, y PORT, z up,
# length 1.0. Positions are where a ray from `side` first meets the hull (the coordinate along the ray is ignored).
#
# entry keys:
#   fac, cls       faction and data.js class (the class sets part sizes through kit.CLS_LEN, and the weapon slots below)
#   name           display name
#   sym            'bilateral' (mirrored pairs) | 'corsair' (lopsided on purpose) | 'organic' (pairs where the body allows)
#   yaw            the game's AI_HULL_YAW for side-on meshes (A4 adds 2: turned half round)
#   roll           quarter turns about the bow axis (A4: hulls meshed lying on their side)
#   cuts           AI parts taken out before refining (cuts.py): dict(name, box=(x0, x1, y0, y1, z0, z1), mirror, cover, pad, raise)
#                  or dict(name, dir='up'|'down'|'aft'|'fore'|'port'|'stbd', level, max_w, min_ratio, box)
#   kit            hand-built parts, in order: (function, name, x, y, z, side, {kwargs}); kwargs: pair, aim, size, slot, wkind, arc, ...
#                  functions: turret casemate spinal launcher emitter engine_at thruster_pod radiators antenna sensor_array hook_prow
#                  sensor_dome bridge tank bay
#   spires         dict(zmin, box, exclude_x, style='gothic'|'mast'|'array'|'radiator'): melted thin spires found and rebuilt crisp
#                  (a2detail/spires.py; Voidsworn 'radiator' since Oct 27: heat-radiator spires, not church spires)
#   dress          surface-detail amount (0 off, 1 normal)
#   breach, wreck  counts (default by size band)
#   notes          the blob-sweep verdicts and taste calls, for the report
ARC_DEG = {'F': 30, 'T': 135, 'P': 60, 'S': 60}  # half-angle from the rest direction (P and S rest 15 degrees forward of abeam: 30 to 150 from the bow)

# data.js HULLS weapon lists per faction and class (the hard point slot order), Oct 26 2026
WEAPONS = {
    'chorus|Bio-titan': [('bioplasma', 'F'), ('bioplasma', 'F'), ('tendril', 'T'), ('spores', 'T')], 'chorus|Carrier': [('bioplasma', 'F'), ('spores', 'T')],
    'chorus|Cruiser': [('tendril', 'T'), ('bioplasma', 'F')], 'chorus|Destroyer': [('bioplasma', 'T'), ('bioplasma', 'F')], 'chorus|Frigate': [('tendril', 'T')],
    'corsair|Battle-barge': [('scatter', 'P'), ('scatter', 'S'), ('htorp', 'F'), ('flak', 'T')], 'corsair|Carrier': [('turret', 'T'), ('turret', 'T')],
    'corsair|Cruiser': [('scatter', 'P'), ('scatter', 'S'), ('torp', 'F'), ('flak', 'T')], 'corsair|Destroyer': [('torp', 'F'), ('scatter', 'S')],
    'corsair|Frigate': [('autocannon', 'T')],
    'deathless|Cruiser': [('gauss', 'T'), ('gauss', 'T'), ('doom', 'F'), ('gsentry', 'T')], 'deathless|Destroyer': [('gauss', 'T'), ('gauss', 'F')],
    'deathless|Frigate': [('gauss', 'T')], 'deathless|Tomb-ark': [('gauss', 'T'), ('gauss', 'T'), ('doom', 'F'), ('flak', 'T')],
    'hegemony|Battleship': [('hturbo', 'P'), ('hturbo', 'S'), ('ion', 'F'), ('flak', 'T')], 'hegemony|Cruiser': [('turbo', 'T'), ('turbo', 'T'), ('ion', 'F')],
    'hegemony|Destroyer': [('ion', 'F'), ('turbo', 'T')], 'hegemony|Frigate': [('laser', 'F'), ('flak', 'T')],
    'hegemony|Super-dreadnought': [('hturbo', 'P'), ('hturbo', 'S'), ('turbo', 'T'), ('ion', 'F'), ('flak', 'T')],
    'ithar|Ark': [('pulsar', 'F'), ('pulsar', 'F'), ('pulsar', 'T'), ('turret', 'T'), ('flak', 'T')], 'ithar|Carrier': [('pulsar', 'F'), ('turret', 'T')],
    'ithar|Cruiser': [('pulsar', 'F'), ('pulsar', 'F'), ('turret', 'T')], 'ithar|Destroyer': [('shard', 'F'), ('startorp', 'F')], 'ithar|Frigate': [('shard', 'F')],
    'voidsworn|Battleship': [('hbattery', 'P'), ('hbattery', 'S'), ('lance', 'F'), ('flak', 'T')], 'voidsworn|Carrier': [('turret', 'T'), ('flak', 'T')],
    'voidsworn|Cruiser': [('battery', 'P'), ('battery', 'S'), ('lance', 'F')], 'voidsworn|Destroyer': [('torp', 'F'), ('turret', 'T')],
    'voidsworn|Dreadnought': [('hbattery', 'P'), ('hbattery', 'S'), ('turret', 'T'), ('flak', 'T')], 'voidsworn|Frigate': [('autocannon', 'F'), ('flak', 'T')],
    'craft|fighter': [('guns', 'T')], 'craft|bomber': [('bombs', 'T')], 'craft|spore': [('sporeb', 'T')],
    'obj|station': [], 'obj|transport': [], 'obj|beacon': [],
}
KEYS = {'loft', 'pitch', 'roll_deg', 'scatter', 'roll', 'spires', 'fac', 'cls', 'name', 'sym', 'yaw', 'cuts', 'kit', 'dress', 'breach', 'wreck', 'notes', 'snap', 'needle', 'wkey', 'keep_islands'}
FNS = {  # kwargs common to all: pair, aim, align ('axis' default: stand square to the side; 'surface': follow the local normal)
       'turret', 'casemate', 'spinal', 'launcher', 'emitter', 'engine_at', 'thruster_pod', 'radiators', 'antenna', 'sensor_array', 'hook_prow', 'sensor_dome', 'bridge', 'tank', 'bay', 'cover', 'sail', 'orifice', 'tendril', 'horn', 'brood'}
SIZES = {'S', 'M', 'L', 'XL'}


def weapons(cfg):
    return WEAPONS.get(cfg.get('wkey') or f"{cfg['fac']}|{cfg['cls']}", [])


def check_entry(code, cfg):
    """the schema check (K1 decision 6): unknown keys or functions, sizes outside the table, backward aims, slots without a mount"""
    probs = [f'unknown key {k}' for k in cfg if k not in KEYS]
    for k in ('fac', 'cls'):
        if k not in cfg: probs.append(f'missing {k}')
    if (cfg.get('wkey') or f"{cfg.get('fac')}|{cfg.get('cls')}") not in WEAPONS: probs.append('no weapon list for this faction and class')
    slots = set(); W = weapons(cfg) if 'fac' in cfg else []
    for spec in cfg.get('kit', []):
        if len(spec) < 6 or spec[0] not in FNS: probs.append(f'bad kit entry {spec[:2]}'); continue
        kw = spec[6] if len(spec) > 6 else {}
        if 'size' in kw and kw['size'] not in SIZES: probs.append(f'{spec[1]}: size {kw["size"]} not in {sorted(SIZES)}')
        if spec[5] not in ('top', 'below', 'port', 'stbd', 'bow', 'stern'): probs.append(f'{spec[1]}: side {spec[5]}')
        aim = kw.get('aim')
        if aim is not None and aim[0] < -.05: probs.append(f'{spec[1]}: aims backward {aim}')
        if 'slot' in kw:
            s = kw['slot']; slots.add(s)
            if kw.get('pair') and 'slot_m' in kw: slots.add(kw['slot_m'])
            if s >= len(W): probs.append(f'{spec[1]}: slot {s} but the class has {len(W)} weapons')
            elif kw.get('arc') != W[s][1]: probs.append(f'{spec[1]}: slot {s} is {W[s][0]} {W[s][1]}, mount says arc {kw.get("arc")}')
    for s in range(len(W)):
        if s not in slots: probs.append(f'weapon slot {s} ({W[s][0]} {W[s][1]}) has no mount in the ship file')
    return probs


SHIPS = {}
# orientation fixes known before a ship file exists: the game's AI_HULL_YAW (ships3d.js) plus A4 finds (2 = turned half round)
YAWS = {'I14_23': 1, 'I15_11': -1, 'I11_37': 2, 'D20_23': -1, 'D9_23': 2, 'C15s_23': 2, 'V14_23': 2, 'V16_37': 2, 'B19_11': 2, 'B21_11': 2, 'B22_11': 2}

# ---------------------------------------------------------------------------------------------------------------------------------------
# Corsair (barge grammar: rust-and-bone salvage, lopsided, junk bolted on; space parts only)
SHIPS['C13s_23'] = dict(
    fac='corsair', cls='Frigate', name='Raider-class frigate', sym='corsair',
    cuts=[dict(name='spine', box=(-.06, .34, -.032, .032, .088, .30)),          # AI top gun, tower and bent pipe mast: rebuilt
          dict(name='crown', box=(-.52, -.385, -.08, .08, -.07, .07)),          # AI engine crown with prongs: rebuilt as bells
          dict(name='chinfin', box=(.26, .425, -.024, .024, -.25, -.116))],     # pass 3: the fin under the bow read as a boat keel (naval tell)
    kit=[('turret', 'ac', .16, 0, 0, 'top', dict(size='M', barrels=2, slot=0, wkind='autocannon', arc='T', lift=.035)),
         ('sensor_array', 'ant', .00, .006, 0, 'top', dict(w=.034)),        # pass 3: the pole antenna read as a mast
         ('hook_prow', 'hook', .34, 0, 0, 'below', dict(length=.17, r=.024, drop=.004)),   # pass 3: boarding claw under the chin
         ('engine_at', 'eM', 0, 0, 0, 'stern', dict(r=.040, L=.055)),
         ('engine_at', 'eP', 0, .056, -.038, 'stern', dict(r=.020, L=.030)),
         ('engine_at', 'eS', 0, -.050, .036, 'stern', dict(r=.016, L=.026)),
         ('radiators', 'rad', -.20, 0, 0, 'top', dict(length=.07, height=.035)),
         ('tank', 'tk', -.12, .052, 0, 'top', dict(r=.011, length=.06)),
         ('sensor_dome', 'sd', .31, 0, 0, 'top', dict(r=.011))],
    notes='pass 3 (Oct 27 lore note, grimmer Corsairs): chin fin cut (keel read), boarding claw under the chin, low sensor array instead of '
          'the pole antenna, trophy plates in the dress')

SHIPS['C14s_23'] = dict(
    fac='corsair', cls='Destroyer', name='Reaver-class destroyer', sym='corsair',
    cuts=[dict(name='tower', box=(.075, .27, -.075, .075, .035, .30)),          # AI lattice tower and crossbar mast (naval tells): rebuilt as antenna arrays
          dict(name='arch', box=(-.50, -.255, -.13, .13, .005, .30)),           # AI wire arch over the stern: rebuilt as heat radiators
          dict(name='nozzle', box=(-.52, -.465, -.065, .065, -.12, .005)),      # AI engine ring at the stern face: rebuilt as a bell
          dict(name='funnel', box=(-.045, .055, -.065, .075, .03, .30))],       # AI smokestack and leaning wire sticks: rebuilt as radiators
    kit=[('spinal', 'torp', .33, 0, 0, 'top', dict(size='M', slot=0, wkind='torp', arc='F', tubes=4)),
         ('casemate', 'scat', .06, 0, -.07, 'stbd', dict(size='M', barrels=2, slot=1, wkind='scatter', arc='S', aim=(.26, -.97, 0))),
         ('sensor_array', 'ant', .17, .02, 0, 'top', dict(w=.040)),         # pass 3: the two pole antennas read as masts
         ('sensor_array', 'ant2', .10, -.035, 0, 'top', dict(w=.028, panels=2, dish=False)),
         ('hook_prow', 'hook', .36, 0, 0, 'below', dict(length=.17, r=.022, drop=.002)),   # pass 3: boarding claw from the chin pod
         ('radiators', 'rad', -.37, 0, 0, 'top', dict(length=.12, height=.05, n_fins=3)),
         ('radiators', 'rad2', .005, .005, 0, 'top', dict(length=.07, height=.04, n_fins=2, splay=24)),
         ('engine_at', 'eM', 0, 0, -.06, 'stern', dict(r=.046, L=.06)),
         ('engine_at', 'eP', 0, .062, -.10, 'stern', dict(r=.019, L=.03)),
         ('engine_at', 'eS', 0, -.058, -.025, 'stern', dict(r=.024, L=.035)),
         ('tank', 'tk', -.17, -.05, 0, 'top', dict(r=.012, length=.07)),
         ('sensor_dome', 'sd', .02, 0, 0, 'top', dict(r=.013))],
    notes='pass 3 (Oct 27 lore note, grimmer Corsairs): boarding claw from the chin pod, low sensor arrays instead of the pole antennas, '
          'trophy plates in the dress')

SHIPS['C15s_23'] = dict(
    fac='corsair', cls='Cruiser', name='Marauder-class cruiser', sym='corsair',
    yaw=2,  # meshed back to front: the rounded nose is at -x in hulls_hi and the crane at +x, so today's game flies it stern first
    cuts=[dict(name='crane', box=(-.50, -.02, -.07, .07, .012, .30)),          # AI A-frame crane with cables (rigging: a naval tell)
          dict(name='fork', box=(.115, .225, -.055, .055, .055, .30)),          # AI fork tower and melted top gun
          dict(name='domes', box=(.31, .445, .045, .125, -.055, .045), mirror=True),   # AI side gun domes and prongs
          dict(name='chinfin', box=(.335, .43, -.024, .024, -.20, -.106))],     # pass 3: the fin under the bow read as a boat keel (naval tell)
    kit=[('casemate', 'scat', .378, 0, -.005, 'port', dict(size='M', barrels=2, slot=0, slot_m=1, wkind='scatter', arc='P', aim=(.26, .97, 0), pair=True)),
         ('spinal', 'torp', .29, 0, 0, 'top', dict(size='M', slot=2, wkind='torp', arc='F', tubes=4)),
         ('turret', 'flak', .145, 0, 0, 'top', dict(size='S', barrels=2, slot=3, wkind='flak', arc='T', lift=.02)),
         ('sensor_array', 'ant', .195, .01, 0, 'top', dict(w=.040)),        # pass 3: the pole antennas read as masts with a crow's nest
         ('sensor_array', 'ant2', -.25, .025, 0, 'top', dict(w=.028, dish=False)),
         ('hook_prow', 'hook', .38, 0, 0, 'below', dict(length=.15, r=.020, drop=.004)),   # pass 3: boarding claw under the chin
         ('radiators', 'rad', -.39, 0, 0, 'top', dict(length=.10, height=.05, n_fins=2)),
         ('engine_at', 'eM', 0, 0, -.02, 'stern', dict(r=.036, L=.05)),
         ('engine_at', 'eP', 0, .052, .004, 'stern', dict(r=.020, L=.03)),
         ('engine_at', 'eS', 0, -.046, -.052, 'stern', dict(r=.025, L=.035)),
         ('tank', 'tk', -.15, -.04, 0, 'top', dict(r=.011, length=.07))],
    notes='pass 3 (Oct 27 lore note, grimmer Corsairs): chin fin cut (keel read), boarding claw under the chin, low sensor arrays instead '
          'of the pole antennas, trophy plates in the dress')

SHIPS['C16s_23'] = dict(
    fac='corsair', cls='Carrier', name='Hulk-carrier', sym='corsair',
    cuts=[dict(name='mast', box=(.115, .20, -.05, .05, .105, .30)),           # AI thin mast sticks and the melted star part
          dict(name='spikes', box=(-.50, -.355, -.075, .075, .062, .30)),       # AI spiky stern clusters
          dict(name='sticks', dir='aft', level=.40, max_w=.03, min_ratio=1.6),  # thin AI sticks trailing aft (wire debris)
          dict(name='bulb', box=(.33, .47, -.055, .055, -.22, -.095)),          # AI bulb on a stalk under the bow
          dict(name='bulb2', box=(.23, .35, -.05, .05, -.20, -.115)),           # pass 2: the bulb's loose end, left floating under the bow
          dict(name='prongs', dir='fore', level=.40, max_w=.03, min_ratio=1.6)],  # pass 3: thin AI prongs off the bow sides (wire debris)
    kit=[('turret', 'tA', .26, 0, 0, 'top', dict(size='M', barrels=2, slot=0, wkind='turret', arc='T', lift=.01)),
         ('turret', 'tB', -.15, 0, 0, 'top', dict(size='M', barrels=3, slot=1, wkind='turret', arc='T', lift=.012)),
         ('bay', 'bay', .05, 0, -.05, 'port', dict(width=.085, height=.05, pair=True)),
         ('sensor_array', 'ant', .155, -.01, 0, 'top', dict(w=.042)),       # pass 3: the pole antenna read as a mast with a crow's nest
         ('hook_prow', 'hook', .37, 0, 0, 'below', dict(length=.15, r=.020, drop=.004)),   # pass 3: boarding claw under the chin
         ('radiators', 'rad', -.42, 0, 0, 'top', dict(length=.09, height=.055, n_fins=2)),
         ('engine_at', 'eP', 0, .046, .005, 'stern', dict(r=.032, L=.05)),
         ('engine_at', 'eS', 0, -.044, -.004, 'stern', dict(r=.026, L=.042)),
         ('engine_at', 'eB', 0, 0, -.075, 'stern', dict(r=.021, L=.03)),
         ('sensor_dome', 'sd', .22, -.02, 0, 'below', dict(r=.018)),          # pass 3: moved aft, the claw pylon took its place
         ('tank', 'tk', -.05, .07, 0, 'top', dict(r=.012, length=.08))],
    notes='pass 3 (Oct 27 lore note, grimmer Corsairs): bow prongs cut, boarding claw under the chin, low sensor array instead of the pole '
          'antenna, trophy plates in the dress')

# ---------------------------------------------------------------------------------------------------------------------------------------
# Voidsworn (grimdark black steel, ember glow; bilateral). Flagship first: V1b_r_23 is the K1 "Basilica" proof manifest.
SHIPS['V1b_r_23'] = dict(
    fac='voidsworn', cls='Dreadnought', name='Ascendant-class dreadnought', sym='bilateral',
    spires=dict(zmin=-.03, exclude_x=.40, style='radiator'),                     # the A2 rebuild: melted AI pinnacles cut and rebuilt crisp
    cuts=[dict(name='domes', box=(-.215, .035, -.042, .042, -.046, .12))],       # AI dome turrets along the spine
    kit=[('casemate', 'hb', -.085, 0, -.09, 'port', dict(size='L', barrels=2, slot=0, slot_m=1, wkind='hbattery', arc='P', aim=(.26, .97, 0), pair=True)),
         ('casemate', 'hb2', .045, 0, -.09, 'port', dict(size='L', barrels=2, slot=0, slot_m=1, wkind='hbattery', arc='P', aim=(.26, .97, 0), pair=True)),
         ('turret', 'tt', -.03, 0, 0, 'top', dict(size='L', barrels=3, slot=2, wkind='turret', arc='T', lift=.006)),
         ('turret', 'tt2', -.15, 0, 0, 'top', dict(size='L', barrels=3, slot=2, wkind='turret', arc='T', lift=.006)),
         ('turret', 'fl', -.40, .05, 0, 'top', dict(size='S', barrels=2, slot=3, wkind='flak', arc='T', pair=True)),
         ('engine_at', 'eC', 0, 0, -.10, 'stern', dict(r=.032, L=.045)),
         ('engine_at', 'eP', 0, .066, -.10, 'stern', dict(r=.029, L=.042, pair=True)),
         ('sensor_dome', 'sd', .30, 0, 0, 'top', dict(r=.014))],
    notes='first pass; the bow keeps the concept ram profile (vetoable: a naval-reading lower bow line)')

SHIPS['V17_37'] = dict(
    fac='voidsworn', cls='Battleship', name='Cathedral-class battleship', sym='bilateral',
    cuts=[dict(name='horns', dir='aft', level=.36, max_w=.035, min_ratio=1.5),   # thin curved AI horns trailing off the stern
          dict(name='hornsup', dir='up', level=.03, box=(-.52, -.28, -.2, .2, -1, 1), max_w=.03),
          dict(name='hornsdn', dir='down', level=.05, box=(-.52, -.28, -.2, .2, -1, 1), max_w=.03)],
    kit=[('casemate', 'hb', -.11, 0, -.03, 'port', dict(size='L', barrels=2, slot=0, slot_m=1, wkind='hbattery', arc='P', aim=(.26, .97, 0), pair=True)),
         ('casemate', 'hb2', .10, 0, -.03, 'port', dict(size='L', barrels=2, slot=0, slot_m=1, wkind='hbattery', arc='P', aim=(.26, .97, 0), pair=True)),
         ('spinal', 'lance', .30, 0, 0, 'top', dict(size='L', slot=2, wkind='lance', arc='F', length=4.5)),
         ('turret', 'fl', -.21, .035, 0, 'top', dict(size='S', barrels=2, slot=3, wkind='flak', arc='T', pair=True)),
         ('engine_at', 'eC', 0, 0, -.015, 'stern', dict(r=.026, L=.04)),
         ('engine_at', 'eP', 0, .046, -.03, 'stern', dict(r=.020, L=.032, pair=True)),
         ('sensor_dome', 'sd', .38, 0, 0, 'top', dict(r=.010))],
    notes='first pass')

SHIPS['V14_23'] = dict(
    fac='voidsworn', cls='Frigate', name='Warden-class frigate', sym='bilateral',
    yaw=2,  # meshed back to front: the twin ring nozzles sat at +x (the bow) in hulls_hi; the concept has them aft
    spires=dict(zmin=.035, style='radiator'),
    kit=[('turret', 'ac', .19, 0, 0, 'top', dict(size='M', barrels=2, slot=0, wkind='autocannon', arc='F', lift=.004)),
         ('turret', 'fl', -.06, .04, 0, 'top', dict(size='S', barrels=2, slot=1, wkind='flak', arc='T', pair=True)),
         ('engine_at', 'eP', 0, .032, .02, 'stern', dict(r=.027, L=.035, pair=True))],
    notes='first pass')

SHIPS['V15_37'] = dict(
    fac='voidsworn', cls='Destroyer', name='Harrow-class destroyer', sym='bilateral',
    cuts=[dict(name='sticks', dir='aft', level=.36, max_w=.03, min_ratio=1.5),   # thin AI prongs trailing off the stern
          dict(name='sternblob', box=(-.52, -.40, -.065, .065, -.055, .05))],     # melted engine block: rebuilt as bells
    kit=[('spinal', 'torp', .25, 0, 0, 'top', dict(size='M', slot=0, wkind='torp', arc='F', tubes=2)),
         ('turret', 'tt', .07, 0, 0, 'top', dict(size='M', barrels=2, slot=1, wkind='turret', arc='T', lift=.004)),
         ('engine_at', 'eP', 0, .03, -.025, 'stern', dict(r=.02, L=.03, pair=True))],
    spires=dict(zmin=.035, style='radiator'),   # the melted tall fin over the waist (concept: a crisp black spike), rebuilt crisp
    notes='pass 2: turret moved off the fin (it had swallowed it and read as a smokestack), bells lowered to the stern face')

SHIPS['V16_37'] = dict(
    fac='voidsworn', cls='Cruiser', name='Penitent-class cruiser', sym='bilateral',
    yaw=2,  # meshed back to front: the twin engine nacelles sat at +x and the fins swept toward +x; the concept flies the dart point first
    kit=[('casemate', 'bt', .06, 0, -.01, 'port', dict(size='M', barrels=2, slot=0, slot_m=1, wkind='battery', arc='P', aim=(.26, .97, 0), pair=True)),
         ('casemate', 'bt2', -.08, 0, -.01, 'port', dict(size='M', barrels=2, slot=0, slot_m=1, wkind='battery', arc='P', aim=(.26, .97, 0), pair=True)),
         ('spinal', 'lance', .28, 0, 0, 'top', dict(size='L', slot=2, wkind='lance', arc='F', length=4.5)),
         ('engine_at', 'eP', 0, .03, -.023, 'stern', dict(r=.016, L=.026, pair=True)),   # pass 2: on the nacelle ends (probe), was off the hull
         ('sensor_dome', 'sd', .10, 0, 0, 'top', dict(r=.009))],
    notes='first pass')

SHIPS['V18_51'] = dict(
    fac='voidsworn', cls='Carrier', name='Reliquary-class carrier', sym='bilateral',
    spires=dict(zmin=.035, style='radiator'),                                       # the melted tine racks rebuilt as crisp pinnacles
    kit=[('turret', 'tt', .22, 0, 0, 'top', dict(size='M', barrels=2, slot=0, wkind='turret', arc='T', lift=.004)),
         ('turret', 'fl', -.12, .07, 0, 'top', dict(size='S', barrels=2, slot=1, wkind='flak', arc='T', pair=True)),
         ('bay', 'bay', 0, .20, -.075, 'bow', dict(width=.035, height=.026, launch=(1, 0, 0), pair=True)),
         ('engine_at', 'eC', 0, .017, 0, 'stern', dict(r=.016, L=.026, pair=True)),
         ('engine_at', 'eW', 0, .205, -.075, 'stern', dict(r=.018, L=.026, pair=True))],
    notes='first pass')

# ---------------------------------------------------------------------------------------------------------------------------------------
# Hegemony (clean light-grey navy with blue trim; parade finish; bilateral)
SHIPS['H4_11'] = dict(
    fac='hegemony', cls='Super-dreadnought', name='Dominion super-dreadnought', sym='bilateral',
    spires=dict(zmin=.07, box=(-.12, 0, -.03, .03), style='array'),            # pass 2: melted mast tubes rebuilt as slim sensor arrays (not funnels)
    cuts=[dict(name='tfore', box=(.195, .325, -.052, .052, -.084, .10)),          # AI U-shaped turret blobs: rebuilt as turrets
          dict(name='taft', box=(-.365, -.235, -.052, .052, -.090, .10))],
    kit=[('casemate', 'ht', .0, 0, -.10, 'port', dict(size='L', barrels=2, slot=0, slot_m=1, wkind='hturbo', arc='P', aim=(.26, .97, 0), pair=True)),
         ('casemate', 'ht2', -.16, 0, -.10, 'port', dict(size='L', barrels=2, slot=0, slot_m=1, wkind='hturbo', arc='P', aim=(.26, .97, 0), pair=True)),
         ('turret', 'tb', .26, 0, 0, 'top', dict(size='L', barrels=2, slot=2, wkind='turbo', arc='T', lift=.004)),
         ('turret', 'tb2', -.30, 0, 0, 'top', dict(size='L', barrels=2, slot=2, wkind='turbo', arc='T', lift=.004)),
         ('spinal', 'ion', .39, 0, 0, 'top', dict(size='L', slot=3, wkind='ion', arc='F', length=3.5)),
         ('turret', 'fl', .12, .07, 0, 'top', dict(size='S', barrels=2, slot=4, wkind='flak', arc='T', pair=True)),
         ('engine_at', 'eC', 0, 0, -.065, 'stern', dict(r=.03, L=.04)),
         ('engine_at', 'eP', 0, .055, -.075, 'stern', dict(r=.024, L=.034, pair=True))],
    notes='first pass')

SHIPS['H10_23'] = dict(
    fac='hegemony', cls='Battleship', name='Dominion-class battleship', sym='bilateral',
    spires=dict(zmin=.06, box=(-.25, 0, -.04, .04), style='array'),
    kit=[('casemate', 'ht', .0, 0, -.045, 'port', dict(size='L', barrels=2, slot=0, slot_m=1, wkind='hturbo', arc='P', aim=(.26, .97, 0), pair=True)),
         ('casemate', 'ht2', .17, 0, -.045, 'port', dict(size='L', barrels=2, slot=0, slot_m=1, wkind='hturbo', arc='P', aim=(.26, .97, 0), pair=True)),  # pass 2: on the side band (probe)
         ('spinal', 'ion', .38, 0, 0, 'top', dict(size='L', slot=2, wkind='ion', arc='F', length=3.5)),
         ('turret', 'fl', .05, .04, 0, 'top', dict(size='S', barrels=2, slot=3, wkind='flak', arc='T', pair=True)),
         ('engine_at', 'eP', 0, .042, -.05, 'stern', dict(r=.022, L=.032, pair=True)),
         ('engine_at', 'eC', 0, 0, -.05, 'stern', dict(r=.018, L=.028))],
    notes='first pass')

SHIPS['H7_23'] = dict(
    fac='hegemony', cls='Frigate', name='Picket-class frigate', sym='bilateral',
    spires=dict(zmin=.08, style='array'),
    kit=[('spinal', 'las', .30, 0, 0, 'top', dict(size='M', slot=0, wkind='laser', arc='F', length=3.0)),
         ('turret', 'fl', -.05, .075, 0, 'top', dict(size='S', barrels=2, slot=1, wkind='flak', arc='T', pair=True)),
         ('engine_at', 'eP', 0, .06, -.04, 'stern', dict(r=.026, L=.034, pair=True))],
    notes='first pass')

SHIPS['H8_23'] = dict(
    fac='hegemony', cls='Destroyer', name='Interdictor-class destroyer', sym='bilateral',
    spires=dict(zmin=.10, style='array'),
    cuts=[dict(name='aftgun', box=(-.52, -.235, -.045, .045, .0, .12))],          # AI turret whose long barrel aimed aft (no ship fires backward)
    kit=[('turret', 'tb', -.29, 0, 0, 'top', dict(size='M', barrels=2, slot=1, wkind='turbo', arc='T', lift=.004)),
         ('spinal', 'ion', .30, 0, 0, 'top', dict(size='M', slot=0, wkind='ion', arc='F', length=3.5)),
         ('engine_at', 'eP', 0, .04, -.05, 'stern', dict(r=.022, L=.032, pair=True))],
    notes='first pass')

SHIPS['H9_23'] = dict(
    fac='hegemony', cls='Cruiser', name='Vanguard-class cruiser', sym='bilateral',
    cuts=[dict(name='aftguns', box=(-.43, -.245, -.05, .05, .062, .20)),         # AI twin-gun block aimed aft (no ship fires backward); pass 2: floor
                                                                                    # at the deck (z .03 cut through it and the patch came out a stretched fan)
          dict(name='bridge', box=(-.245, -.035, -.056, .056, .064, .20))],       # pass 2: the melted AI bridge lump, rebuilt by hand
    kit=[('bridge', 'br', -.15, 0, 0, 'top', dict(length=.15, width=.075, height=.05, tiers=2)),
         ('antenna', 'ant', -.215, 0, 0, 'top', dict(h=.045, dishes=1)),
         ('turret', 'tb', -.31, 0, 0, 'top', dict(size='M', barrels=2, slot=0, wkind='turbo', arc='T', lift=.004)),
         ('turret', 'tb2', .20, 0, 0, 'top', dict(size='M', barrels=2, slot=1, wkind='turbo', arc='T', lift=.004)),
         ('spinal', 'ion', .36, 0, 0, 'top', dict(size='M', slot=2, wkind='ion', arc='F', length=3.5)),
         ('engine_at', 'eP', 0, .06, -.03, 'stern', dict(r=.024, L=.034, pair=True))],
    notes='pass 2 (Oct 26 review): melted bridge rebuilt by hand, aft cut floor at the deck')

# ---------------------------------------------------------------------------------------------------------------------------------------
# Chorus (living bio-ships: no bolted guns or metal bells; grown emitters, ring-muscle vents, brood sacs, crisp tendrils and bone horns;
# pairs where the body allows). Taste call (vetoable, SHIP_QUEUE asked to check with Ryan): the AI's melted worm-sticks stay where they
# read as tentacles, the dangling stalactites are rebuilt as crisp bone horns, and the dress adds ridges, veins, pores and glowing sacs.
SHIPS['B16_23'] = dict(
    fac='chorus', cls='Bio-titan', name='Bio-titan', sym='organic', snap=.015,
    cuts=[dict(name='stalactites', dir='down', level=.20, max_w=.07, min_ratio=1.6)],  # long melted spikes hanging under the body
    spires=dict(zmin=.32, style='gothic'),                                         # the black tower on its back (the concept's spires)
    kit=[('emitter', 'bp', 0, .10, .05, 'bow', dict(size='XL', slot=0, slot_m=1, wkind='bioplasma', arc='F', pair=True, scale=1.6)),
         ('emitter', 'td', .05, 0, 0, 'top', dict(size='XL', slot=2, wkind='tendril', arc='T', scale=1.4)),
         ('emitter', 'sp', -.25, .12, 0, 'top', dict(size='XL', slot=3, wkind='spores', arc='T', scale=1.4)),
         ('orifice', 'ov', 0, .16, 0, 'stern', dict(r=.04, pair=True))],
    scatter=[dict(fn='horn', count=7, where='below', length=(.10, .22), r=(.010, .018)),
             dict(fn='tendril', count=10, where='side', length=(.06, .14), r=(.005, .009))],
    notes='first pass')

SHIPS['B19_11'] = dict(
    fac='chorus', cls='Frigate', name='Drone', sym='organic', snap=.015,
    yaw=2,  # meshed back to front: the spiked glowing heads sat at -x; the concept leads with them
    kit=[('emitter', 'td', .15, 0, 0, 'top', dict(size='S', slot=0, wkind='tendril', arc='T', scale=1.2)),
         ('orifice', 'ov', 0, .06, -.05, 'stern', dict(r=.035, pair=True))],
    scatter=[dict(fn='tendril', count=6, where='below', length=(.06, .12), r=(.008, .013))],
    notes='first pass')

SHIPS['B20_11'] = dict(
    fac='chorus', cls='Destroyer', name='Spitter', sym='organic', snap=.012,
    # pass 2 (Oct 26 review): the concept's submarine conning tower with two masts and a stay wire (naval tells, CLAUDE.md) is cut, not
    # rebuilt as spires; a low bone crest and the dorsal emitter take its place; the thin AI whiskers at the bow go too (probe-tested)
    cuts=[dict(name='tower', box=(-.235, .005, -.036, .036, .034, .30)),
          dict(name='whiskers', dir='fore', level=.42, max_w=.03, min_ratio=1.2, min_h=.004)],   # the AI stay wire lies on the deck: it stays
                                                                                                    # as a dorsal tendon rising to the crest
    kit=[('emitter', 'bf', 0, 0, -.01, 'bow', dict(size='M', slot=1, wkind='bioplasma', arc='F', scale=1.2)),
         ('emitter', 'bt', -.05, 0, 0, 'top', dict(size='M', slot=0, wkind='bioplasma', arc='T', scale=1.1)),
         ('horn', 'cr', -.15, .018, 0, 'top', dict(length=.045, r=.007, bend=.35, pair=True)),
         ('horn', 'cr2', -.20, .012, 0, 'top', dict(length=.032, r=.006, bend=.35, pair=True)),
         ('orifice', 'ov', 0, .03, -.02, 'stern', dict(r=.022, pair=True))],
    scatter=[dict(fn='tendril', count=8, where='below', length=(.03, .07), r=(.004, .007))],
    notes='pass 2: conning tower, masts and bow whiskers cut (naval tells); the stay wire on the deck stays as a dorsal tendon')

SHIPS['B21_11'] = dict(
    fac='chorus', cls='Cruiser', name='Razorfiend', sym='organic', snap=.012,
    yaw=2,  # meshed back to front: the toothed maw sat at -x and a stinger at +x; maw first (vetoable)
    # pass 2 (Oct 26 review): the concept's conning tower with a periscope (naval tells) is cut; a bone crest sits behind the emitter
    cuts=[dict(name='tower', box=(-.005, .135, -.046, .046, .056, .30))],
    kit=[('emitter', 'bf', 0, 0, -.03, 'bow', dict(size='M', slot=1, wkind='bioplasma', arc='F', scale=1.3)),
         ('emitter', 'td', .05, 0, 0, 'top', dict(size='M', slot=0, wkind='tendril', arc='T', scale=1.2)),
         ('horn', 'cr', .10, .022, 0, 'top', dict(length=.05, r=.008, bend=.35, pair=True)),
         ('orifice', 'ov', 0, .055, -.02, 'stern', dict(r=.024, pair=True))],
    scatter=[dict(fn='horn', count=6, where='side', length=(.03, .06), r=(.004, .007))],
    notes='pass 2: conning tower and periscope cut (naval tells)')

SHIPS['B22_11'] = dict(
    fac='chorus', cls='Carrier', name='Brood-carrier', sym='organic', snap=.012,
    yaw=2,  # meshed back to front: the glowing bell sat at -x with the spiked tail ahead of it; bell first, like the concept (vetoable)
    kit=[('emitter', 'bf', 0, 0, 0, 'bow', dict(size='L', slot=0, wkind='bioplasma', arc='F', scale=1.4)),
         ('emitter', 'sp', .10, 0, 0, 'top', dict(size='L', slot=1, wkind='spores', arc='T', scale=1.2)),
         ('brood', 'bay', .05, 0, -.02, 'port', dict(r=.03, pair=True)),
         ('orifice', 'ov', 0, .02, 0, 'stern', dict(r=.018, pair=True))],
    notes='first pass')

# ---------------------------------------------------------------------------------------------------------------------------------------
# Ithar (pearl-white porcelain spindles, gold filigree, jade glow; the sails are the faction's signature). The AI meshed every sail as a
# thick lumpy volume (R28: "Ithar broken"), so the sails are cut off and rebuilt with kit.sail: thin membranes between gold ribs with a lit
# rim, exported with their own see-through material (pack.py). Where the AI body is a plain spindle or missing (I8, I11) the hull is lofted
# by hand (ithar.py). Taste calls (vetoable): sail sizes follow the AI silhouette (it reads top-down), not the concepts' 3/4 framing.
SAIL = dict(ribs=17, billow=.05, th=.0016)
SHIPS['I14_23'] = dict(
    fac='ithar', cls='Frigate', name='Gleam-class frigate', sym='bilateral', yaw=1, snap=.012, needle=.09,
    cuts=[dict(name='sails', box=(-.5, .05, .086, 1, -.06, 1), mirror=True),        # the two wing fans, cut flush beside the body
          dict(name='sailroot', box=(-.27, -.12, .05, .086, .0, .2), mirror=True)],  # the stubs on the body's shoulders
    kit=[('sail', 'sl', 0, 0, 0, 'top', dict(SAIL, root=(-.19, .072, -.004), u=(.309, .951, 0), v=(-.763, .247, .598), a0=-.10, a1=.90, R=.42,
                                            hub=((-.19, .066, -.006), (0, .6, .8)), pair=True)),
         ('turret', 'sh', .15, 0, 0, 'top', dict(size='S', barrels=1, slot=0, wkind='shard', arc='F', lift=.002)),
         ('engine_at', 'eP', 0, .02, -.095, 'stern', dict(r=.014, L=.02, pair=True))],
    notes='pass 1: AI body kept, wing fans rebuilt')

SHIPS['I11_37'] = dict(
    fac='ithar', cls='Destroyer', name='Seraph-class destroyer', sym='bilateral', yaw=2, snap=.012, needle=.05,
    loft=dict(r=.025, facets=6, ys=1.25, zs=.8, x=(-.30, .50), hub=.55, hub_t=.42, hub_w=.08, taper=.8, stern=.45),  # AI body: a thin tube under one sheet
    kit=[('sail', 'su', 0, 0, 0, 'top', dict(SAIL, root=(.02, .012, .014), u=(0, .35, .94), v=(-1, 0, 0), a0=-.25, a1=.95, R=.30,
                                            hub=((.02, .012, .012), (0, .35, .94)), pair=True)),   # the tall pair rising from the hub
         ('sail', 'sw', 0, 0, 0, 'top', dict(SAIL, ribs=13, root=(.0, .026, -.004), u=(0, 1, -.12), v=(-1, 0, 0), a0=-.30, a1=.70, R=.24,
                                            hub=((.0, .024, -.004), (0, 1, 0)), pair=True)),      # the low pair spread to the sides
         ('sail', 'sa', 0, 0, 0, 'top', dict(SAIL, ribs=11, root=(-.24, .008, .004), u=(-.55, .35, .76), v=(-.75, -.2, -.5), a0=-.2, a1=.5, R=.20,
                                            hub=((-.24, .008, .006), (0, .5, .85)), pair=True)),                                         # the small trailing pair at the stern
         ('turret', 'sh', .22, 0, 0, 'top', dict(size='S', barrels=1, slot=0, wkind='shard', arc='F', lift=.002)),
         ('turret', 'st', .16, 0, 0, 'below', dict(size='S', barrels=2, slot=1, wkind='startorp', arc='F')),
         ('engine_at', 'eC', 0, .001, .001, 'stern', dict(r=.009, L=.0125))],
    notes='pass 1: hand-lofted spindle, three sail pairs')

SHIPS['I15_11'] = dict(
    fac='ithar', cls='Cruiser', name='Aurora-class cruiser', sym='bilateral', yaw=-1, pitch=13.5, snap=.012, needle=.10,
    # pass 2 (Oct 26 review): the needle cut left the AI sail roots as a torn, crumpled shell with an open gap over the stern half, so the
    # body is lofted by hand like I8 and I11 (the AI's own forward spindle was a plain taper; the fan sails stay as built)
    loft=dict(r=.055, facets=6, ys=1.25, zs=.78, x=(-.24, .50), hub=.45, hub_t=.135, hub_w=.06, taper=.8, stern=.5),
    kit=[('sail', 'sl', 0, 0, 0, 'top', dict(SAIL, ribs=21, root=(-.14, .03, 0), u=(-.633, .763, -.125), v=(.058, .211, .977), a0=-.05, a1=.78, R=.62,
                                            hub=((-.14, .03, 0), (0, 1, 0)), pair=True)),
         ('turret', 'pf', .20, .025, 0, 'top', dict(size='M', barrels=1, slot=0, slot_m=1, wkind='pulsar', arc='F', pair=True, lift=.002)),
         ('turret', 'tt', .05, 0, 0, 'top', dict(size='M', barrels=2, slot=2, wkind='turret', arc='T', lift=.003)),
         ('engine_at', 'eC', 0, 0, -.02, 'stern', dict(r=.02, L=.024))],
    notes='pass 2: hand-lofted spindle (the cut AI stern was a crumpled shell), stern fans as before')

SHIPS['I16_11'] = dict(
    fac='ithar', cls='Carrier', name='Zenith-class carrier', sym='bilateral', snap=.012, needle=.08,
    cuts=[dict(name='sailaft', box=(-.5, -.25, -.012, .012, -.15, 1)),     # the sail sheet over the deck (the curved blade mast forward stays)
          dict(name='sailmid', box=(-.25, -.1, -.012, .012, -.135, 1)),
          dict(name='sailfore', box=(-.1, .03, -.012, .012, -.12, 1))],
    kit=[('sail', 'sl', 0, 0, 0, 'top', dict(SAIL, ribs=21, billow=.03, root=(-.04, 0, -.125), u=(-1, 0, 0), v=(0, 0, 1), a0=.02, a1=1.55, R=.40,
                                            hub=((-.04, 0, -.127), (0, 0, 1)))),
         ('turret', 'pf', .32, 0, 0, 'top', dict(size='L', barrels=1, slot=0, wkind='pulsar', arc='F', lift=.002)),
         ('turret', 'tt', -.05, 0, 0, 'below', dict(size='L', barrels=2, slot=1, wkind='turret', arc='T')),
         ('bay', 'bay', 0, .065, -.195, 'bow', dict(width=.02, height=.012, launch=(1, 0, 0), pair=True)),
         ('engine_at', 'eC', 0, 0, -.185, 'stern', dict(r=.016, L=.022))],
    notes='pass 1: AI hull kept (it reads well), sail rebuilt')

SHIPS['I8_37'] = dict(
    fac='ithar', cls='Ark', name='Empyrean ark', sym='bilateral', snap=.012, needle=.06,
    loft=dict(r=.026, facets=6, ys=1.25, zs=.8, hub=.9, hub_t=.5, hub_w=.07, taper=.85, stern=.45),   # the AI made one curved sheet with a stub of body
    kit=[('sail', 'sl', 0, 0, 0, 'top', dict(SAIL, ribs=19, root=(0, .045, -.004), u=(1, 0, 0), v=(0, 1, .10), a0=.22, a1=2.92, R=.42,
                                            hub=((0, .045, 0), (0, 1, 0)), pair=True)),   # the leaf: the needle is its midrib
         ('turret', 'pf', .20, 0, 0, 'top', dict(size='L', barrels=1, slot=0, wkind='pulsar', arc='F', lift=.002)),
         ('turret', 'pf2', .20, 0, 0, 'below', dict(size='L', barrels=1, slot=1, wkind='pulsar', arc='F')),
         ('turret', 'pt', -.14, 0, 0, 'top', dict(size='L', barrels=2, slot=2, wkind='pulsar', arc='T', lift=.002)),
         ('turret', 'tt', -.14, 0, 0, 'below', dict(size='M', barrels=2, slot=3, wkind='turret', arc='T')),
         ('turret', 'fl', .16, 0, 0, 'top', dict(size='M', barrels=2, slot=4, wkind='flak', arc='T', lift=.003)),
         ('engine_at', 'eC', 0, .001, .001, 'stern', dict(r=.011, L=.015))],
    notes='pass 1: hand-lofted spindle and leaf sail (the AI mesh was unusable)')

# ---------------------------------------------------------------------------------------------------------------------------------------
# Deathless (black tomb-stone, bone-grey trim, sickly green light; gothic, bilateral). Gauss turrets in the hex style with a green slit.
SHIPS['D22_23'] = dict(
    fac='deathless', cls='Tomb-ark', name='Necropolis tomb-ark', sym='bilateral', pitch=2.4, roll_deg=-25.9,   # the AI meshed the ring rolled 26 degrees (plane fit of the ring)
    kit=[('turret', 'gs', 0, .38, 0, 'top', dict(size='L', barrels=2, slot=0, slot_m=1, wkind='gauss', arc='T', pair=True, lift=.003)),
         ('spinal', 'doom', .36, 0, 0, 'top', dict(size='L', slot=2, wkind='doom', arc='F', length=3.0)),
         ('turret', 'fl', -.36, 0, 0, 'top', dict(size='M', barrels=2, slot=3, wkind='flak', arc='T', lift=.003)),
         ('engine_at', 'eP', 0, .16, .06, 'stern', dict(r=.024, L=.034, pair=True))],
    notes='pass 1: ring levelled; the downward spire stays (vetoable: the concept shows a small ship on a green beam there)')

SHIPS['D9_23'] = dict(
    fac='deathless', cls='Frigate', name='Ossuary frigate', sym='bilateral', yaw=2,   # meshed back to front: the skull and claws sat aft
    cuts=[dict(name='gun', box=(.05, .22, -.025, .025, .105, .2))],                   # the AI deck gun (rebuilt: gauss turret)
    kit=[('turret', 'gs', .13, 0, 0, 'top', dict(size='S', barrels=2, slot=0, wkind='gauss', arc='T', lift=.003)),
         ('engine_at', 'eC', 0, 0, .02, 'stern', dict(r=.022, L=.03))],
    notes='pass 1: the ribcage is the design and stays')

SHIPS['D20_23'] = dict(
    fac='deathless', cls='Destroyer', name='Revenant destroyer', sym='bilateral', yaw=-1,  # meshed side-on: the long axis lay port to starboard
    cuts=[dict(name='dome', box=(.20, .31, -.035, .035, .066, .16))],                       # the AI turret blob on the spine
    kit=[('turret', 'gs', .25, 0, 0, 'top', dict(size='M', barrels=2, slot=0, wkind='gauss', arc='T', lift=.003)),
         ('spinal', 'gf', .31, 0, 0, 'top', dict(size='S', slot=1, wkind='gauss', arc='F', length=3.0)),
         ('engine_at', 'eP', 0, .10, -.078, 'stern', dict(r=.011, L=.016, pair=True)),
         ('engine_at', 'eQ', 0, .14, -.078, 'stern', dict(r=.011, L=.016, pair=True))],
    notes='pass 1')

SHIPS['D21_23'] = dict(
    fac='deathless', cls='Cruiser', name='Monolith cruiser', sym='bilateral',
    kit=[('turret', 'gs', -.20, .09, 0, 'top', dict(size='M', barrels=2, slot=0, slot_m=1, wkind='gauss', arc='T', pair=True, lift=.003)),
         ('spinal', 'doom', .30, 0, 0, 'top', dict(size='L', slot=2, wkind='doom', arc='F', length=2.5)),
         ('turret', 'sn', -.36, 0, 0, 'top', dict(size='M', barrels=2, slot=3, wkind='gsentry', arc='T', lift=.003)),
         ('engine_at', 'eP', 0, .06, -.20, 'stern', dict(r=.02, L=.028, pair=True))],
    notes='pass 1: flies long side first as in the game today (vetoable: the curved edge could lead)')

# ---------------------------------------------------------------------------------------------------------------------------------------
# Squadron craft (shared by every faction, tinted per faction in the game: built in the light Hegemony grey so a tint reads; Chorus wings
# fly the spore) and the objective structures (neutral light grey). Taste calls, vetoable. Craft mounts use scale: a size S mount is 10% of
# a 1.6-unit fighter.
SHIPS['S1_51'] = dict(
    fac='hegemony', cls='Squadron', name='Fighter wing', sym='bilateral', wkey='craft|fighter', breach=0, wreck=3, dress=.5,
    kit=[('turret', 'gn', .05, 0, 0, 'top', dict(size='S', barrels=2, slot=0, wkind='guns', arc='T', scale=.35)),
         ('engine_at', 'eC', 0, 0, -.01, 'stern', dict(r=.04, L=.05))],
    notes='pass 1')

SHIPS['S2_23'] = dict(
    fac='hegemony', cls='Squadron', name='Bomber wing', sym='bilateral', wkey='craft|bomber', breach=0, wreck=3, dress=.5,
    kit=[('turret', 'bb', 0, 0, 0, 'below', dict(size='S', barrels=1, slot=0, wkind='bombs', arc='T', scale=.35)),
         ('engine_at', 'eP', 0, .245, -.015, 'stern', dict(r=.02, L=.028, pair=True)),
         ('engine_at', 'eL', 0, .238, -.085, 'stern', dict(r=.02, L=.028, pair=True))],
    notes='pass 1')

SHIPS['B23_51'] = dict(
    fac='chorus', cls='Squadron', name='Spore wing', sym='organic', wkey='craft|spore', breach=0, wreck=3, snap=.015,
    kit=[('emitter', 'sp', 0, 0, 0, 'top', dict(size='S', slot=0, wkind='sporeb', arc='T', scale=.4))],
    notes='pass 1: the trailing tentacles stay (they read as the spore drifting)')

SHIPS['O1_37'] = dict(
    fac='hegemony', cls='station', name='Defence station', sym='bilateral', wkey='obj|station',
    kit=[('sensor_dome', 'sd', 0, 0, 0, 'top', dict(r=.03))],
    notes='pass 1: AI hull kept (vetoable: Kenney/KayKit station parts are allowed by the plan)')

SHIPS['O2_37'] = dict(
    fac='hegemony', cls='transport', name='Convoy transport', sym='bilateral', wkey='obj|transport',
    kit=[('engine_at', 'eP', 0, .045, .0, 'stern', dict(r=.02, L=.028, pair=True))],
    notes='pass 1')

SHIPS['O3_11'] = dict(
    fac='hegemony', cls='beacon', name='Relay beacon', sym='bilateral', wkey='obj|beacon', wreck=4,
    kit=[], notes='pass 1: stands upright as meshed (the tower is the beacon)')
