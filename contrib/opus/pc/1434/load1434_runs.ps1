# Issue 1434 LOAD10 (with issues 1518 and 1519, Board Nov 21): one pinned checkout, graded on a WARM profile, the cold
# first launch reported alongside on the same items.
#   1. load bench, cold: godot/bench/load_1434.gd on a fresh Godot profile inside this attempt folder (no shader cache,
#      no pipeline cache, no world bakes on disk). Reported, plus its COVER line: the loading cover up on every frame
#      to play and no frame of 5 s or more (the Board's one condition on the cold pass).
#   2. load bench, warm: the same bench again on that same profile (the player's second launch onward). Graded.
#   3. close timing (from close1435_timing5.ps1, PR 1441): the six CLOSE5 cases, each on its own fresh profile (cold,
#      reported) and then each on the warm profile from steps 1 and 2 (graded). Issue 1518: the window hides within
#      500 ms of the close request in altf4_load_5s, title_load_5s and title_battle_30s. Issue 1519: the first title frame
#      within 200 ms of leaving the battle in title_load_5s and title_battle_30s (the game's "[main] battle to title" line).
#      Every case must also take the window route once, exit 0 and not crash (as CLOSE5).
# Writes <Out>\load10_result.txt with the gate line "[load10] RESULT PASS" only when step 2 passes, step 1's COVER
# passes and every graded warm close item passes. Nothing outside <Out> is written; every profile lives under <Out>.
param([Parameter(Mandatory)][string]$Godot, [Parameter(Mandatory)][string]$Project, [Parameter(Mandatory)][string]$Out)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $Out | Out-Null
$res = Join-Path $Out 'load10_result.txt'
"LOAD10, project $Project, $(Get-Date -Format s)" | Set-Content -LiteralPath $res -Encoding Ascii
function Say($s) { Write-Output $s; Add-Content -LiteralPath $res -Value $s -Encoding Ascii }
$keepApp = $env:APPDATA; $keepLocal = $env:LOCALAPPDATA

function Kill-Tree($p) {
  try { & taskkill.exe /T /F /PID $p.Id 2>&1 | Out-Null } catch {}
}

function Start-Game($profile, $argList, $log, $err) {
  $env:APPDATA = $profile; $env:LOCALAPPDATA = $profile
  try {
    $p = Start-Process -FilePath $Godot -ArgumentList $argList -PassThru -RedirectStandardOutput $log -RedirectStandardError $err
    $null = $p.Handle   # keeps ExitCode readable after exit (PowerShell 5.1)
  } finally { $env:APPDATA = $keepApp; $env:LOCALAPPDATA = $keepLocal }
  return $p
}

