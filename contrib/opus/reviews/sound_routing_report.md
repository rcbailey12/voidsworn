# Issue 506: gun sounds at fire time, hull hits chosen by weapon and target

Owner: muse. Branch work/issue-506-deepseek. Sound only, nothing on screen changes.

## What changed

- `godot/scenes/battle/battle.gd` (the fire and hit calls only):
  - The gfx volley path now plays one `sfx.gun` per shot at the fire time the fx layer used for
    that shot's muzzle effect (the new `fires` array), instead of one cue at the volley start
    about 0.2 s before the first flash.
  - The no-gfx fallback path does the same on its own bolt delay, and the separate every-other-shot
    gun call is gone (one cue per shot there too).
  - Hull hits call `sfx.impact(fam, target faction, pos, crit)` at the impact time (already a timer
    on the hit effect's own clock). Shield-only hits keep `sfx.shield`. Torpedo hits keep the boom.
    Death cues are untouched.
- `godot/audio/sfx.gd`:
  - `gun(...)` takes an optional delay and passes it to `play`, so each shot's cue is scheduled on
    the same clock and inside the cue's existing gap and max limits, with the same defer rule.
  - One routing table: `HIT_BY_WEAPON` (las and lance to hit_las, plasma to hit_plasma, rail and
    gauss to hit_rail, ion to hit_ion) and `HIT_BY_TARGET` (Chorus to hit_wet, Glasswright to
    hit_glass). Everything else keeps `hit` (shells, autocannon, tracer, bio, needle, flak, sq).
  - Critical hull hits play `hit_heavy` instead of the family cue. That was my call from the job's
    "layered or instead": instead, so a critical never doubles the voices. Say so in review.
  - `impact_cue()` and `impact()` are the only new public helpers. `hit(pos, heavy)` is unchanged
    for the rules' generic hit event, which carries no weapon family.
- `godot/fx/fx_weapons.gd`: `_shot` returns its fire time as a third value and `_volley` returns a
  `fires` array beside `impacts` (ship and points paths). The guns/bombs/sporeb branch now stores
  the same `T0 + i * 0.15` it already passed to the strafe; the unknown-look branch reports its
  existing end time. No visual timing changed. The job's deliver list did not name this file, but
  the job says not to duplicate the magic numbers and the audit's code finding says to return the
  per-shot fire times from fx.volley. This is the one supporting edit needed to do that.
- `godot/audio/test/audio_check.gd`: 10 routing assertions, including the requested one that fails
  if a las hit plays `hit`.
- `contrib/opus/reviews/sound_routing_report.md`: this report.
- `godot/audio/cues.json` is unchanged: no cue needed a routing field. No new clips, no new voices,
  voice caps and ducking untouched.

## Proof

Seeded six-ship bot battle, cinematic capture scenario s1, seed 1001, the same fight the Codex
capture logged. Before and after produced the same battle (ended true, 132.6 s and 132.8 s).

| cue | before | after |
|---|---|---|
| gun_las | 18 | 50 |
| gun_plasma | 17 | 34 |
| hit | 40 | 1 |
| hit_heavy | 5 | 5 |
| hit_las | 0 | 18 |
| hit_plasma | 0 | 17 |
| hit_ion | 0 | 4 |
| salvo_tail | 0 | 1 |

All other cues are identical between the two runs. Total cue starts: 186 before, 236 after. The
one remaining `hit` is a Corsair tracer hull hit, which the job leaves on the generic cue. The
`salvo_tail` row appearing is the cue table working as designed now that one call per shot reaches
the salvo counter; the review noted it almost never fired with one call per volley.

Gun cue against the fx muzzle fire time (a five-shot macro volley, using the real
`fx.volley_at` fire offsets and `sfx.gun` delays; the battle path uses the same values):

```
fire offsets s: [0.2, 0.28, 0.36, 0.44, 0.52]
cue lags s:     [0.019, 0.008, 0.011, 0.007, 0.009]
```

Each cue starts within 0.02 s of its own muzzle effect. In the battle log the same rhythm shows as
las delays 0.05, 0.17, 0.29 s and plasma delays 0.12, 0.28 s on successive shots, where before
there was one cue at the volley start.

Target material after only (probe capped at 180 s): scenario s13 (Chorus targets) logged
`hit_wet 36, hit 26, hit_heavy 5`; scenario s8 (Glasswright targets) logged
`hit_glass 16, hit 13, hit_heavy 11, hit_las 4`. The generic rows are weapon families the job
leaves on `hit` (bio, needle, tracer) striking a non-Chorus, non-Glasswright hull.

The raw logs are in `out/shots/` (`cue_log_before_s1_seed1001.json`, `cue_log_after_s1_seed1001.json`,
`cue_log_after_s13_chorus.json`, `cue_log_after_s8_ithar.json`) with `cue_counts_before_after.txt`.
There are no screenshots because the job changes sound only.

## Checks I ran

```
node contrib/opus/tools/run_all_checks.js   -> exit 0. Findings row is the known baseline
                                               (KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5),
                                               all other rows PASS.
cmd.exe //c "tools\\pc\\parity.bat nopause"  -> PASS: the Godot port matches the game's rules exactly.
                                               PASS: the Godot campaign matches the game on all 30
                                               seeded runs, and the cross-twin save hand-off passes.
godot --headless --script res://audio/test/audio_check.gd
                                             -> AUDIO CHECK PASS
godot --headless --script res://audio/test/salvo_check.gd
                                             -> SALVO CHECK PASS
godot --headless --script res://audio/test/smoke_lifetime_check.gd
                                             -> SMOKE LIFETIME PASS: 0 engine/script errors
godot --headless --script res://tools/ci/load_all.gd
                                             -> load all: 155 scripts, 11 scenes, 0 failed
godot --headless --script res://tools/ci/bot_battle.gd -- --seed 359
                                             -> bot battle: PASS (win after 3 rounds, no script errors,
                                               no unknown event lines)
```

## How the change reaches the rest of the game

- Callers: `sfx.gun` is called only from `battle.gd:_play_fire` (the gfx path and the fallback)
  and `audio/test/salvo_check.gd`; the new delay argument is optional and the test call still
  passes. `sfx.hit` still has its old signature and is still used by the rules' generic `hit`
  event in `battle.gd:_impact`; every weapon volley hit now calls `sfx.impact`. `fires` is only
  read by `battle.gd`; the other `impacts` readers (look bench, fx probes, gallery) ignore the
  extra key.
- Saves: no player profile, run save or battle field changed. A save written before this change
  loads and plays unchanged; campaign parity (30 seeded runs plus the cross-twin save hand-off)
  and the standing save checks (`save_fuzz`, `inheritance_tests`) pass.
- Twins: no JS root file (`battle.js`, `data.js`, `core.js`) changed, so no table re-export was
  needed. `oracle_copy_test.js` passes, and rules parity plus campaign parity prove the two sides
  still match. Audio lives only in the Godot port; the browser sound is frozen.
- UI: no screen shows the routing table. The Sound on/off option, volume and the cue list are
  unchanged; `audio_check.gd` rechecks the cues, buses, variants and mute behavior.
- CI: I added the assertions to the existing `godot/audio/test/audio_check.gd` rather than a new
  file, so no new registration was needed. GitHub runs it through `godot/tools/ci/godot_checks.txt`
  in the Godot game checks job (with `salvo_check.gd` and `smoke_lifetime_check.gd`), and it also
  runs `node contrib/opus/tools/run_all_checks.js`, rules parity, campaign parity, the tree hand-off,
  the Nemesis scenarios, the load-all step and the seed 359 bot battle. `run_all_checks.js` itself
  runs Node checks only, not GDScript.

## Calls and skipped work

- Criticals: `hit_heavy` instead of the family cue (no layering, no extra voice).
- Bio, needle, flak, tracer, squadron and shell families keep `hit`; the job's mapping does not
  list them and their target factions decide Chorus and Glasswright. A bio hit on a Chorus hull
  still plays `hit_wet` because the target table wins.
- Torpedo hits, death cues, shield cues, the cue table values, ducking and the voice caps are
  untouched, as the job asks.
- No screenshot or listening page: the job's "what Ryan will see" is nothing on screen; the
  listening page is a later sound job.
- I did not touch the move playback block (issue 505, around lines 1470 to 1640 in battle.gd).
