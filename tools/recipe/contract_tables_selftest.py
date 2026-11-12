# Ship recipe: the pure-Python half of the hard point contract check (no numpy, no bpy, so CI can run it). It proves the
# one breach count table, the smallest required set per class, the section and side layout, and every standing gate fixture.
# The glb half (check_export.py on the round 7 ship) is tools/recipe/contract_selftest.py; stage 7 runs it on the PC.
# usage: python contract_tables_selftest.py      (exit 0 when every case behaves)
import os, sys, io, contextlib
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.normpath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(REPO, 'tools', 'blender', 'kits', 'shared'))
import hardpoints as H, standing

bad = 0


def ok(cond, msg):
    global bad
    bad += not cond
    print(('ok  ' if cond else 'WRONG'), msg)


def main():
    table = [('Frigate', 'corsair', 3), ('Frigate', 'ithar', 1), ('Frigate', 'chorus', 2), ('Frigate', 'voidsworn', 2),
             ('Destroyer', 'corsair', 4), ('Destroyer', 'hegemony', 3), ('Cruiser', 'corsair', 5), ('Cruiser', 'ithar', 3),
             ('Cruiser', 'chorus', 4), ('Carrier', 'chorus', 7), ('Battleship', 'hegemony', 6), ('Battle-barge', 'corsair', 7),
             ('Dreadnought', 'corsair', 9), ('Dreadnought', 'ithar', 7), ('Bio-titan', 'chorus', 9), ('Tomb-ark', 'ithar', 7),
             ('Squadron', 'chorus', 0), ('beacon', 'hegemony', 0), ('station', 'chorus', 9), ('transport', 'corsair', 5)]
    for cls, fac, want in table:
        ok(H.expected_breach(cls, fac) == want, f'breach {cls} {fac}: {H.expected_breach(cls, fac)}, expected {want}')
    ok(H.expected_breach('Cruiser', 'hullbreakers') == 5, 'the ship json name hullbreakers reads as the corsair sheet (+1)')
    try:
        H.expected_breach('Corvette', 'corsair'); ok(False, 'an unknown class must fail, not default')
    except ValueError:
        ok(True, 'an unknown class fails loudly (no silent default)')
    ok(H.faction_key('Glasswrights') == 'ithar' and H.faction_key('The Chorus') == 'chorus', 'sheet names resolve to the data.js fac value')

    for n in (0, 1, 2, 3, 4, 5, 6, 7, 8, 9):
        lay = H.breach_layout(n)
        ok(len(lay) == n, f'{n} anchors: {len(lay)} in the layout')
        p = sum(1 for _, s in lay if s == 'P'); s = len(lay) - p
        ok(abs(p - s) <= 1, f'{n} anchors: {p} port, {s} starboard is within one of even')
        ok(not H.check_breach_layout(lay), f'{n} anchors: the layout passes its own section and side check')
    ok(H.breach_layout(2) == [('prow', 'P'), ('eng', 'S')], 'two anchors sit on the prow and the stern, one a side')
    ok(H.breach_layout(3) == [('prow', 'P'), ('mid', 'S'), ('eng', 'P')], 'three anchors cover all three sections')

    w = [('autocannon', 'F'), ('flak', 'T')]
    r = H.required_points(w, 'Frigate', 'corsair')
    ok(r == dict(weapon_slots=2, core=1, engine=1, bay=0, breach=3, rcs=2, board=2), 'a frigate needs two weapon points, one engine, 3 breaches, core, 2 rcs and 2 board')
    r = H.required_points([], 'Carrier', 'chorus', 2)
    ok(r['bay'] == 1 and r['breach'] == 7 and r['rcs'] == 2, 'a carrier needs a launch point and its class and faction breach count')
    r = H.required_points([('guns', 'T')], 'Squadron', 'chorus')
    ok(r == dict(weapon_slots=1, core=1, engine=0, bay=0, breach=0, rcs=0, board=0), 'a squadron craft needs a weapon point and a core only')
    r = H.required_points([], 'station', 'chorus')
    ok(r['rcs'] == 0 and r['board'] == 0 and r['engine'] == 0 and r['breach'] == 9, 'a station is placed: no engine, braking or boarding origins, and its class and faction breaches')

    full = dict(gun=2, engine=1, bay=0, breach=3, core=1, rcs=2, board=2)
    ok(not H.missing_required(full, w, 'Frigate', 'corsair'), 'the full set has no missing required point')
    for k, msg in (('gun', 'weapon'), ('engine', 'hp_eng'), ('breach', 'hp_breach'), ('core', 'hp_core'), ('rcs', 'hp_rcs'), ('board', 'hp_board')):
        c = dict(full); c[k] = 0
        probs = H.missing_required(c, w, 'Frigate', 'corsair')
        ok(any(msg in p for p in probs), f'no {k}: the missing set names {msg}')

    ok(not H.name_problem('hp_w0_autocannon_F_0'), 'a weapon name is one the contract defines')
    ok(not H.name_problem('hp_rcs_1') and not H.name_problem('hp_board_0'), 'the new braking and boarding names are defined')
    ok(H.name_problem('hp_gun_0') is not None, 'an unknown point name is refused')

    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        n = standing.selftest()
    ok(n == 0, 'the standing gate passes good output and fails each broken copy')
    if n:
        for line in buf.getvalue().splitlines():
            print('   ', line)

    print('PASS the hard point contract tables and standing gate behave' if not bad else f'FAIL {bad} case(s) did not behave')
    return 0 if not bad else 1


if __name__ == '__main__':
    sys.exit(main())
