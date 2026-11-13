# Ship recipe stage 5 for a ship built from a build sheet (issue 601): the faction kit's paint stack. The ship json says
# "bake": "stack"; env.bat turns that into this script when the faction kit has a stack (tools/blender/kits/<kit>/stack.py),
# and into the unpainted route ("none") when it has none yet.
#   1. builds the sheet through the same hull module stage 4 audited (sheet_hull: the sheet and its build contract), so the
#      painted ship is the audited ship, no second copy of its design;
#   2. paints it with the faction stack (tools/blender/kits/shared/paint_stack.py: masks baked from the ship's own geometry,
#      procedural layers, the faction's trim sheet and decals; colours sampled from the concept, never the concept projected);
#   3. measures the paint's detail density beside the mesh's, per part type against the hull (R224; tools/recipe/density.py);
#   4. saves CELL.blend (what stages 6 and 7 read) and CELL.json, and prints the "[209] CELL {" line stage 5 waits for.
# The shape reference (B0) is not used: the masks come from the ship's own geometry. It stays the grime source of the older
# traced hulls (bakeAb6.py) and the reference of the second-camera outline score.
# usage: blender -b -P bake_sheet.py -- OUT_DIR B0_GLB _ CELL [RES] [SAMPLES]      (the ship json from R209_SHIP, env.bat)
#        R209_PARTS_RES overrides the parts atlas size (default RES)
import os, sys, json, time, importlib.util
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
KITS = os.path.normpath(os.path.join(HERE, '..', 'kits'))
for p in (os.path.join(KITS, 'shared'), os.path.normpath(os.path.join(HERE, '..', '..', 'recipe'))):
    if p not in sys.path: sys.path.insert(0, p)
import bpy

A = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
OUT, CELL = A[0], A[3]
RES = int(A[4]) if len(A) > 4 else 4096; SAMPLES = int(A[5]) if len(A) > 5 else 64
PRES = int(os.environ.get('R209_PARTS_RES', RES))


def stack_for(ship):
    """the faction kit's paint stack module, or None when the kit has no stack yet"""
    kit = ship.get('faction') or ''
    p = os.path.join(KITS, kit, 'stack.py')
    if not os.path.exists(p): return None, kit
    sp = importlib.util.spec_from_file_location('stack_' + kit, p); m = importlib.util.module_from_spec(sp); sp.loader.exec_module(m)
    return m, kit


def main():
    t0 = time.time(); os.makedirs(OUT, exist_ok=True)
    import sheet_hull as SH
    ship = SH.load_ship()
    S, kit = stack_for(ship)
    if S is None:
        raise SystemExit(f'bake_sheet: the {kit!r} kit has no paint stack (tools/blender/kits/{kit}/stack.py); stage 5 takes the unpainted route for it')
    hull, _, parts, _, notes, _ = SH.build_geometry()
    t_geo = time.time() - t0
    import paint_stack as PS, density, common as C
    info = PS.run(S, OUT, CELL, RES, PRES, SAMPLES, textures_dir=os.path.join(OUT, 'textures'))
    dens = density.measure(bpy.context.scene, os.path.join(OUT, f'{CELL}_hull_albedo.png'), os.path.join(OUT, f'{CELL}_parts_albedo.png'))
    json.dump(dens, open(os.path.join(OUT, 'density.json'), 'w'), indent=1)
    C.mats()  # the clay override material render.py uses
    objs = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    rep = C.report([o for o in objs if o.get('role') != 'interior'])
    meta = dict(cell=CELL, route=f'build sheet {ship.get("sheet")} + the {kit} paint stack (kits/{kit}/stack.py, kits/shared/paint_stack.py)',
                build_seconds=round(time.time() - t0, 1), geometry_seconds=round(t_geo, 1), res=RES, parts_res=PRES, samples=SAMPLES,
                paint=info, density=dens['summary'], contract=SH.RECORD, **rep)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, f'{CELL}.blend'))
    json.dump(meta, open(os.path.join(OUT, f'{CELL}.json'), 'w'), indent=1, default=str)
    print('[209]', CELL, json.dumps(meta, default=str)[:2000], flush=True)


if __name__ == '__main__':
    main()
