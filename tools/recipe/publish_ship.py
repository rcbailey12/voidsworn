"""Publish an accepted ship build into the shared game build, and undo it (issue 1311). Called by tools/pc/jobs/publish_ship.bat.

  publish_ship.py receipt JOB CODE COMMIT GLB_SHA RECORD.json
      Refuses unless JOB/out/result.txt is a ship_job receipt for CODE built at exactly COMMIT that passed: one "start SHIP
      CODE ..." first line, exactly one "commit=COMMIT" line, a "done PASS" line and no "done FAILED" line, and a tail of
      "all done" or "all done" then "pin ok COMMIT" (the pinned wrappers). The collected export JOB/out/recipe/export/CODE
      must hold every file its CODE_export.json lists with that sha256, its glb must be exactly GLB_SHA, and every file the job
      checked (the clone's installed JOB/repo/godot/assets/ships/CODE, Godot's .import and .uid files aside) must be byte for
      byte the export's. JOB/out/recipe/log_detail.txt must hold one surface-detail verdict, a PASS or a dated opt-out
      from Ryan (issue 1517). Writes RECORD.json and prints SHIP=<ship id>.
  publish_ship.py backup GAME CODE BACKUP
      Before the install: copies the ship folder and its three cache scenes to BACKUP and records CODE's own rows of both
      manifests in BACKUP/before.json. Marks this attempt as the latest publish of CODE in GAME/_replaced/CODE.owner.
  publish_ship.py restore GAME CODE BACKUP
      After a failed install, under the install lock: refuses, touching nothing, unless this attempt is still the latest
      publish of CODE (a later one took the mark). Puts every kept file and row back; RESTORE PASS or RESTORE FAILED.
  publish_ship.py seal GAME CODE BACKUP
      After a passed publish: records what is now live for CODE (every file's sha256 and both manifest rows) in
      BACKUP/after.json. The undo refuses unless that is still what is live.
  publish_ship.py undo GAME CODE BACKUP
      Under the install lock (manifest_merge's .stage7.lock): refuses, touching nothing, if CODE's live files or manifest
      rows changed since the seal or a kept copy does not hash as recorded before the publish. Then stages the kept files and
      the two manifests (only CODE's row changed; every other ship's row stays as it is now) in BACKUP/undone_<n>/stage, and
      swaps them in, the published files moved to BACKUP/undone_<n>/published. Any failure there puts the published state
      back. Prints UNDO PASS, or UNDO FAILED with the reason and exit 1. Nothing is deleted.
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


def _listed(files, code):
    """CODE_export.json "files": export7 writes {name: {"bytes": N, "sha256": hex}}; a bare hex string is accepted too.
    Returns ({name: sha256}, {name: bytes}). Anything else is refused (PR 1312 run one stopped on the dict shape)."""
    if not isinstance(files, dict):
        raise ValueError(f'{code}_export.json "files" is not a table of files')
    listed, sizes = {}, {}
    for name, entry in files.items():
        digest = entry.get('sha256') if isinstance(entry, dict) else entry
        if not isinstance(digest, str) or not re.fullmatch(r'[0-9a-f]{64}', digest):
            raise ValueError(f'{code}_export.json lists {name} without a full sha256')
        listed[name] = digest
        if isinstance(entry, dict) and 'bytes' in entry:
            sizes[name] = int(entry['bytes'])
    return listed, sizes


DETAIL_OK = ('PASS detail check', 'OPT-OUT detail check')


def detail_pass(log):
    """issue 1517: the job's stage 5 surface-detail verdict (tools/recipe/detail_check.py) must be a PASS, or a dated opt-out
    from Ryan; a missing log, a FAIL or a ship whose detail was never measured is refused. Returns the verdict line."""
    if not Path(log).is_file():
        raise ValueError(f'{log} is missing: the job has no stage 5 surface-detail verdict, so it cannot be published')
    lines = [l.strip() for l in Path(log).read_text(encoding='utf-8', errors='replace').splitlines()]
    verdicts = [l for l in lines if l.startswith(DETAIL_OK) or l.startswith(('detail check FAIL', 'detail check NOT RUN'))]
    if len(verdicts) != 1 or not verdicts[0].startswith(DETAIL_OK):
        raise ValueError(f'{log} has no surface-detail PASS (issue 1517): {verdicts or "no verdict line"}')
    return verdicts[0]


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
    detail = detail_pass(job / 'out' / 'recipe' / 'log_detail.txt')
    export = job / 'out' / 'recipe' / 'export' / code
    listed, sizes = _listed(read_json(export / f'{code}_export.json').get('files', {}), code)
    if f'{code}.glb' not in listed:
        raise ValueError(f'{code}_export.json lists no {code}.glb')
    for name, digest in listed.items():
        if not (export / name).is_file() or sha256(export / name) != digest:
            raise ValueError(f'{name} in the collected export is not the sha256 its {code}_export.json lists')
        if name in sizes and (export / name).stat().st_size != sizes[name]:
            raise ValueError(f'{name} in the collected export is not the size its {code}_export.json lists')
    if listed[f'{code}.glb'] != glb_sha:
        raise ValueError(f'{code}.glb is {listed[code + ".glb"]}, not the expected {glb_sha}')
    inst = job / 'repo' / 'godot' / 'assets' / 'ships' / code
    checked = sorted(p.name for p in inst.iterdir() if p.is_file() and p.suffix not in SKIP)
    if f'{code}.glb' not in checked:
        raise ValueError(f'the job clone has no installed {code}.glb')
    for name in checked:
        if not (export / name).is_file() or sha256(export / name) != sha256(inst / name):
            raise ValueError(f'{name} was checked by the job but differs from (or is missing in) its collected export')
    write_json(record, dict(job=str(job), ship=ship, code=code, commit=commit, glb=glb_sha, files=listed, checked=checked,
                            detail=detail))
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
        claim(game, code, dest)
    print(f'[publish] kept {code} as it was in {dest}')


def _owner(game, code):
    return Path(game) / '_replaced' / f'{code}.owner'


def claim(game, code, dest):
    """marks this attempt as the latest publish of CODE (called under the install lock, by backup). A later publish of the same
    ship takes the mark, so an older attempt's restore cannot roll back its work (Artoo, PR 1312)"""
    _owner(game, code).parent.mkdir(parents=True, exist_ok=True)
    _owner(game, code).write_text(str(Path(dest).resolve()), encoding='utf-8')


