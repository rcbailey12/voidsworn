# Issue 82: Audio sourcing - chair synthesis

Chair synthesis of four legs (Rey blind, DeepSeek, Qwen, Argon) against the verified evidence pack. The pack cue table is the authority for cue ids. Leg reports are filed verbatim under legs/ in this folder.

## Verdict

GO WITH CONDITIONS.

The sourcing plan below is settled enough to act on: a zero-download fix that removes the synth voice from 25 cues, a pack-led CC0 core for the rest, and an 8-slot music audition list. Three conditions bind it:

1. Downloads need the owner's OK. The issue states this. This deliverable is the list; intake is a separate owner-gated step (owner question Q3 is that gate for the CC0 core).
2. Nobody has listened to any candidate file in any leg. Every pick in this synthesis is metadata-level: pack descriptions, licence blocks, file sizes, and incumbent behaviour in cues.json. An audition and listen pass is a required intake step, not an optional extra (intake steps 3, 5 and 6).
3. Kenney pack sizes are unverified in every leg. The download total is therefore stated as a verified core plus named unverified items, and intake records the real sizes and restates the total (intake step 2).

## 1. Premise correction: what is actually synth today

The issue text says every cue is synthesised. That is wrong, and the correction changes the shape of the job.

Verified state (pack section 2, clone HEAD 80307a2):

- godot/audio/cues.json holds 67 cues.
- 52 of the 67 already carry at least one recorded clip layer. The recorded set is 52 Ogg files in 27 sets under godot/audio/clips/, 795,125 bytes on disk, sourced from Kenney (CC0) and the Sonniss GDC 2026 bundle (royalty free, no attribution required), per sfx_data.js line 1.
- 15 cues are synth-only in practice: 14 with layers: [] plus death_run, whose only layer is the synth take.
- Of the 52 recorded cues, 28 are pure recorded (no synth take plays) and 24 are hybrids: a recorded layer leads, but a synth layer is also present and plays. Arithmetic check: 28 pure + 24 hybrid + 15 synth-only = 67; 28 + 24 = 52 recorded.
- The synth side is 137 rendered takes (about 1.87 MB) rendered offline from the sfx.js recipes by godot/audio/build/render_synth.js. Playback rule (sfx.gd, function _layers): recorded layers play round robin; the synth take is appended only when no recorded layer played, or when a layer explicitly asks for it (a {"syn": 1} layer). The hybrid cues carry that explicit synth layer, which is why it sounds alongside the recording.
- Music is separate: 24 tracks in godot/music/music.json, 33,518,390 bytes (about 33.5 MB) on disk, all OpenGameArt CC0 or CC BY. See section 5 for a one-slot correction to the pack's music table.

Where the owner's complaint lands. "Music is not good, there are no real sound effects. It is just tinny and computer sounds" (Ryan, Nov 2, 2026) maps to three concrete targets, in order of exposure:

1. The 15 synth-only cues: pure oscillator and shaped-noise recipes, no recorded content at all.
2. The synth layer on the 24 hybrid cues: the recorded layer is present, but the synth voice rides on top of it on every play.
3. The music slots named in section 5.2: the Spring Spring soundfont tracks and the older cynicmusic orchestration. The other 16 music slots already fit FINDINGS R37 and loop cleanly, and all four legs keep them.

This job is therefore an upgrade and completion pass, not a from-zero sourcing pass. Job 5 (contrib/muse/research/audio_2026_11/synthesis.md) deferred exactly this work: per-cue real-source selection, and the faction music review beyond a Hullbreaker audition list.

## 2. The zero-download fix (build step 1)

Source: the Argon leg, checked by the chair against the pack. This is the single highest-value action in the package and it costs 0 bytes of download.

Action A: strip the "+ synth" layer from all 24 hybrid cues in godot/audio/cues.json. Each of these cues already has a recorded layer that leads (boomLow, laserLarge, hullHit, shieldHit, arc, whoosh, victory, enemyTurn and others). Removing the explicit synth layer leaves the recorded composite as the whole cue. The 24 cues are: gun_shell, gun_las, gun_plasma, gun_needle, gun_rail, salvo_tail, lance, lance_ion, lance_dark, lance_choir, torp, torp_star, torp_heavy, hit, hit_las, hit_plasma, hit_rail, hit_glass, hit_ion, shield, shield_break, boom_s, sting_win, sting_loss.

Action B: wire the existing enemyTurn recorded set into ui_enemy. The set already exists in godot/audio/clips/index.json and is already used by ui_alert and sting_loss, but ui_enemy itself is synth-only today despite the recorded set existing. Adding enemyTurn to ui_enemy's layers in cues.json kills that synth take at zero cost. In step 1, ui_alert keeps enemyTurn as well; giving ui_alert a distinct pulse is an optional step 3 upgrade, not a step 1 change.

Combined effect: the synth voice is removed from 25 cues (24 hybrids + ui_enemy) before anything is downloaded.

Why this is safe as a data change: the sfx.gd _layers rule appends the synth take only when no recorded layer played or a {"syn": 1} layer exists. Both actions are cues.json data edits, not code edits. The synth takes stay on disk and in git, so any cue that sounds thinner after the strip can have its synth layer restored individually. Verification is the existing audio checks after the edit (the Job 5 build was verified with the Godot headless AUDIO CHECK and SALVO CHECK; the same checks apply here).

This settlement is owner question Q2, because one leg (Rey blind) preferred removing synth only where a replacement lands. The chair pick is strip immediately; the dissent is recorded in section 10.

## 3. SFX sourcing: the pack-led CC0 core

All four legs converge on the same shape: packs first, per-file picks only for the gaps packs cannot cover. Nobody proposes a per-file hunt across all 67 cues, and nobody proposes a new Sonniss pull (section 6).

### 3.1 Core packs

The CC0 core is two pack families:

Rubberduck OpenGameArt packs (all CC0, sizes verified on the live pages by the blind Rey leg):

| Pack | Verified size | Main cue coverage (chair table, section 4) |
|---|---|---|
| 75 CC0 Breaking / Falling / Hit SFX | 1.6 MB | hit_heavy, hit_plasma, hit_rail, shield_break, wreck, death_crack, chunk_cool layers |
| 100 CC0 SFX | 2.9 MB | gun_tracer, patter_hull, cough, puff, pop, torp and UI fallbacks |
| 100 CC0 SFX 2 | cited in DeepSeek leg (2.4 MB, single-source) | patter and small-effect fallbacks |
| 100 CC0 Metal and Wood SFX | cited in DeepSeek leg (2.0 MB, single-source) | metal and wood hit fallbacks |
| 25 CC0 Bang / Firework SFX | 1.4 MB | gun_shell, gun_flak, salvo_tail, torp_rocket |
| 40 CC0 Water / Splash / Slime SFX | 2.3 MB | gun_glob, torp_sac, hit_wet fallback, board_grapple Chorus variant |
| 60 CC0 Sci-Fi SFX | UNVERIFIED (excluded from totals) | gun_sq, gun_plasma, gun_spine, lance_dark, lance_choir, torp_star, hit_ion, shield, patter_shield |

