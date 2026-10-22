# Download free CC0 PBR material sets from ambientCG (license: CC0, free for any use) for the ship texture pass.
# Saves 2K JPG sets to Downloads\voidsworn_test\textures\<AssetId>\ and writes textures\index.csv. Safe to re-run (skips existing).
$ProgressPreference = 'SilentlyContinue'
$out = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test\textures'; New-Item -ItemType Directory -Force -Path $out | Out-Null
$queries = @('painted metal','rust','metal plates','scratched metal','corrugated steel','diamond plate','grime','metal')
$rows = @(); $seen = @{}
foreach ($q in $queries) {
  try { $j = Invoke-RestMethod -Uri ("https://ambientcg.com/api/v2/full_json?type=Material&limit=6&sort=Popular&include=downloadData&q=" + [uri]::EscapeDataString($q)) } catch { "query failed: $q $_"; continue }
  foreach ($a in $j.foundAssets) {
    $id = $a.assetId; if ($seen[$id]) { continue }; $seen[$id] = 1
    $dl = $a.downloadFolders.default.downloadFiletypeCategories.zip.downloads | Where-Object { $_.attribute -eq '2K-JPG' } | Select-Object -First 1
    if (-not $dl) { continue }
    $dir = Join-Path $out $id; $zip = Join-Path $out ($id + '.zip')
    if (-not (Test-Path $dir)) {
      try { Invoke-WebRequest -Uri $dl.fullDownloadPath -OutFile $zip -UseBasicParsing; Expand-Archive -Path $zip -DestinationPath $dir -Force; Remove-Item $zip } catch { "download failed: $id $_"; continue }
    }
    $rows += [pscustomobject]@{ id = $id; query = $q; mb = [math]::Round($dl.size / 1MB, 1); page = "https://ambientcg.com/view?id=$id"; license = 'CC0' }
    "got $id ($q)"
  }
}
$rows | Export-Csv -NoTypeInformation -Path (Join-Path $out 'index.csv')
"textures: " + $rows.Count
