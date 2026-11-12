# The build contract between a build sheet and the ship recipe (issue 592; RULEBOOK 0.9, R225: each fact has one home).
# The approved build sheet (ships/<code>.py, built with kit.py) is the design: its masses, part builders, mounts, seams,
# insides and hard points are decided there once. This step turns the built sheet scene, in place, into the scene the recipe
# stages read (audit.py, export7.py, export3.py, render and outline tools), without changing the design:
#
#   datum                     the sheet writes (one home)                   the recipe reads (this step writes it)
#   units                     world units, design origin                    length one: every mesh scaled by 1 / model length
#                                                                           (the x extent of the outside), about the same origin
#   class length              ships/<code>.py LENGTH                        scene r209_length_world (export7 and the manifest)
#   hull thickness            the hull loft's solidify modifier 'shell'     the same modifier, named 'skin', thickness scaled
#   insides                   objects with inside=True (decks, bulkheads,  role 'interior', visible to the render and export
#                             rooms), in the <code>_inside collection
#   hull and parts            role 'hull' (masses, plates); every other     unchanged: export7 joins role 'hull' as the hull
#                             role is a part (mount, turn, body, ...)       surface and everything else but interiors as parts
#   seams                     K.break_line rows: kind 'trans' at x;         scene r209_t_lines (x) and r209_l_line ([z, x0, x1]
#                             kind 'long' along a path of (x, z)            or [] when the sheet authors no longitudinal seam)
#   gun and launcher mounts   kit fit records (muzzles, barrel aim, bore,  scene r209_hp muzzles (slot = the data.js index of the
#                             mount normal, slot letter and weapon)         sheet's weapon and arc) and r209_guns (aim, normal)
#   turrets                   pivot empties <id>_turret, turning meshes     unchanged hierarchy; the pivot's slot letter becomes
#                             as children (R219)                            the data.js slot index
#   engines                   K.engine: the bell exit centre and radius     scene r209_hp engines (aft, the open bell's centre)
#   core, breach, rcs,        K.point rows (bay with its launch dir)        scene r209_points (export7 uses them instead of
#   board, bay                                                              placing its own), r209_hp bays
#
# Nothing is invented: a sheet without a datum the recipe needs fails here, by name.
# usage (inside Blender, the sheet built and finished): contract.to_recipe(K, ship_json_dict) -> record dict
import json, math, os, sys
import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
RECIPE = os.path.normpath(os.path.join(HERE, '..', '..', 'recipe'))


class ContractError(ValueError):
    pass


def _bbox(objs):
    lo = Vector((1e9, 1e9, 1e9)); hi = Vector((-1e9, -1e9, -1e9))
    dg = bpy.context.evaluated_depsgraph_get()
    for o in objs:
        e = o.evaluated_get(dg); M = o.matrix_world
        for v in e.data.vertices:
            w = M @ v.co
            lo = Vector(map(min, lo, w)); hi = Vector(map(max, hi, w))
    return lo, hi


def slot_index(weapons, letter, weapon, fid):
    """the data.js slot of a sheet gun: its weapon and arc letter must name exactly one entry of the ship's weapon list"""
    hits = [i for i, (wk, arc) in enumerate(weapons) if wk == weapon and arc == letter]
    if len(hits) != 1:
        raise ContractError(f'{fid}: weapon {weapon!r} arc {letter!r} names {len(hits)} slots of the data.js list {weapons}')
    return hits[0]


def _scale_scene(sc, s):
    """every mesh to length one about the design origin; turret pivots keep their rotation, their children their frame"""
    S = Matrix.Scale(s, 4)
    tops = [o for o in sc.objects if o.parent is None]
    for o in tops:
        if o.type == 'MESH':
            o.data.transform(S @ o.matrix_world); o.matrix_world = Matrix.Identity(4)
        else:
            mw = o.matrix_world.copy(); mw.translation = mw.translation * s; o.matrix_world = mw
            for c in o.children_recursive:
                if c.type == 'MESH':
                    c.data.transform(S)
                c.matrix_basis.translation = c.matrix_basis.translation * s
    for o in sc.objects:
        for md in o.modifiers:
            if md.type == 'SOLIDIFY':
                md.thickness *= s
                if md.name == 'shell': md.name = 'skin'
    bpy.context.view_layer.update()


