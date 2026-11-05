"""Round 6 evidence, integrity checks and a matched blurred value comparison."""
import json
import os
from pathlib import Path
import shutil
import textwrap

import numpy as np
from PIL import Image,ImageDraw,ImageFont,ImageFilter

import round6_run as run
from round5_sheets import reference,silhouette,geometry_digest,classify,CLASSES,ANCHORS
first=run.first
CROPS={'battle':(608,417,1312,662),'close':(448,275,1472,805)}


def verify(work):
    cfg=json.loads((work/'config.json').read_text());gpu=json.loads((work/'gpu.json').read_text())
    assert '5080' in gpu['adapter'] and gpu['renderer']=='forward_plus'
    assert gpu['resolution']==[1920,1080] and [r['route'] for r in gpu['rows']]==run.ROUTES
    assert gpu['active_probe_sha256']==first.sha(run.HERE/'round6_probe.gd')
    assert gpu['capture_probe_sha256']==first.sha(run.HERE/'round4_probe.gd')
    builds={};ceiling={}
    for row in gpu['rows']:
        route=row['route'];assert row['geometry']['world_length']==41.6
        for kind in ['single','fleet']:
            assert row[kind]['frames']==360 and row[kind]['warmup']==100 and row[kind]['gpu_median_ms']>0
        for kind in ['battle','close','top','side','below','below_inspect','front','side_reference','quarter','top_reference']:
            assert Image.open(work/'shots'/f'C19_51_{route}_{kind}.png').size==(1920,1080)
        for kind in ['battle','close']:
            assert Image.open(work/'shots'/f'ingame_{route}_{kind}.png').size==(1920,1080)
            assert Image.open(work/'shots'/f'C19_51_{route}_{kind}_mask.png').size==(1920,1080)
        for suffix in ['_4k','_mask_4k']:
            assert Image.open(work/'shots'/f'C19_51_{route}_battle{suffix}.png').size==(3840,2160)
        for kind in ['top','side','below_inspect']:
            assert Image.open(work/'shots'/f'C19_51_{route}_{kind}_clay.png').size==(1920,1080)
        if route=='today':continue
        folder=work/'C19_51'/route;b=json.loads((folder/'build.json').read_text());builds[route]=b
        assert b['triangles']==b['reimport_triangles']==row['geometry']['triangles'] and b['reimport']=='PASS'
        assert first.sha(folder/f'route{route}.glb')==b['sha256']
        assert b['recipe_sha256']==first.sha(run.HERE/'round6_material.py')
        assert b['builder_sha256']==first.sha(run.HERE/'round6_build.py') and not b['projected_paint']
        assert gpu['material_inputs'][route]
        assert all(abs(m['specular']-b['material']['coat_specular_ior_level'])<.00001 for m in gpu['material_inputs'][route])
        assert all(d[0]>=0 for d in b['gun_directions'])
        assert max(p['gap'] for p in b['mount_anchors'])<.0001
        if route=='V1':
            assert first.sha(b['source'])==b['source_sha256']
            old=Path(cfg['cache'])/'C19_51/V1/routeV1.glb'
            assert geometry_digest(old)==geometry_digest(folder/'routeV1.glb'),'V1 geometry changed'
        else:
            assert b['triangles']<=306000
            assert b['cut']['before_triangles']+1620==cfg['round4_geometry']['V3']['triangles']
        for region in ['panel','bow']:
            for angle in ['head','grazing']:assert Image.open(work/'shots'/f'material_{route}_{region}_{angle}.png').size==(1920,1080)
        ceiling[route]=dict(triangles=b['triangles'],triangle_ceiling=306000,triangle_pass=b['triangles']<=306000,
            gpu_ms=row['fleet']['gpu_median_ms'],gpu_ceiling_ms=3.9,gpu_pass=row['fleet']['gpu_median_ms']<=3.9)
    for name,digest in cfg['round6_game_code_sha256'].items():assert first.sha(run.REPO/name)==digest
    selection=json.loads((work/'reference/selection.json').read_text());cache=Path(cfg['cache'])
    assert selection==json.loads((cache/'reference/selection.json').read_text())
    for name in selection.values():assert first.sha(work/'reference'/name)==first.sha(cache/'reference'/name)
    for info in cfg['today'].values():
        assert first.sha(info['packed_scene'])==info['sha256']
        for name,digest in info['maps'].items():assert first.sha(run.PC/'build/godot/assets/ships/C19_51'/name)==digest
    for name,marker in [('gpu.log','GPU PASS'),('game.log','GAME PASS')]:
        log=(work/name).read_text(errors='replace');assert marker in log and 'SCRIPT ERROR' not in log and 'Assertion failed' not in log
    assert json.loads((work/'checks.json').read_text())['result']=='PASS'
    imported=json.loads((work/'game_material_import.json').read_text())
    assert imported['probe_sha256']==first.sha(run.HERE/'round6_game.gd')
    assert [r['route'] for r in imported['rows']]==run.ROUTES[1:]
    assert all(abs(m['specular']-cfg['coat_specular_ior_level'])<.00001 for row in imported['rows'] for m in row['materials'])
    first.dump(work/'verification.json',dict(result='PASS',source_game_unchanged=True,V1_geometry_unchanged=True,
        routes=run.ROUTES,ceiling=ceiling,verifier_sha256=first.sha(__file__),
        caveat='Evidence integrity is separate from ceiling, nine-cell and owner visual acceptance.'))
    return builds


