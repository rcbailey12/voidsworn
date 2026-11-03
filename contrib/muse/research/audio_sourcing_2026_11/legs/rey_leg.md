# Voidsworn Issue 82 - Audio Sourcing - Rey Leg (blind)

## 1. Headline

Approach: pack-led. Four CC0 packs (rubberduck 75 Breaking/Falling/Hit, rubberduck 100 CC0 SFX, rubberduck 25 Bang/Firework, rubberduck 40 Water/Splash/Slime) plus Kenney Impact, Kenney Sci-Fi and rubberduck 60 CC0 Sci-Fi cover most cues with coherent, licence-clean sources; per-file Freesound CC0 picks fill only glass, explosion and flesh gaps.
LIST AND SIZE ONLY. Nothing was downloaded. Nobody has listened to any candidate file; every pick below rests on the source page description, tags and metadata, written as "described as" where relevant.
Combined verified total download size: 16.2 MB approx (SFX 10.1 MB verified + Music 6.1 MB verified). All larger candidates (Kenney packs, Sonniss GDC 2026 at a reported 7.47 GB, Little Robot Sci-Fi Library, 60 CC0 Sci-Fi) are UNVERIFIED for size and are excluded from that total, listed separately in section 5.

Short source key used in the tables:
- RD75 = rubberduck, 75 CC0 breaking / falling / hit sfx, OpenGameArt, https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx , Licence: CC0 (page License(s): CC0), Size: 1.6 Mb verified on page ("sfx_breaking_and_falling.zip 1.6 Mb")
- RD100 = rubberduck, 100 CC0 SFX, OpenGameArt, https://opengameart.org/content/100-cc0-sfx , Licence: CC0, Size: 2.9 Mb verified ("100-CC0-SFX.zip 2.9 Mb"), described as recorded with an Android device, includes explosion, glass, hit, metal, shot, slam, splash, machine, switch
- RD25 = rubberduck, 25 CC0 bang / firework SFX, OpenGameArt, https://opengameart.org/content/25-cc0-bang-firework-sfx , Licence: CC0, Size: 1.4 Mb verified, page says "I recorded 25 bang / firework / cannon / explosions from fireworks" and "a few short bangs usable for gun shots"
- RD40W = rubberduck, 40 CC0 water / splash / slime SFX, OpenGameArt, https://opengameart.org/content/40-cc0-water-splash-slime-sfx , Licence: CC0, Size: 2.3 Mb verified, includes 16 slime partly recorded from real slime, 15 splash, bubbles and loops
- RD60SF = rubberduck, 60 CC0 Sci-Fi SFX, OpenGameArt, https://opengameart.org/content/60-cc0-sci-fi-sfx , Licence: CC0 (title and multiple independent credits on OpenGameArt and itch.io list CC0), Size: UNVERIFIED (live page crawl did not show the file size)
- K-IMP = Kenney, Impact Sounds, https://kenney.nl/assets/impact-sounds , Licence: Creative Commons CC0 (page field "License: Creative Commons CC0", 130 files), Size: UNVERIFIED (Kenney pack page shows no download size)
- K-SF = Kenney, Sci-Fi Sounds, https://kenney.nl/assets/sci-fi-sounds , Licence: Creative Commons CC0 (70 files, tags sci-fi, space, engine), Size: UNVERIFIED (no size on page)
- K-INT = Kenney, Interface Sounds, https://kenney.nl/assets/interface-sounds , Licence: CC0 per Kenney support statement that all Kenney packs are CC0, Size: UNVERIFIED (crawled pack page showed no licence field and no size; see Not checked)
- LRSF = Little Robot Sound Factory, Sci-Fi Sound Effects Library, OpenGameArt, https://opengameart.org/content/sci-fi-sound-effects-library , Licence: CC BY 3.0 (per independent credits citing that page), Attribution line verified on page: "Attribute Little Robot Sound Factory, and provide this link where possible: www.littlerobotsoundfactory.com", Size: UNVERIFIED (live page crawl did not show file size), contents described as 10 lasers, 3 spaceship engine loops, 3 warp drive, 2 alarm loops, 4 ambiences, jingles (win, lose), menu select, robot sounds, 33 SFX in MP3 and WAV
- SONNISS = Sonniss #GameAudioGDC Bundle (2026 edition named in pack), Licence page https://sonniss.com/gdc-bundle-license/?disabled , Licence line quoted in section 4, Size: UNVERIFIED for this leg (7.47 GB, 347 files, reported by Bedroom Producers Blog 2026-03-16, a secondary source, not verified on a Sonniss download page)
- FS-GLASS = Freesound, glass shatter by ccen18, https://freesound.org/people/ccen18/sounds/686849/ , Licence: Creative Commons 0 (page: "Creative Commons 0 - You can copy, modify, distribute and perform the sound, even for commercial purposes"), Size: 310.0 KB verified, described as dropping metal cutlery on a glass-ceramic surface, 0.801 s, WAV 48 kHz stereo
- FS-EXP2 = Freesound, Explosion 2 (Burning Car rec by Nado) by qubodup, https://freesound.org/people/qubodup/sounds/843248/ , Licence: Creative Commons 0, Size: 53.3 KB verified, 0.564 s, WAV mono
- FS-EXPM = Freesound, Explosion Outdoors (Medium) by EvanBoyerman, https://freesound.org/people/EvanBoyerman/sounds/753843/ , Licence: CC BY (page: "You are free to share and to remix as long as you credit the author of the sound" - exact attribution text to be taken from the page Get attribution link at intake), Size: 1.5 MB verified, 5.553 s, described as pitched-down gun shots layered, realistic outdoor explosion
- KEEP = incumbent recorded layer already in game per pack section 3, source Kenney CC0 or Sonniss GDC 2026 royalty-free as stated in pack, no new download, size 0 new

