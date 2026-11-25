extends SceneTree

const FX := preload("res://fx/fx.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const THORN := preload("res://fx/fx_acid_thorn.gd")
const SH := preload("res://fx/fx_shaders.gd")
const POOLS := preload("res://fx/fx_pool.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")
const EPS := 0.002

# kind, weapon id, faction, moving pool layers, solid bodies
const CASES := {
	"macro": ["battery", "battery", "voidsworn", 1, 0],
	"auto": ["battery", "autocannon", "corsair", 4, 0],
	"junk": ["battery", "turret", "corsair", 1, 0],
	"las": ["battery", "turret", "hegemony", 1, 0],
	"plasma_cannon": ["battery", "laser", "hegemony", 2, 0],
	"plasma": ["battery", "turbo", "voidsworn", 2, 0],
	"scatter": ["battery", "scatter", "corsair", 6, 0],
	"prism": ["battery", "shard", "ithar", 6, 0],
	"torp": ["torp", "torp", "voidsworn", 0, 1],
	"rockets": ["torp", "htorp", "corsair", 0, 4],
	"star": ["torp", "startorp", "ithar", 0, 1],
	"flak": ["flak", "flak", "voidsworn", 3, 0],
	"pflak": ["flak", "flak", "hegemony", 4, 0],
	"spores": ["flak", "flak", "chorus", 4, 0],
	"mflak": ["flak", "flak", "ithar", 4, 0],
	"gflak": ["flak", "flak", "deathless", 4, 0],
	"gsentry": ["flak", "gsentry", "deathless", 2, 0],
	"spine": ["bio", "bioplasma", "chorus", 1, 0],
	"tendril": ["bio", "tendril", "chorus", 0, 1],
	"gauss": ["gauss", "gauss", "deathless", 1, 0],
	"guns": ["sq", "guns", "hegemony", 9, 0],
	"bombs": ["sq", "bombs", "voidsworn", 3, 0],
	"sporeb": ["sq", "sporeb", "chorus", 3, 0],
}

var failures := 0


func _init() -> void:
	GUARD.arm(self, "projectile_contact_check")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("projectile contact: " + label)


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var fx := FX.new()
	fx.manual = true
	world.add_child(fx)
	fx.setup({"quality": "high", "shake": 1.0})
	var hull = _target(world, fx, "hull", false)
	var shield = _target(world, fx, "shield", true)
	fx.step(0.5)
	_check(shield._shield_mat != null and not hull.shielded, "shield and hull fixtures")
	for lk in CASES:
		_case(fx, shield, lk, "shield")
		await process_frame
		_case(fx, hull, lk, "hull")
		await process_frame
	_case(fx, shield, "tendril", "break through")
	await process_frame
	_case(fx, shield, "torp", "break through")
	_check(SH.SPRITE.contains("vPastContact > 0.0") and SH.SPRITE.contains("scene_t >= -a4.x"),
		"the sprite shader clips the billboard and switches it off at the packed contact time")
	_check(SH.STREAK.contains("scene_t >= -a4.x"), "the streak shader switches off at the packed contact time")
	_check(SH.NULL_SLUG.contains("s > 1.0") and SH.NULL_SLUG.contains("scene_t < vShape.z"),
		"the gauss shader clips the wake and switches off only its head at contact")
	_check(WEAP.kit_trail_shader_code().contains("wp -= contact_plane.xyz"), "the kit trail clips its drawn width")
	world.free()
	FX.clear_static()
	print("PROJECTILE_CONTACT %d weapon looks, %d shield and hull cases, %d failures" % [CASES.size(), CASES.size() * 2 + 2, failures])
	quit(0 if failures == 0 else 1)


func _target(world: Node3D, fx: Node3D, id: String, shielded: bool):
	var ship_root := Node3D.new()
	ship_root.name = id
	ship_root.position = Vector3(3, 4, 19)
	world.add_child(ship_root)
	var model := Node3D.new()
	model.name = "hull_pivot"
	ship_root.add_child(model)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(14, 3, 4.2)
	mesh.mesh = box
	model.add_child(mesh)
	fx.add_ship(id, ship_root, {"faction": "hegemony", "cls": "Cruiser", "size": 1.0, "shielded": shielded})
	return fx.ship(id)


func _case(fx: FX, target, lk: String, route: String) -> void:
	var label := lk + " " + route
	var spec: Array = CASES[lk]
	var shield_only := route == "shield"
	var breaking := route == "break through"
	var from := Vector3(-8, 5, -19)
	var frame: Transform3D = target.xf()
	var origin: float = fx.now
	var marks: int = target._mark_n
	var root_xf: Transform3D = target.root.global_transform
	var plate_count: int = fx.pools["plate"].emitted
	# Read the actual render packet before the pool uploads it, without retaining a parallel flight model.
	for key in ["spr", "smk", "stk", "null", "shd"]:
		var pool: POOLS.Pool = fx.pools[key]
		pool.flush()
		pool.head = 0
	_check(WEAP.look_of(spec[0], spec[1], spec[2]) == lk, label + " fixture selects the right look")
	var volley := WEAP._volley(fx, null, from, spec[0], target, frame * target.hull.c, {
		"weapon_id": spec[1], "faction": spec[2], "shots": [true],
		"hits": [{"shield": 8 if shield_only or breaking else 0, "hull": 0 if shield_only else 12, "section": "mid"}],
		"break_k": 0 if breaking else -1})
	var p: Vector3 = volley["points"][0]
	var impact: float = origin + float(volley["impacts"][0])
	var at := impact + (WEAP.BREAK_HULL_BEAT if breaking else 0.0)
	if shield_only:
		var local: Vector3 = volley["hit_pts"][0]
		_check(p.distance_to(frame * (local + target.hull.shield_centre())) < EPS, label + " aims at the shield ripple")
	else:
		_check(target.hull.box.grow(EPS).has_point(frame.affine_inverse() * p), label + " aims at the hull")
	_check(_packets(fx, p, at, label) == int(spec[3]), label + " all moving pooled layers end at contact")
	_check(_has_pop(fx, p, at), label + " has a pop at the projectile's exact point and time")
	if lk == "tendril":
		_check(fx.pools["plate"].emitted == plate_count, label + " has no metal plating debris")
		_check(fx.pools["shd"].n_pending == (3 if shield_only else 4), label + " throws only a few bone and horn chips")
	var solid_key := "thorn_proj" if lk == "tendril" else "proj"
	var bodies: Array = fx.dstate.get(solid_key, []).duplicate()
	_check(bodies.size() == int(spec[4]), label + " number of solid bodies")
	if not bodies.is_empty():
		fx.now = at - 0.10
		fx.step(0.0)
	fx.now = at - 0.02
	fx.step(0.0)
	if lk == "torp" and shield_only:
		fx.hit_pause(fx.now, 4)
		fx.step(0.0)
		fx.step(1.0 / 60.0)
		_check(fx.now < at, label + " remains on approach during the prior hit pause")
	if breaking:
		_check(fx.now > impact and target._mark_n == marks, label + " holds the hull hit until after the shield break")
	for body in bodies:
		var node: Node3D = body.get("node", body.get("mesh"))
		_check(is_instance_valid(node) and node.is_visible_in_tree(), label + " body still draws on approach")
		_check(_front(body, node, p, lk) <= EPS, label + " the drawn front does not cross contact on approach")
	fx.now = at
	fx.step(0.0)
	if shield_only:
		_check(target._mark_n == marks and not target._show_rcs and target._power_dip == 0.0 and target._stutter_until < at,
			label + " ordinary block does not mark, spray thrusters, stutter or brown out")
		_check(absf(target._hits[target._hit_i].w - at) < EPS, label + " ripples at contact")
	else:
		_check(target._mark_n > marks, label + " marks the hull on contact")
		var last_hit: Array = target.get_meta("last_hit", [])
		_check(not last_hit.is_empty() and (frame * (last_hit[0] as Vector3)).distance_to(p) < EPS, label + " uses the same point as the hull hit")
	_check(target.root.global_transform.is_equal_approx(root_xf), label + " keeps the ship marker root flat")
	for body in bodies:
		var node: Node3D = body.get("node", body.get("mesh"))
		_check(is_instance_valid(node) and not node.is_visible_in_tree() and node.is_queued_for_deletion(),
			label + " hides the body and its attached drive/light immediately")
		if is_instance_valid(node):
			_check(absf(_front(body, node, p, lk)) < EPS, label + " nose ends on contact")
	_check(fx.dstate.get(solid_key, []).is_empty(), label + " no active solid bodies at impact")
	for trail in fx.dstate.get("ptrails", []):
		var mat: ShaderMaterial = trail["mi"].material_override
		var plane: Vector4 = mat.get_shader_parameter("contact_plane")
		var normal := Vector3(plane.x, plane.y, plane.z)
		_check(absf(normal.length() - 1.0) < EPS and absf(normal.dot(p) - plane.w) < EPS, label + " fading kit trail is clipped at contact")
		for sample in trail["hist"]:
			_check(normal.dot(sample[0]) <= plane.w + EPS, label + " no trail sample beyond contact")
	fx.now = at + 0.9
	fx.step(0.0)
	_check(fx.dstate.get(solid_key, []).is_empty() and fx.dstate.get("ptrails", []).is_empty(), label + " stays gone after impact")


func _front(body: Dictionary, node: Node3D, p: Vector3, lk: String) -> float:
	if lk == "tendril":
		var tip := node.global_transform * (Vector3.RIGHT * THORN.TIP)
		return (tip - p).dot(body["dir"])
	var maximum := -INF
	var bounds: AABB = node.get_meta("solid_bounds")
	for i in 8:
		var offset := node.global_transform * bounds.get_endpoint(i) - p
		maximum = maxf(maximum, offset.dot(body["axis"]))
	return maximum


func _packets(fx: FX, contact: Vector3, at: float, label: String) -> int:
	var count := 0
	for key in ["spr", "smk", "stk", "null"]:
		var pool: POOLS.Pool = fx.pools[key]
		for j in range(0, pool.pending.size(), pool.vpp * POOLS.STRIDE):
			var start := Vector3(pool.pending[j + 4], pool.pending[j + 5], pool.pending[j + 6])
			var born: float = pool.pending[j + 7]
			var speed := Vector3(pool.pending[j + 8], pool.pending[j + 9], pool.pending[j + 10])
			var cutoff: float = -pool.pending[j]
			if cutoff <= 0.0:
				continue
			_check(absf(cutoff - at) < EPS and born < cutoff, label + " render packet uses the contact clock")
			if speed.is_zero_approx(): # stationary plasma shimmer, not a body
				continue
			var life: float = pool.pending[j + 11]
			var end := start + speed * life
			if key == "null":
				life = pool.pending[j + 18]
				end = start + speed * pool.pending[j + 16]
			_check(absf(born + life - at) < EPS and end.distance_to(contact) < EPS, label + " moving render packet ends at contact")
			count += 1
	return count


func _has_pop(fx: FX, contact: Vector3, at: float) -> bool:
	var pool: POOLS.Pool = fx.pools["spr"]
	for j in range(0, pool.pending.size(), pool.vpp * POOLS.STRIDE):
		var p := Vector3(pool.pending[j + 4], pool.pending[j + 5], pool.pending[j + 6])
		if pool.pending[j + 18] == 0.0 and absf(pool.pending[j + 7] - at) < EPS and p.distance_to(contact) < EPS:
			return true
	return false
