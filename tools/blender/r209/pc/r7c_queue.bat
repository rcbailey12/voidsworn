@echo off
rem Opus #209 round 7: the far side stills (R160). Brings Opus's PC clone to the round 7 branch and starts r7c_run.bat.
rem Drop this file into Downloads\voidsworn_test\queue\ to start it. It deletes nothing.
set O=%USERPROFILE%\Downloads\voidsworn_test\opus209
cd /d "%O%\repo"
git -c core.autocrlf=false fetch origin opus/issue-209-r7
git -c core.autocrlf=false checkout -f FETCH_HEAD
git log -1 --oneline
start "opus209 r7c" cmd /c "%O%\repo\tools\blender\r209\pc\r7c_run.bat"
echo launched 209 r7c
