Model shown in the selector before sending: Qwen3.8-Max; model shown in the chat header after generation: Qwen3.8-Max.

AUDIO SOURCING REPORT - VOIDSWORN ISSUE #82
Leg: Qwen3.8 | Date: 2026-11-03 | Branch target: muse/issue-82
Deliver to: contrib/muse/research/audio_sourcing_2026_11/

HEADLINE
Approach: pack-led. Three pack sources (Sonniss GDC 2026, already in-repo; Kenney CC0 audio packs, already the house source; Little Robot Sound Factory CC BY 3.0 on OpenGameArt) cover roughly 50 of the 67 cues between them. Per-file picks from Freesound CC0 and OpenGameArt CC0 fill the remaining gaps (glass, flesh, engine, specific UI tones). Music sourcing is keep-mostly with targeted replacements for the Corsair slot and any slot that fails the R37 direction test.
Combined verified total download size: I cannot produce a verified total. No new entry in this report has a size verified from a live page because this leg cannot open live web pages. All new-source entries are marked UNVERIFIED below. The KEEP entries reference files already in the repo (0.8 MB SFX clips, 32 MB music) whose provenance is verified by the pack. The estimated total if all recommended new sources were fetched is stated in the Totals section as an estimate only, not a verified figure.

PER-CUE TABLE: WEAPONS (22 cues)

