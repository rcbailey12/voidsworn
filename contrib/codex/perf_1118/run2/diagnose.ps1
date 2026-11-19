param(
    [Parameter(Mandatory=$true)][string]$Work,
    [Parameter(Mandatory=$true)][ValidateSet('before_isolation','after_isolation')][string]$Label
)

$ErrorActionPreference = 'Stop'
$backup = Join-Path $Work ('isolation_sources_' + $Label + '_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
if (Test-Path -LiteralPath $backup) { throw "Isolation backup already exists: $backup" }
New-Item -ItemType Directory -Path $backup | Out-Null
$files = 'fx.gd','fx_ship.gd','fx_breach.gd'
foreach ($file in $files) {
    Copy-Item -LiteralPath "$Work/godot/fx/$file" -Destination "$backup/$file"
}
try {
    python -B "$PSScriptRoot/instrument.py" $Work
    if ($LASTEXITCODE -ne 0) { throw 'Cannot add the isolation counters' }
    & "$PSScriptRoot/../run.ps1" -Work $Work -Phase baseline -Label $Label -Shapes fitted -Cases 'gate:max:1:base'
} finally {
    foreach ($file in $files) {
        Copy-Item -LiteralPath "$backup/$file" -Destination "$Work/godot/fx/$file" -Force
    }
}
