# Fleet rebuild: TRELLIS.2 (microsoft/TRELLIS.2-4B) on every remaining hull's concept cut image; textured GLB out, plus a log of the pipeline options.
import os, sys, time, inspect, traceback
sys.path.insert(0, os.path.join(os.environ['USERPROFILE'], 'Downloads', 'trellis2', 'code')); os.chdir(sys.path[0])  # the trellis2 package and its assets live in the code folder
os.environ['OPENCV_IO_ENABLE_OPENEXR'] = '1'; os.environ['PYTORCH_CUDA_ALLOC_CONF'] = 'expandable_segments:True'
DL = os.path.join(os.environ['USERPROFILE'], 'Downloads'); PK = os.path.join(DL, 'voidsworn_meshes', 'picks'); OUT = os.path.join(DL, 'voidsworn_test', 'bakeoff'); os.makedirs(OUT, exist_ok=True)
LOG = open(os.path.join(OUT, 'trellis_fleet.log'), 'a', encoding='utf-8', buffering=1)
def log(*a):
    s = ' '.join(str(x) for x in a); print(s, flush=True); LOG.write(time.strftime('%H:%M:%S ') + s + '\n')

def apply_patches():  # same Windows fallbacks the installer's own worker applies (pipeline_worker._apply_patches): no Triton on Windows
    import torch
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
try:
    import torch
    apply_patches()
    from PIL import Image
    from trellis2.pipelines import Trellis2ImageTo3DPipeline
    import o_voxel
    log('torch', torch.__version__, 'cuda', torch.cuda.is_available(), torch.cuda.get_device_name(0) if torch.cuda.is_available() else '')
    pipe = Trellis2ImageTo3DPipeline.from_pretrained('microsoft/TRELLIS.2-4B'); pipe.cuda()
    try: log('run signature', str(inspect.signature(pipe.run)))
    except Exception as e: log('no signature', e)
    import glob
    CODES = 'B16_23,B19_11,B20_11,B21_11,B22_11,B23_51,C13s_23,C14s_23,C15s_23,C16s_23,D20_23,D21_23,D22_23,D9_23,H10_23,H4_11,H7_23,H8_23,H9_23,I11_37,I14_23,I15_11,I16_11,I8_37,O2_37,O3_11,S1_51,S2_23,V14_23,V15_37,V16_37,V17_37,V18_51,V1b_r_23'.split(',')
    def cutimg(code):
        fs = [f for f in glob.glob(os.path.join(PK, '*_cut.png')) if os.path.basename(f) == code + '_cut.png' or os.path.basename(f).endswith('_' + code + '_cut.png')]
        return sorted(fs, key=len)[0] if fs else None
    for code in CODES:
        out = os.path.join(OUT, f'{code}_trellis.glb')
        if os.path.exists(out): continue
        try:
            t = time.time(); torch.cuda.reset_peak_memory_stats(); f = cutimg(code)
            if not f: log('no cut image', code); continue
            img = Image.open(f).convert('RGBA')
            mesh = None
            for pt in ('1536_cascade', '1024_cascade'):
                try:
                    outputs, latents = pipe.run(img, seed=1234, pipeline_type=pt, return_latent=True); mesh = outputs[0]; res = latents[2]; log(code, 'pipeline', pt, 'res', res); break
                except Exception as e:
                    log(code, pt, 'failed', repr(e)[:200]); torch.cuda.empty_cache()
            mesh.simplify(16777216); mesh.attrs = mesh.attrs.float(); del latents; torch.cuda.empty_cache()
            glb = o_voxel.postprocess.to_glb(vertices=mesh.vertices, faces=mesh.faces, attr_volume=mesh.attrs, coords=mesh.coords, attr_layout=pipe.pbr_attr_layout,
                grid_size=res, aabb=[[-0.5, -0.5, -0.5], [0.5, 0.5, 0.5]], decimation_target=600000, texture_size=2048, remesh=True, remesh_band=1, remesh_project=0)
            glb.export(out, extension_webp=True)
            log('mesh', code, f'{time.time()-t:.1f}s', 'vram GB', round(torch.cuda.max_memory_allocated() / 1e9, 1))
        except Exception as e:
            log('FAILED', code, repr(e)[:400]); log(traceback.format_exc()[-1200:])
except Exception as e:
    log('SETUP FAILED', repr(e)[:400]); log(traceback.format_exc()[-1500:])
log('TRELLIS BAKEOFF DONE')
