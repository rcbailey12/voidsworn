# A2 engine test, shared environment assets (SPEC.md "Environment"), written to enginetest/assets/env/:
#   sky_deadstar_8k.png   8192 x 4096 equirectangular sky: the starfield recipe of make_starfield.py at 8K, faint nebula clouds, and a dim
#                         dark-red dead star with a thin corona centred where the key light comes from
#   rocks/RCAnn.glb       the game's carbon rocks (rocks_hi/RCA*) as glTF: grey-brown rough rock, normal map plus AO (TEXCOORD_1 atlas)
#   asteroids.json        seed 7: about 200 field rocks (1 to 15 units, below and behind the formation) plus 6 large rocks near it
# Sky mapping (Babylon README "Sky mapping", Godot's panorama): u = atan2(x, -z) / 2 pi wrapped to 0..1, v = acos(y) / pi, v = 0 top row.
# usage: python3 make_env.py OUT_DIR [--sky] [--rocks] [--field]   (no flags: all three)
import sys, os, io, json, math, base64, struct
import numpy as np
from PIL import Image, ImageFilter
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
KEY_TO_SCENE = np.array([-0.45, -0.70, -0.55]); SUN = -KEY_TO_SCENE / np.linalg.norm(KEY_TO_SCENE)  # where the light comes from


def dir_of(u, v):
    """inverse of the panorama mapping: pixel (u, v in 0..1) to a unit direction"""
    th = v * np.pi; ph = u * 2 * np.pi
    s = np.sin(th); return np.stack([s * np.sin(ph), np.cos(th), -s * np.cos(ph)], -1)


def uv_of(d):
    d = d / np.linalg.norm(d); u = (math.atan2(d[0], -d[2]) / (2 * math.pi)) % 1.0; v = math.acos(max(-1, min(1, d[1]))) / math.pi; return u, v


def vnoise3(p, seed):
    """value noise on 3D points (smooth), p: (..., 3)"""
    i = np.floor(p).astype(np.int64); f = p - i; f = f * f * (3 - 2 * f)
    def h(a, b, c):
        n = (a * 73856093) ^ (b * 19349663) ^ (c * 83492791) ^ (seed * 2654435761)
        n = (n ^ (n >> 13)) * 1274126177; return ((n ^ (n >> 16)) & 0xffff) / 65535.0
    x, y, z = i[..., 0], i[..., 1], i[..., 2]; fx, fy, fz = f[..., 0], f[..., 1], f[..., 2]
    def lerp(a, b, t): return a + (b - a) * t
    c00 = lerp(h(x, y, z), h(x + 1, y, z), fx); c10 = lerp(h(x, y + 1, z), h(x + 1, y + 1, z), fx)
    c01 = lerp(h(x, y, z + 1), h(x + 1, y, z + 1), fx); c11 = lerp(h(x, y + 1, z + 1), h(x + 1, y + 1, z + 1), fx)
    return lerp(lerp(c00, c10, fy), lerp(c01, c11, fy), fz)


def fbm(p, seed, oct=6):
    a, s, tot = 1.0, 1.0, 0.0; out = np.zeros(p.shape[:-1], np.float32)
    for k in range(oct): out += a * vnoise3(p * s, seed + k); tot += a; a *= .5; s *= 2.03
    return out / tot


