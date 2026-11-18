"""Check run coverage, assemble the final CSV, and print Markdown tables."""

import argparse
import csv
import json
import math
from collections import defaultdict
from pathlib import Path
from statistics import mean, median, stdev


SETUPS = ('today', 'shapes', 'placement', 'tempo', 'all')
LABELS = ('Today', 'Shapes', 'Shapes + placement', 'Shapes + x1.25', 'All three')
ENCOUNTERS = ('rout', 'ambush', 'defend', 'hunt', 'intercept', 'break', 'hold', 'flagship',
              'boss1_rout', 'boss1_ambush', 'boss2_rout', 'boss2_ambush', 'boss3_rout', 'boss3_ambush')
FACTIONS = ('hegemony', 'voidsworn', 'corsair', 'chorus', 'ithar', 'deathless')
FACTION_SETUPS = ('today', 'all', 'tempo', 'recommended')
FIXED_ENCOUNTERS = ('ambush', 'hunt', *ENCOUNTERS[8:])
PAIR_INPUTS = ('requested_map', 'deployment', 'enemy_faction', 'sector', 'player_cp', 'enemy_cp')
SHAPE_INPUTS = ('requested_shape', 'shape', 'arena', 'map', 'approach')


def read(path):
    with path.open(newline='', encoding='utf-8') as src:
        return list(csv.DictReader(src))


def numbers(rows, key):
    return [float(row[key]) for row in rows if row[key] != '']


def ratio(rows, count, total):
    return sum(numbers(rows, count)) / sum(numbers(rows, total))


def percent(rows, key):
    return f'{mean(numbers(rows, key)):.0%}' if numbers(rows, key) else '-'


def spread(rows, key):
    values = numbers(rows, key)
    return f'{median(values):g} [{min(values):g}-{max(values):g}]' if values else '-'


def group(rows, *keys):
    out = defaultdict(list)
    for row in rows:
        out[tuple(row[key] for key in keys)].append(row)
    return out


def assert_pairs(groups, keys, sims, seed):
    assert set(groups) == set(keys), f'Wrong comparison cells: {set(groups) ^ set(keys)}'
    expected = list(range(seed, seed + sims))
    for key, rows in groups.items():
        assert sorted(int(r['seed']) for r in rows) == expected, f'Missing or repeated seeds in {key}'
    return groups


def assert_inputs(base, after, keys):
    paired = {row['seed']: row for row in base}
    for row in after:
        before = paired[row['seed']]
        assert all(row[key] == before[key] for key in keys), (row['encounter'], row['setup'], before, row)


def select_hunt(rows, tuning, columns, sims, seed):
    tuning_keys = tuple(tuning[0])
    variants = [tuple(str(setting[key]) for key in tuning_keys) for setting in tuning]
    assert len(set(variants)) == len(variants) == 5, 'Expected the pick and four distinct neighbors'
    groups = group(rows, *tuning_keys, 'setup')
    setups = ('hunt_placement', 'hunt_all')
    assert_pairs(groups, [(*key, setup) for key in variants for setup in setups], sims, seed)
    print(f'Hunt tuning ({", ".join(tuning_keys)})')
    for key in variants:
        placement, full = (groups[(*key, setup)] for setup in setups)
        assert_inputs(placement, full, PAIR_INPUTS + SHAPE_INPUTS)
        print(key)
        for arm in (placement, full):
            median_rounds = [median(numbers(arm, metric)) for metric in
                             ('first_shot_round', 'capital_contact_round', 'first_target_shot_round')]
            capital = numbers(arm, 'capital_contact_round')
            print(f'  {arm[0]["setup"]}: {percent(arm, "escaped")} escape, {median_rounds} median rounds '
                  f'(gun / hull contact / quarry fire), {sum(3 <= r <= 4 for r in capital)}/{sims} hull contact in R3-4')
    selected = [row for setup in setups for row in groups[(*variants[0], setup)]]
    return [{key: row[key] for key in columns} for row in selected]


def recommended_setup(encounter):
    if encounter == 'hunt':
        return 'hunt_all'
    return 'recommended' if encounter in FIXED_ENCOUNTERS else 'tempo'


