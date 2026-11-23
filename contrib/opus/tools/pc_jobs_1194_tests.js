'use strict';
// Issue 1194: PC jobs use one tools copy, a tool preflight and honest exit codes; the watchers file failed jobs apart;
// PC_DOCTOR.bat is read only. Static contract checks run everywhere. On Windows the step helper, the preflight, the strict
// hash check, the tmo.bat hand-off and the doctor also run for real against fake tools in a temp folder.
process.env.TMO_OWN_COPY = '1';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');

const ROOT = path.resolve(__dirname, '../../..');
const PC = path.join(ROOT, 'tools/pc');
// Files check out CRLF on the PC; compare them as LF everywhere.
const read = p => fs.readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
let groups = 0;
const pass = msg => { groups++; console.log('PASS ' + msg); };

// ---------------------------------------------------------------- static contract
const wrap = read(path.join(PC, 'job_wrap.bat'));
for (const label of ['jw_init', 'jw_run', 'jw_copy', 'jw_fail', 'jw_note', 'jw_end']) assert(wrap.includes(':' + label + '\r\n') || wrap.includes(':' + label + '\n'), 'job_wrap has ' + label);
assert(wrap.includes('call "%JW_TOOLS%\\tmo.bat" %JW_RAW:~4%'), 'every step runs under the watchdog');
assert(/if not defined PC_GPU_ISSUE[^\n]*\n[^\n]*goto jw_run_fail/.test(wrap), 'a step without a GPU label fails');
assert(wrap.includes('set "PC_GPU_ISSUE=%~3"'), 'init sets the GPU label');
assert(wrap.includes('>> "%JW_ST%" echo done FAILED: %JW_FAILED%') && wrap.includes('>> "%JW_ST%" echo done PASS'), 'done PASS or done FAILED');
const end = wrap.slice(wrap.indexOf(':jw_end'));
assert(/done FAILED[\s\S]*?all done[\s\S]*?exit \/b 1[\s\S]*?:jw_pass[\s\S]*?done PASS[\s\S]*?all done[\s\S]*?exit \/b 0/.test(end), 'end: done line, then all done, then the exit code');
assert(wrap.includes('endlocal & set "JW_FAILED=%JW_F%" & set "JW_STOP=%JW_S%" & set "JW_STEP=" & set "JW_OPTIONAL=" & set "JW_CONTINUE=" & set "JW_EXPECT=" & exit /b %JW_RC%'),
  'step settings never leak into the next step');
assert(wrap.includes('if not "%JW_OPTIONAL%"=="1" goto jw_run_fail'), 'only an optional step may fail quietly');
assert(wrap.includes('skipped %JW_NAME%: an earlier step failed'), 'a failed required step stops the later ones');
assert(/hashcheck "%JW_OUT%" "%JW_TOOLS%" "%JW_HASHES%" strict/.test(wrap), 'init checks the watchdog hashes strictly');
assert(/preflight-tools "%JW_OUT%" "%~4"[\s\S]*?set "JW_RC=2"/.test(wrap), 'a missing tool stops init with exit 2');
const initOrder = ['set "PC_GPU_ISSUE=%~3"', 'lane_tools_refresh.ps1" -Build tools_live', 'hashcheck "%JW_OUT%"', 'preflight-tools', ':jw_init_fail'];
initOrder.reduce((at, needle) => { const i = wrap.indexOf(needle, at); assert(i > at, 'init order: ' + needle); return i; }, 0);
assert(wrap.includes('move /y "%JW_OUT%\\done.txt" "%JW_OUT%\\done_previous.txt"'), 'an older done.txt is kept, not deleted');
assert(!/^\s*(del|erase|rd|rmdir)\b/im.test(wrap), 'job_wrap deletes nothing');
// Issue 1180: end starts the janitor's after-job cleanup detached (the janitor rate-limits it and skips during GPU work).
assert(/:jw_end[\s\S]*?call :jw_janitor[\s\S]*?done FAILED/.test(wrap), 'end starts the after-job cleanup before the done lines');
assert(/:jw_janitor\r?\nif "%JW_NO_JANITOR%"=="1" exit \/b 0\r?\nif not exist "%JW_TOOLS%\\janitor\.ps1" exit \/b 0/.test(wrap), 'the after-job cleanup can be turned off and needs the installed janitor');
assert(/Start-Process -WindowStyle Hidden[^\n]*janitor|Start-Process -WindowStyle Hidden[^\n]*--after-job/.test(wrap) && wrap.includes('--after-job'), 'the janitor runs detached with --after-job');
pass('job_wrap: GPU label, watchdog steps, optional and continue steps, outputs, done lines and exit codes');

