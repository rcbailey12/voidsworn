"""station_outpost: the small station for 1- and 3-hex station spots (issue 1791).

Ryan, Nov 24 2026 ("Yes agree on 1"): the giant station_T2 stays at unit scale on the big 19-hex cluster; the 3-hex
teaching spot and the 1-hex station hole get a smaller outpost built from the same station kit with the hull finish
(R362), sized to fit its hexes, so it reads as a different, smaller kind of station rather than a shrunken T2.

Same Parts builders, stack materials and kit units as station_T2 (review.build), so the modules, joints, airlocks,
pipes, towers and radiators match T2 piece for piece at the same detail size. Only the layout is its own: a short
drum stack, two docking arms, one sensor tower on its bridge and two cold radiators, no bearing ring. Abandoned like
T2: one breach, dead caps, a few blue emergency markers.

CPU only:  python outpost.py -- --out DIR [--no-render]   (the pip bpy wheel, or blender -b -P outpost.py -- ...)
Writes station_outpost_shape.json (bounds, footprint, triangles) and, unless --no-render, shape review renders.
"""
import argparse
import json
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Vector, Matrix

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import review                      # T2's builder helpers (empty, bounds, camera, lighting)
from parts import Parts
import stack

CODE = 'station_outpost'
# Kit units, as design.py. Four pressure drums on one service shaft, slimmer than T2's nine.
DRUMS = []
_z = -3.4
for _h, _r in ((1.6, 3.05), (2.3, 3.55), (1.9, 3.35), (1.5, 2.85)):
    DRUMS.append(dict(bottom=_z, height=_h - .10, radius=_r))
    _z += _h
BREACH = {1: (-120, 2.2)}          # one torn hole, facing the damage side as T2's do
ARMS = [dict(angle=20, root=3.2, tip=7.2, z=-.6, width=1.7, modules=2, crane=True),
        dict(angle=200, root=3.2, tip=6.4, z=.9, width=1.4, modules=2, crane=False)]
TOWER = dict(angle=110, dist=4.6, base=.7, height=7.4, cap='dishes')
RADIATORS = [dict(angle=a, radius=3.9, width=2.0, top=-3.6, bottom=-8.4) for a in (290, 335)]
LIGHTS = [dict(deck=2, angle=-40, count=9), dict(deck=0, angle=150, count=6)]
BATTERIES = [(.9, -3.0, -1.2), (-2.2, 2.4, 1.4)]


