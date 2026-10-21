# Bake-off entry C: TRELLIS.2 (microsoft/TRELLIS.2-4B) on the Pyre-Barge and station cut images; textured GLB out, plus a log of the pipeline options.
import os, sys, time, inspect, traceback
os.environ['OPENCV_IO_ENABLE_OPENEXR'] = '1'; os.environ['PYTORCH_CUDA_ALLOC_CONF'] = 'expandable_segments:True'
DL = os.path.join(os.environ['USERPROFILE'], 'Downloads'); PK = os.path.join(DL, 'voidsworn_meshes', 'picks'); OUT = os.path.join(DL, 'voidsworn_test', 'bakeoff'); os.makedirs(OUT, exist_ok=True)
LOG = open(os.path.join(OUT, 'trellis_bakeoff.log'), 'a', encoding='utf-8', buffering=1)
def log(*a):
    s = ' '.join(str(x) for x in a); print(s, flush=True); LOG.write(time.strftime('%H:%M:%S ') + s + '\n')
try:
    import torch
    from PIL import Image
    from trellis2.pipelines import Trellis2ImageTo3DPipeline
    import o_voxel
    log('torch', torch.__version__, 'cuda', torch.cuda.is_available(), torch.cuda.get_device_name(0) if torch.cuda.is_available() else '')
    pipe = Trellis2ImageTo3DPipeline.from_pretrained('microsoft/TRELLIS.2-4B'); pipe.cuda()
    try: log('run signature', str(inspect.signature(pipe.run)))
    except Exception as e: log('no signature', e)
    for code in ['C19_51', 'O1_37']:
        out = os.path.join(OUT, f'{code}_trellis.glb')
        if os.path.exists(out): continue
        try:
            t = time.time(); torch.cuda.reset_peak_memory_stats(); img = Image.open(os.path.join(PK, 'flux11_' + code + '_cut.png')).convert('RGBA')
            try: mesh = pipe.run(img, seed=1234)[0]
            except TypeError: mesh = pipe.run(img)[0]
            mesh.simplify(16777216)
            glb = o_voxel.postprocess.to_glb(vertices=mesh.vertices, faces=mesh.faces, attr_volume=mesh.attrs, coords=mesh.coords, attr_layout=mesh.layout,
                voxel_size=mesh.voxel_size, aabb=[[-0.5, -0.5, -0.5], [0.5, 0.5, 0.5]], decimation_target=600000, texture_size=2048, remesh=True, remesh_band=1, remesh_project=0, verbose=False)
            glb.export(out, extension_webp=True)
            log('mesh', code, f'{time.time()-t:.1f}s', 'vram GB', round(torch.cuda.max_memory_allocated() / 1e9, 1))
        except Exception as e:
            log('FAILED', code, repr(e)[:400]); log(traceback.format_exc()[-1200:])
except Exception as e:
    log('SETUP FAILED', repr(e)[:400]); log(traceback.format_exc()[-1500:])
log('TRELLIS BAKEOFF DONE')
