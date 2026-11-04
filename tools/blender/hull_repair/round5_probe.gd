extends "res://round4_probe.gd"
# Keep the round 4 cameras and bench. Extra masks exclude sky and stars.

func run() -> void:
	await super.run()
	var path := str(cfg["work"]).path_join("gpu.json")
	var result: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	result["active_probe_sha256"]=FileAccess.get_sha256("res://round5_probe.gd")
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  ")+"\n");file.close()


func snap(label: String) -> void:
	await super.snap(label)
	if not label.begins_with("C19_51_") or not (label.ends_with("_battle") or label.ends_with("_close")):return
	var saved: Array = []
	var white := StandardMaterial3D.new()
	white.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color=Color.WHITE
	for mi in nodes(holder):
		for i in mi.mesh.get_surface_count():
			saved.append([mi,i,mi.get_surface_override_material(i)])
			mi.set_surface_override_material(i,white)
	var we: WorldEnvironment
	for child in world.get_children():
		if child is WorldEnvironment:we=child
	var previous := we.environment
	var flat := Environment.new()
	flat.background_mode=Environment.BG_COLOR
	flat.background_color=Color.BLACK
	we.environment=flat
	await settle(4)
	await super.snap(label+"_mask")
	if label.begins_with("C19_51_V1_") or label.begins_with("C19_51_V2_"):
		var shader := Shader.new()
		shader.code="shader_type spatial; render_mode unshaded; uniform sampler2D light_map : source_color; void fragment(){vec3 e=texture(light_map,UV).rgb;ALBEDO=vec3(step(0.01,max(e.r,max(e.g,e.b))));}"
		var empty := Image.create(1,1,false,Image.FORMAT_RGB8)
		empty.fill(Color.BLACK)
		var black := ImageTexture.create_from_image(empty)
		for row in saved:
			var mat := ShaderMaterial.new();mat.shader=shader
			var original: BaseMaterial3D = row[2]
			mat.set_shader_parameter("light_map",original.emission_texture if original.emission_texture!=null else black)
			row[0].set_surface_override_material(row[1],mat)
		await settle(4)
		await super.snap(label+"_emission_mask")
	for row in saved:row[0].set_surface_override_material(row[1],row[2])
	we.environment=previous
	await settle(4)
