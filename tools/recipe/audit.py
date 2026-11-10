# Ship recipe, stage 4: audit an opened build (blender -b CELL.blend -P audit.py -- OUT.json): floating parts, parts across a break
# line, guns aimed backward, with the shared one-pass audit (tools/blender/kits/shared/plumbing.py).
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__))
for p in (os.path.join(HERE, '..', 'blender', 'r209'), os.path.join(HERE, '..', 'blender', 'kits', 'shared')): sys.path.insert(0, os.path.normpath(p))
import bpy
from mathutils import Vector
import common as C, plumbing as PB
out = sys.argv[sys.argv.index('--') + 1]
objs = [o for o in bpy.context.scene.objects if o.type == 'MESH']
hull = [o for o in objs if o.get('role') == 'hull']; parts = [o for o in objs if o.get('role') not in ('hull', 'glow', 'interior')]
guns = [(n, Vector(a)) for n, a in json.loads(bpy.context.scene.get('r209_guns', '[]'))]   # aims recorded by the hull module
sc = bpy.context.scene      # the build's own break lines travel in the blend (common.set_break); the module defaults are an older hull's
tl = tuple(sc['r209_t_lines']) if 'r209_t_lines' in sc else None; ll = tuple(sc['r209_l_line']) if 'r209_l_line' in sc else None
au = PB.audit(hull, parts, guns, t_lines=tl, l_line=ll); au['guns'] = len(guns); json.dump(au, open(out, 'w'), indent=1); print('[audit]', json.dumps(au)[:2000])
