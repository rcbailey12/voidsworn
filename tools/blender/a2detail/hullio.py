# A2 max-detail ships: shared input/output helpers (no Blender needed for most of it).
#   load_hull(root, code)  decodes hulls_hi/CODE.json the way contrib/opus/enginetest/hull2glb.py does (game frame: x bow, y up, z port)
#   pn_subdivide(...)      one 1-to-4 split; new edge points follow the stored normals (curved) except across hard edges (kept straight)
#   write_glb(...)         one mesh, one material, embedded images (PNG normal map, JPEG colour maps), core glTF 2.0 only
# Frames: game (gx, gy up, gz port) <-> Blender (bx = gx, by = -gz, bz = gy). Blender's own glTF importer/exporter uses the same map.
import os, io, json, base64, struct, math
import numpy as np


def game_to_bl(p):
    p = np.asarray(p, np.float32); return np.stack([p[:, 0], -p[:, 2], p[:, 1]], 1)


def bl_to_game(p):
    p = np.asarray(p, np.float32); return np.stack([p[:, 0], p[:, 2], -p[:, 1]], 1)


def load_hull(root, code, folder='hulls_hi'):
    """returns dict(pos, nor, idx (N,3), uv2 (v-down, glTF style), tex=(path_n, path_m)) in the game frame"""
    j = json.load(open(os.path.join(root, folder, code + '.json')))
    b = lambda s, t: np.frombuffer(base64.b64decode(s), t)
    ext = np.array(j['ext'], np.float32)
    pos = b(j['p'], np.int16).reshape(-1, 3).astype(np.float32) / 32767 * ext
    nor = b(j['q'], np.int8).reshape(-1, 3).astype(np.float32) / 127
    nor /= np.maximum(np.linalg.norm(nor, axis=1, keepdims=True), 1e-6)
    idx = b(j['i'], np.uint32 if j.get('i32') else np.uint16).astype(np.int64).reshape(-1, 3)
    uv2 = b(j['u'], np.uint16).reshape(-1, 2).astype(np.float32) / 65535
    uv2[:, 1] = 1 - uv2[:, 1]
    return dict(pos=pos, nor=nor, idx=idx, uv2=uv2, tex=(os.path.join(root, folder, code + '_n.webp'), os.path.join(root, folder, code + '_m.webp')))


def weld_ids(pos, tol=1e-5):
    """id per vertex shared by every vertex at the same position (the atlas splits vertices along UV seams)"""
    q = np.round(pos / tol).astype(np.int64)
    _, inv = np.unique(q, axis=0, return_inverse=True)
    return inv.reshape(-1)


def pn_subdivide(pos, nor, idx, uvs, hard_cos=math.cos(math.radians(32)), bulge=1.0):
    """1-to-4 split of every triangle. Edge midpoints follow a cubic Hermite curve along the stored vertex normals (PN-triangle style), so
    the faceted decimated hull rounds out where it is meant to be smooth; edges whose end normals differ by more than ~32 degrees are hard
    edges and keep a straight midpoint (no melted corners). Midpoints are computed per welded position so both sides of a UV seam agree.
    uvs: list of (V,2) arrays carried linearly. Returns pos, nor, idx, uvs."""
    V = len(pos); w = weld_ids(pos)
    e = np.concatenate([idx[:, [0, 1]], idx[:, [1, 2]], idx[:, [2, 0]]], 0)  # (3F,2) vertex-index edges
    key = np.sort(e, 1); ukey, inv = np.unique(key, axis=0, return_inverse=True); inv = inv.reshape(-1)
    a, b_ = ukey[:, 0], ukey[:, 1]
    pa, pb, na, nb = pos[a], pos[b_], nor[a], nor[b_]
    # average normal per welded position (smooth normal), used for the curve unless the edge is hard
    W = w.max() + 1; ns = np.zeros((W, 3), np.float64); np.add.at(ns, w, nor); ns /= np.maximum(np.linalg.norm(ns, axis=1, keepdims=True), 1e-9)
    sa, sb = ns[w[a]], ns[w[b_]]
    d = pb - pa
    off = ((d * sb).sum(1)[:, None] * sb - (d * sa).sum(1)[:, None] * sa) / 8.0 * bulge
    hard = (na * nb).sum(1) < hard_cos  # stored normals already split at hard edges: those edges stay straight
    soft_ok = (sa * sb).sum(1) > hard_cos
    off[hard | ~soft_ok] = 0
    mid = (pa + pb) / 2 + off.astype(np.float32)
    mn = na + nb; mn /= np.maximum(np.linalg.norm(mn, axis=1, keepdims=True), 1e-9)
    newpos = np.concatenate([pos, mid], 0).astype(np.float32); newnor = np.concatenate([nor, mn], 0).astype(np.float32)
    newuvs = [np.concatenate([u, (u[a] + u[b_]) / 2], 0).astype(np.float32) for u in uvs]
    F = len(idx); m = inv.reshape(3, F).T + V  # midpoint of edges (01, 12, 20)
    i0, i1, i2 = idx[:, 0], idx[:, 1], idx[:, 2]; m01, m12, m20 = m[:, 0], m[:, 1], m[:, 2]
    nidx = np.concatenate([np.stack([i0, m01, m20], 1), np.stack([m01, i1, m12], 1), np.stack([m20, m12, i2], 1), np.stack([m01, m12, m20], 1)], 0)
    return newpos, newnor, nidx, newuvs


