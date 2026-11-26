extends Node
const SKEEP := preload("res://render/shader_keep.gd")
# A shared queue survives title, map and battle changes. Workers own their local
# RenderingDevice, compilation, GPU waits, readback, mipmaps and disk I/O.
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
var _jobs := {}
var _queue: Array = []
var _active := ""
var _thread: Thread
# Issue 1434 (LOAD12: a 9 s main-thread frame lined up with the worker's time after a bake's compute, cold and warm,
# with no pipeline compiled in it): a bake finished while a battle or the title backdrop is loading (group
# "battle_loading") keeps its image in memory and writes the cache file and prunes only once nothing is loading.
# work_stage says what the worker is doing (0 idle, 1 disk check, 2 compute, 3 save, 4 prune, 5 mips, 6 BC7 encode), so the load
# bench can put a frozen frame against it.
var _unsaved: Array = []   # [key, image, folder] baked during a load, saved later into the folder it was queued for
var written := 0           # deferred writes that saved and renamed (the load bench reads these)
var write_failed := 0
const SAVE_JOB := "#save"
static var work_stage := 0
static var bc7_enabled := false   # player opt-in, read only when resolving new requests

static func set_bc7_enabled(enabled: bool) -> void:
	bc7_enabled = enabled

# Issue 1765: a battle opened as the main scene builds its world and board inside its own _ready, while the root is
# still adding children; add_child is refused there ("Parent node is busy") and every bake request then failed on a
# service that never joined the tree. The service now joins with a deferred add, and its calls wait on the tree it
# was made for until it is in.
static var _pending: Node = null
static var _pending_tree: SceneTree = null
# Neon (PR 1776 review, item 2): keys asked for with request_* and not yet collected with result(). The cache never
# evicts them, so a map that finished first can never push out a later map of the same set before its caller reads it.
static var _pins := {}

# The two R01 relief images are decoded and cached as one job. Neither half can be evicted on its own.
class RockyRelief extends RefCounted:
	var height: Image
	var masks: Image

static func service(tree: SceneTree) -> Node:
	var node := tree.root.get_node_or_null("WorldBakes")
	if node == null and is_instance_valid(_pending) and not _pending.is_inside_tree():
		node = _pending
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
	if not is_instance_valid(node) or node.is_inside_tree() or node._exiting: return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root.get_node_or_null("WorldBakes") != null: return
	tree.root.add_child(node)

# Neon (PR 1776 review, item 1): a new battle drops every map still waiting in the queue. Jobs a freed title showcase,
# sector map or earlier battle left behind otherwise run ahead of (or, when urgent, beside) the new battle's board
# planet. The job already running cannot be stopped and finishes. A dropped job's waiters get null; a caller that still
# wants the map asks again and is queued fresh. Returns how many were dropped.
static func drop_waiting(tree: SceneTree) -> int:
	var node := tree.root.get_node_or_null("WorldBakes")
	if node == null and is_instance_valid(_pending): node = _pending
	if node == null: return 0
	var n: int = node._queue.size()
	for k in node._queue:
		if node._jobs.has(k):
			node._jobs[k].done = true
			node._jobs.erase(k)
		_pins.erase(k)
	node._queue.clear()
	return n

func _tree() -> SceneTree:
	return get_tree() if is_inside_tree() else _pending_tree

static func cache_key(key: String, code: String, params: Dictionary, size: Vector2i) -> String:
	var ordered := {}
	var keys := params.keys()
	keys.sort()
	for name in keys: ordered[name] = params[name]
	return var_to_str([key, code, ordered, size]).sha256_text()

static func cached(key: String) -> Image:
	# Disk hits also use the worker, never PNG decode on the caller's thread.
	var entry: RefCounted = _cache.get(key)
	return entry.height if entry is RockyRelief else entry as Image

static func texture(img: Image) -> Texture2D:
	var id := img.get_instance_id()
	if not _textures.has(id): _textures[id] = ImageTexture.create_from_image(img)
	return _textures[id]

static func remember(key: String, entry: RefCounted) -> void:
	if _cache.has(key): return
	_trim(CACHE_MAX - 1)
	_cache[key] = entry

