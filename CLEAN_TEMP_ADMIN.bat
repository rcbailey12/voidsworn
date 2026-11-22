@echo off
rem CLEAN_TEMP_ADMIN.bat - for Ryan to right-click and "Run as administrator" (Board, Nov 22 04:14 UTC; Ryan "Okay to clean temp" 22:11 CT).
rem Removes ONLY the 31 leftover voidsworn job folders in TEMP that cleanup 4 could not remove (their contents belong to the CodexSandboxOffline account).
rem Each path is named in full below; no wildcard is used. For each: take ownership, grant the Administrators group full control, measure, delete, log.
rem Log: %USERPROFILE%\Downloads\voidsworn_test\board1119\clean_temp_admin_log.txt
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (echo This needs "Run as administrator". Nothing was changed. & pause & exit /b 1)
set "LOG=%USERPROFILE%\Downloads\voidsworn_test\board1119\clean_temp_admin_log.txt"
echo clean temp admin start %DATE% %TIME% >> "%LOG%"
for /f "tokens=3" %%F in ('dir /-c C:\ ^| findstr /c:"bytes free"') do echo C: free before %%F bytes >> "%LOG%"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-0592fe522a994357a9b4a4d1c6b4d85b.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-096fcda062c04820b365672a12e1e725.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-0a5ba3f8cc3b4936baa4722685fd6d89.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-1029146854084a55be8f7e5cbef7432d.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-1cd66982941249fc8cf002ed52bccdec.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-1feeba5e919f457c92bcf268f02538d0.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-212d86aa70c74373b9cf3a53366709ef.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-2c77816056da466d911a631e0acdc995.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-49ee68fd69154bb991cb65bbbba55f7d.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-516ab44bd6e5489f8204ac433c8bf68b.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-5660932789454f799423a15cdbe79157.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-679b801e1cb64bd58239d0ed409c69ae.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-6a82604fc40449089604810626cb730b.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-76037b3c57f44545a479839d25f22f6e.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-8b223a64168e41ec81278d00dc743df6.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-8b7cd6eb643a4311b275ba918dc4996f.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-94fdd5cee40c41cea555a1e1a1bc6253.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-acf3918ca6d541179cad4ee23c59a30f.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-b9efeea17ec34a02b8c960d2d6d89036.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-c27e60aed22246d1a54c121bb1d29aa8.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-c3a0f93d3f55499da85fe414a8c3bb56.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-ce9565d4d5004b63837c782304d601d7.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-da92310f5d3541eca3b5840e2e243e31.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-ddc05ff5f6094a9a9e6ba81071071de1.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-de77f47589ee4590ab6e89b3c1b347c0.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-e9951aa3bab74a91a6713b1208fecd15.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-ee965be24a39431f9fb0b1639fe961c3.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-f09f6fe17ecc435199493a46dcb5ce45.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-f880c1064c91426ca0d600d0873a7c65.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-f9fd79a03f18487690a4a9fd0cffafd1.removing"
call :one "C:\Users\rcbai\AppData\Local\Temp\voidsworn-run-fb6cbb420eee49299c7dbcb30141a3eb.removing"
for /f "tokens=3" %%F in ('dir /-c C:\ ^| findstr /c:"bytes free"') do echo C: free after %%F bytes >> "%LOG%"
echo clean temp admin done %DATE% %TIME% >> "%LOG%"
echo.
echo Done. The log is in %LOG%
pause
exit /b 0
:one
set "D=%~1"
if not exist "%D%" (echo gone already: %D% >> "%LOG%" & exit /b 0)
takeown /f "%D%" /r /d y >nul 2>&1
icacls "%D%" /grant *S-1-5-32-544:(OI)(CI)F /t /c /q >nul 2>&1
set "SZ=0"
for /f "tokens=3" %%S in ('dir /s /-c "%D%" 2^>nul ^| findstr /c:"File(s)"') do set "SZ=%%S"
rd /s /q "%D%" 2>nul
if exist "%D%" (echo NOT removed ^(!SZ! bytes^): %D% >> "%LOG%" & echo NOT removed: %D%) else (echo removed ^(!SZ! bytes^): %D% >> "%LOG%" & echo removed ^(!SZ! bytes^): %D%)
exit /b 0
