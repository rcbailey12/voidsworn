'use strict';
// The actual batch job runs against fake templates and a fake tmo, with no Godot or GPU.
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

if (process.platform !== 'win32') {
  console.log('SKIP: playtest export fixture needs Windows cmd.exe');
  process.exit(0);
}
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'export 1100 '));
const app = path.join(root, 'fake appdata');
const build = path.join(root, 'build with spaces');
const job = path.join(__dirname, 'jobs/g2_export.bat');
const log = path.join(root, 'shots/g2_export_log.txt');
const files = ['Voidsworn.exe', 'Voidsworn.console.exe', 'Voidsworn.pck'];
const put = (p, value) => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, value);
};
const read = p => fs.readFileSync(p, 'utf8').trim();
put(path.join(app, 'Godot/export_templates/4.7.2.stable/windows_release_x86_64.exe'), 'stub');
put(path.join(root, 'godot_path.txt'), 'unused fake Godot.exe\r\n');
put(path.join(build, 'godot/gen/v3.txt'), 'no asset build');
fs.mkdirSync(path.dirname(log));
for (const f of files) put(path.join(build, 'export', f), 'last good\r\n');
put(path.join(build, 'tools/pc/tmo.bat'), [
  '@echo off',
  'if "%~6"=="--export-release" goto export',
  'if "%~5"=="--check-export" goto package',
  'if "%~5"=="--bot-runs" goto smoke',
  'if "%~6"=="--import" exit /b 0',
  'exit /b 99',
  ':export',
  'for %%F in (Voidsworn.exe Voidsworn.console.exe Voidsworn.pck assets.dll) do echo candidate>"%~dp8%%F"',
  'if "%FIXTURE_FAILURE%"=="export" exit /b 51',
  'exit /b 0',
  ':package',
  'echo fixture package check',
  'call :check "%~f2"',
  'if errorlevel 1 exit /b 54',
  'if "%FIXTURE_FAILURE%"=="package" exit /b 52',
  'exit /b 0',
  ':smoke',
  'echo fixture smoke check',
  'call :check "%~f2"',
  'if errorlevel 1 exit /b 55',
  'if "%FIXTURE_FAILURE%"=="smoke" exit /b 53',
  'if "%FIXTURE_FAILURE%"=="promotion" move "%~dp2." "%~dp2..\\unavailable-candidate" >nul',
  // Issue 1365: the smoke's report is the ninth argument after the program; write the one this case needs.
  'shift & shift & shift & shift & shift & shift & shift & shift & shift',
  'echo fixture smoke report path %~nx1',
  'if "%FIXTURE_FAILURE%"=="parse" echo SCRIPT ERROR: Parse Error: Expected end of statement',
  'if "%FIXTURE_FAILURE%"=="no-report" exit /b 0',
  // copy keeps the old write time, like a report some earlier run left behind
  'if "%FIXTURE_FAILURE%"=="stale-report" (',
  '  copy /y "%FIXTURE_STALE%" "%~1" >nul',
  '  exit /b 0',
  ')',
  'set "FIXTURE_RUNS={},{}"',
  'if "%FIXTURE_FAILURE%"=="one-run" set "FIXTURE_RUNS={}"',
  'set "FIXTURE_ERRORS=0"',
  'if "%FIXTURE_FAILURE%"=="errors" set "FIXTURE_ERRORS=1"',
  'set "FIXTURE_SOFTLOCKS=0"',
  'if "%FIXTURE_FAILURE%"=="softlocks" set "FIXTURE_SOFTLOCKS=1"',
  '>"%~1" echo {"runs":[%FIXTURE_RUNS%],"errors":%FIXTURE_ERRORS%,"softlocks":%FIXTURE_SOFTLOCKS%}',
  'exit /b 0',
  ':check',
  'set /p "CHECK_CANDIDATE="<"%~1"',
  'set /p "CHECK_LIVE="<"%CD%\\export\\Voidsworn.exe"',
  'if not "%CHECK_CANDIDATE%"=="candidate" exit /b 1',
  'if not "%CHECK_LIVE%"=="last good" exit /b 1',
  'exit /b 0',
].join('\r\n') + '\r\n');

