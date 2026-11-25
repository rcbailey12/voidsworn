# R455. Runs in the same Codex Windows sandbox as the agent, before its lane and issue locks are released.
# Grant the runner account access to sandbox-created items only. Never change ownership or touch shared hard links.
param([string]$Out, [string]$Repo, [string]$RunnerSid, [switch]$RemoveScratch, [switch]$LibraryOnly)

. (Join-Path $PSScriptRoot 'runner_common.ps1') cleanup-library
function Grant-SandboxCleanupAcl($item, $ownerSid, $runner) {
  if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or (Get-FolderOwner $item) -ne $ownerSid.Value) { return }
  # Git's pack files may have another name in the mirror. A file ACL belongs to the inode, not the path.
  if ($item -is [IO.FileInfo]) {
    $identity = Get-FileIdentity $item.FullName
    if (-not $identity -or $identity.Links -ne 1) { return }
  }
  if (Cleanup-Paused) { throw 'PC pause is active' }
  $acl = $item.GetAccessControl([Security.AccessControl.AccessControlSections]::Access)
  $rights = [Security.AccessControl.FileSystemRights]'ReadAndExecute, Delete, WriteAttributes'
  if ($item -is [IO.DirectoryInfo]) { $rights = $rights -bor [Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles }
  $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($runner, $rights, 'Allow'))
  if (-not (Initialize-DiskSpaceNative)) { throw 'Windows DACL helper unavailable' }
  [VoidswornFileIdentity]::SetCleanupDacl($item.FullName, $acl.GetSecurityDescriptorBinaryForm())
}
if ($LibraryOnly) { return }
if (-not $Out -or -not $Repo -or -not $RunnerSid) { throw 'handoff requires the run, its checkout and the runner account' }
$sid = [Security.Principal.SecurityIdentifier]::new($RunnerSid)
$me = [Security.Principal.WindowsIdentity]::GetCurrent()
$sandboxAccounts = @('CodexSandboxOffline','CodexSandboxOnline')
if (($me.Name -split '\\')[-1] -notin $sandboxAccounts -or $me.User.Equals($sid)) {
  throw 'handoff did not run as the Codex sandbox account'
}
$pcRoot = [IO.Path]::GetFullPath((Join-Path $env:USERPROFILE 'Downloads/voidsworn_test'))
$repoDir = Get-Item -LiteralPath ([IO.Path]::GetFullPath($Repo)) -Force
Assert-PlainDirectory $repoDir
Assert-PlainDirectory $repoDir.Parent
if ($repoDir.Name -ne 'repo' -or $repoDir.Parent.Name -notmatch '\Aboard(?:_[b-f])?\z' -or
    $repoDir.Parent.Parent.FullName -ne $pcRoot) { throw 'handoff must name the active checkout in a Codex lane' }
$outDir = Get-Item -LiteralPath $Out -Force
Assert-PlainDirectory $outDir
if ($outDir.Parent.FullName -ne $repoDir.Parent.FullName -or
    $outDir.Name -ne "issue-$env:PC_RUNNER_LOCKED_ISSUE") { throw 'handoff must name this issue in the same lane' }
$status = Get-Item -LiteralPath (Join-Path $outDir.FullName 'status.json') -Force
if ($status -isnot [IO.FileInfo] -or ($status.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'status is not a plain file' }
$record = ([IO.File]::ReadAllText($status.FullName) | ConvertFrom-Json).scratch
$scratch = Get-OwnedScratch $record $env:PC_RUN_SCRATCH
if (-not $scratch) { throw 'scratch owner record did not match' }
Assert-PlainDirectory (Get-Item -LiteralPath $pcRoot -Force)
Assert-PlainDirectory $scratch.Parent
if (Cleanup-Paused) { throw 'PC pause is active' }
if ($RemoveScratch) {
  if (Get-BoardKeepReason $scratch.FullName) { throw 'scratch is on the Board keep list' }
  Assert-NoLinkedChildren $scratch.FullName
  Remove-CleanupDirectory $scratch
  Write-Host "run scratch removed by its sandbox: $($scratch.FullName)"
  exit 0
}

$failed = 0
foreach ($root in @($scratch, $repoDir)) {
  if (Get-BoardKeepReason $root.FullName) { continue }
  $todo = New-Object 'Collections.Generic.Stack[IO.FileSystemInfo]'
  $todo.Push($root)
  while ($todo.Count) {
    $item = $todo.Pop()
    try {
      Grant-SandboxCleanupAcl $item $me.User $sid
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
