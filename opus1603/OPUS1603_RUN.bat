@echo off
rem Issue 1603: the issue 1551 story text on Windows, after PR 1579 (merged 5aaa8163). Two checks, both in the real game code:
rem  1. Old save: on the commit before the merge (9cf8f12b) the game writes four real campaign saves (Sector II map with a
rem     repair stop, standing on an event, inside a shipyard, round 2 of a fight); on the merge commit each one is loaded
rem     cold as Continue does and must resume with no error, nothing dropped, the same run, and the new words
rem     (godot/tools/probes/old_save_1603.gd). Pictures RESUME-1603_map, _event, _yard.
rem  2. Text fit: the Sector III story cards and their results, every event card, the shipyard and the full battle log,
rem     for all six factions at Normal and Larger text; every visible label, button and rich text box is measured and any
rem     cut-off or hidden text fails (godot/tools/probes/text_fit_1603.gd). Pictures STORY-1603, EVENT-1603, SHIP-1603,
rem     LOG-1603, each _normal and _larger, at most 720 tall, code name on each.
rem The pins are the two commits plus only the two probe scripts (branch claude/project-thread-wws9qu): PIN_OLD = 9cf8f12b + probes,
rem PIN_NEW = 5aaa8163 + probes (the merge of PIN_OLD into 5aaa8163, so its game files are exactly 5aaa8163's).
rem The old checkout runs first because a slot job's second checkout resets the same slot. Saves go to <attempt>\saves,
rem never to Ryan's profile; every Godot start has the watchdog's throwaway profile. Deletes nothing of its own.
rem Built from opus_job_template.bat; once queued it is never edited (a change ships under a new name).
setlocal EnableExtensions
set "JOB=opus1603"
set "LABEL=1603"
set "TOOLS=godot"
set "PIN_NEW=06049a02332724df9b84564f05c647677dd9916a"
set "PIN_OLD=0cea72288c8403f4da7d2d299f381f4e45e1f675"
set "OJ_SLOTS=1"
set "OJ_SLOT_KIND=gpu"

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
set "SV=%OJ_OUT%\saves"
if not exist "%SV%" mkdir "%SV%"
rem Godot gets forward slashes (OJ_OUT is always defined here, so the substitution is safe)
set "SVG=%SV:\=/%"
set "PICTURE_SOURCE_REPO="

rem ---- 1a. the old build writes the saves (headless; no hulls needed)
call "%HEAD%" checkout old %PIN_OLD%
set "O=%OJ_OUT%\out_old"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=old import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if not exist "%OJ_REPO%\godot\tools\probes\old_save_1603.gd" (call "%JW%" fail "old checkout has no probe script" & goto :tail)
set "JW_STEP=old make saves" & set "JW_EXPECT=%SV%\old_cases.json;%SV%\map\campaign.json;%SV%\event\campaign.json;%SV%\yard\campaign.json;%SV%\battle\campaign.json" & call "%JW%" run 900 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --script res://tools/probes/old_save_1603.gd -- make "%SVG%" > "%O%\make_saves.txt" 2>&1
findstr /c:"OLD_SAVE_1603 PASS" "%O%\make_saves.txt" > nul || call "%JW%" fail "old build did not write the saves, see out_old\make_saves.txt"
findstr /c:"SCRIPT ERROR" "%O%\make_saves.txt" > nul && call "%JW%" fail "script error while writing the saves, see out_old\make_saves.txt"

rem ---- 1b and 2. the merged build: resume the saves, then the text fit, both in a 1920x1080 window
call "%HEAD%" checkout new %PIN_NEW%
call "%HEAD%" ships
set "O=%OJ_OUT%\out_new"
if not exist "%O%" mkdir "%O%"
set "OG=%O:\=/%"
set "PICTURE_SOURCE_REPO=%OJ_REPO%"
set "JW_STEP=new import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
set "JW_STEP=new resume old saves" & set "JW_CONTINUE=1" & set "JW_EXPECT=%O%\resume\RESUME-1603_map.png;%O%\resume\RESUME-1603_event.png;%O%\resume\RESUME-1603_yard.png" & call "%JW%" run 900 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --script res://tools/probes/old_save_1603.gd -- resume "%SVG%" "%OG%/resume" %PIN_NEW% > "%O%\resume_log.txt" 2>&1
findstr /c:"OLD_SAVE_1603 PASS" "%O%\resume_log.txt" > nul || (set "JW_CONTINUE=1" & call "%JW%" fail "an old save did not resume cleanly, see out_new\resume_log.txt")
findstr /c:"SCRIPT ERROR" "%O%\resume_log.txt" > nul && (set "JW_CONTINUE=1" & call "%JW%" fail "script error while resuming, see out_new\resume_log.txt")
set "JW_STEP=new text fit" & set "JW_EXPECT=%O%\text_fit\text_fit_1603.txt;%O%\text_fit\LOG-1603_battle_log_larger.png;%O%\text_fit\SHIP-1603_chorus_larger.png" & call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --script res://tools/probes/text_fit_1603.gd -- "%OG%/text_fit" %PIN_NEW% > "%O%\text_fit_log.txt" 2>&1
findstr /c:"TEXT_FIT_1603 PASS" "%O%\text_fit_log.txt" > nul || call "%JW%" fail "some text is cut off or hidden, see out_new\text_fit\text_fit_1603.txt"
findstr /c:"SCRIPT ERROR" "%O%\text_fit_log.txt" > nul && call "%JW%" fail "script error in the text fit, see out_new\text_fit_log.txt"

:tail
call "%HEAD%" tail
exit /b %ERRORLEVEL%
