'use strict';
// R293: shared capacity by load, or one solo measurement. Node 22, no packages.
// All tools copies read ROOT/gpu_slots.json: { "sharedSlots": 2 } (missing = 2).
// A claim follows the watchdog and its GPU child until both are gone.
const fs = require('fs');
const path = require('path');
const net = require('net');
const crypto = require('crypto');
const { execFile } = require('child_process');
const { promisify } = require('util');
const queryProcess = promisify(execFile);
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const slotName = index => 'gpu_slot_' + index;
const realClock = { now: () => performance.now(), sleep };
const POLL_MS = 1000;
const RELEASE_WAIT_MS = 30000;
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
const validPid = pid => Number.isSafeInteger(pid) && pid > 0 && pid <= 0x7fffffff;
const validIdentity = item => validPid(item?.pid) && typeof item.startTime === 'string' && item.startTime &&
  typeof item.exe === 'string' && item.exe;
const legacyIdentity = item => item.startTime === undefined && item.exe === undefined;

async function processIdentities(pids, legacyPids) {
  const ids = [...new Set(pids.filter(validPid))];
  const found = new Map();
  // Old ship checkouts only record a PID. A protected process is also alive.
  for (const pid of new Set(legacyPids)) {
    try { process.kill(pid, 0); found.set(pid, { pid }); }
    catch (e) {
      if (e.code === 'EPERM') found.set(pid, { pid });
      else if (e.code !== 'ESRCH') throw e;
    }
  }
  if (!ids.length) return found;
  if (process.platform === 'win32') {
    // One query for the snapshot. Use the same name and UTC file time as the watchdog.
    const command = `$ErrorActionPreference = 'Stop'
      foreach ($id in @(${ids.join(',')})) {
        try { $p = [Diagnostics.Process]::GetProcessById($id) }
        catch [ArgumentException] { continue }
        try {
          if (-not $p.HasExited) {
            $start = $p.StartTime.ToFileTimeUtc()
            $name = $p.ProcessName.ToLowerInvariant()
            if (-not $p.HasExited) { "$id|$start|$name" }
          }
        } catch { if (-not $p.HasExited) { throw } }
        finally { $p.Dispose() }
      }
      exit 0`;
    const { stdout, stderr } = await queryProcess('powershell.exe', ['-NoProfile', '-NonInteractive', '-Command',
      '[Console]::OutputEncoding = [Text.Encoding]::UTF8; ' + command], { encoding: 'utf8', windowsHide: true, timeout: 4000 });
    if (stderr.trim()) throw new Error(stderr.trim());
    for (const line of stdout.trim().split(/\r?\n/).filter(Boolean)) {
      const match = /^(\d+)\|(\d+)\|([^|]+)$/.exec(line);
      if (!match || !ids.includes(Number(match[1]))) throw new Error('Invalid GPU process lookup output');
      const [, id, startTime, exe] = match;
      const pid = Number(id);
      found.set(pid, { pid, startTime, exe });
    }
    return found;
  }
  const boot = fs.readFileSync('/proc/sys/kernel/random/boot_id', 'utf8').trim();
  for (const pid of ids) {
    try {
      const stat = fs.readFileSync(`/proc/${pid}/stat`, 'utf8');
      const fields = stat.slice(stat.lastIndexOf(')') + 2).split(' ');
      if (fields[0] === 'Z' || fields[0] === 'X') continue;
      const exe = path.basename(fs.readlinkSync(`/proc/${pid}/exe`));
      found.set(pid, { pid, startTime: `${boot}:${fields[19]}`, exe });
    } catch (e) {
      if (!['ENOENT', 'ESRCH'].includes(e.code)) throw e;
    }
  }
  return found;
}
function matches(item, identities) {
  const current = identities.get(item.pid);
  return !!current && (legacyIdentity(item) || (current.startTime === item.startTime && current.exe === item.exe));
}
function processes(item) {
  return item.state === 'orphaned_child' ? item.survivors : [item, item.child].filter(Boolean);
}
function parseClaim(raw) {
  if (!raw) return null;
  let item;
  try { item = JSON.parse(raw); }
  catch (e) { if (e instanceof SyntaxError) return undefined; throw e; }
  if (typeof item?.token !== 'string' || !item.token || !validPid(item.pid) ||
      (!legacyIdentity(item) && !validIdentity(item)) || (item.child && !validIdentity(item.child)) ||
      (item.state === 'orphaned_child' && (!item.survivors?.length || !Array.isArray(item.survivors) ||
        !item.survivors.every(validIdentity)))) return undefined;
  return item;
}
function sameClaims(before, after) {
  return before.size === after.size && [...before].every(([name, entry]) => entry.raw === after.get(name)?.raw);
}
function claimLabel(issue, jobDir, exe, args) {
  const explicit = [issue, jobDir].map(value => String(value ?? '').trim()).find(Boolean);
  if (explicit) return explicit;
  const script = /(?:^|\s)(?:"([^"]+)"|(\S+?))(?=\s|$)/g;
  const scriptName = [exe, ...[...args.matchAll(script)].map(match => match[1] || match[2])]
    .find(value => /\.(?:bat|cmd|ps1|gd|tscn|py|js|mjs|cjs|sh)$/i.test(value));
  return scriptName ? path.win32.basename(scriptName) : '';
}

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
  constructor(root, identify = processIdentities) { this.root = root; this.identify = identify; }
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
  readText(name) {
    try {
      return fs.readFileSync(path.join(this.root, name), 'utf8').trim();
    } catch (e) {
      if (e.code === 'ENOENT') return null;
      throw e;
    }
  }
  read(name) {
    const raw = this.readText(name);
    return raw ? JSON.parse(raw) : null;
  }
  snapshot(token) {
    const entries = new Map();
    for (const name of this.names()) {
      const raw = this.readText(name);
      const item = parseClaim(raw);
      if (token === undefined || item?.token === token) entries.set(name, { raw, item });
    }
    return entries;
  }
  async lookup(pids, legacyPids = []) {
    if (!pids.length && !legacyPids.length) return new Map();
    try { return await this.identify(pids, legacyPids); }
    catch { return null; } // An error or timeout provides no evidence that a process is gone.
  }
  archive(name) {
    const archive = `gpu_slot_corrupt_${Date.now()}_${crypto.randomUUID()}`;
    fs.renameSync(path.join(this.root, name), path.join(this.root, archive));
    console.error(`GPU claim: moved damaged ${name} to ${archive}`);
  }
  write(name, value) {
    fs.mkdirSync(this.root, { recursive: true });
    const target = path.join(this.root, name);
    const temp = target + '.tmp-' + crypto.randomUUID();
    fs.writeFileSync(temp, value ? JSON.stringify(value) + '\n' : '', { flag: 'wx' });
    fs.renameSync(temp, target);
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
  async step(holder, waiter = holder, { check, deadline, clock, tx = transaction } = {}) {
    this.checkWeight(holder);
    if (!holder.issue?.trim()) throw new Error('GPU claim requires a label (PC_GPU_ISSUE, JOB_DIR or script name)');
    const snapshot = this.snapshot();
    const processesInClaims = [...snapshot.values()].flatMap(({ item }) => item ? processes(item) : []);
    const pids = [holder.pid, waiter.pid], legacyPids = [];
    for (const process of processesInClaims) (legacyIdentity(process) ? legacyPids : pids).push(process.pid);
    const identities = await this.lookup(pids, legacyPids);
    if (!identities) return null;
    for (const item of [holder, waiter]) {
      const current = identities.get(item.pid);
      if (!validIdentity(current) || !matches(item, identities)) {
        throw new Error('GPU admission cancelled: owner exited or identity changed');
      }
      Object.assign(item, current);
    }
    return tx(() => {
      // Track, release or an older helper may have changed a claim during the lookup.
      if (!sameClaims(snapshot, this.snapshot())) return null;
      return this.claim(holder, waiter, snapshot, identities);
    }, check, deadline, clock);
  }
  claim(holder, waiter, snapshot, identities) {
    const { capacity, weight } = this.checkWeight(holder);
    // A child registered in any copy holds the whole weighted claim, even if a writer died between renames.
    const liveTokens = new Set();
    for (const { item } of snapshot.values()) {
      if (item && processes(item).some(p => matches(p, identities))) liveTokens.add(item.token);
    }
    const held = new Map();
    for (const [name, { item }] of snapshot) {
      if (item === undefined) this.archive(name);
      else if (item && !liveTokens.has(item.token)) this.write(name, null);
      else if (item) held.set(name, item);
    }
    if (!this.cleared()) return null;
    // Include claims above a lowered capacity until they exit or are reclaimed.
    const pending = held.get('gpu_solo');
    held.delete('gpu_solo');
    if (holder.mode === 'solo') {
      if (pending && pending.token !== holder.token) return null;
      // Reserve priority before draining existing shared workers. New workers wait.
      // While draining, the waiting helper owns the reservation. If it is killed
      // outright, the next caller can reclaim it even if the watchdog is alive.
      if (!pending) this.write('gpu_solo', { ...holder, ...waiter });
      if (held.size) return null;
      this.write('gpu_slot_1', holder);
      this.write('gpu_solo', holder);
      return holder;
    }
    if (pending || [...held.values()].some(item => item.mode === 'solo')) return null;
    if (held.size + weight > capacity) return null;
    // One holder occupies every unit of its weight, with admission serialized.
    // Keep the existing file names so claims survive tools updates.
    const free = [];
    for (let index = 1; free.length < weight; index++) {
      const name = slotName(index);
      if (!held.has(name)) free.push(name);
    }
    for (const name of free) this.write(name, holder);
    return holder;
  }
  async update(token, action, identities, tx = transaction) {
    if (!Array.isArray(identities) || !identities.length || !identities.every(validIdentity) ||
        (action === 'track' && identities.length !== 1)) throw new Error('GPU claim update requires process identities');
    // The watchdog holds the child suspended until track succeeds. Lock contention alone must never abort the launch.
    await tx(() => {
      const entries = this.snapshot(token);
      if (!entries.size) throw new Error('GPU claim to update was not found');
      const changes = action === 'track' ? { child: identities[0] } : { state: 'orphaned_child', survivors: identities };
      for (const [name, { item }] of entries) this.write(name, { ...item, ...changes });
    }, undefined, Infinity);
  }
  async release(token, { clock = realClock, tx = transaction } = {}) {
    if (!token) throw new Error('GPU claim token is required for release');
    const deadline = clock.now() + RELEASE_WAIT_MS;
    while (clock.now() < deadline) {
      const entries = this.snapshot(token);
      if (!entries.size) return;
      const children = [...entries.values()].flatMap(({ item }) =>
        item.state === 'orphaned_child' ? item.survivors : [item.child].filter(Boolean));
      const identities = await this.lookup(children.map(p => p.pid));
      if (identities) {
        const released = await tx(() => {
          if (!sameClaims(entries, this.snapshot(token))) return false;
          if (children.some(p => matches(p, identities))) throw new Error('GPU claim still has a live child');
          for (const name of entries.keys()) this.write(name, null);
          return true;
        }, undefined, deadline, clock);
        if (released) return;
      }
      await clock.sleep(Math.min(POLL_MS, Math.max(0, deadline - clock.now())));
    }
    throw new Error('GPU claim release timed out');
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
    console.log(JSON.stringify({ mode, weight: weightFor(input.exe, input.weight, mode),
      label: claimLabel(input.issue, input.jobDir, input.exe, input.args) }));
    return;
  }
  if (!root) throw new Error('GPU root is required');
  const slots = new Slots(root);
  if (action === 'release') { await slots.release(issue); return; }
  if (action === 'track' || action === 'orphan') {
    const identities = JSON.parse(fs.readFileSync(0, 'utf8').replace(/^\uFEFF/, ''));
    await slots.update(issue, action, identities);
    return;
  }
  if (action !== 'acquire' || !['shared', 'solo'].includes(mode)) throw new Error('Usage: gpu_slots.js acquire ROOT ISSUE PID shared|solo [WEIGHT]');
  const lane = codeOnlyLane(process.env.PC_GPU_LANE, process.cwd());
  if (lane) throw new Error(`Lane ${lane} is code only; GPU work refused`);
  const label = claimLabel(issue, process.env.JOB_DIR, '', '');
  if (!label) throw new Error('GPU claim requires a label (PC_GPU_ISSUE, JOB_DIR or script name)');
  const holder = { token: crypto.randomUUID(), issue: label, pid: Number(pid), mode,
    weight: positiveInteger(weight, 'GPU weight'), started: new Date().toISOString() };
  const waitSeconds = positiveInteger(process.env.PC_GPU_WAIT_SECONDS ?? '300', 'PC_GPU_WAIT_SECONDS');
  if (waitSeconds > MAX_WAIT_SECONDS) throw new Error(`PC_GPU_WAIT_SECONDS must be at most ${MAX_WAIT_SECONDS}`);
  let cancelled = false;
  const cancel = () => { cancelled = true; };
  process.on('SIGINT', cancel);
  process.on('SIGTERM', cancel);
  try {
    await admit(slots, holder, { waitSeconds, waiter: { pid: process.pid },
      cancelled: () => cancelled, onWait: () => console.log('WAIT') });
    console.log(holder.token);
  } finally {
    process.off('SIGINT', cancel);
    process.off('SIGTERM', cancel);
  }
}

