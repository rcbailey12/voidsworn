# Issue 1451 (R378, RULEBOOK 9.18): a battle's whole rules state as bytes, so a campaign battle can be saved at the start of each
# round and resumed there with the same dice.
#
# The rules state is a graph of plain Dictionaries and Arrays in which the same container is often reached twice: a unit is in
# B.units and in B.activeUnit or B.aiFocus, a player unit holds the campaign ship that also sits in RUN.fleet (the campaign settles
# HP, XP and losses through that shared ship, by identity), B.map is TERRAIN_META. JSON (and var_to_bytes) would copy each one,
# so pack() writes every container once, numbered, and each further reference to it as a number. unpack() rebuilds the same
# sharing. Numbers keep their exact type and bits (var_to_bytes), and key order is kept, so iteration order does not change.
#
# How a container is recognised the second time: Godot compares Dictionaries and Arrays by value, so there is no identity map. While
# packing, each Dictionary gets one extra key (TAG) and each Array one extra last element holding its number; both are removed
# before pack() returns. Typed, read-only and typed-key containers cannot take the mark and are written as plain values (no
# sharing kept); the rules do not share any.
extends RefCounted
@warning_ignore_start("untyped_declaration", "unsafe_method_access", "unsafe_call_argument", "inference_on_variant")

const MAGIC := 0x51A9E   # never a real value in the rules state (pack() refuses a Vector4i that starts with it)
const TAG := Vector4i(MAGIC, -1, 0, 0)
const K_REF := 1          # Vector4i(MAGIC, index, K_REF, 0): a reference to container <index>
const K_MARK := 7         # the temporary last element of an Array being packed
const K_TYPED := 9        # first element of a typed Array node: [Vector4i(MAGIC, builtin, K_TYPED, 0), values...]

# -> {"bytes": PackedByteArray, "containers": int, "dropped": int} or {"error": String}
static func pack(root) -> Dictionary:
	var ctx := {"nodes": [], "marked": [], "err": "", "dropped": 0}
	var top = _enc(root, ctx)
	for c in ctx["marked"]:   # always unmark, even after an error
		if c is Dictionary: c.erase(TAG)
		else: c.pop_back()
	if ctx["err"] != "": return {"error": ctx["err"]}
	var raw := var_to_bytes([top, ctx["nodes"]])
	return {"bytes": raw.compress(FileAccess.COMPRESSION_ZSTD), "size": raw.size(), "containers": ctx["nodes"].size(), "dropped": ctx["dropped"]}

static func _is_mark(v) -> bool:
	return v is Vector4i and v.x == MAGIC

static func _enc(v, ctx: Dictionary):
	if ctx["err"] != "": return null
	match typeof(v):
		TYPE_DICTIONARY:
			var d: Dictionary = v
			if d.has(TAG): return Vector4i(MAGIC, int(d[TAG]), K_REF, 0)
			var idx: int = ctx["nodes"].size()
			ctx["nodes"].append(null)
			var plain := d.is_read_only() or d.is_typed()
			if not plain:
				d[TAG] = idx; ctx["marked"].append(d)
			var o := {}
			for k in d.keys():
				if not plain and k is Vector4i and k == TAG: continue
				if typeof(k) in [TYPE_DICTIONARY, TYPE_ARRAY, TYPE_OBJECT, TYPE_CALLABLE] or _is_mark(k):
					ctx["err"] = "a dictionary key of type %s cannot be saved" % type_string(typeof(k)); return null
				var x = d[k]
				if typeof(x) == TYPE_CALLABLE:   # as the campaign save does (campaign.gd _enc): a function value is not state
					ctx["dropped"] += 1; continue
				o[k] = _enc(x, ctx)
			ctx["nodes"][idx] = o
			return Vector4i(MAGIC, idx, K_REF, 0)
		TYPE_ARRAY:
			var a: Array = v
			if not a.is_empty() and _is_mark(a[a.size() - 1]) and a[a.size() - 1].z == K_MARK: return Vector4i(MAGIC, a[a.size() - 1].y, K_REF, 0)
			var idx: int = ctx["nodes"].size()
			ctx["nodes"].append(null)
			var typed := a.is_typed()
			var plain := typed or a.is_read_only()
			var n := a.size()
			if not plain:
				a.append(Vector4i(MAGIC, idx, K_MARK, 0)); ctx["marked"].append(a)
			var o := []
			if typed:
				if a.get_typed_builtin() == TYPE_OBJECT:
					ctx["err"] = "an Array of objects cannot be saved"; return null
				o.append(Vector4i(MAGIC, a.get_typed_builtin(), K_TYPED, 0))
			for i in range(n):
				o.append(_enc(a[i], ctx))
			ctx["nodes"][idx] = o
			return Vector4i(MAGIC, idx, K_REF, 0)
		TYPE_VECTOR4I:
			if _is_mark(v): ctx["err"] = "a value looks like a snapshot mark"; return null
			return v
		TYPE_OBJECT, TYPE_CALLABLE, TYPE_SIGNAL, TYPE_RID:
			ctx["err"] = "a value of type %s cannot be saved" % type_string(typeof(v)); return null
	return v   # numbers, strings, StringNames, vectors and packed arrays are values: var_to_bytes keeps them exactly

# -> {"root": Variant} or {"error": String}
static func unpack(bytes: PackedByteArray, size: int) -> Dictionary:
	if bytes.is_empty(): return {"error": "empty snapshot"}
	var raw := bytes.decompress(size, FileAccess.COMPRESSION_ZSTD)
	if raw.size() != size: return {"error": "snapshot does not unpack"}
	var top = bytes_to_var(raw)
	if not (top is Array and top.size() == 2 and top[1] is Array): return {"error": "snapshot has the wrong shape"}
	var nodes: Array = top[1]
	var made := []
	made.resize(nodes.size())
	for i in range(nodes.size()):   # the containers first, so references (and cycles) can point at any of them
		var nd = nodes[i]
		if nd is Dictionary: made[i] = {}
		elif nd is Array:
			if not nd.is_empty() and _is_mark(nd[0]) and nd[0].z == K_TYPED: made[i] = Array([], nd[0].y, &"", null)
			else: made[i] = []
		else: return {"error": "snapshot container %d is damaged" % i}
	for i in range(nodes.size()):
		var nd = nodes[i]
		if nd is Dictionary:
			var o: Dictionary = made[i]
			for k in nd.keys(): o[k] = _dec(nd[k], made)
		else:
			var o: Array = made[i]
			var s := 1 if (not nd.is_empty() and _is_mark(nd[0]) and nd[0].z == K_TYPED) else 0
			for j in range(s, nd.size()): o.append(_dec(nd[j], made))
	return {"root": _dec(top[0], made)}

static func _dec(v, made: Array):
	if v is Vector4i and v.x == MAGIC and v.z == K_REF: return made[v.y]
	return v
