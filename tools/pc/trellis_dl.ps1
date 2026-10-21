# Download the TRELLIS.2 one-click Windows installer (IgorAherne/TRELLIS.2-stableprojectorz, release "latest") and unpack it to Downloads\trellis2.
$ErrorActionPreference = 'Stop'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$dl = Join-Path $env:USERPROFILE 'Downloads'; $dst = Join-Path $dl 'trellis2'; $log = Join-Path $dl 'voidsworn_test\trellis_dl.log'
function L($m){ $t = (Get-Date).ToString('HH:mm:ss'); Add-Content -Path $log -Value "$t $m" }
try {
  $r = Invoke-RestMethod -Uri 'https://api.github.com/repos/IgorAherne/TRELLIS.2-stableprojectorz/releases/tags/latest' -Headers @{ 'User-Agent' = 'voidsworn' }
  foreach($a in $r.assets){ L ("asset " + $a.name + " " + [math]::Round($a.size/1MB,1) + " MB " + $a.browser_download_url) }
  $z = $r.assets | Where-Object { $_.name -like '*.zip' } | Select-Object -First 1
  if(-not $z){ L 'no zip asset'; exit 1 }
  $out = Join-Path $dl $z.name
  if(-not (Test-Path $out)){ L ("downloading " + $z.name); Invoke-WebRequest -Uri $z.browser_download_url -OutFile $out -UseBasicParsing -Headers @{ 'User-Agent' = 'voidsworn' } }
  L ("got " + [math]::Round((Get-Item $out).Length/1MB,1) + " MB")
  if(-not (Test-Path $dst)){ New-Item -ItemType Directory -Path $dst | Out-Null }
  & tar -xf $out -C $dst; L ("unpacked to " + $dst)
  Get-ChildItem -Path $dst -Recurse -Depth 2 | Select-Object -First 60 | ForEach-Object { L ("  " + $_.FullName.Substring($dst.Length)) }
  $ins = Get-ChildItem -Path $dst -Recurse -Filter 'INSTRUCTIONS*' | Select-Object -First 1
  if($ins){ L '--- instructions ---'; Get-Content $ins.FullName | Select-Object -First 120 | ForEach-Object { L $_ } }
  L 'TRELLIS DL DONE'
} catch { L ("FAILED " + $_.Exception.Message) }
