'use strict';
// Issue 1662: tests for pc_daemon.js. Everything runs in new TEMP folders with fake GitHub and fake PC tools; no
// network, no PC, no GitHub writes. runLogged and the lease use real child processes and a real localhost bind.
// No timing-sensitive counts (Astra audit of PR 1835, finding 10): every wait is on a fact, not a clock.
const assert = require('assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn } = require('child_process');
const d = require('./pc_daemon');

const SHA = 'a'.repeat(40), OLD = 'b'.repeat(40);
const tmp = () => fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'pcd-test-')));
const goText = (extra = '', sha = SHA) => `PC go: ${sha}
reviewed: Artoo and Board audit at ${sha.slice(0, 8)}
job: lb_1777
flow: godot
script: res://tools/look_bench/run.gd
args: --ship A17 --out {out}
expect: shots/a.png log.txt
${extra}`;
let at = 0;
const owner = body => ({ user: { login: 'rcbailey12' }, author_association: 'OWNER', body, created_at: `2026-11-23T10:${String(at++).padStart(2, '0')}:00Z` });
const pull = (sha = SHA, fork = false, labels = ['pc-ready']) => ({ number: 7, state: 'open', labels: labels.map(name => ({ name })), head: { sha, repo: { full_name: fork ? 'someone/voidsworn' : 'rcbailey12/voidsworn' } } });
const green = (sha = SHA, status = 'completed', conclusion = 'success', suite = 11) => [{ name: 'All checks', head_sha: sha, status, conclusion, started_at: '2026-11-23T10:00:00Z', app: { slug: 'github-actions' }, check_suite: { id: suite } }];
const wf = (sha = SHA, suite = 11, p = d.CHECKS_WORKFLOW) => [{ path: p, head_sha: sha, check_suite_id: suite }];
let passed = 0;
async function t(name, fn) { await fn(); passed++; console.log('ok ' + name); }

