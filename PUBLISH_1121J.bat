@echo off
title Publish 1413f Navy O2, O3, HB1, H10 on Ryan's "Publish all four" (Board, Nov 21 23:30 UTC)
rem Board, Nov 21 23:30 UTC (Ryan, old-ships thread 23:28 UTC): tools_live a41a4147845e pc\jobs\publish_ship.bat for opus1413o2f O2_37, opus1413o3f O3_11, opus1413hb1f hegemony_HB1, opus1413h10f H10_23 at 7521a69d, one at a time; stops at the first refusal. UNDO kept under build\godot\_replaced\. Writes publish_1121j.txt.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\publish_1121j.txt"
set "TL=%V%\tools_live\a41a4147845e"
set "PICTURE_STAMP_TOOL=%TL%\picture_provenance.py"
set "PC_GPU_WAIT_SECONDS=3600"
echo publishes start %DATE% %TIME% > "%L%"
echo PUBLISH 1413F O2 start %TIME% >> "%L%"
setlocal & set "PIN=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "PC_GPU_ISSUE=1413" & set "PICTURE_SOURCE_REPO=%V%\opus1413o2f\repo" & call "%TL%\pc\jobs\publish_ship.bat" opus1413o2f O2_37 7521a69d4299163e965750f87fdd3819097ef158 559e638717ebe771c3603f79cbb5175bda12ddc67f5b8d4a66701a0c3400e854 & endlocal
set "E=%ERRORLEVEL%"
echo PUBLISH 1413F O2 exit %E% at %TIME% >> "%L%"
if not "%E%"=="0" (echo stopped after a refusal, the rest not run >> "%L%" & exit /b 1)
echo PUBLISH 1413F O3 start %TIME% >> "%L%"
setlocal & set "PIN=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "PC_GPU_ISSUE=1413" & set "PICTURE_SOURCE_REPO=%V%\opus1413o3f\repo" & call "%TL%\pc\jobs\publish_ship.bat" opus1413o3f O3_11 7521a69d4299163e965750f87fdd3819097ef158 8ff62d4b73ac244074c0d463f7759674807099639ba84ae08a5201656bec5a85 & endlocal
set "E=%ERRORLEVEL%"
echo PUBLISH 1413F O3 exit %E% at %TIME% >> "%L%"
if not "%E%"=="0" (echo stopped after a refusal, the rest not run >> "%L%" & exit /b 1)
echo PUBLISH 1413F HB1 start %TIME% >> "%L%"
setlocal & set "PIN=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "PC_GPU_ISSUE=1413" & set "PICTURE_SOURCE_REPO=%V%\opus1413hb1f\repo" & call "%TL%\pc\jobs\publish_ship.bat" opus1413hb1f hegemony_HB1 7521a69d4299163e965750f87fdd3819097ef158 0c5aba0895a748a0c24a50947512adce361f9ea2fa0059e96c50be196b2d6470 & endlocal
set "E=%ERRORLEVEL%"
echo PUBLISH 1413F HB1 exit %E% at %TIME% >> "%L%"
if not "%E%"=="0" (echo stopped after a refusal, the rest not run >> "%L%" & exit /b 1)
echo PUBLISH 1413F H10 start %TIME% >> "%L%"
setlocal & set "PIN=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "PC_GPU_ISSUE=1413" & set "PICTURE_SOURCE_REPO=%V%\opus1413h10f\repo" & call "%TL%\pc\jobs\publish_ship.bat" opus1413h10f H10_23 7521a69d4299163e965750f87fdd3819097ef158 7b04efd4b3bcded22a9d744cf1b1d08f1861cb243f681f7f0882c1315f1e8f09 & endlocal
set "E=%ERRORLEVEL%"
echo PUBLISH 1413F H10 exit %E% at %TIME% >> "%L%"
if not "%E%"=="0" (echo stopped after a refusal, the rest not run >> "%L%" & exit /b 1)
echo publishes all done %TIME% >> "%L%"
exit /b 0