# Battle sound pass 1

Implements build items 1 to 6 from the Muse audio synthesis, with the task's
owner overrides. No gameplay values, FX visuals, music assets or credits changed.
No commit was made. No downloaded or newly rendered audio was needed.

## Changes by item

1. Added ten cue ids to `cues.json`, bringing the table from 57 to 67. The
   synthesis's eleventh id, `ui_plan`, is instead `ui_confirm` at gain 0.707946
   (-3 dB), on move confirmation and target selection. Fire and End ship use
   normal confirmation gain. All new cues use the existing layer schema plus
   optional `duration`, a power-down `end_rate`, and additive faction variants.
   Durations include a short ending fade. Regenerating the browser synth takes
   preserves the Godot-only cues and the gun defer fix.
2. Brace and boarding dispatch from their existing resolution events, for both
   sides. Chorus boarding uses its wet variant. The carrier adaptation report
   and the Nemesis adaptation branch emit a presentation-only `adaptation`
   event. The scene plays `adapt_shift` at most once per battle. Rules state,
   numbers, random draws and log text are unchanged.
3. `death_audio.gd` observes existing FX metadata and the FX clock. Capitals
   power down immediately, vent at .25 FX seconds, crack at .4, and play
   `boom_l` when the hull actually splits. A delayed fracture worker delays the
   boom too. `bass_drop` follows the single core flash at split + .28 FX
   seconds, after the beat releases; reduce flashing skips that sting. `wreck`
   follows at split + .7. The R73 beat already exists in FX. Its actual active
   flag ducks music and ordinary battle audio by 6 dB, with normal playback
   pitch and speed. The existing class/flagship filter owns eligibility. Hurry
   releases the duck when FX releases the beat. Audio does not change visuals.
4. Small ships play `death_run`, stop it at the actual burst, play `boom_s`,
   then `chunk_cool`. The fallback without staged FX has no death-run sound.
   Actual FX hulk outcomes play only `hulk_vent`. Reinforcements each play
   `arrive_jump`, .14 seconds apart, with enemy playback rate .92. Their
   `ui_alert` is removed. The nearby command-warning alert is retained.
5. Every `gun_*` defer covers 40 starts (20 ships with twin barrels), including
   the scheduler's maximum 60 percent stagger jitter and .06 seconds of slack.
   Each also satisfies defer >= gap * max and defer >= gap * 2.5. Caps are
   enforced when a cue is due to start, so pending starts are not stolen before
   being heard. All existing per-cue caps and the global 34-cue cap remain.
   Quiet cooling/vent voices have priority zero and are stolen first. Pending
   layers cannot start after their voice has been stolen; stop_all cancels
   pending cue starts. Existing explosion duck fields now duck the ambient bed.
6. SFX volume and mute now use an independent `sfx` bus. Zero/off sets its mute
   flag, as music does, while music and Master stay unmuted. Restoring volume
   unmutes SFX. A non-finite volume cannot poison the bus. Existing gain floors
   and rate clamps are retained.

## Cue sources

Names below are the existing clip-set keys in `clips/index.json`, which select
all their numbered Ogg takes. Existing synth filenames are listed separately.

| Cue | Recorded clip sets | Existing synth takes |
| --- | --- | --- |
| death_powerdown | ionCharge, whoosh | none |
| death_vent | whoosh | none |
| death_crack | scrape, hullHitBig; ithar adds shieldHit | ithar adds hit_glass_0.ogg, hit_glass_1.ogg, hit_glass_2.ogg |
| death_run | none | engine_0.ogg, engine_1.ogg |
| chunk_cool | debris, scrape | none |
| hulk_vent | whoosh, scrape | none |
| arrive_jump | whoosh, boomLow | none |
| board_grapple | hullHitBig, scrape, whoosh | chorus adds hit_wet_0.ogg, hit_wet_1.ogg, hit_wet_2.ogg |
| brace_lock | hullHit, hullHitBig | none |
| adapt_shift | uiSelect twice, at different rates | none |

Retimed existing cues retain their sources: `boom_s` uses boomSmall plus
boom_s_0/1/2.ogg; `boom_l` uses boomBig and debris; `bass_drop` uses bassDrop;
`wreck` uses scrape. The `ui_plan` override uses uiConfirm. No CC BY intake.

## Verification

Double-click `tools/pc/audio_checks.bat`. It locates the installed Godot console
exe, or accepts `GODOT_EXE` or an exe path as its first argument. Logs stay in
`godot/audio/test/results/`. Optional second argument `nopause` supports runners.
The BAT fails if a script exits nonzero or its PASS marker is missing.

Checked with Godot 4.7.2 headless on Nov 2, 2026:

- AUDIO CHECK PASS: all 67 cues have playable sources, both variants add their
  layers, real brace/boarding branches dispatch for both sides, real adaptation
  reports emit semantic events, duplicate reports sound once, independent mute,
  NaN volume guard, R73 duck and restore, staged death timing, a late split,
  hulk-only audio, small run/burst/cooling, and reduced-flashing sting suppression.
- SALVO CHECK PASS: each of ten gun families starts 20/20; twin shell starts
  40/40. Each start checks its actual AudioStreamPlayer and the per-cue/global
  caps. A mixed-family overload also tests global saturation. stop_all cancels
  pending starts.
- Targeted rules parity PASS: s7 carrier adaptation, 367 identical records;
  s29 Nemesis adaptations, 126 identical records. State hashes and PRNG state
  match the pinned JS oracle after every recorded action, activation and round.
- `git diff --check` and Node syntax check of `render_synth.js`: PASS.
- Existing MUSIC CHECK: FAIL (49). All 24 referenced files under music/tracks
  are missing from this supplied folder: 48 file/open failures plus the map-loop
  check. No music files were fetched or copied from elsewhere. Music duck/mute
  routing is covered by AUDIO CHECK, but track playback cannot be verified here.

There was no existing separate SFX/audio checker in this supplied snapshot, so
the new audio check covers that surface. The headless engine also prints a
Windows certificate-store error, unrelated to these offline checks. This is
functional verification; listening and an in-game mix audition remain undone.
