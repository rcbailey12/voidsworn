# Issue 209 round 4: the two cells, Ab4 (all hand parts) and Hy4 (Ab4 plus Hy3's generated casemates and drum racks; hand-built bow
# guns), on the round 4 slab structure (armA4.py, silhouette first). Every step after the geometry is round 3's (bakeAb3.py):
# Steps (all in one Blender run; GPU on the PC, CPU at low resolution in the cloud sandbox for tests):
#   1. geometry (armA4.build_geometry), the audit, the hull blocks and plates joined into one hull and UV unwrapped;
#   2. the break structure (rim bands, bulkheads, decks); the hull's skin (solidify) is held off during the bakes;
#   3. B0's surface detail: the B0 generation (yaw fixed) is TRIMMED to a shell round the hand hull, so its own drums, tower and masts
#      no longer print ghost copies on the decks (round 2's flaw); its normals are baked twice, from the trimmed B0 and from a smoothed
#      copy, and the smooth one is taken out of the sharp one (a detail-only normal map: B0's panel lines, grilles and ribs stay, its
#      lopsided, melted large shape goes, and the hand-built plate chamfers keep their own shading); B0's cavity AO is baked too;
#   4. the concept paint (paint3.py) baked into albedo and ORM maps, one atlas for the hull (RES), one for the hand parts (RES / 2),
#      and in the hybrid one for the generated hero parts (RES / 2) and one for the hand parts it hides in the hero slots (RES / 4);
#   5. the textured materials replace the procedural ones; the blend is what render.py and export3.py read.
# usage: blender -b -P bakeAb4.py -- OUT_DIR B0_GLB GEN3D_DIR CELL [RES] [SAMPLES]      CELL = Ab4 or Hy4
import os, sys, math, json, time
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import bpy, bmesh
import numpy as np
from mathutils import Vector
import common as C
import armA4 as A3   # round 4 blocks (the module keeps the A3 name so the steps below read as in round 3)
import paint3 as P3

A = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else ['', '', '', 'Ab3']
OUT, B0, GEN, CELL = A[0], A[1], A[2], A[3]
RES = int(A[4]) if len(A) > 4 else 4096; SAMPLES = int(A[5]) if len(A) > 5 else 64
CAGE, RAY, AO_DIST = .035, .070, .025     # as round 2 (ray reach tuned there)
TRIM_OUT = .010        # B0 faces more than this outside the hand hull are cut from the bake source (its drums, tower, masts, rails)
SMOOTH_TRIS = 12000     # the smooth copy: B0 decimated to this many faces, smooth shaded (keeps B0's large shape, drops its detail)
INFO = {}
KEEP_SRC = False
B0_NORMALS = 'keep'   # 'keep': the generator's stored normals (tested best); 'turn': turn faces outward and rebuild normals from them
MAX_TILT = 40.0       # degrees: detail normals tilted further than this are bake errors (rays meeting B0 edge-on or from behind)

def gpu():
    sc = bpy.context.scene; sc.render.engine = 'CYCLES'
    prefs = bpy.context.preferences.addons['cycles'].preferences
    for t in ('OPTIX', 'CUDA'):
        try:
            prefs.compute_device_type = t; prefs.get_devices()
            if not [d for d in prefs.devices if d.type == t]: continue
            for d in prefs.devices: d.use = True
            sc.cycles.device = 'GPU'; return t
        except Exception: pass
    return 'CPU'

def join(objs, name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]; bpy.ops.object.join(); o = bpy.context.view_layer.objects.active; o.name = name; return o

def unwrap(objs, margin=.003):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=margin); bpy.ops.object.mode_set(mode='OBJECT')

def img_np(im):
    a = np.empty(im.size[0] * im.size[1] * 4, np.float32); im.pixels.foreach_get(a); return a.reshape(-1, 4)

