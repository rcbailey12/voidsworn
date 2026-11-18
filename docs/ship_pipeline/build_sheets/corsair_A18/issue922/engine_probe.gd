extends SceneTree
# Issue 922: exported A18 under the production light and engine effect.
# This loads the checked export directly, so the pictures are paint proofs.
const FX = preload("res://fx/fx.gd")
const LOOK = preload("res://render/look.gd")
const GUARD = preload("res://tools/ci/check_guard.gd")
const PROVENANCE = preload("res://tools/picture_provenance.gd")
var viewport: SubViewport
var camera: Camera3D

class ProbeShip extends Node3D:
    var engines: Array = []
    var code: String = "C13s_23"

func _init() -> void:
    GUARD.arm(self, "A18_engine_probe")
    process_frame.connect(run, CONNECT_ONE_SHOT)

func capture(path: String, crop: Rect2i) -> void:
    for frame in 6:
        await RenderingServer.frame_post_draw
    var image := viewport.get_texture().get_image()
    if crop.has_area():
        image = image.get_region(crop)
    var error := PROVENANCE.save_png(image, path, "paint proof")
    assert(error == OK, "A18 capture could not save")

func run() -> void:
    seed(922)
    var out := OS.get_environment("A18_PROBE_OUT")
    var context := PROVENANCE._context()
    var asset_source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("A18_PROBE_SOURCE")))
    context.merge(asset_source, true)
    PROVENANCE._contexts[OS.get_environment("PICTURE_SOURCE_REPO")] = context
    DirAccess.make_dir_recursive_absolute(out)
    viewport = SubViewport.new()
    viewport.size = Vector2i(1920, 1080)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var world := Node3D.new()
    viewport.add_child(world)
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(.004, .004, .005)
    var environment_node := WorldEnvironment.new()
    environment_node.environment = environment
    world.add_child(environment_node)
    var key := DirectionalLight3D.new()
    world.add_child(key)
    var fill := DirectionalLight3D.new()
    world.add_child(fill)
    LOOK.apply(environment, key, fill)
    camera = Camera3D.new()
    camera.fov = 45
    world.add_child(camera)
    var document := GLTFDocument.new()
    var state := GLTFState.new()
    var error := document.append_from_file(OS.get_environment("A18_PROBE_GLB"), state)
    assert(error == OK, "A18 checked export could not load")
    var ship := ProbeShip.new()
    world.add_child(ship)
    var model := document.generate_scene(state)
    ship.add_child(model)
    model.scale = Vector3.ONE * 6.5
    var meshes: Array = model.find_children("*", "MeshInstance3D", true, false)
    if model is MeshInstance3D:
        meshes.push_front(model)
    var surfaces := 0
    var triangles := 0
    for mesh in meshes:
        for index in mesh.mesh.get_surface_count():
            mesh.set_surface_override_material(index, LOOK.hull(mesh.mesh.surface_get_material(index), "corsair", true))
            surfaces += 1
            var arrays = mesh.mesh.surface_get_arrays(index)
            triangles += arrays[Mesh.ARRAY_INDEX].size() / 3 if arrays[Mesh.ARRAY_INDEX].size() else arrays[Mesh.ARRAY_VERTEX].size() / 3
    var fx := FX.new()
    world.add_child(fx)
    fx.manual = true
    fx.setup({"camera": camera, "quality": "max", "starboard_z": 1})
    fx.add_ship("A18", ship, {"faction": "corsair", "cls": "Frigate", "size": .5, "meshes": meshes, "shielded": false})
    fx.set_engine("A18", 1.0)
    var hull = fx.ships["A18"].hull
    var hardpoints := model.find_children("hp_eng*", "Node3D", true, false).size()
    assert(hardpoints == 3 and hull.nozzles_from_kit and hull.nozzles.size() == 3,
           "A18 must draw three engines at the authored bells")
    var centre: Vector3 = ship.to_global(hull.c)
    camera.look_at_from_position(centre + Vector3(0, cos(.98), sin(.98)) * 170, centre)
    for frame in 12:
        fx.step(1.0 / 60)
        await process_frame
    await capture(out.path_join("A18_game_camera170.png"), Rect2i(640, 360, 640, 360))
    var battle_draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
    viewport.size = Vector2i(1280, 720)
    camera.look_at_from_position(centre + Vector3(-1.1, .55, .8).normalized() * 13, centre)
    await capture(out.path_join("A18_game_engines.png"), Rect2i())
    var file := FileAccess.open(out.path_join("readback.json"), FileAccess.WRITE)
    file.store_string(JSON.stringify({"result": "PASS", "engine_hardpoints": hardpoints,
        "nozzles_from_kit": hull.nozzles_from_kit, "effect_nozzles": hull.nozzles.size(),
        "triangles": triangles, "surfaces": surfaces, "battle_draw_calls_whole_probe": battle_draws,
        "camera_distance": 170, "camera_pitch": .98, "viewport": [1920, 1080],
        "camera170_crop": [640, 360], "stage": "paint proof"}, "  "))
    print("PASS A18 engine readback: 3 authored bells, %d triangles, %d surfaces" % [triangles, surfaces])
    fx.remove_ship("A18")
    await process_frame
    quit(0)
