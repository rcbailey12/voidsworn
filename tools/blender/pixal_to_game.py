# Pixal3D textured GLB (ComfyUI SaveGLB) -> game hull: positions/normals/UVs in the game frame (bow +x, up +y, port +z, length 1,
# centred), raw little-endian arrays for vsm_pack.mjs (meshopt compression) + paint / normal / AO maps as webp.
# usage: python3 pixal_to_game.py in.glb out_dir CODE FRONT [TEXRES]
#   FRONT = which view the Pixal run posed as its front: 'front' (front view connected first) or 'left' (side view first).
import sys, os, json, struct, io, base64, numpy as np
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
lo, hi = G.min(0), G.max(0)
if os.environ.get('KIT'):  # the ship's size is hull + hand-built parts: a rebuilt bow is part of the length, or cutting the AI bow would stretch the ship
    _b = open(os.environ['KIT'], 'rb').read(); _L = struct.unpack('<I', _b[12:16])[0]; _J = json.loads(_b[20:20 + _L]); _o = 20 + _L; _BIN = _b[_o + 8:_o + 8 + struct.unpack('<I', _b[_o:_o + 4])[0]]
    for _m in _J['meshes']:
        for _p in _m['primitives']:
            _a = _J['accessors'][_p['attributes']['POSITION']]; _bv = _J['bufferViews'][_a['bufferView']]
            _P = np.frombuffer(_BIN, np.float32, _a['count'] * 3, _bv.get('byteOffset', 0) + _a.get('byteOffset', 0)).reshape(-1, 3).astype(np.float64) @ M.T
            lo, hi = np.minimum(lo, _P.min(0)), np.maximum(hi, _P.max(0))
G = (G - (lo + hi) / 2) / (hi[0] - lo[0]); ext = np.abs(G).max(0)
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
_ai = alb.convert('RGB'); _ai = _ai.resize((res, res), Image.LANCZOS) if _ai.width != res else _ai
PAINT = {f'{code}_a.webp': np.asarray(_ai).astype(np.float64) / 255}  # paint maps, levelled together and written once at the end
if nrm is not None:
    a = np.asarray(nrm.convert('RGB')).copy()  # no change for the mirror: the shader rebuilds the tangent frame from the mirrored geometry and its UVs
    if os.environ.get('FLIPG'): a[..., 1] = 255 - a[..., 1]
    save(Image.fromarray(a), 'n')
if occ is not None:
    o = np.asarray(occ.convert('RGB'))[..., 0]; m = np.dstack([o, np.full_like(o, 128), np.full_like(o, 255)]); save(Image.fromarray(m), 'm')
