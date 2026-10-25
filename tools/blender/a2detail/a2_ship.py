# A2 engine test, max-detail round: one flagship from hulls_hi to a max-detail glTF binary (assets/hi/CODE.glb).
#   1. geometry: adaptive PN refinement of the hulls_hi mesh (curved and long edges split, hard edges kept straight), then hand-style
#      surface detail per faction (dress.py), all on the real hull surface, in mirrored pairs; automatic float / stray / gun audit
#   2. one new UV atlas (UV0: the hulls_hi atlas islands repacked together with the parts' own islands)
#   3. bakes at RES: albedo, normal (PNG), ORM, emissive, from bakemat.py
#   4. glTF binary in the game frame (x bow, y up, z port), one mesh, one material, tangents included
# usage (Blender 4.5 or the bpy module):
#   blender -b --factory-startup -P a2_ship.py -- CODE OUT_DIR RES [--checks DIR] [--samples N]
# env: A2_ROOT = folder holding hulls_hi/ (default: the current folder if it has hulls_hi, else the repo root)
import sys, os, math, time, json, random
HERE = os.path.dirname(os.path.abspath(__file__))
for p in (HERE, os.path.join(HERE, '..', 'hs')):
    if p not in sys.path: sys.path.insert(0, p)
import numpy as np
import bpy, bmesh
from mathutils import Vector
import hullio, blmesh, hs_lib, detail_lib, dress, bakemat

# per ship: faction, symmetry plane (normal, Blender frame; found from the mesh with a reflection search), up axis for window rows,
# whether the stern gets engine glow, Ithar's needle radius (what is hull, what is sail)
SHIPS = {
    # spires: the blob-sweep rebuild of the AI's melted thin sticks (spires.py): search from zmin up, inside box, bow/stern structures beyond
    # |x| > exclude_x left alone
    'V1b_r_23': dict(fac='voidsworn', mirror=(0, 1, 0), spires=dict(zmin=-.03, exclude_x=.40, style='gothic')),
    'H4_11': dict(fac='hegemony', mirror=(0, 1, 0), spires=dict(zmin=.07, box=(-.12, 0, -.03, .03), style='mast')),
    # the next three have no port/starboard symmetry in the AI mesh (reflection search: mean mismatch 0.07 to 0.15 of the length); their
    # best mirror is fore/aft (0.010 to 0.024), so pairs go across that plane, with singles where the mirror point misses
    'B16_23': dict(fac='chorus', mirror=(1, 0, 0), asym=True, engine=False),
    'I8_37': dict(fac='ithar', mirror=(1, 0, 0), asym=True, snap=.015, needle=.06),
    'D22_23': dict(fac='deathless', mirror=(1, 0, 0), asym=True, snap=.015, engine=False),
}


def log(*a):
    print('[a2]', *a, flush=True)


def build_hull(root, code, spc=None):
    h = hullio.load_hull(root, code); idx = h['idx']; fingers = []
    if spc:  # cut the melted fingers before refining (their replacements are built in main)
        import spires
        fingers = spires.scan(hullio.game_to_bl(h['pos']), idx, spc['zmin'], spc.get('box'), spc.get('exclude_x'))
        idx = spires.cut(None, idx, fingers)
    h['fingers'] = fingers
    p, n, i, u = hullio.pn_refine(h['pos'], h['nor'], idx, [h['uv2']])
    uv = u[0].copy(); uv[:, 1] = 1 - uv[:, 1]  # back to Blender's v-up for the atlas
    o = blmesh.mesh_from_arrays('hull', hullio.game_to_bl(p), i, nor=hullio.game_to_bl(n), uvs={'atlas': uv})
    return o, h, len(h['idx']), len(i)