(async () => {
  // ---------------------------------------------------------------------------------------------- parseGo
  await t('go comment: full spec and defaults', () => {
    const s = d.parseGo(goText());
    assert.equal(s.error, undefined);
    assert.equal(s.sha, SHA); assert.equal(s.job, 'lb_1777'); assert.equal(s.flow, 'godot');
    assert.deepEqual(s.args, ['--ship', 'A17', '--out', '{out}']); assert.deepEqual(s.expect, ['shots/a.png', 'log.txt']);
    assert.equal(s.slot, 'gpu'); assert.equal(s.gpu, 'auto'); assert.equal(s.ships, true); assert.equal(s.headless, false);
    assert.equal(s.ceilingS, 3600); assert.equal(s.stallMin, 30);
    const c = d.parseGo(goText('slot: cpu\nships: no\ntimeout: 21600\nstall: 5\nheadless: yes'));
    assert.equal(c.error, undefined); assert.equal(c.slot, 'cpu'); assert.equal(c.ceilingS, 21600); assert.equal(c.stallMin, 5);
    const b = d.parseGo(`PC go: ${SHA}\nreviewed: Board\njob: kit_1743\nflow: blender\nslot: cpu\nscript: tools/blender/kits/x.py\nexpect: kit.glb`);
    assert.equal(b.error, undefined); assert.equal(b.gpu, 'none', 'a cpu Blender job defaults to no GPU'); assert.equal(b.ships, false);
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
      [goText('stall: 1'), /stall must/],
      [goText('slot: cpu'), /cpu slot/, 'a windowed Godot on a cpu slot'],
      [goText('gpu: none'), /Blender only/],
      [goText('weight: 2'), /unknown line/],
      [goText('job: other'), /twice/],
      [goText().replace('res://tools/look_bench/run.gd', 'C:/x.gd'), /res:\/\//],
      [`PC go: ${SHA}\nreviewed: x\njob: k\nflow: blender\nexpect: a`, /blender script/],
      [`PC go: ${SHA}\nreviewed: x\njob: k\nflow: blender\nslot: cpu\ngpu: auto\nscript: a.py\nexpect: a`, /cpu slot/],
      [goText().replace(`PC go: ${SHA}`, 'PC go: abc123'), /first line/]
    ];
    for (const [text, why] of bad) { const s = d.parseGo(text); assert.ok(s && s.error, text); assert.match(s.error, why); }
  });

  // ------------------------------------------------------------------------------------------------- gate
  const g = (o) => d.gate({ pull: pull(), comments: [owner(goText())], checkRuns: green(), workflowRuns: wf(), ledger: new Set(), ...o });
  await t('gate: runs only on green checks.yml at the go commit', () => {
    assert.equal(g({}).verdict, 'run');
    assert.equal(g({ checkRuns: [] }).verdict, 'wait');
    assert.equal(g({ checkRuns: green(SHA, 'in_progress', null) }).verdict, 'wait');
    assert.equal(g({ checkRuns: green(SHA, 'completed', 'failure') }).verdict, 'refuse');
    assert.equal(g({ checkRuns: green(OLD) }).verdict, 'wait', 'a green run on another commit counts for nothing');
    const newest = [...green(SHA, 'completed', 'failure'), { ...green()[0], started_at: '2026-11-23T11:00:00Z' }];
    assert.equal(g({ checkRuns: newest }).verdict, 'run', 'the newest All checks run decides');
    assert.equal(g({ workflowRuns: wf(SHA, 11, '.github/workflows/other.yml') }).verdict, 'wait', 'a same-name check from another workflow');
    assert.equal(g({ workflowRuns: wf(SHA, 12) }).verdict, 'wait', 'a suite that is not checks.yml');
    assert.equal(g({ checkRuns: [{ ...green()[0], app: { slug: 'some-app' } }] }).verdict, 'wait', 'another check producer');
  });
  await t('gate: the newest owner go decides, and must name the head', () => {
    assert.equal(g({ comments: [] }).verdict, 'wait');
    assert.equal(g({ pull: pull(SHA, true) }).verdict, 'refuse', 'forks never run');
    assert.equal(g({ pull: pull(SHA, false, []) }).verdict, 'skip', 'the fetched PR must carry pc-ready');
    assert.equal(g({ pull: pull(SHA, false, []), claimed: true }).verdict, 'run', 'the recheck after the claim needs no label');
    const stale = g({ comments: [owner(goText('', OLD))] });
    assert.equal(stale.verdict, 'refuse'); assert.match(stale.why, /later push/);
    const stranger = { user: { login: 'someone' }, author_association: 'NONE', body: goText(), created_at: '2026-11-23T12:00:00Z' };
    assert.equal(g({ comments: [stranger] }).verdict, 'wait', 'a public commenter cannot start a PC job');
    assert.equal(g({ comments: [owner(goText()), stranger] }).verdict, 'run', 'nor hide the owner go');
    assert.equal(g({ comments: [{ ...owner(goText()), author_association: 'NONE' }] }).verdict, 'wait');
    assert.equal(g({ comments: [owner(goText('', OLD)), owner(goText())] }).verdict, 'run', 'the newest go wins');
    assert.equal(g({ comments: [owner(goText()), owner(goText('', OLD))] }).verdict, 'refuse');
    const malformed = g({ comments: [owner(goText()), owner('PC go: not-a-commit\nreviewed: x')] });
    assert.equal(malformed.verdict, 'refuse', 'a newer malformed go holds the job; the older good one never wins'); assert.match(malformed.why, /first line/);
    assert.equal(g({ comments: [owner(goText()), owner(goText('rm: x'))] }).verdict, 'refuse');
    const shuffled = [owner(goText('', OLD)), owner(goText())].reverse();
    assert.equal(g({ comments: shuffled }).verdict, 'run', 'order comes from the comment times, not the list');
    assert.equal(g({ complete: false }).verdict, 'refuse', 'an unread comment history holds the job');
    assert.equal(g({ pull: { ...pull(), state: 'closed' } }).verdict, 'skip');
  });
  await t('gate: never runs the same commit and job twice', () => {
    assert.equal(g({ ledger: new Set([SHA + ' lb_1777']) }).verdict, 'skip');
    assert.equal(g({ comments: [owner(goText()), owner('done ' + d.DONE_MARK(SHA, 'lb_1777'))] }).verdict, 'skip');
    const fake = { user: { login: 'someone' }, author_association: 'NONE', body: d.DONE_MARK(SHA, 'lb_1777') };
    assert.equal(g({ comments: [owner(goText()), fake] }).verdict, 'run', 'only our own done marker counts');
    assert.equal(g({ ledger: new Set([OLD + ' lb_1777']) }).verdict, 'run');
  });

  // ---------------------------------------------------------------------------------- step runner and watchdog
  const node = process.execPath;
  await t('runLogged: output logged, exit code, missing program, backstop kills nothing', async () => {
    const dir = tmp(), log = path.join(dir, 'log.txt');
    let r = await d.runLogged({ exe: node, args: ['-e', 'console.log("hi");process.exit(3)'], cwd: dir, env: process.env, logFile: log, backstopMs: 60000 });
    assert.equal(r.code, 3); assert.equal(r.backstop, false); assert.match(r.output, /hi/); assert.match(fs.readFileSync(log, 'utf8'), /hi/);
    r = await d.runLogged({ exe: path.join(dir, 'no_such_program'), args: [], cwd: dir, env: process.env, logFile: log, backstopMs: 60000 });
    assert.equal(r.code, null);
    const pidFile = path.join(dir, 'pid');
    r = await d.runLogged({ exe: node, args: ['-e', `require('fs').writeFileSync(${JSON.stringify(pidFile)},String(process.pid));setTimeout(()=>{},60000)`], cwd: dir, env: process.env, logFile: log, backstopMs: 1500 });
    assert.equal(r.backstop, true);
    const pid = +fs.readFileSync(pidFile, 'utf8');
    process.kill(pid, 0); // still alive: the backstop only stops waiting
    process.kill(pid);
  });
  await t('watchdog result: exits, timeouts and the quarantine signs', () => {
    const w = (code, output = '', backstop = false) => d.readWatchdog({ code, output, backstop });
    assert.equal(w(0).ok, true);
    assert.match(w(124, 'run_timeout: TIMEOUT IDLE after 600 s, killed x').why, /TIMEOUT IDLE/);
    assert.match(w(126).why, /GPU admission/); assert.match(w(125).why, /could not start/); assert.match(w(2).why, /exit 2/);
    assert.equal(w(1, 'KILL FAILED: surviving PIDs 12, 13 for step').quarantine, true);
    assert.equal(w(124, 'GPU: retaining claim 1234 as orphaned_child for PIDs 9').quarantine, true);
    assert.equal(w(null, '', true).quarantine, true);
    assert.equal(w(0).quarantine, undefined);
  });
  await t('watchdog call: tmo step mode, idle limit, GPU left to the classifier', async () => {
    const vt = tmp(), pc = path.join(vt, 'tools_live', 'v1', 'pc');
    fs.mkdirSync(path.join(pc, 'jobs'), { recursive: true });
    for (const f of ['jobs/opus_job_head.ps1', 'run_timeout.ps1', 'relay_push.ps1', 'runner_common.ps1']) fs.writeFileSync(path.join(pc, f), '');
    fs.writeFileSync(path.join(vt, 'tools_live', 'current.txt'), 'v1\r\n');
    const seen = [];
    const tools = new d.PcTools({ vt, runStep: async o => { seen.push(o); return { code: 0, output: '', backstop: false }; } });
    const call = gpu => tools.watchdog({ exe: 'C:\\Godot dir\\godot.exe', args: ['--path', 'C:\\slot repo\\godot', '--x'], cwd: vt,
      env: { TMO_REPO: 'leak', PC_RUNNER_TEST: '1' }, ceilingS: 600, stallMin: 10, outDir: 'O', label: 'pcd_x', gpu, logFile: path.join(vt, 'l.txt') });
    await call('auto'); await call('solo'); await call('none');
    const [a, s2, n] = seen;
    assert.equal(a.exe, 'powershell.exe');
    assert.deepEqual(a.args, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(pc, 'run_timeout.ps1')]);
    assert.equal(a.env.TMO_ARGS, '600 "C:\\Godot dir\\godot.exe" --path "C:\\slot repo\\godot" --x');
    assert.equal(a.env.TMO_IDLE_S, '600'); assert.equal(a.env.TMO_STEP_OUT, 'O'); assert.equal(a.env.PC_GPU_ISSUE, 'pcd_x');
    assert.equal(a.env.TMO_REPO, '', 'step mode: the agent-run watch is cleared'); assert.equal(a.env.PC_RUNNER_TEST, '', 'never the test copy');
    assert.equal(a.env.PC_GPU_MODE, '', 'auto leaves the mode to the classifier');
    assert.equal(s2.env.PC_GPU_MODE, 'solo'); assert.equal(n.env.PC_GPU_MODE, 'none');
    assert.equal(a.backstopMs, (600 + 9.5 * 3600) * 1000);
    fs.unlinkSync(path.join(pc, 'run_timeout.ps1'));
    assert.throws(() => tools.pc(), /run_timeout/, 'a tools_live without the watchdog fails closed');
  });
  await t('lease: one daemon per PC, freed when its process ends', async () => {
    const port = 47000 + Math.floor(Math.random() * 900);
    const a = await d.takeLease(port);
    await assert.rejects(d.takeLease(port), /another PC daemon holds the lease/);
    a.close(); await new Promise(r => setTimeout(r, 50));
    const b = await d.takeLease(port); b.close();
    // a holder that dies without closing frees it too
    const child = spawn(node, ['-e', `require('net').createServer().listen({host:'127.0.0.1',port:${port},exclusive:true},()=>console.log('up'))`], { stdio: ['ignore', 'pipe', 'ignore'] });
    await new Promise(r => child.stdout.once('data', r));
    await assert.rejects(d.takeLease(port), /another PC daemon/);
    child.kill('SIGKILL'); await new Promise(r => child.once('exit', r));
    const c = await d.takeLease(port); c.close();
    const live = new d.Daemon({ vt: tmp(), gh: {}, tools: {}, live: true, log: () => {} });
    await assert.rejects(live.tick(), /lease first/);
  });
  await t('paths: absolute plain PC root, live only on the real root, slot receipts checked', () => {
    const vt = tmp();
    assert.throws(() => d.checkRoot('relative/vt', {}), /absolute/);
    assert.throws(() => d.checkRoot('', {}), /absolute/);
    assert.equal(d.checkRoot(vt, {}), vt);
    const home = tmp(); fs.mkdirSync(path.join(home, 'Downloads', 'voidsworn_test'), { recursive: true });
    assert.equal(d.checkRoot(path.join(home, 'Downloads', 'voidsworn_test'), { live: true, profile: home }), path.join(home, 'Downloads', 'voidsworn_test'));
    assert.throws(() => d.checkRoot(vt, { live: true, profile: home }), /live daemon runs only/);
    assert.throws(() => d.checkRoot(vt, { live: true, profile: '' }), /USERPROFILE/);
    // a junction on Windows (no admin right needed), a directory link elsewhere; Node reads both as links
    const linked = path.join(vt, 'linked'); fs.symlinkSync(home, linked, process.platform === 'win32' ? 'junction' : 'dir');
    assert.throws(() => d.checkRoot(path.join(linked, 'Downloads', 'voidsworn_test'), {}), /plain folder/, 'a link anywhere above the root');
    const repo = path.join(vt, 'slots', 'slot_gpu_1', 'repo'); fs.mkdirSync(repo, { recursive: true });
    assert.equal(d.checkSlotRepo(vt, repo + '\n'.trim()), repo);
    for (const bad of ['', 'repo', path.join(vt, 'slots', 'slot_x', 'repo'), path.join(vt, 'elsewhere', 'slot_gpu_1', 'repo'), path.join(vt, 'slots', 'slot_gpu_2', 'repo')]) {
      assert.throws(() => d.checkSlotRepo(vt, bad), undefined, bad || '(empty)');
    }
  });

  // ---------------------------------------------------------------------------------------------- the daemon
  function fakes({ comments = [owner(goText())], runs = green(), workflow = wf(), exit = 0, output = '', writeOutputs = true, optionsChange = false,
    failStep = null, ghFails = false, relayFails = 0, labelFails = false, game = false, onSlot = null } = {}) {
    const vt = tmp(), calls = [];
    const gh = {
      writes: [], pullObj: pull(), runs, workflow,
      readyPulls: () => [7], pull() { return this.pullObj; },
      addLabel(n, l) { if (ghFails) throw new Error('offline'); this.writes.push(['add', n, l]); },
      removeLabel(n, l) { if (ghFails || (labelFails && l === 'pc-ready')) throw new Error('offline'); this.writes.push(['remove', n, l]); },
      comment(n, b) { if (ghFails) throw new Error('offline'); this.writes.push(['comment', n, b]); }
    };
    gh.comments = function () { return { items: this.commentList, complete: true }; };
    gh.commentList = comments;
    gh.checkRuns = function () { return this.runs; };
    gh.workflowRuns = function () { return this.workflow; };
    let opt = 0;
    const step = (name, fn) => (...a) => { calls.push(name); if (failStep === name) throw new Error('fake ' + name + ' failure'); return fn(...a); };
    let watchArgs = null;
    const tools = {
      preflight: step('preflight', () => ({ godot: 'C:\\godot.exe', blender: 'C:\\blender.exe' })),
      hashes: step('hashes', f => { const t2 = optionsChange && opt++ ? 'changed' : 'same'; fs.writeFileSync(f, t2); return t2; }),
      slot: step('slot', (attempt, name, pin, kind) => { assert.equal(pin, SHA); const r = path.join(vt, 'slots', kind === 'cpu' ? 'slot_cpu' : 'slot_gpu_1', 'repo'); fs.mkdirSync(r, { recursive: true }); if (onSlot) onSlot(gh, vt); return r; }),
      ships: step('ships', () => {}),
      watchdog: step('watchdog', async o => {
        watchArgs = o;
        if (writeOutputs) { fs.mkdirSync(path.join(o.outDir, 'shots')); fs.writeFileSync(path.join(o.outDir, 'shots', 'a.png'), 'png'); fs.writeFileSync(path.join(o.outDir, 'log.txt'), 'ok'); }
        return { code: exit, output, backstop: false, ms: 1000 };
      }),
      slotRelease: step('slotRelease', () => {}),
      slotHold: step('slotHold', repo => fs.writeFileSync(path.join(path.dirname(repo), 'hold.txt'), 'x', { flag: 'wx' })),
      relay: step('relay', () => { if (relayFails-- > 0) throw new Error('relay offline'); return 'folder link: https://github.com/rcbailey12/voidsworn-relay/tree/pc-out-lb_1777/x\npicture link: https://example.invalid/a.png\n'; }),
      gameRunning: () => typeof game === 'function' ? game() : game
    };
    const daemon = new d.Daemon({ vt, gh, tools, live: true, leased: true, log: () => {}, clock: () => new Date('2026-11-23T14:00:00Z') });
    return { vt, gh, calls, daemon, watchArgs: () => watchArgs };
  }
  const attemptOf = f => path.join(f.vt, 'lb_1777', fs.readdirSync(path.join(f.vt, 'lb_1777'))[0]);
  await t('daemon: a dry run reads and changes nothing', async () => {
    const f = fakes();
    f.daemon.live = false;
    const seen = await f.daemon.tick();
    assert.equal(seen[0].verdict, 'run');
    assert.deepEqual(f.gh.writes, []); assert.deepEqual(f.calls, []);
    assert.deepEqual(fs.readdirSync(f.vt), [], 'no file written on the PC');
  });
  await t('daemon: a passing job, in order, through the installed watchdog, reported once', async () => {
    const f = fakes();
    await f.daemon.tick();
    assert.deepEqual(f.calls, ['preflight', 'hashes', 'slot', 'ships', 'watchdog', 'hashes', 'slotRelease', 'relay']);
    const w = f.gh.writes;
    assert.deepEqual(w[0], ['remove', 7, 'pc-ready']); assert.deepEqual(w[1], ['add', 7, 'running']);
    assert.match(w[2][2], /started lb_1777/);
    assert.match(w[3][2], /lb_1777 PASS/); assert.match(w[3][2], /voidsworn-relay\/tree/); assert.ok(w[3][2].includes(d.DONE_MARK(SHA, 'lb_1777')));
    assert.deepEqual(w[4], ['remove', 7, 'running']);
    const attempt = attemptOf(f);
    assert.equal(fs.readFileSync(path.join(attempt, 'done.txt'), 'utf8').trim(), 'done PASS');
    const o = f.watchArgs();
    assert.equal(o.gpu, 'auto'); assert.equal(o.stallMin, 30); assert.equal(o.ceilingS, 3600); assert.equal(o.label, 'pcd_lb_1777');
    assert.equal(o.env.VS_OUT, path.join(attempt, 'out_lb_1777')); assert.equal(o.exe, 'C:\\godot.exe');
    assert.ok(!fs.existsSync(path.join(f.vt, 'slots', 'profiles')), 'the daemon makes no profile of its own');
    f.calls.length = 0; f.gh.writes.length = 0;
    const seen = await f.daemon.tick();
    assert.equal(seen[0].verdict, 'skip'); assert.deepEqual(f.calls, []); assert.deepEqual(f.gh.writes, []);
  });
  await t('daemon: no run when the pc-ready label will not come off', async () => {
    const f = fakes({ labelFails: true });
    await f.daemon.tick();
    assert.deepEqual(f.calls, []); assert.ok(!fs.existsSync(path.join(f.vt, 'pc_daemon', 'ran.txt')));
  });
  await t('daemon: a push, a new go or a pause during the slot wait aborts before launch', async () => {
    const cases = [
      ['push', gh => { gh.pullObj = pull(OLD); }, /approval changed/],
      ['newer malformed go', gh => { gh.commentList = [...gh.commentList, owner('PC go: nope')]; }, /approval changed/],
      ['checks turned red', gh => { gh.runs = green(SHA, 'completed', 'failure'); }, /approval changed/],
      ['closed', gh => { gh.pullObj = { ...pull(), state: 'closed' }; }, /approval changed/],
      ['pause', (gh, vt) => fs.writeFileSync(path.join(vt, 'gpu_go.txt'), 'GPU not cleared: paused by the Board\r\n'), /Board pause/]
    ];
    for (const [name, change, why] of cases) {
      const f = fakes({ onSlot: change });
      await f.daemon.tick();
      assert.ok(!f.calls.includes('watchdog'), name + ': nothing launched');
      assert.ok(f.calls.includes('slotRelease'), name + ': the slot is let go');
      const note = f.gh.writes.find(w => w[0] === 'comment' && /not started/.test(w[2]));
      assert.match(note[2], why, name);
      assert.equal(fs.readFileSync(path.join(attemptOf(f), 'done.txt'), 'utf8').trim().split(':')[0], 'done ABORTED');
      assert.equal(f.daemon.ledger().size, 0, name + ': an abort does not use up the run key');
    }
    let n = 0;
    const p = fakes({ game: () => (++n > 1 ? null : false) });
    await p.daemon.tick();
    assert.ok(!p.calls.includes('watchdog'), 'an unreadable process list before launch counts as playing');
  });
  await t('daemon: a failing step still lets the slot go and relays the logs', async () => {
    const f = fakes({ exit: 124, output: 'run_timeout: TIMEOUT IDLE after 1800 s, killed godot.exe' });
    await f.daemon.tick();
    assert.ok(f.calls.includes('slotRelease') && f.calls.includes('relay'));
    const result = f.gh.writes.find(w => w[0] === 'comment' && /FAILED/.test(w[2]));
    assert.match(result[2], /failed: run/); assert.match(result[2], /TIMEOUT IDLE/);
    const g2 = fakes({ failStep: 'ships' });
    await g2.daemon.tick();
    assert.ok(!g2.calls.includes('watchdog'), 'nothing after a failed step starts');
    assert.ok(g2.calls.includes('slotRelease'));
    assert.match(g2.gh.writes.find(w => w[0] === 'comment' && /FAILED/.test(w[2]))[2], /failed: ships/);
    const g3 = fakes({ onSlot: () => {} });
    g3.daemon.tools.slot = (attempt) => { g3.calls.push('slot'); return path.join(g3.vt, 'elsewhere'); };
    await g3.daemon.tick();
    assert.ok(!g3.calls.includes('ships') && !g3.calls.includes('watchdog'), 'a bad slot receipt stops the job');
  });
  await t('daemon: missing outputs and changed options fail the job', async () => {
    const f = fakes({ writeOutputs: false });
    await f.daemon.tick();
    assert.match(f.gh.writes.find(w => /FAILED/.test(w[2] || ''))[2], /failed: outputs/);
    const o = fakes({ optionsChange: true });
    await o.daemon.tick();
    assert.match(o.gh.writes.find(w => /FAILED/.test(w[2] || ''))[2], /failed: options/);
  });
  await t('daemon: a tree that will not die is quarantined, and the hold survives a restart', async () => {
    const f = fakes({ exit: 1, output: 'KILL FAILED: surviving PIDs 4242 for pcd_lb_1777' });
    await f.daemon.tick();
    assert.ok(!f.calls.includes('slotRelease'), 'the slot is not let go');
    assert.ok(fs.existsSync(path.join(f.vt, 'slots', 'slot_gpu_1', 'hold.txt')), 'the slot is set aside for the Board');
    assert.match(fs.readFileSync(path.join(f.vt, 'pc_daemon', 'hold.txt'), 'utf8'), /KILL FAILED/);
    assert.match(f.gh.writes.find(w => /FAILED/.test(w[2] || ''))[2], /QUARANTINE/);
    // a new daemon process on the same PC starts nothing while the hold is there
    const again = new d.Daemon({ vt: f.vt, gh: f.gh, tools: f.daemon.tools, live: true, leased: true, log: () => {} });
    f.gh.commentList = [owner(goText().replace('job: lb_1777', 'job: lb_1777b'))];
    f.calls.length = 0;
    assert.deepEqual(await again.tick(), []); assert.deepEqual(f.calls, []);
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
  });
  await t('daemon: one unreadable result record is reported once and never stalls the queue', async () => {
    const f = fakes({ relayFails: 1 });
    await f.daemon.tick();
    fs.writeFileSync(path.join(attemptOf(f), 'pc_daemon_result.json'), '{broken');
    f.daemon.retryMs = 0; f.gh.writes.length = 0; f.calls.length = 0;
    f.gh.commentList = [owner(goText().replace('job: lb_1777', 'job: lb_next'))];
    await f.daemon.tick();
    assert.equal(f.gh.writes.filter(w => w[0] === 'comment' && /could not be read/.test(w[2])).length, 1);
    assert.ok(f.calls.includes('watchdog'), 'the next job still runs');
    f.gh.writes.length = 0;
    await f.daemon.tick();
    assert.equal(f.gh.writes.filter(w => /could not be read/.test(w[2] || '')).length, 0, 'said once');
  });
  await t('daemon: a start with no result (stopped mid-job) does not block a new go', async () => {
    const f = fakes();
    fs.mkdirSync(path.join(f.vt, 'pc_daemon'));
    fs.writeFileSync(path.join(f.vt, 'pc_daemon', 'ran.txt'), `2026-11-23T13:00:00Z ${SHA} lb_1777 PR7 start\r\n`);
    assert.equal((await f.daemon.tick())[0].verdict, 'run');
    assert.ok(f.calls.includes('watchdog'));
  });
  await t('daemon: GitHub failures after the claim never fail the job', async () => {
    const f = fakes();
    let n = 0;
    f.gh.addLabel = () => { throw new Error('offline'); };
    f.gh.comment = () => { if (n++ === 0) throw new Error('offline'); };
    await f.daemon.tick();
    assert.equal(fs.readFileSync(path.join(attemptOf(f), 'done.txt'), 'utf8').trim(), 'done PASS');
  });
  await t('daemon: a refusal is said once and takes the label off', async () => {
    const f = fakes({ runs: green(SHA, 'completed', 'failure') });
    await f.daemon.tick(); await f.daemon.tick();
    assert.equal(f.gh.writes.filter(w => w[0] === 'comment').length, 1);
    assert.deepEqual(f.gh.writes.find(w => w[0] === 'remove'), ['remove', 7, 'pc-ready']);
    assert.deepEqual(f.calls, []);
  });
  await t('daemon: the Board pause and Ryan playing (or an unreadable process list) hold every start', async () => {
    const f = fakes();
    fs.writeFileSync(path.join(f.vt, 'gpu_go.txt'), 'GPU not cleared: paused by the Board at 14:00\r\n');
    assert.deepEqual(await f.daemon.tick(), []);
    assert.deepEqual(f.calls, []); assert.deepEqual(f.gh.writes, []);
    for (const game of [true, null]) {
      const p = fakes({ game });
      await p.daemon.tick();
      assert.deepEqual(p.calls, []); assert.deepEqual(p.gh.writes, []);
    }
  });
  await t('commands: godot and blender lines, placeholders filled, no shell', () => {
    const s = d.parseGo(goText('headless: yes'));
    const c = d.command(s, path.join('S', 'repo'), path.join('A', 'out'));
    assert.deepEqual(c.args, ['--headless', '--path', path.join('S', 'repo', 'godot'), '--script', 'res://tools/look_bench/run.gd', '--ship', 'A17', '--out', path.join('A', 'out')]);
    const b = d.parseGo(`PC go: ${SHA}\nreviewed: Board\njob: kit\nflow: blender\nscript: tools/blender/x.py\nargs: --code A17\nexpect: kit.glb`);
    assert.deepEqual(d.command(b, 'R', 'O').args, ['-b', '--factory-startup', '--python', path.join('R', 'tools', 'blender', 'x.py'), '--', '--code', 'A17']);
  });
  await t('GhCli: REST calls through gh api, bodies as an input file, full comment history or none', () => {
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
    const full = new d.GhCli({ run: () => ({ status: 0, stdout: JSON.stringify(Array(100).fill({})), stderr: '' }) });
    assert.equal(full.comments(1).complete, false, 'a history past the page cap is reported incomplete');
    const wfRuns = new d.GhCli({ run: (e, a) => ({ status: 0, stdout: JSON.stringify({ workflow_runs: [{ path: d.CHECKS_WORKFLOW }], url: a[1] }), stderr: '' }) });
    assert.equal(wfRuns.workflowRuns(SHA)[0].path, d.CHECKS_WORKFLOW);
  });
  console.log(`PASS: pc_daemon ${passed} checks (go comment, gate, step runner, watchdog contract, lease, paths, daemon order, recheck, failures, quarantine, delivery, commands, gh calls)`);
})().catch(e => { console.error('FAIL: ' + (e.stack || e.message)); process.exit(1); });
