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

console.log('PASS: lane tools refresh keeps old tools, refuses busy lanes, rotates old copies safely and installs tools_live');
