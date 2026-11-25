'use strict';
// Issue 962: run an unchanged copy of the CLI against temporary fixture rows.
// The next row reads the redirected log while the suite is still running.
// Every *_tests.js in this folder is discovered by the standing checks.
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const { ROOT } = require('./run_all_checks');
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'checks962 proof '));
const runner = path.join(root, 'contrib/opus/tools/run_all_checks.js');
const launchTimeout = process.platform === 'win32' ? 180000 : 60000;
const codex = fs.readFileSync(path.join(ROOT, 'tools/pc/codex_issue.bat'), 'utf8');
const write = (file, text) => {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, text);
};
write(runner, fs.readFileSync(path.join(__dirname, 'run_all_checks.js')));
write(path.join(path.dirname(runner), 'checks_baseline.json'), JSON.stringify({
  knownFindingsFailures: [], checksCeiling: 0, namingHardHits: 0, driftDifferedCeiling: 1,
}));
const failName = 'a_fixture_fail_tests';
const failFile = path.join(path.dirname(runner), failName + '.js');
const nextName = 'b_fixture_next_tests';
const lines = Array.from({ length: 20 }, (_, i) => 'fixture output ' + String(i + 1).padStart(2, '0'));
write(failFile,
  'console.log(' + JSON.stringify(lines.concat('FAIL: fixture reason').join('\n')) + ');\nprocess.exitCode = 7;\n');
write(path.join(path.dirname(runner), nextName + '.js'), `
const fs = require('fs'), assert = require('assert');
if (process.env.CHECKS962_VERIFY_LIVE === '1') {
  const log = fs.readFileSync(process.env.CHECKS962_LOG, 'utf8');
  const next = log.indexOf('Running ${nextName} ');
  assert(next >= 0);
  assert(/FAIL: ${failName} \\(\\d+\\.\\d{2} s\\) \\| FAIL: fixture reason/.test(log.slice(0, next)), log);
  for (let n = 1; n <= 20; n++) assert(log.indexOf('fixture output ' + String(n).padStart(2, '0')) < next && log.includes('fixture output ' + String(n).padStart(2, '0')), log);
  assert(!log.includes('check | result | seconds | detail'), log);
}
console.log('PASS: next fixture saw the live failure');
`);
// Supply tiny successful rows for the CLI's explicitly registered checks too.
// Discovery comes from the copied runner, so no real suite or Windows matrix runs here.
for (const c of require(runner).buildChecks()) {
  const file = path.join(root, c.file);
  if (fs.existsSync(file)) continue;
  write(file, 'console.log(' + JSON.stringify([
    'SUMMARY: 0 FAIL, 0 CHECK', 'naming_lint_game: 0 hard, 0 word',
    '0 tests, 0 pass, 0 fail', 'DRIFT SUMMARY: constants 1 differed', 'PASS: fixture row',
  ].join('\n')) + ');\n');
}
let runs = 0;
function run(args, verifyLive = false, ci = false) {
  const logFile = path.join(root, 'run-' + (++runs) + '.txt');
  const fd = fs.openSync(logFile, 'w');
  let result;
  try {
    result = spawnSync(process.execPath, [runner, ...args], {
      cwd: root, env: { ...process.env, CI: ci ? 'true' : '', CHECKS962_LOG: logFile, CHECKS962_VERIFY_LIVE: verifyLive ? '1' : '0' },
      stdio: ['ignore', fd, fd], windowsHide: true, timeout: launchTimeout,
    });
  } finally { fs.closeSync(fd); }
  assert.ifError(result.error);
  return { status: result.status, output: fs.readFileSync(logFile, 'utf8') };
}
const full = run(['--json'], true);
assert.equal(full.status, 1, full.output);
const report = JSON.parse(fs.readFileSync(path.join(root, 'checks_report.json'), 'utf8'));
assert.deepEqual(report.filter(r => r.result === 'FAIL').map(r => r.check), [failName], full.output);
assert.equal(report[0].exitCode, 7);
assert.equal(report[0].output, lines.join('\n') + '\nFAIL: fixture reason\n');
assert(report.some(r => r.result === 'KNOWN'), full.output);
for (const row of report) {
  const live = row.result + ': ' + row.check + ' (' + row.seconds.toFixed(2) + ' s) | ' + row.detail;
  assert(full.output.includes(live), live);
  assert(full.output.indexOf(live) < full.output.indexOf('check | result | seconds | detail'), live);
  assert(full.output.includes(`${row.check} | ${row.result} | ${row.seconds.toFixed(2)} | ${row.detail}`));
}
// Issue 1739: a FAIL row's whole output is in the log, not only its first 15 lines.
assert.equal((full.output.match(new RegExp('FAIL ' + failName + ' output:', 'g')) || []).length, 1);
assert(full.output.includes('fixture output 16'), full.output);
assert(full.output.includes(lines[lines.length - 1]), full.output);
const onlyFail = run(['--only', failName]);
assert.equal(onlyFail.status, 1, onlyFail.output);
assert(!onlyFail.output.includes('Running ' + nextName));
const onlyPass = run(['--only', 'contrib/opus/tools/' + nextName + '.js']);
assert.equal(onlyPass.status, 0, onlyPass.output);
assert(!onlyPass.output.includes('Running ' + failName));
const fast = run(['--fast', '--json']);
assert.equal(fast.status, 0, fast.output);
const fastReport = JSON.parse(fs.readFileSync(path.join(root, 'checks_report.json'), 'utf8'));
for (const row of fastReport) assert(fast.output.includes(row.result + ': ' + row.check + ' (' + row.seconds.toFixed(2) + ' s) | ' + row.detail));
assert(fastReport.some(r => r.check === failName && r.result === 'SKIP' && r.detail === 'SKIP: fast'));
assert(fastReport.some(r => r.check === 'nem_assign_enum' && r.result === 'PASS'));
assert.equal(run(['--only', 'missing_fixture']).status, 1);
assert(require(runner).buildChecks().some(c => c.file === '.claude/hooks/guard.test.cjs'));

