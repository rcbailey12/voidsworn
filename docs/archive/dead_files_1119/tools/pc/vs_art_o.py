# Voidsworn concept round 2 on the RTX 5080: FLUX schnell, prompts from Ryan's feedback (text) + revisions of his picks (image-to-image).
import os, sys, json, time, traceback, gc, faulthandler
DL = os.path.join(os.environ['USERPROFILE'], 'Downloads')
LOG = open(os.path.join(DL, 'art_py.log'), 'a', encoding='utf-8', buffering=1)
FH = open(os.path.join(DL, 'art_crash.log'), 'a'); faulthandler.enable(FH, all_threads=True)
def log(*a):
    s = ' '.join(str(x) for x in a); print(s); LOG.write(time.strftime('%H:%M:%S ') + s + '\n')
LOG.write(time.strftime('%H:%M:%S ')+'R11 python up\n')
P = json.load(open(os.path.join(DL, 'voidsworn_prompts11.json'), encoding='utf-8'))
SRC = os.path.join(DL, 'voidsworn_concepts', P['src']); OUT = os.path.join(DL, 'voidsworn_concepts', P['out']); os.makedirs(OUT, exist_ok=True)
LOG.write('R11 importing torch\n'); import torch
LOG.write('R11 torch '+torch.__version__+' cuda '+str(torch.cuda.is_available())+' '+(torch.cuda.get_device_name(0) if torch.cuda.is_available() else '')+' free '+str(torch.cuda.mem_get_info()[0]//2**20 if torch.cuda.is_available() else 0)+'MB\n')
from PIL import Image
from diffusers import FluxPipeline, FluxImg2ImgPipeline, FluxTransformer2DModel, GGUFQuantizationConfig, AutoencoderKL, FlowMatchEulerDiscreteScheduler
from transformers import CLIPTextModel, CLIPTokenizer, T5EncoderModel, T5TokenizerFast
bf = torch.bfloat16
try:
    log('R11 start'); cfgdir = os.path.join(DL, '_flux_cfg')
    tr = FluxTransformer2DModel.from_single_file('https://huggingface.co/city96/FLUX.1-schnell-gguf/blob/main/flux1-schnell-Q8_0.gguf',
        quantization_config=GGUFQuantizationConfig(compute_dtype=bf), torch_dtype=bf, config=cfgdir)
    log('R11 transformer loaded'); te = CLIPTextModel.from_pretrained('openai/clip-vit-large-patch14', torch_dtype=bf).to('cuda'); tok = CLIPTokenizer.from_pretrained('openai/clip-vit-large-patch14')
    log('R11 clip loaded'); te2 = T5EncoderModel.from_pretrained('city96/t5-v1_1-xxl-encoder-bf16', torch_dtype=bf).to('cuda')
    try: tok2 = T5TokenizerFast.from_pretrained('city96/t5-v1_1-xxl-encoder-bf16')
    except Exception: tok2 = T5TokenizerFast.from_pretrained('google/t5-v1_1-xxl')
    log('R11 t5 loaded'); vae = AutoencoderKL.from_pretrained('lodestones/Chroma1-HD', subfolder='vae', torch_dtype=bf)
    sch = FlowMatchEulerDiscreteScheduler(num_train_timesteps=1000, shift=1.0, use_dynamic_shifting=False)
    enc = FluxPipeline(scheduler=sch, vae=None, text_encoder=te, tokenizer=tok, text_encoder_2=te2, tokenizer_2=tok2, transformer=None)
    E = {}; names = {}
    with torch.no_grad():
        for code, fac, title, prompt in P['items']:
            full = prompt + P['suffix']; names[code] = fac + ' ' + title
            pe, ppe, _ = enc.encode_prompt(prompt=full, prompt_2=full, device='cuda', max_sequence_length=256)
            E[code] = (pe.to('cpu'), ppe.to('cpu'))
    del enc, te, te2; gc.collect(); torch.cuda.empty_cache(); log('R2 encoded', len(E))
except Exception as e:
    log('R2 setup failed', repr(e)[:300]); log(traceback.format_exc()[-900:]); log('NO PIPELINE'); sys.exit(2)
def emb(code): pe, ppe = E[code]; return dict(prompt_embeds=pe.to('cuda', bf), pooled_prompt_embeds=ppe.to('cuda', bf))
# pass 1: text to image, three seeds per new idea
p = FluxPipeline(scheduler=sch, vae=vae, text_encoder=None, tokenizer=None, text_encoder_2=None, tokenizer_2=None, transformer=tr)
p.enable_model_cpu_offload(); p.vae.enable_tiling()
for code, fac, title, prompt in P['items']:
    for sd in P.get('seeds',(11, 23, 37)):
        fn = os.path.join(OUT, f'{code}_{sd}.png')
        if os.path.exists(fn): continue
        t = time.time(); img = p(**emb(code), num_inference_steps=4, guidance_scale=0.0, height=1024, width=1024, generator=torch.Generator('cpu').manual_seed(sd)).images[0]
        img.save(fn); log('saved R11', os.path.basename(fn), f'{time.time()-t:.1f}s', names[code])
p.remove_all_hooks(); del p; gc.collect(); torch.cuda.empty_cache()
# pass 2: revise Ryan's picks (keeps the silhouette, pushes the style)
q = FluxImg2ImgPipeline(scheduler=sch, vae=vae, text_encoder=None, tokenizer=None, text_encoder_2=None, tokenizer_2=None, transformer=tr)
q.enable_model_cpu_offload(); q.vae.enable_tiling()
for out, init, code, st in P['img']:
    src = os.path.join(SRC, init)
    if not os.path.exists(src): log('missing init', init); continue
    im = Image.open(src).convert('RGB').resize((1024, 1024))
    for sd in (11, 23):
        fn = os.path.join(OUT, f'{out}_{sd}.png')
        if os.path.exists(fn): continue
        t = time.time(); img = q(**emb(code), image=im, strength=st, num_inference_steps=8, guidance_scale=0.0, height=1024, width=1024, generator=torch.Generator('cpu').manual_seed(sd)).images[0]
        img.save(fn); log('saved R4i', os.path.basename(fn), f'{time.time()-t:.1f}s', 'from', init, 'as', names[code])
log(P['done'])
