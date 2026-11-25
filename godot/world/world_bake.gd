extends Node
# A shared queue survives title, map and battle changes. The worker owns its
# local RenderingDevice, compilation, GPU waits, readback, mipmaps and disk I/O.
# Scene nodes and texture uploads stay on the main thread, behind loading.

const CACHE_MAX := 24
const CACHE_DIR := "user://world_bakes/v3"
# R79: the sector map primes the same 4K surface the backdrop planet uses.
# Size and shader source are part of cache_key, so older bakes cannot be reused.
const PLANET_SIZE := Vector2i(4096, 2048)
# Issue 1765: moons bake at 2K so craters and rays stay crisp when a moon sits large in the frame.
const MOON_SIZE := Vector2i(2048, 1024)
# Issue 1265: the disk cache on C: is capped. A sector bakes about three 4096 by 2048 maps (sky, planet a and b) plus
# moons, so 500 MB holds the last several sectors (Neon audit P6). After a bake is saved, least recently used maps go
# first; maps the running battle holds never go; a stray .tmp older than a day goes. Only rebuildable bakes are removed.
const CACHE_CAP_BYTES := 500 * 1024 * 1024
const TMP_MAX_AGE := 86400
# Last use per key. Windows often leaves file access times frozen, so the game keeps its own stamps.
const USED_INDEX := "used.json"
static var _cache := {}
static var _textures := {}
# Tickets, pins and the image/texture cache belong to the main thread.
var _jobs := {}
var _thread: Thread
var _exiting := false
# Only these fields cross the thread boundary. Job payloads and completed maps
# are passed by ownership, never edited by both threads.
var _mutex := Mutex.new()
var _wake := Semaphore.new()
var _sleeping := true
var _stopping := false
var _queue: Array[Dictionary] = []
var _finished: Array[Dictionary] = []
var _active := ""
var _canvas_key := ""
var _canvas_work: Dictionary = {}
var _unsaved: Array[Dictionary] = []
var _save_ready := false
var _held_keys := {}
# The worker owns every GPU object, including destruction before it exits.
var _rd: RenderingDevice
var _pipelines := {}

# Issue 1434: encoding and pruning must wait until the loading cover lifts.
# work_stage (0 idle, 1 read, 2 compute, 3 save, 4 prune, 5 mips) is for the load bench.
static var work_stage := 0
var written := 0
var write_failed := 0
const SAVE_JOB := "#save"
const BOARD_SUFFIX := ".bake"
const BOARD_FORMATS := [Image.FORMAT_RGBA8, Image.FORMAT_RGBA8, Image.FORMAT_RF]

# Issue 1765: a battle opened as the main scene builds its world and board inside its own _ready, while the root is
# still adding children; add_child is refused there ("Parent node is busy") and every bake request then failed on a
# service that never joined the tree. The service now joins with a deferred add, and its calls wait on the tree it
# was made for until it is in.
static var _pending: Node = null
static var _pending_tree: SceneTree = null
# Neon (PR 1776 review, item 2): keys asked for with request_* and not yet collected with result(). The cache never
# evicts them, so a map that finished first can never push out a later map of the same set before its caller reads it.
static var _pins := {}

static func service(tree: SceneTree) -> Node:
	var node := _find_service(tree)
	if node == null:
		node = load("res://world/world_bake.gd").new()
		node.name = "WorldBakes"
		_pending = node
		_pending_tree = tree
		# Neon (PR 1776 review, item 3): the add runs through _attach, which skips a service clear_static already freed;
		# a freed node handed straight to add_child corrupted the heap on Windows
		Callable(node.get_script(), "_attach").call_deferred(node)
	return node

static func _attach(node) -> void:
	if not is_instance_valid(node) or node.is_inside_tree(): return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root.get_node_or_null("WorldBakes") != null: return
	tree.root.add_child(node)

static func _find_service(tree: SceneTree) -> Node:
	if tree == null or tree.root == null: return null
	var node := tree.root.get_node_or_null("WorldBakes")
	if node == null and is_instance_valid(_pending) and _pending_tree == tree: return _pending
	return node

# Keep the active job (including one waiting for its canvas). Cancel only jobs
# the worker has not taken, and release their pins so callers can request them again.
static func drop_waiting(tree: SceneTree) -> int:
	var node := _find_service(tree)
	return node._drop_queue() if node != null else 0


func _drop_queue() -> int:
	_mutex.lock()
	var dropped := _queue
	_queue = []
	_mutex.unlock()
	for work in dropped:
		_jobs[work.key]["cancelled"] = true
		_jobs[work.key].done = true
		_jobs.erase(work.key)
		_pins.erase(work.key)
	_refresh_worker()
	_trim(CACHE_MAX)
	return dropped.size()

func _tree() -> SceneTree:
	return get_tree() if is_inside_tree() else _pending_tree

func _owner() -> Node:
	var tree := _tree()
	return service(tree) if tree != null else self

static func cache_key(key: String, code: String, params: Dictionary, size: Vector2i) -> String:
	var ordered := {}
	var keys := params.keys()
	keys.sort()
	for name in keys: ordered[name] = params[name]
	return var_to_str([key, code, ordered, size]).sha256_text()

static func cached(key: String) -> Image:
	# Disk hits also use the worker, never PNG decode on the caller's thread.
	return _cache.get(key) as Image

