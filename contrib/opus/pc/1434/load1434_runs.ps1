# Issue 1434 LOAD10 (with issues 1518 and 1519, Board Nov 21): one pinned checkout, graded on a WARM profile, the cold
# first launch reported alongside on the same items.
#   1. load bench, cold: godot/bench/load_1434.gd on a fresh Godot profile inside this attempt folder (no shader cache,
#      no pipeline cache, no world bakes on disk). Reported, plus its COVER line: the loading cover up on every frame
#      to play and no frame of 5 s or more (the Board's one condition on the cold pass).
#   2. load bench, warm: the same bench again on that same profile (the player's second launch onward). Graded.
#   3. close timing (from close1435_timing5.ps1, PR 1441): the six CLOSE5 cases, each on its own fresh profile (cold)
#      and then each on the warm profile from steps 1 and 2, both graded (Artoo on PR 1445: the warm reading is the
#      Board's for the 1434 load items only). Issue 1518: the window hides within
#      500 ms of the close request in altf4_load_5s, title_load_5s and title_battle_30s. Issue 1519: the first title frame
#      within 200 ms of leaving the battle in title_load_5s and title_battle_30s (the game's "[main] battle to title" line).
#      Every case must also take the window route once, exit 0 and not crash (as CLOSE5).
# Writes <Out>\load10_result.txt with one line per result (1434 load; 1518, 1519 and clean close, cold and warm) and the
# gate line "[load10] RESULT PASS" only when every one passes. Nothing outside <Out> is written; every profile lives under <Out>.
# -CloseOnly (Board, Nov 24, for PR 1950): only step 3, the six close cases cold then warm, on any checkout that prints the
# CLOSE5 lines; the warm profile is warmed by one ungraded launch (title_battle_30s's arguments) instead of the load
# bench, step 4 is skipped, and only the 1518, 1519 and clean-close grades are written.
param([Parameter(Mandatory)][string]$Godot, [Parameter(Mandatory)][string]$Project, [Parameter(Mandatory)][string]$Out, [switch]$CloseOnly, [switch]$Load37)
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
  if ($Load37 -and $argList -contains '--log-file') { $argList = @('--verbose') + $argList }
  try {
    $p = Start-Process -FilePath $Godot -ArgumentList $argList -PassThru -RedirectStandardOutput $log -RedirectStandardError $err
    $null = $p.Handle   # keeps ExitCode readable after exit (PowerShell 5.1)
  } finally { $env:APPDATA = $keepApp; $env:LOCALAPPDATA = $keepLocal }
  return $p
}

