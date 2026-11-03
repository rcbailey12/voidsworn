"""Issue 129: isolated concept crops, local Qwen cleanup, local Pixal3D parts.

The installed ComfyUI and models are used without downloads. All server logs,
inputs, prompts, history and generated meshes stay in the supplied TEMP folder.
"""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import shutil
import sys
import time

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]


def load_comfy(work):
    spec = importlib.util.spec_from_file_location('repair_comfy', REPO/'tools/pc/comfy_run.py')
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    mod.VT = str(work)
    mod.LOG = str(work/'comfy.log')
    return mod


def crops(work):
    from PIL import Image
    source = REPO/'docs/ship_pipeline/c19_example/views_left.webp'
    # Bounds are pixels in the 1024-pixel generated side reference, not a
    # fabricated new drawing. Save the untouched crop beside every AI result.
    boxes = {'engine': (810, 506, 980, 630), 'gun': (645, 610, 743, 677),
             'bridge': (416, 391, 575, 480), 'midships': (369, 473, 596, 615)}
    im = Image.open(source).convert('RGB')
    records = {}
    for name, box in boxes.items():
        crop = im.crop(box)
        crop.save(work/(name+'_crop.png'))
        # Padding changes no crop pixels. Qwen, rather than interpolation
        # alone, gets the explicitly requested chance to isolate small parts.
        crop.thumbnail((700, 700))
        canvas = Image.new('RGB', (768, 768), 'white')
        canvas.paste(crop, ((768-crop.width)//2, (768-crop.height)//2))
        canvas.save(work/(name+'_input.png'))
        records[name] = dict(source=str(source), box=box, original_pixels=list(im.crop(box).size))
    return records


def generate(work, phase, retry=None):
    work.mkdir(parents=True, exist_ok=True)
    manifest_path = work/'parts.json'
    records = json.loads(manifest_path.read_text()) if manifest_path.exists() else crops(work)
    if retry:
        from PIL import Image
        row = records[retry]
        previous={k:v for k,v in row.items() if k!='previous_attempts'}
        row.setdefault('previous_attempts', []).append(previous)
        for key in ['clean_image','mesh','packed_mesh']:
            row.pop(key,None)
        if retry == 'bridge':
            crop=Image.open(REPO/'docs/ship_pipeline/c19_example/views_left.webp').convert('RGB').crop((416,416,575,480))
            crop=crop.resize((700,282),Image.Resampling.LANCZOS)
            canvas=Image.new('RGB',(768,768),'white');canvas.paste(crop,(34,243))
            canvas.save(work/'bridge_input.png')
            row['retry_reason']='first cleanup invented a tall naval-looking lattice tower'
        manifest_path.write_text(json.dumps(records,indent=2)+'\n')
    cr = load_comfy(work)
    server = cr.start(str(work))
    try:
        for name, row in records.items():
            if retry and name != retry:
                continue
            suffix='_retry'+str(len(row.get('previous_attempts',[]))) if retry else ''
            if phase in ['edit', 'all'] and not row.get('clean_image'):
                desc = {'engine': 'rear spacecraft engine block with its exhaust housings',
                        'gun': 'single spacecraft gun turret with its barrel and mounting base',
                        'bridge': 'low compact spacecraft bridge with three broad stacked armoured roof tiers',
                        'midships': 'single midships armoured spacecraft hull section'}[name]
                prompt = cr.qwen_prompt(name+'_input.png',
                    'Isolate and enlarge only the '+desc+' shown in this reference crop. '
                    'Preserve its exact proportions, red worn metal, mechanical detail and side view. '
                    'Remove all neighbouring ship parts. Keep only the low wide bridge tiers if a bridge. '
                    'No tall mast, no lattice tower, no platform on a pole, no underside pedestal. '
                    'One complete separate object, plain white background, no text, no added guns, no naval fittings.',
                    129+len(row.get('previous_attempts',[])), 'clean/'+name+suffix, full=True, angle_w=0.0)
                start = time.perf_counter()
                history = cr.run(prompt, '129 isolate '+name, timeout=600)
                (work/(name+suffix+'_edit_history.json')).write_text(json.dumps(history, indent=2))
                if not history or history.get('status', {}).get('status_str') != 'success':
                    raise RuntimeError('Qwen failed for '+name)
                images = history['outputs']['17']['images']
                image = images[0]
                clean = work/image.get('subfolder', '')/image['filename']
                shutil.copy2(clean, work/(name+suffix+'_clean.png'))
                row.update(clean_image=name+suffix+'_clean.png', edit_seconds=time.perf_counter()-start)
                (work/(name+suffix+'_edit_prompt.json')).write_text(json.dumps(prompt, indent=2))
                manifest_path.write_text(json.dumps(records, indent=2)+'\n')
            if phase in ['mesh', 'all'] and not row.get('mesh'):
                mv = work/'mv'; mv.mkdir(exist_ok=True)
                shutil.copy2(work/row['clean_image'], mv/('part_'+name+'.png'))
                # Single part uses the full 1536 shape cascade. Keep the raw
                # geometry output: no whole-ship triangle allocation or decimator.
                prompt = cr.prune(cr.pixal_api('part', [name], cams=[(90, 0)],
                    res=1536, tag='', raw=True), ['o_raw'])
                prompt['o_raw']['inputs']['filename_prefix'] = 'mesh/'+name+suffix+'_raw'
                start = time.perf_counter()
                history = cr.run(prompt, '129 mesh '+name, timeout=1200)
                (work/(name+suffix+'_mesh_history.json')).write_text(json.dumps(history, indent=2))
                (work/(name+suffix+'_mesh_prompt.json')).write_text(json.dumps(prompt, indent=2))
                if not history or history.get('status', {}).get('status_str') != 'success':
                    raise RuntimeError('Pixal3D failed for '+name)
                files = sorted((work/'mesh').glob(name+suffix+'_raw*.glb'))
                if not files:
                    raise RuntimeError('No generated mesh for '+name)
                row.update(mesh=str(files[-1]), generation_seconds=time.perf_counter()-start,
                           resolution=1536, decimated=False)
                manifest_path.write_text(json.dumps(records, indent=2)+'\n')
    finally:
        server.terminate()
        server.wait(30)


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', type=Path, required=True)
    ap.add_argument('--phase', choices=['edit', 'mesh', 'all'], default='all')
    ap.add_argument('--retry',choices=['bridge','engine','gun','midships'])
    args = ap.parse_args()
    assert args.work.resolve().is_relative_to(Path(os.environ['TEMP']).resolve())
    generate(args.work.resolve(), args.phase,args.retry)
