# 1373 PROBE16 at pin-1373i (Board, Nov 21 02:53 UTC; copy of probe1373h_prep.ps1): plain detach checkout of 84b6e3f4 in opus1373probe11\repo (stops if tracked changes), copies the GV2 and GW4 kits
# (assets\ships\<code>\ and gen\ships\<code>.*) from opus1373gv2i and opus1373gw4i, checks the five manifest_entry.json files exist. Exit 1 on any problem. Deletes nothing.
$V=Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'; $R=Join-Path $V 'opus1373probe11\repo'; $S='84b6e3f481f05d5728ffd407b00e492207db9b91'
$t=@(git -C $R status --porcelain --untracked-files=no); if($t.Count){ "FAIL: probe clone has $($t.Count) tracked changes; not checking out"; exit 1 }
git -C $R fetch -q (Join-Path $V 'repo-mirror.git') $S; git -C $R -c core.autocrlf=false checkout -q --no-overwrite-ignore --detach $S; if($LASTEXITCODE){ "FAIL: checkout $S refused"; exit 1 }
"clone at " + (git -C $R rev-parse HEAD)
foreach($x in @(@('opus1373gv2i','ithar_GV2'),@('opus1373gw4i','ithar_GW4'))){ $src=Join-Path $V "$($x[0])\repo\godot"
 if(-not (Test-Path "$src\assets\ships\$($x[1])\$($x[1]).glb")){ "FAIL: no $($x[1]) install in $($x[0])"; exit 1 }
 robocopy "$src\assets\ships\$($x[1])" "$R\godot\assets\ships\$($x[1])" /E /XF *.uid /NFL /NDL /NJH /NJS /NP | Out-Null
 Get-ChildItem "$src\gen\ships" -Filter "$($x[1]).*" | % { Copy-Item $_.FullName "$R\godot\gen\ships\" -Force }
 "kit $($x[1]) copied from $($x[0])" }
foreach($e in ($env:SQUADRON_ENTRIES -split ',')){ if(-not (Test-Path $e)){ "FAIL: missing entry $e"; exit 1 } }
"entries ok: " + ($env:SQUADRON_ENTRIES -split ',').Count
exit 0