Fallback rule: where a first choice is UNVERIFIED for size, the fallback is a verified-size pack covering a nearby function, and vice versa.

## 2. Per-cue table - all 67 cues

### Weapons (22)

| Cue | Chosen source | Link | Licence | Size / pack | Why it fits (one line) | Fallback |
|---|---|---|---|---|---|---|
| gun_shell | RD25 bang for cannon body + KEEP boomLow layer | https://opengameart.org/content/25-cc0-bang-firework-sfx | CC0 | RD25 1.4 Mb (pack counted once) | Described as recorded cannon and firework bangs, real recording replaces synth pitch drop | K-IMP |
| gun_flak | RD25 short bangs, two quick takes (synth-only cue, real replacement) | https://opengameart.org/content/25-cc0-bang-firework-sfx | CC0 | RD25 pack | Short bangs described as usable for gun shots give two real pops | RD100 shot sounds |
| gun_sq | RD60SF squadron laser / shot variants | https://opengameart.org/content/60-cc0-sci-fi-sfx | CC0 | RD60SF UNVERIFIED size | Pack is sci-fi shots with 2 to 3 variations per sound, matches small craft fire | K-SF, KEEP laserSmall |
| gun_las | LRSF laser (10 lasers described) + KEEP laserLarge | https://opengameart.org/content/sci-fi-sound-effects-library | CC BY 3.0, attribution line in section 1 | LRSF UNVERIFIED size | Designed laser set, stronger than synth sweep; needs CC BY intake ruling (Q1) | K-SF (CC0) |
| gun_plasma | RD60SF energy variant + KEEP laserLarge | https://opengameart.org/content/60-cc0-sci-fi-sfx | CC0 | RD60SF UNVERIFIED | Sci-fi energy shots in a CC0 pack, no attribution burden | LRSF laser |
| gun_tracer | RD100 shot sounds (synth-only cue, real replacement) | https://opengameart.org/content/100-cc0-sfx | CC0 | RD100 2.9 Mb pack | Pack lists shot sounds among recorded household and metal recordings | RD25 short bangs |
| gun_spine | RD60SF resonant sci-fi variant (synth-only cue) | https://opengameart.org/content/60-cc0-sci-fi-sfx | CC0 | RD60SF UNVERIFIED | Chorus spine fire needs an alien energy shot; pack variations allow a distinct pick | RD40W slime layer under RD60SF |
| gun_needle | K-SF high laser / scan sounds + KEEP laserSmall | https://kenney.nl/assets/sci-fi-sounds | Creative Commons CC0 | K-SF UNVERIFIED size | Kenney sci-fi set is the house CC0 source and described for lasers and scans | RD60SF |
| gun_rail | RD25 bang crack + K-IMP metal hit | https://opengameart.org/content/25-cc0-bang-firework-sfx | CC0 | RD25 pack + K-IMP UNVERIFIED | Real bang crack plus metal impact reads as railgun without synth chirp | KEEP boomLow + RD100 metal |
| gun_glob | RD40W slime sounds (synth-only cue) | https://opengameart.org/content/40-cc0-water-splash-slime-sfx | CC0 | RD40W 2.3 Mb pack | Described as partly recorded from real slime, exact fit for a bio glob launch | RD100 plop sounds |
| salvo_tail | RD25 long firework rumble tail + KEEP boomLow | https://opengameart.org/content/25-cc0-bang-firework-sfx | CC0 | RD25 pack | Long recorded bang tails give broadside body on the 4th shot | SONNISS UNVERIFIED |
| lance | LRSF laser, long variant + KEEP laserLarge | https://opengameart.org/content/sci-fi-sound-effects-library | CC BY 3.0, attribution as above | LRSF UNVERIFIED | Beam lance wants a designed sustained laser, pack has 10 | K-SF |
| lance_ion | LRSF laser + KEEP arc layer | https://opengameart.org/content/sci-fi-sound-effects-library | CC BY 3.0 | LRSF UNVERIFIED | Ion variant can pitch-shift a different laser take from same family | RD60SF |
| lance_dark | RD60SF low energy variant + KEEP laserLarge | https://opengameart.org/content/60-cc0-sci-fi-sfx | CC0 | RD60SF UNVERIFIED | Dark Deathless lance should not share the bright LRSF family | LRSF pitched down |
| lance_choir | RD60SF tonal variant + KEEP laserSmall | https://opengameart.org/content/60-cc0-sci-fi-sfx | CC0 | RD60SF UNVERIFIED | Ithar chord lance needs a cleaner tonal shot, pack variations help | K-SF |
| torp | K-SF whoosh / launch + KEEP whoosh layer | https://kenney.nl/assets/sci-fi-sounds | Creative Commons CC0 | K-SF UNVERIFIED | House CC0 sci-fi set plus existing recorded whoosh covers launch | RD100 machine / slam |
| torp_rocket | RD25 staggered bangs (synth-only cue) | https://opengameart.org/content/25-cc0-bang-firework-sfx | CC0 | RD25 pack | Four staggered recorded launches can be built from separate bang takes | RD100 explosion + shot |
| torp_sac | RD40W slime swell (synth-only cue) | https://opengameart.org/content/40-cc0-water-splash-slime-sfx | CC0 | RD40W pack | Chorus sac torpedo is a wet bio launch, slime pack is the only verified wet source | RD100 splash |
| torp_star | RD60SF rising energy variant + KEEP whoosh | https://opengameart.org/content/60-cc0-sci-fi-sfx | CC0 | RD60SF UNVERIFIED | Ithar star torpedo needs bright energy launch distinct from generic torp | K-SF |
| torp_heavy | FS-EXPM layered under KEEP whoosh (deep body) | https://freesound.org/people/EvanBoyerman/sounds/753843/ | CC BY, credit author | 1.5 MB verified (also usable for boom_m) | Described as realistic layered explosion, gives heavy torpedo weight; needs CC BY ruling | RD25 long bang (CC0) |
| charge | LRSF robot activated / engine charge + KEEP ionCharge | https://opengameart.org/content/sci-fi-sound-effects-library | CC BY 3.0 | LRSF UNVERIFIED | Pack ambience and activation sounds suit a 1.3 s charge build | K-SF scan sounds |
| launch | K-SF engine sounds + KEEP launch layer | https://kenney.nl/assets/sci-fi-sounds | Creative Commons CC0 | K-SF UNVERIFIED | Tags include engine, pack is house source for launch sounds | RD60SF |

