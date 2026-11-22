@echo off
rem ALLOW_NODELETE_INSTALLS.bat (issue 1750, R417). Ryan double-clicks this once. Deletes nothing.
rem  1. Adds two narrow allow rules to Claude Code's user settings (C:\Users\<you>\.claude\settings.json) so the PC
rem     Claude can run exactly one command without asking: main's lane_tools_refresh.ps1 from tools_live with -NoRotate,
rem     which installs or refreshes tools and never deletes anything. Any other command still asks as before.
rem     An existing settings.json is copied to settings.json.before_1750 first (nothing is removed from it).
rem  2. Installs the latest tools_live from main the same no-delete way, so the waiting upload fix lands now.
setlocal EnableExtensions
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "LOG=%VT%\allow_nodelete_1750.txt"
set "PS1=%TEMP%\allow_nodelete_1750.ps1"
> "%PS1%" echo $ErrorActionPreference = 'Stop'
>>"%PS1%" echo $dir = Join-Path $env:USERPROFILE '.claude'; $null = [IO.Directory]::CreateDirectory($dir)
>>"%PS1%" echo $f = Join-Path $dir 'settings.json'
>>"%PS1%" echo $cmd = 'powershell -NoProfile -ExecutionPolicy Bypass -File ' + $env:USERPROFILE + '\Downloads\voidsworn_test\tools_live\*\pc\lane_tools_refresh.ps1 -Build * -NoRotate'
>>"%PS1%" echo $rules = @('Bash(' + $cmd + ')', 'PowerShell(' + $cmd + ')')
>>"%PS1%" echo if (Test-Path -LiteralPath $f) { Copy-Item -LiteralPath $f -Destination ($f + '.before_1750') -Force; $j = Get-Content -LiteralPath $f -Raw ^| ConvertFrom-Json } else { $j = New-Object PSObject }
>>"%PS1%" echo if (-not $j.PSObject.Properties['permissions']) { $j ^| Add-Member -NotePropertyName permissions -NotePropertyValue (New-Object PSObject) }
>>"%PS1%" echo if (-not $j.permissions.PSObject.Properties['allow']) { $j.permissions ^| Add-Member -NotePropertyName allow -NotePropertyValue @() }
>>"%PS1%" echo $allow = @($j.permissions.allow); foreach ($r in $rules) { if ($allow -notcontains $r) { $allow += $r } }; $j.permissions.allow = $allow
>>"%PS1%" echo [IO.File]::WriteAllText($f, ($j ^| ConvertTo-Json -Depth 20), (New-Object Text.UTF8Encoding($false)))
>>"%PS1%" echo Write-Host ('allow rules written to ' + $f); Get-Content -LiteralPath $f
echo step 1: allow rules>"%LOG%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" >>"%LOG%" 2>&1
if errorlevel 1 (echo FAILED step 1>>"%LOG%" & type "%LOG%" & pause & exit /b 1)
echo step 2: latest tools_live from main, no rotation>>"%LOG%"
set "BOOT=%TEMP%\vsboot_1750_%RANDOM%%RANDOM%"
git clone -q --depth 1 --filter=blob:none --no-checkout https://github.com/rcbailey12/voidsworn "%BOOT%" >>"%LOG%" 2>&1
if errorlevel 1 (echo FAILED step 2: could not reach GitHub>>"%LOG%" & type "%LOG%" & pause & exit /b 2)
git -C "%BOOT%" show HEAD:tools/pc/lane_tools_refresh.ps1 > "%TEMP%\lane_tools_refresh_1750.ps1" 2>>"%LOG%"
findstr /c:"NoRotate" "%TEMP%\lane_tools_refresh_1750.ps1" >nul 2>&1
if errorlevel 1 (echo FAILED step 2: main has no -NoRotate yet ^(PR 1751 not merged^)>>"%LOG%" & type "%LOG%" & pause & exit /b 3)
powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\lane_tools_refresh_1750.ps1" -Build tools_live -NoRotate >>"%LOG%" 2>&1
if errorlevel 1 (echo FAILED step 2: install>>"%LOG%" & type "%LOG%" & pause & exit /b 4)
echo all done PASS>>"%LOG%"
type "%LOG%"
echo.
echo Done. You can close this window.
pause
exit /b 0
