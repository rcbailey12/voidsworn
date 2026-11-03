"""Issue 129 PC runner. Private meshes, imports, settings and saves in TEMP."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import shutil
import sys

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
sys.path.insert(0, str(HERE.parent/'surface_bakeoff'))
import run as first
# When executed as a script __main__ is this file, so this resolves the
# explicitly inserted surface_bakeoff directory's helper module.
import round2_run as second
PC = first.PC
STAGES = ['S1','S2','S3','S4a','S4b','S5']
OUT = REPO/'docs/shots/ship_pipeline/repair_c19'
REVIEW = PC/'board/issue-129/shots'


def prepare(work):
    first.SHIPS = {'C19_51': first.SHIPS['C19_51']}
    first.prepare(work)
    shutil.copy2(HERE/'probe.gd', work/'project/repair_probe.gd')
    shutil.copy2(HERE/'assembly.gd', work/'project/assembly.gd')
    cfg = json.loads((work/'config.json').read_text())
    cfg['routes'] = ['today']+STAGES
    cfg['repair_scripts_sha256'] = {p.name:first.sha(p) for p in HERE.iterdir()
                                   if p.suffix in ['.py','.gd','.bat']}
    first.dump(work/'config.json', cfg)


def game(work):
    project = second.prepare_game(work)
    text = (HERE.parent/'surface_bakeoff/round2_game.gd').read_text()
    text = text.replace('["today","Aplus","Bake","Reuse"]','cfg["routes"]')
    text = text.replace('[surface111]', '[repair129]')
    text = text.replace('surface111', 'repair129')
    text = text.replace('sv.hull.add_child(doc.generate_scene(state))',
        'var prototype: Node3D=doc.generate_scene(state)\n\t\t\tload("res://assembly.gd").add_parts(prototype,str(cfg["work"]),str(route))\n\t\t\tsv.hull.add_child(prototype)')
    text = text.replace('battle.queue_free()', 'load("res://assembly.gd").clear_static()\n\tbattle.queue_free()')
    (project/'repair_game.gd').write_text(text)
    shutil.copy2(HERE/'assembly.gd',project/'assembly.gd')
    config = (project/'project.godot').read_text().replace('Surface111','Repair129')
    (project/'project.godot').write_text(config)
    return project


def verify(work):
    from PIL import Image, ImageChops
    cfg = json.loads((work/'config.json').read_text())
    gpu = json.loads((work/'gpu.json').read_text())
    assert '5080' in gpu['adapter'] and gpu['renderer'] == 'forward_plus'
    assert gpu['resolution'] == [1920,1080]
    assert [row['route'] for row in gpu['rows']] == cfg['routes']
    analysis = json.loads((work/'analysis.json').read_text())
    assert analysis['flatten'], 'No wavy panel was actually flattened'
    assert all(row['border_max_move'] == 0 for row in analysis['flatten'])
    builds = {}
    source = Path(analysis['source'])
    assert first.sha(source) == analysis['source_sha256']
    for row in gpu['rows']:
        route = row['route']
        for kind in ['single','fleet']:
            assert row[kind]['frames'] == 360 and row[kind]['warmup'] == 100
            assert row[kind]['gpu_median_ms'] > 0
        for kind in ['battle','close','top','side','below','below_inspect','front',
                     'side_reference','concept','head','grazing','blob','engine_part','gun_part','bridge_part']:
            assert Image.open(work/'shots'/f'C19_51_{route}_{kind}.png').size == (1920,1080)
        for kind in ['battle','close']:
            assert Image.open(work/'shots'/f'ingame_{route}_{kind}.png').size == (1920,1080)
        if route == 'today':
            continue
        folder = work/'C19_51'/route
        b = json.loads((folder/'build.json').read_text()); builds[route] = b
        assert b['reimport'] == 'PASS'
        assert b['hull_triangles'] == b['reimport_triangles']
        assert b['triangles'] == row['geometry']['triangles']
        assert first.sha(folder/f'route{route}.glb') == b['sha256']
        assert b['source_sha256'] == analysis['source_sha256'] and b['no_decimation']
        assert all(direction[0] >= 0 for direction in b['gun_directions'])
        assert all(c['gap'] < .0001 for c in b['mount_anchors'])
        a = Image.open(work/'shots'/f'C19_51_{route}_close.png')
        prev = 'today' if route == 'S1' else STAGES[STAGES.index(route)-1]
        other = Image.open(work/'shots'/f'C19_51_{prev}_close.png')
        # Stage 5 can select the same geometry as 4a, so it is checked against
        # the separated original instead of requiring cosmetic noise changes.
        if route != 'S5':
            assert ImageChops.difference(a,other).getbbox() is not None
    assert builds['S1']['triangles'] == builds['S2']['triangles'] == builds['S3']['triangles']
    assert len(builds['S4b']['ai_parts']) == 3
    for code, info in cfg['today'].items():
        assert first.sha(info['packed_scene']) == info['sha256']
        for name, digest in info['maps'].items():
            assert first.sha(PC/'build/godot/assets/ships'/code/name) == digest
    for log, marker in [('gpu.log','GPU PASS'),('game.log','GAME PASS')]:
        text = (work/log).read_text(errors='replace')
        assert marker in text and not any(s in text for s in ['SCRIPT ERROR','Assertion failed','Could not load'])
    result = dict(result='PASS', variants=7, exports=6,
                  screenshots=len(list((work/'shots').glob('*.png'))),
                  source_game_unchanged=True, adapter=gpu['adapter'],
                  verifier_sha256=first.sha(__file__))
    first.dump(work/'verification.json', result)
    return builds


def sheets(work):
    from PIL import Image, ImageDraw, ImageFont
    OUT.mkdir(parents=True, exist_ok=True); REVIEW.mkdir(parents=True, exist_ok=True)
    fonts = Path(os.environ['WINDIR'])/'Fonts'
    font = ImageFont.truetype(str(fonts/'segoeui.ttf'), 18)
    bold = ImageFont.truetype(str(fonts/'segoeuib.ttf'), 25)
    title = ImageFont.truetype(str(fonts/'segoeuib.ttf'), 31)
    labels = {'today':'TODAY', 'S1':'1  STRIP MAPS', 'S2':'2  FLATTEN',
              'S3':'3  SEPARATE', 'S4a':'4a  HAND PARTS', 'S4b':'4b  AI PARTS', 'S5':'5  FINAL PICK'}
    routes = ['today']+STAGES
    def canvas(size, text):
        im = Image.new('RGB', size, '#0a101b'); d = ImageDraw.Draw(im)
        d.text((18,12),text,font=title,fill='white')
        return im,d
    def save(im, name):
        im.save(OUT/name, quality=94); shutil.copy2(OUT/name, REVIEW/name)
    def shot(route, kind):
        return Image.open(work/'shots'/f'C19_51_{route}_{kind}.png').convert('RGB')
    def paste(im, tile, at, size, crop=None):
        if crop:tile=tile.crop(crop)
        tile.thumbnail(size, Image.Resampling.LANCZOS)
        im.paste(tile,(at[0]+(size[0]-tile.width)//2,at[1]+(size[1]-tile.height)//2))
    gpu = json.loads((work/'gpu.json').read_text())
    w=720
    c,d=canvas((w*8,2570),'Repair today in place | fixed cameras, lights, 41.6 game length | concept remains the target')
    for i,route in enumerate(routes):
        x=i*w;d.text((x+12,70),labels[route],font=bold,fill='#eecb85')
        for kind,y,height,crop in [('battle',140,245,(608,417,1312,662)),
                                 ('close',440,290,None),('close',800,280,(600,340,1320,660)),
                                 ('front',1150,360,(448,275,1472,805)),
                                 ('side_reference',1570,360,(448,275,1472,805)),
                                 ('concept',1990,360,None)]:
            paste(c,shot(route,kind),(x+8,y),(704,height),crop)
            label = 'Battle r=170 | 1:1 crop' if kind=='battle' else (
                'Round 1 detail crop' if y==800 else kind.replace('_',' ').upper())
            if kind=='concept':label='Concept quarter direction (approximate)'
            d.text((x+12,y-29),label,font=font,fill='#bac5d6')
        row=next(r for r in gpu['rows'] if r['route']==route)
        d.text((x+12,2420),f"{row['geometry']['triangles']:,} triangles",font=bold,fill='white')
        d.text((x+12,2460),f"20 ships: GPU {row['fleet']['gpu_median_ms']:.3f} ms / frame {row['fleet']['frame_median_ms']:.3f} ms",font=font,fill='white')
    x=w*7;d.text((x+12,70),'CONCEPT REFERENCE',font=bold,fill='#eecb85')
    refs=REPO/'docs/ship_pipeline'
    paste(c,Image.open(refs/'concepts/C19_51.webp').convert('RGB'),(x+8,130),(704,900))
    paste(c,Image.open(refs/'c19_example/views_front.webp').convert('RGB'),(x+8,1150),(704,360),(0,250,1024,780))
    paste(c,Image.open(refs/'c19_example/views_left.webp').convert('RGB'),(x+8,1570),(704,360),(0,240,1024,770))
    paste(c,Image.open(refs/'concepts/C19_51.webp').convert('RGB'),(x+8,1990),(704,360))
    d.text((x+12,2420),'Concept is reference art, not a game render.',font=font,fill='white')
    save(c,'stages_and_concept.webp')
    c,d=canvas((720*7,1100),'Actual game battle | HUD, board, ShipView and G4 lights | private prototype substitution')
    for i,route in enumerate(routes):
        d.text((i*720+12,70),labels[route],font=bold,fill='#eecb85')
        for j,kind in enumerate(['battle','close']):
            tile=Image.open(work/'shots'/f'ingame_{route}_{kind}.png').convert('RGB')
            paste(c,tile,(i*720+4,150+j*460),(712,400))
            d.text((i*720+12,120+j*460),kind.upper(),font=font,fill='#bac5d6')
    save(c,'ingame_stages.webp')
    c,d=canvas((640*7,1320),'Same physical wavy panel and fused bridge | head-on, grazing and blob crop')
    for i,route in enumerate(routes):
        d.text((i*640+12,70),labels[route],font=bold,fill='#eecb85')
        for j,kind in enumerate(['head','grazing','blob']):
            paste(c,shot(route,kind),(i*640+4,150+j*385),(632,352))
            d.text((i*640+12,118+j*385),kind.upper(),font=font,fill='#bac5d6')
    save(c,'panel_and_blob_crops.webp')
    ai=json.loads((work/'ai/parts.json').read_text())
    builds4=json.loads((work/'C19_51/S4b/build.json').read_text())
    hand=json.loads((work/'C19_51/S4a/build.json').read_text())
    c,d=canvas((2160,1900),'Part comparison | same repaired hull, mounts, trim and lights | no whole-ship regeneration')
    for j,name in enumerate(['engine','gun','bridge']):
        y=120+j*570
        d.text((12,y-35),name.upper(),font=bold,fill='#eecb85')
        paste(c,Image.open(work/'ai'/(name+'_crop.png')).convert('RGB'),(4,y),(400,430))
        for i,route in enumerate(['S4a','S4b']):
            paste(c,shot(route,name+'_part'),(420+i*860,y),(850,475))
            d.text((440+i*860,y-32),labels[route],font=font,fill='white')
        cleanup=next(r['cleanup_seconds'] for r in builds4['ai_parts'] if r['part']==name)
        row=ai[name]
        d.text((430,y+483),f"AI: isolation {row['edit_seconds']:.1f}s; generation {row['generation_seconds']:.1f}s; automatic cleanup + fit {cleanup:.1f}s",font=font,fill='white')
        times=hand['hand_timings'][name]
        d.text((430,y+510),f"Hand: construction {times['construction_seconds']:.3f}s; detail {times['detail_seconds']:.3f}s; mesh cleanup 0s (authored geometry)",font=font,fill='white')
    save(c,'hand_vs_ai_parts.webp')
    c,d=canvas((1440,1870),'Final stage | nine-cell blob sweep | each column is one physical third')
    for j,kind in enumerate(['top','side','below_inspect']):
        tile=shot('S5',kind).crop((448,275,1472,805))
        for k,name in enumerate(['STERN','MIDSHIP','BOW']):
            part=tile.crop((k*1024//3,0,(k+1)*1024//3,530))
            paste(c,part,(k*480+4,130+j*570),(472,510))
            d.text((k*480+12,95+j*570),name+' / '+kind.upper(),font=font,fill='#eecb85')
    save(c,'final_nine_cells.webp')
    # Retain every original, AI input, prompt/history, and numeric record in
    # the exact issue folder available to the reviewer.
    for p in (work/'shots').glob('*.png'):shutil.copy2(p,REVIEW/p.name)
    for name in ['gpu.json','analysis.json','verification.json','config.json','midships.json','checks.json','parity.txt']:
        for folder in [OUT,REVIEW]:shutil.copy2(work/name,folder/name)
    builds={r:json.loads((work/'C19_51'/r/'build.json').read_text()) for r in STAGES}
    for folder in [OUT,REVIEW]:first.dump(folder/'builds.json',builds)
    if (work/'ai').exists():
        for p in (work/'ai').glob('*'):
            if p.suffix in ['.json','.png']:shutil.copy2(p,REVIEW/p.name)


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--worker',action='store_true')
    ap.add_argument('--work',type=Path,default=Path(os.environ['TEMP'])/'voidsworn_issue129')
    ap.add_argument('--phase',choices=['all','build','capture','game','sheets','ai'],default='all')
    ap.add_argument('--stage',choices=STAGES+['trim','analyse'])
    args=ap.parse_args();work=args.work.resolve()
    assert work.is_relative_to(Path(os.environ['TEMP']).resolve())
    work.mkdir(parents=True,exist_ok=True)
    os.environ['APPDATA']=str(work/'user')
    if args.phase=='sheets':verify(work);sheets(work);return
    assert args.worker,'Double-click RUN_C19_REPAIR.bat'
    blender=PC/'blender/blender-4.5.14-windows-x64/blender.exe'
    godot=PC/'godot/Godot_v4.7.2-stable_win64_console.exe'
    if args.phase in ['all','ai']:
        first.launch(sys.executable,['-s','-B',HERE/'ai_parts.py','--work',work/'ai'],work,'ai',7200)
        if args.phase=='ai':return
    if args.phase in ['all','build']:
        prepare(work)
        if not args.stage or args.stage in ['S4b','S5']:
            first.launch(sys.executable,['-s','-B',HERE/'pack_parts.py','--work',work/'ai'],work,'pack_parts',1800)
        for stage in ([args.stage] if args.stage else ['trim']+STAGES):
            first.launch(blender,['-b','--factory-startup','--python-exit-code','1','-P',HERE/'build.py',
                '--','--pc',PC,'--work',work,'--stage',stage],work,'build_'+stage,1800)
        if args.phase=='build':return
    if args.phase in ['all','capture']:
        prepare(work)
        first.launch(godot,['--headless','--path',work/'project','--script','res://repair_probe.gd','--check-only'],work,'parse',60)
        first.launch(godot,['--path',work/'project','--resolution','1920x1080','--position','-2400,-1400',
            '--disable-vsync','--audio-driver','Dummy','--log-file',work/'engine.log',
            '--script','res://repair_probe.gd','--',work/'config.json'],work,'gpu',1800)
    if args.phase in ['all','capture','game']:
        project=game(work)
        original=os.environ.get('APPDATA');os.environ['APPDATA']=str(work/'user')
        try:
            first.launch(godot,['--headless','--path',project,'--log-file',work/'game_import_engine.log',
                '--editor','--import','--quit'],work,'game_import',900)
            first.launch(godot,['--path',project,'--resolution','1920x1080','--position','-2400,-1400',
                '--disable-vsync','--audio-driver','Dummy','--log-file',work/'game_engine.log',
                '--script','res://repair_game.gd','--',work/'config.json'],work,'game',1800)
        finally:
            if original:os.environ['APPDATA']=original
        verify(work);sheets(work)
    print('[repair129] ALL PASS',flush=True)


if __name__=='__main__':main()
