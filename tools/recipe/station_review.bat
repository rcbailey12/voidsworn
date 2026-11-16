@echo off
rem Refs #373. R247 review sheets and GPU comparisons, never an install.
call "%~dp0..\blender\kits\hegemony_station\review_run.bat"
exit /b %ERRORLEVEL%
