# A4 glTF writer: several meshes, several materials, named empty nodes (hard points) with extras, images embedded or external (shared
# between the ship and its wreck file). Core glTF 2.0 plus KHR_materials_emissive_strength. No Blender needed.
import io, os, json, struct, math
import numpy as np


class GLB:
    def __init__(self, generator='voidsworn a4'):
        self.blobs = []; self.views = []; self.acc = []; self.meshes = []; self.nodes = []; self.mats = []; self.imgs = []; self.tex = []
        self.gen = generator; self.ext_used = set()

    def _view(self, data, target=None):
        self.blobs.append(data); v = {'buffer': 0, 'byteLength': len(data)}
        if target: v['target'] = target
        self.views.append(v); return len(self.views) - 1

    def accessor(self, arr, kind):
        """kind: 'pos' 'vec3' 'vec2' 'vec4' 'idx'"""
        if kind == 'idx':
            a = np.ascontiguousarray(np.asarray(arr).reshape(-1), '<u4'); v = self._view(a.tobytes(), 34963)
            self.acc.append({'bufferView': v, 'componentType': 5125, 'count': len(a), 'type': 'SCALAR'}); return len(self.acc) - 1
        a = np.ascontiguousarray(arr, '<f4'); t = {'pos': 'VEC3', 'vec3': 'VEC3', 'vec2': 'VEC2', 'vec4': 'VEC4'}[kind]
        v = self._view(a.tobytes(), 34962); d = {'bufferView': v, 'componentType': 5126, 'count': len(a), 'type': t}
        if kind == 'pos': d['min'] = a.min(0).tolist(); d['max'] = a.max(0).tolist()
        self.acc.append(d); return len(self.acc) - 1

    def image(self, uri=None, data=None, mime=None, name=None):
        im = {'name': name or (uri or 'img')}
        if uri:  # mimeType too: Godot's loader tries PNG first for a URI without one (and logs an error per JPEG)
            im['uri'] = uri; im['mimeType'] = 'image/png' if uri.lower().endswith('.png') else 'image/jpeg'
        else: im['bufferView'] = self._view(data); im['mimeType'] = mime
        self.imgs.append(im); self.tex.append({'source': len(self.imgs) - 1, 'sampler': 0}); return len(self.tex) - 1

    def material(self, m):
        self.mats.append(m); return len(self.mats) - 1

    def qaccessor(self, arr, kind):
        """KHR_mesh_quantization: positions as normalized int16 (the ship fits in -1..1), normals as normalized int8, uvs as normalized
        uint16; vertex data padded to 4-byte strides as the spec asks. Half the bytes of float32 for the same look."""
        self.ext_used.add('KHR_mesh_quantization'); self.ext_req = getattr(self, 'ext_req', set()); self.ext_req.add('KHR_mesh_quantization')
        a = np.asarray(arr, np.float64)
        if kind == 'pos':
            q = np.round(np.clip(a, -1, 1) * 32767).astype('<i2'); q = np.concatenate([q, np.zeros((len(q), 1), '<i2')], 1); ct, stride, n = 5122, 8, 3
            d = {'min': (q[:, :3].min(0) / 32767.).tolist(), 'max': (q[:, :3].max(0) / 32767.).tolist()}
        elif kind == 'nor':
            q = np.round(np.clip(a, -1, 1) * 127).astype('<i1'); q = np.concatenate([q, np.zeros((len(q), 1), '<i1')], 1); ct, stride, n, d = 5120, 4, 3, {}
        else:
            q = np.round(np.clip(a, 0, 1) * 65535).astype('<u2'); ct, stride, n, d = 5123, 4, 2, {}
        v = self._view(np.ascontiguousarray(q).tobytes(), 34962); self.views[v]['byteStride'] = stride
        self.acc.append(dict({'bufferView': v, 'componentType': ct, 'normalized': True, 'count': len(q), 'type': 'VEC%d' % n}, **d)); return len(self.acc) - 1

    def mesh(self, name, prims, quant=False):
        """prims: list of dict(pos, nor, idx, uv=None, tan=None, mat); quant=True writes KHR_mesh_quantization attributes"""
        out = []
        for p in prims:
            if quant:
                at = {'POSITION': self.qaccessor(p['pos'], 'pos'), 'NORMAL': self.qaccessor(p['nor'], 'nor')}
                if p.get('uv') is not None: at['TEXCOORD_0'] = self.qaccessor(p['uv'], 'uv')
                out.append({'attributes': at, 'indices': self.accessor(p['idx'], 'idx'), 'material': p['mat']}); continue
            at = {'POSITION': self.accessor(p['pos'], 'pos'), 'NORMAL': self.accessor(p['nor'], 'vec3')}
            if p.get('uv') is not None: at['TEXCOORD_0'] = self.accessor(p['uv'], 'vec2')
            if p.get('tan') is not None: at['TANGENT'] = self.accessor(p['tan'], 'vec4')
            out.append({'attributes': at, 'indices': self.accessor(p['idx'], 'idx'), 'material': p['mat']})
        self.meshes.append({'name': name, 'primitives': out}); return len(self.meshes) - 1

    def node(self, d):
        self.nodes.append(d); return len(self.nodes) - 1

    def save(self, path, roots, extras=None):
        buf = bytearray()
        for v, bl in zip(self.views, self.blobs):
            buf += b'\0' * ((4 - len(buf) % 4) % 4); v['byteOffset'] = len(buf); buf += bl
        buf += b'\0' * ((4 - len(buf) % 4) % 4)
        gl = {'asset': {'version': '2.0', 'generator': self.gen}, 'scene': 0, 'scenes': [{'nodes': roots}], 'nodes': self.nodes,
              'meshes': self.meshes, 'materials': self.mats, 'accessors': self.acc, 'bufferViews': self.views, 'buffers': [{'byteLength': len(buf)}]}
        if self.tex:
            gl['textures'] = self.tex; gl['images'] = self.imgs
            gl['samplers'] = [{'magFilter': 9729, 'minFilter': 9987, 'wrapS': 33071, 'wrapT': 33071}]
        if any('extensions' in m and 'KHR_materials_emissive_strength' in m['extensions'] for m in self.mats): self.ext_used.add('KHR_materials_emissive_strength')
        if self.ext_used: gl['extensionsUsed'] = sorted(self.ext_used)
        if getattr(self, 'ext_req', None): gl['extensionsRequired'] = sorted(self.ext_req)
        if extras: gl['asset']['extras'] = extras
        js = json.dumps(gl, separators=(',', ':')).encode(); js += b' ' * ((4 - len(js) % 4) % 4)
        with open(path, 'wb') as f:
            f.write(struct.pack('<III', 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(buf))); f.write(struct.pack('<II', len(js), 0x4E4F534A)); f.write(js)
            f.write(struct.pack('<II', len(buf), 0x004E4942)); f.write(bytes(buf))
        return os.path.getsize(path)


