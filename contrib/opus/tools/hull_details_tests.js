'use strict';
// The standing runner discovers this Blender-free fixture wrapper automatically.
const path = require('path');
const { spawnSync } = require('child_process');
const script = path.resolve(__dirname, '../../../tools/recipe/test/hull_details_selftest.py');
const candidates = process.env.PYTHON
  ? [[process.env.PYTHON, []]]
  : (process.platform === 'win32' ? [['python', []], ['py', ['-3']], ['python3', []]] : [['python3', []], ['python', []]]);
for (const [python, args] of candidates) {
  const result = spawnSync(python, [...args, '-B', script], { stdio: 'inherit', windowsHide: true });
  if (result.error?.code === 'ENOENT') continue;
  if (result.error) console.error(result.error.message);
  process.exit(result.status ?? 1);
}
console.error('FAIL no Python 3 found for hull_details_selftest.py');
process.exitCode = 1;
