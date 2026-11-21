@echo off
rem Run one Codex task on Ryan's PC (Ryan OK, Nov 1 2026: "use that flow, especially for easy to delegate coding tasks").
rem Usage (from a lane B job): call codex_run.bat <tag>
rem The brief is copied in as CODEX_TASK.md (stdin does not pass through tmo.bat), and removed before the diff.
rem Expects, staged by Opus beside this file's folder in build_b:
rem   cx_<tag>_src.zip   the repo files the task needs (git archive)
rem   cx_<tag>_brief.md  the task brief (what to change, which files, how to check)
rem Produces in build_b: cx_<tag>.patch (git diff of Codex's changes), cx_<tag>_last.md (its final message), cx_<tag>_log.txt
setlocal
rem Reasoning effort (Ryan, Nov 2): high by default; jobs for planning, long analysis or audits set CX_EFFORT=xhigh before the call.
if not defined CX_EFFORT set "CX_EFFORT=high"
set "TAG=%~1"
if "%TAG%"=="" (echo usage: codex_run.bat ^<tag^> & exit /b 2)
set "PATH=C:\Program Files\nodejs;C:\Program Files\Git\cmd;%APPDATA%\npm;%PATH%"
set "B=%USERPROFILE%\Downloads\voidsworn_test\build_b"
set "W=%B%\cx_%TAG%"
if exist "%W%" (echo work folder %W% already exists, use a new tag & exit /b 3)
mkdir "%W%"
powershell -NoProfile -Command "Expand-Archive -LiteralPath '%B%\cx_%TAG%_src.zip' -DestinationPath '%W%'" || exit /b 4
pushd "%W%"
git init -q && git config core.autocrlf false && git add -A && git -c user.name=codex -c user.email=codex@local commit -q -m base
copy /y "%B%\cx_%TAG%_brief.md" "%W%\CODEX_TASK.md" >nul
rem Codex works only inside this folder; 60 minutes at most (xhigh jobs run long) (tmo.bat)
call "%B%\tools\pc\tmo.bat" 3600 "%APPDATA%\npm\codex.cmd" exec -c model_reasoning_effort=%CX_EFFORT% --approve-for-me --ephemeral --color never --skip-git-repo-check -C "%W%" -o "%B%\cx_%TAG%_last.md" "Read CODEX_TASK.md in this folder and do exactly what it says. Work only inside this folder. Do not commit." > "%B%\cx_%TAG%_log.txt" 2>&1
set "RC=%ERRORLEVEL%"
del /q CODEX_TASK.md 2>nul
git add -A
git diff --cached --binary > "%B%\cx_%TAG%.patch"
popd
echo codex exit %RC%, patch: %B%\cx_%TAG%.patch
exit /b %RC%
