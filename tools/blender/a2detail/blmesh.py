# A2 max-detail ships: Blender-side helpers shared by the build, bake and check scripts. Runs under Blender 4.5 (PC) and the bpy 5.2
# module (cloud); every call that differs between them is guarded here.
import math
import numpy as np
import bpy, bmesh

V45 = bpy.app.version < (5, 0, 0)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mesh_from_arrays(name, pos, idx, nor=None, uvs=None, smooth=True):
    """pos (V,3) Blender frame, idx (F,3); nor: per-vertex custom normals; uvs: dict name -> (V,2) with v up (Blender convention)"""
    me = bpy.data.meshes.new(name)
    me.vertices.add(len(pos)); me.vertices.foreach_set('co', np.asarray(pos, np.float32).ravel())
    F = len(idx); me.loops.add(F * 3); me.loops.foreach_set('vertex_index', np.asarray(idx, np.int32).ravel())
    me.polygons.add(F); me.polygons.foreach_set('loop_start', np.arange(0, F * 3, 3, dtype=np.int32))
    try: me.polygons.foreach_set('loop_total', np.full(F, 3, np.int32))
    except Exception: pass  # newer versions derive loop_total from loop_start
    me.update(calc_edges=True); me.validate(clean_customdata=False)
    li = np.asarray(idx, np.int64).ravel()
    for k, uv in (uvs or {}).items():
        l = me.uv_layers.new(name=k); l.data.foreach_set('uv', np.asarray(uv, np.float32)[li].ravel())
    me.polygons.foreach_set('use_smooth', np.full(F, bool(smooth)))
    if nor is not None:
        set_custom_normals(me, np.asarray(nor, np.float32))
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o); return o


def set_custom_normals(me, vnor):
    if V45:
        try: me.use_auto_smooth = True  # 4.0 and older; 4.1+ dropped it (custom normals work without)
        except Exception: pass
    me.normals_split_custom_set_from_vertices([tuple(n) for n in vnor])


def mesh_arrays(o, uv_names=()):
    """evaluated, triangulated arrays with per-corner data turned into split vertices: pos, nor (split normals), uv per name, tangent (from
    the first uv), idx, plus per-vertex float attributes when present"""
    dg = bpy.context.evaluated_depsgraph_get(); oe = o.evaluated_get(dg); me = oe.to_mesh()
    me.calc_loop_triangles()
    uvn = uv_names[0] if uv_names else None
    if uvn:
        me.uv_layers.active = me.uv_layers[uvn]
        try: me.calc_tangents(uvmap=uvn)
        except Exception as e: print('tangents failed', e)
    L = len(me.loops)
    lv = np.zeros(L, np.int32); me.loops.foreach_get('vertex_index', lv)
    co = np.zeros(len(me.vertices) * 3, np.float32); me.vertices.foreach_get('co', co); co = co.reshape(-1, 3)
    ln = np.zeros(L * 3, np.float32)
    try: me.corner_normals.foreach_get('vector', ln)
    except Exception:
        try: me.calc_normals_split()
        except Exception: pass
        me.loops.foreach_get('normal', ln)
    ln = ln.reshape(-1, 3)
    uvd = {}
    for k in uv_names:
        a = np.zeros(L * 2, np.float32); me.uv_layers[k].data.foreach_get('uv', a); uvd[k] = a.reshape(-1, 2)
    tg = None
    if uvn:
        t = np.zeros(L * 3, np.float32); s = np.zeros(L, np.float32); me.loops.foreach_get('tangent', t); me.loops.foreach_get('bitangent_sign', s)
        tg = np.concatenate([t.reshape(-1, 3), s[:, None]], 1)
    tri = np.zeros(len(me.loop_triangles) * 3, np.int32); me.loop_triangles.foreach_get('loops', tri); tri = tri.reshape(-1, 3)
    attrs = {}
    for a in me.attributes:
        if a.domain == 'POINT' and a.data_type == 'FLOAT' and not a.name.startswith('.'):
            v = np.zeros(len(me.vertices), np.float32); a.data.foreach_get('value', v); attrs[a.name] = v[lv]
    # weld corners that share vertex, normal, uv and tangent (keeps the file small)
    parts = [lv[:, None].astype(np.float32), np.round(ln, 4)] + [np.round(uvd[k], 6) for k in uv_names] + ([np.round(tg, 4)] if tg is not None else [])
    keyarr = np.concatenate(parts, 1)
    _, first, inv = np.unique(keyarr, axis=0, return_index=True, return_inverse=True); inv = inv.reshape(-1)
    out = dict(pos=co[lv[first]], nor=ln[first], idx=inv[tri], uv={k: uvd[k][first] for k in uv_names}, attrs={k: v[first] for k, v in attrs.items()})
    out['tan'] = tg[first] if tg is not None else None
    oe.to_mesh_clear(); return out


def gpu_on(sc):
    sc.render.engine = 'CYCLES'
    try:
        pr = bpy.context.preferences.addons['cycles'].preferences
        for t_ in ('OPTIX', 'CUDA'):
            try:
                pr.compute_device_type = t_; pr.get_devices()
                if any(d.type == t_ for d in pr.devices):
                    for d in pr.devices: d.use = d.type == t_
                    sc.cycles.device = 'GPU'; print('device', t_); return t_
            except Exception: pass
    except Exception: pass
    sc.cycles.device = 'CPU'; print('device CPU'); return 'CPU'


def new_image(name, res, data=False, float_buf=False):
    im = bpy.data.images.new(name, res, res, alpha=False, float_buffer=float_buf, is_data=data)
    if data:
        try: im.colorspace_settings.name = 'Non-Color'
        except Exception: pass
    return im


def image_to_numpy(im):
    w, h = im.size; a = np.empty(w * h * 4, np.float32); im.pixels.foreach_get(a); return a.reshape(h, w, 4)[::-1]  # top row first


def load_image_np(path):
    """image as (H, W, 3) floats in 0..1, top row first, raw values (no colour management). Blender's own loader, so it works without PIL
    (Blender 4.5's bundled Python has none)."""
    im = bpy.data.images.load(path, check_existing=True)
    try: im.colorspace_settings.name = 'Non-Color'
    except Exception: pass
    a = image_to_numpy(im)[..., :3].copy(); return a
