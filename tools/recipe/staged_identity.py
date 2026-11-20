"""Prove a private copy of a stage 7 export is exactly what was installed into a staging project (issue 1234, R341).

usage: staged_identity.py SNAPSHOT PROJECT CODE RECORD.json [--expect]
  Checks both ways: the GLB, every map the GLB names and manifest_entry.json in SNAPSHOT against the staging project's
  assets/ships/CODE folder and its manifest row; the set of export maps in that folder must equal the GLB's set. Writes the
  sha256 of every file to RECORD.json, or with --expect compares them with the RECORD.json written earlier. Exit 1 on any
  difference, with the reason.
"""
import json
from pathlib import Path
import sys

from check_export import read_glb
from manifest_merge import ENTRY, is_export_map, read_json, sha256


def identity(snapshot, project, code):
    glb = code + '.glb'
    live = project / 'assets' / 'ships' / code
    doc, _ = read_glb(snapshot / glb)
    maps = {image.get('uri') for image in doc.get('images', [])}
    for name in maps:
        if not isinstance(name, str) or not is_export_map(code, name):
            raise ValueError(f'unsupported export texture path {name!r}')
    staged_maps = {path.name for path in live.iterdir() if is_export_map(code, path.name)}
    if staged_maps != maps:
        raise ValueError(f'map sets differ: only in the copy {sorted(maps - staged_maps)}, '
                         f'only in staging {sorted(staged_maps - maps)}')
    record = {}
    for name in [glb, *sorted(maps)]:
        mine, theirs = sha256(snapshot / name), sha256(live / name)
        if mine != theirs:
            raise ValueError(f'{name} differs from the staged install')
        record[name] = mine
    entry = read_json(snapshot / ENTRY)
    row = read_json(project / 'assets' / 'ships' / 'manifest.json').get('ships', {}).get(code)
    if row != entry:
        raise ValueError(f'{ENTRY} differs from the staged manifest row for {code}')
    record[ENTRY] = sha256(snapshot / ENTRY)
    return record


def main(snapshot, project, code, record_path, *flags):
    record = identity(Path(snapshot), Path(project), code)
    record_path = Path(record_path)
    if '--expect' in flags:
        if read_json(record_path) != record:
            raise ValueError(f'the copy changed since {record_path} was written')
        print(f'[identity] {code} unchanged since the checks: {len(record)} files')
    else:
        record_path.write_text(json.dumps(record, indent=1, sort_keys=True), encoding='utf-8')
        print(f'[identity] {code} matches the staged install: {len(record)} files, glb {record[code + ".glb"]}')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main(*sys.argv[1:]))
    except (OSError, ValueError, TypeError) as exc:
        sys.exit(f'[identity] FAILED: {exc}')
