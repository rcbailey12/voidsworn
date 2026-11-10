# Opus #209 round 1, step G2: TRELLIS.2 (4B, 1536 cascade, the same settings as tools/pc/trellis_fleet.py made the whole-hull B0 mesh)
# on each section and part image. Texture is off for the comparison (the maps are baked small and never used).
# Run with the TRELLIS venv python from Downloads\trellis2\code: python trellis209.py GEN_DIR name=relative.png ...
import os, sys, time, traceback
sys.path.insert(0, os.path.join(os.environ['USERPROFILE'], 'Downloads', 'trellis2', 'code')); os.chdir(sys.path[0])
os.environ['OPENCV_IO_ENABLE_OPENEXR'] = '1'; os.environ['PYTORCH_CUDA_ALLOC_CONF'] = 'expandable_segments:True'
G = sys.argv[1]; JOBS = [a.split('=', 1) for a in sys.argv[2:]]
OUT = os.path.join(G, '3d'); os.makedirs(OUT, exist_ok=True)
LOG = open(os.path.join(G, 'trellis.log'), 'a', encoding='utf-8', buffering=1)
def log(*a):
    s = ' '.join(str(x) for x in a); print(s, flush=True); LOG.write(time.strftime('%H:%M:%S ') + s + '\n')
try:
    import torch
    # the same Windows fallbacks trellis_fleet.py applies (no Triton on Windows)
    try:
        import flex_gemm.ops.spconv as spconv
        from flex_gemm.ops.spconv import Algorithm
        spconv.ALGORITHM = Algorithm.EXPLICIT_GEMM
    except Exception as e: log('spconv patch', e)
    try:
        import flex_gemm.kernels as _fgk
        if not hasattr(_fgk, 'triton'):
            class _TF:
                @staticmethod
                def indice_weighed_sum_fwd(feats, indices, weights):
                    N = feats.shape[0]; idx = indices.long().clamp(min=0, max=N - 1); M, K = idx.shape
                    out = torch.zeros((M, feats.shape[-1]), dtype=feats.dtype, device=feats.device)
                    for i in range(K): out += feats[idx[:, i]] * weights[:, i].unsqueeze(-1)
                    return out
                @staticmethod
                def indice_weighed_sum_bwd_input(grad_output, indices, weights, N):
                    M, C = grad_output.shape; idx = indices.long().clamp(min=0, max=N - 1)
                    g = torch.zeros(N, C, device=grad_output.device, dtype=grad_output.dtype)
                    g.scatter_add_(0, idx.reshape(-1, 1).expand(-1, C), (grad_output.unsqueeze(1) * weights.unsqueeze(-1)).reshape(-1, C)); return g
            _fgk.triton = _TF()
    except Exception as e: log('triton patch', e)
    from PIL import Image
    from trellis2.pipelines import Trellis2ImageTo3DPipeline
    import o_voxel
    t0 = time.time(); pipe = Trellis2ImageTo3DPipeline.from_pretrained('microsoft/TRELLIS.2-4B'); pipe.cuda(); log('model loaded', f'{time.time()-t0:.0f}s')
    for name, rel in JOBS:
        out = os.path.join(OUT, name + '.glb')
        if os.path.exists(out): log('skip', name); continue
        tf = os.path.join(OUT, name + '.try'); tries = int(open(tf).read()) if os.path.exists(tf) and open(tf).read().isdigit() else 0
        if tries >= 2: log('give up', name, 'after', tries, 'tries'); continue
        open(tf, 'w').write(str(tries + 1))  # a crash (the process dies) leaves this count, so the restart uses the gentle settings or skips
        if tries == 1: os.environ['T209_PT'] = '1024_cascade'; os.environ['T209_TOKENS'] = '32768'
        else: os.environ['T209_PT'] = '1536_cascade,1024_cascade'; os.environ['T209_TOKENS'] = '49152'
        try:
            t = time.time(); torch.cuda.reset_peak_memory_stats(); img = Image.open(os.path.join(G, rel)).convert('RGBA'); mesh = None
            for pt in os.environ['T209_PT'].split(','):
                try:
                    outputs, latents = pipe.run(img, seed=1234, pipeline_type=pt, return_latent=True, max_num_tokens=int(os.environ['T209_TOKENS'])); mesh = outputs[0]; res = latents[2]; break
                except Exception as e:
                    log(name, pt, 'failed', repr(e)[:200]); torch.cuda.empty_cache()
            if mesh is None: raise RuntimeError('no mesh from any pipeline')
            mesh.simplify(16777216); mesh.attrs = mesh.attrs.float(); del latents; torch.cuda.empty_cache()
            glb = o_voxel.postprocess.to_glb(vertices=mesh.vertices, faces=mesh.faces, attr_volume=mesh.attrs, coords=mesh.coords, attr_layout=pipe.pbr_attr_layout,
                grid_size=res, aabb=[[-0.5, -0.5, -0.5], [0.5, 0.5, 0.5]], decimation_target=600000, texture_size=512, remesh=True, remesh_band=1, remesh_project=0)
            glb.export(out, extension_webp=True)
            open(tf, 'w').write('ok'); log('mesh', name, pt, f'{time.time()-t:.1f}s', 'vram GB', round(torch.cuda.max_memory_allocated() / 1e9, 1))
        except Exception as e:
            log('FAILED', name, repr(e)[:400]); log(traceback.format_exc()[-1200:]); torch.cuda.empty_cache()
except Exception as e:
    log('SETUP FAILED', repr(e)[:400]); log(traceback.format_exc()[-1500:])
log('TRELLIS209 DONE')
open(os.path.join(G, os.environ.get('T209_DONE', 'trellis_done.txt')), 'w').write('done ' + time.strftime('%H:%M:%S'))
