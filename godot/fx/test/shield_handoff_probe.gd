extends "res://fx/test/shield_fail_probe.gd"
## Issue 1239: before and after pictures of the clean collapse's hand-off to the hull (Neon's audit F2.1 to F2.4), on the
## installed ships, drawn by the look bench the way the battle draws them. Three stories per subject, fitted shield:
##   shoulder  a two-shot volley; the second shot breaks the shield on the bow shoulder and bleeds into the hull
##   lethal    the same volley also kills the ship (the death starts 0.2 s after the break, as the battle's kill beat)
##   torpedo   a three-warhead torpedo salvo: the shield soaks the first, the other two reach the hull
## The same file runs on main (before) and on the branch (after): it calls the branch's new arguments only when the
## checkout has them, so main draws exactly what main does.
##
##   godot --path godot --fixed-fps 60 --disable-vsync --resolution 1920x1080 --script res://fx/test/shield_handoff_probe.gd
##
## Settings (environment):
##   PROBE_OUT        output folder (required)
##   PROBE_TAG        before | after: names the stills folder (PROBE_OUT\handoff_<tag>)
##   PROBE_SUBJECTS   rules hull ids (default i_boss,h_boss)
##   PROBE_RADIUS     camera radius (default 60)
##   PROBE_COMPOSE    "<before folder>;<after folder>": no battle, builds the sheets from two finished runs instead
##   PROBE_PACE       1: the pace sheet instead (Ryan, Nov 20): one failure per close time in PROBE_CLOSES (default
##                    0.7,1.05,1.225,1.4: today and 50, 75 and 100 percent slower), a row each, plus clip frames per row
##   PROBE_BLOCKS     1: placeholder blocks allowed (a cloud preview of the script only, never a picture for Ryan)
## Prints SHIELD1239_DONE (or SHIELD1239_FAILED) last.

const HREV := "r1"
const HCELL := Vector2i(400, 225)
const STORIES := {
	"shoulder": {"name": "Shield breaks on the bow shoulder", "at": [0.1, 0.3, 0.55, 0.85]},
	"lethal": {"name": "The breaking volley kills the ship", "at": [0.1, 0.3, 0.55, 0.85]},
	"torpedo": {"name": "Three-warhead torpedo salvo", "at": [0.05, 0.14, 0.23, 0.6]},
}
const STORY_ORDER := ["shoulder", "lethal", "torpedo"]

var hreport := {"rev": HREV, "rows": [], "scenes": {}}
var new_api := false


