@echo off
rem Run from the synced build folder. The queue job calls prepare before g2_export.bat and capture after export succeeds.
setlocal DisableDelayedExpansion
if not exist godot\project.godot (
  echo FAIL: run g2_playtest_capture.bat from the synced build folder
  exit /b 1
)
if /i "%~1"=="prepare" goto prepare
if /i "%~1"=="capture" goto capture
echo Usage: g2_playtest_capture.bat prepare ^<full archive commit^> ^<git %%cI date^> or capture ^<shots folder^>
exit /b 1

:prepare
set "VS_BUILD_COMMIT=%~2"
set "VS_BUILD_DATE=%~3"
powershell -NoProfile -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "if ($env:VS_BUILD_COMMIT -cnotmatch '\A(?!0+\z)(?:[0-9a-f]{40}|[0-9a-f]{64})\z' -or -not $env:VS_BUILD_DATE) { throw 'Build provenance requires the full archive commit and its git %%cI date' };" ^
  "$culture = [Globalization.CultureInfo]::InvariantCulture;" ^
  "$date = [DateTimeOffset]::ParseExact($env:VS_BUILD_DATE, 'yyyy-MM-ddTHH:mm:sszzz', $culture);" ^
  "Copy-Item -LiteralPath 'tools/picture_font.json' -Destination 'godot/tools/picture_font.json' -Force;" ^
  "@{commit = $env:VS_BUILD_COMMIT; commit_date = $date.UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ssZ', $culture)} | ConvertTo-Json -Compress | Set-Content -LiteralPath 'godot/build_info.json' -Encoding Ascii"
exit /b %ERRORLEVEL%

:capture
if "%~2"=="" exit /b 1
rem The exported game has no script name for the GPU gate to label its claim (exit 126 without one; issue 1369).
if not defined PC_GPU_ISSUE if not defined JOB_DIR set "PC_GPU_ISSUE=g2_playtest_capture"
set "OUT=%~f2"
set "RESULT=%OUT%\result.txt"
set "GAME=%CD%\export\Voidsworn.console.exe"
set "TMO=%CD%\tools\pc\tmo.bat"
if not exist "%OUT%" mkdir "%OUT%"
if not exist "%OUT%" exit /b 1
if not exist "%GAME%" (
  echo FAIL: playtest export is missing >> "%RESULT%"
  exit /b 1
)
rem A zero exit must produce new pictures. A rerun with existing pictures needs a fresh shots folder.
for %%F in ("%OUT%\title_*.png" "%OUT%\title_*.png.provenance.json" "%OUT%\battle_3840x2160\*.png*" "%OUT%\battle_1920x1080\*.png*" "%OUT%\battle_3840x2160\ui_check.txt" "%OUT%\battle_1920x1080\ui_check.txt") do if exist "%%~fF" (
  echo FAIL: capture evidence already exists, use a fresh shots folder >> "%RESULT%"
  exit /b 1
)
set "VS_BOARD_LOOK="
set "FAILED=0"
for %%R in (3840x2160 1920x1080) do call :title %%R title_%%R "title %%R"
call :title 1920x1080 title_credits_1920x1080 "credits 1920x1080" --title-open credits
for %%R in (3840x2160 1920x1080) do call :battle %%R
dir /s /b "%OUT%" > "%OUT%\files.txt"
exit /b %FAILED%

:title
call "%TMO%" 150 "%GAME%" --resolution %1 -- --title-shot "%OUT%\%2.png" --window %1 --quit-after 120 %4 %5 > "%OUT%\%2_log.txt" 2>&1
call :status "%~3" %ERRORLEVEL%
call :pair "%OUT%\%2.png"
findstr /c:"[title" /c:"[main] capture" "%OUT%\%2_log.txt" > "%OUT%\%2_check.txt"
exit /b 0

:battle
set "BATTLE=%OUT%\battle_%1"
if not exist "%BATTLE%" mkdir "%BATTLE%"
call "%TMO%" 300 "%GAME%" --resolution %1 -- --seed 4242 --fac hegemony --map belt --shots "%BATTLE%" --ui-shots "%BATTLE%" --window %1 --quit-after 260 > "%BATTLE%_log.txt" 2>&1
call :status "battle %1" %ERRORLEVEL%
call :pair "%BATTLE%\01_1_battle_start.png"
for %%F in ("%BATTLE%\*.png") do if exist "%%~fF" call :pair "%%~fF"
if not exist "%BATTLE%\ui_check.txt" (
  echo FAIL: battle %1 did not finish its UI capture >> "%RESULT%"
  set "FAILED=1"
)
findstr /c:"[ui-check]" /c:"[hud]" /c:"[main] capture" "%BATTLE%_log.txt" > "%BATTLE%_check.txt"
exit /b 0

:status
echo %~1 exit %2 >> "%RESULT%"
if not "%2"=="0" set "FAILED=1"
exit /b 0

:pair
if exist "%~1" if exist "%~1.provenance.json" exit /b 0
echo FAIL: missing picture or provenance sidecar for %~1 >> "%RESULT%"
set "FAILED=1"
exit /b 0
