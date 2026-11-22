extends SceneTree
# Issue 1482 (independent game audit Nov 21, F-12 part 2): the campaign's music follows the sector, not only the page kind.
#   a run resumed during post-boss rewards (the map page, old sector) gets the new sector's map track when the sector
#   moves on, though the page kind stays "map";
#   a Nemesis fight at a service stop comes back to the stop's page with the map track, not silence;
#   the title page plays the title music, and the battle briefing keeps whatever plays.
# The real campaign_host.gd page handler and battle return, with a stub campaign, main and music player.

const GUARD := preload("res://tools/ci/check_guard.gd")
const HOST := preload("res://main/campaign_host.gd")

class Music extends RefCounted:
	var calls: Array = []
	func play_map(sector := 1) -> void: calls.append("map:%d" % sector)
	func play_title() -> void: calls.append("title")

class Main extends Node:
	var args := {}
	var music = Music.new()
	func play_api(_a, _po) -> Dictionary:
		await get_tree().process_frame
		calls_in_battle.append("battle")
		return {"result": "win", "errors": []}
	var calls_in_battle: Array = []

class Camp extends RefCounted:
	signal changed
	var page := {"kind": "none"}
	var RUN = null
	var modal_d = null
	var pending_battle := {}
	func set_teaching_tips(_on) -> void: pass
	func can_retreat() -> bool: return true
	func finish_battle(_res, _b) -> void: changed.emit()

class Api extends RefCounted:
	var round_saves := false
	func battle_state() -> Dictionary: return {}

var failures := 0


func _init() -> void:
	GUARD.arm(self, "campaign_music_1482_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)
	else:
		print("ok    ", message)


func _host() -> Array:
	var m := Main.new()
	root.add_child(m)
	var h = HOST.new()
	h.main = m
	h.C = Camp.new()
	h.C.changed.connect(h._on_changed)
	m.add_child(h)
	return [h, m]


func _run() -> void:
	# post-boss rewards resumed: the map page in sector 1, then the sector moves on with the page kind still "map"
	var hm := _host()
	var h = hm[0]
	var mus = hm[1].music
	h.C.RUN = {"sector": 1}
	h.C.page = {"kind": "map"}
	h._on_changed()
	h.C.RUN["sector"] = 2
	h._on_changed()
	_check(mus.calls == ["map:1", "map:2"], "resumed in post-boss rewards: the new sector's map track plays (calls %s)" % str(mus.calls))

	# a Nemesis fight at a service stop: the stop's page before and after the battle
	hm = _host()
	h = hm[0]
	mus = hm[1].music
	h.C.RUN = {"sector": 2}
	h.C.page = {"kind": "shipyard"}
	h._on_changed()
	h.api_now = Api.new()
	await h._play_battle()
	_check(mus.calls == ["map:2", "map:2"] and hm[1].calls_in_battle == ["battle"],
		"after a Nemesis fight at a service stop the stop plays its map track again (calls %s)" % str(mus.calls))

	# the title, and the battle briefing keeping the map track
	hm = _host()
	h = hm[0]
	mus = hm[1].music
	h.C.page = {"kind": "title"}
	h._on_changed()
	h.C.RUN = {"sector": 3}
	h.C.page = {"kind": "map"}
	h._on_changed()
	h.C.page = {"kind": "battle"}
	h._on_changed()
	_check(mus.calls == ["title", "map:3"], "title plays the title music; the briefing keeps the map track (calls %s)" % str(mus.calls))
	print("campaign_music_1482_check: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)
