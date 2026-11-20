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

func _blob(folder: String, name: String, bytes: int) -> void:
	var f := FileAccess.open(folder.path_join(name), FileAccess.WRITE)
	var data := PackedByteArray()
	data.resize(bytes)
	f.store_buffer(data)
	f.close()

func _init() -> void:
	GUARD.arm(self, "bake_cache_cap_check")
	var top := OS.get_user_data_dir().path_join("bake_cap_check_%d" % OS.get_process_id())
	var folder := top.path_join("v3")
	DirAccess.make_dir_recursive_absolute(folder)
	# An older cache version beside it, never read again, plus a stranger file the sweep must leave.
	var v2 := top.path_join("v2")
	DirAccess.make_dir_recursive_absolute(v2)
	_blob(v2, "aa.png", 10 * KB)
	_blob(v2, "bb.png.tmp", 10 * KB)
	var v1 := top.path_join("v1")
	DirAccess.make_dir_recursive_absolute(v1)
	_blob(v1, "cc.png", 10 * KB)
	_blob(v1, "keep_me.txt", 1)
	OS.set_environment("VS_WORLD_CACHE", folder)
	var now := Time.get_unix_time_from_system()
	# Ten maps, k0 used longest ago; the battle's map is older still but held.
	for i in 10:
		_blob(folder, "k%d.png" % i, 100 * KB)
		BAKE.touch(folder, "k%d" % i, now - 1000 + i)
	_blob(folder, "battle.png", 100 * KB)
	BAKE.touch(folder, "battle", now - 5000)
	# A real map last used even earlier, then loaded by a battle through the worker: the load refreshes it.
	var img := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.4, 0.6, 1))
	BAKE._finish_image("loaded", img, {})   # the game's own save path (no review picture)
	BAKE.touch(folder, "loaded", now - 9000)
	var got: Dictionary = BAKE._work("loaded", {"size": Vector2i(64, 32), "compute": false}, {})
	_expect(got.source == "loaded" and got.image != null, "a battle loads a cached map through the worker")
	var stamp := float(BAKE._read_used(folder).get("loaded", 0))
	_expect(stamp >= now, "loading a map refreshes its last-use stamp")
	_blob(folder, "old.tmp", 10 * KB)
	_blob(folder, "used.json.junk", 1)
	var size_loaded := FileAccess.get_size(folder.path_join("loaded.png"))

	# 11 blobs of 100 KB plus the loaded map, cap 550 KB: the six oldest unheld maps go, k0 to k5.
	var r: Dictionary = BAKE.prune(folder, 550 * KB + size_loaded, {"battle": true}, "")
	for i in 6: _expect(not FileAccess.file_exists(folder.path_join("k%d.png" % i)), "oldest k%d removed" % i)
	for i in range(6, 10): _expect(FileAccess.file_exists(folder.path_join("k%d.png" % i)), "newer k%d kept" % i)
	_expect(FileAccess.file_exists(folder.path_join("battle.png")), "the map the running battle holds is kept though oldest")
	_expect(FileAccess.file_exists(folder.path_join("loaded.png")), "the map a battle just loaded is kept")
	_expect(int(r.after) <= 550 * KB + size_loaded and int(r.before) > int(r.after), "folder ends under the cap (%d -> %d bytes)" % [r.before, r.after])
	_expect(FileAccess.file_exists(folder.path_join("old.tmp")), "a .tmp younger than a day is kept")
	_expect(FileAccess.file_exists(folder.path_join("used.json.junk")), "files that are not bakes are never touched")
	_expect(not DirAccess.dir_exists_absolute(v2), "the old v2 cache is removed with its folder")
	_expect(not FileAccess.file_exists(v1.path_join("cc.png")) and FileAccess.file_exists(v1.path_join("keep_me.txt")),
		"an old version folder loses its bakes but keeps a file that is not a bake")
	var used := BAKE._read_used(folder)
	_expect(not used.has("k0") and used.has("k9"), "the index drops removed maps")

	# A fresh save through the real save path is never removed, even when it alone exceeds the cap.
	var fresh := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	BAKE._finish_image("fresh", fresh, {})
	_expect(FileAccess.file_exists(folder.path_join("fresh.png")), "the save path writes the new map")
	r = BAKE.prune(folder, 1, {}, "fresh")
	_expect(FileAccess.file_exists(folder.path_join("fresh.png")), "the map just saved survives a tiny cap")
	_expect(not FileAccess.file_exists(folder.path_join("k9.png")), "everything else unheld goes under a tiny cap")

	# Two days on, the stray .tmp is older than a day and goes.
	r = BAKE.prune(folder, 1 << 40, {}, "", now + 2 * 86400)
	_expect(not FileAccess.file_exists(folder.path_join("old.tmp")), "a .tmp older than a day is removed")

	for dir in [folder, v1, v2]:
		for name in DirAccess.get_files_at(dir): DirAccess.remove_absolute(dir.path_join(name))
		DirAccess.remove_absolute(dir)
	DirAccess.remove_absolute(top)
	if failures == 0: print("PASS: bake cache cap (issue 1265)")
	else: printerr("FAIL: %d bake cache cap checks" % failures)
	quit(1 if failures else 0)
