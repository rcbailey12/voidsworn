extends SceneTree
# F4 bake preview: the sky and planet pictures of one or more settings, saved as PNGs, without the battle scene.
#   godot --path godot --resolution 640x360 --script res://world/tools/bake_preview.gd -- --out DIR [--w 1024] [--only sky|planet]
# Settings: one per campaign region (the same biomes as world_shots.gd) and the dead star.

const SKY := preload("res://world/world_sky.gd")
const PL := preload("res://world/world_planet.gd")
const BAKER := preload("res://world/world_bake.gd")

const SETS := [
	["frontier", {"rock": "stone", "planet": 0}, "corsair", false],
	["nebula", {"rock": "ice", "planet": 7}, "ithar", false],
	["world", {"rock": "stone", "planet": 3}, "hegemony", false],
	["boneyard", {"rock": "carbon", "planet": 5}, "deathless", false],
	["deep", {"rock": "carbon", "planet": 6}, "deathless", false],
	["deadstar", {"rock": "ice", "planet": 2}, "ithar", true],
	["nebula_chorus", {"rock": "crystal", "planet": 2}, "chorus", false],
	["world_voidsworn", {"rock": "ice", "planet": 1}, "voidsworn", false],
	["frontier_volcanic", {"rock": "iron", "planet": 4}, "hegemony", false],
]


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var args := {}
	var a := OS.get_cmdline_user_args()
	var i := 0
	while i < a.size():
		if a[i].begins_with("--"):
			args[a[i].substr(2)] = a[i + 1] if i + 1 < a.size() and not a[i + 1].begins_with("--") else "true"
		i += 1
	var out := str(args.get("out", "/tmp"))
	var w := int(args.get("w", "1024"))
	var only := str(args.get("only", ""))
	var pick := str(args.get("sets", ""))
	DirAccess.make_dir_recursive_absolute(out)
	var baker = BAKER.new()
	root.add_child(baker)
	for s in SETS:
		if pick != "" and not pick.split(",").has(s[0]):
			continue
		var st: Dictionary = SKY.setting(s[1], s[2], "open", s[3], 1)
		if only != "planet":
			var params := {"seed": float(int(st["seed"]) % 997) * 0.37, "c1": st["c1"], "c2": st["c2"], "c3": st["c3"], "neb": float(st["neb"]),
				"cover": float(st["cover"]), "dust": float(st["dust"]), "band": float(st["band"]), "band_n": st["band_n"], "feature": st["feature"],
				"steps": 40, "lamp": PackedVector4Array(SKY.lamps(st)), "gal": PackedVector4Array(SKY.galaxies(st))}
			var img: Image = await baker.bake("sky_" + s[0], SKY.bake_code(), params, Vector2i(w, w / 2), 4)
			if img != null:
				img.save_png(out.path_join("sky_%s.png" % s[0]))
				print("saved sky ", s[0])
		if only != "sky" and not s[3]:
			var P: Dictionary = st["planet"]
			for pass_id in 2:
				var pp := {"seed": float(int(st["seed"]) % 997) * 0.71, "kind": int(P["kind"]), "ca": P["a"], "cb": P["b"], "cc": P["c"], "pass_id": pass_id}
				var img2: Image = await baker.bake("pl_%s_%d" % [s[0], pass_id], PL.bake_code(), pp, Vector2i(w, w / 2), 2)
				if img2 != null:
					img2.save_png(out.path_join("planet_%s_%d.png" % [s[0], pass_id]))
		print("done ", s[0])
	quit(0)
