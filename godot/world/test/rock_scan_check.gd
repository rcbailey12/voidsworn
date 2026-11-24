extends SceneTree
# Issue 1361 (World V2, R419) and R420 section 6.2 item 2 (rock scan channel gate): reads every rock the game ships
# straight from its .glb and fails on the regressions that made the five asteroid belts look alike:
#   - a scan's fresh-face channel (COLOR_0.b, the shader's facet) crushed below a usable range (it was 0.16 to 0.27);
#   - a low-detail or flat outlier scan (scan_06 had 14,844 triangles, scan_07 was a flat boomerang 0.43 by 1.9);
#   - a scan file that no longer matches its scans.json hash, or a manifest count the loader does not expect;
#   - every kind drawing on the same scan list, or the warm tan cast back on iron and carbon;
#   - any crystal cluster back in the game (Ryan scrapped them, Nov 22);
#   (Fable M5, H1 on PR 1782) a facet distribution the shader thresholds were not tuned on; a kind's squeeze drawing a
#   rock flatter than DRAWN_ASPECT; a kind's base albedo outside R420 band 3 (0.04 to 0.30 linear luminance).

const GUARD := preload("res://tools/ci/check_guard.gd")
const WR := preload("res://world/world_rocks.gd")
const DIR := "res://world/rocks/"
const MIN_FACET_RANGE := 0.45    # p98 minus p2 of COLOR_0.b
const MIN_TRIS := 50000          # a full scan
const MIN_TRIS_LO := 1500        # its far mesh
const MIN_ASPECT := 0.3          # shortest over longest side of the box

var failures := 0


func _init() -> void:
	GUARD.arm(self, "rock_scan_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL " + message)


