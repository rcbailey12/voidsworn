"""Matched round 5 evidence, fixed colour bins and cache/source verification."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import struct
import textwrap

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

import round5_run as run
first=run.first
CROPS={'battle':(608,417,1312,662),'close':(448,275,1472,805)}
ANCHORS=np.array([[40,39,38],[106,44,34],[184,64,42],[224,64,44]],np.float32)
CLASSES=['soot_dark','rust','red_trim','lit_red']


def classify(rgb):
    classes=((rgb[:,:,None,:]-ANCHORS[None,None,:,:])**2).sum(3).argmin(2)
    # Neutral steel highlights must not become "rust" merely through value.
    r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    warm=(r>g*1.16)&(r>b*1.22)&(r-g>10)
    classes[~warm]=0
    return classes


def silhouette(im):
    rgb=np.asarray(im.convert('RGB')).astype(float)
    border=np.concatenate([rgb[:8].reshape(-1,3),rgb[-8:].reshape(-1,3),rgb[:,:8].reshape(-1,3),rgb[:,-8:].reshape(-1,3)])
    mask=np.max(abs(rgb-np.median(border,axis=0)),axis=2)>22
    labels,_=ndimage.label(mask);sizes=np.bincount(labels.ravel());sizes[0]=0
    mask=np.isin(labels,np.where(sizes>sizes.max()*.008)[0])
    return ndimage.binary_fill_holes(mask)


def reference(work):
    selection=json.loads((work/'reference/selection.json').read_text())
    refs={key:Image.open(work/'reference'/name).convert('RGB') for key,name in selection.items()}
    presentation=json.loads((run.REPO/'docs/shots/ship_pipeline/pyre_round4/reference_presentation.json').read_text())
    im=refs['battle'];bg=tuple(map(int,np.median(np.asarray(im)[:8].reshape(-1,3),axis=0)))
    refs['battle']=im.rotate(presentation['camera_roll_correction_degrees'],resample=Image.Resampling.BICUBIC,
                             expand=True,fillcolor=bg).crop(presentation['crop'])
    return refs


def colour_balance(work,refs):
    rows=[];baseline=[]
    cfg=json.loads((work/'config.json').read_text());cache=Path(cfg['cache'])
    for kind,crop in CROPS.items():
        # Present the art at the same projected width as V1, preserving aspect.
        target=Image.open(work/'shots'/f'C19_51_V1_{kind}_mask.png').convert('L')
        bounds=target.point(lambda x:255 if x>127 else 0).getbbox();assert bounds
        ref=refs['battle'];mask=Image.fromarray(silhouette(ref).astype('uint8')*255)
        box=mask.getbbox();ref=ref.crop(box);mask=mask.crop(box)
        factor=(bounds[2]-bounds[0])/ref.width
        size=(round(ref.width*factor),round(ref.height*factor))
        ref=ref.resize(size,Image.Resampling.LANCZOS);mask=mask.resize(size,Image.Resampling.NEAREST)
        at=(round((bounds[0]+bounds[2]-size[0])/2),round((bounds[1]+bounds[3]-size[1])/2))
        image=Image.new('RGB',(1920,1080));image.paste(ref,at)
        fullmask=Image.new('L',(1920,1080));fullmask.paste(mask,at)
        image.save(work/'shots'/f'reference_measure_{kind}.png')
        fullmask.save(work/'shots'/f'reference_measure_{kind}_mask.png')
        for route in ['reference','V1','V2']:
            if route=='reference':im=image;msk=fullmask
            else:
                im=Image.open(work/'shots'/f'C19_51_{route}_{kind}.png').convert('RGB')
                msk=Image.open(work/'shots'/f'C19_51_{route}_{kind}_mask.png').convert('L')
            rgb=np.asarray(im.crop(crop)).astype(np.float32)
            inside=np.asarray(msk.crop(crop))>127
            # Euclidean distance in rendered 8-bit sRGB, identical for every image.
            classes=classify(rgb)
            count=np.bincount(classes[inside],minlength=4)
            percent=count/count.sum()*100
            row=dict(route=route,crop=kind,pixels=int(count.sum()),
                share_percent={key:round(float(value),3) for key,value in zip(CLASSES,percent)})
            luma=rgb[inside]@np.array([.2126,.7152,.0722])
            row['median_srgb_luma']=round(float(np.median(luma)),3)
            row['mean_srgb_luma']=round(float(luma.mean()),3)
            emission_path=work/'shots'/f'C19_51_{route}_{kind}_emission_mask.png'
            if route!='reference' and emission_path.exists():
                emission=Image.open(emission_path).convert('L')
                emitting=(np.asarray(emission.crop(crop))>127)&inside
                row['actual_emission_area_percent']=round(float(emitting.sum()/inside.sum()*100),3)
            rows.append(row)
            labels=Image.fromarray(ANCHORS[classes].astype('uint8'))
            black=Image.new('RGB',labels.size);black.paste(labels,mask=Image.fromarray(inside.astype('uint8')*255))
            black.save(work/'shots'/f'colour_classes_{route}_{kind}.png')
        for route in ['V1','V2']:
            im=Image.open(cache/'shots'/f'C19_51_{route}_{kind}.png').convert('RGB')
            msk=Image.open(work/'shots'/f'C19_51_{route}_{kind}_mask.png').convert('L')
            rgb=np.asarray(im.crop(crop)).astype(np.float32);inside=np.asarray(msk.crop(crop))>127
            classes=classify(rgb)
            count=np.bincount(classes[inside],minlength=4);percent=count/count.sum()*100
            baseline.append(dict(route=route,crop=kind,pixels=int(count.sum()),
                share_percent={key:round(float(value),3) for key,value in zip(CLASSES,percent)}))
    for row in rows:
        ref=next(r for r in rows if r['route']=='reference' and r['crop']==row['crop'])
        row['delta_from_reference_pp']={k:round(row['share_percent'][k]-ref['share_percent'][k],3) for k in CLASSES}
        row['near_reference_10pp']=all(abs(v)<=10 for v in row['delta_from_reference_pp'].values())
        row['median_luma_delta']=round(row['median_srgb_luma']-ref['median_srgb_luma'],3)
    result=dict(method='Nearest fixed sRGB anchors on ship pixels only; warm-hue gate R>1.16G, R>1.22B, R-G>10, otherwise dark/neutral; silhouette threshold 127; no per-variant thresholds',
        classes=CLASSES,anchors_srgb=ANCHORS.astype(int).tolist(),crops=CROPS,rows=rows,
        caveat='Rendered colour bins, not semantic material IDs. Soot includes neutral steel and trophy colours. Lit red is a bright-colour proxy, not an emissive-channel area measurement. Reference art has approximate camera and baked lighting.',
        reference_resampling='Same width and centre as V1 silhouette per camera, aspect preserved; same crop rectangles',
        target='Within 10 percentage points in every colour bin, in both crops',
        round4_baseline=baseline,baseline_mask='Current silhouettes on unchanged round 4 geometry and cameras')
    first.dump(work/'colour_balance.json',result)
    return result


def geometry_digest(path):
    # UV splits, material slots and vertex order cannot change this fingerprint.
    data=path.read_bytes();size=struct.unpack_from('<I',data,12)[0]
    doc=json.loads(data[20:20+size]);binary=28+size
    def accessor(index):
        a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
        dtype={5126:'<f4',5125:'<u4',5123:'<u2'}[a['componentType']]
        width={'VEC3':3,'SCALAR':1}[a['type']]
        assert v.get('byteStride',np.dtype(dtype).itemsize*width)==np.dtype(dtype).itemsize*width
        return np.frombuffer(data,dtype=dtype,count=a['count']*width,
            offset=binary+v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(-1,width)
    parts=[]
    for mesh in doc['meshes']:
        for primitive in mesh['primitives']:
            vertices=accessor(primitive['attributes']['POSITION'])
            faces=accessor(primitive['indices']).reshape(-1,3)
            parts.append(np.rint(vertices[faces]*1e7).astype('<i4'))
    triangles=np.concatenate(parts)
    points=triangles.view(np.dtype((np.void,12))).reshape(-1,3)
    points.sort(axis=1)
    records=points.copy().view(np.dtype((np.void,36))).ravel()
    records.sort()
    return hashlib.sha256(records.tobytes()).hexdigest()


def verify(work):
    cfg=json.loads((work/'config.json').read_text());gpu=json.loads((work/'gpu.json').read_text())
    assert '5080' in gpu['adapter'] and gpu['renderer']=='forward_plus'
    assert gpu['resolution']==[1920,1080] and [r['route'] for r in gpu['rows']]==run.ROUTES
    assert cfg['scripts']['round5_probe.gd']==first.sha(run.HERE/'round5_probe.gd')
    assert gpu['active_probe_sha256']==first.sha(run.HERE/'round5_probe.gd')
    assert gpu['capture_probe_sha256']==first.sha(run.HERE/'round4_probe.gd')
    builds={};geometry={};ceiling={}
    for row in gpu['rows']:
        route=row['route']
        assert row['geometry']['world_length']==41.6
        for kind in ['single','fleet']:
            assert row[kind]['frames']==360 and row[kind]['warmup']==100 and row[kind]['gpu_median_ms']>0
        for kind in ['battle','close','top','side','below','below_inspect','front','side_reference','quarter','top_reference']:
            assert Image.open(work/'shots'/f'C19_51_{route}_{kind}.png').size==(1920,1080)
        for kind in ['battle','close']:
            assert Image.open(work/'shots'/f'ingame_{route}_{kind}.png').size==(1920,1080)
            assert Image.open(work/'shots'/f'C19_51_{route}_{kind}_mask.png').size==(1920,1080)
        if route=='today':continue
        for kind in ['battle','close']:
            assert Image.open(work/'shots'/f'C19_51_{route}_{kind}_emission_mask.png').size==(1920,1080)
        folder=work/'C19_51'/route;build=json.loads((folder/'build.json').read_text());builds[route]=build
        assert build['reimport']=='PASS' and build['triangles']==build['reimport_triangles']==row['geometry']['triangles']
        assert first.sha(folder/f'route{route}.glb')==build['sha256']
        assert first.sha(build['source'])==build['source_sha256']
        assert build['recipe_sha256']==first.sha(run.HERE/'round5_material.py')
        assert build['builder_sha256']==first.sha(run.HERE/'round5_build.py')
        assert not build['projected_paint'] and not build['geometry_regenerated']
        if route=='V1':
            assert all(d[0]>=0 for d in build['gun_directions'])
            assert max(anchor['gap'] for anchor in build['mount_anchors'])<.0001
        cache=Path(cfg['cache'])/'C19_51'/route/f'route{route}.glb'
        old=geometry_digest(cache);new=geometry_digest(folder/f'route{route}.glb')
        geometry[route]=dict(round4=old,round5=new,unchanged=old==new)
        assert old==new,'Geometry changed during a paint-only task: '+route
        assert build['triangles']==cfg['round4_geometry'][route]['triangles']
        for region in ['panel','bow']:
            for angle in ['head','grazing']:assert Image.open(work/'shots'/f'material_{route}_{region}_{angle}.png').size==(1920,1080)
        ceiling[route]=dict(triangles=build['triangles'],nominal_triangle_ceiling=306000,
            triangle_delta=build['triangles']-306000,unchanged_from_round4_count=True,
            gpu_ms=row['fleet']['gpu_median_ms'],gpu_ceiling_ms=3.9,
            gpu_within_ceiling=row['fleet']['gpu_median_ms']<=3.9)
    record=json.loads((work/'reference/mesh.json').read_text())
    assert first.sha(record['low'])==cfg['cached_low_mesh_sha256']
    selection=json.loads((work/'reference/selection.json').read_text())
    cached=Path(cfg['cache'])/'reference'
    assert selection==json.loads((cached/'selection.json').read_text())
    for filename in selection.values():assert first.sha(work/'reference'/filename)==first.sha(cached/filename)
    paired=json.loads((work/'paired_gpu.json').read_text())
    assert paired['probe_sha256']==first.sha(run.HERE/'round5_bench.gd')
    assert '5080' in paired['adapter'] and paired['resolution']==[1920,1080]
    for route in ['R4V1','V1','R4V2','V2']:
        assert first.sha(work/'C19_51'/route/f'route{route}.glb')==paired['models_sha256'][route]
        rows=[r for r in paired['rows'] if r['route']==route];assert len(rows)==3
        for row in rows:assert row['fleet']['frames']==360 and row['fleet']['warmup']==100
    for name,digest in cfg['round5_game_code_sha256'].items():assert first.sha(run.REPO/name)==digest
    for info in cfg['today'].values():
        assert first.sha(info['packed_scene'])==info['sha256']
        for name,digest in info['maps'].items():assert first.sha(PC/'build/godot/assets/ships/C19_51'/name)==digest
    for name,marker in [('gpu.log','GPU PASS'),('game.log','GAME PASS')]:
        log=(work/name).read_text(errors='replace');assert marker in log and 'SCRIPT ERROR' not in log
    assert json.loads((work/'checks.json').read_text())['result']=='PASS'
    result=dict(result='PASS',routes=run.ROUTES,source_game_unchanged=True,geometry=geometry,
                ceiling=ceiling,verifier_sha256=first.sha(__file__))
    first.dump(work/'verification.json',result)
    return builds


PC=run.PC


def main(work):
    cfg=json.loads((work/'config.json').read_text())
    cfg['scripts']['round5_sheets.py']=first.sha(__file__)
    first.dump(work/'config.json',cfg)
    builds=verify(work);refs=reference(work);balance=colour_balance(work,refs)
    if (work/'iterations').exists():
        for draft in (work/'iterations').iterdir():
            if (draft/'shots/C19_51_V2_close_mask.png').exists():colour_balance(draft,refs)
    verification=json.loads((work/'verification.json').read_text())
    verification['colour_match_pass']=all(row['near_reference_10pp'] for row in balance['rows'])
    verification['brightness_within_15_levels']=all(abs(row['median_luma_delta'])<=15 for row in balance['rows'])
    first.dump(work/'verification.json',verification)
    out=run.OUT;review=run.REVIEW
    out.mkdir(parents=True,exist_ok=True);review.mkdir(parents=True,exist_ok=True)
    fonts=Path(os.environ['WINDIR'])/'Fonts'
    regular=ImageFont.truetype(str(fonts/'segoeui.ttf'),18)
    bold=ImageFont.truetype(str(fonts/'segoeuib.ttf'),25)
    title=ImageFont.truetype(str(fonts/'segoeuib.ttf'),31)
    labels={'today':'TODAY','V1':'V1  REPAIR + ROUND 5 PAINT','V2':'V2  CACHED MESH + ROUND 5 PAINT','reference':'ROUND 4 REFERENCE'}
    gpu=json.loads((work/'gpu.json').read_text())
    verdict_path=out/'blob_sweeps.json'
    verdicts=json.loads(verdict_path.read_text()) if verdict_path.exists() else {}
    def canvas(size,label):
        im=Image.new('RGB',size,'#0a101b');d=ImageDraw.Draw(im);d.text((18,12),label,font=title,fill='white');return im,d
    def save(im,name):
        im.save(out/name,quality=94);shutil.copy2(out/name,review/name)
    def paste(im,tile,at,size,crop=None):
        tile=tile.crop(crop) if crop else tile.copy();tile.thumbnail(size,Image.Resampling.LANCZOS)
        im.paste(tile,(at[0]+(size[0]-tile.width)//2,at[1]+(size[1]-tile.height)//2))
    def shot(route,kind):return Image.open(work/'shots'/f'C19_51_{route}_{kind}.png').convert('RGB')
    c,d=canvas((2880,2570),'Round 5 | same cameras, lights and geometry | soot, rust break-up, limited red trim')
    rows=[('battle',140,245,CROPS['battle'],'Battle r=170 | 1:1 crop'),
        ('close',440,290,CROPS['close'],'Close zoom'),('close',800,280,(600,340,1320,660),'Round 1 detail crop'),
        ('front',1150,360,CROPS['close'],'Front'),('side_reference',1570,360,CROPS['close'],'Side'),
        ('quarter',1990,360,CROPS['close'],'Three-quarter from front below')]
    for i,route in enumerate(run.ROUTES+['reference']):
        x=i*720;d.text((x+12,70),labels[route],font=bold,fill='#eecb85')
        for kind,y,height,crop,label in rows:
            if route=='reference':
                key={'front':'front','side_reference':'side','quarter':'quarter'}.get(kind,'battle');tile=refs[key]
                if y==800:
                    tile=tile.crop((int(tile.width*.35),int(tile.height*.3),int(tile.width*.75),int(tile.height*.7)))
                    zoom=min(704/tile.width,height/tile.height)
                    tile=tile.resize((round(tile.width*zoom),round(tile.height*zoom)),Image.Resampling.LANCZOS)
                paste(c,tile,(x+8,y),(704,height));caption='Art | approximate direction'
            else:paste(c,shot(route,kind),(x+8,y),(704,height),crop);caption=label
            d.text((x+12,y-29),caption,font=regular,fill='#bac5d6')
        if route!='reference':
            r=next(r for r in gpu['rows'] if r['route']==route)
            d.text((x+12,2420),f"{int(r['geometry']['triangles']):,} triangles",font=bold,fill='white')
            d.text((x+12,2460),f"20 ships GPU {r['fleet']['gpu_median_ms']:.3f} / frame {r['fleet']['frame_median_ms']:.3f} ms",font=regular,fill='white')
        else:d.text((x+12,2420),'Same reference as round 4; V3 parked.',font=regular,fill='white')
    save(c,'comparison.webp')
    for number,indices in enumerate([[0,1,3],[1,2,3]],1):
        page,_=canvas((2160,2570),'Round 5 | readable comparison '+str(number))
        for column,index in enumerate(indices):page.paste(c.crop((index*720,60,(index+1)*720,2570)),(column*720,60))
        save(page,f'comparison_{number}.webp')
    c,d=canvas((2880,1120),'Actual game | board, HUD, ShipView and G4 lighting | round 5 private prototypes')
    for i,route in enumerate(run.ROUTES+['reference']):
        d.text((i*720+12,70),labels[route],font=bold,fill='#eecb85')
        for j,kind in enumerate(['battle','close']):
            tile=refs['battle' if j==0 else 'top'] if route=='reference' else Image.open(work/'shots'/f'ingame_{route}_{kind}.png').convert('RGB')
            paste(c,tile,(i*720+4,150+j*460),(712,400))
            d.text((i*720+12,120+j*460),kind.upper() if route!='reference' else 'ART | approximate direction',font=regular,fill='#bac5d6')
    save(c,'ingame.webp')
    c,d=canvas((2160,1060),'Actual game | same battle pixels at 1:1, same close crop | r=170 / 49.92')
    for i,route in enumerate(run.ROUTES):
        d.text((i*720+12,70),labels[route],font=bold,fill='#eecb85')
        for kind,y,height in [('battle',150,245),('close',490,500)]:
            paste(c,Image.open(work/'shots'/f'ingame_{route}_{kind}.png').convert('RGB'),(i*720+8,y),(704,height),CROPS[kind])
            d.text((i*720+12,y-30),kind.upper(),font=regular,fill='#bac5d6')
    save(c,'ingame_crops.webp')
    c,d=canvas((1920,2440),'Round 5 materials | actual exterior panel and bow | head-on and grazing')
    for i,route in enumerate(['V1','V2']):
        x=i*960;d.text((x+16,70),labels[route],font=bold,fill='#eecb85')
        for j,(region,angle) in enumerate([('panel','head'),('panel','grazing'),('bow','head'),('bow','grazing')]):
            y=150+j*565;d.text((x+16,y-32),region.upper()+' / '+angle.upper(),font=bold,fill='#bac5d6')
            paste(c,Image.open(work/'shots'/f'material_{route}_{region}_{angle}.png').convert('RGB'),(x+4,y),(952,535))
    save(c,'material_crops.webp')
    c,d=canvas((2880,1940),'Material change | round 4 versus round 5 | same geometry, lights and surface stations')
    cache=Path(cfg['cache'])
    for i,(route,version) in enumerate([('V1',4),('V1',5),('V2',4),('V2',5)]):
        x=i*720;d.text((x+16,70),route+' / ROUND '+str(version),font=bold,fill='#eecb85')
        for j,(region,angle) in enumerate([('panel','head'),('panel','grazing'),('bow','head'),('bow','grazing')]):
            y=150+j*440;d.text((x+16,y-32),region.upper()+' / '+angle.upper(),font=bold,fill='#bac5d6')
            source=cache if version==4 else work
            paste(c,Image.open(source/'shots'/f'material_{route}_{region}_{angle}.png').convert('RGB'),(x+4,y),(712,400))
    save(c,'material_change.webp')
    for route in ['V1','V2']:
        c,d=canvas((2880,2170),labels[route]+' | nine cells against the unchanged round 4 reference')
        for j,kind in enumerate(['top','side','below_inspect']):
            tile=shot(route,kind).crop(CROPS['close']);ref=refs['top' if kind=='top' else 'side']
            mask=Image.fromarray(silhouette(ref).astype('uint8')*255);ref=ref.crop(mask.getbbox())
            for k,name in enumerate(['STERN','MIDSHIP','BOW']):
                paste(c,tile.crop((k*1024//3,0,(k+1)*1024//3,530)),(k*960+4,130+j*650),(472,510))
                paste(c,ref.crop((k*ref.width//3,0,(k+1)*ref.width//3,ref.height)),(k*960+480,130+j*650),(472,510))
                d.text((k*960+12,95+j*650),name+' / '+kind.upper(),font=bold,fill='#eecb85')
                verdict=verdicts.get(route,{}).get(kind,['NOT REVIEWED']*3)[k]
                for line,text in enumerate(textwrap.wrap(verdict,88)):d.text((k*960+12,650+j*650+line*26),text,font=regular,fill='#ffb196')
        d.text((18,2050),'Each cell: model left, reference right. Same geometry as round 4; fresh paint and captures.',font=regular,fill='white')
        d.text((18,2090),'Below uses side art as a locator. Hidden reference correspondence is not proven.',font=regular,fill='#eecb85')
        save(c,f'nine_cells_{route}.webp')
    c,d=canvas((1800,990),'Rendered colour balance | fixed sRGB anchors | ship pixels only')
    colours=['#282726','#6a2c22','#b8402a','#e0402c']
    for i,row in enumerate(balance['rows']):
        y=120+i*125;d.text((20,y),row['crop'].upper()+' / '+row['route'].upper(),font=bold,fill='white')
        d.text((20,y+42),f"Median luma {row['median_srgb_luma']:.1f} / 255",font=regular,fill='#bac5d6')
        x=440
        for key,colour in zip(CLASSES,colours):
            width=row['share_percent'][key]*12;d.rectangle((x,y,x+width,y+35),fill=colour);x+=width
        d.text((440,y+45),' | '.join(k+f" {row['share_percent'][k]:.1f}%" for k in CLASSES),font=regular,fill='white')
    d.text((20,910),'Colour bins estimate visible balance; lit_red is not a physical emission area measurement.',font=regular,fill='#bac5d6')
    d.text((20,945),'Reference art has its own painted lighting and approximate camera. See colour_balance.json.',font=regular,fill='#bac5d6')
    save(c,'colour_balance.webp')
    for name in ['reference_sheet.webp','reference_presentation.json']:
        source=run.REPO/'docs/shots/ship_pipeline/pyre_round4'/name
        shutil.copy2(source,out/name);shutil.copy2(source,review/name)
    art={}
    for kind,filename in json.loads((work/'reference/selection.json').read_text()).items():
        source=work/'reference'/filename
        shutil.copy2(source,review/('reference_'+kind+'.png'))
        art[kind]=dict(source_name=filename,sha256=first.sha(source),review_image='reference_'+kind+'.png')
    for folder in [out,review]:first.dump(folder/'reference_art.json',art)
    for p in (work/'shots').glob('*.png'):shutil.copy2(p,review/p.name)
    for name in ['config.json','gpu.json','checks.json','verification.json','colour_balance.json']:
        for folder in [out,review]:shutil.copy2(work/name,folder/name)
    if (work/'paired_gpu.json').exists():
        for folder in [out,review]:shutil.copy2(work/'paired_gpu.json',folder/'paired_gpu.json')
    for folder in [out,review]:first.dump(folder/'builds.json',builds)
    models=review/'models';models.mkdir(exist_ok=True)
    for route in ['V1','V2']:shutil.copy2(work/'C19_51'/route/f'route{route}.glb',models/f'route{route}.glb')
    shutil.copy2(work/'parity.txt',review/'parity.txt')
    if (work/'iterations').exists():
        drafts=review/'drafts';drafts.mkdir(exist_ok=True)
        for draft in (work/'iterations').iterdir():
            dst=drafts/draft.name;dst.mkdir(exist_ok=True)
            for name in ['gpu.json','paired_gpu.json','colour_balance.json','build_V1.json','build_V2.json']:
                if (draft/name).exists():shutil.copy2(draft/name,dst/name)
            for name in ['C19_51_V1_close.png','C19_51_V2_close.png','material_V1_panel_head.png']:
                if (draft/'shots'/name).exists():shutil.copy2(draft/'shots'/name,dst/name)
    for p in [out/'README.md',verdict_path]:
        if p.exists():shutil.copy2(p,review/p.name)
    report=out/'README.md'
    if report.exists():
        text=report.read_text(encoding='utf-8')
        perf='| Model | Triangles | 20 ships GPU ms | Frame median ms | Frame p99 ms |\n|---|---:|---:|---:|---:|\n'
        for r in gpu['rows']:
            perf+=f"| {r['route']} | {int(r['geometry']['triangles']):,} | {r['fleet']['gpu_median_ms']:.3f} | {r['fleet']['frame_median_ms']:.3f} | {r['fleet']['frame_p99_ms']:.3f} |\n"
        colour='| Crop | Model | Dark/neutral % | Rust % | Red trim % | Bright red % | Emitting area % | Median luma /255 |\n|---|---|---:|---:|---:|---:|---:|---:|\n'
        for r in balance['rows']:
            colour+=f"| {r['crop']} | {r['route']} | "+' | '.join(f"{r['share_percent'][k]:.2f}" for k in CLASSES)+f" | {r.get('actual_emission_area_percent','n/a')} | {r['median_srgb_luma']:.2f} |\n"
        gap=max(abs(v) for row in balance['rows'] for v in row['delta_from_reference_pp'].values())
        colour+=f"\nLargest colour gap: {gap:.2f} percentage points. All bins within 10 points: {verification['colour_match_pass']}. Median brightness within 15 levels: {verification['brightness_within_15_levels']}.\n"
        paired=''
        if (work/'paired_gpu.json').exists():
            pairs=json.loads((work/'paired_gpu.json').read_text())
            paired='| Material on unchanged mesh | GPU median of 3 runs, ms | GPU range, ms | Frame median of 3, ms |\n|---|---:|---:|---:|\n'
            for route in ['R4V1','V1','R4V2','V2']:
                rows=[r['fleet'] for r in pairs['rows'] if r['route']==route]
                values=[r['gpu_median_ms'] for r in rows]
                paired+=f"| {route} | {np.median(values):.3f} | {min(values):.3f} to {max(values):.3f} | {np.median([r['frame_median_ms'] for r in rows]):.3f} |\n"
        for label,value in [('performance',perf),('colour',colour),('paired',paired)]:
            start=f'<!-- {label}-start -->';end=f'<!-- {label}-end -->'
            if start in text and end in text:
                before,rest=text.split(start,1);_,after=rest.split(end,1);text=before+start+'\n'+value+end+after
        report.write_text(text,encoding='utf-8');shutil.copy2(report,review/report.name)
    print('[round5] SHEETS PASS',out,flush=True)
