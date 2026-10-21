# Pixal3D textured GLB (ComfyUI SaveGLB) -> game hull: positions/normals/UVs in the game frame (bow +x, up +y, port +z, length 1,
# centred), raw little-endian arrays for vsm_pack.mjs (meshopt compression) + paint / normal / AO maps as webp.
# usage: python3 pixal_to_game.py in.glb out_dir CODE FRONT [TEXRES]
#   FRONT = which view the Pixal run posed as its front: 'front' (front view connected first) or 'left' (side view first).
import sys, os, json, struct, io, numpy as np
from PIL import Image
src, outd, code, front = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]; texres = int(sys.argv[5]) if len(sys.argv) > 5 else 0
os.makedirs(outd, exist_ok=True)
b = open(src, 'rb').read(); L = struct.unpack('<I', b[12:16])[0]; J = json.loads(b[20:20 + L]); off = 20 + L; BL = struct.unpack('<I', b[off:off + 4])[0]; BIN = b[off + 8:off + 8 + BL]
CT = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}; NC = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}
def acc(i):
    a = J['accessors'][i]; bv = J['bufferViews'][a['bufferView']]; o = bv.get('byteOffset', 0) + a.get('byteOffset', 0)
    return np.frombuffer(BIN, CT[a['componentType']], a['count'] * NC[a['type']], o).reshape(a['count'], NC[a['type']])
pr = J['meshes'][0]['primitives'][0]; at = pr['attributes']
P = acc(at['POSITION']).astype(np.float64); N = acc(at['NORMAL']).astype(np.float64); U = acc(at['TEXCOORD_0']).astype(np.float64); I = acc(pr['indices']).reshape(-1, 3).astype(np.uint32)
# Pixal frame (z up) arrives in glTF y-up as g = (x, z, -y). Game: bow +x, up +y, port +z (Babylon is left-handed, so this is a mirror: flip winding).
if front == 'front':   # bow faced the front camera (-y Pixal = +gz), port toward the left camera (+x Pixal = +gx)
    M = np.array([[0, 0, 1], [0, 1, 0], [1, 0, 0]], float)
else:                  # 'left': the side view was posed as the front; bow on screen left (-x Pixal = -gx), port toward that camera (+gz)
    M = np.array([[-1, 0, 0], [0, 1, 0], [0, 0, 1]], float)
G = P @ M.T; GN = N @ M.T
if np.linalg.det(M) < 0: I = I[:, [0, 2, 1]]
lo, hi = G.min(0), G.max(0); G = (G - (lo + hi) / 2) / (hi[0] - lo[0]); ext = np.abs(G).max(0)
GN /= np.maximum(np.linalg.norm(GN, axis=1, keepdims=True), 1e-9)
U[:, 1] = 1 - U[:, 1]  # glTF v runs down; the game's textures load with Babylon's default invertY (Blender-style v up)
n = len(G); qp = np.round(G / ext * 32767).astype(np.int16); qn = np.round(GN * 127).astype(np.int8); qu = np.round(np.clip(U, 0, 1) * 65535).astype(np.uint16)
V = np.zeros((n, 16), np.uint8); V[:, 0:6] = qp.view(np.uint8).reshape(n, 6); V[:, 8:11] = qn.view(np.uint8).reshape(n, 3); V[:, 12:16] = qu.view(np.uint8).reshape(n, 4)
V.tofile(os.path.join(outd, code + '.vb')); I.astype(np.uint32).tofile(os.path.join(outd, code + '.ib'))
# maps: base colour, normal, occlusion from the glTF material
mat = J['materials'][pr.get('material', 0)]; pbr = mat.get('pbrMetallicRoughness', {})
def img(tex):
    if tex is None: return None
    s = J['textures'][tex['index']]['source']; bv = J['bufferViews'][J['images'][s]['bufferView']]; o = bv.get('byteOffset', 0)
    return Image.open(io.BytesIO(BIN[o:o + bv['byteLength']]))
alb = Image.open(os.environ['ALB']) if os.environ.get('ALB') else img(pbr.get('baseColorTexture')); nrm = img(mat.get('normalTexture')); occ = img(mat.get('occlusionTexture')); mr = img(pbr.get('metallicRoughnessTexture'))
res = texres or alb.width
def save(im, name, mode='RGB'):
    if im is None: return False
    im = im.convert(mode)
    if im.width != res: im = im.resize((res, res), Image.LANCZOS)
    im.save(os.path.join(outd, f'{code}_{name}.webp'), quality=90, method=6); return True
save(alb, 'a')
if os.environ.get('CONCEPT') and os.path.exists(os.environ['CONCEPT']):  # lift the paint to 0.8x the concept art's brightness (the bakes come out dark)
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import paint_level; print('paint level', paint_level.level(os.path.join(outd, f'{code}_a.webp'), os.environ['CONCEPT']))
if nrm is not None:
    a = np.asarray(nrm.convert('RGB')).copy()  # no change for the mirror: the shader rebuilds the tangent frame from the mirrored geometry and its UVs
    if os.environ.get('FLIPG'): a[..., 1] = 255 - a[..., 1]
    save(Image.fromarray(a), 'n')
if occ is not None:
    o = np.asarray(occ.convert('RGB'))[..., 0]; m = np.dstack([o, np.full_like(o, 128), np.full_like(o, 255)]); save(Image.fromarray(m), 'm')
hdr = {'v': 1, 'fmt': 'vsm1', 'ext': ext.tolist(), 'n': int(n), 't': int(len(I)), 'src': 'pixal3d', 'front': front, 'alb': {'res': res}, 'tex': {'res': min(res, 2048)} if nrm is not None else None,
       'mr': [pbr.get('metallicFactor', 1), pbr.get('roughnessFactor', 1)]}
json.dump(hdr, open(os.path.join(outd, code + '.hdr.json'), 'w'))
print(code, 'verts', n, 'tris', len(I), 'ext', ext.round(3).tolist(), 'maps', [x is not None for x in (alb, nrm, occ, mr)])
