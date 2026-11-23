extends SceneTree
# Issue 1767 / R423: why Chorus hulks barely change with their albedo tint (PROPS_G, H, I, K). Headless-free GPU run:
# loads each hulk code, prints every surface material's class, flags and texture facts, the measured texture mean, and
# the derelict copy's tint and effective luminance. One line per surface: CHORUS_MAT ... ; ends with CHORUS_MAT_DONE.
const A4P := preload("res://assets/ships/a4_props.gd")

func _init() -> void:
	await process_frame
	for code in ["B20_11", "B21_11", "C14s_23", "H8_23"]:
		var n: Node3D = A4P._scene(code)
		if n == null:
			print("CHORUS_MAT code=%s missing" % code)
			continue
		root.add_child(n)
		var fac := A4P.hulk_faction(code)
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.mesh == null:
				continue
			for i in m.mesh.get_surface_count():
				var raw = m.get_active_material(i)
				var line := "CHORUS_MAT code=%s mesh=%s surf=%d class=%s" % [code, m.name, i, raw.get_class() if raw else "null"]
				if raw is BaseMaterial3D:
					var src := raw as BaseMaterial3D
					var t := src.albedo_texture
					var mean := A4P.texture_mean(src)
					var d := A4P.derelict(src, fac)
					var eff := Color(mean.r * d.albedo_color.r, mean.g * d.albedo_color.g, mean.b * d.albedo_color.b)
					line += " albedo=%s tex=%s fmt=%s mips=%s mean=%s vcol=%s emis=%s detail=%s next=%s tint=%s eff_luma=%.4f src_luma=%.4f rough=%.2f" % [
						str(src.albedo_color), (t.resource_path if t and t.resource_path != "" else ("embedded %dx%d" % [t.get_width(), t.get_height()] if t else "none")),
						(str(t.get_image().get_format()) if t and t.get_image() else "-"), (str(t.get_image().has_mipmaps()) if t and t.get_image() else "-"),
						str(mean), str(src.vertex_color_use_as_albedo), str(src.emission_enabled), str(src.detail_enabled),
						(src.next_pass.get_class() if src.next_pass else "none"), str(d.albedo_color), A4P.linear_luma(eff),
						A4P.linear_luma(Color(mean.r * src.albedo_color.r, mean.g * src.albedo_color.g, mean.b * src.albedo_color.b)), d.roughness]
				print(line)
		n.queue_free()
	print("CHORUS_MAT_DONE")
	quit(0)