def pn_refine(pos, nor, idx, uvs, curve_frac=.012, long_q=.80, hard_cos=math.cos(math.radians(32))):
    """adaptive version of pn_subdivide: only edges that are curved (their PN midpoint moves more than curve_frac of their length) or long
    (above the long_q quantile) are split; triangles with 1, 2 or 3 split edges become 2, 3 or 4 (no T-junctions). Flat, short-edged areas
    stay as they are, so the triangles go where they change the shape."""
    V = len(pos); w = weld_ids(pos)
    e = np.concatenate([idx[:, [0, 1]], idx[:, [1, 2]], idx[:, [2, 0]]], 0)
    key = np.sort(e, 1); ukey, inv = np.unique(key, axis=0, return_inverse=True); inv = inv.reshape(-1)
    a, b_ = ukey[:, 0], ukey[:, 1]; pa, pb, na, nb = pos[a], pos[b_], nor[a], nor[b_]
    W = w.max() + 1; ns = np.zeros((W, 3), np.float64); np.add.at(ns, w, nor); ns /= np.maximum(np.linalg.norm(ns, axis=1, keepdims=True), 1e-9)
    sa, sb = ns[w[a]], ns[w[b_]]; d = pb - pa; L = np.linalg.norm(d, axis=1)
    off = ((d * sb).sum(1)[:, None] * sb - (d * sa).sum(1)[:, None] * sa) / 8.0
    hard = ((na * nb).sum(1) < hard_cos) | ((sa * sb).sum(1) < hard_cos); off[hard] = 0
    # the same geometric edge can appear twice (UV seam copies): decide per welded edge so both copies agree
    wk = np.sort(np.stack([w[a], w[b_]], 1), 1); _, winv = np.unique(wk, axis=0, return_inverse=True); winv = winv.reshape(-1)
    split = (np.linalg.norm(off, axis=1) > curve_frac * L) | (L > np.quantile(L, long_q))
    sw = np.zeros(winv.max() + 1, bool); np.logical_or.at(sw, winv, split); split = sw[winv]
    eid = np.full(len(ukey), -1, np.int64); eid[split] = V + np.arange(split.sum())
    mid = ((pa + pb) / 2 + off.astype(np.float32))[split]; mn = (na + nb)[split]; mn /= np.maximum(np.linalg.norm(mn, axis=1, keepdims=True), 1e-9)
    newpos = np.concatenate([pos, mid], 0).astype(np.float32); newnor = np.concatenate([nor, mn], 0).astype(np.float32)
    newuvs = [np.concatenate([u, ((u[a] + u[b_]) / 2)[split]], 0).astype(np.float32) for u in uvs]
    F = len(idx); M = eid[inv].reshape(3, F).T  # midpoint index per edge (01, 12, 20) or -1
    s = (M >= 0); cnt = s.sum(1); out = [idx[cnt == 0]]
    def rot(k):  # rotate each selected triangle by k positions: vertex i -> i+k, edge j -> j+k
        return np.roll(np.arange(3), -k)
    for c in (1, 2):
        sel = np.nonzero(cnt == c)[0]
        for k in range(3):
            if c == 1: m = sel[s[sel, k]]           # split edge k becomes edge 0
            else: m = sel[~s[sel, (k + 2) % 3]]     # unsplit edge (k+2) becomes edge 2
            if not len(m): continue
            r = rot(k); I = idx[m][:, r]; E = M[m][:, r]
            i0, i1, i2 = I[:, 0], I[:, 1], I[:, 2]
            if c == 1:
                out += [np.stack([i0, E[:, 0], i2], 1), np.stack([E[:, 0], i1, i2], 1)]
            else:
                out += [np.stack([i0, E[:, 0], E[:, 1]], 1), np.stack([E[:, 0], i1, E[:, 1]], 1), np.stack([i0, E[:, 1], i2], 1)]
    m = np.nonzero(cnt == 3)[0]; i0, i1, i2 = idx[m, 0], idx[m, 1], idx[m, 2]; m01, m12, m20 = M[m, 0], M[m, 1], M[m, 2]
    out += [np.stack([i0, m01, m20], 1), np.stack([m01, i1, m12], 1), np.stack([m20, m12, i2], 1), np.stack([m01, m12, m20], 1)]
    return newpos, newnor, np.concatenate(out, 0), newuvs


