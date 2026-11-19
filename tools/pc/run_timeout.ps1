# Run a program with a ceiling and a progress watchdog (issues 818 and 1192).
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
using System.Runtime.InteropServices;
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
  for ($attempt = 1; ; $attempt++) {
    try { [IO.File]::AppendAllText($Log, "$(Get-Date -Format s) $Line`r`n"); return }
    catch [IO.IOException] {
      # Several watchdogs can report to the same queue log.
      if ($attempt -ge 10) { Write-Output "run_timeout: could not append kill log: $($_.Exception.Message)"; return }
      Start-Sleep -Milliseconds 25
    }
    catch { Write-Output "run_timeout: could not append kill log: $($_.Exception.Message)"; return }
  }
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
  do {
    # Discover children before stopping their parents, and repeat in case one spawned during taskkill.
    Update-RunTree $Tree
    $live = @($Tree.Values | Where-Object { -not $_.HasExited } | Sort-Object StartTime -Descending)
    foreach ($child in $live) {
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
  } while ([DateTime]::UtcNow -lt $deadline)
  $failure = "KILL FAILED: surviving PIDs $(($live | ForEach-Object { $_.Id }) -join ', '); checkout kept"
  Write-KillLog $Log $failure
  throw $failure
}
function Initialize-StepWatchdog {
  # Start suspended and assign the job before any child code can spawn a process. Windows keeps descendants in
  # the job even after their parent exits and accounts for CPU used by children that exit between polls.
  Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;

public sealed class RunnerStep : IDisposable {
  [StructLayout(LayoutKind.Sequential)]
  struct Startup {
    public int size;
    public IntPtr reserved, desktop, title;
    public int x, y, width, height, xChars, yChars, fill, flags;
    public short show, reservedSize;
    public IntPtr reservedBytes, input, output, error;
  }
  [StructLayout(LayoutKind.Sequential)]
  struct ProcessInfo {
    public IntPtr process, thread;
    public int pid, tid;
  }
  [StructLayout(LayoutKind.Sequential)]
  public struct Usage {
    public long UserTime, KernelTime, PeriodUserTime, PeriodKernelTime;
    public uint PageFaults, Total, Active, Terminated;
    public long CpuTime { get { return UserTime + KernelTime; } }
  }
  [DllImport("kernel32.dll", SetLastError = true)] static extern IntPtr CreateJobObject(IntPtr attrs, IntPtr name);
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool SetInformationJobObject(IntPtr job, int kind, byte[] data, int size);
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool QueryInformationJobObject(IntPtr job, int kind, out Usage data, int size, IntPtr written);
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool TerminateJobObject(IntPtr job, uint code);
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool TerminateProcess(IntPtr process, uint code);
  [DllImport("kernel32.dll", SetLastError = true)] static extern uint ResumeThread(IntPtr thread);
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool SetHandleInformation(IntPtr handle, uint mask, uint flags);
  [DllImport("kernel32.dll")] static extern IntPtr GetStdHandle(int number);
  [DllImport("kernel32.dll")] static extern IntPtr GetCurrentProcess();
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool DuplicateHandle(IntPtr source, IntPtr handle, IntPtr target, out IntPtr copy, uint access, bool inherit, uint options);
  [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr handle);
  [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
  static extern bool CreateProcess(string exe, StringBuilder command, IntPtr processAttrs, IntPtr threadAttrs,
    bool inherit, uint flags, IntPtr env, string cwd, ref Startup startup, out ProcessInfo info);

  readonly IntPtr job;
  public Process Root { get; private set; }
  public RunnerStep(bool gpu) {
    job = CreateJobObject(IntPtr.Zero, IntPtr.Zero);
    if (job == IntPtr.Zero) throw new Win32Exception();
    if (!gpu) return; // A successful ordinary queue launcher may leave background work running.
    // JOBOBJECT_EXTENDED_LIMIT_INFORMATION, LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE.
    byte[] limits = new byte[IntPtr.Size == 8 ? 144 : 112];
    limits[17] = 0x20;
    if (!SetInformationJobObject(job, 9, limits, limits.Length)) {
      var error = new Win32Exception();
      CloseHandle(job);
      throw error;
    }
  }
  public void Start(string exe, string args, string cwd, string output, string error) {
    using (var stdout = new FileStream(output, FileMode.CreateNew, FileAccess.Write, FileShare.ReadWrite))
    using (var stderr = new FileStream(error, FileMode.CreateNew, FileAccess.Write, FileShare.ReadWrite)) {
      var startup = new Startup { size = Marshal.SizeOf(typeof(Startup)), flags = 0x100 }; // STARTF_USESTDHANDLES
      startup.output = stdout.SafeFileHandle.DangerousGetHandle();
      startup.error = stderr.SafeFileHandle.DangerousGetHandle();
      if (!SetHandleInformation(startup.output, 1, 1) || !SetHandleInformation(startup.error, 1, 1))
        throw new Win32Exception();
      // A caller may have no stdin (for example, the queue running under a service).
      IntPtr self = GetCurrentProcess();
      DuplicateHandle(self, GetStdHandle(-10), self, out startup.input, 0, true, 2);
      ProcessInfo info;
      try {
        var command = new StringBuilder("\"" + exe + "\" " + args);
        if (!CreateProcess(exe, command, IntPtr.Zero, IntPtr.Zero, true, 4, IntPtr.Zero, cwd, ref startup, out info))
          throw new Win32Exception();
      } finally {
        if (startup.input != IntPtr.Zero) CloseHandle(startup.input);
      }
      bool started = false;
      try {
        if (!AssignProcessToJobObject(job, info.process)) throw new Win32Exception();
        Root = Process.GetProcessById(info.pid);
        var handle = Root.Handle; // Keep the process identity and its exit code after exit.
        if (ResumeThread(info.thread) == UInt32.MaxValue) throw new Win32Exception();
        started = true;
      } finally {
        if (!started) TerminateProcess(info.process, 125);
        CloseHandle(info.thread);
        CloseHandle(info.process);
      }
    }
  }
  public Usage ReadUsage() {
    Usage usage;
    if (!QueryInformationJobObject(job, 1, out usage, Marshal.SizeOf(typeof(Usage)), IntPtr.Zero))
      throw new Win32Exception();
    return usage;
  }
  public void Kill() {
    if (!TerminateJobObject(job, 124)) throw new Win32Exception();
  }
  public void Dispose() {
    if (Root != null) Root.Dispose();
    CloseHandle(job);
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
  // One shared list for Godot, Blender and other steps. Keep the matched phrase in the log reason.
  static readonly Regex fatal = new Regex("Jolt Physics job system exceeded|Out of memory|Assertion failed", RegexOptions.IgnoreCase);
  static readonly Regex errorLine = new Regex(@"\b(error|fatal|exception|failed|failure|assertion)\b", RegexOptions.IgnoreCase);
  readonly FileStream source;
  readonly Stream target;
  readonly byte[] bytes = new byte[65536];
  readonly char[] chars = new char[65536];
  readonly Decoder decoder = Encoding.UTF8.GetDecoder();
  readonly StringBuilder line = new StringBuilder();
  string previousError;
  int repeats;
  bool longLine;
  public string KnownFatal { get; private set; }
  public bool RepeatedError { get; private set; }
  public bool Pending { get { return source.Position < source.Length; } }
  public RunnerStepOutput(string path, bool stderr) {
    source = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
    target = stderr ? Console.OpenStandardError() : Console.OpenStandardOutput();
  }
  public void ResetRepeats() { previousError = null; repeats = 0; RepeatedError = false; }
  public bool Drain(bool scan) {
    int count = source.Read(bytes, 0, bytes.Length);
    if (count == 0) return false;
    target.Write(bytes, 0, count);
    target.Flush();
    if (!scan) return true;
    int length = decoder.GetChars(bytes, 0, count, chars, 0);
    for (int i = 0; i < length; i++) {
      if (chars[i] == '\n') {
        string text = line.ToString().Trim();
        ScanFatal(text);
        if (longLine || !errorLine.IsMatch(text)) { previousError = null; repeats = 0; }
        else {
          repeats = text == previousError ? repeats + 1 : 1;
          previousError = text;
          if (repeats >= 50) RepeatedError = true;
        }
        line.Clear();
        longLine = false;
      } else if (line.Length == 8192) {
        ScanFatal(line.ToString());
        line.Remove(0, 4096);
        longLine = true;
        line.Append(chars[i]);
      } else line.Append(chars[i]);
    }
    ScanFatal(line.ToString());
    return true;
  }
  void ScanFatal(string text) {
    if (KnownFatal != null) return;
    var match = fatal.Match(text);
    if (match.Success) KnownFatal = match.Value;
  }
  public void Dispose() { source.Dispose(); }
}
'@
}
function Get-StepLimit($Value, $Default, $Name) {
  $number = $Default
  if ($Value -and ($Value -notmatch '^\d+$' -or -not [int]::TryParse($Value, [ref]$number) -or $number -lt 1)) {
    throw "$Name must be a positive number of seconds"
  }
  return $number
}
function Stop-StepTree($Job, $Log, $Step) {
  # Keep the claim while Windows still reports active processes, including during cleanup after a watchdog error.
  while (($usage = $Job.ReadUsage()).Active) {
    try { $Job.Kill() }
    catch { Write-KillLog $Log "$Step kill failed, retrying with GPU claim held: $($_.Exception.Message)" }
    Start-Sleep -Milliseconds 50
  }
  Write-KillLog $Log "$Step kill verified: all $($usage.Total) processes gone (root PID $($Job.Root.Id))"
}
if ($LibraryOnly) { return }
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
  Initialize-RunTree
} else {
  Initialize-StepWatchdog
  $stepName = $env:TMO_STEP
  if (-not $stepName) { $stepName = [IO.Path]::GetFileName($Exe) }
  $stepOut = $env:TMO_STEP_OUT
  if (-not $stepOut) { $stepOut = $watchOut }
  if (-not $stepOut -and $argLine -match '(?:^|\s)--out(?:\s+|=)(?:"([^"]+)"|(\S+))') {
    $stepOut = if ($Matches[1]) { $Matches[1] } else { $Matches[2] }
  }
  $idleDefault = if ([IO.Path]::GetFileName($Exe) -match '^(Godot|Voidsworn)') { 300 } else { 600 }
  $idleSeconds = Get-StepLimit $env:TMO_IDLE_S $idleDefault 'TMO_IDLE_S'
  if ($env:PC_RUNNER_TEST -ne '1') { $idleSeconds = [Math]::Max($idleDefault, $idleSeconds) }
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
$canReleaseGpu = $true
try {
$classify = @{ exe = $Exe; args = $argLine; cwd = (Get-Location).Path; requested = [string]$env:PC_GPU_MODE; weight = [string]$env:PC_GPU_WEIGHT } | ConvertTo-Json -Compress
$gpuClass = ($classify | & $gpuNode $gpuHelper classify) -join ''
if ($LASTEXITCODE -ne 0) { throw 'GPU command classification failed' }
$gpuClass = $gpuClass | ConvertFrom-Json
$gpuMode = $gpuClass.mode
$soloMax = 0
if ($gpuMode -and $watch) { throw 'a GPU claim must wrap one step; clear TMO_REPO, TMO_OUT and TMO_LOG' }
if ($gpuMode -eq 'solo') {
  $soloMax = Get-StepLimit $env:PC_GPU_SOLO_MAX_S 1200 'PC_GPU_SOLO_MAX_S'
}
if ($gpuMode) {
  Write-Output "GPU: waiting for $gpuMode claim, weight $($gpuClass.weight) (issue $env:PC_GPU_ISSUE)"
  # Admission has its own clock in gpu_slots.js (PC_GPU_WAIT_SECONDS, default 300).
  # Read the helper's diagnostic even under Windows PowerShell's native stderr handling.
  $ea = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    & $gpuNode $gpuHelper acquire $gpuRoot ([string]$env:PC_GPU_ISSUE + ':gpu') $PID $gpuMode $gpuClass.weight 2>&1 | ForEach-Object {
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
    exit 126
  }
  Write-Output "GPU: acquired $gpuMode claim $gpuToken"
}
# A forced claim applies to this command only, never a nested watchdog.
$env:PC_GPU_MODE = ''
$env:PC_GPU_WEIGHT = ''
$env:PC_GPU_SOLO_MAX_S = ''
$env:TMO_IDLE_S = ''; $env:TMO_STEP = ''; $env:TMO_STEP_OUT = ''
# Child commands may use tmo.bat too. Their own timeout must never overwrite this agent's resume note.
$env:TMO_REPO = ''; $env:TMO_OUT = ''; $env:TMO_LOG = ''; $env:TMO_ERR_LOG = ''
if (-not $watch) {
  $spool = Join-Path ([IO.Path]::GetTempPath()) ("runner-step-" + [Guid]::NewGuid().ToString('N'))
  $outPath = Join-Path $spool 'stdout.log'
  $errPath = Join-Path $spool 'stderr.log'
  $job = $files = $stdout = $stderr = $null
  $keepSpool = $true
  $finished = $false
  try {
    $cwd = (Get-Location).Path
    $target = if (Test-Path -LiteralPath $Exe -PathType Leaf) { (Get-Item -LiteralPath $Exe).FullName }
              else { (Get-Command -Name $Exe -CommandType Application | Select-Object -First 1).Source }
    $arguments = $argLine
    if ($target -match '\.(bat|cmd)$') {
      $arguments = '/d /s /c ""' + $target + '" ' + $argLine + '"'
      $target = $env:ComSpec
    }
    if ($stepOut) { $stepOut = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($stepOut) }
    $files = [RunnerStepFiles]::new([string]$stepOut)
    $job = [RunnerStep]::new([bool]$gpuToken)
    $null = [IO.Directory]::CreateDirectory($spool)
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $job.Start($target, $arguments, $cwd, $outPath, $errPath)
    $canReleaseGpu = $false
  } catch {
    # No child code runs unless Start attached it to the job and resumed it.
    if ($job -and $job.Root) { Stop-StepTree $job $log $stepName }
    if ($job) { $job.Dispose() }
    if ($files) { $files.Dispose() }
    Write-KillLog $log "START FAILED $stepName ($Exe): $($_.Exception.Message)"
    exit 125
  }
  try {
    $stdout = [RunnerStepOutput]::new($outPath, $false)
    $stderr = [RunnerStepOutput]::new($errPath, $true)
    $lastProgress = 0.0
    $lastCpu = 0
    $lastFiles = 0
    while ($true) {
      $readOut = $stdout.Drain($true)
      $readErr = $stderr.Drain($true)
      $fatal = if ($stdout.KnownFatal) { $stdout.KnownFatal } else { $stderr.KnownFatal }
      # The two streams have separate handles. Any output on the other stream breaks a repeat streak.
      if ($readOut) { $stderr.ResetRepeats() }
      if ($readErr) { $stdout.ResetRepeats() }
      $elapsed = $timer.Elapsed.TotalSeconds
      $usage = $job.ReadUsage()
      $fileCount = $files.Changes
      if ($readOut -or $readErr -or $usage.CpuTime -gt $lastCpu -or $fileCount -ne $lastFiles) {
        $lastProgress = $elapsed
      }
      $lastCpu = $usage.CpuTime
      $lastFiles = $fileCount
      $pendingOutput = $stdout.Pending -or $stderr.Pending
      if ($fatal) { $reason = "FATAL $fatal"; break }
      if ($stdout.RepeatedError -or $stderr.RepeatedError) { $reason = 'FATAL repeated error line 50 times'; break }
      if ($soloMax -and $claimTimer.Elapsed.TotalSeconds -ge $soloMax) { $reason = "SOLO CAP after $soloMax s"; break }
      if ($job.Root.HasExited -and (-not $gpuToken -or -not $usage.Active) -and -not $pendingOutput) {
        $finished = $true
        $keepSpool = [bool]$usage.Active
        if ($keepSpool) { Write-Output "run_timeout: background output continues in $spool" }
        exit $job.Root.ExitCode
      }
      if ($elapsed -ge $Seconds) { $reason = 'CEILING'; break }
      if ($elapsed - $lastProgress -ge $idleSeconds) { $reason = "IDLE after $idleSeconds s without output, new files or CPU progress"; break }
      if (-not $pendingOutput) {
        $waitMs = [Math]::Min(250, ($Seconds - $elapsed) * 1000)
        $waitMs = [Math]::Min($waitMs, ($idleSeconds - ($elapsed - $lastProgress)) * 1000)
        if ($soloMax) { $waitMs = [Math]::Min($waitMs, ($soloMax - $claimTimer.Elapsed.TotalSeconds) * 1000) }
        Start-Sleep -Milliseconds ([int][Math]::Max(1, $waitMs))
      }
    }
    $stoppedAfter = [Math]::Round($elapsed, 3)
    Stop-StepTree $job $log $stepName
    $canReleaseGpu = $true
    $finished = $true
    # Descendants have closed their streams. Copy the last bytes before reporting the stop.
    while ($stdout.Drain($false)) { }
    while ($stderr.Drain($false)) { }
    Write-KillLog $log "TIMEOUT $stepName ($Exe): $reason at $stoppedAfter s (ceiling $Seconds s). Child logs: $spool"
    exit 124
  } finally {
    if (-not $finished) { Stop-StepTree $job $log $stepName }
    $canReleaseGpu = $true
    if ($stdout) { $stdout.Dispose() }
    if ($stderr) { $stderr.Dispose() }
    $files.Dispose()
    $job.Dispose()
    if (-not $keepSpool) {
      # Only delete these two files and the empty scratch directory we created.
      try {
        [IO.File]::Delete($outPath)
        [IO.File]::Delete($errPath)
        [IO.Directory]::Delete($spool)
      } catch { Write-Output "run_timeout: child log cleanup failed in $spool : $($_.Exception.Message)" }
    }
  }
}
# Outer agents keep their original separate logs and repo/commit progress checks.
$timer = [Diagnostics.Stopwatch]::StartNew()
$lastProgress = 0.0
$scanEvery = 60.0
if ($env:PC_RUNNER_TEST -eq '1' -and $env:PC_TEST_SCAN_S) { $scanEvery = [double]$env:PC_TEST_SCAN_S }
$nextScan = $scanEvery
try {
  if ($argLine -ne '') { $p = Start-Process -FilePath $Exe -ArgumentList $argLine -NoNewWindow -PassThru }
  else { $p = Start-Process -FilePath $Exe -NoNewWindow -PassThru }
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
  foreach ($child in $tree.Values) { $child.Dispose() }
}
} finally {
  if ($gpuToken) {
    if ($canReleaseGpu) {
      & $gpuNode $gpuHelper release $gpuRoot $gpuToken
      if ($LASTEXITCODE -ne 0) { Write-Output "GPU: release failed; dead owner PID $PID will be reclaimed" }
      else { Write-Output "GPU: released $gpuMode claim $gpuToken" }
    }
  }
}
