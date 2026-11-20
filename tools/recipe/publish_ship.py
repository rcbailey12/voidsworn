"""Publish an accepted ship build into the shared game build, and undo it (issue 1311). Called by tools/pc/jobs/publish_ship.bat.

  publish_ship.py receipt JOB CODE COMMIT GLB_SHA RECORD.json
      Refuses unless JOB/out/result.txt is a ship_job receipt for CODE built at exactly COMMIT that passed: one "start SHIP
      CODE ..." first line, exactly one "commit=COMMIT" line, a "done PASS" line and no "done FAILED" line, and a tail of
      "all done" or "all done" then "pin ok COMMIT" (the pinned wrappers). The collected export JOB/out/recipe/export/CODE
      must hold every file its CODE_export.json lists with that sha256, its glb must be exactly GLB_SHA, and every file the job
      checked (the clone's installed JOB/repo/godot/assets/ships/CODE, Godot's .import and .uid files aside) must be byte for
      byte the export's. Writes RECORD.json and prints SHIP=<ship id>.
  publish_ship.py backup GAME CODE BACKUP
      Before the install: copies the ship folder and its three cache scenes to BACKUP and records CODE's own rows of both
      manifests in BACKUP/before.json.
  publish_ship.py seal GAME CODE BACKUP
      After a passed publish: records what is now live for CODE (every file's sha256 and both manifest rows) in
      BACKUP/after.json. The undo refuses unless that is still what is live.
  publish_ship.py undo GAME CODE BACKUP
      Under the install lock (manifest_merge's .stage7.lock): refuses if CODE's live files or manifest rows changed since
      the seal; otherwise moves the published files aside to BACKUP/undone_<n>/, puts the kept ones back and restores only
      CODE's rows in both manifests (every other ship's row stays as it is now). Prints UNDO PASS, or UNDO FAILED with the
      reason and exit 1. Nothing is deleted.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sys

from manifest_merge import project_lock

SCENES = ('gen/ships/{c}.scn', 'gen/damage/{c}_damage.scn', 'gen/wreck/{c}_wreck.scn')
ASSET = 'assets/ships/manifest.json'
CACHE = 'gen/manifest.json'
SKIP = ('.import', '.uid')


def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for block in iter(lambda: f.read(1 << 20), b''):
            h.update(block)
    return h.hexdigest()


def read_json(path):
    return json.loads(Path(path).read_text(encoding='utf-8'))


def write_json(path, data):
    path = Path(path)
    tmp = path.with_name(path.name + '.publish_tmp')
    tmp.write_text(json.dumps(data, indent=1), encoding='utf-8', newline='\n')
    os.replace(tmp, path)


def row(game, rel, code):
    p = Path(game) / rel
    if not p.is_file():
        return None
    return read_json(p).get('ships', {}).get(code)


def receipt(job, code, commit, glb_sha, record):
    job = Path(job)
    if not re.fullmatch(r'[0-9a-f]{40}', commit):
        raise ValueError(f'COMMIT must be the full 40-character commit, got {commit!r}')
    if not re.fullmatch(r'[0-9a-f]{64}', glb_sha):
        raise ValueError(f'GLB_SHA must be the full 64-character sha256, got {glb_sha!r}')
    res = job / 'out' / 'result.txt'
    lines = [l.rstrip() for l in res.read_text(encoding='utf-8', errors='replace').splitlines()]
    lines = [l for l in lines if l]
    head = lines[0].split() if lines else []
    if len(head) < 3 or head[0] != 'start':
        raise ValueError(f'{res} does not start with a ship_job "start SHIP CODE" line')
    ship = head[1]
    if head[2] != code:
        raise ValueError(f'{res} is a receipt for {head[2]}, not {code}')
    commits = [l[len('commit='):].strip() for l in lines if l.startswith('commit=')]
    if commits != [commit]:
        raise ValueError(f'{res} commit lines {commits} are not exactly [{commit}]')
    if any(l.startswith('done FAILED') for l in lines):
        raise ValueError(f'{res} has a done FAILED line')
    if len(lines) >= 2 and lines[-1] == 'all done':
        before_end = lines[-2]
    elif len(lines) >= 3 and lines[-2] == 'all done' and lines[-1] == 'pin ok ' + commit:
        before_end = lines[-3]
    else:
        raise ValueError(f'{res} ends {lines[-2:]!r}, not "all done" or "all done" then "pin ok {commit}"')
    if not before_end.startswith('done PASS'):
        raise ValueError(f'{res}: the line before "all done" is {before_end!r}, not done PASS')
    export = job / 'out' / 'recipe' / 'export' / code
    listed = read_json(export / f'{code}_export.json').get('files', {})
    if f'{code}.glb' not in listed:
        raise ValueError(f'{code}_export.json lists no {code}.glb')
    for name, digest in listed.items():
        if sha256(export / name) != digest:
            raise ValueError(f'{name} in the collected export is not the sha256 its {code}_export.json lists')
    if listed[f'{code}.glb'] != glb_sha:
        raise ValueError(f'{code}.glb is {listed[code + ".glb"]}, not the expected {glb_sha}')
    inst = job / 'repo' / 'godot' / 'assets' / 'ships' / code
    checked = sorted(p.name for p in inst.iterdir() if p.is_file() and p.suffix not in SKIP)
    if f'{code}.glb' not in checked:
        raise ValueError(f'the job clone has no installed {code}.glb')
    for name in checked:
        if not (export / name).is_file() or sha256(export / name) != sha256(inst / name):
            raise ValueError(f'{name} was checked by the job but differs from (or is missing in) its collected export')
    write_json(record, dict(job=str(job), ship=ship, code=code, commit=commit, glb=glb_sha, files=listed, checked=checked))
    print(f'[publish] receipt ok: {ship} {code} commit {commit}, glb {glb_sha}, {len(listed)} listed and {len(checked)} checked files')
    print(f'SHIP={ship}')


def state(game, code):
    game = Path(game)
    live = game / 'assets' / 'ships' / code
    files = {p.name: sha256(p) for p in sorted(live.iterdir()) if p.is_file() and p.suffix not in SKIP} if live.is_dir() else None
    scenes = {s.format(c=code): sha256(game / s.format(c=code)) for s in SCENES if (game / s.format(c=code)).is_file()}
    return dict(files=files, scenes=scenes, asset_row=row(game, ASSET, code), cache_row=row(game, CACHE, code))


def backup(game, code, dest):
    game, dest = Path(game), Path(dest)
    dest.mkdir(parents=True, exist_ok=False)
    live = game / 'assets' / 'ships' / code
    with project_lock(game):
        if live.is_dir():
            shutil.copytree(live, dest / 'ship')
        for s in SCENES:
            src = game / s.format(c=code)
            if src.is_file():
                (dest / s.format(c=code)).parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dest / s.format(c=code))
        write_json(dest / 'before.json', state(game, code))
    print(f'[publish] kept {code} as it was in {dest}')


def seal(game, code, dest):
    with project_lock(Path(game)):
        write_json(Path(dest) / 'after.json', state(game, code))
    print(f'[publish] sealed what is now live for {code}')


def undo(game, code, dest):
    game, dest = Path(game), Path(dest)
    before, after = read_json(dest / 'before.json'), read_json(dest / 'after.json')
    with project_lock(game):
        now = state(game, code)
        if now != after:
            moved = [k for k in after if now.get(k) != after.get(k)]
            raise ValueError(f'{code} changed since this publish ({", ".join(moved)}); nothing was touched')
        missing = [str(dest / 'ship')] if before['files'] is not None and not (dest / 'ship').is_dir() else []
        missing += [str(dest / rel) for rel in before['scenes'] if not (dest / rel).is_file()]
        if missing:
            raise ValueError(f'the kept copies are missing ({", ".join(missing)}); nothing was touched')
        n = 1
        while (dest / f'undone_{n}').exists():
            n += 1
        aside = dest / f'undone_{n}'
        aside.mkdir()
        live = game / 'assets' / 'ships' / code
        if live.is_dir():
            os.replace(live, aside / 'ship')
        if before['files'] is not None:
            shutil.copytree(dest / 'ship', live)
        for s in SCENES:
            rel = s.format(c=code)
            if (game / rel).is_file():
                (aside / rel).parent.mkdir(parents=True, exist_ok=True)
                os.replace(game / rel, aside / rel)
            if rel in before['scenes']:
                shutil.copy2(dest / rel, game / rel)
        for rel, key in ((ASSET, 'asset_row'), (CACHE, 'cache_row')):
            path = game / rel
            if not path.is_file():
                if before[key] is None:
                    continue
                raise ValueError(f'{rel} is missing, so {code} row cannot be restored')
            data = read_json(path)
            shutil.copy2(path, aside / Path(rel).name.replace('.json', f'_{key}.json'))
            ships = data.setdefault('ships', {})
            if before[key] is None:
                ships.pop(code, None)
            else:
                ships[code] = before[key]
            write_json(path, data)
        restored = state(game, code)
        for key in ('files', 'scenes', 'asset_row', 'cache_row'):
            if restored[key] != before[key]:
                raise ValueError(f'after the undo {code} {key} is not what it was before the publish')
    print(f'[publish] the published {code} is kept in {aside}')
    print(f'UNDO PASS {code}')


def main(cmd, *args):
    fn = dict(receipt=receipt, backup=backup, seal=seal, undo=undo).get(cmd)
    if fn is None:
        raise ValueError(f'unknown command {cmd!r}')
    fn(*args)
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main(*sys.argv[1:]))
    except (OSError, ValueError, TypeError, KeyError, RuntimeError) as exc:
        label = 'UNDO FAILED' if sys.argv[1:2] == ['undo'] else '[publish] FAILED'
        sys.exit(f'{label}: {exc}')
