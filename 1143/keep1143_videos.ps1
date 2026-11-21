# Issue 1143, OPUS1143_REC1.bat step 5: keep the player path videos, check them, and only then clean up.
# The MAIN1 run (opus1457main1) deleted its AVI masters and all 17 MP4s before anyone had a copy. This step reverses
# that order:
#   a. checks every review MP4 and contact sheet in place (picture_provenance verify, under 8 MB, a full decode with no
#      errors) and checks each AVI master against its own provenance hash;
#   b. makes a 1080p H.264 copy of each AVI master (the full recording, kept small) and checks it decodes to the
#      master's length;
#   c. copies the review set, the 1080p masters, the traces and their provenance to a lasting folder outside every
#      janitor scan (Downloads\voidsworn_test\shots\player_path_1143\<pin>_<stamp>), then reads every copy back by sha256
#      and verifies the copied clips and sheets again;
#   d. only when a to c all pass, deletes the two raw AVI masters from this attempt's own player_path folder (the
#      verified 1080p copies replace them). -KeepAvi keeps them too. Any failure deletes nothing.
# The review MP4s and sheets also stay in the attempt folder, so the Board's results relay can push them.
param(
  [Parameter(Mandatory)][string]$Full,
  [Parameter(Mandatory)][string]$Repo,
  [Parameter(Mandatory)][string]$Python,
  [Parameter(Mandatory)][string]$Ffmpeg,
  [Parameter(Mandatory)][string]$Pin,
  [Parameter(Mandatory)][string]$Out,
  [switch]$KeepAvi
)
$ErrorActionPreference = 'Stop'
$vt = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$report = Join-Path $Out 'keep_report.txt'
$cleanup = Join-Path $Out 'video_cleanup.txt'
New-Item -ItemType Directory -Force -Path $Out | Out-Null
Set-Content -LiteralPath $report -Value "keep1143_videos.ps1 $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))" -Encoding utf8
function Say([string]$line) { Add-Content -LiteralPath $report -Value $line -Encoding utf8; Write-Host $line }
function Sha([string]$path) { (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant() }
function Fail([string]$why) {
  Say "FAILED: $why"
  Say 'nothing was deleted; every recording is still in the attempt folder'
  exit 1
}
function Duration([string]$path) {
  $ErrorActionPreference = 'Continue'
  $text = (& $Ffmpeg -hide_banner -nostdin -i $path 2>&1 | Out-String)
  $ErrorActionPreference = 'Stop'
  if ($text -notmatch 'Duration: (\d+):(\d+):(\d+(?:\.\d+)?)') { return -1 }
  return [double]$Matches[1] * 3600 + [double]$Matches[2] * 60 + [double]$Matches[3]
}
function DecodeErrors([string]$path) {
  $ErrorActionPreference = 'Continue'
  $text = (& $Ffmpeg -hide_banner -nostdin -v error -i $path -f null - 2>&1 | Out-String).Trim()
  $code = $LASTEXITCODE
  $ErrorActionPreference = 'Stop'
  if ($code) { return "ffmpeg exit $code $text" }
  return $text
}
function VerifyPictures([string[]]$paths, [string]$what) {
  $ErrorActionPreference = 'Continue'
  $text = (& $Python -B (Join-Path $Repo 'tools\picture_provenance.py') verify @paths 2>&1 | Out-String).Trim()
  $code = $LASTEXITCODE
  $ErrorActionPreference = 'Stop'
  if ($text) { Say $text }
  if ($code) { Fail "picture_provenance verify failed on the $what (exit $code)" }
  Say "picture_provenance verify passed: $($paths.Count) $what"
}
$env:FFMPEG = $Ffmpeg

# ---- a. what the recorder left, checked in place
$routes = [ordered]@{ 31 = 'hullbreakers'; 10 = 'navy' }
$review = Join-Path $Full 'review'
if (-not (Test-Path -LiteralPath $review)) { Fail "no review folder at $review" }
$pictures = @()
foreach ($seed in $routes.Keys) {
  $route = $routes[$seed]
  foreach ($name in "seed-$seed.avi", "seed-$seed.avi.provenance.json", "seed-$seed.jsonl") {
    if (-not (Test-Path -LiteralPath (Join-Path $Full $name))) { Fail "missing $name" }
  }
  $master = Join-Path $Full "seed-$seed.avi"
  $want = (Get-Content -LiteralPath "$master.provenance.json" -Raw | ConvertFrom-Json).image_sha256
  if ((Sha $master) -ne $want) { Fail "seed-$seed.avi differs from its provenance hash" }
  $win = @(Get-Content -LiteralPath (Join-Path $Full "seed-$seed.jsonl") | ForEach-Object { $_ | ConvertFrom-Json } |
    Where-Object { $_.kind -eq 'end_card' -and $_.result -eq 'win' } | ForEach-Object { $_.battle })
  if (($win -join ',') -ne '1,2,3') { Fail "seed-$seed.jsonl wins battles [$($win -join ',')], not 1,2,3" }
  Say ("master seed-{0}.avi: {1:N0} bytes, {2:N1} s, hash matches its provenance" -f $seed, (Get-Item -LiteralPath $master).Length, (Duration $master))
  foreach ($battle in 1, 2, 3) {
    $sheet = Join-Path $review "$route-b$battle.jpg"
    if (-not (Test-Path -LiteralPath $sheet)) { Fail "missing contact sheet $route-b$battle.jpg" }
    $pictures += $sheet
    $clips = @(Get-ChildItem -LiteralPath $review -Filter "$route-b$battle-p*.mp4" | Sort-Object Name)
    if (-not $clips.Count) { Fail "no clips for $route Battle $battle" }
    foreach ($clip in $clips) {
      if ($clip.Length -ge 8000000) { Fail "$($clip.Name) is $($clip.Length) bytes, over the 8 MB delivery limit" }
      $errors = DecodeErrors $clip.FullName
      if ($errors) { Fail "$($clip.Name) does not decode cleanly: $errors" }
      Say ("clip {0}: {1:N0} bytes, {2:N1} s, decodes cleanly" -f $clip.Name, $clip.Length, (Duration $clip.FullName))
      $pictures += $clip.FullName
    }
  }
}
VerifyPictures $pictures 'review clips and sheets in the attempt folder'

# ---- b. a 1080p H.264 copy of each master (the full recording the README names)
foreach ($seed in $routes.Keys) {
  $master = Join-Path $Full "seed-$seed.avi"
  $small = Join-Path $Full "seed-$seed-1080p.mp4"
  if (Test-Path -LiteralPath $small) { Fail "seed-$seed-1080p.mp4 already exists" }
  $ErrorActionPreference = 'Continue'
  & $Ffmpeg -hide_banner -nostdin -loglevel error -i $master -map 0:v:0 -map 0:a? -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -c:a aac -b:a 160k -movflags +faststart $small 2>&1 | Out-File -LiteralPath (Join-Path $Out "encode_seed-$seed.txt") -Encoding utf8
  $code = $LASTEXITCODE
  $ErrorActionPreference = 'Stop'
  if ($code -or -not (Test-Path -LiteralPath $small)) { Fail "the 1080p copy of seed-$seed.avi did not encode (exit $code)" }
  $errors = DecodeErrors $small
  if ($errors) { Fail "seed-$seed-1080p.mp4 does not decode cleanly: $errors" }
  $a = Duration $master; $b = Duration $small
  if ($a -le 0 -or [math]::Abs($a - $b) -gt 1.0) { Fail "seed-$seed-1080p.mp4 runs $b s but its master runs $a s" }
  $record = [ordered]@{ picture_name = "seed-$seed-1080p.mp4"; made_from = "seed-$seed.avi"; made_from_sha256 = (Sha $master);
    source_commit = $Pin; encode = 'libx264 crf 20 preset medium, aac 160k'; duration_s = $b; image_sha256 = (Sha $small) }
  $record | ConvertTo-Json | Set-Content -LiteralPath "$small.source.json" -Encoding utf8
  Say ("1080p copy seed-{0}-1080p.mp4: {1:N0} bytes, {2:N1} s (master {3:N1} s), decodes cleanly" -f $seed, (Get-Item -LiteralPath $small).Length, $b, $a)
}

# ---- c. the lasting copy, read back
$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$keep = Join-Path $vt ("shots\player_path_1143\{0}_{1}" -f $Pin.Substring(0, 8), $stamp)
New-Item -ItemType Directory -Force -Path (Join-Path $keep 'review') | Out-Null
$files = @(Get-ChildItem -LiteralPath $review -File) + @(Get-ChildItem -LiteralPath $Full -File | Where-Object { $_.Extension -ne '.avi' })
$manifest = @()
foreach ($file in $files) {
  $rel = $file.FullName.Substring($Full.TrimEnd('\').Length + 1)
  $dest = Join-Path $keep $rel
  Copy-Item -LiteralPath $file.FullName -Destination $dest
  $src = Sha $file.FullName; $got = Sha $dest
  if ($src -ne $got) { Fail "the lasting copy of $rel reads back different ($got, want $src)" }
  $manifest += "{0}`t{1}`t{2}" -f $rel, $file.Length, $got
}
$manifest | Set-Content -LiteralPath (Join-Path $keep 'keep_manifest.txt') -Encoding utf8
$manifest | Set-Content -LiteralPath (Join-Path $Out 'keep_manifest.txt') -Encoding utf8
Say "lasting copy: $keep ($($manifest.Count) files, every one read back by sha256)"
$kept = @(Get-ChildItem -LiteralPath (Join-Path $keep 'review') -File | Where-Object { $_.Extension -in '.mp4', '.jpg' } | ForEach-Object FullName)
if ($kept.Count -ne $pictures.Count) { Fail "the lasting copy has $($kept.Count) clips and sheets, the attempt folder $($pictures.Count)" }
VerifyPictures $kept 'review clips and sheets in the lasting copy'
foreach ($seed in $routes.Keys) {
  $errors = DecodeErrors (Join-Path $keep "seed-$seed-1080p.mp4")
  if ($errors) { Fail "the lasting seed-$seed-1080p.mp4 does not decode cleanly: $errors" }
}
Say 'lasting 1080p copies decode cleanly'
Set-Content -LiteralPath (Join-Path $Out 'keep_path.txt') -Value $keep -Encoding utf8

# ---- d. only now: the raw AVI masters in this attempt's own folder
if ($KeepAvi) {
  Set-Content -LiteralPath $cleanup -Value 'nothing deleted: -KeepAvi' -Encoding utf8
} else {
  $lines = @("raw AVI masters removed only after the checks above passed; lasting copies in $keep")
  foreach ($seed in $routes.Keys) {
    $master = Join-Path $Full "seed-$seed.avi"
    $bytes = (Get-Item -LiteralPath $master).Length
    Remove-Item -LiteralPath $master
    $lines += "Deleted file - $master ($bytes bytes); replaced by seed-$seed-1080p.mp4 (verified)"
  }
  $lines += 'every review MP4 and contact sheet was kept, here and in the lasting copy'
  $lines | Set-Content -LiteralPath $cleanup -Encoding utf8
}
$drive = New-Object IO.DriveInfo ([IO.Path]::GetPathRoot($vt))
Say ("drive bytes free after: {0:N0}" -f $drive.AvailableFreeSpace)
Say 'KEEP PASS'
exit 0
