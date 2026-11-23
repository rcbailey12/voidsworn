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
const { build } = require('./fleet_list');
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'lean1739-'));
const write = (name, contents) => {
  const file = path.join(dir, name);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, contents);
};
const git = (...args) => {
  const r = spawnSync('git', ['-C', dir, ...args], { encoding: 'utf8', windowsHide: true });
  assert.equal(r.status, 0, 'git ' + args.join(' ') + ': ' + r.stderr);
  return r.stdout;
};
try {
  git('init', '-q');
  const trackedConcept = 'docs/ship_pipeline/build_sheets/x/concept_beauty.jpg';
  const missingConcept = 'docs/ship_pipeline/build_sheets/x/gone.jpg';
  write(trackedConcept, 'picture');
  write('kept.txt', 'code');
  write('docs/ship_pipeline/fleet.json', JSON.stringify({
    slots: { 'ithar|Cruiser': { ship: 'Fixture cruiser', concept: trackedConcept, job: 1 } },
    other: [{ key: 'ithar|fighter', ship: 'Fixture fighter', concept: missingConcept, job: 2 }]
  }));
  write('godot/render/hull_table.gd', 'const AI_HULLS := {\n  "ithar|Cruiser": "fixture_cruiser"\n}\n');
  write('godot/assets/ships/manifest.json', JSON.stringify({ ships: { fixture_cruiser: {} } }));
  git('add', '.');
  git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '-m', 'fixture');
  // The runner's own profile shape: '/*' then the left-out folder, non-cone.
  git('config', 'core.sparseCheckout', 'true');
  git('config', 'core.sparseCheckoutCone', 'false');
  fs.writeFileSync(path.join(dir, '.git/info/sparse-checkout'), '/*\n!/docs/ship_pipeline/build_sheets/\n');
  git('read-tree', '-mu', 'HEAD');
  const concept = path.join(dir, trackedConcept);
  assert.ok(!fs.existsSync(concept), 'the fixture leaves the concept picture out of the work tree');
  const inputs = require(path.join(tools, 'sparse_check_inputs'))(dir);
  assert.equal(inputs.exists(concept), true, 'a left-out tracked file counts as present');
  assert.equal(inputs.read(concept), 'picture', 'and reads from the index');
  assert.equal(inputs.exists(path.join(dir, missingConcept)), false, 'a truly missing file is still missing');
  assert.equal(inputs.exists(path.join(dir, '..', 'outside', 'README.md')), false, 'a path outside the checkout is missing, not an error');
  assert.equal(inputs.exists(path.join(dir, 'kept.txt')), true);

  const fleet = build(dir);
  assert.equal(fleet.rows[0].concept, trackedConcept);
  assert.equal(fleet.other[0].concept, missingConcept);
  assert.deepStrictEqual(fleet.problems, ['other[0] (Fixture fighter): concept file is missing: ' + missingConcept]);
} finally {
  fs.rmSync(dir, { recursive: true, force: true });
}
console.log('PASS lean_checkout_1739_tests: the fleet list accepts a tracked concept omitted by sparse checkout and reports a missing concept');
