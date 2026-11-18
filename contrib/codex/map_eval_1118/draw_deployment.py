"""Draw the generator's deployment snapshots as side-by-side PNG diagrams."""

import argparse
from functools import lru_cache
import json
from math import cos, pi, sin, sqrt
from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools'))
from picture_provenance import stamp_file, verify


SCALE = 2
WIDTH, HEIGHT = 1280, 688
RADIUS = 10.2
TEXT, MUTED = '#eef4f8', '#acbac6'
PLAYER, ENEMY, GOAL, EXIT = '#62cde7', '#ff9381', '#ffd284', '#87d8a4'
GROUND = {
    'rock': '#70604d', 'hulk': '#806249', 'station': '#87674c', 'planet': '#515663',
    'storm': '#675735', 'neb': '#4c4164', 'debris': '#404956', 'open': '#1a2834',
}
NAMES = {
    'rout': 'Engagement', 'ambush': 'Ambush', 'defend': 'Hold the station', 'hunt': 'Hunt',
    'intercept': 'Intercept', 'break': 'Breakthrough', 'hold': 'Relay', 'flagship': 'Decapitation',
}
OBJECTS = {
    'rout': 'enemy line', 'ambush': 'enemy line', 'defend': 'station guard ring',
    'hunt': 'quarry', 'intercept': 'convoy', 'break': 'exit cells',
    'hold': 'relay zone', 'flagship': 'flagship',
}


@lru_cache
def font(size, bold=False):
    face = 'segoeuib.ttf' if bold else 'segoeui.ttf'
    win = Path('C:/Windows/Fonts') / face
    try:
        return ImageFont.truetype(str(win) if win.is_file() else 'DejaVuSans.ttf', size * SCALE)
    except OSError:
        return ImageFont.load_default(size * SCALE)


def px(point):
    return tuple(round(value * SCALE) for value in point)


def polygon(draw, points, fill, outline=None):
    draw.polygon([px(p) for p in points], fill=fill, outline=outline)


def label(draw, x, y, value, size, fill=TEXT, bold=False):
    draw.text(px((x, y)), value, font=font(size, bold), fill=fill, anchor='lt')


def marker(draw, x, y, sides, r, angle, fill, edge=None):
    polygon(draw, [(x + r * cos(angle + 2*pi*i/sides), y + r * sin(angle + 2*pi*i/sides))
                   for i in range(sides)], fill, edge)


def key(h):
    return f"{h['q']},{h['r']}"


def panel(draw, x, snap, heading, goal):
    draw.rectangle(px((x, 112, x + 598, 551)), fill='#101820', outline='#314350', width=SCALE)
    label(draw, x + 18, 130, heading, 20, bold=True)
    title = ' / '.join(str(snap[k]).replace('_', ' ').title() for k in ('map', 'shape', 'arena'))
    if snap['approach']:
        title += ' / ' + snap['approach'].title()
    label(draw, x + 18, 162, title, 16, MUTED)

    def xy(h):
        return (x + 40 + sqrt(3)*RADIUS*(h['q'] + h['r']/2), 185 + 1.5*RADIUS*h['r'])

    zones = {key(h) for h in snap['zone']}
    exits = {key(h) for h in snap['exit']}
    home = {key(h) for h in snap['home']}
    for h in snap['cells']:
        cx, cy = xy(h)
        cell = key(h)
        paint = GROUND[snap['terrain'].get(cell, 'open')]
        stroke = '#253744'
        if cell in zones:
            paint, stroke = '#493d29', '#b99355'
        if cell in exits or cell in home:
            paint, stroke = '#274634', '#588b6d'
        marker(draw, cx, cy, 6, RADIUS, pi/6, paint, stroke)
    for hole in snap.get('mapHoles') or []:
        for q, r in hole['cells']:
            marker(draw, *xy({'q':q, 'r':r}), 6, RADIUS, pi/6, '#312c30', '#463b40')

    if snap.get('station'):
        marker(draw, *xy(snap['station']), 6, 6, pi/6, '#e5b27d')
    if snap.get('objective') and snap['objective'] != snap.get('station'):
        marker(draw, *xy(snap['objective']), 4, 7, 0, GOAL, '#0a1219')
    for u in sorted(snap['units'], key=lambda u: (u['target'], u['screen'], not u['wing'])):
        cx, cy = xy(u)
        color = PLAYER if u['side'] == 'player' else ENEMY
        if u['wing']:
            marker(draw, cx, cy, 8, 3, 0, color, '#0a1219')
            continue
        if u['target'] or u['transport']:
            marker(draw, cx, cy, 4 if u['target'] else 6, 11, pi/4 if u['target'] else 0, None, GOAL)
        if u['screen']:
            marker(draw, cx, cy, 8, 10, 0, None, '#fff0bb')
        a = pi * u['f'] / 3
        polygon(draw, [(cx + 8*cos(a), cy + 8*sin(a)),
                       (cx + 7*cos(a + 2.48), cy + 7*sin(a + 2.48)),
                       (cx + 7*cos(a - 2.48), cy + 7*sin(a - 2.48))], color, '#0a1219')
    label(draw, x + 18, 522, f"Nearest player to {goal}   {snap['initial']['objective_gap']} hexes", 17, bold=True)


def picture(enc, snapshots, dest):
    a, b = snapshots
    image = Image.new('RGB', (WIDTH*SCALE, HEIGHT*SCALE), '#0b1118')
    draw = ImageDraw.Draw(image)
    code = 'ME-' + enc.upper().replace('_', '-')
    regular = enc.split('_')[-1] if enc.startswith('boss') else enc
    boss = enc.startswith('boss')
    name = f'Sector {enc[4]} boss / {NAMES[regular]}' if boss else NAMES[enc]
    label(draw, 30, 24, code, 17, GOAL, True)
    label(draw, 30, 53, name, 35, bold=True)
    label(draw, 946, 43, f"30 x 22  /  Paired seed {a['seed']}", 20, MUTED)
    goal = 'boss' if boss else OBJECTS[enc]
    panel(draw, 30, a, 'Today', goal)
    panel(draw, 652, b, 'All three', goal)
    legend = [(30, 'Player fleet', PLAYER), (171, 'Enemy fleet', ENEMY), (322, 'Target / objective', GOAL),
              (524, 'Exit / jump bearing', EXIT), (741, 'Solid terrain', GROUND['rock']),
              (912, 'Nebula / storm / debris', '#8d809b')]
    for x, text, color in legend:
        marker(draw, x + 7, 578, 6, 6, 0, color)
        label(draw, x + 20, 571, text, 15, MUTED)
    label(draw, 575, 627, 'Deployment from the rules sim  /  Arrows show facing', 16, MUTED)
    output = dest / (code + '.png')
    image.resize((WIDTH, HEIGHT), Image.Resampling.LANCZOS).save(output)
    stamp_file(output, 'sheet built', repo=ROOT, new_render=True)
    verify(output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path)
    parser.add_argument('output', type=Path)
    opt = parser.parse_args()
    opt.output.mkdir(parents=True, exist_ok=True)
    for enc, snapshots in json.loads(opt.input.read_text(encoding='utf-8')).items():
        assert snapshots[0]['seed'] == snapshots[1]['seed']
        picture(enc, snapshots, opt.output)


if __name__ == '__main__':
    main()
