# Run a program with a ceiling (PC watchdog). Agent runs also stop when progress stalls (issue 818).
# The program's output goes to this window (so "tmo.bat ... > log.txt 2>&1" captures it).
# Call it through tools\pc\tmo.bat <seconds> <exe> [args ...]: the bat hands the whole command line over in TMO_ARGS, so
# arguments that start with "-" or "--" reach the program untouched (PowerShell would read them as its own parameters).
param([switch]$LibraryOnly)
$ErrorActionPreference = 'Stop'

# runner_stall_tests.js runs this decision with fake clocks on Linux CI and probes real processes on Windows.
function Get-StopReason($Elapsed, $Idle, $Ceiling, $StallMinutes) {
  if ($Elapsed -ge $Ceiling) { return 'CEILING' }
  if ($Idle -ge ($StallMinutes * 60)) { return "STALLED after $StallMinutes min" }
  return ''
}
function Get-RunProgress($Repo, $Logs) {
  $files = @{}
  $dirs = New-Object 'System.Collections.Generic.Stack[string]'
  $dirs.Push($Repo)
  while ($dirs.Count) {
    foreach ($f in (Get-ChildItem -LiteralPath $dirs.Pop() -Force -ErrorAction SilentlyContinue)) {
      # Reading git status may touch its index; Git housekeeping must not keep a silent agent alive.
      # Do not follow junctions outside this run's checkout.
      if ($f.Name -eq '.git' -or ($f.Attributes -band [IO.FileAttributes]::ReparsePoint)) { continue }
      if ($f.PSIsContainer) { $dirs.Push($f.FullName) }
      else { $files[$f.FullName] = "$($f.LastWriteTimeUtc.Ticks):$($f.Length)" }
    }
  }
  $head = (& git.exe -C $Repo rev-parse --verify HEAD 2>$null) -join ''
  $bytes = @{}
  foreach ($path in $Logs) {
    $f = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
    $bytes[$path] = if ($f) { $f.Length } else { 0 }
  }
  return @{ Files = $files; Head = $head; Bytes = $bytes }
}
function Test-RunProgress($Before, $After) {
  if ($After.Head -and $After.Head -ne $Before.Head) { return $true }
  if ($After.Files.Count -ne $Before.Files.Count) { return $true }
  foreach ($key in $After.Files.Keys) {
    if (-not $Before.Files.ContainsKey($key) -or $Before.Files[$key] -ne $After.Files[$key]) { return $true }
  }
  foreach ($key in $After.Bytes.Keys) {
    if ($After.Bytes[$key] -gt $Before.Bytes[$key]) { return $true }
  }
  return $false
}
function Save-RunResume($Repo, $Out, $Logs, $Reason, $Base) {
  $utf8 = New-Object Text.UTF8Encoding($false)
  $changed = @(& git.exe --no-optional-locks -C $Repo -c core.quotepath=off diff --name-only $Base -- 2>$null)
  $changed += @(& git.exe --no-optional-locks -C $Repo -c core.quotepath=off ls-files --others --exclude-standard 2>$null)
  $changed = @($changed | Sort-Object -Unique)
  $note = "## Runner resume note (issue 818)`nStop reason: $Reason`n`nChanged files (from run base $Base):`n"
  if ($changed.Count) { $note += ($changed | ForEach-Object { "- $_" }) -join "`n" }
  else { $note += '(none)' }
  foreach ($path in $Logs) {
    $note += "`n`nLast log lines ($([IO.Path]::GetFileName($path))):`n"
    if (Test-Path -LiteralPath $path) {
      $tail = @(Get-Content -LiteralPath $path -Tail 12 -ErrorAction SilentlyContinue | ForEach-Object {
        $line = [string]$_; if ($line.Length -gt 400) { $line = $line.Substring(0, 400) + ' [cut]' }; $line
      })
      $note += $tail -join "`n"
    } else { $note += '(no output)' }
  }
  $note += "`n## End runner resume note`n"
  [IO.File]::WriteAllText((Join-Path $Out 'resume.txt'), $note, $utf8)
  [IO.File]::WriteAllText((Join-Path $Out 'stop_reason.txt'), $Reason, $utf8)
}
# taskkill /T uses process enumeration that can be denied in the Codex sandbox, even for our own children.
# Toolhelp needs no WMI access. Keep process handles, not just PIDs, so a reused PID can never target another job.
function Initialize-RunTree {
  if ('RunnerProcessSnapshot' -as [type]) { return }
  Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
public static class RunnerProcessSnapshot {
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  struct Entry {
    public uint size, usage, id; public UIntPtr heap; public uint module, threads, parent;
    public int priority; public uint flags;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string exe;
  }
  [DllImport("kernel32.dll", SetLastError = true)] static extern IntPtr CreateToolhelp32Snapshot(uint flags, uint id);
  [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern bool Process32FirstW(IntPtr h, ref Entry e);
  [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern bool Process32NextW(IntPtr h, ref Entry e);
  [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
  public static Dictionary<int, int> Parents() {
    IntPtr h = CreateToolhelp32Snapshot(2, 0);
    if (h == new IntPtr(-1)) throw new Win32Exception();
    try {
      var result = new Dictionary<int, int>();
      var e = new Entry(); e.size = (uint)Marshal.SizeOf(typeof(Entry));
      if (!Process32FirstW(h, ref e)) throw new Win32Exception();
      do { result[(int)e.id] = (int)e.parent; } while (Process32NextW(h, ref e));
      if (Marshal.GetLastWin32Error() != 18) throw new Win32Exception();
      return result;
    } finally { CloseHandle(h); }
  }
}

// The child cannot do GPU work until its identity is in the claim. The startup job
// kills it if the watchdog dies during that handoff. The same job accounts for the whole step tree.
public sealed class RunnerStep : IDisposable {
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  struct StartupInfo {
    public int size;
    public string reserved, desktop, title;
    public int x, y, xSize, ySize, xChars, yChars, fill, flags;
    public short show, reservedSize;
    public IntPtr reservedData, input, output, error, attributes;
  }
  [StructLayout(LayoutKind.Sequential)]
  struct ProcessInfo { public IntPtr process, thread; public int pid, tid; }
  [StructLayout(LayoutKind.Sequential)]
  struct JobLimits {
    public long processTime, jobTime;
    public uint flags;
    public UIntPtr minWorkSet, maxWorkSet;
    public uint maxProcesses;
    public UIntPtr affinity;
    public uint priority, scheduling;
    public ulong readOps, writeOps, otherOps, readBytes, writeBytes, otherBytes;
    public UIntPtr processMemory, jobMemory, peakProcessMemory, peakJobMemory;
  }
  [DllImport("kernel32.dll", SetLastError = true)] static extern IntPtr CreateJobObject(IntPtr security, IntPtr name);
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool SetInformationJobObject(IntPtr job, int kind, ref JobLimits limits, int size);
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool InitializeProcThreadAttributeList(IntPtr list, int count, int flags, ref IntPtr size);
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool UpdateProcThreadAttribute(IntPtr list, uint flags, IntPtr attribute, IntPtr value, IntPtr size, IntPtr previous, IntPtr returned);
  [DllImport("kernel32.dll")] static extern void DeleteProcThreadAttributeList(IntPtr list);
  [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern bool CreateProcess(
    string application, StringBuilder command, IntPtr processSecurity, IntPtr threadSecurity, bool inherit, uint flags,
    IntPtr environment, string cwd, ref StartupInfo startup, out ProcessInfo process);
  [DllImport("kernel32.dll")] static extern IntPtr GetStdHandle(int number);
  [DllImport("kernel32.dll")] static extern IntPtr GetCurrentProcess();
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool DuplicateHandle(IntPtr source, IntPtr handle, IntPtr target, out IntPtr copy, uint access, bool inherit, uint options);
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool SetHandleInformation(IntPtr handle, uint mask, uint flags);
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool QueryInformationJobObject(IntPtr job, int kind, out Usage data, int size, IntPtr written);
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool QueryInformationJobObject(IntPtr job, int kind, IntPtr data, int size, IntPtr written);
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool TerminateJobObject(IntPtr job, uint code);
  [DllImport("kernel32.dll", SetLastError = true)] static extern uint ResumeThread(IntPtr thread);
  [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr handle);

  [StructLayout(LayoutKind.Sequential)]
  public struct Usage {
    public long UserTime, KernelTime, PeriodUserTime, PeriodKernelTime;
    public uint PageFaults, Total, Active, Terminated;
    public long CpuTime { get { return UserTime + KernelTime; } }
  }

  IntPtr job;
  ProcessInfo child;
  public int Pid { get { return child.pid; } }
  void SetJobLimits(uint flags) {
    var limits = new JobLimits { flags = flags };
    if (!SetInformationJobObject(job, 9, ref limits, Marshal.SizeOf(typeof(JobLimits)))) throw new Win32Exception();
  }
  public RunnerStep(string command, string cwd, string output, string error) {
    job = CreateJobObject(IntPtr.Zero, IntPtr.Zero);
    if (job == IntPtr.Zero) throw new Win32Exception();
    try {
      SetJobLimits(0x2000); // JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
      IntPtr bytes = IntPtr.Zero;
      InitializeProcThreadAttributeList(IntPtr.Zero, 2, 0, ref bytes);
      IntPtr attributes = Marshal.AllocHGlobal(bytes);
      IntPtr jobList = Marshal.AllocHGlobal(IntPtr.Size);
      try {
        if (!InitializeProcThreadAttributeList(attributes, 2, 0, ref bytes)) throw new Win32Exception();
        try {
          Marshal.WriteIntPtr(jobList, job);
          // PROC_THREAD_ATTRIBUTE_JOB_LIST attaches the job atomically at creation.
          // UpdateProcThreadAttribute retains the pointer to jobList until creation.
          if (!SetJobAttribute(attributes, jobList)) throw new Win32Exception();
          using (var stdout = new FileStream(output, FileMode.CreateNew, FileAccess.Write, FileShare.ReadWrite))
          using (var stderr = new FileStream(error, FileMode.CreateNew, FileAccess.Write, FileShare.ReadWrite)) {
            var startup = new StartupInfo { size = Marshal.SizeOf(typeof(StartupInfo)), attributes = attributes, flags = 0x100,
              output = stdout.SafeFileHandle.DangerousGetHandle(), error = stderr.SafeFileHandle.DangerousGetHandle() };
            if (!SetHandleInformation(startup.output, 1, 1) || !SetHandleInformation(startup.error, 1, 1))
              throw new Win32Exception();
            // A caller may have no stdin.
            IntPtr self = GetCurrentProcess();
            DuplicateHandle(self, GetStdHandle(-10), self, out startup.input, 0, true, 2);
            IntPtr handles = IntPtr.Zero;
            try {
              // A surviving descendant must not keep the watchdog's output pipes open.
              int count = startup.input == IntPtr.Zero ? 2 : 3;
              handles = Marshal.AllocHGlobal(count * IntPtr.Size);
              Marshal.WriteIntPtr(handles, 0, startup.output);
              Marshal.WriteIntPtr(handles, IntPtr.Size, startup.error);
              if (count == 3) Marshal.WriteIntPtr(handles, 2 * IntPtr.Size, startup.input);
              // PROC_THREAD_ATTRIBUTE_HANDLE_LIST passes only the step's own streams.
              if (!UpdateProcThreadAttribute(attributes, 0, new IntPtr(0x20002), handles,
                  new IntPtr(count * IntPtr.Size), IntPtr.Zero, IntPtr.Zero)) throw new Win32Exception();
              const uint createSuspended = 0x4, extendedStartupInfo = 0x80000;
              if (!CreateProcess(null, new StringBuilder(command), IntPtr.Zero, IntPtr.Zero, true,
                  createSuspended | extendedStartupInfo, IntPtr.Zero, cwd, ref startup, out child)) throw new Win32Exception();
            } finally {
              if (handles != IntPtr.Zero) Marshal.FreeHGlobal(handles);
              if (startup.input != IntPtr.Zero) CloseHandle(startup.input);
            }
          }
        } finally { DeleteProcThreadAttributeList(attributes); }
      } finally { Marshal.FreeHGlobal(jobList); Marshal.FreeHGlobal(attributes); }
    } catch { Dispose(); throw; }
  }
  bool SetJobAttribute(IntPtr attributes, IntPtr jobList) {
    return UpdateProcThreadAttribute(attributes, 0, new IntPtr(0x2000D), jobList, new IntPtr(IntPtr.Size), IntPtr.Zero, IntPtr.Zero);
  }
  public void Resume() {
    if (ResumeThread(child.thread) == uint.MaxValue) throw new Win32Exception();
    SetJobLimits(0);
  }
  public Usage ReadUsage() {
    Usage usage;
    if (!QueryInformationJobObject(job, 1, out usage, Marshal.SizeOf(typeof(Usage)), IntPtr.Zero))
      throw new Win32Exception();
    return usage;
  }
  public long[] ActivePids() {
    // JOBOBJECT_BASIC_PROCESS_ID_LIST has two DWORD counts followed by pointer-sized PIDs.
    int capacity = 16;
    while (true) {
      int size = 8 + capacity * IntPtr.Size;
      IntPtr data = Marshal.AllocHGlobal(size);
      try {
        if (QueryInformationJobObject(job, 3, data, size, IntPtr.Zero)) {
          long[] pids = new long[Marshal.ReadInt32(data, 4)];
          for (int i = 0; i < pids.Length; i++) pids[i] = Marshal.ReadIntPtr(data, 8 + i * IntPtr.Size).ToInt64();
          return pids;
        }
        int error = Marshal.GetLastWin32Error();
        if (error != 234) throw new Win32Exception(error); // ERROR_MORE_DATA
        capacity = Math.Max(capacity * 2, Marshal.ReadInt32(data));
      } finally { Marshal.FreeHGlobal(data); }
    }
  }
  public void Kill() {
    if (!TerminateJobObject(job, 124)) throw new Win32Exception();
  }
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool IsProcessInJob(IntPtr process, IntPtr job, out bool member);
  public bool IsMember(IntPtr process) {
    bool member;
    if (!IsProcessInJob(process, job, out member)) throw new Win32Exception();
    return member;
  }
  public void Dispose() {
    if (job != IntPtr.Zero) { CloseHandle(job); job = IntPtr.Zero; }
    if (child.thread != IntPtr.Zero) { CloseHandle(child.thread); child.thread = IntPtr.Zero; }
    if (child.process != IntPtr.Zero) { CloseHandle(child.process); child.process = IntPtr.Zero; }
  }
}

public sealed class RunnerStepFiles : IDisposable {
  readonly FileSystemWatcher watcher;
  readonly string folder;
  int changes;
  public RunnerStepFiles(string output) {
    if (String.IsNullOrEmpty(output)) return;
    folder = Path.GetFullPath(output).TrimEnd('\\', '/') + Path.DirectorySeparatorChar;
    string parent = folder;
    while (!Directory.Exists(parent)) parent = Path.GetDirectoryName(parent.TrimEnd('\\', '/'));
    watcher = new FileSystemWatcher(parent) { IncludeSubdirectories = true, NotifyFilter = NotifyFilters.FileName };
    watcher.Created += Changed;
    watcher.Renamed += Changed;
    watcher.Error += (sender, e) => Interlocked.Increment(ref changes); // An overflow also means file activity.
    watcher.EnableRaisingEvents = true;
  }
  void Changed(object sender, FileSystemEventArgs e) {
    if (e.FullPath.StartsWith(folder, StringComparison.OrdinalIgnoreCase)) Interlocked.Increment(ref changes);
  }
  public int Changes { get { return Volatile.Read(ref changes); } }
  public void Dispose() { if (watcher != null) watcher.Dispose(); }
}

public sealed class RunnerStepOutput : IDisposable {
  static readonly Regex joltFatal = new Regex("Jolt Physics job system exceeded", RegexOptions.IgnoreCase);
  readonly Regex extraFatal;
  readonly FileStream source;
  readonly Stream target;
  readonly byte[] bytes = new byte[65536];
  readonly char[] chars = new char[65536];
  readonly Decoder decoder = Encoding.UTF8.GetDecoder();
  readonly StringBuilder line = new StringBuilder();
  public string KnownFatal { get; private set; }
  public bool Pending { get { return source.Position < source.Length; } }
  public RunnerStepOutput(string path, bool stderr, Regex extraFatal) {
    source = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
    target = stderr ? Console.OpenStandardError() : Console.OpenStandardOutput();
    this.extraFatal = extraFatal;
  }
  public bool Drain(bool scan) {
    int count = source.Read(bytes, 0, bytes.Length);
    if (count == 0) return false;
    target.Write(bytes, 0, count);
    target.Flush();
    if (!scan) return true;
    int length = decoder.GetChars(bytes, 0, count, chars, 0);
    for (int i = 0; i < length; i++) {
      if (chars[i] == '\n') {
        ScanFatal(line.ToString().Trim());
        line.Clear();
      } else if (line.Length == 8192) {
        ScanFatal(line.ToString());
        line.Remove(0, 4096);
        line.Append(chars[i]);
      } else line.Append(chars[i]);
    }
    ScanFatal(line.ToString());
    return true;
  }
  void ScanFatal(string text) {
    if (KnownFatal != null) return;
    var match = joltFatal.Match(text);
    if (!match.Success && extraFatal != null) match = extraFatal.Match(text);
    if (match.Success) KnownFatal = match.Value;
  }
  public void Dispose() { source.Dispose(); }
}
'@
}
function Update-RunTree($Tree) {
  $parents = [RunnerProcessSnapshot]::Parents()
  do {
    $added = $false
    foreach ($childId in $parents.Keys) {
      $parentId = $parents[$childId]
      if ($Tree.ContainsKey($childId) -or -not $Tree.ContainsKey($parentId)) { continue }
      $parent = $Tree[$parentId]
      # A retained handle keeps the original process identity after exit. StartTime also rejects reused parent PIDs.
      try {
        $child = [Diagnostics.Process]::GetProcessById($childId)
        $null = $child.Handle
        if ($child.StartTime -lt $parent.StartTime) { $child.Dispose(); continue }
        if ($parent.HasExited -and $child.StartTime -gt $parent.ExitTime) { $child.Dispose(); continue }
        $Tree[$childId] = $child; $added = $true
      } catch [ArgumentException] { } # The child already exited between snapshot and open.
    }
  } while ($added)
}
function Write-KillLog($Log, $Line) {
  Write-Output "run_timeout: $Line"
  try { "$(Get-Date -Format s) $Line" | Out-File -LiteralPath $Log -Append -Encoding utf8 }
  catch { Write-Output "run_timeout: could not append kill log: $($_.Exception.Message)" }
}
function Stop-RunTree($Process, $Tree, $Log) {
  Update-RunTree $Tree
  $ea = $ErrorActionPreference
  $killer = 'taskkill.exe'
  if ($env:PC_RUNNER_TEST -eq '1' -and $env:PC_TEST_TASKKILL) { $killer = $env:PC_TEST_TASKKILL }
  try {
    $ErrorActionPreference = 'Continue'
    $reply = @(& $killer /PID $Process.Id /T /F 2>&1)
    $code = $LASTEXITCODE
  } finally { $ErrorActionPreference = $ea }
  Write-KillLog $Log "taskkill PID $($Process.Id) exit ${code}: $($reply -join ' ')"
  $deadline = [DateTime]::UtcNow.AddSeconds(15)
  $simulateFailedKill = $env:PC_RUNNER_TEST -eq '1' -and $env:PC_TEST_FAIL_KILL -eq '1' -and $code -ne 0
  do {
    # Discover children before stopping their parents, and repeat in case one spawned during taskkill.
    Update-RunTree $Tree
    $live = @($Tree.Values | Where-Object { -not $_.HasExited } | Sort-Object StartTime -Descending)
    foreach ($child in $live) {
      if ($simulateFailedKill) { continue }
      try { $child.Kill() }
      catch { if (-not $child.HasExited) { Write-KillLog $Log "handle kill PID $($child.Id) failed: $($_.Exception.Message)" } }
    }
    foreach ($child in $live) { $null = $child.WaitForExit(100) }
    Update-RunTree $Tree
    $live = @($Tree.Values | Where-Object { -not $_.HasExited })
    if (-not $live.Count) {
      Write-KillLog $Log "kill verified: all $($Tree.Count) processes gone (PIDs $((@($Tree.Keys) | Sort-Object) -join ', '))"
      return
    }
  } while (-not $simulateFailedKill -and [DateTime]::UtcNow -lt $deadline)
  $failure = "KILL FAILED: surviving PIDs $(($live | ForEach-Object { $_.Id }) -join ', '); checkout kept"
  Write-KillLog $Log $failure
  throw $failure
}
function Get-GpuProcessIdentity($Process) {
  return @{ pid = $Process.Id; startTime = [string]$Process.StartTime.ToFileTimeUtc(); exe = $Process.ProcessName.ToLowerInvariant() }
}
function Update-GpuClaim($Action, $Processes) {
  $identities = @($Processes | ForEach-Object {
    try { Get-GpuProcessIdentity $_ }
    catch { if (-not $_.HasExited) { throw } }
  })
  if (-not $identities.Count) { throw "GPU: no live process identities for $Action" }
  ConvertTo-Json -InputObject $identities -Compress | & $gpuNode $gpuHelper $Action $gpuRoot $gpuToken
  if ($LASTEXITCODE -ne 0) { throw "GPU: could not $Action claim $gpuToken" }
}
function Get-StepLimit($Value, $Default, $Name) {
  $number = $Default
  if ($Value -and ($Value -notmatch '^\d+$' -or -not [int]::TryParse($Value, [ref]$number) -or $number -lt 1)) {
    throw "$Name must be a positive number of seconds"
  }
  return $number
}
function Stop-StepTree($Job, $Log, $Step) {
  $simulateFailedKill = $false
  if ($env:PC_RUNNER_TEST -eq '1' -and $env:PC_TEST_FAIL_KILL -eq '1' -and $env:PC_TEST_TASKKILL) {
    $null = & $env:PC_TEST_TASKKILL
    $simulateFailedKill = $LASTEXITCODE -ne 0
  }
  if (-not $simulateFailedKill) {
    try { $Job.Kill() }
    catch { Write-KillLog $Log "$Step job kill error: $($_.Exception.Message)" }
  }
  $clock = [Diagnostics.Stopwatch]::StartNew()
  do {
    $usage = $Job.ReadUsage()
    if (-not $usage.Active) {
      Write-KillLog $Log "$Step kill verified: all $($usage.Total) processes gone (root PID $($Job.Pid))"
      Set-StepRec treeEmpty ($true)
      return
    }
    if ($simulateFailedKill) { break }
    Start-Sleep -Milliseconds 50
  } while ($clock.Elapsed.TotalSeconds -lt 15)
  $survivors = ($Job.ActivePids() | Sort-Object) -join ', '
  Set-StepRec treeEmpty ($false)
  throw "KILL FAILED: surviving PIDs $survivors for $Step"
}
function Protect-GpuStepClaim($Job, $Log) {
  # Keep the watchdog (and claim) alive until empty or the survivors are on record.
  while ($true) {
    $processes = @()
    try {
      if (-not $Job.ReadUsage().Active) { Set-StepRec treeEmpty ($true); return }
      foreach ($id in $Job.ActivePids()) {
        try { $child = [Diagnostics.Process]::GetProcessById([int]$id) }
        catch [ArgumentException] { continue }
        $processes += $child
      }
      $survivors = @($processes | Where-Object { -not $_.HasExited -and $Job.IsMember($_.Handle) })
      if ($survivors.Count) {
        Set-StepRec treeEmpty ($false)
        Update-GpuClaim orphan $survivors
        Write-KillLog $Log "GPU: retaining claim $gpuToken as orphaned_child for PIDs $($survivors.Id -join ', ')"
        return
      }
    } catch {
      Write-KillLog $Log "GPU: could not record surviving processes; claim $gpuToken held: $($_.Exception.Message)"
    } finally {
      foreach ($child in $processes) { $child.Dispose() }
    }
    Start-Sleep -Seconds 1
  }
}
function New-GodotProfile($Target, $Arguments) {
  if ($env:PC_REAL_PROFILE -ceq '1') { return }
  # PC_STEP_PROFILE_ANY=1 (the PC daemon, issue 1662): every target gets the throwaway profile, Blender too.
  if (-not $script:profileAny -and [IO.Path]::GetFileName($Target) -notmatch '^(Godot|Voidsworn)(.*\.exe)?$') {
    # A caller can override the engine path and rename the Windows executable.
    $app = Get-Command -Name $Target -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $app -or $app.FileVersionInfo.FileDescription -notlike 'Godot Engine*') { return }
  }
  $scratch = $env:PC_RUN_SCRATCH
  if ($scratch) {
    $owner = Join-Path $scratch '.voidsworn-run-owner'
    if ([IO.File]::ReadAllText($owner) -cnotmatch '\A[0-9a-f]{32}\z') {
      throw "Invalid runner scratch ownership token: $owner"
    }
  } else {
    # Standalone queue jobs use the same owned scratch format as the agent runners.
    $scratch = Join-Path (Get-ScratchParent) ("voidsworn-run-" + [Guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path $scratch
    [IO.File]::WriteAllText((Join-Path $scratch '.voidsworn-run-owner'), [Guid]::NewGuid().ToString('N'))
    $script:createdScratch = $scratch
  }
  $profile = Join-Path $scratch ("godot-profile-" + [Guid]::NewGuid().ToString('N'))
  $null = New-Item -ItemType Directory -Path $profile
  $script:createdProfile = $profile
  Set-StepRec profile ($profile)
  if ($env:PC_GODOT_EXPORT_TEMPLATES -and $Arguments -match '(?:^|\s)--export-release\s') {
    # Exporting needs these shared tools, but does not need the player's user data.
    $templates = $env:PC_GODOT_EXPORT_TEMPLATES
    $destination = Join-Path $profile ('Godot\export_templates\' + (Split-Path -Leaf $templates))
    $null = New-Item -ItemType Directory -Path $destination -Force
    foreach ($name in @('windows_release_x86_64.exe', 'windows_release_x86_64_console.exe')) {
      Copy-Item -LiteralPath (Join-Path $templates $name) -Destination $destination
    }
  }
  return $profile
}
function Get-ScratchParent {
  # PC_STEP_SCRATCH_PARENT (the PC daemon, issue 1662): the profile and child logs live in a plain folder the caller
  # owns inside its held slot, never in TEMP. It must already exist.
  if (-not $script:scratchParent) { return [IO.Path]::GetTempPath() }
  $item = Get-Item -LiteralPath $script:scratchParent -Force -ErrorAction SilentlyContinue
  if (-not ($item -is [IO.DirectoryInfo]) -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw "PC_STEP_SCRATCH_PARENT is not a plain folder: $($script:scratchParent)"
  }
  return $item.FullName
}
function Remove-LinkSafeTree($dir) {
  # Delete a folder this launch made without ever following a link: links go as links, then files, then folders.
  $item = Get-Item -LiteralPath $dir -Force -ErrorAction SilentlyContinue
  if (-not $item) { return }
  if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { [IO.Directory]::Delete($item.FullName, $false); return }
  $dirs = New-Object 'Collections.Generic.List[string]'
  $pending = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'
  $pending.Push($item)
  while ($pending.Count) {
    $next = $pending.Pop(); $dirs.Add($next.FullName)
    foreach ($entry in @($next.EnumerateFileSystemInfos())) {
      if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        if ($entry -is [IO.DirectoryInfo]) { [IO.Directory]::Delete($entry.FullName, $false) } else { [IO.File]::Delete($entry.FullName) }
      } elseif ($entry -is [IO.DirectoryInfo]) { $pending.Push($entry) }
      else { $entry.Attributes = [IO.FileAttributes]::Normal; [IO.File]::Delete($entry.FullName) }
    }
  }
  for ($i = $dirs.Count - 1; $i -ge 0; $i--) { [IO.Directory]::Delete($dirs[$i], $false) }
}
function Test-CleanupPaused {
  # The same pause line runner_common.ps1 Cleanup-Paused reads. Tests point PC_CLEANUP_PAUSE_FILE at a fixture.
  $flag = if ($env:PC_RUNNER_TEST -ceq '1' -and $env:PC_CLEANUP_PAUSE_FILE) { $env:PC_CLEANUP_PAUSE_FILE }
    elseif ($env:USERPROFILE) { Join-Path $env:USERPROFILE 'Downloads\voidsworn_test\gpu_go.txt' } else { $null }
  if (-not $flag -or -not (Test-Path -LiteralPath $flag -PathType Leaf)) { return $false }
  return [string](Get-Content -LiteralPath $flag -TotalCount 1) -match '^GPU not cleared: paused by the Board\b'
}
function Remove-CreatedProfile {
  # Issue 1180 (Board, Nov 20): a throwaway Godot profile is removed once its process tree has ended, with the
  # voidsworn-run folder when this launch made that too. Only what this launch created; PC_KEEP_GODOT_PROFILE=1 keeps it
  # (a two-launch gate or a warm-cache bench). A failed removal is logged and left for the janitor.
  if (-not $script:createdProfile -or $env:PC_KEEP_GODOT_PROFILE -ceq '1') { return }
  try {
    # The Board's PC pause removes nothing (RULEBOOK 3.11); the janitor takes the profile on a later pass.
    if (Test-CleanupPaused) { throw 'PC pause is active' }
    Remove-LinkSafeTree $script:createdProfile
    if ($script:createdScratch) {
      [IO.File]::Delete((Join-Path $script:createdScratch '.voidsworn-run-owner'))
      [IO.Directory]::Delete($script:createdScratch, $false)
    }
    Set-StepRec profileRemoved ($true)
    Write-Output "run_timeout: Godot profile removed: $($script:createdProfile)"
  } catch { Write-Output "run_timeout: Godot profile kept for the janitor ($($script:createdProfile)): $($_.Exception.Message)" }
  $script:createdProfile = $null; $script:createdScratch = $null
}
function Start-WithGodotProfile($Profile, [scriptblock]$Start) {
  if (-not $Profile) { return (& $Start) }
  $set = @{ APPDATA = $Profile; LOCALAPPDATA = $Profile }
  if ($script:profileAny) {
    # Blender reads these before APPDATA; all of them point into the throwaway profile (issue 1662, Astra finding A).
    foreach ($n in @('RESOURCES', 'CONFIG', 'SCRIPTS', 'DATAFILES', 'EXTENSIONS')) {
      $set["BLENDER_USER_$n"] = Join-Path $Profile ('blender\' + $n.ToLowerInvariant())
    }
  }
  $saved = @{}
  foreach ($k in $set.Keys) { $saved[$k] = [Environment]::GetEnvironmentVariable($k) }
  try {
    foreach ($k in $set.Keys) { [Environment]::SetEnvironmentVariable($k, $set[$k]) }
    & $Start
  } finally {
    foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k]) }
  }
}
function Set-StepRec($Key, $Value) {
  # The step record exists only in a normal (not -LibraryOnly) run; library callers keep their own variables untouched.
  if ($null -ne $script:pcStepRec) { $script:pcStepRec[$Key] = $Value }
}
function Write-StepRecord {
  # PC_STEP_RECORD (the PC daemon, issue 1662): the watchdog's own account of the step, separate from the child's
  # output, so a log line that quotes an old failure can never set a quarantine (Astra finding F). treeEmpty is true
  # only when the Job Object was seen empty (or the step never started); anything else means the tree is unproven.
  if (-not $script:pcStepRec.started -and $null -eq $script:pcStepRec.treeEmpty) { $script:pcStepRec.treeEmpty = $true }
  $tmp = $script:stepRecord + '.tmp'
  [IO.File]::WriteAllText($tmp, ($script:pcStepRec | ConvertTo-Json -Compress))
  if (Test-Path -LiteralPath $script:stepRecord) { [IO.File]::Replace($tmp, $script:stepRecord, $null) }
  else { [IO.File]::Move($tmp, $script:stepRecord) }
}
if ($LibraryOnly) { return }
# pc-step-settings: 1
# (the PC daemon checks for the line above before it launches anything: a watchdog without these settings is refused)
$script:pcStepRec = [ordered]@{ version = 1; exit = $null; reason = ''; started = $false; treeEmpty = $null; gated = ''; profile = ''; profileRemoved = $false }
# Opt-in step settings of the PC daemon (issue 1662). Read once here and cleared before the child starts, so a nested
# tmo.bat inside the job never inherits them. Unset, the watchdog behaves exactly as before.
$script:stepRecord = $env:PC_STEP_RECORD
$waitTree = $env:PC_STEP_WAIT_TREE -ceq '1'
$script:scratchParent = $env:PC_STEP_SCRATCH_PARENT
$script:profileAny = $env:PC_STEP_PROFILE_ANY -ceq '1'
$gateJs = $env:PC_STEP_GATE_JS; $gateArg = $env:PC_STEP_GATE_ARG
foreach ($n in @('PC_STEP_RECORD', 'PC_STEP_WAIT_TREE', 'PC_STEP_SCRATCH_PARENT', 'PC_STEP_PROFILE_ANY', 'PC_STEP_GATE_JS', 'PC_STEP_GATE_ARG')) {
  [Environment]::SetEnvironmentVariable($n, $null)
}
$raw = $env:TMO_ARGS
if (-not $raw) { Write-Output 'usage: tmo.bat <seconds> <exe> [args ...]'; exit 125 }
$m = [regex]::Match($raw, '^\s*(\d+)\s+("([^"]+)"|(\S+))\s*(.*)$')
if (-not $m.Success) { Write-Output "run_timeout: cannot read the command line: $raw"; exit 125 }
$Seconds = [int]$m.Groups[1].Value
$Exe = if ($m.Groups[3].Success) { $m.Groups[3].Value } else { $m.Groups[4].Value }
$argLine = $m.Groups[5].Value
$root = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$logDir = Join-Path $root 'queue\logs'
if (-not (Test-Path $logDir)) { $logDir = $PSScriptRoot }
$log = Join-Path $logDir 'timeouts.log'
if ($env:PC_RUNNER_TEST -eq '1' -and $env:PC_TEST_TIMEOUT_LOG) { $log = $env:PC_TEST_TIMEOUT_LOG }
$watch = $env:TMO_REPO -and $env:TMO_OUT -and $env:TMO_LOG
$watchRepo = $env:TMO_REPO; $watchOut = $env:TMO_OUT
$stall = 30.0
if ($watch -and $env:STALL_MIN) { $stall = [double]::Parse($env:STALL_MIN, [Globalization.CultureInfo]::InvariantCulture) }
if ($Seconds -le 0 -or $stall -le 0 -or [double]::IsNaN($stall) -or [double]::IsInfinity($stall)) { throw 'ceiling and STALL_MIN must be positive' }
$logs = @($env:TMO_LOG, $env:TMO_ERR_LOG) | Where-Object { $_ }
if ($watch) {
  $before = Get-RunProgress $watchRepo $logs
  $base = $before.Head
  $bp = Join-Path $watchOut 'base_commit.txt'
  if (Test-Path -LiteralPath $bp) { $base = [IO.File]::ReadAllText($bp).Trim() }
} else {
  $stepName = $env:TMO_STEP
  if (-not $stepName) { $stepName = [IO.Path]::GetFileName($Exe) }
  $stepOut = $env:TMO_STEP_OUT
  if (-not $stepOut -and $argLine -match '(?:^|\s)--out(?:\s+|=)(?:"([^"]+)"|(\S+))') {
    $stepOut = if ($Matches[1]) { $Matches[1] } else { $Matches[2] }
  }
  $idleDefault = if ([IO.Path]::GetFileName($Exe) -match '^(Godot|Voidsworn)') { 300 } else { 600 }
  $idleSeconds = Get-StepLimit $env:TMO_IDLE_S $idleDefault 'TMO_IDLE_S'
  if ($env:PC_RUNNER_TEST -ne '1') { $idleSeconds = [Math]::Max($idleDefault, $idleSeconds) }
  $extraFatal = $null
  if ($env:TMO_FATAL_PATTERN) {
    $extraFatal = [regex]::new($env:TMO_FATAL_PATTERN, [Text.RegularExpressions.RegexOptions]::IgnoreCase,
      [TimeSpan]::FromMilliseconds(250))
  }
}
# Nov 1: a test job ran all through Ryan's first Godot playtest, slowing the PC and overwriting the game's log.
# Wait while Ryan is playing: the game is Voidsworn.exe or a windowed Godot started with no job arguments
# (play_godot.bat passes none; every job passes --headless, --script, --bot or similar). Waiting is not timed.
function Test-RyanPlaying {
  try { $ps = Get-CimInstance Win32_Process -Filter "Name LIKE 'Voidsworn%.exe' OR Name LIKE 'Godot%.exe'" } catch { return $false }
  foreach ($q in $ps) {
    if ($q.Name -like '*_console.exe') { continue }
    $cl = [string]$q.CommandLine
    $rest = [regex]::Replace($cl, '^\s*("[^"]*"|\S+)', '')
    $rest = [regex]::Replace($rest, '--path\s+("[^"]*"|\S+)', '')
    # play_godot_safe.bat plays with a renderer choice; that is still play (Astra run 4, item 6)
    $rest = [regex]::Replace($rest, '--rendering-(?:method|driver)\s+("[^"]*"|\S+)', '')
    if ($rest -notmatch '--?\w') { return $true }
  }
  return $false
}
$w0 = Get-Date; $said = $false
# Codex jobs are light (one model session, small node scripts) and do not touch the game's log: they run during play.
$noWait = ($Exe -match 'codex(\.cmd|\.exe)?$') -or ($env:PC_RUNNER_TEST -eq '1')
while ((-not $noWait) -and (Test-RyanPlaying) -and ((Get-Date) - $w0).TotalHours -lt 8) {
  if (-not $said) { Write-Output "run_timeout: the game is open, waiting until it closes"; "$(Get-Date -Format s) WAIT game open: $Exe" | Out-File $log -Append -Encoding utf8; $said = $true }
  Start-Sleep -Seconds 20
}
if ($said) { "$(Get-Date -Format s) RESUME after $([int]((Get-Date) - $w0).TotalMinutes) min: $Exe" | Out-File $log -Append -Encoding utf8 }
# R293: acquire only around the GPU command, never the whole model session.
# A pending solo claim drains all shared slots and blocks new workers.
$gpuHelper = Join-Path $PSScriptRoot 'gpu_slots.js'
$gpuNode = 'node.exe'
$bundledNode = Join-Path $root 'node\node.exe'
if (Test-Path -LiteralPath $bundledNode) { $gpuNode = $bundledNode }
$gpuRoot = $root
if ($env:PC_RUNNER_TEST -eq '1' -and $env:PC_TEST_GPU_ROOT) { $gpuRoot = $env:PC_TEST_GPU_ROOT }
$gpuToken = ''
$retainGpuClaim = $false
$OutputEncoding = New-Object Text.UTF8Encoding($false)
try {
$classify = @{ exe = $Exe; args = $argLine; cwd = (Get-Location).Path; requested = [string]$env:PC_GPU_MODE
  weight = [string]$env:PC_GPU_WEIGHT; issue = [string]$env:PC_GPU_ISSUE; jobDir = [string]$env:JOB_DIR } | ConvertTo-Json -Compress
$gpuClass = ($classify | & $gpuNode $gpuHelper classify) -join ''
if ($LASTEXITCODE -ne 0) { throw 'GPU command classification failed' }
$gpuClass = $gpuClass | ConvertFrom-Json
$gpuMode = $gpuClass.mode
$soloMax = 0
if ($gpuMode -and $watch) { throw 'a GPU claim must wrap one step; clear TMO_REPO, TMO_OUT and TMO_LOG' }
# Without an override, the step ceiling also bounds its solo claim.
if ($gpuMode -eq 'solo' -and $env:PC_GPU_SOLO_MAX_S) {
  $soloMax = Get-StepLimit $env:PC_GPU_SOLO_MAX_S $Seconds 'PC_GPU_SOLO_MAX_S'
}
if ($gpuMode) {
  if (-not $gpuClass.label) {
    Write-Output 'GPU: set PC_GPU_ISSUE or JOB_DIR, or pass the script name for admission'
    Set-StepRec exit (126); Set-StepRec reason ('GPU admission: no label')
    exit 126
  }
  Write-Output "GPU: waiting for $gpuMode claim, weight $($gpuClass.weight) ($($gpuClass.label))"
  # Admission has its own clock in gpu_slots.js (PC_GPU_WAIT_SECONDS, default 300).
  # Read the helper's diagnostic even under Windows PowerShell's native stderr handling.
  $ea = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    & $gpuNode $gpuHelper acquire $gpuRoot $gpuClass.label $PID $gpuMode $gpuClass.weight 2>&1 | ForEach-Object {
      $line = [string]$_
      if ($line -eq 'WAIT') { Write-Host "GPU: still waiting for $gpuMode claim" }
      elseif ($line -cmatch '\A[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\z') {
        $gpuToken = $line
        $claimTimer = [Diagnostics.Stopwatch]::StartNew()
      }
      else { Write-Output $line }
    }
    $admissionExit = $LASTEXITCODE
  } finally { $ErrorActionPreference = $ea }
  if ($admissionExit -ne 0 -or -not $gpuToken) {
    Write-Output 'GPU: admission failed; command was not started'
    Set-StepRec exit (126); Set-StepRec reason ('GPU admission failed')
    exit 126
  }
  Write-Output "GPU: acquired $gpuMode claim $gpuToken"
}
# PC_STEP_GATE_JS (the PC daemon, issue 1662, Astra findings 1 and 6): after the game-open wait and GPU admission, right
# before the start, the caller reads its approval, pause, hold and the game again. Anything but exit 0 means no start;
# the claim is released below like any other unstarted step.
if (-not $watch -and $gateJs) {
  $ea = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $gateText = (& $gpuNode $gateJs --recheck $gateArg 2>&1 | ForEach-Object { [string]$_ }) -join ' '
    $gateExit = $LASTEXITCODE
  } catch { $gateText = $_.Exception.Message; $gateExit = -1 }
  finally { $ErrorActionPreference = $ea }
  if ($gateExit -ne 0) {
    if (-not $gateText) { $gateText = "launch gate exit $gateExit" }
    Set-StepRec gated ($gateText); Set-StepRec exit (125); Set-StepRec reason ('launch gate said no')
    Write-Output "run_timeout: launch gate said no (exit $gateExit): $gateText"
    Write-KillLog $log "GATED $stepName ($Exe): $gateText"
    exit 125
  }
  Write-Output "run_timeout: launch gate passed: $gateText"
}
# A forced claim applies to this command only, never a nested watchdog.
$env:PC_GPU_MODE = ''
$env:PC_GPU_WEIGHT = ''
$env:PC_GPU_SOLO_MAX_S = ''
$env:TMO_IDLE_S = ''; $env:TMO_STEP = ''; $env:TMO_STEP_OUT = ''
$env:TMO_FATAL_PATTERN = ''
# Child commands may use tmo.bat too. Their own timeout must never overwrite this agent's resume note.
$env:TMO_REPO = ''; $env:TMO_OUT = ''; $env:TMO_LOG = ''; $env:TMO_ERR_LOG = ''
if (-not $watch) {
  $spool = Join-Path (Get-ScratchParent) ("runner-step-" + [Guid]::NewGuid().ToString('N'))
  $outPath = Join-Path $spool 'stdout.log'
  $errPath = Join-Path $spool 'stderr.log'
  $job = $p = $files = $stdout = $stderr = $null
  $keepSpool = $true
  $mayBeRunning = $finished = $killAttempted = $false
  try {
    try {
      $cwd = (Get-Location).Path
      $target = if (Test-Path -LiteralPath $Exe -PathType Leaf) { (Get-Item -LiteralPath $Exe).FullName }
                else { (Get-Command -Name $Exe -CommandType Application | Select-Object -First 1 -ErrorAction Stop).Source }
      $command = '"' + $target + '" ' + $argLine
      if ($target -match '\.(bat|cmd)$') { $command = '"' + $env:ComSpec + '" /d /s /c "' + $command + '"' }
      if ($stepOut) { $stepOut = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($stepOut) }
      Initialize-RunTree
      $files = [RunnerStepFiles]::new([string]$stepOut)
      $null = [IO.Directory]::CreateDirectory($spool)
      $profile = New-GodotProfile $target $argLine
      if ($profile) { Write-Output "run_timeout: Godot profile: $profile" }
      $job = Start-WithGodotProfile $profile { [RunnerStep]::new($command, $cwd, $outPath, $errPath) }
      $p = [Diagnostics.Process]::GetProcessById($job.Pid)
      $null = $p.Handle
      $stdout = [RunnerStepOutput]::new($outPath, $false, $extraFatal)
      $stderr = [RunnerStepOutput]::new($errPath, $true, $extraFatal)
      if ($gpuToken) {
        Update-GpuClaim track @($p)
        $retainGpuClaim = $true
      }
      $timer = [Diagnostics.Stopwatch]::StartNew()
      $mayBeRunning = $true
      Set-StepRec started ($true)
      $job.Resume()
    } catch {
      Write-KillLog $log "START FAILED $stepName ($Exe): $($_.Exception.Message)"
      Set-StepRec exit (125); Set-StepRec reason ("START FAILED: $($_.Exception.Message)")
      exit 125
    }
    $lastProgress = 0.0
    $lastCpu = 0
    $lastFiles = 0
    while ($true) {
      $readOut = $stdout.Drain($true)
      $readErr = $stderr.Drain($true)
      $fatal = if ($stdout.KnownFatal) { $stdout.KnownFatal } else { $stderr.KnownFatal }
      $elapsed = $timer.Elapsed.TotalSeconds
      $usage = $job.ReadUsage()
      $fileCount = $files.Changes
      if ($readOut -or $readErr -or $usage.CpuTime -gt $lastCpu -or $fileCount -ne $lastFiles) {
        $lastProgress = $elapsed
      }
      $lastCpu = $usage.CpuTime
      $lastFiles = $fileCount
      # Once the root has exited, its final output is visible to the pending check.
      $rootExited = $p.HasExited
      $pendingOutput = $stdout.Pending -or $stderr.Pending
      if ($fatal) { $reason = "FATAL $fatal"; break }
      if ($soloMax -and $claimTimer.Elapsed.TotalSeconds -ge $soloMax) { $reason = "SOLO CAP after $soloMax s"; break }
      # PC_STEP_WAIT_TREE=1 (the PC daemon, Astra finding 3): like a GPU step, the step ends only with an empty Job
      # Object; descendants that outlive the root stay under the idle stop and the ceiling.
      if ($rootExited -and (-not ($gpuToken -or $waitTree) -or -not $usage.Active) -and -not $pendingOutput) {
        $finished = $true
        $retainGpuClaim = $false # GPU steps reach this branch only with an empty job.
        $keepSpool = [bool]$usage.Active
        Set-StepRec treeEmpty (-not $keepSpool)
        if ($keepSpool) { Write-Output "run_timeout: background output continues in $spool" }
        Set-StepRec exit ($p.ExitCode); Set-StepRec reason ('exited')
        exit $p.ExitCode
      }
      if ($elapsed -ge $Seconds) { $reason = 'CEILING'; break }
      if ($elapsed - $lastProgress -ge $idleSeconds) {
        $quietFor = [Math]::Round($elapsed - $lastProgress, 3)
        $reason = "IDLE after $idleSeconds s without output, new files or CPU progress ($quietFor s since last progress)"
        break
      }
      if (-not $pendingOutput) {
        $waitMs = [Math]::Min(250, ($Seconds - $elapsed) * 1000)
        $waitMs = [Math]::Min($waitMs, ($idleSeconds - ($elapsed - $lastProgress)) * 1000)
        if ($soloMax) { $waitMs = [Math]::Min($waitMs, ($soloMax - $claimTimer.Elapsed.TotalSeconds) * 1000) }
        Start-Sleep -Milliseconds ([int][Math]::Max(1, $waitMs))
      }
    }
    $stoppedAfter = [Math]::Round($elapsed, 3)
    Write-KillLog $log "STOPPING $stepName ($Exe): $reason at $stoppedAfter s"
    $killAttempted = $true
    try {
      Stop-StepTree $job $log $stepName
      $retainGpuClaim = $false
      $finished = $true
      while ($stdout.Drain($false)) { }
      while ($stderr.Drain($false)) { }
    } catch {
      Write-KillLog $log $_.Exception.Message
    }
    Write-KillLog $log "TIMEOUT $stepName ($Exe): $reason at $stoppedAfter s (ceiling $Seconds s). Child logs: $spool"
    Set-StepRec exit (124); Set-StepRec reason ("TIMEOUT $reason at $stoppedAfter s")
    exit 124
  } finally {
    try {
      if ($mayBeRunning -and -not $finished -and -not $killAttempted) {
        try {
          Stop-StepTree $job $log $stepName
          $retainGpuClaim = $false
        } catch { Write-KillLog $log $_.Exception.Message }
      }
      if ($retainGpuClaim) { Protect-GpuStepClaim $job $log }
    } finally {
      if ($stdout) { $stdout.Dispose() }
      if ($stderr) { $stderr.Dispose() }
      if ($p) { $p.Dispose() }
      if ($files) { $files.Dispose() }
      if ($job) { $job.Dispose() }
      if ($finished -and -not $keepSpool) { Remove-CreatedProfile }
      if (-not $keepSpool) {
        # These are the files and the empty scratch directory created above.
        try {
          [IO.File]::Delete($outPath)
          [IO.File]::Delete($errPath)
          [IO.Directory]::Delete($spool)
        } catch { Write-Output "run_timeout: child log cleanup failed in $spool : $($_.Exception.Message)" }
      }
    }
  }
}
# Outer agents keep their original separate logs and repo/commit progress checks.
Initialize-RunTree
$timer = [Diagnostics.Stopwatch]::StartNew()
$lastProgress = 0.0
$scanEvery = 60.0
if ($env:PC_RUNNER_TEST -eq '1' -and $env:PC_TEST_SCAN_S) { $scanEvery = [double]$env:PC_TEST_SCAN_S }
$nextScan = $scanEvery
try {
  $profile = New-GodotProfile $Exe $argLine
  if ($profile) { Write-Output "run_timeout: Godot profile: $profile" }
  $p = Start-WithGodotProfile $profile {
    if ($argLine -ne '') { Start-Process -FilePath $Exe -ArgumentList $argLine -NoNewWindow -PassThru }
    else { Start-Process -FilePath $Exe -NoNewWindow -PassThru }
  }
} catch {
  "$(Get-Date -Format s) START FAILED $Exe $argLine : $_" | Out-File $log -Append -Encoding utf8
  Write-Output "run_timeout: could not start $Exe : $_"
  exit 125
}
$null = $p.Handle   # keeps the exit code readable after the process ends
$tree = @{ }; $tree[$p.Id] = $p
$completed = $false
try {
$poll = 5000
if ($env:PC_RUNNER_TEST -eq '1' -and $env:PC_TEST_POLL_MS) { $poll = [int]$env:PC_TEST_POLL_MS }
while ($true) {
  Update-RunTree $tree
  $remaining = [Math]::Max(1, [Math]::Min($poll, ($Seconds - $timer.Elapsed.TotalSeconds) * 1000))
  if ($p.WaitForExit([int]$remaining)) { $p.WaitForExit(); $completed = $true; exit $p.ExitCode }
  # Scan the checkout once a minute to avoid walking a large repo on every poll.
  if ($timer.Elapsed.TotalSeconds -ge $nextScan) {
    $after = Get-RunProgress $watchRepo $logs
    if (Test-RunProgress $before $after) { $lastProgress = $timer.Elapsed.TotalSeconds }
    $before = $after
    $nextScan = $timer.Elapsed.TotalSeconds + $scanEvery
  }
  $reason = Get-StopReason $timer.Elapsed.TotalSeconds ($timer.Elapsed.TotalSeconds - $lastProgress) $Seconds $stall
  if ($p.HasExited) { $p.WaitForExit(); $completed = $true; exit $p.ExitCode }
  if ($reason) { break }
}
$secs = [int]$timer.Elapsed.TotalSeconds
Stop-RunTree $p $tree $log
Save-RunResume $watchRepo $watchOut $logs $reason $base
"$(Get-Date -Format s) TIMEOUT $reason after $secs s (ceiling $Seconds s), verified dead tree of PID $($p.Id): $Exe $argLine" | Out-File $log -Append -Encoding utf8
Write-Output "run_timeout: TIMEOUT $reason after $secs s, killed $Exe (PID $($p.Id)) and its children"
exit 124
} finally {
  # Reap on an unexpected watchdog error too. A successful queue launcher may deliberately start background jobs.
  if (-not $completed) {
    Update-RunTree $tree
    if (@($tree.Values | Where-Object { -not $_.HasExited }).Count) { Stop-RunTree $p $tree $log }
  }
  if ($completed) {
    # Only when no process this launch started is still alive (a queue launcher may leave background jobs on purpose).
    try { Update-RunTree $tree; if (-not @($tree.Values | Where-Object { -not $_.HasExited }).Count) { Remove-CreatedProfile } }
    catch { Write-Output "run_timeout: Godot profile kept for the janitor: $($_.Exception.Message)" }
  }
  foreach ($child in $tree.Values) { $child.Dispose() }
}
} finally {
  if ($gpuToken -and -not $retainGpuClaim) {
    & $gpuNode $gpuHelper release $gpuRoot $gpuToken
    if ($LASTEXITCODE -ne 0) { Write-Output "GPU: release failed. Claim $gpuToken will be checked at next admission" }
    else { Write-Output "GPU: released $gpuMode claim $gpuToken" }
  }
  if ($script:stepRecord -and -not $watch) {
    try { Write-StepRecord } catch { Write-Output "run_timeout: step record not written: $($_.Exception.Message)" }
  }
}
