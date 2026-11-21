extends RefCounted
## Optional local cache of unposed fitted shield surfaces. The hull and its pose
## still decide the live mesh and hit collider in fx_ship.gd.

const DIRECTORY := "user://shield_skins"
# Bump when the bake or the file layout changes. Old entries are never selected.
const VERSION := "2"
const MAX_BYTES := 32 * 1024 * 1024


static func key_for(box: AABB, faces: PackedVector3Array) -> String:
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(var_to_bytes([VERSION, Engine.get_version_info()["string"], box]))
	digest.update(faces.to_byte_array())
	return digest.finish().hex_encode()


static func read_skin(key: String) -> Array:
	var file := FileAccess.open(_path(key), FileAccess.READ)
	if file == null or file.get_length() < 32 or file.get_length() > MAX_BYTES:
		return []
	var checksum := file.get_buffer(32)
	var bytes := file.get_buffer(file.get_length() - 32)
	if checksum != _checksum(key, bytes):
		return []
	var data = bytes_to_var(bytes)
	if not data is Array or data.size() != Mesh.ARRAY_MAX:
		return []
	var vertices = data[Mesh.ARRAY_VERTEX]
	var normals = data[Mesh.ARRAY_NORMAL]
	var indices = data[Mesh.ARRAY_INDEX]
	if not vertices is PackedVector3Array or not normals is PackedVector3Array or not indices is PackedInt32Array:
		return []
	if vertices.is_empty() or vertices.size() != normals.size() or indices.is_empty() or indices.size() % 3 != 0:
		return []
	return data


static func write_skin(key: String, arrays: Array) -> void:
	var bytes := var_to_bytes(arrays)
	if bytes.size() + 32 > MAX_BYTES:
		return
	if DirAccess.make_dir_recursive_absolute(DIRECTORY) != OK:
		return
	var path := _path(key)
	var temp := "%s.%d.%d.tmp" % [path, OS.get_process_id(), Time.get_ticks_usec()]
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return
	var written := file.store_buffer(_checksum(key, bytes)) and file.store_buffer(bytes)
	file.flush()
	file.close()
	if not written or DirAccess.rename_absolute(temp, path) != OK:
		DirAccess.remove_absolute(temp)


static func _path(key: String) -> String:
	return DIRECTORY.path_join(key + ".bin")


static func _checksum(key: String, bytes: PackedByteArray) -> PackedByteArray:
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(key.to_ascii_buffer())
	digest.update(bytes)
	return digest.finish()
