# Destruction audit, five small reads (#229, from #212 S-F; Opus, Nov 8 2026)

Read against main at the time of writing. PF10 (the movement spec boundary) is in #228.

## PF9: gravity well, Godot rules state

**Matches the browser rules; no fix needed.** `godot/rules/rules.gd` carries `wellTick` and `aiWellScore` line for line with `battle.js:290-297`: the same constants (WELL_RIM 3, WELL_PULL 5, WELL_ASSIST 6, WELL_DMG 7, exported through tables.json), +1 movement inside 6 hexes, 7 tidal hull damage on the rim with the tidal kill and queued death, a one-hex pull toward the star between 4 and 5 hexes onto the first free board hex, AI scoring -45 on the rim and -6 in the pull band. The battle is built with `well` only on a dead-star shape that has a star hex (`rules.gd:1137`), the turn tick calls it (`rules.gd:1453`), and two parity scenarios cover it (`godot/rules/test/scenarios.json`: the Oct 24 well scenario with pulls, tidal damage and AI steering, and the X20 tidal death). The rules emit `tick/tidal` and `pulled` events; the battle view handles `pulled` (`battle.gd:1300`) and tidal deaths fall toward `fx.well` (`fx_death.gd:1293`). The Dead Star background-only ruling is not reopened.

## PF12: squadron physics

**No physics model.** `godot/render/squadron_wing.gd` animates each craft on a closed sine weave around its rest slot (position and rotation from a clock, faster and looser for the Chorus), with sampled trails; `squadron_craft.gd` only builds meshes. No velocity, steering, mass or collision. Squadron movement on the board is the rules' hex movement; the wing is decoration riding the unit.

## CM10: Godot post-processing state as shipped

Battle (`battle.gd` environment plus `render/look.gd`): ACES tonemap (AgX available as an option in look.gd), white 8, exposure 1; glow on (HDR threshold 0.8, intensity 0.6, screen blend, levels 1 to 4 weighted 0.6, 1.0, 0.6, 0.25); SSAO and SSIL on at Max, SSIL off at High, SSAO, SSIL and volumetric haze off at Low; no SSR, no SDFGI, no depth of field, no colour adjustment in battle. MSAA 4x at Max, 2x at High, off plus FXAA at Low; TAA off by default (setting, Max and High only). Shadows: soft high filter, 4 cascades, 4096 atlas (2048 at Low). Campaign 3D map: ACES, glow 0.55, contrast 1.06 and saturation 1.08, MSAA 4x or 2x, no screen-space AA.

## DS13: split width against the 1-unit clearance

**Not checkable yet; carried to #169.** `fx_death.gd:1270` sets `split_width = hull length x 0.04` (about 1.66 units on a 41.6-unit capital). It is the band around a cut used to pick the glowing seam points (`fx_death.gd:1398`), not a geometric gap between pieces. D22's 1-unit clearance is about authored break lines on rebuilt hulls. The comparison needs #169's authored break lines and recordings, which do not exist yet (#169 is open). Rider added to #169.
