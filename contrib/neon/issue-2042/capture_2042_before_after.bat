@echo off
rem Issue 2042 (AAA effects sweep, Build A): before/after look bench captures at cameras 170 and 26.
rem Covers all 4 Build A items per faction where they differ:
rem   1. Directional RCS cone jets (voidsworn, hegemony, corsair, ithar, chorus, deathless)
rem   2. Moving engine trails anchored to nozzle and tapered (hegemony, corsair, chorus, deathless)
rem   3. Main engine plumes with bright core and outer wash (all 6 factions)
rem   4. Strike craft trails unified on SH.CRAFT_TRAIL (hegemony, ithar, chorus)
rem
rem Queued by the Board on Ryan's PC GPU line after checks are green and review passes (RULEBOOK 3.12, R407).
rem Double-click or run from the PC queue:
rem   capture_2042_before_after.bat [AFTER_REF] [BEFORE_REF] [go]
rem Defaults: AFTER_REF=origin/neon/issue-2042, BEFORE_REF=origin/main.
rem Sheets land in %USERPROFILE%\Downloads\voidsworn_test\look_bench_2042\sheets\.
setlocal EnableExtensions
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "AFTER=%~1"
set "BEFORE=%~2"
set "GOWAIT=%~3"
if "%AFTER%"=="" set "AFTER=origin/neon/issue-2042"
if "%BEFORE%"=="" set "BEFORE=origin/main"

set "PC_GPU_ISSUE=2042"
set "LB_HOME=%VT%\look_bench_2042"
set "LB_TOOL_REF=%AFTER%"
rem Pass both LB_MOMENTS (#2007+ launcher) and LB_ARGS (current main launcher) so either installed launcher captures only the 19 Build A rows.
set "LB_MOMENTS=res://bench/look_moments_2042.json"
set "LB_ARGS=--part moments --moments res://bench/look_moments_2042.json"

set "LB_BAT="
if exist "%VT%\tools_live\current.txt" (
  set /p TLV=<"%VT%\tools_live\current.txt"
)
if defined TLV if exist "%VT%\tools_live\%TLV%\pc\jobs\look_bench.bat" (
  set "LB_BAT=%VT%\tools_live\%TLV%\pc\jobs\look_bench.bat"
)
if not defined LB_BAT if exist "%~dp0..\..\..\tools\pc\jobs\look_bench.bat" (
  set "LB_BAT=%~dp0..\..\..\tools\pc\jobs\look_bench.bat"
)
if not defined LB_BAT (
  echo FAILED: look_bench.bat not found in tools_live or repo tools\pc\jobs
  exit /b 2
)

echo Running issue 2042 Build A before/after look bench:
echo   after:   %AFTER%
echo   before:  %BEFORE%
echo   moments: res://bench/look_moments_2042.json (cameras 170 and 26)
echo   output:  %LB_HOME%\sheets\
call "%LB_BAT%" "%AFTER%" "%BEFORE%" "%GOWAIT%"
set "LB_RC=%ERRORLEVEL%"
if not "%LB_RC%"=="0" exit /b %LB_RC%
rem Verify that every run folder captured all 19 Build A row IDs at both cameras 170 and 26 (fail loudly if wrong rows ran).
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $want=@('b2042_rcs_voidsworn','b2042_rcs_hegemony','b2042_rcs_corsair','b2042_rcs_ithar','b2042_rcs_chorus','b2042_rcs_deathless','b2042_trail_hegemony','b2042_trail_corsair','b2042_trail_chorus','b2042_trail_deathless','b2042_plume_voidsworn','b2042_plume_hegemony','b2042_plume_corsair','b2042_plume_ithar','b2042_plume_chorus','b2042_plume_deathless','b2042_craft_hegemony','b2042_craft_ithar','b2042_craft_chorus'); $runs=Get-ChildItem -LiteralPath (Join-Path $env:LB_HOME 'runs') -Directory; if($runs.Count -lt 2){ throw ('Expected 2 run folders (before/after), found ' + $runs.Count) }; foreach($d in $runs){ $bj=Join-Path $d.FullName 'bench.json'; if(-not (Test-Path -LiteralPath $bj)){ throw ('Missing ' + $bj) }; $rep=Get-Content -LiteralPath $bj -Raw | ConvertFrom-Json; $got=@{}; foreach($s in $rep.stills){ if($s.part -eq 'moments'){ $got[($s.id + ':' + $s.cam)]=$true } }; foreach($id in $want){ foreach($cam in @(170,26)){ if(-not $got.ContainsKey($id + ':' + $cam)){ throw ('Run ' + $d.Name + ' missing still ' + $id + ' at cam ' + $cam) } } }; Write-Host ('VERIFIED ' + $d.Name + ': all 19 Build A rows at cams 170 and 26') }"
exit /b %ERRORLEVEL%
