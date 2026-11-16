# Shared PC runner steps (issue 687; issue 722 adds space, hashwrite, hashcheck and model). PowerShell 5.1.
# No model calls except preflight.
# init <out> <branch>; wait <out>; checkout <repo> <out> <branch> <sparse>;
# preflight <out> <repo> <opencode|kimi|codex> <exe> <model> <variant>;
# finish <out> <exit> <partial> <push mode> <checks ok>.
# space <out> <settings file> <target path>: refuse to start when the target's drive has less than min_free_gb
#   (default 60) free; one line in result.txt, status failed. Test knobs: PC_TEST_SETTINGS, PC_TEST_SPACE_FREE_MB.
# hashwrite <tools dir> <hash file>: the Board writes SHA-256 of the runner and watchdog files after copying them.
# hashcheck <out> <tools dir> <hash file>: warn in result.txt when the running copies differ (warn, never stop).
#   Test knob: PC_TEST_HASHES.
# model <out> <resolved> <default>: stamp the resolved model into status.json and result.txt, and warn when it
#   differs from the arm default, whatever the provider.
# base <repo> <out> <issue body file>: parse the optional Base line, fetch and commit its merge before the agent.
# announce <out> <issue> <seat> <repo> <ceiling seconds> <resume command> <push mode>: best-effort GitHub status.
# Test announcements require PC_TEST_GH; dry runs never contact GitHub. Linux probes use pwsh and real git.
$ErrorActionPreference = 'Stop'
$mode = $args[0]
$utf8 = New-Object Text.UTF8Encoding($false)
$test = $env:PC_RUNNER_TEST -eq '1'
function Put($path, $value) { [IO.File]::WriteAllText($path, [string]$value, $utf8) }
function Read($path) { if (Test-Path -LiteralPath $path) { return [IO.File]::ReadAllText($path).Trim() }; return '' }
# result.txt may be held open by the .bat that redirects a step's output into it (work_issue.ps1 commit runs under
# '>> result.txt' and calls 'fetch' here): then Write-Host alone reaches result.txt through that redirect. Never throw
# from Log: on Nov 15 the lock made the earlier-tip fetch report failure and stopped Kimi 371's push.
function Log($line) {
  try { Add-Content -LiteralPath (Join-Path $script:out 'result.txt') -Value $line -Encoding UTF8 -ErrorAction Stop } catch { }
  Write-Host $line
}
function State($status, $reason) {
  $p = Join-Path $script:out 'status.json'
  $s = Get-Content -LiteralPath $p -Raw | ConvertFrom-Json
  $s.status = $status; $s.reason = $reason
  $s.finished = if ($status -eq 'running') { '' } else { [DateTime]::UtcNow.ToString('o') }
  $s.commit = Read (Join-Path $script:out 'run_commit.txt')
  Save-State $s
}
function Save-State($s) {
  $p = Join-Path $script:out 'status.json'
  # Replace in place atomically so a waiter never sees half a JSON document.
  $tmp = "$p.$([guid]::NewGuid().ToString('N')).tmp"
  Put $tmp ($s | ConvertTo-Json)
  [IO.File]::Replace($tmp, $p, "$tmp.previous")
}
function Git([string[]]$words) {
  $ea = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  # 'git.exe', never 'git': PowerShell finds this Git function before the program, so 'git' called itself until the
  # call depth overflowed (first live run, Nov 15). The test stub path never hit it.
  $exe = 'git.exe'; if ($PSVersionTable.Platform -eq 'Unix') { $exe = @(Get-Command git -CommandType Application -ErrorAction Stop)[0].Source }
  if ($test -and $env:PC_TEST_GIT) { $exe = $env:PC_TEST_GIT }
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
# GitHub is reporting only: neither a missing gh nor an API, JSON or file error may stop a run.
function Invoke-Gh($method, $endpoint, $payload = $null, $pages = $false) {
  $script:ghOK = $false
  try {
    $exe = 'gh'
    if ($test) {
      if (-not $env:PC_TEST_GH) { Log 'GitHub status skipped: test has no fake gh'; return '' }
      $exe = $env:PC_TEST_GH
    }
    $null = Get-Command $exe -ErrorAction Stop
    $words = @('api','--method',$method,"repos/rcbailey12/voidsworn/$endpoint")
    if ($pages) { $words += @('--paginate','--slurp') }
    if ($null -ne $payload) {
      $file = Join-Path $out 'github_payload.json'
      Put $file ($payload | ConvertTo-Json -Depth 8)
      $words += @('--input',$file)
    }
    $ea = $ErrorActionPreference
    try {
      $ErrorActionPreference = 'Continue'
      $lines = @(& $exe @words 2>&1); $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $ea }
    if ($code -ne 0) { throw "exit $code $($lines -join ' ')" }
    $script:ghOK = $true
    return ($lines -join "`n")
  } catch { Log "WARNING: GitHub status $method $endpoint failed: $($_.Exception.Message)"; return '' }
}
function Status-Body($s, $label, $reason) {
  $g = $s.github
  $branch = $s.branch
  if ($label -eq 'partial') { $branch += '-partial' }
  $commit = $s.commit; if (-not $commit) { $commit = $g.start_commit }
  return @"
$($g.marker)
Runner status: $label

- Seat: $($g.seat)
- Machine: $($g.machine)
- Lane folder: $($g.folder)
- Branch: $branch
- Started (UTC): $($g.started)
- Ceiling: $($g.ceiling) seconds
- Last commit: $commit
- How to resume: $($g.resume)
- Finished (UTC): $($s.finished)
- Result: $reason
"@
}
function End-Announcement($s, $code) {
  if (-not $s.github) { return }
  try {
    $g = $s.github
    $label = 'failed'
    if ($code -eq '0' -and $s.status -in @('checked_push','unverified')) { $label = 'finished' }
    if ($s.status -eq 'partial') { $label = 'partial' }
    if ($g.comment) { $null = Invoke-Gh 'PATCH' "issues/comments/$($g.comment)" @{ body = (Status-Body $s $label $s.reason) } }
  } catch { Log "WARNING: GitHub final comment failed: $($_.Exception.Message)" }
  # Clearing the label must still be attempted when editing the comment fails.
  $null = Invoke-Gh 'DELETE' "issues/$($s.github.issue)/labels/running"
}
try {
  if ($mode -eq 'init') {
    $script:out = $args[1]
    $s = @{ run = [guid]::NewGuid().ToString('N'); branch = $args[2]; status = 'running'; reason = ''; commit = ''; started = [DateTime]::UtcNow.ToString('o'); finished = '' }
    Put (Join-Path $out 'status.json') ($s | ConvertTo-Json)
    # Old run metadata must never turn a later failure into success or claim an old resume.
    foreach ($f in @('resume.txt','stop_reason.txt','run_commit.txt','confirmed_commit.txt','partial.txt','checks_node.txt','checks_parity.txt')) { Put (Join-Path $out $f) '' }
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
      $resume = "Resumed by merging $br-partial ($($tip[0])). Inspect and finish this work; do not restart it from main."
      $message = (Git @('-C',$repo,'log','-1','--format=%B',$partial)) -join "`n"
      $note = [regex]::Match($message, '(?ms)^## Runner resume note \(issue 818\)\r?\n.*?^## End runner resume note')
      if ($note.Success) { $resume += "`n`n" + $note.Value }
      Put (Join-Path $out 'resume.txt') $resume
    }
  }
  elseif ($mode -eq 'base') {
    $repo = $args[1]; $script:out = $args[2]
    $body = [IO.File]::ReadAllText($args[3])
    $lines = [regex]::Matches($body, '(?im)^[ \t]*Base:[ \t]*([^\r\n]*)')
    if ($lines.Count -eq 0) { exit 0 }
    if ($lines.Count -ne 1) { throw 'Base merge stopped: use one Base: <branch> line; no agent started' }
    $base = $lines[0].Groups[1].Value.Trim()
    $null = Git @('check-ref-format',"refs/heads/$base")
    if (-not $base -or $gitExit -ne 0) { throw "Base merge stopped: invalid branch '$base'; no agent started" }
    Log "Base: fetching and merging origin/$base before the agent"
    Retry-Git 'Base fetch' @('-C',$repo,'fetch','--no-tags','origin',"+refs/heads/${base}:refs/remotes/origin/$base")
    $tip = @(Git @('-C',$repo,'rev-parse',"refs/remotes/origin/$base"))[0]
    # --no-ff makes the runner commit a real merge even when a fast-forward is possible. No editor or signing prompt.
    $null = Git @('-C',$repo,'-c','commit.gpgsign=false','merge','--no-ff','--no-edit','--no-gpg-sign','-m',"Runner Base: origin/$base", "refs/remotes/origin/$base")
    if ($gitExit -ne 0) { throw "Base merge failed for origin/$base; checkout and conflict kept; no agent started (see git_log.txt)" }
    $note = "Base already merged by the runner: origin/$base ($tip). The merge is committed; do not merge it yourself."
    $resume = Read (Join-Path $out 'resume.txt')
    Put (Join-Path $out 'resume.txt') ("$resume`n$note".Trim())
    Log $note
  }
  elseif ($mode -eq 'announce') {
    $script:out = $args[1]
    # Real dry runs must never label or comment on real issues. Test runs can only call their fake gh.
    if ($args[7] -ne 'real' -and -not ($test -and $env:PC_TEST_GH)) { exit 0 }
    try {
      $s = Get-Content -LiteralPath (Join-Path $out 'status.json') -Raw | ConvertFrom-Json
      $repo = $args[4]
      $head = @(Git @('-C',$repo,'rev-parse','HEAD')) -join ''
      $g = @{ issue = $args[2]; seat = $args[3]; folder = $repo; machine = [Environment]::MachineName;
        started = [DateTime]::UtcNow.ToString('o'); ceiling = $args[5]; resume = $args[6]; comment = 0;
        start_commit = $head; marker = "<!-- voidsworn-runner-status branch=$($s.branch) -->" }
      $s | Add-Member -NotePropertyName github -NotePropertyValue $g -Force
      Save-State $s
      $null = Invoke-Gh 'GET' 'labels/running'
      if (-not $ghOK) { $null = Invoke-Gh 'POST' 'labels' @{ name = 'running'; color = '1D76DB'; description = 'An agent is working this issue' } }
      $null = Invoke-Gh 'POST' "issues/$($g.issue)/labels" @{ labels = @('running') }
      # Reuse this branch's comment on retries instead of adding a new comment every run.
      $raw = Invoke-Gh 'GET' "issues/$($g.issue)/comments?per_page=100" $null $true
      if ($ghOK) {
        foreach ($page in (ConvertFrom-Json $raw)) {
          foreach ($comment in $page) { if ([string]$comment.body -like "$($g.marker)*") { $g.comment = $comment.id } }
        }
        $payload = @{ body = (Status-Body $s 'running' 'agent started') }
        if ($g.comment) { $null = Invoke-Gh 'PATCH' "issues/comments/$($g.comment)" $payload }
        else {
          $raw = Invoke-Gh 'POST' "issues/$($g.issue)/comments" $payload
          if ($ghOK) { $g.comment = (ConvertFrom-Json $raw).id }
        }
        Save-State $s
      }
    } catch { Log "WARNING: GitHub start status failed: $($_.Exception.Message)" }
    exit 0
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
    if ($kind -eq 'kimi') {
      # Kimi Code prints its thinking and its answer as bullet lines, then a 'To resume this session' line (first live run,
      # Nov 15): the reply is the answer line, bullet stripped.
      $reply = ''
      foreach ($line in ($stdout.Result -split '\r?\n')) { $t = ($line -replace '^[^A-Za-z0-9_]+','').Trim(); if ($t -eq 'RUNNER_READY') { $reply = $t } }
    }
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
  elseif ($mode -eq 'space') {
    # Issue 722 (audit 706 finding 7): never start a run the disk cannot hold. Runs before the chain wait, so a
    # low disk also fails a chained child closed instead of burning a wait.
    $script:out = $args[1]; $setf = $args[2]; $target = $args[3]
    if ($test -and $env:PC_TEST_SETTINGS) { $setf = $env:PC_TEST_SETTINGS }
    $floor = 60
    if (Test-Path -LiteralPath $setf) {
      foreach ($l in [IO.File]::ReadAllLines($setf)) {
        $m = [regex]::Match($l, '^\s*min_free_gb\s*=\s*(\d+)\s*$')
        if ($m.Success) { $floor = [int]$m.Groups[1].Value }
      }
    }
    $root = [IO.Path]::GetPathRoot([IO.Path]::GetFullPath($target)).TrimEnd('\')
    $free = (New-Object IO.DriveInfo($root)).AvailableFreeSpace
    if ($test -and $env:PC_TEST_SPACE_FREE_MB) { $free = [int64]$env:PC_TEST_SPACE_FREE_MB * 1MB }
    $freeGB = [math]::Round($free / 1GB, 1)
    if ($free -lt ($floor * 1GB)) {
      $why = "refusing to start: drive $root has $freeGB GB free, below the min_free_gb=$floor floor"
      Log $why
      State 'failed' $why
      exit 14
    }
    Log "drive $root has $freeGB GB free (min_free_gb floor $floor)"
  }
  elseif ($mode -eq 'hashwrite') {
    # The Board runs this right after copying the runner files to a PC tools folder; hashcheck then guards the copies.
    $tools = $args[1]; $hashf = $args[2]
    $names = @('codex_issue.bat','codex_issue.ps1','runner_common.ps1','work_issue.bat','work_issue.ps1','run_timeout.ps1','tmo.bat','gpu_slots.js')
    $lines = @()
    foreach ($n in $names) {
      $p = Join-Path $tools $n
      if (-not (Test-Path -LiteralPath $p)) { throw "hashwrite: $p is missing" }
      $lines += ((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLower() + "  $n")
    }
    Put $hashf (($lines -join "`n") + "`n")
    Write-Host "hashes written to $hashf ($($names.Count) files)"
  }
  elseif ($mode -eq 'hashcheck') {
    # Issue 722 (audit 706 finding 6): the running copies must be what the Board copied. A drift or a missing
    # hashes file is a warning only: a run must never stop because the Board has not written hashes yet.
    $script:out = $args[1]; $tools = $args[2]; $hashf = $args[3]
    if ($test -and $env:PC_TEST_HASHES) { $hashf = $env:PC_TEST_HASHES }
    if (-not (Test-Path -LiteralPath $hashf)) {
      Log "WARNING: no Board hashes file at $hashf; the running runner copies are not checked"
      exit 0
    }
    $want = @{}
    foreach ($l in [IO.File]::ReadAllLines($hashf)) {
      $m = [regex]::Match($l, '^([0-9a-fA-F]{64})\s+(\S+)\s*$')
      if ($m.Success) { $want[$m.Groups[2].Value] = $m.Groups[1].Value.ToLower() }
    }
    if ($want.Count -eq 0) { Log "WARNING: the Board hashes file $hashf has no entries; the running runner copies are not checked"; exit 0 }
    $bad = @()
    foreach ($n in ($want.Keys | Sort-Object)) {
      $p = Join-Path $tools $n
      if (-not (Test-Path -LiteralPath $p)) { $bad += "$n (missing)"; continue }
      if ((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLower() -ne $want[$n]) { $bad += $n }
    }
    if ($bad.Count) { Log "WARNING: these runner files differ from the Board-copied hashes: $($bad -join ', ')" }
    else { Log "runner files match the Board hashes ($($want.Count) checked)" }
  }
  elseif ($mode -eq 'model') {
    # Issue 722 (audit 706 finding 6): stamp what will actually run. The bat passes the resolved id and the arm's
    # built-in default, so a same-provider override (the gap the provider guard cannot see) warns here.
    $script:out = $args[1]; $resolved = $args[2]; $default = $args[3]
    $p = Join-Path $script:out 'status.json'
    $s = Get-Content -LiteralPath $p -Raw | ConvertFrom-Json
    $s | Add-Member -NotePropertyName model -NotePropertyValue $resolved -Force
    $tmp = "$p.$([guid]::NewGuid().ToString('N')).tmp"
    Put $tmp ($s | ConvertTo-Json)
    [IO.File]::Replace($tmp, $p, "$tmp.previous")
    Log "model: $resolved"
    if ($resolved -ne $default) { Log "WARNING: resolved model $resolved differs from the arm default $default" }
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
    # State is authoritative; reporting errors never change it or the runner exit code.
    $s = Get-Content -LiteralPath (Join-Path $out 'status.json') -Raw | ConvertFrom-Json
    End-Announcement $s $code
    exit 0
  }
  else { throw "unknown runner step $mode" }
} catch {
  if ($script:out) { Log $_.Exception.Message; if (Test-Path (Join-Path $out 'status.json')) { State 'failed' $_.Exception.Message } }
  else { Write-Host $_.Exception.Message }
  exit 14
}