# Drops the oldest maps nobody is still waiting to collect (item 2) until at most `cap` remain. With every slot pinned
# the cache runs over CACHE_MAX for a while; each later add and each released pin trims it back (Artoo, PR 1776).
static func _trim(cap: int) -> void:
	if _cache.size() <= cap: return
	for oldest in _cache.keys():
		if _cache.size() <= cap: return
		if _pins.has(oldest): continue
		var entry: RefCounted = _cache[oldest]
		if entry is RockyRelief:
			_textures.erase(entry.height.get_instance_id())
			_textures.erase(entry.masks.get_instance_id())
		else:
			_textures.erase(entry.get_instance_id())
		_cache.erase(oldest)

static func _pin(key: String) -> void:
	_pins[key] = int(_pins.get(key, 0)) + 1
	if _cache.has(key):
		# a hit counts as a fresh use: it moves to the young end of the eviction order
		var entry: RefCounted = _cache[key]
		_cache.erase(key)
		_cache[key] = entry

static func _unpin(key: String) -> void:
	var n := int(_pins.get(key, 0)) - 1
	if n > 0: _pins[key] = n
	else:
		_pins.erase(key)
		_trim(CACHE_MAX)

static func clear_static() -> void:
	_old_swept = false
	# issue 1434 (Artoo on PR 1445): quit_clean clears statics before the tree quits, while the root service's worker can
	# still be inside a bake. Stop the worker here first (a compute bake leaves at its next strip and frees its own
	# device), then forget the pins and free a service whose deferred add never landed (issue 1765).
	_stop_worker()
	_textures.clear()
	_cache.clear()
	_pins.clear()
	# Issue 1765 (Artoo, PR 1776): a service whose deferred add never landed (its tree quit first) belongs to nobody
	# else, so it is freed here; one already in a tree is owned by that tree's root and only forgotten. Its queued add
	# goes through _attach, which sees the freed node and does nothing (Neon, item 3).
	if is_instance_valid(_pending) and not _pending.is_inside_tree(): _pending.free()
	_pending = null
	_pending_tree = null


static var _abort := false   # set while shutting down: a running compute bake stops at its next strip


static func begin_shutdown(tree: SceneTree) -> void:
	var node := tree.root.get_node_or_null("WorldBakes")
	if node == null and is_instance_valid(_pending):
		node = _pending
	if node == null:
		return
	# Stop submitting work as soon as the window closes, before scene disposal and the join.
	# In particular, a cut-short battle must not start a deferred 4K PNG write during those frames.
	node._exiting = true
	_abort = node._thread != null
	drop_waiting(tree)
	node._unsaved.clear()


static func _stop_worker() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var node: Node = tree.root.get_node_or_null("WorldBakes") if tree != null and tree.root != null else null
	if node == null or node.get("_thread") == null:
		return
	var t0 := Time.get_ticks_usec()
	var stage := work_stage
	var active: String = node._active
	_abort = true
	var th: Thread = node._thread
	if th.is_started():
		th.wait_to_finish()
	node._thread = null
	_abort = false
	# a clear that is not a quit (a check): the stopped job ends without an image, so nobody waits on it
	var act: String = node._active
	if act != "" and node._jobs.has(act):
		node._jobs[act].done = true
		node._jobs.erase(act)
	node._active = ""
	print("[world] quit bake join %.1f ms (job %s, worker stage %d)" % [
		(Time.get_ticks_usec() - t0) / 1000.0, active.left(12), stage])

# Authored R01 maps use the same shared worker and texture cache as the GPU
# bakes. Decode and mip generation never block the battle's main thread.
func authored(path: String, size: Vector2i, split_relief := false, urgent := false) -> Image:
	return await result(request_authored(path, size, split_relief, urgent))

# Queues an authored map without waiting; returns its key for result(). A caller with several maps requests them all
# first, so nothing else can slip in between them (Artoo, PR 1776).
static func authored_key(path: String, size: Vector2i, float_mips := false, bc7 := false) -> String:
	var key := (path + "|" + str(FileAccess.get_modified_time(path)) + "|" + str(size) + "|" + str(float_mips)).sha256_text()
	return _format_key(key, bc7 and not float_mips)

