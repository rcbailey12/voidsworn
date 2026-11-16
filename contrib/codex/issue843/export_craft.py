"""Export the unchanged issue 793 sheet craft for the formation capture.

Blender --background --python export_craft.py -- SOURCE_ROOT OUTPUT_DIR
SOURCE_ROOT holds the issue 793 version of tools/blender, extracted to TEMP.
No paint, shape or build sheet changes are made by this helper.
"""
import importlib.util
import json
from pathlib import Path
import sys

import bpy

source, output = map(Path, sys.argv[sys.argv.index('--') + 1:])
output.mkdir(parents=True, exist_ok=True)
sheets = source / 'tools/blender/build_sheets'
sys.path.insert(0, str(sheets))
import kit

for code in ['corsair_KB1CC', 'hegemony_HF1D', 'voidsworn_SF3', 'voidsworn_SB4']:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    spec = importlib.util.spec_from_file_location(code, sheets / 'ships' / (code + '.py'))
    design = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(design)
    kit.use_kit(design.KIT)
    built = kit.Kit(code, design.LENGTH)
    design.build(built)
    built.finish()
    bpy.ops.object.select_all(action='DESELECT')
    for obj in built.coll.objects:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(output / (code + '.glb')),
                              export_format='GLB', use_selection=True,
                              export_cameras=False, export_lights=False)
    (output / (code + '.json')).write_text(json.dumps({'length': design.LENGTH}))
    print('CRAFT_EXPORTED', code)
