# Ship recipe, stage 7 install step: merge the export's manifest_entry.json into a Godot project's
# assets/ships/manifest.json. The entry holds the ship's class, band, length and hard point counts (gun, engine, bay, breach,
# core, rcs, board), so the game's own record of a ship always matches the export that was checked.
#   python manifest_merge.py MANIFEST_ENTRY.json GODOT_PROJECT_DIR
# Nothing is deleted: the old file is copied to manifest.json.bak_<date> first, the entry replaces (or adds) its own code, and
# every other ship stays as it was. The third argument is the ship's folder code (the ship json game_code).
#   python manifest_merge.py manifest_entry.json C:\path\to\godot CODE
import os, sys, json, shutil, time


def main(entry_path, godot, code):
    man_path = os.path.join(godot, 'assets', 'ships', 'manifest.json')
    entry = json.load(open(entry_path, encoding='utf-8'))
    man = json.load(open(man_path, encoding='utf-8')) if os.path.exists(man_path) else dict(note='', ships={})
    man.setdefault('ships', {})
    if os.path.exists(man_path):
        stamp = time.strftime('%Y%m%d_%H%M%S')
        shutil.copyfile(man_path, man_path + '.bak_' + stamp)
    man['ships'][code] = entry
    json.dump(man, open(man_path, 'w', encoding='utf-8'), indent=1)
    print('manifest PASS: ' + code + ' written into ' + man_path + ' with points ' + json.dumps(entry.get('hardpoints', {})))
    return 0


if __name__ == '__main__':
    if len(sys.argv) != 4:
        print('usage: python manifest_merge.py MANIFEST_ENTRY.json GODOT_PROJECT_DIR CODE')
        sys.exit(1)
    sys.exit(main(sys.argv[1], sys.argv[2], sys.argv[3]))