static func texture(img: Image) -> Texture2D:
	var id := img.get_instance_id()
	if not _textures.has(id): _textures[id] = ImageTexture.create_from_image(img)
	return _textures[id]

static func remember(key: String, maps: Variant) -> void:
	if _cache.has(key): return
	_trim(CACHE_MAX - (maps.size() if maps is Array else 1))
	_cache[key] = maps

# The limit counts images. A board entry occupies three slots and is evicted as
# a set. If every key is pinned, let the cache run over until a waiter collects.
static func _trim(cap: int) -> void:
	var count := 0
	for maps in _cache.values():
		count += maps.size() if maps is Array else 1
	for oldest in _cache.keys():
		if count <= cap: return
		if _pins.has(oldest): continue
		var maps: Variant = _cache[oldest]
		for img in (maps if maps is Array else [maps]):
			_textures.erase(img.get_instance_id())
			count -= 1
		_cache.erase(oldest)

static func _pin(key: String) -> void:
	_pins[key] = int(_pins.get(key, 0)) + 1
	if _cache.has(key):
		# a hit counts as a fresh use: it moves to the young end of the eviction order
		var maps: Variant = _cache[key]
		_cache.erase(key)
		_cache[key] = maps

static func _unpin(key: String) -> void:
	var n := int(_pins.get(key, 0)) - 1
	if n > 0: _pins[key] = n
	else:
		_pins.erase(key)
		_trim(CACHE_MAX)

static func clear_static() -> void:
	# Stop even if the service has not attached. Its deferred add will skip the freed node.
	_stop_worker()
	_old_swept = false
	_textures.clear()
	_cache.clear()
	_pins.clear()
	if is_instance_valid(_pending) and not _pending.is_inside_tree(): _pending.free()
	_pending = null
	_pending_tree = null


static func _stop_worker() -> void:
	var node := _find_service(Engine.get_main_loop() as SceneTree)
	if node == null and is_instance_valid(_pending): node = _pending
	if node != null: node._join_worker()


func _join_worker() -> void:
	if _thread != null:
		_mutex.lock()
		_stopping = true
		_wake_locked()
		_mutex.unlock()
		_thread.wait_to_finish()
		_thread = null
	for key in _jobs:
		_jobs[key]["cancelled"] = true
		_jobs[key].done = true
		_pins.erase(key)
	_jobs.clear()
	# No worker is using these now. Reset them so an attached service can be used after clear_static.
	_queue.clear()
	_finished.clear()
	_unsaved.clear()
	_held_keys.clear()
	_canvas_work.clear()
	_canvas_key = ""
	_active = ""
	_stopping = false
	_save_ready = false
	_sleeping = true
	_wake = Semaphore.new()
	work_stage = 0

# Authored R01 maps use the same shared worker and texture cache as the GPU
# bakes. Decode and mip generation never block the battle's main thread.
func authored(path: String, size: Vector2i, float_mips := false, urgent := false) -> Image:
	return await result(request_authored(path, size, float_mips, urgent))

# Queues an authored map without waiting; returns its key for result(). A caller with several maps requests them all
# first, so nothing else can slip in between them (Artoo, PR 1776).
static func authored_key(path: String, size: Vector2i, float_mips := false) -> String:
	return (path + "|" + str(FileAccess.get_modified_time(path)) + "|" + str(size) + "|" + str(float_mips)).sha256_text()

# Issue 1434 (Artoo on 002e143f): whether an authored map's texture is still made and held, asked without starting a
# request or a pin (a trim drops the image and its texture together).
static func authored_texture_resident(path: String, size: Vector2i, float_mips := false) -> bool:
	var img = _cache.get(authored_key(path, size, float_mips))
	return img is Image and _textures.has((img as Image).get_instance_id())

func request_authored(path: String, size: Vector2i, float_mips := false, urgent := false) -> String:
	var key := authored_key(path, size, float_mips)
	_owner()._request(key, {"path": path, "size": size, "float_mips": float_mips}, urgent)
	return key


func result(key: String) -> Image:
	return await _owner()._result(key) as Image


func board_maps(key: String, code: String, params: Dictionary, size: Vector2i) -> Array:
	key = board_key(key, code, params, size)
	var owner := _owner()
	owner._request(key, _bake_job(code, params, size, true), true)
	var maps: Variant = await owner._result(key)
	return maps if maps is Array else []


static func board_key(key: String, code: String, params: Dictionary, size: Vector2i) -> String:
	return cache_key(key + "|board_rf1", code + BOARD_OUTPUTS, params, size)


# Read the value before releasing the pin. A trim can evict the just-collected
# map when every other key is still pinned (Artoo, PR 1776).
func _result(key: String) -> Variant:
	if _cache.has(key):
		var hit: Variant = _cache[key]
		_unpin(key)
		return hit
	var tree := _tree()
	if tree == null or _exiting:
		_unpin(key)
		return null
	var job: Variant = _jobs.get(key)
	if job == null:
		_unpin(key)
		return null
	while not job.done:
		await tree.process_frame
	# A dropped ticket's pins were already released. Do not unpin a fresh request for that key.
	if not job.get("cancelled", false): _unpin(key)
	return job.maps


func _request(key: String, work: Dictionary, urgent: bool) -> void:
	if _exiting: return
	_pin(key)
	if _cache.has(key): return
	work["key"] = key
	work["started"] = Time.get_ticks_msec()
	_enqueue(work, urgent)


