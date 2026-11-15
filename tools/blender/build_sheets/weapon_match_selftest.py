# Self-test of the weapon-match check (weapon_match.py; issue 676, FINDINGS R241). Plain Python, no Blender: it builds small
# ship records the way weapon_match.collect() reads a built kit, proves a clean ship passes, then plants one fault per rule and
# proves the check names that rule. It also proves the table covers every weapon the sheet ships carry: each sheet's GAME
# line names its data.js ship, and every weapon of that ship has a row in weapon_match.FITS and a shot count in data.js.
# usage: python weapon_match_selftest.py      (prints one ok line per case, then PASS or FAIL; exit 0 when every case behaves)
import os, sys, re, copy, glob
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(REPO, 'tools', 'recipe'))
import weapon_match as WM
import gamedata


def muz(x, y, aim=(1.0, 0.0, 0.0), r=0.03):
    return dict(pos=(x, y, 1.0), aim=aim, radius=r, d_part=0.0, d_turn=0.0)


def turret(fid, weapon, letter, n=2, size=1.0, rest=None, typ='gun'):
    lo, hi = WM.ARCS[letter]
    rest = (lo + hi) / 2.0 if rest is None else rest
    return dict(id=fid, weapon=weapon, letter=letter, type=typ, mount='turret', barrels=n, size=size, rest_yaw=rest,
                muzzles=[muz(0.0, 0.1 * i) for i in range(n)], turret=dict(arc_lo=lo, arc_hi=hi, letter=letter, under=True))


def launcher(fid, weapon='torp', n=1):
    return dict(id=fid, weapon=weapon, letter='F', type='rack', mount='launcher', barrels=n, size=0.1 * n, rest_yaw=0.0,
                muzzles=[muz(3.0, 0.1 * i) for i in range(n)], turret=None)


def clean():
    """a small ship as data.js c_marauder: scatter P, scatter S, torp F, flak T; two twin turrets a broadside, one rack"""
    weapons = [('scatter', 'P'), ('scatter', 'S'), ('torp', 'F'), ('flak', 'T')]
    stats = {w: gamedata.weapon_stats(w) for w, _ in weapons}
    mounts = [turret('P1', 'scatter', 'P'), turret('P2', 'scatter', 'P'), turret('S1', 'scatter', 'S'), turret('S2', 'scatter', 'S'),
              launcher('R1'), turret('T1', 'flak', 'T')]
    parts = [dict(id=m['id'], kind='launcher' if m['mount'] == 'launcher' else 'gun', type=m['type']) for m in mounts]
    parts += [dict(id='I1', kind='tube', type='tube'), dict(id='D1', kind='dish', type='dish')]   # a scoop and a dish: no weapons
    return dict(code='TEST', weapons=weapons, stats=stats, parts=parts, mounts=mounts)


def m_of(ship, fid):
    return next(m for m in ship['mounts'] if m['id'] == fid)


def plant_extra(s):
    s['parts'].append(dict(id='X1', kind='gun', type='gun'))                       # a decorative gun with no slot


def plant_extra_organ(s):
    s['parts'].append(dict(id='X2', kind='organ', type='spore'))


def plant_tie_no_mesh(s):
    m_of(s, 'R1')['muzzles'][0]['d_part'] = None


def plant_tie_nan(s):
    m_of(s, 'R1')['muzzles'][0]['d_part'] = float('nan')


def plant_count_missing(s):
    s['mounts'] = [m for m in s['mounts'] if m['id'] != 'T1']; s['parts'] = [p for p in s['parts'] if p['id'] != 'T1']


def plant_count_wrong_slot(s):
    m_of(s, 'T1')['weapon'] = 'gauss'                                             # a weapon the ship does not carry


def plant_kind(s):
    m = m_of(s, 'R1'); m['type'] = 'gun'; m['mount'] = 'casemate'                 # torp shown as a gun casemate


def plant_tie(s):
    m_of(s, 'P1')['muzzles'][0]['d_part'] = 0.6                                   # the hard point floats off the barrel


def plant_tie_none(s):
    m_of(s, 'R1')['muzzles'] = []


def plant_arc_fixed(s):
    m_of(s, 'R1')['muzzles'][0]['aim'] = (0.0, 1.0, 0.0)                          # a forward launcher aiming to port