func _run() -> void:
	out = _env("PROBE_OUT", "")
	if out.is_empty():
		push_error("SHIELD1239 PROBE_OUT is not set")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(out)
	var api = API.new()
	if api.load_rules() != "":
		push_error("SHIELD1239 could not read the hull rules")
		quit(2)
		return
	rules_hulls = api.R.HULLS
	var compose := _env("PROBE_COMPOSE", "")
	if compose != "":
		await _compose(compose)
		print("SHIELD1239_", "FAILED" if failed else "DONE")
		quit(1 if failed else 0)
		return
	Engine.max_fps = 0
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	new_api = load("res://fx/fx_weapons.gd").get_script_constant_map().has("TORP_WARHEAD_GAP")
	bench = Bench.new()
	root.add_child(bench)
	bench.out = out
	if _env("PROBE_BLOCKS", "") == "1":
		bench.args["allow-blocks"] = true
		hreport["warning"] = "placeholder blocks allowed: a script preview only, not the installed ships"
	Bench.BL.set_look("cine", false)
	bench._setup_view()
	var info = JSON.parse_string(FileAccess.get_file_as_string("res://build_info.json")) if FileAccess.file_exists("res://build_info.json") else null
	hreport["commit"] = str(info.get("commit", "")) if info is Dictionary else ""
	hreport["new_api"] = new_api
	hreport["adapter"] = RenderingServer.get_video_adapter_name()
	if _env("PROBE_PACE", "") == "1":
		await _pace()
		hreport["scenes"] = report.get("scenes", {})
		var fp := FileAccess.open(out.path_join("shield1239_pace.json"), FileAccess.WRITE)
		if fp != null:
			fp.store_string(JSON.stringify(hreport, " "))
			fp.close()
		bench._clear()
		bench.queue_free()
		await process_frame
		Bench.FX.clear_static()
		Bench.SV.clear_static()
		OS.set_environment("VS_SHIELD_CLOSE", "")
		print("SHIELD1239_", "FAILED" if failed else "DONE")
		quit(1 if failed else 0)
		return
	var tag := _env("PROBE_TAG", "after")
	var dir := out.path_join("handoff_" + tag)
	DirAccess.make_dir_recursive_absolute(dir)
	var radius := float(_env("PROBE_RADIUS", "60"))
	for sid in _env("PROBE_SUBJECTS", "i_boss,h_boss").split(","):
		if not rules_hulls.has(sid):
			_fail("no rules hull " + sid)
			break
		for story in STORY_ORDER:
			await _hstory(sid, story, radius, dir)
			if failed:
				break
		if failed:
			break
	hreport["scenes"] = report.get("scenes", {})
	var f := FileAccess.open(dir.path_join("shield1239.json"), FileAccess.WRITE)
	if f == null:
		_fail("could not write shield1239.json")
	else:
		f.store_string(JSON.stringify(hreport, " "))
		f.close()
	bench._clear()
	bench.queue_free()
	await process_frame
	Bench.FX.clear_static()
	Bench.SV.clear_static()
	print("SHIELD1239_", "FAILED" if failed else "DONE")
	quit(1 if failed else 0)


func _hstory(sid: String, story: String, radius: float, dir: String) -> void:
	if not await _scene(sid, "fitted", "collapse", radius):
		return
	await bench.fx.warmup(bench.cam)
	for i in 60:
		await bench._step()
	bench.fx.rng.seed = 11
	seed(2070)
	var fx = bench.fx
	var t0: float = fx.now
	var row := {"subject": sid, "story": story, "code": str(bench.T.code), "moments": {}}
	var break_at := -1.0
	var lp := Vector3.INF
	if story == "torpedo":
		var T = fx.ship("T")
		fx.torp_lane("L1239", "A", T.to_world(T.hull.c), 1)
		fx.torp_launch("L1239")
		for i in 40:
			await bench._step()
		var hits := [{"shield": 8, "hull": 0, "section": "mid", "crit": false}, {"shield": 0, "hull": 9, "section": "prow", "crit": false},
			{"shield": 0, "hull": 9, "section": "eng", "crit": true}]
		var ts: float = fx.now
		var r: Dictionary
		if new_api:
			r = fx.torp_strike("L1239", "T", hits[0], hits.slice(1), 0)
		else:
			r = fx.torp_strike("L1239", "T", hits[0])
		var imp: Array = r.get("impacts", [])
		if imp.is_empty():
			_fail("the torpedo had no impact")
			return
		row["impacts"] = imp
		break_at = ts + float(imp[0])
		var pts: Array = r.get("hit_pts", [])
		if not pts.is_empty():
			lp = pts[0]
	else:
		var opts := {"weapon_id": "battery", "shots": [true, true], "quad": 3,
			"hits": [{"shield": 8, "hull": 0, "section": "mid", "crit": false}, {"shield": 4, "hull": 3, "section": "prow", "crit": false}]}
		if new_api:
			opts["break_k"] = 1
		var r: Dictionary = fx.volley("A", "battery", "T", opts)
		var imp: Array = r.get("impacts", [])
		if imp.size() < 2:
			_fail("the volley had %d impacts" % imp.size())
			return
		row["impacts"] = imp
		break_at = t0 + float(imp[1])
		var pts: Array = r.get("hit_pts", [])
		if pts.size() > 1:
			lp = pts[1]
	# the break on the breaking hit, as battle.gd's _land_hit does
	while fx.now < break_at:
		await bench._step()
	if new_api and lp.is_finite():
		fx.shield_break("T", 3, lp)
	else:
		fx.shield_break("T", 3)
	fx.sync_ship("T", bench._unit(1.0, 0))
	var tb: float = fx.now
	row["break_t"] = tb
	row["aim"] = str(lp) if lp.is_finite() else "quadrant middle"
	var killed := false
	for k in STORIES[story]["at"]:
		while fx.now < tb + float(k):
			if story == "lethal" and not killed and fx.now >= tb + 0.2:
				killed = true
				fx.death("T", "blast")
			await bench._step()
		var img: Image = bench._grab()
		if img == null or img.is_empty():
			_fail("empty frame")
			return
		img = bench._crop(img, CROP.get(int(radius), Vector2i(1152, 648)), HCELL)
		var name := "%s_%s_%.2f.png" % [sid, story, float(k)]
		# (a plain still: only the finished sheet carries the picture stamp, so no stamp covers a cell)
		if img.save_png(dir.path_join(name)) != OK:
			_fail("could not save " + name)
			return
		row["moments"]["%.2f" % float(k)] = fx.now
	for i in 90:
		await bench._step()
	hreport["rows"].append(row)
	print("SHIELD1239 story %s %s %s" % [sid, story, JSON.stringify(row)])