# Issue 1434 (Artoo on 002e143f): whether an authored map's texture is still made and held, asked without starting a
# request or a pin (a trim drops the image and its texture together).
static func authored_texture_resident(path: String, size: Vector2i, float_mips := false, color := false) -> bool:
	var img = _cache.get(authored_key(path, size, float_mips, _use_bc7(color, float_mips)))
	return img is Image and _textures.has((img as Image).get_instance_id())

func request_authored(path: String, size: Vector2i, float_mips := false, urgent := false, color := false) -> String:
	var owner := service(_tree())
	var bc7 := _use_bc7(color, float_mips)
	var key := authored_key(path, size, float_mips, bc7)
	_pin(key)
	if _cache.has(key): return key
	if not owner._jobs.has(key):
		owner._jobs[key] = {"path": path, "size": size, "done": false,
			"image": null, "started": Time.get_ticks_msec(), "compute": false, "float_mips": float_mips,
			"bc7": bc7, "folder": _folder()}
	owner._enqueue(key, urgent)
	return key

# Waits for a requested map. A job keeps its dictionary until it is done, and a done job's image is cached.
# The image is read before the pin is released: the last release trims the cache, and with every slot pinned the map
# just collected can be the only one it may drop (Artoo, PR 1776).
func result(key: String) -> Image:
	var entry := await _result(key)
	return entry.height if entry is RockyRelief else entry as Image

func relief_result(key: String) -> RockyRelief:
	return (await _result(key)) as RockyRelief

func _result(key: String) -> RefCounted:
	if _cache.has(key):
		var hit: RefCounted = _cache[key]
		_unpin(key)
		return hit
	var tree := _tree()
	if tree == null or _exiting:
		_unpin(key)
		return null
	var owner := service(tree)
	var job = owner._jobs.get(key)
	if job == null:
		var late: RefCounted = _cache.get(key)
		_unpin(key)
		return late
	while not job.done:
		await tree.process_frame
		if not is_instance_valid(owner) or owner._exiting:
			_unpin(key)
			return null
	_unpin(key)
	return job.image

# Issue 1765 (PC proof OPUS1765_PC_C): the board planet fills half the frame and holds the loading cover, but its maps
# queued behind every far backdrop bake, so a cold cache missed the 20 s cover. An urgent job goes to the front of the
# queue (behind only the job already running); a queued job asked for urgently moves up.
func _enqueue(key: String, urgent: bool) -> void:
	if not _jobs.has(key) or _active == key: return
	var at := _queue.find(key)
	if at < 0 and _jobs[key].get("queued", false): return   # already taken by the worker: never run twice
	_jobs[key]["queued"] = true
	if at == 0 and urgent: _jobs[key]["urgent"] = true   # Neon item 8: a promoted head keeps its place for later urgents
	if at >= 0 and (not urgent or at == 0): return
	if at >= 0: _queue.remove_at(at)
	if urgent:
		# behind the urgent maps already waiting, ahead of everything else: a board map set runs in the order asked
		var n := 0
		while n < _queue.size() and _jobs.has(_queue[n]) and _jobs[_queue[n]].get("urgent", false): n += 1
		_queue.insert(n, key)
		_jobs[key]["urgent"] = true
	else: _queue.append(key)

# half_mips (issue 1765): the map holds a 16-bit height packed in R and G (the board planet's relief). It is decoded to
# one 32-bit float channel before its mips are made: exact, half the memory of half floats in four channels (Fable,
# PR 1776 M4), and averaging never rounds the high byte into false ridges.
func bake(key: String, code: String, params: Dictionary, size: Vector2i, strips: int, half_mips := false, urgent := false, color := false) -> Image:
	return await result(request_bake(key, code, params, size, strips, half_mips, urgent, color))

# Queues a bake without waiting; returns its key for result() (see request_authored).
func request_bake(key: String, code: String, params: Dictionary, size: Vector2i, _strips: int, half_mips := false, urgent := false, color := false) -> String:
	var owner := service(_tree())
	var bc7 := _use_bc7(color, half_mips)
	key = _format_key(cache_key(key, code, params, size), bc7)
	_pin(key)
	if _cache.has(key): return key
	if not owner._jobs.has(key):
		owner._jobs[key] = {"code": code, "params": params.duplicate(true), "size": size, "half_mips": half_mips, "bc7": bc7,
			"done": false, "image": null, "started": Time.get_ticks_msec(), "folder": _folder(),
			"compute": DisplayServer.get_name() != "headless" and RenderingServer.get_current_rendering_method() != "gl_compatibility"}
	owner._enqueue(key, urgent)
	return key

