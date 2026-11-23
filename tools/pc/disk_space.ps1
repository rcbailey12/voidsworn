# Issue 1739 (Board, Nov 23 03:22 janitor dry run): the janitor said 49.9 GB would come back and about 4.6 GB did.
# Two causes: a checkout's files are often hard links shared with the mirror or another checkout, so removing them frees
# nothing, and the Codex sandbox account owns folders the janitor's account cannot delete. These helpers let a size say
# what would really be freed. Windows PowerShell 5.1 and pwsh (Linux for the tests). Read only; nothing here deletes.
# Dot-source this file; it defines functions only.

function Initialize-DiskSpaceNative {
  if ($script:diskSpaceNative -ne $null) { return $script:diskSpaceNative }
  $script:diskSpaceNative = $false
  if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { return $false }
  try {
    if (-not ('VoidswornFileIdentity' -as [type])) {
      Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
public static class VoidswornFileIdentity {
  // BY_HANDLE_FILE_INFORMATION: 52 bytes, the link count at offset 40. Each FILETIME is two 32-bit halves; a long would
  // be 8-byte aligned and shift every later field (Artoo on PR 1812).
  [StructLayout(LayoutKind.Sequential)] public struct Info {
    public uint attributes;
    public uint createdLow, createdHigh, accessedLow, accessedHigh, writtenLow, writtenHigh;
    public uint volume, sizeHigh, sizeLow, links, indexHigh, indexLow;
  }
  [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
  static extern SafeFileHandle CreateFileW(string name, uint access, uint share, IntPtr security, uint mode, uint flags, IntPtr template);
  [DllImport("kernel32.dll", SetLastError = true)]
  static extern bool GetFileInformationByHandle(SafeFileHandle handle, out Info info);
  // Returns "volume:index links", or null when the file cannot be opened for its attributes.
  public static string Get(string path) {
    // 0x80 FILE_READ_ATTRIBUTES; share read, write and delete; OPEN_EXISTING; FILE_FLAG_BACKUP_SEMANTICS for folders.
    using (SafeFileHandle h = CreateFileW(@"\\?\" + path, 0x80, 7, IntPtr.Zero, 3, 0x02000000, IntPtr.Zero)) {
      if (h.IsInvalid) return null;
      Info i;
      if (!GetFileInformationByHandle(h, out i)) return null;
      return i.volume.ToString("x") + ":" + ((((ulong)i.indexHigh) << 32) | i.indexLow).ToString("x") + " " + i.links;
    }
  }
}
'@
    }
    $script:diskSpaceNative = $true
  } catch { $script:diskSpaceNative = $false }
  return $script:diskSpaceNative
}

function Get-FileIdentity([string]$path) {
  # @{ Id = '<volume>:<index>'; Links = <hard link count> }, or $null when it cannot be read.
  if (Initialize-DiskSpaceNative) {
    $text = $null
    try { $text = [VoidswornFileIdentity]::Get($path) } catch { $text = $null }
    if (-not $text) { return $null }
    $parts = $text.Split(' ')
    return @{ Id = $parts[0]; Links = [int]$parts[1] }
  }
  if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { return $null }
  # pwsh off Windows: the provider's UnixStat (in process; a stat process per file made the fixtures time out).
  try { $st = (Get-Item -LiteralPath $path -Force -ErrorAction Stop).UnixStat } catch { return $null }
  if (-not $st) { return $null }
  return @{ Id = "$($st.DeviceId):$($st.Inode)"; Links = [int]$st.HardlinkCount }
}

function Get-CurrentAccountIds {
  if ($script:currentAccountIds) { return $script:currentAccountIds }
  $ids = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
  if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
    $me = [Security.Principal.WindowsIdentity]::GetCurrent()
    $null = $ids.Add($me.User.Value)
    # A folder owned by a group in this account's token (Administrators, when the account made it elevated) is ours.
    foreach ($g in $me.Groups) { $null = $ids.Add($g.Value) }
  } else {
    $null = $ids.Add(([string](& id -u)).Trim())
  }
  $script:currentAccountIds = $ids
  return $ids
}

function Get-FolderOwner($directory) {
  # The owner's SID (Windows) or uid (Linux), or '' when it cannot be read.
  try {
    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
      $sections = [Security.AccessControl.AccessControlSections]::Owner
      $acl = if ($directory.PSObject.Methods['GetAccessControl']) { $directory.GetAccessControl($sections) }
        else { [IO.FileSystemAclExtensions]::GetAccessControl($directory, $sections) }
      return $acl.GetOwner([Security.Principal.SecurityIdentifier]).Value
    }
    $st = (Get-Item -LiteralPath $directory.FullName -Force -ErrorAction Stop).UnixStat
    if (-not $st) { return '' }
    return [string]$st.UserId
  } catch { return '' }
}

function Select-OtherAccountFolders($directories) {
  # The folders of a batch another account owns.
  return @(@($directories) | Where-Object { Test-OtherAccountFolder $_ })
}

function Test-OtherAccountFolder($directory) {
  # True when another account owns the folder, so this account may not be able to delete it (the Codex sandbox scratch).
  $owner = Get-FolderOwner $directory
  if (-not $owner) { return $false }
  return -not (Get-CurrentAccountIds).Contains($owner)
}

function New-FreeTally {
  # Adds up what removing a set of files would free: a file counts once per identity, and only when every hard link to it
  # is in the set. Unchecked files (no identity) are kept apart, never guessed.
  return [pscustomobject]@{ Listed = 0L; Free = 0L; Unchecked = 0L; Shared = @{} }
}

function Get-FileIdentities($files) {
  # Path -> identity for a batch of files.
  $map = @{}
  foreach ($f in @($files)) { $map[$f.FullName] = Get-FileIdentity $f.FullName }
  return $map
}

function Add-FreeTallyBatch($tally, $files) {
  $ids = Get-FileIdentities $files
  foreach ($f in @($files)) { Add-FreeTally $tally $f $ids[$f.FullName] -Known }
}

function Add-FreeTally($tally, $file, $identity = $null, [switch]$Known) {
  $length = [long]$file.Length
  $tally.Listed += $length
  if (-not $Known) { $identity = Get-FileIdentity $file.FullName }
  if (-not $identity) { $tally.Unchecked += $length; return }
  if ($identity.Links -le 1) { $tally.Free += $length; return }
  $entry = $tally.Shared[$identity.Id]
  if (-not $entry) { $entry = @{ Length = $length; Links = $identity.Links; Seen = 0 }; $tally.Shared[$identity.Id] = $entry }
  $entry.Seen++
}

function Complete-FreeTally($tally) {
  # @{ Listed; Free; SharedOutside; Unchecked } in bytes. A shared file whose links are all in the set is freed once.
  $free = $tally.Free; $outside = 0L
  foreach ($entry in $tally.Shared.Values) {
    if ($entry.Seen -ge $entry.Links) { $free += $entry.Length } else { $outside += $entry.Length * $entry.Seen }
  }
  return [pscustomobject]@{ Listed = $tally.Listed; Free = $free; SharedOutside = $outside; Unchecked = $tally.Unchecked }
}

function Format-FreeBytes($stats) {
  # "<free> bytes would be freed, <listed> listed, ...": the first number is what removal gives back, the rest says why it is smaller.
  $parts = @("$($stats.FreeBytes) bytes would be freed", "$($stats.Bytes) listed")
  if ($stats.SharedBytes) { $parts += "$($stats.SharedBytes) in hard links shared outside it" }
  if ($stats.UncheckedBytes) { $parts += "$($stats.UncheckedBytes) not checked for hard links, left out" }
  return ($parts -join ', ')
}
