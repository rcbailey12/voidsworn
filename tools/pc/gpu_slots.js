'use strict';
// R293: shared capacity by load, or one solo measurement. Node 22, no packages.
// All tools copies read ROOT/gpu_slots.json: { "sharedSlots": 2 } (missing = 2).
// The watchdog owns the claim, so killing its tree leaves a reclaimable dead PID.
const fs = require('fs');
const path = require('path');
const net = require('net');
const crypto = require('crypto');
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const slotName = index => 'gpu_slot_' + index;
const realClock = { now: () => performance.now(), sleep };
// The longest admission wait. ship_job.bat defaults to it (issue 1174): on Nov 19 three helpers queued at once and the
// 300 s default failed them. Ship jobs run the helper from their own branch checkout, so raising this only helps once every
// ship branch carries the change.
const MAX_WAIT_SECONDS = 3600;
function positiveInteger(value, label) {
  const number = Number(value);
  if (!/^[0-9]+$/.test(String(value)) || !Number.isSafeInteger(number) || number < 1) {
    throw new Error(label + ' must be a positive integer');
  }
  return number;
}
const alive = pid => {
  if (!Number.isInteger(pid) || pid <= 0) return false;
  try { process.kill(pid, 0); return true; } catch (e) { return e.code === 'EPERM'; }
};

// An OS-owned localhost bind serializes short file transactions across ALL tools
// copies. The OS drops it after a crash. No lock or job files are ever deleted.
// No client connects and no data is sent. An occupied port fails closed (waits).
// clock: { now, sleep } (tests pass a fake one, so no test races the wall clock; issue 1174). When the deadline has passed,
// check() runs once more before the lock's own message: an admission that runs out while the lock is busy reports
// "admission timed out", whichever of the two clocks reads first (the Nov 19 CI flake at gpu_slots_tests.js:159).
async function transaction(fn, check = () => {}, deadline, clock = realClock) {
  if (deadline === undefined) deadline = clock.now() + 5000;
  for (;;) {
    check();
    if (clock.now() >= deadline) { check(); throw new Error('GPU slot lock timed out'); }
    const server = net.createServer(socket => socket.destroy());
    const bound = await new Promise((resolve, reject) => {
      server.once('error', e => e.code === 'EADDRINUSE' ? resolve(false) : reject(e));
      server.listen({ host: '127.0.0.1', port: 47847, exclusive: true }, () => resolve(true));
    });
    if (!bound) { await clock.sleep(25); continue; }
    try { check(); return fn(); } finally { await new Promise(resolve => server.close(resolve)); }
  }
}

class Slots {
  constructor(root, isAlive = alive) { this.root = root; this.isAlive = isAlive; }
  capacity() {
    const config = this.read('gpu_slots.json');
    // Only a missing file uses the default. A damaged setting fails closed.
    if (config === null && !fs.existsSync(path.join(this.root, 'gpu_slots.json'))) return 2;
    return positiveInteger(config?.sharedSlots, 'gpu_slots.json sharedSlots');
  }
  names() {
    try { return fs.readdirSync(this.root).filter(name => /^gpu_slot_[1-9][0-9]*$/.test(name)).concat('gpu_solo'); }
    catch (e) { if (e.code === 'ENOENT') return ['gpu_solo']; throw e; }
  }
  read(name) {
    try {
      const text = fs.readFileSync(path.join(this.root, name), 'utf8').trim();
      return text ? JSON.parse(text) : null;
    } catch (e) {
      if (e.code === 'ENOENT') return null;
      // A damaged holder file must never silently grant another worker a slot.
      throw e;
    }
  }
  write(name, value) {
    fs.mkdirSync(this.root, { recursive: true });
    fs.writeFileSync(path.join(this.root, name), value ? JSON.stringify(value) + '\n' : '');
  }
  cleared() {
    try { return /^GPU cleared(?:\s*:.*)?$/i.test(fs.readFileSync(path.join(this.root, 'gpu_go.txt'), 'utf8').split(/\r?\n/)[0].trim()); }
    catch (e) { if (e.code === 'ENOENT') return false; throw e; }
  }
  checkWeight(holder) {
    const capacity = this.capacity();
    const weight = positiveInteger(holder.weight ?? 1, 'GPU weight');
    if (holder.mode === 'shared' && weight > capacity) throw new Error(`GPU weight ${weight} exceeds shared capacity ${capacity}`);
    return { capacity, weight };
  }
  step(holder, waiterPid = holder.pid) {
    const { capacity, weight } = this.checkWeight(holder);
    const state = this.names().map(name => {
      const item = this.read(name);
      if (item && !this.isAlive(item.pid)) { this.write(name, null); return null; }
      return item;
    });
    if (!this.isAlive(holder.pid)) throw new Error('GPU admission cancelled: owner exited');
    if (!this.cleared()) return null;
    // Include claims above a lowered capacity until they exit or are reclaimed.
    const occupied = state.slice(0, -1).filter(Boolean);
    const pending = state[state.length - 1];
    if (holder.mode === 'solo') {
      if (pending && pending.token !== holder.token) return null;
      // Reserve priority before draining existing shared workers. New workers wait.
      // While draining, the waiting helper owns the reservation. If it is killed
      // outright, the next caller can reclaim it even if the watchdog is alive.
      if (!pending) this.write('gpu_solo', { ...holder, pid: waiterPid });
      if (occupied.length) return null;
      this.write('gpu_slot_1', holder);
      this.write('gpu_solo', holder);
      return holder;
    }
    if (pending || occupied.some(item => item && item.mode === 'solo')) return null;
    if (occupied.length + weight > capacity) return null;
    // One holder occupies every unit of its weight, with admission serialized.
    // Keep the existing file names so claims survive tools updates.
    const free = [];
    for (let index = 1; free.length < weight; index++) {
      const name = slotName(index);
      if (!this.read(name)) free.push(name);
    }
    for (const name of free) this.write(name, holder);
    return holder;
  }
  release(token) {
    for (const name of this.names()) if (this.read(name)?.token === token) this.write(name, null);
  }
}

