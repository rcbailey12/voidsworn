extends SceneTree
## Issue 1078: the shield failure looks side by side (today's, energy shear, clean collapse), for Ryan to pick one or none.
## Built on the look bench (bench/look_bench.gd: fixed effect clock, fixed seeds, installed ships drawn as the battle draws
## them). Each story plays on one shielded target: a single shield hit, two hits landing at once, a shield hit beside a
## hull hit, then the failure. Stills, a sheet per shield shape and subject, and clip frames.
##
##   godot --path godot --fixed-fps 60 --disable-vsync --resolution 1920x1080 --script res://fx/test/shield_fail_probe.gd
##
## Settings (environment, so a PC .bat can set them):
##   PROBE_OUT        output folder (required)
##   PROBE_SUBJECTS   rules hull ids, comma list (default h_boss,c_boss,i_boss,cathedral: one per shielded faction)
##   PROBE_SHAPES     fitted,egg (default both)
##   PROBE_LOOKS      today,shear,collapse (default all three); "shear_low" is the shear with the cheaper crack network
##   PROBE_RADII      camera radii, comma list (default 170,60)
##   PROBE_CLIP       1: clip frames (every second frame, 1280x720, 30 a second) at camera 170: one folder per subject and
##                    shield shape, the three looks back to back, each after a one second title card
##   PROBE_COST       1: the cost pass instead (PROBE_COST_SHIPS shielded ships, every one failing at once, GPU time)
##   PROBE_BLOCKS     1: allow placeholder blocks (a cloud preview of the script only, never a picture for Ryan)
## Prints SHIELD1078_DONE (or SHIELD1078_FAILED) last.

class Bench extends "res://bench/look_bench.gd":
	func _ready() -> void:
		pass

	func story_ship(id: String, spec: Dictionary, pos: Vector3, facing := 0):
		var view = SV.new()
		view.name = "ship_" + id
		world.add_child(view)
		view.setup({"id": id, "fac": spec.fac, "cls": spec.cls, "size": spec.size, "facing": facing,
			"hp": spec.hp, "maxHp": spec.hp}, pos, true)
		view.set_process(false)
		if _is_block(view) and not args.has("allow-blocks"):
			return null
		var info := {"faction": spec.fac, "cls": spec.cls, "code": view.code, "size": spec.size,
			"flagship": spec.get("boss", false)}
		if not view.a4:
			info["meshes"] = view.meshes
		fx.add_ship(id, view, info)
		view.fx_engines = true
		fx.set_engine(id, 0.3)
		fx.sync_ship(id, _unit(1.0, 5 if float(spec.get("sh", 0)) > 0 else 0))
		return view

const API := preload("res://rules/battle_api.gd")
const CAP := preload("res://tools/picture_provenance.gd")
const REV := "r1"
const CELL := Vector2i(384, 216)
# camera 170 is a 1 to 1 pixel crop (the battle camera at true size); closer cameras are a wider crop scaled down
const CROP := {170: Vector2i(384, 216), 60: Vector2i(1152, 648), 26: Vector2i(1920, 1080)}
const FAIL_AT := [0.1, 0.3, 0.55, 0.85]
const LOOK_NAMES := {"today": "Today's look (default)", "shear": "Energy shear", "shear_low": "Energy shear, lower quality",
	"collapse": "Clean collapse"}

var bench: Bench
var out: String
var rules_hulls: Dictionary
var failed := false
var stills := {}          # moment -> Image (the current story)
var clip_dir := ""
var clip_n := 0
var report := {"rev": REV, "stories": [], "cost": []}


func _initialize() -> void:
	_run.call_deferred()


func _env(k: String, d: String) -> String:
	var v := OS.get_environment(k)
	return d if v.is_empty() else v


