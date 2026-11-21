'use strict';
// Issue 1535: job tools make temporary folders the normal cleanup can delete. Python 3.12.4+ on Windows gives a
// tempfile.mkdtemp folder a private ACL (an elevated owner made 31 voidsworn-run folders undeletable, cleanup 4, Nov 21).
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '../../..');
const site = path.join(root, 'tools', 'pc', 'pysite');
const read = rel => fs.readFileSync(path.join(root, rel), 'utf8').replace(/\r\n/g, '\n');

// 1. Both job bats put the site folder on PYTHONPATH while the tools run under the job TEMP, and restore it after.
for (const rel of ['tools/pc/jobs/ship_job.bat', 'tools/pc/jobs/look_bench.bat']) {
  const bat = read(rel);
  const tempSet = bat.indexOf('set "TMPDIR=%TEMP%"');
  const run = bat.indexOf('call :run_tools 9>');
  const site = bat.indexOf('set "PYTHONPATH=', tempSet);
  const restore = bat.indexOf('set "PYTHONPATH=%BASE_PYTHONPATH%"');
  assert(tempSet > 0 && site > tempSet && site < run && restore > run, rel + ': PYTHONPATH gets pysite between the TEMP switch and the tools, and is restored after');
  assert(/pysite/.test(bat.slice(tempSet, run)), rel + ': names the pysite folder');
  assert(!/PYTHONPATH=[^"\n]*;"/.test(bat), rel + ': never leaves an empty PYTHONPATH entry');
}
// 2. The selftest makes and removes its own folder, never through mkdtemp.
const self = read('contrib/opus/tools/picture_provenance_selftest.py');
assert(!/tempfile\.mkdtemp\(/.test(self), 'picture_provenance_selftest.py no longer uses tempfile.mkdtemp');
assert(/def run\(\):[\s\S]*checks\(folder\)[\s\S]*except BaseException:[\s\S]*kept for diagnosis[\s\S]*raise[\s\S]*remove_folder\(folder\)/.test(self), 'the selftest removes its folder only after its checks pass');
// 3. The site module: mkdtemp makes a plain folder (no 0o700 mode), TemporaryDirectory still cleans up.
let python = null;
for (const py of process.env.PYTHON ? [process.env.PYTHON] : ['python3', 'python']) {
  const r = spawnSync(py, ['-c', 'import sys; print(sys.version_info[0])'], { encoding: 'utf8' });
  if (!r.error && r.status === 0 && r.stdout.trim() === '3') { python = py; break; }
}
if (!python) {
  console.log('SKIP pysite run: no Python 3 here');
} else {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'pysite1535-'));
  const probe = [
    'import os, stat, tempfile, json',
    'assert getattr(tempfile, "_voidsworn_inherited_acl", False), "sitecustomize not loaded"',
    'a = tempfile.mkdtemp(prefix="p-", suffix="-s")',
    'b = tempfile.mkdtemp(dir=os.environ["TMPDIR"])',
    'with tempfile.TemporaryDirectory(prefix="t-") as t: inside = os.path.isdir(t)',
    'print(json.dumps({"a": a, "b": b, "modeA": stat.S_IMODE(os.stat(a).st_mode), "t": t, "inside": inside, "gone": not os.path.exists(t)}))'
  ].join('\n');
  const env = { ...process.env, VOIDSWORN_PYSITE_TEST: '1', PYTHONPATH: site, TMPDIR: tmp, TEMP: tmp, TMP: tmp };
  const r = spawnSync('sh', ['-c', `umask 022; exec "$0" -c "$1"`, python, probe], { env, encoding: 'utf8' });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  const got = JSON.parse(r.stdout.trim().split('\n').pop());
  assert(path.basename(got.a).startsWith('p-') && got.a.endsWith('-s') && [tmp, fs.realpathSync(tmp)].includes(path.dirname(got.a)), 'names and folder as the standard library: ' + r.stdout);
  assert.equal(got.modeA, 0o755, 'a plain mkdir (inherits), not the private 0o700 folder');
  assert(got.inside && got.gone, 'TemporaryDirectory still makes and removes its folder');
  // without the site folder the standard library still makes 0o700 folders: the difference is the module
  const plain = spawnSync('sh', ['-c', 'umask 022; exec "$0" -c "$1"', python, 'import os, stat, tempfile; a = tempfile.mkdtemp(); print(stat.S_IMODE(os.stat(a).st_mode))'], { env: { ...env, PYTHONPATH: '' }, encoding: 'utf8' });
  assert.equal(plain.stdout.trim(), String(0o700), plain.stdout + plain.stderr);
  fs.rmSync(tmp, { recursive: true, force: true });
}
console.log('PASS pysite 1535: job bats load it, mkdtemp makes inheritable folders, the picture selftest cleans up after a PASS');
