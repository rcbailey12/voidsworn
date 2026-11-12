@echo off
rem Opus #209: the six B2 sections, one fresh TRELLIS process each (a long process ran out of memory and failed them all).
set V=%USERPROFILE%\Downloads\voidsworn_test
set G=%V%\opus209\gen
:wait
if exist "%G%\trellis_done3.txt" goto go
timeout /t 20 /nobreak >nul
goto wait
:go
for %%S in (0 1 2 3 4 5) do call :one %%S
echo done > "%G%\trellis_done4.txt"
goto :eof
:one
set T209_DONE=trellis_b2_%1.txt
"%USERPROFILE%\Downloads\trellis2\code\venv\Scripts\python.exe" "%G%\trellis209.py" "%G%" b2_s%1=q/b2_s%1_s1_00001_.png >> "%G%\trellis_out4.log" 2>&1
if not exist "%G%\3d\b2_s%1.glb" "%USERPROFILE%\Downloads\trellis2\code\venv\Scripts\python.exe" "%G%\trellis209.py" "%G%" b2_s%1=q/b2_s%1_s1_00001_.png >> "%G%\trellis_out4.log" 2>&1
goto :eof