# issue 1434 (LOAD17): the bakes handed back to the main thread since main.gd last read it (12-character keys)
static var handed_back := ""


static func take_handed_back() -> String:
	var s := handed_back
	handed_back = ""
	return s


func _loading() -> bool:
	var t := _tree()   # issue 1765: a service still waiting on its deferred add has no get_tree()
	return t != null and not t.get_nodes_in_group("battle_loading").is_empty()

var _exiting := false   # issue 1482: set in _exit_tree; a raster that finishes after it starts no worker

func _enter_tree() -> void:
	_exiting = false

func _process(_dt: float) -> void:
	if _exiting:
		return
	if _thread != null:
		if _thread.is_alive(): return
		var result: Dictionary = _thread.wait_to_finish()
		_thread = null
		if _active == SAVE_JOB:
			if result.get("ok", false): written += 1
			else: write_failed += 1
			print("[world] %s %s later (stages ms %s)" % ["saved" if result.get("ok", false) else "could not save", str(result.get("key", "")), str(result.get("stages", {}))])
			_active = ""
			return
		var job: Dictionary = _jobs[_active]
		if result.image == null and not job.has("path") and not job.compute and DisplayServer.get_name() != "headless" and not job.get("raster_done", false):
			job.raster_done = true
			var img: Image = await _canvas(job.code, job.params, job.size)
			# issue 1482: the raster awaited frames; if the service left the tree meanwhile, _exit_tree already joined
			# and cleared every job, so no new worker may start (it would never be joined)
			if _exiting or not is_inside_tree() or job.done:
				job.done = true
				return
			_thread = Thread.new()
			job["defer_save"] = job.get("defer_save", false) or _loading()
			_thread.start(_finish_image.bind(_active, img, _keep_keys(), job))
			return
		job.image = result.image
		job.done = true
		if result.get("save_image") != null:
			_unsaved.append([_active, result.save_image, str(job.get("folder", _folder()))])
		if result.image != null:
			remember(_active, result.image)
			handed_back = (handed_back + " " if handed_back != "" else "") + _active.left(12)
			# Artoo on PR 1445: queued, worker start and completion apart (absolute ms), so a frozen frame can be put
			# against the wait in the queue, the worker's own stages, or the hand-back here
			print("[world] %s %s %dx%d in %d ms (worker%s; queued at %d, worker from %d, handed back at %d ms)" % [result.source, _active, job.size.x, job.size.y, Time.get_ticks_msec() - job.started,
				"; stages ms %s" % str(result.get("stages")) if result.get("stages") is Dictionary else "", int(job.started), int(job.get("worker_from", -1)), Time.get_ticks_msec()])
		elif result.get("error", "") != "":
			push_error("World bake: " + result.error)
		_jobs.erase(_active)
		_active = ""
	if _active != "": return
	if _queue.is_empty():
		if not _unsaved.is_empty() and not _loading():
			var u: Array = _unsaved.pop_front()
			_active = SAVE_JOB
			_thread = Thread.new()
			if _thread.start(_save_later.bind(u[0], u[1], _keep_keys(), u[2])) != OK:
				_thread = null
				_active = ""
		return
	_active = _queue.pop_front()
	_jobs[_active]["defer_save"] = _loading()
	_jobs[_active]["worker_from"] = Time.get_ticks_msec()
	_thread = Thread.new()
	var err := _thread.start(_work.bind(_active, _jobs[_active], _keep_keys()))
	if err != OK:
		_jobs[_active].done = true
		_jobs.erase(_active)
		_active = ""
		_thread = null
		push_error("Could not start world bake worker: %s" % err)

func _exit_tree() -> void:
	# Deleting a world does not cancel its shared job. Only shutdown joins it.
	_exiting = true
	if _thread != null:
		_abort = true
		_thread.wait_to_finish()
		_thread = null
		_abort = false
	for job in _jobs.values(): job.done = true
	_jobs.clear()
	_queue.clear()
	clear_static()

