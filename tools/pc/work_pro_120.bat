@echo off
rem Workhorse head-to-head, third contender (board, Nov 8 2026, R129): DeepSeek V4 Pro on issue 120, 90 minutes, same runner.
rem Copy in Downloads\voidsworn_test as WORKHORSE_H2H_120_PRO.bat. First finds the V4 Pro model id this OpenCode knows (a
rem one-word check per candidate, a fraction of a cent), then runs the job. Pushes work/issue-120-deepseekpro. Nothing is deleted.
setlocal
title Workhorse: issue 120, DeepSeek V4 Pro
set "T=%~dp0work217\tools\"
if not exist "%T%work_issue.bat" set "T=%~dp0"
set "W=%USERPROFILE%\Downloads\voidsworn_test\work217"
set "PATH=%USERPROFILE%\Downloads\voidsworn_test\node;C:\Program Files\nodejs;C:\Program Files\Git\cmd;%APPDATA%\npm;%PATH%"
set "OC=%APPDATA%\npm\opencode.cmd"
set "SHELL=C:\Program Files\Git\bin\bash.exe"
set "OPENCODE_GIT_BASH_PATH=C:\Program Files\Git\bin\bash.exe"
set "OPENCODE_DISABLE_AUTOUPDATE=1"
set "OPENCODE_DISABLE_MODELS_FETCH=1"
set "OPENCODE_CONFIG=%T%work\opencode.json"
set "S=%W%\h2h_120_pro_summary.txt"
echo DeepSeek V4 Pro on 120 started %date% %time% > "%S%"
set "WORK_MODEL="
for %%M in (deepseek/deepseek-pro deepseek/deepseek-v4-pro deepseek/deepseek-v4-pro-0423) do if not defined WORK_MODEL call :probe %%M
if not defined WORK_MODEL (echo no V4 Pro model id answered; see %W%\pro_probe_*.jsonl >> "%S%" & type "%S%" & pause & exit /b 1)
echo model id: %WORK_MODEL% >> "%S%"
set "WORK_CAP=5400"
call "%T%work_issue.bat" 120 deepseekpro
set "L="
set /p L=<"%W%\issue-120-deepseekpro\latest.txt"
echo ===== deepseekpro arm: %L% >> "%S%"
type "%L%\out\result.txt" >> "%S%" 2>nul
type "%L%\out\stats.txt" >> "%S%" 2>nul
echo finished %date% %time% >> "%S%"
type "%S%"
echo.
echo  DONE. Opus reviews the pull request from here. This window can be closed.
pause
exit /b 0
:probe
set "N=%~1"
set "N=%N:/=_%"
call "%T%tmo.bat" 120 "%OC%" run --format json -m %~1 --dir "%W%" "Reply with the single word READY and nothing else." > "%W%\pro_probe_%N%.jsonl" 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%T%work_issue.ps1" lasttext "%W%\pro_probe_%N%.jsonl" > "%W%\pro_probe_%N%.txt" 2>nul
findstr /i /c:"READY" "%W%\pro_probe_%N%.txt" > nul && set "WORK_MODEL=%~1"
echo probe %~1: %WORK_MODEL% >> "%S%"
exit /b 0
