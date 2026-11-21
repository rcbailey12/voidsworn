'use strict';
// Issues 1174 and 1185: static checks of the shared ship job, the look bench and the helper wrappers.
// Runs on any host (no cmd needed). What it holds:
//   the guard: after every step that can fail, "if defined FAILED goto collect" comes before the next command, so a failed
//     stage, install or check never reaches the shots; the shots line sits right behind that guard;
//   all three installed-glb checks (readback, interiors, death seam) count toward the guard (S10_RUN_1157.bat let a failed
//     death seam through to the shots);
//   the GPU wait default (3600, the gpu_slots.js MAX_WAIT_SECONDS that every ship checkout's helper accepts) is set before any GPU step;
//   the last line: every way out of the main job writes "done PASS" or "done FAILED: ..." and then "all done";
//   both jobs refresh and clone from the local mirror under the runner's lock;
//   the ship job collects only deliverables, and nothing when no recipe stage ran (1516); it lists backups older than the newest two for the janitor;
//   no delete or move commands, and output only under the job folder and the helper's own TEMP;
//   every wrapper in docs/ship_pipeline/ship_job/wrappers/ is three lines that set the inputs and call ship_job.bat.
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const ROOT = path.resolve(__dirname, '../../..');
const JOB = path.join(ROOT, 'tools/pc/jobs/ship_job.bat');
const LOOK = path.join(ROOT, 'tools/pc/jobs/look_bench.bat');
const WRAPPERS = path.join(ROOT, 'docs/ship_pipeline/ship_job/wrappers');
let passed = 0;
const pass = s => { passed++; console.log('PASS ' + s); };

const text = fs.readFileSync(JOB, 'utf8');
const lines = text.split(/\r?\n/);
const code = lines.map((l, i) => ({ n: i + 1, s: l.trim() })).filter(l => l.s && !/^rem\b/i.test(l.s));
const at = re => code.findIndex(l => re.test(l.s));
const main = code.slice(0, at(/^:collect$/));
const isCommand = s => /(tmo\.bat|^git |^cmd \/c|^powershell |^call |^xcopy |^copy )/i.test(s);
const guard = /^if defined FAILED goto collect$/i;
const mayFail = s => /set "?(FAILED|CHECKFAIL)=/i.test(s) && !/^set (FAILED|CHECKFAIL)=$/i.test(s);

