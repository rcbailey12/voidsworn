# A4 ship files: one entry per hull, the "ship template as data" (K1 decision 6). Blender working frame (frame.py): x bow, y PORT, z up,
# length 1.0. Positions are where a ray from `side` first meets the hull (the coordinate along the ray is ignored).
#
# entry keys:
#   fac, cls       faction and data.js class (the class sets part sizes through kit.CLS_LEN, and the weapon slots below)
#   name           display name
#   sym            'bilateral' (mirrored pairs) | 'corsair' (lopsided on purpose) | 'organic' (pairs where the body allows)
#   yaw            the game's AI_HULL_YAW for side-on meshes
#   cuts           AI parts taken out before refining (cuts.py): dict(name, box=(x0, x1, y0, y1, z0, z1), mirror, cover, pad, raise)
#                  or dict(name, dir='up'|'down'|'aft'|'fore'|'port'|'stbd', level, max_w, min_ratio, box)
#   kit            hand-built parts, in order: (function, name, x, y, z, side, {kwargs}); kwargs: pair, aim, size, slot, wkind, arc, ...
#                  functions: turret casemate spinal launcher emitter engine_at thruster_pod radiators antenna sensor_dome bridge tank bay
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
KEYS = {'fac', 'cls', 'name', 'sym', 'yaw', 'cuts', 'kit', 'dress', 'breach', 'wreck', 'notes', 'snap', 'needle', 'wkey', 'keep_islands'}
FNS = {  # kwargs common to all: pair, aim, align ('axis' default: stand square to the side; 'surface': follow the local normal)
       'turret', 'casemate', 'spinal', 'launcher', 'emitter', 'engine_at', 'thruster_pod', 'radiators', 'antenna', 'sensor_dome', 'bridge', 'tank', 'bay', 'cover', 'sail'}
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

# ---------------------------------------------------------------------------------------------------------------------------------------
# Corsair (barge grammar: rust-and-bone salvage, lopsided, junk bolted on; space parts only)
SHIPS['C13s_23'] = dict(
    fac='corsair', cls='Frigate', name='Raider-class frigate', sym='corsair',
    cuts=[dict(name='spine', box=(-.06, .34, -.032, .032, .088, .30)),          # AI top gun, tower and bent pipe mast: rebuilt
          dict(name='crown', box=(-.52, -.385, -.08, .08, -.07, .07))],         # AI engine crown with prongs: rebuilt as bells
    kit=[('turret', 'ac', .16, 0, 0, 'top', dict(size='M', barrels=2, slot=0, wkind='autocannon', arc='T', lift=.035)),
         ('antenna', 'ant', .00, 0, 0, 'top', dict(h=.075)),
         ('engine_at', 'eM', 0, 0, 0, 'stern', dict(r=.040, L=.055)),
         ('engine_at', 'eP', 0, .056, -.038, 'stern', dict(r=.020, L=.030)),
         ('engine_at', 'eS', 0, -.050, .036, 'stern', dict(r=.016, L=.026)),
         ('radiators', 'rad', -.20, 0, 0, 'top', dict(length=.07, height=.035)),
         ('tank', 'tk', -.12, .052, 0, 'top', dict(r=.011, length=.06)),
         ('sensor_dome', 'sd', .31, 0, 0, 'top', dict(r=.011))],
    notes='first pass')

SHIPS['C14s_23'] = dict(
    fac='corsair', cls='Destroyer', name='Reaver-class destroyer', sym='corsair',
    cuts=[dict(name='tower', box=(.075, .27, -.075, .075, .035, .30)),          # AI lattice tower and crossbar mast (naval tells): rebuilt as antenna arrays
          dict(name='arch', box=(-.50, -.255, -.13, .13, .005, .30)),           # AI wire arch over the stern: rebuilt as heat radiators
          dict(name='nozzle', box=(-.52, -.465, -.065, .065, -.12, .005)),      # AI engine ring at the stern face: rebuilt as a bell
          dict(name='funnel', box=(-.045, .055, -.065, .075, .03, .30))],       # AI smokestack and leaning wire sticks: rebuilt as radiators
    kit=[('spinal', 'torp', .33, 0, 0, 'top', dict(size='M', slot=0, wkind='torp', arc='F', tubes=4)),
         ('casemate', 'scat', .06, 0, -.07, 'stbd', dict(size='M', barrels=2, slot=1, wkind='scatter', arc='S', aim=(.26, -.97, 0))),
         ('antenna', 'ant', .17, .02, 0, 'top', dict(h=.10)),
         ('antenna', 'ant2', .12, -.035, 0, 'top', dict(h=.06, dishes=1)),
         ('radiators', 'rad', -.37, 0, 0, 'top', dict(length=.12, height=.05, n_fins=3)),
         ('radiators', 'rad2', .005, .005, 0, 'top', dict(length=.07, height=.04, n_fins=2, splay=24)),
         ('engine_at', 'eM', 0, 0, -.06, 'stern', dict(r=.046, L=.06)),
         ('engine_at', 'eP', 0, .062, -.10, 'stern', dict(r=.019, L=.03)),
         ('engine_at', 'eS', 0, -.058, -.025, 'stern', dict(r=.024, L=.035)),
         ('tank', 'tk', -.17, -.05, 0, 'top', dict(r=.012, length=.07)),
         ('sensor_dome', 'sd', .02, 0, 0, 'top', dict(r=.013))],
    notes='first pass')

