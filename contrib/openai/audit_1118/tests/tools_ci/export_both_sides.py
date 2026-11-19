"""A ship with two port points and no starboard point must fail stage 7."""
import copy
import gzip
import io
import json
from pathlib import Path
import struct
import sys
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / 'tools/recipe'))
import check_export as checker

SHIP = ROOT / 'tools/recipe/ships/corsair_A16.json'
FIXTURE = ROOT / 'godot/fx/test/fixtures/C19_51_unbaked.glb.gz'
raw = gzip.decompress(FIXTURE.read_bytes())
size = struct.unpack_from('<I', raw, 12)[0]
original = json.loads(raw[20:20 + size])
blob = raw[28 + size:]


def problems(doc):
    counts = {}
    for node in doc['nodes']:
        if node.get('name', '').startswith('hp_'):
            kind = node['extras']['kind']
            counts[kind] = counts.get(kind, 0) + 1
    entry = dict(hardpoints=counts, breaches=counts['breach'], cls='Battle-barge')
    real_open = open

    def open_file(path, *args, **kwargs):
        if str(path) == 'manifest_entry.json':
            return io.StringIO(json.dumps(entry))
        return real_open(path, *args, **kwargs)

    real_exists = checker.os.path.exists
    with patch.object(sys, 'argv', ['check_export.py', str(SHIP), '', 'unbaked=1']), \
         patch.object(checker, 'read_glb', return_value=(doc, blob)), \
         patch.object(checker, 'finish', side_effect=lambda out, code, issues, notes, info: issues), \
         patch.object(checker.os.path, 'exists', side_effect=lambda p: p == 'manifest_entry.json' or real_exists(p)), \
         patch.object(checker, 'open', new=open_file, create=True):
        return checker.main()


baseline = problems(original)
if baseline:
    sys.exit('SETUP ERROR: A16 baseline must pass: ' + '; '.join(baseline))
missed = []
for kind in ('rcs', 'board'):
    broken = copy.deepcopy(original)
    points = [n for n in broken['nodes'] if n.get('name', '').startswith('hp_' + kind + '_')]
    port = next(n for n in points if n['extras']['side'] == 'P')
    starboard = next(n for n in points if n['extras']['side'] == 'S')
    name = starboard['name']
    starboard.clear()
    starboard.update(copy.deepcopy(port) | {'name': name})
    if not problems(broken):
        missed.append(kind)

if missed:
    sys.exit('FAIL: stage 7 accepted two port and zero starboard points: ' + ', '.join(missed))
print('PASS: stage 7 rejected both missing starboard origins')
