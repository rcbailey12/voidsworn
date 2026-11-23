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
const { spawnSync, spawn } = require('child_process');
const pc = path.resolve(__dirname, '../../../tools/pc');
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'runner846 proof '));
const gh = require('../../../tools/pc/runner_claim_fixture')(root);
const write = (p, s) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, s); };
const read = p => fs.readFileSync(p, 'utf8');
for (const name of ['codex_issue', 'work_issue']) {
  const bat = read(path.join(pc, name + '.bat'));
  const prep = read(path.join(pc, name + '.ps1'));
  assert(bat.includes('%COMMON% announce '));
  assert(bat.indexOf('%COMMON% announce ') < bat.indexOf('%COMMON% checkout '), 'claim before checkout');
  assert(bat.indexOf('%COMMON% announce ') < bat.indexOf('%COMMON% preflight '), 'claim before any model call');
  assert(/%COMMON% announce [^\r\n]+\r?\nif errorlevel 1 exit \/b 14/.test(bat), 'claim failures must stop the runner');
  assert(prep.includes("'validated_issue.json'"), 'prep uses the validated snapshot');
  assert(!prep.includes('Invoke-RestMethod -UseBasicParsing -Headers'), 'prep cannot fetch a different brief');
  assert(bat.indexOf('%COMMON% announce ') < bat.indexOf('call "%T' + (name === 'codex_issue' ? 'P' : '') + '%tmo.bat"'));
  assert(prep.includes("'runner_common.ps1') base $repo $out $bodyFile"));
  assert(prep.includes('Do not run git merge'));
  const compareHead = bat.indexOf(' head-changed ');
  assert(compareHead >= 0 && compareHead < bat.indexOf('\n:haschange'), 'check for committed work before running checks');
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
  function treeFor(entries) {
    return object('tree', Buffer.concat(Object.entries(entries)
      .sort(([a, left], [b, right]) => Buffer.compare(Buffer.from(a + (typeof left === 'object' ? '/' : '')), Buffer.from(b + (typeof right === 'object' ? '/' : ''))))
      .map(([name, value]) => {
        const directory = typeof value === 'object';
        return Buffer.concat([Buffer.from((directory ? '40000 ' : '100644 ') + name + '\0'),
          Buffer.from(directory ? treeFor(value) : object('blob', value), 'hex')]);
      })));
  }
  const tree = treeFor({
    docs: { shots: { 'shot.png': 'picture' }, ship_pipeline: { build_sheets: { 'sheet.md': 'sheet' } } },
    contrib: { muse: { design: { 'draft.md': 'design' } } },
    hulls_hi: { 'hull.glb': 'hull' }, rocks_hi: { 'rock.glb': 'rock' },
    ...files
  });
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
write(path.join(root, 'gh-default.json'), JSON.stringify(gh.database(846, main)));
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
  $env:PC_TEST_GH_DB = Join-Path $out 'gh-db.json'; Put $env:PC_TEST_GH_DB ([IO.File]::ReadAllText((Join-Path $root 'gh-default.json')))
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
foreach ($field in @('Seat: codex','Lane: other','Branch: codex/issue-846','Started (UTC):','Ceiling: 21600 seconds','Last commit:','How to resume: codex_issue.bat 846','Runner status: running')) { Assert ($text.Contains($field)) "missing $field" }
Assert (-not $text.Contains($repo) -and -not $text.Contains([Environment]::MachineName) -and -not $text.Contains('Machine:')) 'issue 947: the public status comment carries no PC path or machine name'
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
Init 'failed'; Announce; Finish '8'
$end = @(Calls | Where-Object { $_.method -eq 'PATCH' })[-1]
Assert ($end.payload.body.Contains('Runner status: failed') -and $end.payload.body.Contains('runner exit 8')) 'failed comment'
Pass 'failed publish still edits status and clears the label'
Init 'failed-checks'; Announce
Put (Join-Path $out 'run_commit.txt') ('a' * 40); Put (Join-Path $out 'confirmed_commit.txt') ('a' * 40)
Shared @('finish',$out,'0','','real','0')
$end = @(Calls | Where-Object { $_.method -eq 'PATCH' })[-1]
Assert ($end.payload.body.Contains('Runner status: unverified') -and $end.payload.body.Contains('checks did not pass')) 'confirmed push with failed checks stays unverified publicly'
Assert ((Calls)[-1].method -eq 'DELETE') 'unverified finish still clears the running label'
Pass 'a zero-exit confirmed push with failed checks cannot report finished'
Init 'private-exception'; Announce
$secret = 'fake-secret-for-status-1100'
$privatePath = 'Z:/private runner/' + $secret
Base "Base: $privatePath" 14
$end = @(Calls | Where-Object { $_.method -eq 'PATCH' })[-1]
Assert ($end.payload.body.Contains('Runner status: failed') -and -not $end.payload.body.Contains($secret) -and -not $end.payload.body.Contains('Z:/')) 'public comment leaked a raw runner exception'
Assert ((Get-Content -LiteralPath (Join-Path $out 'result.txt') -Raw).Contains($privatePath)) 'the full exception should be available locally'
Pass 'public failed status hides exception paths and secrets and keeps the local diagnostic'
Init 'patch-failure'; Announce; $env:PC_TEST_GH_FAIL = 'PATCH'; Finish '0' 'CEILING'
Assert ((Calls)[-1].method -eq 'DELETE') 'label clear after failed comment edit'
Assert ((Get-Content (Join-Path $out 'status.json') -Raw | ConvertFrom-Json).status -eq 'partial') 'report failure cannot change run outcome'
Pass 'failed comment edit is logged and label removal still runs'
$env:PC_TEST_GH_FAIL = '*'; Init 'all-gh-failure'
& $common announce $out 846 codex $repo 21600 'codex_issue.bat 846' real
Assert ($LASTEXITCODE -eq 14) 'cannot start without validating and claiming'
Finish '8'
Assert ([IO.File]::ReadAllText((Join-Path $out 'result.txt')).Contains('WARNING: GitHub status')) 'gh failures logged'
Assert (@(Calls | Where-Object { $_.method -ne 'GET' }).Count -eq 0) 'a refused start cannot clear another claim'
Pass 'start fails closed on GitHub errors without modifying claims'
$env:PC_TEST_GH_FAIL = ''; $fake = $env:PC_TEST_GH; $env:PC_TEST_GH = Join-Path $root 'missing-gh'
Init 'missing-gh'
& $common announce $out 846 codex $repo 21600 'codex_issue.bat 846' real
Assert ($LASTEXITCODE -eq 14) 'missing gh refuses before work'
Pass 'missing gh fails closed at start'
$env:PC_TEST_GH = $fake; Init 'dry-run'
Shared @('announce',$out,'846','codex',$repo,'21600','codex_issue.bat 846','dry')
Assert (@(Calls).Count -gt 0) 'fixture dry run validates through fake gh'
Finish '8'
Pass 'test dry runs use the fake GitHub service'
Init 'real-dry-run'
# A local function stands in for gh while exercising the production (non-test) dry path. Still no live network.
function gh { & $env:PC_TEST_GH @args }
$env:PC_RUNNER_TEST = '0'
Shared @('announce',$out,'846','codex',$repo,'21600','codex_issue.bat 846','dry')
Assert (@(Calls | Where-Object { $_.method -ne 'GET' }).Count -eq 0) 'production dry run must remain read-only'
Assert (-not (Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json).running) 'production dry run cannot claim'
$env:PC_RUNNER_TEST = '1'
Remove-Item Function:\gh
Pass 'production dry runs validate the current brief without labels or comments'
# Issue 914: exercise production lookup with real executable files under fake install roots.
# The executable forwards only to the existing local REST fixture, never to GitHub.
$savedPath = $env:PATH; $savedProgramFiles = $env:ProgramFiles; $savedLocal = $env:LOCALAPPDATA
$lookup = Join-Path $root 'gh lookup'
$program = Join-Path $lookup 'Program Files'
$local = Join-Path $lookup 'Local App Data'
$onPath = Join-Path $lookup 'bin'
$empty = Join-Path $lookup 'empty'
foreach ($p in @($program,$local,$onPath,$empty)) { $null = New-Item -ItemType Directory -Path $p -Force }
$programGh = Join-Path $program 'GitHub CLI/gh.exe'
$localGh = Join-Path $local 'Programs/GitHub CLI/gh.exe'
$pathGh = Join-Path $onPath 'gh.exe'
foreach ($p in @($programGh,$localGh)) { $null = New-Item -ItemType Directory -Path (Split-Path -Parent $p) -Force }
if ($PSVersionTable.Platform -ne 'Unix') {
  # Use the installed Windows compiler even when this probe runs under pwsh, whose Add-Type cannot emit an exe.
  $source = Join-Path $lookup 'FakeGhLookup.cs'
  Put $source @'
using System;
using System.Diagnostics;
using System.IO;
using System.Text;
public class FakeGhLookup {
  static string Literal(string value) { return "'" + value.Replace("'", "''") + "'"; }
  public static int Main(string[] args) {
    string command = "& " + Literal(Environment.GetEnvironmentVariable("PC_TEST_GH"));
    foreach (string arg in args) command += " " + Literal(arg);
    command += "; exit $LASTEXITCODE";
    var start = new ProcessStartInfo(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),
      @"WindowsPowerShell\\v1.0\\powershell.exe"), "-NoProfile -ExecutionPolicy Bypass -EncodedCommand " +
      Convert.ToBase64String(Encoding.Unicode.GetBytes(command)));
    start.UseShellExecute = false; start.CreateNoWindow = true;
    start.RedirectStandardOutput = true; start.RedirectStandardError = true;
    using (var child = Process.Start(start)) {
      Console.Write(child.StandardOutput.ReadToEnd()); Console.Error.Write(child.StandardError.ReadToEnd());
      child.WaitForExit(); return child.ExitCode;
    }
  }
}
'@
  $compiler = Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
  $compileScript = Join-Path $lookup 'compile.ps1'
  Put $compileScript '$ErrorActionPreference = "Stop"; Add-Type -Path $args[0] -OutputAssembly $args[1] -OutputType ConsoleApplication'
  & $compiler -NoProfile -ExecutionPolicy Bypass -File $compileScript $source $pathGh
  Assert ($LASTEXITCODE -eq 0) 'compile Windows gh fixture'
} else {
  # Use this host's binary, without depending on a PATH launcher or tools outside the isolated fixture PATH.
  $pwsh = (Get-Process -Id $PID).Path
  Put $pathGh ("#!/bin/sh" + [char]10 + 'exec "' + $pwsh + '" -NoProfile -File "$PC_TEST_GH" "$@"' + [char]10)
  # Get-Command gh resolves the extensionless executable on Unix.
  $unixGh = Join-Path $onPath 'gh'
  Copy-Item -LiteralPath $pathGh -Destination $unixGh
}
Copy-Item -LiteralPath $pathGh -Destination $programGh
Copy-Item -LiteralPath $pathGh -Destination $localGh
if ($PSVersionTable.Platform -eq 'Unix') {
  # Copies must themselves be executable, including the Windows-named install-folder fixtures.
  foreach ($p in @($unixGh,$pathGh,$programGh,$localGh)) {
    & chmod +x $p
    Assert ($LASTEXITCODE -eq 0) "make gh fixture executable: $p"
    Assert ([bool](Get-Command $p -CommandType Application -ErrorAction SilentlyContinue)) "resolve gh fixture: $p"
  }
}
function Invoke-RestMethod { throw 'lookup fixture must use fake gh, never public REST' }
try {
  foreach ($case in @('path','program','local','missing')) {
    Init ('gh-lookup-' + $case)
    $env:ProgramFiles = if ($case -in @('path','program')) { $program } else { $empty }
    $env:LOCALAPPDATA = $local
    if ($case -eq 'missing') { $env:LOCALAPPDATA = $empty }
    $env:PATH = if ($case -eq 'path') { $onPath } else { $empty }
    Assert ([bool](Get-Command gh -ErrorAction SilentlyContinue) -eq ($case -eq 'path')) 'fixture PATH contains gh only for the PATH case'
    $env:PC_RUNNER_TEST = '0'
    & $common announce $out 846 codex $repo 21600 'resume' dry
    $code = $LASTEXITCODE
    $env:PC_RUNNER_TEST = '1'
    $log = [IO.File]::ReadAllText((Join-Path $out 'result.txt'))
    if ($case -eq 'missing') {
      Assert ($code -eq 14) 'no executable still refuses before work'
      Assert ($log.Contains('GitHub CLI gh is missing; install it and run gh auth login before starting PC jobs')) 'same missing gh message'
      Assert (@(Calls).Count -eq 0) 'missing gh cannot call GitHub'
    } else {
      Assert ($code -eq 0) "production lookup failed: $case (exit $code): $log"
      $selected = if ($case -eq 'program') { $programGh } elseif ($case -eq 'local') { $localGh } else { (Get-Command gh).Source }
      Assert ($log.Contains("GitHub CLI: $selected")) "log the selected $case executable"
      Assert (@(Calls).Count -gt 0) 'selected executable actually ran the REST fixture'
      Assert (@(Calls | Where-Object { $_.method -ne 'GET' }).Count -eq 0) 'production dry lookup remains read-only'
    }
    Pass ("production gh lookup: " + $case)
  }
  Init 'gh-lookup-board'
  $db = Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json
  $db | Add-Member -NotePropertyName issues -NotePropertyValue @()
  Put $env:PC_TEST_GH_DB ($db | ConvertTo-Json -Depth 12)
  $env:ProgramFiles = $program; $env:LOCALAPPDATA = $local; $env:PATH = $empty
  $env:PC_RUNNER_TEST = '0'
  Shared @('board-dryrun',$out)
  $log = [IO.File]::ReadAllText((Join-Path $out 'result.txt'))
  Assert ($log.Contains("GitHub CLI: $programGh") -and -not $log.Contains('gh is missing')) 'board audit finds the install without a false missing-tool warning'
  Assert (@(Calls).Count -eq 3 -and @(Calls | Where-Object { $_.method -ne 'GET' }).Count -eq 0) 'board fallback uses only the fake gh GETs'
  Pass 'board dry run uses the same install-folder fallback'
} finally {
  $env:PATH = $savedPath; $env:ProgramFiles = $savedProgramFiles; $env:LOCALAPPDATA = $savedLocal
  $env:PC_RUNNER_TEST = '1'
  Remove-Item Function:\\Invoke-RestMethod
}
# The job checks exercise the shared start contract on every CI host; runner_selftest also drives real Windows .bat files.
foreach ($case in @('closed','running','pr','linked-pr','branch','other-partial','missing','duplicate','empty','run-label-only','run-label-before-history','missing-field','missing-effort','quoted-marker','two-fixed','earlier-run','old-numbered-run')) {
  Init ("refuse-" + $case)
  $db = Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json
  switch ($case) {
    'closed' { $db.issue.state = 'closed' }
    'running' { $db.running = $true }
    'pr' { $db.pulls = @(@{ number = 999; head = @{ ref = 'work/issue-846-deepseek' } }) }
    'linked-pr' { $db.pulls = @(@{ number = 999; title = 'Other branch'; body = 'Refs #846'; head = @{ ref = 'review/another-seat' } }) }
    'branch' { $db.branches += @(@{ name = 'opus/issue-846' }) }
    'other-partial' { $db.branches += @(@{ name = 'work/issue-846-deepseek-partial' }) }
    'missing' { $db.issue.body = $db.issue.body.Replace('THIS IS THE JOB NOW','An old brief') }
    'duplicate' { $db.issue.body += "\n## Run 2 (THIS IS THE JOB NOW)\nSecond brief" }
    'empty' { $db.issue.body = $db.issue.body.Substring(0, $db.issue.body.IndexOf('Finish the current fixture job.')) }
    'run-label-only' {
      $db.issue.body = $db.issue.body.Substring(0, $db.issue.body.IndexOf('Finish the current fixture job.')).Replace(
        '## THIS IS THE JOB NOW', '## THIS IS THE JOB NOW (run 2, Board, Nov 17)')
    }
    'run-label-before-history' {
      $db.issue.body = $db.issue.body.Replace('## THIS IS THE JOB NOW', '## THIS IS THE JOB NOW (run 2, Board, Nov 17)').Replace(
        "Finish the current fixture job.\n\n## Earlier run (DONE)", '## Run 1 (Board, Nov 16): DONE')
    }
    'missing-field' { $db.issue.body = $db.issue.body.Replace('Brief: below','') }
    'missing-effort' { $db.issue.body = $db.issue.body.Replace("Effort (Codex): high\n",'') }
    'quoted-marker' { $db.issue.body += "\n> THIS IS THE JOB NOW\n" }
    'two-fixed' {
      $fixed = $db.issue.body.Substring(0, $db.issue.body.IndexOf("\n\n## THIS IS THE JOB NOW"))
      $db.issue.body = $fixed + "\n\n" + $fixed + "\n\nAmbiguous job."
    }
    'earlier-run' {
      $db.issue.body = $db.issue.body.Substring(0, $db.issue.body.IndexOf("\n\n## THIS IS THE JOB NOW")) + "\n\n## Earlier-run notes\nAmbiguous job."
    }
    'old-numbered-run' {
      $db.issue.body = $db.issue.body.Substring(0, $db.issue.body.IndexOf("\n\n## THIS IS THE JOB NOW")) + "\n\n**Run 1 (DONE)**\nAn old brief."
    }
  }
  Put $env:PC_TEST_GH_DB ($db | ConvertTo-Json -Depth 12)
  & $common announce $out 846 codex $repo 21600 'codex_issue.bat 846' real
  Assert ($LASTEXITCODE -eq 14) "must refuse $case"
  $s = Get-Content (Join-Path $out 'status.json') -Raw | ConvertFrom-Json
  Assert ($s.status -eq 'failed' -and $s.reason.Contains('no agent started')) "clear refusal $case"
  if ($case -like 'run-label-*') { Assert ($s.reason.Contains('current instruction refused: the current block is empty')) 'a run label is not instruction content' }
  Finish '14'
  Assert (@(Calls | Where-Object { $_.method -ne 'GET' }).Count -eq 0) "refusal cannot mutate GitHub: $case"
  Pass ("job refused without writes: " + $case)
}
# Issue 969: compare the other seat's tip to main, not a branch name that could move.
foreach ($status in @('behind','identical','ahead','diverged','unknown','missing','read-failure','open-pr','mixed')) {
  Init ('other-seat-compare-' + $status)
  $db = Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json
  $oldBranch = 'opus/issue-846-docs'
  $tip = if ($status -eq 'identical') { '${main}' } elseif ($status -eq 'ahead') { '${fast}' } elseif ($status -eq 'diverged') { '${conflict}' } else { '${ancestor}' }
  $db.branches += @(@{ name = $oldBranch; commit = @{ sha = $tip } })
  $answer = if ($status -eq 'missing') { @{} } elseif ($status -in @('read-failure','open-pr','mixed')) { @{ status = 'behind' } } else { @{ status = $status } }
  $db.comparisons | Add-Member -NotePropertyName $tip -NotePropertyValue $answer
  if ($status -eq 'identical') {
    $db.branches[-1].name = 'muse/issue-846'
    $oldBranch = $db.branches[-1].name
  }
  if ($status -eq 'mixed') {
    $db.branches += @(@{ name = 'work/issue-846-deepseek'; commit = @{ sha = '${fast}' } })
    $db.comparisons | Add-Member -NotePropertyName '${fast}' -NotePropertyValue @{ status = 'ahead' }
  }
  if ($status -eq 'open-pr') { $db.pulls = @(@{ number = 999; head = @{ ref = $oldBranch } }) }
  Put $env:PC_TEST_GH_DB ($db | ConvertTo-Json -Depth 12)
  $endpoint = "repos/rcbailey12/voidsworn/compare/main...$tip"
  if ($status -eq 'read-failure') { $env:PC_TEST_GH_FAIL = "GET $endpoint" }
  & $common announce $out 846 codex $repo 21600 'codex_issue.bat 846' real
  $code = $LASTEXITCODE; $env:PC_TEST_GH_FAIL = ''
  $log = [IO.File]::ReadAllText((Join-Path $out 'result.txt'))
  $comparisons = @(Calls | Where-Object { $_.endpoint -match '/compare/' })
  if ($status -in @('behind','identical')) {
    Assert ($code -eq 0) "finished other-seat branch must allow a job: $status"
    Assert ($log.Contains("finished work: delivery branch $oldBranch tip $tip is already in main ($status)")) 'log names finished branch'
    Assert ((Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json).running) 'accepted job acquires claim'
    Finish '8'
  } else {
    Assert ($code -eq 14) "unverified or active other-seat work must block: $status"
    $s = Get-Content (Join-Path $out 'status.json') -Raw | ConvertFrom-Json
    Assert ($s.status -eq 'failed' -and $s.reason.Contains('no agent started')) 'clear refusal before work'
    if ($status -eq 'read-failure') {
      Assert ($s.reason.Contains("GET compare/main...$tip failed")) 'compare failure names unreadable REST endpoint'
    } elseif ($status -eq 'open-pr') {
      Assert ($s.reason.Contains("open PR #999 from other seat $oldBranch")) 'open PR still blocks even with a finished tip'
    } else {
      $blocked = if ($status -eq 'mixed') { 'work/issue-846-deepseek' } else { $oldBranch }
      Assert ($s.reason.Contains("delivery branch $blocked from another seat exists")) 'active or unknown compare answer keeps branch refusal'
    }
    Assert (@(Calls | Where-Object { $_.method -ne 'GET' }).Count -eq 0) 'branch or compare refusal cannot mutate GitHub'
  }
  if ($status -eq 'open-pr') {
    Assert ($comparisons.Count -eq 0) 'open PR blocks before branch comparison'
  } else {
    $count = if ($status -eq 'mixed') { 2 } else { 1 }
    Assert ($comparisons.Count -eq $count -and $comparisons[0].method -eq 'GET' -and $comparisons[0].endpoint -eq $endpoint) 'REST compare uses main and branch tip SHA'
  }
  Pass ("other-seat branch comparison: " + $status)
}
foreach ($endpoint in @('GET repos/rcbailey12/voidsworn/pulls?state=open&per_page=100',
  'GET repos/rcbailey12/voidsworn/branches?per_page=100', 'GET repos/rcbailey12/voidsworn/issues/846/comments?per_page=100',
  'POST repos/rcbailey12/voidsworn/issues/846/labels', 'POST repos/rcbailey12/voidsworn/issues/846/comments')) {
  Init ('api-' + [guid]::NewGuid().ToString('N'))
  $env:PC_TEST_GH_FAIL = $endpoint
  & $common announce $out 846 codex $repo 21600 'codex_issue.bat 846' real
  Assert ($LASTEXITCODE -eq 14) "start requires $endpoint"
  $db = Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json
  Assert (-not $db.running) 'failed claim must release only the label it acquired'
  $env:PC_TEST_GH_FAIL = ''
}
Pass 'unreadable dispatch state or failed label/comment claim stops before work'
foreach ($part in @('label','comment')) {
  Init ('unconfirmed-' + $part)
  $env:PC_TEST_GH_DROP = $part
  & $common announce $out 846 codex $repo 21600 'resume' real
  Assert ($LASTEXITCODE -eq 14) "must read back claimed $part"
  Assert ([IO.File]::ReadAllText((Join-Path $out 'result.txt')).Contains('claim did not land')) 'clear claim readback failure'
  Assert (-not (Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json).running) 'failed readback does not leave running'
  $env:PC_TEST_GH_DROP = ''
}
Pass 'a zero-exit API response cannot start work unless label and owned comment actually landed'
Init 'replaced-claim'; Announce
$db = Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json
$db.comments[0].body = $db.comments[0].body.Replace('- Run:', '- Previous run:')
Put $env:PC_TEST_GH_DB ($db | ConvertTo-Json -Depth 12)
Finish '8'
Assert ((Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json).running) 'cannot clear a newer claim'
Assert (@(Calls | Where-Object { $_.method -eq 'DELETE' }).Count -eq 0) 'newer claim preserved'
Pass 'finish cannot edit or clear a status comment now owned by another run'
foreach ($form in @('## Run 2: THIS IS THE JOB NOW','**Run 2: THIS IS THE JOB NOW.** Inline current instructions.',
  'THIS IS THE JOB NOW (run 2). Inline current instructions.')) {
  Init ('marker-' + [guid]::NewGuid().ToString('N'))
  $db = Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json
  $db.issue.body = $db.issue.body.Replace('## THIS IS THE JOB NOW', $form).Replace('## Earlier run (DONE)','**Run 1 (DONE).**')
  $db.branches += @(@{ name = 'codex/issue-846' }, @{ name = 'codex/issue-846-partial' }, @{ name = 'work/issue-8460-other' })
  $db.pulls = @(@{ number = 999; head = @{ ref = 'codex/issue-846' } }, @{ number = 998; body = 'Refs #846'; head = @{ ref = 'codex/another-name' } })
  Put $env:PC_TEST_GH_DB ($db | ConvertTo-Json -Depth 12)
  Announce
  $snapshot = Get-Content (Join-Path $out 'validated_issue.json') -Raw | ConvertFrom-Json
  Assert ($snapshot.body.Contains($form) -and -not $snapshot.body.Contains('OLD BRIEF')) 'any-form marker selects only its current block'
  Finish '8'
}
Pass 'heading, bold and plain current lines allow same-prefix branches and open PR reruns'
# Issue 984: issue 975's run 2 starts with prose about run 1, followed by numbered instructions.
foreach ($boundary in @('## Run 1 (Board, Nov 16): DONE', '**Run 1 (Board, Nov 16): DONE**', 'Run 1 (Board, Nov 16): DONE',
  ('## Run 1: DONE ' + ('old label ' * 10)), ('**Run 1: DONE ' + ('old label ' * 10) + '**'))) {
  Init ('prose-run-' + [guid]::NewGuid().ToString('N'))
  $db = Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json
  $fixed = $db.issue.body.Substring(0, $db.issue.body.IndexOf("\n\n## THIS IS THE JOB NOW"))
  $current = "## THIS IS THE JOB NOW (run 2, Board, Nov 17)\n\nRun 1 (PR 977) passed every check, but the station still needs its paint and close zoom work before this run is done.\n\n" +
    "Run 1 passed every check.\n\nRun 1: " + ('this prose continues well beyond a short label. ' * 3) + "\n\n" +
    "1. Keep the station paint instructions.\n2. Keep the close zoom checks."
  $db.issue.body = $fixed + "\n\n" + $current + "\n\n" + $boundary + "\nOLD BRIEF MUST NOT REACH AGENT\n"
  if ($boundary.StartsWith('**')) { $db.issue.body = $db.issue.body.Replace("\n", "\r\n") }
  Put $env:PC_TEST_GH_DB ($db | ConvertTo-Json -Depth 12)
  Announce
  $snapshot = Get-Content (Join-Path $out 'validated_issue.json') -Raw | ConvertFrom-Json
  $expected = $fixed + "\n\n" + $current
  Assert ($snapshot.body.Replace("\r\n", "\n") -eq $expected) '975 body keeps all prose and numbered items, ending only at a run label'
  Finish '8'
}
Pass '975 run 2 keeps long and short Run 1 prose; heading, bold and short plain labels still end the brief'
foreach ($seat in @('deepseek','kimi','kimicode','opus')) {
  $branch = if ($seat -eq 'opus') { 'opus/issue-846' } else { "work/issue-846-$seat" }
  Init ('no-effort-' + $seat) $branch
  $db = Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json
  $db.issue.body = $db.issue.body.Replace("Effort (Codex): high\n",'').Replace('Owner: codex', ('Owner: ' + $seat)).Replace('Branch: codex/issue-846', "Branch: $branch")
  Put $env:PC_TEST_GH_DB ($db | ConvertTo-Json -Depth 12)
  Shared @('announce',$out,'846',$seat,$repo,'21600','resume','real')
  Finish '8'
}
Pass 'work, Kimi and Opus jobs need no Codex Effort or Models line'
foreach ($seat in @('codex','deepseek','kimi','kimicode','opus','muse')) {
  $branch = if ($seat -in @('codex','opus','muse')) { "$seat/issue-846" } else { "work/issue-846-$seat" }
  foreach ($form in @('plain','fenced-crlf')) {
    Init ('new-job-' + $seat + '-' + $form) $branch
    $db = Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json
    $fixed = $db.issue.body.Substring(0, $db.issue.body.IndexOf("\n\n## THIS IS THE JOB NOW"))
    if ($seat -ne 'codex') {
      $fixed = $fixed.Replace("Effort (Codex): high\n",'').Replace('Owner: codex', ('Owner: ' + $seat)).Replace('Branch: codex/issue-846', "Branch: $branch")
    }
    $body = $fixed + "\n\nFinish the new job.\n## Checks\nKeep all new-job checks.\n"
    if ($form -eq 'fenced-crlf') { $body = ('\x60\x60\x60text' + "\n" + $fixed + "\n" + '\x60\x60\x60' + "\n\nFinish the new job.\n").Replace("\n","\r\n") }
    $db.issue.body = $body
    Put $env:PC_TEST_GH_DB ($db | ConvertTo-Json -Depth 12)
    Shared @('announce',$out,'846',$seat,$repo,'21600','resume','real')
    $snapshot = Get-Content (Join-Path $out 'validated_issue.json') -Raw | ConvertFrom-Json
    Assert ($snapshot.body -eq $body.Trim()) 'one fixed block without run history passes the whole body'
    Finish '8'
  }
}
Pass 'new jobs with a single plain or fenced fixed block need no current-run marker on every seat'
Init 'work-opus-prefix' 'work/issue-846-opus'
$db = Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json
$db.issue.body = $db.issue.body.Replace("Effort (Codex): high\n",'').Replace('Branch: codex/issue-846','Branch: work/issue-846-opus')
$db.branches += @(@{ name = 'work/issue-846-opus' })
$db.pulls = @(@{ number = 999; head = @{ ref = 'work/issue-846-deepseek' } })
Put $env:PC_TEST_GH_DB ($db | ConvertTo-Json -Depth 12)
Shared @('announce',$out,'846','opus',$repo,'21600','resume','real')
Finish '8'
Pass 'Opus API arm uses its actual work branch prefix when allowing reruns'
Init 'inline-fixed-marker'
$db = Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json
$db.issue.body = $db.issue.body.Replace("Done when: stub finishes\n\n## THIS IS THE JOB NOW\nFinish the current fixture job.",
  'Done when: (run 2, THIS IS THE JOB NOW) finish this inline job.').Replace('## Earlier run (DONE)', 'Run 1 (done):')
