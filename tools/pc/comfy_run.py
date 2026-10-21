# Headless ComfyUI runner for the ship pipeline (runs with ComfyUI's embedded python on the PC).
#   comfy_run.py views CODE [seeds]      -> Qwen-Image-Edit 2511 + multiple-angles LoRA: front/left/back/right (+ extras) of the concept cut-out
#   comfy_run.py mesh CODE [res] [tris]  -> Pixal3D multi-view (official template, views fed as prepared) -> high mesh + textured GLB
# Inputs/outputs live in Downloads\voidsworn_test\comfy_io\CODE\ . Log: Downloads\voidsworn_test\comfy_run.log
import os, sys, json, time, shutil, subprocess, urllib.request, urllib.error, glob, random
DL = os.path.join(os.environ['USERPROFILE'], 'Downloads'); R = os.path.join(DL, 'ComfyUI_windows_portable'); C = os.path.join(R, 'ComfyUI')
VT = os.path.join(DL, 'voidsworn_test'); IO_ = os.path.join(VT, 'comfy_io'); LOG = os.path.join(VT, 'comfy_run.log'); REF = os.path.join(VT, 'comfy_ref')
PICKS = os.path.join(DL, 'voidsworn_meshes', 'picks'); URL = 'http://127.0.0.1:8188'
def log(*a):
    s = time.strftime('%H:%M:%S') + ' ' + ' '.join(str(x) for x in a); print(s, flush=True)
    with open(LOG, 'a', encoding='utf-8') as f: f.write(s + '\n')
def get(p): return json.loads(urllib.request.urlopen(URL + p, timeout=30).read())
def post(p, d):
    r = urllib.request.Request(URL + p, data=json.dumps(d).encode(), headers={'Content-Type': 'application/json'})
    try: return json.loads(urllib.request.urlopen(r, timeout=60).read())
    except urllib.error.HTTPError as e: log('POST error', e.code, e.read().decode()[:3000]); raise
def start(outdir):
    os.makedirs(outdir, exist_ok=True)
    py = os.path.join(R, 'python_embeded', 'python.exe'); lf = open(os.path.join(VT, 'comfy_server.log'), 'a', encoding='utf-8')
    p = subprocess.Popen([py, '-s', os.path.join(C, 'main.py'), '--windows-standalone-build', '--listen', '127.0.0.1', '--port', '8188', '--output-directory', outdir,
                          '--input-directory', outdir, '--disable-auto-launch'], cwd=C, stdout=lf, stderr=subprocess.STDOUT)
    for _ in range(240):
        try: get('/system_stats'); log('server up'); return p
        except Exception: time.sleep(2)
    raise RuntimeError('server did not start')
def run(prompt, tag, timeout=3600):
    r = post('/prompt', {'prompt': prompt, 'client_id': 'voidsworn'}); pid = r['prompt_id']; t = time.time()
    while time.time() - t < timeout:
        h = get('/history/' + pid)
        if pid in h:
            st = h[pid].get('status', {}); log(tag, st.get('status_str'), '%.0fs' % (time.time() - t))
            if st.get('status_str') != 'success':
                for m in st.get('messages', []):
                    if m[0] in ('execution_error', 'execution_interrupted'): log('  error', json.dumps(m[1])[:3000])
            return h[pid]
        time.sleep(3)
    log(tag, 'TIMEOUT'); return None

# ---------- views: Qwen-Image-Edit 2511 + multiple-angles LoRA (chain from the official template, lightning 8-step) ----------
VIEWS = {'front': 'front view', 'left': 'left side view', 'back': 'back view', 'right': 'right side view',
         'q_fl': 'front-left quarter view', 'top': 'front view high-angle shot'}
