# For one built sheet blend: the stack zone every outside object resolves to, and that zone's full recipe, under the old
# (origin/main) and the new (issue 651) Hullbreaker stack. Prints DIFF lines, or SAME.
import bpy, sys, importlib.util, json
a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
def load(p, n):
    sp = importlib.util.spec_from_file_location(n, p); m = importlib.util.module_from_spec(sp); sp.loader.exec_module(m); return m
old, new = load(a[0], 'old_stack'), load(a[1], 'new_stack')
diff = 0; used = set(); n = 0
for o in bpy.context.scene.objects:
    if o.type != 'MESH' or o.get('role') == 'interior': continue
    m = o.data.materials[0].name if o.data.materials else ''
    zo = old.ZONE_BY_KIND.get((o.get('part_kind'), m)) or m
    zn = new.ZONE_BY_KIND.get((o.get('part_kind'), m)) or m
    zo = zo if zo in old.ZONES or zo in old.GLOW else old.FALLBACK
    zn = zn if zn in new.ZONES or zn in new.GLOW else new.FALLBACK
    n += 1; used.add(zo)
    if zo != zn: diff += 1; print('DIFF zone', o.name, zo, zn)
for z in sorted(used):
    if z in old.ZONES and json.dumps(old.ZONES[z], sort_keys=True, default=str) != json.dumps(new.ZONES.get(z), sort_keys=True, default=str):
        diff += 1; print('DIFF recipe', z)
for k in ('LAYERS', 'CONCEPT', 'PATCH_FAMILIES', 'PATCH_FAMILIES_PARTS', 'ENGINE_GLOW', 'RUNNING_LIGHTS', 'DECALS', 'GLOW_STRENGTH', 'GLOW_TINT', 'LIGHT_STRENGTH', 'FALLBACK', 'GLOW'):
    if json.dumps(getattr(old, k), sort_keys=True, default=str) != json.dumps(getattr(new, k), sort_keys=True, default=str):
        diff += 1; print('DIFF', k)
print('ZONEPROOF', a[2], 'objects', n, 'zones used', sorted(used), 'SAME' if diff == 0 else 'DIFFERS %d' % diff)
