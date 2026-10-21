# List (no download) the exact files and sizes for the Pixal3D multi-view + Qwen-Image-Edit views setup, plus free disk space.
# Log: Downloads\voidsworn_test\comfy_probe.log
$ErrorActionPreference = 'Continue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$dl = Join-Path $env:USERPROFILE 'Downloads'; $log = Join-Path $dl 'voidsworn_test\comfy_probe.log'
if (Test-Path $log) { Remove-Item $log }
function L($m){ Add-Content -Path $log -Value $m }
$H = @{ 'User-Agent' = 'voidsworn' }
L ("disk free C: GB " + [math]::Round((Get-PSDrive C).Free/1GB,1))
L ("ram GB " + [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1))
try { $g = (& nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader) -join ' '; L ("gpu " + $g) } catch { L 'gpu ?' }
try { $v = & tar --version; L ("tar " + ($v -join ' ')) } catch { L 'tar ?' }
foreach ($rp in @('Comfy-Org/ComfyUI','comfyanonymous/ComfyUI')) {
  try { $r = Invoke-RestMethod -Uri "https://api.github.com/repos/$rp/releases/latest" -Headers $H
    L ("== github $rp " + $r.tag_name + " " + $r.published_at)
    foreach($a in $r.assets){ L ("  " + $a.name + " | " + [math]::Round($a.size/1MB,1) + " MB | " + $a.browser_download_url) } } catch { L ("== github $rp FAILED " + $_.Exception.Message) }
}
function Tree($repo, $path) {
  $u = "https://huggingface.co/api/models/$repo/tree/main" + ($(if($path){"/$path"}else{""})) + "?recursive=true"
  try { $t = Invoke-RestMethod -Uri $u -Headers $H
    foreach($f in $t){ if($f.type -eq 'file'){ $s = if($f.lfs){ $f.lfs.size } else { $f.size }; if($s -gt 5MB -or $f.path -like '*.json'){ L ("  " + $f.path + " | " + [math]::Round($s/1GB,2) + " GB") } } } } catch { L ("  FAILED " + $_.Exception.Message) }
}
foreach ($x in @(
  @('Comfy-Org/Pixal3D',''),
  @('Comfy-Org/Qwen-Image-Edit_ComfyUI','split_files'),
  @('Comfy-Org/Qwen-Image_ComfyUI','split_files'),
  @('fal/Qwen-Image-Edit-2511-Multiple-Angles-LoRA',''),
  @('lightx2v/Qwen-Image-Edit-2511-Lightning',''),
  @('QuantStack/Qwen-Image-Edit-2511-GGUF',''),
  @('unsloth/Qwen-Image-Edit-2511-GGUF',''),
  @('TencentARC/Pixal3D','')
)) { L ("== hf " + $x[0] + " " + $x[1]); Tree $x[0] $x[1] }
L 'PROBE DONE'
