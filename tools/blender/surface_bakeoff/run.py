"""Stage an isolated issue 75 comparison and run it through the PC watchdog.

Double-click RUN_SURFACE_BAKEOFF.bat. It queues GPU work in lane A.
--worker is for that queued job; --sheets only recomposes retained captures.
"""
import argparse
import datetime
import hashlib
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
PC = Path.home() / 'Downloads' / 'voidsworn_test'
DEFAULT_WORK = Path(os.environ['TEMP']) / 'voidsworn_issue75'
SHIPS = {
    'C19_51': dict(name="Warlord's Pyre-Barge", faction='corsair', length=41.6),
    'D21_23': dict(name='Eclipse zenith', faction='deathless', length=23.2),
    'B16_23': dict(name='The Ninefold Maw', faction='chorus', length=44.8),
}


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def dump(path, data):
    path.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')


def launch(exe, args, work, name, seconds=900):
    # The official watchdog waits while Ryan plays and kills the entire tree.
    cmd = ['cmd.exe', '/d', '/c', str(REPO / 'tools/pc/tmo.bat'), str(seconds), str(exe), *map(str, args)]
    print('Running', name, flush=True)
    with (work / (name + '.log')).open('w', encoding='utf-8') as log:
        result = subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, cwd=REPO)
    if result.returncode:
        raise RuntimeError(f'{name} failed ({result.returncode}); see {work / (name + ".log")}')


def prepare(work):
    project = work / 'project'
    project.mkdir(parents=True, exist_ok=True)
    shutil.copy2(HERE / 'project.godot', project / 'project.godot')
    shutil.copy2(HERE / 'probe.gd', project / 'probe.gd')
    # Snapshot current packed scenes AND the texture resources they reference.
    # The current game remains untouched even if another job rebuilds it later.
    game = PC / 'build/godot'
    (project / 'gen/ships').mkdir(parents=True, exist_ok=True)
    shutil.copy2(game / 'gen/sky.res', project / 'gen/sky.res')
    today = {}
    for code in SHIPS:
        packed = game / 'gen/ships' / (code + '.scn')
        shutil.copy2(packed, project / 'gen/ships' / packed.name)
        target = project / 'assets/ships' / code
        target.mkdir(parents=True, exist_ok=True)
        maps = {}
        for src in (game / 'assets/ships' / code).iterdir():
            if src.suffix == '.jpg' or src.name.endswith('.jpg.import'):
                shutil.copy2(src, target / src.name)
                maps[src.name] = sha(src)
                if src.suffix == '.import':
                    import re
                    for rel in re.findall(r'res://[^"\s]+\.ctex', src.read_text()):
                        dst = project / rel[6:]
                        dst.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(game / rel[6:], dst)
        today[code] = dict(packed_scene=str(packed), sha256=sha(packed), bytes=packed.stat().st_size, maps=maps)
    cfg = dict(work=str(work), shots=str(work / 'shots'), ships=SHIPS, today=today,
               factions=json.loads((REPO / 'godot/fx/faction_looks.json').read_text()),
               reference_sha256={f: sha(REPO / f) for f in ['godot/render/look.gd', 'godot/render/camera_rig.gd', 'godot/render/ship_view.gd', 'godot/fx/faction_looks.json']},
               sky_sha256=sha(game / 'gen/sky.res'),
               prototype_scripts_sha256={f.name:sha(f) for f in HERE.iterdir() if f.suffix in ['.py','.gd','.godot','.bat']},
               repo_commit=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=REPO, text=True).strip(),
               created_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
    dump(work / 'config.json', cfg)


