'use strict';
// Issue 1303: tools/pc/jobs/opus_job_head.bat is the one shared head for helper PC proof bats, and
// opus_job_template.bat is how a helper starts one. A static contract runs everywhere; the PowerShell half
// (opus_job_head.ps1: live, watchdog, checkout, tracked, shipcheck, hashes) also runs for real under pwsh (Linux CI).
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '../../..');
const jobs = path.join(root, 'tools/pc/jobs');
const read = p => fs.readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const code = text => text.split('\n').filter(l => !/^\s*(rem\b|#)/i.test(l)).join('\n');
const head = read(path.join(jobs, 'opus_job_head.bat'));
const tpl = read(path.join(jobs, 'opus_job_template.bat'));
const ps = read(path.join(jobs, 'opus_job_head.ps1'));
const headCode = code(head), tplCode = code(tpl), psCode = code(ps);

// ---------------------------------------------------------------- static contract: the head
for (const label of ['oj_init', 'oj_checkout', 'oj_ships', 'oj_tail']) assert(head.includes('\n:' + label + '\n'), 'head has ' + label);
const init = headCode.slice(headCode.indexOf(':oj_init'), headCode.indexOf(':oj_checkout'));
const order = ['tools_live\\current.txt', 'live "%OJ_HERE%."', 'OPUS_JOB_HEAD_PREMERGE', 'set "OJ_OUT=%OJ_VT%\\%OJ_JOB%\\out_%OJ_STAMP%_%RANDOM%"',
  'if exist "%OJ_OUT%"', 'set "PC_REAL_PROFILE="', 'set "PC_KEEP_GODOT_PROFILE="', 'set "JW_TOOLS="', 'set "JW_HASHES="',
  'set "JW_NO_REFRESH=1"', 'set "JW_NO_JANITOR=1"', 'call "%JW%" init "%OJ_OUT%" "%~3" "%~4"',
  'bundle "%OJ_HERE%." "%JW_TOOLS%" "%JW_HASHES%" %OJ_PRE%', 'set "TMO_OWN_COPY=1"', 'watchdog "%JW_TOOLS%"', 'hashes "%OJ_OUT%\\real_options_before.txt"'];
order.reduce((at, needle) => { const i = init.indexOf(needle, at); assert(i >= at && i >= 0, 'init order: ' + needle); return i; }, 0);
assert(init.includes('if not "%OPUS_JOB_JANITOR%"=="1" set "JW_NO_JANITOR=1"'), 'the after-job janitor is off unless switched on');
assert(/if not defined OJ_LIVE if not "%OPUS_JOB_HEAD_PREMERGE%"=="1" \(echo [^\n]*refused[^\n]*& exit \/b 2\)/.test(init), 'a head outside tools_live refuses');
assert(/if exist "%OJ_OUT%" \([^\n]*exit \/b 2\)/.test(init), 'an attempt folder is never reused');
assert(read(path.join(root, 'tools/pc/tmo.bat')).includes('if "%TMO_OWN_COPY%"=="1" goto run'), 'tmo.bat honours TMO_OWN_COPY, which keeps a job on the verified watchdog');
assert(init.includes('set "JW=%~dp0..\\job_wrap.bat"'), 'steps run through the job_wrap beside the head');
const ships = headCode.slice(headCode.indexOf(':oj_ships'), headCode.indexOf(':oj_tail'));
const flags = '/E /XC /XN /XO /XF manifest.json README.md a4_props.gd *.uid /XD test previews';
assert.equal((ships.match(/robocopy /g) || []).length, 2, 'two copies: gen and assets\\ships');
const copies = ships.split('\n').filter(l => l.includes('robocopy '));
const genCopy = copies.find(l => l.includes('"%LB_SHIPS%\\gen"'));
const shipCopy = copies.find(l => l.includes('"%LB_SHIPS%\\assets\\ships"'));
assert(genCopy && genCopy.includes('/E ') && !/\/X[CNOF]\b/.test(genCopy), 'gen is copied whole with no skip flags, so its manifest.json lands and the source wins: ' + genCopy);
assert(shipCopy && shipCopy.includes(flags), 'assets\\ships copy uses the safe flags: ' + shipCopy);
assert(/if not exist "%OJ_REPO%\\godot\\gen\\manifest\.json" \(call "%JW%" fail/.test(ships), 'a missing gen manifest fails the job');
assert.equal((ships.match(/if errorlevel 8 \(call "%JW%" fail/g) || []).length, 2, 'robocopy 8 or more fails the job');
assert(ships.indexOf('tracked "%OJ_REPO%"') > ships.lastIndexOf('robocopy '), 'the tracked check runs after the copies');
assert(ships.indexOf('shipcheck "%OJ_REPO%" "%OJ_REPO%_ships_identity.txt"') > ships.lastIndexOf('robocopy '), 'every copied ship is checked against its cache stamp after both copies');
assert(/shipcheck[^\n]*\nif errorlevel 1 \(call "%JW%" fail/.test(ships), 'a ship that does not match its cache fails the job');
assert(/:oj_checkout[\s\S]*checkout "%OJ_OUT%" "%~2" "%~3"[\s\S]*set "OJ_REPO=%OJ_OUT%\\%~2"/.test(headCode), 'checkout goes into the attempt folder');
const tail = headCode.slice(headCode.indexOf(':oj_tail'));
assert(/hashes "%OJ_OUT%\\real_options_after\.txt"[\s\S]*fc \/b "%OJ_OUT%\\real_options_before\.txt" "%OJ_OUT%\\real_options_after\.txt"[\s\S]*Ryan's real options changed[\s\S]*call "%JW%" end\nexit \/b %ERRORLEVEL%/.test(tail), 'tail compares the options hash, then ends through job_wrap');
for (const step of ['oj_checkout', 'oj_ships']) {
  const body = headCode.slice(headCode.indexOf(':' + step));
  assert(/if defined JW_STOP \([^\n]*skipped/.test(body.split('\n').slice(0, 4).join('\n')), step + ' is skipped after a failed step');
}
assert(!/^\s*(del|erase|rd|rmdir)\b|\/MIR|\/PURGE|\/MOV/im.test(headCode), 'the head deletes nothing');
assert(!/tmo\.bat"\s|%TMO%/.test(headCode), 'the head starts nothing outside job_wrap');
console.log('PASS head: tools_live only, new attempt folder, job_wrap init, watchdog hashes, throwaway profile, options hash, safe ships copy, honest tail');

// ---------------------------------------------------------------- static contract: the template
const fill = tpl.match(/^rem ---- FILL/gm) || [];
assert.equal(fill.length, 4, 'the template marks its fill lines (FILL 1, 2, 3, and 4 and 5)');
assert(/if defined OPUS_JOB_HEAD if not "%OPUS_JOB_HEAD_PREMERGE%"=="1" \(echo FAILED[^\n]*exit \/b 2\)/.test(tplCode), 'a head override outside a pre-merge smoke is refused');
assert(tplCode.includes('set "HEAD=%VT%\\tools_live\\%TLV%\\pc\\jobs\\opus_job_head.bat"'), 'the template finds the head in tools_live');
assert(tplCode.includes('call "%HEAD%" init "%JOB%" "%LABEL%" "%TOOLS%"') && tplCode.includes('call "%HEAD%" tail\nexit /b %ERRORLEVEL%'), 'template starts and ends through the head');
const one = tplCode.slice(tplCode.indexOf(':one'));
['call "%HEAD%" checkout %1 %2', 'call "%HEAD%" ships', 'call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\\godot" --import']
  .reduce((at, needle) => { const i = one.indexOf(needle, at); assert(i >= at && i >= 0, 'template order: ' + needle); return i; }, 0);
assert(!/\bgit\b|robocopy|tmo\.bat|origin\//i.test(tplCode.replace(/opus_job_head\.bat/g, '')), 'the template does no git, copy or watchdog work of its own');
console.log('PASS template: five fill lines, head from tools_live, every step through the head and job_wrap');

// ---------------------------------------------------------------- static contract: the PowerShell half
assert(psCode.includes("$mirror + '.lock', 'OpenOrCreate', 'ReadWrite', 'None'"), 'takes the shared mirror lock');
assert(psCode.includes("clone --local -q --no-checkout $mirror $repo"), 'clones from the shared mirror');
assert(psCode.includes("'\\A[0-9a-f]{40}\\z'"), 'a pin must be a full commit');
for (const banned of [/reset\s+--hard/, /\bclean\s+-/, /--force/, /Remove-Item/, /\.Delete\(/]) assert(!banned.test(psCode), 'ps1 must not use ' + banned);
console.log('PASS ps1: shared mirror lock, full pins, nothing deleted');

// ---------------------------------------------------------------- live fixtures (pwsh)
const windows = process.platform === 'win32';
const shell = windows ? 'powershell.exe' : 'pwsh';
if (windows || spawnSync(shell, ['-NoProfile', '-Command', 'exit 0']).error) {
  if (process.env.CI && !windows) throw new Error(`${shell} is required in CI`);
  console.log('SKIP opus job head fixtures: they need pwsh (Linux CI runs them)');
  process.exit(0);
}
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'opus-job-head-'));
const vt = path.join(tmp, 'vt');
const source = path.join(tmp, 'source.git');
const realu = path.join(tmp, 'realu');
const env = { ...process.env, PC_TEST_HELPER: '1', PC_TEST_HELPER_VT: vt, PC_TEST_SOURCE: source, PC_TEST_REALU: realu };
const write = (file, text) => { fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, text); };
function git(args, cwd = tmp) {
  const r = spawnSync('git', args, { cwd, encoding: 'utf8' });
  assert.equal(r.status, 0, `git ${args.join(' ')}: ${r.stderr}`);
  return r.stdout.trim();
}
function run(...args) {
  const r = spawnSync(shell, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(jobs, 'opus_job_head.ps1'), ...args], { env, encoding: 'utf8', timeout: 60000 });
  if (r.error) throw r.error;
  return { status: r.status, out: `${r.stdout}\n${r.stderr}` };
}
const work = path.join(tmp, 'work');
git(['init', '-q', '-b', 'main', work]);
write(path.join(work, 'godot', 'project.godot'), 'fixture\n');
write(path.join(work, 'godot', 'assets', 'ships', 'a4_props.gd'), 'extends Node\n');
git(['add', '-A'], work);
git(['-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '-m', 'one'], work);
const one1 = git(['rev-parse', 'HEAD'], work);
write(path.join(work, 'godot', 'project.godot'), 'fixture two\n');
git(['-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qam', 'two'], work);
const two = git(['rev-parse', 'HEAD'], work);
git(['clone', '-q', '--bare', work, source]);

const live = path.join(vt, 'tools_live');
assert.notEqual(run('live', path.join(live, 'v2', 'pc', 'jobs')).status, 0, 'no current.txt: refused');
write(path.join(live, 'current.txt'), 'v2\r\n');
let r = run('live', path.join(live, 'v2', 'pc', 'jobs') + path.sep + '.');
assert.equal(r.status, 0, 'the current tools_live head is accepted: ' + r.out);
assert.notEqual(run('live', path.join(live, 'v1', 'pc', 'jobs')).status, 0, 'an older installed head is refused');
assert.notEqual(run('live', path.join(vt, 'opus1303', 'src', 'tools', 'pc', 'jobs')).status, 0, 'a head outside tools_live is refused');

// One verified bundle: job_wrap's tools and hashes must be the current version's, and match the files.
const sha = text => require('node:crypto').createHash('sha256').update(text).digest('hex');
const files = { 'tmo.bat': 'rem watchdog\n', 'run_timeout.ps1': '# watchdog\n', 'jobs\\opus_job_head.bat': 'rem head\n', 'jobs\\opus_job_head.ps1': '# head\n' };
for (const v of ['v1', 'v2']) {
  for (const [name, text] of Object.entries(files)) write(path.join(live, v, 'pc', ...name.split('\\')), text);
  write(path.join(live, v, 'hashes.txt'), Object.entries(files).map(([n, t]) => `${sha(t)}  ${n}`).join('\n') + '\n');
}
const v2 = path.join(live, 'v2');
r = run('bundle', path.join(v2, 'pc', 'jobs'), path.join(v2, 'pc'), path.join(v2, 'hashes.txt'), '0');
assert.equal(r.status, 0, 'the current bundle verifies: ' + r.out);
assert.equal((r.out.match(/^verified [0-9a-f]{64} /gm) || []).length, 4, 'head and watchdog files are all verified');
assert.notEqual(run('bundle', path.join(v2, 'pc', 'jobs'), path.join(live, 'v1', 'pc'), path.join(v2, 'hashes.txt'), '0').status, 0, 'leftover JW_TOOLS from an older version is refused');
assert.notEqual(run('bundle', path.join(v2, 'pc', 'jobs'), path.join(v2, 'pc'), path.join(live, 'v1', 'hashes.txt'), '0').status, 0, 'leftover JW_HASHES from an older version is refused');
assert.notEqual(run('bundle', path.join(v2, 'pc', 'jobs'), path.join(v2, 'pc'), '', '0').status, 0, 'no hashes file is refused');
write(path.join(v2, 'pc', 'jobs', 'opus_job_head.bat'), 'rem edited head\n');
assert.notEqual(run('bundle', path.join(v2, 'pc', 'jobs'), path.join(v2, 'pc'), path.join(v2, 'hashes.txt'), '0').status, 0, 'an edited head fails the hash check');
r = run('bundle', path.join(v2, 'pc', 'jobs'), path.join(v2, 'pc'), path.join(v2, 'hashes.txt'), '1');
assert.equal(r.status, 0, 'a pre-merge smoke still verifies the watchdog: ' + r.out);
write(path.join(v2, 'pc', 'tmo.bat'), 'rem edited watchdog\n');
assert.notEqual(run('bundle', path.join(v2, 'pc', 'jobs'), path.join(v2, 'pc'), path.join(v2, 'hashes.txt'), '1').status, 0, 'an edited watchdog fails even in a smoke');

const tools = path.join(vt, 'tools_live', 'v9', 'pc');
write(path.join(tools, 'tmo.bat'), 'rem watchdog\n');
r = run('watchdog', tools);
assert.notEqual(r.status, 0, 'a missing run_timeout.ps1 fails closed');
write(path.join(tools, 'run_timeout.ps1'), '# watchdog\n');
r = run('watchdog', tools);
assert.equal(r.status, 0, r.out);
assert.match(r.out, /watchdog [0-9a-f]{64} .*tmo\.bat/);
assert.match(r.out, /watchdog [0-9a-f]{64} .*run_timeout\.ps1/);

const attempt = path.join(vt, 'opus1303', 'out_1');
r = run('checkout', attempt, 'old', one1);
assert.equal(r.status, 0, r.out);
assert.equal(git(['rev-parse', 'HEAD'], path.join(attempt, 'old')), one1, 'the old pin is checked out exactly');
r = run('checkout', attempt, 'new', two);
assert.equal(r.status, 0, r.out);
assert.equal(fs.readFileSync(path.join(attempt, 'new', 'godot', 'project.godot'), 'utf8'), 'fixture two\n');
assert.notEqual(run('checkout', attempt, 'new', two).status, 0, 'a checkout folder is never reused');
assert.notEqual(run('checkout', attempt, 'short', two.slice(0, 8)).status, 0, 'a short pin is refused');
assert.notEqual(run('checkout', attempt, 'ghost', 'f'.repeat(40)).status, 0, 'an unknown commit is refused');
assert.notEqual(run('checkout', path.join(tmp, 'elsewhere'), 'x', two).status, 0, 'an attempt folder outside voidsworn_test is refused');

r = run('tracked', path.join(attempt, 'new'));
assert.equal(r.status, 0, r.out);
write(path.join(attempt, 'new', 'godot', 'assets', 'ships', 'a4_props.gd'), 'stale copy\n');
write(path.join(attempt, 'new', 'godot', 'gen', 'T1.glb'), 'untracked ship');
r = run('tracked', path.join(attempt, 'new'));
assert.notEqual(r.status, 0, 'a changed tracked .gd fails the job');
assert.match(r.out, /a4_props\.gd/);

// shipcheck: each copied ship's glb stamp (unix mtime:size per glb, as build_assets.gd source_stamp) must equal its
// gen\manifest.json "src", and its cached scene must exist.
const sc = path.join(tmp, 'sc');
const glb = path.join(sc, 'godot', 'assets', 'ships', 'S1', 'S1.glb');
write(glb, 'twelve bytes');
fs.utimesSync(glb, 1700000000, 1700000000);
write(path.join(sc, 'godot', 'gen', 'ships', 'S1.scn'), 'scene');
const man = src => write(path.join(sc, 'godot', 'gen', 'manifest.json'), JSON.stringify({ ships: { S1: { v: 9, res: 'res://gen/ships/S1.scn', src }, GONE: { res: 'res://gen/ships/GONE.scn' } } }));
const ident = path.join(tmp, 'ident.txt');
man('1700000000:12;');
r = run('shipcheck', sc, ident);
assert.equal(r.status, 0, 'a matching ship passes: ' + r.out);
assert.match(fs.readFileSync(ident, 'utf8'), /^S1 1700000000:12; res:\/\/gen\/ships\/S1\.scn/m, 'the measured hull identity is recorded');
man('1600000000:12;');
r = run('shipcheck', sc, ident);
assert.notEqual(r.status, 0, 'a glb newer than its cache (a publish between the copies) fails');
assert.match(r.out, /S1 cache was built from other files/);
man('1700000000:12;');
fs.rmSync(path.join(sc, 'godot', 'gen', 'ships', 'S1.scn'));
assert.notEqual(run('shipcheck', sc, ident).status, 0, 'a missing cached scene fails');
fs.rmSync(path.join(sc, 'godot', 'gen', 'manifest.json'));
assert.notEqual(run('shipcheck', sc, ident).status, 0, 'a missing gen manifest fails');

const before = path.join(tmp, 'before.txt'), after = path.join(tmp, 'after.txt');
assert.equal(run('hashes', before).status, 0);
assert.match(fs.readFileSync(before, 'utf8'), /absent battle_opts\.json/);
write(path.join(realu, 'battle_opts.json'), '{}');
assert.equal(run('hashes', after).status, 0);
assert.match(fs.readFileSync(after, 'utf8'), /^[0-9a-f]{64} battle_opts\.json/m);
assert.notEqual(fs.readFileSync(before, 'utf8'), fs.readFileSync(after, 'utf8'), 'a change to the options shows in the hash');
fs.rmSync(tmp, { recursive: true, force: true });
console.log('PASS ps1 fixtures: current tools_live gate, one verified bundle, watchdog hashes, exact fresh checkouts, tracked check, ship cache stamps, options hash');
