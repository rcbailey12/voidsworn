extends "res://round6_base_game.gd"
# Godot's runtime GLB import leaves the authored specular extension at 0.5.
# Match the exported coat parameter for prototypes in this private project.
var import_audit: Array = []


func maps(ship) -> void:
	super.maps(ship)
	var desired := float(cfg["coat_specular_ior_level"])
	var rows: Array = []
	for mi in ship.meshes:
		for i in mi.mesh.get_surface_count():
			var mat: BaseMaterial3D=mi.get_active_material(i)
			var imported := mat.metallic_specular
			mat.metallic_specular=desired
			rows.append({"raw_import_specular":imported,"specular":mat.metallic_specular})
	import_audit.append({"route":cfg["routes"][import_audit.size()+1],"materials":rows})
	var file := FileAccess.open(str(cfg["work"]).path_join("game_material_import.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"rows":import_audit,"probe_sha256":FileAccess.get_sha256("res://round6_game.gd")},"  ")+"\n")
	file.close()
