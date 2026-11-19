param(
    [Parameter(Mandatory=$true)][string]$Work,
    [string]$Shared = "$env:USERPROFILE/Downloads/voidsworn_test/build/godot"
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path "$PSScriptRoot/../../..").Path
$commit = & git -C $repo rev-parse HEAD
if ($LASTEXITCODE -ne 0) { throw 'Cannot read the source revision.' }
$dirty = @(& git -C $repo -c core.quotepath=false diff --name-only --no-renames $commit -- godot tools/picture_font.json)
if ($LASTEXITCODE -ne 0) { throw 'Cannot compare the checkout with the baseline revision.' }
$project = Join-Path $Work 'godot'
if (Test-Path -LiteralPath $project) { throw 'Choose a fresh working directory in TEMP.' }
$Shared = (Resolve-Path -LiteralPath $Shared).Path
$manifests = @('assets/ships/manifest.json', 'gen/manifest.json')
$hashes = @{}
foreach ($file in $manifests) {
    $hashes[$file] = (Get-FileHash -LiteralPath (Join-Path $Shared $file)).Hash.ToLowerInvariant()
}
New-Item -ItemType Directory -Path $Work -Force | Out-Null
robocopy $Shared $project /E /XD shader_cache /NP /NFL /NDL /NJH /NJS /R:1 /W:1
if ($LASTEXITCODE -ge 8) { throw "Shared build copy failed: $LASTEXITCODE" }
foreach ($file in $manifests) {
    foreach ($base in @($Shared, $project)) {
        if ($hashes[$file] -ne (Get-FileHash -LiteralPath (Join-Path $base $file)).Hash) {
            throw "Shared asset manifest changed during the snapshot: $file"
        }
    }
}
$installed = Get-Content -Raw -LiteralPath (Join-Path $project $manifests[0]) | ConvertFrom-Json
$checked = 0
foreach ($ship in $installed.ships.PSObject.Properties) {
    foreach ($entry in $ship.Value.files.PSObject.Properties) {
        $manifestPath = Join-Path "$project/assets/ships/$($ship.Name)" $entry.Name
        $asset = Get-Item -LiteralPath $manifestPath
        if ($asset.Length -ne $entry.Value.bytes -or (Get-FileHash -LiteralPath $manifestPath).Hash -ne $entry.Value.sha256) {
            throw "Installed ship file disagrees with manifest: $($ship.Name)/$($entry.Name)"
        }
        $checked++
    }
}

$commitDate = & git -C $repo show -s --format=%cI $commit
if ($LASTEXITCODE -ne 0) { throw 'Cannot read the source commit date.' }
$files = @(& git -C $repo -c core.quotepath=false ls-tree -r --name-only $commit -- godot tools/picture_font.json)
if ($LASTEXITCODE -ne 0) { throw 'Cannot read the tracked Godot files.' }
foreach ($path in $files) {
    if ($path -in $dirty) { continue }
    $target = Join-Path $Work $path
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
    [IO.File]::Copy((Join-Path $repo $path), $target, $true)
}
$fromCommit = @($dirty | Where-Object { $_ -in $files })
if ($fromCommit.Count) {
    $archive = Join-Path $Work 'baseline_overlay.zip'
    & git -C $repo archive --format=zip "--output=$archive" $commit -- @fromCommit
    if ($LASTEXITCODE -ne 0) { throw 'Cannot read modified files from the baseline revision.' }
    Expand-Archive -LiteralPath $archive -DestinationPath $Work -Force
}
if ($hashes[$manifests[0]] -ne (Get-FileHash (Join-Path $project $manifests[0])).Hash) {
    throw 'The shared installed ship manifest differs from the requested source revision.'
}
[IO.File]::Copy((Join-Path $Work 'tools/picture_font.json'), (Join-Path $project 'tools/picture_font.json'), $true)
$cpu = Get-ItemPropertyValue 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0' ProcessorNameString
$gpu = & nvidia-smi --query-gpu=name,driver_version,vbios_version,memory.total --format=csv,noheader
if ($LASTEXITCODE -ne 0) { throw 'Cannot read the NVIDIA driver version.' }
@{
    commit = $commit
    commit_date = ([DateTimeOffset]::Parse($commitDate)).UtcDateTime.ToString("yyyy-MM-ddTHH:mm:ss'Z'")
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $project 'build_info.json') -Encoding Ascii
@{
    commit = $commit
    installed_ship_manifest_sha256 = $hashes[$manifests[0]]
    installed_gen_manifest_sha256 = $hashes[$manifests[1]]
    installed_ship_files_checked = $checked
    gpu_driver_vbios_vram = $gpu
    cpu = $cpu.Trim()
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Work 'machine.json') -Encoding Ascii
Write-Output "Staged $commit with the installed fleet in $project"
exit 0
