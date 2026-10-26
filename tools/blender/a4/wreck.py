# A4 wreck and death pieces (K1 decision 10): the finished ship (same atlas, so the chunks wear the ship's own paint) cut into chunks by
# planes, each cut capped with a separate "interior" surface (scorched, for the effects helper to glow or char), each chunk saved with
# its origin at its own centre of mass. Cuts run mostly across the hull (a ship breaks across its length), some along it or at a slant.
# Output: OUT/CODE_wreck.npz with per chunk: body arrays (pos, nor, uv, tan, idx) and cap arrays (pos, nor, idx), centre, volume.
import math, random
import numpy as np
import bpy, bmesh
from mathutils import Vector
import blmesh, frame
DECIMATE = .45


def _bm_bounds(bm):
    co = np.array([v.co[:] for v in bm.verts]) if len(bm.verts) else np.zeros((1, 3))
    return co.min(0), co.max(0), co


def _split(bm, co, no, cap_name):
    """returns (negative side, positive side) bmeshes, both capped where the plane cut them"""
    out = []
    for clear_outer in (True, False):
        b = bm.copy(); cap_layer = b.faces.layers.int[cap_name]; geom = b.verts[:] + b.edges[:] + b.faces[:]
        r = bmesh.ops.bisect_plane(b, geom=geom, dist=1e-6, plane_co=co, plane_no=no, clear_outer=clear_outer, clear_inner=not clear_outer)
        cut_e = [e for e in r['geom_cut'] if isinstance(e, bmesh.types.BMEdge)]
        if cut_e:
            try:
                f = bmesh.ops.triangle_fill(b, use_beauty=True, use_dissolve=False, edges=cut_e, normal=no if clear_outer else -no)
                want = Vector(no) if clear_outer else -Vector(no)
                for face in f['geom']:
                    if isinstance(face, bmesh.types.BMFace):
                        face[cap_layer] = 1
                        if face.normal.dot(want) < 0: face.normal_flip()
            except Exception as e:
                print('[wreck] cap fill failed', e)
        out.append(b)
    return out


def _arrays(bm, cap_name, want_cap, name):
    b = bm.copy(); cap_layer = b.faces.layers.int[cap_name]; dead = [f for f in b.faces if (f[cap_layer] == 1) != want_cap]
    bmesh.ops.delete(b, geom=dead, context='FACES'); loose = [v for v in b.verts if not v.link_faces]
    if loose: bmesh.ops.delete(b, geom=loose, context='VERTS')
    if not b.faces: b.free(); return None
    bmesh.ops.triangulate(b, faces=b.faces[:])  # bisect leaves n-gons; tangents need triangles
    me = bpy.data.meshes.new(name); b.to_mesh(me); b.free(); o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    if not want_cap and DECIMATE < 1:  # chunks are seen drifting and burning, not up close: lighter than the live hull
        md = o.modifiers.new('dec', 'DECIMATE'); md.ratio = DECIMATE
        try: md.use_collapse_triangulate = True
        except Exception: pass
    if want_cap:
        for p in me.polygons: p.use_smooth = False
    a = blmesh.mesh_arrays(o, ('UV0',) if 'UV0' in me.uv_layers else ())
    bpy.data.objects.remove(o); bpy.data.meshes.remove(me)
    return a


def make(ship, code, outdir, count, seed=1):
    rng = random.Random(seed * 7 + 3); cap_layer_name = 'wcap'
    bm = bmesh.new(); bm.from_mesh(ship.data); bmesh.ops.triangulate(bm, faces=bm.faces[:])
    cap = bm.faces.layers.int.new(cap_layer_name)
    chunks = [bm]; tries = 0
    while len(chunks) < count and tries < count * 6:
        tries += 1
        sizes = []
        for c in chunks:
            lo, hi, _ = _bm_bounds(c); sizes.append(float(np.prod(np.maximum(hi - lo, 1e-4))))
        k = int(np.argmax(sizes)); c = chunks[k]; lo, hi, co = _bm_bounds(c); ext = hi - lo
        u = rng.random()
        if u < .65: no = Vector((1, rng.uniform(-.35, .35), rng.uniform(-.35, .35)))  # across the hull
        elif u < .85: no = Vector((rng.uniform(-.3, .3), 1, rng.uniform(-.3, .3)))  # split port from starboard
        else: no = Vector((rng.uniform(-.4, .4), rng.uniform(-.3, .3), 1))  # top from bottom
        no.normalize(); mid = Vector(((lo + hi) / 2).tolist()) + Vector((ext[0] * rng.uniform(-.18, .18), ext[1] * rng.uniform(-.12, .12), ext[2] * rng.uniform(-.12, .12)))
        a, b = _split(c, mid, no, cap_layer_name)
        na, nb = len(a.faces), len(b.faces)
        if min(na, nb) < max(200, len(c.faces) * .08): a.free(); b.free(); continue  # a sliver: try another plane
        chunks[k] = a; chunks.append(b); c.free()
    out = []; data = {}
    for i, c in enumerate(chunks):
        body = _arrays(c, cap_layer_name, False, f'wb{i}'); capa = _arrays(c, cap_layer_name, True, f'wc{i}')
        if body is None: continue
        P = np.concatenate([body['pos']] + ([capa['pos']] if capa is not None else [])); I = np.concatenate([body['idx']] + ([capa['idx'] + len(body['pos'])] if capa is not None else []))
        A, B, C = P[I[:, 0]], P[I[:, 1]], P[I[:, 2]]; v = np.einsum('ij,ij->i', A, np.cross(B, C)) / 6
        cen = ((A + B + C) / 4 * v[:, None]).sum(0) / v.sum() if abs(v.sum()) > 1e-9 else P.mean(0)
        vol = abs(float(v.sum()))
        if vol < 1e-7: vol = float(np.prod(P.max(0) - P.min(0))) * .3  # open chunk: a rough volume from its box
        cen_gl = frame.bl_to_gl(np.array([cen]))[0]
        def conv(a, with_uv):
            d = dict(pos=(frame.bl_to_gl(a['pos']) - cen_gl).astype(np.float32), nor=frame.bl_to_gl(a['nor']).astype(np.float32), idx=a['idx'].astype(np.uint32))
            d['nor'] /= np.maximum(np.linalg.norm(d['nor'], axis=1, keepdims=True), 1e-9)
            if with_uv and a.get('tan') is not None:
                uv = a['uv']['UV0'].copy(); uv[:, 1] = 1 - uv[:, 1]; d['uv'] = np.clip(uv, 0, 1).astype(np.float32)
                tg = a['tan'].copy(); tg[:, :3] = frame.bl_to_gl(tg[:, :3]); tg[:, :3] /= np.maximum(np.linalg.norm(tg[:, :3], axis=1, keepdims=True), 1e-9)
                tg[:, 3] = np.where(tg[:, 3] < 0, -1., 1.); d['tan'] = tg.astype(np.float32)
            return d
        bd = conv(body, True)
        for k_, v_ in bd.items(): data[f'c{i}_body_{k_}'] = v_
        if capa is not None:
            cd = conv(capa, False)
            for k_, v_ in cd.items(): data[f'c{i}_cap_{k_}'] = v_
        out.append(dict(i=i, centre=cen_gl.tolist(), volume=round(vol, 7), tris=int(len(I))))
        c.free()
    path = f'{outdir}/{code}_wreck.npz'; np.savez(path, **data)
    print('[wreck]', code, len(out), 'chunks', flush=True)
    return out
