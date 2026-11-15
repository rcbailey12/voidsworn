"""Replace selected bench rows with a new capture from identical FX source."""
import argparse
import json
from pathlib import Path
import shutil

if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('target', type=Path)
    p.add_argument('patch', type=Path)
    p.add_argument('--allow-source-change', action='store_true')
    p.add_argument('--replace-id', help='Replace one mistaken fixture id with the single recaptured id')
    args = p.parse_args()
    target, patch = args.target.resolve(), args.patch.resolve()
    old_hashes = json.loads((target/'source_hashes.json').read_text())
    new_hashes = json.loads((patch/'source_hashes.json').read_text())
    assert args.allow_source_change or old_hashes == new_hashes
    original = json.loads((target/'bench.json').read_text())
    update = json.loads((patch/'bench.json').read_text())
    assert not update['warnings']
    replacements = {(r['id'], r['cam']): r for r in update['stills']}
    replacement_id = None
    if args.replace_id:
        ids = {r['id'] for r in update['stills']}
        assert len(ids) == 1
        replacement_id = ids.pop()
        assert any(r['id'] == args.replace_id for r in original['stills'])
        assert not any(r['id'] == replacement_id for r in original['stills'])
    for row in replacements.values():
        for key in ['file', 'native_file']:
            if key in row:
                src, dst = (patch/row[key]).resolve(), (target/row[key]).resolve()
                assert src.is_relative_to(patch) and dst.is_relative_to(target)
                shutil.copy2(src, dst)
    original['stills'] = [replacements[(replacement_id, r['cam'])] if r['id'] == args.replace_id
        else replacements.get((r['id'], r['cam']), r) for r in original['stills']]
    if replacement_id:
        cfg = json.loads((target/'moments.json').read_text())
        patch_cfg = json.loads((patch/'moments.json').read_text())
        new_row = next(r for r in patch_cfg['rows'] if r['id'] == replacement_id)
        cfg['rows'] = [new_row if r['id'] == args.replace_id else r for r in cfg['rows']]
        (target/'moments.json').write_text(json.dumps(cfg, indent=1))
    original['parts']['recapture_' + patch.name] = dict(source=str(patch), ids=sorted(set(r['id'] for r in replacements.values())),
        original_fx_sha256=old_hashes, replacement_fx_sha256=new_hashes)
    if replacement_id:
        original['parts']['recapture_' + patch.name]['replaces_fixture'] = args.replace_id
    if args.allow_source_change:
        original['parts']['recapture_' + patch.name]['reason'] = 'Only these looks use the changed craft-trail path. Other source branches are unchanged.'
    (target/'bench.json').write_text(json.dumps(original, indent=1))
    print(f'Replaced {len(replacements)} rows from identical FX source')
