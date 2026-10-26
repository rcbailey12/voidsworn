# A4: review sheet for the breach damage (damage.py): per anchor, the intact hull, the hole and the heavy damage, close up, from the
# anchor's own outward side and at a slant. Workbench (fast, cloud or PC); hull in flat grey (paint is in the maps), interiors in their
# material colours, glow and hot edges bright.
# usage: python3 dmgview.py SHIP_NPZ META_JSON OUT_PNG [anchors e.g. 0,1,2]   (writes OUT_PNG_layout.json; compose with look.py --compose)
import sys, os, json, math
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path: sys.path.insert(0, HERE)
import numpy as np
# bpy, mathutils, damage and frame load inside the Blender-only functions: the compose step runs in plain Python (PC job, ComfyUI's
# Python), where importing bpy at the top stopped every breach review sheet on Oct 26


def obj(name, pos, idx, col):
    import bpy, frame
    me = bpy.data.meshes.new(name); P = frame.gl_to_bl(np.asarray(pos, float))
    me.vertices.add(len(P)); me.vertices.foreach_set('co', P.astype(np.float32).ravel())
    I = np.asarray(idx, np.int64).reshape(-1, 3); me.loops.add(I.size); me.loops.foreach_set('vertex_index', I[:, ::-1].ravel().astype(np.int32))
    me.polygons.add(len(I)); me.polygons.foreach_set('loop_start', np.arange(0, I.size, 3, dtype=np.int32)); me.polygons.foreach_set('loop_total', np.full(len(I), 3, np.int32))
    me.update(); me.validate()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    m = bpy.data.materials.new(name); m.diffuse_color = (*col, 1); me.materials.append(m); return o


def main():
    import bpy
    from mathutils import Vector
    import damage, frame
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    npz, metap, out = a[0], a[1], a[2]; os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True); d = damage.build(npz, metap); meta = json.load(open(metap))
    want = [int(x) for x in a[3].split(',')] if len(a) > 3 else list(range(len(d['anchors'])))
    for o in list(bpy.data.objects): bpy.data.objects.remove(o)
    m = dict(np.load(npz)); lab = d['label']
    sc = bpy.context.scene; sc.render.engine = 'BLENDER_WORKBENCH'; sh = sc.display.shading
    sh.light = 'STUDIO'; sh.color_type = 'MATERIAL'; sh.show_cavity = True; sh.cavity_type = 'BOTH'; sh.show_shadows = True
    sc.render.resolution_x, sc.render.resolution_y = 560, 420; sc.render.film_transparent = False
    sc.world = sc.world or bpy.data.worlds.new('w'); sh.background_type = 'VIEWPORT'; sh.background_color = (.30, .31, .34)
    hullc = (.55, .55, .56)
    live = obj('live', m['pos'], m['idx'][lab == 0], hullc)
    skins = {k: obj(f'skin{k}', m['pos'], m['idx'][lab == k], hullc) for k in np.unique(lab) if k > 0}
    wall, framec, glow, edge = damage.INTERIOR.get(d['fac'], damage.INTERIOR['voidsworn'])
    cols = dict(hull=(.62, .60, .58), interior=tuple(min(1, c * 3) for c in wall), frame=framec, glow=glow, edge=edge)
    parts = {}
    for name, mats in d['parts'].items():
        parts[name] = [obj(f'{name}_{mt}', ar['pos'], ar['idx'], cols[mt]) for mt, ar in mats.items()]
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 50
    shots = []; tmp = out + '_parts'; os.makedirs(tmp, exist_ok=True)
    hits = d.get('hits', {})
    def show(k, stage):
        hid = set()
        if stage == 'hole': hid = {2 * k + 1}
        elif stage == 'heavy': hid = {2 * k + 1, 2 * k + 2}
        elif f'breach_{k}_{stage}' in hits: hid = {(int(x.split('_')[1]) * 2 + (2 if x.endswith('heavy') else 1)) for x in hits[f'breach_{k}_{stage}']['hides']}
        for kk, o in skins.items(): o.hide_render = bool(kk in hid)
        for name, objs in parts.items():
            vis = name == f'breach_{k}_{stage}'
            for o in objs: o.hide_render = not vis
    STAGES = ['intact', 'hole', 'heavy']
    for k in want:
        STAGES = ['intact', 'hole', 'heavy'] + [h['kind'] for nm, h in hits.items() if h.get('breach') == k]
        an = d['anchors'][k]; p = Vector(frame.gl_to_bl(np.array([an['p']]))[0].tolist()); n = Vector(frame.gl_to_bl(np.array([an['n']]))[0].tolist())
        for vi, (tilt, dist) in enumerate(((.25, 4.2), (.85, 5.6))):
            side = n.cross(Vector((0, 0, 1))); side = side.normalized() if side.length > .1 else Vector((1, 0, 0))
            dirv = (n + side * tilt + Vector((0, 0, .25))).normalized()
            for stage in STAGES:
                cam.location = p + dirv * an['r_heavy'] * dist; cam.rotation_euler = (p - cam.location).to_track_quat('-Z', 'Y').to_euler()
                show(k, stage); f = os.path.join(tmp, f'b{k}_{vi}_{stage}.png'); sc.render.filepath = f; bpy.ops.render.render(write_still=True)
                shots.append(dict(path=f, label=f'breach {k} ({an["section"]}) {stage}', row=len(shots) // 3))
        if len(STAGES) > 3: break  # one view per anchor when the weapon variants are on it
    lay = dict(out=out, title=f'{meta["code"]} breach damage: intact, hole, heavy, then per-weapon variants (R39, R43)', cols=max(3, len(STAGES)), shots=shots)
    json.dump(lay, open(out + '_layout.json', 'w'), indent=1); print('dmgview', len(shots), 'shots')


def compose(lay_path):
    """grid of the shots, three per row (plain Python with PIL: Blender 4.5's Python has none)"""
    from PIL import Image, ImageDraw
    L = json.load(open(lay_path)); ims = []
    for s in L['shots']:
        im = Image.open(s['path']).convert('RGB'); ImageDraw.Draw(im).text((6, 4), s['label'], fill=(240, 240, 240)); ims.append(im)
    w, h = ims[0].size; c = L['cols']; rows = (len(ims) + c - 1) // c
    sheet = Image.new('RGB', (c * (w + 4) + 4, rows * (h + 4) + 34), (18, 18, 22)); ImageDraw.Draw(sheet).text((8, 10), L['title'], fill=(240, 240, 240))
    for i, im in enumerate(ims): sheet.paste(im, (4 + (i % c) * (w + 4), 30 + (i // c) * (h + 4)))
    sheet.save(L['out']); print('dmgview sheet', L['out'])


if __name__ == '__main__':
    if '--compose' in sys.argv: compose(sys.argv[sys.argv.index('--compose') + 1])
    else: main()