# ---------------------------------------------------------------- the sheets (one per subject and story)

func _compose(spec: String) -> void:
	var parts := spec.split(";")
	if parts.size() != 2:
		_fail("PROBE_COMPOSE needs <before>;<after>")
		return
	var runs := []
	for p in parts:
		var j = JSON.parse_string(FileAccess.get_file_as_string(p.path_join("shield1239.json"))) if FileAccess.file_exists(p.path_join("shield1239.json")) else null
		if not (j is Dictionary):
			_fail("no shield1239.json in " + p)
			return
		runs.append({"dir": p, "json": j})
	# both arms must have drawn the same ship files (Artoo on PR 1329): the scene sha256 each recorded, per hull code
	var sa: Dictionary = runs[0]["json"].get("scenes", {})
	var sb: Dictionary = runs[1]["json"].get("scenes", {})
	var blocks := str(runs[1]["json"].get("warning", "")) != ""   # (a cloud preview on stand-in blocks has no ship files)
	if not blocks and (sa.is_empty() or sb.is_empty()):
		_fail("a run recorded no ship scenes")
		return
	for code in ([] if blocks else sb.keys()):
		var ha := str((sa.get(code, {}) as Dictionary).get("sha256", ""))
		var hb := str((sb[code] as Dictionary).get("sha256", ""))
		if hb == "" or ha != hb:
			_fail("%s drew different ship files before (%s) and after (%s)" % [code, ha, hb])
			return
	var codes := {}
	for row in runs[1]["json"]["rows"]:
		codes[str(row["subject"])] = str(row["code"])
	var subjects: Array = []
	for row in runs[1]["json"]["rows"]:
		if not subjects.has(str(row["subject"])):
			subjects.append(str(row["subject"]))
	for sid in subjects:
		for story in STORY_ORDER:
			await _hsheet(sid, story, str(codes.get(sid, sid)), runs)
	if not failed:
		var f := FileAccess.open(out.path_join("shield1239_compose_done.txt"), FileAccess.WRITE)
		if f == null:
			_fail("could not write shield1239_compose_done.txt")
		else:
			f.store_string("before and after sheets built; scenes match: %s\n" % JSON.stringify(sb))
			f.close()


