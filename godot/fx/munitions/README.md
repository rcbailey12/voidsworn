# Munition bodies (issue 1379)

`<faction>_<look>.glb` are built by `tools/blender/build_sheets/munitions/munitions.py`. Each has a committed `.glb.import`
with `gltf/embedded_image_handling=2` (embed as Basis Universal, with mipmaps), so a Godot import never writes the maps out
as loose image files here. Any image file in this folder is somebody's work: PC jobs keep it, never clean it up
(Artoo on PR 1529). A new body gets its own `.glb.import` with the same setting (`git add -f`, since `*.import` is ignored).