def build():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    root = review.empty(CODE)
    root['status'] = 'SHAPE REVIEW - issue 1791'
    root['station_kind'] = 'outpost'; root['state'] = 'abandoned outpost'
    move = review.empty('outpost_static', root)   # the kit's finish() needs a moving parent; nothing moves here
    p = Parts(stack.materials(), repair_loose=True)
    for i, d in enumerate(DRUMS):
        z, radius, height = d['bottom'], d['radius'], d['height']
        p.record('core_%02d' % (i + 1), 'deck_drum', ['command', 'habitat', 'stores', 'machinery'][i])
        p.damaged_drum(radius, z, height, hole=BREACH.get(i), top_tear=False, viewport=None)
        if i < len(DRUMS) - 1:
            neck = min(radius, DRUMS[i + 1]['radius']) - .15
            p.band(neck - .18, neck, z + height - .08, DRUMS[i + 1]['bottom'] + .08, steps=64, zone='trim')
        review.empty('joint_core_%02d' % (i + 1), root, (0, 0, z + height + .10))
        for j in range(4):
            a = math.tau * j / 4 + .4 * (i % 2)
            hole = BREACH.get(i)
            if hole and abs(math.atan2(math.sin(a - math.radians(hole[0])), math.cos(a - math.radians(hole[0])))) * radius < hole[1] * .65:
                continue
            old = p.matrix.copy()
            p.matrix = Matrix.Translation(Vector(((radius + .10) * math.cos(a), (radius + .10) * math.sin(a), z + height * .38))) \
                @ Matrix.Rotation(a + math.pi / 2, 4, 'Z') @ Matrix.Rotation(math.pi / 2, 4, 'X')
            p.airlock(.55 if height < 2 else .65)
            p.matrix = old
        with p.detail('service_pipe', 'core drum service risers and shoulder manifolds'):
            for j in range(6):
                a = math.tau * (j + .5) / 6
                hole = BREACH.get(i)
                if hole and abs(math.atan2(math.sin(a - math.radians(hole[0])), math.cos(a - math.radians(hole[0])))) * radius < hole[1] * .65:
                    continue
                rr = radius + .15
                p.rod((rr * math.cos(a), rr * math.sin(a), z + .15), (rr * math.cos(a), rr * math.sin(a), z + height - .22), .045, 'trim')
                p.rod(((radius - .05) * math.cos(a), (radius - .05) * math.sin(a), z + .15),
                      (rr * math.cos(a), rr * math.sin(a), z + .15), .045, 'edge')
    # top cap: a dead beacon ring on the upper drum
    top = DRUMS[-1]['bottom'] + DRUMS[-1]['height']
    p.record('core_cap', 'tower_cap', 'dead beacon ring on the upper deck')
    for zz in (.1, .42):
        p.band(.9, 1.7, top + zz, top + zz + .12, steps=32, zone='trim')
    for a in range(6):
        p.rod((1.2 * math.cos(a * math.tau / 6), 1.2 * math.sin(a * math.tau / 6), top),
              (1.2 * math.cos(a * math.tau / 6), 1.2 * math.sin(a * math.tau / 6), top + 1.3), .03)
    for i, arm in enumerate(ARMS):
        p.record('arm_%d' % (i + 1), 'docking_arm', 'dead berth corridor')
        a = math.radians(arm['angle'])
        p.matrix = Matrix.Rotation(a, 4, 'Z') @ Matrix.Translation(Vector((arm['root'], 0, arm['z'])))
        p.arm(arm['tip'] - arm['root'] - 1.0, arm['width'], arm['modules'], cap=True)
        xf = p.matrix.copy()
        if arm['crane']:
            p.matrix = xf @ Matrix.Translation(Vector((3.0, 0, arm['width'] * .31 + .15)))
            p.crane(2.4)
        p.matrix = xf
        for j in range(arm['modules']):
            x = arm['root'] + j * (arm['tip'] - arm['root']) / arm['modules']
            review.empty('joint_arm_%d_%d' % (i + 1, j), root, (x * math.cos(a), x * math.sin(a), arm['z']))
        p.matrix = Matrix.Identity(4)
    t = TOWER
    ta = math.radians(t['angle'])
    tx, ty = t['dist'] * math.cos(ta), t['dist'] * math.sin(ta)
    p.record('equipment_deck', 'platform', 'one radial tower bridge from the core')
    p.matrix = Matrix.Rotation(ta, 4, 'Z') @ Matrix.Translation(Vector((DRUMS[1]['radius'] - .2, 0, t['base'] - .65)))
    length = t['dist'] - DRUMS[1]['radius'] + .2
    p.box((length / 2, 0, 0), (length, 1.4, .22), 'plate2')
    for yy in (-.55, .55):
        p.rod((0, yy, -.35), (length, yy, -.35), .09, 'trim')
    p.handrail(length, 1.25)
    p.matrix = Matrix.Identity(4)
    p.record('tower_1', 'tower_cap', 'dishes; dead; whole machine on its module joint')
    p.matrix = Matrix.Translation(Vector((tx, ty, t['base'])))
    h = t['height']; rad = .75
    for name, local in (('base', (0, 0, 0)), ('tip', (0, 0, h))):
        review.empty('tower_axis_1_%s' % name, root, p.matrix @ Vector(local))
    p.band(.30, rad * 1.2, -.55, .14, steps=32, zone='trim')
    for j in range(3):
        rr = rad * (1 - .085 * j)
        p.drum(rr, j * h / 3, h / 3 - .12, decks=True, breach=False)
        for a in (0, math.pi / 2, math.pi, math.pi * 1.5):
            p.rod((rr * math.cos(a), rr * math.sin(a), j * h / 3 + .15), (rr * math.cos(a), rr * math.sin(a), (j + 1) * h / 3 - .25), .045, 'trim')
        p.band(rr - .10, rr + .20, j * h / 3 + .10, j * h / 3 + .26, steps=32, zone='plate2')
    p.band(.2, rad * 1.1, h - .08, h + .10, steps=32, zone='edge')
    p.rod((-.9, 0, h + .1), (.9, 0, h + .1), .10)
    for x in (-.9, .9):
        p.dish((x, 0, h + .32), .55, .7)
    p.matrix = Matrix.Identity(4)
    c_r = DRUMS[0]['radius']
    for i, rd in enumerate(RADIATORS):
        p.record('radiator_%d' % (i + 1), 'radiator', 'cold grooved bank and header', inside='header channels and manifold')
        a = math.radians(rd['angle']); h = rd['top'] - rd['bottom']
        p.matrix = Matrix.Rotation(a, 4, 'Z') @ Matrix.Translation(Vector((rd['radius'], 0, rd['top'])))
        with p.detail('coolant_manifold', 'radiator header and paired pipes into the lower core'):
            p.rod((0, -rd['width'] / 2, 0), (0, rd['width'] / 2, 0), .16, 'trim')
            for yy in (-.14, .14):
                p.rod((0, yy, 0), (c_r - rd['radius'], yy, .8), .06, 'trim')
        with p.detail('maintenance_truss', 'radiator suspension struts tied to the core shell'):
            for yy in (-rd['width'] / 2, rd['width'] / 2):
                p.rod((0, yy, 0), (c_r - rd['radius'], 0, .8), .065, 'edge')
        with p.detail('radiator', 'cold thermal panel, coolant channels and edge frame'):
            p.box((0, 0, -h / 2), (.14, rd['width'], h), 'trim')
            for y in (-rd['width'] / 2, rd['width'] / 2):
                p.rod((0, y, -h), (0, y, 0), .07, 'edge')
            for j in range(20):
                y = (j / 19 - .5) * (rd['width'] - .2)
                p.box((.09, y, -h / 2), (.05, .025, h - .2), 'edge')
        p.matrix = Matrix.Identity(4)
    p.record('ring_attitude_control', 'thruster_quad', 'two hull attitude quads on the lower drum')
    for angle in (60, 240):
        a = math.radians(angle); r0 = DRUMS[0]['radius'] + .12
        p.matrix = Matrix.Translation(Vector((r0 * math.cos(a), r0 * math.sin(a), DRUMS[0]['bottom'] + .8))) \
            @ Matrix.Rotation(a, 4, 'Z') @ Matrix.Rotation(math.pi / 2, 4, 'Y')
        p.thruster_quad()
        p.matrix = Matrix.Identity(4)
    p.record('emergency_lights', 'lights', 'blue emergency markers in two clusters; dull battery strips', inside='module-local batteries')
    rng = random.Random(1791)
    for cl in LIGHTS:
        d = DRUMS[cl['deck']]
        for _ in range(cl['count']):
            a = math.radians(cl['angle'] + rng.uniform(-9, 9))
            z = d['bottom'] + d['height'] * (.69 + rng.uniform(0, .10))
            rr = d['radius'] + .11
            p.box((rr * math.cos(a), rr * math.sin(a), z), (.11, .17, .17), 'blue', rotation=a)
    for pos in BATTERIES:
        p.box(pos, (.55, .12, .10), 'battery')
    objs = p.finish(root, move)
    return root, move, objs, p.rows, p.details


