'use strict';
// Issue 687: actual Windows .bat runs against tiny local Git fixtures and stub agents.
// Issue 722 extends it: the resolved-model stamp, the free-space floor and the Board hashes check (audit 706
// findings 6 and 7), all in test mode through the same entry points.
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
  for (const step of ['init', 'wait', 'announce', 'checkout', 'preflight', 'finish']) assert(bat.includes('%COMMON% ' + step + ' '), name + ' missing ' + step);
  assert(bat.indexOf('%COMMON% announce ') < bat.indexOf('%COMMON% checkout '), name + ' must claim before checkout');
  for (const step of ['space', 'hashcheck', 'model']) assert(bat.includes('%COMMON% ' + step + ' '), name + ' missing issue 722 step ' + step);
  assert(!/git clone .*https:|git clean -fd/.test(bat), name + ' bypasses safe checkout');
  assert(read(path.join(here, name + '.ps1')).includes('$resume'), name + ' missing task resume note');
}
assert(read(path.join(here, 'chain_issue.bat')).includes('set "PC_WAIT_FOR=%~1"'));
assert(read(path.join(here, 'work_issue.bat')).includes('min_free_gb=60'), 'work_issue.bat must seed the min_free_gb floor in runner_settings.txt');
assert(read(path.join(here, 'runner_common.ps1')).includes('PC_TEST_SPACE_FREE_MB') && read(path.join(here, 'runner_common.ps1')).includes('PC_TEST_HASHES'), 'runner_common.ps1 must carry the 722 test knobs');
// The Git helper must call the program, never its own name: PowerShell resolves functions first, so $exe = 'git' recursed
// until the call depth overflowed on the first live run (Nov 15) while the test stub path passed.
// Log must never throw when result.txt is held open by the calling .bat's redirect (Nov 15, Kimi 371's push stopped).
assert(/function Log\(\$line\) \{\s*try \{ Add-Content[^\n]*-ErrorAction Stop \} catch \{ \}/.test(read(path.join(here, 'runner_common.ps1'))), 'runner_common Log must not throw on a locked result.txt');
assert(/\$exe = 'git\.exe'/.test(read(path.join(here, 'runner_common.ps1'))) && !/\$exe = 'git'[;\s]/.test(read(path.join(here, 'runner_common.ps1'))), 'runner_common Git helper must run git.exe');
pass('shared runner contract, chain launcher and issue 722 start checks');
if (process.platform !== 'win32') {
  console.log('SKIP Windows fault matrix: run tools/pc/runner_selftest.bat on the PC');
  process.exit(0);
}
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'runner687 proof '));
const gh = require('./runner_claim_fixture')(root);
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
function fixtureCommit(files, parent, note = '') {
  return object('commit', 'tree ' + tree(files) + '\n' + (parent ? 'parent ' + parent + '\n' : '') +
    'author Runner fixture <fixture@example.invalid> 1700000000 +0000\ncommitter Runner fixture <fixture@example.invalid> 1700000000 +0000\n\nTest fixture\n' + note);
}
const base = fixtureCommit({ 'progress.txt': 'base\n' });
const partial = fixtureCommit({ 'progress.txt': 'from partial\n' }, base,
  '\n## Runner resume note (issue 818)\nStop reason: STALLED after 30 min\nChanged files: progress.txt\nLast log lines: saved work before stopping\n## End runner resume note\n');
