'use strict';
// R276: Linux CI runs the real policy, file transactions and competing clients.
// Fake workers hold claims without touching the graphics card. Windows also runs
// the watchdog, proving release on normal exit, failed start and timeout.
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn } = require('child_process');
const pc = path.resolve(__dirname, '../../../tools/pc');
const helper = path.join(pc, 'gpu_slots.js');
const { Slots, modeFor } = require(helper);
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'gpu847 '));
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const children = [];
const put = (p, s) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, s); };
let passed = 0;
function pass(s) { passed++; console.log('PASS ' + s); }
function client(args, env = {}) {
  const p = spawn(process.execPath, [helper, ...args], { cwd: root, windowsHide: true,
    env: { ...process.env, PC_GPU_LANE: '', ...env } });
  children.push(p);
  p.output = ''; p.errors = ''; p.done = false;
  p.stdout.on('data', b => { p.output += b; });
  p.stderr.on('data', b => { p.errors += b; });
  p.result = new Promise((resolve, reject) => {
    p.on('error', reject);
    p.on('exit', code => { p.done = true; resolve({ code, text: p.output.trim(), error: p.errors }); });
  });
  return p;
}
async function until(fn) {
  for (let i = 0; i < 200; i++) { if (fn()) return; await sleep(50); }
  throw new Error('timed out waiting for fake GPU client');
}
const holder = (pid, mode = 'shared') => ({ pid, mode, token: String(pid), issue: '847', started: 'fake start' });
async function main() {
  const fakeRoot = path.join(root, 'fake');
  const live = new Set([1, 2, 3, 4]);
  const slots = new Slots(fakeRoot, pid => live.has(pid));
  assert.equal(slots.step(holder(1)), null, 'missing go must block');
  put(path.join(fakeRoot, 'gpu_go.txt'), 'GPU not cleared\nGPU cleared');
  assert.equal(slots.step(holder(1)), null);
  put(path.join(fakeRoot, 'gpu_go.txt'), 'GPU cleared: Ryan, "cpu and gpu are yours again"\n');
  assert(slots.step(holder(1))); assert(slots.step(holder(2)));
  assert.equal(slots.step(holder(3)), null);
  assert.equal(slots.read('gpu_slot_1').issue, '847');
  assert.equal(slots.read('gpu_slot_2').started, 'fake start');
  pass('fake processes: exactly two slots, holder issue/start, missing and withdrawn go block');
  assert.equal(slots.step(holder(3, 'solo')), null);
  slots.release('1');
  assert.equal(slots.step(holder(4)), null, 'pending solo must block new shared work');
  assert.equal(slots.step(holder(3, 'solo')), null, 'solo must drain the second slot too');
  slots.release('2');
  assert(slots.step(holder(3, 'solo')));
  assert.equal(slots.step(holder(4)), null);
  slots.release('3'); assert(slots.step(holder(4)));
  slots.release('old token'); assert(slots.read('gpu_slot_1'));
  live.delete(4); assert(slots.step(holder(1)));
  slots.release('1');
  slots.write('gpu_solo', holder(4, 'solo'));
  assert(slots.step(holder(2)), 'dead solo waiter must be reclaimed');
  pass('fake processes: solo drains both, blocks arrivals, releases, and reclaims dead slots and waiters');
  slots.release('2');
  put(path.join(fakeRoot, 'gpu_go.txt'), 'GPU not cleared');
  assert.equal(slots.step(holder(3, 'solo')), null);
  assert.equal(slots.read('gpu_solo'), null, 'closed gate must not reserve a new claim');
  pass('gaming gate also blocks solo admission');

  const project = path.join(root, 'project');
  put(path.join(project, 'capture.gd'), 'extends SceneTree\n# capture only\n');
  put(path.join(project, 'timing.gd'), 'var sample = Performance.get_monitor(Performance.TIME_PROCESS)');
  put(path.join(project, 'timing.tscn'), '[ext_resource path="res://timing.gd"]');
  const gd = 'C:\\Godot_v4.7.2-stable_win64_console.exe';
  assert.equal(modeFor(gd, '--headless --import'), '');
  assert.equal(modeFor('blender.exe', '-b'), 'shared');
  assert.equal(modeFor('node.exe', 'tests.js'), '');
  assert.equal(modeFor(gd, `--path "${project}" --script res://capture.gd`), 'shared');
  assert.equal(modeFor(gd, `--path "${project}" res://timing.tscn`), 'solo');
  assert.equal(modeFor(gd, 'res://bench/scene_gate.tscn'), 'solo');
  assert.equal(modeFor(gd, 'res://bench/look_bench.tscn'), 'shared');
  const game = path.resolve(pc, '../../godot');
  assert.equal(modeFor(gd, `--path "${game}" res://bench/look_bench.tscn`), 'shared');
  assert.equal(modeFor(gd, `--path "${game}" res://assets/ships/test/a4_shots.tscn`), 'shared');
  assert.equal(modeFor(gd, '--bench timing.json'), 'solo');
  assert.equal(modeFor(gd, `--script "${path.join(project, 'timing.gd')}"`), 'solo');
  assert.equal(modeFor(gd, 'res://bench209r3.gd', root, 'shared'), 'solo');
  put(path.join(project, 'project.godot'), '[application]\nrun/main_scene="res://timing.tscn"');
  assert.equal(modeFor(gd, `--path "${project}"`), 'solo');
  pass('launch classification: capture shared, timing scene and known benches solo, headless and code skip');

  const raceRoot = path.join(root, 'race');
  put(path.join(raceRoot, 'gpu_go.txt'), 'GPU cleared');
  const workers = [1, 2, 3, 4].map(() => {
    const p = spawn(process.execPath, ['-e', 'setInterval(()=>{},1000)'], { windowsHide: true });
    children.push(p); return p;
  });
  const claim = (worker, mode = 'shared') => client(['acquire', raceRoot, '847', String(worker.pid), mode]);
  const release = async token => assert.equal((await client(['release', raceRoot, token]).result).code, 0);
  const claims = workers.slice(0, 3).map(w => claim(w));
  await until(() => claims.filter(p => p.done).length === 2);
  await sleep(200);
  assert.equal(claims.filter(p => p.done).length, 2, 'concurrent clients overbooked');
  const rs = new Slots(raceRoot);
  assert(rs.read('gpu_slot_1') && rs.read('gpu_slot_2'));
  // Cancel the third shared waiter, then queue solo before releasing either slot.
  const blocked = claims.find(p => !p.done); blocked.kill(); await blocked.result;
  const solo = claim(workers[3], 'solo');
  await until(() => !!rs.read('gpu_solo'));
  const newcomer = claim(workers[2]);
  for (const p of claims.filter(p => p.done && p !== blocked)) {
    const result = await p.result; assert.equal(result.code, 0, result.error); await release(result.text);
  }
  await until(() => solo.done);
  assert.equal(newcomer.done, false);
  const soloResult = await solo.result; assert.equal(soloResult.code, 0, soloResult.error);
  put(path.join(raceRoot, 'gpu_go.txt'), 'GPU not cleared');
  await release(soloResult.text); await sleep(300);
  assert.equal(newcomer.done, false, 'waiting client bypassed gaming pause');
  put(path.join(raceRoot, 'gpu_go.txt'), 'GPU cleared');
  const shared = await newcomer.result; assert.equal(shared.code, 0, shared.error);
  // A process that dies while holding a slot is replaced, without manual cleanup.
  workers[2].kill(); await new Promise(resolve => workers[2].once('exit', resolve));
  const replacement = await claim(workers[0]).result;
  assert.equal(replacement.code, 0, replacement.error);
  assert.equal(rs.read('gpu_slot_1').pid, workers[0].pid);
  await release(shared.text); assert(rs.read('gpu_slot_1'), 'stale release cleared the new holder');
  await release(replacement.text);
  const refused = await client(['acquire', raceRoot, '847', String(process.pid), 'shared'], { PC_GPU_LANE: 'C' }).result;
  assert.notEqual(refused.code, 0); assert(/code only/.test(refused.error));
  pass('real concurrent clients: two slots, solo priority/exclusion, pause on wait, stale PID, token-safe release, lane C refusal');

  for (const name of ['codex_issue', 'work_issue']) {
    const bat = fs.readFileSync(path.join(pc, name + '.bat'), 'utf8');
    assert(bat.includes('PC_GPU_ISSUE=%N%')); assert(bat.includes('PC_GPU_LANE=C'));
    assert(fs.readFileSync(path.join(pc, name + '.ps1'), 'utf8').includes('tmo.bat'));
  }
  const watchdog = fs.readFileSync(path.join(pc, 'run_timeout.ps1'), 'utf8');
  assert(watchdog.includes('finally {\n  if ($gpuToken)'));
  const lb = fs.readFileSync(path.join(pc, 'jobs/look_bench.bat'), 'utf8');
  assert(!lb.includes('GEQ 60 goto gpufree'));
  pass('runner context, generated task guidance, watchdog release and look bench wiring');

  if (process.platform === 'win32') await windowsWatchdog();
  else console.log('SKIP Windows watchdog integration (runs on Windows standing checks)');
  console.log(`PASS GPU slot checks (${passed} groups)`);
}

