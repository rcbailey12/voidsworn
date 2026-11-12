# Parts inventory and the per-cell table (issue 532 round 3; R218, RULEBOOK 5.16, ships.md 2c).
#   python inventory.py <code> <repo> <out dir> [<model json>]
# Without a model: writes inventory.md (the list written from the concept before modelling).
# With the model json from build.py: adds, per blob-sweep cell (bow, mid, stern x top, side, below), each inventory line
# with three ticks: PRESENT (the model has at least the listed count of parts carrying this inventory id), SHAPED (built by
# its kit part type, not a plain block), DETAILED (every sub-part of the kit type is modelled; tools/blender/kits/
# hullbreakers/parts.py SUBPARTS). Returns non-zero when a line is not present, shaped and detailed and the sheet does not
# say why (a 'why' entry in the ship's INV_NOTES). Every part has a job (R221, ships.md 2c, RULEBOOK 4.11): a line with no job,
# or a built part whose inventory id is missing or names no line, also fails.
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
         'make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:',
         '`tools/blender/build_sheets/ships/%s_inv.py`.\n' % CODE,
         '| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |', '|---|---|---|---|---:|---|---|---|']
no_job = [it['id'] for it in INV if not it.get('job')]
for it in INV:
    lines.append('| %s | %s | %s | %s%s | %d | %s | %s | %s |' % (it['id'], it.get('job') or '**NONE: cut it**', it['type'], it['what'],
                                                                (' (' + it['note'] + ')') if it.get('note') else '',
                                                                it['count'], ', '.join(it['cells']), it['reads'], it['src']))
lines.append('\nKit sub-parts per type (what DETAILED checks):\n')
for t in sorted({it['type'] for it in INV}):
    lines.append('- %s: %s' % (t, ', '.join(TYPES.get(t, ['(hull shaping, checked by eye on the side-by-side)']))))
lines.append('\nLeft as surface, and why:\n')
for w in inv.LEFT_PLAIN:
    lines.append('- ' + w)


def ratios(rd):
    """length to beam and length to height, concept sheet against build renders, the same measure on both"""
    from PIL import Image
    import numpy as np
    from scipy import ndimage

    def clean(d):
        d = ndimage.binary_opening(d, np.ones((3, 3)))
        lab, n = ndimage.label(d); sz = ndimage.sum(d, lab, range(1, n + 1)); return lab == (np.argmax(sz) + 1)

    def prof(m):
        xs = np.where(m.any(0))[0]; x0, x1 = xs.min(), xs.max(); L = x1 - x0
        ext = []
        for c in m[:, x0:x1 + 1].T:
            ys = np.where(c)[0]; ext.append(ys.max() - ys.min() if len(ys) else 0)
        ext = np.array(ext, float); mid = ext[int(0.2 * len(ext)):int(0.8 * len(ext))]
        ys = np.where(m.any(1))[0]
        return L, ys.max() - ys.min(), float(np.median(mid))
    im = np.asarray(Image.open(os.path.join(REPO, 'contrib/muse/design/concept_round8_2026_11', CODE + '_sheet.jpg')).convert('RGB')).astype(int)
    bg = np.median(im[5:40, 5:40].reshape(-1, 3), axis=0); d = np.abs(im - bg).sum(2) > 40
    h2 = im.shape[0] * 7 // 12; w2 = im.shape[1] * 3 // 4
    views = dict(concept=(clean(d[:h2, :w2]), clean(d[h2:, :w2])),
                 build=(clean(np.rot90(np.asarray(Image.open(os.path.join(rd, 'top.png')))[..., 3] > 8)),
                        clean(np.asarray(Image.open(os.path.join(rd, 'side.png')))[..., 3] > 8)))
    out = {}
    for k, (t, s_) in views.items():
        Lt, Bt, Bm = prof(t); Ls, Hs, Hm = prof(s_)
        out[k] = dict(env_LB=round(Lt / Bt, 2), env_LH=round(Ls / Hs, 2), hull_LB=round(Lt / Bm, 2), hull_LH=round(Ls / Hm, 2))
    return out


bad = len(no_job)
if no_job:
    lines.append('\nLines with no job (cut them): %s.' % ', '.join(no_job))
if MODEL:
    M = json.load(open(MODEL))
    built = {}
    ids = {it['id'] for it in INV}
    orphans = [p['id'] for p in M.get('parts', []) if not set(p.get('inv', [])) & ids]
    bad += len(orphans)
    lines.append('\n## Every built part has a job (R221)\n')
    lines.append('Built kit parts: %d; parts whose inventory id names no line with a job: %d%s.' % (
        len(M.get('parts', [])), len(orphans), (' (' + ', '.join(orphans) + ')') if orphans else ''))
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
    # ---- structure, not only parts (the Board on round 3, ships.md 2c): distinct masses per cell, concept against build ----
    lo_z = min(m['z'][0] for m in M.get('masses', [])) if M.get('masses') else M['lo'][2]  # the belly, not claw tips
    regs = {'bow': (0.0, 33.4), 'mid': (33.3, 66.7), 'stern': (66.6, 100.0)}
    SC = getattr(inv, 'STRUCTURE', {})
    srows = []
    lines.append('\n## Structure per cell: distinct masses (blocks, tiers, belts), concept against build\n')
    lines.append('Concept counts read off the round 8 sheet by eye (%s); build counts are the model\'s registered masses whose station range '
                 'overlaps the third (below: masses reaching within 0.8 of the belly).\n' % getattr(inv, 'STRUCTURE_NOTE', 'see the inventory file'))
    lines.append('| Cell | Concept | Build | Build masses |\n|---|---:|---:|---|')
    for c in CELLS:
        reg, view = c.split('/')
        a, b = regs[reg]
        ms = [m for m in M.get('masses', []) if m['st'][0] < b and m['st'][1] > a and (view != 'below' or m['z'][0] <= lo_z + 0.8)
              and (view != 'side' or m['y'][1] > 0.05)]  # the side view is the port beam: starboard-only masses are hidden
        cc = SC.get(c)
        srows.append(dict(cell=c, concept=cc, build=len(ms)))
        lines.append('| %s | %s | %d | %s |' % (c, cc if cc is not None else 'no view', len(ms), '; '.join(m['name'] for m in ms)[:240]))
    rat = None
    rd = os.path.dirname(MODEL)
    if os.path.exists(os.path.join(rd, 'top.png')) and os.path.exists(os.path.join(rd, 'side.png')):
        rat = ratios(rd)
        lines.append('\n## Proportions: length to beam and length to height, concept against build (the Board on round 3)\n')
        lines.append('Measured the same way on both: the concept sheet\'s top and side views and the blockout\'s top and side renders, bow left. '
                     'Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length '
                     '(dishes, guns and antennas sticking out at a few stations do not count).\n')
        lines.append('| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |\n|---|---:|---:|---:|---:|')
        for k_ in ('concept', 'build'):
            r_ = rat[k_]
            lines.append('| %s | %.2f | %.2f | %.2f | %.2f |' % (k_, r_['env_LB'], r_['env_LH'], r_['hull_LB'], r_['hull_LH']))
    json.dump(dict(rows=rows, failing=bad, structure=srows, ratios=rat), open(os.path.join(OUT, 'cells.json'), 'w'), indent=1)
    lines.append('\nLines not present, shaped and detailed without a reason: %d.' % bad)
open(os.path.join(OUT, 'inventory.md'), 'w').write('\n'.join(lines) + '\n')
print('inventory', CODE, 'failing', bad)
sys.exit(1 if bad else 0)
