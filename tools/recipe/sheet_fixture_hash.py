# The staleness guard for the unpainted A16 fixture of godot/fx/test/death_seam_check.gd (opus_check_608 note 3, issue 532).
# Writes godot/fx/test/fixtures/C19_51_unbaked.sheet.txt: the sha256 of the files that make A16's sheet geometry (its design
# file, the sheet kit, the Hullbreaker kit parts, the build contract, the exporter, the hull builder and A16's ship json),
# concatenated in the listed order,
# and the list itself. death_seam_check.gd reads the list from that file, hashes the same files and fails when the fixture is
# stale (one home for the list: this script writes it, the check reads it). CI runs --check on every pull request (checks.yml,
# Godot game checks), so a stale fixture fails there by name.
# Regenerate the fixture and this record together, whenever any listed file changes:
#   python3 tools/blender/r209/sheet_hull.py -- OUT A16              (R209_SHIP=tools/recipe/ships/corsair_A16.json; bpy)
#   python3 run_blend.py OUT/A16.blend tools/recipe/export7.py -- tools/recipe/ships/corsair_A16.json EX maps=2048 unbaked=1
#   gzip -9 -n -c EX/C19_51.glb > godot/fx/test/fixtures/C19_51_unbaked.glb.gz
#   python3 tools/recipe/sheet_fixture_hash.py
import hashlib, os, sys
REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
FILES = ['tools/blender/build_sheets/ships/corsair_A16.py', 'tools/blender/build_sheets/kit.py', 'tools/blender/kits/hullbreakers/parts.py',
         'tools/blender/build_sheets/contract.py', 'tools/recipe/export7.py',
         # the hull builder and the recipe input of step 1 below (Muse's check of PR 611, BLOCKING 1; issue 618)
         'tools/blender/r209/sheet_hull.py', 'tools/recipe/ships/corsair_A16.json',
         # what export7.py imports and writes into the fixture: hard points and breach layout, turret pivots, the game's weapon
         # list (Muse's check of PR 620, BLOCKING 4.1). data.js, read through gamedata.py, is not listed: listing it would mark the
         # fixture stale on every rules edit; a data.js change to A16's own ship entry (c_boss) needs the rebuild below by hand.
         'tools/blender/kits/shared/hardpoints.py', 'tools/blender/kits/shared/turrets.py', 'tools/recipe/gamedata.py']
OUT = os.path.join(REPO, 'godot', 'fx', 'test', 'fixtures', 'C19_51_unbaked.sheet.txt')


def digest():
    h = hashlib.sha256()
    for f in FILES:
        h.update(open(os.path.join(REPO, f), 'rb').read().replace(b'\r\n', b'\n'))
    return h.hexdigest()


if __name__ == '__main__':
    d = digest()
    if '--check' in sys.argv:
        old = open(OUT).read().split('\n')[0].split()[-1]
        print('PASS fixture record matches' if old == d else 'FAIL fixture record is stale'); sys.exit(0 if old == d else 1)
    open(OUT, 'w', newline='\n').write('sha256 %s\n' % d + ''.join(f + '\n' for f in FILES))
    print('wrote', OUT, d)