def to_recipe(K, ship):
    sys.path.insert(0, RECIPE)
    import gamedata
    sc = bpy.context.scene
    game = ship.get('game_ship')
    if not game: raise ContractError('the ship json has no game_ship (the data.js id)')
    weapons = gamedata.weapons(game); hangar = int(gamedata.ship_attr(game, 'hangar', default=0) or 0)
    outside = [o for o in K.coll.objects if o.type == 'MESH']
    lo, hi = _bbox(outside); L = hi.x - lo.x; s = 1.0 / L
    _scale_scene(sc, s)
    P = lambda v: [float(c) * s for c in v]  # noqa: E731  a sheet position in the recipe frame

    # insides and roles
    for o in K.cin.objects:
        o['role'] = 'interior'; o.hide_render = False; o.hide_set(False)
    for o in sc.objects:
        if o.type != 'MESH': continue
        w = [o.matrix_world @ Vector(b) for b in o.bound_box]
        o['size'] = (Vector([max(v[i] for v in w) for i in range(3)]) - Vector([min(v[i] for v in w) for i in range(3)])).length
    if not any(o.get('role') == 'interior' for o in sc.objects): raise ContractError('the sheet has no INSIDE geometry')

    # seams
    breaks = [r for r in K.inside if r.get('kind') == 'break']
    t_lines = sorted(r['x'] * s for r in breaks if r.get('orient', 'trans') == 'trans')
    longs = [r for r in breaks if r.get('orient') == 'long']
    if len(longs) > 1:
        raise ContractError(f'{len(longs)} longitudinal seams ({", ".join(r["name"] for r in longs)}): format version 1 holds one')
    l_line = []
    if longs:
        pts = longs[0].get('path') or []
        if len(pts) < 2: raise ContractError(f'longitudinal seam {longs[0]["name"]} has no path of (x, z) points')
        l_line = [sum(p[1] for p in pts) / len(pts) * s, min(p[0] for p in pts) * s, max(p[0] for p in pts) * s]
    if not t_lines: raise ContractError('the sheet authors no transverse seam')
    sc['r209_t_lines'] = t_lines; sc['r209_l_line'] = l_line

    # gun and launcher mounts, engines
    feats = {f['id']: f for f in K.features}
    hp = dict(muzzles=[], engines=[], bays=[]); guns = []
    for fd in K.fitdata:
        fid = fd['id']; f = feats.get(fid, {})
        if fd['kind'] == 'gun':
            if 'aim' not in fd: raise ContractError(f'{fid}: the kit recorded no barrel aim')
            slot = slot_index(weapons, fd['slot'], f.get('weapon'), fid)
            part = 'casemate' if fd.get('mount') == 'casemate' else 'turret'
            for i, m in enumerate(fd['muzzles']):
                hp['muzzles'].append(dict(name=f'{fid}_{i}', socket=fid, tip=P(m), aim=list(fd['aim']), normal=list(fd['up']),
                                          radius=float(fd.get('bore', 0)) * s, slot=slot, part=part))
            guns.append([fid, list(fd['aim']), list(fd['up'])])
        elif fd['kind'] == 'launcher':
            slot = slot_index(weapons, fd['slot'], f.get('weapon'), fid)
            ap = fd['apertures']; aim = list(ap[0]['dir'])
            for i, e in enumerate(ap):
                hp['muzzles'].append(dict(name=f'{fid}_{i}', socket=fid, tip=P(e['pos']), aim=list(e['dir']), normal=[0.0, 0.0, 1.0],
                                          radius=float(e.get('r', 0)) * s, slot=slot, part='drum_rack'))
            guns.append([fid, aim, [0.0, 0.0, 1.0]])
    for f in K.features:
        if f['kind'] == 'engine':
            hp['engines'].append(dict(name=f['id'], pos=P(f['exit']), dir=[-1.0, 0.0, 0.0], radius=float(f['radius']) * s))
    # the sheet's own hard points: core, breach anchors, braking and boarding origins, bays
    pts = []
    for p in K.points:
        side = {'port': 'P', 'stbd': 'S', 'P': 'P', 'S': 'S'}.get(p.get('side') or '', '')
        if p['kind'] == 'bay':
            if not p.get('dir'): raise ContractError(f'bay {p["name"]} has no launch direction (K.point dir=)')
            hp['bays'].append(dict(name=p['name'], pos=P(p['pos']), dir=list(p['dir']), hangar=hangar))
        else:
            pts.append(dict(kind=p['kind'], name=p['name'], pos=P(p['pos']), side=side, section=p.get('section') or ''))
    if not hp['engines']: raise ContractError('the sheet has no engine')
    sc['r209_hp'] = json.dumps(hp); sc['r209_guns'] = json.dumps(guns); sc['r209_points'] = json.dumps(pts)

    # turret pivots: the data.js slot index in place of the sheet's arc letter
    pivots = [o for o in sc.objects if o.type == 'EMPTY' and o.get('turret')]
    for pv in pivots:
        fid = pv.name[:-len('_turret')] if pv.name.endswith('_turret') else pv.name
        pv['slot'] = slot_index(weapons, str(pv.get('slot')), str(pv.get('weapon')), fid); pv['socket'] = fid

    sc['r209_length_world'] = float(K.length); sc['r209_sheet'] = K.code; sc['r209_scale'] = s
    return dict(sheet=K.code, model_length=round(L, 5), scale=s, length_world=K.length, t_lines=[round(x, 5) for x in t_lines], l_line=l_line,
                muzzles=len(hp['muzzles']), guns=len(guns), engines=len(hp['engines']), bays=len(hp['bays']), points=len(pts),
                turrets=sorted(pv.name for pv in pivots), interior_objects=sum(o.get('role') == 'interior' for o in sc.objects),
                slots={f'{wk} {arc}': i for i, (wk, arc) in enumerate(weapons)})
