# A4: quick inspection sheets for a hull (cloud or PC). Workbench clay renders (fast, no GPU needed) with a coordinate grid, so cut boxes,
# hard points and part positions can be read straight off the picture. Frame: the A4 working frame (frame.py: bow +x, port +y, up +z).
# usage: python3 look.py OUT_DIR CODE [CODE ...]            (hull from hulls_hi/ in the repo, or A4_ROOT)
#        python3 look.py OUT_DIR --glb FILE.glb [...]        (any glb in the game frame, e.g. an A4 export)
# Panels: top (bow right, port up), side from starboard (bow right), below (bow right, starboard up), bow-on, stern-on, three-quarter.
import sys, os, math
HERE = os.path.dirname(os.path.abspath(__file__))
for p in (HERE, os.path.join(HERE, '..', 'a2detail'), os.path.join(HERE, '..', 'hs')):
    if p not in sys.path: sys.path.insert(0, p)
import numpy as np
import bpy
from mathutils import Vector

FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
PX = 620  # panel height in pixels for the ortho views


def setup(color='MATERIAL'):
    """color: 'MATERIAL' (plain clay) or 'VERTEX' (the build's flat part colours, attribute Col)"""
    sc = bpy.context.scene; sc.render.engine = 'BLENDER_WORKBENCH'
    sh = sc.display.shading; sh.light = 'STUDIO'; sh.color_type = color
    try: sh.show_cavity = True; sh.cavity_type = 'BOTH'; sh.curvature_ridge_factor = 1.0; sh.curvature_valley_factor = 1.0
    except Exception: pass
    try: sh.show_shadows = True; sh.shadow_intensity = .35
    except Exception: pass
    sc.display.shading.background_type = 'VIEWPORT' if hasattr(sc.display.shading, 'background_type') else None
    sc.render.film_transparent = False
    try: sc.world = bpy.data.worlds.new('w'); sc.world.color = (.11, .115, .13)
    except Exception: pass
    sc.view_settings.view_transform = 'Standard'
    return sc


def load_code(root, code, yaw=0):
    """the raw hull in the A4 working frame (frame.py: x bow, y port, z up, true chirality)"""
    import frame, blmesh
    h = frame.load(root, code, yaw)
    o = blmesh.mesh_from_arrays(code, h['pos'], h['idx'], nor=h['nor'])
    return [o]


def load_glb(path):
    before = set(bpy.context.scene.objects); bpy.ops.import_scene.gltf(filepath=path)
    return [o for o in set(bpy.context.scene.objects) - before if o.type == 'MESH']


def bounds(objs):
    mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
    for o in objs:
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c); mn = Vector(map(min, mn, w)); mx = Vector(map(max, mx, w))
    return mn, mx


def cam(sc):
    c = bpy.data.objects.get('lookcam')
    if not c: c = bpy.data.objects.new('lookcam', bpy.data.cameras.new('lookcam')); sc.collection.objects.link(c)
    sc.camera = c; c.data.clip_start = .001; c.data.clip_end = 100; return c


# ortho views: (name, camera direction from target, euler, image right axis, image up axis) in the Blender frame
VIEWS = [('top', (0, 0, 1), (0, 0, 0), 'x', 'y'), ('side', (0, -1, 0), (math.pi / 2, 0, 0), 'x', 'z'), ('below', (0, 0, -1), (math.pi, 0, 0), 'x', '-y'),
         ('bow', (1, 0, 0), (math.pi / 2, 0, math.pi / 2), 'y', 'z'), ('stern', (-1, 0, 0), (math.pi / 2, 0, -math.pi / 2), '-y', 'z')]


