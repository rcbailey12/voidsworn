'use strict';
// Issue 687: actual Windows .bat runs against tiny local Git fixtures and stub agents.
// Fixture objects are test data written directly to TEMP. No git commit or push is run.
const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');
const zlib = require('zlib');
const { spawnSync, spawn } = require('child_process');
const assert = require('assert');
const here = __dirname;
const read = p => fs.readFileSync(p, 'utf8');
const write = (p, s) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, s); };
let passed = 0;
function pass(s) { passed++; console.log('PASS ' + s); }
// Run on every CI host: both entry points must use all five shared steps, and the task must carry resume context.
for (const name of ['work_issue', 'codex_issue']) {
  const bat = read(path.join(here, name + '.bat'));
  for (const step of ['init', 'wait', 'checkout', 'preflight', 'finish']) assert(bat.includes('%COMMON% ' + step + ' '), name + ' missing ' + step);
  assert(!/git clone .*https:|git clean -fd/.test(bat), name + ' bypasses safe checkout');
  assert(read(path.join(here, name + '.ps1')).includes('$resume'), name + ' missing task resume note');
}
assert(read(path.join(here, 'chain_issue.bat')).includes('set "PC_WAIT_FOR=%~1"'));
pass('shared runner contract and chain launcher');
if (process.platform !== 'win32') {
  console.log('SKIP Windows fault matrix: run tools/pc/runner_selftest.bat on the PC');
  process.exit(0);
}
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'runner687 proof '));
console.log('Evidence: ' + root);
function run(exe, args, env = {}, cwd = root) {
  const p = spawnSync(exe, args, { cwd, env: { ...process.env, ...env }, encoding: 'utf8', windowsHide: true, windowsVerbatimArguments: /cmd\.exe$/i.test(exe), timeout: 90000 });
  if (p.error) throw p.error;
  return { code: p.status, text: (p.stdout || '') + (p.stderr || '') };
}
const ps = (args, env) => run('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(here, 'runner_common.ps1'), ...args], env);
const source = path.join(root, 'upstream.git');
assert.equal(run('git', ['init', '--bare', '-q', source]).code, 0);
function object(type, value) {
  const b = Buffer.isBuffer(value) ? value : Buffer.from(value);
  const raw = Buffer.concat([Buffer.from(type + ' ' + b.length + '\0'), b]);
  const id = crypto.createHash('sha1').update(raw).digest('hex');
  write(path.join(source, 'objects', id.slice(0, 2), id.slice(2)), zlib.deflateSync(raw));
  return id;
}
function tree(files) {
  return object('tree', Buffer.concat(Object.entries(files).sort(([a], [b]) => a.localeCompare(b)).map(([name, value]) =>
    Buffer.concat([Buffer.from('100644 ' + name + '\0'), Buffer.from(object('blob', value), 'hex')]))));
}
function fixtureCommit(files, parent) {
  return object('commit', 'tree ' + tree(files) + '\n' + (parent ? 'parent ' + parent + '\n' : '') +
    'author Runner fixture <fixture@example.invalid> 1700000000 +0000\ncommitter Runner fixture <fixture@example.invalid> 1700000000 +0000\n\nTest fixture\n');
}
const base = fixtureCommit({ 'progress.txt': 'base\n' });
const partial = fixtureCommit({ 'progress.txt': 'from partial\n' }, base);
const conflicting = fixtureCommit({ 'progress.txt': 'conflicting main\n' }, base);
write(path.join(source, 'HEAD'), 'ref: refs/heads/main\n');
write(path.join(source, 'refs/heads/main'), base + '\n');
const arms = ['opus', 'sonnet', 'deepseek', 'kimicode', 'codex'];
for (const arm of arms) write(path.join(source, 'refs/heads', (arm === 'codex' ? 'codex/issue-687' : 'work/issue-687-' + arm) + '-partial'), partial + '\n');
const issue = path.join(root, 'issue.json');
write(issue, JSON.stringify({ title: 'Stub runner job', body: 'Owner: codex\nDeliver to: tools/pc/\nEffort (Codex): high\nDone when: stub finishes' }));
const agent = path.join(root, 'stub agent.bat');
const gitStub = path.join(root, 'stub git.bat');
write(agent, '@echo off\r\n"' + process.execPath + '" "' + path.join(root, 'agent.js') + '" %*\r\nexit /b %ERRORLEVEL%\r\n');
write(path.join(root, 'agent.js'), `
const fs = require('fs'), path = require('path');
const a = process.argv.slice(2), probe = a.some(s => s.includes('Reply with exactly RUNNER_READY.'));
if (probe) {
  fs.appendFileSync(process.env.PC_TEST_TRACE, JSON.stringify(a) + '\\n');
  if (process.env.STUB_AUTH_FAIL === '1') {
    console.log(JSON.stringify({type:'error',error:{message:process.env.STUB_REASON}})); process.exit(0);
  }
  if (process.env.STUB_PROBE_TIMEOUT === '1') Atomics.wait(new Int32Array(new SharedArrayBuffer(4)),0,0,5000);
  if (a[0] === 'run') console.log(JSON.stringify({type:'text',part:{text:'RUNNER_READY'}}));
  else if (a[0] === 'exec') { fs.writeFileSync(a[a.indexOf('-o') + 1], 'RUNNER_READY'); console.log('stub codex'); }
  else console.log('RUNNER_READY');
} else {
  const task = fs.existsSync('CODEX_TASK.md') ? 'CODEX_TASK.md' : 'WORK_TASK.md';
  if (!fs.readFileSync(task,'utf8').includes('Resumed by merging')) process.exit(31);
  if (fs.readFileSync('progress.txt','utf8') !== 'from partial\\n') process.exit(32);
  fs.writeFileSync('agent_started.txt', 'resumed work verified');
  console.log(JSON.stringify({type:'text',part:{text:'Stub completed from partial'}}));
}
`);
write(gitStub, '@echo off\r\n"' + process.execPath + '" "' + path.join(root, 'git.js') + '" %*\r\nexit /b %ERRORLEVEL%\r\n');
write(path.join(root, 'git.js'), `
const fs = require('fs'), path = require('path'), cp = require('child_process');
const a = process.argv.slice(2), mode = process.env.STUB_GIT_FAULT || '';
const op = a.includes('fetch') ? 'fetch' : a[0] === 'clone' ? 'clone' : '';
if (op === 'fetch' && process.env.STUB_FETCH_HOLD === '1') Atomics.wait(new Int32Array(new SharedArrayBuffer(4)),0,0,800);
if (op && mode.startsWith(op)) {
  const counter = process.env.PC_TEST_COUNTER + '-' + op;
  const n = fs.existsSync(counter) ? Number(fs.readFileSync(counter,'utf8')) + 1 : 1;
  fs.writeFileSync(counter,String(n));
  if (mode.endsWith('dead') || n <= 2) {
    if (op === 'clone') { fs.mkdirSync(a[a.length-1],{recursive:true}); fs.writeFileSync(path.join(a[a.length-1],'keep.txt'),'failed clone evidence'); }
    console.error('stub network drop'); process.exit(55);
  }
}
const p = cp.spawnSync(process.env.PC_REAL_GIT,a,{stdio:'inherit',windowsHide:true}); process.exit(p.status ?? 99);
`);
const gitPath = run('where.exe', ['git.exe']).text.trim().split(/\r?\n/)[0];
const mirror = path.join(root, 'shared mirror.git');
const defaults = {
  PC_RUNNER_TEST: '1', PC_TEST_SOURCE: source, PC_TEST_MIRROR: mirror, PC_TEST_ISSUE: issue,
  PC_TEST_PREFLIGHT: agent, PC_TEST_GIT: gitStub, PC_REAL_GIT: gitPath, PC_TEST_RETRY_SECONDS: '0',
  PC_TEST_STOP_BEFORE_PUBLISH: '1', WORK_TEST_AGENT: agent, CODEX_TEST_AGENT: agent, WORK_SKIP_CHECKS: '1',
  PC_WAIT_FOR: '', PC_WAIT_RUN: '', PC_WAIT_SECONDS: '2', STUB_GIT_FAULT: '', STUB_AUTH_FAIL: '',
  STUB_PROBE_TIMEOUT: '', STUB_FETCH_HOLD: '',
  GIT_AUTHOR_NAME: 'Fixture', GIT_AUTHOR_EMAIL: 'fixture@example.invalid', GIT_COMMITTER_NAME: 'Fixture', GIT_COMMITTER_EMAIL: 'fixture@example.invalid'
};
function job(arm, label, extra = {}) {
  const home = path.join(root, arm + '-' + label); fs.mkdirSync(home, { recursive: true });
  const env = { ...defaults, WORK_ROOT: home, CODEX_TEST_ROOT: home, PC_TEST_TRACE: path.join(home, 'probe_args.txt'), PC_TEST_COUNTER: path.join(home, 'tries'), ...extra };
  const bat = path.join(here, arm === 'codex' ? 'codex_issue.bat' : 'work_issue.bat');
  const cmd = '""' + bat + '" 687' + (arm === 'codex' ? '' : ' ' + arm + ' dryrun') + '"';
  const r = run(process.env.COMSPEC, ['/d', '/s', '/c', cmd], env);
  write(path.join(home, 'console.txt'), r.text);
  assert(fs.existsSync(path.join(home, arm === 'codex' ? 'issue-687/status.json' : 'dryrun-687-' + arm + '/latest.txt')), r.text);
  const runHome = arm === 'codex' ? home : read(path.join(home, 'dryrun-687-' + arm, 'latest.txt')).trim();
  const out = path.join(runHome, arm === 'codex' ? 'issue-687' : 'out');
  const repo = path.join(runHome, 'repo');
  write(path.join(home, 'console.txt'), r.text);
  return { ...r, out, repo, env, result: read(path.join(out, 'result.txt')), state: JSON.parse(read(path.join(out, 'status.json'))) };
}
(async () => { try {
  for (const arm of arms) {
    const r = job(arm, 'resume');
    assert.equal(r.code, 0, r.text + '\n' + r.result);
    assert(fs.existsSync(path.join(r.repo, 'agent_started.txt')), r.result);
    assert(read(path.join(r.out, arm === 'codex' ? 'CODEX_TASK.md' : 'WORK_TASK.md')).includes('Resumed by merging'));
    assert.equal(run('git', ['-C', r.repo, 'remote', 'get-url', 'origin']).text.trim(), source);
    assert(!fs.existsSync(path.join(r.repo, '.git/objects/info/alternates')));
    const probe = JSON.parse(read(r.env.PC_TEST_TRACE).trim());
    assert.equal(probe[0], arm === 'codex' ? 'exec' : arm === 'kimicode' ? '-m' : 'run');
    assert.equal(r.state.status, 'unverified');
    pass(arm + ': local mirror clone, partial merged, task note, correct preflight and stub agent, no publish');
    const why = arm === 'kimicode' ? 'provider managed:kimi-code has no credential configured (expired login)' : arm === 'codex' ? 'quota exhausted' : 'credit balance is too low';
    const bad = job(arm, 'auth', { STUB_AUTH_FAIL: '1', STUB_REASON: why });
    assert.notEqual(bad.code, 0); assert(bad.result.includes(why), bad.result);
    assert(!fs.existsSync(path.join(bad.repo, 'agent_started.txt')));
    assert.equal(bad.state.status, 'failed');
    pass(arm + ': provider error with exit 0 stops before agent and keeps the reason');
    const dead = job(arm, 'fetchdead', { STUB_GIT_FAULT: 'fetch-dead' });
    assert.notEqual(dead.code, 0); assert(dead.result.includes('failed after 3 attempts'), dead.result);
    assert(!fs.existsSync(dead.env.PC_TEST_TRACE));
    assert.equal(read(dead.env.PC_TEST_COUNTER + '-fetch'), '3');
    const stopped = job(arm, 'chain', { PC_WAIT_FOR: path.join(dead.out, 'status.json') });
    assert.notEqual(stopped.code, 0); assert(stopped.result.includes('chain stopped: predecessor ended failed'), stopped.result);
    assert(!fs.existsSync(stopped.repo)); assert(!fs.existsSync(stopped.env.PC_TEST_TRACE));
    pass(arm + ': three failed fetch attempts, then chain stops before clone or model');
  }
  for (const fault of ['fetch-two', 'clone-two', 'clone-dead']) {
    const r = job('deepseek', fault, { STUB_GIT_FAULT: fault });
    assert.equal(r.code, fault === 'clone-dead' ? 14 : 0, r.text + r.result);
    const op = fault.split('-')[0]; assert.equal(read(r.env.PC_TEST_COUNTER + '-' + op), '3');
    if (op === 'clone') assert.equal(fs.readdirSync(path.dirname(r.repo)).filter(n => n.startsWith('repo-clone-failed-')).length, fault === 'clone-dead' ? 3 : 2);
    pass(fault + ': retry count and failed checkout preservation');
  }
  const rerun = job('codex','resume');
  const kept = fs.readdirSync(path.dirname(rerun.repo)).filter(n => n.startsWith('repo-kept-'));
  assert.equal(rerun.code,0); assert.equal(kept.length,1);
  assert(fs.existsSync(path.join(path.dirname(rerun.repo),kept[0],'agent_started.txt')));
  pass('Codex restart keeps the earlier checkout and its untracked work');
  // A conflicting partial stops before preflight and leaves MERGE_HEAD and conflicted files intact.
  write(path.join(source, 'refs/heads/main'), conflicting + '\n');
  const conflict = job('codex', 'conflict');
  assert.notEqual(conflict.code, 0); assert(conflict.result.includes('resume merge failed'));
  assert(fs.existsSync(path.join(conflict.repo, '.git/MERGE_HEAD'))); assert(!fs.existsSync(conflict.env.PC_TEST_TRACE));
  write(path.join(source, 'refs/heads/main'), base + '\n');
  pass('resume conflict keeps the checkout and stops before model use');
  const stateOut = path.join(root, 'states'); fs.mkdirSync(stateOut); write(path.join(stateOut, 'result.txt'), '');
  const consumerOut = path.join(root, 'consumer'); fs.mkdirSync(consumerOut); write(path.join(consumerOut, 'result.txt'), '');
  assert.equal(ps(['init', consumerOut, 'fixture/consumer'], defaults).code, 0);
  for (const [code, partialReason, push, checks, expected] of [
    ['0', '', 'real', '1', 'checked_push'], ['0', '', 'dry', '1', 'unverified'], ['0', '', 'real', '0', 'unverified'],
    ['0', 'agent exit 124', 'real', '1', 'partial'], ['7', '', 'real', '1', 'no_changes'], ['8', '', 'real', '1', 'failed'], ['10', '', 'real', '1', 'failed']
  ]) {
    assert.equal(ps(['init', stateOut, 'fixture/issue-687'], defaults).code, 0);
    write(path.join(stateOut, 'run_commit.txt'), partial);
    write(path.join(stateOut, 'confirmed_commit.txt'), partial);
    assert.equal(ps(['finish', stateOut, code, partialReason, push, checks], defaults).code, 0);
    assert.equal(JSON.parse(read(path.join(stateOut, 'status.json'))).status, expected);
    const wait = ps(['wait', consumerOut], { ...defaults, PC_WAIT_FOR: path.join(stateOut, 'status.json') });
    assert.equal(wait.code, expected === 'checked_push' ? 0 : 14, wait.text);
  }
  pass('only a confirmed non-partial real push with passing checks releases a chain');
  assert.equal(ps(['init', stateOut, 'fixture/issue-687'], defaults).code, 0);
  write(path.join(stateOut, 'run_commit.txt'), partial);
  assert.equal(ps(['finish', stateOut, '0', '', 'real', '1'], defaults).code, 0);
  assert.equal(JSON.parse(read(path.join(stateOut,'status.json'))).status,'unverified');
  pass('a success exit without push confirmation cannot release a chain');
  const missing = ps(['wait', stateOut], { ...defaults, PC_WAIT_FOR: path.join(root, 'old-result.txt') });
  assert.equal(missing.code, 14);
  pass('missing or legacy predecessor status fails closed');
  assert.equal(ps(['init', stateOut, 'fixture/issue-687'], defaults).code, 0);
  assert.equal(ps(['wait', consumerOut], { ...defaults, PC_WAIT_FOR: path.join(stateOut, 'status.json'), PC_WAIT_SECONDS: '1' }).code, 14);
  assert.equal(ps(['wait', consumerOut], { ...defaults, PC_WAIT_FOR: path.join(stateOut, 'status.json'), PC_WAIT_RUN: 'older-run' }).code, 14);
  pass('unfinished predecessor times out; a stale run id stops the chain');
  const slow = job('codex', 'preflight-timeout', { STUB_PROBE_TIMEOUT: '1', PC_TEST_PREFLIGHT_SECONDS: '1' });
  assert.equal(slow.code, 14); assert(slow.result.includes('timed out after 1 seconds')); assert(!fs.existsSync(path.join(slow.repo, 'agent_started.txt')));
  pass('preflight timeout kills the probe tree and stops the job');
  // Hold a real mirror fetch briefly so two simultaneous checkouts contend for the file lock.
  async function concurrentCheckout(n) {
    const home = path.join(root, 'concurrent-' + n); fs.mkdirSync(home); const out = path.join(home, 'out'); fs.mkdirSync(out); write(path.join(out, 'result.txt'), '');
    assert.equal(ps(['init', out, 'fixture/concurrent-' + n], defaults).code, 0);
    const env = { ...process.env, ...defaults, STUB_FETCH_HOLD: '1' };
    const args = ['-NoProfile','-ExecutionPolicy','Bypass','-File',path.join(here,'runner_common.ps1'),'checkout',path.join(home,'repo'),out,'fixture/concurrent-' + n,''];
    return new Promise((resolve, reject) => {
      const p = spawn('powershell.exe', args, { cwd: root, env, windowsHide: true }); let text = '';
      p.stdout.on('data', b => text += b); p.stderr.on('data', b => text += b); p.on('error', reject);
      p.on('close', code => { write(path.join(home,'console.txt'),text); resolve({code,text}); });
    });
  }
  const concurrent = await Promise.all([concurrentCheckout(1), concurrentCheckout(2)]);
  assert(concurrent.every(r => r.code === 0), JSON.stringify(concurrent));
  assert(concurrent.some(r => r.text.includes('waiting for the shared repo copy')), JSON.stringify(concurrent));
  pass('two simultaneous jobs serialize mirror fetch and local clone');
  const confirmationOut = path.join(root,'confirmation'); fs.mkdirSync(confirmationOut); write(path.join(confirmationOut,'result.txt'),'');
  assert.equal(ps(['init',confirmationOut,'fixture/pushed'],defaults).code,0);
  const confirmationRepo = path.join(root,'concurrent-1','repo');
  write(path.join(source,'refs/heads/fixture/pushed'),partial + '\n');
  write(path.join(confirmationOut,'pre_commit.txt'),base); write(path.join(confirmationOut,'run_commit.txt'),partial);
  write(path.join(confirmationOut,'diff_numstat.txt'),run('git',['-C',confirmationRepo,'diff','--numstat','--no-renames',base,partial]).text);
  const confirmed = run('powershell.exe',['-NoProfile','-ExecutionPolicy','Bypass','-File',path.join(here,'work_issue.ps1'),'confirm',confirmationRepo,confirmationOut,'fixture/pushed','real'],defaults);
  assert.equal(confirmed.code,0,confirmed.text); assert.equal(read(path.join(confirmationOut,'confirmed_commit.txt')),partial);
  assert.equal(ps(['finish',confirmationOut,'0','','real','1'],defaults).code,0);
  assert.equal(JSON.parse(read(path.join(confirmationOut,'status.json'))).status,'checked_push');
  pass('real Git remote confirmation writes the marker required for chain success (fixture ref, no push)');
  const note = 'PASS runner687: ' + passed + ' checks, Windows entry points, local Git and stub agents only. No commits, pushes or model usage.\nEvidence: ' + root + '\n';
  write(path.join(root, 'summary.txt'), note); console.log(note.trim());
} catch (e) { write(path.join(root, 'failure.txt'), e.stack); console.error('FAIL runner687: ' + e.stack + '\nEvidence: ' + root); process.exitCode = 1; } })();
