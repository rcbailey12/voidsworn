# A4 kit rollout: one ship from hulls_hi to Godot-ready files, following the ship-kit skill (build, check, export).
#   1. load the AI hull in the true-chirality frame (frame.py), take out what gets rebuilt by hand (cuts.py, from the ship file)
#   2. refine it (adaptive PN, hullio.pn_refine), cover the cut holes, build the hand-made parts (kit.py) and the faction surface detail
#      (a2detail dress.py, dress4.py for Corsair), record the hard points
#   3. audit (blocking): no floating parts, no backward guns, port mounts on the port side, every weapon slot has a mount
#   4. one UV atlas, bakes (bakemat4.py: albedo, ORM, emissive, normal), arrays + hard points + wreck chunks written for pack.py
#   5. optional: clay look sheet (Workbench, cloud) and studio checks (Cycles, PC) with the 9-cell blob sweep
# usage (Blender 4.5 -b -P, or the bpy module):
#   a4_ship.py -- CODE OUT_DIR [--res 4096] [--nobake] [--look] [--checks DIR] [--samples N]
# env A4_ROOT: folder holding hulls_hi/ (default: the repo root, or the current folder if it has hulls_hi)
import sys, os, math, time, json, random
HERE = os.path.dirname(os.path.abspath(__file__))
for p in (HERE, os.path.join(HERE, '..', 'a2detail'), os.path.join(HERE, '..', 'hs')):
    if p not in sys.path: sys.path.insert(0, p)
import numpy as np
import bpy, bmesh
from mathutils import Vector
import hullio, blmesh, hs_lib, detail_lib, dress
import frame, cuts, kit, dress4, bakemat4, ships, wreck

AIM_FNS = {'turret', 'casemate', 'launcher'}


def log(*a): print('[a4]', *a, flush=True)


def build_hull(root, code, cfg):
    if cfg.get('loft'):  # Ithar hulls the AI could not mesh (I8: a curved sheet with a stub of body) are lofted by hand instead
        import ithar
        h = ithar.loft(cfg['loft'], os.environ.get('A4_TMP') or os.path.join(root, '_a4tmp'))
        o = blmesh.mesh_from_arrays('hull', h['pos'], h['idx'], nor=h['nor'], uvs={'atlas': h['uv']})
        h['fingers'] = []; return o, h, {}, len(h['idx']), len(h['idx'])
    h = frame.load(root, code, cfg.get('yaw', 0), roll=cfg.get('roll', 0))
    if cfg.get('pitch'):  # the AI tilted the spindle (I15: bow up); level it by turning about the port axis (degrees, + = bow down)
        a = math.radians(cfg['pitch']); c_, s_ = math.cos(a), math.sin(a)
        for k in ('pos', 'nor'):
            q = h[k].copy(); h[k][:, 0] = c_ * q[:, 0] + s_ * q[:, 2]; h[k][:, 2] = -s_ * q[:, 0] + c_ * q[:, 2]
    idx, rims, rep = cuts.apply(h['pos'], h['idx'], cfg.get('cuts', []), keep_islands=cfg.get('keep_islands', False))
    for r in rep: log(r)
    h['fingers'] = []
    if cfg.get('spires'):  # the A2 blob-sweep rebuild of melted thin spires (a2detail/spires.py): cut here, rebuilt crisp in main()
        import spires
        sp = cfg['spires']; h['fingers'] = spires.scan(h['pos'], idx, sp['zmin'], sp.get('box'), sp.get('exclude_x'))
        idx = spires.cut(h['pos'], idx, h['fingers']); log('spires cut', len(h['fingers']))
    p, n, i, u = hullio.pn_refine(h['pos'], h['nor'], idx, [h['uv2']])
    uv = u[0].copy(); uv[:, 1] = 1 - uv[:, 1]
    o = blmesh.mesh_from_arrays('hull', p, i, nor=n, uvs={'atlas': uv})
    return o, h, rims, len(h['idx']), len(i)


