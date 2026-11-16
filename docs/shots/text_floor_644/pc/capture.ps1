param(
    [string]$Raw = (Join-Path $env:TEMP ('issue671_' + (Get-Date -Format yyyyMMdd_HHmmss))),
    [switch]$FinalOnly,
    [switch]$ResumeFinal
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$pcRoot = (Resolve-Path (Join-Path $repo '..\..')).Path
$engine = Join-Path $pcRoot 'godot\Godot_v4.7.2-stable_win64_console.exe'
$watchdog = Join-Path $repo 'tools\pc\tmo.bat'
$harness = Join-Path $PSScriptRoot 'capture.gd'
$pythonExe = Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'
if (-not (Test-Path -LiteralPath $pythonExe)) { $pythonExe = (Get-Command python -ErrorAction Stop).Source }
New-Item -ItemType Directory -Force -Path $Raw | Out-Null

function Capture([int]$height, [int]$fleet, [string]$sky) {
    $tag = '{0}_{1}_{2}' -f $height,$fleet,$sky
    $savedLog = Join-Path $Raw ($tag+'_engine.log')
    if ($ResumeFinal -and (Test-Path -LiteralPath $savedLog) -and (Select-String -LiteralPath $savedLog -Pattern 'CAPTURE_DONE' -Quiet)) {
        Write-Output ('Reusing completed '+$tag)
        return
    }
    # The queue can start an API worker while Codex is running. Recheck before every render.
    while (Get-CimInstance Win32_Process | Where-Object {
        $_.Name -match 'blender|Embers' -or ($_.Name -match 'Godot' -and $_.CommandLine -notmatch '--headless')
    }) {
        Write-Output 'Waiting for the other GPU rendering job.'
        Start-Sleep -Seconds 15
    }
    $size = '{0}x{1}' -f ($height * 16 / 9),$height
    $captureArgs = @(360,$engine,'--path',(Join-Path $repo 'godot'),'--log-file',(Join-Path $Raw ($tag+'_engine.log')),'--rendering-method','forward_plus','--windowed','--resolution',$size,'--max-fps',60,'--script',$harness,'--',$Raw,$height,$fleet,$sky)
    & $watchdog @captureArgs *> (Join-Path $Raw ($tag+'.log'))
    if ($LASTEXITCODE -ne 0) { throw ('Capture failed: '+$tag+', exit '+$LASTEXITCODE) }
    Write-Output ('Finished '+$tag)
}

if (-not $FinalOnly) {
    foreach ($sky in @('frontier','nebula','world','boneyard','deep','storm')) { Capture 1080 1 $sky }
}
$selectionJson = & $pythonExe (Join-Path $PSScriptRoot 'finish.py') select $Raw
if ($LASTEXITCODE -ne 0) { throw 'Sky selection failed' }
$selection = $selectionJson | ConvertFrom-Json
$selectionJson | Set-Content -Encoding UTF8 (Join-Path $Raw 'sky_selection.json')
Write-Output $selectionJson
foreach ($height in @(1080,1440)) {
    foreach ($fleet in @(1,20)) {
        foreach ($sky in @($selection.brightest,$selection.darkest)) { Capture $height $fleet $sky }
    }
}
Capture 1440 3 campaign
$shots = Join-Path $pcRoot 'board\issue-671\shots'
& $pythonExe (Join-Path $PSScriptRoot 'finish.py') finish $Raw $PSScriptRoot $shots
if ($LASTEXITCODE -ne 0) { throw 'Picture measurement or JPG conversion failed' }
Write-Output ('CAPTURE_SET_DONE '+$Raw)
