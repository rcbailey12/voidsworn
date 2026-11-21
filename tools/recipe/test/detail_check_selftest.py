"""Issue 1517: the stage 5 surface-detail check gates every faction, and the sheet and publish tools refuse a build without
its PASS. No Blender: the fixtures are real PC bakes measured over the skin texels Blender's UVs gave.

  python tools/recipe/test/detail_check_selftest.py

Fixtures (tools/recipe/test/detail_fixtures/, docs/ship_pipeline/detail_floors.md says how they were made):
  O2   Navy Convoy transport O2 at board/pin-1413c (e031f492): the PC run opus1413o2c's own 4096 atlases, box-downsampled to
       the check's 1024, every texel more than 3 away from the skin zeroed; the masks are the skin texels of the same build's
       UVs. Ryan caught its clay look on Nov 21; it must fail.
  C12  Chorus Drone-spawn C12, round G (PC run opus1291c12d, board/pin-1291-wrap1, 392b9468), accepted Nov 20 (R374): one
       quarter of its skin texels (every other 128 px tile both ways), to keep the fixture small. It must pass.
  S10  Sunward Vigil S10 (PC run 1157 shipjob9, eef9fd81), accepted Nov 20 (PR 1166): the same quarter. It must pass.
Every temporary file stays in TEMP.
"""
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
RECIPE = HERE.parent
sys.path.insert(0, str(RECIPE))
sys.path.insert(0, str(RECIPE.parent))
import detail_check as DC  # noqa: E402

FIX = HERE / 'detail_fixtures'
passed = 0


def ok(what):
    global passed
    passed += 1
    print('PASS ' + what)


def masks(cell):
    import numpy as np
    from PIL import Image
    out = {}
    for a in ('hull', 'parts'):
        p = FIX / cell / ('%s_%s_mask.png' % (cell, a))
        if p.exists():
            out[a] = np.asarray(Image.open(p).convert('L')) > 127
    return out


def run_main(tmp, cell, ship):
    """detail_check.main on a fixture copied to a temp job folder; returns (exit code, detail_check.json, printed line)"""
    import contextlib
    import io
    job = tmp / ('job_' + cell + '_' + str(abs(hash(json.dumps(ship, sort_keys=True))) % 10 ** 8))
    shutil.copytree(FIX / cell, job)
    sj = job / 'ship.json'
    sj.write_text(json.dumps(ship), encoding='utf-8')
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        rc = DC.main(str(job), cell, str(sj), masks=masks(cell))
    return rc, json.loads((job / 'detail_check.json').read_text(encoding='utf-8')), buf.getvalue().strip()


def check_floors():
    # every faction is gated by default: no key needed any more (it was Chorus only, issue 1291)
    for fac in ('voidsworn', 'hegemony', 'hullbreakers', 'eclipse', 'ithar', 'chorus', 'someday'):
        floors, opt, problem = DC.floors_for(dict(faction=fac))
        assert problem is None and opt is None and floors == DC.FLOORS.get(fac, DC.DEFAULT), (fac, floors)
    ok('every faction is gated by default with its own floors (an unknown faction takes the default)')
    floors, _, problem = DC.floors_for(dict(faction='hegemony', surface_detail={'normal': 9}))
    assert problem is None and floors['normal'] == 9
    _, _, problem = DC.floors_for(dict(faction='hegemony', surface_detail={'normal': 0.1}))
    assert problem and 'lowers' in problem
    _, _, problem = DC.floors_for(dict(faction='hegemony', surface_detail=False))
    assert problem and 'not an opt-out' in problem
    _, _, problem = DC.floors_for(dict(faction='hegemony', surface_detail={'opt_out': {'date': 'today', 'ryan': 'ok'}}))
    assert problem and 'date' in problem
    _, _, problem = DC.floors_for(dict(faction='hegemony', surface_detail={'opt_out': {'date': '2026-11-21', 'ryan': ''}}))
    assert problem and 'own words' in problem
    floors, opt, problem = DC.floors_for(dict(faction='hegemony', surface_detail={
        'normal': 0.1, 'opt_out': {'date': '2026-11-21', 'ryan': 'that one is meant to be smooth'}}))
    assert problem is None and opt['date'] == '2026-11-21' and floors['normal'] == 0.1
    ok('a ship may raise a floor; lowering one or the old "surface_detail": false needs a dated opt-out with Ryan\'s words')


