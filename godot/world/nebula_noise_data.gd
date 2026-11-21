extends Resource
# CPU-backed 3D texture source. Baking must also work with Godot's headless renderer.
@export var side := 128
@export var seed_value := 368
@export var origin := Vector3.ZERO
@export var slices: Array[Image] = []

func texture() -> ImageTexture3D:
	var result := ImageTexture3D.new()
	if slices.is_empty() or slices.size() != side:
		push_error("Issue 368: missing noise slices")
		return null
	var error := result.create(slices[0].get_format(), side, side, side, false, slices)
	if error != OK:
		push_error("Issue 368: cannot upload noise texture: %s" % error)
		return null
	return result
