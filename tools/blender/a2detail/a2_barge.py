# A2 engine test, max-detail round: the Pyre-Barge (C19_51) keeps its signed-off v15 look. project_paint.py (PAINT=proc) re-bakes its
# paint at 8K first (albedo, ORM, fine normal; see tools/pc/jobs/a2_detail.bat); this script then adds an emissive map (sparse running
# lights, bridge window glow, lit slits on the bridge tier, engine glow discs) and writes full-PBR glTF binaries:
#   C19_51_shell.glb and C19_51_kit.glb (same frame as the v15 exports: bow at -x, z up in Blender, so y up in glTF; the engine test turns
#   the barge 180 degrees about y as SPEC.md says)
# usage: blender -b --factory-startup -P a2_barge.py -- PAINTED_DIR OUT_DIR RES [--checks DIR]
#   PAINTED_DIR holds shell_painted.glb + shell_albproj.png (+ _orm.png, _nrm.png) and kit_painted.glb + kit_albproj.png (+ ...)
import sys, os, math, time, json
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path: sys.path.insert(0, HERE)
import numpy as np
import bpy
from mathutils import Vector
import hullio, blmesh

ZC = -.070  # barge_v15.py
WIN = (1.0, .40, .20); ENG = (1.0, .38, .16); RUN = (1.0, .15, .08)  # FAC3D corsair win, eng, tip
GLOW = [((.299, .215, ZC), .036), ((.355, -.226, ZC - .016), .050), ((.512, 0, ZC + .022), .026), ((.512, 0, ZC - .030), .029)]  # glow discs (barge_v15.py)


def log(*a): print('[a2b]', *a, flush=True)


def import_one(path):
    before = set(bpy.context.scene.objects); bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in set(bpy.context.scene.objects) - before if o.type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for o in new: o.select_set(True)
    bpy.context.view_layer.objects.active = new[0]
    if len(new) > 1: bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active; bpy.ops.object.transform_apply(location=True, rotation=True, scale=True); return o


def light_points(objs):
    """running lights at the barge's hard points, found from the geometry: the antenna tips (top and bottom), the outboard ends of both
    engine pods, the bow corners; Corsair-sparse, not a full navigation set"""
    V = np.concatenate([np.array([o.matrix_world @ v.co for v in o.data.vertices]) for o in objs])
    pts = []
    pts.append(V[np.argmax(V[:, 2])]); pts.append(V[np.argmin(V[:, 2])])                     # dorsal and ventral antenna tips
    for s in (1, -1):                                                                        # outboard ends of the engine pods
        side = V[V[:, 1] * s > .15]
        if len(side): pts.append(side[np.argmin(side[:, 0] + np.abs(side[:, 1]) * -.3)])
    bow = V[V[:, 0] < V[:, 0].min() + .03]                                                   # bow corners, port and starboard
    for s in (1, -1):
        b = bow[bow[:, 1] * s > 0]
        if len(b): pts.append(b[np.argmax(np.abs(b[:, 1]))])
    return [tuple(map(float, p)) for p in pts]