def check_fixtures(tmp):
    rc, rec, line = run_main(tmp, 'O2', dict(faction='hegemony'))
    assert rc == 1 and rec['verdict'] == 'FAIL' and line.startswith('detail check FAIL') and 'albedo' in rec['low'], line
    assert DC.detail_verdict('Blender 4.5\n' + line + '\n') == 'FAIL'
    ok('O2 at pin-1413c fails the Navy floor (colour contrast): ' + line.split(': ', 2)[-1])
    rc, rec, line = run_main(tmp, 'O2', dict(faction='hegemony', surface_detail={'opt_out': {
        'date': '2026-11-21', 'ryan': 'selftest stand-in quote'}}))
    assert rc == 0 and rec['verdict'] == 'OPT-OUT' and line.startswith('OPT-OUT detail check') and '2026-11-21' in line, line
    ok('the same O2 bake passes only as a dated OPT-OUT line naming Ryan\'s words')
    rc, rec, line = run_main(tmp, 'O2', dict(faction='hegemony', surface_detail=False))
    assert rc == 1 and 'not an opt-out' in line, line
    ok('O2 with the old "surface_detail": false still fails')
    for cell, fac in (('C12', 'chorus'), ('S10', 'voidsworn')):
        rc, rec, line = run_main(tmp, cell, dict(faction=fac))
        assert rc == 0 and rec['verdict'] == 'PASS' and line.startswith('PASS detail check'), line
        assert DC.detail_verdict(line) == 'PASS'
        ok('%s (%s, accepted in game) passes: %s' % (cell, fac, line.split(': ', 1)[-1]))
    # a job with no atlas at all fails, whatever the faction
    empty = tmp / 'empty'
    empty.mkdir()
    (empty / 'ship.json').write_text(json.dumps(dict(faction='voidsworn')), encoding='utf-8')
    import contextlib
    import io
    with contextlib.redirect_stdout(io.StringIO()):
        rc = DC.main(str(empty), 'X1', str(empty / 'ship.json'))
    assert rc == 1
    ok('a job with no hull atlas fails for every faction')


JOB_COMMIT = 'e' * 40


def stamp(img, path, stage, commit=JOB_COMMIT):
    """save a picture with a real provenance stamp made at `commit` (the job clone's revision)"""
    from unittest.mock import patch
    from picture_provenance import save_picture
    with patch('picture_provenance.revision', return_value=dict(source_commit=commit, source_dirty=False,
                                                                 source_diff_sha256='')):
        save_picture(img, path, stage)


def fake_out(tmp, name, detail, result='start voidsworn_S10 V16_37 board/pin\ncommit=' + JOB_COMMIT + '\ndone PASS\nall done\n',
             renders=True, shots=False):
    from PIL import Image
    out = tmp / name
    (out / 'recipe' / 'r').mkdir(parents=True)
    (out / 'result.txt').write_text(result, encoding='utf-8')
    if detail is not None:
        (out / 'recipe' / 'log_detail.txt').write_text(detail, encoding='utf-8')
    if renders:
        stamp(Image.new('RGB', (1280, 720), (90, 80, 70)), out / 'recipe' / 'r' / 'S10_concept_cl.png', 'paint proof')
        stamp(Image.new('RGB', (1280, 720), (60, 70, 80)), out / 'recipe' / 'r' / 'S10_hero.png', 'paint proof')
    if shots:
        (out / 'shots').mkdir()
        stamp(Image.new('RGB', (1280, 720), (40, 60, 90)), out / 'shots' / 'V16_37_battle.jpg', 'installed in game')
    return out


