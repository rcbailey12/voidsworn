extends SceneTree
# Data and loader check only. GPU appearance is proved by planet369_bench.bat.
const PL := preload("res://world/world_planet.gd")
const WR := preload("res://world/world_rocks.gd")
const WB := preload("res://world/world_bake.gd")
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, text: String) -> void:
	print(("PASS " if ok else "FAIL ") + text)
	if not ok: failures += 1

func _run() -> void:
	var receipt = JSON.parse_string(FileAccess.get_file_as_string("res://world/rocks/SOURCES_369.json"))
	check(receipt is Dictionary and receipt.sources.size() == 10, "ten source credit records")
	var scans = JSON.parse_string(FileAccess.get_file_as_string("res://world/rocks/scans.json"))
	check(WR.scan_names().size() == 8, "eight complete scan pairs")
	var mat := WR.material("stone", {})
	var batch := WR.Batch.new()
	batch.add("scan_00",mat,false,Transform3D.IDENTITY,Vector3.UP,0.01,0.37)
	var dust: Dictionary = batch.groups.values()[0]
	check(str(dust.mesh).begins_with("frag_") and WR.mesh(dust.mesh) != null, "dust-size instance loads a rockgen mesh")
	check(dust.mat.get_shader_parameter("scanned") == false, "dust uses its procedural surface material")
	var large := WR.Batch.new()
	large.add("scan_00",mat,false,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*20),Vector3.ZERO),Vector3.UP,0.01,0.37)
	check(large.groups.values()[0].mesh == "scan_00", "large instance retains the scanned silhouette")
	for entry in scans.rocks:
		var high := WR.mesh(entry.name)
		var low := WR.mesh(entry.name + "_lo")
		check(high != null and low != null, str(entry.name) + " actual GLB loads")
		if high == null or low == null: continue
		var arrays := high.surface_get_arrays(0)
		var lo_arrays := low.surface_get_arrays(0)
		check(arrays[Mesh.ARRAY_INDEX].size() > lo_arrays[Mesh.ARRAY_INDEX].size(), str(entry.name) + " far mesh reduces triangles")
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var radius := 0.0
		for v in vertices: radius = maxf(radius, v.length())
		check(absf(radius - 1.0) < 0.001, str(entry.name) + " normalized unit radius")
		check(arrays[Mesh.ARRAY_COLOR].size() == vertices.size(), str(entry.name) + " scan colour and AO per vertex")
	var baker = WB.service(self)
	var colour: Image = await baker.authored(PL.R01_DIR + "colour.png", PL.R01_SIZE)
	var data: Image = await baker.authored(PL.R01_DIR + "relief.png", PL.R01_SIZE)
	check(colour != null and data != null, "two real 8K maps decoded by shared worker")
	if colour != null and data != null:
		check(colour.has_mipmaps() and data.has_mipmaps(), "both maps have mip chains")
		var min_h := 1.0
		var max_h := 0.0
		var clouds := 0
		var clear := 0
		for y in range(100, 4000, 151):
			for x in range(100, 8100, 137):
				var v := data.get_pixel(x,y)
				var h := (v.r*65280.0+v.g*255.0)/65535.0
				min_h = minf(min_h,h)
				max_h = maxf(max_h,h)
				if v.a > .15: clouds += 1
				if v.a < .01: clear += 1
		check(max_h-min_h > .2, "relief contains measured variation %.4f" % (max_h-min_h))
		check(clouds > 0 and clear > 0, "cloud mask has opaque and clear samples")
		var planet := MeshInstance3D.new()
		planet.mesh = SphereMesh.new()
		root.add_child(planet)
		var air := MeshInstance3D.new()
		air.mesh = SphereMesh.new()
		root.add_child(air)
		await PL.install_rocky(planet, air, Vector3(1,2,3)*1000)
		check(planet.get_meta("planet_code", "") == "R01", "R01 material installation finishes")
		check(planet.get_node_or_null("R01Clouds") != null, "moving cloud layer is a separate shell")
		check(planet.material_override.get_shader_parameter("surface_data") == planet.get_node("R01Clouds").material_override.get_shader_parameter("surface_data"), "ground shadow and clouds share one texture")
		planet.queue_free()
		air.queue_free()
	print("R01_DATA_CHECK failures=%d; GPU visuals and scale not measured here" % failures)
	quit(1 if failures else 0)