Kenney packs (kenney.nl; CC0 licence verified on the Kenney pages by the blind leg; sizes UNVERIFIED in all legs, excluded from totals, recorded at intake):

| Pack | Licence | Main cue coverage |
|---|---|---|
| Kenney Impact Sounds | CC0 (verified on page by blind leg; 130 files) | hit, hit_rail, hit_glass pattern, patter_hull, patter_shield, ui_round, torp_heavy pattern |
| Kenney Sci-Fi Sounds | CC0 (verified on page by blind leg; 70 files) | gun_las, lance family, torp family, engine, puff, boom_s, death_run patterns |
| Kenney Interface Sounds | CC0 (house licence; blind leg notes the crawled page showed no licence field, see section 12) | ui_round, ui_enemy upgrade, UI upgrade patterns |

Kenney file names in the Argon leg (for example impactMetal_heavy_000.ogg to 004.ogg, laserSmall_000.ogg, forceField_000.ogg, thrusterFire_000.ogg, explosionCrunch_000.ogg, spaceEngineLow_000.ogg) follow Kenney's known naming pattern but were not confirmed against a live pack listing. In section 4 they are cited as candidate patterns for intake to confirm, never as verified files.

### 3.2 Per-file Freesound CC0 picks and searches

Per-file picks are for the gaps packs cannot cover: glass, flesh, organic, engine. Two specific files were independently named by two legs each, and the chair adopts both as named picks:

