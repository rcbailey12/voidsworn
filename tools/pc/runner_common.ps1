# Shared PC runner steps (issue 687). PowerShell 5.1. No model calls except preflight.
# init <out> <branch>; wait <out>; checkout <repo> <out> <branch> <sparse>;
# preflight <out> <repo> <opencode|kimi|codex> <exe> <model> <variant>;
# finish <out> <exit> <partial> <push mode> <checks ok>.
$ErrorActionPreference = 'Stop'
$mode = $args[0]
$utf8 = New-Object Text.UTF8Encoding($false)
$test = $env:PC_RUNNER_TEST -eq '1'
function Put($path, $value) { [IO.File]::WriteAllText($path, [string]$value, $utf8) }
function Read($path) { if (Test-Path -LiteralPath $path) { return [IO.File]::ReadAllText($path).Trim() }; return '' }
function Log($line) { Add-Content -LiteralPath (Join-Path $script:out 'result.txt') -Value $line -Encoding UTF8; Write-Host $line }
function State($status, $reason) {
  $p = Join-Path $script:out 'status.json'
  $s = Get-Content -LiteralPath $p -Raw | ConvertFrom-Json
  $s.status = $status; $s.reason = $reason
  $s.finished = if ($status -eq 'running') { '' } else { [DateTime]::UtcNow.ToString('o') }
  $s.commit = Read (Join-Path $script:out 'run_commit.txt')
  # Replace in place atomically so a waiter never sees half a JSON document.
  $tmp = "$p.$([guid]::NewGuid().ToString('N')).tmp"
  Put $tmp ($s | ConvertTo-Json)
  [IO.File]::Replace($tmp, $p, "$tmp.previous")
}
function Git([string[]]$words) {
  $ea = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  $exe = 'git'; if ($test -and $env:PC_TEST_GIT) { $exe = $env:PC_TEST_GIT }
  $lines = @(& $exe @words 2>&1); $script:gitExit = $LASTEXITCODE
  $ErrorActionPreference = $ea
  foreach ($line in $lines) { Add-Content -LiteralPath (Join-Path $script:out 'git_log.txt') -Value ([string]$line) -Encoding UTF8 }
  return @($lines | ForEach-Object { [string]$_ })
}
function Must-Git([string[]]$words) {
  $null = Git $words
  if ($script:gitExit -ne 0) { throw "git $($words[0]) failed (exit $script:gitExit); see git_log.txt" }
}
function Retry-Git($label, [string[]]$words) {
  $delay = 120
  if ($test -and $env:PC_TEST_RETRY_SECONDS) { $delay = [int]$env:PC_TEST_RETRY_SECONDS }
  for ($attempt = 1; $attempt -le 3; $attempt++) {
    Log "$label attempt $attempt/3"
    $null = Git $words
    if ($script:gitExit -eq 0) { return }
    if ($attempt -lt 3) { Log "$label failed (exit $script:gitExit); retry in $delay seconds"; Start-Sleep -Seconds $delay }
  }
  throw "$label failed after 3 attempts; see git_log.txt"
}
function Keep-Repo($repo, $tag) {
  if (-not (Test-Path -LiteralPath $repo)) { return }
  $full = [IO.Path]::GetFullPath($repo).TrimEnd('\')
  if ([IO.Path]::GetFileName($full) -ne 'repo') { throw "refusing to rename unexpected checkout path $full" }
  $name = "repo-$tag-$([guid]::NewGuid().ToString('N'))"
  Rename-Item -LiteralPath $full -NewName $name
  Log "earlier checkout kept beside repo as $name"
}
# Windows command line quoting, including trailing backslashes. Inputs are argument values, never shell snippets.
function Quote($value) { return '"' + ([regex]::Replace(([string]$value), '(\\*)"', '$1$1\"') -replace '(\\+)$', '$1$1') + '"' }
try {
  if ($mode -eq 'init') {
    $script:out = $args[1]
    $s = @{ run = [guid]::NewGuid().ToString('N'); branch = $args[2]; status = 'running'; reason = ''; commit = ''; started = [DateTime]::UtcNow.ToString('o'); finished = '' }
    Put (Join-Path $out 'status.json') ($s | ConvertTo-Json)
    # Old run metadata must never turn a later failure into success or claim an old resume.
    foreach ($f in @('resume.txt','run_commit.txt','confirmed_commit.txt','partial.txt','checks_node.txt','checks_parity.txt')) { Put (Join-Path $out $f) '' }
  }
  elseif ($mode -eq 'wait') {
    $script:out = $args[1]
    if (-not $env:PC_WAIT_FOR) { exit 0 }
    $p = $env:PC_WAIT_FOR
    if (Test-Path -LiteralPath $p -PathType Container) { $p = Join-Path $p 'status.json' }
    if ([IO.Path]::GetFullPath($p) -eq [IO.Path]::GetFullPath((Join-Path $out 'status.json'))) { throw 'chain stopped: a job cannot wait for itself' }
    $limit = 43200; if ($env:PC_WAIT_SECONDS) { $limit = [int]$env:PC_WAIT_SECONDS }
    $end = [DateTime]::UtcNow.AddSeconds($limit)
    Log "chain waiting for $p"
    $run = ''
    while ($true) {
      if (-not (Test-Path -LiteralPath $p)) { throw 'chain stopped: predecessor status.json is missing; text results cannot prove a checked push' }
      $s = Get-Content -LiteralPath $p -Raw | ConvertFrom-Json
      if (-not $run) { $run = $s.run }
      if (-not $run -or $run -ne $s.run) { throw 'chain stopped: predecessor run changed while waiting' }
      if ($env:PC_WAIT_RUN -and $s.run -ne $env:PC_WAIT_RUN) { throw 'chain stopped: predecessor run id does not match PC_WAIT_RUN' }
      if ($s.status -eq 'checked_push' -and $s.commit -match '^[0-9a-f]{40,64}$') { Log "chain released: checked push $($s.branch) $($s.commit)"; exit 0 }
      if ($s.status -ne 'running') { throw "chain stopped: predecessor ended $($s.status): $($s.reason)" }
      if ([DateTime]::UtcNow -ge $end) { throw 'chain stopped: predecessor did not finish before the wait limit' }
      Start-Sleep -Milliseconds 500
    }
  }
  elseif ($mode -eq 'checkout') {
    $repo = $args[1]; $script:out = $args[2]; $br = $args[3]; $sparse = $args[4]
    $source = 'https://github.com/rcbailey12/voidsworn'
    $mirror = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test\repo-mirror.git'
    if ($test) {
      if (-not $env:PC_TEST_SOURCE -or -not $env:PC_TEST_MIRROR) { throw 'test checkout requires PC_TEST_SOURCE and PC_TEST_MIRROR (no live network)' }
      $source = $env:PC_TEST_SOURCE; $mirror = $env:PC_TEST_MIRROR
    }
    $parent = Split-Path -Parent $mirror
    $null = New-Item -ItemType Directory -Force -Path $parent
    $lock = $null; $deadline = [DateTime]::UtcNow.AddMinutes(30); $said = $false
    while (-not $lock) {
      try { $lock = [IO.File]::Open("$mirror.lock", 'OpenOrCreate', 'ReadWrite', 'None') }
      catch [IO.IOException] {
        if (-not $said) { Log 'waiting for the shared repo copy'; $said = $true }
        if ([DateTime]::UtcNow -ge $deadline) { throw 'shared repo copy stayed locked for 30 minutes' }
        Start-Sleep -Milliseconds 500
      }
    }
    try {
      if (-not (Test-Path -LiteralPath (Join-Path $mirror 'HEAD'))) {
        Must-Git @('init','--bare',$mirror)
        Must-Git @('--git-dir',$mirror,'remote','add','--mirror=fetch','origin',$source)
      }
      $url = @(Git @('--git-dir',$mirror,'remote','get-url','origin'))
      if ($gitExit -ne 0 -or $url[0] -ne $source) { throw 'shared repo copy has an unexpected origin; kept unchanged' }
      Retry-Git 'mirror fetch' @('--git-dir',$mirror,'-c','http.lowSpeedLimit=1000','-c','http.lowSpeedTime=60','fetch','--prune','origin')
      # The remote default branch may not yet be set by init --bare.
      Must-Git @('--git-dir',$mirror,'symbolic-ref','HEAD','refs/heads/main')
      Keep-Repo $repo 'kept'
      $delay = 120; if ($test -and $env:PC_TEST_RETRY_SECONDS) { $delay = [int]$env:PC_TEST_RETRY_SECONDS }
      for ($attempt = 1; $attempt -le 3; $attempt++) {
        Log "local clone attempt $attempt/3"
        $null = Git @('clone','-q','-c','core.autocrlf=false','--local','--no-checkout',$mirror,$repo)
        if ($gitExit -eq 0) { break }
        Keep-Repo $repo 'clone-failed'
        if ($attempt -eq 3) { throw 'local clone failed after 3 attempts; see git_log.txt' }
        Log "local clone failed; retry in $delay seconds"; Start-Sleep -Seconds $delay
      }
    } finally { $lock.Dispose() }
    # Local hardlinks share immutable objects without alternates. All pushes go to GitHub, never to the mirror.
    Must-Git @('-C',$repo,'remote','set-url','origin',$source)
    if ($sparse) { Must-Git (@('-C',$repo,'sparse-checkout','set','--no-cone') + @($sparse -split '\s+')) }
    Must-Git @('-C',$repo,'checkout','-q','-B',$br,'refs/remotes/origin/main')
    $base = @(Git @('-C',$repo,'rev-parse','HEAD'))[0]
    Put (Join-Path $out 'base_commit.txt') $base
    $partial = "refs/remotes/origin/$br-partial"
    $tip = @(Git @('-C',$repo,'rev-parse','--verify','--quiet',$partial))
    if ($gitExit -eq 0) {
      Log "resuming $br-partial at $($tip[0])"
      # Full mirror history makes the merge base available. A conflict stays on disk and stops before the model.
      $null = Git @('-C',$repo,'merge','--no-edit',$partial)
      if ($gitExit -ne 0) { throw "resume merge failed for $br-partial; checkout and conflict kept; no agent started" }
      Put (Join-Path $out 'resume.txt') "Resumed by merging $br-partial ($($tip[0])). Inspect and finish this work; do not restart it from main."
    }
  }
  elseif ($mode -eq 'fetch') {
    $repo = $args[1]; $script:out = $args[2]
    Retry-Git 'branch fetch' @('-C',$repo,'fetch','-q','origin',$args[3])
  }
  elseif ($mode -eq 'preflight') {
    $script:out = $args[1]; $repo = $args[2]; $kind = $args[3]; $exe = $args[4]; $model = $args[5]; $variant = $args[6]
    $probe = Join-Path $out 'preflight'; $null = New-Item -ItemType Directory -Force -Path $probe
    $prompt = 'Reply with exactly RUNNER_READY. Do not use tools or read any files.'
    switch ($kind) {
      'opencode' { $words = @('run','--auto','--format','json','-m',$model,'--dir',$probe); if ($variant) { $words += @('--variant',($variant -replace '^--variant\s+','')) }; $words += $prompt }
      'kimi' { $words = @('-m',$model,'--output-format','text','-p',$prompt) }
      'codex' { $words = @('exec','-m','gpt-6.1-sol','-c','model_reasoning_effort=low','--ephemeral','--skip-git-repo-check','--color','never','-C',$probe,'-o',(Join-Path $probe 'reply.txt'),$prompt) }
      default { throw "unknown preflight harness $kind" }
    }
    if ($test -and $env:PC_TEST_PREFLIGHT) { $exe = $env:PC_TEST_PREFLIGHT }
    Log "preflight: $kind $model"
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = $exe; $psi.Arguments = ($words | ForEach-Object { Quote $_ }) -join ' '
    if ($exe -match '\.(cmd|bat)$') { $psi.FileName = $env:COMSPEC; $psi.Arguments = '/d /s /c ""' + $exe + '" ' + $psi.Arguments + '"' }
    $psi.WorkingDirectory = $probe; $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $p = New-Object Diagnostics.Process; $p.StartInfo = $psi
    $null = $p.Start(); $stdout = $p.StandardOutput.ReadToEndAsync(); $stderr = $p.StandardError.ReadToEndAsync()
    $cap = 90; if ($test -and $env:PC_TEST_PREFLIGHT_SECONDS) { $cap = [int]$env:PC_TEST_PREFLIGHT_SECONDS }
    if (-not $p.WaitForExit($cap * 1000)) {
      & taskkill.exe /PID $p.Id /T /F | Out-Null; $p.WaitForExit()
      Put (Join-Path $out 'preflight_log.txt') ($stdout.Result + "`n" + $stderr.Result)
      throw "preflight failed: $kind timed out after $cap seconds"
    }
    $p.WaitForExit(); $code = $p.ExitCode
    $raw = $stdout.Result + "`n" + $stderr.Result
    Put (Join-Path $out 'preflight_log.txt') $raw
    $reply = Read (Join-Path $probe 'reply.txt')
    if ($kind -eq 'kimi') { $reply = $stdout.Result.Trim() }
    if ($kind -eq 'opencode') {
      $reply = ''
      foreach ($line in ($stdout.Result -split '\r?\n')) {
        try { $ev = $line | ConvertFrom-Json; if ($ev.type -eq 'text') { $reply += [string]$ev.part.text } } catch { }
      }
    }
    $problem = @($raw -split '\r?\n' | Where-Object { $_ -match '(?i)"type"\s*:\s*"error"|"is_error"\s*:\s*true|credit balance|no credential|not logged|unauthori[sz]ed|quota|rate.limit|expired|error:|"error"\s*:' } | Select-Object -Last 1)
    if ($code -ne 0 -or $problem.Count -or $reply.Trim() -ne 'RUNNER_READY') {
      $why = if ($problem.Count) { $problem[0] } else { @($raw -split '\r?\n' | Where-Object { $_.Trim() } | Select-Object -Last 1) -join '' }
      $why = ($why -replace '\s+',' ').Trim(); if ($why.Length -gt 350) { $why = $why.Substring(0,350) }
      throw "preflight failed: $kind exit $code; $why (see preflight_log.txt)"
    }
    Log "preflight passed: $kind $model"
  }
  elseif ($mode -eq 'finish') {
    $script:out = $args[1]; $code = $args[2]; $partial = $args[3]; $push = $args[4]; $checks = $args[5]
    $old = Get-Content -LiteralPath (Join-Path $out 'status.json') -Raw | ConvertFrom-Json
    $status = 'failed'; $reason = "runner exit $code"
    if ($old.status -eq 'failed' -and $old.reason) { $reason = $old.reason }
    if ($code -eq '0' -and -not $partial) {
      $commit = Read (Join-Path $out 'run_commit.txt')
      $confirmed = Read (Join-Path $out 'confirmed_commit.txt')
      if ($push -eq 'real' -and $checks -eq '1' -and $commit -match '^[0-9a-f]{40,64}$' -and $confirmed -eq $commit) { $status = 'checked_push'; $reason = 'non-partial push confirmed and runner checks passed' }
      else { $status = 'unverified'; $reason = 'dry/test push or checks did not pass; chain stays stopped' }
    }
    elseif ($partial) { $status = 'partial'; $reason = $partial }
    elseif ($code -eq '7') { $status = 'no_changes'; $reason = 'no changes pushed' }
    State $status $reason
    Log "runner status: $status ($reason)"
  }
  else { throw "unknown runner step $mode" }
} catch {
  if ($script:out) { Log $_.Exception.Message; if (Test-Path (Join-Path $out 'status.json')) { State 'failed' $_.Exception.Message } }
  else { Write-Host $_.Exception.Message }
  exit 14
}
