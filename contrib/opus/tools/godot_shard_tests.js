'use strict';
// Issue 1430: the headless Godot list runs as parallel shards on GitHub. These checks run the real run_checks.sh in its
// plan-only mode to prove coverage and budgets, and with a fake Godot to prove scratch cleanup (no real Godot needed).
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawn, spawnSync } = require('node:child_process');
const { setTimeout: delay } = require('node:timers/promises');
const { workflowTexts } = require('./workflow_patch_fixture');

const ROOT = path.resolve(__dirname, '../../..');
const SCRIPT = path.join(ROOT, 'godot/tools/ci/run_checks.sh');
const LIST = path.join(ROOT, 'godot/tools/ci/godot_checks.txt');
const windows = process.platform === 'win32';
const sh = windows ? path.join(process.env.ProgramFiles, 'Git', 'bin', 'bash.exe') : 'sh';
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'godot-shard-1430-'));
const shellPath = p => windows ? p.replace(/\\/g, '/') : p;
const planRows = stdout => stdout.split(/\r?\n/).filter(l => /^\d+\|headless\|/.test(l));

function shell(args, env) {
  const r = spawnSync(sh, args, { cwd: ROOT, env, encoding: 'utf8', windowsHide: true, timeout: 120000 });
  assert.ifError(r.error);
  return { status: r.status, stdout: r.stdout, out: r.stdout + r.stderr };
}

const planEnv = (shard, extra) => ({ ...process.env, SHARD: shard, GODOT_CHECKS_PLAN: '1', RUNNER_TEMP: tmp, ...extra });
const plan = (shard, extra) => shell([SCRIPT], planEnv(shard, extra));

const headless = fs.readFileSync(LIST, 'utf8').split(/\r?\n/).filter(l => l.startsWith('headless|'));
const scriptOf = l => l.split('|')[1];
const stepLines = headless.filter(l => l.split('|')[2].startsWith('step:')).map(scriptOf);
assert.ok(headless.length > 50, 'godot_checks.txt has fewer headless lines than expected');

// The workflow's shard count, read from its matrix, so a change there is exercised here.
const wf = workflowTexts().get('checks.yml');
const m = /shard: \[([0-9, ]+)\]/.exec(wf);
assert.ok(m, 'checks.yml godot-game has no shard matrix');
const shards = m[1].split(',').map(s => Number(s.trim()));
const wfCount = shards.length;
assert.deepEqual(shards, Array.from({ length: wfCount }, (_, i) => i + 1), 'the matrix must list shards 1 to n');
assert.ok(new RegExp('SHARD: \\$\\{\\{ matrix\\.shard \\}\\}/' + wfCount).test(wf), 'the list step must pass SHARD=<shard>/' + wfCount);

