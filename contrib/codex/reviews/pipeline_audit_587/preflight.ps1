$ErrorActionPreference='Continue'
$repo='C:\Users\rcbai\Downloads\voidsworn_test\board\repo'
$p=Join-Path $env:TEMP 'voidsworn_audit_587'
$dest=Join-Path $p 'recipe_wrappers'
New-Item -ItemType Directory -Force $dest | Out-Null
$base='C:\Users\rcbai\Downloads\voidsworn_test'
$e=Get-Content "$repo\tools\recipe\env.bat" -Raw
$e=$e.Replace('set V=%USERPROFILE%\Downloads\voidsworn_test',"set V=$p\virtual_pc")
$e=$e.Replace('set B=%V%\',"set B=$base\").Replace('set BPY=%V%\',"set BPY=$base\").Replace('set GD=%V%\',"set GD=$base\")
$e=$e.Replace('for %%I in ("%~dp0..\..") do set REPO=%%~fI',"set REPO=$repo")
$e=($e -split "`n" | Where-Object {$_ -notmatch '^"%BPY%" -c "import scipy, PIL"'}) -join "`n"; Set-Content "$dest\env.bat" $e -Encoding ASCII
$env:SHIP='corsair_A16'; $env:RECIPE_NOPAUSE='1'
$rows=@()
foreach($f in (Get-ChildItem "$repo\tools\recipe\[1-7]_*.bat")){
 $s=(Get-Content $f.FullName -Raw) -replace '(?m)^pause\r?$','rem audit: unattended' -replace '& pause &','& ver &'
 # The one inline pause is only reached if a real shape ref exists; it does not in this isolated job.
 Set-Content "$dest\$($f.Name)" $s -Encoding ASCII
 & "$repo\tools\pc\tmo.bat" 60 $env:ComSpec /c "$dest\$($f.Name)" *> "$p\stage_$($f.BaseName).log"
 $rows += [pscustomobject]@{stage=$f.Name;exit=$LASTEXITCODE}
}
$rows | ConvertTo-Json | Set-Content "$p\stage_preflights.json" -Encoding UTF8
$rows | Format-Table
Get-ChildItem "$p\stage_*.log" | ForEach-Object { Select-String -LiteralPath $_.FullName -Pattern 'Stage [1-7] FAILED' }


