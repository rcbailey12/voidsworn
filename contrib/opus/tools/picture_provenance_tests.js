'use strict';
// Issue 889: automatically discovered by run_all_checks.js.
const { spawnSync } = require('child_process');
const path = require('path');
const root = path.resolve(__dirname, '../../..');
// Issue 1739: a real Python 3 that has Pillow (never the Windows Store alias)
const py = require('./find_python').findPython(['PIL']);
if (py) {
  const result = spawnSync(py, [path.join(__dirname, 'picture_provenance_selftest.py')], {
    cwd: root, encoding: 'utf8', windowsHide: true, env: { ...process.env, PYTHONDONTWRITEBYTECODE: '1' }
  });
  process.stdout.write((result.stdout || '') + (result.stderr || ''));
  process.exit(result.status === null ? 1 : result.status);
}
console.log('FAIL Python with Pillow is required for picture provenance checks');
process.exitCode = 1;
