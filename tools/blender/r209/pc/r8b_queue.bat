@echo off
rem Opus #209 round 8: bring Opus's PC clone to the round 8 branch, then start r8b_run.bat in its own window and return, so the
rem queue stays free. Drop this file into Downloads\voidsworn_test\queue\ to start it. It deletes nothing.
set O=%USERPROFILE%\Downloads\voidsworn_test\opus209
cd /d "%O%\repo"
git -c core.autocrlf=false fetch origin opus/issue-209-r8
git -c core.autocrlf=false checkout -f FETCH_HEAD
git log -1 --oneline
start "opus209 r8b" cmd /c "%O%\repo\tools\blender\r209\pc\r8b_run.bat"
echo launched 209 r8b