# ---- 1 and 2: the load bench, cold then warm, on one profile
$warmProfile = Join-Path $Out 'profile_warm'
New-Item -ItemType Directory -Force -Path $warmProfile | Out-Null
$bench = @{}
foreach ($pass in @('cold', 'warm')) {
  $d = Join-Path $Out "load_$pass"
  New-Item -ItemType Directory -Force -Path $d | Out-Null
  $argList = @('--path', "`"$Project`"", '--fullscreen', '--script', 'res://bench/load_1434.gd', '--', '--out', "`"$d`"", '--pass', $pass)
  $p = Start-Game $warmProfile $argList (Join-Path $d 'log.txt') (Join-Path $d 'log_err.txt')
  if (-not $p.WaitForExit(1500 * 1000)) { Kill-Tree $p; Say "load $pass`: FAIL: still running after 1500 s, stopped" }
  $txt = Join-Path $d 'load_result.txt'
  $r = if (Test-Path -LiteralPath $txt) { Get-Content -LiteralPath $txt -Raw } else { '' }
  $bench[$pass] = @{
    result = [regex]::Match($r, '\[load1434\] RESULT [^\r\n]*').Value
    cover = [regex]::Match($r, '\[load1434\] COVER [^\r\n]*').Value
    pass = $r -match '\[load1434\] RESULT PASS'
    cover_pass = $r -match '\[load1434\] COVER PASS'
  }
  if (-not $r) { Say "load $pass`: FAIL: no load_result.txt (see load_$pass\log.txt)" }
  else { Say "load $pass`: $($bench[$pass].result)"; Say "load $pass`: $($bench[$pass].cover)" }
  Start-Sleep -Seconds 3
}

# ---- 3: the close cases (close1435_timing5.ps1's method), cold set then warm set
$shell = New-Object -ComObject WScript.Shell
Add-Type -Namespace V1434L -Name User32 -MemberDefinition @'
[DllImport("user32.dll")] public static extern System.IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern bool IsIconic(System.IntPtr hWnd);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(System.IntPtr hWnd);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(System.IntPtr hWnd, System.Text.StringBuilder buf, int max);
'@
function Get-WindowClass($h) { $b = New-Object Text.StringBuilder 256; [void][V1434L.User32]::GetClassName($h, $b, 256); $b.ToString() }
function Find-Game($p, $seconds) {
  $t = Get-Date
  while (((Get-Date) - $t).TotalSeconds -lt $seconds) {
    $cands = @($p)
    try { $cands += @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$($p.Id)" | Where-Object { $_.Name -match '^(Godot|Voidsworn)' } | ForEach-Object { Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue }) } catch {}
    foreach ($q in $cands) {
      if (-not $q) { continue }
      $q.Refresh()
      if ($q.HasExited -or $q.MainWindowHandle -eq [IntPtr]::Zero) { continue }
      $cls = Get-WindowClass $q.MainWindowHandle
      if ($cls -in @('ConsoleWindowClass', 'CASCADIA_HOSTING_WINDOW_CLASS', 'PseudoConsoleWindow')) { continue }
      $null = $q.Handle
      return @{proc = $q; cls = $cls}
    }
    if ($p.HasExited) { return $null }
    Start-Sleep -Milliseconds 200
  }
  return $null
}
$cases = @(
  @{name = 'x_load_4s'; how = 'x'; wait = 4},
  @{name = 'altf4_load_5s'; how = 'altf4'; wait = 5; hide = 500},
  @{name = 'x_battle_30s'; how = 'x'; wait = 30},
  @{name = 'altf4_battle_30s'; how = 'altf4'; wait = 30},
  @{name = 'title_load_5s'; how = 'x'; wait = 10; title = 5; hide = 500; first = 200},
  @{name = 'title_battle_30s'; how = 'x'; wait = 36; title = 30; hide = 500; first = 200}
)
$limitMs = 15000
$rows = @()
$warmBad = 0
foreach ($set in @('cold', 'warm')) {
  foreach ($c in $cases) {
    $dir = Join-Path $Out "close_$set\$($c.name)"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $prof = if ($set -eq 'warm') { $warmProfile } else { Join-Path $dir 'profile' }
    New-Item -ItemType Directory -Force -Path $prof | Out-Null
    $log = Join-Path $dir 'game.log'; $err = Join-Path $dir 'game_err.log'; $flog = Join-Path $dir 'godot_file.log'
    $argList = @('--path', "`"$Project`"", '--windowed', '--resolution', '1920x1080', '--log-file', "`"$flog`"", '--', '--battle', '--quit-after', '240')
    if ($c.title) { $argList += @('--title-after', [string]$c.title) }
    $p = Start-Game $prof $argList $log $err
    $found = Find-Game $p 60
    $row = [ordered]@{set = $set; case = $c.name; how = $c.how; wait_s = $c.wait; window = [bool]$found}
    $fails = @()
    if (-not $found) {
      $fails += 'no game window'
      if (-not $p.HasExited) { Kill-Tree $p }
    } else {
      $g = $found.proc
      Start-Sleep -Seconds $c.wait
      $sw = [Diagnostics.Stopwatch]::StartNew()
      $row.sent = 'x'
      if ($c.how -eq 'x') { [void]$g.CloseMainWindow() }
      else {
        # Alt-F4 only when the game's own window is verified in front; otherwise its own window is closed directly
        $g.Refresh()
        $activated = $shell.AppActivate($g.Id)
        Start-Sleep -Milliseconds 150
        $g.Refresh()
        $front = [V1434L.User32]::GetForegroundWindow()
        if ($activated -and $g.MainWindowHandle -ne [IntPtr]::Zero -and $front -eq $g.MainWindowHandle) { $sw.Restart(); $shell.SendKeys('%{F4}'); $row.sent = 'altf4' }
        else { $row.skip = 'game not in front, closed with the title bar close'; $sw.Restart(); [void]$g.CloseMainWindow() }
      }
      $hwnd = $g.MainWindowHandle
      $row.hidden_ms = $null
      $done = $false
      while ($sw.ElapsedMilliseconds -lt $limitMs) {
        if ($row.hidden_ms -eq $null -and ([V1434L.User32]::IsIconic($hwnd) -or -not [V1434L.User32]::IsWindowVisible($hwnd))) { $row.hidden_ms = [int]$sw.ElapsedMilliseconds }
        if ($g.HasExited) { $done = $true; break }
        Start-Sleep -Milliseconds 10
      }
      if ($done) { [void]$g.WaitForExit(); [void]$p.WaitForExit(5000) }
      $row.close_to_exit_ms = [int]$sw.ElapsedMilliseconds
      if (-not $done) { $fails += "still running $limitMs ms after the close"; Kill-Tree $p }
      else {
        Start-Sleep -Milliseconds 300
        $text = (Get-Content -LiteralPath $flog -Raw -ErrorAction SilentlyContinue) + "`n" + (Get-Content -LiteralPath $log -Raw -ErrorAction SilentlyContinue) + "`n" + (Get-Content -LiteralPath $err -Raw -ErrorAction SilentlyContinue)
        $row.exit_code = $g.ExitCode
        $per = @($flog, $log) | ForEach-Object { $t1 = Get-Content -LiteralPath $_ -Raw -ErrorAction SilentlyContinue; if ($t1) { ([regex]::Matches($t1, '\[main\] quit \(')).Count } else { 0 } }
        $row.quit_window = $text -match '\[main\] quit \(window\)'
        $row.quit_lines = ($per | Measure-Object -Maximum).Maximum
        $mt = [regex]::Match($text, 'battle to title: leave frame ([0-9.]+) ms, first title frame ([0-9.]+) ms')
        if ($mt.Success) { $row.title_leave_frame_ms = [double]$mt.Groups[1].Value; $row.title_first_frame_ms = [double]$mt.Groups[2].Value }
        $mw = [regex]::Match($text, 'battle to title: worst frame in the first second ([0-9.]+) ms')
        if ($mw.Success) { $row.title_worst_first_second_ms = [double]$mw.Groups[1].Value }
        $mp = [regex]::Match($text, 'battle to title parts \(ms\): [^\r\n]*')
        if ($mp.Success) { $row.title_parts = $mp.Value }
        $row.crash = $text -match 'CrashHandlerException|Program crashed|access violation|RenderingServer is null|SCRIPT ERROR'
        if (-not $row.quit_window -or $row.quit_lines -ne 1) { $fails += 'not one window-route quit' }
        if ($row.crash) { $fails += 'crash or script error' }
        if ($g.ExitCode -ne 0) { $fails += "exit $($g.ExitCode)" }
        if ($c.title -and $row.title_leave_frame_ms -eq $null) { $fails += 'no battle to title line' }
      }
      if ($c.hide -and ($row.hidden_ms -eq $null -or $row.hidden_ms -gt $c.hide)) { $fails += "hidden after $($row.hidden_ms) ms (limit $($c.hide), issue 1518)" }
      if ($c.first -and ($row.title_first_frame_ms -eq $null -or $row.title_first_frame_ms -gt $c.first)) { $fails += "first title frame $($row.title_first_frame_ms) ms (limit $($c.first), issue 1519)" }
    }
    $row.result = if ($fails.Count) { 'FAIL: ' + ($fails -join '; ') } else { 'PASS' }
    if ($set -eq 'warm' -and $fails.Count) { $warmBad++ }
    $rows += New-Object psobject -Property $row
    Say ("close {0} {1}: {2}{3} sent={4} hidden_ms={5} first_title_frame_ms={6} worst_title_frame_first_s={7} close_to_exit_ms={8} exit={9}{10}" -f $set, $row.case,
      $(if ($set -eq 'cold') { 'reported ' } else { '' }), $row.result, $row.sent, $row.hidden_ms, $row.title_first_frame_ms, $row.title_worst_first_second_ms,
      $row.close_to_exit_ms, $row.exit_code, $(if ($row.title_parts) { " | $($row.title_parts)" } else { '' }))
    Start-Sleep -Seconds 2
  }
}
$rows | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $Out 'close_timing.json') -Encoding Ascii

$ok = $bench['warm'].pass -and $bench['cold'].cover_pass -and $warmBad -eq 0
Say ("[load10] RESULT {0} (warm load bench {1}; cold cover condition {2}; warm close items {3} of {4} cases failing; cold reported above)" -f
  $(if ($ok) { 'PASS' } else { 'FAIL' }), $(if ($bench['warm'].pass) { 'PASS' } else { 'FAIL' }), $(if ($bench['cold'].cover_pass) { 'PASS' } else { 'FAIL' }), $warmBad, $cases.Count)
if ($ok) { exit 0 } else { exit 1 }
