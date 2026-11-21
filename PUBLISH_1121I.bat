@echo off
title Publish 1415H Glasswright GS1, GL1, GP1, GA1 on Ryan's "Yes, publish all four" (Board, Nov 21 22:41 UTC)
rem Board, Nov 21 22:41 UTC (Ryan, Glasswright thread 22:40 UTC): tools_live a41a4147845e pc\jobs\publish_ship.bat for opus1415h_GS1 I14_23, GL1 I11_37, GP1 I15_11, GA1 I16_11 at ddc85277 one at a time; stops at the first refusal. UNDO kept under build\godot\_replaced\. Writes publish_1121i.txt.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\publish_1121i.txt"
set "TL=%V%\tools_live\a41a4147845e"
set "PICTURE_STAMP_TOOL=%TL%\picture_provenance.py"
set "PC_GPU_WAIT_SECONDS=3600"
echo publishes start %DATE% %TIME% > "%L%"
echo PUBLISH 1415H GS1 start %TIME% >> "%L%"
setlocal & set "PIN=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "PC_GPU_ISSUE=1415" & set "PICTURE_SOURCE_REPO=%V%\opus1415h_GS1\repo" & call "%TL%\pc\jobs\publish_ship.bat" opus1415h_GS1 I14_23 ddc85277c0ef733d1ebb46ce95127a262826cf41 6421b23a73fa0628cf7e6184be1efd7224aa398a9c744fb2aa9f38d9a68f5ecb & endlocal
set "E=%ERRORLEVEL%"
echo PUBLISH 1415H GS1 exit %E% at %TIME% >> "%L%"
if not "%E%"=="0" (echo stopped after a refusal, the rest not run >> "%L%" & exit /b 1)
echo PUBLISH 1415H GL1 start %TIME% >> "%L%"
setlocal & set "PIN=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "PC_GPU_ISSUE=1415" & set "PICTURE_SOURCE_REPO=%V%\opus1415h_GL1\repo" & call "%TL%\pc\jobs\publish_ship.bat" opus1415h_GL1 I11_37 ddc85277c0ef733d1ebb46ce95127a262826cf41 df9f533f8b8405ab8b9db0336f5da7fb642a90241d0356109057c9b5dfc5fb2d & endlocal
set "E=%ERRORLEVEL%"
echo PUBLISH 1415H GL1 exit %E% at %TIME% >> "%L%"
if not "%E%"=="0" (echo stopped after a refusal, the rest not run >> "%L%" & exit /b 1)
echo PUBLISH 1415H GP1 start %TIME% >> "%L%"
setlocal & set "PIN=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "PC_GPU_ISSUE=1415" & set "PICTURE_SOURCE_REPO=%V%\opus1415h_GP1\repo" & call "%TL%\pc\jobs\publish_ship.bat" opus1415h_GP1 I15_11 ddc85277c0ef733d1ebb46ce95127a262826cf41 cdb9a54726119a5d7b06afaed44078764e0c26f60bc25eaa482356c00406c173 & endlocal
set "E=%ERRORLEVEL%"
echo PUBLISH 1415H GP1 exit %E% at %TIME% >> "%L%"
if not "%E%"=="0" (echo stopped after a refusal, the rest not run >> "%L%" & exit /b 1)
echo PUBLISH 1415H GA1 start %TIME% >> "%L%"
setlocal & set "PIN=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "PC_GPU_ISSUE=1415" & set "PICTURE_SOURCE_REPO=%V%\opus1415h_GA1\repo" & call "%TL%\pc\jobs\publish_ship.bat" opus1415h_GA1 I16_11 ddc85277c0ef733d1ebb46ce95127a262826cf41 8efcd98f9af249a687fcd4b859304906032ec6545b7f0acdc10f95d58f6d77fc & endlocal
set "E=%ERRORLEVEL%"
echo PUBLISH 1415H GA1 exit %E% at %TIME% >> "%L%"
if not "%E%"=="0" (echo stopped after a refusal, the rest not run >> "%L%" & exit /b 1)
echo publishes all done %TIME% >> "%L%"
exit /b 0