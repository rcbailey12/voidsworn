@echo off
rem Voidsworn sound packs: Kenney CC0 packs + Sonniss GDC 2026 bundle (royalty free, no attribution)
set D=%USERPROFILE%\Downloads\voidsworn_sfx
mkdir "%D%" 2>nul
cd /d "%D%"
echo start %date% %time% > dl_log.txt
curl.exe -L -sS -o kenney_scifi.zip https://opengameart.org/sites/default/files/sci-fi_sounds.zip >> dl_log.txt 2>&1
curl.exe -L -sS -o kenney_interface.zip https://opengameart.org/sites/default/files/kenney_interfaceSounds.zip >> dl_log.txt 2>&1
curl.exe -L -sS -o kenney_rpg.zip https://opengameart.org/sites/default/files/RPGsounds_Kenney.zip >> dl_log.txt 2>&1
for %%k in (scifi interface rpg) do (
  mkdir kenney_%%k 2>nul
  tar -xf kenney_%%k.zip -C kenney_%%k >> dl_log.txt 2>&1
)
echo kenney done %time% >> dl_log.txt
mkdir sonniss 2>nul
for /L %%i in (1,1,5) do (
  echo part %%i start %time% >> dl_log.txt
  curl.exe -L -sS -C - --retry 5 -o sonniss_%%iof5.zip "https://downloads.sonniss.com/Sonniss.com-GDC2026-GameAudioBundle%%iof5.zip" >> dl_log.txt 2>&1
  tar -xf sonniss_%%iof5.zip -C sonniss >> dl_log.txt 2>&1
  if errorlevel 1 powershell -NoProfile -Command "Expand-Archive -Force sonniss_%%iof5.zip sonniss" >> dl_log.txt 2>&1
  echo part %%i done %time% >> dl_log.txt
)
powershell -NoProfile -Command "Get-ChildItem -Recurse -File -Include *.wav,*.ogg,*.flac,*.mp3 | Select-Object @{n='Path';e={$_.FullName.Substring((Get-Location).Path.Length+1)}},Length | Export-Csv -NoTypeInformation -Encoding UTF8 index.csv" >> dl_log.txt 2>&1
copy /y index.csv "%USERPROFILE%\Downloads\voidsworn_test\sfx_index.csv" >nul
copy /y dl_log.txt "%USERPROFILE%\Downloads\voidsworn_test\sfx_dl_log.txt" >nul
echo ALL DONE %date% %time% >> dl_log.txt
echo done > "%USERPROFILE%\Downloads\voidsworn_test\sfx_done.txt"