def trim_source(src, hull):
    """cut away every B0 face more than TRIM_OUT outside the hand hull (signed distance along the hull's normal at the nearest point),
    TRELLIS.2's whole-hull mesh has mixed triangle winding (about 45 percent of the first faces a ray from outside meets face inward),
    but its stored normals point outward, so they are kept ('keep'); rebuilding normals from turned faces ('turn') tested worse."""
    T = C.bvh([hull]); bm = bmesh.new(); bm.from_mesh(src.data); bm.faces.ensure_lookup_table(); kill = []; flip = []
    for f in bm.faces:
        c = f.calc_center_median(); h = T.find_nearest(c)
        if h[0] is None: kill.append(f); continue
        if (c - h[0]).dot(h[1]) > TRIM_OUT: kill.append(f)
        elif B0_NORMALS == 'turn' and f.normal.dot(h[1]) < 0: flip.append(f)
    n0 = len(bm.faces); bmesh.ops.reverse_faces(bm, faces=flip); INFO['b0_faces_turned'] = len(flip)
    bmesh.ops.delete(bm, geom=kill, context='FACES'); bm.to_mesh(src.data); bm.free()
    if B0_NORMALS == 'turn':
        bpy.context.view_layer.objects.active = src
        with bpy.context.temp_override(object=src, active_object=src):
            bpy.ops.mesh.customdata_custom_splitnormals_clear()
        for p in src.data.polygons: p.use_smooth = True
    return n0, n0 - len(kill)

def b0_bakes(hull):
    """steps 3: trimmed B0, smoothed B0, the detail-only normal map and the cavity AO, all on the hull's UVs"""
    t0 = time.time()
    src = C.import_glb(B0, 'b0_src'); C.ai_align(src, 22.0)
    n0, n1 = trim_source(src, hull); INFO.update(b0_triangles_faces=n0, b0_faces_kept=n1, trim_outside=TRIM_OUT)
    sm = src.copy(); sm.data = src.data.copy(); bpy.context.scene.collection.objects.link(sm); sm.name = 'b0_smooth'
    m = sm.modifiers.new('dec', 'DECIMATE'); sm.data.calc_loop_triangles(); m.ratio = min(1, SMOOTH_TRIS / max(1, len(sm.data.loop_triangles)))
    bpy.context.view_layer.objects.active = sm
    for mm in list(sm.modifiers): bpy.ops.object.modifier_apply(modifier=mm.name)
    for p in sm.data.polygons: p.use_smooth = True
    sc = bpy.context.scene
    if sc.world is None: sc.world = bpy.data.worlds.new('w')
    sc.world.light_settings.distance = AO_DIST
    INFO['bake_device'] = gpu(); sc.cycles.samples = SAMPLES
    bmat = bpy.data.materials.new('bake_target'); bmat.use_nodes = True; tex = bmat.node_tree.nodes.new('ShaderNodeTexImage')
    keep = list(hull.data.materials); hull.data.materials.clear(); hull.data.materials.append(bmat)
    rb = sc.render.bake; rb.use_selected_to_active = True; rb.cage_extrusion = CAGE; rb.max_ray_distance = RAY; rb.margin = 8
    out = {}; was_hidden = {o.name: o.hide_render for o in bpy.context.scene.objects}
    for key, source, kind in (('hi', src, 'NORMAL'), ('lo', sm, 'NORMAL'), ('ao', src, 'AO')):
        im = bpy.data.images.new(f'{CELL}_b0{key}', RES, RES, alpha=False, float_buffer=(kind == 'NORMAL')); im.colorspace_settings.name = 'Non-Color'
        im.generated_color = (.5, .5, 1, 1) if kind == 'NORMAL' else (1, 1, 1, 1)
        tex.image = im; bmat.node_tree.nodes.active = tex
        bpy.ops.object.select_all(action='DESELECT'); source.select_set(True); hull.select_set(True); bpy.context.view_layer.objects.active = hull
        for a in ('visible_diffuse', 'visible_glossy', 'visible_shadow', 'visible_transmission', 'visible_volume_scatter'): setattr(hull, a, kind != 'AO')
        for o in bpy.context.scene.objects:   # only the source counts for AO (parts and other objects hidden)
            if o not in (src, sm, hull) and o.type == 'MESH': o.hide_render = True
        src.hide_render = source is not src; sm.hide_render = source is not sm
        t1 = time.time(); bpy.ops.object.bake(type=kind, normal_space='TANGENT' if kind == 'NORMAL' else 'OBJECT'); INFO[f'bake_{key}_seconds'] = round(time.time() - t1, 1)
        out[key] = im
    for o in bpy.context.scene.objects: o.hide_render = was_hidden.get(o.name, False)
    for a in ('visible_diffuse', 'visible_glossy', 'visible_shadow', 'visible_transmission', 'visible_volume_scatter'): setattr(hull, a, True)
    # detail-only normal: rotate the sharp normal by the rotation that takes the smooth normal to straight up (tangent space)
    hi = img_np(out['hi'])[:, :3] * 2 - 1; lo = img_np(out['lo'])[:, :3] * 2 - 1
    hi /= np.maximum(np.linalg.norm(hi, axis=1, keepdims=True), 1e-6); lo /= np.maximum(np.linalg.norm(lo, axis=1, keepdims=True), 1e-6)
    v = np.stack([lo[:, 1], -lo[:, 0], np.zeros(len(lo), np.float32)], 1); c = lo[:, 2:3]
    d = hi * c + np.cross(v, hi) + v * (np.sum(v * hi, 1, keepdims=True) / np.maximum(1 + c, 1e-3))
    d /= np.maximum(np.linalg.norm(d, axis=1, keepdims=True), 1e-6)
    cz = math.cos(math.radians(MAX_TILT)); bad = d[:, 2] < 0; INFO['detail_pixels_inverted_share'] = round(float(bad.mean()), 4)
    d[bad] = (0, 0, 1)
    steep = d[:, 2] < cz; INFO['detail_pixels_clamped_share'] = round(float(steep.mean()), 4)
    xy = d[steep, :2]; xy *= (math.sin(math.radians(MAX_TILT)) / np.maximum(np.linalg.norm(xy, axis=1, keepdims=True), 1e-6)); d[steep, :2] = xy; d[steep, 2] = cz
    nimg = bpy.data.images.new(f'{CELL}_normal', RES, RES, alpha=False); nimg.colorspace_settings.name = 'Non-Color'
    px = np.concatenate([d * .5 + .5, np.ones((len(d), 1), np.float32)], 1).astype(np.float32); nimg.pixels.foreach_set(px.ravel())
    for k, im in (('normal', nimg), ('b0ao', out['ao'])):
        im.filepath_raw = os.path.join(OUT, f'{CELL}_{k}.png'); im.file_format = 'PNG'; im.save(); im.pack()
    tilt = np.degrees(np.arccos(np.clip(d[:, 2], -1, 1))); tilt_hi = np.degrees(np.arccos(np.clip(hi[:, 2], -1, 1)))
    INFO.update(normal_tilt_mean_deg_detail=round(float(tilt.mean()), 2), normal_tilt_mean_deg_raw=round(float(tilt_hi.mean()), 2))
    if KEEP_SRC: INFO['_dbg'] = (hi, lo, d)
    if not KEEP_SRC:
        for o in (src, sm): bpy.data.objects.remove(o)
        for im in (out['hi'], out['lo']): bpy.data.images.remove(im)
    hull.data.materials.clear()
    for mm in keep: hull.data.materials.append(mm)
    INFO['b0_bake_total_seconds'] = round(time.time() - t0, 1)
    return nimg, out['ao']

