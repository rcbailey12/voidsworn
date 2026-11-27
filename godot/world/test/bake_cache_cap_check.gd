extends SceneTree
# Issue 1265: the planet bake cache on disk is capped. Fills a scratch cache (VS_WORLD_CACHE) past a small cap and
# shows the least recently used maps removed, the newest kept, a map the running battle holds kept, a map a battle
# just loaded from disk counted as fresh, and stray .tmp files older than a day removed (newer ones kept).

const GUARD := preload("res://tools/ci/check_guard.gd")
const BAKE := preload("res://world/world_bake.gd")
const KB := 1024

var failures := 0

func _expect(ok: bool, what: String) -> void:
	if ok: print("  ok: " + what)
	else:
		failures += 1
		printerr("  FAIL: " + what)

func K(n: String) -> String:
	return n.sha256_text()

func _blob(folder: String, name: String, bytes: int) -> void:
	var f := FileAccess.open(folder.path_join(name), FileAccess.WRITE)
	var data := PackedByteArray()
	data.resize(bytes)
	f.store_buffer(data)
	f.close()

func _init() -> void:
	GUARD.arm(self, "bake_cache_cap_check")
	_run.call_deferred()

func _run() -> void:
	var top := OS.get_user_data_dir().path_join("bake_cap_check_%d" % OS.get_process_id())
	var folder := top.path_join("v3")
	DirAccess.make_dir_recursive_absolute(folder)
	# Folders beside an override cache are not the game's: the sweep of older versions must never touch them, even when
	# they look like old versions and hold bake-shaped names (Artoo on PR 1295).
	var hexa := "a".repeat(64)
	var hexb := "b".repeat(64)
	var v2 := top.path_join("v2")
	DirAccess.make_dir_recursive_absolute(v2)
	_blob(v2, hexa + ".png", 10 * KB)
	_blob(v2, "photo.png", 10 * KB)
	_blob(v2, "notes.tmp", 10 * KB)
	OS.set_environment("VS_WORLD_CACHE", folder)
	var now := Time.get_unix_time_from_system()
	# Ten maps, k0 used longest ago; the battle's map is older still but held.
	for i in 10:
		_blob(folder, K("k%d" % i) + ".png", 100 * KB)
		BAKE.touch(folder, K("k%d" % i), now - 1000 + i)
	_blob(folder, K("battle") + ".png", 100 * KB)
	BAKE.touch(folder, K("battle"), now - 5000)
	# A real map last used even earlier, then loaded by a battle through the worker: the load refreshes it.
	var img := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.4, 0.6, 1))
	var loaded := BAKE.cache_key("loaded", "", {}, Vector2i(64, 32))
	BAKE._save(loaded, img, {}, {}, folder)
	BAKE.touch(folder, loaded, now - 9000)
	var svc = BAKE.service(self)
	var got: Image = await svc.bake("loaded", "", {}, Vector2i(64, 32), 32)
	_expect(got != null, "a battle loads a cached map through the worker")
	var stamp := float(BAKE._read_used(folder).get(loaded, 0))
	_expect(stamp >= now, "loading a map refreshes its last-use stamp")
	_blob(folder, K("old") + ".png.tmp", 10 * KB)
	_blob(folder, "used.json.junk", 1)
	_blob(folder, "photo.png", 10 * KB)
	_blob(folder, "notes.tmp", 10 * KB)
	var size_loaded := FileAccess.get_size(folder.path_join(loaded + ".png"))

	# 11 blobs of 100 KB plus the loaded map, cap 550 KB: the six oldest unheld maps go, k0 to k5.
	var r: Dictionary = BAKE.prune(folder, 550 * KB + size_loaded, {K("battle"): true}, "")
	for i in 6: _expect(not FileAccess.file_exists(folder.path_join(K("k%d" % i) + ".png")), "oldest k%d removed" % i)
	for i in range(6, 10): _expect(FileAccess.file_exists(folder.path_join(K("k%d" % i) + ".png")), "newer k%d kept" % i)
	_expect(FileAccess.file_exists(folder.path_join(K("battle") + ".png")), "the map the running battle holds is kept though oldest")
	_expect(FileAccess.file_exists(folder.path_join(loaded + ".png")), "the map a battle just loaded is kept")
	_expect(int(r.after) <= 550 * KB + size_loaded and int(r.before) > int(r.after), "folder ends under the cap (%d -> %d bytes)" % [r.before, r.after])
	_expect(FileAccess.file_exists(folder.path_join(K("old") + ".png.tmp")), "a .tmp younger than a day is kept")
	for f in ["used.json.junk", "photo.png", "notes.tmp"]:
		_expect(FileAccess.file_exists(folder.path_join(f)), "a file the game never writes is never touched: " + f)
	for f in [hexa + ".png", "photo.png", "notes.tmp"]:
		_expect(FileAccess.file_exists(v2.path_join(f)), "beside an override cache, v2/%s survives" % f.left(12))

	# Under the game's own root the sweep runs once and takes only names the game writes.
	var own := top.path_join("own")
	var own1 := own.path_join("v1")
	var own2 := own.path_join("v2")
	for d in [own1, own2, own.path_join("v3")]: DirAccess.make_dir_recursive_absolute(d)
	_blob(own2, hexa + ".png", 10 * KB)
	_blob(own2, hexb + ".png.tmp", 10 * KB)
	_blob(own2, "used.json", 2)
	_blob(own1, hexb + ".png", 10 * KB)
	_blob(own1, "photo.png", 10 * KB)
	_blob(own1, "notes.tmp", 10 * KB)
	_blob(own1, "AAAA" + hexa.substr(4) + ".png", 10 * KB)
	BAKE._old_swept = false
	var swept: Array = BAKE._sweep_old_versions(own.path_join("v3"), true)
	_expect(not DirAccess.dir_exists_absolute(own2), "the game's old v2 cache is removed with its folder")
	_expect(not FileAccess.file_exists(own1.path_join(hexb + ".png")), "the game's old v1 bake is removed")
	for f in ["photo.png", "notes.tmp", "AAAA" + hexa.substr(4) + ".png"]:
		_expect(FileAccess.file_exists(own1.path_join(f)), "a file the game never writes survives: v1/%s" % f.left(12))
	_expect(swept.size() == 4, "the sweep reports what it removed (%d)" % swept.size())
	_expect(BAKE._sweep_old_versions(own.path_join("v3"), true).is_empty(), "the sweep runs once per run")
	var used := BAKE._read_used(folder)
	_expect(not used.has(K("k0")) and used.has(K("k9")), "the index drops removed maps")

	# A fresh save through the real save path is never removed, even when it alone exceeds the cap.
	var fresh := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	BAKE._save(K("fresh"), fresh, {}, {}, folder)
	_expect(FileAccess.file_exists(folder.path_join(K("fresh") + ".png")), "the save path writes the new map")
	r = BAKE.prune(folder, 1, {}, K("fresh"))
	_expect(FileAccess.file_exists(folder.path_join(K("fresh") + ".png")), "the map just saved survives a tiny cap")
	_expect(not FileAccess.file_exists(folder.path_join(K("k9") + ".png")), "everything else unheld goes under a tiny cap")

	# Two days on, the stray .tmp is older than a day and goes.
	r = BAKE.prune(folder, 1 << 40, {}, "", now + 2 * 86400)
	_expect(not FileAccess.file_exists(folder.path_join(K("old") + ".png.tmp")), "a .tmp older than a day is removed")
	_expect(FileAccess.file_exists(folder.path_join("notes.tmp")) and FileAccess.file_exists(folder.path_join("photo.png")),
		"an old .tmp or image the game never wrote stays, even under a tiny cap")

	for dir in [folder, v2, own1, own.path_join("v3"), own]:
		for name in DirAccess.get_files_at(dir): DirAccess.remove_absolute(dir.path_join(name))
		DirAccess.remove_absolute(dir)
	DirAccess.remove_absolute(top)
	if failures == 0: print("PASS: bake cache cap (issue 1265)")
	else: printerr("FAIL: %d bake cache cap checks" % failures)
	BAKE.clear_static()
	quit(1 if failures else 0)
