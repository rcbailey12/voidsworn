@echo off
rem Issue 209 round 8: re-check round 8's baked Ab8 export (out8b) with the tightened stage 7 check (Muse check of PR 341:
rem the breach contract, the length-scaled off-mesh limit, extras.socket) and its nine-case self-test. No Blender, no GPU, no
rem re-export: it copies out8b\export\C15s_23 to out8b\recheck341\C15s_23 (copy only) and checks the copy, so the round 8
rem files are not touched. Drop this file into Downloads\voidsworn_test\queue\ to start it. It deletes nothing.
set V=%USERPROFILE%\Downloads\voidsworn_test
set O=%V%\opus209
set BPY=%V%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe
cd /d "%O%\repo"
git -c core.autocrlf=false fetch origin opus/issue-209-r8
git -c core.autocrlf=false checkout -f FETCH_HEAD
git log -1 --oneline
set RC=%O%\repo\tools\recipe
set SHIPJ=%RC%\ships\C15s_23.json
set SRC=%O%\out8b\export\C15s_23
set EX=%O%\out8b\recheck341\C15s_23
if not exist "%EX%" mkdir "%EX%"
robocopy "%SRC%" "%EX%" /XD _selftest _gltf_source /NP /NDL /R:1 /W:1 > "%O%\out8b\recheck341\log_copy.txt" 2>&1
"%BPY%" "%RC%\check_export.py" "%SHIPJ%" "%EX%" > "%O%\out8b\recheck341\log_export_check.txt" 2>&1
echo export check exit %errorlevel% > "%O%\out8b\recheck341\result.txt"
"%BPY%" "%RC%\check_export_selftest.py" "%SHIPJ%" "%EX%" > "%O%\out8b\recheck341\log_export_selftest.txt" 2>&1
echo export self-test exit %errorlevel% >> "%O%\out8b\recheck341\result.txt"
type "%O%\out8b\recheck341\result.txt"
