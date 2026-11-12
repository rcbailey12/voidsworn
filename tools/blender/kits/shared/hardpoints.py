# The hard point contract, shared by the recipe export (tools/recipe/export7.py), the recipe check
# (tools/recipe/check_export.py) and the standing gate (tools/recipe/standing.py). Plain Python, no bpy and no numpy, so it runs
# inside Blender, in Blender's own python and in the CI checks.
# The written contract is docs/ship_pipeline/HARDPOINTS.md. This file is the one table it names: the point types and their axes,
# the smallest required set per class, and the breach anchor count by class and faction.
# Frame: the game frame is +X bow, +Y up, -Z port (standard glTF, true chirality; tools/blender/a4/K1_DECISIONS.md decision 2).
# Node axes for every type: local -Z is the effect's forward (the barrel, plume, launch, breach tangent or party direction),
# local +Y is the effect's up (the mount normal, ship up or outward surface normal), local +X completes the right-handed frame.

# Point types the game needs. The name pattern is a Python regular expression; <n> is the 0-based counter per type and slot.
TYPES = (
    dict(kind='gun', pattern=r'hp_w(\d+)_([A-Za-z0-9_]+)_([FTPS])_(\d+)',
         what='weapon muzzle', axes='-Z along the barrel at rest, +Y away from the hull (the mount normal)',
         extras=('kind', 'size', 'arc', 'arc_deg', 'slot', 'weapon', 'radius', 'socket'),
         required='at least one per weapon slot of data.js (slot order), as many as the hull has barrels'),
    dict(kind='engine', pattern=r'hp_eng_(\d+)',
         what='engine exit', axes='-Z out of the bell along the plume (aft), +Y ship up',
         extras=('kind', 'radius', 'engine'), required='at least one on every ship that has an engine'),
    dict(kind='bay', pattern=r'hp_bay_(\d+)',
         what='hangar mouth and launch point', axes='-Z out of the mouth along the launch direction, +Y ship up',
         extras=('kind', 'hangar'), required='at least one when data.js gives the ship a hangar'),
    dict(kind='breach', pattern=r'hp_breach_(\d+)',
         what='breach anchor (where the hull opens when it dies)',
         axes='+Y is the outward surface normal, -Z is a tangent along the hull',
         extras=('kind', 'section', 'side', 'clear'),
         required='the class and faction count in BREACH below, spread over prow, mid and eng, both sides balanced'),
    dict(kind='core', pattern=r'hp_core',
         what='hull centre of mass (death explosion origin)', axes='identity: the ship frame itself',
         extras=('kind',), required='exactly one on every ship'),
    dict(kind='rcs', pattern=r'hp_rcs_(\d+)',
         what='braking puff origin (attitude thruster)', axes='-Z along the braking thrust (forward for a braking burn), +Y ship up',
         extras=('kind', 'side'), required='two, one port and one starboard, on the forward half'),
    dict(kind='board', pattern=r'hp_board_(\d+)',
         what='boarding origin', axes='-Z out of the hull toward the target (the side normal at rest), +Y ship up',
         extras=('kind', 'side'), required='two, one port and one starboard, on the mid hull'),
)

NAME_PATTERNS = {t['kind']: t['pattern'] for t in TYPES}
POINT_TYPE = {t['kind']: t for t in TYPES}

# Breach anchors by class: the base count from docs/playbooks/factions.md, "Breach anchors by class". A faction may add or
# remove one where its sheet says so (FACTION_ADJUST). No fixed count (Ryan, R164), never a constant.
BREACH_BASE = {
    'Squadron': 0, 'beacon': 0,
    'Frigate': 2, 'Destroyer': 3, 'Cruiser': 4, 'transport': 4,
    'Carrier': 6, 'Battleship': 6, 'Battle-barge': 6,
    'Dreadnought': 8, 'Super-dreadnought': 8, 'Ark': 8, 'Bio-titan': 8, 'Tomb-ark': 8,
    'station': 8,
}

