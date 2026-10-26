# A4: quick inspection sheets for a hull (cloud or PC). Workbench clay renders (fast) with a coordinate grid, so cut boxes, hard points
# and part positions can be read straight off the picture. Frame: the A4 working frame (frame.py: bow +x, port +y, up +z).
# usage: python3 look.py OUT_DIR CODE [CODE ...]            (hull from hulls_hi/ in the repo, or A4_ROOT; yaw from ships.py, or env YAW)
#        python3 look.py OUT_DIR --glb FILE.glb [...]        (any glb)
#        python look.py --compose LAYOUT.json [...]          (sheets only: Blender 4.5's Python has no PIL, so the PC job composes in ComfyUI's)
# Panels: top (bow right, port up), side from starboard (bow right), below (bow right, starboard up), bow-on, stern-on, three-quarter.
# Close-ups (closeups()): bow, midship and stern thirds from high and low quarters, for the blob sweep.
import sys, os, math, json
HERE = os.path.dirname(os.path.abspath(__file__))
for p in (HERE, os.path.join(HERE, '..', 'a2detail'), os.path.join(HERE, '..', 'hs')):
    if p not in sys.path: sys.path.insert(0, p)
PX = 620  # panel height in pixels for the ortho views


def font(n):
    from PIL import ImageFont
    for f in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/arial.ttf', 'arial.ttf'):
        try: return ImageFont.truetype(f, n)
        except Exception: pass
    return ImageFont.load_default()


def setup(color='MATERIAL'):
    """color: 'MATERIAL' (plain clay) or 'VERTEX' (the build's flat part colours, attribute Col)"""
    import bpy
    sc = bpy.context.scene; sc.render.engine = 'BLENDER_WORKBENCH'
    sh = sc.display.shading; sh.light = 'STUDIO'; sh.color_type = color
    try: sh.show_cavity = True; sh.cavity_type = 'BOTH'; sh.curvature_ridge_factor = 1.0; sh.curvature_valley_factor = 1.0
    except Exception: pass
    try: sh.show_shadows = True; sh.shadow_intensity = .35
    except Exception: pass
    sc.render.film_transparent = False
    try: sc.world = bpy.data.worlds.new('w'); sc.world.color = (.11, .115, .13)
    except Exception: pass
    sc.view_settings.view_transform = 'Standard'
    return sc


def load_code(root, code, yaw=0):
    """the raw hull in the A4 working frame (frame.py: x bow, y port, z up, true chirality)"""
    import frame, blmesh
    h = frame.load(root, code, yaw)
    return [blmesh.mesh_from_arrays(code, h['pos'], h['idx'], nor=h['nor'])]


def load_glb(path):
    import bpy
    before = set(bpy.context.scene.objects); bpy.ops.import_scene.gltf(filepath=path)
    return [o for o in set(bpy.context.scene.objects) - before if o.type == 'MESH']


def bounds(objs):
    from mathutils import Vector
    mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
    for o in objs:
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c); mn = Vector(map(min, mn, w)); mx = Vector(map(max, mx, w))
    return mn, mx


def cam(sc):
    import bpy
    c = bpy.data.objects.get('lookcam')
    if not c: c = bpy.data.objects.new('lookcam', bpy.data.cameras.new('lookcam')); sc.collection.objects.link(c)
    sc.camera = c; c.data.clip_start = .001; c.data.clip_end = 100; return c


# ortho views: (name, camera direction from target, euler, image right axis, image up axis) in the working frame
VIEWS = [('top', (0, 0, 1), (0, 0, 0), 'x', 'y'), ('side', (0, -1, 0), (math.pi / 2, 0, 0), 'x', 'z'), ('below', (0, 0, -1), (math.pi, 0, 0), 'x', '-y'),
         ('bow', (1, 0, 0), (math.pi / 2, 0, math.pi / 2), 'y', 'z'), ('stern', (-1, 0, 0), (math.pi / 2, 0, -math.pi / 2), '-y', 'z')]


def render(objs, out, title, sub=''):
    """render the panels next to out, write out + '_layout.json', and compose the sheet when PIL is here"""
    import bpy
    from mathutils import Vector
    sc = bpy.context.scene; c = cam(sc); mn, mx = bounds(objs); ctr = (mn + mx) / 2; ext = mx - mn; L = max(ext)
    ax = {'x': 0, 'y': 1, 'z': 2}; panels = []
    for name, d, rot, ra, ua in VIEWS:
        rs = -1 if ra[0] == '-' else 1; us = -1 if ua[0] == '-' else 1; ri, ui = ax[ra[-1]], ax[ua[-1]]
        w_u = ext[ri] * 1.12 + .02; h_u = ext[ui] * 1.12 + .02
        W = int(PX * w_u / h_u) if w_u > h_u else PX; H = PX if w_u > h_u else int(PX * h_u / w_u)
        W = max(240, min(W, 1500)); H = max(200, min(H, 900))
        sc.render.resolution_x, sc.render.resolution_y = W, H; sc.render.resolution_percentage = 100
        c.data.type = 'ORTHO'
        c.data.ortho_scale = max(w_u, h_u * W / H) if W >= H else max(h_u, w_u * H / W)
        c.location = ctr + Vector(d) * L * 3; c.rotation_euler = rot; p = f'{out}_{name}.png'; sc.render.filepath = p; bpy.ops.render.render(write_still=True)
        panels.append(dict(path=p, name=name, W=W, H=H, upp=c.data.ortho_scale / max(W, H), cr=ctr[ri] * rs, cu=ctr[ui] * us, rs=rs, us=us, ra=ra, ua=ua, grid=True))
    sc.render.resolution_x, sc.render.resolution_y = 900, 560; c.data.type = 'PERSP'; c.data.lens = 50
    loc = ctr + Vector((.9, -1.1, .75)).normalized() * L * 2.1; c.location = loc; c.rotation_euler = (ctr - loc).to_track_quat('-Z', 'Y').to_euler()
    p = f'{out}_q.png'; sc.render.filepath = p; bpy.ops.render.render(write_still=True); panels.append(dict(path=p, name='three-quarter', grid=False))
    lay = dict(kind='views', out=out, title=f'{title}  {sub}  extent x {ext.x:.3f} y {ext.y:.3f} z {ext.z:.3f}', panels=panels)
    _finish(lay)


