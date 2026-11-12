@echo off
rem Workhorse trial (#217, Opus, Nov 7 2026): the same job, issue 26 (Heat dial after the first loss), run twice back to back,
rem first by DeepSeek V4.1 Flash, then by Kimi K3.1 Pro, both inside OpenCode. Each pushes work/issue-26-<arm>; GitHub opens
rem the two PRs. Opus reviews both, merges the better one and writes the results note.
rem Double-click it (from Downloads\voidsworn_test as WORKHORSE_TRIAL.bat, or from tools\pc). Leave the window open.
rem Usage: work_trial.bat [dryrun] [nopause]   dryrun: free stand-in model, nothing pushed (Opus's test of the runner).
setlocal
title Workhorse trial: DeepSeek arm, then Kimi arm, on issue 26
set "T=%~dp0"
if not exist "%T%work_issue.bat" set "T=%~dp0work217\tools\"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "W=%VT%\work217"
set "MODE=%~1"
if /i "%MODE%"=="nopause" set "MODE="
set "S=%W%\trial_summary.txt"
if /i "%MODE%"=="dryrun" set "S=%W%\dryrun_summary.txt"
echo.
echo  Workhorse trial: two AI coding runs on issue 26, DeepSeek first, then Kimi.
echo  Each run is capped at one hour. You can use the PC meanwhile; if you open the game, a run waits until you close it.
echo  Leave this window open. It says DONE at the end, and Opus takes it from there.
echo.
echo Workhorse trial %MODE% started %date% %time% > "%S%"
for %%A in (deepseek kimi) do call :arm %%A
echo. >> "%S%"
echo finished %date% %time% >> "%S%"
echo.
type "%S%"
echo.
echo  DONE. Opus reviews both pull requests from here.
if /i not "%~1"=="nopause" if /i not "%~2"=="nopause" pause
exit /b 0

:arm
echo [%time%] %1 arm running ...
call "%T%work_issue.bat" 26 %1 %MODE%
echo [%time%] %1 arm finished (exit %ERRORLEVEL%)
set "K=issue-26-%1"
if /i "%MODE%"=="dryrun" set "K=dryrun-26-%1"
set "L="
set /p L=<"%W%\%K%\latest.txt"
echo. >> "%S%"
echo ===== %1 arm: %L% >> "%S%"
type "%L%\out\result.txt" >> "%S%" 2>nul
type "%L%\out\stats.txt" >> "%S%" 2>nul
exit /b 0
