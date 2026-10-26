# Download the candidate music pool (all CC0 or CC-BY, OpenGameArt) into Downloads\voidsworn_test\music\raw\.
# Files over 24 MB are split into 20 MB parts (name.part00, .part01 ...) so they fit the file bridge; the sandbox rejoins them.
# Log: Downloads\voidsworn_test\music\music_dl.log
$ErrorActionPreference = 'Continue'; $ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$root = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test\music'; $raw = Join-Path $root 'raw'
if (-not (Test-Path $raw)) { New-Item -ItemType Directory $raw -Force | Out-Null }
$log = Join-Path $root 'music_dl.log'
function L($s){ $t = (Get-Date -Format 'HH:mm:ss') + ' ' + $s; Write-Output $t; Add-Content -Path $log -Value $t }
$o = 'https://opengameart.org/sites/default/files/'
$list = @(
  @('war_theme_v2.ogg', 'war%20theme%20ver%202_0.ogg'),
  @('war_theme.ogg', 'war%20theme_0.ogg'),
  @('determined_pursuit_loop.wav', 'determined_pursuit_loop.wav'),
  @('qazijamjam.wav', 'QaziJamJam.wav'),
  @('nfm_tactical_thinking.wav', 'tactical_thinking.wav'),
  @('nfm_dark_times.wav', 'dark_times.wav'),
  @('nfm_heat_of_the_battle.wav', 'heat_of_the_battle.wav'),
  @('nfm_aftermath.wav', 'aftermath.wav'),
  @('the_final_battle.ogg', 'the_final_battle.ogg'),
  @('battle_theme_a.mp3', 'battleThemeA.mp3'),
  @('generic_trailer_music.mp3', 'Generic%20Trailer%20Music_0.mp3'),
  @('space_battle_bpm130.ogg', 'space_battle_bpm130_0.ogg'),
  @('heavy_battle_battle1.mp3', 'battle1.mp3'),
  @('dark_ambient_drone_loop.flac', 'dark_ambient_drone_loop.flac'),
  @('space_echo.ogg', 'space_echo.ogg'),
  @('outer_space_loop.mp3', 'outer_space_2.mp3'),
  @('continuum_mix.ogg', 'continuummix_0.ogg'),
  @('srg774_dark_scifi_ogg.zip', 'ogg.zip'),
  @('menacing_otherworld.mp3', 'ruskerdax_-_menacing_otherworld.mp3'),
  @('claimed_by_the_void_mix.ogg', 'claimed_by_the_void_mix_0.ogg'),
  @('cathedral.wav', 'cathedral.wav'),
  @('chapel_of_hate.mp3', 'Chapel%20of%20Hate%20v0_8.mp3'),
  @('some_militaristic_tune.ogg', 'march2_0.ogg'),
  @('soviet_style_march.mp3', 'Soviet%20march_0.mp3'),
  @('tribal_loop_1.wav', 'tribal_loop_1_1.wav'),
  @('tribal_loop_2.wav', 'tribal_loop_2_0.wav'),
  @('fanfare_random.ogg', 'fanfare_0.ogg'),
  @('ss_VICTORY.ogg', 'VICTORY_0.ogg'),
  @('ss_LOSE.ogg', 'LOSE_0.ogg'),
  @('ss_WIN_AGAINST_CHAMPION.ogg', 'WIN_AGAINST_CHAMPION_0.ogg'),
  @('ss_TITLE_BOUT.ogg', 'TITLE%20BOUT_0.ogg'),
  @('the_fallen_mp3.zip', 'The%20Fallen%20MP3_0.zip'),
  @('sad_game_over.wav', 'sad_game_over.wav')
)
foreach ($f in $list) {
  $dst = Join-Path $raw $f[0]
  if (-not (Test-Path $dst)) {
    try { Invoke-WebRequest -Uri ($o + $f[1]) -OutFile $dst -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0 voidsworn' }
          L ("ok " + $f[0] + " " + [math]::Round((Get-Item $dst).Length/1MB,1) + " MB") }
    catch { L ("FAILED " + $f[0] + " : " + $_.Exception.Message); if (Test-Path $dst) { Remove-Item $dst }; continue }
  } else { L ("have " + $f[0]) }
  $len = (Get-Item $dst).Length
  if ($len -gt 24MB) {
    $fs = [IO.File]::OpenRead($dst); $buf = New-Object byte[] (20MB); $i = 0
    while (($n = $fs.Read($buf, 0, $buf.Length)) -gt 0) {
      $p = $dst + ('.part{0:D2}' -f $i); $w = [IO.File]::Create($p); $w.Write($buf, 0, $n); $w.Close(); $i++ }
    $fs.Close(); L ("  split into " + $i + " parts")
  }
}
L 'MUSIC DL DONE'