Put $env:PC_TEST_GH_DB ($db | ConvertTo-Json -Depth 12)
Announce
$snapshot = Get-Content (Join-Path $out 'validated_issue.json') -Raw | ConvertFrom-Json
Assert ($snapshot.body.Contains('finish this inline job') -and -not $snapshot.body.Contains('OLD BRIEF')) 'inline marker keeps instructions and excludes history'
Assert ([regex]::Matches($snapshot.body,'THIS IS THE JOB NOW').Count -eq 1) 'inline marker is not duplicated in snapshot'
Finish '8'
Pass 'a marker and instruction on Done when itself are valid, with plain old-run boundary'
Init 'embedded-effort'
$db = Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json
$db.issue.body = $db.issue.body.Replace("Effort (Codex): high\n",'').Replace('Owner: codex','Owner: codex (Board: Effort (Codex): xhigh)')
Put $env:PC_TEST_GH_DB ($db | ConvertTo-Json -Depth 12)
Announce
& (Join-Path $pc 'codex_issue.ps1') prep 846 $repo $out
Assert ($LASTEXITCODE -eq 0) 'prep accepts fixed-block effort on the owner line'
Assert ([IO.File]::ReadAllText((Join-Path $out 'effort.txt')) -eq 'xhigh') 'prep preserves the chosen effort instead of silently defaulting'
Finish '8'
Pass 'Codex keeps the effort embedded on the Owner line used by the live station issue'
Init 'current-sections'
$db = Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json
$db.issue.body = $db.issue.body.Replace('Finish the current fixture job.', "Finish the current fixture job.\n## Checks\nKEEP CURRENT CHECKS\n~~~text\n## THIS IS THE JOB NOW\n~~~\n" +
  '\x60\x60\x60text' + "\nTHIS IS THE JOB NOW\n" + '\x60\x60\x60')
