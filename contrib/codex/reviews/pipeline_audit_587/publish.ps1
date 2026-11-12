Add-Type -AssemblyName System.Drawing
$p=Join-Path $env:TEMP 'voidsworn_audit_587'
$out=Join-Path $p 'publish'
New-Item -ItemType Directory -Force $out,"$out\raw","$out\sheet","$out\logs","$out\records","$out\asset","$out\scripts" | Out-Null
$font=New-Object System.Drawing.Font('Segoe UI',20,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
$small=New-Object System.Drawing.Font('Segoe UI',16,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Pixel)
$ink=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(12,17,24))
$white=[System.Drawing.Brushes]::White
foreach($f in (Get-ChildItem "$p\captures_final_verified\*.png")){
 Copy-Item $f.FullName "$out\raw\$($f.Name)"
 $src=[System.Drawing.Image]::FromFile($f.FullName)
 $bmp=New-Object System.Drawing.Bitmap(1280,720)
 $g=[System.Drawing.Graphics]::FromImage($bmp)
 $g.DrawImage($src,0,0,1280,720)
 $g.FillRectangle($ink,0,0,1280,76)
 $label=$f.BaseName.Replace('corsair_A16_','').Replace('_',' | ')
 $g.DrawString("corsair_A16 | $label",$font,$white,20,10)
 $g.DrawString('Issue 587 dry run | unpainted diagnostic | default export check FAILED',$small,$white,20,43)
 $bmp.Save("$out\$($f.Name)",[System.Drawing.Imaging.ImageFormat]::Png)
 $g.Dispose();$bmp.Dispose();$src.Dispose()
}
foreach($f in (Get-ChildItem "$p\sheet\*.png")){
 $src=[System.Drawing.Image]::FromFile($f.FullName)
 $bmp=New-Object System.Drawing.Bitmap(1280,720)
 $g=[System.Drawing.Graphics]::FromImage($bmp)
 $g.Clear([System.Drawing.Color]::FromArgb(28,33,40))
 $k=[math]::Min(1240.0/$src.Width,620.0/$src.Height)
 $w=[int]($src.Width*$k);$h=[int]($src.Height*$k)
 $g.DrawImage($src,[int]((1280-$w)/2),[int](82+(620-$h)/2),$w,$h)
 $g.DrawString("corsair_A16 | rebuilt sheet | $($f.BaseName)",$font,$white,20,12)
 $g.DrawString('Issue 587 | approved source rebuilt unchanged | quick render, 8 samples',$small,$white,20,44)
 $bmp.Save("$out\sheet\corsair_A16_$($f.BaseName).png",[System.Drawing.Imaging.ImageFormat]::Png)
 $g.Dispose();$bmp.Dispose();$src.Dispose()
}
$font.Dispose();$small.Dispose();$ink.Dispose()
$logs=@('sheet_build','raw_export','raw_audit','bridge','bridged_audit','bridged_export','export_check','export_selftest','recipe_standing','baked_attempt','lod','lod_bench','capture_final','target_export','target_export_check','engine_tolerance_diagnostic','env_probe','env_fixed_probe','scratch_install','standing_checks','game_import','gpu_gate','preflight_summary')
foreach($name in $logs){if(Test-Path "$p\$name.log"){Copy-Item "$p\$name.log" "$out\logs\$name.log"}}
Copy-Item "$p\stage_*.log" "$out\logs\"
$records=@('ship.json','ship_target.json','bridge_record.json','raw_audit.json','bridged_audit.json','stage_preflights.json','install_cache_record.json','read_receipt.json','engine_tolerance_diagnostic.json')
foreach($name in $records){Copy-Item "$p\$name" "$out\records\$name"}
Copy-Item "$p\sheet\corsair_A16_model.json","$p\sheet\corsair_A16_fit.json","$p\lod\corsair_A16_lods.json","$p\lod_bench\bench209.json","$p\captures_final_verified\interiors_cost.json" "$out\records\"
Copy-Item "$p\target_export\C19_51.glb","$p\target_export\C19_51_export.json","$p\target_export\C19_51_check.json","$p\target_export\manifest_entry.json","$p\target_export\export_status.txt" "$out\asset\"
Copy-Item "$p\sheet\corsair_A16_blockout.blend","$p\a16_bridged.blend" "$out\asset\"
Copy-Item "$p\run_sheet.ps1","$p\run_capture_final.ps1","$p\run_bench.ps1","$p\propose_env.py" "$out\scripts\"
Copy-Item 'contrib\codex\reviews\pipeline_audit_587\*' "$out\scripts\"
'PUBLISH_READY'
Get-ChildItem $out -Recurse -File | Measure-Object Length -Sum | Select-Object Count,Sum

