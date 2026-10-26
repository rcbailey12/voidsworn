# A4: the Pyre-Barge (C19_51) into the same Godot format as every other A4 ship. The barge keeps its approved shape and paint (R12 to R14):
# the A2 8K re-bake of the v15 painted files (comfy_io\a2detail\C19_51_shell.glb and C19_51_kit.glb, project_paint PAINT=proc) is
# imported, turned bow first, and its two texture sets are re-baked onto one atlas, so the barge gets one material, hard points and wreck
# pieces like the rest. Hard points come from barge_v15.py's own part positions.
# usage (Blender 4.5): blender -b --factory-startup -P barge4.py -- SHELL.glb KIT.glb OUT_DIR [--res 4096] [--checks DIR]
import sys, os, math, json, time
HERE = os.path.dirname(os.path.abspath(__file__))
for p in (HERE, os.path.join(HERE, '..', 'a2detail'), os.path.join(HERE, '..', 'hs')):
    if p not in sys.path: sys.path.insert(0, p)
import numpy as np
import bpy, bmesh
from mathutils import Vector, Matrix
import blmesh, frame, wreck

CODE = 'C19_51'; ZC = -.070


def log(*a): print('[barge4]', *a, flush=True)


def to_ship(p):
    """barge_v15 frame (x aft, y as authored, z up) -> A4 working frame (x bow): a half turn about z (a rotation: chirality as authored)"""
    return Vector((-p[0], -p[1], p[2]))


def hardpoints():
    """from barge_v15.py: bow guns (heavy torpedo tubes, F), side guns (scatter, two per side), the rocket rack top (flak, T), four engines"""
    hp = []
    def gun(slot, wk, arc, base, d, L, k):
        d = Vector(d).normalized(); m = Vector(base) + d * L
        hp.append(dict(kind='gun', slot=slot, wkind=wk, arc=arc, p=to_ship(m), fwd=to_ship(d), up=Vector((0, 0, 1)), size='L' if slot == 2 else 'M', radius=.012, k=k))
    for y in (.050, -.050): gun(2, 'htorp', 'F', (-.380, y, ZC), (-1, 0, 0), .055, 0)
    for x, y, z in ((-.140, .120, ZC + .045), (.235, .120, ZC + .048)):
        for s in (1, -1):  # side_guns: d = (-1, s * .45, .25), barrels .075 long
            gun(None, 'scatter', None, (x, s * y, z), (-1, s * .45, .25), .075, s)
    hp.append(dict(kind='gun', slot=3, wkind='flak', arc='T', p=to_ship((.217, 0, .118)), fwd=Vector((1, 0, 0)), up=Vector((0, 0, 1)), size='S', radius=.012))
    for c, r in (((.299, .215, ZC), .036), ((.355, -.226, ZC - .016), .050), ((.512, 0, ZC + .022), .026), ((.512, 0, ZC - .030), .029)):
        hp.append(dict(kind='engine', p=to_ship(c), fwd=Vector((-1, 0, 0)), up=Vector((0, 0, 1)), radius=r, size='-', arc='-', slot=None, wkind='engine'))
    for h in hp:  # side guns: P or S by the side they actually sit on (A4 frame: +y is port)
        if h['kind'] == 'gun' and h['slot'] is None:
            h['arc'] = 'P' if h['p'].y > 0 else 'S'; h['slot'] = 0 if h['arc'] == 'P' else 1
    return hp


