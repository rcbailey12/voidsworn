'use strict';

const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const comparator = path.resolve(__dirname, '../../../godot/rules/sim/compare_trials.js');
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'compare-trials-'));
const controlPath = path.join(dir, 'control.log');
const treatmentPath = path.join(dir, 'treatment.log');

function trial(arm, seed) {
  return 'TRIAL ' + JSON.stringify({
    faction: 'deathless', difficulty: 'veteran', arm, seed,
    cell: { mode: 'campaign', sector: 1, kind: 'battle', column: 1 },
    terminal_reason: 'completed_win', rounds: 4, hull: 0.75, lost: 0, abilities_fired: { phase: 1 },
  });
}

const controlRows = [trial('control', 1706), trial('control', 1707)];
const treatmentRows = [trial('treatment', 1706), trial('treatment', 1707)];
const done = 'TRIALS_COMPLETE 2';

function run(control, treatment) {
  fs.writeFileSync(controlPath, control.join('\n') + '\n');
  fs.writeFileSync(treatmentPath, treatment.join('\n') + '\n');
  const result = spawnSync(process.execPath, [comparator, controlPath, treatmentPath], { encoding: 'utf8' });
  if (result.error) throw result.error;
  return result;
}

function rejects(control, treatment, error) {
  const result = run(control, treatment);
  assert.equal(result.status, 1, `expected rejection (${error}), got ${result.stdout || result.stderr}`);
  assert.match(result.stderr, error);
  assert.equal(result.stdout, '');
}

try {
  rejects([controlRows[0]], [treatmentRows[0]], /missing TRIALS_COMPLETE/);
  rejects([...controlRows, done], treatmentRows, /treatment\.log.*missing TRIALS_COMPLETE/);
  rejects([controlRows[0], done], [treatmentRows[0], done], /expected 2 TRIAL records, found 1/);
  rejects([...controlRows, 'TRIALS_COMPLETE 1'], [...treatmentRows, done], /expected 1 TRIAL records, found 2/);
  rejects([...controlRows, 'TRIALS_COMPLETE 0'], [...treatmentRows, done], /invalid TRIALS_COMPLETE/);
  rejects([...controlRows, done, done], [...treatmentRows, done], /duplicate TRIALS_COMPLETE/);
  rejects([controlRows[0], done, controlRows[1]], [...treatmentRows, done], /TRIAL after TRIALS_COMPLETE/);
  const complete = run([...controlRows, done], [...treatmentRows, done]);
  assert.equal(complete.status, 0, complete.stderr);
  assert.match(complete.stdout, /^PAIRED /);
  assert.equal(JSON.parse(complete.stdout.slice('PAIRED '.length)).pairs, 2);
  console.log('PASS: paired trials require a completion marker and the planned count in both logs');
} finally {
  for (const file of [controlPath, treatmentPath]) {
    if (fs.existsSync(file)) fs.unlinkSync(file);
  }
  fs.rmdirSync(dir);
}
