@echo off
rem Issue 362 GPU window 2: the branch as it will merge (after): probe twice, gate twice, moments twice; then the moments
rem compared with main's (before) runs: moments_diff.py (hull versus everything else) and the bench's own sheets; then
rem zips of what the report needs. Order: cheap steps first. Writes only under opus362\. Never deletes anything.
setlocal
set "D=%USERPROFILE%\Downloads\voidsworn_test\opus362"
set "PY=%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
call "%D%\run362.bat" probe origin/opus/issue-362 after
call "%D%\run362.bat" gate origin/opus/issue-362 after
call "%D%\run362.bat" moments origin/opus/issue-362 after
copy /y "%D%\repo\contrib\opus\reviews\readability_362\pc\moments_diff.py" "%D%\tool\" > nul
if not exist "%D%\mdiff_after" mkdir "%D%\mdiff_after"
if not exist "%D%\mdiff_noise" mkdir "%D%\mdiff_noise"
"%PY%" "%D%\tool\moments_diff.py" --before "%D%\moments_before_2" --after "%D%\moments_after_2" --out "%D%\mdiff_after" > "%D%\mdiff_after\log.txt" 2>&1
"%PY%" "%D%\tool\moments_diff.py" --before "%D%\moments_before_1" --after "%D%\moments_before_2" --out "%D%\mdiff_noise" > "%D%\mdiff_noise\log.txt" 2>&1
call "%D%\run362.bat" sheets moments_before_2 moments_after_2
call "%D%\zip362.bat" probe_after_2
call "%D%\zip362.bat" mdiff_after
call "%D%\zip362.bat" mdiff_noise
echo %date% %time% job b done >> "%D%\status.txt"
exit /b 0