def qwen_prompt(img, view_txt, seed, prefix, steps=8, cfg=1.0, lightning=True, angle_w=0.9, full=False):
    p = {
      '1': {'class_type': 'LoadImage', 'inputs': {'image': img}},
      '2': {'class_type': 'FluxKontextImageScale', 'inputs': {'image': ['1', 0]}},
      '3': {'class_type': 'UNETLoader', 'inputs': {'unet_name': 'qwen_image_edit_2511_fp8mixed.safetensors', 'weight_dtype': 'default'}},
      '4': {'class_type': 'LoraLoaderModelOnly', 'inputs': {'model': ['3', 0], 'lora_name': 'qwen-image-edit-2511-multiple-angles-lora.safetensors', 'strength_model': angle_w}},
      '5': {'class_type': 'ModelSamplingAuraFlow', 'inputs': {'model': ['4', 0], 'shift': 3.1}},
      '6': {'class_type': 'CFGNorm', 'inputs': {'model': ['5', 0], 'strength': 1.0}},
      '8': {'class_type': 'CLIPLoader', 'inputs': {'clip_name': 'qwen_2.5_vl_7b_fp8_scaled.safetensors', 'type': 'qwen_image', 'device': 'default'}},
      '9': {'class_type': 'VAELoader', 'inputs': {'vae_name': 'qwen_image_vae.safetensors'}},
      '10': {'class_type': 'TextEncodeQwenImageEditPlus', 'inputs': {'clip': ['8', 0], 'vae': ['9', 0], 'image1': ['2', 0],
             'prompt': '<sks> ' + view_txt + ('' if full else ' eye-level shot medium shot')}},
      '11': {'class_type': 'TextEncodeQwenImageEditPlus', 'inputs': {'clip': ['8', 0], 'vae': ['9', 0], 'image1': ['2', 0], 'prompt': ''}},
      '12': {'class_type': 'FluxKontextMultiReferenceLatentMethod', 'inputs': {'conditioning': ['10', 0], 'reference_latents_method': 'index_timestep_zero'}},
      '13': {'class_type': 'FluxKontextMultiReferenceLatentMethod', 'inputs': {'conditioning': ['11', 0], 'reference_latents_method': 'index_timestep_zero'}},
      '14': {'class_type': 'VAEEncode', 'inputs': {'pixels': ['2', 0], 'vae': ['9', 0]}},
      '15': {'class_type': 'KSampler', 'inputs': {'model': ['7' if lightning else '6', 0], 'positive': ['12', 0], 'negative': ['13', 0], 'latent_image': ['14', 0],
             'seed': seed, 'steps': steps, 'cfg': cfg, 'sampler_name': 'euler', 'scheduler': 'simple', 'denoise': 1.0}},
      '16': {'class_type': 'VAEDecode', 'inputs': {'samples': ['15', 0], 'vae': ['9', 0]}},
      '17': {'class_type': 'SaveImage', 'inputs': {'images': ['16', 0], 'filename_prefix': prefix}}}
    if lightning: p['7'] = {'class_type': 'LoraLoaderModelOnly', 'inputs': {'model': ['6', 0], 'lora_name': 'Qwen-Image-Edit-2511-Lightning-8steps-V1.0-bf16.safetensors', 'strength_model': 1.0}}
    return p
def views(code, seeds=2, which=None, src=None, tag=''):
    d = os.path.join(IO_, code); os.makedirs(d, exist_ok=True)
    src = src or os.path.join(PICKS, 'flux11_' + code + '_cut.png'); img = code + '_src' + tag + '.png'
    from PIL import Image
    im = Image.open(src).convert('RGBA'); bg = Image.new('RGBA', im.size, (255, 255, 255, 255)); bg.alpha_composite(im); bg.convert('RGB').save(os.path.join(d, img))  # plain white backdrop
    p = start(d)
    try:
        for v in (which or ['right', 'left', 'front', 'back']):
            name, txt = (v.split('=', 1) if '=' in v else (v, VIEWS[v]))  # name=raw angle words, e.g. front_lo=front view low-angle shot
            for s in range(seeds):
                run(qwen_prompt(img, txt, 1000 + s, f'views{tag}/{code}_{name}_s{s}', full=('=' in v)), f'{code}{tag} {name} s{s}')
    finally: p.terminate(); p.wait(30)
    log('VIEWS DONE', code)