def lod_tags(objs):
    """per object: its size (bounding box diagonal, ship units), so export3 can drop small parts in the hand LOD chain"""
    for o in objs:
        w = [o.matrix_world @ Vector(b) for b in o.bound_box]
        o['size'] = max((Vector([max(v[i] for v in w) for i in range(3)]) - Vector([min(v[i] for v in w) for i in range(3)])).length, 0)

def main():
    t0 = time.time(); os.makedirs(OUT, exist_ok=True)
    hero = A3.HERO_SLOTS if CELL.startswith('Hy') else ()
    S, Pl, hard, gen, notes, prox = A3.build_geometry(hero, GEN)
    t_geo = time.time() - t0
    au = C.audit(S + Pl, [o for o in hard if o.get('role') != 'glow'] + gen, A3.GUNS); au['plates_crossing_break_lines'] = A3.plate_crossing(Pl)
    block_t = sum(C.tris(o) for o in S); plate_t = sum(C.tris(o) for o in Pl); gen_t = sum(C.tris(o) for o in gen)
    hull = join(S + Pl, 'hull_baked'); hull['role'] = 'hull'; hull['kind'] = 'hull'; unwrap([hull])
    made, fit = C.breakable([hull]); skin = hull.modifiers.get('skin'); skin.show_render = False; skin.show_viewport = False
    nimg, b0ao = b0_bakes(hull)
    parts = hard + gen; allobj = [hull] + parts + made + prox
    mats = P3.assign(allobj, [hull], b0ao)
    lod_tags(parts + made + prox)
    painted = [o for o in hard + made if o.get('role') not in ('interior', 'glow')]
    pprox = [o for o in prox if o.get('role') not in ('interior', 'glow')]
    unwrap(painted, margin=.002)
    if pprox: unwrap(pprox, margin=.002)
    if gen: unwrap(gen, margin=.002)   # the generated parts get their own atlas: their thousands of tiny UV islands, packed in with
    #                                    the hand parts, shrank every island below a texel and the parts baked black (round 3 first run)
    sc = bpy.context.scene; sc.cycles.samples = max(4, SAMPLES // 8); t1 = time.time()
    hm = [m for (b, g), m in mats.items() if g == 'H']; pm = [m for (b, g), m in mats.items() if g == 'P']; gm = [m for (b, g), m in mats.items() if g == 'G']
    himg, th = P3.bake_group([hull], hm, f'{CELL}_hull', RES, OUT)
    pimg, tp = P3.bake_group(painted, pm, f'{CELL}_parts', RES // 2, OUT, margin=4)
    if pprox:   # second pass: the hand proxies into the same atlas, with the generated parts out of the way
        for o in gen: o.hide_render = True
        for o in prox: o.hide_render = False
        ximg, tp2 = P3.bake_group(pprox, pm, f'{CELL}_proxy', RES // 4, OUT, margin=4); tp['proxies'] = tp2
        for o in gen: o.hide_render = False
        for o in prox: o.hide_render = True
    if gen:
        gimg, tg = P3.bake_group(gen, gm, f'{CELL}_gen', RES // 2, OUT, margin=4); tp['generated'] = tg
    INFO.update(paint_bake_seconds=round(time.time() - t1, 1), paint_bake_hull=th, paint_bake_parts=tp)
    HM = P3.textured(f'{CELL}_hull_mat', himg['albedo'], himg['orm'], nimg); PM = P3.textured(f'{CELL}_parts_mat', pimg['albedo'], pimg['orm'])
    hull.data.materials.clear(); hull.data.materials.append(HM); hull.data.polygons.foreach_set('material_index', np.zeros(len(hull.data.polygons), np.int32))
    for o in painted:
        o.data.materials.clear(); o.data.materials.append(PM); o.data.polygons.foreach_set('material_index', np.zeros(len(o.data.polygons), np.int32))
    if pprox:
        XM = P3.textured(f'{CELL}_proxy_mat', ximg['albedo'], ximg['orm'])
        for o in pprox:
            o.data.materials.clear(); o.data.materials.append(XM); o.data.polygons.foreach_set('material_index', np.zeros(len(o.data.polygons), np.int32))
    if gen:
        GM = P3.textured(f'{CELL}_gen_mat', gimg['albedo'], gimg['orm'])
        for o in gen:
            o.data.materials.clear(); o.data.materials.append(GM); o.data.polygons.foreach_set('material_index', np.zeros(len(o.data.polygons), np.int32))
    for m in list(bpy.data.materials):
        if m.name.startswith('p3_') and m.users == 0 and m.name not in ('p3_glow', 'p3_interior'): bpy.data.materials.remove(m)
    skin.show_render = True; skin.show_viewport = True
    C.mats()  # the clay override material render.py uses
    rep = C.report([hull] + parts + made)
    meta = dict(cell=CELL, route='round 4 slab structure (concept silhouette, layered armour) + hand parts' + (' + AI hero parts' if hero else '') + ' + B0 detail baked + concept paint baked',
                build_seconds=round(time.time() - t0, 1), geometry_seconds=round(t_geo, 1), audit=au, break_fit=fit, break_lines=A3.BREAK,
                block_triangles=block_t, plate_triangles=plate_t, plates=len(Pl), hero_parts=[o.name for o in gen], hero_triangles=gen_t,
                generations=notes, hand_parts=len(hard), proxies=len(prox), bake=INFO, res=RES, parts_res=RES // 2, **rep)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, f'{CELL}.blend'))
    json.dump(meta, open(os.path.join(OUT, f'{CELL}.json'), 'w'), indent=1); print('[209]', CELL, json.dumps(meta)[:2000], flush=True)

if __name__ == '__main__':
    main()
