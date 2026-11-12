# Ship recipe: the standing checks every ship keeps for the rest of its life (outside audit pass 2, findings 3, 4 and 13;
# FINDINGS R160 point (f); docs/ship_pipeline/HARDPOINTS.md). Plain Python, no bpy and no numpy.
#   outline  the outline score per third (bow, midship, stern) and the inner edge check from the concept camera. The
#            overlap numbers are REPORTED against the ship json outline_gate, never a pass bar (RULEBOOK 5.8); missing
#            numbers or missing inner edge distances still fail loudly.
#   battle   the outline score from the second camera, the game's battle camera at r 170 (outline_battle.py), both cameras
#   paint    the concept side, the far side and the underside stills all exist (stage 5 render.py)
#   blink    the concept and model blink sheet exists (blink.py)
#   licences every downloaded texture used by the bake has its licence line recorded per texture as used
#   lights   every window and trim light is at least light_min_px across at the battle camera on a 70 px ship
#   all      every check above; the recipe runs this before stage 7 will export
#   selftest build good fixtures in the system temp folder and prove each check refuses its own broken copy
# usage: python standing.py CHECK --ship SHIP.json --job JOB_DIR
#   The stage outputs are read from JOB_DIR: sil/outline_thirds.json, sil/outline_battle.json, r/<cell>_*.png, bow_blink.gif,
#   textures/ and licences.json. Nothing is written outside the system temp folder by selftest.
import os, sys, json, shutil, tempfile, argparse

THIRDS = ('bow', 'midship', 'stern')
LICENCES = ('CC0', 'CC-BY', 'CC-BY-SA', 'public domain', 'own work', 'own')
EDGE_KEYS = ('edge_cell_to_concept_median_px', 'edge_cell_within_6px', 'edge_concept_to_cell_median_px', 'edge_concept_within_6px')


def load_ship(path):
    with open(path, encoding='utf-8') as f:
        return json.load(f)


def fail(msg):
    print('FAIL', msg)
    return 1


def ok(msg):
    print('PASS', msg)
    return 0


def check_outline(ship, job):
    cell = ship.get('cell') or ship.get('ship')
    gate = 100.0 * float(ship.get('outline_gate', .9))
    slack = float(ship.get('outline_third_slack', 5.0))
    floor = gate - slack
    p = os.path.join(job, 'sil', 'outline_thirds.json')
    if not os.path.exists(p):
        return fail(f'outline: no {p} (stage 3 and stage 4 must run outline_thirds.py)')
    d = json.load(open(p, encoding='utf-8')).get('cells', {}).get(cell)
    if not d:
        return fail(f'outline: no cell {cell} in {p}')
    bad = []
    for t in THIRDS:
        n = d.get(t) or {}
        if 'overlap' not in n:
            bad.append(f'{t}: no overlap'); continue
        for k in EDGE_KEYS:
            if k not in n:
                bad.append(f'{t}: no {k} (the inner edge check did not run)')
    whole = (d.get('whole') or {}).get('overlap')
    if whole is None:
        bad.append('no whole overlap')
    if bad:
        for b in bad:
            print('  FAIL', b)
        return fail(f'outline: {cell} does not have a complete standing outline record')
    # RULEBOOK 5.8: the overlap against the concept is a reported number, not a pass bar. The old gate and floor are
    # printed beside it so the builder can see where the shape sits, and a low number is a note, never a failure.
    print(f'  outline {cell}: bow {d["bow"]["overlap"]}, midship {d["midship"]["overlap"]}, stern {d["stern"]["overlap"]}, whole {whole} '
          f'(reported, not a pass bar; old gate {gate:.0f}, old per-third floor {floor:.1f})')
    print(f'  inner edges within 6 px bow {d["bow"]["edge_cell_within_6px"]}, midship {d["midship"]["edge_cell_within_6px"]}, stern {d["stern"]["edge_cell_within_6px"]}')
    for t in THIRDS:
        v = float(d[t]['overlap'])
        if v < floor:
            print(f'  REPORT {t} overlap {v} percent is below the old per-third floor {floor:.1f}; no failure (RULEBOOK 5.8)')
    if float(whole) < gate:
        print(f'  REPORT whole overlap {whole} percent is below the old gate {gate:.0f}; no failure (RULEBOOK 5.8)')
    return ok('outline per third and inner edge data are present; the overlap is reported, not a pass bar')