# ---------------------------------------------------------------------------------------------------------------------------------------
def _img_bytes(img, kind, quality=92):
    from PIL import Image
    if not isinstance(img, Image.Image): img = Image.open(img)
    img = img.convert('RGB'); bio = io.BytesIO()
    if kind == 'png': img.save(bio, 'PNG', compress_level=6)
    else: img.save(bio, 'JPEG', quality=quality, subsampling=0 if kind == 'jpg_hq' else 2, optimize=True)
    return bio.getvalue(), ('image/png' if kind == 'png' else 'image/jpeg')


def write_glb(out, name, pos, nor, idx, uv0, tangent=None, uv1=None, images=None, mat=None, extras=None):
    """pos/nor/tangent in the game frame (x bow, y up, z port). images: dict slot -> (PIL image or path, 'png'|'jpg'|'jpg_hq') for slots
    base, normal, orm, emissive. mat: dict(baseColorFactor, metallicFactor, roughnessFactor, emissiveFactor, occlusionStrength, normalScale)."""
    images = images or {}; mat = mat or {}
    pos = np.ascontiguousarray(pos, '<f4'); nor = np.ascontiguousarray(nor, '<f4'); uv0 = np.ascontiguousarray(uv0, '<f4')
    idx = np.ascontiguousarray(np.asarray(idx).reshape(-1), '<u4')
    blobs = [pos.tobytes(), nor.tobytes(), uv0.tobytes()]; attrs = {'POSITION': 0, 'NORMAL': 1, 'TEXCOORD_0': 2}
    acc = [{'bufferView': 0, 'componentType': 5126, 'count': len(pos), 'type': 'VEC3', 'min': pos.min(0).tolist(), 'max': pos.max(0).tolist()},
           {'bufferView': 1, 'componentType': 5126, 'count': len(pos), 'type': 'VEC3'},
           {'bufferView': 2, 'componentType': 5126, 'count': len(pos), 'type': 'VEC2'}]
    if tangent is not None:
        tg = np.ascontiguousarray(tangent, '<f4'); attrs['TANGENT'] = len(acc); acc.append({'bufferView': len(blobs), 'componentType': 5126, 'count': len(pos), 'type': 'VEC4'}); blobs.append(tg.tobytes())
    if uv1 is not None:
        u1 = np.ascontiguousarray(uv1, '<f4'); attrs['TEXCOORD_1'] = len(acc); acc.append({'bufferView': len(blobs), 'componentType': 5126, 'count': len(pos), 'type': 'VEC2'}); blobs.append(u1.tobytes())
    nvert = len(blobs)
    acc.append({'bufferView': len(blobs), 'componentType': 5125, 'count': len(idx), 'type': 'SCALAR'}); ia = len(acc) - 1; blobs.append(idx.tobytes())
    gl_images, textures = [], []; m = {'name': name + '_mat', 'pbrMetallicRoughness': {}}
    pbr = m['pbrMetallicRoughness']
    pbr['baseColorFactor'] = list(mat.get('baseColorFactor', [1, 1, 1, 1])); pbr['metallicFactor'] = mat.get('metallicFactor', 1.0); pbr['roughnessFactor'] = mat.get('roughnessFactor', 1.0)
    def add_tex(slot):
        im, kind = images[slot]; data, mime = _img_bytes(im, kind)
        gl_images.append({'bufferView': len(blobs), 'mimeType': mime, 'name': f'{name}_{slot}'}); blobs.append(data)
        textures.append({'source': len(gl_images) - 1, 'sampler': 0}); return len(textures) - 1
    if 'base' in images: pbr['baseColorTexture'] = {'index': add_tex('base'), 'texCoord': 0}
    if 'orm' in images:
        t = add_tex('orm'); pbr['metallicRoughnessTexture'] = {'index': t, 'texCoord': 0}
        m['occlusionTexture'] = {'index': t, 'texCoord': 0, 'strength': mat.get('occlusionStrength', 1.0)}
    if 'normal' in images: m['normalTexture'] = {'index': add_tex('normal'), 'texCoord': 0, 'scale': mat.get('normalScale', 1.0)}
    if 'emissive' in images:
        m['emissiveTexture'] = {'index': add_tex('emissive'), 'texCoord': 0}; m['emissiveFactor'] = list(mat.get('emissiveFactor', [1, 1, 1]))
    views, buf = [], bytearray()
    for i, bl in enumerate(blobs):
        buf += b'\0' * ((4 - len(buf) % 4) % 4); v = {'buffer': 0, 'byteOffset': len(buf), 'byteLength': len(bl)}
        if i < nvert: v['target'] = 34962
        elif i == nvert: v['target'] = 34963
        views.append(v); buf += bl
    buf += b'\0' * ((4 - len(buf) % 4) % 4)
    gl = {'asset': {'version': '2.0', 'generator': 'voidsworn a2detail'}, 'scene': 0, 'scenes': [{'nodes': [0]}],
          'nodes': [{'name': name, 'mesh': 0}],
          'meshes': [{'name': name, 'primitives': [{'attributes': attrs, 'indices': ia, 'material': 0}]}],
          'materials': [m], 'accessors': acc, 'bufferViews': views, 'buffers': [{'byteLength': len(buf)}]}
    if textures:
        gl['textures'] = textures; gl['images'] = gl_images
        gl['samplers'] = [{'magFilter': 9729, 'minFilter': 9987, 'wrapS': 33071, 'wrapT': 33071}]  # clamp: one atlas, no tiling
    if extras: gl['asset']['extras'] = extras
    js = json.dumps(gl, separators=(',', ':')).encode(); js += b' ' * ((4 - len(js) % 4) % 4)
    with open(out, 'wb') as f:
        f.write(struct.pack('<III', 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(buf))); f.write(struct.pack('<II', len(js), 0x4E4F534A)); f.write(js)
        f.write(struct.pack('<II', len(buf), 0x004E4942)); f.write(bytes(buf))
    return os.path.getsize(out)


