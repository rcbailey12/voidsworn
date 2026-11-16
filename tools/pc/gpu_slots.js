'use strict';
// R276: two GPU workers, or one solo measurement. Node 22, no packages.
// The watchdog owns the claim, so killing its tree leaves a reclaimable dead PID.
const fs = require('fs');
const path = require('path');
const net = require('net');
const crypto = require('crypto');
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const names = ['gpu_slot_1', 'gpu_slot_2', 'gpu_solo'];
const alive = pid => {
  if (!Number.isInteger(pid) || pid <= 0) return false;
  try { process.kill(pid, 0); return true; } catch (e) { return e.code === 'EPERM'; }
};

// An OS-owned localhost bind serializes short file transactions across ALL tools
// copies. The OS drops it after a crash. No lock or job files are ever deleted.
// No client connects and no data is sent. An occupied port fails closed (waits).
async function transaction(fn) {
  for (;;) {
    const server = net.createServer(socket => socket.destroy());
    const bound = await new Promise((resolve, reject) => {
      server.once('error', e => e.code === 'EADDRINUSE' ? resolve(false) : reject(e));
      server.listen({ host: '127.0.0.1', port: 47847, exclusive: true }, () => resolve(true));
    });
    if (!bound) { await sleep(25); continue; }
    try { return fn(); } finally { await new Promise(resolve => server.close(resolve)); }
  }
}

class Slots {
  constructor(root, isAlive = alive) { this.root = root; this.isAlive = isAlive; }
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
  step(holder) {
    const state = names.map(name => {
      const item = this.read(name);
      if (item && !this.isAlive(item.pid)) { this.write(name, null); return null; }
      return item;
    });
    if (!this.isAlive(holder.pid)) throw new Error('GPU claim owner has exited');
    if (!this.cleared()) return null;
    const occupied = state.slice(0, 2);
    const pending = state[2];
    if (holder.mode === 'solo') {
      if (pending && pending.token !== holder.token) return null;
      // Reserve priority before draining existing shared workers. New workers wait.
      if (!pending) this.write('gpu_solo', holder);
      if (occupied.some(Boolean)) return null;
      this.write('gpu_slot_1', holder);
      return holder;
    }
    if (pending || occupied.some(item => item && item.mode === 'solo')) return null;
    const index = occupied.findIndex(item => !item);
    if (index < 0) return null;
    this.write(names[index], holder);
    return holder;
  }
  release(token) {
    for (const name of names) if (this.read(name)?.token === token) this.write(name, null);
  }
}

// Benchmarks take solo themselves, including direct tmo launches. Follow scene
// and script resources, so a scene's script cannot hide timing behind a .tscn.
function modeFor(exe, args, cwd = process.cwd(), requested = '') {
  const godot = /^(?:Godot|Voidsworn).*\.exe$/i.test(path.win32.basename(exe)) || /^godot(?:[34])?$/i.test(path.basename(exe));
  const blender = /^blender(?:\.exe)?$/i.test(path.win32.basename(exe));
  if (!godot && !blender) return requested === 'solo' || requested === 'shared' ? requested : '';
  if (godot && /(?:^|\s)--headless(?:\s|$)/i.test(args)) return '';
  if (requested === 'solo') return 'solo';
  if (blender) return 'shared';
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

async function main() {
  const [action, root, issue, pid, mode] = process.argv.slice(2);
  if (action === 'classify') {
    const input = JSON.parse(fs.readFileSync(0, 'utf8').replace(/^\uFEFF/, ''));
    console.log(modeFor(input.exe, input.args, input.cwd, input.requested));
    return;
  }
  if (!root) throw new Error('GPU root is required');
  const slots = new Slots(root);
  if (action === 'release') { await transaction(() => slots.release(issue)); return; }
  if (action !== 'acquire' || !['shared', 'solo'].includes(mode)) throw new Error('Usage: gpu_slots.js acquire ROOT ISSUE PID shared|solo');
  if (process.env.PC_GPU_LANE === 'C' || /(?:^|[\\/])board_c(?:[\\/]|$)/i.test(process.cwd())) throw new Error('Lane C is code only; GPU work refused');
  const holder = { token: crypto.randomUUID(), issue, pid: Number(pid), mode, started: new Date().toISOString() };
  let claimed = false;
  let heartbeat = Date.now();
  try {
    for (;;) {
      claimed = !!await transaction(() => slots.step(holder));
      if (claimed) { console.log(holder.token); return; }
      if (Date.now() - heartbeat >= 60000) { console.log('WAIT'); heartbeat = Date.now(); }
      await sleep(250);
    }
  } finally {
    if (!claimed) await transaction(() => slots.release(holder.token));
  }
}
if (require.main === module) main().catch(e => { console.error('GPU claim: ' + e.message); process.exitCode = 1; });
module.exports = { Slots, modeFor, transaction };
