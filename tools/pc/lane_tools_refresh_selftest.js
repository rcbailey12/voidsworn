'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// The PC checks .ps1 files out with CRLF; read them as LF so the patterns hold on both.
const script = fs.readFileSync(path.join(__dirname, 'lane_tools_refresh.ps1'), 'utf8').replace(/\r\n/g, '\n');

assert.doesNotMatch(script, /\/(?:mir|purge|mov|move)\b/i, 'robocopy must keep destination files');
assert.doesNotMatch(script, /\bStop-Process\b|\[(?:IO\.)?(?:File|Directory)\]::Delete\b/i, 'refresh leaves processes alone');
// Issue 1194: the only deletes are the two rotations, each behind its keep rules.
const removes = [...script.matchAll(/Remove-Item\b[^\n]*/g)];
assert.equal(removes.length, 2, 'exactly two Remove-Item lines (old backups, old tools_live versions)');
const fnOf = index => (script.slice(0, index).match(/^function ([\w-]+)/gm) || []).pop();
assert.deepEqual(removes.map(m => fnOf(m.index)).sort(), ['function Remove-OldBackups', 'function Remove-OldLiveVersions']);
const backups = script.slice(script.indexOf('function Remove-OldBackups'), script.indexOf('function Copy-Tools'));
assert.match(backups, /if \(\$all\.Count -le \$keepBackups\) \{ return \}/, 'keep the newest backups');
assert.match(backups, /Test-KeptElsewhere[\s\S]*?if \(\$unique\) \{[\s\S]*?continue[\s\S]*?Remove-Item/, 'an old backup with a unique file is kept');
const versions = script.slice(script.indexOf('function Remove-OldLiveVersions'), script.indexOf('function Get-FileKeys'));
assert.match(versions, /if \(\$null -eq \$commands\) \{[^\n]*return \}/, 'unknown processes keep every version');
assert.match(versions, /TotalHours -lt 24\) \{ continue \}/, 'a version replaced within a day stays');
assert.match(versions, /IndexOf\(\$old\.FullName[\s\S]*?continue[\s\S]*?Remove-Item/, 'a version a running process names stays');
assert.match(versions, /if \(\$old\.Name -eq \$Current\) \{ continue \}/, 'the current version stays');
assert.doesNotMatch(script, /three dated backups/, 'a fourth backup no longer stops the refresh');
assert.match(script, /'work217', 'build', 'tools_live'\)\]/, 'build and tools_live are refreshable');
assert.match(script, /if \(\$seat -eq 'build'\) \{[\s\S]*?queue\\running[\s\S]*?throw "refused: a queue job is still running/, 'build refuses while a queue job runs');
const live = script.slice(script.indexOf("if ($seat -eq 'tools_live') {\n    $null = [IO.Directory]::CreateDirectory($liveRoot)"));
assert.match(live, /Test-ToolsMatch \$staged \$snapshot \$sourceFiles[\s\S]*?Write-Hashes \$staged[\s\S]*?\[IO\.Directory\]::Move\(\$staged, \$target\)/, 'tools_live installs a verified, hashed copy in one move');
assert.match(live, /Switch-LivePointer \(Join-Path \$liveRoot 'current\.txt'\) \$version/, 'current.txt flips through Switch-LivePointer');
// Issue 1180 (Nov 20 install): PowerShell passes $null to a .NET string parameter as "", which File.Replace rejects, so a
// second install (current.txt already there) threw. The backup argument must be a real null.
assert.doesNotMatch(script, /::Replace\([^)\n]*\$null\)/, 'File.Replace never gets $null as its backup path');
assert.match(script, /\[IO\.File\]::Replace\(\$temp, \$Pointer, \[NullString\]::Value\)/, 'current.txt flips in one rename with no backup');
assert.match(live, /\[IO\.Directory\]::Move\(\$target, \$aside\)/, 'an incomplete version is set aside, not deleted');
assert.doesNotMatch(live.slice(0, live.indexOf('exit 0')), /Copy-Tools \$liveTools|Move\(\$liveTools/, 'tools_live never edits a version in place');
assert.match(script, /fetch origin\/main[^\n]+--depth=1/, 'fetch main into a shallow source');
assert.match(script, /\$state\.status -eq 'running'\) \{ throw "refused: job still running/, 'refuse a running job');
assert.match(script, /work217\b[\s\S]*?Join-Path \$run\.FullName 'out\\status\.json'/, 'check workhorse run status');
assert.match(script, /runner_backups/);
assert.match(script, /yyyyMMdd_HHmmss/);

const steps = [
  /^  Assert-IdleLane$/m,
  /^  Copy-Tools \$liveTools \$staged /m,
  /^  Copy-Tools \$snapshot \$staged /m,
  /^  Assert-IdleLane$/m,
  /^  \[IO\.Directory\]::Move\(\$liveTools, \$original\)$/m,
  /^    \[IO\.Directory\]::Move\(\$staged, \$liveTools\)$/m,
  /^    Write-Step "installed origin\/main \$commit"$/m,
  /^      \[IO\.Directory\]::Move\(\$original, \$liveTools\)$/m,
];
let remaining = script;
for (const step of steps) {
  const match = step.exec(remaining);
  assert.ok(match, `missing or out-of-order refresh step ${step}`);
  remaining = remaining.slice(match.index + match[0].length);
}
assert.doesNotMatch(script, /Copy-Tools \$snapshot \$liveTools\b/, 'stage the overlay before touching live tools');
assert.match(script, /robocopy\.exe[^\n]+\/E[^\n]+\n\s+if \(\$LASTEXITCODE -lt 0 -or \$LASTEXITCODE -ge 8\) \{ throw/);
assert.match(script, /Write-Step \$message[^\n]+\n  exit 1/);

// Live: run the pointer switch itself in PowerShell, first with no current.txt (move), then over an existing one (replace).
{
  const os = require('node:os');
  const { spawnSync } = require('node:child_process');
  const shell = process.platform === 'win32' ? 'powershell.exe' : 'pwsh';
  if (spawnSync(shell, ['-NoProfile', '-Command', 'exit 0']).error) {
    if (process.env.CI) throw new Error(`${shell} is required in CI for the current.txt switch fixture`);
    console.log(`SKIP current.txt switch fixture: no ${shell} here (CI runs it)`);
  } else {
    const fn = /^function Switch-LivePointer[\s\S]*?^\}$/m.exec(script);
    assert.ok(fn, 'Switch-LivePointer is defined');
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'live-pointer-'));
    try {
      const pointer = path.join(dir, 'current.txt');
      const flip = version => {
        const r = spawnSync(shell, ['-NoProfile', '-Command', `${fn[0]}\nWrite-Output (Switch-LivePointer $env:FIX_POINTER $env:FIX_VERSION)`],
          { encoding: 'utf8', env: { ...process.env, FIX_POINTER: pointer, FIX_VERSION: version }, timeout: 60000 });
        assert.equal(r.status, 0, r.stdout + r.stderr);
        return r.stdout.trim();
      };
      assert.equal(flip('aaaaaaaaaaaa'), '', 'first install: no previous version');
      assert.equal(fs.readFileSync(pointer, 'utf8'), 'aaaaaaaaaaaa\r\n');
      assert.equal(flip('bbbbbbbbbbbb'), 'aaaaaaaaaaaa', 'second install replaces an existing current.txt');
      assert.equal(fs.readFileSync(pointer, 'utf8'), 'bbbbbbbbbbbb\r\n');
      assert.equal(flip('bbbbbbbbbbbb'), 'bbbbbbbbbbbb', 'same version: unchanged');
      assert.deepEqual(fs.readdirSync(dir), ['current.txt'], 'no .tmp or backup file is left behind');
    } finally { fs.rmSync(dir, { recursive: true, force: true }); }
  }
}

// Issue 1186 (Artoo on PR 1334): the refresh takes every arm's slot lock, even for a slot that does not exist yet, so a
// first launch of a fresh arm during a paused refresh is refused before it starts.
assert.match(script, /if \(\$seat -eq 'work217'\) \{ \$checkoutLock = @\(Lock-WorkhorseSlots /, 'the work217 refresh holds every slot lock');
{
  const os = require('node:os');
  const { spawn, spawnSync } = require('node:child_process');
  const shell = process.platform === 'win32' ? 'powershell.exe' : 'pwsh';
  if (spawnSync(shell, ['-NoProfile', '-Command', 'exit 0']).error) {
    if (process.env.CI) throw new Error(`${shell} is required in CI for the first-launch slot fixture`);
    console.log(`SKIP first-launch slot fixture: no ${shell} here (CI runs it)`);
  } else {
    const fn = /^function Lock-WorkhorseSlots[\s\S]*?^\}$/m.exec(script);
    assert.ok(fn, 'Lock-WorkhorseSlots is defined');
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'slot-refresh-'));
    const workRoot = path.join(dir, 'work217');
    const ready = path.join(dir, 'ready'), release = path.join(dir, 'release'), done = path.join(dir, 'done');
    const sleep = ms => Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
    const until = (test, ms) => { const end = Date.now() + ms; while (!test() && Date.now() < end) sleep(50); return test(); };
    const launch = () => spawnSync(shell, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(__dirname, 'work_issue.ps1'),
      'run', '687', 'deepseek', 'dryrun', path.join(workRoot, 'slot_deepseek', 'repo')], { encoding: 'utf8', timeout: 60000 });
    let refresh;
    try {
      assert.ok(!fs.existsSync(workRoot), 'the slot folder does not exist when the refresh starts');
      refresh = spawn(shell, ['-NoProfile', '-Command', `${fn[0]}\n$h = @(Lock-WorkhorseSlots $env:FIX_ROOT)\n` +
        `[IO.File]::WriteAllText($env:FIX_READY, [string]$h.Count)\n` +
        `$end = [DateTime]::UtcNow.AddSeconds(60); while (-not (Test-Path -LiteralPath $env:FIX_RELEASE) -and [DateTime]::UtcNow -lt $end) { Start-Sleep -Milliseconds 50 }\n` +
        `foreach ($x in $h) { $x.Dispose() }\n[IO.File]::WriteAllText($env:FIX_DONE, 'released')`], { env: { ...process.env, FIX_ROOT: workRoot, FIX_READY: ready, FIX_RELEASE: release, FIX_DONE: done }, stdio: 'ignore' });
      assert.ok(until(() => fs.existsSync(ready), 30000), 'paused refresh never took the slot locks');
      assert.equal(fs.readFileSync(ready, 'utf8'), '14', 'seven arms, live and dry run');
      const first = launch();
      assert.equal(first.status, 14, first.stdout + first.stderr);
      assert.match(first.stdout, /workhorse slot busy/, 'a first launch during the refresh is refused');
      fs.writeFileSync(release, 'go');
      assert.ok(until(() => fs.existsSync(done), 30000), 'paused refresh did not release its locks');
      if (process.platform !== 'win32') {
        // Off Windows there is no cmd to start, so a free slot gets past the lock and stops at the batch launch.
        const after = launch();
        assert.doesNotMatch(after.stdout, /workhorse slot busy/, 'the slot is free once the refresh ends: ' + after.stdout);
      }
    } finally {
      fs.writeFileSync(release, 'go');
      if (refresh) refresh.kill();
      fs.rmSync(dir, { recursive: true, force: true });
    }
  }
}

console.log('PASS: lane tools refresh keeps old tools, refuses busy lanes, rotates old copies safely and installs tools_live');
