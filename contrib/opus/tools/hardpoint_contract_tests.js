'use strict';
// Issue 363: the hard point contract. The table and the standing gate are plain Python, so this wrapper runs the pure test
// from tools/recipe (no numpy, no Blender) and lets the runner show it as a normal row. The glb half of the contract
// (tools/recipe/contract_selftest.py) and the real export check (check_export_selftest.py) run on the PC inside stage 7.
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = process.env.VS_ROOT || path.resolve(__dirname, '../../..');
const script = path.join(ROOT, 'tools', 'recipe', 'contract_tables_selftest.py');
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
console.log('FAIL no Python 3 found for tools/recipe/contract_tables_selftest.py: ' + (last && last.error ? last.error.message : 'not found'));
process.exit(1);
