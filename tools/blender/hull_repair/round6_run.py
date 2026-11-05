"""Issue 187: cached simple-paint comparison through PC GPU lane A."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

sys.dont_write_bytecode=True
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
import round4_run as prior
first=prior.first
PC=prior.PC
REPO=prior.REPO
OUT=REPO/'docs/shots/ship_pipeline/pyre_round6'
REVIEW=PC/'board/issue-187/shots'
ROUTES=['today','V3','V1']


def prepare(work,cache):
    if not (work/'config.json').exists():
        assert (cache/'base_repair/C19_51/S5/prototype.blend').exists(),'Retained round 4 stage 5 cache required'
        shutil.copytree(cache/'project',work/'project',dirs_exist_ok=True)
        shutil.copytree(cache/'base_repair',work/'base_repair',dirs_exist_ok=True)
        shutil.copytree(cache/'reference',work/'reference',dirs_exist_ok=True)
        if (cache/'game').exists():shutil.copytree(cache/'game',work/'game',dirs_exist_ok=True)
        shutil.copy2(cache/'config.json',work/'config.json')
    for name in ['round4_probe.gd','round6_probe.gd']:shutil.copy2(HERE/name,work/'project'/name)
    cfg=json.loads((work/'config.json').read_text())
    cfg.update(work=str(work),shots=str(work/'shots'),routes=ROUTES,round=6,cache=str(cache))
    cfg['scripts']={p.name:first.sha(p) for pattern in ['round4*','round6*'] for p in HERE.glob(pattern) if p.is_file()}
    cfg['round6_repo_commit']=subprocess.check_output(['git','rev-parse','HEAD'],cwd=REPO,text=True).strip()
    cfg['round6_game_code_sha256']={name:first.sha(REPO/name) for name in cfg['reference_sha256']}
    cfg['round4_geometry']={r:json.loads((cache/'C19_51'/r/'build.json').read_text()) for r in ROUTES[1:]}
    specs=[json.loads((work/'C19_51'/r/'build.json').read_text())['material'].get('coat_specular_ior_level',.5)
           for r in ROUTES[1:] if (work/'C19_51'/r/'build.json').exists()]
    if specs:
        assert len(set(specs))==1,'Both prototypes must use the same coat specular'
        cfg['coat_specular_ior_level']=specs[0]
    first.dump(work/'config.json',cfg)


def capture(work):
    for route in ROUTES[1:]:
        record=json.loads((work/'C19_51'/route/'build.json').read_text())
        assert record['recipe_sha256']==first.sha(HERE/'round6_material.py'),'Rebuild changed paint'
        assert record['builder_sha256']==first.sha(HERE/'round6_build.py'),'Rebuild changed geometry/assignment'
    godot=PC/'godot/Godot_v4.7.2-stable_win64_console.exe'
    first.launch(godot,['--headless','--path',work/'project','--script','res://round6_probe.gd','--check-only'],work,'parse',60)
    first.launch(godot,['--path',work/'project','--resolution','1920x1080','--position','-2400,-1400',
        '--disable-vsync','--audio-driver','Dummy','--log-file',work/'gpu_engine.log',
        '--script','res://round6_probe.gd','--',work/'config.json'],work,'gpu',900)


def game(work):
    cfg=json.loads((work/'config.json').read_text())
    specs=[json.loads((work/'C19_51'/r/'build.json').read_text())['material']['coat_specular_ior_level'] for r in ROUTES[1:]]
    assert len(set(specs))==1
    cfg['coat_specular_ior_level']=specs[0]
    project=prior.second.prepare_game(work)
    text=(HERE.parent/'surface_bakeoff/round2_game.gd').read_text()
    text=text.replace('["today","Aplus","Bake","Reuse"]','cfg["routes"]')
    text=text.replace('surface111','round6187').replace('else 62.0','else 49.92')
    (project/'round6_base_game.gd').write_text(text)
    shutil.copy2(HERE/'round6_game.gd',project/'round6_game.gd')
    cfg['game_probe_sha256']=first.sha(HERE/'round6_game.gd')
    cfg['game_base_sha256']=first.sha(project/'round6_base_game.gd')
    first.dump(work/'config.json',cfg)
    config=(project/'project.godot').read_text().replace('Surface111','Pyre187')
    (project/'project.godot').write_text(config)
    godot=PC/'godot/Godot_v4.7.2-stable_win64_console.exe'
    first.launch(godot,['--headless','--path',project,'--log-file',work/'game_import_engine.log',
        '--editor','--import','--quit'],work,'game_import',900)
    first.launch(godot,['--path',project,'--resolution','1920x1080','--position','-2400,-1400',
        '--disable-vsync','--audio-driver','Dummy','--log-file',work/'game_engine.log',
        '--script','res://round6_game.gd','--',work/'config.json'],work,'game',900)


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--worker',action='store_true')
    ap.add_argument('--work',type=Path,default=Path(os.environ['TEMP'])/'voidsworn_issue187')
    ap.add_argument('--cache',type=Path,default=Path(os.environ['TEMP'])/'voidsworn_issue146')
    ap.add_argument('--phase',choices=['all','build','capture','game','checks','sheets'],default='all')
    ap.add_argument('--route',choices=['V1','V3']);a=ap.parse_args()
    work=a.work.resolve();assert work.is_relative_to(Path(os.environ['TEMP']).resolve())
    work.mkdir(parents=True,exist_ok=True)
    if not a.worker:
        py=Path.home()/'Downloads/ComfyUI_windows_portable/python_embeded/python.exe'
        command='@echo off\r\ncall "'+str(REPO/'tools/pc/tmo.bat')+'" 3300 "'+str(py)+'" -s -B "'+str(__file__)+'" --worker --work "'+str(work)+'" --cache "'+str(a.cache.resolve())+'" --phase '+a.phase
        if a.route:command+=' --route '+a.route
        command+=' > "'+str(work/('driver_'+a.phase+'.log'))+'" 2>&1\r\nset "ROUND6_EXIT=%ERRORLEVEL%"\r\ncd /d "'+str(PC/'build')+'"\r\nexit /b %ROUND6_EXIT%\r\n'
        staged=work/'queued_job.bat';staged.write_bytes(command.encode('utf-8'))
        queue=PC/'queue'/('pyre187_'+str(time.time_ns())+'.bat')
        shutil.copy2(staged,queue);assert queue.read_bytes()==staged.read_bytes()
        print('Queued:',queue,flush=True);return
    os.environ['APPDATA']=str(work/'user')
    prepare(work,a.cache.resolve())
    if a.phase in ['all','build']:
        if (work/'gpu.json').exists():
            archive=work/'iterations'/str(time.time_ns());archive.mkdir(parents=True)
            shutil.copy2(work/'gpu.json',archive/'gpu.json');shutil.copytree(work/'shots',archive/'shots')
            for route in ROUTES[1:]:shutil.copy2(work/'C19_51'/route/'build.json',archive/('build_'+route+'.json'))
        blender=PC/'blender/blender-4.5.14-windows-x64/blender.exe'
        for route in ([a.route] if a.route else ROUTES[1:]):
            first.launch(blender,['-b','--factory-startup','--python-exit-code','1','-P',HERE/'round6_build.py',
                '--','--pc',PC,'--work',work,'--route',route],work,'build_'+route,900)
    if a.phase in ['all','capture']:capture(work)
    if a.phase in ['all','game']:game(work)
    if a.phase in ['all','checks']:first.launch(sys.executable,['-s','-B',HERE/'checks.py','--work',work],work,'checks',900)
    if a.phase in ['all','sheets']:
        import round6_sheets
        round6_sheets.main(work)
    print('[round6] PHASE PASS',a.phase,flush=True)


if __name__=='__main__':main()
