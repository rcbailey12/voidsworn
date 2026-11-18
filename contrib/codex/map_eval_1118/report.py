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


def update(rows, paths):
    def key(r):
        return tuple(r[k] for k in ('encounter', 'setup', 'seed', 'player_faction', 'enemy_faction'))
    results = {key(r):r for r in rows}
    assert len(results) == len(rows), 'Repeated rows'
    for path in paths:
        for row in read(path):
            assert key(row) in results, f'Unexpected replacement row in {path}'
            results[key(row)] = row
    return list(results.values())


def encounter_tables(encounters):
    print('| Encounter | Setup | First gun act | First gun round | Rounds | Move only | Hex / move action | Win | Escape | Cap |')
    print('|---|---|---:|---:|---:|---:|---:|---:|---:|---:|')
    for enc in ENCOUNTERS:
        for setup, label in zip(SETUPS, LABELS):
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
    for setup in SETUPS:
        rows = encounters['hunt', setup]
        target = numbers(rows, 'first_target_shot_round')
        counts = {round_: target.count(round_) for round_ in sorted(set(target))}
        contact = numbers(rows, 'first_shot_round')
        print(setup, 'kill', percent(rows, 'quarry_kill'), 'target shot round counts', counts,
              'no target shot', len(rows) - len(target), 'first gun R3-4', sum(3 <= r <= 4 for r in contact),
              'screen bounds', spread(rows, 'hunt_screen_min'), spread(rows, 'hunt_screen_max'))


def faction_table(factions):
    print('\n| Player | Enemy | Today | All three | Change | Paired wins up/down | Approx. 95% range |')
    print('|---|---|---:|---:|---:|---:|---:|')
    flagged = 0
    for pf in FACTIONS:
        for ef in FACTIONS:
            base, all_ = (factions[pf, ef, setup] for setup in ('today', 'all'))
            order = lambda r: r['seed']
            first, second = (sorted(rows, key=order) for rows in (base, all_))
            assert all(a['encounter'] == b['encounter'] and a['requested_map'] == b['requested_map']
                       for a, b in zip(first, second)), (pf, ef)
            change = [int(b['win']) - int(a['win']) for a, b in zip(first, second)]
            points = 100 * sum(change) / len(change)
            if abs(points) <= 10:
                continue
            flagged += 1
            margin = 1.96 * 100 * stdev(change) / math.sqrt(len(change))
            print(f'| {pf} | {ef} | {percent(base, "win")} | {percent(all_, "win")} | {points:+g} pp | '
                  f'{change.count(1)} / {change.count(-1)} | {points - margin:+.0f} to {points + margin:+.0f} pp |')
    print(f'\n{flagged} of {len(FACTIONS)**2} seatings above 10 points')


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--encounters', type=Path, required=True)
    cli.add_argument('--factions', type=Path, required=True)
    cli.add_argument('--encounter-retest', type=Path, action='append', default=[])
    cli.add_argument('--faction-retest', type=Path, action='append', default=[])
    cli.add_argument('--out', type=Path, required=True)
    cli.add_argument('--pictures', type=Path, required=True)
    cli.add_argument('--sims', default=100, type=int)
    cli.add_argument('--seed', default=1000, type=int)
    opt = cli.parse_args()
    results = update(read(opt.encounters), opt.encounter_retest)
    matchup = update(read(opt.factions), opt.faction_retest)
    enc = assert_pairs(group(results, 'encounter', 'setup'),
                       [(e, s) for e in ENCOUNTERS for s in SETUPS], opt.sims, opt.seed)
    fac = assert_pairs(group(matchup, 'player_faction', 'enemy_faction', 'setup'),
                       [(p, e, s) for p in FACTIONS for e in FACTIONS for s in ('today', 'all')],
                       opt.sims, opt.seed)
    assert set(r['player_cp'] for r in matchup) == {'16'}
    assert all(int(r['enemy_cp']) >= 16 and (r['enemy_cp'] == '16' or r['encounter'] == 'intercept') for r in matchup)
    seeds = {}
    for e in ENCOUNTERS:
        today = {r['seed']:r for r in enc[e, 'today']}
        after = enc[e, 'all']
        for setup in SETUPS[1:]:
            assert all(all(r[key] == today[r['seed']][key] for key in ('requested_map', 'deployment', 'enemy_faction'))
                       for r in enc[e, setup]), f'Unpaired input in {e}, {setup}'
        shaped = {r['seed']:r for r in enc[e, 'shapes']}
        for setup in SETUPS[2:]:
            assert all(all(r[key] == shaped[r['seed']][key] for key in ('requested_shape', 'shape', 'arena', 'map'))
                       for r in enc[e, setup]), f'Unpaired terrain in {e}, {setup}'
        gap = median(numbers(after, 'objective_gap'))
        old_gap = median(numbers(enc[e, 'today'], 'objective_gap'))
        ranked = sorted(after, key=lambda r: (
            r['shape'] == today[r['seed']]['shape'] and r['objective_gap'] == today[r['seed']]['objective_gap'],
            abs(float(r['objective_gap']) - gap) + abs(float(today[r['seed']]['objective_gap']) - old_gap),
            int(r['seed'])))
        if e == 'hunt':
            ranked.sort(key=lambda r: not (r['first_target_shot_round'] in ('3', '4')))
        seeds[e] = int(ranked[0]['seed'])
    with opt.out.open('x', newline='', encoding='utf-8') as dest:
        writer = csv.DictWriter(dest, fieldnames=list(results[0]), lineterminator='\n')
        writer.writeheader()
        writer.writerows(results + matchup)
    with opt.pictures.open('x', encoding='utf-8') as dest:
        json.dump(seeds, dest)
    encounter_tables(enc)
    faction_table(fac)


if __name__ == '__main__':
    main()