func _hsheet(sid: String, story: String, code: String, runs: Array) -> void:
	var at: Array = STORIES[story]["at"]
	var lw := 170
	var head := 50
	var colh := 22
	var size := Vector2i(lw + HCELL.x * at.size(), head + colh + HCELL.y * 2 + PFOOT)
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.07)
	bg.size = size
	vp.add_child(bg)
	var spec: Dictionary = rules_hulls.get(sid, {})
	var title := "SHIELD1239 %s · %s · %s %s (%s) · fitted shield · camera %s" % [HREV, STORIES[story]["name"], code,
		str(spec.get("n", sid)), _fac_name(str(spec.get("fac", ""))), _env("PROBE_RADIUS", "60")]
	if str(runs[1]["json"].get("warning", "")) != "":
		title += " · STAND-IN BLOCKS"
	_label(vp, title, Vector2(10, 6), 20, Color(1, 0.85, 0.5))
	_label(vp, "Same shots and seed in both rows. Times are after the shield breaks.", Vector2(10, 29), 13, Color(0.75, 0.75, 0.8))
	for c in at.size():
		_label(vp, "+%.2f s" % float(at[c]), Vector2(lw + c * HCELL.x + 6, head + 2), 14, Color(0.9, 0.9, 0.9))
	for r in 2:
		var y := head + colh + r * HCELL.y
		var commit := str(runs[r]["json"].get("commit", ""))
		_label(vp, ("Before (main)" if r == 0 else "After (this fix)") + ("\n" + commit.left(8) if commit != "" else ""), Vector2(8, y + 8), 15, Color(1, 1, 1), lw - 12)
		for c in at.size():
			var p: String = (runs[r]["dir"] as String).path_join("%s_%s_%.2f.png" % [sid, story, float(at[c])])
			if not FileAccess.file_exists(p):
				_fail("missing still " + p)
				continue
			var img := Image.load_from_file(p)
			var tr := TextureRect.new()
			tr.texture = ImageTexture.create_from_image(img)
			tr.position = Vector2(lw + c * HCELL.x, y)
			vp.add_child(tr)
	for i in 3:
		await RenderingServer.frame_post_draw
	var sheet := vp.get_texture().get_image()
	sheet.convert(Image.FORMAT_RGB8)
	var name := "SHIELD1239_%s_%s_%s_%s.png" % [HREV, code, sid, story]
	if preload("res://tools/picture_provenance.gd").save_png(sheet, out.path_join(name)) != OK:
		_fail("could not stamp the sheet " + name)
	vp.queue_free()
	print("SHIELD1239 sheet ", name)


# ---------------------------------------------------------------- the pace sheet (Ryan, Nov 20 2026)
# "Can we close the shield break down/collapse by like 50, 75 or 100% so it's slightly more visible": the same failure
# at each close time, a row each, the same moments in every row.
const PCELL := Vector2i(248, 140)
const PFOOT := 92   # room under the rows for the picture stamp, so it never covers a cell
const PACE_AT := [0.1, 0.35, 0.6, 0.85, 1.1, 1.4]
const PACE_NAMES := {"0.7": "Today (0.70 s)", "1.05": "50% slower (1.05 s)", "1.225": "75% slower (1.23 s)", "1.4": "100% slower (1.40 s)"}


