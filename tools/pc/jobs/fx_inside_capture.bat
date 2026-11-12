@echo off
setlocal
rem Run from Downloads\voidsworn_test\build: fx_inside_capture.bat tag
rem fx_tag.zip must contain godot/fx. Old files are moved, never deleted.
set "FX_TAG=%~1"
if not defined FX_TAG goto usage
if not "%~2"=="" goto usage
powershell -NoProfile -Command "if ($env:FX_TAG -notmatch '^[A-Za-z0-9_-]+$') { exit 2 }"
if errorlevel 1 goto usage
cd /d "%USERPROFILE%\Downloads\voidsworn_test\build"
if errorlevel 1 exit /b 2
if not exist "fx_%FX_TAG%.zip" goto missing
if exist "..\sync_old\fx_%FX_TAG%" goto exists
if not exist "godot\fx" goto missing
set "FX_GODOT="
for /f "usebackq delims=" %%G in ("..\godot_path.txt") do set "FX_GODOT=%%G"
if not defined FX_GODOT goto missing
set "FX_GODOT=%FX_GODOT:_console.exe=.exe%"
if not exist "%FX_GODOT%" goto missing
if not exist "tools\pc\tmo.bat" goto missing
rem Reject archives outside godot/fx before moving anything. No shell metacharacters in arguments.
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; Add-Type -AssemblyName System.IO.Compression.FileSystem; $zip=[IO.Compression.ZipFile]::OpenRead((Join-Path $PWD ('fx_'+$env:FX_TAG+'.zip'))); try { $found=$false; foreach ($e in $zip.Entries) { $n=$e.FullName.Replace('\','/'); if ($n.StartsWith('/') -or $n -match '^[A-Za-z]:' -or $n.Split('/') -contains '..') { throw 'Unsafe archive path' }; if ($n -ne 'godot/' -and $n -ne 'godot/fx/' -and -not $n.StartsWith('godot/fx/')) { throw 'Archive must contain only godot/fx' }; if ($n -eq 'godot/fx/test/fx_inside_probe.gd') { $found=$true } }; if (-not $found) { throw 'Archive has no inside probe' } } finally { $zip.Dispose() }; $base=[IO.Path]::GetFullPath([string]$PWD); $source=(Resolve-Path -LiteralPath 'godot\fx').Path; if ($source -ne (Join-Path $base 'godot\fx')) { throw 'Unexpected fx source path' }; $backup=[IO.Path]::GetFullPath((Join-Path $base ('..\sync_old\fx_'+$env:FX_TAG))); $parent=[IO.Path]::GetFullPath((Join-Path $base '..\sync_old')); if ([IO.Path]::GetDirectoryName($backup) -ne $parent) { throw 'Unexpected backup path' }; New-Item -ItemType Directory -Force -Path $parent -ErrorAction Stop; Move-Item -LiteralPath $source -Destination $backup -ErrorAction Stop; Expand-Archive -LiteralPath ('fx_'+$env:FX_TAG+'.zip') -DestinationPath $base -Force"
if errorlevel 1 goto failed
set "PROBE_BOX="
set "PROBE_SHIPS=corsair:Battle-barge,hegemony:Super-dreadnought,voidsworn:Frigate"
set "PROBE_OUT=..\shots\fx_%FX_TAG%"
if not exist "%PROBE_OUT%" mkdir "%PROBE_OUT%"
call tools\pc\tmo.bat 600 "%FX_GODOT%" --path godot --fixed-fps 60 --script res://fx/test/fx_inside_probe.gd --log-file "%PROBE_OUT%\probe.log"
exit /b %ERRORLEVEL%
:usage
echo Usage: fx_inside_capture.bat tag
echo Use letters, numbers, underscores or hyphens, with no spaces.
exit /b 2
:missing
echo FAIL: missing archive, godot\fx, or Godot executable/path file.
exit /b 2
:exists
echo FAIL: backup already exists. Use a fresh tag to preserve it.
exit /b 2
:failed
echo FAIL: archive validation, backup, or extraction failed. Any old fx remains in sync_old.
exit /b 2
