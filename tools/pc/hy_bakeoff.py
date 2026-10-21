# Voidsworn shape bake-off, entry A: the Pyre-Barge and the station re-meshed by Hunyuan3D 2.1 at higher octree resolution (was 384), same seed and cut image.
import os, sys, time, traceback
DL = os.path.join(os.environ['USERPROFILE'], 'Downloads'); PK = os.path.join(DL, 'voidsworn_meshes', 'picks')
OUT = os.path.join(DL, 'voidsworn_test', 'bakeoff'); os.makedirs(OUT, exist_ok=True)
LOG = open(os.path.join(OUT, 'hy_bakeoff.log'), 'a', encoding='utf-8', buffering=1)
def log(*a):
    s = ' '.join(str(x) for x in a); print(s); LOG.write(time.strftime('%H:%M:%S ') + s + '\n')
sys.path.insert(0, './hy3dshape')
import torch
from PIL import Image
from hy3dshape import FloaterRemover, DegenerateFaceRemover, Hunyuan3DDiTFlowMatchingPipeline
from hy3dshape.pipelines import export_to_trimesh
pipe = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained('tencent/Hunyuan3D-2.1', subfolder='hunyuan3d-dit-v2-1', use_safetensors=False, device='cuda')
fr, dr = FloaterRemover(), DegenerateFaceRemover()
for code in ['C19_51', 'O1_37']:
    img = Image.open(os.path.join(PK, 'flux11_' + code + '_cut.png')).convert('RGBA')
    for oct_ in (512, 640):
        out = os.path.join(OUT, f'{code}_hy{oct_}.glb')
        if os.path.exists(out): continue
        try:
            t = time.time(); torch.cuda.empty_cache()
            res = pipe(image=img, num_inference_steps=50, guidance_scale=5.0, generator=torch.Generator().manual_seed(1234), octree_resolution=oct_, num_chunks=20000, output_type='mesh')
            m = export_to_trimesh(res)[0]; m = fr(m); m = dr(m); m.export(out)
            log('mesh', code, oct_, f'{time.time()-t:.1f}s', 'faces', len(m.faces), 'vram GB', round(torch.cuda.max_memory_allocated() / 1e9, 1))
        except Exception as e:
            log('FAILED', code, oct_, repr(e)[:300]); log(traceback.format_exc()[-600:])
log('HY BAKEOFF DONE')
