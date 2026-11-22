'use strict';
// Issue 1194: test this checkout's tmo.bat, never the PC's installed tools_live copy.
process.env.TMO_OWN_COPY = '1';
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
assert(!read(path.join(here, 'runner_common.ps1')).includes('godot/fx/munition_bodies'), 'Reuse-Caches never counts a munition image as rebuildable: the glbs keep their maps embedded (Artoo on PR 1529)');
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
const openaiDefault = 'openai/gpt-6.2-sol';
const openaiReview = 'openai/gpt-6.1-terra';
assert(workBat.includes('"MODEL=' + openaiDefault + '"'));
assert(workBat.includes('if /i "%ARM%"=="openai" set "OPENCODE_CONFIG=%T%work\\opencode_lean.json"'));
assert(workBat.includes('if /i "%ARM%"=="openai" set "OPENCODE_DISABLE_DEFAULT_PLUGINS=1"'));
assert.equal(lean.provider.openai.options.baseURL, 'https://api.openai.com/v1');
assert.equal(lean.provider.openai.options.apiKey, '{env:VOIDSWORN_OPENAI_API_KEY}');
assert.equal(lean.tools.task, false);
assert.equal(mock.provider.openai.options.baseURL, 'http://127.0.0.1:8765/v1');
assert.equal(lean.provider.openai.npm, '@ai-sdk/openai');
assert.equal(mock.provider.openai.npm, lean.provider.openai.npm);
assert.deepEqual(mock.provider.openai.models, lean.provider.openai.models);
for (const id of [openaiDefault, 'openai/gpt-6.1-sol', openaiReview]) {
  const model = lean.provider.openai.models[id.split('/')[1]];
  assert.equal(model.reasoning, true);
  for (const effort of ['low', 'medium', 'high', 'max']) assert.equal(model.variants[effort].reasoningEffort, effort);
}
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
const concurrency = 10;
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
let shell;
async function runScript(name, args, env) {
  const start = Date.now();
  const result = await shell.run(path.join(here, name), args, env, root);
  recordTiming(name + ':' + args[0], start, result.code);
  return result;
}
const ps = (args, env) => runScript('runner_common.ps1', args, env);
const entryQueue = [];
let activeEntries = 0;
function startEntries() {
  while (activeEntries < concurrency && entryQueue.length) {
    activeEntries++;
    entryQueue.shift()();
  }
}
function runEntryPoint(cmd, env) {
  return new Promise((resolve, reject) => {
    entryQueue.push(() => launchEntryPoint(cmd, env).then(resolve, reject).finally(() => {
      activeEntries--;
      startEntries();
    }));
    startEntries();
  });
}
function launchEntryPoint(cmd, env) {
  const start = Date.now();
  return new Promise((resolve, reject) => {
    const child = spawn(process.env.COMSPEC, ['/d', '/s', '/c', cmd], {
      cwd: root, env: { ...process.env, ...shell.env, ...env }, windowsHide: true, windowsVerbatimArguments: true, timeout: 90000
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
// Let active fixtures finish writing their evidence before propagating a failure.
async function parallel(items, check) {
  const results = await Promise.allSettled(items.map(check));
  const failed = results.find(r => r.status === 'rejected');
  if (failed) throw failed.reason;
}
async function waitFor(condition, milliseconds) {
  const deadline = Date.now() + milliseconds;
  while (!condition() && Date.now() < deadline) await new Promise(resolve => setTimeout(resolve, 25));
  return condition();
}
const source = path.join(root, 'upstream.git');
assert.equal(run('git', ['init', '--bare', '-q', source]).code, 0);
function object(type, value, repo) {
  const b = Buffer.isBuffer(value) ? value : Buffer.from(value);
  const raw = Buffer.concat([Buffer.from(type + ' ' + b.length + '\0'), b]);
  const id = crypto.createHash('sha1').update(raw).digest('hex');
  write(path.join(repo, 'objects', id.slice(0, 2), id.slice(2)), zlib.deflateSync(raw));
  return id;
}
function tree(files, repo) {
  return object('tree', Buffer.concat(Object.entries(files).sort(([a], [b]) => a.localeCompare(b)).map(([name, value]) =>
    Buffer.concat([Buffer.from('100644 ' + name + '\0'), Buffer.from(object('blob', value, repo), 'hex')]))), repo);
}
function fixtureCommit(files, parent, note = '', repo = source) {
  return object('commit', 'tree ' + tree(files, repo) + '\n' + (parent ? 'parent ' + parent + '\n' : '') +
    'author Runner fixture <fixture@example.invalid> 1700000000 +0000\ncommitter Runner fixture <fixture@example.invalid> 1700000000 +0000\n\nTest fixture\n' + note, repo);
}
const base = fixtureCommit({ 'progress.txt': 'base\n' });
const partial = fixtureCommit({ 'progress.txt': 'from partial\n' }, base,
  '\n## Runner resume note (issue 818)\nStop reason: STALLED after 30 min\nChanged files: progress.txt\nLast log lines: saved work before stopping\n## End runner resume note\n');
const conflicting = fixtureCommit({ 'progress.txt': 'conflicting main\n' }, base);
const otherSeatTip = fixtureCommit({ 'progress.txt': 'base\n', 'other-seat.txt': 'from the other seat\n' }, base);
write(path.join(source, 'HEAD'), 'ref: refs/heads/main\n');
write(path.join(source, 'refs/heads/main'), base + '\n');
write(path.join(source, 'refs/heads/opus/issue-687'), otherSeatTip + '\n');
const arms = ['opus', 'sonnet', 'openai', 'deepseek', 'kimi', 'kimicode', 'codex'];
for (const arm of arms) write(path.join(source, 'refs/heads', (arm === 'codex' ? 'codex/issue-687' : 'work/issue-687-' + arm) + '-partial'), partial + '\n');
function fixtureSource(label) {
  const copy = path.join(root, label + '.git');
  fs.cpSync(source, copy, { recursive: true });
  return copy;
}
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
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)),0,0,15000);
  }
  if (a[0] === 'run') {
    console.log(JSON.stringify({type:'step_finish',part:{tokens:{input:100,output:10,reasoning:3,cache:{read:20,write:0}}}}));
    console.log(JSON.stringify({type:'text',part:{text:'RUNNER_READY'}}));
  }
  else if (a[0] === 'exec') { fs.writeFileSync(a[a.indexOf('-o') + 1], 'RUNNER_READY'); console.log('stub codex'); }
  else console.log('RUNNER_READY');
} else {
  if (!process.env.PC_RUN_SCRATCH || process.env.TEMP !== process.env.PC_RUN_SCRATCH ||
      process.env.TMP !== process.env.TEMP || process.env.TMPDIR !== process.env.TEMP) process.exit(38);
  fs.writeFileSync(path.join(process.env.TEMP, 'agent-scratch.txt'), 'owned by the fixture');
  if (process.env.ARM === 'openai') fs.writeFileSync(process.env.PC_TEST_TRACE + '.agent', JSON.stringify(a));
  const task = fs.existsSync('CODEX_TASK.md') ? 'CODEX_TASK.md' : 'WORK_TASK.md';
  const brief = fs.readFileSync(task, 'utf8');
  const expectResume = process.env.STUB_EXPECT_FRESH !== '1';
  if (brief.includes('OLD BRIEF MUST NOT REACH AGENT')) process.exit(35);
  if (brief.includes('Resumed by merging') !== expectResume) process.exit(31);
  if (brief.includes('saved work before stopping') !== expectResume) process.exit(33);
  if (fs.readFileSync('progress.txt','utf8') !== 'from partial\\n') process.exit(32);
  if (process.env.STUB_AGENT_NO_CHANGE !== '1') {
    fs.writeFileSync('agent_started.txt', expectResume ? 'resumed work verified' : 'fresh start verified');
  }
  const agentHold = process.env.STUB_AGENT_HOLD;
  if (agentHold) {
    fs.writeFileSync(agentHold + '.ready', 'agent owns checkout');
    const deadline = Date.now() + 40000;
    while (!fs.existsSync(agentHold + '.release')) {
      if (Date.now() >= deadline) process.exit(38);
      Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 25);
    }
  }
  if (process.env.STUB_IGNORED_WORK === '1') {
    fs.appendFileSync('.git/info/exclude', '\\n/ignored-work.txt\\n');
    fs.writeFileSync('ignored-work.txt', 'only in the checkout');
  }
  if (process.env.STUB_LOCAL_OBJECTS) {
    fs.cpSync(process.env.STUB_LOCAL_OBJECTS, '.git/objects', { recursive: true });
    fs.writeFileSync('.git/refs/remotes/origin/stale-local', process.env.STUB_LOCAL_TIP + '\\n');
  }
  if (process.env.STUB_AGENT_EXIT) process.exit(Number(process.env.STUB_AGENT_EXIT));
  const fault = process.env.STUB_ACCOUNT_FAULT;
  if (fault === 'invalid') fs.writeFileSync(path.join(process.env.WORK_ROOT, 'openai_spend.txt'), 'invalid ledger\\n');
  if (fault === 'busy') {
    fs.writeFileSync(process.env.PC_TEST_TRACE + '.lock-request', 'lock now');
    const end = Date.now() + 10000;
    while (!fs.existsSync(process.env.PC_TEST_TRACE + '.locked')) {
      if (Date.now() > end) process.exit(37);
      Atomics.wait(new Int32Array(new SharedArrayBuffer(4)),0,0,25);
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
  fs.writeFileSync(path.join(a[a.indexOf('-C') + 1], process.env.STUB_CHECKOUT_EDIT_PATH || 'progress.txt'), process.env.STUB_CHECKOUT_EDIT);
  fs.writeFileSync(process.env.STUB_CHECKOUT_MARKER, 'edit injected before switch');
}
if (a.includes('status') && process.env.STUB_RECHECK_FAIL === '1' && fs.existsSync(process.env.STUB_CHECKOUT_MARKER)) {
  console.error('stub status failure after branch switch'); process.exit(55);
}
const op = a.includes('fetch') ? 'fetch' : a[0] === 'clone' ? 'clone' : '';
const hold = process.env.STUB_FETCH_HOLD;
if (op === 'fetch' && hold) {
  fs.writeFileSync(hold + '.ready', 'fetch holds the mirror');
  const deadline = Date.now() + 30000;
  while (!fs.existsSync(hold + '.release')) {
    if (Date.now() >= deadline) { console.error('fixture mirror fetch was not released'); process.exit(56); }
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)),0,0,25);
  }
}
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
  STUB_CHECKOUT_EDIT_PATH: '',
  STUB_ACCOUNT_FAULT: '', STUB_EXPECT_FRESH: '', STUB_AGENT_HOLD: '', STUB_AGENT_EXIT: '', STUB_CHECKS_EXIT: '', STUB_IGNORED_WORK: '',
  // Issue 722: about 68 GB fake free space, above the 60 GB floor, so fixture runs pass the space check on any host;
  // the dedicated floor tests force 100 MB instead. Settings and hashes fixtures stay unset unless a test names them.
  PC_TEST_SPACE_FREE_MB: '70000', PC_TEST_SETTINGS: '', PC_TEST_HASHES: '',
  PC_TEST_GH: gh.fake, PC_TEST_GH_FAIL: '', PC_TEST_GH_HOLD: '', PC_TEST_GH_HOLD_FINISH: '',
  VOIDSWORN_OPENAI_API_KEY: '', OPENAI_API_KEY: '', WORK_MODEL: '', WORK_EFFORT: '',
  GIT_AUTHOR_NAME: 'Fixture', GIT_AUTHOR_EMAIL: 'fixture@example.invalid', GIT_COMMITTER_NAME: 'Fixture', GIT_COMMITTER_EMAIL: 'fixture@example.invalid'
};
// Most scenarios need real Git only. Avoid a cmd + Node + Git process tree for every harmless Git call.
// Keep the wrapper for every injected Git fault, late edit/status race and deliberate fetch hold.
function gitEnvironment(env) {
  return { ...env, PC_TEST_GIT: env.STUB_GIT_FAULT || env.STUB_CHECKOUT_EDIT || env.STUB_RECHECK_FAIL || env.STUB_FETCH_HOLD ? gitStub : gitPath };
}
// Copy the launchers and run their real helpers through the warm fixture shell.
// Only the agent watchdog is replaced. Its preflight kill path and the separate
// runner_stall_tests row still exercise the real timeout code.
function fixtureTools(name, scenario = '') {
  const dir = path.join(root, name);
  for (const file of ['codex_issue.bat', 'codex_issue.ps1', 'work_issue.bat', 'work_issue.ps1', 'runner_common.ps1', 'review_evidence.ps1', 'run_timeout.ps1', 'gpu_slots.js', 'janitor.ps1', 'janitor_salvage.ps1', 'janitor.bat']) {
    let body = read(path.join(here, file));
    if (file.endsWith('.bat')) {
      body = body.replace(/powershell -NoProfile (?:-ExecutionPolicy Bypass )?(?=-File |-Command "(?:\(Get-Date\)|Get-Date -Format))/g,
        'node "%RUNNER_FIXTURE_PS%" ').replace(/\r?\n/g, '\r\n');
      if (scenario === 'accounting' && file === 'work_issue.bat') {
        body = body.replace(/(%PS% openai-(?:budget|spend)[^\r\n]*)"%DRY%"/g, '$1"0"')
          .replace('set "PUSHMODE=dry"', 'set "PUSHMODE=test"');
      }
      if (scenario === 'delivery' && file === 'work_issue.bat') {
        // Keep dryrun's mock agent and fake GitHub. Exercise real delivery logic against a bare TEMP remote.
        body = body.replace('set "PUSHMODE=dry"', 'set "PUSHMODE=real"');
      }
    }
    write(path.join(dir, file), body);
  }
  write(path.join(dir, 'tmo.bat'), [
    '@echo off',
    'setlocal',
    'if not "%PC_RUNNER_TEST%"=="1" exit /b 125',
    'set "STUB_WATCHDOG_ARGS=%*"',
    'node "' + path.join(root, 'watchdog.js') + '"',
    'exit /b %ERRORLEVEL%'
  ].join('\r\n') + '\r\n');
  return dir;
}
write(path.join(root, 'watchdog.js'), `
const assert = require('assert');
const { spawnSync } = require('child_process');
const { COMSPEC, CODEX_TEST_AGENT, WORK_TEST_AGENT, STUB_WATCHDOG_ARGS } = process.env;
const [, exe, args] = /^\\d+ "([^"]+)" (.*)$/.exec(STUB_WATCHDOG_ARGS);
if (args === 'contrib\\\\opus\\\\tools\\\\run_all_checks.js') process.exit(Number(process.env.STUB_CHECKS_EXIT || 0));
if (args === '/c tools\\\\pc\\\\parity.bat nopause') process.exit(0);
let cmd;
if (exe.toLowerCase() === COMSPEC.toLowerCase()) {
  assert([CODEX_TEST_AGENT, WORK_TEST_AGENT].some(agent => args === '/d /s /c ""' + agent + '""'), args);
  cmd = args.slice('/d /s /c '.length);
} else {
  assert.strictEqual(exe, WORK_TEST_AGENT);
  cmd = '""' + exe + '" ' + args + '"';
}
const result = spawnSync(COMSPEC, ['/d', '/s', '/c', cmd], { windowsVerbatimArguments: true, windowsHide: true, stdio: 'inherit',
  timeout: process.env.STUB_AGENT_HOLD ? 45000 : 10000 });
if (result.error) throw result.error;
process.exitCode = result.status ?? 125;
`);
const tools = fixtureTools('launchers');
const faultTools = fixtureTools('accounting runner', 'accounting');
const deliveryTools = fixtureTools('delivery runner', 'delivery');
async function job(arm, label, extra = {}) {
  const home = extra.CODEX_TEST_ROOT || path.join(root, arm + '-' + label);
  fs.mkdirSync(home, { recursive: true });
  const temp = path.join(home, 'temp'); fs.mkdirSync(temp, { recursive: true });
  const env = gitEnvironment({ ...defaults, TEMP: temp, TMP: temp, TMPDIR: temp, PC_TEST_MIRROR: path.join(home, 'mirror.git'), WORK_ROOT: home, CODEX_TEST_ROOT: home, PC_TEST_TRACE: path.join(home, 'probe_args.txt'), PC_TEST_COUNTER: path.join(home, 'tries'),
    PC_TEST_GH_DB: path.join(home, 'gh-db.json'), PC_TEST_GH_TRACE: path.join(home, 'gh.jsonl'), ...extra });
  testPidFiles.push(env.PC_TEST_TRACE + '.pid');
  if (!fs.existsSync(env.PC_TEST_GH_DB)) {
    const db = gh.database(687, base);
    const prefix = arm === 'codex' ? 'codex' : 'work';
    if (label === 'same-seat') {
      db.branches.push({ name: prefix + '/issue-687' + (prefix === 'work' ? '-deepseek' : '') });
      db.pulls = [{ number: 700, head: { ref: prefix + '/issue-687' } }];
    }
    if (arm !== 'codex') db.issue.body = db.issue.body.replace('Effort (Codex): high\n', '').replace('Branch: codex/issue-687', `Branch: work/issue-687-${arm}`);
    if (label === 'moved-seat') db.issue.body = db.issue.body.replace('Branch: codex/issue-687', 'Branch: work/issue-687-openai');
    if (label === 'moved-arm') db.issue.body = db.issue.body.replace('Branch: work/issue-687-deepseek', 'Branch: work/issue-687-openai');
    if (label === 'moved-owner') db.issue.body = db.issue.body.replace('Owner: codex', 'Owner: muse');
    if (label === 'same-seat') db.issue.body = db.issue.body.replace('## THIS IS THE JOB NOW', '**Run 2: THIS IS THE JOB NOW.** Inline instructions.').replace('## Earlier run (DONE)', 'Run 1 (DONE):');
    if (label === 'closed') db.issue.state = 'closed';
    if (label === 'claimed') db.running = true;
    if (['other-pr', 'other-branch', 'other-branch-base'].includes(label)) {
      const branch = 'opus/issue-687';
      db.branches.push({ name: branch, commit: { sha: otherSeatTip } });
      db.comparisons[otherSeatTip] = { status: 'ahead' };
      if (label !== 'other-branch') db.issue.body = db.issue.body.replace('Done when:', `Base: ${branch}\nDone when:`);
      if (label === 'other-pr') db.pulls = [{ number: 700, head: { ref: branch } }];
    }
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
  const bat = path.join(extra.STUB_RUNNER_TOOLS || tools, arm === 'codex' ? 'codex_issue.bat' : 'work_issue.bat');
  const cmd = '""' + bat + '" 687' + (arm === 'codex' ? '' : ' ' + arm + ' dryrun') + '"';
  const r = await runEntryPoint(cmd, env);
  write(path.join(home, 'console.txt'), r.text);
  const latest = path.join(env.WORK_ROOT, 'dryrun-687-' + arm, 'latest.txt');
  assert(fs.existsSync(arm === 'codex' ? path.join(home, 'issue-687/status.json') : latest), r.text);
  const runHome = arm === 'codex' ? home : read(latest).trim();
  const out = path.join(runHome, arm === 'codex' ? 'issue-687' : 'out');
  const repo = arm === 'codex' ? path.join(runHome, 'repo') : path.join(env.WORK_ROOT, 'slot_' + arm, 'repo');
  return { ...r, out, repo, env, result: read(path.join(out, 'result.txt')), state: JSON.parse(read(path.join(out, 'status.json'))) };
}
const fixtureSetupSeconds = (Date.now() - started) / 1000;
console.log('Fixture setup: ' + fixtureSetupSeconds.toFixed(2) + ' s (tiny shared source and stubs; retry delay 0 s)');
async function testAccounting() {
  // Issue 985: exercise real PS accounting with only token fixtures, never a key or provider call.
  const spendRoot = path.join(root, 'openai accounting'); fs.mkdirSync(spendRoot, { recursive: true });
  const spendOut = path.join(spendRoot, 'out'); write(path.join(spendOut, 'result.txt'), '');
  const spendSettings = path.join(spendRoot, 'runner_settings.txt');
  const ledger = path.join(spendRoot, 'openai_spend.txt');
  const workPS = args => runScript('work_issue.ps1', args, defaults);
  const budget = (model = openaiDefault, dry = '0') => workPS(['openai-budget', spendOut, spendRoot, spendSettings, model, dry]);
  const spend = (out = spendOut, model = openaiDefault, dry = '0') => workPS(['openai-spend', '985', out, spendRoot, spendSettings, model, dry]);
  const rows = () => read(ledger).trim().split(/\r?\n/).filter(Boolean).map(s => JSON.parse(s));
  assert.equal((await workPS(['openai-key', spendOut])).code, 3);
  assert(read(path.join(spendOut, 'result.txt')).includes('no OpenAI API key saved: run OPENAI_API_KEY.bat'));
  assert.equal((await budget()).code, 0); // Missing setting defaults to 94.
  const event = (input, cached, output) => JSON.stringify({type:'step_finish',part:{tokens:{input,output,reasoning:100000,cache:{read:cached,write:0}}}}) + '\n';
  write(path.join(spendOut, 'events.jsonl'), event(1000000, 2000000, 3000000));
  write(path.join(spendOut, 'preflight_log.txt'), event(100000, 100000, 100000));
  assert.equal((await spend()).code, 0);
  assert.equal(rows()[0].model, openaiDefault);
  assert.equal(rows().length, 1); assert.equal(rows()[0].estimated_usd, 35.41);
  assert.equal(rows()[0].running_total_usd, 35.41); assert.equal(rows()[0].budget_usd, 94);
  assert.equal(rows()[0].input, 1100000); assert.equal(rows()[0].cached_input, 2100000); assert.equal(rows()[0].output, 3300000);
  assert.equal((await spend()).code, 0); assert.equal(rows().length, 1, 'finish must not double record');
  assert(read(path.join(spendOut, 'result.txt')).includes('OpenAI estimate USD: 35.41'));
  write(spendSettings, 'openai_budget_usd=35.41\n');
  assert.equal((await budget()).code, 3); assert(read(path.join(spendOut, 'result.txt')).includes('OpenAI budget reached'));
  assert.equal((await budget('openai/gpt-6.1-sol', '1')).code, 0, 'dry run ignores real spend');
  assert.equal((await budget('openai/gpt-6.1-sol')).code, 3, 'legacy model stays priced and shares the same budget');
  write(spendSettings, 'openai_budget_usd=36\n'); assert.equal((await budget()).code, 0);
  write(spendSettings, 'openai_budget_usd=oops\n'); assert.equal((await budget()).code, 3);
  write(spendSettings, 'openai_budget_usd=94\n'); assert.equal((await budget('openai/unpriced')).code, 3);
  const old = rows()[0]; old.date = '2000-01-01T00:00:00Z'; write(ledger, JSON.stringify(old) + '\n');
  write(spendSettings, 'openai_budget_usd=1\n'); assert.equal((await budget()).code, 0, 'previous month does not spend this month');
  const terraOut = path.join(spendRoot, 'terra'); write(path.join(terraOut, 'result.txt'), '');
  write(path.join(terraOut, 'events.jsonl'), event(1000000, 2000000, 3000000));
  assert.equal((await spend(terraOut, openaiReview)).code, 0);
  assert.equal(rows()[1].estimated_usd, 16.6); assert.equal(rows()[1].running_total_usd, 16.6);
  assert.equal((await budget()).code, 3, 'run crossing budget stops the next start');
  const beforeDry = read(ledger); assert.equal((await spend(terraOut, openaiReview, '1')).code, 0);
  assert.equal(read(ledger), beforeDry);
  const unknownOut = path.join(spendRoot, 'unknown'); write(path.join(unknownOut, 'result.txt'), '');
  write(path.join(unknownOut, 'preflight_log.txt'), '{"type":"error","error":{"message":"fixture failed probe"}}\n');
  assert.equal((await spend(unknownOut)).code, 3); assert.equal(rows()[2].status, 'unknown');
  write(spendSettings, 'openai_budget_usd=94\n'); assert.equal((await budget()).code, 3);
  assert(read(path.join(spendOut, 'result.txt')).includes('OpenAI usage unknown'));
  write(ledger, 'bad ledger\n'); assert.equal((await budget()).code, 3);
  pass('OpenAI missing key, named prices, probe plus agent usage, idempotent ledger, default/configured budget, dry isolation, month rollover and unknown-usage refusal');
}
async function testAccountingFaults() {
  // Run the real preservation path against our local remote. Only the TEMP copy enables live accounting in dryrun
  // and a local push; test agents and fake GitHub still isolate every provider and network operation.
  const ledgerHolder = path.join(root, 'ledger holder.ps1');
  write(ledgerHolder, `while (-not (Test-Path ($env:PC_TEST_TRACE + '.lock-request'))) { Start-Sleep -Milliseconds 25 }
$s = [IO.File]::Open((Join-Path $env:WORK_ROOT 'openai_spend.txt'), 'OpenOrCreate', 'ReadWrite', 'None')
try {
  [IO.File]::WriteAllText(($env:PC_TEST_TRACE + '.locked'), 'locked')
  while (-not (Test-Path ($env:PC_TEST_TRACE + '.release'))) { Start-Sleep -Milliseconds 25 }
} finally { $s.Dispose() }
`);
  await parallel(['missing', 'invalid', 'busy'], async fault => {
    const source = fixtureSource('accounting-' + fault);
    const extra = { STUB_RUNNER_TOOLS: faultTools, STUB_ACCOUNT_FAULT: fault,
      PC_TEST_STOP_BEFORE_PUBLISH: '0', PC_TEST_SOURCE: source };
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
    const checkoutBefore = read(path.join(r.repo, '.git', 'logs', 'HEAD'));
    const refused = await job('openai', 'account-' + fault, extra);
    assert.equal(refused.code, 3, refused.text + refused.result);
    assert.equal(refused.state.status, 'failed'); assert(refused.result.includes('OpenAI usage unknown'), refused.result);
    assert.equal(refused.repo, r.repo);
    assert(!fs.existsSync(path.join(refused.out, 'base_commit.txt')), 'next paid start refused before checkout');
    assert.equal(read(path.join(refused.repo, '.git', 'logs', 'HEAD')), checkoutBefore, 'refusal leaves the existing slot alone');
    assert.equal(read(r.env.PC_TEST_TRACE), probeBefore, 'next paid start never calls the probe');
    pass('OpenAI ' + fault + ' accounting: guarded partial push retains agent changes, never checked, next paid start refused');
  });
}
function assertOpenAIEffort(r, model, effort) {
  assert.equal(r.state.model, model);
  assert.equal(r.state.effort, effort);
  assert(r.result.includes('effort: ' + effort), r.result);
  assert.equal(read(path.join(r.out, 'model.txt')).trim(), model + ' --variant ' + effort);
  for (const trace of [r.env.PC_TEST_TRACE, r.env.PC_TEST_TRACE + '.agent']) {
    const args = JSON.parse(read(trace));
    assert.deepEqual(args.slice(args.indexOf('-m'), args.indexOf('-m') + 2), ['-m', model]);
    assert.deepEqual(args.slice(args.indexOf('--variant'), args.indexOf('--variant') + 2), ['--variant', effort]);
  }
}
async function testOpenAIModels() {
  const openaiOverride = await job('openai', 'override', { WORK_MODEL: openaiReview, WORK_EFFORT: 'MeDiUm' });
  assert.equal(openaiOverride.code, 0, openaiOverride.text + openaiOverride.result);
  assertOpenAIEffort(openaiOverride, openaiReview, 'medium');
  assert(openaiOverride.result.includes('differs from the arm default ' + openaiDefault));
  const wrongProvider = await job('openai', 'provider', { WORK_MODEL: 'anthropic/claude-opus-5-5' });
  assert.equal(wrongProvider.code, 0, wrongProvider.text + wrongProvider.result);
  assert.equal(wrongProvider.state.model, openaiDefault);
  const unpriced = await job('openai', 'unpriced', { WORK_MODEL: 'openai/unpriced' });
  assert.equal(unpriced.code, 3, unpriced.text + unpriced.result);
  assert(!fs.existsSync(unpriced.env.PC_TEST_TRACE)); assert(!fs.existsSync(unpriced.repo));
  pass('OpenAI medium review effort reaches probe and agent and is stamped, other provider ignored and unpriced model refused');
}
// Issue 860 run 2: exercise the real checkout with local Git data, never publish or discard fixture files.
async function checkoutFixture(source, label, prepare = () => {}, expectedKeep = false, options = {}) {
  const home = path.join(root, 'reuse-' + label), repo = path.join(home, 'repo'), out = path.join(home, 'out');
  fs.mkdirSync(home, { recursive: true }); write(path.join(out, 'result.txt'), '');
  assert.equal(run('git', ['clone', '-q', '-c', 'core.autocrlf=false', source, repo]).code, 0);
  const git = args => {
    const r = run('git', ['-C', repo, ...args]); assert.equal(r.code, 0, r.text); return r.text.trim();
  };
  prepare(repo, git);
  const existing = fs.readdirSync(home).filter(n => n.startsWith('repo-kept-'));
  const oldGit = fs.statSync(path.join(repo, '.git'));
  assert.equal((await ps(['init', out, 'fixture/reuse'], defaults)).code, 0);
  const env = gitEnvironment({ ...defaults, PC_TEST_SOURCE: source, PC_TEST_MIRROR: path.join(home, 'mirror.git'), STUB_CHECKOUT_MARKER: path.join(home, 'switch-hook.txt'), ...options.env });
  const r = await ps(['checkout', repo, out, 'fixture/reuse', ''], env);
  if (options.changed) {
    assert.equal(r.code, 14, r.text);
    assert(r.text.includes('checkout changed while starting; kept as is'), r.text);
    assert.equal(JSON.parse(read(path.join(out, 'status.json'))).status, 'failed');
    assert(fs.existsSync(env.STUB_CHECKOUT_MARKER), 'the edit hook ran between eligibility and the switch');
    assert.equal(fs.statSync(path.join(repo, '.git')).ino, oldGit.ino);
    assert.equal(fs.readdirSync(home).filter(n => n.startsWith('repo-kept-')).length, 0);
    assert(!r.text.includes('local clone attempt') && !r.text.includes('earlier checkout reused in place'), r.text);
    assert(!fs.existsSync(path.join(out, 'base_commit.txt')), 'stop before resume or agent work');
    assert.equal(read(path.join(repo, env.STUB_CHECKOUT_EDIT_PATH || 'progress.txt')), env.STUB_CHECKOUT_EDIT, 'late edit bytes survive');
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
async function testCleanAndCacheReuse() {
  const source = fixtureSource('reuse-clean');
  const refreshedMain = fixtureCommit({ 'progress.txt': 'base\n', 'upstream.txt': 'fresh upstream\n' }, base, '', source);
  let clean;
  try {
    clean = await checkoutFixture(source, 'clean-pushed', (repo, git) => {
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
  const ignored = await checkoutFixture(source, 'unique-ignored', repo => {
    write(path.join(repo, '.git/info/exclude'), 'unique work.blend\n');
    write(path.join(repo, 'unique work.blend'), 'unique ignored work');
  }, true);
  assert.equal(read(path.join(ignored.old, 'unique work.blend')), 'unique ignored work');
  pass('unique ignored file is kept aside and its bytes survive');
  const cache = await checkoutFixture(source, 'cache-only', repo => {
    write(path.join(repo, '.git/info/exclude'), 'godot/.godot/\ngodot/*.import\n');
    write(path.join(repo, 'godot/.godot/imported/cached.bin'), 'cached import');
    write(path.join(repo, 'godot/texture.png.import'), 'import settings');
  });
  assert.equal(read(path.join(cache.repo, 'godot/.godot/imported/cached.bin')), 'cached import');
  assert.equal(read(path.join(cache.repo, 'godot/texture.png.import')), 'import settings');
  pass('cache-only ignored files allow reuse and both cache files survive');
  // Issue 1379 (Artoo on PR 1529): the munition glbs keep their maps embedded, so an image beside them is work: an ignored
  // one named like the body's map, and one at the folder root with no body, both keep the checkout and survive.
  for (const [label, name] of [['munition-map-named', 'godot/fx/munition_bodies/corsair_rockets_corsair_rockets_hull_albedo.jpg'],
    ['munition-map-root', 'godot/fx/munition_bodies/stray_albedo.png']]) {
    const kept = await checkoutFixture(source, label, repo => {
      write(path.join(repo, '.git/info/exclude'), 'godot/fx/munition_bodies/*.jpg\ngodot/fx/munition_bodies/*.png\n');
      write(path.join(repo, name), 'hand-painted map');
    }, true);
    assert.equal(read(path.join(kept.old, name)), 'hand-painted map');
    assert(kept.text.includes('working tree needs keeping:'), kept.text);
    pass(label + ': an ignored image in godot/fx/munition_bodies keeps the checkout and its bytes');
  }
  const pythonCaches = {
    '__pycache__/root.cpython-312.pyc': 'root bytecode',
    'tools/blender/build_sheets/__pycache__/weapon_match.cpython-312.pyc': 'nested bytecode',
    'tools/__pycache__/nested/cache.bin': 'cache folder contents',
    'module.pyc': 'standalone bytecode',
    'tools/compiled/module.pyc': 'nested standalone bytecode'
  };
  const python = await checkoutFixture(source, 'python-caches', (repo, git) => {
    git(['checkout', '-q', '-b', 'fixture/old-pushed', partial]);
    write(path.join(repo, '.git/info/exclude'), '__pycache__/\n*.pyc\n');
    for (const [name, bytes] of Object.entries(pythonCaches)) write(path.join(repo, name), bytes);
  });
  for (const [name, bytes] of Object.entries(pythonCaches)) assert.equal(read(path.join(python.repo, name)), bytes);
  pass('pushed checkout with only ignored Python caches reuses in place and preserves every cache byte');
}
async function testSharedShipCopySafety() {
  const source = fixtureSource('reuse-ship-safety');
  const ship = 'godot/assets/ships/B16_23/armor plate.glb';
  const profile = path.join(root, 'ship-profile');
  const sharedShip = path.join(profile, 'Downloads/voidsworn_test/build', ship);
  write(sharedShip, 'hull-A');
  function copyShip(repo) {
    write(path.join(repo, '.git/info/exclude'), 'godot/assets/ships/*/\n');
    fs.mkdirSync(path.dirname(path.join(repo, ship)), { recursive: true });
    fs.copyFileSync(sharedShip, path.join(repo, ship));
  }
  const env = { USERPROFILE: profile };
  await checkoutFixture(source, 'late-shared-ship-edit', copyShip, false, {
    changed: true, env: { ...env, STUB_CHECKOUT_EDIT: 'hull-B', STUB_CHECKOUT_EDIT_PATH: ship }
  });
  pass('a byte change to a shared ship after eligibility stops the job and survives the switch');

  const linked = await checkoutFixture(source, 'linked-shared-ship', repo => {
    write(path.join(repo, '.git/info/exclude'), 'godot/assets/ships/*/\n');
    const linkedDir = path.dirname(path.join(repo, ship));
    fs.mkdirSync(path.dirname(linkedDir), { recursive: true });
    fs.symlinkSync(path.dirname(sharedShip), linkedDir, 'junction');
  }, true, { env });
  assert(linked.text.includes('shared ship copy could not be verified'), linked.text);
  assert(fs.lstatSync(path.dirname(path.join(linked.old, ship))).isSymbolicLink());
  assert.equal(read(path.join(linked.old, ship)), 'hull-A');
  pass('a junction to the shared build keeps the checkout and the junction');

  const collisionTip = fixtureCommit({ godot: 'incoming tracked file\n', 'progress.txt': 'base\n' }, base, '', source);
  const collision = await checkoutFixture(source, 'shared-ship-collision', repo => {
    copyShip(repo);
    write(path.join(source, 'refs/heads/main'), collisionTip + '\n');
  }, true, { env });
  assert(collision.text.includes('cache would be overwritten by incoming file: ' + ship), collision.text);
  assert.equal(read(path.join(collision.old, ship)), 'hull-A');
  assert.equal(read(path.join(collision.repo, 'godot')), 'incoming tracked file\n');
  assert.equal(read(sharedShip), 'hull-A');
  pass('an incoming tracked file that collides with an identical ship copy keeps the checkout and both copies');
}
async function testKeptLookalikes() {
  const source = fixtureSource('reuse-lookalikes');
  for (const [label, name, exclude] of [
    ['untracked-pyc', 'module.pyc', ''],
    ['untracked-pycache', 'tools/__pycache__/module.pyc', ''],
    ['other-ignored', 'notes.txt', 'notes.txt\n'],
    ['other-untracked', 'notes.txt', ''],
    ['pycache-lookalike', 'tools/__pycache__backup/module.bin', '__pycache__backup/\n'],
    ['pyc-lookalike', 'module.pyc.backup', '*.backup\n'],
    ['quoted-pyc', 'tools/folder with spaces/module.pyc', '*.pyc\n']
  ]) {
    const kept = await checkoutFixture(source, label, repo => {
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
}
async function testCampaignParityCleanup() {
  const home = path.join(root, 'campaign-parity'), dir = path.join(home, 'godot/campaign/test');
  const bat = path.join(home, 'tools/pc/parity_campaign.bat');
  write(bat, read(path.join(here, 'parity_campaign.bat')));
  write(path.join(home, 'godot/project.godot'), '');
  write(path.join(home, 'godot/campaign/data/campaign_tables.json'), '{"sha256":"fixture"}');
  write(path.join(dir, 'node/export_campaign.js'), 'require("fs").writeFileSync(process.argv[2], \'{"sha256":"fixture"}\');');
  write(path.join(dir, 'node/golden_campaign.js'), 'require("fs").writeFileSync(process.argv[3], process.argv[2]);');
  write(path.join(dir, 'node/compare_campaign.js'), `
    const fs = require('fs');
    const same = fs.readFileSync(process.argv[2]).equals(fs.readFileSync(process.argv[3]));
    console.log(same ? 'match' : 'fixture mismatch');
    process.exitCode = same ? 0 : 1;
  `);
  write(path.join(dir, 'node/cross_twin_handoff_test.js'), 'process.exitCode = 0;');
  write(path.join(home, 'compile.ps1'), `
$ErrorActionPreference = 'Stop'
Add-Type -TypeDefinition @'
using System;
using System.IO;
public static class CampaignFixture {
  public static int Main(string[] args) {
    int separator = Array.IndexOf(args, "--");
    if (separator < 0 || args[0] != "--headless") return 1;
    string folder = args[separator + 1];
    bool fail = Environment.GetEnvironmentVariable("PC_TEST_CAMPAIGN_MISMATCH") == "1";
    for (int i = separator + 2; i < args.Length; i++) {
      string seed = args[i];
      File.WriteAllText(Path.Combine(folder, "c" + seed + ".jsonl"), fail && seed == "1" ? "different" : seed);
    }
    return 0;
  }
}
'@ -OutputAssembly (Join-Path $PSScriptRoot 'godot.exe') -OutputType ConsoleApplication
  `);
  const built = run('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(home, 'compile.ps1')]);
  assert.equal(built.code, 0, built.text);
  write(path.join(home, 'godot_path.txt'), path.join(home, 'godot.exe') + '\r\n');
  const launch = mismatch => runEntryPoint('""' + bat + '" nopause"', {
    PATH: path.dirname(process.execPath) + path.delimiter + process.env.PATH,
    PC_TEST_CAMPAIGN_MISMATCH: mismatch
  });
  const failed = await launch('1');
  assert.equal(failed.code, 1, failed.text);
  assert(failed.text.includes('fixture mismatch'), failed.text);
  assert.equal(fs.readdirSync(path.join(dir, 'golden')).length, 30);
  assert.equal(fs.readdirSync(path.join(dir, 'out')).length, 32);
  assert.equal(read(path.join(dir, 'golden/c1.jsonl')), '1');
  assert.equal(read(path.join(dir, 'out/c1.jsonl')), 'different');
  assert(read(path.join(dir, 'parity_campaign_log.txt')).includes('fixture mismatch'));

  const succeeded = await launch('0');
  assert.equal(succeeded.code, 0, succeeded.text);
  assert(succeeded.text.includes('matches the game on all 30 seeded runs'), succeeded.text);
  assert.deepEqual(fs.readdirSync(path.join(dir, 'golden')), []);
  assert.deepEqual(fs.readdirSync(path.join(dir, 'out')), []);
  assert(read(path.join(dir, 'parity_campaign_log.txt')).includes('PASS'));
  pass('campaign parity batch keeps mismatch records and clears all generated output after a pass');
}
async function testLateCheckoutEdits() {
  const source = fixtureSource('reuse-late-edit');
  const lateEdit = 'tracked edit written during startup\r\n';
  const changed = await checkoutFixture(source, 'late-tracked-edit', () => {}, false, {
    changed: true, env: { STUB_CHECKOUT_EDIT: lateEdit }
  });
  assert.equal(run('git', ['-C', changed.repo, 'symbolic-ref', '--short', 'HEAD']).text.trim(), 'fixture/reuse');
  pass('tracked edit after eligibility survives the branch switch and stops the job with failed status');
  await checkoutFixture(source, 'late-status-failure', () => {}, false, {
    changed: true, env: { STUB_CHECKOUT_EDIT: lateEdit, STUB_RECHECK_FAIL: '1' }
  });
  pass('unreadable status after the branch switch fails closed and keeps late edit bytes');
  try {
    await checkoutFixture(source, 'late-edit-blocks-switch', () => write(path.join(source, 'refs/heads/main'), conflicting + '\n'), false, {
      changed: true, env: { STUB_CHECKOUT_EDIT: lateEdit }
    });
    pass('late tracked edit that blocks the branch switch survives and stops with the same clear message');
  } finally { write(path.join(source, 'refs/heads/main'), base + '\n'); }
}
async function testIncomingCheckoutCollisions() {
  const source = fixtureSource('reuse-collisions');
  for (const [label, incoming, cachePath] of [
    ['python-file-collision', 'module.pyc', 'module.pyc'],
    ['python-parent-collision', 'tools', 'tools/__pycache__/module.pyc']
  ]) {
    const tip = fixtureCommit({ [incoming]: 'incoming tracked file\n', 'progress.txt': 'base\n' }, base, '', source);
    write(path.join(source, 'refs/heads/main'), tip + '\n');
    try {
      const collision = await checkoutFixture(source, label, (repo, git) => {
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
  const collisionTip = fixtureCommit({ 'godot': 'incoming tracked file\n', 'progress.txt': 'base\n' }, base, '', source);
  write(path.join(source, 'refs/heads/main'), collisionTip + '\n');
  try {
    const collision = await checkoutFixture(source, 'cache-collision', (repo, git) => {
      git(['checkout', '-q', '--detach', base]);
      write(path.join(repo, '.git/info/exclude'), 'godot/.godot/\n');
      write(path.join(repo, 'godot/.godot/cache.bin'), 'cache must survive collision');
    }, true);
    assert.equal(read(path.join(collision.old, 'godot/.godot/cache.bin')), 'cache must survive collision');
    assert.equal(read(path.join(collision.repo, 'godot')), 'incoming tracked file\n');
    pass('incoming tracked path that collides with an ignored cache keeps the old checkout and cache intact');
  } finally { write(path.join(source, 'refs/heads/main'), base + '\n'); }
}
async function testKeptCheckoutHistory() {
  const source = fixtureSource('reuse-history');
  const privateTip = fixtureCommit({ 'progress.txt': 'private commit\n' }, base, '', source);
  const unpushed = await checkoutFixture(source, 'unpushed', (repo, git) => {
    git(['fetch', '-q', source, privateTip]);
    git(['checkout', '-q', '-b', 'fixture/private', privateTip]);
  }, true);
  assert.equal(read(path.join(unpushed.old, 'progress.txt')), 'private commit\n');
  assert.equal(run('git', ['-C', unpushed.old, 'rev-parse', 'HEAD']).text.trim(), privateTip);
  pass('unpushed commit is kept aside with its branch and work intact');
  const abandoned = await checkoutFixture(source, 'reflog-only', (repo, git) => {
    git(['fetch', '-q', source, privateTip]);
    git(['checkout', '-q', '--detach', privateTip]);
    git(['checkout', '-q', 'main']);
  }, true);
  assert(run('git', ['-C', abandoned.old, 'reflog', '--format=%H']).text.includes(privateTip));
  pass('unpushed history reachable only from the reflog is kept aside');
  const dirty = await checkoutFixture(source, 'dirty-tracked', repo => write(path.join(repo, 'progress.txt'), 'uncommitted edits\n'), true);
  assert.equal(read(path.join(dirty.old, 'progress.txt')), 'uncommitted edits\n');
  pass('dirty tracked file is kept aside with edits intact');
  const hidden = await checkoutFixture(source, 'hidden-tracked', (repo, git) => {
    git(['update-index', '--assume-unchanged', 'progress.txt']);
    write(path.join(repo, 'progress.txt'), 'hidden edits\n');
  }, true);
  assert.equal(read(path.join(hidden.old, 'progress.txt')), 'hidden edits\n');
  pass('index flags that hide tracked edits cause the checkout to be kept');
}
async function testClaimRules() {
  await parallel(['codex', 'deepseek', 'kimi', 'kimicode'], async arm => {
    await parallel([['closed', 'not an open job'], ['claimed', 'already carries running'],
      ['other-pr', 'open PR #700'], ['other-branch', 'delivery branch opus/issue-687 from another seat exists'], ['no-current', 'found 0'], ['two-current', 'found 2'],
      ['two-fixed', 'fixed blocks: 2']], async ([scenario, reason]) => {
      const r = await job(arm, scenario);
      assert.equal(r.code, 14, r.text + '\n' + r.result);
      assert.equal(r.state.status, 'failed'); assert(r.result.includes(reason), r.result);
      assert(!fs.existsSync(r.repo), 'refusal before checkout');
      assert(!fs.existsSync(r.env.PC_TEST_TRACE), 'refusal before model probe');
      const calls = read(r.env.PC_TEST_GH_TRACE).trim().split(/\r?\n/).filter(Boolean).map(l => JSON.parse(l));
      assert(calls.every(c => c.method === 'GET'), 'refusal cannot change another claim');
      assert.equal(JSON.parse(read(r.env.PC_TEST_GH_DB)).running, scenario === 'claimed');
      pass(arm + ': ' + scenario + ' refuses before checkout, probe or agent, with no GitHub writes');
    });
    const fromBase = await job(arm, 'other-branch-base');
    assert.equal(fromBase.code, 0, fromBase.text + '\n' + fromBase.result);
    assert(fromBase.result.includes("Base branch opus/issue-687 from another seat is this job's Base; does not block issue #687"), fromBase.result);
    assert.equal(read(path.join(fromBase.repo, 'other-seat.txt')), 'from the other seat\n');
    assert(fs.existsSync(path.join(fromBase.repo, 'agent_started.txt')), fromBase.result);
    pass(arm + ': other-seat branch named as Base passes validation, merges and starts the agent');
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
}
async function testClaimFailures() {
  await parallel(['codex', 'deepseek', 'kimicode'], async arm => {
    const failure = await job(arm, 'claim-failure', { PC_TEST_GH_FAIL: 'POST repos/rcbailey12/voidsworn/issues/687/comments' });
    assert.equal(failure.code, 14, failure.text + failure.result);
    assert(!fs.existsSync(failure.repo)); assert(!fs.existsSync(failure.env.PC_TEST_TRACE));
    assert(!JSON.parse(read(failure.env.PC_TEST_GH_DB)).running, 'failed comment claim rolls back its label');
    assert(failure.result.includes('cannot validate or claim job'), failure.result);
    pass(arm + ': failed status-comment claim stops before checkout or model calls and releases only its label');
  });
}
async function testAssignedBranch() {
  await parallel([
    ['codex', 'moved-seat', 'Branch: assigns'],
    ['deepseek', 'moved-arm', 'Branch: assigns'],
    ['codex', 'moved-owner', 'Owner: muse does not match']
  ], async ([arm, scenario, reason]) => {
    const r = await job(arm, scenario);
    assert.equal(r.code, 14, r.text + r.result);
    assert(r.result.includes(reason), r.result);
    assert(!fs.existsSync(r.repo) && !fs.existsSync(r.env.PC_TEST_TRACE), 'assignment refusal precedes checkout and model calls');
    const calls = read(r.env.PC_TEST_GH_TRACE).trim().split(/\r?\n/).map(l => JSON.parse(l));
    assert(calls.length && calls.every(c => c.method === 'GET'), 'assignment refusal precedes any claim');
    pass(arm + ': ' + scenario + ' refuses before any claim or agent call');
  });
  const override = 'fixture/assigned-issue-687';
  const source = fixtureSource('assigned-branch');
  write(path.join(source, 'refs/heads', override + '-partial'), partial + '\n');
  const r = await job('codex', 'test-push-override', { PC_TEST_SOURCE: source, CODEX_TEST_BRANCH: override });
  assert.equal(r.code, 0, r.text + r.result);
  assert.equal(r.state.branch, override);
  assert(fs.existsSync(path.join(r.repo, 'agent_started.txt')));
  pass('fixture push override still validates the issue against the actual Codex assignment');
}
async function testLaneOwnership() {
  const fixture = fs.mkdtempSync(path.join(root, 'lane-lock-'));
  const profile = path.join(fixture, 'profile');
  const home = path.join(profile, 'Downloads', 'voidsworn_test', 'board_d');
  const out = path.join(home, 'issue-687');
  const agentHold = path.join(fixture, 'agent hold');
  const finishHold = path.join(fixture, 'finish hold');
  const settings = path.join(fixture, 'runner_settings.txt');
  write(settings, 'min_free_gb=60\n');
  const commonEnv = { CODEX_TEST_ROOT: home, USERPROFILE: profile, PC_TEST_SETTINGS: settings, PC_TEST_SPACE_FREE_MB: '131072' };
  const waiting = job('codex', 'lane-lock', { ...commonEnv, STUB_AGENT_HOLD: agentHold, PC_TEST_GH_HOLD_FINISH: finishHold })
    .catch(error => ({ error }));
  async function waitForReady(hold, label) {
    const ready = hold + '.ready';
    let watcher;
    try {
      await Promise.race([
        new Promise((resolve, reject) => {
          const check = () => { if (fs.existsSync(ready)) resolve(); };
          watcher = fs.watch(fixture, check);
          watcher.on('error', reject);
          check();
        }),
        waiting.then(run => { throw run.error || new Error(label + '\n' + run.text + run.result); })
      ]);
    } finally {
      watcher?.close();
    }
  }
  async function refuse(issue) {
    const db = path.join(home, 'contender-gh.json');
    const trace = path.join(home, 'contender-gh.jsonl');
    write(db, JSON.stringify(gh.database(issue, base, { running: issue === 687 }))); write(trace, '');
    const r = await runEntryPoint('""' + path.join(tools, 'codex_issue.bat') + '" ' + issue + '"', {
      ...defaults, ...commonEnv, PC_TEST_MIRROR: path.join(home, 'mirror.git'), PC_TEST_GH_DB: db, PC_TEST_GH_TRACE: trace,
      PC_TEST_TRACE: path.join(home, 'contender-probe.txt')
    });
    assert.equal(r.code, 14, r.text);
    assert(r.text.includes('cannot take the Codex checkout lock'), r.text);
    assert.equal(read(trace), '', 'contender cannot contact GitHub or claim an issue');
    assert(!fs.existsSync(path.join(home, 'contender-probe.txt')));
  }
  let winner;
  try {
    await waitForReady(agentHold, 'mock agent never reached its checkout');
    assert(read(path.join(out, 'result.txt')).includes('has 128 GB free (min_free_gb floor 60)'), 'lane fixture must use fake space');
    const watched = [path.join(out, 'status.json'), path.join(out, 'result.txt'), path.join(home, 'repo', 'CODEX_TASK.md'),
      path.join(home, 'repo', '.git', 'HEAD'), path.join(home, 'repo', 'agent_started.txt')];
    const before = watched.map(read);
    await refuse(687);
    await refuse(688);
    assert.deepEqual(watched.map(read), before, 'the live checkout, work and run records must be untouched');
    assert(!fs.existsSync(path.join(home, 'issue-688')), 'a different issue cannot create its output folder on this lane');
    write(agentHold + '.release', 'agent may finish');
    await waitForReady(finishHold, 'runner never reached final reporting');
    assert.equal(JSON.parse(read(path.join(out, 'status.json'))).status, 'unverified', 'local state was already finalized');
    await refuse(687);
    const refresh = run('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
      path.join(here, 'lane_tools_refresh.ps1'), '-Build', 'build_e'], { USERPROFILE: profile });
    assert.equal(refresh.code, 1, refresh.text);
    assert(refresh.text.includes('Codex checkout lock is busy'), refresh.text);
  } finally {
    write(agentHold + '.release', 'released');
    write(finishHold + '.release', 'released');
    winner = await waiting;
  }
  if (winner.error) throw winner.error;
  assert.equal(winner.code, 0, winner.text + winner.result);
  const next = await job('codex', 'lane-lock-retry', commonEnv);
  assert.equal(next.code, 0, next.text + next.result);
  assert.notEqual(next.state.run, winner.state.run);
  pass('Codex refuses same-issue and different-issue launches before writes, blocks refresh during final reporting, and releases the lane');
}
async function testDeliveryCleanup() {
  await parallel([
    ['failed-checks', 'unverified', { STUB_CHECKS_EXIT: '1' }],
    ['partial', 'partial', { STUB_AGENT_EXIT: '1' }],
    ['ignored-work', 'checked_push', { STUB_IGNORED_WORK: '1' }],
    ['local-history', 'checked_push', {}],
    ['clean', 'checked_push', {}]
  ], async ([scenario, expected, extra]) => {
    const label = 'cleanup-' + scenario;
    const source = fixtureSource(label);
    const home = path.join(root, 'deepseek-' + label);
    if (scenario === 'local-history') {
      const privateObjects = path.join(home, 'private objects');
      extra.STUB_LOCAL_TIP = fixtureCommit({ 'local.txt': 'private history\n' }, partial, '', privateObjects);
      extra.STUB_LOCAL_OBJECTS = path.join(privateObjects, 'objects');
    }
    write(path.join(home, 'runner_settings.txt'), 'remove_repo_copy_after_push=yes\n');
    const r = await job('deepseek', label, { ...extra, STUB_RUNNER_TOOLS: deliveryTools,
      PC_TEST_STOP_BEFORE_PUBLISH: '0', WORK_SKIP_CHECKS: '0', PC_TEST_SOURCE: source });
    assert.equal(r.code, 0, r.text + r.result);
    const branch = 'work/issue-687-deepseek' + (scenario === 'partial' ? '-partial' : '');
    const tip = run('git', ['--git-dir', source, 'rev-parse', branch]);
    assert.equal(tip.code, 0, tip.text + r.result);
    assert.equal(read(path.join(r.out, 'confirmed_commit.txt')).trim(), tip.text.trim());
    assert.equal(r.state.status, expected, r.result);
    const publicStatus = JSON.parse(read(r.env.PC_TEST_GH_DB)).comments[0].body;
    const labelShown = expected === 'checked_push' ? 'finished' : expected;
    assert(publicStatus.includes('Runner status: ' + labelShown), publicStatus);
    assert(fs.existsSync(r.repo), 'the slot stays available after every outcome, even with the old cleanup setting');
    assert(!fs.existsSync(path.join(path.dirname(r.out), 'repo')), 'the run folder holds no clone');
    assert.match(r.result, /disk: run folder \d+ logical bytes/);
    assert.match(r.result, /disk: shared checkout \d+ logical bytes/);
    if (scenario === 'ignored-work') {
      assert.equal(read(path.join(r.repo, 'ignored-work.txt')), 'only in the checkout');
    }
    if (scenario === 'local-history') {
      assert.equal(read(path.join(r.repo, '.git/refs/remotes/origin/stale-local')).trim(), extra.STUB_LOCAL_TIP);
    }
    assert(fs.existsSync(path.join(r.out, 'result.txt')), 'run evidence stays after cleanup');
    pass('workhorse delivers and keeps the shared slot: ' + scenario);
  });
}
async function testWorkhorseSlots() {
  const workRoot = path.join(root, 'workhorse slots');
  const hold = path.join(root, 'workhorse-agent-hold');
  const options = { WORK_ROOT: workRoot, STUB_AGENT_NO_CHANGE: '1' };
  const first = await job('deepseek', 'slot-first', options);
  assert.equal(first.code, 0, first.text + first.result);
  assert.match(first.result, /code checkout excludes: docs\/shots, .*rocks_hi/);
  const gitDirectory = fs.statSync(path.join(first.repo, '.git')).ino;
  const second = await job('deepseek', 'slot-second', options);
  assert.equal(second.code, 0, second.text + second.result);
  assert.equal(second.repo, first.repo);
  assert.equal(fs.statSync(path.join(second.repo, '.git')).ino, gitDirectory);
  assert.match(second.result, /earlier checkout reused in place/);
  assert.notEqual(second.out, first.out);
  const firstResult = read(path.join(first.out, 'result.txt'));
  assert.equal(firstResult, first.result);

  write(path.join(first.repo, 'local-work.txt'), 'unpublished work');
  const running = job('deepseek', 'slot-held', { ...options, STUB_AGENT_HOLD: hold }).catch(error => ({ error }));
  let other;
  try {
    assert(await waitFor(() => fs.existsSync(hold + '.ready'), 30000), 'mock DeepSeek did not reach the slot');
    const repoHead = read(path.join(first.repo, '.git', 'HEAD'));
    const refused = await runEntryPoint('""' + path.join(tools, 'work_issue.bat') + '" 688 deepseek dryrun"', {
      ...defaults, WORK_ROOT: workRoot
    });
    assert.equal(refused.code, 14, refused.text);
    assert.match(refused.text, /workhorse slot busy/);
    assert(!fs.existsSync(path.join(workRoot, 'dryrun-688-deepseek')));
    assert.equal(read(path.join(first.repo, '.git', 'HEAD')), repoHead);
    other = await job('openai', 'slot-other-arm', options);
    assert.equal(other.code, 0, other.text + other.result);
    assert.notEqual(other.repo, first.repo);
  } finally {
    write(hold + '.release', 'released');
  }
  const held = await running;
  if (held.error) throw held.error;
  assert.equal(held.code, 0, held.text + held.result);
  assert.match(held.result, /working tree needs keeping: \?\? local-work\.txt/);
  const slot = path.dirname(first.repo);
  const kept = fs.readdirSync(slot).find(name => name.startsWith('repo-kept-'));
  assert.equal(read(path.join(slot, kept, 'local-work.txt')), 'unpublished work');
  const nextOpenai = await job('openai', 'slot-other-arm-again', options);
  assert.equal(nextOpenai.code, 0, nextOpenai.text + nextOpenai.result);
  assert.match(nextOpenai.result, /earlier checkout reused in place/);
  assert.notEqual(nextOpenai.out, other.out);
  pass('DeepSeek and OpenAI use separate reusable slots with per-run logs, a slot lock and preserved local work');

  // Artoo on PR 1250: stop only the PowerShell that took the slot lock. The batch it started keeps working, so the slot
  // must stay locked until that whole process tree has exited.
  const orphanHold = path.join(root, 'workhorse-orphan-hold');
  const slotLock = first.repo + '.checkout.lock';
  const lockFree = () => { try { fs.closeSync(fs.openSync(slotLock, 'r+')); return true; } catch { return false; } };
  const orphan = job('deepseek', 'slot-orphan', { ...options, STUB_AGENT_HOLD: orphanHold }).catch(error => ({ error }));
  try {
    assert(await waitFor(() => fs.existsSync(orphanHold + '.ready'), 30000), 'mock DeepSeek did not reach the slot');
    const holders = run('powershell.exe', ['-NoProfile', '-Command',
      "Get-CimInstance Win32_Process -Filter \"Name='powershell.exe'\" | Where-Object { $_.CommandLine -and " +
      "$_.CommandLine.Contains('work_issue.ps1\" run \"687\" \"deepseek\"') -and $_.CommandLine.Contains($env:ORPHAN_SLOT) } | " +
      'ForEach-Object { $_.ProcessId }'], { ORPHAN_SLOT: first.repo });
    const pids = holders.text.trim().split(/\s+/).filter(Boolean);
    assert.equal(pids.length, 1, 'exactly one slot lock holder: ' + holders.text);
    const killed = run('taskkill.exe', ['/PID', pids[0], '/F']);
    assert.equal(killed.code, 0, killed.text);
    const gone = () => { try { process.kill(Number(pids[0]), 0); return false; } catch (e) { return e.code === 'ESRCH'; } };
    assert(await waitFor(gone, 10000), 'the slot lock holder did not stop');
    // The batch is still parked in the mock agent, so its tree is alive. Its inherited output pipes keep the launcher's
    // promise open, so it is awaited only after the release below.
    assert(!fs.existsSync(orphanHold + '.release'));
    assert(!lockFree(), 'slot lock released while the batch still runs');
    const contender = await runEntryPoint('""' + path.join(tools, 'work_issue.bat') + '" 689 deepseek dryrun"', {
      ...defaults, WORK_ROOT: workRoot
    });
    assert.equal(contender.code, 14, contender.text);
    assert.match(contender.text, /workhorse slot busy/);
    assert(!fs.existsSync(path.join(workRoot, 'dryrun-689-deepseek')), 'the contender made no run folder');
  } finally {
    write(orphanHold + '.release', 'released');
  }
  await orphan;
  assert(await waitFor(lockFree, 90000), 'slot lock still held after the orphaned batch finished');
  const afterOrphan = await job('deepseek', 'slot-after-orphan', options);
  assert.equal(afterOrphan.code, 0, afterOrphan.text + afterOrphan.result);
  assert.equal(afterOrphan.repo, first.repo);
  pass('the slot lock outlives its PowerShell while the batch lives, refuses another issue, and frees when the batch ends');
}
async function testResumeAndFailures() {
  await parallel(arms, async arm => {
    const r = await job(arm, 'resume', arm === 'sonnet' ? { WORK_EFFORT: 'medium' } : {});
    assert.equal(r.code, 0, r.text + '\n' + r.result);
    assert(fs.existsSync(path.join(r.repo, 'agent_started.txt')), r.result);
    assert(read(path.join(r.out, arm === 'codex' ? 'CODEX_TASK.md' : 'WORK_TASK.md')).includes('Resumed by merging'));
    assert.equal(run('git', ['-C', r.repo, 'remote', 'get-url', 'origin']).text.trim(), source);
    assert(!fs.existsSync(path.join(r.repo, '.git/objects/info/alternates')));
    const probe = JSON.parse(read(r.env.PC_TEST_TRACE).trim());
    assert.equal(probe[0], arm === 'codex' ? 'exec' : arm === 'kimicode' ? '-m' : 'run');
    assert.equal(r.state.status, 'unverified');
    assert.equal(path.dirname(r.state.scratch.path), r.env.TEMP);
    assert.equal(read(path.join(r.state.scratch.path, 'agent-scratch.txt')), 'owned by the fixture');
    const expectModel = {
      codex: 'gpt-6.2-sol', kimicode: 'kimi-code/kimi-for-coding', kimi: 'moonshotai/kimi-k3.1-pro',
      opus: 'anthropic/claude-opus-5-5', sonnet: 'anthropic/claude-sonnet-5-5',
      openai: openaiDefault, deepseek: 'deepseek/deepseek-flash'
    }[arm];
    assert(r.result.includes('model: ' + expectModel), r.result);
    assert.equal(r.state.model, expectModel);
    if (arm === 'codex') { assert(r.result.includes('effort: high'), r.result); assert.equal(r.state.effort, 'high'); }
    assert(!r.result.includes('differs from the arm default'), r.result);
    assert(!JSON.parse(read(r.env.PC_TEST_GH_DB)).running, 'finished run releases its claim');
    if (arm === 'openai') {
      assertOpenAIEffort(r, openaiDefault, 'high');
      assert(r.result.includes('dry run, no spend recorded'), r.result);
      assert(read(path.join(r.out, 'stats.txt')).includes('OpenAI estimate USD:'));
      assert(!fs.existsSync(path.join(r.env.WORK_ROOT, 'openai_spend.txt')));
      pass('OpenAI default model and high effort reach probe and agent and are stamped');
    }
    if (arm === 'sonnet') {
      assert(r.text.includes('WORK_EFFORT ignored'), r.text);
      assert(!probe.includes('--variant'));
      assert.equal(r.state.effort, undefined);
      assert(!r.result.includes('effort:'));
      pass('Sonnet ignores a leftover WORK_EFFORT setting');
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
  const rerun = await job('codex','resume');
  const kept = fs.readdirSync(path.dirname(rerun.repo)).filter(n => n.startsWith('repo-kept-'));
  assert.equal(rerun.code,0); assert.equal(kept.length,1);
  assert(fs.existsSync(path.join(path.dirname(rerun.repo),kept[0],'agent_started.txt')));
  pass('Codex restart keeps the earlier checkout and its untracked work');
}
async function testGitRetries() {
  await parallel(['fetch-two', 'clone-two', 'clone-dead'], async fault => {
    const r = await job('deepseek', fault, { STUB_GIT_FAULT: fault });
    assert.equal(r.code, fault === 'clone-dead' ? 14 : 0, r.text + r.result);
    const op = fault.split('-')[0]; assert.equal(read(r.env.PC_TEST_COUNTER + '-' + op), '3');
    if (op === 'clone') assert.equal(fs.readdirSync(path.dirname(r.repo)).filter(n => n.startsWith('repo-clone-failed-')).length, fault === 'clone-dead' ? 3 : 2);
    pass(fault + ': retry count and failed checkout preservation');
  });
}
async function testHeldCheckout() {
  // A previous agent's current directory pins repo on Windows. Run the real preservation path, then free it.
  async function holder(home) {
    const repo = path.join(home, 'repo'); write(path.join(repo, 'keep.txt'), 'untracked work must survive');
    const child = spawn(process.execPath, ['-e', "const fs=require('fs'); fs.openSync('keep.txt','r'); console.log('READY'); setInterval(()=>{},1000);", repo], { cwd: repo, windowsHide: true });
    testChildren.push(child);
    await new Promise((resolve, reject) => { child.once('error', reject); child.stdout.once('data', resolve); child.once('exit', code => reject(new Error('holder exited: ' + code))); });
    return child;
  }
  async function startCheckout(home, env = {}) {
    const out = path.join(home, 'out'); write(path.join(out, 'result.txt'), '');
    assert.equal((await ps(['init', out, 'fixture/held'], defaults)).code, 0);
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
  const waiting = await startCheckout(pinnedHome);
  assert(await waitFor(() => waiting.text.includes('checkout rename held'), 20000), waiting.text);
  const other = await startCheckout(path.join(root, 'other-lane'));
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
  const expired = await startCheckout(stuckHome, { PC_TEST_KEEP_SECONDS: '0.3' });
  assert.equal(await expired.done, 14, expired.text);
  assert(expired.text.includes('checkout rename still held after 0.3 seconds'), expired.text);
  assert.equal(JSON.parse(read(path.join(expired.out, 'status.json'))).status, 'failed');
  assert.equal(read(path.join(stuckHome, 'repo/keep.txt')), 'untracked work must survive');
  assert.equal(fs.readdirSync(stuckHome).filter(n => n.startsWith('repo-kept-')).length, 0);
  stuck.kill(); await new Promise(resolve => stuck.once('exit', resolve));
  pass('rename wait expires cleanly with failed status and the original checkout intact');
}
async function testMergedPartial() {
  const mergedSource = fixtureSource('merged-partial-source');
  const main = fixtureCommit({ 'progress.txt': 'from partial\n', 'upstream.txt': 'later main work\n' }, partial, '', mergedSource);
  write(path.join(mergedSource, 'refs/heads/main'), main + '\n');
  write(path.join(root, 'codex-merged-partial', 'issue-687', 'resume.txt'), 'Resumed by merging an earlier partial');
  const trace = path.join(root, 'merged-partial-trace.jsonl');
  const merged = await job('codex', 'merged-partial', { PC_TEST_SOURCE: mergedSource, STUB_EXPECT_FRESH: '1', GIT_TRACE2_EVENT: trace });
  assert.equal(merged.code, 0, merged.text + '\n' + merged.result);
  assert(merged.result.includes(`skipping codex/issue-687-partial at ${partial}: already in HEAD`), merged.result);
  assert(!fs.existsSync(path.join(merged.out, 'resume.txt')));
  const commands = read(trace).trim().split(/\r?\n/).map(line => JSON.parse(line)).filter(event => event.event === 'cmd_name');
  assert(!commands.some(event => event.name === 'merge'), 'a partial already in HEAD must skip git merge');
  assert.equal(run('git', ['-C', merged.repo, 'rev-parse', 'HEAD']).text.trim(), main);
  assert.equal(read(path.join(merged.repo, 'agent_started.txt')), 'fresh start verified');
  pass('partial in HEAD skips git merge, logs why and starts fresh without resume.txt');

  const pending = await job('codex', 'unmerged-partial');
  assert.equal(pending.code, 0, pending.text + '\n' + pending.result);
  assert(pending.result.includes(`resuming codex/issue-687-partial at ${partial}`), pending.result);
  assert.equal(run('git', ['-C', pending.repo, 'rev-parse', 'HEAD']).text.trim(), partial);
  const note = read(path.join(pending.out, 'resume.txt'));
  assert(note.includes(`Resumed by merging codex/issue-687-partial (${partial})`), note);
  assert(note.includes('saved work before stopping'), note);
  assert.equal(read(path.join(pending.repo, 'agent_started.txt')), 'resumed work verified');
  pass('partial with new commits still merges and passes the saved resume note to the agent');
}
async function testResumeConflict() {
  const source = fixtureSource('conflicting-source');
  // A conflicting partial stops before preflight and leaves MERGE_HEAD and conflicted files intact.
  write(path.join(source, 'refs/heads/main'), conflicting + '\n');
  const conflict = await job('codex', 'conflict', { PC_TEST_SOURCE: source });
  assert.notEqual(conflict.code, 0); assert(conflict.result.includes('resume merge failed'));
  assert(fs.existsSync(path.join(conflict.repo, '.git/MERGE_HEAD'))); assert(!fs.existsSync(conflict.env.PC_TEST_TRACE));
  write(path.join(source, 'refs/heads/main'), base + '\n');
  pass('resume conflict keeps the checkout and stops before model use');
}
async function testChainRelease() {
  const stateOut = path.join(root, 'states'); fs.mkdirSync(stateOut); write(path.join(stateOut, 'result.txt'), '');
  const consumerOut = path.join(root, 'consumer'); fs.mkdirSync(consumerOut); write(path.join(consumerOut, 'result.txt'), '');
  assert.equal((await ps(['init', consumerOut, 'fixture/consumer'], defaults)).code, 0);
  for (const [code, partialReason, push, checks, expected] of [
    ['0', '', 'real', '1', 'checked_push'], ['0', '', 'dry', '1', 'unverified'], ['0', '', 'real', '0', 'unverified'],
    ['0', 'agent exit 124', 'real', '1', 'partial'], ['7', '', 'real', '1', 'no_changes'], ['8', '', 'real', '1', 'failed'], ['10', '', 'real', '1', 'failed']
  ]) {
    assert.equal((await ps(['init', stateOut, 'fixture/issue-687'], defaults)).code, 0);
    write(path.join(stateOut, 'run_commit.txt'), partial);
    write(path.join(stateOut, 'confirmed_commit.txt'), partial);
    assert.equal((await ps(['finish', stateOut, code, partialReason, push, checks], defaults)).code, 0);
    assert.equal(JSON.parse(read(path.join(stateOut, 'status.json'))).status, expected);
    const wait = await ps(['wait', consumerOut], { ...defaults, PC_WAIT_FOR: path.join(stateOut, 'status.json') });
    assert.equal(wait.code, expected === 'checked_push' ? 0 : 14, wait.text);
  }
  pass('only a confirmed non-partial real push with passing checks releases a chain');
  assert.equal((await ps(['init', stateOut, 'fixture/issue-687'], defaults)).code, 0);
  write(path.join(stateOut, 'run_commit.txt'), partial);
  assert.equal((await ps(['finish', stateOut, '0', '', 'real', '1'], defaults)).code, 0);
  assert.equal(JSON.parse(read(path.join(stateOut,'status.json'))).status,'unverified');
  pass('a success exit without push confirmation cannot release a chain');
  const missing = await ps(['wait', stateOut], { ...defaults, PC_WAIT_FOR: path.join(root, 'old-result.txt') });
  assert.equal(missing.code, 14);
  pass('missing or legacy predecessor status fails closed');
  assert.equal((await ps(['init', stateOut, 'fixture/issue-687'], defaults)).code, 0);
  assert.equal((await ps(['wait', consumerOut], { ...defaults, PC_WAIT_FOR: path.join(stateOut, 'status.json'), PC_WAIT_SECONDS: '1' })).code, 14);
  assert.equal((await ps(['wait', consumerOut], { ...defaults, PC_WAIT_FOR: path.join(stateOut, 'status.json'), PC_WAIT_RUN: 'older-run' })).code, 14);
  pass('unfinished predecessor times out; a stale run id stops the chain');
}
async function testProbeTimeout() {
  const deniedKiller = path.join(root, 'denied taskkill.bat'); write(deniedKiller, '@echo off\r\necho Access denied\r\nexit /b 5\r\n');
  const slow = await job('codex', 'preflight-timeout', { STUB_PROBE_TIMEOUT: '1', PC_TEST_PREFLIGHT_SECONDS: '1', PC_TEST_TASKKILL: deniedKiller });
  assert.equal(slow.code, 14); assert(slow.result.includes('timed out after 1 seconds')); assert(!fs.existsSync(path.join(slow.repo, 'agent_started.txt')));
  assert(read(path.join(slow.out, 'preflight_kill_log.txt')).includes('kill verified:'), slow.result);
  const slowPid = Number(read(slow.env.PC_TEST_TRACE + '.pid'));
  assert.throws(() => process.kill(slowPid, 0), e => e.code === 'ESRCH', 'preflight probe survived denied taskkill');
  testPidFiles.splice(testPidFiles.indexOf(slow.env.PC_TEST_TRACE + '.pid'), 1);
  pass('preflight timeout kills the probe tree and stops the job');
}
async function testMirrorAndConfirmation() {
  const source = fixtureSource('confirmation-source');
  const mirror = path.join(root, 'confirmation mirror.git');
  // Release the first fetch as soon as the second checkout reports lock contention.
  async function concurrentCheckout(n, hold = '') {
    const home = path.join(root, 'concurrent-' + n); fs.mkdirSync(home); const out = path.join(home, 'out'); fs.mkdirSync(out); write(path.join(out, 'result.txt'), '');
    assert.equal((await ps(['init', out, 'fixture/concurrent-' + n], defaults)).code, 0);
    const env = { ...process.env, ...gitEnvironment({ ...defaults, PC_TEST_SOURCE: source, PC_TEST_MIRROR: mirror, STUB_FETCH_HOLD: hold }) };
    const args = ['-NoProfile','-ExecutionPolicy','Bypass','-File',path.join(here,'runner_common.ps1'),'checkout',path.join(home,'repo'),out,'fixture/concurrent-' + n,''];
    const p = spawn('powershell.exe', args, { cwd: root, env, windowsHide: true, timeout: 45000 });
    testChildren.push(p);
    const state = { text: '' };
    p.stdout.on('data', b => state.text += b);
    p.stderr.on('data', b => state.text += b);
    p.once('error', e => state.text += e.message);
    state.done = new Promise(resolve => {
      p.once('close', code => {
        write(path.join(home, 'console.txt'), state.text);
        resolve({ code, text: state.text });
      });
    });
    return state;
  }
  const hold = path.join(root, 'mirror-fetch');
  const first = await concurrentCheckout(1, hold);
  let second, concurrent;
  try {
    assert(await waitFor(() => fs.existsSync(hold + '.ready'), 20000), first.text);
    second = await concurrentCheckout(2);
    assert(await waitFor(() => second.text.includes('waiting for the shared repo copy'), 20000), second.text);
  } finally {
    write(hold + '.release', 'contender saw the lock');
    concurrent = await Promise.all([first.done, second?.done]);
  }
  assert(concurrent.every(r => r.code === 0), JSON.stringify(concurrent));
  assert(concurrent.some(r => r.text.includes('waiting for the shared repo copy')), JSON.stringify(concurrent));
  pass('two simultaneous jobs serialize mirror fetch and local clone');
  const confirmationOut = path.join(root,'confirmation'); fs.mkdirSync(confirmationOut); write(path.join(confirmationOut,'result.txt'),'');
  assert.equal((await ps(['init',confirmationOut,'fixture/pushed'],defaults)).code,0);
  const confirmationRepo = path.join(root,'concurrent-1','repo');
  write(path.join(source,'refs/heads/fixture/pushed'),partial + '\n');
  write(path.join(confirmationOut,'pre_commit.txt'),base); write(path.join(confirmationOut,'run_commit.txt'),partial);
  write(path.join(confirmationOut,'diff_numstat.txt'),run('git',['-C',confirmationRepo,'diff','--numstat','--no-renames',base,partial]).text);
  const confirmed = await runScript('work_issue.ps1', ['confirm', confirmationRepo, confirmationOut, 'fixture/pushed', 'real'], defaults);
  assert.equal(confirmed.code,0,confirmed.text); assert.equal(read(path.join(confirmationOut,'confirmed_commit.txt')),partial);
  assert.equal((await ps(['finish',confirmationOut,'0','','real','1'],defaults)).code,0);
  assert.equal(JSON.parse(read(path.join(confirmationOut,'status.json'))).status,'checked_push');
  pass('real Git remote confirmation writes the marker required for chain success (fixture ref, no push)');
}
async function testRunnerStartChecks() {
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
  assert.equal((await ps(['init', modelOut, 'fixture/model'], defaults)).code, 0);
  assert.equal((await ps(['model', modelOut, 'provider/x', 'provider/y'], defaults)).code, 0);
  const modelResult = read(path.join(modelOut, 'result.txt'));
  assert(modelResult.includes('model: provider/x') && modelResult.includes('WARNING: resolved model provider/x differs from the arm default provider/y'), modelResult);
  assert.equal(JSON.parse(read(path.join(modelOut, 'status.json'))).model, 'provider/x');
  pass('model mode stamps status.json and result.txt and warns on any difference');
  // Below the floor the run refuses to start: one line in result.txt, status failed. min_free_gb is a tuning value
  // in runner_settings.txt; a missing line or file keeps the 60 default.
  const setFix = path.join(root, 'space_settings.txt'); write(setFix, 'remove_repo_copy_after_push=no\nmin_free_gb=60\n');
  const spaceOut = path.join(root, 'spacefloor'); fs.mkdirSync(spaceOut); write(path.join(spaceOut, 'result.txt'), '');
  assert.equal((await ps(['init', spaceOut, 'fixture/space'], defaults)).code, 0);
  const low = await ps(['space', spaceOut, setFix, path.join(root, 'voidsworn_test')], { ...defaults, PC_TEST_SPACE_FREE_MB: '100' });
  assert.equal(low.code, 14, low.text);
  assert.equal(JSON.parse(read(path.join(spaceOut, 'status.json'))).status, 'failed');
  const lowResult = read(path.join(spaceOut, 'result.txt'));
  assert(lowResult.includes('refusing to start') && lowResult.includes('below the min_free_gb=60 floor'), lowResult);
  assert.equal((await ps(['space', spaceOut, setFix, path.join(root, 'voidsworn_test')], { ...defaults, PC_TEST_SPACE_FREE_MB: '70000' })).code, 0);
  write(path.join(root, 'space_settings_low.txt'), 'min_free_gb=1\n');
  assert.equal((await ps(['space', spaceOut, path.join(root, 'space_settings_low.txt'), path.join(root, 'voidsworn_test')], { ...defaults, PC_TEST_SPACE_FREE_MB: '2000' })).code, 0);
  assert.equal((await ps(['space', spaceOut, path.join(root, 'missing_settings.txt'), path.join(root, 'voidsworn_test')], { ...defaults, PC_TEST_SPACE_FREE_MB: '100' })).code, 14);
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
  const runnerFiles = ['codex_issue.bat', 'codex_issue.ps1', 'runner_common.ps1', 'work_issue.bat', 'work_issue.ps1', 'review_evidence.ps1', 'run_timeout.ps1', 'tmo.bat', 'gpu_slots.js', 'janitor.ps1', 'janitor_salvage.ps1', 'janitor.bat'];
  const hashesGood = path.join(root, 'board_hashes_good.txt');
  write(hashesGood, runnerFiles.map(n => crypto.createHash('sha256').update(fs.readFileSync(path.join(here, n))).digest('hex') + '  ' + n).join('\n') + '\n');
  const hashOut = path.join(root, 'hashcheck'); fs.mkdirSync(hashOut); write(path.join(hashOut, 'result.txt'), '');
  assert.equal((await ps(['init', hashOut, 'fixture/hash'], defaults)).code, 0);
  const hashesWritten = path.join(root, 'board_hashes_written.txt');
  assert.equal((await ps(['hashwrite', here, hashesWritten], defaults)).code, 0);
  assert.equal(read(hashesWritten), read(hashesGood));
  assert.equal((await ps(['hashcheck', hashOut, here, hashesGood], defaults)).code, 0);
  assert(read(path.join(hashOut, 'result.txt')).includes(`runner files match the Board hashes (${runnerFiles.length} checked)`));
  pass('hashwrite and hashcheck agree on the runner and watchdog files');
  const hashesBad = path.join(root, 'board_hashes_bad.txt');
  write(hashesBad, read(hashesGood).split('\n').map(l => l.endsWith('runner_common.ps1') ? '0'.repeat(64) + '  runner_common.ps1' : l).join('\n'));
  assert.equal((await ps(['hashcheck', hashOut, here, hashesBad], defaults)).code, 0);
  assert(read(path.join(hashOut, 'result.txt')).includes('WARNING: these runner files differ from the Board-copied hashes: runner_common.ps1'));
  assert.equal((await ps(['hashcheck', hashOut, here, path.join(root, 'no_such_hashes.txt')], defaults)).code, 0);
  assert(read(path.join(hashOut, 'result.txt')).includes('WARNING: no Board hashes file'));
  pass('a hash mismatch and a missing hashes file warn without stopping');
  const hashWarn = await job('deepseek', 'hashwarn', { PC_TEST_HASHES: hashesBad });
  assert.equal(hashWarn.code, 0, hashWarn.text + '\n' + hashWarn.result);
  assert(fs.existsSync(path.join(hashWarn.repo, 'agent_started.txt')));
  assert(hashWarn.result.includes('WARNING: these runner files differ'), hashWarn.result);
  pass('a run whose tools folder drifts from the Board hashes still starts and warns');
}
(async () => { try {
  shell = await require('./runner_selftest_shell')(root, concurrency, [here, tools, faultTools, deliveryTools]);
  // The held runner and its contenders must be able to reach the fixture shell without waiting on unrelated cases.
  await testLaneOwnership();
  await testWorkhorseSlots();
  await parallel([
    testAccounting, testAccountingFaults, testOpenAIModels,
    testCleanAndCacheReuse, testSharedShipCopySafety, testKeptLookalikes, testCampaignParityCleanup, testLateCheckoutEdits,
    testIncomingCheckoutCollisions, testKeptCheckoutHistory,
    testClaimRules, testClaimFailures, testAssignedBranch, testDeliveryCleanup, testResumeAndFailures, testGitRetries,
    testHeldCheckout, testMergedPartial, testResumeConflict, testChainRelease, testProbeTimeout,
    testMirrorAndConfirmation, testRunnerStartChecks
  ], check => check());
  shell.assertHealthy();
  const note = 'PASS runner687+722+860+985: ' + passed + ' checks, Windows entry points, local Git and stub agents only. Preservation commits and pushes use TEMP remotes only; no model usage.\nEvidence: ' + root + '\n';
  write(path.join(root, 'summary.txt'), note); console.log(note.trim());
} catch (e) { write(path.join(root, 'failure.txt'), e.stack); console.error('FAIL runner687: ' + e.stack + '\nEvidence: ' + root); process.exitCode = 1; }
finally {
  if (shell) await shell.close();
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
  // Issue 1180 (Board, Nov 20): a passing run removes its evidence root (several GB of clones per standing-checks run
  // filled TEMP). A failure keeps it for reading. rmSync removes junctions as links and never follows them.
  if (process.exitCode !== 1 && process.env.RUNNER_SELFTEST_KEEP !== '1') {
    try { fs.rmSync(root, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 }); console.log('Evidence removed after PASS: ' + root); }
    catch (e) { console.log('Evidence kept (could not remove: ' + e.message + '): ' + root); }
  } else console.log('Evidence kept: ' + root);
} })();
