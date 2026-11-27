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
const shellPath = p => windows ? p.replace(/\\/g, '/') : p;

function shell(args, env) {
  const r = spawnSync(sh, args, { cwd: ROOT, env, encoding: 'utf8', windowsHide: true, timeout: 120000 });
  assert.ifError(r.error);
  return { status: r.status, out: r.stdout + r.stderr };
}

function plan(shard, extra) {
  const env = { ...process.env, SHARD: shard, GODOT_CHECKS_PLAN: '1', RUNNER_TEMP: tmp, ...extra };
  return shell([SCRIPT], env);
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
const first = plan('1/' + wfCount);
assert.equal(first.status, 0, first.out);
const est = Array.from({ length: wfCount }, (_, i) => {
  const r = i === 0 ? first : plan((i + 1) + '/' + wfCount);
  assert.equal(r.status, 0, r.out);
  const load = /^  shard: \d+ of \d+, \d+ checks, about (\d+) s/m.exec(r.out);
  assert.ok(load, r.out);
  return Number(load[1]);
});
const total = est.reduce((a, b) => a + b, 0);
assert.ok(est.length === wfCount && total > 0, 'no load estimate was written');
est.forEach((t, i) => assert.ok(t <= 1.25 * total / wfCount, 'shard ' + (i + 1) + ' is planned for ' + t + ' s of ' + total + ' s'));

const repeat = plan('1/' + wfCount, { GODOT_CHECKS_BUDGET: '1' });
assert.equal(repeat.status, 0, repeat.out);
assert.match(repeat.out, new RegExp('budget raised to ' + Math.min(1080, Math.ceil(est[0] * 1.15)) + ' s'));
assert.deepEqual(repeat.out.split(/\r?\n/).filter(l => /^\d+\|/.test(l)), first.out.split(/\r?\n/).filter(l => /^\d+\|/.test(l)));
const rolled = plan('1/1', { GODOT_CHECKS_BUDGET: '600' });
assert.equal(rolled.status, 0, rolled.out);
assert.match(rolled.out, new RegExp('budget raised to ' + Math.min(1080, Math.ceil(total * 1.15)) + ' s'));

// Bad SHARD values fail before anything runs.
['0/3', '4/3', 'x/3', '2', '1/', '/3'].forEach(v => {
  const r = plan(v);
  assert.notEqual(r.status, 0, 'SHARD=' + v + ' must fail');
  assert.match(r.out, /FAIL: SHARD/);
});
for (const budget of ['0', 'oops']) {
  const r = plan('1/' + wfCount, { GODOT_CHECKS_BUDGET: budget });
  assert.equal(r.status, 2, r.out);
  assert.match(r.out, /FAIL: GODOT_CHECKS_BUDGET/);
}

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

// PR 2220: native Windows APIs must fold the doubled backslashes before opening a new scratch folder.
if (windows) {
  const mangled = tmp.replace(/\\/g, '\\\\').replace(/\\\\/, '/');
  const r = plan('1/' + wfCount, { RUNNER_TEMP: mangled });
  assert.equal(r.status, 0, r.out);
  assert.equal(r.out, first.out);
}
assert.deepEqual(fs.readdirSync(tmp), [], 'plan-only calls must clean up their own scratch');

const notDirectory = path.join(tmp, 'file-not-directory');
fs.writeFileSync(notDirectory, 'sentinel');
const noScratch = plan('1/' + wfCount, { RUNNER_TEMP: notDirectory });
assert.equal(noScratch.status, 1, noScratch.out);
assert.match(noScratch.out, /^FAIL: could not prepare Godot check scratch space\./m);
assert.equal(fs.readFileSync(notDirectory, 'utf8'), 'sentinel');

// Two workers must overlap with distinct protected profile paths, then report a capped failure excerpt in list order.
const fake = path.join(tmp, 'fake godot');
fs.writeFileSync(fake, `#!/bin/sh
case "$*" in
  *res://main/test/title_settings_test.gd*) name=title_settings_test; peer=title_continue_test ;;
  *res://main/test/title_continue_test.gd*) name=title_continue_test; peer=title_settings_test ;;
  *) exit 2 ;;
esac
case "$APPDATA" in */godot_checks/xdg/"$name") ;; *) echo "FAIL: wrong profile for $name"; exit 1 ;; esac
touch "$APPDATA/ready" || exit 1
i=0
while [ ! -f "$APPDATA/../$peer/ready" ]; do
  if [ "$i" -ge 10 ]; then echo "FAIL: workers did not overlap"; exit 1; fi
  i=$((i + 1)); sleep 1
done
if [ "$name" = title_continue_test ]; then exit 0; fi
echo 'ERROR: placeholder hull: unwanted'
for i in 1 2 3 4 5 6 7 8 9; do echo "ERROR: incidental $i"; done
echo 'FAIL: late assertion detail'
echo 'title settings: FAIL (1)'
exit 1
`);
fs.chmodSync(fake, 0o755);
const contents = fs.readdirSync(tmp);
const guarded = ['title_continue_test', 'title_settings_test'];
const failure = shell([SCRIPT, ...guarded], { ...process.env, GODOT: shellPath(fake), SHARD: '1/1', GODOT_CHECKS_PLAN: '0', RUNNER_TEMP: tmp });
assert.equal(failure.status, 1, failure.out);
assert.match(failure.out, /^  title_continue_test: PASS/m);
assert.match(failure.out, /^  title_settings_test: FAIL/m);
assert.match(failure.out, /^    FAIL: late assertion detail/m);
assert.doesNotMatch(failure.out, /placeholder hull:|^PASS:/m);
assert.equal(failure.out.split(/\r?\n/).filter(l => l.startsWith('    ')).length, 8, failure.out);
assert.deepEqual(fs.readdirSync(tmp), contents, 'failed runs must clean up after printing their evidence');

// The standing checks do not install Godot. With GODOT set, --onboarding also runs the real engine against a custom temp.
if (process.argv.includes('--onboarding')) {
  assert.ok(process.env.GODOT, 'set GODOT to the Godot console executable for --onboarding');
  const customTemp = fs.mkdtempSync(path.join(tmp, 'custom engine temp '));
  const env = { ...process.env, SHARD: '1/1', GODOT_CHECKS_PLAN: '0', RUNNER_TEMP: tmp, TMPDIR: customTemp };
  if (windows) Object.assign(env, { TEMP: customTemp, TMP: customTemp });
  const probeRun = spawnSync(env.GODOT, ['--headless', '--path', 'godot', '--script', 'res://tools/ci/print_temp_dir.gd'], {
    cwd: ROOT, env: { ...env, APPDATA: tmp, XDG_DATA_HOME: tmp }, encoding: 'utf8', windowsHide: true, timeout: 20000,
  });
  assert.ifError(probeRun.error);
  assert.equal(probeRun.status, 0, probeRun.stderr);
  const probe = probeRun.stdout;
  const actual = /^GODOT_TEMP_DIR=(.+)\r?$/m.exec(probe);
  assert.ok(actual, probe);
  assert.equal(path.normalize(actual[1].trimEnd()), path.normalize(customTemp));
  const before = fs.readdirSync(tmp);
  const r = shell([SCRIPT, 'onboarding_test', ...guarded], env);
  assert.equal(r.status, 0, r.out);
  for (const check of ['onboarding_test', ...guarded]) assert.match(r.out, new RegExp('^  ' + check + ': PASS', 'm'));
  assert.deepEqual(fs.readdirSync(tmp), before, 'successful runs must clean up their own scratch');
  assert.ok(!fs.readdirSync(customTemp).some(entry => entry.startsWith('voidsworn-onboarding-ci-')), 'profile alias was left behind');
  console.log('PASS godot_shard_tests: real onboarding, title settings and Continue checks with a non-default TMPDIR');
}

fs.rmSync(tmp, { recursive: true, force: true });
console.log('PASS godot_shard_tests: ' + headless.length + ' headless checks, each in exactly one of 1, 2, ' + wfCount + ' and 5 shards; ' + wfCount + ' shards planned at ' + est.join(', ') + ' s');
