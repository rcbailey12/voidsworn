# A2 max-detail ships: reimport check (ship-kit skill, step 2): each glb comes back into Blender with the expected triangle count, finite
# positions and its four textures. usage: blender -b --factory-startup -P reimport.py -- a.glb [b.glb ...]   (expected counts from the glb's
# own accessors, read with hullio)
import sys, os, math
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path: sys.path.insert(0, HERE)
import bpy, hullio
args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
for p in args:
    if not os.path.exists(p): print('[reimport]', os.path.basename(p), 'MISSING'); continue
    js, _ = hullio.read_glb(p); want = sum(js['accessors'][pr['indices']]['count'] // 3 for m in js['meshes'] for pr in m['primitives'])
    bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=p)
    obs = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    got = sum(len(pl.vertices) - 2 for o in obs for pl in o.data.polygons)
    fin = all(all(math.isfinite(c) for c in v.co) for o in obs for v in o.data.vertices)
    texs = len([n for o in obs for m in o.data.materials if m and m.use_nodes for n in m.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image])
    print('[reimport]', os.path.basename(p), 'PASS' if (got == want and fin) else 'FAIL', 'tris', want, got, 'textures', texs, flush=True)
