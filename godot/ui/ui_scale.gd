extends RefCounted
# The one UI scale law for every screen (contrib/opus/briefs/ui_spec.md section 4, FINDINGS R136; settles TY4 of the
# Nov 6 UI audit). Before this there were six copies with three ceilings (battle HUD, title and campaign fallback 2.2,
# campaign screens 2.5, career screen and rename dialog 2.0); all six agreed at 1080, 1440 and 2160 lines.
#
#   k = clamp(window height / 1080, 0.6, 2.2) x the player's UI scale
#
# 1080 is the design height: every size in the UI code is written as it looks at 1920x1080. The floor and the ceiling
# are provisional: the U-A calibration captures (1440p, 4K and a small window, ruled on by Ryan) set them for good
# (HD1). The ceiling only binds above 2376 lines, the floor below 648.
# The player's UI scale (R2) multiplies the window law. It stays 1.0 until the settings entry ships (ui_spec.md 4.4);
# main.gd copies settings["ui_scale"] here when settings are applied, and a missing key reads as 1.0.
# Users: hud.gd (s), title.gd (s), campaign_ui.gd (px, which map3d.gd's labels read), campaign_fallback_ui.gd,
# career_screen.gd, rename_dialog.gd, load_screen.gd. A new screen calls k_for(), never its own clamp.

const DESIGN_HEIGHT := 1080.0
const K_MIN := 0.6
const K_MAX := 2.2
const PLAYER_MIN := 0.8
const PLAYER_MAX := 1.4
# TY6: no text is set below 12 at the design height (12 pixels at 1080 lines, 24 at 4K). Checked by script
# (contrib/opus/tools/ui_spec_tests.js) on every font size literal in godot/ui and godot/main.
const MIN_TEXT := 12

static var player := 1.0


# the UI scale for a window of size vs (its height decides; the width never does, TY5)
static func k_for(vs: Vector2) -> float:
	return clampf(vs.y / DESIGN_HEIGHT, K_MIN, K_MAX) * clampf(player, PLAYER_MIN, PLAYER_MAX)


# a design size (written at 1080) at scale k, in whole pixels
static func px(v: float, k: float) -> int:
	return int(round(v * k))


# the player's UI scale from the settings dictionary (main.gd); anything missing or out of range reads safely
static func set_player(v) -> void:
	player = clampf(float(v), PLAYER_MIN, PLAYER_MAX) if (v is float or v is int) else 1.0