def plant_arc_rest(s):
    m_of(s, 'S1')['rest_yaw'] = 20.0                                              # a starboard turret resting off the bow


def plant_arc_turn(s):
    m_of(s, 'P2')['turret']['arc_lo'] = -60.0                                     # the turret node turns through the wrong arc


def plant_turret_under(s):
    m_of(s, 'T1')['turret']['under'] = False                                      # barrels not parented to the turret node


def plant_turret_muzzle(s):
    m_of(s, 'T1')['muzzles'][1]['d_turn'] = 0.5                                   # a muzzle on the base, not the turning part


def plant_turret_none(s):
    m_of(s, 'T1')['turret'] = None


def plant_turret_casemate(s):
    m = m_of(s, 'T1'); m['mount'] = 'casemate'; m['turret'] = None                # all-round flak in a fixed casemate


def plant_same_type(s):
    m = m_of(s, 'P2'); m['mount'] = 'casemate'; m['turret'] = None                # one turret and one casemate on a slot


def plant_same_barrels(s):
    p = m_of(s, 'S2'); p['barrels'] = 1; p['muzzles'] = p['muzzles'][:1]          # a twin beside a single on one slot


def plant_same_size(s):
    m_of(s, 'P2')['size'] = 1.6                                                   # one slot's turrets of very different sizes


def plant_split(s):
    s['mounts'].append(turret('P3', 'scatter', 'P', n=2)); s['mounts'].append(turret('P4', 'scatter', 'P', n=2))
    s['parts'] += [dict(id='P3', kind='gun', type='gun'), dict(id='P4', kind='gun', type='gun')]   # 8 muzzles for 5 shots


def plant_split_launchers(s):
    s['mounts'].append(launcher('R2')); s['parts'].append(dict(id='R2', kind='launcher', type='rack'))   # two racks, 1 torp shot


def craft(kind):
    """a squadron craft as data.js fighter (guns T: one three-barrel turret) or bomber (bombs T: one two-tube bomb cassette)"""
    if kind == 'fighter':
        weapons = [('guns', 'T')]
        m = turret('G1', 'guns', 'T', n=3, rest=0.0)
    else:
        weapons = [('bombs', 'T')]
        m = dict(id='BT', weapon='bombs', letter='T', type='bomb_tube', mount='launcher', barrels=2, size=0.2, rest_yaw=0.0,
                 muzzles=[muz(1.0, 0.1 * i) for i in range(2)], turret=None)
    stats = {w: gamedata.weapon_stats(w) for w, _ in weapons}
    parts = [dict(id=m['id'], kind='launcher' if m['mount'] == 'launcher' else 'gun', type=m['type'])]
    return dict(code=kind.upper(), weapons=weapons, stats=stats, parts=parts, mounts=[m])


def plant_craft_bombs_turret(s):
    m = s['mounts'][0]; lo, hi = WM.ARCS['T']
    m.update(type='gun', mount='turret', turret=dict(arc_lo=lo, arc_hi=hi, letter='T', under=True))   # bombs shown as a gun turret
    s['parts'][0].update(kind='gun', type='gun')


def plant_craft_guns_casemate(s):
    m = s['mounts'][0]; m['mount'] = 'casemate'; m['turret'] = None                # the fighter's all-round guns fixed in a casemate


def plant_craft_guns_cassette(s):
    m = s['mounts'][0]; m.update(type='bomb_tube', mount='launcher', turret=None)  # the fighter's guns shown as bomb tubes
    s['parts'][0].update(kind='launcher', type='bomb_tube')


def plant_craft_extra_tube(s):
    s['parts'].append(dict(id='BX', kind='launcher', type='bomb_tube'))            # a second, silent bomb cassette


CRAFT_CASES = [
    ('KIND', 'bomber', 'a bomber\'s bombs shown as a gun turret', plant_craft_bombs_turret),
    ('TURRET', 'fighter', 'a fighter\'s all-round guns in a fixed casemate', plant_craft_guns_casemate),
    ('KIND', 'fighter', 'a fighter\'s guns shown as bomb tubes', plant_craft_guns_cassette),
    ('EXTRA', 'bomber', 'a second bomb cassette with no slot', plant_craft_extra_tube),
]


