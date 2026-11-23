'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const crypto = require('node:crypto');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const windows = process.platform === 'win32';
const common = path.resolve(__dirname, '../../../tools/pc/runner_common.ps1');
const janitor = path.join(path.dirname(common), 'janitor.ps1');
const ownerFile = '.voidsworn-run-owner';
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'runner-cleanup-proof-'));
// PR 1813 measured a 2.1x slowdown with overlapping PC lanes. Allow 65 s instead of 30 s per child.
const childTimeout = 65000;
// The first full dry scan still had folders left after 65 s with lanes A, B and D checking.
// Allow 140 s for a Windows janitor scan (65 s x 2.1, rounded up).
const janitorTimeout = windows ? 140000 : childTimeout;
const temp = path.join(root, 'temp'), board = path.join(root, 'board');
const mirror = path.join(root, 'mirror.git'), repo = path.join(board, 'repo');
const profile = path.join(root, 'profile'), flag = path.join(profile, 'Downloads', 'voidsworn_test', 'gpu_go.txt');
const env = { ...process.env, USERPROFILE: profile, PC_RUNNER_TEST: '1', PC_RUN_TEMP: temp, PC_TEST_MIRROR: mirror, PC_TEST_GIT: '' };
const fixtureNow = new Date();
function write(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, value);
}
function read(file) { return fs.readFileSync(file, 'utf8'); }
function execute(exe, args, input, extra = {}, timeout = childTimeout) {
  const merged = { ...env, ...extra };
  for (const key of Object.keys(merged)) if (merged[key] === null) delete merged[key];
  // Janitor can start another PowerShell. Its working directory must survive fixture cleanup if its parent times out.
  const r = spawnSync(exe, args, {
    input, cwd: path.dirname(root), env: merged, encoding: 'utf8', windowsHide: true, timeout
  });
  assert.equal(r.status, 0, `${exe} ${args.join(' ')}: ${r.error || ''}\n${r.stderr}\n${r.stdout}`);
  return r.stdout.trim();
}
const git = (args, input) => execute('git', args, input);
function shared(args, scratch = '', issue = '') {
  const scratchEnv = scratch ? { TEMP: scratch, TMP: scratch, TMPDIR: scratch } : {};
  execute(windows ? 'powershell.exe' : 'pwsh', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', common, ...args], undefined,
    { ...scratchEnv, PC_RUN_SCRATCH: scratch, PC_RUNNER_LOCKED_ISSUE: issue });
}
function start(name, issue = '') {
  const out = path.join(root, name);
  fs.mkdirSync(out);
  shared(['init', out, 'fixture/cleanup']);
  shared(['scratch', out], '', issue);
  const scratch = read(path.join(out, 'scratch_path.txt')).trim();
  assert.equal(path.dirname(scratch), temp);
  const record = JSON.parse(read(path.join(out, 'status.json'))).scratch;
  assert.equal(record.path, scratch);
  assert.match(record.token, /^[0-9a-f]{32}$/);
  assert.equal(read(path.join(scratch, ownerFile)), record.token);
  write(path.join(scratch, 'nested', 'proof.txt'), name);
  return { out, scratch, issue };
}
function finish(run, { code = '0', partial = '', push = 'real', checks = '1', confirmed = true, selected = run.scratch, checkout = '' } = {}) {
  write(path.join(run.out, 'run_commit.txt'), 'a'.repeat(40));
  if (confirmed) write(path.join(run.out, 'confirmed_commit.txt'), 'a'.repeat(40));
  shared(['finish', run.out, code, partial, push, checks, checkout], selected, run.issue);
  return read(path.join(run.out, 'result.txt'));
}
const keep = run => assert(fs.existsSync(path.join(run.scratch, 'nested', 'proof.txt')), run.out);
function makeCopy(name, age, lane = board) {
  const dir = path.join(lane, name);
  // Dating fixture metadata must never change a hardlinked object in another checkout.
  git(['clone', '-q', '--no-hardlinks', '-c', 'core.autocrlf=false', mirror, dir]);
  const date = new Date(Date.UTC(2026, 0, age));
  fs.utimesSync(dir, date, date);
  return dir;
}
function dated(file, hours) {
  const time = new Date(fixtureNow.getTime() - hours * 3600000);
  fs.utimesSync(file, time, time);
}
function dateTree(dir, hours) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const file = path.join(dir, entry.name);
    if (entry.isSymbolicLink()) continue;
    if (entry.isDirectory()) dateTree(file, hours);
    else dated(file, hours);
  }
  dated(dir, hours);
}
function scratch(parent, name, hours) {
  const dir = path.join(parent, name);
  const file = path.join(dir, 'nested', 'proof.txt');
  write(file, name);
  dateTree(dir, hours);
  return dir;
}
try {
  fs.mkdirSync(temp);
  const other = path.join(temp, 'voidsworn-run-other');
  write(path.join(other, 'proof.txt'), 'unrelated scratch');
  const real = start('checked');
  const insufficient = [
    ['dry', { push: 'dry' }], ['test-push', { push: 'test' }],
    ['partial', { partial: 'agent interrupted' }], ['failed-checks', { checks: '0' }],
    ['unconfirmed', { confirmed: false }], ['mismatched-path', { selected: other }]
  ];
  for (const [name, options] of insufficient) {
    const run = start(name);
    finish(run, options);
    keep(run);
  }
  const swapped = start('swapped');
  const original = path.join(temp, 'original-scratch');
  fs.renameSync(swapped.scratch, original);
  write(path.join(swapped.scratch, 'nested', 'proof.txt'), 'replacement folder');
  assert.match(finish(swapped), /run scratch kept: .*ownership token file is missing/);
  assert.equal(read(path.join(swapped.scratch, 'nested', 'proof.txt')), 'replacement folder');
  assert.equal(read(path.join(original, 'nested', 'proof.txt')), 'swapped');
  const changed = start('changed-token');
  fs.copyFileSync(path.join(original, ownerFile), path.join(changed.scratch, ownerFile));
  assert.match(finish(changed), /run scratch kept: .*ownership token file changed/);
  keep(changed);
  fs.mkdirSync(board);
  git(['init', '--bare', '-q', mirror]);
  const blob = git(['--git-dir', mirror, 'hash-object', '-w', '--stdin'], 'shared file\n');
  const tree = git(['--git-dir', mirror, 'mktree'], `100644 blob ${blob}\ttracked.txt\n`);
  const author = 'author Fixture <fixture@example.invalid> 1700000000 +0000\ncommitter Fixture <fixture@example.invalid> 1700000000 +0000';
  const commit = (dir, message, parent = '') => git(['--git-dir', dir, 'hash-object', '-t', 'commit', '-w', '--stdin'],
    `tree ${tree}\n${parent ? `parent ${parent}\n` : ''}${author}\n\n${message}\n`);
  const main = commit(mirror, 'shared history');
  git(['--git-dir', mirror, 'update-ref', 'refs/heads/main', main]);
  git(['--git-dir', mirror, 'symbolic-ref', 'HEAD', 'refs/heads/main']);
  makeCopy('repo', 1);
  const rebuildable = makeCopy('repo-kept-caches', 1);
  write(path.join(rebuildable, '.git', 'info', 'exclude'), '/godot/.godot/\n');
  write(path.join(rebuildable, 'godot', '.godot', 'test.cache'), 'rebuildable');
  const clean = makeCopy('repo-kept-clean', 2);
  const dirty = makeCopy('repo-kept-untracked', 3);
  write(path.join(dirty, 'work.txt'), 'local work');
  const staged = makeCopy('repo-kept-staged', 4);
  write(path.join(staged, 'staged.txt'), 'staged work');
  git(['-C', staged, 'add', 'staged.txt']);
  const history = makeCopy('repo-kept-history', 4);
  const local = commit(path.join(history, '.git'), 'local work in a commit', main);
  git(['-C', history, 'update-ref', 'refs/heads/main', local]);
  const invalid = path.join(board, 'repo-kept-invalid');
  write(path.join(invalid, 'proof.txt'), 'same name, no Git checkout');
  fs.utimesSync(invalid, new Date(2020, 0, 1), new Date(2020, 0, 1));
  const linked = makeCopy('repo-kept-linked', 5);
  fs.symlinkSync(other, path.join(linked, 'external'), windows ? 'junction' : 'dir');
  const newest = makeCopy('repo-kept-newest', 28);
  // The Board keep list also binds the runner's end-of-job cleanup, not only the janitor (Artoo on PR 1277).
  const listedClean = makeCopy('repo-kept-listed', 2);
  write(path.join(path.dirname(flag), 'janitor_keep.txt'), `# held by the Board\n${listedClean}\n`);
  const noncandidate = makeCopy('repo-clone-failed-older', 1);
  // Files created at the top of a kept checkout also change its directory timestamp.
  fs.utimesSync(newest, new Date(2030, 0, 1), new Date(2030, 0, 1));
  const boardPaused = start('board-paused');
  write(flag, 'GPU not cleared: paused by the Board at 12:30');
  assert.match(finish(boardPaused, { checkout: repo }), /cleanup skipped during the PC pause/);
  assert(fs.existsSync(rebuildable) && fs.existsSync(clean));
  keep(boardPaused);
  write(flag, 'GPU cleared');
  const log = finish(real, { checkout: repo });
  assert.match(log, /run scratch removed/);
  assert(!fs.existsSync(real.scratch));
  assert(!fs.existsSync(rebuildable) && !fs.existsSync(clean), log);
  assert.match(log, /kept checkout removed \(rebuildable\): .*repo-kept-caches/);
  assert.match(log, /kept checkout removed \(rebuildable\): .*repo-kept-clean/);
  assert.match(log, /kept checkout retained \(newest\): .*repo-kept-newest/);
  assert.match(log, /repo-kept-history.*local history not in fetched mirror/);
  assert.match(log, /repo-kept-untracked.*working tree needs keeping/);
  assert.match(log, /repo-kept-staged.*working tree needs keeping/);
  assert.match(log, /repo-kept-invalid.*not a standalone checkout/);
  assert.match(log, /repo-kept-linked.*linked path/);
  assert.match(log, /repo-kept-listed.*kept: on the Board keep list/);
  assert.equal(git(['-C', history, 'rev-parse', 'HEAD']), local);
  assert.equal(read(path.join(dirty, 'work.txt')), 'local work');
  assert.equal(read(path.join(staged, 'staged.txt')), 'staged work');
  assert.equal(read(path.join(invalid, 'proof.txt')), 'same name, no Git checkout');
  assert.equal(read(path.join(other, 'proof.txt')), 'unrelated scratch');
  for (const dir of [repo, newest, noncandidate, linked, listedClean]) assert(fs.existsSync(dir), dir);
  const firstFail = start('first-fail', '201');
  assert.match(finish(firstFail, { code: '6' }), /kept for a retry for one day/);
  keep(firstFail);
  const timeout = start('timed-out', '201');
  assert.match(finish(timeout, { code: '124', partial: 'CEILING' }), /older failed run scratch removed/);
  assert(!fs.existsSync(firstFail.scratch));
  keep(timeout);
  const unchanged = start('unchanged', '201');
  assert.match(finish(unchanged, { code: '7' }), /run scratch removed/);
  assert(!fs.existsSync(unchanged.scratch));
  keep(timeout);
  const pausedFailure = start('paused-failure', '201');
  write(flag, 'GPU not cleared: paused by the Board at 12:30');
  assert.match(finish(pausedFailure, { partial: 'agent interrupted' }), /cleanup skipped during the PC pause/);
  keep(pausedFailure);
  keep(timeout);
  write(flag, 'GPU cleared');
  console.log('PASS runner cleanup: scratch ownership, failed-run retention, pause, and rebuildable kept checkouts');

  const pc = path.dirname(flag);
  const laneB = path.join(pc, 'board_b');
  fs.mkdirSync(laneB);
  const caches = makeCopy('repo-kept-r336', 1, laneB);
  const generatedShip = 'godot/gen/ships/cache 1.scn';
  const ignored = ['godot/campaign/test/out/c1.jsonl', 'godot/audio/build/test.gd.uid',
    'godot/scenes/campaign/test.gd.uid', '.onboarding_checks/build.txt', generatedShip,
    'godot/assets/ships/manifest.bak_1/manifest.json', 'godot/.stage7-replaced-1/previous/test.glb'];
  const rules = ['godot/campaign/test/out/', 'godot/**/*.uid', '.onboarding_checks/', 'godot/gen/', 'godot/assets/ships/*/'];
  write(path.join(caches, '.git', 'info', 'exclude'), rules.join('\n') + '\n');
  for (const file of ignored) write(path.join(caches, file), 'generated cache');
  write(path.join(pc, 'build', generatedShip), 'generated cache');
  // parity_campaign.bat sends each seed to golden_campaign.js and writes the log itself.
  // Test the two outputs separately, using the actual checkout's ignore rules as evidence.
  const checkout = path.resolve(__dirname, '../../..');
  const campaignOutput = (name, file, ignore) => {
    assert.equal(git(['-C', checkout, 'check-ignore', '--', file]), file);
    const dir = makeCopy(`repo-kept-${name}`, 2, laneB);
    write(path.join(dir, '.git', 'info', 'exclude'), `${ignore}\n`);
    write(path.join(dir, file), 'campaign parity fixture');
    dateTree(dir, 8);
    return dir;
  };
  const golden = campaignOutput('campaign-golden', 'godot/campaign/test/golden/c1.jsonl', '/godot/campaign/test/golden/');
  const parityLog = campaignOutput('campaign-log', 'godot/campaign/test/parity_campaign_log.txt', '/godot/campaign/test/parity_campaign_log.txt');
  const goldenNotes = campaignOutput('campaign-notes', 'godot/campaign/test/golden/notes.md', '/godot/campaign/test/golden/');
  const localWork = ['CODEX_TASK.md', 'contrib/notes.txt', 'rebuild.bat', 'notes.md', 'shot.png'].map((file, i) => {
    const dir = makeCopy(`repo-kept-untracked-work-${i}`, 2, laneB);
    write(path.join(dir, file), 'work to keep');
    dateTree(dir, 8);
    return dir;
  });
  const wrongGen = makeCopy('repo-kept-wrong-gen', 2, laneB);
  write(path.join(wrongGen, '.git', 'info', 'exclude'), 'godot/gen/\n');
  write(path.join(wrongGen, 'godot/gen/proof.uid'), 'local');
  write(path.join(pc, 'build/godot/gen/proof.uid'), 'other');
  // Issue 1180 run 7: the copy's differing gen file is newer than the build's, so it is not superseded and is kept.
  // The never-touch fixtures later re-date pc/build, so the build times are applied just before the first scan.
  const buildTimes = [[path.join(pc, 'build/godot/gen/proof.uid'), 40]];
  // A differing ship or gen file counts as rebuildable for removal only when the shared build holds the same file written
  // strictly later (superseded). Newer copies, files missing from the build and untrusted times keep the copy.
  function shipCopy(name, file, copyHours, buildHours, ignore = 'godot/assets/ships/*/', bytes = `${name} copy bake`) {
    const dir = makeCopy(`repo-kept-${name}`, 2, laneB);
    write(path.join(dir, '.git', 'info', 'exclude'), `${ignore}\n`);
    write(path.join(dir, file), bytes);
    dateTree(dir, 26);
    if (copyHours !== null) dated(path.join(dir, file), copyHours);
    if (buildHours !== null) {
      write(path.join(pc, 'build', file), `${name} installed bake, longer`);
      buildTimes.push([path.join(pc, 'build', file), buildHours]);
    }
    return dir;
  }
  const shipSuperseded = shipCopy('ship-superseded', 'godot/assets/ships/T1_11/T1_11.glb', 26, 10);
  // The same superseded bytes in a second lane copy are stored once (Board, Nov 20).
  const shipSupersededTwin = shipCopy('ship-superseded-twin', 'godot/assets/ships/T1_11/T1_11.glb', 26, 10, undefined, 'ship-superseded copy bake');
  const genSuperseded = shipCopy('gen-superseded', 'godot/gen/manifest.json', 26, 10, 'godot/gen/');
  const shipNewer = shipCopy('ship-newer', 'godot/assets/ships/T2_11/T2_11.glb', 26, 40);
  // Run 8: a worktree whose folder is gone is prunable and shares nothing; a live one keeps the checkout.
  const worktreeCopy = (name, keepLive) => {
    const dir = makeCopy(`repo-kept-${name}`, 2, laneB);
    const extra = path.join(root, `${name}-extra`);
    git(['-C', dir, 'worktree', 'add', '-q', '--detach', extra]);
    if (!keepLive) fs.rmSync(extra, { recursive: true, force: true });
    dateTree(dir, 26);
    return dir;
  };
  const worktreeStale = worktreeCopy('worktree-stale', false);
  const worktreeLive = worktreeCopy('worktree-live', true);
  // Run 8: a damage glb with no build twin, while the build holds the same ship code installed later.
  const shipNoTwin = shipCopy('ship-no-twin', 'godot/assets/ships/T5_11/T5_11_damage.glb', 26, null);
  write(path.join(pc, 'build', 'godot/assets/ships/T5_11/T5_11.glb'), 'T5_11 reinstalled');
  buildTimes.push([path.join(pc, 'build', 'godot/assets/ships/T5_11/T5_11.glb'), 10]);
  // A gen file with no build twin, while the build's gen was regenerated later (gen/manifest.json newer): R8 dry run 2.
  const genNoTwin = shipCopy('gen-no-twin', 'godot/gen/damage/D9_11_damage.scn', 26, null, 'godot/gen/');
  const shipMissing = shipCopy('ship-missing', 'godot/assets/ships/T3_11/T3_11.glb', 26, null);
  const shipOldTime = shipCopy('ship-old-time', 'godot/assets/ships/T4_11/T4_11.glb', null, 10);
  fs.utimesSync(path.join(shipOldTime, 'godot/assets/ships/T4_11/T4_11.glb'), new Date(Date.UTC(1990, 0, 1)), new Date(Date.UTC(1990, 0, 1)));
  const edited = makeCopy('repo-kept-hand-edit', 2, laneB);
  write(path.join(edited, 'tracked.txt'), 'hand edit');
  const localHistory = makeCopy('repo-kept-local-history', 2, laneB);
  const unpushed = commit(path.join(localHistory, '.git'), 'local history for janitor', main);
  git(['-C', localHistory, 'update-ref', 'refs/heads/main', unpushed]);
  git(['-C', localHistory, 'update-ref', 'refs/heads/main', main]);
  const trashUntracked = makeCopy('repo-kept-untracked', 2, laneB);
  write(path.join(trashUntracked, 'notes.txt'), 'hand notes');
  const trashStaged = makeCopy('repo-kept-staged', 2, laneB);
  write(path.join(trashStaged, 'notes.txt'), Buffer.from([0, 1, 2]));
  git(['-C', trashStaged, 'add', 'notes.txt']);
  write(path.join(trashStaged, 'notes.txt'), Buffer.from([0, 1, 3]));
  const invalidRepo = path.join(laneB, 'repo-kept-unreadable');
  write(path.join(invalidRepo, 'proof.txt'), 'unreadable checkout');
  const failedSalvage = makeCopy('repo-kept-failed-salvage', 2, laneB);
  makeCopy('nested', 2, failedSalvage);
  for (const dir of [caches, localHistory, trashUntracked, trashStaged, wrongGen, invalidRepo, failedSalvage]) dateTree(dir, 26);
  // Recent Git bookkeeping must affect neither the three-hour nor the one-day cutoff.
  const oldCopies = [caches, localHistory];
  for (const dir of oldCopies) {
    dated(path.join(dir, '.git', 'index'), 1);
    dated(path.join(dir, '.git', 'logs', 'HEAD'), 1);
    const fetchHead = path.join(dir, '.git', 'FETCH_HEAD');
    write(fetchHead, `${main}\t\tfixture main\n`);
    dated(fetchHead, 1);
  }
  dateTree(edited, 8);
  const laneNewest = makeCopy('repo-kept-newest', 30, laneB);
  fs.utimesSync(laneNewest, new Date(2030, 0, 1), new Date(2030, 0, 1));

  const ownerName = (issue, char) => `voidsworn-run-${issue}-${char.repeat(32)}`;
  const oldOwned = scratch(temp, ownerName(301, 'a'), 4);
  const activeOwned = scratch(temp, ownerName(302, 'b'), 4);
  const oldRetry = scratch(temp, ownerName(303, 'c'), 26);
  const freshRetry = scratch(temp, ownerName(304, 'd'), 4);
  function markOwned(dir, hours, token = 'f'.repeat(32)) {
    write(path.join(dir, ownerFile), token);
    dated(path.join(dir, ownerFile), hours);
    dated(dir, hours);
  }
  const tokenOnly = scratch(temp, 'owned-tool-output', 4);
  // The Board keep list (issue 1180, Nov 20): an owned scratch that would otherwise go stays when listed by exact path.
  const boardKept = scratch(temp, ownerName(309, 'a'), 26);
  markOwned(boardKept, 26);
  write(path.join(pc, 'janitor_keep.txt'), `\uFEFF# held on purpose by the Board\r\n${boardKept}\r\n${path.join(pc, 'opus1396kept')}\r\n\r\n`);
  for (const dir of [oldOwned, activeOwned, oldRetry, freshRetry, tokenOnly]) markOwned(dir, 26);
  for (const [dir, hours] of [[oldRetry, 25], [freshRetry, 4]]) {
    const marker = path.join(dir, '.voidsworn-run-failed');
    write(marker, '');
    dated(marker, hours);
    dated(dir, 26);
  }
  const lookalikes = ['issue-notes', 'voidsworn-parity-x', 'stage7-checked-x', 'tune2-old',
    'voidsworn-parity-issue-302-copy'].map(name => scratch(temp, name, 4));
  function recordScratch(issue, dir, extra = {}) {
    write(path.join(laneB, `issue-${issue}`, 'status.json'), JSON.stringify({
      status: 'failed', scratch: { path: dir, ...extra }
    }));
  }
  // The runner records the token and the folder's creation time in .NET ticks (runner_common.ps1 'scratch').
  const createdTicks = dir => String(fs.statSync(dir, { bigint: true }).birthtimeNs / 100n + 621355968000000000n);
  function recordOwned(issue, dir, token, extra = {}) {
    markOwned(dir, 4, token);
    recordScratch(issue, dir, { token, created: createdTicks(dir), ...extra });
  }
  const recordedFull = scratch(temp, 'voidsworn-parity-recorded', 4);
  recordOwned(305, recordedFull, 'a'.repeat(32));
  const recordedActive = scratch(temp, 'recorded-active-output', 4);
  recordOwned(302, recordedActive, 'b'.repeat(32));
  // Path-only record (Artoo, PR 1252): no token or creation time, so it proves nothing.
  const pathOnly = scratch(temp, 'recorded-path-only', 4);
  recordScratch(312, pathOnly);
  // A finished record that outlived its folder: a new folder at the same path has no token, or a different birth.
  const survivorBare = scratch(temp, 'recorded-survivor-bare', 4);
  recordScratch(313, survivorBare, { token: 'c'.repeat(32), created: '638000000000000000' });
  const survivorCopied = scratch(temp, 'recorded-survivor-copied', 4);
  markOwned(survivorCopied, 4, 'd'.repeat(32));
  recordScratch(314, survivorCopied, { token: 'd'.repeat(32), created: String(BigInt(createdTicks(survivorCopied)) - 36000000000n) });
  const replaced = scratch(temp, 'stage7-checked-replaced', 4);
  markOwned(replaced, 4);
  recordScratch(311, replaced, { token: 'e'.repeat(32), created: createdTicks(replaced) });
  const recent = scratch(temp, 'issue-306-recent', 2);
  markOwned(recent, 2);
  // Issue 1180 run 8: a helper folder goes after a day only when every out file is a blob committed on a board/pc-out
  // relay branch (a loose blob is not a receipt, Artoo on PR 1266) and everything else is a rebuildable checkout.
  let relays = 0;
  const relay = (...files) => {
    const entries = files.map((file, i) =>
      `100644 blob ${git(['--git-dir', mirror, 'hash-object', '-w', '--no-filters', file])}\tf${i}`).join('\n') + '\n';
    const tree = git(['--git-dir', mirror, 'mktree'], entries);
    const receipt = git(['--git-dir', mirror, 'hash-object', '-t', 'commit', '-w', '--stdin'],
      `tree ${tree}\nauthor relay <relay@example.invalid> 0 +0000\ncommitter relay <relay@example.invalid> 0 +0000\n\nrelay\n`);
    git(['--git-dir', mirror, 'update-ref', `refs/heads/board/pc-out-fixture${relays++}`, receipt]);
  };
  const opus = scratch(pc, 'opus901out1', 73);
  relay(path.join(opus, 'nested', 'proof.txt'));
  dateTree(opus, 73);
  const recentOpus = scratch(pc, 'opus902', 71);
  const helperFolder = (name, files) => {
    const dir = path.join(pc, name);
    for (const [file, text] of Object.entries(files)) write(path.join(dir, file), text);
    return dir;
  };
  // helper_clone's own top-level files (lease, attempt, commit, copy record) never keep a folder (PR 1275).
  const helperRelayed = helperFolder('opus905', { 'out/result.txt': 'opus905 result relayed', '.voidsworn-run-active': '',
    'attempt.txt': `${'9'.repeat(32)}\n`, 'repo_commit.txt': `${'a'.repeat(40)}\n`, 'ships_copied.txt': '' });
  relay(path.join(helperRelayed, 'out', 'result.txt'));
  makeCopy('repo', 2, helperRelayed);
  dateTree(helperRelayed, 30);
  const helperUnrelayed = helperFolder('opus903', { 'out/result.txt': 'opus903 result relayed', 'out/shot.png': 'opus903 picture too big to relay' });
  relay(path.join(helperUnrelayed, 'out', 'result.txt'));
  // DRY3 on the PC spent about 250 s per opus1434 folder hashing 2 GB videos: a file over GitHub's 100 MB limit is never
  // on a relay branch, so it counts as not relayed without being read (a sparse file here).
  const helperHuge = path.join(helperUnrelayed, 'out', 'capture.avi');
  fs.writeFileSync(helperHuge, ''); fs.truncateSync(helperHuge, 101 * 1024 * 1024);
  dateTree(helperUnrelayed, 30);
  const helperLoose = helperFolder('opus906', { 'out/result.txt': 'opus906 loose blob only' });
  git(['--git-dir', mirror, 'hash-object', '-w', '--no-filters', path.join(helperLoose, 'out', 'result.txt')]);
  dateTree(helperLoose, 30);
  const helperSibling = helperFolder('opus907', { 'out/result.txt': 'opus907 result relayed', 'work.blend': 'opus907 working file' });
  relay(path.join(helperSibling, 'out', 'result.txt'));
  dateTree(helperSibling, 30);
  const helperNoOut = scratch(pc, 'opus904', 30);
  // A relayed helper whose lease a helper_clone run holds: the janitor cannot take it, so the folder stays (Artoo, PR 1275).
  const helperLeased = helperFolder('opus910', { 'out/result.txt': 'opus910 result relayed', '.voidsworn-run-active': '' });
  relay(path.join(helperLeased, 'out', 'result.txt'));
  makeCopy('repo', 2, helperLeased);
  dateTree(helperLeased, 30);
  // A relayed helper whose clone holds an older ship file that differs from the newer shared copy: no archive on this path,
  // so the folder is kept (Artoo on PR 1266).
  const helperShip = helperFolder('opus908', { 'out/result.txt': 'opus908 result relayed' });
  relay(path.join(helperShip, 'out', 'result.txt'));
  const helperShipRepo = makeCopy('repo', 2, helperShip);
  write(path.join(helperShipRepo, '.git', 'info', 'exclude'), 'godot/assets/ships/*/\n');
  write(path.join(helperShipRepo, 'godot/assets/ships/T6_11/T6_11.glb'), 'opus908 older unique bake');
  write(path.join(pc, 'build', 'godot/assets/ships/T6_11/T6_11.glb'), 'T6_11 newer shared bake, different');
  buildTimes.push([path.join(pc, 'build', 'godot/assets/ships/T6_11/T6_11.glb'), 10]);
  dateTree(helperShip, 30);
  // Artoo on PR 1592 (cd20c292): a checkout inside out is not hashed as a result but must still pass the Git proof. Every
  // real result relayed; the nested checkout holds an unsaved file (opus1396n) or an unpushed commit (opus1396u): the
  // whole folder and the work survive.
  const nestDirty = helperFolder('opus1396n', { 'out/result.txt': 'opus1396n result relayed' });
  relay(path.join(nestDirty, 'out', 'result.txt'));
  const nestDirtyRepo = makeCopy('repo', 2, path.join(nestDirty, 'out'));
  write(path.join(nestDirtyRepo, 'notes.txt'), 'unsaved notes in a nested checkout');
  dateTree(nestDirty, 30);
  // Review of PR 1592: a ship job's clone waits for its publish; the janitor never removes it, whole folder or checkout.
  const shipJob = helperFolder('opus1396s', { 'out/result.txt': 'start S5 T9_11 opus/issue-1396 Sun 11/22/2026 1:00\r\ndone PASS\r\nall done\r\n' });
  relay(path.join(shipJob, 'out', 'result.txt'));
  const shipClone = makeCopy('repo', 2, shipJob);
  dateTree(shipJob, 30);
  const nestLocal = helperFolder('opus1396u', { 'out/result.txt': 'opus1396u result relayed' });
  relay(path.join(nestLocal, 'out', 'result.txt'));
  const nestLocalRepo = makeCopy('repo', 2, path.join(nestLocal, 'out'));
  const nestUnpushed = commit(path.join(nestLocalRepo, '.git'), 'unpushed work in a nested checkout', main);
  git(['-C', nestLocalRepo, 'update-ref', 'refs/heads/main', nestUnpushed]);
  dateTree(nestLocal, 30);
  // A relayed helper whose clone has a live external worktree (it could hold staged-only work under the clone's .git).
  const helperWorktree = helperFolder('opus909', { 'out/result.txt': 'opus909 result relayed' });
  relay(path.join(helperWorktree, 'out', 'result.txt'));
  const helperWorktreeRepo = makeCopy('repo', 2, helperWorktree);
  git(['-C', helperWorktreeRepo, 'worktree', 'add', '-q', '--detach', path.join(root, 'opus909-external')]);
  dateTree(helperWorktree, 30);
  // Issue 1396: suffixed job folders (opus1211_run6, opus1434o) and playtest folders (pt1120c) are job folders too. A folder
  // the whole-folder rule keeps (results not relayed) still loses its rebuildable checkouts after 6 hours idle (Artoo on
  // #1396: LOAD15's opus1434o; its unrelayed masters stay). Out files, pictures and logs are never touched.
  const suffixRelayed = helperFolder('opus1211_run6', { 'out/result.txt': 'opus1211_run6 result relayed' });
  relay(path.join(suffixRelayed, 'out', 'result.txt'));
  makeCopy('repo', 2, suffixRelayed);
  dateTree(suffixRelayed, 30);
  const jobKeptOut = helperFolder('opus1434o', { 'out/result.txt': 'opus1434o review clip relayed', 'out/master_A.avi': 'opus1434o unrelayed master', 'run.log': 'opus1434o log' });
  relay(path.join(jobKeptOut, 'out', 'result.txt'));
  const jobKeptRepo = makeCopy('repo', 2, jobKeptOut);
  dateTree(jobKeptOut, 30);
  const playtest = helperFolder('pt1120c', { 'out_A/shot.png': 'pt1120c picture', 'out_A/done.txt': 'FAILED' });
  const playtestRepo = makeCopy('repo_A', 2, path.join(playtest, 'out_A'));
  dateTree(playtest, 30);
  const jobRecent = helperFolder('opus1373probe2', { 'out/shot.png': 'opus1373probe2 picture' });
  const jobRecentRepo = makeCopy('repo', 2, jobRecent);
  dateTree(jobRecent, 4);
  const jobWork = helperFolder('opus1238b', { 'out/shot.png': 'opus1238b picture' });
  const jobWorkRepo = makeCopy('repo', 2, jobWork);
  write(path.join(jobWorkRepo, 'godot', 'bench', 'probe.gd'), 'opus1238b unsaved probe');
  dateTree(jobWork, 30);
  const jobLookalike = scratch(pc, 'opus1396.old', 30);
  const jobCheckoutsGone = [jobKeptRepo, playtestRepo];
  // Board, Nov 22: the janitor runs the job head's relay proof (dropjobs) over PASS attempts that still list checkouts.
  // With no relay branch for this job the proof refuses, so the checkout stays in both runs and the reason is logged.
  const relayAttempt = path.join(pc, 'opus1396relay', 'out_20261122_010101_1');
  write(path.join(relayAttempt, 'done.txt'), 'PASS\r\n');
  write(path.join(relayAttempt, 'checkouts.txt'), `new ${'a'.repeat(40)}\r\n`);
  write(path.join(relayAttempt, 'new', 'godot', 'project.godot'), 'pinned checkout stand-in');
  write(path.join(relayAttempt, 'out_new', 'result.txt'), 'relay fixture result');
  dateTree(path.join(pc, 'opus1396relay'), 30);
  const relayCheckout = path.join(relayAttempt, 'new');
  // Artoo on PR 1592: the relay proof never runs where the janitor's own checks refuse: a Board-kept job folder, and a
  // job whose lease a helper run holds (opus910). Both carry a PASS attempt listing a checkout.
  const relayGuarded = [path.join(pc, 'opus1396kept'), helperLeased].map(dir => {
    const at = path.join(dir, 'out_20261122_020202_2');
    write(path.join(at, 'done.txt'), 'PASS\r\n');
    write(path.join(at, 'checkouts.txt'), `new ${'b'.repeat(40)}\r\n`);
    write(path.join(at, 'new', 'godot', 'project.godot'), 'guarded checkout stand-in');
    dateTree(dir, 30);
    return dir;
  });
  const jobCheckoutsKept = [jobWorkRepo];
  // Older scratch with no ownership token: our tools' exact names, a day untouched, no process naming it.
  const legacyOld = scratch(temp, `voidsworn-run-${'a1'.repeat(16)}`, 30);
  const legacyIssue = scratch(temp, `voidsworn-run-320-${'b2'.repeat(16)}`, 30);
  const legacyParity = scratch(temp, 'voidsworn-parity-Ab3dE9', 30);
  const legacyStage7 = scratch(temp, 'stage7-checked-D20_23-abc_1234', 30);
  const legacyRecent = scratch(temp, `voidsworn-run-${'c3'.repeat(16)}`, 20);
  const legacyLocked = scratch(temp, `voidsworn-run-302-${'d4'.repeat(16)}`, 30);
  const legacyProcess = scratch(temp, `voidsworn-run-${'e5'.repeat(16)}`, 30);
  const legacyLookalike = scratch(temp, 'voidsworn-run-notahexname', 30);
  const linkTarget = path.join(root, 'shared-ships-target');
  write(path.join(linkTarget, 'B16_23.glb'), 'shared ship the link points at');
  const legacyLinked = scratch(temp, `voidsworn-run-${'f6'.repeat(16)}`, 30);
  fs.symlinkSync(linkTarget, path.join(legacyLinked, 'nested', 'ships-link'), 'junction');
  dateTree(legacyLinked, 30);
  // Owned runner scratch with a selftest junction inside (R8 dry run: 26 such folders were kept): the link goes as a link.
  const ownedLinked = scratch(temp, ownerName(308, 'e'), 26);
  fs.symlinkSync(linkTarget, path.join(ownedLinked, 'nested', 'ships-link'), 'junction');
  markOwned(ownedLinked, 26);
  dateTree(ownedLinked, 26);
  // A process naming a longer folder name (this name plus "-other") does not keep this one.
  const legacyNear = scratch(temp, `voidsworn-run-${'b8'.repeat(16)}`, 30);
  const sharedSize = 65536;
  const sharedFile = path.join(legacyOld, 'shared.bin');
  fs.writeFileSync(sharedFile, Buffer.alloc(sharedSize));
  fs.linkSync(sharedFile, path.join(legacyNear, 'shared.bin'));
  dateTree(legacyOld, 30);
  dateTree(legacyNear, 30);
  // A folder another account owns (Codex sandbox scratch) is left in place; the rest goes (R8 dry run: 68 rows unsized).
  const legacyUnreadable = windows || process.getuid?.() === 0 ? '' : scratch(temp, `voidsworn-run-${'a7'.repeat(16)}`, 30);
  const lockedPart = legacyUnreadable && path.join(legacyUnreadable, 'nested', 'sandbox-owned');
  if (legacyUnreadable) {
    write(path.join(lockedPart, 'secret.txt'), 'another account');
    dateTree(legacyUnreadable, 30);
    fs.chmodSync(lockedPart, 0o000);
  }
  const oldStage7 = scratch(temp, 'stage7-checked-old', 4);
  markOwned(oldStage7, 4);
  const liveHelper = scratch(temp, `voidsworn-run-${'f'.repeat(32)}`, 5);
  write(path.join(liveHelper, ownerFile), 'f'.repeat(32));
  const activeMarker = path.join(liveHelper, '.voidsworn-run-active');
  write(activeMarker, '');
  dateTree(liveHelper, 5);
  const invalidOwner = scratch(temp, ownerName(307, 'f'), 26);
  markOwned(invalidOwner, 26, 'invalid token');
  const never = ['build', 'build_e', 'work217', 'repo-mirror-b.git', 'recipe', 'runner_backups', 'opus-nonjob', 'pt112', 'ptx1120']
    .map(name => scratch(pc, name, 26));
  never.push(jobLookalike, jobRecentRepo, relayCheckout);
  never.push(makeCopy('repo', 1, laneB), scratch(temp, 'ordinary-folder', 26), scratch(root, 'issue-910-out-of-scope', 26));
  const lockPath = path.join(temp, 'voidsworn-runner-issue-302.lock');
  const work = path.join(pc, 'work217');
  function workCopy(issue, status, hours) {
    const run = path.join(work, `issue-${issue}-openai`, '20260102_031000');
    const out = path.join(run, 'out');
    write(path.join(out, 'status.json'), JSON.stringify({ status, finished: status === 'running' ? '' : '2026-01-02T03:20:00Z' }));
    const dir = makeCopy('repo', 2, run);
    dateTree(dir, hours);
    never.push(out);
    return dir;
  }
  const workClean = workCopy(701, 'checked_push', 5);
  const workLive = workCopy(702, 'running', 25);
  const workLocked = workCopy(302, 'checked_push', 25);
  const workNew = workCopy(704, 'checked_push', 2);
  const workDirty = workCopy(705, 'partial', 26);
  write(path.join(workDirty, 'unfinished.txt'), 'local workhorse note');
  dateTree(workDirty, 26);
  for (const name of ['runner_settings.txt', 'runner_hashes.txt']) {
    const file = path.join(work, name);
    write(file, name);
    never.push(file);
  }
  const salvageRoot = path.join(pc, 'salvage');
  const previousBackup = path.join(salvageRoot, 'earlier', 'proof.txt');
  write(previousBackup, 'keep prior backups');
  never.push(previousBackup);

  function runJanitor(trigger = '', heldPath = lockPath, extra = {}) {
    const command = `$lock = [IO.File]::Open($env:JANITOR_PROOF_LOCK, 'OpenOrCreate', 'ReadWrite', 'None'); ` +
      `if ($env:JANITOR_PROOF_ACTIVE) { $active = [IO.File]::Open($env:JANITOR_PROOF_ACTIVE, 'Open', 'Read', 'None') }; ` +
      `$helper = [IO.File]::Open($env:JANITOR_PROOF_HELPER, 'OpenOrCreate', 'ReadWrite', 'None'); ` +
      `try { & $env:JANITOR_PROOF_SCRIPT ${trigger}; exit $LASTEXITCODE } finally { $lock.Dispose(); $helper.Dispose(); if ($active) { $active.Dispose() } }`;
    return execute(windows ? 'powershell.exe' : 'pwsh',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', command], undefined,
      { JANITOR_PROOF_SCRIPT: janitor, JANITOR_PROOF_LOCK: heldPath, PC_RUN_SCRATCH: '', PC_TEST_GH_DB: '',
        JANITOR_PROOF_ACTIVE: activeMarker, JANITOR_PROOF_HELPER: path.join(helperLeased, '.voidsworn-run-active'), PC_TEST_JANITOR_NOW: fixtureNow.toISOString(),
        PC_TEST_COMMAND_LINES: `fixture.exe --work "${legacyProcess}${path.sep}nested"\nfixture.exe ${legacyNear}-other`, ...extra }, janitorTimeout);
  }
  const recover = [localHistory, trashUntracked, trashStaged, workDirty];
  const remove = [caches, golden, parityLog, shipSuperseded, shipSupersededTwin, genSuperseded, shipNoTwin, genNoTwin, worktreeStale, oldOwned, oldRetry, tokenOnly, recordedFull, opus, helperRelayed,
    legacyOld, legacyIssue, legacyParity, legacyStage7, legacyLinked, ownedLinked, legacyNear, oldStage7, workClean, suffixRelayed, ...jobCheckoutsGone, ...recover];
  const preserve = [boardKept, worktreeLive, helperLeased, helperUnrelayed, helperLoose, helperSibling, helperShip, helperWorktree, helperNoOut, nestDirty, nestLocal, nestDirtyRepo, nestLocalRepo, shipJob, shipClone, jobKeptOut, playtest, jobRecent, jobWork, ...jobCheckoutsKept, legacyRecent, legacyLocked, legacyProcess, legacyLookalike, edited, laneNewest, wrongGen, shipNewer, shipMissing, shipOldTime, invalidRepo, goldenNotes, ...localWork, activeOwned, recordedActive, pathOnly, survivorBare,
    ...lookalikes, replaced, ...(windows ? [survivorCopied] : []), freshRetry, recent, recentOpus, invalidOwner, liveHelper, workLive, workLocked, workNew];
  function decision(report, dir, word) {
    const row = report.split(/\r?\n/).find(line => line.includes(`${dir} (`));
    assert(row?.includes(word) && /\d+ bytes/.test(row), `missing ${word} and size for ${dir}: ${row || report}`);
    return row;
  }
  function checkoutSnapshot(dir) {
    const files = ['tracked.txt', '.git/index', '.git/logs/HEAD', '.git/FETCH_HEAD'];
    return files.map(file => {
      const full = path.join(dir, file);
      return { bytes: fs.readFileSync(full), modified: fs.statSync(full, { bigint: true }).mtimeNs };
    });
  }
  for (const [file, hours] of buildTimes) dated(file, hours);
  const beforeScan = oldCopies.map(checkoutSnapshot);
  const dry = runJanitor('--dry-run');
  assert.deepEqual(oldCopies.map(checkoutSnapshot), beforeScan);
  const secondDry = runJanitor('--dry-run');
  assert.deepEqual(oldCopies.map(checkoutSnapshot), beforeScan);
  for (const dir of oldCopies) {
    assert.equal(decision(secondDry, dir, 'would remove'), decision(dry, dir, 'would remove'));
  }
  for (const dir of remove) decision(dry, dir, 'would remove');
  for (const dir of preserve) decision(dry, dir, dir.startsWith(temp + path.sep) || /[\\/](?:opus\d+|pt\d{4})[^\\/]*$/.test(dir) ? 'would keep' : (jobCheckoutsKept.includes(dir) ? 'retained' : 'kept'));
  for (const dir of lookalikes) {
    assert.match(decision(dry, dir, 'would keep'), /name match without owner record/);
  }
  assert.match(decision(dry, recordedActive, 'would keep'), /issue #302 lock is held/);
  assert.match(decision(dry, replaced, 'would keep'), /ownership token differs from runner status/);
  for (const [dir, file] of [[shipSuperseded, 'godot/assets/ships/T1_11/T1_11.glb'], [genSuperseded, 'godot/gen/manifest.json']]) {
    assert(dry.split(/\r?\n/).some(line => line.startsWith(`superseded by the shared build: ${file} (copy `) && /bytes; build .* bytes\)$/.test(line)),
      `superseded call for ${dir} must log both times and sizes`);
  }
  // Artoo, PR 1260: an older ignored GLB with unique bytes and a newer, different same-name build file is only nominated;
  // it is archived and read back before its checkout goes.
  assert.match(decision(dry, shipSuperseded, 'would remove'), /after checked archive of 1 superseded ship or gen files, \d+ bytes/);
  assert.match(decision(dry, genSuperseded, 'would remove'), /after checked archive of 1 superseded ship or gen files/);
  assert.match(decision(dry, worktreeLive, 'retained'), /checkout may be shared with another worktree: /);
  assert.match(decision(dry, shipNoTwin, 'would remove'), /after checked archive of 1 superseded ship or gen files/);
  assert.match(decision(dry, genNoTwin, 'would remove'), /after checked archive of 1 superseded ship or gen files/);
  assert.match(dry, /superseded by the shared build: godot\/gen\/damage\/D9_11_damage\.scn \(copy .*; no build twin; build gen regenerated /);
  assert.match(dry, /superseded by the shared build: godot\/assets\/ships\/T5_11\/T5_11_damage\.glb \(copy .*; no build twin; ship T5_11 installed /);
  assert.match(decision(dry, shipNewer, 'retained'), /shared ship copy could not be verified/);
  assert.match(dry, /copy is not older than the shared build, kept: godot\/assets\/ships\/T2_11\/T2_11\.glb \(copy /);
  assert.match(decision(dry, shipMissing, 'retained'), /shared ship copy could not be verified/);
  assert.match(decision(dry, shipOldTime, 'retained'), /shared ship copy could not be verified/);
  assert.match(dry, /shared copy time not trusted, kept: godot\/assets\/ships\/T4_11\/T4_11\.glb/);
  assert.match(decision(dry, wrongGen, 'retained'), /shared generated copy could not be verified/);
  assert.match(decision(dry, helperUnrelayed, 'would keep'), /results not all relayed: 2 of 3 out files are not on a relay branch/);
  assert(dry.includes(`helper file not on a relay branch: ${helperHuge} (105906176 bytes; over GitHub's 100 MB file limit, not read)`), 'a huge file is not hashed: ' + dry);
  assert(dry.includes(`helper file not on a relay branch: ${path.join(helperUnrelayed, 'out', 'shot.png')} (`), 'unrelayed file is listed');
  assert.match(decision(dry, helperWorktree, 'would keep'), /is not rebuildable: checkout may be shared with another worktree: /);
  assert.match(decision(dry, helperShip, 'would keep'), /holds 1 ship or gen files that differ from the shared build/);
  assert.match(decision(dry, helperLoose, 'would keep'), /results not all relayed: 1 of 1 out files are not on a relay branch/);
  assert.match(decision(dry, helperSibling, 'would keep'), /1 files outside out are not in a rebuildable checkout/);
  assert(dry.includes(`helper file outside out and outside a checkout: ${path.join(helperSibling, 'work.blend')} (`), 'working file is listed');
  assert.match(decision(dry, helperNoOut, 'would keep'), /no out folder to prove the results were relayed/);
  assert.match(decision(dry, helperLeased, 'would keep'), /a helper run holds this folder's lease/);
  // Issue 1396: the checkout-only path, its record lines and its refusals.
  assert(dry.includes(`job relay: checkouts kept: ${relayAttempt} (results not relayed yet: board/pc-out-opus1396relay:out_20261122_010101_1: branch board/pc-out-opus1396relay (from the job name) is not on origin`), 'the dry run lists the relay proof refusal: ' + dry);
  assert(dry.includes(`job relay check exit 0 in ${path.join(pc, 'opus1396relay')}`), 'the head ran for the unguarded job');
  assert(dry.includes(`job relay checkouts would keep in ${relayGuarded[0]} (kept: on the Board keep list)`), 'a Board-kept job never reaches the relay proof: ' + dry);
  assert(dry.includes(`job relay checkouts would keep in ${relayGuarded[1]} (a helper run holds this folder's lease)`), 'a held lease never reaches the relay proof');
  for (const dir of relayGuarded) assert(!dry.includes(`job relay check exit 0 in ${dir}`) && !dry.includes(`job relay: checkouts kept: ${dir}`), `the head never ran for ${dir}`);
  assert.match(decision(dry, jobKeptOut, 'would keep'), /results not all relayed: 1 of 2 out files are not on a relay branch/);
  assert.match(decision(dry, jobKeptRepo, 'would remove'), /kept checkout would remove \(rebuildable\)/);
  // DRY2 on the PC (Artoo on PR 1592): a checkout inside an out folder is not output. Its files and pack are never hashed
  // as results; it takes the Git proof instead. pt1120c's out_A holds repo_A beside two unrelayed results: 2 of 2.
  assert.match(decision(dry, playtest, 'would keep'), /results not all relayed: 2 of 2 out files are not on a relay branch/);
  assert.match(decision(dry, shipJob, 'would keep'), /a ship clone waits for its publish/);
  assert.match(decision(dry, shipClone, 'retained'), /a ship clone waits for its publish/);
  for (const [dir, repo] of [[nestDirty, nestDirtyRepo], [nestLocal, nestLocalRepo]]) {
    assert.match(decision(dry, dir, 'would keep'), new RegExp(`checkout ${repo.replace(/[\\^$.*+?()[\]{}|]/g, '\\$&')} is not rebuildable: `), 'a nested checkout with local work keeps its folder: ' + dry);
  }
  assert(!/helper file not on a relay branch: [^\r\n]*[\\/]\.git[\\/]/.test(dry) && !dry.includes(`helper file not on a relay branch: ${playtestRepo}`), 'no file inside a checkout is hashed as a result');
  assert.match(decision(dry, playtestRepo, 'would remove'), /kept checkout would remove \(rebuildable\)/);
  const headOf = dir => git(['-C', dir, 'rev-parse', 'HEAD']);
  for (const dir of jobCheckoutsGone) assert(dry.includes(`job checkout record: ${dir} HEAD ${headOf(dir)}, `), `HEAD and status logged for ${dir}`);
  assert.match(dry, new RegExp(`job checkouts would keep in ${jobRecent.replace(/[\\^$.*+?()[\]{}|]/g, '\\$&')} \\(job folder touched in the last 6 hours\\)`));
  assert.match(decision(dry, jobWorkRepo, 'retained'), /working tree needs keeping: \?\? godot\/bench\/probe\.gd/);
  assert(dry.includes(`job checkout status: ${jobWorkRepo}: ?? godot/bench/probe.gd`), 'the unsaved file is listed');
  assert.match(dry, /job checkouts would keep in .*opus910 \(a helper run holds this folder's lease\)/);
  assert.match(decision(dry, helperShip, 'would keep'), /holds 1 ship or gen files/);
  assert.match(decision(dry, path.join(helperShip, 'repo'), 'retained'), /superseded ship or gen files need a checked archive/);
  assert.match(decision(dry, boardKept, 'would keep'), /kept: on the Board keep list/);
  assert.match(dry, /Board keep list: 2 paths/);
  assert.match(decision(dry, legacyRecent, 'would keep'), /touched in the last 24 hours/);
  assert.match(decision(dry, legacyLocked, 'would keep'), /issue #302 lock is held/);
  assert.match(decision(dry, legacyProcess, 'would keep'), /a running process names this folder \(process 0 fixture\)/);
  assert(!dry.includes('fixture.exe'), 'a command line never reaches the log (Artoo, PR 1266)');
  assert.match(decision(dry, legacyLookalike, 'would keep'), /name match without owner record/);
  assert.match(decision(dry, legacyLinked, 'would remove'), /1 links not followed; scratch named by our tools/);
  assert.match(decision(dry, ownedLinked, 'would remove'), /1 links not followed; owned TEMP scratch/);
  assert(dry.includes(`link not followed: ${path.join(ownedLinked, 'nested', 'ships-link')} -> `), 'the link and its target are logged');
  decision(dry, legacyNear, 'would remove');
  if (legacyUnreadable) {
    assert.match(decision(dry, legacyUnreadable, 'would remove'), /1 folders another account owns cannot be removed and are not counted; scratch named by our tools/);
    assert(dry.includes(`cannot remove: ${lockedPart} (another account owns it or it cannot be read; left in place)`), 'the unreadable folder is listed');
  }
  if (!windows) {
    // With no process list (and no test list), older scratch is kept.
    assert.match(decision(runJanitor('--dry-run', lockPath, { PC_TEST_COMMAND_LINES: null }), legacyOld, 'would keep'),
      /running processes could not be checked/);
  }
  assert.match(decision(dry, pathOnly, 'would keep'), /runner status record lacks token or creation time/);
  assert.match(decision(dry, survivorBare, 'would keep'), /runner status record names a folder without its ownership token/);
  if (windows) assert.match(decision(dry, survivorCopied, 'would keep'), /recorded directory was replaced/);
  assert.match(decision(dry, invalidOwner, 'would keep'), /ownership token file changed/);
  for (const dir of recover) decision(dry, dir, 'would remove (after checked salvage');
  decision(dry, failedSalvage, 'would remove (after checked salvage');
  for (const dir of [...remove, ...preserve, ...never]) assert(fs.existsSync(dir), `dry run changed ${dir}`);
  // Artoo on PR 1592: a dry run never creates a job folder's lease; the live run below must take one where none existed.
  for (const dir of [jobKeptOut, playtest]) assert(!fs.existsSync(path.join(dir, '.voidsworn-run-active')), `dry run created a lease in ${dir}`);
  for (const dir of never) assert(!dry.includes(`${dir} (`), `unexpected candidate ${dir}`);
  assert.match(dry, /issue #302 lock is held/);
  assert.match(dry, /touched in the last 3 hours/);
  assert.match(dry, /helper scratch lock is held/);
  assert.match(dry, /shared generated copy could not be verified/);
  assert.match(dry, /free space before: [\d]+ bytes[\s\S]*free space after: [\d]+ bytes\r?\nall done$/);
  // The individual rows exclude the cross-folder hard link; the closing total counts its file once.
  for (const folder of [legacyOld, legacyNear]) {
    assert.match(decision(dry, folder, 'would remove'), new RegExp(sharedSize + ' in hard links shared outside it'));
  }
  const total = /^space would be freed: (\d+) bytes \([\d.,]+ GB\) by (\d+) removals; hard links shared outside (?:the removal set|a removed folder) are not counted; \d+ folders another account owns cannot be removed and are not counted$/m.exec(dry);
  assert(total, 'dry run total line: ' + dry.slice(-800));
  const rows = [...dry.matchAll(/^(?:kept checkout )?would remove\b[^\n]*\((\d+) bytes would be freed/gm)].map(m => +m[1]);
  assert.equal(rows.length, +total[2], 'one count per would-remove row: ' + rows.length + ' vs ' + total[2]);
  assert.equal(+total[1] - rows.reduce((a, b) => a + b, 0), sharedSize, 'the total adds the cross-folder file once');
  assert.deepEqual(fs.readdirSync(salvageRoot), ['earlier']);
  // Issue 1396 (the first PC dry run ran 1 h 47 min unfinished): the time cap stops before the next folder and says where;
  // a dry run never writes janitor_resume.txt; a resume file makes the job folders start at its name and wrap around.
  const resumeFile = path.join(pc, 'janitor_resume.txt');
  const ordinalTwin = scratch(pc, 'opus12110', 30);
  const jobTimes = report => report.split(/\r?\n/).filter(l => l.startsWith('folder time: ' + pc + path.sep)).map(l => l.slice(13).replace(/ \d+ s$/, ''));
  const capDry = runJanitor('--dry-run', lockPath, { PC_JANITOR_CAP_SECONDS: '0' });
  assert.match(capDry, /time cap: stopped the temp folders at \S+ after \d+ s \(cap 0 s\); the next run starts there/);
  assert.match(capDry, /time cap: stopped the root folders at (?:opus|pt)\S* after \d+ s \(cap 0 s\); the next run starts there/);
  assert(!/folder time: /.test(capDry) && !/job relay check exit/.test(capDry), 'a capped run reaches no folder: ' + capDry);
  // Review of PR 1592: the board lanes and the Workhorse runs stop at the cap too, so no lane checkout is even sized.
  assert.match(capDry, /time cap: stopped the lane folders at \S+ after \d+ s \(cap 0 s\); the next run starts there/);
  assert(!/kept checkout (?:would remove|retained|removed)/.test(capDry), 'a capped run reaches no lane checkout: ' + capDry);
  assert(!fs.existsSync(resumeFile), 'a dry run never writes janitor_resume.txt');
  // A fresh baseline with the same inventory as the resumed runs (Artoo on PR 1592: opus12110 is made after the first dry run).
  const allJobs = jobTimes(runJanitor('--dry-run'));
  assert(allJobs.includes(ordinalTwin), 'the baseline holds the new folder: ' + allJobs);
  assert(allJobs.includes(path.join(pc, 'opus1396relay')) && allJobs.length > 5, 'every job folder has a folder time line in test mode: ' + allJobs);
  write(resumeFile, 'root opus1396relay\r\n');
  const resumed = jobTimes(runJanitor('--dry-run'));
  assert.equal(resumed[0], path.join(pc, 'opus1396relay'), 'the job folders start at the resume name: ' + resumed);
  assert.deepEqual([...resumed].sort(), [...allJobs].sort(), 'and wrap around to reach every job folder once');
  assert.equal(read(resumeFile), 'root opus1396relay\r\n', 'a dry run leaves the resume file as it was');
  // Review of PR 1592: one ordering for the walk and the lookup. Sort-Object put opus1211_run6 before opus12110 while the
  // ordinal lookup judged it greater, so a cursor at opus12110 restarted at opus1211_run6.
  write(resumeFile, 'root opus12110\r\n');
  const resumedAt = jobTimes(runJanitor('--dry-run'));
  assert.equal(resumedAt[0], ordinalTwin, 'an exact resume name starts there: ' + resumedAt);
  assert.deepEqual([...resumedAt].sort(), [...allJobs].sort());
  fs.rmSync(resumeFile);
  const live = runJanitor('--low-space');
  assert(!fs.existsSync(resumeFile), 'a run that reached every folder leaves no resume file');
  const reportFile = fs.readdirSync(pc).find(name => /^janitor_\d{8}-\d{4}\.txt$/.test(name));
  assert(reportFile && read(path.join(pc, reportFile)).includes('all done'));
  for (const dir of remove) {
    decision(live, dir, 'removed');
    assert(!fs.existsSync(dir), `janitor left ${dir}`);
  }
  for (const dir of [...preserve, ...never]) assert(fs.existsSync(dir), `janitor removed ${dir}`);
  for (const [dir, file, text] of [[jobKeptOut, 'out/master_A.avi', 'opus1434o unrelayed master'], [jobKeptOut, 'run.log', 'opus1434o log'],
    [playtest, 'out_A/shot.png', 'pt1120c picture'], [playtest, 'out_A/done.txt', 'FAILED']]) {
    assert.equal(read(path.join(dir, file)), text, `checkout-only cleanup kept ${file} in ${dir}`);
  }
  assert(live.includes(`job relay: checkouts kept: ${relayAttempt} (`) && live.includes(`job relay check exit 0 in ${path.join(pc, 'opus1396relay')}`), 'the live run runs the relay proof and keeps an unrelayed checkout: ' + live);
  assert(live.includes(`job relay checkouts kept in ${relayGuarded[0]} (kept: on the Board keep list)`) && live.includes(`job relay checkouts kept in ${relayGuarded[1]} (a helper run holds this folder's lease)`), 'guards hold in the live run too');
  for (const dir of relayGuarded) assert(fs.existsSync(path.join(dir, 'out_20261122_020202_2', 'new', 'godot', 'project.godot')), `guarded checkout stays in ${dir}`);
  // The missing-lease case (Artoo on PR 1592): the live run created and held a lease in each folder that had none, so a
  // helper_clone start (OpenOrCreate, no sharing) during the removal would have stopped instead of overlapping.
  for (const dir of [jobKeptOut, playtest]) assert(fs.existsSync(path.join(dir, '.voidsworn-run-active')), `live run took no lease in ${dir}`);
  // Review of PR 1592: the whole-folder rule creates and holds the lease on a live run when the folder had none.
  assert(fs.existsSync(path.join(helperUnrelayed, '.voidsworn-run-active')), 'live run took the helper lease in a folder that had none');
  assert.equal(read(path.join(linkTarget, 'B16_23.glb')), 'shared ship the link points at', 'a removed link never touches its target');
  if (legacyUnreadable) {
    decision(live, legacyUnreadable, 'removed all but 1 folders another account owns');
    assert(fs.existsSync(lockedPart), 'the unreadable folder is left in place');
    assert.deepEqual(fs.readdirSync(legacyUnreadable), ['nested'], 'everything readable is removed');
    assert.deepEqual(fs.readdirSync(path.join(legacyUnreadable, 'nested')), ['sandbox-owned']);
  }
  const store = path.join(salvageRoot, 'superseded_store');
  const stored = {};
  for (const [dir, file, bytes] of [[shipSuperseded, 'godot/assets/ships/T1_11/T1_11.glb', 'ship-superseded copy bake'],
    [shipSupersededTwin, 'godot/assets/ships/T1_11/T1_11.glb', 'ship-superseded copy bake'],
    [genSuperseded, 'godot/gen/manifest.json', 'gen-superseded copy bake'],
    [shipNoTwin, 'godot/assets/ships/T5_11/T5_11_damage.glb', 'ship-no-twin copy bake'],
    [genNoTwin, 'godot/gen/damage/D9_11_damage.scn', 'gen-no-twin copy bake']]) {
    const archive = path.join(salvageRoot, `board_b_${path.basename(dir)}_superseded`);
    const row = read(path.join(archive, 'superseded_manifest.txt'));
    const hash = crypto.createHash('sha256').update(bytes).digest('hex');
    assert.equal(row, `${hash}  ${Buffer.byteLength(bytes)}  ${file}\n`);
    assert.equal(read(path.join(store, `${hash}.bin`)), bytes, `the store keeps the unique bytes of ${file}`);
    assert.match(live, new RegExp(`superseded archive verified: ${archive.replace(/[\\^$.*+?()[\]{}|]/g, '\\$&')} \\(1 files, \\d+ bytes; `));
    stored[hash] = true;
  }
  assert.deepEqual(fs.readdirSync(store).sort(), Object.keys(stored).map(hash => `${hash}.bin`).sort());
  assert.match(live, /0 new bytes in the shared store, 1 already stored\)/);
  decision(live, failedSalvage, 'untracked path cannot be verified');
  // A live run that reaches its cap writes where each loop stopped, for the next run.
  if (!windows) {
    // Review of PR 1592: a resume file that is a link is never written through (its target outside stays as it was).
    const outside = path.join(root, 'resume-target.txt');
    write(outside, 'not the janitor\'s file\n');
    fs.symlinkSync(outside, resumeFile);
    const linked = runJanitor('', lockPath, { PC_JANITOR_CAP_SECONDS: '0' });
    assert.match(linked, /resume file (?:ignored|not written): .* is not a plain file/, linked);
    assert.equal(read(outside), 'not the janitor\'s file\n', 'the link target is untouched');
    assert(fs.lstatSync(resumeFile).isSymbolicLink(), 'the link stays a link');
    fs.rmSync(resumeFile);
  }
  const capLive = runJanitor('', lockPath, { PC_JANITOR_CAP_SECONDS: '0' });
  const stopped = [...capLive.matchAll(/time cap: stopped the (lane|temp|root) folders at (\S+) after/g)].map(m => m[1] + ' ' + m[2]);
  assert.equal(stopped.length, 3, 'the lanes, TEMP and job folders each stop at a zero cap: ' + capLive);
  assert(!fs.existsSync(resumeFile + '.new'), 'no half-written resume file is left');
  assert.equal(read(resumeFile).replace(/\r\n/g, '\n'), stopped.join('\n') + '\n');
  fs.rmSync(resumeFile);
  assert(fs.existsSync(failedSalvage));
  const historyBackup = path.join(salvageRoot, 'board_b_repo-kept-local-history', 'salvage.bundle');
  const restored = makeCopy('restored', 2);
  git(['-C', restored, 'bundle', 'verify', historyBackup]);
  git(['-C', restored, 'fetch', '-q', historyBackup, `refs/salvage/${unpushed}`]);
  assert.equal(git(['-C', restored, 'rev-parse', 'FETCH_HEAD']), unpushed);
  const stageBackup = path.join(salvageRoot, 'board_b_repo-kept-staged');
  git(['-C', restored, 'apply', path.join(stageBackup, 'salvage.patch')]);
  git(['-C', restored, 'apply', '--cached', path.join(stageBackup, 'salvage-index.patch')]);
  assert.deepEqual(fs.readFileSync(path.join(restored, 'notes.txt')), Buffer.from([0, 1, 3]));
  const zip = path.join(salvageRoot, 'work217_issue-705-openai_20260102_031000', 'untracked.zip');
  const zipRead = `Add-Type -AssemblyName System.IO.Compression.FileSystem; $zip = [IO.Compression.ZipFile]::OpenRead($env:FIXTURE_ZIP); ` +
    `try { $zip.Entries.FullName; [IO.StreamReader]::new($zip.GetEntry('unfinished.txt').Open()).ReadToEnd() } finally { $zip.Dispose() }`;
  assert.match(execute(windows ? 'powershell.exe' : 'pwsh', ['-NoProfile', '-Command', zipRead], undefined, { FIXTURE_ZIP: zip }),
    /^unfinished\.txt\r?\nlocal workhorse note$/);
  const nightly = scratch(temp, 'issue-308-rate-limit', 4);
  markOwned(nightly, 4);
  assert.equal(runJanitor('--low-space'), '');
  assert(fs.existsSync(nightly));
  const nightTemp = path.join(root, 'night-temp');
  fs.mkdirSync(nightTemp);
  const nightRun = now => runJanitor('--nightly', lockPath, {
    PC_TEST_JANITOR_NOW: now, PC_RUN_TEMP: nightTemp, JANITOR_PROOF_ACTIVE: '', USERPROFILE: path.join(root, 'night-profile')
  });
  fs.mkdirSync(path.join(root, 'night-profile', 'Downloads', 'voidsworn_test'), { recursive: true });
  assert.equal(nightRun('2026-11-19T08:59:59Z'), '');
  assert.equal(nightRun('2026-11-19T12:00:00Z'), '');
  assert.equal(nightRun('2026-07-19T19:00:00Z'), '');
  assert.match(nightRun('2026-11-19T09:00:00Z'), /janitor --nightly/);
  assert.match(nightRun('2026-07-19T10:59:59Z'), /janitor --nightly/);
  assert.equal(nightRun('2026-07-19T10:59:59Z'), '');
  // Issue 1180: --after-job skips silently while any GPU claim is held, and shares the hourly allowance with --low-space.
  const nightVt = path.join(root, 'night-profile', 'Downloads', 'voidsworn_test');
  const afterJob = (now, extra = {}) => runJanitor('--after-job', lockPath, {
    PC_TEST_JANITOR_NOW: now, PC_RUN_TEMP: nightTemp, JANITOR_PROOF_ACTIVE: '', USERPROFILE: path.join(root, 'night-profile'), ...extra
  });
  write(path.join(nightVt, 'gpu_solo'), '{"token":"t","issue":"bench","pid":1,"mode":"solo"}\n');
  write(path.join(nightVt, 'gpu_slot_1'), '');
  assert.equal(afterJob('2026-11-20T15:00:00Z'), '', 'a held solo claim stops the after-job cleanup');
  write(path.join(nightVt, 'gpu_solo'), '');
  write(path.join(nightVt, 'gpu_slot_2'), '{"token":"u","issue":"render","pid":2,"mode":"shared"}\n');
  assert.equal(afterJob('2026-11-20T15:00:00Z'), '', 'a held shared claim stops it too');
  write(path.join(nightVt, 'gpu_slot_2'), '');
  assert.match(afterJob('2026-11-20T15:00:00Z'), /janitor --after-job/, 'empty claim files: it runs, the GPU checks spent no allowance');
  assert.equal(afterJob('2026-11-20T15:30:00Z'), '', 'once an hour');
  assert.equal(runJanitor('--low-space', lockPath, {
    PC_TEST_JANITOR_NOW: '2026-11-20T15:40:00Z', PC_RUN_TEMP: nightTemp, JANITOR_PROOF_ACTIVE: '', USERPROFILE: path.join(root, 'night-profile')
  }), '', 'the low-space trigger shares the hour');
  assert.match(afterJob('2026-11-20T16:00:01Z'), /janitor --after-job/);
  const heldLock = path.join(nightVt, 'janitor.lock');
  assert.equal(runJanitor('--after-job', heldLock, {
    PC_TEST_JANITOR_NOW: '2026-11-20T18:00:00Z', PC_RUN_TEMP: nightTemp, JANITOR_PROOF_ACTIVE: '', USERPROFILE: path.join(root, 'night-profile')
  }), '', 'a busy janitor lock: skipped without a word');
  if (windows) {
    const inUse = scratch(temp, 'issue-309-in-use', 4);
    markOwned(inUse, 4);
    const heldFile = path.join(inUse, 'nested', 'proof.txt');
    decision(runJanitor('', heldFile), inUse, 'kept');
    assert.equal(read(heldFile), 'issue-309-in-use');
  }
  const pausedTemp = scratch(temp, 'issue-310-pause', 4);
  markOwned(pausedTemp, 4);
  write(flag, 'GPU not cleared: paused by the Board at 12:30');
  assert.match(runJanitor(), /janitor skipped during the PC pause/);
  assert(fs.existsSync(pausedTemp));
  console.log('PASS janitor: dry and live decisions, retained edits and history, issue locks, age, safe paths, and the automatic rate limit');
} catch (error) {
  // Print the check failure before teardown so a Windows sharing error cannot hide it.
  console.error(error);
  process.exitCode = 1;
} finally {
  for (const dir of fs.readdirSync(path.join(root, 'temp'), { withFileTypes: true })) {
    const locked = path.join(root, 'temp', dir.name, 'nested', 'sandbox-owned');
    if (fs.existsSync(locked)) fs.chmodSync(locked, 0o755);
  }
  // Lane A exhausted the old 600 ms retry window. Six 100 ms backoff steps allow up to 2.1 s on a busy path.
  fs.rmSync(root, { recursive: true, force: true, maxRetries: 6, retryDelay: 100 });
}
