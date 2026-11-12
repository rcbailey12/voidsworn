@echo off
rem Refs #230, Refs #520: capture the merged working tree, including uncommitted edits.
rem Usage: env230_motion.bat [repo] [shots folder] [resume run] [single]. No clone, reset, commit, push or deletion.
rem Copy built assets only, import headless, then run five variants sequentially on the RTX 5080.
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
for %%I in ("%~dp0..\..\..") do set "R=%%~fI"
if not "%~1"=="" set "R=%~1"
set "O=%VT%\board\issue-520\shots"
if not "%~2"=="" set "O=%~2"
set "L=%TEMP%\env230-520"
set /p G=<"%VT%\godot_path.txt"
if not exist "%L%" mkdir "%L%"
if not exist "%O%" mkdir "%O%"
if not exist "%R%\godot\world\world_shots.tscn" exit /b 2
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; if (Get-CimInstance Win32_Process | Where-Object { ($_.Name -like 'Godot*.exe' -and $_.CommandLine -notmatch '--headless') -or $_.Name -in @('blender.exe','ffmpeg.exe') }) { Write-Output 'GPU job already running; stop and wait'; exit 1 }"
if errorlevel 1 exit /b 3
nvidia-smi > "%L%\gpu_before.txt" 2>&1
set "TMO=%R%\tools\pc\tmo.bat"
git -C "%R%" rev-parse HEAD > "%L%\head.txt"
git -C "%R%" rev-parse MERGE_HEAD > "%L%\merged_main.txt" 2>nul
robocopy "%VT%\build\godot\gen" "%R%\godot\gen" /E /NP /NDL /R:1 /W:1 > "%L%\gencopy.txt" 2>&1
if errorlevel 8 exit /b 4
robocopy "%VT%\build\godot\assets\ships" "%R%\godot\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NP /NDL /R:1 /W:1 > "%L%\a4copy.txt" 2>&1
if errorlevel 8 exit /b 4
call "%TMO%" 2400 "%G%" --headless --path "%R%\godot" --import > "%L%\import.txt" 2>&1
if not "%ERRORLEVEL%"=="0" exit /b 5
findstr /C:"SCRIPT ERROR" /C:"SHADER ERROR" "%L%\import.txt" >nul
if not errorlevel 1 exit /b 5
set "CASES=boneyard_graveyard,nebula_storm,deep_storm,frontier_belt"
set "SHOTS=res://world/world_shots.tscn"
set "VS_TUMBLE="
set "VS_ROCK_TUMBLE="
set "VS_GAS_FLAT="
if /I "%~3"=="periods" goto periods
if /I "%~3"=="cap_rocks" goto cap_rocks
if /I "%~3"=="periods_rocks" goto periods_rocks
if /I "%~3"=="gas_flat" goto gas_flat
call :run shipped
if not "%ERRORLEVEL%"=="0" exit /b 6
if /I "%~4"=="single" exit /b 0
:periods
set "VS_TUMBLE=periods"
call :run periods
if not "%ERRORLEVEL%"=="0" exit /b 6
if /I "%~4"=="single" exit /b 0
:cap_rocks
set "VS_TUMBLE="
set "VS_ROCK_TUMBLE=1"
call :run cap_rocks
if not "%ERRORLEVEL%"=="0" exit /b 6
if /I "%~4"=="single" exit /b 0
:periods_rocks
set "VS_TUMBLE=periods"
set "VS_ROCK_TUMBLE=1"
call :run periods_rocks
if not "%ERRORLEVEL%"=="0" exit /b 6
if /I "%~4"=="single" exit /b 0
:gas_flat
set "VS_TUMBLE="
set "VS_ROCK_TUMBLE="
set "VS_GAS_FLAT=1"
call :run gas_flat "nebula_storm,deep_storm"
if not "%ERRORLEVEL%"=="0" exit /b 6
if /I "%~4"=="single" exit /b 0
echo all five runs complete
exit /b 0

:run
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; if (Get-CimInstance Win32_Process | Where-Object { ($_.Name -like 'Godot*.exe' -and $_.CommandLine -notmatch '--headless') -or $_.Name -in @('blender.exe','ffmpeg.exe') }) { Write-Output 'Another job is running; resume this run after it finishes'; exit 1 }"
if errorlevel 1 exit /b 1
set "ONLY=%CASES%"
if not "%~2"=="" set "ONLY=%~2"
if not exist "%O%\%~1" mkdir "%O%\%~1"
echo %~1 start %time%
call "%TMO%" 1500 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 %SHOTS% -- --out "%O%\%~1" --motion 30 --every 5 --tag %~1 --only %ONLY% > "%L%\%~1.txt" 2>&1
if not "%ERRORLEVEL%"=="0" exit /b 1
findstr /C:"SCRIPT ERROR" /C:"SHADER ERROR" /C:"placeholder hull:" "%L%\%~1.txt" >nul
if not errorlevel 1 exit /b 1
findstr /L /C:"[world_shots] done" "%L%\%~1.txt" >nul
if errorlevel 1 exit /b 1
rem Give every image its case, run and view name, with a 720 px height ceiling. No source asset is changed.
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; Add-Type -AssemblyName System.Drawing; $files=@(Get-ChildItem -LiteralPath '%O%\%~1' -Filter '*.jpg'); if ($files.Count -eq 0) { throw 'No captures written' }; foreach ($f in $files) { $im=[Drawing.Image]::FromFile($f.FullName); $s=[Math]::Min(1.0,684/$im.Height); $w=[int]($im.Width*$s); $h=[int]($im.Height*$s); $bmp=New-Object Drawing.Bitmap($w,($h+36)); $g=[Drawing.Graphics]::FromImage($bmp); $g.Clear([Drawing.Color]::FromArgb(15,18,25)); $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic; $g.DrawImage($im,0,36,$w,$h); $font=New-Object Drawing.Font('Consolas',12); $g.DrawString($f.BaseName,$font,[Drawing.Brushes]::White,8,8); $im.Dispose(); $g.Dispose(); $font.Dispose(); $bmp.Save($f.FullName,[Drawing.Imaging.ImageFormat]::Jpeg); $bmp.Dispose() }"
if errorlevel 1 exit /b 1
echo %~1 done %time%
exit /b 0
