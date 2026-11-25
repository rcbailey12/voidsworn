"""Read the station range from its table home, never from a fitted manifest."""
import hashlib
from pathlib import Path
import re

REPO = Path(__file__).resolve().parents[4]


def contract():
    table = REPO/'docs/playbooks/scale.md'
    board = REPO/'godot/render/board.gd'
    rows = []
    for line in table.read_text(encoding='utf-8').splitlines():
        cells = [s.strip() for s in line.split('|')]
        if len(cells) > 5 and cells[1] == 'Station':
            match = re.fullmatch(r'([\d.]+) to ([\d.]+)', cells[4])
            if not match:
                raise ValueError('Station target is not a numeric range: '+line)
            rows.append(tuple(float(n) for n in match.groups()))
    # the one-hex row became the Outpost row (Ryan, Nov 24 2026, issue 1791): the big station row sets T2's range
    if len(rows) != 1:
        raise ValueError('Expected one board station row (the big cluster)')
    live = {}
    source = board.read_text(encoding='utf-8')
    props = (REPO/'godot/assets/ships/a4_props.gd').read_text(encoding='utf-8')
    for key in ('STATION_BASE_LEN', 'STATION_PER_HEX', 'STATION_BIG_LEN', 'STATION_BIG_HEXES'):
        match = re.search(r'^const '+key+r'\s*:=\s*([\d.]+|A4P\.\w+)', source, re.M)
        if match and match[1].startswith('A4P.'):
            # board.gd names some station sizes from a4_props.gd (STATION_BIG_LEN := A4P.LARGE_STATION_SIZE)
            match = re.search(r'^const '+match[1][4:]+r'\s*:=\s*([\d.]+)', props, re.M)
        if not match:
            raise ValueError('Missing live station constant '+key)
        live[key] = float(match[1])
    return dict(range=list(rows[0]), table='docs/playbooks/scale.md',
                table_sha256=hashlib.sha256(table.read_bytes()).hexdigest(),
                live_source='godot/render/board.gd', live_constants=live,
                live_one_hex=live['STATION_BASE_LEN']+live['STATION_PER_HEX'],
                live_large=live['STATION_BIG_LEN'])
