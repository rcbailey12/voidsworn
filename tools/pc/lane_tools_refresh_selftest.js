'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const script = fs.readFileSync(path.join(__dirname, 'lane_tools_refresh.ps1'), 'utf8');

assert.doesNotMatch(script, /\/(?:mir|purge|mov|move)\b/i, 'robocopy must keep destination files');
assert.doesNotMatch(script, /\b(?:Remove-Item|Stop-Process)\b|\[(?:IO\.)?(?:File|Directory)\]::Delete\b/i,
  'refresh must keep files and leave processes alone');
assert.match(script, /fetch origin\/main[^\n]+--depth=1/, 'fetch main into a shallow source');
assert.match(script, /\$state\.status -eq 'running'\) \{ throw "refused: job still running/, 'refuse a running job');
assert.match(script, /work217\b[\s\S]*?Join-Path \$run\.FullName 'out\\status\.json'/, 'check workhorse run status');
assert.match(script, /\$backups\.Count -ge 3\) \{ throw/, 'refuse a fourth backup');
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

console.log('PASS: lane tools refresh keeps old tools, refuses busy lanes and caps dated backups');