// the guard
const shots = main.filter(l => /a4_shots\.tscn/.test(l.s));
assert.equal(shots.length, 1, 'exactly one shots command in the main job');
const before = main[main.indexOf(shots[0]) - 1];
assert(guard.test(before.s), `line ${before.n} before the shots must be the FAILED guard, is: ${before.s}`);
// Issue 1180: the private TEMP setup runs before :run_tools and may fail on its own; the build steps start inside :run_tools.
const runTools = main.findIndex(l => l.s === ':run_tools');
const firstFail = main.findIndex((l, i) => i > runTools && mayFail(l.s));
assert(firstFail > 0, 'the job sets FAILED somewhere');
for (let i = firstFail; i < main.indexOf(shots[0]); i++) {
  if (!mayFail(main[i].s)) continue;
  let j = i + 1;
  while (j < main.length && !guard.test(main[j].s) && !isCommand(main[j].s)) j++;
  // a CHECKFAIL line may be followed by the next check: the checks all run, then CHECKFAIL turns into FAILED before the guard
  if (/CHECKFAIL=/.test(main[i].s) && isCommand(main[j].s) && /installed_ship_check|authored_interiors|death_seam/.test(main[j].s)) continue;
  if (/^if defined FAILED git -C .* merge --abort/.test(main[j].s)) j++;
  assert(j < main.length && guard.test(main[j].s), `line ${main[i].n} can fail, but line ${main[j] && main[j].n} runs before the guard`);
}
for (const check of ['installed_ship_check.gd', 'authored_interiors_check.gd', 'death_seam_check.gd']) {
  const k = main.findIndex(l => l.s.includes(check));
  assert(k > 0, check + ' runs');
  const tail = main.slice(k + 1, k + 5).map(l => l.s).join('\n');
  assert(/set EL=%ERRORLEVEL%/.test(tail) && /if not "%EL%"=="0" set "CHECKFAIL=/.test(tail), check + ' counts toward CHECKFAIL');
  assert(k < main.indexOf(shots[0]), check + ' runs before the shots');
}
assert(main.some(l => /^if defined CHECKFAIL set "FAILED=/.test(l.s)), 'CHECKFAIL becomes FAILED before the shots');
const fresh = main.findIndex(l => /LastWriteTimeUtc\.Ticks -lt \[long\]\$env:START_TICKS/.test(l.s));
assert(fresh > 0 && fresh < main.findIndex(l => l.s.includes('installed_ship_check.gd')), 'the installed glb must be this run\'s before any check');
assert(/for %%S in \(%STAGES%\) do call :stage %%S/.test(text), 'the stages loop runs STAGES in order');
const stage = text.slice(text.indexOf(':stage'));
assert(/if defined FAILED \(\s*\r?\n\s*echo %1 SKIPPED/.test(stage), 'a failed stage skips the later stages');
const co = main.findIndex(l => /checkout -q --no-overwrite-ignore -B shipjob FETCH_HEAD/.test(l.s));
assert(!/checkout[^\r\n]* -f\b|checkout[^\r\n]*--force/.test(text), 'never a forced checkout: it would replace untracked or ignored local files');
assert(main.some(l => /merge -q --no-edit --no-overwrite-ignore refs\/ship-job\/paint-base/.test(l.s)), 'the PAINT_BASE merge refuses to overwrite ignored files too');
assert(main.slice(0, co).some(l => /^git -C "%C%" checkout -q HEAD -- godot\/assets\/ships /.test(l.s)), 'only the install folder is restored');
const pre = main.slice(0, co).map(l => l.s);
assert(co > 0 && pre.some(s => /status --porcelain/.test(s)) && pre.some(s => /diff --binary HEAD > "%O%\\clone_changes_before_checkout\.patch"/.test(s)),
  'every tracked change in the clone is listed and saved before the checkout');
const unexpected = pre.findIndex(s => /status --porcelain --untracked-files=no -- \. ":\(exclude\)godot\/assets\/ships" ":\(glob,exclude\)godot\/\*\*\/\*\.import" "%TMO_EXCL%" > "%O%\\clone_changes_unexpected\.txt"/.test(s));
assert(unexpected > 0 && /set "FAILED=checkout: git status/.test(pre[unexpected + 1]) && guard.test(pre[unexpected + 2])
  && /set "FAILED=checkout: the clone has local changes outside/.test(pre[unexpected + 3]) && guard.test(pre[unexpected + 4]),
  'a change outside godot/assets/ships and the rewritten *.import files stops the job before the checkout (git filters, not findstr: PR 1190)');
assert(!pre.some(s => /findstr/.test(s)), 'no findstr filter on the git status list (its $ needs a CR)');
assert(main.slice(0, co).some(l => /^git -C "%C%" checkout -q HEAD -- ":\(glob\)godot\/\*\*\/\*\.import" /.test(l.s)), 'the rewritten *.import files are restored after the patch is saved');
// Issue 1194 (Artoo on PR 1254): a pinned commit's recipe stages call the clone's own tmo.bat, so the job copies the
// tools_live tmo.bat over it after the checkout, and restores the committed file before the next checkout.
assert(main.slice(0, co).some(l => l.s === 'if defined TMO_GEN git -C "%C%" checkout -q HEAD -- tools/pc/tmo.bat >> "%RES%" 2>&1'), 'the hand-off copy is restored before the checkout, only when it is the recorded copy');
// Artoo on PR 1254 (760e4bad): a staged edit with the worktree equal to HEAD is not in the patch, and the restores erased it.
const staged = pre.findIndex(s => s === 'git -C "%C%" diff --cached --quiet HEAD >> "%O%\\log_clone_status.txt" 2>&1');
const firstReset = pre.findIndex(s => /checkout -q HEAD -- /.test(s));
assert(staged > 0 && staged < firstReset && /set "FAILED=checkout: the clone has staged changes/.test(pre[staged + 1]) && guard.test(pre[staged + 2]),
  'a staged change stops the job before any reset');
const gen = pre.findIndex(s => s === 'if defined TMO_LEFT if defined TMO_REC if /i "%TMO_LEFT%"=="%TMO_REC%" set "TMO_GEN=1"');
const excl = pre.findIndex(s => s === 'if defined TMO_GEN set "TMO_EXCL=:(exclude)tools/pc/tmo.bat"');
assert(gen > 0 && excl > gen && excl < unexpected && pre[excl - 1] === 'set "TMO_EXCL=:(exclude)godot/assets/ships"', 'tmo.bat leaves the unexpected list only when it is the recorded hand-off copy');
const record = main.findIndex(l => l.s === 'if defined TMO_OK git -C "%C%" hash-object -- tools/pc/tmo.bat > "%C%\\.git\\ship_job_tmo_handoff.txt" 2>> "%RES%"');
assert(record > main.findIndex(l => l.s === 'if defined TMO_OK copy /y "%TMO%" "%C%\\tools\\pc\\tmo.bat" > nul'), 'the hand-off copy hash is recorded after the copy');
assert(text.includes("for /f %%H in ('git -C \"%C%\" hash-object -- tools/pc/tmo.bat 2^>nul') do set \"TMO_LEFT=%%H\""), 'the left-over tmo.bat is hashed the same way');
const based = main.findIndex(l => l.s === ':based');
const overlay = main.findIndex(l => l.s === 'if defined TMO_OK copy /y "%TMO%" "%C%\\tools\\pc\\tmo.bat" > nul');
const stagesAt = main.findIndex(l => /cmd \/c ""%~f0" ship"/.test(l.s));
assert(based > 0 && overlay > based && overlay < stagesAt, 'the clone tmo.bat hands off to tools_live before any stage runs');
pass('the guard: a failed fetch, merge, import, stage, install or check never reaches the shots; all three checks count');

// the wait default
const wait = code.findIndex(l => /^if not defined PC_GPU_WAIT_SECONDS set PC_GPU_WAIT_SECONDS=3600$/.test(l.s));
assert(wait > 0, 'PC_GPU_WAIT_SECONDS defaults to 3600');
assert(wait < code.findIndex(l => /tmo\.bat/.test(l.s)), 'the wait default is set before the first GPU step');
const { MAX_WAIT_SECONDS } = require(path.join(ROOT, 'tools/pc/gpu_slots.js'));
assert.equal(MAX_WAIT_SECONDS, 3600, 'the default is the most gpu_slots.js accepts');
pass('the GPU wait: 3600 s by default for every GPU step, accepted by gpu_slots.js');

// the last line
const finish = code.findIndex(l => l.s === ':finish');
const tailLines = code.slice(finish).map(l => l.s);
assert.deepEqual(tailLines.slice(1, 8), ['if defined FAILED goto finish_failed', 'echo done PASS %DATE% %TIME% >> "%RES%"',
  'echo all done >> "%RES%"', 'exit /b 0', ':finish_failed', 'echo done FAILED: %FAILED% %DATE% %TIME% >> "%RES%"',
  'echo all done >> "%RES%"']);
const start = code.findIndex(l => /^echo start /.test(l.s));
const subs = code.findIndex(l => l.s === ':ship');
assert(/call "%J%\\ship_job_running\.bat"\s+if errorlevel 1 [^\n]*exit \/b 1\s+[^\n]*exit \/b 0/.test(text),
  'the launcher returns a failed result from its private script');
// Nov 19 chain 1119B: the launcher clears the wrapper's inputs in the caller, so a chain's next ship never inherits STAGES
for (const v of ['SHIP', 'CODE', 'BRANCH', 'JOB_DIR', 'STAGES', 'SETS', 'FACS', 'PAINT_BASE', 'PC_GPU_ISSUE']) {
  assert(new RegExp(`if errorlevel 1 endlocal & .*set "${v}=" .*& exit \\/b 1`).test(text), `the failed exit does not clear ${v} in the caller`);
  assert(new RegExp(`\\n\\s*endlocal & .*set "${v}=" .*& exit \\/b 0`).test(text), `the passed exit does not clear ${v} in the caller`);
}
for (let i = start; i < subs; i++) {
  if (/exit \/b/i.test(code[i].s)) assert(i > finish, `line ${code[i].n} leaves the job before the done and all done lines`);
}
for (const l of code.slice(start, finish)) {
  if (/goto (\w+)/i.test(l.s)) assert(['collect', 'collect_skipped', 'finish', 'based'].includes(/goto (\w+)/i.exec(l.s)[1]), `line ${l.n}: ${l.s}`);
}
pass('the last line: every way out of the job writes done PASS or done FAILED, then all done');

// no deletes, output only in the job folder
for (const l of code) {
  assert(!/^(del|erase|rd|rmdir|move)\b|\b(del|rmdir|rd) \/[sq]|\b(Remove-Item|Move-Item)\b/i.test(l.s),
    `line ${l.n} deletes or moves: ${l.s}`);
  assert(!/^robocopy .*\/(MIR|PURGE|MOV|MOVE)\b/i.test(l.s), `line ${l.n} deletes or moves: ${l.s}`);
  for (const m of l.s.matchAll(/(?<!\^)>>?\s*("[^"]*"|\S+)/g)) {
    const target = m[1].replace(/"/g, '');
    if (target === 'nul' || target === '&1') continue;
    if (l.s.startsWith('call :run_tools 9>') && target === '%TEMP%\\.voidsworn-run-active') continue;
    // 1194: the hash of the clone's tmo.bat hand-off copy lives in the job's own clone metadata
    if (target === '%C%\\.git\\ship_job_tmo_handoff.txt') continue;
    assert(/^%(O|RES)%/.test(target), `line ${l.n} writes outside the job's out folder: ${target}`);
  }
}
pass('no deletes or moves; logs only under out');

// Both standalone launchers serialize the refresh, hardlink clone and branch fetch with runner_common.ps1.
const look = fs.readFileSync(LOOK, 'utf8');
for (const [name, script, root] of [['ship job', text, '%V%'], ['look bench', look, '%VT%']]) {
  assert(script.includes(`set "MIRROR=${root}\\repo-mirror.git"`), `${name} uses the shared PC mirror`);
  const lock = script.indexOf("[IO.File]::Open($mirror + '.lock', 'OpenOrCreate', 'ReadWrite', 'None')");
  const refresh = script.indexOf('fetch --prune origin');
  const head = script.indexOf('symbolic-ref HEAD refs/heads/main');
  const clone = script.indexOf('clone --local');
  const fetch = script.indexOf('fetch -', clone);
  const unlock = script.indexOf('finally { $lock.Dispose() }');
  assert(lock >= 0 && lock < refresh && refresh < head && head < clone && clone < fetch && fetch < unlock,
    `${name} refreshes, clones and fetches in order while holding the mirror lock`);
  assert(!/\bclone [^\r\n]*https?:|\bclone [^\r\n]*--depth/i.test(script), `${name} never clones from GitHub or uses a shallow clone`);
}
assert(text.includes("fetch -q --no-tags @depth $mirror ('refs/heads/' + $env:BRANCH)"), 'ship job fetches the requested branch from the mirror');
assert(text.includes("fetch -q --no-tags --no-write-fetch-head $mirror ('+refs/heads/' + $env:PAINT_BASE"), 'PAINT_BASE is fetched from the same mirror without replacing FETCH_HEAD');
assert(look.includes('foreach ($checkout in @($env:TOOL, $env:R))') &&
  look.includes("fetch --no-tags $mirror '+refs/heads/*:refs/remotes/origin/*'"), 'look bench refreshes both checkouts and their origin refs');
pass('mirror refresh and local clone for ship job and both look bench checkouts');

const collect = code.slice(at(/^:collect$/), finish).map(l => l.s);
const copies = collect.filter(s => /^robocopy /i.test(s));
assert.equal(copies.length, 3, 'collect uses separate report, shot and export copies');
assert(copies[0].startsWith('robocopy "%RECIPE%" "%O%\\recipe" *.txt *.json *.md *.jpg /S ') &&
  copies[0].includes('/XD sil "%RECIPE%\\godot\\proj" "%RECIPE%\\export"'), 'collect only the approved report types outside excluded folders');
assert(collect.some(s => s.startsWith('for /d %%D in ("%RECIPE%\\clay" "%RECIPE%\\r" "%RECIPE%\\close" "%RECIPE%\\surface" "%RECIPE%\\godot" "%RECIPE%\\shots" "%RECIPE%\\shots_*")')) &&
  copies[1].includes('"%O%\\recipe\\%%~nxD" *.png *.jpg *.jpeg *.gif /S ') &&
  copies[1].includes('/XD sil "%RECIPE%\\godot\\proj"'), 'copy images from shot folders, excluding the Godot project cache');
assert(copies[2].startsWith('robocopy "%RECIPE%\\export\\%CODE%" "%O%\\recipe\\export\\%CODE%" /E ') &&
  copies[2].includes('/XD sil "%RECIPE%\\export\\%CODE%\\godot\\proj" /XF *.blend b0.npz'),
  'copy only the requested export folder and omit build scratch even there');
assert(copies.every(s => s.includes('/XJ')) && !collect.some(s => /^xcopy /i.test(s)), 'collect avoids junctions and never copies the whole recipe');
assert(copies.every(s => /^if errorlevel 8 if not defined FAILED set "FAILED=collect/.test(collect[collect.indexOf(s) + 1])),
  'a failed copy sets FAILED without hiding an earlier build failure');
assert(collect.some(s => /if not exist "%O%\\recipe\\export\\%CODE%\\%CODE%.glb" if not defined FAILED/.test(s)), 'the stage 7 export guard still checks for the collected GLB');
pass('collect only reports, shots and the requested export');

// Issue 1516 (1415E GP1 and GA1, Nov 21): the mirror fetch failed, yet collect copied the earlier 1415D build's files from
// the shared recipe folder into out\recipe, and the relay looked like a build of the new pin. Collect now runs only when a
// recipe stage ran in this run, and the result names the fetch as the failed step.
{
  const stagesCmd = main.findIndex(l => /cmd \/c ""%~f0" ship"/.test(l.s));
  const ranSet = code.filter(l => /STAGES_RAN=/.test(l.s));
  assert.deepEqual(ranSet.map(l => l.s), ['set STAGES_RAN=', 'set "STAGES_RAN=1"'], 'STAGES_RAN is cleared once and set once');
  const clear = main.findIndex(l => l.s === 'set STAGES_RAN=');
  assert(clear > 0 && clear < main.findIndex(l => guard.test(l.s)), 'STAGES_RAN is cleared before the first way to collect');
  assert(main[stagesCmd - 1].s === 'set "STAGES_RAN=1"' && guard.test(main[stagesCmd - 2].s),
    'STAGES_RAN is set right before the stages run, after the import guard');
  const col = code.slice(at(/^:collect$/)).map(l => l.s);
  assert.equal(col[1], 'if not defined STAGES_RAN goto collect_skipped', 'the first thing collect does is skip when no stage ran');
  const skipped = col.indexOf(':collect_skipped');
  const fin = col.indexOf(':finish');
  assert(skipped > 0 && fin === skipped + 3, 'the skip branch falls straight into :finish');
  assert(/^echo collect SKIPPED: no recipe stage ran/.test(col[skipped + 1]), 'the skip is written to result.txt');
  assert.equal(col[skipped + 2], 'if not defined FAILED set "FAILED=collect (no recipe stage ran)"', 'a skipped collect never passes');
  assert.equal(col[skipped - 1], 'goto finish', 'a normal collect does not run into the skip branch');
  assert(!col.slice(skipped, fin).some(s => /robocopy|copy |xcopy/i.test(s)), 'the skip branch copies nothing');
  const fetchFail = main.find(l => /if errorlevel 1 set "FAILED=mirror fetch: /.test(l.s));
  assert(fetchFail && guard.test(main[main.indexOf(fetchFail) + 1].s), 'a failed fetch says "mirror fetch" and goes straight to collect');
  assert(text.includes("if ($try -ge 3) { throw ('mirror fetch failed ' + $try + ' times') }"), 'the mirror fetch tries three times, then fails');
  assert(/\$wait = 30 \* \$try \* \$try;[^\r\n]*Start-Sleep -Seconds \$wait/.test(text), 'with backoff between tries (30 s, then 120 s)');
  assert(col.some(s => /recipe_from_earlier_runs\.txt/.test(s) && /LastWriteTimeUtc\.Ticks -lt \[long\]\$env:START_TICKS/.test(s)),
    'collected files older than this run are listed');
}
if (process.platform === 'win32') {
  // the real collect section under cmd: stale recipe files, a failed fetch, then a run whose stages ran
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'shipjob1516-'));
  try {
    const recipe = path.join(tmp, 'recipe', 'ithar_GP1');
    fs.mkdirSync(path.join(recipe, 'export', 'G1'), { recursive: true });
    fs.writeFileSync(path.join(recipe, 'build_report.txt'), 'the 1415D build\n');
    fs.writeFileSync(path.join(recipe, 'export', 'G1', 'G1.glb'), 'old glb');
    const old = new Date(Date.now() - 3600e3);
    for (const f of ['build_report.txt', 'export/G1/G1.glb']) fs.utimesSync(path.join(recipe, f), old, old);
    const ticks = (BigInt(Date.now()) * 10000n + 621355968000000000n).toString();
    const section = lines.slice(lines.findIndex(l => l.trim() === ':collect'), lines.findIndex(l => l.trim() === ':ship'));
    const runCase = (name, extra) => {
      const o = path.join(tmp, name);
      fs.mkdirSync(o);
      const probe = path.join(tmp, name + '.bat');
      const head = ['@echo off', 'setlocal', `set "O=${o}"`, 'set "RES=%O%\\result.txt"', `set "RECIPE=${recipe}"`,
        'set "SHIP=ithar_GP1"', 'set "CODE=G1"', 'set "STAGES=1_concept_in 7_export"', `set "START_TICKS=${ticks}"`, ...extra];
      fs.writeFileSync(probe, [...head, ...section].join('\r\n') + '\r\n');
      const run = spawnSync('cmd.exe', ['/d', '/c', probe], { encoding: 'utf8', timeout: 60000 });
      return { status: run.status, o, res: fs.readFileSync(path.join(o, 'result.txt'), 'utf8') };
    };
    const failed = runCase('fetch_failed', ['set "FAILED=mirror fetch: clone or fetch of opus/issue-1415 failed, see the Git output above"']);
    assert.equal(failed.status, 1, failed.res);
    assert(!fs.existsSync(path.join(failed.o, 'recipe')), 'a failed fetch copies nothing from the shared recipe folder');
    assert(/collect SKIPPED: no recipe stage ran/.test(failed.res) && /done FAILED: mirror fetch: /.test(failed.res), failed.res);
    const ran = runCase('stages_ran', ['set "STAGES_RAN=1"']);
    assert(fs.existsSync(path.join(ran.o, 'recipe', 'build_report.txt')), 'a run whose stages ran still collects');
    assert(/recipe_from_earlier_runs/.test(ran.res), ran.res);
    assert(/build_report\.txt/.test(fs.readFileSync(path.join(ran.o, 'recipe_from_earlier_runs.txt'), 'utf8')), 'the earlier file is listed');
    console.log('PASS 1516 real cmd run: the collect section');
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true, maxRetries: 3 });
  }
}
pass('1516: a failed mirror fetch collects nothing from the shared recipe folder and the result names the fetch');

assert(main.some(l => /^ren "%O%" "out_before_%STAMP%" \|\| exit \/b 1$/.test(l.s)), 'stop if the earlier out folder could not be renamed');
const janitor = main.findIndex(l => /out_before_for_janitor\.txt/.test(l.s));
assert(janitor > start && janitor < firstFail + 1 &&
  main[janitor].s.includes("Get-ChildItem -LiteralPath $env:J -Directory -Filter 'out_before_*' | Sort-Object Name -Descending | Select-Object -Skip 2 -ExpandProperty FullName") &&
  main[janitor].s.includes('> "%O%\\out_before_for_janitor.txt"'), 'list only backup folders older than the newest two for the janitor before any build step');
pass('the newest two backups stay off the janitor list');

const bench = fs.readFileSync(path.join(ROOT, 'tools/pc/jobs/look_bench.bat'), 'utf8');
function tempSetup(script) {
  const start = script.indexOf('powershell -NoProfile -Command "$ErrorActionPreference=\'Stop\'; $id=');
  const end = script.indexOf(':run_tools', script.indexOf('exit /b %RUN_EL%', start));
  assert(start >= 0 && end > start, 'sets the helper temp before its tools run');
  return script.slice(start, end);
}
const setups = [tempSetup(text), tempSetup(bench)];
for (const setup of setups) {
  assert.match(setup, /voidsworn-run-.*\.voidsworn-run-owner/);
  assert.match(setup, /set \/p TEMP=.*\r?\nset "TMP=%TEMP%"\r?\nset "TMPDIR=%TEMP%"/);
  assert.match(setup, /call :run_tools 9>"%TEMP%\\\.voidsworn-run-active"\r?\nset "RUN_EL=%ERRORLEVEL%"/);
  // Issue 1180: after the marker is released, TEMP goes back to the base and scratch_done.ps1 ends the scratch with the
  // job's exit code (removed on PASS, newest failure per job kept a day); the job still exits with the tools' code.
  assert.match(setup, /set "BASE_TEMP=%TEMP%"\r?\nset \/p TEMP=/);
  assert.match(setup, /set "TEMP=%BASE_TEMP%"\r?\nset "TMP=%BASE_TEMP%"\r?\nset "TMPDIR=%BASE_TEMP%"/);
  assert.match(setup, /scratch_done\.ps1" -Scratch "%RUN_SCRATCH%" -Code %RUN_EL% -BaseTemp "%BASE_TEMP%" -JobKey "/);
  assert.match(setup, /\r?\nexit \/b %RUN_EL%\r?\n/);
}
if (process.platform === 'win32') {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'helper-temp-proof-'));
  try {
    for (const [number, setup] of setups.entries()) {
      const probe = path.join(tmp, `helper${number}.bat`);
      const lines = ['@echo off', 'setlocal', 'set "O=%PROOF_HOME%"', 'set "LB_HOME=%PROOF_HOME%"',
        'set "RES=%PROOF_HOME%\\setup.log"', 'set "ST=%RES%"', setup,
        ':run_tools', 'powershell -NoProfile -Command "try { [IO.File]::Open((Join-Path $env:TEMP \'.voidsworn-run-active\'),\'Open\',\'Read\',\'None\').Dispose(); exit 1 } catch [IO.IOException] { exit 0 }"',
        'if errorlevel 1 exit /b 1', 'echo TMP=%TMP%', 'echo TEMP=%TEMP%', 'echo TMPDIR=%TMPDIR%',
        'exit /b 0', ':collect', ':finish', 'exit /b 1'];
      fs.writeFileSync(probe, lines.map(line => line.replace(/\r?\n/g, '\r\n')).join('\r\n') + '\r\n');
      const run = spawnSync('cmd.exe', ['/d', '/c', probe], { env: { ...process.env, TEMP: tmp, PROOF_HOME: tmp }, encoding: 'utf8', timeout: 15000 });
      assert.equal(run.status, 0, `${run.stdout}\n${run.stderr}\n${fs.readFileSync(path.join(tmp, 'setup.log'), 'utf8')}`);
      const fromEnv = run.stdout.trim().split(/\r?\n/).map(line => line.split('=')[1]);
      assert.equal(fromEnv.length, 3);
      const [dir] = fromEnv;
      assert(fromEnv.every(value => value === dir));
      assert.equal(path.dirname(dir), tmp);
      assert.equal(fs.readFileSync(path.join(dir, '.voidsworn-run-owner'), 'utf8'), path.basename(dir).slice('voidsworn-run-'.length));
      assert(fs.existsSync(path.join(dir, '.voidsworn-run-active')));
    }
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true, maxRetries: 3 });
  }
}
pass('both helper launchers give their tools separate owned TEMP folders');

