@echo off
rem Issue 1539, pre-merge proof for PR 1540 (Board and Ryan's outside review, Nov 21): one real PC ship job's in-game
rem shots must get through tools/recipe/offer_sheet.py, and a real source edit must still be refused.
rem Built from tools/pc/jobs/opus_job_template.bat on opus_job_head.bat. Queue it as a pre-merge smoke:
rem   OPUS_JOB_HEAD=<a copy of PR 1540's tools\pc\jobs>\opus_job_head.bat, OPUS_JOB_HEAD_PREMERGE=1 (the head logs it),
rem or after the merge plainly. What it does:
rem   1. a fresh checkout of PR 1540 at PIN_1540 (the head copy): its ship_job.bat, picture_provenance.py, offer_sheet.py.
rem   2. guard: recipe\chorus_C14 must still hold C14H's build (its export glb equals opus1291c14h\out's), so the rebuild
rem      below repeats C14H and never overwrites newer C14 work. Otherwise it stops before touching anything.
rem   3. the ship job from that copy, in its own new folder opus1539c14h: chorus_C14 / B22_11 at board/pin-1291-holes4
rem      (d2a9acd2, the C14H pin), stages 5_paint_bake 6_lod 7_export (C14H's bake, LOD and install again, in the clone),
rem      checks, then the in-game shots, stamped by PR 1540's picture_provenance.py (PICTURE_STAMP_TOOL).
rem      Stage 5 to 7 rewrite recipe\chorus_C14 from the same pin and blend: the same build C14H made.
rem   4. offer_sheet.py from the copy on the fresh job: must write the sheet (PASS).
rem   5. a real source edit: one line appended to the clone's godot\fx\fx.gd, a copy of a fresh shot stamped from that
rem      tree, offer_sheet must refuse it naming "dirty" and godot/fx/fx.gd. The line is then removed (git checkout).
rem   6. a live watchdog that differs from the pin's: a line appended to the clone's tools\pc\tmo.bat and its git hash
rem      recorded as the hand-off, a shot stamped from that tree must PASS; the same shot against the job's real hand-off
rem      record must be refused naming tools/pc/tmo.bat. tmo.bat is then put back byte for byte.
rem   result.txt in the attempt's proof folder says PASS or FAILED for each step. Nothing outside opus1539proof and
rem   opus1539c14h is written, except recipe\chorus_C14 by stages 5 to 7 (step 3). Nothing is deleted.
rem Once queued, never edited; a change ships under a new name (next: OPUS1539_PROOF_B.bat).
setlocal EnableExtensions
set "JOB=opus1539proof"
set "LABEL=1539"
set "TOOLS=godot blender pil"
set "PIN_1540=a006817a8f778e9cd793f9818fc6247cc8691544"
set "SHIP_PIN=d2a9acd26c3305641229d000d8890ba8a753dcfb"
if not defined PIL_PYTHON set "PIL_PYTHON=%USERPROFILE%\AppData\Local\Programs\Python\Python312\python.exe"

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

call "%HEAD%" checkout tools %PIN_1540%
set "T=%OJ_REPO%"
set "O=%OJ_OUT%\proof"
if not exist "%O%" mkdir "%O%"
set "R=%O%\result.txt"
> "%R%" echo issue 1539 proof, PR 1540 at %PIN_1540%, attempt %OJ_OUT%
if defined JW_STOP goto done
set "PY=%JW_PIL%"
if not defined PY set "PY=%PIL_PYTHON%"
set "OS=%T%\tools\recipe\offer_sheet.py"
set "PP=%T%\tools\picture_provenance.py"
if not exist "%OS%" (call "%JW%" fail "no offer_sheet.py in the PR 1540 copy" & goto done)

rem 2. the recipe folder must still hold C14H's build
set "SJ=%VT%\opus1539c14h"
if exist "%SJ%" (call "%JW%" fail "%SJ% already exists; this proof never reuses a job folder" & goto done)
set "GA=%VT%\recipe\chorus_C14\export\B22_11\B22_11.glb"
set "GB=%VT%\opus1291c14h\out\recipe\export\B22_11\B22_11.glb"
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $a = (Get-FileHash -LiteralPath $env:GA).Hash; $b = (Get-FileHash -LiteralPath $env:GB).Hash; 'recipe ' + $a; 'C14H   ' + $b; if ($a -ne $b) { exit 1 }" > "%O%\recipe_guard.txt" 2>&1
if errorlevel 1 (call "%JW%" fail "recipe\chorus_C14 no longer holds C14H's export, or opus1291c14h\out is gone (recipe_guard.txt); nothing rebuilt" & goto done)
>> "%R%" echo step 2 PASS: recipe\chorus_C14 holds C14H's export

rem 3. the ship job from the PR 1540 copy, shots stamped by its picture_provenance.py
set "PICTURE_STAMP_TOOL=%PP%"
set "SHIP=chorus_C14" & set "CODE=B22_11" & set "BRANCH=board/pin-1291-holes4" & set "JOB_DIR=opus1539c14h" & set "FACS=chorus" & set "STAGES=5_paint_bake 6_lod 7_export" & set "PC_GPU_ISSUE=1539"
call "%T%\tools\pc\jobs\ship_job.bat" > "%O%\ship_job_console.txt" 2>&1
set "SO=%SJ%\out"
set "SC=%SJ%\repo"
if not exist "%SO%\result.txt" (call "%JW%" fail "the ship job wrote no result.txt" & goto done)
copy /y "%SO%\result.txt" "%O%\ship_job_result.txt" > nul
findstr /b /c:"done PASS" "%SO%\result.txt" > nul || (call "%JW%" fail "the ship job did not pass (ship_job_result.txt)" & goto done)
findstr /b /c:"commit=%SHIP_PIN%" "%SO%\result.txt" > nul || (call "%JW%" fail "the ship job did not build the C14H pin" & goto done)
findstr /c:"shots stamped with" "%SO%\result.txt" | findstr /i /c:"%JOB%" > nul || (call "%JW%" fail "the shots were not stamped by PR 1540's picture_provenance.py" & goto done)
if not exist "%SO%\shots\B22_11_b.jpg" (call "%JW%" fail "no B22_11_b.jpg shot" & goto done)
copy /y "%SO%\shots\B22_11_b.jpg.provenance.json" "%O%\real_shot_stamp.json" > nul
>> "%R%" echo step 3 PASS: ship job done PASS at %SHIP_PIN%, shots stamped by the PR 1540 copy

rem 4. the real job's sheet
"%PY%" "%OS%" "%SO%" "%O%\C14H_offer_sheet.jpg" > "%O%\offer_real.txt" 2>&1
set "RC4=%ERRORLEVEL%"
type "%O%\offer_real.txt" >> "%R%"
if not "%RC4%"=="0" (call "%JW%" fail "offer_sheet refused the real job (offer_real.txt)" & goto done)
>> "%R%" echo step 4 PASS: offer_sheet wrote the sheet from the real PC shots

rem 5. a real source edit is refused
set "SIM=%O%\sim_edit"
call :sim "%SIM%"
>> "%SC%\godot\fx\fx.gd" echo # issue 1539 proof: a real source edit
"%PY%" "%PP%" stamp "%SIM%\shots\B22_11_b.jpg" --stage "installed in game" --repo "%SC%" --new-render > "%O%\stamp_edit.txt" 2>&1
set "RCS=%ERRORLEVEL%"
git -C "%SC%" checkout -q -- godot/fx/fx.gd >> "%O%\stamp_edit.txt" 2>&1
if errorlevel 1 (call "%JW%" fail "could not put godot\fx\fx.gd back in the clone" & goto done)
if not "%RCS%"=="0" (call "%JW%" fail "could not stamp the edit test shot (stamp_edit.txt)" & goto done)
"%PY%" "%OS%" "%SIM%" "%O%\sheet_edit.jpg" > "%O%\offer_edit.txt" 2>&1
set "RC5=%ERRORLEVEL%"
type "%O%\offer_edit.txt" >> "%R%"
if "%RC5%"=="0" (call "%JW%" fail "offer_sheet passed a shot from a tree with a source edit" & goto done)
findstr /c:"dirty" "%O%\offer_edit.txt" > nul || (call "%JW%" fail "the edit refusal does not say dirty" & goto done)
findstr /c:"godot/fx/fx.gd" "%O%\offer_edit.txt" > nul || (call "%JW%" fail "the edit refusal does not name godot/fx/fx.gd" & goto done)
if exist "%O%\sheet_edit.jpg" (call "%JW%" fail "a refused sheet was written" & goto done)
>> "%R%" echo step 5 PASS: a source edit is refused by name

rem 6. a live watchdog that differs from the pin's
copy /y "%SC%\tools\pc\tmo.bat" "%O%\tmo_saved.bat" > nul || (call "%JW%" fail "could not save the clone's tmo.bat" & goto done)
>> "%SC%\tools\pc\tmo.bat" echo rem issue 1539 proof: a live watchdog that differs from the pin's
set "SIM=%O%\sim_tmo"
call :sim "%SIM%"
git -C "%SC%" hash-object -- tools/pc/tmo.bat > "%SIM%\tmo_handoff.txt" 2> "%O%\stamp_tmo.txt"
"%PY%" "%PP%" stamp "%SIM%\shots\B22_11_b.jpg" --stage "installed in game" --repo "%SC%" --new-render >> "%O%\stamp_tmo.txt" 2>&1
set "RCS=%ERRORLEVEL%"
set "SIM3=%O%\sim_tmo_wrong"
call :sim "%SIM3%"
copy /y "%SIM%\shots\B22_11_b.jpg" "%SIM3%\shots\B22_11_b.jpg" > nul
copy /y "%SIM%\shots\B22_11_b.jpg.provenance.json" "%SIM3%\shots\B22_11_b.jpg.provenance.json" > nul
> "%SIM3%\tmo_handoff.txt" echo 0000000000000000000000000000000000000000
copy /y "%O%\tmo_saved.bat" "%SC%\tools\pc\tmo.bat" > nul
fc /b "%O%\tmo_saved.bat" "%SC%\tools\pc\tmo.bat" > nul || (call "%JW%" fail "the clone's tmo.bat was not put back" & goto done)
if not "%RCS%"=="0" (call "%JW%" fail "could not stamp the watchdog test shot (stamp_tmo.txt)" & goto done)
"%PY%" "%OS%" "%SIM%" "%O%\sheet_tmo.jpg" > "%O%\offer_tmo.txt" 2>&1
set "RC6=%ERRORLEVEL%"
type "%O%\offer_tmo.txt" >> "%R%"
if not "%RC6%"=="0" (call "%JW%" fail "offer_sheet refused a recorded watchdog hand-off (offer_tmo.txt)" & goto done)
"%PY%" "%OS%" "%SIM3%" "%O%\sheet_tmo_wrong.jpg" > "%O%\offer_tmo_wrong.txt" 2>&1
set "RC7=%ERRORLEVEL%"
type "%O%\offer_tmo_wrong.txt" >> "%R%"
if "%RC7%"=="0" (call "%JW%" fail "offer_sheet passed a tmo.bat that is not the recorded hand-off" & goto done)
findstr /c:"tools/pc/tmo.bat" "%O%\offer_tmo_wrong.txt" > nul || (call "%JW%" fail "the hand-off refusal does not name tools/pc/tmo.bat" & goto done)
>> "%R%" echo step 6 PASS: a differing live watchdog passes at its recorded hash and is refused at any other

>> "%R%" echo proof PASS: a real PC ship job's shots get through offer_sheet; a source edit and a wrong hand-off are refused
:done
call "%HEAD%" tail
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" >> "%R%" echo proof FAILED: see %OJ_OUT%\status.txt
>> "%R%" echo all done
type "%R%"
exit /b %RC%

rem ---- a copy of the job's records with one fresh, unstamped shot, for a stamp from the clone as it is now
:sim
mkdir "%~1\shots" "%~1\recipe" 2> nul
copy /y "%SO%\result.txt" "%~1\result.txt" > nul
copy /y "%SO%\recipe\log_detail.txt" "%~1\recipe\log_detail.txt" > nul
if exist "%SO%\tmo_handoff.txt" copy /y "%SO%\tmo_handoff.txt" "%~1\tmo_handoff.txt" > nul
copy /y "%SO%\base_manifest.json" "%~1\base_manifest.json" > nul
copy /y "%SO%\installed_manifest.json" "%~1\installed_manifest.json" > nul
copy /y "%SO%\shots\B22_11_b.jpg" "%~1\shots\B22_11_b.jpg" > nul
exit /b 0
