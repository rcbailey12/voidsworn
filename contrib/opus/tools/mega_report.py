# Turn the mega sim's raw logs (contrib/opus/compute/raw/*.txt) into CSVs plus balance_reference.md.
# usage: python3 contrib/opus/tools/mega_report.py
import os, re, json, csv
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
RAW = os.path.join(ROOT, 'contrib', 'opus', 'compute', 'raw'); OUT = os.path.join(ROOT, 'contrib', 'opus', 'compute')
F = ['voidsworn', 'hegemony', 'corsair', 'chorus', 'ithar', 'deathless']
def lines(name):
    p = os.path.join(RAW, name + '.txt')
    return [l.rstrip('\n') for l in open(p, encoding='utf-8', errors='replace') if not l.startswith('[swarm]')] if os.path.exists(p) else []
def wcsv(name, head, rows):
    with open(os.path.join(OUT, name), 'w', newline='') as fh: w = csv.writer(fh); w.writerow(head); w.writerows(rows)
md = []
legs = open(os.path.join(RAW, 'legs.log')).read() if os.path.exists(os.path.join(RAW, 'legs.log')) else ''
# ---- campaign ----
camp = []
for l in lines('campaign'):
    m = re.match(r'sector (\d) (\S+)\s+win (\d+)%\s+rounds ([\d.]+)\s+hull left (\d+)%\s+ships lost ([\d.]+)\s+timeouts (\d+)\s+wait old (\d+)s new (\d+)s', l)
    if m: camp.append(m.groups())
wcsv('campaign.csv', ['sector', 'kind', 'win_pct', 'rounds', 'hull_left_pct', 'ships_lost', 'timeouts', 'wait_old_s', 'wait_new_s'], camp)
# ---- fmatrix ----
fm = None
for l in lines('fmatrix'):
    if l.startswith('FM '): fm = json.loads(l[3:])
if fm:
    wcsv('fmatrix_winrates.csv', ['player_faction'] + ['vs_' + e for e in F], [[p] + [fm['out'][p].get(e, '') for e in F] for p in F])
    wcsv('fmatrix_hulls.csv', ['hull', 'cp', 'fielded', 'damage_dealt', 'deaths', 'damage_per_fielding', 'death_rate'],
         [[h, v['cp'], v['n'], v['dealt'], v['died'], round(v['dealt'] / v['n'], 1), round(v['died'] / v['n'], 3)] for h, v in fm['hull'].items()])
    wcsv('fmatrix_weapons.csv', ['weapon', 'damage', 'shots', 'damage_per_shot'], [[k, round(v['dmg']), v['shots'], round(v['dmg'] / max(1, v['shots']), 2)] for k, v in fm['weap'].items()])
# ---- bossmatrix (one file per sector) ----
boss = []; byboss = []; carr = []
for name in ('bossmatrix', 'bossmatrix_s2', 'bossmatrix_s3'):
    for l in lines(name):
        m = re.match(r'bossmatrix s(\d) (\{.*\})', l)
        if m:
            sec = m.group(1); cur = sec
            for adm, v in json.loads(m.group(2)).items():
                mm = re.match(r'(\d+)% r([\d.]+)( \(carrier\))?', v); boss.append([sec, adm, mm.group(1), mm.group(2), 'yes' if mm.group(3) else 'no'])
        m = re.match(r'by boss (\{.*\})', l)
        if m: byboss += [[cur, k, v.rstrip('%')] for k, v in json.loads(m.group(1)).items()]
        m = re.match(r'carrier fleets (\d+)% gun fleets (\d+)%', l)
        if m: carr.append([cur, m.group(1), m.group(2)])
wcsv('bossmatrix_admirals.csv', ['sector', 'admiral', 'win_pct', 'rounds', 'carrier_fleet'], boss)
wcsv('bossmatrix_by_boss.csv', ['sector', 'boss_faction', 'player_win_pct'], byboss)
# ---- archmatrix ----
arch = []
for l in lines('archmatrix'):
    m = re.match(r'archmatrix s(\d) col(\d) (\{.*\})', l)
    if m:
        for k, v in json.loads(m.group(3)).items():
            mm = re.match(r'(\d+)% r([\d.]+) ships ([\d.]+)', v); arch.append([m.group(1), m.group(2), k, *mm.groups()])
wcsv('archmatrix.csv', ['sector', 'column', 'enemy_archetype', 'win_pct', 'rounds', 'ships_left'], arch)
# ---- matrix (skirmish table) ----
mat = []; hdr = None
for l in lines('matrix'):
    t = l.split()
    if t[:6] == ['void', 'hege', 'cors', 'chor', 'itha', 'deat']: hdr = t; continue
    if hdr and len(t) >= 7 and t[0][:4] in ('void', 'hege', 'cors', 'chor', 'itha', 'deat'): mat.append(t[:7])
wcsv('matrix_skirmish.csv', ['row'] + (hdr or []), mat)
# ---- fuzz ----
fz = [l for l in lines('fuzz') if l.strip()]
open(os.path.join(OUT, 'fuzz_summary.txt'), 'w').write('\n'.join(fz[-20:]) + '\n')
print('campaign', len(camp), 'fm', bool(fm), 'boss', len(boss), 'arch', len(arch), 'matrix', len(mat), 'fuzz lines', len(fz))