def check_battle(ship, job):
    cell = ship.get('cell') or ship.get('ship')
    p = os.path.join(job, 'sil', 'outline_battle.json')
    if not os.path.exists(p):
        return fail(f'battle camera: no {p} (stage 4 must run outline_battle.py)')
    d = json.load(open(p, encoding='utf-8')).get('cells', {}).get(cell)
    if not d:
        return fail(f'battle camera: no cell {cell} in {p}')
    bad = []
    for cam in ('game', 'studio'):
        n = d.get(cam) or {}
        for t in THIRDS + ('whole',):
            if t not in n:
                bad.append(f'{cam} {t}: missing')
    if bad:
        for b in bad:
            print('  FAIL', b)
        return fail(f'battle camera: {cell} has no complete second-camera score')
    print('  battle camera ' + cell + ': ' + ', '.join(f'{cam} ' + ' '.join(f'{t} {d[cam][t]}' for t in THIRDS + ('whole',)) for cam in ('game', 'studio')))
    return ok('the outline score from the second camera (the game battle camera, r 170) is recorded')


def check_paint(ship, job):
    cell = ship.get('cell') or ship.get('ship')
    need = {
        'concept side': os.path.join(job, 'r', f'{cell}_concept_cl.png'),
        'far side': os.path.join(job, 'r', f'{cell}_side_s.png'),
        'underside': os.path.join(job, 'r', f'{cell}_below.png'),
    }
    missing = [f'{k}: {v}' for k, v in need.items() if not os.path.exists(v)]
    if missing:
        for m in missing:
            print('  FAIL', m)
        return fail('paint: the concept side, far side and underside stills must all be rendered')
    return ok('paint is judged on the concept side, the far side and the underside stills')


def check_blink(ship, job):
    p = os.path.join(job, 'bow_blink.gif')
    if not os.path.exists(p):
        return fail(f'blink: no {p} (stage 5 must run blink.py)')
    return ok('the concept and model blink sheet exists')


def check_licences(ship, job):
    tdir = os.path.join(job, 'textures')
    files = []
    if os.path.isdir(tdir):
        for root, _, names in os.walk(tdir):
            for n in names:
                files.append(os.path.relpath(os.path.join(root, n), tdir).replace('\\', '/'))
    if not files:
        return ok('licences: no downloaded textures are used (nothing to record)')
    p = os.path.join(job, 'licences.json')
    if not os.path.exists(p):
        return fail(f'licences: {len(files)} downloaded textures but no {p}')
    try:
        rows = json.load(open(p, encoding='utf-8')).get('textures', [])
    except ValueError as e:
        return fail(f'licences: {p} is not JSON: {e}')
    by_file = {}
    for r in rows:
        if not isinstance(r, dict) or not r.get('file'):
            return fail(f'licences: an entry has no file: {r!r}')
        by_file[str(r['file']).replace('\\', '/')] = r
    bad = []
    for f in files:
        r = by_file.get(f)
        if r is None:
            bad.append(f'{f}: no licence line'); continue
        for k in ('source', 'licence', 'used'):
            if not r.get(k):
                bad.append(f'{f}: no {k}')
        if r.get('licence') and str(r['licence']) not in LICENCES:
            bad.append(f'{f}: licence {r["licence"]!r} is not one of {", ".join(LICENCES)}')
    if bad:
        for b in bad:
            print('  FAIL', b)
        return fail(f'licences: {len(bad)} problem(s); every downloaded texture needs its own line as used')
    return ok(f'licences: {len(files)} downloaded texture(s), each with a source, a licence and what it is used for')


def _px(v):
    if isinstance(v, dict):
        return v.get('px')
    return v


def check_lights(ship, job):
    lights = dict(ship.get('lights') or {})
    # issue 601: a paint stack that builds lights measures them and writes the job's lights.json; the measured size wins
    mp = os.path.join(job, 'lights.json')
    if os.path.exists(mp):
        try:
            lights.update(json.load(open(mp, encoding='utf-8')).get('lights', {}))
        except ValueError as e:
            return fail(f'lights: {mp} is not JSON: {e}')
    if not lights:
        return ok('lights: no window or trim lights are declared (the paint has no light map yet)')
    floor = float(ship.get('light_min_px', 2.0))
    bad = []
    for k, v in lights.items():
        px = _px(v)
        if px is None:
            bad.append(f'{k}: no px size'); continue
        if float(px) < floor:
            bad.append(f'{k}: {px} px across on a 70 px ship is below the {floor:.1f} px floor')
    if bad:
        for b in bad:
            print('  FAIL', b)
        return fail('lights: a light that is too small will not read at the battle camera')
    return ok(f'lights: every declared window and trim light is at least {floor:.1f} px across on a 70 px ship')