const smokeReport = path.join(root, 'shots/g2_export_smoke.json');
const staleReport = path.join(root, 'stale smoke.json');
put(staleReport, '{"runs":[{},{}],"errors":0,"softlocks":0}');
fs.utimesSync(staleReport, new Date('2026-11-19T00:00:00Z'), new Date('2026-11-19T00:00:00Z'));
// Report-level failures: the smoke exits 0, so only the report and output checks can stop the promotion (issue 1365).
const reportFailures = ['no-report', 'stale-report', 'one-run', 'errors', 'softlocks', 'parse'];
for (const failure of ['export', 'package', 'smoke', ...reportFailures, 'promotion', '']) {
  // A good report from an earlier run is on disk before every case; it must never count for this one.
  put(smokeReport, '{"runs":[{},{}],"errors":0,"softlocks":0}');
  const r = spawnSync('cmd.exe', ['/d', '/s', '/c', `call "${job}"`], {
    cwd: build, windowsVerbatimArguments: true, windowsHide: true, timeout: 15000, encoding: 'utf8',
    env: { ...process.env, APPDATA: app, FIXTURE_FAILURE: failure, FIXTURE_STALE: staleReport },
  });
  const text = read(log);
  assert.equal(r.status, failure ? 1 : 0, `${failure}: ${text}\n${r.stderr}`);
  for (const f of files) assert.equal(read(path.join(build, 'export', f)), failure ? 'last good' : 'candidate', `${failure}: live ${f}`);
  assert.equal(fs.existsSync(path.join(build, 'export/assets.dll')), !failure);
  assert.equal(text.includes('fixture package check'), failure !== 'export');
  assert.equal(text.includes('fixture smoke check'), !['export', 'package'].includes(failure), text);
  assert.equal(/^OK:/m.test(text), !failure);
  if (reportFailures.includes(failure)) assert.match(text, /^FAIL: (?:the smoke|smoke)/m, `${failure}: ${text}`);
  // Artoo on PR 1366: the gate reads only this candidate's own report and output, never the fixed-name copies
  if (!['export', 'package', 'smoke'].includes(failure)) {
    assert.match(text, /^fixture smoke report path g2_export_smoke_[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\.json$/m, text);
    assert.deepEqual(fs.readdirSync(path.dirname(smokeReport)).filter(n => /^g2_export_smoke.*[0-9a-f]{12}\./.test(n)), [], `${failure}: per-run smoke files left behind`);
    assert.ok(fs.existsSync(path.join(root, 'shots/g2_export_smoke_output.txt')), `${failure}: the latest smoke output for people`);
  }
  if (failure === 'no-report') assert.ok(!fs.existsSync(smokeReport), 'the old fixed-name report is gone when this run wrote none');
  if (['stale-report', 'one-run', 'errors', 'softlocks', 'parse', ''].includes(failure)) assert.ok(fs.existsSync(smokeReport), `${failure}: the latest report for people`);
  if (failure === 'stale-report') assert.match(text, /older than this run/, text);
  if (failure === 'parse') assert.match(text, /has a script error: SCRIPT ERROR: Parse Error/, text);
  if (!failure) assert.match(text, /smoke report checked: 2 runs, 0 errors, 0 softlocks/);
}
console.log('PASS: export, check, smoke report (missing, stale, short, errors, softlocks, parse error) and promotion failures keep the live build; a clean run promotes all companions together');

// Try the real Play launcher with a harmless executable in the promoted folder.
const play = path.join(build, 'tools/pc/play_godot.bat');
fs.copyFileSync(path.join(__dirname, 'play_godot.bat'), play);
put(path.join(build, 'godot/project.godot'), '; fake project');
const live = path.join(build, 'export/Voidsworn.exe');
fs.renameSync(live, live + '.fixture');
// Always copy: hard links to node.exe left in kept TEMP scratch pushed it to NTFS's 1023-link limit (issue 1854).
fs.copyFileSync(process.execPath, live);
const marker = path.join(root, 'played.txt');
const launch = path.join(build, 'launch.js');
put(launch, `require('fs').writeFileSync(${JSON.stringify(marker)}, process.execPath);`);
const played = spawnSync('cmd.exe', ['/d', '/s', '/c', `call "${play}" "${launch}"`], {
  cwd: build, windowsVerbatimArguments: true, windowsHide: true, timeout: 10000, encoding: 'utf8',
});
assert.equal(played.status, 0, played.stderr);
const deadline = Date.now() + 5000;
while (!fs.existsSync(marker) && Date.now() < deadline) Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 50);
assert.equal(read(marker).toLowerCase(), live.toLowerCase());
console.log('PASS: Play launches the promoted export in a path with spaces');
