# Ways-of-working audit (Nov 25 2026): give back the disk that the old relay branches still hold on the PC.
# On Nov 25 GitHub still carried 348 board/pc-out-* branches (pushed Nov 19 to 23, before results moved to the relay repo,
# issue 1657). Fetching them costs more than 21.9 GB; main with every job branch and PR is about 3.9 GB. Every shared mirror
# (repo-mirror*.git, fetched with +refs/*:refs/*) and every lane checkout (fetched with +refs/heads/*) holds its own refs to
# them, nothing in tools/pc ever runs git gc, and lanes are hard-linked clones of the mirror, so a pack only leaves the
# disk once the mirror AND every lane let go of it.
# Order: janitor live run (removes job checkouts while their receipts still exist), PRUNE_RELAY_BRANCHES_LIVE.bat
# (deletes the branches on GitHub), then this. Dry run unless -Live. Windows PowerShell 5.1.
#   compact_repos.ps1 [-Live] [-Root <voidsworn_test>]
param([switch]$Live, [string]$Root = (Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'))
$ErrorActionPreference = 'Stop'
$env:GIT_OPTIONAL_LOCKS = '0'
function Say([string]$t) { Write-Host $t }
function G { & git -c safe.directory=* @args; if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') failed ($LASTEXITCODE)" } }
function FreeGb { [math]::Round((Get-PSDrive -Name ($Root.Substring(0, 1))).Free / 1GB, 1) }

# Lanes must be idle: gc may drop an object another git process wrote a moment ago.
foreach ($q in @('queue', 'queue_b')) {
  $running = @(Get-ChildItem -LiteralPath (Join-Path $Root "$q\running") -File -Filter '*.bat' -ErrorAction SilentlyContinue)
  if ($running.Count -gt 0) { throw "$q has $($running.Count) running job(s); pause the lanes first (pause_all.bat)" }
}
$busy = @(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^(codex|opencode|git)\.exe$' })
if ($busy.Count -gt 0) { throw "$($busy.Count) codex, opencode or git process(es) running; wait for them or pause the lanes first" }
$ver = ((& git --version) -replace '[^0-9.]', '').Split('.')
if ([int]$ver[0] -lt 2 -or ([int]$ver[0] -eq 2 -and [int]$ver[1] -lt 29)) { throw "git $($ver -join '.') is older than 2.29: update Git for Windows first" }

$before = FreeGb
Say ("Free on the drive now: {0} GB. Mode: {1}" -f $before, $(if ($Live) { 'LIVE' } else { 'dry run (add -Live to clean)' }))
$mirrors = @(Get-ChildItem -LiteralPath $Root -Directory -Filter 'repo-mirror*.git' -ErrorAction SilentlyContinue)
foreach ($m in $mirrors) {
  $relay = @(G --git-dir $m.FullName for-each-ref --format='%(refname)' 'refs/heads/board/pc-out-*').Count
  Say ("{0}: {1} relay branches" -f $m.Name, $relay)
  if (-not $Live) { continue }
  # Same lock as Open-MirrorWriterLock in runner_common.ps1, so no runner fetches or clones while this runs.
  $lock = [IO.File]::Open("$($m.FullName).lock", 'OpenOrCreate', 'ReadWrite', 'None')
  try {
    G --git-dir $m.FullName fetch --no-auto-maintenance --prune origin
    G --git-dir $m.FullName -c gc.reflogExpire=now -c gc.reflogExpireUnreachable=now gc --prune=now --quiet
  } finally { $lock.Dispose() }
  Say ("  cleaned; relay branches left: {0}" -f @(G --git-dir $m.FullName for-each-ref --format='%(refname)' 'refs/heads/board/pc-out-*').Count)
}
$lanes = @(Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName '.git') -PathType Container })
foreach ($l in $lanes) {
  $refs = @(G -C $l.FullName for-each-ref --format='%(refname)' 'refs/remotes/origin/board/pc-out-*')
  if ($refs.Count -eq 0) { continue }
  Say ("{0}: {1} copied relay refs" -f $l.Name, $refs.Count)
  if (-not $Live) { continue }
  # Remote-tracking refs are copies of GitHub's; deleting them loses no work. Local branches and stashes are untouched.
  $refs | ForEach-Object { "delete $_" } | & git -c safe.directory=* -C $l.FullName update-ref --stdin
  if ($LASTEXITCODE -ne 0) { throw "update-ref failed in $($l.Name)" }
  # One hour of grace keeps any object a crashed run wrote just now; the relay objects are days old.
  G -C $l.FullName -c gc.reflogExpire=now -c gc.reflogExpireUnreachable=now gc --prune=1.hour.ago --quiet
}
Say ("Free on the drive after: {0} GB (was {1} GB)" -f (FreeGb), $before)
