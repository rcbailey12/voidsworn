# ElevenLabs sound candidates (issues 1572 and 1585)

Ryan, Nov 22 2026: ElevenLabs Creator, monthly ($11 first month, then $22), for sound redo candidates. Ryan, 04:10 UTC
(issue 1585, Neon's pre-flight on PR 1577): hold the blind Batch 1, run a small Gate 1 pilot first, pick by ear, then
Gate 2 production and Gate 3 stems. Nothing is wired into godot/ until Ryan picks.

## The three gates

- **Gate 1, calibration pilot** (`elevenlabs_pilot.json`, about 2,840 credits, under 3% of 121,000): one take each of
  12 benchmark cues (a 45 s battle music preview, a 30 s reward preview, 10 sound effects) plus 2 v2 A/B takes, plus 13
  atomic combat and death beats added Nov 22 (R412: broadside thump, gauss charge, crack and exit rip, Glasswright
  crystal shatter, Chorus acid sizzle and tendril lash; R409: Navy blackout thump, Hullbreaker tether snap, Glasswright
  fracture crackle, jammed-turret spark, blowout hiss, ion crawl static). No stems. Menu clicks are not made here: they come from free Sonniss or CC0 switches. Output goes to a listening page
  (today vs free vs ElevenLabs, built by `../tools/sound/listen_page.js`).
- **Gate 2, production** (after Ryan's picks): full-length versions of the music he approves, 2 takes of each winning
  sound. The game's layering, pitch jitter and round robin (godot/audio/sfx.gd) turn 2 takes into many variations.
- **Gate 3, stems**: split into stems only the 1 or 2 battle songs Ryan picks, for one-song adaptive battle music. The
  generator refuses stems in any list not marked `"gate": 3`.

## Tools

- `../tools/sound/elevenlabs_gen.js`: makes the files. Live calls go only to api.elevenlabs.io (no redirects). Every
  output is its own resumable step with its own manifest row; PASS needs all of them. Defaults: `eleven_text_to_sound_v3`
  and `music_v2` with `output_format=auto` (models page, Nov 22 2026: `eleven_text_to_sound_v2` is removed Mar 1 2027,
  `music_v1` Jan 31 2027; an item's `model` keeps v2 for an A/B). Estimates: 40 credits a second for a sound effect
  with a set duration, 900 a minute of music, stems at the song's own cost (unpublished). The `character-cost` response
  header is logged in `manifest.jsonl` on every call and counted. The key's credit cap at elevenlabs.io is the real
  ceiling; `--max-credits` is a second stop read from the account balance. A paid call is never retried after a 5xx or
  a lost answer. Every paid call writes a pending line to `receipts.jsonl` first (no call is sent if that write
  fails), then accepted, then the file, the manifest row and done (Artoo on PR 1590). A take that is not on disk with its
  manifest row is paid for again only if it has no receipt or the vendor refused it (not_charged); otherwise a rerun prints
  RECONCILE. After checking the account history, delete that take's receipt lines to allow one new try.
  A live run holds `run.lock` in its output folder for its whole run, so a second run on the same folder stops with
  LOCKED and sends nothing; a lock left by a crash is deleted by hand once no run is going. Offline check: `node elevenlabs_gen_selftest.js`. A sound-effect prompt over 450 characters fails the whole list, dry runs included (ElevenLabs refuses it with HTTP 400 text_too_long; Wave A2, Nov 23 2026).
- `generation_mode` ("loop", "ambience", "track") was asked for in issue 1585 but is not in the ElevenLabs API reference
  for POST /v1/music read on Nov 22 2026, so the generator sends it only when an item sets it, and the pilot does not.
- Death sounds are atomic beat layers for godot/audio/death_audio.gd (powerdown, bed, vent, crack, boom at the split,
  bass drop at +0.28 s, tail at +0.35 s, wreck at +0.7 s, quiet at +0.9 s): a crack or a burst has no boom in it, and
  no multi-stage death story goes into one cue. Pilot crack takes are 1.0 s so they can be trimmed to the 0.4 s cue.
- Key: `tools/pc/elevenlabs_api_key.bat` (on the PC: ELEVENLABS_API_KEY.bat). Hidden PowerShell prompt; the same
  process saves `VOIDSWORN_ELEVENLABS_API_KEY` as a Windows user setting. The key is never shown, never on a command
  line, never in a file. `/selftest` checks the save path with a dummy value under a separate name and removes it.
  Make the key with only Sound Effects and Music allowed and a credit cap.
- The cloud cannot reach elevenlabs.io: this runs on the PC through the Board's queue.

## Licence and repo rules

- Paid plan only. Never use Free-plan outputs (personal use only, attribution required).
- Music Terms (last updated Oct 9 2026): paid self-serve plans allow commercial use in an Indie Game: under $500,000
  revenue for the game since release and under $1,000,000 a year for the studio. If the game stops qualifying, there are
  60 days to move to a plan that covers Studio Games; copies already distributed keep their music. No attribution on
  paid plans. Output stays under the plan it was made on after a downgrade or cancel. Sound effects: paid plans are
  marked Commercial on the pricing page.
- Never feed Sonniss GDC audio into ElevenLabs or any AI (Sonniss licence v2.0, "NO AI TRAINING OR USAGE").
- Raw masters, MP3s and stem zips stay out of git. When a pick is wired in: level loudness, roll off harsh highs once,
  export Ogg (mono for positional battle sounds, stereo for music, beds and menus), and record the plan, date and these
  terms in godot/audio/SFX_CREDITS.md or godot/music/CREDITS.md and docs/playbooks/sound.md.
- The playbook line "Free tools and free sources only" (docs/playbooks/sound.md) predates Ryan's Nov 22 buy; the Board
  updates it with the first wired pick.

## Gate 3 listening and staged waves (issue 2039)

- Ryan can open [Sound Gate 3](listen_gate3/index.html) with `listen_gate3/LISTEN.bat`. Compare each pair, choose Keep,
  Swap or Cut, then press **Show my picks**. Those are the inputs to run 2, before merge.
- Neon picked 72 IDs in total, including the two Wave A extras. The list spells out exact takes, channel choices and
  trims in `keepers_gate3.json`. `wiring_gate3.json` records the old and new cue names. Wreck settle stays as it is.
  Asteroid scrape and shield raise are mastered and on the page, but do not fire until the trigger is decided.
- Rebuild from clean pre-Gate-3 cue tables with `master_keepers.py` and `wire_gate3.py`. The latter also renders the
  listening clips. Use `--sunward-music` when the two M1 Oggs are present. A dry generator plan never sends a request.
- F2 has nine staged re-roll rows. M2 is staged as `M2_test` first (Glasswrights and Chorus, two tracks and two stem
  splits), then `M2` only if the tests pass by ear. Keep the test output for those two tracks. No paid call without
  Ryan's typed go. Use the named wave's IDs with the generator's `--only` flag.
- For the test, pass the planned BPM and bar count to `stem_loop_check.py`. Listen across the exact-grid wrap and
  compare calm and full at the switch points. The 25 ms click guard does not shorten the loop. The boss and Nemesis
  tracks each have their own stem split to avoid fighting the faction's key and tempo.
