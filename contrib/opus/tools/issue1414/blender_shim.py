import sys, runpy
a = sys.argv[1:]
blend = None; script = None; rest = []
i = 0
while i < len(a):
    if a[i] == '--':
        rest = a[i + 1:]; break
    if a[i] == '-b':
        pass
    elif a[i] == '--python-exit-code':
        i += 1
    elif a[i] == '-P':
        i += 1; script = a[i]
    elif a[i].endswith('.blend'):
        blend = a[i]
    i += 1
import bpy
if blend:
    bpy.ops.wm.open_mainfile(filepath=blend)
sys.argv = ['blender', '--'] + rest
try:
    runpy.run_path(script, run_name='__main__')
except SystemExit as e:
    if e.code not in (0, None):
        raise
