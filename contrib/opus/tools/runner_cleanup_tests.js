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
function execute(exe, args, input, extra = {}) {
  const r = spawnSync(exe, args, { input, cwd: root, env: { ...env, ...extra }, encoding: 'utf8', windowsHide: true, timeout: 30000 });
  if (r.error) throw r.error;
  assert.equal(r.status, 0, `${exe} ${args.join(' ')}: ${r.stdout}\n${r.stderr}`);
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
  assert.equal(git(['-C', history, 'rev-parse', 'HEAD']), local);
  assert.equal(read(path.join(dirty, 'work.txt')), 'local work');
  assert.equal(read(path.join(staged, 'staged.txt')), 'staged work');
  assert.equal(read(path.join(invalid, 'proof.txt')), 'same name, no Git checkout');
  assert.equal(read(path.join(other, 'proof.txt')), 'unrelated scratch');
  for (const dir of [repo, newest, noncandidate, linked]) assert(fs.existsSync(dir), dir);
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
  const opus = scratch(pc, 'opus901out1', 73);
  const recentOpus = scratch(pc, 'opus902', 71);
  const oldStage7 = scratch(temp, 'stage7-checked-old', 4);
  markOwned(oldStage7, 4);
  const liveHelper = scratch(temp, `voidsworn-run-${'f'.repeat(32)}`, 5);
  write(path.join(liveHelper, ownerFile), 'f'.repeat(32));
  const activeMarker = path.join(liveHelper, '.voidsworn-run-active');
  write(activeMarker, '');
  dateTree(liveHelper, 5);
  const invalidOwner = scratch(temp, ownerName(307, 'f'), 26);
  markOwned(invalidOwner, 26, 'invalid token');
  const never = ['build', 'build_e', 'work217', 'repo-mirror-b.git', 'recipe', 'runner_backups', 'opus-nonjob']
    .map(name => scratch(pc, name, 26));
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
      `try { & $env:JANITOR_PROOF_SCRIPT ${trigger}; exit $LASTEXITCODE } finally { $lock.Dispose(); if ($active) { $active.Dispose() } }`;
    return execute(windows ? 'powershell.exe' : 'pwsh',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', command], undefined,
      { JANITOR_PROOF_SCRIPT: janitor, JANITOR_PROOF_LOCK: heldPath, PC_RUN_SCRATCH: '', PC_TEST_GH_DB: '',
        JANITOR_PROOF_ACTIVE: activeMarker, PC_TEST_JANITOR_NOW: fixtureNow.toISOString(), ...extra });
  }
  const recover = [localHistory, trashUntracked, trashStaged, workDirty];
  const remove = [caches, golden, parityLog, shipSuperseded, shipSupersededTwin, genSuperseded, oldOwned, oldRetry, tokenOnly, recordedFull, opus, oldStage7, workClean, ...recover];
  const preserve = [edited, laneNewest, wrongGen, shipNewer, shipMissing, shipOldTime, invalidRepo, goldenNotes, ...localWork, activeOwned, recordedActive, pathOnly, survivorBare,
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
  for (const dir of preserve) decision(dry, dir, dir.startsWith(temp + path.sep) || dir === recentOpus ? 'would keep' : 'kept');
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
  assert.match(decision(dry, shipNewer, 'retained'), /shared ship copy could not be verified/);
  assert.match(dry, /copy is not older than the shared build, kept: godot\/assets\/ships\/T2_11\/T2_11\.glb \(copy /);
  assert.match(decision(dry, shipMissing, 'retained'), /shared ship copy could not be verified/);
  assert.match(decision(dry, shipOldTime, 'retained'), /shared ship copy could not be verified/);
  assert.match(dry, /shared copy time not trusted, kept: godot\/assets\/ships\/T4_11\/T4_11\.glb/);
  assert.match(decision(dry, wrongGen, 'retained'), /shared generated copy could not be verified/);
  assert.match(decision(dry, pathOnly, 'would keep'), /runner status record lacks token or creation time/);
  assert.match(decision(dry, survivorBare, 'would keep'), /runner status record names a folder without its ownership token/);
  if (windows) assert.match(decision(dry, survivorCopied, 'would keep'), /recorded directory was replaced/);
  assert.match(decision(dry, invalidOwner, 'would keep'), /ownership token file changed/);
  for (const dir of recover) decision(dry, dir, 'would remove (after checked salvage');
  decision(dry, failedSalvage, 'would remove (after checked salvage');
  for (const dir of [...remove, ...preserve, ...never]) assert(fs.existsSync(dir), `dry run changed ${dir}`);
  for (const dir of never) assert(!dry.includes(`${dir} (`), `unexpected candidate ${dir}`);
  assert.match(dry, /issue #302 lock is held/);
  assert.match(dry, /touched in the last 3 hours/);
  assert.match(dry, /helper scratch lock is held/);
  assert.match(dry, /shared generated copy could not be verified/);
  assert.match(dry, /free space before: [\d]+ bytes[\s\S]*free space after: [\d]+ bytes\r?\nall done$/);
  assert.deepEqual(fs.readdirSync(salvageRoot), ['earlier']);
  const live = runJanitor('--low-space');
  const reportFile = fs.readdirSync(pc).find(name => /^janitor_\d{8}-\d{4}\.txt$/.test(name));
  assert(reportFile && read(path.join(pc, reportFile)).includes('all done'));
  for (const dir of remove) {
    decision(live, dir, 'removed');
    assert(!fs.existsSync(dir), `janitor left ${dir}`);
  }
  for (const dir of [...preserve, ...never]) assert(fs.existsSync(dir), `janitor removed ${dir}`);
  const store = path.join(salvageRoot, 'superseded_store');
  const stored = {};
  for (const [dir, file, bytes] of [[shipSuperseded, 'godot/assets/ships/T1_11/T1_11.glb', 'ship-superseded copy bake'],
    [shipSupersededTwin, 'godot/assets/ships/T1_11/T1_11.glb', 'ship-superseded copy bake'],
    [genSuperseded, 'godot/gen/manifest.json', 'gen-superseded copy bake']]) {
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
} finally {
  fs.rmSync(root, { recursive: true, force: true, maxRetries: 3 });
}
