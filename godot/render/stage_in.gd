extends RefCounted
const SKEEP := preload("res://render/shader_keep.gd")
# Issue 1434 (LOAD22): a mesh's first draw makes its pipelines ("mesh" pipelines, up to 40 ms each on a cold profile),
# so a load that adds a station and its 34 debris pieces, or a battle's effect pools, pays all of them in one draw (the
# title backdrop's 852 ms warm and 1651 ms cold frames). While a sliced load runs, every new mesh under `root` is put on
# a render layer no camera or light draws, and a few meshes with unseen materials are given their layers back after
# each draw. Meshes whose materials and vertex formats were already given back return at once, since they make no new
# pipelines. The battle drains the queue while its camera is pulled back over the whole board (scenes/battle/battle.gd
# _warmup), so each mesh's first draw is in view, and stops watching before the effect warm-up, which spreads its own.
#
# Only the instance ids are held; a mesh freed while waiting simply drops out. The rim watcher changes
# the saved layers, not the staging mask, so it cannot make a waiting painted mesh draw early.

const BIT := 1 << 19          # render layer 20: never drawn by the battle camera or its lights
const META := &"stage_in_layers"
const MAX_STEP := 16          # most new-material meshes given back in one frame
const SLOW_MS := 200.0        # a draw that showed new meshes and took longer than this drops the count back to one
const QUICK_MS := 60.0        # a draw that showed new meshes and took less than this raises it by one

var root: Node = null
var active := false
var paused := false           # true while the effect warm-up runs (it spreads its own meshes)
var step := 1                 # new-material meshes given back after the next draw (LOAD23: starting at 2 and growing on
                              # empty draws let all four effect pools out at once, 36 pipelines in a 1.3 s title frame)
var max_step := MAX_STEP
var cam: Camera3D = null      # Artoo on PR 1445: a new material comes back only on a mesh the camera sees, so it is drawn
var draining := false         # in the drain (camera pulled back over the board) every waiting mesh may come back
var _fresh_last := 0          # new-material meshes the last draw showed for the first time
var given := 0                # meshes given back so far (the load bench reads it)
var waiting_peak := 0
var late := 0                 # meshes still waiting when the drain's 10 s ran out (0: it finished)
var _queue: Array = []        # instance ids, oldest first
var _seen := {}               # material and format key -> true, already given back once
var _pre_us := 0
var _draw_ms := 0.0
var _warmed := {}            # shader variant, vertex layout and pass, local to this build


# Forward+ prepares surface pipelines even outside a camera's layers. Present a tiny triangle with
# the real vertex layout and material before the real mesh enters the scenario.
func warm_meshes(host: Node3D, nodes: Array, label: String, keep_going := Callable(), lit := false) -> bool:
	if DisplayServer.get_name() == "headless" or RenderingServer.get_current_rendering_method() != "forward_plus":
		return true
	# Directional shadow culling also checks the drawing camera's mask in Godot 4.7. Use
	# a private viewport whose camera and light both see layer 20. The live camera and
	# shadow atlas never see these triangles, and regular stage-in stays untouched.
	var viewport: SubViewport = _warm_viewport(host) if lit else null
	var warm := MeshInstance3D.new()
	warm.name = "PipelineWarm"
	warm.layers = BIT
	warm.scale = Vector3.ONE * (0.3 if lit else 0.001)
	warm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if lit else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	warm.set_meta(&"pipeline_warm", true)
	if viewport != null:
		viewport.add_child(warm)
	else:
		host.add_child(warm)
	var cleanup: Node = viewport if viewport != null else warm
	var tree := host.get_tree()
	for source in nodes:
		var mi := source as MeshInstance3D
		var mesh := (mi.mesh if mi != null else source) as ArrayMesh
		if mesh == null or (mi != null and mi.skin != null) or mesh.get_blend_shape_count() > 0:
			continue
		for surface in mesh.get_surface_count():
			var fmt := mesh.surface_get_format(surface)
			if mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
				continue
			var mat := mi.get_active_material(surface) if mi != null else mesh.surface_get_material(surface)
			if mat == null:
				continue
			var key := "%s:%d:%s" % [_warm_material_key(mat), fmt, lit]
			if _warmed.has(key):
				continue
			var proxy := _triangle(fmt)
			if proxy == null:
				continue
			warm.mesh = proxy
			warm.material_override = mat
			if viewport != null:
				viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			SKEEP.event("%s warm %s surface %d/%d (%s fmt %x)" % [
				label, mi.name if mi != null else mesh.resource_name, surface, mesh.get_surface_count(), _warm_shader_name(mat), fmt])
			await tree.process_frame
			if (not is_instance_valid(warm) or not is_instance_valid(host) or not host.is_inside_tree()
					or host.is_queued_for_deletion() or (keep_going.is_valid() and not keep_going.call())):
				if is_instance_valid(cleanup):
					cleanup.queue_free()
				return false
			_warmed[key] = true
	cleanup.queue_free()
	return true


