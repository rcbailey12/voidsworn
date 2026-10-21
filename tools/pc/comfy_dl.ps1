# Download + unpack ComfyUI portable (NVIDIA) and the models for: Qwen-Image-Edit 2511 views (multiple-angles LoRA) and Pixal3D multi-view.
# Owner OK'd the full set (~44 GB) Oct 21. Resumable (curl -C -): rerun to continue. Log: Downloads\voidsworn_test\comfy_dl.log
$ErrorActionPreference = 'Continue'; $ProgressPreference = 'SilentlyContinue'
$dl = Join-Path $env:USERPROFILE 'Downloads'; $log = Join-Path $dl 'voidsworn_test\comfy_dl.log'
function L($m){ Add-Content -Path $log -Value ((Get-Date).ToString('HH:mm:ss') + ' ' + $m) }
$root = Join-Path $dl 'ComfyUI_windows_portable'; $zip = Join-Path $dl 'ComfyUI_windows_portable_nvidia.7z'
function Get1($url, $out, $gb) {
  if ((Test-Path $out) -and ((Get-Item $out).Length -ge $gb * 1GB * 0.995)) { L ("have " + (Split-Path $out -Leaf)); return $true }
  $d = Split-Path $out; if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
  $t = Get-Date; L ("get " + (Split-Path $out -Leaf) + " (" + $gb + " GB)")
  for ($k = 0; $k -lt 4; $k++) { & curl.exe -L -s -S --retry 5 --retry-delay 5 -C - -o $out $url 2>&1 | ForEach-Object { L ("  curl " + $_) }; if ((Test-Path $out) -and ((Get-Item $out).Length -ge $gb * 1GB * 0.995)) { break } }
  $s = (Get-Date) - $t; $sz = if (Test-Path $out) { (Get-Item $out).Length } else { 0 }
  L ("  " + [math]::Round($sz/1GB,2) + " GB in " + [math]::Round($s.TotalMinutes,1) + " min (" + [math]::Round($sz/1MB/[math]::Max($s.TotalSeconds,1),1) + " MB/s)")
  return ($sz -ge $gb * 1GB * 0.995)
}
try {
  L ("start, disk free GB " + [math]::Round((Get-PSDrive C).Free/1GB,1))
  if (-not (Test-Path (Join-Path $root 'run_nvidia_gpu.bat'))) {
    if (Get1 'https://github.com/Comfy-Org/ComfyUI/releases/download/v0.42.1/ComfyUI_windows_portable_nvidia.7z' $zip 1.79) {
      L 'unpacking'; & tar -xf $zip -C $dl 2>&1 | ForEach-Object { L ("  tar " + $_) }
      if (-not (Test-Path (Join-Path $root 'run_nvidia_gpu.bat'))) {
        L 'tar could not unpack, using 7zr'; $z7 = Join-Path $dl '7zr.exe'; Get1 'https://www.7-zip.org/a/7zr.exe' $z7 0.0004 | Out-Null
        & $z7 x $zip ("-o" + $dl) -y 2>&1 | Select-Object -Last 3 | ForEach-Object { L ("  7zr " + $_) } }
      L ("unpacked: " + (Test-Path (Join-Path $root 'run_nvidia_gpu.bat')))
    }
  } else { L 'ComfyUI already unpacked' }
  $m = Join-Path $root 'ComfyUI\models'; $hf = 'https://huggingface.co'
  $files = @(
    @("$hf/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors", 'vae\qwen_image_vae.safetensors', 0.24),
    @("$hf/fal/Qwen-Image-Edit-2511-Multiple-Angles-LoRA/resolve/main/qwen-image-edit-2511-multiple-angles-lora.safetensors", 'loras\qwen-image-edit-2511-multiple-angles-lora.safetensors', 0.27),
    @("$hf/lightx2v/Qwen-Image-Edit-2511-Lightning/resolve/main/Qwen-Image-Edit-2511-Lightning-8steps-V1.0-bf16.safetensors", 'loras\Qwen-Image-Edit-2511-Lightning-8steps-V1.0-bf16.safetensors', 0.79),
    @("$hf/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors", 'text_encoders\qwen_2.5_vl_7b_fp8_scaled.safetensors', 8.74),
    @("$hf/Comfy-Org/Qwen-Image-Edit_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors", 'diffusion_models\qwen_image_edit_2511_fp8mixed.safetensors', 19.12),
    @("$hf/Comfy-Org/Pixal3D/resolve/main/clip_vision/dino_v3_L_naf_fp32.safetensors", 'clip_vision\dino_v3_L_naf_fp32.safetensors', 1.13),
    @("$hf/Comfy-Org/Pixal3D/resolve/main/vae/trellis_2_shape_vae_bf16.safetensors", 'vae\trellis_2_shape_vae_bf16.safetensors', 1.02),
    @("$hf/Comfy-Org/Pixal3D/resolve/main/vae/trellis_2_texture_vae_bf16.safetensors", 'vae\trellis_2_texture_vae_bf16.safetensors', 0.88),
    @("$hf/Comfy-Org/Pixal3D/resolve/main/diffusion_models/pixal3d_multiview_bf16.safetensors", 'diffusion_models\pixal3d_multiview_bf16.safetensors', 10.24)
  )
  $ok = $true
  foreach ($f in $files) { if (-not (Get1 $f[0] (Join-Path $m $f[1]) $f[2])) { $ok = $false; L ("MISSING " + $f[1]) } }
  L ("disk free GB " + [math]::Round((Get-PSDrive C).Free/1GB,1))
  if ($ok) { L 'COMFY DL DONE' } else { L 'COMFY DL INCOMPLETE (rerun to resume)' }
} catch { L ("FAILED " + $_.Exception.Message) }
