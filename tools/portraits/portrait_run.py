# Headless ComfyUI portrait runner (runs with ComfyUI's embedded python on Ryan's PC).
#   portrait_run.py probe                 -> lists ComfyUI models, custom nodes and disk free into voidsworn_test\portraits\probe.txt
#   portrait_run.py gen <batch.json>      -> renders every item x seed; PNGs in voidsworn_test\comfy_io\PORTRAITS\<out>\
# Workflows:
#   zit : Z-Image Turbo text to image (official ComfyUI template settings: lumina2 text encoder, AuraFlow shift 3, 8 steps, cfg 1, res_multistep)
#   qie : Qwen-Image-Edit 2511 used as text to image (empty latent, Lightning 8-step LoRA), the model already on the PC for ship views
# Batch json: {"out": "b1", "suffix": "...", "items": [{"id": "mending", "model": "zit", "prompt": "...", "seeds": [11, 23], "w": 1024, "h": 1024}]}
import os, sys, json, time, subprocess, urllib.request, urllib.error
DL = os.path.join(os.environ['USERPROFILE'], 'Downloads'); R = os.path.join(DL, 'ComfyUI_windows_portable'); C = os.path.join(R, 'ComfyUI')
VT = os.path.join(DL, 'voidsworn_test'); PD = os.path.join(VT, 'portraits'); IO_ = os.path.join(VT, 'comfy_io', 'PORTRAITS')
LOG = os.path.join(PD, 'portrait_run.log'); URL = 'http://127.0.0.1:8188'
os.makedirs(PD, exist_ok=True); os.makedirs(IO_, exist_ok=True)
def log(*a):
    s = time.strftime('%H:%M:%S') + ' ' + ' '.join(str(x) for x in a); print(s, flush=True)
    with open(LOG, 'a', encoding='utf-8') as f: f.write(s + '\n')
def get(p): return json.loads(urllib.request.urlopen(URL + p, timeout=30).read())
def post(p, d):
    r = urllib.request.Request(URL + p, data=json.dumps(d).encode(), headers={'Content-Type': 'application/json'})
    try: return json.loads(urllib.request.urlopen(r, timeout=60).read())
    except urllib.error.HTTPError as e: log('POST error', e.code, e.read().decode()[:3000]); raise
def start():
    py = os.path.join(R, 'python_embeded', 'python.exe'); lf = open(os.path.join(PD, 'comfy_server.log'), 'a', encoding='utf-8')
    p = subprocess.Popen([py, '-s', os.path.join(C, 'main.py'), '--windows-standalone-build', '--listen', '127.0.0.1', '--port', '8188',
                          '--output-directory', IO_, '--input-directory', IO_, '--disable-auto-launch'], cwd=C, stdout=lf, stderr=subprocess.STDOUT)
    for _ in range(240):
        try: get('/system_stats'); log('server up'); return p
        except Exception: time.sleep(2)
    raise RuntimeError('server did not start')
def run(prompt, tag, timeout=900):
    try: r = post('/prompt', {'prompt': prompt, 'client_id': 'vs_portraits'})
    except Exception as e: log(tag, 'REJECTED', repr(e)[:300]); return None
    pid = r['prompt_id']; t = time.time()
    while time.time() - t < timeout:
        h = get('/history/' + pid)
        if pid in h:
            st = h[pid].get('status', {}); log(tag, st.get('status_str'), '%.1fs' % (time.time() - t))
            if st.get('status_str') != 'success':
                for m in st.get('messages', []):
                    if m[0] in ('execution_error', 'execution_interrupted'): log('  error', json.dumps(m[1])[:2000])
            return h[pid]
        time.sleep(1)
    log(tag, 'TIMEOUT'); return None
def have(sub, name): return os.path.exists(os.path.join(C, 'models', sub, name))

def zit(prompt, seed, prefix, w=1024, h=1024, steps=8, cfg=1.0, shift=3.0):
    return {
      '1': {'class_type': 'UNETLoader', 'inputs': {'unet_name': 'z_image_turbo_bf16.safetensors', 'weight_dtype': 'default'}},
      '2': {'class_type': 'CLIPLoader', 'inputs': {'clip_name': 'qwen_3_4b.safetensors', 'type': 'lumina2', 'device': 'default'}},
      '3': {'class_type': 'VAELoader', 'inputs': {'vae_name': 'ae.safetensors'}},
      '4': {'class_type': 'ModelSamplingAuraFlow', 'inputs': {'model': ['1', 0], 'shift': shift}},
      '5': {'class_type': 'CLIPTextEncode', 'inputs': {'clip': ['2', 0], 'text': prompt}},
      '6': {'class_type': 'ConditioningZeroOut', 'inputs': {'conditioning': ['5', 0]}},
      '7': {'class_type': 'EmptySD3LatentImage', 'inputs': {'width': w, 'height': h, 'batch_size': 1}},
      '8': {'class_type': 'KSampler', 'inputs': {'model': ['4', 0], 'positive': ['5', 0], 'negative': ['6', 0], 'latent_image': ['7', 0],
             'seed': seed, 'steps': steps, 'cfg': cfg, 'sampler_name': 'res_multistep', 'scheduler': 'simple', 'denoise': 1.0}},
      '9': {'class_type': 'VAEDecode', 'inputs': {'samples': ['8', 0], 'vae': ['3', 0]}},
      '10': {'class_type': 'SaveImage', 'inputs': {'images': ['9', 0], 'filename_prefix': prefix}}}