def basis_quat(fwd, up):
    """glTF rotation (x, y, z, w) whose local -Z is fwd and local +Y is up (both in the glTF frame); Godot's forward is -Z"""
    f = np.asarray(fwd, float); f /= max(np.linalg.norm(f), 1e-9); z = -f
    u = np.asarray(up, float); u = u - z * u.dot(z)
    if np.linalg.norm(u) < 1e-6:
        u = np.array([0., 1, 0]) - z * z[1]
        if np.linalg.norm(u) < 1e-6: u = np.array([1., 0, 0]) - z * z[0]
    y = u / np.linalg.norm(u); x = np.cross(y, z); M = np.stack([x, y, z], 1)
    t = M[0, 0] + M[1, 1] + M[2, 2]
    if t > 0:
        s = math.sqrt(t + 1) * 2; w = .25 * s; qx = (M[2, 1] - M[1, 2]) / s; qy = (M[0, 2] - M[2, 0]) / s; qz = (M[1, 0] - M[0, 1]) / s
    elif M[0, 0] > M[1, 1] and M[0, 0] > M[2, 2]:
        s = math.sqrt(1 + M[0, 0] - M[1, 1] - M[2, 2]) * 2; w = (M[2, 1] - M[1, 2]) / s; qx = .25 * s; qy = (M[0, 1] + M[1, 0]) / s; qz = (M[0, 2] + M[2, 0]) / s
    elif M[1, 1] > M[2, 2]:
        s = math.sqrt(1 + M[1, 1] - M[0, 0] - M[2, 2]) * 2; w = (M[0, 2] - M[2, 0]) / s; qx = (M[0, 1] + M[1, 0]) / s; qy = .25 * s; qz = (M[1, 2] + M[2, 1]) / s
    else:
        s = math.sqrt(1 + M[2, 2] - M[0, 0] - M[1, 1]) * 2; w = (M[1, 0] - M[0, 1]) / s; qx = (M[0, 2] + M[2, 0]) / s; qy = (M[1, 2] + M[2, 1]) / s; qz = .25 * s
    q = np.array([qx, qy, qz, w]); return (q / np.linalg.norm(q)).tolist()


