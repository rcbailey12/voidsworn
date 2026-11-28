# Issue 2029 (rock scatter): the map's region rocks use all three rock finishes, chosen by a stable rule, not finish 0 for every mesh.
#   godot --headless --path godot --script res://ui/campaign/test/rock_finish_2029_test.gd
# Builds real region rock fields (ui/campaign/map3d_props.gd region_rocks) and reads the "kind" each scatter's material carries.
# Checks: one field shows all three finishes; the same field seed gives the same finishes twice; neighbouring field seeds
# differ; the rocks' positions and counts are the ones the map's own random stream gives, finishes or not.
extends SceneTree
@warning_ignore_start("untyped_declaration", "unsafe_method_access", "unsafe_call_argument", "inference_on_variant", "unsafe_property_access")
const Props = preload("res://ui/campaign/map3d_props.gd")
const System = preload("res://ui/campaign/map3d_system.gd")
var fails := 0

func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok: fails += 1

# kinds of one field, per scatter in build order, and the instance positions
func _field(field_seed: int) -> Array:
	var sys = System.new(); var rng := RandomNumberGenerator.new(); rng.seed = 424242
	sys.rng = rng; sys.q = 0.0
	var props = Props.new(sys)
	var parent := Node3D.new(); root.add_child(parent)
	props.region_rocks(parent, 22, 3.5, field_seed)
	var kinds := []; var spots := []
	for n in parent.get_children():
		kinds.append(int(round(float((n.material_override as ShaderMaterial).get_shader_parameter("kind")))))
		var mm: MultiMesh = n.multimesh
		for i in mm.instance_count: spots.append(mm.get_instance_transform(i).origin)
	parent.queue_free()
	return [kinds, spots]

func _run() -> void:
	var a = _field(0); var b = _field(0); var c = _field(1); var d = _field(2)
	var kinds: Array = a[0]
	_check(kinds.size() > 3, "the field builds one scatter per rock mesh (%d)" % kinds.size())
	var seen := {}
	for k in kinds: seen[k] = true
	_check(seen.has(0) and seen.has(1) and seen.has(2), "all three finishes appear in one field (%s)" % str(kinds))
	_check(a[0] == b[0] and a[1] == b[1], "the same field seed builds the same finishes and positions twice")
	_check(a[0] != c[0] and c[0] != d[0] and a[0] != d[0], "fields with other seeds rotate the finishes (%s, %s, %s)" % [str(a[0]), str(c[0]), str(d[0])])
	_check(a[1] == c[1] and a[1] == d[1], "positions and counts do not depend on the finishes")
	var even := true
	for f in [0, 1, 2]:
		if kinds.count(f) != kinds.size() / 3: even = false
	_check(even, "the three finishes share the meshes evenly")
	print("rock_finish_2029_test: %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)