def encounter_tables(encounters):
    print('\n| Encounter | First gun act | Hexes per move | Move only | Player win / quarry kill |')
    print('|---|---:|---:|---:|---:|')
    for enc in ENCOUNTERS:
        base, pick = (encounters[enc, setup] for setup in ('today', recommended_setup(enc)))
        win = 'quarry_kill' if enc == 'hunt' else 'win'
        results = [(f'{median(numbers(arm, "first_shot_act")):g}', f'{ratio(arm, "move_hexes", "move_actions"):.2f}',
                    f'{ratio(arm, "move_only", "acts"):.1%}', percent(arm, win)) for arm in (base, pick)]
        print(f'| {enc} | ' + ' | '.join(f'{b} -> {a}' for b, a in zip(*results)) + ' |')

    print()
    print('| Encounter | Setup | First gun act | First gun round | Rounds | Move only | Hex / move action | Win | Escape | Cap |')
    print('|---|---|---:|---:|---:|---:|---:|---:|---:|---:|')
    for enc in ENCOUNTERS:
        cases = list(zip(SETUPS, LABELS))
        if enc == 'hunt':
            cases.append(('hunt_placement', 'Shapes + retuned Hunt'))
        if enc in FIXED_ENCOUNTERS:
            cases.append((recommended_setup(enc), 'Recommended'))
        for setup, label in cases:
            rows = encounters[enc, setup]
            acts = numbers(rows, 'first_shot_act')
            rounds = numbers(rows, 'first_shot_round')
            first = f'{median(acts):g}' if acts else '-'
            first_round = f'{median(rounds):g}' if rounds else '-'
            if len(acts) < len(rows):
                first += f' ({len(acts)}/{len(rows)})'
            length = mean(numbers(rows, 'rounds'))
            move = ratio(rows, 'move_only', 'acts')
            distance = ratio(rows, 'move_hexes', 'move_actions')
            caps = int(sum(numbers(rows, 'timeout')))
            print(f'| {enc} | {label} | {first} | {first_round} | {length:.1f} | {move:.1%} | '
                  f'{distance:.2f} | {percent(rows, "win")} | {percent(rows, "escaped")} | {caps} |')

    print('\n| Encounter | Goal gap today | Goal gap fixed | Line gap today | Line gap fixed | '
          'Opening gun today P/E | Opening gun fixed P/E |')
    print('|---|---:|---:|---:|---:|---:|---:|')
    for enc in ENCOUNTERS:
        base, fixed = (encounters[enc, setup] for setup in ('today', 'placement'))
        gaps = [spread(rows, metric) for metric in ('objective_gap', 'line_gap') for rows in (base, fixed)]
        odds = [f'{percent(rows, "player_open_shot")} / {percent(rows, "enemy_open_shot")}' for rows in (base, fixed)]
        print('| ' + ' | '.join([enc, *gaps, *odds]) + ' |')

    print('\nHunt details')
    for setup in (*SETUPS, 'hunt_placement', 'hunt_all'):
        rows = encounters['hunt', setup]
        target = numbers(rows, 'first_target_shot_round')
        counts = {round_: target.count(round_) for round_ in sorted(set(target))}
        contact = numbers(rows, 'first_shot_round')
        print(setup, 'kill', percent(rows, 'quarry_kill'), 'target shot round counts', counts,
              'no target shot', len(rows) - len(target), 'first gun R3-4', sum(3 <= r <= 4 for r in contact),
              'screen bounds', spread(rows, 'hunt_screen_min'), spread(rows, 'hunt_screen_max'))


