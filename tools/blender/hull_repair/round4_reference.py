"""Local anchored Qwen references and full-resolution multi-view Pixal3D.

No external service, download, concept projection or shipping write.
"""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]


def dump(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')


def main(work, phase):
    from PIL import Image
    root = work/'reference'; root.mkdir(exist_ok=True)
    spec = importlib.util.spec_from_file_location('local_comfy', REPO/'tools/pc/comfy_run.py')
    cr = importlib.util.module_from_spec(spec); spec.loader.exec_module(cr)
    cr.VT = str(root); cr.LOG = str(root/'comfy.log'); cr.URL = 'http://127.0.0.1:8196'
    pack = (REPO/'contrib/muse/design/faction_looks_2026_11/synthesis.md').read_text(encoding='utf-8')
    section = pack.split('### 1. Flagship: Warlords Pyre Barge')[1].split('### 2.')[0]
    positive = section.split('Prompt: ')[1].split('\n')[0]
    negative = section.split('Negative: ')[1].split('\n')[0]
    manifest = root/'references.json'
    records = json.loads(manifest.read_text()) if manifest.exists() else {}
    # A private port avoids accidentally attaching to somebody else's server.
    try:
        cr.get('/system_stats')
    except Exception:
        pass
    else:
        raise RuntimeError('Port 8196 already in use; do not borrow another GPU session')
    py = Path.home()/'Downloads/ComfyUI_windows_portable/python_embeded/python.exe'
    log = (root/'server.log').open('a', encoding='utf-8')
    server = subprocess.Popen([str(py), '-s', str(Path(cr.C)/'main.py'),
        '--windows-standalone-build', '--listen', '127.0.0.1', '--port', '8196',
        '--output-directory', str(root), '--input-directory', str(root), '--disable-auto-launch'],
        cwd=cr.C, stdout=log, stderr=subprocess.STDOUT)
    try:
        for _ in range(240):
            if server.poll() is not None: raise RuntimeError('ComfyUI exited; see reference/server.log')
            try:
                info = cr.get('/system_stats'); break
            except Exception: time.sleep(2)
        else: raise RuntimeError('ComfyUI startup timed out')
        dump(root/'system.json', info)
        if phase in ['reference','views']:
            tasks = [('quarter',146), ('quarter_alt',147), ('side',146), ('front',146), ('top',146),
                     ('quarter_final',148),('side_final',148),('front_final',148),('top_final',148)]
            if phase=='views':tasks=[]
            camera = {'quarter':'three quarter view from front below, the bow pointing right',
                      'quarter_alt':'three quarter view from front below, the bow pointing right',
                      'side':'exact right side orthographic view, bow at right, stern at left',
                      'front':'exact front orthographic view looking directly at the bow',
                      'top':'exact top orthographic view, bow at right, stern at left'}
            for name, seed in tasks:
                if name in records: continue
                base_name=name.replace('_final','')
                anchor_name = {'side':'side_reference','top':'top_reference','quarter_alt':'quarter'}.get(base_name,base_name)
                source = work/'shots'/('anchor_'+anchor_name+'.png')
                # Crop only empty background. The ship pixels remain unedited.
                Image.open(source).convert('RGB').crop((320,190,1600,890)).save(root/(name+'_anchor.png'))
                prompt = ('Refresh the spacecraft in the input render into this faction concept. '
                    'Keep the recognisable long low bundled hull masses and their relative scale and placement. '
                    'Replace the old naval-like towers with low spacecraft equipment and radiators. '
                    'Preserve the overall length to width ratio. ' + positive + '. '
                    'For this reference view use '+camera[base_name]+'. '
                    'Show the entire single ship with clear silhouette, on a plain light grey background, '
                    'no stars, no asteroids, no shield bubble, no floor, no shadow on the background. '
                    'No labels. Surface detail must be readable; avoid crushed black. '
                    'The source render sets the layout. This is a refreshed design, not a copy of its paint.')
                if name.endswith('_final'):
                    prompt = ('Build a SPACECRAFT from bundled salvaged industrial spaceship fuselages. '
                        'The RIGHT end is the blunt armoured BOW, the LEFT end has the glowing rear engines. '
                        'Add two large shallow circular listening dishes and rectangular sensor scoops on the forward RIGHT third. '
                        'Replace the long lance with dense box clusters of short rocket launch tubes pointing RIGHT, '
                        'and short broad gun barrels pointing right or outward. Add folded jointed boarding claws at the right bow. '
                        'Add visible chain links between the separate salvaged hull modules. '
                        'Break any continuous boat-like side edge with stepped armour blocks, exposed pipe joints and side pods. '
                        'Remove any naval bow, ship railing, flat boat deck, mast or conning tower. '
                        'Keep a blunt vertical bow face and a flat armoured belly with angled chines. '
                        'No long lance, no backward weapons, no raked bow, no keel, no smokestack. '+prompt)
                p = cr.qwen_prompt(name+'_anchor.png', prompt, seed, 'generated/'+name,
                                   full=True, angle_w=0.0 if name.startswith('quarter') else .6)
                # Later views also see the selected quarter so the refresh is shared.
                if base_name in ['side','front','top'] or name=='quarter_final':
                    shared='quarter_final.png' if name.endswith('_final') and name!='quarter_final' else ('quarter_alt.png' if name=='quarter_final' else 'quarter.png')
                    p['18'] = {'class_type':'LoadImage','inputs':{'image':shared}}
                    p['10']['inputs']['image2'] = ['18',0]
                    p['11']['inputs']['image2'] = ['18',0]
                    p['10']['inputs']['prompt'] += ' The second image defines the same refreshed ship. Match its parts and colours.'
                p['11']['inputs']['prompt'] = negative
                dump(root/(name+'_prompt.json'),p)
                start = time.perf_counter(); h = cr.run(p, '146 '+name, timeout=1200)
                dump(root/(name+'_history.json'),h)
                if not h or h.get('status',{}).get('status_str') != 'success': raise RuntimeError('Reference failed: '+name)
                output = h['outputs']['17']['images'][0]
                shutil.copy2(root/output.get('subfolder','')/output['filename'], root/(name+'.png'))
                records[name] = dict(image=name+'.png', anchor=str(source), seed=seed,
                    seconds=time.perf_counter()-start, faction_prompt=positive, faction_negative=negative,
                    model='Qwen-Image-Edit-2511 fp8, Lightning 8 steps', status='candidate, visual selection required')
                dump(manifest,records)
            import numpy as np
            from scipy import ndimage
            selected={}
            for name in ['quarter','side','front','top']:
                im=Image.open(root/(name+'_final.png')).convert('RGB');pixels=np.array(im)
                bg=np.median(np.concatenate([pixels[:8].reshape(-1,3),pixels[:,-8:].reshape(-1,3)]),axis=0)
                mask=np.max(abs(pixels.astype(float)-bg),axis=2)>24
                labels,count=ndimage.label(mask);sizes=np.bincount(labels.ravel());sizes[0]=0
                largest=labels==int(sizes.argmax())
                near=ndimage.binary_dilation(largest,iterations=14)
                keep=np.unique(labels[near]);keep=keep[keep!=0]
                mask=np.isin(labels,keep)
                pixels[~mask]=bg.astype('uint8')
                filename=name+'_selected.png';Image.fromarray(pixels).save(root/filename);selected[name]=filename
                records[name+'_selection']=dict(source=name+'_final.png',image=filename,
                    edit='remove disconnected background artifacts only; retain largest ship component and nearby parts')
            for name,view in [('side','right side view eye-level shot medium shot'),
                              ('front','front view eye-level shot medium shot'),
                              ('top','top view high-angle shot bird eye view overhead shot'),
                              ('battle','right side view high-angle shot medium shot')]:
                filename='front_headon.png' if name=='front' else ('battle_target.png' if name=='battle' else name+'_ortho.png')
                if not (root/filename).exists():
                    source='quarter_selected.png'
                    instruction=view+'. Show this same spacecraft from the requested camera. '
                    instruction+='Keep the design and colours, show the whole ship, plain light grey background. '
                    instruction+='Exact top-down orthographic plan, see the top surfaces only. ' if name=='top' else ''
                    instruction+='Exact flat side elevation, bow at right, engines at left. ' if name=='side' else ''
                    if name=='front':instruction='front view eye-level shot medium shot'
                    if name=='battle':
                        instruction=(view+'. Change ONLY the viewing camera of this exact spacecraft. '
                            'Show its right side from about 34 degrees above the horizon, bow right and engines left. '
                            'Preserve all hull masses, their relative proportions, the stepped side pods, the exact soot/rust '
                            'material zones, trophy plates, dishes, rocket clusters, claws and chains of the reference. '
                            'Do not redesign, add or remove parts. Show the entire single ship on plain light grey, '
                            'no floor, no shadow, no stars, no labels. The reference design is the invariant.')
                    key='battle_target' if name=='battle' else name+'_ortho'
                    p=cr.qwen_prompt(source,instruction,155 if name=='battle' else (152 if name=='front' else 149),'generated/'+key,full=True,angle_w=1.15 if name=='front' else .95)
                    p['11']['inputs']['prompt']=negative
                    dump(root/(key+'_prompt.json'),p)
                    start=time.perf_counter();h=cr.run(p,'146 orthographic '+name,timeout=1200)
                    dump(root/(key+'_history.json'),h)
                    if not h or h.get('status',{}).get('status_str')!='success':raise RuntimeError('View failed: '+name)
                    output=h['outputs']['17']['images'][0]
                    shutil.copy2(root/output.get('subfolder','')/output['filename'],root/filename)
                    records[key]=dict(image=filename,source=source,seconds=time.perf_counter()-start,
                        camera=view,model='Qwen-Image-Edit-2511, multiple-angles .95, Lightning 8 steps')
                selected[name]=filename
            prior=root/'selection.json'
            if prior.exists() and json.loads(prior.read_text()).get('battle')!=selected['battle']:
                shutil.copy2(prior,root/'selection_before_battle_refresh.json')
            dump(root/'selection.json',selected);dump(manifest,records)
        else:
            from PIL import ImageOps
            import numpy as np
            from scipy import ndimage
            selection = json.loads((root/'selection.json').read_text())
            mv = root/'mv'; mv.mkdir(exist_ok=True)
            cams = []
            # The installed orbit camera has front=-Y. At azimuth 270 the
            # bow projects right, matching the selected side and plan views.
            for name, angles in [('front',(0,0)),('side',(270,0)),('top',(270,89)),('quarter',(315,-24))]:
                # Shared canvas and scale from the reference's own silhouette.
                im = Image.open(root/selection[name]).convert('RGB')
                pixels=np.asarray(im).astype(np.float32)
                border=np.concatenate([pixels[:8].reshape(-1,3),pixels[-8:].reshape(-1,3),pixels[:,:8].reshape(-1,3),pixels[:,-8:].reshape(-1,3)])
                bg=np.median(border,axis=0)
                mask=np.max(abs(pixels-bg),axis=2)>22
                labels,count=ndimage.label(mask)
                sizes=np.bincount(labels.ravel());sizes[0]=0
                mask=np.isin(labels,np.where(sizes>sizes.max()*.008)[0])
                mask=ndimage.binary_fill_holes(mask)
                pixels[~mask]=0
                Image.fromarray((mask*255).astype('uint8')).save(root/(name+'_mask.png'))
                im=Image.fromarray(pixels.astype('uint8'))
                im = ImageOps.pad(im,(1536,1536),color=(0,0,0))
                im.save(mv/('round4_'+name+'.png')); cams.append(angles)
            p = cr.pixal_api('round4', ['front','side','top','quarter'], cams=cams,
                res=2048, tag='', raw=True)
            # Decimate the native surface directly. Remeshing would melt the detail.
            p['dec']['inputs']['mesh']=['shape',0]
            p['dec']['inputs']['target_face_count']=300000
            p['uv']['inputs']['resolution']=4096
            p['uv']['inputs']['padding']=4
            p['nm']['inputs'].update(high_poly=['shape',0],resolution=4096,cage_distance=.012,ignore_backfaces=False)
            p['o_low']={'class_type':'SaveGLB','inputs':{'mesh':['uv',0],'filename_prefix':'mesh/round4_2048_low'}}
            p['o_nm']['inputs']['filename_prefix']='mesh/round4_2048_normal'
            p=cr.prune(p,['o_raw','o_low','o_nm'])
            p['o_raw']['inputs']['filename_prefix'] = 'mesh/round4_2048_raw'
            dump(root/'mesh_prompt.json',p)
            start=time.perf_counter();h=cr.run(p,'146 full ship',timeout=2400)
            dump(root/'mesh_history.json',h)
            if not h or h.get('status',{}).get('status_str')!='success': raise RuntimeError('Pixal3D failed')
            files=sorted((root/'mesh').glob('round4_2048_raw*.glb'))
            low=sorted((root/'mesh').glob('round4_2048_low*.glb'))
            normal=sorted((root/'mesh').glob('round4_2048_normal*.png'))
            assert files and low and normal
            if (root/'mesh.json').exists():shutil.copy2(root/'mesh.json',root/'mesh_previous.json')
            dump(root/'mesh.json',dict(source=str(files[-1]),resolution=2048,views=selection,cameras=cams,
                seconds=time.perf_counter()-start,model='installed Pixal3D multiview / TRELLIS.2 cascade',
                raw=True,projected_paint=False,low=str(low[-1]),normal=str(normal[-1]),target_triangles=300000,
                cleanup='native QEM decimation without remeshing, unique UVs, 4096 tangent normal bake'))
    finally:
        server.terminate(); server.wait(40); log.close()


if __name__ == '__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--work',type=Path,required=True)
    ap.add_argument('--phase',choices=['reference','views','mesh'],required=True);a=ap.parse_args()
    assert a.work.resolve().is_relative_to(Path(os.environ['TEMP']).resolve())
    main(a.work.resolve(),a.phase)
