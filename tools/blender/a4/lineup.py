# A4 faction lineup sheet (plan A4: "Exit per faction: you approve a faction lineup shot"), laid out for Ryan's phone (portrait, 1080 wide,
# WebP). Imports the packed Godot files of one faction and renders:
#   - a strip of the whole line side by side from starboard at true relative size (game length per class), numbered;
#   - one card per ship, flagship first: a three-quarter studio view of that ship alone, framed to fill the card, with its name, class,
#     length and weapons in plain words.
# v1 (Oct 26) shot the whole line in one three-quarter camera and cropped the big ships and lost the small ones; this layout replaces it.
# Cycles (GPU on the PC, CPU works in the cloud at low samples).
# usage: blender -b --factory-startup -P lineup.py -- GODOT_DIR OUT.webp "Faction title" CODE [CODE ...] [--samples N]
#        python lineup.py --compose OUT.webp_layout.json      (the sheet, where Blender's Python has no PIL: the PC job runs this in ComfyUI's)
import sys, os, json, math
HERE = os.path.dirname(os.path.abspath(__file__))
for p in (HERE, os.path.join(HERE, '..', 'a2detail')):
    if p not in sys.path: sys.path.insert(0, p)

W = 1080                  # sheet width (phone portrait)
CARD = (1080, 640)        # card render size
ARC = {'F': 'forward', 'T': 'turret', 'P': 'port', 'S': 'starboard'}
# Oct 27, lore approved: class and weapon display names (rename_map_final.md 4.0; the cls keys stay)
CLS_NAME = {'Battle-barge': 'War-barge', 'Bio-titan': 'Colossus', 'Ark': 'Lattice-ship', 'Tomb-ark': 'Archive-ship'}
WNAME = {'hbattery': 'heavy battery', 'battery': 'battery', 'hturbo': 'heavy pulse laser', 'turbo': 'pulse laser', 'torp': 'torpedoes',
         'htorp': 'heavy torpedoes', 'autocannon': 'autocannon', 'flak': 'flak', 'lance': 'lance', 'ion': 'ion cannon', 'laser': 'laser',
         'scatter': 'scatter guns', 'gauss': 'null cannon', 'doom': 'corona arc', 'gsentry': 'null sentry', 'pulsar': 'prism lance', 'shard': 'shard',
         'startorp': 'star torpedo', 'bioplasma': 'bioplasma', 'tendril': 'tendrils', 'spores': 'spores', 'turret': 'turret', 'guns': 'guns',
         'bombs': 'bombs', 'sporeb': 'spore bombs'}


def font(n, bold=False):
    from PIL import ImageFont
    names = (('DejaVuSans-Bold.ttf', 'arialbd.ttf') if bold else ('DejaVuSans.ttf', 'arial.ttf'))
    for d in ('/usr/share/fonts/truetype/dejavu/', 'C:/Windows/Fonts/', ''):
        for f in names:
            try: return ImageFont.truetype(d + f, n)
            except Exception: pass
    return ImageFont.load_default()


def weapons_text(names):
    """hard point node names hp_w<slot>_<weapon>_<arc>_<n> -> 'heavy battery (port and starboard), lance (forward)'"""
    slots = {}
    for nm in names:
        if not nm.startswith('hp_w'): continue
        parts = nm.split('_')
        try: slot = int(parts[1][1:]); arc = parts[-2]; wk = '_'.join(parts[2:-2])
        except (ValueError, IndexError): continue
        slots.setdefault(slot, (wk, set()))[1].add(arc)
    byw = {}
    for slot in sorted(slots):
        wk, arcs = slots[slot]; byw.setdefault(wk, set()).update(arcs)
    out = []
    for wk, arcs in byw.items():
        a = [ARC[x] for x in 'FTPS' if x in arcs]
        out.append(f"{WNAME.get(wk, wk)} ({' and '.join(a)})" if a else WNAME.get(wk, wk))
    return ', '.join(out) if out else 'no weapons'