def fill_holes(o, cfg, fac):
    """close the holes the cuts left: each boundary loop inside a cut box is filled, subdivided and relaxed into a soft patch, then split
    off as its own part in the hull colour (its paint and occlusion come from the bake like any hand-built part). Rebuilt parts sit on it."""
    boxes = []
    for c in cfg.get('cuts', []):
        if 'box' not in c or c.get('cover', True) is False: continue
        x0, x1, y0, y1, z0, z1 = c['box']; boxes.append((x0, x1, y0, y1, z0, z1))
        if c.get('mirror'): boxes.append((x0, x1, -y1, -y0, z0, z1))
    needles = [c['needle'] for c in cfg.get('cuts', []) if 'needle' in c and c.get('cover', True) is not False]
    if not boxes and not needles: return []
    e_ = .015
    inside = lambda v: any(b[0] - e_ < v.x < b[1] + e_ and b[2] - e_ < v.y < b[3] + e_ and b[4] - e_ < v.z < b[5] + e_ for b in boxes) or \
        any(cuts.in_needle(nd, (v.x, v.y, v.z), e_) for nd in needles)
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-6)  # the atlas splits vertices along UV seams; weld them (UVs live on corners)
    bnd = [e for e in bm.edges if e.is_boundary]
    par = {}
    def find(v):
        while par.get(v, v) != v: v = par[v]
        return v
    for e in bnd:
        a, b = find(e.verts[0].index), find(e.verts[1].index)
        if a != b: par[a] = b
    groups = {}
    for e in bnd: groups.setdefault(find(e.verts[0].index), []).append(e)
    pl = bm.faces.layers.int.new('patch'); nf = 0
    for g in groups.values():
        vs = {v for e in g for v in e.verts}; cen = sum((v.co for v in vs), Vector()) / len(vs)
        if len(g) < 3 or not inside(cen): continue
        # fan from the loop's centre: works for any boundary (holes_fill skips loops that touch themselves); each new triangle runs its
        # rim edge the opposite way to the hull face beside it, so the patch faces outward with the hull
        cv = bm.verts.new(cen); new = []
        for e in g:
            if not e.link_faces: continue
            f0 = e.link_faces[0]; lp = next((l for l in f0.loops if l.edge == e), None)
            if lp is None: continue
            a_, b_ = lp.vert, lp.link_loop_next.vert
            try: new.append(bm.faces.new((b_, a_, cv)))
            except ValueError: pass
        if not new: continue
        nf += 1; tagv = 1 + nf  # this hole's faces only (earlier patches must not be subdivided again)
        for f in new: f[pl] = tagv
        L_rim = sum(e.calc_length() for e in g)
        for _ in range(2 if L_rim > .03 else 0):
            inner = list({e for f in bm.faces if f[pl] == tagv for e in f.edges if len(e.link_faces) == 2 and all(ff[pl] == tagv for ff in e.link_faces)})
            if not inner: break
            r2 = bmesh.ops.subdivide_edges(bm, edges=inner, cuts=1, use_grid_fill=False)
            for f in r2.get('geom', []):
                if isinstance(f, bmesh.types.BMFace): f[pl] = tagv
            bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if f[pl] == tagv and len(f.verts) > 3])
        mine = [f for f in bm.faces if f[pl] == tagv]
        rimv = {v for f in mine for v in f.verts if any(ff[pl] != tagv for ff in v.link_faces) or any(e.is_boundary for e in v.link_edges)}
        innerv = list({v for f in mine for v in f.verts if v not in rimv})
        for _ in range(12 if innerv else 0): bmesh.ops.smooth_vert(bm, verts=innerv, factor=.8, use_axis_x=True, use_axis_y=True, use_axis_z=True)
    pf = [f for f in bm.faces if f[pl] >= 1]
    if not pf: bm.free(); return []
    # split the patch faces into their own object
    pb = bmesh.new(); vmap = {}
    for f in pf:
        vv = []
        for v in f.verts:
            if v not in vmap: vmap[v] = pb.verts.new(v.co)
            vv.append(vmap[v])
        try: pb.faces.new(vv)
        except ValueError: pass
    bmesh.ops.recalc_face_normals(pb, faces=pb.faces[:])
    out_n = sum((f.normal for f in pf), Vector())
    bmesh.ops.delete(bm, geom=pf, context='FACES_ONLY')
    bm.to_mesh(o.data); bm.free(); o.data.update()
    po = hs_lib._obj('cov_patch', pb, 0)
    for f in po.data.polygons: f.use_smooth = True
    F = bakemat4.FAC[fac]; dress.PROPS[po.name] = dict(col=tuple(bakemat4.lin(F['hull'])), emit=0., rgh=F['rgh'], met=F['met']); dress._mark[0] = len(hs_lib.PARTS)
    log('filled', nf, 'cut holes')
    return [po]


