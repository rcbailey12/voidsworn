@echo off
rem Opus #209 round 7: bring Opus's PC clone to the round 7 branch, then start the run in its own window and return, so the
rem queue stays free. The run does nothing on the GPU until Downloads\voidsworn_test\opus209\go7.txt exists (r7_run.bat).
rem Drop this file into Downloads\voidsworn_test\queue\ to start it.
set O=%USERPROFILE%\Downloads\voidsworn_test\opus209
cd /d "%O%\repo"
git -c core.autocrlf=false fetch origin opus/issue-209-r7
git -c core.autocrlf=false checkout -f FETCH_HEAD
git log -1 --oneline
start "opus209 r7" cmd /c "%O%\repo\tools\blender\r209\pc\r7_run.bat"
echo launched 209 r7 (it waits for opus209\go7.txt)
