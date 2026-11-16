@echo off
rem Issue 362 job F (Ryan, Nov 12 11:40 CST: Eclipse a bit darker, Hullbreakers stay 1.25). Eclipse only:
rem   1. the band at camera 170 on the darkest sky (world) and the storm, once: the branch as it is (Eclipse 3.2) and lift
rem      2.6, 2.2, 1.8, and 2.2 with the Eclipse material rim down a third (0.4 to 0.27) (variants_f.json)
rem   2. pictures Ryan can judge: the Eclipse ships at camera 60 (the bench's middle camera, real game pixels, no scaling),
rem      darkest sky, 1440x840 crops: main (before) twice, keep the second, then the branch with the same five settings.
rem The camera 60 runs need the probe's --cam, --cell and --factions options (in the branch's probe and run362.bat): this
rem job copies the branch's run362.bat beside the old one as run362f.bat (a new file; the old one stays as it is).
rem Then zips. Writes only under opus362\. Never deletes anything.
setlocal
set "D=%USERPROFILE%\Downloads\voidsworn_test\opus362"
set "PX="
call "%D%\run362.bat" probe origin/opus/issue-362 f variants_f.json world+storm
copy /y "%D%\repo\contrib\opus\reviews\readability_362\pc\run362.bat" "%D%\run362f.bat" > nul
if not exist "%D%\run362f.bat" (
  echo job f: no run362f.bat >> "%D%\status.txt"
  exit /b 1
)
set "PX=--cam 60 --cell 1440x840 --factions deathless"
call "%D%\run362f.bat" probe b7cacdc4 f60before none world
call "%D%\run362f.bat" probe origin/opus/issue-362 f60 variants_f.json world
set "PX="
call "%D%\zip362.bat" probe_f_1
call "%D%\zip362.bat" probe_f60before_2
call "%D%\zip362.bat" probe_f60_1
echo %date% %time% job f done >> "%D%\status.txt"
exit /b 0