const conflicting = fixtureCommit({ 'progress.txt': 'conflicting main\n' }, base);
write(path.join(source, 'HEAD'), 'ref: refs/heads/main\n');
write(path.join(source, 'refs/heads/main'), base + '\n');
const arms = ['opus', 'sonnet', 'deepseek', 'kimi', 'kimicode', 'codex'];
for (const arm of arms) write(path.join(source, 'refs/heads', (arm === 'codex' ? 'codex/issue-687' : 'work/issue-687-' + arm) + '-partial'), partial + '\n');
const agent = path.join(root, 'stub agent.bat');
const gitStub = path.join(root, 'stub git.bat');
write(agent, '@echo off\r\n"' + process.execPath + '" "' + path.join(root, 'agent.js') + '" %*\r\nexit /b %ERRORLEVEL%\r\n');
write(path.join(root, 'agent.js'), `
const fs = require('fs'), path = require('path');
const a = process.argv.slice(2), probe = a.some(s => s.includes('Reply with exactly RUNNER_READY.'));
const db = JSON.parse(fs.readFileSync(process.env.PC_TEST_GH_DB, 'utf8'));
if (!db.running || !db.comments.some(c => c.body.includes('Runner status: running') && c.body.includes('- Run: '))) process.exit(34);
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
  if (fs.readFileSync(task,'utf8').includes('OLD BRIEF MUST NOT REACH AGENT')) process.exit(35);
  if (!fs.readFileSync(task,'utf8').includes('Resumed by merging')) process.exit(31);
  if (!fs.readFileSync(task,'utf8').includes('saved work before stopping')) process.exit(33);
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
  PC_RUNNER_TEST: '1', PC_TEST_SOURCE: source, PC_TEST_MIRROR: mirror,
  PC_TEST_PREFLIGHT: agent, PC_TEST_GIT: gitStub, PC_REAL_GIT: gitPath, PC_TEST_RETRY_SECONDS: '0',
  PC_TEST_STOP_BEFORE_PUBLISH: '1', WORK_TEST_AGENT: agent, CODEX_TEST_AGENT: agent, WORK_SKIP_CHECKS: '1',
  PC_WAIT_FOR: '', PC_WAIT_RUN: '', PC_WAIT_SECONDS: '2', STUB_GIT_FAULT: '', STUB_AUTH_FAIL: '',
  STUB_PROBE_TIMEOUT: '', STUB_FETCH_HOLD: '',
  // Issue 722: about 68 GB fake free space, above the 60 GB floor, so fixture runs pass the space check on any host;
  // the dedicated floor tests force 100 MB instead. Settings and hashes fixtures stay unset unless a test names them.
  PC_TEST_SPACE_FREE_MB: '70000', PC_TEST_SETTINGS: '', PC_TEST_HASHES: '',
  PC_TEST_GH: gh.fake, PC_TEST_GH_FAIL: '', PC_TEST_GH_HOLD: '',
  GIT_AUTHOR_NAME: 'Fixture', GIT_AUTHOR_EMAIL: 'fixture@example.invalid', GIT_COMMITTER_NAME: 'Fixture', GIT_COMMITTER_EMAIL: 'fixture@example.invalid'
};
function job(arm, label, extra = {}) {
  const home = path.join(root, arm + '-' + label); fs.mkdirSync(home, { recursive: true });
  const env = { ...defaults, WORK_ROOT: home, CODEX_TEST_ROOT: home, PC_TEST_TRACE: path.join(home, 'probe_args.txt'), PC_TEST_COUNTER: path.join(home, 'tries'),
    PC_TEST_GH_DB: path.join(home, 'gh-db.json'), PC_TEST_GH_TRACE: path.join(home, 'gh.jsonl'), ...extra };
  if (!fs.existsSync(env.PC_TEST_GH_DB)) {
    const db = gh.database(687, base);
    if (label === 'closed') db.issue.state = 'closed';
    if (label === 'claimed') db.running = true;
    if (label === 'other-pr') db.pulls = [{ number: 700, head: { ref: 'opus/issue-687' } }];
    if (label === 'no-current') db.issue.body = db.issue.body.replace('## THIS IS THE JOB NOW', '## Old job');
    if (label === 'two-current') db.issue.body += '\n## Run 2 THIS IS THE JOB NOW\nAnother job.\n';
    write(env.PC_TEST_GH_DB, JSON.stringify(db)); write(env.PC_TEST_GH_TRACE, '');
  }
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
  for (const arm of ['codex', 'deepseek', 'kimi', 'kimicode']) {
    for (const [scenario, reason] of [['closed', 'not an open job'], ['claimed', 'already carries running'],
      ['other-pr', 'open PR #700'], ['no-current', 'found 0'], ['two-current', 'found 2']]) {
      const r = job(arm, scenario);
      assert.equal(r.code, 14, r.text + '\n' + r.result);
      assert.equal(r.state.status, 'failed'); assert(r.result.includes(reason), r.result);
      assert(!fs.existsSync(r.repo), 'refusal before checkout');
      assert(!fs.existsSync(r.env.PC_TEST_TRACE), 'refusal before model probe');
      const calls = read(r.env.PC_TEST_GH_TRACE).trim().split(/\r?\n/).filter(Boolean).map(l => JSON.parse(l));
      assert(calls.every(c => c.method === 'GET'), 'refusal cannot change another claim');
      assert.equal(JSON.parse(read(r.env.PC_TEST_GH_DB)).running, scenario === 'claimed');
      pass(arm + ': ' + scenario + ' refuses before checkout, probe or agent, with no GitHub writes');
    }
  }
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
    const expectModel = arm === 'codex' ? 'gpt-6.1-sol' : arm === 'kimicode' ? 'kimi-code/kimi-for-coding' : arm === 'kimi' ? 'moonshotai/kimi-k3.1-pro' : arm === 'opus' ? 'anthropic/claude-opus-5-5' : arm === 'sonnet' ? 'anthropic/claude-sonnet-5-5' : 'deepseek/deepseek-flash';
    assert(r.result.includes('model: ' + expectModel), r.result);
    assert.equal(r.state.model, expectModel);
    assert(!r.result.includes('differs from the arm default'), r.result);
    assert(!JSON.parse(read(r.env.PC_TEST_GH_DB)).running, 'finished run releases its claim');
    pass(arm + ': claim before probe and agent, only current brief, partial resumed, model stamped, claim released, no publish');
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
  // ---- Issue 722 (audit 706 findings 6 and 7): model stamp, free-space floor, Board hashes ----
  // The stamp warns when the resolved model differs from the arm default, whatever the provider: a same-provider
  // WORK_MODEL override passes the provider guard silently, so the warning must come from the stamp itself.
  const overridden = job('deepseek', 'model-override', { WORK_MODEL: 'deepseek/deepseek-v4-pro' });
  assert.equal(overridden.code, 0, overridden.text + '\n' + overridden.result);
  assert(overridden.result.includes('model: deepseek/deepseek-v4-pro'), overridden.result);
  assert(overridden.result.includes('WARNING: resolved model deepseek/deepseek-v4-pro differs from the arm default deepseek/deepseek-flash'), overridden.result);
  assert.equal(overridden.state.model, 'deepseek/deepseek-v4-pro');
  pass('resolved model stamp warns when a same-provider override changes the model');
  const modelOut = path.join(root, 'modelstamp'); fs.mkdirSync(modelOut); write(path.join(modelOut, 'result.txt'), '');
  assert.equal(ps(['init', modelOut, 'fixture/model'], defaults).code, 0);
  assert.equal(ps(['model', modelOut, 'provider/x', 'provider/y'], defaults).code, 0);
  const modelResult = read(path.join(modelOut, 'result.txt'));
  assert(modelResult.includes('model: provider/x') && modelResult.includes('WARNING: resolved model provider/x differs from the arm default provider/y'), modelResult);
  assert.equal(JSON.parse(read(path.join(modelOut, 'status.json'))).model, 'provider/x');
  pass('model mode stamps status.json and result.txt and warns on any difference');
  // Below the floor the run refuses to start: one line in result.txt, status failed. min_free_gb is a tuning value
  // in runner_settings.txt; a missing line or file keeps the 60 default.
  const setFix = path.join(root, 'space_settings.txt'); write(setFix, 'remove_repo_copy_after_push=no\nmin_free_gb=60\n');
  const spaceOut = path.join(root, 'spacefloor'); fs.mkdirSync(spaceOut); write(path.join(spaceOut, 'result.txt'), '');
  assert.equal(ps(['init', spaceOut, 'fixture/space'], defaults).code, 0);
  const low = ps(['space', spaceOut, setFix, path.join(root, 'voidsworn_test')], { ...defaults, PC_TEST_SPACE_FREE_MB: '100' });
  assert.equal(low.code, 14, low.text);
  assert.equal(JSON.parse(read(path.join(spaceOut, 'status.json'))).status, 'failed');
  const lowResult = read(path.join(spaceOut, 'result.txt'));
  assert(lowResult.includes('refusing to start') && lowResult.includes('below the min_free_gb=60 floor'), lowResult);
  assert.equal(ps(['space', spaceOut, setFix, path.join(root, 'voidsworn_test')], { ...defaults, PC_TEST_SPACE_FREE_MB: '70000' }).code, 0);
  write(path.join(root, 'space_settings_low.txt'), 'min_free_gb=1\n');
  assert.equal(ps(['space', spaceOut, path.join(root, 'space_settings_low.txt'), path.join(root, 'voidsworn_test')], { ...defaults, PC_TEST_SPACE_FREE_MB: '2000' }).code, 0);
  assert.equal(ps(['space', spaceOut, path.join(root, 'missing_settings.txt'), path.join(root, 'voidsworn_test')], { ...defaults, PC_TEST_SPACE_FREE_MB: '100' }).code, 14);
  pass('free-space floor refuses below min_free_gb, honors the tuning value, defaults to 60');
  const noStart = job('deepseek', 'nofreespace', { PC_TEST_SPACE_FREE_MB: '100' });
  assert.equal(noStart.code, 14, noStart.text + '\n' + noStart.result);
  assert.equal(noStart.state.status, 'failed');
  assert(noStart.result.includes('refusing to start: drive'), noStart.result);
  assert(!fs.existsSync(noStart.env.PC_TEST_TRACE));
  assert(!fs.existsSync(noStart.repo));
  pass('a low-disk run stops before the mirror, the model probe and the agent');
  // The Board writes work217\runner_hashes.txt with hashwrite after copying the runner and watchdog files; hashcheck then
  // guards the running copies. A mismatch or a missing file is a warning, never a stop.
  const runnerFiles = ['codex_issue.bat', 'codex_issue.ps1', 'runner_common.ps1', 'work_issue.bat', 'work_issue.ps1', 'run_timeout.ps1', 'tmo.bat', 'gpu_slots.js'];
  const hashesGood = path.join(root, 'board_hashes_good.txt');
  write(hashesGood, runnerFiles.map(n => crypto.createHash('sha256').update(fs.readFileSync(path.join(here, n))).digest('hex') + '  ' + n).join('\n') + '\n');
  const hashOut = path.join(root, 'hashcheck'); fs.mkdirSync(hashOut); write(path.join(hashOut, 'result.txt'), '');
  assert.equal(ps(['init', hashOut, 'fixture/hash'], defaults).code, 0);
  const hashesWritten = path.join(root, 'board_hashes_written.txt');
  assert.equal(ps(['hashwrite', here, hashesWritten], defaults).code, 0);
  assert.equal(read(hashesWritten), read(hashesGood));
  assert.equal(ps(['hashcheck', hashOut, here, hashesGood], defaults).code, 0);
  assert(read(path.join(hashOut, 'result.txt')).includes(`runner files match the Board hashes (${runnerFiles.length} checked)`));
  pass('hashwrite and hashcheck agree on the runner and watchdog files');
  const hashesBad = path.join(root, 'board_hashes_bad.txt');
  write(hashesBad, read(hashesGood).split('\n').map(l => l.endsWith('runner_common.ps1') ? '0'.repeat(64) + '  runner_common.ps1' : l).join('\n'));
  assert.equal(ps(['hashcheck', hashOut, here, hashesBad], defaults).code, 0);
  assert(read(path.join(hashOut, 'result.txt')).includes('WARNING: these runner files differ from the Board-copied hashes: runner_common.ps1'));
  assert.equal(ps(['hashcheck', hashOut, here, path.join(root, 'no_such_hashes.txt')], defaults).code, 0);
  assert(read(path.join(hashOut, 'result.txt')).includes('WARNING: no Board hashes file'));
  pass('a hash mismatch and a missing hashes file warn without stopping');
  const hashWarn = job('deepseek', 'hashwarn', { PC_TEST_HASHES: hashesBad });
  assert.equal(hashWarn.code, 0, hashWarn.text + '\n' + hashWarn.result);
  assert(fs.existsSync(path.join(hashWarn.repo, 'agent_started.txt')));
  assert(hashWarn.result.includes('WARNING: these runner files differ'), hashWarn.result);
  pass('a run whose tools folder drifts from the Board hashes still starts and warns');
  const note = 'PASS runner687+722: ' + passed + ' checks, Windows entry points, local Git and stub agents only. No commits, pushes or model usage.\nEvidence: ' + root + '\n';
  write(path.join(root, 'summary.txt'), note); console.log(note.trim());
} catch (e) { write(path.join(root, 'failure.txt'), e.stack); console.error('FAIL runner687: ' + e.stack + '\nEvidence: ' + root); process.exitCode = 1; } })();
