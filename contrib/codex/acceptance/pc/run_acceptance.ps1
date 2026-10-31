param([string]$Godot = $env:VOIDSWORN_GODOT_EXE)
$ErrorActionPreference = 'Stop'
try {
  if (-not $Godot -or -not (Test-Path -LiteralPath $Godot -PathType Leaf)) {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = 'Choose the Godot executable'
    $dialog.Filter = 'Godot executable|*.exe'
    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { throw 'Canceled. No checks ran.' }
    $Godot = $dialog.FileName
  }
  Write-Host 'Running automated checks in isolated source copies. This does not install runtime patches.'
  & node (Join-Path $PSScriptRoot '..\tools\run_all.js') --godot $Godot
  exit $LASTEXITCODE
} catch {
  Write-Host $_.Exception.Message -ForegroundColor Red
  exit 2
}
