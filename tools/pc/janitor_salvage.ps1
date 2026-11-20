# R339. Build and read back a backup before the janitor can remove a checkout with local work.
function Start-Utf8InputProcess($start) {
  # Issue 1335: PowerShell 5.1 (.NET Framework) writes redirected stdin in [Console]::InputEncoding and emits its
  # preamble when the process starts. Under code page 65001 that is a UTF-8 BOM, so git read '<BOM>create ...' and
  # every salvage on Nov 20 was kept. Newer .NET takes StandardInputEncoding; 5.1 needs the console encoding swapped
  # around the start. A preamble that is still there stops the call rather than corrupting the input.
  $noBom = New-Object Text.UTF8Encoding($false)
  if ($start.PSObject.Properties['StandardInputEncoding']) { $start.StandardInputEncoding = $noBom; return [Diagnostics.Process]::Start($start) }
  $saved = $null
  try { $saved = [Console]::InputEncoding; if ($saved.GetPreamble().Length) { [Console]::InputEncoding = $noBom } } catch { }
  try {
    if ([Console]::InputEncoding.GetPreamble().Length) { throw 'stdin encoding still writes a byte order mark; nothing started' }
    return [Diagnostics.Process]::Start($start)
  } finally {
    if ($saved -and $saved -ne [Console]::InputEncoding) { try { [Console]::InputEncoding = $saved } catch { } }
  }
}
function Salvage-Git([string[]]$words, [string[]]$inputLines) {
  $words = @('-c','core.longpaths=true') + $words
  if (-not $inputLines.Count) {
    $lines = @(Read-CleanupGit $words)
    if ($gitExit -ne 0) { throw "salvage Git failed ($($words -join ' ')): $($lines -join ' ')" }
    return $lines
  }
  # Git's stdin commands require LF. PowerShell 5.1 pipes CRLF to native commands.
  $start = New-Object Diagnostics.ProcessStartInfo
  $start.FileName = (Get-Command git -CommandType Application | Select-Object -First 1).Source
  $start.Arguments = ($words | ForEach-Object { Quote $_ }) -join ' '
  $start.UseShellExecute = $false
  $start.RedirectStandardInput = $true
  $start.RedirectStandardOutput = $true
  $start.RedirectStandardError = $true
  $child = Start-Utf8InputProcess $start
  try {
    $output = $child.StandardOutput.ReadToEndAsync()
    $errors = $child.StandardError.ReadToEndAsync()
    $child.StandardInput.Write(($inputLines -join "`n") + "`n")
    $child.StandardInput.Close()
    $child.WaitForExit()
    if ($child.ExitCode -ne 0) { throw "salvage Git failed ($($words -join ' ')): $($errors.GetAwaiter().GetResult().Trim())" }
    $output.GetAwaiter().GetResult().Trim() -split '\r?\n'
  } finally { $child.Dispose() }
}
function Set-SalvageObjects($gitDir, $objects) {
  $objects = Get-Item -LiteralPath $objects -Force
  Assert-PlainDirectory $objects
  Put (Join-Path $gitDir 'objects/info/alternates') ($objects.FullName.Replace('\','/') + "`n")
}
function Save-SalvageBundle($scratch, $backup, $mirror, $state, $objectFormat) {
  $updates = @(); $refs = @(); $parents = New-Object 'Collections.Generic.HashSet[string]'
  foreach ($line in $state.Local) {
    $id, $ancestry = $line -split ' ', 2
    $ref = "refs/salvage/$id"
    $updates += "create $ref $id"
    $refs += "$id $ref"
    foreach ($parent in ($ancestry -split ' ')) {
      if ($state.MirrorCommits.Contains($parent)) { $null = $parents.Add("^$parent") }
    }
  }
  $null = Salvage-Git @('-C',$scratch,'update-ref','--stdin') $updates
  $bundle = Join-Path $backup 'salvage.bundle'
  $command = @('-C',$scratch,'bundle','create',$bundle,'--glob=refs/salvage/*')
  if ($parents.Count) { $command += '--stdin' }
  $null = Salvage-Git $command @($parents)
  $null = Salvage-Git @('--git-dir',$mirror,'bundle','verify',$bundle)
  $found = @(Salvage-Git @('-C',$scratch,'bundle','list-heads',$bundle))
  if (Compare-Object $refs $found) { throw 'salvage bundle refs differ from local history' }

  # Unpack without the source objects, then check that every advertised commit is recoverable.
  $verify = Join-Path $scratch 'verify.git'
  $null = Salvage-Git @('init','--quiet','--bare',"--object-format=$objectFormat",$verify)
  Set-SalvageObjects $verify (Join-Path $mirror 'objects')
  $null = Salvage-Git @('--git-dir',$verify,'bundle','unbundle',$bundle)
  $null = Salvage-Git @('--git-dir',$verify,'update-ref','--stdin') $updates
  $null = Salvage-Git @('--git-dir',$verify,'fsck','--connectivity-only','--no-reflogs')
}
function Save-SalvageZip($repo, $backup, $state) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $paths = @(foreach ($line in $state.Status) {
    if (-not $line.StartsWith('?? ')) { continue }
    if ($line -notmatch '^\?\? ("?)([^"\\:\r\n]+)(?<!/)\1$') { throw "untracked path cannot be verified: $line" }
    $entry = $Matches[2]
    if ($entry -notin $state.Caches) { $entry }
  })
  $zip = Join-Path $backup 'untracked.zip'
  $archive = [IO.Compression.ZipFile]::Open($zip, 'Create')
  try {
    foreach ($path in $paths) {
      $file = Get-Item -LiteralPath (Join-Path $repo $path) -Force
      if ($file -isnot [IO.FileInfo] -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "untracked file could not be read: $path" }
      Assert-PlainDirectory $file.Directory
      $null = [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $path)
    }
  } finally { $archive.Dispose() }

  $archive = [IO.Compression.ZipFile]::OpenRead($zip)
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    if ($archive.Entries.Count -ne $paths.Count) { throw 'salvage zip file count differs' }
    foreach ($path in $paths) {
      $entry = $archive.GetEntry($path)
      if (-not $entry) { throw "salvage zip is missing $path" }
      $stream = $entry.Open()
      try { $digest = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','') }
      finally { $stream.Dispose() }
      if ($digest -ne (Get-FileHash -LiteralPath (Join-Path $repo $path) -Algorithm SHA256).Hash) { throw "salvage zip differs for $path" }
    }
  } finally { $sha.Dispose(); $archive.Dispose() }
}
function Save-CheckoutSalvage($repo, $mirror, $state, $dest) {
  $root = Split-Path -Parent $dest
  $dir = [IO.Directory]::CreateDirectory($root)
  Assert-PlainDirectory $dir
  $staging = Join-Path $root ".checking-$([guid]::NewGuid().ToString('N'))"
  $scratch = Join-Path $staging 'scratch'
  $backup = Join-Path $staging 'backup'
  $null = [IO.Directory]::CreateDirectory($backup)
  try {
    $index = @(Salvage-Git @('-C',$repo,'ls-files','--stage'))
    if ($index -match '^(?:160000 |[0-9]+ [0-9a-f]+ [123]\t)') { throw 'salvage cannot verify submodules or an unmerged index' }
    $head = @(Salvage-Git @('-C',$repo,'rev-parse','--verify','HEAD'))[0]
    $objectFormat = @(Salvage-Git @('-C',$repo,'rev-parse','--show-object-format'))[0]
    $null = Salvage-Git @('init','--quiet',"--object-format=$objectFormat",$scratch)
    Set-SalvageObjects (Join-Path $scratch '.git') (Join-Path $repo '.git/objects')
    # Load HEAD's tree in the scratch worktree index without copying the game assets into its working directory.
    $null = Salvage-Git @('-C',$scratch,'read-tree',$head)
    # Git diff can refresh the source's index even though the backup only needs to read it.
    $base = @('-C',$repo,'-c','diff.autoRefreshIndex=false','diff','--no-ext-diff','--no-textconv','--binary','--full-index','--no-color','--no-relative','--src-prefix=a/','--dst-prefix=b/')
    foreach ($name in @('salvage.patch','salvage-index.patch')) {
      $file = Join-Path $backup $name
      $options = if ($name -eq 'salvage-index.patch') { @('--cached') } else { @() }
      $null = Salvage-Git ($base + @($options) + @("--output=$file",$head,'--'))
      if ((Get-Item -LiteralPath $file).Length) {
        $null = Salvage-Git @('-C',$scratch,'apply','--check','--cached',$file)
      }
    }
    if ($state.Local.Count) { Save-SalvageBundle $scratch $backup $mirror $state $objectFormat }
    Save-SalvageZip $repo $backup $state
    Put (Join-Path $backup 'HEAD.txt') ($head + "`n")
    if (Cleanup-Paused) { throw 'PC pause is active' }
    # Directory.Move fails if a prior backup already exists. Never overwrite checked salvage.
    [IO.Directory]::Move($backup, $dest)
    foreach ($file in (Get-Item -LiteralPath $dest).EnumerateFiles()) { Log "salvage verified: $($file.FullName) ($($file.Length) bytes)" }
  } finally {
    try {
      $dir = Get-Item -LiteralPath $staging -Force
      Assert-NoLinkedChildren $staging
      Remove-CleanupDirectory $dir
    } catch { Log "salvage scratch kept: $staging ($($_.Exception.Message))" }
  }
}

# Issue 1180 run 7 (Artoo and the Board, PR 1260): ship and gen files the shared build looks to have superseded are kept
# once each in salvage\superseded_store\<sha256>.bin (the same D20_23.glb from three lanes is stored once), read back by
# size and SHA-256, and listed in a per-checkout manifest. Only the manifest folder is per checkout.
function Test-StoreEntry($file, $hash, $length) {
  return ($file -is [IO.FileInfo] -and -not ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -and
    $file.Length -eq $length -and (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLower() -eq $hash)
}
function Save-SupersededArchive($repo, $paths, $dest) {
  $root = Split-Path -Parent $dest
  $dir = [IO.Directory]::CreateDirectory($root)
  Assert-PlainDirectory $dir
  $store = [IO.Directory]::CreateDirectory((Join-Path $root 'superseded_store'))
  Assert-PlainDirectory $store
  $staging = Join-Path $root ".checking-$([guid]::NewGuid().ToString('N'))"
  $null = [IO.Directory]::CreateDirectory($staging)
  try {
    $manifest = @(); $bytes = 0L; $newBytes = 0L; $reused = 0
    foreach ($path in $paths) {
      $source = Get-Item -LiteralPath (Join-Path $repo $path) -Force
      if ($source -isnot [IO.FileInfo] -or ($source.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "archive source changed: $path" }
      $hash = (Get-FileHash -LiteralPath $source.FullName -Algorithm SHA256).Hash.ToLower()
      $blob = Join-Path $store.FullName "$hash.bin"
      $existing = Get-Item -LiteralPath $blob -Force -ErrorAction SilentlyContinue
      if ($existing) {
        if (-not (Test-StoreEntry $existing $hash $source.Length)) { throw "archive store entry does not match: $hash.bin" }
        $reused++
      } else {
        $part = Join-Path $staging "$hash.part"
        [IO.File]::Copy($source.FullName, $part, $false)
        if (-not (Test-StoreEntry (Get-Item -LiteralPath $part -Force) $hash $source.Length)) { throw "archive read-back failed: $path" }
        [IO.File]::Move($part, $blob)
        if (-not (Test-StoreEntry (Get-Item -LiteralPath $blob -Force) $hash $source.Length)) { throw "archive read-back failed: $path" }
        $newBytes += $source.Length
      }
      $manifest += "$hash  $($source.Length)  $path"
      $bytes += $source.Length
    }
    Put (Join-Path $staging 'superseded_manifest.txt') (($manifest -join "`n") + "`n")
    if (Cleanup-Paused) { throw 'PC pause is active' }
    # Directory.Move fails if an archive already exists. Never overwrite one.
    [IO.Directory]::Move($staging, $dest)
    Log "superseded archive verified: $dest ($($paths.Count) files, $bytes bytes; $newBytes new bytes in the shared store, $reused already stored)"
  } finally {
    if (Test-Path -LiteralPath $staging) {
      try { Remove-CleanupDirectory (Get-Item -LiteralPath $staging -Force) }
      catch { Log "archive scratch kept: $staging ($($_.Exception.Message))" }
    }
  }
}