def make_sky(out, W=8192):
    H = W // 2; rng = np.random.default_rng(7)
    # nebula at 2048 x 1024 (it is soft), lifted to 8K
    w2, h2 = 2048, 1024; vv, uu = np.mgrid[0:h2, 0:w2]; D = dir_of((uu + .5) / w2, (vv + .5) / h2).astype(np.float32)
    neb = np.zeros((h2, w2, 3), np.float32)
    for cx, cy, r, col in ((0.30, 0.42, 0.22, (0.10, 0.06, 0.16)), (0.68, 0.55, 0.18, (0.04, 0.07, 0.14)), (0.52, 0.35, 0.12, (0.12, 0.05, 0.05))):
        d = ((uu / w2 - cx) ** 2 * 4 + (vv / h2 - cy) ** 2) / r ** 2; neb += np.exp(-d)[..., None] * np.array(col, np.float32)  # the 4K starfield's blobs
    for sd, col, sc, k in ((3, (0.16, 0.07, 0.20), 2.2, 1.0), (11, (0.05, 0.10, 0.20), 3.1, .8), (19, (0.20, 0.06, 0.04), 2.6, .7)):  # wispy clouds
        n = fbm(D * sc, sd); n = np.clip((n - .48) / .30, 0, 1) ** 2.2
        wisp = fbm(D * sc * 4.0 + 7, sd + 50); neb += (n * (.55 + .9 * wisp) * k)[..., None] * np.array(col, np.float32) * .28  # faint: the ships must stay the brightest thing
    # darker dust lanes cut through the clouds
    lane = np.clip((fbm(D * 3.5 + 3, 77) - .5) / .12, 0, 1); neb *= (1 - .55 * lane)[..., None]
    # a faint red wash around the dead star, so it sits in its own glow
    cosd = (D @ SUN.astype(np.float32)); neb += (np.clip(cosd, 0, 1) ** 40 * .10)[..., None] * np.array((0.30, 0.06, 0.03), np.float32)
    img = np.stack([np.asarray(Image.fromarray(np.ascontiguousarray(neb[..., c])).resize((W, H), Image.BICUBIC), np.float32) for c in range(3)], -1)  # float resize: no banding in the darks
    img = np.clip(img, 0, None)
    del D, neb, uu, vv
    # stars at full size: the 4K recipe, four times as many, same band, a few with a soft glow
    n = 104000; sx = rng.integers(0, W, n); band = rng.normal(0.5, 0.18, n); sy = np.clip((band * H).astype(int), 0, H - 1)
    b = rng.power(6, n) * 0.9 + 0.08; tint = np.array([(1, .95, .9), (.85, .9, 1), (1, .85, .7), (1, 1, 1)], np.float32)[rng.integers(0, 4, n)]
    star = np.zeros((H, W, 3), np.float32); np.add.at(star, (sy, sx), b[:, None] * tint)
    big = b > .75; bx, by = sx[big], sy[big]
    for dx, dy, k in ((1, 0, .35), (-1, 0, .35), (0, 1, .35), (0, -1, .35), (1, 1, .12), (-1, -1, .12), (1, -1, .12), (-1, 1, .12)):
        np.add.at(star, (np.clip(by + dy, 0, H - 1), (bx + dx) % W), (b[big, None] * tint[big]) * k)
    img += star; del star
    # the dead star: a dim dark-red disc (limb darkened) with a thin bright corona and a faint halo; computed in a window around it
    u0, v0 = uv_of(SUN); R = math.radians(2.6)  # angular radius
    win = int(W * math.radians(14) / (2 * math.pi)); cx, cy = int(u0 * W), int(v0 * H)
    ys = np.arange(max(0, cy - win), min(H, cy + win)); xs = (np.arange(cx - win * 2, cx + win * 2)) % W
    YY, XX = np.meshgrid(ys, xs, indexing='ij'); Dw = dir_of((XX + .5) / W, (YY + .5) / H); ang = np.arccos(np.clip(Dw @ SUN, -1, 1))
    r = ang / R; disc = (r < 1.0).astype(np.float32); limb = np.sqrt(np.clip(1 - r ** 2, 0, 1))
    mott = fbm(Dw * 220, 5, 4)
    dcol = np.array((0.11, 0.018, 0.010), np.float32) * (.45 + .55 * limb)[..., None] * (.75 + .5 * mott)[..., None]
    corona = np.exp(-((r - 1.0) / .035) ** 2) * .55 + np.exp(-np.clip(r - 1, 0, None) / .25) * .16 * (r > 1)
    streak = fbm(np.stack([np.arctan2(Dw[..., 0] - SUN[0], Dw[..., 2] - SUN[2]) * 3, r * .5, np.zeros_like(r)], -1), 9, 3)
    corona = corona * (.7 + .6 * streak)
    ccol = np.array((1.0, 0.36, 0.16), np.float32)
    patch = img[YY, XX] * (1 - disc)[..., None] + dcol * disc[..., None] + (corona * (1 - disc * .85))[..., None] * ccol * .55
    img[YY, XX] = patch
    out_img = Image.fromarray((np.clip(img, 0, 1) ** (1 / 2.2) * 255 + .5).astype(np.uint8))
    glow = out_img.filter(ImageFilter.GaussianBlur(1.6)); out_img = Image.blend(out_img, glow, 0.30)
    out_img.save(out, optimize=True); print('sky', out, out_img.size, round(os.path.getsize(out) / 1e6, 1), 'MB', 'sun uv', round(u0, 4), round(v0, 4))


