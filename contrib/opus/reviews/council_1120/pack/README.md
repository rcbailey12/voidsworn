# Council pack: build 25adec31 (Nov 20 2026)

Every picture here comes from the council playtest build: Voidsworn.exe exported from main 25adec31 (main at 17:20 UTC plus
the export rock fix and the Vigil manifest row). Bot smoke 0 errors; 295 packaged ship files match the manifest. Stage of
every picture: **installed in game, playtest build**. Sources are on the project drive at
board/council_1120/playtest_25adec3/.

## What is here

- `stills/`: title and credits (1080p capture), and six battle moments from Battle 1 (start, move preview, enemy clicked, tip
  card and legend, enemy turn, menu focus), all scaled to 720 px tall.
- `run_seed10/`, `run_seed121/`: one frame every 8 seconds from the two player-path recordings (fresh Sunward runs, the
  player's default settings: Standard AI, Max quality, tips on). Frame `tNNN` is at about (NNN - 1) x 8 seconds. Each run
  shows flagship pick, the sector map, Battle 1 with its teaching cards, the reward and promotion screens, and Battle 2.
- `traces/`: the recorder's event log per run (one JSON line per moment: teaching cards, previews, cut-ins, end cards).

## Read this before judging

- The runs are played by a **scripted route**, not a person: the moves are the script's, not a new player's. Judge what the
  screen shows and teaches, not the script's tactics.
- Seed 121 **lost Battle 2** (vs a Hullbreaker gutship and raider, 7 rounds). Seed 10 won Battles 1 and 2, then the script
  stopped because the map did not offer the route it expected ("expected route 2-2 is missing after Battle 2"). Neither run
  reached Battle 3. Whether a plain first route can lose Battle 2 is a fair first-time player question.
- Ship revisions: B20_11, I8_37 and V14_23 match publish receipts. B19_11, B21_11 and H4_11 are a **PC snapshot, not an
  approved revision**, and the Chorus ships are mid rebuild: do not judge them as finished art.
- The front-end screen set is in `frontend/` (added later, see below). It is a Godot checkout capture, not the packaged build.
- No sound is reviewed. Videos are not in git (8 MB each); the stills cover them.

## Added for the challenge round

- `factions/`: three battles played **as Sunward against** the Glasswrights (ithar), the Chorus and Eclipse (deathless)
  (capture log: the player fleet is V14_23 and V15_37; the enemy is the named faction). Six moments each (01 first turn,
  05 mid fight on the enemy turn), build 25adec31, the game's own battle camera (not the fixed camera 170). Ship names
  come from the in-game tip card. The enemy ships show in about one frame per set, small: these frames say how those
  factions read as opponents, not how they read when the player commands them. Chorus ships are mid rebuild.
- `frontend/`: the front-end screens (title, credits, settings, setup, run options, the six faction desks, flagship pick,
  help, lineage, progression; normal and larger text) plus the F2 to F5 sheets. **Godot checkout capture at b557adc85**, not
  the packaged playtest 25adec31: the two pins differ. Receipt: PASS for import, front-end tests and pictures at 1080p and 4K.
  Stills at 720 px tall or less.
- The Battle 2 footage in the run folders predates merged PR 1398: do not score it as a capture of the current Battle 2 layout.
- A seat that already submitted (Fable, Neon) may add an evidence-only addendum on these; its blind leg stays as written.