def sheets(work):
    from PIL import Image, ImageDraw, ImageFont
    out = REPO / 'docs/shots/ship_pipeline/issue75'
    out.mkdir(parents=True, exist_ok=True)
    gpu = json.loads((work / 'gpu.json').read_text())
    assert '5080' in gpu['adapter'] and len(gpu['rows']) == 7
    fonts = Path(os.environ['WINDIR']) / 'Fonts'
    title = ImageFont.truetype(str(fonts / 'segoeuib.ttf'), 32)
    label = ImageFont.truetype(str(fonts / 'segoeui.ttf'), 22)
    small = ImageFont.truetype(str(fonts / 'segoeui.ttf'), 18)
    builds = {}
    names = {'today': 'TODAY', 'B': 'B: REMESH + PBR', 'A': 'A: CLEAN KIT + TRIM'}
    for code, ship in SHIPS.items():
        routes = ['today', 'B', 'A'] if code == 'C19_51' else ['today', 'B']
        for route in routes[1:]:
            builds[code + '_' + route] = json.loads((work / code / route / 'build.json').read_text())
        # Every screenshot uses the same pixels and framing across routes.
        # Show whole frame at battle scale, full close frame, then a matched
        # central crop to expose what changes on the surface.
        w = 720
        canvas = Image.new('RGB', (w * len(routes), 1110), '#0a101b')
        draw = ImageDraw.Draw(canvas)
        draw.text((22, 12), ship['name'] + ' | surface bake-off', font=title, fill='white')
        draw.text((22, 56), 'Godot 4.7.2 / RTX 5080 / identical lights, camera direction and ship length', font=small, fill='#b1becd')
        for i, route in enumerate(routes):
            x = i*w
            row = next(r for r in gpu['rows'] if r['code'] == code and r['route'] == route)
            draw.text((x+20,92),names[route],font=label,fill='#eecb85')
            for j, kind in enumerate(['battle','close']):
                im=Image.open(work/'shots'/f'{code}_{route}_{kind}.png').convert('RGB')
                assert im.size==(1920,1080)
                im.thumbnail((w-8,400))
                y=155 if kind=='battle' else 445
                # Battle shot is deliberately not enlarged to fill its card.
                if kind=='battle':
                    im.thumbnail((w-8,245))
                else:
                    im.thumbnail((w-8,290))
                canvas.paste(im,(x+(w-im.width)//2,y))
                draw.text((x+16,y-24),'Battle camera, r=170' if kind=='battle' else 'Close zoom, same direction',font=small,fill='#b1becd')
            im=Image.open(work/'shots'/f'{code}_{route}_close.png').convert('RGB')
            im=im.crop((600,340,1320,660)).resize((w-16,280),Image.Resampling.LANCZOS)
            canvas.paste(im,(x+8,780))
            draw.text((x+16,750),'Matched detail crop',font=small,fill='#b1becd')
            text=f"{row['geometry']['triangles']:,} tris | 20 ships: {row['fleet']['gpu_median_ms']:.2f} ms GPU"
            draw.text((x+16,1080),text,font=small,fill='white')
        canvas.save(out / f'comparison_{code}.webp',quality=92)
        # Region-by-region evidence: full top/side/below views have bow, middle
        # and stern crop marks; the verdict table is recorded in README.md.
        sweep=Image.new('RGB',(640*len(routes),3*440+95),'#0a101b')
        d=ImageDraw.Draw(sweep)
        d.text((18,12),ship['name']+' | shape sweep',font=title,fill='white')
        for i,route in enumerate(routes):
            d.text((i*640+16,58),names[route],font=label,fill='#eecb85')
            for j,kind in enumerate(['top','side','below']):
                im=Image.open(work/'shots'/f'{code}_{route}_{kind}.png').convert('RGB')
                im.thumbnail((636,400))
                sweep.paste(im,(i*640+2,95+j*440))
                d.text((i*640+16,95+j*440+400),kind.upper()+' | stern left, bow right',font=small,fill='#b1becd')
        sweep.save(out/f'sweep_{code}.webp',quality=90)
    dump(out/'measurements.json',gpu)
    dump(out/'builds.json',builds)
    sources=json.loads((work/'config.json').read_text())
    sources['sheet_script_sha256']=sha(__file__)
    dump(out/'sources.json',sources)
    print('Sheets:',out)


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--worker',action='store_true')
    p.add_argument('--sheets',action='store_true')
    p.add_argument('--capture-only',action='store_true')
    p.add_argument('--work',type=Path,default=DEFAULT_WORK)
    p.add_argument('--only',help='Build just CODE:ROUTE, for an iteration')
    args=p.parse_args()
    work=args.work.resolve()
    assert work.is_relative_to(Path(os.environ['TEMP']).resolve()), 'Scratch output must stay in TEMP'
    work.mkdir(parents=True,exist_ok=True)
    if args.sheets:
        sheets(work)
        return
    assert args.worker,'Use the double-click BAT to queue the GPU job'
    blender=PC/'blender/blender-4.5.14-windows-x64/blender.exe'
    godot=PC/'godot/Godot_v4.7.2-stable_win64_console.exe'
    if not args.capture_only:
        prepare(work)
        jobs=[('C19_51','A'),('C19_51','B'),('D21_23','B'),('B16_23','B')]
        if args.only:
            jobs=[tuple(args.only.split(':'))]
        for code,route in jobs:
            launch(blender,['-b','--factory-startup','--python-exit-code','1','-P',HERE/'build.py','--','--pc',PC,'--work',work,'--code',code,'--route',route],work,code+'_'+route)
            assert (work/code/route/'build.json').exists(), 'Blender did not finish the build'
        if args.only:
            return
    launch(godot,['--headless','--path',work/'project','--script','res://probe.gd','--check-only'],work,'parse',60)
    launch(godot,['--path',work/'project','--resolution','1920x1080','--position','-2400,-1400','--disable-vsync','--audio-driver','Dummy','--log-file',work/'engine.log','--script','res://probe.gd','--',work/'config.json'],work,'gpu',600)
    launch(sys.executable,['-s',HERE/'verify.py',work],work,'verification',60)
    sheets(work)


if __name__=='__main__':
    main()