# ---------------------------------------------------------------------------------------------------------------------------------------
def rock_glb(code, out):
    j = json.load(open(os.path.join(ROOT, 'rocks_hi', code + '.json')))
    b = lambda s, t: np.frombuffer(base64.b64decode(s), t)
    ext = np.array(j['ext'], np.float32); pos = b(j['p'], np.int16).reshape(-1, 3).astype(np.float32) / 32767 * ext
    nor = b(j['q'], np.int8).reshape(-1, 3).astype(np.float32) / 127; nor /= np.maximum(np.linalg.norm(nor, axis=1, keepdims=True), 1e-6)
    idx = b(j['i'], np.uint32 if j.get('i32') else np.uint16).astype(np.uint32)
    uv = b(j['u'], np.uint16).reshape(-1, 2).astype(np.float32) / 65535; uv[:, 1] = 1 - uv[:, 1]
    tint = [.27, .255, .245]  # scene3d.js ROCK_TINT for RCA (carbon rock), a little browner
    tint = [tint[0] * 1.08, tint[1] * 1.0, tint[2] * .9, 1.0]
    def enc(path, fmt):
        im = Image.open(path).convert('RGB'); bio = io.BytesIO()
        (im.save(bio, 'PNG', compress_level=9) if fmt == 'png' else im.save(bio, 'JPEG', quality=92)); return bio.getvalue()
    ao = Image.open(os.path.join(ROOT, 'rocks_hi', code + '_m.webp')).convert('RGB'); a = np.asarray(ao)
    orm = np.stack([a[..., 0], np.full_like(a[..., 0], 255), np.zeros_like(a[..., 0])], -1)  # R occlusion, G roughness 1 (x factor), B metal 0
    bio = io.BytesIO(); Image.fromarray(orm).save(bio, 'JPEG', quality=92); ormb = bio.getvalue()
    blobs = [pos.astype('<f4').tobytes(), nor.astype('<f4').tobytes(), uv.astype('<f4').tobytes(), idx.astype('<u4').tobytes(), enc(os.path.join(ROOT, 'rocks_hi', code + '_n.webp'), 'png'), ormb]
    views, buf = [], bytearray()
    for i, bl in enumerate(blobs):
        buf += b'\0' * ((4 - len(buf) % 4) % 4); v = {'buffer': 0, 'byteOffset': len(buf), 'byteLength': len(bl)}
        if i < 3: v['target'] = 34962
        elif i == 3: v['target'] = 34963
        views.append(v); buf += bl
    buf += b'\0' * ((4 - len(buf) % 4) % 4)
    gl = {'asset': {'version': '2.0', 'generator': 'voidsworn make_env'}, 'scene': 0, 'scenes': [{'nodes': [0]}], 'nodes': [{'name': code, 'mesh': 0}],
          'meshes': [{'name': code, 'primitives': [{'attributes': {'POSITION': 0, 'NORMAL': 1, 'TEXCOORD_0': 2}, 'indices': 3, 'material': 0}]}],
          'materials': [{'name': 'rock_' + code, 'pbrMetallicRoughness': {'baseColorFactor': tint, 'metallicFactor': 0.0, 'roughnessFactor': 0.92,
                                                                        'metallicRoughnessTexture': {'index': 1, 'texCoord': 0}},
                         'normalTexture': {'index': 0, 'texCoord': 0}, 'occlusionTexture': {'index': 1, 'texCoord': 0, 'strength': 1.0}}],
          'textures': [{'source': 0, 'sampler': 0}, {'source': 1, 'sampler': 0}], 'samplers': [{'magFilter': 9729, 'minFilter': 9987, 'wrapS': 33071, 'wrapT': 33071}],
          'images': [{'bufferView': 4, 'mimeType': 'image/png'}, {'bufferView': 5, 'mimeType': 'image/jpeg'}],
          'accessors': [{'bufferView': 0, 'componentType': 5126, 'count': len(pos), 'type': 'VEC3', 'min': pos.min(0).tolist(), 'max': pos.max(0).tolist()},
                        {'bufferView': 1, 'componentType': 5126, 'count': len(pos), 'type': 'VEC3'},
                        {'bufferView': 2, 'componentType': 5126, 'count': len(pos), 'type': 'VEC2'},
                        {'bufferView': 3, 'componentType': 5125, 'count': len(idx), 'type': 'SCALAR'}],
          'bufferViews': views, 'buffers': [{'byteLength': len(buf)}]}
    js = json.dumps(gl, separators=(',', ':')).encode(); js += b' ' * ((4 - len(js) % 4) % 4)
    with open(out, 'wb') as f:
        f.write(struct.pack('<III', 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(buf))); f.write(struct.pack('<II', len(js), 0x4E4F534A)); f.write(js)
        f.write(struct.pack('<II', len(buf), 0x004E4942)); f.write(bytes(buf))
    return len(idx) // 3, (pos.max(0) - pos.min(0)).max(), os.path.getsize(out)