CASES = [
    ('EXTRA', 'a decorative gun on no slot', plant_extra),
    ('EXTRA', 'a decorative spore organ on no slot', plant_extra_organ),
    ('COUNT', 'a data.js slot with no mount', plant_count_missing),
    ('COUNT', 'a mount for a weapon the ship does not carry', plant_count_wrong_slot),
    ('KIND', 'a torpedo slot shown as a gun casemate', plant_kind),
    ('TIE', 'a muzzle off its mount\'s mesh', plant_tie),
    ('TIE', 'a mount with no muzzle', plant_tie_none),
    ('TIE', 'a muzzle with no weapon mesh measurement', plant_tie_no_mesh),
    ('TIE', 'a non-finite weapon mesh measurement', plant_tie_nan),
    ('ARC', 'a fixed launcher aiming outside its arc', plant_arc_fixed),
    ('ARC', 'a turret resting outside its arc', plant_arc_rest),
    ('ARC', 'a turret node turning through the wrong arc', plant_arc_turn),
    ('TURRET', 'turning pieces not under the turret node', plant_turret_under),
    ('TURRET', 'a turret muzzle off its turning mesh', plant_turret_muzzle),
    ('TURRET', 'a turning mount with no turret node', plant_turret_none),
    ('TURRET', 'an all-round weapon in a fixed casemate', plant_turret_casemate),
    ('SAME', 'a turret and a casemate on one slot', plant_same_type),
    ('SAME', 'a twin and a single on one slot', plant_same_barrels),
    ('SAME', 'mounts of very different size on one slot', plant_same_size),
    ('SPLIT', 'more muzzles than shots, so a mount sits out a volley', plant_split),
    ('SPLIT', 'two launchers for a one-shot torpedo slot', plant_split_launchers),
]


def trench(fid, weapon='ion', letter='F'):
    """the Hegemony ion cannon as the kit builds it: an emitter trench in the bow face, fixed, its muzzle on the lens (issue 759)"""
    return dict(id=fid, weapon=weapon, letter=letter, type='ion_trench', mount='fixed', barrels=1, size=1.3, rest_yaw=0.0,
                muzzles=[muz(2.0, 0.0)], turret=None)


def clean_heg():
    """a Hegemony ship as data.js h_boss: hturbo P, hturbo S, turbo T, ion F, flak T (issue 768, hegemony_IM5)"""
    weapons = [('hturbo', 'P'), ('hturbo', 'S'), ('turbo', 'T'), ('ion', 'F'), ('flak', 'T')]
    stats = {w: gamedata.weapon_stats(w) for w, _ in weapons}
    mounts = [turret('HP', 'hturbo', 'P'), turret('HS', 'hturbo', 'S'), turret('T1', 'turbo', 'T'), trench('I1'), turret('F1', 'flak', 'T')]
    parts = [dict(id=m['id'], kind='spinal' if m['mount'] == 'fixed' else 'gun', type=m['type']) for m in mounts]
    return dict(code='TESTH', weapons=weapons, stats=stats, parts=parts, mounts=mounts)


def plant_ion_turret(s):
    s['mounts'] = [m for m in s['mounts'] if m['id'] != 'I1'] + [turret('I1', 'ion', 'F', n=1)]
    s['parts'] = [p for p in s['parts'] if p['id'] != 'I1'] + [dict(id='I1', kind='gun', type='gun')]


def plant_hturbo_trench(s):
    s['mounts'] = [m for m in s['mounts'] if m['id'] != 'HP'] + [trench('HP', 'hturbo', 'P')]
    m_of(s, 'HP')['rest_yaw'] = 90.0; m_of(s, 'HP')['muzzles'][0]['aim'] = (0.0, 1.0, 0.0)
    s['parts'] = [p for p in s['parts'] if p['id'] != 'HP'] + [dict(id='HP', kind='spinal', type='ion_trench')]


def plant_hturbo_trench_turning(s):
    m = m_of(s, 'HP'); m['type'] = 'ion_trench'
    next(p for p in s['parts'] if p['id'] == 'HP')['type'] = 'ion_trench'


def plant_ion_turning(s):
    m = m_of(s, 'I1'); lo, hi = WM.ARCS['F']
    m['mount'] = 'turret'; m['turret'] = dict(arc_lo=lo, arc_hi=hi, letter='F', under=True)   # the trench itself on a turning mount


