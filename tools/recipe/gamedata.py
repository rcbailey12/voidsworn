# Ship recipe: read a ship's weapon list from the game's own data.js (plain Python; used by export7.py inside Blender and by
# check_export.py outside it), so hard point names always follow the rules file and never a copy of it.
import os, re
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.normpath(os.path.join(HERE, '..', '..'))

def weapons(ship_id, data_js=None):
    """[(weapon kind, arc), ...] in slot order for the ship with this id in data.js; raises ValueError when it cannot be read"""
    src = open(data_js or os.path.join(REPO, 'data.js'), encoding='utf-8').read()
    m = re.search(r'(?<![A-Za-z0-9_])' + re.escape(ship_id) + r'\s*:\s*\{', src)
    if not m: raise ValueError(f'ship {ship_id} is not in data.js')
    end = src.find('}', m.end())
    w = re.search(r'(?<![A-Za-z0-9_])w\s*:\s*\[((?:\s*\[[^\]]*\]\s*,?)*)\s*\]', src[m.end():end])
    if not w: raise ValueError(f'ship {ship_id} has no weapon list in data.js')
    out = re.findall(r"\[\s*'([A-Za-z0-9_]+)'\s*,\s*'([FTPS])'\s*\]", w.group(1))
    if not out or len(out) != w.group(1).count('['): raise ValueError(f'could not read every weapon of {ship_id} in data.js')
    return out

if __name__ == '__main__':
    import sys
    print(weapons(sys.argv[1]))
