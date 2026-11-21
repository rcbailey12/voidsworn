@echo off
title Publish 1291 Chorus C13 L and C10 H on Ryan's "Yes" (Board, Nov 21 15:23 UTC)
rem Board, Nov 21 15:23 UTC (Ryan "Yes", Chorus thread 15:22 UTC): tools_live 9204dbb0c395 pc\jobs\publish_ship.bat opus1291c13l B20_11 d2a9acd2 f69ae2f5, then opus1291c10h B16_23 d2a9acd2 abf178af; PIN, STAGES, PAINT_BASE, SETS cleared;
rem UNDO kept under build\godot\_replaced\. End lines "PUBLISH 1291 C13L exit", "PUBLISH 1291 C10H exit". Writes publish_1121d.txt. Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\publish_1121d.txt"
set "TL=%V%\tools_live\9204dbb0c395"
set "PICTURE_STAMP_TOOL=%TL%\picture_provenance.py"
set "PC_GPU_WAIT_SECONDS=3600"
echo publishes start %DATE% %TIME% > "%L%"
echo PUBLISH 1291 C13L start %TIME% >> "%L%"
setlocal & set "PIN=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "PC_GPU_ISSUE=1291" & set "PICTURE_SOURCE_REPO=%V%\opus1291c13l\repo" & call "%TL%\pc\jobs\publish_ship.bat" opus1291c13l B20_11 d2a9acd26c3305641229d000d8890ba8a753dcfb f69ae2f5f222ff7c822d07a5436aec484e4753089ce2cffc71e9af2c9f71ddfa & endlocal
echo PUBLISH 1291 C13L exit %ERRORLEVEL% at %TIME% >> "%L%"
echo PUBLISH 1291 C10H start %TIME% >> "%L%"
setlocal & set "PIN=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "PC_GPU_ISSUE=1291" & set "PICTURE_SOURCE_REPO=%V%\opus1291c10h\repo" & call "%TL%\pc\jobs\publish_ship.bat" opus1291c10h B16_23 d2a9acd26c3305641229d000d8890ba8a753dcfb abf178af67a48ebc5db75ee3a150f6403a23eef574e9782fc5cb14a14d4c206c & endlocal
echo PUBLISH 1291 C10H exit %ERRORLEVEL% at %TIME% >> "%L%"
exit /b 0