const ported = {
  'jobs/explosion_routes.bat': 'godot blender pil',
  'jobs/ui344_briefing_shots.bat': 'godot',
  'jobs/ui344_rollout_shots.bat': 'godot',
  'jobs/godot_gpu_checks.bat': 'godot',
  'jobs/look_bench.bat': 'godot pil',
  'run_smoke.bat': '',
};
for (const [name, tools] of Object.entries(ported)) {
  const bat = read(path.join(PC, name));
  const init = bat.indexOf('call "%JW%" init ');
  assert(init > 0, name + ' calls job_wrap init');
  assert(bat.slice(init).split(/\r?\n/)[0].endsWith(`"${tools}"`), name + ' preflights ' + (tools || 'no tools'));
  assert(bat.includes('call "%JW%" end'), name + ' ends through job_wrap');
  const code = bat.split(/\r?\n/).filter(l => !/^\s*rem\b/i.test(l)).join('\n');
  assert(!/"%TMO%"|tmo\.bat"\s/.test(code), name + ' runs no step outside job_wrap');
  assert(!/nvidia-smi/i.test(code), name + ' has no nvidia-smi polling');
  assert(!/^\s*echo done\s*>/im.test(code), name + ' writes no unconditional done.txt');
  const afterEnd = code.slice(code.lastIndexOf('call "%JW%" end')).split('\n')[1] || '';
  assert(/%ERRORLEVEL%/.test(afterEnd), name + ' exits with the code end gave: ' + afterEnd);
  const before = code.slice(0, code.indexOf('call "%JW%" init '));
  assert(!/\bgit\b[^\n]*\bclone\b|call "%JW%" run/.test(before), name + ' clones nothing before the preflight');
}
for (const name of ['jobs/ui344_briefing_shots.bat', 'jobs/ui344_rollout_shots.bat']) {
  assert(!read(path.join(PC, name)).includes('%R%\\tools\\pc\\tmo.bat'), name + ' never uses the old branch checkout watchdog');
}
pass('the five job bats and run_smoke run through job_wrap: preflight first, no polling, honest end');

{
  // Look bench after 1252: the run-active marker is held by one redirection around every step, so it stays open for the
  // whole bench, and a failed bench reaches job_wrap end (done FAILED, exit 1) so the watcher files it under failed.
  const lb = read(path.join(PC, 'jobs/look_bench.bat'));
  const lines = lb.split('\n').filter(l => !/^\s*rem\b/i.test(l)).join('\n');
  const init = lines.indexOf('call "%JW%" init ');
  const marker = lines.indexOf('call :run_tools 9>"%TEMP%\\.voidsworn-run-active"');
  const tools = lines.indexOf('\n:run_tools');
  assert(init > 0 && marker > init, 'look bench: the preflight runs before the marker is taken');
  assert(/^set "RUN_EL=%ERRORLEVEL%"\r?$/m.test(lines.slice(marker).split('\n')[1]) &&
    /\nexit \/b %RUN_EL%\r?\n/.test(lines.slice(marker, tools)), 'look bench: the exit code of the marked block is the job exit code');
  assert(tools > marker, 'look bench: the marked block follows the marker call');
  const top = lines.slice(0, tools);
  assert(!/call "%JW%" run|\bgit\b|call :bench/.test(top), 'look bench: no step runs outside the marked block');
  const body = lines.slice(tools);
  assert(body.indexOf('\n:finish') > 0 && body.indexOf('call "%JW%" end') > body.indexOf('\n:finish'), 'look bench: end runs inside the marked block');
  assert(body.indexOf('call :bench') > 0 && body.indexOf('call :bench') < body.indexOf('\n:finish'), 'look bench: the bench runs inside the marked block');
  for (const m of body.matchAll(/call :bench [^\n]*\n([^\n]*)/g)) assert.equal(m[1].trim(), 'if errorlevel 1 goto finish', 'look bench: a failed bench goes to end');
  const bench = body.slice(body.indexOf('\n:bench'));
  assert(/call "%JW%" fail "bench %SHA% did not finish"\s*\n\s*exit \/b 1/.test(bench), 'look bench: a bench that did not finish is marked failed');
  assert(/FAILED: private TEMP setup >> "%ST%"\s*\n\s*call "%JW%" fail "private TEMP setup"\s*\n\s*goto finish/.test(lines), 'look bench: a failed TEMP setup still ends through job_wrap');
}
pass('look bench: the marker stays open for every step, and a failed bench ends FAILED with a non-zero exit');

for (const [name, q, dir] of [['watcher.bat', 'queue', 'build'], ['watcher_b.bat', 'queue_b', 'build_b']]) {
  const w = read(path.join(PC, name)).replace(/\r\n/g, '\n');
  assert(w.includes(`if not exist ${q}\\failed mkdir ${q}\\failed`), name + ' makes the failed folder');
  assert(w.includes(`call "%~dp0${q}\\running\\%J%" >> "%~dp0${q}\\logs\\%J%.log" 2>&1\nset "JX=%ERRORLEVEL%"`), name + ' keeps the job exit code');
  assert(w.includes(`echo [%date% %time%] finished, exit %JX% >> "${q}\\logs\\%J%.log"`), name + ' logs the exit code');
  assert(w.includes(`if "%JX%"=="0" (move /y "${q}\\running\\%J%" "${q}\\done\\%J%" >nul) else (move /y "${q}\\running\\%J%" "${q}\\failed\\%J%" >nul)`), name + ' files failed jobs apart');
  assert(w.includes(`pushd ${dir}`));
}
const watcher = read(path.join(PC, 'watcher.bat'));
assert(watcher.indexOf('-Build tools_live') > 0 && watcher.indexOf('-Build tools_live') < watcher.indexOf('move /y "queue\\%J%" "queue\\running\\%J%"'), 'the main watcher refreshes tools_live before a job');
assert(watcher.indexOf('-Build build') > 0 && watcher.indexOf('-Build build') < watcher.indexOf('move /y "queue\\%J%" "queue\\running\\%J%"'), 'the main watcher refreshes build\\tools between jobs');
pass('watchers log the exit code and move failed jobs to the failed folder; the main one refreshes tools between jobs');

const tmo = read(path.join(PC, 'tmo.bat'));
assert(tmo.includes('set "TMO_LIVE=%USERPROFILE%\\Downloads\\voidsworn_test\\tools_live"'));
assert(tmo.includes('if "%PC_RUNNER_TEST%"=="1" goto run') && tmo.includes('if "%TMO_OWN_COPY%"=="1" goto run'), 'tests keep their own watchdog');
assert(tmo.includes('if /i "%~dp0"=="%TMO_LIVE%\\%TMO_VER%\\pc\\" goto run'), 'tools_live does not hand off to itself');
assert(tmo.includes('set "TMO_PS=%TMO_LIVE%\\%TMO_VER%\\pc\\run_timeout.ps1"') && tmo.includes('-File "%TMO_PS%"'), 'other copies hand off to tools_live');
// Artoo on PR 1254: once tools_live exists, a blank pointer or a missing target stops the step; it never falls back.
const tmoCode = tmo.replace(/\r\n/g, '\n');
assert(tmoCode.includes('if not exist "%TMO_LIVE%\\" goto run\nif not defined TMO_VER goto broken\n'), 'a blank pointer fails closed');
assert(tmoCode.includes('if not exist "%TMO_LIVE%\\%TMO_VER%\\pc\\run_timeout.ps1" goto broken\nset "TMO_PS='), 'a missing target fails closed');
assert(/:broken\n[^\n]*\nexit \/b 125/.test(tmoCode), 'a broken install exits 125 without running anything');
const ship = read(path.join(PC, 'jobs/ship_job.bat'));
assert(!ship.includes('call "%C%\\tools\\pc\\tmo.bat"') && (ship.match(/call "%TMO%"/g) || []).length === 5, 'ship_job runs every step through the tools_live watchdog');
assert(ship.includes('if exist "%V%\\tools_live\\" if not defined TMO_OK set "FAILED='), 'ship_job fails closed on a broken install');
assert(read(path.join(ROOT, 'contrib/opus/tools/run_all_checks.js')).includes("TMO_OWN_COPY: '1'"), 'the standing checks test this checkout');
pass('every tmo.bat outside tools_live hands its step to the canonical watchdog');

const common = read(path.join(PC, 'runner_common.ps1'));
const pre = common.slice(common.indexOf("elseif ($mode -eq 'preflight-tools')"), common.indexOf("elseif ($mode -eq 'model')"));
for (const tool of ['godot', 'blender', 'ffmpeg', 'node', 'pil']) assert(pre.includes(`'${tool}'`), 'preflight knows ' + tool);
assert(/if \(\$missing\.Count\) \{ exit 2 \}/.test(pre), 'preflight exits 2 on a missing tool');
assert(pre.includes('-c "import PIL"'), 'pil means a Python that imports Pillow');
assert(pre.includes("'tools.cmd'") && pre.includes("'set \"JW_' + $name.ToUpperInvariant()"), 'preflight hands the found paths to the job');
const hc = common.slice(common.indexOf("elseif ($mode -eq 'hashcheck')"), common.indexOf("elseif ($mode -eq 'preflight-tools')"));
assert(hc.includes("$guarded = @('tmo.bat', 'run_timeout.ps1', 'gpu_slots.js', 'job_wrap.bat')"));
assert(/if \(\$args\[4\] -eq 'strict' -and \$stop\.Count\) \{[\s\S]*?exit 14/.test(hc), 'strict hashcheck stops on a watchdog or slot file');
assert(/if \(\$strict -and -not \(Test-Path -LiteralPath \$hashf\)\) \{ Stop-Strict/.test(hc), 'strict stops on a missing manifest');
assert(/leaves out: [\s\S]*?\n    \}\n    if \(\$want\.Count -eq 0\)/.test(hc), 'strict stops on a partial or empty manifest before the empty-file warning');
for (const [name, root] of [['codex_issue.bat', '%ROOT%'], ['work_issue.bat', '%VT%']]) {
  const bat = read(path.join(PC, name)).replace(/\r\n/g, '\n');
  assert(bat.includes(`  %COMMON% hashcheck "%O%" "${root}\\tools_live\\%TLV%\\pc" "${root}\\tools_live\\%TLV%\\hashes.txt" strict\n  if errorlevel 1 exit /b 14`), name + ' stops on a changed tools_live watchdog');
  assert(bat.includes(`if exist "${root}\\tools_live\\" if not defined TLV (`), name + ' stops on a blank tools_live pointer');
}
pass('tool preflight (godot, blender, ffmpeg, node, pil; exit 2) and the strict watchdog hash check in both runners');

const doctor = read(path.join(PC, 'pc_doctor.ps1'));
assert(!/\b(Remove-Item|Move-Item|Rename-Item|Stop-Process|Set-Content|Out-File|Add-Content|Copy-Item|New-Item)\b|::(Delete|Move|Replace|WriteAllText|AppendAllText)\(/.test(doctor), 'the doctor changes nothing');
assert.equal((doctor.match(/WriteAll\w+\(/g) || []).length, 1, 'the doctor writes one report file');
assert(doctor.includes("Join-Path $Root 'pc_doctor.txt'"));
for (const needle of ['watchdog: $(Health $c)', 'GPU child: $(Health $c.child)', 'age $age', 'CORRUPT', 'ORPHANED CHILD', 'STUCK?']) assert(doctor.includes(needle), 'doctor shows ' + needle);
const doctorBat = read(path.join(PC, 'PC_DOCTOR.bat'));
assert(doctorBat.includes('pc_doctor.ps1" -SampleSeconds %SAMPLE%') && doctorBat.includes('if /i "%~1"=="strict" set "SAMPLE=300"'));
pass('PC_DOCTOR.bat is read only and shows owner, child, age and health for every claim');

// ---------------------------------------------------------------- issue 1352: where ffmpeg and Pillow are looked for
// Fake tools: .cmd stubs on Windows, /bin/sh scripts elsewhere, so the same cases run under Windows PowerShell 5.1 and pwsh.
// The caller's runner hides the real PATH (the PC has a real python and ffmpeg), so "nothing found" is honest.
const isWin = process.platform === 'win32';
function lookupCases(run, base, label) {
  const dir = fs.mkdtempSync(path.join(base, 'tools-'));
  const stub = (name, winLines, shLines) => {
    const file = path.join(dir, isWin ? name + '.cmd' : name);
    fs.writeFileSync(file, isWin ? ['@echo off', ...winLines, ''].join('\r\n') : ['#!/bin/sh', ...shLines, ''].join('\n'));
    if (!isWin) fs.chmodSync(file, 0o755);
    return file;
  };
  const ffmpeg = (name, good) => stub(name, good ? ['echo ffmpeg version fake', 'exit /b 0'] : ['exit /b 3'], good ? ['echo "ffmpeg version fake"', 'exit 0'] : ['exit 3']);
  const IMAGEIO = 'import imageio_ffmpeg,sys; print(imageio_ffmpeg.get_ffmpeg_exe())';
  // A fake python: `-c "import PIL"` exits pil (0 or 1); the imageio_ffmpeg line prints the given path, or fails when none.
  const python = (name, answer, pil) => stub(name,
    [`if "%~2"=="import PIL" exit /b ${pil}`, answer ? `if "%~2"=="${IMAGEIO}" echo ${answer}& exit /b 0` : 'rem no imageio_ffmpeg', 'exit /b 1'],
    [`case "$2" in`, '  "import PIL") exit ' + pil + ' ;;', answer ? `  *imageio_ffmpeg*) echo "${answer}"; exit 0 ;;` : '  *imageio_ffmpeg*) exit 1 ;;', 'esac', 'exit 1']);
  const good = ffmpeg('good_ffmpeg', true);
  const bad = ffmpeg('bad_ffmpeg', false);
  const pyGood = python('py_good', good, 0);
  const pyBadFfmpeg = python('py_bad_ffmpeg', bad, 0);
  const pyNoPil = python('py_no_pil', null, 1);
  let n = 0;
  const go = (tools, env) => {
    const out = path.join(dir, 'out' + (++n));
    const r = run([out, tools], env);
    const txt = fs.existsSync(path.join(out, 'preflight.txt')) ? read(path.join(out, 'preflight.txt')) : '';
    const cmd = fs.existsSync(path.join(out, 'tools.cmd')) ? read(path.join(out, 'tools.cmd')) : '';
    return { code: r.status, txt, cmd, all: label + ' ' + r.stdout + r.stderr + txt };
  };
  // a fake python whose imageio_ffmpeg answer points at a fake ffmpeg is found and named
  let r = go('ffmpeg pil', { PIL_PYTHON: pyGood });
  assert.equal(r.code, 0, r.all);
  assert(r.txt.includes(`found ffmpeg: ${good} (imageio_ffmpeg via ${pyGood})`), r.all);
  assert(r.txt.includes(`found pil: ${pyGood} (PIL_PYTHON)`), r.all);
  assert(r.cmd.includes(`set "JW_FFMPEG=${good}"`) && r.cmd.includes(`set "JW_PIL=${pyGood}"`), r.all);
  // FFMPEG_EXE still wins first
  r = go('ffmpeg', { FFMPEG_EXE: good, PIL_PYTHON: pyGood });
  assert.equal(r.code, 0, r.all);
  assert(r.txt.includes(`found ffmpeg: ${good} (FFMPEG_EXE)`), r.all);
  // a fake ffmpeg whose -version fails is skipped, and the next source is used
  r = go('ffmpeg', { FFMPEG_EXE: bad, PIL_PYTHON: pyGood });
  assert.equal(r.code, 0, r.all);
  assert(r.txt.includes(`skipped ffmpeg: ${bad}`) && r.txt.includes(`found ffmpeg: ${good} (imageio_ffmpeg via ${pyGood})`), r.all);
  // a Python that names a broken ffmpeg gives nothing: skipped, then MISSING with exit 2
  r = go('ffmpeg', { PIL_PYTHON: pyBadFfmpeg });
  assert.equal(r.code, 2, r.all);
  assert(r.txt.includes(`skipped ffmpeg: ${bad}`) && r.txt.includes('MISSING ffmpeg: set FFMPEG_EXE or install it'), r.all);
  // a Python without Pillow does not count for pil
  r = go('pil', { PIL_PYTHON: pyNoPil });
  assert.equal(r.code, 2, r.all);
  assert(r.txt.includes('MISSING pil: set PIL_PYTHON or install it') && !r.txt.includes('found pil'), r.all);
  // nothing found: the old lines, exit 2
  r = go('ffmpeg pil', {});
  assert.equal(r.code, 2, r.all);
  assert(r.txt.includes('MISSING ffmpeg: set FFMPEG_EXE or install it') && r.txt.includes('MISSING pil: set PIL_PYTHON or install it'), r.all);
  assert(r.txt.includes('STOPPED: missing tools: ffmpeg, pil'), r.all);
  pass(`${label}: preflight finds ffmpeg through a Python's imageio_ffmpeg and names the source, skips an ffmpeg whose -version fails, still says MISSING (exit 2)`);
}
// ---------------------------------------------------------------- PowerShell 7 (GitHub's Linux runners have pwsh)
const hasPwsh = process.platform !== 'win32' && !spawnSync('pwsh', ['-v'], { encoding: 'utf8' }).error;
if (hasPwsh) {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'pc1194-pwsh-'));
  const parse = spawnSync('pwsh', ['-NoProfile', '-Command', `$bad = 0; foreach ($f in $env:PARSE_FILES.Split([char]124)) { $e = $null; $null = [System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$null, [ref]$e); foreach ($x in $e) { Write-Output "$f $($x.Extent.StartLineNumber): $($x.Message)"; $bad++ } }; exit $bad`,
    ], { encoding: 'utf8', env: { ...process.env, PARSE_FILES: ['lane_tools_refresh.ps1', 'pc_doctor.ps1', 'runner_common.ps1', 'run_timeout.ps1'].map(n => path.join(PC, n)).join('|') } });
  assert.equal(parse.status, 0, parse.stdout + parse.stderr);
  const ps = (args, env = {}) => spawnSync('pwsh', ['-NoProfile', '-File', ...args], { encoding: 'utf8', env: { ...process.env, USERPROFILE: temp, ...env } });
  const out = path.join(temp, 'out');
  const fakeGodot = path.join(temp, 'godot');
  fs.writeFileSync(fakeGodot, 'fake');
  let r = ps([path.join(PC, 'runner_common.ps1'), 'preflight-tools', out, 'godot'], { GODOT_EXE: fakeGodot });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert(read(path.join(out, 'tools.cmd')).includes(`set "JW_GODOT=${fakeGodot}"`));
  r = ps([path.join(PC, 'runner_common.ps1'), 'preflight-tools', out, 'godot blender'], { GODOT_EXE: fakeGodot, BLENDER_EXE: path.join(temp, 'none') });
  assert.equal(r.status, 2, r.stdout + r.stderr);
  assert(read(path.join(out, 'preflight.txt')).includes('MISSING blender: set BLENDER_EXE or install it'));
  r = ps([path.join(PC, 'runner_common.ps1'), 'preflight-tools', out, 'paint']);
  assert.equal(r.status, 2, 'an unknown tool name fails');
  const hashOut = path.join(temp, 'hash');
  fs.mkdirSync(hashOut);
  const good = path.join(temp, 'good.txt');
  const sum = n => crypto.createHash('sha256').update(fs.readFileSync(path.join(PC, n))).digest('hex');
  fs.writeFileSync(good, ['tmo.bat', 'run_timeout.ps1', 'gpu_slots.js', 'job_wrap.bat'].map(n => sum(n) + '  ' + n).join('\n') + '\n');
  r = ps([path.join(PC, 'runner_common.ps1'), 'hashcheck', hashOut, PC, good, 'strict']);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  const bad = path.join(temp, 'bad.txt');
  // every guarded file listed (a partial manifest stops earlier), run_timeout.ps1 with a wrong hash
  fs.writeFileSync(bad, ['tmo.bat', 'gpu_slots.js', 'job_wrap.bat'].map(n => sum(n) + '  ' + n).join('\n') + '\n' + '0'.repeat(64) + '  run_timeout.ps1\n' + '0'.repeat(64) + '  runner_common.ps1\n');
  r = ps([path.join(PC, 'runner_common.ps1'), 'hashcheck', hashOut, PC, bad, 'strict']);
  assert.equal(r.status, 14, r.stdout + r.stderr);
  assert(read(path.join(hashOut, 'result.txt')).includes('STOPPED: the watchdog or slot files differ from ' + bad + ': run_timeout.ps1'), read(path.join(hashOut, 'result.txt')));
  r = ps([path.join(PC, 'runner_common.ps1'), 'hashcheck', hashOut, PC, bad]);
  assert.equal(r.status, 0, 'without strict a difference only warns');
  r = ps([path.join(PC, 'runner_common.ps1'), 'hashcheck', hashOut, PC, path.join(temp, 'none.txt'), 'strict']);
  assert.equal(r.status, 14, 'strict: a missing manifest stops');
  const partial = path.join(temp, 'partial.txt');
  fs.writeFileSync(partial, sum('tmo.bat') + '  tmo.bat\n');
  r = ps([path.join(PC, 'runner_common.ps1'), 'hashcheck', hashOut, PC, partial, 'strict']);
  assert.equal(r.status, 14, 'strict: a partial manifest stops');
  assert(read(path.join(hashOut, 'result.txt')).includes('leaves out: run_timeout.ps1, gpu_slots.js, job_wrap.bat'), read(path.join(hashOut, 'result.txt')));
  const empty = path.join(temp, 'empty.txt');
  fs.writeFileSync(empty, '');
  r = ps([path.join(PC, 'runner_common.ps1'), 'hashcheck', hashOut, PC, empty, 'strict']);
  assert.equal(r.status, 14, 'strict: an empty manifest stops');
  const vt = path.join(temp, 'vt');
  fs.mkdirSync(vt);
  fs.writeFileSync(path.join(vt, 'gpu_slot_1'), JSON.stringify({ token: 't', issue: 'issue-1194 pwsh', pid: 999999, mode: 'shared', weight: 2,
    started: new Date(Date.now() - 7200000).toISOString(), startTime: '1', exe: 'pwsh' }) + '\n');
  fs.writeFileSync(path.join(vt, 'gpu_slot_2'), 'not json');
  r = ps([path.join(PC, 'pc_doctor.ps1'), '-SampleSeconds', '1', '-Root', vt]);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert(/gpu_slot_1: issue-1194 pwsh, shared weight 2, age 2\.0 h/.test(r.stdout) && /watchdog: PID 999999 GONE/.test(r.stdout), r.stdout);
  assert(/gpu_slot_2: CORRUPT/.test(r.stdout) && read(path.join(vt, 'gpu_slot_2')) === 'not json', r.stdout);
  {
    // pwsh found by absolute path through a PATH that holds only a link to it, so no host python or ffmpeg is seen
    const which = spawnSync('sh', ['-c', 'command -v pwsh'], { encoding: 'utf8' });
    const bin = path.join(temp, 'isolated_bin');
    fs.mkdirSync(bin);
    fs.symlinkSync(fs.realpathSync(which.stdout.trim()), path.join(bin, 'pwsh'));
    lookupCases((tail, extra) => spawnSync(path.join(bin, 'pwsh'), ['-NoProfile', '-File', path.join(PC, 'runner_common.ps1'), 'preflight-tools', ...tail],
      { encoding: 'utf8', env: { ...process.env, USERPROFILE: temp, PATH: bin, FFMPEG_EXE: '', PIL_PYTHON: '', ...extra } }), temp, 'pwsh');
  }
  pass('pwsh: the scripts parse, the preflight finds and misses tools (exit 2), strict hashcheck stops (exit 14), the doctor reads claims');
} else if (process.platform !== 'win32') console.log('SKIP pwsh runs: no PowerShell 7 on this machine');

// ---------------------------------------------------------------- Windows: the real thing against fake tools
if (process.platform !== 'win32') {
  console.log('SKIP Windows job_wrap, preflight, hand-off and doctor runs (they run in the standing checks on the PC)');
  console.log(`PASS PC jobs 1194 checks (${groups} groups)`);
  process.exit(0);
}

const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'pc1194 '));
console.log('Evidence: ' + temp);
const put = (p, text) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, text); };
const crlf = s => s.replace(/\r?\n/g, '\r\n');
const sha = p => crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const profile = path.join(temp, 'profile');
const vt = path.join(profile, 'Downloads', 'voidsworn_test');
fs.mkdirSync(vt, { recursive: true });
const tools = path.join(temp, 'fake tools', 'pc');
// The fake watchdog runs the step's command directly: tmo.bat <seconds> <exe> [args ...].
put(path.join(tools, 'tmo.bat'), crlf('@echo off\ncall %2 %3 %4 %5 %6\nexit /b %ERRORLEVEL%\n'));
fs.copyFileSync(path.join(PC, 'runner_common.ps1'), path.join(tools, 'runner_common.ps1'));
const hashes = path.join(temp, 'fake tools', 'hashes.txt');
put(path.join(tools, 'run_timeout.ps1'), 'exit 0\n');
put(path.join(tools, 'gpu_slots.js'), '// fake\n');
put(hashes, ['tmo.bat', 'run_timeout.ps1', 'gpu_slots.js'].map(n => sha(path.join(tools, n)) + '  ' + n).join('\n') + '\n');
const step = path.join(temp, 'step.bat');
put(step, crlf('@echo off\nif not "%~2"=="" if "%~3"=="empty" type nul > "%~2"\nif not "%~2"=="" if not "%~3"=="empty" echo made> "%~2"\nexit /b %~1\n'));
const godot = path.join(temp, 'godot.exe');
put(godot, 'fake');
const env = extra => ({ ...process.env, USERPROFILE: profile, JW_TOOLS: tools, JW_HASHES: hashes, JW_NO_REFRESH: '1', PC_GPU_ISSUE: '',
  GODOT_EXE: godot, JW: path.join(PC, 'job_wrap.bat'), STEP: step, ...extra });
