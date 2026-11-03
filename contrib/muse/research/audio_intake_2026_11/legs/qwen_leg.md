Gate 1 (selector before send): Qwen3.8-Max. Gate 2 (header after generation): Qwen3.8-Max.
Container note: Qwen3.8-Max rejected inventory.tsv; the leg ran with inventory.md (the identical 879-row inventory in a markdown container) plus pack.md, both attached to the send message.

CUE: gun_shell
SET: boomLow
TAKES: extracted/rd25_bang/bang_01.ogg, extracted/rd25_bang/bang_02.ogg, extracted/rd25_bang/bang_03.ogg
GAIN: 0.6
NOTES: Low heavy detonation for a slow main-gun shell; stack three takes with a long 0.8 s fade to smooth the muzzle-to-impact tail.

CUE: gun_flak
SET: flakBang
TAKES: extracted/rd25_bang/bang_08.ogg, extracted/rd25_bang/shot_01.ogg, extracted/rd25_bang/shot_02.ogg
GAIN: 0.6
NOTES: Sharp mid-range bang for flak fragmentation; use the loudest take first and let the two shot takes provide a rapid crackle.

CUE: gun_las
SET: laserLarge
TAKES: extracted/littlerobot_scifi/Sci-Fi Sound Library/Wav/Laser/Laser_01.wav, extracted/littlerobot_scifi/Sci-Fi Sound Library/Wav/Laser/Laser_05.wav
GAIN: 0.6
NOTES: Large laser cannon with a clean beam onset; two takes at 0.58 s and 0.71 s provide a bright, heavy laser signature.

CUE: gun_plasma
SET: laserLarge
TAKES: extracted/rd60_scifi/sfx_01a.ogg, extracted/rd60_scifi/sfx_01b.ogg, extracted/rd60_scifi/sfx_01c.ogg
GAIN: 0.6
NOTES: Three plasma variants at 0.57-0.58 s; use a/b for the main shot and c for a lower-energy secondary.

CUE: gun_tracer
SET: tracerThump
TAKES: extracted/rd100_sfx/shot_02.ogg, extracted/rd100_sfx/hit_01.ogg, extracted/rd100_sfx/hit_02.ogg
GAIN: 0.6
NOTES: Short, punchy tracer fire; shot_02 gives the launch thump and the two hit takes add impact body.

CUE: gun_spine
SET: spineSnap
TAKES: extracted/rd60_scifi/sfx_03a.ogg, extracted/rd60_scifi/sfx_03b.ogg, extracted/rd60_scifi/sfx_03c.ogg
GAIN: 0.6
NOTES: Three spine variants at 0.46-0.51 s; use a/b for the main snap and c for a sharper, higher-pitched variant.

CUE: gun_needle
SET: laserSmall
TAKES: extracted/kenney_impact/Audio/impactGlass_light_000.ogg, extracted/kenney_impact/Audio/impactGlass_light_001.ogg, extracted/kenney_impact/Audio/impactGlass_light_002.ogg
GAIN: 0.4
NOTES: Light glass taps for a needle-like, high-frequency projectile; keep gain low to avoid a brittle, glassy edge.

CUE: gun_rail
SET: boomLow
TAKES: extracted/kenney_impact/Audio/impactMetal_heavy_001.ogg, extracted/kenney_impact/Audio/impactMetal_heavy_002.ogg, extracted/kenney_impact/Audio/impactMetal_heavy_003.ogg
GAIN: 0.8
NOTES: Heavy metal impacts for a railgun's massive kinetic strike; use the loudest take first and let the others provide a metallic resonance.

CUE: gun_glob
SET: globLaunch
TAKES: extracted/rd40_water_slime/slime_03.ogg, extracted/rd40_water_slime/slime_04.ogg, extracted/rd40_water_slime/slime_05.ogg
GAIN: 0.6
NOTES: Wet, organic slime launches; use the mid-range take first and let the other two provide a sticky, viscous tail.

CUE: salvo_tail
SET: boomLow
TAKES: extracted/rd25_bang/fw_06.ogg, extracted/rd25_bang/bang_06.ogg, extracted/rd25_bang/bang_07.ogg
GAIN: 0.6
NOTES: A long, rolling boom tail for a salvo's aftermath; use fw_06 for the initial crack and bang_06/07 for the sustained rumble.

