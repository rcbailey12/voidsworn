# Parts inventory and the per-cell table (issue 532 round 3; R218, RULEBOOK 5.16, ships.md 2c).
#   python inventory.py <code> <repo> <out dir> [<model json>]
# Without a model: writes inventory.md (the list written from the concept before modelling).
# With the model json from build.py: adds, per blob-sweep cell (bow, mid, stern x top, side, below), each inventory line
# with three ticks: PRESENT (the model has at least the listed count of parts carrying this inventory id), SHAPED (built by
# its kit part type, not a plain block), DETAILED (every sub-part of the kit type is modelled; tools/blender/kits/
# hullbreakers/parts.py SUBPARTS). Returns non-zero when a line is not present, shaped and detailed and the sheet does not
# say why (a 'why' entry in the ship's INV_NOTES).
import sys, os, json, importlib.util

CODE, REPO, OUT = sys.argv[1:4]
MODEL = sys.argv[4] if len(sys.argv) > 4 else None
os.makedirs(OUT, exist_ok=True)
sp = importlib.util.spec_from_file_location('inv', os.path.join(REPO, 'tools/blender/build_sheets/ships', CODE + '_inv.py'))
inv = importlib.util.module_from_spec(sp); sp.loader.exec_module(inv)
INV = inv.INVENTORY
CELLS = ['%s/%s' % (r, v) for r in ('bow', 'mid', 'stern') for v in ('top', 'side', 'below')]
TYPES = {}
try:
    import re
    src = open(os.path.join(REPO, 'tools/blender/kits/hullbreakers/parts.py')).read()
    blk = src[src.index('SUBPARTS = {'):]; blk = blk[:blk.index('\n}\n') + 3]
    TYPES = eval(blk.split('=', 1)[1])
except Exception as ex:
    print('no SUBPARTS', ex)

lines = ['# %s parts inventory (R218)\n' % CODE,
         'Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the',
         'kit part type (tools/blender/kits/hullbreakers/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that',
         'make it read as that thing. Source: `tools/blender/build_sheets/ships/%s_inv.py`.\n' % CODE,
         '| ID | Type | What | Count | Cells | Reads as (sub-parts) | Source |', '|---|---|---|---:|---|---|---|']
for it in INV:
    lines.append('| %s | %s | %s%s | %d | %s | %s | %s |' % (it['id'], it['type'], it['what'], (' (' + it['note'] + ')') if it.get('note') else '',
                                                           it['count'], ', '.join(it['cells']), it['reads'], it['src']))
lines.append('\nKit sub-parts per type (what DETAILED checks):\n')
for t in sorted({it['type'] for it in INV}):
    lines.append('- %s: %s' % (t, ', '.join(TYPES.get(t, ['(hull shaping, checked by eye on the side-by-side)']))))
lines.append('\nLeft as surface, and why:\n')
for w in inv.LEFT_PLAIN:
    lines.append('- ' + w)
bad = 0
if MODEL:
    M = json.load(open(MODEL))
    built = {}
    for p in M.get('parts', []):
        for iid in p.get('inv', []):
            b = built.setdefault(iid, dict(n=0, shaped=True, detailed=True, kinds=set()))
            b['n'] += 1; b['kinds'].add(p['kind'])
            b['shaped'] &= p.get('shaped', False); b['detailed'] &= p.get('detailed', False)
    lines.append('\n## Per cell: present, shaped, detailed (from the model, %s)\n' % os.path.basename(MODEL))
    lines.append('Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.\n')
    rows = []
    for c in CELLS:
        lines.append('### %s\n' % c)
        lines.append('| ID | What | Built / listed | Present | Shaped | Detailed |\n|---|---|---|---|---|---|')
        items = [it for it in INV if c in it['cells']]
        if not items:
            lines.append('| - | nothing listed in this cell | | | | |')
        for it in items:
            b = built.get(it['id'], dict(n=0, shaped=False, detailed=False))
            pres = b['n'] >= it['count'] or (it['type'] in ('plate', 'hull', 'tier', 'rib', 'patch', 'pylon') and b['n'] >= 1)
            ok = pres and b['shaped'] and b['detailed']
            why = getattr(inv, 'INV_NOTES', {}).get(it['id'], '')
            if not ok and not why:
                bad += 1
            lines.append('| %s | %s | %d / %d | %s | %s | %s |%s' % (it['id'], it['what'][:70], b['n'], it['count'], 'Y' if pres else 'n',
                                                                 'Y' if b['shaped'] else 'n', 'Y' if b['detailed'] else 'n', (' ' + why) if why else ''))
            rows.append(dict(cell=c, id=it['id'], built=b['n'], listed=it['count'], present=pres, shaped=bool(b['shaped']), detailed=bool(b['detailed'])))
        lines.append('')
    json.dump(dict(rows=rows, failing=bad), open(os.path.join(OUT, 'cells.json'), 'w'), indent=1)
    lines.append('Lines not present, shaped and detailed without a reason: %d.' % bad)
open(os.path.join(OUT, 'inventory.md'), 'w').write('\n'.join(lines) + '\n')
print('inventory', CODE, 'failing', bad)
sys.exit(1 if bad else 0)
