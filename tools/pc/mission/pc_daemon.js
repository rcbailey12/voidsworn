'use strict';
// Issue 1662 run 1 (Ryan, Nov 22 2026, studio ops plan Wave 4.1): the label-driven PC runner daemon.
//   node pc_daemon.js            dry run: reads GitHub, prints what it would run, changes nothing anywhere
//   node pc_daemon.js --once     one dry look and exit
//   node pc_daemon.js --live     runs jobs (the Board turns this on only after its review and a PC proof)
// A pull request is run when all of these hold (RULEBOOK 3.12, owner decision 3), checked when it is picked and again
// right before the job starts:
//   it is open, from this repo (never a fork), labelled pc-ready (at pick);
//   the newest owner comment that starts "PC go" names its current head commit, is well formed and says who passed
//   the diff ("reviewed:"); a newer malformed one holds the job, an older good one never wins;
//   the "All checks" run at that head commit, made by GitHub Actions for .github/workflows/checks.yml, ended success;
//   the daemon has no result for that commit and job yet (its own ledger and its own done marker on the PR).
// Then, one job at a time: claim (pc-ready must come off, running on, a status comment), a new attempt folder
// voidsworn_test\<job>\out_<stamp>_<n>, a warm slot reset to the head commit, the built ships copied in, Ryan's real
// options hashed, the Godot or Blender step through the installed watchdog run_timeout.ps1 (RULEBOOK 3.5: hard
// ceiling, idle stop, Windows Job Object with verified kill, GPU admission by its own classifier, the game-open wait,
// a throwaway Godot profile it makes and removes), the outputs and options checked, the slot let go, the relay push,
// a result comment, running off.
// Run 1 keeps the proven Windows pieces it calls from tools_live: the slot lease and reset (opus_job_head.ps1 slot and
// slotrelease), the ships checks (tracked, shipcheck, shiprecord, hashes), the tool preflight (runner_common.ps1), the
// watchdog (run_timeout.ps1) and relay_push.ps1. Later runs move those one flow at a time.
// Astra's run 2 recheck (issue 1836) moved the last checks into the watchdog itself, through opt-in settings only this
// daemon sets (PC_STEP_*): the approval, pause, hold and game are read again after the game wait and GPU admission,
// right before the start (node pc_daemon.js --recheck <attempt>); the step ends only once its Job Object is empty; the
// throwaway profile (Godot and Blender alike) and child logs live in the held slot's run_scratch folder; the watchdog's
// own record (watchdog_record.json) says whether the tree is proven gone, never the child's log text.
// Deletes: its temporary GitHub request files in TEMP, and its own in-flight marker (the slot's hold.txt it wrote, only
// while it still holds exactly what it wrote, once the watchdog proved the tree gone). The slot reset it asks the head
// for deletes only inside voidsworn_test\slots; the watchdog removes only the profile and logs it made in run_scratch.
// Node 22, built-in modules only.
const fs = require('fs');
const os = require('os');
const net = require('net');
const path = require('path');
const crypto = require('crypto');
const { spawn, spawnSync } = require('child_process');

const REPO = 'rcbailey12/voidsworn';
const READY = 'pc-ready';
const RUNNING = 'running';
const CHECK_NAME = 'All checks';
const CHECKS_WORKFLOW = '.github/workflows/checks.yml';
const OWNERS = ['rcbailey12'];
const TRUSTED = new Set(['OWNER', 'MEMBER', 'COLLABORATOR']);
const MAX_CEILING_S = 6 * 3600; // RULEBOOK 3.5's default hard ceiling
const DEFAULT_CEILING_S = 3600;
const DEFAULT_STALL_MIN = 30;
const LEASE_PORT = 47662;       // the daemon's one-per-PC lease: an exclusive localhost bind the OS frees on exit
const PAUSE_LINE = /^GPU not cleared: paused by the Board\b/;
const SLOT_REPO = /^slot_(?:gpu_1|gpu_2|cpu)$/;
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
// optional: slot: gpu|cpu (gpu), gpu: auto|solo|none (auto: the watchdog's classifier decides; none only for Blender),
//   ships: yes|no (yes for godot, no for blender), hulls: <codes>, headless: yes|no (no; a cpu slot needs a headless
//   Godot or a Blender job that says gpu: none itself), timeout: <seconds, ceiling> (3600, at most 21600), stall: <minutes with no output>
//   (30, 5 to 360; the watchdog's step idle limit)
const GO_LINE = /^\s*PC go\b/i;
function parseGo(body) {
  const lines = String(body || '').replace(/\r/g, '').split('\n').map(l => l.trim()).filter(Boolean);
  if (!GO_LINE.test(lines[0] || '')) return null;
  const head = /^PC go:\s*([0-9a-f]{40})$/.exec(lines[0]);
  if (!head) return { sha: null, error: 'the first line must be exactly "PC go: <40-character commit>"' };
  const kv = {};
  for (const line of lines.slice(1)) {
    if (line.startsWith('```') || line.startsWith('<!--') || line === '---') continue;
    const m = /^([a-z]+):\s*(.*)$/.exec(line);
    if (!m) continue;
    if (kv[m[1]] !== undefined) return { sha: head[1], error: `the line "${m[1]}:" is given twice` };
    kv[m[1]] = m[2].trim();
  }
  const fail = error => ({ sha: head[1], error });
  const known = ['reviewed', 'job', 'flow', 'script', 'args', 'expect', 'slot', 'gpu', 'ships', 'hulls', 'headless', 'timeout', 'stall'];
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
    // a cpu slot Blender job must say gpu: none itself; nothing defaults a Blender step to no claim (Astra run 2, item 6)
    const gpu = kv.gpu || 'auto';
    if (!['auto', 'solo', 'none'].includes(gpu)) throw new Error('gpu must be auto, solo or none');
    if (gpu === 'none' && kv.flow !== 'blender') throw new Error('gpu: none is for Blender only; Godot GPU use is classified by the watchdog');
    const headless = yesNo('headless', false);
    if (slot === 'cpu' && (gpu === 'solo' || (kv.flow === 'godot' && !headless) || (kv.flow === 'blender' && gpu !== 'none'))) {
      throw new Error('a cpu slot job does no GPU work: headless: yes for Godot, gpu: none for Blender');
    }
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
      ships: yesNo('ships', kv.flow === 'godot'), hulls, headless,
      ceilingS: int('timeout', DEFAULT_CEILING_S, 60, MAX_CEILING_S), stallMin: int('stall', DEFAULT_STALL_MIN, 5, 360)
    };
  } catch (e) { return fail(e.message); }
}