def run_kit(cfg, rims, covers=()):
    """every part in the ship file, in order, seated on the hull and the hole patches"""
    for o in covers: kit.add_target(o)
    if covers: kit.rebuild_bvh()
    made = 0; missed = []
    for spec in cfg.get('kit', []):
        fn_name, name, x, y, z, side = spec[:6]; kw = dict(spec[6]) if len(spec) > 6 else {}
        if fn_name == 'sail':  # placed by explicit geometry (root, plane, angles), mirrored across y when pair=True
            pair = kw.pop('pair', False); kit.sail(name, **kw); made += 1
            if pair:
                m = lambda t: (t[0], -t[1], t[2])
                kw2 = dict(kw, root=m(kw['root']), u=m(kw['u']), v=m(kw['v']))
                if 'hub' in kw and kw['hub']: kw2['hub'] = (Vector(m(kw['hub'][0])), Vector(m(kw['hub'][1])))
                kit.sail(name + 'm', **kw2); made += 1
            continue
        pair = kw.pop('pair', False); aim = kw.pop('aim', None)
        fn = getattr(kit, fn_name)
        if fn_name in AIM_FNS and aim is None: aim = (1, 0, 0)
        if fn_name not in AIM_FNS and aim is not None: kw['aim'] = aim; aim = None
        res = kit.place(fn, name, x, y, z, side, pair=pair, aim=aim, **kw)
        for k, r in enumerate(res):
            if r is None: missed.append(name + ('m' if k else ''))
            else: made += 1
        if fn_name in ('cover', 'bridge', 'sensor_dome'): kit.rebuild_bvh()
    return made, missed


def hull_attrs(o, fac):
    F = bakemat4.FAC[fac]; me = o.data; nv = len(me.vertices); c = bakemat4.lin(F['hull'])
    ca = me.color_attributes.new('Col', 'FLOAT_COLOR', 'POINT'); ca.data.foreach_set('color', np.tile([*c, 1.0], nv).astype(np.float32))
    for k, v in (('emit', 0.), ('rgh', F['rgh']), ('met', F['met']), ('hull', 1.)):
        a = me.attributes.new(k, 'FLOAT', 'POINT'); a.data.foreach_set('value', np.full(nv, v, np.float32))


def audit_guns(cfg):
    probs = []
    for nm, d, arc in kit.GUNS:
        if d.x < -.05: probs.append(f'gun {nm} points backward ({d.x:+.2f})')
        if arc == 'P' and d.y < .25: probs.append(f'gun {nm} is a port battery not aimed to port')
        if arc == 'S' and d.y > -.25: probs.append(f'gun {nm} is a starboard battery not aimed to starboard')
    for h in kit.HP:
        if h['kind'] != 'gun': continue
        if h['arc'] == 'P' and h['p'].y < 0: probs.append(f'{h["name"]}: port mount on the starboard side')
        if h['arc'] == 'S' and h['p'].y > 0: probs.append(f'{h["name"]}: starboard mount on the port side')
    for slot, (wk, arc) in enumerate(ships.weapons(cfg)):
        if not any(h['kind'] == 'gun' and h['slot'] == slot for h in kit.HP): probs.append(f'weapon slot {slot} ({wk} {arc}) has no mount')
    return probs


