@echo off
title Publish 1373L Corsair KF1 on Ryan's "Yes good" (Board, Nov 21 15:43 UTC)
rem Board, Nov 21 15:43 UTC (Ryan "Yes good", strike craft thread 15:42 UTC): tools_live 9204dbb0c395 pc\jobs\publish_ship.bat opus1373kf1l corsair_KF1 237fd5b2 a7c36d58; PIN, STAGES, PAINT_BASE, SETS cleared;
rem UNDO kept under build\godot\_replaced\. End line "PUBLISH 1373L KF1 exit". Writes publish_1121e.txt. Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\publish_1121e.txt"
set "TL=%V%\tools_live\9204dbb0c395"
set "PICTURE_STAMP_TOOL=%TL%\picture_provenance.py"
set "PC_GPU_WAIT_SECONDS=3600"
echo PUBLISH 1373L KF1 start %DATE% %TIME% > "%L%"
setlocal & set "PIN=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "PC_GPU_ISSUE=1373" & set "PICTURE_SOURCE_REPO=%V%\opus1373kf1l\repo" & call "%TL%\pc\jobs\publish_ship.bat" opus1373kf1l corsair_KF1 237fd5b260efe1be2df04aba5492ed7d41e505c6 a7c36d580c20e9fa800e2c765c7a45a3031b6dd39baccf4d7c40d3b401f647ca & endlocal
echo PUBLISH 1373L KF1 exit %ERRORLEVEL% at %TIME% >> "%L%"
exit /b 0