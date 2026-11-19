# Nebula wake prototype, issue 1079

Ships disturb the calm nebula as they pass. Visual only: no rule, move or terrain changes. Off by default.

## What it does

- `godot/world/nebula_wake.gd` keeps a small ring of recent ship positions (8 at Max and High, 4 at Low). A ship that
  has moved about 0.8 of its disturbance radius drops a point. Each point pushes the gas aside, curls it and thins it a
  little, then fades out over 3 seconds. No fluid simulation, nothing persistent.
- The radius comes from hull length: about 9 units for a frigate, up to 26 for a capital (a hex is 17.3 across).
- It reads every ship the battle shows (`battle.gd` `views`, through `world_living.gd`), so every faction and class
  picks it up, squadrons included. Nothing is per hull.
- The shaders carry two marker comments, `// WAKE_SHIFT` and `// WAKE_THIN` (world_living.gd); the wake code replaces
  them only when on. `world/test/nebula_wake_check.gd` fails if a calm gas shader at Max, High or Low loses them.
- Only the calm nebula is touched: its gas cards (every tier) and its fog volume (Max). The ion storm's cards, fog and
  flare are never changed.
- Off (the default), the gas shaders are byte for byte today's: the wake code is only added when the setting is on.

## How to turn it on

- Settings key `nebula_wake` (main.gd, default false; no menu switch yet, nothing installed without Ryan's pick).
- Battle flag `--nebula-wake`, or `b.args["nebula_wake"] = "true"` from a bench.

## Evidence

- `OPUS1079_RUN3.bat` is the deciding run on main after PR 1210 (marker injection, High added; writes out3): clip, stills and timing passed; its scene 207 gate timed out on a cold first build (sky bakes about 40 s each against the gate's 60 s build limit, mode base with the wake off). `OPUS1079_RUN4.bat` redoes only the gate with `--build-wait-s 300` (writes out4). `OPUS1079_RUN2.bat` (PC, queued by the Board, R334; it replaces `OPUS1079_RUN.bat`, which reset a reused clone on a retry): a fresh clone per run, the clip frames (wake off then on, 1280x720, 30 fps, at the battle camera c170 and closer at c120; the video is assembled and checked in the cloud), the stills (max
  and low), the dense-storm fixture timing (GPU solo, wake off and on, max and low, 1080p and 4K, 3 sessions, plus a held
  worst case) and scene 207 (`bench/scene_gate.tscn` modes base, wake_idle, wake_full).
- Capture script: `godot/world/nebula_wake_capture.gd` (modes still, shots, timing).
- Cloud drafts (software renderer, placeholder hull blocks) are for checking the effect reaches the gas only; they are
  never a sheet for Ryan.