Put $env:PC_TEST_GH_DB ($db | ConvertTo-Json -Depth 12)
Announce
$snapshot = Get-Content (Join-Path $out 'validated_issue.json') -Raw | ConvertFrom-Json
Assert ($snapshot.body.Contains('KEEP CURRENT CHECKS') -and -not $snapshot.body.Contains('OLD BRIEF')) 'keep current peer sections, omit completed runs'
Finish '8'
Pass 'current block preserves peer sections and ignores both kinds of fenced marker examples'
Init 'board-audit'
$db = Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json
$accept = $db.issue | ConvertTo-Json -Depth 12 | ConvertFrom-Json
$accept.labels = @(@{ name = 'codex' }); $accept.number = 846
$refuse = $db.issue | ConvertTo-Json -Depth 12 | ConvertFrom-Json
$refuse.number = 847; $refuse.labels = @(@{ name = 'opus' }); $refuse.body = 'No current brief'
$skip = $db.issue | ConvertTo-Json -Depth 12 | ConvertFrom-Json
$skip.number = 848; $skip.labels = @(@{ name = 'ryan' })
$muse = $db.issue | ConvertTo-Json -Depth 12 | ConvertFrom-Json
$muse.number = 849; $muse.labels = @(@{ name = 'muse' })
$muse.body = $muse.body.Substring(0, $muse.body.IndexOf("\n\n## THIS IS THE JOB NOW")).Replace('Owner: codex','Owner: muse').Replace('Branch: codex/issue-846','Branch: muse/issue-849') + "\n\nNew Muse job."
$db | Add-Member -NotePropertyName issues -NotePropertyValue @($accept,$refuse,$skip,$muse)
$db.branches += @(@{ name = 'codex/issue-846' }); $db.pulls = @(@{ number = 900; head = @{ ref = 'codex/issue-846' } })
Put $env:PC_TEST_GH_DB ($db | ConvertTo-Json -Depth 12)
Shared @('board-dryrun',$out)
$audit = [IO.File]::ReadAllText((Join-Path $out 'board_audit.txt'))
Assert ($audit.Contains('#846 [codex] ACCEPT') -and $audit.Contains('#847 [opus] REFUSE:') -and $audit.Contains('#849 [muse] ACCEPT') -and -not $audit.Contains('#848')) 'audit includes all and only codex, muse or opus jobs with per-issue verdicts'
Assert (@(Calls | Where-Object { $_.method -ne 'GET' }).Count -eq 0) 'audit cannot write claims'
Assert (-not (Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json).running) 'audit leaves issue unclaimed'
Pass 'paginated board dry run uses the same validation, allows reruns and performs only GETs'
Init 'base-clean'; Put (Join-Path $out 'resume.txt') 'Resumed by merging earlier partial.'
Put (Join-Path $out 'base_commit.txt') '${main}'
$publisher = Join-Path $pc 'work_issue.ps1'
& $publisher head-changed $repo $out
Assert ($LASTEXITCODE -eq 7) 'a resume note alone does not advance HEAD'
Base "Owner: codex\r\n  Base: work/issue-800  \r\nDone when: works"
& $publisher head-changed $repo $out
Assert ($LASTEXITCODE -eq 0) 'a Base merge advances HEAD from the recorded base on a fresh branch'
$parents = (& $script:git -C $repo rev-list --parents -n 1 HEAD) -split ' '
Assert ($parents.Count -eq 3 -and $parents[1] -eq '${main}' -and $parents[2] -eq '${clean}') 'runner committed both merge parents'
Assert ([IO.File]::ReadAllText((Join-Path $repo 'base.txt')) -eq "from base\n") 'base content merged'
& $script:git -C $repo rev-parse -q --verify MERGE_HEAD
Assert ($LASTEXITCODE -ne 0) 'no unfinished merge reaches agent'
$resume = [IO.File]::ReadAllText((Join-Path $out 'resume.txt'))
Assert ($resume.Contains('Resumed by merging earlier partial.') -and $resume.Contains('Base already merged by the runner: origin/work/issue-800')) 'preserve partial context and add base note'
Pass 'Base parses CRLF and commits a real merge while preserving resume context'
# Prep is the production caller for both seats. Use the same already-merged base, no extra commit.
$db = Get-Content $env:PC_TEST_GH_DB -Raw | ConvertFrom-Json
$db.issue.body = $db.issue.body.Replace('Brief: below', "Brief: below\nBase: work/issue-800")
Put $env:PC_TEST_GH_DB ($db | ConvertTo-Json -Depth 12)
Announce
# Later GitHub edits cannot change the brief that this run validated and claimed.
$db.issue.body = 'AN UNVALIDATED REPLACEMENT BRIEF'
Put $env:PC_TEST_GH_DB ($db | ConvertTo-Json -Depth 12)
foreach ($seat in @('codex','work')) {
  $helper = Join-Path $pc ($seat + '_issue.ps1')
  if ($seat -eq 'codex') { & $helper prep 846 $repo $out }
  else { & $helper prep 846 deepseek $repo $out 'godot' }
  Assert ($LASTEXITCODE -eq 0) "$seat prep"
  $task = [IO.File]::ReadAllText((Join-Path $repo ($seat.ToUpper() + '_TASK.md')))
  Assert ($task.Contains('Base already merged by the runner') -and $task.Contains('Do not run git merge')) "$seat prompt must say base is already in"
  Assert (-not $task.Contains('OLD BRIEF MUST NOT REACH AGENT')) "$seat omits completed briefs"
  Assert (-not $task.Contains('AN UNVALIDATED REPLACEMENT BRIEF')) "$seat uses only the validated snapshot"
}
Pass 'both real prep helpers merge Base and tell the agent it is committed'
Finish '8'
Shared @('init',$out,'codex/issue-846')
foreach ($seat in @('codex','work')) {
  try {
    if ($seat -eq 'codex') { & (Join-Path $pc 'codex_issue.ps1') prep 846 $repo $out }
    else { & (Join-Path $pc 'work_issue.ps1') prep 846 deepseek $repo $out 'godot' }
    throw 'STALE SNAPSHOT WAS ACCEPTED'
  } catch { Assert ($_.Exception.Message.Contains('no validated current instruction')) 'old snapshot must refuse' }
}
Pass 'both prep helpers refuse an earlier run snapshot after init'
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

