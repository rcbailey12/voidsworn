@echo off
rem Internal adapter for manifest_merge.py: bound each headless check while leaving rollback in the installer.
setlocal
set "TMO_STEP=recipe 7 install %~5"
set "TMO_STEP_OUT=%INSTALL_TO%\gen"
call "%~dp0..\pc\tmo.bat" %RECIPE_CHECK_CAP% "%GD%" %*
exit /b %ERRORLEVEL%
