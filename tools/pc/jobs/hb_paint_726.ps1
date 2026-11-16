param([string]$Repo)
$ErrorActionPreference = 'Stop'
$root = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$proof = Join-Path $root 'board_b\issue-726\shots\run3'
$scratch = Join-Path $env:TEMP ('voidsworn726_' + (Get-Date -Format yyyyMMdd_HHmmss))
$game = Join-Path $Repo 'godot'
$installedGame = Join-Path $root 'build\godot'
$tmo = Join-Path $Repo 'tools\pc\tmo.bat'
$gd = Join-Path $root 'godot\Godot_v4.7.2-stable_win64_console.exe'
$blender = Join-Path $root 'blender\blender-4.5.14-windows-x64\blender.exe'
$python = Join-Path $root 'blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe'
$node = Join-Path $root 'node\node.exe'
$ships = @(
    @('corsair_A20', 'A20', 'C16s_23'),
    @('corsair_A18', 'A18', 'C13s_23'),
    @('corsair_A19', 'A19', 'C14s_23'),
    @('corsair_A16', 'A16', 'C19_51'),
    @('corsair_A17', 'A17', 'C15s_23')
)
$null = New-Item -ItemType Directory -Force -Path $proof, $scratch
$status = Join-Path $proof 'status.txt'
function Note([string]$Message) {
    $line = (Get-Date -Format s) + ' ' + $Message
    Add-Content -LiteralPath $status -Value $line
    Write-Host $line
}
function Run([string]$Name, [string]$Exe, [string[]]$Arguments, [int]$Seconds = 21600) {
    $log = Join-Path $scratch ($Name + '.log')
    Note ('START ' + $Name)
    $watch = [Diagnostics.Stopwatch]::StartNew()
    # Native programs write normal diagnostics on stderr. Judge their exit code.
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $tmo $Seconds $Exe @Arguments *> $log
    $code = $LASTEXITCODE
    $ErrorActionPreference = $old
    Note ('END ' + $Name + ' exit=' + $code + ' seconds=' + [math]::Round($watch.Elapsed.TotalSeconds, 1))
    if ($code -ne 0) { throw ($Name + ' failed: ' + $log) }
    return $log
}
function Need([string]$Path, [string]$Pattern) {
    if (-not (Test-Path -LiteralPath $Path)) { throw ('Missing evidence: ' + $Path) }
    if (-not (Select-String -LiteralPath $Path -Pattern $Pattern -Quiet)) { throw ('Missing success marker ' + $Pattern + ' in ' + $Path) }
}
try {
    Set-Location -LiteralPath $Repo
    $env:RECIPE_NOPAUSE = '1'
    $env:PC_GPU_ISSUE = '726'
    $env:PC_GPU_LANE = 'B'
    $env:INSTALL_TO = $game
    $env:TMO_REPO = ''; $env:TMO_OUT = ''; $env:TMO_LOG = ''; $env:TMO_ERR_LOG = ''
    Note ('Scratch logs: ' + $scratch)
    $head = (& git rev-parse HEAD) -join ''
    foreach ($revision in @('440c55fe', '19db9029', '225b10ae')) {
        & git merge-base --is-ancestor $revision HEAD
        if ($LASTEXITCODE -ne 0) { throw ('Required geometry revision is missing: ' + $revision) }
    }
    if ((Get-Content -LiteralPath (Join-Path $root 'gpu_go.txt') -TotalCount 1) -notmatch '^GPU cleared') { throw 'GPU is not cleared' }
    $env:HB726_REVISION = $head.Substring(0, 8) + '+normal726-run3'
    Note ('Source ' + $env:HB726_REVISION + '; PRs 866, 884 and 898 present; GPU cleared')
    $diag = Join-Path $proof 'diagnostic'
    $null = New-Item -ItemType Directory -Force -Path $diag
    $null = Run 'fixture_record' $python @((Join-Path $Repo 'tools\recipe\sheet_fixture_hash.py'), '--check') 120
    foreach ($script in @('normal_bake_diagnostic', 'ship_normal_diagnostic')) {
        $diagOut = Join-Path $scratch $script
        $log = Run $script $blender @('-b', '--python-exit-code', '1', '-P', (Join-Path $Repo ('contrib\codex\issue726\' + $script + '.py')), '--', $Repo, $diagOut)
        Need $log 'PASS .*diagnostic'
        if (Select-String -LiteralPath $log -Pattern 'out of SVM stack space|failed to compile|shader compil(?:e|ation) (?:error|failed)|error compiling' -Quiet) { throw ($script + ': shader compile failure') }
        Copy-Item -LiteralPath (Join-Path $diagOut 'diagnostic.json') -Destination (Join-Path $diag ($script + '.json'))
    }
    foreach ($ship in $ships) {
        $name, $cell, $code = $ship
        foreach ($path in @((Join-Path $root ('bakeoff\' + $name + '_trellis.glb')), (Join-Path $root ('recipe\' + $name + '\concept.png')), (Join-Path $root ('recipe\' + $name + '\concept_camera.json')))) {
            if (-not (Test-Path -LiteralPath $path)) { throw ('Missing recipe prerequisite ' + $path) }
        }
    }
    # Copy only; no purge, deletion or replacement of source code.
    foreach ($folder in @('gen', 'assets\ships')) {
        & robocopy (Join-Path $installedGame $folder) (Join-Path $game $folder) /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-File (Join-Path $scratch 'copy.log') -Append
        if ($LASTEXITCODE -ge 8) { throw ('Asset copy failed: ' + $folder) }
    }
    # gen/manifest.json is generated, and is needed to resolve the copied cache.
    Copy-Item -LiteralPath (Join-Path $installedGame 'gen\manifest.json') -Destination (Join-Path $game 'gen\manifest.json')
    $null = Run 'import_before' $gd @('--headless', '--path', $game, '--import') 2400
    $allCodes = ($ships | ForEach-Object { $_[2] }) -join ','
    $before = Join-Path $proof 'before'
    $null = Run 'before_shots' $gd @('--path', $game, '--resolution', '1920x1080', 'res://assets/ships/test/a4_shots.tscn', '--', '--out', $before, '--facs', 'corsair', '--sets', 'cams', '--codes', $allCodes) 1800
    foreach ($ship in $ships) {
        $name, $cell, $code = $ship
        $env:SHIP = $name
        $job = Join-Path $root ('recipe\' + $name)
        $out = Join-Path $proof $cell
        $null = New-Item -ItemType Directory -Force -Path $out
        if (-not (Test-Path -LiteralPath (Join-Path $before ($code + '_cam170.jpg')))) { throw ($cell + ': before picture is missing') }
        $shipJson = Join-Path $Repo ('tools\recipe\ships\' + $name + '.json')
        $config = Get-Content -Raw -LiteralPath $shipJson | ConvertFrom-Json
        $concept = Join-Path $Repo $config.concept
        foreach ($stage in @('4_parts_kit', '5_paint_bake', '6_lod', '7_export')) {
            $stageLog = Run ($cell + '_' + $stage) 'cmd.exe' @('/d', '/c', ('"' + (Join-Path $Repo ('tools\recipe\' + $stage + '.bat')) + '"'))
            Need $stageLog ('Stage ' + $stage.Substring(0,1) + ' done:')
            Copy-Item -LiteralPath $stageLog -Destination $out
            if ($stage -eq '5_paint_bake') {
                if (Select-String -LiteralPath (Join-Path $job 'log_bake.txt') -Pattern 'out of SVM stack space|failed to compile|shader compil(?:e|ation) (?:error|failed)|error compiling' -Quiet) { throw ($cell + ': Cycles could not compile a bake shader') }
                Need (Join-Path $job 'log_surface.txt') '^PASS surface check'
                $renderCount = @(Select-String -LiteralPath (Join-Path $job 'log_render.txt') -Pattern 'RENDER DONE').Count
                if ($renderCount -ne 3) { throw ($cell + ': expected three completed render passes, got ' + $renderCount) }
            }
        }
        $log = Run ($cell + '_gpu_readback') $gd @('--path', $game, '--script', 'res://render/test/installed_ship_check.gd', '--', $code) 900
        Need $log 'INSTALL READBACK PASS'
        $glb = Join-Path $game ('assets\ships\' + $code + '\' + $code + '.glb')
        $null = Run ($cell + '_interiors') $gd @('--headless', '--path', $game, '--script', 'res://fx/test/authored_interiors_check.gd', '--', $glb) 900
        $null = Run ($cell + '_death_seam') $gd @('--headless', '--path', $game, '--script', 'res://fx/test/death_seam_check.gd', '--', $glb) 900
        # Install the same checked export into the playable PC build. Stage 7
        # backs up the previous files, merges its manifest and refreshes its cache.
        $env:INSTALL_TO = $installedGame
        $installLog = Run ($cell + '_install_playable') 'cmd.exe' @('/d', '/c', ('"' + (Join-Path $Repo 'tools\recipe\7_export.bat') + '"'))
        Need $installLog 'Stage 7 done: PASS'
        Copy-Item -LiteralPath $installLog -Destination $out
        $env:INSTALL_TO = $game
        $after = Join-Path $out 'after'
        $null = Run ($cell + '_after_shots') $gd @('--path', $installedGame, '--resolution', '1920x1080', 'res://assets/ships/test/a4_shots.tscn', '--', '--out', $after, '--facs', 'corsair', '--sets', 'close,cams', '--codes', $code) 1800
        $paint = Join-Path $out 'paint'
        $null = Run ($cell + '_paint_sheet') $blender @('-b', (Join-Path $job ($cell + '.blend')), '-P', (Join-Path $Repo 'tools\blender\build_sheets\paint_sheet.py'), '--', $paint, $name, $concept, 'lift=1.25', 'samples=64', 'scale=1.0', 'gpu=1', 'sky_spec=0', 'cam170=1')
        $null = Run ($cell + '_compare') $python @((Join-Path $Repo 'tools\blender\build_sheets\paint_compare.py'), $paint, $concept, $after, $code, (Join-Path $out 'pictures'), ('name=' + $cell), 'stack=Hullbreaker', 'issue=726') 900
        $null = Run ($cell + '_before_after') $python @((Join-Path $Repo 'tools\pc\jobs\hb_paint_726_pictures.py'), $Repo, $proof, $cell, $code) 900
        foreach ($file in @('audit.json', 'density.json', 'lights.json', 'licences.json', ($cell + '.json'), 'surface\surface_check.json', 'godot\bench209.json', ('export\' + $code + '\' + $code + '_export.json'), ('export\' + $code + '\' + $code + '_check.json'), ('export\' + $code + '\manifest_entry.json'))) {
            $src = Join-Path $job $file
            if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination $out }
        }
        foreach ($file in (Get-ChildItem -LiteralPath $job -File -Filter 'log_*.txt')) {
            Copy-Item -LiteralPath $file.FullName -Destination $out
        }
        $pictures = Join-Path $Repo 'docs\shots\look_bench\hullbreaker_paint_726'
        $null = New-Item -ItemType Directory -Force -Path $pictures
        foreach ($file in @(($cell + '_paint_full.jpg'), ($cell + '_ingame_cam170.jpg'))) {
            Copy-Item -LiteralPath (Join-Path $out ('pictures\' + $file)) -Destination $pictures
        }
        Note ($cell + ' painted, checked and installed')
    }
    # Warm once, keep the second scene gate. tmo reserves the GPU solo.
    foreach ($take in @(1, 2)) {
        $gate = Join-Path $proof ('scene_gate_' + $take)
        $log = Run ('scene_gate_' + $take) $gd @('--path', $game, '--rendering-method', 'forward_plus', '--resolution', '1920x1080', 'res://bench/scene_gate.tscn', '--', '--out', $gate, '--modes', 'base,res_2160') 2400
        Need $log '\[scene_gate\] DONE'
    }
    $log = Run 'fixture_record_after' $python @((Join-Path $Repo 'tools\recipe\sheet_fixture_hash.py'), '--check') 120
    Copy-Item -LiteralPath $log -Destination $diag
    $log = Run 'standing_checks' $node @((Join-Path $Repo 'contrib\opus\tools\run_all_checks.js')) 7200
    Copy-Item -LiteralPath $log -Destination $proof
    Note 'PASS all five paint runs, installs and checks finished'
} catch {
    Note ('FAILED ' + $_.Exception.Message)
    exit 1
}
exit 0