def audit(H, parts):
    """every part must touch the hull or a part that (in a chain) touches the hull; nothing may reach far off the hull. No guns are added
    by this pass, so the backward-gun check has nothing to flag (it still runs on any part named gun*/barrel*)."""
    from mathutils.bvhtree import BVHTree
    dg = bpy.context.evaluated_depsgraph_get(); probs = []; tol = .0012
    bm = bmesh.new(); owner = []
    data = []
    for k, o in enumerate(parts):
        me = o.evaluated_get(dg).to_mesh(); vs = [o.matrix_world @ v.co for v in me.vertices]
        t = bmesh.new(); t.from_mesh(me); t.transform(o.matrix_world); bmesh.ops.triangulate(t, faces=t.faces[:]); tm = bpy.data.meshes.new('t'); t.to_mesh(tm); t.free()
        nf = len(tm.polygons); bm.from_mesh(tm); owner += [k] * nf; bpy.data.meshes.remove(tm); o.evaluated_get(dg).to_mesh_clear(); data.append(vs)
    ALL = BVHTree.FromBMesh(bm); bm.free()
    grounded = np.zeros(len(parts), bool); stray = []
    lo, hi = H.lo - Vector((.03, .03, .03)), H.hi + Vector((.03, .03, .03))
    for k, vs in enumerate(data):
        if not vs: stray.append(k); continue
        if any(not (lo.x <= v.x <= hi.x and lo.y <= v.y <= hi.y and lo.z <= v.z <= hi.z) for v in vs[::max(1, len(vs) // 50)]): stray.append(k); continue
        step = max(1, len(vs) // 120); dmin = 9
        for v in vs[::step]:
            q = H.T.find_nearest(v, .05)
            if q[0] is not None: dmin = min(dmin, q[3])
            if dmin <= tol: break
        grounded[k] = dmin <= tol
    # parts that do not touch the hull must overlap a grounded part (edge beads on plates, slats in vents, lenses in housings)
    pend = [k for k in range(len(parts)) if not grounded[k] and k not in stray]
    for _ in range(4):
        left = []
        for k in pend:
            o = parts[k]; me = o.evaluated_get(dg).to_mesh(); t = bmesh.new(); t.from_mesh(me); t.transform(o.matrix_world); P = BVHTree.FromBMesh(t); t.free(); o.evaluated_get(dg).to_mesh_clear()
            hits = {owner[j] for i_, j in ALL.overlap(P)} - {k}
            if not hits:  # no crossing: touching within tolerance also counts
                for v in data[k][::max(1, len(data[k]) // 60)]:
                    q = ALL.find_nearest(v, tol)
                    if q[0] is not None and owner[q[2]] != k: hits.add(owner[q[2]])
            if any(grounded[j] for j in hits): grounded[k] = True
            else: left.append(k)
        if len(left) == len(pend): break
        pend = left
    for k in pend: probs.append(f'part {parts[k].name} floats')
    for k in stray: probs.append(f'part {parts[k].name} reaches off the hull (removed)')
    guns = [o.name for o in parts if o.name.startswith(('gun', 'barrel'))]
    return probs, stray, guns


def finish_parts(parts):
    """apply modifiers, write the per-part attributes, join into one object"""
    for o in parts:
        bpy.context.view_layer.objects.active = o
        for md in list(o.modifiers):
            o.select_set(True); bpy.ops.object.modifier_apply(modifier=md.name); o.select_set(False)
        pr = dress.PROPS.get(o.name, dict(col=(.2, .2, .2), emit=0., rgh=.5, met=.3)); me = o.data; nv = len(me.vertices)
        ca = me.color_attributes.new('Col', 'FLOAT_COLOR', 'POINT'); ca.data.foreach_set('color', np.tile([*pr['col'], 1.0], nv).astype(np.float32))
        for k in ('emit', 'rgh', 'met'):
            a = me.attributes.new(k, 'FLOAT', 'POINT'); a.data.foreach_set('value', np.full(nv, pr[k], np.float32))
        a = me.attributes.new('hull', 'FLOAT', 'POINT'); a.data.foreach_set('value', np.zeros(nv, np.float32))
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts: o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]; bpy.ops.object.join(); kit = bpy.context.view_layer.objects.active; kit.name = 'kit'
    bpy.ops.object.select_all(action='DESELECT'); kit.select_set(True)
    try: bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35), keep_sharp_edges=True)
    except Exception:
        for p in kit.data.polygons: p.use_smooth = True
    return kit


def hull_attrs(o, fac):
    F = bakemat.FAC[fac]; me = o.data; nv = len(me.vertices); c = bakemat.lin(F['hull'])
    ca = me.color_attributes.new('Col', 'FLOAT_COLOR', 'POINT'); ca.data.foreach_set('color', np.tile([*c, 1.0], nv).astype(np.float32))
    for k, v in (('emit', 0.), ('rgh', F['rgh']), ('met', F['met']), ('hull', 1.)):
        a = me.attributes.new(k, 'FLOAT', 'POINT'); a.data.foreach_set('value', np.full(nv, v, np.float32))


def make_uv0(o):
    """UV0: start from the hulls_hi atlas (good islands), unwrap only the parts, then pack every island together"""
    me = o.data; me.uv_layers.active = me.uv_layers['atlas']; uv0 = me.uv_layers.new(name='UV0', do_init=True); me.uv_layers.active = uv0
    try: uv0.active_render = True
    except Exception: pass
    hv = np.zeros(len(me.vertices), np.float32); me.attributes['hull'].data.foreach_get('value', hv)
    ps = np.zeros(len(me.polygons), np.int32); lt = np.zeros(len(me.polygons), np.int32); me.polygons.foreach_get('loop_start', ps)
    lv = np.zeros(len(me.loops), np.int32); me.loops.foreach_get('vertex_index', lv)
    sel = hv[lv[ps]] < .5; me.polygons.foreach_set('select', sel)
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_mode(type='FACE')
    t = time.time(); bpy.ops.uv.smart_project(angle_limit=math.radians(55), island_margin=0.0)
    log('parts unwrapped', int(sel.sum()), 'faces', round(time.time() - t, 1), 's')
    bpy.ops.mesh.select_all(action='SELECT'); t = time.time()
    try: bpy.ops.uv.pack_islands(rotate=True, margin_method='FRACTION', margin=0.0012, shape_method=os.environ.get('A2_PACK', 'CONCAVE'))
    except TypeError: bpy.ops.uv.pack_islands(rotate=True, margin=0.0012)
    bpy.ops.object.mode_set(mode='OBJECT'); log('packed', round(time.time() - t, 1), 's')


def bake_all(o, mat, socks, res, outdir, code, samples):
    sc = bpy.context.scene; blmesh.gpu_on(sc); sc.cycles.samples = samples
    try: sc.cycles.use_denoising = False
    except Exception: pass
    sc.render.bake.margin = max(4, res // 512); sc.render.bake.use_selected_to_active = False
    try: sc.render.bake.margin_type = 'EXTEND'
    except Exception: pass
    o.data.materials.clear(); o.data.materials.append(mat)
    g = socks['g']; T = mat.node_tree; tt = T.nodes.new('ShaderNodeTexImage'); T.nodes.active = tt; tt.select = True
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
    outs = {}
    for key, data in (('albedo', False), ('orm', True), ('emit', False)):
        im = blmesh.new_image(f'{code}_{key}', res, data=data); tt.image = im
        s = socks[key]
        if isinstance(s, tuple):
            for l in list(socks['em'].inputs[0].links): T.links.remove(l)
            socks['em'].inputs[0].default_value = (*s, 1)
        else: g.link(s, socks['em'].inputs[0])
        g.link(socks['em'].outputs[0], socks['out'].inputs[0])
        t = time.time(); bpy.ops.object.bake(type='EMIT')
        p = os.path.join(outdir, f'{code}_{key}.png'); im.filepath_raw = p; im.file_format = 'PNG'; im.save(); outs[key] = p
        log('baked', key, res, round(time.time() - t, 1), 's')
    im = blmesh.new_image(f'{code}_normal', res, data=True); tt.image = im
    g.link(socks['normal'], socks['out'].inputs[0]); sc.render.bake.normal_space = 'TANGENT'
    t = time.time(); bpy.ops.object.bake(type='NORMAL')
    p = os.path.join(outdir, f'{code}_normal.png'); im.filepath_raw = p; im.file_format = 'PNG'; im.save(); outs['normal'] = p
    log('baked normal', res, round(time.time() - t, 1), 's')
    return outs


def export(o, code, fac, maps, out_glb, res_note):
    """mesh arrays (game frame) to OUT/CODE_mesh.npz plus a meta json; the glTF binary is packed right away when PIL is present (cloud),
    otherwise by pack_glb.py in a Python that has it (the PC job uses ComfyUI's)"""
    md = o.modifiers.new('tri', 'TRIANGULATE')  # parts carry n-gons; tangents need triangles
    try: md.keep_custom_normals = True
    except Exception: pass
    a = blmesh.mesh_arrays(o, ('UV0',))
    pos = hullio.bl_to_game(a['pos']); nor = hullio.bl_to_game(a['nor']); nor /= np.maximum(np.linalg.norm(nor, axis=1, keepdims=True), 1e-9)
    tg = a['tan'].copy(); tg[:, :3] = hullio.bl_to_game(tg[:, :3]); tg[:, :3] /= np.maximum(np.linalg.norm(tg[:, :3], axis=1, keepdims=True), 1e-9)
    tg[:, 3] = np.where(tg[:, 3] < 0, -1.0, 1.0)
    uv = a['uv']['UV0'].copy(); uv[:, 1] = 1 - uv[:, 1]; uv = np.clip(uv, 0, 1)
    base = out_glb[:-4]
    np.savez(base + '_mesh.npz', pos=pos.astype(np.float32), nor=nor.astype(np.float32), idx=a['idx'].astype(np.uint32), uv=uv.astype(np.float32), tan=tg.astype(np.float32))
    meta = dict(name=code, faction=fac, glb=out_glb, maps=maps, res=res_note, extras=dict(faction=fac, source='hulls_hi/' + code, textures=res_note))
    json.dump(meta, open(base + '_meta.json', 'w'), indent=1)
    o.modifiers.remove(md)
    try:
        import PIL  # noqa
    except ImportError:
        log('PIL not here: run pack_glb.py on', base + '_meta.json'); return len(a['idx']), None
    import pack_glb; return len(a['idx']), pack_glb.pack(base + '_meta.json')


def main():
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    code, outdir, res = a[0], a[1], int(a[2])
    checks = a[a.index('--checks') + 1] if '--checks' in a else None
    samples = int(a[a.index('--samples') + 1]) if '--samples' in a else 16
    root = os.environ.get('A2_ROOT') or (os.getcwd() if os.path.isdir(os.path.join(os.getcwd(), 'hulls_hi')) else os.path.abspath(os.path.join(HERE, '..', '..', '..')))
    cfg = SHIPS[code]; fac = cfg['fac']; os.makedirs(outdir, exist_ok=True); t0 = time.time()
    blmesh.reset(); hs_lib.PARTS.clear(); dress.PROPS.clear(); dress._mark[0] = 0
    hull, h, tri0, tri1 = build_hull(root, code, cfg.get('spires')); log(code, fac, 'hull tris', tri0, '->', tri1, 'fingers cut', len(h['fingers']))
    mmap = blmesh.load_image_np(h['tex'][1])
    H = dress.Hull(hull, mmap, cfg['mirror'], (0, 0, 0)); H.asym = cfg.get('asym', False); H.snap = cfg.get('snap', .006)
    S = detail_lib.Surface([hull], None)
    F = bakemat.FAC[fac]
    P = dict(base=bakemat.lin(F['hull']), dark=bakemat.lin(F['dark']), trim=bakemat.lin(F['trim']), lens=tuple(F['win']))
    seed = sum(map(ord, code))
    if h['fingers']: dress.build_spires(h['fingers'], cfg['spires']['style'], P['base'], P['dark'], dict(rgh=F['rgh'], met=F['met']))
    for f in h['fingers']: H.placed.append((Vector((float(f['c'][0]), float(f['c'][1]), f['z0'])), float(max(f['plate_hi'] - f['plate_lo'])) / 2 + .003))
    if fac in ('voidsworn', 'hegemony'): dress.dress_armour(H, S, fac, seed, P)
    elif fac == 'chorus': dress.dress_chorus(H, S, seed, P)
    elif fac == 'ithar': P['trim'] = bakemat.lin('#c9a44a'); dress.dress_ithar(H, S, seed, P)  # filigree gold a step richer than the trim tint
    elif fac == 'deathless': P['trim'] = bakemat.lin('#7d867f'); dress.dress_deathless(H, S, seed, P)  # ribs: pale slate-bone from the hull family
    parts = list(hs_lib.PARTS); log('parts', len(parts), round(time.time() - t0, 1), 's')
    probs, stray, guns = audit(H, parts)
    for k in stray: o = parts[k]; hs_lib.PARTS.remove(o); bpy.data.objects.remove(o)
    parts = list(hs_lib.PARTS)
    log('audit:', 'PASS' if not [p for p in probs if 'floats' in p] else 'FAIL', f'{len(probs)} notes, guns added: {len(guns)}')
    for p in probs[:40]: log('  ', p)
    hull_attrs(hull, fac); kit = finish_parts(parts)
    kit_tris = sum(len(p.vertices) - 2 for p in kit.data.polygons)
    bpy.ops.object.select_all(action='DESELECT'); hull.select_set(True); kit.select_set(True); bpy.context.view_layer.objects.active = hull
    bpy.ops.object.join(); ship = bpy.context.view_layer.objects.active; ship.name = code
    make_uv0(ship)
    info = dict(lo=tuple(H.lo), hi=tuple(H.hi), up=(0, 0, 1), needle=cfg.get('needle', .06), engine=cfg.get('engine', True))
    mat, socks = bakemat.build(ship, fac, h['tex'][0], h['tex'][1], info)
    tex_dir = os.path.join(outdir, 'tex'); os.makedirs(tex_dir, exist_ok=True)
    maps = bake_all(ship, mat, socks, res, tex_dir, code, samples)
    out_glb = os.path.join(outdir, code + '.glb'); tris, chk = export(ship, code, fac, maps, out_glb, f'{res}px')
    chk = chk or dict(tris=tris, mb=None, problems=['glb not packed yet (pack_glb.py)'])
    rep = dict(code=code, faction=fac, tris_before=tri0, hull_tris=tri1, kit_tris=kit_tris, tris_after=chk['tris'], ratio=round(chk['tris'] / tri0, 2), parts=len(parts),
               audit=probs, guns_added=guns, glb_mb=chk['mb'], glb_check=chk, res=res, seconds=round(time.time() - t0))
    json.dump(rep, open(os.path.join(outdir, code + '_report.json'), 'w'), indent=1)
    log('wrote', out_glb, chk['mb'], 'MB', 'tris', chk['tris'], 'problems', chk['problems'], round(time.time() - t0), 's')
    if checks:
        import checks as C
        os.makedirs(checks, exist_ok=True); tmp = os.path.join(checks, '_r_' + code); os.makedirs(tmp, exist_ok=True)
        sc = bpy.context.scene; C.studio(sc, samples=int(os.environ.get('CHECK_SAMPLES', '16')))
        o2 = ship.copy(); o2.data = ship.data.copy(); sc.collection.objects.link(o2); ship.hide_render = True
        C.render_views([o2], os.path.join(tmp, 'clay'), mat=C.clay_mat()); C.render_sweep([o2], os.path.join(tmp, 'sclay'))
        pm = C.painted_mat(dict(base=maps['albedo'], orm=maps['orm'], normal=maps['normal'], emissive=maps['emit']))
        C.render_views([o2], os.path.join(tmp, 'paint'), mat=pm); C.render_sweep([o2], os.path.join(tmp, 'spaint'))
        json.dump(dict(code=code, faction=fac, res=res), open(os.path.join(tmp, 'info.json'), 'w'))
        try:
            import checks_sheet; checks_sheet.make(checks, code); log('check sheets in', checks)
        except ImportError: log('renders in', tmp, '(sheets: pack_glb.py --sheets)')


if __name__ == '__main__':
    main()
