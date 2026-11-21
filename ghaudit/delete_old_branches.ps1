# Deletes the old branches listed in deleted_branches.tsv (Ryan "Yes to all", Nov 21 2026, R385). Run on the PC with gh as rcbailey12.
# Skips any branch whose tip moved since the list was made, and every board/* branch (never listed).
# Restore one: git push origin <sha>:refs/heads/<name>   (shas are in the list; PR heads also stay under refs/pull/N/head)
$ErrorActionPreference = 'Continue'
$list = Join-Path $PSScriptRoot 'deleted_branches.tsv'
$log  = Join-Path $PSScriptRoot 'delete_log.txt'
$done = 0; $skip = 0; $fail = 0
Get-Content $list | Where-Object { $_ -match '^DEL' } | ForEach-Object {
  $f = $_ -split "`t"; $name = $f[1]; $sha = $f[2]
  if ($name -like 'board/*') { $skip++; return }
  $tip = gh api "repos/rcbailey12/voidsworn/branches/$name" --jq .commit.sha 2>$null
  if (-not $tip) { Add-Content $log "gone  $name"; return }
  if ($tip -ne $sha) { Add-Content $log "moved $name (kept)"; $skip++; return }
  gh api -X DELETE "repos/rcbailey12/voidsworn/git/refs/heads/$name" 2>$null
  if ($LASTEXITCODE -eq 0) { Add-Content $log "del   $name $sha"; $done++ } else { Add-Content $log "fail  $name"; $fail++ }
}
"deleted $done, kept $skip, failed $fail (log: $log)"
