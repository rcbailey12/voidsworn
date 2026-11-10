# Issue 209 round 7: the outline gate per third and the inner edge check (outside audit pass 2, finding 13: one whole-ship
# number let a wrong bow through). Plain Python: numpy, scipy, Pillow; reuses silhouette4.py's concept camera and raster.
#   thirds  every pixel of the concept frame is labelled bow, midship or stern from the cell's own geometry (triangle centre
#           x > +1/6 bow, x < -1/6 stern, nearest visible triangle wins; concept pixels outside the cell take the label of the
#           nearest labelled pixel), then the overlap (intersection over union) is scored inside each third.
#   edges   inner edges, not only the outline: the concept's edges (luminance gradient of the painting) and the cell's edges
#           (gradient of a flat-shaded render through the same camera, so paint does not count) are found inside the ship,
#           and each cell edge pixel is measured to the nearest concept edge (and back). Reported per third: the median
#           distance and the share within 6 px at the concept's 1024 px. These are automatic edges (deck edge, chine, bow
#           profile and casemate frames are among them), not hand-traced named lines.
# usage: python3 outline_thirds.py CONCEPT.png CAM.json OUT_DIR name=cell.npz[,name=cell.npz...]
#   writes OUT_DIR/thirds_<name>.png, edges_<name>.png and outline_thirds.json
import sys, os, json
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import silhouette4 as S

N = S.N
THIRDS = ('bow', 'midship', 'stern')


def painter(T, p, value):
    """draw triangles far to near; value: (M,) uint8 per triangle; returns the image of the nearest triangle's value"""
    pos, f, r, u = S.cam_basis(p); c = T.mean(1); z = (c - pos) @ f; o = np.argsort(-z); uv = S.project(T, p)
    im = Image.new('L', (N, N), 0); from PIL import ImageDraw; d = ImageDraw.Draw(im)
    for i in o: d.polygon(uv[i].ravel().tolist(), fill=int(value[i]))
    return np.asarray(im)


def shade_values(T, p):
    pos, f, r, u = S.cam_basis(p)
    n = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0]); n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)
    vd = T.mean(1) - pos; n[(n * vd).sum(1) > 0] *= -1
    L = np.array([.35, .55, .76]); L /= np.linalg.norm(L); L2 = np.array([-.6, .2, .3]); L2 /= np.linalg.norm(L2)
    return np.clip(30 + 160 * np.clip(n @ L, 0, 1) + 60 * np.clip(n @ L2, 0, 1), 1, 255).astype(np.uint8)


def edges(gray, mask, keep=0.14):
    g = ndimage.gaussian_filter(gray.astype(float), 1.2)
    m = np.hypot(ndimage.sobel(g, 0), ndimage.sobel(g, 1))
    inner = ndimage.binary_erosion(mask, iterations=4)
    v = m[inner]; thr = np.quantile(v, 1 - keep) if v.size else 1e9
    return inner & (m >= thr)


def run(concept, camj, outdir, cells):
    os.makedirs(outdir, exist_ok=True)
    p = json.load(open(camj))['camera']; C = S.concept_mask(concept)
    cg = np.asarray(Image.open(concept).convert('L').resize((N, N), Image.LANCZOS))
    CE = edges(cg, C); dC = ndimage.distance_transform_edt(~CE)
    res = {}
    for spec in cells:
        name, path = spec.split('=', 1); T = np.load(path)['tris'].astype(np.float64)
        x = T.mean(1)[:, 0]; lab = np.where(x > 1 / 6, 1, np.where(x < -1 / 6, 3, 2)).astype(np.uint8)
        Lm = painter(T, p, lab); M = Lm > 0
        idx = ndimage.distance_transform_edt(~M, return_distances=False, return_indices=True)
        Lfull = Lm[idx[0], idx[1]]
        shade = painter(T, p, shade_values(T, p))
        ME = edges(shade, M & C); dM = ndimage.distance_transform_edt(~ME)
        r = {}
        for k, t in enumerate(THIRDS, 1):
            R = Lfull == k; inter = (C & M & R).sum(); uni = ((C | M) & R).sum()
            me = ME & R; ce = CE & R & M
            r[t] = dict(overlap=round(100 * inter / max(1, uni), 1), concept_covered=round(100 * inter / max(1, (C & R).sum()), 1),
                        cell_outside=round(100 * (M & ~C & R).sum() / max(1, (M & R).sum()), 1),
                        edge_cell_to_concept_median_px=round(float(np.median(dC[me])) if me.any() else -1, 1),
                        edge_cell_within_6px=round(100 * float((dC[me] <= 6).mean()) if me.any() else 0, 1),
                        edge_concept_to_cell_median_px=round(float(np.median(dM[ce])) if ce.any() else -1, 1),
                        edge_concept_within_6px=round(100 * float((dM[ce] <= 6).mean()) if ce.any() else 0, 1))
        r['whole'] = dict(overlap=round(100 * (C & M).sum() / (C | M).sum(), 1))
        res[name] = r; print('[thirds]', name, json.dumps(r), flush=True)
        # overlays: thirds (outline colours as silhouette4, third borders in white) and edges
        ov = np.asarray(S.overlay(C, M, concept)).copy()
        bord = (ndimage.grey_dilation(Lfull, 3) != ndimage.grey_erosion(Lfull, 3)) & (C | M)
        ov[bord] = (255, 255, 255); Image.fromarray(ov).save(os.path.join(outdir, f'thirds_{name}.png'))
        base = np.asarray(Image.open(concept).convert('RGB').resize((N, N))).astype(np.float32) * .35 + 8
        e = base.copy(); e[CE] = (40, 220, 255); e[ME] = (255, 60, 220); e[CE & ME] = (255, 255, 255)
        Image.fromarray(e.clip(0, 255).astype(np.uint8)).save(os.path.join(outdir, f'edges_{name}.png'))
        Image.fromarray(shade).save(os.path.join(outdir, f'shade_{name}.png'))
    json.dump(dict(note='outline_thirds.py: overlap per third at the concept camera, and the inner edge distances (px at 1024).', cells=res),
              open(os.path.join(outdir, 'outline_thirds.json'), 'w'), indent=1)


if __name__ == '__main__':
    run(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4].split(','))