def read_glb(path):
    """minimal reader for checks: returns (json, bin)"""
    with open(path, 'rb') as f: d = f.read()
    mg, ver, L = struct.unpack('<III', d[:12]); assert mg == 0x46546C67 and ver == 2
    jl, jt = struct.unpack('<II', d[12:20]); js = json.loads(d[20:20 + jl]); o = 20 + jl
    bl, bt = struct.unpack('<II', d[o:o + 8]); return js, d[o + 8:o + 8 + bl]


def check_glb(path):
    """structural check a strict loader would do: offsets, alignment, accessor bounds, index range, image decode, unit normals/tangents"""
    from PIL import Image
    js, bn = read_glb(path); probs = []
    for i, v in enumerate(js['bufferViews']):
        if v['byteOffset'] % 4: probs.append(f'view {i} misaligned')
        if v['byteOffset'] + v['byteLength'] > len(bn): probs.append(f'view {i} past buffer')
    def arr(ai):
        a = js['accessors'][ai]; v = js['bufferViews'][a['bufferView']]; n = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[a['type']]
        dt = {5126: '<f4', 5125: '<u4', 5123: '<u2'}[a['componentType']]
        return np.frombuffer(bn, dt, a['count'] * n, v['byteOffset'] + a.get('byteOffset', 0)).reshape(a['count'], n)
    pr = js['meshes'][0]['primitives'][0]; P = arr(pr['attributes']['POSITION']); I = arr(pr['indices'])
    if I.max() >= len(P): probs.append('index out of range')
    if not np.isfinite(P).all(): probs.append('non-finite positions')
    N = arr(pr['attributes']['NORMAL']); ln = np.linalg.norm(N, axis=1)
    if abs(ln - 1).max() > 1e-3: probs.append(f'normals not unit ({abs(ln - 1).max():.4f})')
    if 'TANGENT' in pr['attributes']:
        T = arr(pr['attributes']['TANGENT']); lt = np.linalg.norm(T[:, :3], axis=1)
        if abs(lt - 1).max() > 1e-3: probs.append('tangents not unit')
        if not np.isin(T[:, 3], (-1, 1)).all(): probs.append('tangent w not +-1')
    U = arr(pr['attributes']['TEXCOORD_0'])
    if U.min() < -1e-4 or U.max() > 1 + 1e-4: probs.append('uv0 outside 0..1')
    sizes = []
    for im in js.get('images', []):
        v = js['bufferViews'][im['bufferView']]; data = bn[v['byteOffset']:v['byteOffset'] + v['byteLength']]
        try: x = Image.open(io.BytesIO(data)); x.load(); sizes.append((im['name'], im['mimeType'], x.size, round(len(data) / 1e6, 1)))
        except Exception as e: probs.append(f'image {im["name"]} does not decode: {e}')
    ext = P.max(0) - P.min(0)
    return dict(tris=len(I) // 3, verts=len(P), ext=[round(float(x), 3) for x in ext], images=sizes, problems=probs, mb=round(os.path.getsize(path) / 1e6, 1))
