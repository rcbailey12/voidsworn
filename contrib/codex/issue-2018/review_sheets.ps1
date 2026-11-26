param([switch]$Plan)
$ErrorActionPreference = 'Stop'
$cfg = Get-Content -LiteralPath $env:SPARK_MOMENTS -Raw | ConvertFrom-Json
$cameras = @(170, 26)
$beats = @('hit', 'crit', 'death', 'weapon')
$factions = @('voidsworn', 'hegemony', 'corsair', 'ithar', 'deathless', 'chorus')
if (($cfg.cameras -join ',') -ne '170,26' -or $cfg.rows.Count -ne 24) { throw 'Expected 24 rows at cameras 170 and 26.' }
foreach ($faction in $factions) {
    foreach ($beat in $beats) {
        $id = $faction + '_' + $beat
        $one = @($cfg.rows | Where-Object { $_.id -eq $id })
        if ($one.Count -ne 1 -or -not $one[0].expect_code) { throw "Bad row $id" }
        $row = $one[0]
        $frames = 0
        foreach ($window in $row.windows) { $frames += $window[2] }
        if ($frames -ne 4) { throw "Expected four frames in $id" }
        if ($beat -eq 'weapon') {
            if ($row.att[0] -ne $faction -or -not $row.weapon) { throw "Wrong shooter in $id" }
        } elseif ($row.tgt[0] -ne $faction) { throw "Wrong target in $id" }
    }
}
if ($Plan) {
    Write-Output 'PASS: 24 rows, four frames each, cameras 170 and 26. No Godot run.'
    exit 0
}
if ($env:SPARK_A -eq $env:SPARK_B) { throw 'Before and after resolve to the same commit.' }
foreach ($rev in @($env:SPARK_A, $env:SPARK_B)) {
    $run = Join-Path $env:LB_HOME "runs\$rev"
    $log = Join-Path $run 'bench_log.txt'
    if (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR|Shader compilation failed|LOOK_BENCH CODE MISMATCH' -Quiet) {
        throw "The bench logged an error for $rev ($log)."
    }
    $report = Get-Content -LiteralPath (Join-Path $run 'bench.json') -Raw | ConvertFrom-Json
    if ($report.commit -ne $rev -or $report.stills.Count -ne 48) { throw "Wrong revision or incomplete capture for $rev." }
    foreach ($row in $cfg.rows) {
        foreach ($cam in $cameras) {
            $found = @($report.stills | Where-Object { $_.id -eq $row.id -and $_.cam -eq $cam })
            if ($found.Count -ne 1 -or $found[0].cells.Count -ne 4 -or $found[0].code -ne $row.expect_code) {
                throw "Missing frames or wrong hull in $rev for $($row.id), camera $cam."
            }
        }
    }
}
$sheetDir = Join-Path $env:LB_HOME ('sheets\' + $env:SPARK_B + '_vs_' + $env:SPARK_A + '\moments')
$files = foreach ($row in $cfg.rows) {
    $picture = Join-Path $sheetDir ($row.id + '.jpg')
    $sidecar = $picture + '.provenance.json'
    if (-not (Test-Path -LiteralPath $picture -PathType Leaf) -or -not (Test-Path -LiteralPath $sidecar -PathType Leaf)) {
        throw "Missing comparison or provenance for $($row.id)."
    }
    $picture
    $sidecar
}
[void][IO.Directory]::CreateDirectory($env:SPARK_SHOTS)
Copy-Item -LiteralPath $files -Destination $env:SPARK_SHOTS
Write-Output "PASS: 24 matched strips with provenance in $env:SPARK_SHOTS"
