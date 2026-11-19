'use strict';
// Automatically registered by run_all_checks.js. PC-installed files are measured via --installed.
const { spawnSync } = require('child_process');
const path = require('path');

const lint = path.resolve(__dirname, '../../../tools/blender/kits/shared/paint_lint.py');
for (const python of process.env.PYTHON ? [process.env.PYTHON] : ['python', 'python3']) {
  const result = spawnSync(python, [lint, '--self-test'], { encoding: 'utf8', windowsHide: true });
  if (result.error?.code === 'ENOENT') continue;
  process.stdout.write((result.stdout || '') + (result.stderr || ''));
  process.exit(result.status ?? 1);
}
console.log('FAIL paint_lint: Python with Pillow is required');
process.exitCode = 1;