# ---------- mesh: Pixal3D multi-view, from the official template (UI json -> API) ----------
def ui_to_api_unused(wf, info, skip_types=('Note', 'MarkdownNote', 'PreviewImage', 'Preview3DAdvanced', 'Reroute')):
    links = {}
    for l in wf.get('links', []):
        if isinstance(l, list): links[l[0]] = (str(l[1]), l[2])
        else: links[l['id']] = (str(l['origin_id']), l['origin_slot'])
    api = {}
    for n in wf['nodes']:
        if n.get('mode') == 4 or n['type'] in skip_types: continue
        oi = info.get(n['type'])
        if oi is None: log('  unknown node type', n['type']); continue
        spec = {}; spec.update(oi['input'].get('required', {})); spec.update(oi['input'].get('optional', {}))
        order = list(oi['input'].get('required', {}).keys()) + list(oi['input'].get('optional', {}).keys())
        vals = list(n.get('widgets_values') or []) if isinstance(n.get('widgets_values'), list) else []
        ins = {}; linked = {}
        for i in n.get('inputs', []) or []:
            if i.get('link') is not None and i['link'] in links: linked[i['name']] = list(links[i['link']])
        vi = 0
        for name in order:
            t = spec[name]; typ = t[0]; opt = t[1] if len(t) > 1 and isinstance(t[1], dict) else {}
            is_widget = isinstance(typ, list) or typ in ('INT', 'FLOAT', 'STRING', 'BOOLEAN', 'COMBO')
            if is_widget and vi < len(vals):
                v = vals[vi]; vi += 1
                if typ == 'INT' and (opt.get('control_after_generate') or name in ('seed', 'noise_seed')) and vi < len(vals) and vals[vi] in ('fixed', 'randomize', 'increment', 'decrement'): vi += 1
                ins[name] = v
            if name in linked: ins[name] = linked[name]
        api[str(n['id'])] = {'class_type': n['type'], 'inputs': ins}
    return api
def prune(api, outs):
    keep = set(); st = list(outs)
    while st:
        k = st.pop()
        if k in keep or k not in api: continue
        keep.add(k)
        for v in api[k]['inputs'].values():
            if isinstance(v, list) and len(v) == 2 and isinstance(v[0], str): st.append(v[0])
    return {k: v for k, v in api.items() if k in keep}
