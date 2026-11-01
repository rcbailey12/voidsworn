# A4 concept paint (feel pass, Nov 1 2026). Ryan after his first Godot playtest: "Painting and ship visuals looked incomplete"; his bar is
# that a ship looks like its concept art from every angle, with real material texture. The in-game check showed the maps reach the screen;
# what was missing is the concept's own livery: the bake painted every ship of a faction one flat colour plus procedural noise (Hegemony
# came out nearly white, with none of the concept's slate panels and blue bands). Ryan saw concept projection before (NEXT.md, Oct 21:
# "much closer") and the A4 chain had dropped it.
#
# This step works in texture space on what a4_ship.py already wrote (numpy, PIL, scipy; no Blender), so it runs in pack.py on the PC and
# in the cloud for checks:
#   1. register the concept: point-splat silhouettes of the finished ship over a camera grid, fit the concept's cut-out (IoU), refine;
#   2. rasterise the ship's UV atlas (every texel gets its 3D point and normal);
#   3. project: a texel takes the concept colour where the concept camera sees it (z-buffer, facing); its mirror twin across the centre
#      plane fills the far side; what no view sees (belly, stern face) takes the mean of the nearest seen texels in 3D;
#   4. composite: the concept colour carries the large shapes (livery, light and dark sections), the baked procedural paint carries the
#      small ones (panel lines, photo grain, hatches, AO, edge wear) as a ratio to its own blur.
# Factions whose lore changed after the concepts (R59: Chorus olive and ochre, Eclipse violet-black with no green, Glasswright ice-blue
# crystal) take only the concept's light-and-dark pattern, recoloured through their lore palette.
#   python concept.py META.json [--concept PNG] [--out DIR] [--res 2048] [--sheet]
import sys, os, json, math, time
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
CONCEPTS = os.path.join(REPO, 'docs', 'ship_pipeline', 'concepts')
if not os.path.isdir(CONCEPTS): CONCEPTS = os.path.join(HERE, '..', 'concepts')  # on the PC: a4tools\concepts (stage.py copies them)

# how much of the concept each faction takes (vetoable): col = concept colour share, lum = concept value pattern share in palette mode
MODE = {
    'hegemony': dict(kind='colour', k=1.0), 'voidsworn': dict(kind='colour', k=.9), 'corsair': dict(kind='colour', k=.9),
    'obj': dict(kind='colour', k=1.0), 'craft': dict(kind='colour', k=.9),
    'chorus': dict(kind='palette', k=.75), 'deathless': dict(kind='palette', k=.70), 'ithar': dict(kind='palette', k=.70),
}
DETAIL = {'hegemony': .55, 'voidsworn': .8, 'corsair': .9, 'obj': .6, 'craft': .7, 'chorus': .8, 'deathless': .7, 'ithar': .5}
# which side of the concept picture the bow points to (read off docs/ship_pipeline/concepts, Nov 1): a silhouette alone cannot tell bow
# from stern on a long hull (H4 and C14s fitted back to front). None: discs, rings, towers and blobs, the fit decides.
TOP = ('D20_23', 'D21_23', 'D22_23', 'O1_37')
BOW = {'B19_11': 'L', 'B21_11': 'R', 'B22_11': 'L', 'B23_51': 'R', 'C13s_23': 'L', 'C14s_23': 'L', 'C15s_23': 'L', 'C16s_23': 'L',
       'C19_51': 'L', 'D9_23': 'L', 'H10_23': 'R', 'H4_11': 'L', 'H7_23': 'R', 'H8_23': 'R', 'H9_23': 'R', 'I11_37': 'R', 'I14_23': 'L',
       'I15_11': 'R', 'I16_11': 'R', 'O2_37': 'R', 'S1_51': 'L', 'S2_23': 'L', 'V14_23': 'L', 'V15_37': 'L', 'V16_37': 'L', 'V17_37': 'L',
       'V18_51': 'L', 'V1b_r_23': 'L'}
PALETTE = {  # lore palettes (bakemat4.FAC, R59): dark, hull, accent, trim (sRGB hex); palette mode takes its hue from the hull entry
    'chorus': ['#14130a', '#3b3a22', '#6b5a2a', '#b5852f'],
    'deathless': ['#0b0910', '#1e1726', '#3a2f4a', '#8d7fa8'],
    'ithar': ['#3d4c5c', '#7f97ad', '#b6c8d8', '#e6eef5'],
}


