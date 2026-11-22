# Ship recipe: read ship slots and attributes from the Godot rules tables.
# This module runs both inside Blender and in the plain Python export checks.
import json
import os
import struct

HERE = os.path.dirname(os.path.abspath(__file__))
TABLES = os.path.join(HERE, '..', '..', 'godot', 'rules', 'data', 'tables.json')

# The intercept transport and relay beacon use objective meshes, without roster weapon slots
# (issue 1413, godot/render/hull_table.gd AI_HULLS obj|transport and obj|beacon).
OBJECTIVES = {
    'obj_transport': {'cls': 'transport', 'fac': 'hegemony', 'w': []},
    'obj_beacon': {'cls': 'beacon', 'fac': 'hegemony', 'w': []},
}


def _table(name, tables_json):
    with open(tables_json or TABLES, encoding='utf-8') as source:
        table = json.load(source).get('tables', {}).get(name)
    if not isinstance(table, dict):
        raise ValueError(f'the Godot rules tables have no {name} table')
    return table


def _ship(hulls, ship_id):
    ship = hulls.get(ship_id)
    if not isinstance(ship, dict):
        raise ValueError(f'ship {ship_id} is not in the Godot HULLS table')
    return ship


def weapons(ship_id, tables_json=None):
    """Return (weapon id, arc) pairs in the ship's Godot slot order."""
    ship = OBJECTIVES.get(ship_id)
    if ship is None:
        ship = _ship(_table('HULLS', tables_json), ship_id)
    slots = ship.get('w')
    if not isinstance(slots, list) or any(
        not isinstance(slot, list) or len(slot) != 2
        or not isinstance(slot[0], str) or not slot[0] or slot[1] not in ('F', 'T', 'P', 'S')
        for slot in slots
    ):
        raise ValueError(f'ship {ship_id} has an invalid weapon list in the Godot HULLS table')
    return [tuple(slot) for slot in slots]


def ship_attr(ship_id, key, tables_json=None, default=None):
    """Return an attribute from the hull, following its base for missing keys."""
    if ship_id in OBJECTIVES:
        return OBJECTIVES[ship_id].get(key, default)
    hulls = _table('HULLS', tables_json)
    seen = set()
    while True:
        if ship_id in seen:
            raise ValueError(f'cyclic Godot HULLS base chain at {ship_id}')
        seen.add(ship_id)
        ship = _ship(hulls, ship_id)
        if key in ship:
            value = ship[key]
            if isinstance(value, str) and value.startswith('#d:'):
                return struct.unpack('>d', bytes.fromhex(value[3:]))[0]
            return value
        ship_id = ship.get('base')
        if not ship_id:
            return default


def weapon_stats(weapon_id, tables_json=None):
    """Return the kind, shots per volley and name from the Godot W table."""
    w = _table('W', tables_json).get(weapon_id)
    if not isinstance(w, dict):
        raise ValueError(f'weapon {weapon_id} is not in the Godot weapon table W')
    if not isinstance(w.get('k'), str) or not isinstance(w.get('shots'), int):
        raise ValueError(f'weapon {weapon_id} has no kind or shots in the Godot weapon table W')
    return dict(k=w['k'], shots=w['shots'], n=w.get('n') or weapon_id)


if __name__ == '__main__':
    import sys
    print(weapons(sys.argv[1]))
