$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskShots = Join-Path $taskRoot 'contrib/codex/onboarding_2026_11/shots'
$taskCards = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'onboarding_cards.json') -Raw | ConvertFrom-Json
$taskFont = New-Object System.Drawing.Font('Arial', 12)
$taskBrush = [System.Drawing.Brushes]::White
function Add-CardCrop($graphics, $name, $x, $y, $label, $campaign) {
    $picture = [System.Drawing.Image]::FromFile((Join-Path $taskShots $name))
    try {
        $graphics.DrawString($label, $taskFont, $taskBrush, [single]($x + 8), [single]($y + 5))
        $sourceX = if ($campaign) { 1523 } else { 1190 }
        $sourceY = if ($campaign) { 82 } else { 72 }
        $destination = New-Object System.Drawing.Rectangle($x, ($y + 30), 380, 300)
        $source = New-Object System.Drawing.Rectangle($sourceX, $sourceY, 380, 300)
        $graphics.DrawImage($picture, $destination, $source, [System.Drawing.GraphicsUnit]::Pixel)
    } finally { $picture.Dispose() }
}
try {
    $sheet = New-Object System.Drawing.Bitmap(1200, 1670)
    $graphics = [System.Drawing.Graphics]::FromImage($sheet)
    try {
        $graphics.Clear([System.Drawing.Color]::FromArgb(15, 22, 38))
        for ($i = 0; $i -lt $taskCards.Count; $i++) {
            $id = $taskCards[$i][0]
            $campaign = $id.StartsWith('c_')
            $prefix = if ($campaign) { 'campaign_' } else { 'battle_' }
            Add-CardCrop $graphics ($prefix + $id + '_1080.png') (($i % 3) * 400) ([math]::Floor($i / 3) * 334) (($i + 1).ToString() + '. ' + $taskCards[$i][1]) $campaign
        }
        $sheet.Save((Join-Path $taskShots 'all_cards.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    } finally { $graphics.Dispose(); $sheet.Dispose() }
    if (Test-Path -LiteralPath (Join-Path $taskShots 'before_select_1080.png')) {
        $comparison = New-Object System.Drawing.Bitmap(800, 340)
        $graphics = [System.Drawing.Graphics]::FromImage($comparison)
        try {
            $graphics.Clear([System.Drawing.Color]::FromArgb(15, 22, 38))
            Add-CardCrop $graphics 'before_select_1080.png' 0 0 'Before' $false
            Add-CardCrop $graphics 'battle_select_1080.png' 400 0 'After: complete brace rule and off link' $false
            $comparison.Save((Join-Path $taskShots 'before_after.png'), [System.Drawing.Imaging.ImageFormat]::Png)
        } finally { $graphics.Dispose(); $comparison.Dispose() }
    }
} finally { $taskFont.Dispose() }
Write-Output 'PASS: retained teaching card sheets'
