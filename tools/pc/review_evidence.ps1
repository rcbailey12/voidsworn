# Picture evidence in runner reports, PowerShell 5.1. Never invent a stamp here.
# prepare <repo> <out> <repo destination>, check <repo> <commit body>
$ErrorActionPreference = 'Stop'
$mode = $args[0]; $repo = $args[1]; $inputPath = $args[2]
$body = $inputPath
if ($mode -eq 'prepare') { $body = Join-Path $inputPath 'last.md' }
if (-not (Test-Path -LiteralPath $body)) { exit 0 }
# Code-only reports need neither Pillow nor an evidence directory.
if ([IO.File]::ReadAllText($body) -notmatch '(?i)\.(png|jpe?g|webp|gif)\b') { exit 0 }
$python = $env:PICTURE_PYTHON
if (-not $python) {
  foreach ($candidate in @(
    "$env:USERPROFILE\Downloads\ComfyUI_windows_portable\python_embeded\python.exe",
    "$env:USERPROFILE\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe",
    'python'
  )) {
    if (Get-Command $candidate -ErrorAction SilentlyContinue) { $python = $candidate; break }
  }
}
if (-not $python) { Write-Host 'FAIL review pictures: Python with Pillow is required'; exit 1 }
$helper = Join-Path $repo 'tools\picture_provenance.py'
if ($mode -eq 'prepare') {
  & $python $helper publish-report $inputPath --repo $repo --destination $args[3]
} elseif ($mode -eq 'check') {
  & $python $helper check-body $inputPath --repo $repo --staged
} else { Write-Host 'FAIL unknown review evidence mode'; exit 1 }
exit $LASTEXITCODE