CUE: lance
SET: laserLarge
TAKES: extracted/littlerobot_scifi/Sci-Fi Sound Library/Wav/Laser/Laser_06.wav, extracted/littlerobot_scifi/Sci-Fi Sound Library/Wav/Laser/Laser_07.wav
GAIN: 0.6
NOTES: Large lance laser with a clean, powerful beam; two takes at 0.71 s and 0.77 s provide a heavy, sustained laser signature.

CUE: lance_ion
SET: arc
TAKES: extracted/kenney_scifi/Audio/forceField_000.ogg, extracted/kenney_scifi/Audio/forceField_001.ogg, extracted/kenney_scifi/Audio/forceField_002.ogg
GAIN: 0.6
NOTES: Ion arc crackle with a force-field shimmer; use the first take for the main arc and the others for a layered, electric tail.

CUE: lance_dark
SET: laserLarge
TAKES: extracted/rd60_scifi/sfx_06.ogg, extracted/rd60_scifi/sfx_06b.ogg, extracted/rd60_scifi/sfx_18b.ogg
GAIN: 0.6
NOTES: Dark lance variants at 0.55-0.57 s; use sfx_06 for the main shot and sfx_06b/18b for lower, darker variants.

CUE: lance_choir
SET: laserSmall
TAKES: extracted/kenney_impact/Audio/impactBell_heavy_002.ogg, extracted/kenney_impact/Audio/impactBell_heavy_003.ogg, extracted/kenney_impact/Audio/impactBell_heavy_004.ogg
GAIN: 0.5
NOTES: Heavy bell strikes for a choir-like, resonant lance; use the loudest take first and let the others provide a harmonic tail.

CUE: torp
SET: whoosh
TAKES: extracted/kenney_scifi/Audio/explosionCrunch_000.ogg, extracted/kenney_scifi/Audio/explosionCrunch_001.ogg, extracted/kenney_scifi/Audio/explosionCrunch_002.ogg
GAIN: 0.6
NOTES: A whoosh-like launch using explosion crunch takes; use the first take for the main launch and the others for a layered, explosive tail.

CUE: torp_rocket
SET: rocketSalvo
TAKES: extracted/rd25_bang/cannon_03.ogg, extracted/rd25_bang/cannon_04.ogg, extracted/rd25_bang/cannon_05.ogg
GAIN: 0.7
NOTES: Rocket salvo using cannon takes; use the loudest take first and let the others provide a rapid, percussive launch sequence.

CUE: torp_sac
SET: sacExpel
TAKES: extracted/rd40_water_slime/slime_09.ogg, extracted/rd40_water_slime/slime_10.ogg, extracted/rd40_water_slime/slime_11.ogg
GAIN: 0.6
NOTES: Wet, organic sac expulsion; use the mid-range take first and let the other two provide a sticky, viscous tail.

CUE: torp_star
SET: whoosh
TAKES: extracted/kenney_impact/Audio/impactBell_heavy_000.ogg, extracted/kenney_impact/Audio/impactBell_heavy_001.ogg, extracted/kenney_impact/Audio/impactBell_heavy_002.ogg
GAIN: 0.5
NOTES: A star-like launch using heavy bell strikes; use the loudest take first and let the others provide a resonant, metallic tail.

CUE: torp_heavy
SET: whoosh
TAKES: extracted/kenney_impact/Audio/impactMetal_heavy_001.ogg, extracted/kenney_impact/Audio/impactMetal_heavy_002.ogg, extracted/kenney_impact/Audio/impactMetal_heavy_003.ogg
GAIN: 0.8
NOTES: Heavy torpedo launch using heavy metal impacts; use the loudest take first and let the others provide a massive, metallic resonance.

CUE: hit
SET: hullHit
TAKES: extracted/kenney_impact/Audio/impactMetal_medium_000.ogg, extracted/kenney_impact/Audio/impactMetal_medium_001.ogg, extracted/kenney_impact/Audio/impactMetal_medium_002.ogg
GAIN: 0.6
NOTES: Medium metal hull hits for a standard impact; use the first take for the main hit and the others for a layered, metallic tail.

CUE: hit_las
SET: hullHit
TAKES: extracted/kenney_scifi/Audio/laserSmall_002.ogg, extracted/kenney_scifi/Audio/laserSmall_003.ogg, extracted/kenney_scifi/Audio/laserSmall_004.ogg
GAIN: 0.6
NOTES: Small laser hull hits; use the first take for the main hit and the others for a layered, electric tail.

