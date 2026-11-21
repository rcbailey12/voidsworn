"""Issue 1311: publish_ship.py against the real ship_job receipts and a stand-in game folder (no Godot, no Windows needed).

  python tools/recipe/test/publish_ship_selftest.py
Receipts: the three real ones in test/publish_receipts (S9 shipjob5 R3 and CD5 r5d end "all done"; S10 shipjob5 ends "all
done" then "pin ok <sha>") pass with their own commit and glb, and fail on another commit, a short commit, a glb other than the
listed one, a "pin ok" of another commit, a done FAILED line, a collected file whose sha256 is not the listed one, and a checked
file the export does not hold. Undo: publish A, publish B, undo A puts back only A (its files, scenes and manifest rows) and
leaves B as published; an undo after A's live files changed refuses and touches nothing; a corrupt or missing kept copy
is refused before anything live moves (UNDO FAILED, exit 1, never UNDO PASS); a failure forced in the middle of the live
steps puts the published files, scenes and both manifest rows back, and a clean undo still passes afterwards. Restore after
a failed install puts back the damage and wreck scenes the cache refresh rewrote, and refuses a corrupt kept copy. Prints PASS lines and exits 0, or stops at the first failure.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
TOOL = HERE.parent / 'publish_ship.py'
RECEIPTS = HERE / 'publish_receipts'
passed = 0


def ok(what):
    global passed
    passed += 1
    print('PASS ' + what)


def run(*args):
    r = subprocess.run([sys.executable, '-B', str(TOOL), *map(str, args)], capture_output=True, text=True, cwd=str(TOOL.parent))
    return r.returncode, r.stdout + r.stderr


def sha(b):
    return hashlib.sha256(b).hexdigest()


# the V14_23 export of opus1156 (export7's 8 files); CODE_export.json lists each as {"bytes": N, "sha256": hex}
LAYOUT = ('{c}.glb', '{c}_base.jpg', '{c}_normal.png', '{c}_orm.png', '{c}_parts_base.jpg', '{c}_parts_normal.png',
          '{c}_parts_orm.png', '{c}_maps.json')


# issue 1517: the stage 5 surface-detail verdict every published job carries (detail_check.py's PASS line)
DETAIL_PASS = ('Blender 4.5.4 LTS\nPASS detail check: normal relief 2.61 deg (floor 2.00), albedo contrast 0.310 (floor 0.060), '
               'roughness spread 0.115 (floor 0.060), 8528 texels\n')


def fake_job(root, receipt, code, files=None, bare=False):
    """a job folder: the real receipt, an export with CODE_export.json listing its files in export7's shape ({"bytes",
    "sha256"} per file; bare=True writes the old bare hex string), the clone's checked install"""
    job = root / receipt.split('_result')[0]
    exp = job / 'out' / 'recipe' / 'export' / code
    inst = job / 'repo' / 'godot' / 'assets' / 'ships' / code
    exp.mkdir(parents=True)
    inst.mkdir(parents=True)
    shutil.copy(RECEIPTS / receipt, job / 'out' / 'result.txt')
    (job / 'out' / 'recipe' / 'log_detail.txt').write_text(DETAIL_PASS, encoding='utf-8')
    files = files or {n.format(c=code): (n.split('}')[1] + ' ' + code).encode() for n in LAYOUT}
    files[f'{code}_base.jpg'] = b'base ' + code.encode()
    for name, data in files.items():
        (exp / name).write_bytes(data)
        (inst / name).write_bytes(data)
    (inst / f'{code}.glb.import').write_text('godot import', encoding='utf-8')
    listed = {n: sha(d) if bare else dict(bytes=len(d), sha256=sha(d)) for n, d in files.items()}
    (exp / f'{code}_export.json').write_text(json.dumps(dict(ship='S', code=code, files=listed), indent=2), encoding='utf-8')
    return job, sha(files[f'{code}.glb'])


