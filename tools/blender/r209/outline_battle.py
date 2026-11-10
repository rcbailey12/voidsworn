# Issue 209 round 8, step 4: the outline gate at the battle camera too (R160 (f): "the outline gate gets a second camera, the
# battle camera"). The concept is one painting from one camera, so at the battle camera there is no concept outline to compare
# with. The reference here is B0, the whole-hull TRELLIS generation made from the concept (the recipe's stage 2 shape reference,
# yaw fixed): the AI's reading of the concept, not the concept itself. Read the numbers as "does the hull still agree with the
# shape reference from where the game is played", never as a concept match.
# Two battle cameras, both orthographic (at r 170 the game's 45 degree lens is nearly parallel over one ship):
#   game    the game's default camera (godot/render/camera_rig.gd: b 0.98 rad from straight up, so 34 degrees above the board),
#           looking at the ship's port beam (the outline is the same either way round)
#   studio  render.py's battle view (55 degrees up, azimuth 150), the studio battle camera of rounds 4 to 7
# Scored at 4x the ship's true size in the game (about 180 px long at 1080p, so about 720 px here) so one pixel of noise does not
# move the number; per third as outline_thirds.py (x above +1/6 bow, below -1/6 stern).
# usage: python3 outline_battle.py OUT_DIR ref=B0.npz name=cell.npz[,name=cell.npz...]
import sys, os, json, math
import numpy as np
from PIL import Image, ImageDraw

CAMS = dict(game=(math.degrees(math.pi / 2 - .98), 90.0), studio=(55.0, 150.0))
LEN_PX = 720; N = (1000, 640)


def basis(el, az):
    el, az = math.radians(el), math.radians(az)
    d = np.array([math.cos(el) * math.cos(az), math.cos(el) * math.sin(az), math.sin(el)])     # toward the camera
    f = -d; r = np.cross(f, (0, 0, 1)); r /= np.linalg.norm(r); u = np.cross(r, f)
    return f, r, u


def raster(T, cam, label=None):
    f, r, u = basis(*cam); k = LEN_PX / 1.0
    P = T.reshape(-1, 3); uv = np.stack([N[0] / 2 + k * (P @ r), N[1] / 2 - k * (P @ u)], -1).reshape(-1, 3, 2)
    im = Image.new('L', N, 0); d = ImageDraw.Draw(im)
    if label is None:
        for t in uv.reshape(-1, 6).tolist(): d.polygon(t, fill=255)
        return np.asarray(im) > 0
    z = (T.mean(1) @ f); o = np.argsort(-z)
    for i in o: d.polygon(uv[i].ravel().tolist(), fill=int(label[i]))
    return np.asarray(im)


def run(out, ref, cells):
    os.makedirs(out, exist_ok=True); R = np.load(ref)['tris'].astype(np.float64); res = {}
    for spec in cells:
        name, path = spec.split('=', 1); T = np.load(path)['tris'].astype(np.float64); res[name] = {}
        x = T.mean(1)[:, 0]; lab = np.where(x > 1 / 6, 1, np.where(x < -1 / 6, 3, 2)).astype(np.uint8)
        for cn, cam in CAMS.items():
            M = raster(T, cam); B = raster(R, cam); L = raster(T, cam, lab)
            from scipy import ndimage
            idx = ndimage.distance_transform_edt(L == 0, return_distances=False, return_indices=True); L = L[idx[0], idx[1]]
            r = {t: round(100 * (B & M & (L == k)).sum() / max(1, ((B | M) & (L == k)).sum()), 1) for k, t in enumerate(('bow', 'midship', 'stern'), 1)}
            r['whole'] = round(100 * (B & M).sum() / (B | M).sum(), 1); res[name][cn] = r
            ov = np.full(N[::-1] + (3,), 24, np.uint8); ov[B & M] = (40, 150, 60); ov[B & ~M] = (215, 45, 40); ov[M & ~B] = (235, 200, 40)
            Image.fromarray(ov).save(os.path.join(out, f'battle_{cn}_{name}.png'))
        print('[battle]', name, json.dumps(res[name]), flush=True)
    json.dump(dict(note='outline_battle.py: overlap per third at the two battle cameras against B0 (the shape reference), not the concept.',
                   cells=res), open(os.path.join(out, 'outline_battle.json'), 'w'), indent=1)


if __name__ == '__main__':
    a = sys.argv[1:]; ref = [x for x in a if x.startswith('ref=')][0][4:]
    run(a[0], ref, [c for x in a[1:] if not x.startswith('ref=') for c in x.split(',')])
