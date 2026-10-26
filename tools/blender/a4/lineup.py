# A4 faction lineup sheet (plan A4: "Exit per faction: you approve a faction lineup shot"). Imports the packed Godot files of one
# faction, sets them at true relative size (game length per class), and renders a studio sheet: a three-quarter view of the line,
# a starboard side strip and a top strip, labelled with names and classes. Cycles (GPU on the PC, CPU works in the cloud at low samples).
# usage: blender -b --factory-startup -P lineup.py -- GODOT_DIR OUT.png "Faction title" CODE [CODE ...] [--samples N] [--res W H]
#        python lineup.py --compose OUT.png_layout.json      (the sheet, where Blender's Python has no PIL: the PC job runs this in ComfyUI's)
import sys, os, json, math
HERE = os.path.dirname(os.path.abspath(__file__))
for p in (HERE, os.path.join(HERE, '..', 'a2detail')):
    if p not in sys.path: sys.path.insert(0, p)


def font(n):
    from PIL import ImageFont
    for f in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'C:/Windows/Fonts/arial.ttf', 'arial.ttf'):
        try: return ImageFont.truetype(f, n)
        except Exception: pass
    return ImageFont.load_default()


def main():
    import bpy
    from mathutils import Vector
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    gdir, out, title = a[0], a[1], a[2]; codes = [c for c in a[3:] if not c.startswith('--') and not c.isdigit()]
    samples = int(a[a.index('--samples') + 1]) if '--samples' in a else 32
    W, H = (int(a[a.index('--res') + 1]), int(a[a.index('--res') + 2])) if '--res' in a else (1800, 820)
    man = json.load(open(os.path.join(gdir, 'ships.json')))
    bpy.ops.wm.read_factory_settings(use_empty=True)
    import blmesh, checks as C
    sc = bpy.context.scene; C.studio(sc, samples=samples); blmesh.gpu_on(sc); sc.cycles.samples = samples
    ships = []
    for c in codes:
        e = man.get(c)
        if not e: print('[lineup] no', c); continue
        before = set(sc.objects); bpy.ops.import_scene.gltf(filepath=os.path.join(gdir, e['ship']))
        new = [o for o in set(sc.objects) - before]
        mesh = [o for o in new if o.type == 'MESH']
        for o in new:
            if o.type == 'EMPTY' and not o.children: o.hide_render = True
        root = [o for o in new if o.parent is None][0]; L = e['length_world']; root.scale = (L, L, L)
        ships.append(dict(code=c, root=root, mesh=mesh, L=L, name=e['name'], cls=e['cls']))
    ships.sort(key=lambda s: s['L'])
    bpy.context.view_layer.update()
    def bounds(objs):
        mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
        for o in objs:
            for v in o.bound_box:
                w = o.matrix_world @ Vector(v); mn = Vector(map(min, mn, w)); mx = Vector(map(max, mx, w))
        return mn, mx
    # three-quarter line: side by side along y (smallest nearest the camera), bows aligned at x = 0
    y = 0.0
    for s in ships:
        s['root'].location = (0, 0, 0); bpy.context.view_layer.update(); mn, mx = bounds(s['mesh'])
        s['root'].location = (-mx.x, y - mn.y, -(mn.z + mx.z) / 2); y += (mx.y - mn.y) + max(2.0, s['L'] * .12)
    bpy.context.view_layer.update(); mn, mx = bounds([m for s in ships for m in s['mesh']]); ctr = (mn + mx) / 2; ext = mx - mn
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.lens = 50; cam.data.clip_end = 2000
    shots = []
    def shoot(path, loc, tgt, ortho=None, rot=None, res=(W, H)):
        sc.render.resolution_x, sc.render.resolution_y = res; cam.location = loc
        if ortho: cam.data.type = 'ORTHO'; cam.data.ortho_scale = ortho
        else: cam.data.type = 'PERSP'
        cam.rotation_euler = rot if rot is not None else (tgt - loc).to_track_quat('-Z', 'Y').to_euler()
        sc.render.filepath = path; bpy.ops.render.render(write_still=True); shots.append(path)
    D = max(ext) * 1.25
    shoot(out + '_q.png', ctr + Vector((.75, -.9, .55)).normalized() * D, ctr)
    # side strip: in a row along x, starboard side (camera at -y), true scale
    x = 0.0
    for s in ships:
        s['root'].location = (0, 0, 0); bpy.context.view_layer.update(); mn, mx = bounds(s['mesh'])
        s['root'].location = (x - mn.x, -(mn.y + mx.y) / 2, -(mn.z + mx.z) / 2); s['x0'] = x; x += (mx.x - mn.x) + max(1.5, s['L'] * .08); s['x1'] = x
    bpy.context.view_layer.update(); mn, mx = bounds([m for s in ships for m in s['mesh']]); ctr = (mn + mx) / 2; ext = mx - mn
    shoot(out + '_side.png', ctr + Vector((0, -ext.x * 3, 0)), ctr, ortho=ext.x * 1.04, rot=(math.pi / 2, 0, 0), res=(W, int(W * max(ext.z * 1.35, ext.x * .12) / ext.x)))
    shoot(out + '_top.png', ctr + Vector((0, 0, ext.x * 3)), ctr, ortho=ext.x * 1.04, rot=(0, 0, 0), res=(W, int(W * max(ext.y * 1.25, ext.x * .12) / ext.x)))
    labels = []
    for s in ships:
        labels.append(dict(x=(s['x0'] + (s['x1'] - s['x0']) * .1 - (ctr.x - ext.x * 1.04 / 2)) / (ext.x * 1.04), text=f"{s['name']} ({s['code']})"))
    lay = dict(out=out, title=title, W=W, shots=shots, labels=labels); json.dump(lay, open(out + '_layout.json', 'w'), indent=1)
    try: compose(out + '_layout.json')
    except ImportError: print('[lineup] renders done; compose with: python lineup.py --compose', out + '_layout.json', flush=True)


def compose(lay_path):
    from PIL import Image, ImageDraw
    L = json.load(open(lay_path)); W = L['W']; ims = [Image.open(p).convert('RGB') for p in L['shots']]; TH = 56; LH = 34
    sheet = Image.new('RGB', (W, TH + sum(i.size[1] for i in ims) + LH * 2), (16, 16, 20)); d = ImageDraw.Draw(sheet)
    d.text((14, 12), L['title'], font=font(28), fill=(240, 236, 228)); yy = TH
    for k, im in enumerate(ims):
        sheet.paste(im, (0, yy)); yy += im.size[1]
        if k == 1:  # labels under the side strip, at each ship's place
            for i, lb in enumerate(L['labels']): d.text((max(4, int(lb['x'] * W)), yy + 4 + (i % 2) * 16), lb['text'], font=font(17), fill=(225, 220, 210))
            yy += LH * 2
    sheet.save(L['out']); print('[lineup]', L['out'], len(L['labels']), 'ships', flush=True)

if __name__ == '__main__':
    if '--compose' in sys.argv: compose(sys.argv[sys.argv.index('--compose') + 1])
    else: main()
