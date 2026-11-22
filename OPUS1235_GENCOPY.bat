@echo off
rem Issue 1235 wounds (R402 redo): copy the built hulls of the six newest faction ships out of the job checkout so the
rem cloud thread can render them with the wound shaders. No Godot run. Copies gen\manifest.json, gen\ships\<code>.* for
rem V16_37 H10_23 C15s_23 B21_11 I15_11 D21_23, and a size listing of the whole gen folder. Built from opus_job_template.bat.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1235gx"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1235"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=2fc0613662d16db9eafaecf1944188ec0ad04350"
set "PIN_OLD="

rem The head is the installed main copy in tools_live (fail closed). OPUS_JOB_HEAD may name another copy only for a
rem pre-merge smoke, together with OPUS_JOB_HEAD_PREMERGE=1; the head logs that.
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "HEAD="
if defined OPUS_JOB_HEAD if not "%OPUS_JOB_HEAD_PREMERGE%"=="1" (echo FAILED: OPUS_JOB_HEAD is only for a pre-merge smoke & exit /b 2)
if "%OPUS_JOB_HEAD_PREMERGE%"=="1" set "HEAD=%OPUS_JOB_HEAD%"
set "TLV="
if not defined HEAD if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined HEAD if defined TLV set "HEAD=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.bat"
if not defined HEAD (echo FAILED: no tools_live\current.txt & exit /b 2)
if not exist "%HEAD%" (echo FAILED: no head at %HEAD% & exit /b 2)
call "%HEAD%" init "%JOB%" "%LABEL%" "%TOOLS%"
if errorlevel 1 exit /b %ERRORLEVEL%

call :one new %PIN_NEW%
if defined PIN_OLD call :one old %PIN_OLD%
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one pinned commit: checkout, ships, import, then the job's own steps. Every Godot start goes through job_wrap.
:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
rem ---- STEPS: copy the six hulls and the manifest (no Godot)
set "G=%OJ_REPO%\godot\gen"
if not exist "%G%\manifest.json" (call "%JW%" fail "%1 no gen manifest" & exit /b 1)
if not exist "%O%\gen\ships" mkdir "%O%\gen\ships"
copy /y "%G%\manifest.json" "%O%\gen\manifest.json" > nul
for %%C in (V16_37 H10_23 C15s_23 B21_11 I15_11 D21_23) do copy /y "%G%\ships\%%C.*" "%O%\gen\ships\" > nul
dir /s /-c "%G%" > "%O%\gen_listing.txt" 2>&1
dir /-c "%O%\gen\ships" > "%O%\copied.txt" 2>&1
findstr /c:"I15_11" "%O%\copied.txt" > nul || call "%JW%" fail "%1 I15_11 hull not copied (see copied.txt)"
exit /b 0
