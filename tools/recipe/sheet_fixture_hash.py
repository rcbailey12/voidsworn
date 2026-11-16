# The staleness guard for the unpainted A16 fixture of godot/fx/test/death_seam_check.gd (opus_check_608 note 3, issue 532).
# Writes godot/fx/test/fixtures/C19_51_unbaked.sheet.txt: the sha256 of the files that make A16's sheet geometry (its design
# file, the sheet kit, the Hullbreaker kit parts, the build contract, the exporter, the hull builder and A16's ship json),
# concatenated in the listed order, plus a canonical extract of A16's own data.js entry (c_boss: the fields the build reads,
# through gamedata.py, as sorted-key JSON), and the list and the extract themselves. death_seam_check.gd reads the list and
# the extract from that file, hashes the same bytes and fails when the fixture is stale (one home for both: this script
# writes them, the check reads them). CI runs --check on every pull request (checks.yml, Godot game checks), so a stale
# fixture fails there by name.
# Regenerate the fixture and this record together, whenever any listed file changes or A16's data.js entry (c_boss) changes:
#   python3 tools/blender/r209/sheet_hull.py -- OUT A16              (R209_SHIP=tools/recipe/ships/corsair_A16.json; bpy)
#   python3 run_blend.py OUT/A16.blend tools/recipe/export7.py -- tools/recipe/ships/corsair_A16.json EX maps=2048 unbaked=1
#   gzip -9 -n -c EX/C19_51.glb > godot/fx/test/fixtures/C19_51_unbaked.glb.gz
#   python3 tools/recipe/sheet_fixture_hash.py
import hashlib, json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
FILES = ['tools/blender/build_sheets/ships/corsair_A16.py', 'tools/blender/build_sheets/kit.py', 'tools/blender/kits/hullbreakers/parts.py',
         'tools/blender/build_sheets/contract.py', 'tools/recipe/export7.py',
         # the hull builder and the recipe input of step 1 below (Muse's check of PR 611, BLOCKING 1; issue 618)
         'tools/blender/r209/sheet_hull.py', 'tools/recipe/ships/corsair_A16.json',
         # what export7.py imports and writes into the fixture: hard points and breach layout, turret pivots, the game's weapon
         # list (Muse's check of PR 620, BLOCKING 4.1). data.js is not listed: listing it would mark the fixture stale on every
         # rules edit. Instead the digest below also reads A16's own entry (c_boss) through gamedata.py and hashes only the
         # fields the build reads, as sorted-key JSON, so a c_boss edit marks the fixture stale and any other ship's edit does not.
         'tools/blender/kits/shared/hardpoints.py', 'tools/blender/kits/shared/turrets.py', 'tools/recipe/gamedata.py']
SHIP_JSON = 'tools/recipe/ships/corsair_A16.json'
OUT = os.path.join(REPO, 'godot', 'fx', 'test', 'fixtures', 'C19_51_unbaked.sheet.txt')
EXTRACT_MARK = '# data.js entry %s: the fields the build reads (tools/recipe/gamedata.py), sorted keys, JSON'


def extract():
    """the canonical extract of A16's data.js entry: the fields export7.py reads through gamedata.py, as sorted-key JSON"""
    import gamedata
    ship = json.load(open(os.path.join(REPO, SHIP_JSON), encoding='utf-8'))
    game = ship['game_ship']
    fields = dict(cls=gamedata.ship_attr(game, 'cls', default='Cruiser'),
                  fac=gamedata.ship_attr(game, 'fac', default=ship.get('faction')),
                  hangar=int(gamedata.ship_attr(game, 'hangar', default=0) or 0),
                  weapons=[list(w) for w in gamedata.weapons(game)])
    return json.dumps(fields, sort_keys=True, separators=(',', ':')), game


def digest(text):
    h = hashlib.sha256()
    for f in FILES:
        h.update(open(os.path.join(REPO, f), 'rb').read().replace(b'\r\n', b'\n'))
    h.update((text + '\n').encode('utf-8'))
    return h.hexdigest()


if __name__ == '__main__':
    try:
        text, game = extract()
    except ValueError as e:
        print('FAIL', e); sys.exit(1)
    d = digest(text)
    if '--check' in sys.argv:
        try:
            old = open(OUT, encoding='utf-8').read().split('\n')[0].split()[-1]
        except (OSError, IndexError):
            print('FAIL fixture record is missing or unreadable'); sys.exit(1)
        print('PASS fixture record matches' if old == d else 'FAIL fixture record is stale'); sys.exit(0 if old == d else 1)
    open(OUT, 'w', newline='\n').write('sha256 %s\n' % d + ''.join(f + '\n' for f in FILES)
                                      + (EXTRACT_MARK % game) + '\n' + text + '\n')
    print('wrote', OUT, d)