// Exercise the successful CLI exit with a real KNOWN row. On Windows feed that exit through the Codex check
// step too, with a stand-in watchdog and parity command so this fixture never starts the real suite or Godot.
write(failFile, "console.log('PASS: fixture repaired');\n");
if (process.platform === 'win32') {
  const bat = path.join(root, 'tools/pc/codex_issue.bat');
  write(bat, codex);
  write(path.join(path.dirname(bat), 'tmo.bat'), [
    '@echo off',
    'if /i "%~2"=="%COMSPEC%" exit /b 0',
    '"%CHECKS962_NODE%" "%~3" --json --jobs 4',
    'exit /b %ERRORLEVEL%',
  ].join('\r\n') + '\r\n');
  const checked = spawnSync(process.env.ComSpec || 'cmd.exe', ['/d', '/s', '/c', `call "${bat}" checks "${root}"`], {
    cwd: root, env: { ...process.env, CHECKS962_NODE: process.execPath }, windowsVerbatimArguments: true,
    encoding: 'utf8', windowsHide: true, timeout: launchTimeout,
  });
  assert.ifError(checked.error);
  const nodeLog = fs.readFileSync(path.join(root, 'checks_node.txt'), 'utf8');
  assert.equal(checked.status, 0, nodeLog + checked.stderr);
  assert.match(fs.readFileSync(path.join(root, 'result.txt'), 'utf8'), /checks: node exit 0, parity exit 0/);
} else {
  const checked = run(['--json', '--jobs', '4']);
  assert.equal(checked.status, 0, checked.output);
}
const accepted = JSON.parse(fs.readFileSync(path.join(root, 'checks_report.json'), 'utf8'));
assert(accepted.every(row => ['PASS', 'KNOWN'].includes(row.result)));
assert(accepted.some(row => row.result === 'PASS'));
assert(accepted.some(row => row.result === 'KNOWN' && row.detail.includes('within the baseline')));