const stage7 = spawnSync(process.env.PYTHON || 'python', ['-B', path.join(ROOT, 'tools/recipe/manifest_merge_selftest.py')],
  { encoding: 'utf8', timeout: 20000 });
assert.equal(stage7.status, 0, `${stage7.error || ''}\n${stage7.stdout}\n${stage7.stderr}`);
assert.match(stage7.stdout, /PASS stage 7 scratch removed after successful install/);
assert.match(stage7.stdout, /PASS stage 7 scratch kept after failed install/);
pass('stage 7 removes the checked export scratch after success and keeps it after a failure');

// the wrappers
const wrappers = fs.existsSync(WRAPPERS) ? fs.readdirSync(WRAPPERS).filter(f => /\.bat$/i.test(f)) : [];
assert(wrappers.length >= 1, 'at least one wrapper (the S10 port) in docs/ship_pipeline/ship_job/wrappers');
for (const f of wrappers) {
  const w = fs.readFileSync(path.join(WRAPPERS, f), 'utf8').split(/\r?\n/).filter(l => l.trim());
  assert.equal(w.length, 3, f + ' is three lines');
  assert.equal(w[0].trim(), '@echo off', f);
  for (const v of ['SHIP', 'CODE', 'BRANCH', 'JOB_DIR']) assert(new RegExp(`set "${v}=[^"]+"`).test(w[1]), `${f} sets ${v}`);
  assert(/^call "%USERPROFILE%\\Downloads\\voidsworn_test\\ship_job\\ship_job\.bat"$/.test(w[2].trim()), f + ' calls the shared copy');
}
pass(`the wrappers: ${wrappers.length} three-line wrapper(s) set the inputs and call the shared job`);
{
  // 1194 (Artoo on PR 1254, 760e4bad): the same git commands the job runs, on a real repo. A staged tmo.bat edit with the
  // worktree equal to HEAD leaves the patch empty, so the job must stop on git diff --cached before any restore; a hand
  // edit of the hand-off copy no longer matches the recorded hash, so it stays on the unexpected list.
  const repo = fs.mkdtempSync(path.join(os.tmpdir(), 'shipjob1194-'));
  const g = (...a) => spawnSync('git', ['-C', repo, '-c', 'user.name=t', '-c', 'user.email=t@t', ...a], { encoding: 'utf8' });
  fs.mkdirSync(path.join(repo, 'tools', 'pc'), { recursive: true });
  fs.mkdirSync(path.join(repo, 'godot', 'assets', 'ships'), { recursive: true });
  const tmo = path.join(repo, 'tools', 'pc', 'tmo.bat');
  fs.writeFileSync(tmo, 'old watchdog\n');
  fs.writeFileSync(path.join(repo, 'godot', 'assets', 'ships', 'manifest.json'), '{}\n');
  assert.equal(g('init', '-q').status, 0);
  g('add', '.'); assert.equal(g('commit', '-qm', 'base').status, 0);
  const status = excl => g('status', '--porcelain', '--untracked-files=no', '--', '.', ':(exclude)godot/assets/ships', ':(glob,exclude)godot/**/*.import', excl).stdout.trim();
  // staged edit, worktree back at HEAD
  fs.writeFileSync(tmo, 'hand fix\n'); g('add', tmo); fs.writeFileSync(tmo, 'old watchdog\n');
  assert.equal(g('diff', '--binary', 'HEAD').stdout, '', 'the patch misses a staged edit when the worktree matches HEAD');
  assert.equal(g('diff', '--cached', '--quiet', 'HEAD').status, 1, 'git diff --cached stops the job on a staged edit');
  g('reset', '-q');
  assert.equal(g('diff', '--cached', '--quiet', 'HEAD').status, 0, 'a clean index passes');
  // the hand-off copy: recorded hash matches, so it is excluded and restored
  fs.writeFileSync(tmo, 'tools_live hand-off\r\n');
  const rec = g('hash-object', '--', 'tools/pc/tmo.bat').stdout.trim();
  assert(/^[0-9a-f]{40}$/.test(rec));
  assert.equal(g('hash-object', '--', 'tools/pc/tmo.bat').stdout.trim(), rec, 'the left-over copy matches its record');
  assert.equal(status(':(exclude)tools/pc/tmo.bat'), '', 'the recorded copy is not an unexpected change');
  // a hand edit of the copy: hash differs, so the filler exclude keeps tmo.bat on the unexpected list
  fs.appendFileSync(tmo, 'rem hand edit\r\n');
  assert.notEqual(g('hash-object', '--', 'tools/pc/tmo.bat').stdout.trim(), rec, 'a hand edit no longer matches the record');
  assert(/tools\/pc\/tmo\.bat/.test(status(':(exclude)godot/assets/ships')), 'a hand-edited tmo.bat stops the job as unexpected');
  fs.rmSync(repo, { recursive: true, force: true });
}
pass('1194: a staged clone change stops the job before any reset; only the recorded tmo.bat hand-off copy is restored');
console.log(`PASS ship job checks (${passed} groups)`);
