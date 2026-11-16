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
	var bake = JSON.parse_string(FileAccess.get_file_as_string(PL.R01_DIR + "bake.json"))
	var files_ok: bool = bake.files.size() == 48
	for file in bake.files:
		var bytes := FileAccess.get_file_as_bytes(PL.R01_DIR + str(file))
		var h := HashingContext.new()
		h.start(HashingContext.HASH_SHA256)
		h.update(bytes)
		files_ok = files_ok and bytes.size() <= 8000000 and bytes.size() == int(bake.files[file].bytes) and h.finish().hex_encode() == str(bake.files[file].sha256)
	check(files_ok, "all 48 shipped tiles match their hashes and the 8 MB file limit")
	var total := 0
	for entry in bake.files.values(): total += int(entry.bytes)
	check(total > 0 and total <= 40000000, "complete R01 texture package below 40 MB: %d bytes" % total)
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
	var colour: Image = await baker.authored(PL.R01_DIR + "colour.json", PL.R01_SIZE)
	var data: Image = await baker.authored(PL.R01_DIR + "relief.json", PL.R01_SIZE, true)
	check(colour != null and data != null, "two real 8K maps decoded by shared worker")
	if colour != null and data != null:
		for name in ["colour", "relief", "roughness"]:
			var assembled: Image = await baker.authored(PL.R01_DIR + name + ".json", PL.R01_SIZE, name == "relief")
			var desc = JSON.parse_string(FileAccess.get_file_as_string(PL.R01_DIR + name + ".json"))
			var h := HashingContext.new()
			h.start(HashingContext.HASH_SHA256)
			var pixels := assembled.duplicate() as Image if assembled != null else null
			if pixels != null:
				pixels.clear_mipmaps()
				pixels.convert(int(desc.format))
				h.update(pixels.get_data())
			check(pixels != null and h.finish().hex_encode() == str(desc.pixel_sha256), name + " assembled pixels match the encoded 8K reference")
		check(colour.has_mipmaps() and data.has_mipmaps(), "both maps have mip chains")
		check(data.get_format() == Image.FORMAT_RGBAF, "packed height uses float mipmaps instead of byte-rounded height steps")
		var mip_size := data.get_size()/8
		var offset := data.get_mipmap_offset(3)
		var mip := Image.create_from_data(mip_size.x,mip_size.y,false,data.get_format(),data.get_data().slice(offset,offset+mip_size.x*mip_size.y*16))
		var mip_error := 0.0
		for y in range(19,mip_size.y-1,71):
			for x in range(17,mip_size.x-1,113):
				var average := 0.0
				for dy in 8:
					for dx in 8:
						var v := data.get_pixel(x*8+dx,y*8+dy)
						average += (v.r*65280.0+v.g*255.0)/65535.0/64.0
				var v := mip.get_pixel(x,y)
				mip_error = maxf(mip_error,absf((v.r*65280.0+v.g*255.0)/65535.0-average))
		check(mip_error < 1.0/65535.0, "mip heights match the 64 source heights within one 16-bit step; error %.9f" % mip_error)
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
