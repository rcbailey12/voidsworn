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
# announce <out> <issue> <seat> <repo> <ceiling seconds> <resume command> <push mode>: validate and claim before work.
# board-dryrun <out>: list ACCEPT or REFUSE for every open codex, muse or opus issue, without claims or agent calls.
# Test claims require PC_TEST_GH and PC_TEST_GH_DB; real dry runs validate read-only. Linux probes use pwsh and real git.
$ErrorActionPreference = 'Stop'
$mode = $args[0]
$utf8 = New-Object Text.UTF8Encoding($false)
$test = $env:PC_RUNNER_TEST -eq '1'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
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
  # Writing the log must never fail the job (Nov 16: four starts died when another process briefly held git_log.txt,
  # 'The process cannot access the file because it is being used by another process'). One append, retried, never thrown.
  $gl = Join-Path $script:out 'git_log.txt'; $text = (@($lines | ForEach-Object { [string]$_ }) -join "`r`n")
  if ($text) { for ($t = 0; $t -lt 40; $t++) { try { [IO.File]::AppendAllText($gl, $text + "`r`n", (New-Object Text.UTF8Encoding($false))); break } catch { Start-Sleep -Milliseconds 500 } } }
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
# Restart Manager can name file holders without installing handle.exe. It cannot report directory-only handles,
# and access may be denied in a sandbox; diagnostics must never prevent the preservation retry.
function Get-RepoHolders($full) {
  try {
    if (-not ('RunnerFileHolders' -as [type])) {
      Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
public static class RunnerFileHolders {
  [StructLayout(LayoutKind.Sequential)] public struct UniqueProcess {
    public uint id; public System.Runtime.InteropServices.ComTypes.FILETIME started;
  }
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] public struct Info {
    public UniqueProcess process;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)] public string name;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 64)] public string service;
    public uint type, status, session;
    [MarshalAs(UnmanagedType.Bool)] public bool restartable;
  }
  [DllImport("rstrtmgr.dll", CharSet = CharSet.Unicode)] static extern int RmStartSession(out uint session, uint flags, StringBuilder key);
  [DllImport("rstrtmgr.dll", CharSet = CharSet.Unicode)] static extern int RmRegisterResources(uint session, uint files, string[] names, uint apps, IntPtr processes, uint services, IntPtr serviceNames);
  [DllImport("rstrtmgr.dll")] static extern int RmGetList(uint session, out uint needed, ref uint count, [In, Out] Info[] info, ref uint reasons);
  [DllImport("rstrtmgr.dll")] static extern int RmEndSession(uint session);
  public static Info[] Find(string[] paths) {
    uint session; int error = RmStartSession(out session, 0, new StringBuilder(33));
    if (error != 0) throw new Win32Exception(error);
    try {
      error = RmRegisterResources(session, (uint)paths.Length, paths, 0, IntPtr.Zero, 0, IntPtr.Zero);
      if (error != 0) throw new Win32Exception(error);
      uint needed, count = 0, reasons = 0;
      var info = new Info[0];
      for (int attempt = 0; attempt < 4; attempt++) {
        error = RmGetList(session, out needed, ref count, info, ref reasons);
        if (error == 0) { Array.Resize(ref info, (int)count); return info; }
        if (error != 234) throw new Win32Exception(error);
        count = needed; info = new Info[count];
      }
      throw new Win32Exception(error);
    } finally { RmEndSession(session); }
  }
}
'@
    }
    # Register files, not the directory: RmGetList rejects directories with ERROR_ACCESS_DENIED.
    $files = @(Get-ChildItem -LiteralPath $full -File -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    $gitDir = Join-Path $full '.git'
    if (Test-Path -LiteralPath $gitDir -PathType Container) {
      $files += @(Get-ChildItem -LiteralPath $gitDir -File -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    }
    $holders = @(); if ($files.Count) { $holders = @([RunnerFileHolders]::Find([string[]]$files)) }
    foreach ($holder in $holders) { Log "Windows file holder: PID $($holder.process.id) $($holder.name)" }
  } catch { Log "Windows file holder lookup unavailable: $($_.Exception.Message)" }
  try {
    # Command lines are useful for an agent holding only its current directory. These are candidates, not proof.
    $candidates = @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -and $_.CommandLine.IndexOf($full, [StringComparison]::OrdinalIgnoreCase) -ge 0 })
    foreach ($holder in $candidates) { Log "possible checkout holder: PID $($holder.ProcessId) $($holder.Name): $($holder.CommandLine)" }
    if (-not $holders.Count -and -not $candidates.Count) { Log 'Windows could not name the checkout holder (directory handles may not be reported)' }
  } catch { Log "Windows holder lookup unavailable: $($_.Exception.Message)" }
}
function Keep-Repo($repo, $tag) {
  if (-not (Test-Path -LiteralPath $repo)) { return }
  $full = [IO.Path]::GetFullPath($repo).TrimEnd('\')
  if ([IO.Path]::GetFileName($full) -ne 'repo') { throw "refusing to rename unexpected checkout path $full" }
  $name = "repo-$tag-$([guid]::NewGuid().ToString('N'))"
  $limit = 600.0; $pause = 1000
  if ($test -and $env:PC_TEST_KEEP_SECONDS) { $limit = [double]$env:PC_TEST_KEEP_SECONDS }
  if ($test -and $env:PC_TEST_KEEP_POLL_MS) { $pause = [int]$env:PC_TEST_KEEP_POLL_MS }
  $clock = [Diagnostics.Stopwatch]::StartNew(); $nextLog = 0.0
  while ($true) {
    try { Rename-Item -LiteralPath $full -NewName $name -ErrorAction Stop; break }
    catch {
      $failure = $_.Exception.Message
      if ($clock.Elapsed.TotalSeconds -ge $nextLog) {
        Log "checkout rename held; waiting up to $limit seconds: $full : $failure"
        Get-RepoHolders $full
        $nextLog = $clock.Elapsed.TotalSeconds + 60
      }
      $left = $limit - $clock.Elapsed.TotalSeconds
      if ($left -le 0) { throw "checkout rename still held after $limit seconds; earlier checkout kept at ${full}: $failure" }
      Start-Sleep -Milliseconds ([int][Math]::Min($pause, [Math]::Ceiling($left * 1000)))
    }
  }
  Log "earlier checkout kept beside repo as $name"
}
# Windows command line quoting, including trailing backslashes. Inputs are argument values, never shell snippets.
function Quote($value) { return '"' + ([regex]::Replace(([string]$value), '(\\*)"', '$1$1\"') -replace '(\\+)$', '$1$1') + '"' }
# Final reporting is best effort. Start validation and claiming must fail closed.
function Invoke-Gh($method, $endpoint, $payload = $null, $pages = $false) {
  $script:ghOK = $false
  $script:ghError = ''
  try {
    $exe = 'gh'
    if ($test) {
      if (-not $env:PC_TEST_GH) { Log 'GitHub status skipped: test has no fake gh'; return '' }
      $exe = $env:PC_TEST_GH
    }
    $command = Get-Command $exe -ErrorAction SilentlyContinue
    if (-not $command -and $script:boardReadOnly -and -not $test -and $method -eq 'GET') {
      # The public board audit works before gh is installed. Claims always require authenticated gh.
      $items = @(); $page = 1
      do {
        $url = "https://api.github.com/repos/rcbailey12/voidsworn/$endpoint"
        if ($pages) { $url += "&page=$page" }
        $reply = Invoke-RestMethod -UseBasicParsing -TimeoutSec 30 -Headers @{ 'User-Agent' = 'voidsworn-runner-board-audit' } -Uri $url
        if (-not $pages) { $script:ghOK = $true; return (ConvertTo-Json -InputObject $reply -Depth 30) }
        $items += @($reply); $page++
      } while (@($reply).Count -eq 100)
      $script:ghOK = $true
      return ('[' + (ConvertTo-Json -InputObject @($items) -Depth 30 -Compress) + ']')
    }
    if (-not $command) { throw 'GitHub CLI gh is missing; install it and run gh auth login before starting PC jobs' }
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
  } catch { $script:ghError = $_.Exception.Message; Log "WARNING: GitHub status $method $endpoint failed: $script:ghError"; return '' }
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
- Run: $($s.run)
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
function Require-Gh($method, $endpoint, $payload = $null, $pages = $false) {
  $raw = Invoke-Gh $method $endpoint $payload $pages
  if (-not $script:ghOK) { throw "cannot validate or claim job: $method $endpoint failed ($script:ghError); no agent started" }
  try { return (ConvertFrom-Json $raw) }
  catch { throw "cannot validate or claim job: invalid JSON from $method $endpoint; no agent started" }
}
function Gh-Pages($endpoint) {
  $pages = Require-Gh 'GET' $endpoint $null $true
  foreach ($page in $pages) { foreach ($item in $page) { $item } }
}
function Current-Body($body, $prefix) {
  # A marker is a line, not a heading or an occurrence: bold and plain run lines work too.
  $current = @(); $runs = @(); $fence = ''; $offset = 0
  foreach ($line in ([regex]::Split($body, '(?<=\n)'))) {
    $text = $line.TrimEnd("`r", "`n")
    if ($text -match '^ {0,3}(`{3,}|~{3,})') {
      $mark = $Matches[1]
      if (-not $fence) { $fence = $mark }
      elseif ($mark[0] -eq $fence[0] -and $mark.Length -ge $fence.Length -and $text -match '^ {0,3}(`{3,}|~{3,})[ \t]*$') { $fence = '' }
    } elseif (-not $fence) {
      $entry = @{ start = $offset; end = $offset + $line.Length; text = $text }
      if ($text.Contains('THIS IS THE JOB NOW')) { $current += $entry }
      if ($text -match '(?i)^[ \t#*_]*(run[ \t]+[0-9]+|(?:earlier|previous|old)[ \t-]+runs?)\b') { $runs += $entry }
    }
    $offset += $line.Length
  }
  if ($current.Count -gt 1) { throw "current instruction refused: expected one line containing THIS IS THE JOB NOW outside code fences, found $($current.Count); no agent started" }
  # Take only the opening fixed block, whether it is plain text or fenced for display.
  $blocks = [regex]::Matches($body, '(?im)^[ \t]*Owner:[^\r\n]*(?:\r?\n(?![ \t]*(?:\r?$|`{3,}|~{3,}))[^\r\n]+)*')
  $fixed = ''; if ($blocks.Count) { $fixed = $blocks[0].Value }
  foreach ($field in @('Owner','Brief','Deliver to','Branch','Done when')) {
    $pattern = [regex]::Escape($field)
    if ($field -eq 'Done when') { $pattern += '(?:[ \t]+\([^\r\n]*?\))?' }
    if ([regex]::Matches($fixed, "(?im)^[ \t]*${pattern}:[ \t]*\S[^\r\n]*").Count -ne 1) {
      throw "current instruction refused: fixed block needs one ${field}: line; no agent started"
    }
  }
  if ($prefix -eq 'codex' -and $fixed -notmatch '(?im)\bEffort \(Codex\):[ \t]*(xhigh|high|medium)\b') {
    throw 'current instruction refused: Codex fixed block needs Effort (Codex): high or xhigh; no agent started'
  }
  if ($current.Count -eq 0) {
    # A new job has no run history to select from. Its one fixed block and entire body are current.
    if ($blocks.Count -ne 1 -or $runs.Count) {
      throw "current instruction refused: found 0 THIS IS THE JOB NOW lines; without a marker use exactly one fixed block and no run history (fixed blocks: $($blocks.Count), run lines: $($runs.Count)); no agent started"
    }
    return $body.Trim()
  }
  $h = $current[0]
  $end = $body.Length
  foreach ($next in $runs) {
    if ($next.start -gt $h.start) { $end = $next.start; break }
  }
  $fixedMatch = [regex]::Match($body, [regex]::Escape($fixed))
  if ($h.start -lt $fixedMatch.Index) { throw 'current instruction refused: put the fixed block before the current run; no agent started' }
  $inline = $h.text -creplace '^.*?THIS IS THE JOB NOW[\W_]*', ''
  if (-not $inline.Trim() -and -not $body.Substring($h.end, $end - $h.end).Trim()) { throw 'current instruction refused: the current block is empty; no agent started' }
  if ($h.start -lt $fixedMatch.Index + $fixed.Length) {
    # Some current jobs put their marker and the entire instruction on Done when itself.
    return $body.Substring($fixedMatch.Index, $end - $fixedMatch.Index).Trim()
  }
  return ($fixed.Trim() + "`n`n" + $body.Substring($h.start, $end - $h.start).Trim())
}
function Seat-Prefix($seat, $branch) {
  if ($branch -match '^(codex|work|muse|opus)/') { return $Matches[1] }
  if ($seat -in @('codex','opus','muse')) { return $seat }
  return 'work'
}
function Validate-Job($i, $issue, $prefix, $pulls, $branches) {
  if ($i.state -ne 'open' -or $i.pull_request) { throw "job refused: issue #$issue is not an open job (state: $($i.state)); no agent started" }
  if (@($i.labels | Where-Object { $_.name -eq 'running' -or $_ -eq 'running' }).Count) { throw "job refused: issue #$issue already carries running; another run owns the claim; no agent started" }
  $body = Current-Body ([string]$i.body) $prefix
  $jobBranch = "^(codex|work|muse|opus)/issue-$issue(?:-|$)"
  foreach ($pr in $pulls) {
    $ref = [string]$pr.head.ref
    if ($ref -match $jobBranch -or "$($pr.title)`n$($pr.body)" -match "(?im)(?:\b(?:issue|refs)\s+#$issue\b|/issues/$issue\b)") {
      if (($ref -split '/')[0] -ne $prefix) { throw "job refused: open PR #$($pr.number) from other seat $ref covers issue #$issue; no agent started" }
    }
  }
  foreach ($branch in $branches) {
    if ($branch.name -match $jobBranch -and ([string]$branch.name -split '/')[0] -ne $prefix) {
      throw "job refused: delivery branch $($branch.name) from another seat exists for issue #$issue; no agent started"
    }
  }
  return $body
}
function Issue-Lock($issue) {
  # All PC lanes and seats use the same OS temp folder. Hold this only through validation and the claim, not agent work.
  $path = Join-Path ([IO.Path]::GetTempPath()) "voidsworn-runner-issue-$issue.lock"
  if ($test) { $path = Join-Path (Split-Path -Parent $env:PC_TEST_GH_DB) "issue-$issue.lock" }
  $deadline = [DateTime]::UtcNow.AddSeconds(30)
  while ($true) {
    try { return [IO.File]::Open($path, 'OpenOrCreate', 'ReadWrite', 'None') }
    catch [IO.IOException] {
      if ([DateTime]::UtcNow -ge $deadline) { throw 'job claim stayed locked for 30 seconds; no agent started' }
      Start-Sleep -Milliseconds 100
    }
  }
}
function End-Announcement($s, $code) {
  if (-not $s.github -or -not $s.github.claimed) { return }
  try {
    $g = $s.github
    # Never edit or clear a claim replaced by another run, even on the same branch or seat.
    $raw = Invoke-Gh 'GET' "issues/comments/$($g.comment)"
    if (-not $ghOK) { return }
    $comment = ConvertFrom-Json $raw
    if (-not ([string]$comment.body).Contains("- Run: $($s.run)")) { Log 'GitHub finish skipped: status comment belongs to another run'; return }
    $label = 'failed'
    if ($code -eq '0' -and $s.status -in @('checked_push','unverified')) { $label = 'finished' }
    if ($s.status -eq 'partial') { $label = 'partial' }
    if ($g.comment) { $null = Invoke-Gh 'PATCH' "issues/comments/$($g.comment)" @{ body = (Status-Body $s $label $s.reason) } }
    # Clearing the owned label must still be attempted when editing the comment fails.
    $null = Invoke-Gh 'DELETE' "issues/$($g.issue)/labels/running"
    if ($ghOK) { $g.claimed = $false; Save-State $s }
  } catch { Log "WARNING: GitHub final status failed: $($_.Exception.Message)" }
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
    } finally { $lock.Dispose() }
    # A pinned lane must not hold the shared mirror lock for the ten-minute preservation wait.
    Keep-Repo $repo 'kept'
    $delay = 120; if ($test -and $env:PC_TEST_RETRY_SECONDS) { $delay = [int]$env:PC_TEST_RETRY_SECONDS }
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        Log "local clone attempt $attempt/3"
        # Reacquire around each local clone: mirror fetch and hardlink cloning must still serialize.
        $lock = $null
        while (-not $lock) {
          try { $lock = [IO.File]::Open("$mirror.lock", 'OpenOrCreate', 'ReadWrite', 'None') }
          catch [IO.IOException] {
            if ([DateTime]::UtcNow -ge $deadline) { throw 'shared repo copy stayed locked for 30 minutes' }
            Start-Sleep -Milliseconds 500
          }
        }
        try { $null = Git @('clone','-q','-c','core.autocrlf=false','--local','--no-checkout',$mirror,$repo) }
        finally { $lock.Dispose() }
        if ($gitExit -eq 0) { break }
        Keep-Repo $repo 'clone-failed'
        if ($attempt -eq 3) { throw 'local clone failed after 3 attempts; see git_log.txt' }
        Log "local clone failed; retry in $delay seconds"; Start-Sleep -Seconds $delay
    }
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
  elseif ($mode -eq 'board-dryrun') {
    $script:out = $args[1]
    $null = New-Item -ItemType Directory -Force -Path $out
    $script:boardReadOnly = $true
    if ($test -and (-not $env:PC_TEST_GH -or -not $env:PC_TEST_GH_DB)) { throw 'test board audit requires fake gh and PC_TEST_GH_DB' }
    if (-not $test -and -not (Get-Command gh -ErrorAction SilentlyContinue)) {
      Log 'GitHub CLI gh is missing: claims will fail closed; this read-only audit uses public REST'
    }
    $issues = @(Gh-Pages 'issues?state=open&per_page=100')
    $pulls = @(Gh-Pages 'pulls?state=open&per_page=100')
    $branches = @(Gh-Pages 'branches?per_page=100')
    $report = @("Board dry run (UTC): $([DateTime]::UtcNow.ToString('o')); no claims or agent calls")
    foreach ($i in ($issues | Sort-Object number)) {
      if ($i.pull_request -or $i.state -ne 'open') { continue }
      $seats = @($i.labels | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.name } } | Where-Object { $_ -in @('codex','muse','opus') })
      foreach ($prefix in $seats) {
        try {
          $null = Validate-Job $i ([string]$i.number) $prefix $pulls $branches
          $report += "#$($i.number) [$prefix] ACCEPT"
        } catch { $report += "#$($i.number) [$prefix] REFUSE: $($_.Exception.Message)" }
      }
    }
    Put (Join-Path $out 'board_audit.txt') (($report -join "`n") + "`n")
    $report | ForEach-Object { Log $_ }
    exit 0
  }
  elseif ($mode -eq 'announce') {
    $script:out = $args[1]
    $issue = $args[2]
    if ($issue -notmatch '^[1-9][0-9]*$') { throw 'invalid job issue number; no agent started' }
    if ($test -and (-not $env:PC_TEST_GH -or -not $env:PC_TEST_GH_DB)) { throw 'test claim requires fake gh and PC_TEST_GH_DB (no live GitHub); no agent started' }
    $lock = Issue-Lock $issue
    try {
      $s = Get-Content -LiteralPath (Join-Path $out 'status.json') -Raw | ConvertFrom-Json
      $repo = $args[4]
      $i = Require-Gh 'GET' "issues/$issue"
      if ($i.state -ne 'open' -or $i.pull_request) { throw "job refused: issue #$issue is not an open job (state: $($i.state)); no agent started" }
      if (@($i.labels | Where-Object { $_.name -eq 'running' -or $_ -eq 'running' }).Count) { throw "job refused: issue #$issue already carries running; another run owns the claim; no agent started" }
      $prefix = Seat-Prefix $args[3] $s.branch
      $body = Current-Body ([string]$i.body) $prefix
      $pulls = @(Gh-Pages 'pulls?state=open&per_page=100')
      $branches = @(Gh-Pages 'branches?per_page=100')
      $body = Validate-Job $i $issue $prefix $pulls $branches
      $comments = @(Gh-Pages "issues/$issue/comments?per_page=100")
      # Snapshot exactly what was validated. Prep must never re-fetch a possibly changed or older brief.
      Put (Join-Path $out 'validated_issue.json') (@{ number = $issue; title = $i.title; body = $body; run = $s.run } | ConvertTo-Json)
      $s | Add-Member -NotePropertyName instruction_run -NotePropertyValue $s.run -Force
      Save-State $s
      # Dry runs validate read-only. Only fixture tests may write to their fake GitHub.
      if ($args[7] -ne 'real' -and -not $test) { Log "job validated: issue #$issue (dry run, no claim written)"; exit 0 }
      $head = @($branches | Where-Object { $_.name -eq 'main' } | ForEach-Object { $_.commit.sha }) -join ''
      $g = @{ issue = $issue; seat = $args[3]; folder = $repo; machine = [Environment]::MachineName;
        started = [DateTime]::UtcNow.ToString('o'); ceiling = $args[5]; resume = $args[6]; comment = 0;
        start_commit = $head; claimed = $false; marker = "<!-- voidsworn-runner-status branch=$($s.branch) -->" }
      $s | Add-Member -NotePropertyName github -NotePropertyValue $g -Force
      Save-State $s
      $null = Invoke-Gh 'GET' 'labels/running'
      if (-not $ghOK) { $null = Require-Gh 'POST' 'labels' @{ name = 'running'; color = '1D76DB'; description = 'An agent is working this issue' } }
      $null = Require-Gh 'POST' "issues/$issue/labels" @{ labels = @('running') }
      $g.claimed = $true
      # Reuse this branch's comment on retries instead of adding a new comment every run.
      try {
        foreach ($comment in $comments) { if (([string]$comment.body).StartsWith($g.marker)) { $g.comment = $comment.id } }
        $payload = @{ body = (Status-Body $s 'running' 'claimed before checkout and model calls') }
        if ($g.comment) { $null = Require-Gh 'PATCH' "issues/comments/$($g.comment)" $payload }
        else { $reply = Require-Gh 'POST' "issues/$issue/comments" $payload; $g.comment = $reply.id }
        if (-not $g.comment) { throw 'claim comment has no id; no agent started' }
        $claimedIssue = Require-Gh 'GET' "issues/$issue"
        $claimedComment = Require-Gh 'GET' "issues/comments/$($g.comment)"
        if (-not @($claimedIssue.labels | Where-Object { $_.name -eq 'running' -or $_ -eq 'running' }).Count -or
          -not ([string]$claimedComment.body).StartsWith($g.marker) -or -not ([string]$claimedComment.body).Contains("- Run: $($s.run)")) {
          throw 'claim did not land: running label and owned status comment must read back; no agent started'
        }
        Save-State $s
      } catch {
        # Still under the issue lock: no other local seat can have acquired this label in between.
        $null = Invoke-Gh 'DELETE' "issues/$issue/labels/running"
        $g.claimed = $false; Save-State $s
        throw
      }
      Log "job claimed: issue #$issue by $($g.seat), run $($s.run); current instruction validated"
    } finally { $lock.Dispose() }
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
    # The probe must use the same verified kill as an agent, including when taskkill cannot enumerate its tree.
    . (Join-Path $PSScriptRoot 'run_timeout.ps1') -LibraryOnly
    Initialize-RunTree
    $p = New-Object Diagnostics.Process; $p.StartInfo = $psi
    $null = $p.Start(); $stdout = $p.StandardOutput.ReadToEndAsync(); $stderr = $p.StandardError.ReadToEndAsync()
    $null = $p.Handle
    $tree = @{}; $tree[$p.Id] = $p
    try {
    $cap = 90; if ($test -and $env:PC_TEST_PREFLIGHT_SECONDS) { $cap = [int]$env:PC_TEST_PREFLIGHT_SECONDS }
    if (-not $p.WaitForExit($cap * 1000)) {
      Stop-RunTree $p $tree (Join-Path $out 'preflight_kill_log.txt')
      Put (Join-Path $out 'preflight_log.txt') ($stdout.Result + "`n" + $stderr.Result)
      throw "preflight failed: $kind timed out after $cap seconds"
    }
    $p.WaitForExit(); $code = $p.ExitCode
    } finally {
      Update-RunTree $tree
      if (@($tree.Values | Where-Object { -not $_.HasExited }).Count) { Stop-RunTree $p $tree (Join-Path $out 'preflight_kill_log.txt') }
      foreach ($child in $tree.Values) { $child.Dispose() }
    }
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
    $names = @('codex_issue.bat','codex_issue.ps1','runner_common.ps1','work_issue.bat','work_issue.ps1','review_evidence.ps1','run_timeout.ps1','tmo.bat','gpu_slots.js')
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
  if ($script:out) {
    Log $_.Exception.Message
    if (Test-Path (Join-Path $out 'status.json')) {
      State 'failed' $_.Exception.Message
      End-Announcement (Get-Content -LiteralPath (Join-Path $out 'status.json') -Raw | ConvertFrom-Json) '14'
    }
  }
  else { Write-Host $_.Exception.Message }
  exit 14
}
exit 0