function job(name, body, extra = {}) {
  const out = path.join(temp, name);
  const bat = path.join(temp, name + '.bat');
  put(bat, crlf('@echo off\nsetlocal\n' + body + '\n'));
  const r = spawnSync(process.env.ComSpec || 'cmd.exe', ['/d', '/c', bat], { env: env({ OUT: out, ...extra }), encoding: 'utf8', windowsHide: true, timeout: 120000 });
  const st = fs.existsSync(path.join(out, 'status.txt')) ? read(path.join(out, 'status.txt')) : '';
  const done = fs.existsSync(path.join(out, 'done.txt')) ? read(path.join(out, 'done.txt')).trim() : '';
  return { code: r.status, text: (r.stdout || '') + (r.stderr || ''), st, done, out };
}

{
  // Windows PowerShell 5.1 by absolute path, with a PATH that holds nothing (no real python, py or ffmpeg is seen)
  const psExe = path.join(process.env.SystemRoot || 'C:\Windows', 'System32', 'WindowsPowerShell', 'v1.0', 'powershell.exe');
  const isolated = fs.mkdtempSync(path.join(fs.realpathSync.native(os.tmpdir()), 'pc1352-'));
  const emptyBin = path.join(isolated, 'empty_bin');
  fs.mkdirSync(emptyBin);
  lookupCases((tail, extra) => spawnSync(psExe, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(PC, 'runner_common.ps1'), 'preflight-tools', ...tail],
    { encoding: 'utf8', windowsHide: true, timeout: 240000, env: { ...process.env, USERPROFILE: path.join(isolated, 'profile'), PATH: emptyBin, FFMPEG_EXE: '', PIL_PYTHON: '', ...extra } }), isolated, 'Windows PowerShell 5.1');
}

