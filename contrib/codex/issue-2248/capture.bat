@echo off
setlocal
rem Run from a GPU lane after green All checks and review of the exact after commit.
rem Optional first argument: the reviewed commit. Double-click pins the reviewed checkout's HEAD.
rem Compare against the merged cap tint fix, not the base from the first run.
set "LB_BEFORE=4a6c1c18b2b1a84991ac48bf9cceb97220179faa"
set "LB_AFTER=%~1"
set "LB_CHECK="
if /i "%LB_AFTER%"=="check" (
  set "LB_CHECK=1"
  set "LB_AFTER="
)
set "LB_ROOT=%USERPROFILE%\Downloads\voidsworn_test\board\issue-2248"
set "LB_HOME=%LB_ROOT%\look_bench"
set "LB_SHEETS=%LB_ROOT%\shots"
set "LB_MOMENTS=%~dp0look_moments.json"
set "LB_LAUNCHER=%~dp0..\..\..\tools\pc\jobs\look_bench.bat"
set "LB_PRE_RUN="
set "LB_RUN_NAME="
set "PC_GPU_ISSUE=2248"
if not exist "%LB_LAUNCHER%" (
  echo FAILED: look bench launcher not found.
  exit /b 2
)
if not exist "%LB_MOMENTS%" (
  echo FAILED: issue 2248 rows not found.
  exit /b 2
)
if not defined LB_AFTER for /f %%H in ('git -C "%~dp0." rev-parse --verify HEAD') do set "LB_AFTER=%%H"
if not defined LB_AFTER (
  echo FAILED: could not pin the reviewed checkout.
  exit /b 2
)
set "LB_TOOL_REF=%LB_AFTER%"
if defined LB_CHECK goto check
set "GPU_GO="
set /p GPU_GO=<"%USERPROFILE%\Downloads\voidsworn_test\gpu_go.txt"
if not "%GPU_GO%"=="GPU cleared" (
  echo HELD: gpu_go.txt does not say GPU cleared.
  exit /b 2
)
call "%LB_LAUNCHER%" "%LB_AFTER%" "%LB_BEFORE%"
exit /b %ERRORLEVEL%

:check
rem Check rows and baseline on Windows without starting the bench or claiming the GPU.
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $rows=Get-Content -Raw -LiteralPath $env:LB_MOMENTS | ConvertFrom-Json; if (($rows.cameras -join ',') -ne '170,26' -or ($rows.rows.expect_code -join ',') -ne 'D22_23,C19_51') { throw 'Wrong cameras or hull codes' }; & git -C (Split-Path -Parent $env:LB_MOMENTS) cat-file -e ($env:LB_BEFORE + '^{commit}'); if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; Write-Output 'Issue 2248 capture paths, baseline, hull codes and cameras verified'"
exit /b %ERRORLEVEL%
