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

static var trace := false

# Clear every loaded owner. Never load a new system just to clear its empty cache while closing.
static func clear_all() -> void:
	for p in SCRIPTS:
		if not ResourceLoader.exists(p):
			push_error("static_caches: listed script missing: " + p)
			continue
		if not ResourceLoader.has_cached(p):
			continue
		var t0 := Time.get_ticks_usec()
		var sc = load(p)
		var t1 := Time.get_ticks_usec()
		if sc != null and sc.has_method("clear_static"):
			sc.clear_static()
		if trace:
			print("[main] quit cache %s: fetch %.1f ms, clear %.1f ms" % [
				p, (t1 - t0) / 1000.0, (Time.get_ticks_usec() - t1) / 1000.0])
	trace = false
