"""Double-click RUN_SURFACE_ROUND2.bat. Isolated issue 111 GPU worker."""
import argparse
import json
import os
import shutil
import subprocess
import struct
import sys
from pathlib import Path

sys.path.insert(0,str(Path(__file__).parent))
import run as first

HERE=Path(__file__).parent.resolve()
REPO=HERE.parents[2]
PC=first.PC
ROUTES=['today','Aplus','Bake','Reuse']
LABELS={'today':'TODAY','Aplus':'1  A+ RICH SURFACE','Bake':'2  CLEAN SHELL + BAKE','Reuse':'3  CLEAN HULL + AI PARTS'}
OUT=REPO/'docs/shots/ship_pipeline/issue75b'
REVIEW=PC/'board/issue-111/shots'


def prepare(work):
    first.SHIPS={'C19_51':first.SHIPS['C19_51']}
    first.prepare(work)
    shutil.copy2(HERE/'round2_probe.gd',work/'project/round2_probe.gd')
    cfg=json.loads((work/'config.json').read_text())
    cfg['prototype_scripts_sha256']={p.name:first.sha(p) for p in HERE.iterdir() if p.suffix in ['.py','.gd','.godot','.bat']}
    first.dump(work/'config.json',cfg)


def prepare_game(work):
    game=work/'game'
    # Use this checkout's game code with the live build's generated resources.
    # All copies are private to TEMP, including Godot's import cache and user data.
    shutil.copytree(REPO/'godot',game,dirs_exist_ok=True,
                    ignore=shutil.ignore_patterns('.godot','gen','out','golden','results'))
    live=PC/'build/godot'
    shutil.copytree(live/'gen',game/'gen',dirs_exist_ok=True)
    shutil.copytree(live/'assets/ships',game/'assets/ships',dirs_exist_ok=True)
    # Preserve this private project's completed imports on capture iterations.
    # Live .scn texture references require any missing .ctex files, but replacing
    # existing cache metadata forces unrelated audio to import repeatedly.
    target=game/'.godot/imported';target.mkdir(parents=True,exist_ok=True)
    for src in (live/'.godot/imported').iterdir():
        if src.is_file() and not (target/src.name).exists():shutil.copy2(src,target/src.name)
    shutil.copy2(HERE/'round2_game.gd',game/'round2_game.gd')
    # Isolate saves/settings without changing any gameplay code.
    text=(game/'project.godot').read_text()
    text=text.replace('config/name="Embers of the Hollow Sun"','config/name="Surface111"')
    (game/'project.godot').write_text(text)
    return game