def plant_turbo_trench(s):
    s['mounts'] = [m for m in s['mounts'] if m['id'] != 'T1'] + [trench('T1', 'turbo', 'T')]
    s['parts'] = [p for p in s['parts'] if p['id'] != 'T1'] + [dict(id='T1', kind='spinal', type='ion_trench')]


# the Hegemony rows of FITS (issues 759 and 768; Muse opus_check_767 condition 2): each row refuses the wrong build
HEG_CASES = [
    ('KIND', 'an ion cannon built as a turning gun turret', plant_ion_turret),
    ('KIND', 'a heavy plasma lance built as a fixed emitter trench', plant_hturbo_trench),
    ('KIND', 'a heavy plasma lance trench on a turning mount', plant_hturbo_trench_turning),
    ('KIND', 'an ion emitter trench on a turning mount', plant_ion_turning),
    ('KIND', 'a plasma lance built as a fixed emitter trench', plant_turbo_trench),
]


def spinal(fid, weapon='nlance', letter='F'):
    """the Eclipse null lance as a fixed forward gun: one bore firing over the bow (issue 784; the E14 sheet is issue 782)"""
    return dict(id=fid, weapon=weapon, letter=letter, type='nullcannon', mount='fixed', barrels=1, size=1.0, rest_yaw=0.0,
                muzzles=[muz(2.0, 0.0)], turret=None)


def clean_flare():
    """an Eclipse ship as data.js d_jackal after issue 784: one null lance, F, nothing else"""
    weapons = [('nlance', 'F')]
    stats = {w: gamedata.weapon_stats(w) for w, _ in weapons}
    mounts = [spinal('L1')]
    parts = [dict(id='L1', kind='spinal', type='nullcannon')]
    return dict(code='TESTE', weapons=weapons, stats=stats, parts=parts, mounts=mounts)


def plant_lance_turret(s):
    s['mounts'] = [turret('L1', 'nlance', 'F', n=1, typ='nullcannon')]
    s['parts'] = [dict(id='L1', kind='turret', type='nullcannon')]


def plant_flare_old_turret(s):
    s['mounts'].append(turret('T1', 'gauss', 'T', typ='nullcannon'))               # the old aft null cannon left on the ship
    s['parts'].append(dict(id='T1', kind='turret', type='nullcannon'))


def plant_lance_abeam(s):
    s['mounts'][0]['muzzles'] = [muz(2.0, 0.0, aim=(0.0, 1.0, 0.0))]                # the fixed lance laid along the beam (issue 782)


# the Eclipse flare row of FITS (issue 784): the null lance is fixed, and the old turret is no slot any more
FLARE_CASES = [
    ('KIND', 'a null lance built on a turning turret', plant_lance_turret),
    ('COUNT', 'the old aft null cannon turret kept on the flare', plant_flare_old_turret),
    ('ARC', 'the fixed null lance aimed along the beam', plant_lance_abeam),
]

def sheet_games():
    """(code, data.js ship id) for every sheet ship design file"""
    out = []
    for f in sorted(glob.glob(os.path.join(HERE, 'ships', '*.py'))):
        if f.endswith('_inv.py') or os.path.basename(f).startswith('_'):
            continue
        src = open(f, encoding='utf-8').read()
        m = re.search(r'^GAME\s*=\s*["\'].*?data\.js\s+([A-Za-z0-9_]+)', src, re.M)
        if m:
            out.append((os.path.basename(f)[:-3], m.group(1)))
    return out


