'use strict';
// Issue 676 (FINDINGS R241): the weapon-match check. The check is plain Python (tools/blender/build_sheets/weapon_match.py);
// this wrapper runs its pure self-test (no Blender) and lets the runner show it as a normal row. The check on the real built
// ships runs inside Blender in build.py (every building mode, and its own mode "match").
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = process.env.VS_ROOT || path.resolve(__dirname, '../../..');
const script = path.join(ROOT, 'tools', 'blender', 'build_sheets', 'weapon_match_selftest.py');
const candidates = process.env.PYTHON
  ? [[process.env.PYTHON, []]]
  : (process.platform === 'win32' ? [['python', []], ['py', ['-3']], ['python3', []]] : [['python3', []], ['python', []]]);

let last = null;
for (const [py, pre] of candidates) {
  const r = spawnSync(py, [...pre, script], { cwd: ROOT, encoding: 'utf8', windowsHide: true });
  if (r.error && r.error.code === 'ENOENT') { last = r; continue; }
  const out = (r.stdout || '') + (r.stderr || '');
  if (r.status !== 0 && !/^(PASS|FAIL)\b/m.test(r.stdout || '')) { last = r; continue; }  // a Windows Store alias, not the test
  process.stdout.write(out);
  process.exitCode = r.status === null ? 1 : r.status;
  process.exit();
}
console.log('FAIL no Python 3 found for tools/blender/build_sheets/weapon_match_selftest.py: ' + (last && last.error ? last.error.message : 'not found'));
process.exitCode = 1;
