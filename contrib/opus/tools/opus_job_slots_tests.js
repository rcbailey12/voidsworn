'use strict';
// Issue 1659 (Ryan, Nov 22 2026, Wave 2.1): helper PC jobs reset a warm slot to their pin instead of a fresh checkout per
// attempt. Static contract for the head and template; the slot, lease and reset steps of opus_job_head.ps1 run for real
// under pwsh (Linux CI): two gpu slots then a wait, a second checkout in the same slot with the first one's leftovers saved
// into its attempt, the warm import cache kept, release by the tail and by the job's process ending, and a slot set aside
// when its leftovers cannot be saved.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '../../..');
const jobs = path.join(root, 'tools/pc/jobs');
const read = p => fs.readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const head = read(path.join(jobs, 'opus_job_head.bat'));
const tpl = read(path.join(jobs, 'opus_job_template.bat'));

// ---------------------------------------------------------------- static contract
const co = head.slice(head.indexOf('\n:oj_checkout\n'), head.indexOf('\n:oj_ships\n'));
assert(/if "%OJ_SLOTS%"=="1" goto oj_checkout_slot\n/.test(co), 'checkout goes to the slot form with OJ_SLOTS=1');
assert(/:oj_checkout_slot\npowershell [^\n]*"%OJ_PS%" slot "%OJ_OUT%" "%~2" "%~3"[^\n]*\nif errorlevel 1 \(call "%JW%" fail/.test(co), 'a failed slot checkout fails the job');
assert(co.includes('set /p OJ_REPO=<"%OJ_OUT%\\slot_repo.txt"') && co.includes('set "OJ_SIDE=%OJ_OUT%\\%~2"'), 'slot jobs keep their side files in the attempt');
assert(co.includes('set "OJ_SIDE=%OJ_REPO%"'), 'fresh checkouts keep their side files where they were');
const ships = head.slice(head.indexOf('\n:oj_ships\n'), head.indexOf('\n:oj_tail\n'));
assert(!ships.includes('%OJ_REPO%_ships') && (ships.match(/%OJ_SIDE%_ships_/g) || []).length >= 6, 'every ships side file goes through OJ_SIDE');
const tail = head.slice(head.indexOf('\n:oj_tail\n'));
assert(/if "%OJ_SLOTS%"=="1" set "OJ_DROP="\ncall "%JW%" end\n/.test(tail), 'a slot job drops no checkout of its own');
assert(tail.indexOf('slotrelease "%OJ_OUT%"') > tail.indexOf('call "%JW%" end'), 'the slot is let go after the result is written');
assert(/\nset "OJ_SLOTS=0"\n/.test(tpl) && /\nset "OJ_SLOT_KIND=gpu"\n/.test(tpl), 'the template names the slot switch, off until the Windows proof (Artoo on PR 1728)');
console.log('PASS slots static: checkout goes through a slot with OJ_SLOTS=1, side files in the attempt, release after the result');

// ---------------------------------------------------------------- live fixtures (pwsh)
const windows = process.platform === 'win32';
const shell = windows ? 'powershell.exe' : 'pwsh';
if (windows || spawnSync(shell, ['-NoProfile', '-Command', 'exit 0']).error) {
  if (process.env.CI && !windows) throw new Error(`${shell} is required in CI`);
  console.log('SKIP slot fixtures: they need pwsh (Linux CI runs them)');
  process.exit(0);
}
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'opus-slots-'));
const vt = path.join(tmp, 'vt');
const source = path.join(tmp, 'source.git');
const env = { ...process.env, PC_TEST_HELPER: '1', PC_TEST_HELPER_VT: vt, PC_TEST_SOURCE: source, POWERSHELL_TELEMETRY_OPTOUT: '1', OJ_SLOT_WAIT_MINUTES: '0' };
const write = (file, text) => { fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, text); };
function git(args, cwd = tmp) {
  const r = spawnSync('git', args, { cwd, encoding: 'utf8' });
  assert.equal(r.status, 0, `git ${args.join(' ')}: ${r.stderr}`);
  return r.stdout.trim();
}
function run(extra, ...args) {
  const r = spawnSync(shell, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(jobs, 'opus_job_head.ps1'), ...args], { env: { ...env, ...extra }, encoding: 'utf8', timeout: 90000 });
  if (r.error) throw r.error;
  // CI's pwsh wraps error text into a boxed, coloured layout: join it back into one line for the message checks
  const flat = `${r.stdout}\n${r.stderr}`.replace(/\x1b\[[0-9;]*m/g, '').replace(/\s*\n\s*\|\s*/g, ' ').replace(/\s+/g, ' ');
  return { status: r.status, out: flat };
}
const waitFor = (test, ms) => { const end = Date.now() + ms; while (Date.now() < end) { if (test()) return true; spawnSync('sleep', ['0.2']); } return test(); };
const gone = pid => { try { process.kill(pid, 0); } catch { return true; } return !windows && /^State:\s+Z/m.test((() => { try { return fs.readFileSync(`/proc/${pid}/status`, 'utf8'); } catch { return 'State: Z'; } })()); };
const attempt = (job, n) => { const a = path.join(vt, job, `out_20261122_18000${n}_1`); fs.mkdirSync(a, { recursive: true }); return a; };
const slot = n => path.join(vt, 'slots', n);
// a stand-in job process: a background process of a shell that has ended (a killed one may stay unreaped; the head
// counts that as ended)
const sleeper = () => Number(spawnSync('sh', ['-c', 'sleep 120 >/dev/null 2>&1 & echo $!'], { encoding: 'utf8' }).stdout.trim());
const holders = n => fs.existsSync(slot(n)) ? fs.readdirSync(slot(n)).filter(f => /^holder_[0-9a-f]{32}\.txt$/.test(f)) : [];
try {
  const work = path.join(tmp, 'work');
  git(['init', '-q', '-b', 'main', work]);
  write(path.join(work, 'godot', 'project.godot'), 'one\n');
  write(path.join(work, 'godot', 'assets', 'ships', 'a4_props.gd'), 'extends Node\n');
  git(['add', '-A'], work);
  git(['-c', 'user.name=f', '-c', 'user.email=f@example.invalid', 'commit', '-q', '-m', 'one'], work);
  const one = git(['rev-parse', 'HEAD'], work);
  write(path.join(work, 'godot', 'project.godot'), 'two\n');
  git(['-c', 'user.name=f', '-c', 'user.email=f@example.invalid', 'commit', '-qam', 'two'], work);
  const two = git(['rev-parse', 'HEAD'], work);
  git(['clone', '-q', '--bare', work, source]);

  // two gpu jobs take the two gpu slots; a third waits (here: no wait) and is refused
  const a1 = attempt('opus1659a', 1), a2 = attempt('opus1659b', 2), a3 = attempt('opus1659c', 3);
  let r = run({}, 'slot', a1, 'new', one);
  assert.equal(r.status, 0, r.out);
  assert(/slot slot_gpu_1 taken/.test(r.out), r.out);
  const repo1 = path.join(slot('slot_gpu_1'), 'repo');
  assert.equal(fs.readFileSync(path.join(a1, 'slot_repo.txt'), 'utf8').trim(), repo1);
  assert.equal(git(['rev-parse', 'HEAD'], repo1), one);
  assert(!fs.existsSync(path.join(a1, 'checkouts.txt')), 'a slot is never listed for removal');
  assert.equal(holders('slot_gpu_1').length, 1, 'a holder keeps the lease');
  r = run({}, 'slot', a2, 'new', two);
  assert.equal(r.status, 0, r.out);
  assert(/slot slot_gpu_2 taken/.test(r.out), 'the second job takes the other gpu slot: ' + r.out);
  r = run({}, 'slot', a3, 'new', two);
  assert.notEqual(r.status, 0, 'no free gpu slot');
  assert(/no free gpu slot/.test(r.out), r.out);
  r = run({ OJ_SLOT_KIND: 'bogus' }, 'slot', a3, 'new', two);
  assert(r.status !== 0 && /gpu or cpu/.test(r.out), 'an unknown slot kind is refused: ' + r.out);

  // the job's own work in the slot (a tracked change and a new file) is saved into its attempt before the next reset;
  // the import cache and .import sidecars stay warm; an ignored build file goes
  write(path.join(repo1, 'godot', 'project.godot'), 'changed by the job\n');
  write(path.join(repo1, 'godot', 'probe_result.json'), '{"ok":true}\n');
  write(path.join(repo1, 'godot', '.godot', 'imported', 'x.ctex'), 'cache\n');
  write(path.join(repo1, 'godot', 'project.godot.import'), 'sidecar\n');
  r = run({}, 'slot', a1, 'old', two);
  assert.equal(r.status, 0, r.out);
  assert(/saved 1 changed and 1 new file/.test(r.out), 'leftovers saved: ' + r.out);
  const saved = path.join(a1, 'out_new', 'slot_leftovers');
  assert(fs.readFileSync(path.join(saved, 'changes.patch'), 'utf8').includes('changed by the job'));
  assert.equal(fs.readFileSync(path.join(saved, 'files', 'godot', 'probe_result.json'), 'utf8'), '{"ok":true}\n');
  assert.equal(git(['rev-parse', 'HEAD'], repo1), two, 'the same slot is reset to the second pin');
  assert.equal(git(['status', '--porcelain', '--untracked-files=no'], repo1), '', 'tracked files match the pin');
  assert(!fs.existsSync(path.join(repo1, 'godot', 'probe_result.json')), 'the job file is gone from the slot');
  assert(fs.existsSync(path.join(repo1, 'godot', '.godot', 'imported', 'x.ctex')) && fs.existsSync(path.join(repo1, 'godot', 'project.godot.import')), 'the import cache stays warm');
  assert.equal(fs.readFileSync(path.join(a1, 'slots.txt'), 'utf8').trim().split(/\r?\n/).length, 2, 'both checkouts recorded');

  // the tail lets the slot go; the waiting job then gets it
  r = run({}, 'slotrelease', a1);
  assert(r.status === 0 && /let go/.test(r.out), r.out);
  assert.equal(holders('slot_gpu_1').length, 0, 'no holder after release');
  r = run({}, 'slot', a3, 'new', one);
  assert(r.status === 0 && /slot slot_gpu_1 taken/.test(r.out), 'a freed slot is taken again: ' + r.out);
  assert(!fs.existsSync(path.join(a1, 'out_old', 'slot_leftovers')), 'a clean slot saves nothing');

  // the lease ends with the job's process, with no release from the tail
  // a background process of a shell that has ended, so init reaps it the moment it is killed (no zombie keeps its id)
  const sleeperPid = Number(spawnSync('sh', ['-c', 'sleep 60 >/dev/null 2>&1 & echo $!'], { encoding: 'utf8' }).stdout.trim());
  const a4 = attempt('opus1659d', 4);
  r = run({ PC_TEST_SLOT_OWNER_PID: String(sleeperPid), OJ_SLOT_KIND: 'cpu' }, 'slot', a4, 'new', one);
  assert(r.status === 0 && /slot slot_cpu taken/.test(r.out), r.out);
  assert.equal(holders('slot_cpu').length, 1);
  process.kill(sleeperPid, 'SIGKILL');
  assert(waitFor(() => holders('slot_cpu').length === 0, 15000), 'the holder lets go once the job process is gone');

  // leftovers that cannot be saved: the slot is set aside with hold.txt, the job fails, the next job skips the slot
  const repoCpu = path.join(slot('slot_cpu'), 'repo');
  write(path.join(repoCpu, 'godot', 'big_result.bin'), 'x'.repeat(4096));
  const a5 = attempt('opus1659e', 5);
  r = run({ OJ_SLOT_KIND: 'cpu', PC_TEST_LEFTOVER_CAP: '100' }, 'slot', a5, 'new', two);
  assert(r.status !== 0 && /slot held/.test(r.out), 'unsaveable leftovers stop the reset: ' + r.out);
  assert(fs.existsSync(path.join(slot('slot_cpu'), 'hold.txt')) && fs.existsSync(path.join(repoCpu, 'godot', 'big_result.bin')), 'the slot is kept as it is');
  run({}, 'slotrelease', a5);
  const a6 = attempt('opus1659f', 6);
  r = run({ OJ_SLOT_KIND: 'cpu' }, 'slot', a6, 'new', two);
  assert(r.status !== 0 && /no free cpu slot/.test(r.out), 'a held slot is skipped: ' + r.out);

  // a commit made in the slot (no mirror branch holds it) also sets the slot aside, before any reset
  fs.rmSync(path.join(slot('slot_gpu_2'), 'hold.txt'), { force: true });
  const repo2 = path.join(slot('slot_gpu_2'), 'repo');
  git(['-c', 'user.name=f', '-c', 'user.email=f@example.invalid', 'commit', '-q', '--allow-empty', '-m', 'job commit'], repo2);
  const jobCommit = git(['rev-parse', 'HEAD'], repo2);
  run({}, 'slotrelease', a2);
  const a7 = attempt('opus1659g', 7);
  r = run({}, 'slot', a7, 'new', one);
  assert(r.status !== 0 && /slot held: the last job left HEAD at [0-9a-f]{40}/.test(r.out), 'a slot commit holds the slot: ' + r.out);
  assert.equal(git(['rev-parse', 'HEAD'], repo2), jobCommit, 'the commit is still checked out');
  run({}, 'slotrelease', a7);

  // a claimant whose new slot turns out to need the Board's look lets it go and takes the next free one (Artoo on PR 1728)
  run({}, 'slotrelease', a3);
  fs.rmSync(path.join(slot('slot_gpu_2'), 'hold.txt'));
  git(['checkout', '-q', '--detach', one], repo2);
  write(path.join(repo1, 'godot', 'big_result.bin'), 'x'.repeat(4096));
  const aM = attempt('opus1659m', 8), jobM = sleeper();
  r = run({ PC_TEST_LEFTOVER_CAP: '100', PC_TEST_SLOT_OWNER_PID: String(jobM) }, 'slot', aM, 'new', two);
  assert(r.status === 0 && /slot held: the last job's leftovers/.test(r.out) && /slot slot_gpu_2 taken/.test(r.out), 'moves on to the next free slot: ' + r.out);
  assert(fs.existsSync(path.join(slot('slot_gpu_1'), 'hold.txt')) && fs.existsSync(path.join(repo1, 'godot', 'big_result.bin')), 'the held slot is kept as it is');
  assert.equal(git(['rev-parse', 'HEAD'], repo2), two);

  // a holder stopped abruptly leaves its marker; a new job takes the slot, and the old attempt's next checkout must not
  // touch it (Artoo on PR 1728: prove the holder, the owner token and the lease, fail closed on a stale mark)
  const tokM = fs.readFileSync(path.join(aM, 'slot.txt'), 'utf8').trim().split('|')[1];
  const markM = path.join(slot('slot_gpu_2'), `holder_${tokM}.txt`);
  const holderPid = Number(fs.readFileSync(markM, 'utf8').trim().split(' ')[1]);
  process.kill(holderPid, 'SIGKILL'); process.kill(jobM, 'SIGKILL');
  assert(fs.existsSync(markM), 'the stopped holder left its marker');
  const aN = attempt('opus1659n', 9);
  assert(waitFor(() => run({}, 'slot', aN, 'new', one).status === 0, 15000), 'a new job takes the freed slot');
  assert.equal(git(['rev-parse', 'HEAD'], repo2), one);
  r = run({}, 'slot', aM, 'old', two);
  assert(r.status !== 0 && /no longer held for this attempt/.test(r.out), 'the old attempt is refused: ' + r.out);
  assert.equal(git(['rev-parse', 'HEAD'], repo2), one, "the new job's slot is untouched");
  assert(!fs.existsSync(markM), 'the new holder cleared the stale marker');
  run({}, 'slotrelease', aN);

  // a holder that dies while its job is mid-reset (Artoo on PR 1728): a claimant that gets the lease waits on the slot's
  // reset lock, the dying job's reset fails at its last check, and the claimant's reset runs after it
  const aP = attempt('opus1659p', 10), aQ = attempt('opus1659q', 11), jobP = sleeper();
  r = run({ PC_TEST_SLOT_OWNER_PID: String(jobP) }, 'slot', aP, 'new', one);
  assert(r.status === 0 && /slot slot_gpu_2 taken/.test(r.out), r.out);
  const rcP = path.join(tmp, 'p_rc.txt'), outP = path.join(tmp, 'p_out.txt');
  const quote = s => `'${s.replace(/'/g, `'\\''`)}'`;
  spawnSync('sh', ['-c', `( PC_TEST_SLOT_RESET_DELAY=6 ${shell} -NoProfile -File ${quote(path.join(jobs, 'opus_job_head.ps1'))} slot ${quote(aP)} old ${two} > ${quote(outP)} 2>&1; echo $? > ${quote(rcP)} ) < /dev/null > /dev/null 2>&1 &`], { env, stdio: 'ignore' });
  const tokP = fs.readFileSync(path.join(aP, 'slot.txt'), 'utf8').trim().split('|')[1];
  assert(waitFor(() => fs.existsSync(path.join(slot('slot_gpu_2'), 'test_reset_in_flight')), 20000), 'the reset is in flight, holding its lock');
  process.kill(Number(fs.readFileSync(path.join(slot('slot_gpu_2'), `holder_${tokP}.txt`), 'utf8').trim().split(' ')[1]), 'SIGKILL');
  process.kill(jobP, 'SIGKILL');   // the whole job went down mid-reset
  assert(waitFor(() => gone(jobP), 10000), 'the dead job has ended');
  const startQ = Date.now();
  r = run({}, 'slot', aQ, 'new', one);
  assert(waitFor(() => fs.existsSync(rcP), 20000), 'the first reset ends');
  const outPText = fs.readFileSync(outP, 'utf8').replace(/\s+/g, ' ');
  assert(fs.readFileSync(rcP, 'utf8').trim() !== '0' && /was lost during the reset/.test(outPText), 'the dying job fails at its last check: ' + outPText + ' | claimant: ' + r.out + ' | waited ms ' + (Date.now() - startQ));
  assert(r.status === 0 && /slot slot_gpu_2 taken/.test(r.out) && Date.now() - startQ >= 3000, 'the claimant waited for the reset lock: ' + r.out);
  assert.equal(git(['rev-parse', 'HEAD'], repo2), one, "the claimant's pin, applied after the dying reset");
  run({}, 'slotrelease', aQ);

  // Artoo on PR 1728: the holder dies after the checkout returned while the job still runs (copying ships, Godot); no
  // claimant may take the slot until the job's own process has ended
  const aR = attempt('opus1659r', 12), aS = attempt('opus1659s', 13), jobR = sleeper();
  r = run({ PC_TEST_SLOT_OWNER_PID: String(jobR) }, 'slot', aR, 'new', two);
  assert(r.status === 0 && /slot slot_gpu_2 taken/.test(r.out), r.out);
  const tokR = fs.readFileSync(path.join(aR, 'slot.txt'), 'utf8').trim().split('|')[1];
  process.kill(Number(fs.readFileSync(path.join(slot('slot_gpu_2'), `holder_${tokR}.txt`), 'utf8').trim().split(' ')[1]), 'SIGKILL');
  spawnSync('sleep', ['1']);
  r = run({}, 'slot', aS, 'new', one);
  assert(r.status !== 0 && /no free gpu slot/.test(r.out), 'the job still runs, so its slot is not free: ' + r.out);
  assert.equal(git(['rev-parse', 'HEAD'], repo2), two, "the running job's checkout is untouched");
  process.kill(jobR, 'SIGKILL');
  assert(waitFor(() => gone(jobR), 10000), 'the dead job has ended');
  assert(waitFor(() => run({}, 'slot', aS, 'new', one).status === 0, 15000), 'once the job has ended the slot is taken');
  assert.equal(git(['rev-parse', 'HEAD'], repo2), one);
  run({}, 'slotrelease', aS);

  // Artoo on PR 1728: on the PC the recorded parent is the long-lived watcher shell, not the job. The holder dies, the
  // job's tail runs while that parent lives on, and the next claimant gets the slot without the parent exiting
  const aT = attempt('opus1659t', 14), aU = attempt('opus1659u', 15), watcher = sleeper();
  r = run({ PC_TEST_SLOT_OWNER_PID: String(watcher) }, 'slot', aT, 'new', two);
  assert(r.status === 0 && /slot slot_gpu_2 taken/.test(r.out), r.out);
  const tokT = fs.readFileSync(path.join(aT, 'slot.txt'), 'utf8').trim().split('|')[1];
  process.kill(Number(fs.readFileSync(path.join(slot('slot_gpu_2'), `holder_${tokT}.txt`), 'utf8').trim().split(' ')[1]), 'SIGKILL');
  r = run({}, 'slot', aU, 'new', one);
  assert(r.status !== 0 && /no free gpu slot/.test(r.out), 'before the tail the slot is still the job\'s: ' + r.out);
  r = run({}, 'slotrelease', aT);
  assert(r.status === 0, r.out);
  assert(/^released /m.test(fs.readFileSync(path.join(slot('slot_gpu_2'), 'owner.txt'), 'utf8')), 'the tail marked its token released');
  r = run({}, 'slot', aU, 'new', one);
  assert(r.status === 0 && /slot slot_gpu_2 taken/.test(r.out) && !gone(watcher), 'the claimant takes the slot while the parent lives on: ' + r.out);
  const ownerU = fs.readFileSync(path.join(slot('slot_gpu_2'), 'owner.txt'), 'utf8');
  r = run({}, 'slotrelease', aT);
  assert.equal(fs.readFileSync(path.join(slot('slot_gpu_2'), 'owner.txt'), 'utf8'), ownerU, "a late tail leaves the next job's owner.txt alone");
  run({}, 'slotrelease', aU);
  process.kill(watcher, 'SIGKILL');

  // a slot whose folder is a link is refused before anything is reset
  if (!windows) {
    fs.rmSync(slot('slot_cpu'), { recursive: true, force: true });
    fs.mkdirSync(path.join(tmp, 'elsewhere'));
    fs.symlinkSync(path.join(tmp, 'elsewhere'), slot('slot_cpu'));
    r = run({ OJ_SLOT_KIND: 'cpu' }, 'slot', a6, 'new', two);
    assert(r.status !== 0 && /not a plain folder/.test(r.out), 'a linked slot is refused: ' + r.out);
  }
  console.log('PASS slots live: two gpu slots then none, leftovers saved before a reset, warm import cache, release by tail and by process end, held and linked slots refused');
} finally {
  spawnSync('sleep', ['1']);
  fs.rmSync(tmp, { recursive: true, force: true });
}