CHECKS = dict(outline=check_outline, battle=check_battle, paint=check_paint, blink=check_blink, licences=check_licences, lights=check_lights)


def run(name, ship, job):
    return CHECKS[name](ship, job)


def write_fixture(root, good=True):
    """the good fixture, or one broken copy per check when good is False. Returns (ship json path, job dir)."""
    os.makedirs(os.path.join(root, 'sil'), exist_ok=True)
    os.makedirs(os.path.join(root, 'r'), exist_ok=True)
    os.makedirs(os.path.join(root, 'textures'), exist_ok=True)
    ship = dict(ship='SELFTEST', cell='T1', outline_gate=.9, outline_third_slack=5.0, lights={'window_px': 2.5, 'trim_px': 2.0}, light_min_px=2.0)
    if not good:
        ship['lights']['trim_px'] = 1.0
    sp = os.path.join(root, 'ship.json')
    json.dump(ship, open(sp, 'w'), indent=1)
    thirds = {}
    for k, v in (('bow', 80.0), ('midship', 80.0), ('stern', 70.0)):
        thirds[k] = dict(overlap=v, **{e: 10.0 for e in EDGE_KEYS})
    if not good:
        # RULEBOOK 5.8: a low overlap is reported, so the broken copy is missing an inner edge distance instead.
        thirds['stern'].pop('edge_cell_within_6px')
    thirds['whole'] = dict(overlap=78.0)
    json.dump(dict(cells={'T1': thirds}), open(os.path.join(root, 'sil', 'outline_thirds.json'), 'w'), indent=1)
    battle = {'game': dict(bow=85.2, midship=90.9, stern=85.8, whole=87.7), 'studio': dict(bow=74.6, midship=90.7, stern=89.2, whole=86.0)}
    json.dump(dict(cells={'T1': battle}), open(os.path.join(root, 'sil', 'outline_battle.json'), 'w'), indent=1)
    for n in ('T1_concept_cl.png', 'T1_side_s.png', 'T1_below.png'):
        open(os.path.join(root, 'r', n), 'wb').write(b'x')
    open(os.path.join(root, 'bow_blink.gif'), 'wb').write(b'x')
    open(os.path.join(root, 'textures', 'stone.png'), 'wb').write(b'x')
    rows = [] if not good else [dict(file='stone.png', source='https://ambientcg.example/stone', licence='CC0', used='hull albedo grime')]
    json.dump(dict(textures=rows), open(os.path.join(root, 'licences.json'), 'w'), indent=1)
    return sp, root


def selftest():
    tmp = tempfile.mkdtemp(prefix='standing-selftest-')
    try:
        good = os.path.join(tmp, 'good'); os.makedirs(good)
        sp, job = write_fixture(good, True)
        ship = load_ship(sp)
        bad = 0
        for name in CHECKS:
            code = run(name, ship, job); bad += code != 0
        broken = os.path.join(tmp, 'broken'); os.makedirs(broken)
        sp2, job2 = write_fixture(broken, False)
        ship2 = load_ship(sp2)
        for name in ('outline', 'licences', 'lights'):
            code = run(name, ship2, job2); bad += code == 0
        os.remove(os.path.join(job2, 'r', 'T1_side_s.png'))
        bad += run('paint', ship2, job2) == 0
        os.remove(os.path.join(job2, 'sil', 'outline_battle.json'))
        bad += run('battle', ship2, job2) == 0
        os.remove(os.path.join(job2, 'bow_blink.gif'))
        bad += run('blink', ship2, job2) == 0
        return bad
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    a = sys.argv[1:]
    if not a:
        print(__doc__ or 'usage: python standing.py CHECK --ship SHIP.json --job JOB_DIR'); return 1
    name = a[0]
    if name == 'selftest':
        bad = selftest()
        print('PASS the standing gate passes good output and fails each broken copy' if not bad else
              f'FAIL {bad} case(s) did not behave (the gate let a broken copy through, or refused a good one)')
        return 0 if not bad else 1
    if name not in CHECKS and name != 'all':
        print(f'unknown check {name}; use one of {", ".join(list(CHECKS) + ["all", "selftest"])}'); return 1
    ap = argparse.ArgumentParser(); ap.add_argument('--ship', required=True); ap.add_argument('--job', required=True)
    ns = ap.parse_args(a[1:])
    ship = load_ship(ns.ship)
    if name == 'all':
        codes = [run(n, ship, ns.job) for n in CHECKS]
        print('PASS every standing check' if not any(codes) else 'FAIL one or more standing checks')
        return 0 if not any(codes) else 1
    return run(name, ship, ns.job)


if __name__ == '__main__':
    sys.exit(main())
