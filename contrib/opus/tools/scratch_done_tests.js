'use strict';
// Issue 1180 (Board, Nov 20): tools/pc/scratch_done.ps1 ends a queue job's owned TEMP scratch. On PASS it goes (links
// removed as links, never followed); on FAILED the newest scratch per job stays a day and older failures of the same job
// go. Only owned voidsworn-run-<32 hex> folders directly under the base TEMP, with no held run marker, are touched.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawn, spawnSync } = require('node:child_process');
const script = path.resolve(__dirname, '../../../tools/pc/scratch_done.ps1');
const windows = process.platform === 'win32';
const shell = windows ? 'powershell.exe' : 'pwsh';
if (spawnSync(shell, ['-NoProfile', '-Command', 'exit 0']).error) {
  if (process.env.CI && !windows) throw new Error('pwsh is required in CI');
  console.log(`SKIP scratch_done fixtures: no ${shell} here (CI runs them)`);
  process.exit(0);
}
const base = fs.mkdtempSync(path.join(os.tmpdir(), 'scratch-done-proof-'));
const outside = fs.mkdtempSync(path.join(os.tmpdir(), 'scratch-done-outside-'));
const hex = c => c.repeat(32);
function scratch(char, { owner = true, failedKey = null } = {}) {
  const dir = path.join(base, `voidsworn-run-${hex(char)}`);
  fs.mkdirSync(path.join(dir, 'tool', 'cache'), { recursive: true });
  fs.writeFileSync(path.join(dir, 'tool', 'cache', 'big.bin'), 'scratch bytes');
  if (owner) fs.writeFileSync(path.join(dir, '.voidsworn-run-owner'), hex(char));
  if (failedKey !== null) fs.writeFileSync(path.join(dir, '.voidsworn-run-failed'), failedKey);
  return dir;
}
const pauseFile = path.join(outside, 'gpu_go.txt');
const run = (dir, code, key) => {
  const r = spawnSync(shell, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script, '-Scratch', dir, '-Code', String(code),
    '-BaseTemp', base, '-JobKey', key], { encoding: 'utf8', timeout: 30000,
    env: { ...process.env, PC_RUNNER_TEST: '1', PC_CLEANUP_PAUSE_FILE: pauseFile } });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  return r.stdout;
};
try {
  fs.writeFileSync(path.join(outside, 'keep.txt'), 'outside the scratch');
  const passed = scratch('a');
  fs.symlinkSync(outside, path.join(passed, 'tool', 'link-out'), windows ? 'junction' : 'dir');
  assert.match(run(passed, 0, 'ship_job C:\\jobs\\one'), /job scratch removed after PASS/);
  assert(!fs.existsSync(passed), 'PASS removes the scratch');
  assert.equal(fs.readFileSync(path.join(outside, 'keep.txt'), 'utf8'), 'outside the scratch', 'a link is never followed');

  const key = 'ship_job C:\\jobs\\two';
  const olderSame = scratch('b', { failedKey: key });
  const olderOther = scratch('c', { failedKey: 'ship_job C:\\jobs\\three' });
  const notOwned = scratch('d', { owner: false, failedKey: key });
  const failed = scratch('e');
  let out = run(failed, 1, key);
  assert.match(out, /kept for a day after exit 1/);
  assert.equal(fs.readFileSync(path.join(failed, '.voidsworn-run-failed'), 'utf8'), key, 'the newest failure is marked with its job');
  assert(fs.existsSync(path.join(failed, 'tool', 'cache', 'big.bin')), 'the newest failure keeps its bytes');
  assert(!fs.existsSync(olderSame), 'an older failure of the same job goes');
  assert(fs.existsSync(olderOther), 'another job\'s failure stays');
  assert(fs.existsSync(notOwned), 'a folder without an ownership token is never touched');

  // The Board's PC pause removes nothing (Artoo on PR 1280): a paused PASS and a paused retry keep every folder.
  fs.writeFileSync(pauseFile, 'GPU not cleared: paused by the Board at 12:30\n');
  const pausedPass = scratch('7');
  assert.match(run(pausedPass, 0, 'ship_job C:\\jobs\\four'), /left for the janitor: .*PC pause is active/);
  assert(fs.existsSync(path.join(pausedPass, 'tool', 'cache', 'big.bin')), 'a paused PASS keeps its scratch');
  const pausedKey = 'ship_job C:\\jobs\\five';
  const pausedOlder = scratch('8', { failedKey: pausedKey });
  const pausedNew = scratch('6');
  assert.match(run(pausedNew, 1, pausedKey), /older failed scratch kept: .*PC pause is active/);
  assert(fs.existsSync(pausedOlder) && fs.existsSync(pausedNew), 'a paused retry removes no older failure');
  fs.writeFileSync(pauseFile, 'GPU cleared\n');
  assert.match(run(pausedPass, 0, 'ship_job C:\\jobs\\four'), /job scratch removed after PASS/);
  assert(!fs.existsSync(pausedPass), 'after the pause the next pass removes it');

  // A held run marker (tools still running) keeps the folder.
  const busy = scratch('f');
  const marker = path.join(busy, '.voidsworn-run-active');
  fs.writeFileSync(marker, '');
  const holder = spawn(shell, ['-NoProfile', '-Command',
    `$h = [IO.File]::Open('${marker}', 'Open', 'ReadWrite', 'None'); [Console]::Out.WriteLine('held'); Start-Sleep -Seconds 20; $h.Dispose()`]);
  (async () => {
    await new Promise(resolve => holder.stdout.on('data', d => { if (String(d).includes('held')) resolve(); }));
    out = run(busy, 0, 'look_bench C:\\bench');
    assert.match(out, /left for the janitor: .*its tools are still running/);
    assert(fs.existsSync(busy), 'a scratch whose tools still run is kept');
    holder.kill();
    // Outside the base TEMP or a wrong name: left for the janitor.
    const stray = path.join(outside, `voidsworn-run-${hex('9')}`);
    fs.mkdirSync(stray); fs.writeFileSync(path.join(stray, '.voidsworn-run-owner'), hex('9'));
    assert.match(run(stray, 0, 'x'), /not an owned voidsworn-run folder under/);
    assert(fs.existsSync(stray));
    console.log('PASS scratch_done: PASS removes the owned scratch without following links, FAILED keeps the newest per job, never touches unowned, busy or outside folders');
  })().catch(e => { console.error(e); process.exitCode = 1; holder.kill(); })
    .finally(() => { fs.rmSync(base, { recursive: true, force: true }); fs.rmSync(outside, { recursive: true, force: true }); });
} catch (e) {
  fs.rmSync(base, { recursive: true, force: true }); fs.rmSync(outside, { recursive: true, force: true });
  throw e;
}
