# Issue 1435 PC proof, part 2 (v3: closes the GAME's window, not the console wrapper's; v2: Alt-F4 only when the game
# window is verified in front, Board Nov 21). v2 ran JW_GODOT, the console wrapper exe, and closed ITS main window
# (the console): exits 0xC000013A / 0xC0000602 with no quit line. v3 finds the wrapper's child game process and its
# own window (window class recorded; console and terminal windows refused) and closes that. a real window close in the game, timed from the close request to process exit.
# Launches the pinned checkout's game windowed straight into a quick battle (Main --battle), waits a set time, then
# closes it the way a player does: "x" = the title bar close (WM_CLOSE via CloseMainWindow), "altf4" = Alt-F4 keys.
# Each launch gets its own fresh profile inside the attempt folder. Reads the game's own log for the quit route
# ("[main] quit (window)"), the fx retire and drain lines, and crash or teardown errors. Writes close_timing.txt and
# close_timing.json in -Out; exit 0 only when every close took the window route and ended cleanly in time.
param([Parameter(Mandatory)][string]$Godot, [Parameter(Mandatory)][string]$Project, [Parameter(Mandatory)][string]$Out)
$ErrorActionPreference = 'Stop'
$cases = @(
  @{name = 'x_load_4s'; how = 'x'; wait = 4},
  @{name = 'x_load_7s'; how = 'x'; wait = 7},
  @{name = 'altf4_load_5s'; how = 'altf4'; wait = 5},
  @{name = 'x_battle_30s'; how = 'x'; wait = 30},
  @{name = 'altf4_battle_30s'; how = 'altf4'; wait = 30}
)
$limitMs = 15000
New-Item -ItemType Directory -Force -Path $Out | Out-Null
$txt = Join-Path $Out 'close_timing.txt'
"close timing, project $Project, $(Get-Date -Format s)" | Set-Content -LiteralPath $txt -Encoding Ascii
$shell = New-Object -ComObject WScript.Shell
Add-Type -Namespace V1435b -Name User32 -MemberDefinition @'
[DllImport("user32.dll")] public static extern System.IntPtr GetForegroundWindow();
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(System.IntPtr hWnd, System.Text.StringBuilder buf, int max);
'@
function Get-WindowClass($h) { $b = New-Object Text.StringBuilder 256; [void][V1435b.User32]::GetClassName($h, $b, 256); $b.ToString() }
# The game process: the wrapper itself when it is the GUI exe, else its child Godot/Voidsworn process; only a window
# that is not a console or terminal window counts.
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
$rows = @()
$bad = 0
$keepApp = $env:APPDATA; $keepLocal = $env:LOCALAPPDATA
foreach ($c in $cases) {
  $dir = Join-Path $Out $c.name
  New-Item -ItemType Directory -Force -Path (Join-Path $dir 'profile') | Out-Null
  $log = Join-Path $dir 'game.log'
  $err = Join-Path $dir 'game_err.log'
  $flog = Join-Path $dir 'godot_file.log'
  $env:APPDATA = Join-Path $dir 'profile'; $env:LOCALAPPDATA = $env:APPDATA
  try {
    $argList = @('--path', "`"$Project`"", '--windowed', '--resolution', '1920x1080', '--log-file', "`"$flog`"", '--', '--battle', '--quit-after', '240')
    $p = Start-Process -FilePath $Godot -ArgumentList $argList -PassThru -RedirectStandardOutput $log -RedirectStandardError $err
    $null = $p.Handle   # keeps ExitCode readable after exit (PowerShell 5.1)
  } finally { $env:APPDATA = $keepApp; $env:LOCALAPPDATA = $keepLocal }
  $found = Find-Game $p 60
  $row = [ordered]@{case = $c.name; how = $c.how; wait_s = $c.wait; window = [bool]$found}
  if (-not $found) {
    $row.result = 'FAIL: no game window'; $bad++
    if (-not $p.HasExited) { $p.Kill() }
  } else {
    $g = $found.proc
    $row.game_exe = $g.ProcessName; $row.wrapper_exe = $p.ProcessName; $row.window_class = $found.cls
    Start-Sleep -Seconds $c.wait
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $row.sent = 'x'
    if ($c.how -eq 'x') { [void]$g.CloseMainWindow() }
    else {
      # Keys go to whatever window is in front: send Alt-F4 only when the game's own window is verified in front,
      # otherwise skip the keys and close the game's window directly (never another app's window).
      $g.Refresh()
      $activated = $shell.AppActivate($g.Id)
      Start-Sleep -Milliseconds 150
      $g.Refresh()
      $front = [V1435b.User32]::GetForegroundWindow()
      if ($activated -and $g.MainWindowHandle -ne [IntPtr]::Zero -and $front -eq $g.MainWindowHandle) {
        $sw.Restart(); $shell.SendKeys('%{F4}'); $row.sent = 'altf4'
      } else {
        $row.skip = 'SKIP: game not in front, closed with the title bar close instead'
        $sw.Restart(); [void]$g.CloseMainWindow()
      }
    }
    $done = $g.WaitForExit($limitMs)
    $sw.Stop()
    if ($done) { [void]$p.WaitForExit(5000) }
    $row.close_to_exit_ms = [int]$sw.ElapsedMilliseconds
    if (-not $done) { $row.result = "FAIL: still running $limitMs ms after the close"; $bad++; $g.Kill(); if (-not $p.HasExited) { $p.Kill() }; [void]$p.WaitForExit(5000) }
    else {
      Start-Sleep -Milliseconds 300
      $text = (Get-Content -LiteralPath $flog -Raw -ErrorAction SilentlyContinue) + "`n" + (Get-Content -LiteralPath $log -Raw -ErrorAction SilentlyContinue) + "`n" + (Get-Content -LiteralPath $err -Raw -ErrorAction SilentlyContinue)
      $row.exit_code = $g.ExitCode; $row.wrapper_exit_code = $(if ($p.HasExited) { $p.ExitCode } else { $null })
      $row.quit_window = $text -match '\[main\] quit \(window\)'
      $row.quit_lines = ([regex]::Matches($text, '\[main\] quit \(')).Count
      $row.fx_retired = @([regex]::Matches($text, '\[fx\] left with [^\r\n]*') | ForEach-Object { $_.Value })
      $row.cut_pending_at_close = $row.fx_retired.Count -gt 0
      $row.fx_drained = @([regex]::Matches($text, '\[fx\] drained [^\r\n]*') | ForEach-Object { $_.Value })
      $row.crash = $text -match 'CrashHandlerException|Program crashed|access violation|RenderingServer is null|SCRIPT ERROR'
      $row.still_in_use = @([regex]::Matches($text, '[^\r\n]*still in use at exit[^\r\n]*') | ForEach-Object { $_.Value })
      if ($row.quit_window -and $row.quit_lines -eq 1 -and -not $row.crash -and $g.ExitCode -eq 0) { $row.result = 'PASS' }
      else { $row.result = 'FAIL: see game.log'; $bad++ }
    }
  }
  $rows += New-Object psobject -Property $row
  ("{0}: {1}{8} sent={9} pending_cut={10} close_to_exit_ms={2} exit={3} quit_window={4} retired=[{5}] drained=[{6}] crash={7}" -f $row.case, $row.result,
    $row.close_to_exit_ms, $row.exit_code, $row.quit_window, ($row.fx_retired -join '; '), ($row.fx_drained -join '; '), $row.crash, $(if ($row.skip) { " ($($row.skip))" } else { '' }), $row.sent, $row.cut_pending_at_close) |
    Add-Content -LiteralPath $txt -Encoding Ascii
  Start-Sleep -Seconds 2
}
$rows | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $Out 'close_timing.json') -Encoding Ascii
"failures=$bad" | Add-Content -LiteralPath $txt -Encoding Ascii
Get-Content -LiteralPath $txt
if ($bad) { exit 1 } else { exit 0 }
