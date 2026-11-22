# Issue 1657 (Ryan, Nov 22 2026): send one PC job attempt's results to the private relay repo rcbailey12/voidsworn-relay,
# branch pc-out-<job>, with the attempt folder at <attempt folder name>/ in its tree, instead of a board/pc-out branch of
# the main repo (22.66 GB with 316 such branches on Nov 22). The layout is the one opus_job_head.ps1 proves before it
# removes a checkout (relay_branch.txt "relay/pc-out-<job> <attempt folder name>").
#   relay_push.bat <job> <attempt folder> [dry]
# Sends the attempt's out_* folders and the small text files at its top (status, done, logs). Never a checkout or any
# other folder. A file over 10 MB stays on the PC and is listed in <attempt folder name>/skipped_over_10MB.txt as
# "<path with \> <size> MB", the form the proof reads. dry lists what would go and changes nothing. It deletes nothing,
# on the PC or on GitHub. Prints the branch link and the picture and video links for the PR comment.
param([Parameter(Mandatory)][string]$Job, [Parameter(Mandatory)][string]$Attempt, [string]$Mode = '')
$ErrorActionPreference = 'Stop'
$test = [bool]$env:PC_TEST_HELPER
$unix = $PSVersionTable.Platform -eq 'Unix'
if ($test) { $vt = $env:PC_TEST_HELPER_VT } else { $vt = Join-Path (Join-Path $env:USERPROFILE 'Downloads') 'voidsworn_test' }
$vt = [IO.Path]::GetFullPath($vt).TrimEnd('\', '/')
$relayMirror = Join-Path $vt 'relay-mirror.git'
$relaySource = 'https://github.com/rcbailey12/voidsworn-relay'
if ($test) { $relaySource = $env:PC_TEST_RELAY_SOURCE }
$web = 'https://github.com/rcbailey12/voidsworn-relay'
$gitExe = 'git.exe'; if ($unix) { $gitExe = @(Get-Command git -CommandType Application)[0].Source }
$OutputEncoding = New-Object System.Text.UTF8Encoding $false
function Run-Git {
  $ErrorActionPreference = 'Continue'
  $out = & $gitExe @args 2>&1 | ForEach-Object { "$_" }
  if ($LASTEXITCODE -ne 0) { throw ('git failed: ' + ($args -join ' ') + ': ' + ($out -join ' ')) }; $out }
function Run-GitIn($lines) {
  # git with lines on stdin (hash-object --stdin-paths, update-index --index-info)
  $ErrorActionPreference = 'Continue'
  $a = $args
  $out = $lines | & $gitExe @a 2>&1 | ForEach-Object { "$_" }
  if ($LASTEXITCODE -ne 0) { throw ('git failed: ' + ($a -join ' ') + ': ' + ($out -join ' ')) }; $out }

if ($Mode -and $Mode -ne 'dry') { throw "the third argument may only be dry, got: $Mode" }
$dry = $Mode -eq 'dry'
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
$branch = "pc-out-$Job"
# one push stays well under GitHub's 2 GiB push limit (Artoo on PR 1672); tests set a tiny limit
$batchBytes = 512MB
if ($test -and $env:PC_TEST_RELAY_BATCH_BYTES) { $batchBytes = [long]$env:PC_TEST_RELAY_BATCH_BYTES }

# What goes: top-level text files and every file under out_* folders (links refused, not followed).
$files = New-Object 'Collections.Generic.List[object]'
foreach ($e in @($at.EnumerateFiles())) {
  if ($e.Extension -in @('.txt', '.log', '.json', '.csv', '.md') -and -not ($e.Attributes -band [IO.FileAttributes]::ReparsePoint)) { $files.Add($e) }
}
foreach ($d in @($at.EnumerateDirectories('out_*'))) {
  # each out_* folder is checked before the walk enters it, like every folder below it
  if ($d.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "a link in the results: $($d.FullName)" }
  $pending = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'; $pending.Push($d)
  while ($pending.Count) {
    foreach ($e in @($pending.Pop().EnumerateFileSystemInfos())) {
      if ($e.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "a link in the results: $($e.FullName)" }
      if ($e -is [IO.DirectoryInfo]) { $pending.Push($e) } else { $files.Add($e) }
    }
  }
}
if (-not $files.Count) { throw "nothing to relay in $full (no out_* files)" }
$send = @(); $skipped = @()
foreach ($f in $files) {
  $rel = $f.FullName.Substring($full.Length + 1)
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
try {
  if (-not (Test-Path -LiteralPath (Join-Path $relayMirror 'HEAD'))) {
    Run-Git init -q --bare $relayMirror | Out-Null
    Run-Git --git-dir $relayMirror remote add --mirror=fetch origin $relaySource | Out-Null
  }
  if ((Run-Git --git-dir $relayMirror config --get remote.origin.url) -ne $relaySource) { throw 'relay repo copy has an unexpected origin' }
  $env:GIT_INDEX_FILE = $index
  $env:GIT_AUTHOR_NAME = 'voidsworn PC relay'; $env:GIT_AUTHOR_EMAIL = 'relay@voidsworn.invalid'
  $env:GIT_COMMITTER_NAME = $env:GIT_AUTHOR_NAME; $env:GIT_COMMITTER_EMAIL = $env:GIT_AUTHOR_EMAIL
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
      Run-Git --git-dir $relayMirror -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 fetch -q --prune origin | Out-Null
      $ErrorActionPreference = 'Continue'
      $parent = (& $gitExe --git-dir $relayMirror rev-parse --verify -q "refs/heads/$branch^{commit}" 2>$null) | Select-Object -Last 1
      $ErrorActionPreference = 'Stop'
      if (Test-Path -LiteralPath $index) { Remove-Item -LiteralPath $index -Force }
      if ($parent) {
        Run-Git --git-dir $relayMirror read-tree $parent | Out-Null
        # the first batch of a resend replaces the attempt's folder whole; later batches add to what the earlier ones sent
        if ($b -eq 0) {
          $old = @(Run-Git --git-dir $relayMirror -c core.quotepath=false ls-files -- "$leaf/")
          if ($old.Count) { Run-GitIn @($old | ForEach-Object { "0 0000000000000000000000000000000000000000`t$_" }) --git-dir $relayMirror update-index --index-info | Out-Null }
        }
      } else { Run-Git --git-dir $relayMirror read-tree --empty | Out-Null }
      $shas = @(Run-GitIn @($part | ForEach-Object { $_.Path }) --git-dir $relayMirror hash-object -w --no-filters --stdin-paths)
      if ($shas.Count -ne $part.Count) { throw "hashed $($shas.Count) of $($part.Count) files" }
      $info = for ($i = 0; $i -lt $part.Count; $i++) { "100644 $($shas[$i])`t$($part[$i].Key)" }
      if ($last -and $skipped.Count) {
        $tmpList = Join-Path ([IO.Path]::GetTempPath()) ("voidsworn-relay-skipped-" + [guid]::NewGuid().ToString('N') + '.txt')
        [IO.File]::WriteAllText($tmpList, (($skipped -join "`r`n") + "`r`n"))
        $ls = (Run-Git --git-dir $relayMirror hash-object -w --no-filters -- $tmpList) | Select-Object -Last 1
        Remove-Item -LiteralPath $tmpList -Force
        $info = @($info) + "100644 $ls`t$leaf/skipped_over_10MB.txt"
      }
      Run-GitIn @($info) --git-dir $relayMirror update-index --add --index-info | Out-Null
      $tree = (Run-Git --git-dir $relayMirror write-tree) | Select-Object -Last 1
      $msg = "relay $Job $leaf (part $($b + 1) of $($batches.Count), $($part.Count) files)"
      if ($parent) { $commit = (Run-Git --git-dir $relayMirror commit-tree $tree -p $parent -m $msg) | Select-Object -Last 1 }
      else { $commit = (Run-Git --git-dir $relayMirror commit-tree $tree -m $msg) | Select-Object -Last 1 }
      $ErrorActionPreference = 'Continue'
      $pushOut = & $gitExe --git-dir $relayMirror push -q origin "${commit}:refs/heads/$branch" 2>&1 | ForEach-Object { "$_" }
      $pushed = $LASTEXITCODE -eq 0; $ErrorActionPreference = 'Stop'
      if ($pushed) { break }
      if ($try) { throw "push of part $($b + 1) of $($batches.Count) to $branch refused: $($pushOut -join ' '). Nothing is proven until every part is sent; run the relay again." }
      Write-Output "push of part $($b + 1) refused once (another relay moved $branch); fetching and trying again"
    }
    if ($batches.Count -gt 1) { Write-Output "sent part $($b + 1) of $($batches.Count) ($($part.Count) files)" }
  }
  Run-Git --git-dir $relayMirror update-ref "refs/heads/$branch" $commit | Out-Null
  $remote = @(Run-Git ls-remote $relaySource "refs/heads/$branch") | Select-Object -First 1
  if (-not $remote -or "$remote".Substring(0, 40) -ne $commit) { throw "the relay repo does not show $branch at $commit after the push" }
} finally {
  Remove-Item Env:\GIT_INDEX_FILE -ErrorAction SilentlyContinue
  if (Test-Path -LiteralPath $index) { Remove-Item -LiteralPath $index -Force }
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
