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
  'exit /b 0',
  ':check',
  'set /p "CHECK_CANDIDATE="<"%~1"',
  'set /p "CHECK_LIVE="<"%CD%\\export\\Voidsworn.exe"',
  'if not "%CHECK_CANDIDATE%"=="candidate" exit /b 1',
  'if not "%CHECK_LIVE%"=="last good" exit /b 1',
  'exit /b 0',
].join('\r\n') + '\r\n');

for (const failure of ['export', 'package', 'smoke', 'promotion', '']) {
  const r = spawnSync('cmd.exe', ['/d', '/s', '/c', `call "${job}"`], {
    cwd: build, windowsVerbatimArguments: true, windowsHide: true, timeout: 15000, encoding: 'utf8',
    env: { ...process.env, APPDATA: app, FIXTURE_FAILURE: failure },
  });
  const text = read(log);
  assert.equal(r.status, failure ? 1 : 0, `${failure}: ${text}\n${r.stderr}`);
  for (const f of files) assert.equal(read(path.join(build, 'export', f)), failure ? 'last good' : 'candidate', `${failure}: live ${f}`);
  assert.equal(fs.existsSync(path.join(build, 'export/assets.dll')), !failure);
  assert.equal(text.includes('fixture package check'), failure !== 'export');
  assert.equal(text.includes('fixture smoke check'), !['export', 'package'].includes(failure), text);
  assert.equal(/^OK:/m.test(text), !failure);
}
console.log('PASS: export, check and promotion failures keep the live build; two passing checks promote all companions together');

// Try the real Play launcher with a harmless executable in the promoted folder.
const play = path.join(build, 'tools/pc/play_godot.bat');
fs.copyFileSync(path.join(__dirname, 'play_godot.bat'), play);
put(path.join(build, 'godot/project.godot'), '; fake project');
const live = path.join(build, 'export/Voidsworn.exe');
fs.renameSync(live, live + '.fixture');
try { fs.linkSync(process.execPath, live); }
catch (e) { if (e.code !== 'EXDEV') throw e; fs.copyFileSync(process.execPath, live); }
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
