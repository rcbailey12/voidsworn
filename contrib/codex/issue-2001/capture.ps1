param([string]$Shots, [switch]$Plan)

$ErrorActionPreference = 'Stop'
$trialModes = [ordered]@{ before = $null; after = '1' }

function Get-PlanetCaptureOptions($dir, $side) {
    # Offset 0 frames a dark basalt flow at c26. Offset 5 puts lit ash and basalt in view at the same exposure.
    # --seed is a bench offset, applied to both planet kinds and held fixed across the two passes.
    @(
        '--rendering-method', 'forward_plus', '--fixed-fps', '60', '--disable-vsync', '--windowed',
        '--resolution', '1280x720', '--script', 'res://world/planet_v2_shots.gd', '--',
        '--out', $dir, '--only', 'board', '--mm-trial', '--seed', '5', '--tag', $side
    )
}

if ($Plan) {
    Write-Host 'Planet comparison plan only. No captures are run.'
    foreach ($side in $trialModes.Keys) {
        $trial = if ($null -eq $trialModes[$side]) { '<unset>' } else { $trialModes[$side] }
        $options = Get-PlanetCaptureOptions "<scratch>\$side" $side
        Write-Host ("{0} (VS_MM_TRIAL={1}): {2}" -f $side, $trial, ($options -join ' '))
    }
    exit 0
}

