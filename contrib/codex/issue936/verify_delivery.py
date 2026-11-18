"""Read back installed assets, manifests, painted geometry and labelled proofs."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from PIL import Image

REPO=Path(__file__).resolve().parents[3]
PC=REPO.parents[1]
PROOF=PC/'board_b/issue-936/shots'
DEST=REPO/'docs/shots/look_bench/hullbreaker_rust_936'
sys.path.insert(0,str(REPO/'tools'))
from picture_provenance import verify


def main():
    geometry_report=DEST/'approved_geometry.json'
    env=dict(os.environ,PC_GPU_ISSUE='936',PC_GPU_LANE='B',TMO_REPO='',TMO_OUT='',TMO_LOG='',TMO_ERR_LOG='')
    log=Path(tempfile.gettempdir())/'voidsworn936_approved_geometry.log'
    with log.open('w') as stream:
        subprocess.run([str(REPO/'tools/pc/tmo.bat'),'900',
                        str(PC/'blender/blender-4.5.14-windows-x64/blender.exe'),
                        '-b','--python-exit-code','1','-P',str(Path(__file__).with_name('check_geometry.py')),
                        '--',str(geometry_report)],cwd=REPO,env=env,stdout=stream,stderr=subprocess.STDOUT,check=True)
    approved=json.loads(geometry_report.read_text())
    shutil.copy2(geometry_report,PROOF/geometry_report.name)
    changes=subprocess.check_output(['git','diff','--name-only','HEAD','--','tools/blender/build_sheets','tools/blender/kits'],cwd=REPO,text=True).splitlines()
    geometry_edits=[p for p in changes if p not in ('tools/blender/kits/hullbreakers/stack.py','tools/blender/kits/shared/paint_stack.py')]
    assert not geometry_edits,geometry_edits
    rows={}
    for cell in ('A16','A17','A18','A19','A20'):
        config=json.loads((REPO/f'tools/recipe/ships/corsair_{cell}.json').read_text())
        code=config['game_code']; out=PROOF/cell
        before=json.loads((out/'before/painted_mesh_measure.json').read_text())
        after=json.loads((out/'after/painted_mesh_measure.json').read_text())
        same_before=before['geometry_sha256']==after['geometry_sha256']
        assert approved[cell]['ok'],(cell,'painted geometry differs from approved sheet')
        if not same_before:
            assert cell=='A18',(cell,'unexplained installed geometry drift')
        assert after['engines_share_seed'], (cell,'engine seeds differ')
        export=json.loads((out/f'{code}_export.json').read_text())
        assert len(after['engine_seeds'])==export['hardpoints']['engine'], (cell,'glowing engine count')
        assert json.loads((out/f'{code}_check.json').read_text())['ok'], (cell,'export check')
        assert json.loads((out/'surface_check.json').read_text())['ok'], (cell,'surface check')
        installed={}
        expected=json.loads((out/'manifest_entry.json').read_text())
        for game in (REPO/'godot',PC/'build/godot'):
            manifest=json.loads((game/'assets/ships/manifest.json').read_text())
            entries=manifest.get('ships',manifest)
            entry=entries[code]
            assert entry['files']==expected['files'], (cell,'installed files differ from checked export',str(game))
            checked=[]
            for filename,record in entry['files'].items():
                file=game/'assets/ships'/code/filename
                assert file.stat().st_size==record['bytes'], (file,'size')
                digest=hashlib.sha256(file.read_bytes()).hexdigest()
                assert digest==record['sha256'], (file,'manifest hash')
                checked.append(dict(file=filename,bytes=record['bytes'],sha256=digest))
            installed['repo_game' if game==REPO/'godot' else 'playable_game']=checked
        rows[cell]=dict(matches_approved_geometry=True,before_install_geometry_unchanged=same_before,engine_groups=len(after['engine_seeds']),
                        shared_seed=True,installed_files=installed)
    pictures=[]
    for pic in sorted(DEST.glob('*.jpg')):
        with Image.open(pic) as im:
            assert im.height<=720 and im.width==1280, (pic,im.size)
        verify(pic)
        mirror=PROOF/pic.name
        assert pic.read_bytes()==mirror.read_bytes(), (pic,'PC picture differs')
        pictures.append(pic.name)
    assert len(pictures)==16, pictures
    result=dict(ok=True,ships=rows,pictures=pictures,geometry_source_edits=geometry_edits,
                note='Painted meshes match fresh builds of unchanged approved sheets. Pre-job A18 install differs from the current sheet in D1 seating, engine throat/lining meshes and one generated running lamp. This normal repaint uses the current approved sheet; no geometry sources were edited.')
    (DEST/'delivery_check.json').write_text(json.dumps(result,indent=2)+'\n')
    shutil.copy2(DEST/'delivery_check.json',PROOF/'delivery_check.json')
    print('PASS delivery: five installs in both games, matching manifests and approved geometry, no geometry source edits, shared engine seeds, 16 labelled 720p pictures; A18 pre-existing install drift recorded')


if __name__=='__main__':
    main()
