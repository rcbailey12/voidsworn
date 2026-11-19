'use strict';
// R293: Linux CI runs the real policy, file transactions and competing clients.
// Fake workers hold claims without touching the graphics card. Windows also runs
// the watchdog, proving release on normal exit, failed start and timeout.
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const net = require('net');
const { spawn } = require('child_process');
const pc = path.resolve(__dirname, '../../../tools/pc');
const helper = path.join(pc, 'gpu_slots.js');
const { Slots, modeFor, weightFor, codeOnlyLane } = require(helper);
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'gpu847 '));
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const children = [];
const put = (p, s) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, s); };
let passed = 0;
function pass(s) { passed++; console.log('PASS ' + s); }
function client(args, env = {}) {
  const p = spawn(process.execPath, [helper, ...args], { cwd: root, windowsHide: true,
    env: { ...process.env, PC_GPU_LANE: '', PC_GPU_WAIT_SECONDS: '300', ...env } });
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
async function until(fn, ms = 10000) {
  for (let i = 0; i < ms / 50; i++) { if (fn()) return; await sleep(50); }
  throw new Error('timed out waiting for fake GPU client');
}
const holder = (pid, mode = 'shared') => ({ pid, mode, token: String(pid), issue: '847', started: 'fake start' });
const capacity = (root, count) => put(path.join(root, 'gpu_slots.json'), JSON.stringify({ sharedSlots: count }));
const used = slots => slots.names().filter(name => name !== 'gpu_solo' && slots.read(name));
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

  put(path.join(fakeRoot, 'gpu_go.txt'), 'GPU cleared');
  const heavy = { ...holder(2), weight: 2 };
  assert(slots.step(holder(1)));
  assert.equal(slots.step(heavy), null, 'weight 2 cannot fit in one free slot');
  assert.equal(used(slots).length, 1, 'a waiting heavy job must not hold a partial claim');
  capacity(fakeRoot, 3);
  assert(new Slots(fakeRoot, pid => live.has(pid)).step(heavy), 'other tools copies must read the same raised capacity');
  assert.equal(used(slots).length, 3);
  slots.release('2'); assert.equal(used(slots).length, 1, 'release must clear the whole weight');
  assert(slots.step(holder(2))); assert(slots.step(holder(3)));
  live.add(4);
  assert.equal(slots.step(holder(4)), null);
  capacity(fakeRoot, 4);
  assert(slots.step(holder(4)), 'four light jobs must fit after raising the setting');
  capacity(fakeRoot, 2);
  slots.release('1'); slots.release('2');
  assert.equal(slots.step(holder(1)), null, 'lowering capacity must count claims in higher slot files');
  assert.equal(slots.step(holder(1, 'solo')), null);
  slots.release('3');
  assert.equal(slots.step(holder(1, 'solo')), null, 'solo must drain slot 4 even after lowering capacity');
  slots.release('4'); assert(slots.step(holder(1, 'solo')));
  capacity(fakeRoot, 4);
  assert.equal(slots.step(heavy), null, 'raising capacity must never bypass solo');
  slots.release('1');
  assert(slots.step(heavy)); live.delete(2);
  assert(slots.step(holder(1))); assert.equal(used(slots).length, 1, 'dead weighted claims must be reclaimed in full');
  slots.release('1'); live.add(2);
  capacity(fakeRoot, 1);
  assert.throws(() => slots.step(heavy), /exceeds.*capacity/, 'a job larger than total capacity must fail immediately');
  assert.equal(slots.read('gpu_solo'), null, 'heavy shared waiters must not reserve solo');
  capacity(fakeRoot, 3);
  assert(slots.step(heavy)); slots.release('2');
  pass('weighted load: no partial admission, live raised capacity, lowered capacity, solo across all slots, dead weighted claims');

  for (const count of [0, -1, 1.5, '2 jobs', null, true, Number.MAX_SAFE_INTEGER + 1]) {
    capacity(fakeRoot, count);
    assert.throws(() => slots.step(holder(1)), /positive integer/);
  }
  for (const content of ['', 'null', '{"sharedSlots":', '{}']) {
    put(path.join(fakeRoot, 'gpu_slots.json'), content);
    assert.throws(() => slots.step(holder(1)));
  }
  capacity(fakeRoot, 4);
  for (const weight of [0, -1, 1.5, '2 jobs', true]) {
    assert.throws(() => slots.step({ ...holder(1), weight }), /positive integer/);
  }
  pass('invalid capacity and weights fail closed');

  const project = path.join(root, 'project');
  put(path.join(project, 'capture.gd'), 'extends SceneTree\n# capture only\n');
  put(path.join(project, 'timing.gd'), 'var sample = Performance.get_monitor(Performance.TIME_PROCESS)');
  put(path.join(project, 'timing.tscn'), '[ext_resource path="res://timing.gd"]');
  const gd = 'C:\\Godot_v4.7.2-stable_win64_console.exe';
  assert.equal(modeFor(gd, '--headless --import'), '');
  assert.equal(modeFor('blender.exe', '-b'), 'shared');
  const cpuMode = modeFor('blender.exe', '-b', root, 'none');
  assert.equal(cpuMode, '');
  assert.equal(weightFor('blender.exe', '', cpuMode), 0);
  assert.equal(weightFor('blender.exe', '2', 'none'), 0);
  assert.equal(weightFor('C:\\Blender\\blender.exe'), 2);
  assert.equal(weightFor(gd), 1);
  assert.equal(weightFor('python.exe', '2'), 2);
  assert.equal(weightFor('blender.exe', '1'), 1);
  assert.throws(() => weightFor(gd, '0'), /positive integer/);
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
  assert.equal(modeFor(gd, 'res://bench209r3.gd', root, 'none'), 'solo');
  put(path.join(project, 'project.godot'), '[application]\nrun/main_scene="res://timing.tscn"');
  assert.equal(modeFor(gd, `--path "${project}"`), 'solo');
  pass('launch classification: capture shared, timing scene and known benches solo, headless and code skip');

  const raceRoot = path.join(root, 'race');
  put(path.join(raceRoot, 'gpu_go.txt'), 'GPU cleared');
  const closed = path.join(root, 'closed');
  capacity(closed, 1);
  const tooHeavy = client(['acquire', closed, '1100', String(process.pid), 'shared', '2'], { PC_GPU_WAIT_SECONDS: '60' });
  try { await until(() => tooHeavy.done, 2500); }
  catch { throw new Error('impossible GPU weight waited for admission'); }
  assert.match((await tooHeavy.result).error, /exceeds.*capacity/i);
  const closedGate = client(['acquire', closed, '1100', String(process.pid), 'shared'], { PC_GPU_WAIT_SECONDS: '1' });
  await until(() => closedGate.done, 3500);
  const expired = await closedGate.result;
  assert.notEqual(expired.code, 0); assert.match(expired.error, /admission timed out/i);
  pass('GPU admission fails promptly at impossible weight and times out with the go gate closed');
  const heldLock = net.createServer();
  await new Promise((resolve, reject) => {
    heldLock.once('error', reject); heldLock.listen(47847, '127.0.0.1', resolve);
  });
  try {
    const waiter = client(['acquire', raceRoot, '1100', String(process.pid), 'shared'], { PC_GPU_WAIT_SECONDS: '1' });
    await until(() => waiter.done, 3500);
    assert.match((await waiter.result).error, /admission timed out/i);
  } finally { await new Promise(resolve => heldLock.close(resolve)); }
  pass('admission deadline also covers a busy slot lock');
  const workers = [1, 2, 3, 4].map(() => {
    const p = spawn(process.execPath, ['-e', 'setInterval(()=>{},1000)'], { windowsHide: true });
    children.push(p); return p;
  });
  const claim = (worker, mode = 'shared', weight = '1') => client(['acquire', raceRoot, '847', String(worker.pid), mode, weight]);
  const release = async token => assert.equal((await client(['release', raceRoot, token]).result).code, 0);
  const claims = workers.slice(0, 3).map(w => claim(w));
  await until(() => claims.filter(p => p.done).length === 2);
  await sleep(200);
  assert.equal(claims.filter(p => p.done).length, 2, 'concurrent clients overbooked');
  const rs = new Slots(raceRoot);
  assert(rs.read('gpu_slot_1') && rs.read('gpu_slot_2'));
  // Cancel the third shared waiter, then queue solo before releasing either slot.
  const blocked = claims.find(p => !p.done); blocked.kill(); await blocked.result;
  const cancelled = claim(workers[3], 'solo');
  await until(() => !!rs.read('gpu_solo'));
  workers[3].kill();
  await until(() => cancelled.done, 3500);
  const cancelResult = await cancelled.result;
  assert.notEqual(cancelResult.code, 0); assert.match(cancelResult.error, /cancelled/i);
  assert.equal(rs.read('gpu_solo'), null, 'cancellation must release the pending solo reservation');
  workers[3] = spawn(process.execPath, ['-e', 'setInterval(()=>{},1000)'], { windowsHide: true });
  children.push(workers[3]);
  const timedSolo = client(['acquire', raceRoot, '1100', String(workers[3].pid), 'solo'], { PC_GPU_WAIT_SECONDS: '1' });
  await until(() => !!rs.read('gpu_solo'));
  await until(() => timedSolo.done, 3500);
  assert.match((await timedSolo.result).error, /admission timed out/i);
  assert.equal(rs.read('gpu_solo'), null, 'timeout must release the pending solo reservation');
  pass('pending solo releases on cancellation and on admission timeout');
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
  const refusedD = await client(['acquire', raceRoot, '847', String(process.pid), 'shared'], { PC_GPU_LANE: 'D' }).result;
  assert.notEqual(refusedD.code, 0); assert(/Lane D is code only/.test(refusedD.error));
  pass('real concurrent clients: two slots, solo priority/exclusion, pause on wait, stale PID, token-safe release, lane C and D refusal');

  capacity(raceRoot, 3);
  const lightLoad = await claim(workers[0]).result;
  assert.equal(lightLoad.code, 0, lightLoad.error);
  const heavyLoad = await claim(workers[1], 'shared', '2').result;
  assert.equal(heavyLoad.code, 0, heavyLoad.error);
  assert.equal(used(rs).length, 3);
  const waitingLight = claim(workers[3]);
  await sleep(400); assert(!waitingLight.done, 'weighted concurrent clients overbooked');
  capacity(raceRoot, 4);
  const raised = await waitingLight.result; assert.equal(raised.code, 0, raised.error);
  assert.equal(used(rs).length, 4);
  const weightedSolo = claim(workers[0], 'solo');
  await until(() => !!rs.read('gpu_solo'));
  await release(lightLoad.text); await release(heavyLoad.text);
  await sleep(300); assert(!weightedSolo.done, 'solo ignored the fourth slot');
  await release(raised.text);
  const sole = await weightedSolo.result; assert.equal(sole.code, 0, sole.error);
  await release(sole.text); assert.equal(used(rs).length, 0);
  const badWeight = await claim(workers[0], 'shared', '0').result;
  assert.notEqual(badWeight.code, 0); assert(/positive integer/.test(badWeight.error));
  pass('real concurrent clients: mixed weights fill capacity, a setting increase admits a waiter, solo drains every slot');

  // Issue 947: the four production lanes. Main and B may take GPU work; C and D refuse by flag or by folder.
  const lanes = [['', 'C:\\v\\board\\repo', ''], ['B', 'C:\\v\\board_b\\repo', ''], ['', 'C:\\v\\board_c\\repo', 'C'],
    ['', 'C:\\v\\board_d\\repo', 'D'], ['C', '/tmp/x', 'C'], ['D', '/tmp/x', 'D'], ['', '/home/v/board_d/repo/sub', 'D'], ['', '/tmp/board_dx', '']];
  for (const [flag, cwd, want] of lanes) assert.equal(codeOnlyLane(flag, cwd), want, `lane ${flag || '-'} at ${cwd}`);
  const codex = fs.readFileSync(path.join(pc, 'codex_issue.bat'), 'utf8');
  for (const [dir, board] of [['build_b', 'board'], ['build_c', 'board_b'], ['build_d', 'board_c'], ['build_e', 'board_d']]) {
    assert(codex.includes(`if /i "%LANEDIR%"=="${dir}" set "BOARD=${board}"`), `runner maps ${dir} to ${board}`);
  }
  pass('lane selection: main and B take GPU work, C and D refuse; each tools copy maps to its own board folder');

  for (const name of ['codex_issue', 'work_issue']) {
    const bat = fs.readFileSync(path.join(pc, name + '.bat'), 'utf8');
    assert(bat.includes('PC_GPU_ISSUE=%N%')); assert(bat.includes('PC_GPU_LANE=C')); assert(bat.includes('PC_GPU_LANE=D'));
    assert(fs.readFileSync(path.join(pc, name + '.ps1'), 'utf8').includes('tmo.bat'));
    assert(fs.readFileSync(path.join(pc, name + '.ps1'), 'utf8').includes('PC_GPU_WEIGHT=2'));
  }
  const watchdog = fs.readFileSync(path.join(pc, 'run_timeout.ps1'), 'utf8');
  assert(watchdog.includes('finally {\n  if ($gpuToken)'));
  const lb = fs.readFileSync(path.join(pc, 'jobs/look_bench.bat'), 'utf8');
  assert(!lb.includes('GEQ 60 goto gpufree'));
  assert(fs.readFileSync(path.resolve(pc, '../recipe/2_shape_ref.bat'), 'utf8').includes('PC_GPU_WEIGHT=2'));
  pass('runner context, generated task guidance, watchdog release and look bench wiring');

  if (process.platform === 'win32') await windowsWatchdog();
  else console.log('SKIP Windows watchdog integration (runs on Windows standing checks)');
  console.log(`PASS GPU slot checks (${passed} groups)`);
}

