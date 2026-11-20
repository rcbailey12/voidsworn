'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const script = fs.readFileSync(path.join(__dirname, 'lane_tools_refresh.ps1'), 'utf8');

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
assert.match(live, /\[IO\.File\]::Replace\(\$temp, \$pointer, \$null\)/, 'current.txt flips in one rename');
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

console.log('PASS: lane tools refresh keeps old tools, refuses busy lanes, rotates old copies safely and installs tools_live');