# The first enqueue starts the worker even before the service's deferred add.
# Urgent requests keep their own order and jump only jobs that have not started.
func _enqueue(work: Dictionary, urgent: bool) -> void:
	var key: String = work.key
	var loading := _loading()
	_mutex.lock()
	if loading: _save_ready = false
	var at := _queue.find_custom(func(pending: Dictionary) -> bool: return pending.key == key)
	if not _jobs.has(key):
		_jobs[key] = {"done": false, "maps": null}
		_insert_work(work, urgent)
	elif at >= 0 and urgent and not _queue[at].urgent:
		_insert_work(_queue.pop_at(at), true)
	# A job in flight (or awaiting hand-back) is never queued again.
	_held_keys[key] = true
	if _thread == null:
		_thread = Thread.new()
		var err := _thread.start(_worker_loop)
		if err != OK:
			_thread = null
			_queue.clear()
			_jobs[key].done = true
			_jobs.erase(key)
			push_error("Could not start world bake worker: %s" % err)
	_wake_locked()
	_mutex.unlock()


func _insert_work(work: Dictionary, urgent: bool) -> void:
	work["urgent"] = urgent
	if not urgent:
		_queue.append(work)
		return
	var at := 0
	while at < _queue.size() and _queue[at].urgent: at += 1
	_queue.insert(at, work)


func _wake_locked() -> void:
	if _sleeping:
		_sleeping = false
		_wake.post()


func bake(key: String, code: String, params: Dictionary, size: Vector2i, strips: int, half_mips := false, urgent := false) -> Image:
	return await result(request_bake(key, code, params, size, strips, half_mips, urgent))


func request_bake(key: String, code: String, params: Dictionary, size: Vector2i, _strips: int, half_mips := false, urgent := false) -> String:
	key = cache_key(key, code, params, size)
	var work := _bake_job(code, params, size, false)
	work["half_mips"] = half_mips
	_owner()._request(key, work, urgent)
	return key


func _bake_job(code: String, params: Dictionary, size: Vector2i, board: bool) -> Dictionary:
	var visible := DisplayServer.get_name() != "headless"
	var compute := visible and RenderingServer.get_current_rendering_method() != "gl_compatibility"
	return {"code": code, "params": params.duplicate(true), "size": size, "board": board,
		"folder": _folder(), "compute": compute, "canvas": visible and not compute}

# issue 1434 (LOAD17): the bakes handed back to the main thread since main.gd last read it (12-character keys)
static var handed_back := ""


static func take_handed_back() -> String:
	var s := handed_back
	handed_back = ""
	return s


func _loading() -> bool:
	var t := _tree()   # issue 1765: a service still waiting on its deferred add has no get_tree()
	return t != null and t.has_group(&"battle_loading")

func _process(_dt: float) -> void:
	_refresh_worker()
	_mutex.lock()
	var finished := _finished
	_finished = []
	_mutex.unlock()
	for reply in finished:
		var work: Dictionary = reply.work
		var key: String = work.key
		var value: Dictionary = reply.value
		if key == SAVE_JOB:
			if value.ok: written += 1
			else: write_failed += 1
			print("[world] %s %s later (stages ms %s)" % ["saved" if value.ok else "could not save", work.save.key, value.stages])
			continue
		var job: Dictionary = _jobs[key]
		if value.get("canvas", false):
			_raster(work, job)
			continue
		job.maps = value.get("maps")
		job.done = true
		if job.maps != null:
			remember(key, job.maps)
			handed_back = (handed_back + " " if handed_back != "" else "") + key.left(12)
			var now := Time.get_ticks_msec()
			print("[world] %s %s %dx%d in %d ms (worker; stages ms %s; queued at %d, worker from %d, handed back at %d ms)" % [
				value.source, key, work.size.x, work.size.y, now - work.started, value.get("stages", {}), work.started, work.worker_from, now])
		elif value.get("error", "") != "":
			push_error("World bake: " + value.error)
		_jobs.erase(key)


func _refresh_worker() -> void:
	var loading := _loading()
	_mutex.lock()
	# Main authorizes only one low-priority write at a time, based on the live loading group.
	_save_ready = not loading and not _unsaved.is_empty()
	if _save_ready and _canvas_key == "":
		var keep := {}
		for key in _cache: keep[key] = true
		for key in _jobs: keep[key] = true
		_held_keys = keep
		_wake_locked()
	_mutex.unlock()


func _exit_tree() -> void:
	_exiting = true
	if name == &"WorldBakes":
		_join_worker()
		clear_static()


func _worker_loop() -> void:
	# The worker touches only its own data, the locked mailbox, and the rendering
	# server's local device. All scene tree work (including the canvas) stays on main.
	while true:
		_wake.wait()
		while true:
			_mutex.lock()
			if _stopping:
				_mutex.unlock()
				_free_device()
				return
			var work: Dictionary
			var keep: Dictionary
			if _canvas_key != "":
				work = _canvas_work
				_canvas_work = {}
			elif not _queue.is_empty():
				work = _queue.pop_front()
				work["worker_from"] = Time.get_ticks_msec()
			elif _save_ready:
				work = {"key": SAVE_JOB, "save": _unsaved.pop_front()}
				keep = _held_keys.duplicate()
				_save_ready = false
			if work.is_empty():
				_sleeping = true
				_mutex.unlock()
				break
			_active = work.key
			_mutex.unlock()
			var value: Dictionary
			if work.key == SAVE_JOB:
				var save: Dictionary = work.save
				var stages := {}
				value = {"ok": _save(save.key, save.maps, keep, stages, save.folder), "stages": stages}
			else:
				value = _work(work)
			work_stage = 0
			_mutex.lock()
			if value.has("save"):
				_unsaved.append({"key": work.key, "maps": value.save, "folder": work.folder})
				value.erase("save")
				value.stages["save"] = "deferred"
			_finished.append({"work": work, "value": value, "thread_id": OS.get_thread_caller_id()})
			_canvas_key = work.key if value.get("canvas", false) else ""
			if _canvas_key == "": _active = ""
			_mutex.unlock()