### Impacts (19)

| Cue | Chosen source | Link | Licence | Size / pack | Why it fits | Fallback |
|---|---|---|---|---|---|---|
| hit | K-IMP impact hit + KEEP hullHit | https://kenney.nl/assets/impact-sounds | Creative Commons CC0 | K-IMP UNVERIFIED, 130 files | 130 described hits, thuds and crashes is the core hull-hit pool | RD75 hit sounds |
| hit_heavy | RD75 heavy breaking hit + KEEP hullHitBig and boomLow | https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx | CC0 | RD75 1.6 Mb pack | Pack tags include metal, stone, cracking, demolition and impact | K-IMP |
| hit_las | K-IMP short hit + KEEP hullHit, synth sizzle removed in favour of RD60SF zap layer | https://kenney.nl/assets/impact-sounds | Creative Commons CC0 | K-IMP UNVERIFIED | Short metal hit plus sci-fi zap reads as laser impact without synth | RD60SF alone |
| hit_plasma | RD75 big hit + KEEP hullHitBig | https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx | CC0 | RD75 pack | Heavy breaking hit gives plasma impact body | FS-EXPM CC BY |
| hit_rail | RD75 metal crack + KEEP hullHitBig | https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx | CC0 | RD75 pack | Sharp recorded metal and stone cracks suit rail impact | K-IMP metal |
| hit_wet | RD40W slime hit (synth-only cue) | https://opengameart.org/content/40-cc0-water-splash-slime-sfx | CC0 | RD40W pack | Real slime recordings are the direct flesh-hit replacement | RD100 splash / plop |
| hit_glass | FS-GLASS glass shatter | https://freesound.org/people/ccen18/sounds/686849/ | Creative Commons 0 | 310.0 KB verified | Real glass-ceramic shatter recording, Ithar glass hit in one file | RD100 glass sounds (5 glass listed) |
| hit_ion | RD60SF zap + KEEP arc layer | https://opengameart.org/content/60-cc0-sci-fi-sfx | CC0 | RD60SF UNVERIFIED | Electric sci-fi variants replace synth buzz and crackle | LRSF |
| shield | RD60SF shield / energy variant + KEEP shieldHit | https://opengameart.org/content/60-cc0-sci-fi-sfx | CC0 | RD60SF UNVERIFIED | Energy hit variations keep shield distinct from hull | K-SF |
| shield_break | RD75 glass and metal break + KEEP shieldBig and shieldHit | https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx | CC0 | RD75 pack | Breaking and falling sounds give a collapse layer under the shield ring | FS-GLASS for Ithar-facing breaks |
| patter_hull | RD100 metal taps (synth-only cue) | https://opengameart.org/content/100-cc0-sfx | CC0 | RD100 pack | Pack lists 12 metal and small hit recordings for light patter | K-IMP short hits |
| patter_shield | RD60SF small energy ticks (synth-only cue) | https://opengameart.org/content/60-cc0-sci-fi-sfx | CC0 | RD60SF UNVERIFIED | Small sci-fi ticks at low gain read as shield patter | K-SF |
| phase | LRSF WarpDrive (3 described) + KEEP whoosh and arc | https://opengameart.org/content/sci-fi-sound-effects-library | CC BY 3.0 | LRSF UNVERIFIED | Pack explicitly lists WarpDrive sounds, exact phase function | RD60SF sweep variant |
| engine | LRSF SpaceShip Engine Loops (3 described) (synth-only cue) | https://opengameart.org/content/sci-fi-sound-effects-library | CC BY 3.0 | LRSF UNVERIFIED | Engine loops are a named pack item, replaces brown-noise synth swell | K-SF engine-tagged sounds |
| cough | RD100 machine sounds, short chuff takes (synth-only cue) | https://opengameart.org/content/100-cc0-sfx | CC0 | RD100 pack | Machine and slam recordings can be cut as damaged engine chuffs | RD75 falling / hit short takes |
| puff | RD100 noise / splash short takes (synth-only cue) | https://opengameart.org/content/100-cc0-sfx | CC0 | RD100 pack | Short recorded noise bursts suit a soft vent puff at low gain | RD40W bubble short takes |
| arrive_jump | KEEP whoosh + boomLow composite (Godot-only, already recorded) + optional LRSF WarpDrive upgrade | https://opengameart.org/content/sci-fi-sound-effects-library | CC BY 3.0 for upgrade only | KEEP 0 new; upgrade UNVERIFIED | Incumbent already satisfies the cue, warp upgrade only if CC BY intake passes | KEEP alone |
| board_grapple | KEEP hullHitBig + scrape + whoosh; upgrade RD75 metal hit for grapple bite, RD40W for Chorus variant | https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx | CC0 | RD75 pack | Metal hit plus existing scrape gives grapple clunk; slime layer separates Chorus variant | KEEP alone |
| brace_lock | KEEP hullHit + hullHitBig composite; upgrade K-IMP slam | https://kenney.nl/assets/impact-sounds | Creative Commons CC0 | K-IMP UNVERIFIED | Incumbent already recorded; a Kenney slam would thicken the lock | KEEP alone |

