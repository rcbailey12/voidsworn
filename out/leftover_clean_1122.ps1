# Ryan, Nov 22 15:48 UTC, his own message: "Yes clean the four leg other groups" (the four leftover groups in
# opus1119check\next_check_1122.txt). Each item is re-proven right before removal; anything that fails is kept and logged.
$V = 'C:\Users\rcbai\Downloads\voidsworn_test'
$L = "$V\opus1119check\leftover_clean_1122_log.txt"
$env:GIT_CONFIG_GLOBAL = 'NUL'
$M = "$V\repo-mirror.git"
function Has($sha) { if (-not $sha) { return $false }; & git --git-dir $M cat-file -e "$sha^{commit}" 2>$null; return ($LASTEXITCODE -eq 0) }
function Remove-One($rel) {
  if (-not $rel -or $rel.Length -lt 10) { Add-Content $L "refused empty or short path"; return }
  $full = "$V\$rel"
  if (-not (Test-Path -LiteralPath $full)) { Add-Content $L "kept $rel (not found)"; return }
  $a = (Get-PSDrive C).Free
  Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction SilentlyContinue
  if (Test-Path -LiteralPath $full) { cmd /c "rd /s /q `"$full`"" 2>&1 | select -First 2 | % { Add-Content $L "  err $_" } }
  Add-Content $L ("{0} {1} gone={2} freed {3:N2} GB" -f (Get-Date -f HH:mm:ss), $rel, (-not (Test-Path -LiteralPath $full)), (((Get-PSDrive C).Free - $a) / 1GB))
}
$cl = (Get-CimInstance Win32_Process | % CommandLine) -join "`n"
$f0 = (Get-PSDrive C).Free
Add-Content $L ("start {0}: C free {1:N1} GB" -f (Get-Date -f 'yyyy-MM-dd HH:mm:ss'), ($f0 / 1GB))
# (1) repo-kept-*
foreach ($k in 'board\repo-kept-836469265b074cdd9b34aa7964afd780', 'board\repo-kept-673e0707a06a4f938ec278d063b715b1', 'board_b\repo-kept-1ff71d6a04814dadba964d1032d78f1f', 'board_b\repo-kept-afc8eaa1da8041579d7d7a0c666212c8') {
  $p = "$V\$k"
  if ($cl -match [regex]::Escape($k)) { Add-Content $L "kept $k (named by a running process)"; continue }
  $h = git -C $p rev-parse HEAD
  $lm = 0; foreach ($t in @(git -C $p for-each-ref --format='%(objectname)' refs/heads | select -Unique)) { if (-not (Has $t)) { $lm++ } }
  $dirty = @(git -C $p -c core.longpaths=true status --porcelain --untracked-files=no).Count
  if (-not (Has $h) -or $lm -or $dirty) { Add-Content $L "kept $k (re-proof failed: HEAD $h, tips missing $lm, tracked changes $dirty)"; continue }
  Add-Content $L "proved $k HEAD $($h.Substring(0,8))"; Remove-One $k
}
# (2), (3) failed-attempt checkouts
foreach ($k in 'opus1434t\out_20261122_061335_30692\new', 'opus1394meltb\out_20261122_015450_14441\new') {
  $p = "$V\$k"
  if ($cl -match [regex]::Escape(($k -split '\\')[0] + '\')) { Add-Content $L "kept $k (job named by a running process)"; continue }
  $h = git -C $p rev-parse HEAD
  $st = @(git -C $p -c core.longpaths=true -c core.autocrlf=false status --porcelain --untracked-files=all 2>&1)
  $bad = @($st | ? { "$_" -notmatch '^\?\? godot/assets/ships/manifest\.json\.bak_\d+_\d+$' -and "$_" -ne '?? godot/build_info.json' })
  if (-not (Has $h) -or $bad.Count) { Add-Content $L "kept $k (re-proof failed: HEAD $h on origin $(Has $h), other changes $($bad.Count): $($bad | select -First 3))"; continue }
  Add-Content $L "proved $k HEAD $($h.Substring(0,8)); only manifest.json.bak_* and build_info.json untracked"; Remove-One $k
}
# (4) stray git dir
$k = 'board1119\stray_git_1119v'
if ((Get-Content "$V\$k\HEAD" -ErrorAction SilentlyContinue) -eq 'ref: refs/heads/board/pc-out-1119v') { Add-Content $L "checked ${k}: HEAD names board/pc-out-1119v, which is on origin"; Remove-One $k } else { Add-Content $L "kept $k (HEAD file not as checked)" }
$f1 = (Get-PSDrive C).Free
Add-Content $L ("end {0}: freed {1:N1} GB, C free {2:N1} GB" -f (Get-Date -f HH:mm:ss), (($f1 - $f0) / 1GB), ($f1 / 1GB))
