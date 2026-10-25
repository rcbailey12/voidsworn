# A2: portable Godot (standard build, not .NET) into Downloads\voidsworn_test\godot. Nothing installed system-wide.
# Asks GitHub for the latest stable godot-builds release and takes its win64 zip. Log: godot_setup_log.txt
$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'
$root = Split-Path -Parent $PSScriptRoot; if (-not (Test-Path "$root\watcher.bat")) { $root = "$env:USERPROFILE\Downloads\voidsworn_test" }
$dst = Join-Path $root 'godot'; $log = Join-Path $root 'godot_setup_log.txt'
"start $(Get-Date)" | Out-File $log
try {
  $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/godotengine/godot-builds/releases/latest' -Headers @{ 'User-Agent' = 'voidsworn' }
  $asset = $rel.assets | Where-Object { $_.name -match '_win64\.exe\.zip$' -and $_.name -notmatch 'mono' } | Select-Object -First 1
  "release $($rel.tag_name) asset $($asset.name) size $($asset.size)" | Out-File $log -Append
  New-Item -ItemType Directory -Force -Path $dst | Out-Null
  $zip = Join-Path $dst $asset.name
  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing
  Expand-Archive -Path $zip -DestinationPath $dst -Force
  Remove-Item $zip
  $exe = Get-ChildItem $dst -Filter 'Godot_*_win64.exe' | Where-Object { $_.Name -notmatch 'console' } | Select-Object -First 1
  $con = Get-ChildItem $dst -Filter 'Godot_*_console.exe' | Select-Object -First 1
  "exe $($exe.FullName)" | Out-File $log -Append; "console $($con.FullName)" | Out-File $log -Append
  "$($con.FullName)" | Out-File (Join-Path $root 'godot_path.txt') -Encoding ascii
  & $con.FullName --version 2>&1 | Out-File $log -Append
  "OK" | Out-File $log -Append
} catch { "FAILED $_" | Out-File $log -Append }
