'use strict';
// Issue 1663 (Ryan, Nov 22 2026, owner decision 4): build\export refreshes overnight only when gpu_go.txt is clear, the
// PC is idle, C: has 75 GB free and main changed game files. Static contract for the watcher hook, the job and
// g2_export's idle promotion; the decider (tools/pc/overnight_export.ps1) runs for real under pwsh (Linux CI).
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '../../..');
const read = p => fs.readFileSync(path.join(root, p), 'utf8').replace(/\r\n/g, '\n');
const watcher = read('tools/pc/watcher.bat'), job = read('tools/pc/jobs/overnight_export_job.bat'), g2 = read('tools/pc/jobs/g2_export.bat');

const idle = watcher.slice(watcher.indexOf('\n:idle\n'));
assert(/if "%OX_MINUTE%"=="%time:~0,4%" goto idle_wait\n/.test(idle), 'the decider runs about every 10 minutes, not every 5 seconds');
assert(/powershell [^\n]*-File "tools_live\\%TLV%\\pc\\overnight_export\.ps1" >> "queue\\logs\\overnight_export\.txt" 2>&1/.test(idle), 'the watcher runs the tools_live decider and logs it');
assert(watcher.indexOf('overnight_export') > watcher.indexOf('if not defined J goto idle'), 'only from the idle branch');
assert(/call "%HEAD%" init "%JOB%" "%LABEL%" "%TOOLS%"/.test(job) && /call "%HEAD%" tail/.test(job), 'the export job runs through the job head');
assert(/if not defined ON_PIN \(echo FAILED[^\n]*exit \/b 2\)/.test(job) && /set "PIN_NEW=%ON_PIN%"/.test(job), 'the job pins the commit the decider saw');
assert(/set "OJ_SLOTS=0"\n/.test(job) && /set "OJ_SLOT_KIND=cpu"\n/.test(job), 'a fresh checkout until the slots rollout turns slots on for every caller');
const one = job.slice(job.indexOf('\n:one\n'));
assert(/powershell [^\n]*-File "%ON_HERE%\.\.\\overnight_export\.ps1" -Check start/.test(one) && one.indexOf('-Check start') < one.indexOf('call "%HEAD%" checkout'), 'the gates are checked again when the job starts, before its checkout');
assert(/if "%ON_RC%"=="3" \(call "%JW%" note "skipped[^\n]*& exit \/b 0\)/.test(one), 'a gate that no longer holds ends the job as skipped, not failed');
assert(/set "G2_PROMOTE_CHECK=%ON_HERE%\.\.\\overnight_export\.ps1"/.test(job) && job.indexOf('if "%ON_RC%"=="3" (call "%JW%" note "skipped: the overnight gates no longer held at promotion') < job.indexOf("'exported '"), 'a skip at promotion records nothing');
assert(job.indexOf('if defined JW_STOP') < job.indexOf('g2_export.bat" "%OJ_REPO%'), 'no export after a failed checkout or ships copy');
assert(job.indexOf('set "G2_PROMOTE_ONLY_IDLE=1"') < job.indexOf('g2_export.bat"') && job.indexOf("'exported '") > job.indexOf('if not "%ON_RC%"=="0" (call "%JW%" fail "g2_export'), 'the commit is recorded only after a passed export');
assert(!/build\\godot\\[^\n]*(?:robocopy|del |rmdir|move )/i.test(job), 'build\\godot itself is never changed');
const promote = g2.slice(g2.indexOf('G2_PROMOTE_ONLY_IDLE'));
assert(/tasklist [^\n]*findstr [^\n]*Voidsworn\.exe[^\n]*Voidsworn\.console\.exe/.test(promote) && promote.indexOf('tasklist') < promote.indexOf('[IO.Directory]::Move($live, $backup)'), 'the live export is not replaced while the game runs');
assert(/-File "%G2_PROMOTE_CHECK%" -Check promote/.test(promote) && promote.indexOf('-Check promote') < promote.indexOf('[IO.Directory]::Move($live, $backup)') && /if errorlevel 3 \([^\n]*exit \/b 3\)/.test(promote), 'the gates are checked again just before promotion');
assert(/if defined G2_ARG if "%G2_ARG:~1,1%"==":" set "PROJ=%~f1"/.test(g2), 'g2_export takes a full project path');
console.log('PASS overnight export static: watcher hook every 10 minutes when idle, job through the head on the decided pin, no promotion while the game runs');

const windows = process.platform === 'win32';
const shell = windows ? 'powershell.exe' : 'pwsh';
if (windows || spawnSync(shell, ['-NoProfile', '-Command', 'exit 0']).error) {
  if (process.env.CI && !windows) throw new Error(`${shell} is required in CI`);
  console.log('SKIP overnight export fixtures: they need pwsh (Linux CI runs them)');
  process.exit(0);
}
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'overnight-export-'));
const vt = path.join(tmp, 'vt'), source = path.join(tmp, 'source.git'), work = path.join(tmp, 'work');
const write = (file, text) => { fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, text); };
const git = (args, cwd = tmp) => { const r = spawnSync('git', args, { cwd, encoding: 'utf8' }); assert.equal(r.status, 0, r.stderr); return r.stdout.trim(); };
const night = '2026-11-23T08:00:00Z';   // 2:00 AM Central
const base = { ...process.env, PC_TEST_HELPER: '1', PC_TEST_HELPER_VT: vt, PC_TEST_SOURCE: source, PC_TEST_NOW: night, PC_TEST_PROCS: 'explorer', PC_TEST_FREE_GB: '200', POWERSHELL_TELEMETRY_OPTOUT: '1' };
function run(extra = {}, ...args) {
  const r = spawnSync(shell, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(root, 'tools/pc/overnight_export.ps1'), ...args], { env: { ...base, ...extra }, encoding: 'utf8', timeout: 60000 });
  return { status: r.status, out: `${r.stdout}\n${r.stderr}`.replace(/\s+/g, ' ') };
}
const queued = () => fs.existsSync(path.join(vt, 'queue')) ? fs.readdirSync(path.join(vt, 'queue')).filter(f => /^OVERNIGHT_EXPORT_[0-9a-f]{12}\.bat$/.test(f)) : [];
const commit = (file, text) => { write(path.join(work, file), text); git(['add', '-A'], work); git(['-c', 'user.name=f', '-c', 'user.email=f@example.invalid', 'commit', '-qm', file], work); return git(['rev-parse', 'HEAD'], work); };
try {
  git(['init', '-q', '-b', 'main', work]);
  const c1 = commit('godot/project.godot', 'one\n');
  git(['clone', '-q', '--bare', work, source]);
  git(['init', '-q', '--bare', path.join(vt, 'repo-mirror.git')]);
  git(['--git-dir', path.join(vt, 'repo-mirror.git'), 'remote', 'add', '--mirror=fetch', 'origin', source]);
  write(path.join(vt, 'gpu_go.txt'), 'GPU cleared: test\n');
  fs.mkdirSync(path.join(vt, 'queue', 'running'), { recursive: true });

  assert.equal(run({ PC_TEST_NOW: '2026-11-23T18:00:00Z' }).status, 0);
  assert.equal(queued().length, 0, 'noon: nothing');
  write(path.join(vt, 'gpu_go.txt'), 'GPU not cleared: paused\n');
  assert(/gpu_go\.txt does not say GPU cleared/.test(run().out) && !queued().length, 'paused GPU: nothing');
  write(path.join(vt, 'gpu_go.txt'), 'GPU cleared\n');
  assert(/under the 75 GB job floor/.test(run({ PC_TEST_FREE_GB: '60' }).out) && !queued().length, 'low disk: nothing');
  write(path.join(vt, 'queue_b', 'running', 'X.bat'), 'rem\n');
  assert(/queue_b\\running has a job/.test(run().out) && !queued().length, 'a running job: nothing');
  fs.rmSync(path.join(vt, 'queue_b'), { recursive: true });
  write(path.join(vt, 'gpu_slot_1'), 'opus1234 9999\n');
  assert(/a GPU claim is live/.test(run().out) && !queued().length, 'a GPU claim: nothing');
  write(path.join(vt, 'gpu_slot_1'), '');
  assert(/Voidsworn is running/.test(run({ PC_TEST_PROCS: 'explorer,Voidsworn' }).out) && !queued().length, 'Ryan playing: nothing');

  let r = run();
  assert.equal(r.status, 0, r.out);
  assert.deepEqual(queued(), [`OVERNIGHT_EXPORT_${c1.slice(0, 12)}.bat`], 'all gates hold: one job for main: ' + r.out);
  const bat = fs.readFileSync(path.join(vt, 'queue', queued()[0]), 'utf8');
  assert(bat.includes(`set "ON_PIN=${c1}"\r\n`) && /set "ON_DATE=\d{4}-\d\d-\d\dT[^"]+"\r\n/.test(bat) && bat.includes('pc\\jobs\\overnight_export_job.bat"'), bat);
  fs.rmSync(path.join(vt, 'queue', queued()[0]));
  assert.equal(run().status, 0); assert.equal(queued().length, 0, 'one try a night');

  // the next night: the job recorded c1; a change outside godot/ queues nothing, a game change queues the new main
  const state = path.join(vt, 'overnight_export', 'state.txt');
  write(state, `tried 20261123\r\nexported ${c1}\r\n`);
  commit('docs/notes.md', 'docs only\n'); git(['push', '-q', source, 'main'], work);
  r = run({ PC_TEST_NOW: '2026-11-24T08:00:00Z' });
  assert(/same game files as the last overnight export/.test(r.out) && !queued().length, 'docs-only change: nothing: ' + r.out);
  const c3 = commit('godot/main.gd', 'extends Node\n'); git(['push', '-q', source, 'main'], work);
  write(state, `exported ${c1}\r\n`);
  r = run({ PC_TEST_NOW: '2026-11-24T09:30:00Z' });
  assert.deepEqual(queued(), [`OVERNIGHT_EXPORT_${c3.slice(0, 12)}.bat`], 'a game change queues the new main: ' + r.out);
  assert(fs.readFileSync(state, 'utf8').includes(`exported ${c1}`) && fs.readFileSync(state, 'utf8').includes('tried 20261124'), 'the last export stays recorded until a job passes');
  // Artoo on PR 1733: the job rechecks when it starts and before promotion, leaving out its own queue entry
  fs.rmSync(path.join(vt, 'queue'), { recursive: true, force: true });
  write(path.join(vt, 'queue', 'running', `OVERNIGHT_EXPORT_${c3.slice(0, 12)}.bat`), 'rem\n');
  r = run({}, '-Check', 'start');
  assert(r.status === 0 && /gates hold at start/.test(r.out), 'its own queue entry does not count: ' + r.out);
  r = run({ PC_TEST_NOW: '2026-11-24T12:30:00Z' }, '-Check', 'start');
  assert(r.status === 3 && /skipped: outside the 1 to 5 AM Central window \(06:30\)/.test(r.out), 'a job that starts after its window is skipped: ' + r.out);
  write(path.join(vt, 'gpu_go.txt'), 'GPU not cleared: paused\n');
  r = run({}, '-Check', 'start');
  assert(r.status === 3 && /gpu_go/.test(r.out), 'the GPU switch turned off after queueing: ' + r.out);
  write(path.join(vt, 'gpu_go.txt'), 'GPU cleared\n');
  write(path.join(vt, 'queue', 'B.bat'), 'rem\n');
  r = run({}, '-Check', 'start');
  assert(r.status === 3 && /queue has a job/.test(r.out), 'another job arrived: ' + r.out);
  fs.rmSync(path.join(vt, 'queue', 'B.bat'));
  write(path.join(vt, 'gpu_slot_1'), 'opus1663night 1234\n');
  r = run({ PC_TEST_PROCS: 'explorer,Godot_v4.7.2' }, '-Check', 'promote');
  assert(r.status === 0, "at promotion the job's own Godot and GPU claim do not count: " + r.out);
  r = run({ PC_TEST_PROCS: 'explorer,Voidsworn' }, '-Check', 'promote');
  assert(r.status === 3 && /Voidsworn is running/.test(r.out), 'Ryan started the game: ' + r.out);
  r = run({ PC_TEST_NOW: '2026-11-24T11:10:00Z' }, '-Check', 'promote');
  assert(r.status === 3 && /outside the 1 to 5 AM/.test(r.out), 'an export that finishes after the window is not promoted: ' + r.out);
  assert.equal(queued().length, 0, 'a check queues nothing');
  console.log('PASS overnight export rechecks: at the job start and before promotion, its own entry left out, a late job skipped');
  console.log('PASS overnight export decider: night window, gpu_go, disk floor, queues, GPU claims and the game gate it; one try a night; only game file changes queue the job');
} finally { fs.rmSync(tmp, { recursive: true, force: true }); }
