@echo off
title Publish 1291 Chorus C11 G and C12 G on Ryan's "Yes" (Board, Nov 21 15:59 UTC)
rem Board, Nov 21 15:59 UTC (Ryan "Yes", Chorus thread 15:58 UTC): tools_live 9204dbb0c395 pc\jobs\publish_ship.bat opus1291c11g B21_11 d2a9acd2 56c9f6be, then opus1291c12g B19_11 d2a9acd2 11da0fb7; PIN, STAGES, PAINT_BASE, SETS cleared;
rem UNDO kept under build\godot\_replaced\. End lines "PUBLISH 1291 C11G exit", "PUBLISH 1291 C12G exit". Writes publish_1121f.txt. Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\publish_1121f.txt"
set "TL=%V%\tools_live\9204dbb0c395"
set "PICTURE_STAMP_TOOL=%TL%\picture_provenance.py"
set "PC_GPU_WAIT_SECONDS=3600"
echo publishes start %DATE% %TIME% > "%L%"
echo PUBLISH 1291 C11G start %TIME% >> "%L%"
setlocal & set "PIN=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "PC_GPU_ISSUE=1291" & set "PICTURE_SOURCE_REPO=%V%\opus1291c11g\repo" & call "%TL%\pc\jobs\publish_ship.bat" opus1291c11g B21_11 d2a9acd26c3305641229d000d8890ba8a753dcfb 56c9f6be63bdbb9ca9a5be9596c20e3dc8e330c78fb1ddce23d147fc9aa72ae5 & endlocal
echo PUBLISH 1291 C11G exit %ERRORLEVEL% at %TIME% >> "%L%"
echo PUBLISH 1291 C12G start %TIME% >> "%L%"
setlocal & set "PIN=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "PC_GPU_ISSUE=1291" & set "PICTURE_SOURCE_REPO=%V%\opus1291c12g\repo" & call "%TL%\pc\jobs\publish_ship.bat" opus1291c12g B19_11 d2a9acd26c3305641229d000d8890ba8a753dcfb 11da0fb7f016b4ea578b7bc554ba4b28c5ec39bcd2d1dd98a2be2fd365ec509a & endlocal
echo PUBLISH 1291 C12G exit %ERRORLEVEL% at %TIME% >> "%L%"
exit /b 0