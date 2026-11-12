# Turret marking in a ship blend (issue 560; RULEBOOK 6.17, Ryan R219: turret guns turn to face their target, fixed side guns
# stay fixed). The game contract (the turret_<n> node, its turning mesh and its muzzles) is in hardpoints.py and
# docs/ship_pipeline/HARDPOINTS.md "Turrets". This file is the Blender side: how a blend says "this gun turns".
#
# The marking in a blend (the same for every faction kit):
#   <id>_turret        an EMPTY at the ring centre, on the ring's top face. Its local +Z is the turning axis (the mount normal),
#                      its local +X the rest aim projected into the ring's plane. Custom properties: turret=1, slot, weapon,
#                      arc_lo, arc_hi (bearings from the bow in degrees, + to port), rest_yaw, rest_pitch; socket (optional:
#                      the socket name the kit registered the muzzles under, when it differs from <id>).
#   its children       every mesh that turns (housing, mantlet, barrels, muzzle brakes), parented to it. The ring and the
#                      bolt ring are not its children: they stay on the hull.
# Two ways to get there:
#   1. the kit writes it while it builds (the build-sheet kit, tools/blender/build_sheets/kit.py emit(), issue 532);
#   2. the kit declares which of its named pieces turn (TURRET_TURN in its kit.py) and stage 7 applies mark_from_parts below to
#      the scene in memory before the export (the recipe kit's turret(), whose blends were built before this marking). The
#      blend on disk is never changed.
# A casemate or a broadside battery is never marked: its muzzles stay fixed to the hull.
import math, re
import bpy
from mathutils import Vector, Matrix


def pivots(sc):
    """the turret pivots a blend carries: [(empty, [turning mesh objects])], in name order"""
    out = []
    for o in sorted(sc.objects, key=lambda o: o.name):
        if o.type == 'EMPTY' and int(o.get('turret', 0) or 0) == 1:
            out.append((o, [c for c in o.children_recursive if c.type == 'MESH' and not c.hide_render]))
    return out


def _frame(origin, fwd, up):
    """a world matrix with +Z along up and +X along fwd projected off up"""
    u = Vector(up).normalized(); f = Vector(fwd) - u * Vector(fwd).dot(u)
    if f.length < 1e-6: f = Vector((1, 0, 0)) - u * u.x
    f.normalize(); y = u.cross(f).normalized()
    M = Matrix((f, y, u)).transposed().to_4x4(); M.translation = Vector(origin)
    return M


def mark_from_parts(sc, parts, turn_pieces, weapons, ring_piece='ring'):
    """apply the marking to a recipe-kit scene: for every ship-json socket whose part is 'turret' (and its '_s' mirror when the
    socket is a pair), make <socket>_turret at the top centre of <socket><ring_piece> and parent to it every mesh named
    <socket><piece>... for a piece in turn_pieces. weapons: the data.js list [(kind, arc)], for the slot's weapon and arc.
    Returns [(socket, empty, [meshes])] for the sockets it marked; a socket already marked in the blend is left as it is.
    Raises ValueError when a turret socket's ring or turning pieces are not in the scene (the export must fail loudly)."""
    import hardpoints as HP
    have = {o.name for o, _ in pivots(sc)}
    socks = []
    for e in parts:
        if e.get('part') != 'turret':
            continue
        socks.append((e['name'], e.get('slot'), e.get('aim', (1, 0, 0)), (e.get('extra') or {}).get('elev', 12)))
        if e.get('pair'):
            a = e.get('aim', (1, 0, 0))
            socks.append((e['name'] + '_s', e.get('slot_s', e.get('slot')), (a[0], -a[1], a[2]), (e.get('extra') or {}).get('elev', 12)))
    out = []
    pat = '|'.join(re.escape(p) for p in turn_pieces)
    for name, slot, aim, elev in socks:
        if name + '_turret' in have:
            continue
        ring = sc.objects.get(name + ring_piece)
        if ring is None:
            raise ValueError(f'turret socket {name}: no {name}{ring_piece} in this blend')
        rx = re.compile(r'^' + re.escape(name) + r'(' + pat + r')[A-Za-z0-9_.]*$')
        turn = [o for o in sc.objects if o.type == 'MESH' and rx.match(o.name)]   # 'turA' + a piece: never 'turA_s...'
        if not turn:
            raise ValueError(f'turret socket {name}: none of its turning pieces ({", ".join(turn_pieces)}) are in this blend')
        w = [ring.matrix_world @ Vector(b) for b in ring.bound_box]
        top = Vector(((min(v.x for v in w) + max(v.x for v in w)) / 2, (min(v.y for v in w) + max(v.y for v in w)) / 2, max(v.z for v in w)))
        piv = bpy.data.objects.new(name + '_turret', None); sc.collection.objects.link(piv)
        piv.empty_display_type = 'ARROWS'; piv.empty_display_size = .02
        piv.matrix_world = _frame(top, aim, (0, 0, 1))
        wk, arc = weapons[int(slot)] if slot is not None and int(slot) < len(weapons) else ('', 'T')
        lo, hi = HP.turret_arc(arc)
        piv['turret'] = 1; piv['socket'] = name; piv['slot'] = int(slot) if slot is not None else -1; piv['weapon'] = wk
        piv['arc_lo'] = lo; piv['arc_hi'] = hi; piv['rest_yaw'] = round(math.degrees(math.atan2(aim[1], aim[0])), 4)
        piv['rest_pitch'] = float(elev); piv['marked_by'] = 'stage 7 (tools/blender/kits/shared/turrets.py mark_from_parts)'
        bpy.context.view_layer.update()
        inv = piv.matrix_world.inverted()
        for o in turn:
            mw = o.matrix_world.copy(); o.parent = piv; o.matrix_parent_inverse = inv; o.matrix_world = mw
        out.append((name, piv, turn))
    bpy.context.view_layer.update()
    return out