static func _warm_viewport(host: Node3D) -> SubViewport:
	var source := host.get_viewport()
	var vp := SubViewport.new()
	vp.size = Vector2i(64, 64)
	vp.world_3d = World3D.new()
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	vp.msaa_3d = source.msaa_3d
	vp.screen_space_aa = source.screen_space_aa
	vp.use_taa = source.use_taa
	vp.scaling_3d_mode = source.scaling_3d_mode
	vp.scaling_3d_scale = source.scaling_3d_scale
	host.add_child(vp)
	var camera := Camera3D.new()
	camera.cull_mask = BIT
	camera.environment = host.get_world_3d().environment
	camera.position = Vector3(0, 0, 2)
	vp.add_child(camera)
	camera.make_current()
	var light := DirectionalLight3D.new()
	light.set_meta(&"pipeline_warm", true)
	light.light_cull_mask = BIT
	light.shadow_caster_mask = BIT
	light.shadow_enabled = true
	vp.add_child(light)
	return vp


# The PSO needs the vertex layout, not the authored data. Skip unusual formats instead of
# guessing at skin, custom attribute or 2D layouts. Those meshes still go through stage-in.
static func _triangle(fmt: int) -> ArrayMesh:
	var supported := (Mesh.ARRAY_FORMAT_VERTEX | Mesh.ARRAY_FORMAT_NORMAL | Mesh.ARRAY_FORMAT_TANGENT
		| Mesh.ARRAY_FORMAT_COLOR | Mesh.ARRAY_FORMAT_TEX_UV | Mesh.ARRAY_FORMAT_TEX_UV2 | Mesh.ARRAY_FORMAT_INDEX)
	if (fmt & ((1 << Mesh.ARRAY_MAX) - 1) & ~supported) or (fmt & Mesh.ARRAY_FLAG_USE_2D_VERTICES):
		return null
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3(0, 1, 0.1)])
	if fmt & Mesh.ARRAY_FORMAT_NORMAL:
		a[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK])
	if fmt & Mesh.ARRAY_FORMAT_TANGENT:
		a[Mesh.ARRAY_TANGENT] = PackedFloat32Array([1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1])
	if fmt & Mesh.ARRAY_FORMAT_COLOR:
		a[Mesh.ARRAY_COLOR] = PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE])
	for slot in [Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2]:
		if fmt & (1 << slot):
			a[slot] = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN])
	if fmt & Mesh.ARRAY_FORMAT_INDEX:
		a[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a, [], {}, fmt & Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES)
	return mesh if mesh.get_surface_count() == 1 else null


static func _warm_material_key(m: Material) -> String:
	var key := shader_sig(m) if m is BaseMaterial3D else _mat_key(m)
	if m is BaseMaterial3D and m.next_pass != null:
		key += "+" + _warm_material_key(m.next_pass)
	return key


static func _warm_shader_name(m: Material) -> String:
	if m is ShaderMaterial and m.shader != null:
		return "%s %08x" % [m.resource_name, m.shader.code.hash() & 0xffffffff]
	if not m is BaseMaterial3D:
		return m.get_class()
	var bits := PackedStringArray()
	for f in ["normal", "ao", "emission", "rim", "detail", "anisotropy", "clearcoat", "subsurf_scatter", "backlight"]:
		if m.get(f + "_enabled") == true:
			bits.append(f)
	return "%s [%s] alpha %d" % [m.resource_name, ",".join(bits), m.transparency]