def owns(game, code, dest):
    p = _owner(game, code)
    return p.is_file() and p.read_text(encoding='utf-8').strip() == str(Path(dest).resolve())


def seal(game, code, dest):
    with project_lock(Path(game)):
        write_json(Path(dest) / 'after.json', state(game, code))
    print(f'[publish] sealed what is now live for {code}')


def _put_back(game, code, dest, before, label):
    """puts CODE back exactly as before.json recorded it (called under the install lock): the kept copies are hashed against
    the record and staged before anything live moves; any failure puts the live state back as it was"""
    live = game / 'assets' / 'ships' / code
    # 1. the kept copies must hash exactly as recorded before the publish, and are staged before anything live moves
    if before['files'] is not None:
        kept = {p.name: sha256(p) for p in sorted((dest / 'ship').iterdir()) if p.is_file() and p.suffix not in SKIP} \
            if (dest / 'ship').is_dir() else None
        if kept != before['files']:
            raise ValueError(f'the kept copy of {code} is not what was live before the publish; nothing was touched')
    for rel, digest in before['scenes'].items():
        if not (dest / rel).is_file() or sha256(dest / rel) != digest:
            raise ValueError(f'the kept {rel} is missing or not what was live before the publish; nothing was touched')
    n = 1
    while (dest / f'undone_{n}').exists():
        n += 1
    aside = dest / f'undone_{n}'
    stage = aside / 'stage'
    stage.mkdir(parents=True)
    if before['files'] is not None:
        shutil.copytree(dest / 'ship', stage / 'ship')
    for rel in before['scenes']:
        (stage / rel).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(dest / rel, stage / rel)
    manifests = []
    for rel, key in ((ASSET, 'asset_row'), (CACHE, 'cache_row')):
        path = game / rel
        if not path.is_file():
            if before[key] is None:
                continue
            raise ValueError(f'{rel} is missing, so the {code} row cannot be restored; nothing was touched')
        data = read_json(path)
        ships = data.setdefault('ships', {})
        if ships.get(code) == before[key]:
            continue                      # this row is already right: the file is left exactly as it is
        if before[key] is None:
            ships.pop(code, None)
        else:
            ships[code] = before[key]
        staged = stage / (Path(rel).name.replace('.json', f'_{key}.json'))
        staged.write_text(json.dumps(data, indent=1), encoding='utf-8', newline='\n')
        manifests.append((path, staged))
    if (stage / 'ship').exists() and {p.name: sha256(p) for p in (stage / 'ship').iterdir() if p.is_file() and p.suffix not in SKIP} != before['files']:
        raise ValueError(f'the staged copy of {code} does not hash as recorded; nothing was touched')

    # 2. the live changes, each one recorded so any failure puts the published state back
    done = []          # (live path, where the published one went or None)

    def swap(target, incoming):
        gone = None
        if target.exists():
            gone = aside / 'published' / target.relative_to(game)
            gone.parent.mkdir(parents=True, exist_ok=True)
            os.replace(target, gone)
        done.append((target, gone))
        if incoming is not None:
            os.replace(incoming, target)
    try:
        swap(live, stage / 'ship' if before['files'] is not None else None)
        for s_ in SCENES:
            rel = s_.format(c=code)
            swap(game / rel, stage / rel if rel in before['scenes'] else None)
        for path, staged in manifests:
            swap(path, staged)
        restored = state(game, code)
        for key in ('files', 'scenes', 'asset_row', 'cache_row'):
            if restored[key] != before[key]:
                raise ValueError(f'after the {label} {code} {key} is not what it was before the publish')
    except BaseException as exc:
        errors = []
        for target, gone in reversed(done):
            try:
                if target.exists():
                    failed = aside / 'failed' / target.relative_to(game)
                    failed.parent.mkdir(parents=True, exist_ok=True)
                    os.replace(target, failed)
                if gone is not None:
                    os.replace(gone, target)
            except OSError as e:
                errors.append(str(e))
        if errors:
            raise RuntimeError(f'{label} failed ({exc}) and could not put the live {code} back: {" | ".join(errors)}; '
                               f'files in {aside}') from None
        raise ValueError(f'{exc}; the live {code} was put back as it was') from None
    print(f"[publish] the {label}: the live {code} it replaced is kept in {aside / 'published'}")