# Faction names in the recipe's ship json and in data.js point at the same sheet. The first name is the data.js fac value.
FACTION_ALIAS = {
    'corsair': 'corsair', 'hullbreakers': 'corsair', 'ashfall hullbreakers': 'corsair', 'ashfall': 'corsair',
    'voidsworn': 'voidsworn', 'sunward crusade': 'voidsworn', 'sunward': 'voidsworn',
    'ithar': 'ithar', 'glasswrights': 'ithar', 'the glasswrights': 'ithar',
    'deathless': 'deathless', 'eclipse': 'deathless', 'the eclipse': 'deathless',
    'chorus': 'chorus', 'the chorus': 'chorus',
    'hegemony': 'hegemony', 'hegemony navy': 'hegemony',
}

# The faction theme on top of the class base (factions.md, each faction sheet's "How it breaks"). These are the only
# adjustments; everything else is the base count.
FACTION_ADJUST = {
    'corsair': 1,      # "One more breach anchor than the base count, placed unevenly."
    'ithar': -1,       # "One fewer breach anchor than the base count; each large optic is its own break piece."
    'chorus': 'big+1',  # "One more breach anchor than the base count on the big ones."
}

# Where a faction's side-hull anchors prefer to sit, in ship units on the z axis (the side height the sheet names). None means
# no preference: the scan takes the clearest open hull point nearest the section middle.
FACTION_Z = {
    'voidsworn': 0.000,   # broadside deck line, evenly spaced
    'hegemony': -0.020,   # module joints
    'corsair': None,      # uneven, jittered below
    'ithar': -0.010,      # lens bays
    'deathless': 0.010,   # shade bands
    'chorus': -0.060,     # sacs and flanks
}

BAND = {
    'Frigate': 'S', 'Squadron': 'S', 'beacon': 'S',
    'Destroyer': 'M', 'Cruiser': 'M', 'transport': 'M',
    'Battleship': 'L', 'Carrier': 'L', 'Battle-barge': 'L',
    'Dreadnought': 'XL', 'Super-dreadnought': 'XL', 'Ark': 'XL', 'Bio-titan': 'XL', 'Tomb-ark': 'XL', 'station': 'XL',
}

SECTIONS = ('prow', 'mid', 'eng')


def faction_key(name):
    """the data.js fac value for any name the ship json or a sheet uses (an unknown name is returned in lower case)"""
    s = str(name or '').strip().lower()
    return FACTION_ALIAS.get(s, s)


def band(cls):
    if cls not in BAND:
        raise ValueError(f'unknown hull class {cls!r}: add it to BAND and BREACH_BASE in hardpoints.py (Board, issue 363: never a silent default)')
    return BAND[cls]


def breach_base(cls):
    if cls not in BREACH_BASE:
        raise ValueError(f'unknown hull class {cls!r}: add it to BREACH_BASE in hardpoints.py (Board, issue 363: never a silent default)')
    return BREACH_BASE[cls]


def breach_adjust(cls, faction):
    """the faction's own +1 or -1, from the faction sheets; zero on craft, beacons and stations"""
    base = breach_base(cls)
    if base <= 0:
        return 0
    f = faction_key(faction)
    adj = FACTION_ADJUST.get(f, 0)
    if adj == 'big+1':
        return 1 if base >= 6 else 0
    return int(adj)


def expected_breach(cls, faction):
    """the one number check_export.py reads for a hull of this class and faction (never a constant)"""
    return max(0, breach_base(cls) + breach_adjust(cls, faction))


def sections_for(n):
    """how many anchors each section carries for n anchors: even, with the extra in mid first, then prow, then eng"""
    n = int(n)
    if n <= 0:
        return {'prow': 0, 'mid': 0, 'eng': 0}
    if n == 1:
        return {'prow': 0, 'mid': 1, 'eng': 0}
    if n == 2:
        return {'prow': 1, 'mid': 0, 'eng': 1}
    q, r = divmod(n, 3)
    d = {s: q for s in SECTIONS}
    for s in ('mid', 'prow', 'eng')[:r]:
        d[s] += 1
    return d


