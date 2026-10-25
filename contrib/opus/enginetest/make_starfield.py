# A2 engine test: one shared equirectangular star background (4096 x 2048 PNG), the same file in both engines.
import numpy as np
from PIL import Image, ImageFilter
W, H = 4096, 2048; rng = np.random.default_rng(7)
img = np.zeros((H, W, 3), np.float32)
yy, xx = np.mgrid[0:H, 0:W]
# faint nebula: a few soft colour blobs
for cx, cy, r, col in ((0.30, 0.42, 0.22, (0.10, 0.06, 0.16)), (0.68, 0.55, 0.18, (0.04, 0.07, 0.14)), (0.52, 0.35, 0.12, (0.12, 0.05, 0.05))):
    d = ((xx / W - cx) ** 2 * 4 + (yy / H - cy) ** 2) / r ** 2; img += np.exp(-d)[..., None] * np.array(col, np.float32)
# stars: many dim, few bright; denser toward a faint band
n = 26000; sx = rng.integers(0, W, n); band = rng.normal(0.5, 0.18, n); sy = np.clip((band * H).astype(int), 0, H - 1)
b = rng.power(6, n) * 0.9 + 0.08; tint = rng.choice([(1, .95, .9), (.85, .9, 1), (1, .85, .7), (1, 1, 1)], n)
img[sy, sx] += (b[:, None] * np.array(tint, np.float32))
out = Image.fromarray((np.clip(img, 0, 1) ** (1 / 2.2) * 255).astype(np.uint8))
glow = out.filter(ImageFilter.GaussianBlur(1.2)); out = Image.blend(out, glow, 0.35)
out.save('starfield_4k.png', optimize=True); print('ok')