const mixed = job('mixed', [
  'call "%JW%" init "%OUT%" "test1194" "godot"',
  'if errorlevel 1 exit /b %ERRORLEVEL%',
  'if not defined JW_GODOT (echo no godot path & exit /b 9)',
  'set "JW_STEP=one" & set "JW_EXPECT=%OUT%\\a.txt" & call "%JW%" run 10 "%STEP%" 0 "%OUT%\\a.txt"',
  'set "JW_STEP=two" & set "JW_OPTIONAL=1" & call "%JW%" run 10 "%STEP%" 5',
  'if defined JW_OPTIONAL (echo leak & exit /b 9)',
  'set "JW_STEP=three" & set "JW_CONTINUE=1" & call "%JW%" run 10 "%STEP%" 4',
  'set "JW_STEP=four" & set "JW_EXPECT=%OUT%\\empty.txt" & call "%JW%" run 10 "%STEP%" 0 "%OUT%\\empty.txt" empty',
  'set "JW_STEP=five" & call "%JW%" run 10 "%STEP%" 0 "%OUT%\\five.txt"',
  'call "%JW%" end',
  'exit /b %ERRORLEVEL%'].join('\n'));
assert.equal(mixed.code, 1, mixed.text + mixed.st);
assert.equal(mixed.done, 'FAILED: three, four', mixed.st);
assert(/step one ok/.test(mixed.st) && /optional step two failed; the job goes on/.test(mixed.st), mixed.st);
assert(/empty or missing output .*empty\.txt/.test(mixed.st) && /skipped five: an earlier step failed/.test(mixed.st), mixed.st);
assert(!fs.existsSync(path.join(mixed.out, 'five.txt')), 'a skipped step never runs');
assert(/done FAILED: three, four\r?\nall done/.test(mixed.st), mixed.st);
pass('Windows: a required failure stops later steps, continue and optional behave, empty outputs fail, exit 1');

