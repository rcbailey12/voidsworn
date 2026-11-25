extends RefCounted
# Admiral faces for any screen (owner: music and portraits helper; R37, R40).
#   const Portraits := preload("res://portraits/portraits.gd")
#   var tex: Texture2D = Portraits.face("vex")      # painted portrait when one is chosen, else the admiral's crest
#   var tex2: Texture2D = Portraits.crest("vex")    # always the crest (small slots, lists, map tokens)
#   Portraits.has_painting("vex")                   # true when a painted portrait is in godot/portraits/painted/
#   Portraits.face("nekhet", 3)                     # Eclipse only (R78 Q17, issue 43): mastery level adds restoration
#                                                   # frame marks; capstone mastery (third arg) adds the outer hairline
# Admiral ids are data.js ADMIRALS keys (vex, kassar, grax, matriarch, aelith, nekhet, ...).
# index.json lists the picked painting per admiral and the kept alternates (alts/) Ryan can swap in by editing "pick".

const INDEX := "res://portraits/index.json"
static var _idx := {}
static var _cache := {}


static func _index() -> Dictionary:
	if _idx.is_empty() and FileAccess.file_exists(INDEX):
		var d = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
		if d is Dictionary:
			_idx = d
	return _idx


static func has_painting(id: String) -> bool:
	var e = _index().get("painted", {}).get(id, {})
	return e is Dictionary and String(e.get("pick", "")) != "" and _exists("res://portraits/" + String(e["pick"]))


# One picked face per subject. Alternate pictures of the same face are not new captains.
static func captain_pool(fac: String) -> Array:
	var pool := []
	for id in _index().get("painted", {}):
		if _index()["painted"][id].get("faction") == fac and has_painting(id): pool.append(id)
	for id in _index().get("nemesis", {}):
		var entry: Dictionary = _index()["nemesis"][id]
		if id.begins_with("nem_" + fac + "_") and _exists("res://portraits/" + str(entry["pick"])):
			pool.append(id)
	pool.sort()
	return pool


static func captain_face(id: String) -> Texture2D:
	if id.is_empty(): return null
	var entry: Dictionary = _index().get("nemesis", {}).get(id, {})
	# The unframed source is a portrait, not the red-framed Nemesis card or scar overlay.
	if not entry.is_empty(): return _tex("res://portraits/" + str(entry["pick"]))
	return face(id)


static func face(id: String, level: int = 0, capstone: int = 0) -> Texture2D:
	var base := _face_base(id)
	if base == null:
		return null
	if level <= 0 and capstone <= 0:
		return base
	if _restore_faction(id) != RESTORE_FAC:
		return base
	var key := "%s|r%d|c%d" % [id, clampi(level, 0, 99), clampi(capstone, 0, 9)]
	if _cache.has(key):
		return _cache[key]
	# Work on a copy of the face image: get_image() may hand back the texture's own image, and
	# marking it in place would bleed the frame onto the plain face too.
	var img := _face_image(id)
	if img == null:
		return base
	var ov := _restore_overlay(clampi(level, 0, RESTORE_MAX_LEVEL), clampi(capstone, 0, 3), img.get_width())
	img.blend_rect(ov, Rect2i(0, 0, ov.get_width(), ov.get_height()), Vector2i.ZERO)
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


static func _face_path(id: String) -> String:
	var e = _index().get("painted", {}).get(id, {})
	if e is Dictionary and String(e.get("pick", "")) != "" and _exists("res://portraits/" + String(e["pick"])):
		return "res://portraits/" + String(e["pick"])
	return "res://portraits/crests/" + id + ".svg"


static func _face_image(id: String) -> Image:
	var p := _face_path(id)
	var img: Image = null
	if ResourceLoader.exists(p):
		var r = load(p)
		if r is Texture2D and r.get_image() != null:
			img = r.get_image().duplicate()
	if img == null and FileAccess.file_exists(p):
		# fresh checkout run headless: no import cache yet, decode the raw file (as _tex does)
		var d := Image.new()
		var err := d.load_svg_from_buffer(FileAccess.get_file_as_bytes(p)) if p.ends_with(".svg") else d.load(p)
		if err == OK:
			img = d
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return img