CUE: hit_plasma
SET: hullHitBig
TAKES: extracted/rd75_breaking/bfh1_hit_01.ogg, extracted/rd75_breaking/bfh1_hit_02.ogg, extracted/rd75_breaking/bfh1_hit_03.ogg
GAIN: 0.7
NOTES: Big plasma hull hits using breaking takes; use the loudest take first and let the others provide a massive, cracking tail.

CUE: hit_rail
SET: hullHitBig
TAKES: extracted/kenney_impact/Audio/impactPlate_heavy_000.ogg, extracted/kenney_impact/Audio/impactPlate_heavy_001.ogg, extracted/kenney_impact/Audio/impactPlate_heavy_002.ogg
GAIN: 0.8
NOTES: Heavy plate impacts for a railgun hull hit; use the loudest take first and let the others provide a massive, metallic resonance.

CUE: hit_wet
SET: wetImpact
TAKES: extracted/rd40_water_slime/splash_06.ogg, extracted/rd40_water_slime/splash_07.ogg, extracted/rd40_water_slime/splash_08.ogg
GAIN: 0.6
NOTES: Wet splash impacts for a watery hit; use the mid-range take first and let the other two provide a sticky, viscous tail.

CUE: hit_glass
SET: glassShatter
TAKES: extracted/kenney_impact/Audio/impactGlass_heavy_001.ogg, extracted/kenney_impact/Audio/impactGlass_heavy_002.ogg, extracted/kenney_impact/Audio/impactGlass_heavy_003.ogg
GAIN: 0.6
NOTES: Heavy glass shatter for a brittle hull hit; use the loudest take first and let the others provide a sharp, crystalline tail.

CUE: hit_ion
SET: arc
TAKES: extracted/rd60_scifi/sfx_02a.ogg, extracted/rd60_scifi/sfx_02c.ogg, extracted/rd60_scifi/sfx_02d.ogg
GAIN: 0.6
NOTES: Ion arc hits at 0.57-0.58 s; use a/c for the main hit and d for a sharper, higher-pitched variant.

CUE: shield
SET: shieldHit
TAKES: extracted/kenney_scifi/Audio/forceField_000.ogg, extracted/kenney_scifi/Audio/forceField_001.ogg, extracted/kenney_scifi/Audio/forceField_002.ogg
GAIN: 0.6
NOTES: Shield hit with a force-field shimmer; use the first take for the main hit and the others for a layered, electric tail.

CUE: shield_break
SET: shieldBig
TAKES: extracted/rd75_breaking/bfh1_breaking_01.ogg, extracted/rd75_breaking/bfh1_breaking_02.ogg, extracted/rd75_breaking/bfh1_breaking_03.ogg
GAIN: 0.7
NOTES: Big shield break using breaking takes; use the loudest take first and let the others provide a massive, cracking tail.

CUE: patter_hull
SET: hullPatter
TAKES: extracted/kenney_impact/Audio/impactMetal_light_000.ogg, extracted/kenney_impact/Audio/impactMetal_light_001.ogg, extracted/kenney_impact/Audio/impactMetal_light_002.ogg
GAIN: 0.4
NOTES: Light metal patter for rapid hull impacts; keep gain low to avoid a brittle, metallic edge.

CUE: patter_shield
SET: shieldPatter
TAKES: extracted/kenney_impact/Audio/impactGlass_light_000.ogg, extracted/kenney_impact/Audio/impactGlass_light_001.ogg, extracted/kenney_impact/Audio/impactGlass_light_002.ogg
GAIN: 0.4
NOTES: Light glass patter for rapid shield impacts; keep gain low to avoid a brittle, glassy edge.

CUE: engine
SET: engineLoop
TAKES: extracted/kenney_scifi/Audio/spaceEngineLow_000.ogg, extracted/littlerobot_scifi/Sci-Fi Sound Library/Wav/Engine/Engine_01.wav, extracted/littlerobot_scifi/Sci-Fi Sound Library/Wav/Engine/Engine_02.wav
GAIN: 0.5
NOTES: Engine loop using Kenney spaceEngineLow and Little Robot engine takes; use the Kenney take for the main loop and the Little Robot takes for a layered, mechanical tail.