def s2l(c):
    c = np.asarray(c, np.float32); return np.where(c <= .04045, c / 12.92, ((c + .055) / 1.055) ** 2.4)


def l2s(c):
    c = np.clip(np.asarray(c, np.float32), 0, 1); return np.where(c <= .0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - .055)


def hexc(h): return np.array([int(h[i:i + 2], 16) / 255. for i in (1, 3, 5)], np.float32)


# ------------------------------------------------------------------------------------------------ camera

def cam_basis(az, el):
    """camera on a sphere around the ship (glTF frame: +X bow, +Y up, +Z starboard). az 0 = looking from the bow, 90 = from starboard."""
    a, e = math.radians(az), math.radians(el)
    back = np.array([math.cos(e) * math.cos(a), math.sin(e), math.cos(e) * math.sin(a)], np.float32)  # from the target toward the camera
    fwd = -back; up0 = np.array([0, 1, 0], np.float32)
    if abs(fwd @ up0) > .999: up0 = np.array([1, 0, 0], np.float32)
    right = np.cross(fwd, up0); right /= np.linalg.norm(right); up = np.cross(right, fwd)
    return back, right, up, fwd


def project(P, az, el, fov, D=None):
    """perspective projection: returns (x, y) in units of the half image (tan of the half fov), depth"""
    back, right, up, fwd = cam_basis(az, el)
    if D is None: D = 1.1 * .5 / math.tan(math.radians(fov) / 2)
    C = back * D; Q = P - C; z = Q @ fwd; t = math.tan(math.radians(fov) / 2)
    return (Q @ right) / (z * t), (Q @ up) / (z * t), z


def splat(x, y, R, w=1.0):
    """silhouette by point splat: x, y in -1..1 (y up) to an R x R mask"""
    from scipy import ndimage
    px = ((x * .5 + .5) * R).astype(np.int32); py = ((.5 - y * .5) * R).astype(np.int32)
    ok = (px >= 0) & (px < R) & (py >= 0) & (py < R); M = np.zeros((R, R), bool); M[py[ok], px[ok]] = True
    M = ndimage.binary_closing(M, iterations=2); M = ndimage.binary_fill_holes(M); return M


def bbox(M):
    ys, xs = np.nonzero(M); return xs.min(), xs.max() + 1, ys.min(), ys.max() + 1


def place_concept(cm, S, sx=1.0, dx=0., dy=0., sy=1.0):
    """the concept mask cm (cropped to its box) scaled into the render mask S's frame: uniform scale from the box areas, centred on the
    box centres. Returns the placed mask and the similarity (s, ox, oy): render px = concept_crop px * s + (ox, oy)"""
    R = S.shape[0]; x0, x1, y0, y1 = bbox(S); w, h = x1 - x0, y1 - y0; ch, cw = cm.shape
    s = math.sqrt((w * h) / (cw * ch)) * sx; t = s * sy; cx = (x0 + x1) / 2 + dx; cy = (y0 + y1) / 2 + dy
    ox, oy = cx - cw * s / 2, cy - ch * t / 2
    im = Image.fromarray((cm * 255).astype(np.uint8)).resize((max(1, round(cw * s)), max(1, round(ch * t))), Image.BILINEAR)
    M = np.zeros((R, R), np.uint8); px, py = round(ox), round(oy); a = np.asarray(im)
    xa, ya = max(0, px), max(0, py); xb, yb = min(R, px + a.shape[1]), min(R, py + a.shape[0])
    if xb > xa and yb > ya: M[ya:yb, xa:xb] = a[ya - py:yb - py, xa - px:xb - px]
    return M > 127, (s, ox, oy, t)


def iou(A, B): return (A & B).sum() / max(1, (A | B).sum())