# Keys the running game holds or is about to load. Read on the main thread, handed to the worker by value.
func _keep_keys() -> Dictionary:
	var keep := {}
	for k in _cache: keep[k] = true
	for k in _jobs: keep[k] = true
	return keep

static func _folder() -> String:
	return OS.get_environment("VS_WORLD_CACHE") if OS.has_environment("VS_WORLD_CACHE") else CACHE_DIR

static func _format_key(key: String, bc7: bool) -> String:
	return (key + "|bc7").sha256_text() if bc7 else key

static func _use_bc7(color: bool, high_precision: bool) -> bool:
	return bc7_enabled and color and not high_precision and _supports_bc7()

static func _supports_bc7() -> bool:
	var rd := RenderingServer.get_rendering_device()
	if rd == null: return false
	return rd.texture_is_format_supported_for_usage(RenderingDevice.DATA_FORMAT_BC7_UNORM_BLOCK, RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT) \
		and rd.texture_is_format_supported_for_usage(RenderingDevice.DATA_FORMAT_BC7_SRGB_BLOCK, RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT)


static func _load_bc7(path: String, size: Vector2i) -> Image:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return null
	var w := size.x
	var h := size.y
	var expected := 0
	while true:
		expected += ceili(w / 4.0) * ceili(h / 4.0) * 16
		if w == 1 and h == 1: break
		w = maxi(1, w >> 1)
		h = maxi(1, h >> 1)
	if file.get_length() != expected: return null
	var bytes := file.get_buffer(expected)
	if bytes.size() != expected: return null
	return Image.create_from_data(size.x, size.y, true, Image.FORMAT_BPTC_RGBA, bytes)


static func _compress_bc7(img: Image, stages: Dictionary) -> bool:
	# The sky's alpha is transmittance, and planet albedo alpha is ocean/ice sheen. BC7 keeps both.
	# Only 8-bit color goes through this path. Packed relief and the half-float sky planned in #1502 keep their format.
	if img.get_format() != Image.FORMAT_RGBA8 and img.get_format() != Image.FORMAT_RGB8: return false
	work_stage = 6
	var t := Time.get_ticks_usec()
	var ok := img.compress(Image.COMPRESS_BPTC, Image.COMPRESS_SOURCE_GENERIC) == OK
	stages["bc7_encode"] = (Time.get_ticks_usec() - t) / 1000
	work_stage = 0
	return ok and img.get_format() == Image.FORMAT_BPTC_RGBA


static func _work(key: String, job: Dictionary, keep: Dictionary = {}) -> Dictionary:
	# Issue 1434: the folder is pinned when queued, including reads and deferred writes for both formats.
	var folder := str(job.get("folder", _folder()))
	var bc7 := bool(job.get("bc7", false))
	work_stage = 1
	if bc7:
		var hit := _load_bc7(folder.path_join(key + ".bc7"), job.size)
		if hit != null:
			touch(folder, key)
			work_stage = 0
			return {"image": hit, "source": "loaded BC7"}
	if job.has("path"):
		var authored_image: Image = null
		if str(job.path).ends_with(".json"):
			authored_image = _authored_tiles(job.path, job.size)
		else:
			authored_image = Image.load_from_file(job.path)
		if authored_image == null or authored_image.get_size() != job.size:
			work_stage = 0
			return {"image": null, "error": "Missing or wrong-size R01 map: " + str(job.path)}
		# Averaging the high/low height bytes into 8-bit mip levels rounds the
		# high byte first. Near a pole that makes false radial ridges. Float
		# channels preserve the linear packed value through filtering and mips.
		work_stage = 5
		if job.get("float_mips", false): authored_image.convert(Image.FORMAT_RGBAF)
		authored_image.generate_mipmaps()
		var authored_stages := {}
		var save_image: Image = null
		if bc7 and _compress_bc7(authored_image, authored_stages):
			save_image = _save_or_defer(key, authored_image, keep, authored_stages, job)
		work_stage = 0
		return {"image": authored_image, "source": "authored", "stages": authored_stages, "save_image": save_image}
	var path := folder.path_join(key + ".png")
	var img: Image = null
	work_stage = 1
	if not bc7 and FileAccess.file_exists(path): img = Image.load_from_file(path)
	var source := "loaded"
	var error := ""
	var stages := {}
	if img == null or img.is_empty() or img.get_size() != job.size:
		img = null
		if job.compute:
			work_stage = 2
			var result := _compute(job.code, job.params, job.size)
			img = result.image
			error = result.get("error", "")
			stages = result.get("stages", {})
			source = "baked"
	else:
		touch(folder, key)
	var finished := _prepare_bake(key, img, keep, stages, job, source == "baked")
	finished.merge({"source": source, "error": error, "stages": stages})
	return finished


