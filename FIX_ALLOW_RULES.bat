@echo off
rem FIX_ALLOW_RULES.bat (issue 1750, R417). Ryan double-clicks once. Splits the joined allow rule that
rem ALLOW_NODELETE_INSTALLS.bat wrote into two entries. Keeps a copy of the old file. Deletes nothing.
setlocal
set "F=%USERPROFILE%\.claude\settings.json"
set "PS1=%TEMP%\fix_allow_1750.ps1"
> "%PS1%" echo $f = Join-Path $env:USERPROFILE '.claude\settings.json'
>>"%PS1%" echo if (Test-Path -LiteralPath $f) { Copy-Item -LiteralPath $f -Destination ($f + '.before_fix_1750') -Force }
>>"%PS1%" echo $p = ($env:USERPROFILE + '\Downloads\voidsworn_test\tools_live\*\pc\lane_tools_refresh.ps1').Replace('\', '\\')
>>"%PS1%" echo $c = 'powershell -NoProfile -ExecutionPolicy Bypass -File ' + $p + ' -Build * -NoRotate'
>>"%PS1%" echo $t = '{' + "`r`n" + '  "permissions": {' + "`r`n" + '    "allow": [' + "`r`n" + '      "Bash(' + $c + ')",' + "`r`n" + '      "PowerShell(' + $c + ')"' + "`r`n" + '    ]' + "`r`n" + '  }' + "`r`n" + '}' + "`r`n"
>>"%PS1%" echo [IO.File]::WriteAllText($f, $t, (New-Object Text.UTF8Encoding($false)))
>>"%PS1%" echo $null = Get-Content -LiteralPath $f -Raw ^| ConvertFrom-Json
>>"%PS1%" echo Get-Content -LiteralPath $f
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
if errorlevel 1 (echo FAILED & pause & exit /b 1)
echo.
echo Done: two allow rules written. You can close this window.
pause
exit /b 0
