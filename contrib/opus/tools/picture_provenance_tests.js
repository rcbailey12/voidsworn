'use strict';
// Issue 889: automatically discovered by run_all_checks.js.
const { spawnSync } = require('child_process');
const path = require('path');
const root = path.resolve(__dirname, '../../..');
for (const py of process.env.PYTHON ? [process.env.PYTHON] : ['python', 'python3']) {
  const result = spawnSync(py, [path.join(__dirname, 'picture_provenance_selftest.py')], {
    cwd: root, encoding: 'utf8', windowsHide: true, env: { ...process.env, PYTHONDONTWRITEBYTECODE: '1' }
  });
  if (result.error && result.error.code === 'ENOENT') continue;
  process.stdout.write((result.stdout || '') + (result.stderr || ''));
  process.exit(result.status === null ? 1 : result.status);
}
console.log('FAIL Python with Pillow is required for picture provenance checks');
process.exitCode = 1;
