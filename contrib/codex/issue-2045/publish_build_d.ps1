param([switch]$Plan, [Parameter(Mandatory=$true)][string]$Repo, [string]$Bench, [string]$Shots)

$ErrorActionPreference = 'Stop'
$cfgPath = Join-Path $Repo 'godot\bench\look_moments_build_d.json'
$cfgText = Get-Content -LiteralPath $cfgPath -Raw
$cfg = $cfgText | ConvertFrom-Json
$cameras = @(170, 26)
if (($cfg.cameras -join ',') -ne '170,26') { throw 'Build D needs cameras 170 and 26 in that order' }
$rows = @($cfg.rows)
if ($rows.Count -eq 0 -or @($rows.id | Select-Object -Unique).Count -ne $rows.Count) { throw 'Missing or repeated Build D rows' }
if ($Plan) {
    Write-Output ('Build D plan: {0} comparison pictures, with three moments per camera' -f $rows.Count)
    $rows | Group-Object event | ForEach-Object { Write-Output ('  {0}: {1}' -f $_.Name, $_.Count) }
    return
}

function CheckedSha([string]$Checkout) {
    $sha = & git -C $Checkout rev-parse --short=8 HEAD
    if ($LASTEXITCODE -ne 0 -or "$sha" -notmatch '^[0-9a-f]{8,40}$') { throw "No bench revision in $Checkout" }
    return $sha
}

$after = CheckedSha (Join-Path $Bench 'tool')
$before = CheckedSha (Join-Path $Bench 'repo')
$runs = Join-Path $Bench 'runs'
foreach ($ref in @(@{sha=$after; kit='shared'}, @{sha=$before; kit='legacy'})) {
    $run = Join-Path $runs $ref.sha
    $shotCfg = Get-Content -LiteralPath (Join-Path $run 'moments.json') -Raw
    if (($shotCfg -replace "`r`n", "`n").Trim() -cne ($cfgText -replace "`r`n", "`n").Trim()) {
        throw "Bench rows in $run do not match the launcher. Use the same checkout as AFTER."
    }
    $report = Get-Content -LiteralPath (Join-Path $run 'bench.json') -Raw | ConvertFrom-Json
    if ($report.commit -ne $ref.sha -or $report.build_d -ne $ref.kit) { throw "Wrong Build D revision or kit in $run" }
    if (Select-String -LiteralPath (Join-Path $run 'bench_log.txt') -SimpleMatch -Quiet -Pattern 'SCRIPT ERROR', 'SHADER ERROR', 'CODE MISMATCH') {
        throw "Godot or hull error in $run"
    }
    $indexed = @{}
    foreach ($still in $report.stills) { $indexed[('{0}/{1}' -f $still.id, $still.cam)] = $still }
    foreach ($row in $rows) {
        foreach ($cam in $cameras) {
            $key = '{0}/{1}' -f $row.id, $cam
            if (-not $indexed.ContainsKey($key) -or $indexed[$key].cells.Count -ne 3) { throw "Missing frames for $key in $run" }
        }
    }
}

$source = Join-Path $Bench ("sheets\${before}_vs_${after}\moments")
Add-Type -AssemblyName System.Drawing
$files = @()
foreach ($row in $rows) {
    $jpg = Join-Path $source ($row.id + '.jpg')
    $sidecar = $jpg + '.provenance.json'
    $image = [System.Drawing.Image]::FromFile($jpg)
    try {
        if ($image.Height -gt 720) { throw "Review picture is too tall: $jpg" }
    } finally { $image.Dispose() }
    if (-not (Test-Path -LiteralPath $sidecar -PathType Leaf)) { throw "Missing picture provenance: $sidecar" }
    $stamp = Get-Content -LiteralPath $sidecar -Raw | ConvertFrom-Json
    if (-not ($stamp.sources.source_commit -like "$before*") -or -not ($stamp.sources.source_commit -like "$after*") -or
        ($stamp.sources.stage -contains 'cloud direction check')) {
        throw "Picture provenance does not show two captures from the expected revisions: $jpg"
    }
    $files += @($jpg, $sidecar)
}
New-Item -ItemType Directory -Force -Path $Shots | Out-Null
Copy-Item -LiteralPath $files -Destination $Shots -Force
Write-Output ('Published {0} before/after pictures and provenance sidecars to {1}' -f $rows.Count, $Shots)