func _should_stop() -> bool:
	_mutex.lock()
	var stopping := _stopping
	_mutex.unlock()
	return stopping


func _raster(work: Dictionary, job: Dictionary) -> void:
	var params: Dictionary = work.params.duplicate()
	var images: Array[Image] = []
	for pass_id in (3 if work.board else 1):
		if work.board: params["pass_id"] = pass_id
		var img := await _canvas(work.code, params, work.size, job)
		if job.done or _exiting: return
		if img == null: break
		images.append(img)
	if work.board:
		work["raster_maps"] = images if images.size() == 3 else null
	else:
		work["raster_maps"] = images.front() if not images.is_empty() else null
	_mutex.lock()
	_canvas_work = work
	_wake_locked()
	_mutex.unlock()


static func _folder() -> String:
	return OS.get_environment("VS_WORLD_CACHE") if OS.has_environment("VS_WORLD_CACHE") else CACHE_DIR

func _work(work: Dictionary) -> Dictionary:
	if work.has("path"):
		work_stage = 1
		var img: Image
		if str(work.path).ends_with(".json"):
			img = _authored_tiles(work.path, work.size)
		else:
			img = Image.load_from_file(work.path)
		if img == null or img.get_size() != work.size:
			return {"error": "Missing or wrong-size R01 map: " + str(work.path)}
		work_stage = 5
		# Preserve both packed height bytes through filtering and mips.
		if work.float_mips: img.convert(Image.FORMAT_RGBAF)
		img.generate_mipmaps()
		return {"maps": img, "source": "authored"}
	if work.has("raster_maps"):
		var maps: Variant = work.raster_maps
		if maps != null and work.board: maps[2] = height_float(maps[2])
		return _mip_result(maps, "baked", {}, work.get("half_mips", false))
	# Capture the folder at enqueue, so later VS_WORLD_CACHE changes cannot move a deferred write.
	work_stage = 1
	var path: String = work.folder.path_join(work.key + (BOARD_SUFFIX if work.board else ".png"))
	var loaded: Variant
	if FileAccess.file_exists(path):
		loaded = _load_board(path, work.size) if work.board else _load_png(path, work.size)
	if loaded != null:
		touch(work.folder, work.key)
		return _mip_result(loaded, "loaded", {}, work.get("half_mips", false))
	if work.compute:
		work_stage = 2
		var output := _compute(work.code, work.params, work.size, work.board)
		if not output.has("maps"): return output
		return _mip_result(output.maps, "baked", output.stages, work.get("half_mips", false))
	return {"canvas": work.canvas}


static func _mip_result(maps: Variant, source: String, stages: Dictionary, half_mips: bool) -> Dictionary:
	if maps == null: return {}
	work_stage = 5
	var t := Time.get_ticks_usec()
	var result := {"maps": maps, "source": source, "stages": stages}
	if source == "baked":
		# PNG encodes the base level. Only the legacy packed-height map needs an unconverted copy.
		result["save"] = maps.duplicate() if half_mips else maps
	if half_mips:
		maps = height_float(maps)
		result.maps = maps
	for img in (maps if maps is Array else [maps]):
		if not img.has_mipmaps(): img.generate_mipmaps()
	stages["mips"] = (Time.get_ticks_usec() - t) / 1000
	return result


static func _load_png(path: String, size: Vector2i) -> Image:
	var img := Image.load_from_file(path)
	return img if img != null and not img.is_empty() and img.get_size() == size else null


# One atomic board entry, with three native image buffers including their mips.
# A warm battle reads them directly: no PNG decode, pixel conversion or mip build.
static func _load_board(path: String, size: Vector2i) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return null
	var bytes := _board_map_bytes(size)
	if f.get_length() != bytes * BOARD_FORMATS.size(): return null
	var maps: Array[Image] = []
	for format in BOARD_FORMATS:
		var data := f.get_buffer(bytes)
		if data.size() != bytes: return null
		maps.append(Image.create_from_data(size.x, size.y, true, format, data))
	return maps


static func _board_map_bytes(size: Vector2i) -> int:
	var bytes := 0
	while size != Vector2i.ONE:
		bytes += 4 * size.x * size.y
		size = (size / 2).max(Vector2i.ONE)
	return bytes + 4


