'use strict';
// Issue 1739: a Codex lane checks out a lean tree (runner_common.ps1 leaves out docs/shots, the build sheets,
// contrib/muse/design, hulls_hi and rocks_hi), and every lane run ended "unverified" because two checks read that tree
// as if it were full: fleet_list_tests called each left-out concept picture missing, and doc_check_tests crashed when
// sparse_check_inputs handed git a path outside the checkout. This row builds a tiny lean checkout and proves the shared
// helper answers from the git index, refuses nothing outside the repo, and still reports a file that is truly missing.
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const tools = __dirname;
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'lean1739-'));
const git = (...args) => {
  const r = spawnSync('git', ['-C', dir, ...args], { encoding: 'utf8', windowsHide: true });
  assert.equal(r.status, 0, 'git ' + args.join(' ') + ': ' + r.stderr);
  return r.stdout;
};
try {
  git('init', '-q');
  fs.mkdirSync(path.join(dir, 'docs/ship_pipeline/build_sheets/x'), { recursive: true });
  fs.writeFileSync(path.join(dir, 'docs/ship_pipeline/build_sheets/x/concept_beauty.jpg'), 'picture');
  fs.writeFileSync(path.join(dir, 'kept.txt'), 'code');
  git('add', '.');
  git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '-m', 'fixture');
  // The runner's own profile shape: '/*' then the left-out folder, non-cone.
  git('config', 'core.sparseCheckout', 'true');
  git('config', 'core.sparseCheckoutCone', 'false');
  fs.writeFileSync(path.join(dir, '.git/info/sparse-checkout'), '/*\n!/docs/ship_pipeline/build_sheets/\n');
  git('read-tree', '-mu', 'HEAD');
  const concept = path.join(dir, 'docs/ship_pipeline/build_sheets/x/concept_beauty.jpg');
  assert.ok(!fs.existsSync(concept), 'the fixture leaves the concept picture out of the work tree');
  const inputs = require(path.join(tools, 'sparse_check_inputs'))(dir);
  assert.equal(inputs.exists(concept), true, 'a left-out tracked file counts as present');
  assert.equal(inputs.read(concept), 'picture', 'and reads from the index');
  assert.equal(inputs.exists(path.join(dir, 'docs/ship_pipeline/build_sheets/x/gone.jpg')), false, 'a truly missing file is still missing');
  assert.equal(inputs.exists(path.join(dir, '..', 'outside', 'README.md')), false, 'a path outside the checkout is missing, not an error');
  assert.equal(inputs.exists(path.join(dir, 'kept.txt')), true);
} finally {
  fs.rmSync(dir, { recursive: true, force: true });
}
// Both concept checks in the fleet list go through the helper, so a lean lane sees the pictures it left out.
const fleet = fs.readFileSync(path.join(tools, 'fleet_list.js'), 'utf8');
assert.doesNotMatch(fleet, /fs\.existsSync\(path\.join\(root, (?:row|r)\.concept\)\)/, 'fleet_list checks concepts through sparse_check_inputs');
assert.equal((fleet.match(/inputs\.exists\(path\.join\(root, (?:row|r)\.concept\)\)/g) || []).length, 2, 'both concept checks use the helper');
console.log('PASS lean_checkout_1739_tests: a lean lane checkout reads left-out files from the index, a path outside it is simply missing, and the fleet list uses the helper');
