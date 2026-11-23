'use strict';
// Issue 1662: tests for pc_daemon.js. Everything runs in new TEMP folders with fake GitHub and fake PC tools; no
// network, no PC, no GitHub writes. The watchdog tests start real Node child processes.
const assert = require('assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const d = require('./pc_daemon');

const SHA = 'a'.repeat(40), OLD = 'b'.repeat(40);
const tmp = () => fs.mkdtempSync(path.join(os.tmpdir(), 'pcd-test-'));
const goText = (extra = '', sha = SHA) => `PC go: ${sha}
reviewed: Artoo and Board audit at ${sha.slice(0, 8)}
job: lb_1777
flow: godot
script: res://tools/look_bench/run.gd
args: --ship A17 --out {out}
expect: shots/a.png log.txt
${extra}`;
const owner = body => ({ user: { login: 'rcbailey12' }, author_association: 'OWNER', body });
const pull = (sha = SHA, fork = false) => ({ number: 7, state: 'open', head: { sha, repo: { full_name: fork ? 'someone/voidsworn' : 'rcbailey12/voidsworn' } } });
const green = (sha = SHA, status = 'completed', conclusion = 'success') => [{ name: 'All checks', head_sha: sha, status, conclusion, started_at: '2026-11-23T10:00:00Z' }];
let passed = 0;
async function t(name, fn) { await fn(); passed++; console.log('ok ' + name); }

(async () => {
  // ---------------------------------------------------------------------------------------------- parseGo
  await t('go comment: full spec and defaults', () => {
    const s = d.parseGo(goText());
    assert.equal(s.error, undefined);
    assert.equal(s.sha, SHA); assert.equal(s.job, 'lb_1777'); assert.equal(s.flow, 'godot');
    assert.deepEqual(s.args, ['--ship', 'A17', '--out', '{out}']); assert.deepEqual(s.expect, ['shots/a.png', 'log.txt']);
    assert.equal(s.slot, 'gpu'); assert.equal(s.gpu, 'shared'); assert.equal(s.ships, true); assert.equal(s.headless, false);
    assert.equal(s.ceilingS, 3600); assert.equal(s.stallMin, 30); assert.equal(s.weight, 1);
    const c = d.parseGo(goText('slot: cpu\ngpu: none\nships: no\ntimeout: 21600\nstall: 5\nheadless: yes'));
    assert.equal(c.slot, 'cpu'); assert.equal(c.gpu, 'none'); assert.equal(c.ships, false); assert.equal(c.ceilingS, 21600); assert.equal(c.stallMin, 5);
    const b = d.parseGo(`PC go: ${SHA}\nreviewed: Board\njob: kit_1743\nflow: blender\nscript: tools/blender/kits/x.py\nexpect: kit.glb`);
    assert.equal(b.ships, false); assert.equal(b.script, 'tools/blender/kits/x.py');
    assert.equal(d.parseGo('just a comment'), null);
    assert.equal(d.parseGo('Looks good. PC go: ' + SHA), null, 'the go line must be the first line');
  });
  await t('go comment: refusals', () => {
    const bad = [
      [goText().replace(/reviewed:.*\n/, ''), /reviewed/],
      [goText().replace('job: lb_1777', 'job: LB 1777'), /job must/],
      [goText().replace('flow: godot', 'flow: bash'), /flow must/],
      [goText().replace('--ship A17', '--ship A17&calc'), /argument not accepted/],
      [goText().replace('--ship A17', '--ship %USERPROFILE%'), /argument not accepted/],
      [goText().replace('run.gd', '../../x.gd'), /script|\.\./],
      [goText().replace('shots/a.png', '../escape.png'), /expect path/],
      [goText().replace(/expect:.*\n/, ''), /expect/],
      [goText('timeout: 99999'), /timeout must/],
      [goText('stall: 0'), /stall must/],
      [goText('slot: cpu\ngpu: solo'), /cpu slot/],
      [goText('rm: -rf'), /unknown line/],
      [goText('job: other'), /twice/],
      [goText().replace('res://tools/look_bench/run.gd', 'C:/x.gd'), /res:\/\//],
      [`PC go: ${SHA}\nreviewed: x\njob: k\nflow: blender\nexpect: a`, /blender script/]
    ];
    for (const [text, why] of bad) { const s = d.parseGo(text); assert.ok(s && s.error, text); assert.match(s.error, why); }
  });

  // ------------------------------------------------------------------------------------------------- gate
  const g = (o) => d.gate({ pull: pull(), comments: [owner(goText())], checkRuns: green(), ledger: new Set(), ...o });
  await t('gate: runs only on green checks at the go commit', () => {
    assert.equal(g({}).verdict, 'run');
    assert.equal(g({ checkRuns: [] }).verdict, 'wait');
    assert.equal(g({ checkRuns: green(SHA, 'in_progress', null) }).verdict, 'wait');
    assert.equal(g({ checkRuns: green(SHA, 'completed', 'failure') }).verdict, 'refuse');
    assert.equal(g({ checkRuns: green(OLD) }).verdict, 'wait', 'a green run on another commit counts for nothing');
    const newest = [...green(SHA, 'completed', 'failure'), { ...green()[0], started_at: '2026-11-23T11:00:00Z' }];
    assert.equal(g({ checkRuns: newest }).verdict, 'run', 'the newest All checks run decides');
  });
  await t('gate: the go comment must name the head and come from the owner account', () => {
    assert.equal(g({ comments: [] }).verdict, 'wait');
    assert.equal(g({ pull: pull(SHA, true) }).verdict, 'refuse', 'forks never run');
    const stale = g({ comments: [owner(goText('', OLD))] });
    assert.equal(stale.verdict, 'refuse'); assert.match(stale.why, /later push/);
    const stranger = { user: { login: 'someone' }, author_association: 'NONE', body: goText() };
    assert.equal(g({ comments: [stranger] }).verdict, 'wait', 'a public commenter cannot start a PC job');
    assert.equal(g({ comments: [{ ...owner(goText()), author_association: 'NONE' }] }).verdict, 'wait');
    assert.equal(g({ comments: [owner(goText('', OLD)), owner(goText())] }).verdict, 'run', 'the newest go wins');
    assert.equal(g({ comments: [owner(goText()), owner(goText('', OLD))] }).verdict, 'refuse');
    assert.equal(g({ comments: [owner(goText('rm: x'))] }).verdict, 'refuse');
    assert.equal(g({ pull: { ...pull(), state: 'closed' } }).verdict, 'skip');
  });
  await t('gate: never runs the same commit and job twice', () => {
    assert.equal(g({ ledger: new Set([SHA + ' lb_1777']) }).verdict, 'skip');
    assert.equal(g({ comments: [owner(goText()), owner('done ' + d.DONE_MARK(SHA, 'lb_1777'))] }).verdict, 'skip');
    const fake = { user: { login: 'someone' }, author_association: 'NONE', body: d.DONE_MARK(SHA, 'lb_1777') };
    assert.equal(g({ comments: [owner(goText()), fake] }).verdict, 'run', 'only our own done marker counts');
    assert.equal(g({ ledger: new Set([OLD + ' lb_1777']) }).verdict, 'run');
  });

  // --------------------------------------------------------------------------------------------- watchdog
  const node = process.execPath;
  await t('watchdog: a clean exit, a failing exit, a missing program', async () => {
    const dir = tmp(), log = path.join(dir, 'log.txt');
    let r = await d.watch({ exe: node, args: ['-e', 'console.log("hi")'], cwd: dir, env: process.env, ceilingMs: 20000, stallMs: 20000, logFile: log, pollMs: 50 });
    assert.equal(r.reason, 'exit'); assert.equal(r.code, 0); assert.ok(r.bytes >= 3);
    assert.match(fs.readFileSync(log, 'utf8'), /hi/);
    r = await d.watch({ exe: node, args: ['-e', 'process.exit(3)'], cwd: dir, env: process.env, ceilingMs: 20000, stallMs: 20000, logFile: log, pollMs: 50 });
    assert.equal(r.reason, 'exit'); assert.equal(r.code, 3);
    r = await d.watch({ exe: path.join(dir, 'no_such_program'), args: [], cwd: dir, env: process.env, ceilingMs: 20000, stallMs: 20000, logFile: log, pollMs: 50 });
    assert.equal(r.reason, 'start');
  });
  await t('watchdog: a silent run stops at the stall limit, a chatty one at the ceiling', async () => {
    const dir = tmp(), log = path.join(dir, 'log.txt');
    let r = await d.watch({ exe: node, args: ['-e', 'setTimeout(()=>{},60000)'], cwd: dir, env: process.env, ceilingMs: 30000, stallMs: 600, logFile: log, pollMs: 50 });
    assert.equal(r.reason, 'stall'); assert.ok(r.ms < 10000);
    r = await d.watch({ exe: node, args: ['-e', 'setInterval(()=>console.log("."),50)'], cwd: dir, env: process.env, ceilingMs: 900, stallMs: 600, logFile: log, pollMs: 50 });
    assert.equal(r.reason, 'ceiling', 'output keeps it alive past the stall limit, never past the ceiling');
  });
  await t('watchdog: file writes in the out folder count as progress', async () => {
    const dir = tmp(), out = path.join(dir, 'out'); fs.mkdirSync(out);
    const script = `const fs=require('fs');let i=0;setInterval(()=>fs.writeFileSync(${JSON.stringify(path.join(out, 'f'))}+(i++),'x'),40);setTimeout(()=>process.exit(0),1500)`;
    const r = await d.watch({ exe: node, args: ['-e', script], cwd: dir, env: process.env, ceilingMs: 20000, stallMs: 500, progressDirs: [out], logFile: path.join(dir, 'log.txt'), pollMs: 50 });
    assert.equal(r.reason, 'exit');
  });
  await t('watchdog: stop requests repeat, and a tree that never ends comes back unkilled', async () => {
    const dir = tmp(); let asks = 0, pid = 0;
    const r = await d.watch({ exe: node, args: ['-e', 'setTimeout(()=>{},60000)'], cwd: dir, env: process.env, ceilingMs: 30000, stallMs: 300,
      logFile: path.join(dir, 'log.txt'), pollMs: 30, killRetryMs: 100, killTries: 3, kill: p => { asks++; pid = p; if (asks === 1) throw new Error('taskkill exit 1'); } });
    assert.equal(r.unkilled, true); assert.equal(asks, 3); assert.equal(r.reason, 'stall');
    assert.match(fs.readFileSync(path.join(dir, 'log.txt'), 'utf8'), /stop request failed: taskkill exit 1/);
    d.killTree(pid);
    let got = 0;
    const r2 = await d.watch({ exe: node, args: ['-e', 'setTimeout(()=>{},60000)'], cwd: dir, env: process.env, ceilingMs: 30000, stallMs: 300,
      logFile: path.join(dir, 'log.txt'), pollMs: 30, killRetryMs: 100, kill: p => { if (++got === 2) d.killTree(p); } });
    assert.equal(r2.unkilled, false); assert.equal(got, 2, 'the second request ended it');
  });
  if (process.platform !== 'win32') await t('watchdog: a stop kills the whole process tree', async () => {
    const dir = tmp(), pidFile = path.join(dir, 'grandchild.pid');
    const script = `const c=require('child_process').spawn(process.execPath,['-e','setTimeout(()=>{},60000)'],{stdio:'ignore'});require('fs').writeFileSync(${JSON.stringify(pidFile)},String(c.pid));setTimeout(()=>{},60000)`;
    const r = await d.watch({ exe: node, args: ['-e', script], cwd: dir, env: process.env, ceilingMs: 30000, stallMs: 800, logFile: path.join(dir, 'log.txt'), pollMs: 50 });
    assert.equal(r.reason, 'stall');
    const gc = +fs.readFileSync(pidFile, 'utf8');
    await new Promise(res => setTimeout(res, 300));
    // a killed process nobody has reaped yet (no init reaper in a container) still answers kill 0: read its state
    let alive = true; try { process.kill(gc, 0); } catch { alive = false; }
    if (alive && fs.existsSync(`/proc/${gc}/status`)) alive = !/^State:\s+Z/m.test(fs.readFileSync(`/proc/${gc}/status`, 'utf8'));
    assert.equal(alive, false, 'the grandchild must be gone');
  });

  // -------------------------------------------------------------------------------------------- removeInside
  await t('profile removal: only a daemon profile in slots\\profiles, links removed as links', () => {
    const vt = tmp(), slots = path.join(vt, 'slots'), profiles = path.join(slots, 'profiles');
    const prof = path.join(profiles, 'pcd-profile-' + '0'.repeat(32));
    fs.mkdirSync(path.join(prof, 'Godot', 'app_userdata'), { recursive: true });
    fs.writeFileSync(path.join(prof, 'Godot', 'app_userdata', 'x.cfg'), 'x');
    const keep = path.join(vt, 'ryan_saves'); fs.mkdirSync(keep); fs.writeFileSync(path.join(keep, 'save.json'), 'precious');
    fs.symlinkSync(keep, path.join(prof, 'link_to_saves'), 'dir');
    fs.symlinkSync(path.join(keep, 'save.json'), path.join(prof, 'file_link'));
    d.removeInside(slots, prof);
    assert.equal(fs.existsSync(prof), false);
    assert.equal(fs.readFileSync(path.join(keep, 'save.json'), 'utf8'), 'precious', 'never follows a link');
    for (const bad of [keep, path.join(profiles, 'godot-profile-x'), path.join(slots, 'slot_gpu_1'), path.join(profiles, '..', '..', 'ryan_saves')]) {
      assert.throws(() => d.removeInside(slots, bad));
    }
    assert.ok(fs.existsSync(keep));
    // a profiles folder that is a link (it would send the delete elsewhere) is refused
    const vt2 = tmp(), slots2 = path.join(vt2, 'slots'); fs.mkdirSync(slots2);
    const elsewhere = path.join(vt2, 'elsewhere'), victim = path.join(elsewhere, 'pcd-profile-' + '1'.repeat(32));
    fs.mkdirSync(victim, { recursive: true });
    fs.symlinkSync(elsewhere, path.join(slots2, 'profiles'), 'dir');
    assert.throws(() => d.removeInside(slots2, path.join(slots2, 'profiles', path.basename(victim))), /plain folder/);
    assert.ok(fs.existsSync(victim));
  });

  // ---------------------------------------------------------------------------------------------- the daemon
  function fakes({ comments = [owner(goText())], runs = green(), exit = 0, writeOutputs = true, optionsChange = false, failStep = null, ghFails = false, relayFails = 0, unkilled = false } = {}) {
    const vt = tmp(), calls = [], gh = {
      writes: [],
      readyPulls: () => [7], pull: () => pull(), comments: () => comments, checkRuns: () => runs,
      addLabel(n, l) { if (ghFails) throw new Error('offline'); this.writes.push(['add', n, l]); },
      removeLabel(n, l) { if (ghFails) throw new Error('offline'); this.writes.push(['remove', n, l]); },
      comment(n, b) { if (ghFails) throw new Error('offline'); this.writes.push(['comment', n, b]); }
    };
    let opt = 0;
    const step = (name, fn) => (...a) => { calls.push(name); if (failStep === name) throw new Error('fake ' + name + ' failure'); return fn(...a); };
    const tools = {
      preflight: step('preflight', () => ({ godot: 'C:\\godot.exe', blender: 'C:\\blender.exe' })),
      hashes: step('hashes', f => { const t = optionsChange && opt++ ? 'changed' : 'same'; fs.writeFileSync(f, t); return t; }),
      slot: step('slot', (attempt, name, pin, kind) => { assert.equal(pin, SHA); assert.equal(kind, 'gpu'); const r = path.join(vt, 'slots', 'slot_gpu_1', 'repo'); fs.mkdirSync(r, { recursive: true }); return r; }),
      ships: step('ships', () => {}),
      gpuAcquire: step('gpuAcquire', () => '12345678-1234-1234-1234-123456789abc'),
      gpuRelease: step('gpuRelease', () => {}),
      slotRelease: step('slotRelease', () => {}),
      relay: step('relay', () => { if (relayFails-- > 0) throw new Error('relay offline'); return 'folder link: https://github.com/rcbailey12/voidsworn-relay/tree/pc-out-lb_1777/x\npicture link: https://example.invalid/a.png\n'; }),
      gameRunning: () => false
    };
    let seenEnv = null;
    const watchImpl = async o => {
      seenEnv = o.env;
      assert.match(o.env.APPDATA, /slots[\\/]profiles[\\/]pcd-profile-[0-9a-f]{32}$/);
      assert.ok(fs.existsSync(o.env.APPDATA));
      if (writeOutputs) { fs.mkdirSync(path.join(o.progressDirs[0], 'shots')); fs.writeFileSync(path.join(o.progressDirs[0], 'shots', 'a.png'), 'png'); fs.writeFileSync(path.join(o.progressDirs[0], 'log.txt'), 'ok'); }
      if (unkilled) return { code: null, signal: null, reason: 'stall', ms: 1000, bytes: 0, unkilled: true };
      return { code: exit, signal: null, reason: 'exit', ms: 1000, bytes: 10 };
    };
    const daemon = new d.Daemon({ vt, gh, tools, live: true, log: () => {}, watchImpl, clock: () => new Date('2026-11-23T14:00:00Z') });
    return { vt, gh, calls, daemon, env: () => seenEnv };
  }
  await t('daemon: a dry run reads and changes nothing', async () => {
    const f = fakes();
    f.daemon.live = false;
    const seen = await f.daemon.tick();
    assert.equal(seen[0].verdict, 'run');
    assert.deepEqual(f.gh.writes, []); assert.deepEqual(f.calls, []);
    assert.deepEqual(fs.readdirSync(f.vt), [], 'no file written on the PC');
  });
  await t('daemon: a passing job, in order, reported once', async () => {
    const f = fakes();
    await f.daemon.tick();
    assert.deepEqual(f.calls, ['preflight', 'hashes', 'slot', 'ships', 'gpuAcquire', 'gpuRelease', 'hashes', 'slotRelease', 'relay']);
    const w = f.gh.writes;
    assert.deepEqual(w[0], ['remove', 7, 'pc-ready']); assert.deepEqual(w[1], ['add', 7, 'running']);
    assert.match(w[2][2], /started lb_1777/);
    assert.match(w[3][2], /lb_1777 PASS/); assert.match(w[3][2], /voidsworn-relay\/tree/); assert.ok(w[3][2].includes(d.DONE_MARK(SHA, 'lb_1777')));
    assert.deepEqual(w[4], ['remove', 7, 'running']);
    const attempt = path.join(f.vt, 'lb_1777', fs.readdirSync(path.join(f.vt, 'lb_1777'))[0]);
    assert.equal(fs.readFileSync(path.join(attempt, 'done.txt'), 'utf8').trim(), 'done PASS');
    assert.deepEqual(fs.readdirSync(path.join(f.vt, 'slots', 'profiles')), [], 'the throwaway profile is gone');
    assert.equal(f.env().VS_OUT, path.join(attempt, 'out_lb_1777'));
    // the next look skips it from the ledger alone, even when GitHub never got the done marker
    f.calls.length = 0; f.gh.writes.length = 0;
    const seen = await f.daemon.tick();
    assert.equal(seen[0].verdict, 'skip'); assert.deepEqual(f.calls, []); assert.deepEqual(f.gh.writes, []);
  });
  await t('daemon: a failing step still lets the slot and GPU go and relays the logs', async () => {
    const f = fakes({ exit: 2 });
    await f.daemon.tick();
    assert.ok(f.calls.includes('gpuRelease') && f.calls.includes('slotRelease') && f.calls.includes('relay'));
    const result = f.gh.writes.find(w => w[0] === 'comment' && /FAILED/.test(w[2]));
    assert.match(result[2], /failed: run/);
    const g2 = fakes({ failStep: 'ships' });
    await g2.daemon.tick();
    assert.ok(!g2.calls.includes('gpuAcquire'), 'nothing after a failed step starts');
    assert.ok(g2.calls.includes('slotRelease'));
    assert.match(g2.gh.writes.find(w => w[0] === 'comment' && /FAILED/.test(w[2]))[2], /failed: ships/);
  });
  await t('daemon: missing outputs and changed options fail the job', async () => {
    const f = fakes({ writeOutputs: false });
    await f.daemon.tick();
    assert.match(f.gh.writes.find(w => /FAILED/.test(w[2] || ''))[2], /failed: outputs/);
    const o = fakes({ optionsChange: true });
    await o.daemon.tick();
    assert.match(o.gh.writes.find(w => /FAILED/.test(w[2] || ''))[2], /failed: options/);
  });
  await t('daemon: GitHub failures never fail the job', async () => {
    const f = fakes({ ghFails: true });
    await f.daemon.tick();
    const attempt = path.join(f.vt, 'lb_1777', fs.readdirSync(path.join(f.vt, 'lb_1777'))[0]);
    assert.equal(fs.readFileSync(path.join(attempt, 'done.txt'), 'utf8').trim(), 'done PASS');
  });
  await t('daemon: a refusal is said once and takes the label off', async () => {
    const f = fakes({ runs: green(SHA, 'completed', 'failure') });
    await f.daemon.tick(); await f.daemon.tick();
    assert.equal(f.gh.writes.filter(w => w[0] === 'comment').length, 1);
    assert.deepEqual(f.gh.writes.find(w => w[0] === 'remove'), ['remove', 7, 'pc-ready']);
    assert.deepEqual(f.calls, []);
  });
  await t('daemon: the Board pause and Ryan playing hold every start', async () => {
    const f = fakes();
    fs.writeFileSync(path.join(f.vt, 'gpu_go.txt'), 'GPU not cleared: paused by the Board at 14:00\r\n');
    assert.deepEqual(await f.daemon.tick(), []);
    assert.deepEqual(f.calls, []); assert.deepEqual(f.gh.writes, []);
    const p = fakes();
    p.daemon.tools.gameRunning = () => true;
    await p.daemon.tick();
    assert.deepEqual(p.calls, []); assert.deepEqual(p.gh.writes, []);
  });
  await t('daemon: a failed relay keeps the run key but not the done marker, and is retried without a rerun', async () => {
    const f = fakes({ relayFails: 1 });
    await f.daemon.tick();
    const notes = f.gh.writes.filter(w => w[0] === 'comment');
    assert.match(notes[1][2], /relay failed/); assert.ok(!notes.some(w => w[2].includes('pc-daemon done')), 'no done marker without delivery');
    assert.deepEqual(f.daemon.undelivered().map(e => e.state), ['PASS']);
    f.calls.length = 0; f.gh.writes.length = 0;
    await f.daemon.tick();
    assert.deepEqual(f.calls, [], 'inside the retry wait nothing runs or relays');
    f.daemon.retryMs = 0;
    await f.daemon.tick();
    assert.deepEqual(f.calls, ['relay'], 'only the relay runs again');
    const result = f.gh.writes.find(w => w[0] === 'comment')[2];
    assert.match(result, /PASS/); assert.match(result, /relayed on try 2/); assert.ok(result.includes(d.DONE_MARK(SHA, 'lb_1777')));
    assert.deepEqual(f.daemon.undelivered(), []);
    f.calls.length = 0; await f.daemon.tick(); assert.deepEqual(f.calls, []);
  });
  await t('daemon: a start with no result (stopped mid-job) does not block a new go', async () => {
    const f = fakes();
    fs.mkdirSync(path.join(f.vt, 'pc_daemon'));
    fs.writeFileSync(path.join(f.vt, 'pc_daemon', 'ran.txt'), `2026-11-23T13:00:00Z ${SHA} lb_1777 PR7 start\r\n`);
    assert.equal((await f.daemon.tick())[0].verdict, 'run');
    assert.ok(f.calls.includes('preflight'));
  });
  await t('daemon: a tree that will not die is quarantined: slot, GPU and profile kept, nothing new starts', async () => {
    const f = fakes({ unkilled: true });
    await f.daemon.tick();
    assert.ok(!f.calls.includes('gpuRelease') && !f.calls.includes('slotRelease'));
    assert.equal(fs.readdirSync(path.join(f.vt, 'slots', 'profiles')).length, 1, 'the profile in use stays');
    assert.match(f.gh.writes.find(w => /FAILED/.test(w[2] || ''))[2], /QUARANTINE/);
    f.calls.length = 0;
    fs.appendFileSync(path.join(f.vt, 'pc_daemon', 'ran.txt'), ''); // a fresh go would still not start
    assert.deepEqual(await f.daemon.tick(), []); assert.deepEqual(f.calls, []);
  });
  await t('daemon lock: one live daemon per root, a stale lock is taken over, no sweep without it', async () => {
    const vt = tmp(), mk = () => new d.Daemon({ vt, gh: {}, tools: {}, live: true, log: () => {} });
    const a = mk(); a.lease();
    assert.throws(() => mk().lease(), /another PC daemon/);
    const lock = path.join(vt, 'pc_daemon', 'daemon.lock');
    fs.writeFileSync(lock, JSON.stringify({ pid: 999999999, beat: Date.now(), id: 'old' }));
    const b = mk(); b.lease({ alive: () => false });
    assert.equal(JSON.parse(fs.readFileSync(lock, 'utf8')).id, b.leaseId);
    assert.throws(() => a.beat(), /taken over/, 'the old holder notices and stops');
    fs.writeFileSync(lock, JSON.stringify({ pid: process.pid, beat: Date.now() - 6 * 60000, id: 'quiet' }));
    mk().lease();
    assert.throws(() => mk().sweepProfiles(), /lock first/);
  });
  await t('commands: godot and blender lines, placeholders filled, no shell', () => {
    const s = d.parseGo(goText('headless: yes'));
    const c = d.command(s, path.join('S', 'repo'), path.join('A', 'out'));
    assert.deepEqual(c.args, ['--headless', '--path', path.join('S', 'repo', 'godot'), '--script', 'res://tools/look_bench/run.gd', '--ship', 'A17', '--out', path.join('A', 'out')]);
    const b = d.parseGo(`PC go: ${SHA}\nreviewed: Board\njob: kit\nflow: blender\nscript: tools/blender/x.py\nargs: --code A17\nexpect: kit.glb`);
    assert.deepEqual(d.command(b, 'R', 'O').args, ['-b', '--factory-startup', '--python', path.join('R', 'tools', 'blender', 'x.py'), '--', '--code', 'A17']);
  });
  await t('GhCli: REST calls through gh api, bodies as an input file', () => {
    const seen = [];
    const run = (exe, args) => {
      const i = args.indexOf('--input');
      seen.push({ exe, args, input: i >= 0 ? JSON.parse(fs.readFileSync(args[i + 1], 'utf8')) : null });
      return { status: 0, stdout: args[1].includes('/issues?') ? JSON.stringify([{ number: 5, pull_request: {} }, { number: 6 }]) : '[]', stderr: '' };
    };
    const gh = new d.GhCli({ run });
    assert.deepEqual(gh.readyPulls(), [5], 'issues without a pull request are not jobs');
    gh.comment(5, 'hello'); gh.removeLabel(5, 'pc-ready');
    assert.ok(seen.every(s => s.exe === 'gh' && s.args[0] === 'api' && !s.args.includes('graphql')));
    assert.deepEqual(seen[1].input, { body: 'hello' });
    assert.deepEqual(seen[2].args.slice(1, 4), ['-X', 'DELETE', 'repos/rcbailey12/voidsworn/issues/5/labels/pc-ready']);
    assert.throws(() => new d.GhCli({ run: () => ({ status: 1, stdout: '', stderr: 'HTTP 404' }) }).pull(1), /404/);
  });
  console.log(`PASS: pc_daemon ${passed} checks (go comment, gate, watchdog, profile removal, daemon order, failures, delivery retry, quarantine and lock, commands, gh calls)`);
})().catch(e => { console.error('FAIL: ' + (e.stack || e.message)); process.exit(1); });