func _run() -> void:
	out = _env("PROBE_OUT", "")
	if out.is_empty():
		push_error("SHIELD1078 PROBE_OUT is not set")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(out)
	Engine.max_fps = 0
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var api = API.new()
	if api.load_rules() != "":
		push_error("SHIELD1078 could not read the hull rules")
		quit(2)
		return
	rules_hulls = api.R.HULLS
	bench = Bench.new()
	root.add_child(bench)
	bench.out = out
	if _env("PROBE_BLOCKS", "") == "1":
		bench.args["allow-blocks"] = true
		report["warning"] = "placeholder blocks allowed: a script preview only, not the installed ships"
	Bench.BL.set_look("cine", false)
	bench._setup_view()
	report["adapter"] = RenderingServer.get_video_adapter_name()
	report["godot"] = Engine.get_version_info().get("string", "")
	report["method"] = str(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	var info = JSON.parse_string(FileAccess.get_file_as_string("res://build_info.json")) if FileAccess.file_exists("res://build_info.json") else null
	report["commit"] = str(info.get("commit", "")) if info is Dictionary else ""
	bench._cam(Vector3.ZERO, 170.0)
	if _env("PROBE_COST", "") == "1":
		await _cost()
	else:
		await _stories()
	var f := FileAccess.open(out.path_join("shield1078.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, " "))
		f.close()
	bench._clear()
	bench.queue_free()
	await process_frame
	Bench.FX.clear_static()
	Bench.SV.clear_static()
	print("SHIELD1078_", "FAILED" if failed else "DONE")
	quit(1 if failed else 0)


func _fail(why: String) -> void:
	failed = true
	push_error("SHIELD1078 " + why)


func _set_look(look: String) -> void:
	OS.set_environment("VS_SHIELD_FAILURE", "shear" if look == "shear_low" else look)
	OS.set_environment("VS_SHIELD_FAILURE_Q", "low" if look == "shear_low" else "high")


# ---------------------------------------------------------------- the stories

func _stories() -> void:
	var subjects := _env("PROBE_SUBJECTS", "h_boss,c_boss,i_boss,cathedral").split(",")
	var shapes := _env("PROBE_SHAPES", "fitted,egg").split(",")
	var looks := _env("PROBE_LOOKS", "today,shear,collapse").split(",")
	var radii := _env("PROBE_RADII", "170,60").split(",")
	for sid in subjects:
		if not rules_hulls.has(sid):
			_fail("no rules hull " + sid)
			return
		for shape in shapes:
			for r in radii:
				var rows: Array = []
				for look in looks:
					await _story(sid, shape, look, int(r))
					if failed:
						return
					rows.append([look, stills.duplicate()])
				await _sheet(sid, shape, int(r), rows)


func _scene(sid: String, shape: String, look: String, radius: float) -> bool:
	bench._clear()
	OS.set_environment("VS_SHIELD_SHAPE", shape)
	_set_look(look)
	bench._make_fx()
	bench._cam(Vector3.ZERO, radius)
	bench.fx.rng.seed = 11
	seed(2070)
	var att: Dictionary = rules_hulls["penitent"]
	bench.A = bench.story_ship("A", att, Vector3(-35.0, 0, 18.0))
	var b = bench.story_ship("B", att, Vector3(35.0, 0, 18.0), 3)
	bench.T = bench.story_ship("T", rules_hulls[sid], Vector3.ZERO)
	if bench.A == null or b == null or bench.T == null:
		_fail("placeholder or missing ship for " + sid)
		return false
	var sh = bench.fx.ship("T")
	if not sh.shielded or sh._shield_mat == null:
		_fail(sid + " has no shield")
		return false
	if (sh._shield_tm != null) != (shape == "fitted"):
		_fail("%s did not build the %s shield" % [sid, shape])
		return false
	if "_fail_look" in sh and sh._fail_look != ["today", "shear", "collapse"].find("shear" if look == "shear_low" else look):
		_fail("%s did not pick up the %s look" % [sid, look])
		return false
	return true


func _story(sid: String, shape: String, look: String, radius: int) -> void:
	stills.clear()
	if not _scene(sid, shape, look, radius):
		return
	await bench.fx.warmup(bench.cam)
	for i in 60:
		await bench._step()
	bench.fx.rng.seed = 11
	seed(2070)
	clip_dir = ""
	if _env("PROBE_CLIP", "") == "1" and radius == 170:
		clip_dir = out.path_join("clip_%s_%s_c%d" % [sid, shape, radius])
		if not DirAccess.dir_exists_absolute(clip_dir):
			DirAccess.make_dir_recursive_absolute(clip_dir)
			clip_n = 0
		var card := await _card("SHIELD1078 %s · prototype · %s shield · %s · camera %d" % [REV, shape, str(rules_hulls[sid].get("n", sid)), radius],
			LOOK_NAMES.get(look, look))
		for i in 30:
			card.save_jpg(clip_dir.path_join("f_%04d.jpg" % clip_n), 0.9)
			clip_n += 1
	var row := {"subject": sid, "shape": shape, "look": look, "radius": radius, "moments": {}}
	# 1. one shield hit
	var t1 := _fire("A", true, 3)
	await _until(t1 + 0.06, "hit", row)
	await _until(t1 + 0.7, "", row)
	# 2. two hits landing at once (two ships firing in the same frame)
	var t2 := maxf(_fire("A", true, 3), _fire("B", true, 3))
	await _until(t2 + 0.06, "double", row)
	await _until(t2 + 0.7, "", row)
	# 3. a shield hit and a hull hit side by side (the second ship's shell gets through on an open side)
	var t3 := maxf(_fire("A", true, 3), _fire("B", false, 3))
	await _until(t3 + 0.06, "beside", row)
	await _until(t3 + 0.9, "", row)
	# 4. the failure
	var tb: float = bench.fx.now
	bench.fx.shield_break("T", 3)
	bench.fx.sync_ship("T", bench._unit(1.0, 0))
	for k in FAIL_AT:
		await _until(tb + float(k), "fail_%.2f" % float(k), row)
	await _until(tb + 1.7, "", row)
	report["stories"].append(row)
	print("SHIELD1078 story %s %s %s c%d" % [sid, shape, look, radius])


# fire one battery shot at the target; returns the impact time on the effect clock
func _fire(from: String, shield: bool, quad: int) -> float:
	var at: float = bench.fx.now
	var r: Dictionary = bench.fx.volley(from, "battery", "T", {"weapon_id": "battery", "shots": [true], "quad": quad,
		"hits": [{"shield": 8 if shield else 0, "hull": 0 if shield else 9, "section": "mid"}]})
	if r.get("impacts", []).is_empty():
		_fail("a volley had no impact")
		return at
	return at + float(r.impacts[0])


func _until(t: float, key: String, row: Dictionary) -> void:
	while bench.fx.now < t:
		await bench._step()
		if clip_dir != "" and bench.steps % 2 == 0:
			var img: Image = bench._grab()
			if img != null:
				img = bench._crop(img, Vector2i(1280, 720), Vector2i(1280, 720))
				img.save_jpg(clip_dir.path_join("f_%04d.jpg" % clip_n), 0.9)
				clip_n += 1
	if key != "":
		var img: Image = bench._grab()
		if img == null:
			_fail("empty frame")
			return
		if key == "fail_0.30" and _env("PROBE_FULL", "") == "1":
			img.save_png(out.path_join("full_%s_%s_c%d_%s.png" % [row.subject, row.shape, row.radius, row.look]))
		stills[key] = bench._crop(img, CROP.get(int(row.radius), CELL), CELL)
		row["moments"][key] = bench.fx.now


# One sheet: a row per look, a column per moment, labels drawn by Godot itself (no tools needed on the PC).
func _sheet(sid: String, shape: String, radius: int, rows: Array) -> void:
	var cols := ["hit", "double", "beside"]
	for k in FAIL_AT:
		cols.append("fail_%.2f" % float(k))
	var col_names := {"hit": "One shield hit", "double": "Two hits at once", "beside": "Shield hit beside hull hit"}
	for k in FAIL_AT:
		col_names["fail_%.2f" % float(k)] = "Failure +%.2f s" % float(k)
	var lw := 150
	var head := 46
	var colh := 20
	var size := Vector2i(lw + CELL.x * cols.size(), head + colh + CELL.y * rows.size())
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.07)
	bg.size = size
	vp.add_child(bg)
	var spec: Dictionary = rules_hulls[sid]
	var title := "SHIELD1078 %s · prototype · %s shield · %s (%s, %s) · camera %d" % [REV, shape, str(spec.get("n", sid)), _fac_name(str(spec.fac)), sid, radius]
	if bench.args.has("allow-blocks"):
		title += " · STAND-IN BLOCKS, cloud software render"
	_label(vp, title, Vector2(10, 6), 20, Color(1, 0.85, 0.5))
	_label(vp, ("Camera 170 is the battle camera at true pixel size. " if radius == 170 else "Wider crop, scaled down. ") + "Same shots and seed in every row; only the failure look changes.", Vector2(10, 27), 13, Color(0.75, 0.75, 0.8))
	for c in cols.size():
		_label(vp, col_names[cols[c]], Vector2(lw + c * CELL.x + 6, head + 2), 13, Color(0.9, 0.9, 0.9))
	for r in rows.size():
		var y := head + colh + r * CELL.y
		_label(vp, LOOK_NAMES.get(rows[r][0], rows[r][0]), Vector2(8, y + 8), 15, Color(1, 1, 1), lw - 12)
		for c in cols.size():
			var img: Image = rows[r][1].get(cols[c])
			if img == null:
				continue
			var tr := TextureRect.new()
			tr.texture = ImageTexture.create_from_image(img)
			tr.position = Vector2(lw + c * CELL.x, y)
			vp.add_child(tr)
	for i in 3:
		await RenderingServer.frame_post_draw
	var sheet := vp.get_texture().get_image()
	sheet.convert(Image.FORMAT_RGB8)
	var name := "SHIELD1078_%s_%s_%s_c%d.png" % [REV, sid, shape, radius]
	if CAP.save_png(sheet, out.path_join(name)) != OK:
		sheet.save_png(out.path_join(name))
	vp.queue_free()
	print("SHIELD1078 sheet ", name)


# a 1280x720 title card for the clip
func _card(top: String, big: String) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.05)
	bg.size = Vector2(1280, 720)
	vp.add_child(bg)
	_label(vp, top, Vector2(40, 40), 22, Color(1, 0.85, 0.5))
	_label(vp, big, Vector2(40, 320), 56, Color(1, 1, 1))
	_label(vp, "One shield hit, two hits at once, a shield hit beside a hull hit, then the failure", Vector2(40, 410), 22, Color(0.75, 0.75, 0.8))
	for i in 3:
		await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	vp.queue_free()
	return img


func _label(parent: Node, text: String, pos: Vector2, px: int, col: Color, width := 0) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", col)
	if width > 0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.size = Vector2(width, 120)
	parent.add_child(l)


func _fac_name(f: String) -> String:
	return {"voidsworn": "Sunward Crusade", "corsair": "Ashfall Hullbreakers", "ithar": "the Glasswrights",
		"hegemony": "Hegemony Navy", "chorus": "the Chorus", "deathless": "Eclipse"}.get(f, f)


# ---------------------------------------------------------------- the cost pass

# PROBE_COST_SHIPS shielded ships (every shielded faction in turn) at the battle camera, all failing in the same frame
# every 1.7 s. GPU time of the bench viewport per frame, during the failures and in a quiet window; three repeats per
# look so the noise shows. Run it with the GPU to itself (R293).
func _cost() -> void:
	var looks := _env("PROBE_LOOKS", "today,shear,shear_low,collapse").split(",")
	var shapes := _env("PROBE_SHAPES", "fitted").split(",")
	var n := int(_env("PROBE_COST_SHIPS", "8"))
	var subjects := ["h_boss", "c_boss", "i_boss", "cathedral", "h_dominion", "c_hulk", "i_carrier", "reliquary"]
	var vrid: RID = bench.vp.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vrid, true)
	for shape in shapes:
		for rep in 3:
			for look in looks:
				bench._clear()
				OS.set_environment("VS_SHIELD_SHAPE", shape)
				_set_look(look)
				bench._make_fx()
				bench._cam(Vector3.ZERO, 170.0)
				var ids: Array = []
				for i in n:
					var sid: String = subjects[i % subjects.size()]
					var p := Vector3((i % 4 - 1.5) * 30.0, 0, (int(i / 4) - 0.5) * 34.0)
					if bench.story_ship("T%d" % i, rules_hulls[sid], p) == null:
						_fail("placeholder or missing ship " + sid)
						return
					ids.append("T%d" % i)
				await bench.fx.warmup(bench.cam)
				for i in 90:
					await bench._step()
				var quiet := await _gpu_window(vrid, 60)
				var fail_ms: Array = []
				for cycle in 3:
					for id in ids:
						bench.fx.shield_break(id, 3)
					var w := await _gpu_window(vrid, 96)    # 1.6 s, the whole failure
					fail_ms.append_array(w)
					for id in ids:
						bench.fx.sync_ship(id, bench._unit(1.0, 5))
					for i in 12:
						await bench._step()
				var row := {"shape": shape, "look": look, "repeat": rep, "ships": n,
					"quiet_median_ms": _median(quiet), "fail_median_ms": _median(fail_ms), "fail_p95_ms": _pct(fail_ms, 0.95),
					"fail_max_ms": _pct(fail_ms, 1.0)}
				report["cost"].append(row)
				print("SHIELD1078 cost ", JSON.stringify(row))


func _gpu_window(vrid: RID, frames: int) -> Array:
	var v: Array = []
	for i in frames:
		await bench._step()
		v.append(RenderingServer.viewport_get_measured_render_time_gpu(vrid))
	return v


func _median(a: Array) -> float:
	return _pct(a, 0.5)


func _pct(a: Array, q: float) -> float:
	if a.is_empty():
		return 0.0
	var s := a.duplicate()
	s.sort()
	return float(s[clampi(int(round(q * (s.size() - 1))), 0, s.size() - 1)])