def pixal_api(code, views, cams=None, res=1536, tris=2000000, remesh=768, qef=True, tex=4096, tag='', fov=20.0, unet='pixal3d_multiview_bf16.safetensors', lods=None, raw=True):
    """Pixal3D multi-view chain, written out from the official template (3d_pixal3d_multi_views.json) with its settings.
    views: list of names with images at mv{tag}/{code}_{name}.png; cams: None (built-in rig; names must be front/left/back/right) or list of (az, el)."""
    A = {}
    def n(k, t, **i): A[k] = {'class_type': t, 'inputs': i}; return k
    n('unet', 'UNETLoader', unet_name=unet, weight_dtype='default'); n('dino', 'CLIPVisionLoader', clip_name='dino_v3_L_naf_fp32.safetensors')
    n('svae', 'VAELoader', vae_name='trellis_2_shape_vae_bf16.safetensors'); n('tvae', 'VAELoader', vae_name='trellis_2_texture_vae_bf16.safetensors')
    for v in views: n('L_' + v, 'LoadImage', image=f'mv{tag}/{code}_{v}.png')
    if cams: n('cond', 'VoidswornPixal3DViews', clip_vision_model=['dino', 0], fov=fov, cams=';'.join(f'{a},{e}' for a, e in cams), **{f'view{k + 1}': ['L_' + v, 0] for k, v in enumerate(views)})
    else: n('cond', 'Pixal3DMultiViewConditioning', clip_vision_model=['dino', 0], fov=fov, **{v: ['L_' + v, 0] for v in views})
    # sparse structure
    n('cfgA', 'CFGOverride', model=['unet', 0], cfg=1.0, start_percent=0.667, end_percent=1.0); n('rsA', 'RescaleCFG', model=['cfgA', 0], multiplier=0.7); n('msA', 'ModelSamplingSD3', model=['rsA', 0], shift=5.0)
    n('emp', 'EmptyTrellis2LatentStructure', batch_size=1)
    n('ks1', 'KSampler', model=['msA', 0], seed=56, steps=12, cfg=7.5, sampler_name='euler', scheduler='normal', positive=['cond', 0], negative=['cond', 1], latent_image=['emp', 0], denoise=1.0)
    n('struct', 'VaeDecodeStructureTrellis2', samples=['ks1', 0], vae=['svae', 0], resolution='32')
    # shape 512 then cascade to res
    n('cfgB', 'CFGOverride', model=['unet', 0], cfg=1.0, start_percent=0.769, end_percent=1.0); n('rsB', 'RescaleCFG', model=['cfgB', 0], multiplier=0.5)
    n('ss', 'Trellis2ShapeStage', positive=['cond', 0], negative=['cond', 1], voxel=['struct', 0])
    n('ks2', 'KSampler', model=['rsB', 0], seed=42, steps=20, cfg=7.5, sampler_name='euler', scheduler='normal', positive=['ss', 0], negative=['ss', 1], latent_image=['ss', 2], denoise=1.0)
    n('up', 'Trellis2UpsampleStage', positive=['ss', 0], negative=['ss', 1], shape_latent=['ks2', 0], vae=['svae', 0], target_resolution=res)
    n('ks3', 'KSampler', model=['rsB', 0], seed=42, steps=12, cfg=7.5, sampler_name='euler', scheduler='simple', positive=['up', 0], negative=['up', 1], latent_image=['up', 2], denoise=1.0)
    # texture
    n('ts', 'Trellis2TextureStage', positive=['up', 0], negative=['up', 1], shape_latent=['ks3', 0])
    n('ks4', 'KSampler', model=['unet', 0], seed=43, steps=12, cfg=1.0, sampler_name='euler', scheduler='normal', positive=['ts', 0], negative=['ts', 1], latent_image=['ts', 2], denoise=1.0)
    n('shape', 'VaeDecodeShapeTrellis', samples=['ks3', 0], vae=['svae', 0]); n('vox', 'VaeDecodeTextureTrellis', samples=['ks4', 0], vae=['tvae', 0], shape_subdivides=['shape', 1])
    # clean surface (udf remesh; QEF keeps hard-surface edges sharp), decimate, unwrap, bake
    n('info', 'GetMeshInfo', mesh=['shape', 0])
    n('rem', 'RemeshMesh', mesh=['info', 0], resolution=remesh, sign_mode='udf', **{'sign_mode.qef': qef, 'sign_mode.drop_inverted_components': False, 'sign_mode.drop_enclosed_components': False},
      band=1.0, project_back=0.0, fix_poles=False, smooth_iters=20, drop_small_components=0.01, precluster_max_verts=20000000)
    for li, (lt, lres) in enumerate(lods or [(tris, tex)]):  # one decimate -> unwrap -> bake chain per level of detail, all from the same remeshed surface
        s_ = '' if not lods else f'_lod{li}'
        n('dec' + s_, 'DecimateMesh', mesh=['rem', 0], target_face_count=lt, placement_mode='midpoint'); n('sm' + s_, 'MeshSmoothNormals', mesh=['dec' + s_, 0], crease_angle=180.0)
        n('uv' + s_, 'UnwrapMesh', mesh=['sm' + s_, 0], segmenter='pec', resolution=lres, padding=1 if lres >= 2048 else 2, weld_distance=0.0002)
        n('bake' + s_, 'BakeTextureFromVoxel', mesh=['uv' + s_, 0], voxel_colors=['vox', 0], texture_size=lres, reference_mesh=['shape', 0])
        n('ao' + s_, 'BakeAmbientOcclusion', low_poly=['uv' + s_, 0], high_poly=['rem', 0], resolution=min(lres, 2048), samples=64, max_distance=0.71, strength=1.0, bias=0.01)
        n('nm' + s_, 'BakeNormalMapFromMesh', low_poly=['uv' + s_, 0], high_poly=['rem', 0], resolution=min(lres, 2048), cage_distance=0.05, ignore_backfaces=True)
        n('apply' + s_, 'ApplyTextureToMesh', mesh=['uv' + s_, 0], base_color=['bake' + s_, 0], metallic=['bake' + s_, 1], roughness=['bake' + s_, 2], occlusion=['ao' + s_, 0], normal_map=['nm' + s_, 0])
        n('sm2' + s_, 'MeshSmoothNormals', mesh=['apply' + s_, 0], crease_angle=180.0)
        n('o_tex' + s_, 'SaveGLB', mesh=['sm2' + s_, 0], filename_prefix=f'mesh/{code}{tag}_pixal_tex{s_}')
        for k, i in (('o_base', 0), ('o_met', 1), ('o_rough', 2)): n(k + s_, 'SaveImage', images=['bake' + s_, i], filename_prefix=f'mesh/{code}{tag}_{k[2:]}{s_}')
        n('o_ao' + s_, 'SaveImage', images=['ao' + s_, 0], filename_prefix=f'mesh/{code}{tag}_ao{s_}'); n('o_nm' + s_, 'SaveImage', images=['nm' + s_, 0], filename_prefix=f'mesh/{code}{tag}_nm{s_}')
    n('o_rem', 'SaveGLB', mesh=['rem', 0], filename_prefix=f'mesh/{code}{tag}_pixal_remesh')
    if raw: n('o_raw', 'SaveGLB', mesh=['shape', 0], filename_prefix=f'mesh/{code}{tag}_pixal_raw')
    return A
