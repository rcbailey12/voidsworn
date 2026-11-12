@echo off
rem Opus #209 round 7, step 5 repair: bring Opus's PC clone to the round 7 branch, then start r7b_run.bat in its own window.
rem Drop this file into Downloads\voidsworn_test\queue\ to start it. It deletes nothing.
set O=%USERPROFILE%\Downloads\voidsworn_test\opus209
cd /d "%O%\repo"
git -c core.autocrlf=false fetch origin opus/issue-209-r7
git -c core.autocrlf=false checkout -f FETCH_HEAD
git log -1 --oneline
start "opus209 r7b" cmd /c "%O%\repo\tools\blender\r209\pc\r7b_run.bat"
echo launched 209 r7b
