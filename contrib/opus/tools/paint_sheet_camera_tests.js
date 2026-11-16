'use strict';
// Issue 844: exercise paint_sheet.py's real camera functions without Blender or a GPU.
// The standing runner discovers this wrapper automatically.
const path = require('path');
const { spawnSync } = require('child_process');
const ROOT = process.env.VS_ROOT || path.resolve(__dirname, '../../..');
const script = path.join(ROOT, 'contrib/opus/tools/paint_sheet_camera_selftest.py');
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
console.log('FAIL no Python 3 found for paint_sheet_camera_selftest.py');
process.exitCode = 1;
