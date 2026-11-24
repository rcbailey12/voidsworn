@echo off
rem Issue 2011 (R431 publish follow-up): publish the round F build of ithar_GA1 (I16_11), built at 020b529587b19bb1f94fc391af6ef53b3d2baf60 on opus/issue-1777-glass
rem (job opus431f_GA1, receipt done PASS then all done). Every input of this hull is unchanged on main since that commit
rem (the later kit edits are a default-off option and docs), so this is the merged look Ryan approved. publish_ship.bat refuses
rem unless the receipt, commit and glb sha match exactly; it backs up the old ship and writes an UNDO bat; it deletes nothing
rem but its own job clone after a PASS (RULEBOOK 3.3, issue 1497).
setlocal EnableExtensions
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined TLV (echo FAILED: no tools_live\current.txt & exit /b 2)
set "PUB=%VT%\tools_live\%TLV%\pc\jobs\publish_ship.bat"
if not exist "%PUB%" (echo FAILED: no publish_ship.bat at %PUB% & exit /b 2)
call "%PUB%" opus431f_GA1 I16_11 020b529587b19bb1f94fc391af6ef53b3d2baf60 ae0041d527ec86a299809b310132ec8568746a5442103e9ac5a0fe2439b36afd
exit /b %ERRORLEVEL%
