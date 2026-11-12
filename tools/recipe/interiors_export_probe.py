# Issue 557: repeatable exports from one baked build, no modelling or rebake.
# blender -b BUILD.blend -P interiors_export_probe.py -- SHIP_JSON OUT variant=authored|moved|legacy [fixture=1]
# The legacy comparison pins the exporter before issue 557, so it remains repeatable after this change lands.
import os, sys, runpy, subprocess
import bpy

here = os.path.dirname(os.path.abspath(__file__))
args = sys.argv[sys.argv.index('--') + 1:]
opts = dict(a.split('=', 1) for a in args[2:] if '=' in a)
variant = opts.get('variant', 'authored')
if opts.get('fixture') == '1':
    # Test-only machinery markers between Ab8's decks. These are plumbing fixtures, never production ship art.
    # The source hull and authored decks/frames are unchanged; all variants start from the same scene contents.
    mat = bpy.data.materials.new('issue557_test_machinery'); mat.use_nodes = True
    bs = mat.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value = (.14, .19, .22, 1)
    bs.inputs['Metallic'].default_value = .45; bs.inputs['Roughness'].default_value = .6
    for i, x in enumerate((-.29, -.04, .27)):
        for side in (-1, 1):
            bpy.ops.mesh.primitive_cube_add(size=1, location=(x, side * .045, -.038))
            block = bpy.context.object; block.name = f'issue557_test_machinery_{i}_{side}'
            block.dimensions = (.045, .030, .038); block['role'] = 'interior'
            block.data.materials.append(mat)
if variant == 'moved':
    sc = bpy.context.scene
    lines = sorted(sc['r209_t_lines'])
    lines[0] -= .10
    sc['r209_t_lines'] = lines
    z, _, right = sc['r209_l_line']
    sc['r209_l_line'] = [z, lines[0], right]
if variant == 'legacy':
    baseline = opts.get('baseline', '902388eb2fa3582bd26531be3e3ec38d8d01dfd0')
    source = subprocess.check_output(['git', 'show', baseline + ':tools/recipe/export7.py'], cwd=os.path.join(here, '..', '..')).decode('utf-8')
    exec(compile(source, os.path.join(here, 'export7.py'), 'exec'), dict(__file__=os.path.join(here, 'export7.py'), __name__='__main__'))
else:
    runpy.run_path(os.path.join(here, 'export7.py'), run_name='__main__')