static func _prepare_bake(key: String, img: Image, keep: Dictionary, stages: Dictionary, job: Dictionary, baked: bool) -> Dictionary:
	var save_image: Image = null
	var bc7 := bool(job.get("bc7", false))
	var half_mips := bool(job.get("half_mips", false))
	if img == null:
		work_stage = 0
		return {"image": null}
	if baked and not bc7:
		save_image = _save_or_defer(key, img, keep, stages, job)
	work_stage = 5
	var tm := Time.get_ticks_usec()
	# PNG keeps the original packed height bytes, even when written after the upload.
	if half_mips: img = height_float(img.duplicate() if save_image != null else img)
	if not img.has_mipmaps(): img.generate_mipmaps()
	if not stages.is_empty(): stages["mips"] = (Time.get_ticks_usec() - tm) / 1000
	if bc7 and _compress_bc7(img, stages):
		save_image = _save_or_defer(key, img, keep, stages, job)
	work_stage = 0
	return {"image": img, "save_image": save_image}


static func _save_or_defer(key: String, img: Image, keep: Dictionary, stages: Dictionary, job: Dictionary) -> Image:
	if job.get("defer_save", false):
		stages["save"] = "deferred (a load is running)"
		return img
	_save(key, img, keep, stages, str(job.get("folder", _folder())))
	return null


# Cache file write and prune, each timed. BC7 arrives already encoded so the same image can be uploaded before a save.
static func _save(key: String, img: Image, keep: Dictionary, stages: Dictionary, folder: String) -> bool:
	var bc7 := img.get_format() == Image.FORMAT_BPTC_RGBA
	var path := folder.path_join(key + (".bc7" if bc7 else ".png"))
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		return false
	work_stage = 3
	var t := Time.get_ticks_usec()
	stages["save_began"] = Time.get_ticks_msec()
	var tmp := path + ".tmp"
	var wrote := false
	if bc7:
		var file := FileAccess.open(tmp, FileAccess.WRITE)
		if file != null:
			wrote = file.store_buffer(img.get_data())
			file.close()
	else:
		wrote = img.save_png(tmp) == OK
	var ok := wrote and DirAccess.rename_absolute(tmp, path) == OK
	stages["save"] = (Time.get_ticks_usec() - t) / 1000
	if ok:
		work_stage = 4
		t = Time.get_ticks_usec()
		prune(folder, CACHE_CAP_BYTES, keep, key)
		stages["prune"] = (Time.get_ticks_usec() - t) / 1000
	work_stage = 0
	return ok


static func _save_later(key: String, img: Image, keep: Dictionary, folder: String) -> Dictionary:
	var stages := {}
	var ok := _save(key, img, keep, stages, folder)
	return {"key": key, "ok": ok, "stages": stages}


# Issue 1765: a 16-bit height packed big-endian in R and G, as one 32-bit float channel (0 to 1). Worker thread only.
# Neon (PR 1776 review, item 6): this runs on the worker for every cold and warm load of a baked look, about 1.6 s per
# 4K map on the PC. The image is cut to its two height bytes (RG8, in native code), each pixel is read as one 16-bit
# word and looked up in a 64K table of the exact heights: about half the time of the per-byte loop, same values.
static var _height_lut := PackedFloat32Array()

static func _height_table() -> PackedFloat32Array:
	if _height_lut.is_empty():
		var lut := PackedFloat32Array()
		lut.resize(65536)
		for v in 65536: lut[v] = float((v & 255) * 256 + (v >> 8)) / 65535.0   # the word reads low byte first: R is v & 255
		_height_lut = lut
	return _height_lut

