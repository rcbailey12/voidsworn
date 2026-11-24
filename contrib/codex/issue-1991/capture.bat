@echo off
setlocal
rem Queue this from the reviewed branch checkout after All checks is green.
rem Optional first argument: the exact reviewed after commit.
rem The before pin is the main revision merged for run 2, with the same thrust profiles as the branch.
set "LB_BEFORE=3d7ecab76a2fe72df169ac1198602431f54d599c"
set "LB_AFTER=%~1"
if not defined LB_AFTER set "LB_AFTER=origin/codex/issue-1991"
set "LB_ROOT=%USERPROFILE%\Downloads\voidsworn_test\board\issue-1991"
set "LB_HOME=%LB_ROOT%\look_bench"
set "LB_SHEETS=%LB_ROOT%\shots"
set "LB_MOMENTS=%~dp0look_moments.json"
set "LB_LAUNCHER=%~dp0..\..\..\tools\pc\jobs\look_bench.bat"
set "LB_TOOL_REF=%LB_AFTER%"
set "LB_PRE_RUN="
set "LB_RUN_NAME="
set "LB_QUIET=1"
set "PC_GPU_ISSUE=1991"
if not exist "%LB_LAUNCHER%" (
  echo FAILED: run capture.bat from contrib\codex\issue-1991 in the reviewed checkout.
  exit /b 2
)
if not exist "%LB_MOMENTS%" exit /b 2
if /i "%LB_AFTER%"=="check" goto check
call "%LB_LAUNCHER%" "%LB_AFTER%" "%LB_BEFORE%"
exit /b %ERRORLEVEL%

:check
rem Exercise the launcher paths and rows on Windows without queueing a GPU run.
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $rows=Get-Content -Raw -LiteralPath $env:LB_MOMENTS | ConvertFrom-Json; if (($rows.cameras -join ',') -ne '170,26' -or $rows.rows.Count -lt 1) { throw 'Issue 1991 needs both cameras and at least one row' }; & git -C (Split-Path -Parent $env:LB_MOMENTS) cat-file -e ($env:LB_BEFORE + '^{commit}'); if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; Write-Output ('Issue 1991 launcher paths and cameras verified for ' + $rows.rows.Count + ' rows')"
exit /b %ERRORLEVEL%
