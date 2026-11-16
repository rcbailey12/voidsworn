# the E14 beauty's outline mask for the camera fit (issue 782), after the first sheet's camera note: luminance over 9 (the dark
# lower plates read at 10 to 14), the sky's
# teal and blue nebula left out (dim pixels greener or bluer than red), closed, holes filled, the largest shape; the engine's
# light ring and its glow (right of x 1290 in the 1920 picture, where the spar ends) cut away, since the build's engine has no
# glow. Then the ring's open middle is cut back out (the upright ring of the build is open there too): the sky pixels inside
# the plates' inner edges (a hand ellipse round the picture's ring centre, 590, 640): the teal sky there (green 9 or more over
# red, dim), closed with a 31 px square so the small drones in it drop out; the violet gun heart and spar stay.
# usage: python mask_e14.py BEAUTY.jpg OUT_MASK.png
import sys, numpy as np
from PIL import Image
from scipy import ndimage
rgb = np.asarray(Image.open(sys.argv[1]).convert('RGB')).astype(float)
lum = rgb @ np.array([0.299, 0.587, 0.114])
ship = (lum > 9) & ~(((rgb[..., 1] > rgb[..., 0] + 6) | (rgb[..., 2] > rgb[..., 0] + 10)) & (lum < 45))
m = ship.copy()
m[:, 1290:] = False
m[:275, :245] = False; m[:85, :340] = False      # the bright nebula top left, above and left of the upper plates (a hand box)
m = ndimage.binary_closing(m, np.ones((15, 15)))
m = ndimage.binary_fill_holes(m)
lab, n = ndimage.label(m)
if n:
    sizes = ndimage.sum(m, lab, range(1, n + 1)); m = lab == (1 + int(np.argmax(sizes)))
yy, xx = np.mgrid[:m.shape[0], :m.shape[1]]
inner = ((xx - 590) / 300.0) ** 2 + ((yy - 640) / 330.0) ** 2 <= 1.0     # inside the plates' inner edges (a hand ellipse)
sky = (rgb[..., 1] >= rgb[..., 0] + 9) & (lum < 40)                             # the teal sky seen through the ring
m = m & ~(inner & ndimage.binary_closing(sky, np.ones((31, 31))))
Image.fromarray((m * 255).astype(np.uint8)).save(sys.argv[2])
print('mask', sys.argv[2], 'cover', round(float(m.mean()), 3))
