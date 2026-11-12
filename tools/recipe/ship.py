# Ship recipe helper (plain Python, runs on Blender's own python): read or start a ship's placement file and report the outline overlap.
#   ship.py SHIP get KEY            print a key of tools/recipe/ships/SHIP.json (empty if missing)
#   ship.py SHIP new FACTION        start SHIP.json from ships/_template.json (never overwrites)
#   ship.py SHIP gate SCORES.json   print the outline overlap against the ship's outline_gate; report only, never a pass bar
#                                   (RULEBOOK 5.8). Exits non-zero only when the score file cannot be read.
#   ship.py SHIP concept OUT.png    the concept as a PNG with its alpha (the outline the score is reported against)
import sys, os, json
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.normpath(os.path.join(HERE, '..', '..'))
ship, cmd = sys.argv[1], sys.argv[2]; P = os.path.join(HERE, 'ships', f'{ship}.json')
if cmd == 'get':
    d = json.load(open(P)) if os.path.exists(P) else {}; print(d.get(sys.argv[3], ''))
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
    Image.open(os.path.join(REPO, json.load(open(P))['concept'])).convert('RGBA').save(sys.argv[3]); print('wrote', sys.argv[3])