def check_receipts(root):
    cases = [('1156_shipjob5_R3_result.txt', 'V14_23', '2c2e86da0b4a8ef930012c4b4d6e85752c95635a'),
             ('1183_r5d_result.txt', 'I8_37', '6b69276a47fc8a0d674d4ad88a5fd244bc5a637d'),
             ('1157_shipjob5_result.txt', 'V16_37', 'e511d6d5882b5ac57d3a8ce424df0a124afaa0c1')]
    for receipt, code, commit in cases:
        job, glb = fake_job(root / 'r', receipt, code)
        rec = root / (code + '.json')
        rc, out = run('receipt', job, code, commit, glb, rec)
        assert rc == 0 and 'SHIP=' in out, out
        ok(f'{receipt} passes with its own commit and glb')
        for bad, why in ((('receipt', job, code, '0' * 40, glb, rec), 'another commit'),
                         (('receipt', job, code, commit[:8], glb, rec), 'a short commit'),
                         (('receipt', job, code, commit, '0' * 64, rec), 'another glb'),
                         (('receipt', job, code, commit, glb[:8], rec), 'a glb prefix'),
                         (('receipt', job, 'X1_11', commit, glb, rec), 'another code')):
            rc, out = run(*bad)
            assert rc == 1 and 'SHIP=' not in out, f'{receipt} with {why}: {out}'
        ok(f'{receipt} refuses another commit, a short commit, another or partial glb, another code')
        res = job / 'out' / 'result.txt'
        text = res.read_text(encoding='utf-8')
        if 'pin ok' in text:
            res.write_text(text.replace('pin ok ' + commit, 'pin ok ' + 'f' * 40), encoding='utf-8')
            rc, out = run('receipt', job, code, commit, glb, rec)
            assert rc == 1, out
            ok(f'{receipt} refuses a pin ok of another commit')
        res.write_text(text.replace('done PASS', 'done FAILED: shots'), encoding='utf-8')
        rc, out = run('receipt', job, code, commit, glb, rec)
        assert rc == 1, out
        res.write_text(text, encoding='utf-8')
        exp = job / 'out' / 'recipe' / 'export' / code
        (exp / f'{code}_base.jpg').write_bytes(b'changed')
        rc, out = run('receipt', job, code, commit, glb, rec)
        assert rc == 1 and 'not the sha256' in out, out
        (exp / f'{code}_base.jpg').write_bytes(b'base ' + code.encode())
        (job / 'repo' / 'godot' / 'assets' / 'ships' / code / f'{code}_extra.png').write_bytes(b'checked only')
        rc, out = run('receipt', job, code, commit, glb, rec)
        assert rc == 1 and 'was checked by the job' in out, out
        ok(f'{receipt} refuses a done FAILED, a changed export file and a checked file the export lacks')
        (job / 'repo' / 'godot' / 'assets' / 'ships' / code / f'{code}_extra.png').unlink()
        log = job / 'out' / 'recipe' / 'log_detail.txt'
        for text, why in (('detail check FAIL: a flat clay surface (normal under the hegemony floor): normal relief 1.54 deg\n',
                           'a detail FAIL'),
                          ('detail check NOT RUN: bake bakeAb6.py is not the paint stack\n', 'a detail check not run'),
                          ('Blender quit\n', 'no verdict line'), (None, 'no log_detail.txt'),
                          (DETAIL_PASS + 'detail check FAIL: second\n', 'two verdicts')):
            log.unlink(missing_ok=True)
            if text is not None:
                log.write_text(text, encoding='utf-8')
            rc, out = run('receipt', job, code, commit, glb, rec)
            assert rc == 1 and 'SHIP=' not in out and 'detail' in out, f'{receipt} with {why}: {out}'
        log.write_text('OPT-OUT detail check: normal under the floor, Ryan 2026-11-21: "fine as it is"; normal relief 1.20\n',
                       encoding='utf-8')
        rc, out = run('receipt', job, code, commit, glb, rec)
        assert rc == 0 and 'SHIP=' in out, out
        assert json.loads(rec.read_text(encoding='utf-8'))['detail'].startswith('OPT-OUT detail check'), rec.read_text()
        log.write_text(DETAIL_PASS, encoding='utf-8')
        ok(f'{receipt} refuses a detail FAIL, a check not run, no verdict, no log and two verdicts; a dated opt-out passes')
    # PR 1312 run one: the real CODE_export.json lists {"bytes", "sha256"}; the old bare hex form still passes, a listing
    # with no full sha256 or a wrong size is refused
    receipt, code, commit = cases[0]
    job, glb = fake_job(root / 'bare', receipt, code, bare=True)
    rc, out = run('receipt', job, code, commit, glb, root / 'bare.json')
    assert rc == 0 and 'SHIP=' in out and '8 listed' in out, out
    job, glb = fake_job(root / 'shape', receipt, code)
    js = job / 'out' / 'recipe' / 'export' / code / f'{code}_export.json'
    good = js.read_text(encoding='utf-8')
    rc, out = run('receipt', job, code, commit, glb, root / 'shape.json')
    assert rc == 0 and '8 listed and 8 checked' in out, out
    d = json.loads(good)
    d['files'][f'{code}_orm.png']['bytes'] += 1
    js.write_text(json.dumps(d), encoding='utf-8')
    rc, out = run('receipt', job, code, commit, glb, root / 'shape.json')
    assert rc == 1 and 'not the size' in out, out
    d = json.loads(good)
    d['files'][f'{code}_orm.png'] = dict(bytes=3)
    js.write_text(json.dumps(d), encoding='utf-8')
    rc, out = run('receipt', job, code, commit, glb, root / 'shape.json')
    assert rc == 1 and 'without a full sha256' in out, out
    ok('the real export json shape ({"bytes", "sha256"}, 8 files) passes, the bare form too; a wrong size or no sha256 is refused')