static func _save(key: String, maps: Variant, keep: Dictionary, stages: Dictionary, folder: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(folder) != OK: return false
	var path := folder.path_join(key + (BOARD_SUFFIX if maps is Array else ".png"))
	work_stage = 3
	var t := Time.get_ticks_usec()
	stages["save_began"] = Time.get_ticks_msec()
	var tmp := path + ".tmp"
	var stored: bool = _store_board(tmp, maps) if maps is Array else maps.save_png(tmp) == OK
	var ok := stored and DirAccess.rename_absolute(tmp, path) == OK
	stages["save"] = (Time.get_ticks_usec() - t) / 1000
	if ok:
		work_stage = 4
		t = Time.get_ticks_usec()
		prune(folder, CACHE_CAP_BYTES, keep, key)
		stages["prune"] = (Time.get_ticks_usec() - t) / 1000
	work_stage = 0
	return ok


static func _store_board(path: String, maps: Array) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null: return false
	for img: Image in maps:
		if not f.store_buffer(img.get_data()): return false
	f.close()
	return true


# Issue 1765: a 16-bit height packed big-endian in R and G, as one 32-bit float channel (0 to 1). Worker thread only.
# Neon (PR 1776 review, item 6): this runs on the worker for every cold and warm load of a baked look, about 1.6 s per
# 4K map on the PC. The image is cut to its two height bytes (RG8, in native code), each pixel is read as one 16-bit
# word and looked up in a 64K table of the exact heights: about half the time of the per-byte loop, same values.
static var _height_lut := PackedFloat32Array()

static func height_float(img: Image) -> Image:
	if _height_lut.is_empty():
		var lut := PackedFloat32Array()
		lut.resize(65536)
		for v in 65536: lut[v] = float((v & 255) * 256 + (v >> 8)) / 65535.0   # the word reads low byte first: R is v & 255
		_height_lut = lut
	if img.get_format() != Image.FORMAT_RG8: img.convert(Image.FORMAT_RG8)
	var src := img.get_data()
	var n := img.get_width() * img.get_height()
	var out := PackedFloat32Array()
	out.resize(n)
	var lut := _height_lut
	for i in n:
		out[i] = lut[src.decode_u16(i * 2)]
	return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RF, out.to_byte_array())


static func _authored_tiles(path: String, size: Vector2i) -> Image:
	var desc = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not desc is Dictionary: return null
	var stored_size: Array = desc.get("size", [])
	if stored_size.size() != 2 or Vector2i(int(stored_size[0]), int(stored_size[1])) != size: return null
	var tiles: Array = desc.get("tiles", [])
	if tiles.size() != 16: return null
	var image := Image.create(size.x, size.y, false, int(desc.get("format", -1)))
	var positions := {}
	for entry in tiles:
		var pos := Vector2i(int(entry.x), int(entry.y))
		var tile_size := size / 4
		if pos.x < 0 or pos.y < 0 or pos.x % tile_size.x or pos.y % tile_size.y or pos.x >= size.x or pos.y >= size.y or positions.has(pos): return null
		positions[pos] = true
		var resource := ResourceLoader.load(path.get_base_dir().path_join(str(entry.file)), "Resource", ResourceLoader.CACHE_MODE_IGNORE)
		if resource == null: return null
		var tile: Image = null
		if desc.get("encoding", "") == "webp_resource_v1":
			tile = Image.new()
			if tile.load_webp_from_buffer(resource.get_meta("webp", PackedByteArray())) != OK: return null
			tile.convert(image.get_format())
		else:
			tile = resource as Image
		if tile == null or tile.get_size() != tile_size or tile.get_format() != image.get_format(): return null
		image.blit_rect(tile, Rect2i(Vector2i.ZERO, tile_size), pos)
	return image