# Artoo on PR 1445: read back whether the warm launch really reuses the caches. Godot's shader cache
# (user://shader_cache) and the Vulkan pipeline cache (user://vulkan) are counted before and after each launch on the
# shared profile: a warm launch that reuses them adds few or no files, and the pipeline cache file is the same size.
function Get-CacheStat($profile) {
  $ud = Join-Path $profile 'Godot\app_userdata\Voidsworn'
  $o = [ordered]@{}
  foreach ($d in @('shader_cache', 'vulkan', 'world_bakes')) {
    $p = Join-Path $ud $d
    $files = @(if (Test-Path -LiteralPath $p) { Get-ChildItem -LiteralPath $p -Recurse -File -ErrorAction SilentlyContinue } else { @() })
    $o[$d] = @{n = $files.Count; mb = [math]::Round((($files | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)}
  }
  return $o
}
function Say-Cache($label, $before, $after) {
  $bits = foreach ($k in $after.Keys) { "$k $($before[$k].n) -> $($after[$k].n) files ($($before[$k].mb) -> $($after[$k].mb) MB)" }
  Say "cache readback, $label`: $($bits -join '; ')"
}

function Say-ExitSplit($label, $text, $exitWall) {
  $m = [regex]::Match($text, 'engine handoff wall ms (\d+)')
  $engine = if ($m.Success -and $null -ne $exitWall) { [long]$exitWall - [long]$m.Groups[1].Value } else { 'unknown' }
  $cache = [regex]::Matches($text, 'Updated PSO cache \([^)]+\)') | Select-Object -Last 1
  $pso = if ($cache) { $cache.Value } else { 'no cache update logged' }
  Say ("exit split {0}: native teardown {1} ms (includes cache save and engine joins) | {2}" -f $label, $engine, $pso)
}

# ---- 1 and 2: the load bench, cold then warm, on one profile
$warmProfile = Join-Path $Out 'profile_warm'
New-Item -ItemType Directory -Force -Path $warmProfile | Out-Null
$bench = @{}
if ($CloseOnly) {
  $d = Join-Path $Out 'warmup'
  New-Item -ItemType Directory -Force -Path $d | Out-Null
  $p = Start-Game $warmProfile @('--path', "`"$Project`"", '--windowed', '--resolution', '1920x1080', '--', '--battle', '--quit-after', '240', '--title-after', '30') (Join-Path $d 'log.txt') (Join-Path $d 'log_err.txt')
  if (-not $p.WaitForExit(60 * 1000)) { $null = $p.CloseMainWindow(); if (-not $p.WaitForExit(15000)) { Kill-Tree $p } }
  Say "close only: one ungraded warm-up launch on the warm profile (exit $($p.ExitCode))"
}
foreach ($pass in @($(if ($CloseOnly) { @() } else { @('cold', 'warm') }))) {
  $d = Join-Path $Out "load_$pass"
  New-Item -ItemType Directory -Force -Path $d | Out-Null
  $argList = @('--path', "`"$Project`"", '--fullscreen', '--script', 'res://bench/load_1434.gd', '--', '--out', "`"$d`"", '--pass', $pass)
  $c0 = Get-CacheStat $warmProfile
  $p = Start-Game $warmProfile $argList (Join-Path $d 'log.txt') (Join-Path $d 'log_err.txt')
  if (-not $p.WaitForExit(1500 * 1000)) { Kill-Tree $p; Say "load $pass`: FAIL: still running after 1500 s, stopped" }
  Say-Cache "load $pass" $c0 (Get-CacheStat $warmProfile)
  $txt = Join-Path $d 'load_result.txt'
  $r = if (Test-Path -LiteralPath $txt) { Get-Content -LiteralPath $txt -Raw } else { '' }
  $bench[$pass] = @{
    result = [regex]::Match($r, '\[load1434\] RESULT [^\r\n]*').Value
    cover = [regex]::Match($r, '\[load1434\] COVER [^\r\n]*').Value
    pass = $r -match '\[load1434\] RESULT PASS'
    cover_pass = $r -match '\[load1434\] COVER PASS'
    title = [regex]::Match($r, '\[load1434\] title (PASS|FAIL)[^\r\n]*').Value
    title_pass = $r -match '\[load1434\] title PASS'
    title_split = [regex]::Match($r, '\[load1434\] title worst frames split: [^\r\n]*').Value
    s25_max_ms = $null
  }
  $s25 = [regex]::Match($r, '(?m)^\[load1434\] s25 worst cover frames split: (\d+) ms')
  if ($s25.Success) { $bench[$pass].s25_max_ms = [int]$s25.Groups[1].Value }
  if (-not $r) { Say "load $pass`: FAIL: no load_result.txt (see load_$pass\log.txt)" }
  else {
    Say "load $pass`: $($bench[$pass].result)"; Say "load $pass`: $($bench[$pass].cover)"
    Say "load $pass`: $($bench[$pass].title)"; Say "load $pass`: $($bench[$pass].title_split)"
  }
  Start-Sleep -Seconds 3
}

# ---- 3: the close cases (close1435_timing5.ps1's method), cold set then warm set
Add-Type -Namespace V1434L -Name User32 -MemberDefinition @'
[DllImport("user32.dll")] public static extern System.IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern bool IsIconic(System.IntPtr hWnd);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(System.IntPtr hWnd);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(System.IntPtr hWnd, System.Text.StringBuilder buf, int max);
[DllImport("user32.dll")] public static extern bool PostMessage(System.IntPtr hWnd, uint msg, System.IntPtr wParam, System.IntPtr lParam);
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
$cw0 = Get-CacheStat $warmProfile
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
        # Alt-F4 is the system menu's Close: WM_SYSCOMMAND SC_CLOSE, posted straight to the game's window (Board, Nov 23:
        # AppActivate and SendKeys need the focus, which Windows refuses for 200 s after Ryan touches the PC, so the old
        # key press came back UNVERIFIED or never arrived). The same message the key makes, no focus needed.
        $g.Refresh()
        if ($g.MainWindowHandle -ne [IntPtr]::Zero) {
          $sw.Restart()
          if ([V1434L.User32]::PostMessage($g.MainWindowHandle, 0x0112, [IntPtr]0xF060, [IntPtr]::Zero)) { $row.sent = 'altf4' }
          else { $row.skip = 'Alt-F4 UNVERIFIED: the system close could not be posted, closed with the title bar close'; [void]$g.CloseMainWindow() }
        }
        else { $row.skip = 'Alt-F4 UNVERIFIED: no game window handle, closed with the title bar close'; $sw.Restart(); [void]$g.CloseMainWindow() }
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
        if ($Load37) { Say-ExitSplit "$set $($c.name)" $text (([DateTimeOffset]$g.ExitTime).ToUnixTimeMilliseconds()) }
        $per = @($flog, $log) | ForEach-Object { $t1 = Get-Content -LiteralPath $_ -Raw -ErrorAction SilentlyContinue; if ($t1) { ([regex]::Matches($t1, '\[main\] quit \(')).Count } else { 0 } }
        $row.quit_window = $text -match '\[main\] quit \(window\)'
        $row.quit_lines = ($per | Measure-Object -Maximum).Maximum
        $mt = [regex]::Match($text, 'battle to title: leave frame ([0-9.]+) ms, first title frame ([0-9.]+) ms')
        if ($mt.Success) { $row.title_leave_frame_ms = [double]$mt.Groups[1].Value; $row.title_first_frame_ms = [double]$mt.Groups[2].Value }
        $mw = [regex]::Match($text, 'battle to title: worst frame in the first second ([0-9.]+) ms')
        if ($mw.Success) { $row.title_worst_first_second_ms = [double]$mw.Groups[1].Value }
        $ml = [regex]::Match($text, '\[main\] loading at the close: ([^\r\n]*)')
        $row.loading_at_close = if ($ml.Success) { $ml.Groups[1].Value } else { $null }
        $mf = [regex]::Match($text, '\[main\] frames before the close, oldest first: ([^\r\n]*)')
        $row.frames_before_close = if ($mf.Success) { $mf.Groups[1].Value } else { $null }
        $mp = [regex]::Match($text, 'battle to title parts \(ms\): [^\r\n]*')
        if ($mp.Success) { $row.title_parts = $mp.Value }
        $row.crash = $text -match 'CrashHandlerException|Program crashed|access violation|RenderingServer is null|SCRIPT ERROR'
        if (-not $row.quit_window -or $row.quit_lines -ne 1) { $fails += 'not one window-route quit' }
        if ($row.crash) { $fails += 'crash or script error' }
        if ($g.ExitCode -ne 0) { $fails += "exit $($g.ExitCode)" }
        if ($c.title -and $row.title_leave_frame_ms -eq $null) { $fails += 'no battle to title line' }
      }
    }
    # three separate gradings per case (Artoo on PR 1445): a clean close (window route once, exit 0, no crash or hang),
    # issue 1518's hide time, issue 1519's first title frame; an Alt-F4 case whose keys could not be sent is UNVERIFIED
    $row.clean = if ($fails.Count) { 'FAIL: ' + ($fails -join '; ') } else { 'PASS' }
    $row.g1518 = '-'
    if ($c.hide) {
      $row.g1518 = if ($row.hidden_ms -eq $null -or $row.hidden_ms -gt $c.hide) { "FAIL (hidden after $($row.hidden_ms) ms, limit $($c.hide))" } elseif ($row.skip) { 'UNVERIFIED (Alt-F4 not sent)' } elseif (-not $row.loading_at_close -or $row.loading_at_close -eq 'nothing') { 'UNVERIFIED (nothing was loading at the close)' } else { 'PASS' }
    }
    $row.g1519 = '-'
    if ($c.first) {
      $row.g1519 = if ($row.title_first_frame_ms -eq $null -or $row.title_first_frame_ms -gt $c.first) { "FAIL (first title frame $($row.title_first_frame_ms) ms, limit $($c.first))" } else { 'PASS' }
    }
    $row.result = if ($row.clean -ne 'PASS' -or $row.g1518 -like 'FAIL*' -or $row.g1519 -like 'FAIL*') { 'FAIL' } elseif ($row.skip -or $row.g1518 -like 'UNVERIFIED*') { 'UNVERIFIED' } else { 'PASS' }
    $rows += New-Object psobject -Property $row
    if ($row.frames_before_close) { Say ("close {0} {1}: frames before the close: {2}" -f $set, $row.case, $row.frames_before_close) }
    Say ("close {0} {1}: {2}{3} clean={11} 1518={12} 1519={13}{14} sent={4} loading_at_close=[{15}] hidden_ms={5} first_title_frame_ms={6} worst_title_frame_first_s={7} close_to_exit_ms={8} exit={9}{10}" -f $set, $row.case,
      '', $row.result, $row.sent, $row.hidden_ms, $row.title_first_frame_ms, $row.title_worst_first_second_ms,
      $row.close_to_exit_ms, $row.exit_code, $(if ($row.title_parts) { " | $($row.title_parts)" } else { '' }), $row.clean, $row.g1518, $row.g1519, $(if ($row.skip) { " ($($row.skip))" } else { '' }), $row.loading_at_close)
    Start-Sleep -Seconds 2
  }
}
Say-Cache 'the cold then warm close launches' $cw0 (Get-CacheStat $warmProfile)
$rows | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $Out 'close_timing.json') -Encoding Ascii

