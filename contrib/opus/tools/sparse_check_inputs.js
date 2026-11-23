'use strict';
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

// Only inputs marked skip-worktree can fall back to the index. A working-tree
// edit or an ordinary missing file must still be visible to the checks.
module.exports = function checkInputs(root) {
  function git(...args) {
    return spawnSync('git', args, { cwd: root, encoding: 'utf8', windowsHide: true, maxBuffer: 8 * 1024 * 1024 });
  }
  const relative = file => path.relative(root, file).split(path.sep).join('/');
  const sparse = git('config', '--bool', 'core.sparseCheckout').stdout?.trim() === 'true';
  function skipped(file) {
    if (!sparse) return [];
    // A path outside the checkout (doc_check probes godot/<token>, and a token can start with ..)
    // has no index entry; git would refuse it with 'outside repository'.
    const rel = relative(file);
    if (rel === '..' || rel.startsWith('../') || path.isAbsolute(rel)) return [];
    const result = git('--literal-pathspecs', 'ls-files', '-t', '-z', '--', relative(file) || '.');
    if (result.status !== 0) throw new Error(result.stderr || result.error);
    return result.stdout.split('\0').filter(line => line.startsWith('S ')).map(line => line.slice(2));
  }
  function exists(file) {
    return fs.existsSync(file) || skipped(file).length > 0;
  }
  function read(file) {
    if (fs.existsSync(file) || !skipped(file).includes(relative(file))) return fs.readFileSync(file, 'utf8');
    const result = git('show', ':' + relative(file));
    if (result.status !== 0) throw new Error(result.stderr || result.error);
    return result.stdout;
  }
  return { skipped, exists, read };
};