static func _face_base(id: String) -> Texture2D:
	# A picked painting that exists but fails to load falls back to the crest, as face() did before issue 43
	# (Muse opus_check_707 condition 2).
	var t := _tex(_face_path(id))
	return t if t != null else crest(id)


static func crest(id: String) -> Texture2D:
	return _tex("res://portraits/crests/" + id + ".svg")


# Faction crest (lore bible round 8, section x.8): id is the faction id (voidsworn, hegemony, corsair, chorus, ithar, deathless).
static func faction_crest(id: String) -> Texture2D:
	return _tex("res://portraits/crests/faction_" + id + ".svg")


static func _exists(p: String) -> bool:
	return ResourceLoader.exists(p) or FileAccess.file_exists(p)


static func _tex(p: String) -> Texture2D:
	if _cache.has(p):
		return _cache[p]
	var t: Texture2D = null
	if ResourceLoader.exists(p):
		var r = load(p)
		if r is Texture2D:
			t = r
	if t == null and FileAccess.file_exists(p):
		# not imported yet (fresh checkout run headless): load the raw file
		var img := Image.new()
		var err := img.load_svg_from_buffer(FileAccess.get_file_as_bytes(p)) if p.ends_with(".svg") else img.load(p)
		if err == OK:
			t = ImageTexture.create_from_image(img)
	_cache[p] = t
	return t


# ---------- Nemesis (R42) ----------
# Portraits.nemesis("corsair", 3, ["burn", "eye"]) -> the Nemesis nem_corsair_3 with those scars and the red-black frame.
# Scar kinds (scars.json says which faction can take which): burn (all), cyber, eye (human factions), carapace (Chorus),
# porcelain (Ithar), machine (Deathless). The first scar uses a painted (baked) version when one exists; the rest are
# overlays placed at the portrait's face anchor. Stream B stores the Nemesis as nem_<faction>_<1..6> plus its scar list.
static func nemesis(fac: String, n: int, scars: Array = []) -> Texture2D:
	var id := "nem_%s_%d" % [fac, n]
	var key := id + ":" + ",".join(PackedStringArray(scars))
	if _cache.has(key):
		return _cache[key]
	var e = _index().get("nemesis", {}).get(id, {})
	if not (e is Dictionary) or String(e.get("pick", "")) == "":
		return null
	var rest: Array = scars.duplicate()
	var src := "res://portraits/" + String(e["pick"])
	var baked = e.get("baked", {})
	if not rest.is_empty() and baked is Dictionary and baked.has(rest[0]) and _exists("res://portraits/" + String(baked[rest[0]])):
		src = "res://portraits/" + String(baked[rest[0]])
		rest.remove_at(0)
	var img := _img(src)
	if img == null:
		return null
	img.convert(Image.FORMAT_RGBA8)
	var sz := img.get_width()
	var anc: Array = e.get("anchor", [0.5, 0.42, 0.34])
	var place: Dictionary = _scars().get("place", {})
	var patches = e.get("patch", {})
	for k in rest:
		# a later scar: the scarred region cut from this Nemesis's own painted scar of that kind (feathered), when present
		if patches is Dictionary and patches.has(k):
			var pe: Dictionary = patches[k]
			var pi := _img("res://portraits/" + String(pe.get("file", "")))
			if pi != null:
				pi.convert(Image.FORMAT_RGBA8)
				var f := float(sz) / 768.0
				if absf(f - 1.0) > 0.01:
					pi.resize(int(pi.get_width() * f), int(pi.get_height() * f), Image.INTERPOLATE_LANCZOS)
				img.blend_rect(pi, Rect2i(0, 0, pi.get_width(), pi.get_height()), Vector2i(int(float(pe.get("x", 0.0)) * sz), int(float(pe.get("y", 0.0)) * sz)))
				continue
		# fallback: the generic overlay at the face anchor
		var sc := _img("res://portraits/nemesis/scars/scar_%s.png" % k)
		if sc == null or not place.has(k):
			continue
		var pl: Array = place[k]
		var s := int(sz * float(anc[2]) * float(pl[2]))
		sc.convert(Image.FORMAT_RGBA8)
		sc.resize(s, s, Image.INTERPOLATE_LANCZOS)
		var x := int(sz * (float(anc[0]) + float(pl[0]) * float(anc[2])) - s / 2.0)
		var y := int(sz * (float(anc[1]) + float(pl[1]) * float(anc[2])) - s / 2.0)
		img.blend_rect(sc, Rect2i(0, 0, s, s), Vector2i(x, y))
	var fr := _img("res://portraits/nemesis/frame_%s.png" % fac)
	if fr != null:
		fr.convert(Image.FORMAT_RGBA8)
		if fr.get_width() != sz:
			fr.resize(sz, sz, Image.INTERPOLATE_LANCZOS)
		img.blend_rect(fr, Rect2i(0, 0, sz, sz), Vector2i.ZERO)
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