# ---------------------------------------------------------------------------------------------------------------------------------------
SHIPS_MAIN = [(-45, 30), (0, 30), (45, 30), (-45, -30), (0, -30), (45, -30)]  # SPEC layout, length 24, bows +x, port +z
CROWD_X = (-60, -36, -12, 12, 36, 60)


def seg_dist(p, a, b):
    a, b = np.asarray(a, float), np.asarray(b, float); d = b - a; t = np.clip(np.dot(p - a, d) / max(np.dot(d, d), 1e-9), 0, 1); return np.linalg.norm(p - (a + d * t))


def make_field(out, rocks):
    rng = np.random.default_rng(7)
    ships = [(np.array([x, 0, z], float), 12.0) for x, z in SHIPS_MAIN]
    for zr in (60, 0, -60, 90, -90, 120):  # stress rows and the 40-ship rows, 0.6 scale copies
        ships += [(np.array([x, 0, zr], float), 7.2) for x in CROWD_X]
    lines = []
    for x, z in SHIPS_MAIN:
        lines.append(((x + 12, 0, z), (x + 92, 0, z)))           # lance: from the bow to 80 ahead
        for gx in (-6.7, -2.4, 2.4, 6.7): lines.append(((x + gx, 2, z + 3), (x + gx, 0, z + 70)))  # broadside: 70 off the port side
        lines.append(((x, 0, z - 40), (x, 0, z - 3)))            # incoming shell from starboard
    sights = [((20, 14, 58), (45, 0, 30)), ((12, 10, 52), (0, 2, 30))]  # close-up and breach stills
    for x, z in SHIPS_MAIN: sights.append(((x - 8, 6, z + (20 if z > 0 else -20)), (x, 0, z)))  # hero stills
    def clear(p, R, pad_ship=6, pad_line=6):
        if any(np.linalg.norm(p - c) < R + r + pad_ship for c, r in ships): return False
        if any(seg_dist(p, a, b) < R + pad_line for a, b in lines): return False
        if any(seg_dist(p, a, b) < R + 2 for a, b in sights): return False
        return True
    def quat(r):
        q = r.normal(0, 1, 4); q /= np.linalg.norm(q); return [round(float(x), 5) for x in q]  # x, y, z, w
    def spin(r):
        a = r.normal(0, 1, 3); a /= np.linalg.norm(a); return [round(float(x), 4) for x in a], round(float(r.uniform(.03, .18)), 4)
    items = []
    tries = 0
    while len([i for i in items if i['kind'] == 'field']) < 200 and tries < 20000:  # the field: below the formation, mostly on the far side
        tries += 1
        az = rng.normal(math.radians(80), math.radians(55)); dist = 30 + 120 * math.sqrt(rng.random())  # far side of the 200..320 degree camera orbit
        s = float(np.clip(1 + 14 * rng.power(.45), 1, 15)) if rng.random() < .9 else float(rng.uniform(8, 15))  # mostly small, a few big
        y = rng.uniform(-45, -10); R = s / 2
        if y + R > -9: y = -9 - R
        p = np.array([dist * math.cos(az), y, dist * math.sin(az)])
        if np.hypot(p[0], p[2]) > 150: continue
        if any(np.linalg.norm(p - np.array(i['position'])) < R + i['scale'] / 2 + .5 for i in items): continue
        if not clear(p, R, 2, 2): continue
        ax, w = spin(rng); items.append(dict(kind='field', mesh=rocks[int(rng.integers(len(rocks)))], position=[round(float(c), 3) for c in p], rotation=quat(rng), scale=round(s, 3), spin_axis=ax, spin_rate=w))
    big = 0; tries = 0
    while big < 6 and tries < 50000:  # six large rocks near the formation, clear of ships, lances, broadsides and the still cameras
        tries += 1; s = rng.uniform(20, 30); R = s / 2
        p = np.array([rng.uniform(-125, 125), rng.uniform(-22, 14), rng.uniform(-125, 125)])
        if not (40 < np.hypot(p[0], p[2]) < 135): continue
        if not clear(p, R): continue
        if any(np.linalg.norm(p - np.array(i['position'])) < R + i['scale'] / 2 + 4 for i in items): continue
        ax, w = spin(rng); items.append(dict(kind='large', mesh=rocks[int(rng.integers(len(rocks)))], position=[round(float(c), 3) for c in p], rotation=quat(rng), scale=round(float(s), 3), spin_axis=ax, spin_rate=round(w * .3, 4)))
        big += 1
    doc = dict(seed=7, frame='engine world: x toward the bows, y up, z to port (the SPEC layout)',
               notes='mesh = file rocks/<mesh>.glb (rock about 1 unit across, so scale = size in units); rotation = quaternion [x, y, z, w]; spin_axis is a unit vector in world space, spin_rate in radians per second',
               count=len(items), rocks=items)
    json.dump(doc, open(out, 'w'), indent=1); print('field', out, 'field rocks', len(items) - big, 'large', big)


if __name__ == '__main__':
    a = sys.argv[1:]; out = a[0]; flags = set(a[1:]) or {'--sky', '--rocks', '--field'}; os.makedirs(out, exist_ok=True)
    codes = sorted(f[:-5] for f in os.listdir(os.path.join(ROOT, 'rocks_hi')) if f.startswith('RCA') and f.endswith('.json'))
    if '--rocks' in flags:
        os.makedirs(os.path.join(out, 'rocks'), exist_ok=True)
        for c in codes: t, L, sz = rock_glb(c, os.path.join(out, 'rocks', c + '.glb')); print('rock', c, 'tris', t, 'size', round(float(L), 3), 'MB', round(sz / 1e6, 2))
    if '--field' in flags: make_field(os.path.join(out, 'asteroids.json'), codes)
    if '--sky' in flags: make_sky(os.path.join(out, 'sky_deadstar_8k.png'))
