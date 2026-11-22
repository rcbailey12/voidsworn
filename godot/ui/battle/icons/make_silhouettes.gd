extends SceneTree
## Offline only. Run with a renderer and pass the directory of installed GLBs:
## --script res://ui/battle/icons/make_silhouettes.gd -- SHIP_DIR [REVIEW_DIR]
## Uses the manifest's reviewed GLBs, an orthographic camera and a white, unlit material.

const MANIFEST := "res://assets/ships/manifest.json"
const OUTPUT := "res://ui/battle/icons/ships"
const GS := preload("res://ui/theme/glass_shell.gd")

var view: SubViewport
var camera: Camera3D
var flat: StandardMaterial3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or DisplayServer.get_name() == "headless":
		printerr("FAIL silhouettes: a renderer and SHIP_DIR are required")
		quit(1)
		return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)).get("ships", {})
	var codes := manifest.keys()
	codes.sort_custom(func(a, b): return str(manifest[a].faction) + ":" + str(a) < str(manifest[b].faction) + ":" + str(b))
	var paths := {}
	for code: String in codes:
		var fn := code + ".glb"
		var path := args[0].path_join(code).path_join(fn)
		if FileAccess.get_sha256(path) != str(manifest[code].files[fn].sha256):
			printerr("FAIL silhouettes: missing or different reviewed GLB: ", path)
			quit(1)
			return
		paths[code] = path
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	view = SubViewport.new()
	view.own_world_3d = true
	view.size = Vector2i(512, 256)
	view.transparent_bg = true
	view.msaa_3d = Viewport.MSAA_4X
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(view)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	view.add_child(camera)
	flat = StandardMaterial3D.new()
	flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var proof: Array[Dictionary] = []
	for code: String in codes:
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		state.handle_binary_image = GLTFState.HANDLE_BINARY_DISCARD_TEXTURES
		if doc.append_from_buffer(_model_bytes(paths[code]), "", state) != OK:
			printerr("FAIL silhouettes: cannot read ", paths[code])
			quit(1)
			return
		var hull := doc.generate_scene(state) as Node3D
		view.add_child(hull)
		var box := _flatten(hull)
		var top: bool = box.size.y < box.size.x * 0.13 or manifest[code].faction == "ithar"
		var center := box.get_center()
		var extent := box.size.length() + 4.0
		camera.far = extent * 3.0
		camera.position = center + (Vector3.UP if top else Vector3.BACK) * extent
		camera.look_at(center, Vector3.FORWARD if top else Vector3.UP)
		camera.size = maxf(box.size.x * 0.5, box.size.z if top else box.size.y) * 1.05
		view.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		var im := view.get_texture().get_image()
		hull.free()
		var used := im.get_used_rect()
		if not used.has_area():
			printerr("FAIL silhouettes: blank projection for ", code)
			quit(1)
			return
		im = im.get_region(used)
		im.convert(Image.FORMAT_RGBA8)
		for y in im.get_height():
			for x in im.get_width():
				im.set_pixel(x, y, Color(1, 1, 1, im.get_pixel(x, y).a))
		im.resize(256, maxi(1, roundi(float(used.size.y) * 256 / used.size.x)), Image.INTERPOLATE_LANCZOS)
		if "--proof-only" not in args and im.save_png(OUTPUT.path_join(code + ".png")) != OK:
			printerr("FAIL silhouettes: cannot write ", code)
			quit(1)
			return
		proof.append({"code": code, "faction": manifest[code].faction, "image": ImageTexture.create_from_image(im)})
		print("PASS silhouette ", code, ": ", "top" if top else "side")
	if args.size() > 1 and not await _review_sheet(proof, args[1]):
		quit(1)
		return
	print("PASS silhouettes: %d installed hulls" % proof.size())
	quit()


## Keep the original node hierarchy and BIN geometry. The unlit proof has no
## material inputs, so strip texture references before GLTFDocument can load them.
func _model_bytes(path: String) -> PackedByteArray:
	var raw := FileAccess.get_file_as_bytes(path)
	var bin_start := 20 + int(raw.decode_u32(12))
	var data: Dictionary = JSON.parse_string(raw.slice(20, bin_start).get_string_from_utf8())
	for field in ["materials", "images", "textures", "samplers"]:
		data.erase(field)
	for mesh in data.meshes:
		for primitive in mesh.primitives:
			primitive.erase("material")
	var text := JSON.stringify(data).to_utf8_buffer()
	while text.size() % 4 != 0:
		text.append(32)
	var result := raw.slice(0, 20)
	result.encode_u32(8, 20 + text.size() + raw.size() - bin_start)
	result.encode_u32(12, text.size())
	result.append_array(text)
	result.append_array(raw.slice(bin_start))
	return result


func _flatten(n: Node3D) -> AABB:
	var bounds := AABB()
	if n is MeshInstance3D and n.mesh != null and n.is_visible_in_tree():
		n.material_override = flat
		bounds = n.global_transform * n.get_aabb()
	for child in n.get_children():
		if child is Node3D:
			var more := _flatten(child)
			if more.has_surface():
				bounds = bounds.merge(more) if bounds.has_surface() else more
	return bounds


func _review_sheet(proof: Array[Dictionary], dir: String) -> bool:
	var sheet := SubViewport.new()
	sheet.size = Vector2i(1280, 720)
	sheet.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(sheet)
	var page := Sheet.new()
	sheet.add_child(page)
	for start in range(0, proof.size(), 36):
		page.entries = proof.slice(start, start + 36)
		page.queue_redraw()
		sheet.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		var name := "keel_silhouettes_%02d.png" % (1 + int(float(start) / 36))
		if preload("res://tools/picture_provenance.gd").save_png(sheet.get_texture().get_image(), dir.path_join(name), "sheet built") != OK:
			return false
	return true


class Sheet extends Node2D:
	const FACTIONS := {"voidsworn": "Sunward Crusade", "corsair": "Ashfall Hullbreakers", "ithar": "Glasswrights",
		"deathless": "Eclipse", "chorus": "Chorus", "hegemony": "Meridian Directorate"}
	var entries: Array[Dictionary] = []

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("#11151b"))
		draw_string(GS.sheet_name(), Vector2(38, 47), "KEEL / INSTALLED HULL SILHOUETTES", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, GS.MAP_EMBER)
		for i in entries.size():
			var cell := Vector2(38 + (i % 6) * 205, 65 + floorf(float(i) / 6) * 90)
			var e: Dictionary = entries[i]
			var tex: Texture2D = e.image
			var native := tex.get_size()
			var fit := native * minf(162.0 / native.x, 42.0 / native.y)
			draw_texture_rect(tex, Rect2(cell + Vector2(0, (42 - fit.y) * 0.5), fit), false, GS.TEXT)
			draw_string(GS.num(), cell + Vector2(0, 61), str(e.code), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, GS.TEXT)
			draw_string(GS.sheet_body(), cell + Vector2(0, 79), str(FACTIONS.get(e.faction, e.faction)), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, GS.TEXT2)