def bake_mat(m):
    """emission bake sources from an imported glTF material: images by their names (_base, _orm, _normal, _emissive), old UVs 'atlas'"""
    imgs = {}
    for n in m.node_tree.nodes:
        if n.type == 'TEX_IMAGE' and n.image:
            for k in ('base', 'orm', 'normal', 'emissive'):
                if n.image.name.lower().split('.')[0].endswith('_' + k): imgs[k] = n.image
    T = m.node_tree; T.nodes.clear(); L = T.links
    out = T.nodes.new('ShaderNodeOutputMaterial'); em = T.nodes.new('ShaderNodeEmission'); L.new(em.outputs[0], out.inputs[0])
    uv = T.nodes.new('ShaderNodeUVMap'); uv.uv_map = 'atlas'; tex = {}
    for k, im in imgs.items():
        if k != 'base' and k != 'emissive':
            try: im.colorspace_settings.name = 'Non-Color'
            except Exception: pass
        t = T.nodes.new('ShaderNodeTexImage'); t.image = im; L.new(uv.outputs[0], t.inputs[0]); tex[k] = t
    nm = T.nodes.new('ShaderNodeNormalMap'); nm.uv_map = 'atlas'
    if 'normal' in tex: L.new(tex['normal'].outputs[0], nm.inputs['Color'])
    pb = T.nodes.new('ShaderNodeBsdfPrincipled'); L.new(nm.outputs[0], pb.inputs['Normal'])
    target = T.nodes.new('ShaderNodeTexImage'); target.name = 'bake_target'; T.nodes.active = target
    return dict(T=T, em=em, out=out, tex=tex, pb=pb, target=target)


