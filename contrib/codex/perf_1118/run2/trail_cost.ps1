param(
    [Parameter(Mandatory=$true)][string]$Before,
    [Parameter(Mandatory=$true)][string]$After,
    [Parameter(Mandatory=$true)][string]$Output
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path "$PSScriptRoot/../../../..").Path
$engine = Join-Path $env:USERPROFILE 'Downloads/voidsworn_test/godot/Godot_v4.7.2-stable_win64_console.exe'
$env:PC_GPU_ISSUE = '1070'
$env:PC_GPU_MODE = 'solo'
New-Item -ItemType Directory -Path $Output | Out-Null
$projects = @{ before = (Resolve-Path "$Before/godot").Path; after = (Resolve-Path "$After/godot").Path }
foreach ($project in $projects.Values) {
    Copy-Item -LiteralPath "$PSScriptRoot/trail_cost.gd" -Destination "$project/bench"
}
for ($session = 1; $session -le 3; $session++) {
    $order = if ($session % 2 -eq 0) { 'after','before' } else { 'before','after' }
    foreach ($source in $order) {
        $log = Join-Path $Output "${source}_s$session.log"
        $data = Join-Path $Output "${source}_s$session.jsonl"
        & "$repo/tools/pc/tmo.bat" 120 $engine --path $projects[$source] --rendering-method forward_plus --rendering-driver vulkan --windowed --resolution 1920x1080 --log-file $log --script res://bench/trail_cost.gd -- $data
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $data) -or
            (Select-String -Quiet -LiteralPath $log -Pattern '^(SCRIPT ERROR|ERROR|Parse Error):')) {
            throw "Moving trail probe failed for $source session $session. See $log"
        }
    }
}