def render(objs, out, title, sub=''):
    from PIL import Image, ImageDraw, ImageFont
    sc = bpy.context.scene; c = cam(sc); mn, mx = bounds(objs); ctr = (mn + mx) / 2; ext = mx - mn; L = max(ext)
    ax = {'x': 0, 'y': 1, 'z': 2}; panels = []; tmp = out + '_tmp.png'
    for name, d, rot, ra, ua in VIEWS:
        rs = -1 if ra[0] == '-' else 1; us = -1 if ua[0] == '-' else 1; ri, ui = ax[ra[-1]], ax[ua[-1]]
        w_u = ext[ri] * 1.12 + .02; h_u = ext[ui] * 1.12 + .02; scale = max(w_u, h_u)
        W = int(PX * w_u / h_u) if w_u > h_u else PX; H = PX if w_u > h_u else int(PX * h_u / w_u)
        W = max(240, min(W, 1500)); H = max(200, min(H, 900))
        sc.render.resolution_x, sc.render.resolution_y = W, H; sc.render.resolution_percentage = 100
        c.data.type = 'ORTHO'; c.data.ortho_scale = scale if W >= H else scale * W / H
        if W >= H: c.data.ortho_scale = max(w_u, h_u * W / H)
        else: c.data.ortho_scale = max(h_u, w_u * H / W)
        c.location = ctr + Vector(d) * L * 3; c.rotation_euler = rot; sc.render.filepath = tmp; bpy.ops.render.render(write_still=True)
        im = Image.open(tmp).convert('RGB'); dr = ImageDraw.Draw(im); f = ImageFont.truetype(FONT, 12)
        upp = c.data.ortho_scale / max(W, H)  # units per pixel
        def px(u, v): return (W / 2 + (u - ctr[ri] * rs) / upp, H / 2 - (v - ctr[ui] * us) / upp)
        for k in np.arange(-1, 1.0001, .05):  # grid every 0.05, labelled every 0.1
            x, _ = px(k, 0); y = px(0, k)[1]; maj = abs(round(k * 10) - k * 10) < 1e-6
            if 0 <= x < W: dr.line([(x, 0), (x, H)], fill=(70, 90, 120) if maj else (48, 56, 70)); maj and dr.text((x + 2, H - 14), f'{k * rs:+.1f}', font=f, fill=(150, 180, 220))
            if 0 <= y < H: dr.line([(0, y), (W, y)], fill=(70, 90, 120) if maj else (48, 56, 70)); maj and dr.text((2, y + 1), f'{k * us:+.1f}', font=f, fill=(150, 180, 220))
        im2 = Image.open(tmp).convert('RGB'); im = Image.blend(im, im2, .55)  # grid faint over the ship
        dr = ImageDraw.Draw(im); dr.text((6, 4), f'{name}: right {ra}, up {ua}', font=ImageFont.truetype(FONT, 14), fill=(235, 235, 235)); panels.append(im)
    # three-quarter perspective
    sc.render.resolution_x, sc.render.resolution_y = 900, 560; c.data.type = 'PERSP'; c.data.lens = 50
    loc = ctr + Vector((.9, -1.1, .75)).normalized() * L * 2.1; c.location = loc; c.rotation_euler = (ctr - loc).to_track_quat('-Z', 'Y').to_euler()
    sc.render.filepath = tmp; bpy.ops.render.render(write_still=True); panels.append(Image.open(tmp).convert('RGB'))
    os.remove(tmp)
    rows = [panels[0:2], panels[2:4], panels[4:6]]; Wt = max(sum(p.size[0] for p in r) for r in rows) + 10
    Ht = sum(max(p.size[1] for p in r) for r in rows) + 40
    sheet = Image.new('RGB', (Wt, Ht), (18, 18, 22)); y = 36
    ImageDraw.Draw(sheet).text((8, 8), f'{title}  {sub}  extent x {ext.x:.3f} y {ext.y:.3f} z {ext.z:.3f}', font=ImageFont.truetype(FONT, 18), fill=(240, 240, 240))
    for r in rows:
        x = 4
        for p in r: sheet.paste(p, (x, y)); x += p.size[0] + 4
        y += max(p.size[1] for p in r)
    sheet.save(out); print('look:', out, flush=True)


def closeups(objs, out, title):
    """the blob sweep in perspective: bow, midship and stern thirds, each from high and low quarters (port and starboard alternate)"""
    from PIL import Image, ImageDraw, ImageFont
    sc = bpy.context.scene; c = cam(sc); mn, mx = bounds(objs); ext = mx - mn; L = max(ext); tmp = out + '_tmp.png'; panels = []
    sc.render.resolution_x, sc.render.resolution_y = 760, 470; c.data.type = 'PERSP'; c.data.lens = 40
    for reg, xf in (('stern', .17), ('mid', .5), ('bow', .83)):
        tgt = Vector((mn.x + ext.x * xf, (mn.y + mx.y) / 2, (mn.z + mx.z) / 2))
        for lab, d in (('high', Vector((.25 if reg != 'stern' else -.55, .8, .62))), ('low', Vector((.25 if reg != 'stern' else -.55, -.8, -.55)))):
            if reg == 'bow': d.x = .65
            loc = tgt + d.normalized() * L * .55; c.location = loc; c.rotation_euler = (tgt - loc).to_track_quat('-Z', 'Y').to_euler()
            sc.render.filepath = tmp; bpy.ops.render.render(write_still=True); im = Image.open(tmp).convert('RGB')
            ImageDraw.Draw(im).text((6, 4), f'{reg} {lab} ({"port" if d.y > 0 else "starboard"} quarter)', font=ImageFont.truetype(FONT, 15), fill=(235, 235, 235)); panels.append(im)
    os.remove(tmp)
    sheet = Image.new('RGB', (760 * 2 + 4, 470 * 3 + 40), (18, 18, 22)); ImageDraw.Draw(sheet).text((8, 8), f'{title}  close-ups (blob sweep)', font=ImageFont.truetype(FONT, 18), fill=(240, 240, 240))
    for k, p in enumerate(panels): sheet.paste(p, ((k % 2) * 764, 36 + (k // 2) * 470))
    sheet.save(out); print('look:', out, flush=True)


def main():
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    out = a[0]; os.makedirs(out, exist_ok=True)
    root = os.environ.get('A4_ROOT') or os.path.abspath(os.path.join(HERE, '..', '..', '..'))
    items = a[1:]; glb = False
    if items and items[0] == '--glb': glb = True; items = items[1:]
    for it in items:
        bpy.ops.wm.read_factory_settings(use_empty=True); setup()
        yaw = int(os.environ.get('YAW', '0'))
        if not glb and not yaw:
            try:
                import ships; yaw = ships.SHIPS.get(it, {}).get('yaw', 0)
            except Exception: pass
        objs = load_glb(it) if glb else load_code(root, it, yaw)
        nm = os.path.splitext(os.path.basename(it))[0]
        render(objs, os.path.join(out, nm + '_look.png'), nm, 'glb' if glb else 'hulls_hi')


if __name__ == '__main__':
    main()
