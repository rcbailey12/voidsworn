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
    if len(rows) != 2 or len(set(rows)) != 1:
        raise ValueError('Expected two board station rows with one shared range')
    live = {}
    source = board.read_text(encoding='utf-8')
    for key in ('STATION_BASE_LEN', 'STATION_PER_HEX', 'STATION_BIG_LEN', 'STATION_BIG_HEXES'):
        match = re.search(r'^const '+key+r'\s*:=\s*([\d.]+)', source, re.M)
        if not match:
            raise ValueError('Missing live station constant '+key)
        live[key] = float(match[1])
    return dict(range=list(rows[0]), table='docs/playbooks/scale.md',
                table_sha256=hashlib.sha256(table.read_bytes()).hexdigest(),
                live_source='godot/render/board.gd', live_constants=live,
                live_one_hex=live['STATION_BASE_LEN']+live['STATION_PER_HEX'],
                live_large=live['STATION_BIG_LEN'])