func _run() -> void:
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(DIR + "scans.json"))
	_check(manifest is Dictionary, "scans.json does not parse")
	if not manifest is Dictionary:
		quit(1)
		return
	var rocks: Array = manifest.get("rocks", [])
	_check(rocks.size() == WR.SCAN_COUNT, "scans.json lists %d scans, world_rocks.gd expects %d" % [rocks.size(), WR.SCAN_COUNT])
	_check(WR.scan_names().size() == WR.SCAN_COUNT, "the loader refused the scan package (%d names)" % WR.scan_names().size())
	var names := {}
	var exts := {}
	for entry in rocks:
		var nm := str(entry.name)
		names[nm] = true
		for f in entry.files:
			var path: String = DIR + str(f.file)
			var lo := str(f.file).ends_with("_lo.glb")
			var g := _glb(path)
			if g.is_empty():
				_check(false, "%s does not read" % path)
				continue
			_check(FileAccess.get_sha256(path) == str(f.sha256), "%s does not match its scans.json hash" % f.file)
			var tris: int = g.tris
			if not lo:
				# a full scan must be closed: scan_00, a rubble pile scanned from above with an open base, turned over and
				# drew as a torn see-through shell at camera 26 (PC capture ROCKS_H, Nov 23)
				var open := _open_edges(path)
				_check(open == 0, "%s has %d open edges: a hole that shows the sky through the rock when it turns" % [f.file, open])
			_check(tris >= (MIN_TRIS_LO if lo else MIN_TRIS), "%s has %d triangles (minimum %d)" % [f.file, tris, MIN_TRIS_LO if lo else MIN_TRIS])
			var ext: Vector3 = g.ext
			var aspect := minf(ext.x, minf(ext.y, ext.z)) / maxf(ext.x, maxf(ext.y, ext.z))
			_check(aspect >= MIN_ASPECT, "%s is flat: shortest side %.2f of its longest (minimum %.2f)" % [f.file, aspect, MIN_ASPECT])
			var b: PackedFloat32Array = g.colour_b
			_check(b.size() > 0, "%s has no COLOR_0" % f.file)
			if b.size() > 0:
				b.sort()
				var spread := b[int(b.size() * 0.98)] - b[int(b.size() * 0.02)]
				_check(spread >= MIN_FACET_RANGE, "%s COLOR_0.b spans %.2f (p2 to p98, minimum %.2f): the facet channel is crushed" % [f.file, spread, MIN_FACET_RANGE])
				# the shape ROCK_SHADER's thresholds (0.04, 0.16 hollows; 0.66, 0.95 ridges) were tuned on: scan_facet.py's
				# rank ** 1.5, mean about 0.4, about 30% under 0.16 and 24% over 0.66
				var mean := 0.0
				var low := 0
				var high := 0
				for v in b:
					mean += v
					if v < 0.16: low += 1
					if v > 0.66: high += 1
				mean /= b.size()
				var lo_share := float(low) / b.size()
				var hi_share := float(high) / b.size()
				_check(mean >= 0.3 and mean <= 0.52, "%s facet mean %.2f (want 0.30 to 0.52)" % [f.file, mean])
				# a far mesh averages its clustering cell, which pulls the tails in, so its floor is lower
				var tail_min := 0.1 if lo else 0.18
				_check(lo_share >= tail_min and lo_share <= 0.42, "%s facet share under 0.16 is %.2f (want %.2f to 0.42)" % [f.file, lo_share, tail_min])
				_check(hi_share >= tail_min and hi_share <= 0.38, "%s facet share over 0.66 is %.2f (want %.2f to 0.38)" % [f.file, hi_share, tail_min])
				print("%s: %d triangles, aspect %.2f, facet spread %.2f mean %.2f under 0.16 %.2f over 0.66 %.2f" % [f.file, tris, aspect, spread, mean, lo_share, hi_share])
			if not lo:
				exts[nm] = ext
	# each kind draws on its own scans, all of them in the package
	var pools := {}
	for kind in WR.KINDS:
		var pool: Array = WR.names_for(kind)
		_check(pool.size() >= 3, "%s draws on only %d scans" % [kind, pool.size()])
		for nm in pool:
			_check(names.has(nm), "%s draws on %s, which is not in scans.json" % [kind, nm])
		pools[str(pool)] = true
	_check(pools.size() >= 4, "only %d different scan pools across the five kinds" % pools.size())
	var src: String = WR.ROCK_SHADER.code
	_check(src.count("vec3(1.12, 1.0, 0.84)") == 1 and src.contains("if (kind == 0) { a *= vec3(1.12, 1.0, 0.84); }"), "the warm tan cast must stay on stone only (kind == 0)")
	_check(src.contains("sq = min(max(sq, vec3(%.2f * max(d.x, max(d.y, d.z))) / e), vec3(1.0));" % WR.DRAWN_ASPECT), "ROCK_SHADER lost its drawn-aspect floor (%.2f)" % WR.DRAWN_ASPECT)
	# every kind's squeeze, at both ends of its seeded range, on every scan it draws: the drawn box stays rounder than
	# DRAWN_ASPECT (the same formula as ROCK_SHADER's vertex squeeze)
	for kind in WR.KINDS:
		var k0 := float(WR.KINDS[kind].get("shape", 0.0))
		var base: Vector3 = WR.KINDS[kind]["base"]
		var luma := 0.2126 * base.x + 0.7152 * base.y + 0.0722 * base.z
		_check(luma >= 0.04 and luma <= 0.30, "%s base luminance %.3f is outside R420 band 3 (0.04 to 0.30)" % [kind, luma])
		if k0 == 0.0:
			continue
		for nm in WR.names_for(kind):
			if not exts.has(nm):
				continue
			for jitter in [0.6, 1.4]:
				var d := _drawn(exts[nm], k0 * jitter)
				var a := minf(d.x, minf(d.y, d.z)) / maxf(d.x, maxf(d.y, d.z))
				_check(a >= WR.DRAWN_ASPECT - 0.005, "%s draws %s at aspect %.2f (shape %.2f), flatter than %.2f" % [kind, nm, a, k0 * jitter, WR.DRAWN_ASPECT])
	# Ryan scrapped the free crystal clusters (Nov 22): the game ships none, so nothing can draw them by accident
	_check(WR.lib().get("crystals", []).is_empty(), "rocks.json lists crystal clusters again (Ryan scrapped them, Nov 22)")
	for f in DirAccess.get_files_at(DIR):
		_check(not (f.begins_with("crystal_") and f.ends_with(".glb")), "%s is back in %s (Ryan scrapped the crystal clusters, Nov 22)" % [f, DIR])
	print("rock_scan_check: %d failures" % failures)
	quit(1 if failures > 0 else 0)


# ROCK_SHADER's squeeze on a mesh box e with shape k (vertex(): pow, clamp 0.55 to 1, then the drawn-aspect floor)
func _drawn(e: Vector3, k: float) -> Vector3:
	var mx := maxf(e.x, maxf(e.y, e.z))
	var mn := minf(e.x, minf(e.y, e.z))
	var sq := Vector3.ONE
	for i in 3:
		var v: float = pow(e[i] / mx, k) if k > 0.0 else pow(mn / e[i], -k)
		sq[i] = clampf(v, 0.55, 1.0)
	var d := e * sq
	var top := maxf(d.x, maxf(d.y, d.z))
	for i in 3:
		sq[i] = minf(maxf(sq[i], WR.DRAWN_ASPECT * top / e[i]), 1.0)
	return e * sq