def main():
    import bpy
    from mathutils import Vector
    from bpy_extras.object_utils import world_to_camera_view
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    gdir, out, title = a[0], a[1], a[2]; codes = [c for c in a[3:] if not c.startswith('--') and not c.isdigit()]
    samples = int(a[a.index('--samples') + 1]) if '--samples' in a else 32
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
        ships.append(dict(code=c, root=root, objs=new, mesh=mesh, L=L, name=e['name'], cls=e['cls'],
                          weapons=weapons_text([o.name.split('.')[0] for o in new if o.type == 'EMPTY'])))
    ships.sort(key=lambda s: s['L'])
    bpy.context.view_layer.update()

    def bounds(objs):
        mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
        for o in objs:
            for v in o.bound_box:
                w = o.matrix_world @ Vector(v); mn = Vector(map(min, mn, w)); mx = Vector(map(max, mx, w))
        return mn, mx
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.lens = 50; cam.data.clip_end = 5000; cam.data.sensor_fit = 'HORIZONTAL'
    shots = []

    def render(path, res):
        sc.render.resolution_x, sc.render.resolution_y = res; sc.render.filepath = path; bpy.ops.render.render(write_still=True); shots.append(path)
    # strip: in a row along x, seen from starboard (camera at -y), true relative size
    x = 0.0
    for s in ships:
        s['root'].location = (0, 0, 0); bpy.context.view_layer.update(); mn, mx = bounds(s['mesh'])
        gap = max(1.5, s['L'] * .10)
        s['root'].location = (x - mn.x, -(mn.y + mx.y) / 2, -(mn.z + mx.z) / 2); s['xc'] = x + (mx.x - mn.x) / 2; x += (mx.x - mn.x) + gap
    bpy.context.view_layer.update(); mn, mx = bounds([m for s in ships for m in s['mesh']]); ctr = (mn + mx) / 2; ext = mx - mn
    ow = ext.x * 1.06; sh = max(int(W * ext.z * 1.3 / ow), 150)
    cam.data.type = 'ORTHO'; cam.data.ortho_scale = ow; cam.location = ctr + Vector((0, -ext.x * 3, 0)); cam.rotation_euler = (math.pi / 2, 0, 0)
    render(out + '_strip.png', (W, sh))
    strip_x = [(s['xc'] - (ctr.x - ow / 2)) / ow for s in ships]
    # cards: each ship alone, three-quarter from the bow on the starboard side, a little above; framed so its corners fill about 90%
    cam.data.type = 'PERSP'; cards = []
    order = sorted(range(len(ships)), key=lambda i: -ships[i]['L'])
    for rank, i in enumerate(order):
        s = ships[i]
        for t in ships:
            for o in t['objs']:
                if o.type == 'MESH': o.hide_render = t is not s
        s['root'].location = (0, 0, 0); bpy.context.view_layer.update(); mn, mx = bounds(s['mesh']); c = (mn + mx) / 2
        corners = [Vector((x_, y_, z_)) for x_ in (mn.x, mx.x) for y_ in (mn.y, mx.y) for z_ in (mn.z, mx.z)]
        d = Vector((.95, -1.0, .62)).normalized(); dist = (mx - mn).length * 1.6
        sc.render.resolution_x, sc.render.resolution_y = CARD
        for _ in range(4):
            cam.location = c + d * dist; cam.rotation_euler = (c - cam.location).to_track_quat('-Z', 'Y').to_euler(); bpy.context.view_layer.update()
            pv = [world_to_camera_view(sc, cam, q) for q in corners]
            span = max(max(abs(p.x - .5) for p in pv) / .48, max(abs(p.y - .5) for p in pv) / .46)
            # recentre on the box's projected middle, then scale the distance by the span
            cx = (max(p.x for p in pv) + min(p.x for p in pv)) / 2 - .5; cy = (max(p.y for p in pv) + min(p.y for p in pv)) / 2 - .5
            R = cam.matrix_world.to_3x3(); w = 2 * dist * math.tan(math.atan(18 / 50))
            c = c + R @ Vector((cx * w, cy * w * CARD[1] / CARD[0], 0)); dist *= span
        cam.location = c + d * dist; cam.rotation_euler = (c - cam.location).to_track_quat('-Z', 'Y').to_euler()
        p = out + f'_card{rank}.png'; render(p, CARD)
        cards.append(dict(path=p, num=i + 1, name=s['name'], code=s['code'], cls=s['cls'], L=s['L'], weapons=s['weapons']))
    lay = dict(out=out, title=title, strip=out + '_strip.png', strip_x=strip_x, cards=cards, n=len(ships))
    json.dump(lay, open(out + '_layout.json', 'w'), indent=1)
    try: compose(out + '_layout.json')
    except ImportError: print('[lineup] renders done; compose with: python lineup.py --compose', out + '_layout.json', flush=True)


def compose(lay_path):
    from PIL import Image, ImageDraw
    L = json.load(open(lay_path)); bg = (18, 18, 22); ink = (238, 234, 226); dim = (170, 168, 162); acc = (214, 170, 92)
    strip = Image.open(L['strip']).convert('RGB'); strip = strip.resize((W, int(strip.size[1] * W / strip.size[0])))
    cards = [Image.open(c['path']).convert('RGB') for c in L['cards']]
    TH, SB, CB, PAD = 150, 64, 132, 18
    H = TH + strip.size[1] + SB + sum(im.size[1] + CB + PAD for im in cards) + 40
    sheet = Image.new('RGB', (W, H), bg); d = ImageDraw.Draw(sheet)
    d.text((36, 28), L['title'], font=font(52, True), fill=ink)
    d.text((36, 96), f"{L['n']} ships. Top: the line at true size. Below: each ship close up.", font=font(24), fill=dim)
    y = TH; sheet.paste(strip, (0, y)); y += strip.size[1]
    for k, fx in enumerate(L['strip_x']):  # number badges under each ship in the strip
        cx = int(fx * W); d.ellipse((cx - 19, y + 10, cx + 19, y + 48), fill=acc); t = str(k + 1)
        tw = d.textlength(t, font=font(24, True)); d.text((cx - tw / 2, y + 15), t, font=font(24, True), fill=bg)
    y += SB
    for c, im in zip(L['cards'], cards):
        sheet.paste(im, (0, y)); y += im.size[1]
        d.ellipse((30, y + 18, 76, y + 64), fill=acc); t = str(c['num']); tw = d.textlength(t, font=font(28, True))
        d.text((53 - tw / 2, y + 23), t, font=font(28, True), fill=bg)
        d.text((92, y + 16), c['name'], font=font(36, True), fill=ink)
        d.text((92, y + 62), f"{CLS_NAME.get(c['cls'], c['cls'])}, {c['L']:g} units long ({c['code']})", font=font(24), fill=dim)
        d.text((92, y + 94), c['weapons'], font=font(24), fill=dim)
        y += CB + PAD
    out = L['out']
    if out.lower().endswith('.webp'): sheet.save(out, 'WEBP', quality=82, method=6)
    else: sheet.save(out)
    print('[lineup]', out, len(cards), 'ships', sheet.size, flush=True)


if __name__ == '__main__':
    if '--compose' in sys.argv: compose(sys.argv[sys.argv.index('--compose') + 1])
    else: main()
