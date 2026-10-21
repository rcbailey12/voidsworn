# Register a concept picture to a Pixal3D mesh in the Pixal orbit rig (fov 20, z up, az 0 = the run's first view): search azimuth and
# elevation by silhouette overlap, then fit the picture's scale and offset in 2D; writes the picture and its mask re-framed into that
# rig camera (1024 square, black backdrop), ready for project_paint.py.
# usage: blender -b -P fitcam_rig.py -- mesh.glb concept_cut.png out_prefix az0 el0 [span]
import sys, math, json, numpy as np, bpy, mathutils
from PIL import Image
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
src, cpt, outp, az0, el0 = argv[0], argv[1], argv[2], float(argv[3]), float(argv[4]); span = float(argv[5]) if len(argv) > 5 else 30
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=src)
sc = bpy.context.scene; sc.render.engine = 'BLENDER_WORKBENCH'; sc.display.shading.light = 'FLAT'; sc.display.shading.color_type = 'SINGLE'; sc.display.shading.single_color = (1, 1, 1)
sc.world = bpy.data.worlds.new('w'); sc.world.color = (0, 0, 0); R = 384; sc.render.resolution_x = sc.render.resolution_y = R
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam; cam.data.angle = math.radians(20); cam.data.sensor_fit = 'HORIZONTAL'
D = 1.1 * 0.5 / math.tan(math.radians(10))
def sil(az, el, res=R):
    sc.render.resolution_x = sc.render.resolution_y = res
    a, e = math.radians(az), math.radians(el); back = mathutils.Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e)))
    cam.location = back * D; cam.rotation_euler = (-back).to_track_quat('-Z', 'Y').to_euler()
    sc.render.filepath = outp + '_sil.png'; bpy.ops.render.render(write_still=True)
    return np.asarray(Image.open(outp + '_sil.png').convert('L')) > 40
ci = Image.open(cpt).convert('RGBA'); ca = np.asarray(ci)[..., 3] > 128; ys, xs = np.nonzero(ca); cbox = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
crop = ci.crop(cbox); cm = Image.fromarray((ca[cbox[1]:cbox[3], cbox[0]:cbox[2]] * 255).astype(np.uint8))
def place(S, sx, dx, dy, res):  # concept mask scaled to the silhouette's bbox width * sx, centred on its bbox centre + offset
    ys, xs = np.nonzero(S); w = (xs.max() - xs.min() + 1) * sx; s = w / crop.width; h = crop.height * s
    cx = (xs.min() + xs.max()) / 2 + dx; cy = (ys.min() + ys.max()) / 2 + dy
    m = Image.new('L', (res, res), 0); m.paste(cm.resize((max(1, round(w)), max(1, round(h)))), (round(cx - w / 2), round(cy - h / 2))); return np.asarray(m) > 127, (s, cx, cy, w, h)
def iou(A, B): return (A & B).sum() / max(1, (A | B).sum())
best = None
for az in np.arange(az0 - span, az0 + span + .1, 6):
    for el in np.arange(max(-20, el0 - 18), el0 + 19, 6):
        S = sil(az, el); M, _ = place(S, 1.0, 0, 0, R); v = iou(S, M)
        if best is None or v > best[0]: best = (v, az, el)
for step in (3, 1.5):
    b0 = best
    for az in (b0[1] - step, b0[1], b0[1] + step):
        for el in (b0[2] - step, b0[2], b0[2] + step):
            S = sil(az, el); M, _ = place(S, 1.0, 0, 0, R); v = iou(S, M)
            if v > best[0]: best = (v, az, el)
S = sil(best[1], best[2], 1024); bb = (1.0, 0, 0, iou(S, place(S, 1.0, 0, 0, 1024)[0]))
for sx in (0.94, 0.97, 1.0, 1.03, 1.06):
    for dx in range(-24, 25, 8):
        for dy in range(-24, 25, 8):
            v = iou(S, place(S, sx, dx, dy, 1024)[0])
            if v > bb[3]: bb = (sx, dx, dy, v)
M, (s, cx, cy, w, h) = place(S, bb[0], bb[1], bb[2], 1024)
img = Image.new('RGBA', (1024, 1024), (0, 0, 0, 255)); img.alpha_composite(crop.resize((max(1, round(w)), max(1, round(h))), Image.LANCZOS), (round(cx - w / 2), round(cy - h / 2)))
img.convert('RGB').save(outp + '.png'); Image.fromarray((M * 255).astype(np.uint8)).save(outp + '_mask.png')
Image.fromarray(np.dstack([S * 255, M * 255, np.zeros_like(M)]).astype(np.uint8)).save(outp + '_overlap.png')
r = {'az': float(best[1]), 'el': float(best[2]), 'iou_coarse': float(best[0]), 'iou': float(bb[3]), 'sx': bb[0], 'dx': bb[1], 'dy': bb[2]}
json.dump(r, open(outp + '.json', 'w')); print('FIT', json.dumps(r))
