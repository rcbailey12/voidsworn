extends RefCounted
## One cached revision query per run. Stamping frames never launches a process.
## Python and Godot share tools/picture_font.json and the same sidecar schema.
static var _contexts: Dictionary = {}
static var _glyphs: Dictionary = {}

static func save_png(image: Image, path: String, stage: String = "installed in game") -> Error:
	return _save(image, path, stage, false, 0.9)

static func save_jpg(image: Image, path: String, quality: float = 0.9, stage: String = "installed in game") -> Error:
	return _save(image, path, stage, true, quality)

static func _hash(bytes: PackedByteArray) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	return hash.finish().hex_encode()

static func _context() -> Dictionary:
	var repo := OS.get_environment("PICTURE_SOURCE_REPO")
	if repo.is_empty():
		repo = ProjectSettings.globalize_path("res://").path_join("..")
	if _contexts.has(repo):
		return _contexts[repo]
	var helper := OS.get_environment("PICTURE_STAMP_TOOL")
	if helper.is_empty():
		helper = repo.path_join("tools/picture_provenance.py")
	_glyphs = JSON.parse_string(FileAccess.get_file_as_string(helper.get_base_dir().path_join("picture_font.json")))
	var python := OS.get_environment("PICTURE_PYTHON")
	if python.is_empty():
		var pc := OS.get_environment("USERPROFILE").path_join("Downloads")
		for candidate in [pc.path_join("ComfyUI_windows_portable/python_embeded/python.exe"), pc.path_join("voidsworn_test/blender/blender-4.5.14-windows-x64/4.5/python/bin/python.exe")]:
			if FileAccess.file_exists(candidate):
				python = candidate
				break
	if python.is_empty():
		python = "python" if OS.get_name() == "Windows" else "python3"
	var output: Array = []
	var code := OS.execute(python, PackedStringArray([helper, "context", "--repo", repo]), output, true)
	if code != 0 or output.is_empty():
		push_error("Picture provenance context FAILED: " + str(output))
		return {}
	var record: Variant = JSON.parse_string(str(output[0]))
	if not record is Dictionary or not record.has("source_commit"):
		return {}
	_contexts[repo] = record
	return record

static func _strip(record: Dictionary, size: Vector2i) -> Image:
	var scale := 2 if size.x >= 1000 else 1
	var width: int = size.x / scale
	var lines: Array[String] = []
	var text_lines: Array[String] = [record.picture_name]
	for source: Dictionary in record.sources:
		var rev: String = source.source_commit.left(12)
		if source.source_dirty:
			rev += " + working " + str(source.source_diff_sha256).left(8)
		var line := rev + " | " + str(source.stage)
		if line not in text_lines:
			text_lines.append(line)
	text_lines.append(str(record.stage) + " | " + str(record.date))
	var strip_width := 0
	for line in text_lines:
		while not line.is_empty():
			var count: int = maxi(1, (width - 12) / 6)
			var part := line.left(count)
			lines.append(part)
			strip_width = maxi(strip_width, part.length() * 6 + 12)
			line = line.substr(count)
	var height := lines.size() * 13 + 10
	if height * scale > size.y:
		push_error("Picture is too small for a readable provenance strip")
		return null
	var strip := Image.create(mini(width, strip_width), height, false, Image.FORMAT_RGB8)
	strip.fill(Color("#10151e"))
	strip.fill_rect(Rect2i(0, 0, strip.get_width(), 1), Color("#e8b56b"))
	for row in range(lines.size()):
		for col in range(lines[row].length()):
			var glyph: Array = _glyphs.get(lines[row][col], _glyphs["?"])
			for y in range(glyph.size()):
				for x in range(6):
					if int(glyph[y]) & (1 << (5 - x)):
						strip.set_pixel(6 + col * 6 + x, 4 + row * 13 + y, Color("#f1e8d9"))
	strip.resize(strip.get_width() * scale, height * scale, Image.INTERPOLATE_NEAREST)
	return strip

static func _save(image: Image, path: String, stage: String, jpeg: bool, quality: float) -> Error:
	var context := _context()
	if context.is_empty() or _glyphs.is_empty() or stage not in ["sheet built", "paint proof", "installed in game"]:
		return _failed(path)
	var absolute := ProjectSettings.globalize_path(path)
	var source := context.duplicate()
	source.stage = stage
	var record := context.duplicate()
	record.merge({"schema": 1, "picture_name": absolute.get_file(), "stage": stage,
		"date": Time.get_datetime_string_from_system(true) + "Z", "sources": [source], "inputs": []})
	var original := image.duplicate() as Image
	original.convert(Image.FORMAT_RGB8 if jpeg else Image.FORMAT_RGBA8)
	var strip := _strip(record, original.get_size())
	if strip == null:
		return _failed(path)
	var box := Rect2i(0, original.get_height() - strip.get_height(), strip.get_width(), strip.get_height())
	var covered := original.get_region(box).save_png_to_buffer()
	record.stamp_template_sha256 = _hash(strip.get_data())
	strip.convert(original.get_format())
	original.blit_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), box.position)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var result := original.save_jpg(absolute, quality) if jpeg else original.save_png(absolute)
	if result != OK:
		return result
	var saved := Image.load_from_file(absolute)
	saved.convert(Image.FORMAT_RGB8)
	record.merge({"stamp_box": [box.position.x, box.position.y, box.end.x, box.end.y],
		"strip_size": [strip.get_width(), strip.get_height()],
		"covered_pixels": [Marshalls.raw_to_base64(covered)],
		"strip_sha256": [_hash(saved.get_region(box).get_data())],
		"image_sha256": _hash(FileAccess.get_file_as_bytes(absolute))})
	var manifest := FileAccess.open(absolute + ".provenance.json", FileAccess.WRITE)
	if manifest == null:
		return _failed(path)
	manifest.store_string(JSON.stringify(record, "\t") + "\n")
	return OK

static func _failed(path: String) -> Error:
	push_error("Picture stamp FAILED: " + path)
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.quit(1)
	return ERR_CANT_CREATE
