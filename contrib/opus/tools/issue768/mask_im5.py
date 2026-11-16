# The IM5 beauty's outline mask for the camera fit (issue 768). IM5.jpg carries its own "IM5" label in the lower left corner and
# blue engine plumes above the stern: the label is blanked first, then contrib/opus/tools/issue738/mask.py makes the mask (edges
# or luminance over the background, closed, filled, the largest shape), then the plumes above the stern edge are cut away (two
# straight lines along the stern edge as the picture draws it) and the largest shape is kept.
# usage: python mask_im5.py IM5.jpg OUT_DIR   (writes OUT_DIR/IM5_nolabel.png and OUT_DIR/mask.png; Python, numpy, scipy, Pillow)
import os, subprocess, sys
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
src, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
im = Image.open(src).convert('RGB')
ImageDraw.Draw(im).rectangle((0, 625, 130, 720), fill=(0, 0, 0))
im.save(os.path.join(out, 'IM5_nolabel.png'))
here = os.path.dirname(os.path.abspath(__file__))
subprocess.check_call([sys.executable, os.path.join(here, '..', 'issue738', 'mask.py'), os.path.join(out, 'IM5_nolabel.png'), os.path.join(out, 'mask.png')])
m = np.asarray(Image.open(os.path.join(out, 'mask.png'))) > 127
H, W = m.shape
yy, xx = np.mgrid[0:H, 0:W]
cut = ((xx >= 590) & (xx <= 935) & (yy < 74 + (xx - 620) * 28 / 315)) | ((xx > 935) & (yy < 100 + (xx - 935) * 0.95))
m = m & ~cut
lab, n = ndimage.label(m)
sz = ndimage.sum(m, lab, range(1, n + 1))
m = lab == (np.argmax(sz) + 1)
Image.fromarray((m * 255).astype('uint8')).save(os.path.join(out, 'mask.png'))
print('mask', round(float(m.mean()), 4))