// Wait for a claim until waitSeconds pass. Resolves with the holder once it is written; throws "admission timed out" or
// "admission cancelled" (owner exited, or cancelled() turned true) and then releases anything it reserved. tx and clock are
// for tests: tx defaults to the localhost lock, clock to the real one.
async function admit(slots, holder, { waitSeconds, cancelled = () => false, onWait = () => {}, waiter = holder,
  clock = realClock, tx = transaction } = {}) {
  const deadline = clock.now() + waitSeconds * 1000;
  let handedOff = false;
  const check = () => {
    if (cancelled()) throw new Error('GPU admission cancelled');
    if (clock.now() >= deadline) throw new Error(`GPU admission timed out after ${waitSeconds} seconds`);
  };
  let heartbeat = clock.now();
  try {
    for (;;) {
      check();
      const claim = await slots.step(holder, waiter, { check, deadline, clock, tx });
      check();
      if (claim) { handedOff = true; return claim; }
      if (clock.now() - heartbeat >= 60000) { onWait(); heartbeat = clock.now(); }
      await clock.sleep(Math.min(POLL_MS, Math.max(0, deadline - clock.now())));
    }
  } finally {
    try {
      if (!handedOff) await slots.release(holder.token, { clock, tx });
    } catch (e) { console.error('GPU claim cleanup: ' + e.message); }
  }
}
if (require.main === module) main().catch(e => { console.error('GPU claim: ' + e.message); process.exitCode = 1; });
module.exports = { Slots, modeFor, weightFor, claimLabel, transaction, codeOnlyLane, admit, MAX_WAIT_SECONDS };