def sides_for(n):
    """the side of each anchor, alternating port and starboard so the pair stays within one of even"""
    return ['P' if i % 2 == 0 else 'S' for i in range(int(n))]


def breach_layout(n):
    """[(section, side), ...] in the order the export writes them: even sections, alternating sides"""
    sec = sections_for(n)
    body = [s for s in SECTIONS for _ in range(sec[s])]
    return list(zip(body, sides_for(n)))


def required_points(weapons, cls, faction, hangar=0):
    """the smallest required set per class. weapons is the data.js [(kind, arc), ...] list (slot order); hangar is data.js's
    hangar value (0 when the ship has none). Counts are minimums except breach, which is exact."""
    slots = len(weapons or [])
    d = dict(weapon_slots=slots, core=1, engine=0, bay=0, breach=expected_breach(cls, faction), rcs=0, board=0)
    if cls in ('Squadron', 'beacon'):
        return d                                     # craft and beacons cannot brake or board, and carry no breach anchors
    if cls == 'station':
        return d                                     # a station is placed, not flown: no engine, braking or boarding origin
    d['engine'] = 1
    d['rcs'] = 2
    d['board'] = 2
    if int(hangar or 0) > 0:
        d['bay'] = 1                                 # one launch point for every hangar the rules give the ship
    return d


def missing_required(counts, weapons, cls, faction, hangar=0):
    """problems for a written point set against the smallest required set: [] when the export may pass"""
    req = required_points(weapons, cls, faction, hangar)
    probs = []
    if counts.get('gun', 0) < len(weapons or []):
        probs.append(f'{len(weapons or [])} weapon slots need at least one gun point each ({counts.get("gun", 0)} written)')
    if counts.get('core', 0) != req['core']:
        probs.append(f'need exactly {req["core"]} hp_core ({counts.get("core", 0)} written)')
    for kind, key, name in (('engine', 'engine', 'hp_eng'), ('rcs', 'rcs', 'hp_rcs'), ('board', 'board', 'hp_board'), ('bay', 'bay', 'hp_bay')):
        if counts.get(kind, 0) < req[key]:
            probs.append(f'need at least {req[key]} {name} ({counts.get(kind, 0)} written)')
    if counts.get('breach', 0) != req['breach']:
        probs.append(f'need exactly {req["breach"]} hp_breach for a {cls} of {faction_key(faction)} ({counts.get("breach", 0)} written)')
    return probs


def name_problem(name):
    """the point type for a written node name, or None when the name is not one the contract defines"""
    import re
    for t in TYPES:
        if re.fullmatch(t['pattern'], str(name)):
            return None
    return f'{name}: not a hard point name the contract defines'


def check_breach_layout(rows):
    """rows: [(section, side), ...] for the written breach anchors. Problems against the class and faction layout contract:
    count is checked by the caller (it knows the class), this checks section coverage and side balance."""
    n = len(rows)
    probs = []
    if not n:
        return probs
    sec = sections_for(n)
    got = {s: 0 for s in SECTIONS}
    p = s = 0
    for section, side in rows:
        if section in got:
            got[section] += 1
        if side == 'P':
            p += 1
        elif side == 'S':
            s += 1
    for k in SECTIONS:
        if got[k] < 1 and sec[k] > 0:
            probs.append(f'the {k} section has no breach anchor (the contract for {n} is {sec})')
    if abs(p - s) > 1:
        probs.append(f'breach anchors are {p} port and {s} starboard: the pair must stay within one of even')
    return probs


