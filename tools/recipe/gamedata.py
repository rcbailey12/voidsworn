# Ship recipe: read a ship's weapon list from the game's own data.js (plain Python; used by export7.py inside Blender and by
# check_export.py outside it), so hard point names always follow the rules file and never a copy of it.
import os, re
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.normpath(os.path.join(HERE, '..', '..'))


def _block(ship_id, data_js=None):
    """the text of the ship's own object in data.js, from its id to the closing brace of that entry"""
    src = open(data_js or os.path.join(REPO, 'data.js'), encoding='utf-8').read()
    m = re.search(r'(?<![A-Za-z0-9_])' + re.escape(ship_id) + r'\s*:\s*\{', src)
    if not m:
        raise ValueError(f'ship {ship_id} is not in data.js')
    end = src.find('}', m.end())
    if end < 0:
        raise ValueError(f'ship {ship_id} has no closing brace in data.js')
    return src[m.end():end]


def weapons(ship_id, data_js=None):
    """[(weapon kind, arc), ...] in slot order for the ship with this id in data.js; raises ValueError when it cannot be read"""
    body = _block(ship_id, data_js)
    w = re.search(r'(?<![A-Za-z0-9_])w\s*:\s*\[((?:\s*\[[^\]]*\]\s*,?)*)\s*\]', body)
    if not w:
        raise ValueError(f'ship {ship_id} has no weapon list in data.js')
    out = re.findall(r"\[\s*'([A-Za-z0-9_]+)'\s*,\s*'([FTPS])'\s*\]", w.group(1))
    if not out or len(out) != w.group(1).count('['):
        raise ValueError(f'could not read every weapon of {ship_id} in data.js')
    return out


def ship_attr(ship_id, key, data_js=None, default=None):
    """a simple value from the ship's data.js entry (cls, fac, hangar and the like); default when the key is not there"""
    body = _block(ship_id, data_js)
    m = re.search(r'(?<![A-Za-z0-9_])' + re.escape(key) + r'\s*:\s*(?:\'([^\']*)\'|"([^"]*)"|([0-9.]+)|(true|false))', body)
    if not m:
        return default
    v = m.group(1) if m.group(1) is not None else m.group(2) if m.group(2) is not None else m.group(3) if m.group(3) is not None else m.group(4)
    if v in ('true', 'false'):
        return v == 'true'
    try:
        return float(v) if '.' in v else int(v)
    except ValueError:
        return v


if __name__ == '__main__':
    import sys
    print(weapons(sys.argv[1]))
