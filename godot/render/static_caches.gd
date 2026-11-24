extends RefCounted
# Issue 1204 (the G-6 exit-crash class): resources held in script-level statics outlive the RenderingServer at quit
# and crash the exit on Windows (PC bot runs ended with an access violation after the summary). Every script whose
# statics can hold a texture, mesh, material, shader or font has a static func clear_static() and is on this one list.
# Both quit paths (main.gd quit_clean, battle.gd _quit) call clear_all() after the scene is freed.
# The standing check contrib/opus/tools/gpu_statics_tests.js fails on a GPU-holding static that is not cleared here.

const SCRIPTS := [
	"res://render/ship_view.gd",
	"res://render/shader_keep.gd",
	"res://render/board.gd",
	"res://render/look.gd",
	"res://render/shader_cache.gd",
	"res://scenes/battle/fx_stub.gd",
	"res://fx/fx.gd",
	"res://fx/terrain_scorch.gd",
	"res://portraits/portraits.gd",
	"res://world/world.gd",
	"res://world/world_bake.gd",
	"res://world/world_planet.gd",
	"res://world/world_rocks.gd",
	"res://world/world_living.gd",
	"res://world/blocker_visuals.gd",
	"res://ui/campaign/map3d_props.gd",
	"res://ui/battle/brand.gd",
	"res://ui/battle/icons/keel_icons.gd",
	"res://ui/theme/glass_shell.gd",
	"res://ui/theme/orders_kit.gd",
	"res://ui/theme/modal_focus.gd",
]


# Every listed script is loaded and cleared, loaded before or not: its statics start empty, so loading one fills nothing,
# and no cache check can silently skip a script (an exported build's cache is not tested in the cloud).
static func clear_all() -> void:
	for p in SCRIPTS:
		if not ResourceLoader.exists(p):
			push_error("static_caches: listed script missing: " + p)
			continue
		var sc = load(p)
		if sc != null and sc.has_method("clear_static"):
			sc.clear_static()
