# Issue 1303: the PowerShell half of opus_job_head.bat (one shared head for helper PC proof bats). Actions:
#   live <folder>                              exit 0 when the folder is inside voidsworn_test\tools_live\ (the head
#                                              must run from the installed main copy)
#   watchdog <tools pc folder>                 tmo.bat and run_timeout.ps1 must both exist; prints each path and sha256
#   checkout <attempt folder> <name> <sha>     a fresh checkout of one exact commit in <attempt>\<name>, never reused:
#                                              the shared repo-mirror.git (same lock as helper_clone.ps1 and the runners)
#                                              is fetched only when the commit is missing, then `git clone --local` and a
#                                              detached checkout; HEAD must equal the pin
#   tracked <repo>                             fails when any tracked file differs from the pinned commit
#   hashes <out file>                          sha256 of Ryan's real battle_opts.json and board_look.cfg
# Deletes nothing. Test settings (helper_clone's): PC_TEST_HELPER=1, PC_TEST_HELPER_VT, PC_TEST_SOURCE, PC_TEST_REALU.
param([Parameter(Mandatory)][ValidateSet('live', 'watchdog', 'checkout', 'tracked', 'hashes')][string]$Action,
      [string]$A = '', [string]$B = '', [string]$C = '')
$ErrorActionPreference = 'Stop'
$test = [bool]$env:PC_TEST_HELPER
$unix = $PSVersionTable.Platform -eq 'Unix'
$sep = [IO.Path]::DirectorySeparatorChar
if ($test) { $vt = $env:PC_TEST_HELPER_VT } else { $vt = Join-Path (Join-Path $env:USERPROFILE 'Downloads') 'voidsworn_test' }
$vt = [IO.Path]::GetFullPath($vt).TrimEnd('\', '/')
$mirror = Join-Path $vt 'repo-mirror.git'
$source = 'https://github.com/rcbailey12/voidsworn'
if ($test) { $source = $env:PC_TEST_SOURCE }
$gitExe = 'git.exe'; if ($unix) { $gitExe = @(Get-Command git -CommandType Application)[0].Source }
function Run-Git {
  # PowerShell 5.1 turns native stderr into errors under 'Stop'; read it as text instead.
  $ErrorActionPreference = 'Continue'
  $out = & $gitExe @args 2>&1 | ForEach-Object { "$_" }
  if ($LASTEXITCODE -ne 0) { throw ('git failed: ' + ($args -join ' ') + ': ' + ($out -join ' ')) }; $out }
function Hash($path) { (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant() }

switch ($Action) {
  'live' {
    $here = [IO.Path]::GetFullPath($A).TrimEnd('\', '/')
    $live = (Join-Path $vt 'tools_live') + $sep
    if (-not $here.StartsWith($live, [StringComparison]::OrdinalIgnoreCase)) { throw "not a tools_live copy: $here" }
    Write-Output "head runs from tools_live: $here"
  }
  'watchdog' {
    foreach ($name in @('tmo.bat', 'run_timeout.ps1')) {
      $path = Join-Path $A $name
      if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "no watchdog file $path" }
      Write-Output "watchdog $(Hash $path) $path"
    }
  }
  'checkout' {
    if ($C -notmatch '\A[0-9a-f]{40}\z') { throw "a pin must be a full 40-character commit, got: $C" }
    if ($B -notmatch '\A[A-Za-z0-9_-]{1,40}\z') { throw "checkout name not accepted: $B" }
    $attempt = [IO.Path]::GetFullPath($A).TrimEnd('\', '/')
    if (-not $attempt.StartsWith($vt + $sep, [StringComparison]::OrdinalIgnoreCase)) { throw "attempt folder must be under $vt" }
    $repo = Join-Path $attempt $B
    if (Test-Path -LiteralPath $repo) { throw "checkout $repo already exists; every attempt gets a new folder" }
    $lock = $null; $deadline = [DateTime]::UtcNow.AddMinutes(30)
    while (-not $lock) {
      try { $lock = [IO.File]::Open($mirror + '.lock', 'OpenOrCreate', 'ReadWrite', 'None') }
      catch [IO.IOException] { if ([DateTime]::UtcNow -ge $deadline) { throw 'shared repo copy stayed locked for 30 minutes' }; Start-Sleep -Milliseconds 500 }
    }
    try {
      if (-not (Test-Path -LiteralPath (Join-Path $mirror 'HEAD'))) { Run-Git init -q --bare $mirror | Out-Null; Run-Git --git-dir $mirror remote add --mirror=fetch origin $source | Out-Null }
      if ((Run-Git --git-dir $mirror config --get remote.origin.url) -ne $source) { throw 'shared repo copy has an unexpected origin; kept unchanged' }
      $ErrorActionPreference = 'Continue'
      & $gitExe --git-dir $mirror cat-file -e "$C^{commit}" 2>$null
      $have = $LASTEXITCODE -eq 0
      $ErrorActionPreference = 'Stop'
      if (-not $have) {
        Write-Output "fetching the shared mirror for $C"
        Run-Git --git-dir $mirror -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 fetch -q --prune origin | Out-Null
        Run-Git --git-dir $mirror symbolic-ref HEAD refs/heads/main | Out-Null
      }
      Run-Git --git-dir $mirror cat-file -e "$C^{commit}" | Out-Null
      Run-Git -c core.autocrlf=false clone --local -q --no-checkout $mirror $repo | Out-Null
    } finally { $lock.Dispose() }
    Run-Git -C $repo -c core.autocrlf=false -c advice.detachedHead=false checkout -q --detach $C | Out-Null
    $head = (Run-Git -C $repo rev-parse HEAD) | Select-Object -Last 1
    if ($head -ne $C) { throw "checkout $repo is at $head, not the pin $C" }
    Write-Output "checkout $B $C $repo"
  }
  'tracked' {
    $changed = @(Run-Git -C $A status --porcelain --untracked-files=no | Where-Object { $_ })
    if ($changed.Count) { $changed | ForEach-Object { Write-Output "tracked change: $_" }; throw "$($changed.Count) tracked file(s) differ from the pin in $A" }
    Write-Output "tracked files match the pin: $A"
  }
  'hashes' {
    if ($test) { $realu = $env:PC_TEST_REALU } else { $realu = Join-Path $env:APPDATA 'Godot\app_userdata\Voidsworn' }
    $lines = foreach ($f in 'battle_opts.json', 'board_look.cfg') {
      $p = Join-Path $realu $f
      if (Test-Path -LiteralPath $p) { (Hash $p) + ' ' + $f } else { 'absent ' + $f }
    }
    [IO.File]::WriteAllLines($A, [string[]]$lines)
  }
}
