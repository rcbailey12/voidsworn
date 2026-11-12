@echo off
rem Issue 209 round 7: starboard stills of Ab6 (out6f) and Ab7 (out7), paint and clay, studio rig, so the paint is judged on the
rem far side too (FINDINGS R160). Reads the two blends, writes Downloads\voidsworn_test\opus209\out7c\r only. Deletes nothing.
set V=%USERPROFILE%\Downloads\voidsworn_test
set O=%V%\opus209
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set R=%O%\repo\tools\blender\r209
set OUT=%O%\out7c
for %%D in ("%OUT%" "%OUT%\r") do if not exist %%D mkdir %%D
cd /d "%O%\repo"
git log -1 --oneline > "%OUT%\git.txt" 2>&1
echo start %date% %time% > "%OUT%\time.txt"
set /a W=0
:gpuwait
set U=0
for /f %%U in ('nvidia-smi --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits 2^>nul') do set U=%%U
if %U% LSS 15 goto gpufree
set /a W+=1
if %W% GEQ 90 goto gpufree
timeout /t 60 /nobreak > nul
goto gpuwait
:gpufree
echo gpu free after %W% min %date% %time% >> "%OUT%\time.txt"
"%B%" -b "%O%\out7\Ab7.blend" -P "%R%\render.py" -- "%OUT%\r" Ab7 --views=side_s,hero_s > "%OUT%\logr_Ab7.txt" 2>&1
"%B%" -b "%O%\out6f\Ab6.blend" -P "%R%\render.py" -- "%OUT%\r" Ab6 --views=side_s,hero_s > "%OUT%\logr_Ab6.txt" 2>&1
findstr /L /c:"[209]" /c:"Error" "%OUT%\logr_Ab7.txt" "%OUT%\logr_Ab6.txt" >> "%OUT%\time.txt"
echo done %date% %time% >> "%OUT%\time.txt"
echo done > "%OUT%\done7c.txt"
