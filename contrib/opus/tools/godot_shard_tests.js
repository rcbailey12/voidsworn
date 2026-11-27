'use strict';
// Issue 1430: the headless Godot list runs as parallel shards on GitHub. These checks run the real run_checks.sh in its
// plan-only mode (no Godot needed) and prove every headless check lands in exactly one shard, for the shard count the
// workflow uses and for others, with and without recorded times, and that a bad SHARD value fails.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const ROOT = path.resolve(__dirname, '../../..');
const SCRIPT = path.join(ROOT, 'godot/tools/ci/run_checks.sh');
const LIST = path.join(ROOT, 'godot/tools/ci/godot_checks.txt');
const WORKFLOW = path.join(ROOT, '.github/workflows/checks.yml');
const windows = process.platform === 'win32';
const sh = windows ? path.join(process.env.ProgramFiles, 'Git', 'bin', 'bash.exe') : 'sh';
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'godot-shard-1430-'));

function plan(shard, extra) {
  const env = Object.assign({}, process.env, { SHARD: shard, GODOT_CHECKS_PLAN: '1', RUNNER_TEMP: tmp }, extra || {});
  const r = spawnSync(sh, [SCRIPT], { cwd: ROOT, env, encoding: 'utf8', windowsHide: true, timeout: 60000 });
  return { status: r.status, out: (r.stdout || '') + (r.stderr || '') };
}

const headless = fs.readFileSync(LIST, 'utf8').split(/\r?\n/).filter(l => l.startsWith('headless|'));
const scriptOf = l => l.split('|')[1];
const stepLines = headless.filter(l => l.split('|')[2].startsWith('step:')).map(scriptOf);
assert.ok(headless.length > 50, 'godot_checks.txt has fewer headless lines than expected');

// The workflow's shard count, read from its matrix, so a change there is exercised here.
const wf = fs.readFileSync(WORKFLOW, 'utf8');
const m = /shard: \[([0-9, ]+)\]/.exec(wf);
assert.ok(m, 'checks.yml godot-game has no shard matrix');
const shards = m[1].split(',').map(s => Number(s.trim()));
const wfCount = shards.length;
assert.deepEqual(shards, Array.from({ length: wfCount }, (_, i) => i + 1), 'the matrix must list shards 1 to n');
assert.ok(new RegExp('SHARD: \\$\\{\\{ matrix\\.shard \\}\\}/' + wfCount).test(wf), 'the list step must pass SHARD=<shard>/' + wfCount);

function cover(n, extra) {
  const seen = new Map();
  for (let i = 1; i <= n; i++) {
    const r = plan(i + '/' + n, extra);
    assert.equal(r.status, 0, 'plan for shard ' + i + '/' + n + ' failed:\n' + r.out);
    const rows = r.out.split(/\r?\n/).filter(l => /^[0-9]+\|headless\|/.test(l));
    assert.equal(rows.length, headless.length, 'shard ' + i + '/' + n + ' printed a plan that is not the whole list');
    rows.forEach(l => {
      const [s, , script] = l.split('|');
      const prev = seen.get(script);
      assert.ok(prev === undefined || prev === s, script + ' is planned for shard ' + prev + ' and shard ' + s);
      seen.set(script, s);
    });
  }
  headless.map(scriptOf).forEach(s => {
    assert.ok(seen.has(s), s + ' is in no shard of ' + n);
    const k = Number(seen.get(s));
    assert.ok(k >= 1 && k <= n, s + ' is planned for shard ' + k + ' of ' + n);
  });
  stepLines.forEach(s => assert.equal(seen.get(s), '1', s + ' (run in its own step) must sit in shard 1 so it is reported once'));
  assert.equal(seen.size, headless.length);
  return seen;
}

[1, 2, wfCount, 5].forEach(n => cover(n));
// No recorded times at all (a fresh check, or the file gone): still every check exactly once.
cover(wfCount, { GODOT_CHECKS_TIMES: path.join(tmp, 'missing_times.txt') });

// Balance at the workflow's count by the recorded times: no shard more than 25% over the even share.
plan('1/' + wfCount);
const est = fs.readFileSync(path.join(tmp, 'godot_checks', 'loads.txt'), 'utf8').trim().split(/\r?\n/).map(l => Number(l.split('|')[2]));
const total = est.reduce((a, b) => a + b, 0);
assert.ok(est.length === wfCount && total > 0, 'no load estimate was written');
est.forEach((t, i) => assert.ok(t <= 1.25 * total / wfCount, 'shard ' + (i + 1) + ' is planned for ' + t + ' s of ' + total + ' s'));

// Bad SHARD values fail before anything runs.
['0/3', '4/3', 'x/3', '2', '1/', '/3'].forEach(v => {
  const r = plan(v);
  assert.notEqual(r.status, 0, 'SHARD=' + v + ' must fail');
  assert.match(r.out, /FAIL: SHARD/);
});

// Artoo on PR 1615: a short, doubled or out-of-range plan stops the run before any check, and never reads as PASS.
[['$d', 'a dropped line'], ['1d', 'a dropped first line'], ['1p', 'a doubled line'], ['1s/^[0-9]*|/9|/', 'shard 9 of ' + wfCount],
 ['1,$d', 'an empty plan']].forEach(([edit, what]) => {
  for (let i = 1; i <= wfCount; i++) {
    const r = plan(i + '/' + wfCount, { GODOT_CHECKS_PLAN_EDIT: edit });
    assert.equal(r.status, 1, 'a plan with ' + what + ' must fail shard ' + i + ':\n' + r.out);
    assert.match(r.out, /FAIL: the shard plan is broken/);
    assert.doesNotMatch(r.out, /^PASS/m);
  }
});

// Issue 2174: a Codex sandbox set RUNNER_TEMP to a doubled-backslash USERPROFILE style path and Git's mkdir was denied,
// so plan.txt was never written and the shard skipped its Godot checks. The step now folds the slashes with the Windows
// path APIs, so the plan must still be written under the same temp folder. Windows only: on Linux the path is unchanged.
if (windows) {
  const mangled = tmp.replace(/\\/g, '\\\\').replace(/\\\\/, '/');
  const mr = plan('1/' + wfCount, { RUNNER_TEMP: mangled });
  assert.equal(mr.status, 0, 'a USERPROFILE style RUNNER_TEMP must still plan:\n' + mr.out);
  assert.equal(mr.out.split(/\r?\n/).filter(l => /^[0-9]+\|headless\|/.test(l)).length, headless.length,
    'a USERPROFILE style RUNNER_TEMP printed a plan that is not the whole list');
  assert.ok(fs.existsSync(path.join(tmp, 'godot_checks', 'plan.txt')), 'plan.txt was not written under the normalised temp folder');
}

fs.rmSync(tmp, { recursive: true, force: true });
console.log('PASS godot_shard_tests: ' + headless.length + ' headless checks, each in exactly one of 1, 2, ' + wfCount + ' and 5 shards; ' + wfCount + ' shards planned at ' + est.join(', ') + ' s');