// ------------------------------------------------------------------------------------------------------- the gate
// Returns { verdict, why, spec }: run (start it), wait (look again later), refuse (tell the PR once, take the label off),
// skip (already done or not ours; say nothing). claimed: the recheck right before launch, after this daemon took the
// pc-ready label off itself and before any result exists.
function gate({ pull, comments, complete = true, checkRuns, workflowRuns = [], ledger = new Set(), owners = OWNERS, repo = REPO, claimed = false }) {
  const sha = pull?.head?.sha;
  if (!pull || pull.state !== 'open') return { verdict: 'skip', why: 'not open' };
  if (pull.head?.repo?.full_name !== repo) return { verdict: 'refuse', why: 'the branch is on a fork; the PC never runs fork code' };
  if (!claimed && !(pull.labels || []).some(l => l.name === READY)) return { verdict: 'skip', why: `no ${READY} label on the pull request` };
  if (!complete) return { verdict: 'refuse', why: 'the comment history could not be read to its end, so the newest PC go is unknown' };
  const ours = c => owners.includes(c.user?.login) && TRUSTED.has(c.author_association);
  const done = new Set();
  for (const c of comments) if (ours(c)) for (const m of String(c.body || '').matchAll(DONE_RE)) done.add(m[1] + ' ' + m[2]);
  const newest = [...comments].sort((a, b) => String(a.created_at || '').localeCompare(String(b.created_at || '')))
    .reverse().find(c => ours(c) && GO_LINE.test(String(c.body || '').trimStart()));
  if (!newest) return { verdict: 'wait', why: 'no "PC go:" comment from the owner account yet' };
  const go = parseGo(newest.body);
  if (go.error && !go.sha) return { verdict: 'refuse', why: 'the newest PC go comment is not usable: ' + go.error };
  if (go.sha !== sha) return { verdict: 'refuse', why: `the newest PC go names ${go.sha.slice(0, 8)} but the head is ${sha.slice(0, 8)}; a later push needs green checks and a review again (RULEBOOK 3.12)` };
  if (go.error) return { verdict: 'refuse', why: 'the newest PC go comment is not usable: ' + go.error };
  if (!claimed && (done.has(sha + ' ' + go.job) || ledger.has(sha + ' ' + go.job))) return { verdict: 'skip', why: `${go.job} already ran at ${sha.slice(0, 8)}` };
  // The newest checks.yml run at this commit (and its newest attempt) decides, through its own "All checks" (Astra run 2,
  // item 8): an older green run never stands in for a newer run that has not reached its aggregate yet.
  const num = v => Number(v) || 0;
  const wr = workflowRuns.filter(w => w.path === CHECKS_WORKFLOW && w.head_sha === sha)
    .sort((a, b) => num(b.run_number) - num(a.run_number) || num(b.run_attempt) - num(a.run_attempt) || String(b.created_at || '').localeCompare(String(a.created_at || '')))[0];
  if (!wr) return { verdict: 'wait', why: `no ${CHECKS_WORKFLOW} run at ${sha.slice(0, 8)} yet`, spec: go };
  if (wr.status !== 'completed') return { verdict: 'wait', why: `the newest ${CHECKS_WORKFLOW} run is ${wr.status}`, spec: go };
  if (wr.conclusion !== 'success') return { verdict: 'refuse', why: `the newest ${CHECKS_WORKFLOW} run ended ${wr.conclusion} at ${sha.slice(0, 8)}` };
  const run = checkRuns.filter(r => r.name === CHECK_NAME && r.head_sha === sha && r.app?.slug === 'github-actions' && r.check_suite?.id === wr.check_suite_id)
    .sort((a, b) => String(b.started_at || '').localeCompare(String(a.started_at || '')))[0];
  if (!run) return { verdict: 'wait', why: `no "${CHECK_NAME}" in the newest ${CHECKS_WORKFLOW} run at ${sha.slice(0, 8)}`, spec: go };
  if (run.status !== 'completed') return { verdict: 'wait', why: `"${CHECK_NAME}" is ${run.status}`, spec: go };
  if (run.conclusion !== 'success') return { verdict: 'refuse', why: `"${CHECK_NAME}" ended ${run.conclusion} at ${sha.slice(0, 8)}` };
  return { verdict: 'run', why: 'green checks, review named, PC go at the head commit', spec: go };
}

