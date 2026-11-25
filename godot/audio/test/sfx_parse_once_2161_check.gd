extends SceneTree
# Issue 2161 (Artoo on PR 2010): startup parses cues.json and clips/index.json once. prefetch() and the first sound's
# catalog load share one read, so the two files are parsed twice in all (once each), not four times.
#   godot --headless --path godot --script res://audio/test/sfx_parse_once_2161_check.gd

const GUARD := preload("res://tools/ci/check_guard.gd")
const SFX := preload("res://audio/sfx.gd")

var failures := 0


func _init() -> void:
	GUARD.arm(self, "sfx_parse_once_2161_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if ok:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)


func _run() -> void:
	SFX._cue_data = {}
	SFX._clip_index = {}
	SFX._json_reads = 0
	SFX.prefetch()
	_check(SFX._json_reads == 2, "prefetch() parses the two catalog files once each (%d reads)" % SFX._json_reads)
	_check(not SFX._cue_data.is_empty() and SFX._cue_data.has("shot_pass_by"), "prefetch() leaves the cue table, with the built-in cues, for the catalog")
	var catalog: Array = SFX._load_catalog("", [])
	_check(SFX._json_reads == 2, "the catalog load after prefetch() parses nothing more (%d reads)" % SFX._json_reads)
	_check(catalog[0].size() == SFX._cue_data.size() and catalog[0].has("acid_sizzle") and catalog[0].has("shield_sputter"),
		"the catalog holds the same cues the prefetch read (%d)" % catalog[0].size())
	SFX.prefetch()
	SFX._load_catalog("ui", [])
	_check(SFX._json_reads == 2, "later prefetches and catalog loads reuse it (%d reads)" % SFX._json_reads)
	print("%s: sfx_parse_once_2161_check" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