async function windowsWatchdog() {
  const home = path.join(root, 'watchdog');
  put(path.join(home, 'gpu_go.txt'), 'GPU cleared');
  const probe = path.join(home, 'probe.js');
  put(probe, `const fs = require('fs'); const { Slots } = require(${JSON.stringify(helper)});
const slots = new Slots(${JSON.stringify(home)});
const claims = slots.names().filter(n => n !== 'gpu_solo').map(n => slots.read(n)).filter(Boolean);
fs.writeFileSync(process.argv[2], JSON.stringify({ claims, weightEnv: process.env.PC_GPU_WEIGHT, modeEnv: process.env.PC_GPU_MODE }));
setTimeout(()=>process.exit(Number(process.argv[3])), Number(process.argv[4]));`);
  async function run(exe, args, extra = {}) {
    const p = spawn('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(pc, 'run_timeout.ps1')], {
      cwd: root, windowsHide: true, env: { ...process.env, PC_RUNNER_TEST: '1', PC_TEST_GPU_ROOT: home,
        PC_GPU_LANE: '', PC_GPU_MODE: 'shared', PC_GPU_WEIGHT: '', PC_GPU_ISSUE: '847', PC_GPU_WAIT_SECONDS: '300', PC_TEST_POLL_MS: '30',
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
  const notStarted = path.join(home, 'admission_started.txt');
  put(path.join(home, 'gpu_go.txt'), 'GPU not cleared');
  const admission = await run(process.execPath, `"${probe}" "${notStarted}" 0 0`, { PC_GPU_WAIT_SECONDS: '1' });
  assert.equal(admission.code, 126, admission.output);
  assert.match(admission.output, /GPU admission timed out after 1 seconds/);
  assert(!fs.existsSync(notStarted));
  put(path.join(home, 'gpu_go.txt'), 'GPU cleared');
  pass('Windows watchdog returns a separate admission failure without starting the command');
  for (const [code, delay, expect] of [[7, 0, 7], [0, 5000, 124]]) {
    const r = await run(process.execPath, `"${probe}" "${marker}" ${code} ${delay}`, { PC_GPU_WEIGHT: '2' });
    assert.equal(r.code, expect, r.output); assert(fs.existsSync(marker));
    const observed = JSON.parse(fs.readFileSync(marker, 'utf8'));
    assert.equal(observed.claims.length, 2); assert(observed.claims.every(c => c.weight === 2));
    assert(!observed.weightEnv && !observed.modeEnv, 'a forced load must not leak to nested commands');
    assert.equal(rs.read('gpu_slot_1'), null); assert.equal(rs.read('gpu_slot_2'), null);
  }
  const failed = await run(path.join(home, 'missing.exe'), '', { PC_GPU_WEIGHT: '2' });
  assert.equal(failed.code, 125, failed.output); assert.equal(rs.read('gpu_slot_1'), null);
  assert.equal(rs.read('gpu_slot_2'), null);
  const denied = await run(process.execPath, `"${probe}" "${path.join(home, 'denied.txt')}" 0 0`, { PC_GPU_LANE: 'C' });
  assert.notEqual(denied.code, 0); assert(!fs.existsSync(path.join(home, 'denied.txt')));
  const invalidMarker = path.join(home, 'invalid_started.txt');
  const invalid = await run(process.execPath, `"${probe}" "${invalidMarker}" 0 0`, { PC_GPU_WEIGHT: '0' });
  assert.notEqual(invalid.code, 0); assert(!fs.existsSync(invalidMarker));
  const fakeBlender = path.join(home, 'blender.exe');
  fs.linkSync(process.execPath, fakeBlender);
  const blended = await run(fakeBlender, `"${probe}" "${marker}" 0 0`, { PC_GPU_MODE: '' });
  assert.equal(blended.code, 0, blended.output);
  assert.equal(JSON.parse(fs.readFileSync(marker, 'utf8')).claims.length, 2, 'Blender must default to weight 2');
  put(path.join(home, 'gpu_go.txt'), 'GPU not cleared');
  const cpuOnly = await run(fakeBlender, `"${probe}" "${marker}" 0 0`, { PC_GPU_MODE: 'none', PC_GPU_WEIGHT: '2', PC_GPU_WAIT_SECONDS: '1' });
  assert.equal(cpuOnly.code, 0, cpuOnly.output);
  assert.doesNotMatch(cpuOnly.output, /GPU: .*claim/);
  assert.equal(JSON.parse(fs.readFileSync(marker, 'utf8')).claims.length, 0);
  put(path.join(home, 'gpu_go.txt'), 'GPU cleared');
  pass('Windows watchdog runs CPU-only Blender with zero claims while the GPU gate is closed');
  capacity(home, 3);
  const custom = await run(process.execPath, `"${probe}" "${marker}" 0 0`, { PC_GPU_WEIGHT: '3' });
  assert.equal(custom.code, 0, custom.output);
  assert.equal(JSON.parse(fs.readFileSync(marker, 'utf8')).claims.length, 3);
  assert.equal(used(rs).length, 0);
  pass('Windows watchdog uses weights and live capacity, clears nested overrides, releases on exit/timeout/start failure, refuses lane C and invalid weights');

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