def value_structure(work,refs,canvas,paste,save,regular,bold,scale=1):
    """Equal projected width and neutral background; no histogram matching."""
    images={};masks={};metrics=[];colour=[]
    crop=tuple(v*scale for v in CROPS['battle']);suffix='_4k' if scale==2 else ''
    for route in run.ROUTES:
        image=Image.open(work/'shots'/f'C19_51_{route}_battle{suffix}.png').convert('RGB')
        mask=Image.open(work/'shots'/f'C19_51_{route}_battle_mask{suffix}.png').convert('L').point(lambda v:255 if v>127 else 0)
        clean=Image.new('RGB',image.size,'#131313');clean.paste(image,mask=mask)
        images[route]=clean.crop(crop)
        masks[route]=mask.crop(crop)
        pixels=np.asarray(image.crop(crop)).astype(float);inside=np.asarray(mask.crop(crop))>127
        counts=np.bincount(classify(pixels)[inside],minlength=4)
        colour.append(dict(route=route,share_percent={k:float(v) for k,v in zip(CLASSES,counts/counts.sum()*100)},
            median_srgb_luma=float(np.median(pixels[inside]@np.array([.2126,.7152,.0722])))))
    for route in ['V3','V1']:
        target=Image.open(work/'shots'/f'C19_51_{route}_battle_mask{suffix}.png').convert('L').point(lambda v:255 if v>127 else 0)
        bounds=target.getbbox();assert bounds
        art=refs['battle'];mask=Image.fromarray(silhouette(art).astype('uint8')*255)
        box=mask.getbbox();art=art.crop(box);mask=mask.crop(box)
        factor=(bounds[2]-bounds[0])/art.width
        size=(round(art.width*factor),round(art.height*factor))
        art=art.resize(size,Image.Resampling.LANCZOS);mask=mask.resize(size,Image.Resampling.NEAREST)
        clean=Image.new('RGB',(1920*scale,1080*scale),'#131313')
        at=(round((bounds[0]+bounds[2]-size[0])/2),round((bounds[1]+bounds[3]-size[1])/2))
        clean.paste(art,at,mask);images['reference_'+route]=clean.crop(crop)
        fullmask=Image.new('L',clean.size);fullmask.paste(mask,at)
        masks['reference_'+route]=fullmask.crop(crop)
        pixels=np.asarray(clean.crop(crop)).astype(float);inside=np.asarray(fullmask.crop(crop))>127
        counts=np.bincount(classify(pixels)[inside],minlength=4)
        colour.append(dict(route='reference_'+route,share_percent={k:float(v) for k,v in zip(CLASSES,counts/counts.sum()*100)},
            median_srgb_luma=float(np.median(pixels[inside]@np.array([.2126,.7152,.0722])))))
    sigma=7.5*scale
    c,d=canvas((2880,1160),f'Battle value structure | {1080*scale}p source | Rec.709 then {sigma:g} px Gaussian blur')
    for i,route in enumerate(['V3','reference_V3','V1','reference_V1']):
        im=images[route];rgb=np.asarray(im).astype(np.float32)
        grey=Image.fromarray(np.clip(rgb@np.array([.2126,.7152,.0722]),0,255).astype('uint8'))
        blurred=grey.filter(ImageFilter.GaussianBlur(sigma))
        for j,tile in enumerate([im,grey.convert('RGB'),blurred.convert('RGB')]):
            paste(c,tile,(i*720+8,140+j*310),(704,245))
        d.text((i*720+12,76),route.replace('_',' ').upper(),font=bold,fill='#eecb85')
        for j,label in enumerate(['COLOUR | '+('1:1' if scale==1 else '4K reduced for this sheet'),'GREYSCALE | Rec.709 sRGB luma',f'BLUR | sigma {sigma:g} source pixels']):
            d.text((i*720+12,112+j*310),label,font=regular,fill='#bac5d6')
        values=np.asarray(blurred).astype(float)
        occupied=np.asarray(masks[route])>127
        sample=values[occupied]
        metrics.append(dict(route=route,blur_sigma_source_pixels=sigma,p10=float(np.percentile(sample,10)),
            p90=float(np.percentile(sample,90)),median=float(np.median(sample)),
            gradient_rms=float(np.sqrt(np.mean(np.diff(values,axis=1)**2)))))
        im.save(work/'shots'/f'value_{route}_colour{suffix}.png');grey.save(work/'shots'/f'value_{route}_grey{suffix}.png')
        blurred.save(work/'shots'/f'value_{route}_blur{suffix}.png')
    d.text((18,1090),'Art fitted to each variant projected width, aspect preserved. No exposure or histogram matching.',font=regular,fill='white')
    d.text((18,1125),'Neutral background replaces stars and art backdrop. Reference camera and painted lighting remain approximate.',font=regular,fill='#bac5d6')
    save(c,'value_structure'+suffix+'.webp')
    for r in colour:
        if r['route'] in ['V3','V1']:
            ref=next(x for x in colour if x['route']=='reference_'+r['route'])
            r['median_delta_from_reference']=r['median_srgb_luma']-ref['median_srgb_luma']
            r['S10_fail']=abs(r['median_delta_from_reference'])>10
            r['S10_target']=abs(r['median_delta_from_reference'])<=5
            r['S6_rust_band']=5<=r['share_percent']['rust']<=15
            r['S8_trim_max']=r['share_percent']['red_trim']<=2
    first.dump(work/('value_structure'+suffix+'.json'),dict(method=f'Rec.709 weighted sRGB greyscale, Gaussian sigma {sigma:g} px at native battle scale',
        rows=metrics,acceptance='Visual judgement of broad masses; no invented numerical pass threshold',
        measurements='Descriptive crop statistics; gradient includes silhouette, never a geometry score'))
    first.dump(work/('colour_balance'+suffix+'.json'),dict(rows=colour,anchors_srgb=ANCHORS.tolist(),
        method='Unchanged round 5 classifier and warm-hue gate; ship pixels only; each art copy fitted to its variant width',
        standard='Issue 188 S6, S8 and S10; binding at 1080p. Colour shares alone cannot approve paint.'))


