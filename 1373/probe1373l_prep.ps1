# 1373L PROBE17 prep (issue 1373 thread, Nov 21; copy of the Board's probe1373i_prep.ps1): plain detach checkout of board/pin-1373l (237fd5b2) in
# opus1373probe11\repo (stops if tracked changes), copies the KF1 kit from opus1373kf1l and the GV2 kit from opus1373gv2i, or from build\godot when
# opus1373gv2i was cleaned up; writes the GV2 entry to opus1373probe17\gv2_entry.json from whichever source it used. Exit 1 on any problem. Deletes nothing.
$V=Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'; $R=Join-Path $V 'opus1373probe11\repo'; $W=Join-Path $V 'opus1373probe17'; $S='237fd5b260efe1be2df04aba5492ed7d41e505c6'
$t=@(git -C $R status --porcelain --untracked-files=no); if($t.Count){ "FAIL: probe clone has $($t.Count) tracked changes; not checking out"; exit 1 }
git -C $R fetch -q (Join-Path $V 'repo-mirror.git') $S; git -C $R -c core.autocrlf=false checkout -q --no-overwrite-ignore --detach $S; if($LASTEXITCODE){ "FAIL: checkout $S refused"; exit 1 }
"clone at " + (git -C $R rev-parse HEAD)
function CopyKit($src, $code, $label){
 if(-not (Test-Path "$src\assets\ships\$code\$code.glb")){ return $false }
 robocopy "$src\assets\ships\$code" "$R\godot\assets\ships\$code" /E /XF *.uid /NFL /NDL /NJH /NJS /NP | Out-Null
 if(Test-Path "$src\gen\ships"){ Get-ChildItem "$src\gen\ships" -Filter "$code.*" | % { Copy-Item $_.FullName "$R\godot\gen\ships\" -Force } }
 Write-Host "kit $code copied from $label"; return $true }
if(-not (CopyKit (Join-Path $V 'opus1373kf1l\repo\godot') 'corsair_KF1' 'opus1373kf1l')){ "FAIL: no corsair_KF1 install in opus1373kf1l"; exit 1 }
$gv2e=Join-Path $V 'opus1373gv2i\out\recipe\export\ithar_GV2\manifest_entry.json'
if((Test-Path $gv2e) -and (CopyKit (Join-Path $V 'opus1373gv2i\repo\godot') 'ithar_GV2' 'opus1373gv2i')){ Copy-Item $gv2e (Join-Path $W 'gv2_entry.json') -Force; "GV2 entry from opus1373gv2i" }
else {
 $B=Join-Path $V 'build\godot'
 if(-not (CopyKit $B 'ithar_GV2' 'build\godot (published)')){ "FAIL: no ithar_GV2 in opus1373gv2i or build\godot"; exit 1 }
 if(Test-Path $gv2e){ Copy-Item $gv2e (Join-Path $W 'gv2_entry.json') -Force; "GV2 entry from opus1373gv2i\out" }
 else {
 $m=Get-Content (Join-Path $B 'assets\ships\manifest.json') -Raw | ConvertFrom-Json
 if(-not $m.ships.ithar_GV2){ "FAIL: build\godot manifest has no ithar_GV2 row"; exit 1 }
 $m.ships.ithar_GV2 | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 (Join-Path $W 'gv2_entry.json'); "GV2 entry from build\godot manifest" } }
foreach($e in ($env:SQUADRON_ENTRIES -split ',')){ if(-not (Test-Path $e)){ "FAIL: missing entry $e"; exit 1 } }
"entries ok: " + ($env:SQUADRON_ENTRIES -split ',').Count
exit 0