# ---- 4: the title from launch (issue 1518, Artoo on PR 1445, 6784b6b1): the title waits a frame at a time for the
# launch's campaign host read, so launch to the first painted menu is measured on its own, cold without a save and cold
# with a valid saved run (its first button "Continue run"), each on a fresh profile; no menu in 20 s fails plainly.
# The game prints "[main] title menu painted at N ms after the engine started (first button: ...)"; the case closes the
# window after 20 s and reads that line after the exit.
$launch = [ordered]@{}
foreach ($lc in @($(if ($CloseOnly) { @() } else { @(@{name = 'title_launch_nosave'; save = $false; want = 'New run'}, @{name = 'title_launch_save'; save = $true; want = 'Continue run'}) }))) {
  $dir = Join-Path $Out "close_cold\$($lc.name)"
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $prof = Join-Path $dir 'profile'
  New-Item -ItemType Directory -Force -Path $prof | Out-Null
  $log = Join-Path $dir 'game.log'; $err = Join-Path $dir 'game_err.log'; $flog = Join-Path $dir 'godot_file.log'
  $note = ''
  if ($lc.save) {
    $sp = Start-Game $prof @('--headless', '--path', "`"$Project`"", '-s', 'res://bench/write_save_1434.gd') (Join-Path $dir 'save.log') (Join-Path $dir 'save_err.log')
    if (-not $sp.WaitForExit(120000)) { Kill-Tree $sp }
    $st = Get-Content -LiteralPath (Join-Path $dir 'save.log') -Raw -ErrorAction SilentlyContinue
    if ($st -notmatch '\[save1434\] PASS') { $note = 'no saved run was written (see save.log)' }
  }
  $p = Start-Game $prof @('--path', "`"$Project`"", '--windowed', '--resolution', '1920x1080', '--log-file', "`"$flog`"", '--', '--quit-after', '240') $log $err
  $found = Find-Game $p 60
  $verdict = 'FAIL'; $why = @()
  if ($note) { $why += $note }
  if (-not $found) { $why += 'no game window'; if (-not $p.HasExited) { Kill-Tree $p } }
  else {
    Start-Sleep -Seconds 20
    $g = $found.proc
    $closeWall = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    if (-not $g.CloseMainWindow()) { $why += 'close could not be sent' }
    $exitWall = $null
    if (-not $g.WaitForExit(15000)) { $why += 'still running 15 s after the close'; Kill-Tree $p }
    else {
      $exitWall = ([DateTimeOffset]$g.ExitTime).ToUnixTimeMilliseconds()
      if ($g.ExitCode -ne 0) { $why += "exit $($g.ExitCode)" }
      if ($exitWall - $closeWall -gt 15000) { $why += 'close to exit exceeded 15 s' }
      [void]$p.WaitForExit(5000)
    }
    Start-Sleep -Milliseconds 300
    $text = (Get-Content -LiteralPath $flog -Raw -ErrorAction SilentlyContinue) + "`n" + (Get-Content -LiteralPath $log -Raw -ErrorAction SilentlyContinue) + "`n" + (Get-Content -LiteralPath $err -Raw -ErrorAction SilentlyContinue)
    $mr = [regex]::Match($text, '\[main\] ready at ([0-9]+) ms')
    if ($Load37) {
      Say-ExitSplit "cold $($lc.name)" $text $exitWall
      $closeMs = if ($null -ne $exitWall) { $exitWall - $closeWall } else { 'timeout' }
      Say ("title launch cold {0}: close to exit {1} ms (2 s goal, 15 s cap)" -f $lc.name, $closeMs)
    }
    $mm = [regex]::Match($text, '\[main\] title menu painted at ([0-9]+) ms after the engine started \(first button: ([^)]*)\)')
    $ready = if ($mr.Success) { $mr.Groups[1].Value } else { '-' }
    if (-not $mm.Success) { $why += 'no menu painted within the 20 s' }
    else {
      $painted = [int]$mm.Groups[1].Value
      if ($painted -gt 20000) { $why += "menu painted only at $painted ms" }
      if ($mm.Groups[2].Value -ne $lc.want) { $why += "first button '$($mm.Groups[2].Value)', expected '$($lc.want)'" }
    }
    if ($text -match 'CrashHandlerException|Program crashed|access violation|RenderingServer is null|SCRIPT ERROR') { $why += 'crash or script error' }
    if ($why.Count -eq 0) { $verdict = 'PASS' }
    Say ("title launch cold {0}: {1} main ready at {2} ms, menu painted at {3} ms (first button: {4}){5}" -f $lc.name, $verdict, $ready,
      $(if ($mm.Success) { $mm.Groups[1].Value } else { '-' }), $(if ($mm.Success) { $mm.Groups[2].Value } else { '-' }), $(if ($why.Count) { ' | ' + ($why -join '; ') } else { '' }))
  }
  if (-not $found) { Say ("title launch cold {0}: FAIL | {1}" -f $lc.name, ($why -join '; ')) }
  $launch[$lc.name] = $verdict
  Start-Sleep -Seconds 2
}

# Separate results (Artoo on PR 1445): the Board's warm grading covers the issue 1434 load items only; issues 1518 and
# 1519 keep their own limits on BOTH profiles, and every close must be clean on both.
function Set-Grade($set, $key) {
  $r = @($rows | Where-Object { $_.set -eq $set -and $_.$key -ne '-' } | ForEach-Object { $_.$key })
  if (@($r | Where-Object { $_ -like 'FAIL*' }).Count) { return 'FAIL' }
  if (@($r | Where-Object { $_ -like 'UNVERIFIED*' }).Count) { return 'UNVERIFIED' }
  return 'PASS'
}
$grades = [ordered]@{}
if (-not $CloseOnly) {
$grades['1434 load (warm bench, cold COVER)'] = if ($bench['warm'].pass -and $bench['cold'].cover_pass) { 'PASS' } else { 'FAIL' }
# the two LOAD13 targets on lines of their own (Board, Nov 21): (a) the warm title backdrop's frame, (b) the cold close
# while the title backdrop loads; both are also inside the lines around them
$grades['target a: warm title backdrop frame (bench title line)'] = if ($bench['warm'].title_pass) { 'PASS' } else { 'FAIL' }
$tl = @($rows | Where-Object { $_.set -eq 'cold' -and $_.case -eq 'title_load_5s' })
# target b counts only when the backdrop itself was loading at the close; a world bake alone is UNVERIFIED (Artoo on PR 1445)
$grades['target b: cold close during the title load hides within 500 ms'] = if ($tl.Count -eq 1) { $(if ($tl[0].g1518 -like 'FAIL*') { 'FAIL' } elseif ($tl[0].g1518 -like 'UNVERIFIED*') { 'UNVERIFIED' } elseif ([string]$tl[0].loading_at_close -notmatch '(^|, )backdrop ') { 'UNVERIFIED (the backdrop was not loading at the close)' } else { 'PASS' }) } else { 'FAIL' }
}
foreach ($set in @('cold', 'warm')) {
  $grades["1518 close hides within 500 ms, $set"] = Set-Grade $set 'g1518'
  $grades["1519 first title frame within 200 ms, $set"] = Set-Grade $set 'g1519'
  $grades["every close clean, $set"] = Set-Grade $set 'clean'
}
if (-not $CloseOnly) { $grades['title launch to first painted menu within 20 s, cold, no save and with a saved run'] = if (@($launch.Values | Where-Object { $_ -ne 'PASS' }).Count -eq 0 -and $launch.Count -eq 2) { 'PASS' } else { 'FAIL' } }
if ($Load37 -and -not $CloseOnly) {
  foreach ($set in @('cold', 'warm')) {
    $ms = $bench[$set].s25_max_ms
    $grades["LOAD37 s25 cover under 5000 ms, $set"] = if ($null -ne $ms -and $ms -lt 5000) { 'PASS' } else { 'FAIL' }
  }
}
foreach ($k in $grades.Keys) { Say "[load10] $k`: $($grades[$k])" }
$ok = @($grades.Values | Where-Object { $_ -ne 'PASS' }).Count -eq 0
Say ("[load10] RESULT {0} (every line above must PASS; an Alt-F4 case that could not send its keys is UNVERIFIED, never PASS)" -f $(if ($ok) { 'PASS' } else { 'FAIL' }))
if ($ok) { exit 0 } else { exit 1 }
