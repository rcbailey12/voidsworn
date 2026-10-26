# Fetch the Z-Image Turbo files for ComfyUI portable (Apache 2.0, Tongyi-MAI), skipping files already there.
# Log: Downloads\voidsworn_test\portraits\portrait_dl.log
$ErrorActionPreference = 'Continue'; $ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$dl = Join-Path $env:USERPROFILE 'Downloads'; $m = Join-Path $dl 'ComfyUI_windows_portable\ComfyUI\models'
$logdir = Join-Path $dl 'voidsworn_test\portraits'; if (-not (Test-Path $logdir)) { New-Item -ItemType Directory $logdir | Out-Null }
$log = Join-Path $logdir 'portrait_dl.log'
function L($s){ $t = (Get-Date -Format 'HH:mm:ss') + ' ' + $s; Write-Output $t; Add-Content -Path $log -Value $t }
$base = 'https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files'
$files = @(
  @("$base/diffusion_models/z_image_turbo_bf16.safetensors", 'diffusion_models\z_image_turbo_bf16.safetensors', 10GB),
  @("$base/text_encoders/qwen_3_4b.safetensors", 'text_encoders\qwen_3_4b.safetensors', 6GB),
  @("$base/vae/ae.safetensors", 'vae\ae.safetensors', 300MB)
)
L ("disk free C: GB " + [math]::Round((Get-PSDrive C).Free/1GB,1))
foreach ($f in $files) {
  $dst = Join-Path $m $f[1]
  if ((Test-Path $dst) -and ((Get-Item $dst).Length -gt $f[2])) { L ("have " + $f[1] + " " + [math]::Round((Get-Item $dst).Length/1GB,2) + " GB"); continue }
  $dir = Split-Path $dst; if (-not (Test-Path $dir)) { New-Item -ItemType Directory $dir | Out-Null }
  $tmp = $dst + '.part'; $t = Get-Date
  # Lane A (pt_b1) and lane B (pt_dl) both call this script: if the other copy is writing the .part right now
  # (exclusive open fails), wait for it to finish instead of fighting over the file.
  $waited = 0
  while ((Test-Path $tmp) -and $waited -lt 2400) {
    try { $h = [IO.File]::Open($tmp, 'Open', 'ReadWrite', 'None'); $h.Close(); break }
    catch { if ($waited -eq 0) { L ("another download is writing " + $f[1] + ", waiting") }; Start-Sleep -Seconds 20; $waited += 20 }
  }
  if ((Test-Path $dst) -and ((Get-Item $dst).Length -gt $f[2])) { L ("have " + $f[1] + " after waiting " + $waited + " s"); continue }
  if (Test-Path $tmp) { Remove-Item -Force $tmp }
  L ("get " + $f[0])
  try { Invoke-WebRequest -Uri $f[0] -OutFile $tmp -UseBasicParsing -Headers @{ 'User-Agent' = 'voidsworn' }
        Move-Item -Force $tmp $dst
        L ("  ok " + [math]::Round((Get-Item $dst).Length/1GB,2) + " GB in " + [math]::Round(((Get-Date)-$t).TotalMinutes,1) + " min") }
  catch { L ("  FAILED " + $_.Exception.Message) }
}
L 'PORTRAIT DL DONE'
