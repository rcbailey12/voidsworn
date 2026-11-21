"""Issue 1535 PC proof probe. Run under a job's voidsworn-run TEMP with tools/pc/pysite on PYTHONPATH.

It makes one folder through tempfile.mkdtemp (left in the job TEMP for scratch_done.ps1 to remove) and reports whether
its access list is protected (not inherited). As a control it makes one folder with the standard library's own mkdtemp,
reports the same, and removes it again in this same process. PASS needs the site module loaded and the probe folder
inheriting its access.
"""
import json
import os
import subprocess
import sys
import tempfile


def protected(path):
    cmd = "(Get-Acl -LiteralPath $env:PROBE_PATH).AreAccessRulesProtected"
    r = subprocess.run(['powershell', '-NoProfile', '-Command', cmd], capture_output=True, text=True,
                       env={**os.environ, 'PROBE_PATH': path})
    return (r.stdout.strip() or ('error: ' + r.stderr.strip()))


loaded = bool(getattr(tempfile, '_voidsworn_inherited_acl', False))
probe = tempfile.mkdtemp(prefix='probe1535-')
with open(os.path.join(probe, 'file.txt'), 'w') as f:
    f.write('issue 1535 probe\n')
result = {'python': sys.version.split()[0], 'site_loaded': loaded, 'temp': tempfile.gettempdir(), 'probe': probe,
          'probe_protected': protected(probe)}
stock = getattr(tempfile, '_voidsworn_stock_mkdtemp', None)
if stock:
    control = stock(prefix='control1535-')
    result['control_protected'] = protected(control)
    os.rmdir(control)
    result['control_removed_by_its_maker'] = not os.path.exists(control)
print(json.dumps(result, indent=1))
ok = loaded and result['probe_protected'] == 'False'
print(('PASS' if ok else 'FAILED') + ' probe 1535: mkdtemp under the job TEMP ' +
      ('inherits its access' if ok else 'did not inherit its access (or the site module did not load)'))
sys.exit(0 if ok else 1)