def verify(work):
    from PIL import Image, ImageChops
    cfg=json.loads((work/'config.json').read_text());gpu=json.loads((work/'gpu.json').read_text())
    assert '5080' in gpu['adapter'] and gpu['renderer']=='forward_plus'
    assert gpu['resolution']==[1920,1080] and len(gpu['rows'])==4
    builds={}
    donor=next(r for r in gpu['rows'] if r['route']=='today')['geometry']['raw_bounds']
    for route in ROUTES:
        row=next(r for r in gpu['rows'] if r['route']==route)
        for kind in ['single','fleet']:
            assert row[kind]['frames']==360 and row[kind]['warmup']==100
            assert row[kind]['gpu_median_ms']>0
        for kind in ['battle','close','top','side','below','below_inspect']:
            p=work/'shots'/f'C19_51_{route}_{kind}.png'
            assert Image.open(p).size==(1920,1080)
            if route!='today':
                a=Image.open(p).convert('RGB');b=Image.open(work/'shots'/f'C19_51_today_{kind}.png').convert('RGB')
                assert sum(ImageChops.difference(a,b).convert('L').histogram()[5:])>200
        for kind in ['battle','close']:
            assert Image.open(work/'shots'/f'ingame_{route}_{kind}.png').size==(1920,1080)
        if route=='today':continue
        bounds=row['geometry']['raw_bounds']
        for axis in [1,2]:
            assert abs((bounds[axis]/bounds[0])/(donor[axis]/donor[0])-1)<.15, 'Donor masses or exported bounds changed too much'
        folder=work/'C19_51'/route
        b=json.loads((folder/'build.json').read_text());builds[route]=b
        assert b['reimport']=='PASS' and b['triangles']==b['reimport_triangles']==row['geometry']['triangles']
        assert first.sha(folder/f'route{route}.glb')==b['sha256']
        assert first.sha(b['source'])==b['source_sha256']
        assert b['contact_count']>100 and max(c['gap'] for c in b['contact_anchors'])<.0001
        assert b['backward_guns']==0 and all(d[0]>=0 for d in b['gun_directions'])
        assert all(first.sha(work/'shared'/p)==s for p,s in b['shared_trim_sha256'].items())
    b=builds['Bake']
    assert b['normal_mean_z']>.94 and b['low_frequency_rms_after']<b['low_frequency_rms_before']*.60
    assert b['occupied_texels']>500000
    data=(work/'C19_51/Bake/routeBake.glb').read_bytes()
    length=struct.unpack_from('<I',data,12)[0]
    gltf=json.loads(data[20:20+length])
    material=next(m for m in gltf['materials'] if m['name']=='shared_trim_with_donor_cavity')
    assert material['normalTexture'].get('texCoord',0)==0
    assert material['pbrMetallicRoughness']['baseColorTexture'].get('texCoord',0)==0
    assert material['occlusionTexture'].get('texCoord',0)==0
    assert len(builds['Reuse']['reused_parts'])>=10
    assert max(p['largest_dimension'] for p in builds['Reuse']['reused_parts'])<=.063
    for angle in ['head','grazing']:
        a=Image.open(work/'shots'/f'proof_raw_{angle}.png').convert('RGB')
        b=Image.open(work/'shots'/f'proof_filtered_{angle}.png').convert('RGB')
        assert ImageChops.difference(a,b).getbbox() is not None
    for info in cfg['today'].values():
        p=Path(info['packed_scene']);assert first.sha(p)==info['sha256']
        for n,digest in info['maps'].items():assert first.sha(p.parents[2]/'assets/ships/C19_51'/n)==digest
    for log,marker in [('gpu.log','GPU PASS'),('game.log','GAME PASS')]:
        text=(work/log).read_text(errors='replace')
        assert marker in text and not any(x in text for x in ['SCRIPT ERROR','Assertion failed','Could not load'])
    result=dict(result='PASS',variants=4,exports=3,screenshots=36,source_game_unchanged=True,
                verifier_sha256=first.sha(__file__),adapter=gpu['adapter'])
    first.dump(work/'verification.json',result)
    return builds


