# Issue 769 helper (sandbox only): refresh the words in a build.py model json (the changed-from-the-picture list, the open items,
# the fit report's fix column, the SHEET dict) from the design file without rendering again. The geometry is untouched: it refuses
# when the rebuilt sheet's feature count, mass list or part list differs from the json's, so it never papers over a changed design.
# usage: python model_notes.py CODE RENDER_DIR   (bpy module)
import sys, os, json, importlib.util
import bpy
HERE = os.path.dirname(os.path.abspath(__file__))
SHEETS = os.path.normpath(os.path.join(HERE, '..', '..', '..', '..', 'tools', 'blender', 'build_sheets'))
sys.path.insert(0, SHEETS)
import kit  # noqa: E402
code, rd = sys.argv[1], sys.argv[2]
sp = importlib.util.spec_from_file_location(code, os.path.join(SHEETS, 'ships', code + '.py'))
d = importlib.util.module_from_spec(sp); sp.loader.exec_module(d)
bpy.ops.wm.read_factory_settings(use_empty=True)
kit.use_kit(getattr(d, 'KIT', 'hullbreakers'))
K = kit.Kit(code, d.LENGTH); d.build(K); K.finish()
p = os.path.join(rd, code + '_model.json')
m = json.load(open(p))
same = (len(m['features']) == len(K.features) and [x['name'] for x in m['masses']] == [x['name'] for x in K.masses]
        and [x['id'] for x in m['parts']] == [x['id'] for x in K.built])
if not same:
    sys.exit('the design changed since the render: render again (build.py render), do not patch the words')
m['changes'] = [list(c) for c in K.changes]; m['tbd'] = K.tbd; m['sheet'] = getattr(d, 'SHEET', m.get('sheet'))
json.dump(m, open(p, 'w'), indent=1)
fp = os.path.join(rd, code + '_fit.json')
if os.path.exists(fp):
    f = json.load(open(fp)); f['fixes'] = [list(x) for x in K.fixes]; json.dump(f, open(fp, 'w'), indent=1)
print('words refreshed', p, len(K.changes), 'changes', len(K.fixes), 'fixes')