def emission_mat(lights):
    m = bpy.data.materials.new('a2emit'); m.use_nodes = True; T = m.node_tree; T.nodes.clear(); L = T.links
    out = T.nodes.new('ShaderNodeOutputMaterial'); em = T.nodes.new('ShaderNodeEmission'); L.new(em.outputs[0], out.inputs[0])
    tc = T.nodes.new('ShaderNodeTexCoord'); geo = T.nodes.new('ShaderNodeNewGeometry'); obj = tc.outputs['Object']
    sx = T.nodes.new('ShaderNodeSeparateXYZ'); L.new(obj, sx.inputs[0]); X, Y, Z = sx.outputs
    sn = T.nodes.new('ShaderNodeSeparateXYZ'); L.new(geo.outputs['Normal'], sn.inputs[0]); NX, NY, NZ = sn.outputs
    def m_(op, a, b=0.0):
        n = T.nodes.new('ShaderNodeMath'); n.operation = op
        for i, v in enumerate((a, b)):
            if isinstance(v, (int, float)): n.inputs[i].default_value = v
            else: L.new(v, n.inputs[i])
        return n.outputs[0]
    def box(c, s):
        r = None
        for v, cc, ss in ((X, c[0], s[0]), (Y, c[1], s[1]), (Z, c[2], s[2])):
            k = m_('LESS_THAN', m_('ABSOLUTE', m_('SUBTRACT', v, cc)), ss / 2); r = k if r is None else m_('MULTIPLY', r, k)
        return r
    def sphere(c, rad):
        d = T.nodes.new('ShaderNodeVectorMath'); d.operation = 'DISTANCE'; L.new(obj, d.inputs[0]); d.inputs[1].default_value = c
        mr = T.nodes.new('ShaderNodeMapRange'); L.new(d.outputs['Value'], mr.inputs['Value']); mr.inputs['From Min'].default_value = rad * .6; mr.inputs['From Max'].default_value = rad
        mr.inputs['To Min'].default_value = 1; mr.inputs['To Max'].default_value = 0; return mr.outputs[0]
    def mixc(fac, a, col):
        n = T.nodes.new('ShaderNodeMix'); n.data_type = 'RGBA'; L.new(fac, n.inputs['Factor'])
        if isinstance(a, tuple): n.inputs[6].default_value = (*a, 1)
        else: L.new(a, n.inputs[6])
        n.inputs[7].default_value = (*col, 1); return n.outputs[2]
    def white(*vs):
        c = T.nodes.new('ShaderNodeCombineXYZ')
        for i, v in enumerate(vs):
            if isinstance(v, (int, float)): c.inputs[i].default_value = v
            else: L.new(v, c.inputs[i])
        w = T.nodes.new('ShaderNodeTexWhiteNoise'); w.noise_dimensions = '3D'; L.new(c.outputs[0], w.inputs['Vector']); return w.outputs['Value']
    col = (0, 0, 0)
    # engine glow discs
    for c, r in GLOW: col = mixc(box(c, (.006, r * 2.1, r * 2.1)), col, ENG)
    # bridge windows: the dark strip in the tier front, panes lit unevenly (some dark: it is a Corsair bridge)
    pane = m_('GREATER_THAN', m_('FRACT', m_('MULTIPLY', Y, 160)), .18)
    lit = m_('GREATER_THAN', white(m_('FLOOR', m_('MULTIPLY', Y, 160)), 0.0, 2.0), .3)
    col = mixc(m_('MULTIPLY', box((-.076, 0, .074), (.012, .094, .010)), m_('MULTIPLY', pane, lit)), col, WIN)
    # lit slits in short runs on the bridge tier's flanks (side-facing only), uneven like everything Corsair
    U = m_('MULTIPLY', X, 140); Vv = m_('MULTIPLY', Z, 120); cu = m_('FLOOR', U); cv = m_('FLOOR', Vv)
    rect = m_('MULTIPLY', m_('MULTIPLY', m_('GREATER_THAN', m_('FRACT', U), .2), m_('LESS_THAN', m_('FRACT', U), .8)), m_('MULTIPLY', m_('GREATER_THAN', m_('FRACT', Vv), .35), m_('LESS_THAN', m_('FRACT', Vv), .65)))
    on = m_('GREATER_THAN', white(cu, cv, m_('GREATER_THAN', Y, 0.0)), .55)
    side = m_('GREATER_THAN', m_('ABSOLUTE', NY), .75)
    col = mixc(m_('MULTIPLY', m_('MULTIPLY', box((-.015, 0, .066), (.13, .14, .024)), side), m_('MULTIPLY', rect, on)), col, WIN)
    # running lights
    for p in lights: col = mixc(sphere(p, .0045), col, RUN)
    L.new(col, em.inputs[0]); return m


