# Workhorse runner helpers (#217, Opus, Nov 7 2026). PowerShell 5.1. Called by work_issue.bat and work_setup.bat.
# Usage:
#   work_issue.ps1 prep    <n> <arm> <repo> <out> <godot exe>   writes <repo>\WORK_TASK.md and <out>\title.txt
#   work_issue.ps1 balance <arm> <out file>                      writes the account balance (number and currency) or "unknown"
#   work_issue.ps1 keycheck <arm>                                 exit 0 if the saved key opens the provider's model list
#   work_issue.ps1 lasttext <events.jsonl>                        prints the agent's final text
#   work_issue.ps1 stats   <n> <arm> <out>                        reads events.jsonl, balances and times; writes stats.txt and last.md
#   work_issue.ps1 msg     <n> <arm> <out>                        writes commit.txt (becomes the PR description)
#   work_issue.ps1 openai-key <out>                              checks the run's isolated credential, no network
#   work_issue.ps1 openai-budget <out> <root> <settings> <model> <dry 0|1>   refuses spent budgets and unpriced models
#   work_issue.ps1 openai-spend <n> <out> <root> <settings> <model> <dry 0|1> records emitted usage once per run
#   work_issue.ps1 openai-agent <out> <repo> <exe> <model> <variant> <cap>  runs and resumes an OpenCode session
# Runner 2 (issue 377, Opus, Nov 12 2026); codex_issue.bat uses these three too:
#   work_issue.ps1 guard   <n> <tag> <repo> <out>                 the refuse list and the Deliver to warning, on the staged change;
#                                                                 its files go to <out>\runs\<date_time>\ (one folder per run)
#   work_issue.ps1 commit  <repo> <out> <branch> <real|dry|test>  one commit that keeps the branch's earlier tip, checked before push
#   work_issue.ps1 confirm <repo> <out> <branch> <real|dry|test>  after the push: GitHub's branch must carry exactly out\diffstat.txt
#   work_issue.ps1 disk    <run folder> <repo>                 separately reports the run and reusable checkout sizes
# Keys come from the environment (DEEPSEEK_API_KEY, MOONSHOT_API_KEY, KIMI_CODE_API_KEY) and are never written to any file.
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$utf8 = New-Object System.Text.UTF8Encoding($false)
$mode = $args[0]
if ($mode -eq 'run') {
  # run <issue> <arm> <dryrun or blank> <slot repo>: hold the slot and issue locks around the whole batch run.
  $issue = $args[1]; $arm = $args[2]; $runMode = $args[3]
  if ($issue -notmatch '^[1-9][0-9]*$' -or $arm -notin @('deepseek','deepseekpro','kimi','kimicode','sonnet','opus','openai')) { exit 14 }
  if ($runMode -ne 'dryrun') { $runMode = '' }
  $runner = Join-Path $PSScriptRoot 'work_issue.bat'
  $start = New-Object Diagnostics.ProcessStartInfo
  $start.FileName = $env:COMSPEC
  $start.Arguments = '/d /s /c ""' + $runner + '" ' + $issue + ' ' + $arm + ' "' + $runMode + '" locked"'
  $start.UseShellExecute = $false
  # Issue 1186: the arm's one reused checkout. Its lock sits beside it, like the Codex lane lock, and is taken before
  # the issue lock; the batch's process tree inherits both (Artoo on issue 1186 and PR 1250).
  $slotRepo = $args[4]
  if (-not $slotRepo -or [IO.Path]::GetFileName([IO.Path]::GetFullPath($slotRepo).TrimEnd('\','/')) -ne 'repo' -or
      (Split-Path -Leaf (Split-Path -Parent ([IO.Path]::GetFullPath($slotRepo)))) -cne "slot_$arm") {
    Write-Host 'job refused: workhorse slot path not verified; no agent started'; exit 14
  }
  $start.EnvironmentVariables['WORK_LOCKED_REPO'] = $slotRepo
  $slotLock = $null
  try {
    . (Join-Path $PSScriptRoot 'runner_common.ps1') cleanup-library
    $full = [IO.Path]::GetFullPath($slotRepo)
    $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($full))
    try { $slotLock = Open-HeldLock "$full.checkout.lock" }
    catch [IO.IOException] { Write-Host 'job refused: workhorse slot busy or slot lock unavailable; no agent started'; exit 14 }
    exit (Invoke-LockedRunner $start $issue)
  } catch { Write-Host "job refused: could not hold the issue lock and run work_issue.bat ($($_.Exception.Message))"; exit 14 }
  finally { if ($slotLock) { $slotLock.Dispose() } }
}

function Start-Utf8InputProcess($start) {
  # Issue 1335: PowerShell 5.1 (.NET Framework) writes redirected stdin in [Console]::InputEncoding and emits its
  # preamble when the process starts. Under code page 65001 that is a UTF-8 BOM, so git read '<BOM>create ...' and
  # every salvage on Nov 20 was kept; under a legacy page such as 437, non-ASCII text leaves in that page. Newer .NET
  # takes StandardInputEncoding. On 5.1 the console input encoding becomes BOM-free UTF-8 around the start and is put
  # back after. A preamble that would still be written stops the call before anything starts. Send the text itself
  # with Write-Utf8Input, which writes UTF-8 bytes whatever the console page is (Artoo on PR 1345).
  $noBom = New-Object Text.UTF8Encoding($false)
  if ($start.PSObject.Properties['StandardInputEncoding']) { $start.StandardInputEncoding = $noBom; return [Diagnostics.Process]::Start($start) }
  $saved = $null
  try { $saved = [Console]::InputEncoding } catch { }
  $isUtf8 = { param($e) $e -and $e.CodePage -eq 65001 -and -not $e.GetPreamble().Length }
  try {
    if (-not (& $isUtf8 $saved)) { try { [Console]::InputEncoding = $noBom } catch { } }
    $now = $null; try { $now = [Console]::InputEncoding } catch { }
    if ($now -and $now.GetPreamble().Length) { throw 'stdin encoding still writes a byte order mark; nothing started' }
    return [Diagnostics.Process]::Start($start)
  } finally {
    if ($saved) { try { if (-not $saved.Equals([Console]::InputEncoding)) { [Console]::InputEncoding = $saved } } catch { } }
  }
}
function Write-Utf8Input($process, [string]$text) {
  # UTF-8 bytes straight to the pipe, so the console code page cannot change the text (issue 1335).
  $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes($text)
  $process.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length)
  $process.StandardInput.BaseStream.Flush()
  $process.StandardInput.Close()
}
# Issue 953: the report and the runner check logs carry PC paths. A path to a file inside this job's checkout becomes a
# GitHub link on the delivery branch, so it opens on a phone; every other path under the user's home folder becomes
# %USERPROFILE%\..., so no PC folder name reaches a public pull request. Everything else is left exactly as written.
function Path-Pattern([string]$p) {
  if (-not $p) { return '' }
  # Either separator matches, whatever the host wrote: every joined separator is [\\/]+, and a leading
  # separator (a Unix absolute path) is part of the match so none is left in front of the replacement.
  $lead = ''
  if ($p -match '^[\\/]') { $lead = '[\\/]+' }
  $segs = @($p -split '[\\/]+' | Where-Object { $_ -ne '' })
  if (-not $segs.Count) { return '' }
  return $lead + (@($segs | ForEach-Object { [regex]::Escape($_) }) -join '[\\/]+')
}
function Profile-Root {
  if ($env:USERPROFILE) { return $env:USERPROFILE }
  if ($env:HOME) { return $env:HOME }
  return ''
}
# Issue 1490: a runner receipt must not print a full Windows user path. A path below the voidsworn_test folder is
# shown from that folder down (for example work217\issue-1-deepseek\20261122_120000); anything else is left as is.
function Relative-ToVoidswornTest([string]$path) {
  if (-not $path) { return $path }
  $parts = @(($path -replace '/', '\') -split '\\+')
  for ($i = $parts.Count - 1; $i -ge 0; $i--) {
    if ($parts[$i] -ieq 'voidsworn_test') {
      $rest = @()
      if ($i -lt $parts.Count - 1) { $rest = @($parts[($i + 1)..($parts.Count - 1)] | Where-Object { $_ -ne '' }) }
      if ($rest.Count) { return ($rest -join '\') }
      return '.'
    }
  }
  return $path
}
function Rewrite-ReportPaths([string]$text, [string]$repo, [string]$branch, [string]$profileRoot) {
  if (-not $text) { return $text }
  $repoPat = Path-Pattern $repo
  if ($repoPat) {
    $tail = '([\\/][^\s\)\]\>"' + [char]39 + [char]96 + ',;]*)'
    $rx = New-Object System.Text.RegularExpressions.Regex ('(?i)' + $repoPat + $tail)
    $text = $rx.Replace($text, [System.Text.RegularExpressions.MatchEvaluator]{
      param($m)
      $rel = $m.Groups[1].Value -replace '\\', '/'
      $trail = ''
      $t2 = [regex]::Match($rel, '^(.*?)([.,;:]+)$')
      if ($t2.Success) { $rel = $t2.Groups[1].Value; $trail = $t2.Groups[2].Value }
      return 'https://github.com/rcbailey12/voidsworn/blob/' + $branch + $rel + $trail
    })
  }
  $homePat = Path-Pattern $profileRoot
  if ($homePat) {
    $homeTail = '([\\/][^\s\)\]\>"' + [char]39 + [char]96 + ',;]*)?'
    $hx = New-Object System.Text.RegularExpressions.Regex ('(?i)' + $homePat + $homeTail)
    $text = $hx.Replace($text, [System.Text.RegularExpressions.MatchEvaluator]{
      param($m)
      $rest = $m.Groups[1].Value
      if ($rest) { $rest = $rest.Substring(1) }
      $trail = ''
      $t2 = [regex]::Match($rest, '^(.*?)([.,;:]+)$')
      if ($t2.Success) { $rest = $t2.Groups[1].Value; $trail = $t2.Groups[2].Value }
      if ($rest) { return '%USERPROFILE%\' + $rest + $trail } else { return '%USERPROFILE%' + $trail }
    })
  }
  return $text
}

function Arm-Info($arm) {
  switch ($arm) {
    { $_ -in 'deepseek','deepseekpro' } { return @{ base = 'https://api.deepseek.com'; key = $env:DEEPSEEK_API_KEY; models = 'https://api.deepseek.com/models'; bal = 'https://api.deepseek.com/user/balance' } }
    'kimi'     { return @{ base = 'https://api.moonshot.ai/v1'; key = $env:MOONSHOT_API_KEY; models = 'https://api.moonshot.ai/v1/models'; bal = 'https://api.moonshot.ai/v1/users/me/balance' } }
    'kimicode' { return @{ base = 'https://api.kimi.com/coding/v1'; key = $env:KIMI_CODE_API_KEY; models = 'https://api.kimi.com/coding/v1/models'; bal = $null } }   # plan quota, no balance endpoint (issue 597)
    { $_ -in 'sonnet','opus' } { return @{ base = 'https://api.anthropic.com/v1'; key = $env:VOIDSWORN_CLAUDE_API_KEY; models = 'https://api.anthropic.com/v1/models'; bal = $null; anthropic = $true } }   # Max plan API credits, no balance endpoint (issue 614)
    'openai' { return @{ base = 'https://api.openai.com/v1'; key = $env:VOIDSWORN_OPENAI_API_KEY; models = 'https://api.openai.com/v1/models'; bal = $null } }
    default    { throw "unknown arm $arm" }
  }
}

function Read-Events($path) {
  $ev = @()
  if (-not (Test-Path $path)) { return $ev }
  foreach ($line in [IO.File]::ReadAllLines($path)) {
    $t = $line.Trim()
    if ($t.StartsWith('{')) { try { $ev += ,($t | ConvertFrom-Json) } catch { } }
  }
  return $ev
}

function Last-Text($ev) {
  $last = ''
  foreach ($e in $ev) { if ($e.type -eq 'text' -and $e.part.text) { $last = [string]$e.part.text } }
  return $last
}

function Read-Txt($p) { if (Test-Path $p) { return ([IO.File]::ReadAllText($p)).Trim() } else { return '' } }

function OpenAI-Agent($out, $repo, $exe, $model, $variant, [int]$cap) {
  $watchdog = Join-Path $PSScriptRoot 'tmo.bat'
  $log = [IO.StreamWriter]::new((Join-Path $out 'log.txt'), $false, $utf8)
  $log.AutoFlush = $true
  $stderr = Join-Path $out 'stderr.txt'
  [IO.File]::WriteAllText($stderr, '', $utf8)
  $waits = @(0, 30, 60, 120, 240, 240)
  $timer = [Diagnostics.Stopwatch]::StartNew()
  $session = ''
  $resumeArg = ''
  $taskPrompt = 'Read WORK_TASK.md in this folder and do exactly what it says. Do not commit and do not push.'
  $continuePrompt = 'Continue the task from where you stopped. Do not commit and do not push.'
  $remaining = $cap
  try {
    for ($resumes = 0; ; $resumes++) {
      $lastError = $null
      $diagnostic = $false
      $prompt = if ($resumes) { $continuePrompt } else { $taskPrompt }
      $start = [Diagnostics.ProcessStartInfo]::new($env:COMSPEC)
      $start.Arguments = '/d /s /c ""{0}" {1} "{2}" run --auto --format json -m {3} {4} --dir "{5}"{6} 2>&1"' -f `
        $watchdog, $remaining, $exe, $model, $variant, $repo, $resumeArg
      $start.UseShellExecute = $false
      $start.CreateNoWindow = $true
      $start.RedirectStandardInput = $true
      $start.RedirectStandardOutput = $true
      $start.StandardOutputEncoding = $utf8
      # OpenCode reads the prompt as UTF-8; no byte order mark in front of it (issue 1335).
      $process = Start-Utf8InputProcess $start
      try {
        # OpenCode reads the message from stdin. The watchdog can record its command line on a timeout.
        try { Write-Utf8Input $process $prompt } catch [IO.IOException] { }
        if ($resumes) {
          Add-Content -LiteralPath (Join-Path $out 'result.txt') -Value ('rate limited, resumed {0} of {1}' -f $resumes, $waits.Count) -Encoding UTF8
        }
        while ($null -ne ($line = $process.StandardOutput.ReadLine())) {
          $event = $null
          if ($line.TrimStart().StartsWith('{')) { try { $event = $line | ConvertFrom-Json } catch { } }
          if (-not $event.type) {
            if ($line.Trim() -and -not $diagnostic) {
              Add-Content -LiteralPath $stderr -Value 'OpenCode or its watchdog wrote a diagnostic.' -Encoding UTF8
              $diagnostic = $true
            }
            continue
          }
          if ($event.sessionID -cmatch '^ses_[a-zA-Z0-9]+$' -and -not $session) { $session = $event.sessionID }
          if ($event.type -eq 'error') {
            $data = $event.error.data
            $status = if ([string]$data.statusCode -match '^[1-5][0-9]{2}$') { [int]$data.statusCode }
            $retryable = $data.isRetryable -is [bool] -and $data.isRetryable
            $seconds = $null
            if ($status -eq 429 -and $retryable) {
              $hint = [regex]::Match("$($data.message) $($data.responseBody)", '(?i)\btry again in\s+(\d+(?:\.\d+)?)\s*(?:s|secs?|seconds?)\b')
              if ($hint.Success) { $seconds = [double]::Parse($hint.Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture) }
            }
            # Keep only the fields needed to decide the retry. Provider errors can carry headers and account details.
            $lastError = @{ statusCode = $status; isRetryable = $retryable; retryAfterSeconds = $seconds }
            $line = @{ type = 'error'; sessionID = $session; error = @{ data = $lastError } } | ConvertTo-Json -Compress -Depth 4
            if ($event.sessionID -cne $session) { $lastError = $null }
          } else {
            if ($env:VOIDSWORN_OPENAI_API_KEY -and $env:VOIDSWORN_OPENAI_API_KEY -ne 'dry') {
              $line = $line.Replace($env:VOIDSWORN_OPENAI_API_KEY, '[redacted]')
            }
            $line = $line.Replace($taskPrompt, '[redacted]').Replace($continuePrompt, '[redacted]')
          }
          $log.WriteLine($line)
        }
        $process.WaitForExit()
        $code = $process.ExitCode
      } finally { $process.Dispose() }

      if ($code -in @(0, 124) -or $resumes -ge $waits.Count -or -not $session -or
          $lastError.statusCode -ne 429 -or -not $lastError.isRetryable) { return $code }

      $minimum = $lastError.retryAfterSeconds
      if ($null -eq $minimum -and $resumes -eq 0) { $minimum = 5 }
      $delay = [Math]::Ceiling([Math]::Max($waits[$resumes], [double]$minimum))
      # Only the dry-run fixture can shorten waits. Check the real delay against the cap either way.
      if ($timer.Elapsed.TotalSeconds + $delay + 1 -gt $cap) {
        Add-Content -LiteralPath (Join-Path $out 'result.txt') -Value 'rate limited, too little time left to resume' -Encoding UTF8
        return $code
      }
      if ($env:PC_RUNNER_TEST -ne '1' -or $env:PC_TEST_OPENAI_NO_WAIT -ne '1') { Start-Sleep -Seconds $delay }
      $remaining = [int][Math]::Floor($cap - $timer.Elapsed.TotalSeconds)
      if ($remaining -lt 1) { return $code }
      $resumeArg = " --session $session"
    }
  } finally { $log.Dispose() }
}

if ($mode -eq 'openai-agent') {
  try { exit (OpenAI-Agent $args[1] $args[2] $args[3] $args[4] $args[5] $args[6]) }
  catch {
    Add-Content -LiteralPath (Join-Path $args[1] 'result.txt') -Value 'OpenCode runner failed while running the agent' -Encoding UTF8
    exit 125
  }
}

# Issue 985: one price table, USD per million tokens (Board's standard rates, Nov 17 2026).
# OpenCode step_finish input excludes cache reads; its visible output and reasoning are separate counts.
$openaiPrices = @{
  'openai/gpt-6.2-sol' = @{ input = [decimal]2; cached = [decimal]0.10; output = [decimal]10 }
  'openai/gpt-6.1-sol' = @{ input = [decimal]2; cached = [decimal]0.10; output = [decimal]10 }
  'openai/gpt-6.1-terra' = @{ input = [decimal]1; cached = [decimal]0.05; output = [decimal]5 }
  'openai/gpt-6.2-astra' = @{ input = [decimal]8; cached = [decimal]0.80; output = [decimal]40 }
}
function OpenAI-Budget($settings) {
  $budget = [decimal]94
  foreach ($line in ((Read-Txt $settings) -split '\r?\n')) {
    if ($line -match '^\s*openai_budget_usd\s*=(.*)$') {
      if (-not [decimal]::TryParse($Matches[1].Trim(), [Globalization.NumberStyles]::AllowDecimalPoint,
        [Globalization.CultureInfo]::InvariantCulture, [ref]$budget) -or $budget -lt 0) { throw 'invalid openai_budget_usd in runner_settings.txt' }
    }
  }
  return $budget
}
function OpenAI-Lock($root) {
  $path = Join-Path $root 'openai_spend.txt'
  for ($attempt = 0; $attempt -lt 100; $attempt++) {
    try { return [IO.File]::Open($path, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
    catch [IO.IOException] { Start-Sleep -Milliseconds 100 }
  }
  throw 'OpenAI spend ledger is busy; retry accounting before another run'
}
function OpenAI-Rows($stream) {
  $stream.Position = 0
  $reader = New-Object IO.StreamReader($stream, $utf8, $true, 1024, $true)
  try { $raw = $reader.ReadToEnd() } finally { $reader.Dispose() }
  foreach ($line in ($raw -split '\r?\n' | Where-Object { $_.Trim() })) {
    try {
      $row = $line | ConvertFrom-Json
      if (-not $row.run -or $row.date -notmatch '^\d{4}-\d{2}-\d{2}T' -or
        $null -eq $row.estimated_usd -or [decimal]$row.estimated_usd -lt 0 -or $row.status -notin @('estimated','unknown')) { throw 'bad row' }
    } catch { throw 'OpenAI spend ledger is invalid; reconcile openai_spend.txt before another run' }
    $row
  }
}
function OpenAI-Total($rows, $month) {
  $total = [decimal]0
  foreach ($row in $rows) { if ($row.date.StartsWith($month)) { $total += [decimal]$row.estimated_usd } }
  return $total
}
function OpenAI-UnknownPath($root, $out) {
  $hash = [Security.Cryptography.SHA256]::Create()
  try { $id = [BitConverter]::ToString($hash.ComputeHash($utf8.GetBytes([IO.Path]::GetFullPath($out).ToLowerInvariant()))).Replace('-', '').ToLowerInvariant() }
  finally { $hash.Dispose() }
  return Join-Path (Join-Path $root 'openai_spend_unknown') ($id + '.json')
}
function OpenAI-KeepUnknown($root, $out, $n, $model) {
  # A separate entry per run survives an invalid or locked main ledger. Never repair either automatically.
  $path = OpenAI-UnknownPath $root $out
  [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path)) | Out-Null
  $row = [ordered]@{ date = [datetime]::UtcNow.ToString('s') + 'Z'; issue = $n; model = $model;
    estimated_usd = 0; status = 'unknown'; run = [IO.Path]::GetFullPath($out) }
  [IO.File]::WriteAllText($path, ($row | ConvertTo-Json -Compress) + "`n", $utf8)
}
function OpenAI-CheckUnknown($root, $out, $spend) {
  $dir = Join-Path $root 'openai_spend_unknown'
  if (-not (Test-Path -LiteralPath $dir)) { return }
  foreach ($file in (Get-ChildItem -LiteralPath $dir -Filter '*.json' -File)) {
    try {
      $row = [IO.File]::ReadAllText($file.FullName) | ConvertFrom-Json
      if (-not $row.run -or $row.status -notin @('estimated','unknown')) { throw 'bad entry' }
    } catch { throw 'OpenAI unknown-spend entry is invalid; reconcile openai_spend_unknown before another run' }
    if ($row.status -eq 'unknown' -and (-not $spend -or $row.run -eq [IO.Path]::GetFullPath($out))) {
      throw 'OpenAI usage unknown: reconcile openai_spend_unknown and openai_spend.txt before another run'
    }
  }
}
function OpenAI-Usage($out) {
  $inputTokens = [decimal]0; $cached = [decimal]0; $outputTokens = [decimal]0; $steps = 0
  foreach ($file in @('preflight_log.txt','events.jsonl')) {
    foreach ($e in (Read-Events (Join-Path $out $file))) {
      if ($e.type -ne 'step_finish') { continue }
      $k = $e.part.tokens
      if ($null -eq $k.input -or $null -eq $k.output -or $null -eq $k.cache.read) { throw 'OpenAI token counts missing in OpenCode stats' }
      foreach ($v in @($k.input, $k.output, $k.reasoning, $k.cache.read)) {
        if ([decimal]$v -lt 0) { throw 'invalid OpenAI token counts in OpenCode stats' }
      }
      $inputTokens += [decimal]$k.input; $cached += [decimal]$k.cache.read
      $outputTokens += [decimal]$k.output + [decimal]$k.reasoning; $steps++
    }
  }
  return @{ input = $inputTokens; cached = $cached; output = $outputTokens; steps = $steps }
}
function OpenAI-Note($out, $row, $dry) {
  $note = 'OpenAI estimate USD: {0}; running total {1} / budget {2}; input {3}, cached input {4}, output {5}' -f
    $row.estimated_usd, $row.running_total_usd, $row.budget_usd, $row.input, $row.cached_input, $row.output
  if ($dry) { $note += '; dry run, no spend recorded' }
  if ($row.status -eq 'unknown') { $note += '; UNKNOWN usage: reconcile ledger before another paid run' }
  [IO.File]::WriteAllText((Join-Path $out 'openai_estimate.txt'), $note + "`n", $utf8)
  Add-Content -LiteralPath (Join-Path $out 'result.txt') -Value $note -Encoding UTF8
}

if ($mode -in @('openai-key','openai-budget','openai-spend')) {
  # These commands never call a provider. No credential or prompt belongs in an accounting file or error.
  $out = if ($mode -eq 'openai-spend') { $args[2] } else { $args[1] }
  $stream = $null
  try {
    if ($mode -eq 'openai-key') {
      if (-not $env:VOIDSWORN_OPENAI_API_KEY) { throw 'no OpenAI API key saved: run OPENAI_API_KEY.bat' }
      exit 0
    }
    if ($mode -eq 'openai-budget') {
      $root = $args[2]; $settings = $args[3]; $model = $args[4]; $dry = $args[5] -eq '1'
    } else {
      $n = $args[1]; $root = $args[3]; $settings = $args[4]; $model = $args[5]; $dry = $args[6] -eq '1'
      # Setup/checkout failures have no usage. A failed paid probe still has its log and must be counted.
      if (-not (Test-Path (Join-Path $out 'preflight_log.txt')) -and -not (Test-Path (Join-Path $out 'events.jsonl'))) { exit 0 }
    }
    if (-not $openaiPrices.ContainsKey($model)) { throw 'OpenAI model has no spend price: add its named rates to openaiPrices before running' }
    $budget = OpenAI-Budget $settings
    $month = [datetime]::UtcNow.ToString('yyyy-MM')
    $rows = @(); $total = [decimal]0
    if (-not $dry) {
      OpenAI-CheckUnknown $root $out ($mode -eq 'openai-spend')
      $stream = OpenAI-Lock $root; $rows = @(OpenAI-Rows $stream); $total = OpenAI-Total $rows $month
    }
    if ($mode -eq 'openai-budget') {
      if (@($rows | Where-Object { $_.status -eq 'unknown' }).Count) { throw 'OpenAI usage unknown: reconcile openai_spend.txt before another run' }
      if (-not $dry -and $total -ge $budget) { throw "OpenAI budget reached: USD $total / $budget; no paid call started" }
      exit 0
    }
    # Idempotent even when the runner regenerates stats or reaches finish after recording the run.
    $run = [IO.Path]::GetFullPath($out)
    $existing = @($rows | Where-Object { $_.run -eq $run })
    if ($existing.Count) {
      if (-not (Test-Path (Join-Path $out 'openai_estimate.txt'))) { OpenAI-Note $out $existing[0] $false }
      if ($existing[0].status -eq 'unknown') { exit 3 }
      exit 0
    }
    try { $usage = OpenAI-Usage $out } catch { $usage = @{ input = 0; cached = 0; output = 0; steps = 0 } }
    $price = $openaiPrices[$model]
    $cost = [decimal]::Round(($usage.input * $price.input + $usage.cached * $price.cached + $usage.output * $price.output) / 1000000, 8)
    $row = [ordered]@{ date = [datetime]::UtcNow.ToString('s') + 'Z'; issue = $n; model = $model;
      input = $usage.input; cached_input = $usage.cached; output = $usage.output; estimated_usd = $cost;
      running_total_usd = $total + $cost; budget_usd = $budget; status = $(if ($usage.steps) { 'estimated' } else { 'unknown' }); run = $run }
    if (-not $dry) {
      $bytes = $utf8.GetBytes(($row | ConvertTo-Json -Compress) + "`n")
      $stream.Position = $stream.Length; $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true)
    }
    OpenAI-Note $out ([pscustomobject]$row) $dry
    if ($row.status -eq 'unknown' -and -not $dry) { OpenAI-KeepUnknown $root $out $n $model; exit 3 }
    exit 0
  } catch {
    if ($mode -eq 'openai-spend' -and -not $dry) { OpenAI-KeepUnknown $root $out $n $model }
    Add-Content -LiteralPath (Join-Path $out 'result.txt') -Value $_.Exception.Message -Encoding UTF8
    exit 3
  } finally { if ($stream) { $stream.Dispose() } }
}

# ---- Runner 2 helpers (issue 377) ----
# Board, Nov 23 (RULEBOOK 2.5): a runner commit never carries a GitHub closing word. Agents' reports said "Closes #N"
# (Codex PRs 1758, 1759, 1784); every closing word before an issue reference (#N, owner/repo#N or an issue link) becomes "Refs", any case, colon or not.
function Refs-Only([string]$text) { return [regex]::Replace($text, '(?i)\b(close[sd]?|fix(e[sd])?|resolve[sd]?):?[ \t]+(https://github\.com/[^/\s]+/[^/\s]+/issues/[0-9]+|(?:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)?#[0-9]+)\b', 'Refs $3') }
# git's output as an array of lines; $script:gx holds its exit code. stderr is dropped (PowerShell 5.1 turns it into errors).
function Git-Lines { $o = & git @args 2>$null; $script:gx = $LASTEXITCODE; if ($null -eq $o) { return @() }; return @($o | ForEach-Object { [string]$_ }) }
function Git-One { $o = @(Git-Lines @args); if ($o.Count) { return $o[0].Trim() } else { return '' } }
function Write-Lines($path, $lines) { [IO.File]::WriteAllText($path, ((@($lines) -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding($false))) }
function Read-Lines($path) { if (-not (Test-Path -LiteralPath $path)) { return @() }; return @([IO.File]::ReadAllLines($path) | Where-Object { $_ -ne '' }) }
# Folders and files named on the issue's "Deliver to" line (anything with a slash, or a file name with an extension).
function Scope-Paths($dl) {
  $res = @()
  if (-not $dl) { return $res }
  $t = $dl -replace '[`"''()\[\]]', ' '
  foreach ($m in [regex]::Matches($t, '[A-Za-z0-9_.\-]+(?:/[A-Za-z0-9_.\-<>*{}]*)+|[A-Za-z0-9_\-]+\.[A-Za-z0-9]{1,5}\b')) {
    $p = $m.Value
    $cut = $p.IndexOfAny([char[]]'<*{'); if ($cut -ge 0) { $p = $p.Substring(0, $cut) }
    $p = $p.TrimEnd('.', ',', ';', ':').TrimEnd('/')
    if ($p.Length -ge 2) { $res += $p }
  }
  return $res
}
function In-Scope($p, $scope) {
  foreach ($s in $scope) { if ($p -ieq $s -or $p.StartsWith($s + '/', [StringComparison]::OrdinalIgnoreCase)) { return $true } }
  return $false
}
# Why a staged file may not be committed, or $null. The second line of defence behind godot/.gitignore (R144).
function Refuse-Reason($st, $p, $repo, $maxMb) {
  $lp = $p.ToLower()
  if ($lp.StartsWith('godot/gen/')) { return 'under godot/gen (built on the PC, never committed)' }
  if ($lp.StartsWith('godot/.godot/')) { return "under godot/.godot (Godot's import cache)" }
  if ($p -match '^godot/assets/ships/([^/]+)/' -and $Matches[1] -notin @('previews', 'test')) { return "ship files under godot/assets/ships/$($Matches[1])/ (PC-built, never committed)" }
  if ($lp.EndsWith('.uid') -and $st -eq 'A') { return 'a new .uid file (Godot makes these)' }
  if ($lp.EndsWith('.import') -and $st -eq 'M') { return 'a re-saved .import file (Godot rewrites these on import)' }
  if ($lp.EndsWith('.import') -and $st -eq 'A') { return 'a new .import file (Godot makes these)' }
  if ($st -eq 'A' -or $st -eq 'M') {
    $f = Join-Path $repo ($p -replace '/', '\')
    if (Test-Path -LiteralPath $f) {
      $mb = (Get-Item -LiteralPath $f -Force).Length / 1MB
      if ($mb -gt $maxMb) { return ('{0:N1} MB, over the {1} MB limit (WORK_MAX_FILE_MB)' -f $mb, $maxMb) }
    }
  }
  return $null
}
# The staged change, kept as a patch beside the run when the runner stops before a push.
function Save-Patch($out, $pre) { & git diff --cached --binary "--output=$(Join-Path $out 'change.patch')" $pre 2>$null }

if ($mode -eq 'prep') {
  $n = $args[1]; $arm = $args[2]; $repo = $args[3]; $out = $args[4]; $godot = $args[5]
  $i = Get-Content -LiteralPath (Join-Path $out 'validated_issue.json') -Raw | ConvertFrom-Json
  $state = Get-Content -LiteralPath (Join-Path $out 'status.json') -Raw | ConvertFrom-Json
  if ($i.number -ne $n -or $i.run -ne $state.run -or $state.instruction_run -ne $state.run -or $state.status -ne 'running') {
    throw 'job preparation refused: no validated current instruction for this run; no agent started'
  }
  $bodyFile = Join-Path $out 'issue_body.txt'
  [IO.File]::WriteAllText($bodyFile, [string]$i.body, $utf8)
  & (Join-Path $PSScriptRoot 'runner_common.ps1') base $repo $out $bodyFile
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  $resume = Read-Txt (Join-Path $out 'resume.txt')
  $task = @"
# Workhorse job: issue #$n, "$($i.title)"

You are the coding seat on the Voidsworn job board (github.com/rcbailey12/voidsworn/issues/$n), doing the job Codex used to do.
This folder is a fresh checkout on the branch work/issue-$n-$arm (main, or its earlier tip with main merged in; see below). Follow AGENTS.md and CLAUDE.md, except the
"work in your own folder" rule: you are the main coding seat for this job, so edit the game files the job names.
Nobody is watching this run and nobody can answer questions. Make the sensible call, say what you chose in your report, and keep going.
$resume

Rules:
- Do exactly what the job below asks. Change nothing else. Read the brief it names first.
- No em dashes in anything you write. Plain words, plain ASCII.
- Do not commit and do not push: the runner does that after you finish.
- The runner handles Base and resume merges before you start. Do not run git merge; report a missing base in your report.
- GPU work must use tools/pc/tmo.bat <seconds> <exe> [args]. Shared capacity comes from Downloads\voidsworn_test\gpu_slots.json (default 2).
  Captures weigh 1, Blender weighs 2; set PC_GPU_WEIGHT=2 for other heavy bakes, or the Board's chosen weight;
  frame-time scripts take solo automatically. For a new timing script set PC_GPU_MODE=solo before calling tmo.bat.
  gpu_go.txt must say GPU cleared. Lane C is code only. Never launch GPU executables directly.
- Keep scratch output (logs, temp files) out of this folder, in the system temp folder.
- Save review pictures and their .provenance.json sidecars in $out\shots (create it). Link them as shots/<file> so the
  runner can copy them into docs/shots/issue-$n-$arm and rewrite the links before publishing.
- Link pictures already in the checkout by repo-relative path, and keep every picture link relative.
- Finish with a short report: what you changed (files), each check you ran and its result (paste the PASS or FAIL lines),
  anything you skipped and why. Your report goes at the top of the pull request description; the runner runs the standing
  checks and parity itself after you stop and adds their real rows under it, so write it for a reviewer.

Before you finish, check how your change reaches the rest of the game (the reviewer checks all five, so do it first):
- Callers: search the whole repo for every function, constant and save field you changed or added, and check or fix each use.
- Saves: a player profile or run save written before your change must still load and behave; say how you checked.
- Rules (R405): change Godot and its tables. Reseal edited tables with res://rules/tools/reseal_tables.gd and check the saved Godot results. Keep the browser rules frozen. Follow RULEBOOK 3.1 for the current ship-data exception.
- UI: every screen that shows what you changed (campaign map, intel, panels, HUD) must read the new value the same way.
- CI: a new test file must be added to contrib/opus/tools/run_all_checks.js, or GitHub never runs it; say which checks GitHub runs.
Put one line per item in your report with what you found.

How to run things on this PC (Windows 10; your shell is Git Bash):
- Standing checks: node contrib/opus/tools/run_all_checks.js
- Rules parity and campaign parity (needs Godot, a few minutes): cmd.exe //c "tools\\pc\\parity.bat nopause"
  It prints PASS or FAIL per check; campaign parity runs at the end. Both must PASS. One shell command may run up to
  30 minutes, so run parity in the foreground and wait for it.
- Godot 4 console exe: $godot
  Before any Godot run that loads scenes, UI or textures, import once: "$godot" --headless --path godot --import
- Screenshots of the campaign UI: godot/campaign/test/r1_ui_shots.gd is a worked example of a script that builds a campaign
  screen and saves a PNG (run it without --headless so it can capture). Copy its pattern for your own shot script.

## The job

$($i.body)
"@
  [IO.File]::WriteAllText((Join-Path $repo 'WORK_TASK.md'), $task, $utf8)
  [IO.File]::WriteAllText((Join-Path $out 'title.txt'), [string]$i.title, $utf8)
  # The issue's "Deliver to" line: the guard step warns about changed files outside it (issue 377).
  $dl = ''
  if ([string]$i.body -match '(?im)^\s*Deliver to:\s*(.+?)\s*$') { $dl = $Matches[1] }
  [IO.File]::WriteAllText((Join-Path $out 'deliver_to.txt'), $dl, $utf8)
  Write-Host "issue #$n prepared for the $arm arm"
}
elseif ($mode -eq 'balance') {
  $arm = $args[1]; $file = $args[2]; $a = Arm-Info $arm; $v = 'unknown'
  if (-not $a.bal) { [IO.File]::WriteAllText($file, 'plan (no balance)', [Text.Encoding]::ASCII); Write-Host 'plan (no balance)'; exit 0 }
  try {
    $r = Invoke-RestMethod -UseBasicParsing -TimeoutSec 30 -Headers @{ Authorization = "Bearer $($a.key)" } -Uri $a.bal
    if ($arm -like 'deepseek*') { $b = $r.balance_infos | Select-Object -First 1; $v = "$($b.total_balance) $($b.currency)" }
    else { $v = "$($r.data.available_balance) USD" }
  } catch { $v = 'unknown' }
  [IO.File]::WriteAllText($file, $v, [Text.Encoding]::ASCII)
  Write-Host $v
}
elseif ($mode -eq 'keycheck') {
  $arm = $args[1]; $a = Arm-Info $arm
  if (-not $a.key) { Write-Host 'no key saved'; exit 1 }
  try {
    $h = @{ Authorization = "Bearer $($a.key)" }
    if ($a.anthropic) { $h = @{ "x-api-key" = $a.key; "anthropic-version" = "2023-06-01" } }
    $r = Invoke-RestMethod -UseBasicParsing -TimeoutSec 30 -Headers $h -Uri $a.models
    $ids = @($r.data | ForEach-Object { $_.id }) -join ', '
    Write-Host "key works; models: $ids"; exit 0
  } catch { Write-Host "key refused or no network: $($_.Exception.Message)"; exit 1 }
}
elseif ($mode -eq 'lasttext') {
  Write-Output (Last-Text (Read-Events $args[1]))
}
elseif ($mode -eq 'stats') {
  $n = $args[1]; $arm = $args[2]; $out = $args[3]
  $ev = Read-Events (Join-Path $out 'events.jsonl')
  $tin = 0; $tout = 0; $treason = 0; $tcr = 0; $tcw = 0; $cost = 0.0; $steps = 0; $tools = 0; $errs = 0
  foreach ($e in $ev) {
    if ($e.type -eq 'step_finish') {
      $steps++
      $k = $e.part.tokens
      if ($k) { $tin += [double]$k.input; $tout += [double]$k.output; $treason += [double]$k.reasoning; $tcr += [double]$k.cache.read; $tcw += [double]$k.cache.write }
      if ($e.part.cost) { $cost += [double]$e.part.cost }
    }
    elseif ($e.type -eq 'tool_use') { $tools++; if ($e.part.state.status -eq 'error') { $errs++ } }
  }
  $last = Last-Text $ev
  [IO.File]::WriteAllText((Join-Path $out 'last.md'), $last, $utf8)
  $b0 = Read-Txt (Join-Path $out 'balance_before.txt'); $b1 = Read-Txt (Join-Path $out 'balance_after.txt')
  $charge = 'unknown (read it on the provider console)'
  try {
    $x0 = [double]($b0 -split ' ')[0]; $x1 = [double]($b1 -split ' ')[0]
    $charge = '{0:N4} {1}' -f ($x0 - $x1), (($b0 -split ' ')[1])
  } catch { }
  $t0 = Read-Txt (Join-Path $out 'time_start.txt'); $t1 = Read-Txt (Join-Path $out 'time_agent_end.txt'); $t2 = Read-Txt (Join-Path $out 'time_pushed.txt')
  $mins = ''
  try { $mins = '{0:N1}' -f ((([datetime]$t1) - ([datetime]$t0)).TotalMinutes) } catch { }
  $s = @"
arm: $arm
model: $(Read-Txt (Join-Path $out 'model.txt'))
opencode exit: $(Read-Txt (Join-Path $out 'exit.txt'))
started: $t0
agent finished: $t1 ($mins minutes)
pushed: $t2
steps (model calls): $steps
tool calls: $tools (failed: $errs)
tokens: input $tin, output $tout, reasoning $treason, cache read $tcr, cache write $tcw
cost OpenCode estimated from its price table (USD): $('{0:N4}' -f $cost)
balance before: $b0
balance after: $b1
real charge (balance before minus after): $charge
"@
  if ($arm -eq 'openai') { $s += "`n" + (Read-Txt (Join-Path $out 'openai_estimate.txt')) }
  [IO.File]::WriteAllText((Join-Path $out 'stats.txt'), $s, $utf8)
  Write-Host $s
}
elseif ($mode -eq 'msg') {
  $n = $args[1]; $arm = $args[2]; $out = $args[3]
  . (Join-Path $PSScriptRoot 'runner_common.ps1') publication-library
  $title = Read-Txt (Join-Path $out 'title.txt')
  $last = Read-Txt (Join-Path $out 'last.md')
  if (-not $last) { $last = '(the agent left no final report; see board log on the PC)' }
  if ($last.Length -gt 6000) { $last = $last.Substring(0, 6000) + "`n(report cut at 6000 characters; full text on Ryan's PC in the run's out\last.md)" }
  # Issue 953: this runner's own checkout is the sibling repo folder of out; a partial run takes -partial.
  $repo = Join-Path (Split-Path -Parent $out) 'repo'
  $branch = "work/issue-$n-$arm"
  $partial = Read-Txt (Join-Path $out 'partial.txt')
  if (-not $partial) { $partial = Read-Txt (Join-Path $out 'stop_reason.txt') }
  $checks = if ($partial) { 'SKIP: runner checks (partial run)' } else { Public-RunnerText 'checks' '' '' $out }
  if ($partial) { $branch += '-partial'; $last = 'Stop reason: ' + (Public-RunnerText 'partial' $partial) }
  $msg = "Workhorse $arm arm (issue #$n): $title`n`n$last`n`n## Checks run by the runner`n`n$checks`n`nRefs #$n`n"
  $msg = Rewrite-ReportPaths $msg $repo $branch (Profile-Root)
  [IO.File]::WriteAllText((Join-Path $out 'commit.txt'), $msg, $utf8)
}
elseif ($mode -eq 'guard') {
  # After git add -A: refuse what must never be committed, keep a copy of it (never deleted), and warn about changed files
  # outside the issue's Deliver to line. Everything this step makes goes to a folder of its own for this run,
  # <out>\runs\<date_time>\ (refused\, refused.txt, scope_warnings.txt, guard.md), so a rerun that shares <out> (Codex's
  # board\issue-N) never overwrites an earlier run's refused copies (Muse, opus_check_575). out\guard_dir.txt names it.
  $ErrorActionPreference = 'Continue'
  $n = $args[1]; $tag = $args[2]; $repo = $args[3]; $out = $args[4]
  $maxMb = 8; if ($env:WORK_MAX_FILE_MB) { $maxMb = [double]$env:WORK_MAX_FILE_MB }
  Push-Location $repo
  # prepare copies report pictures after checkout, even when the brief did not need the old pictures.
  $evidence = "docs/shots/issue-$n-$tag"
  if ((Test-Path -LiteralPath $evidence -PathType Container) -and (Git-One config --bool core.sparseCheckout) -eq 'true') {
    & git add --sparse --ignore-removal -- $evidence
    if ($LASTEXITCODE -ne 0) { Write-Host 'guard failed: could not stage review evidence'; Pop-Location; exit 1 }
  }
  $staged = @(Git-Lines -c core.quotepath=off diff --cached --name-status --no-renames)
  if ($gx -ne 0) { Write-Host 'guard failed: git could not list the staged change'; Pop-Location; exit 1 }
  $dlFile = Join-Path $out 'deliver_to.txt'
  $dl = Read-Txt $dlFile
  if (-not (Test-Path $dlFile)) {
    try {
      $i = Invoke-RestMethod -UseBasicParsing -TimeoutSec 30 -Headers @{ 'User-Agent' = 'voidsworn-runner' } -Uri "https://api.github.com/repos/rcbailey12/voidsworn/issues/$n"
      if ([string]$i.body -match '(?im)^\s*Deliver to:\s*(.+?)\s*$') { $dl = $Matches[1] }
      [IO.File]::WriteAllText($dlFile, $dl, $utf8)
    } catch { }
  }
  $scope = @(Scope-Paths $dl)
  $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
  $gdir = Join-Path $out "runs\$stamp"; $k = 2
  while (Test-Path -LiteralPath $gdir) { $gdir = Join-Path $out "runs\${stamp}_$k"; $k++ }
  New-Item -ItemType Directory -Force -Path $gdir | Out-Null
  $grel = $gdir.Substring($out.TrimEnd('\').Length).TrimStart('\')
  [IO.File]::WriteAllText((Join-Path $out 'guard_dir.txt'), $gdir, [Text.Encoding]::ASCII)
  $refused = @(); $warn = @()
  foreach ($l in $staged) {
    $parts = $l -split "`t", 2
    if ($parts.Count -lt 2) { continue }
    $st = $parts[0].Substring(0, 1); $p = $parts[1]
    $why = Refuse-Reason $st $p $repo $maxMb
    if ($why) { $refused += [pscustomobject]@{ S = $st; P = $p; Why = $why }; continue }
    if ($p -like "$evidence/*") { continue }
    if ($scope.Count -and -not (In-Scope $p $scope)) { $warn += "$st $p" }
  }
  $keep = Join-Path $gdir 'refused'
  $bad = @()
  foreach ($r in $refused) {
    if ($r.S -ne 'D') {
      $src = Join-Path $repo ($r.P -replace '/', '\'); $dst = Join-Path $keep ($r.P -replace '/', '\')
      try { New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null; Copy-Item -LiteralPath $src -Destination $dst -Force -ErrorAction Stop } catch { $bad += "copy failed: $($r.P)" }
    }
    & git restore --staged --ignore-skip-worktree-bits -- ":(literal)$($r.P)" 2>$null
  }
  # The refused files must be out of the commit now (they stay in the working folder and in out\refused).
  $after = @(Git-Lines -c core.quotepath=off diff --cached --name-only --no-renames)
  foreach ($r in $refused) { if ($after -contains $r.P) { $bad += "still staged: $($r.P)" } }
  $rl = @($refused | ForEach-Object { "$($_.S) $($_.P): $($_.Why)" })
  Write-Lines (Join-Path $gdir 'refused.txt') $rl
  Write-Lines (Join-Path $gdir 'scope_warnings.txt') $warn
  $md = @()
  if ($refused.Count) {
    Write-Host "REFUSED $($refused.Count) file(s): not committed, copies kept in $(Relative-ToVoidswornTest ($gdir + '\refused')) (never deleted):"
    $rl | ForEach-Object { Write-Host "  $_" }
    $md += "Refused by the runner, not committed ($($refused.Count); copies kept on the PC in the run's out folder, $grel\refused):"
    $md += @($rl | Select-Object -First 30 | ForEach-Object { "- $_" })
    if ($rl.Count -gt 30) { $md += "- and $($rl.Count - 30) more ($grel\refused.txt on the PC)" }
    $md += ''
  } else { Write-Host 'refuse list: nothing refused' }
  if (-not $scope.Count) {
    Write-Host 'scope: no folders found on the issue''s Deliver to line, so nothing was checked against it'
    $md += 'Scope: no folders found on the issue''s Deliver to line; not checked.'
  } elseif ($warn.Count) {
    Write-Host "WARNING: $($warn.Count) changed file(s) outside the issue's Deliver to ($($scope -join ', ')):"
    $warn | ForEach-Object { Write-Host "  $_" }
    $md += "Warning: changed outside the issue's Deliver to ($($scope -join ', ')):"
    $md += @($warn | Select-Object -First 30 | ForEach-Object { "- $_" })
    if ($warn.Count -gt 30) { $md += "- and $($warn.Count - 30) more ($grel\scope_warnings.txt on the PC)" }
  } else { Write-Host "scope: every changed file is inside the issue's Deliver to" }
  Write-Lines (Join-Path $gdir 'guard.md') $md
  Pop-Location
  if ($bad.Count) { Write-Host 'guard failed:'; $bad | ForEach-Object { Write-Host "  $_" }; exit 1 }
  exit 0
}
elseif ($mode -eq 'commit') {
  . (Join-Path $PSScriptRoot 'runner_common.ps1') publication-library
  # One commit for the run, made with git's plumbing (no hooks, no editor, its exit code checked). Its parents are the
  # agent's HEAD (with any merge the agent made under it) and the branch's earlier tip on GitHub, so a rerun pushes as a
  # fast-forward with no force and the earlier run stays reachable. Then the check the issue 541 trap needs: the commit
  # must carry exactly the staged change (out\diffstat.txt). The author is git's own identity, or GIT_AUTHOR_* and
  # GIT_COMMITTER_* when the calling .bat sets them. Exit 0 ready to push, 7 nothing to commit, 10 diff mismatch,
  # 11 commit failed, 12 the branch's earlier tip could not be read, 15 the run does not descend from that tip (issue 1739).
  $ErrorActionPreference = 'Continue'
  $repo = $args[1]; $out = $args[2]; $br = $args[3]; $push = $args[4]
  $fault = ''; if ($push -ne 'real' -and $env:WORK_TEST_FAULT) { $fault = $env:WORK_TEST_FAULT }
  Push-Location $repo
  $pre = Git-One rev-parse HEAD
  # Issue 889: check the exact PR body and the full report before truncation can hide a bad link.
  # Partial branches preserve interrupted work and never open a PR.
  if (-not (Read-Txt (Join-Path $out 'partial.txt'))) {
    foreach ($bodyName in @('last.md', 'commit.txt')) {
      & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'review_evidence.ps1') check $repo (Join-Path $out $bodyName)
      if ($LASTEXITCODE -ne 0) { Write-Host 'PR body refused: review picture evidence failed; work kept, nothing committed or pushed'; Pop-Location; exit 13 }
    }
  }
  [IO.File]::WriteAllText((Join-Path $out 'pre_commit.txt'), $pre, [Text.Encoding]::ASCII)
  & git diff --cached --quiet 2>$null
  if ($LASTEXITCODE -eq 0) {
    $base = Read-Txt (Join-Path $out 'base_commit.txt')
    $resumed = Read-Txt (Join-Path $out 'resume.txt')
    & git diff --quiet $base HEAD 2>$null
    $partial = Read-Txt (Join-Path $out 'partial.txt')
    if (-not $partial -and (-not $resumed -or $LASTEXITCODE -eq 0)) { Write-Host 'nothing left to commit after the refuse list'; Pop-Location; exit 7 }
    Write-Host 'resumed work is already committed; carry it through the checked push'
  }
  $num = @(Git-Lines -c core.quotepath=off diff --cached --numstat --no-renames)
  Write-Lines (Join-Path $out 'diff_numstat.txt') $num
  Write-Lines (Join-Path $out 'diffstat.txt') @(Git-Lines -c core.quotepath=off diff --cached --stat --no-renames)
  # The branch's earlier tip (an earlier run, or the Board's own fix-ups): kept, never overwritten.
  $old = ''
  $ls = @(Git-Lines ls-remote origin "refs/heads/$br")
  if ($gx -ne 0) { Write-Host "push stopped: could not read branch $br on GitHub, the check failed; change kept as out\change.patch"; Save-Patch $out $pre; Pop-Location; exit 12 }
  if ($ls.Count) {
    $want = ($ls[0] -split '\s+')[0]
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'runner_common.ps1') fetch $repo $out "+refs/heads/${br}:refs/remotes/origin/runner-prev"
    if ($LASTEXITCODE -ne 0) { Write-Host 'push stopped: earlier tip fetch failed after retries'; Save-Patch $out $pre; Pop-Location; exit 12 }
    $old = Git-One rev-parse -q --verify 'refs/remotes/origin/runner-prev^{commit}'
    if (-not $old) { Write-Host "push stopped: could not fetch the earlier tip $want of $br, the check failed; change kept as out\change.patch"; Save-Patch $out $pre; Pop-Location; exit 12 }
  }
  [IO.File]::WriteAllText((Join-Path $out 'prev_tip.txt'), $old, [Text.Encoding]::ASCII)
  # Issue 1739 (1747 run 2): a run that did not start from the branch's earlier tip would push a commit whose files are
  # that run's alone, dropping the earlier runs' work. The checkout now starts from the tip; this stops any run that
  # still does not descend from it (or a tip that moved during the run), naming the files it would drop.
  if ($old) {
    & git merge-base --is-ancestor $old $pre 2>$null
    $ancestor = $LASTEXITCODE
    if ($ancestor -ne 0) {
      $oldFiles = @(Git-Lines -c core.quotepath=off ls-tree -r --name-only $old)
      $nowFiles = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
      foreach ($f in @(Git-Lines -c core.quotepath=off ls-files)) { $null = $nowFiles.Add($f) }
      $dropped = @($oldFiles | Where-Object { -not $nowFiles.Contains($_) })
      $why = if ($ancestor -eq 1) { "this run did not start from the earlier tip $old of $br" } else { "could not check that this run descends from the earlier tip $old of $br" }
      $v = @("EARLIER TIP CHECK FAILED (issue 1739): $why.", "agent HEAD $pre", "files the earlier tip has that this commit would drop: $($dropped.Count)") + @($dropped | Select-Object -First 200)
      Write-Lines (Join-Path $out 'EARLIER_TIP.txt') $v
      Write-Host "!!! push stopped: $why; the earlier runs' work would be lost ($($dropped.Count) of its files dropped, listed in out\EARLIER_TIP.txt). Nothing pushed; the change is kept as out\change.patch"
      Save-Patch $out $pre; Pop-Location; exit 15
    }
  }
  $runNo = 1
  if ($old) {
    $runNo = 2
    $om = (Git-Lines log -1 --format=%B $old) -join "`n"
    if ($om -match '(?m)^Run-Number: (\d+)') { $runNo = [int]$Matches[1] + 1 }
  }
  # The message: the runner's text (commit.txt) plus the runner's own block. Never empty (issue 541: an empty
  # commit.txt made the old runner's commit abort, and its push carried only the agent's merge commit).
  $msg = ''
  $cp = Join-Path $out 'commit.txt'
  if (Test-Path $cp) { $msg = [IO.File]::ReadAllText($cp) }
  $n = ''; if ($br -match 'issue-(\d+)') { $n = $Matches[1] }
  if (-not $msg.Trim()) { $msg = "Runner commit for $br (the message step left no text; the agent's report is in the run's out folder on the PC)`n`nRefs #$n`n"; Write-Host 'WARNING: commit.txt was empty, the runner wrote a plain message' }
  $partial = Read-Txt (Join-Path $out 'partial.txt')
  $base = Read-Txt (Join-Path $out 'base_commit.txt')
  $block = "## Runner (issue 377)`n`n"
  if ($partial) {
    $reason = Public-RunnerText 'partial' $partial
    $msg = "PARTIAL RUN, not a finished job ($reason): " + $msg
    $block += "PARTIAL RUN: $reason. This branch ends in -partial and opens no pull request. The Board reruns the job or takes the work by hand.`n`n"
  }
  if ($base -and $base -ne $pre) {
    $ac = @(Git-Lines log --format='%H' "$base..$pre" | Where-Object { $_ -cmatch '\A[0-9a-f]{40,64}\z' })
    if ($ac.Count) { $block += "Earlier commits (runner Base and resume merges included), under this one:`n" + (($ac | ForEach-Object { "- $_" }) -join "`n") + "`n`n" }
  }
  if ($old) { $block += "Earlier tip of $br kept: this run started from $old, so its files are the earlier runs' work plus this run's change.`n" }
  $block += "Run-Number: $runNo`n"
  $final = Refs-Only ($msg.TrimEnd() + "`n`n" + $block)
  [IO.File]::WriteAllText($cp, $final, $utf8)
  $new = $pre
  if ($fault -eq 'skipcommit') {
    Write-Host 'TEST FAULT skipcommit (dry run only): the runner leaves the staged change uncommitted, as the issue 541 run did'
  } else {
    $tree = Git-One write-tree
    if ($gx -ne 0 -or -not $tree) { Write-Host 'COMMIT FAILED: git write-tree failed; nothing pushed, change kept as out\change.patch'; Save-Patch $out $pre; Pop-Location; exit 11 }
    $pargs = @('-p', $pre)
    $mh = Git-One rev-parse -q --verify MERGE_HEAD
    if ($mh) { $pargs += @('-p', $mh) }
    $new = Git-One commit-tree $tree @pargs -F $cp
    if ($gx -ne 0 -or -not $new) { Write-Host 'COMMIT FAILED: git commit-tree failed; nothing pushed, change kept as out\change.patch'; Save-Patch $out $pre; Pop-Location; exit 11 }
    & git update-ref -m 'runner commit (issue 377)' HEAD $new $pre 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host 'COMMIT FAILED: git update-ref failed; nothing pushed, change kept as out\change.patch'; Save-Patch $out $pre; Pop-Location; exit 11 }
  }
  [IO.File]::WriteAllText((Join-Path $out 'run_commit.txt'), $new, [Text.Encoding]::ASCII)
  # Before the push: the commit must carry exactly the staged change, and nothing may be left staged.
  $head = Git-One rev-parse HEAD
  $num2 = @(Git-Lines -c core.quotepath=off diff --numstat --no-renames $pre $head)
  & git diff --cached --quiet $head 2>$null; $clean = ($LASTEXITCODE -eq 0)
  if ((($num -join "`n") -ne ($num2 -join "`n")) -or -not $clean -or $head -ne $new) {
    $v = @('DIFF MISMATCH before the push (issue 377): the commit to push does not carry the staged change.', "agent HEAD $pre, commit to push $head", '', 'staged (out\diffstat.txt):') + $num + @('', 'in the commit to push:') + $num2
    Write-Lines (Join-Path $out 'DIFF_MISMATCH.txt') $v
    Write-Host '!!! DIFF MISMATCH: push stopped, the check failed. The commit to push does not carry the change in out\diffstat.txt.'
    Write-Host "!!! staged: $($num.Count) file(s); in the commit to push: $($num2.Count). Nothing pushed; the staged change is kept as out\change.patch; see out\DIFF_MISMATCH.txt"
    Save-Patch $out $pre; Pop-Location; exit 10
  }
  $sh = $new.Substring(0, [Math]::Min(9, $new.Length))
  if ($old) { Write-Host "commit $sh (run $runNo of $br) carries the staged change ($($num.Count) files) on top of the earlier tip $($old.Substring(0, 9)), so the push needs no force" }
  else { Write-Host "commit $sh (run 1 of $br) carries the staged change ($($num.Count) files)" }
  Pop-Location; exit 0
}
elseif ($mode -eq 'confirm') {
  # After the push: GitHub's branch must be the runner's commit, and its diff from the agent's HEAD must be exactly
  # out\diffstat.txt. Writes pushed_diffstat.txt. Exit 10, loudly, when they differ.
  $ErrorActionPreference = 'Continue'
  $repo = $args[1]; $out = $args[2]; $br = $args[3]; $push = $args[4]
  Push-Location $repo
  $pre = Read-Txt (Join-Path $out 'pre_commit.txt'); $new = Read-Txt (Join-Path $out 'run_commit.txt')
  $num = @(Read-Lines (Join-Path $out 'diff_numstat.txt'))
  if ($push -eq 'dry') { Write-Host 'dry run: nothing pushed; the commit that would be pushed carries exactly out\diffstat.txt (checked before the push)'; Pop-Location; exit 0 }
  $ls = @(Git-Lines ls-remote origin "refs/heads/$br")
  $remote = ''; if ($ls.Count) { $remote = ($ls[0] -split '\s+')[0] }
  if ($remote -ne $new) {
    Write-Lines (Join-Path $out 'DIFF_MISMATCH.txt') @('PUSH CHECK FAILED (issue 377)', "GitHub's $br is '$remote'", "the runner's commit is $new")
    Write-Host "!!! PUSH CHECK FAILED: GitHub's $br is '$remote', not the runner's commit $new. See out\DIFF_MISMATCH.txt"
    Pop-Location; exit 10
  }
  $num2 = @(Git-Lines -c core.quotepath=off diff --numstat --no-renames $pre $remote)
  & git -c core.quotepath=off diff --stat --no-renames "--output=$(Join-Path $out 'pushed_diffstat.txt')" $pre $remote 2>$null
  if (($num -join "`n") -ne ($num2 -join "`n")) {
    Write-Lines (Join-Path $out 'DIFF_MISMATCH.txt') (@('DIFF MISMATCH after the push (issue 377)', 'out\diffstat.txt:') + $num + @('', "pushed ($pre..$remote):") + $num2)
    Write-Host "!!! DIFF MISMATCH after the push, the check failed: GitHub's $br does not carry exactly out\diffstat.txt. Do not merge it; see out\DIFF_MISMATCH.txt"
    Pop-Location; exit 10
  }
  Write-Host "pushed diff checked: GitHub's $br ($($remote.Substring(0, 9))) carries exactly out\diffstat.txt ($($num.Count) files)"
  [IO.File]::WriteAllText((Join-Path $out 'confirmed_commit.txt'), $remote, [Text.Encoding]::ASCII)
  Pop-Location; exit 0
}
elseif ($mode -eq 'disk') {
  $run = $args[1]; $repo = $args[2]
  foreach ($entry in @(@{ label = 'run folder'; path = $run }, @{ label = 'shared checkout'; path = $repo })) {
    try {
      $bytes = 0L
      if (Test-Path -LiteralPath $entry.path) {
        $bytes = (Get-ChildItem -LiteralPath $entry.path -Recurse -Force -File | Measure-Object -Property Length -Sum).Sum
      }
      Write-Host ('disk: {0} {1} logical bytes ({2:N2} GiB) at {3}' -f $entry.label, [long]$bytes, ($bytes / 1GB), (Relative-ToVoidswornTest $entry.path))
    } catch { Write-Host "disk: could not measure $($entry.label) at $(Relative-ToVoidswornTest $entry.path): $($_.Exception.Message)" }
  }
  exit 0
}
else { Write-Host 'usage: work_issue.ps1 prep|balance|keycheck|lasttext|stats|msg|guard|commit|confirm|disk ...'; exit 2 }