static func nemesis_ids(fac: String) -> Array:
	var out: Array = []
	for id in _index().get("nemesis", {}):
		if String(id).begins_with("nem_%s_" % fac):
			out.append(id)
	out.sort()
	return out


static var _sc := {}
static func _scars() -> Dictionary:
	if _sc.is_empty() and FileAccess.file_exists("res://portraits/nemesis/scars/scars.json"):
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://portraits/nemesis/scars/scars.json"))
		if d is Dictionary:
			_sc = d
	return _sc


# ---------- Restoration frames (R78 Q17, issue 43) ----------
# Eclipse admirals (faction id deathless) level by restoration, so their portrait frame changes with
# mastery level: dark plates stack in the four corners, white-gold ring pieces light one per level
# around the frame, and the visor slit at the bottom widens and brightens. Capstone mastery (the
# lineage cap, up to 3 more levels) draws a thin outer hairline in brighter gold. Other factions
# ignore the level arguments and get the plain face. Marks are drawn once per (level, capstone,
# size) and cached; the base portrait is never edited.
const RESTORE_FAC := "deathless"
const RESTORE_MAX_LEVEL := 8

static var _rfac := {}


static func _restore_faction(id: String) -> String:
	if _rfac.is_empty() and FileAccess.file_exists("res://portraits/crests/index.json"):
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://portraits/crests/index.json"))
		if d is Dictionary:
			for k in d:
				if d[k] is Dictionary:
					_rfac[k] = str(d[k].get("faction", ""))
	return str(_rfac.get(id, ""))


static func _restore_overlay(level: int, capstone: int, size: int) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var S := float(size)
	var c := S * 0.5
	if level > 0:
		_ring_pass(img, S, c, S * 0.452, maxf(1.5, S * 0.006), S * 0.016, mini(level, RESTORE_MAX_LEVEL), 0.16, 0.95, Color8(0xf0, 0xd6, 0x90))
		_plates_pass(img, S, c, clampi(int(ceil(float(level) / 2.0)), 0, 4))
		_visor_pass(img, S, level, capstone)
	if capstone > 0:
		_ring_pass(img, S, c, S * 0.470, maxf(1.2, S * 0.0032), S * 0.007, RESTORE_MAX_LEVEL, 0.0, 0.15 * float(mini(capstone, 3)), Color8(0xff, 0xf2, 0xc8))
	return img


# One white-gold arc band split into 8 slots, lit clockwise from the top; `lit` slots show, `gap` is
# the empty fraction of each slot. With gap 0 every slot shows (the capstone hairline). The band is
# drawn core plus a soft glow, alpha-composited over whatever is already in the overlay.
static func _ring_pass(img: Image, S: float, c: float, r0: float, th: float, glow: float, lit: int, gap: float, a: float, col: Color) -> void:
	var size := img.get_width()
	var lo := int(max(0.0, c - r0 - glow - 2.0))
	var hi := int(min(float(size - 1), c + r0 + glow + 2.0))
	var seg := TAU / 8.0
	var g2 := (r0 - glow) * (r0 - glow)
	var h2 := (r0 + glow) * (r0 + glow)
	for y in range(lo, hi + 1):
		var dy := float(y) + 0.5 - c
		for x in range(lo, hi + 1):
			var dx := float(x) + 0.5 - c
			var d2 := dx * dx + dy * dy
			if d2 < g2 or d2 > h2:
				continue
			var d := sqrt(d2)
			var band := absf(d - r0)
			var core := clampf(th + 0.5 - band, 0.0, 1.0)
			var glo := clampf(1.0 - band / glow, 0.0, 1.0)
			var alpha := (core + glo * glo * 0.35 * (1.0 - core)) * a
			if alpha <= 0.004:
				continue
			var on := true
			if lit < 8:
				var t := fposmod(atan2(dy, dx) + PI * 0.5, TAU)
				on = int(t / seg) < lit and (gap <= 0.0 or fposmod(t, seg) < seg * (1.0 - gap))
			if not on:
				continue
			var dst := img.get_pixel(x, y)
			img.set_pixel(x, y, col.lerp(dst, 1.0 - alpha))


