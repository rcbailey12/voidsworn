$V='C:\Users\rcbai\Downloads\voidsworn_test'; Set-Location $V
$L="$V\board1119\saved_runs_delete_log_1122.txt"
$f0=(Get-PSDrive C).Free
"start $(Get-Date -f 'yyyy-MM-dd HH:mm:ss') C free {0:N1} GB (Ryan direct wake 04:21:36Z 'Yes remove saved runs')" -f ($f0/1GB) | Add-Content $L
foreach($p in Get-Content "$V\board1119\saved_runs_clean_1122.txt"){
 $full=Join-Path $V $p
 if($p -match '\*|\?' -or -not (Test-Path "$full\.git")){ "skip $p (not a checkout or wildcard)" | Add-Content $L; continue }
 $a=(Get-PSDrive C).Free; cmd /c "rd /s /q `"$full`"" 2>&1 | select -First 3 | % { "  err $_" | Add-Content $L }
 $b=(Get-PSDrive C).Free
 "{0} {1} gone={2} freed {3:N1} GB" -f (Get-Date -f HH:mm:ss),$p,(-not (Test-Path $full)),(($b-$a)/1GB) | Add-Content $L
}
$f1=(Get-PSDrive C).Free
"end $(Get-Date -f 'HH:mm:ss') freed {0:N1} GB, C free {1:N1} GB" -f (($f1-$f0)/1GB),($f1/1GB) | Add-Content $L
