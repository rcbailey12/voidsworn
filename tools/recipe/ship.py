# Ship recipe helper (plain Python, runs on Blender's own python): read or start a ship's placement file and report the outline overlap.
#   ship.py SHIP get KEY            print a key of tools/recipe/ships/SHIP.json (empty if missing). For a ship built from a
#                                   build sheet ("sheet" in the json) the sheet is the one home of its class length:
#                                   length_world is read from tools/blender/build_sheets/ships/<sheet>.py LENGTH (R225)
#   ship.py SHIP new FACTION        start SHIP.json from ships/_template.json (never overwrites)
#   ship.py SHIP gate SCORES.json   print the outline overlap against the ship's outline_gate; report only, never a pass bar
#                                   (RULEBOOK 5.8). Exits non-zero only when the score file cannot be read.
#   ship.py SHIP concept OUT.png    the concept named by the json ("concept") as a square PNG with its alpha (the outline the
#                                   score is reported against). A picture without its own alpha (an accepted beauty JPEG) is
#                                   cut out by the build sheets' rule: luminance over 28, closed, holes filled, the largest
#                                   shape only; a picture that is not square is padded square (transparent; black for raw), never stretched
#   ship.py SHIP concept OUT.png raw  the same picture squared, with no cut-out: stage 2's input when the concept has no alpha
#                                   of its own, so TRELLIS.2 removes the background with its own model (the luminance rule
#                                   loses a dark hull's belly against a dark sky)
import sys, os, json
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.normpath(os.path.join(HERE, '..', '..'))
ship, cmd = sys.argv[1], sys.argv[2]; P = os.path.join(HERE, 'ships', f'{ship}.json')

def sheet_length(sheet):
    """LENGTH of a build sheet's design file, read without running it (it imports bpy)"""
    import ast
    src = os.path.join(REPO, 'tools', 'blender', 'build_sheets', 'ships', sheet + '.py')
    for node in ast.parse(open(src, encoding='utf-8').read()).body:
        if isinstance(node, ast.Assign) and any(getattr(t, 'id', '') == 'LENGTH' for t in node.targets):
            return float(ast.literal_eval(node.value))
    raise SystemExit(f'no LENGTH in {src}')


def get(d, key):
    if key == 'length_world' and d.get('sheet'): return sheet_length(d['sheet'])
    return d.get(key, '')


def cutout(im):
    """the concept's outline as alpha: its own alpha when it has one, else the build sheets' luminance rule"""
    import numpy as np
    from PIL import Image
    a = np.asarray(im.convert('RGBA'))
    if a[:, :, 3].min() < 250: return Image.fromarray(a)
    from scipy import ndimage
    lum = a[:, :, :3].astype(float) @ [.299, .587, .114]
    m = ndimage.binary_fill_holes(ndimage.binary_closing(lum > 28, iterations=2))
    lab, n = ndimage.label(m)
    if n > 1: m = lab == (1 + int(np.argmax(ndimage.sum(m, lab, range(1, n + 1)))))
    a = a.copy(); a[:, :, 3] = np.where(m, 255, 0).astype(np.uint8); return Image.fromarray(a)


if cmd == 'get':
    d = json.load(open(P)) if os.path.exists(P) else {}; print(get(d, sys.argv[3]))
elif cmd == 'new':
    if os.path.exists(P): print('already there:', P); sys.exit(0)
    d = json.load(open(os.path.join(HERE, 'ships', '_template.json')))
    d.update(ship=ship, faction=sys.argv[3], concept=f'docs/ship_pipeline/concepts/{ship}.webp', cell=f'{ship}_A', parts=[])
    json.dump(d, open(P, 'w'), indent=1); print('started', P)
elif cmd == 'gate':
    # RULEBOOK 5.8: the outline overlap is reported, not a pass bar. The gate is printed for context only.
    d = json.load(open(P)); s = json.load(open(sys.argv[3])); g = 100 * d.get('outline_gate', .9)
    cell = d.get('cell'); v = s.get(cell, {}).get('overlap', 0)
    print('REPORT', f'{cell} outline overlap {v} percent, outline_gate {g:.0f} is context only (not a pass bar)')
elif cmd == 'concept':
    try:
        from PIL import Image
    except ImportError:
        print('Pillow missing: run 3_trace_hull.bat once (it installs scipy and Pillow into Blender\'s python)'); sys.exit(1)
    im = Image.open(os.path.join(REPO, json.load(open(P))['concept']))
    if 'raw' not in sys.argv[4:]: im = cutout(im)
    elif im.convert('RGBA').getextrema()[3][0] >= 250: im = im.convert('RGB')      # no alpha of its own: leave the cut to TRELLIS.2
    else: im = im.convert('RGBA')
    w, h = im.size
    if w != h:      # square, centred, transparent margin: the outline tools work on a square picture
        sq = Image.new(im.mode, (max(w, h), max(w, h)), (0, 0, 0, 0) if im.mode == 'RGBA' else (0, 0, 0)); sq.paste(im, ((max(w, h) - w) // 2, (max(w, h) - h) // 2)); im = sq
    im.save(sys.argv[3]); print('wrote', sys.argv[3], im.size)
