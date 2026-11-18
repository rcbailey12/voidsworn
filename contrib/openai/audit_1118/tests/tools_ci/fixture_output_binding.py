"""The fixture freshness check should reject an unchanged record with a broken fixture."""
import contextlib
import gzip
import io
from pathlib import Path
import runpy
import sys
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[5]
CHECK = ROOT / 'tools/recipe/sheet_fixture_hash.py'
FIXTURE = ROOT / 'godot/fx/test/fixtures/C19_51_unbaked.glb.gz'
BROKEN = gzip.compress(b'not an exported GLB')


def check_with_replacement(replace):
    real_open = open

    def read_file(path, *args, **kwargs):
        if replace and Path(path).resolve() == FIXTURE:
            return io.BytesIO(BROKEN)
        return real_open(path, *args, **kwargs)

    output = io.StringIO()
    with patch.object(sys, 'argv', [str(CHECK), '--check']), patch('builtins.open', read_file), \
         patch('io.open', read_file), contextlib.redirect_stdout(output):
        try:
            runpy.run_path(str(CHECK), run_name='__main__')
        except SystemExit as result:
            return result.code, output.getvalue().strip()
    raise AssertionError('fixture check did not report a result')


baseline, output = check_with_replacement(False)
if baseline:
    sys.exit('SETUP ERROR: expected a current A16 fixture record; got ' + output)
code, output = check_with_replacement(True)
if code == 0:
    sys.exit('FAIL: the fixture freshness check accepted replacement bytes: ' + output)
print('PASS: the fixture freshness check rejected replacement bytes:', output)