def closeups(objs, out, title):
    """the blob sweep in perspective: bow, midship and stern thirds, each from high and low quarters (port and starboard alternate)"""
    import bpy
    from mathutils import Vector
    sc = bpy.context.scene; c = cam(sc); mn, mx = bounds(objs); ext = mx - mn; L = max(ext); panels = []
    sc.render.resolution_x, sc.render.resolution_y = 760, 470; c.data.type = 'PERSP'; c.data.lens = 40
    for reg, xf in (('stern', .17), ('mid', .5), ('bow', .83)):
        tgt = Vector((mn.x + ext.x * xf, (mn.y + mx.y) / 2, (mn.z + mx.z) / 2))
        for lab, d in (('high', Vector((.25 if reg != 'stern' else -.55, .8, .62))), ('low', Vector((.25 if reg != 'stern' else -.55, -.8, -.55)))):
            if reg == 'bow': d.x = .65
            loc = tgt + d.normalized() * L * .55; c.location = loc; c.rotation_euler = (tgt - loc).to_track_quat('-Z', 'Y').to_euler()
            p = f'{out}_{reg}_{lab}.png'; sc.render.filepath = p; bpy.ops.render.render(write_still=True)
            panels.append(dict(path=p, name=f'{reg} {lab} ({"port" if d.y > 0 else "starboard"} quarter)', grid=False))
    _finish(dict(kind='close', out=out, title=f'{title}  close-ups (blob sweep)', panels=panels))


def _finish(lay):
    json.dump(lay, open(lay['out'] + '_layout.json', 'w'), indent=1)
    try: compose(lay['out'] + '_layout.json')
    except ImportError: print('look: panels rendered; compose with: python look.py --compose', lay['out'] + '_layout.json', flush=True)


def compose(lay_path):
    from PIL import Image, ImageDraw
    L = json.load(open(lay_path)); ims = []
    for P in L['panels']:
        im = Image.open(P['path']).convert('RGB')
        if P.get('grid'):
            W, H, upp = P['W'], P['H'], P['upp']; base = im.copy(); dr = ImageDraw.Draw(im); f = font(12)
            px = lambda u: W / 2 + (u - P['cr']) / upp
            py = lambda v: H / 2 - (v - P['cu']) / upp
            for i in range(-20, 21):  # grid every 0.05, labelled every 0.1
                k = i * .05; maj = i % 2 == 0; x = px(k); y = py(k)
                if 0 <= x < W:
                    dr.line([(x, 0), (x, H)], fill=(70, 90, 120) if maj else (48, 56, 70))
                    if maj: dr.text((x + 2, H - 14), f'{k * P["rs"]:+.1f}', font=f, fill=(150, 180, 220))
                if 0 <= y < H:
                    dr.line([(0, y), (W, y)], fill=(70, 90, 120) if maj else (48, 56, 70))
                    if maj: dr.text((2, y + 1), f'{k * P["us"]:+.1f}', font=f, fill=(150, 180, 220))
            im = Image.blend(im, base, .55); ImageDraw.Draw(im).text((6, 4), f'{P["name"]}: right {P["ra"]}, up {P["ua"]}', font=font(14), fill=(235, 235, 235))
        else:
            ImageDraw.Draw(im).text((6, 4), P['name'], font=font(15), fill=(235, 235, 235))
        ims.append(im)
    if L['kind'] == 'views': rows = [ims[0:2], ims[2:4], ims[4:6]]
    else: rows = [ims[0:2], ims[2:4], ims[4:6]]
    Wt = max(sum(p.size[0] for p in r) + 4 * len(r) for r in rows); Ht = sum(max(p.size[1] for p in r) for r in rows) + 40
    sheet = Image.new('RGB', (Wt, Ht), (18, 18, 22)); y = 36; ImageDraw.Draw(sheet).text((8, 8), L['title'], font=font(18), fill=(240, 240, 240))
    for r in rows:
        x = 4
        for p in r: sheet.paste(p, (x, y)); x += p.size[0] + 4
        y += max(p.size[1] for p in r)
    out = L['out'] if L['out'].endswith('.png') else L['out'] + '.png'
    sheet.save(out); print('look:', out, flush=True)
    for P in L['panels']:
        try: os.remove(P['path'])
        except OSError: pass


def main():
    import bpy
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
                import ships; yaw = ships.SHIPS.get(it, {}).get('yaw', ships.YAWS.get(it, 0))
            except Exception: pass
        objs = load_glb(it) if glb else load_code(root, it, yaw)
        nm = os.path.splitext(os.path.basename(it))[0]
        render(objs, os.path.join(out, nm + '_look'), nm, 'glb' if glb else f'hulls_hi{" yaw " + str(yaw) if yaw else ""}')
        if '--close' in os.environ.get('LOOKOPT', ''): closeups(objs, os.path.join(out, nm + '_close'), nm)


if __name__ == '__main__':
    if '--compose' in sys.argv:
        for p in sys.argv[sys.argv.index('--compose') + 1:]: compose(p)
    else: main()
