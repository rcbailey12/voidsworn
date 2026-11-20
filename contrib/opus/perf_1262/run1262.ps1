# Issue 1262: timing and pictures for the cheaper 4K Max items, on Ryan's PC through the Board's queue (RUN1262B.bat).
# Uses 1070's probe (contrib/codex/perf_1118/perf_1118.gd and boot.gd) from the checkout in -Work, the GPU solo (R293).
# Every Godot start goes through the watchdog given in -Tmo (the tools_live copy) in its own throwaway profile.
# -Variants: name=VS_1262_OLD pairs, e.g. "after=,ssil=ssil,before=all" ("" means the branch as it ships).
# Writes <Out>\t_<variant>\s<n>\samples.jsonl, <Out>\shots_<variant>\ and <Out>\summary_<label>.txt. Deletes nothing.
param(
    [Parameter(Mandatory=$true)][string]$Work,
    [Parameter(Mandatory=$true)][string]$Tmo,
    [Parameter(Mandatory=$true)][string]$Godot,
    [Parameter(Mandatory=$true)][string]$Out,
    [Parameter(Mandatory=$true)][string]$Label,
    [Parameter(Mandatory=$true)][string]$Variants,
    [string]$ShotVariant = '',
    [int]$Runs = 3
)
$ErrorActionPreference = 'Stop'
$project = (Resolve-Path (Join-Path $Work 'godot')).Path
$probeDir = Join-Path $Work 'contrib/codex/perf_1118'
Copy-Item -LiteralPath (Join-Path $probeDir 'boot.gd'), (Join-Path $probeDir 'perf_1118.gd') -Destination (Join-Path $project 'bench')
$cases = @('gate:max:2:base', 'dense:max:2:native_lod', 'gate:max:1:base', 'dense:max:1:native_lod')
$env:PC_GPU_ISSUE = '1262'
$env:PC_GPU_MODE = 'solo'
$env:VS_SHIELD_SHAPE = 'fitted'
$profiles = Join-Path $Out 'profiles'
if (-not (Test-Path -LiteralPath $profiles)) { New-Item -ItemType Directory -Path $profiles | Out-Null }

function Invoke-Godot($folder, [string[]]$opts, [int]$expect) {
    New-Item -ItemType Directory -Path $folder | Out-Null
    $profile = Join-Path $profiles ([Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $profile | Out-Null
    $oldApp = $env:APPDATA; $oldLocal = $env:LOCALAPPDATA
    $env:APPDATA = $profile; $env:LOCALAPPDATA = $profile
    $engine = @('--path', $project, '--rendering-method', 'forward_plus', '--rendering-driver', 'vulkan',
        '--windowed', '--resolution', '1920x1080', '--log-file', (Join-Path $folder 'engine.log'),
        '--script', 'res://bench/boot.gd', '--', '--out', $folder) + $opts
    $previous = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $Tmo 1800 $Godot @engine
        $status = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previous
        $env:APPDATA = $oldApp; $env:LOCALAPPDATA = $oldLocal
    }
    $result = Join-Path $folder 'samples.jsonl'
    if ($status -ne 0 -or -not (Test-Path -LiteralPath $result)) { throw "$folder failed with watchdog exit $status." }
    if (@(Get-Content -LiteralPath $result).Count -ne $expect) { throw "Incomplete case data in $folder." }
    if (Select-String -Quiet -LiteralPath (Join-Path $folder 'engine.log') -Pattern '^(SCRIPT ERROR|ERROR|Parse Error):') {
        throw "Godot logged an error in $folder."
    }
}

$pairs = [ordered]@{}
foreach ($p in $Variants.Split(',')) { $kv = $p.Split('=', 2); $pairs[$kv[0]] = $kv[1] }
for ($session = 1; $session -le $Runs; $session++) {
    $names = [string[]]@($pairs.Keys)
    if ($session % 2 -eq 0) { [Array]::Reverse($names) }
    foreach ($name in $names) {
        $env:VS_1262_OLD = $pairs[$name]
        $seq = [string[]]$cases.Clone()
        if ($session % 2 -eq 0) { [Array]::Reverse($seq) }
        Write-Output "Issue 1262 $Label $name session $session"
        Invoke-Godot (Join-Path $Out "t_$name/s$session") @('--cases', ($seq -join ','), '--session', "$session", '--suite', 'switches') ($seq.Count + 1)
    }
}
# Look pictures at c170 and c26 (1070's shots suite), 1080p and 4K.
$env:VS_1262_OLD = $ShotVariant
Invoke-Godot (Join-Path $Out "shots_$Label") @('--cases', ($cases -join ','), '--suite', 'shots') ($cases.Count + 1)
$env:VS_1262_OLD = ''

function Median([double[]]$v) {
    if ($v.Count -eq 0) { return [double]::NaN }
    $s = $v | Sort-Object
    if ($s.Count % 2) { return $s[[int][math]::Floor($s.Count / 2)] }
    return ($s[$s.Count / 2 - 1] + $s[$s.Count / 2]) / 2
}
$lines = @("Issue 1262 $Label timing: median of per-session medians, ms (frame / GPU), fitted shields, GPU solo")
foreach ($name in $pairs.Keys) {
    foreach ($case in $cases) {
        $frames = @(); $gpus = @(); $ssil = @()
        foreach ($f in Get-ChildItem -Path (Join-Path $Out "t_$name") -Recurse -Filter samples.jsonl) {
            foreach ($line in Get-Content -LiteralPath $f.FullName) {
                $row = $line | ConvertFrom-Json
                if ($row.case -ne $case -or -not $row.samples) { continue }
                $frames += Median ([double[]]@($row.samples | ForEach-Object { $_[0] }))
                $gpus += Median ([double[]]@($row.samples | ForEach-Object { $_[3] }))
                $ssil += $row.effective.ssil
            }
        }
        $lines += ('{0} | {1} | {2:N3} | {3:N3} | sessions {4} | ssil {5}' -f $name, $case, (Median $frames), (Median $gpus), $frames.Count, (($ssil | Select-Object -Unique) -join ','))
    }
}
$lines | Set-Content -LiteralPath (Join-Path $Out "summary_$Label.txt") -Encoding Ascii
$lines | Write-Output