| # | Cue ID | Source Item | Source Site | Live Link | Licence Line | Size | Why It Fits | Fallback |
|---|---|---|---|---|---|---|---|---|
| 1 | gun_shell | KEEP: boomLow clip set (Sonniss GDC 2026) + UPGRADE: Sonniss GDC 2026 "Weapons" category, large cannon/boom files | Sonniss | sonniss.com/gameaudiogdc (2026 bundle page) | Sonniss royalty-free licence: "You may use these sounds in your projects including commercial projects. You may not redistribute the raw files." (paraphrase from training knowledge; UNVERIFIED against live page) | Pack is multi-GB (see Totals); existing boomLow clips in-repo are part of the 0.8 MB set | Recorded low boom already covers the body; upgrade pick adds a sharper transient crack layer | Kenney "Impact Sounds" CC0 boom files as lighter alternative |
| 2 | gun_flak | REPLACEMENT: Kenney "Sci-Fi Sounds" pack, flak/anti-air category files | kenney.nl | kenney.nl/assets/sci-fi-sounds | "License: CC0 1.0 Universal" (Kenney standard; UNVERIFIED live) | Pack approx 2-4 MB (UNVERIFIED) | Pack contains described-as sharp percussive bursts suitable for flak; CC0, no attribution needed | Little Robot Sound Factory CC BY 3.0 weapon bursts |
| 3 | gun_sq | KEEP: laserSmall clip set (Kenney CC0) + optional upgrade from Kenney "Sci-Fi Sounds" small weapon files | kenney.nl | kenney.nl/assets/sci-fi-sounds | CC0 1.0 Universal (UNVERIFIED live) | Pack approx 2-4 MB (UNVERIFIED) | Existing laserSmall covers the tick; upgrade adds variety | Little Robot Sound Factory small weapons |
| 4 | gun_las | KEEP: laserLarge clip set (Kenney CC0); synth layer present but recorded layer leads | Kenney (in-repo) | n/a (already in repo) | CC0 1.0 Universal (verified by repo provenance, sfx_data.js header) | In-repo, part of 0.8 MB | laserLarge already provides the sweep; synth is secondary | Sonniss GDC 2026 sci-fi weapons for a richer variant |
| 5 | gun_plasma | UPGRADE: Little Robot Sound Factory "Sci-Fi Sound Effects Library", plasma weapon files | OpenGameArt | opengameart.org/content/sci-fi-sound-effects-library | "CC BY 3.0" (UNVERIFIED live; attribution: "Little Robot Sound Factory") | Pack approx 150-200 MB (UNVERIFIED) | Described as designed plasma and energy weapon sounds; covers the vibrato-sweep character | Sonniss GDC 2026 weapons/energy category |
| 6 | gun_tracer | REPLACEMENT: Kenney "Sci-Fi Sounds" rapid-fire or burst files | kenney.nl | kenney.nl/assets/sci-fi-sounds | CC0 1.0 Universal (UNVERIFIED live) | Pack approx 2-4 MB (UNVERIFIED) | Described as containing short percussive shots in sequence; fits the three-thump roll | Freesound CC0 search "tracer fire" (specific file UNVERIFIED) |
| 7 | gun_spine | REPLACEMENT: Little Robot Sound Factory energy weapon sweep files | OpenGameArt | opengameart.org/content/sci-fi-sound-effects-library | CC BY 3.0 (UNVERIFIED live) | Pack approx 150-200 MB (UNVERIFIED) | Described as containing resonant rising energy sweeps; matches the 320-1300 Hz band sweep character | Sonniss GDC 2026 sci-fi weapons |
| 8 | gun_needle | KEEP: laserSmall clip set (Kenney CC0); synth adds high partials but recorded layer leads | Kenney (in-repo) | n/a (in repo) | CC0 1.0 Universal (verified by repo provenance) | In-repo | laserSmall provides the high-frequency tick; adequate | Little Robot Sound Factory for a more sustained needle tone |
| 9 | gun_rail | UPGRADE: Sonniss GDC 2026 weapons category, railgun/gauss files | Sonniss | sonniss.com/gameaudiogdc | Sonniss royalty-free licence (UNVERIFIED live; see pack recommendation section) | Multi-GB pack (UNVERIFIED exact) | Described as containing electromagnetic railgun shots with rising chirp and crack | Kenney "Impact Sounds" metal hits layered with "Sci-Fi Sounds" charge |
| 10 | gun_glob | REPLACEMENT: Freesound CC0 search for "wet blob" or "organic projectile" sounds | freesound.org | Search: freesound.org/search/?q=glob+projectile&f=license:%22Creative+Commons+0%22 | Per-file CC0 (UNVERIFIED; specific file not yet identified) | UNVERIFIED | Needs a warbling organic drop sound; Freesound CC0 pool is the best source for this | Little Robot Sound Factory "goo" or "organic" category if present |
| 11 | salvo_tail | KEEP: boomLow clip set (Sonniss GDC 2026); synth adds rumble body but recorded layer covers | Sonniss (in-repo) | n/a (in repo) | Sonniss royalty-free (verified by repo provenance, sfx_data.js header) | In-repo | boomLow provides the long rumble body; adequate for the 4th-shot tail | Sonniss GDC 2026 explosion/impact category for a longer rumble variant |
| 12 | lance | KEEP: laserLarge clip set (Kenney CC0); synth adds beam sustain | Kenney (in-repo) | n/a (in repo) | CC0 1.0 Universal (verified by repo provenance) | In-repo | laserLarge covers the beam fire transient; synth adds sustain which is acceptable | Sonniss GDC 2026 energy weapons for a fuller beam |
| 13 | lance_ion | KEEP: arc clip set (source per repo: Kenney or Sonniss GDC 2026) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | arc provides the crackle layer; synth adds the 880 Hz shimmer | Little Robot Sound Factory ion/electric weapons |
| 14 | lance_dark | UPGRADE: Sonniss GDC 2026 weapons/energy, low-frequency beam files | Sonniss | sonniss.com/gameaudiogdc | Sonniss royalty-free licence (UNVERIFIED live) | Multi-GB pack (UNVERIFIED) | Described as containing dark low energy beams; matches the 82 Hz sawtooth character | Little Robot Sound Factory dark energy weapons |
| 15 | lance_choir | UPGRADE: Little Robot Sound Factory tonal/harmonic energy weapons | OpenGameArt | opengameart.org/content/sci-fi-sound-effects-library | CC BY 3.0 (UNVERIFIED live) | Pack approx 150-200 MB (UNVERIFIED) | Needs a sustained multi-partial chord; described as containing tonal sci-fi elements | Freesound CC0 singing bowl or harmonic tone files |
| 16 | torp | KEEP: whoosh clip set (Kenney or Sonniss in-repo); synth adds sub drop | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | whoosh covers the launch body; adequate | Sonniss GDC 2026 whoosh category for a heavier variant |
| 17 | torp_rocket | REPLACEMENT: Sonniss GDC 2026 weapons/rockets or Kenney "Sci-Fi Sounds" launch files | Sonniss or kenney.nl | sonniss.com/gameaudiogdc or kenney.nl/assets/sci-fi-sounds | Sonniss royalty-free OR CC0 1.0 Universal (UNVERIFIED live) | Multi-GB (Sonniss) or approx 2-4 MB (Kenney) UNVERIFIED | Needs four staggered launches; described as containing rocket launch volleys | Freesound CC0 "rocket launch" files |
| 18 | torp_sac | REPLACEMENT: Freesound CC0 organic swell or resonant whoosh files | freesound.org | Search: freesound.org/search/?q=organic+swell&f=license:%22Creative+Commons+0%22 | Per-file CC0 (UNVERIFIED) | UNVERIFIED | Needs a resonant bandpass swell with warble; organic character points to Freesound | Little Robot Sound Factory organic/bio weapons if present |
| 19 | torp_star | KEEP: whoosh clip set (in-repo); synth adds gliss | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | whoosh provides the launch; synth gliss is secondary | Kenney "Sci-Fi Sounds" for a brighter launch variant |
| 20 | torp_heavy | KEEP: whoosh clip set (in-repo); synth adds deep sub | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | whoosh covers the launch; sub drop from synth is acceptable hybrid | Sonniss GDC 2026 heavy weapons/launches for a deeper variant |
| 21 | charge | KEEP: ionCharge clip set (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | ionCharge already provides the 1.3 s rising charge; fully adequate | Little Robot Sound Factory charge-up files as alternate |
| 22 | launch | KEEP: launch clip set (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | launch clip already provides the brown noise burst and rising whoosh | Sonniss GDC 2026 whoosh/launch category |

PER-CUE TABLE: IMPACTS (19 cues)

| # | Cue ID | Source Item | Source Site | Live Link | Licence Line | Size | Why It Fits | Fallback |
|---|---|---|---|---|---|---|---|---|
| 23 | hit | KEEP: hullHit clip set (in-repo); synth is secondary | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | hullHit provides the metal thump; adequate | Kenney "Impact Sounds" for additional variety |
| 24 | hit_heavy | KEEP: hullHitBig + boomLow clip sets (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | Two recorded layers already cover the heavy hit; no synth needed | Sonniss GDC 2026 heavy impacts |
| 25 | hit_las | KEEP: hullHit clip set (in-repo); synth adds sizzle | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | hullHit covers the impact body; synth sizzle is secondary | Kenney "Sci-Fi Sounds" laser impact files |
| 26 | hit_plasma | KEEP: hullHitBig clip set (in-repo); synth adds sub and sizzle | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | hullHitBig provides the big impact; synth sub is secondary | Sonniss GDC 2026 explosion/impact category |
| 27 | hit_rail | KEEP: hullHitBig clip set (in-repo); synth adds crack | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | hullHitBig covers the impact; adequate | Kenney "Impact Sounds" metal category |
| 28 | hit_wet | REPLACEMENT: Freesound CC0 "flesh impact" or "wet hit" files | freesound.org | Search: freesound.org/search/?q=flesh+impact&f=license:%22Creative+Commons+0%22 | Per-file CC0 (UNVERIFIED; specific file not identified) | UNVERIFIED | Needs a wet organic thud; Freesound CC0 pool has described-as flesh and wet impact recordings | rubberduck "75 CC0 Breaking, Falling and Hit SFX" on OpenGameArt |
| 29 | hit_glass | UPGRADE: Freesound CC0 glass hit/ping files; current shieldHit is a substitute | freesound.org | Search: freesound.org/search/?q=glass+hit&f=license:%22Creative+Commons+0%22 | Per-file CC0 (UNVERIFIED) | UNVERIFIED | Ithar faction needs a glass-specific impact; described-as glass ping and shatter files exist in CC0 pool | Kenney "Impact Sounds" glass category if present |
| 30 | hit_ion | KEEP: arc clip set (in-repo); synth adds buzz | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | arc provides the crackle; adequate | Little Robot Sound Factory electric impact files |
| 31 | shield | KEEP: shieldHit clip set (in-repo); synth adds sine partials | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | shieldHit provides the shield ring; adequate | Little Robot Sound Factory shield/energy impact files |
| 32 | shield_break | KEEP: shieldBig + shieldHit clip sets (in-repo); synth adds fall | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | Two recorded layers cover the break; adequate | Sonniss GDC 2026 impact/shatter category |
| 33 | patter_hull | REPLACEMENT: Kenney "Impact Sounds" small metal tap files | kenney.nl | kenney.nl/assets/impact-sounds | CC0 1.0 Universal (UNVERIFIED live) | Pack approx 1-3 MB (UNVERIFIED) | Described as containing small impact and tap sounds; fits the tick-on-hull character | Freesound CC0 "metal tap" or "small hits" files |
| 34 | patter_shield | REPLACEMENT: Little Robot Sound Factory shield ping or energy tap files | OpenGameArt | opengameart.org/content/sci-fi-sound-effects-library | CC BY 3.0 (UNVERIFIED live) | Pack approx 150-200 MB (UNVERIFIED) | Needs high sine pings on an energy surface; described as containing shield and energy UI-like pings | Freesound CC0 "ping" or "sonar" files |
| 35 | phase | KEEP: whoosh + arc clip sets (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | Two recorded layers cover the jump sweep and thump; adequate | Sonniss GDC 2026 whoosh category |
| 36 | engine | REPLACEMENT: Freesound CC0 "engine rumble" or "thruster" loop files | freesound.org | Search: freesound.org/search/?q=engine+rumble+thruster&f=license:%22Creative+Commons+0%22 | Per-file CC0 (UNVERIFIED) | UNVERIFIED | Needs a brown-noise low rumble with a 48 Hz body; described-as engine idle and thruster recordings exist in CC0 pool | Sonniss GDC 2026 engine/mechanical category |
| 37 | cough | REPLACEMENT: Freesound CC0 "engine cough" or "engine sputter" files | freesound.org | Search: freesound.org/search/?q=engine+sputter&f=license:%22Creative+Commons+0%22 | Per-file CC0 (UNVERIFIED) | UNVERIFIED | Needs two short brown-noise chuffs; described-as engine misfire recordings exist | Sonniss GDC 2026 mechanical category |
| 38 | puff | REPLACEMENT: Freesound CC0 "air puff" or "gas vent" files | freesound.org | Search: freesound.org/search/?q=air+puff+vent&f=license:%22Creative+Commons+0%22 | Per-file CC0 (UNVERIFIED) | UNVERIFIED | Needs a soft pink/brown noise puff; described-as air release and vent recordings exist | Kenney "Impact Sounds" soft hit as a substitute |
| 39 | arrive_jump | KEEP: whoosh + boomLow clip sets (in-repo); Godot-only recorded composite | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | Two recorded layers cover the arrival; no synth; adequate | n/a |
| 40 | board_grapple | KEEP: hullHitBig + scrape + whoosh clip sets (in-repo); Godot-only recorded composite | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | Three recorded layers cover the grapple; adequate | Sonniss GDC 2026 metal/scrape category for Chorus variant |
| 41 | brace_lock | KEEP: hullHit + hullHitBig clip sets (in-repo); Godot-only recorded composite | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | Two recorded layers cover the lock; adequate | n/a |

PER-CUE TABLE: EXPLOSIONS (6 cues)

| # | Cue ID | Source Item | Source Site | Live Link | Licence Line | Size | Why It Fits | Fallback |
|---|---|---|---|---|---|---|---|---|
| 42 | pop | KEEP: boomSmall clip set (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | boomSmall provides the small pop; adequate | Kenney "Impact Sounds" pop files |
| 43 | boom_s | KEEP: boomSmall clip set (in-repo); synth is secondary | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | boomSmall covers the explosion body; adequate | Sonniss GDC 2026 explosion category |
| 44 | boom_m | KEEP: boomSmall + boomLow + debris clip sets (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | Three recorded layers cover the medium explosion; adequate | Sonniss GDC 2026 explosion category |
| 45 | boom_l | KEEP: boomBig + debris clip sets (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | Two recorded layers cover the capital explosion; adequate | Sonniss GDC 2026 large explosion category |
| 46 | bass_drop | KEEP: bassDrop clip set (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | bassDrop provides the sub sine drop; adequate | Sonniss GDC 2026 cinematic/sub category |
| 47 | wreck | KEEP: scrape clip set (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | scrape provides the groan; adequate | Freesound CC0 "metal creak" or "ship groan" files |

PER-CUE TABLE: DEATH (6 cues)

| # | Cue ID | Source Item | Source Site | Live Link | Licence Line | Size | Why It Fits | Fallback |
|---|---|---|---|---|---|---|---|---|
| 48 | death_powerdown | KEEP: ionCharge + whoosh clip sets (in-repo); Godot-only recorded composite | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | Two recorded layers cover the power-down; adequate | n/a |
| 49 | death_vent | KEEP: whoosh clip set (in-repo); Godot-only recorded composite | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | whoosh covers the vent; adequate | Sonniss GDC 2026 steam/vent category |
| 50 | death_crack | KEEP: scrape + hullHitBig clip sets (in-repo); Godot-only recorded composite | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | Two recorded layers cover the hull crack; adequate. Ithar variant: see note below | Freesound CC0 glass crack for Ithar variant |
| 51 | death_run | REPLACEMENT: Freesound CC0 "engine wind down" or "engine run down" files | freesound.org | Search: freesound.org/search/?q=engine+wind+down&f=license:%22Creative+Commons+0%22 | Per-file CC0 (UNVERIFIED) | UNVERIFIED | Needs an engine spool-down; described-as engine run-down recordings exist in CC0 pool | Sonniss GDC 2026 engine/mechanical category |
| 52 | chunk_cool | KEEP: debris + scrape clip sets (in-repo); Godot-only recorded composite | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | Two recorded layers cover the cooling chunk; adequate | n/a |
| 53 | hulk_vent | KEEP: whoosh + scrape clip sets (in-repo); Godot-only recorded composite | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | Two recorded layers cover the hulk vent; adequate | n/a |

Note on death_crack Ithar variant: the cue supports a faction variant. The Ithar variant should use a glass crack sound. Recommend sourcing from Freesound CC0 "glass crack" or "glass shatter" files (specific file UNVERIFIED). This is a per-file gap pick.

PER-CUE TABLE: UI (14 cues)

| # | Cue ID | Source Item | Source Site | Live Link | Licence Line | Size | Why It Fits | Fallback |
|---|---|---|---|---|---|---|---|---|
| 54 | ui_click | KEEP: uiClick clip set (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | uiClick provides the button click; adequate | Kenney "Interface Sounds" click files |
| 55 | ui_confirm | KEEP: uiConfirm clip set (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | uiConfirm provides the two-note chime; adequate | Kenney "Interface Sounds" confirm files |
| 56 | ui_cancel | KEEP: uiDeny clip set (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | uiDeny provides the falling deny tone; adequate | Kenney "Interface Sounds" deny/cancel files |
| 57 | ui_select | KEEP: uiSelect clip set (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | uiSelect provides the select blip; adequate | Kenney "Interface Sounds" select files |
| 58 | ui_panel | KEEP: uiPanel clip set (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | uiPanel provides the panel swish; adequate | Kenney "Interface Sounds" swoosh files |
| 59 | ui_reward | KEEP: reward clip set (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | reward provides the four-note arpeggio; adequate | Kenney "Interface Sounds" reward/jingle files |
| 60 | ui_round | REPLACEMENT: Kenney "Interface Sounds" round-start or notification chime files | kenney.nl | kenney.nl/assets/interface-sounds | CC0 1.0 Universal (UNVERIFIED live) | Pack approx 1-2 MB (UNVERIFIED) | Needs a soft chord tone; described-as containing notification and transition chimes | Freesound CC0 "chime" or "bell" files |
| 61 | ui_your | KEEP: yourTurn clip set (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | yourTurn provides the rising arpeggio; adequate | Kenney "Interface Sounds" |
| 62 | ui_enemy | REPLACEMENT: Kenney "Interface Sounds" low warning or alert files | kenney.nl | kenney.nl/assets/interface-sounds | CC0 1.0 Universal (UNVERIFIED live) | Pack approx 1-2 MB (UNVERIFIED) | Needs low falling warning tones; described-as containing alert and warning sounds | Freesound CC0 "low warning tone" files |
| 63 | ui_alert | KEEP: enemyTurn clip set (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | enemyTurn provides the warning tones; adequate | Kenney "Interface Sounds" alert files |
| 64 | ui_boss | KEEP: impactChord clip set (in-repo) | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | impactChord provides the low stereo stack; adequate | Sonniss GDC 2026 cinematic impact category |
| 65 | sting_win | KEEP: victory clip set (in-repo); synth adds sparkle | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | victory provides the rising scale; adequate | Kenney music jingles CC0 |
| 66 | sting_loss | KEEP: enemyTurn clip set (in-repo); synth adds pad | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | enemyTurn provides the falling line; adequate | Kenney music jingles CC0 |
| 67 | adapt_shift | KEEP: uiSelect + uiSelect clip sets (in-repo); Godot-only recorded composite | In-repo | n/a (in repo) | CC0 or Sonniss royalty-free (verified by repo provenance) | In-repo | Two recorded layers cover the shift; adequate | n/a |

MUSIC TABLE: SIX FACTION SLOTS

| Slot ID | Layer Role | Incumbent Track | Author | Licence | Verdict | Rationale | Replacement Candidate (if any) | Candidate Source | Candidate Licence | Candidate Size | Loop Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| fac_voidsworn (Sunward Crusade) | Battle intense layer | Chapel of Hate (organ and drums) | FoxSynergy | CC BY 3.0 | KEEP | Organ and drums as faction flavour is exactly what R37 prescribes ("organ and machine sounds only as faction flavour"). This is the Crusade identity. | n/a | OpenGameArt (existing) | CC BY 3.0, attribution to FoxSynergy | In-repo, part of 32 MB | UNVERIFIED loop status |
| fac_hegemony (Hegemony) | Battle calm layer | Some Militaristic Tune (brass march) | Spring Spring | CC0 | KEEP | Brass march fits R37 "brass and tactical percussion in battle" directly. CC0, no attribution needed. | n/a | OpenGameArt (existing) | CC0 | In-repo | UNVERIFIED loop status |
| fac_corsair (Ashfall Hullbreakers) | Battle intense layer | Heavy battle music | Davieplier | CC0 | AUDITION REPLACEMENT | Owner steering note (Job 5 pack): hears incumbent as "thin MIDI war drums" and wants a stronger candidate auditioned. This is an audition request, not a replacement verdict. | Candidate 1: OpenGameArt CC0 battle/percussion track with described-as heavy drums and brass. Search: opengameart.org search "battle drums brass" filter CC0. Specific track UNVERIFIED. Candidate 2: Kenney music loops CC0 battle category if available. | OpenGameArt / kenney.nl | CC0 | UNVERIFIED | Must loop cleanly or be published as loop; UNVERIFIED |
| fac_chorus (Chorus) | Bed under both battle layers at -9 dB | Menacing Otherworld | Ruskerdax | CC0 | KEEP | Described-as ominous ambient bed suits the Chorus organic/alien identity. Sits at -9 dB under battle layers, so it is texture not foreground. Fits R37 as faction flavour. | n/a | OpenGameArt (existing) | CC0 | In-repo | UNVERIFIED loop status |
| fac_ithar (Glasswrights) | Bed under both battle layers at -11 dB | Airy | SRG774 | CC0 | KEEP | Described-as airy ambient bed suits the Glasswrights ethereal identity. At -11 dB it is pure texture. Fits R37 as faction flavour. | n/a | OpenGameArt (existing) | CC0 | In-repo | UNVERIFIED loop status |
| fac_deathless (Eclipse) | Battle calm layer | Claimed by the Void mix (industrial machine pulse) | vitalezzz, tricksntraps | CC0 | KEEP | Industrial machine pulse is exactly R37 "machine sounds only as faction flavour." Fits the Deathless/Eclipse identity. CC0. | n/a | OpenGameArt (existing) | CC0 | In-repo | UNVERIFIED loop status |

MUSIC TABLE: OTHER SLOTS (18 slots)

| Slot | Track ID | Incumbent Track | Author | Licence | Verdict | Rationale | Replacement Candidate | Source | Licence | Size | Loop |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Title screen | title_war | War Theme v2 (brass, strings, timpani) | Spring Spring | CC0 | KEEP | Brass and timpani fit R37 battle direction; appropriate for title. CC0. | n/a | OpenGameArt (existing) | CC0 | In-repo | UNVERIFIED |
| Map sector 1 | map_sector | Sector | SRG774 | CC0 | KEEP | Synth drone/ambient fits R37 "synth drone on the map." CC0. | n/a | OpenGameArt (existing) | CC0 | In-repo | UNVERIFIED |
| Map sector 1 | map_outer | Outer Space Loop | wipics | CC0 | KEEP | Described-as space ambient loop fits map drone role. CC0. Published as loop per title. | n/a | OpenGameArt (existing) | CC0 | In-repo | Published as loop |
| Map sector 2 | map_drone | Dark Ambient Drone | Tsorthan Grove | CC BY 3.0 | KEEP | Fits R37 synth drone on map. CC BY 3.0 with attribution in music.json. | n/a | OpenGameArt (existing) | CC BY 3.0, attribution to Tsorthan Grove | In-repo | UNVERIFIED |
| Map sector 2 | map_echo | Space Echo | Centurion_of_war | CC0 | KEEP | Fits map ambient role. CC0. | n/a | OpenGameArt (existing) | CC0 | In-repo | UNVERIFIED |
| Map sector 3 | map_signal | Title and Transmission | SRG774 | CC0 | KEEP | Fits map ambient/transmission role. CC0. | n/a | OpenGameArt (existing) | CC0 | In-repo | UNVERIFIED |
| Map sector 3 | map_transmission | Signal Transmission | One Man Symphony | CC BY 4.0 | KEEP | Fits map signal role. CC BY 4.0 with attribution in music.json. | n/a | OpenGameArt (existing) | CC BY 4.0, attribution to One Man Symphony | In-repo | UNVERIFIED |
| Battle calm layer | calm_tactical | Tactical Thinking | NorthFantasyMusic | CC BY 4.0 | KEEP | Brass and tactical percussion fit R37 directly. CC BY 4.0 with attribution. | n/a | OpenGameArt (existing) | CC BY 4.0, attribution to NorthFantasyMusic | In-repo | UNVERIFIED |
| Battle calm layer | calm_darktimes | Dark Times | NorthFantasyMusic | CC BY 4.0 | KEEP | Companion calm layer; fits tactical tone. CC BY 4.0. | n/a | OpenGameArt (existing) | CC BY 4.0, attribution to NorthFantasyMusic | In-repo | UNVERIFIED |
| Battle intense layer | hot_pursuit | Determined Pursuit (horns, brass, drums) | Emma_MA | CC BY 3.0 | KEEP | Horns, brass, drums fit R37 directly. CC BY 3.0. | n/a | OpenGameArt (existing) | CC BY 3.0, attribution to Emma_MA | In-repo | UNVERIFIED |
| Battle intense layer | hot_qazi | QaziJamJam | Emma_MA | CC BY 3.0 | KEEP | Second intense layer option. CC BY 3.0. | n/a | OpenGameArt (existing) | CC BY 3.0, attribution to Emma_MA | In-repo | UNVERIFIED |
| Battle intense layer | hot_theme_a | Battle Theme A | cynicmusic | CC0 | KEEP | CC0 battle theme. Fits intense layer. | n/a | OpenGameArt (existing) | CC0 | In-repo | UNVERIFIED |
| Boss intense layer | boss_final | The Final Battle | skrjablin | CC BY 3.0 | KEEP | Boss layer needs weight; described-as orchestral battle. CC BY 3.0. | n/a | OpenGameArt (existing) | CC BY 3.0, attribution to skrjablin | In-repo | UNVERIFIED |
| Victory sting | sting_victory | VICTORY | Spring Spring | CC BY 3.0 | KEEP | Victory fanfare. CC BY 3.0. Stings do not loop. | n/a | OpenGameArt (existing) | CC BY 3.0, attribution to Spring Spring | In-repo | No loop needed |
| Victory sting | sting_fanfare | Just a random fanfare | Spring Spring | CC BY 3.0 | KEEP | Alternate victory sting. CC BY 3.0. Stings do not loop. | n/a | OpenGameArt (existing) | CC BY 3.0, attribution to Spring Spring | In-repo | No loop needed |
| Boss victory sting | sting_champion | WIN AGAINST CHAMPION | Spring Spring | CC BY 3.0 | KEEP | Boss victory sting. CC BY 3.0. | n/a | OpenGameArt (existing) | CC BY 3.0, attribution to Spring Spring | In-repo | No loop needed |
| Defeat sting | sting_lose | LOSE | Spring Spring | CC BY 3.0 | KEEP | Defeat sting. CC BY 3.0. | n/a | OpenGameArt (existing) | CC BY 3.0, attribution to Spring Spring | In-repo | No loop needed |

Music summary: 23 of 24 slots are KEEP. One slot (fac_corsair) is flagged for AUDITION of a stronger candidate per the owner's Job 5 steering note. No replacement is mandated; the incumbent stays until the owner hears an alternative. All incumbent tracks are already CC0 or CC BY with attribution lines in music.json. No new music download is required unless the owner approves a Corsair audition replacement.

PACK RECOMMENDATIONS

PACK 1: Sonniss GDC 2026 Bundle (already in use for existing clips)
Licence: Sonniss royalty-free licence. The bundle's licence page (sonniss.com/gameaudiogdc) states the sounds are royalty-free for use in projects including commercial games. UNVERIFIED against live page this pass. The pack's standard licence includes wording to the effect that raw files may not be redistributed (flagged per D22 and the chair note in section 7 of the evidence pack). The exact current licence line must be quoted from the live page before any new material is drawn. Flag: no-redistribution wording present per training knowledge; needs live confirmation.
Size: Multi-gigabyte. The 2026 bundle is estimated at 10-30+ GB based on prior bundle sizes. UNVERIFIED.
Cues it covers: gun_shell (upgrade), gun_rail (upgrade), lance_dark (upgrade), salvo_tail (upgrade), hit_heavy, hit_plasma, hit_rail, boom_s through boom_l, bass_drop, wreck, death_vent, death_crack, arrive_jump, board_grapple, brace_lock, phase, torp, torp_heavy, torp_rocket, and general weapon/impact/explosion variety for round-robin. Effectively it can touch 25-30 cues as a source for additional takes or upgrade layers.
Note: The repo already contains Sonniss GDC 2026 clips (verified by sfx_data.js header). This pack recommendation is for drawing ADDITIONAL files from the same bundle to cover cues that currently rely on synth or have thin coverage. The owner must approve the multi-GB download.

PACK 2: Kenney Audio Packs (CC0)
Packs: "Impact Sounds", "Sci-Fi Sounds", "Interface Sounds"
Licence: "CC0 1.0 Universal" per Kenney's site. UNVERIFIED against live page this pass. Kenney's standard licence line on asset pages reads: "License: CC0 1.0 Universal."
Size: Each pack is approximately 1-5 MB for audio. Combined estimate 5-12 MB. UNVERIFIED.
Links: kenney.nl/assets/impact-sounds, kenney.nl/assets/sci-fi-sounds, kenney.nl/assets/interface-sounds
Cues covered: gun_flak, gun_tracer, gun_sq (upgrade), gun_rail (fallback), torp_rocket (fallback), hit (variety), hit_las, hit_rail, hit_glass (if glass category present), patter_hull, patter_shield (fallback), ui_round, ui_enemy, ui_click (upgrade), ui_confirm (upgrade), ui_cancel (upgrade), ui_select (upgrade), ui_panel (upgrade), ui_reward (upgrade), pop (upgrade), boom_s (upgrade). Approximately 20 cues can draw from these three packs.
Note: Kenney is already the house source for part of the current clip set. These packs are small, clean, CC0, and require no attribution. Strong recommendation as the primary lightweight source.

PACK 3: Little Robot Sound Factory - Sci-Fi Sound Effects Library (CC BY 3.0, OpenGameArt)
Licence: CC BY 3.0. Attribution line: "Little Robot Sound Factory" (exact attribution format UNVERIFIED against live page; the OpenGameArt submission page carries the licence block).
Size: Estimated 100-200 MB. UNVERIFIED.
Link: opengameart.org/content/sci-fi-sound-effects-library (UNVERIFIED; exact slug may differ)
Cues covered: gun_plasma (upgrade), gun_spine, lance_choir (upgrade), lance_dark (fallback), hit_ion (upgrade), hit_plasma (upgrade), shield (upgrade), shield_break (upgrade), patter_shield, charge (upgrade), lance_ion (upgrade). Approximately 10-12 cues.
Note: This is the CC BY option. If the owner approves CC BY SFX intake (see Owner Questions), this pack is the strongest single source for sci-fi energy weapons and shields. If CC BY SFX is not approved, this pack is excluded and its cues fall to Sonniss, Kenney, or Freesound CC0 alternatives.

PACK 4: rubberduck CC0 SFX packs (OpenGameArt)
Packs: "75 CC0 Breaking, Falling and Hit SFX" and "100 CC0 SFX"
Licence: CC0 (per Job 5 research; UNVERIFIED against live page this pass)
Size: Estimated 10-30 MB combined. UNVERIFIED.
Link: opengameart.org search for rubberduck submissions (UNVERIFIED exact URLs)
Cues covered: hit_wet (fallback), patter_hull (fallback), pop (fallback), boom_s (fallback), general impact variety. Approximately 5-8 cues as fallbacks.
Note: Named by Job 5 as audition candidates. Useful as CC0 fallbacks where Kenney or Sonniss do not cover a specific need.

PER-FILE PICKS (gaps packs cannot cover):
hit_glass / death_crack Ithar variant: Freesound CC0 glass crack/shatter files. Specific files UNVERIFIED. Search freesound.org with CC0 licence filter for "glass crack", "glass shatter", "crystal hit". Estimated 1-3 files, 100 KB to 2 MB each. UNVERIFIED.
hit_wet: Freesound CC0 flesh/wet impact files. Specific files UNVERIFIED. Search "flesh impact", "wet hit", "meat thud" with CC0 filter. Estimated 1-2 files. UNVERIFIED.
gun_glob: Freesound CC0 organic projectile/glob files. Specific files UNVERIFIED. UNVERIFIED.
torp_sac: Freesound CC0 organic swell files. Specific files UNVERIFIED. UNVERIFIED.
engine, cough, puff: Freesound CC0 engine/thruster/vent files. Specific files UNVERIFIED. UNVERIFIED.
death_run: Freesound CC0 engine wind-down files. Specific files UNVERIFIED. UNVERIFIED.
ui_round, ui_enemy: Kenney "Interface Sounds" covers these (see Pack 2).

TOTALS
SFX total (verified sizes only): 0 bytes of NEW material verified. All new-source entries are UNVERIFIED. The existing in-repo SFX clips total 0.8 MB (verified by the pack). No new SFX download size can be stated as verified.
SFX total (estimated, UNVERIFIED):
Kenney packs (3 packs): approx 5-12 MB
Little Robot Sound Factory: approx 100-200 MB
Sonniss GDC 2026 (if owner approves multi-GB download): approx 10-30 GB
Freesound per-file picks (approx 8-12 files): approx 1-10 MB
rubberduck packs: approx 10-30 MB
Estimated SFX total excluding Sonniss: approx 120-250 MB
Estimated SFX total including Sonniss: approx 10-30 GB
Music total (verified sizes only): 0 bytes of NEW material verified. All 24 incumbent tracks are already in the repo at 32 MB (verified by the pack). No new music download is required unless the owner approves a Corsair audition replacement. If a replacement is approved, its size is UNVERIFIED at this time.
Music total (estimated, UNVERIFIED): 0 MB additional (all KEEP except one audition slot). If the Corsair audition replacement is approved, add one track estimated 3-8 MB (UNVERIFIED).
Combined verified total: 0 bytes new. All new entries are UNVERIFIED.

UNVERIFIED list (all new-source entries):
Kenney "Impact Sounds" - size UNVERIFIED (cannot open kenney.nl live)
Kenney "Sci-Fi Sounds" - size UNVERIFIED (cannot open kenney.nl live)
Kenney "Interface Sounds" - size UNVERIFIED (cannot open kenney.nl live)
Little Robot Sound Factory - size and exact licence block UNVERIFIED (cannot open OpenGameArt live)
Sonniss GDC 2026 bundle - size and exact current licence line UNVERIFIED (cannot open sonniss.com live)
rubberduck "75 CC0 Breaking, Falling and Hit SFX" - size and URL UNVERIFIED
rubberduck "100 CC0 SFX" - size and URL UNVERIFIED
All Freesound per-file picks (glass, flesh, engine, glob, swell) - specific file IDs, sizes, and licence lines UNVERIFIED (no specific files identified; search hints only)
fac_corsair audition replacement candidates - no specific track identified; UNVERIFIED
All OpenGameArt incumbent music loop statuses - UNVERIFIED against live pages
Reason for all UNVERIFIED entries: this leg cannot open live web pages. No URL was loaded, no file size was read from a source page, and no licence text was quoted from a live page in this pass. All licence lines and sizes above are from training-data knowledge and must be confirmed against live pages before the owner approves any download.

OWNER QUESTIONS
Q1: CC BY SFX intake - the music set already accepts CC BY with attribution (music.json carries attribution lines and CREDITS.md is generated). However, no in-game credits surface currently displays SFX attributions. Little Robot Sound Factory (CC BY 3.0) is the strongest single pack for sci-fi energy weapons and shields (10-12 cues). Options: (a) build an SFX credits surface before or alongside CC BY SFX intake, then accept Little Robot; (b) hold SFX to CC0 only (Kenney, Sonniss, Freesound CC0, rubberduck CC0) until the credits surface exists; (c) accept CC BY SFX now and add the credits surface before the next release.
PICK: (b) hold SFX to CC0 for now. The Kenney + Sonniss + Freesound CC0 coverage is sufficient for all 67 cues. CC BY SFX intake can follow once the credits surface is built. This avoids a licence obligation the game cannot yet display.
Q2: Bundle size - the Sonniss GDC 2026 bundle is estimated at 10-30 GB. The repo already contains clips from it (0.8 MB of extracted files). Drawing additional files from the bundle means downloading the full multi-GB package. Options: (a) approve the full Sonniss bundle download for maximum coverage; (b) skip Sonniss for new material and rely on Kenney (5-12 MB), Freesound CC0 (a few MB), and rubberduck CC0 (10-30 MB) for a total well under 100 MB; (c) approve Sonniss only if specific cues cannot be covered by smaller sources.
PICK: (b) skip Sonniss for new material. The existing Sonniss clips in the repo already cover the heavy-hitter cues (booms, whooshes, hull hits). The remaining gaps (glass, flesh, engines, specific weapons) are better served by small CC0 packs and per-file picks. This keeps the total download under 250 MB and avoids the multi-GB commitment. Revisit if the owner wants richer round-robin variety.
Q3: fac_corsair audition - the owner's Job 5 steering note asks for a stronger Hullbreaker candidate. This pass has not identified a specific replacement track (no live search was possible). Options: (a) keep the incumbent until a dedicated audition pass is run; (b) commission a follow-up leg to search OpenGameArt CC0 for heavy brass-and-drums battle loops specifically for this slot; (c) the owner supplies a candidate.
PICK: (a) keep the incumbent for now and commission a focused audition leg. The current track is CC0 and functional; the owner's complaint is about quality, not licence. A dedicated listening pass is the right next step.
Q4: Freesound per-file sourcing - eight to twelve cues need per-file picks from Freesound CC0 (glass, flesh, engine, organic sounds). This leg could not identify specific files without live search. Options: (a) run a follow-up leg with live web access to identify and verify specific Freesound files; (b) skip Freesound and approximate these sounds from Kenney and rubberduck packs; (c) the owner or a contributor identifies specific Freesound files.
PICK: (a) run a follow-up leg with live access. The per-file cues (hit_glass, hit_wet, gun_glob, torp_sac, engine, cough, puff, death_run) need specific recorded character that packs may not cover. A live-search leg can verify licences and sizes properly.
Q5: Loop verification for music - the incumbent music tracks' loop status could not be verified against live pages this pass. The music intake pipeline (process.py, loopfind scorer) handles loop points at build time, but a track that cannot loop cleanly is a weak candidate. Options: (a) trust the existing music set since it is already in the repo and presumably passed intake; (b) verify loop status against OpenGameArt live pages in a follow-up pass; (c) flag any track the owner suspects of poor looping.
PICK: (a) trust the existing set. The 24 tracks are already in the repo and presumably passed the loopfind scorer at intake time. No music replacement is proposed (except the optional Corsair audition), so loop verification is not blocking.

NOT CHECKED
All live source pages. This leg cannot open URLs. Every link in this report is from training-data knowledge and may be stale, redirected, or wrong. No file size, licence line, or file description was read from a live page.
Sonniss GDC 2026 exact current licence text. The pack cites D22 and the chair note requiring the exact licence line to be quoted and any no-redistribution wording flagged. This leg could not do so. The licence must be verified from sonniss.com before any new Sonniss material is drawn.
Little Robot Sound Factory exact OpenGameArt submission URL and licence block. The slug "sci-fi-sound-effects-library" is from training knowledge and may not be the current URL.
rubberduck CC0 pack exact URLs and sizes on OpenGameArt.
All Freesound per-file candidates. No specific Freesound file IDs are cited. All Freesound entries in this report are search hints, not verified picks.
Kenney pack exact current sizes and contents. Kenney occasionally updates packs.
OpenGameArt incumbent music track loop points and exact file sizes as published. The in-repo sizes are known (32 MB total) but the published source sizes were not checked.
fac_corsair replacement candidates. No specific alternative track was identified.
Whether the Sonniss GDC 2026 bundle is still available for download at the time of this report. Bundles may be time-limited around GDC.
Whether any OpenGameArt incumbent music track has been removed or had its licence changed since the repo last fetched it.
Nobody has listened to any audio file referenced in this report. All "described as" characterisations come from source page metadata and training-data knowledge, not from audition.
END OF REPORT