### Explosions (6)

| Cue | Chosen source | Link | Licence | Size / pack | Why it fits | Fallback |
|---|---|---|---|---|---|---|
| pop | RD100 explosion (1 listed) + KEEP boomSmall | https://opengameart.org/content/100-cc0-sfx | CC0 | RD100 pack | Small recorded explosion for fighter destruction | RD25 short bang |
| boom_s | FS-EXP2 Explosion 2 + KEEP boomSmall | https://freesound.org/people/qubodup/sounds/843248/ | Creative Commons 0 | 53.3 KB verified | Short real car-fire explosion extract, CC0, mono, fits small ship boom | RD25 bang |
| boom_m | FS-EXPM Explosion Outdoors (Medium) + KEEP boomSmall, boomLow, debris | https://freesound.org/people/EvanBoyerman/sounds/753843/ | CC BY, credit author | 1.5 MB verified (shared with torp_heavy, counted once) | Title and duration match medium explosion; described as realistic and layered | RD25 + RD75 layered (CC0 only) |
| boom_l | SONNISS GDC bundle explosion material + KEEP boomBig and debris | https://sonniss.com/gdc-bundle-license/?disabled | Sonniss GDC licence v2.0, quoted in section 4 | SONNISS UNVERIFIED (reported 7.47 GB for whole 2026 bundle) | Capital death needs the deepest recorded explosions; bundle is the pack-named source family | FS-EXPM layered with RD75 debris (verified sizes only) |
| bass_drop | KEEP bassDrop incumbent | Pack section 3: bassDrop set, Sonniss GDC 2026 royalty-free per pack | Royalty-free, no attribution required (as stated in pack for incumbent) | 0 new | Pure sub drop is a designed element, incumbent already recorded and fit for purpose | RD25 lowest bang pitched down |
| wreck | RD75 falling and cracking + KEEP scrape | https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx | CC0 | RD75 pack | Falling, cracking and demolition sounds give groaning wreck settle without synth saw | RD100 machine / metal groans |

### Death (6)

