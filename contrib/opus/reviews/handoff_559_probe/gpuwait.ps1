# Issue 559: wait until the GPU is free (utilisation under 15 percent on two checks in a row and no Blender running), up to 40 minutes.
param([string]$log)
$ok = 0
$deadline = (Get-Date).AddMinutes(40)
while ((Get-Date) -lt $deadline) {
  $u = 100
  try { $u = [int]((& nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits) | Select-Object -First 1) } catch {}
  $bl = @(Get-Process -Name blender -ErrorAction SilentlyContinue).Count
  Add-Content -Path $log -Value ("{0} gpu {1} blender {2}" -f (Get-Date -Format HH:mm:ss), $u, $bl)
  if ($u -lt 15 -and $bl -eq 0) { $ok++ } else { $ok = 0 }
  if ($ok -ge 2) { exit 0 }
  Start-Sleep -Seconds 20
}
exit 1
