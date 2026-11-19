'use strict';
// Issue 946: --fast runs the rows that are actually fast.
// Proves the selection contract of run_all_checks.js:
//   - row names are unique and there is exactly one gate row (nem_assign_enum);
//   - fastSelected() returns exactly the rows marked fast plus the gate, even with no fast mark on the gate;
//   - representative rows land on the expected side, including the two slow Windows matrices;
//   - the CLI agrees: --fast --only on an unmarked row prints "SKIP: fast", and
//     --fast --only on the gate row runs it instead of skipping it.
// A plain run still runs every row; that is proven by the delivery run of the
// suite itself, not inside this test (a nested full run would take minutes).
const path = require('path');
const { spawnSync } = require('child_process');
const { buildChecks, fastSelected, ROOT } = require('./run_all_checks.js');

const failures = [];
function check(label, ok) {
  console.log((ok ? 'ok   ' : 'BAD  ') + label);
  if (!ok) failures.push(label);
}

const checks = buildChecks();
const names = checks.map(c => c.name);
check('row names are unique', new Set(names).size === names.length);

const gates = checks.filter(c => c.gate);
check('exactly one gate row', gates.length === 1);
check('the gate row is nem_assign_enum', gates.length === 1 && gates[0].name === 'nem_assign_enum');

const selected = new Set(fastSelected(checks).map(c => c.name));
const expected = new Set(checks.filter(c => c.fast || c.gate).map(c => c.name));
check('fastSelected returns exactly the marked rows plus the gate',
  selected.size === expected.size && [...expected].every(n => selected.has(n)));
const unmarkedGates = gates.map(c => ({ ...c, fast: false }));
check('gate rows are selected without a fast mark', fastSelected(unmarkedGates).length === gates.length);

const mustRun = ['b1_tests', 'gpu_slots_tests',
  'nem_assign_enum', 'checks', 'findings_tests', 'oracle_drift_guard', 'fixture_check',
  'tree_last_rows_test', 'fast_selection_test'];
for (const n of mustRun) check('selected under --fast: ' + n, selected.has(n));

const mustSkip = ['r1_tests', 'tree_effects_test', 'naming_lint_game', 'softlock_sweep',
  'picture_provenance_tests', 'runner_job_tests', 'runner_selftest', 'stage5_fail_selftest'];
for (const n of mustSkip) check('skipped under --fast: ' + n, names.includes(n) && !selected.has(n));

function cliProbe(only) {
  const r = spawnSync(process.execPath, [path.join(__dirname, 'run_all_checks.js'), '--fast', '--only', only],
    { cwd: ROOT, encoding: 'utf8', timeout: 120000 });
  return { status: r.status, output: (r.stdout || '') + (r.stderr || '') };
}
const slowProbe = cliProbe('r1_tests');
check('CLI: --fast --only r1_tests prints SKIP: fast', slowProbe.status === 0 && slowProbe.output.includes('SKIP: fast'));
const gateProbe = cliProbe('nem_assign_enum');
check('CLI: --fast --only nem_assign_enum passes the gate',
  gateProbe.status === 0 && gateProbe.output.includes('PASS: all issue 120 enumeration checks'));

if (failures.length) {
  console.log('FAIL: fast selection broken: ' + failures.join('; '));
  process.exit(1);
}
console.log('PASS: --fast selects ' + selected.size + ' of ' + checks.length + ' rows using fast marks and gates');
