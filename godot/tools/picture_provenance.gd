extends RefCounted
## One cached revision query per run. Stamping frames never launches a process.
## Python and Godot share tools/picture_font.json and the same sidecar schema.
const BUILD_INFO := "res://build_info.json"
const BUILD_FONT := "res://tools/picture_font.json"
const PLACEHOLDER_GUARD := preload("res://render/placeholder_guard.gd")
static var _contexts: Dictionary = {}
static var _glyphs: Dictionary = {}

## Issue 1567: every save names its stage (no default: a caller that forgot it used to claim "installed in game").
## "cloud direction check" is a cloud or software render, the compatibility renderer, or a scene with a placeholder hull.
const STAGES := ["sheet built", "paint proof", "installed in game", "cloud direction check", "pre-merge capture"]

static func save_png(image: Image, path: String, stage: String, footer := false) -> Error:
	return _save(image, path, stage, false, 0.9, footer)

static func save_jpg(image: Image, path: String, quality: float, stage: String) -> Error:
	return _save(image, path, stage, true, quality)

## Direction checks keep their stage. A game-quality checkout capture needs to be on main to count as installed.
static func capture_stage() -> String:
	if capture_is_direction_check():
		return "cloud direction check"
	return "pre-merge capture" if _context().get("_pre_merge", false) else "installed in game"

static func capture_is_direction_check() -> bool:
	# Headless checks and sheet tools draw nothing, so there is no renderer to classify.
	if DisplayServer.get_name() == "headless":
		return false
	if RenderingServer.get_current_rendering_method() != "forward_plus":
		return true
	var adapter := (RenderingServer.get_video_adapter_name() + " " + RenderingServer.get_video_adapter_vendor()).to_lower()
	for soft in ["llvmpipe", "lavapipe", "swiftshader", "software", "mesa offscreen"]:
		if adapter.contains(soft):
			return true
	if int(PLACEHOLDER_GUARD.count) > 0:
		return true
	return false

static func _hash(bytes: PackedByteArray) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	return hash.finish().hex_encode()

static func _context() -> Dictionary:
	var repo := ProjectSettings.globalize_path("res://").path_join("..")
	if not OS.has_feature("editor"):
		# Only an export in a checkout can use the legacy Git path without packed metadata.
		var git_marker := repo.path_join(".git")
		var in_checkout := FileAccess.file_exists(git_marker) or DirAccess.dir_exists_absolute(git_marker)
		if FileAccess.file_exists(BUILD_INFO) or not in_checkout:
			return _build_context()
	var repo_override := OS.get_environment("PICTURE_SOURCE_REPO")
	if not repo_override.is_empty():
		repo = repo_override
	if _contexts.has(repo):
		return _contexts[repo]
	var record := _checkout_context(repo)
	if record.is_empty():
		return _build_context()
	_contexts[repo] = record
	return record

static func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		return {}
	return json.data

static func _build_context() -> Dictionary:
	if _contexts.has(BUILD_INFO):
		return _contexts[BUILD_INFO]
	var info := _read_json(BUILD_INFO)
	var commit: Variant = info.get("commit")
	var date: Variant = info.get("commit_date")
	var full_commit := RegEx.create_from_string("\\A(?!0+\\z)(?:[0-9a-f]{40}|[0-9a-f]{64})\\z")
	if not commit is String or not full_commit.search(commit) or not date is String or not _is_utc_date(date):
		push_error("Picture provenance unavailable: no Git checkout context or valid " + BUILD_INFO + " with a full commit and UTC commit date")
		return {}
	var glyphs := _read_json(BUILD_FONT)
	if not glyphs.has("?"):
		push_error("Picture provenance build font missing or invalid: " + BUILD_FONT)
		return {}
	_glyphs = glyphs
	var record := {"source_commit": commit, "source_commit_date": date, "source_dirty": false, "source_diff_sha256": ""}
	_contexts[BUILD_INFO] = record
	return record

static func _is_utc_date(date: String) -> bool:
	var utc_date := RegEx.create_from_string("\\A[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\\z")
	if not utc_date.search(date):
		return false
	var seconds := Time.get_unix_time_from_datetime_string(date.trim_suffix("Z"))
	return Time.get_datetime_string_from_unix_time(seconds) + "Z" == date

static func _checkout_context(repo: String) -> Dictionary:
	var helper := OS.get_environment("PICTURE_STAMP_TOOL")
	if helper.is_empty():
		helper = repo.path_join("tools/picture_provenance.py")
	if not FileAccess.file_exists(helper):
		return {}
	var glyphs := _read_json(helper.get_base_dir().path_join("picture_font.json"))
	if not glyphs.has("?"):
		return {}
	var python := OS.get_environment("PICTURE_PYTHON")
	if python.is_empty():
		var pc := OS.get_environment("USERPROFILE").path_join("Downloads")
		for candidate in [pc.path_join("voidsworn_test/blender/blender-4.5.14-windows-x64/4.5/python/bin/python.exe")]:
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
	# A missing main ref or failed ancestry check cannot establish that this checkout is installed.
	record["_pre_merge"] = OS.execute("git", PackedStringArray([
		"-C", repo, "merge-base", "--is-ancestor", record.source_commit, "refs/remotes/origin/main"]), [], true) != 0
	_glyphs = glyphs
	return record

static func _strip(record: Dictionary, image_width: int) -> Image:
	var scale := 2 if image_width >= 1000 else 1
	var width: int = image_width / scale
	var lines: Array[String] = []
	var text_lines: Array[String] = [record.picture_name]
	for source: Dictionary in record.sources:
		var rev: String = source.source_commit.left(12)
		if source.has("source_commit_date"):
			rev = "built from " + rev
		elif source.source_dirty:
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

static func _save(image: Image, path: String, stage: String, jpeg: bool, quality: float, footer := false) -> Error:
	var context := _context()
	if context.is_empty() or _glyphs.is_empty() or stage not in STAGES:
		return _failed(path)
	var absolute := ProjectSettings.globalize_path(path)
	var record := context.duplicate()
	record.erase("_pre_merge")
	var source := record.duplicate()
	source.stage = stage
	record.merge({"schema": 1, "picture_name": absolute.get_file(), "stage": stage,
		"date": Time.get_datetime_string_from_system(true) + "Z", "sources": [source], "inputs": []})
	var original := image.duplicate() as Image
	original.convert(Image.FORMAT_RGB8 if jpeg else Image.FORMAT_RGBA8)
	var strip := _strip(record, original.get_width())
	if footer:
		var cell_height := original.get_height()
		original.crop(original.get_width(), cell_height + strip.get_height())
		original.fill_rect(Rect2i(0, cell_height, original.get_width(), strip.get_height()), Color("#10151e"))
	elif strip.get_height() > original.get_height():
		push_error("Picture is too small for a readable provenance strip")
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