function weightFor(exe, requested = '', mode = 'shared') {
  if (!mode || mode === 'none') return 0;
  if (requested !== '') return positiveInteger(requested, 'PC_GPU_WEIGHT');
  return /^blender(?:\.exe)?$/i.test(path.win32.basename(exe)) ? 2 : 1;
}

// Benchmarks take solo themselves, including direct tmo launches. Follow scene
// and script resources, so a scene's script cannot hide timing behind a .tscn.
function modeFor(exe, args, cwd = process.cwd(), requested = '') {
  const godot = /^(?:Godot|Voidsworn).*\.exe$/i.test(path.win32.basename(exe)) || /^godot(?:[34])?$/i.test(path.basename(exe));
  const blender = /^blender(?:\.exe)?$/i.test(path.win32.basename(exe));
  if (!godot && !blender) return requested === 'solo' || requested === 'shared' ? requested : '';
  if (godot && /(?:^|\s)--headless(?:\s|$)/i.test(args)) return '';
  if (requested === 'solo') return 'solo';
  // Only explicitly marked CPU-only Blender steps can skip a Blender claim.
  // Godot still detects GPU work and takes solo for timing scripts.
  if (blender) return requested === 'none' ? '' : 'shared';
  // Known benches remain solo even if their checkout has not been prepared yet.
  if (/--(?:bench|benchmark|measure)\b|bench209|scene_gate|bench\d|frame[_-]?time|performance|perf_probe/i.test(args) && !/--still\b/.test(args)) return 'solo';
  const project = /--path\s+(?:"([^"]+)"|(\S+))/.exec(args);
  const base = project ? path.resolve(cwd, project[1] || project[2]) : cwd;
  const visited = new Set();
  function measures(resource) {
    if (visited.has(resource)) return false;
    visited.add(resource);
    if (visited.size > 256) throw new Error('GPU resource scan too large; use PC_GPU_MODE=solo');
    let source;
    try { source = fs.readFileSync(resource.startsWith('res://') ? path.join(base, resource.slice(6)) : path.resolve(cwd, resource), 'utf8'); }
    catch (e) { if (e.code === 'ENOENT') return false; throw e; }
    source = source.replace(/^\s*#.*$/gm, '');
    if (/TIME_(?:PROCESS|FPS)|get_frame_setup_time_cpu|get_ticks_usec|frame[_ ]?(?:ms|times?)|gpu_ms|percentile|median/i.test(source)) return true;
    // Follow scene attachments, not every production preload in a capture script.
    // Effects use microsecond clocks for animation even when no speed is measured.
    return resource.endsWith('.tscn') && [...source.matchAll(/res:\/\/[^"'\s)]+\.(?:gd|tscn)/g)].some(m => measures(m[0]));
  }
  const resources = [...args.matchAll(/res:\/\/[^"'\s]+\.(?:gd|tscn)/g)].map(m => m[0]);
  const script = /--script\s+(?:"([^"]+)"|(\S+))/.exec(args);
  if (script) resources.push(script[1] || script[2]);
  if (!resources.length) {
    try {
      const config = fs.readFileSync(path.join(base, 'project.godot'), 'utf8');
      const main = /^run\/main_scene="(res:\/\/[^"\r\n]+)"/m.exec(config);
      if (main) resources.push(main[1]);
    } catch (e) { if (e.code !== 'ENOENT') throw e; }
  }
  return resources.some(measures) ? 'solo' : 'shared';
}

// Lanes C (board_c) and D (board_d) are code only (R268, R301). The runner flag or the working folder is enough (issue 947).
function codeOnlyLane(flag, cwd) {
  if (flag === 'C' || flag === 'D') return flag;
  const m = /(?:^|[\\/])board_([cd])(?:[\\/]|$)/i.exec(cwd || '');
  return m ? m[1].toUpperCase() : '';
}

async function main() {
  const [action, root, issue, pid, mode, weight = '1'] = process.argv.slice(2);
  if (action === 'classify') {
    const input = JSON.parse(fs.readFileSync(0, 'utf8').replace(/^\uFEFF/, ''));
    const mode = modeFor(input.exe, input.args, input.cwd, input.requested);
    console.log(JSON.stringify({ mode, weight: weightFor(input.exe, input.weight, mode) }));
    return;
  }
  if (!root) throw new Error('GPU root is required');
  const slots = new Slots(root);
  if (action === 'release') { await transaction(() => slots.release(issue)); return; }
  if (action !== 'acquire' || !['shared', 'solo'].includes(mode)) throw new Error('Usage: gpu_slots.js acquire ROOT ISSUE PID shared|solo [WEIGHT]');
  const lane = codeOnlyLane(process.env.PC_GPU_LANE, process.cwd());
  if (lane) throw new Error(`Lane ${lane} is code only; GPU work refused`);
  const holder = { token: crypto.randomUUID(), issue, pid: Number(pid), mode,
    weight: positiveInteger(weight, 'GPU weight'), started: new Date().toISOString() };
  const waitSeconds = positiveInteger(process.env.PC_GPU_WAIT_SECONDS ?? '300', 'PC_GPU_WAIT_SECONDS');
  if (waitSeconds > MAX_WAIT_SECONDS) throw new Error(`PC_GPU_WAIT_SECONDS must be at most ${MAX_WAIT_SECONDS}`);
  slots.checkWeight(holder); // Fail even if the go gate is closed or the slot lock is busy.
  let cancelled = false;
  const cancel = () => { cancelled = true; };
  process.on('SIGINT', cancel);
  process.on('SIGTERM', cancel);
  try {
    await admit(slots, holder, { waitSeconds, cancelled: () => cancelled, onWait: () => console.log('WAIT') });
    console.log(holder.token);
  } finally {
    process.off('SIGINT', cancel);
    process.off('SIGTERM', cancel);
  }
}

// Wait for a claim until waitSeconds pass. Resolves with the holder once it is written; throws "admission timed out" or
// "admission cancelled" (owner exited, or cancelled() turned true) and then releases anything it reserved. tx and clock are
// for tests: tx defaults to the localhost lock, clock to the real one.
async function admit(slots, holder, { waitSeconds, cancelled = () => false, onWait = () => {}, waiterPid = process.pid,
  clock = realClock, tx = transaction } = {}) {
  const deadline = clock.now() + waitSeconds * 1000;
  let handedOff = false, touched = false;
  const check = () => {
    if (cancelled() || !slots.isAlive(holder.pid)) throw new Error('GPU admission cancelled');
    if (clock.now() >= deadline) throw new Error(`GPU admission timed out after ${waitSeconds} seconds`);
  };
  let heartbeat = clock.now();
  try {
    for (;;) {
      const claim = await tx(() => { touched = true; return slots.step(holder, waiterPid); }, check, deadline, clock);
      check();
      if (claim) { handedOff = true; return claim; }
      if (clock.now() - heartbeat >= 60000) { onWait(); heartbeat = clock.now(); }
      await clock.sleep(Math.min(250, Math.max(0, deadline - clock.now())));
    }
  } finally {
    try {
      if (!handedOff && touched) await tx(() => slots.release(holder.token), undefined, undefined, clock);
    } catch (e) { console.error('GPU claim cleanup: ' + e.message); }
  }
}
if (require.main === module) main().catch(e => { console.error('GPU claim: ' + e.message); process.exitCode = 1; });
module.exports = { Slots, modeFor, weightFor, transaction, codeOnlyLane, admit, MAX_WAIT_SECONDS };