static func height_float(img: Image) -> Image:
	if img.get_format() != Image.FORMAT_RG8: img.convert(Image.FORMAT_RG8)
	var src := img.get_data()
	var n := img.get_width() * img.get_height()
	var out := PackedFloat32Array()
	out.resize(n)
	var lut := _height_table()
	for i in n:
		out[i] = lut[src.decode_u16(i * 2)]
	return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RF, out.to_byte_array())

# R01's source RGBA8 is height (R high, G low), roughness (B), and cloud coverage (A). Decode the height before
# filtering to avoid seams at byte carries. The other two channels are linear masks, not a stored normal.
static func split_rocky_relief(img: Image) -> RockyRelief:
	if img.get_format() != Image.FORMAT_RGBA8: img.convert(Image.FORMAT_RGBA8)
	var size := img.get_size()
	var count := size.x * size.y
	var heights := PackedFloat32Array()
	heights.resize(count)
	var masks := PackedByteArray()
	masks.resize(count * 2)
	var lut := _height_table()
	var src := img.get_data()
	for i in count:
		var rgba := src.decode_u32(i * 4)
		heights[i] = lut[rgba & 0xffff]
		masks.encode_u16(i * 2, rgba >> 16)
	var relief := RockyRelief.new()
	relief.height = Image.create_from_data(size.x, size.y, false, Image.FORMAT_RF, heights.to_byte_array())
	relief.masks = Image.create_from_data(size.x, size.y, false, Image.FORMAT_RG8, masks)
	relief.height.generate_mipmaps()
	relief.masks.generate_mipmaps()
	return relief


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

static func _finish_image(key: String, img: Image, keep: Dictionary = {}, job: Dictionary = {}) -> Dictionary:
	var stages := {}
	var finished := _prepare_bake(key, img, keep, stages, job, true)
	finished.merge({"source": "baked", "stages": stages})
	return finished

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
# (64 hex digits with .png or .bc7, their .tmp files, used.json's .tmp) are removed. `keep` and `fresh` (the
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
		if not (name.ends_with(".png") or name.ends_with(".bc7")): continue
		var key := name.get_basename()
		var size := FileAccess.get_size(path)
		var stamp: float = float(used.get(key, maxi(FileAccess.get_modified_time(path), FileAccess.get_access_time(path))))
		maps.append({"key": key, "name": name, "path": path, "size": size, "stamp": stamp})
		total += size
	var before := total
	if total > cap:
		maps.sort_custom(func(a, b): return a.stamp < b.stamp)
		for m in maps:
			if total <= cap: break
			if keep.has(m.key) or m.key == fresh: continue
			if DirAccess.remove_absolute(m.path) == OK:
				total -= int(m.size)
				removed.append(m.name)
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
# override (Artoo on PR 1295: its neighbours are not the game's). Only names recognized by _bake_name go,
# then the folder if it is empty.
static var _old_swept := false

static func _bake_name(f: String) -> bool:
	if f == USED_INDEX or f == USED_INDEX + ".tmp": return true
	var name := f.trim_suffix(".tmp")
	if not (name.ends_with(".png") or name.ends_with(".bc7")): return false
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
			if _bake_name(f) and DirAccess.remove_absolute(old.path_join(f)) == OK: removed.append("v%d/%s" % [n, f])
		if DirAccess.get_files_at(old).is_empty() and DirAccess.get_directories_at(old).is_empty():
			DirAccess.remove_absolute(old)
	return removed

# The two bake shaders use the GLSL subset of Godot's shader language. Reuse
# their equations, with a storage buffer for uniforms and an image output.
static func _compute_source(code: String, params: Dictionary, size: Vector2i) -> Dictionary:
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
	header += "layout(set=0,binding=0,rgba8) uniform writeonly image2D output_image;\n"
	header += "layout(set=0,binding=1,std430) readonly buffer BakeData { vec4 values[]; } bake_data;\n"
	header += "layout(push_constant,std430) uniform Tile { int y; } tile;\nvec2 UV; vec4 COLOR;\n"
	var entry := "\nvoid main() { ivec2 p=ivec2(gl_GlobalInvocationID.xy)+ivec2(0,tile.y); if(any(greaterThanEqual(p,ivec2(full_size)))) return; UV=(vec2(p)+0.5)/full_size; bake_pixel(); imageStore(output_image,p,COLOR); }\n"
	return {"code": header + defines + code + entry, "data": values.to_byte_array()}

