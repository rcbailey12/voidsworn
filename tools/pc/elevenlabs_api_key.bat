@echo off
setlocal
rem Issue 1585 (Artoo and Neon on PR 1577): the key is typed into a hidden PowerShell prompt and saved as a Windows
rem user setting by that same PowerShell process. It is never shown, never put on a command line, never in a file.
rem   ELEVENLABS_API_KEY.bat            Ryan's normal use: paste the key, press Enter.
rem   ELEVENLABS_API_KEY.bat /selftest  Board check with a dummy value under a separate _SELFTEST name, removed after.
title Save your ElevenLabs API key for the sound jobs
if /I not "%~1"=="/selftest" (
  echo.
  echo  Saves the API key from elevenlabs.io ^(Settings, API keys^) for the sound jobs on this PC,
  echo  as a user setting named VOIDSWORN_ELEVENLABS_API_KEY. Typing stays hidden.
  echo  Tip: when you make the key, allow only Sound Effects and Music, and set a credit cap.
  echo  To paste: right-click in this window, then press Enter.
  echo.
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { param($mode) $n = 'VOIDSWORN_ELEVENLABS_API_KEY'; $dummy = 'dummy-not-a-key-1585'; if ($mode -eq '/selftest') { $n = $n + '_SELFTEST'; $s = ConvertTo-SecureString $dummy -AsPlainText -Force } else { $s = Read-Host '  ElevenLabs API key (hidden)' -AsSecureString }; if ($s.Length -eq 0) { Write-Host '  Nothing pasted, nothing saved.'; exit 1 }; $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s); try { $v = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b).Trim(); [Environment]::SetEnvironmentVariable($n, $v, 'User'); $v = $null } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) }; if ($mode -eq '/selftest') { $read = (Get-ItemProperty -Path 'HKCU:\Environment' -Name $n -ErrorAction SilentlyContinue).$n; $ok = ($read -eq $dummy); [Environment]::SetEnvironmentVariable($n, $null, 'User'); $gone = -not (Get-ItemProperty -Path 'HKCU:\Environment' -Name $n -ErrorAction SilentlyContinue); if ($ok -and $gone) { Write-Host 'KEY BAT SELFTEST PASS'; exit 0 } else { Write-Host ('KEY BAT SELFTEST FAIL: saved=' + $ok + ' removed=' + $gone); exit 1 } }; Write-Host '  Saved. You can close this window. The Board takes it from here.'; exit 0 }" "%~1"
set "RC=%ERRORLEVEL%"
if /I not "%~1"=="/selftest" pause
exit /b %RC%
