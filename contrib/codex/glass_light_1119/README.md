# CD5 glass lighting probe

Refs #1137. The probe uses the isolated run 4 CD5 and C11 exports from
`e148748d5a074fe933a34ced35cc14e41d4a1419`. The battle source is
`d26b229c44aa7e49281eabd703f3951f2a29bc07`.

- [CD5 from both sides, with glass rod and sphere](../../../docs/shots/glass_light_1119/CD5_lighting.jpg)
- [C19_51 metal and C11 chitin](../../../docs/shots/glass_light_1119/C19_51_C11_lighting.jpg)

## Pick

Try the **cool edge light** first. At radius 170 it picks out the top and
crossing edges on both sides of CD5. At radius 26 those highlights help the eye
follow the curved glass across the darker frames behind it. C19_51 keeps its
red plates, and C11 gets a stronger glint along the top of its shell.

The pale strip puts the clearest curved reflection on the plain sphere. On
CD5 it is stronger from side 2. Brighter sky lifts the whole reflection,
especially on the close views. The nebula trial produces the smallest change
at radius 170. The battle-sized gain from lighting alone is modest across the
sheet. These are visual judgments from the stills.

## What the probe changes

`probe.tscn` builds the stock battle Environment, key, fill and hull rim through
the battle scene. It uses the production dead-star sky shader and nebula bake.
`look.gd` sets the final ambient to cool white after battle setup. The scene
holds the hulls still, uses the same camera on each side and captures after
30 settled frames per view. Radius 170 crops keep native pixels. Radius 26
shows matching detail crops. The 1920 by 720 sheets fit five columns at
those scales.

| Setup | Change |
| --- | --- |
| Today's light | Live battle lights and the 256-pixel sky radiance map. |
| Brighter sky | 512-pixel radiance map and 3.5 times the existing reflected sky. |
| Nebula reflections | A radiance map with stronger baked gas and wider highlights around two stars from the same nebula. |
| Cool edge light | A shadowless hull light placed 29 degrees off the camera's line of sight from behind the ship. |
| Pale light strip | A broad pale band in the reflection map. Its bend gives the eye a continuous glass highlight to follow. |

The sky-only captures were pixel-identical in all five setups from both sides.
The run 4 glass is unshaded and samples the scene and sky itself. For each
trial the probe supplies the added light to its existing reflection term.
The baseline uses the original run 4 shader. The five glass surfaces, smoke,
refraction, dispersion, paint maps and geometry are the same across the test.
The 512-pixel map applies to Godot's lit surfaces. CD5's glass samples the
reflections directly.

## Scene 207 at 1080p

Three separate Godot 4.7.2 sessions held solo GPU claims on the RTX 5080.
Every setup used the same 24-ship storm scene with CD5, C11 and C19_51,
Forward+, 4x MSAA, fitted shields, full mesh detail and vsync off. After
warm-up, each case measured at least 720 frames and eight seconds of volleys.
All five glass surfaces stayed active in every case.

| Setup | Frame median | Frame p95 | Frame p99 | Worst frame | GPU median | Visible + shadow draws |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Today's light | 3.72 ms | 5.84 ms | 8.15 ms | 67.62 ms | 2.67 ms | 475 + 313 |
| Brighter sky | 4.19 ms | 6.52 ms | 8.36 ms | 85.14 ms | 2.66 ms | 476 + 313 |
| Nebula reflections | 4.32 ms | 7.86 ms | 11.02 ms | 46.20 ms | 2.65 ms | 478 + 313 |
| Cool edge light | 4.13 ms | 6.91 ms | 9.13 ms | 67.07 ms | 2.66 ms | 476 + 313 |
| Pale light strip | 4.76 ms | 7.03 ms | 9.74 ms | 70.24 ms | 2.57 ms | 476 + 313 |

The table uses the middle of the three session statistics and the worst frame
across all sessions. All 15 medians passed the 12.5 ms gate. Median frame time
ranged from 3.24 to 4.52 ms for today's light and 3.63 to 4.41 ms for cool edge
light. Some sessions were uneven, with brighter sky reaching a 10.93 ms median
in one pass. The table measures steady play after the reflection maps settle.

## Reproduce

Copy the isolated run 4 Godot project into the current job's `%TEMP%`. Its
installed ship manifest SHA-256 is
`06a9d9125b289c194695e91e8d9137bf8b497dd15933ed17b02a01528095dc9d`. Its generated
manifest SHA-256 is
`f46f08fd7c288a88852ddaf138bd7c73fff7d3eaea414217ac6bf3edf0978857`.
Run `stage.ps1 -Project "$env:TEMP/review"` from PowerShell. It copies the
probe and original glass shader into that project and stages the scene 207
sampler with issue 1058's two roster substitutions.

- Use `tools/pc/tmo.bat` to launch Godot 4.7.2 in Forward+ at 1920 by 1080.
  For stills, run `res://bench/glass_light_1119/probe.tscn` with `--fixed-fps 60`
  and pass an absolute scratch output directory after `--`. Capture twice
  and pass the second folder and a destination to `sheets.py`.
- For timing, set `PC_GPU_MODE=solo` and `VS_SHIELD_SHAPE=fitted`. Launch
  `--script res://bench/glass_light_1119/boot_207.gd` and pass `--out` with a
  fresh scratch directory, `--suite timing --warmup 180 --frames 720
  --min-us 8000000` and a `--cases` list. Prefix each of `today`, `bright_sky`,
  `nebula_map`, `edge_light`, and `light_strip` with `gate:max:1:`. Set
  `--session` to a distinct integer for each launch and vary the case order.