def check_offer_sheet(tmp):
    import contextlib
    import io
    import offer_sheet as OS
    from PIL import Image

    def run(args):
        with contextlib.redirect_stdout(io.StringIO()) as buf:
            rc = OS.main([str(a) for a in args])
        return rc, buf.getvalue()

    good = 'PASS detail check: normal relief 1.62 deg (floor 1.30), albedo contrast 0.460 (floor 0.300), roughness spread 0.161 (floor 0.120), 102278 texels\n'
    cases = (('fail', 'detail check FAIL: a flat clay surface (normal under the hegemony floor): normal relief 1.25 deg\n'),
             ('old', 'detail check (reported, this ship has no surface_detail floor): normal relief 1.54 deg (floor 3.50)\n'),
             ('notrun', 'detail check NOT RUN: bake bakeAb6.py is not the paint stack\n'),
             ('missing', None))
    for name, detail in cases:
        out = fake_out(tmp, 'offer_' + name, detail, shots=True)
        sheet = tmp / ('sheet_' + name + '.jpg')
        rc, text = run([out, sheet])
        assert rc == 1 and not sheet.exists() and 'REFUSED' in text, (name, text)
    out = fake_out(tmp, 'offer_failedjob', good, result='start a b\ncommit=' + JOB_COMMIT + '\ndone FAILED: shots\nall done\n')
    assert run([out, tmp / 'sheet_failedjob.jpg'])[0] == 1
    ok('the offer sheet refuses a detail FAIL, the old reported-only line, a check not run, no log and a failed job')
    # Artoo on PR 1521: a passed job's sheet must show this job's own current proof of the sheet's stage
    out = fake_out(tmp, 'offer_noshots', good)
    rc, text = run([out, tmp / 'sheet_noshots.jpg'])
    assert rc == 1 and 'in-game shots' in text and not (tmp / 'sheet_noshots.jpg').exists(), text
    rc, text = run([out, tmp / 'sheet_rendersasgame.jpg', out / 'recipe' / 'r' / 'S10_hero.png'])
    assert rc == 1 and 'not "installed in game"' in text, text
    stamp(Image.new('RGB', (1280, 720), (1, 2, 3)), out / 'recipe' / 'r' / 'S10_old.png', 'paint proof', commit='a' * 40)
    rc, text = run([out, tmp / 'sheet_old.jpg', '--stage', 'paint proof', out / 'recipe' / 'r' / 'S10_old.png'])
    assert rc == 1 and 'not the job commit' in text, text
    Image.new('RGB', (1280, 720)).save(out / 'recipe' / 'r' / 'S10_plain.png')
    rc, text = run([out, tmp / 'sheet_plain.jpg', '--stage', 'paint proof', out / 'recipe' / 'r' / 'S10_plain.png'])
    assert rc == 1 and 'provenance' in text, text
    outside = tmp / 'concept.png'
    stamp(Image.new('RGB', (1280, 720), (9, 9, 9)), outside, 'paint proof')
    rc, text = run([out, tmp / 'sheet_outside.jpg', '--stage', 'paint proof', outside])
    assert rc == 1 and '--reference' in text, text
    ok('a passed job is refused with no in-game shots, a render passed as in-game, an old-commit, an unstamped or an outside picture')
    sheet = tmp / 'sheet_pass.jpg'
    Image.new('RGB', (1024, 1024), (120, 110, 90)).save(tmp / 'concept_unstamped.jpg')
    rc, text = run([out, sheet, '--stage', 'paint proof', '--reference', tmp / 'concept_unstamped.jpg'])
    assert rc == 0, text
    from picture_provenance import verify
    with Image.open(sheet) as im:
        assert im.height == OS.HEIGHT, im.size
    rec = verify(sheet)
    assert rec['stage'] == 'paint proof' and rec['source_commit'] == JOB_COMMIT, rec
    out = fake_out(tmp, 'offer_game', good, shots=True)
    rc, text = run([out, tmp / 'sheet_game.jpg'])
    assert rc == 0 and verify(tmp / 'sheet_game.jpg')['stage'] == 'installed in game', text
    ok('a passed job gets a 720 px sheet of its own stamped pictures (a concept only as a labelled reference), stamped with the job commit')


def main():
    check_floors()
    tmp = Path(tempfile.mkdtemp(prefix='detail1517_'))
    try:
        check_fixtures(tmp)
        check_offer_sheet(tmp)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    print('detail_check_selftest: %d passed' % passed)


if __name__ == '__main__':
    main()