def bake_emit(o, mat, res, path):
    sc = bpy.context.scene; blmesh.gpu_on(sc); sc.cycles.samples = 4; sc.render.bake.margin = max(4, res // 512)
    keep = list(o.data.materials); o.data.materials.clear(); o.data.materials.append(mat)
    T = mat.node_tree; tt = T.nodes.new('ShaderNodeTexImage'); im = blmesh.new_image('emit', res); tt.image = im; T.nodes.active = tt
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
    t = time.time(); bpy.ops.object.bake(type='EMIT'); im.filepath_raw = path; im.file_format = 'PNG'; im.save(); log('baked emit', res, round(time.time() - t, 1), 's')
    o.data.materials.clear()
    for m in keep: o.data.materials.append(m)
    return path


def export(o, name, maps, out):
    md = o.modifiers.new('tri', 'TRIANGULATE')
    uvn = o.data.uv_layers.active.name; a = blmesh.mesh_arrays(o, (uvn,))
    pos = hullio.bl_to_game(a['pos']); nor = hullio.bl_to_game(a['nor']); nor /= np.maximum(np.linalg.norm(nor, axis=1, keepdims=True), 1e-9)
    tg = a['tan'].copy(); tg[:, :3] = hullio.bl_to_game(tg[:, :3]); tg[:, :3] /= np.maximum(np.linalg.norm(tg[:, :3], axis=1, keepdims=True), 1e-9); tg[:, 3] = np.where(tg[:, 3] < 0, -1., 1.)
    uv = a['uv'][uvn].copy(); uv[:, 1] = 1 - uv[:, 1]; uv = np.clip(uv, 0, 1)
    base = out[:-4]; np.savez(base + '_mesh.npz', pos=pos.astype(np.float32), nor=nor.astype(np.float32), idx=a['idx'].astype(np.uint32), uv=uv.astype(np.float32), tan=tg.astype(np.float32))
    json.dump(dict(name=name, faction='corsair', glb=out, maps=maps, extras=dict(faction='corsair', source='C19_51 v15 painted (project_paint PAINT=proc)', frame='bow at -x (turn 180 about y)')),
              open(base + '_meta.json', 'w'), indent=1)
    o.modifiers.remove(md)
    try:
        import PIL  # noqa
    except ImportError:
        log('PIL not here: run pack_glb.py on', base + '_meta.json'); return dict(tris=len(a['idx']) // 3, problems=['not packed yet'])
    import pack_glb; return pack_glb.pack(base + '_meta.json')


def main():
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    src, outdir, res = a[0], a[1], int(a[2]); checks = a[a.index('--checks') + 1] if '--checks' in a else None
    os.makedirs(outdir, exist_ok=True); blmesh.reset(); t0 = time.time()
    shell = import_one(os.path.join(src, 'shell_painted.glb')); kit = import_one(os.path.join(src, 'kit_painted.glb'))
    lights = light_points([shell, kit]); log('running lights at', [tuple(round(c, 3) for c in p) for p in lights])
    mat = emission_mat(lights); rep = {}
    for o, nm, alb in ((shell, 'C19_51_shell', 'shell_albproj'), (kit, 'C19_51_kit', 'kit_albproj')):
        base = os.path.join(src, alb)
        maps = dict(albedo=base + '.png', orm=base + '_orm.png', normal=base + '_nrm.png', emit=bake_emit(o, mat, res, base + '_emit.png'))
        for k, p in maps.items():
            if not os.path.exists(p): raise SystemExit(f'missing {p} (run project_paint.py with PAINT=proc first)')
        chk = export(o, nm, maps, os.path.join(outdir, nm + '.glb')); rep[nm] = chk; log('wrote', nm, chk)
    json.dump(rep, open(os.path.join(outdir, 'C19_51_report.json'), 'w'), indent=1)
    if checks:
        import checks as C
        os.makedirs(checks, exist_ok=True); tmp = os.path.join(checks, '_r_C19_51'); os.makedirs(tmp, exist_ok=True)
        sc = bpy.context.scene; C.studio(sc, samples=int(os.environ.get('CHECK_SAMPLES', '16')))
        for o, alb in ((shell, 'shell_albproj'), (kit, 'kit_albproj')):
            base = os.path.join(src, alb); uvn = o.data.uv_layers.active.name
            o.data.materials.clear(); o.data.materials.append(C.painted_mat(dict(base=base + '.png', orm=base + '_orm.png', normal=base + '_nrm.png', emissive=base + '_emit.png'), uv=uvn))
        for ob in (shell, kit): ob.rotation_euler.z = math.pi  # bow to +x like the other ships' check views
        bpy.context.view_layer.update()
        C.render_views([shell, kit], os.path.join(tmp, 'paint'))
        sc.world.node_tree.nodes['Background'].inputs[1].default_value = .05
        for L_ in [x for x in sc.objects if x.type == 'LIGHT']: L_.data.energy *= .08
        C.render_views([shell, kit], os.path.join(tmp, 'dark'))
        json.dump(dict(code='C19_51', faction='corsair', res=res), open(os.path.join(tmp, 'info.json'), 'w'))
        try:
            import checks_sheet; checks_sheet.make_barge(checks)
        except ImportError: log('renders in', tmp, '(sheets: pack_glb.py --sheets)')
    log('done', round(time.time() - t0), 's')


if __name__ == '__main__':
    main()