def register(P, cm, log=print, fixed=None, bow=None, top=False):
    """the camera (az, el, fov) and 2D fit whose silhouette best matches the concept cut-out. P: points on the ship (subsampled)."""
    R = 160; best = None
    fovs = (14.0, 26.0); azs = range(0, 360, 6)
    els = range(30, 91, 6) if top else range(14, 51, 4)  # the concepts are three-quarter views from above (discs and rings: from the top)
    elo, ehi = (24., 90.) if top else (12., 52.)
    if fixed: azs, els = [fixed['az']], [fixed['el']]
    xs_ = P[:, 0]; ends = (P[xs_ > np.percentile(xs_, 97)].mean(0), P[xs_ < np.percentile(xs_, 3)].mean(0))  # bow and stern ends
    def bow_ok(az, el, fov):
        if bow is None: return True
        bx, sx_ = project(np.stack(ends), az, el, fov)[0]; return (bx < sx_) == (bow == 'L')
    for fov in fovs:
        for az in azs:
            for el in els:
                if not bow_ok(az, el, fov): continue
                x, y, _ = project(P, az, el, fov); S = splat(x, y, R)
                if S.sum() < 30: continue
                for sx in (.95, 1.0, 1.05):
                    v = iou(S, place_concept(cm, S, sx)[0])
                    if best is None or v > best[0]: best = (v, az, el, fov, sx, 0., 0.)
    log('[concept] coarse', dict(iou=round(best[0], 3), az=best[1], el=best[2], fov=best[3]))
    # refine at a finer resolution: angles, fov, scale, offset
    R = 320; v0, az0, el0, fov0, sx0, dx0, dy0 = best; sy0 = 1.0; best = None
    for _ in range(3):
        for daz in (-3, -1.5, 0, 1.5, 3):
            for de in (-3, -1.5, 0, 1.5, 3):
                for df in (-4, 0, 4):
                    az, el, fov = az0 + daz, min(ehi, max(elo, el0 + de)), min(34., max(10., fov0 + df))
                    if not bow_ok(az, el, fov): continue
                    x, y, _ = project(P, az, el, fov); S = splat(x, y, R)
                    for sx in (sx0 - .03, sx0, sx0 + .03):
                        for sy in (sy0 - .05, sy0, sy0 + .05):
                            for dx in (dx0 - 3, dx0, dx0 + 3):
                                for dy in (dy0 - 3, dy0, dy0 + 3):
                                    v = iou(S, place_concept(cm, S, sx, dx, dy, sy)[0])
                                    if best is None or v > best[0]: best = (v, az, el, fov, sx, dx, dy, sy)
        _, az0, el0, fov0, sx0, dx0, dy0, sy0 = best
    log('[concept] fit', dict(iou=round(best[0], 3), az=best[1], el=best[2], fov=best[3], sx=round(best[4], 3), sy=round(best[7], 3), dx=best[5], dy=best[6]))
    return dict(iou=float(best[0]), az=float(best[1]), el=float(best[2]), fov=float(best[3]), sx=float(best[4]), dx=float(best[5]), dy=float(best[6]), sy=float(best[7]), R=R)


# ------------------------------------------------------------------------------------------------ atlas

