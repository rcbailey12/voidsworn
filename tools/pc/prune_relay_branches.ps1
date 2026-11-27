# Issue 1657 (Ryan, Nov 22 2026): prune stale board/pc-out-* and board/pin-* branches from the main repo
# (rcbailey12/voidsworn: 22.66 GB and 701 branches on Nov 22, 316 pc-out and 133 pin). Results now go to the private
# relay repo (relay_push.ps1), so these branches only bloat the code repo.
#   prune_relay_branches.ps1            dry run (the default): writes the list it would delete, deletes nothing
#   prune_relay_branches.ps1 audit      compares live GitHub tips, prints results only
#   prune_relay_branches.ps1 audit-cached   compares local mirrors only, never gives permission to delete
#   prune_relay_branches.ps1 live       deletes only branches in the newest dry-run list that are still at the commit the
#                                       list names AND still pass every keep rule below, checked again now; asks Ryan
#                                       to type YES first
# A branch is KEPT when any of these holds:
#   1. it is named in voidsworn_test\prune\keep.txt (one branch per line; the Board writes the queued pins there);
#   2. a queued job names it (any file directly in a voidsworn_test\queue* folder);
#   3. its newest commit is under 3 days old;
#   4. an open pull request uses it;
#   5. board/pc-out-<job> while voidsworn_test\<job> still holds a checkout (repo folder, or a checkouts.txt entry that
#      still exists) or an attempt there names the branch in relay_branch.txt, relay_receipt.txt or relay_found.txt with a checkout left,
#      because the job's cleanup proves its relay from that branch before it frees the disk.
#   6. its tip's tracked paths, modes and object IDs are not all proven on the private relay.
# It deletes branches on GitHub only, never a file on this PC. Every run is logged in voidsworn_test\prune\.
param([string]$Mode = '')
$ErrorActionPreference = 'Stop'
$env:GIT_TERMINAL_PROMPT = '0'
$test = [bool]$env:PC_TEST_HELPER
if ($test) { $vt = $env:PC_TEST_HELPER_VT } else { $vt = Join-Path (Join-Path $env:USERPROFILE 'Downloads') 'voidsworn_test' }
$vt = [IO.Path]::GetFullPath($vt).TrimEnd('\', '/')
$source = 'https://github.com/rcbailey12/voidsworn'
$relaySource = 'https://github.com/rcbailey12/voidsworn-relay'
if ($test) {
  $source = $env:PC_TEST_SOURCE
  $relaySource = $env:PC_TEST_RELAY_SOURCE
  if (-not $source -or -not $relaySource) { throw 'test requires both Git sources' }
}
$mirror = Join-Path $vt 'repo-mirror.git'
$relayMirror = Join-Path $vt 'relay-mirror.git'
$unix = $PSVersionTable.Platform -eq 'Unix'
$gitExe = 'git.exe'; if ($unix) { $gitExe = @(Get-Command git -CommandType Application)[0].Source }
. (Join-Path $PSScriptRoot 'runner_common.ps1') publication-library
Set-PCGitNonInteractive
$net = @(PCGitNetworkOptions)
$days = 3
function Run-Git {
  $ErrorActionPreference = 'Continue'
  $out = & $gitExe @net @args 2>&1 | ForEach-Object { "$_" }
  if ($LASTEXITCODE -ne 0) { throw ('git failed: ' + ($args -join ' ') + ': ' + ($out -join ' ')) }; $out }
. (Join-Path $PSScriptRoot 'relay_branch_proof.ps1')
if ($Mode -and $Mode -notin @('live', 'audit', 'audit-cached')) { throw "unknown mode: $Mode" }
$legacyPattern = 'refs/heads/board/pc-out-*'
$relayPattern = 'refs/heads/pc-out-*'
if ($Mode -in @('audit','audit-cached')) {
  $cached = $Mode -eq 'audit-cached'
  $mainTips = Read-BranchTips $source $(if ($cached) { $mirror }) @($legacyPattern)
  $relayTips = Read-BranchTips $relaySource $(if ($cached) { $relayMirror }) @($relayPattern)
  Write-Output "$(if ($cached) { 'CACHE ONLY (not live proof)' } else { 'LIVE TIPS' }): $($mainTips.Count) legacy branches, $($relayTips.Count) relay branches"
  foreach ($name in ($mainTips.Keys | Sort-Object)) {
    Write-RelayProof $name $mainTips[$name] (Get-RelayProof $name $mainTips[$name] $relayTips $mirror $relayMirror)
  }
  exit 0
}
$live = $Mode -eq 'live'
$home1657 = Join-Path $vt 'prune'
if (-not (Test-Path -LiteralPath $home1657)) { $null = New-Item -ItemType Directory -Path $home1657 }
$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd_HHmmss')
$log = Join-Path $home1657 "prune_$(if ($live) { 'live' } else { 'dry' })_$stamp.log"
function Say($t) { Write-Output $t; Add-Content -LiteralPath $log -Value $t }

# What GitHub holds now: name -> commit
$remote = Read-BranchTips $source $null @($legacyPattern,'refs/heads/board/pin-*')
Say ("{0}: {1} board/pc-out and board/pin branches on GitHub" -f $stamp, $remote.Count)

# Decide each branch from the PC's state now. The dry run writes this; the live run decides again after Ryan types YES,
# refreshes the whole decision every 25 deletes, and rereads keep.txt and the queues just before each delete.
function Get-LocalKeep {
  # keep.txt lines and branches a queued job names: cheap file reads, so the live run rereads them before every delete.
  $keep = @{}
  $keepFile = Join-Path $home1657 'keep.txt'
  if (Test-Path -LiteralPath $keepFile) { foreach ($l in [IO.File]::ReadAllLines($keepFile)) { $t = $l.Trim(); if ($t) { $keep[$t] = 'in keep.txt' } } }
  foreach ($q in @(Get-ChildItem -LiteralPath $vt -Directory -Filter 'queue*' -ErrorAction SilentlyContinue)) {
    foreach ($f in @(Get-ChildItem -LiteralPath $q.FullName -File -ErrorAction SilentlyContinue)) {
      if ($f.Length -gt 1MB) { continue }
      foreach ($m in [regex]::Matches([IO.File]::ReadAllText($f.FullName), 'board/(?:pc-out|pin)-[A-Za-z0-9._-]+')) { if (-not $keep[$m.Value]) { $keep[$m.Value] = "named by queued job $($q.Name)\$($f.Name)" } }
    }
  }
  return $keep
}
function Get-Decision {
  # Every keep rule from the PC and GitHub as they stand now: @{ Prune = "name sha" rows; Why = name -> reason kept }.
  $keep = Get-LocalKeep
  # open pull requests (gh, when signed in; without it every branch an open PR could use is kept by age only)
  $openHeads = @{}
  $gh = Get-Command gh -ErrorAction SilentlyContinue
  if ($gh -and -not $test) {
    $ErrorActionPreference = 'Continue'
    $heads = & $gh.Source api --paginate 'repos/rcbailey12/voidsworn/pulls?state=open&per_page=100' --jq '.[].head.ref' 2>$null
    $ghOk = $LASTEXITCODE -eq 0; $ErrorActionPreference = 'Stop'
    if (-not $ghOk) { throw 'gh could not list open pull requests: nothing decided (sign in with gh auth login)' }
    foreach ($h in @($heads)) { $openHeads["$h".Trim()] = 1 }
  } elseif (-not $test) { throw 'gh is not installed: nothing decided' }
  if ($test -and $env:PC_TEST_OPEN_HEADS) { foreach ($h in $env:PC_TEST_OPEN_HEADS.Split(',')) { $openHeads[$h] = 1 } }
  # commit dates from the shared repo mirror (no download); a branch the mirror lacks is kept
  $dates = @{}
  if (Test-Path -LiteralPath (Join-Path $mirror 'HEAD')) {
    foreach ($l in @(Run-Git --git-dir $mirror for-each-ref '--format=%(refname:lstrip=2) %(objectname) %(committerdate:unix)' 'refs/heads/board/')) {
      if ("$l" -match '\A(\S+) ([0-9a-f]{40}) ([0-9]+)\z') { $dates[$Matches[1]] = @{ Sha = $Matches[2]; At = [long]$Matches[3] } }
    }
  }
  $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  # jobs on this PC that still hold a checkout
  function Test-HasCheckout($dir) {
    if (Test-Path -LiteralPath (Join-Path $dir 'repo')) { return $true }
    $ck = Join-Path $dir 'checkouts.txt'
    if (Test-Path -LiteralPath $ck -PathType Leaf) {
      foreach ($l in [IO.File]::ReadAllLines($ck)) { if ($l -match '\A([A-Za-z0-9_-]{1,40}) [0-9a-f]{40}\z' -and (Test-Path -LiteralPath (Join-Path $dir $Matches[1]))) { return $true } }
    }
    return $false
  }
  $busy = @{}
  foreach ($job in @(Get-ChildItem -LiteralPath $vt -Directory -ErrorAction SilentlyContinue)) {
    if ($job.Name -like 'queue*' -or $job.Name -like '*.git' -or $job.Name -eq 'prune') { continue }
    $held = Test-HasCheckout $job.FullName
    foreach ($a in @(Get-ChildItem -LiteralPath $job.FullName -Directory -ErrorAction SilentlyContinue)) {
      if (-not (Test-HasCheckout $a.FullName)) { continue }
      $held = $true
      foreach ($n in @('relay_branch.txt', 'relay_receipt.txt', 'relay_found.txt')) {
        $f = Join-Path $a.FullName $n
        if ((Test-Path -LiteralPath $f -PathType Leaf) -and ([string](Get-Content -LiteralPath $f -TotalCount 1)) -match '\A(board/pc-out-[A-Za-z0-9._-]+) ') { $busy[$Matches[1]] = "attempt $($a.FullName) still holds a checkout" }
      }
    }
    if ($held) { $busy["board/pc-out-$($job.Name)"] = "job folder $($job.FullName) still holds a checkout" }
  }
  $relayError = ''
  try { $relayTips = Read-BranchTips $relaySource $null @($relayPattern) }
  catch { $relayError = "live relay unavailable: $($_.Exception.Message)" }
  $prune = @(); $why = @{}
  $proofs = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
  foreach ($name in ($remote.Keys | Sort-Object)) {
    $sha = $remote[$name]
    if ($name.StartsWith('board/pc-out-', [StringComparison]::Ordinal) -and (-not $live -or $liveNames.Contains($name))) {
      $proofs[$name] = if ($relayError) { @{ State = 'unverified'; Detail = $relayError } }
                       else { Get-RelayProof $name $sha $relayTips $mirror $relayMirror }
      if (-not $live) { Write-RelayProof $name $sha $proofs[$name] | Add-Content -LiteralPath $log }
    }
    if ($keep[$name]) { $why[$name] = $keep[$name]; continue }
    if ($openHeads[$name]) { $why[$name] = 'an open pull request uses it'; continue }
    if ($busy[$name]) { $why[$name] = $busy[$name]; continue }
    $d = $dates[$name]
    if (-not $d -or $d.Sha -ne $sha) { $why[$name] = 'not in the PC repo mirror at this commit (age unknown)'; continue }
    if ($now - $d.At -lt $days * 86400) { $why[$name] = "newer than $days days"; continue }
    if ($name.StartsWith('board/pc-out-', [StringComparison]::Ordinal) -and $proofs[$name].State -ne 'covered') {
      $why[$name] = 'relay content not proven'; continue
    }
    $prune += "$name $sha"
  }
  return @{ Prune = $prune; Why = $why; Proofs = $proofs }
}


if ($live) {
  $lists = @(Get-ChildItem -LiteralPath $home1657 -Filter 'prune_list_*.txt' | Sort-Object Name)
  if (-not $lists.Count) { throw 'no dry-run list yet: run PRUNE_RELAY_BRANCHES_DRY.bat first' }
  $list = $lists[-1]
  $rows = @(foreach ($l in [IO.File]::ReadAllLines($list.FullName)) { if ($l -match '\A(board/(?:pc-out|pin)-[A-Za-z0-9._-]+) ([0-9a-f]{40})\z') { @{ Name = $Matches[1]; Sha = $Matches[2] } } })
  $liveNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  foreach ($r in $rows) { $null = $liveNames.Add($r.Name) }
  Say "list: $($list.Name), $($rows.Count) branch(es)"
  if (-not $rows.Count) { Say 'nothing to delete'; exit 0 }
  if (-not $test) {
    $answer = Read-Host "Delete these $($rows.Count) branches from GitHub? Type YES to go ahead"
    if ($answer -cne 'YES') { Say 'not confirmed: nothing deleted'; exit 1 }
  }
  # test only: the Board adds a keep line while the prompt waits
  if ($test -and $env:PC_TEST_AT_PROMPT) { Add-Content -LiteralPath (Join-Path $home1657 'keep.txt') -Value $env:PC_TEST_AT_PROMPT }
  # every protection again, decided only now, after YES (Artoo on PR 1672): a keep.txt line, a queued job, an open PR or a
  # checkout added since the dry run, or while the prompt waited, keeps the branch even though its commit did not move
  $done = 0; $kept = 0; $n = 0
  foreach ($r in $rows) {
    if ($n % 25 -eq 0) { $fresh = Get-Decision }
    $n++
    if ($remote[$r.Name] -ne $r.Sha) { Say "kept (moved or already gone since the dry run): $($r.Name)"; $kept++; continue }
    $local = Get-LocalKeep
    if ($local[$r.Name]) { Say "kept (now protected: $($local[$r.Name])): $($r.Name)"; $kept++; continue }
    if ($fresh.Why[$r.Name]) { Say "kept (now protected: $($fresh.Why[$r.Name])): $($r.Name)"; $kept++; continue }
    if ($fresh.Prune -cnotcontains "$($r.Name) $($r.Sha)") { Say "kept (no longer on a fresh dry-run list): $($r.Name)"; $kept++; continue }
    if ($fresh.Proofs[$r.Name]) {
      $paired = $r.Name.Substring('board/'.Length)
      $relayNow = Read-BranchTips $relaySource $null @("refs/heads/$paired")
      if ($relayNow[$paired] -cne $fresh.Proofs[$r.Name].Tip) {
        Say "kept (relay tip moved since proof): $($r.Name)"; $kept++; continue
      }
    }
    # only if GitHub still has it at the listed commit (a lease, so a branch a job pushed again since stays)
    $ErrorActionPreference = 'Continue'
    $o = & $gitExe @net push -q "--force-with-lease=refs/heads/$($r.Name):$($r.Sha)" $source ":refs/heads/$($r.Name)" 2>&1 | ForEach-Object { "$_" }
    $ok = $LASTEXITCODE -eq 0; $ErrorActionPreference = 'Stop'
    if ($ok) { $done++; Add-Content -LiteralPath $log -Value "deleted $($r.Name) $($r.Sha)" } else { $kept++; Say "kept (GitHub refused: $($o -join ' ')): $($r.Name)" }
  }
  Say "deleted $done branch(es), kept $kept; the list and this log are in $home1657"
  exit 0
}

$decision = Get-Decision; $prune = $decision.Prune; $why = $decision.Why
$listFile = Join-Path $home1657 "prune_list_$stamp.txt"
[IO.File]::WriteAllLines($listFile, [string[]]$prune)
foreach ($k in ($why.Keys | Sort-Object)) { Add-Content -LiteralPath $log -Value "keep $k ($($why[$k]))" }
foreach ($p in $prune) { Add-Content -LiteralPath $log -Value "would delete $p" }
Say ("dry run: would delete {0} branch(es), keep {1}. Nothing was deleted." -f $prune.Count, $why.Count)
Say "list: $listFile"
Say "log: $log"