# Issue 1265. The index maps a cache key to the unix time a battle last loaded or saved it. A missing stamp (older
# bakes, a lost write) falls back to the newer of the file's modified and access times. Runs on the bake worker only.
static func _read_used(folder: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(folder.path_join(USED_INDEX))
	var parsed = JSON.parse_string(text) if text != "" else null
	return parsed if parsed is Dictionary else {}

static func _write_used(folder: String, used: Dictionary) -> void:
	var path := folder.path_join(USED_INDEX)
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null: return
	f.store_string(JSON.stringify(used))
	f.close()
	DirAccess.rename_absolute(path + ".tmp", path)

static func touch(folder: String, key: String, now: float = -1.0) -> void:
	var used := _read_used(folder)
	used[key] = Time.get_unix_time_from_system() if now < 0.0 else now
	_write_used(folder, used)

# Removes stale .tmp files, then least recently used maps until the folder is under cap. Only names the game writes
# (<64 hex>.png, its .tmp, used.json's .tmp) are ever removed. `keep` (keys the running game holds) and `fresh` (the
# map just saved) are never removed. Returns what it did, for logs and the check.
static func prune(folder: String, cap: int, keep: Dictionary, fresh: String, now: float = -1.0) -> Dictionary:
	if now < 0.0: now = Time.get_unix_time_from_system()
	var used := _read_used(folder)
	if fresh != "": used[fresh] = now
	var maps: Array = []
	var total := 0
	var removed: Array = []
	for name in DirAccess.get_files_at(folder):
		if not _bake_name(name): continue   # only names the game writes, never a stranger's file
		var path := folder.path_join(name)
		if name.ends_with(".tmp"):
			if now - FileAccess.get_modified_time(path) > TMP_MAX_AGE and DirAccess.remove_absolute(path) == OK:
				removed.append(name)
			continue
		if not (name.ends_with(".png") or name.ends_with(BOARD_SUFFIX)): continue
		var key := name.get_basename()
		var size := FileAccess.get_size(path)
		var stamp: float = float(used.get(key, maxi(FileAccess.get_modified_time(path), FileAccess.get_access_time(path))))
		maps.append({"key": key, "path": path, "size": size, "stamp": stamp})
		total += size
	var before := total
	if total > cap:
		maps.sort_custom(func(a, b): return a.stamp < b.stamp)
		for m in maps:
			if total <= cap: break
			if keep.has(m.key) or m.key == fresh: continue
			if DirAccess.remove_absolute(m.path) == OK:
				total -= int(m.size)
				removed.append(m.path.get_file())
	removed.append_array(_sweep_old_versions(folder, folder == CACHE_DIR))
	var live := {}
	for m in maps:
		if FileAccess.file_exists(m.path) and used.has(m.key): live[m.key] = used[m.key]
	_write_used(folder, live)
	if not removed.is_empty():
		print("[world] bake cache %d -> %d MB (cap %d MB), removed %d files" % [before >> 20, total >> 20, cap >> 20, removed.size()])
	return {"before": before, "after": total, "removed": removed}

# Issue 1265 (Board, Nov 20: the PC held 0.15 GB of v2 never read again): bake folders of older cache versions under
# the game's own cache root (user://world_bakes/v1 .. v<N-1>) are cleared once per run. Never for a VS_WORLD_CACHE
# override (Artoo on PR 1295: its neighbours are not the game's). Only names the game writes go: <64 hex>.png, that
# plus .tmp, and used.json; then the folder if it is empty. Anything else stays.
static var _old_swept := false

static func _bake_name(f: String) -> bool:
	if f == USED_INDEX or f == USED_INDEX + ".tmp": return true
	var name := f.trim_suffix(".tmp")
	if not (name.ends_with(".png") or name.ends_with(BOARD_SUFFIX)): return false
	var key := name.get_basename()
	if key.length() != 64: return false
	for c in key:
		if not c in "0123456789abcdef": return false
	return true

static func _sweep_old_versions(folder: String, owned: bool) -> Array:
	var removed: Array = []
	var name := folder.get_file()
	if not owned or _old_swept or not name.begins_with("v") or not name.substr(1).is_valid_int(): return removed
	_old_swept = true
	var parent := folder.get_base_dir()
	for n in range(1, int(name.substr(1))):
		var old := parent.path_join("v%d" % n)
		if not DirAccess.dir_exists_absolute(old): continue
		for f in DirAccess.get_files_at(old):
			if n < 3 and f.trim_suffix(".tmp").ends_with(BOARD_SUFFIX): continue   # those versions only wrote PNG
			if _bake_name(f) and DirAccess.remove_absolute(old.path_join(f)) == OK: removed.append("v%d/%s" % [n, f])
		if DirAccess.get_files_at(old).is_empty() and DirAccess.get_directories_at(old).is_empty():
			DirAccess.remove_absolute(old)
	return removed

# Swap only the legacy pass selector, leaving the recipe and its raster shader
# unchanged. Keep the previous height quantization, but write the value directly.
const PASS_SELECTOR := "\n\tvec4 o;\n\tif (pass_id == 2)"
const BOARD_OUTPUTS := """
	float dither = (hh(vec3(px, seed)) - 0.5) / 255.0;
	vec4 a = vec4(clamp(alb, 0.0, 1.0), ocean);
	vec4 b = vec4(cloud, lights, clamp(relief, 0.0, 1.0), lava);
	a.rgb += dither;
	b.rgb += dither;
	float h = floor(clamp(relief, 0.0, 1.0) * 65535.0 + 0.5) / 65535.0;
	imageStore(out_a, pixel, a);
	imageStore(out_b, pixel, b);
	imageStore(out_h, pixel, vec4(h, 0.0, 0.0, 1.0));
}
"""

# Reuse the canvas shader's GLSL-compatible math with a storage buffer for its uniforms.
static func _compute_source(code: String, params: Dictionary, size: Vector2i, board := false) -> Dictionary:
	if board:
		var at := code.rfind(PASS_SELECTOR)
		if at == -1: return {"error": "Board bake: missing pass selector"}
		code = code.left(at) + BOARD_OUTPUTS
	code = code.replace("shader_type canvas_item;", "").replace("render_mode unshaded, blend_disabled;", "")
	var rx := RegEx.new()
	rx.compile("(?m)^uniform (float|int|vec2|vec3|vec4) (\\w+)(?:\\[(\\d+)\\])?[^;]*;")
	var values := PackedFloat32Array()
	var defines := ""
	var arrays := {}
	var uniforms := params.duplicate(true)
	uniforms.merge({"full_size": Vector2(size), "strip_y0": 0.0, "strip_h": float(size.y)}, true)
	for match_ in rx.search_all(code):
		var type := match_.get_string(1)
		var name := match_.get_string(2)
		var count := maxi(1, int(match_.get_string(3)))
		var offset := values.size() / 4
		if not uniforms.has(name): return {"error": "Missing bake uniform " + name}
		var value = uniforms[name]
		if match_.get_string(3) != "":
			arrays[name] = offset
		else:
			var expr := "bake_data.values[%d]" % offset
			match type:
				"float": expr += ".x"
				"int": expr = "int(" + expr + ".x)"
				"vec2": expr += ".xy"
				"vec3": expr += ".xyz"
			defines += "#define %s (%s)\n" % [name, expr]
		for i in count:
			var v = value[i] if match_.get_string(3) != "" else value
			match type:
				"float", "int": values.append_array([float(v), 0.0, 0.0, 0.0])
				"vec2": values.append_array([v.x, v.y, 0.0, 0.0])
				"vec3": values.append_array([v.x, v.y, v.z, 0.0])
				"vec4": values.append_array([v.x, v.y, v.z, v.w])
	code = rx.sub(code, "", true)
	for name in arrays:
		rx.compile(name + "\\[([^\\]]+)\\]")
		code = rx.sub(code, "bake_data.values[%d + ($1)]" % arrays[name], true)
	code = code.replace("void fragment()", "void bake_pixel()")
	var header := "#version 450\nlayout(local_size_x=8, local_size_y=8, local_size_z=1) in;\n"
	if board:
		header += "layout(set=0,binding=0,rgba8) uniform writeonly image2D out_a;\n"
		header += "layout(set=0,binding=2,rgba8) uniform writeonly image2D out_b;\n"
		header += "layout(set=0,binding=3,r32f) uniform writeonly image2D out_h;\n"
	else:
		header += "layout(set=0,binding=0,rgba8) uniform writeonly image2D output_image;\n"
	header += "layout(set=0,binding=1,std430) readonly buffer BakeData { vec4 values[]; } bake_data;\n"
	header += "layout(push_constant,std430) uniform Tile { int y; } tile;\nvec2 UV; vec4 COLOR;\n"
	if board: header += "ivec2 pixel;\n"
	var entry := "\nvoid main() { ivec2 p=ivec2(gl_GlobalInvocationID.xy)+ivec2(0,tile.y); if(any(greaterThanEqual(p,ivec2(full_size)))) return; UV=(vec2(p)+0.5)/full_size; "
	entry += "pixel=p; bake_pixel(); }\n" if board else "bake_pixel(); imageStore(output_image,p,COLOR); }\n"
	return {"code": header + defines + code + entry, "data": values.to_byte_array()}


func _compute(code: String, params: Dictionary, size: Vector2i, board: bool) -> Dictionary:
	var source := _compute_source(code, params, size, board)
	if source.has("error"): return source
	var stages := {"began": Time.get_ticks_msec()}
	var t := Time.get_ticks_usec()
	if _rd == null:
		_rd = RenderingServer.create_local_rendering_device()
		stages["device"] = (Time.get_ticks_usec() - t) / 1000
		if _rd == null: return {"error": "Local RenderingDevice is unavailable"}
	var compiled := _pipeline(source.code, stages)
	if compiled.has("error"): return compiled
	if _should_stop(): return {}

	var formats := [RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM]
	if board: formats.append_array([RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM, RenderingDevice.DATA_FORMAT_R32_SFLOAT])
	var usage := RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	for format in formats:
		if not _rd.texture_is_format_supported_for_usage(format, usage):
			return {"error": "Unsupported world bake texture format: %d" % format}
	var outputs: Array[RID] = []
	var bindings: Array[RDUniform] = []
	for i in formats.size():
		var format := RDTextureFormat.new()
		format.width = size.x
		format.height = size.y
		format.format = formats[i]
		format.usage_bits = usage
		var output := _rd.texture_create(format, RDTextureView.new())
		if not output.is_valid():
			_free_bake_rids(RID(), RID(), outputs)
			return {"error": "Could not allocate world bake output"}
		outputs.append(output)
		bindings.append(_binding(RenderingDevice.UNIFORM_TYPE_IMAGE, [0, 2, 3][i], output))
	var buffer := _rd.storage_buffer_create(source.data.size(), source.data)
	if not buffer.is_valid():
		_free_bake_rids(RID(), buffer, outputs)
		return {"error": "Could not allocate world bake uniforms"}
	bindings.append(_binding(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 1, buffer))
	var uniforms := _rd.uniform_set_create(bindings, compiled.shader, 0)
	if not uniforms.is_valid():
		_free_bake_rids(uniforms, buffer, outputs)
		return {"error": "Could not bind world bake pipeline"}
	var completed := _dispatch_strips(compiled.pipeline, uniforms, size, stages)
	if not completed:
		_free_bake_rids(uniforms, buffer, outputs)
		return {}

	t = Time.get_ticks_usec()
	var maps: Array[Image] = []
	for i in outputs.size():
		var bytes := _rd.texture_get_data(outputs[i], 0)
		if bytes.size() != size.x * size.y * 4: break
		maps.append(Image.create_from_data(size.x, size.y, false, BOARD_FORMATS[i], bytes))
	_free_bake_rids(uniforms, buffer, outputs)
	stages["readback"] = (Time.get_ticks_usec() - t) / 1000
	if maps.size() != formats.size(): return {"error": "Incomplete bake readback"}
	return {"maps": maps if board else maps.front(), "stages": stages}


func _pipeline(code: String, stages: Dictionary) -> Dictionary:
	if _pipelines.has(code): return _pipelines[code]
	var t := Time.get_ticks_usec()
	var src := RDShaderSource.new()
	src.source_compute = code
	var spirv := _rd.shader_compile_spirv_from_source(src)
	var error := spirv.get_stage_compile_error(RenderingDevice.SHADER_STAGE_COMPUTE)
	if error != "": return {"error": error}
	stages["spirv"] = (Time.get_ticks_usec() - t) / 1000
	t = Time.get_ticks_usec()
	var shader := _rd.shader_create_from_spirv(spirv)
	if not shader.is_valid(): return {"error": "Could not create world bake shader"}
	var pipeline := _rd.compute_pipeline_create(shader)
	if not pipeline.is_valid():
		_rd.free_rid(shader)
		return {"error": "Could not create world bake pipeline"}
	stages["pipeline"] = (Time.get_ticks_usec() - t) / 1000
	_pipelines[code] = {"shader": shader, "pipeline": pipeline}
	return _pipelines[code]


static func _binding(type: RenderingDevice.UniformType, at: int, rid: RID) -> RDUniform:
	var uniform := RDUniform.new()
	uniform.uniform_type = type
	uniform.binding = at
	uniform.add_id(rid)
	return uniform


func _dispatch_strips(pipeline: RID, uniforms: RID, size: Vector2i, stages: Dictionary) -> bool:
	# A short first strip gauges the card for this shader. Cap subsequent strips
	# at 256 rows and aim well below the Windows GPU watchdog on slower cards.
	var limit := mini(256, _rd.limit_get(RenderingDevice.LIMIT_MAX_COMPUTE_WORKGROUP_COUNT_Y) * 8)
	var rows := mini(limit, 256 if size.x <= 256 else 32)
	var worst := 0
	var count := 0
	var y := 0
	var began := Time.get_ticks_usec()
	while y < size.y:
		if _should_stop(): return false
		var elapsed := _dispatch_strip(pipeline, uniforms, y, Vector2i(size.x, mini(rows, size.y - y)))
		worst = maxi(worst, elapsed)
		count += 1
		y += rows
		rows = clampi(floori(rows * 100000.0 / elapsed / 8.0) * 8, 8, limit)
	stages["strips"] = count
	stages["dispatch"] = (Time.get_ticks_usec() - began) / 1000
	stages["worst_strip"] = worst / 1000
	return not _should_stop()


func _dispatch_strip(pipeline: RID, uniforms: RID, y: int, size: Vector2i) -> int:
	var start := Time.get_ticks_usec()
	var list := _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(list, pipeline)
	_rd.compute_list_bind_uniform_set(list, uniforms, 0)
	var push := PackedInt32Array([y]).to_byte_array()
	_rd.compute_list_set_push_constant(list, push, push.size())
	_rd.compute_list_dispatch(list, ceili(size.x / 8.0), ceili(size.y / 8.0), 1)
	_rd.compute_list_end()
	_rd.submit()
	_rd.sync()
	return maxi(1, Time.get_ticks_usec() - start)


func _free_bake_rids(uniforms: RID, buffer: RID, outputs: Array[RID]) -> void:
	if uniforms.is_valid(): _rd.free_rid(uniforms)
	if buffer.is_valid(): _rd.free_rid(buffer)
	for output in outputs: _rd.free_rid(output)


func _free_device() -> void:
	if _rd == null: return
	for compiled in _pipelines.values():
		_rd.free_rid(compiled.pipeline)
		_rd.free_rid(compiled.shader)
	_pipelines.clear()
	_rd.free()
	_rd = null


# Compatibility has no compute device. Keep its original raster bake under the
# loading cover; mipmaps and PNG work still go through the worker.
func _canvas(code: String, params: Dictionary, size: Vector2i, job: Dictionary = {}) -> Image:
	var strips := maxi(2, ceili(size.y / 32.0))
	var sh := Shader.new()
	sh.code = code
	var mat := ShaderMaterial.new()
	mat.shader = sh
	for k in params:
		mat.set_shader_parameter(k, params[k])
	var sh_h := int(ceil(float(size.y) / strips))
	var vp := SubViewport.new()
	vp.size = Vector2i(size.x, sh_h)
	vp.disable_3d = true
	vp.transparent_bg = true   # keeps the shader's alpha (the sky stores starlight transmittance there)
	vp.use_hdr_2d = false
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var rect := ColorRect.new()
	rect.size = Vector2(vp.size)
	rect.material = mat
	vp.add_child(rect)
	add_child(vp)
	mat.set_shader_parameter("full_size", Vector2(size))
	mat.set_shader_parameter("strip_h", float(sh_h))
	var full := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	for i in strips:
		mat.set_shader_parameter("strip_y0", float(i * sh_h))
		var img: Image = null
		for attempt in 3:
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			# r6: one more frame before reading back (a strip read straight after its draw came back with a dark block
			# missing from the gas on the PC)
			for frame in 2:
				await RenderingServer.frame_post_draw
				if not is_instance_valid(vp):
					return null
				if _exiting or job.get("done", false) or not is_inside_tree():
					vp.queue_free()
					return null
			img = vp.get_texture().get_image()
			if img == null or img.is_empty():
				vp.queue_free()
				return null
			if not _blank(img):
				break
		img.convert(Image.FORMAT_RGBA8)
		var h := mini(sh_h, size.y - i * sh_h)
		full.blit_rect(img, Rect2i(0, 0, size.x, h), Vector2i(0, i * sh_h))
	vp.queue_free()
	return full

static func _blank(img: Image) -> bool:
	for k in 16:
		var c := img.get_pixel(int((k * 7919) % img.get_width()), int((k * 104729) % img.get_height()))
		if c.r + c.g + c.b + c.a > 0.0: return false
	return true