def hp_records(cfg):
    """hard points in the glTF frame with their final names (K1 decision 7)"""
    out = []; cnt = {}
    for h in kit.HP:
        if h['kind'] == 'gun': key = f'hp_w{h["slot"]}_{h["wkind"]}_{h["arc"]}'
        elif h['kind'] == 'engine': key = 'hp_eng'
        elif h['kind'] == 'bay': key = 'hp_bay'
        else: key = 'hp_breach'
        k = cnt.get(key, 0); cnt[key] = k + 1
        p = frame.bl_to_gl(np.array([h['p'][:]]))[0]; f = frame.bl_to_gl(np.array([h['fwd'][:]]))[0]; u = frame.bl_to_gl(np.array([h['up'][:]]))[0]
        ex = dict(kind=h['kind'], size=h.get('size'), arc=h.get('arc'), slot=h.get('slot'), weapon=h.get('wkind'), radius=round(float(h.get('radius') or 0), 5))
        if h['kind'] == 'gun': ex['arc_deg'] = ships.ARC_DEG[h['arc']]
        out.append(dict(name=f'{key}_{k}', p=p.tolist(), fwd=f.tolist(), up=u.tolist(), extras=ex))
    return out


def core_point(o):
    """centre of mass of the closed-ish hull (signed-volume weighted), in the glTF frame"""
    me = o.data; me.calc_loop_triangles(); F = len(me.loop_triangles)
    tv = np.zeros(F * 3, np.int32); me.loop_triangles.foreach_get('vertices', tv); tv = tv.reshape(-1, 3)
    co = np.zeros(len(me.vertices) * 3, np.float32); me.vertices.foreach_get('co', co); co = co.reshape(-1, 3)
    a, b, c = co[tv[:, 0]], co[tv[:, 1]], co[tv[:, 2]]; v = np.einsum('ij,ij->i', a, np.cross(b, c)) / 6
    cen = ((a + b + c) / 4 * v[:, None]).sum(0) / v.sum() if abs(v.sum()) > 1e-9 else co.mean(0)
    return frame.bl_to_gl(np.array([cen]))[0].tolist()


def export_arrays(o, code, outdir, tag='ship'):
    md = o.modifiers.new('tri', 'TRIANGULATE')
    try: md.keep_custom_normals = True
    except Exception: pass
    a = blmesh.mesh_arrays(o, ('UV0',)); o.modifiers.remove(md)
    pos = frame.bl_to_gl(a['pos']); nor = frame.bl_to_gl(a['nor']); nor /= np.maximum(np.linalg.norm(nor, axis=1, keepdims=True), 1e-9)
    tg = a['tan'].copy(); tg[:, :3] = frame.bl_to_gl(tg[:, :3]); tg[:, :3] /= np.maximum(np.linalg.norm(tg[:, :3], axis=1, keepdims=True), 1e-9)
    tg[:, 3] = np.where(tg[:, 3] < 0, -1.0, 1.0)
    uv = a['uv']['UV0'].copy(); uv[:, 1] = 1 - uv[:, 1]; uv = np.clip(uv, 0, 1)
    path = os.path.join(outdir, f'{code}_{tag}.npz')
    ex = {}
    if 'sail' in a['attrs']: ex['sail'] = (a['attrs']['sail'][a['idx']].max(1) > .5).astype(np.uint8)  # per triangle: sail membrane
    np.savez(path, pos=pos.astype(np.float32), nor=nor.astype(np.float32), idx=a['idx'].astype(np.uint32), uv=uv.astype(np.float32), tan=tg.astype(np.float32), **ex)
    return path, len(a['idx'])


def hp_markers(hps):
    """small cones at each hard point (look sheets only, never exported): weapon mounts red, engines orange, bays green, breaches blue"""
    out = []
    for h in hps:
        p = Vector(frame.gl_to_bl(np.array([h['p']]))[0].tolist()); f = Vector(frame.gl_to_bl(np.array([h['fwd']]))[0].tolist())
        L = .03 if h['extras']['kind'] != 'breach' else .012
        bm = bmesh.new(); bmesh.ops.create_cone(bm, cap_ends=True, segments=8, radius1=L * .22, radius2=0, depth=L)
        R = f.to_track_quat('Z', 'Y').to_matrix().to_4x4(); bmesh.ops.transform(bm, matrix=R, verts=bm.verts); bmesh.ops.translate(bm, verts=bm.verts, vec=p + f * L / 2)
        me = bpy.data.meshes.new('hpm'); bm.to_mesh(me); bm.free(); ob = bpy.data.objects.new('hpm_' + h['name'], me); bpy.context.scene.collection.objects.link(ob)
        col = dict(gun=(1, .05, .05, 1), engine=(1, .55, .05, 1), bay=(.1, 1, .2, 1), breach=(.2, .4, 1, 1), core=(1, 1, 1, 1))[h['extras']['kind']]
        ca = me.color_attributes.new('Col', 'FLOAT_COLOR', 'POINT')
        for d in ca.data: d.color = col
        out.append(ob)
    return out