def img_bytes(img, kind, quality=90, size=None):
    from PIL import Image
    if not isinstance(img, Image.Image): img = Image.open(img)
    img = img.convert('RGB')
    if size and img.size[0] != size: img = img.resize((size, size), Image.LANCZOS)
    bio = io.BytesIO()
    if kind == 'png': img.save(bio, 'PNG', compress_level=7)
    else: img.save(bio, 'JPEG', quality=quality, subsampling=0)
    return bio.getvalue()


def read_glb(path):
    with open(path, 'rb') as f: d = f.read()
    mg, ver, L = struct.unpack('<III', d[:12]); assert mg == 0x46546C67 and ver == 2
    jl, jt = struct.unpack('<II', d[12:20]); js = json.loads(d[20:20 + jl]); o = 20 + jl
    bl, bt = struct.unpack('<II', d[o:o + 8]); return js, d[o + 8:o + 8 + bl]


def check(path):
    """what a strict loader checks: alignment, bounds, index range, finite data, unit normals and tangents, uv range, external images
    present, hard point names unique; plus the A4 frame check (port hard points at z < 0)"""
    js, bn = read_glb(path); probs = []; base = os.path.dirname(path)
    for i, v in enumerate(js['bufferViews']):
        if v['byteOffset'] % 4: probs.append(f'view {i} misaligned')
        if v['byteOffset'] + v['byteLength'] > len(bn): probs.append(f'view {i} past buffer')
    def arr(ai):
        a = js['accessors'][ai]; v = js['bufferViews'][a['bufferView']]; n = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[a['type']]
        dt = {5126: '<f4', 5125: '<u4', 5122: '<i2', 5120: '<i1', 5123: '<u2'}[a['componentType']]; sz = np.dtype(dt).itemsize
        st = v.get('byteStride', sz * n) // sz; raw = np.frombuffer(bn, dt, a['count'] * st, v['byteOffset'] + a.get('byteOffset', 0)).reshape(a['count'], st)[:, :n]
        if a.get('normalized'): raw = np.maximum(raw.astype(np.float64) / {5122: 32767., 5120: 127., 5123: 65535.}[a['componentType']], -1)
        return raw
    tris = 0; lo = np.full(3, 1e9); hi = -lo
    for m in js['meshes']:
        for pr in m['primitives']:
            P = arr(pr['attributes']['POSITION']); I = arr(pr['indices']); tris += len(I) // 3
            lo = np.minimum(lo, P.min(0)); hi = np.maximum(hi, P.max(0))
            if I.max() >= len(P): probs.append(f'{m["name"]}: index out of range')
            if not np.isfinite(P).all(): probs.append(f'{m["name"]}: non-finite positions')
            N = arr(pr['attributes']['NORMAL']); tol = .02 if js['accessors'][pr['attributes']['NORMAL']].get('normalized') else 2e-3
            if abs(np.linalg.norm(N, axis=1) - 1).max() > tol: probs.append(f'{m["name"]}: normals not unit')
            if 'TANGENT' in pr['attributes']:
                T = arr(pr['attributes']['TANGENT'])
                if abs(np.linalg.norm(T[:, :3], axis=1) - 1).max() > 2e-3 or not np.isin(T[:, 3], (-1, 1)).all(): probs.append(f'{m["name"]}: bad tangents')
            if 'TEXCOORD_0' in pr['attributes']:
                U = arr(pr['attributes']['TEXCOORD_0'])
                if U.min() < -1e-4 or U.max() > 1 + 1e-4: probs.append(f'{m["name"]}: uv outside 0..1')
    for im in js.get('images', []):
        if 'uri' in im and not os.path.exists(os.path.join(base, im['uri'])): probs.append(f'missing image {im["uri"]}')
    names = [n.get('name', '') for n in js['nodes']]; hp = [n for n in js['nodes'] if n.get('name', '').startswith('hp_')]
    if len(set(names)) != len(names): probs.append('duplicate node names')
    for n in hp:
        e = n.get('extras', {}); t = n.get('translation', [0, 0, 0])
        if e.get('arc') == 'P' and t[2] > 1e-4: probs.append(f'{n["name"]} is a port mount on the starboard side')
        if e.get('arc') == 'S' and t[2] < -1e-4: probs.append(f'{n["name"]} is a starboard mount on the port side')
    return dict(tris=tris, ext=[round(float(x), 3) for x in hi - lo], hardpoints=len(hp), problems=probs, mb=round(os.path.getsize(path) / 1e6, 2))
