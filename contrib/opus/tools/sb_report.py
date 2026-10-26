# Stream B: summarise sim outputs (fmatrix FM/FID lines, campaign, matrix, bossmatrix, archmatrix, fuzz, runsim, nemmatrix) from a folder,
# optionally against a 'before' folder. Usage: python3 contrib/opus/tools/sb_report.py AFTER_DIR [BEFORE_DIR]
import sys, os, json, re
F = ['voidsworn', 'hegemony', 'corsair', 'chorus', 'ithar', 'deathless']
def lines(d, name):
    p = os.path.join(d, name)
    if not os.path.exists(p): return []
    return [l.rstrip('\n') for l in open(p, encoding='utf8', errors='replace') if not l.startswith('[swarm')]
def fm(d):
    out = {}
    for l in lines(d, 'fm.txt'):
        if l.startswith('FM '): out['fm'] = json.loads(l[3:])
        if l.startswith('FID '): out['fid'] = json.loads(l[4:])
    return out
def show_fm(a, b):
    if 'fm' not in a: return
    A = a['fm']['out']; Bv = b.get('fm', {}).get('out') if b else None
    print('\n## fmatrix (row = player-side faction, % wins; avg; delta of avg vs before)')
    print('| | ' + ' | '.join(F) + ' | avg | before avg |'); print('|' + '---|' * (len(F) + 3))
    for pf in F:
        row = [A[pf][ef] for ef in F]; avg = sum(row) / len(row)
        bavg = sum(Bv[pf][ef] for ef in F) / len(F) if Bv else None
        print(f'| {pf} | ' + ' | '.join(str(x) for x in row) + f' | {avg:.0f} | ' + (f'{bavg:.0f}' if bavg is not None else '') + ' |')
    # column view: how often each faction wins as the enemy side
    print('\nAs the enemy side (100 minus column average): ' + ', '.join(f"{ef} {100 - sum(A[pf][ef] for pf in F) / len(F):.0f}" + (f" (was {100 - sum(Bv[pf][ef] for pf in F) / len(F):.0f})" if Bv else '') for ef in F))
    st = a['fm']['st']; print(f"rounds per battle {st['rounds'] / st['n']:.2f}" + (f" (was {b['fm']['st']['rounds'] / b['fm']['st']['n']:.2f})" if Bv else '') + f", timeouts {st['timeout']}")
    if 'fid' in a:
        print('\n## faction identity (FID): range = average firing distance; shield/cut/hull = share of incoming damage; regen per ship; loss rate; damage dealt per ship')
        keys = ['range', 'shieldPct', 'cutPct', 'hullPct', 'regenPerShip', 'lossPct', 'dealtPerShip']
        extra = sorted({k for f in a['fid'].values() for k in f if k not in keys})
        print('| faction | ' + ' | '.join(keys + extra) + ' |'); print('|' + '---|' * (len(keys) + len(extra) + 1))
        for f in F:
            x = a['fid'].get(f, {}); y = (b or {}).get('fid', {}).get(f, {})
            cell = lambda k: (str(x.get(k, '')) + (f' ({y[k]})' if k in y and y[k] != x.get(k) else ''))
            print(f'| {f} | ' + ' | '.join(cell(k) for k in keys + extra) + ' |')
def grab(d, name, pat):
    return [l for l in lines(d, name) if re.search(pat, l)]
def main():
    a = sys.argv[1]; b = sys.argv[2] if len(sys.argv) > 2 else None
    A = fm(a); Bf = fm(b) if b else {}
    show_fm(A, Bf)
    for name, pat, title in [('cp.txt', r'^sector \d', 'campaign (200 per cell)'), ('mx.txt', r'avg|per battle|void', 'skirmish matrix (50 per cell)'),
                             ('bm.txt', r'^bossmatrix|^by boss|^carrier', 'boss matrix'), ('am.txt', r'^archmatrix', 'archetypes'), ('fz.txt', r'^fuzz', 'fuzz'),
                             ('rs.txt', r'battles, won|reach', 'run sim'), ('nm.txt', r'^nemmatrix', 'nemesis matrix')]:
        la = grab(a, name, pat)
        if not la: continue
        print(f'\n## {title}'); print('after:'); [print('  ' + l) for l in la]
        if b:
            lb = grab(b, name, pat)
            if lb: print('before:'); [print('  ' + l) for l in lb]
main()