def plan_extent(objs):
    """Farthest horizontal reach from the core axis (kit units), from every mesh vertex."""
    far = 0.0
    deps = bpy.context.evaluated_depsgraph_get()
    for ob in objs:
        ev = ob.evaluated_get(deps); me = ev.to_mesh()
        for v in me.vertices:
            w = ob.matrix_world @ v.co
            far = max(far, math.hypot(w.x, w.y))
        ev.to_mesh_clear()
    return far


def main():
    args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    ap = argparse.ArgumentParser(); ap.add_argument('--out', required=True)
    ap.add_argument('--no-render', action='store_true'); a = ap.parse_args(args)
    out = Path(a.out); out.mkdir(parents=True, exist_ok=True)
    root, move, objs, rows, details = build()
    bpy.context.view_layer.update()
    bb = review.bounds(objs)
    reach = plan_extent(objs)
    deps = bpy.context.evaluated_depsgraph_get()
    tris = {'exterior': 0, 'inside': 0}
    for ob in objs:
        ev = ob.evaluated_get(deps); me = ev.to_mesh(); me.calc_loop_triangles()
        tris['inside' if ob.get('inside') else 'exterior'] += len(me.loop_triangles)
        ev.to_mesh_clear()
    report = dict(code=CODE, kit_units=True, bounds=bb, plan_reach=reach, triangles=tris,
                  modules=[r['id'] for r in rows], details=len(details))
    (out / 'station_outpost_shape.json').write_text(json.dumps(report, indent=1, default=str))
    print('OUTPOST', json.dumps(dict(reach=reach, triangles=tris, size=bb['size'])), flush=True)
    if not a.no_render:
        scene = bpy.context.scene
        scene['review_fov'] = 40.0
        review.lighting(scene)
        scene.cycles.samples = int(__import__('os').environ.get('OUTPOST_SAMPLES', '24'))
        for name, pos in (('three_quarter', (24, -30, 20)), ('top', (0.01, -0.01, 40)), ('side', (34, -8, 2))):
            review.camera(scene, name, pos, (0, 0, -0.5))
            scene.render.filepath = str(out / ('outpost_%s.png' % name))
            bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out / 'station_outpost_shape.blend'))


if __name__ == '__main__':
    main()
