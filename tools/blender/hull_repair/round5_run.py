"""Issue 163, cached V1/V2 material calibration through GPU lane A."""
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
OUT=REPO/'docs/shots/ship_pipeline/pyre_round5'
REVIEW=PC/'board/issue-163/shots'
ROUTES=['today','V1','V2']


def prepare(work,cache):
    if not (work/'config.json').exists():
        assert (cache/'base_repair/C19_51/S5/prototype.blend').exists(),'Round 4 stage 5 cache required'
        assert (cache/'reference/mesh.json').exists(),'Retained V2 mesh cache required'
        shutil.copytree(cache/'project',work/'project',dirs_exist_ok=True)
        shutil.copytree(cache/'base_repair',work/'base_repair',dirs_exist_ok=True)
        (work/'reference').mkdir(exist_ok=True)
        for path in (cache/'reference').iterdir():
            if path.is_file() and path.suffix in ['.png','.json']:shutil.copy2(path,work/'reference'/path.name)
        # Keep the completed private game imports, avoiding another audio import.
        if (cache/'game').exists():shutil.copytree(cache/'game',work/'game',dirs_exist_ok=True)
        shutil.copy2(cache/'config.json',work/'config.json')
    for name in ['round4_probe.gd','round5_probe.gd','round5_bench.gd']:shutil.copy2(HERE/name,work/'project'/name)
    cfg=json.loads((work/'config.json').read_text())
    cfg.update(work=str(work),shots=str(work/'shots'),routes=ROUTES,round=5,cache=str(cache))
    cfg['scripts']={p.name:first.sha(p) for p in HERE.glob('round[45]*') if p.is_file()}
    cfg['round5_repo_commit']=subprocess.check_output(['git','rev-parse','HEAD'],cwd=REPO,text=True).strip()
    cfg['round5_game_code_sha256']={name:first.sha(REPO/name) for name in cfg['reference_sha256']}
    cfg['round4_geometry']={r:json.loads((cache/'C19_51'/r/'build.json').read_text()) for r in ROUTES[1:]}
    cfg['cached_low_mesh_sha256']=first.sha(json.loads((work/'reference/mesh.json').read_text())['low'])
    first.dump(work/'config.json',cfg)


def capture(work):
    for route in ROUTES[1:]:
        build=json.loads((work/'C19_51'/route/'build.json').read_text())
        assert build['recipe_sha256']==first.sha(HERE/'round5_material.py'),'Rebuild changed paint before capturing'
        assert build['builder_sha256']==first.sha(HERE/'round5_build.py'),'Rebuild changed assignment before capturing'
    godot=PC/'godot/Godot_v4.7.2-stable_win64_console.exe'
    first.launch(godot,['--headless','--path',work/'project','--script','res://round5_probe.gd','--check-only'],work,'parse',60)
    first.launch(godot,['--path',work/'project','--resolution','1920x1080','--position','-2400,-1400',
        '--disable-vsync','--audio-driver','Dummy','--log-file',work/'gpu_engine.log',
        '--script','res://round5_probe.gd','--',work/'config.json'],work,'gpu',900)


def paired_bench(work):
    cfg=json.loads((work/'config.json').read_text());cache=Path(cfg['cache'])
    for route in ROUTES[1:]:
        alias=work/'C19_51'/('R4'+route);alias.mkdir(exist_ok=True)
        shutil.copy2(cache/'C19_51'/route/f'route{route}.glb',alias/f'routeR4{route}.glb')
    cfg['bench_models_sha256']={r:first.sha(work/'C19_51'/r/f'route{r}.glb') for r in ['R4V1','V1','R4V2','V2']}
    first.dump(work/'config.json',cfg)
    godot=PC/'godot/Godot_v4.7.2-stable_win64_console.exe'
    first.launch(godot,['--headless','--path',work/'project','--script','res://round5_bench.gd','--check-only'],work,'bench_parse',60)
    first.launch(godot,['--path',work/'project','--resolution','1920x1080','--position','-2400,-1400',
        '--disable-vsync','--audio-driver','Dummy','--log-file',work/'paired_gpu_engine.log',
        '--script','res://round5_bench.gd','--',work/'config.json'],work,'paired_gpu',900)


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--worker',action='store_true')
    ap.add_argument('--work',type=Path,default=Path(os.environ['TEMP'])/'voidsworn_issue163')
    ap.add_argument('--cache',type=Path,default=Path(os.environ['TEMP'])/'voidsworn_issue146')
    ap.add_argument('--phase',choices=['all','build','capture','game','bench','checks','sheets'],default='all')
    ap.add_argument('--route',choices=['V1','V2']);a=ap.parse_args()
    work=a.work.resolve();assert work.is_relative_to(Path(os.environ['TEMP']).resolve())
    work.mkdir(parents=True,exist_ok=True)
    if not a.worker:
        py=Path.home()/'Downloads/ComfyUI_windows_portable/python_embeded/python.exe'
        command='@echo off\r\ncall "'+str(REPO/'tools/pc/tmo.bat')+'" 3300 "'+str(py)+'" -s -B "'+str(__file__)+'" --worker --work "'+str(work)+'" --cache "'+str(a.cache.resolve())+'" --phase '+a.phase
        if a.route:command+=' --route '+a.route
        command+=' > "'+str(work/('driver_'+a.phase+'.log'))+'" 2>&1\r\nset "ROUND5_EXIT=%ERRORLEVEL%"\r\ncd /d "'+str(PC/'build')+'"\r\nexit /b %ROUND5_EXIT%\r\n'
        staged=work/'queued_job.bat';staged.write_bytes(command.encode('utf-8'))
        queue=PC/'queue'/('pyre163_'+str(time.time_ns())+'.bat')
        shutil.copy2(staged,queue);print('Queued:',queue,flush=True);return
    os.environ['APPDATA']=str(work/'user')
    if a.phase in ['all','build'] and (work/'gpu.json').exists():
        draft=work/'iterations'/str(time.time_ns());draft.mkdir(parents=True)
        for name in ['gpu.json','paired_gpu.json','colour_balance.json','config.json']:
            if (work/name).exists():shutil.copy2(work/name,draft/name)
        shutil.copytree(work/'shots',draft/'shots')
        for route in ROUTES[1:]:
            if (work/'C19_51'/route/'build.json').exists():shutil.copy2(work/'C19_51'/route/'build.json',draft/('build_'+route+'.json'))
    prepare(work,a.cache.resolve())
    if a.phase in ['all','build']:
        blender=PC/'blender/blender-4.5.14-windows-x64/blender.exe'
        for route in ([a.route] if a.route else ROUTES[1:]):
            first.launch(blender,['-b','--factory-startup','--python-exit-code','1','-P',HERE/'round5_build.py',
                '--','--pc',PC,'--work',work,'--route',route],work,'build_'+route,900)
    if a.phase in ['all','capture']:capture(work)
    if a.phase in ['all','game']:prior.game(work)
    if a.phase in ['all','bench']:paired_bench(work)
    if a.phase in ['all','checks']:first.launch(sys.executable,['-s','-B',HERE/'checks.py','--work',work],work,'checks',900)
    if a.phase in ['all','sheets']:
        import round5_sheets
        round5_sheets.main(work)
    print('[round5] PHASE PASS',a.phase,flush=True)


if __name__=='__main__':main()
