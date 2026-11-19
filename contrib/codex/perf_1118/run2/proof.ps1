param(
    [Parameter(Mandatory=$true)][string]$Work,
    [string]$Label = 'proof',
    [switch]$Storm,
    [switch]$StormHighOnly
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path "$PSScriptRoot/../../../..").Path
$project = (Resolve-Path (Join-Path $Work 'godot')).Path
$pc = Join-Path $env:USERPROFILE 'Downloads/voidsworn_test'
$engine = Join-Path $pc 'godot/Godot_v4.7.2-stable_win64_console.exe'
Copy-Item -LiteralPath "$PSScriptRoot/../perf_1118.gd","$PSScriptRoot/proof.gd" -Destination "$project/bench"
$boot = 'extends SceneTree', '', 'func _initialize() -> void:', "`troot.add_child.call_deferred(preload(`"res://bench/proof.gd`").new())"
$boot | Set-Content -LiteralPath "$project/bench/proof_boot.gd" -Encoding Ascii
$env:PC_GPU_ISSUE = '1070'
$env:PC_GPU_MODE = 'solo'
$env:VS_SHIELD_SHAPE = 'fitted'
$cases = 'gate:max:1:base'
$count = 4
if ($StormHighOnly) {
    $cases = 'dense:high:2:native_lod'
    $count = 2
} elseif ($Storm) {
    $cases += ',dense:high:2:native_lod,dense:max:2:native_lod'
    $count += 4
}
foreach ($take in 1,2) {
    $out = Join-Path $Work "${Label}_$take"
    if (Test-Path -LiteralPath $out) { throw "Proof output already exists: $out" }
    New-Item -ItemType Directory -Path $out | Out-Null
    $log = Join-Path $out 'engine.log'
    & "$repo/tools/pc/tmo.bat" 900 $engine --path $project --rendering-method forward_plus --rendering-driver vulkan --windowed --resolution 1920x1080 --log-file $log --script res://bench/proof_boot.gd -- --out $out --cases $cases --suite shots
    if ($LASTEXITCODE -ne 0 -or @(Get-ChildItem -LiteralPath $out -Filter '*.png').Count -ne $count -or
        (Select-String -Quiet -LiteralPath $log -Pattern '^(SCRIPT ERROR|ERROR|Parse Error):')) {
        throw "Proof take $take failed. See $log"
    }
}