put(path.join(temp, 'clean', 'done.txt'), 'old');
const clean = job('clean', ['call "%JW%" init "%OUT%" "test1194" ""', 'if errorlevel 1 exit /b %ERRORLEVEL%',
  'set "JW_STEP=one" & call "%JW%" run 10 "%STEP%" 0', 'call "%JW%" end', 'exit /b %ERRORLEVEL%'].join('\n'));
assert.equal(clean.code, 0, clean.text + clean.st);
assert.equal(clean.done, 'PASS');
assert.equal(read(path.join(clean.out, 'done_previous.txt')), 'old', 'the older done.txt is kept');
assert(/done PASS\r?\nall done/.test(clean.st));
const nolabel = job('nolabel', ['call "%JW%" init "%OUT%" "" ""', 'exit /b %ERRORLEVEL%'].join('\n'));
assert.equal(nolabel.code, 1, nolabel.text + nolabel.st);
assert.equal(nolabel.done, 'FAILED: GPU label');
pass('Windows: a clean job ends PASS with exit 0; a job without a GPU label stops at init');

const missing = job('missing', ['call "%JW%" init "%OUT%" "test1194" "godot blender"', 'if errorlevel 1 exit /b %ERRORLEVEL%',
  'set "JW_STEP=clone" & call "%JW%" run 10 "%STEP%" 0 "%OUT%\\cloned.txt"', 'call "%JW%" end'].join('\n'), { BLENDER_EXE: path.join(temp, 'no_blender.exe') });
