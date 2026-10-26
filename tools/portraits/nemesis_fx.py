# Nemesis frame and scar overlays (R42), made in code so the game can stack them on any Nemesis portrait:
#   godot/portraits/nemesis/frame_<faction>.png   1024 px, transparent centre: black band, blood-red line, thin faction trim,
#                                                 thorned corners and a dark edge vignette (reads as "enemy", unlike the admirals' thin trim)
#   godot/portraits/nemesis/scars/scar_<kind>.png 512 px RGBA overlays: burn, cyber, eye, carapace, porcelain, machine
# The game draws: base portrait, then each scar at the portrait's anchor (index.json), then the frame (portraits.gd nemesis()).
# Run: python3 tools/portraits/nemesis_fx.py
import os, math, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.dirname(os.path.dirname(HERE))
ND = os.path.join(REPO, 'godot', 'portraits', 'nemesis'); SD = os.path.join(ND, 'scars')
TRIM = {'voidsworn': (200, 80, 31), 'hegemony': (58, 120, 208), 'corsair': (184, 64, 42), 'chorus': (164, 145, 58), 'ithar': (215, 200, 138), 'deathless': (31, 191, 74)}
GLOW = {'chorus': (214, 210, 74), 'ithar': (255, 214, 120), 'deathless': (61, 255, 106)}
KINDS = {'burn': 'all', 'cyber': 'voidsworn hegemony corsair', 'eye': 'voidsworn hegemony corsair', 'carapace': 'chorus', 'porcelain': 'ithar', 'machine': 'deathless'}

def frame(fac, n=1024):
    im = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    # dark edge vignette inside the frame
    y, x = np.mgrid[0:n, 0:n] / n; e = np.minimum(np.minimum(x, 1 - x), np.minimum(y, 1 - y))
    a = (np.clip(1 - e / 0.12, 0, 1) ** 2 * 170).astype(np.uint8)
    v = np.zeros((n, n, 4), np.uint8); v[..., 0] = 18; v[..., 3] = a; im = Image.alpha_composite(im, Image.fromarray(v))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, n - 1, n - 1], outline=(6, 4, 4, 255), width=30)
    d.rectangle([30, 30, n - 31, n - 31], outline=(150, 14, 14, 255), width=7)
    d.rectangle([40, 40, n - 41, n - 41], outline=TRIM[fac] + (200,), width=2)
    for cx, cy, sx, sy in ((0, 0, 1, 1), (n, 0, -1, 1), (0, n, 1, -1), (n, n, -1, -1)):   # thorned corners
        d.polygon([(cx, cy), (cx + sx * 150, cy + sy * 30), (cx + sx * 56, cy + sy * 56), (cx + sx * 30, cy + sy * 150)], fill=(8, 4, 4, 255))
        d.line([(cx + sx * 30, cy + sy * 30), (cx + sx * 104, cy + sy * 104)], fill=(170, 18, 18, 255), width=6)
        d.polygon([(cx + sx * 96, cy + sy * 96), (cx + sx * 126, cy + sy * 104), (cx + sx * 104, cy + sy * 126)], fill=(170, 18, 18, 255))
    return im

