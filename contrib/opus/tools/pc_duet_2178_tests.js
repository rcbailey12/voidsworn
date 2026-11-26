'use strict';
// The same fixtures run against the working tree or --base HEAD. No live queue, GitHub or GPU.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execFileSync, spawn, spawnSync } = require('node:child_process');
const repo = path.resolve(__dirname, '../../..');
const base = process.argv[2] === '--base' && process.argv[3];
const source = name => (base
  ? execFileSync('git', ['show', base + ':tools/pc/' + name], { cwd: repo, encoding: 'utf8' })
  : fs.readFileSync(path.join(repo, 'tools/pc', name), 'utf8')).replace(/\r\n/g, '\n');
if (process.platform !== 'win32') {
  console.log('PASS Windows-only issue 2178 fixtures not run on this host');
  process.exit(0);
}
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'runner 2178 '));
const env = { ...process.env };
for (const name of Object.keys(env)) {
  if (/token|api_?key|password|secret|^PC_TEST_|^TMO_|^PC_GPU_|^PC_RUNNER_/i.test(name)) delete env[name];
}
const cmd = process.env.ComSpec;
const dirs = name => {
  const dir = path.join(root, name);
  fs.mkdirSync(dir, { recursive: true });
  return dir;
};
const write = (file, text) => fs.writeFileSync(file, text);
const bat = (file, text) => write(file, text.replace(/\r?\n/g, '\r\n'));
const copy = (dir, name, text = source(name)) => {
  const dest = path.join(dir, name);
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  (name.endsWith('.bat') ? bat : write)(dest, text);
  return dest;
};
const read = file => fs.readFileSync(file, 'utf8').trim();
const run = (exe, args, options = {}) => spawnSync(exe, args, {
  cwd: root, env, encoding: 'utf8', windowsHide: true, timeout: 30000, ...options
});
const cmdArgs = file => ['/d', '/s', '/c', '""' + file + '""'];
const cmdRun = (file, options) => run(cmd, cmdArgs(file), { windowsVerbatimArguments: true, ...options });
const ps = (file, args, extraEnv) => run('powershell.exe',
  ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', file, ...args], { env: { ...env, ...extraEnv } });
const detail = r => r.stdout + r.stderr + (r.error || '');
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
const until = async (condition, message, ms = 12000) => {
  const end = Date.now() + ms;
  while (!condition()) {
    if (Date.now() >= end) throw Error(message);
    await delay(50);
  }
};
const children = [];
function start(file, cwd) {
  const child = spawn(cmd, cmdArgs(file), { cwd, env, windowsHide: true, windowsVerbatimArguments: true, stdio: ['ignore', 'pipe', 'ignore'] });
  children.push(child);
  const probe = { child, output: '', stopped: false };
  child.stdout.on('data', chunk => { probe.output += chunk; });
  child.on('close', () => { probe.stopped = true; });
  return probe;
}
async function withWatchers(name, laneB, fixture) {
  const dir = dirs(name), queue = path.join(dir, laneB ? 'queue_b' : 'queue');
  fs.mkdirSync(queue);
  fs.mkdirSync(path.join(dir, laneB ? 'build_b' : 'build'));
  const watcher = copy(dir, laneB ? 'watcher_b.bat' : 'watcher.bat');
  const offset = children.length;
  try { await fixture(dir, queue, () => start(watcher, dir)); }
  finally {
    for (const child of children.slice(offset)) {
      if (child.exitCode === null) child.kill();
    }
  }
}

const failures = [];
async function test(name, fixture) {
  try { await fixture(); console.log('PASS ' + name); }
  catch (e) { failures.push(name); console.error('FAIL ' + name + ' - ' + e.message); }
}
async function main() {
  await test('F3 one watcher per queue, isolated job exits, checked claims', async () => {
    for (const laneB of [true, false]) await withWatchers(laneB ? 'double B' : 'double A', laneB, async (dir, queue, launch) => {
      const one = launch();
      await until(() => one.output.includes('Watching'), 'first watcher did not start: ' + one.output);
      const two = launch();
      await until(() => two.stopped || two.output.includes('Watching'), 'second watcher did not settle');
      assert(two.stopped && /could not lock/.test(two.output), 'second watcher entered the queue: ' + two.output);
      const count = path.join(dir, 'ran.txt');
      bat(path.join(queue, 'fail.bat'), '@echo off\n>> "' + count + '" echo once\nexit 37\n');
      await until(() => fs.existsSync(path.join(queue, 'failed/fail.bat')), 'plain exit killed the watcher or lost the result');
      assert.match(read(path.join(queue, 'logs/fail.bat.log')), /finished, exit 37/);
      assert.equal(read(count), 'once');
      bat(path.join(queue, 'next.bat'), '@echo off\nexit /b 0\n');
      await until(() => fs.existsSync(path.join(queue, 'done/next.bat')), 'watcher did not continue after a failed job');
      const old = path.join(queue, 'running/conflict.bat');
      bat(old, '@exit /b 29\n');
      const pending = path.join(queue, 'conflict.bat');
      bat(pending, '@exit /b 0\n');
      bat(path.join(queue, 'unblocked.bat'), '@exit /b 0\n');
      await until(() => fs.existsSync(path.join(queue, 'done/unblocked.bat')), 'interrupted name blocked an unrelated job');
      assert.equal(read(old), '@exit /b 29');
      assert.equal(read(pending), '@exit /b 0');
    });
  });
  await test('F4 Board pause holds both queues and resumes them, with a bounded GPU wait default', async () => {
    for (const laneB of [true, false]) await withWatchers(laneB ? 'pause B' : 'pause A', laneB, async (dir, queue, launch) => {
      const flag = path.join(dir, 'gpu_go.txt'), pending = path.join(queue, 'held.bat');
      write(flag, 'GPU not cleared: paused by the Board at 12:13 for Ryan.\r\n');
      bat(pending, '@exit /b 0\n');
      const w = launch();
      await until(() => w.output.includes('Watching'), 'watcher did not start');
      await delay(600);
      assert(fs.existsSync(pending), 'a paused queue moved its job');
      assert(!fs.existsSync(path.join(queue, 'logs/held.bat.log')));
      write(flag, 'GPU cleared\r\n');
      await until(() => fs.existsSync(path.join(queue, 'done/held.bat')), 'resume did not release the queued job');
    });
    const dir = dirs('wait default'), wrapper = copy(dir, 'job_wrap.bat');
    bat(path.join(dir, 'tmo.bat'), '@exit /b 0\n');
    write(path.join(dir, 'runner_common.ps1'), 'exit 0\n');
    const driver = path.join(dir, 'driver.bat');
    bat(driver, '@echo off\nset "JW_HASHES="\nset "JW_TOOLS=%~dp0."\ncall "' + wrapper +
      '" init "%~dp0out" fixture ""\nif errorlevel 1 exit /b %ERRORLEVEL%\necho [%PC_GPU_WAIT_SECONDS%]\n');
    assert.match(detail(cmdRun(driver)), /\[3600\]/);
    assert.match(detail(cmdRun(driver, { env: { ...env, PC_GPU_WAIT_SECONDS: '17' } })), /\[17\]/);
  });
  await test('F5 retired Startup entry and one-line Codex queue history', () => {
    const dir = dirs('autostart'), appdata = path.join(dir, 'appdata');
    const startup = path.join(appdata, 'Microsoft/Windows/Start Menu/Programs/Startup');
    fs.mkdirSync(startup, { recursive: true });
    const retired = path.join(startup, 'voidsworn_codex_board.bat');
    bat(retired, '@echo stale\n');
    const r = cmdRun(copy(dir, 'autostart_on.bat'), { env: { ...env, APPDATA: appdata }, input: 'x\r\n' });
    assert.equal(r.status, 0, detail(r));
    assert(!fs.existsSync(retired), 'the retired Startup entry still exists');
    assert(fs.existsSync(path.join(startup, 'voidsworn_watcher.bat')));
    assert(fs.existsSync(path.join(startup, 'voidsworn_watcher_b.bat')));
    const profile = path.join(dir, 'profile');
    const list = path.join(profile, 'Downloads/voidsworn_test/board/queued.txt');
    fs.mkdirSync(path.dirname(list), { recursive: true });
    const filter = source('codex_issue.bat').split('\n').find(line => line.includes('board\\queued.txt'));
    const script = path.join(dir, 'usage-limit.bat');
    bat(script, '@echo off\nset "N=17"\n' + filter + '\nexit /b %ERRORLEVEL%\n');
    for (const [before, after] of [['789', '789'], ['17', ''], ['17\r\n27\r\n17\r\n5', '27\r\n5']]) {
      write(list, before);
      const hit = cmdRun(script, { env: { ...env, USERPROFILE: profile } });
      assert.equal(hit.status, 0, detail(hit));
      assert.equal(read(list), after);
    }
  });
  await test('F7 watcher never calls the janitor and checks its scheduled task', async () => {
    await withWatchers('janitor', false, async (dir, queue, launch) => {
      const trap = path.join(dir, 'janitor-started.txt');
      bat(path.join(dir, 'janitor.bat'), '@echo off\n> "' + trap + '" echo started\nexit /b 0\n');
      const w = launch();
      await until(() => w.output.includes('Watching'), 'watcher did not start');
      await delay(550);
      assert(!fs.existsSync(trap), 'watcher ran the janitor');
      assert.match(source('watcher.bat'), /schtasks \/query \/tn "Voidsworn Janitor".*WARNING:/i);
    });
  });
  const commonDir = dirs('common');
  const common = copy(commonDir, 'runner_common.ps1');
  const watchdog = copy(commonDir, 'run_timeout.ps1');
  copy(commonDir, 'gpu_slots.js');
  await test('W3 dead claim is recovered only when this PC owns the exact run', () => {
    const dir = dirs('claims');
    let out = dirs('claims/board_f/issue-2178'), checkout = dirs('claims/board_f/repo');
    const db = path.join(dir, 'github.json'), trace = path.join(dir, 'gh.jsonl');
    const gh = require('../../../tools/pc/runner_claim_fixture')(dir);
    const deletes = () => read(trace).split(/\r?\n/).filter(line => JSON.parse(line).method === 'DELETE').length;
    const branch = 'codex/issue-2178';
    write(db, JSON.stringify(gh.database(2178, 'a'.repeat(40))));
    const fake = { PC_RUNNER_TEST: '1', PC_TEST_GH: gh.fake, PC_TEST_GH_DB: db, PC_TEST_GH_TRACE: trace };
    const holder = path.join(dir, 'hold-issue-lock.ps1');
    write(holder, [
      'param($Common, $Out, $Checkout, $Branch)',
      "$lockPath = Join-Path (Split-Path -Parent $env:PC_TEST_GH_DB) 'issue-2178.lock'",
      "$lock = [IO.File]::Open($lockPath, 'OpenOrCreate', 'ReadWrite', 'Inheritable')",
      'try {',
      "  $env:PC_RUNNER_LOCKED_ISSUE = '2178'",
      "  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Common announce $Out 2178 codex $Checkout 100 'resume fixture' real $Branch",
      '  exit $LASTEXITCODE',
      '} finally { $lock.Dispose() }'
    ].join('\n'));
    const init = () => ps(common, ['init', out, branch, 'archive-codex'], fake);
    const claim = () => ps(holder, [common, out, checkout, branch], fake);
    const firstInit = init();
    assert.equal(firstInit.status, 0, detail(firstInit));
    const first = claim();
    assert.equal(first.status, 0, detail(first));
    const firstRun = JSON.parse(read(path.join(out, 'status.json'))).run;
    assert(JSON.parse(read(db)).running, 'first runner claimed the issue');
    out = dirs('claims/board_e/issue-2178');
    checkout = dirs('claims/board_e/repo');
    const retryInit = init();
    assert.equal(retryInit.status, 0, detail(retryInit));
    const retry = claim();
    assert.equal(retry.status, 0, detail(retry));
    const current = JSON.parse(read(db));
    assert.equal(deletes(), 1);
    assert(current.running && !current.comments[0].body.includes(firstRun));
    fs.renameSync(path.join(dir, 'issue-2178.lock.claim.json'), path.join(dir, 'saved-fixture-receipt.json'));
    assert.equal(init().status, 0);
    const legacy = claim();
    assert.equal(legacy.status, 0, detail(legacy));
    const changed = JSON.parse(read(db));
    assert.equal(deletes(), 2, 'local status must also recover a claim from before receipts');
    changed.comments[0].body = changed.comments[0].body.replace(/- Run: [a-f0-9]{32}/, '- Run: ' + 'f'.repeat(32));
    write(db, JSON.stringify(changed));
    assert.equal(init().status, 0);
    const foreign = claim();
    assert.equal(foreign.status, 14, detail(foreign));
    assert.match(detail(foreign), /already carries running/);
    assert.equal(deletes(), 2, 'a foreign claim must not be cleared');
  });
  await test('W4 a silent CPU-active grandchild reaches the ceiling, not the stall stop', () => {
    const dir = dirs('silently busy'), work = dirs('silently busy/repo'), out = dirs('silently busy/out');
    const g = run('git', ['init', '-q', work]);
    assert.equal(g.status, 0, detail(g));
    const tree = run('git', ['-C', work, 'mktree'], { input: '' });
    assert.equal(tree.status, 0, detail(tree));
    const who = 'Fixture <fixture@example.invalid> 1700000000 +0000';
    const head = run('git', ['-C', work, 'hash-object', '-w', '-t', 'commit', '--stdin'],
      { input: 'tree ' + tree.stdout.trim() + '\nauthor ' + who + '\ncommitter ' + who + '\n\nFixture\n' });
    assert.equal(head.status, 0, detail(head));
    write(path.join(work, '.git/refs/heads/fixture'), head.stdout.trim() + '\n');
    const ref = run('git', ['-C', work, 'symbolic-ref', 'HEAD', 'refs/heads/fixture']);
    assert.equal(ref.status, 0, detail(ref));
    const agent = path.join(dir, 'agent.js'), leaf = path.join(dir, 'leaf.js'), child = path.join(dir, 'child.js');
    write(leaf, 'for (;;) Math.sqrt(Math.random());');
    write(child, 'require("node:child_process").spawn(process.execPath, [' + JSON.stringify(leaf) + '], { stdio:"ignore" }); setInterval(() => {}, 1000);');
    write(agent, 'require("node:child_process").spawn(process.execPath, [' + JSON.stringify(child) + '], { stdio:"ignore" }); setInterval(() => {}, 1000);');
    const log = path.join(out, 'log.txt');
    write(log, '');
    const result = ps(watchdog, [], {
      TMO_ARGS: '6 "' + process.execPath + '" "' + agent + '"',
      TMO_REPO: work, TMO_OUT: out, TMO_LOG: log, STALL_MIN: '0.04',
      PC_RUNNER_TEST: '1', PC_TEST_POLL_MS: '100', PC_TEST_SCAN_S: '0.2', PC_TEST_TIMEOUT_LOG: path.join(out, 'timeouts.log')
    });
    assert.equal(result.status, 124, detail(result));
    assert.equal(read(path.join(out, 'stop_reason.txt')), 'CEILING');
  });
  await test('W5 queued jobs and A2 return the real watchdog exit', () => {
    const dir = dirs('queued exits'), profile = path.join(dir, 'profile');
    const vt = path.join(profile, 'Downloads/voidsworn_test');
    fs.mkdirSync(path.join(vt, 'work217/tools'), { recursive: true });
    bat(path.join(vt, 'work217/tools/tmo.bat'), '@echo off\nset "RAW=%*"\n%RAW:~6%\nexit /b %ERRORLEVEL%\n');
    const actual = { env: { ...env, USERPROFILE: profile }, cwd: dir };
    const exits = [];
    for (const [wrapper, job] of [['q_paint_642','E11_E12_PAINT_642'], ['q_a633','A18_A20_RUN_633'], ['q_c1153','C12_RUN_1153']]) {
      bat(path.join(vt, job + '.bat'), '@exit /b 37\n');
      const r = cmdRun(copy(dir, 'jobs/' + wrapper + '.bat'), actual);
      exits.push(r.status);
    }
    fs.mkdirSync(path.join(dir, 'a2detail'));
    write(path.join(dir, 'a2detail/a2_ship.py'), '');
    const py = path.join(dir, 'fake-py.bat');
    bat(py, '@exit /b 0\n');
    bat(path.join(dir, 'tmo.bat'), '@echo off\nif "%~6"=="a2detail\\reimport.py" exit /b 37\nexit /b 0\n');
    const a2 = source('jobs/a2_detail.bat').replace(/^set PY=.*$/m, 'set PY=call "' + py + '"');
    const build = path.join(dir, 'build');
    fs.mkdirSync(build);
    fs.renameSync(path.join(dir, 'a2detail'), path.join(build, 'a2detail'));
    const r = cmdRun(copy(dir, 'jobs/a2_detail.bat', a2), { ...actual, cwd: build });
    exits.push(r.status);
    assert.deepEqual(exits, [37, 37, 37, 37], detail(r));
  });
  await test('W6 runner push disables Git and GCM prompts and preserves the failure code', () => {
    const dir = dirs('push'), git = path.join(dir, 'fake-git.bat'), stub = path.join(dir, 'fake-git.js');
    const trace = path.join(dir, 'args.json');
    bat(git, '@echo off\n"' + process.execPath + '" "' + stub + '" %*\nexit /b %ERRORLEVEL%\n');
    write(stub, "const fs = require('node:fs'); const e = process.env; " +
      "fs.writeFileSync(e.FIXTURE_TRACE, JSON.stringify({ args:process.argv.slice(2), prompt:e.GIT_TERMINAL_PROMPT," +
      "gcm:e.GCM_INTERACTIVE, askpass:e.GIT_ASKPASS || '', ssh:e.SSH_ASKPASS || '' })); process.exit(47);");
    const r = ps(common, ['push', dir, 'fixture/no-remote', 'dry'], {
      PC_RUNNER_TEST: '1', PC_TEST_GIT: git, FIXTURE_TRACE: trace,
      GIT_TERMINAL_PROMPT: '1', GCM_INTERACTIVE: 'always', GIT_ASKPASS: 'fake-prompt.exe', SSH_ASKPASS: 'fake-ssh-prompt.exe'
    });
    assert.equal(r.status, 47, detail(r));
    const got = JSON.parse(read(trace));
    assert.deepEqual([got.prompt, got.gcm, got.askpass, got.ssh], ['0', 'never', '', '']);
    for (const arg of ['credential.interactive=false', 'core.askPass=', 'http.lowSpeedLimit=1000', 'http.lowSpeedTime=60',
      'push', '--dry-run', 'HEAD:refs/heads/fixture/no-remote']) assert(got.args.includes(arg), arg);
    for (const runner of ['codex_issue.bat', 'work_issue.bat']) assert.match(source(runner), /%COMMON% push /);
    assert.match(source('lane_tools_refresh.ps1'), /http\.lowSpeedLimit=1000.*http\.lowSpeedTime=60/);
  });
  await test('N1 every rerun keeps the prior evidence and failed push patch by the job', () => {
    const dir = dirs('run history'), branch = 'codex/issue-2178';
    const evidence = ['last.md','result.txt','log.txt','push_failed.patch','CODEX_TASK.md'];
    for (const number of [1, 2]) {
      for (const file of evidence) write(path.join(dir, file), number + ':' + file);
      const r = ps(common, ['init', dir, branch, 'archive-codex']);
      assert.equal(r.status, 0, detail(r));
    }
    const archives = fs.readdirSync(path.join(dir, 'runs')).filter(name => name.startsWith('previous-'));
    assert.equal(archives.length, 2);
    for (const file of evidence) {
      assert.deepEqual(archives.map(name => read(path.join(dir, 'runs', name, file))).sort(), ['1:' + file, '2:' + file]);
    }
    assert(!fs.existsSync(path.join(dir, 'last.md')), 'a new run must not present the last run message as its own');
    assert.match(source('codex_issue.bat'), /git diff --binary --output="%O%\\push_failed\.patch"/);
  });
}
main().catch(e => { failures.push('fixture'); console.error(e); }).finally(async () => {
  for (const child of children) if (child.exitCode === null) child.kill();
  await delay(150);
  // Only remove the fresh fixture root, never the PC's real queue or job history.
  fs.rmSync(root, { recursive: true, force: true, maxRetries: 4 });
  process.exitCode = failures.length ? 1 : 0;
  if (!failures.length) console.log('PASS issue 2178 Windows runner regressions (9 items)');
});
