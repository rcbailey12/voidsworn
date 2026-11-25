# Inspect the PC's Git caches. Default: no writes, locks, fetches or deletes.
# After the relay audit and upstream prune, the Board can run -Live with the lanes idle.
# Live only removes cached refs and runs GC with a grace period. It never pushes or touches local branches.
param([switch]$Live, [string]$Root = (Join-Path $env:USERPROFILE 'Downloads/voidsworn_test'))
$env:GIT_TERMINAL_PROMPT = '0'
. (Join-Path $PSScriptRoot 'runner_common.ps1') cleanup-library
. (Join-Path $PSScriptRoot 'relay_branch_proof.ps1')

function Run-Git {
  $rows = @(Git $args)
  if ($gitExit -ne 0) { throw "git $($args -join ' ') failed: $($rows -join ' ')" }
  $rows
}
function Read-CachedRefs($dir, $prefix) {
  foreach ($line in @(Run-Git --git-dir $dir for-each-ref '--format=%(objectname) %(refname)' $prefix)) {
    if ($line -notmatch '\A([0-9a-f]{40}) (\S+)\z') { throw "unexpected ref row in $dir" }
    [pscustomobject]@{ Sha = $Matches[1]; Ref = $Matches[2] }
  }
}
function Remove-CachedRefs($dir, $refs) {
  if (-not $refs.Count) { return }
  $exe = (Get-Command git -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
  $refs | ForEach-Object { "delete $($_.Ref) $($_.Sha)" } | & $exe --git-dir $dir update-ref --stdin
  if ($LASTEXITCODE -ne 0) { throw "cached refs changed in $dir; stop and preview again" }
}
function Invoke-Compaction($dir) {
  $words = Get-MirrorGcArgs $dir
  Run-Git @words
}
function Get-ProvenLegacyCopies($refs, $prefix, $dir, [switch]$UpstreamGone) {
  foreach ($ref in $refs) {
    $name = $ref.Ref.Substring($prefix.Length)
    $mainSha = $mainTips[$name]
    if ($UpstreamGone -and $mainSha) { continue }
    if ($mainSha -ceq $ref.Sha -or (Get-RelayProof $name $ref.Sha $relayTips $dir $relayMirror).State -eq 'covered') { $ref }
    else { Write-Host "kept $name in $dir : copied tip not proven elsewhere" }
  }
}

$Root = [IO.Path]::GetFullPath($Root)
Assert-PlainDirectory (Get-Item -LiteralPath $Root -Force)
$relayMirror = Join-Path $Root 'relay-mirror.git'
if ($Live) {
  if ([Environment]::OSVersion.Platform -ne 'Win32NT') { throw 'live compaction is for the Windows PC' }
  foreach ($queue in @('queue','queue_b')) {
    if (@(Get-ChildItem -LiteralPath (Join-Path $Root "$queue/running") -File -Filter '*.bat' -ErrorAction SilentlyContinue).Count) {
      throw "$queue has running jobs; wait until the PC is idle"
    }
  }
  if (@(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^(codex|opencode|git)\.exe$' }).Count) {
    throw 'Codex, OpenCode or Git is running; wait until the PC is idle'
  }
  $mainTips = Read-BranchTips 'https://github.com/rcbailey12/voidsworn' $null @('refs/heads/board/pc-out-*')
  $relayTips = Read-BranchTips 'https://github.com/rcbailey12/voidsworn-relay' $null @('refs/heads/pc-out-*')
}
Write-Output "$(if ($Live) { 'LIVE' } else { 'DRY RUN: nothing will change' }): $Root"

foreach ($mirror in @(Get-PcStorageMirrors $Root)) {
  $lease = $null
  try {
    if ($Live) { $lease = Open-MirrorWriterLock $mirror 'compact' 'prune cached pull refs and compact' 0 }
    $pull = @(Read-CachedRefs $mirror 'refs/pull/' | Where-Object { $_.Ref -cmatch '\Arefs/pull/[0-9]+/(head|merge)\z' })
    $relay = @(Read-CachedRefs $mirror 'refs/heads/board/pc-out-*')
    Write-Output "$mirror : $($pull.Count) cached PR refs to drop, $($relay.Count) legacy heads (live drops only upstream-pruned, proven copies)"
    if (-not $Live) { continue }
    # Keep the mirror safe for plain 'git fetch origin' as well as the explicit refspecs in the runners.
    Run-Git --git-dir $mirror config --replace-all remote.origin.fetch '+refs/heads/*:refs/heads/*'
    Run-Git --git-dir $mirror config --add remote.origin.fetch '+refs/tags/*:refs/tags/*'
    $drop = @(Get-ProvenLegacyCopies $relay 'refs/heads/' $mirror -UpstreamGone)
    Remove-CachedRefs $mirror ($pull + $drop)
    Invoke-Compaction $mirror
  } finally { if ($lease) { $lease.Dispose() } }
}

$laneNames = @('board','board_b','board_c','board_d','board_e','board_f',
  'work217/slot_deepseek','work217/slot_deepseekpro','work217/slot_kimi','work217/slot_kimicode',
  'work217/slot_sonnet','work217/slot_opus','work217/slot_openai')
foreach ($lane in $laneNames) {
  $repo = Join-Path $Root "$lane/repo"
  $dir = Join-Path $repo '.git'
  if (-not (Test-Path -LiteralPath $dir -PathType Container)) { continue }
  Assert-PlainDirectory (Get-Item -LiteralPath $dir -Force)
  $lease = $null
  try {
    if ($Live) { $lease = [IO.File]::Open("$repo.checkout.lock", 'OpenOrCreate', 'ReadWrite', 'None') }
    $cached = @(Read-CachedRefs $dir 'refs/remotes/origin/board/pc-out-*')
    Write-Output "$lane/repo : $($cached.Count) copied legacy refs (live drops only refs proven elsewhere)"
    if (-not $Live) { continue }
    $drop = @(Get-ProvenLegacyCopies $cached 'refs/remotes/origin/' $dir)
    Remove-CachedRefs $dir $drop
    Invoke-Compaction $dir
  } finally { if ($lease) { $lease.Dispose() } }
}
