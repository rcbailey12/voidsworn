'use strict';
// Issue 846: run the real shared PowerShell steps with fake gh and tiny Git repos.
// Windows PowerShell 5.1 locally, pwsh on Linux (included on the GitHub Ubuntu runner).
// Fixture commits are objects written into TEMP, never commits in this checkout. No live GitHub or model calls.
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');
const zlib = require('zlib');
const { spawnSync } = require('child_process');
const pc = path.resolve(__dirname, '../../../tools/pc');
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'runner846 proof '));
const write = (p, s) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, s); };
const read = p => fs.readFileSync(p, 'utf8');
for (const name of ['codex_issue', 'work_issue']) {
  const bat = read(path.join(pc, name + '.bat'));
  const prep = read(path.join(pc, name + '.ps1'));
  assert(bat.includes('%COMMON% announce '));
  assert(bat.indexOf('%COMMON% announce ') < bat.indexOf('call "%T' + (name === 'codex_issue' ? 'P' : '') + '%tmo.bat"'));
  assert(prep.includes("'runner_common.ps1') base $repo $out $bodyFile"));
  assert(prep.includes('Do not run git merge'));
  assert(bat.includes('/c:"Base already merged"'), 'base-only work must reach the publisher');
}
const upstream = path.join(root, 'upstream.git');
let r = spawnSync('git', ['init', '--bare', '-q', upstream], { encoding: 'utf8', windowsHide: true });
assert.equal(r.status, 0, r.stderr);
function object(type, value) {
  const b = Buffer.isBuffer(value) ? value : Buffer.from(value);
  const raw = Buffer.concat([Buffer.from(type + ' ' + b.length + '\0'), b]);
  const id = crypto.createHash('sha1').update(raw).digest('hex');
  write(path.join(upstream, 'objects', id.slice(0, 2), id.slice(2)), zlib.deflateSync(raw));
  return id;
}
function commit(files, parent) {
  const tree = object('tree', Buffer.concat(Object.entries(files).sort(([a], [b]) => a.localeCompare(b)).map(([name, value]) =>
    Buffer.concat([Buffer.from('100644 ' + name + '\0'), Buffer.from(object('blob', value), 'hex')]))));
  return object('commit', `tree ${tree}\n${parent ? 'parent ' + parent + '\n' : ''}` +
    'author Fixture <fixture@example.invalid> 1700000000 +0000\ncommitter Fixture <fixture@example.invalid> 1700000000 +0000\n\nRunner fixture\n');
}
const ancestor = commit({ 'shared.txt': 'ancestor\n' });
const main = commit({ 'shared.txt': 'main\n' }, ancestor);
const clean = commit({ 'shared.txt': 'ancestor\n', 'base.txt': 'from base\n' }, ancestor);
const fast = commit({ 'shared.txt': 'main\n', 'fast.txt': 'fast\n' }, main);
const conflict = commit({ 'shared.txt': 'other\n' }, ancestor);
write(path.join(upstream, 'HEAD'), 'ref: refs/heads/main\n');
for (const [name, id] of Object.entries({ main, 'work/issue-800': clean, fast, conflict })) {
  write(path.join(upstream, 'refs/heads', name), id + '\n');
}
write(path.join(root, 'fake gh.ps1'), `
$ErrorActionPreference = 'Stop'
$words = @($args)
if ($words[0] -ne 'api') { throw 'Only gh api REST is allowed' }
$method = $words[2]; $endpoint = $words[3]
$payload = $null
if ($words -contains '--input') { $payload = Get-Content -LiteralPath $words[([array]::IndexOf($words, '--input') + 1)] -Raw | ConvertFrom-Json }
$call = @{ words = $words; method = $method; endpoint = $endpoint; payload = $payload }
Add-Content -LiteralPath $env:PC_TEST_GH_TRACE -Value ($call | ConvertTo-Json -Depth 10 -Compress)
if ($env:PC_TEST_GH_FAIL -eq '*' -or $env:PC_TEST_GH_FAIL -eq $method) { Write-Output 'fake gh failure'; exit 55 }
$db = Get-Content -LiteralPath $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json
if ($endpoint -match '/labels/running$' -and $method -eq 'GET') {
  if (-not $db.label) { Write-Output 'label missing'; exit 1 }
  Write-Output '{}'
} elseif ($endpoint -match '/labels$' -and $method -eq 'POST') { $db.label = $true; Write-Output '{}' }
elseif ($endpoint -match '/comments\\?') {
  if (-not ($words -contains '--paginate') -or -not ($words -contains '--slurp')) { throw 'Must find status beyond the first page' }
  Write-Output ('[[{"id":1,"body":"unrelated"}],' + (ConvertTo-Json -InputObject @($db.comments) -Depth 8 -Compress) + ']')
} elseif ($endpoint -match '/comments$' -and $method -eq 'POST') {
  $db.comments = @($db.comments) + @(@{ id = 77; body = $payload.body })
  Write-Output '{"id":77}'
} elseif ($method -eq 'PATCH') {
  $db.comments[0].body = $payload.body; Write-Output '{}'
} else { Write-Output '{}' }
[IO.File]::WriteAllText($env:PC_TEST_GH_DB, ($db | ConvertTo-Json -Depth 10))
exit 0
`);
write(path.join(root, 'probes.ps1'), `
$ErrorActionPreference = 'Stop'
$pc = $args[0]; $root = $args[1]; $upstream = Join-Path $root 'upstream.git'
$common = Join-Path $pc 'runner_common.ps1'
$script:passed = 0
function Assert($ok, $why) { if (-not $ok) { throw $why } }
function Pass($name) { $script:passed++; Write-Output "PASS $name" }
function Put($p, $s) { [IO.File]::WriteAllText($p, $s) }
function Calls { return @(Get-Content -LiteralPath $env:PC_TEST_GH_TRACE | ForEach-Object { $_ | ConvertFrom-Json }) }
function Shared([object[]]$words) {
  & $common @words
  Assert ($LASTEXITCODE -eq 0) "common failed: $words"
}
function Init($name, $branch = 'codex/issue-846') {
  $script:out = Join-Path $root $name
  $null = New-Item -ItemType Directory -Path $out
  $env:PC_TEST_GH_TRACE = Join-Path $out 'gh.jsonl'; Put $env:PC_TEST_GH_TRACE ''
  $env:PC_TEST_GH_DB = Join-Path $out 'gh-db.json'; Put $env:PC_TEST_GH_DB '{"label":false,"comments":[]}'
  Shared @('init',$out,$branch)
}
function New-Repo($name) {
  $p = Join-Path $root $name
  & $script:git clone -q -c core.autocrlf=false --no-local $upstream $p
  Assert ($LASTEXITCODE -eq 0) 'clone fixture'
  & $script:git -C $p checkout -q -b codex/issue-846
  Assert ($LASTEXITCODE -eq 0) 'fixture branch'
  return $p
}
function Announce { Shared @('announce',$out,'846','codex',$repo,'21600','codex_issue.bat 846','real') }
function Base($body, $expected = 0) {
  $p = Join-Path $out 'body.txt'; Put $p $body
  & $common base $repo $out $p
  Assert ($LASTEXITCODE -eq $expected) "base exit expected $expected, got $LASTEXITCODE"
}
function Finish($code = '0', $partial = '') { Shared @('finish',$out,$code,$partial,'real','1') }
$script:git = 'git'; if ($PSVersionTable.Platform -ne 'Unix') { $script:git = 'git.exe' }
$repo = New-Repo 'repo'
Init 'normal'
Announce
$start = @(Calls | Where-Object { $_.endpoint -match '/comments$' })[0]
$text = $start.payload.body
foreach ($field in @('Seat: codex','Machine:','Lane folder:','Branch: codex/issue-846','Started (UTC):','Ceiling: 21600 seconds','Last commit:','How to resume: codex_issue.bat 846','Runner status: running')) { Assert ($text.Contains($field)) "missing $field" }
Assert ($text.Contains($repo)) 'lane folder value'
Assert ($text.Contains('${main}')) 'start commit value'
$calls = Calls
Assert (@($calls | Where-Object { $_.endpoint -eq 'repos/rcbailey12/voidsworn/labels' -and $_.payload.name -eq 'running' -and $_.payload.color -eq '1D76DB' }).Count -eq 1) 'label created'
Assert (@($calls | Where-Object { $_.endpoint -match '/issues/846/labels$' -and $_.payload.labels[0] -eq 'running' }).Count -eq 1) 'running applied'
Pass 'running REST label and status payload carry the real run context'
Put (Join-Path $out 'run_commit.txt') ('a' * 40); Put (Join-Path $out 'confirmed_commit.txt') ('a' * 40)
Finish
$calls = Calls; $end = @($calls | Where-Object { $_.method -eq 'PATCH' })[-1]
Assert ($end.endpoint -eq 'repos/rcbailey12/voidsworn/issues/comments/77') 'edit original id'
Assert ($end.payload.body.Contains('Runner status: finished') -and $end.payload.body.Contains(('a' * 40))) 'finished body'
Assert ($calls[-1].method -eq 'DELETE' -and $calls[-1].endpoint -match '/issues/846/labels/running$') 'running removed'
Assert (@($calls | Where-Object { $_.method -eq 'POST' -and $_.endpoint -match '/comments$' }).Count -eq 1) 'only one comment'
Pass 'checked finish edits the original comment and clears running'
Shared @('init',$out,'codex/issue-846')
Announce
Assert (@(Calls | Where-Object { $_.method -eq 'POST' -and $_.endpoint -match '/comments$' }).Count -eq 1) 'retry must reuse comment, even from another page'
Finish '0' 'STALLED after 30 min'
$end = @(Calls | Where-Object { $_.method -eq 'PATCH' })[-1]
Assert ($end.payload.body.Contains('Runner status: partial') -and $end.payload.body.Contains('Branch: codex/issue-846-partial') -and $end.payload.body.Contains('STALLED after 30 min')) 'partial branch and reason'
Pass 'retry reuses one paginated comment; partial names its branch and stop reason'
Init 'failed' 'work/issue-846-deepseek'; Announce; Finish '8'
$end = @(Calls | Where-Object { $_.method -eq 'PATCH' })[-1]
Assert ($end.payload.body.Contains('Runner status: failed') -and $end.payload.body.Contains('runner exit 8')) 'failed comment'
Pass 'failed publish still edits status and clears the label'
Init 'patch-failure'; Announce; $env:PC_TEST_GH_FAIL = 'PATCH'; Finish '0' 'CEILING'
Assert ((Calls)[-1].method -eq 'DELETE') 'label clear after failed comment edit'
Assert ((Get-Content (Join-Path $out 'status.json') -Raw | ConvertFrom-Json).status -eq 'partial') 'report failure cannot change run outcome'
Pass 'failed comment edit is logged and label removal still runs'
$env:PC_TEST_GH_FAIL = '*'; Init 'all-gh-failure'; Announce; Finish '8'
Assert ([IO.File]::ReadAllText((Join-Path $out 'result.txt')).Contains('WARNING: GitHub status')) 'gh failures logged'
Assert ((Calls)[-1].method -eq 'DELETE') 'clear attempted despite every API failing'
Pass 'all gh failures leave the run outcome intact'
$env:PC_TEST_GH_FAIL = ''; $fake = $env:PC_TEST_GH; $env:PC_TEST_GH = Join-Path $root 'missing-gh'
Init 'missing-gh'; Announce; Finish '8'
Pass 'missing gh is nonfatal'
$env:PC_TEST_GH = $fake; Init 'dry-run'; $env:PC_RUNNER_TEST = '0'
Shared @('announce',$out,'846','codex',$repo,'21600','codex_issue.bat 846','dry')
Assert ((Get-Item $env:PC_TEST_GH_TRACE).Length -eq 0) 'dry run must never contact GitHub'
$env:PC_RUNNER_TEST = '1'
Pass 'dry runs do not report to live GitHub'
Init 'base-clean'; Put (Join-Path $out 'resume.txt') 'Resumed by merging earlier partial.'
Put (Join-Path $out 'base_commit.txt') '${main}'
Base "Owner: codex\r\n  Base: work/issue-800  \r\nDone when: works"
$parents = (& $script:git -C $repo rev-list --parents -n 1 HEAD) -split ' '
Assert ($parents.Count -eq 3 -and $parents[1] -eq '${main}' -and $parents[2] -eq '${clean}') 'runner committed both merge parents'
Assert ([IO.File]::ReadAllText((Join-Path $repo 'base.txt')) -eq "from base\n") 'base content merged'
& $script:git -C $repo rev-parse -q --verify MERGE_HEAD
Assert ($LASTEXITCODE -ne 0) 'no unfinished merge reaches agent'
$resume = [IO.File]::ReadAllText((Join-Path $out 'resume.txt'))
Assert ($resume.Contains('Resumed by merging earlier partial.') -and $resume.Contains('Base already merged by the runner: origin/work/issue-800')) 'preserve partial context and add base note'
Pass 'Base parses CRLF and commits a real merge while preserving resume context'
# Prep is the production caller for both seats. Use the same already-merged base, no extra commit.
$env:PC_TEST_ISSUE = Join-Path $out 'issue.json'
Put $env:PC_TEST_ISSUE '{"title":"Fixture","body":"Base: work/issue-800"}'
foreach ($seat in @('codex','work')) {
  $helper = Join-Path $pc ($seat + '_issue.ps1')
  if ($seat -eq 'codex') { & $helper prep 846 $repo $out }
  else { & $helper prep 846 deepseek $repo $out 'godot' }
  Assert ($LASTEXITCODE -eq 0) "$seat prep"
  $task = [IO.File]::ReadAllText((Join-Path $repo ($seat.ToUpper() + '_TASK.md')))
  Assert ($task.Contains('Base already merged by the runner') -and $task.Contains('Do not run git merge')) "$seat prompt must say base is already in"
}
Pass 'both real prep helpers merge Base and tell the agent it is committed'
$repo = New-Repo 'fast-repo'; Init 'base-fast'; Base 'Base: fast'
$parents = (& $script:git -C $repo rev-list --parents -n 1 HEAD) -split ' '
Assert ($parents.Count -eq 3 -and $parents[2] -eq '${fast}') 'fast-forward base still gets runner merge commit'
Pass 'fast-forward Base also gets a committed merge'
$repo = New-Repo 'optional-repo'; Init 'base-optional'; Base 'Owner: codex'
Assert ((& $script:git -C $repo rev-parse HEAD) -eq '${main}') 'optional Base must be a no-op'
Base 'Base: bad branch' 14
Base "Base: fast\nBase: conflict" 14
Base 'Base: ' 14
Base 'Base: no-such-branch' 14
Assert ((& $script:git -C $repo rev-parse HEAD) -eq '${main}') 'bad bases cannot change checkout'
Pass 'Base is optional; invalid, duplicate, empty and missing branches stop before the agent'
$repo = New-Repo 'conflict-repo'; Init 'base-conflict'
Base 'Base: conflict' 14
$state = Get-Content (Join-Path $out 'status.json') -Raw | ConvertFrom-Json
Assert ($state.status -eq 'failed' -and $state.reason.Contains('no agent started')) 'clear conflict result'
Assert ([IO.File]::ReadAllText((Join-Path $repo 'shared.txt')).Contains('<<<<<<<')) 'conflict evidence kept'
Assert (-not (Test-Path (Join-Path $repo 'CODEX_TASK.md'))) 'no prompt generated on conflict'
Pass 'conflicting Base keeps evidence and fails before the agent'
Write-Output "PASS runner job checks ($script:passed groups)"
`);
const ps = process.platform === 'win32' ? 'powershell.exe' : 'pwsh';
r = spawnSync(ps, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(root, 'probes.ps1'), pc, root], {
  encoding: 'utf8', windowsHide: true, timeout: 90000,
  env: { ...process.env, PC_RUNNER_TEST: '1', PC_TEST_GH: path.join(root, 'fake gh.ps1'), PC_TEST_GH_FAIL: '',
    PC_TEST_GIT: '', PC_TEST_RETRY_SECONDS: '0',
    GIT_AUTHOR_NAME: 'Fixture', GIT_AUTHOR_EMAIL: 'fixture@example.invalid',
    GIT_COMMITTER_NAME: 'Fixture', GIT_COMMITTER_EMAIL: 'fixture@example.invalid' }
});
assert.equal(r.status, 0, (r.stdout || '') + (r.stderr || '') + String(r.error || '') + '\nEvidence: ' + root);
console.log(r.stdout.trim());