def main(work):
    builds=verify(work);refs=reference(work)
    cfg=json.loads((work/'config.json').read_text());gpu=json.loads((work/'gpu.json').read_text())
    cfg['scripts']['round6_sheets.py']=first.sha(__file__)
    cfg['paint_standard']={
        'url':'https://github.com/rcbailey12/voidsworn/blob/eb945198f2059f20654d86e1b83fcbd157c6f0d5/contrib/muse/research/readable_paint_2026_11/synthesis.md',
        'merged_pr':191,'merged_at':'2026-11-05T03:34:27Z','owner_adoption':'FINDINGS R105, read from main during this run',
        'binding_resolution':[1920,1080],'blur_sigma_pixels':7.5,'record_resolution':[3840,2160],'record_blur_sigma_pixels':15}
    first.dump(work/'config.json',cfg)
    out=run.OUT;review=run.REVIEW;out.mkdir(parents=True,exist_ok=True);review.mkdir(parents=True,exist_ok=True)
    fonts=Path(os.environ['WINDIR'])/'Fonts'
    regular=ImageFont.truetype(str(fonts/'segoeui.ttf'),18);bold=ImageFont.truetype(str(fonts/'segoeuib.ttf'),25)
    title=ImageFont.truetype(str(fonts/'segoeuib.ttf'),31)
    labels={'today':'TODAY','V3':'A  V3 CUT + SIMPLE PAINT','V1':'B  V1 + SIMPLE PAINT','reference':'ROUND 4 REFERENCE'}
    def canvas(size,label):
        im=Image.new('RGB',size,'#0a101b');d=ImageDraw.Draw(im);d.text((18,12),label,font=title,fill='white');return im,d
    def save(im,name):
        im.save(out/name,quality=94);shutil.copy2(out/name,review/name)
    def paste(im,tile,at,size,crop=None):
        tile=tile.crop(crop) if crop else tile.copy();tile.thumbnail(size,Image.Resampling.LANCZOS)
        im.paste(tile,(at[0]+(size[0]-tile.width)//2,at[1]+(size[1]-tile.height)//2))
    def shot(route,kind):return Image.open(work/'shots'/f'C19_51_{route}_{kind}.png').convert('RGB')
    c,d=canvas((2880,2570),'Round 6 | fixed round 4 cameras and lights | large simple coat zones')
    rows=[('battle',140,245,CROPS['battle'],'Battle r=170 | 1:1 crop'),('close',440,290,CROPS['close'],'Close zoom'),
        ('close',800,280,(600,340,1320,660),'Round 1 detail crop'),('front',1150,360,CROPS['close'],'Front'),
        ('side_reference',1570,360,CROPS['close'],'Side'),('quarter',1990,360,CROPS['close'],'Three-quarter from front below')]
    for i,route in enumerate(run.ROUTES+['reference']):
        x=i*720;d.text((x+12,70),labels[route],font=bold,fill='#eecb85')
        for kind,y,height,crop,label in rows:
            if route=='reference':
                key={'front':'front','side_reference':'side','quarter':'quarter'}.get(kind,'battle');tile=refs[key]
                if y==140:
                    box=Image.fromarray(silhouette(tile).astype('uint8')*255).getbbox();tile=tile.crop(box)
                    bounds=Image.open(work/'shots/C19_51_V3_battle_mask.png').getbbox()
                    factor=(bounds[2]-bounds[0])/tile.width
                    tile=tile.resize((round(tile.width*factor),round(tile.height*factor)),Image.Resampling.LANCZOS)
                if y==800:
                    tile=tile.crop((int(tile.width*.35),int(tile.height*.3),int(tile.width*.75),int(tile.height*.7)))
                    factor=min(704/tile.width,height/tile.height)
                    tile=tile.resize((round(tile.width*factor),round(tile.height*factor)),Image.Resampling.LANCZOS)
                paste(c,tile,(x+8,y),(704,height));caption='Art | approximate direction'
            else:paste(c,shot(route,kind),(x+8,y),(704,height),crop);caption=label
            d.text((x+12,y-29),caption,font=regular,fill='#bac5d6')
        if route!='reference':
            r=next(r for r in gpu['rows'] if r['route']==route)
            d.text((x+12,2420),f"{int(r['geometry']['triangles']):,} triangles",font=bold,fill='white')
            d.text((x+12,2460),f"20 ships GPU {r['fleet']['gpu_median_ms']:.3f} / frame {r['fleet']['frame_median_ms']:.3f} ms",font=regular,fill='white')
        else:d.text((x+12,2420),'Reference unchanged from round 4.',font=regular,fill='white')
    save(c,'comparison.webp')
    for number,indices in enumerate([[0,1,3],[0,2,3]],1):
        page,_=canvas((2160,2570),'Round 6 | readable comparison '+str(number))
        for column,index in enumerate(indices):page.paste(c.crop((index*720,60,(index+1)*720,2570)),(column*720,60))
        save(page,f'comparison_{number}.webp')
    c,d=canvas((2160,1120),'Actual game | board, HUD, ShipView and G4 lights | private prototypes')
    for i,route in enumerate(run.ROUTES):
        d.text((i*720+12,70),labels[route],font=bold,fill='#eecb85')
        for j,kind in enumerate(['battle','close']):
            tile=Image.open(work/'shots'/f'ingame_{route}_{kind}.png').convert('RGB')
            paste(c,tile,(i*720+4,150+j*460),(712,400));d.text((i*720+12,120+j*460),kind.upper(),font=regular,fill='#bac5d6')
    save(c,'ingame.webp')
    c,d=canvas((2160,1060),'Actual game | battle 1:1 crop, then close crop | r=170 / 49.92')
    for i,route in enumerate(run.ROUTES):
        d.text((i*720+12,70),labels[route],font=bold,fill='#eecb85')
        for kind,y,height in [('battle',150,245),('close',490,500)]:
            paste(c,Image.open(work/'shots'/f'ingame_{route}_{kind}.png').convert('RGB'),(i*720+8,y),(704,height),CROPS[kind])
            d.text((i*720+12,y-30),kind.upper(),font=regular,fill='#bac5d6')
    save(c,'ingame_crops.webp')
    value_structure(work,refs,canvas,paste,save,regular,bold)
    value_structure(work,refs,canvas,paste,save,regular,bold,scale=2)
    verdict_path=out/'blob_sweeps.json';verdicts=json.loads(verdict_path.read_text()) if verdict_path.exists() else {}
    for route,finish in [(r,f) for r in ['V3','V1'] for f in ['','_clay']]:
        c,d=canvas((2880,2170),labels[route]+(' | CLAY CONSTRUCTION INSPECTION' if finish else ' | PAINT')+' | nine cells')
        for j,kind in enumerate(['top','side','below_inspect']):
            tile=shot(route,kind+finish).crop(CROPS['close']);ref=refs['top' if kind=='top' else 'side']
            mask=Image.fromarray(silhouette(ref).astype('uint8')*255);ref=ref.crop(mask.getbbox())
            for k,name in enumerate(['STERN','MIDSHIP','BOW']):
                paste(c,tile.crop((k*1024//3,0,(k+1)*1024//3,530)),(k*960+4,130+j*650),(472,510))
                paste(c,ref.crop((k*ref.width//3,0,(k+1)*ref.width//3,ref.height)),(k*960+480,130+j*650),(472,510))
                d.text((k*960+12,95+j*650),name+' / '+kind.upper(),font=bold,fill='#eecb85')
                verdict=verdicts.get(route,{}).get(kind,['NOT REVIEWED']*3)[k]
                for line,text in enumerate(textwrap.wrap(verdict,88)):
                    d.text((k*960+12,650+j*650+line*26),text,font=regular,fill='#a7e1b2' if verdict.startswith('CLEAN') else '#ffb196')
        d.text((18,2050),'Each cell: model left, reference right. Bow is right in all locator views.',font=regular,fill='white')
        d.text((18,2090),'Below uses side art as a locator. No underside reference exists; construction is judged from the model.',font=regular,fill='#eecb85')
        save(c,f'nine_cells_{route}{finish}.webp')
    c,d=canvas((1920,2440),'Simple paint | actual exterior panel and bow | head-on and grazing')
    for i,route in enumerate(['V3','V1']):
        x=i*960;d.text((x+16,70),labels[route],font=bold,fill='#eecb85')
        for j,(region,angle) in enumerate([('panel','head'),('panel','grazing'),('bow','head'),('bow','grazing')]):
            y=150+j*565;d.text((x+16,y-32),region.upper()+' / '+angle.upper(),font=bold,fill='#bac5d6')
            paste(c,Image.open(work/'shots'/f'material_{route}_{region}_{angle}.png').convert('RGB'),(x+4,y),(952,535))
    save(c,'material_crops.webp')
    for name in ['reference_sheet.webp','reference_presentation.json']:
        source=run.REPO/'docs/shots/ship_pipeline/pyre_round4'/name
        shutil.copy2(source,out/name);shutil.copy2(source,review/name)
    for p in (work/'shots').glob('*.png'):shutil.copy2(p,review/p.name)
    if (work/'iterations').exists():
        for iteration in (work/'iterations').iterdir():
            dest=review/'drafts'/iteration.name;dest.mkdir(parents=True,exist_ok=True)
            for name in ['gpu.json','build_V3.json','build_V1.json']:
                if (iteration/name).exists():shutil.copy2(iteration/name,dest/name)
            for route in ['V3','V1']:
                for kind in ['battle','close']:
                    name=f'C19_51_{route}_{kind}.png'
                    if (iteration/'shots'/name).exists():shutil.copy2(iteration/'shots'/name,dest/name)
    for name in ['config.json','gpu.json','checks.json','verification.json','game_material_import.json','value_structure.json','value_structure_4k.json','colour_balance.json','colour_balance_4k.json']:
        for folder in [out,review]:shutil.copy2(work/name,folder/name)
    for folder in [out,review]:first.dump(folder/'builds.json',builds)
    models=review/'models';models.mkdir(exist_ok=True)
    for route in ['V3','V1']:shutil.copy2(work/'C19_51'/route/f'route{route}.glb',models/f'route{route}.glb')
    for key,name in json.loads((work/'reference/selection.json').read_text()).items():shutil.copy2(work/'reference'/name,review/('reference_'+key+'.png'))
    shutil.copy2(work/'parity.txt',review/'parity.txt')
    for p in [out/'README.md',verdict_path,out/'readability_review.json']:
        if p.exists():shutil.copy2(p,review/p.name)
    report=out/'README.md'
    if report.exists():
        text=report.read_text(encoding='utf-8')
        table='| Model | Triangles | 20 ships GPU ms | Frame median ms | Frame p99 ms |\n|---|---:|---:|---:|---:|\n'
        for r in gpu['rows']:
            table+=f"| {r['route']} | {int(r['geometry']['triangles']):,} | {r['fleet']['gpu_median_ms']:.3f} | {r['fleet']['frame_median_ms']:.3f} | {r['fleet']['frame_p99_ms']:.3f} |\n"
        start='<!-- performance-start -->';end='<!-- performance-end -->'
        if start in text and end in text:
            before,rest=text.split(start,1);_,after=rest.split(end,1);text=before+start+'\n'+table+end+after
        report.write_text(text,encoding='utf-8');shutil.copy2(report,review/report.name)
    print('[round6] SHEETS PASS',out,flush=True)
