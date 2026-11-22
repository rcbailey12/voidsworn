@echo off
rem Issue 1657 rollout, step B (the Board queues this after PR 1740 merges; Ryan does nothing). Deletes nothing, here or on
rem GitHub. Step A's push (pc-out-relayproof1657 at b7a1a878) had an EMPTY tree: Windows PowerShell 5.1 lost the file list
rem on its way into git (issue 1739). B is A again with the fixed relay_push.ps1 and a check of the pushed tree itself.
rem  1. checks tools_live (which the watcher refreshes from main before every job) holds PR 1672's relay code and the
rem     issue 1739 fix;
rem  2. checks this PC can read the private relay repo rcbailey12/voidsworn-relay;
rem  3. makes one tiny test attempt under voidsworn_test\relayproof1657, lists it with relay_push dry, then pushes it
rem     for real to branch pc-out-relayproof1657 of the relay repo, checks GitHub has the pushed commit, and checks that
rem     commit's tree holds both test files;
rem  4. writes the prune DRY list (voidsworn_test\prune\), which deletes nothing; the live prune is Ryan's double-click.
rem Everything goes to voidsworn_test\relayproof1657\rollout_log.txt and to this window. Exit 0 only when all four pass.
setlocal EnableExtensions
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "GIT_TERMINAL_PROMPT=0"
set "GCM_INTERACTIVE=never"
set "P=%VT%\relayproof1657"
if not exist "%P%" mkdir "%P%"
set "LOG=%P%\rollout_log_B.txt"
set "RELAY=https://github.com/rcbailey12/voidsworn-relay"
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined TLV (echo FAILED step 1: no tools_live\current.txt>"%LOG%" & type "%LOG%" & exit /b 2)
set "T=%VT%\tools_live\%TLV%\pc"
echo step 1: tools_live is %TLV%>"%LOG%"
findstr /c:"voidsworn-relay" "%T%\relay_push.ps1" >nul 2>&1
if errorlevel 1 (echo FAILED step 1: tools_live %TLV% has no relay_push.ps1 from PR 1672 yet; rerun after the watcher refreshes it>>"%LOG%" & type "%LOG%" & exit /b 3)
findstr /c:"Get-RelayRepo" "%T%\jobs\opus_job_head.ps1" >nul 2>&1
if errorlevel 1 (echo FAILED step 1: tools_live %TLV% has an opus_job_head.ps1 older than PR 1672>>"%LOG%" & type "%LOG%" & exit /b 3)
findstr /c:"the relay tree is missing" "%T%\relay_push.ps1" >nul 2>&1
if errorlevel 1 (echo FAILED step 1: tools_live %TLV% has a relay_push.ps1 older than the issue 1739 fix; rerun after the watcher refreshes it>>"%LOG%" & type "%LOG%" & exit /b 3)
echo step 1 PASS: tools_live holds the PR 1672 relay code and the issue 1739 fix>>"%LOG%"
git ls-remote "%RELAY%" HEAD >>"%LOG%" 2>&1
if errorlevel 1 (echo FAILED step 2: this PC cannot read %RELAY% ^(GitHub sign-in on the PC^)>>"%LOG%" & type "%LOG%" & exit /b 4)
echo step 2 PASS: the relay repo answers>>"%LOG%"
for /f %%s in ('powershell -NoProfile -Command "[DateTime]::UtcNow.ToString('yyyyMMdd_HHmmss')"') do set "ST=%%s"
set "AT=%P%\out_%ST%_1"
mkdir "%AT%\out_proof"
echo PASS>"%AT%\done.txt"
echo relay proof B for issue 1657, made %ST% UTC>"%AT%\out_proof\proof.txt"
call "%T%\relay_push.bat" relayproof1657 "%AT%" dry >>"%LOG%" 2>&1
if errorlevel 1 (echo FAILED step 3: relay_push dry>>"%LOG%" & type "%LOG%" & exit /b 5)
call "%T%\relay_push.bat" relayproof1657 "%AT%" >>"%LOG%" 2>&1
if errorlevel 1 (echo FAILED step 3: relay_push could not push to the relay repo>>"%LOG%" & type "%LOG%" & exit /b 5)
git ls-remote "%RELAY%" refs/heads/pc-out-relayproof1657 >"%P%\ls.txt" 2>>"%LOG%"
findstr /c:"refs/heads/pc-out-relayproof1657" "%P%\ls.txt" >nul 2>&1
if errorlevel 1 (echo FAILED step 3: GitHub has no pc-out-relayproof1657 after the push>>"%LOG%" & type "%LOG%" & exit /b 5)
type "%P%\ls.txt">>"%LOG%"
rem the tree itself, from the relay repo's own copy that relay_push just checked against GitHub
git --git-dir "%VT%\relay-mirror.git" ls-tree -r --name-only refs/heads/pc-out-relayproof1657 >"%P%\tree_B.txt" 2>>"%LOG%"
type "%P%\tree_B.txt">>"%LOG%"
findstr /x /c:"out_%ST%_1/done.txt" "%P%\tree_B.txt" >nul 2>&1
if errorlevel 1 (echo FAILED step 3: the pushed tree has no out_%ST%_1/done.txt>>"%LOG%" & type "%LOG%" & exit /b 5)
findstr /x /c:"out_%ST%_1/out_proof/proof.txt" "%P%\tree_B.txt" >nul 2>&1
if errorlevel 1 (echo FAILED step 3: the pushed tree has no out_%ST%_1/out_proof/proof.txt>>"%LOG%" & type "%LOG%" & exit /b 5)
echo step 3 PASS: the PC pushed to the relay repo and the pushed tree holds both files>>"%LOG%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%T%\prune_relay_branches.ps1" >>"%LOG%" 2>&1
if errorlevel 1 (echo FAILED step 4: prune dry run>>"%LOG%" & type "%LOG%" & exit /b 6)
echo step 4 PASS: prune dry list written under %VT%\prune\ ^(nothing deleted^)>>"%LOG%"
echo all done PASS>>"%LOG%"
type "%LOG%"
exit /b 0
