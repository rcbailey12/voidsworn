'use strict';
// Issue 1194: test this checkout's tmo.bat, never the PC's installed tools_live copy.
process.env.TMO_OWN_COPY = '1';
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
const { Slots, modeFor, weightFor, claimLabel, codeOnlyLane, admit, transaction, MAX_WAIT_SECONDS } = require(helper);
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
// Issue 1174: a fake clock for every admission timeout, so no test races the wall clock. Time moves only when the code
// under test sleeps; each fake sleep still yields to the event loop. onSleep sees the state while the waiter waits.
function fakeClock(onSleep = () => {}) {
  const clock = { t: 0, sleeps: 0, now: () => clock.t,
    sleep: async ms => { clock.sleeps++; clock.t += Math.max(ms, 1); onSleep(); await new Promise(r => setImmediate(r)); } };
  return clock;
}
const fails = async (promise, pattern) => {
  try { await promise; } catch (e) { assert.match(e.message, pattern); return; }
  throw new Error('expected a failure matching ' + pattern);
};
const identity = pid => ({ pid, startTime: 'fake time ' + pid, exe: 'fake.exe' });
const holder = (pid, mode = 'shared') => ({ ...identity(pid), mode, token: String(pid), issue: '847', started: 'fake start' });
const capacity = (root, count) => put(path.join(root, 'gpu_slots.json'), JSON.stringify({ sharedSlots: count }));
const used = slots => slots.names().filter(name => name !== 'gpu_solo' && slots.read(name));
async function main() {
  const fakeRoot = path.join(root, 'fake');
  const live = new Set([1, 2, 3, 4]);
  const replacements = new Map();
  const identify = (pids, legacyPids = []) => new Map([...pids, ...legacyPids].filter(pid => live.has(pid)).map(pid => [pid, replacements.get(pid) || identity(pid)]));
  const slots = new Slots(fakeRoot, identify);
  assert.equal(await slots.step(holder(1)), null, 'missing go must block');
  put(path.join(fakeRoot, 'gpu_go.txt'), 'GPU not cleared\nGPU cleared');
  assert.equal(await slots.step(holder(1)), null);
  put(path.join(fakeRoot, 'gpu_go.txt'), 'GPU cleared: Ryan, "cpu and gpu are yours again"\n');
  assert(await slots.step(holder(1))); assert(await slots.step(holder(2)));
  assert.equal(await slots.step(holder(3)), null);
  assert.equal(slots.read('gpu_slot_1').issue, '847');
  assert.equal(slots.read('gpu_slot_2').started, 'fake start');
  pass('fake processes: exactly two slots, holder issue/start, missing and withdrawn go block');
  assert.equal(await slots.step(holder(3, 'solo')), null);
  await slots.release('1');
  assert.equal(await slots.step(holder(4)), null, 'pending solo must block new shared work');
  assert.equal(await slots.step(holder(3, 'solo')), null, 'solo must drain the second slot too');
  await slots.release('2');
  assert(await slots.step(holder(3, 'solo')));
  assert.equal(await slots.step(holder(4)), null);
  await slots.release('3'); assert(await slots.step(holder(4)));
  await slots.release('old token'); assert(slots.read('gpu_slot_1'));
  live.delete(4); assert(await slots.step(holder(1)));
  await slots.release('1');
  slots.write('gpu_solo', holder(4, 'solo'));
  assert(await slots.step(holder(2)), 'dead solo waiter must be reclaimed');
  pass('fake processes: solo drains both, blocks arrivals, releases, and reclaims dead slots and waiters');
  await slots.release('2');
  put(path.join(fakeRoot, 'gpu_go.txt'), 'GPU not cleared');
  assert.equal(await slots.step(holder(3, 'solo')), null);
  assert.equal(slots.read('gpu_solo'), null, 'closed gate must not reserve a new claim');
  pass('gaming gate also blocks solo admission');

  put(path.join(fakeRoot, 'gpu_go.txt'), 'GPU cleared');
  const heavy = { ...holder(2), weight: 2 };
  assert(await slots.step(holder(1)));
  assert.equal(await slots.step(heavy), null, 'weight 2 cannot fit in one free slot');
  assert.equal(used(slots).length, 1, 'a waiting heavy job must not hold a partial claim');
  capacity(fakeRoot, 3);
  assert(await new Slots(fakeRoot, identify).step(heavy), 'other tools copies must read the same raised capacity');
  assert.equal(used(slots).length, 3);
  await slots.release('2'); assert.equal(used(slots).length, 1, 'release must clear the whole weight');
  assert(await slots.step(holder(2))); assert(await slots.step(holder(3)));
  live.add(4);
  assert.equal(await slots.step(holder(4)), null);
  capacity(fakeRoot, 4);
  assert(await slots.step(holder(4)), 'four light jobs must fit after raising the setting');
  capacity(fakeRoot, 2);
  await slots.release('1'); await slots.release('2');
  assert.equal(await slots.step(holder(1)), null, 'lowering capacity must count claims in higher slot files');
  assert.equal(await slots.step(holder(1, 'solo')), null);
  await slots.release('3');
  assert.equal(await slots.step(holder(1, 'solo')), null, 'solo must drain slot 4 even after lowering capacity');
  await slots.release('4'); assert(await slots.step(holder(1, 'solo')));
  capacity(fakeRoot, 4);
  assert.equal(await slots.step(heavy), null, 'raising capacity must never bypass solo');
  await slots.release('1');
  assert(await slots.step(heavy)); live.delete(2);
  assert(await slots.step(holder(1))); assert.equal(used(slots).length, 1, 'dead weighted claims must be reclaimed in full');
  await slots.release('1'); live.add(2);
  capacity(fakeRoot, 1);
  await assert.rejects(slots.step(heavy), /exceeds.*capacity/, 'a job larger than total capacity must fail immediately');
  assert.equal(slots.read('gpu_solo'), null, 'heavy shared waiters must not reserve solo');
  capacity(fakeRoot, 3);
  assert(await slots.step(heavy)); await slots.release('2');
  pass('weighted load: no partial admission, live raised capacity, lowered capacity, solo across all slots, dead weighted claims');

  for (const count of [0, -1, 1.5, '2 jobs', null, true, Number.MAX_SAFE_INTEGER + 1]) {
    capacity(fakeRoot, count);
    await assert.rejects(slots.step(holder(1)), /positive integer/);
  }
  for (const content of ['', 'null', '{"sharedSlots":', '{}']) {
    put(path.join(fakeRoot, 'gpu_slots.json'), content);
    await assert.rejects(slots.step(holder(1)));
  }
  capacity(fakeRoot, 4);
  for (const weight of [0, -1, 1.5, '2 jobs', true]) {
    await assert.rejects(slots.step({ ...holder(1), weight }), /positive integer/);
  }
  pass('invalid capacity and weights fail closed');

  const recoveryRoot = path.join(root, 'recovery');
  const recovering = new Slots(recoveryRoot, identify);
  put(path.join(recoveryRoot, 'gpu_go.txt'), 'GPU cleared');
  capacity(recoveryRoot, 2);
  for (const name of ['gpu_slot_1', 'gpu_solo']) put(path.join(recoveryRoot, name), '{"half":');
  put(path.join(recoveryRoot, 'gpu_slot_2.tmp-interrupted'), '{"half":');
  assert(await recovering.step(holder(1)));
  assert.equal(recovering.read('gpu_slot_1').pid, 1);
  const archives = fs.readdirSync(recoveryRoot).filter(name => /^gpu_slot_corrupt_/.test(name));
  assert.equal(archives.length, 2);
  for (const name of archives) assert.equal(fs.readFileSync(path.join(recoveryRoot, name), 'utf8'), '{"half":');
  assert.equal(fs.readFileSync(path.join(recoveryRoot, 'gpu_slot_2.tmp-interrupted'), 'utf8'), '{"half":');
  const rename = fs.renameSync;
  try {
    fs.renameSync = (source, target) => {
      assert.equal(target, path.join(recoveryRoot, 'gpu_slot_1'));
      assert.equal(path.dirname(source), recoveryRoot);
      assert.equal(JSON.parse(fs.readFileSync(source, 'utf8')).pid, 2);
      assert.equal(recovering.read('gpu_slot_1').pid, 1);
      throw new Error('simulated interruption before rename');
    };
    assert.throws(() => recovering.write('gpu_slot_1', holder(2)), /interruption/);
  } finally { fs.renameSync = rename; }
  assert.equal(recovering.read('gpu_slot_1').pid, 1);
  pass('interrupted writes leave the previous claim whole and damaged slot and solo files are archived');

  for (const changed of [{ startTime: 'new start' }, { exe: 'service.exe' }]) {
    replacements.set(1, { ...identity(1), ...changed });
    assert(await recovering.step({ ...holder(2), weight: 2 }), 'reused owner PID must be reclaimed');
    await recovering.release('2');
    replacements.delete(1);
    assert(await recovering.step(holder(1)));
  }
  await recovering.release('1');
  assert(await recovering.step({ ...holder(1), weight: 2 }));
  // Only one copy was updated when the writer died. The surviving child holds both units.
  recovering.write('gpu_slot_1', { ...recovering.read('gpu_slot_1'), child: identity(2) });
  live.delete(1);
  assert.equal(await recovering.step(holder(3)), null, 'watchdog death must not free its GPU child');
  await assert.rejects(recovering.release('1'), /live child/);
  await recovering.update('1', 'orphan', [identity(2), identity(3)]);
  assert.equal(recovering.read('gpu_slot_2').state, 'orphaned_child');
  replacements.set(2, { ...identity(2), startTime: 'reused child PID' });
  const nextSolo = { ...holder(2, 'solo'), ...replacements.get(2) };
  assert.equal(await recovering.step(nextSolo), null, 'one survivor still holds the whole claim');
  live.delete(3);
  assert(await recovering.step(nextSolo), 'dead survivors must free the claim');
  await recovering.release('2');
  pass('PID reuse, watchdog death, and orphaned child claims use the full process identity');

  const legacyRoot = path.join(root, 'legacy');
  const legacy = new Slots(legacyRoot, identify);
  put(path.join(legacyRoot, 'gpu_go.txt'), 'GPU cleared');
  capacity(legacyRoot, 1);
  const oldClaim = { pid: 4, token: 'old-format', issue: '847:gpu', mode: 'shared', weight: 1, started: 'old time' };
  live.add(1);
  for (const name of ['gpu_slot_1', 'gpu_solo']) {
    live.add(4);
    legacy.write(name, { ...oldClaim, mode: name === 'gpu_solo' ? 'solo' : 'shared' });
    assert.equal(await legacy.step(holder(1)), null, 'a live old-format PID must block admission');
    assert.equal(legacy.read(name).token, oldClaim.token);
    live.delete(4);
    assert(await legacy.step(holder(1)), 'a dead old-format PID must free the claim');
    await legacy.release('1');
  }
  pass('old-format shared and solo claims stay held until their PID exits');

  await lookupContention();

  assert.equal(claimLabel(' 847 ', 'job', '', ''), '847');
  assert.equal(claimLabel(' ', ' opus1193 ', '', ''), 'opus1193');
  assert.equal(claimLabel('', '', 'blender.exe', '-P "C:\\Ship Tools\\render.py" -- out'), 'render.py');
  assert.equal(claimLabel('', '', 'godot.exe', '--script res://fx/check.gd'), 'check.gd');
  assert.equal(claimLabel('', '', 'job.cmd', ''), 'job.cmd');
  await assert.rejects(recovering.step({ ...holder(2), issue: ' ' }), /requires a label/);
  const anonymous = await client(['acquire', recoveryRoot, '', String(process.pid), 'shared'], { JOB_DIR: '' }).result;
  assert.notEqual(anonymous.code, 0); assert.match(anonymous.error, /requires a label/);
  assert.equal(used(recovering).length, 0);
  pass('claims use issue, job directory or script and refuse empty labels');

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
  try { await until(() => tooHeavy.done, 20000); }
  catch { throw new Error('impossible GPU weight waited for admission'); }
  assert.match((await tooHeavy.result).error, /exceeds.*capacity/i);
  // The go gate closed: admission ends with "admission timed out" after exactly its own wait, on the fake clock.
  const closedSlots = new Slots(closed, pids => new Map(pids.map(pid => [pid, identity(pid)])));
  const gateClock = fakeClock();
  await fails(admit(closedSlots, { ...holder(process.pid), token: 'gate', weight: 1 }, { waitSeconds: 1, clock: gateClock }),
    /admission timed out after 1 seconds/);
  assert(gateClock.t >= 1000 && gateClock.t < 1300, 'timed out at ' + gateClock.t + ' fake ms, not after its 1 s wait');
  pass('GPU admission fails promptly at impossible weight and times out with the go gate closed');
  // The slot lock held for the whole wait: the lock's loop reports the admission timeout, never its own message, however
  // the two deadline readings fall (the Nov 19 CI failure said "GPU slot lock timed out" at the old line 159).
  const heldLock = net.createServer();
  await new Promise((resolve, reject) => {
    heldLock.once('error', reject); heldLock.listen(47847, '127.0.0.1', resolve);
  });
  try {
    const lockClock = fakeClock();
    await fails(admit(closedSlots, { ...holder(2), token: 'lock', weight: 1 }, { waitSeconds: 1, clock: lockClock }),
      /admission timed out after 1 seconds/);
    assert(lockClock.t >= 1000, 'gave up on a busy lock before the wait ran out');
    // The race itself: check() reads the clock just before the deadline, the lock's own reading lands on it.
    const reads = [999];
    const edgeClock = { now: () => (reads.length ? reads.shift() : 1000), sleep: async () => {} };
    const edgeCheck = () => { if (edgeClock.now() >= 1000) throw new Error('GPU admission timed out after 1 seconds'); };
    await fails(transaction(() => 'never', edgeCheck, 1000, edgeClock), /admission timed out/);
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
  await until(() => cancelled.done, 20000);
  const cancelResult = await cancelled.result;
  assert.notEqual(cancelResult.code, 0); assert.match(cancelResult.error, /cancelled/i);
  assert.equal(rs.read('gpu_solo'), null, 'cancellation must release the pending solo reservation');
  workers[3] = spawn(process.execPath, ['-e', 'setInterval(()=>{},1000)'], { windowsHide: true });
  children.push(workers[3]);
  // Two shared slots stay held, so a solo waiter reserves gpu_solo and drains; on the fake clock it times out and must
  // release the reservation it made.
  let sawReservation = false;
  const soloClock = fakeClock(() => { if (rs.read('gpu_solo')) sawReservation = true; });
  const waiterIdentity = (await rs.identify([workers[3].pid])).get(workers[3].pid);
  await fails(admit(rs, { ...holder(workers[3].pid, 'solo'), ...waiterIdentity, token: 'timed-solo', weight: 1 },
    { waitSeconds: 1, clock: soloClock }), /admission timed out/);
  assert(sawReservation, 'the solo waiter never reserved gpu_solo');
  assert.equal(rs.read('gpu_solo'), null, 'timeout must release the pending solo reservation');
  pass('pending solo releases on cancellation and on admission timeout');
  // Issue 1174: ship_job.bat waits up to 3600 s for the GPU; more than that is refused before any waiting.
  assert.equal(MAX_WAIT_SECONDS, 3600);
  const tooLong = await client(['acquire', closed, '1100', String(process.pid), 'shared'], { PC_GPU_WAIT_SECONDS: '3601' }).result;
  assert.notEqual(tooLong.code, 0); assert.match(tooLong.error, /at most 3600/);
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

  // Issues 947 and 2057: main and B may take GPU work; C to F refuse by flag or by folder.
  const lanes = [['', 'C:\\v\\board\\repo', ''], ['B', 'C:\\v\\board_b\\repo', ''], ['', 'C:\\v\\board_c\\repo', 'C'],
    ['', 'C:\\v\\board_d\\repo', 'D'], ['', 'C:\\v\\board_e\\repo', 'E'], ['', 'C:\\v\\board_f\\repo', 'F'],
    ['C', '/tmp/x', 'C'], ['D', '/tmp/x', 'D'], ['E', '/tmp/x', 'E'], ['F', '/tmp/x', 'F'],
    ['', '/home/v/board_f/repo/sub', 'F'], ['', '/tmp/board_fx', '']];
  for (const [flag, cwd, want] of lanes) assert.equal(codeOnlyLane(flag, cwd), want, `lane ${flag || '-'} at ${cwd}`);
  const codex = fs.readFileSync(path.join(pc, 'codex_issue.bat'), 'utf8');
  for (const [dir, board] of [['build_b', 'board'], ['build_c', 'board_b'], ['build_d', 'board_c'], ['build_e', 'board_d'],
    ['build_f', 'board_e'], ['build_g', 'board_f']]) {
    assert(codex.includes(`if /i "%LANEDIR%"=="${dir}" set "BOARD=${board}"`), `runner maps ${dir} to ${board}`);
  }
  pass('lane selection: main and B take GPU work, C to F refuse; each tools copy maps to its own board folder');

  for (const name of ['codex_issue', 'work_issue']) {
    const bat = fs.readFileSync(path.join(pc, name + '.bat'), 'utf8');
    assert(bat.includes('PC_GPU_ISSUE=%N%'));
    for (const lane of 'CDEF') assert(bat.includes('PC_GPU_LANE=' + lane));
    assert(fs.readFileSync(path.join(pc, name + '.ps1'), 'utf8').includes('tmo.bat'));
    assert(fs.readFileSync(path.join(pc, name + '.ps1'), 'utf8').includes('PC_GPU_WEIGHT=2'));
  }
  const lb = fs.readFileSync(path.join(pc, 'jobs/look_bench.bat'), 'utf8');
  assert(!lb.includes('GEQ 60 goto gpufree'));
  assert(fs.readFileSync(path.resolve(pc, '../recipe/2_shape_ref.bat'), 'utf8').includes('PC_GPU_WEIGHT=2'));
  pass('runner context, generated task guidance, watchdog release and look bench wiring');

  if (process.platform === 'win32') await windowsWatchdog();
  else console.log('SKIP Windows watchdog integration (runs on Windows standing checks)');
  console.log(`PASS GPU slot checks (${passed} groups)`);
}

async function lookupContention() {
  const home = path.join(root, 'lookup');
  put(path.join(home, 'gpu_go.txt'), 'GPU cleared');
  capacity(home, 2);
  const lookupTimes = [];
  const clock = fakeClock(() => assert.equal(slots.read('gpu_slot_1').token, '1'));
  const slots = new Slots(home, pids => {
    lookupTimes.push(clock.now());
    if (lookupTimes.length === 1) throw new Error('simulated process lookup timeout');
    return new Map(pids.filter(pid => pid !== 1).map(pid => [pid, identity(pid)]));
  });
  slots.write('gpu_slot_1', holder(1));
  slots.write('gpu_slot_2', holder(2));
  await admit(slots, holder(3), { waitSeconds: 3, clock });
  assert.deepEqual(lookupTimes, [0, 1000], 'failed lookup must leave the claim and retry a second later');
  await slots.release('3');

  // Three waiters all see a dead watchdog in the old snapshot. During their
  // lookups the child is registered and another holder releases its slot.
  const pending = [];
  const waitingSlots = new Slots(home, pids => new Promise(resolve => {
    pending.push(() => resolve(new Map(pids.filter(pid => pid !== 1).map(pid => [pid, identity(pid)]))));
  }));
  slots.write('gpu_slot_1', holder(1));
  const waiters = [3, 4, 5].map(pid => waitingSlots.step(holder(pid)));
  await until(() => pending.length === waiters.length);
  await slots.update('1', 'track', [identity(6)]);
  await slots.release('2');
  for (const finish of pending) finish();
  assert.deepEqual(await Promise.all(waiters), [null, null, null], 'stale lookups must not change claims');
  assert.equal(slots.read('gpu_slot_1').child.pid, 6);
  assert.equal(slots.read('gpu_slot_2'), null);
  assert.equal(await slots.step({ ...holder(3), weight: 2 }), null, 'registered child must still hold its slot');

  let releaseChecks = 0;
  const releaseClock = fakeClock(() => assert.equal(slots.read('gpu_slot_1').child.pid, 6));
  const releasing = new Slots(home, () => {
    if (releaseChecks++ === 0) throw new Error('simulated process lookup timeout');
    return new Map();
  });
  await releasing.release('1', { clock: releaseClock });
  assert.equal(releaseChecks, 2);
  assert.equal(slots.read('gpu_slot_1'), null);
  pass('slow lookups leave track and release free, changed snapshots retry, and failed lookups never clear a claim');
}

async function windowsWatchdog() {
  const home = path.join(root, 'watchdog');
  put(path.join(home, 'gpu_go.txt'), 'GPU cleared');
  function fakeExecutable(source, name) {
    const target = path.join(home, name);
    // Always copy: hard links to node.exe and blender.exe left in kept TEMP scratch pushed node.exe to NTFS's
    // 1023-link limit on the PC (issue 1854), and a running exe's links cannot be deleted.
    fs.copyFileSync(source, target);
    return target;
  }
  const probe = path.join(home, 'probe.js');
  put(probe, `const fs = require('fs'); const { Slots } = require(${JSON.stringify(helper)});
const slots = new Slots(${JSON.stringify(home)});
const claims = slots.names().filter(n => n !== 'gpu_solo').map(n => slots.read(n)).filter(Boolean);
const marker = process.argv[2];
fs.writeFileSync(marker + '.tmp', JSON.stringify({ claims, pid: process.pid, weightEnv: process.env.PC_GPU_WEIGHT, modeEnv: process.env.PC_GPU_MODE }));
fs.renameSync(marker + '.tmp', marker);
setTimeout(()=>process.exit(Number(process.argv[3])), Number(process.argv[4]));`);
  function start(exe, args, extra = {}, seconds = 1) {
    const p = spawn('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(pc, 'run_timeout.ps1')], {
      cwd: root, windowsHide: true, env: { ...process.env, PC_RUNNER_TEST: '1', PC_TEST_GPU_ROOT: home,
        PC_GPU_LANE: '', PC_GPU_MODE: 'shared', PC_GPU_WEIGHT: '', PC_GPU_ISSUE: '847', PC_GPU_WAIT_SECONDS: '300', PC_TEST_POLL_MS: '30',
        PC_TEST_TIMEOUT_LOG: path.join(home, 'timeouts.log'), TMO_REPO: '', TMO_OUT: '', TMO_LOG: '',
        JOB_DIR: '', TMO_ARGS: `${seconds} "${exe}" ${args}`, ...extra }
    });
    children.push(p);
    let output = ''; p.stdout.on('data', b => { output += b; }); p.stderr.on('data', b => { output += b; });
    p.result = new Promise((resolve, reject) => {
      p.on('error', reject); p.on('exit', code => resolve({ code, output }));
    });
    return p;
  }
  const run = (exe, args, extra) => start(exe, args, extra).result;
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
    assert(observed.claims.every(c => c.child?.pid === observed.pid && c.child.startTime && c.child.exe),
      'the child must be registered in both slots before it runs');
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
  const fakeBlender = fakeExecutable(process.execPath, 'blender.exe');
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

  for (const [jobDir, label] of [['job 1193', 'job 1193'], ['', 'probe.js']]) {
    const named = await run(process.execPath, `"${probe}" "${marker}" 0 0`, { PC_GPU_ISSUE: '', JOB_DIR: jobDir });
    assert.equal(named.code, 0, named.output);
    assert.equal(JSON.parse(fs.readFileSync(marker, 'utf8')).claims[0].issue, label);
  }
  const anonymous = await run(process.execPath, '-e "process.exit(99)"', { PC_GPU_ISSUE: ' ' });
  assert.equal(anonymous.code, 126, anonymous.output);
  assert.match(anonymous.output, /set PC_GPU_ISSUE or JOB_DIR/);
  assert.equal(used(rs).length, 0);
  pass('Windows watchdog resolves a missing issue label before launching and refuses anonymous launches');

  capacity(home, 1);
  const brokenKiller = path.join(home, 'failed_kill.cmd');
  put(brokenKiller, '@echo off\r\nexit /b 1\r\n');
  for (const failedKill of [false, true]) {
    const lifeMarker = path.join(home, failedKill ? 'failed_kill.json' : 'dead_watchdog.json');
    const extra = failedKill ? { PC_TEST_TASKKILL: brokenKiller, PC_TEST_FAIL_KILL: '1' } : {};
    const watchdog = start(process.execPath, `"${probe}" "${lifeMarker}" 0 10000`, extra, failedKill ? 1 : 30);
    await until(() => fs.existsSync(lifeMarker));
    const { pid: childPid } = JSON.parse(fs.readFileSync(lifeMarker, 'utf8'));
    try {
      if (!failedKill) watchdog.kill();
      const stopped = await watchdog.result;
      assert.notEqual(stopped.code, 0, stopped.output);
      assert.doesNotThrow(() => process.kill(childPid, 0), 'the probe must outlive its watchdog');
      const held = rs.read('gpu_slot_1');
      if (failedKill) {
        assert.match(stopped.output, /KILL FAILED: surviving PIDs/);
        assert.equal(held.state, 'orphaned_child');
        assert.deepEqual(held.survivors, [held.child]);
        assert.match(fs.readFileSync(path.join(home, 'timeouts.log'), 'utf8'), /retaining claim .* as orphaned_child/);
      } else { assert.equal(held.child.pid, childPid); }
      const release = await client(['release', home, held.token]).result;
      assert.notEqual(release.code, 0); assert.match(release.error, /live child/);
      const blocked = await client(['acquire', home, 'other', String(process.pid), 'shared'], { PC_GPU_WAIT_SECONDS: '1' }).result;
      assert.notEqual(blocked.code, 0); assert.match(blocked.error, /admission timed out/);
    } finally {
      try { process.kill(childPid); } catch (e) { if (e.code !== 'ESRCH') throw e; }
    }
    const next = await client(['acquire', home, 'other', String(process.pid), 'shared']).result;
    assert.equal(next.code, 0, next.error);
    assert.equal((await client(['release', home, next.text]).result).code, 0);
    assert.equal(rs.read('gpu_slot_1'), null);
  }
  pass('Windows watchdog loss and failed kills hold capacity until the real surviving child exits');

  // Node under a different name is a fake Godot executable: it writes a marker instead of
  // rendering. This exercises automatic classification through the real watchdog.
  const fakeGodot = fakeExecutable(fakeBlender, 'Godot_fake.exe');
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