def sheets(work):
    from PIL import Image,ImageDraw,ImageFont
    OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
    fontdir=Path(os.environ['WINDIR'])/'Fonts'
    title=ImageFont.truetype(str(fontdir/'segoeuib.ttf'),32)
    small=ImageFont.truetype(str(fontdir/'segoeui.ttf'),19)
    label=ImageFont.truetype(str(fontdir/'segoeuib.ttf'),22)
    gpu=json.loads((work/'gpu.json').read_text())
    def sheet(name,size,heading):
        canvas=Image.new('RGB',size,'#0a101b');d=ImageDraw.Draw(canvas)
        d.text((18,12),heading,font=title,fill='white')
        return canvas,d
    def save(im,name):
        im.save(OUT/name,quality=93)
        shutil.copy2(OUT/name,REVIEW/name)
    w=720
    c,d=sheet('comparison',(w*4,1135),'Pyre-Barge | round 2 surface bake-off | identical lighting and scale')
    for i,route in enumerate(ROUTES):
        x=i*w;d.text((x+14,72),LABELS[route],font=label,fill='#eecb85')
        for kind,y in [('battle',140),('close',444)]:
            im=Image.open(work/'shots'/f'C19_51_{route}_{kind}.png').convert('RGB')
            if kind=='battle':im=im.crop((608,417,1312,662))
            else:im.thumbnail((712,290))
            c.paste(im,(x+(w-im.width)//2,y))
            d.text((x+14,y-27),'Battle r=170 | 1:1 centre crop' if kind=='battle' else 'Close zoom, same direction',font=small,fill='#b1becd')
        im=Image.open(work/'shots'/f'C19_51_{route}_close.png').convert('RGB')
        im=im.crop((600,340,1320,660)).resize((704,280),Image.Resampling.LANCZOS)
        c.paste(im,(x+8,790));d.text((x+14,757),'Same detail crop as round 1',font=small,fill='#b1becd')
        row=next(r for r in gpu['rows'] if r['route']==route)
        d.text((x+14,1090),f"{row['geometry']['triangles']:,} tris | 20 ships: {row['fleet']['gpu_median_ms']:.3f} ms GPU",font=small,fill='white')
    save(c,'comparison_C19_51.webp')
    c,d=sheet('sweep',(2560,1490),'Pyre-Barge | top, side, below | bow right | fill below for inspection only')
    for i,route in enumerate(ROUTES):
        d.text((i*640+12,65),LABELS[route],font=label,fill='#eecb85')
        for j,kind in enumerate(['top','side','below_inspect']):
            im=Image.open(work/'shots'/f'C19_51_{route}_{kind}.png').convert('RGB')
            # Tight region extraction makes all nine cells inspectable.
            im=im.crop((500,275,1420,805));im.thumbnail((636,370))
            y=115+j*450;c.paste(im,(i*640+2,y))
            d.text((i*640+12,y+377),kind.replace('_',' ').upper()+' | stern / middle / bow',font=small,fill='#b1becd')
    save(c,'sweep_C19_51.webp')
    # Explicit 9-cell sheets for each prototype. Each region is the same
    # physical third of the retained matched top/side/below views.
    for route in ROUTES[1:]:
        c,d=sheet('cells',(960,1900),LABELS[route]+' | nine-cell inspection')
        for j,kind in enumerate(['top','side','below_inspect']):
            im=Image.open(work/'shots'/f'C19_51_{route}_{kind}.png').convert('RGB').crop((500,275,1420,805))
            for k,name in enumerate(['STERN','MIDDLE','BOW']):
                tile=im.crop((k*920//3,0,(k+1)*920//3,530))
                x=k*320;y=110+j*590;c.paste(tile,(x+(320-tile.width)//2,y))
                d.text((x+12,y-25),name+' / '+kind.replace('_',' ').upper(),font=small,fill='#eecb85')
        save(c,'cells_'+route+'.webp')
    c,d=sheet('proof',(1920,1260),'Same clean shell panel | donor normal bake before and after filtering')
    for i,mode in enumerate(['raw','filtered']):
        d.text((i*960+15,70),'RAW DONOR BAKE' if mode=='raw' else 'FILTERED DEVIATION + FLAT NORMAL',font=label,fill='#eecb85')
        for j,angle in enumerate(['head','grazing']):
            im=Image.open(work/'shots'/f'proof_{mode}_{angle}.png').convert('RGB');im.thumbnail((952,535))
            y=145+j*565;c.paste(im,(i*960+4,y));d.text((i*960+15,y-30),angle.upper(),font=small,fill='#b1becd')
    save(c,'wavy_panel_proof.webp')
    c,d=sheet('ingame',(2880,1010),'Actual battle scene | HUD, board, ShipView and G4 lighting | prototype assets in memory')
    for i,route in enumerate(ROUTES):
        d.text((i*720+14,65),LABELS[route],font=label,fill='#eecb85')
        for j,kind in enumerate(['battle','close']):
            im=Image.open(work/'shots'/f'ingame_{route}_{kind}.png').convert('RGB');im.thumbnail((712,400))
            y=140+j*440;c.paste(im,(i*720+4,y));d.text((i*720+14,y-28),kind.upper(),font=small,fill='#b1becd')
    save(c,'ingame_C19_51.webp')
    # Keep originals available to Opus at the exact folder the task specifies.
    for p in (work/'shots').glob('*.png'):shutil.copy2(p,REVIEW/p.name)
    builds={r:json.loads((work/'C19_51'/r/'build.json').read_text()) for r in ROUTES[1:]}
    first.dump(OUT/'builds.json',builds)
    first.dump(REVIEW/'builds.json',builds)
    for src,dst in [('gpu.json','measurements.json'),('verification.json','verification.json')]:
        shutil.copy2(work/src,OUT/dst);shutil.copy2(work/src,REVIEW/dst)
    sources=json.loads((work/'config.json').read_text())
    sources['sheet_script_sha256']=first.sha(__file__)
    first.dump(OUT/'sources.json',sources);first.dump(REVIEW/'sources.json',sources)
    shutil.copy2(work/'shared/trim_base.png',OUT/'Hullbreaker_trim.png')
    shutil.copy2(OUT/'Hullbreaker_trim.png',REVIEW/'Hullbreaker_trim.png')


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--worker',action='store_true')
    ap.add_argument('--work',type=Path,default=Path(os.environ['TEMP'])/'voidsworn_issue111')
    ap.add_argument('--only',choices=['trim','Aplus','Bake','Reuse'])
    ap.add_argument('--capture-only',action='store_true');ap.add_argument('--sheets',action='store_true')
    ap.add_argument('--game-only',action='store_true')
    a=ap.parse_args();work=a.work.resolve();assert work.is_relative_to(Path(os.environ['TEMP']).resolve())
    work.mkdir(parents=True,exist_ok=True)
    if a.sheets:verify(work);sheets(work);return
    assert a.worker,'Use RUN_SURFACE_ROUND2.bat'
    blender=PC/'blender/blender-4.5.14-windows-x64/blender.exe'
    godot=PC/'godot/Godot_v4.7.2-stable_win64_console.exe'
    if not a.game_only:
        prepare(work)
        if not a.capture_only:
            for route in ([a.only] if a.only else ['trim','Aplus','Bake','Reuse']):
                first.launch(blender,['-b','--factory-startup','--python-exit-code','1','-P',HERE/'round2_build.py',
                    '--','--pc',PC,'--work',work,'--route',route],work,route,900)
            if a.only:return
        first.launch(godot,['--headless','--path',work/'project','--log-file',work/'parse_engine.log',
            '--script','res://round2_probe.gd','--check-only'],work,'parse',60)
        first.launch(godot,['--path',work/'project','--resolution','1920x1080','--position','-2400,-1400',
            '--disable-vsync','--audio-driver','Dummy','--log-file',work/'engine.log',
            '--script','res://round2_probe.gd','--',work/'config.json'],work,'gpu',600)
    game=prepare_game(work)
    # Godot's complete user directory is redirected under TEMP for this run.
    appdata=os.environ.get('APPDATA');os.environ['APPDATA']=str(work/'user')
    try:
        first.launch(godot,['--headless','--path',game,'--log-file',work/'game_import_engine.log',
            '--editor','--import','--quit'],work,'game_import',600)
        first.launch(godot,['--path',game,'--resolution','1920x1080','--position','-2400,-1400',
            '--disable-vsync','--audio-driver','Dummy','--log-file',work/'game_engine.log',
            '--script','res://round2_game.gd','--',work/'config.json'],work,'game',600)
    finally:
        if appdata:os.environ['APPDATA']=appdata
    verify(work);sheets(work)
    print('[surface111] ALL PASS',flush=True)


if __name__=='__main__':main()