# ---------------------------------------------------------------------------------------------------------------- turrets (issue 560)
# RULEBOOK 6.17 (Ryan, Nov 11 2026, R219: "I agree with your design on turrets"): turret guns turn to face their target when
# they fire; fixed side guns (casemates, broadside batteries) stay fixed. A turret reaches the game as its own node:
#   turret_<n>          an empty node, a direct child of the ship node, at the ring centre (the pivot). Local +Y is the turning
#                       axis (the mount normal, away from the hull); local -Z is the rest aim projected into the ring's plane
#                       (the same axes as every hard point). extras: kind=turret, id (the kit's part id), socket, slot, weapon,
#                       arc_lo and arc_hi (bearings in degrees from the bow, + to port: the arc the turret may train through),
#                       rest_yaw (the rest aim's bearing), rest_pitch (the barrels' rest elevation).
#   turret_<n>_turn     the turning mesh (housing, mantlet, barrels): a child of turret_<n>, in its frame.
#   hp_w<...>           each muzzle of that turret's barrels: a child of turret_<n> (so it turns with the barrels), with the
#                       weapon extras plus turret=<n>. Every other hard point stays a direct child of the ship node.
# The ring (the part that stays on the hull) stays in the ship mesh. A casemate or broadside battery is not a turret: its
# muzzles stay direct children of the ship node and never move.
TURRET_PATTERN = r'turret_(\d+)'
TURRET_MESH_PATTERN = r'turret_(\d+)_turn'
TURRET_EXTRAS = ('kind', 'id', 'socket', 'slot', 'weapon', 'arc_lo', 'arc_hi', 'rest_yaw', 'rest_pitch')
# The rules' firing arcs (core.js inArc: F within 60.5 degrees of the bow, S and P 29.5 to 150.5 to one side, T all round),
# as bearings from the bow, + to port. A turret whose kit gives no arc of its own trains through its slot's rules arc.
RULES_ARC = {'F': (-60.0, 60.0), 'P': (30.0, 150.0), 'S': (-150.0, -30.0), 'T': (-180.0, 180.0), 'R': (120.0, 240.0)}


def turret_arc(arc_letter, kit_lo=None, kit_hi=None):
    """the arc a turret trains through: the kit's own when it gives one, else the slot's rules arc"""
    if kit_lo is not None and kit_hi is not None:
        return float(kit_lo), float(kit_hi)
    return RULES_ARC.get(str(arc_letter), (-180.0, 180.0))


def turret_problems(rows):
    """rows: [dict(name, extras, has_mesh, muzzles, up_dot_normal)] for the written turret nodes. Problems with the marking."""
    import re
    probs = []
    for r in rows:
        nm = r['name']; ex = r.get('extras') or {}
        if not re.fullmatch(TURRET_PATTERN, nm):
            probs.append(f'{nm}: not a turret node name the contract defines (turret_<n>)')
        for k in TURRET_EXTRAS:
            if k not in ex:
                probs.append(f'{nm} has no extras.{k}')
        if ex.get('kind') not in (None, 'turret'):
            probs.append(f'{nm}: extras.kind is {ex.get("kind")!r}, not turret')
        lo, hi = ex.get('arc_lo'), ex.get('arc_hi')
        if isinstance(lo, (int, float)) and isinstance(hi, (int, float)):
            if not lo < hi or hi - lo > 360.0 + 1e-6:
                probs.append(f'{nm}: the arc {lo} to {hi} is not a range of at most 360 degrees')
            ry = ex.get('rest_yaw')
            if isinstance(ry, (int, float)) and not (lo - 1e-6 <= ry <= hi + 1e-6 or lo - 1e-6 <= ry + 360 <= hi + 1e-6 or lo - 1e-6 <= ry - 360 <= hi + 1e-6):
                probs.append(f'{nm}: rests at bearing {ry}, outside its own arc {lo} to {hi}')
        if not r.get('has_mesh'):
            probs.append(f'{nm} has no turning mesh ({nm}_turn): the barrels would not turn')
        if not r.get('muzzles'):
            probs.append(f'{nm} carries no hp_w muzzle: the flash would not follow the barrel')
    return probs
