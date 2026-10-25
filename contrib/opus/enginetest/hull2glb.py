# A2 engine test: turn a game hull (hulls_hi/CODE.json plus CODE_m.webp and CODE_n.webp) into a standard glTF binary that Babylon and
# Godot both load the same way. Base colour, metal and roughness come from the faction values the game uses (ships3d.js FAC3D and the
# aiHullMat table); the normal map and the AO (red channel of _m) use the baked atlas UVs (TEXCOORD_1). Frame kept as the game's:
# x toward the bow, y up, z to port, length about 1. Textures are written as PNG (core glTF; WebP needs an extension Godot may not take).
# usage: python3 hull2glb.py CODE faction out.glb
import sys, json, base64, struct, io, os, numpy as np
from PIL import Image
code, fac, out = sys.argv[1], sys.argv[2], sys.argv[3]
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
j = json.load(open(os.path.join(ROOT, 'hulls_hi', code + '.json')))
b = lambda s, t: np.frombuffer(base64.b64decode(s), t)
qp = b(j['p'], np.int16).reshape(-1, 3).astype(np.float32); ext = np.array(j['ext'], np.float32)
pos = qp / 32767 * ext; nor = b(j['q'], np.int8).reshape(-1, 3).astype(np.float32) / 127
nor /= np.maximum(np.linalg.norm(nor, axis=1, keepdims=True), 1e-6)
idx = b(j['i'], np.uint32 if j.get('i32') else np.uint16).astype(np.uint32)
uv2 = b(j['u'], np.uint16).reshape(-1, 2).astype(np.float32) / 65535
uv2[:, 1] = 1 - uv2[:, 1]  # the game reads these with Babylon's default invertY (Blender v-up); glTF wants v-down
n = len(pos)
# box-projected UVs, as the game makes them (decodeAIHull), so any tiled detail lands the same in both engines
ax = np.abs(nor); uv0 = np.zeros((n, 2), np.float32); k = 3.2
m1 = (ax[:, 1] >= ax[:, 0]) & (ax[:, 1] >= ax[:, 2]); m2 = ~m1 & (ax[:, 0] >= ax[:, 2]); m3 = ~m1 & ~m2
uv0[m1] = pos[m1][:, [0, 2]] * k; uv0[m2] = pos[m2][:, [2, 1]] * k; uv0[m3] = pos[m3][:, [0, 1]] * k
HULL = dict(voidsworn='#4a4440', hegemony='#c4ccd5', corsair='#6a2c22', chorus='#57364c', ithar='#e4ebe7', deathless='#2c3431')
MET = dict(voidsworn=.3, hegemony=.4, corsair=.35, chorus=.05, ithar=.25, deathless=.55)
RGH = dict(voidsworn=.55, hegemony=.48, corsair=.62, chorus=.38, ithar=.42, deathless=.5)
def lin(c): c = c / 255.; return float(c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4)
h = HULL[fac]; base = [lin(int(h[i:i + 2], 16)) for i in (1, 3, 5)] + [1.0]
def png(path):
    bio = io.BytesIO(); Image.open(path).convert('RGB').save(bio, 'PNG', optimize=False, compress_level=6); return bio.getvalue()
imgs = [png(os.path.join(ROOT, 'hulls_hi', code + '_n.webp')), png(os.path.join(ROOT, 'hulls_hi', code + '_m.webp'))]
blobs = [pos.astype('<f4').tobytes(), nor.astype('<f4').tobytes(), uv0.astype('<f4').tobytes(), uv2.astype('<f4').tobytes(), idx.astype('<u4').tobytes()] + imgs
views, buf, off = [], b'', 0
for i, bl in enumerate(blobs):
    pad = (4 - len(buf) % 4) % 4; buf += b'\0' * pad; off = len(buf)
    v = {'buffer': 0, 'byteOffset': off, 'byteLength': len(bl)}
    if i < 4: v['target'] = 34962
    elif i == 4: v['target'] = 34963
    views.append(v); buf += bl
acc = [
    {'bufferView': 0, 'componentType': 5126, 'count': n, 'type': 'VEC3', 'min': pos.min(0).tolist(), 'max': pos.max(0).tolist()},
    {'bufferView': 1, 'componentType': 5126, 'count': n, 'type': 'VEC3'},
    {'bufferView': 2, 'componentType': 5126, 'count': n, 'type': 'VEC2'},
    {'bufferView': 3, 'componentType': 5126, 'count': n, 'type': 'VEC2'},
    {'bufferView': 4, 'componentType': 5125, 'count': len(idx), 'type': 'SCALAR'}]
gl = {'asset': {'version': '2.0', 'generator': 'voidsworn hull2glb'}, 'scene': 0, 'scenes': [{'nodes': [0]}],
      'nodes': [{'name': code, 'mesh': 0}],
      'meshes': [{'name': code, 'primitives': [{'attributes': {'POSITION': 0, 'NORMAL': 1, 'TEXCOORD_0': 2, 'TEXCOORD_1': 3}, 'indices': 4, 'material': 0}]}],
      'materials': [{'name': f'{fac}_{code}', 'pbrMetallicRoughness': {'baseColorFactor': base, 'metallicFactor': MET[fac], 'roughnessFactor': RGH[fac]},
                     'normalTexture': {'index': 0, 'texCoord': 1}, 'occlusionTexture': {'index': 1, 'texCoord': 1, 'strength': .9}}],
      'textures': [{'source': 0, 'sampler': 0}, {'source': 1, 'sampler': 0}], 'samplers': [{'magFilter': 9729, 'minFilter': 9987, 'wrapS': 10497, 'wrapT': 10497}],
      'images': [{'bufferView': 5, 'mimeType': 'image/png'}, {'bufferView': 6, 'mimeType': 'image/png'}],
      'accessors': acc, 'bufferViews': views, 'buffers': [{'byteLength': len(buf)}]}
js = json.dumps(gl, separators=(',', ':')).encode(); js += b' ' * ((4 - len(js) % 4) % 4); buf += b'\0' * ((4 - len(buf) % 4) % 4)
with open(out, 'wb') as f:
    f.write(struct.pack('<III', 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(buf))); f.write(struct.pack('<II', len(js), 0x4E4F534A)); f.write(js)
    f.write(struct.pack('<II', len(buf), 0x004E4942)); f.write(buf)
print(code, fac, 'verts', n, 'tris', len(idx) // 3, 'MB', round(os.path.getsize(out) / 1e6, 1))