SHIPS['C15s_23'] = dict(
    fac='corsair', cls='Cruiser', name='Marauder-class cruiser', sym='corsair',
    yaw=2,  # meshed back to front: the rounded nose is at -x in hulls_hi and the crane at +x, so today's game flies it stern first
    cuts=[dict(name='crane', box=(-.50, -.02, -.07, .07, .012, .30)),          # AI A-frame crane with cables (rigging: a naval tell)
          dict(name='fork', box=(.115, .225, -.055, .055, .055, .30)),          # AI fork tower and melted top gun
          dict(name='domes', box=(.31, .445, .045, .125, -.055, .045), mirror=True)],  # AI side gun domes and prongs
    kit=[('casemate', 'scat', .378, 0, -.005, 'port', dict(size='M', barrels=2, slot=0, slot_m=1, wkind='scatter', arc='P', aim=(.26, .97, 0), pair=True)),
         ('spinal', 'torp', .29, 0, 0, 'top', dict(size='M', slot=2, wkind='torp', arc='F', tubes=4)),
         ('turret', 'flak', .145, 0, 0, 'top', dict(size='S', barrels=2, slot=3, wkind='flak', arc='T', lift=.02)),
         ('antenna', 'ant', .195, .01, 0, 'top', dict(h=.10)),
         ('antenna', 'ant2', -.25, .025, 0, 'top', dict(h=.06, dishes=1)),
         ('radiators', 'rad', -.39, 0, 0, 'top', dict(length=.10, height=.05, n_fins=2)),
         ('engine_at', 'eM', 0, 0, -.02, 'stern', dict(r=.036, L=.05)),
         ('engine_at', 'eP', 0, .052, .004, 'stern', dict(r=.020, L=.03)),
         ('engine_at', 'eS', 0, -.046, -.052, 'stern', dict(r=.025, L=.035)),
         ('tank', 'tk', -.15, -.04, 0, 'top', dict(r=.011, length=.07))],
    notes='first pass')

SHIPS['C16s_23'] = dict(
    fac='corsair', cls='Carrier', name='Hulk-carrier', sym='corsair',
    cuts=[dict(name='mast', box=(.115, .20, -.05, .05, .105, .30)),           # AI thin mast sticks and the melted star part
          dict(name='spikes', box=(-.50, -.355, -.075, .075, .062, .30)),       # AI spiky stern clusters
          dict(name='sticks', dir='aft', level=.40, max_w=.03, min_ratio=1.6),  # thin AI sticks trailing aft (wire debris)
          dict(name='bulb', box=(.33, .47, -.055, .055, -.22, -.095))],         # AI bulb on a stalk under the bow
    kit=[('turret', 'tA', .26, 0, 0, 'top', dict(size='M', barrels=2, slot=0, wkind='turret', arc='T', lift=.01)),
         ('turret', 'tB', -.15, 0, 0, 'top', dict(size='M', barrels=3, slot=1, wkind='turret', arc='T', lift=.012)),
         ('bay', 'bay', .05, 0, -.05, 'port', dict(width=.085, height=.05, pair=True)),
         ('antenna', 'ant', .155, -.01, 0, 'top', dict(h=.11)),
         ('radiators', 'rad', -.42, 0, 0, 'top', dict(length=.09, height=.055, n_fins=2)),
         ('engine_at', 'eP', 0, .046, .005, 'stern', dict(r=.032, L=.05)),
         ('engine_at', 'eS', 0, -.044, -.004, 'stern', dict(r=.026, L=.042)),
         ('engine_at', 'eB', 0, 0, -.075, 'stern', dict(r=.021, L=.03)),
         ('sensor_dome', 'sd', .40, 0, 0, 'below', dict(r=.02)),
         ('tank', 'tk', -.05, .07, 0, 'top', dict(r=.012, length=.08))],
    notes='first pass')
