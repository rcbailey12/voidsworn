'use strict';
// Issue 1662 run 1 (Ryan, Nov 22 2026, studio ops plan Wave 4.1): the label-driven PC runner daemon.
//   node pc_daemon.js            dry run: reads GitHub, prints what it would run, changes nothing anywhere
//   node pc_daemon.js --once     one dry look and exit
//   node pc_daemon.js --live     runs jobs (the Board turns this on only after its review and a PC proof)
// A pull request is run when all of these hold (RULEBOOK 3.12, owner decision 3):
//   it is open, from this repo (never a fork), labelled pc-ready;
//   its newest "PC go: <head sha>" comment, written by the owner account, names its current head commit and says who
//   passed the diff ("reviewed:");
//   its "All checks" run at that head commit is completed with success;
//   the daemon has not run that commit and job before (its own ledger and its own done marker on the PR).
// Then, one job at a time: claim (pc-ready off, running on, a status comment), a new attempt folder
// voidsworn_test\<job>\out_<stamp>_<n>, a warm slot reset to the head commit, the built ships copied in, a GPU claim,
// the Godot or Blender step under this file's watchdog (hard ceiling, stall stop, whole process tree killed), a
// throwaway Godot profile, Ryan's real options hashed before and after, the relay push, a result comment, running off.
// Run 1 keeps the proven Windows pieces it calls from tools_live: the slot lease and reset (opus_job_head.ps1 slot and
// slotrelease, which need Windows share-mode locks), the ships checks (tracked, shipcheck, shiprecord), the tool
// preflight (runner_common.ps1) and relay_push.ps1. Later runs move those one flow at a time.
// Deletes: this file deletes only its own throwaway profiles under voidsworn_test\slots\profiles (removeInside);
// the slot reset it asks the head for deletes only inside voidsworn_test\slots. Nothing else, on the PC or on GitHub.
// Node 22, built-in modules only.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { spawn, spawnSync } = require('child_process');