# Layered dark plates with a gold edge, stacked along each frame corner diagonal. `count` is the
# layers per corner (0 to 4): one layer per two restoration levels.
static func _plates_pass(img: Image, S: float, c: float, count: int) -> void:
	if count <= 0:
		return
	var hw := S * 0.034
	var hh := S * 0.016
	var edge := maxf(1.2, S * 0.0032)
	var step := S * 0.046
	var fill := Color(0.10, 0.075, 0.14)
	var gold := Color8(0xf0, 0xd6, 0x90)
	var size := img.get_width()
	var r := hw + edge + 2.0
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			# plates lie tangential to the ring, stacked along the corner diagonal like bracket layers
			var theta := sx * sy * PI * 0.25 + PI * 0.5
			var ct := cos(theta)
			var st := sin(theta)
			var ux := 0.70710678 * sx
			var uy := 0.70710678 * sy
			for k in range(count):
				var dist := S * 0.505 + float(k) * step
				var pcx := c + ux * dist
				var pcy := c + uy * dist
				var x0 := int(max(0.0, pcx - r))
				var x1 := int(min(float(size - 1), pcx + r))
				var y0 := int(max(0.0, pcy - r))
				var y1 := int(min(float(size - 1), pcy + r))
				for y in range(y0, y1 + 1):
					var dy := float(y) + 0.5 - pcy
					for x in range(x0, x1 + 1):
						var dx := float(x) + 0.5 - pcx
						var lx := dx * ct + dy * st
						var ly := -dx * st + dy * ct
						var d := maxf(absf(lx) - hw, absf(ly) - hh)
						var aa := clampf(0.5 - d, 0.0, 1.0)
						if aa <= 0.004:
							continue
						var dst := img.get_pixel(x, y)
						var out := fill if d < -edge else gold
						img.set_pixel(x, y, out.lerp(dst, 1.0 - aa))


# The visor: a white-gold slit on the bottom frame edge, widening and brightening with level, with a
# soft glow. A capsule along x: straight middle, round ends.
static func _visor_pass(img: Image, S: float, level: int, capstone: int) -> void:
	var wv := S * (0.05 + 0.023 * float(mini(level, RESTORE_MAX_LEVEL)))
	var hv := maxf(1.5, S * 0.0052)
	var cx := S * 0.5
	var cy := S * 0.956
	var size := img.get_width()
	var x0 := int(max(0.0, cx - wv - hv * 4.0))
	var x1 := int(min(float(size - 1), cx + wv + hv * 4.0))
	var y0 := int(max(0.0, cy - hv * 4.0))
	var y1 := int(min(float(size - 1), cy + hv * 4.0))
	var col := Color(1.0, 0.949, 0.784)
	var a := clampf(0.5 + 0.055 * float(mini(level, RESTORE_MAX_LEVEL)) + 0.07 * float(capstone), 0.0, 0.97)
	for y in range(y0, y1 + 1):
		var dy := float(y) + 0.5 - cy
		for x in range(x0, x1 + 1):
			var dx := absf(float(x) + 0.5 - cx)
			var qx := maxf(dx - wv + hv, 0.0)
			var d := sqrt(qx * qx + dy * dy) - hv
			var core := clampf(0.5 - d, 0.0, 1.0)
			var glo := clampf(1.0 - maxf(d, 0.0) / (hv * 3.0), 0.0, 1.0)
			var alpha := clampf((core + glo * glo * 0.4 * (1.0 - core)) * a * (0.35 + 0.65 * core), 0.0, 1.0)
			if alpha <= 0.004:
				continue
			var dst := img.get_pixel(x, y)
			img.set_pixel(x, y, col.lerp(dst, 1.0 - alpha))


static func _img(p: String) -> Image:
	var t := _tex(p)
	if t == null:
		return null
	var img := t.get_image()
	if img != null and img.is_compressed():
		img.decompress()
	return img


static func clear_static() -> void:
	_sc.clear()
	_cache.clear()
	_idx.clear()
	_rfac.clear()