def mesh(code, views, cams=None, tag='', **kw):
    d = os.path.join(IO_, code); p = start(d)
    try:
        api = pixal_api(code, views, cams, tag=tag, **kw); json.dump(api, open(os.path.join(d, f'{code}{tag}_mesh_api.json'), 'w'), indent=1)
        log('mesh', code, tag, views, cams, kw); run(api, f'{code}{tag} pixal3d', timeout=7200)
    finally: p.terminate(); p.wait(30)
    log('MESH DONE', code, tag)

if __name__ == '__main__':
    os.makedirs(IO_, exist_ok=True); a = sys.argv[1:]
    try:
        if a[0] == 'views': views(a[1], int(a[2]) if len(a) > 2 else 2, a[3].split(';') if len(a) > 3 else None, a[4] if len(a) > 4 else None, a[5] if len(a) > 5 else '')
        elif a[0] == 'mesh':  # mesh CODE TAG views(front,left,..) [cams az,el;az,el|-] [res] [tris] [remesh] [qef 1|0]
            cams = [tuple(float(x) for x in c.split(',')) for c in a[4].split(';')] if len(a) > 4 and a[4] != '-' else None
            kw = {}
            for k, v in zip(('res', 'tris', 'remesh', 'qef', 'lods'), a[5:]):
                kw[k] = (v == '1') if k == 'qef' else [tuple(int(x) for x in l.split('@')) for l in v.split(',')] if k == 'lods' else int(v)  # lods: 2000000@4096,400000@4096,...
            if 'lods' in kw: kw['raw'] = False
            mesh(a[1], a[3].split(','), cams, tag=a[2], **kw)
    except Exception as e:
        import traceback; log('FAILED', repr(e)); log(traceback.format_exc())
