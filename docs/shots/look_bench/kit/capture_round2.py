"""Run matching short bench batches, avoiding the long-run Jolt job stall.

python capture_round2.py --out DIR [--batch-size 10]
Every row warms its materials; the first batch also pays a full row prepass.
Child records and logs are retained; the aggregate comes only from them.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import time
from capture_kit import rows, REPO


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--batch-size', type=int, default=10)
    a = p.parse_args()
    assert 1 <= a.batch_size <= 10
    a.out.mkdir(parents=True, exist_ok=True)
    ids = [r['id'] for r in rows()]
    aggregate, hashes, processes = None, None, []
    for start in range(0, len(ids), a.batch_size):
        child = a.out / f'batch_{start//a.batch_size+1:02d}'
        selection = ids[start:start+a.batch_size]
        print('BATCH', child.name, ','.join(selection), flush=True)
        command = [sys.executable, '-B', str(Path(__file__).with_name('capture_kit.py')),
                   '--out', str(child), '--only', ','.join(selection), '--cameras', '170,60']
        # The first batch pays the full row warm-up. Later batches reuse the
        # disk pipelines and still call the bench's material warm-up per row.
        # Both versions follow this exact sequence; changed weapons also get
        # a separate preview before the kept after run.
        if start:
            command.append('--skip-row-warm')
        completed = child / 'process.json'
        reuse = completed.exists() and json.loads(completed.read_text())['exit'] == 0
        if not reuse:
            if child.exists():
                archive = child.with_name(child.name + f'_interrupted_{time.time_ns()}')
                assert child.resolve().is_relative_to(a.out.resolve())
                assert archive.resolve().is_relative_to(a.out.resolve()) and not archive.exists()
                shutil.move(str(child), str(archive))
            result = subprocess.run(command)
            if result.returncode:
                raise SystemExit(result.returncode)
        process = json.loads((child / 'process.json').read_text())
        assert process['exit'] == 0 and not process['stopped_after_completion'], process
        processes.append(dict(folder=child.name, **process))
        report = json.loads((child / 'bench.json').read_text())
        assert not report['warnings'] and len(report['stills']) == len(selection)*2
        current = json.loads((child / 'source_hashes.json').read_text())
        if hashes is None:
            hashes = current
            aggregate = report
            aggregate['stills'] = []
            aggregate['parts'] = {}
            shutil.copy2(child / 'moments.json', a.out / 'moments.json')
        assert current == hashes
        # Re-read because aggregate and report refer to the same first dict.
        report = json.loads((child / 'bench.json').read_text())
        for record in report['stills']:
            for field in ['file', 'native_file', 'phone_file']:
                if field not in record:
                    continue
                assert (child / record[field]).is_file()
                record[field] = f'{child.name}/{record[field]}'
            record['capture_batch'] = child.name
            aggregate['stills'].append(record)
        aggregate['parts'][child.name] = dict(ids=selection, report=f'{child.name}/bench.json',
                                            process=f'{child.name}/process.json')
        (a.out / 'bench.json').write_text(json.dumps(aggregate, indent=1))
        (a.out / 'source_hashes.json').write_text(json.dumps(hashes, indent=1))
    assert len(aggregate['stills']) == len(ids)*2
    # Guard against source edits during the series, in addition to child hashes.
    for name, expected in hashes.items():
        assert hashlib.sha256((REPO / 'godot' / name.replace('\\', '/')).read_bytes()).hexdigest() == expected
    (a.out / 'process.json').write_text(json.dumps(dict(exit=0, stopped_after_completion=False,
        batched=True, children=processes), indent=1))
    print('ROUND2_CAPTURE_DONE', len(aggregate['stills']), 'stills', flush=True)


if __name__ == '__main__':
    main()