$pc = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
if ($repo -match '[\\/]board_[c-f][\\/]') { throw 'Use a GPU lane checkout for the comparison.' }
if ((Get-Content -LiteralPath (Join-Path $pc 'gpu_go.txt') -TotalCount 1) -notmatch '^GPU cleared(?:\s*:.*)?$') {
    throw 'gpu_go.txt must say GPU cleared.'
}
$godot = $env:GODOT_EXE
if (-not $godot) { $godot = Join-Path $pc 'godot\Godot_v4.7.2-stable_win64_console.exe' }
if (-not (Test-Path -LiteralPath $godot -PathType Leaf)) { throw "Godot not found at $godot" }
$project = Join-Path $repo 'godot'
$tmo = Join-Path $repo 'tools\pc\tmo.bat'
if (-not $Shots) { $Shots = Join-Path $pc 'board_c\issue-2001\shots' }
$Shots = [IO.Path]::GetFullPath($Shots)
$work = Join-Path $env:TEMP ('mm-2001-capture-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
Write-Host "Capture logs are in $work"
Add-Type -AssemblyName System.Drawing

function Get-CleanCommit {
    $revision = & git -C $repo rev-parse --verify HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Could not read the capture checkout commit.' }
    $status = & git -C $repo status --porcelain
    if ($LASTEXITCODE -ne 0 -or $status) { throw 'Use a clean checkout of the reviewed commit with the PC-built hulls installed.' }
    return $revision
}

function Invoke-GodotStep($name, $seconds, [string[]]$options, $marker, [string[]]$trialLoads = @(), [switch]$AllowBandMiss) {
    $log = Join-Path $work "$name.log"
    $env:TMO_STEP = "issue 2001 $name"
    # Windows PowerShell treats native stderr redirected to a file as an error record.
    $ErrorActionPreference = 'Continue'
    & $tmo $seconds $godot --path $project @options *> $log
    $code = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    $output = Get-Content -LiteralPath $log -Raw
    $bandMiss = $AllowBandMiss -and $code -eq 5 -and
        $output -cmatch '(?m)^planet v2 shots: done in \d+ s\r?$' -and
        $output -cmatch '(?m)^planet v2 shots: band 2 MISS: .+\r?$'
    if ((-not $bandMiss -and ($code -ne 0 -or $output -notmatch $marker)) -or
            $output -match 'SCRIPT ERROR|SHADER ERROR|LOOK_BENCH placeholder hull|LOOK_BENCH CODE MISMATCH|Error importing|MM_TRIAL MISSING|planet v2 shots: FAILED to save') {
        throw "$name failed. See $log"
    }
    if ($env:VS_MM_TRIAL -eq '1') {
        foreach ($load in $trialLoads) {
            if ($output -cnotmatch ('(?m)^' + [regex]::Escape("MM_TRIAL LOADED $load") + '\r?$')) {
                throw "$name did not report MM_TRIAL LOADED $load. See $log"
            }
        }
    }
    if ($bandMiss) { return $true }
}

function Confirm-Picture($path) {
    $sidecar = Get-Content -LiteralPath "$path.provenance.json" -Raw | ConvertFrom-Json
    if ($sidecar.picture_name -cne (Split-Path $path -Leaf) -or $sidecar.source_commit -ne $commit -or
            $sidecar.source_dirty -or $sidecar.stage -notin @('installed in game', 'pre-merge capture') -or
            $sidecar.image_sha256 -ine (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash) {
        throw "Capture provenance failed for $path"
    }
    $img = [System.Drawing.Image]::FromFile($path)
    try {
        if ($img.Width -ne 1280 -or $img.Height -gt 720) { throw "Unexpected capture size at $path" }
    } finally {
        $img.Dispose()
    }
}

$commit = Get-CleanCommit
$env:PC_GPU_ISSUE = '2001'
$env:PC_GPU_MODE = 'shared'
$env:PC_REAL_PROFILE = $null
$env:PICTURE_SOURCE_REPO = $repo
$env:VS_SHIP_LOOK_V2 = '1'
$env:VS_FLEET_LIGHTING = '1'
$env:VS_WORLD_PREVIEW = $null
$env:VS_WORLD_CACHE = Join-Path $work 'world-cache'
$env:VS_MM_TRIAL = $null
Invoke-GodotStep 'import' 1800 @('--headless', '--import') 'Godot Engine'

$shipTrialLoads = foreach ($faction in 'voidsworn', 'hegemony', 'corsair', 'chorus', 'ithar', 'deathless') {
    "$faction res://assets/ships/detail/mm_trial/${faction}_grain.png"
    "$faction res://assets/ships/detail/mm_trial/${faction}_n.png"
}
$planets = 'terran', 'volcanic'
$planetTrialLoads = foreach ($planet in $planets) { "$planet res://world/detail/mm_trial/$planet.png" }

$pictures = @()
$bandSummary = @("Material Maker comparison at $commit")
$failedGrade = $false
foreach ($side in $trialModes.Keys) {
    $env:VS_MM_TRIAL = $trialModes[$side]
    $dir = Join-Path $work $side
    New-Item -ItemType Directory -Path $dir | Out-Null
    $rows = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'look_moments.json') -Raw | ConvertFrom-Json
    foreach ($row in $rows.rows) { $row.id = "$($row.expect_code)_$side" }
    $rowFile = Join-Path $dir 'rows.json'
    $rows | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $rowFile -Encoding Ascii
    if ((Get-CleanCommit) -ne $commit) { throw 'The checkout changed during the comparison.' }
    Invoke-GodotStep "ships-$side" 1800 @(
        '--rendering-method', 'forward_plus', '--fixed-fps', '60', '--disable-vsync', '--windowed',
        '--resolution', '1920x1080', 'res://bench/look_bench.tscn', '--', '--out', $dir,
        '--moments', $rowFile, '--part', 'moments', '--commit', $commit
    ) 'LOOK_BENCH_DONE' $shipTrialLoads
    $bench = Get-Content -LiteralPath (Join-Path $dir 'bench.json') -Raw | ConvertFrom-Json
    if ($bench.commit -ne $commit -or $bench.stills.Count -ne ($rows.rows.Count * $rows.cameras.Count)) {
        throw "Incomplete ship comparison in $dir"
    }
    foreach ($row in $rows.rows) {
        foreach ($camera in $rows.cameras) {
            $match = @($bench.stills | Where-Object { $_.id -ceq $row.id -and $_.cam -eq $camera })
            if ($match.Count -ne 1 -or $match[0].code -cne $row.expect_code) {
                throw "Missing installed hull $($row.expect_code) at camera $camera"
            }
            $pictures += Join-Path $dir "moments\$($row.id)__c$camera.png"
        }
    }

    # The before pass measures the stock look. Only grade the trial.
    $planetMarker = if ($side -eq 'before') {
        '(?m)^planet v2 shots: done in \d+ s\r?$'
    } else {
        '(?m)^planet v2 shots: band 2 PASS\r?$'
    }
    $planetStep = "planets-$side"
    $failedGrade = Invoke-GodotStep $planetStep 1200 (Get-PlanetCaptureOptions $dir $side) $planetMarker $planetTrialLoads -AllowBandMiss:($side -eq 'after')
    $summary = @("Planet band 2 summary ($side)") + @(Select-String -LiteralPath (Join-Path $work "$planetStep.log") `
        -Pattern '^planet v2 shots: band(2 | 2 (PASS|MISS)\b)' | ForEach-Object { $_.Line })
    $summary | ForEach-Object { Write-Host $_ }
    $bandSummary += $summary
    foreach ($planet in $planets) {
        foreach ($camera in 'c170', 'c26') {
            $pictures += Join-Path $dir ('{0}_{1}_{2}.png' -f $planet, $camera, $side)
        }
    }
}

if ((Get-CleanCommit) -ne $commit) { throw 'The checkout changed during the comparison.' }
$destinationDir = if ($failedGrade) { Join-Path $Shots 'failed-band-2' } else { $Shots }
foreach ($picture in $pictures) {
    Confirm-Picture $picture
    $destination = Join-Path $destinationDir (Split-Path $picture -Leaf)
    if ((Test-Path -LiteralPath $destination) -or (Test-Path -LiteralPath "$destination.provenance.json")) {
        throw "Review files already exist in $destinationDir. Pass a fresh output directory to capture.bat."
    }
}
New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
foreach ($picture in $pictures) {
    Copy-Item -LiteralPath $picture,"$picture.provenance.json" -Destination $destinationDir
}
if ($failedGrade) {
    (@('FAILED: diagnostic evidence only') + $bandSummary) |
        Set-Content -LiteralPath (Join-Path $destinationDir 'band-summary.txt') -Encoding Ascii
    throw "Trial band 2 failed. $($pictures.Count) verified diagnostic pictures and the band summary are in $destinationDir."
}
Write-Host "PASS: $($pictures.Count) stamped comparisons in $Shots"
