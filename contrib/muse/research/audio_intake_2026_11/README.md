# Audio intake, issue 101: chair record

Implements contrib/muse/research/audio_sourcing_2026_11/synthesis.md section 8
steps 1 to 5 with the owner rulings after its section 11 (FINDINGS R82).
Models per the issue block: DeepSeek and Qwen wrote, Rey chaired, Argon
reviewed only. Legs are in legs/ (deepseek_leg.md, qwen_leg.md, argon_leg.md).

## Step 1: synth strip (done)

The {"syn": 1} layer was removed from all 24 hybrid cues in
godot/audio/cues.json, verified against the playback rule in
godot/audio/sfx.gd (_layers appends the synth take when a syn layer is
present or no recorded layer resolves). One judgment call in the same spirit:
the death_crack ithar variant was also a hybrid (shieldHit plus syn) and got
the same strip. ui_enemy, previously synth-only, now layers the existing
enemyTurn recorded set, which was already in clips/index.json. After this
step every cue in the game resolves to recorded clips only under the
_layers rule; synth takes remain as the designed fallback if a clip fails
to load.

Propagation flag for Opus (also in the sourcing synthesis, section 12):
cues.json is rendered from SFX.MAP by godot/audio/build/render_synth.js.
A re-render restores the synth layers unless SFX.MAP gets the same strip.
The checks do not re-render, so this delivery stands as data; the upstream
call is Opus's.

## Step 2: downloads (done, measured)

Downloaded Nov 3, 2026, into the intake workspace (not the repo):

- Rubberduck OpenGameArt packs (CC0): 75 Breaking 1,624,406 bytes; 100 CC0
  SFX 2,921,904; 100 CC0 SFX 2 2,367,871; 100 Metal and Wood 1,990,361;
  25 Bang 1,390,498; 40 Water/Splash/Slime 2,259,262; 60 Sci-Fi 9,180,009.
  Rubberduck total 21,734,311 bytes.
- Kenney packs (CC0, via kenney.nl): Impact Sounds 800,850; Sci-Fi Sounds
  5,875,104; Interface Sounds 834,536. Kenney total 7,510,490 bytes.
- CC0 core total: 29,244,801 bytes (29.24 MB). This replaces the sourcing
  synthesis section 7 estimates: Kenney sizes were unverified there, and
  the 60 Sci-Fi pack was excluded from its totals (measured here at
  9.18 MB, larger than the other rubberduck packs).
- Little Robot (step 4, CC BY 3.0): 42,262,851 bytes, confirming the
  single-source cited figure in the sourcing synthesis.
- All downloads total: 71,507,652 bytes (71.51 MB).
- Also downloaded for step 5: Kenney Music Jingles 1,239,525 bytes (CC0);
  Matthew Pablo, Space Boss Battle Theme (Orbital Colossus) 6,066,975 bytes
  (CC BY 3.0); two NorthFantasyMusic WAVs (below).

## Step 3: per-cue selection and registration (done)

Both writing legs selected from a verified inventory of 879 pack files
(path, duration, channels). The chair merged with three structural rules:
incumbent sets are shared across cues (boomLow serves six cues, whoosh
eight), so upgrades land as NEW per-cue sets added as extra layers, never
as appends to shared sets; REPLACE cues get the new set as their only layer
and their synth take list is cleared; the two variant blocks named in the
sourcing spec (board_grapple chorus, death_crack ithar) had their layers
replaced, the ithar variant keeping its incumbent rate 1.6 and delay 0.1.

