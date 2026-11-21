extends SceneTree
# Scale pictures use real units from the real scenario constructor, one per
# class. Only their presentation positions change for this labelled turntable.
const API := preload("res://rules/battle_api.gd")
const BATTLE := preload("res://scenes/battle/battle.tscn")
const WR := preload("res://world/world_rocks.gd")
const HT := preload("res://render/hull_table.gd")
const PG := preload("res://render/placeholder_guard.gd")
var out := ""
var title: Label

func _initialize() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	var a := OS.get_cmdline_user_args()
	if a.size() != 2 or a[0] != "--out":
		quit(2)
		return
	out = a[1]
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()

func frames(n: int) -> void:
	for i in n: await process_frame

func shot(name: String, text: String) -> void:
	title.text = text
	await frames(12)
	await RenderingServer.frame_post_draw
	if PG.stop_if_any(): return
	var img := root.get_texture().get_image()
	# 1280x720 viewport: every picture is a full frame at actual pixels.
	preload("../../../godot/tools/picture_provenance.gd").save_png(img, out.path_join(name + ".png"))
	print("R01_SHOWCASE ", name)

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	AudioServer.set_bus_mute(0,true)
	var api = API.new()
	if api.load_rules() != "":
		quit(1)
		return
	var fleet := []
	var classes := {}
	for id in api.R.HULLS:
		var cls := str(api.R.HULLS[id].cls)
		if HT.CLS_LEN.has(cls) and cls != "Squadron" and not classes.has(cls):
			classes[cls] = true
			fleet.append(id)
	var sc := {"seed":5,"sector":3,"admiral":"vex","fleet":fleet,
		"enemies":["c_raider"],"fac":"corsair","obj":"rout",
		"shape":"open","map":"open","dep":"line","kind":"battle"}
	api.new_battle_scenario(sc,5)
	var b = BATTLE.instantiate()
	b.external = true
	b.args["no-tips"] = true
	b.args["quality"] = "max"
	root.add_child(b)
	b.battle_cfg = sc
	b.begin_with(api)
	await frames(3)
	while b.warming or b.busy: await process_frame
	if PG.stop_if_any(): return
	b.hud.hide()
	b.board.hide()
	if is_instance_valid(b.world): b.world.hide()
	if is_instance_valid(b.gfx): b.gfx.hide()
	b.cam.input_enabled = false
	b.cam.keyboard_enabled = false
	b.cam.screen_shift = 0
	for sv in b.views.values(): sv.hide()
	var layer := CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	title = Label.new()
	title.position = Vector2(18,16)
	title.add_theme_font_size_override("font_size",21)
	title.add_theme_color_override("font_shadow_color",Color.BLACK)
	title.add_theme_constant_override("shadow_outline_size",8)
	layer.add_child(title)
	var rock := MeshInstance3D.new()
	rock.mesh = WR.mesh("scan_04")
	rock.material_override = WR.material("stone",{"haze_max":0.0})
	rock.scale = Vector3.ONE*20.0
	rock.position = Vector3(30,0,0)
	root.add_child(rock)
	var rows := []
	for u in api.view().units:
		if u.side != "player": continue
		var sv = b.views[u.id]
		sv.position = Vector3(-30,0,0)
		sv.show()
		for radius in [170.0,60.0]:
			b.cam.r = radius
			b.cam.b = 0.98
			b.cam.t = Vector3.ZERO
			b.cam.snap()
			await shot("R01_scale_%s_c%d" % [str(u.cls).replace("-","_"),int(radius)],
				"R01 | %s %.1f units | scan_04 proposed 20x | camera %d" % [u.cls,sv.L,int(radius)])
		rows.append({"class":u.cls,"hull_code":sv.code,"length":sv.L,"rock_scale":20.0,"rock_long_axis":20.0*float(WR.mesh("scan_04").get_aabb().size[WR.mesh("scan_04").get_aabb().get_longest_axis_index()])})
		sv.hide()
	rock.scale = Vector3.ONE*16
	rock.position = Vector3(-22,0,0)
	var far := MeshInstance3D.new()
	far.position = Vector3(22,0,0)
	far.scale = Vector3.ONE*16
	far.material_override = rock.material_override
	root.add_child(far)
	b.cam.r = 170
	b.cam.t = Vector3.ZERO
	b.cam.snap()
	for name in WR.scan_names():
		rock.mesh = WR.mesh(name)
		far.mesh = WR.mesh(name + "_lo")
		await shot("R01_" + name, "R01 | %s | full scan left, reduced mesh right | same 16x scale" % name)
	for kind in WR.KINDS:
		rock.mesh = WR.mesh("scan_04")
		far.mesh = WR.mesh("scan_04_lo")
		rock.material_override = WR.material(kind,{"haze_max":0.0})
		far.material_override = rock.material_override
		await shot("R01_biome_" + kind, "R01 | scan_04 | %s biome | full and reduced" % kind)
	var f := FileAccess.open(out.path_join("R01_scale.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(rows,"  ") + "\n")
	PG.finish(0)
