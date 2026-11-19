"""Exercise stage 5's actual bake/compile guard with stub Blender output."""
import json
import os
from pathlib import Path
import subprocess
import sys

repo, output = map(Path, sys.argv[1:])
output.mkdir(parents=True, exist_ok=True)
source = (repo / 'tools/recipe/5_paint_bake.bat').read_text()
prefix = source.split('rem issue 601: every surface seen from outside')[0]
(output / 'stage.bat').write_text(prefix + '\necho PASS guard\nexit /b 0\n:bad\nexit /b 1\n')
(output / 'reference.glb').write_bytes(b'fixture only')
variables = dict(REPO=output, JOB=output, B0=output / 'reference.glb', BAKE='probe.py',
                 CELL='A20', B='stub_blender', R='unused', RECIPE_NOPAUSE='1')
(output / 'env.bat').write_text('@echo off\n' + '\n'.join(f'set "{key}={value}"' for key, value in variables.items()) + '\n')
tmo = output / 'tools/pc/tmo.bat'
tmo.parent.mkdir(parents=True, exist_ok=True)
tmo.write_text('@echo off\necho [209] A20 {\nif not "%TEST_MESSAGE%"=="" echo %TEST_MESSAGE%\nexit /b %TEST_EXIT%\n')
rows = []
for message, blender_exit in [(message, 0) for message in ('out of SVM stack space', 'failed to compile',
                            'shader compilation failed', 'shader compilation error', 'shader compile error', 'error compiling')] + [('', 2), ('', -1), ('', 0)]:
    environment = dict(os.environ, TEST_MESSAGE=message, TEST_EXIT=str(blender_exit))
    result = subprocess.run(['cmd.exe', '/d', '/c', str(output / 'stage.bat')], env=environment, capture_output=True, text=True)
    expected = 1 if message or blender_exit else 0
    row = dict(message=message, blender_exit=blender_exit, expected=expected, stage_exit=result.returncode)
    assert result.returncode == expected, (row, result.stdout, result.stderr)
    rows.append(row)
(output / 'guard_diagnostic.json').write_text(json.dumps(dict(ok=True, cases=rows), indent=2))
print('PASS stage 5 guard:', len(rows), 'cases')