Result: 40 new sets, 128 new clip files (mono Ogg Vorbis, 44.1 kHz,
matching the incumbent clips), clips/index.json grows from 27 to 67 sets,
and the indexed clips total grows from 795,125 bytes to 2,123,292 bytes
(2.12 MB, far under the issue's 30 MB flag line). After registration, all
67 cues and both variant blocks resolve to recorded-only layers, and the
14 remaining synth-only cues from the sourcing pass are all replaced.
Synth-only cue count is now zero.

Leg screenings: Qwen invented 6 file paths that do not exist (an
sfx_03c, two Little Robot Engine_01/02 wavs, two sfx100v2 air files, a
bfh1_breaking_04); every one was screened and replaced chair-side with a
real file in the same family. DeepSeek invented none. Qwen also ran with
the inventory in a markdown container after Qwen3.8-Max rejected the .tsv
file type; gates passed on both attempts.

Chair fixes after the Argon review (details in legs/argon_leg.md header):
disjoint Little Robot laser split (gun_las takes the short lasers,
lance the long ones, no shared files), slime reassignments so the four
Chorus wet cues share no takes, torp_rocket shot takes swapped for cannon
takes (they duplicated gun_flak's), rate separation where one family
serves two roles (ionField 1.1 vs shieldShimmer 0.9, needleTick 1.15,
heavyPlate 0.85, uiRound 0.95, deathRun 0.92), a fade out on deathRun so
the engine loops fall away, and a 5 ms fade in on the trimmed torpLaunch
takes against clicks.

Two conversion edits, both disclosed in godot/audio/SFX_CREDITS.md:
torpLaunch is trimmed to 1.4 s (the source thruster loops are 5.0 s) and
deathRun carries the fade out above. Everything else is channel mixdown
and format only.

Freesound gap, recorded plainly: the named per-file picks (break-window
for hit_glass, Pound of Flesh for hit_wet, the ccen18 glass for the
death_crack variant) could not be downloaded; Freesound serves originals
only to signed-in accounts and no account is on file. Pack fallbacks were
selected for those cues, marked FREESOUND FALLBACK in the legs. If a
Freesound account is provided, swapping the named files in is a small
follow-up.

## Step 4: Little Robot (done)

Attribution filed in godot/audio/SFX_CREDITS.md (new), with the author's
required line verbatim, plus a per-set licence table for all 40 intake
sets and the CC0 pack sources with measured zip sizes. Little Robot takes
serve laserLR, lanceLR and one engineLoop take (CC BY 3.0).

## Step 5: music audition (done, no game change)

Per the audition standard (sourcing synthesis 5.3), candidates were run
through tools/music/process.py loopfind and nothing was added to
selection.json: a candidate wins only at the owner's listen (step 6), so
incumbents all stay. Results, with candidate files in
tools/music/audition_2026_11/ and the full sheet in its LISTEN_SHEET.md:

- fac_corsair: the two cynicmusic citations failed recheck (the pages are
  Spring Spring's; the War Theme ver 2 file is the title_war incumbent
  itself). Matthew Pablo's Space Boss Battle Theme (CC BY 3.0) loopfinds
  at 0.814 (loop point 76.1 s, bar 0.55) but is published as not looping;
  its eligibility under 5.3 is an owner call at the listen pass.
- hot_theme_a: JRPG Battle Theme by NorthFantasyMusic (CC BY 4.0, licence
  verified on the page) loopfinds at 0.648 (loop point 24.0 s). Eligible;
  the listen decides. (Arcane Predators, same composer, scored 0.488 and
  is not eligible.)
- fac_hegemony and title_war: no eligible candidate sourced. The directed
  composer search found no specific verified free brass march; the one
  NorthFantasyMusic pack in that direction is drum loops only.
- The four stings: Kenney Music Jingles (CC0, 1,239,525 bytes) contains no
  brass; its Hit jingles are nominated in the listen sheet as character
  long shots, incumbents favored.

## Checks

Local: the _layers resolution audit above (all cues recorded-only, no
missing set references, every indexed file present on disk); converted
files probed (mono, 44.1 kHz, expected durations). The Godot audio checks
(godot/audio/test/audio_check.gd, salvo_check.gd) need a Godot binary,
which this environment does not have; they run in the PR checks and on
the PC. run_all_checks results are recorded in the delivery message.

## Step 6

The owner's listen pass, from tools/music/audition_2026_11/LISTEN_SHEET.md,
after merge. Synth restorations and music swaps are follow-ups from his
notes.
