@echo off
title Publish 1291 Chorus C14 K on Ryan's "Cool, everything looks goood" (Board, Nov 21 21:37 UTC)
rem Board, Nov 21 21:37 UTC (Ryan, Chorus thread 21:37 UTC): tools_live 2f6488efe90d pc\jobs\publish_ship.bat opus1291c14k B22_11 4a73ba3a aa516019; PIN, STAGES, PAINT_BASE, SETS cleared;
rem UNDO kept under build\godot\_replaced\. End line "PUBLISH 1291 C14K exit". Writes publish_1121g.txt.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\publish_1121g.txt"
set "TL=%V%\tools_live\2f6488efe90d"
set "PICTURE_STAMP_TOOL=%TL%\picture_provenance.py"
set "PC_GPU_WAIT_SECONDS=3600"
echo publishes start %DATE% %TIME% > "%L%"
echo PUBLISH 1291 C14K start %TIME% >> "%L%"
setlocal & set "PIN=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "PC_GPU_ISSUE=1291" & set "PICTURE_SOURCE_REPO=%V%\opus1291c14k\repo" & call "%TL%\pc\jobs\publish_ship.bat" opus1291c14k B22_11 4a73ba3abee5a62b3317a63030ca082a498e86d6 aa5160198f8503a54f89b524f1ebe5e17154ea6ca1473e88a63c1860bd23e77b & endlocal
echo PUBLISH 1291 C14K exit %ERRORLEVEL% at %TIME% >> "%L%"
exit /b 0