def noise(n, scale, seed):
    rng = np.random.default_rng(seed); z = rng.random((max(2, n // scale), max(2, n // scale)))
    return np.array(Image.fromarray((z * 255).astype(np.uint8)).resize((n, n), Image.BICUBIC)) / 255.0

def blob(n, seed, r=0.36, rough=0.35):
    y, x = np.mgrid[0:n, 0:n] / n - 0.5; ang = np.arctan2(y, x); rr = np.hypot(x, y)
    rng = np.random.default_rng(seed); k = np.zeros_like(ang)
    for f in range(2, 7): k += rng.uniform(-1, 1) * np.sin(f * ang + rng.uniform(0, 6.3)) / f
    edge = r * (1 + rough * k) + 0.04 * (noise(n, 16, seed + 1) - 0.5)
    return np.clip((edge - rr) / 0.05, 0, 1)

def rgba(rgb, a): return Image.fromarray(np.dstack([np.clip(rgb, 0, 255), np.clip(a, 0, 255)]).astype(np.uint8))

def scar_burn(n=512, seed=3):
    m = blob(n, seed, 0.34, 0.45); core = blob(n, seed + 7, 0.2, 0.6) * m; t = noise(n, 6, seed + 2); t2 = noise(n, 24, seed + 3)
    t3 = noise(n, 40, seed + 5)
    raw = np.stack([120 + 40 * t3, 52 + 26 * t3, 46 + 18 * t3], -1)           # healed, waxy scar tissue
    char = np.stack([42 + 22 * t2, 26 + 14 * t2, 24 + 10 * t2], -1)           # darker puckered centre
    rgb = raw * (1 - core[..., None]) + char * core[..., None]
    gloss = (np.clip(t3 - 0.6, 0, 1) * 2.5)[..., None] * 70; rgb = rgb + gloss
    a = m * (0.45 + 0.35 * t3) * 215                                          # see-through so the painting's light shows through
    return rgba(rgb, a).filter(ImageFilter.GaussianBlur(3))

def scar_cyber(n=512, seed=5):
    im = Image.new('RGBA', (n, n), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    pts = [(n * .18, n * .22), (n * .78, n * .16), (n * .86, n * .58), (n * .62, n * .84), (n * .24, n * .74)]
    d.polygon(pts, fill=(58, 60, 64, 245)); d.line(pts + [pts[0]], fill=(20, 20, 22, 255), width=8)
    t = noise(n, 3, seed); arr = np.array(im).astype(float); arr[..., :3] *= (0.75 + 0.5 * t)[..., None]; im = Image.fromarray(arr.clip(0, 255).astype(np.uint8))
    d = ImageDraw.Draw(im)
    d.line([(n * .3, n * .45), (n * .8, n * .4)], fill=(30, 30, 34, 255), width=5); d.line([(n * .5, n * .2), (n * .48, n * .8)], fill=(30, 30, 34, 255), width=4)
    for px, py in pts: d.ellipse([px - 9 + (n * .5 - px) * .12, py - 9 + (n * .5 - py) * .12, px + 9 + (n * .5 - px) * .12, py + 9 + (n * .5 - py) * .12], fill=(120, 120, 126, 255))
    cx, cy, r = n * .5, n * .44, n * .1; d.ellipse([cx - r * 1.4, cy - r * 1.4, cx + r * 1.4, cy + r * 1.4], fill=(14, 12, 12, 255))
    gl = Image.new('RGBA', (n, n), (0, 0, 0, 0)); g = ImageDraw.Draw(gl); g.ellipse([cx - r * 2, cy - r * 2, cx + r * 2, cy + r * 2], fill=(255, 30, 20, 120)); gl = gl.filter(ImageFilter.GaussianBlur(18))
    im = Image.alpha_composite(im, gl); d = ImageDraw.Draw(im); d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 40, 30, 255)); d.ellipse([cx - r * .4, cy - r * .5, cx + r * .1, cy], fill=(255, 190, 170, 255))
    return im

def scar_eye(n=512, seed=9):
    # a deep slash through the eye: dark socket, puckered scar line, milky dead eye
    im = Image.new('RGBA', (n, n), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.ellipse([n * .34, n * .38, n * .66, n * .56], fill=(25, 14, 14, 200)); im = im.filter(ImageFilter.GaussianBlur(14)); d = ImageDraw.Draw(im)
    d.ellipse([n * .43, n * .44, n * .57, n * .51], fill=(196, 192, 180, 235)); d.ellipse([n * .48, n * .455, n * .53, n * .495], fill=(150, 150, 146, 200))
    line = [(n * .42, n * .08), (n * .47, n * .3), (n * .5, n * .47), (n * .55, n * .66), (n * .6, n * .92)]
    sl = Image.new('RGBA', (n, n), (0, 0, 0, 0)); e = ImageDraw.Draw(sl)
    e.line(line, fill=(70, 30, 30, 150), width=26, joint='curve'); sl = sl.filter(ImageFilter.GaussianBlur(7)); e = ImageDraw.Draw(sl)
    e.line(line, fill=(176, 120, 110, 200), width=6, joint='curve')
    for i in range(1, 8):
        p = (line[0][0] + (line[-1][0] - line[0][0]) * i / 8, line[0][1] + (line[-1][1] - line[0][1]) * i / 8)
        e.line([(p[0] - 11, p[1] - 3), (p[0] + 11, p[1] + 3)], fill=(110, 60, 56, 150), width=3)    # faint old stitch marks
    return Image.alpha_composite(im, sl.filter(ImageFilter.GaussianBlur(1.2)))

def cracks(n, seed, gens=5, width=9):
    rng = np.random.default_rng(seed); segs = []
    def grow(x, y, a, L, w, g):
        if g == 0 or L < 8: return
        x2, y2 = x + L * math.cos(a), y + L * math.sin(a); segs.append(((x, y), (x2, y2), w))
        grow(x2, y2, a + rng.uniform(-.5, .5), L * rng.uniform(.6, .85), w * .75, g - 1)
        if rng.random() < .6: grow(x2, y2, a + rng.choice([-1, 1]) * rng.uniform(.6, 1.2), L * .6, w * .6, g - 1)
    for k in range(4): grow(n * .5, n * .5, k * math.pi / 2 + rng.uniform(-.6, .6), n * .17, width, gens)
    return segs

def scar_carapace(n=512, seed=11):
    # broken carapace: dark split plates, raw ooze glowing in the gaps
    m = blob(n, seed, 0.33, 0.4); t = noise(n, 5, seed)
    im = rgba(np.stack([40 + 30 * t, 20 + 15 * t, 34 + 20 * t], -1), m * 150); d = ImageDraw.Draw(im)
    for (a, b, w) in cracks(n, seed, 5, 16):
        d.line([a, b], fill=GLOW['chorus'] + (230,), width=int(w)); d.line([a, b], fill=(255, 250, 190, 255), width=max(1, int(w * .3)))
    glow = im.filter(ImageFilter.GaussianBlur(10)); return Image.alpha_composite(glow, im)

def scar_porcelain(n=512, seed=13):
    im = Image.new('RGBA', (n, n), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    for (a, b, w) in cracks(n, seed, 6, 7):
        d.line([a, b], fill=(30, 26, 22, 235), width=int(w) + 2); d.line([a, b], fill=GLOW['ithar'] + (255,), width=max(1, int(w * .45)))
    chip = blob(n, seed + 4, 0.08, 0.6); im = Image.alpha_composite(rgba(np.stack([np.full((n, n), 26.0)] * 3, -1), chip * 220), im)
    glow = im.filter(ImageFilter.GaussianBlur(8)); return Image.alpha_composite(glow, im)

def scar_machine(n=512, seed=17):
    # torn plating: jagged hole, green-lit circuitry and cables inside
    m = blob(n, seed, 0.3, 0.55); t = noise(n, 4, seed)
    inner = np.stack([10 + 10 * t, 22 + 30 * t, 14 + 12 * t], -1); im = rgba(inner, m * 240); d = ImageDraw.Draw(im)
    rng = np.random.default_rng(seed)
    for k in range(9):
        y0 = n * (.3 + .4 * k / 9); d.line([(n * .25, y0), (n * .45, y0), (n * .5, y0 + 12), (n * .75, y0 + 12)], fill=(61, 255, 106, 200), width=3)
        d.ellipse([n * .45 - 4, y0 - 4, n * .45 + 4, y0 + 4], fill=(180, 255, 190, 255))
    for k in range(4):
        x0 = n * (.35 + .1 * k); d.line([(x0, n * .25), (x0 + rng.uniform(-30, 30), n * .55), (x0 + rng.uniform(-20, 20), n * .78)], fill=(20, 20, 22, 255), width=10)
    rim = (m > 0.05) & (m < 0.6); arr = np.array(im); arr[rim] = (150, 156, 150, 255); arr[..., 3] = (arr[..., 3] * m).astype(np.uint8)
    im = Image.fromarray(arr); glow = im.filter(ImageFilter.GaussianBlur(9)); return Image.alpha_composite(glow, im)

SCARS = {'burn': scar_burn, 'cyber': scar_cyber, 'eye': scar_eye, 'carapace': scar_carapace, 'porcelain': scar_porcelain, 'machine': scar_machine}
# where each scar sits relative to the portrait's face anchor (dx, dy in anchor sizes, scale)
PLACE = {'burn': (-0.25, 0.25, 1.2), 'cyber': (0.22, -0.05, 0.9), 'eye': (-0.2, -0.05, 1.1), 'carapace': (0.15, 0.1, 1.1), 'porcelain': (0.1, -0.1, 1.0), 'machine': (0.1, 0.05, 1.0)}

def composite(base, fac, scars=(), anchor=(0.5, 0.42, 0.34)):
    """the same composite the game does (portraits.gd nemesis): base, scars at the anchor, frame"""
    im = base.convert('RGBA').resize((1024, 1024)); ax, ay, s = anchor
    for k in scars:
        sc = Image.open(os.path.join(SD, 'scar_%s.png' % k)); dx, dy, ss = PLACE[k]; size = int(1024 * s * ss)
        sc = sc.resize((size, size), Image.LANCZOS); x = int(1024 * (ax + dx * s) - size / 2); y = int(1024 * (ay + dy * s) - size / 2)
        layer = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0)); layer.paste(sc, (x, y), sc); im = Image.alpha_composite(im, layer)
    return Image.alpha_composite(im, Image.open(os.path.join(ND, 'frame_%s.png' % fac)))

if __name__ == '__main__':
    os.makedirs(SD, exist_ok=True)
    for fac in TRIM: frame(fac).save(os.path.join(ND, 'frame_%s.png' % fac), optimize=True)
    for k, fn in SCARS.items(): fn().save(os.path.join(SD, 'scar_%s.png' % k), optimize=True)
    import json
    json.dump({'kinds': {k: v.split() if v != 'all' else list(TRIM) for k, v in KINDS.items()}, 'place': PLACE},
              open(os.path.join(SD, 'scars.json'), 'w'), indent=1)
    print('frames and scars written to', ND)
