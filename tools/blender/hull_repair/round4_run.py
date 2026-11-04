"""Issue 146 isolated GPU comparison. Use RUN_PYRE_ROUND4.bat."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import textwrap
import time

sys.dont_write_bytecode=True
HERE=Path(__file__).resolve().parent
REPO=HERE.parents[2]
sys.path.insert(0,str(HERE.parent/'surface_bakeoff'))
import run as first
import round2_run as second
PC=first.PC
OUT=REPO/'docs/shots/ship_pipeline/pyre_round4'
REVIEW=PC/'board/issue-146/shots'
ROUTES=['today','V1','Raw','V2','V3']


def prepare(work):
    first.SHIPS={'C19_51':first.SHIPS['C19_51']}
    if not (work/'config.json').exists():first.prepare(work)
    shutil.copy2(HERE/'round4_probe.gd',work/'project/round4_probe.gd')
    cfg=json.loads((work/'config.json').read_text());cfg['routes']=ROUTES
    cfg['scripts']={p.name:first.sha(p) for p in HERE.glob('round4*') if p.is_file()}
    cfg['resume_repo_commit']=subprocess.check_output(['git','rev-parse','HEAD'],cwd=REPO,text=True).strip()
    first.dump(work/'config.json',cfg)


def launch_gpu(work,config,name):
    godot=PC/'godot/Godot_v4.7.2-stable_win64_console.exe'
    first.launch(godot,['--headless','--path',work/'project','--script','res://round4_probe.gd','--check-only'],work,'parse',60)
    first.launch(godot,['--path',work/'project','--resolution','1920x1080','--position','-2400,-1400',
        '--disable-vsync','--audio-driver','Dummy','--log-file',work/(name+'_engine.log'),
        '--script','res://round4_probe.gd','--',config],work,name,2400)


def game(work):
    project=second.prepare_game(work)
    text=(HERE.parent/'surface_bakeoff/round2_game.gd').read_text()
    text=text.replace('["today","Aplus","Bake","Reuse"]','cfg["routes"]')
    text=text.replace('surface111','round4146')
    text=text.replace('else 62.0','else 49.92')
    (project/'round4_game.gd').write_text(text)
    config=(project/'project.godot').read_text().replace('Surface111','Pyre146')
    (project/'project.godot').write_text(config)
    godot=PC/'godot/Godot_v4.7.2-stable_win64_console.exe'
    first.launch(godot,['--headless','--path',project,'--log-file',work/'game_import_engine.log',
        '--editor','--import','--quit'],work,'game_import',1200)
    first.launch(godot,['--path',project,'--resolution','1920x1080','--position','-2400,-1400',
        '--disable-vsync','--audio-driver','Dummy','--log-file',work/'game_engine.log',
        '--script','res://round4_game.gd','--',work/'config.json'],work,'game',2400)


def verify(work):
    from PIL import Image, ImageChops
    cfg=json.loads((work/'config.json').read_text());gpu=json.loads((work/'gpu.json').read_text())
    assert '5080' in gpu['adapter'] and gpu['renderer']=='forward_plus'
    assert gpu['resolution']==[1920,1080] and [r['route'] for r in gpu['rows']]==ROUTES
    assert gpu['capture_probe_sha256']==first.sha(HERE/'round4_probe.gd'),'Stale capture probe'
    builds={}
    for row in gpu['rows']:
        route=row['route']
        for kind in ['single','fleet']:
            assert row[kind]['frames']==360 and row[kind]['warmup']==100
            assert row[kind]['gpu_median_ms']>0
        for kind in ['battle','close','top','side','below','below_inspect','front','side_reference','quarter','top_reference']:
            assert Image.open(work/'shots'/f'C19_51_{route}_{kind}.png').size==(1920,1080)
        for kind in ['battle','close']:
            assert Image.open(work/'shots'/f'ingame_{route}_{kind}.png').size==(1920,1080)
        assert row['geometry']['world_length']==41.6
        if route=='today':continue
        if route!='Raw':
            assert set(row['material_crops'])=={'panel','bow'}
            for region in ['panel','bow']:
                for angle in ['head','grazing']:
                    assert Image.open(work/'shots'/f'material_{route}_{region}_{angle}.png').size==(1920,1080)
        folder=work/'C19_51'/route;b=json.loads((folder/'build.json').read_text());builds[route]=b
        assert first.sha(folder/('route'+route+'.glb'))==b['sha256']
        assert b['triangles']==row['geometry']['triangles']
        if route!='Raw':
            assert b['reimport']=='PASS' and b['reimport_triangles']==b['triangles']
            assert not b['projected_paint']
            if route in ['V1','V3']:
                assert all(d[0]>=0 for d in b['gun_directions'])
                assert max(p['gap'] for p in b['mount_anchors'])<.0001
        a=Image.open(work/'shots'/f'C19_51_{route}_close.png')
        control=Image.open(work/'shots/C19_51_today_close.png')
        assert ImageChops.difference(a,control).getbbox() is not None
    assert builds['Raw']['triangles']==builds['Raw']['source_triangles']
    assert not builds['Raw']['geometry_cleanup']
    reference_hashes=[first.sha(work/'reference/selection.json')]
    previous_selection=work/'reference/selection_before_battle_refresh.json'
    if previous_selection.exists():reference_hashes.append(first.sha(previous_selection))
    assert builds['V3']['reference_sha256'] in reference_hashes,'Unrecorded reference selection change'
    mesh_reference=json.loads((work/'reference/mesh.json').read_text())
    current_reference=json.loads((work/'reference/selection.json').read_text())
    assert all(current_reference[name]==filename for name,filename in mesh_reference['views'].items())
    raw=next(r for r in gpu['rows'] if r['route']=='Raw')['geometry']['raw_bounds']
    low=next(r for r in gpu['rows'] if r['route']=='V2')['geometry']['raw_bounds']
    assert all(abs(low[i]/low[0]-raw[i]/raw[0])<.04 for i in [1,2]),'Regeneration axes or uniform scale changed'
    assert 270000<=builds['V2']['triangles']<=320000
    b=builds['V2']['bake'];assert b['low_frequency_rms_after']<b['low_frequency_rms_before']*.6
    assert b['normal_mean_z']>.85
    for kind in ['head','grazing']:
        raw_proof=Image.open(work/'shots'/f'proof_raw_{kind}.png')
        filtered_proof=Image.open(work/'shots'/f'proof_filtered_{kind}.png')
        assert raw_proof.size==filtered_proof.size==(1920,1080)
        assert ImageChops.difference(raw_proof,filtered_proof).getbbox() is not None
    for info in cfg['today'].values():
        assert first.sha(info['packed_scene'])==info['sha256']
        for name,digest in info['maps'].items():assert first.sha(PC/'build/godot/assets/ships/C19_51'/name)==digest
    for name,marker in [('gpu.log','GPU PASS'),('game.log','GAME PASS')]:
        log=(work/name).read_text(errors='replace')
        assert marker in log and 'SCRIPT ERROR' not in log and 'Assertion failed' not in log
    checks=json.loads((work/'checks.json').read_text());assert checks['result']=='PASS'
    result=dict(result='PASS',routes=ROUTES,adapter=gpu['adapter'],world_length=41.6,
        screenshots=76,source_game_unchanged=True,gun_axes='forward or outward on authored replacements',
        capture_scripts_sha256=cfg['scripts'],
        high_pass='low-frequency normal deviation reduced; geometry waves are not claimed fixed',
        verifier_sha256=first.sha(__file__))
    first.dump(work/'verification.json',result)
    return builds


def sheets(work):
    from PIL import Image, ImageDraw, ImageFont
    import math
    import numpy as np
    builds=verify(work)
    OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
    fonts=Path(os.environ['WINDIR'])/'Fonts'
    regular=ImageFont.truetype(str(fonts/'segoeui.ttf'),18)
    bold=ImageFont.truetype(str(fonts/'segoeuib.ttf'),25)
    title=ImageFont.truetype(str(fonts/'segoeuib.ttf'),31)
    labels={'today':'TODAY','V1':'1  REPAIR + MATERIALS','Raw':'RAW GENERATION','V2':'2  REGENERATED + BAKE','V3':'3  HAND BUILT'}
    gpu=json.loads((work/'gpu.json').read_text())
    selection=json.loads((work/'reference/selection.json').read_text())
    verdict_path=OUT/'blob_sweeps.json'
    verdicts=json.loads(verdict_path.read_text()) if verdict_path.exists() else {}
    def canvas(size,label):
        im=Image.new('RGB',size,'#0a101b');ImageDraw.Draw(im).text((18,12),label,font=title,fill='white');return im,ImageDraw.Draw(im)
    def save(im,name):
        im.save(OUT/name,quality=94);shutil.copy2(OUT/name,REVIEW/name)
    def shot(route,kind):return Image.open(work/'shots'/f'C19_51_{route}_{kind}.png').convert('RGB')
    def paste(im,tile,at,size,crop=None):
        # thumbnail mutates its input. Reusing the master reference object
        # here would progressively shrink later crops and the saved references.
        tile=tile.crop(crop) if crop else tile.copy()
        tile.thumbnail(size,Image.Resampling.LANCZOS)
        im.paste(tile,(at[0]+(size[0]-tile.width)//2,at[1]+(size[1]-tile.height)//2))
    references={k:Image.open(work/'reference'/v).convert('RGB') for k,v in selection.items()}
    # Correct only the elevated drawing's camera roll for horizontal comparison.
    # Keep the untouched generated PNG, prompt and history in the review folder.
    tile=references['battle'];pixels=np.asarray(tile)
    background=np.median(np.concatenate([pixels[:8].reshape(-1,3),pixels[-8:].reshape(-1,3)]),axis=0)
    mask=np.max(abs(pixels.astype(float)-background),axis=2)>22
    yy,xx=np.nonzero(mask);xy=np.stack([xx,yy],1)
    _,axes=np.linalg.eigh(np.cov(xy.T));direction=axes[:,-1]
    if direction[0]<0:direction=-direction
    angle=math.degrees(math.atan2(direction[1],direction[0]))
    rotated=tile.rotate(angle,resample=Image.Resampling.BICUBIC,expand=True,fillcolor=tuple(map(int,background)))
    rotated_mask=Image.fromarray((mask*255).astype('uint8')).rotate(angle,expand=True)
    box=rotated_mask.getbbox();references['battle']=rotated.crop(box)
    presentation=dict(image=selection['battle'],camera_roll_correction_degrees=angle,crop=list(box),
        method='rigid image rotation and empty-background crop for sheet presentation only; native PNG unchanged')
    for folder in [OUT,REVIEW]:first.dump(folder/'reference_presentation.json',presentation)
    c,d=canvas((2880,1500),'Refreshed Pyre-Barge | five local Qwen views | original game renders anchor the layout')
    for i,kind in enumerate(['quarter','side','front','top','battle']):
        x=(i%3)*960;y=100+(i//3)*680
        d.text((x+16,y),'ELEVATED VIEW | approximate battle direction' if kind=='battle' else kind.upper(),font=bold,fill='#eecb85')
        paste(c,references[kind],(x+8,y+48),(944,570))
    x=1936;y=780
    notes=['MASTER NOTES | low, heavy, lopsided',
        'Bow right: dishes, scoops, folded boarding claws.',
        'Forward rocket clusters; chains between hull modules.',
        'Trophy plates in faded faction colours: flagship only.',
        'Stern left: red-orange bells. Dim red running lights.',
        'Soot / rust #6a2c22; trim #b8402a; glow #e0402c.',
        'Material targets used: roughness 0.61 to 0.88.',
        'Metalness: coated 0.07; exposed wear up to 0.76.',
        'Four conditioning views + one derived elevated view.',
        'Elevated art is rolled level for presentation only.',
        'Art directions approximate; views are not metrology.',
        'No back or underside reference was generated.',
        'Nominal hull + kit length: 41.6 game units.']
    for j,line in enumerate(notes):d.text((x,y+j*40),line,font=bold if j==0 else regular,fill='#eecb85' if j==0 else 'white')
    d.line((x,y+525,x+832,y+525),fill='white',width=3)
    for j in range(5):
        d.line((x+j*208,y+517,x+j*208,y+533),fill='white',width=2)
        d.text((x+j*208,y+543),f'{j*10.4:g}',font=regular,fill='white')
    d.text((x,y+590),'Nominal scale bar; model bounds use this total length.',font=regular,fill='#bac5d6')
    save(c,'reference_sheet.webp')
    routes=['today','V1','V2','V3'];w=720
    c,d=canvas((w*5,2570),'Round 4 | same model cameras, G4 light and 41.6 length | reference art shown separately')
    rows=[('battle',140,245,(608,417,1312,662),'Battle r=170 | 1:1 crop'),
          ('close',440,290,(448,275,1472,805),'Close zoom'),('close',800,280,(600,340,1320,660),'Round 1 detail crop'),
          ('front',1150,360,(448,275,1472,805),'Front'),
          ('side_reference',1570,360,(448,275,1472,805),'Side'),
          ('quarter',1990,360,(448,275,1472,805),'Three-quarter from front below')]
    for i,route in enumerate(routes):
        x=i*w;d.text((x+12,70),labels[route],font=bold,fill='#eecb85')
        for kind,y,height,crop,label in rows:
            paste(c,shot(route,kind),(x+8,y),(704,height),crop)
            d.text((x+12,y-29),label,font=regular,fill='#bac5d6')
        row=next(r for r in gpu['rows'] if r['route']==route)
        d.text((x+12,2420),f"{row['geometry']['triangles']:,} triangles",font=bold,fill='white')
        d.text((x+12,2460),f"20 ships GPU {row['fleet']['gpu_median_ms']:.3f} ms / frame {row['fleet']['frame_median_ms']:.3f} ms",font=regular,fill='white')
    x=w*4;d.text((x+12,70),'NEW REFERENCE',font=bold,fill='#eecb85')
    for kind,y,height,crop,label in rows:
        key={'front':'front','side_reference':'side','quarter':'quarter'}.get(kind,'battle')
        tile=references[key]
        if y==800:
            tile=tile.crop((int(tile.width*.35),int(tile.height*.3),int(tile.width*.75),int(tile.height*.7)))
            zoom=min(704/tile.width,height/tile.height)
            tile=tile.resize((round(tile.width*zoom),round(tile.height*zoom)),Image.Resampling.LANCZOS)
        paste(c,tile,(x+8,y),(704,height))
        d.text((x+12,y-29),'Reference art | '+('elevated, approximate' if key=='battle' else key),font=regular,fill='#bac5d6')
    d.text((x+12,2420),'Art views approximate the camera direction.',font=regular,fill='white')
    d.text((x+12,2460),'Model battle pixels remain at 1:1 scale.',font=regular,fill='white')
    save(c,'comparison.webp')
    for number,indices in enumerate([[0,1,4],[2,3,4]],1):
        page=Image.new('RGB',(w*3,2570),'#0a101b')
        for column,index in enumerate(indices):page.paste(c.crop((index*w,60,(index+1)*w,2570)),(column*w,60))
        ImageDraw.Draw(page).text((18,12),'Round 4 | readable comparison '+str(number),font=title,fill='white')
        save(page,'comparison_'+str(number)+'.webp')
    c,d=canvas((720*6,1120),'Actual game battle | HUD, board, ShipView and G4 lights | private in-memory prototypes')
    for i,route in enumerate(ROUTES):
        d.text((i*720+12,70),labels[route],font=bold,fill='#eecb85')
        for j,kind in enumerate(['battle','close']):
            tile=Image.open(work/'shots'/f'ingame_{route}_{kind}.png').convert('RGB')
            paste(c,tile,(i*720+4,150+j*460),(712,400))
            d.text((i*720+12,120+j*460),kind.upper(),font=regular,fill='#bac5d6')
    d.text((3612,70),'NEW REFERENCE ART',font=bold,fill='#eecb85')
    for j,key in enumerate(['battle','top']):
        paste(c,references[key],(3604,150+j*460),(712,400))
        d.text((3612,120+j*460),'Art | '+key+' | approximate direction',font=regular,fill='#bac5d6')
    save(c,'ingame.webp')
    for number,indices in enumerate([[0,1,5],[3,4,5]],1):
        page=Image.new('RGB',(2160,1120),'#0a101b')
        for column,index in enumerate(indices):page.paste(c.crop((index*720,60,(index+1)*720,1120)),(column*720,60))
        ImageDraw.Draw(page).text((18,12),'Actual game | readable comparison '+str(number),font=title,fill='white')
        save(page,'ingame_'+str(number)+'.webp')
    c,d=canvas((3600,1060),'Actual game | matched battle crop at 1:1 pixels, then close crop | camera r=170 / 49.92')
    for i,route in enumerate(ROUTES):
        x=i*720;d.text((x+12,70),labels[route],font=bold,fill='#eecb85')
        for kind,y,height,crop in [('battle',150,245,(608,417,1312,662)),('close',490,500,(448,275,1472,805))]:
            tile=Image.open(work/'shots'/f'ingame_{route}_{kind}.png').convert('RGB')
            paste(c,tile,(x+8,y),(704,height),crop)
            d.text((x+12,y-30),kind.upper()+' | '+('1:1 pixels' if kind=='battle' else 'same crop, reduced'),font=regular,fill='#bac5d6')
    save(c,'ingame_crops.webp')
    c,d=canvas((2160,1500),'Full generation before cleanup | native topology beside 300k cleanup and the new reference')
    for i,route in enumerate(['Raw','V2']):
        d.text((i*720+12,70),labels[route],font=bold,fill='#eecb85')
        for j,kind in enumerate(['close','side_reference','quarter']):paste(c,shot(route,kind),(i*720+4,140+j*420),(712,400),(448,275,1472,805))
    for j,key in enumerate(['top','side','quarter']):paste(c,references[key],(1444,140+j*420),(712,400))
    d.text((1460,70),'NEW REFERENCE',font=bold,fill='#eecb85')
    d.text((18,1430),'Raw display adds outward normals and a neutral inspection material; every generated face is retained.',font=regular,fill='white')
    save(c,'raw_and_cleanup.webp')
    c,d=canvas((1920,1320),'High-pass proof | same generated side panel, head-on and grazing | geometry remains unchanged')
    for i,state in enumerate(['raw','filtered']):
        for j,kind in enumerate(['head','grazing']):
            x=i*960;y=120+j*570
            d.text((x+16,y-32),state.upper()+' NORMAL / '+kind.upper(),font=bold,fill='#eecb85')
            paste(c,Image.open(work/'shots'/f'proof_{state}_{kind}.png').convert('RGB'),(x+4,y),(952,535))
    save(c,'high_pass_proof.webp')
    c,d=canvas((2880,2440),'Shared material recipe | actual broad panel and bow surfaces | head-on and grazing, same G4 lights')
    for i,route in enumerate(['V1','V2','V3']):
        x=i*960;d.text((x+16,70),labels[route],font=bold,fill='#eecb85')
        for j,(region,angle) in enumerate([('panel','head'),('panel','grazing'),('bow','head'),('bow','grazing')]):
            y=150+j*565
            d.text((x+16,y-32),region.upper()+' / '+angle.upper(),font=bold,fill='#bac5d6')
            paste(c,Image.open(work/'shots'/f'material_{route}_{region}_{angle}.png').convert('RGB'),(x+4,y),(952,535))
    save(c,'material_crops.webp')
    for route in ['V1','V2','V3']:
        c,d=canvas((2880,2170),labels[route]+' | nine-cell blob sweep | matched region crops beside new references')
        for j,kind in enumerate(['top','side','below_inspect']):
            tile=shot(route,kind).crop((448,275,1472,805))
            # Both studio views show bow right. Below uses the same +X direction.
            refkey='top' if kind=='top' else 'side'
            ref=references[refkey]
            mask=Image.open(work/'reference'/(refkey+'_mask.png'))
            assert mask.size==ref.size,'Reference mask no longer matches the selected view'
            ref=ref.crop(mask.getbbox())
            for k,name in enumerate(['STERN','MIDSHIP','BOW']):
                paste(c,tile.crop((k*1024//3,0,(k+1)*1024//3,530)),(k*960+4,130+j*650),(472,510))
                paste(c,ref.crop((k*ref.width//3,0,(k+1)*ref.width//3,ref.height)),(k*960+480,130+j*650),(472,510))
                d.text((k*960+12,95+j*650),name+' / '+kind.upper(),font=bold,fill='#eecb85')
                verdict=verdicts.get(route,{}).get(kind,['NOT REVIEWED']*3)[k]
                for line,text in enumerate(textwrap.wrap(verdict,88)):
                    d.text((k*960+12,650+j*650+line*26),text,font=regular,
                        fill='#a7e1b2' if verdict.startswith('CLEAN') else '#ffb196')
        d.text((18,2050),'Each cell: model at left, reference at right. Bow is at right in all locator views.',font=regular,fill='white')
        d.text((18,2090),'Each cell verdict and named repairs are in README.md. Underside uses the side reference as a locator only.',font=regular,fill='white')
        d.text((18,2125),'No underside concept was generated. Hidden form is judged from the model, not claimed proven by side art.',font=regular,fill='#eecb85')
        save(c,'nine_cells_'+route+'.webp')
    # All source captures and reference candidates remain available to Opus.
    for p in (work/'shots').glob('*.png'):shutil.copy2(p,REVIEW/p.name)
    models=REVIEW/'models';models.mkdir(exist_ok=True)
    for route in ROUTES[1:]:
        shutil.copy2(work/'C19_51'/route/('route'+route+'.glb'),models/('route'+route+'.glb'))
    mesh_record=json.loads((work/'reference/mesh.json').read_text())
    shutil.copy2(mesh_record['source'],models/'native_generation.glb')
    if (work/'iterations').exists():
        drafts=REVIEW/'drafts';drafts.mkdir(exist_ok=True)
        for p in (work/'iterations').glob('*.png'):shutil.copy2(p,drafts/p.name)
    for p in (work/'reference').iterdir():
        if p.is_file() and p.suffix in ['.png','.json','.log']:shutil.copy2(p,REVIEW/('reference_'+p.name))
    for key,tile in references.items():save(tile,'reference_'+key+'.webp')
    for name in ['gpu.json','checks.json','verification.json','config.json']:
        for folder in [OUT,REVIEW]:shutil.copy2(work/name,folder/name)
    shutil.copy2(work/'parity.txt',REVIEW/'parity.txt')
    for folder in [OUT,REVIEW]:first.dump(folder/'builds.json',builds)
    for name in ['selection.json','selection_before_battle_refresh.json','references.json','mesh.json','battle_target_prompt.json','battle_target_history.json']:
        if not (work/'reference'/name).exists():continue
        for folder in [OUT,REVIEW]:shutil.copy2(work/'reference'/name,folder/('reference_'+name))
    if verdict_path.exists():shutil.copy2(verdict_path,REVIEW/verdict_path.name)
    report=OUT/'README.md'
    if report.exists():
        content=report.read_text(encoding='utf-8')
        header='| Model | Triangles per ship | 20 ships GPU ms | Frame median ms | Frame p99 ms |\n|---|---:|---:|---:|---:|\n'
        names={'today':'Today','V1':'V1: repair and materials','Raw':'Raw generation','V2':'V2: regenerated and baked','V3':'V3: hand-built'}
        table=header+''.join(f"| {names[r['route']]} | {r['geometry']['triangles']:,} | {r['fleet']['gpu_median_ms']:.3f} | {r['fleet']['frame_median_ms']:.3f} | {r['fleet']['frame_p99_ms']:.3f} |\n" for r in gpu['rows'])
        start='<!-- performance-start -->';end='<!-- performance-end -->'
        if start in content and end in content:
            before,rest=content.split(start,1);_,after=rest.split(end,1)
            content=before+start+'\n'+table+end+after
            report.write_text(content,encoding='utf-8')
        shutil.copy2(report,REVIEW/report.name)
    print('[round4] SHEETS PASS',OUT,flush=True)


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--worker',action='store_true')
    ap.add_argument('--work',type=Path,default=Path(os.environ['TEMP'])/'voidsworn_issue146')
    ap.add_argument('--phase',choices=['all','reference','views','mesh','build','capture','game','sheets','checks'],default='all')
    ap.add_argument('--route',choices=ROUTES[1:]);a=ap.parse_args()
    work=a.work.resolve();assert work.is_relative_to(Path(os.environ['TEMP']).resolve())
    work.mkdir(parents=True,exist_ok=True)
    if not a.worker:
        queue=PC/'queue'/('pyre146_'+str(time.time_ns())+'.bat')
        py=Path.home()/'Downloads/ComfyUI_windows_portable/python_embeded/python.exe'
        command='@echo off\r\ncall "'+str(REPO/'tools/pc/tmo.bat')+'" 24000 "'+str(py)+'" -s -B "'+str(__file__)+'" --worker --work "'+str(work)+'" --phase '+a.phase
        if a.route:command+=' --route '+a.route
        command+=' > "'+str(work/('driver_'+a.phase+'.log'))+'" 2>&1\r\nexit /b %ERRORLEVEL%\r\n'
        staged=work/'queued_job.bat';staged.write_bytes(command.encode('utf-8'))
        shutil.copy2(staged,queue)
        print('Queued:',queue,'\nLogs:',work,flush=True);return
    os.environ['APPDATA']=str(work/'user')
    prepare(work)
    if a.phase in ['all','reference']:
        cfg=json.loads((work/'config.json').read_text());cfg['anchors_only']=True
        first.dump(work/'anchors.json',cfg)
        launch_gpu(work,work/'anchors.json','anchors')
        first.launch(sys.executable,['-s','-B',HERE/'round4_reference.py','--work',work,'--phase','reference'],work,'reference',7200)
        if a.phase=='reference':return
    if a.phase in ['all','mesh']:
        first.launch(sys.executable,['-s','-B',HERE/'round4_reference.py','--work',work,'--phase','mesh'],work,'mesh',3600)
        if a.phase=='mesh':return
    if a.phase=='views':
        first.launch(sys.executable,['-s','-B',HERE/'round4_reference.py','--work',work,'--phase','views'],work,'views',3600)
        return
    if a.phase in ['all','build']:
        blender=PC/'blender/blender-4.5.14-windows-x64/blender.exe'
        for route in ([a.route] if a.route else ROUTES[1:]):
            if route=='V1' and not (work/'base_repair/C19_51/S5/prototype.blend').exists():
                base=work/'base_repair';base.mkdir(exist_ok=True)
                for stage in ['trim','S5']:
                    first.launch(blender,['-b','--factory-startup','--python-exit-code','1','-P',HERE/'build.py',
                        '--','--pc',PC,'--work',base,'--stage',stage],work,'stage5_'+stage,2400)
            if route=='Raw':
                first.launch(sys.executable,['-s','-B',HERE/'round4_raw.py','--work',work],work,'build_Raw',1800)
                continue
            first.launch(blender,['-b','--factory-startup','--python-exit-code','1','-P',HERE/'round4_build.py',
                '--','--pc',PC,'--work',work,'--route',route],work,'build_'+route,7200)
        if a.phase=='build':return
    if a.phase in ['all','capture']:
        # A resumed capture must never silently mix an earlier material draft
        # with the final recipe on the other variants.
        blender=PC/'blender/blender-4.5.14-windows-x64/blender.exe'
        for route in ([a.route] if a.route and a.route!='Raw' else (['V1','V2','V3'] if not a.route else [])):
            record=work/'C19_51'/route/'build.json'
            b=json.loads(record.read_text()) if record.exists() else {}
            glb=work/'C19_51'/route/('route'+route+'.glb')
            stale=(not glb.exists() or b.get('sha256')!=first.sha(glb))
            if b.get('material',{}).get('version')!=14604 or stale or (route=='V3' and b.get('hand_version')!=14605):
                first.launch(blender,['-b','--factory-startup','--python-exit-code','1','-P',HERE/'round4_build.py',
                    '--','--pc',PC,'--work',work,'--route',route],work,'build_'+route,7200)
            fresh=json.loads(record.read_text());assert first.sha(glb)==fresh['sha256'],'Unverified partial export'
        config=work/'config.json'
        if a.route:
            cfg=json.loads(config.read_text());cfg['routes']=['today',a.route]
            cfg['gpu_out']=str(work/('gpu_'+a.route+'.json'));config=work/'route_config.json';first.dump(config,cfg)
        launch_gpu(work,config,'gpu_'+a.route if a.route else 'gpu')
    if a.phase in ['all','game']:game(work)
    if a.phase in ['all','checks']:
        first.launch(sys.executable,['-s','-B',HERE/'checks.py','--work',work],work,'checks',2400)
    if a.phase in ['all','sheets']:sheets(work)
    print('[round4] PHASE PASS',a.phase,flush=True)


if __name__=='__main__':main()
