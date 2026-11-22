'use strict';
// Issue 1517: the stage 5 detail check gates every faction; the offer sheet and publish refuse a build without its PASS.
// The standing runner discovers this wrapper automatically.
const path = require('path');
const { spawnSync } = require('child_process');
const ROOT = process.env.VS_ROOT || path.resolve(__dirname, '../../..');
const script = path.join(ROOT, 'tools/recipe/test/detail_check_selftest.py');
const candidates = process.env.PYTHON
  ? [[process.env.PYTHON, []]]
  : (process.platform === 'win32' ? [['python', []], ['py', ['-3']], ['python3', []]] : [['python3', []], ['python', []]]);
for (const [py, pre] of candidates) {
  const r = spawnSync(py, [...pre, script], { cwd: ROOT, encoding: 'utf8', windowsHide: true });
  if (r.error && r.error.code === 'ENOENT') continue;
  if (r.status !== 0 && !r.stdout && /not found|not recognized/i.test(r.stderr || '')) continue;
  process.stdout.write((r.stdout || '') + (r.stderr || ''));
  process.exit(r.status === null ? 1 : r.status);
}
console.log('FAIL no Python 3 found for detail_check_selftest.py');
process.exitCode = 1;
