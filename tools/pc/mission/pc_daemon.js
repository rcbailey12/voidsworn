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
// Deletes: nothing of its own except its temporary GitHub request files in TEMP. The slot reset it asks the head for
// deletes only inside voidsworn_test\slots; the watchdog removes only the profile it made.
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
//   Godot or a gpu: none Blender), timeout: <seconds, ceiling> (3600, at most 21600), stall: <minutes with no output>
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
    const gpu = kv.gpu || (slot === 'cpu' && kv.flow === 'blender' ? 'none' : 'auto');
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
  const suites = new Set(workflowRuns.filter(w => w.path === CHECKS_WORKFLOW && w.head_sha === sha).map(w => w.check_suite_id));
  const runs = checkRuns.filter(r => r.name === CHECK_NAME && r.head_sha === sha)
    .sort((a, b) => String(b.started_at || '').localeCompare(String(a.started_at || '')));
  const run = runs[0];
  if (!run) return { verdict: 'wait', why: `no "${CHECK_NAME}" run at ${sha.slice(0, 8)} yet`, spec: go };
  if (run.app?.slug !== 'github-actions' || !suites.has(run.check_suite?.id)) {
    return { verdict: 'wait', why: `the newest "${CHECK_NAME}" at ${sha.slice(0, 8)} is not from ${CHECKS_WORKFLOW} on GitHub Actions`, spec: go };
  }
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
    let output = '', done = false, timer = null;
    const say = s => { try { fs.writeSync(log, s); } catch { /* best effort */ } };
    const finish = (code, backstop = false) => {
      if (done) return;
      done = true; clearTimeout(timer);
      say(`[pc_daemon ${new Date().toISOString()}] ${backstop ? 'stopped waiting (backstop); the step may still run' : 'step ended, exit ' + code}\n`);
      try { fs.closeSync(log); } catch { /* closed */ }
      resolve({ code, ms: now() - start, output, backstop });
    };
    say(`[pc_daemon ${new Date(start).toISOString()}] start ${exe} ${args.join(' ')}\n`);
    let child;
    try { child = spawn(exe, args, { cwd, env, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] }); }
    catch (e) { say(`could not start: ${e.code || e.message}\n`); finish(null); return; }
    const take = chunk => { const s = chunk.toString('utf8'); output = (output + s).slice(-200000); say(s); };
    child.stdout.on('data', take);
    child.stderr.on('data', take);
    child.on('error', e => { say(`could not start: ${e.code || e.message}\n`); finish(null); });
    child.on('close', code => finish(code));
    timer = setTimeout(() => finish(null, true), backstopMs);
  });
}
// What the installed watchdog's exit and output mean for the daemon (run_timeout.ps1 and tmo.bat's contract).
function readWatchdog(r) {
  const out = r.output || '';
  if (r.backstop) return { ok: false, quarantine: true, why: 'the watchdog did not end within its ceiling plus the waits' };
  if (/KILL FAILED/.test(out)) return { ok: false, quarantine: true, why: 'the watchdog could not prove the process tree ended (KILL FAILED)' };
  if (/retaining claim \S+ as orphaned_child/.test(out)) return { ok: false, quarantine: true, why: 'processes outlived the step (orphaned GPU claim)' };
  if (r.code === 0) return { ok: true, why: 'exit 0' };
  if (r.code === 124) return { ok: false, why: ((/TIMEOUT .*$/m.exec(out) || [''])[0] || 'stopped by the watchdog (exit 124)').trim() };
  if (r.code === 125) return { ok: false, why: 'the watchdog could not start the step (exit 125)' };
  if (r.code === 126) return { ok: false, why: 'GPU admission failed (exit 126)' };
  if (r.code === null) return { ok: false, why: 'the watchdog did not start' };
  return { ok: false, why: `exit ${r.code}` };
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
// The proven tools_live pieces this run calls. Every path is checked; nothing here deletes.
class PcTools {
  constructor({ vt, run = spawnSync, runStep = runLogged } = {}) { this.vt = vt; this.run = run; this.runStep = runStep; }
  pc() {
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
  slotHold(repo, why) {
    // Enter-Slot skips a slot with hold.txt until the Board has looked (opus_job_head.ps1); writing it deletes nothing
    fs.writeFileSync(path.join(path.dirname(repo), 'hold.txt'), `${why}\r\nset by pc_daemon.js ${new Date().toISOString()}\r\nThe Board removes this file once it has looked.\r\n`, { flag: 'wx' });
  }
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
  // The job step through the installed watchdog, in step mode (tmo.bat's contract: TMO_ARGS "<seconds> <exe> <args>").
  watchdog({ exe, args, cwd, env, ceilingS, stallMin, outDir, label, gpu, logFile }) {
    const q = a => /\s/.test(a) ? `"${a}"` : a;
    const stepEnv = { ...env, TMO_ARGS: `${ceilingS} ${q(exe)} ${args.map(q).join(' ')}`, TMO_STEP: label, TMO_STEP_OUT: outDir,
      TMO_IDLE_S: String(stallMin * 60), PC_GPU_ISSUE: label, PC_GPU_MODE: gpu === 'auto' ? '' : gpu, PC_GPU_WAIT_SECONDS: '3600',
      TMO_REPO: '', TMO_OUT: '', TMO_LOG: '', TMO_ERR_LOG: '', PC_RUNNER_TEST: '', TMO_OWN_COPY: '', PC_REAL_PROFILE: '' };
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
  }
  // ran.txt lines: "<time> <sha> <job> PR<n> <state> [attempt]", state start, aborted, PASS, FAILED or delivered.
  // A start or an abort (approval changed before launch, the daemon stopped mid-job) does not block a new go; a result
  // does, and a result with no delivered line is relayed and reported again without a rerun.
  entries() {
    try {
      return fs.readFileSync(this.ledgerFile, 'utf8').split(/\r?\n/).filter(Boolean).map(l => {
        const p = l.split(' ');
        return { sha: p[1], job: p[2], pr: +String(p[3]).slice(2), state: p[4], attempt: p.slice(5).join(' ') };
      });
    } catch { return []; }
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
    try { return PAUSE_LINE.test(fs.readFileSync(path.join(this.vt, 'gpu_go.txt'), 'utf8').split(/\r?\n/)[0]); } catch { return false; }
  }
  held() { try { return fs.readFileSync(this.holdFile, 'utf8').split(/\r?\n/)[0] || 'hold.txt'; } catch (e) { return e.code === 'ENOENT' ? null : 'hold.txt unreadable'; } }
  stopAsked() { return fs.existsSync(path.join(this.dir, 'stop.txt')); }
  report(n, fn, what) {
    // GitHub reporting failures are logged and never fail the job (RULEBOOK 2.4)
    try { fn(); return true; } catch (e) { this.log(`PR ${n}: could not ${what}: ${e.message}`); return false; }
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
        await this.runJob(n, g.spec);
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
    this.note(sha, spec.job, n, 'start');
    this.report(n, () => this.gh.addLabel(n, RUNNING), `add ${RUNNING}`);
    const attempt = this.newAttempt(spec.job);
    const outDir = path.join(attempt, `out_${spec.job}`);
    fs.mkdirSync(outDir);
    const st = path.join(attempt, 'status.txt');
    const say = s => { fs.appendFileSync(st, `${this.clock().toISOString()} ${s}\r\n`); this.log(`  ${s}`); };
    fs.writeFileSync(path.join(attempt, 'pc_daemon_spec.json'), JSON.stringify({ pr: n, ...spec }, null, 2));
    this.report(n, () => this.gh.comment(n, `PC daemon (issue 1662): started ${spec.job} at ${sha.slice(0, 8)} (${spec.flow}, ${spec.slot} slot, ceiling ${Math.round(spec.ceilingS / 60)} min, idle stop ${spec.stallMin} min). Reviewed: ${spec.reviewed}.`), 'comment');
    const failed = [];
    let watch = null, slotTaken = false, quarantine = null, aborted = null;
    const step = async (name, fn) => {
      if (failed.length || aborted) { say(`skipped ${name}: an earlier step stopped`); return; }
      say(`step ${name}`);
      try { await fn(); } catch (e) { failed.push(name); say(`FAILED ${name}: ${e.message}`); }
    };
    let exe = null, repo = null;
    await step('preflight', () => { exe = this.tools.preflight(attempt, [spec.flow], st)[spec.flow]; });
    await step('options before', () => this.tools.hashes(path.join(attempt, 'real_options_before.txt'), st));
    await step('slot', () => { slotTaken = true; repo = checkSlotRepo(this.vt, this.tools.slot(attempt, `pr${n}`, sha, spec.slot, st)); say(`slot repo ${repo}`); });
    if (spec.ships) await step('ships', () => this.tools.ships(attempt, repo, `pr${n}`, spec.hulls, st));
    await step('recheck', () => {
      // the slot wait and the ships copy can take hours: approval, pause and play are read again right before launch
      const why = this.paused() ? 'the Board pause began' : this.held() ? 'a hold was set' : this.tools.gameRunning() !== false ? 'Voidsworn may be running' : null;
      if (why) { aborted = why; return; }
      const { g } = this.look(n, { claimed: true });
      if (g.verdict !== 'run' || g.spec.job !== spec.job || g.spec.sha !== sha) aborted = `the approval changed while waiting (${g.why})`;
    });
    await step('run', async () => {
      const { args, cwd } = command(spec, repo, outDir);
      say(`run ${path.basename(exe)} ${args.join(' ')} (watchdog run_timeout.ps1)`);
      const env = { ...process.env, VS_OUT: outDir, VS_REPO: repo, JOB_DIR: attempt };
      watch = readWatchdog(await this.tools.watchdog({ exe, args, cwd, env, ceilingS: spec.ceilingS, stallMin: spec.stallMin, outDir,
        label: `pcd_${spec.job}`, gpu: spec.gpu, logFile: path.join(attempt, 'run_log.txt') }));
      say(`watchdog: ${watch.why}`);
      if (watch.quarantine) quarantine = watch.why;
      if (!watch.ok) throw new Error(watch.why);
    });
    if (quarantine) {
      // the tree may still be running in the slot (Astra audit of PR 1835, findings 3 and 4): the slot is set aside with
      // its hold.txt and the daemon holds every start until the Board removes pc_daemon\hold.txt; the watchdog keeps
      // the GPU claim of survivors itself. Nothing is let go or swept.
      say('QUARANTINE: ' + quarantine);
      try { this.tools.slotHold(repo, `pc_daemon quarantine: ${quarantine} (attempt ${attempt})`); } catch (e) { say(`slot hold.txt: ${e.message}`); }
      this.setHold(`PR ${n} ${spec.job}: ${quarantine}`, attempt);
      slotTaken = false;
    }
    if (!aborted) await step('outputs', () => { const miss = expectMissing(outDir, spec.expect); if (miss.length) throw new Error(`missing or empty: ${miss.join(', ')}`); });
    // the options check runs even after a failed step: a job that touched Ryan's settings must say so
    try {
      const after = this.tools.hashes(path.join(attempt, 'real_options_after.txt'), st);
      const before = fs.readFileSync(path.join(attempt, 'real_options_before.txt'), 'utf8');
      if (before !== after) { failed.push('options'); say("FAILED options: Ryan's real battle_opts.json or board_look.cfg changed during the job"); }
      else say("Ryan's real options unchanged");
    } catch (e) { if (!failed.includes('options before')) { failed.push('options'); say(`FAILED options: ${e.message}`); } }
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

async function main(argv) {
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
module.exports = { parseGo, gate, runLogged, readWatchdog, GhCli, PcTools, Daemon, command, describe, relayLinks, expectMissing,
  checkRoot, checkSlotRepo, plainChain, takeLease, DONE_MARK, READY, RUNNING, CHECKS_WORKFLOW };
