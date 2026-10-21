@echo off
REM usage: fx_run.bat <res> <frames> <variants...>
set T=%USERPROFILE%\Downloads\voidsworn_test
for /f "delims=" %%b in (%T%\blender_path.txt) do set BL=%%b
set PYTHONPATH=
set RES=%1
set FR=%2
shift
shift
if not exist %T%\fx mkdir %T%\fx
echo start %date% %time% > %T%\fx_log.txt
:loop
if "%1"=="" goto end
"%BL%" -b --factory-startup -P %T%\fxsim.py -- %T%\fx %1 %RES% %FR% >> %T%\fx_log.txt 2>&1
echo variant %1 rc %errorlevel% >> %T%\fx_log.txt
shift
goto loop
:end
echo FX DONE %date% %time% >> %T%\fx_log.txt
