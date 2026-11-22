'use strict';
// Issue 1303: tools/pc/jobs/opus_job_head.bat is the one shared head for helper PC proof bats, and
// opus_job_template.bat is how a helper starts one. A static contract runs everywhere; the PowerShell half
// (opus_job_head.ps1: live, watchdog, checkout, tracked, shipcheck, hashes) also runs for real under pwsh (Linux CI).
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawn, spawnSync } = require('node:child_process');
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
assert(ships.includes('> "%OJ_OUT%\\ships_source.txt" echo %LB_SHIPS%'), 'the ships step records its source for the tail\'s unchanged-copy proof');
assert(ships.indexOf('shipcheck "%OJ_REPO%" "%OJ_REPO%_ships_identity.txt" "%OJ_NEED_HULLS%"') > ships.lastIndexOf('robocopy '), 'every copied ship is checked against its cache stamp after both copies');
assert(/fc \/b "%OJ_OUT%\\ships_identity_first\.txt" "%OJ_REPO%_ships_identity\.txt"[^\n]*\nif errorlevel 1 \(call "%JW%" fail/.test(ships), 'every checkout must measure the same hulls as the first');
assert(/shipcheck[^\n]*\nif errorlevel 1 \(call "%JW%" fail/.test(ships), 'a ship that does not match its cache fails the job');
assert(/:oj_checkout[\s\S]*checkout "%OJ_OUT%" "%~2" "%~3"[\s\S]*set "OJ_REPO=%OJ_OUT%\\%~2"/.test(headCode), 'checkout goes into the attempt folder');
const tail = headCode.slice(headCode.indexOf(':oj_tail'));
assert(/hashes "%OJ_OUT%\\real_options_after\.txt"[\s\S]*fc \/b "%OJ_OUT%\\real_options_before\.txt" "%OJ_OUT%\\real_options_after\.txt"[\s\S]*Ryan's real options changed[\s\S]*call "%JW%" end\nset "OJ_RC=%ERRORLEVEL%"/.test(tail), 'tail compares the options hash, then ends through job_wrap');
for (const step of ['oj_checkout', 'oj_ships']) {
  const body = headCode.slice(headCode.indexOf(':' + step));
  assert(/if defined JW_STOP \([^\n]*skipped/.test(body.split('\n').slice(0, 4).join('\n')), step + ' is skipped after a failed step');
}
assert(!/^\s*(del|erase|rd|rmdir)\b|\/MIR|\/PURGE|\/MOV/im.test(headCode), 'the head deletes nothing');
assert(!/tmo\.bat"\s|%TMO%/.test(headCode), 'the head starts nothing outside job_wrap');
assert(/fc \/b "%OJ_OUT%\\real_options_before\.txt"[\s\S]*:oj_tail_end\n[\s\S]*call "%JW%" end\nset "OJ_RC=%ERRORLEVEL%"\nif defined OJ_DROP powershell [^\n]*dropcheckouts "%OJ_OUT%" >> "%OJ_ST%" 2>&1\n(?:[^\n]*\n)*?exit \/b %OJ_RC%/.test(tail), 'the tail runs the checkout step after job_wrap end has written the result, and keeps its exit code');
assert(/shiprecord "%OJ_REPO%" "%OJ_REPO%_ships_copied\.txt" "%LB_SHIPS%"/.test(ships) && ships.indexOf('shiprecord') > ships.indexOf('shipcheck "%OJ_REPO%"'), 'the ships step records what it copied, after the cache check (issue 1497)');
assert(/if "%OJ_KEEP_CHECKOUTS%"=="1"/.test(tail), 'OJ_KEEP_CHECKOUTS=1 keeps them');
// Issue 1396 (Board, Nov 22): the tail starts the relay waiter hidden, after the result, only with the drop step on.
assert(/if defined OJ_DROP if not "%OJ_NO_DROPWAIT%"=="1" set "OJ_WAIT=1"\nset "OJ_DROPWAIT_ATTEMPT=%OJ_OUT%"\n[\s\S]*if defined OJ_WAIT powershell [^\n]*\$ErrorActionPreference = 'Stop'; Start-Process -WindowStyle Hidden [^\n]*dropwait' -f \$env:OJ_PS\)"/.test(tail) && tail.indexOf('dropwait') > tail.indexOf('dropcheckouts "%OJ_OUT%"'), 'the tail starts the relay waiter after its own drop step, the attempt in its environment, not on its command line');
assert(/if defined OJ_WAIT if errorlevel 1 \([^\n]*could not be started[^\n]*\) else \([^\n]*hidden waiter clears them/.test(tail) && !/-RedirectStandard/.test(tail), 'a failed launch is logged as one, and the start is never redirected (review of PR 1644)');
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
const walk = psCode.slice(psCode.indexOf('function Remove-LinkSafeTree'), psCode.indexOf('switch ($Action)'));
const outsideWalk = psCode.replace(walk, '');
for (const banned of [/reset\s+--hard/, /\bclean\s+-/, /--force/, /Remove-Item/, /\.Delete\(/]) assert(!banned.test(outsideWalk), 'ps1 must not use ' + banned + ' outside the link-safe walk');
const ownedFn = psCode.slice(psCode.indexOf('function Remove-Owned'), psCode.indexOf('function Assert-NoLinks'));
assert.equal((psCode.match(/Remove-LinkSafeTree /g) || []).length, (ownedFn.match(/Remove-LinkSafeTree /g) || []).length, 'the link-safe walk is called only from Remove-Owned and Complete-Removing');
assert(/function Complete-Removing[\s\S]*removing\.txt[\s\S]*\$names -cnotcontains[\s\S]*Assert-NoLinks \$tomb[\s\S]*not the recorded commit[\s\S]*Test-Paused[\s\S]*Remove-LinkSafeTree \$tomb/.test(ownedFn), 'an unfinished removal is finished only when recorded, for a listed name, after the link, HEAD and pause checks (Artoo on PR 1498)');
assert(/\.removing'[\s\S]*AppendAllText\(\$record[\s\S]*\[IO\.Directory\]::Move\(\$full, \$tomb\)[\s\S]*Remove-LinkSafeTree \$tomb/.test(ownedFn), 'a checkout is recorded, then renamed whole, before any file goes (Board, AFTERRELAY2 lock)');
const drop = psCode.slice(psCode.indexOf("'dropcheckouts' {"), psCode.indexOf("'hashes' {"));
const dropFn = psCode.slice(psCode.indexOf('function Drop-Attempt'), psCode.indexOf('function Get-AttemptState'));
assert(/HEAD is no longer the pin[\s\S]*Get-KeptWork \$repo[\s\S]*Test-Paused[\s\S]*Save-Leftovers \$repo[\s\S]*Remove-Owned \$repo/.test(dropFn), 'a checkout goes only after its pin, its working files and the pause are checked, and its work is saved');
assert(/function Remove-Owned\(\$path, \[switch\]\$InPlace, \[string\]\$Commit = ''\) \{\n(\s*#[^\n]*\n)*\s*if \(Test-Paused\)[^\n]*\n/.test(walk), 'every removal checks the pause first');
assert(/Get-AttemptProblem \$attempt[\s\S]*Drop-Attempt \$attempt/.test(drop) && !/\$sib/.test(drop), 'the step covers this attempt only; earlier ones go through their waiter or the janitor (review of PR 1644)');
assert(/\$state -ne 'PASS'[\s\S]*Assert-Relayed \$attempt[\s\S]*HEAD is no longer the pin[\s\S]*Assert-Rebuildable \$repo[\s\S]*Get-KeptWork/.test(dropFn), 'only a passed and relayed attempt, then pin, branches and stash, then the files (Artoo on PR 1498)');
assert(/\$code\[0\] -ne ' '[^\n]*staged: /.test(psCode), 'a staged change is listed as staged, which Save-Leftovers refuses');
assert(/Assert-Relayed \(Join-Path \$jobDir 'out'\)[\s\S]*Get-KeptWork \$repo \$null/.test(psCode.slice(psCode.indexOf("'droprepo' {"))), 'the publish removes the clone only after the relay');
assert(/\[IO\.File\]::AppendAllText\(\(Join-Path \$attempt 'checkouts\.txt'\)/.test(psCode), 'the checkout step lists what it made');
console.log('PASS ps1: shared mirror lock, full pins, deletes only through the link-safe walk of its own checkouts');

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
const relaySource = path.join(tmp, 'relay-source.git');   // issue 1657: the private relay repo's stand-in
const env = { ...process.env, PC_TEST_HELPER: '1', PC_TEST_HELPER_VT: vt, PC_TEST_SOURCE: source, PC_TEST_RELAY_SOURCE: relaySource, PC_TEST_REALU: realu };
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
// Issue 1379 (Artoo on PR 1529): a tracked munition body. Its maps stay embedded on import (the committed .glb.import), so any
// image file beside it is somebody's work, even an ignored one whose name starts with the body's.
write(path.join(work, 'godot', 'fx', 'munition_bodies', 'corsair_rockets.glb'), 'body\n');
write(path.join(work, 'godot', 'fx', 'munition_bodies', '.gitignore'), '*.jpg\n*.png\n');
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
assert.match(fs.readFileSync(ident, 'utf8'), /^GONE no-glb res:\/\/gen\/ships\/GONE\.scn scene=0/m, 'an older entry with no ship folder is listed, so checkouts must agree on it too');
assert.equal(run('shipcheck', sc, ident, 'S1').status, 0, 'a needed hull that matches passes');
r = run('shipcheck', sc, ident, 'S1 GONE');
assert.notEqual(r.status, 0, 'a needed hull with no matching ship fails');
assert.match(r.out, /GONE is needed by this job/);
man('1600000000:12;');
r = run('shipcheck', sc, ident);
assert.notEqual(r.status, 0, 'a glb newer than its cache (a publish between the copies) fails');
assert.match(r.out, /S1 cache was built from other files/);
man('1700000000:12;');
fs.rmSync(path.join(sc, 'godot', 'gen', 'ships', 'S1.scn'));
assert.notEqual(run('shipcheck', sc, ident).status, 0, 'a missing cached scene fails');
fs.rmSync(path.join(sc, 'godot', 'gen', 'manifest.json'));
assert.notEqual(run('shipcheck', sc, ident).status, 0, 'a missing gen manifest fails');

// dropcheckouts: only a passed attempt whose results are relayed (every out_* file a blob on a board/pc-out branch);
// only the listed checkouts whose HEAD is still the pin, with every local branch in the mirror, no stash and nothing
// staged; links inside are not followed; files the job left in a checkout are saved into out_<name>\checkout_leftovers
// first (issue 1497); out_* and logs stay; the Board's pause and a folder outside voidsworn_test\<job>\out_* remove
// nothing; earlier passed and relayed attempts of the job are cleared too, failed or unfinished ones never.
let relays = 0;
const relay = (entries, branch = '', target = source) => {
  // what the Board's relay does: commit result folders on a new board/pc-out branch of the origin, each [local folder,
  // folder in the tree]; returns the branch the receipt names
  const rr = path.join(tmp, `relay${++relays}`);
  git(['init', '-q', rr]);
  for (const [d, treeDir] of entries) {
    const walk = (from, to) => { for (const e of fs.readdirSync(from, { withFileTypes: true })) {
      if (e.isDirectory()) { if (!/^checkout_leftovers/.test(e.name)) walk(path.join(from, e.name), path.join(to, e.name)); }
      else if (e.name !== 'relay_receipt.txt') { fs.mkdirSync(to, { recursive: true }); fs.copyFileSync(path.join(from, e.name), path.join(to, e.name)); } } };
    walk(d, path.join(rr, ...treeDir.split('/')));
  }
  git(['add', '-A'], rr);
  git(['-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'relay'], rr);
  const ref = branch || `board/pc-out-t${relays}`;
  git(['push', '-q', '-f', target, `HEAD:refs/heads/${ref}`], rr);
  return ref;
};
const listed = fs.readFileSync(path.join(attempt, 'checkouts.txt'), 'utf8');
assert.match(listed, new RegExp(`^old ${one1}\\r?$`, 'm'), 'checkout lists old');
assert.match(listed, new RegExp(`^new ${two}\\r?$`, 'm'), 'checkout lists new');
const outside = path.join(tmp, 'outside');
write(path.join(outside, 'keep.txt'), 'not ours');
git(['checkout', '--', '.'], path.join(attempt, 'new'));
write(path.join(attempt, 'new', 'godot', '.godot', 'cache.bin'), 'import cache');
fs.symlinkSync(outside, path.join(attempt, 'new', 'godot', '.godot', 'linked'), 'dir');
write(path.join(attempt, 'new', 'godot', 'bench', 'copy.godot'), 'fixture two\n');
// The ships source the ships step recorded; copied files keep its size and time, as robocopy leaves them.
const shipsSrc = path.join(vt, 'build', 'godot');
write(path.join(attempt, 'ships_source.txt'), shipsSrc + '\r\n');
const copyShip = (rel, text, into = 'new') => {
  const from = path.join(shipsSrc, ...rel.split('/')), to = path.join(attempt, into, 'godot', ...rel.split('/'));
  write(from, text); write(to, text); fs.utimesSync(from, 1700000000, 1700000000); fs.utimesSync(to, 1700000000, 1700000000);
};
copyShip('gen/T1.glb', 'untracked ship');
copyShip('assets/ships/S1/S1.glb', 'ship glb');
write(path.join(attempt, 'new', 'godot', 'assets', 'ships', 'S1', 'S1.glb.import'), 'generated by import');
r = run('checkout', attempt, 'work', two);
assert.equal(r.status, 0, r.out);
// A passing job that wrote ship output inside the copied tree: its files are saved before the checkout goes (Artoo,
// PR 1326; issue 1497).
r = run('checkout', attempt, 'shipout', two);
assert.equal(r.status, 0, r.out);
const so = path.join(attempt, 'shipout', 'godot');
write(path.join(shipsSrc, 'assets', 'ships', 'S2', 'S2.glb'), 'published ship');
write(path.join(so, 'assets', 'ships', 'S2', 'S2.glb'), 'a re-export the job wrote over the copy');
write(path.join(so, 'assets', 'ships', 'S9', 'S9.glb'), 'a new ship the job made');
write(path.join(so, 'gen', 'orphan.res.import'), 'a sidecar with no proven file');
// Ignored images beside the munition bodies are work (Artoo on PR 1529): a root image with no body, and a hand-painted map
// named like the body's. Their own checkout, so the shipout list above keeps its five examples.
r = run('checkout', attempt, 'mapsout', two);
assert.equal(r.status, 0, r.out);
const mo = path.join(attempt, 'mapsout', 'godot', 'fx', 'munition_bodies');
write(path.join(mo, 'stray_albedo.jpg'), 'an ignored map with no tracked body');
write(path.join(mo, 'corsair_rockets_corsair_rockets_hull_albedo.jpg'), 'a hand-painted map named like an extracted one');
// Same size and same time, different bytes: only a hash match proves a copy.
write(path.join(shipsSrc, 'gen', 'same.res'), 'AAAA'); write(path.join(so, 'gen', 'same.res'), 'BBBB');
fs.utimesSync(path.join(shipsSrc, 'gen', 'same.res'), 1700000000, 1700000000); fs.utimesSync(path.join(so, 'gen', 'same.res'), 1700000000, 1700000000);
write(path.join(attempt, 'work', 'godot', 'project.godot'), 'an edit left by a step\n');
write(path.join(attempt, 'work', 'godot', 'notes.txt'), 'a new output inside the checkout');
// More than the results may take keeps the checkout (the cap is 200 MB on the PC; 1000 bytes here).
r = run('checkout', attempt, 'big', two);
assert.equal(r.status, 0, r.out);
write(path.join(attempt, 'big', 'godot', 'huge.bin'), 'x'.repeat(2000));
// A staged edit whose working file was put back (git MM or M-space): no patch of the files shows it, so it keeps the
// checkout, index and all (Artoo on PR 1498).
r = run('checkout', attempt, 'staged', two);
assert.equal(r.status, 0, r.out);
const stg = path.join(attempt, 'staged');
write(path.join(stg, 'godot', 'project.godot'), 'staged only\n');
git(['add', 'godot/project.godot'], stg);
write(path.join(stg, 'godot', 'project.godot'), 'fixture two\n');
// A stash keeps the checkout too.
r = run('checkout', attempt, 'stashed', two);
assert.equal(r.status, 0, r.out);
const sts = path.join(attempt, 'stashed');
write(path.join(sts, 'godot', 'project.godot'), 'stashed work\n');
git(['-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'stash', '-q'], sts);
// The copy-time record proves a ships copy even after a publish moved build\godot on (opus1457main1, Nov 21).
r = run('checkout', attempt, 'rec', two);
assert.equal(r.status, 0, r.out);
copyShip('assets/ships/B16/B16_damage.glb', 'ship as copied', 'rec');
write(path.join(attempt, 'rec', 'godot', 'assets', 'ships', 'B16', 'B16_damage.glb.import'), 'import sidecar');
write(path.join(attempt, 'rec', 'godot', 'build_info.json'), '{"commit":"x"}');
// an untracked file that exists only in the checkout was never copied, so it is never recorded (Artoo on PR 1498)
write(path.join(attempt, 'rec', 'godot', 'assets', 'ships', 'B16', 'only_here.bin'), 'made by the job');
r = run('shiprecord', path.join(attempt, 'rec'), path.join(attempt, 'rec_ships_copied.txt'), shipsSrc);
assert.equal(r.status, 0, r.out);
const recText = fs.readFileSync(path.join(attempt, 'rec_ships_copied.txt'), 'utf8');
assert.match(recText, new RegExp(`^${sha('ship as copied')} 14 godot/assets/ships/B16/B16_damage\\.glb\\r?$`, 'm'), 'the record holds the copied file: ' + recText);
assert(!/a4_props\.gd/.test(recText), 'tracked files are not recorded');
assert(!/only_here\.bin/.test(recText), 'a file only in the checkout is not recorded');
write(path.join(shipsSrc, 'assets', 'ships', 'B16', 'B16_damage.glb'), 'ship as published later');
write(path.join(attempt, 'out_new', 'samples.jsonl'), '{"a": 1}');
write(path.join(attempt, 'new_ships_identity.txt'), 'S1');
write(path.join(attempt, 'stray'), 'not a checkout');
fs.appendFileSync(path.join(attempt, 'checkouts.txt'), `stray ${two}\r\n../escape ${two}\r\n`);
// Earlier attempts of the same job: passed and relayed (cleared), failed and unfinished (never touched here).
const jobDir = path.join(vt, 'opus1303');
const earlier = (name, done) => {
  const at = path.join(jobDir, name);
  const rr = run('checkout', at, 'new', two);
  assert.equal(rr.status, 0, rr.out);
  write(path.join(at, `out_new`, 'result.txt'), `result of ${name}\n`);
  if (done) write(path.join(at, 'done.txt'), done + '\r\n');
  return at;
};
const passedBefore = earlier('out_2', 'PASS');
const failedBefore = earlier('out_3', 'FAILED: a step');
const unfinished = earlier('out_4', '');
// the RUN6 layout: the attempt folder itself, out_new inside it (board/pc-out-1211r6)
write(path.join(passedBefore, 'relay_receipt.txt'), relay([[path.join(passedBefore, 'out_new'), 'out_2/out_new']]) + ' out_2\r\n');
write(path.join(failedBefore, 'relay_receipt.txt'), relay([[path.join(failedBefore, 'out_new'), 'out_3/out_new']]) + ' out_3\r\n');
env.PC_TEST_LEFTOVER_CAP = '1000';
// Before the result is relayed (the tail itself) and before it passed, nothing goes.
r = run('dropcheckouts', attempt);
assert.equal(r.status, 0, r.out);
assert(fs.existsSync(path.join(attempt, 'new')) && /checkouts kept: .*has no result yet/.test(r.out), 'an attempt with no done.txt keeps its checkouts: ' + r.out);
write(path.join(attempt, 'done.txt'), 'PASS\r\n');
r = run('dropcheckouts', attempt);
assert(fs.existsSync(path.join(attempt, 'new')) && /results not relayed yet: board\/pc-out-opus1303:out_1: branch board\/pc-out-opus1303 \(from the job name\) is not on origin/.test(r.out), 'a passed attempt keeps its checkouts until the relay receipt: ' + r.out);
// a receipt whose tree folder does not hold this attempt's files (the bytes sit under another folder) proves nothing
const other = relay([[path.join(attempt, 'out_new'), 'opus9999/out_9/out_new']]);
r = run('dropcheckouts', attempt, other, 'out_1');
assert(fs.existsSync(path.join(attempt, 'new')) && /results not relayed yet: board\/pc-out-t\d+:out_1: out_new\/\S+ is not on the relay/.test(r.out), 'identical bytes under another folder keep the checkouts: ' + r.out);
assert.notEqual(run('dropcheckouts', attempt, 'main', 'out_1').out.match(/relay receipt not accepted/), null, 'a receipt must name a board/pc-out branch');
assert(fs.existsSync(path.join(passedBefore, 'new')), 'an earlier passed and relayed attempt is left to its own waiter or the janitor (review of PR 1644): ' + r.out);
assert(fs.existsSync(path.join(failedBefore, 'new')) && fs.existsSync(path.join(unfinished, 'new')), 'failed and unfinished attempts are never touched here: ' + r.out);
// A relay that left out a file over 10 MB (board/pc-out da39c826, opus1415d_GL1_out/skipped_over_10MB.txt; Artoo on
// PR 1498): kept with the reason named, unless the relay's own list names that exact file and size. The file stays here.
{
  const big = path.join(vt, 'opus1498big', 'out_1');
  assert.equal(run('checkout', big, 'new', two).status, 0);
  write(path.join(big, 'out_new', 'result.txt'), 'big job result\n');
  fs.writeFileSync(path.join(big, 'out_new', 'big.glb'), Buffer.alloc(11 * 1024 * 1024, 7));
  write(path.join(big, 'done.txt'), 'PASS\r\n');
  const stage = path.join(tmp, 'stage1498');
  const partial = (list) => {
    fs.rmSync(stage, { recursive: true, force: true });
    write(path.join(stage, 'out_new', 'result.txt'), 'big job result\n');
    if (list !== null) write(path.join(stage, 'skipped_over_10MB.txt'), list);
    return relay([[stage, 'out_1']]);
  };
  r = run('dropcheckouts', big, partial(null), 'out_1');
  assert(fs.existsSync(path.join(big, 'new')) && /results not relayed yet: .*out_1: out_new\/big\.glb is not on the relay/.test(r.out), 'a partial relay keeps the checkout and names the file: ' + r.out);
  r = run('dropcheckouts', big, partial('out_new\\big.glb 4.0 MB\r\n'), 'out_1');
  assert(fs.existsSync(path.join(big, 'new')) && /out_new\/big\.glb is not on the relay/.test(r.out), 'a skip list with another size proves nothing: ' + r.out);
  r = run('dropcheckouts', big, partial('out_new\\other.glb 11.0 MB\r\n'), 'out_1');
  assert(fs.existsSync(path.join(big, 'new')), 'a skip list naming another file proves nothing: ' + r.out);
  r = run('dropcheckouts', big, partial('out_new\\big.glb 11.0 MB\r\n'), 'out_1');
  assert.equal(r.status, 0, r.out);
  assert(!fs.existsSync(path.join(big, 'new')) && /result kept on the PC only: out_new\/big\.glb/.test(r.out) && /1 of 2 result file\(s\) are on/.test(r.out), 'a listed skipped file lets the checkout go: ' + r.out);
  assert.equal(fs.statSync(path.join(big, 'out_new', 'big.glb')).size, 11 * 1024 * 1024, 'the skipped file stays on the PC');
}
// Issue 1535 (Board, Nov 22): no session writes relay_receipt.txt any more. The head proves the relay itself from the job:
// the relay_branch.txt the head wrote at init, else board/pc-out-<job> with the attempt folder at the tree's root, and
// origin (git ls-remote) must hold that branch at the commit checked. Wrong folder, wrong bytes or a branch deleted on
// origin since the last fetch keep everything.
{
  const job1535 = (job, n = 'out_1') => {
    const at = path.join(vt, job, n);
    assert.equal(run('checkout', at, 'new', two).status, 0);
    write(path.join(at, 'out_new', 'result.txt'), `${job} result\n`);
    write(path.join(at, 'done.txt'), 'PASS\r\n');
    return at;
  };
  // by the job's own name, no receipt of any kind
  const named = job1535('opus1535a');
  relay([[path.join(named, 'out_new'), 'out_9/out_new']], 'board/pc-out-opus1535a');
  r = run('dropcheckouts', named);
  assert(fs.existsSync(path.join(named, 'new')) && /results not relayed yet: board\/pc-out-opus1535a:out_1: out_new\/result\.txt is not on the relay/.test(r.out), 'the job branch with the attempt under another folder proves nothing: ' + r.out);
  relay([[path.join(named, 'out_new'), 'out_1/out_new']], 'board/pc-out-opus1535a');
  r = run('dropcheckouts', named);
  assert.equal(r.status, 0, r.out);
  assert(!fs.existsSync(path.join(named, 'new')) && /checkout new removed after the job/.test(r.out) && !fs.existsSync(path.join(named, 'relay_receipt.txt')), 'the job branch at the attempt folder clears the checkout, no receipt written: ' + r.out);
  assert.equal(fs.readFileSync(path.join(named, 'out_new', 'result.txt'), 'utf8'), 'opus1535a result\n', 'results stay');
  // the head's relay_branch.txt wins over the job name; wrong bytes on it keep the checkout
  const recorded = job1535('opus1535b', 'out_20261122_041500_123');
  write(path.join(recorded, 'relay_branch.txt'), 'board/pc-out-1535rec out_20261122_041500_123\r\n');
  const wrong = path.join(tmp, 'stage1535');
  write(path.join(wrong, 'out_new', 'result.txt'), 'other bytes\n');
  relay([[wrong, 'out_20261122_041500_123']], 'board/pc-out-1535rec');
  relay([[path.join(recorded, 'out_new'), 'out_20261122_041500_123/out_new']], 'board/pc-out-opus1535b');
  r = run('dropcheckouts', recorded);
  assert(fs.existsSync(path.join(recorded, 'new')) && /board\/pc-out-1535rec:out_20261122_041500_123: out_new\/result\.txt differs on the relay/.test(r.out), 'relay_branch.txt names the place, and other bytes there prove nothing: ' + r.out);
  relay([[path.join(recorded, 'out_new'), 'out_20261122_041500_123/out_new']], 'board/pc-out-1535rec');
  r = run('dropcheckouts', recorded);
  assert(!fs.existsSync(path.join(recorded, 'new')), 'the recorded branch with the right bytes clears it: ' + r.out);
  // a branch the shared mirror still has but origin deleted proves nothing
  const gone = job1535('opus1535c');
  relay([[path.join(gone, 'out_new'), 'out_1/out_new']], 'board/pc-out-opus1535c');
  git(['--git-dir', path.join(vt, 'repo-mirror.git'), 'fetch', '-q', 'origin', '+refs/heads/board/pc-out-opus1535c:refs/heads/board/pc-out-opus1535c']);
  git(['--git-dir', source, 'update-ref', '-d', 'refs/heads/board/pc-out-opus1535c']);
  r = run('dropcheckouts', gone);
  assert(fs.existsSync(path.join(gone, 'new')) && /branch board\/pc-out-opus1535c \(from the job name\) is not on origin/.test(r.out), 'a branch gone from origin keeps the checkout: ' + r.out);
  // Issue 1657 (Ryan, Nov 22): results go to the private relay repo. relay_branch.txt names relay/pc-out-<job> (branch
  // pc-out-<job> of the relay repo); the head makes and fetches the relay repo's own mirror, proves the same way, and a
  // branch only on the main repo under that name proves nothing for it.
  git(['init', '-q', '--bare', relaySource]);
  const rel = job1535('opus1657rel', 'out_20261122_130000_1');
  write(path.join(rel, 'relay_branch.txt'), 'relay/pc-out-opus1657rel out_20261122_130000_1\r\n');
  relay([[path.join(rel, 'out_new'), 'out_20261122_130000_1/out_new']], 'board/pc-out-opus1657rel');
  r = run('dropcheckouts', rel);
  assert(fs.existsSync(path.join(rel, 'new')) && /results not relayed yet: relay\/pc-out-opus1657rel:out_20261122_130000_1: branch relay\/pc-out-opus1657rel \(from relay_branch\.txt\) is not on origin/.test(r.out), 'a relay-repo receipt is not proven by the main repo: ' + r.out);
  const wrong1657 = path.join(tmp, 'stage1657');
  write(path.join(wrong1657, 'out_new', 'result.txt'), 'other bytes\n');
  relay([[wrong1657, 'out_20261122_130000_1']], 'pc-out-opus1657rel', relaySource);
  r = run('dropcheckouts', rel);
  assert(fs.existsSync(path.join(rel, 'new')) && /relay\/pc-out-opus1657rel:out_20261122_130000_1: out_new\/result\.txt differs on the relay/.test(r.out), 'other bytes on the relay repo prove nothing: ' + r.out);
  assert(fs.existsSync(path.join(vt, 'relay-mirror.git', 'HEAD')), 'the head made the relay mirror');
  relay([[path.join(rel, 'out_new'), 'out_20261122_130000_1/out_new']], 'pc-out-opus1657rel', relaySource);
  r = run('dropcheckouts', rel);
  assert.equal(r.status, 0, r.out);
  assert(!fs.existsSync(path.join(rel, 'new')) && /results relayed: 1 of 1 result file\(s\) are on relay\/pc-out-opus1657rel/.test(r.out), 'the relay repo with the right bytes clears it: ' + r.out);
  assert.equal(fs.readFileSync(path.join(rel, 'out_new', 'result.txt'), 'utf8'), 'opus1657rel result\n', 'results stay');
  // by the job's own name: the relay repo wins once its mirror holds pc-out-<job>
  const relNamed = job1535('opus1657named');
  relay([[path.join(relNamed, 'out_new'), 'out_1/out_new']], 'pc-out-opus1657named', relaySource);
  git(['--git-dir', path.join(vt, 'relay-mirror.git'), 'fetch', '-q', 'origin', '+refs/heads/pc-out-opus1657named:refs/heads/pc-out-opus1657named']);
  r = run('dropcheckouts', relNamed);
  assert(!fs.existsSync(path.join(relNamed, 'new')) && /on relay\/pc-out-opus1657named under out_1/.test(r.out), 'the job name finds the relay repo branch: ' + r.out);
  // Issue 1396 (Board, Nov 22): the relay lands after the tail, so the janitor runs dropjobs over every PASS attempt that
  // still lists checkouts. dry removes and fetches nothing; the live run clears only what the relay proof clears.
  const later = job1535('opus1396later');
  relay([[path.join(later, 'out_new'), 'out_1/out_new']], 'board/pc-out-opus1396later');
  const laterJob = path.dirname(later);
  // a dry run never fetches, so the mirror must already hold the relay (on the PC other jobs refresh it); a live run fetches
  r = run('dropjobs', laterJob, 'dry');
  assert(fs.existsSync(path.join(later, 'new')) && /branch board\/pc-out-opus1396later \(from the job name\) is not on origin at the shared mirror's commit/.test(r.out), 'a dry run does not fetch: ' + r.out);
  git(['--git-dir', path.join(vt, 'repo-mirror.git'), 'fetch', '-q', 'origin', '+refs/heads/board/pc-out-opus1396later:refs/heads/board/pc-out-opus1396later']);
  r = run('dropjobs', laterJob, 'dry');
  assert.equal(r.status, 0, r.out);
  assert(fs.existsSync(path.join(later, 'new')) && r.out.includes(`checkout new would be checked and removed after the relay: ${path.join(later, 'new')}`), 'the dry run names the checkout and keeps it: ' + r.out);
  assert(!/would be checked and removed/.test(r.out.split('\n').filter(l => !l.includes('opus1396later')).join('\n')), 'nothing else is nominated: ' + r.out);
  assert(!/disk: checkouts freed/.test(r.out), 'a dry run frees nothing');
  assert.notEqual(run('dropjobs', laterJob, 'now').status, 0, 'dropjobs takes only dry');
  assert.notEqual(run('dropjobs').status, 0, 'dropjobs needs one job folder');
  assert.notEqual(run('dropjobs', later).status, 0, 'an attempt folder is not a job folder');
  r = run('dropjobs', path.dirname(gone));
  assert(fs.existsSync(path.join(gone, 'new')) && r.out.includes(`checkouts kept: ${gone} (`), 'a refused attempt is logged as kept: ' + r.out);
  r = run('dropjobs', laterJob);
  assert.equal(r.status, 0, r.out);
  assert(!fs.existsSync(path.join(later, 'new')) && /checkout new removed after the job/.test(r.out) && /disk: checkouts freed/.test(r.out), 'the live run clears the relayed attempt: ' + r.out);
  assert(fs.existsSync(path.join(gone, 'new')) && fs.existsSync(path.join(attempt, 'new')), 'and nothing the proof refuses: ' + r.out);
  // Issue 1396 (Board, Nov 22): the relay lands after the tail, so the tail's waiter (dropwait) asks origin until the branch
  // shows up, then runs the same proof and drop for its attempt only. Without the branch it keeps everything at its limit.
  const waitRun = (extra, ...args) => {
    const w = spawnSync(shell, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(jobs, 'opus_job_head.ps1'), ...args], { env: { ...env, ...extra }, encoding: 'utf8', timeout: 90000 });
    if (w.error) throw w.error;
    return { status: w.status, out: `${w.stdout}\n${w.stderr}` };
  };
  const waited = job1535('opus1396wait');
  r = waitRun({ OJ_DROPWAIT_POLL_SECONDS: '1', OJ_DROPWAIT_SECONDS: '3', PC_TEST_COMMAND_LINES: 'fixture.exe unrelated' }, 'dropwait', waited);
  assert.equal(r.status, 0, r.out);
  assert(fs.existsSync(path.join(waited, 'new')) && /waiting for board\/pc-out-opus1396wait on origin \(from the job name\)/.test(r.out) && /still lists checkouts after 3 s; the janitor's relay sweep handles it later/.test(r.out), 'no relay: the waiter keeps the checkout and stops at its limit: ' + r.out);
  r = run('dropwait', waited, 'dry');
  assert(fs.existsSync(path.join(waited, 'new')) && /board\/pc-out-opus1396wait is not on origin yet \(dry: one look\)/.test(r.out) && !/disk: checkouts freed/.test(r.out), 'dry looks once: ' + r.out);
  assert.notEqual(run('dropwait', waited, 'now').status, 0, 'dropwait takes only dry');
  const staged = relay([[path.join(waited, 'out_new'), 'out_1/out_new']], 'board/pc-out-stage1396wait');
  const stagedSha = git(['--git-dir', source, 'rev-parse', `refs/heads/${staged}`]);
  // the relay lands two seconds after the waiter starts
  const landed = spawnSync('bash', ['-c', '(sleep 2; git --git-dir "$1" update-ref refs/heads/board/pc-out-opus1396wait "$2") & exec "$3" -NoProfile -ExecutionPolicy Bypass -File "$4" dropwait "$5"',
    'x', source, stagedSha, shell, path.join(jobs, 'opus_job_head.ps1'), waited], { env: { ...env, OJ_DROPWAIT_POLL_SECONDS: '1', OJ_DROPWAIT_SECONDS: '60', PC_TEST_COMMAND_LINES: 'fixture.exe unrelated' }, encoding: 'utf8', timeout: 90000 });
  const landedOut = `${landed.stdout}\n${landed.stderr}`;
  assert.equal(landed.status, 0, landedOut);
  assert(!fs.existsSync(path.join(waited, 'new')) && landedOut.includes(`relay branch board/pc-out-opus1396wait is on origin at ${stagedSha}`) && /checkout new removed after the job/.test(landedOut) && /disk: checkouts freed/.test(landedOut), 'the waiter clears the checkout once the relay lands: ' + landedOut);
  assert.equal(fs.readFileSync(path.join(waited, 'out_new', 'result.txt'), 'utf8'), 'opus1396wait result\n', 'results stay');
  assert(fs.existsSync(path.join(gone, 'new')), 'and only its own attempt');
  // Issue 1657 with 1644: the waiter asks the relay repo (not the main repo) for a relay/pc-out-<job> place
  const rwait = job1535('opus1657wait', 'out_20261122_190000_1');
  write(path.join(rwait, 'relay_branch.txt'), 'relay/pc-out-opus1657wait out_20261122_190000_1\r\n');
  relay([[path.join(rwait, 'out_new'), 'out_20261122_190000_1/out_new']], 'pc-out-opus1657wait', relaySource);
  r = waitRun({ OJ_DROPWAIT_POLL_SECONDS: '1', OJ_DROPWAIT_SECONDS: '30', PC_TEST_COMMAND_LINES: 'fixture.exe unrelated' }, 'dropwait', rwait);
  assert.equal(r.status, 0, r.out);
  assert(!fs.existsSync(path.join(rwait, 'new')) && /relay branch relay\/pc-out-opus1657wait is on origin at [0-9a-f]{40}/.test(r.out) && /checkout new removed after the job/.test(r.out), 'the waiter proves a relay-repo place: ' + r.out);
  // Artoo on PR 1644: the waiter checks what the janitor checks before a removal (the Board keep list, no running process
  // naming the attempt, the PC pause, the job lease) and keeps everything while any holds; a passing refusal is tried
  // again at the next look on the same relay, without waiting for the branch to move.
  const guarded = job1535('opus1396guard');
  relay([[path.join(guarded, 'out_new'), 'out_1/out_new']], 'board/pc-out-opus1396guard');
  const quick = { OJ_DROPWAIT_POLL_SECONDS: '1', OJ_DROPWAIT_SECONDS: '2', PC_TEST_COMMAND_LINES: 'fixture.exe unrelated' };
  write(path.join(vt, 'janitor_keep.txt'), `# Board\r\n${path.join(guarded, 'new')}\r\n`);
  r = waitRun(quick, 'dropwait', guarded);
  assert(fs.existsSync(path.join(guarded, 'new')) && /checkouts kept for now: \S+ \(on the Board keep list/.test(r.out), 'a keep-listed checkout survives its relay: ' + r.out);
  fs.rmSync(path.join(vt, 'janitor_keep.txt'));
  r = waitRun({ ...quick, PC_TEST_COMMAND_LINES: `godot.exe --path "${path.join(guarded, 'new')}"` }, 'dropwait', guarded);
  assert(fs.existsSync(path.join(guarded, 'new')) && /a running process names this job folder/.test(r.out), 'a checkout in use survives its relay: ' + r.out);
  // Artoo on PR 1644 at 1c264710: the issue lock as well. While a runner for issue 1396 holds it, the relayed checkout stays.
  const runTemp = path.join(tmp, 'runtemp1644');
  fs.mkdirSync(runTemp, { recursive: true });
  const issueLock = path.join(runTemp, 'voidsworn-runner-issue-1396.lock');
  // The holder is its own script (Artoo on PR 1644: bash expanded $h inside a quoted -Command) and says when it holds.
  const holder = path.join(tmp, 'hold1644.ps1'), ready = path.join(tmp, 'hold1644.ready');
  write(holder, '$h = [IO.File]::Open($env:LOCK1644, "OpenOrCreate", "ReadWrite", "None")\n[IO.File]::WriteAllText($env:READY1644, "held")\nStart-Sleep -Seconds 12\n$h.Dispose()\n');
  const held = spawnSync('bash', ['-c', '"$1" -NoProfile -ExecutionPolicy Bypass -File "$4" & n=0; while [ ! -f "$5" ] && [ $n -lt 300 ]; do sleep 0.1; n=$((n+1)); done; [ -f "$5" ] || exit 9; exec "$1" -NoProfile -ExecutionPolicy Bypass -File "$2" dropwait "$3"',
    'x', shell, path.join(jobs, 'opus_job_head.ps1'), guarded, holder, ready], { env: { ...env, ...quick, PC_RUN_TEMP: runTemp, LOCK1644: issueLock, READY1644: ready }, encoding: 'utf8', timeout: 90000 });
  const heldOut = `${held.stdout}\n${held.stderr}`;
  assert(fs.existsSync(path.join(guarded, 'new')) && /checkouts kept for now: \S+ \(the issue lock \S+voidsworn-runner-issue-1396\.lock is held or not a plain file\)/.test(heldOut), 'a held issue lock keeps the relayed checkout: ' + heldOut);
  const pauseFile = path.join(tmp, 'pause1644.txt');
  write(pauseFile, 'GPU not cleared: paused by the Board for a fixture\r\n');
  const resumed = spawnSync('bash', ['-c', '(sleep 2; rm -f "$1") & exec "$2" -NoProfile -ExecutionPolicy Bypass -File "$3" dropwait "$4"',
    'x', pauseFile, shell, path.join(jobs, 'opus_job_head.ps1'), guarded], { env: { ...env, ...quick, OJ_DROPWAIT_SECONDS: '60', PC_CLEANUP_PAUSE_FILE: pauseFile }, encoding: 'utf8', timeout: 90000 });
  const resumedOut = `${resumed.stdout}\n${resumed.stderr}`;
  assert.equal(resumed.status, 0, resumedOut);
  assert(/checkouts kept for now: \S+ \(the Board PC pause is active\)/.test(resumedOut) && !fs.existsSync(path.join(guarded, 'new')) && /checkout new removed after the job/.test(resumedOut), 'a pause holds the drop, and the same relay clears it once the pause ends: ' + resumedOut);
  // Review of PR 1644 (issue 1647): the waiter's remaining edges.
  const q = { OJ_DROPWAIT_POLL_SECONDS: '1', OJ_DROPWAIT_SECONDS: '2', PC_TEST_COMMAND_LINES: 'fixture.exe unrelated' };
  // a failed or unfinished attempt is not waited for at all
  const unfinishedWait = path.join(vt, 'opus1647u', 'out_1');
  assert.equal(run('checkout', unfinishedWait, 'new', two).status, 0);
  write(path.join(unfinishedWait, 'out_new', 'result.txt'), 'unfinished\n');
  r = waitRun(q, 'dropwait', unfinishedWait);
  assert(/is not a passed attempt; nothing to wait for/.test(r.out) && !/waiting for/.test(r.out), 'no wait for an attempt that did not pass: ' + r.out);
  // the attempt can come from the environment the tail sets
  r = waitRun({ ...q, OJ_DROPWAIT_ATTEMPT: unfinishedWait }, 'dropwait');
  assert(/is not a passed attempt/.test(r.out), 'OJ_DROPWAIT_ATTEMPT names the attempt: ' + r.out);
  // dry with the relay on origin and in the mirror: the proof runs, nothing is removed, no lease or log is made
  const dryRelayed = job1535('opus1647d');
  relay([[path.join(dryRelayed, 'out_new'), 'out_1/out_new']], 'board/pc-out-opus1647d');
  git(['--git-dir', path.join(vt, 'repo-mirror.git'), 'fetch', '-q', 'origin', '+refs/heads/board/pc-out-opus1647d:refs/heads/board/pc-out-opus1647d']);
  r = waitRun({ ...q, OJ_DROPWAIT_LOG: '1' }, 'dropwait', dryRelayed, 'dry');
  assert(fs.existsSync(path.join(dryRelayed, 'new')) && r.out.includes(`checkout new would be checked and removed after the relay: ${path.join(dryRelayed, 'new')}`), 'dry runs the proof on a relayed attempt and removes nothing: ' + r.out);
  assert(!fs.existsSync(path.join(path.dirname(dryRelayed), '.voidsworn-run-active')) && !fs.existsSync(path.join(path.dirname(dryRelayed), 'dropwait_out_1.txt')), 'dry takes no lease and writes no log');
  // a relayed sibling of the same job is left to its own waiter; a command line naming only the job folder holds the drop
  const sibA = job1535('opus1647s', 'out_1'), sibB = job1535('opus1647s', 'out_2');
  relay([[path.join(sibA, 'out_new'), 'out_1/out_new'], [path.join(sibB, 'out_new'), 'out_2/out_new']], 'board/pc-out-opus1647s');
  r = waitRun({ ...q, PC_TEST_COMMAND_LINES: `godot.exe --path "${path.dirname(sibB)}"` }, 'dropwait', sibB);
  assert(fs.existsSync(path.join(sibB, 'new')) && /a running process names this job folder/.test(r.out), 'a process naming only the job folder holds the drop: ' + r.out);
  r = waitRun({ ...q, OJ_DROPWAIT_LOG: '1' }, 'dropwait', sibB);
  assert(!fs.existsSync(path.join(sibB, 'new')) && fs.existsSync(path.join(sibA, 'new')), 'the waiter clears its own attempt only, never a relayed sibling: ' + r.out);
  assert(fs.statSync(path.join(path.dirname(sibB), 'dropwait_out_2.txt')).isFile(), 'a live waiter with OJ_DROPWAIT_LOG=1 writes its log beside the attempt');
  // a result root that is a link to other bytes is refused, even when those bytes are on the relay
  const linked = job1535('opus1647j');
  const elsewhereRoot = path.join(tmp, 'elsewhere1647', 'out_new');
  write(path.join(elsewhereRoot, 'result.txt'), 'opus1647j result\n');
  fs.rmSync(path.join(linked, 'out_new'), { recursive: true });
  fs.symlinkSync(elsewhereRoot, path.join(linked, 'out_new'), 'dir');
  relay([[elsewhereRoot, 'out_1/out_new']], 'board/pc-out-opus1647j');
  r = waitRun(q, 'dropwait', linked);
  assert(fs.existsSync(path.join(linked, 'new')) && /a result folder is not a plain folder/.test(r.out), 'a linked result root proves nothing: ' + r.out);
  // an unfinished earlier removal (a recorded tomb) goes only after the same fresh proof under the mirror lock: with the
  // relay moved to other bytes it stays; back on the right bytes it is finished
  const tombed = job1535('opus1647t');
  fs.renameSync(path.join(tombed, 'new'), path.join(tombed, 'new.removing'));
  write(path.join(tombed, 'removing.txt'), `new.removing ${two}\r\n`);
  const tombWrong = path.join(tmp, 'tomb1647wrong', 'out_new');
  write(path.join(tombWrong, 'result.txt'), 'other bytes\n');
  relay([[tombWrong, 'out_1/out_new']], 'board/pc-out-opus1647t');
  r = waitRun(q, 'dropwait', tombed);
  assert(fs.existsSync(path.join(tombed, 'new.removing')) && /results not relayed yet/.test(r.out) && !/finished an earlier removal/.test(r.out), 'a tomb stays while the relay holds other bytes: ' + r.out);
  // a record that does not name the listed pin is left alone
  write(path.join(tombed, 'removing.txt'), `new.removing ${one1}\r\n`);
  relay([[path.join(tombed, 'out_new'), 'out_1/out_new']], 'board/pc-out-opus1647t');
  r = waitRun(q, 'dropwait', tombed);
  assert(fs.existsSync(path.join(tombed, 'new.removing')) && /does not name the listed pin, left alone/.test(r.out), 'a tomb record must name the listed pin: ' + r.out);
  write(path.join(tombed, 'removing.txt'), `new.removing ${two}\r\n`);
  // Artoo on PR 1644 at cb55a261: the final checks run before a tomb goes too. A keep entry added while the waiter waits
  // for the mirror lock (after its first checks passed) keeps the tomb.
  const mirrorHolder = path.join(tmp, 'mirror1644.ps1'), mirrorReady = path.join(tmp, 'mirror1644.ready');
  write(mirrorHolder, '$h = [IO.File]::Open($env:LOCK1644, "OpenOrCreate", "ReadWrite", "None")\n[IO.File]::WriteAllText($env:READY1644, "held")\nStart-Sleep -Seconds 10\n$h.Dispose()\n');
  const lateKeep = spawnSync('bash', ['-c', '"$1" -NoProfile -ExecutionPolicy Bypass -File "$2" & n=0; while [ ! -f "$3" ] && [ $n -lt 300 ]; do sleep 0.1; n=$((n+1)); done; [ -f "$3" ] || exit 9; "$1" -NoProfile -ExecutionPolicy Bypass -File "$4" dropwait "$5" & w=$!; sleep 5; printf "# Board\\r\\n%s\\r\\n" "$5" > "$6"; wait $w',
    'x', shell, mirrorHolder, mirrorReady, path.join(jobs, 'opus_job_head.ps1'), tombed, path.join(vt, 'janitor_keep.txt')], { env: { ...env, ...q, OJ_DROPWAIT_SECONDS: '20', LOCK1644: path.join(vt, 'repo-mirror.git') + '.lock', READY1644: mirrorReady }, encoding: 'utf8', timeout: 90000 });
  const lateOut = `${lateKeep.stdout}\n${lateKeep.stderr}`;
  fs.rmSync(path.join(vt, 'janitor_keep.txt'), { force: true });
  assert.equal(lateKeep.status, 0, lateOut);
  assert(fs.existsSync(path.join(tombed, 'new.removing')) && /earlier removal still unfinished: \S+ \(held back: on the Board keep list/.test(lateOut) && !/finished an earlier removal/.test(lateOut), 'a keep entry added during the mirror wait keeps the tomb: ' + lateOut);
  r = waitRun(q, 'dropwait', tombed);
  assert(!fs.existsSync(path.join(tombed, 'new.removing')) && /finished an earlier removal/.test(r.out), 'with the right bytes on the relay the tomb is finished: ' + r.out);
  assert.equal(fs.readFileSync(path.join(later, 'out_new', 'result.txt'), 'utf8'), 'opus1396later result\n', 'results stay');
  // Review of PR 1592: the sweep keeps a checkout whose reflog holds a commit no mirror ref reaches (a detached checkout
  // that went back to its pin), and one with a second worktree; and it finishes a recorded <name>.removing left alone.
  const relayed = (job) => {
    const at = job1535(job);
    relay([[path.join(at, 'out_new'), 'out_1/out_new']], `board/pc-out-${job}`);
    git(['--git-dir', path.join(vt, 'repo-mirror.git'), 'fetch', '-q', 'origin', `+refs/heads/board/pc-out-${job}:refs/heads/board/pc-out-${job}`]);
    return at;
  };
  const reflogAt = relayed('opus1396reflog');
  const reflogRepo = path.join(reflogAt, 'new');
  git(['-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '--allow-empty', '-m', 'only in the reflog'], reflogRepo);
  const onlyReflog = git(['rev-parse', 'HEAD'], reflogRepo);
  git(['checkout', '-q', '--detach', two], reflogRepo);
  assert.equal(fs.readFileSync(path.join(reflogRepo, '.git', 'HEAD'), 'utf8').trim(), two, 'back at its pin');
  r = run('dropjobs', path.dirname(reflogAt));
  assert(fs.existsSync(reflogRepo) && r.out.includes(`checkout new kept: ${reflogRepo} (commit ${onlyReflog} is on no branch or tag of the shared mirror`), 'a reflog-only commit keeps the checkout: ' + r.out);
  const treeAt = relayed('opus1396wt');
  const treeRepo = path.join(treeAt, 'new');
  git(['worktree', 'add', '-q', '--detach', path.join(tmp, 'opus1396wt-linked'), two], treeRepo);
  r = run('dropjobs', path.dirname(treeAt));
  assert(fs.existsSync(treeRepo) && r.out.includes(`checkout new kept: ${treeRepo} (it has 2 worktrees, not 1)`), 'a second worktree keeps the checkout: ' + r.out);
  const tombAt = relayed('opus1396tomb');
  fs.renameSync(path.join(tombAt, 'new'), path.join(tombAt, 'new.removing'));
  fs.writeFileSync(path.join(tombAt, 'removing.txt'), `new.removing ${two}\r\n`);
  r = run('dropjobs', path.dirname(tombAt), 'dry');
  assert(fs.existsSync(path.join(tombAt, 'new.removing')) && r.out.includes(`earlier removal would be finished after the relay proof if removing.txt recorded it: ${path.join(tombAt, 'new.removing')}`), 'a dry sweep names a left tomb and keeps it: ' + r.out);
  r = run('dropjobs', path.dirname(tombAt));
  assert(!fs.existsSync(path.join(tombAt, 'new.removing')) && r.out.includes(`finished an earlier removal`), 'the live sweep finishes a recorded tomb with no checkout left beside it: ' + r.out);
  assert(fs.existsSync(path.join(tombAt, 'out_new', 'result.txt')), 'results stay');
}
// A file locked for a moment (Board, AFTERRELAY2 on Nov 21: a pack .idx denied, free a minute later) is retried; one
// locked past the retries leaves <name>.removing, which the next run finishes. A read-only folder stands in for the lock.
if (process.getuid && process.getuid() !== 0) {
  const lockJob = path.join(vt, 'opus1498lock');
  const lockAttempt = (n) => {
    const at = path.join(lockJob, n);
    assert.equal(run('checkout', at, 'new', two).status, 0);
    write(path.join(at, 'out_new', 'result.txt'), `lock ${n}\n`);
    write(path.join(at, 'done.txt'), 'PASS\r\n');
    return [at, relay([[path.join(at, 'out_new'), `${n}/out_new`]])];
  };
  env.PC_TEST_RETRY_MS = '1000';
  const [l1, l1relay] = lockAttempt('out_1');
  fs.chmodSync(path.join(l1, 'new', 'godot'), 0o555);
  const unlock = spawn('sh', ['-c', `sleep 2; chmod 755 '${path.join(l1, 'new.removing', 'godot')}'`], { stdio: 'ignore' });
  r = run('dropcheckouts', l1, l1relay, 'out_1');
  assert(!fs.existsSync(path.join(l1, 'new')) && !fs.existsSync(path.join(l1, 'new.removing')) && /checkout new removed after the job/.test(r.out) && /still locked, trying again in \d+ ms/.test(r.out), 'a short lock is retried, logged, then the checkout goes: ' + r.out);
  unlock.unref();
  env.PC_TEST_RETRY_MS = '50';
  const [l2, l2relay] = lockAttempt('out_2');
  fs.chmodSync(path.join(l2, 'new', 'godot'), 0o555);
  r = run('dropcheckouts', l2, l2relay, 'out_2');
  assert(/checkout new kept: .*partly removed; the rest is .*new\.removing/.test(r.out) && fs.existsSync(path.join(l2, 'new.removing')), 'a lasting lock leaves the renamed folder and says so: ' + r.out);
  fs.chmodSync(path.join(l2, 'new.removing', 'godot'), 0o755);
  // a .removing folder this file did not record, and a recorded name that is no listed checkout, are left alone
  write(path.join(l2, 'notes.removing', 'keep.txt'), 'not a checkout');
  write(path.join(l2, 'other.removing', 'keep.txt'), 'not a listed checkout');
  fs.appendFileSync(path.join(l2, 'removing.txt'), `other.removing ${two}\r\n`);
  r = run('dropcheckouts', l2);
  assert(!fs.existsSync(path.join(l2, 'new.removing')) && /finished an earlier removal/.test(r.out), 'the next run finishes the removal: ' + r.out);
  assert.equal(fs.readFileSync(path.join(l2, 'notes.removing', 'keep.txt'), 'utf8'), 'not a checkout', 'an unrecorded .removing folder is untouched');
  assert.equal(fs.readFileSync(path.join(l2, 'other.removing', 'keep.txt'), 'utf8'), 'not a listed checkout', 'a recorded name that is no listed checkout is untouched');
  assert(/removing\.txt line not accepted, left alone: other\.removing/.test(r.out), 'and says so: ' + r.out);
  assert(!/new\.removing/.test(fs.readFileSync(path.join(l2, 'removing.txt'), 'utf8')), 'the finished name leaves the record');
  delete env.PC_TEST_RETRY_MS;
}
const mine = relay([[path.join(attempt, 'out_new'), 'out_1/out_new']]);
const pause = path.join(tmp, 'gpu_go.txt');
write(pause, 'GPU not cleared: paused by the Board for a check\n');
env.PC_CLEANUP_PAUSE_FILE = pause;
r = run('dropcheckouts', attempt, mine, 'out_1');
assert.equal(r.status, 0, r.out);
assert(fs.existsSync(path.join(attempt, 'new')) && fs.existsSync(path.join(attempt, 'old')), 'the PC pause removes nothing: ' + r.out);
assert.match(r.out, /checkout new kept: .*pause/);
assert(!fs.existsSync(path.join(attempt, 'out_work', 'checkout_leftovers')), 'the pause saves nothing either');
fs.writeFileSync(pause, 'GPU cleared\n');
fs.writeFileSync(path.join(attempt, 'old', '.git', 'HEAD'), two + '\n');
const elsewhere = path.join(tmp, 'notjob', 'out_1');
write(path.join(elsewhere, 'checkouts.txt'), `x ${two}\r\n`);
write(path.join(elsewhere, 'x', '.git', 'HEAD'), two + '\n');
r = run('dropcheckouts', elsewhere);
assert(fs.existsSync(path.join(elsewhere, 'x')) && /not a job attempt folder/.test(r.out), 'a folder outside voidsworn_test\\<job>\\out_* is refused');
r = run('dropcheckouts', attempt);
assert.equal(r.status, 0, r.out);
assert(!fs.existsSync(path.join(attempt, 'new')), 'the pinned new checkout is removed: ' + r.out);
assert.match(r.out, /checkout new removed after the job/);
assert(!fs.existsSync(path.join(attempt, 'out_new', 'checkout_leftovers')), 'nothing to save from a checkout of proven leftovers');
assert(fs.existsSync(path.join(outside, 'keep.txt')), 'a link inside a checkout is removed as a link, never followed');
assert(fs.existsSync(path.join(attempt, 'old')) && /checkout old kept: .*no longer the pin/.test(r.out), 'a checkout whose HEAD moved is kept');
assert(/checkout stray kept: .*not a plain folder/.test(r.out) && fs.existsSync(path.join(attempt, 'stray')), 'a listed name that is not a checkout folder is kept');
assert(/line not accepted, ignored: \.\.\/escape/.test(r.out), 'a path in checkouts.txt is never followed');
// work: the edit goes into changes.patch and the new file is copied, then the checkout goes
const wl = path.join(attempt, 'out_work', 'checkout_leftovers');
assert(!fs.existsSync(path.join(attempt, 'work')), 'a checkout whose work was saved is removed: ' + r.out);
assert.match(r.out, /saved 1 changed and 1 new file\(s\)/);
assert.match(fs.readFileSync(path.join(wl, 'changes.patch'), 'utf8'), /\+an edit left by a step/, 'the edit is in the patch');
assert.equal(fs.readFileSync(path.join(wl, 'files', 'godot', 'notes.txt'), 'utf8'), 'a new output inside the checkout', 'the new file is saved');
assert.match(fs.readFileSync(path.join(wl, 'leftovers.txt'), 'utf8'), new RegExp(`^HEAD ${two}\\r?$[\\s\\S]*changed \\(in changes\\.patch\\): godot/project\\.godot[\\s\\S]*copied ${sha('a new output inside the checkout')} \\d+ godot/notes\\.txt`, 'm'));
// shipout: the changed copy, the new ship, the unproven sidecar and the same-size different-bytes file are all saved
const sl = path.join(attempt, 'out_shipout', 'checkout_leftovers', 'files', 'godot');
assert(!fs.existsSync(path.join(attempt, 'shipout')), 'the ship output checkout goes once its files are saved: ' + r.out);
for (const [f, text] of [['assets/ships/S2/S2.glb', 'a re-export the job wrote over the copy'], ['assets/ships/S9/S9.glb', 'a new ship the job made'],
  ['gen/orphan.res.import', 'a sidecar with no proven file'], ['gen/same.res', 'BBBB']]) {
  assert.equal(fs.readFileSync(path.join(sl, ...f.split('/')), 'utf8'), text, f + ' is saved with the results');
}
// mapsout: the ignored munition images are never treated as rebuildable; they are saved with the results first (PR 1529)
const ml = path.join(attempt, 'out_mapsout', 'checkout_leftovers', 'files', 'godot', 'fx', 'munition_bodies');
assert(!fs.existsSync(path.join(attempt, 'mapsout')), 'the munition image checkout goes once its images are saved: ' + r.out);
for (const [f, text] of [['stray_albedo.jpg', 'an ignored map with no tracked body'], ['corsair_rockets_corsair_rockets_hull_albedo.jpg', 'a hand-painted map named like an extracted one']]) {
  assert.equal(fs.readFileSync(path.join(ml, f), 'utf8'), text, 'munition_bodies/' + f + ' is saved with the results');
}
assert(fs.existsSync(path.join(attempt, 'big', 'godot', 'huge.bin')) && /checkout big kept: .*could not be saved .*more than/.test(r.out), 'more than the cap keeps the checkout: ' + r.out);
// staged and stashed: kept, with the staged bytes and the stash still there
assert(fs.existsSync(stg) && /checkout staged kept: .*staged: godot\/project\.godot/.test(r.out), 'a staged change keeps the checkout: ' + r.out);
assert.match(git(['diff', '--cached'], stg), /\+staged only/, 'the staged bytes survive');
assert(!fs.existsSync(path.join(attempt, 'out_staged', 'checkout_leftovers')), 'nothing is half saved for a staged change');
assert(fs.existsSync(sts) && /checkout stashed kept: .*it has a stash/.test(r.out), 'a stash keeps the checkout: ' + r.out);
assert.match(git(['stash', 'show', '-p'], sts), /\+stashed work/, 'the stash survives');
// rec: the copied ship matches its record (the shared build moved on), so only build_info.json is saved
assert(!fs.existsSync(path.join(attempt, 'rec')), 'the recorded checkout is removed: ' + r.out);
const rl = path.join(attempt, 'out_rec', 'checkout_leftovers', 'files', 'godot');
assert.equal(fs.readFileSync(path.join(rl, 'build_info.json'), 'utf8'), '{"commit":"x"}', 'build_info.json is saved');
assert.equal(fs.readFileSync(path.join(rl, 'assets', 'ships', 'B16', 'only_here.bin'), 'utf8'), 'made by the job', 'a file only in the checkout is saved');
assert(!fs.existsSync(path.join(rl, 'assets', 'ships', 'B16', 'B16_damage.glb')) && !fs.existsSync(path.join(rl, 'assets', 'ships', 'B16', 'B16_damage.glb.import')), 'a copy proven by its record and its sidecar are not saved');
assert(fs.existsSync(path.join(failedBefore, 'new')) && fs.existsSync(path.join(unfinished, 'new')), 'failed and unfinished attempts are still untouched');
assert.match(r.out, /^disk: checkouts freed \d+\.\d GB in all/m, 'the step names the GB freed');
for (const keep of ['out_new/samples.jsonl', 'new_ships_identity.txt', 'checkouts.txt', 'rec_ships_copied.txt']) assert(fs.existsSync(path.join(attempt, keep)), keep + ' stays');
r = run('dropcheckouts', failedBefore);
assert(fs.existsSync(path.join(failedBefore, 'new')) && /checkouts kept: .*failed/.test(r.out), 'a failed attempt keeps its checkouts: ' + r.out);
r = run('dropcheckouts', attempt);
assert.match(r.out, /checkout new already gone/);
delete env.PC_TEST_LEFTOVER_CAP;

// Ship clones (ship_job.bat and publish_ship.bat): dropcache removes only repo\godot\.godot; droprepo removes the clone
// after a publish when HEAD is the published commit, every local commit is in the mirror (or a merge of mirror commits),
// and its files are rebuildable or saved first.
const shipJob = (name, at = two) => {
  const j = path.join(vt, name), repo = path.join(j, 'repo');
  git(['clone', '-q', '--no-checkout', source, repo]);
  git(['-c', 'advice.detachedHead=false', 'checkout', '-q', '-B', 'shipjob', at], repo);
  return { j, repo };
};
const sa = shipJob('opus1497a');
write(path.join(sa.repo, 'godot', '.godot', 'imported', 'x.ctex'), 'cache');
r = run('dropcache', sa.j);
assert.equal(r.status, 0, r.out);
assert(!fs.existsSync(path.join(sa.repo, 'godot', '.godot')) && fs.existsSync(path.join(sa.repo, 'godot', 'project.godot')), 'only the import cache goes: ' + r.out);
assert.match(r.out, /import cache removed after the PASS/);
assert.match(run('dropcache', path.join(tmp, 'notjob')).out, /import cache kept: .*not a job folder/, 'a folder outside voidsworn_test is refused');
const exportDir = j => path.join(j, 'out', 'recipe', 'export', 'S5');
write(path.join(exportDir(sa.j), 'S5.glb'), 'the built ship');
write(path.join(sa.repo, 'godot', 'assets', 'ships', 'S5', 'S5.glb'), 'the built ship');
write(path.join(sa.repo, 'godot', 'assets', 'ships', 'S5', 'S5.glb.import'), 'sidecar');
write(path.join(sa.repo, 'godot', 'assets', 'ships', 'a4_props.gd'), 'an install rewrite\n');
write(path.join(sa.repo, 'tools', 'scratch.txt'), 'left by a stage');
r = run('droprepo', sa.j, two, 'S5');
assert(fs.existsSync(sa.repo) && /ship clone kept: results not relayed yet/.test(r.out), 'an unrelayed ship job keeps its clone: ' + r.out);
const saOther = relay([[path.join(sa.j, 'out'), 'opus1497z_out']]);
r = run('droprepo', sa.j, two, 'S5', saOther, 'opus1497a_out');
assert(fs.existsSync(sa.repo) && /ship clone kept: results not relayed yet: .* is not on the relay/.test(r.out), 'a receipt whose folder does not hold the files keeps the clone: ' + r.out);
const saRef = relay([[path.join(sa.j, 'out'), 'opus1497a_out']]);
write(path.join(sa.j, 'out', 'relay_receipt.txt'), `${saRef} opus1497a_out\r\n`);
r = run('droprepo', sa.j, one1, 'S5');
assert(fs.existsSync(sa.repo) && /ship clone kept: HEAD is .*not the published commit/.test(r.out), 'another commit keeps the clone: ' + r.out);
r = run('droprepo', sa.j, two, 'S5');
assert.equal(r.status, 0, r.out);
assert(!fs.existsSync(sa.repo), 'the published clone is removed: ' + r.out);
assert.match(r.out, /ship clone removed after the publish/);
const sal = path.join(sa.j, 'out', 'checkout_leftovers_repo');
assert.match(fs.readFileSync(path.join(sal, 'changes.patch'), 'utf8'), /\+an install rewrite/, 'a tracked install change is saved as a patch');
assert.equal(fs.readFileSync(path.join(sal, 'files', 'tools', 'scratch.txt'), 'utf8'), 'left by a stage', 'a stray file is saved');
assert(!fs.existsSync(path.join(sal, 'files', 'godot', 'assets', 'ships', 'S5')), 'installed files that match the export are not saved');
assert(fs.existsSync(path.join(exportDir(sa.j), 'S5.glb')), 'the job\'s out folder stays');
// a local commit that is not in the mirror keeps the clone; a merge of mirror commits (PAINT_BASE) does not
const sb = shipJob('opus1497b');
write(path.join(sb.repo, 'local.txt'), 'local work');
git(['add', 'local.txt'], sb.repo);
git(['-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'local'], sb.repo);
write(path.join(exportDir(sb.j), 'S5.glb'), 'x');
r = run('droprepo', sb.j, git(['rev-parse', 'HEAD'], sb.repo), 'S5', relay([[path.join(sb.j, 'out'), 'opus1497b_out']]), 'opus1497b_out');
assert(fs.existsSync(sb.repo) && /ship clone kept: commit [0-9a-f]{40} is on no branch or tag of the shared mirror/.test(r.out), 'an unpushed commit keeps the clone: ' + r.out);
const sm = shipJob('opus1497c', one1);
git(['-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'merge', '-q', '--no-ff', '--no-edit', two], sm.repo);
write(path.join(exportDir(sm.j), 'S5.glb'), 'x');
r = run('droprepo', sm.j, git(['rev-parse', 'HEAD'], sm.repo), 'S5', relay([[path.join(sm.j, 'out'), 'opus1497c_out']]), 'opus1497c_out');
assert(!fs.existsSync(sm.repo), 'a merge of two mirror commits is rebuildable: ' + r.out);
// a merge whose tree git does not rebuild from its parents (its own edits) keeps the clone (Artoo on PR 1498)
const se = shipJob('opus1497d', one1);
git(['-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'merge', '-q', '--no-ff', '--no-commit', two], se.repo);
write(path.join(se.repo, 'godot', 'project.godot'), 'an edit inside the merge\n');
git(['add', 'godot/project.godot'], se.repo);
git(['-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'merge with edits'], se.repo);
write(path.join(exportDir(se.j), 'S5.glb'), 'y');
r = run('droprepo', se.j, git(['rev-parse', 'HEAD'], se.repo), 'S5', relay([[path.join(se.j, 'out'), 'opus1497d_out']]), 'opus1497d_out');
assert(fs.existsSync(se.repo) && /ship clone kept: merge [0-9a-f]{40} is on no branch or tag of the shared mirror and git does not rebuild its exact tree/.test(r.out), 'a merge with its own edits keeps the clone: ' + r.out);
// a commit the mirror holds as an object but on no ref (its branch was deleted) keeps the clone (Artoo on PR 1498)
const fixedEnv = { ...process.env, GIT_AUTHOR_NAME: 'f', GIT_AUTHOR_EMAIL: 'f@example.invalid', GIT_COMMITTER_NAME: 'f',
  GIT_COMMITTER_EMAIL: 'f@example.invalid', GIT_AUTHOR_DATE: '1700000000 +0000', GIT_COMMITTER_DATE: '1700000000 +0000' };
const mirrorDir = path.join(vt, 'repo-mirror.git');
const orphanTree = git(['rev-parse', `${two}^{tree}`], work);
const mk = cwdArgs => { const rr = spawnSync('git', [...cwdArgs, 'commit-tree', orphanTree, '-p', two, '-m', 'orphan'], { env: fixedEnv, encoding: 'utf8' }); assert.equal(rr.status, 0, rr.stderr); return rr.stdout.trim(); };
const orphan = mk(['--git-dir', mirrorDir]);
const so2 = shipJob('opus1497f');
assert.equal(mk(['-C', so2.repo]), orphan, 'the same commit exists in the clone');
git(['reset', '-q', '--hard', orphan], so2.repo);
git(['branch', '-f', 'main', orphan], so2.repo);
r = run('droprepo', so2.j, orphan, 'S5', relay([[path.join(sa.j, 'out'), 'opus1497f_out']]), 'opus1497f_out');
assert(fs.existsSync(so2.repo) && /ship clone kept: commit [0-9a-f]{40} is on no branch or tag of the shared mirror/.test(r.out), 'an unreferenced mirror object is not a backup: ' + r.out);
// a local-only tag keeps the clone even when HEAD and the branches are on the mirror
const st = shipJob('opus1497g');
write(path.join(st.repo, 'tagged.txt'), 'tagged work');
git(['add', 'tagged.txt'], st.repo);
git(['-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'tagged'], st.repo);
git(['tag', 'keepme'], st.repo);
git(['reset', '-q', '--hard', two], st.repo);
r = run('droprepo', st.j, two, 'S5', relay([[path.join(sa.j, 'out'), 'opus1497g_out']]), 'opus1497g_out');
assert(fs.existsSync(st.repo) && /ship clone kept: ref refs\/tags\/keepme is not in the shared mirror with the same object/.test(r.out), 'a local-only tag keeps the clone: ' + r.out);
assert.equal(git(['rev-parse', 'keepme'], st.repo).length, 40, 'the tag survives');
// a local-only annotated tag on a commit the mirror already has also keeps the clone: its name and message are work
const sat = shipJob('opus1497h');
git(['-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'tag', '-a', 'note1497', '-m', 'a note only here', two], sat.repo);
git(['reset', '-q', '--hard', two], sat.repo);
r = run('droprepo', sat.j, two, 'S5', relay([[path.join(sa.j, 'out'), 'opus1497h_out']]), 'opus1497h_out');
assert(fs.existsSync(sat.repo) && /ship clone kept: ref refs\/tags\/note1497 is not in the shared mirror with the same object/.test(r.out), 'a local annotated tag on a mirrored commit keeps the clone: ' + r.out);
assert.equal(git(['cat-file', '-p', 'note1497'], sat.repo).includes('a note only here'), true, 'the annotation survives');
// a link above the import cache: dropcache refuses, and the folder the link points to survives
const sl2 = shipJob('opus1497e');
const elsewhereGodot = path.join(tmp, 'elsewhere_godot');
write(path.join(elsewhereGodot, '.godot', 'keep.bin'), 'not this job\'s');
fs.rmSync(path.join(sl2.repo, 'godot'), { recursive: true, force: true });
fs.symlinkSync(elsewhereGodot, path.join(sl2.repo, 'godot'), 'dir');
r = run('dropcache', sl2.j);
assert(fs.existsSync(path.join(elsewhereGodot, '.godot', 'keep.bin')) && /import cache kept: .*link or junction/.test(r.out), 'a link above the import cache is refused: ' + r.out);
r = run('survey');
assert.equal(r.status, 0, r.out);
assert(/attempt checkout [\d.]+ GB FAILED .*out_3/.test(r.out) && /ship clone [\d.]+ GB .*opus1497b/.test(r.out) && /nothing was removed/.test(r.out), 'the survey lists what is left: ' + r.out);
assert(fs.existsSync(path.join(failedBefore, 'new')) && fs.existsSync(sb.repo), 'the survey removes nothing');

const before = path.join(tmp, 'before.txt'), after = path.join(tmp, 'after.txt');
assert.equal(run('hashes', before).status, 0);
assert.match(fs.readFileSync(before, 'utf8'), /absent battle_opts\.json/);
write(path.join(realu, 'battle_opts.json'), '{}');
assert.equal(run('hashes', after).status, 0);
assert.match(fs.readFileSync(after, 'utf8'), /^[0-9a-f]{64} battle_opts\.json/m);
assert.notEqual(fs.readFileSync(before, 'utf8'), fs.readFileSync(after, 'utf8'), 'a change to the options shows in the hash');
fs.rmSync(tmp, { recursive: true, force: true });
console.log('PASS ps1 fixtures: current tools_live gate, one verified bundle, watchdog hashes, exact fresh checkouts, tracked check, ship cache stamps, own checkouts removed safely, options hash');