def fake_game(root):
    game = root / 'game'
    (game / 'assets' / 'ships').mkdir(parents=True)
    for d in ('ships', 'damage', 'wreck'):
        (game / 'gen' / d).mkdir(parents=True)
    (game / 'project.godot').write_text('', encoding='utf-8')
    rows = {}
    for code in ('A1_11', 'B2_22', 'C3_33'):
        (game / 'assets' / 'ships' / code).mkdir()
        (game / 'assets' / 'ships' / code / f'{code}.glb').write_bytes(b'old ' + code.encode())
        (game / 'gen' / 'ships' / f'{code}.scn').write_bytes(b'old scene ' + code.encode())
        rows[code] = dict(old=code)
    (game / 'assets' / 'ships' / 'manifest.json').write_text(json.dumps(dict(note='n', ships=rows)), encoding='utf-8')
    (game / 'gen' / 'manifest.json').write_text(json.dumps(dict(hulls={}, ships={c: dict(src='old ' + c) for c in rows})), encoding='utf-8')
    return game


def stand_in_install(game, code, tag):
    """what manifest_merge --install and the cache rebuild do to one ship, by hand"""
    live = game / 'assets' / 'ships' / code
    os.replace(live, game / f'_gone_{code}_{tag}') if live.exists() else None
    live.mkdir()
    (live / f'{code}.glb').write_bytes(b'new ' + tag.encode())
    (live / f'{code}_maps.png').write_bytes(b'new maps ' + tag.encode())
    (game / 'gen' / 'ships' / f'{code}.scn').write_bytes(b'new scene ' + tag.encode())
    (game / 'gen' / 'damage' / f'{code}_damage.scn').write_bytes(b'new damage ' + tag.encode())
    for rel, val in (('assets/ships/manifest.json', dict(new=tag)), ('gen/manifest.json', dict(src='new ' + tag))):
        p = game / rel
        d = json.loads(p.read_text(encoding='utf-8'))
        d['ships'][code] = val
        p.write_text(json.dumps(d), encoding='utf-8')


def snapshot(game):
    return {str(p.relative_to(game)): p.read_bytes() for p in sorted(game.rglob('*')) if p.is_file() and '_replaced' not in p.parts
            and not p.name.startswith('_gone') and p.name != '.stage7.lock' and not any(q.startswith('_gone') for q in p.relative_to(game).parts)}


def rows_of(game, rel):
    return json.loads((game / rel).read_text(encoding='utf-8'))['ships']