CUE: cough
SET: engineCough
TAKES: extracted/rd100_sfx/machine_01.ogg, extracted/rd100_sfx/machine_02.ogg, extracted/rd100_sfx/machine_03.ogg
GAIN: 0.6
NOTES: Engine cough using machine takes; use the first take for the main cough and the others for a layered, mechanical tail.

CUE: puff
SET: rcsPuff
TAKES: extracted/rd100_sfx2/sfx100v2_air_03.ogg, extracted/rd100_sfx2/sfx100v2_air_04.ogg, extracted/rd100_sfx2/sfx100v2_air_05.ogg
GAIN: 0.5
NOTES: RCS puff using air takes; use the mid-range take first and let the other two provide a short, airy tail.

CUE: board_grapple
SET: hullHitBig
TAKES: extracted/rd40_water_slime/splash_04.ogg, extracted/rd40_water_slime/splash_05.ogg, extracted/rd40_water_slime/splash_06.ogg
GAIN: 0.7
NOTES: Boarding grapple using splash takes; use the mid-range take first and let the other two provide a wet, organic tail.

CUE: boom_s
SET: boomSmall
TAKES: extracted/kenney_scifi/Audio/explosionCrunch_000.ogg, extracted/kenney_scifi/Audio/explosionCrunch_001.ogg, extracted/kenney_scifi/Audio/explosionCrunch_002.ogg
GAIN: 0.6
NOTES: Small boom using explosion crunch takes; use the first take for the main boom and the others for a layered, explosive tail.

CUE: wreck
SET: scrape
TAKES: extracted/rd75_breaking/bfh1_falling_01.ogg, extracted/rd75_breaking/bfh1_falling_02.ogg, extracted/rd75_breaking/bfh1_falling_03.ogg
GAIN: 0.6
NOTES: Wreck scrape using falling takes; use the first take for the main scrape and the others for a layered, metallic tail.

CUE: death_crack
SET: scrape
TAKES: extracted/rd75_breaking/bfh1_breaking_02.ogg, extracted/rd75_breaking/bfh1_breaking_03.ogg, extracted/rd75_breaking/bfh1_breaking_04.ogg
GAIN: 0.7
NOTES: Death crack using breaking takes; use the loudest take first and let the others provide a massive, cracking tail.

CUE: death_run
SET: deathRun
TAKES: extracted/kenney_scifi/Audio/spaceEngineSmall_000.ogg, extracted/kenney_scifi/Audio/spaceEngineSmall_001.ogg, extracted/kenney_scifi/Audio/spaceEngineSmall_002.ogg
GAIN: 0.5
NOTES: Death run using small engine takes; use the first take for the main run and the others for a layered, mechanical tail.

CUE: ui_round
SET: roundBell
TAKES: extracted/kenney_impact/Audio/impactBell_heavy_000.ogg, extracted/kenney_impact/Audio/impactBell_heavy_002.ogg, extracted/kenney_interface/Audio/bong_001.ogg
GAIN: 0.3
NOTES: Kenney Impact bell (0.70-1.48 s) plus Kenney Interface bong (0.12 s) replace the synth chord with a recorded resonant round-start strike.

RISKS:
- torp / torp_rocket: Kenney Sci-Fi thrusterFire files are all 5.0 s loops, far outside the <=1.5 s launch one-shot scale; I substituted explosionCrunch, impactMetal, and RD25 cannon takes instead, but nobody has auditioned them in context.
- hit_wet: The named Freesound pick (Pound of Flesh, felixblume) is absent from the inventory; RD40 splashes are a rough wetness proxy but lack flesh specificity. FREESOUND FALLBACK.
- puff: Left the named Kenney Sci-Fi family for RD100 SFX2 air files because door/thruster patterns do not match vent-puff character; the 0.29 s take may be too short to read at low bus gain.
- engine / death_run: Both rely on 5 s Kenney spaceEngine loops as FREESOUND FALLBACK; loop trim points and wind-down shaping are unverified without listening.
- lance_dark: RD60 sfx_06 / sfx_06b / sfx_18b are labelled only by number; the "low variant" assumption is unconfirmed until audition.
- gun_las / lance: Little Robot takes are CC BY and gated on owner question Q1; if Q1 fails these six picks must be swapped to Kenney Sci-Fi or RD60 fallbacks.
