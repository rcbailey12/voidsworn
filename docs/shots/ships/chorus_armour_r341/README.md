# R341: the Chorus armour shell, before and after (issue 1234)

One sheet per ship, 1920 x 720: the current look (top row, the shared Chorus kit and the issue 1058 paint stack as merged from
codex/issue-1058) above the armoured look (bottom row), at the battle camera's distance 170 (true size on a 1080p screen) and
26, plus one close-up of the skin.

- chorus_C11_R341_sheet.jpg (b_razor), chorus_C12_R341_sheet.jpg (b_drone), chorus_C13_R341_sheet.jpg (b_spitter)

Method: each ship baked in the cloud with tools/blender/r209/bake_sheet.py (Blender 4.5 bpy, Cycles CPU, 1024 maps, 8 samples),
then render_views.py (the game's key and fill light, the Chorus albedo lift 1.25, the battle camera's pitch) and make_sheet.py.
Cloud bakes are previews: the PC export (stages 5 to 7 at 4096) waits for Ryan's yes.