def check_undo(root):
    game = fake_game(root)
    start = snapshot(game)
    a, b = game / '_replaced' / 'A1_11_1', game / '_replaced' / 'B2_22_1'
    for code, dest in (('A1_11', a), ('B2_22', b)):
        rc, out = run('backup', game, code, dest)
        assert rc == 0, out
        stand_in_install(game, code, code)
        rc, out = run('seal', game, code, dest)
        assert rc == 0, out
    published = snapshot(game)
    rc, out = run('undo', game, 'A1_11', a)
    assert rc == 0 and 'UNDO PASS A1_11' in out, out
    now = snapshot(game)
    for k in now:
        if 'A1_11' in k:
            assert now[k] == start.get(k), f'{k} not put back'
        elif 'B2_22' in k:
            assert now[k] == published[k], f'{k} of B changed by the undo of A'
    assert not (game / 'gen' / 'damage' / 'A1_11_damage.scn').exists(), 'the new damage scene of A stays live'
    for rel in ('assets/ships/manifest.json', 'gen/manifest.json'):
        r = rows_of(game, rel)
        assert r['A1_11'] == json.loads(start[rel.replace('/', os.sep)])['ships']['A1_11'], rel + ' A row not restored'
        assert r['B2_22'] == json.loads(published[rel.replace('/', os.sep)])['ships']['B2_22'], rel + ' B row rolled back'
        assert r['C3_33'] == json.loads(start[rel.replace('/', os.sep)])['ships']['C3_33'], rel + ' C row changed'
    assert (a / 'undone_1' / 'published' / 'assets' / 'ships' / 'A1_11' / 'A1_11.glb').read_bytes() == b'new A1_11', 'the published A is not kept aside'
    ok('publish A, publish B, undo A: only A goes back (files, scenes, both manifest rows); B and C stay as they were')

    rc, out = run('undo', game, 'A1_11', a)
    assert rc == 1 and 'UNDO FAILED' in out and 'UNDO PASS' not in out, out
    (game / 'assets' / 'ships' / 'B2_22' / 'B2_22.glb').write_bytes(b'someone else')
    before = snapshot(game)
    rc, out = run('undo', game, 'B2_22', b)
    assert rc == 1 and 'changed since this publish' in out and 'UNDO PASS' not in out, out
    assert snapshot(game) == before, 'a refused undo touched the game'
    ok('an undo refuses, touching nothing, once the ship changed since its publish (and a second undo of A)')

    (game / 'assets' / 'ships' / 'B2_22' / 'B2_22.glb').write_bytes(b'new B2_22')
    published = snapshot(game)
    for spoil, why in ((lambda: (b / 'ship' / 'B2_22.glb').write_bytes(b'corrupt'), 'a corrupt kept ship file'),
                       (lambda: os.replace(b / 'ship', b / 'ship_hidden'), 'a missing kept ship folder'),
                       (lambda: (b / 'gen' / 'ships' / 'B2_22.scn').write_bytes(b'corrupt'), 'a corrupt kept scene')):
        keep = Path(tempfile.mkdtemp())
        shutil.copytree(b, keep / 'b')
        spoil()
        rc, out = run('undo', game, 'B2_22', b)
        assert rc == 1 and 'UNDO FAILED' in out and 'UNDO PASS' not in out and 'nothing was touched' in out, f'{why}: {out}'
        assert snapshot(game) == published, f'{why}: the undo touched the live game'
        shutil.rmtree(b)
        shutil.copytree(keep / 'b', b)
    ok('a corrupt or missing kept copy is refused before anything live moves; live files and both manifest rows intact')

    # a failure in the middle of the live steps: the third os.replace inside the undo raises
    sys.path.insert(0, str(TOOL.parent))
    import publish_ship
    real, calls = os.replace, []

    def flaky(src, dst):
        calls.append(src)
        if len(calls) == 3:
            raise OSError('forced failure')
        return real(src, dst)
    publish_ship.os.replace = flaky
    try:
        publish_ship.undo(str(game), 'B2_22', str(b))
        raise AssertionError('the forced failure did not stop the undo')
    except ValueError as exc:
        assert 'put back as it was' in str(exc), exc
    finally:
        publish_ship.os.replace = real
    assert snapshot(game) == published, 'a failed undo left the live game changed'
    for rel in ('assets/ships/manifest.json', 'gen/manifest.json'):
        assert rows_of(game, rel)['B2_22'] == json.loads(published[rel.replace('/', os.sep)])['ships']['B2_22'], rel
    ok('a forced failure in the middle of the live steps puts the published ship back: live folder, scenes, both rows')
    rc, out = run('undo', game, 'B2_22', b)
    assert rc == 0 and 'UNDO PASS B2_22' in out, out
    ok('after the failed attempt, a clean undo of B still passes')