def rasterise(pos, nor, idx, uv, res):
    """every texel centre inside a UV triangle: (texel flat index, 3D point, normal). UV v runs up (glTF stores v down: image row = v * res)"""
    T = uv[idx] * res  # (n, 3, 2) pixel coords, glTF convention: row = v * res
    x0 = np.floor(T[..., 0].min(1)).astype(np.int32); x1 = np.ceil(T[..., 0].max(1)).astype(np.int32)
    y0 = np.floor(T[..., 1].min(1)).astype(np.int32); y1 = np.ceil(T[..., 1].max(1)).astype(np.int32)
    sz = np.maximum(x1 - x0, y1 - y0) + 1
    out_i, out_p, out_n = [], [], []
    b = 2
    while True:
        sel = np.nonzero((sz <= b) & (sz > b // 2 if b > 2 else sz <= b))[0]
        if len(sel):
            for c0 in range(0, len(sel), max(1, 4_000_000 // (b * b))):
                s = sel[c0:c0 + max(1, 4_000_000 // (b * b))]
                oy, ox = np.mgrid[0:b, 0:b]; ox = ox.ravel(); oy = oy.ravel()
                px = x0[s, None] + ox[None]; py = y0[s, None] + oy[None]; cx = px + .5; cy = py + .5
                A = T[s, 0]; B = T[s, 1]; C = T[s, 2]
                d = (B[:, 1] - C[:, 1]) * (A[:, 0] - C[:, 0]) + (C[:, 0] - B[:, 0]) * (A[:, 1] - C[:, 1]); d = np.where(np.abs(d) < 1e-12, 1e-12, d)
                l1 = ((B[:, 1, None] - C[:, 1, None]) * (cx - C[:, 0, None]) + (C[:, 0, None] - B[:, 0, None]) * (cy - C[:, 1, None])) / d[:, None]
                l2 = ((C[:, 1, None] - A[:, 1, None]) * (cx - C[:, 0, None]) + (A[:, 0, None] - C[:, 0, None]) * (cy - C[:, 1, None])) / d[:, None]
                l3 = 1 - l1 - l2; e = -1e-4
                ins = (l1 >= e) & (l2 >= e) & (l3 >= e) & (px >= 0) & (px < res) & (py >= 0) & (py < res)
                ti, oi = np.nonzero(ins)
                if not len(ti): continue
                tri = idx[s[ti]]; w = np.stack([l1[ti, oi], l2[ti, oi], l3[ti, oi]], 1).astype(np.float32)
                out_i.append((py[ti, oi] * res + px[ti, oi]).astype(np.int64))
                out_p.append((pos[tri] * w[..., None]).sum(1)); out_n.append((nor[tri] * w[..., None]).sum(1))
        if (sz > b).sum() == 0: break
        b *= 2
    I = np.concatenate(out_i); Pp = np.concatenate(out_p).astype(np.float32); N = np.concatenate(out_n).astype(np.float32)
    N /= np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-9)
    I, first = np.unique(I, return_index=True)  # a texel on a shared edge: keep one
    return I, Pp[first], N[first]


# ------------------------------------------------------------------------------------------------ projection

def concept_rgba(code, path=None):
    p = path or os.path.join(CONCEPTS, code + '.webp'); im = Image.open(p).convert('RGBA'); a = np.asarray(im).astype(np.float32) / 255.
    return a


def sample(img, u, v):
    """bilinear sample of img (H, W, C) at pixel coords u, v (float)"""
    H, W = img.shape[:2]; u = np.clip(u - .5, 0, W - 1.001); v = np.clip(v - .5, 0, H - 1.001)
    x0 = np.floor(u).astype(np.int32); y0 = np.floor(v).astype(np.int32); fx = (u - x0)[:, None]; fy = (v - y0)[:, None]
    return (img[y0, x0] * (1 - fx) * (1 - fy) + img[y0, x0 + 1] * fx * (1 - fy) + img[y0 + 1, x0] * (1 - fx) * fy + img[y0 + 1, x0 + 1] * fx * fy)


def view_lookup(P, N, reg, cm_box, cimg, zres=1024):
    """concept colour and weight for points P (normals N) under the registered camera"""
    az, el, fov = reg['az'], reg['el'], reg['fov']; R = reg['R']
    x, y, z = project(P, az, el, fov)
    # render pixel (R frame) -> concept crop pixel -> concept image pixel
    rx = (x * .5 + .5) * R; ry = (.5 - y * .5) * R
    s, ox, oy, t = reg['sim']; cx0, cy0 = cm_box[0], cm_box[2]
    u = (rx - ox) / s + cx0; v = (ry - oy) / t + cy0
    # visibility: z-buffer of the same points at zres
    back, right, up, fwd = cam_basis(az, el)
    zx = np.clip((x * .5 + .5) * zres, 0, zres - 1).astype(np.int32); zy = np.clip((.5 - y * .5) * zres, 0, zres - 1).astype(np.int32)
    zb = np.full(zres * zres, np.inf, np.float32); np.minimum.at(zb, zy * zres + zx, z.astype(np.float32))
    from scipy import ndimage
    zb2 = ndimage.minimum_filter(zb.reshape(zres, zres), size=3).ravel()  # holes between splats
    vis = z <= zb2[zy * zres + zx] + .006
    D = 1.1 * .5 / math.tan(math.radians(fov) / 2); C = back * D
    vd = C[None] - P; vd /= np.linalg.norm(vd, axis=1, keepdims=True)
    face = np.clip(((N * vd).sum(1) - .08) / .35, 0, 1)
    col = sample(cimg, u, v)  # RGBA, alpha from the cut-out (eroded)
    w = vis * face * col[:, 3]
    return col[:, :3], w.astype(np.float32)


def erode_alpha(cimg, px=3):
    from scipy import ndimage
    a = cimg[..., 3] > .5; a = ndimage.binary_erosion(a, iterations=px); out = cimg.copy(); out[..., 3] = ndimage.gaussian_filter(a.astype(np.float32), 1.0)
    return out


def blur_masked(img, mask, sigma):
    from scipy import ndimage
    m = mask.astype(np.float32); num = np.stack([ndimage.gaussian_filter(img[..., c] * m, sigma) for c in range(img.shape[2])], -1)
    den = ndimage.gaussian_filter(m, sigma)[..., None]; return num / np.maximum(den, 1e-4)


def fill_empty(img, mask):
    """padding: every texel outside the islands takes its nearest island texel (no dark seams in the mips)"""
    from scipy import ndimage
    _, (iy, ix) = ndimage.distance_transform_edt(~mask, return_indices=True); return img[iy, ix]



def compose(A, Cimg, mask, fac, mode, detail=None, k=None, rows=512, vk=1.0):
    """A: the baked procedural albedo (sRGB, uint8 or 0..1 float), Cimg: the projected concept colour (sRGB, padded). The concept carries
    the large shapes; the procedural paint's small-scale value (panel lines, grain, hatches, AO, wear) rides on it as a ratio to its own
    blur, softened by `detail` (an exponent: 1 keeps it all; the AI hull's dress plates otherwise read as blotches over the concept's clean
    livery). vk: how much of the concept's own light-and-dark to keep (1 all; a looser fit keeps its colours and stripes but flattens its
    value, or misplaced dark parts of the picture land on open hull as blotches that read as dazzle camouflage). Works in row bands (a 4096 bake on the 8 GB cloud box). Returns uint8 sRGB."""
    res = A.shape[0]; det = DETAIL.get(fac, .7) if detail is None else detail; k = mode['k'] if k is None else k
    A8 = A if A.dtype == np.uint8 else (np.clip(A, 0, 1) * 255 + .5).astype(np.uint8)
    C8 = Cimg if Cimg.dtype == np.uint8 else (np.clip(Cimg, 0, 1) * 255 + .5).astype(np.uint8)
    W3 = np.array([.2126, .7152, .0722], np.float32)
    tint = None
    if mode['kind'] == 'palette':  # the concept's light-and-dark pattern only: hue from the lore hull colour, mean brightness from the lore
        # paint as baked (a near-black concept stays dark, a pale one stays pale relative to its own mean)
        hue = s2l(hexc(PALETTE[fac][1])); hue = hue / max(float((hue * W3).sum()), 1e-4)
        q0 = max(1, C8.shape[0] // 512); Lc = (s2l(C8[::q0, ::q0].astype(np.float32) / 255.) * W3).sum(-1)
        La0 = (s2l(A8[::max(1, res // 512), ::max(1, res // 512)].astype(np.float32) / 255.) * W3).sum(-1)
        mk = np.asarray(Image.fromarray(mask.astype(np.uint8) * 255).resize(Lc.shape[::-1], Image.NEAREST)) > 127
        mk2 = np.asarray(Image.fromarray(mask.astype(np.uint8) * 255).resize(La0.shape[::-1], Image.NEAREST)) > 127
        tint = hue * (float(La0[mk2].mean()) / max(float(Lc[mk].mean()), 1e-4)); del Lc, La0
    Lm = None
    if vk < 1.0:
        q0 = max(1, C8.shape[0] // 512); Lc0 = (s2l(C8[::q0, ::q0].astype(np.float32) / 255.) * W3).sum(-1)
        mk0 = np.asarray(Image.fromarray(mask.astype(np.uint8) * 255).resize(Lc0.shape[::-1], Image.NEAREST)) > 127; Lm = float(Lc0[mk0].mean()); del Lc0
    if C8.shape[0] != res: C8 = np.asarray(Image.fromarray(C8).resize((res, res), Image.BILINEAR))
    if mask.shape[0] != res: mask = np.asarray(Image.fromarray(mask.astype(np.uint8) * 255).resize((res, res), Image.NEAREST)) > 127
    # the procedural paint's own large shapes: a masked blur of its luminance at 1024
    q = max(1, res // 1024); Lq = np.zeros((res // q, res // q), np.float32)
    for r0 in range(0, res, rows):
        La = (s2l(A8[r0:r0 + rows].astype(np.float32) / 255.) * W3).sum(-1); Lq[r0 // q:(r0 + rows) // q] = La.reshape(-1, q, res // q, q).mean((1, 3))
    mq = mask.reshape(res // q, q, res // q, q).mean((1, 3)) > .5
    Lb = blur_masked(Lq[..., None], mq, 1024 / 256.)[..., 0]; Lb = np.asarray(Image.fromarray(Lb.astype(np.float32), mode='F').resize((res, res), Image.BILINEAR))
    out = np.empty_like(A8)
    for r0 in range(0, res, rows):
        Al = s2l(A8[r0:r0 + rows].astype(np.float32) / 255.); Cl = s2l(C8[r0:r0 + rows].astype(np.float32) / 255.)
        ratio = (np.clip((Al * W3).sum(-1) / np.maximum(Lb[r0:r0 + rows], 1e-4), 0, 2.5) ** det)[..., None]
        if Lm is not None:
            Lc_ = np.maximum((Cl * W3).sum(-1, keepdims=True), 1e-4); Cl = Cl * ((Lm + (Lc_ - Lm) * vk) / Lc_)
        if tint is not None: Cl = (Cl * W3).sum(-1, keepdims=True) * tint
        o = Al * (1 - k) + Cl * ratio * k
        out[r0:r0 + rows] = (l2s(o) * 255 + .5).astype(np.uint8)
    return out


def paint(meta_path, concept=None, res=2048, out_dir=None, sheet=False, log=print, fixed=None, albedo_path=None):
    t0 = time.time(); meta = json.load(open(meta_path)); code = meta['code']; fac = meta['faction']; base = os.path.dirname(meta_path)
    if meta.get('cls') == 'Squadron' or code.startswith('S'): fac_m = 'craft'
    elif code.startswith('O'): fac_m = 'obj'
    else: fac_m = fac
    mode = MODE.get(fac_m, MODE.get(fac))
    mp = meta['mesh'] if os.path.exists(meta['mesh']) else os.path.join(base, os.path.basename(meta['mesh'].replace('\\', '/')))
    m = np.load(mp); pos, nor, idx, uv = m['pos'], m['nor'], m['idx'].astype(np.int64), m['uv']
    nor = nor / np.maximum(np.linalg.norm(nor, axis=1, keepdims=True), 1e-9)
    ap = albedo_path or meta['maps'].get('albedo_proc') or meta['maps']['albedo']
    if not os.path.exists(ap): ap = os.path.join(base, 'tex', os.path.basename(ap.replace('\\', '/')))
    A = np.asarray(Image.open(ap).convert('RGB'))
    cimg = erode_alpha(concept_rgba(code, concept), 3)
    a = cimg[..., 3] > .5; ys, xs = np.nonzero(a); cm_box = (xs.min(), xs.max() + 1, ys.min(), ys.max() + 1)
    cm = a[cm_box[2]:cm_box[3], cm_box[0]:cm_box[1]]
    # 1. registration on a point cloud: vertices plus triangle centres
    rng = np.random.default_rng(1); cen = pos[idx].mean(1); Pr = np.concatenate([pos, cen]); Pr = Pr[rng.permutation(len(Pr))[:120000]]
    reg = register(Pr, cm, log, fixed, BOW.get(code), code in TOP)
    x, y, _ = project(Pr, reg['az'], reg['el'], reg['fov']); S = splat(x, y, reg['R'])
    M, sim = place_concept(cm, S, reg['sx'], reg['dx'], reg['dy'], reg.get('sy', 1.0)); reg['sim'] = sim
    # 2. atlas texels
    I, P, N = rasterise(pos, nor, idx, uv, res); log('[concept] texels', len(I), round(time.time() - t0, 1), 's')
    # 3. projection: direct view and its mirror twin across the centre plane (z -> -z)
    c1, w1 = view_lookup(P, N, reg, cm_box, cimg)
    Pm = P * np.array([1, 1, -1], np.float32); Nm = N * np.array([1, 1, -1], np.float32)
    c2, w2 = view_lookup(Pm, Nm, reg, cm_box, cimg)
    if fac == 'corsair': w2 = w2 * .7  # junky, not quite symmetric
    W = w1 + w2; Cc = (c1 * w1[:, None] + c2 * w2[:, None]) / np.maximum(W, 1e-6)[:, None]; W = np.clip(W, 0, 1)
    seen = W > .35
    # unseen texels: the mean of the nearest seen texels in 3D (belly, stern face, inner faces)
    from scipy.spatial import cKDTree
    sp = np.nonzero(seen)[0]; sub = sp[rng.permutation(len(sp))[:250000]]
    tree = cKDTree(P[sub]); Cs = Cc[sub]; Cfill = np.empty_like(Cc)
    for c0 in range(0, len(P), 200000):
        _, nn = tree.query(P[c0:c0 + 200000], k=12, workers=-1); Cfill[c0:c0 + 200000] = Cs[nn].mean(1)
    del tree
    under = np.clip((-N[:, 1] - .2) / .5, 0, 1)  # undersides a step darker (the concept never shows them)
    Cfill = Cfill * (1 - .25 * under[:, None])
    Cp = Cc * W[:, None] + Cfill * (1 - W[:, None])
    # 4. composite in texture space
    mask = np.zeros(res * res, bool); mask[I] = True; mask = mask.reshape(res, res)
    Cimg = np.zeros((res * res, 3), np.float32); Cimg[I] = Cp; Cimg = Cimg.reshape(res, res, 3)
    Cimg = blur_masked(Cimg, mask, 1.2)
    out_dir = os.path.abspath(out_dir or os.path.join(base, 'tex')); os.makedirs(out_dir, exist_ok=True)
    # the projected colour alone (sRGB, padded), so the mix can be re-tuned without projecting again
    Image.fromarray((np.clip(fill_empty(Cimg, mask), 0, 1) * 255 + .5).astype(np.uint8)).save(os.path.join(out_dir, f'{code}_concept_col.png'))
    Image.fromarray(mask.astype(np.uint8) * 255).save(os.path.join(out_dir, f'{code}_concept_mask.png'))
    del P, N, Pm, Nm, c1, c2, w1, w2, Cc, Cfill, Cp
    vk = float(np.clip((reg['iou'] - .76) / (.90 - .76), .35, 1.0)); reg['vk'] = vk
    out = compose(A, Cimg, mask, fac, mode, vk=vk)
    op = os.path.join(out_dir, f'{code}_albedo_concept.png'); Image.fromarray(out).save(op)
    rep = dict(code=code, faction=fac, mode=mode, reg={k_: v_ for k_, v_ in reg.items() if k_ != 'sim'}, seen=float(seen.mean()), texels=int(len(I)), s=round(time.time() - t0, 1))
    json.dump(rep, open(os.path.join(out_dir, f'{code}_concept.json'), 'w'), indent=1)
    log('[concept]', code, 'iou', round(reg['iou'], 3), 'seen', round(float(seen.mean()), 3), 'wrote', op, round(time.time() - t0, 1), 's')
    if sheet:  # registration check: the concept over the fitted silhouette
        ov = np.zeros((reg['R'], reg['R'], 3), np.uint8); ov[..., 0] = S * 255; ov[..., 1] = M * 255
        Image.fromarray(ov).save(os.path.join(out_dir, f'{code}_concept_fit.png'))
    return op, rep


def apply(meta_path, op, rep, base_dirs):
    """point the ship's meta at the concept paint (pack.py then packs it), keeping the procedural bake as albedo_proc; with base_dirs (a
    packed ship folder, e.g. a4\\godot\\CODE), also rewrite CODE_base.jpg there at pack.py's size, so a repaint needs no re-export: the
    glb files name that file and the game re-imports it"""
    import pack, gio
    meta = json.load(open(meta_path)); mp = meta['maps']
    if 'albedo_proc' not in mp: mp['albedo_proc'] = mp['albedo']
    mp['albedo'] = op; meta['concept'] = rep['reg']; json.dump(meta, open(meta_path, 'w'), indent=1)
    res = pack.auto_res(meta)
    for d in base_dirs:
        if not os.path.isdir(d): continue
        hi = 'godot_hi' in d.replace('\\', '/').split('/')
        size = 4096 if hi else res['base']
        open(os.path.join(d, f"{meta['code']}_base.jpg"), 'wb').write(gio.img_bytes(op, 'jpg', quality=90, size=size))
        pack.write_normal_import(d, meta['code'])
        print('[concept] base', meta['code'], size, '->', d, flush=True)


if __name__ == '__main__':
    a = sys.argv[1:]
    kw = {}
    if '--concept' in a: kw['concept'] = a[a.index('--concept') + 1]
    if '--out' in a: kw['out_dir'] = a[a.index('--out') + 1]
    if '--res' in a: kw['res'] = int(a[a.index('--res') + 1])
    if '--albedo' in a: kw['albedo_path'] = a[a.index('--albedo') + 1]
    if '--fixed' in a: az_, el_ = a[a.index('--fixed') + 1].split(','); kw['fixed'] = dict(az=float(az_), el=float(el_))
    op, rep = paint(a[0], sheet='--sheet' in a, **kw)
    if '--apply' in a: apply(a[0], op, rep, [a[i + 1] for i, x in enumerate(a) if x == '--base'])
