@echo off
title C13 launcher (issue 1154) - RETIRED
rem RETIRED (Artoo, issue 1154, Nov 20): this launcher let SKIP3=1 override FULL=1 and ended "exit 0" after a failed stage,
rem so a failed or shortened C13 job could look finished to the queue. C13 (chorus_C13, game folder B20_11) is now built by
rem tools\pc\jobs\OPUS1291_EXPORT.bat (issue 1291): fail closed on every step, its own out folder per run, publish only with
rem PUBLISH=1 after Ryan's yes. This file stays so an old queue line fails loudly instead of running the old path.
rem Writes only opus1154out\retired\result.txt. Nothing is deleted.
setlocal
set "O=%USERPROFILE%\Downloads\voidsworn_test\opus1154out\retired"
if not exist "%O%" mkdir "%O%"
echo start C13_RUN_1154 %* %DATE% %TIME% > "%O%\result.txt"
echo all done FAILED: C13_RUN_1154.bat is retired; run tools\pc\jobs\OPUS1291_EXPORT.bat (issue 1291) >> "%O%\result.txt"
echo C13_RUN_1154.bat is retired; run tools\pc\jobs\OPUS1291_EXPORT.bat (issue 1291)
exit /b 1