def check_restore(root):
    """a failed install (Fable, PR 1312): manifest_merge rolls back the ship, its scene and both manifests, but the cache refresh
    has rewritten the damage and wreck scenes in place; restore puts every kept file back and reports what it did"""
    game = fake_game(root)
    (game / 'gen' / 'damage' / 'C3_33_damage.scn').write_bytes(b'old damage C3_33')
    (game / 'gen' / 'wreck' / 'C3_33_wreck.scn').write_bytes(b'old wreck C3_33')
    start = snapshot(game)
    c = game / '_replaced' / 'C3_33_1'
    rc, out = run('restore', game, 'C3_33', c)
    assert rc == 1 and 'RESTORE FAILED' in out, 'a restore with no backup must fail: ' + out
    rc, out = run('backup', game, 'C3_33', c)
    assert rc == 0, out
    rc, out = run('restore', game, 'C3_33', c)
    assert rc == 0 and 'already exactly as before' in out, out
    (game / 'gen' / 'damage' / 'C3_33_damage.scn').write_bytes(b'new damage from the failed build')
    (game / 'gen' / 'wreck' / 'C3_33_wreck.scn').write_bytes(b'new wreck from the failed build')
    rc, out = run('restore', game, 'C3_33', c)
    assert rc == 0 and 'RESTORE PASS C3_33' in out and 'scenes' in out, out
    assert snapshot(game) == start, 'restore did not put the damage and wreck scenes back'
    ok('after a failed install, restore puts back the damage and wreck scenes the cache refresh rewrote in place')
    (game / 'gen' / 'wreck' / 'C3_33_wreck.scn').write_bytes(b'new wreck again')
    (c / 'gen' / 'wreck' / 'C3_33_wreck.scn').write_bytes(b'corrupt kept copy')
    before = snapshot(game)
    rc, out = run('restore', game, 'C3_33', c)
    assert rc == 1 and 'RESTORE FAILED' in out and 'RESTORE PASS' not in out and 'nothing was touched' in out, out
    assert snapshot(game) == before, 'a refused restore touched the game'
    ok('a restore with a corrupt kept copy reports RESTORE FAILED, exit 1, and touches nothing')
    (c / 'gen' / 'wreck' / 'C3_33_wreck.scn').write_bytes(b'old wreck C3_33')
    rc, out = run('restore', game, 'C3_33', c)
    assert rc == 0 and 'RESTORE PASS C3_33' in out, out
    d = game / '_replaced' / 'C3_33_2'
    rc, out = run('backup', game, 'C3_33', d)
    assert rc == 0, out
    stand_in_install(game, 'C3_33', 'D')
    landed = snapshot(game)
    rc, out = run('restore', game, 'C3_33', c)
    assert rc == 1 and 'RESTORE FAILED' in out and 'another publish' in out and 'nothing was touched' in out, out
    assert snapshot(game) == landed, 'an older attempt\'s restore rolled back a later publish of the same ship'
    ok('a failed attempt\'s restore refuses, touching nothing, when a later publish of the same ship landed in the gap')
    rc, out = run('locked', game, sys.executable, '-c', 'raise SystemExit(3)')
    assert rc == 3, out
    ok('locked runs a command under the install lock and returns its exit code')


def main():
    with tempfile.TemporaryDirectory() as t:
        check_receipts(Path(t))
    with tempfile.TemporaryDirectory() as t:
        check_undo(Path(t))
    with tempfile.TemporaryDirectory() as t:
        check_restore(Path(t))
    print(f'publish_ship_selftest: {passed} passed')
    return 0


if __name__ == '__main__':
    sys.exit(main())
