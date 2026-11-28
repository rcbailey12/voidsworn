# R455. Runs in the same Codex Windows sandbox as the agent, before its lane and issue locks are released.
# Grant the runner account access to sandbox-created items only. Never change ownership or touch shared hard links.
param([string]$Out, [string]$Repo, [string]$RunnerSid, [string]$PcRoot, [string]$ScratchRoot,
  [switch]$RemoveScratch, [switch]$LibraryOnly)

. (Join-Path $PSScriptRoot 'runner_common.ps1') cleanup-library
function Grant-SandboxCleanupAcl($item, $ownerSid, $runner, $pcRoot) {
  if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or (Get-FolderOwner $item) -ne $ownerSid.Value) { return }
  # Git's pack files may have another name in the mirror. A file ACL belongs to the inode, not the path.
  if ($item -is [IO.FileInfo]) {
    $identity = Get-FileIdentity $item.FullName
    if (-not $identity -or $identity.Links -ne 1) { return }
  }
  if (Cleanup-Paused $pcRoot) { throw 'PC pause is active' }
  $acl = $item.GetAccessControl([Security.AccessControl.AccessControlSections]::Access)
  $rights = [Security.AccessControl.FileSystemRights]'ReadAndExecute, Delete, WriteAttributes'
  if ($item -is [IO.DirectoryInfo]) { $rights = $rights -bor [Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles }
  $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($runner, $rights, 'Allow'))
  if (-not (Initialize-DiskSpaceNative)) { throw 'Windows DACL helper unavailable' }
  [VoidswornFileIdentity]::SetCleanupDacl($item.FullName, $acl.GetSecurityDescriptorBinaryForm())
}
function Get-SandboxHandoffTargets($out, $repo, $pcRoot, $scratchRoot, $expectedScratch, $issue) {
  # These roots come from the locked host runner. The sandbox profile is not the host profile.
  if (-not $pcRoot -or -not $scratchRoot -or -not $expectedScratch -or $issue -notmatch '\A[1-9][0-9]*\z') {
    throw 'handoff requires the host roots and the locked run'
  }
  $hostDir = Get-Item -LiteralPath ([IO.Path]::GetFullPath($pcRoot)) -Force
  Assert-PlainDirectory $hostDir
  $repoDir = Get-Item -LiteralPath ([IO.Path]::GetFullPath($repo)) -Force
  Assert-PlainDirectory $repoDir
  if ($repoDir.Name -ne 'repo' -or $repoDir.Parent.Name -notmatch '\Aboard(?:_[b-f])?\z' -or
      $repoDir.Parent.Parent.FullName -ne $hostDir.FullName) { throw 'handoff must name the active checkout in a Codex lane' }
  $outDir = Get-Item -LiteralPath ([IO.Path]::GetFullPath($out)) -Force
  Assert-PlainDirectory $outDir
  if ($outDir.Parent.FullName -ne $repoDir.Parent.FullName -or $outDir.Name -ne "issue-$issue") {
    throw 'handoff must name this issue in the same lane'
  }
  $status = Get-Item -LiteralPath (Join-Path $outDir.FullName 'status.json') -Force
  if ($status -isnot [IO.FileInfo] -or ($status.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'status is not a plain file' }
  $record = ([IO.File]::ReadAllText($status.FullName) | ConvertFrom-Json).scratch
  $scratch = Get-OwnedScratch $record $expectedScratch $scratchRoot
  if (-not $scratch -or $scratch.Name -notmatch "\Avoidsworn-run-$issue-[0-9a-f]{32}\z") {
    throw 'scratch owner record did not match the locked issue'
  }
  return [pscustomobject]@{ PcRoot = $hostDir.FullName; Repo = $repoDir; Scratch = $scratch }
}
if ($LibraryOnly) { return }
if (-not $Out -or -not $Repo -or -not $RunnerSid) { throw 'handoff requires the run, its checkout and the runner account' }
$sid = [Security.Principal.SecurityIdentifier]::new($RunnerSid)
$me = [Security.Principal.WindowsIdentity]::GetCurrent()
$sandboxAccounts = @('CodexSandboxOffline','CodexSandboxOnline')
if (($me.Name -split '\\')[-1] -notin $sandboxAccounts -or $me.User.Equals($sid)) {
  throw 'handoff did not run as the Codex sandbox account'
}
$targets = Get-SandboxHandoffTargets $Out $Repo $PcRoot $ScratchRoot $env:PC_RUN_SCRATCH $env:PC_RUNNER_LOCKED_ISSUE
$pcRoot = $targets.PcRoot
$scratch = $targets.Scratch
if (Cleanup-Paused $pcRoot) { throw 'PC pause is active' }
$script:boardKeep = Read-BoardKeepList (Join-Path $pcRoot 'janitor_keep.txt')
if ($RemoveScratch) {
  if (Get-BoardKeepReason $scratch.FullName) { throw 'scratch is on the Board keep list' }
  Assert-NoLinkedChildren $scratch.FullName
  Remove-CleanupDirectory $scratch $pcRoot
  Write-Host "run scratch removed by its sandbox: $($scratch.FullName)"
  exit 0
}

$failed = 0
foreach ($root in @($scratch, $targets.Repo)) {
  if (Get-BoardKeepReason $root.FullName) { continue }
  $todo = New-Object 'Collections.Generic.Stack[IO.FileSystemInfo]'
  $todo.Push($root)
  while ($todo.Count) {
    $item = $todo.Pop()
    try {
      Grant-SandboxCleanupAcl $item $me.User $sid $pcRoot
    } catch {
      $failed++
      Write-Host "sandbox handoff kept $($item.FullName) ($($_.Exception.Message))"
    }
    if ($item -is [IO.DirectoryInfo] -and -not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
      try { foreach ($child in $item.EnumerateFileSystemInfos()) { $todo.Push($child) } }
      catch { $failed++; Write-Host "sandbox handoff could not list $($item.FullName)" }
    }
  }
}
if ($failed) { exit 1 }
Write-Host 'sandbox scratch and checkout ACL handoff complete'
