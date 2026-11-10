# Issue 209 round 4: dump a cell's visible triangles (ship frame: x to the bow, y to port, z up, length 1.0) to an npz for the
# silhouette score (silhouette4.py, plain Python, no Blender).
# usage: blender -b [CELL.blend] -P sil_dump.py -- OUT.npz [glb PATH [lod0]] [b0 PATH] [build armA4 CELL] [blend PATH] [scene]
#   glb PATH lod0   import a glb (Godot export), keep only the *_lod0 node
#   b0 PATH         the B0 generation, yaw fixed (common.ai_align 22 degrees), as the bake uses it
#   build MOD CELL  build a cell's geometry with MOD.build_geometry (no bake), hero parts from GEN3D env var for Hy cells
#   blend PATH      open a blend (python3.11 with the bpy module), then as scene
#   scene           whatever the opened blend holds (visible to the render, interior and proxies left out)
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import bpy
import numpy as np
import common as C

a = sys.argv[sys.argv.index('--') + 1:]
OUT, MODE = a[0], a[1]

def tri_array(objs):
    dg = bpy.context.evaluated_depsgraph_get(); out = []
    for o in objs:
        e = o.evaluated_get(dg); me = e.to_mesh(); me.calc_loop_triangles()
        v = np.empty(len(me.vertices) * 3, np.float32); me.vertices.foreach_get('co', v); v = v.reshape(-1, 3)
        t = np.empty(len(me.loop_triangles) * 3, np.int32); me.loop_triangles.foreach_get('vertices', t); t = t.reshape(-1, 3)
        M = np.array(o.matrix_world, np.float32); v = v @ M[:3, :3].T + M[:3, 3]
        out.append(v[t]); e.to_mesh_clear()
    return np.concatenate(out, 0) if out else np.zeros((0, 3, 3), np.float32)

if MODE == 'glb':
    bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=a[2])
    objs = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    if len(a) > 3 and a[3] == 'lod0': objs = [o for o in objs if o.name.endswith('lod0')]
elif MODE == 'b0':
    bpy.ops.wm.read_factory_settings(use_empty=True); o = C.import_glb(a[2], 'b0'); C.ai_align(o, 22.0); objs = [o]
elif MODE == 'build':
    mod = __import__(a[2]); cell = a[3]
    hero = getattr(mod, 'HERO_SLOTS', ('casemate', 'bowguns', 'drumrack')) if cell.startswith('Hy') else ()
    r = mod.build_geometry(hero, os.environ.get('GEN3D'))
    objs = [o for o in bpy.context.scene.objects if o.type == 'MESH' and not o.hide_render and o.get('role') != 'interior']
elif MODE == 'blend':
    bpy.ops.wm.open_mainfile(filepath=a[2])
    objs = [o for o in bpy.context.scene.objects if o.type == 'MESH' and not o.hide_render and o.get('role') != 'interior']
else:
    objs = [o for o in bpy.context.scene.objects if o.type == 'MESH' and not o.hide_render and o.get('role') != 'interior']
T = tri_array(objs)
np.savez_compressed(OUT, tris=T)
print('[sil] dumped', OUT, T.shape, 'objects', len(objs), flush=True)