assert.equal(missing.code, 2, missing.text + missing.st);
assert.equal(missing.done, 'FAILED: preflight: missing tool');
assert(read(path.join(missing.out, 'preflight.txt')).includes('MISSING blender'));
assert(!fs.existsSync(path.join(missing.out, 'cloned.txt')), 'nothing runs after a failed preflight');
pass('Windows: a missing tool stops the job with exit 2 before its first step');

const partialHashes = path.join(temp, 'fake tools', 'partial.txt');
put(partialHashes, sha(path.join(tools, 'tmo.bat')) + '  tmo.bat\n');
const partialRun = job('partial', ['call "%JW%" init "%OUT%" "test1194" ""', 'exit /b %ERRORLEVEL%'].join('\n'), { JW_HASHES: partialHashes });
assert.equal(partialRun.code, 1, partialRun.text + partialRun.st);
assert.equal(partialRun.done, 'FAILED: tools hashcheck');
assert(partialRun.st.includes('leaves out: run_timeout.ps1, gpu_slots.js'), partialRun.st);
// The look bench shape: init, then one marked call around every step; a failed bench inside it ends FAILED, exit 1.
const bench = job('bench', [
  'call "%JW%" init "%OUT%" "test1194" "godot"',
  'if errorlevel 1 exit /b %ERRORLEVEL%',
  'call :run_tools 9>"%OUT%\\.run-active"',
  'exit /b %ERRORLEVEL%',
  ':run_tools',
  'set "JW_STEP=checkout" & call "%JW%" run 10 "%STEP%" 0',
  'if errorlevel 1 goto finish',
  'call :bench',
  'if errorlevel 1 goto finish',
  'echo not reached> "%OUT%\\after_bench.txt"',
  ':finish',
  'del "%OUT%\\.run-active" > nul 2>&1',
  'if exist "%OUT%\\.run-active" echo held> "%OUT%\\held_at_end.txt"',
  'call "%JW%" end',
  'exit /b %ERRORLEVEL%',
  ':bench',
  'del "%OUT%\\.run-active" > nul 2>&1',
  'if exist "%OUT%\\.run-active" echo held> "%OUT%\\held_in_bench.txt"',
  'set "JW_STEP=capture" & set "JW_CONTINUE=1" & call "%JW%" run 10 "%STEP%" 3',
  'call "%JW%" fail "bench abc did not finish"',
  'exit /b 1'].join('\n'));