# Issue 1434 (LOAD6 on the PC: with world bakes pending, single main-thread frames of 5 to 10 s that were neither
# render nor pipeline time). Each stage of a compute bake is timed with its wall-clock start, so a PC log lines up a
# frozen frame against the stage that ran during it. The local device stays per bake: it belongs to the thread that
# made it (a cloud trial on software Vulkan refused free_rid and finalize from any other thread), and each bake is a
# new worker thread.
static func _compute(code: String, params: Dictionary, size: Vector2i) -> Dictionary:
	var source := _compute_source(code, params, size)
	if source.has("error"): return {"image": null, "error": source.error}
	var stages := {"began": Time.get_ticks_msec()}
	var t := Time.get_ticks_usec()
	var rd := RenderingServer.create_local_rendering_device()
	stages["device"] = (Time.get_ticks_usec() - t) / 1000
	if rd == null: return {"image": null, "error": "Local RenderingDevice is unavailable"}
	t = Time.get_ticks_usec()
	var shader_source := RDShaderSource.new()
	shader_source.source_compute = source.code
	var spirv := rd.shader_compile_spirv_from_source(shader_source)
	var error := spirv.get_stage_compile_error(RenderingDevice.SHADER_STAGE_COMPUTE)
	if error != "":
		rd.free()
		return {"image": null, "error": error}
	stages["spirv"] = (Time.get_ticks_usec() - t) / 1000
	t = Time.get_ticks_usec()
	var shader := rd.shader_create_from_spirv(spirv)
	var pipeline := rd.compute_pipeline_create(shader)
	stages["pipeline"] = (Time.get_ticks_usec() - t) / 1000
	t = Time.get_ticks_usec()
	var format := RDTextureFormat.new()
	format.width = size.x
	format.height = size.y
	format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	var output := rd.texture_create(format, RDTextureView.new())
	var buffer := rd.storage_buffer_create(source.data.size(), source.data)
	var image_uniform := RDUniform.new()
	image_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	image_uniform.binding = 0
	image_uniform.add_id(output)
	var data_uniform := RDUniform.new()
	data_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	data_uniform.binding = 1
	data_uniform.add_id(buffer)
	var uniforms := rd.uniform_set_create([image_uniform, data_uniform], shader, 0)
	# Small dispatches avoid the Windows GPU watchdog on slower graphics cards.
	var worst_strip := 0
	for y in range(0, size.y, 32):
		if _abort:
			for rid in [uniforms, buffer, output, pipeline, shader]: rd.free_rid(rid)
			rd.free()
			return {"image": null, "error": "", "stages": stages}
		var ts := Time.get_ticks_usec()
		var list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(list, pipeline)
		rd.compute_list_bind_uniform_set(list, uniforms, 0)
		var push := PackedInt32Array([y]).to_byte_array()
		rd.compute_list_set_push_constant(list, push, push.size())
		rd.compute_list_dispatch(list, ceili(size.x / 8.0), ceili(mini(32, size.y - y) / 8.0), 1)
		rd.compute_list_end()
		rd.submit()
		rd.sync()
		worst_strip = maxi(worst_strip, Time.get_ticks_usec() - ts)
	stages["dispatch"] = (Time.get_ticks_usec() - t) / 1000
	stages["worst_strip"] = worst_strip / 1000
	t = Time.get_ticks_usec()
	var bytes := rd.texture_get_data(output, 0)
	for rid in [uniforms, buffer, output, pipeline, shader]: rd.free_rid(rid)
	rd.free()
	stages["readback"] = (Time.get_ticks_usec() - t) / 1000
	if bytes.size() != size.x * size.y * 4: return {"image": null, "error": "Incomplete bake readback", "stages": stages}
	return {"image": Image.create_from_data(size.x, size.y, false, Image.FORMAT_RGBA8, bytes), "stages": stages}


# Compatibility has no compute device. Keep its original raster bake under the
# loading cover; mipmaps and PNG work still go through the worker.
func _canvas(code: String, params: Dictionary, size: Vector2i) -> Image:
	var strips := maxi(2, ceili(size.y / 32.0))
	var mat := ShaderMaterial.new()
	mat.shader = SKEEP.of(code)
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
				if _exiting or not is_inside_tree():
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