func _pace() -> void:
	var closes := _env("PROBE_CLOSES", "0.7,1.05,1.225,1.4").split(",")
	var radius := float(_env("PROBE_RADIUS", "60"))
	for sid in _env("PROBE_SUBJECTS", "i_boss,h_boss").split(","):
		if not rules_hulls.has(sid):
			_fail("no rules hull " + sid)
			return
		var rows: Array = []
		var code := sid
		for c in closes:
			OS.set_environment("VS_SHIELD_CLOSE", c)
			if not await _scene(sid, "fitted", "collapse", radius):
				return
			code = str(bench.T.code)
			await bench.fx.warmup(bench.cam)
			for i in 60:
				await bench._step()
			bench.fx.rng.seed = 11
			seed(2070)
			var cdir := out.path_join("clip_%s_close_%s" % [sid, c.replace(".", "_")])
			DirAccess.make_dir_recursive_absolute(cdir)
			var n := 0
			var card := await _card("SHIELD1239 %s · %s %s · fitted shield · camera %d" % [HREV, code, str(rules_hulls[sid].get("n", sid)), int(radius)],
				str(PACE_NAMES.get(c, c + " s")))
			for i in 30:
				preload("res://tools/picture_provenance.gd").save_jpg(card, cdir.path_join("f_%04d.jpg" % n), 0.9)
				n += 1
			var tb: float = bench.fx.now
			bench.fx.shield_break("T", 3)
			bench.fx.sync_ship("T", bench._unit(1.0, 0))
			var sh = bench.fx.ship("T")
			var got = sh._shield_mat.get_shader_parameter("brk_close")
			if got == null or absf(float(got) - float(c)) > 0.001:
				_fail("%s: the shield did not take the close time %s (got %s)" % [sid, c, str(got)])
				return
			var cells := {}
			for k in PACE_AT:
				while bench.fx.now < tb + float(k):
					await bench._step()
					if bench.steps % 2 == 0:
						var fr: Image = bench._grab()
						if fr != null:
							fr = bench._crop(fr, Vector2i(1280, 720), Vector2i(1280, 720))
							preload("res://tools/picture_provenance.gd").save_jpg(fr, cdir.path_join("f_%04d.jpg" % n), 0.9)
							n += 1
				var img: Image = bench._grab()
				if img == null or img.is_empty():
					_fail("empty frame")
					return
				cells["%.2f" % float(k)] = bench._crop(img, CROP.get(int(radius), Vector2i(1152, 648)), PCELL)
			for i in 40:
				await bench._step()
				if bench.steps % 2 == 0:
					var fr: Image = bench._grab()
					if fr != null:
						fr = bench._crop(fr, Vector2i(1280, 720), Vector2i(1280, 720))
						preload("res://tools/picture_provenance.gd").save_jpg(fr, cdir.path_join("f_%04d.jpg" % n), 0.9)
						n += 1
			rows.append([c, cells])
			hreport["rows"].append({"subject": sid, "code": code, "close": float(c), "frames": n})
			print("SHIELD1239 pace %s %s close %s" % [sid, code, c])
		await _pace_sheet(sid, code, rows, radius)


func _pace_sheet(sid: String, code: String, rows: Array, radius: float) -> void:
	var lw := 150
	var head := 44
	var colh := 20
	var size := Vector2i(lw + PCELL.x * PACE_AT.size(), head + colh + PCELL.y * rows.size() + PFOOT)
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
	var title := "SHIELD1239 %s · collapse pace · %s %s (%s) · fitted shield · camera %d" % [HREV, code, str(spec.get("n", sid)), _fac_name(str(spec.fac)), int(radius)]
	if bench.args.has("allow-blocks"):
		title += " · STAND-IN BLOCKS"
	_label(vp, title, Vector2(10, 5), 19, Color(1, 0.85, 0.5))
	_label(vp, "Same failure in every row; only the close time changes. Times are after the shield breaks.", Vector2(10, 26), 13, Color(0.75, 0.75, 0.8))
	for c in PACE_AT.size():
		_label(vp, "+%.2f s" % float(PACE_AT[c]), Vector2(lw + c * PCELL.x + 6, head + 1), 13, Color(0.9, 0.9, 0.9))
	for r in rows.size():
		var y := head + colh + r * PCELL.y
		_label(vp, str(PACE_NAMES.get(rows[r][0], str(rows[r][0]) + " s")), Vector2(8, y + 8), 15, Color(1, 1, 1), lw - 12)
		for c in PACE_AT.size():
			var img: Image = rows[r][1].get("%.2f" % float(PACE_AT[c]))
			if img == null:
				continue
			var tr := TextureRect.new()
			tr.texture = ImageTexture.create_from_image(img)
			tr.position = Vector2(lw + c * PCELL.x, y)
			vp.add_child(tr)
	for i in 3:
		await RenderingServer.frame_post_draw
	var sheet := vp.get_texture().get_image()
	sheet.convert(Image.FORMAT_RGB8)
	var name := "SHIELD1239_%s_pace_%s_%s.png" % [HREV, code, sid]
	if preload("res://tools/picture_provenance.gd").save_png(sheet, out.path_join(name)) != OK:
		_fail("could not stamp the sheet " + name)
	vp.queue_free()
	print("SHIELD1239 sheet ", name)