| Cue | Chosen source | Link | Licence | Size / pack | Why it fits | Fallback |
|---|---|---|---|---|---|---|
| death_powerdown | LRSF ambience / robot deactivation style take + KEEP ionCharge and whoosh | https://opengameart.org/content/sci-fi-sound-effects-library | CC BY 3.0 | LRSF UNVERIFIED | Designed sci-fi power sounds suit stage 1 power down | K-SF pitched engine take |
| death_vent | RD100 noise / toilet-flush-adjacent vent takes are NOT used; pick RD40W bubble and air loops + KEEP whoosh | https://opengameart.org/content/40-cc0-water-splash-slime-sfx | CC0 | RD40W pack | Short airy loop and bubble takes layer under whoosh as venting | KEEP whoosh alone |
| death_crack | RD75 cracking (tags: cracking, crack) + KEEP scrape and hullHitBig; Ithar variant FS-GLASS | https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx | CC0; FS-GLASS Creative Commons 0 | RD75 pack; FS-GLASS 310.0 KB (shared with hit_glass, counted once) | Hull crack is the pack headline function; glass file gives the Ithar variant a real glass crack | RD100 glass |
| death_run | K-SF engine take pitched and cut as run-down (synth-only cue, real replacement required) | https://kenney.nl/assets/sci-fi-sounds | Creative Commons CC0 | K-SF UNVERIFIED | Engine-tagged recorded / designed takes replace the only synth-only death cue | LRSF engine loop, edited down |
| chunk_cool | RD75 falling debris + KEEP debris and scrape | https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx | CC0 | RD75 pack | Falling and hit debris sounds fit a cooling chunk settling | RD100 metal / pot takes |
| hulk_vent | RD75 falling air / RD100 noise + KEEP whoosh and scrape | https://opengameart.org/content/100-cc0-sfx | CC0 | RD100 pack | Recorded noise and metal takes thicken hulk venting over incumbent whoosh | KEEP alone |

### UI (14)

| Cue | Chosen source | Link | Licence | Size / pack | Why it fits | Fallback |
|---|---|---|---|---|---|---|
| ui_click | KEEP uiClick; upgrade K-INT clicks | https://kenney.nl/assets/interface-sounds | CC0 (see Not checked for this pack page) | K-INT UNVERIFIED | Incumbent already Kenney-style recorded click; pack has 100 described interface sounds | RD100 switch sounds |
| ui_confirm | KEEP uiConfirm; upgrade K-INT confirmation sounds | https://kenney.nl/assets/interface-sounds | CC0, UNVERIFIED on pack page | K-INT UNVERIFIED | Pack described as including confirmation sounds | LRSF Menu Select (CC BY) |
| ui_cancel | K-INT back / deny style take + KEEP uiDeny | https://kenney.nl/assets/interface-sounds | CC0, UNVERIFIED on pack page | K-INT UNVERIFIED | Interface pack gives a matched cancel to match click and confirm | RD100 switch |
| ui_select | KEEP uiSelect; upgrade K-INT select take | https://kenney.nl/assets/interface-sounds | CC0, UNVERIFIED on pack page | K-INT UNVERIFIED | Matched set cohesion for select | LRSF Menu Select |
| ui_panel | K-INT minimize / maximize style swish + KEEP uiPanel | https://kenney.nl/assets/interface-sounds | CC0, UNVERIFIED on pack page | K-INT UNVERIFIED | Godot Asset Library copy of this pack describes minimize and maximize sounds, panel motion fit | RD100 door squeak / switch |
| ui_reward | KEEP reward; upgrade LRSF Jingles (Achievement) | https://opengameart.org/content/sci-fi-sound-effects-library | CC BY 3.0 | LRSF UNVERIFIED | Pack jingles include achievement and win, exact reward function | KEEP alone |
| ui_round | LRSF Jingles, neutral take (synth-only cue) | https://opengameart.org/content/sci-fi-sound-effects-library | CC BY 3.0 | LRSF UNVERIFIED | A short designed jingle replaces the synth chord for round start | RD100 bell takes (CC0) |
| ui_your | KEEP yourTurn incumbent | Pack section 3 | Incumbent recorded, licence per pack | 0 new | Rising arpeggio already recorded and distinct | K-INT confirmation |
| ui_enemy | RD100 gong / low bell takes (synth-only cue) | https://opengameart.org/content/100-cc0-sfx | CC0 | RD100 pack | Pack lists 2 gong sounds, low recorded tones for enemy banner | KEEP enemyTurn layer from ui_alert family |
| ui_alert | KEEP enemyTurn; upgrade LRSF Alarm Loops (2 described) | https://opengameart.org/content/sci-fi-sound-effects-library | CC BY 3.0 | LRSF UNVERIFIED | Alarm loops are a named pack item for boss warning | RD60SF alert variant |
| ui_boss | KEEP impactChord; upgrade RD75 heavy hit under it | https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx | CC0 | RD75 pack | Heavy recorded hit adds weight to the flagship arrival chord | FS-EXPM low layer (CC BY) |
| sting_win | KEEP victory + LRSF Win jingle as replacement candidate for synth layer | https://opengameart.org/content/sci-fi-sound-effects-library | CC BY 3.0 | LRSF UNVERIFIED | Pack jingles explicitly include Win | KEEP alone |
| sting_loss | KEEP enemyTurn + LRSF Lose jingle as replacement candidate for synth layer | https://opengameart.org/content/sci-fi-sound-effects-library | CC BY 3.0 | LRSF UNVERIFIED | Pack jingles explicitly include Lose | KEEP alone |
| adapt_shift | KEEP uiSelect + uiSelect composite (Godot-only, already recorded) | Pack section 3 | Incumbent recorded | 0 new | Double select already signals a shift; no new source needed | K-INT select pitched variant |