# Material parameters (including fitted UV scale) don't make pipelines. The modes, features,
# flags and texture presence do. This only deduplicates warm jobs, never replaces live materials.
static func shader_sig(bm: BaseMaterial3D) -> String:
	var p := PackedStringArray([bm.get_class(), str(bm.transparency), str(bm.blend_mode), str(bm.cull_mode),
		str(bm.depth_draw_mode), str(bm.shading_mode), str(bm.diffuse_mode), str(bm.specular_mode), str(bm.texture_filter),
		str(bm.billboard_mode), str(bm.detail_blend_mode), str(bm.detail_uv_layer), str(bm.distance_fade_mode),
		str(bm.alpha_antialiasing_mode), str(bm.emission_operator), str(bm.texture_repeat),
		str(bm.stencil_mode), str(bm.stencil_flags), str(bm.stencil_compare)])
	var bits := ""
	for f in BaseMaterial3D.FEATURE_MAX:
		bits += "1" if bm.get_feature(f) else "0"
	bits += "|"
	for f in BaseMaterial3D.FLAG_MAX:
		bits += "1" if bm.get_flag(f) else "0"
	bits += "|"
	for t in BaseMaterial3D.TEXTURE_MAX:
		bits += "1" if bm.get_texture(t) != null else "0"
	p.append(bits)
	return ",".join(p)


func start(r: Node) -> void:
	root = r
	if active or r == null or not r.is_inside_tree():
		return
	active = true
	var tree := r.get_tree()
	if not tree.node_added.is_connected(_added):
		tree.node_added.connect(_added)
	if not RenderingServer.frame_pre_draw.is_connected(_on_pre):
		RenderingServer.frame_pre_draw.connect(_on_pre)
	if not RenderingServer.frame_post_draw.is_connected(_on_post):
		RenderingServer.frame_post_draw.connect(_on_post)


# the battle's camera and key light never draw the staging layer
static func hide_layer_from(cam: Camera3D, lights: Array) -> void:
	if cam != null:
		cam.cull_mask &= ~BIT
	for l in lights:
		if l is Light3D:
			(l as Light3D).light_cull_mask &= ~BIT
			(l as Light3D).shadow_caster_mask &= ~BIT


static func visible_layers(g: GeometryInstance3D) -> int:
	return int(g.get_meta(META)) if g.has_meta(META) and g.layers == BIT else g.layers


static func add_visible_layer(g: GeometryInstance3D, mask: int) -> void:
	if g.has_meta(META) and g.layers == BIT:
		g.set_meta(META, visible_layers(g) | mask)
	else:
		g.layers |= mask


# stop watching new meshes and give every waiting one back now (a load that ends or is stopped)
func stop() -> void:
	_unhook()
	for id in _queue:
		_give(instance_from_id(id))
	_queue.clear()
	active = false


# give the waiting meshes back over the next draws; returns once all are back, the load was stopped, or 10 s passed (then
# the rest keep coming back a step a draw, never all at once, and the load log says INCOMPLETE)
func drain(tree: SceneTree) -> void:
	if tree.node_added.is_connected(_added):
		tree.node_added.disconnect(_added)
	var t0 := Time.get_ticks_msec()
	var drawn := DisplayServer.get_name() != "headless"
	draining = true
	while not _queue.is_empty() and active and Time.get_ticks_msec() - t0 < 10000:
		await tree.process_frame
		if not drawn:
			_on_post()   # a headless sliced check (--sliced-load) draws nothing: give back a step a frame all the same
	if not active:
		return
	if _queue.is_empty():
		print("[load] stage-in drained: %d meshes given back, at most %d waiting, in %d ms" % [given, waiting_peak, Time.get_ticks_msec() - t0])
		stop()
		return
	# Artoo on PR 1445: a drain past 10 s never gives the rest back in one frame; they keep coming back a step a draw
	# while the battle goes on, and the load line says so
	late = _queue.size()
	print("[load] stage-in INCOMPLETE after %d ms: %d meshes still waiting (given back %d, at most %d waiting); the rest follow a step a draw" % [Time.get_ticks_msec() - t0, late, given, waiting_peak])
	if not drawn:
		stop()


func waiting() -> int:
	return _queue.size()


func _unhook() -> void:
	if root != null and is_instance_valid(root) and root.is_inside_tree():
		var tree := root.get_tree()
		if tree.node_added.is_connected(_added):
			tree.node_added.disconnect(_added)
	if RenderingServer.frame_pre_draw.is_connected(_on_pre):
		RenderingServer.frame_pre_draw.disconnect(_on_pre)
	if RenderingServer.frame_post_draw.is_connected(_on_post):
		RenderingServer.frame_post_draw.disconnect(_on_post)


