# The recipe's hull module for a ship built from an approved build sheet (issue 592). The ship json names it ("hull":
# "sheet_hull") and names the sheet ("sheet": "corsair_A16", the design file tools/blender/build_sheets/ships/<sheet>.py).
# It builds the sheet with the sheet kit (the same builders, the same design, no tracing, no tuning) and hands the scene to
# the recipe through the one build contract (tools/blender/build_sheets/contract.py). Stage 3 (sil_dump.py build), stage 4
# (this file run as a script) and stage 5 (the bake) all build through here, so every stage sees the same ship.
# usage: blender -b -P sheet_hull.py -- OUT_DIR CELL        (the ship json from R209_SHIP, which env.bat sets)
import os, sys, json, time, importlib.util
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
SHEETS = os.path.normpath(os.path.join(HERE, '..', 'build_sheets')); sys.path.insert(0, SHEETS)
import bpy

SHIP = os.environ.get('R209_SHIP', '')
GUNS = []                 # (name, aim, mount normal), as every hull module keeps them
BREAK = {}                # the sheet's seams (t_lines, l_line), filled by build_geometry
HERO_SLOTS = ()
OWN_INSIDES = True        # the sheet authors its insides; the bake must not add the round 2 break structure
RECORD = {}


def load_ship():
    if not SHIP or not os.path.exists(SHIP): raise SystemExit(f'sheet_hull: no ship json (R209_SHIP={SHIP!r})')
    d = json.load(open(SHIP))
    if not d.get('sheet'): raise SystemExit(f'sheet_hull: {SHIP} names no "sheet" (the build sheet design file)')
    return d


def build_geometry(hero=(), G=None):
    """build the sheet and apply the contract; returns (hull objects, [], parts, [], notes, []) as the other hull modules"""
    import kit, contract
    ship = load_ship(); code = ship['sheet']
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sp = importlib.util.spec_from_file_location(code, os.path.join(SHEETS, 'ships', code + '.py'))
    design = importlib.util.module_from_spec(sp); sp.loader.exec_module(design)
    kit.use_kit(getattr(design, 'KIT', 'hullbreakers'))
    K = kit.Kit(code, design.LENGTH); design.build(K); K.finish(); bpy.context.view_layer.update()
    rec = contract.to_recipe(K, ship); RECORD.clear(); RECORD.update(rec)
    sc = bpy.context.scene
    GUNS[:] = [tuple(g) for g in json.loads(sc['r209_guns'])]
    BREAK.clear(); BREAK.update(t_lines=list(sc['r209_t_lines']), l_line=list(sc['r209_l_line']))
    meshes = [o for o in sc.objects if o.type == 'MESH']
    hull = [o for o in meshes if o.get('role') == 'hull']
    parts = [o for o in meshes if o.get('role') not in ('hull', 'interior')]
    return hull, [], parts, [], [dict(route='build sheet ' + code, contract=rec)], []


def interiors():
    return [o for o in bpy.context.scene.objects if o.type == 'MESH' and o.get('role') == 'interior']


def plate_crossing(Pl):
    return []


if __name__ == '__main__':
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    out = a[0]; cell = a[1]; t0 = time.time()
    hull, _, parts, _, notes, _ = build_geometry()
    os.makedirs(out, exist_ok=True); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, f'{cell}.blend'))
    meta = dict(cell=cell, hull_objects=len(hull), parts=len(parts), interiors=len(interiors()), seconds=round(time.time() - t0, 1), notes=notes)
    json.dump(meta, open(os.path.join(out, f'{cell}_build.json'), 'w'), indent=1)
    print('[209]', json.dumps(meta)[:3000], flush=True)
