'use strict';
// Issue 687: actual Windows .bat runs against tiny local Git fixtures and stub agents.
// Issue 722 extends it: the resolved-model stamp, the free-space floor and the Board hashes check (audit 706
// findings 6 and 7), all in test mode through the same entry points.
// Fixture objects are test data written directly to TEMP. Accounting fault cases preserve commits to local TEMP remotes only.
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
const started = Date.now();
function pass(s) {
  passed++;
  console.log('PASS ' + s + ' (elapsed ' + ((Date.now() - started) / 1000).toFixed(2) + ' s)');
}
// Run on every CI host: both entry points must use all five shared steps, and the task must carry resume context.
for (const name of ['work_issue', 'codex_issue']) {
  const bat = read(path.join(here, name + '.bat'));
  assert(/setlocal\r?\nset "PYTHONDONTWRITEBYTECODE=1"/.test(bat), name + ' must disable Python bytecode before runner and agent steps');
  for (const step of ['init', 'wait', 'announce', 'checkout', 'preflight', 'finish']) assert(bat.includes('%COMMON% ' + step + ' '), name + ' missing ' + step);
  assert(bat.indexOf('%COMMON% announce ') < bat.indexOf('%COMMON% checkout '), name + ' must claim before checkout');
  for (const step of ['space', 'hashcheck', 'model']) assert(bat.includes('%COMMON% ' + step + ' '), name + ' missing issue 722 step ' + step);
  assert(!/git clone .*https:|git clean -fd/.test(bat), name + ' bypasses safe checkout');
  assert(read(path.join(here, name + '.ps1')).includes('$resume'), name + ' missing task resume note');
}
// Issue 873: the Codex task must forbid workflow edits, because the PC token has no workflow scope and a full run is
// refused at push time. The CI change goes in the report instead.
assert(read(path.join(here, 'codex_issue.ps1')).includes('Never edit anything under .github/workflows'), 'codex_issue.ps1 prompt must forbid .github/workflows edits');
pass('Codex task prompt forbids .github/workflows edits (issue 873)');
assert(read(path.join(here, 'chain_issue.bat')).includes('set "PC_WAIT_FOR=%~1"'));
assert(read(path.join(here, 'work_issue.bat')).includes('min_free_gb=60'), 'work_issue.bat must seed the min_free_gb floor in runner_settings.txt');
assert(read(path.join(here, 'runner_common.ps1')).includes('PC_TEST_SPACE_FREE_MB') && read(path.join(here, 'runner_common.ps1')).includes('PC_TEST_HASHES'), 'runner_common.ps1 must carry the 722 test knobs');
// The Git helper must call the program, never its own name: PowerShell resolves functions first, so $exe = 'git' recursed
// until the call depth overflowed on the first live run (Nov 15) while the test stub path passed.
// Log must never throw when result.txt is held open by the calling .bat's redirect (Nov 15, Kimi 371's push stopped).
assert(/function Log\(\$line\) \{\s*try \{ Add-Content[^\n]*-ErrorAction Stop \} catch \{ \}/.test(read(path.join(here, 'runner_common.ps1'))), 'runner_common Log must not throw on a locked result.txt');
assert(/\$exe = 'git\.exe'/.test(read(path.join(here, 'runner_common.ps1'))) && !/\$exe = 'git'[;\s]/.test(read(path.join(here, 'runner_common.ps1'))), 'runner_common Git helper must run git.exe');
assert(/\$limit = 600\.0/.test(read(path.join(here, 'runner_common.ps1'))), 'checkout preservation must allow ten minutes');
pass('shared runner contract, chain launcher and issue 722 start checks');
// Issue 914: lookup order and logging belong to Invoke-Gh, including the board audit.
const shared = read(path.join(here, 'runner_common.ps1'));
const ghLookup = shared.slice(shared.indexOf('function Invoke-Gh('), shared.indexOf('function Status-Body('));
assert(ghLookup.indexOf('Get-Command $exe') < ghLookup.indexOf("relative = 'GitHub CLI/gh.exe'"));
assert(ghLookup.indexOf("relative = 'GitHub CLI/gh.exe'") < ghLookup.indexOf("relative = 'Programs/GitHub CLI/gh.exe'"));
assert(ghLookup.includes('if (-not $command -and -not $test)'), 'test gh must never fall through to a real install');
assert(ghLookup.includes('Log "GitHub CLI: $exe"'), 'log the selected executable');
assert(ghLookup.includes('GitHub CLI gh is missing; install it and run gh auth login before starting PC jobs'));
pass('GitHub CLI lookup uses PATH, ProgramFiles, then LOCALAPPDATA and keeps the missing-tool refusal');
const workBat = read(path.join(here, 'work_issue.bat'));
const lean = JSON.parse(read(path.join(here, 'work/opencode_lean.json')));
const mock = JSON.parse(read(path.join(here, 'work/opencode_mock.json')));
assert(workBat.includes('"MODEL=openai/gpt-6.1-sol"'));
assert(workBat.includes('if /i "%ARM%"=="openai" set "OPENCODE_CONFIG=%T%work\\opencode_lean.json"'));
assert(workBat.includes('if /i "%ARM%"=="openai" set "OPENCODE_DISABLE_DEFAULT_PLUGINS=1"'));
assert.equal(lean.provider.openai.options.baseURL, 'https://api.openai.com/v1');
assert.equal(lean.provider.openai.options.apiKey, '{env:VOIDSWORN_OPENAI_API_KEY}');
assert.equal(lean.tools.task, false);
assert.equal(mock.provider.openai.options.baseURL, 'http://127.0.0.1:8765/v1');
assert.equal(mock.provider.openai.npm, '@ai-sdk/openai');
assert(mock.provider.openai.models['gpt-6.1-sol']);
assert(!/(?:getkey|setx|set)\s+"?OPENAI_API_KEY\b/i.test(workBat));
const openaiKeyBat = read(path.join(here, 'openai_api_key.bat'));
assert(openaiKeyBat.includes('setx VOIDSWORN_OPENAI_API_KEY "%K%"'));
assert(!/setx\s+OPENAI_API_KEY\b/i.test(openaiKeyBat));
pass('OpenAI arm defaults, isolated key name, lean config and local stand-in config');
assert(!/['"](?:reset|clean|--force)['"]/.test(shared), 'checkout reuse must never discard working tree bytes');
if (process.platform !== 'win32') {
  console.log('SKIP Windows fault matrix: run tools/pc/runner_selftest.bat on the PC');
  process.exit(0);
}
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'runner687 proof '));
const testChildren = [];
const testPidFiles = [];
const gh = require('./runner_claim_fixture')(root);
console.log('Evidence: ' + root);
const timings = [];
function recordTiming(step, start, code) {
  const timing = { step, seconds: (Date.now() - start) / 1000, code };
  timings.push(timing);
  fs.appendFileSync(path.join(root, 'timings.jsonl'), JSON.stringify(timing) + '\n');
}
function run(exe, args, env = {}, cwd = root) {
  const start = Date.now();
  const p = spawnSync(exe, args, { cwd, env: { ...process.env, ...env }, encoding: 'utf8', windowsHide: true, windowsVerbatimArguments: /cmd\.exe$/i.test(exe), timeout: 90000 });
  const script = args.indexOf('-File');
  const step = script >= 0 ? path.basename(args[script + 1]) + ':' + args[script + 2] :
    /^git(?:\.exe)?$/i.test(path.basename(exe)) ? 'git:' + (args[0] === '-C' ? args[2] : args[0]) : path.basename(exe);
  recordTiming(step, start, p.status);
  if (p.error) throw p.error;
  return { code: p.status, text: (p.stdout || '') + (p.stderr || '') };
}
const ps = (args, env) => run('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(here, 'runner_common.ps1'), ...args], env);
function runEntryPoint(cmd, env) {
  const start = Date.now();
  return new Promise((resolve, reject) => {
    const child = spawn(process.env.COMSPEC, ['/d', '/s', '/c', cmd], {
      cwd: root, env: { ...process.env, ...env }, windowsHide: true, windowsVerbatimArguments: true, timeout: 90000
    });
    testChildren.push(child);
    let text = '', error;
    child.stdout.on('data', b => text += b); child.stderr.on('data', b => text += b);
    child.once('error', e => { error = e; });
    child.once('close', code => {
      recordTiming('runner entry point', start, code);
      if (error) reject(error); else resolve({ code, text });
    });
  });
}
// Each arm owns its job folders and fake GitHub database. The real mirror lock still protects shared Git data.
// Settle the whole batch before throwing so failure cleanup cannot race a runner that is still writing evidence.
async function parallelArms(items, check) {
  for (let i = 0; i < items.length; i += 4) {
    const results = await Promise.allSettled(items.slice(i, i + 4).map(check));
    const failed = results.find(r => r.status === 'rejected');
    if (failed) throw failed.reason;
  }
}
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
const arms = ['opus', 'sonnet', 'openai', 'deepseek', 'kimi', 'kimicode', 'codex'];
for (const arm of arms) write(path.join(source, 'refs/heads', (arm === 'codex' ? 'codex/issue-687' : 'work/issue-687-' + arm) + '-partial'), partial + '\n');
const agent = path.join(root, 'stub agent.bat');
const gitStub = path.join(root, 'stub git.bat');
write(agent, '@echo off\r\n"' + process.execPath + '" "' + path.join(root, 'agent.js') + '" %*\r\nexit /b %ERRORLEVEL%\r\n');
write(path.join(root, 'agent.js'), `
const fs = require('fs'), path = require('path');
const a = process.argv.slice(2), probe = a.some(s => s.includes('Reply with exactly RUNNER_READY.'));
if (process.env.PYTHONDONTWRITEBYTECODE !== '1') process.exit(36);
const db = JSON.parse(fs.readFileSync(process.env.PC_TEST_GH_DB, 'utf8'));
if (!db.running || !db.comments.some(c => c.body.includes('Runner status: running') && c.body.includes('- Run: '))) process.exit(34);
if (probe) {
  fs.appendFileSync(process.env.PC_TEST_TRACE, JSON.stringify(a) + '\\n');
  if (process.env.STUB_AUTH_FAIL === '1') {
    console.log(JSON.stringify({type:'error',error:{message:process.env.STUB_REASON}})); process.exit(0);
  }
  if (process.env.STUB_PROBE_TIMEOUT === '1') {
    fs.writeFileSync(process.env.PC_TEST_TRACE + '.pid', String(process.pid));
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)),0,0,60000);
  }
  if (a[0] === 'run') {
    console.log(JSON.stringify({type:'step_finish',part:{tokens:{input:100,output:10,reasoning:3,cache:{read:20,write:0}}}}));
    console.log(JSON.stringify({type:'text',part:{text:'RUNNER_READY'}}));
  }
  else if (a[0] === 'exec') { fs.writeFileSync(a[a.indexOf('-o') + 1], 'RUNNER_READY'); console.log('stub codex'); }
  else console.log('RUNNER_READY');
} else {
  const task = fs.existsSync('CODEX_TASK.md') ? 'CODEX_TASK.md' : 'WORK_TASK.md';
  if (fs.readFileSync(task,'utf8').includes('OLD BRIEF MUST NOT REACH AGENT')) process.exit(35);
  if (!fs.readFileSync(task,'utf8').includes('Resumed by merging')) process.exit(31);
  if (!fs.readFileSync(task,'utf8').includes('saved work before stopping')) process.exit(33);
  if (fs.readFileSync('progress.txt','utf8') !== 'from partial\\n') process.exit(32);
  fs.writeFileSync('agent_started.txt', 'resumed work verified');
  const fault = process.env.STUB_ACCOUNT_FAULT;
  if (fault === 'invalid') fs.writeFileSync(path.join(process.env.WORK_ROOT, 'openai_spend.txt'), 'invalid ledger\\n');
  if (fault === 'busy') {
    fs.writeFileSync(process.env.PC_TEST_TRACE + '.lock-request', 'lock now');
    const end = Date.now() + 10000;
    while (!fs.existsSync(process.env.PC_TEST_TRACE + '.locked')) {
      if (Date.now() > end) process.exit(37);
      Atomics.wait(new Int32Array(new SharedArrayBuffer(4)),0,0,50);
    }
  }
  const tokens = {input:1000,output:100,reasoning:30,cache:{read:200,write:0}};
  if (fault === 'missing') delete tokens.output;
  console.log(JSON.stringify({type:'step_finish',part:{tokens}}));
  console.log(JSON.stringify({type:'text',part:{text:'Stub completed from partial'}}));
}
`);
write(gitStub, '@echo off\r\n"' + process.execPath + '" "' + path.join(root, 'git.js') + '" %*\r\nexit /b %ERRORLEVEL%\r\n');
write(path.join(root, 'git.js'), `
const fs = require('fs'), path = require('path'), cp = require('child_process');
const a = process.argv.slice(2), mode = process.env.STUB_GIT_FAULT || '';
// This hook runs after reuse eligibility, immediately before the real branch switch.
if (a.includes('checkout') && a.includes('-B') && process.env.STUB_CHECKOUT_EDIT) {
  fs.writeFileSync(path.join(a[a.indexOf('-C') + 1], 'progress.txt'), process.env.STUB_CHECKOUT_EDIT);
  fs.writeFileSync(process.env.STUB_CHECKOUT_MARKER, 'edit injected before switch');
}
if (a.includes('status') && process.env.STUB_RECHECK_FAIL === '1' && fs.existsSync(process.env.STUB_CHECKOUT_MARKER)) {
  console.error('stub status failure after branch switch'); process.exit(55);
}
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
  PYTHONDONTWRITEBYTECODE: '0', // Both launchers must override this for the probe and agent children.
  PC_RUNNER_TEST: '1', PC_TEST_SOURCE: source, PC_TEST_MIRROR: mirror,
  PC_TEST_PREFLIGHT: agent, PC_TEST_GIT: gitPath, PC_REAL_GIT: gitPath, PC_TEST_RETRY_SECONDS: '0',
  PC_TEST_STOP_BEFORE_PUBLISH: '1', WORK_TEST_AGENT: agent, CODEX_TEST_AGENT: agent, WORK_SKIP_CHECKS: '1',
  PC_WAIT_FOR: '', PC_WAIT_RUN: '', PC_WAIT_SECONDS: '2', STUB_GIT_FAULT: '', STUB_AUTH_FAIL: '',
  STUB_PROBE_TIMEOUT: '', STUB_FETCH_HOLD: '', STUB_CHECKOUT_EDIT: '', STUB_RECHECK_FAIL: '', STUB_CHECKOUT_MARKER: '',
  STUB_ACCOUNT_FAULT: '',
  // Issue 722: about 68 GB fake free space, above the 60 GB floor, so fixture runs pass the space check on any host;
  // the dedicated floor tests force 100 MB instead. Settings and hashes fixtures stay unset unless a test names them.
  PC_TEST_SPACE_FREE_MB: '70000', PC_TEST_SETTINGS: '', PC_TEST_HASHES: '',
  PC_TEST_GH: gh.fake, PC_TEST_GH_FAIL: '', PC_TEST_GH_HOLD: '',
  VOIDSWORN_OPENAI_API_KEY: '', WORK_MODEL: '', WORK_EFFORT: '',
  GIT_AUTHOR_NAME: 'Fixture', GIT_AUTHOR_EMAIL: 'fixture@example.invalid', GIT_COMMITTER_NAME: 'Fixture', GIT_COMMITTER_EMAIL: 'fixture@example.invalid'
};
// Most scenarios need real Git only. Avoid a cmd + Node + Git process tree for every harmless Git call.
// Keep the wrapper for every injected Git fault, late edit/status race and deliberate fetch hold.
function gitEnvironment(env) {
  return { ...env, PC_TEST_GIT: env.STUB_GIT_FAULT || env.STUB_CHECKOUT_EDIT || env.STUB_RECHECK_FAIL || env.STUB_FETCH_HOLD ? gitStub : gitPath };
}
async function job(arm, label, extra = {}) {
  const home = path.join(root, arm + '-' + label); fs.mkdirSync(home, { recursive: true });
  const env = gitEnvironment({ ...defaults, WORK_ROOT: home, CODEX_TEST_ROOT: home, PC_TEST_TRACE: path.join(home, 'probe_args.txt'), PC_TEST_COUNTER: path.join(home, 'tries'),
    PC_TEST_GH_DB: path.join(home, 'gh-db.json'), PC_TEST_GH_TRACE: path.join(home, 'gh.jsonl'), ...extra });
  testPidFiles.push(env.PC_TEST_TRACE + '.pid');
  if (!fs.existsSync(env.PC_TEST_GH_DB)) {
    const db = gh.database(687, base);
    const prefix = arm === 'codex' ? 'codex' : 'work';
    if (label === 'same-seat') {
      db.branches.push({ name: prefix + '/issue-687' + (prefix === 'work' ? '-deepseek' : '') });
      db.pulls = [{ number: 700, head: { ref: prefix + '/issue-687' } }];
    }
    if (arm !== 'codex') db.issue.body = db.issue.body.replace('Effort (Codex): high\n', '');
    if (label === 'same-seat') db.issue.body = db.issue.body.replace('## THIS IS THE JOB NOW', '**Run 2: THIS IS THE JOB NOW.** Inline instructions.').replace('## Earlier run (DONE)', 'Run 1 (DONE):');
    if (label === 'closed') db.issue.state = 'closed';
    if (label === 'claimed') db.running = true;
    if (label === 'other-pr') db.pulls = [{ number: 700, head: { ref: 'opus/issue-687' } }];
    if (label === 'other-branch') db.branches.push({ name: 'opus/issue-687' });
    if (label === 'no-effort') db.issue.body = db.issue.body.replace('Effort (Codex): high\n', '');
    if (label === 'new-job') db.issue.body = db.issue.body.split('\n\n## THIS IS THE JOB NOW')[0] + '\n\nFinish the new fixture job.\n';
    if (label === 'two-fixed') {
      const fixed = db.issue.body.split('\n\n## THIS IS THE JOB NOW')[0];
      db.issue.body = fixed + '\n\n' + fixed + '\n\nAmbiguous new job.\n';
    }
    if (label === 'no-current') db.issue.body = db.issue.body.replace('## THIS IS THE JOB NOW', '## Old job');
    if (label === 'two-current') db.issue.body += '\n## Run 2 THIS IS THE JOB NOW\nAnother job.\n';
    write(env.PC_TEST_GH_DB, JSON.stringify(db)); write(env.PC_TEST_GH_TRACE, '');
  }
  const bat = path.join(extra.STUB_RUNNER_TOOLS || here, arm === 'codex' ? 'codex_issue.bat' : 'work_issue.bat');
  const cmd = '""' + bat + '" 687' + (arm === 'codex' ? '' : ' ' + arm + ' dryrun') + '"';
  const r = await runEntryPoint(cmd, env);
  write(path.join(home, 'console.txt'), r.text);
  assert(fs.existsSync(path.join(home, arm === 'codex' ? 'issue-687/status.json' : 'dryrun-687-' + arm + '/latest.txt')), r.text);
  const runHome = arm === 'codex' ? home : read(path.join(home, 'dryrun-687-' + arm, 'latest.txt')).trim();
  const out = path.join(runHome, arm === 'codex' ? 'issue-687' : 'out');
  const repo = path.join(runHome, 'repo');
  write(path.join(home, 'console.txt'), r.text);
  return { ...r, out, repo, env, result: read(path.join(out, 'result.txt')), state: JSON.parse(read(path.join(out, 'status.json'))) };
}
const fixtureSetupSeconds = (Date.now() - started) / 1000;
console.log('Fixture setup: ' + fixtureSetupSeconds.toFixed(2) + ' s (tiny shared source and stubs; retry delay 0 s)');
(async () => { try {
  // Issue 985: exercise real PS accounting with only token fixtures, never a key or provider call.
  const spendRoot = path.join(root, 'openai accounting'); fs.mkdirSync(spendRoot, { recursive: true });
  const spendOut = path.join(spendRoot, 'out'); write(path.join(spendOut, 'result.txt'), '');
  const spendSettings = path.join(spendRoot, 'runner_settings.txt');
  const ledger = path.join(spendRoot, 'openai_spend.txt');
  const workPS = args => run('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(here, 'work_issue.ps1'), ...args], { ...defaults });
  const budget = (model = 'openai/gpt-6.1-sol', dry = '0') => workPS(['openai-budget', spendOut, spendRoot, spendSettings, model, dry]);
  const spend = (out = spendOut, model = 'openai/gpt-6.1-sol', dry = '0') => workPS(['openai-spend', '985', out, spendRoot, spendSettings, model, dry]);
  const rows = () => read(ledger).trim().split(/\r?\n/).filter(Boolean).map(s => JSON.parse(s));
  assert.equal(workPS(['openai-key', spendOut]).code, 3);
  assert(read(path.join(spendOut, 'result.txt')).includes('no OpenAI API key saved: run OPENAI_API_KEY.bat'));
  assert.equal(budget().code, 0); // Missing setting defaults to 94.
  const event = (input, cached, output) => JSON.stringify({type:'step_finish',part:{tokens:{input,output,reasoning:100000,cache:{read:cached,write:0}}}}) + '\n';
  write(path.join(spendOut, 'events.jsonl'), event(1000000, 2000000, 3000000));
  write(path.join(spendOut, 'preflight_log.txt'), event(100000, 100000, 100000));
  assert.equal(spend().code, 0);
  assert.equal(rows().length, 1); assert.equal(rows()[0].estimated_usd, 35.41);
  assert.equal(rows()[0].running_total_usd, 35.41); assert.equal(rows()[0].budget_usd, 94);
  assert.equal(rows()[0].input, 1100000); assert.equal(rows()[0].cached_input, 2100000); assert.equal(rows()[0].output, 3300000);
  assert.equal(spend().code, 0); assert.equal(rows().length, 1, 'finish must not double record');
  assert(read(path.join(spendOut, 'result.txt')).includes('OpenAI estimate USD: 35.41'));
  write(spendSettings, 'openai_budget_usd=35.41\n');
  assert.equal(budget().code, 3); assert(read(path.join(spendOut, 'result.txt')).includes('OpenAI budget reached'));
  assert.equal(budget('openai/gpt-6.1-sol', '1').code, 0, 'dry run ignores real spend');
  write(spendSettings, 'openai_budget_usd=36\n'); assert.equal(budget().code, 0);
  write(spendSettings, 'openai_budget_usd=oops\n'); assert.equal(budget().code, 3);
  write(spendSettings, 'openai_budget_usd=94\n'); assert.equal(budget('openai/unpriced').code, 3);
  const old = rows()[0]; old.date = '2000-01-01T00:00:00Z'; write(ledger, JSON.stringify(old) + '\n');
  write(spendSettings, 'openai_budget_usd=1\n'); assert.equal(budget().code, 0, 'previous month does not spend this month');
  const terraOut = path.join(spendRoot, 'terra'); write(path.join(terraOut, 'result.txt'), '');
  write(path.join(terraOut, 'events.jsonl'), event(1000000, 2000000, 3000000));
  assert.equal(spend(terraOut, 'openai/gpt-6.1-terra').code, 0);
  assert.equal(rows()[1].estimated_usd, 16.6); assert.equal(rows()[1].running_total_usd, 16.6);
  assert.equal(budget().code, 3, 'run crossing budget stops the next start');
  const beforeDry = read(ledger); assert.equal(spend(terraOut, 'openai/gpt-6.1-terra', '1').code, 0);
  assert.equal(read(ledger), beforeDry);
  const unknownOut = path.join(spendRoot, 'unknown'); write(path.join(unknownOut, 'result.txt'), '');
  write(path.join(unknownOut, 'preflight_log.txt'), '{"type":"error","error":{"message":"fixture failed probe"}}\n');
  assert.equal(spend(unknownOut).code, 3); assert.equal(rows()[2].status, 'unknown');
  write(spendSettings, 'openai_budget_usd=94\n'); assert.equal(budget().code, 3);
  assert(read(path.join(spendOut, 'result.txt')).includes('OpenAI usage unknown'));
  write(ledger, 'bad ledger\n'); assert.equal(budget().code, 3);
  pass('OpenAI missing key, named prices, probe plus agent usage, idempotent ledger, default/configured budget, dry isolation, month rollover and unknown-usage refusal');
  // Run the real preservation path against our local remote. Only the TEMP copy enables live accounting in dryrun
  // and a local push; test agents and fake GitHub still isolate every provider and network operation.
  const faultTools = path.join(root, 'accounting runner');
  for (const name of ['work_issue.bat','work_issue.ps1','runner_common.ps1','run_timeout.ps1','tmo.bat','gpu_slots.js']) {
    write(path.join(faultTools, name), read(path.join(here, name)));
  }
  write(path.join(faultTools, 'work_issue.bat'), read(path.join(faultTools, 'work_issue.bat'))
    .replace(/(%PS% openai-(?:budget|spend)[^\r\n]*)"%DRY%"/g, '$1"0"')
    .replace('set "PUSHMODE=dry"', 'set "PUSHMODE=test"'));
  const ledgerHolder = path.join(root, 'ledger holder.ps1');
  write(ledgerHolder, `while (-not (Test-Path ($env:PC_TEST_TRACE + '.lock-request'))) { Start-Sleep -Milliseconds 100 }
$s = [IO.File]::Open((Join-Path $env:WORK_ROOT 'openai_spend.txt'), 'OpenOrCreate', 'ReadWrite', 'None')
try {
  [IO.File]::WriteAllText(($env:PC_TEST_TRACE + '.locked'), 'locked')
  while (-not (Test-Path ($env:PC_TEST_TRACE + '.release'))) { Start-Sleep -Milliseconds 100 }
} finally { $s.Dispose() }
`);
  for (const fault of ['missing', 'invalid', 'busy']) {
    const extra = { STUB_RUNNER_TOOLS: faultTools, STUB_ACCOUNT_FAULT: fault,
      PC_TEST_STOP_BEFORE_PUBLISH: '0' };
    if (fault === 'busy') {
      const home = path.join(root, 'openai-account-busy');
      const child = spawn('powershell.exe', ['-NoProfile', '-File', ledgerHolder], { stdio: 'ignore', windowsHide: true,
        env: { ...process.env, WORK_ROOT: home, PC_TEST_TRACE: path.join(home, 'probe_args.txt') } });
      testChildren.push(child);
    }
    const r = await job('openai', 'account-' + fault, extra);
    assert.equal(r.code, 14, r.text + r.result);
    assert.equal(r.state.status, 'partial', r.result);
    assert.equal(r.state.reason, 'spend accounting unknown');
    assert.equal(read(path.join(r.out, 'checks.txt')).trim(), 'runner checks skipped: partial run');
    assert(fs.existsSync(path.join(r.out, 'guard_dir.txt')), 'the preservation guard ran');
    const branch = 'work/issue-687-openai-partial';
    const tip = run('git', ['--git-dir', source, 'rev-parse', branch]); assert.equal(tip.code, 0, tip.text);
    assert.equal(run('git', ['--git-dir', source, 'show', tip.text.trim() + ':agent_started.txt']).text.trim(), 'resumed work verified');
    assert.equal(read(path.join(r.out, 'confirmed_commit.txt')).trim(), tip.text.trim());
    assert.equal(run('git', ['--git-dir', source, 'show-ref', '--verify', 'refs/heads/work/issue-687-openai']).code, 128, 'no delivery branch or PR');
    const journal = path.join(r.env.WORK_ROOT, 'openai_spend_unknown');
    const entries = fs.readdirSync(journal).map(name => JSON.parse(read(path.join(journal, name))));
    assert.equal(entries.length, 1); assert.equal(entries[0].status, 'unknown'); assert.equal(entries[0].run.toLowerCase(), r.out.toLowerCase());
    if (fault === 'busy') write(r.env.PC_TEST_TRACE + '.release', 'release');
    // Repairing the ledger and releasing its lock cannot erase the separate unknown entry.
    if (fault !== 'busy') write(path.join(r.env.WORK_ROOT, 'openai_spend.txt'), '');
    const probeBefore = read(r.env.PC_TEST_TRACE);
    const refused = await job('openai', 'account-' + fault, extra);
    assert.equal(refused.code, 3, refused.text + refused.result);
    assert.equal(refused.state.status, 'failed'); assert(refused.result.includes('OpenAI usage unknown'), refused.result);
    assert(!fs.existsSync(refused.repo), 'next paid start refused before checkout');
    assert.equal(read(r.env.PC_TEST_TRACE), probeBefore, 'next paid start never calls the probe');
    // Restore the shared source partial so the existing resume matrix keeps its original fixture.
    write(path.join(source, 'refs/heads', branch), partial + '\n');
    pass('OpenAI ' + fault + ' accounting: guarded partial push retains agent changes, never checked, next paid start refused');
  }
  const openaiOverride = await job('openai', 'override', { WORK_MODEL: 'openai/gpt-6.1-terra' });
  assert.equal(openaiOverride.code, 0, openaiOverride.text + openaiOverride.result);
  assert.equal(openaiOverride.state.model, 'openai/gpt-6.1-terra');
  assert(openaiOverride.result.includes('differs from the arm default openai/gpt-6.1-sol'));
  const wrongProvider = await job('openai', 'provider', { WORK_MODEL: 'anthropic/claude-opus-5-5' });
  assert.equal(wrongProvider.code, 0, wrongProvider.text + wrongProvider.result);
  assert.equal(wrongProvider.state.model, 'openai/gpt-6.1-sol');
  const unpriced = await job('openai', 'unpriced', { WORK_MODEL: 'openai/unpriced' });
  assert.equal(unpriced.code, 3, unpriced.text + unpriced.result);
  assert(!fs.existsSync(unpriced.env.PC_TEST_TRACE)); assert(!fs.existsSync(unpriced.repo));
  pass('OpenAI same-provider override stamped, other provider ignored and unpriced model refused before checkout/probe');
  // Issue 860 run 2: exercise the real checkout with local Git data, never publish or discard fixture files.
  function checkoutFixture(label, prepare = () => {}, expectedKeep = false, options = {}) {
    const home = path.join(root, 'reuse-' + label), repo = path.join(home, 'repo'), out = path.join(home, 'out');
    fs.mkdirSync(home, { recursive: true }); write(path.join(out, 'result.txt'), '');
    assert.equal(run('git', ['clone', '-q', '-c', 'core.autocrlf=false', source, repo]).code, 0);
    const git = args => {
      const r = run('git', ['-C', repo, ...args]); assert.equal(r.code, 0, r.text); return r.text.trim();
    };
    prepare(repo, git);
    const existing = fs.readdirSync(home).filter(n => n.startsWith('repo-kept-'));
    const oldGit = fs.statSync(path.join(repo, '.git'));
    assert.equal(ps(['init', out, 'fixture/reuse'], defaults).code, 0);
    const env = gitEnvironment({ ...defaults, STUB_CHECKOUT_MARKER: path.join(home, 'switch-hook.txt'), ...options.env });
    const r = ps(['checkout', repo, out, 'fixture/reuse', ''], env);
    if (options.changed) {
      assert.equal(r.code, 14, r.text);
      assert(r.text.includes('checkout changed while starting; kept as is'), r.text);
      assert.equal(JSON.parse(read(path.join(out, 'status.json'))).status, 'failed');
      assert(fs.existsSync(env.STUB_CHECKOUT_MARKER), 'the edit hook ran between eligibility and the switch');
      assert.equal(fs.statSync(path.join(repo, '.git')).ino, oldGit.ino);
      assert.equal(fs.readdirSync(home).filter(n => n.startsWith('repo-kept-')).length, 0);
      assert(!r.text.includes('local clone attempt') && !r.text.includes('earlier checkout reused in place'), r.text);
      assert(!fs.existsSync(path.join(out, 'base_commit.txt')), 'stop before resume or agent work');
      assert.equal(read(path.join(repo, 'progress.txt')), env.STUB_CHECKOUT_EDIT, 'late tracked edit bytes survive');
      return { home, repo, text: r.text };
    }
    assert.equal(r.code, 0, r.text);
    const kept = fs.readdirSync(home).filter(n => n.startsWith('repo-kept-') && !existing.includes(n));
    for (const name of existing) assert(fs.existsSync(path.join(home, name)), 'existing kept copy survives');
    assert.equal(kept.length, expectedKeep ? 1 : 0, r.text);
    assert.equal(git(['symbolic-ref', '--short', 'HEAD']), 'fixture/reuse');
    assert.equal(git(['rev-parse', 'HEAD']), read(path.join(source, 'refs/heads/main')).trim());
    assert.equal(git(['remote', 'get-url', 'origin']), source);
    assert.equal(read(path.join(repo, 'progress.txt')), 'base\n');
    if (!expectedKeep) {
      assert.equal(fs.statSync(path.join(repo, '.git')).ino, oldGit.ino, 'reuse keeps the Git directory');
      assert(r.text.includes('earlier checkout reused in place'), r.text);
      assert(!r.text.includes('local clone attempt'), r.text);
    }
    return { home, repo, old: expectedKeep ? path.join(home, kept[0]) : repo, text: r.text };
  }
  const refreshedMain = fixtureCommit({ 'progress.txt': 'base\n', 'upstream.txt': 'fresh upstream\n' }, base);
  let clean;
  try {
    clean = checkoutFixture('clean-pushed', (repo, git) => {
      git(['checkout', '-q', '-b', 'fixture/old-pushed', partial]);
      write(path.join(source, 'refs/heads/main'), refreshedMain + '\n');
      // These stand in for existing kept checkouts. Every byte must remain after the warning.
      for (let i = 0; i < 3; i++) write(path.join(path.dirname(repo), 'repo-kept-old-' + i, 'proof.txt'), 'preserved-' + i);
    });
  } finally { write(path.join(source, 'refs/heads/main'), base + '\n'); }
  assert.equal(read(path.join(clean.repo, 'upstream.txt')), 'fresh upstream\n');
  assert(clean.text.includes('WARNING:') && clean.text.includes('3 repo-kept-* copies'), clean.text);
  for (let i = 0; i < 3; i++) {
    const copy = path.join(clean.home, 'repo-kept-old-' + i);
    assert.equal(read(path.join(copy, 'proof.txt')), 'preserved-' + i);
    assert(clean.text.includes(copy + ': 11 logical bytes'), clean.text);
  }
  pass('clean pushed checkout reuses the Git directory, switches from old branch to main, warns with kept names and sizes, removes nothing');
  const ignored = checkoutFixture('unique-ignored', repo => {
    write(path.join(repo, '.git/info/exclude'), 'unique work.blend\n');
    write(path.join(repo, 'unique work.blend'), 'unique ignored work');
  }, true);
  assert.equal(read(path.join(ignored.old, 'unique work.blend')), 'unique ignored work');
  pass('unique ignored file is kept aside and its bytes survive');
  const cache = checkoutFixture('cache-only', repo => {
    write(path.join(repo, '.git/info/exclude'), 'godot/.godot/\ngodot/*.import\n');
    write(path.join(repo, 'godot/.godot/imported/cached.bin'), 'cached import');
    write(path.join(repo, 'godot/texture.png.import'), 'import settings');
  });
  assert.equal(read(path.join(cache.repo, 'godot/.godot/imported/cached.bin')), 'cached import');
  assert.equal(read(path.join(cache.repo, 'godot/texture.png.import')), 'import settings');
  pass('cache-only ignored files allow reuse and both cache files survive');
  const pythonCaches = {
    '__pycache__/root.cpython-312.pyc': 'root bytecode',
    'tools/blender/build_sheets/__pycache__/weapon_match.cpython-312.pyc': 'nested bytecode',
    'tools/__pycache__/nested/cache.bin': 'cache folder contents',
    'module.pyc': 'standalone bytecode',
    'tools/compiled/module.pyc': 'nested standalone bytecode'
  };
  const python = checkoutFixture('python-caches', (repo, git) => {
    git(['checkout', '-q', '-b', 'fixture/old-pushed', partial]);
    write(path.join(repo, '.git/info/exclude'), '__pycache__/\n*.pyc\n');
    for (const [name, bytes] of Object.entries(pythonCaches)) write(path.join(repo, name), bytes);
  });
  for (const [name, bytes] of Object.entries(pythonCaches)) assert.equal(read(path.join(python.repo, name)), bytes);
  pass('pushed checkout with only ignored Python caches reuses in place and preserves every cache byte');
  for (const [label, name, exclude] of [
    ['untracked-pyc', 'module.pyc', ''],
    ['untracked-pycache', 'tools/__pycache__/module.pyc', ''],
    ['other-ignored', 'notes.txt', 'notes.txt\n'],
    ['other-untracked', 'notes.txt', ''],
    ['pycache-lookalike', 'tools/__pycache__backup/module.bin', '__pycache__backup/\n'],
    ['pyc-lookalike', 'module.pyc.backup', '*.backup\n'],
    ['quoted-pyc', 'tools/folder with spaces/module.pyc', '*.pyc\n']
  ]) {
    const kept = checkoutFixture(label, repo => {
      write(path.join(repo, '.git/info/exclude'), label.startsWith('untracked-') ? 'tools/__pycache__/safe.pyc\n' : '__pycache__/\n*.pyc\n' + exclude);
      write(path.join(repo, 'tools/__pycache__/safe.pyc'), 'ignored cache');
      write(path.join(repo, name), 'unique work');
    }, true);
    assert.equal(read(path.join(kept.old, name)), 'unique work');
    assert.equal(read(path.join(kept.old, 'tools/__pycache__/safe.pyc')), 'ignored cache');
    assert(kept.text.includes('working tree needs keeping:'), kept.text);
    if (label.startsWith('untracked-')) assert(kept.text.includes('?? ' + name), kept.text);
    pass(label + ': checkout and all bytes kept aside even beside a Python cache');
  }
  const lateEdit = 'tracked edit written during startup\r\n';
  const changed = checkoutFixture('late-tracked-edit', () => {}, false, {
    changed: true, env: { STUB_CHECKOUT_EDIT: lateEdit }
  });
  assert.equal(run('git', ['-C', changed.repo, 'symbolic-ref', '--short', 'HEAD']).text.trim(), 'fixture/reuse');
  pass('tracked edit after eligibility survives the branch switch and stops the job with failed status');
  checkoutFixture('late-status-failure', () => {}, false, {
    changed: true, env: { STUB_CHECKOUT_EDIT: lateEdit, STUB_RECHECK_FAIL: '1' }
  });
  pass('unreadable status after the branch switch fails closed and keeps late edit bytes');
  try {
    checkoutFixture('late-edit-blocks-switch', () => write(path.join(source, 'refs/heads/main'), conflicting + '\n'), false, {
      changed: true, env: { STUB_CHECKOUT_EDIT: lateEdit }
    });
    pass('late tracked edit that blocks the branch switch survives and stops with the same clear message');
  } finally { write(path.join(source, 'refs/heads/main'), base + '\n'); }
  for (const [label, incoming, cachePath] of [
    ['python-file-collision', 'module.pyc', 'module.pyc'],
    ['python-parent-collision', 'tools', 'tools/__pycache__/module.pyc']
  ]) {
    const tip = fixtureCommit({ [incoming]: 'incoming tracked file\n', 'progress.txt': 'base\n' }, base);
    write(path.join(source, 'refs/heads/main'), tip + '\n');
    try {
      const collision = checkoutFixture(label, (repo, git) => {
        git(['checkout', '-q', '--detach', base]);
        write(path.join(repo, '.git/info/exclude'), '__pycache__/\n*.pyc\n');
        write(path.join(repo, cachePath), 'Python cache must survive collision');
      }, true);
      assert.equal(read(path.join(collision.old, cachePath)), 'Python cache must survive collision');
      assert.equal(read(path.join(collision.repo, incoming)), 'incoming tracked file\n');
      assert(collision.text.includes('cache would be overwritten by incoming file:'), collision.text);
      pass(label + ': incoming tracked collision keeps the checkout and Python cache intact');
    } finally { write(path.join(source, 'refs/heads/main'), base + '\n'); }
  }
  const privateTip = fixtureCommit({ 'progress.txt': 'private commit\n' }, base);
  const unpushed = checkoutFixture('unpushed', (repo, git) => {
    git(['fetch', '-q', source, privateTip]);
    git(['checkout', '-q', '-b', 'fixture/private', privateTip]);
  }, true);
  assert.equal(read(path.join(unpushed.old, 'progress.txt')), 'private commit\n');
  assert.equal(run('git', ['-C', unpushed.old, 'rev-parse', 'HEAD']).text.trim(), privateTip);
  pass('unpushed commit is kept aside with its branch and work intact');
  const abandoned = checkoutFixture('reflog-only', (repo, git) => {
    git(['fetch', '-q', source, privateTip]);
    git(['checkout', '-q', '--detach', privateTip]);
    git(['checkout', '-q', 'main']);
  }, true);
  assert(run('git', ['-C', abandoned.old, 'reflog', '--format=%H']).text.includes(privateTip));
  pass('unpushed history reachable only from the reflog is kept aside');
  const dirty = checkoutFixture('dirty-tracked', repo => write(path.join(repo, 'progress.txt'), 'uncommitted edits\n'), true);
  assert.equal(read(path.join(dirty.old, 'progress.txt')), 'uncommitted edits\n');
  pass('dirty tracked file is kept aside with edits intact');
  const hidden = checkoutFixture('hidden-tracked', (repo, git) => {
    git(['update-index', '--assume-unchanged', 'progress.txt']);
    write(path.join(repo, 'progress.txt'), 'hidden edits\n');
  }, true);
  assert.equal(read(path.join(hidden.old, 'progress.txt')), 'hidden edits\n');
  pass('index flags that hide tracked edits cause the checkout to be kept');
  const collisionTip = fixtureCommit({ 'godot': 'incoming tracked file\n', 'progress.txt': 'base\n' }, base);
  write(path.join(source, 'refs/heads/main'), collisionTip + '\n');
  try {
    const collision = checkoutFixture('cache-collision', (repo, git) => {
      git(['checkout', '-q', '--detach', base]);
      write(path.join(repo, '.git/info/exclude'), 'godot/.godot/\n');
      write(path.join(repo, 'godot/.godot/cache.bin'), 'cache must survive collision');
    }, true);
    assert.equal(read(path.join(collision.old, 'godot/.godot/cache.bin')), 'cache must survive collision');
    assert.equal(read(path.join(collision.repo, 'godot')), 'incoming tracked file\n');
    pass('incoming tracked path that collides with an ignored cache keeps the old checkout and cache intact');
  } finally { write(path.join(source, 'refs/heads/main'), base + '\n'); }
  await parallelArms(['codex', 'deepseek', 'kimi', 'kimicode'], async arm => {
    for (const [scenario, reason] of [['closed', 'not an open job'], ['claimed', 'already carries running'],
      ['other-pr', 'open PR #700'], ['other-branch', 'delivery branch opus/issue-687'], ['no-current', 'found 0'], ['two-current', 'found 2'],
      ['two-fixed', 'fixed blocks: 2']]) {
      const r = await job(arm, scenario);
      assert.equal(r.code, 14, r.text + '\n' + r.result);
      assert.equal(r.state.status, 'failed'); assert(r.result.includes(reason), r.result);
      assert(!fs.existsSync(r.repo), 'refusal before checkout');
      assert(!fs.existsSync(r.env.PC_TEST_TRACE), 'refusal before model probe');
      const calls = read(r.env.PC_TEST_GH_TRACE).trim().split(/\r?\n/).filter(Boolean).map(l => JSON.parse(l));
      assert(calls.every(c => c.method === 'GET'), 'refusal cannot change another claim');
      assert.equal(JSON.parse(read(r.env.PC_TEST_GH_DB)).running, scenario === 'claimed');
      pass(arm + ': ' + scenario + ' refuses before checkout, probe or agent, with no GitHub writes');
    }
    const rerun = await job(arm, 'same-seat');
    assert.equal(rerun.code, 0, rerun.text + '\n' + rerun.result);
    assert(fs.existsSync(path.join(rerun.repo, 'agent_started.txt')), rerun.result);
    const task = read(path.join(rerun.out, arm === 'codex' ? 'CODEX_TASK.md' : 'WORK_TASK.md'));
    assert(task.includes('Inline instructions.') && !task.includes('OLD BRIEF'), task);
    const calls = read(rerun.env.PC_TEST_GH_TRACE).trim().split(/\r?\n/).filter(Boolean).map(l => JSON.parse(l));
    assert(calls.some(c => c.method === 'POST' && /\/labels$/.test(c.endpoint)), 'successful claim sets running');
    assert(calls.some(c => c.payload?.body?.includes('claimed before checkout and model calls')), 'successful claim writes its status comment');
    pass(arm + ': same-seat branch and PR rerun starts with a bold marker, current brief only and Codex-only Effort');
    const fresh = await job(arm, 'new-job');
    assert.equal(fresh.code, 0, fresh.text + '\n' + fresh.result);
    assert(fs.existsSync(path.join(fresh.repo, 'agent_started.txt')), fresh.result);
    const freshTask = read(path.join(fresh.out, arm === 'codex' ? 'CODEX_TASK.md' : 'WORK_TASK.md'));
    assert(freshTask.includes('Finish the new fixture job.') && !freshTask.includes('THIS IS THE JOB NOW'), freshTask);
    assert(!JSON.parse(read(fresh.env.PC_TEST_GH_DB)).running, 'finished new job releases its claim');
    pass(arm + ': a new job with one fixed block and no run history runs its whole body without a marker');
  });
  const effortMissing = await job('codex', 'no-effort');
  assert.equal(effortMissing.code, 14); assert(!fs.existsSync(effortMissing.repo));
  assert(effortMissing.result.includes('Codex fixed block needs Effort'), effortMissing.result);
  pass('Codex alone refuses a missing Effort line before checkout');
  for (const arm of ['codex', 'deepseek', 'kimicode']) {
    const failure = await job(arm, 'claim-failure', { PC_TEST_GH_FAIL: 'POST repos/rcbailey12/voidsworn/issues/687/comments' });
    assert.equal(failure.code, 14, failure.text + failure.result);
    assert(!fs.existsSync(failure.repo)); assert(!fs.existsSync(failure.env.PC_TEST_TRACE));
    assert(!JSON.parse(read(failure.env.PC_TEST_GH_DB)).running, 'failed comment claim rolls back its label');
    assert(failure.result.includes('cannot validate or claim job'), failure.result);
    pass(arm + ': failed status-comment claim stops before checkout or model calls and releases only its label');
  }
  await parallelArms(arms, async arm => {
    const r = await job(arm, 'resume');
    assert.equal(r.code, 0, r.text + '\n' + r.result);
    assert(fs.existsSync(path.join(r.repo, 'agent_started.txt')), r.result);
    assert(read(path.join(r.out, arm === 'codex' ? 'CODEX_TASK.md' : 'WORK_TASK.md')).includes('Resumed by merging'));
    assert.equal(run('git', ['-C', r.repo, 'remote', 'get-url', 'origin']).text.trim(), source);
    assert(!fs.existsSync(path.join(r.repo, '.git/objects/info/alternates')));
    const probe = JSON.parse(read(r.env.PC_TEST_TRACE).trim());
    assert.equal(probe[0], arm === 'codex' ? 'exec' : arm === 'kimicode' ? '-m' : 'run');
    assert.equal(r.state.status, 'unverified');
    const expectModel = arm === 'codex' ? 'gpt-6.2-sol' : arm === 'kimicode' ? 'kimi-code/kimi-for-coding' : arm === 'kimi' ? 'moonshotai/kimi-k3.1-pro' : arm === 'opus' ? 'anthropic/claude-opus-5-5' : arm === 'sonnet' ? 'anthropic/claude-sonnet-5-5' : 'deepseek/deepseek-flash';
    assert(r.result.includes('model: ' + expectModel), r.result);
    assert.equal(r.state.model, expectModel);
    if (arm === 'codex') { assert(r.result.includes('effort: high'), r.result); assert.equal(r.state.effort, 'high'); }
    assert(!r.result.includes('differs from the arm default'), r.result);
    assert(!JSON.parse(read(r.env.PC_TEST_GH_DB)).running, 'finished run releases its claim');
    if (arm === 'openai') {
      assert(r.result.includes('dry run, no spend recorded'), r.result);
      assert(read(path.join(r.out, 'stats.txt')).includes('OpenAI estimate USD:'));
      assert(!fs.existsSync(path.join(r.env.WORK_ROOT, 'openai_spend.txt')));
    }
    pass(arm + ': claim before probe and agent, only current brief, partial resumed, model stamped, Python bytecode disabled in probe and agent, claim released, no publish');
    const why = arm === 'kimicode' ? 'provider managed:kimi-code has no credential configured (expired login)' : arm === 'codex' ? 'quota exhausted' : 'credit balance is too low';
    const bad = await job(arm, 'auth', { STUB_AUTH_FAIL: '1', STUB_REASON: why });
    assert.notEqual(bad.code, 0); assert(bad.result.includes(why), bad.result);
    assert(!fs.existsSync(path.join(bad.repo, 'agent_started.txt')));
    assert.equal(bad.state.status, 'failed');
    pass(arm + ': provider error with exit 0 stops before agent and keeps the reason');
    const dead = await job(arm, 'fetchdead', { STUB_GIT_FAULT: 'fetch-dead' });
    assert.notEqual(dead.code, 0); assert(dead.result.includes('failed after 3 attempts'), dead.result);
    assert(!fs.existsSync(dead.env.PC_TEST_TRACE));
    assert.equal(read(dead.env.PC_TEST_COUNTER + '-fetch'), '3');
    const stopped = await job(arm, 'chain', { PC_WAIT_FOR: path.join(dead.out, 'status.json') });
    assert.notEqual(stopped.code, 0); assert(stopped.result.includes('chain stopped: predecessor ended failed'), stopped.result);
    assert(!fs.existsSync(stopped.repo)); assert(!fs.existsSync(stopped.env.PC_TEST_TRACE));
    pass(arm + ': three failed fetch attempts, then chain stops before clone or model');
  });
  for (const fault of ['fetch-two', 'clone-two', 'clone-dead']) {
    const r = await job('deepseek', fault, { STUB_GIT_FAULT: fault });
    assert.equal(r.code, fault === 'clone-dead' ? 14 : 0, r.text + r.result);
    const op = fault.split('-')[0]; assert.equal(read(r.env.PC_TEST_COUNTER + '-' + op), '3');
    if (op === 'clone') assert.equal(fs.readdirSync(path.dirname(r.repo)).filter(n => n.startsWith('repo-clone-failed-')).length, fault === 'clone-dead' ? 3 : 2);
    pass(fault + ': retry count and failed checkout preservation');
  }
  const rerun = await job('codex','resume');
  const kept = fs.readdirSync(path.dirname(rerun.repo)).filter(n => n.startsWith('repo-kept-'));
  assert.equal(rerun.code,0); assert.equal(kept.length,1);
  assert(fs.existsSync(path.join(path.dirname(rerun.repo),kept[0],'agent_started.txt')));
  pass('Codex restart keeps the earlier checkout and its untracked work');
  // A previous agent's current directory pins repo on Windows. Run the real preservation path, then free it.
  async function holder(home) {
    const repo = path.join(home, 'repo'); write(path.join(repo, 'keep.txt'), 'untracked work must survive');
    const child = spawn(process.execPath, ['-e', "const fs=require('fs'); fs.openSync('keep.txt','r'); console.log('READY'); setInterval(()=>{},1000);", repo], { cwd: repo, windowsHide: true });
    testChildren.push(child);
    await new Promise((resolve, reject) => { child.once('error', reject); child.stdout.once('data', resolve); child.once('exit', code => reject(new Error('holder exited: ' + code))); });
    return child;
  }
  function startCheckout(home, env = {}) {
    const out = path.join(home, 'out'); write(path.join(out, 'result.txt'), '');
    assert.equal(ps(['init', out, 'fixture/held'], defaults).code, 0);
    const child = spawn('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(here, 'runner_common.ps1'), 'checkout', path.join(home, 'repo'), out, 'fixture/held', ''], {
      cwd: root, windowsHide: true, env: { ...process.env, ...defaults, PC_TEST_KEEP_SECONDS: '30', PC_TEST_KEEP_POLL_MS: '100', ...env }
    });
    testChildren.push(child);
    const state = { text: '', out, child };
    state.done = new Promise((resolve, reject) => {
      const timer = setTimeout(() => { child.kill(); reject(new Error('checkout test timed out: ' + state.text)); }, 45000);
      child.stdout.on('data', b => state.text += b); child.stderr.on('data', b => state.text += b);
      child.once('error', e => { clearTimeout(timer); reject(e); });
      child.once('close', code => { clearTimeout(timer); write(path.join(out, 'console.txt'), state.text); resolve(code); });
    });
    return state;
  }
  const pinnedHome = path.join(root, 'held-checkout'), pin = await holder(pinnedHome);
  const waiting = startCheckout(pinnedHome);
  const waitDeadline = Date.now() + 20000;
  while (!waiting.text.includes('checkout rename held') && Date.now() < waitDeadline) await new Promise(resolve => setTimeout(resolve, 50));
  assert(waiting.text.includes('checkout rename held'), waiting.text);
  const other = startCheckout(path.join(root, 'other-lane'));
  assert.equal(await other.done, 0, other.text);
  assert.equal(pin.exitCode, null, 'test holder must still pin the first lane');
  pin.kill(); await new Promise(resolve => pin.once('exit', resolve));
  assert.equal(await waiting.done, 0, waiting.text);
  const preserved = fs.readdirSync(pinnedHome).filter(n => n.startsWith('repo-kept-'));
  assert.equal(preserved.length, 1);
  assert.equal(read(path.join(pinnedHome, preserved[0], 'keep.txt')), 'untracked work must survive');
  assert(fs.existsSync(path.join(pinnedHome, 'repo/progress.txt')));
  assert(waiting.text.includes('holder: PID ' + pin.pid) || /Windows (holder lookup unavailable|could not name)/.test(waiting.text), waiting.text);
  pass('held checkout retries, keeps untracked work, logs holder diagnostics and lets another lane use the mirror');
  const stuckHome = path.join(root, 'permanent-holder'), stuck = await holder(stuckHome);
  const expired = startCheckout(stuckHome, { PC_TEST_KEEP_SECONDS: '0.3' });
  assert.equal(await expired.done, 14, expired.text);
  assert(expired.text.includes('checkout rename still held after 0.3 seconds'), expired.text);
  assert.equal(JSON.parse(read(path.join(expired.out, 'status.json'))).status, 'failed');
  assert.equal(read(path.join(stuckHome, 'repo/keep.txt')), 'untracked work must survive');
  assert.equal(fs.readdirSync(stuckHome).filter(n => n.startsWith('repo-kept-')).length, 0);
  stuck.kill(); await new Promise(resolve => stuck.once('exit', resolve));
  pass('rename wait expires cleanly with failed status and the original checkout intact');
  // A conflicting partial stops before preflight and leaves MERGE_HEAD and conflicted files intact.
  write(path.join(source, 'refs/heads/main'), conflicting + '\n');
  const conflict = await job('codex', 'conflict');
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
  const deniedKiller = path.join(root, 'denied taskkill.bat'); write(deniedKiller, '@echo off\r\necho Access denied\r\nexit /b 5\r\n');
  const slow = await job('codex', 'preflight-timeout', { STUB_PROBE_TIMEOUT: '1', PC_TEST_PREFLIGHT_SECONDS: '1', PC_TEST_TASKKILL: deniedKiller });
  assert.equal(slow.code, 14); assert(slow.result.includes('timed out after 1 seconds')); assert(!fs.existsSync(path.join(slow.repo, 'agent_started.txt')));
  assert(read(path.join(slow.out, 'preflight_kill_log.txt')).includes('kill verified:'), slow.result);
  const slowPid = Number(read(slow.env.PC_TEST_TRACE + '.pid'));
  assert.throws(() => process.kill(slowPid, 0), e => e.code === 'ESRCH', 'preflight probe survived denied taskkill');
  testPidFiles.splice(testPidFiles.indexOf(slow.env.PC_TEST_TRACE + '.pid'), 1);
  pass('preflight timeout kills the probe tree and stops the job');
  // Hold a real mirror fetch briefly so two simultaneous checkouts contend for the file lock.
  async function concurrentCheckout(n) {
    const home = path.join(root, 'concurrent-' + n); fs.mkdirSync(home); const out = path.join(home, 'out'); fs.mkdirSync(out); write(path.join(out, 'result.txt'), '');
    assert.equal(ps(['init', out, 'fixture/concurrent-' + n], defaults).code, 0);
    const env = { ...process.env, ...gitEnvironment({ ...defaults, STUB_FETCH_HOLD: '1' }) };
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
  const overridden = await job('deepseek', 'model-override', { WORK_MODEL: 'deepseek/deepseek-v4-pro' });
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
  const noStart = await job('deepseek', 'nofreespace', { PC_TEST_SPACE_FREE_MB: '100' });
  assert.equal(noStart.code, 14, noStart.text + '\n' + noStart.result);
  assert.equal(noStart.state.status, 'failed');
  assert(noStart.result.includes('refusing to start: drive'), noStart.result);
  assert(!fs.existsSync(noStart.env.PC_TEST_TRACE));
  assert(!fs.existsSync(noStart.repo));
  pass('a low-disk run stops before the mirror, the model probe and the agent');
  // The Board writes work217\runner_hashes.txt with hashwrite after copying the runner and watchdog files; hashcheck then
  // guards the running copies. A mismatch or a missing file is a warning, never a stop.
  const runnerFiles = ['codex_issue.bat', 'codex_issue.ps1', 'runner_common.ps1', 'work_issue.bat', 'work_issue.ps1', 'review_evidence.ps1', 'run_timeout.ps1', 'tmo.bat', 'gpu_slots.js'];
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
  const hashWarn = await job('deepseek', 'hashwarn', { PC_TEST_HASHES: hashesBad });
  assert.equal(hashWarn.code, 0, hashWarn.text + '\n' + hashWarn.result);
  assert(fs.existsSync(path.join(hashWarn.repo, 'agent_started.txt')));
  assert(hashWarn.result.includes('WARNING: these runner files differ'), hashWarn.result);
  pass('a run whose tools folder drifts from the Board hashes still starts and warns');
  const note = 'PASS runner687+722+860+985: ' + passed + ' checks, Windows entry points, local Git and stub agents only. Preservation commits and pushes use TEMP remotes only; no model usage.\nEvidence: ' + root + '\n';
  write(path.join(root, 'summary.txt'), note); console.log(note.trim());
} catch (e) { write(path.join(root, 'failure.txt'), e.stack); console.error('FAIL runner687: ' + e.stack + '\nEvidence: ' + root); process.exitCode = 1; }
finally {
  for (const file of testPidFiles.filter(file => fs.existsSync(file))) {
    const pid = Number(read(file));
    try { process.kill(pid, 'SIGKILL'); } catch (e) { if (e.code !== 'ESRCH') throw e; }
  }
  for (const child of testChildren) {
    if (child.exitCode === null && child.signalCode === null) {
      child.kill();
      await new Promise(resolve => child.once('exit', resolve));
    }
  }
  const totals = {};
  for (const t of timings) {
    const total = totals[t.step] ||= { calls: 0, seconds: 0 };
    total.calls++; total.seconds += t.seconds;
  }
  const timingNote = 'Timing: ' + ((Date.now() - started) / 1000).toFixed(2) + ' s wall time; cumulative child times below overlap in parallel batches\n' +
    'Fixture setup: ' + fixtureSetupSeconds.toFixed(2) + ' s (includes static checks and Git init)\n' +
    Object.entries(totals).map(([step, t]) => step + ': ' + t.calls + ' calls, ' + t.seconds.toFixed(2) + ' s').join('\n') + '\n';
  write(path.join(root, 'timings.txt'), timingNote);
  console.log(timingNote.trim());
} })();
