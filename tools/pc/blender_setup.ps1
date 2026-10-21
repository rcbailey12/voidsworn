# Voidsworn: portable Blender 4.5 LTS (no installer, no admin) into Downloads\voidsworn_test\blender
$ErrorActionPreference = 'Stop'
$root = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$log = Join-Path $root 'blender_setup_log.txt'
"start $(Get-Date)" | Out-File -Encoding utf8 $log
try {
  $mirrors = @('https://mirrors.ocf.berkeley.edu/blender/release/Blender4.5/','https://ftp.halifax.rwth-aachen.de/blender/release/Blender4.5/','https://mirror.clarkson.edu/blender/release/Blender4.5/','https://download.blender.org/release/Blender4.5/')
  $base = $null; $p = $null
  foreach ($u in $mirrors) {
    try { $idx = (& curl.exe -L -sS -A 'Mozilla/5.0' $u) -join "`n"
      $m = [regex]::Matches($idx, 'blender-4\.5\.(\d+)-windows-x64\.zip') | ForEach-Object { [int]$_.Groups[1].Value }
      if ($m.Count -gt 0) { $p = ($m | Measure-Object -Maximum).Maximum; $base = $u; break } else { "no listing at $u" | Out-File -Encoding utf8 $log -Append } } catch { "mirror failed $u $_" | Out-File -Encoding utf8 $log -Append } }
  if (-not $base) { throw 'no mirror listing' }
  $name = "blender-4.5.$p-windows-x64.zip"; "picked $name from $base" | Out-File -Encoding utf8 $log -Append
  $zip = Join-Path $root $name
  if (-not (Test-Path $zip) -or (Get-Item $zip).Length -lt 100MB) { & curl.exe -L -sS -A 'Mozilla/5.0' -o $zip ($base + $name) }
  "downloaded $((Get-Item $zip).Length)" | Out-File -Encoding utf8 $log -Append
  $dst = Join-Path $root 'blender'; if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
  New-Item -ItemType Directory $dst | Out-Null
  & tar.exe -xf $zip -C $dst
  $exe = Get-ChildItem -Recurse -Filter blender.exe $dst | Select-Object -First 1
  $exe.FullName | Out-File (Join-Path $root 'blender_path.txt') -Encoding ascii
  & $exe.FullName -b --factory-startup --python-expr "import bpy,sys; p=bpy.context.preferences.addons['cycles'].preferences; p.compute_device_type='OPTIX'; p.get_devices(); print('BLENDER OK', bpy.app.version_string, [d.name for d in p.devices if d.type=='OPTIX'])" 2>&1 | Out-File -Encoding utf8 $log -Append
  Remove-Item $zip
  "DONE $(Get-Date)" | Out-File -Encoding utf8 $log -Append
} catch { "FAILED $_" | Out-File -Encoding utf8 $log -Append }
