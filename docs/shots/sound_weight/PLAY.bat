@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='%~dp0'; $files=@('before\cruiser_death.wav','after\cruiser_death.wav','before\capital_death.wav','after\capital_death.wav','before\lance_shot.wav','after\lance_shot.wav','before\shield_break.wav','after\shield_break.wav'); foreach($f in $files){ Write-Host ('Playing ' + $f); (New-Object Media.SoundPlayer (Join-Path $p $f)).PlaySync() }"
echo Done.
pause
