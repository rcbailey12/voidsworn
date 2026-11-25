# ElevenLabs sound candidates (issues 1572 and 1585)

Ryan, Nov 22 2026: ElevenLabs Creator, monthly ($11 first month, then $22), for sound redo candidates. Ryan, 04:10 UTC
(issue 1585, Neon's pre-flight on PR 1577): hold the blind Batch 1, run a small Gate 1 pilot first, pick by ear, then
Gate 2 production and Gate 3 stems. Nothing is wired into godot/ until Ryan picks.

The prompts follow sections 2 to 8 of the [sound plan](../plans/cohesive_audio_v2.md), including the section 2 banned-word list.

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

- Ryan can open [Sound Gate 3](listen_gate3/index.html) with `listen_gate3/LISTEN.bat`. The clips that play in game
  are on the page, with the three Wave F3 picks and the full Chorus calm and intense loops first. The sound effect previews
  use the cue levels without battle bus effects or distance.
- The list has 80 SFX keeper IDs including the two Wave A extras. Godot plays 78. Asteroid scrape and shield raise remain
  catalogued but do not fire until their triggers are decided. Wreck settle stays as it is.
- `keepers_gate3.json` records the source take, channel and mastering edits. `wiring_gate3.json` records the runtime
  cue and the original keeper for variety additions. Rebuild from clean pre-Gate-3 cue tables with `master_keepers.py`
  and `wire_gate3.py`. The latter also renders shipped cues for the listening page.
- The shipped F3 picks are `death_metal_crack_f3` t1, `ship_thruster_puff_f3` t1 and
  `wep_eclipse_gsentry_more_f3` t1. `mus_chorus_loop_a_test2` t1 is the Chorus battle pair. Its calm mix is all stems
  except drums, and its intense mix is the full song. `wire_gate3.py --chorus-music` adds both listening previews.
- `M2_test5` stages only `mus_ithar_loop_a_test5`, a re-roll of test4 with its own receipt. Every take since test2 asked
  for a steady timpani pulse from bar 1, and because timpani are tuned drums that pulse is two pitches repeated for the
  whole loop and it lands outside the drums stem, which left test4's calm mix only 0.7 dB under the full mix. Test5
  removes timpani and tuned drums, gives every section its own unpitched groove, and bans ostinato, drone, pedal tone and
  a repeated two-note figure. Use the wave's ID with the generator's `--only` flag. No paid request without Ryan's go.
- Review gate: the core tone changes colour, register or harmony in every section. Compare test4 with test5 on the
  listening page once the Board has the new take. Listen in both mixes for a held tone or a repeated two-note figure,
  and check that the calm mix still carries the whole melody without drums. Check that there is no timpani or tuned
  drum in the full mix and that the calm mix is 1 to 12 dB under the full mix.
- Run `stem_loop_check.py` with the planned BPM and bar count. The source MP3 may be 50 ms short or 120 ms long,
  but the mastered loop uses the exact bar grid and the 25 ms click guard. Listen across the wrap and compare calm and
  full at the switch points. Review the Glasswrights test5 by ear before starting the rest of M2. The remaining M2 rows are unchanged.