kit = None
if os.environ.get('KIT'):  # hand-built parts in the same GLB frame: same axis change and the same centring/scale as the hull
    kb = open(os.environ['KIT'], 'rb').read(); kL = struct.unpack('<I', kb[12:16])[0]; KJ = json.loads(kb[20:20 + kL]); ko = 20 + kL; KBIN = kb[ko + 8:ko + 8 + struct.unpack('<I', kb[ko:ko + 4])[0]]
    def kacc(i):
        a = KJ['accessors'][i]; bv = KJ['bufferViews'][a['bufferView']]; o = bv.get('byteOffset', 0) + a.get('byteOffset', 0)
        v = np.frombuffer(KBIN, CT[a['componentType']], a['count'] * NC[a['type']], o).reshape(a['count'], NC[a['type']]).astype(np.float64)
        if a.get('normalized'): v = v / {5121: 255., 5123: 65535.}[a['componentType']]
        return v
    KP, KN, KC, KI, KU = [], [], [], [], []; base = 0
    for mesh in KJ['meshes']:
        for kp in mesh['primitives']:
            ka = kp['attributes']; p_ = kacc(ka['POSITION']); n_ = kacc(ka['NORMAL']); c_ = kacc(ka['COLOR_0'])[:, :3] if 'COLOR_0' in ka else np.full((len(p_), 3), .2)
            u_ = kacc(ka['TEXCOORD_0']) if 'TEXCOORD_0' in ka else None; KU.append(u_)
            i_ = kacc(kp['indices']).reshape(-1, 3).astype(np.int64) + base; base += len(p_); KP.append(p_); KN.append(n_); KC.append(c_); KI.append(i_)
    KP0 = np.concatenate(KP); KN0 = np.concatenate(KN); KI = np.concatenate(KI)
    fn = np.cross(KP0[KI[:, 1]] - KP0[KI[:, 0]], KP0[KI[:, 2]] - KP0[KI[:, 0]]); bad = (fn * KN0[KI].sum(1)).sum(1) < 0  # winding that disagrees with the normals (two-sided in Blender, black in game)
    KI[bad] = KI[bad][:, [0, 2, 1]]; print('kit winding fixed', int(bad.sum()), 'of', len(KI))
    KP = KP0 @ M.T; KN = KN0 @ M.T; KC = np.concatenate(KC)
    KU = np.concatenate(KU) if all(u is not None for u in KU) else None
    if np.linalg.det(M) < 0: KI = KI[:, [0, 2, 1]]
    KP = (KP - (lo + hi) / 2) / (hi[0] - lo[0]); KN /= np.maximum(np.linalg.norm(KN, axis=1, keepdims=True), 1e-9)
    kit = {'n': len(KP), 't': len(KI), 'p': base64.b64encode(KP.astype(np.float32).tobytes()).decode(), 'q': base64.b64encode(np.round(KN * 127).astype(np.int8).tobytes()).decode(),
           'c': base64.b64encode(np.round(np.clip(KC, 0, 1) * 255).astype(np.uint8).tobytes()).decode(), 'i': base64.b64encode(KI.astype(np.uint32).tobytes()).decode()}
    if KU is not None:  # painted parts: UVs + their texture
        KU[:, 1] = 1 - KU[:, 1]; kit['u'] = base64.b64encode(np.round(np.clip(KU, 0, 1) * 65535).astype(np.uint16).tobytes()).decode()
        km = KJ['materials'][KJ['meshes'][0]['primitives'][0].get('material', 0)]; bt = km.get('pbrMetallicRoughness', {}).get('baseColorTexture')
        if bt is not None:
            bv = KJ['bufferViews'][KJ['images'][KJ['textures'][bt['index']]['source']]['bufferView']]; kimg = Image.open(io.BytesIO(KBIN[bv.get('byteOffset', 0):bv.get('byteOffset', 0) + bv['byteLength']])).convert('RGB')
            if texres and kimg.width > texres: kimg = kimg.resize((texres, texres), Image.LANCZOS)  # phone set: the kit atlas at the phone's map size
            PAINT[code + '_kit_a.webp'] = np.asarray(kimg).astype(np.float64) / 255; kit['tex'] = 1
    json.dump(kit, open(os.path.join(outd, code + '_kit.json'), 'w')); print('kit verts', len(KP), 'tris', len(KI), 'painted', 'tex' in kit)
# one brightness transform for hull and kit together (audits, Oct 22): solved over both maps' painted texels, applied to both, saved once
if os.environ.get('CONCEPT') and os.path.exists(os.environ['CONCEPT']):
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import paint_level
    g_ = paint_level.solve(list(PAINT.values()), os.environ['CONCEPT']); print('joint paint gain %.3f' % g_)
    for k_ in PAINT: m_ = PAINT[k_].sum(2) > 6 / 255; b_ = PAINT[k_][m_].mean(); PAINT[k_] = paint_level.apply(PAINT[k_], g_); print('  %s mean %.3f -> %.3f' % (k_, b_, PAINT[k_][m_].mean()))
for k_, a_ in PAINT.items(): Image.fromarray((np.clip(a_, 0, 1) * 255 + .5).astype(np.uint8)).save(os.path.join(outd, k_), quality=90, method=6)
hdr = {'v': 1, 'kit': kit is not None, 'fmt': 'vsm1', 'ext': ext.tolist(), 'n': int(n), 't': int(len(I)), 'src': 'pixal3d', 'front': front, 'alb': {'res': res}, 'tex': {'res': min(res, 2048)} if nrm is not None else None,
       'mr': [pbr.get('metallicFactor', 1), pbr.get('roughnessFactor', 1)]}
json.dump(hdr, open(os.path.join(outd, code + '.hdr.json'), 'w'))
print(code, 'verts', n, 'tris', len(I), 'ext', ext.round(3).tolist(), 'maps', [x is not None for x in (alb, nrm, occ, mr)])