const optional = require(runner).buildChecks().find(c => c.kind === 'optional');
write(path.join(root, optional.file), "console.error('Cannot find module: planted dependency'); process.exitCode = 1;\n");
const localMissing = run(['--only', optional.name]);
assert.equal(localMissing.status, 0, localMissing.output);
assert.match(localMissing.output, /SKIP: fixture_check/);
const ciMissing = run(['--only', optional.name], false, true);
assert.equal(ciMissing.status, 1, ciMissing.output);
assert.match(ciMissing.output, /FAIL: check could not run in CI: SKIP: Cannot find module/);

write(failFile, "console.log('PASS: static fixture'); console.log('SKIP fixture: no pwsh');\n");
const localSkip = run(['--only', failName]);
assert.equal(localSkip.status, 0, localSkip.output);
assert.match(localSkip.output, new RegExp('SKIP: ' + failName));
const ciSkip = run(['--only', failName], false, true);
assert.equal(ciSkip.status, 1, ciSkip.output);
assert.match(ciSkip.output, /FAIL: check could not run in CI: SKIP fixture: no pwsh/);
const windowsOnly = 'tools/pc/g2_export_selftest.js';
const windowsMessage = 'SKIP: playtest export fixture needs Windows cmd.exe';
write(path.join(root, windowsOnly), 'console.log(' + JSON.stringify(windowsMessage) + ');\n');
const ciWindows = run(['--only', windowsOnly], false, true);
assert.equal(ciWindows.status, process.platform === 'win32' ? 1 : 0, ciWindows.output);
const { windowsSkipAllowed } = require(runner);
assert.equal(windowsSkipAllowed(windowsOnly, windowsMessage, 'linux'), true);
assert.equal(windowsSkipAllowed(windowsOnly, windowsMessage + '\nSKIP no pwsh', 'linux'), false);

const work = fs.readFileSync(path.join(ROOT, 'tools/pc/work_issue.bat'), 'utf8');
assert(/call :checks "%O%"/.test(codex));
assert(/call "%TP%tmo\.bat" 5400 node contrib\\opus\\tools\\run_all_checks\.js/.test(codex));
assert(/if not defined CHECK_CAP set "CHECK_CAP=3600"/.test(work));
assert(/call "%T%tmo\.bat" %CHECK_CAP% "%NODE%" contrib\\opus\\tools\\run_all_checks\.js/.test(work));
assert(/call "%TP%tmo\.bat" 1500 "%COMSPEC%" \/c tools\\pc\\parity\.bat/.test(codex));
assert(/if not defined PARITY_CAP set "PARITY_CAP=1500"/.test(work));
// Issue 1739: rows never inherit the lane runner's job variables, but keep PATH, TEMP and the GPU lane.
const { rowEnv } = require(path.join(__dirname, 'run_all_checks.js'));
const leaked = rowEnv({ PATH: 'p', TEMP: 't', PC_GPU_LANE: 'C', PC_RUN_TEMP: 'x', PC_RUN_SCRATCH: 'x', PC_RUNNER_LOCKED_ISSUE: '1693',
  CODEX_MODEL: 'gpt-6.2-astra', CODEX_LOCKED_REPO: 'r', WORK_LOCKED_REPO: 'r', TMO_REPO: 'r', CHECKS_OK: '0', PC_WAIT_FOR: 'w' });
assert.deepEqual(leaked, { PATH: 'p', TEMP: 't', PC_GPU_LANE: 'C' });
console.log('PASS: live failures precede the next row; table and JSON agree; PASS with reasoned KNOWN rows exits 0; FAIL exits 1; Codex runs the same check step in the lane and proof');
console.log('Evidence: ' + root);
