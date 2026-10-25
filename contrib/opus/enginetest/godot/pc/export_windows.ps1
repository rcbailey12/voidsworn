# A2: export the Godot engine test as a standalone Windows .exe and measure its size and cold start.
# Needs the official 4.7.2 export templates (downloaded once from the Godot release page on GitHub, about 1 GB).
# PowerShell 5.1. Log: enginetest\build\export_log.txt
$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'
$root = "$env:USERPROFILE\Downloads\voidsworn_test"
$G = "$root\godot\Godot_v4.7.2-stable_win64_console.exe"
$et = "$root\enginetest"
$build = "$et\build"
New-Item -ItemType Directory -Force -Path $build | Out-Null
New-Item -ItemType Directory -Force -Path "$et\results" | Out-Null
$log = "$build\export_log.txt"
"start $(Get-Date)" | Out-File $log
try {
  $tdir = "$env:APPDATA\Godot\export_templates\4.7.2.stable"
  if (-not (Test-Path "$tdir\windows_release_x86_64.exe")) {
    $tpz = "$root\godot\Godot_v4.7.2-stable_export_templates.tpz"
    if (-not (Test-Path $tpz)) {
      Invoke-WebRequest -Uri 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz' -OutFile $tpz -UseBasicParsing
    }
    $zip = "$root\godot\templates_4.7.2.zip"
    Copy-Item $tpz $zip -Force
    Expand-Archive -Path $zip -DestinationPath "$root\godot\tpl" -Force
    New-Item -ItemType Directory -Force -Path $tdir | Out-Null
    Copy-Item "$root\godot\tpl\templates\*" $tdir -Force
    Remove-Item $zip
    "templates installed in $tdir" | Out-File $log -Append
  }
  Set-Location $et
  & $G --headless --path godot --export-release "Windows Desktop" "$build\VoidswornEngineTest.exe" 2>&1 | Out-File $log -Append
  $exe = Get-Item "$build\VoidswornEngineTest.exe"
  $size = (Get-ChildItem $build -Filter 'VoidswornEngineTest*' | Measure-Object -Property Length -Sum).Sum
  "exe_bytes $($exe.Length)  all_files_bytes $size" | Out-File $log -Append
  # cold start: first run after export (load_s in the JSON is engine start to the first full frame), then a warm run
  $sw = [Diagnostics.Stopwatch]::StartNew()
  & "$build\VoidswornEngineTest.console.exe" --rendering-method forward_plus --resolution 2560x1440 --disable-vsync -- --bench ../results/godot_exe_cold.json --seconds 5 --res 2560x1440 2>&1 | Out-File $log -Append
  "cold run wall seconds $($sw.Elapsed.TotalSeconds)" | Out-File $log -Append
  & "$build\VoidswornEngineTest.console.exe" --rendering-method forward_plus --resolution 2560x1440 --disable-vsync -- --bench ../results/godot_exe_warm.json --seconds 5 --res 2560x1440 2>&1 | Out-File $log -Append
  "OK" | Out-File $log -Append
} catch { "FAILED $_" | Out-File $log -Append }
