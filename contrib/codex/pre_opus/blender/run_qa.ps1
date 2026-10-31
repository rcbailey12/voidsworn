param(
  [string]$Asset = '',
  [string]$Blender = $env:VOIDSWORN_BLENDER_EXE,
  [string]$Forward = '+X',
  [string]$Up = '+Z',
  [switch]$SelfTest
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
function Choose-File([string]$Title, [string]$Filter) {
  $dialog = New-Object System.Windows.Forms.OpenFileDialog
  $dialog.Title = $Title
  $dialog.Filter = $Filter
  if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { throw 'Canceled. No QA job ran.' }
  return $dialog.FileName
}
try {
  if (-not $Blender) {
    $candidates = @(Get-ChildItem -Path "$env:ProgramFiles\Blender Foundation\Blender*\blender.exe" -ErrorAction SilentlyContinue | Sort-Object FullName -Descending)
    if ($candidates.Count -gt 0) { $Blender = $candidates[0].FullName }
  }
  if (-not $Blender -or -not (Test-Path -LiteralPath $Blender -PathType Leaf)) {
    $Blender = Choose-File 'Choose Blender executable' 'Blender|blender.exe'
  }
  if (-not $SelfTest -and -not $Asset) { $Asset = Choose-File 'Choose the GLB or glTF to inspect' 'glTF asset|*.glb;*.gltf' }
  if (-not $SelfTest -and -not (Test-Path -LiteralPath $Asset -PathType Leaf)) { throw 'The selected asset does not exist.' }
  $stamp = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
  $output = Join-Path $PSScriptRoot ('output\qa_' + $stamp)
  New-Item -ItemType Directory -Path $output -Force | Out-Null
  $script = Join-Path $PSScriptRoot 'inspect_and_render.py'
  $arguments = @('--background', '--factory-startup', '--python-exit-code', '2', '--python', $script, '--', '--out', $output, ('--forward=' + $Forward), ('--up=' + $Up), '--render')
  if ($SelfTest) { $arguments += '--self-test' } else { $arguments += @('--asset', $Asset) }
  Write-Host ('Imported Blender frame: forward ' + $Forward + ', up ' + $Up + '. Confirm this on the diagnostic sheet.')
  Write-Host 'Inspecting and rendering 18 diagnostic views. The source asset is not saved or replaced.'
  $previousPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  & $Blender @arguments 2>&1 | Tee-Object -FilePath (Join-Path $output 'blender.log')
  $code = $LASTEXITCODE
  $ErrorActionPreference = $previousPreference
  if ($code -ne 0) { throw ('Blender failed with exit ' + $code + '. See ' + $output) }
  $reportPath = Join-Path $output 'report.json'
  if (-not (Test-Path -LiteralPath $reportPath)) { throw 'Blender exited without a report. The job is incomplete.' }
  $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
  if ($report.status -ne 'DIAGNOSTIC_ONLY_REVIEW_REQUIRED' -or @($report.images).Count -ne 18) { throw 'Missing diagnostic images or unexpected report status.' }
  if ($SelfTest -and $report.selfTest -ne 'PASS') { throw 'The generated-fixture self-test did not pass.' }
  Write-Host ('Ready for manual inspection: ' + $output)
  Start-Process (Join-Path $output 'contact_sheet.html')
  exit 0
} catch {
  Write-Host $_.Exception.Message -ForegroundColor Red
  exit 1
}
