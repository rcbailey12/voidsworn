@echo off
title GPU line: 1371 battle stills per faction on the live PT1120C build (Board, Nov 20)
rem Board, Nov 20 18:03 UTC: waits (60 s steps) for "OPUS1369 frontend exit" in opus1369c_wait.txt, then runs the live build\export\Voidsworn.console.exe
rem (25adec31, promoted 11:38) through build\tools\pc\tmo.bat with PC_GPU_ISSUE=1371, the same battle call g2_playtest_capture uses, once per faction:
rem ithar (Glasswrights), chorus, deathless (Eclipse); seed 4242, map belt, 1920x1080, --shots and --ui-shots into shots\pt1120c_faction_stills\<fac>\.
rem 300 s ceiling each (about 15 minutes at most). End line "OPUS1371 stills exit". Writes opus1371_wait.txt. Never deletes.
setlocal EnableDelayedExpansion
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1371_wait.txt"
set "OUT=%V%\shots\pt1120c_faction_stills"
set "X=%V%\build\export\Voidsworn.console.exe"
set "TMO=%V%\build\tools\pc\tmo.bat"
set "PC_GPU_ISSUE=1371"
set "PC_GPU_WAIT_SECONDS=3600"
set "VS_BOARD_LOOK="
echo waiting for OPUS1369 frontend exit in opus1369c_wait.txt %DATE% %TIME% > "%L%"
:wait
findstr /b /c:"OPUS1369 frontend exit" "%V%\opus1369c_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if exist "%OUT%" (echo FAIL: %OUT% exists >> "%L%" & echo OPUS1371 stills exit 1 at %TIME% >> "%L%" & exit /b 1)
mkdir "%OUT%"
set "RC=0"
for %%F in (ithar chorus deathless) do (
  mkdir "%OUT%\%%F"
  echo %%F start !TIME! >> "%L%"
  call "%TMO%" 300 "%X%" --resolution 1920x1080 -- --seed 4242 --fac %%F --map belt --shots "%OUT%\%%F" --ui-shots "%OUT%\%%F" --window 1920x1080 --quit-after 260 > "%OUT%\%%F_log.txt" 2>&1
  set "E=!ERRORLEVEL!"
  echo %%F exit !E! at !TIME! >> "%L%"
  if not "!E!"=="0" set "RC=1"
)
echo OPUS1371 stills exit !RC! at %TIME% >> "%L%"
exit /b 0