assert.equal(bench.code, 1, bench.text + bench.st);
assert(/^FAILED: .*bench abc did not finish/.test(bench.done), bench.done);
assert(fs.existsSync(path.join(bench.out, 'held_in_bench.txt')), 'the marker is held during the bench');
assert(fs.existsSync(path.join(bench.out, 'held_at_end.txt')), 'the marker is still held when job_wrap end runs');
assert(!fs.existsSync(path.join(bench.out, 'after_bench.txt')), 'nothing runs after a failed bench');
fs.unlinkSync(path.join(bench.out, '.run-active'));
pass('Windows: the look bench marker stays held through end, and a failed bench exits 1 (the watcher files it under failed)');

fs.appendFileSync(path.join(tools, 'tmo.bat'), 'rem changed\r\n');
const tampered = job('tampered', ['call "%JW%" init "%OUT%" "test1194" ""', 'exit /b %ERRORLEVEL%'].join('\n'));
assert.equal(tampered.code, 1, tampered.text + tampered.st);
assert.equal(tampered.done, 'FAILED: tools hashcheck');
assert(tampered.st.includes('STOPPED: the watchdog or slot files differ'), tampered.st);
pass('Windows: a changed watchdog file stops the job before any step');

// tmo.bat hands a step to tools_live\<version>\pc\run_timeout.ps1 unless the caller is a test.
const version = 'abcdef123456';
put(path.join(vt, 'tools_live', 'current.txt'), version + '\r\n');
const marker = path.join(temp, 'handoff.txt');
put(path.join(vt, 'tools_live', version, 'pc', 'run_timeout.ps1'), `Set-Content -LiteralPath '${marker}' -Value $env:TMO_ARGS\nexit 7\n`);
const handoff = spawnSync(process.env.ComSpec || 'cmd.exe', ['/d', '/c', 'call', path.join(PC, 'tmo.bat'), '5', 'fake.exe', '--x'],
  { env: { ...process.env, USERPROFILE: profile, TMO_OWN_COPY: '', PC_RUNNER_TEST: '' }, encoding: 'utf8', windowsHide: true, timeout: 60000 });
