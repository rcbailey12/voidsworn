# Issue 362: wait until the GPU is free (utilisation under 15 percent on two checks in a row, no Blender running), up to 90
# minutes. Exit 0 when free, 1 when it never was. Logs every check.
param([string]$log, [int]$minutes = 90)
$ok = 0
$deadline = (Get-Date).AddMinutes($minutes)
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
