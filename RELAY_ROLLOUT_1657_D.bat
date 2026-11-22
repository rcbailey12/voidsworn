@echo off
rem Issue 1657 rollout, step D: the prune DRY list only (rollout C proved the relay push, de43b505, both files in the tree;
rem its findstr /x tree check was a false FAIL on LF-only lines). Deletes nothing.
setlocal EnableExtensions
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "P=%VT%\relayproof1657"
if not exist "%P%" mkdir "%P%"
set "LOG=%P%\rollout_log_D.txt"
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined TLV (echo FAILED: no tools_live\current.txt>"%LOG%" & type "%LOG%" & exit /b 2)
set "T=%VT%\tools_live\%TLV%\pc"
echo tools_live %TLV%>"%LOG%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%T%\prune_relay_branches.ps1" >>"%LOG%" 2>&1
if errorlevel 1 (echo FAILED: prune dry run>>"%LOG%" & type "%LOG%" & exit /b 6)
echo prune dry list written under %VT%\prune\ ^(nothing deleted^)>>"%LOG%"
echo all done PASS>>"%LOG%"
type "%LOG%"
exit /b 0