# The first primitive of a .glb: triangle count, box, COLOR_0 r and b as 0 to 1 floats.
func _glb(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() < 28 or bytes.decode_u32(0) != 0x46546c67:
		return {}
	var jlen := bytes.decode_u32(12)
	var doc = JSON.parse_string(bytes.slice(20, 20 + jlen).get_string_from_utf8())
	if not doc is Dictionary:
		return {}
	var bin_at := 20 + jlen + 8
	var prim: Dictionary = doc.meshes[0].primitives[0]
	var pos: Dictionary = doc.accessors[int(prim.attributes.POSITION)]
	var out := {"tris": int(doc.accessors[int(prim.indices)].count) / 3,
		"ext": Vector3(pos.max[0] - pos.min[0], pos.max[1] - pos.min[1], pos.max[2] - pos.min[2]),
		"lo_y": float(pos.min[1]), "hi_y": float(pos.max[1]), "colour_r": PackedFloat32Array(), "colour_b": PackedFloat32Array()}
	if not prim.attributes.has("COLOR_0"):
		return out
	var acc: Dictionary = doc.accessors[int(prim.attributes.COLOR_0)]
	var view: Dictionary = doc.bufferViews[int(acc.bufferView)]
	var comps := 4 if str(acc.type) == "VEC4" else 3
	var ctype := int(acc.componentType)
	var size := {5126: 4, 5123: 2, 5121: 1}.get(ctype, 0) as int
	if size == 0:
		return out
	var stride := int(view.get("byteStride", size * comps))
	var start := bin_at + int(view.get("byteOffset", 0)) + int(acc.get("byteOffset", 0))
	var r := PackedFloat32Array()
	var b := PackedFloat32Array()
	r.resize(int(acc.count))
	b.resize(int(acc.count))
	for i in int(acc.count):
		var at := start + i * stride
		r[i] = _comp(bytes, at, ctype)
		b[i] = _comp(bytes, at + 2 * size, ctype)
	out.colour_r = r
	out.colour_b = b
	return out


# Edges used by only one triangle, after welding vertices that share a position (scans split vertices along seams).
func _open_edges(path: String) -> int:
	var bytes := FileAccess.get_file_as_bytes(path)
	var jlen := bytes.decode_u32(12)
	var doc = JSON.parse_string(bytes.slice(20, 20 + jlen).get_string_from_utf8())
	var bin_at := 20 + jlen + 8
	var prim: Dictionary = doc.meshes[0].primitives[0]
	var pa: Dictionary = doc.accessors[int(prim.attributes.POSITION)]
	var pv: Dictionary = doc.bufferViews[int(pa.bufferView)]
	var ps := bin_at + int(pv.get("byteOffset", 0)) + int(pa.get("byteOffset", 0))
	var pstride := int(pv.get("byteStride", 12))
	var weld := PackedInt32Array()
	weld.resize(int(pa.count))
	var ids := {}
	for i in int(pa.count):
		var at := ps + i * pstride
		var key := Vector3(bytes.decode_float(at), bytes.decode_float(at + 4), bytes.decode_float(at + 8))
		if not ids.has(key):
			ids[key] = ids.size()
		weld[i] = ids[key]
	var ia: Dictionary = doc.accessors[int(prim.indices)]
	var iv: Dictionary = doc.bufferViews[int(ia.bufferView)]
	var is_at := bin_at + int(iv.get("byteOffset", 0)) + int(ia.get("byteOffset", 0))
	var wide := int(ia.componentType) == 5125
	var n := int(ia.count)
	var edges := {}
	for t in range(0, n, 3):
		var v := PackedInt32Array()
		for k in 3:
			var at := is_at + (t + k) * (4 if wide else 2)
			v.append(weld[bytes.decode_u32(at) if wide else bytes.decode_u16(at)])
		for k in 3:
			var a := v[k]
			var b := v[(k + 1) % 3]
			var e := Vector2i(mini(a, b), maxi(a, b))
			edges[e] = int(edges.get(e, 0)) + 1
	var open := 0
	for e in edges:
		if int(edges[e]) == 1:
			open += 1
	return open


func _comp(bytes: PackedByteArray, at: int, ctype: int) -> float:
	match ctype:
		5126: return bytes.decode_float(at)
		5123: return bytes.decode_u16(at) / 65535.0
		_: return bytes.decode_u8(at) / 255.0