Ambient bed (not a cue): KEEP incumbent (synth bed plus recorded room tone per pack). Optional upgrade: LRSF 4 ambiences (CC BY 3.0, UNVERIFIED size) auditioned as a recorded room tone layer. No verified new size.


## 3. Music tables

Judged against R37 in the pack: brass and tactical percussion in battle, synth drone on the map, organ and machine sounds only as faction flavour. Incumbent details are from pack section 4. KEEP means no new download (0 MB new). Nobody has listened to any candidate.

### Six faction slots

| Slot | Verdict | Candidate / incumbent | Link | Licence | Size | Loop / fit note |
|---|---|---|---|---|---|---|
| fac_voidsworn (Sunward Crusade), battle intense | KEEP | Chapel of Hate (organ and drums), FoxSynergy, incumbent | Pack section 4 (already in repo) | CC BY 3.0, attribution in music.json per pack | 0 new | Organ is allowed as faction flavour under R37; this is the flavour exception, not the battle default |
| fac_hegemony (Hegemony), battle calm | KEEP | Some Militaristic Tune (brass march), Spring Spring, incumbent | Pack section 4 | CC0 | 0 new | Brass march is directly on R37 direction for the calm layer |
| fac_corsair (Ashfall Hullbreakers), battle intense | REPLACE - audition first | Space Boss Battle Theme (Orbital Colossus.mp3), Matthew Pablo, OpenGameArt | https://opengameart.org/content/space-boss-battle-theme | CC-BY 3.0 (page License(s): CC-BY 3.0; Attribution Instructions on page point to the author services page, exact line to be captured at intake) | 6.1 Mb verified on page | WEAK LOOP FIT: page says "This track doesn't loop as it is" and offers a loopable version by contacting the author. Described as heavy electronic, drum and bass, epic boss track. It answers the owner note in the pack that the incumbent Heavy battle music is heard as thin MIDI war drums, but it moves away from brass toward electronic, so it is an audition candidate only, not a straight replacement. Fallback: KEEP incumbent |
| fac_chorus (Chorus), bed at -9 dB | KEEP | Menacing Otherworld, Ruskerdax, incumbent | Pack section 4 | CC0 | 0 new | Otherworld bed under both layers is flavour, consistent with R37 |
| fac_ithar (Glasswrights), bed at -11 dB | KEEP | Airy, SRG774, incumbent | Pack section 4 | CC0 | 0 new | Light bed under both layers, no direction conflict |
| fac_deathless (Eclipse), battle calm | KEEP | Claimed by the Void mix (industrial machine pulse), vitalezzz and tricksntraps, incumbent | Pack section 4 | CC0 | 0 new | Machine pulse is allowed as faction flavour under R37 |

### Other music slots (18 slots in pack, grouped)

| Slot group | Verdict | Incumbent / candidate | Licence | Size | Note |
|---|---|---|---|---|---|
| Title screen (title_war) | KEEP | War Theme v2, Spring Spring | CC0 | 0 new | Brass, strings, timpani fits R37 title weight |
| Map sector 1 (map_sector, map_outer) | KEEP both | Sector, SRG774; Outer Space Loop, wipics | CC0; CC0 | 0 new | Outer Space Loop is named as a loop; map drone direction satisfied by incumbents |
| Map sector 2 (map_drone, map_echo) | KEEP both | Dark Ambient Drone, Tsorthan Grove; Space Echo, Centurion_of_war | CC BY 3.0; CC0 | 0 new | Dark Ambient Drone is the synth drone R37 asks for on the map |
| Map sector 3 (map_signal, map_transmission) | KEEP both | Title and Transmission, SRG774; Signal Transmission, One Man Symphony | CC0; CC BY 4.0 | 0 new | No candidate found that beats incumbents on description alone |
| Battle calm (calm_tactical, calm_darktimes) | KEEP both | Tactical Thinking; Dark Times, NorthFantasyMusic | CC BY 4.0; CC BY 4.0 | 0 new | Tactical naming and incumbent status fit R37; replacement would need a listen pass |
| Battle intense (hot_pursuit, hot_qazi, hot_theme_a) | KEEP all | Determined Pursuit, Emma_MA; QaziJamJam, Emma_MA; Battle Theme A, cynicmusic | CC BY 3.0; CC BY 3.0; CC0 | 0 new | Determined Pursuit is described in pack as horns, brass, drums and as an epic orchestra loop in OpenGameArt collections, directly on R37 |
| Boss intense (boss_final) | KEEP, audition Space Boss Battle Theme here as second choice | The Final Battle, skrjablin, incumbent; candidate as in fac_corsair row | CC BY 3.0; candidate CC-BY 3.0 | Candidate 6.1 Mb verified, counted once in music total | Boss slot tolerates a non-looping track less badly than a battle layer, but the player loops boss music, so the non-loop caveat still applies |
| Victory stings (sting_victory, sting_fanfare, sting_champion) | KEEP all | VICTORY; Just a random fanfare; WIN AGAINST CHAMPION, Spring Spring | CC BY 3.0 each | 0 new | Stings do not loop, incumbents are fit and already credited |
| Defeat sting (sting_lose) | KEEP | LOSE, Spring Spring | CC BY 3.0 | 0 new | Paired with the victory set, keep the family together |

