# Issue 1657 (Ryan, Nov 22 2026): send one PC job attempt's results to the private relay repo rcbailey12/voidsworn-relay,
# branch pc-out-<job>, with the attempt folder at <attempt folder name>/ in its tree, instead of a board/pc-out branch of
# the main repo (22.66 GB with 316 such branches on Nov 22). The layout is the one opus_job_head.ps1 proves before it
# removes a checkout (relay_branch.txt "relay/pc-out-<job> <attempt folder name>").
#   relay_push.bat <job> <attempt folder> [dry | leftovers]
# leftovers adds only checkout_leftovers to an existing private relay. It checks that all other
# attempt results are already there. For a custom location, pass the branch suffix as <job> and -TreePath to the ps1.
# Sends out and out_* folders and the small text files at the attempt's top (status, done, logs). When the attempt is
# itself out or out_*, sends its result subfolders. Never sends a checkout. A file over 10 MB stays on the PC and is
# listed in <attempt folder name>/skipped_over_10MB.txt as
# "<path with \> <size> MB", the form the proof reads. Godot cache folders stay on the PC and are listed by their
# attempt-relative paths in relay_manifest/skipped_cache_folders.txt. dry lists what would go and changes nothing. It deletes nothing,
# on the PC or on GitHub. Prints the branch link and the picture and video links for the PR comment.
param([Parameter(Mandatory)][string]$Job, [Parameter(Mandatory)][string]$Attempt, [string]$Mode = '',
      [string]$TreePath = '', [string]$ProvenTip = '')
