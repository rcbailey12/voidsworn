# Ship recipe, stage 4: audit an opened build (blender -b CELL.blend -P audit.py -- OUT.json): floating parts, parts across a break
# line, guns aimed backward or into the ship, with the shared one-pass audit (tools/blender/kits/shared/plumbing.py).
# It fails loudly (exit 1, and audit.json says why) when the build carries no break lines of its own (common.set_break writes
# r209_t_lines and r209_l_line into the blend; the module defaults belong to an older hull) or carries them empty, when any gun
# lacks its mount normal (the into-the-ship test could not run for it; Muse condition 1 on PR 341), and when the audit lists any
# problem or any part across a break line.
# What the floating test proves: every part intersects the hull or another part (BVH overlap: faces that cross), or has a sampled
# vertex within .002 of the hull. A part resting exactly on another part without crossing its faces is not excused by it. A part
# intersecting only another part is excused, so a chain of parts can hang off one that meets the hull; it does not prove each part
# sits on its own mount.
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__))
for p in (os.path.join(HERE, '..', 'blender', 'r209'), os.path.join(HERE, '..', 'blender', 'kits', 'shared')): sys.path.insert(0, os.path.normpath(p))
import bpy
from mathutils import Vector
import common as C, plumbing as PB
out = sys.argv[sys.argv.index('--') + 1]
sc = bpy.context.scene
objs = [o for o in sc.objects if o.type == 'MESH']
hull = [o for o in objs if o.get('role') == 'hull']; parts = [o for o in objs if o.get('role') not in ('hull', 'glow', 'interior')]
guns = []
for g in json.loads(sc.get('r209_guns', '[]')):        # (name, aim) or (name, aim, mount normal), recorded by the hull module
    guns.append((g[0], Vector(g[1]), Vector(g[2]) if len(g) > 2 and g[2] is not None else None))
fail = []
if 'r209_t_lines' not in sc or 'r209_l_line' not in sc:
    fail.append('the build has no break lines of its own (r209_t_lines, r209_l_line); the audit will not fall back to an older hull\'s')
elif not len(sc['r209_t_lines']) or not len(sc['r209_l_line']):
    fail.append('the build\'s break lines are empty (r209_t_lines or r209_l_line): an empty list tests no break line')
if not hull: fail.append('no hull object (role hull) in the build')
if not guns: fail.append('no guns recorded (r209_guns is empty)')
else:
    bare = [g[0] for g in guns if g[2] is None]
    if bare: fail.append(f'{len(bare)} of {len(guns)} guns carry no mount normal, so the into-the-ship test could not run for them: ' + ', '.join(bare[:8]))
if fail:
    au = dict(result='FAIL', failures=fail, problems=[], crossing_break_lines=[], guns=len(guns), guns_with_normals=sum(g[2] is not None for g in guns))
else:
    au = PB.audit(hull, parts, guns, t_lines=tuple(sc['r209_t_lines']), l_line=tuple(sc['r209_l_line']))
    au['guns'] = len(guns); au['break_lines'] = dict(t_lines=list(sc['r209_t_lines']), l_line=list(sc['r209_l_line']))
    au['result'] = 'FAIL' if (au['problems'] or au['crossing_break_lines']) else 'PASS'
json.dump(au, open(out, 'w'), indent=1)
print('[audit]', json.dumps(au)[:2000], flush=True)
print('[audit]', au['result'], flush=True)
sys.exit(0 if au['result'] == 'PASS' else 1)