$ship = 'godot/assets/ships/B16_23/B16_23.glb'
foreach ($case in @(
  @{ name = 'identical'; local = 'hull-A'; shared = 'hull-A' },
  @{ name = 'different'; local = 'hull-A'; shared = 'hull-B' },
  # Issue 1180 run 7: a ship the shared build has superseded may be removed by the janitor, but never reused.
  @{ name = 'superseded'; local = 'hull-A'; shared = 'hull-B'; older = $true },
  @{ name = 'missing'; local = 'hull-A' }
)) {
  $lane = 'ship-' + $case.name
  $null = New-Item -ItemType Directory -Path (Join-Path $root $lane)
  $repo = New-Repo "$lane/repo"
  Put (Join-Path $repo '.git/info/exclude') 'godot/assets/ships/*/'
  $localShip = Join-Path $repo $ship
  $sharedPath = if ($case.shared) { $ship } else { 'godot/assets/ships/B16_23/other.glb' }
  $env:USERPROFILE = Join-Path $root "$lane/profile"
  $sharedShip = Join-Path (Join-Path $env:USERPROFILE 'Downloads/voidsworn_test/build') $sharedPath
  $sharedBytes = if ($case.shared) { $case.shared } else { $case.local }
  $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $localShip), (Split-Path -Parent $sharedShip)
  Put $localShip $case.local
  Put $sharedShip $sharedBytes
  if ($case.older) { (Get-Item -LiteralPath $localShip).LastWriteTimeUtc = [DateTime]::UtcNow.AddDays(-2) }
  Init "$lane/out" 'fixture/ship-reuse'
  $env:PC_TEST_SOURCE = $upstream
  $env:PC_TEST_MIRROR = Join-Path $root "$lane/mirror.git"
  Shared @('checkout',$repo,$out,'fixture/ship-reuse','')
  Assert ((& $script:git -C $repo symbolic-ref --short HEAD) -eq 'fixture/ship-reuse') 'runner switches to the new branch'
  $result = [IO.File]::ReadAllText((Join-Path $out 'result.txt'))
  $kept = @(Get-ChildItem -LiteralPath (Split-Path -Parent $repo) -Directory -Filter 'repo-kept-*')
  if ($case.name -eq 'identical') {
    Assert ($kept.Count -eq 0 -and $result.Contains('earlier checkout reused in place')) 'identical ship must reuse checkout'
    Assert ([IO.File]::ReadAllText($localShip) -ceq $case.local) 'reused ship bytes survive'
  } else {
    Assert ($kept.Count -eq 1 -and $result.Contains('shared ship copy could not be verified')) "$lane must keep the checkout"
    Assert ([IO.File]::ReadAllText((Join-Path $kept[0].FullName $ship)) -ceq $case.local) 'kept ship bytes survive'
    Assert (-not (Test-Path -LiteralPath $localShip)) 'fresh checkout has no ignored ship file'
  }
  Assert ([IO.File]::ReadAllText($sharedShip) -ceq $sharedBytes) 'shared ship bytes survive'
  Pass "$lane preserves the earlier ship bytes and starts the next branch"
}

