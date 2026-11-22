# issue 1291: proves a kit change leaves a ship's built geometry byte-identical (first use: the armadillo bare-strip clamp
# must not change the published C13). Builds the ship's sheet through the same hull module stage 5 uses (no paint, no bake)
# and prints one sha256 over every outside and inside mesh's vertex coordinates and faces, object by object in name order.
# usage (Blender 4.5 or the bpy wheel): R209_SHIP=tools/recipe/ships/chorus_C13.json python armadillo_check.py
#   run it on two checkouts and compare the "geometry sha256" lines; the [armadillo] line also says how many steps were clamped
import os, sys, hashlib, struct
HERE = os.path.dirname(os.path.abspath(__file__))
R209 = os.path.normpath(os.path.join(HERE, '..', '..', 'r209'))
for p in (R209, os.path.normpath(os.path.join(HERE, '..', 'shared')), os.path.normpath(os.path.join(HERE, '..', '..', '..', 'recipe'))):
    if p not in sys.path:
        sys.path.insert(0, p)
import bpy  # noqa: E402
import sheet_hull as SH  # noqa: E402

SH.load_ship()
SH.build_geometry()
h = hashlib.sha256()
n = 0
for ob in sorted((o for o in bpy.context.scene.objects if o.type == 'MESH'), key=lambda o: o.name):
    me = ob.data
    h.update(ob.name.encode())
    for v in me.vertices:
        co = ob.matrix_world @ v.co
        h.update(struct.pack('<3f', co.x, co.y, co.z))
    for poly in me.polygons:
        h.update(struct.pack('<%di' % len(poly.vertices), *poly.vertices))
    n += 1
print('geometry sha256 %s (%d meshes)' % (h.hexdigest(), n), flush=True)