const REPO = 'rcbailey12/voidsworn';
const READY = 'pc-ready';
const RUNNING = 'running';
const CHECK_NAME = 'All checks';
const OWNERS = ['rcbailey12'];
const TRUSTED = new Set(['OWNER', 'MEMBER', 'COLLABORATOR']);
const MAX_CEILING_S = 6 * 3600; // RULEBOOK 3.5's default hard ceiling
const DEFAULT_CEILING_S = 3600;
const DEFAULT_STALL_MIN = 30;   // RULEBOOK 3.5's STALL_MIN default
const PAUSE_LINE = /^GPU not cleared: paused by the Board\b/;
const PROFILE_NAME = /^pcd-profile-[0-9a-f]{32}$/;
const DONE_MARK = (sha, job) => `<!-- pc-daemon done ${sha} ${job} -->`;
const DONE_RE = /<!-- pc-daemon done ([0-9a-f]{40}) ([a-z0-9_]{1,40}) -->/g;
const BAD_ARG = /[|&<>"%^\r\n\t]/; // RULEBOOK 3.5: no |, &, < or > in job arguments; no quotes or cmd expansion either

// ------------------------------------------------------------------------------------------------- the go comment
// The Board writes it after its review, on the PR, as one comment:
//   PC go: <40-character head commit>
//   reviewed: <who passed the diff at that commit, e.g. "Artoo and Board audit at 1a2b3c4d">
//   job: <name, a-z 0-9 _ , up to 40>
//   flow: godot | blender
//   script: res://<path>.gd (godot, optional) or <repo path>.py (blender, required)
//   args: <arguments; {out} is the results folder, {repo} the slot checkout>
//   expect: <one or more paths under the results folder that must exist and not be empty>
// optional: slot: gpu|cpu (gpu), gpu: shared|solo|none (shared on a gpu slot, none on cpu), weight: 1-8 (1),
//   ships: yes|no (yes for godot, no for blender), hulls: <codes>, headless: yes|no (no),
//   timeout: <seconds, ceiling> (3600, at most 21600), stall: <minutes without progress> (30, 1 to 360)
function parseGo(body) {
  const lines = String(body || '').replace(/\r/g, '').split('\n').map(l => l.trim()).filter(Boolean);
  const head = /^PC go:\s*([0-9a-f]{40})$/.exec(lines[0] || '');
  if (!head) return null;
  const kv = {};
  for (const line of lines.slice(1)) {
    if (line.startsWith('```') || line.startsWith('<!--') || line === '---') continue;
    const m = /^([a-z]+):\s*(.*)$/.exec(line);
    if (!m) continue;
    if (kv[m[1]] !== undefined) return { sha: head[1], error: `the line "${m[1]}:" is given twice` };
    kv[m[1]] = m[2].trim();
  }
  const fail = error => ({ sha: head[1], error });
  const known = ['reviewed', 'job', 'flow', 'script', 'args', 'expect', 'slot', 'gpu', 'weight', 'ships', 'hulls',
    'headless', 'timeout', 'stall'];
  const unknown = Object.keys(kv).filter(k => !known.includes(k));
  if (unknown.length) return fail(`unknown line "${unknown[0]}:"`);
  if (!kv.reviewed) return fail('no "reviewed:" line (who passed the diff at this commit, RULEBOOK 3.12)');
  if (!/^[a-z0-9_]{1,40}$/.test(kv.job || '')) return fail('job must be 1 to 40 of a-z, 0-9 and _');
  if (!['godot', 'blender'].includes(kv.flow)) return fail('flow must be godot or blender');
  const yesNo = (k, dflt) => {
    if (kv[k] === undefined) return dflt;
    if (kv[k] === 'yes') return true;
    if (kv[k] === 'no') return false;
    throw new Error(`${k} must be yes or no`);
  };
  const int = (k, dflt, lo, hi) => {
    if (kv[k] === undefined) return dflt;
    if (!/^[0-9]{1,6}$/.test(kv[k]) || +kv[k] < lo || +kv[k] > hi) throw new Error(`${k} must be a whole number from ${lo} to ${hi}`);
    return +kv[k];
  };
  try {
    const slot = kv.slot || 'gpu';
    if (!['gpu', 'cpu'].includes(slot)) throw new Error('slot must be gpu or cpu');
    const gpu = kv.gpu || (slot === 'gpu' ? 'shared' : 'none');
    if (!['shared', 'solo', 'none'].includes(gpu)) throw new Error('gpu must be shared, solo or none');
    if (slot === 'cpu' && gpu !== 'none') throw new Error('a cpu slot job takes no GPU claim (gpu: none)');
    const script = kv.script || '';
    if (kv.flow === 'godot' && script && !/^res:\/\/[A-Za-z0-9_./-]+\.gd$/.test(script)) throw new Error('a godot script is res://<path>.gd');
    if (kv.flow === 'blender' && !/^[A-Za-z0-9_][A-Za-z0-9_./-]*\.py$/.test(script)) throw new Error('a blender script is a repo path ending .py');
    if (script.split('/').includes('..')) throw new Error('the script path may not use ..');
    const args = kv.args ? kv.args.split(/\s+/) : [];
    const bad = args.find(a => BAD_ARG.test(a));
    if (bad) throw new Error(`argument not accepted (no | & < > " % ^): ${bad}`);
    const expect = (kv.expect || '').split(/\s+/).filter(Boolean);
    if (!expect.length) throw new Error('no "expect:" line (the outputs that prove the job ran)');
    for (const e of expect) {
      if (!/^[A-Za-z0-9_][A-Za-z0-9_./-]*$/.test(e) || e.split('/').includes('..')) throw new Error(`expect path not accepted: ${e}`);
    }
    const hulls = (kv.hulls || '').split(/[\s,]+/).filter(Boolean);
    if (hulls.some(h => !/^[A-Za-z0-9_]{1,12}$/.test(h))) throw new Error('hulls are ship codes split by spaces');
    return {
      sha: head[1], reviewed: kv.reviewed, job: kv.job, flow: kv.flow, script, args, expect, slot, gpu,
      weight: int('weight', 1, 1, 8), ships: yesNo('ships', kv.flow === 'godot'), hulls,
      headless: yesNo('headless', false), ceilingS: int('timeout', DEFAULT_CEILING_S, 60, MAX_CEILING_S),
      stallMin: int('stall', DEFAULT_STALL_MIN, 1, 360)
    };
  } catch (e) { return fail(e.message); }
}

// ------------------------------------------------------------------------------------------------------- the gate
// Returns { verdict, why, spec }: run (start it), wait (look again later), refuse (tell the PR once, take the label off),
// skip (already done or not ours; say nothing).
function gate({ pull, comments, checkRuns, ledger, owners = OWNERS, repo = REPO }) {
  const sha = pull?.head?.sha;
  if (!pull || pull.state !== 'open') return { verdict: 'skip', why: 'not open' };
  if (pull.head?.repo?.full_name !== repo) return { verdict: 'refuse', why: 'the branch is on a fork; the PC never runs fork code' };
  const ours = c => owners.includes(c.user?.login) && TRUSTED.has(c.author_association);
  const done = new Set();
  for (const c of comments) if (ours(c)) for (const m of String(c.body || '').matchAll(DONE_RE)) done.add(m[1] + ' ' + m[2]);
  const go = [...comments].reverse().map(c => ours(c) ? parseGo(c.body) : null).find(Boolean);
  if (!go) return { verdict: 'wait', why: 'no "PC go:" comment from the owner account yet' };
  if (go.sha !== sha) return { verdict: 'refuse', why: `the newest PC go names ${go.sha.slice(0, 8)} but the head is ${sha.slice(0, 8)}; a later push needs green checks and a review again (RULEBOOK 3.12)` };
  if (go.error) return { verdict: 'refuse', why: 'the PC go comment is not usable: ' + go.error };
  if (done.has(sha + ' ' + go.job) || ledger.has(sha + ' ' + go.job)) return { verdict: 'skip', why: `${go.job} already ran at ${sha.slice(0, 8)}` };
  const runs = checkRuns.filter(r => r.name === CHECK_NAME && r.head_sha === sha)
    .sort((a, b) => String(b.started_at || '').localeCompare(String(a.started_at || '')));
  const run = runs[0];
  if (!run) return { verdict: 'wait', why: `no "${CHECK_NAME}" run at ${sha.slice(0, 8)} yet`, spec: go };
  if (run.status !== 'completed') return { verdict: 'wait', why: `"${CHECK_NAME}" is ${run.status}`, spec: go };
  if (run.conclusion !== 'success') return { verdict: 'refuse', why: `"${CHECK_NAME}" ended ${run.conclusion} at ${sha.slice(0, 8)}` };
  return { verdict: 'run', why: 'green checks, review named, PC go at the head commit', spec: go };
}

// --------------------------------------------------------------------------------------------------- the watchdog
// Starts exe with args (never through a shell), logs stdout and stderr to logFile and stops the whole process tree
// at the hard ceiling or after stallMs with no progress. Progress: new output bytes, or a newer file time anywhere
// under progressDirs (a walk of at most 20,000 entries per look). Resolves { code, signal, reason, ms, bytes }, reason
// one of exit, ceiling, stall, start (the program could not start).
function newestTime(dirs, cap = 20000) {
  let newest = 0, seen = 0;
  const stack = [...dirs];
  while (stack.length && seen < cap) {
    const d = stack.pop();
    let entries;
    try { entries = fs.readdirSync(d, { withFileTypes: true }); } catch { continue; }
    for (const e of entries) {
      if (++seen > cap) break;
      const p = path.join(d, e.name);
      try {
        const st = fs.lstatSync(p);
        if (st.mtimeMs > newest) newest = st.mtimeMs;
        if (e.isDirectory() && !st.isSymbolicLink()) stack.push(p);
      } catch { /* gone between the read and the look */ }
    }
  }
  return newest;
}
function killTree(pid, platform = process.platform) {
  if (!pid) return;
  if (platform === 'win32') {
    const r = spawnSync('taskkill', ['/PID', String(pid), '/T', '/F'], { windowsHide: true, timeout: 60000, encoding: 'utf8' });
    if (r.status !== 0) throw new Error(`taskkill exit ${r.status}: ${String(r.stderr || r.stdout || '').trim().slice(0, 200)}`);
  }
  else { try { process.kill(-pid, 'SIGKILL'); } catch { try { process.kill(pid, 'SIGKILL'); } catch { /* gone */ } } }
}
// A stop is asked again every killRetryMs until the child closes (Artoo on PR 1835: one failed taskkill must not leave
// the job running); after killTries asks with no close it resolves with unkilled: true, and the caller keeps the slot and
// GPU claim held and starts nothing more (the tree may still be running in the slot).
function watch({ exe, args, cwd, env, ceilingMs, stallMs, progressDirs = [], logFile, pollMs = 5000, now = Date.now, kill = killTree,
  killRetryMs = 30000, killTries = 5 }) {
  return new Promise(resolve => {
    const start = now();
    const log = fs.openSync(logFile, 'a');
    const say = s => { try { fs.writeSync(log, s); } catch { /* the log is best effort */ } };
    say(`[pc_daemon ${new Date(start).toISOString()}] start ${exe} ${args.join(' ')}\n`);
    let bytes = 0, lastProgress = start, lastTime = newestTime(progressDirs), reason = null, timer = null, finished = false;
    let child, kills = 0, lastKill = 0;
    const finish = (code, signal, unkilled = false) => {
      if (finished) return;
      finished = true;
      clearInterval(timer);
      const ms = now() - start;
      say(`[pc_daemon ${new Date().toISOString()}] end: ${reason || 'exit'} code ${code} signal ${signal || '-'} after ${Math.round(ms / 1000)} s\n`);
      fs.closeSync(log);
      resolve({ code, signal: signal || null, reason: reason || 'exit', ms, bytes, unkilled });
    };
    try {
      child = spawn(exe, args, { cwd, env, windowsHide: true, detached: process.platform !== 'win32', stdio: ['ignore', 'pipe', 'pipe'] });
    } catch (e) { reason = 'start'; say(`could not start: ${e.code || e.message}\n`); finish(null, null); return; }
    const take = chunk => { bytes += chunk.length; lastProgress = now(); say(chunk.toString('utf8')); };
    child.stdout.on('data', take);
    child.stderr.on('data', take);
    child.on('error', e => { reason = reason || 'start'; say(`could not start: ${e.code || e.message}\n`); finish(null, null); });
    child.on('close', (code, signal) => finish(code, signal));
    const stop = t => {
      if (kills >= killTries) { say(`[pc_daemon] the process tree did not end after ${kills} stop requests\n`); finish(null, null, true); return; }
      kills++; lastKill = t;
      say(`[pc_daemon] stopping the process tree (${reason}), request ${kills}\n`);
      try { kill(child.pid); } catch (e) { say(`[pc_daemon] stop request failed: ${e.message}\n`); }
    };
    timer = setInterval(() => {
      const t = now();
      if (reason) { if (t - lastKill >= killRetryMs) stop(t); return; }
      const newest = newestTime(progressDirs);
      if (newest > lastTime) { lastTime = newest; lastProgress = t; }
      if (t - start >= ceilingMs) reason = 'ceiling';
      else if (t - lastProgress >= stallMs) reason = 'stall';
      if (reason) stop(t);
    }, pollMs);
  });
}

// -------------------------------------------------------------------------------------------- the one delete here
// Removes target, which must be a pcd-profile-<hex> folder directly in <slotsRoot>\profiles, never following a link or
// junction (a link is removed as a link). slotsRoot and profiles must be plain folders. Throws on any doubt.
function removeInside(slotsRoot, target) {
  const root = path.resolve(slotsRoot), profiles = path.join(root, 'profiles'), t = path.resolve(target);
  if (path.dirname(t) !== profiles || !PROFILE_NAME.test(path.basename(t))) throw new Error(`not a daemon profile under ${profiles}: ${t}`);
  for (const p of [root, profiles, t]) {
    const st = fs.lstatSync(p);
    if (!st.isDirectory() || st.isSymbolicLink()) throw new Error(`not a plain folder: ${p}`);
  }
  const drop = p => {
    const st = fs.lstatSync(p);
    if (st.isSymbolicLink()) {
      try { fs.unlinkSync(p); } catch (e) { if (['EPERM', 'EISDIR'].includes(e.code)) fs.rmdirSync(p); else throw e; }
    } else if (st.isDirectory()) {
      for (const n of fs.readdirSync(p)) drop(path.join(p, n));
      fs.rmdirSync(p);
    } else {
      try { fs.chmodSync(p, 0o666); } catch { /* read-only flag cleared when allowed */ }
      fs.unlinkSync(p);
    }
  };
  drop(t);
}

// --------------------------------------------------------------------------------------------------------- GitHub
// Every call goes through `gh api` (REST only, RULEBOOK 2.5), with the PC's own sign-in. No tokens pass through here.
class GhCli {
  constructor({ repo = REPO, gh = 'gh', run = spawnSync } = {}) { this.repo = repo; this.gh = gh; this.run = run; }
  api(args, input) {
    let file = null;
    if (input !== undefined) {
      file = path.join(require('os').tmpdir(), `pcd-${crypto.randomUUID()}.json`);
      fs.writeFileSync(file, JSON.stringify(input));
      args = [...args, '--input', file];
    }
    try {
      const r = this.run(this.gh, ['api', ...args], { encoding: 'utf8', timeout: 120000, windowsHide: true, maxBuffer: 64 << 20 });
      if (r.status !== 0) throw new Error(`gh api ${args[0]} ${args[1] || ''}: exit ${r.status}: ${String(r.stderr || '').trim().slice(0, 300)}`);
      return r.stdout.trim() ? JSON.parse(r.stdout) : null;
    } finally { if (file) try { fs.unlinkSync(file); } catch { /* temp file */ } }
  }
  pages(route) {
    const out = [];
    for (let page = 1; page <= 30; page++) {
      const got = this.api([`${route}${route.includes('?') ? '&' : '?'}per_page=100&page=${page}`]);
      const list = Array.isArray(got) ? got : (got?.check_runs || []);
      out.push(...list);
      if (list.length < 100) break;
    }
    return out;
  }
  readyPulls() { return this.pages(`repos/${this.repo}/issues?state=open&labels=${READY}`).filter(i => i.pull_request).map(i => i.number); }
  pull(n) { return this.api([`repos/${this.repo}/pulls/${n}`]); }
  comments(n) { return this.pages(`repos/${this.repo}/issues/${n}/comments`); }
  checkRuns(sha) { return this.pages(`repos/${this.repo}/commits/${sha}/check-runs?check_name=${encodeURIComponent(CHECK_NAME)}`); }
  addLabel(n, label) { this.api(['-X', 'POST', `repos/${this.repo}/issues/${n}/labels`], { labels: [label] }); }
  removeLabel(n, label) { this.api(['-X', 'DELETE', `repos/${this.repo}/issues/${n}/labels/${encodeURIComponent(label)}`]); }
  comment(n, body) { this.api(['-X', 'POST', `repos/${this.repo}/issues/${n}/comments`], { body }); }
}

// ----------------------------------------------------------------------------------------------- the PC's own tools
// The proven tools_live pieces this run calls. Every path is checked; nothing here deletes.
class PcTools {
  constructor({ vt, run = spawnSync } = {}) { this.vt = vt; this.run = run; }
  pc() {
    const current = fs.readFileSync(path.join(this.vt, 'tools_live', 'current.txt'), 'utf8').trim();
    if (!/^[A-Za-z0-9._-]+$/.test(current)) throw new Error(`tools_live\\current.txt is not a version name: ${current}`);
    const pc = path.join(this.vt, 'tools_live', current, 'pc');
    if (!fs.existsSync(path.join(pc, 'jobs', 'opus_job_head.ps1'))) throw new Error(`no installed tools at ${pc}`);
    return pc;
  }
  ps(script, args, { env = {}, timeoutMs = 1800000, log } = {}) {
    const r = this.run('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script, ...args],
      { encoding: 'utf8', timeout: timeoutMs, windowsHide: true, env: { ...process.env, ...env }, maxBuffer: 64 << 20 });
    const text = `${r.stdout || ''}${r.stderr || ''}`;
    if (log) fs.appendFileSync(log, `> ${path.basename(script)} ${args.join(' ')}\n${text}`);
    if (r.status !== 0) throw new Error(`${path.basename(script)} ${args[0]} failed (exit ${r.status}): ${text.trim().split(/\r?\n/).slice(-3).join(' | ')}`);
    return text;
  }
  head(args, opts) { return this.ps(path.join(this.pc(), 'jobs', 'opus_job_head.ps1'), args, opts); }
  preflight(attempt, tools, log) {
    this.ps(path.join(this.pc(), 'runner_common.ps1'), ['preflight-tools', attempt, tools.join(' ')], { log, timeoutMs: 300000 });
    const found = {};
    for (const line of fs.readFileSync(path.join(attempt, 'tools.cmd'), 'utf8').split(/\r?\n/)) {
      const m = /^set "?JW_([A-Z]+)=(.*?)"?$/.exec(line.trim());
      if (m) found[m[1].toLowerCase()] = m[2];
    }
    for (const t of tools) if (!found[t]) throw new Error(`preflight found no ${t}`);
    return found;
  }
  hashes(file, log) { this.head(['hashes', file], { log, timeoutMs: 120000 }); return fs.readFileSync(file, 'utf8'); }
  slot(attempt, name, pin, kind, log) {
    this.head(['slot', attempt, name, pin], { env: { OJ_SLOT_KIND: kind }, log, timeoutMs: 7 * 3600000 });
    return fs.readFileSync(path.join(attempt, 'slot_repo.txt'), 'utf8').trim();
  }
  slotRelease(attempt, log) { this.head(['slotrelease', attempt], { log, timeoutMs: 120000 }); }
  ships(attempt, repo, name, hulls, log) {
    // as opus_job_head.bat :oj_ships: gen whole (the source wins), assets\ships without the tracked files, then checks
    const src = path.join(this.vt, 'build', 'godot'), side = path.join(attempt, name);
    if (!fs.existsSync(path.join(src, 'gen'))) throw new Error(`no built ships at ${src}\\gen`);
    fs.writeFileSync(path.join(attempt, 'ships_source.txt'), src + '\r\n');
    const robo = (from, to, extra, out) => {
      const r = this.run('robocopy', [from, to, '/E', ...extra, '/NFL', '/NDL', '/NJH', '/NJS', '/R:1', '/W:1'], { encoding: 'utf8', timeout: 3600000, windowsHide: true, maxBuffer: 64 << 20 });
      fs.writeFileSync(out, `${r.stdout || ''}${r.stderr || ''}`);
      if (r.status === null || r.status >= 8) throw new Error(`ships copy failed (robocopy ${r.status}), see ${out}`);
    };
    robo(path.join(src, 'gen'), path.join(repo, 'godot', 'gen'), [], side + '_ships_gen.txt');
    if (!fs.existsSync(path.join(repo, 'godot', 'gen', 'manifest.json'))) throw new Error('no gen\\manifest.json after the ships copy');
    if (fs.existsSync(path.join(src, 'assets', 'ships'))) {
      robo(path.join(src, 'assets', 'ships'), path.join(repo, 'godot', 'assets', 'ships'),
        ['/XC', '/XN', '/XO', '/XF', 'manifest.json', 'README.md', 'a4_props.gd', '*.uid', '/XD', 'test', 'previews'], side + '_ships_assets.txt');
    }
    this.head(['tracked', repo], { log });
    this.head(['shipcheck', repo, side + '_ships_identity.txt', hulls.join(' ')], { log });
    try { this.head(['shiprecord', repo, side + '_ships_copied.txt', src], { log }); }
    catch (e) { fs.appendFileSync(log, `note: the ships copy record could not be written: ${e.message}\n`); }
  }
  gpu(action, ...rest) {
    const node = fs.existsSync(path.join(this.vt, 'node', 'node.exe')) ? path.join(this.vt, 'node', 'node.exe') : process.execPath;
    const r = this.run(node, [path.join(this.pc(), 'gpu_slots.js'), action, this.vt, ...rest.map(String)],
      { encoding: 'utf8', timeout: 3700000, windowsHide: true, env: { ...process.env, PC_GPU_WAIT_SECONDS: '3600' } });
    if (r.status !== 0) throw new Error(`GPU ${action} failed: ${String(r.stderr || r.stdout || '').trim().slice(0, 300)}`);
    return String(r.stdout || '').split(/\r?\n/).map(s => s.trim()).filter(s => /^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$/.test(s)).pop();
  }
  gpuAcquire(label, mode, weight) { const t = this.gpu('acquire', label, process.pid, mode, weight); if (!t) throw new Error('GPU claim gave no token'); return t; }
  gpuRelease(token) { this.gpu('release', token); }
  relay(job, attempt, log) { return this.ps(path.join(this.pc(), 'relay_push.ps1'), [job, attempt], { log, timeoutMs: 3 * 3600000 }); }
  gameRunning() {
    // Ryan playing (R173): no GPU job starts while Voidsworn runs
    const r = this.run('tasklist', ['/FI', 'IMAGENAME eq Voidsworn*', '/FO', 'CSV', '/NH'], { encoding: 'utf8', timeout: 30000, windowsHide: true });
    return /Voidsworn/i.test(String(r.stdout || ''));
  }
}

// ------------------------------------------------------------------------------------------------------ the daemon
const stamp = d => d.toISOString().replace(/[-:]/g, '').replace('T', '_').slice(0, 15);
function relayLinks(text) {
  const lines = String(text || '').split(/\r?\n/);
  return {
    folder: (lines.find(l => l.startsWith('folder link: ')) || '').slice(13),
    pictures: lines.filter(l => l.startsWith('picture link: ')).map(l => l.slice(14)).slice(0, 12)
  };
}
function expectMissing(outDir, expect) {
  return expect.filter(rel => {
    const p = path.join(outDir, ...rel.split('/'));
    try {
      const st = fs.statSync(p);
      return st.isDirectory() ? fs.readdirSync(p).length === 0 : st.size === 0;
    } catch { return true; }
  });
}

class Daemon {
  constructor({ vt, gh, tools, live = false, log = s => console.log(s), clock = () => new Date(), watchImpl = watch, pollMs = 5000 }) {
    Object.assign(this, { vt, gh, tools, live, log, clock, watchImpl, pollMs });
    this.slots = path.join(vt, 'slots');
    this.ledgerFile = path.join(vt, 'pc_daemon', 'ran.txt');
    this.refused = new Set();
    this.deliveryTries = new Map();
    this.quarantined = null;
    this.retryMs = 30 * 60000;
  }
  // One live daemon per voidsworn_test (Artoo on PR 1835: a second one would sweep the first one's active profile).
  // pc_daemon\daemon.lock names the holder's pid and a heartbeat it rewrites every 30 s. A lock whose pid still runs is
  // never taken over, however old its beat: the slot wait and the relay are synchronous and can hold the beat for hours
  // (Artoo on PR 1835, second pass). The beat age is only reported. A lock whose pid is gone is taken over. The file is
  // never deleted; if Windows has given that pid to an unrelated program, the refusal says so and the Board clears it.
  lease({ alive = pid => { try { process.kill(pid, 0); return true; } catch (e) { return e.code === 'EPERM'; } } } = {}) {
    const file = path.join(this.vt, 'pc_daemon', 'daemon.lock');
    fs.mkdirSync(path.dirname(file), { recursive: true });
    const me = () => JSON.stringify({ pid: process.pid, beat: this.clock().getTime(), id: this.leaseId });
    this.leaseId = crypto.randomUUID();
    try {
      const fd = fs.openSync(file, 'wx'); fs.writeSync(fd, me()); fs.closeSync(fd);
    } catch (e) {
      if (e.code !== 'EEXIST') throw e;
      let held = null; try { held = JSON.parse(fs.readFileSync(file, 'utf8')); } catch { /* unreadable: stale */ }
      if (held && alive(held.pid)) {
        const age = Math.round((this.clock().getTime() - held.beat) / 60000);
        throw new Error(`another PC daemon (pid ${held.pid}, last beat ${age} min ago) holds ${file}; if that pid is not a PC daemon (node pc_daemon.js), the Board removes the file`);
      }
      const tmpFile = `${file}.${process.pid}.tmp`;
      fs.writeFileSync(tmpFile, me()); fs.renameSync(tmpFile, file);
    }
    if (JSON.parse(fs.readFileSync(file, 'utf8')).id !== this.leaseId) throw new Error('lost the daemon lock to another start');
    this.beat = () => {
      const now = JSON.parse(fs.readFileSync(file, 'utf8'));
      if (now.id !== this.leaseId) throw new Error('the daemon lock was taken over; stopping');
      const tmpFile = `${file}.${process.pid}.tmp`;
      fs.writeFileSync(tmpFile, me()); fs.renameSync(tmpFile, file);
    };
    return file;
  }
  // ran.txt lines: "<time> <sha> <job> PR<n> <state> [attempt]", state start, PASS, FAILED or delivered (Artoo on PR 1835:
  // launch, local result and verified delivery are kept apart). A start with no result (the daemon stopped mid-job)
  // does not block a new go; a result does, and a result with no delivered line is relayed and reported again.
  entries() {
    try {
      return fs.readFileSync(this.ledgerFile, 'utf8').split(/\r?\n/).filter(Boolean).map(l => {
        const p = l.split(' ');
        return { sha: p[1], job: p[2], pr: +String(p[3]).slice(2), state: p[4], attempt: p.slice(5).join(' ') };
      });
    } catch { return []; }
  }
  ledger() { return new Set(this.entries().filter(e => e.state !== 'start').map(e => e.sha + ' ' + e.job)); }
  undelivered() {
    const all = this.entries(), done = new Set(all.filter(e => e.state === 'delivered').map(e => e.sha + ' ' + e.job));
    return all.filter(e => ['PASS', 'FAILED'].includes(e.state) && !done.has(e.sha + ' ' + e.job));
  }
  note(line) { fs.mkdirSync(path.dirname(this.ledgerFile), { recursive: true }); fs.appendFileSync(this.ledgerFile, line + '\r\n'); }
  paused() {
    try { return PAUSE_LINE.test(fs.readFileSync(path.join(this.vt, 'gpu_go.txt'), 'utf8').split(/\r?\n/)[0]); } catch { return false; }
  }
  stopAsked() { return fs.existsSync(path.join(this.vt, 'pc_daemon', 'stop.txt')); }
  report(n, fn, what) {
    // GitHub reporting failures are logged and never fail the job (RULEBOOK 2.4)
    try { fn(); } catch (e) { this.log(`PR ${n}: could not ${what}: ${e.message}`); }
  }
  // One look at the board. Returns what it decided per PR, and runs at most one job (live only).
  async tick() {
    const seen = [];
    if (this.paused()) { this.log('paused: gpu_go.txt holds the Board pause; nothing starts'); return seen; }
    if (this.live) await this.redeliver();
    if (this.quarantined) { this.log(`quarantined, nothing starts: ${this.quarantined}`); return seen; }
    const ledger = this.ledger();
    for (const n of this.gh.readyPulls()) {
      const pull = this.gh.pull(n);
      const comments = this.gh.comments(n);
      const checkRuns = pull?.head?.sha ? this.gh.checkRuns(pull.head.sha) : [];
      const g = gate({ pull, comments, checkRuns, ledger });
      seen.push({ pr: n, ...g });
      this.log(`PR ${n}: ${g.verdict}: ${g.why}${g.spec?.job ? ` (job ${g.spec.job})` : ''}`);
      if (!this.live) { if (g.verdict === 'run') this.log(`  would run: ${describe(g.spec)}`); continue; }
      if (g.verdict === 'refuse') {
        const key = `${n} ${pull?.head?.sha} ${g.why}`;
        if (this.refused.has(key)) continue; // said once already (a label that would not come off)
        this.refused.add(key);
        this.report(n, () => this.gh.comment(n, `PC daemon (issue 1662): not run. ${g.why}. Fix it, then put a new "PC go:" comment and the ${READY} label back.`), 'comment');
        this.report(n, () => this.gh.removeLabel(n, READY), `remove ${READY}`);
      }
      if (g.verdict === 'run') {
        if (g.spec.slot === 'gpu' && this.tools.gameRunning()) { this.log('  Voidsworn is running (Ryan may be playing); GPU job waits'); continue; }
        await this.runJob(n, pull, g.spec);
        break; // one job per look; the next look starts fresh from GitHub
      }
    }
    return seen;
  }
  sweepProfiles() {
    // Leftover throwaway profiles from a daemon that stopped mid-job. Only after lease(): no other daemon runs on this
    // root, and this one has no job yet, so no profile here is in use.
    if (!this.leaseId) throw new Error('sweepProfiles needs the daemon lock first');
    const dir = path.join(this.slots, 'profiles');
    if (this.paused() || !fs.existsSync(dir)) return;
    for (const n of fs.readdirSync(dir)) {
      if (!PROFILE_NAME.test(n)) continue;
      try { removeInside(this.slots, path.join(dir, n)); this.log(`removed an old daemon profile ${n}`); }
      catch (e) { this.log(`kept ${n}: ${e.message}`); }
    }
  }
  newAttempt(job) {
    const jobDir = path.join(this.vt, job);
    fs.mkdirSync(jobDir, { recursive: true });
    for (let i = 1; i < 1000; i++) {
      const a = path.join(jobDir, `out_${stamp(this.clock())}_${i}`);
      try { fs.mkdirSync(a); return a; } catch (e) { if (e.code !== 'EEXIST') throw e; }
    }
    throw new Error('no free attempt folder name');
  }
  async runJob(n, pull, spec) {
    const sha = spec.sha;
    this.note(`${this.clock().toISOString()} ${sha} ${spec.job} PR${n} start`);
    this.report(n, () => this.gh.removeLabel(n, READY), `remove ${READY}`);
    this.report(n, () => this.gh.addLabel(n, RUNNING), `add ${RUNNING}`);
    const attempt = this.newAttempt(spec.job);
    const outDir = path.join(attempt, `out_${spec.job}`);
    fs.mkdirSync(outDir);
    const st = path.join(attempt, 'status.txt');
    const say = s => { fs.appendFileSync(st, `${this.clock().toISOString()} ${s}\r\n`); this.log(`  ${s}`); };
    fs.writeFileSync(path.join(attempt, 'pc_daemon_spec.json'), JSON.stringify({ pr: n, ...spec }, null, 2));
    this.report(n, () => this.gh.comment(n, `PC daemon (issue 1662): started ${spec.job} at ${sha.slice(0, 8)} (${spec.flow}, ${spec.slot} slot, ceiling ${Math.round(spec.ceilingS / 60)} min, stall ${spec.stallMin} min). Reviewed: ${spec.reviewed}.`), 'comment');
    const failed = [];
    let result = null, gpuToken = null, profile = null, slotTaken = false;
    const step = async (name, fn) => {
      if (failed.length) { say(`skipped ${name}: an earlier step failed`); return; }
      say(`step ${name}`);
      try { await fn(); } catch (e) { failed.push(name); say(`FAILED ${name}: ${e.message}`); }
    };
    let exe = null, repo = null;
    await step('preflight', () => { const t = this.tools.preflight(attempt, [spec.flow], st); exe = t[spec.flow]; });
    await step('options before', () => this.tools.hashes(path.join(attempt, 'real_options_before.txt'), st));
    await step('slot', () => { slotTaken = true; repo = this.tools.slot(attempt, `pr${n}`, sha, spec.slot, st); say(`slot repo ${repo}`); });
    if (spec.ships) await step('ships', () => this.tools.ships(attempt, repo, `pr${n}`, spec.hulls, st));
    if (spec.gpu !== 'none') await step('gpu claim', () => { gpuToken = this.tools.gpuAcquire(`pcd_${spec.job}`, spec.gpu, spec.weight); say(`GPU ${spec.gpu} claim ${gpuToken}`); });
    await step('run', async () => {
      profile = path.join(this.slots, 'profiles', `pcd-profile-${crypto.randomUUID().replace(/-/g, '')}`);
      fs.mkdirSync(profile, { recursive: true });
      const { args, cwd } = command(spec, repo, outDir);
      say(`run ${path.basename(exe)} ${args.join(' ')}`);
      // throwaway profile: Godot and Blender keep their user data under APPDATA (issue 1228); Ryan's is never opened
      const env = { ...process.env, APPDATA: profile, LOCALAPPDATA: profile, VS_OUT: outDir, VS_REPO: repo, PC_GPU_ISSUE: `pcd_${spec.job}` };
      result = await this.watchImpl({ exe, args, cwd, env, ceilingMs: spec.ceilingS * 1000, stallMs: spec.stallMin * 60000,
        progressDirs: [outDir], logFile: path.join(attempt, 'run_log.txt'), pollMs: this.pollMs });
      say(`watchdog: ${result.reason}, exit ${result.code}, ${Math.round(result.ms / 1000)} s, ${result.bytes} bytes of output`);
      if (result.reason !== 'exit') throw new Error(result.reason === 'start' ? 'the program did not start' : `stopped at the ${result.reason === 'ceiling' ? 'hard ceiling' : 'stall limit'}`);
      if (result.code !== 0) throw new Error(`exit ${result.code}`);
    });
    if (result?.unkilled) {
      // the tree may still be running in the slot: keep the GPU claim, the profile and the slot lease held by this
      // process, and start nothing more until the Board has looked (Artoo on PR 1835)
      this.quarantined = `PR ${n} ${spec.job}: the process tree did not end; slot, GPU claim and profile kept. Attempt ${attempt}`;
      say('QUARANTINE: ' + this.quarantined);
      gpuToken = null; profile = null; slotTaken = false;
    }
    if (gpuToken) { try { this.tools.gpuRelease(gpuToken); say('GPU claim released'); } catch (e) { say(`GPU release: ${e.message} (the claim ends with this process)`); } }
    if (profile) {
      if (this.paused()) say(`profile kept during the Board pause: ${profile}`);
      else { try { removeInside(this.slots, profile); say('throwaway profile removed'); } catch (e) { say(`profile kept: ${e.message}`); } }
    }
    await step('outputs', () => { const miss = expectMissing(outDir, spec.expect); if (miss.length) throw new Error(`missing or empty: ${miss.join(', ')}`); });
    // the options check runs even after a failed step: a job that touched Ryan's settings must say so
    try {
      const after = this.tools.hashes(path.join(attempt, 'real_options_after.txt'), st);
      const before = fs.readFileSync(path.join(attempt, 'real_options_before.txt'), 'utf8');
      if (before !== after) { failed.push('options'); say("FAILED options: Ryan's real battle_opts.json or board_look.cfg changed during the job"); }
      else say("Ryan's real options unchanged");
    } catch (e) { if (!failed.includes('options before')) { failed.push('options'); say(`FAILED options: ${e.message}`); } }
    if (slotTaken) { try { this.tools.slotRelease(attempt, st); say('slot let go'); } catch (e) { say(`slot release: ${e.message}`); } }
    const pass = failed.length === 0;
    fs.writeFileSync(path.join(attempt, 'done.txt'), pass ? 'done PASS\r\n' : `done FAILED: ${failed.join(', ')}\r\n`);
    say(pass ? 'done PASS' : `done FAILED: ${failed.join(', ')}`);
    fs.writeFileSync(path.join(attempt, 'pc_daemon_result.json'), JSON.stringify({ pr: n, spec, pass, failed, result, quarantined: !!result?.unkilled }, null, 2));
    this.note(`${this.clock().toISOString()} ${sha} ${spec.job} PR${n} ${pass ? 'PASS' : 'FAILED'} ${attempt}`);
    const links = this.deliver({ sha, job: spec.job, pr: n, attempt });
    this.report(n, () => this.gh.removeLabel(n, RUNNING), `remove ${RUNNING}`);
    return { pass, failed, attempt, result, links };
  }
  // Relay the attempt and post its result with the done marker; only both together write "delivered". A failed relay
  // or comment leaves the attempt as it is for redeliver(), which never reruns the job (Artoo on PR 1835).
  deliver(e) {
    const st = path.join(e.attempt, 'status.txt');
    const r = JSON.parse(fs.readFileSync(path.join(e.attempt, 'pc_daemon_result.json'), 'utf8'));
    const { spec, pass, failed, result } = r;
    (this.lastTry ||= new Map()).set(e.attempt, this.clock().getTime());
    const tries = (this.deliveryTries.get(e.attempt) || 0) + 1;
    this.deliveryTries.set(e.attempt, tries);
    let links;
    try { links = relayLinks(this.tools.relay(e.job, e.attempt, st)); if (!links.folder) throw new Error('no folder link printed'); }
    catch (err) {
      fs.appendFileSync(st, `${this.clock().toISOString()} relay failed (try ${tries}): ${err.message}\r\n`);
      if (tries === 1) this.report(e.pr, () => this.gh.comment(e.pr, `PC daemon (issue 1662): ${e.job} ${pass ? 'PASS' : 'FAILED'} at ${e.sha.slice(0, 8)} on the PC, but the relay failed (${err.message}). The daemon retries the relay every ${Math.round(this.retryMs / 60000)} minutes without rerunning the job; results stay at ${e.attempt}.`), 'comment');
      return null;
    }
    const body = [
      `PC daemon (issue 1662): ${e.job} ${pass ? 'PASS' : 'FAILED'} at ${e.sha.slice(0, 8)}`,
      '',
      pass ? '' : `- failed: ${failed.join(', ')}`,
      r.quarantined ? '- QUARANTINE: the process tree did not end; the daemon holds the slot and GPU and starts nothing until the Board looks' : '',
      result ? `- watchdog: ${result.reason}, exit ${result.code} after ${(result.ms / 60000).toFixed(1)} min (ceiling ${Math.round(spec.ceilingS / 60)} min, stall ${spec.stallMin} min)` : '- the job step did not start',
      `- results: ${links.folder}`,
      ...links.pictures.map(p => `- picture: ${p}`),
      tries > 1 ? `- relayed on try ${tries}` : '',
      `- reviewed before the run: ${spec.reviewed}`,
      '',
      DONE_MARK(e.sha, e.job)
    ].filter((l, i, a) => l !== '' || (i > 0 && a[i - 1] !== '')).join('\n');
    try { this.gh.comment(e.pr, body); }
    catch (err) { fs.appendFileSync(st, `${this.clock().toISOString()} result comment failed: ${err.message}\r\n`); return null; }
    this.note(`${this.clock().toISOString()} ${e.sha} ${e.job} PR${e.pr} delivered ${e.attempt}`);
    this.deliveryTries.delete(e.attempt); this.lastTry?.delete(e.attempt);
    return links;
  }
  async redeliver() {
    this.lastTry ||= new Map();
    for (const e of this.undelivered()) {
      const last = this.lastTry.get(e.attempt) || 0, t = this.clock().getTime();
      if (last && t - last < this.retryMs) continue;
      if (!fs.existsSync(path.join(e.attempt, 'pc_daemon_result.json'))) continue;
      this.log(`redelivering ${e.job} at ${e.sha.slice(0, 8)} (PR ${e.pr})`);
      this.deliver(e);
    }
  }
}
function command(spec, repo, outDir) {
  const sub = a => a.replaceAll('{out}', outDir).replaceAll('{repo}', repo);
  if (spec.flow === 'godot') {
    const args = [...(spec.headless ? ['--headless'] : []), '--path', path.join(repo, 'godot'), ...(spec.script ? ['--script', spec.script] : []), ...spec.args.map(sub)];
    return { args, cwd: path.join(repo, 'godot') };
  }
  return { args: ['-b', '--factory-startup', '--python', path.join(repo, ...spec.script.split('/')), '--', ...spec.args.map(sub)], cwd: repo };
}
function describe(spec) {
  const { args } = command(spec, '<slot repo>', '<out>');
  return `${spec.flow} ${args.join(' ')} | ${spec.slot} slot, gpu ${spec.gpu}, ships ${spec.ships ? 'yes' : 'no'}, ceiling ${spec.ceilingS} s, stall ${spec.stallMin} min, expect ${spec.expect.join(' ')}`;
}

async function main(argv) {
  const live = argv.includes('--live'), once = argv.includes('--once') || !live && !argv.includes('--loop');
  const vt = process.env.PC_DAEMON_VT || path.join(process.env.USERPROFILE || '', 'Downloads', 'voidsworn_test');
  if (live && process.platform !== 'win32') throw new Error('--live runs on Ryan\'s PC only');
  const d = new Daemon({ vt, gh: new GhCli(), tools: new PcTools({ vt }), live });
  console.log(`PC daemon (issue 1662) ${live ? 'LIVE' : 'dry run: reads GitHub only, changes nothing'}; root ${vt}`);
  if (live) {
    d.lease();
    setInterval(() => { try { d.beat(); } catch (e) { console.error('PC daemon: ' + e.message); process.exit(3); } }, 30000).unref();
    d.sweepProfiles();
  }
  for (;;) {
    if (d.stopAsked()) { console.log('stop.txt found in pc_daemon; stopping'); return; }
    try { await d.tick(); } catch (e) { console.log(`look failed: ${e.message}`); }
    if (once) return;
    await new Promise(r => setTimeout(r, 120000));
  }
}
if (require.main === module) main(process.argv.slice(2)).catch(e => { console.error('PC daemon: ' + e.message); process.exitCode = 1; });
module.exports = { parseGo, gate, watch, newestTime, killTree, removeInside, GhCli, PcTools, Daemon, command, describe, relayLinks, expectMissing, DONE_MARK, READY, RUNNING };
