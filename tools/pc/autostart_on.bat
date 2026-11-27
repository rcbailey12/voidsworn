@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem The installer may be in a build tools copy. The queues live at the PC root.
set "PC_DIR=Downloads\voidsworn_test"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "S=%STARTUP%\voidsworn_watcher.bat"
set "L=%STARTUP%\voidsworn_watcher_b.bat"
set "C=%STARTUP%\voidsworn_codex_board.bat"
if not exist "%USERPROFILE%\%PC_DIR%\watcher.bat" goto missing
if not exist "%USERPROFILE%\%PC_DIR%\watcher_b.bat" goto missing

rem The root watcher already starts its sibling watcher_b.bat. Retire the duplicate Startup entry.
if exist "%L%" del "%L%"
if exist "%L%" goto duplicate
(
  echo @echo off
  echo start "Voidsworn test watcher" /min "%%USERPROFILE%%\%PC_DIR%\watcher.bat"
) > "%S%" || goto write_failed

rem Retire only the startup entry created by earlier versions of this installer.
if exist "%C%" del "%C%"
if exist "%C%" goto retired_failed
echo Done. Both Voidsworn queue watchers will start when you log in.
echo To undo this, double-click autostart_off.bat in the same folder.
pause
exit /b 0

:missing
echo Both watcher.bat and watcher_b.bat must be in "%USERPROFILE%\%PC_DIR%". Startup was not changed.
goto failed
:duplicate
echo Could not remove the duplicate Startup entry "%L%".
goto failed
:write_failed
echo Could not write the Startup entry "%S%".
goto failed
:retired_failed
echo WARNING: the retired Codex startup entry "%C%" could not be removed.
:failed
pause
exit /b 1
