param(
    [Parameter(Mandatory=$true)][string]$RowsPath,
    [string]$BenchHome,
    [string]$Shots
)

$ErrorActionPreference = 'Stop'
$spec = Get-Content -LiteralPath $RowsPath -Raw | ConvertFrom-Json
$rows = @($spec.rows)
if (($spec.cameras -join ',') -ne '170,26' -or $rows.Count -ne 19) {
    throw 'Expected 19 look-bench rows at cameras 170 and 26.'
}
if (@($rows | Select-Object -ExpandProperty id -Unique).Count -ne $rows.Count) {
    throw 'Duplicate look-bench row id.'
}
foreach ($row in $rows) {
    if ($row.strict -ne $true) {
        throw "Expected a strict capture row: $($row.id)"
    }
    if ($row.id -notmatch '^[a-z0-9_]+$' -or $row.id -ne $row.group -or $row.label -notlike "*$($row.expect_code)*" -or
        ($row.expect_attacker -and $row.label -notlike "*$($row.expect_attacker)*")) {
        throw "Missing row or hull label: $($row.id)"
    }
}
if (-not $BenchHome) {
    Write-Output 'PASS: 19 code-labelled rows at cameras 170 and 26. No GPU work.'
    exit 0
}
if (-not $Shots) { throw 'A shots folder is required to export proof.' }

# Use the exact revision pair that the standing bench just completed.
$status = Get-Content -LiteralPath (Join-Path $BenchHome 'status.txt')
$pairs = @($status | Where-Object { $_ -match '^sheets exit 0 .+\\sheets\\[0-9a-f]+_vs_[0-9a-f]+$' })
if ($pairs.Count -ne 1 -or $pairs[0] -notmatch '(?<sheets>[A-Za-z]:\\.*\\sheets\\(?<before>[0-9a-f]+)_vs_(?<after>[0-9a-f]+))$') {
    throw 'The look bench did not report one completed before/after pair.'
}
$sheets = $Matches.sheets
$before = $Matches.before
$after = $Matches.after
if ($before -eq $after) { throw 'The before and after revisions must be different.' }
$timelines = @{}
foreach ($sha in @($before, $after)) {
    $run = Join-Path (Join-Path $BenchHome 'runs') $sha
    $report = Get-Content -LiteralPath (Join-Path $run 'bench.json') -Raw | ConvertFrom-Json
    if ($report.commit -ne $sha -or @($report.stills).Count -ne $rows.Count * $spec.cameras.Count) {
        throw "The bench result at $sha is incomplete or from a different revision."
    }
    foreach ($row in $rows) {
        $frames = 0
        foreach ($window in $row.windows) { $frames += [int]$window[2] }
        foreach ($camera in $spec.cameras) {
            $match = @($report.stills | Where-Object { $_.id -eq $row.id -and $_.cam -eq $camera })
            if ($match.Count -ne 1 -or $match[0].code -ne $row.expect_code -or $match[0].cells.Count -ne $frames -or
                ($row.expect_attacker -and $match[0].attacker_code -ne $row.expect_attacker)) {
                throw "Missing, incomplete or wrong hull: $sha $($row.id) c$camera"
            }
            $image = Join-Path $run $match[0].file
            if (-not (Test-Path -LiteralPath $image -PathType Leaf) -or
                -not (Test-Path -LiteralPath "$image.provenance.json" -PathType Leaf)) {
                throw "Missing capture or provenance: $image"
            }
            $key = "$($row.id) c$camera"
            $times = ($match[0].cells | Select-Object -ExpandProperty t) -join ','
            if ($sha -eq $before) {
                $timelines[$key] = $times
            } elseif ($timelines[$key] -ne $times) {
                throw "Before and after frame times do not match: $key"
            }
        }
    }
}

# The overview is one 1232 px-wide before/after row per item. Full timing strips stay in the bench folder.
$images = @($rows | ForEach-Object {
    $image = Join-Path $sheets ("moments_overview_{0}.jpg" -f $_.group)
    if (-not (Test-Path -LiteralPath $image -PathType Leaf) -or
        -not (Test-Path -LiteralPath "$image.provenance.json" -PathType Leaf)) {
        throw "Missing proof picture or provenance: $image"
    }
    $image
    "$image.provenance.json"
})
$null = New-Item -Path $Shots -ItemType Directory -Force
foreach ($image in $images) { Copy-Item -LiteralPath $image -Destination $Shots }
Write-Output "PASS: $($rows.Count) before/after comparisons with provenance in $Shots"
