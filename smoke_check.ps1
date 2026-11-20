param([string]$Report,[string]$Log,[string]$Since,[string]$Out)
$bad=@(); $since=[datetime]::Parse($Since)
if(-not (Test-Path $Report)){ $bad+="no smoke report at $Report" } else {
  $f=Get-Item $Report; if($f.LastWriteTime -lt $since){ $bad+="smoke report is stale ($($f.LastWriteTime.ToString('s')) before $($since.ToString('s')))" }
  $j=Get-Content $Report -Raw | ConvertFrom-Json
  if(@($j.runs).Count -ne 2){ $bad+="runs=$(@($j.runs).Count), expected 2" }
  if($j.errors -ne 0){ $bad+="errors=$($j.errors): $(@($j.runs | % { $_.errors }) -join ' | ')" }
  if($j.softlocks -ne 0){ $bad+="softlocks=$($j.softlocks)" }
  "smoke report $($f.LastWriteTime.ToString('s')): $($j.summary)" }
$hits=@(Select-String -Path $Log -Pattern 'SCRIPT ERROR|Parse Error' -SimpleMatch:$false)
if($hits.Count){ $bad+="$($hits.Count) SCRIPT ERROR / Parse Error lines in the export log, first: $($hits[0].Line.Trim())" }
if($bad.Count){ $lines=@('SMOKE CHECK FAILED') + $bad } else { $lines=@('SMOKE CHECK OK: fresh report, runs=2, errors=0, softlocks=0, no SCRIPT ERROR or Parse Error lines') }
$lines | Out-File -FilePath $Out -Encoding ascii -Append
if($bad.Count){ exit 1 } else { exit 0 }