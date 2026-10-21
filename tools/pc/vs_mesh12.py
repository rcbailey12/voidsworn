# Voidsworn: mesh Ryan's picked concepts with Hunyuan3D 2.1, with a background cut that falls back to a colour key when rembg keeps the backdrop.
import os, sys, json, time, traceback
DL = os.path.join(os.environ['USERPROFILE'], 'Downloads')
J = json.load(open(os.path.join(DL, 'voidsworn_mesh_picks9.json'), encoding='utf-8'))
IN = os.path.join(DL, 'voidsworn_concepts'); OUT = os.path.join(DL, 'voidsworn_meshes', 'picks'); os.makedirs(OUT, exist_ok=True)
LOG = open(os.path.join(DL, 'mesh_py.log'), 'a', encoding='utf-8', buffering=1)
def log(*a):
    s = ' '.join(str(x) for x in a); print(s); LOG.write(time.strftime('%H:%M:%S ') + s + '\n')
sys.path.insert(0, './hy3dshape'); sys.path.insert(0, './hy3dpaint')
import torch, numpy as np
from PIL import Image, ImageFilter
from hy3dshape import FloaterRemover, DegenerateFaceRemover, Hunyuan3DDiTFlowMatchingPipeline
from hy3dshape.pipelines import export_to_trimesh
from hy3dshape.rembg import BackgroundRemover
rm = BackgroundRemover()
def cut(img):
    a = rm(img).convert('RGBA'); al = np.array(a)[:, :, 3] > 128
    border = np.concatenate([al[0], al[-1], al[:, 0], al[:, -1]]).mean()
    if al.mean() < .45 and border < .12: return a, 'rembg'
    rgb = np.array(img).astype(int); k = 24
    corners = np.concatenate([rgb[:k, :k].reshape(-1, 3), rgb[:k, -k:].reshape(-1, 3), rgb[-k:, :k].reshape(-1, 3), rgb[-k:, -k:].reshape(-1, 3)])
    key = np.abs(rgb - np.median(corners, 0)).sum(2) > 42
    m = Image.fromarray((key * 255).astype('uint8')).filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(5))
    out = img.convert('RGBA'); out.putalpha(m); return out, 'colour key'
pipe = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained('tencent/Hunyuan3D-2.1', subfolder='hunyuan3d-dit-v2-1', use_safetensors=False, device='cuda')
fr, dr = FloaterRemover(), DegenerateFaceRemover()
log('meshing picks', len(J['picks']))
for code in J['picks']:
    f = os.path.join(IN, *code.split('/')) + '.png'; code = code.replace('/', '_'); out = os.path.join(OUT, code + '.glb')
    if os.path.exists(out) or not os.path.exists(f): continue
    try:
        t = time.time(); img, how = cut(Image.open(f).convert('RGB')); img.save(os.path.join(OUT, code + '_cut.png'))
        res = pipe(image=img, num_inference_steps=50, guidance_scale=5.0, generator=torch.Generator().manual_seed(1234), octree_resolution=384, num_chunks=8000, output_type='mesh')
        m = export_to_trimesh(res)[0]; m = fr(m); m = dr(m); m.export(out)
        log('mesh pick', code, how, f'{time.time()-t:.1f}s', 'faces', len(m.faces))
    except Exception as e:
        log('FAILED', code, repr(e)); log(traceback.format_exc()[-800:])
log('PICKS9 DONE')
