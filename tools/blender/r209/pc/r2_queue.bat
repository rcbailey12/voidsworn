@echo off
rem Opus #209 round 2: bring Opus's PC clone to the round 2 branch, then start the run in its own window and return.
set O=%USERPROFILE%\Downloads\voidsworn_test\opus209
cd /d "%O%\repo"
git -c core.autocrlf=false fetch origin opus/issue-209-r2
git -c core.autocrlf=false checkout -f FETCH_HEAD
git log -1 --oneline
start "opus209 r2" cmd /c "%O%\repo\tools\blender\r209\pc\r2_run.bat"
echo launched 209 r2
