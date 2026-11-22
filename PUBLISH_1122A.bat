@echo off
title Publish 1373N Glasswright strike craft GV2, GW4 on Ryan's "Good to go" (Board, Nov 22 03:11 UTC)
rem Board, Nov 22 03:11 UTC: tools_live a41a4147845e pc\jobs\publish_ship.bat for opus1373gv2n ithar_GV2 and opus1373gw4n ithar_GW4 at 746d8d7c, one at a time; stops at the first refusal. UNDO kept under build\godot\_replaced\. Writes publish_1122a.txt.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\publish_1122a.txt"
set "TL=%V%\tools_live\a41a4147845e"
set "PICTURE_STAMP_TOOL=%TL%\picture_provenance.py"
set "PC_GPU_WAIT_SECONDS=3600"
echo publishes start %DATE% %TIME% > "%L%"
echo PUBLISH 1373N GV2 start %TIME% >> "%L%"
setlocal & set "PIN=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "PC_GPU_ISSUE=1373" & set "PICTURE_SOURCE_REPO=%V%\opus1373gv2n\repo" & call "%TL%\pc\jobs\publish_ship.bat" opus1373gv2n ithar_GV2 746d8d7c9a27a155575727e9e4c018b7ba6ebd66 7d7f4291b02e9bbfb57f0fac913233f568035080bf5939ddb90f1eaa4658c4b8 & endlocal
set "E=%ERRORLEVEL%"
echo PUBLISH 1373N GV2 exit %E% at %TIME% >> "%L%"
if not "%E%"=="0" (echo stopped after a refusal, the rest not run >> "%L%" & exit /b 1)
echo PUBLISH 1373N GW4 start %TIME% >> "%L%"
setlocal & set "PIN=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "PC_GPU_ISSUE=1373" & set "PICTURE_SOURCE_REPO=%V%\opus1373gw4n\repo" & call "%TL%\pc\jobs\publish_ship.bat" opus1373gw4n ithar_GW4 746d8d7c9a27a155575727e9e4c018b7ba6ebd66 9ce86aefa62b2d10e06a354c84653e50ad431ff87c822cf14b2ad0bc05745a2b & endlocal
set "E=%ERRORLEVEL%"
echo PUBLISH 1373N GW4 exit %E% at %TIME% >> "%L%"
if not "%E%"=="0" (echo stopped after a refusal, the rest not run >> "%L%" & exit /b 1)
echo publishes all done %TIME% >> "%L%"
exit /b 0