async function windowsWatchdog() {
  const home = path.join(root, 'watchdog');
  put(path.join(home, 'gpu_go.txt'), 'GPU cleared');
  const probe = path.join(home, 'probe.js');
  put(probe, "require('fs').writeFileSync(process.argv[2], 'started'); setTimeout(()=>process.exit(Number(process.argv[3])), Number(process.argv[4]));");
  async function run(exe, args, extra = {}) {
    const p = spawn('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(pc, 'run_timeout.ps1')], {
      cwd: root, windowsHide: true, env: { ...process.env, PC_RUNNER_TEST: '1', PC_TEST_GPU_ROOT: home,
        PC_GPU_LANE: '', PC_GPU_MODE: 'shared', PC_GPU_ISSUE: '847', PC_TEST_POLL_MS: '30',
        PC_TEST_TIMEOUT_LOG: path.join(home, 'timeouts.log'), TMO_REPO: '', TMO_OUT: '', TMO_LOG: '',
        TMO_ARGS: `1 "${exe}" ${args}`, ...extra }
    });
    children.push(p);
    let output = ''; p.stdout.on('data', b => { output += b; }); p.stderr.on('data', b => { output += b; });
    const code = await new Promise((resolve, reject) => { p.on('error', reject); p.on('exit', resolve); });
    return { code, output };
  }
  const marker = path.join(home, 'started.txt');
  const rs = new Slots(home);
  for (const [code, delay, expect] of [[7, 0, 7], [0, 5000, 124]]) {
    const r = await run(process.execPath, `"${probe}" "${marker}" ${code} ${delay}`);
    assert.equal(r.code, expect, r.output); assert(fs.existsSync(marker));
    assert.equal(rs.read('gpu_slot_1'), null); assert.equal(rs.read('gpu_slot_2'), null);
  }
  const failed = await run(path.join(home, 'missing.exe'), '');
  assert.equal(failed.code, 125, failed.output); assert.equal(rs.read('gpu_slot_1'), null);
  const denied = await run(process.execPath, `"${probe}" "${path.join(home, 'denied.txt')}" 0 0`, { PC_GPU_LANE: 'C' });
  assert.notEqual(denied.code, 0); assert(!fs.existsSync(path.join(home, 'denied.txt')));
  pass('Windows watchdog preserves child exit, releases on timeout/start failure, refuses lane C before spawn');

  // A hard link to Node is a fake Godot executable: it writes a marker instead of
  // rendering. This exercises automatic classification through the real watchdog.
  const fakeGodot = path.join(home, 'Godot_fake.exe');
  fs.linkSync(process.execPath, fakeGodot);
  const held = await client(['acquire', home, '847', String(process.pid), 'shared']).result;
  assert.equal(held.code, 0, held.error);
  const soloMarker = path.join(home, 'solo_started.txt');
  const measuring = run(fakeGodot, `"${probe}" "${soloMarker}" 0 100 res://bench/scene_gate.tscn`, { PC_GPU_MODE: '' });
  await until(() => !!rs.read('gpu_solo'));
  await sleep(1200); // longer than the command limit; queue time must not consume it
  assert(!fs.existsSync(soloMarker), 'measurement started alongside shared work');
  const arrival = client(['acquire', home, '847', String(process.pid), 'shared']);
  await sleep(150); assert(!arrival.done, 'solo waiter let new work in');
  await client(['release', home, held.text]).result;
  const measured = await measuring; assert.equal(measured.code, 0, measured.output);
  assert(fs.existsSync(soloMarker));
  const next = await arrival.result; assert.equal(next.code, 0, next.error);
  await client(['release', home, next.text]).result;
  assert.equal(rs.read('gpu_solo'), null); assert.equal(rs.read('gpu_slot_1'), null);
  pass('Windows automatic timing claim waits solo, blocks arrivals, excludes queue time and releases after measurement');
}
main().catch(e => { console.error(e.stack); process.exitCode = 1; }).finally(() => {
  for (const p of children) if (p.exitCode === null && p.signalCode === null) p.kill();
});
