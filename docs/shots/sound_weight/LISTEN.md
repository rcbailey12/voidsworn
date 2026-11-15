# Sound weight listening page (issue 771)

Four sounds, each in a "before" and an "after" take, so the change can be judged by ear.
Before is the dry sound on main. After is the issue 771 build: deaths and big hits carry a tail,
the sub-bass and a bed for the length of the death picture; the mix ducks under the core flash; a
capital death leaves a short beat of near-silence; capital hits and shield breaks get a tail; the
lance and the torpedo get a short charge. Guns stay short and dry.

## Listen

Double-click `PLAY.bat`. It plays the eight files in order: before then after for each sound, as a
plain Windows media player. It needs no tools and no game install.

| Sound | Before | After | What to listen for |
| --- | --- | --- | --- |
| Cruiser death | `before/cruiser_death.wav` | `after/cruiser_death.wav` | a tail and a low bed under the whole ten second death picture, and the mix dipping under the core flash |
| Capital death | `before/capital_death.wav` | `after/capital_death.wav` | the same, longer (about sixteen seconds), with a short beat of near-silence after the core flash |
| Lance shot | `before/lance_shot.wav` | `after/lance_shot.wav` | a short charge before the shot, then the same dry shot |
| Shield break | `before/shield_break.wav` | `after/shield_break.wav` | a tail after the break, not a one second pop |

The files are 16 bit mono wav at 22050 Hz, so they are small and open anywhere.

## How the renders were made

`godot/audio/build/bake_sound_weight.gd` runs the game's own cue path through the Master bus (with
its compressor and limiter) and captures it. It renders both passes: the before pass sets the
player's `legacy` flag, which leaves out the new tail layers, the death bed, the duck, the charge
and the small death pitch variation; the after pass is the real build. Death timings come from the
real `DeathTimeline` in `godot/fx/fx_death.gd`, so the bed length is the death picture length.

Run it from the repo root (Godot 4.7.2, no window needed):

```
"C:\Users\rcbai\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path godot --script res://audio/build/bake_sound_weight.gd
```

It prints one line per file and rewrites `before/` and `after/` under this folder.

The headless proof of the same behaviour is `godot/audio/test/sound_weight_check.gd`; it is listed
in `godot/tools/ci/godot_checks.txt` and runs with the other headless Godot checks.
