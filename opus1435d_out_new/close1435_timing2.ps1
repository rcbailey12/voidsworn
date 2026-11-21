# Issue 1435 PC proof, part 2 (v2: Alt-F4 only when the game window is verified in front, Board Nov 21): a real window close in the game, timed from the close request to process exit.
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
Add-Type -Namespace V1435 -Name User32 -MemberDefinition '[DllImport("user32.dll")] public static extern System.IntPtr GetForegroundWindow();'
$rows = @()
$bad = 0
$keepApp = $env:APPDATA; $keepLocal = $env:LOCALAPPDATA
foreach ($c in $cases) {
  $dir = Join-Path $Out $c.name
  New-Item -ItemType Directory -Force -Path (Join-Path $dir 'profile') | Out-Null
  $log = Join-Path $dir 'game.log'
  $err = Join-Path $dir 'game_err.log'
  $env:APPDATA = Join-Path $dir 'profile'; $env:LOCALAPPDATA = $env:APPDATA
  try {
    $argList = @('--path', "`"$Project`"", '--windowed', '--resolution', '1920x1080', '--', '--battle', '--quit-after', '240')
    $p = Start-Process -FilePath $Godot -ArgumentList $argList -PassThru -RedirectStandardOutput $log -RedirectStandardError $err
    $null = $p.Handle   # keeps ExitCode readable after exit (PowerShell 5.1)
  } finally { $env:APPDATA = $keepApp; $env:LOCALAPPDATA = $keepLocal }
  $t0 = Get-Date
  while ($p.MainWindowHandle -eq 0 -and -not $p.HasExited -and ((Get-Date) - $t0).TotalSeconds -lt 60) { Start-Sleep -Milliseconds 100; $p.Refresh() }
  $row = [ordered]@{case = $c.name; how = $c.how; wait_s = $c.wait; window = ($p.MainWindowHandle -ne 0)}
  if ($p.HasExited -or $p.MainWindowHandle -eq 0) {
    $row.result = 'FAIL: no window'; $bad++
    if (-not $p.HasExited) { $p.Kill() }
  } else {
    Start-Sleep -Seconds $c.wait
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $row.sent = 'x'
    if ($c.how -eq 'x') { [void]$p.CloseMainWindow() }
    else {
      # Keys go to whatever window is in front: send Alt-F4 only when the game's own window is verified in front,
      # otherwise skip the keys and close the game's window directly (never another app's window).
      $p.Refresh()
      $activated = $shell.AppActivate($p.Id)
      Start-Sleep -Milliseconds 150
      $p.Refresh()
      $front = [V1435.User32]::GetForegroundWindow()
      if ($activated -and $p.MainWindowHandle -ne [IntPtr]::Zero -and $front -eq $p.MainWindowHandle) {
        $sw.Restart(); $shell.SendKeys('%{F4}'); $row.sent = 'altf4'
      } else {
        $row.skip = 'SKIP: game not in front, closed with the title bar close instead'
        $sw.Restart(); [void]$p.CloseMainWindow()
      }
    }
    $done = $p.WaitForExit($limitMs)
    $sw.Stop()
    $row.close_to_exit_ms = [int]$sw.ElapsedMilliseconds
    if (-not $done) { $row.result = "FAIL: still running $limitMs ms after the close"; $bad++; $p.Kill(); [void]$p.WaitForExit(5000) }
    else {
      Start-Sleep -Milliseconds 300
      $text = (Get-Content -LiteralPath $log -Raw -ErrorAction SilentlyContinue) + "`n" + (Get-Content -LiteralPath $err -Raw -ErrorAction SilentlyContinue)
      $row.exit_code = $p.ExitCode
      $row.quit_window = $text -match '\[main\] quit \(window\)'
      $row.quit_lines = ([regex]::Matches($text, '\[main\] quit \(')).Count
      $row.fx_retired = @([regex]::Matches($text, '\[fx\] left with [^\r\n]*') | ForEach-Object { $_.Value })
      $row.cut_pending_at_close = $row.fx_retired.Count -gt 0
      $row.fx_drained = @([regex]::Matches($text, '\[fx\] drained [^\r\n]*') | ForEach-Object { $_.Value })
      $row.crash = $text -match 'CrashHandlerException|Program crashed|access violation|RenderingServer is null|SCRIPT ERROR'
      $row.still_in_use = @([regex]::Matches($text, '[^\r\n]*still in use at exit[^\r\n]*') | ForEach-Object { $_.Value })
      if ($row.quit_window -and $row.quit_lines -eq 1 -and -not $row.crash -and $p.ExitCode -eq 0) { $row.result = 'PASS' }
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
