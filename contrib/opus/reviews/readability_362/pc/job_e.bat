@echo off
rem Issue 362 job E (Ryan's ruling of Nov 12, R227: Eclipse lift 3.2, Hullbreakers 1.25). The branch head on the darkest
rem sky (world), the brightest (frontier) and the storm: the probe twice, keep the second (probe_e_2). Then one run of two
rem nearby numbers on the darkest sky and the storm (variants_e.json: Eclipse 3.0 and 3.5, Hullbreakers 1.2 and 1.3), so a
rem fallback is measured if 3.2 or 1.25 falls out of the band. Then zips of the new probe, the bracket run and main's
rem probe (probe_before_2, the left half of the phone sheet). Writes only under opus362\. Never deletes anything.
setlocal
set "D=%USERPROFILE%\Downloads\voidsworn_test\opus362"
call "%D%\run362.bat" probe origin/opus/issue-362 e
call "%D%\run362.bat" probe origin/opus/issue-362 ealt variants_e.json world+storm
call "%D%\zip362.bat" probe_e_2
call "%D%\zip362.bat" probe_ealt_1
call "%D%\zip362.bat" probe_before_2
echo %date% %time% job e done >> "%D%\status.txt"
exit /b 0
