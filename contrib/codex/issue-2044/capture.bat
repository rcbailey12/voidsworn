@echo off
rem Board job for issue 2044. Queue only after green All checks and a passed review on the candidate.
rem Double-click from the candidate checkout, or pass its exact pushed commit as argument 1.
setlocal EnableExtensions DisableDelayedExpansion
set "ROOT=%~dp0..\..\.."
set "AFTER=%~1"
set "BEFORE=6c99aa10d54be50fc92c938d5f82dd810d61f214"
if not defined AFTER for /f %%H in ('git -C "%ROOT%" rev-parse HEAD') do set "AFTER=%%H"
if not defined AFTER exit /b 1
powershell -NoProfile -Command "if($env:AFTER -notmatch '^[0-9a-f]{40}$') { Write-Error 'Pass the full candidate commit hash.'; exit 1 }"
if errorlevel 1 exit /b 1
if /i "%AFTER%"=="%BEFORE%" (
  echo Use the pushed Build C candidate, not the before commit.
  exit /b 1
)
set "AFTER_TAG=%AFTER:~0,8%"
set "BEFORE_TAG=%BEFORE:~0,8%"
set "LB_HOME=%TEMP%\voidsworn-look-2044-%AFTER_TAG%"
set "LB_TOOL_REF=%AFTER%"
set "LB_ARGS=--part moments --moments res://bench/look_moments_2044.json --strict-moments"
set "LB_RUN_NAME="
set "LB_PRE_RUN="
set "LB_QUIET=1"
set "PC_GPU_ISSUE=2044"
set "PC_GPU_WEIGHT=1"
set "OUT=%USERPROFILE%\Downloads\voidsworn_test\board_e\issue-2044\shots"
rem The shared bench uses the canonical tmo.bat watchdog and gpu_go.txt for the 170 and 26 captures.
call "%ROOT%\tools\pc\jobs\look_bench.bat" "%AFTER%" "%BEFORE%"
if errorlevel 1 exit /b 1

rem Copy only complete, stamped review sheets. The bench lays out 170 first, then 26, with the hull code in each heading.
powershell -NoProfile -Command ^
  "$ErrorActionPreference='Stop'; $runs=Join-Path $env:LB_HOME runs; $tags=@($env:BEFORE_TAG,$env:AFTER_TAG);" ^
  "$rowsFile=Join-Path $runs ($env:AFTER_TAG + '/moments.json'); $config=Get-Content -Raw -LiteralPath $rowsFile | ConvertFrom-Json;" ^
  "$rowsHash=(Get-FileHash -Algorithm SHA256 -LiteralPath $rowsFile).Hash;" ^
  "$pairs=Join-Path $env:LB_HOME ('sheets/' + ($tags -join '_vs_') + '/moments');" ^
  "foreach($tag in $tags) { $rep=Get-Content -Raw -LiteralPath (Join-Path $runs ($tag + '/bench.json')) | ConvertFrom-Json; if($rep.warnings.Count -ne 0) { throw ($rep.warnings -join ', ') };" ^
  "  if($rep.moments_sha256 -ne $rowsHash) { throw ('Wrong moments file in run: ' + $tag) };" ^
  "  foreach($row in $config.rows) { foreach($cam in $config.cameras) { $match=@($rep.stills | Where-Object { $_.id -eq $row.id -and $_.cam -eq $cam });" ^
  "    if($match.Count -ne 1 -or $match[0].code -ne $row.expect_code -or $match[0].cells.Count -ne 3) { throw ('Incomplete matching capture: ' + $tag + ' ' + $row.id + ' c' + $cam) } } } };" ^
  "$files=@(foreach($row in $config.rows) { foreach($suffix in @('.jpg','.jpg.provenance.json')) {" ^
  "  $file=Get-Item -LiteralPath (Join-Path $pairs ($row.id + $suffix)); if($file.Length -le 0) { throw ('Empty review file: ' + $file.FullName) }; $file } });" ^
  "[void][IO.Directory]::CreateDirectory($env:OUT); foreach($file in $files) { Copy-Item -LiteralPath $file.FullName -Destination $env:OUT };" ^
  "Write-Output ('Saved ' + $config.rows.Count + ' before/after rows with sidecars to ' + $env:OUT)"
exit /b %ERRORLEVEL%