assert.equal(handoff.status, 7, handoff.stdout + handoff.stderr);
assert(read(marker).includes('5 fake.exe --x'), 'the arguments reach the canonical watchdog');
// Fail closed: a copy of tmo.bat with its own (marker) watchdog must never run it once tools_live exists.
const local = path.join(temp, 'local pc');
fs.mkdirSync(local, { recursive: true });
fs.copyFileSync(path.join(PC, 'tmo.bat'), path.join(local, 'tmo.bat'));
const localMarker = path.join(temp, 'local.txt');
put(path.join(local, 'run_timeout.ps1'), `Set-Content -LiteralPath '${localMarker}' -Value ran\nexit 0\n`);
const runLocal = () => spawnSync(process.env.ComSpec || 'cmd.exe', ['/d', '/c', 'call', path.join(local, 'tmo.bat'), '5', 'fake.exe'],
  { env: { ...process.env, USERPROFILE: profile, TMO_OWN_COPY: '', PC_RUNNER_TEST: '' }, encoding: 'utf8', windowsHide: true, timeout: 60000 });
put(path.join(vt, 'tools_live', 'current.txt'), '');
let broken = runLocal();
assert.equal(broken.status, 125, broken.stdout + broken.stderr);
put(path.join(vt, 'tools_live', 'current.txt'), 'fedcba654321\r\n');
broken = runLocal();
assert.equal(broken.status, 125, broken.stdout + broken.stderr);
assert(!fs.existsSync(localMarker), 'the local watchdog never ran');
put(path.join(vt, 'tools_live', 'current.txt'), version + '\r\n');
pass('Windows: a checkout tmo.bat hands its step to tools_live, and a blank pointer or missing target stops it (exit 125)');

// The doctor reads fake claims and changes none of them.
const live = { token: 't1', issue: 'issue-1194 test', pid: process.pid, mode: 'shared', weight: 1, started: new Date(Date.now() - 600000).toISOString(),
  startTime: '1', exe: 'node', child: { pid: 999999, startTime: '2', exe: 'godot_v4.7.2-stable_win64_console' } };
put(path.join(vt, 'gpu_slot_1'), JSON.stringify(live) + '\n');
put(path.join(vt, 'gpu_slot_2'), '{broken');
put(path.join(vt, 'gpu_solo'), '');
put(path.join(vt, 'gpu_go.txt'), 'GPU cleared');
const before = fs.readdirSync(vt).map(n => [n, fs.statSync(path.join(vt, n)).isFile() ? sha(path.join(vt, n)) : 'dir']);
const doc = spawnSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(PC, 'pc_doctor.ps1'), '-SampleSeconds', '1', '-Root', vt],
  { encoding: 'utf8', windowsHide: true, timeout: 120000 });
assert.equal(doc.status, 0, doc.stdout + doc.stderr);
assert(/gpu_slot_1: issue-1194 test, shared weight 1, age 10 min/.test(doc.stdout), doc.stdout);
assert(/watchdog: PID \d+ REUSED by node/.test(doc.stdout) && /GPU child: PID 999999 GONE/.test(doc.stdout), doc.stdout);
assert(/gpu_slot_2: CORRUPT/.test(doc.stdout) && /gpu_solo: free/.test(doc.stdout) && /Claims held: 1/.test(doc.stdout), doc.stdout);
const after = fs.readdirSync(vt).filter(n => n !== 'pc_doctor.txt').map(n => [n, fs.statSync(path.join(vt, n)).isFile() ? sha(path.join(vt, n)) : 'dir']);
assert.deepEqual(after, before, 'the doctor changed nothing but its report');
assert(fs.existsSync(path.join(vt, 'pc_doctor.txt')));
pass('Windows: the doctor shows owner, age and health, flags a damaged slot and changes nothing');

console.log(`PASS PC jobs 1194 checks (${groups} groups)`);