function cover(n, extra) {
  const seen = new Map();
  const loads = [];
  for (let i = 1; i <= n; i++) {
    const r = plan(i + '/' + n, extra);
    assert.equal(r.status, 0, 'plan for shard ' + i + '/' + n + ' failed:\n' + r.out);
    const estimate = /about (\d+) s by the recorded times/.exec(r.out);
    assert.ok(estimate, r.out);
    loads.push(Number(estimate[1]));
    const rows = planRows(r.stdout);
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
  return loads;
}

const counts = [...new Set([1, 2, 3, wfCount, 5])];
const est = new Map(counts.map(n => [n, cover(n)])).get(wfCount);
const budget = plan('1/3', { GODOT_CHECKS_BUDGET: '600' });
assert.equal(budget.status, 0, budget.out);
const raised = /([0-9]+) s planned for a 600 s budget; budget raised to ([0-9]+) s/.exec(budget.out);
assert.ok(raised, budget.out);
assert.equal(Number(raised[2]), Math.min(1080, Math.ceil(Number(raised[1]) * 1.15)));
const capped = plan('1/1', { GODOT_CHECKS_BUDGET: '600' });
assert.equal(capped.status, 0, capped.out);
assert.match(capped.out, /budget raised to 1080 s/);

// Exercise the same merge-tree probe as CI, without moving a real ref or merging this checkout.
const mergeFixture = path.join(tmp, 'merge-fixture');
fs.mkdirSync(mergeFixture);
function fixtureGit(status, ...args) {
  const r = spawnSync('git', ['-c', 'user.name=CI Fixture', '-c', 'user.email=fixture@example.invalid', ...args], {
    cwd: mergeFixture, encoding: 'utf8', windowsHide: true, timeout: 10000
  });
  assert.ifError(r.error);
  assert.equal(r.status, status, r.stdout + r.stderr);
  return r.stdout.trim();
}
fixtureGit(0, 'init', '-q');
fs.copyFileSync(path.join(ROOT, '.gitattributes'), path.join(mergeFixture, '.gitattributes'));
const unionFiles = ['godot_checks.txt', 'godot_check_times.txt'].map(name => 'godot/tools/ci/' + name);
fs.mkdirSync(path.join(mergeFixture, 'godot/tools/ci'), { recursive: true });
function treeCommit(files, label, parent) {
  for (const file of files) fs.writeFileSync(path.join(mergeFixture, file), 'shared\n' + label + '\n');
  fixtureGit(0, 'add', '.');
  return fixtureGit(0, 'commit-tree', fixtureGit(0, 'write-tree'), '-m', label, ...(parent ? ['-p', parent] : []));
}
const base = treeCommit([...unionFiles, 'ordinary.txt'], 'base');
const left = treeCommit(unionFiles, 'left', base);
const right = treeCommit(unionFiles, 'right', base);
const mergedTree = fixtureGit(0, 'merge-tree', '--write-tree', left, right);
for (const file of unionFiles) {
  assert.deepEqual(fixtureGit(0, 'show', mergedTree + ':' + file).split(/\r?\n/).sort(), ['left', 'right', 'shared']);
}
const conflictLeft = treeCommit(['ordinary.txt'], 'left', base);
const conflictRight = treeCommit(['ordinary.txt'], 'right', base);
assert.match(fixtureGit(1, 'merge-tree', '--write-tree', conflictLeft, conflictRight), /CONFLICT.*ordinary\.txt/);
if (wf.includes('git merge-tree --write-tree HEAD origin/main')) {
  // Execute the proposed changes job against real refs, including one that is
  // behind main rather than exactly at its tip.
  const step = /        id: classify\n[\s\S]*?        run: \|\n((?: {10}[^\n]*\n)+)/.exec(wf);
  assert.ok(step, 'changes job is missing its Bash step');
  fixtureGit(0, 'read-tree', '--reset', '-u', base);
  const docs = treeCommit(['Docs.md'], 'docs only', base);
  fixtureGit(0, 'remote', 'add', 'origin', '.');
  fixtureGit(0, 'update-ref', 'refs/heads/main', conflictRight);
  fs.mkdirSync(path.join(mergeFixture, 'tools/ci'), { recursive: true });
  fs.copyFileSync(path.join(ROOT, 'tools/ci/docs_only.js'), path.join(mergeFixture, 'tools/ci/docs_only.js'));
  function classify(commit, ref, status, output, detail) {
    fixtureGit(0, 'checkout', '-q', '--detach', '-f', commit);
    const outputFile = path.join(tmp, 'changes-output.txt');
    fs.writeFileSync(outputFile, '');
    const r = spawnSync(sh, ['-e', '-s'], {
      cwd: mergeFixture, encoding: 'utf8', windowsHide: true, timeout: 20000,
      // The docs_only self-test checks live YAML wiring separately in its real
      // checkout. The fixture uses the real classifier for changed paths.
      input: 'node() { if [ "$2" = --self-test ]; then return 0; fi; command node "$@"; }\n' +
        step[1].replace(/^ {10}/gm, ''),
      env: { ...process.env, EVENT: 'push', BASE: '', GITHUB_REF: ref, RUNNER_TEMP: shellPath(tmp),
        GITHUB_STEP_SUMMARY: shellPath(path.join(tmp, 'changes-summary.txt')), GITHUB_OUTPUT: shellPath(outputFile) },
    });
    assert.ifError(r.error);
    assert.equal(r.status, status, r.stdout + r.stderr);
    assert.match(r.stdout, detail);
    assert.equal(fs.readFileSync(outputFile, 'utf8').trim(), output);
  }
  const branch = 'refs/heads/codex/issue-2179';
  classify(conflictRight, 'refs/heads/main', 0, 'godot=true', /Running on main/);
  classify(base, branch, 0, 'godot=false', /Nothing ahead/);
  classify(docs, branch, 0, 'godot=false', /Docs-only change/);
  classify(left, branch, 0, 'godot=true', /Code changed/);
  classify(conflictLeft, branch, 1, '', /CONFLICT.*ordinary\.txt/);
}
// No recorded times at all (a fresh check, or the file gone): still every check exactly once.
cover(wfCount, { GODOT_CHECKS_TIMES: shellPath(path.join(tmp, 'missing_times.txt')) });

// Balance at the workflow's count by the recorded times: no shard more than 25% over the even share.
const first = plan('1/' + wfCount);
assert.equal(first.status, 0, first.out);
const total = est.reduce((a, b) => a + b, 0);
assert.ok(est.length === wfCount && total > 0, 'no load estimate was written');
est.forEach((t, i) => assert.ok(t <= 1.25 * total / wfCount, 'shard ' + (i + 1) + ' is planned for ' + t + ' s of ' + total + ' s'));

const repeat = plan('1/' + wfCount, { GODOT_CHECKS_BUDGET: '1' });
assert.equal(repeat.status, 0, repeat.out);
assert.match(repeat.out, new RegExp('budget raised to ' + Math.min(1080, Math.ceil(est[0] * 1.15)) + ' s'));
assert.deepEqual(planRows(repeat.stdout), planRows(first.stdout));
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

function scratchRoot(r, label = 'scratch') {
  const match = new RegExp('^  ' + label + ': (.+)$', 'm').exec(r.stdout);
  assert.ok(match, r.out);
  return path.normalize(match[1]);
}

function assertPlan(r, base) {
  assert.equal(r.status, 0, r.out);
  assert.equal(path.dirname(scratchRoot(r)), path.normalize(base), r.out);
  assert.deepEqual(planRows(r.stdout), planRows(first.stdout), 'each invocation prints the complete plan on stdout');
}

assert.ok(!fs.existsSync(scratchRoot(first)), 'plan-only calls must clean up their own scratch');

const notDirectory = path.join(tmp, 'file-not-directory');
fs.writeFileSync(notDirectory, 'sentinel');
const fallback = fs.mkdtempSync(path.join(tmp, 'fallback-'));
const unusablePrimary = { RUNNER_TEMP: notDirectory, TMPDIR: notDirectory, TEMP: notDirectory, TMP: fallback };
assertPlan(plan('1/' + wfCount, unusablePrimary), fallback);
assert.deepEqual(fs.readdirSync(fallback), [], 'a successful fallback plan must clean up');
assert.equal(fs.readFileSync(notDirectory, 'utf8'), 'sentinel');
if (windows) {
  const noScratch = plan('1/' + wfCount, { ...unusablePrimary, TMP: notDirectory, USERPROFILE: notDirectory });
  assert.equal(noScratch.status, 1, noScratch.out);
  assert.match(noScratch.out, /^FAIL: could not prepare Godot check scratch space\./m);
  assert.doesNotMatch(noScratch.out, /^PASS/m);
}

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
const guarded = ['title_continue_test', 'title_settings_test'];
const failure = shell([SCRIPT, ...guarded], { ...process.env, GODOT: shellPath(fake), SHARD: '1/1', GODOT_CHECKS_PLAN: '0', RUNNER_TEMP: tmp });
assert.equal(failure.status, 1, failure.out);
assert.match(failure.out, /^  title_continue_test: PASS/m);
assert.match(failure.out, /^  title_settings_test: FAIL/m);
assert.ok(failure.out.indexOf('  title_settings_test: FAIL') < failure.out.indexOf('  title_continue_test: PASS'), failure.out);
assert.match(failure.out, /^    FAIL: late assertion detail/m);
assert.doesNotMatch(failure.out, /placeholder hull:|^PASS:/m);
assert.equal(failure.out.split(/\r?\n/).filter(l => l.startsWith('    ')).length, 8, failure.out);
const failed = scratchRoot(failure, 'scratch kept');
assert.equal(failed, scratchRoot(failure));
const failedWork = path.join(failed, 'godot_checks');
assert.match(fs.readFileSync(path.join(failedWork, 'logs/title_settings_test.log'), 'utf8'), /placeholder hull: unwanted/);
assert.ok(fs.existsSync(path.join(failedWork, 'xdg/title_settings_test/ready')), 'the failed check profile must remain');

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

// Hold both invocations inside the runner until their scratch can be inspected live.
const gateScript = `
: > "$PROOF_GATE/$PROOF_ID" || exit 1
i=0
while [ ! -f "$PROOF_GATE/release" ]; do
  [ "$i" -lt 20 ] || exit 1
  i=$((i + 1)); sleep 1
done
`;

async function overlap(shared, args, env) {
  const gate = fs.mkdtempSync(path.join(tmp, 'gate-'));
  const ids = ['first', 'second'];
  const runs = ids.map(id => new Promise(resolve => {
    const child = spawn(sh, args, { cwd: ROOT, windowsHide: true, env: { ...env, PROOF_GATE: shellPath(gate), PROOF_ID: id } });
    let stdout = '', stderr = '';
    child.stdout.setEncoding('utf8').on('data', data => { stdout += data; });
    child.stderr.setEncoding('utf8').on('data', data => { stderr += data; });
    child.on('error', error => { stderr += String(error); });
    child.on('close', status => resolve({ status, stdout, out: stdout + stderr }));
  }));
  const stop = Date.now() + 15000;
  while (!ids.every(id => fs.existsSync(path.join(gate, id))) && Date.now() < stop) await delay(25);
  const bothReady = ids.every(id => fs.existsSync(path.join(gate, id)));
  const liveRoots = fs.readdirSync(shared).filter(name => /^godot_checks-[a-z0-9]{6}$/i.test(name));
  fs.writeFileSync(path.join(gate, 'release'), '');
  const results = await Promise.all(runs);
  assert.ok(bothReady, 'both invocations must reach the barrier:\n' + results.map(r => r.out).join('\n'));
  assert.deepEqual(results.map(r => path.basename(scratchRoot(r))).sort(), liveRoots.sort());
  return results;
}

async function verifyConcurrentScratch() {
  // Artoo on PR 2223: two plan-only calls with the same malformed Windows temp path (PR 2220).
  if (windows) {
    const shared = fs.mkdtempSync(path.join(tmp, 'mangled path '));
    const mangled = shared.replace(/\\/g, () => '\\\\').replace(/\\\\/, '/');
    assert.notEqual(mangled, shared);
    const bin = fs.mkdtempSync(path.join(tmp, 'plan-bin-'));
    fs.writeFileSync(path.join(bin, 'sed'), `#!/bin/sh
if [ "$1" = -e ]; then
${gateScript}
fi
PATH=\${PATH#*:} exec sed "$@"
`, { mode: 0o755 });
    const env = planEnv('1/' + wfCount, { RUNNER_TEMP: mangled, GODOT_CHECKS_PLAN_EDIT: 'p;d', PROOF_BIN: shellPath(bin) });
    const runs = await overlap(shared, ['-c', 'PATH="$(cd "$PROOF_BIN" && pwd):$PATH" exec sh "$@"', 'sh', shellPath(SCRIPT)], env);
    for (const r of runs) assertPlan(r, shared);
    assert.deepEqual(fs.readdirSync(shared), [], 'both passing plan calls remove their own live scratch');
    console.log('PASS godot_shard_tests: overlapping malformed Windows temp plans, distinct live scratch and no leftovers');
  }

  // Run one pass and one exit-zero SCRIPT ERROR together, both falling back from an unusable primary.
  const shared = fs.mkdtempSync(path.join(tmp, 'shared-scratch-'));
  const engineTemp = fs.mkdtempSync(path.join(tmp, 'stub engine temp '));
  const fixture = fs.mkdtempSync(path.join(tmp, 'cleanup fixture '));
  const ci = path.join(fixture, 'godot/tools/ci');
  fs.mkdirSync(ci, { recursive: true });
  for (const file of ['run_checks.sh', 'check_scratch.js', 'print_temp_dir.gd']) {
    fs.copyFileSync(path.join(path.dirname(SCRIPT), file), path.join(ci, file));
  }
  const userdirLine = headless.find(l => l.split('|')[2] === 'userdir');
  assert.ok(userdirLine, 'need an onboarding check row');
  const script = path.join(fixture, 'godot', scriptOf(userdirLine));
  fs.mkdirSync(path.dirname(script), { recursive: true });
  fs.writeFileSync(script, '');
  fs.writeFileSync(path.join(ci, 'godot_checks.txt'), userdirLine + '\n');
  const stub = path.join(fixture, 'fake godot');
  fs.writeFileSync(stub, `#!/bin/sh
case "$*" in
  *res://tools/ci/print_temp_dir.gd*) printf 'GODOT_TEMP_DIR=%s\\n' "$PROOF_ENGINE_TEMP"; exit 0 ;;
esac
case "$APPDATA" in "$PROOF_ENGINE_TEMP"/voidsworn-onboarding-*/profile) ;; *) exit 2 ;; esac
printf 'profile proof\\n' > "$APPDATA/proof.txt" || exit 2
${gateScript}
if [ "$PROOF_ID" = second ]; then echo 'SCRIPT ERROR: fixture failed'; fi
`, { mode: 0o755 });
  const sentinel = path.join(shared, 'unrelated.txt');
  fs.writeFileSync(sentinel, 'keep');
  const [pass, fail] = await overlap(shared, [shellPath(path.join(ci, 'run_checks.sh'))], {
    ...process.env, ...unusablePrimary, TMPDIR: shared, SHARD: '1/1', GODOT_CHECKS_PLAN: '0', GODOT_CHECKS_PLAN_EDIT: '',
    GODOT_CHECKS_TIMES: '', GODOT_CHECKS_BUDGET: '60', GODOT: shellPath(stub), PROOF_ENGINE_TEMP: shellPath(engineTemp),
  });
  assert.equal(pass.status, 0, pass.out);
  assert.match(pass.out, /^PASS: every listed headless Godot check passed\./m);
  assert.equal(fail.status, 1, fail.out);
  assert.match(fail.out, /^FAIL: 1 Godot check\(s\) failed\./m);
  const kept = scratchRoot(fail, 'scratch kept');
  assert.equal(kept, scratchRoot(fail));
  assert.equal(path.dirname(kept), shared);
  assert.deepEqual(fs.readdirSync(shared).sort(), [path.basename(kept), 'unrelated.txt'].sort());
  assert.equal(fs.readFileSync(sentinel, 'utf8'), 'keep');
  const work = path.join(kept, 'godot_checks');
  const name = path.basename(script, '.gd');
  assert.equal(fs.readFileSync(path.join(work, 'plan.txt'), 'utf8').trim(), '1|' + userdirLine);
  assert.match(fs.readFileSync(path.join(work, 'logs', name + '.log'), 'utf8'), /SCRIPT ERROR: fixture failed/);
  assert.equal(fs.readFileSync(path.join(work, 'xdg', name, 'proof.txt'), 'utf8').trim(), 'profile proof');
  assert.deepEqual(fs.readdirSync(engineTemp), [], 'only the temporary onboarding aliases are removed on both exits');
}

verifyConcurrentScratch().then(() => {
  fs.rmSync(tmp, { recursive: true, force: true });
  console.log('PASS godot_shard_tests: ' + headless.length + ' headless checks, 5-shard plan, old-branch budget, temp paths and pass-only cleanup; workflow uses ' + wfCount + ' shards at ' + est.join(', ') + ' s');
}).catch(error => {
  console.error(error);
  process.exitCode = 1;
});