def main():
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    shell, kitf, outdir = a[0], a[1], a[2]; os.makedirs(outdir, exist_ok=True)
    res = int(a[a.index('--res') + 1]) if '--res' in a else 4096
    checks = a[a.index('--checks') + 1] if '--checks' in a else None
    t0 = time.time(); blmesh.reset(); objs = []
    for f in (shell, kitf):
        before = set(bpy.context.scene.objects); bpy.ops.import_scene.gltf(filepath=f)
        objs += [o for o in set(bpy.context.scene.objects) - before if o.type == 'MESH']
    for o in objs:
        o.data.transform(o.matrix_world); o.matrix_world = Matrix.Identity(4)
        o.data.transform(Matrix.Rotation(math.pi, 4, 'Z')); o.data.update()
        if o.data.uv_layers: o.data.uv_layers[0].name = 'atlas'
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]; bpy.ops.object.join(); ship = bpy.context.view_layer.objects.active; ship.name = CODE
    me = ship.data; nv = len(me.vertices)
    a_ = me.attributes.new('hull', 'FLOAT', 'POINT'); a_.data.foreach_set('value', np.ones(nv, np.float32))  # keep every island as it is
    co = np.zeros(nv * 3, np.float32); me.vertices.foreach_get('co', co); co = co.reshape(-1, 3); lo, hi = co.min(0), co.max(0)
    log('imported', len(objs), 'meshes,', len(me.polygons), 'faces, extent', (hi - lo).round(3).tolist(), 'materials', len(me.materials))
    import a2_ship
    a2_ship.make_uv0(ship)
    sc = bpy.context.scene; blmesh.gpu_on(sc); sc.cycles.samples = 1
    sc.render.bake.margin = max(4, res // 512); sc.render.bake.use_selected_to_active = False
    try: sc.render.bake.margin_type = 'EXTEND'
    except Exception: pass
    mats = [bake_mat(m) for m in me.materials]
    tex_dir = os.path.join(outdir, 'tex'); os.makedirs(tex_dir, exist_ok=True); maps = {}
    bpy.ops.object.select_all(action='DESELECT'); ship.select_set(True); bpy.context.view_layer.objects.active = ship
    for key, src, data in (('albedo', 'base', False), ('orm', 'orm', True), ('emit', 'emissive', False), ('normal', None, True)):
        im = blmesh.new_image(f'{CODE}_{key}', res, data=data)
        for M in mats:
            M['target'].image = im; M['T'].nodes.active = M['target']
            for l in list(M['out'].inputs[0].links): M['T'].links.remove(l)
            if key == 'normal': M['T'].links.new(M['pb'].outputs[0], M['out'].inputs[0])
            else:
                M['T'].links.new(M['em'].outputs[0], M['out'].inputs[0])
                for l in list(M['em'].inputs[0].links): M['T'].links.remove(l)
                if src in M['tex']: M['T'].links.new(M['tex'][src].outputs[0], M['em'].inputs[0])
                else: M['em'].inputs[0].default_value = (0, 0, 0, 1) if src == 'emissive' else (1, .6, 0, 1) if src == 'orm' else (.3, .3, .3, 1)
        t = time.time()
        if key == 'normal': sc.render.bake.normal_space = 'TANGENT'; bpy.ops.object.bake(type='NORMAL')
        else: bpy.ops.object.bake(type='EMIT')
        p = os.path.join(tex_dir, f'{CODE}_{key}.png'); im.filepath_raw = p; im.file_format = 'PNG'; im.save(); maps[key] = p; log('baked', key, res, round(time.time() - t, 1), 's')
    import kit, ships
    kit.HP.clear(); [kit.HP.append(h) for h in hardpoints()]
    import a4_ship
    hps = a4_ship.hp_records(dict(fac='corsair', cls='Battle-barge'))
    hps.append(dict(name='hp_core', p=frame.bl_to_gl(np.array([[(lo[0] + hi[0]) / 2, 0, ZC]]))[0].tolist(), fwd=[1, 0, 0], up=[0, 1, 0], extras=dict(kind='core')))
    # breach anchors: farthest-point picks over upward and sideways faces
    me.calc_loop_triangles(); F = len(me.loop_triangles); tv = np.zeros(F * 3, np.int32); me.loop_triangles.foreach_get('vertices', tv); tv = tv.reshape(-1, 3)
    A, B, C = co[tv[:, 0]], co[tv[:, 1]], co[tv[:, 2]]; N = np.cross(B - A, C - A); ar = np.linalg.norm(N, axis=1); N = N / np.maximum(ar[:, None], 1e-12)
    cand = np.nonzero((ar > np.percentile(ar, 70)) & (N[:, 2] > -.3))[0]; P = (A + B + C)[cand] / 3; rng = np.random.default_rng(5)
    pick = [int(rng.integers(len(cand)))]; d = np.linalg.norm(P - P[pick[0]], axis=1)
    while len(pick) < 8: i = int(np.argmax(d)); pick.append(i); d = np.minimum(d, np.linalg.norm(P - P[i], axis=1))
    for k, i in enumerate(pick):
        p_ = frame.bl_to_gl(P[i:i + 1])[0]; n_ = frame.bl_to_gl(N[cand[i]:cand[i] + 1])[0]
        hps.append(dict(name=f'hp_breach_{k}', p=p_.tolist(), fwd=[1, 0, 0] if abs(n_[0]) < .9 else [0, 1, 0], up=n_.tolist(), extras=dict(kind='breach', radius=0)))
    for M in mats:  # restore a plain material for the arrays and the wreck
        pass
    npz, tris = a4_ship.export_arrays(ship, CODE, outdir)
    meta = dict(code=CODE, faction='corsair', cls='Battle-barge', band='L', length_world=26, hardpoints=hps, maps=maps, mesh=npz, name="Warlord's Pyre-Barge",
                palette=dict(eng=[1, .38, .16], win=[1, .4, .2]), frame='glTF: +X bow, +Y up, -Z port, +Z starboard (K1 decision 2)')
    meta['wreck'] = wreck.make(ship, CODE, outdir, 8, 19)
    json.dump(meta, open(os.path.join(outdir, CODE + '_meta.json'), 'w'), indent=1)
    json.dump(dict(code=CODE, tris=tris, hardpoints=len(hps), wreck_chunks=len(meta['wreck']), seconds=round(time.time() - t0)), open(os.path.join(outdir, CODE + '_report.json'), 'w'), indent=1)
    log('wrote', npz, 'tris', tris, 'hard points', len(hps), round(time.time() - t0), 's')
    if checks:
        import checks as C
        os.makedirs(checks, exist_ok=True); tmp = os.path.join(checks, '_r_' + CODE); os.makedirs(tmp, exist_ok=True)
        C.studio(sc, samples=24); o2 = ship.copy(); o2.data = ship.data.copy(); sc.collection.objects.link(o2); ship.hide_render = True
        C.render_views([o2], os.path.join(tmp, 'clay'), mat=C.clay_mat()); C.render_sweep([o2], os.path.join(tmp, 'sclay'))
        pm = C.painted_mat(dict(base=maps['albedo'], orm=maps['orm'], normal=maps['normal'], emissive=maps['emit']))
        C.render_views([o2], os.path.join(tmp, 'paint'), mat=pm); C.render_sweep([o2], os.path.join(tmp, 'spaint'))
        json.dump(dict(code=CODE, faction='corsair', res=res), open(os.path.join(tmp, 'info.json'), 'w'))


if __name__ == '__main__':
    main()
