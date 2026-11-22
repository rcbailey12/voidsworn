'use strict';
// Issue 1180: tools/pc/helper_clone.ps1 is the one shared base for helper PC jobs. A static contract, then live fixtures
// under PowerShell (pwsh in CI): a repeat run keeps a unique local ship file, a second run cannot touch a checkout whose
// job is still running (Artoo on PR 1275), and release removes only this folder's own copies after a relayed PASS.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawn, spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '../../..');
const script = path.join(root, 'tools/pc/helper_clone.ps1');
const ps = fs.readFileSync(script, 'utf8');
const bat = fs.readFileSync(path.join(root, 'tools/pc/helper_clone.bat'), 'utf8');
const code = ps.split(/\r?\n/).filter(line => !line.trim().startsWith('#')).join('\n');
assert.match(code, /clone --local -q --no-checkout \$mirror \$repo/, 'clones from the shared mirror with shared objects');
assert.match(code, /\$mirror \+ '\.lock', 'OpenOrCreate', 'ReadWrite', 'None'/, 'takes the same mirror lock as the runners');
assert.match(code, /'\.voidsworn-run-active'\), 'OpenOrCreate', 'ReadWrite', 'None'/, 'holds the job lease');
assert.match(code, /status --porcelain --untracked-files=no/, 'checks a reused clone for local edits first');
assert.match(code, /rev-list HEAD --not --remotes=origin/, 'checks a reused clone for local-only commits first');
assert.match(code, /StartsWith\(\$vt \+ \$sep/, 'job folder must be under voidsworn_test');
assert.match(code, /get_ship_files\.bat/, 'ships come from the checked copy step');
for (const banned of [/reset\s+--hard/, /checkout\s+(-q\s+)?-f\b/, /--force/, /\bclean\s+-/, /HardLink|mklink|SymbolicLink/i]) {
  assert.doesNotMatch(code, banned, `helper_clone.ps1 must not use ${banned}`);
}
assert.match(bat, /-JobDir "%~1" -Branch "%~2" -Ships "%~3" -Steps "%~4"/);
assert.match(bat, /if \/i "%~2"=="release"/);
assert.match(bat, /exit \/b %ERRORLEVEL%/);

const windows = process.platform === 'win32';
const shell = windows ? 'powershell.exe' : 'pwsh';
if (windows || spawnSync(shell, ['-NoProfile', '-Command', 'exit 0']).error) {
  if (process.env.CI && !windows) throw new Error(`${shell} is required in CI`);
  console.log('SKIP helper clone fixtures: they need pwsh and sh (Linux CI runs them)');
  console.log('PASS helper clone: static contract');
  process.exit(0);
}
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'helper-clone-proof-'));
const vt = path.join(tmp, 'vt');
const source = path.join(tmp, 'source.git');
const job = path.join(vt, 'opus901');
const shipRel = path.join('assets', 'ships', 'T1_11', 'T1_11.glb');
const buildShip = path.join(vt, 'build', 'godot', shipRel);
const cloneShip = path.join(job, 'repo', 'godot', shipRel);
const env = { ...process.env, PC_TEST_HELPER: '1', PC_TEST_HELPER_VT: vt, PC_TEST_SOURCE: source };
const write = (file, text) => { fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, text); };
const read = file => fs.readFileSync(file, 'utf8');
function git(args, cwd = tmp) {
  const r = spawnSync('git', args, { cwd, encoding: 'utf8' });
  assert.equal(r.status, 0, `git ${args.join(' ')}: ${r.stderr}`);
  return r.stdout.trim();
}
const psArgs = args => ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script, ...args];
function helper(args) {
  const r = spawnSync(shell, psArgs(args), { env, encoding: 'utf8', timeout: 60000 });
  if (r.error) throw r.error;
  return { status: r.status, out: `${r.stdout}\n${r.stderr}` };
}
const run = (steps = '') => helper(['-JobDir', job, '-Branch', 'opus/issue-901', '-Ships', 'ships', '-Steps', steps]);
const release = () => helper(['-JobDir', job, '-Release']);
try {
  const work = path.join(tmp, 'work');
  git(['init', '-q', '-b', 'opus/issue-901', work]);
  write(path.join(work, 'godot', 'project.godot'), 'fixture\n');
  git(['add', '-A'], work);
  git(['-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '-m', 'fixture'], work);
  git(['clone', '-q', '--bare', work, source]);
  git(['--git-dir', source, 'branch', 'main', 'opus/issue-901']);
  write(buildShip, 'build v1');
  write(path.join(vt, 'build', 'godot', 'gen', 'manifest.json'), '{"gen":1}');
  write(path.join(vt, 'build', 'godot', 'assets', 'ships', 'manifest.json'), 'tracked, never copied');
  const steps = path.join(tmp, 'steps.sh');
  write(steps, 'echo "$C" > /dev/null\nexit 0\n');

  let r = run(steps);
  assert.equal(r.status, 0, r.out);
  assert.equal(read(cloneShip), 'build v1', 'first run copies the ship');
  assert(!fs.existsSync(path.join(job, 'repo', 'godot', 'assets', 'ships', 'manifest.json')), 'the copy follows get_ship_files exclusions');
  assert.match(read(path.join(job, 'ships_copied.txt')), /T1_11\.glb/);

  write(buildShip, 'build v2');
  r = run();
  assert.equal(r.status, 0, r.out);
  assert.equal(read(cloneShip), 'build v2', 'an unchanged earlier copy is refreshed from a newer build');

  write(cloneShip, 'unique local bake');
  write(buildShip, 'build v3');
  r = run();
  assert.notEqual(r.status, 0, 'a repeat run with a unique local ship file stops');
  assert.match(r.out, /differ from the shared build and from this folder's last copy/);
  assert.equal(read(cloneShip), 'unique local bake', 'the unique local ship file is kept');
  fs.rmSync(cloneShip);

  // A run whose steps are still working holds the lease: a second run and a release are refused and change nothing.
  const started = path.join(tmp, 'started'), go = path.join(tmp, 'go');
  const slow = path.join(tmp, 'slow.sh');
  write(slow, `touch '${started}'\ni=0\nwhile [ ! -f '${go}' ] && [ $i -lt 300 ]; do sleep 0.1; i=$((i+1)); done\nexit 0\n`);
  const first = spawn(shell, psArgs(['-JobDir', job, '-Branch', 'opus/issue-901', '-Ships', 'ships', '-Steps', slow]), { env });
  const done = new Promise(resolve => first.on('exit', resolve));
  (async () => {
    for (let i = 0; i < 300 && !fs.existsSync(started); i++) await new Promise(res => setTimeout(res, 100));
    assert(fs.existsSync(started), 'the first run reached its steps');
    const before = read(path.join(job, 'repo_commit.txt'));
    write(buildShip, 'build v4');
    const second = run();
    assert.notEqual(second.status, 0);
    assert.match(second.out, /another run is using .* right now; nothing changed/);
    assert.match(release().out, /another run is using/);
    assert.equal(read(cloneShip), 'build v3', 'the in-flight checkout keeps the first run\'s copy');
    assert.equal(read(path.join(job, 'repo_commit.txt')), before);
    write(go, '');
    assert.equal(await done, 0, 'the first run finishes normally');

    // Release: only after a PASS whose out files are committed on a board/pc-out branch.
    const out = path.join(job, 'out');
    write(path.join(out, 'result.txt'), 'started\nFAILED: steps exit 1\nall done\n');
    write(path.join(out, 'shot.png'), 'result bytes');
    write(path.join(job, 'repo', 'godot', '.godot', 'imported', 'T1_11.glb-x.scn'), 'import cache');
    r = release();
    assert.notEqual(r.status, 0);
    assert.match(r.out, /does not say PASS/);
    write(path.join(out, 'result.txt'), 'started\nPASS\nall done\n');
    r = release();
    assert.notEqual(r.status, 0);
    assert.match(r.out, /out files are not on a relay branch \(board\/pc-out or the relay repo\); nothing removed/);
    assert.equal(read(cloneShip), 'build v3', 'nothing removed before the relay');
    const relay = path.join(tmp, 'relay');
    git(['init', '-q', '-b', 'board/pc-out-fixture', relay]);
    fs.cpSync(out, path.join(relay, 'opus901'), { recursive: true });
    git(['add', '-A'], relay);
    git(['-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '-m', 'relay'], relay);
    git(['push', '-q', source, 'board/pc-out-fixture'], relay);
    write(path.join(job, 'repo', 'godot', 'gen', 'manifest.json'), 'changed after the copy');
    r = release();
    assert.equal(r.status, 0, r.out);
    assert(!fs.existsSync(cloneShip), 'the ship copy is released');
    assert(!fs.existsSync(path.join(job, 'repo', 'godot', '.godot')), 'the import cache is released');
    assert.equal(read(path.join(job, 'repo', 'godot', 'gen', 'manifest.json')), 'changed after the copy', 'a changed copy is kept');
    assert.match(r.out, /kept \(changed since it was copied\): gen.manifest\.json/);
    assert(fs.existsSync(path.join(job, 'repo', '.git')), 'the clone stays for reuse');
    assert.equal(read(path.join(out, 'shot.png')), 'result bytes', 'results are never removed');

    // Artoo on PR 1275: a relayed PASS, then a retry that fails before writing any output. Release must refuse.
    write(path.join(job, 'repo', 'godot', 'gen', 'manifest.json'), '{"gen":1}');
    r = run(steps);
    assert.equal(r.status, 0, r.out);
    assert.match(read(path.join(out, 'attempt_result.txt')), /^[0-9a-f]{32} steps exit 0\n$/);
    fs.rmSync(path.join(relay, 'opus901'), { recursive: true });
    fs.cpSync(out, path.join(relay, 'opus901'), { recursive: true });
    git(['add', '-A'], relay);
    git(['-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '-m', 'relay 2'], relay);
    git(['push', '-q', source, 'HEAD:refs/heads/board/pc-out-fixture2'], relay);
    // A setup-only call (no steps) after that relayed PASS: relayed too, it still never authorizes a release.
    const setup = run();
    assert.equal(setup.status, 0, setup.out);
    assert.match(read(path.join(out, 'attempt_result.txt')), /^[0-9a-f]{32} setup only\n$/);
    fs.rmSync(path.join(relay, 'opus901'), { recursive: true });
    fs.cpSync(out, path.join(relay, 'opus901'), { recursive: true });
    git(['add', '-A'], relay);
    git(['-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '-m', 'relay 3'], relay);
    git(['push', '-q', source, 'HEAD:refs/heads/board/pc-out-fixture3'], relay);
    r = release();
    assert.notEqual(r.status, 0);
    assert.match(r.out, /did not pass its job steps/);
    assert.equal(read(cloneShip), 'build v4', 'a setup-only attempt releases nothing');
    const retry = helper(['-JobDir', job, '-Branch', 'opus/issue-404', '-Ships', 'ships', '-Steps', steps]);
    assert.notEqual(retry.status, 0, 'the retry fails early (no such branch)');
    assert.match(read(path.join(out, 'attempt_result.txt')), /^[0-9a-f]{32} stopped exit 1\n$/);
    assert.match(read(path.join(out, 'result.txt')), /PASS/, 'the older PASS is still in result.txt');
    r = release();
    assert.notEqual(r.status, 0);
    assert.match(r.out, /did not pass its job steps/);
    assert.equal(read(cloneShip), 'build v4', 'the retry left the copies in place and release removed nothing');
    console.log('PASS helper clone: shared mirror under its lock, job lease held through the steps, unique local ships kept, release only after a relayed PASS');
  })().catch(error => { console.error(error); process.exitCode = 1; first.kill(); })
    .finally(() => fs.rmSync(tmp, { recursive: true, force: true, maxRetries: 3 }));
} catch (error) {
  fs.rmSync(tmp, { recursive: true, force: true, maxRetries: 3 });
  throw error;
}
