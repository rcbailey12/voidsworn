# Issue 354 death vent strips

Before and after captures of the ship death vent, for the DeepSeek workhorse job on issue 354. The death vent gas
used to be placed by pushing the middle of the baked picture a fixed share of the ship's length away from the hull
(0.42 of 0.85 L), so the visible gas floated beside the ship. The gas root is now found with the hull ray the braking
puffs have used since PR 327, and the picture is placed from its measured root (0.40 of the picture height), so the
gas starts on the plating and blows outward.

## Files

| File | What it shows |
|---|---|
| `death_vent_strip_c170.jpg` | Frigate, cruiser and capital deaths, before (top) and after (bottom), at the battle camera (r 170), 1 to 1 pixels. |
| `death_vent_strip_c26.jpg` | The same at the closest the game allows (r 26), the bench's 1152x648 crop scaled to 384x216 cells. |
Each sheet row is 24 cells, one every 1/30 s of effect time from the death call, which covers the vent beat at 0.12 s
(small) or 0.30 s (big) and its drift.

The raw probe strips are also in the job's `out\shots` folder as `<class>_c<cam>_<before|after>.png` for the reviewer.

The vent picture itself is still the pale 64-cell bake. This job only puts its root on the plating; P3-16 (issue 365)
replaces the picture.

## How they were made

The standing look bench's death rows jump from the death call to the split, so they never show the vent at 0.12 s or
0.30 s. The vent beat was captured with a focused probe in the same pattern instead:

```
godot --path godot --fixed-fps 60 --disable-vsync --resolution 1920x1080 --script res://fx/test/death_vent_strip_probe.gd
```

`DV_OUT` selects the output folder; `DV_CLASS` and `DV_CAM` select the rows. The before run is the same probe on
main's `godot/fx/fx_death.gd` (restored for the run, then the change put back); the after run is the change. Real
ShipView hulls from `godot/gen`, the real world and look, a fixed effect clock and the real `fx.death` cause per
class. The frigate is a Hullbreaker frigate (blast), the cruiser a Sunward cruiser (big), the capital a Hegemony
super-dreadnought (cut).

## The measured root

In the baked vent pictures (godot/fx/atlases/death/small, cruiser and capital, vent_color.png) the visible gas runs
down to row 0.90 of the crop, and the crop is rows 0.40 to 0.84 of the cell. The directional flip puts that lower
edge at the +up end of the quad, so the root sits 0.40 of the picture height from its centre. `fx_death.gd` uses
that number (`VENT_ROOT_FRAC`) and the hull ray hit as the root. The old placement used 0.42 of the whole picture
height with the picture centre as the reference, which put the gas root 0.82 of the picture height out from the
plating. P3-16 (issue 365) rebakes these pictures and must redo this number.

## The check

`godot/fx/test/death_spawn_check.gd` kills the Eclipse cruiser (a disc with a tower, a hull that does not fill its
box) through the real death path and measures each picture's gas root against the ship's own hull samples. It reads
the vent atlas itself (frame 0, inside the shader's crop) to find the root share, so a rebake without redoing the
number shows up. On main the vent root was 6.747 from the hull (limit 1.856) and no death picture recorded a spawn.
With the change every picture passes and all seven pictures recorded a spawn.
