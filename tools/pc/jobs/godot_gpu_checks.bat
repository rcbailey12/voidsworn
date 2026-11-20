@echo off
rem Issue 359: the Godot checks that need a window, the GPU or the built ship files, on Ryan's PC. Double-click, or call it
rem from the root of a clone (made with core.autocrlf=false). It runs every "gpu" line of godot\tools\ci\godot_checks.txt
rem (GitHub runs the "headless" lines), one after another, each under tools\pc\tmo.bat with a 15 minute limit.
rem   tools\pc\jobs\godot_gpu_checks.bat [path to the Godot console exe]
rem Ship files: the probes that draw real ships need godot\gen in this clone (the copy-and-verify step). Without it they stop
rem at once on a placeholder hull (render\placeholder_guard.gd) and the results file says STOPPED for them.
rem Output: ..\shots\gpu_checks\<check>\ (its pictures and log.txt) and ONE results file, ..\shots\gpu_checks\results.txt:
rem one line per check (PASS, FAIL with the exit code, or STOPPED), then the totals.
rem Unrun when written (issue 359 was built in the cloud): the first PC run is its test.
rem Issue 1194: each check runs through tools\pc\job_wrap.bat (the installed main watchdog, a GPU label on every claim).
rem Godot is checked first; a failed or STOPPED check marks the run failed and the others still run. ..\shots\gpu_checks\
rem done.txt says PASS or FAILED: <checks>, and the exit code is 0 only when every check passed.
setlocal EnableDelayedExpansion
set "ROOT=%~dp0..\..\"
pushd "%ROOT%"
set "ROOT=%CD%\"
set "G=%~1"
if not defined G if exist "%ROOT%..\godot_path.txt" set /p G=<"%ROOT%..\godot_path.txt"
if defined G set "GODOT_EXE=%G%"
set "OUT=%ROOT%..\shots\gpu_checks"
set "R=%OUT%\results.txt"
if not exist "%OUT%" mkdir "%OUT%"
if not defined PC_GPU_ISSUE set "PC_GPU_ISSUE=godot_gpu_checks"
set "JW=%ROOT%tools\pc\job_wrap.bat"
call "%JW%" init "%OUT%" "%PC_GPU_ISSUE%" "godot"
if errorlevel 1 (
  echo FAIL: Godot console exe not found, or the installed tools are missing. Pass its full path, or set GODOT_EXE.
  echo See %OUT%\status.txt and %OUT%\preflight.txt
  popd
  exit /b 1
)
set "G=%JW_GODOT%"
if not exist "%ROOT%.onboarding_checks" mkdir "%ROOT%.onboarding_checks"
echo GPU Godot checks (godot\tools\ci\godot_checks.txt, class gpu), %date% %time% > "%R%"
echo Clone: %ROOT% >> "%R%"
if exist "%ROOT%godot\gen" (echo Ship files: godot\gen is present >> "%R%") else (echo Ship files: godot\gen is MISSING, probes that draw real ships will stop >> "%R%")
for /f "usebackq eol=# tokens=1-4 delims=|" %%a in ("%ROOT%godot\tools\ci\godot_checks.txt") do (
  if "%%a"=="gpu" call :one "%%b" "%%c" "%%d"
)
set "NP=0"
set "NT=0"
for /f %%k in ('findstr /b /c:"PASS " "%R%" ^| find /c /v ""') do set "NP=%%k"
for /f %%k in ('findstr /b /c:"PASS " /c:"FAIL " /c:"STOPPED " "%R%" ^| find /c /v ""') do set "NT=%%k"
echo Totals: !NP! of !NT! GPU checks passed. >> "%R%"
type "%R%"
popd
call "%JW%" end
endlocal & exit /b %ERRORLEVEL%

rem ---- one check: %1 script (res path under godot\), %2 setup, %3 args after "--" ("-" for none)
:one
setlocal EnableDelayedExpansion
set "S=%~1"
set "SETUP=%~2"
set "ARGS=%~3"
for %%n in ("%S%") do set "NAME=%%~nn"
set "O=%OUT%\!NAME!"
if not exist "!O!" mkdir "!O!"
set "LAUNCH=--script res://!S!"
set "REN="
if not "!SETUP!"=="-" (
  for %%t in (!SETUP!) do (
    for /f "tokens=1* delims=:" %%x in ("%%t") do (
      if "%%x"=="env" set "%%y=!O!"
      if "%%x"=="envpng" set "%%y=!O!\shot.png"
      if "%%x"=="scene" set "LAUNCH=%%y"
      if "%%x"=="compat" set "REN=--rendering-method gl_compatibility"
    )
  )
)
set "A="
if not "!ARGS!"=="-" (
  set "A=!ARGS:{out}=%O%!"
  set "A=!A:{repo}=%ROOT:~0,-1%!"
)
echo --- !NAME! ---
set "JW_STEP=!NAME!"
set "JW_CONTINUE=1"
if defined A (
  call "%JW%" run 900 "%G%" --path "%ROOT%godot" --resolution 1920x1080 !REN! !LAUNCH! -- !A! > "!O!\log.txt" 2>&1
) else (
  call "%JW%" run 900 "%G%" --path "%ROOT%godot" --resolution 1920x1080 !REN! !LAUNCH! > "!O!\log.txt" 2>&1
)
set "CODE=!ERRORLEVEL!"
findstr /c:"placeholder hull" "!O!\log.txt" > nul && (
  echo STOPPED !NAME!: placeholder hull, the ship files are missing ^(!O!\log.txt^)>> "%R%"
  if "!CODE!"=="0" (set "JW_CONTINUE=1" & call "%JW%" fail "!NAME! placeholder hull")
  goto one_end
)
if "!CODE!"=="0" (
  echo PASS !NAME! ^(!O!^)>> "%R%"
) else if "!CODE!"=="124" (
  echo FAIL !NAME!: time limit, 15 minutes ^(!O!\log.txt^)>> "%R%"
) else (
  echo FAIL !NAME!: exit code !CODE! ^(!O!\log.txt^)>> "%R%"
)
:one_end
rem Carry the failed list out of this check's setlocal (issue 1194).
endlocal & set "JW_FAILED=%JW_FAILED%" & goto :eof