$parityOutputs = @(
  'godot/campaign/test/golden/c1.jsonl',
  'godot/campaign/test/out/c1.jsonl',
  'godot/campaign/test/parity_campaign_log.txt',
  'godot/rules/test/golden/s1.jsonl',
  'godot/rules/test/out/s1.jsonl',
  'godot/rules/test/parity_log.txt',
  'godot/scenes/test script.gd.uid'
)
foreach ($case in @(
  @{ name = 'outputs-only' },
  @{ name = 'tracked-edit'; path = 'shared.txt'; status = ' M shared.txt' },
  @{ name = 'untracked-uid'; path = 'godot/scenes/unsaved.gd.uid'; status = '?? godot/scenes/unsaved.gd.uid' },
  @{ name = 'ignored-lookalike'; path = 'godot/campaign/test/out-notes/notes.txt'; status = '!! godot/campaign/test/out-notes/notes.txt' },
  @{ name = 'nested-repo'; path = 'godot/campaign/test/out/nested/notes.txt'; status = '!! godot/campaign/test/out/nested/'; nested = $true }
)) {
  $lane = 'parity-' + $case.name
  $null = New-Item -ItemType Directory -Path (Join-Path $root $lane)
  $repo = New-Repo "$lane/repo"
  Put (Join-Path $repo '.git/info/exclude') (@(
    '/godot/campaign/test/golden/', '/godot/campaign/test/out/', '/godot/campaign/test/parity_campaign_log.txt',
    '/godot/rules/test/golden/', '/godot/rules/test/out/', '/godot/rules/test/parity_log.txt',
    '/godot/**/*.uid', '!/godot/scenes/unsaved.gd.uid', '/godot/campaign/test/out-notes/', ''
  ) -join [Environment]::NewLine)
  foreach ($name in $parityOutputs) {
    $file = Join-Path $repo $name
    $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $file)
    Put $file 'generated output'
  }
  if ($case.path) {
    $file = Join-Path $repo $case.path
    $parent = Split-Path -Parent $file
    $null = New-Item -ItemType Directory -Force -Path $parent
    if ($case.nested) {
      & $script:git init -q $parent
      Assert ($LASTEXITCODE -eq 0) 'nested repo fixture'
    }
    Put $file 'local work'
  }
  Init "$lane/out" 'fixture/parity-reuse'
  $env:PC_TEST_SOURCE = $upstream
  $env:PC_TEST_MIRROR = Join-Path $root "$lane/mirror.git"
  Shared @('checkout',$repo,$out,'fixture/parity-reuse','')
  $result = [IO.File]::ReadAllText((Join-Path $out 'result.txt'))
  $kept = @(Get-ChildItem -LiteralPath (Split-Path -Parent $repo) -Directory -Filter 'repo-kept-*')
  $earlier = $repo
  if ($case.path) {
    Assert ($kept.Count -eq 1 -and $result.Contains("working tree needs keeping: $($case.status)")) $result
    $earlier = $kept[0].FullName
    Assert ([IO.File]::ReadAllText((Join-Path $earlier $case.path)) -ceq 'local work') 'local work survives'
  } else {
    Assert ($kept.Count -eq 0 -and $result.Contains('earlier checkout reused in place')) $result
  }
  foreach ($name in $parityOutputs) {
    Assert ([IO.File]::ReadAllText((Join-Path $earlier $name)) -ceq 'generated output') "$name survives"
  }
  Pass "$lane uses the rebuildable-file list and preserves checkout bytes"
}
function Sparse-Start($label, $slot, $brief, $delivery, $history = '') {
  Init $label 'fixture/sparse'
  $body = @('Owner: codex', "Brief: $brief", "Deliver to: $delivery", 'Branch: fixture/sparse', 'Done when: proof', '', $history) -join [Environment]::NewLine
  Put (Join-Path $out 'validated_issue.json') (@{body = $body} | ConvertTo-Json)
  Shared @('checkout',$slot,$out,'fixture/sparse','')
  return [IO.File]::ReadAllText((Join-Path $out 'result.txt'))
}
$env:PC_TEST_SOURCE = $upstream
$env:PC_TEST_MIRROR = Join-Path $root 'sparse-mirror.git'
$paths = @('docs/shots/shot.png','docs/ship_pipeline/build_sheets/sheet.md','contrib/muse/design/draft.md','hulls_hi/hull.glb','rocks_hi/rock.glb')
foreach ($lane in @('board_c','board_d','slot_deepseek','slot_openai','board_b')) {
  $slot = Join-Path $root "$lane/repo"
  $null = Sparse-Start "sparse-$lane" $slot 'docs/shots-index.md' 'shared.txt' "Brief: hulls_hi/hull.glb"
  if (-not (Test-Path -LiteralPath (Join-Path $slot 'shared.txt'))) {
    # Show what Git did, so a failure on another host can be read from the CI log alone.
    $seen = @(Get-ChildItem -LiteralPath $slot -Force -Name -ErrorAction SilentlyContinue) -join ', '
    $gitLog = [IO.File]::ReadAllText((Join-Path $out 'git_log.txt'))
    $result = [IO.File]::ReadAllText((Join-Path $out 'result.txt'))
    $status = (& $script:git -C $slot status --porcelain=v1 2>&1 | Select-Object -First 10) -join ' | '
    [Console]::Error.WriteLine(("DIAG $lane keeps code: slot holds [$seen]; status [$status]; result [$result]; git log [$gitLog]" -replace '[\r\n]+', ' / '))
    throw "$lane keeps code (see DIAG line)"
  }
  foreach ($name in $paths) {
    Assert ((Test-Path -LiteralPath (Join-Path $slot $name)) -eq ($lane -eq 'board_b')) "$lane checks out the right paths: $name"
  }
  $log = Sparse-Start "sparse-reuse-$lane" $slot 'below' 'shared.txt'
  Assert ($log.Contains('earlier checkout reused in place')) "$lane failed reuse: $log"
}
$slot = Join-Path $root 'board_d/repo'
$evidence = 'docs/shots/issue-846-codex/proof.png'
$null = New-Item -ItemType Directory -Path (Split-Path -Parent (Join-Path $slot $evidence)) -Force
Put (Join-Path $slot $evidence) 'report evidence'
Put (Join-Path $slot ($evidence + '.provenance.json')) '{}'
Put (Join-Path $out 'deliver_to.txt') 'shared.txt'
& (Join-Path $pc 'work_issue.ps1') guard 846 codex $slot $out
Assert ($LASTEXITCODE -eq 0) 'runner can stage review evidence in the excluded shots folder'
$staged = @(& $script:git -C $slot diff --cached --name-only)
Assert ($staged.Count -eq 2 -and $staged -contains $evidence -and $staged -contains ($evidence + '.provenance.json')) 'only the picture and sidecar are staged'
Pass 'sparse runner stages new report evidence without materializing historical pictures'
$slot = Join-Path $root 'slot_openai/repo'
$log = Sparse-Start 'sparse-opt-in' $slot './docs/shots/shot.png' 'contrib\\muse\\design\\draft.md, rocks_hi/rock.glb'
# Issue 1739: a profile change on a clean runner-managed checkout is applied in place, not kept as a ~28 GB copy.
Assert ($log.Contains('sparse checkout profile changed in place') -and $log.Contains('earlier checkout reused in place')) "opt-in profile change reuses the checkout: $log"
foreach ($i in 0,2,4) { Assert (Test-Path -LiteralPath (Join-Path $slot $paths[$i])) "missing requested path $($paths[$i])" }
foreach ($i in 1,3) { Assert (-not (Test-Path -LiteralPath (Join-Path $slot $paths[$i]))) "unexpected path $($paths[$i])" }
Assert (-not @(Get-ChildItem -LiteralPath (Split-Path -Parent $slot) -Directory | Where-Object { $_.Name -like 'repo-kept-*' }).Count) 'no kept copy for a safe profile change'
# Back to the lean profile: the opted-in folders hold only tracked files, so they leave the work tree again.
$log = Sparse-Start 'sparse-back-to-lean' $slot 'below' 'shared.txt'
Assert ($log.Contains('sparse checkout profile changed in place') -and $log.Contains('earlier checkout reused in place')) "lean profile change reuses the checkout: $log"
foreach ($name in $paths) { Assert (-not (Test-Path -LiteralPath (Join-Path $slot $name))) "lean profile still holds $name" }
# An agent that turned sparse off (git sparse-checkout disable) leaves a full checkout; the next run makes it lean in place.
& $script:git -C $slot sparse-checkout disable 2>&1 | Out-Null
Assert ((Test-Path -LiteralPath (Join-Path $slot $paths[0])) -and $LASTEXITCODE -eq 0) 'fixture turned sparse off'
$log = Sparse-Start 'sparse-full-to-lean' $slot 'below' 'shared.txt'
Assert ($log.Contains('sparse checkout profile changed in place') -and $log.Contains('earlier checkout reused in place')) "full checkout made lean in place: $log"
foreach ($name in $paths) { Assert (-not (Test-Path -LiteralPath (Join-Path $slot $name))) "full-to-lean still holds $name" }
# An untracked file in a folder the new profile leaves out could be lost, so that checkout is still kept whole.
$log = Sparse-Start 'sparse-opt-in-again' $slot './docs/shots/shot.png' 'contrib\\muse\\design\\draft.md, rocks_hi/rock.glb'
Assert ($log.Contains('earlier checkout reused in place')) "opt-in again reuses: $log"
Put (Join-Path $slot 'docs/shots/local_only.png') 'untracked picture'
$log = Sparse-Start 'sparse-untracked-in-left-out' $slot 'below' 'shared.txt'
Assert ($log.Contains('docs/shots/local_only.png is not tracked')) "untracked file in a newly left-out folder keeps the checkout: $log"
$kept = @(Get-ChildItem -LiteralPath (Split-Path -Parent $slot) -Directory | Where-Object { $_.Name -like 'repo-kept-*' })
Assert ($kept.Count -eq 1 -and [IO.File]::ReadAllText((Join-Path $kept[0].FullName 'docs/shots/local_only.png')) -eq 'untracked picture') 'the untracked picture survives in the kept copy'
$log = Sparse-Start 'sparse-opt-in-after-keep' $slot './docs/shots/shot.png' 'contrib\\muse\\design\\draft.md, rocks_hi/rock.glb'
$log = Sparse-Start 'sparse-opt-in-reuse' $slot 'docs/shots/shot.png' 'contrib/muse/design/draft.md, rocks_hi/rock.glb'
Assert ($log.Contains('earlier checkout reused in place')) 'same opt-in profile can be reused'
& $script:git -C $slot update-index --assume-unchanged shared.txt
Assert ($LASTEXITCODE -eq 0) 'fixture sets an unsafe index flag on included code'
Put (Join-Path $slot 'shared.txt') 'hidden local work'
$log = Sparse-Start 'sparse-hidden-edit' $slot 'docs/shots/shot.png' 'contrib/muse/design/draft.md, rocks_hi/rock.glb'
Assert ($log.Contains('index may hide tracked edits')) 'included code with a hidden edit requires preservation'
$kept = Get-ChildItem -LiteralPath (Split-Path -Parent $slot) -Directory | Where-Object { $_.Name -like 'repo-kept-*' }
Assert (@($kept | Where-Object { [IO.File]::ReadAllText((Join-Path $_.FullName 'shared.txt')) -eq 'hidden local work' }).Count -eq 1) 'hidden edit survives'
Pass 'lanes C and D and Workhorse slots reuse sparse profiles, honor fixed fields, and preserve hidden edits'
# Issue 1739 (1747 run 2): a rerun must start from the delivery branch's earlier tip, never from main alone, and a
# commit that does not descend from that tip must stop before the push. work/issue-800 holds base.txt; main does not.
$slot = Join-Path $root 'continue/repo'
Init 'continue-tip' 'work/issue-800'
Shared @('checkout',$slot,$out,'work/issue-800','')
$log = [IO.File]::ReadAllText((Join-Path $out 'result.txt'))
Assert ($log.Contains('continuing work/issue-800 from its earlier tip ${clean}')) "rerun starts from the earlier tip: $log"
Assert ([IO.File]::ReadAllText((Join-Path $out 'base_commit.txt')).Trim() -eq '${clean}') 'base commit is the earlier tip'
Assert ([IO.File]::ReadAllText((Join-Path $slot 'base.txt')) -eq "from base\n") 'the earlier run''s file is in the checkout'
$parents = (& $script:git -C $slot rev-list --parents -n 1 HEAD) -split ' '
Assert ($parents.Count -eq 3 -and $parents[1] -eq '${clean}' -and $parents[2] -eq '${main}') 'main is merged on top of the earlier tip'
$resume = [IO.File]::ReadAllText((Join-Path $out 'resume.txt'))
Assert ($resume.Contains('Continued from the earlier tip of work/issue-800') -and $resume.Contains('merged origin/main')) "agent is told: $resume"
Pass 'a rerun checks out the branch''s earlier tip and merges main on top'
# The commit step needs Windows PowerShell by name; on Linux point that name at pwsh.
if ($PSVersionTable.Platform -eq 'Unix') {
  $shim = Join-Path $root 'shim'; $null = New-Item -ItemType Directory -Force -Path $shim
  [IO.File]::WriteAllText((Join-Path $shim 'powershell'), '#!/bin/sh\nexec pwsh "$@"\n')
  & chmod 755 (Join-Path $shim 'powershell')
  $env:PATH = "$($shim):$($env:PATH)"
}
$work = Join-Path $pc 'work_issue.ps1'
Put (Join-Path $slot 'run2.txt') "run 2 report\n"
& $script:git -C $slot add run2.txt
Push-Location $slot; & $work commit $slot $out 'work/issue-800' 'dry' | Out-Null; $code = $LASTEXITCODE; Pop-Location
Assert ($code -eq 0) "a rerun from the earlier tip commits (exit $code)"
$tree = @(& $script:git -C $slot ls-tree -r --name-only HEAD)
Assert ($tree -contains 'base.txt' -and $tree -contains 'run2.txt') 'the rerun commit keeps run 1 and adds run 2'
& $script:git -C $slot merge-base --is-ancestor '${clean}' HEAD
Assert ($LASTEXITCODE -eq 0) 'the earlier tip is an ancestor of the push'
Pass 'a rerun commit keeps the earlier runs'' files'
# 1747 run 2's shape: the checkout is main alone, the branch already exists, the agent adds only its report.
$repo = New-Repo 'tip-drop-repo'
Init 'continue-drop' 'work/issue-800'
& $script:git -C $repo checkout -q -B work/issue-800 '${main}'
Put (Join-Path $out 'base_commit.txt') '${main}'
Put (Join-Path $repo 'report.md') "only the report\n"
& $script:git -C $repo add report.md
Push-Location $repo; $said = (& $work commit $repo $out 'work/issue-800' 'dry') -join "\n"; $code = $LASTEXITCODE; Pop-Location
Assert ($code -eq 15) "a run that does not descend from the earlier tip stops (exit $code): $said"
$tipNote = [IO.File]::ReadAllText((Join-Path $out 'EARLIER_TIP.txt'))
Assert ($tipNote.Contains('did not start from the earlier tip ${clean}') -and $tipNote.Contains('base.txt')) "the reason and the dropped file are named: $tipNote"
Assert ((& $script:git -C $repo rev-parse HEAD) -eq '${main}') 'nothing was committed'
Pass 'a commit that would drop the earlier tip''s files stops before the push and names them'
# Artoo on PR 1804: a reused slot must not continue a branch GitHub deleted, even while its old tip stays reachable.
$slot = Join-Path $root 'continue-reuse/repo'
Init 'continue-reuse-first' 'fixture/continue-reuse'
Shared @('checkout',$slot,$out,'fixture/continue-reuse','')
Assert ((& $script:git -C $slot rev-parse -q --verify 'refs/remotes/origin/work/issue-800') -eq '${clean}') 'the slot first sees the delivery branch'
& $script:git -C $upstream update-ref refs/heads/archive-800 '${clean}'
& $script:git -C $upstream update-ref -d refs/heads/work/issue-800
Init 'continue-reuse-deleted' 'work/issue-800'
Shared @('checkout',$slot,$out,'work/issue-800','')
$log = [IO.File]::ReadAllText((Join-Path $out 'result.txt'))
Assert ($log.Contains('earlier checkout reused in place') -and -not $log.Contains('continuing work/issue-800')) "a deleted branch is not continued: $log"
Assert ((& $script:git -C $slot rev-parse HEAD) -eq '${main}') 'the reused slot starts from main'
Pass 'a reused slot drops a deleted delivery branch and starts from main'
Write-Output "PASS runner job checks ($script:passed groups)"
`);
// Allow the same PC proof to run with pwsh, the engine used by Linux CI.
const ps = process.env.PC_TEST_POWERSHELL || (process.platform === 'win32' ? 'powershell.exe' : 'pwsh');
const probeStarted = Date.now();
r = spawnSync(ps, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(root, 'probes.ps1'), pc, root], {
  cwd: root, encoding: 'utf8', windowsHide: true, timeout: 240000,
  env: { ...process.env, PC_RUNNER_TEST: '1', PC_TEST_GH: gh.fake, PC_TEST_GH_FAIL: '',
    // The Windows prep helper builds its Godot path from USERPROFILE, which Linux does not provide.
    USERPROFILE: root,
    PC_TEST_GIT: '', PC_TEST_RETRY_SECONDS: '0',
    GIT_AUTHOR_NAME: 'Fixture', GIT_AUTHOR_EMAIL: 'fixture@example.invalid',
    GIT_COMMITTER_NAME: 'Fixture', GIT_COMMITTER_EMAIL: 'fixture@example.invalid' }
});
// Standing checks show only the first 15 lines on failure. Keep the actual exception ahead of earlier PASS output.
assert.equal(r.status, 0, (r.stderr || '') + String(r.error || '') + '\nEvidence: ' + root + '\n' + (r.stdout || ''));
console.log(r.stdout.trim());
console.log('PASS PowerShell probes elapsed: ' + ((Date.now() - probeStarted) / 1000).toFixed(1) + ' s');
// Race two actual PowerShell processes against the same issue and fake REST database, just like two PC lanes.
(async () => {
  const race = path.join(root, 'claim-race'); fs.mkdirSync(race);
  const database = path.join(race, 'gh-db.json'), trace = path.join(race, 'gh.jsonl');
  write(database, JSON.stringify(gh.database(846, main))); write(trace, '');
  const env = { ...process.env, PC_RUNNER_TEST: '1', PC_TEST_GH: gh.fake, PC_TEST_GH_DB: database,
    PC_TEST_GH_TRACE: trace, PC_TEST_GH_FAIL: '', PC_TEST_GH_HOLD: '1' };
  const common = path.join(pc, 'runner_common.ps1');
  const args = words => ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', common, ...words];
  const outs = ['lane-a', 'lane-b'].map(lane => {
    const out = path.join(race, lane); fs.mkdirSync(out);
    const init = spawnSync(ps, args(['init', out, 'codex/issue-846']), { env, encoding: 'utf8', windowsHide: true });
    assert.equal(init.status, 0, init.stderr); return out;
  });
  const results = await Promise.all(outs.map(out => new Promise((resolve, reject) => {
    const child = spawn(ps, args(['announce', out, '846', 'codex', path.join(out, 'repo'), '21600', 'resume', 'real']), { env, windowsHide: true });
    let output = ''; child.stdout.on('data', b => output += b); child.stderr.on('data', b => output += b);
    child.on('error', reject); child.on('close', code => resolve({ code, output, out }));
  })));
  assert.deepEqual(results.map(r => r.code).sort((a, b) => a - b), [0, 14], JSON.stringify(results));
  assert(results.find(r => r.code === 14).output.includes('already carries running'), JSON.stringify(results));
  const calls = read(trace).trim().split(/\r?\n/).map(l => JSON.parse(l));
  assert.equal(calls.filter(c => c.method === 'POST' && /\/issues\/846\/labels$/.test(c.endpoint)).length, 1);
  assert.equal(JSON.parse(read(database)).comments.length, 1);
  const finish = spawnSync(ps, args(['finish', results.find(r => r.code === 0).out, '8', '', 'real', '0']), { env, encoding: 'utf8', windowsHide: true });
  assert.equal(finish.status, 0, finish.stderr); assert(!JSON.parse(read(database)).running);
  console.log('PASS simultaneous Codex starts on two lanes yield exactly one claim; losing run cannot clear it');
})().catch(e => { console.error(e.stack); process.exitCode = 1; });