func _added(n: Node) -> void:
	if root == null or not is_instance_valid(root) or not root.is_ancestor_of(n) or n.has_meta(&"pipeline_warm"):
		return
	if n is Light3D:
		hide_layer_from(null, [n])   # a light added during the load (the world's) never draws a waiting mesh either
		return
	if paused or not (n is GeometryInstance3D):
		return
	var g := n as GeometryInstance3D
	if g.has_meta(META) or g.layers == BIT:
		return   # re-entered while still waiting
	g.set_meta(META, g.layers)
	g.layers = BIT
	_queue.append(g.get_instance_id())
	waiting_peak = maxi(waiting_peak, _queue.size())


func _on_pre() -> void:
	_pre_us = Time.get_ticks_usec()


func _on_post() -> void:
	if _pre_us > 0:
		_draw_ms = (Time.get_ticks_usec() - _pre_us) / 1000.0
	# only a draw that showed new materials says what the next ones may cost
	if _fresh_last > 0:
		if _draw_ms > SLOW_MS:
			step = 1
		elif _draw_ms < QUICK_MS:
			step = mini(max_step, step + 1)
	var fresh := 0
	var keep: Array = []
	for id in _queue:
		var n = instance_from_id(id)
		if n == null or not is_instance_valid(n):
			continue
		var g := n as GeometryInstance3D
		var key := _key(g)
		if _seen.has(key):
			_give(g)
		elif fresh < step and (draining or _in_view(g)):
			fresh += 1
			_seen[key] = true
			_give(g)
		else:
			keep.append(id)
	_queue = keep
	_fresh_last = fresh
	if _queue.is_empty() and late > 0:
		stop()   # a drain that ran past its time has given the last ones back


func _give(n) -> void:
	if n == null or not is_instance_valid(n) or not (n is GeometryInstance3D):
		return
	var g := n as GeometryInstance3D
	if g.has_meta(META):
		if g.layers == BIT:
			g.layers = int(g.get_meta(META))
		g.remove_meta(META)
	given += 1


# what makes a mesh's pipelines: its node type, its materials and its surfaces' vertex formats
static func _key(g: GeometryInstance3D) -> String:
	var parts := PackedStringArray([g.get_class()])
	if g.material_override != null:
		parts.append(_mat_key(g.material_override))
	var mesh: Mesh = null
	if g is MeshInstance3D:
		mesh = (g as MeshInstance3D).mesh
	elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null:
		mesh = (g as MultiMeshInstance3D).multimesh.mesh
	if mesh != null:
		for i in mesh.get_surface_count():
			var m: Material = null
			if g is MeshInstance3D:
				m = (g as MeshInstance3D).get_active_material(i)
			if m == null:
				m = mesh.surface_get_material(i)
			parts.append("%s:%d" % [_mat_key(m), mesh.surface_get_format(i) if mesh is ArrayMesh else 0])
	else:
		parts.append(str(g.get_instance_id()))   # particles and others: never shared
	return "|".join(parts)


# materials of one shader share their pipelines; a standard material is keyed by itself
static func _mat_key(m: Material) -> String:
	if m == null:
		return "-"
	var k := ""
	if m is ShaderMaterial and (m as ShaderMaterial).shader != null:
		k = "s%d" % (m as ShaderMaterial).shader.get_instance_id()
	else:
		k = "m%d" % m.get_instance_id()
	if m.next_pass != null:
		k += "+" + _mat_key(m.next_pass)
	return k


# a mesh with a material not yet drawn comes back only where the camera will draw it, so the next draw makes its
# pipelines and the same-material meshes after it really find them made (Artoo on PR 1445); without a camera, always
func _in_view(g: GeometryInstance3D) -> bool:
	if cam == null or not is_instance_valid(cam) or not cam.is_inside_tree() or not g.is_inside_tree():
		return true
	var box := g.global_transform * g.get_aabb()
	if box.has_point(cam.global_position):
		return true
	for i in 8:
		if cam.is_position_in_frustum(box.get_endpoint(i)):
			return true
	return cam.is_position_in_frustum(box.get_center())