def undo(game, code, dest):
    game, dest = Path(game), Path(dest)
    before, after = read_json(dest / 'before.json'), read_json(dest / 'after.json')
    with project_lock(game):
        now = state(game, code)
        if now != after:
            moved = [k for k in after if now.get(k) != after.get(k)]
            raise ValueError(f'{code} changed since this publish ({", ".join(moved)}); nothing was touched')
        _put_back(game, code, dest, before, 'undo')
    print(f'UNDO PASS {code}')


def restore(game, code, dest):
    """after a failed install: manifest_merge's own rollback puts back the ship folder, its scene and both manifests, but the
    cache refresh rewrites gen/damage and gen/wreck in place (Fable, PR 1312). Puts every kept file and row back from the
    backup; prints RESTORE PASS when CODE is exactly as before the publish, RESTORE FAILED naming what still differs."""
    game, dest = Path(game), Path(dest)
    before = read_json(dest / 'before.json')
    with project_lock(game):
        if not owns(game, code, dest):
            raise ValueError(f'another publish of {code} started after this one ({_owner(game, code)}); nothing was touched')
        now = state(game, code)
        if now == before:
            print(f'RESTORE PASS {code}: already exactly as before the publish')
            return
        moved = [k for k in before if now.get(k) != before.get(k)]
        print(f'[publish] {code} differs from before the publish in {", ".join(moved)}; putting it back')
        _put_back(game, code, dest, before, 'restore')
    print(f'RESTORE PASS {code}')


def locked(game, *command):
    """runs COMMAND (the Godot cache build) holding the install lock, so no install or undo runs under it"""
    import subprocess
    with project_lock(Path(game)):
        return subprocess.run(list(command)).returncode


def main(cmd, *args):
    fn = dict(receipt=receipt, backup=backup, seal=seal, undo=undo, restore=restore, locked=locked).get(cmd)
    if fn is None:
        raise ValueError(f'unknown command {cmd!r}')
    return fn(*args) or 0


if __name__ == '__main__':
    try:
        sys.exit(main(*sys.argv[1:]))
    except (OSError, ValueError, TypeError, KeyError, RuntimeError) as exc:
        label = {'undo': 'UNDO FAILED', 'restore': 'RESTORE FAILED'}.get(sys.argv[1] if len(sys.argv) > 1 else '', '[publish] FAILED')
        sys.exit(f'{label}: {exc}')
