@echo off
title Ship line CS: 1373M in-game squadron probe PROBE18B (Board, Nov 22)
rem Board, Nov 22 00:09 UTC (inbox fb687300, folder 1373p18): calls wait1373p18\OPUS1373M_PROBE18B.bat (sha256 8f593783, unedited, with probe1373m_prep.ps1 b0e3ef63 beside it), the way OPUS1373P17_WAIT ran PROBE17B.
rem It checks out board/pin-1373m 44987b5b in opus1373probe11\repo with the GV2 and GW4 kits from opus1373gv2m / opus1373gw4m; output opus1373probe18\out; its GPU step is PC_GPU_MODE=solo through tools_live tmo.bat (fail closed).
rem The bat writes its own end line "1373M PROBE18 exit" into %L% (this log). Writes chain_1119cs.txt. Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\chain_1119cs.txt"
set "PC_GPU_WAIT_SECONDS=3600"
echo 1373M PROBE18B start %DATE% %TIME% >> "%L%"
call "%V%\wait1373p18\OPUS1373M_PROBE18B.bat"
findstr /b /c:"1373M PROBE18 exit" "%L%" >nul 2>&1 || echo 1373M PROBE18 exit 9 at %TIME%, the bat ended without its own end line >> "%L%"
echo all done %DATE% %TIME% >> "%L%"
exit /b 0