def main():
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    code, outdir = a[0], a[1]
    res = int(a[a.index('--res') + 1]) if '--res' in a else 4096
    samples = int(a[a.index('--samples') + 1]) if '--samples' in a else 16
    checks = a[a.index('--checks') + 1] if '--checks' in a else None
    bake = '--nobake' not in a; look = '--look' in a
    root = os.environ.get('A4_ROOT') or (os.getcwd() if os.path.isdir(os.path.join(os.getcwd(), 'hulls_hi')) else os.path.abspath(os.path.join(HERE, '..', '..', '..')))
    cfg = ships.SHIPS[code]; probs0 = ships.check_entry(code, cfg)
    if probs0:
        for p_ in probs0: log('ship file:', p_)
        raise SystemExit('ship file problems: fix tools/blender/a4/ships.py')
    fac, cls = cfg['fac'], cfg['cls']; os.makedirs(outdir, exist_ok=True); t0 = time.time()
    blmesh.reset(); hs_lib.PARTS.clear(); dress.PROPS.clear(); dress._mark[0] = 0
    hull, h, rims, tri0, tri1 = build_hull(root, code, cfg); log(code, fac, cls, 'hull tris', tri0, '->', tri1, 'chirality flip' if h['flipped'] else '')
    seed = sum(map(ord, code)); kit.setup([hull], cls, fac, seed)
    if h['fingers']:
        F_ = bakemat4.FAC[fac]; dress.build_spires(h['fingers'], cfg['spires'].get('style', 'gothic'), bakemat4.lin(F_['hull']), bakemat4.lin(F_['dark']), dict(rgh=F_['rgh'], met=F_['met']))
    covers = fill_holes(hull, cfg, fac); made, missed = run_kit(cfg, rims, covers); kit_parts = list(hs_lib.PARTS); log('kit parts', len(kit_parts), 'placements', made, 'missed', missed)
    mmap = blmesh.load_image_np(h['tex'][1])
    H = dress.Hull(hull, mmap, (0, 1, 0), (0, 0, 0)); H.asym = cfg.get('sym', 'bilateral') != 'bilateral'; H.snap = cfg.get('snap', .006)
    for o in kit_parts:  # dressing keeps clear of the hand-built parts (not of the hole patches: they are hull)
        if o.name.startswith('cov_'): continue
        w = [o.matrix_world @ Vector(c) for c in o.bound_box]; lo = Vector(map(min, *w)); hi = Vector(map(max, *w)); H.placed.append(((lo + hi) / 2, (hi - lo).length / 2))
    for k_, sc_ in enumerate(cfg.get('scatter', [])):  # organic growths spread over the body (Chorus tendrils, bone horns)
        rng_ = np.random.default_rng(seed + 31 * k_); fn_ = getattr(kit, sc_['fn']); made_ = 0; tries_ = 0
        wh = sc_.get('where', 'any'); box_ = sc_.get('box')
        ok_ = {'any': lambda nn: True, 'side': lambda nn: abs(nn[1]) > .6, 'below': lambda nn: nn[2] < -.55, 'top': lambda nn: nn[2] > .55,
               'aft': lambda nn: nn[0] < -.5, 'fore': lambda nn: nn[0] > .5}[wh]
        while made_ < sc_['count'] and tries_ < sc_['count'] * 60:
            tries_ += 1; i_ = int(rng_.integers(len(H.sp))); nn = H.sn[i_]; pp = H.sp[i_]
            if not ok_(nn) or H.ao[i_] < .4: continue
            if box_ and not all(box_[2 * j] < pp[j] < box_[2 * j + 1] for j in range(3)): continue
            p_, n_ = Vector(pp.tolist()), Vector(nn.tolist()); L_ = float(rng_.uniform(*sc_['length'])); r_ = float(rng_.uniform(*sc_['r']))
            if not H.free(p_, r_ * 3, 1.0): continue
            fn_(f"{sc_['fn']}{k_}_{made_}", p_, n_, L_, r_); H.placed.append((p_, r_ * 3)); made_ += 1
        log('scatter', sc_['fn'], made_)
    S = detail_lib.Surface([hull] + [o for o in kit_parts if o.name.startswith('cov_')], [o for o in kit_parts if not o.name.startswith('cov_')] or None)
    P = dict(base=bakemat4.lin(bakemat4.FAC[fac]['hull']), dark=bakemat4.lin(bakemat4.FAC[fac]['dark']), trim=bakemat4.lin(bakemat4.FAC[fac]['trim']), lens=tuple(bakemat4.FAC[fac]['win']))
    amt = cfg.get('dress', 1.0)
    if amt > 0:
        if fac in ('voidsworn', 'hegemony'): dress.dress_armour(H, S, fac, seed, P)
        elif fac == 'corsair': dress4.dress_corsair(H, S, seed, P, amt)
        elif fac == 'chorus': dress.dress_chorus(H, S, seed, P)
        elif fac == 'ithar': P['trim'] = bakemat4.lin('#c9a44a'); dress.dress_ithar(H, S, seed, P)
        elif fac == 'deathless': P['trim'] = bakemat4.lin('#7d867f'); dress.dress_deathless(H, S, seed, P)
    nb = kit.breach_anchors(H, cfg.get('breach', {'S': 4, 'M': 6, 'L': 8, 'XL': 10}[kit.BAND.get(cls, 'M')]))
    parts = list(hs_lib.PARTS); log('parts', len(parts), 'breach anchors', nb, round(time.time() - t0, 1), 's')
    import a2_ship
    lo0, hi0 = H.lo.copy(), H.hi.copy(); H.lo = lo0 - Vector((.08, .08, .08)); H.hi = hi0 + Vector((.08, .08, .08))  # engines and guns may reach past the AI hull's box
    sail_names = tuple(s_[1] for s_ in cfg.get('kit', []) if s_[0] == 'sail')
    for o in (parts if sail_names else []):  # Ithar sails spread far past the spindle: their own reach widens the box
        if o.name.startswith(sail_names):
            for c_ in o.bound_box:
                w_ = o.matrix_world @ Vector(c_); H.lo = Vector(map(min, H.lo, w_ - Vector((.03, .03, .03)))); H.hi = Vector(map(max, H.hi, w_ + Vector((.03, .03, .03))))
    probs, stray, _ = a2_ship.audit(H, parts); H.lo, H.hi = lo0, hi0
    kitset = set(o.name for o in kit_parts); kit_float = [p_ for p_ in probs if p_.split()[1] in kitset]
    floaters = [p_.split()[1] for p_ in probs if p_.endswith('floats') and p_.split()[1] not in kitset]
    for k in stray:
        o = parts[k]
        if o.name not in kitset: hs_lib.PARTS.remove(o); bpy.data.objects.remove(o)
    for nm in floaters: o = bpy.data.objects[nm]; hs_lib.PARTS.remove(o); bpy.data.objects.remove(o)
    gprobs = audit_guns(cfg); fail = kit_float + gprobs
    log('audit:', 'PASS' if not fail else 'FAIL', f'(dress: removed {len(floaters)} floating, {len(stray)} stray)')
    for p_ in fail: log('  ', p_)
    parts = list(hs_lib.PARTS)
    for o in parts:  # Ithar sail membranes: flagged so pack.py gives them their own see-through material
        if o.name in kit.SAILS:
            bpy.context.view_layer.objects.active = o
            for md in list(o.modifiers): o.select_set(True); bpy.ops.object.modifier_apply(modifier=md.name); o.select_set(False)
            a_ = o.data.attributes.new('sail', 'FLOAT', 'POINT'); a_.data.foreach_set('value', np.ones(len(o.data.vertices), np.float32))
    hull_attrs(hull, fac); kitobj = a2_ship.finish_parts(parts)
    kit_tris = sum(len(p_.vertices) - 2 for p_ in kitobj.data.polygons)
    core = core_point(hull)
    bpy.ops.object.select_all(action='DESELECT'); hull.select_set(True); kitobj.select_set(True); bpy.context.view_layer.objects.active = hull
    bpy.ops.object.join(); ship = bpy.context.view_layer.objects.active; ship.name = code
    hps = hp_records(cfg); hps.append(dict(name='hp_core', p=core, fwd=[1, 0, 0], up=[0, 1, 0], extras=dict(kind='core')))
    rep = dict(code=code, faction=fac, cls=cls, tris_before=tri0, hull_tris=tri1, kit_tris=kit_tris, parts=len(parts), audit=fail, audit_ok=not fail,
               missed=missed, hardpoints=len(hps), res=res if bake else None)
    meta = dict(code=code, faction=fac, cls=cls, band=kit.BAND.get(cls), length_world=kit.CLS_LEN.get(cls), hardpoints=hps,
                palette={k: [round(float(c), 4) for c in v] for k, v in dict(eng=bakemat4.FAC[fac]['eng'], win=bakemat4.FAC[fac]['win']).items()},
                frame='glTF: +X bow, +Y up, -Z port, +Z starboard (K1 decision 2)', name=cfg.get('name', code))
    if look:
        import look as LK
        mk = hp_markers(hps); LK.setup('VERTEX'); LK.render([ship] + mk, os.path.join(outdir, f'{code}_a4look.png'), code, f'A4 build, audit {"PASS" if not fail else "FAIL"}, {len(hps)} hard points')
        LK.closeups([ship], os.path.join(outdir, f'{code}_a4close.png'), code)
        for m in mk: bpy.data.objects.remove(m)
    if not bake:
        json.dump(rep, open(os.path.join(outdir, code + '_report.json'), 'w'), indent=1); json.dump(meta, open(os.path.join(outdir, code + '_meta.json'), 'w'), indent=1)
        log('built (no bake)', round(time.time() - t0), 's'); return
    a2_ship.make_uv0(ship)
    info = dict(lo=tuple(H.lo), hi=tuple(H.hi), up=(0, 0, 1), needle=cfg.get('needle', .06), engine=not any(x['extras']['kind'] == 'engine' for x in hps))
    mat, socks = bakemat4.build(ship, fac, h['tex'][0], h['tex'][1], info)
    tex_dir = os.path.join(outdir, 'tex'); os.makedirs(tex_dir, exist_ok=True)
    maps = a2_ship.bake_all(ship, mat, socks, res, tex_dir, code, samples); meta['maps'] = maps
    npz, tris = export_arrays(ship, code, outdir); meta['mesh'] = npz; rep['tris'] = tris
    wk = cfg.get('wreck', {'S': 4, 'M': 6, 'L': 8, 'XL': 10}[kit.BAND.get(cls, 'M')])
    meta['wreck'] = wreck.make(ship, code, outdir, wk, seed)
    rep['wreck_chunks'] = len(meta['wreck']); rep['seconds'] = round(time.time() - t0)
    json.dump(rep, open(os.path.join(outdir, code + '_report.json'), 'w'), indent=1); json.dump(meta, open(os.path.join(outdir, code + '_meta.json'), 'w'), indent=1)
    log('wrote', npz, 'tris', tris, 'wreck chunks', len(meta['wreck']), round(time.time() - t0), 's')
    if checks:
        import checks as C
        os.makedirs(checks, exist_ok=True); tmp = os.path.join(checks, '_r_' + code); os.makedirs(tmp, exist_ok=True)
        sc = bpy.context.scene; C.studio(sc, samples=int(os.environ.get('CHECK_SAMPLES', '16')))
        o2 = ship.copy(); o2.data = ship.data.copy(); sc.collection.objects.link(o2); ship.hide_render = True
        C.render_views([o2], os.path.join(tmp, 'clay'), mat=C.clay_mat()); C.render_sweep([o2], os.path.join(tmp, 'sclay'))
        pm = C.painted_mat(dict(base=maps['albedo'], orm=maps['orm'], normal=maps['normal'], emissive=maps['emit']))
        C.render_views([o2], os.path.join(tmp, 'paint'), mat=pm); C.render_sweep([o2], os.path.join(tmp, 'spaint'))
        json.dump(dict(code=code, faction=fac, res=res), open(os.path.join(tmp, 'info.json'), 'w'))
        log('check renders in', tmp)


if __name__ == '__main__':
    main()
