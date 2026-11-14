# The weapon-match check (issue 676; FINDINGS R241, ships.md section 0 "Visible weapons are the game's weapons").
# Ryan, Nov 13 2026: "all ships should have weapons that match their actual weapons in game, so they line up with firing,
# effects, turns, etc"; and "I'm fine with it if we have like 2 turrets tied to one weapon but it has to be consistent and
# line up with the in game behavior."
#
# A built sheet ship fails when any of these holds (each problem names its rule):
#   EXTRA   a visible part of a weapon kind (WEAPON_PART_KINDS: gun, turret, launcher, spinal) that is no mount of a data.js
#           weapon slot (a decorative or extra gun)
#   COUNT   a data.js weapon slot with no mount on the ship, or a mount whose weapon and arc name no slot of the ship
#   KIND    a mount whose part type or mount does not fit its data weapon (FITS below, one row per data.js weapon)
#   TIE     a mount with no muzzle, or a muzzle (the point that becomes its hp_w<slot> hard point) farther than TIE_TOL from
#           the mount's own mesh, so the shot would not leave the visible barrel or cell
#   ARC     a fixed mount (casemate, launcher, spinal, fixed organ) aiming outside its data.js arc, or a turret resting outside
#           its arc or turning through an arc other than the data arc
#   TURRET  a turret whose turning pieces do not hang under its turret node, or one of its muzzles off its turning mesh (the
#           flash would not turn with the barrels); or a weapon the game fires all round (arc T) shown on a fixed mount the
#           table does not allow there
#   SAME    the mounts of one slot differ in part type, mount (one turning, one fixed), barrel count or size (more than SIZE_TOL)
#   SPLIT   a mount of a slot that fires nothing on some volley. The game deals a volley's shots over the slot's muzzles in
#           turn (godot/fx/fx_hull.gd guns(): shot i takes muzzle (offset + i) mod count, the offset moving one on each
#           volley); this simulates every offset with the data.js shots and needs every mount to fire on every volley
# The pure check (check) takes plain records, so its self-test (weapon_match_selftest.py) runs with no Blender; collect()
# reads a built kit inside Blender. It runs in build.py (every mode that builds: <code>_weapon_match.json) and in the build
# contract (contract.to_recipe), so stage 4 refuses a ship that fails it.
import math

ARCS = {'F': (-60.0, 60.0), 'P': (30.0, 150.0), 'S': (-150.0, -30.0), 'T': (-180.0, 180.0), 'R': (120.0, 240.0)}  # core.js inArc
ARC_TOL = 1.0          # degrees of slack at an arc edge
SIZE_TOL = 1.3         # largest over smallest mount size in one slot
WEAPON_PART_KINDS = ('gun', 'spinal', 'rack', 'bow_launcher', 'launcher', 'turret')   # kit part kinds that read as weapons
# Not weapons, said so here so nobody adds them by mistake: a Hullbreaker 'tube' is a scoop or intake drum with a grille
# (its sheets name it so); a 'dish' and an 'antenna' are sensors; a 'claw', 'claw_arm' and 'prong' are grabbers.

# The table: each data.js weapon (W in data.js, its kind k in brackets), the part types that may show it and the mounts they
# may sit on. Part type is the kit's own (Kit.built 'type': a kit that builds each weapon its own way names it; the
# Hullbreaker kit has one gun builder, so its guns are type 'gun'). Mounts: turret (turns on a pivot), casemate (fixed in a
# flank), launcher (a rack or bow launcher, fixed), fixed (a spinal mount or a fixed organ).
FITS = {
    'autocannon': ({'gun'}, {'turret', 'casemate'}),          # battery
    'scatter': ({'gun'}, {'turret', 'casemate'}),             # battery
    'turret': ({'gun'}, {'turret'}),                          # battery: the Dorsal turret is a turret
    'battery': ({'gun'}, {'turret', 'casemate'}),             # battery
    'hbattery': ({'gun'}, {'turret', 'casemate'}),            # battery
    'flak': ({'gun', 'shredder'}, {'turret', 'casemate'}),    # flak: a Hullbreaker gun mount or the Eclipse null shredder
    'gsentry': ({'spire'}, {'turret'}),                       # flak: the Eclipse null spire
    'spores': ({'spore'}, {'turret'}),                        # flak: the Chorus spore organ
    'gauss': ({'nullcannon'}, {'turret'}),                    # gauss: the Eclipse null cannon
    'doom': ({'corona_arc'}, {'fixed'}),                      # lance: the Eclipse corona arc projector, spinal
    'torp': ({'rack', 'bow_launcher'}, {'launcher'}),         # torp: a rocket rack or a bow launcher
    'htorp': ({'rack', 'bow_launcher'}, {'launcher'}),        # torp
    'bioplasma': ({'throat'}, {'fixed'}),                     # bio: the Chorus throat, fixed forward
    'tendril': ({'tendril', 'mane'}, {'turret', 'fixed'}),    # bio: a tendril crown turns; the mane is a fixed organ
}


