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
def qwen_prompt(img, view_txt, seed, prefix, steps=8, cfg=1.0, lightning=True, angle_w=0.9):
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
             'prompt': '<sks> ' + view_txt + ' eye-level shot medium shot'}},
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
def views(code, seeds=2, which=None):
    d = os.path.join(IO_, code); os.makedirs(d, exist_ok=True)
    src = os.path.join(PICKS, 'flux11_' + code + '_cut.png'); img = code + '_concept.png'
    from PIL import Image
    im = Image.open(src).convert('RGBA'); bg = Image.new('RGBA', im.size, (255, 255, 255, 255)); bg.alpha_composite(im); bg.convert('RGB').save(os.path.join(d, img))  # plain white backdrop
    p = start(d)
    try:
        for v in (which or ['right', 'left', 'front', 'back']):
            for s in range(seeds):
                run(qwen_prompt(img, VIEWS[v], 1000 + s, f'views/{code}_{v}_s{s}'), f'{code} {v} s{s}')
    finally: p.terminate(); p.wait(30)
    log('VIEWS DONE', code)

# ---------- mesh: Pixal3D multi-view, from the official template (UI json -> API) ----------
def ui_to_api(wf, info, skip_types=('Note', 'MarkdownNote', 'PreviewImage', 'Preview3DAdvanced', 'Reroute')):
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
def mesh(code, res=1536, tris=2000000, fov=20.0, int8=False):
    d = os.path.join(IO_, code); p = start(d)
    try:
        info = get('/object_info'); wf = json.load(open(os.path.join(REF, '3d_pixal3d_multi_views.json'), encoding='utf-8'))
        api = ui_to_api(wf, info)
        api['319']['inputs']['unet_name'] = 'pixal3d_multiview_int8_convrot.safetensors' if int8 else 'pixal3d_multiview_bf16.safetensors'
        for v in ('front', 'left', 'back', 'right'):  # prepared views: square, black backdrop, one shared scale (made in the sandbox)
            api['L' + v] = {'class_type': 'LoadImage', 'inputs': {'image': f'mv/{code}_{v}.png'}}; api['324']['inputs'][v] = ['L' + v, 0]
        api['324']['inputs']['fov'] = fov
        api['94']['inputs']['target_resolution'] = res
        for k, v in list(api['186']['inputs'].items()):
            if isinstance(v, int) and not isinstance(v, bool): api['186']['inputs'][k] = tris
        log('decimate', api['186']['inputs'], 'remesh', api['241']['inputs'])
        for k in ('372',): api[k]['inputs']['filename_prefix'] = f'mesh/{code}_pixal_tex'
        api['M1'] = {'class_type': 'MeshToFile3D', 'inputs': {'mesh': ['241', 0]}}; api['S1'] = {'class_type': 'Save3DAdvanced', 'inputs': dict(api['372']['inputs'], model_3d=['M1', 0], filename_prefix=f'mesh/{code}_pixal_hi')}
        api['M2'] = {'class_type': 'MeshToFile3D', 'inputs': {'mesh': ['92', 0]}}; api['S2'] = {'class_type': 'Save3DAdvanced', 'inputs': dict(api['372']['inputs'], model_3d=['M2', 0], filename_prefix=f'mesh/{code}_pixal_raw')}
        api = prune(api, ['372', 'S1', 'S2'])
        json.dump(api, open(os.path.join(d, f'{code}_mesh_api.json'), 'w'), indent=1)
        log('mesh api nodes', len(api))
        run(api, f'{code} pixal3d mv res {res}', timeout=7200)
    finally: p.terminate(); p.wait(30)
    log('MESH DONE', code)

if __name__ == '__main__':
    os.makedirs(IO_, exist_ok=True); a = sys.argv[1:]
    try:
        if a[0] == 'views': views(a[1], int(a[2]) if len(a) > 2 else 2, a[3].split(',') if len(a) > 3 else None)
        elif a[0] == 'mesh': mesh(a[1], int(a[2]) if len(a) > 2 else 1536, int(a[3]) if len(a) > 3 else 2000000, int8=len(a) > 4 and a[4] == 'int8')
    except Exception as e:
        import traceback; log('FAILED', repr(e)); log(traceback.format_exc())