Music candidates not taken: any AI-generated battle pack (excluded by pack rule against AI-generated audio presented as recorded and by the licence / provenance risk), and 8-bit / chiptune battle themes on OpenGameArt (off R37 brass and percussion direction and would worsen the owner tinny complaint).

## 4. Pack recommendations

1. RD75 - rubberduck, 75 CC0 breaking / falling / hit sfx, OpenGameArt. Licence line: License(s): CC0. Size: 1.6 Mb verified. Covers: hit_heavy, hit_plasma, hit_rail, shield_break, wreck, death_crack, chunk_cool, ui_boss upgrade, board_grapple upgrade. Strongest single impact pack in this leg.
2. RD100 - rubberduck, 100 CC0 SFX, OpenGameArt. Licence: CC0. Size: 2.9 Mb verified. Covers: gun_tracer, patter_hull, cough, puff, pop, ui_enemy, death_vent and hulk_vent layers, plus fallbacks for glass, machine and switch sounds across the table. Described as recorded with an Android device, so fidelity is a listen-pass question, not a licence question.
3. RD25 - rubberduck, 25 CC0 bang / firework SFX, OpenGameArt. Licence: CC0. Size: 1.4 Mb verified. Covers: gun_shell, gun_flak, gun_rail crack, salvo_tail, torp_rocket. Recorded fireworks and cannon, the real-recording answer to the synth gun family.
4. RD40W - rubberduck, 40 CC0 water / splash / slime SFX, OpenGameArt. Licence: CC0. Size: 2.3 Mb verified. Covers: gun_glob, hit_wet, torp_sac, board_grapple Chorus variant, death_vent layer. The only verified wet / flesh source found; without it the Chorus cues stay synth.
5. RD60SF - rubberduck, 60 CC0 Sci-Fi SFX, OpenGameArt. Licence: CC0. Size: UNVERIFIED. Covers: gun_sq, gun_plasma, gun_spine, lance_dark, lance_choir, torp_star, hit_ion, shield, patter_shield, plus fallbacks. Recommended subject to size verification at intake; the pack structure (22 sounds, 2 to 3 variations each, 60 total) is verified on the page.
6. K-IMP and K-SF - Kenney Impact Sounds (130 files) and Sci-Fi Sounds (70 files), kenney.nl. Licence line on both pack pages: Creative Commons CC0. Size: UNVERIFIED for both (no size shown on the pack pages). Covers: hit, hit_las, brace_lock upgrade, gun_needle, torp, launch, death_run, plus cohesion with the incumbent Kenney clips already in game. K-INT Interface Sounds (100 files) is the UI companion, licence and size UNVERIFIED on its crawled pack page (see Not checked).
7. LRSF - Little Robot Sound Factory, Sci-Fi Sound Effects Library, OpenGameArt. Licence: CC BY 3.0. Attribution line verified: "Attribute Little Robot Sound Factory, and provide this link where possible: www.littlerobotsoundfactory.com". Size: UNVERIFIED. Covers: gun_las, lance, lance_ion, phase, engine, ui_reward, ui_round, ui_alert, sting_win, sting_loss, death_powerdown, arrive_jump upgrade. This is the highest-value CC BY pack; it should only enter if Q1 passes.
8. SONNISS - Sonniss #GameAudioGDC Bundle. Licence line quoted exactly from https://sonniss.com/gdc-bundle-license/?disabled , Version 2.0, effective 27 August 2026: "Upon downloading this sound effects collection, the Licensor grants the Licensee, a worldwide, non-exclusive, royalty-free license to use all or any of the sound effects" and "Licensee may use and modify the licensed sound effects for personal and commercial projects without attribution to the original creator." REDISTRIBUTION FLAG, quoted: "Licensee may not distribute, publish, sub-license or otherwise supply the sound effects as sound effects to any other person, without the Licensor's prior written permission" and "Licensee may not sell any of the sound effects as they come. (Although the sound effects may be sold as incorporated into licensee project)." That wording sits in tension with a public repo that carries audio files, which is exactly the D22 issue in the pack; this leg flags it and does not clear it. Size: UNVERIFIED (7.47 GB, 347 files for the 2026 edition, reported by a secondary blog, not verified on Sonniss). Covers potentially: boom_l and any gap, but no cue in this leg depends on it except boom_l, which has a verified fallback.

## 5. Totals

Verified sizes only. Each pack counted once, however many cues point at it. Shared files counted once.

SFX verified:
- RD75: 1.6 MB
- RD100: 2.9 MB
- RD25: 1.4 MB
- RD40W: 2.3 MB
- FS-GLASS: 0.310 MB (310.0 KB)
- FS-EXP2: 0.0533 MB (53.3 KB)
- FS-EXPM: 1.5 MB
SFX total verified: 10.0633 MB, reported as 10.1 MB approx.

