# Issue 209 round 8: the near (port) bow deck edge against the concept's, at the concept camera. The concept's edge is traced by eye
# (docs/shots/ship_pipeline/route209/round8/concept_bow_trace.json); the model's is the deck lip line (y = Ws + 0.003, z = deck)
# from a cell's bow knots. Reports the mean distance in px at 1024 and draws all of them on the concept.
# usage: python3 deck_line.py OUT_DIR   (writes OUT_DIR/deck_line.json and deckline.png; plain Python)
import os, sys, json, re
import numpy as np
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import silhouette4 as S4
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
CON = os.path.join(REPO, 'docs/ship_pipeline/concepts/C15s_23.webp'); CAM = os.path.join(REPO, 'docs/shots/ship_pipeline/route209/round4/concept_camera.json')
TR = json.load(open(os.path.join(REPO, 'docs/shots/ship_pipeline/route209/round8/concept_bow_trace.json')))
cam = json.load(open(CAM))['camera']; L = np.array(TR['deck_edge_port'], float)


def line(K):
    xs = np.linspace(.22, K[-1][0] - .002, 40)
    zt = np.interp(xs, [k[0] for k in K], [k[1] for k in K]); ws = np.interp(xs, [k[0] for k in K], [k[3] for k in K]) + .003
    return S4.project(np.stack([xs, ws, zt + .0014], 1), cam)


def dist(uv):
    a, b = L[:-1], L[1:]; d = b - a
    t = np.clip(((uv[:, None, :] - a[None]) * d[None]).sum(-1) / (d * d).sum(-1)[None], 0, 1); q = a[None] + t[..., None] * d[None]
    return float(np.linalg.norm(uv[:, None, :] - q, axis=-1).min(1).mean())


src = open(os.path.join(HERE, 'armA7.py')).read(); B7 = eval('[' + re.search(r'BOW = \[(.*?)\n\]', src, re.S).group(1) + ']')
cells = dict(Ab7=B7, Ab8try1=json.load(open(os.path.join(HERE, 'fit8_bow_try1.json')))['bow'], Ab8=json.load(open(os.path.join(HERE, 'fit8_bow.json')))['bow'])
out = sys.argv[1]; os.makedirs(out, exist_ok=True); res = {}
im = Image.open(CON).convert('RGBA'); bg = Image.new('RGBA', im.size, (30, 30, 34, 255)); bg.alpha_composite(im); im = bg.convert('RGB'); d = ImageDraw.Draw(im)
d.line([tuple(p) for p in L], fill=(255, 255, 255), width=3)
for n, col in (('Ab7', (255, 230, 0)), ('Ab8try1', (255, 140, 0)), ('Ab8', (0, 255, 80))):
    uv = line(cells[n]); res[n] = round(dist(uv), 1); d.line([tuple(p) for p in uv], fill=col, width=3)
im.crop((0, 330, 640, 740)).save(os.path.join(out, 'deckline.png'))
json.dump(res, open(os.path.join(out, 'deck_line.json'), 'w'), indent=1); print('[deck]', res)
