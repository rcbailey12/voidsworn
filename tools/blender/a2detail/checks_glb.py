# A2 max-detail ships: review renders straight from an exported glb (its own glTF material as Blender imports it, plus clay), so what is
# reviewed is the file the engines load. usage: blender -b --factory-startup -P checks_glb.py -- CODE.glb CHECK_DIR [--sweep-only]
import sys, os, json
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path: sys.path.insert(0, HERE)
import bpy
import checks as C
a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
glb, chk = a[0], a[1]; code = os.path.basename(glb)[:-4]; tmp = os.path.join(chk, '_r_' + code); os.makedirs(tmp, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=glb)
obs = [o for o in bpy.context.scene.objects if o.type == 'MESH']; own = [list(o.data.materials) for o in obs]
sc = bpy.context.scene; C.studio(sc, samples=int(os.environ.get('CHECK_SAMPLES', '16')))
for o in obs:  # the studio stand-in for the engines' emissive strength (glTF import sets strength 1)
    for m in o.data.materials:
        b = m.node_tree.nodes.get('Principled BSDF') if m and m.use_nodes else None
        if b and b.inputs['Emission Strength'].default_value > 0: b.inputs['Emission Strength'].default_value = 2.5
if '--sweep-only' not in a: C.render_views(obs, os.path.join(tmp, 'clay'), mat=C.clay_mat())
C.render_sweep(obs, os.path.join(tmp, 'sclay'), mat=C.clay_mat())
for o, ms in zip(obs, own):
    o.data.materials.clear()
    for m in ms: o.data.materials.append(m)
if '--sweep-only' not in a: C.render_views(obs, os.path.join(tmp, 'paint'))
C.render_sweep(obs, os.path.join(tmp, 'spaint'))
info = os.path.join(tmp, 'info.json')
if not os.path.exists(info): json.dump(dict(code=code, faction='?', res='glb'), open(info, 'w'))
try:
    import checks_sheet; checks_sheet.make(chk, code); print('[checks] sheets for', code)
except ImportError: print('[checks] renders in', tmp)