def tie_tol(radius):
    """how far a muzzle may sit from its mount's mesh: the bore or cell radius (the point sits in the opening) and a margin"""
    return 0.05 + 1.5 * float(radius or 0.0)


def bearing(v):
    """bearing of a direction from the bow, + to port (core.js inArc frame; the sheet's +X bow, +Y port)"""
    return math.degrees(math.atan2(v[1], v[0]))


def in_arc(b, letter):
    lo, hi = ARCS.get(letter, (-180.0, 180.0))
    if hi - lo >= 360.0:
        return True
    b = (b - lo) % 360.0
    return b <= (hi - lo) + ARC_TOL or b >= 360.0 - ARC_TOL


def slot_of(weapons, mounts):
    """the data.js slot index of every mount, as the build contract deals them (contract.slot_map: a pair listed once gives the
    slot to every mount of that pair; a pair listed twice deals its mounts over the slots in build order). Returns
    (slots, problems): no exception, so every problem is listed."""
    out, probs, groups = {}, [], {}
    for m in mounts:
        groups.setdefault((m['weapon'], m['letter']), []).append(m['id'])
    for (weapon, letter), fids in groups.items():
        hits = [i for i, (wk, arc) in enumerate(weapons) if wk == weapon and arc == letter]
        if not hits:
            probs.append(f'COUNT {", ".join(fids)}: weapon {weapon!r} arc {letter!r} is no slot of the data.js list {weapons}')
            continue
        if len(fids) < len(hits):
            probs.append(f'COUNT {", ".join(fids)}: {weapon} {letter} is {len(hits)} slots in data.js but the ship shows only {len(fids)} mounts')
        for k, fid in enumerate(fids):
            out[fid] = hits[min(len(hits) - 1, k * len(hits) // max(1, len(fids)))]
    return out, probs


def volleys(order, shots):
    """the mounts each volley fires from, for every offset the game can be at: order is the slot's muzzles as the game sorts
    them (one entry per muzzle: the mount id), shots the volley's shot count (fx_hull.gd guns())"""
    n = len(order)
    return [{order[(off + i) % n] for i in range(max(1, shots))} for off in range(n)] if n else []


def check(ship):
    """ship: dict(code, weapons=[(id, arc), ...] (data.js slot order), stats={weapon id: {'k', 'shots'}}, parts=[{id, kind,
    type}] (every part built), mounts=[{id, weapon, letter, type, mount, barrels, size, rest_yaw, muzzles=[{pos, aim, radius,
    d_part, d_turn}], turret=None or {arc_lo, arc_hi, letter, under}}] in build order).
    Returns a list of problems, each starting with its rule; empty when the ship passes."""
    probs = []
    weapons = [tuple(w) for w in ship['weapons']]
    mounts = ship['mounts']
    ids = {m['id'] for m in mounts}
    for p in ship['parts']:
        if p['kind'] in WEAPON_PART_KINDS and p['id'] not in ids:
            probs.append(f'EXTRA {p["id"]}: a visible {p.get("type") or p["kind"]} that is no mount of any data.js weapon slot (no decorative or extra guns, R241)')
    slots, sp = slot_of(weapons, mounts)
    probs += sp
    for i, (wk, arc) in enumerate(weapons):
        if not any(s == i for s in slots.values()):
            if not any(f'{wk!r} arc {arc!r}' in q or f'{wk} {arc} is' in q for q in sp):
                probs.append(f'COUNT slot {i} ({wk} {arc}): no mount on the ship shows this data.js weapon')
    by_slot = {}
    for m in mounts:
        fid = m['id']
        if fid in slots:
            by_slot.setdefault(slots[fid], []).append(m)
        row = FITS.get(m['weapon'])
        if row is None:
            probs.append(f'KIND {fid}: weapon {m["weapon"]!r} has no row in the weapon-match table (weapon_match.FITS); add it from data.js')
        else:
            types, mts = row
            if m['type'] not in types:
                probs.append(f'KIND {fid}: a {m["type"]} cannot show {m["weapon"]} (the table allows {sorted(types)})')
            if m['mount'] not in mts:
                probs.append(f'KIND {fid}: {m["weapon"]} on a {m["mount"]} mount (the table allows {sorted(mts)})')
        mz = m.get('muzzles') or []
        if not mz:
            probs.append(f'TIE {fid}: no muzzle registered, so it has no hard point to fire from')
        for j, q in enumerate(mz):
            tol = tie_tol(q.get('radius'))
            if q.get('d_part') is not None and q['d_part'] > tol:
                probs.append(f'TIE {fid}: muzzle {j} sits {q["d_part"]:.3f} from the mount\'s mesh (more than {tol:.3f}): its shots would not leave the visible barrel')
        letter = m['letter']
        if m['mount'] == 'turret':
            t = m.get('turret')
            if not t:
                probs.append(f'TURRET {fid}: a turning mount with no turret node')
            else:
                lo, hi = ARCS.get(letter, (-180.0, 180.0))
                if t.get('letter') not in (None, letter) or abs(float(t['arc_lo']) - lo) > 0.5 or abs(float(t['arc_hi']) - hi) > 0.5:
                    probs.append(f'ARC {fid}: the turret turns through {t["arc_lo"]:.0f} to {t["arc_hi"]:.0f}, the data arc {letter} is {lo:.0f} to {hi:.0f}')
                if not in_arc(float(m.get('rest_yaw', 0.0)), letter):
                    probs.append(f'ARC {fid}: the turret rests at bearing {float(m["rest_yaw"]):.0f}, outside its data arc {letter}')
                if not t.get('under', False):
                    probs.append(f'TURRET {fid}: its turning pieces do not all hang under its turret node')
                for j, q in enumerate(mz):
                    tol = tie_tol(q.get('radius'))
                    if q.get('d_turn') is None or q['d_turn'] > tol:
                        probs.append(f'TURRET {fid}: muzzle {j} is not on the turning mesh, so its flash would not turn with the barrels')
        else:
            if letter == 'T' and m['mount'] == 'casemate':
                probs.append(f'TURRET {fid}: {m["weapon"]} fires all round (arc T) but sits in a fixed casemate')
            for j, q in enumerate(mz):
                b = bearing(q['aim'])
                if abs(q['aim'][0]) + abs(q['aim'][1]) > 1e-3 and not in_arc(b, letter):
                    probs.append(f'ARC {fid}: muzzle {j} aims at bearing {b:.0f}, outside its data arc {letter} {ARCS.get(letter)}')
    for s, ms in sorted(by_slot.items()):
        wk, arc = weapons[s]
        if len(ms) > 1:
            first = ms[0]
            for m in ms[1:]:
                for key, what in (('type', 'part type'), ('mount', 'mount'), ('barrels', 'barrel count')):
                    if m.get(key) != first.get(key):
                        probs.append(f'SAME slot {s} ({wk} {arc}): {first["id"]} and {m["id"]} differ in {what} ({first.get(key)} and {m.get(key)}); one slot\'s mounts must match')
            sz = [float(m.get('size') or 0) for m in ms]
            if min(sz) > 0 and max(sz) / min(sz) > SIZE_TOL:
                probs.append(f'SAME slot {s} ({wk} {arc}): mount sizes run from {min(sz):.2f} to {max(sz):.2f} (more than x{SIZE_TOL})')
        shots = int((ship.get('stats') or {}).get(wk, {}).get('shots', 1))
        order = [m['id'] for m in ms for _ in (m.get('muzzles') or [])]
        if order:
            fired = volleys(order, shots)
            for m in ms:
                miss = sum(1 for v in fired if m['id'] not in v)
                if miss:
                    probs.append(f'SPLIT slot {s} ({wk} {arc}): {m["id"]} fires nothing on {miss} of {len(fired)} volleys ({shots} shots over '
                                 f'{len(order)} muzzles of {len(ms)} mounts); never a mount that fires nothing')
    return probs


def summary(ship, probs):
    """one plain record for the sheet folder (<code>_weapon_match.json) and the build log"""
    slots, _ = slot_of([tuple(w) for w in ship['weapons']], ship['mounts'])
    rows = []
    for i, (wk, arc) in enumerate(ship['weapons']):
        ms = [m for m in ship['mounts'] if slots.get(m['id']) == i]
        rows.append(dict(slot=i, weapon=wk, arc=arc, shots=int((ship.get('stats') or {}).get(wk, {}).get('shots', 1)),
                         mounts=[dict(id=m['id'], type=m['type'], mount=m['mount'], barrels=m.get('barrels'), muzzles=len(m.get('muzzles') or []))
                                 for m in ms]))
    return dict(code=ship.get('code'), result='PASS' if not probs else 'FAIL', problems=probs, slots=rows)


# ------------------------------------------------------------------------------------------------ inside Blender
def collect(K, weapons, stats):
    """the check's records from a built kit (kit.Kit after ship.build and K.finish), in the sheet's own units"""
    import bpy
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    built = {b['id']: b for b in K.built}
    feats = {f['id']: f for f in K.features}
    dg = bpy.context.evaluated_depsgraph_get()

    def bvh(objs):
        V, F = [], []
        for o in objs:
            e = o.evaluated_get(dg); me = e.to_mesh(); M = o.matrix_world; k = len(V)
            V.extend(M @ v.co for v in me.vertices); F.extend(tuple(k + i for i in p.vertices) for p in me.polygons)
            e.to_mesh_clear()
        return BVHTree.FromPolygons(V, F) if F else None

    def dist(T, p):
        if T is None: return None
        hit = T.find_nearest(Vector(p))
        return None if hit[0] is None else float(hit[3])

    mounts = []
    for fd in K.fitdata:
        if fd['kind'] not in ('gun', 'launcher'): continue
        fid = fd['id']; f = feats.get(fid, {}); b = built.get(fid, {})
        objs = [o for o in K.coll.objects if o.type == 'MESH' and o.get('grp') == fid]
        Tp = bvh(objs)
        piv = bpy.data.objects.get(fid + '_turret')
        tur = None; Tt = None
        if fd['kind'] == 'launcher':
            mount = 'launcher'
            mz = [dict(pos=tuple(a['pos']), aim=tuple(a['dir']), radius=float(a.get('r', 0))) for a in fd['apertures']]
            barrels = len(mz); size = max((float(a.get('r', 0)) for a in fd['apertures']), default=0.0) * len(mz)
        else:
            mt = fd.get('mount')
            mount = 'turret' if piv is not None else 'casemate' if mt == 'casemate' else 'fixed'
            mz = [dict(pos=tuple(m), aim=tuple(fd['aim']), radius=float(fd.get('bore', 0))) for m in fd['muzzles']]
            barrels = int(f.get('count', len(mz))); size = float(fd.get('hous_r') or 0)
        if piv is not None:
            turning = [o for o in objs if o.get('role') == 'turn']
            under = bool(turning) and all(o.parent == piv for o in turning) and all(o.parent != piv for o in objs if o.get('role') == 'mount')
            Tt = bvh(turning)
            tur = dict(arc_lo=float(piv.get('arc_lo', -180)), arc_hi=float(piv.get('arc_hi', 180)), letter=str(piv.get('slot', '')) or None, under=under)
        for q in mz:
            q['d_part'] = dist(Tp, q['pos'])
            q['d_turn'] = dist(Tt, q['pos']) if Tt is not None else None
        mounts.append(dict(id=fid, weapon=f.get('weapon') or '', letter=fd.get('slot') or f.get('slot') or 'T',
                           type=b.get('type') or b.get('kind') or fd['kind'], mount=mount, barrels=barrels, size=size,
                           rest_yaw=float(fd.get('rest_yaw', (f.get('aim') or (0.0, 0.0))[0])), muzzles=mz, turret=tur))
    parts = [dict(id=b['id'], kind=b['kind'], type=b.get('type')) for b in K.built]
    return dict(code=K.code, weapons=[list(w) for w in weapons], stats=stats, parts=parts, mounts=mounts)


def run(K, game):
    """collect and check a built kit against data.js ship `game`: (summary dict, problems)"""
    import os, sys
    rec = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'recipe'))
    if rec not in sys.path: sys.path.insert(0, rec)
    import gamedata
    weapons = gamedata.weapons(game)
    stats = {}
    for wk, _ in weapons:
        try: stats[wk] = gamedata.weapon_stats(wk)
        except ValueError: stats[wk] = dict(k='?', shots=1)
    ship = collect(K, weapons, stats)
    probs = check(ship)
    return summary(ship, probs), probs
