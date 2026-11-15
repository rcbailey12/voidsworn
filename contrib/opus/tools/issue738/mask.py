# beauty mask for the S8 beauty (its background carries a soft light glow top left and the ship's shadowed plates are as dark as
# the background, so luminance alone fails): edges (Sobel of the lightly blurred picture over a threshold) or luminance well over
# the background, closed with a 15 px element, holes filled, the largest shape (drops the escort).
# usage: python mask.py BEAUTY.jpg OUT_MASK.png [edge threshold, default 28]
import sys, numpy as np
from PIL import Image
from scipy import ndimage
im = np.asarray(Image.open(sys.argv[1]).convert('L')).astype(float)
b = ndimage.gaussian_filter(im, 1.2)
g = np.hypot(ndimage.sobel(b, 0), ndimage.sobel(b, 1))
glow = ndimage.gaussian_filter(im, 25)
m = (g > float(sys.argv[3]) if len(sys.argv) > 3 else g > 28) | (im > glow + 25)
m = ndimage.binary_closing(m, np.ones((15, 15)))
m = ndimage.binary_fill_holes(m)
m = ndimage.binary_opening(m, np.ones((5, 5)))
lab, n = ndimage.label(m); sz = ndimage.sum(m, lab, range(1, n + 1))
m = lab == (np.argmax(sz) + 1)
Image.fromarray((m * 255).astype('uint8')).save(sys.argv[2])
print('mask', m.mean())
