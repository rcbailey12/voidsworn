# Issue 1439: acceptance check for summarize.ps1 before the measured run (Artoo, PR 1442). The fixture has the game
# (pid 4242), another Godot process with larger numbers (pid 999) and one unreadable sample. Pass: only 4242 counts
# (dedicated 1,500, shared 130), the unreadable sample is reported unavailable, pid 999 is ignored. Writes nothing
# outside a new folder under TEMP.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('perf1439-selftest-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
Copy-Item -Path (Join-Path $here 'fixture\*') -Destination $tmp
& (Join-Path $here 'summarize.ps1') -Run $tmp | Out-Null
$txt = Get-Content -LiteralPath (Join-Path $tmp 'summary.txt') -Raw
$want = @('game process 4242, 2 samples read, 1 unavailable, 2 from other processes ignored', 'First drawn title: 900 ms after engine start; 900 ms after the bat launched the exe')
$bad = @($want | Where-Object { $txt.IndexOf($_) -lt 0 })
$line = @($txt -split "`r?`n" | Where-Object { $_ -like 'title *' })
if (-not $line.Count -or $line[0] -notmatch '1,500\s+130\s*$') { $bad += 'title row should end with 1,500 and 130' }
if ($line.Count -and $line[0] -match '9,') { $bad += 'title row used the other process' }
if ($bad.Count) { Write-Output ('SELFTEST FAIL: ' + ($bad -join '; ')); Write-Output $txt; exit 1 }
Write-Output 'SELFTEST OK'
Write-Output $txt