$ErrorActionPreference = 'Stop'
$test = [bool]$env:PC_TEST_HELPER
$unix = $PSVersionTable.Platform -eq 'Unix'
if ($test) { $vt = $env:PC_TEST_HELPER_VT } else { $vt = Join-Path (Join-Path $env:USERPROFILE 'Downloads') 'voidsworn_test' }
$vt = [IO.Path]::GetFullPath($vt).TrimEnd('\', '/')
$relayMirror = Join-Path $vt 'relay-mirror.git'
$relaySource = 'https://github.com/rcbailey12/voidsworn-relay'
if ($test) { $relaySource = $env:PC_TEST_RELAY_SOURCE }
$web = 'https://github.com/rcbailey12/voidsworn-relay'
# Issue 1739: git prints names as UTF-8 (core.quotepath=false); Windows PowerShell 5.1 would read them in the console's
# OEM code page, so a non-ASCII name would never match in the tree check. A process with no console may refuse the change.
try { [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false) } catch { }
$gitExe = 'git.exe'; if ($unix) { $gitExe = @(Get-Command git -CommandType Application)[0].Source }
$gitLongPaths = @('-c', 'core.longpaths=true')
$OutputEncoding = New-Object System.Text.UTF8Encoding $false
function Run-Git {
  $ErrorActionPreference = 'Continue'
  $out = & $gitExe @gitLongPaths @args 2>&1 | ForEach-Object { "$_" }
  if ($LASTEXITCODE -ne 0) { throw ('git failed: ' + ($args -join ' ') + ': ' + ($out -join ' ')) }; $out }
function Run-GitChunks($fixed, $items) {
  # Issue 1739: no stdin into git at all. Windows PowerShell 5.1 changed what reached git's stdin twice over (CRLF lines,
  # then a UTF-8 byte order mark before the first path that .NET Framework's redirected stdin writes on start), so the
  # paths and index entries go as arguments, in calls kept well under Windows' 32,767-character command line.
  # An item may be a group of arguments that must stay in one call (--cacheinfo and its value).
  $out = @(); $chunk = @(); $len = 0
  foreach ($it in $items) {
    $group = @($it | ForEach-Object { "$_" }); $glen = ($group | Measure-Object -Property Length -Sum).Sum + 3 * $group.Count
    if ($chunk.Count -and $len + $glen -gt 6000) { $out += @(Run-Git @fixed @chunk); $chunk = @(); $len = 0 }
    $chunk += $group; $len += $glen
  }
  if ($chunk.Count) { $out += @(Run-Git @fixed @chunk) }
  $out
}
function Test-CheckoutRoot($dir) {
  # A worktree's .git is a file. A Voidsworn checkout can also have its project one level down in godot/.
  if ((Test-Path -LiteralPath (Join-Path $dir.FullName '.git')) -or
      (Test-Path -LiteralPath (Join-Path $dir.FullName 'project.godot') -PathType Leaf)) { return $true }
  $godot = Get-Item -LiteralPath (Join-Path $dir.FullName 'godot') -Force -ErrorAction Ignore
  if ($godot -is [IO.DirectoryInfo] -and -not ($godot.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    return (Test-Path -LiteralPath (Join-Path $godot.FullName 'project.godot') -PathType Leaf)
  }
  return $false
}
function Assert-BackfillSource($parent) {
  $have = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
  foreach ($line in @(Run-Git --git-dir $relayMirror -c core.quotepath=false ls-tree -r -t $parent -- "$leaf/")) {
    if ($line -notmatch '\A(\d+) (?:blob|tree|commit) ([0-9a-f]{40})\t(.+)\z') { continue }
    $have[$Matches[3]] = if ($Matches[1] -in @('100644', '100755')) { $Matches[2] } else { '' }
  }
  $verify = $originals.ToArray()
  if ($skippedCaches.Count) {
    $manifest = $have["$leaf/relay_manifest/skipped_cache_folders.txt"]
    $listed = if ($manifest) { @(Run-Git --git-dir $relayMirror cat-file -p $manifest) }
    $pending = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'
    foreach ($k in $skippedCaches) {
      if ($listed -ccontains $k -and -not $have.ContainsKey("$leaf/$k")) { continue }
      $pending.Push([IO.DirectoryInfo]::new((Join-Path $full $k)))
    }
    # An older relay may have sent these folders. Prove their files normally when the tip does not exclude them.
    $extra = @(while ($pending.Count) {
      $dir = $pending.Pop()
      if ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "a link in the results: $($dir.FullName)" }
      if (Test-Path -LiteralPath (Join-Path $dir.FullName '.git') -PathType Container) { continue }
      foreach ($e in $dir.EnumerateFileSystemInfos()) {
        if ($e.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "a link in the results: $($e.FullName)" }
        if ($e -is [IO.DirectoryInfo]) { $pending.Push($e) } else { $e }
      }
    })
    $verify += $extra
  }
  if (-not $verify.Count) { throw 'no original result files to prove the relay' }
  $keys = @(foreach ($file in $verify) {
    $key = "$leaf/" + $file.FullName.Substring($full.Length + 1).Replace('\', '/')
    if ($file.Length -gt 100MB -or -not $have.ContainsKey($key)) { throw "original result missing or different on $branch`: $key" }
    $key
  })
  $shas = @(Run-GitChunks @('--git-dir', $relayMirror, 'hash-object', '--no-filters', '--') @($verify | ForEach-Object { $_.FullName }))
  if ($shas.Count -ne $keys.Count) { throw 'original result hashes could not be read' }
  for ($i = 0; $i -lt $keys.Count; $i++) {
    if ($have[$keys[$i]] -ne $shas[$i]) { throw "original result missing or different on $branch`: $($keys[$i])" }
  }
}

if ($Mode -and $Mode -notin @('dry', 'leftovers')) { throw "the third argument may only be dry or leftovers, got: $Mode" }
$dry = $Mode -eq 'dry'
$leftovers = $Mode -eq 'leftovers'
if (($TreePath -or $ProvenTip) -and -not $leftovers) { throw 'TreePath and ProvenTip require leftovers mode' }
if ($ProvenTip -and $ProvenTip -cnotmatch '\A[0-9a-f]{40}\z') { throw 'invalid proven relay tip' }
if ($Job -notmatch '\A[A-Za-z0-9._-]{1,80}\z' -or $Job.Contains('..')) { throw "not a job name: $Job" }
$at = Get-Item -LiteralPath $Attempt -Force
if (-not $at.PSIsContainer -or ($at.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "not a plain folder: $Attempt" }
$full = $at.FullName.TrimEnd('\', '/')
if (-not $full.StartsWith($vt + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw "the attempt must be inside $vt" }
# No link anywhere from voidsworn_test down to the attempt (Artoo on PR 1672): an ancestor junction would make the
# lexical inside-check above meaningless.
$walk = $at.Parent
while ($walk -and $walk.FullName.TrimEnd('\', '/').Length -gt $vt.Length) {
  if ($walk.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "a link on the way to the attempt: $($walk.FullName)" }
  $walk = $walk.Parent
}
if ((Get-Item -LiteralPath $vt -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "voidsworn_test itself is a link: $vt" }
$leaf = $at.Name
if ($leaf -notmatch '\A[A-Za-z0-9._-]+\z' -or $leaf -eq '..') { throw "not an attempt folder name: $leaf" }
if ($TreePath) {
  if ($TreePath -notmatch '\A[A-Za-z0-9._-]+(?:/[A-Za-z0-9._-]+)*\z' -or $TreePath.Contains('..')) { throw "invalid relay tree folder: $TreePath" }
  $leaf = $TreePath
}
$branch = "pc-out-$Job"
# one push stays well under GitHub's 2 GiB push limit (Artoo on PR 1672); tests set a tiny limit
$batchBytes = 512MB
if ($test -and $env:PC_TEST_RELAY_BATCH_BYTES) { $batchBytes = [long]$env:PC_TEST_RELAY_BATCH_BYTES }

# For backfill, check the attempt files the janitor can count as results, skipping Git checkouts.
# The job head already proved its out files before cleanup and supplies the exact tip it saw.
$files = New-Object 'Collections.Generic.List[object]'
$originals = New-Object 'Collections.Generic.List[object]'
$receipt = Join-Path $full 'relay_receipt.txt'
$cacheNames = @('profile', 'shader_cache', '.godot')
$leftoverNames = @('checkout_leftovers', 'checkout_leftovers_repo')
$skippedCaches = New-Object 'Collections.Generic.List[string]'
if (-not $leftovers -and ($at.Name -in $leftoverNames -or (Test-CheckoutRoot $at))) {
  throw "not a results folder: $full"
}
foreach ($e in @($at.EnumerateFiles())) {
  if ($leftovers) {
    if ($ProvenTip) { continue }
    if ($e.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "a link in the results: $($e.FullName)" }
    $originals.Add($e)
  } elseif ($e.Extension -in @('.txt', '.log', '.json', '.csv', '.md') -and -not ($e.Attributes -band [IO.FileAttributes]::ReparsePoint)) { $files.Add($e) }
}
if ($ProvenTip) { $roots = @($at.EnumerateDirectories('out_*')) }
else {
  $top = @($at.EnumerateDirectories())
  foreach ($d in $top) {
    if ($d.Name -notin $cacheNames) { continue }
    if ($leftovers -and ($d.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "a link in the results: $($d.FullName)" }
    $skippedCaches.Add($d.Name)
  }
  $useSubfolders = $leftovers -or $at.Name -eq 'out' -or $at.Name -like 'out_*'
  $roots = @($top | Where-Object { $_.Name -notin $cacheNames -and
    ($useSubfolders -or $_.Name -eq 'out' -or $_.Name -like 'out_*') })
}
foreach ($d in $roots) {
  # Each result folder is checked before the walk enters it, like every folder below it.
  if ($d.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "a link in the results: $($d.FullName)" }
  $pending = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'
  if ($ProvenTip) {
    $saved = Get-Item -LiteralPath (Join-Path $d.FullName 'checkout_leftovers') -Force -ErrorAction SilentlyContinue
    if (-not $saved) { continue }
    if ($saved -isnot [IO.DirectoryInfo] -or ($saved.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "not a plain leftovers folder: $($saved.FullName)" }
    $pending.Push($saved)
  } else { $pending.Push($d) }
  while ($pending.Count) {
    $dir = $pending.Pop()
    if (-not $leftovers -and ($dir.Name -in $leftoverNames -or (Test-CheckoutRoot $dir))) { continue }
    $relDir = $dir.FullName.Substring($full.Length + 1).Replace('\', '/')
    $savedFiles = $relDir -match '\Aout_[^/]+/checkout_leftovers(?:/|\z)'
    if ($leftovers -and -not $savedFiles -and (Test-Path -LiteralPath (Join-Path $dir.FullName '.git') -PathType Container)) { continue }
    foreach ($e in @($dir.EnumerateFileSystemInfos())) {
      if ($e.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "a link in the results: $($e.FullName)" }
      if ($e -is [IO.DirectoryInfo]) {
        # Issue 1830: prune the subtree before enumeration. Profile shader cache paths can exceed MAX_PATH.
        if (-not $savedFiles -and $e.Name -in $cacheNames) { $skippedCaches.Add($e.FullName.Substring($full.Length + 1).Replace('\', '/')) }
        else { $pending.Push($e) }
      }
      elseif (-not $leftovers -or $savedFiles) { $files.Add($e) }
      else { $originals.Add($e) }
    }
  }
}
if ($leftovers -and -not $files.Count) { Write-Output "no checkout leftovers in $full"; exit 0 }
if (-not $files.Count -and -not $skippedCaches.Count) { throw "nothing to relay in $full (no result files)" }
$send = @(); $skipped = @()
foreach ($f in $files) {
  $rel = $f.FullName.Substring($full.Length + 1)
  if ($leftovers -and $f.Length -gt 10MB) { throw "checkout leftovers exceed the relay's 10 MB file limit: $rel" }
  if ($f.Length -gt 10MB) { $skipped += ('{0} {1} MB' -f $rel.Replace('/', '\'), ($f.Length / 1MB).ToString('0.0', [Globalization.CultureInfo]::InvariantCulture)); continue }
  $send += @{ Path = $f.FullName; Key = "$leaf/" + $rel.Replace('\', '/') }
}
# batches go in path order, so a relay that stops partway always stops at the same file
$send = @($send | Sort-Object -CaseSensitive { $_.Key })
$mb = (($files | Measure-Object -Property Length -Sum).Sum / 1MB)
Write-Output ("relay: {0} file(s) to {1} branch {2} under {3}/ ({4:N1} MB in all), {5} over 10 MB kept on the PC" -f $send.Count, $web, $branch, $leaf, $mb, $skipped.Count)
if ($dry) {
  foreach ($s in ($send | Select-Object -First 40)) { Write-Output "  would send $($s.Key)" }
  foreach ($k in $skipped) { Write-Output "  would list as skipped: $k" }
  foreach ($k in ($skippedCaches | Sort-Object -CaseSensitive)) { Write-Output "  would list as skipped: $k (Godot cache folder)" }
  Write-Output 'dry run: nothing sent'
  exit 0
}

# The relay repo's own mirror, under its own writers' lock (the one opus_job_head.ps1 takes).
$lock = $null; $deadline = [DateTime]::UtcNow.AddMinutes(30)
while (-not $lock) {
  try { $lock = [IO.File]::Open($relayMirror + '.lock', 'OpenOrCreate', 'ReadWrite', 'None') }
  catch [IO.IOException] { if ([DateTime]::UtcNow -ge $deadline) { throw 'relay repo copy stayed locked for 30 minutes' }; Start-Sleep -Milliseconds 500 }
}
$index = Join-Path ([IO.Path]::GetTempPath()) ("voidsworn-relay-index-" + [guid]::NewGuid().ToString('N'))
$receiptDraft = $null
$receiptLine = "relay/$branch $leaf"
try {
  if (-not (Test-Path -LiteralPath (Join-Path $relayMirror 'HEAD'))) {
    Run-Git init -q --bare $relayMirror | Out-Null
    Run-Git --git-dir $relayMirror remote add --mirror=fetch origin $relaySource | Out-Null
  }
  if ((Run-Git --git-dir $relayMirror config --get remote.origin.url) -ne $relaySource) { throw 'relay repo copy has an unexpected origin' }
  $env:GIT_INDEX_FILE = $index
  $env:GIT_AUTHOR_NAME = 'voidsworn PC relay'; $env:GIT_AUTHOR_EMAIL = 'relay@voidsworn.invalid'
  $env:GIT_COMMITTER_NAME = $env:GIT_AUTHOR_NAME; $env:GIT_COMMITTER_EMAIL = $env:GIT_AUTHOR_EMAIL
  if ($ProvenTip) {
    $existing = Get-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue
    if ($existing) {
      if ($existing -isnot [IO.FileInfo] -or ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
          [IO.File]::ReadAllText($receipt).TrimEnd() -cne $receiptLine) { throw "existing receipt names a different relay or is not a plain file: $receipt" }
      $receiptBlob = $receipt
    } else {
      $receiptDraft = $index + '.receipt'
      [IO.File]::WriteAllText($receiptDraft, "$receiptLine`r`n")
      $receiptBlob = $receiptDraft
    }
    # The janitor counts the local receipt too. Put those exact bytes on the branch before creating it locally.
    $send += @{ Path = $receiptBlob; Key = "$leaf/relay_receipt.txt" }
  }
  # Artoo on PR 1672: GitHub refuses a push over 2 GiB, so the files go in batches of at most $batchBytes, one commit and one
  # push each, each built on the branch tip the last one left. The proof (opus_job_head.ps1) needs every file in the final
  # tree, so a relay stopped between batches proves nothing and frees nothing; running it again resends the attempt whole.
  $batches = New-Object 'Collections.Generic.List[object]'; $cur = @(); $curBytes = 0
  foreach ($s1 in $send) {
    $len = (Get-Item -LiteralPath $s1.Path -Force).Length
    if ($cur.Count -and $curBytes + $len -gt $batchBytes) { $batches.Add($cur); $cur = @(); $curBytes = 0 }
    $cur += $s1; $curBytes += $len
  }
  $batches.Add($cur)
  for ($b = 0; $b -lt $batches.Count; $b++) {
    $part = @($batches[$b]); $last = $b -eq $batches.Count - 1
    for ($try = 0; $try -lt 2; $try++) {
      Run-Git --git-dir $relayMirror -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 fetch -q --prune --no-auto-maintenance --no-tags --refmap= origin '+refs/heads/*:refs/heads/*' '+refs/tags/*:refs/tags/*' | Out-Null
      $ErrorActionPreference = 'Continue'
      $parent = (& $gitExe @gitLongPaths --git-dir $relayMirror rev-parse --verify -q "refs/heads/$branch^{commit}" 2>$null) | Select-Object -Last 1
      $ErrorActionPreference = 'Stop'
      if ($leftovers) {
        if (-not $parent) { throw "no existing relay branch: $branch" }
        if ($ProvenTip -and $parent -ne $ProvenTip) { throw "relay branch $branch moved after proof. Run the leftovers backfill." }
        if (-not $ProvenTip -and $parent -ne $commit) { Assert-BackfillSource $parent }
      }
      if (Test-Path -LiteralPath $index) { Remove-Item -LiteralPath $index -Force }
      if ($parent) {
        Run-Git --git-dir $relayMirror read-tree $parent | Out-Null
        # the first batch of a resend replaces the attempt's folder whole; later batches add to what the earlier ones sent
        if ($b -eq 0 -and -not $leftovers) {
          $old = @(Run-Git --git-dir $relayMirror -c core.quotepath=false ls-files -- "$leaf/")
          if ($old.Count) {
            # --force-remove wants a work tree; an empty one of our own, so nothing outside the index is ever read
            $empty = Join-Path ([IO.Path]::GetTempPath()) ("voidsworn-relay-empty-" + [guid]::NewGuid().ToString('N'))
            $null = [IO.Directory]::CreateDirectory($empty)
            try { Run-GitChunks @('--git-dir', $relayMirror, '--work-tree', $empty, 'update-index', '--force-remove', '--') $old | Out-Null }
            finally { [IO.Directory]::Delete($empty) }
          }
        }
      } else { Run-Git --git-dir $relayMirror read-tree --empty | Out-Null }
      $shas = @(Run-GitChunks @('--git-dir', $relayMirror, 'hash-object', '-w', '--no-filters', '--') @($part | ForEach-Object { $_.Path }))
      if ($shas.Count -ne $part.Count) { throw "hashed $($shas.Count) of $($part.Count) files" }
      $info = @(for ($i = 0; $i -lt $part.Count; $i++) { "100644,$($shas[$i]),$($part[$i].Key)" })
      if ($last -and -not $leftovers -and ($skipped.Count -or $skippedCaches.Count)) {
        $tmpList = Join-Path ([IO.Path]::GetTempPath()) ("voidsworn-relay-skipped-" + [guid]::NewGuid().ToString('N') + '.txt')
        $manifests = @(
          @{ Key = 'skipped_over_10MB.txt'; Lines = $skipped }
          @{ Key = 'relay_manifest/skipped_cache_folders.txt'; Lines = @($skippedCaches | Sort-Object -CaseSensitive) }
        )
        try {
          foreach ($manifest in $manifests) {
            if (-not $manifest.Lines.Count) { continue }
            [IO.File]::WriteAllText($tmpList, (($manifest.Lines -join "`r`n") + "`r`n"))
            $ls = (Run-Git --git-dir $relayMirror hash-object -w --no-filters -- $tmpList) | Select-Object -Last 1
            $info += "100644,$ls,$leaf/$($manifest.Key)"
          }
        } finally {
          if (Test-Path -LiteralPath $tmpList) { Remove-Item -LiteralPath $tmpList -Force }
        }
      }
      Run-GitChunks @('--git-dir', $relayMirror, 'update-index', '--add') @($info | ForEach-Object { ,@('--cacheinfo', $_) }) | Out-Null
      $tree = (Run-Git --git-dir $relayMirror write-tree) | Select-Object -Last 1
      # issue 1739: never push a tree that lost files on the way in (a pushed empty tree was a silent PASS)
      $inTree = @{}; foreach ($n in @(Run-Git --git-dir $relayMirror -c core.quotepath=false ls-tree -r --name-only $tree)) { $inTree["$n"] = $true }
      $lost = @($part | Where-Object { -not $inTree.ContainsKey($_.Key) })
      if ($lost.Count) { throw "the relay tree is missing $($lost.Count) of $($part.Count) files, first $($lost[0].Key); nothing pushed" }
      if ($leftovers -and $tree -eq (Run-Git --git-dir $relayMirror rev-parse "${parent}^{tree}")) { $commit = $parent; break }
      $msg = "relay $Job $leaf (part $($b + 1) of $($batches.Count), $($part.Count) files)"
      if ($parent) { $commit = (Run-Git --git-dir $relayMirror commit-tree $tree -p $parent -m $msg) | Select-Object -Last 1 }
      else { $commit = (Run-Git --git-dir $relayMirror commit-tree $tree -m $msg) | Select-Object -Last 1 }
      # The leftovers commit is a child of the proved tip. Require that exact tip so a concurrent deletion cannot recreate it.
      $lease = @()
      if ($leftovers) { $lease = @("--force-with-lease=refs/heads/${branch}:$parent") }
      $ErrorActionPreference = 'Continue'
      $pushOut = & $gitExe @gitLongPaths --git-dir $relayMirror push -q @lease origin "${commit}:refs/heads/$branch" 2>&1 | ForEach-Object { "$_" }
      $pushed = $LASTEXITCODE -eq 0; $ErrorActionPreference = 'Stop'
      if ($pushed) { break }
      if ($try) { throw "push of part $($b + 1) of $($batches.Count) to $branch refused: $($pushOut -join ' '). Nothing is proven until every part is sent; run the relay again." }
      Write-Output "push of part $($b + 1) refused once (another relay moved $branch); fetching and trying again"
    }
    if ($ProvenTip) { $ProvenTip = $commit }
    if ($batches.Count -gt 1) { Write-Output "sent part $($b + 1) of $($batches.Count) ($($part.Count) files)" }
  }
  Run-Git --git-dir $relayMirror update-ref "refs/heads/$branch" $commit | Out-Null
  $remote = @(Run-Git ls-remote $relaySource "refs/heads/$branch") | Select-Object -First 1
  if (-not $remote -or "$remote".Substring(0, 40) -ne $commit) { throw "the relay repo does not show $branch at $commit after the push" }
  if ($receiptDraft) {
    $localReceipt = [IO.File]::Open($receipt, 'CreateNew', 'Write', 'None')
    try { $bytes = [IO.File]::ReadAllBytes($receiptDraft); $localReceipt.Write($bytes, 0, $bytes.Length) } finally { $localReceipt.Dispose() }
    Write-Output "relay receipt written: $receiptLine"
  }
} finally {
  Remove-Item Env:\GIT_INDEX_FILE -ErrorAction SilentlyContinue
  if (Test-Path -LiteralPath $index) { Remove-Item -LiteralPath $index -Force }
  if ($receiptDraft -and (Test-Path -LiteralPath $receiptDraft)) { Remove-Item -LiteralPath $receiptDraft -Force }
  $lock.Dispose()
}
Write-Output "relayed: $($send.Count) file(s) on $branch at $commit; $($skipped.Count) over 10 MB listed as skipped"
Write-Output "receipt place: relay/$branch $leaf"
Write-Output "folder link: $web/tree/$branch/$leaf"
$pics = @($send | Where-Object { $_.Key -match '\.(png|jpe?g|gif|webp|mp4|webm)\z' } | Select-Object -First 30)
foreach ($p in $pics) {
  $escaped = (($p.Key -split '/') | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
  Write-Output ("picture link: {0}/blob/{1}/{2}" -f $web, $commit, $escaped)
}
if ($pics.Count -eq 30) { Write-Output 'picture links: first 30 shown; the folder link has the rest' }
