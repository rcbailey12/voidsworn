# Ryan, Nov 22 15:35 UTC, his own message: "Yes cleanup the 318 staging folders".
# Removes only the board1119 staging folders the 09:32 check listed as PROVABLE, and only after re-proving each one
# right now: a git checkout whose HEAD equals its branch on origin (ls-remote) with a clean working tree (long paths on).
# Anything that no longer proves is kept and logged. Nothing else is touched.
$V = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$B = Join-Path $V 'board1119'
$L = Join-Path $V 'opus1119check\staging_clean_1122_log.txt'
$env:GIT_CONFIG_GLOBAL = 'NUL'
$list = Get-Content (Join-Path $V 'opus1119check\board1119_check_1122.txt') | ? { $_ -match '^\s*[\d.]+ GB\s+PROVABLE\s+(\S+)\s' } | % { $Matches[1] }
$f0 = (Get-PSDrive C).Free
Add-Content $L ("start {0}: {1} folders from the 09:32 check; C free {2:N1} GB" -f (Get-Date -f 'yyyy-MM-dd HH:mm:ss'), $list.Count, ($f0 / 1GB))
$gone = 0; $kept = 0
foreach ($n in $list) {
  $d = Join-Path $B $n
  if ($n -notmatch '^[A-Za-z0-9._-]+$' -or -not (Test-Path (Join-Path $d '.git'))) { Add-Content $L "kept $n (not a plain git folder now)"; $kept++; continue }
  $br = git -C $d branch --show-current
  $head = git -C $d rev-parse HEAD
  $remote = ((git -C $d ls-remote origin "refs/heads/$br" 2>$null) -split '\s')[0]
  $dirty = @(git -C $d -c core.longpaths=true -c core.autocrlf=false status --porcelain --untracked-files=all 2>$null).Count
  if (-not $br -or -not $remote -or $remote -ne $head -or $dirty) { Add-Content $L "kept $n (re-proof failed: branch '$br' local $head origin $remote dirty $dirty)"; $kept++; continue }
  $a = (Get-PSDrive C).Free
  cmd /c "rd /s /q `"\\?\$d`"" 2>&1 | select -First 2 | % { Add-Content $L "  err $_" }
  $ok = -not (Test-Path $d)
  if ($ok) { $gone++ } else { $kept++ }
  Add-Content $L ("{0} {1} ({2} at {3}) gone={4} freed {5:N2} GB" -f (Get-Date -f HH:mm:ss), $n, $br, $head.Substring(0, 8), $ok, (((Get-PSDrive C).Free - $a) / 1GB))
}
$f1 = (Get-PSDrive C).Free
Add-Content $L ("end {0}: removed {1}, kept {2}; freed {3:N1} GB, C free {4:N1} GB" -f (Get-Date -f HH:mm:ss), $gone, $kept, (($f1 - $f0) / 1GB), ($f1 / 1GB))