def faction_table(factions, setup):
    print(f'\n| Player | Enemy | Today | {setup} | Change | Paired wins up/down | Approx. 95% range |')
    print('|---|---|---:|---:|---:|---:|---:|')
    flagged = 0
    for pf in FACTIONS:
        for ef in FACTIONS:
            base = factions[pf, ef, 'today']
            after = factions[pf, ef, setup]
            order = lambda r: r['seed']
            first, second = (sorted(rows, key=order) for rows in (base, after))
            change = [int(b['win']) - int(a['win']) for a, b in zip(first, second)]
            points = 100 * sum(change) / len(change)
            if abs(points) <= 10:
                continue
            flagged += 1
            margin = 1.96 * 100 * stdev(change) / math.sqrt(len(change))
            print(f'| {pf} | {ef} | {percent(base, "win")} | {percent(after, "win")} | {points:+g} pp | '
                  f'{change.count(1)} / {change.count(-1)} | {points - margin:+.0f} to {points + margin:+.0f} pp |')
    print(f'\n{flagged} of {len(FACTIONS)**2} seatings above 10 points')


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--base', type=Path, required=True, help='Combined run 1 CSV')
    cli.add_argument('--encounters', type=Path, required=True, help='Follow-up boss and ambush encounters')
    cli.add_argument('--factions', type=Path, action='append', required=True, help='Follow-up faction data')
    cli.add_argument('--hunt', type=Path, required=True, help='Paired Hunt tuning data')
    cli.add_argument('--hunt-settings', type=Path, default=Path(__file__).with_name('hunt_settings.json'))
    cli.add_argument('--out', type=Path, required=True)
    cli.add_argument('--pictures', type=Path, required=True)
    cli.add_argument('--sims', default=100, type=int)
    cli.add_argument('--seed', default=1000, type=int)
    opt = cli.parse_args()
    base = read(opt.base)
    results = [r for r in base if r['group'] == 'encounter'] + read(opt.encounters)
    tuning = json.loads(opt.hunt_settings.read_text(encoding='utf-8'))
    hunt = select_hunt(read(opt.hunt), tuning, list(base[0]), opt.sims, opt.seed)
    results.extend(hunt)
    matchup = [r for r in base if r['group'] == 'faction']
    for path in opt.factions:
        matchup.extend(read(path))
    # The faction mix has only ordinary encounters. The two follow-up starts
    # differ from tempo solely in Hunt and Ambush, so their other seeds are shared.
    def pairing(row):
        return row['player_faction'], row['enemy_faction'], row['seed']

    simulated = {pairing(row) for row in matchup if row['setup'] == 'recommended'}
    shared = [dict(row, setup='recommended') for row in matchup if row['setup'] == 'tempo' and
              row['encounter'] not in FIXED_ENCOUNTERS and pairing(row) not in simulated]
    matchup.extend(shared)
    print(f'{len(shared)} faction battles shared with tempo')
    enc = assert_pairs(group(results, 'encounter', 'setup'),
                       [(e, s) for e in ENCOUNTERS for s in SETUPS] +
                       [(e, 'recommended') for e in FIXED_ENCOUNTERS if e != 'hunt'] +
                       [('hunt', 'hunt_placement'), ('hunt', 'hunt_all')], opt.sims, opt.seed)
    fac = assert_pairs(group(matchup, 'player_faction', 'enemy_faction', 'setup'),
                       [(p, e, s) for p in FACTIONS for e in FACTIONS for s in FACTION_SETUPS],
                       opt.sims, opt.seed)
    assert set(r['player_cp'] for r in matchup) == {'16'}
    assert all(int(r['enemy_cp']) >= 16 and (r['enemy_cp'] == '16' or r['encounter'] == 'intercept') for r in matchup)
    for (pf, ef, setup), rows in fac.items():
        assert_inputs(fac[pf, ef, 'today'], rows, PAIR_INPUTS + ('encounter',))
        if setup != 'today':
            assert_inputs(fac[pf, ef, 'tempo'], rows, SHAPE_INPUTS)
        if setup == 'recommended':
            unchanged = [r for r in rows if r['encounter'] not in FIXED_ENCOUNTERS]
            assert_inputs(fac[pf, ef, 'tempo'], unchanged, tuple(k for k in rows[0] if k != 'setup'))
    for (encounter, setup), rows in enc.items():
        assert_inputs(enc[encounter, 'today'], rows, PAIR_INPUTS)
        if setup != 'today':
            assert_inputs(enc[encounter, 'shapes'], rows, SHAPE_INPUTS)
    seeds = {}
    for e in ENCOUNTERS:
        today = {r['seed']:r for r in enc[e, 'today']}
        after = enc[e, 'hunt_all' if e == 'hunt' else 'all']
        gap = median(numbers(after, 'objective_gap'))
        old_gap = median(numbers(enc[e, 'today'], 'objective_gap'))
        ranked = sorted(after, key=lambda r: (
            r['shape'] == today[r['seed']]['shape'] and r['objective_gap'] == today[r['seed']]['objective_gap'],
            abs(float(r['objective_gap']) - gap) + abs(float(today[r['seed']]['objective_gap']) - old_gap),
            int(r['seed'])))
        if e == 'hunt':
            ranked.sort(key=lambda r: r['first_target_shot_round'] not in ('3', '4'))
        seeds[e] = int(ranked[0]['seed'])
    with opt.out.open('x', newline='', encoding='utf-8') as dest:
        writer = csv.DictWriter(dest, fieldnames=list(results[0]), lineterminator='\n')
        writer.writeheader()
        writer.writerows(results + matchup)
    with opt.pictures.open('x', encoding='utf-8') as dest:
        json.dump(seeds, dest)
    encounter_tables(enc)
    for setup in FACTION_SETUPS[2:]:
        faction_table(fac, setup)


if __name__ == '__main__':
    main()