| File | Licence | Size | Chair use |
|---|---|---|---|
| break-window by JasonElrod, freesound.org/people/JasonElrod/sounds/854244/ | CC0 | 64 KB | hit_glass primary named pick (named by DeepSeek; the glass gap is also the Qwen leg's first per-file search) |
| Pound of Flesh by felixblume, freesound.org/people/felixblume/sounds/203299/ | CC0 | 348.8 KB | hit_wet and hit_flesh character (named by DeepSeek; the flesh gap is also the Qwen leg's per-file search; note hit_flesh is not a cue id, the cue is hit_wet) |

Two further single-leg named files are recorded as audition candidates, not settled picks: glass shatter by ccen18 (freesound.org/people/ccen18/sounds/686849/, CC0, 310.0 KB, blind Rey leg) for hit_glass and the death_crack Ithar variant, to be auditioned alongside break-window; and Explosion 2 by qubodup (freesound.org/people/qubodup/sounds/843248/, CC0, 53.3 KB, blind Rey leg) as a boom_s layer candidate.

All other per-file needs are specified as Freesound CC0 searches to resolve at intake, following the Qwen leg's search list, because only DeepSeek named further specific files and its per-cue table cannot be trusted at id level (section 9.1). The search list: glob projectile / organic projectile (gun_glob refinement), organic swell (torp_sac refinement), flesh impact (hit_wet fallback), glass hit (hit_glass fallback), engine rumble thruster (engine), engine sputter (cough), air puff vent (puff), engine wind down (death_run). Every file resolved this way gets its licence checked file by file (Freesound licences are per file; only CC0 and CC BY qualify, and CC BY follows the Q1 ruling) and its size recorded at intake. This settlement is owner question Q5.

Three Job 5 names are carried as search hints only, per the pack: Glitterglass Ship Creaking B (wreck, hulk_vent upgrade hint), NenadSimic Muffled Distant Explosion (salvo_tail, boom_m upgrade hint), unfa Braam (bass_drop, ui_boss upgrade hint). Job 5's DeepSeek leg verified them as CC0 files; no leg in this pass verified a size for any of them, so none enters a total.

### 3.3 The attributed option: Little Robot (owner question Q1)

Little Robot Sound Factory, Sci-Fi Sound Effects Library, OpenGameArt, CC BY 3.0. Attribution line verified on the page by the blind leg: "Attribute Little Robot Sound Factory, and provide this link where possible: www.littlerobotsoundfactory.com". Contents as described on the page: 10 lasers, 3 spaceship engine loops, 3 warp drive sounds, 2 alarm loops, 4 ambiences, jingles (win, lose), menu select, robot sounds, 33 SFX.

Size: 42.3 MB, cited by the DeepSeek leg from the live page. The blind leg left the size unverified, and the Qwen leg estimated 150 to 200 MB. The chair rejects the Qwen estimate and adopts the DeepSeek cited figure, flagged single-source (section 7).

In the chair table it is the strongest single source for 10 to 12 cues: the laser and lance family, shields, phase (warp drive), engine (engine loops), ui_round and ui_alert (jingles and alarms), sting_win and sting_loss layers, death_powerdown. Whether it enters at all is owner question Q1. If Q1 fails, every cue that names it falls back to the CC0 core pattern named in the same row; no cue depends on it alone.

## 4. Per-cue disposition table (all 67 cues)

Reading the table:

- State: PURE (recorded only today), HYBRID (recorded layer plus synth layer today), SYNTH-ONLY (no recorded layer today; death_run is counted here because its only layer is the synth take).
- STRIP: remove the synth layer in build step 1 (section 2). The recorded layer becomes the whole cue at zero download cost.
- REPLACE: synth-only cue; a recorded replacement from section 3 lands in build step 3 and the synth take is removed as it lands.
- KEEP: no action; the incumbent recorded composite already satisfies the cue. Optional upgrades are audition candidates only.
- Pack and pattern names are defined in section 3. "Pattern" means an Argon-leg Kenney candidate file pattern for intake to confirm, not a verified file.
- Synth-only 15 are replaced or wired first in the build order: gun_flak, gun_tracer, gun_spine, gun_glob, torp_rocket, torp_sac, hit_wet, patter_hull, patter_shield, engine, cough, puff, death_run, ui_round, ui_enemy (ui_enemy is fixed by wiring in step 1 and needs no download).

### 4.1 Weapons (22)

| Cue | State | Chair disposition | Source / action | Notes |
|---|---|---|---|---|
| gun_shell | HYBRID | STRIP + UPGRADE | Keep boomLow; audition RD25 bang over it, Kenney Impact heavy pattern as fallback | Broadside body stays recorded; synth pitch drop goes in step 1 |
| gun_flak | SYNTH-ONLY | REPLACE | RD25 short bangs, two takes; fallback RD100 shot sounds | Recorded fireworks bangs described as usable for gun shots |
| gun_sq | PURE | KEEP | Incumbent laserSmall; optional upgrade Kenney Sci-Fi pattern or RD60SF variants | Already satisfies the cue |
| gun_las | HYBRID | STRIP + UPGRADE | Keep laserLarge; upgrade LRSF laser if Q1 passes, else Kenney Sci-Fi / RD60SF | Strongest LRSF candidate cue |
| gun_plasma | HYBRID | STRIP + UPGRADE | Keep laserLarge; upgrade RD60SF energy variant; fallback LRSF | Legs agree the synth vibrato sweep is the problem, not the recorded layer |
| gun_tracer | SYNTH-ONLY | REPLACE | RD100 shot sounds; fallback RD25 short bangs | Three-thump roll rebuilt from recorded takes |
| gun_spine | SYNTH-ONLY | REPLACE | RD60SF resonant variant; fallback rubberduck breaking snap pattern | Chorus spine fire; organic snap is the fallback character |
| gun_needle | HYBRID | STRIP + UPGRADE | Keep laserSmall; upgrade Kenney Impact glass pattern | Glasswright needle fire wants a crystalline transient, not sine partials |
| gun_rail | HYBRID | STRIP + UPGRADE | Keep boomLow; upgrade Kenney Impact heavy metal pattern; fallback incumbent arc + hullHitBig + boomLow composite | Gauss fire; the composite fallback costs 0 bytes |
| gun_glob | SYNTH-ONLY | REPLACE | RD40W slime primary; Freesound CC0 glob projectile search as refinement (section 3.2) | Bio weapon; real slime recordings are the direct fit |
| salvo_tail | HYBRID | STRIP + UPGRADE | Keep boomLow; upgrade RD25 long bang tail; NenadSimic hint as search fallback | Fires on the 4th salvo shot only |
| lance | HYBRID | STRIP + UPGRADE | Keep laserLarge; upgrade Kenney Sci-Fi sustained pattern or LRSF long laser if Q1 passes | Beam sustain is the gap |
| lance_ion | HYBRID | STRIP + UPGRADE | Keep arc; upgrade Kenney Sci-Fi forceField pattern; fallback LRSF | 880 Hz synth shimmer removed in step 1 |
| lance_dark | HYBRID | STRIP + UPGRADE | Keep laserLarge and bassDrop character; upgrade RD60SF low variant or Kenney spaceEngine pattern | Deathless lance must stay distinct from the bright family |
| lance_choir | HYBRID | STRIP + UPGRADE | Keep laserSmall; upgrade Kenney Impact glass / bell pattern | Four-sine synth chord is a named complaint target |
| torp | HYBRID | STRIP + UPGRADE | Keep whoosh; upgrade Kenney Sci-Fi thruster pattern; fallback incumbent launch + whoosh composite | Synth sub drop removed in step 1 |
| torp_rocket | SYNTH-ONLY | REPLACE | Kenney Sci-Fi thruster takes staggered x4, or RD25 staggered bangs | Corsair rocket salvos; four staggered launches |
| torp_sac | SYNTH-ONLY | REPLACE | RD40W slime swell primary; Freesound CC0 organic swell search as refinement | Chorus sac torpedo; wet expulsion character |
| torp_star | HYBRID | STRIP + UPGRADE | Keep whoosh; upgrade Kenney Impact bell / glass pattern | Glasswright star torpedo; crystalline shimmer over whoosh |
| torp_heavy | HYBRID | STRIP + UPGRADE | Keep whoosh + boomLow composite; upgrade Kenney Impact heavy pattern | The Argon 0-byte composite is the floor, not the fallback |
| charge | PURE | KEEP | Incumbent ionCharge; optional upgrade Kenney Sci-Fi powerUp pattern or LRSF activation if Q1 passes | Already a pure recorded charge |
| launch | PURE | KEEP | Incumbent launch; optional upgrade Kenney Sci-Fi thruster pattern | Three recorded takes already rotate |

### 4.2 Impacts (19)

| Cue | State | Chair disposition | Source / action | Notes |
|---|---|---|---|---|
| hit | HYBRID | STRIP + UPGRADE | Keep hullHit; upgrade Kenney Impact medium metal pattern; fallback hullHit alone after strip | Generic hull hit; strip alone is an acceptable end state |
| hit_heavy | PURE | KEEP | Incumbent hullHitBig + boomLow; optional upgrade RD75 heavy breaking hit | Two-layer recorded composite already |
| hit_las | HYBRID | STRIP + UPGRADE | Keep hullHit; upgrade Kenney Sci-Fi sear pattern | Synth sizzle replaced by a designed energy tail |
| hit_plasma | HYBRID | STRIP + UPGRADE | Keep hullHitBig (+ boomLow composite option at 0 bytes); upgrade RD75 big hit | Sub drop synth removed in step 1 |
| hit_rail | HYBRID | STRIP + UPGRADE | Keep hullHitBig; upgrade Kenney Impact plate pattern | Sharp plate strike fits rail impact |
| hit_wet | SYNTH-ONLY | REPLACE | Pound of Flesh (felixblume, CC0, 348.8 KB) named pick; fallback RD40W slime hit | Chorus flesh hit; the most specific per-file need in the set |
| hit_glass | HYBRID | STRIP + REPLACE synth layer | break-window (JasonElrod, CC0, 64 KB) named pick over incumbent shieldHit; audition ccen18 glass shatter (CC0, 310.0 KB) alongside; fallback Kenney Impact glass pattern | Glasswright glass hit; two CC0 files named across legs, both auditioned at intake |
| hit_ion | HYBRID | STRIP + UPGRADE | Keep arc; upgrade RD100 electric takes or RD60SF zap | Second recorded zap layer replaces synth buzz |
| shield | HYBRID | STRIP + UPGRADE | Keep shieldHit; upgrade Kenney Sci-Fi forceField pattern or RD60SF energy variant; LRSF shield if Q1 passes | Sine partial pairs removed in step 1 |
| shield_break | HYBRID | STRIP + UPGRADE | Keep shieldBig + shieldHit; upgrade RD75 shatter layer | Collapse reads from the recorded shatter, not the synth ring fall |
| patter_hull | SYNTH-ONLY | REPLACE | Kenney Impact light metal pattern; fallback RD100 metal taps | Five round-robin light hits per the Argon leg |
| patter_shield | SYNTH-ONLY | REPLACE | Kenney Impact glass light pattern + Kenney Sci-Fi forceField trimmed; fallback RD60SF ticks; Freesound CC0 search if both fail the listen | Small-arms shield patter |
| phase | PURE | KEEP | Incumbent whoosh + arc; optional upgrade LRSF WarpDrive if Q1 passes | Warp drive is an exact-function LRSF item, but the incumbent already works |
| engine | SYNTH-ONLY | REPLACE | Freesound CC0 engine rumble / thruster search primary (section 3.2); fallback Kenney spaceEngine pattern; LRSF engine loops if Q1 passes | Engine loops are the strongest single LRSF argument after lasers |
| cough | SYNTH-ONLY | REPLACE | Freesound CC0 engine sputter search primary; fallback RD100 machine chuff takes | Damaged engine; two short chuffs |
| puff | SYNTH-ONLY | REPLACE | Freesound CC0 air puff / vent search primary; fallback Kenney Sci-Fi short thruster / door pattern | RCS vent puff |
| arrive_jump | PURE | KEEP | Incumbent whoosh + boomLow | Job 5 landed composite; no action |
| board_grapple | PURE | KEEP base + UPGRADE variant | Keep hullHitBig + scrape + whoosh; Chorus variant adds RD40W wet latch layer | The cue already supports a faction variant; the upgrade uses that slot |
| brace_lock | PURE | KEEP | Incumbent hullHit + hullHitBig; optional upgrade Kenney Impact plate pattern | Job 5 landed composite; no action needed |

### 4.3 Explosions (6)

| Cue | State | Chair disposition | Source / action | Notes |
|---|---|---|---|---|
| pop | PURE | KEEP | Incumbent boomSmall; optional upgrade RD100 explosion take | Fighter destruction; already recorded |
| boom_s | HYBRID | STRIP + UPGRADE | Keep boomSmall + debris character; upgrade Kenney Sci-Fi explosionCrunch pattern; audition qubodup Explosion 2 (CC0, 53.3 KB) as a layer | Small ship deaths are frequent; this hybrid is heard constantly |
| boom_m | PURE | KEEP | Incumbent boomSmall + boomLow + debris | Three-layer pure recorded composite; the blind leg's CC BY medium explosion file is an audition candidate only and follows the Q1 principle, it is not in the settled core |
| boom_l | PURE | KEEP | Incumbent boomBig + debris, with bass_drop and wreck staged by death_audio.gd | No Sonniss pull for this cue (section 6); if the listen pass fails it, the fallback is layered RD75 debris over the incumbent, resolved at intake |
| bass_drop | PURE | KEEP | Incumbent bassDrop; unfa Braam as a search hint only | Sub drop is a designed element; incumbent is recorded and fits |
| wreck | PURE | KEEP + UPGRADE | Keep scrape; upgrade RD75 falling and cracking layer; Glitterglass Ship Creaking B as a search hint | Settle and groan after capital deaths |

### 4.4 Death (6)

All six are Godot-only cues staged by godot/audio/death_audio.gd (pack section 5).

| Cue | State | Chair disposition | Source / action | Notes |
|---|---|---|---|---|
| death_powerdown | PURE | KEEP | Incumbent ionCharge + whoosh; optional upgrade LRSF power-down if Q1 passes | Stage 1 of the big ship death sequence |
| death_vent | PURE | KEEP | Incumbent whoosh; optional upgrade Kenney Sci-Fi vent pattern | Fires at 0.25 s |
| death_crack | PURE | KEEP base + UPGRADE variant | Keep scrape + hullHitBig; base upgrade RD75 cracking; Ithar variant gets a real glass crack: audition break-window and the ccen18 shatter (section 3.2) | The cue already supports an Ithar faction variant; today the variant has no glass-specific source |
| death_run | SYNTH-ONLY | REPLACE | Freesound CC0 engine wind down search primary; fallback Kenney Sci-Fi spaceEngine + thruster composite (Argon) | The only synth-only death cue; small ship deaths play it before boom_s |
| chunk_cool | PURE | KEEP | Incumbent debris + scrape; optional upgrade Kenney Impact light tick pattern | Cooling chunk settle |
| hulk_vent | PURE | KEEP | Incumbent whoosh + scrape; Glitterglass hint as upgrade search | Hulk venting |

### 4.5 UI (14)

Note: sting_win and sting_loss here are SFX cues in cues.json. They are not the music sting slots (sting_victory, sting_fanfare, sting_champion, sting_lose in music.json, section 5.2). The two systems are separate.

| Cue | State | Chair disposition | Source / action | Notes |
|---|---|---|---|---|
| ui_click | PURE | KEEP | Incumbent uiClick; optional upgrade Kenney Interface pattern | Already recorded |
| ui_confirm | PURE | KEEP | Incumbent uiConfirm (also carries ui_plan at -3 dB per FINDINGS R74); optional upgrade Kenney Interface confirmation pattern | No separate ui_plan cue exists by owner ruling |
| ui_cancel | PURE | KEEP | Incumbent uiDeny; optional upgrade Kenney Interface back / error pattern | Already recorded |
| ui_select | PURE | KEEP | Incumbent uiSelect; optional upgrade Kenney Interface select pattern | Also the base of adapt_shift |
| ui_panel | PURE | KEEP | Incumbent uiPanel; optional upgrade Kenney Interface open pattern | Already recorded |
| ui_reward | PURE | KEEP | Incumbent reward; optional upgrade Kenney Interface confirmation pattern or LRSF jingle if Q1 passes | Already recorded |
| ui_round | SYNTH-ONLY | REPLACE | Kenney Impact bell pattern + Kenney Interface bong pattern (Argon); fallback RD100 bell takes; LRSF jingle if Q1 passes | Round start; synth chord replaced by a recorded resonant strike |
| ui_your | PURE | KEEP | Incumbent yourTurn; optional upgrade Kenney Interface confirmation pattern | Already recorded |
| ui_enemy | SYNTH-ONLY | WIRE (step 1) | Wire the existing enemyTurn set into ui_enemy in cues.json; optional upgrade Kenney Interface low tone pattern in step 3 | Zero-download fix, section 2 action B; no pack download gates this cue |
| ui_alert | PURE | KEEP | Incumbent enemyTurn stays on ui_alert in step 1; optional distinct pulse from Kenney Sci-Fi / Interface patterns in step 3 | Sharing the enemyTurn set with ui_enemy is acceptable; a distinct alert sound is an upgrade, not a fix |
| ui_boss | PURE | KEEP | Incumbent impactChord; unfa Braam as a search hint for an added brass layer | Flagship arrival banner |
| sting_win | HYBRID | STRIP | Keep victory set, remove the synth layer in step 1; Kenney Music Jingles upgrade belongs to the music sting audition (section 5.2) | The six-note synth scale over the recorded victory set is a named tinny source |
| sting_loss | HYBRID | STRIP | Keep enemyTurn + impactChord character, remove the synth layer in step 1 | Falling synth line removed |
| adapt_shift | PURE | KEEP | Incumbent uiSelect + uiSelect composite; optional upgrade Kenney Sci-Fi powerUp pattern | Job 5 landed composite; Nemesis adaptation signal |

Chair notes on disagreements inside the table: where the blind Rey leg named a specific pack take and the Argon leg named a Kenney pattern for the same cue, the chair kept the incumbent-first disposition (STRIP or KEEP) and listed both as audition candidates, because nobody has heard either. Where Qwen marked a hybrid cue KEEP (its analysis treats the recorded layer leading as sufficient), the chair overrules with STRIP, per section 2: a leading recorded layer does not silence the synth layer that the cue explicitly appends. Where the blind leg proposed the Sonniss bundle for boom_l, the chair holds KEEP per section 6.


## 5. Music: keep 16, audition 8

All judgements are against FINDINGS R37 (brass and tactical percussion in battle, a synth drone on the map, organ and machine sounds only as faction flavour) and R40 (CC0 or CC BY only, no NC, ND or SA, attribution lines stored as credit.attribution in music.json). Incumbents stay until a candidate beats them (section 5.3).

Chair correction to the pack table: the pack's other-slots table names 17 slots and its faction table names 6, for 23, but music.json holds 24 tracks. The missing slot is hot_heat (Heat of the Battle, NorthFantasyMusic, CC BY 3.0, Corsair intense layer), verified in godot/music/music.json in the repo. It is included below as a KEEP, which is how the keep count reaches 16.

### 5.1 Keep (16 slots)

| Slot | Incumbent | Licence | Why it stays |
|---|---|---|---|
| fac_voidsworn (Sunward Crusade, battle intense) | Chapel of Hate, FoxSynergy (organ and drums) | CC BY 3.0 | Organ is allowed as faction flavour under R37; this is the flavour exception working as intended. Argon allows an audition upgrade only if the organ reads as MIDI in play; no leg proposes replacement |
| fac_chorus (Chorus, bed at -9 dB) | Menacing Otherworld, Ruskerdax | CC0 | Alien bed under both layers; flavour role, never foreground |
| fac_ithar (Glasswrights, bed at -11 dB) | Airy, SRG774 | CC0 | Light crystalline bed; no direction conflict |
| fac_deathless (Eclipse, battle calm) | Claimed by the Void mix, vitalezzz / tricksntraps | CC0 | Machine pulse is allowed as faction flavour under R37 |
| map_sector | Sector, SRG774 | CC0 | Map synth drone, on direction |
| map_outer | Outer Space Loop, wipics | CC0 | Published as a loop; map drone |
| map_drone | Dark Ambient Drone, Tsorthan Grove | CC BY 3.0 | The R37 map drone in its clearest form |
| map_echo | Space Echo, Centurion_of_war | CC0 | Map ambient, on direction |
| map_signal | Title and Transmission, SRG774 | CC0 | Map sector 3, on direction |
| map_transmission | Signal Transmission, One Man Symphony | CC BY 4.0 | Map sector 3, on direction |
| calm_tactical | Tactical Thinking, NorthFantasyMusic | CC BY 4.0 | Tactical percussion and restrained tension; direct R37 fit |
| calm_darktimes | Dark Times, NorthFantasyMusic | CC BY 4.0 | Companion to calm_tactical by the same composer |
| hot_pursuit | Determined Pursuit, Emma_MA (horns, brass, drums) | CC BY 3.0 | Direct R37 fit |
| hot_qazi | QaziJamJam, Emma_MA | CC BY 3.0 | Same composer family as hot_pursuit; Argon allows an audition alongside it, no leg proposes replacement |
| hot_heat | Heat of the Battle, NorthFantasyMusic | CC BY 3.0 | War drums and intense percussion; direct R37 fit (see the chair correction above) |
| boss_final | The Final Battle, skrjablin | CC BY 3.0 | Boss layer at -16 LUFS target; Argon allows an optional upgrade audition, no leg proposes replacement. The blind leg's Pablo candidate is also auditioned here as a second slot (section 5.2) |

### 5.2 Audition list (8 slots)

Audition means: candidates are sourced, run through the intake standard in section 5.3, and listened to against the incumbent. The incumbent stays unless a candidate wins. Nothing in this list is a replacement verdict.

| Slot | Incumbent (stays until beaten) | Why it is on the list | Named candidates and directions |
|---|---|---|---|
| fac_corsair (Ashfall Hullbreakers, battle intense) | Heavy battle music, Davieplier, CC0 | Owner-flagged in Job 5: heard as thin MIDI war drums, stronger candidate requested | (1) Battle Theme A by cynicmusic, OpenGameArt content/battle-theme: DeepSeek cites CC BY 4.0 and 10.8 MB, single-source. Chair note: a track of this name already serves as the hot_theme_a incumbent, whose music.json credit reads CC0 1.0 for Battle Theme A by cynicmusic; the candidate page and licence must be rechecked at intake before the citation is relied on. (2) War Theme by cynicmusic, OpenGameArt content/war-theme: DeepSeek cites CC BY 4.0 and 5.4 MB, single-source, same recheck rule. (3) Space Boss Battle Theme (Orbital Colossus) by Matthew Pablo, OpenGameArt: CC BY 3.0, 6.1 MB verified on the page by the blind leg; flagged non-looping as published ("This track doesn't loop as it is", loopable version by contacting the author), so audition-only unless a loopable version is obtained. Direction from Argon: heavy war drums and low brass |
| fac_hegemony (Hegemony, battle calm) | Some Militaristic Tune, Spring Spring, CC0 | Spring Spring soundfont brass; Argon proposes replacement, Qwen and the blind leg keep it. Chair settles as audition, not replacement (section 10) | Modern sampled brass and percussion march loops in the NorthFantasyMusic / One Man Symphony line (composer-level direction from Argon; specific tracks UNVERIFIED, identified in the audition pass) |
| title_war | War Theme v2, Spring Spring, CC0 | Soundfont brass, strings and timpani on the game's first impression screen | Same NorthFantasyMusic / One Man Symphony direction: modern sampled orchestral brass and timpani (specific tracks UNVERIFIED) |
| hot_theme_a | Battle Theme A, cynicmusic, CC0 | Older cynicmusic orchestration; Argon flags the retro read against the NorthFantasyMusic calm layers it crossfades from | Same composer-level direction (specific tracks UNVERIFIED). Note the overlap with the fac_corsair candidate list: if the cynicmusic Battle Theme A candidate for fac_corsair turns out to be this same track, it cannot win fac_corsair by being itself; intake must source a distinct candidate or drop that line |
| sting_victory | VICTORY, Spring Spring, CC BY 3.0 | Spring Spring MIDI fanfare | Kenney Music Jingles (CC0, size UNVERIFIED) brass / percussion win jingle |
| sting_fanfare | Just a random fanfare, Spring Spring, CC BY 3.0 | Spring Spring MIDI fanfare | Kenney Music Jingles (CC0, size UNVERIFIED) fanfare sting |
| sting_champion | WIN AGAINST CHAMPION, Spring Spring, CC BY 3.0 | Spring Spring MIDI fanfare | Kenney Music Jingles (CC0, size UNVERIFIED) heavy brass and timpani sting |
| sting_lose | LOSE, Spring Spring, CC BY 3.0 | Spring Spring MIDI sting | Kenney Music Jingles (CC0, size UNVERIFIED) dark low brass sting |

The pattern the audition targets is consistent across legs: every slot on this list is built on the Spring Spring soundfont or the older cynicmusic orchestration, which is the plausible source of the "music is not good" half of the owner complaint. The 16 kept slots are the counter-evidence: they already use sampled or modern production and fit R37.

Scope is owner question Q4. The Qwen leg would audition fac_corsair only; the chair adopts the Argon 8-slot scope (section 10).

### 5.3 Audition standard

Every candidate for a looping slot must pass tools/music/process.py loopfind at 0.55 or better, be levelled by the same process (about -18 LUFS for loops, intense -17, boss -16, stings -16, true peak under -1 dBFS), and then win a listen against the incumbent. Stings do not loop, so loopfind does not apply to the four sting slots; the listen is the whole gate. Candidates are added through tools/music/selection.json only; music.json and CREDITS.md are generated and are never hand edited. A candidate with a loop defect as published (the Pablo track) is not eligible for a looping slot unless a loopable version is obtained.

## 6. Sonniss: settled, no new pull

All four legs converge, and the chair settles it here. It is not an owner question.

- No new Sonniss download. The blind leg cites the GDC bundle at 7.47 GB (secondary source: Bedroom Producers Blog, 2026-03-16, not verified on a Sonniss page) and quotes the licence v2.0 text from sonniss.com (effective 27 August 2026): a worldwide, non-exclusive, royalty-free licence for personal and commercial projects without attribution, with the redistribution flag quoted verbatim: "Licensee may not distribute, publish, sub-license or otherwise supply the sound effects as sound effects to any other person, without the Licensor's prior written permission" and "Licensee may not sell any of the sound effects as they come. (Although the sound effects may be sold as incorporated into licensee project)."
- That no-redistribution-as-SFX wording sits badly with a public repo that carries audio files. FINDINGS D22 closed the question for the existing clips only, on the owner's Oct 25, 2026 decision ("Disregard the Sonniss thing, we're fine"); it records a decision, not a licence clearance, and it does not extend to new material.
- Existing Sonniss clips stay, per FINDINGS R10 and D22. Nothing already in godot/audio/clips/ is removed by this synthesis.
- The DeepSeek leg's use of the bundle for boom_l and boom_xl is not adopted: boom_xl is not a cue id in cues.json, and boom_l is a pure recorded KEEP (section 4.3). The Qwen leg's proposal to draw additional files from the bundle is likewise not adopted.
- No cue in the settled plan depends on new Sonniss material. The one cue the blind leg assigned to it (boom_l) has an incumbent-first disposition and a CC0 fallback path.

## 7. Totals, stated honestly

No single grand total is stated, because part of the plan is verified and part is not, and a single figure would be false precision. Sizes are published sizes; processed in-game files will usually be smaller.

Verified:

| Item | Size | Basis |
|---|---|---|
| SFX verified core: rubberduck packs with verified sizes (RD75 1.6 MB, RD100 2.9 MB, RD25 1.4 MB, RD40W 2.3 MB, plus the DeepSeek-cited RD100 SFX 2 at 2.4 MB and Metal and Wood at 2.0 MB where used as fallbacks) plus the named per-file picks (break-window 64 KB, Pound of Flesh 348.8 KB, ccen18 shatter 310.0 KB, qubodup Explosion 2 53.3 KB) | About 10.06 MB for the blind leg's summed core (its SFX total: 10.0633 MB) | Live-checked on source pages by the blind Rey leg; the chair adopts its sum for the core it priced. The DeepSeek-cited fallback packs sit inside the same order of magnitude and are flagged single-source where they appear |
| Music audition candidate: Space Boss Battle Theme, Matthew Pablo | 6.1 MB | Verified on the OpenGameArt page by the blind leg |

Cited, single-source, flagged:

| Item | Size | Basis |
|---|---|---|
| Little Robot Sound Factory library (only if Q1 passes) | 42.3 MB | DeepSeek leg, cited from the live page. Blind leg left it unverified; Qwen estimated 150 to 200 MB, rejected by the chair (section 9.2) |
| Music audition candidates: cynicmusic Battle Theme A and War Theme | 10.8 MB and 5.4 MB (16.2 MB combined) | DeepSeek leg citations; licence lines also need the intake recheck described in section 5.2 |

Unverified and excluded from every total above:

- Kenney Impact Sounds, Kenney Sci-Fi Sounds, Kenney Interface Sounds: sizes UNVERIFIED in all legs (the Kenney pages do not state a download size). Recorded at intake (step 2).
- Rubberduck 60 CC0 Sci-Fi SFX: size UNVERIFIED (blind leg page crawl showed no size).
- Kenney Music Jingles: size UNVERIFIED in all legs.
- Sonniss GDC bundle: 7.47 GB secondary-source figure; excluded by the section 6 settlement in any case.
- All Freesound search-resolved files (section 3.2) and all composer-direction music candidates (section 5.2): do not exist as named items yet; sized at intake.

Existing audio already on disk, for scale: 795,125 bytes of SFX clips, about 1.87 MB of synth takes, and 33,518,390 bytes of music. The whole verified new SFX core is roughly twelve times the current clip set and still only about 10 MB.

## 8. Intake build order

For Codex or Opus, after the owner rulings on Q1 to Q5. Steps are in order; each step is independently checkable.

1. Zero-download fix (no owner download gate; covered by Q2). Strip the synth layer from the 24 hybrid cues and wire enemyTurn into ui_enemy, as cues.json data edits (section 2). Run the existing audio checks. Restore any individual synth layer the step 6 listen pass asks for, from git.
2. Download the CC0 core packs (owner OK gate: Q3). Download the rubberduck packs and Kenney Impact, Sci-Fi and Interface. Record the real zip sizes in the intake commit and restate the download total there, replacing the unverified entries in section 7 with measured figures.
3. Per-cue clip selection. For each REPLACE and UPGRADE cue in section 4, audition pack takes against the incumbent, select, convert to Ogg Vorbis (mono is the house norm for clips), land sets under godot/audio/clips/, register them in godot/audio/clips/index.json, point the cue layers in cues.json at them, and remove synth takes on replaced synth-only cues as each replacement lands. Resolve the section 3.2 Freesound CC0 searches in this step (Q5), checking each file's licence on its own page and recording its size. Confirm the Argon Kenney patterns against the real pack listings in this step.
4. Little Robot intake (only if Q1 passes). Download the library (42.3 MB cited), file its attribution line ("Attribute Little Robot Sound Factory, and provide this link where possible: www.littlerobotsoundfactory.com") into a new SFX credits text in the repo at intake, mirroring the music credit.attribution flow, and select its takes for the cues that name it in section 4.
5. Music audition (scope per Q4). Source the section 5.2 candidates, recheck the cynicmusic licence citations, run every looping candidate through tools/music/process.py (loopfind 0.55 or better), and hold incumbents in place until a candidate wins the listen in step 6. Add winners through tools/music/selection.json only.
6. Listen pass and sign-off. A listen over every replaced, stripped and wired cue, and every auditioned music slot, is the sign-off. The owner judges by ear. Any cue that reads thinner after its synth strip gets its synth layer restored or its upgrade re-auditioned before the pass closes. Nobody signs off on metadata alone.

## 9. Screenings

### 9.1 DeepSeek - used in part

Used: its pack list, its licence table, its totals framing (verified core stated separately from unverified items, Kenney sizes excluded), the Little Robot 42.3 MB figure, its two specific Freesound CC0 files (break-window and Pound of Flesh, both independently converged on by the Qwen leg's gap analysis), and its two named cynicmusic candidates for fac_corsair.

Not used: its per-cue table. It renames or invents cue ids that do not exist in cues.json, including gun_tach, gun_mag, gun_maser, gun_neut, torp_launch, torp_fly, torp_hit, torp_miss, lance_charge, lance_fire, lance_hit, board_grapple / board_cut / board_breach / board_fight as separate cues, brace_on / brace_off / brace_fail, bass_impact / bass_rumble, hull_creak / hull_stress, engine_idle / engine_boost / engine_damage, wreck_break / wreck_fall / wreck_settle, death_thud, hulk_creak / hulk_groan, chunk_break / chunk_fall, sting_win / sting_lose under wrong groupings, and adapt_low / adapt_high. The pack cue table is the authority, so its cue-level mapping does not survive contact with the pack and no row in section 4 rests on it. Its Sonniss assignments (boom_l, boom_xl) are also not used (section 6). Its risk-register pick on CC BY SFX (hold to CC0 until a credits surface exists, or build the surface first) is recorded as a partial dissent under Q1: the chair pick builds the credits text at intake, which is its second branch, but does not hold the whole pass to CC0 meanwhile.

### 9.2 Qwen - used with caveats

Used: its per-cue analysis, which uses the correct 67 cue ids throughout, including its KEEP / UPGRADE / REPLACEMENT calls and its note of the death_crack Ithar variant; its Freesound CC0 search list, adopted in section 3.2 as the intake resolution list; and its owner questions, two of which survive as dissents (section 10).

Caveats: it declares it could not open live web pages, so every new-source size in its report is an estimate and its verified total is 0 bytes of new material. Its Little Robot estimate of 150 to 200 MB is rejected in favour of the DeepSeek cited 42.3 MB. Its Sonniss estimate of 10 to 30 GB is superseded by the blind leg's 7.47 GB secondary figure, and the settlement in section 6 makes the number moot. Where its KEEP calls rest on "the recorded layer leads", the chair overrules for hybrid cues (section 4 chair notes), because the pack's playback rule shows the synth layer still plays.

### 9.3 Argon - used with the limits in its filed header

Used, with the two limits stated in the chair screening header on the filed leg: (1) it had no live web access, so no size figure in this synthesis rests on it; (2) its specific Kenney file names are candidate patterns for intake to confirm, not verified files.

Adopted from it, after checking each against the pack: the hybrid strip and the ui_enemy wiring gap (section 2, its structural findings hold against cues.json and clips/index.json); the 8-slot music audition scope (section 5.2); its 0-byte incumbent-composite fallbacks, several of which the chair promotes to floors in section 4 (gun_rail, hit_plasma, torp_heavy); and its per-cue picks where they agree with the pack-led shape. Its position that new Sonniss pulls stay out unless the owner explicitly clears them matches section 6.

### 9.4 Rey blind leg - primary source for verified sizes

The blind leg is the primary source for verified sizes (the rubberduck pack sizes, the three Freesound file sizes, the Pablo 6.1 MB) and for the pack-led shape of section 3. Its Sonniss licence quotation (v2.0, with the redistribution flag) is the text section 6 relies on. Two of its positions are not adopted: its proposal to assign boom_l to the Sonniss bundle (section 6) and its narrower hybrid policy (section 10, Q2). Its CC BY medium explosion file for boom_m and torp_heavy is recorded as an audition candidate only (section 4.3), because it is a single-leg CC BY per-file pick and the Q1 question is scoped to the Little Robot library.

## 10. Dissents

1. CC BY SFX intake. Qwen pick: hold SFX to CC0 for now (its Q1 option b). Argon pick: hold all new SFX strictly to CC0 this pass, with Little Robot demoted to a fallback for 9 cues (its owner question 1, option A). Rey blind and DeepSeek both include Little Robot (the blind leg with attribution lines filed in a plain repo SFX credits text at intake). Chair: put it to the owner as Q1 with a narrow yes pick (library only, credits text at intake). The dissent is recorded, not smoothed over: two of four legs would not take CC BY SFX in this pass at all.
2. fac_corsair handling. Qwen pick: keep the incumbent and commission a focused audition leg (its Q3). DeepSeek: named candidates now. Chair: the named candidates (DeepSeek's cynicmusic pair, the blind leg's Pablo track) go into the audition list now (section 5.2), with the licence recheck and the loop defect flagged; no separate commissioning round is needed to start the audition, and the incumbent stays until a candidate wins.
3. Music scope. Argon: targeted 8-slot audition list. Qwen: fac_corsair only (23 of 24 slots KEEP in its music table). Blind Rey leg: also near-total KEEP, with fac_hegemony and title_war explicitly kept. Chair: the 8-slot audition list, under the keep-until-beaten standard (section 5.3). Audition is not replacement, which is what makes the wider scope safe; but the disagreement is real: three legs saw no case to touch fac_hegemony or the stings, and the chair's case rests on the Argon leg's soundfont pattern argument.
4. Hybrid handling. Argon: strip the synth layer from all 24 hybrids immediately, alongside wiring ui_enemy. Rey blind: remove the synth take where a recorded replacement lands, keep it where the leg says KEEP with no replacement (its Q5). Chair: strip hybrids immediately, because a recorded layer already leads on every hybrid and the synth layer is the complaint; remove synth takes on synth-only cues as each replacement lands, which is the blind leg's mechanism applied to the cues it fits. The risk the blind leg's caution protects against is priced into step 6: the listen pass can restore any individual synth layer from git.

## 11. Owner questions

Exactly five. Chair pick marked on each. Stakes in plain words.

Q1. CC BY SFX intake: allow the Little Robot library (CC BY 3.0, 42.3 MB) as the one attributed SFX source, with its attribution line filed in a new SFX credits text at intake (CHAIR PICK: YES, narrow), vs hold SFX strictly to CC0 as Qwen and Argon advise. Stakes: Little Robot is the strongest single sci-fi weapons and shields source (10 to 12 cues: lasers, lances, shields, warp, engine loops, jingles). The music side already runs CC BY with attribution machinery; the gap is only an SFX credits surface, and the pick closes it with a plain credits text at intake rather than waiting for an in-game surface. Holding to CC0 leaves those cues to thinner pack coverage from Kenney and the rubberduck sci-fi pack.

Q2. Synth strip scope: strip the synth layer from all 24 hybrid cues and wire enemyTurn into ui_enemy immediately as build step 1 (CHAIR PICK), vs only where a replacement has landed. Stakes: zero download, and it kills the synth voice on 25 cues at once, which is most of what "tinny and computer sounds" points at on the SFX side. The risk is a hybrid that secretly leaned on its synth layer sounding thinner; the listen pass (step 6) catches that cue by cue, and the synth take is restorable from git for any single cue.

Q3. Download approval for the CC0 core: approve downloading the rubberduck packs plus Kenney Impact, Sci-Fi and Interface (CHAIR PICK), vs a smaller first batch. Stakes: this is the download the issue says needs your OK. The verified rubberduck side is about 10 MB; the Kenney sizes are not published and are recorded at intake, with the total restated in the intake commit. Nothing else in the SFX plan can be auditioned until the packs are local, so a smaller first batch mostly buys a second approval round later.

Q4. Music audition scope: the targeted 8-slot audition list (CHAIR PICK) vs fac_corsair only vs all 24 slots. Stakes: the 8 slots (fac_corsair, fac_hegemony, title_war, hot_theme_a, sting_victory, sting_fanfare, sting_champion, sting_lose) are every track built on the older soundfont or retro orchestration, which plausibly drives the "music is not good" half of the complaint. The other 16 already fit R37 and loop cleanly. Audition means incumbents stay until a candidate beats them in loopfind and by ear, so the wider list costs listening time, not stability. All 24 would re-open slots no leg found fault with.

Q5. Per-file Freesound picks: resolve the remaining gap cues (glass, flesh, organic, engine set) as specific Freesound CC0 files at intake, using the two named files (break-window for hit_glass, Pound of Flesh for hit_wet) plus the Qwen leg's search list (CHAIR PICK), vs approximating them from the packs. Stakes: these are the cues with the most specific recorded character (a glass hit for Glasswright hulls, a flesh hit for Chorus hulls, an engine run-down for small ship deaths). Pack approximations are the fallback if the per-file pass finds nothing with a clean CC0 line, but they are approximations: the character the owner will actually hear lives in the per-file picks.

## 12. Not checked

- No audio file, incumbent or candidate, was listened to by the chair or by any leg. Every fit judgement in this synthesis rests on pack data, source page descriptions, tags, licence blocks and file sizes.
- Kenney pack contents at file level. The Argon leg's Kenney file names are patterns; whether each named pattern exists in the current pack versions is an intake check (step 3), not verified here.
- Kenney Interface Sounds licence field on its own pack page: the blind leg's crawl showed no licence field and no size on that page; its CC0 status in section 3 rests on the Kenney house licence as verified on the Impact and Sci-Fi pages. Intake confirms it on the page or drops the pack.
- The DeepSeek cynicmusic citations (Battle Theme A CC BY 4.0 at 10.8 MB, War Theme CC BY 4.0 at 5.4 MB): single-source, and the Battle Theme A citation conflicts with the CC0 credit the same-named incumbent carries in music.json. Both are recheck items at intake (step 5), not verified facts.
- The Little Robot 42.3 MB size: single-source (DeepSeek). The blind leg could not verify it and Qwen's estimate was rejected, but no second live figure exists in the legs.
- The Sonniss 7.47 GB bundle size: secondary source only. The licence v2.0 text is quoted from the Sonniss site by the blind leg; the bundle's current availability and exact archive size were not verified, and section 6 makes both moot for this plan.
- Loop quality of the Pablo candidate beyond its own page statement, and loopfind scores for every music candidate: none has been run through tools/music/process.py in this pass.
- Whether the rubberduck 100 CC0 SFX 2 and 100 Metal and Wood pack sizes cited by DeepSeek (2.4 MB and 2.0 MB) match the live pages: single-source citations, used only for fallback rows.
- The browser build's copy of the same audio data (sfx.js SFX.MAP and sfx_data.js): the pack establishes that render_synth.js regenerates cues.json from sfx.js and preserves Godot-only cues, but no leg in this pass audited how an intake change propagates to the browser build. That is an Opus check at intake, flagged here rather than assumed.
- Prices: every source in this plan is free. No leg found a paid item worth proposing, and none is proposed.