// --------------------------------------------------------------------------------------- one step, output logged
// Starts exe (never through a shell), appends its output to logFile and resolves { code, ms, output, backstop } when
// it closes. The watchdog inside the step kills and verifies; this only waits. After backstopMs it stops waiting
// (backstop: true) and kills nothing: the caller quarantines, since the step may still be running.
function runLogged({ exe, args, cwd, env, logFile, backstopMs, now = Date.now }) {
  return new Promise(resolve => {
    const start = now();
    const log = fs.openSync(logFile, 'a');
    let output = '', done = false, timer = null, startError = false;
    const say = s => { try { fs.writeSync(log, s); } catch { /* best effort */ } };
    const finish = (code, backstop = false) => {
      if (done) return;
      done = true; clearTimeout(timer);
      say(`[pc_daemon ${new Date().toISOString()}] ${backstop ? 'stopped waiting (backstop); the step may still run' : 'step ended, exit ' + code}\n`);
      try { fs.closeSync(log); } catch { /* closed */ }
      resolve({ code, ms: now() - start, output, backstop, startError });
    };
    say(`[pc_daemon ${new Date(start).toISOString()}] start ${exe} ${args.join(' ')}\n`);
    let child;
    try { child = spawn(exe, args, { cwd, env, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] }); }
    catch (e) { say(`could not start: ${e.code || e.message}\n`); startError = true; finish(null); return; }
    const take = chunk => { const s = chunk.toString('utf8'); output = (output + s).slice(-200000); say(s); };
    child.stdout.on('data', take);
    child.stderr.on('data', take);
    child.on('error', e => { say(`could not start: ${e.code || e.message}\n`); if (!child.pid) startError = true; finish(null); });
    child.on('close', code => finish(code));
    timer = setTimeout(() => finish(null, true), backstopMs);
  });
}
// What the watchdog's step means for the daemon. The tree state comes only from the watchdog's own record
// (PC_STEP_RECORD), never from the mixed output, where a child's log line could fake or hide it (Astra run 2, item F).
// No record, or a record that does not say the Job Object was seen empty, is a quarantine: the tree is unproven.
function inside(p, dir) {
  const rel = path.relative(path.resolve(dir).toLowerCase(), path.resolve(p).toLowerCase());
  return !!rel && !rel.startsWith('..') && !path.isAbsolute(rel);
}
function readRecord(file) { try { return JSON.parse(fs.readFileSync(file, 'utf8').replace(/^﻿/, '')); } catch { return null; } }
function readWatchdog(r, rec, scratch) {
  if (r.backstop) return { ok: false, quarantine: true, why: 'the watchdog did not end within its ceiling plus the waits' };
  if (r.startError) return { ok: false, why: 'the watchdog could not be started' };
  if (!rec) return { ok: false, quarantine: true, why: 'the watchdog left no step record, so the process tree is unproven' };
  if (rec.treeEmpty !== true) return { ok: false, quarantine: true, why: `processes outlived the step or could not be proven gone (${rec.reason || 'exit ' + r.code})` };
  if (rec.gated) return { ok: false, gated: String(rec.gated).trim(), why: 'the launch gate said no' };
  if (rec.started && !rec.profile) return { ok: false, why: 'the step ran without a throwaway profile' };
  if (rec.profile && !(scratch && inside(rec.profile, scratch))) return { ok: false, why: `the throwaway profile was made outside the slot: ${rec.profile}` };
  const kept = rec.profile && !rec.profileRemoved ? '; its throwaway profile was kept for the janitor' : '';
  if (r.code === 0) return { ok: true, why: 'exit 0' + kept };
  if (r.code === 124) return { ok: false, why: (rec.reason || 'stopped by the watchdog (exit 124)') + kept };
  if (r.code === 125) return { ok: false, why: 'the watchdog could not start the step (exit 125)' + (rec.reason ? ': ' + rec.reason : '') };
  if (r.code === 126) return { ok: false, why: 'GPU admission failed (exit 126)' };
  return { ok: false, why: `exit ${r.code}` + kept };
}
// Windows command-line quoting (the rules CommandLineToArgvW reads): backslashes are doubled only before a quote, so a
// folder argument that ends in a backslash no longer swallows the next argument (Astra run 2, item E).
function winQuote(a) {
  a = String(a);
  if (a && !/[\s"]/.test(a)) return a;
  let out = '"', slashes = 0;
  for (const ch of a) {
    if (ch === '\\') { slashes++; continue; }
    out += ch === '"' ? '\\'.repeat(slashes * 2 + 1) + '"' : '\\'.repeat(slashes) + ch;
    slashes = 0;
  }
  return out + '\\'.repeat(slashes * 2) + '"';
}

// --------------------------------------------------------------------------------------------------------- GitHub
// Every call goes through `gh api` (REST only, RULEBOOK 2.5), with the PC's own sign-in. No tokens pass through here.
class GhCli {
  constructor({ repo = REPO, gh = 'gh', run = spawnSync } = {}) { this.repo = repo; this.gh = gh; this.run = run; }
  api(args, input) {
    let file = null;
    if (input !== undefined) {
      file = path.join(os.tmpdir(), `pcd-${crypto.randomUUID()}.json`);
      fs.writeFileSync(file, JSON.stringify(input));
      args = [...args, '--input', file];
    }
    try {
      const r = this.run(this.gh, ['api', ...args], { encoding: 'utf8', timeout: 120000, windowsHide: true, maxBuffer: 64 << 20 });
      if (r.status !== 0) throw new Error(`gh api ${args[0]} ${args[1] || ''}: exit ${r.status}: ${String(r.stderr || '').trim().slice(0, 300)}`);
      return r.stdout.trim() ? JSON.parse(r.stdout) : null;
    } finally { if (file) try { fs.unlinkSync(file); } catch { /* temp file */ } }
  }
  // { items, complete }: complete is false when the page cap was reached on a full page
  pages(route, key) {
    const items = [];
    for (let page = 1; page <= 100; page++) {
      const got = this.api([`${route}${route.includes('?') ? '&' : '?'}per_page=100&page=${page}`]);
      const list = Array.isArray(got) ? got : (got?.[key] || []);
      items.push(...list);
      if (list.length < 100) return { items, complete: true };
    }
    return { items, complete: false };
  }
  readyPulls() { return this.pages(`repos/${this.repo}/issues?state=open&labels=${READY}`).items.filter(i => i.pull_request).map(i => i.number); }
  pull(n) { return this.api([`repos/${this.repo}/pulls/${n}`]); }
  comments(n) { return this.pages(`repos/${this.repo}/issues/${n}/comments`); }
  checkRuns(sha) { return this.pages(`repos/${this.repo}/commits/${sha}/check-runs?check_name=${encodeURIComponent(CHECK_NAME)}`, 'check_runs').items; }
  workflowRuns(sha) { return this.pages(`repos/${this.repo}/actions/runs?head_sha=${sha}`, 'workflow_runs').items; }
  addLabel(n, label) { this.api(['-X', 'POST', `repos/${this.repo}/issues/${n}/labels`], { labels: [label] }); }
  removeLabel(n, label) { this.api(['-X', 'DELETE', `repos/${this.repo}/issues/${n}/labels/${encodeURIComponent(label)}`]); }
  comment(n, body) { this.api(['-X', 'POST', `repos/${this.repo}/issues/${n}/comments`], { body }); }
}

// ------------------------------------------------------------------------------------------------- PC paths
// The PC root must be an absolute plain folder whose every parent is a plain folder too (no link or junction anywhere
// on the way), and in live use exactly %USERPROFILE%\Downloads\voidsworn_test (Astra audit of PR 1835, finding 5).
function plainChain(p) {
  const parts = [];
  for (let cur = p; ; cur = path.dirname(cur)) { parts.push(cur); if (path.dirname(cur) === cur) break; }
  for (const q of parts.reverse()) {
    const st = fs.lstatSync(q);
    if (!st.isDirectory() || st.isSymbolicLink()) throw new Error(`not a plain folder: ${q}`);
  }
}
function checkRoot(vt, { live, profile = process.env.USERPROFILE } = {}) {
  if (!vt || !path.isAbsolute(vt)) throw new Error(`the PC root must be an absolute path, got: ${vt || '(empty)'}`);
  const root = path.resolve(vt);
  if (live) {
    if (!profile || !path.isAbsolute(profile)) throw new Error('USERPROFILE is not an absolute path');
    const want = path.join(profile, 'Downloads', 'voidsworn_test');
    if (root.toLowerCase() !== path.resolve(want).toLowerCase()) throw new Error(`a live daemon runs only on ${want}, not ${root}`);
  }
  plainChain(root);
  return root;
}
function checkSlotRepo(vt, repo) {
  // the head's slot receipt must name <vt>\slots\slot_<gpu_1|gpu_2|cpu>\repo, all plain folders
  if (!repo || !path.isAbsolute(repo)) throw new Error(`the slot receipt is not an absolute path: ${repo || '(empty)'}`);
  const r = path.resolve(repo), slot = path.dirname(r);
  if (path.basename(r) !== 'repo' || !SLOT_REPO.test(path.basename(slot)) || path.dirname(slot).toLowerCase() !== path.join(vt, 'slots').toLowerCase()) {
    throw new Error(`the slot receipt is not a warm slot under ${path.join(vt, 'slots')}: ${r}`);
  }
  plainChain(r);
  return r;
}

// ----------------------------------------------------------------------------------------------- the PC's own tools
// The proven tools_live pieces this run calls. Every path is checked; the only delete is the daemon's own in-flight
// marker (clearInFlight).
class PcTools {
  constructor({ vt, run = spawnSync, runStep = runLogged, testEnv = null } = {}) { Object.assign(this, { vt, run, runStep, testEnv, pinned: null }); }
  pc() {
    if (this.pinned) return this.pinned;
    const current = fs.readFileSync(path.join(this.vt, 'tools_live', 'current.txt'), 'utf8').trim();
    if (!/^[A-Za-z0-9._-]+$/.test(current)) throw new Error(`tools_live\\current.txt is not a version name: ${current}`);
    const pc = path.join(this.vt, 'tools_live', current, 'pc');
    for (const f of [path.join('jobs', 'opus_job_head.ps1'), 'run_timeout.ps1', 'relay_push.ps1', 'runner_common.ps1']) {
      if (!fs.existsSync(path.join(pc, f))) throw new Error(`no installed ${f} at ${pc}`);
    }
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
  // The attempt's tools version, checked against its own hashes.txt by the head's bundle check (tmo.bat,
  // run_timeout.ps1, opus_job_head.bat and .ps1; RULEBOOK 3.5's strict watchdog check), then pinned: every later call of
  // the attempt uses that same version even if a refresh moves current.txt meanwhile (Astra run 2, item D).
  pin(log) {
    this.pinned = null;
    const pc = this.pc();
    this.ps(path.join(pc, 'jobs', 'opus_job_head.ps1'), ['bundle', 'daemon', pc, path.join(path.dirname(pc), 'hashes.txt')], { log, timeoutMs: 120000 });
    this.pinned = pc;
    return pc;
  }
  unpin() { this.pinned = null; }
  preflight(attempt, tools, log) {
    this.ps(path.join(this.pc(), 'runner_common.ps1'), ['preflight-tools', attempt, tools.join(' ')], { log, timeoutMs: 300000 });
    const found = {};
    for (const line of fs.readFileSync(path.join(attempt, 'tools.cmd'), 'utf8').split(/\r?\n/)) {
      const m = /^set "?JW_([A-Z]+)=(.*?)"?$/.exec(line.trim());
      if (m) found[m[1].toLowerCase()] = m[2];
    }
    for (const t of tools) if (!found[t] || !path.isAbsolute(found[t])) throw new Error(`preflight found no ${t}`);
    return found;
  }
  hashes(file, log) { this.head(['hashes', file], { log, timeoutMs: 120000 }); return fs.readFileSync(file, 'utf8'); }
  slot(attempt, name, pin, kind, log) {
    this.head(['slot', attempt, name, pin], { env: { OJ_SLOT_KIND: kind }, log, timeoutMs: 7 * 3600000 });
    return fs.readFileSync(path.join(attempt, 'slot_repo.txt'), 'utf8').trim();
  }
  slotRelease(attempt, log) { this.head(['slotrelease', attempt], { log, timeoutMs: 120000 }); }
  // The head's own lease record must agree with its receipt (Astra run 2, item 5): <attempt>\slot.txt names the slot
  // folder and token, the slot is of the kind asked for, its owner.txt names this attempt and token and is not
  // released, and its holder still answers for the token. Returns { dir, token }.
  slotLease(attempt, repo, kind) {
    const parts = fs.readFileSync(path.join(attempt, 'slot.txt'), 'utf8').trim().split('|');
    if (parts.length !== 2 || !/^[0-9a-f]{32}$/.test(parts[1])) throw new Error('slot.txt is not "<slot>|<token>"');
    const [dir, token] = parts, same = (a, b) => path.resolve(a).toLowerCase() === path.resolve(b).toLowerCase();
    if (!same(dir, path.dirname(repo))) throw new Error(`the slot receipt ${repo} is not the leased slot ${dir}`);
    const names = kind === 'cpu' ? ['slot_cpu'] : ['slot_gpu_1', 'slot_gpu_2'];
    if (!names.includes(path.basename(dir))) throw new Error(`a ${kind} job got ${path.basename(dir)}`);
    const owner = fs.readFileSync(path.join(dir, 'owner.txt'), 'utf8');
    const lines = owner.split(/\r?\n/);
    if (!lines.includes(`token ${token}`)) throw new Error(`${dir}\\owner.txt does not name this attempt's token`);
    if (!lines.some(l => l.startsWith('attempt ') && same(l.slice(8), attempt))) throw new Error(`${dir}\\owner.txt does not name this attempt`);
    if (lines.some(l => l.startsWith('released'))) throw new Error(`the lease on ${dir} was already let go`);
    if (!/^held \d+ \d+/.test(fs.readFileSync(path.join(dir, `holder_${token}.txt`), 'utf8').trim())) throw new Error(`no holder answers for ${dir}`);
    return { dir, token };
  }
  // Before the step starts, the slot is set aside with hold.txt naming this attempt (Enter-Slot skips a slot with
  // hold.txt). If the daemon stops mid-step, the slot holder lets the lease go with the daemon's process, but the
  // marker keeps every later job out of a slot whose step may still run, until the Board has looked (Astra run 2,
  // item 4). Also makes the step's own scratch folder beside the slot repo. Returns { marker, text, scratch }.
  inFlight(lease, attempt) {
    const marker = path.join(lease.dir, 'hold.txt');
    const text = `pc_daemon in flight: attempt ${attempt} token ${lease.token}\r\n` +
      `set by pc_daemon.js ${new Date().toISOString()}. If no daemon is running this attempt, its step may still be running here.\r\n` +
      'The daemon removes this file itself only after the watchdog proved the step gone; otherwise the Board removes it once it has looked.\r\n';
    fs.writeFileSync(marker, text, { flag: 'wx' });
    const scratch = path.join(lease.dir, 'run_scratch');
    fs.mkdirSync(scratch, { recursive: true });
    plainChain(scratch);
    return { marker, text, scratch };
  }
  clearInFlight(f) {
    // only the exact marker this attempt wrote: anything added to it (a quarantine, the Board) keeps it
    if (fs.readFileSync(f.marker, 'utf8') !== f.text) throw new Error(`${f.marker} changed since the daemon wrote it; kept`);
    fs.unlinkSync(f.marker);
  }
  holdInFlight(f, why) { fs.appendFileSync(f.marker, `QUARANTINE: ${why}\r\nThe Board removes this file once it has looked.\r\n`); }
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
  // The job step through the installed watchdog, in step mode (tmo.bat's contract: TMO_ARGS "<seconds> <exe> <args>"),
  // with the daemon's opt-in step settings: the watchdog's own record, wait for an empty Job Object, the throwaway
  // profile for every target in the slot's scratch folder, and the launch gate (this script's --recheck).
  watchdog({ exe, args, cwd, env, ceilingS, stallMin, outDir, label, gpu, logFile, record, scratch, gateJs, gateArg }) {
    if (/"/.test(exe)) throw new Error('the program path holds a quote');
    const stepEnv = { ...env, TMO_ARGS: `${ceilingS} "${exe}" ${args.map(winQuote).join(' ')}`, TMO_STEP: label, TMO_STEP_OUT: outDir,
      TMO_IDLE_S: String(stallMin * 60), PC_GPU_ISSUE: label, PC_GPU_MODE: gpu === 'auto' ? '' : gpu, PC_GPU_WAIT_SECONDS: '3600',
      PC_STEP_RECORD: record, PC_STEP_WAIT_TREE: '1', PC_STEP_SCRATCH_PARENT: scratch, PC_STEP_PROFILE_ANY: '1',
      PC_STEP_GATE_JS: gateJs || '', PC_STEP_GATE_ARG: gateArg || '',
      TMO_REPO: '', TMO_OUT: '', TMO_LOG: '', TMO_ERR_LOG: '', PC_RUNNER_TEST: '', TMO_OWN_COPY: '', PC_REAL_PROFILE: '',
      PC_RUN_SCRATCH: '', PC_KEEP_GODOT_PROFILE: '', ...(this.testEnv || {}) };
    // backstop: the ceiling, up to 8 hours of the game-open wait and an hour of GPU admission, plus slack
    return this.runStep({ exe: 'powershell.exe', args: ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(this.pc(), 'run_timeout.ps1')],
      cwd, env: stepEnv, logFile, backstopMs: (ceilingS + 9.5 * 3600) * 1000 });
  }
  relay(job, attempt, log) { return this.ps(path.join(this.pc(), 'relay_push.ps1'), [job, attempt], { log, timeoutMs: 3 * 3600000 }); }
  gameRunning() {
    // Ryan playing (R173): true, false, or null when the process list could not be read (the caller waits on null)
    const r = this.run('tasklist', ['/FI', 'IMAGENAME eq Voidsworn*', '/FO', 'CSV', '/NH'], { encoding: 'utf8', timeout: 30000, windowsHide: true });
    if (r.status !== 0) return null;
    return /Voidsworn/i.test(String(r.stdout || ''));
  }
}

// ---------------------------------------------------------------------------------------- the one-per-PC lease
// An exclusive bind on 127.0.0.1:<port>: the OS holds it for exactly this process's life and frees it on any exit,
// so two daemons can never both hold it (Astra audit of PR 1835, finding 2). Any bind error fails closed.
function takeLease(port = LEASE_PORT) {
  return new Promise((resolve, reject) => {
    const server = net.createServer(socket => socket.destroy());
    server.once('error', e => reject(new Error(e.code === 'EADDRINUSE' ? `another PC daemon holds the lease (port ${port})` : `could not take the daemon lease: ${e.code || e.message}`)));
    server.listen({ host: '127.0.0.1', port, exclusive: true }, () => { server.unref(); resolve(server); });
  });
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
function writeAtomic(file, text) {
  const tmp = `${file}.${process.pid}.tmp`;
  fs.writeFileSync(tmp, text); fs.renameSync(tmp, file);
}

class Daemon {
  constructor({ vt, gh, tools, live = false, log = s => console.log(s), clock = () => new Date(), leased = false }) {
    Object.assign(this, { vt, gh, tools, live, log, clock, leased });
    this.dir = path.join(vt, 'pc_daemon');
    this.ledgerFile = path.join(this.dir, 'ran.txt');
    this.holdFile = path.join(this.dir, 'hold.txt');
    this.refused = new Set();
    this.reported = new Set();
    this.deliveryTries = new Map();
    this.lastTry = new Map();
    this.retryMs = 30 * 60000;
    this.mine = new Set(); // attempts this process started
  }
  // ran.txt lines: "<time> <sha> <job> PR<n> <state> <attempt>", state start, aborted, PASS, FAILED or delivered.
  // An abort (approval changed before launch) does not block a new go; a result does, and a result with no delivered
  // line is relayed and reported again without a rerun. A start with nothing after it from an earlier daemon process
  // means that daemon stopped mid-job: interrupted() sets the daemon hold for the Board (Astra run 2, item 4).
  entries() {
    try {
      return fs.readFileSync(this.ledgerFile, 'utf8').split(/\r?\n/).filter(Boolean).map(l => {
        const p = l.split(' ');
        return { sha: p[1], job: p[2], pr: +String(p[3]).slice(2), state: p[4], attempt: p.slice(5).join(' ') };
      });
    } catch { return []; }
  }
  interrupted() {
    const all = this.entries(), ended = new Set(all.filter(e => e.state !== 'start').map(e => e.attempt));
    return all.filter(e => e.state === 'start' && e.attempt && !ended.has(e.attempt) && !this.mine.has(e.attempt));
  }
  ledger() { return new Set(this.entries().filter(e => ['PASS', 'FAILED', 'delivered'].includes(e.state)).map(e => e.sha + ' ' + e.job)); }
  undelivered() {
    const all = this.entries(), done = new Set(all.filter(e => e.state === 'delivered').map(e => e.sha + ' ' + e.job));
    return all.filter(e => ['PASS', 'FAILED'].includes(e.state) && !done.has(e.sha + ' ' + e.job));
  }
  note(sha, job, n, state, attempt = '') {
    fs.mkdirSync(this.dir, { recursive: true });
    fs.appendFileSync(this.ledgerFile, `${this.clock().toISOString()} ${sha} ${job} PR${n} ${state}${attempt ? ' ' + attempt : ''}\r\n`);
  }
  paused() {
    // no gpu_go.txt means no pause; a file that cannot be read counts as paused (Artoo on ae304378)
    try { return PAUSE_LINE.test(fs.readFileSync(path.join(this.vt, 'gpu_go.txt'), 'utf8').split(/\r?\n/)[0]); }
    catch (e) { return e.code !== 'ENOENT'; }
  }
  held() { try { return fs.readFileSync(this.holdFile, 'utf8').split(/\r?\n/)[0] || 'hold.txt'; } catch (e) { return e.code === 'ENOENT' ? null : 'hold.txt unreadable'; } }
  stopAsked() { return fs.existsSync(path.join(this.dir, 'stop.txt')); }
  report(n, fn, what) {
    // GitHub reporting failures are logged and never fail the job (RULEBOOK 2.4)
    try { fn(); return true; } catch (e) { this.log(`PR ${n}: could not ${what}: ${e.message}`); return false; }
  }
  // Read again right before launch: the pause, the holds, the game and the whole approval (Astra findings 1 and 6, and
  // Artoo on a33b94f4). Returns null to go on, or why not. Never throws: a GitHub that cannot be read is a reason not
  // to start, and the job stays eligible (Astra run 2, item C). The watchdog calls it again through --recheck after
  // its game-open wait and GPU admission, right before the start.
  recheck(n, spec) {
    if (this.paused()) return 'the Board pause began';
    if (this.held()) return 'a daemon hold was set';
    const game = this.tools.gameRunning();
    if (game !== false) return game === null ? 'the process list could not be read, so the game check failed' : 'Voidsworn is running';
    let g;
    try { ({ g } = this.look(n, { claimed: true })); } catch (e) { return `GitHub could not be read for the recheck (${e.message})`; }
    if (g.verdict !== 'run') return `the approval changed while waiting (${g.why})`;
    // the whole approved spec must be the same, not only its job and commit
    if (JSON.stringify(g.spec) !== JSON.stringify(spec)) return 'the approval changed while waiting (a newer PC go replaced this job spec)';
    return null;
  }
  look(n, { claimed = false } = {}) {
    const pull = this.gh.pull(n);
    const { items: comments, complete } = this.gh.comments(n);
    const sha = pull?.head?.sha;
    const checkRuns = sha ? this.gh.checkRuns(sha) : [], workflowRuns = sha ? this.gh.workflowRuns(sha) : [];
    return { pull, g: gate({ pull, comments, complete, checkRuns, workflowRuns, ledger: this.ledger(), claimed }) };
  }
  // One look at the board. Returns what it decided per PR, and runs at most one job (live only).
  async tick() {
    const seen = [];
    if (this.live && !this.leased) throw new Error('a live daemon must hold the lease first');
    const lost = this.live ? this.interrupted() : [];
    if (lost.length && !this.held()) {
      this.setHold(`the daemon stopped in the middle of ${lost.map(e => `${e.job} (PR ${e.pr})`).join(', ')}; its step may still run in its slot`, lost.map(e => e.attempt).join(', '));
    }
    const hold = this.held();
    if (hold) { this.log(`held, nothing starts until the Board removes ${this.holdFile}: ${hold}`); return seen; }
    if (this.paused()) { this.log('paused: gpu_go.txt holds the Board pause; nothing starts'); return seen; }
    if (this.live) this.redeliver();
    for (const n of this.gh.readyPulls()) {
      const { pull, g } = this.look(n);
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
        if (this.tools.gameRunning() !== false) { this.log('  Voidsworn may be running (Ryan playing, or the process list was unreadable); the job waits'); continue; }
        // the claim must succeed: a label that will not come off could start the same job twice
        if (!this.report(n, () => this.gh.removeLabel(n, READY), `remove ${READY}`)) continue;
        try { await this.runJob(n, g.spec); }
        catch (e) { this.setHold(`PR ${n} ${g.spec.job}: the daemon failed in the middle of the job (${e.message})`, '(see the newest attempt)'); throw e; }
        break; // one job per look; the next look starts fresh from GitHub
      }
    }
    return seen;
  }
  newAttempt(job) {
    const jobDir = path.join(this.vt, job);
    fs.mkdirSync(jobDir, { recursive: true });
    plainChain(jobDir);
    for (let i = 1; i < 1000; i++) {
      const a = path.join(jobDir, `out_${stamp(this.clock())}_${i}`);
      try { fs.mkdirSync(a); return a; } catch (e) { if (e.code !== 'EEXIST') throw e; }
    }
    throw new Error('no free attempt folder name');
  }
  setHold(why, attempt) {
    fs.mkdirSync(this.dir, { recursive: true });
    fs.appendFileSync(this.holdFile, `${why}\r\nattempt ${attempt}\r\nset ${this.clock().toISOString()}; the Board removes this file once it has looked.\r\n`);
  }
  async runJob(n, spec) {
    const sha = spec.sha;
    const attempt = this.newAttempt(spec.job);
    this.mine.add(attempt);
    this.note(sha, spec.job, n, 'start', attempt);
    this.report(n, () => this.gh.addLabel(n, RUNNING), `add ${RUNNING}`);
    const outDir = path.join(attempt, `out_${spec.job}`);
    fs.mkdirSync(outDir);
    const st = path.join(attempt, 'status.txt');
    const say = s => { fs.appendFileSync(st, `${this.clock().toISOString()} ${s}\r\n`); this.log(`  ${s}`); };
    fs.writeFileSync(path.join(attempt, 'pc_daemon_spec.json'), JSON.stringify({ pr: n, ...spec }, null, 2));
    this.report(n, () => this.gh.comment(n, `PC daemon (issue 1662): started ${spec.job} at ${sha.slice(0, 8)} (${spec.flow}, ${spec.slot} slot, ceiling ${Math.round(spec.ceilingS / 60)} min, idle stop ${spec.stallMin} min). Reviewed: ${spec.reviewed}.`), 'comment');
    const failed = [];
    let watch = null, slotTaken = false, quarantine = null, aborted = null, lease = null, flight = null, launched = false;
    const step = async (name, fn) => {
      if (failed.length || aborted) { say(`skipped ${name}: an earlier step stopped`); return; }
      say(`step ${name}`);
      try { await fn(); } catch (e) { failed.push(name); say(`FAILED ${name}: ${e.message}`); }
    };
    let exe = null, repo = null;
    try {
      await step('tools', () => say(`tools ${this.tools.pin(st)} (hashes verified)`));
      await step('preflight', () => { exe = this.tools.preflight(attempt, [spec.flow], st)[spec.flow]; });
      await step('options before', () => this.tools.hashes(path.join(attempt, 'real_options_before.txt'), st));
      await step('slot', () => {
        slotTaken = true;
        repo = checkSlotRepo(this.vt, this.tools.slot(attempt, `pr${n}`, sha, spec.slot, st));
        lease = this.tools.slotLease(attempt, repo, spec.slot);
        say(`slot repo ${repo} (lease ${lease.token})`);
      });
      if (spec.ships) await step('ships', () => this.tools.ships(attempt, repo, `pr${n}`, spec.hulls, st));
      // the slot wait and the ships copy can take hours: everything is read again before the in-flight marker, and the
      // watchdog reads it once more after its own waits
      await step('recheck', () => { aborted = this.recheck(n, spec); });
      await step('in flight', () => { flight = this.tools.inFlight(lease, attempt); say(`slot set aside while the step runs: ${flight.marker}`); });
      await step('run', async () => {
        const { args, cwd } = command(spec, repo, outDir);
        say(`run ${path.basename(exe)} ${args.join(' ')} (watchdog run_timeout.ps1)`);
        const env = { ...process.env, VS_OUT: outDir, VS_REPO: repo, JOB_DIR: attempt };
        const record = path.join(attempt, 'watchdog_record.json');
        launched = true;
        const r = await this.tools.watchdog({ exe, args, cwd, env, ceilingS: spec.ceilingS, stallMin: spec.stallMin, outDir,
          label: `pcd_${spec.job}`, gpu: spec.gpu, logFile: path.join(attempt, 'run_log.txt'), record, scratch: flight.scratch,
          gateJs: __filename, gateArg: attempt });
        watch = readWatchdog(r, readRecord(record), flight.scratch);
        say(`watchdog: ${watch.why}`);
        if (watch.quarantine) quarantine = watch.why;
        else if (watch.gated) { aborted = `the launch gate said no: ${watch.gated}`; return; }
        if (!watch.ok) throw new Error(watch.why);
      });
      if (flight) {
        if (quarantine || (launched && !watch)) {
          // the tree may still run in the slot: the marker stays with the reason, the slot is not let go, and the
          // daemon holds every start until the Board removes pc_daemon\hold.txt; the watchdog keeps the GPU claim of
          // survivors itself. Nothing is swept.
          quarantine = quarantine || 'the step ended without a watchdog result';
          say('QUARANTINE: ' + quarantine);
          try { this.tools.holdInFlight(flight, quarantine); } catch (e) { say(`slot hold.txt: ${e.message}`); }
          this.setHold(`PR ${n} ${spec.job}: ${quarantine}`, attempt);
          slotTaken = false;
        } else {
          try { this.tools.clearInFlight(flight); say('the step is proven gone; the in-flight marker is cleared'); }
          catch (e) { say(`the in-flight marker stays: ${e.message}`); }
        }
      }
    } finally { this.tools.unpin(); }
    if (!aborted) await step('outputs', () => { const miss = expectMissing(outDir, spec.expect); if (miss.length) throw new Error(`missing or empty: ${miss.join(', ')}`); });
    // the options check runs even after a failed step: a job that touched Ryan's settings must say so
    try {
      const after = this.tools.hashes(path.join(attempt, 'real_options_after.txt'), st);
      const before = fs.readFileSync(path.join(attempt, 'real_options_before.txt'), 'utf8');
      if (before !== after) { failed.push('options'); say("FAILED options: Ryan's real battle_opts.json or board_look.cfg changed during the job"); }
      else say("Ryan's real options unchanged");
    } catch (e) { if (!failed.includes('options before') && !failed.includes('tools')) { failed.push('options'); say(`FAILED options: ${e.message}`); } }
    if (slotTaken) { try { this.tools.slotRelease(attempt, st); say('slot let go'); } catch (e) { say(`slot release: ${e.message}`); } }
    if (aborted && !failed.length) {
      say(`aborted before launch: ${aborted}`);
      fs.writeFileSync(path.join(attempt, 'done.txt'), `done ABORTED: ${aborted}\r\n`);
      this.note(sha, spec.job, n, 'aborted', attempt);
      this.report(n, () => this.gh.comment(n, `PC daemon (issue 1662): ${spec.job} not started at ${sha.slice(0, 8)}: ${aborted}. Nothing ran. Put the ${READY} label back (with a new "PC go:" comment if the head moved) to try again.`), 'comment');
      this.report(n, () => this.gh.removeLabel(n, RUNNING), `remove ${RUNNING}`);
      return { pass: false, aborted, attempt };
    }
    const pass = failed.length === 0;
    fs.writeFileSync(path.join(attempt, 'done.txt'), pass ? 'done PASS\r\n' : `done FAILED: ${failed.join(', ')}\r\n`);
    say(pass ? 'done PASS' : `done FAILED: ${failed.join(', ')}`);
    writeAtomic(path.join(attempt, 'pc_daemon_result.json'), JSON.stringify({ pr: n, spec, pass, failed, watch, quarantine }, null, 2));
    this.note(sha, spec.job, n, pass ? 'PASS' : 'FAILED', attempt);
    const links = this.deliver({ sha, job: spec.job, pr: n, attempt });
    this.report(n, () => this.gh.removeLabel(n, RUNNING), `remove ${RUNNING}`);
    return { pass, failed, attempt, watch, links, quarantine };
  }
  // Relay the attempt and post its result with the done marker; only both together write "delivered". A failed relay
  // or comment leaves the attempt for redeliver(), which never reruns the job. A missing or unreadable result record
  // is reported once and skipped, so it never stalls the queue (Astra audit of PR 1835, finding 9).
  deliver(e) {
    const st = path.join(e.attempt, 'status.txt');
    this.lastTry.set(e.attempt, this.clock().getTime());
    let r;
    try { r = JSON.parse(fs.readFileSync(path.join(e.attempt, 'pc_daemon_result.json'), 'utf8')); }
    catch (err) {
      const key = 'record ' + e.attempt;
      if (!this.reported.has(key)) {
        this.reported.add(key);
        this.log(`PR ${e.pr}: the result record of ${e.attempt} is missing or unreadable (${err.code || err.message}); kept for the Board`);
        this.report(e.pr, () => this.gh.comment(e.pr, `PC daemon (issue 1662): ${e.job} at ${e.sha.slice(0, 8)} ran, but its result record could not be read (${err.code || 'unreadable'}). The attempt is kept on the PC at ${e.attempt} for the Board.`), 'comment');
      }
      return null;
    }
    const { spec, pass, failed, watch, quarantine } = r;
    const tries = (this.deliveryTries.get(e.attempt) || 0) + 1;
    this.deliveryTries.set(e.attempt, tries);
    let links;
    try { links = relayLinks(this.tools.relay(e.job, e.attempt, st)); if (!links.folder) throw new Error('no folder link printed'); }
    catch (err) {
      try { fs.appendFileSync(st, `${this.clock().toISOString()} relay failed (try ${tries}): ${err.message}\r\n`); } catch { /* attempt folder gone */ }
      if (tries === 1) this.report(e.pr, () => this.gh.comment(e.pr, `PC daemon (issue 1662): ${e.job} ${pass ? 'PASS' : 'FAILED'} at ${e.sha.slice(0, 8)} on the PC, but the relay failed (${err.message}). The daemon retries the relay every ${Math.round(this.retryMs / 60000)} minutes without rerunning the job; results stay at ${e.attempt}.`), 'comment');
      return null;
    }
    const body = [
      `PC daemon (issue 1662): ${e.job} ${pass ? 'PASS' : 'FAILED'} at ${e.sha.slice(0, 8)}`,
      '',
      pass ? '' : `- failed: ${failed.join(', ')}`,
      quarantine ? `- QUARANTINE: ${quarantine}. The slot is set aside and the daemon starts nothing until the Board has looked` : '',
      watch ? `- watchdog: ${watch.why} (ceiling ${Math.round(spec.ceilingS / 60)} min, idle stop ${spec.stallMin} min)` : '- the job step did not start',
      `- results: ${links.folder}`,
      ...links.pictures.map(p => `- picture: ${p}`),
      tries > 1 ? `- relayed on try ${tries}` : '',
      `- reviewed before the run: ${spec.reviewed}`,
      '',
      DONE_MARK(e.sha, e.job)
    ].filter((l, i, a) => l !== '' || (i > 0 && a[i - 1] !== '')).join('\n');
    try { this.gh.comment(e.pr, body); }
    catch (err) { try { fs.appendFileSync(st, `${this.clock().toISOString()} result comment failed: ${err.message}\r\n`); } catch { /* gone */ } return null; }
    this.note(e.sha, e.job, e.pr, 'delivered', e.attempt);
    this.deliveryTries.delete(e.attempt);
    return links;
  }
  redeliver() {
    for (const e of this.undelivered()) {
      const last = this.lastTry.get(e.attempt) || 0;
      if (last && this.clock().getTime() - last < this.retryMs) continue;
      this.log(`redelivering ${e.job} at ${e.sha.slice(0, 8)} (PR ${e.pr})`);
      try { this.deliver(e); } catch (err) { this.log(`redelivery of ${e.attempt} failed: ${err.message}`); }
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
  return `${spec.flow} ${args.join(' ')} | ${spec.slot} slot, gpu ${spec.gpu}, ships ${spec.ships ? 'yes' : 'no'}, ceiling ${spec.ceilingS} s, idle stop ${spec.stallMin} min, expect ${spec.expect.join(' ')}`;
}

// The watchdog's launch gate (PC_STEP_GATE_JS): node pc_daemon.js --recheck <attempt>. Exit 0 starts the step; any
// other exit, or a crash, keeps it from starting.
function recheckMain(attemptArg) {
  const attempt = path.resolve(String(attemptArg || ''));
  const vt = checkRoot(path.dirname(path.dirname(attempt)), { live: process.platform === 'win32' });
  const { pr, ...spec } = JSON.parse(fs.readFileSync(path.join(attempt, 'pc_daemon_spec.json'), 'utf8'));
  const d = new Daemon({ vt, gh: new GhCli(), tools: new PcTools({ vt }) });
  const why = d.recheck(pr, spec);
  console.log(why ? `not started: ${why}` : `go: ${spec.job} at ${spec.sha.slice(0, 8)} still approved`);
  return why ? 3 : 0;
}
async function main(argv) {
  if (argv[0] === '--recheck') { process.exitCode = recheckMain(argv[1]); return; }
  const live = argv.includes('--live'), once = argv.includes('--once') || !live && !argv.includes('--loop');
  if (live && process.platform !== 'win32') throw new Error('--live runs on Ryan\'s PC only');
  const fallback = process.env.USERPROFILE ? path.join(process.env.USERPROFILE, 'Downloads', 'voidsworn_test') : '';
  const vt = checkRoot(live ? fallback : (process.env.PC_DAEMON_VT || fallback || os.tmpdir()), { live });
  const d = new Daemon({ vt, gh: new GhCli(), tools: new PcTools({ vt }), live });
  console.log(`PC daemon (issue 1662) ${live ? 'LIVE' : 'dry run: reads GitHub only, changes nothing'}; root ${vt}`);
  if (live) { d.lease = await takeLease(); d.leased = true; }
  for (;;) {
    if (d.stopAsked()) { console.log('stop.txt found in pc_daemon; stopping'); return; }
    try { await d.tick(); } catch (e) { console.log(`look failed: ${e.message}`); }
    if (once) return;
    await new Promise(r => setTimeout(r, 120000));
  }
}
if (require.main === module) main(process.argv.slice(2)).then(() => process.exit(process.exitCode || 0), e => { console.error('PC daemon: ' + e.message); process.exit(1); });
module.exports = { parseGo, gate, runLogged, readWatchdog, readRecord, winQuote, GhCli, PcTools, Daemon, command, describe, relayLinks,
  expectMissing, checkRoot, checkSlotRepo, plainChain, takeLease, recheckMain, DONE_MARK, READY, RUNNING, CHECKS_WORKFLOW };
