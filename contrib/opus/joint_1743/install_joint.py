"""R421 joint sheet (issue 1743): lay the six painted Interior Kit V2 exports into a job checkout, as stage 7 does.

usage: install_joint.py RELAY_FOLDER GODOT_PROJECT

RELAY_FOLDER is the joint1743 folder of the voidsworn-relay checkout. Every file must match SHA256SUMS.txt beside this
script (the copy pinned in the job's commit), and no file may be missing or extra, or nothing is copied. For each hull it
moves an older <CODE>_damage.glb and <CODE>_wreck.glb aside into assets/ships_aside_joint1743/ (they belong to the old
hull, as stage 7 does), copies the glb and its maps into assets/ships/<CODE>/ and merges the export's manifest entry
with tools/recipe/manifest_merge.py. It deletes nothing. Prints JOINT INSTALL PASS or exits non-zero.
"""
import hashlib
import shutil
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
sys.path.insert(0, str(REPO / 'tools' / 'recipe'))
import manifest_merge  # noqa: E402

CODES = ['V16_37', 'H10_23', 'C19_51', 'B21_11', 'I15_11', 'D21_23']


def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for block in iter(lambda: f.read(1 << 20), b''):
            h.update(block)
    return h.hexdigest()


def main(relay, project):
    relay, project = Path(relay).resolve(), Path(project).resolve()
    want = {}
    for line in (HERE / 'SHA256SUMS.txt').read_text(encoding='utf-8').splitlines():
        if line.strip():
            digest, name = line.split(None, 1)
            want[name.strip()] = digest
    have = {p.relative_to(relay).as_posix() for p in relay.rglob('*') if p.is_file() and p.name != 'SHA256SUMS.txt'}
    missing, extra = sorted(set(want) - have), sorted(have - set(want))
    if missing or extra:
        sys.exit(f'JOINT INSTALL FAILED: missing {missing} extra {extra}')
    bad = [n for n, d in want.items() if sha(relay / n) != d]
    if bad:
        sys.exit(f'JOINT INSTALL FAILED: hash mismatch {bad}')
    if sorted({n.split('/')[0] for n in want}) != sorted(CODES):
        sys.exit('JOINT INSTALL FAILED: the hash list does not name the six hulls')
    ships = project / 'assets' / 'ships'
    aside = project / 'assets' / 'ships_aside_joint1743'
    for code in CODES:
        dest = ships / code
        dest.mkdir(parents=True, exist_ok=True)
        for suf in ('_damage', '_wreck'):
            old = dest / f'{code}{suf}.glb'
            if old.exists():
                aside.mkdir(parents=True, exist_ok=True)
                shutil.move(str(old), str(aside / old.name))
                print(f'moved aside {old.name}')
        for src in sorted((relay / code).iterdir()):
            if src.name in ('manifest_entry.json',) or src.name.endswith('_export.json'):
                continue
            shutil.copy2(src, dest / src.name)
            if sha(dest / src.name) != want[f'{code}/{src.name}']:
                sys.exit(f'JOINT INSTALL FAILED: copy of {code}/{src.name} does not match')
        if manifest_merge.main(str(relay / code / 'manifest_entry.json'), str(project), code) != 0:
            sys.exit(f'JOINT INSTALL FAILED: manifest merge for {code}')
    print(f'JOINT INSTALL PASS: {len(want)} files, hulls {" ".join(CODES)} into {ships}')
    return 0


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    sys.exit(main(sys.argv[1], sys.argv[2]))