def qie(prompt, seed, prefix, w=1024, h=1024, steps=8, cfg=1.0):
    return {
      '3': {'class_type': 'UNETLoader', 'inputs': {'unet_name': 'qwen_image_edit_2511_fp8mixed.safetensors', 'weight_dtype': 'default'}},
      '5': {'class_type': 'ModelSamplingAuraFlow', 'inputs': {'model': ['3', 0], 'shift': 3.1}},
      '6': {'class_type': 'CFGNorm', 'inputs': {'model': ['5', 0], 'strength': 1.0}},
      '7': {'class_type': 'LoraLoaderModelOnly', 'inputs': {'model': ['6', 0], 'lora_name': 'Qwen-Image-Edit-2511-Lightning-8steps-V1.0-bf16.safetensors', 'strength_model': 1.0}},
      '8': {'class_type': 'CLIPLoader', 'inputs': {'clip_name': 'qwen_2.5_vl_7b_fp8_scaled.safetensors', 'type': 'qwen_image', 'device': 'default'}},
      '9': {'class_type': 'VAELoader', 'inputs': {'vae_name': 'qwen_image_vae.safetensors'}},
      '10': {'class_type': 'TextEncodeQwenImageEditPlus', 'inputs': {'clip': ['8', 0], 'vae': ['9', 0], 'prompt': prompt}},
      '11': {'class_type': 'TextEncodeQwenImageEditPlus', 'inputs': {'clip': ['8', 0], 'vae': ['9', 0], 'prompt': ''}},
      '14': {'class_type': 'EmptySD3LatentImage', 'inputs': {'width': w, 'height': h, 'batch_size': 1}},
      '15': {'class_type': 'KSampler', 'inputs': {'model': ['7', 0], 'positive': ['10', 0], 'negative': ['11', 0], 'latent_image': ['14', 0],
             'seed': seed, 'steps': steps, 'cfg': cfg, 'sampler_name': 'euler', 'scheduler': 'simple', 'denoise': 1.0}},
      '16': {'class_type': 'VAEDecode', 'inputs': {'samples': ['15', 0], 'vae': ['9', 0]}},
      '17': {'class_type': 'SaveImage', 'inputs': {'images': ['16', 0], 'filename_prefix': prefix}}}

NEEDS = {'zit': [('diffusion_models', 'z_image_turbo_bf16.safetensors'), ('text_encoders', 'qwen_3_4b.safetensors'), ('vae', 'ae.safetensors')],
         'qie': [('diffusion_models', 'qwen_image_edit_2511_fp8mixed.safetensors'), ('text_encoders', 'qwen_2.5_vl_7b_fp8_scaled.safetensors'),
                 ('vae', 'qwen_image_vae.safetensors'), ('loras', 'Qwen-Image-Edit-2511-Lightning-8steps-V1.0-bf16.safetensors')]}
def ready(model):
    miss = [s + '\\' + n for s, n in NEEDS[model] if not have(s, n)]
    if miss: log('model', model, 'MISSING', ', '.join(miss))
    return not miss

def probe():
    out = os.path.join(PD, 'probe.txt'); L = []
    import shutil
    L.append('disk free C GB %.1f' % (shutil.disk_usage('C:\\').free / 1e9))
    for root, dirs, files in os.walk(os.path.join(C, 'models')):
        for f in files:
            p = os.path.join(root, f); s = os.path.getsize(p)
            if s > 1e6: L.append('%8.2f GB  %s' % (s / 1e9, os.path.relpath(p, C)))
    cn = os.path.join(C, 'custom_nodes')
    if os.path.isdir(cn): L.append('custom_nodes: ' + ', '.join(sorted(os.listdir(cn))))
    hf = os.path.join(os.environ['USERPROFILE'], '.cache', 'huggingface', 'hub')
    if os.path.isdir(hf): L.append('hf cache: ' + ', '.join(sorted(os.listdir(hf))))
    open(out, 'w', encoding='utf-8').write('\n'.join(L) + '\n'); log('probe written', len(L), 'lines')

def gen(path):
    B = json.load(open(path, encoding='utf-8')); out = B['out']; suf = B.get('suffix', '')
    items = B['items']; order = sorted(range(len(items)), key=lambda i: (items[i].get('model', 'zit') != 'zit', i))  # one model load per family
    ok = {m: ready(m) for m in NEEDS}; p = start(); n = 0; t0 = time.time(); man = []
    try:
        for i in order:
            it = items[i]; m = it.get('model', 'zit')
            if not ok.get(m): continue
            txt = it['prompt'] + (' ' + suf if suf and not it.get('nosuffix') else '')
            for sd in it.get('seeds', [11, 23, 37]):
                pre = f"{out}/{it['id']}_{m}_s{sd}"
                if os.path.exists(os.path.join(IO_, pre + '_00001_.png')): continue
                fn = zit if m == 'zit' else qie
                r = run(fn(txt, sd, pre, it.get('w', 1024), it.get('h', 1024)), pre)
                n += 1; man.append({'id': it['id'], 'model': m, 'seed': sd, 'ok': bool(r and r.get('status', {}).get('status_str') == 'success'), 'prompt': txt})
                if time.time() - t0 > B.get('budget_s', 1050): log('budget reached, stopping'); raise StopIteration
    except StopIteration: pass
    finally:
        p.terminate()
        try: p.wait(30)
        except Exception: p.kill()
        with open(os.path.join(PD, 'manifest_%s_%s.json' % (out, time.strftime('%H%M%S'))), 'w', encoding='utf-8') as f: json.dump(man, f, indent=1)
    log('GEN DONE', out, n, 'images', '%.0fs' % (time.time() - t0))

if __name__ == '__main__':
    a = sys.argv[1:]
    if not a or a[0] == 'probe': probe()
    elif a[0] == 'gen': gen(a[1])
