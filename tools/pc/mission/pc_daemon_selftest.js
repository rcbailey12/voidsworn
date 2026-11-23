'use strict';
// Issue 1662: tests for pc_daemon.js. Everything runs in new TEMP folders with fake GitHub and fake PC tools; no
// network, no PC, no GitHub writes. runLogged and the lease use real child processes and a real localhost bind.
// No timing-sensitive counts (Astra audit of PR 1835, finding 10): every wait is on a fact, not a clock. On Windows one
// more group runs the real adapter through the real run_timeout.ps1 with a Node stand-in (Astra run 2, item 10).
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
// the "All checks" job of one workflow run attempt (run ids double as suite numbers here)
const green = (sha = SHA, status = 'completed', conclusion = 'success', run = 11, attempt = 1) => [{ name: 'All checks', head_sha: sha, status, conclusion, run_id: run, run_attempt: attempt }];
const wf = (sha = SHA, suite = 11, p = d.CHECKS_WORKFLOW, status = 'completed', conclusion = 'success', runNumber = 5) =>
  [{ id: suite, path: p, head_sha: sha, check_suite_id: suite, status, conclusion, run_number: runNumber, run_attempt: 1, created_at: '2026-11-23T09:59:00Z' }];
const rec = (o = {}) => ({ version: 1, exit: 0, reason: 'exited', started: true, treeEmpty: true, gated: '', profile: '', profileRemoved: true, ...o });
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
    const b = d.parseGo(`PC go: ${SHA}\nreviewed: Board\njob: kit_1743\nflow: blender\nslot: cpu\ngpu: none\nscript: tools/blender/kits/x.py\nexpect: kit.glb`);
    assert.equal(b.error, undefined); assert.equal(b.gpu, 'none'); assert.equal(b.ships, false);
    const nb = d.parseGo(`PC go: ${SHA}\nreviewed: Board\njob: kit_1743\nflow: blender\nslot: cpu\nscript: tools/blender/kits/x.py\nexpect: kit.glb`);
    assert.match(nb.error, /cpu slot/, 'a cpu Blender job must say gpu: none itself (Astra run 2, item 6)');
    assert.equal(d.parseGo(`PC go: ${SHA}\nreviewed: Board\njob: k\nflow: blender\nscript: x.py\nexpect: a`).gpu, 'auto', 'Blender never defaults to no claim');
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
  const g = (o) => d.gate({ pull: pull(), comments: [owner(goText())], jobs: green(), workflowRuns: wf(), ledger: new Set(), ...o });
  await t('gate: runs only on the green "All checks" job of the newest checks.yml run and attempt', () => {
    assert.equal(g({}).verdict, 'run');
    assert.equal(g({ jobs: [] }).verdict, 'wait');
    assert.equal(g({ jobs: green(SHA, 'in_progress', null) }).verdict, 'wait');
    assert.equal(g({ jobs: green(SHA, 'completed', 'failure') }).verdict, 'refuse');
    assert.equal(g({ jobs: green(OLD) }).verdict, 'wait', 'a green job on another commit counts for nothing');
    assert.equal(g({ workflowRuns: wf(SHA, 11, '.github/workflows/other.yml') }).verdict, 'wait', 'a same-name job from another workflow');
    assert.equal(g({ jobs: green(SHA, 'completed', 'success', 12) }).verdict, 'wait', 'a job from another run');
    assert.equal(g({ workflowRuns: wf(OLD) }).verdict, 'wait', 'a run at another commit');
    // the newest run decides, not an older green one
    const rerun = [...wf(SHA, 11), ...wf(SHA, 12, d.CHECKS_WORKFLOW, 'in_progress', null, 6)];
    assert.equal(g({ workflowRuns: rerun }).verdict, 'wait', 'a newer run still going holds the job even with an older green aggregate');
    assert.equal(g({ workflowRuns: [...wf(SHA, 11), ...wf(SHA, 12, d.CHECKS_WORKFLOW, 'completed', 'failure', 6)] }).verdict, 'refuse');
    assert.equal(g({ workflowRuns: [...wf(SHA, 12, d.CHECKS_WORKFLOW, 'completed', 'success', 6), ...wf(SHA, 11, d.CHECKS_WORKFLOW, 'completed', 'failure', 5)],
      jobs: green(SHA, 'completed', 'success', 12) }).verdict, 'run', 'its own aggregate, not the older one');
    // a rerun of the same workflow run: attempt 2 decides, never attempt 1's job (Astra run 3, item 8)
    const second = [{ ...wf()[0], run_attempt: 2 }];
    assert.equal(g({ workflowRuns: second, jobs: green(SHA, 'completed', 'success', 11, 1) }).verdict, 'wait', 'attempt 1\'s green job does not count for attempt 2');
    assert.equal(g({ workflowRuns: second, jobs: [...green(SHA, 'completed', 'success', 11, 1), ...green(SHA, 'completed', 'success', 11, 2)] }).verdict, 'run');
    assert.equal(g({ workflowRuns: [{ ...second[0], status: 'in_progress', conclusion: null }], jobs: green(SHA, 'completed', 'success', 11, 1) }).verdict, 'wait', 'a rerun still going');
    assert.equal(d.newestChecksRun([...wf(SHA, 11), { ...wf(SHA, 11)[0], run_attempt: 3 }], SHA).run_attempt, 3);
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
  await t('watchdog result: only the watchdog record proves the tree, never the log text', () => {
    const scratch = path.join(os.tmpdir(), 'slot_x', 'run_scratch'), prof = path.join(scratch, 'voidsworn-run-1', 'godot-profile-2');
    const w = (code, r = rec({ profile: prof }), extra = {}) => d.readWatchdog({ code, output: '', backstop: false, ...extra }, r, scratch);
    assert.equal(w(0).ok, true);
    assert.match(w(124, rec({ exit: 124, reason: 'TIMEOUT IDLE after 600 s', profile: prof })).why, /TIMEOUT IDLE/);
    assert.match(w(126, rec({ started: false })).why, /GPU admission/); assert.match(w(125, rec({ started: false })).why, /could not start/); assert.match(w(2).why, /exit 2/);
    assert.equal(w(1, rec({ treeEmpty: false, profile: prof })).quarantine, true, 'survivors');
    assert.equal(w(0, rec({ treeEmpty: null, profile: prof })).quarantine, true, 'unproven');
    assert.equal(w(0, null).quarantine, true, 'no record at all');
    assert.equal(w(null, null, { backstop: true }).quarantine, true);
    assert.equal(w(null, null, { startError: true }).quarantine, undefined, 'powershell never started');
    assert.equal(d.readWatchdog({ code: 0, output: 'KILL FAILED: an old line quoted by the job\nretaining claim 1 as orphaned_child', backstop: false }, rec({ profile: prof }), scratch).ok, true,
      'a child log quoting a failure sets nothing (Astra run 2, item F)');
    const gated = w(125, rec({ started: false, gated: 'not started: the Board pause began' }));
    assert.equal(gated.gated, 'not started: the Board pause began'); assert.equal(gated.quarantine, undefined);
    assert.match(w(0, rec({ profile: '' })).why, /without a throwaway profile/, 'a started step must have had its own profile');
    assert.match(w(0, rec({ profile: path.join(os.tmpdir(), 'voidsworn-run-1', 'p') })).why, /outside the slot/, 'never a profile in TEMP (Astra run 2, item B)');
    assert.match(w(0, rec({ profile: prof, profileRemoved: false })).why, /kept for the janitor/);
    assert.equal(w(0, rec({ profile: prof, profileRemoved: false })).ok, true);
  });
  await t('Windows quoting: a trailing backslash never merges two arguments', () => {
    // CommandLineToArgvW's rules, as the C runtime reads a command line
    const parse = line => {
      const out = []; let i = 0;
      while (i < line.length) {
        while (line[i] === ' ') i++;
        if (i >= line.length) break;
        let arg = '', quoted = false;
        for (; i < line.length; i++) {
          let n = 0; while (line[i] === '\\') { n++; i++; }
          if (line[i] === '"') { arg += '\\'.repeat(n >> 1); if (n % 2) { arg += '"'; continue; } quoted = !quoted; continue; }
          arg += '\\'.repeat(n);
          if (i >= line.length) break;
          if (line[i] === ' ' && !quoted) break;
          arg += line[i];
        }
        out.push(arg);
      }
      return out;
    };
    const args = ['C:\\out dir\\', '--next', 'plain', 'C:\\a b\\\\', 'say "hi"', '', 'x\\y'];
    assert.deepEqual(parse(args.map(d.winQuote).join(' ')), args);
    assert.equal(d.winQuote('C:\\plain\\'), 'C:\\plain\\', 'no space, no quotes, left alone');
  });
  await t('watchdog call: tmo step mode, idle limit, GPU left to the classifier', async () => {
    const vt = tmp(), pc = path.join(vt, 'tools_live', 'v1', 'pc');
    fs.mkdirSync(path.join(pc, 'jobs'), { recursive: true });
    for (const f of ['jobs/opus_job_head.ps1', 'run_timeout.ps1', 'relay_push.ps1', 'runner_common.ps1']) fs.writeFileSync(path.join(pc, f), '');
    fs.writeFileSync(path.join(vt, 'tools_live', 'current.txt'), 'v1\r\n');
    const seen = [];
    const tools = new d.PcTools({ vt, runStep: async o => { seen.push(o); return { code: 0, output: '', backstop: false }; } });
    const call = gpu => tools.watchdog({ exe: 'C:\\Godot dir\\godot.exe', args: ['--path', 'C:\\slot repo\\godot', '--out', 'C:\\out dir\\', '--x'], cwd: vt,
      env: { TMO_REPO: 'leak', PC_RUNNER_TEST: '1', PC_RUN_SCRATCH: 'C:\\elsewhere', PC_KEEP_GODOT_PROFILE: '1' }, ceilingS: 600, stallMin: 10, outDir: 'O', label: 'pcd_x', gpu,
      logFile: path.join(vt, 'l.txt'), record: 'R.json', scratch: 'S', gateJs: 'G.js', gateArg: 'A' });
    await call('auto'); await call('solo'); await call('none');
    const [a, s2, n] = seen;
    assert.equal(a.exe, 'powershell.exe');
    assert.deepEqual(a.args, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(pc, 'run_timeout.ps1')]);
    assert.equal(a.env.TMO_ARGS, '600 "C:\\Godot dir\\godot.exe" --path "C:\\slot repo\\godot" --out "C:\\out dir\\\\" --x');
    assert.equal(a.env.PC_STEP_RECORD, 'R.json'); assert.equal(a.env.PC_STEP_WAIT_TREE, '1'); assert.equal(a.env.PC_STEP_SCRATCH_PARENT, 'S');
    assert.equal(a.env.PC_STEP_PROFILE_ANY, '1'); assert.equal(a.env.PC_STEP_GATE_JS, 'G.js'); assert.equal(a.env.PC_STEP_GATE_ARG, 'A');
    assert.equal(a.env.PC_RUN_SCRATCH, '', 'never a scratch outside the slot'); assert.equal(a.env.PC_KEEP_GODOT_PROFILE, '');
    assert.equal(a.env.TMO_IDLE_S, '600'); assert.equal(a.env.TMO_STEP_OUT, 'O'); assert.equal(a.env.PC_GPU_ISSUE, 'pcd_x');
    assert.equal(a.env.TMO_REPO, '', 'step mode: the agent-run watch is cleared'); assert.equal(a.env.PC_RUNNER_TEST, '', 'never the test copy');
    assert.equal(a.env.PC_GPU_MODE, '', 'auto leaves the mode to the classifier');
    assert.equal(s2.env.PC_GPU_MODE, 'solo'); assert.equal(n.env.PC_GPU_MODE, 'none');
    assert.equal(a.backstopMs, (600 + 9.5 * 3600) * 1000);
    // the attempt pins the version its bundle check verified, even if current.txt moves on
    const ran = [];
    const pinTools = new d.PcTools({ vt, run: (exe, args) => { ran.push(args); return { status: 0, stdout: 'verified', stderr: '' }; } });
    assert.throws(() => pinTools.pin(), /no PC daemon step settings/, 'an older verified watchdog is refused (Astra run 3, item G)');
    assert.equal(pinTools.pinned, null);
    fs.writeFileSync(path.join(pc, 'run_timeout.ps1'), 'param()\r\n# pc-step-settings: 1\r\n');
    assert.equal(pinTools.pin(), pc);
    assert.deepEqual(ran[0].slice(4), [path.join(pc, 'jobs', 'opus_job_head.ps1'), 'bundle', 'daemon', pc, path.join(vt, 'tools_live', 'v1', 'hashes.txt')]);
    fs.writeFileSync(path.join(vt, 'tools_live', 'current.txt'), 'v2\r\n');
    assert.equal(pinTools.pc(), pc, 'pinned for the attempt');
    pinTools.unpin(); assert.throws(() => pinTools.pc(), /no installed/);
    fs.writeFileSync(path.join(vt, 'tools_live', 'current.txt'), 'v1\r\n');
    const bad = new d.PcTools({ vt, run: () => ({ status: 1, stdout: 'run_timeout.ps1 differs from hashes.txt', stderr: '' }) });
    assert.throws(() => bad.pin(), /differs/); assert.equal(bad.pinned, null, 'a failed bundle check pins nothing');
    fs.unlinkSync(path.join(pc, 'run_timeout.ps1'));
    assert.throws(() => tools.pc(), /run_timeout/, 'a tools_live without the watchdog fails closed');
  });
  await t('slot lease: the receipt must be the leased slot of the asked kind, and the marker is the daemon\'s own', () => {
    const vt = tmp(), attempt = path.join(vt, 'job', 'out_1'); fs.mkdirSync(attempt, { recursive: true });
    const token = 'c'.repeat(32), tools = new d.PcTools({ vt });
    let live = true; const checks = [];
    tools.slotCheck = (att, lease) => { checks.push(lease.dir); if (!live) throw new Error('the slot helper does not prove it held'); };
    const mk = (name, tok = token, att = attempt, extra = '') => {
      const dir = path.join(vt, 'slots', name); fs.mkdirSync(path.join(dir, 'repo'), { recursive: true });
      fs.writeFileSync(path.join(dir, 'owner.txt'), `attempt ${att}\r\ntoken ${tok}\r\njob process 1 2\r\nholder 3\r\n${extra}`);
      fs.writeFileSync(path.join(dir, `holder_${tok}.txt`), 'held 3 4\r\n');
      return dir;
    };
    const g1 = mk('slot_gpu_1'), g2 = mk('slot_gpu_2', 'd'.repeat(32), path.join(vt, 'job', 'out_other'));
    fs.writeFileSync(path.join(attempt, 'slot.txt'), `${g1}|${token}\r\n`);
    assert.deepEqual(tools.slotLease(attempt, path.join(g1, 'repo'), 'gpu'), { dir: g1, token });
    assert.throws(() => tools.slotLease(attempt, path.join(g2, 'repo'), 'gpu'), /not the leased slot/, 'a receipt naming the other existing slot');
    assert.throws(() => tools.slotLease(attempt, path.join(g1, 'repo'), 'cpu'), /a cpu job got slot_gpu_1/);
    fs.writeFileSync(path.join(attempt, 'slot.txt'), `${g2}|${token}\r\n`);
    assert.throws(() => tools.slotLease(attempt, path.join(g2, 'repo'), 'gpu'), /token/, 'another attempt\'s lease');
    mk('slot_gpu_1', token, attempt, 'released 2026\r\n'); fs.writeFileSync(path.join(attempt, 'slot.txt'), `${g1}|${token}\r\n`);
    assert.throws(() => tools.slotLease(attempt, path.join(g1, 'repo'), 'gpu'), /let go/);
    fs.writeFileSync(path.join(g1, 'owner.txt'), `attempt ${attempt}\r\ntoken ${token}\r\n`);
    live = false;
    assert.throws(() => tools.slotLease(attempt, path.join(g1, 'repo'), 'gpu'), /does not prove/, 'saved files alone are not a held lease');
    live = true; checks.length = 0;
    // the in-flight marker: written once, cleared only while the lease is proven live and it is exactly the daemon's text
    const f = tools.inFlight({ dir: g2, token }, attempt);
    assert.ok(fs.existsSync(path.join(g2, 'run_scratch')));
    assert.throws(() => tools.inFlight({ dir: g2, token }, attempt), /EEXIST/, 'never over an existing hold');
    live = false;
    assert.throws(() => tools.clearInFlight(f), /does not prove/); assert.ok(fs.existsSync(f.marker), 'no live lease, no removal');
    live = true;
    tools.clearInFlight(f); assert.ok(!fs.existsSync(f.marker)); assert.deepEqual(checks, [g2, g2]);
    const f2 = tools.inFlight({ dir: g2, token }, attempt);
    tools.holdInFlight(f2, 'survivors');
    assert.throws(() => tools.clearInFlight(f2), /changed/); assert.match(fs.readFileSync(f2.marker, 'utf8'), /QUARANTINE: survivors/);
    assert.deepEqual(fs.readdirSync(g2).filter(n => /clearing/.test(n)), [], 'a changed marker is put back whole');
    fs.unlinkSync(f2.marker);
    // the scratch folder is checked before the marker exists (Astra run 3, item I)
    const g3 = path.join(vt, 'slots', 'slot_cpu'); fs.mkdirSync(g3, { recursive: true });
    fs.symlinkSync(tmp(), path.join(g3, 'run_scratch'), process.platform === 'win32' ? 'junction' : 'dir');
    assert.throws(() => tools.inFlight({ dir: g3, token }, attempt), /plain folder/);
    assert.ok(!fs.existsSync(path.join(g3, 'hold.txt')), 'no marker stranded');
  });
  await t('play check: the watchdog\'s rule, read through one process query', () => {
    assert.equal(d.playing('Voidsworn.exe', '"C:\\Games\\Voidsworn.exe"'), true);
    assert.equal(d.playing('Godot_v4.7.exe', '"C:\\Godot\\Godot_v4.7.exe" --path "C:\\vs\\godot"'), true, 'a windowed Godot with only --path is play');
    assert.equal(d.playing('Godot_v4.7.exe', 'Godot_v4.7.exe --path C:\\slot\\godot --headless --script x.gd'), false, 'a job');
    assert.equal(d.playing('Godot_v4.7_console.exe', 'Godot_v4.7_console.exe'), false);
    assert.equal(d.playing('Voidsworn.exe', ''), true, 'an unreadable command line counts as play');
    const answer = out => new d.PcTools({ vt: tmp(), run: () => out });
    assert.equal(answer({ status: 0, stdout: '' }).gameRunning(), false);
    assert.equal(answer({ status: 0, stdout: JSON.stringify({ n: 'Godot.exe', c: 'Godot.exe' }) }).gameRunning(), true);
    assert.equal(answer({ status: 0, stdout: JSON.stringify([{ n: 'Godot.exe', c: 'Godot.exe --headless' }]) }).gameRunning(), false);
    assert.equal(answer({ status: 1, stdout: '' }).gameRunning(), null);
    assert.equal(answer({ status: 0, stdout: '{broken' }).gameRunning(), null);
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
    failStep = null, ghFails = false, relayFails = 0, labelFails = false, game = false, onSlot = null, record = {} } = {}) {
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
    gh.runJobs = function (id, attempt) { assert.equal(id, 11); assert.equal(attempt, 1); return this.runs; };
    gh.workflowRuns = function () { return this.workflow; };
    let opt = 0;
    const step = (name, fn) => (...a) => { calls.push(name); if (failStep === name) throw new Error('fake ' + name + ' failure'); return fn(...a); };
    let watchArgs = null;
    const tools = {
      preflight: step('preflight', () => ({ godot: 'C:\\godot.exe', blender: 'C:\\blender.exe' })),
      hashes: step('hashes', f => { const t2 = optionsChange && opt++ ? 'changed' : 'same'; fs.writeFileSync(f, t2); return t2; }),
      slot: step('slot', (attempt, name, pin, kind) => { assert.equal(pin, SHA); const r = path.join(vt, 'slots', kind === 'cpu' ? 'slot_cpu' : 'slot_gpu_1', 'repo'); fs.mkdirSync(r, { recursive: true }); if (onSlot) onSlot(gh, vt); return r; }),
      ships: step('ships', () => {}),
      pin: step('pin', () => 'C:\\tools_live\\v1\\pc'),
      unpin: () => {},
      slotLease: step('slotLease', (attempt, repo) => ({ dir: path.dirname(repo), token: 'e'.repeat(32) })),
      inFlight: step('inFlight', (lease, attempt) => d.PcTools.prototype.inFlight(lease, attempt)),
      clearInFlight: step('clearInFlight', f => d.PcTools.prototype.clearInFlight.call({ slotCheck: () => {} }, f)),
      holdInFlight: step('holdInFlight', (f, why) => d.PcTools.prototype.holdInFlight(f, why)),
      watchdog: step('watchdog', async o => {
        watchArgs = o;
        if (record !== null) {
          const r = typeof record === 'function' ? record(o) : record;
          if (r !== null) fs.writeFileSync(o.record, JSON.stringify(rec({ exit, profile: path.join(o.scratch, 'voidsworn-run-1', 'godot-profile-1'), ...r })));
        }
        if (writeOutputs && !(record && record.gated)) { fs.mkdirSync(path.join(o.outDir, 'shots')); fs.writeFileSync(path.join(o.outDir, 'shots', 'a.png'), 'png'); fs.writeFileSync(path.join(o.outDir, 'log.txt'), 'ok'); }
        return { code: exit, output, backstop: false, ms: 1000 };
      }),
      slotRelease: step('slotRelease', () => {}),
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
    assert.deepEqual(f.calls, ['pin', 'preflight', 'hashes', 'slot', 'slotLease', 'ships', 'inFlight', 'watchdog', 'clearInFlight', 'hashes', 'slotRelease', 'relay']);
    assert.ok(!fs.existsSync(path.join(f.vt, 'slots', 'slot_gpu_1', 'hold.txt')), 'the in-flight marker is gone once the tree is proven gone');
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
    assert.equal(o.scratch, path.join(f.vt, 'slots', 'slot_gpu_1', 'run_scratch'), 'profile and logs inside the held slot');
    assert.equal(o.record, path.join(attempt, 'watchdog_record.json')); assert.equal(o.gateArg, attempt);
    assert.equal(o.gateJs, require.resolve('./pc_daemon'));
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
      ['same job and commit, new arguments', gh => { gh.commentList = [...gh.commentList, owner(goText().replace('--ship A17', '--ship C10'))]; }, /replaced this job spec/],
      ['checks turned red', gh => { gh.runs = green(SHA, 'completed', 'failure'); }, /approval changed/],
      ['closed', gh => { gh.pullObj = { ...pull(), state: 'closed' }; }, /approval changed/],
      ['pause', (gh, vt) => fs.writeFileSync(path.join(vt, 'gpu_go.txt'), 'GPU not cleared: paused by the Board\r\n'), /Board pause/],
      ['GitHub down', gh => { gh.pull = () => { throw new Error('HTTP 502'); }; }, /GitHub could not be read/]
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
  await t('daemon: the watchdog\'s own launch gate (after its waits) can still stop the start', async () => {
    const f = fakes({ exit: 125, record: { started: false, gated: 'not started: a newer PC go replaced this job spec', profile: '' } });
    await f.daemon.tick();
    assert.match(f.gh.writes.find(w => w[0] === 'comment' && /not started/.test(w[2]))[2], /launch gate said no: not started: a newer PC go/);
    assert.ok(f.calls.includes('clearInFlight') && f.calls.includes('slotRelease'), 'nothing ran: the marker and the slot go');
    assert.equal(f.daemon.ledger().size, 0, 'the job stays eligible');
    assert.ok(!fs.existsSync(path.join(f.vt, 'pc_daemon', 'hold.txt')));
    // the gate itself: the daemon's recheck, as the watchdog calls it
    const r = fakes();
    assert.equal(r.daemon.recheck(7, d.parseGo(goText())), null);
    r.gh.commentList = [...r.gh.commentList, owner(goText().replace('expect: shots/a.png log.txt', 'expect: other.png'))];
    assert.match(r.daemon.recheck(7, d.parseGo(goText())), /replaced this job spec/);
    const q = fakes({ game: null });
    assert.match(q.daemon.recheck(7, d.parseGo(goText())), /process list could not be read/);
  });
  await t('daemon: a failing step still lets the slot go and relays the logs', async () => {
    const f = fakes({ exit: 124, record: { reason: 'TIMEOUT IDLE after 1800 s without output' } });
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
    const g4 = fakes({ failStep: 'slotLease' });
    await g4.daemon.tick();
    assert.ok(!g4.calls.includes('ships') && !g4.calls.includes('watchdog') && g4.calls.includes('slotRelease'), 'a lease that does not match stops the job');
    const g5 = fakes({ failStep: 'pin' });
    await g5.daemon.tick();
    assert.ok(!g5.calls.includes('slot') && !g5.calls.includes('watchdog'), 'unverified tools start nothing');
    assert.match(g5.gh.writes.find(w => w[0] === 'comment' && /FAILED/.test(w[2]))[2], /failed: tools/);
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
    const f = fakes({ exit: 124, record: { treeEmpty: false, reason: 'TIMEOUT CEILING at 600 s' } });
    await f.daemon.tick();
    assert.ok(!f.calls.includes('slotRelease') && !f.calls.includes('clearInFlight'), 'the slot is not let go');
    assert.match(fs.readFileSync(path.join(f.vt, 'slots', 'slot_gpu_1', 'hold.txt'), 'utf8'), /in flight[\s\S]*QUARANTINE: processes outlived/, 'the slot is set aside for the Board');
    assert.match(fs.readFileSync(path.join(f.vt, 'pc_daemon', 'hold.txt'), 'utf8'), /outlived the step/);
    assert.match(f.gh.writes.find(w => /FAILED/.test(w[2] || ''))[2], /QUARANTINE/);
    // a new daemon process on the same PC starts nothing while the hold is there
    const again = new d.Daemon({ vt: f.vt, gh: f.gh, tools: f.daemon.tools, live: true, leased: true, log: () => {} });
    f.gh.commentList = [owner(goText().replace('job: lb_1777', 'job: lb_1777b'))];
    f.calls.length = 0;
    assert.deepEqual(await again.tick(), []); assert.deepEqual(f.calls, []);
    const none = fakes({ record: null });
    await none.daemon.tick();
    assert.match(fs.readFileSync(path.join(none.vt, 'pc_daemon', 'hold.txt'), 'utf8'), /no step record/, 'no watchdog record is a quarantine too');
    const thrown = fakes();
    thrown.daemon.tools.watchdog = async () => { thrown.calls.push('watchdog'); throw new Error('spawn EPERM'); };
    await thrown.daemon.tick();
    assert.match(fs.readFileSync(path.join(thrown.vt, 'pc_daemon', 'hold.txt'), 'utf8'), /without a watchdog result/);
    assert.ok(!thrown.calls.includes('slotRelease'));
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
  await t('daemon: a daemon that stopped mid-job holds every start; its slot keeps the in-flight marker', async () => {
    const f = fakes();
    fs.mkdirSync(path.join(f.vt, 'pc_daemon'));
    fs.writeFileSync(path.join(f.vt, 'pc_daemon', 'ran.txt'), `2026-11-23T13:00:00Z ${SHA} lb_1777 PR7 start C:\\vt\\lb_1777\\out_1\r\n`);
    assert.deepEqual(await f.daemon.tick(), []); assert.deepEqual(f.calls, []);
    assert.match(fs.readFileSync(path.join(f.vt, 'pc_daemon', 'hold.txt'), 'utf8'), /stopped in the middle of lb_1777 \(PR 7\)/);
    // a start followed by its own end line is not interrupted, and the dry run never sets a hold
    const ok = fakes();
    fs.mkdirSync(path.join(ok.vt, 'pc_daemon'));
    fs.writeFileSync(path.join(ok.vt, 'pc_daemon', 'ran.txt'), `t ${OLD} lb_1777 PR7 start A1\r\nt ${OLD} lb_1777 PR7 aborted A1\r\n`);
    assert.equal((await ok.daemon.tick())[0].verdict, 'run');
    // the Board's clearance of that attempt lets the next look go on (Astra run 3, item H)
    fs.unlinkSync(path.join(f.vt, 'pc_daemon', 'hold.txt'));
    f.daemon.note(SHA, 'lb_1777', 7, 'cleared', 'C:\\vt\\lb_1777\\out_1');
    assert.equal((await f.daemon.tick())[0].verdict, 'run'); assert.ok(f.calls.includes('watchdog'));
    if (process.platform !== 'win32') {
      const c = fakes(), a2 = path.join(c.vt, 'lb_1777', 'out_9');
      fs.mkdirSync(path.join(c.vt, 'pc_daemon'));
      fs.writeFileSync(path.join(c.vt, 'pc_daemon', 'ran.txt'), `t ${SHA} lb_1777 PR7 start ${a2}\r\n`);
      const log = console.log; console.log = () => {};
      try { assert.equal(d.clearMain(a2), 0); assert.equal(d.clearMain(a2), 2, 'only an interrupted attempt'); } finally { console.log = log; }
      assert.deepEqual(c.daemon.interrupted(), []);
    }
    const dry = fakes(); dry.daemon.live = false;
    fs.mkdirSync(path.join(dry.vt, 'pc_daemon'));
    fs.writeFileSync(path.join(dry.vt, 'pc_daemon', 'ran.txt'), `t ${SHA} lb_1777 PR7 start A1\r\n`);
    await dry.daemon.tick(); assert.ok(!fs.existsSync(path.join(dry.vt, 'pc_daemon', 'hold.txt')));
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
    // an unreadable pause file (here a folder in its place) holds too, at the look and at the last-moment recheck
    const u = fakes();
    fs.mkdirSync(path.join(u.vt, 'gpu_go.txt'));
    assert.deepEqual(await u.daemon.tick(), []); assert.deepEqual(u.calls, []);
    assert.match(u.daemon.recheck(7, d.parseGo(goText())), /Board pause/);
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
  // ------------------------------------------------------------------------- Windows: the real adapter and watchdog
  // Astra run 2, item 10: PcTools.watchdog through the real run_timeout.ps1 (copied from this checkout into a temporary
  // tools_live), with a Node stand-in for the job. Its own child outlives it by three seconds: the step must not end
  // before that child does. It also checks the arguments the child received, the throwaway profile inside the slot's
  // scratch folder (Blender's user folders too) and its removal, and the launch gate. Everything is under a new TEMP
  // folder; PC_RUNNER_TEST keeps the watchdog's log, GPU root and pause file there too.
  if (process.platform === 'win32') {
    await t('Windows: the real watchdog waits for the whole tree, keeps the arguments and the profile in the slot', async () => {
      const vt = tmp(), pc = path.join(vt, 'tools_live', 'v1', 'pc'), src = path.join(__dirname, '..');
      fs.mkdirSync(path.join(pc, 'jobs'), { recursive: true });
      fs.copyFileSync(path.join(src, 'run_timeout.ps1'), path.join(pc, 'run_timeout.ps1'));
      fs.copyFileSync(path.join(src, 'gpu_slots.js'), path.join(pc, 'gpu_slots.js'));
      fs.copyFileSync(path.join(src, 'jobs', 'opus_job_head.ps1'), path.join(pc, 'jobs', 'opus_job_head.ps1'));
      for (const f of ['relay_push.ps1', 'runner_common.ps1']) fs.writeFileSync(path.join(pc, f), '');
      fs.writeFileSync(path.join(vt, 'tools_live', 'current.txt'), 'v1\r\n');
      const attempt = path.join(vt, 'job', 'out_1'), outDir = path.join(attempt, 'out_job'); fs.mkdirSync(outDir, { recursive: true });
      // a real slot lease: the head's own holder process, owned by this test process, holding slot_cpu's lease file
      const slotDir = path.join(vt, 'slots', 'slot_cpu'); fs.mkdirSync(path.join(slotDir, 'repo'), { recursive: true });
      const token = require('crypto').randomBytes(16).toString('hex');
      const ticks = require('child_process').execFileSync('powershell.exe', ['-NoProfile', '-Command', `(Get-Process -Id ${process.pid}).StartTime.ToUniversalTime().Ticks`], { encoding: 'utf8' }).trim();
      const holder = spawn('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(pc, 'jobs', 'opus_job_head.ps1'), 'slothold'],
        { stdio: 'ignore', windowsHide: true, env: { ...process.env, PC_TEST_HELPER: '1', PC_TEST_HELPER_VT: vt, OJ_SLOT_DIR: slotDir, OJ_SLOT_TOKEN: token,
          OJ_SLOT_OWNER: String(process.pid), OJ_SLOT_OWNER_START: ticks, OJ_SLOT_ATTEMPT: attempt } });
      const holderExit = new Promise(r => holder.once('exit', r));
      const ready = path.join(slotDir, `holder_${token}.txt`);
      for (let i = 0; i < 600 && !(fs.existsSync(ready) && /^held /.test(fs.readFileSync(ready, 'utf8'))); i++) await new Promise(r => setTimeout(r, 100));
      fs.writeFileSync(path.join(attempt, 'slot.txt'), `${slotDir}|${token}\r\n`);
      const later = path.join(vt, 'grandchild_done.txt');
      const standin = path.join(vt, 'standin.js');
      fs.writeFileSync(standin, `const fs = require('fs'), { spawn } = require('child_process');
const e = process.env;
fs.writeFileSync(${JSON.stringify(path.join(outDir, 'seen.json'))}, JSON.stringify({ argv: process.argv.slice(2), appdata: e.APPDATA, local: e.LOCALAPPDATA, blender: e.BLENDER_USER_CONFIG, record: e.PC_STEP_RECORD || '' }));
spawn(process.execPath, ['-e', 'setTimeout(() => require("fs").writeFileSync(' + JSON.stringify(${JSON.stringify(later)}) + ', "x"), 3000)'], { detached: true, stdio: 'ignore' }).unref();
`);
      const gateOk = path.join(vt, 'gate_ok.js'), gateNo = path.join(vt, 'gate_no.js');
      fs.writeFileSync(gateOk, 'console.log("go: test")');
      fs.writeFileSync(gateNo, 'console.log("not started: test gate"); process.exit(3)');
      const tools = new d.PcTools({ vt, testEnv: { PC_RUNNER_TEST: '1', PC_TEST_TIMEOUT_LOG: path.join(vt, 'timeouts.log'),
        PC_TEST_GPU_ROOT: path.join(vt, 'gpu'), PC_CLEANUP_PAUSE_FILE: path.join(vt, 'no_pause.txt'), PC_TEST_HELPER: '1', PC_TEST_HELPER_VT: vt } });
      const lease = tools.slotLease(attempt, path.join(slotDir, 'repo'), 'cpu'); // the head's live proof, not saved files
      const flight = tools.inFlight(lease, attempt), scratch = flight.scratch;
      const spaced = path.join(vt, 'a dir') + '\\';
      const args = [standin, spaced, '--next', 'plain'];
      const run = (record, gateJs) => tools.watchdog({ exe: process.execPath, args, cwd: vt, env: { ...process.env }, ceilingS: 120, stallMin: 5,
        outDir, label: 'pcd_selftest', gpu: 'auto', logFile: path.join(vt, 'run_log.txt'), record, scratch, gateJs, gateArg: 'x' });
      const r1 = await run(path.join(vt, 'rec1.json'), gateOk);
      const rec1 = d.readRecord(path.join(vt, 'rec1.json'));
      assert.equal(r1.code, 0, r1.output);
      assert.ok(fs.existsSync(later), 'the step ended only after the stand-in\'s own child had ended');
      assert.equal(rec1.treeEmpty, true); assert.equal(rec1.started, true);
      const seen = JSON.parse(fs.readFileSync(path.join(outDir, 'seen.json'), 'utf8'));
      assert.deepEqual(seen.argv, [spaced, '--next', 'plain'], 'a trailing backslash keeps its argument apart');
      assert.equal(seen.record, '', 'the step settings never reach the job');
      assert.ok(rec1.profile && seen.appdata.toLowerCase() === rec1.profile.toLowerCase() && seen.local.toLowerCase() === rec1.profile.toLowerCase(), 'the throwaway profile');
      assert.ok(seen.blender && seen.blender.toLowerCase().startsWith(rec1.profile.toLowerCase()), 'Blender\'s user folders are in it too');
      assert.ok(rec1.profile.toLowerCase().startsWith(scratch.toLowerCase() + '\\'), 'inside the slot, not TEMP');
      assert.equal(rec1.profileRemoved, true); assert.ok(!fs.existsSync(rec1.profile));
      assert.deepEqual(fs.readdirSync(scratch), [], 'the profile, its run folder and the child logs are all gone');
      assert.equal(d.readWatchdog(r1, rec1, scratch).ok, true);
      // the lease is still live after the descendant ended, so the marker comes off under the head's proof
      tools.clearInFlight(flight); assert.ok(!fs.existsSync(flight.marker));
      fs.unlinkSync(path.join(outDir, 'seen.json'));
      const r2 = await run(path.join(vt, 'rec2.json'), gateNo);
      const rec2 = d.readRecord(path.join(vt, 'rec2.json'));
      assert.equal(r2.code, 125); assert.equal(rec2.started, false); assert.match(rec2.gated, /not started: test gate/);
      assert.ok(!fs.existsSync(path.join(outDir, 'seen.json')), 'the gate stopped the start');
      assert.match(d.readWatchdog(r2, rec2, scratch).gated, /test gate/);
      // once the lease is let go, nothing proves it held: no marker removal
      const f3 = tools.inFlight(lease, attempt);
      fs.writeFileSync(path.join(slotDir, `release_${token}`), 'release\r\n');
      await holderExit;
      assert.throws(() => tools.clearInFlight(f3), /slotcheck failed|does not prove/);
      assert.ok(fs.existsSync(f3.marker), 'kept for the Board');
    });
  }
  console.log(`PASS: pc_daemon ${passed} checks (go comment, gate, step runner, watchdog contract, lease, paths, daemon order, recheck, failures, quarantine, delivery, commands, gh calls)`);
})().catch(e => { console.error('FAIL: ' + (e.stack || e.message)); process.exit(1); });
