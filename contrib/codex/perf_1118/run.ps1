param(
    [Parameter(Mandatory=$true)][string]$Work,
    [Parameter(Mandatory=$true)][ValidateSet('baseline','switches','cold','profile','shots','gate')][string]$Phase,
    [int]$Runs = 3,
    [string]$Label = $Phase,
    [string[]]$Cases,
    [ValidateSet('fitted','egg')][string[]]$Shapes
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path "$PSScriptRoot/../../..").Path
$pc = Join-Path $env:USERPROFILE 'Downloads/voidsworn_test'
$godot = Join-Path $pc 'godot/Godot_v4.7.2-stable_win64_console.exe'
$project = (Resolve-Path (Join-Path $Work 'godot')).Path
$output = Join-Path $Work "run/$Label"
if (Test-Path -LiteralPath $output) { throw "Output already exists: $Label" }
New-Item -ItemType Directory -Path $output | Out-Null
Copy-Item -LiteralPath "$PSScriptRoot/perf_1118.gd" -Destination (Join-Path $output 'probe.gd')
Copy-Item -LiteralPath "$PSScriptRoot/boot.gd","$PSScriptRoot/perf_1118.gd" -Destination "$project/bench"
$env:PC_GPU_ISSUE = '1070'
$env:PC_GPU_MODE = 'solo'
$watchdog = Join-Path $repo 'tools/pc/tmo.bat'
if (-not $Shapes) {
    $Shapes = if ($Phase -in @('baseline','gate','cold')) { @('fitted','egg') } else { @('fitted') }
}
$presets = @{
    cold = @('gate:max:1:base')
    profile = @('gate:max:1:base','dense:max:1:base','large:max:1:base','gate:max:1:ship_submissions')
    shots = @('gate:max:1:base','gate:max:1:msaa_2x','gate:max:1:msaa_off')
    switches = @(
        'gate:max:1:base','gate:max:1:msaa_2x','gate:max:1:msaa_off',
        'gate:max:1:meshes_off','gate:max:1:opaque_material','gate:max:1:lod',
        'gate:max:1:shadows_off','gate:max:1:ship_shadows_off','gate:max:1:lights_off',
        'gate:max:1:shields_off','gate:max:1:shield_hit','gate:max:1:shield_failure',
        'gate:max:1:particles_off','gate:max:1:fragments_off','gate:max:1:fragment_burst',
        'gate:max:1:death','gate:max:1:death_without_fragments','gate:max:1:fx_off',
        'gate:max:1:post_off','gate:max:1:ship_process_off','gate:max:1:battle_process_off',
        'gate:max:2:base','gate:max:2:msaa_2x','gate:max:2:msaa_off',
        'dense:max:2:base','dense:max:2:fog_off','dense:max:2:fog_64',
        'dense:max:2:storm_off','dense:max:2:gas_cards_off','dense:max:2:dust_off',
        'dense:max:2:bolts_draw_off','dense:max:2:lod',
        'dense:high:2:base','dense:high:2:gas_cards_off',
        'large:max:2:base','large:max:2:lod'
    )
}

function Invoke-PerfBatch($shape, $session) {
    $folder = Join-Path $output ("{0}_s{1}" -f $shape, $session)
    New-Item -ItemType Directory -Path $folder | Out-Null
    $env:VS_SHIELD_SHAPE = $shape
    $engine = @('--path', $project, '--rendering-method', 'forward_plus', '--rendering-driver', 'vulkan',
        '--windowed', '--resolution', '1920x1080', '--log-file', (Join-Path $folder 'engine.log'))
    if ($Phase -eq 'profile') { $engine += @('-d', '--gpu-profile') }
    $opts = @('--out', $folder)
    $sequence = $Cases
    if ($Phase -eq 'gate') {
        $opts += @('--sessions', '1', '--warmup', '180', '--frames', '720', '--modes', 'base,res_2160')
        $result = 'scene_gate.json'
        $engine += @('res://bench/scene_gate.tscn', '--')
    } else {
        if (-not $sequence -and $Phase -eq 'baseline') {
            $fixtures = if ($shape -eq 'fitted') { @('gate','dense','large') } else { @('gate') }
            $sequence = @(foreach ($fixture in $fixtures) {
                $variant = if ($fixture -eq 'gate') { 'base' } else { 'native_lod' }
                foreach ($quality in @('max','high','low')) {
                    foreach ($scale in @(1,2)) { "${fixture}:${quality}:${scale}:${variant}" }
                }
            })
        }
        if (-not $sequence) { $sequence = $presets[$Phase] }
        $sequence = [string[]]$sequence.Clone()
        if ($session % 2 -eq 0 -and $Phase -in @('baseline','switches')) { [Array]::Reverse($sequence) }
        $opts += @('--cases', ($sequence -join ','), '--session', "$session", '--suite', $Phase)
        if ($Phase -eq 'profile') { $opts += '--profile' }
        $result = 'samples.jsonl'
        $engine += @('--script', 'res://bench/boot.gd', '--')
    }
    Write-Output "Issue 1070 $Label $shape session $session begins"
    $before = & nvidia-smi --query-gpu=temperature.gpu,clocks.gr,clocks.mem,pstate,power.draw,memory.used --format=csv
    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $watchdog 1800 $godot @engine @opts
        $status = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    $after = & nvidia-smi --query-gpu=temperature.gpu,clocks.gr,clocks.mem,pstate,power.draw,memory.used --format=csv
    @($before[0], $before[-1], $after[-1]) | Set-Content -LiteralPath (Join-Path $folder 'gpu.csv') -Encoding Ascii
    if ($status -ne 0 -or -not (Test-Path -LiteralPath (Join-Path $folder $result))) {
        throw "$Label $shape session $session failed with watchdog exit $status."
    }
    if ($Phase -ne 'gate' -and @(Get-Content -LiteralPath (Join-Path $folder $result)).Count -ne ($sequence.Count + 1)) {
        throw "Incomplete case data for $Label $shape session $session."
    }
    if (Select-String -Quiet -LiteralPath (Join-Path $folder 'engine.log') -Pattern '^(SCRIPT ERROR|ERROR|Parse Error):') {
        throw "Godot logged an error during $Label $shape session $session."
    }
    Write-Output "Issue 1070 $Label $shape session $session complete"
}

for ($session = 1; $session -le $Runs; $session++) {
    $order = [string[]]$Shapes.Clone()
    if ($session % 2 -eq 0) { [Array]::Reverse($order) }
    foreach ($shape in $order) {
        Invoke-PerfBatch $shape $session
    }
}
