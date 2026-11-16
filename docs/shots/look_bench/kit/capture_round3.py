"""R271: matching short GPU batches, complete kit plus eight shield-hit cases.

python capture_round3.py --out DIR [--only doom,gauss] [--batch-size 8]
Run twice per version, retaining the second run. Logs and generated drivers
stay in TEMP; only raw evidence and source hashes go to the supplied directory.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
from capture_kit import REPO, rows


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--only')
    p.add_argument('--project', type=Path, default=REPO / 'godot')
    p.add_argument('--batch-size', type=int, default=8)
    a = p.parse_args()
    ids = [r['id'] for r in rows()] + [f'shield_{w}_{f}' for f in
        ['voidsworn', 'hegemony', 'ithar', 'corsair'] for w in ['torp', 'doom']]
    if a.only:
        selected = a.only.split(',')
        assert set(selected) <= set(ids)
        ids = selected
    a.out.mkdir(parents=True, exist_ok=True)
    aggregate, hashes, processes = None, None, []
    for start in range(0, len(ids), a.batch_size):
        child = a.out / f'batch_{start//a.batch_size+1:02d}'
        assert not child.exists(), f'Use a fresh output directory: {child}'
        selection = ids[start:start+a.batch_size]
        print('BATCH', child.name, ','.join(selection), flush=True)
        command = [sys.executable, '-B', str(Path(__file__).with_name('capture_kit.py')),
            '--out', str(child), '--only', ','.join(selection), '--cameras', '170,60', '--round3', '--project', str(a.project)]
        # Every row renders once as warm-up and again as kept evidence.
        subprocess.run(command, check=True)
        process = json.loads((child / 'process.json').read_text())
        assert process['exit'] == 0 and not process['stopped_after_completion'], process
        processes.append(dict(folder=child.name, **process))
        report = json.loads((child / 'bench.json').read_text())
        assert not report['warnings'] and len(report['stills']) == len(selection)*2
        current = json.loads((child / 'source_hashes.json').read_text())
        if hashes is None:
            hashes = current
            aggregate = dict(report, stills=[], parts={})
            shutil.copy2(child / 'moments.json', a.out / 'moments.json')
        assert current == hashes, 'FX source changed during capture'
        for record in report['stills']:
            for field in ['file', 'native_file', 'phone_file']:
                if field in record:
                    assert (child / record[field]).is_file()
                    record[field] = f'{child.name}/{record[field]}'
            record['capture_batch'] = child.name
            aggregate['stills'].append(record)
        aggregate['parts'][child.name] = dict(ids=selection, process=f'{child.name}/process.json')
        (a.out / 'bench.json').write_text(json.dumps(aggregate, indent=1))
        (a.out / 'source_hashes.json').write_text(json.dumps(hashes, indent=1))
    for name, expected in hashes.items():
        assert hashlib.sha256((a.project / name.replace('\\', '/')).read_bytes()).hexdigest() == expected
    (a.out / 'process.json').write_text(json.dumps(dict(exit=0, children=processes), indent=1))
    print('ROUND3_CAPTURE_DONE', len(aggregate['stills']), 'stills', flush=True)


if __name__ == '__main__':
    main()
