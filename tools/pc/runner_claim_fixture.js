'use strict';
// Shared fake REST service for the real runner helpers and Windows entry-point self-tests. No live network.
const fs = require('fs');
const path = require('path');
module.exports = function fixture(root) {
  const fake = path.join(root, 'fake gh.ps1');
  fs.writeFileSync(fake, `
$ErrorActionPreference = 'Stop'
$words = @($args)
if ($words[0] -ne 'api') { throw 'Only gh api REST is allowed' }
$method = $words[2]; $endpoint = $words[3]
$payload = $null
if ($words -contains '--input') { $payload = Get-Content -LiteralPath $words[([array]::IndexOf($words, '--input') + 1)] -Raw | ConvertFrom-Json }
$call = @{ words = $words; method = $method; endpoint = $endpoint; payload = $payload }
Add-Content -LiteralPath $env:PC_TEST_GH_TRACE -Value ($call | ConvertTo-Json -Depth 12 -Compress)
if ($env:PC_TEST_GH_FAIL -eq '*' -or $env:PC_TEST_GH_FAIL -eq $method -or $env:PC_TEST_GH_FAIL -eq "$method $endpoint") { Write-Output 'fake gh failure'; exit 55 }
$db = Get-Content -LiteralPath $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json
if ($endpoint -match '/issues/[0-9]+$' -and $method -eq 'GET') {
  $db.issue.labels = if ($db.running) { @(@{ name = 'running' }) } else { @() }
  $db.issue | ConvertTo-Json -Depth 12 -Compress
} elseif ($endpoint -match '/(pulls|branches|issues)\\?') {
  if (-not ($words -contains '--paginate') -or -not ($words -contains '--slurp')) { throw 'Must read every page' }
  $items = if ($endpoint -match '/pulls\\?') { @($db.pulls) } elseif ($endpoint -match '/branches\\?') { @($db.branches) } else { @($db.issues) }
  Write-Output ('[[],' + (ConvertTo-Json -InputObject @($items) -Depth 12 -Compress) + ']')
} elseif ($endpoint -match '/compare/main\\.\\.\\.([0-9a-f]{40,64})$' -and $method -eq 'GET') {
  $answer = $db.comparisons.PSObject.Properties[$Matches[1]]
  if (-not $answer) { throw 'No compare answer for branch tip' }
  ConvertTo-Json -InputObject $answer.Value -Depth 12 -Compress
} elseif ($endpoint -match '/labels/running$' -and $method -eq 'GET') {
  if (-not $db.label) { Write-Output 'label missing'; exit 1 }
  Write-Output '{}'
} elseif ($endpoint -match '/issues/[0-9]+/labels$' -and $method -eq 'POST') {
  if ($env:PC_TEST_GH_DROP -ne 'label') { $db.running = $true }; Write-Output '{}'
} elseif ($endpoint -match '/labels$' -and $method -eq 'POST') {
  $db.label = $true; Write-Output '{}'
} elseif ($endpoint -match '/labels/running$' -and $method -eq 'DELETE') {
  $db.running = $false; Write-Output '{}'
} elseif ($endpoint -match '/comments\\?') {
  if (-not ($words -contains '--paginate') -or -not ($words -contains '--slurp')) { throw 'Must find status beyond the first page' }
  Write-Output ('[[{"id":1,"body":"unrelated"}],' + (ConvertTo-Json -InputObject @($db.comments) -Depth 12 -Compress) + ']')
} elseif ($endpoint -match '/comments$' -and $method -eq 'POST') {
  $id = 77 + @($db.comments).Count
  $comment = @{ id = $id; body = $(if ($env:PC_TEST_GH_DROP -eq 'comment') { 'wrong body' } else { $payload.body }) }
  $db.comments = @($db.comments) + @($comment)
  $comment | ConvertTo-Json -Compress
} elseif ($endpoint -match '/issues/comments/([0-9]+)$') {
  $id = [int]$Matches[1]
  $comment = @($db.comments | Where-Object { $_.id -eq $id })[0]
  if (-not $comment) { throw 'Unknown comment' }
  if ($method -eq 'PATCH' -and $env:PC_TEST_GH_HOLD_FINISH -and $payload.body -notmatch 'Runner status: running') {
    $hold = $env:PC_TEST_GH_HOLD_FINISH
    [IO.File]::WriteAllText("$hold.ready", 'final comment waiting')
    $deadline = [DateTime]::UtcNow.AddSeconds(45)
    while (-not (Test-Path -LiteralPath "$hold.release")) {
      if ([DateTime]::UtcNow -ge $deadline) { throw 'fixture final comment was not released' }
      Start-Sleep -Milliseconds 25
    }
  }
  if ($method -eq 'PATCH') { $comment.body = $payload.body }
  $comment | ConvertTo-Json -Compress
} else { throw "Unexpected REST call: $method $endpoint" }
[IO.File]::WriteAllText($env:PC_TEST_GH_DB, ($db | ConvertTo-Json -Depth 12))
exit 0
`);
  return { fake, database(number, sha = '', extra = {}) {
    return { label: false, running: false, comments: [], pulls: [], comparisons: {}, branches: [{ name: 'main', commit: { sha } }],
      issue: { number, title: 'Stub runner job', state: 'open', labels: [],
        body: `Owner: codex\nBrief: below\nDeliver to: tools/pc/\nBranch: codex/issue-${number}\nEffort (Codex): high\nDone when: stub finishes\n\n## THIS IS THE JOB NOW\nFinish the current fixture job.\n\n## Earlier run (DONE)\nOLD BRIEF MUST NOT REACH AGENT\n` }, ...extra };
  } };
};
