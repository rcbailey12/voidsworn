@echo off
rem Issue 1877 (R437): real 1080p look-bench clips of the four Chorus close-weapon options on the PC.
rem Benches branch opus/issue-1877 with its own bench script and the chorus_close rows (Spitter B20_11 firing at the
rem Cordon destroyer H8_23 one hex away, cameras 170 and 26, every frame saved). Copies the built hulls in, deletes nothing.
rem Frames land in Downloads\voidsworn_test\look_bench\runs\<commit>\moments\cc_*__c170 and __c26; the Board makes the mp4s.
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "PC_GPU_ISSUE=1877"
set "LB_TOOL_REF=origin/opus/issue-1877"
set "LB_ARGS=--part moments --moments res://bench/look_moments_chorus_close.json"
call "%VT%\build_b\tools\pc\jobs\look_bench.bat" origin/opus/issue-1877 none
echo look bench 1877 exit %ERRORLEVEL% > "%VT%\look_bench\OPUS1877_result.txt"