Music verified:
- Space Boss Battle Theme (Orbital Colossus.mp3): 6.1 MB, counted once although auditioned for two slots
- All KEEP music slots: 0 MB new
Music total verified: 6.1 MB.

Combined verified total: 16.1633 MB, reported as 16.2 MB approx.

UNVERIFIED list (excluded from all totals):
- K-IMP Kenney Impact Sounds - licence CC0 verified, size not shown on pack page
- K-SF Kenney Sci-Fi Sounds - licence CC0 verified, size not shown on pack page
- K-INT Kenney Interface Sounds - size not shown, and licence field not shown on the crawled pack page
- RD60SF 60 CC0 Sci-Fi SFX - licence CC0 verified via title and independent credits, file size not shown in the live page crawl
- LRSF Sci-Fi Sound Effects Library - attribution line verified, CC BY 3.0 via independent credits, file size not shown in the live page crawl
- SONNISS GDC 2026 bundle - licence v2.0 verified on Sonniss licence page, bundle size 7.47 GB only from a secondary blog, and no Sonniss download page with a size was opened
- 80 CC0 creature SFX (rubberduck, OpenGameArt, https://opengameart.org/content/80-cc0-creature-sfx ) - considered for Chorus creature colour, not used as a primary pick; live page crawl showed contents (80 creature effects) but no file size and no licence field, so it stays UNVERIFIED and unused in totals

## 6. Owner questions (pick marked on each)

Q1. CC BY SFX intake before an SFX credits surface exists? LRSF (lasers, warp, engine loops, jingles, alarms) and FS-EXPM (medium explosion) are CC BY. The music system already stores attribution, the SFX system does not.
Pick: YES, allow CC BY SFX now, but only LRSF and FS-EXPM, and only if their attribution lines are added to a plain SFX credits text file in the repo at intake, with the in-game surface to follow. Holding to CC0 only would lose the engine loops, warp and laser family that most directly answer the tinny complaint.

Q2. Multi-gigabyte Sonniss bundle versus curated smaller packs?
Pick: Curated smaller packs. The verified CC0 core in this leg is about 10 MB and covers every cue except a top-end boom_l. Do not take a reported 7.47 GB bundle for one cue, especially with the redistribution wording flagged in section 4 sitting against a public repo. Revisit Sonniss only for boom_l if the verified fallback (FS-EXPM plus RD75 debris) fails the listen pass.

Q3. Hullbreaker faction slot (fac_corsair): audition Space Boss Battle Theme against the incumbent, even though it is electronic, does not loop as published, and moves away from the R37 brass direction?
Pick: YES, audition it for fac_corsair and for boss_final, but do not ship it unless a loopable version is obtained and the listen pass prefers it. The owner steering note in the pack asked for a stronger Hullbreaker candidate to be auditioned, and this is the only verified-size, CC BY, space boss candidate found; the loop defect is the blocker, not the licence.

Q4. Kenney and RD60SF size verification at intake: both are CC0 and low risk, but this leg could not verify their download sizes from the live pack pages.
Pick: Approve them on licence and description, and let intake record the real zip sizes then, rather than blocking the whole SFX pass on pack-page metadata that the sites do not publish. The chair total should be restated after intake with those real sizes.

Q5. Synth layer policy for hybrid cues: when a new recorded layer lands for a cue that today plays synth alongside recording, should the synth take be removed for that cue, or kept at lower gain?
Pick: Remove it for the 15 synth-only cues and for weapons and impacts where a replacement is named in this leg; keep it only where this leg says KEEP with no replacement. The owner complaint is specifically about tinny computer sound, and layering the synth under a real recording preserves the problem.

## 7. Not checked

- No audio file was listened to, by design and by the LIST AND SIZE ONLY rule. All fit judgements are from page descriptions, tags and metadata.
- Kenney pack download sizes: not published on the kenney.nl pack pages opened for Impact Sounds, Sci-Fi Sounds or Interface Sounds.
- Kenney Interface Sounds licence field: not shown on the crawled pack page; CC0 status rests on Kenney support statements reported in secondary guides, so it is marked UNVERIFIED on that page in the tables.
- RD60SF file size and LRSF file size: not shown in the OpenGameArt page crawls used.
- Sonniss GDC bundle download page and its stated size: not opened; size figure is secondary-source only, and the 2026 bundle contents per cue were not checked.
- Freesound files beyond the three named: not searched file by file for ship creaks, engine run-downs or Chorus creature sounds; those gaps are covered by packs instead.
- Pixabay, ZapSplat and similar stock libraries: not used, because no licence line clearly permitting redistribution inside a public game repo build was verified for any specific item.
- Music beyond Space Boss Battle Theme: no new CC0 brass battle loop with a verified size was found and opened in this leg; all other music slots are therefore KEEP, which is a coverage decision, not a claim that no better track exists.
- Loop quality of every music incumbent and of LRSF engine loops: not checked by listening; process.py loop scoring at intake remains the gate per the pack.
