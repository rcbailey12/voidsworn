@echo off
rem Opus #209: TRELLIS.2 on the chosen section and part images (GPU). Restarts the process after a crash (up to 8 times);
rem a part that crashes twice is given up and the assembly falls back to hand-built for it.
set V=%USERPROFILE%\Downloads\voidsworn_test
set G=%V%\opus209\gen
set /a N=0
:again
set /a N+=1
echo pass %N% %date% %time% >> "%G%\trellis_passes.txt"
"%USERPROFILE%\Downloads\trellis2\code\venv\Scripts\python.exe" "%G%\trellis209.py" "%G%" p_drumrack=q/p_drumrack_s0_00001_.png p_bowguns=q/p_bowguns_s0_00001_.png b1_s0=q/b1_s0_s0_00001_.png b1_s1=q/b1_s1_s1_00001_.png b1_s2=q/b1_s2_s1_00001_.png p_cargo=q/p_cargo_s0_00001_.png p_sternblock=q/p_sternblock_s0_00001_.png b2_s0=q/b2_s0_s1_00001_.png b2_s1=q/b2_s1_s1_00001_.png b2_s2=q/b2_s2_s1_00001_.png b2_s3=q/b2_s3_s1_00001_.png b2_s4=q/b2_s4_s1_00001_.png b2_s5=q/b2_s5_s1_00001_.png >> "%G%\trellis_out.log" 2>&1
echo exit %errorlevel% >> "%G%\trellis_passes.txt"
if exist "%G%\trellis_done.txt" goto end
if %N% LSS 8 goto again
:end
echo done > "%G%\trellis_done2.txt"