def main():
    bad = []
    probs = WM.check(clean())
    if probs:
        bad.append('the clean ship fails: ' + '; '.join(probs))
    else:
        print('ok   clean ship (two twin turrets a broadside, one rack, one flak turret, a scoop and a dish): PASS')
    for rule, what, plant in CASES:
        s = clean(); plant(s)
        probs = WM.check(s)
        hits = [p for p in probs if p.startswith(rule + ' ')]
        if not hits:
            bad.append(f'{rule} not raised for {what}: got {probs}')
        else:
            print(f'ok   {rule:<6} {what}: {hits[0][:110]}')
    # squadron craft (issue 769): a clean fighter and bomber pass; each planted craft fault is named by its rule
    for kind in ('fighter', 'bomber'):
        probs = WM.check(craft(kind))
        if probs:
            bad.append(f'the clean {kind} fails: ' + '; '.join(probs))
        else:
            print(f'ok   clean {kind} (data.js {kind}: ' + ('one three-barrel guns turret' if kind == 'fighter' else 'one two-tube bomb cassette') + '): PASS')
    for rule, kind, what, plant in CRAFT_CASES:
        s_ = craft(kind); plant(s_)
        probs = WM.check(s_)
        hits = [p for p in probs if p.startswith(rule + ' ')]
        if not hits:
            bad.append(f'{rule} not raised for {what}: got {probs}')
        else:
            print(f'ok   {rule:<6} {what}: {hits[0][:110]}')
    probs = WM.check(clean_heg())
    if probs:
        bad.append('the clean Hegemony ship fails: ' + '; '.join(probs))
    else:
        print('ok   clean Hegemony ship (h_boss: two shoulder lances, a bridge lance, the ion trench, a picket turret): PASS')
    for rule, what, plant in HEG_CASES:
        s = clean_heg(); plant(s)
        probs = WM.check(s)
        hits = [p for p in probs if p.startswith(rule + ' ')]
        if not hits:
            bad.append(f'{rule} not raised for {what}: got {probs}')
        else:
            print(f'ok   {rule:<6} {what}: {hits[0][:110]}')
    probs = WM.check(clean_flare())
    if probs:
        bad.append('the clean Eclipse flare fails: ' + '; '.join(probs))
    else:
        print('ok   clean Eclipse flare (d_jackal: one fixed null lance firing forward): PASS')
    for rule, what, plant in FLARE_CASES:
        s = clean_flare(); plant(s)
        probs = WM.check(s)
        hits = [p for p in probs if p.startswith(rule + ' ')]
        if not hits:
            bad.append(f'{rule} not raised for {what}: got {probs}')
        else:
            print(f'ok   {rule:<6} {what}: {hits[0][:110]}')
    # the game's muzzle rotation (fx_hull.gd guns()): 5 shots over 6 muzzles of 3 twin mounts reaches every mount every volley
    # issue 812: the turreted zenith's T arc needs a real turning projector; accepting its part type alone is insufficient.
    arc = dict(code='E12_variant', weapons=[['doom', 'T']], stats={'doom': gamedata.weapon_stats('doom')},
               mounts=[turret('A1', 'doom', 'T', n=1, typ='corona_arc')],
               parts=[dict(id='A1', kind='gun', type='corona_arc')])
    if WM.check(arc):
        bad.append('the clean turning corona arc fails: ' + '; '.join(WM.check(arc)))
    arc['mounts'][0]['mount'] = 'fixed'
    arc['mounts'][0]['turret'] = None
    if not any(p.startswith('KIND ') for p in WM.check(arc)):
        bad.append('the turreted zenith accepts a fixed corona arc')
    else:
        print('ok   KIND   the turreted zenith refuses a fixed corona arc')

    v = WM.volleys(['a', 'a', 'b', 'b', 'c', 'c'], 5)
    if len(v) != 6 or any(x != {'a', 'b', 'c'} for x in v):
        bad.append(f'volleys() wrong for 5 shots over 3 twins: {v}')
    else:
        print('ok   volleys: 5 shots over 3 twin mounts fire every mount on all 6 offsets')
    # the table covers every weapon on every sheet ship, and data.js gives each a shot count
    games = sheet_games()
    if len(games) < 9:
        bad.append(f'only {len(games)} sheet ships found with a GAME line')
    for code, game in games:
        for wk, arc in gamedata.weapons(game):
            if wk not in WM.FITS:
                bad.append(f'{code} ({game}): weapon {wk} has no row in weapon_match.FITS')
            st = gamedata.weapon_stats(wk)
            if int(st.get('shots', 0)) < 1:
                bad.append(f'{code} ({game}): weapon {wk} has no shot count in data.js')
            if arc not in WM.ARCS:
                bad.append(f'{code} ({game}): arc {arc} unknown')
    print(f'ok   table: {len(games)} sheet ships, every data.js weapon has a FITS row and a shot count' if not any('FITS' in b or 'shot' in b for b in bad) else 'FAIL table')
    for b in bad:
        print('  ' + b)
    print(('FAIL' if bad else 'PASS') + f' weapon match self-test ({len(CASES) + len(CRAFT_CASES) + len(HEG_CASES) + len(FLARE_CASES) + 1} planted faults, {len(games)} sheet ships in the table)')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
