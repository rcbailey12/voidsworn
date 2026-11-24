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
rem Pass both a real Windows path in LB_MOMENTS (#2007+ launcher checks `if not exist`) and legacy LB_ARGS (current main launcher).
set "LB_MOMENTS="
for %%I in ("%~dp0..\..\..\godot\bench\look_moments_2042.json") do if exist "%%~fI" set "LB_MOMENTS=%%~fI"
if not defined LB_MOMENTS if exist "%LB_HOME%\tool\godot\bench\look_moments_2042.json" set "LB_MOMENTS=%LB_HOME%\tool\godot\bench\look_moments_2042.json"
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
rem Verify only the exact AFTER and BEFORE receipts for this invocation (supports both main's runs\<sha> and #2007's runs\<sha>_<tool>_<rows8>).
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $want=@('b2042_rcs_voidsworn','b2042_rcs_hegemony','b2042_rcs_corsair','b2042_rcs_ithar','b2042_rcs_chorus','b2042_rcs_deathless','b2042_trail_hegemony','b2042_trail_corsair','b2042_trail_chorus','b2042_trail_deathless','b2042_plume_voidsworn','b2042_plume_hegemony','b2042_plume_corsair','b2042_plume_ithar','b2042_plume_chorus','b2042_plume_deathless','b2042_craft_hegemony','b2042_craft_ithar','b2042_craft_chorus'); $repo=Join-Path $env:LB_HOME 'repo'; $tool=Join-Path $env:LB_HOME 'tool'; $runsRoot=Join-Path $env:LB_HOME 'runs'; $toolSha=if(Test-Path -LiteralPath (Join-Path $tool '.git')){ (& git -C $tool rev-parse --short=8 HEAD).Trim() } else { '' }; $rowsFile=if($env:LB_MOMENTS -and (Test-Path -LiteralPath $env:LB_MOMENTS)){ $env:LB_MOMENTS } else { Join-Path $tool 'godot\bench\look_moments_2042.json' }; $rowsKey=if(Test-Path -LiteralPath $rowsFile){ (Get-FileHash -Algorithm SHA256 -LiteralPath $rowsFile).Hash.ToLower().Substring(0,8) } else { '' }; $refs=@($env:AFTER); if($env:BEFORE -and $env:BEFORE -ne 'none'){ $refs+=@($env:BEFORE) }; foreach($ref in $refs){ $sha=(& git -C $repo rev-parse --short=8 $ref).Trim(); if(-not $sha){ throw ('Cannot resolve ref ' + $ref) }; $cands=@(); if($toolSha -and $rowsKey){ $cands+=@(Join-Path $runsRoot ($sha + '_' + $toolSha + '_' + $rowsKey)) }; $cands+=@(Join-Path $runsRoot $sha); $runDir=$null; foreach($c in $cands){ if(Test-Path -LiteralPath (Join-Path $c 'bench.json')){ $runDir=$c; break } }; if(-not $runDir){ throw ('Missing bench.json for ' + $ref + ' (checked: ' + ($cands -join ', ') + ')') }; $bj=Join-Path $runDir 'bench.json'; $rep=Get-Content -LiteralPath $bj -Raw | ConvertFrom-Json; if(-not ($rep.commit -and $rep.commit.StartsWith($sha))){ throw ('Commit mismatch in ' + $bj + ': got ' + $rep.commit + ', expected ' + $sha) }; $got=@{}; foreach($s in $rep.stills){ if($s.part -eq 'moments'){ $got[($s.id + ':' + $s.cam)]=$true } }; foreach($id in $want){ foreach($cam in @(170,26)){ if(-not $got.ContainsKey($id + ':' + $cam)){ throw ('Run ' + (Split-Path -Leaf $runDir) + ' (' + $ref + ') missing still ' + $id + ' at cam ' + $cam) } } }; Write-Host ('VERIFIED ' + (Split-Path -Leaf $runDir) + ' (' + $ref + '): all 19 Build A rows at cams 170 and 26') }"
exit /b %ERRORLEVEL%
