# Issue 1262: before and after timing and pictures for the cheaper 4K Max items, on Ryan's PC through the Board's queue.
# Reuses 1070's probe (contrib/codex/perf_1118/run.ps1, GPU solo, R293). Every variant runs on the same opus/issue-1262
# checkout; VS_1262_OLD switches items back to the old way (all = main's behaviour). A "main" pass checks that claim.
# Writes <Work>\run\t1262_<variant>\..., <Work>\run\s1262_<old|new>\... and <Work>\run\summary1262.txt. Deletes nothing.
param(
    [Parameter(Mandatory=$true)][string]$Work,
    [int]$Runs = 3
)
$ErrorActionPreference = 'Stop'
$probe = Join-Path $Work 'contrib/codex/perf_1118/run.ps1'
$cases = @('gate:max:2:base', 'dense:max:2:native_lod', 'gate:max:1:base', 'dense:max:1:native_lod')
# name = VS_1262_OLD. "after" is the branch as it ships; each single name puts back one item, so its cost is that row
# minus "after"; "before" puts back all four.
$variants = [ordered]@{ after = ''; before = 'all'; ssil = 'ssil'; underlay = 'underlay'; cards = 'cards'; rockshadow = 'rockshadow' }
foreach ($name in $variants.Keys) {
    $env:VS_1262_OLD = $variants[$name]
    & $probe -Work $Work -Phase switches -Runs $Runs -Label "t1262_$name" -Cases $cases -Shapes fitted
}
# Look pictures at c170 and c26 (1070's shots suite), 1080p and 4K, old against new.
foreach ($pair in @(@('old', 'all'), @('new', ''))) {
    $env:VS_1262_OLD = $pair[1]
    & $probe -Work $Work -Phase shots -Runs 1 -Label "s1262_$($pair[0])" -Cases $cases -Shapes fitted
}
$env:VS_1262_OLD = ''

function Median([double[]]$v) {
    if ($v.Count -eq 0) { return [double]::NaN }
    $s = $v | Sort-Object
    if ($s.Count % 2) { return $s[[int][math]::Floor($s.Count / 2)] }
    return ($s[$s.Count / 2 - 1] + $s[$s.Count / 2]) / 2
}
$lines = @('Issue 1262 timing: median of per-session medians, ms (frame / GPU), fitted shields, GPU solo', '')
$table = @{}
foreach ($name in $variants.Keys) {
    foreach ($case in $cases) {
        $frames = @(); $gpus = @(); $ssil = @()
        foreach ($f in Get-ChildItem -Path (Join-Path $Work "run/t1262_$name") -Recurse -Filter samples.jsonl) {
            foreach ($line in Get-Content -LiteralPath $f.FullName) {
                $row = $line | ConvertFrom-Json
                if ($row.case -ne $case -or -not $row.samples) { continue }
                $frames += Median ([double[]]@($row.samples | ForEach-Object { $_[0] }))
                $gpus += Median ([double[]]@($row.samples | ForEach-Object { $_[3] }))
                $ssil += $row.effective.ssil
            }
        }
        $table["$name|$case"] = @((Median $frames), (Median $gpus))
        $lines += ('{0,-11} {1,-24} {2,7:N3} / {3,7:N3}   sessions {4}, ssil {5}' -f $name, $case, (Median $frames), (Median $gpus), $frames.Count, (($ssil | Select-Object -Unique) -join ','))
    }
}
$lines += ''
$lines += 'Saving per item (item row minus after, GPU ms; positive = the item wins):'
foreach ($name in @('before', 'ssil', 'underlay', 'cards', 'rockshadow')) {
    foreach ($case in $cases) {
        $lines += ('{0,-11} {1,-24} {2,7:N3}' -f $name, $case, ($table["$name|$case"][1] - $table["after|$case"][1]))
    }
}
$out = Join-Path $Work 'run/summary1262.txt'
$lines | Set-Content -LiteralPath $out -Encoding Ascii
$lines | Write-Output
