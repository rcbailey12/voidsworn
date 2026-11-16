# usage: python run_blend.py BUILD.blend SCRIPT.py [args after --]
# run a recipe script on an opened blend with the bpy module, as "blender -b BLEND -P SCRIPT -- ARGS" does
import sys, runpy, bpy
blend, script = sys.argv[1], sys.argv[2]
bpy.ops.wm.open_mainfile(filepath=blend)
sys.argv = [script, '--'] + sys.argv[3:]
runpy.run_path(script, run_name='__main__')
