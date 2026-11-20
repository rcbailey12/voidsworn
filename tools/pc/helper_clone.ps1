# Issue 1180 (Board, Nov 20): one shared base for helper PC jobs, so a helper no longer downloads its own copy.
# Usage (from helper_clone.bat): helper_clone.ps1 <job folder> <branch> [ships]
#   - Refreshes the shared repo-mirror.git under the same lock as runner_common.ps1 and ship_job.bat.
#   - Makes <job folder>\repo once with `git clone --local` (Git objects are hardlinked from the mirror, near zero bytes),
#     then reuses it on later runs: fetch the branch and switch to it. A clone with local changes or local-only commits
#     is never reset; the run stops and says so.
#   - With "ships": runs get_ship_files.bat from build\godot (a checked copy). Ship files are copied, not hardlinked,
#     because stage 7 and other tools rewrite those files in place and a hardlink would change the shared build too.
#   - Writes <job folder>\repo_commit.txt. Writes only under <job folder> and the mirror.
param([Parameter(Mandatory)][string]$JobDir, [Parameter(Mandatory)][string]$Branch, [string]$Ships = '')
$ErrorActionPreference = 'Stop'
$vt = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$mirror = Join-Path $vt 'repo-mirror.git'
$source = 'https://github.com/rcbailey12/voidsworn'
if ($Branch -notmatch '\A[A-Za-z0-9._/-]+\z' -or $Branch.Contains('..')) { throw "branch name not accepted: $Branch" }
$job = [IO.Path]::GetFullPath($JobDir)
if (-not $job.StartsWith($vt + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "job folder must be under $vt" }
$repo = Join-Path $job 'repo'
function Run-Git {
  # PowerShell 5.1 turns native stderr into errors under 'Stop'; read it as text instead.
  $ErrorActionPreference = 'Continue'
  $out = & git.exe @args 2>&1 | ForEach-Object { "$_" }
  if ($LASTEXITCODE -ne 0) { throw ('git failed: ' + ($args -join ' ') + ': ' + ($out -join ' ')) }; $out }
$null = [IO.Directory]::CreateDirectory($job)
$lock = $null; $deadline = [DateTime]::UtcNow.AddMinutes(30)
while (-not $lock) {
  try { $lock = [IO.File]::Open($mirror + '.lock', 'OpenOrCreate', 'ReadWrite', 'None') }
  catch [IO.IOException] { if ([DateTime]::UtcNow -ge $deadline) { throw 'shared repo copy stayed locked for 30 minutes' }; Start-Sleep -Milliseconds 500 }
}
try {
  if (-not (Test-Path -LiteralPath (Join-Path $mirror 'HEAD'))) { Run-Git init --bare $mirror | Out-Null; Run-Git --git-dir $mirror remote add --mirror=fetch origin $source | Out-Null }
  if ((Run-Git --git-dir $mirror config --get remote.origin.url) -ne $source) { throw 'shared repo copy has an unexpected origin; kept unchanged' }
  Write-Output "refreshing shared mirror $mirror"
  Run-Git --git-dir $mirror -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 fetch --prune origin | Out-Null
  Run-Git --git-dir $mirror symbolic-ref HEAD refs/heads/main | Out-Null
  $fresh = -not (Test-Path -LiteralPath (Join-Path $repo '.git'))
  if ($fresh) {
    Write-Output "local clone $repo (objects shared with the mirror)"
    Run-Git -c core.autocrlf=false clone --local -q --no-checkout $mirror $repo | Out-Null
  }
  $depth = @(); if ((Run-Git -C $repo rev-parse --is-shallow-repository) -eq 'true') { $depth = @('--unshallow') }
  Run-Git -C $repo fetch -q --no-tags @depth $mirror "+refs/heads/${Branch}:refs/remotes/origin/$Branch" | Out-Null
} finally { $lock.Dispose() }
# Never reset someone's work: stop if the clone has tracked edits, staged changes or commits not on any mirror branch.
if (-not $fresh) {
  $dirty = @(Run-Git -C $repo status --porcelain --untracked-files=no)
  if ($dirty.Count) { throw "clone has local changes, kept as is: $($dirty -join '; ')" }
  $local = @(Run-Git -C $repo rev-list HEAD --not --remotes=origin)
  if ($local.Count) { throw "clone has $($local.Count) commits not on any mirror branch, kept as is" }
}
Run-Git -C $repo checkout -q --detach "refs/remotes/origin/$Branch" | Out-Null
$commit = (Run-Git -C $repo rev-parse HEAD) | Select-Object -First 1
[IO.File]::WriteAllText((Join-Path $job 'repo_commit.txt'), "$commit`n")
Write-Output "helper clone $repo at $commit ($Branch)"
if ($Ships -eq 'ships') {
  & cmd.exe /d /c "`"$repo\tools\pc\get_ship_files.bat`" `"$vt\build\godot`" `"$repo`""
  if ($LASTEXITCODE -ne 0) { throw "get_ship_files.bat failed (exit $LASTEXITCODE)" }
}
