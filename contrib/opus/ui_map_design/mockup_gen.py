#!/usr/bin/env python3
"""Builds the three campaign map design options as .dc.html artboards plus plain preview pages."""
import base64, math, os, random, datetime, json

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), 'project')
PREV = os.path.join(HERE, 'preview')
os.makedirs(OUT, exist_ok=True)
os.makedirs(PREV, exist_ok=True)

NEM = 'data:image/jpeg;base64,' + base64.b64encode(open(os.path.join(HERE, 'nem.jpg'), 'rb').read()).decode()

INK = '#070907'
COL = '#0b0e0b'
BONE = '#e8eee0'
BONE2 = '#a7b09d'
BONE3 = '#7c8674'
IRON3 = '#283228'
HAIR = '#1c241c'
LIME = '#c8f53a'
ON_LIME = '#0d1200'
ALERT = '#ff4433'
EMBER = '#ffb23e'
FONT = "'Chakra Petch', system-ui, sans-serif"
MONO = "'Azeret Mono', ui-monospace, monospace"

# id, name, type, danger 0..4, x, y, state, nemesis meeting
NODES = [
    ('ENG', 'Engagement', 'battle', 1, 208, 776, 'current', False),
    ('REL', 'Relay', 'battle', 1, 208, 544, 'next', False),
    ('BRK1', 'Breakthrough', 'battle', 1, 352, 639, 'next', False),
    ('UNK1', 'Unknown signal', 'event', 0, 399, 770, 'next', False),
    ('SHP1', 'Shipyard', 'shipyard', 0, 438, 382, 'ahead', False),
    ('DEC', 'Decapitation', 'elite', 1, 455, 504, 'ahead', False),
    ('UNK2', 'Unknown signal', 'event', 0, 598, 389, 'ahead', False),
    ('SHP2', 'Shipyard', 'shipyard', 0, 767, 320, 'ahead', False),
    ('HOLD', 'Hold the station', 'battle', 3, 784, 417, 'ahead', False),
    ('INT', 'Intercept', 'elite', 4, 1115, 366, 'ahead', True),
    ('BRK2', 'Breakthrough', 'battle', 4, 1038, 454, 'ahead', True),
    ('REP', 'Field repairs', 'repair', 0, 1371, 516, 'ahead', False),
    ('SHP3', 'Shipyard', 'shipyard', 0, 1217, 569, 'ahead', False),
    ('FLAG', 'Sector flagship', 'flagship', 4, 1384, 787, 'ahead', False),
]
EDGES = [('ENG', 'REL'), ('ENG', 'BRK1'), ('ENG', 'UNK1'), ('REL', 'SHP1'), ('BRK1', 'SHP1'), ('BRK1', 'DEC'),
         ('UNK1', 'DEC'), ('SHP1', 'UNK2'), ('DEC', 'UNK2'), ('DEC', 'HOLD'), ('UNK2', 'SHP2'), ('UNK2', 'HOLD'),
         ('SHP2', 'INT'), ('HOLD', 'BRK2'), ('HOLD', 'INT'), ('INT', 'REP'), ('BRK2', 'SHP3'), ('BRK2', 'REP'),
         ('REP', 'FLAG'), ('SHP3', 'FLAG')]
KIND = {'battle': 'Fight', 'elite': 'Elite fight', 'event': 'Event', 'shipyard': 'Shipyard',
        'repair': 'Repairs', 'flagship': 'Flagship fight'}
DANGER = ['', 'Easy', 'Even', 'Hard', 'Deadly']
NOTE = {'shipyard': 'Buy, repair, upgrade', 'repair': 'Every ship patches 20%', 'event': 'Anything can happen'}
BY = {n[0]: n for n in NODES}


def tf(T, x, y):
    s, cx, cy = T
    return (round(cx + s * (x - 800), 1), round(cy + s * (y - 660), 1))


def glyph(t, size, col, sw=1.5, fill='none'):
    b = {
        'battle': '<path d="M8 1.5 14.5 8 8 14.5 1.5 8Z"/>',
        'elite': '<path d="M8 1.5 14.5 8 8 14.5 1.5 8Z"/><path d="M8 5.2 10.8 8 8 10.8 5.2 8Z" fill="%s" stroke="none"/>' % col,
        'shipyard': '<rect x="2.5" y="2.5" width="11" height="11"/>',
        'repair': '<circle cx="8" cy="8" r="6.2"/><path d="M8 4.8v6.4M4.8 8h6.4"/>',
        'event': '<circle cx="8" cy="8" r="6.2"/><circle cx="8" cy="8" r="1.4" fill="%s" stroke="none"/>' % col,
        'flagship': '<path d="M8 1 15 8 8 15 1 8Z"/><path d="M4.4 8h7.2M8 4.4v7.2"/>',
    }[t]
    return ('<svg width="%d" height="%d" viewBox="0 0 16 16" fill="%s" stroke="%s" stroke-width="%s" '
            'stroke-linejoin="miter" aria-hidden="true" style="display:block; flex:none">%s</svg>') % (
                size, size, fill, col, sw, b)


def pips(n, on=BONE, off=IRON3, w=5, h=12):
    out = ['<span style="display:inline-flex; gap:3px; vertical-align:-1px" aria-hidden="true">']
    for i in range(4):
        out.append('<span style="display:block; width:%dpx; height:%dpx; background:%s"></span>' % (w, h, on if i < n else off))
    out.append('</span>')
    return ''.join(out)


def scene(T, w, h, lane_w=1.0, lane_a=0.20, next_w=2.0, ring_a=0.055, stars=80, seed=7):
    s, cx, cy = T
    r = random.Random(seed)
    o = ['<svg width="%d" height="%d" viewBox="0 0 %d %d" aria-hidden="true" style="position:absolute; left:0; top:0; display:block">' % (w, h, w, h)]
    for _ in range(stars):
        o.append('<circle cx="%.0f" cy="%.0f" r="%.1f" fill="%s" opacity="%.2f"/>' % (
            r.uniform(0, w), r.uniform(0, h), r.choice([0.6, 0.8, 0.8, 1.1]), BONE, r.uniform(0.10, 0.42)))
    for rr in (270, 360, 450, 540, 630):
        o.append('<ellipse cx="%s" cy="%s" rx="%.0f" ry="%.0f" fill="none" stroke="%s" stroke-opacity="%s" stroke-width="1"/>' % (
            cx, cy, s * rr, s * rr * 0.54, BONE, ring_a))
    # the dead star: flat, one warm tone, no glow
    o.append('<g transform="translate(%s %s) rotate(-9)">' % (cx, cy))
    o.append('<ellipse rx="%.0f" ry="%.0f" fill="none" stroke="%s" stroke-opacity="0.22" stroke-width="1"/>' % (s * 128, s * 30, EMBER))
    o.append('<ellipse rx="%.0f" ry="%.0f" fill="none" stroke="%s" stroke-opacity="0.75" stroke-width="%.1f"/>' % (s * 96, s * 21, EMBER, 2.5 * s))
    o.append('<circle r="%.0f" fill="#000" stroke="%s" stroke-opacity="0.6" stroke-width="1.2"/>' % (s * 40, EMBER))
    o.append('<path d="M %.0f 0 A %.0f %.0f 0 0 0 %.0f 0" fill="none" stroke="%s" stroke-opacity="0.75" stroke-width="%.1f"/>' % (
        -s * 96, s * 96, s * 21, s * 96, EMBER, 2.5 * s))
    o.append('</g>')
    for a, b in EDGES:
        A, B = BY[a], BY[b]
        x1, y1 = tf(T, A[4], A[5])
        x2, y2 = tf(T, B[4], B[5])
        d = math.hypot(x2 - x1, y2 - y1)
        cut = 17 * max(1.0, s * 0.95)
        ux, uy = (x2 - x1) / d, (y2 - y1) / d
        x1, y1, x2, y2 = x1 + ux * cut, y1 + uy * cut, x2 - ux * cut, y2 - uy * cut
        if A[6] == 'current' and B[6] == 'next':
            o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="%s"/>' % (x1, y1, x2, y2, LIME, next_w))
        else:
            o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-opacity="%s" stroke-width="%s"/>' % (
                x1, y1, x2, y2, BONE, lane_a, lane_w))
    o.append('</svg>')
    return ''.join(o)


HALO = 'text-shadow: 0 0 3px #070907, 0 0 3px #070907, 0 0 8px #070907'
CURSOR = ('<svg width="18" height="22" viewBox="0 0 18 22" aria-hidden="true" style="position:absolute; left:%spx; top:%spx; display:block; z-index:6">'
          '<path d="M2 1.5v16l4.2-3.6 2.7 6 2.6-1.2-2.7-5.9 5.6-.5Z" fill="#e8eee0" stroke="#070907" stroke-width="1.2" stroke-linejoin="round"/></svg>')


def tip(n, extra_style=''):
    """The hover card every unlabelled stop carries."""
    kind = KIND[n[2]]
    line2 = (pips(n[3]) + '<span style="margin-left:8px">%s</span>' % DANGER[n[3]]) if n[3] else NOTE.get(n[2], '')
    nem = ('<span style="display:block; margin-top:4px; color:%s">The Nemesis meets you here</span>' % ALERT) if n[7] else ''
    return ('<span class="tip%s" style="position:absolute; left:20px; top:18px; z-index:5; display:block; text-align:left; white-space:nowrap; '
            'background:#0b0e0b; border:1px solid #283228; padding:8px 12px; font-family:%s; font-size:13px; line-height:18px; color:%s; %s">'
            '<span style="display:block; font-size:15px; font-weight:600; color:%s">%s</span>'
            '<span style="display:block">%s</span><span style="display:block">%s</span>%s</span>') % (
                ' show' if n[0] == 'HOLD' else '', FONT, BONE2, extra_style, BONE, n[1], kind, line2, nem)


CSS = """
body{margin:0}
button{font:inherit}
.stop .tip{opacity:0; pointer-events:none}
.stop:hover .tip,.stop:focus .tip,.stop .tip.show{opacity:1}
.stop:focus{outline:none}
.stop:focus-visible{outline:2px solid #e8eee0; outline-offset:3px}
.plain:hover{color:#e8eee0}
"""
FONTS_LINK = ('<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Azeret+Mono:wght@500;700'
              '&family=Chakra+Petch:wght@400;500;600;700&display=swap">')
FDIR = '/home/claude/voidsworn/godot/ui/theme/fonts/'
FONTS_LOCAL = '<style>' + ''.join(
    "@font-face{font-family:'Chakra Petch';font-weight:%d;src:url('file://%sChakraPetch-%s.ttf')}" % (w, FDIR, f)
    for w, f in ((400, 'Regular'), (500, 'Medium'), (600, 'SemiBold'), (700, 'Bold'))) + (
    "@font-face{font-family:'Azeret Mono';font-weight:100 900;src:url('file://%sAzeretMono-VF.ttf')}" % FDIR) + '</style>'


def wrap(title, root):
    dc = ('<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n<title>%s</title>\n'
          '<script src="./support.js"></script>\n</head>\n<body>\n<x-dc>\n<helmet>\n%s\n<style>%s</style>\n</helmet>\n%s\n</x-dc>\n'
          '<script type="text/x-dc" data-dc-script data-props=\'{"$preview":{"width":1920,"height":1080}}\'>\n'
          'class Component extends DCLogic {\nrenderVals() { return {}; }\n}\n</script>\n</body>\n</html>\n') % (
              title, FONTS_LINK, CSS, root)
    pv = '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>%s</title>%s<style>%s</style></head><body>%s</body></html>' % (
        title, FONTS_LOCAL, CSS, root)
    return dc, pv


def caps(txt, col=BONE3, size=12, track='0.18em', extra=''):
    return '<div style="font-size:%dpx; line-height:16px; font-weight:700; letter-spacing:%s; text-transform:uppercase; color:%s; %s">%s</div>' % (
        size, track, col, extra, txt)


def keycap(txt, dark=False):
    if dark:
        return ('<span style="font-family:%s; font-size:12px; font-weight:700; line-height:20px; padding:0 7px; '
                'background:rgba(13,18,0,0.16); color:%s; letter-spacing:0">%s</span>') % (MONO, ON_LIME, txt)
    return ('<span style="font-family:%s; font-size:12px; font-weight:500; line-height:20px; padding:0 6px; '
            'border:1px solid #3a463a; color:%s; letter-spacing:0">%s</span>') % (MONO, BONE2, txt)


FLEET = [('Cold Fury', 'Cruiser Mk I', '135', '135', True), ('Edge of Winter', 'Destroyer Mk I', '85', '85', False),
         ('Black Anvil', 'Frigate Mk I', '50', '50', False)]
STAR = ('<svg width="12" height="12" viewBox="0 0 12 12" aria-hidden="true" style="display:inline-block; vertical-align:-1px; margin-right:6px">'
        '<path d="M6 .8 7.5 4.4l3.9.3-3 2.5.9 3.8L6 9 2.7 11l.9-3.8-3-2.5 3.9-.3Z" fill="%s"/></svg>')


# ---------------------------------------------------------------------------------------------------------
# Option A: star chart. Plain text on calm space, two colours, small tight type, one quiet column.
# ---------------------------------------------------------------------------------------------------------
def option_a():
    T = (1.0, 780, 610)
    W = 1520
    o = ['<div style="width:1920px; height:1080px; box-sizing:border-box; position:relative; overflow:hidden; background:%s; color:%s; font-family:%s; font-size:14px; line-height:22px">' % (INK, BONE, FONT)]
    o.append('<div style="position:absolute; left:0; top:0; width:%dpx; height:1080px; overflow:hidden">' % W)
    o.append(scene(T, W, 1080))
    for n in NODES:
        x, y = tf(T, n[4], n[5])
        st = n[6]
        col = BONE if st != 'ahead' else BONE2
        inner = []
        if st == 'current':
            inner.append('<span style="display:block; width:12px; height:12px; background:%s; transform:rotate(45deg)"></span>' % LIME)
            inner.append('<span style="position:absolute; left:50%%; top:30px; transform:translateX(-50%%); white-space:nowrap; text-align:center; %s">'
                         '<span style="display:block; font-size:15px; line-height:20px; font-weight:600; color:%s">%s</span>'
                         '<span style="display:block; font-size:12px; line-height:16px; color:%s">Your fleet is here</span></span>' % (HALO, BONE, n[1], BONE2))
        else:
            inner.append(glyph(n[2], 16, LIME if st == 'next' else col))
        if st == 'next':
            sel = n[0] == 'REL'
            if sel:  # target brackets on the stop you have picked
                for (a, b) in (('left:-6px; top:-6px', 'border-left:2px solid; border-top:2px solid'), ('right:-6px; top:-6px', 'border-right:2px solid; border-top:2px solid'),
                               ('left:-6px; bottom:-6px', 'border-left:2px solid; border-bottom:2px solid'), ('right:-6px; bottom:-6px', 'border-right:2px solid; border-bottom:2px solid')):
                    inner.append('<span style="position:absolute; %s; width:8px; height:8px; %s; border-color:%s"></span>' % (a, b, LIME))
            kind = KIND[n[2]]
            l2 = ('%s<span style="margin:0 8px 0 0"></span>%s<span style="margin-left:8px">%s</span>' % (kind, pips(n[3], BONE2), DANGER[n[3]])) if n[3] else kind
            side = 'right:40px; text-align:right' if n[0] == 'BRK1' else 'left:40px; text-align:left'
            inner.append('<span style="position:absolute; %s; top:50%%; transform:translateY(-50%%); white-space:nowrap; %s">'
                         '<span style="display:block; font-size:15px; line-height:20px; font-weight:600; color:%s">%s</span>'
                         '<span style="display:block; font-size:12px; line-height:16px; color:%s">%s</span></span>' % (
                             side, HALO, LIME if sel else BONE, n[1], BONE2, l2))
        if st == 'ahead':
            inner.append(tip(n))
        if n[7]:
            inner.append('<span style="position:absolute; left:50%%; top:-11px; width:7px; height:7px; margin-left:-3.5px; background:%s; transform:rotate(45deg)"></span>' % ALERT)
        o.append('<button class="stop" aria-label="%s" style="position:absolute; left:%.1fpx; top:%.1fpx; width:28px; height:28px; padding:0; border:0; background:transparent; '
                 'cursor:pointer; display:flex; align-items:center; justify-content:center; color:%s; font-family:%s">%s</button>' % (
                     n[1], x - 14, y - 14, col, FONT, ''.join(inner)))
    hx, hy = tf(T, BY['HOLD'][4], BY['HOLD'][5])
    o.append(CURSOR % (hx + 2, hy + 2))
    # header: plain text, one size ladder
    o.append('<div style="position:absolute; left:48px; top:40px">')
    o.append(caps('Sector I of III'))
    o.append('<div style="margin-top:8px; font-size:30px; line-height:36px; font-weight:600; letter-spacing:0.08em; text-transform:uppercase">Old Battlefield</div>')
    o.append('<div style="margin-top:8px; display:flex; gap:32px; font-size:14px; line-height:22px; color:%s">'
             '<span><span style="font-family:%s; color:%s">1</span> of 8 jumps</span><span>Held by Ashfall Hullbreakers</span>'
             '<span>Ion season: shields recharge 25%% slower</span></div>' % (BONE2, MONO, BONE))
    o.append('</div>')
    o.append('<div style="position:absolute; right:48px; top:44px; display:flex; gap:32px; font-size:14px; line-height:22px">'
             '<button class="plain" style="padding:0; border:0; background:transparent; color:%s; cursor:pointer">Map key</button>'
             '<button class="plain" style="padding:0; border:0; background:transparent; color:%s; cursor:pointer">Save and quit</button></div>' % (BONE2, BONE2))
    o.append('<div style="position:absolute; left:48px; bottom:36px; display:flex; gap:32px; font-size:12px; line-height:16px; color:%s">'
             '<span>Scroll to zoom</span><span>Right-drag to pan</span><span>Home resets the view</span></div>' % BONE3)
    o.append('</div>')

    # the column
    hr = '<div style="height:1px; background:%s; margin:24px 0"></div>' % HAIR
    c = ['<div style="position:absolute; left:%dpx; top:0; width:400px; height:1080px; box-sizing:border-box; background:%s; border-left:1px solid %s; padding:32px; display:flex; flex-direction:column">' % (W, COL, HAIR)]
    c.append(caps('Next jump'))
    c.append('<div style="margin-top:12px; display:flex; align-items:center; justify-content:space-between"><div style="font-size:26px; line-height:32px; font-weight:600">Relay</div>%s</div>' % glyph('battle', 20, BONE2))
    c.append('<div style="color:%s">Fight against a Glasswrights picket</div>' % BONE2)
    c.append('<div style="margin-top:12px; color:%s">Break their fleet. It flees once it has lost about two thirds of its strength.</div>' % BONE2)
    c.append('<div style="margin-top:16px; display:grid; grid-template-columns:repeat(3, minmax(0, 1fr)); gap:16px">')
    for lab, val in (('Danger', pips(1) + '<span style="margin-left:8px">Easy</span>'), ('Reward', 'Repairs'), ('Leads to', 'Shipyard')):
        c.append('<div>%s<div style="margin-top:4px; font-size:15px; line-height:22px">%s</div></div>' % (caps(lab), val))
    c.append('</div>')
    c.append('<button style="margin-top:20px; height:48px; border:0; background:%s; color:%s; cursor:pointer; display:flex; align-items:center; justify-content:space-between; padding:0 16px; '
             'font-family:%s; font-size:15px; font-weight:700; letter-spacing:0.12em; text-transform:uppercase"><span>Jump to Relay</span>%s</button>' % (LIME, ON_LIME, FONT, keycap('Enter', True)))
    c.append('<div style="margin-top:12px; font-size:13px; line-height:18px; color:%s">Or pick Breakthrough or Unknown signal on the map.</div>' % BONE3)
    c.append(hr)
    c.append('<div style="display:flex; justify-content:space-between; align-items:baseline">%s'
             '<button class="plain" style="padding:0; border:0; background:transparent; color:%s; cursor:pointer; font-size:13px; line-height:16px">Dossier</button></div>' % (caps('Nemesis', ALERT), BONE2))
    c.append('<div style="margin-top:12px; display:flex; gap:16px; align-items:center">'
             '<img src="%s" alt="High Nadir Essane" width="64" height="64" style="display:block; width:64px; height:64px; object-fit:cover; flex:none">'
             '<div><div style="font-size:18px; line-height:24px; font-weight:600">High Nadir Essane</div>'
             '<div style="font-size:13px; line-height:18px; color:%s">Eclipse</div></div></div>' % (NEM, BONE2))
    c.append('<div style="margin-top:12px; color:%s">Cruel: finishes crippled ships first.<br>Meets you at the two stops marked '
             '<span style="display:inline-block; width:7px; height:7px; background:%s; transform:rotate(45deg); margin:0 3px 1px 3px"></span></div>' % (BONE2, ALERT))
    c.append('<div style="margin-top:12px; display:flex; align-items:center; gap:12px; font-size:13px; line-height:16px; color:%s"><span>Hunt clock</span>%s'
             '<span style="font-family:%s; color:%s">0/4</span></div>' % (BONE2, pips(0, ALERT, IRON3, 14, 6), MONO, BONE))
    c.append(hr)
    c.append('<div style="display:grid; grid-template-columns:repeat(2, minmax(0, 1fr)); gap:16px">')
    for lab, val, dim in (('Credits', '120', ''), ('Command points', '6', '/10')):
        c.append('<div>%s<div style="margin-top:4px; font-family:%s; font-size:26px; line-height:32px; font-weight:700">%s<span style="color:%s; font-weight:500">%s</span></div></div>' % (
            caps(lab), MONO, val, BONE3, dim))
    c.append('</div>')
    c.append(hr)
    c.append('<div style="display:flex; justify-content:space-between; align-items:baseline">%s<span style="font-size:13px; line-height:16px; color:%s">3 ships, all ready</span></div>' % (caps('Fleet'), BONE2))
    for name, cls, hp, mx, flag in FLEET:
        c.append('<div style="margin-top:12px; display:flex; align-items:center; gap:10px">'
                 '<div style="flex:1; min-width:0; white-space:nowrap; font-size:15px; line-height:20px; font-weight:600">%s%s<span style="margin-left:10px; font-size:13px; font-weight:400; color:%s">%s</span></div>'
                 '<div style="width:36px; height:3px; background:%s; flex:none"><div style="height:3px; width:100%%; background:%s"></div></div>'
                 '<div style="width:56px; flex:none; text-align:right; font-family:%s; font-size:13px; line-height:20px">%s<span style="color:%s">/%s</span></div></div>' % (
                     (STAR % BONE) if flag else '', name, BONE3, cls, IRON3, BONE2, MONO, hp, BONE3, mx))
    c.append('<div style="margin-top:auto">')
    c.append('<div style="display:flex; justify-content:space-between; align-items:baseline"><div style="font-size:15px; line-height:20px; font-weight:600">Keep the dawn watch</div>'
             '<div style="font-family:%s; font-size:13px; line-height:20px; color:%s">40 credits</div></div>' % (MONO, BONE2))
    c.append('<div style="font-size:13px; line-height:18px; color:%s">Next battle, ships next to an ally take 15%% less hull damage.</div>' % BONE3)
    c.append('<button style="margin-top:16px; width:100%%; height:44px; border:1px solid #3a463a; background:transparent; color:%s; cursor:pointer; '
             'font-family:%s; font-size:14px; font-weight:600; display:flex; align-items:center; justify-content:space-between; padding:0 16px"><span>Fleet and refits</span>%s</button>' % (BONE, FONT, keycap('F')))
    c.append('</div></div>')
    o.append(''.join(c))
    o.append('</div>')
    return wrap('Option A: star chart', ''.join(o))


# ---------------------------------------------------------------------------------------------------------
# Option B: war table. Icon discs, one bottom dock in the game's slab style, three colours.
# ---------------------------------------------------------------------------------------------------------
def chamfer(w, h, inner, edge='rgba(200,245,58,0.28)', fill='#0a0d0a', c=14, extra=''):
    poly = 'polygon(%dpx 0, 100%% 0, 100%% calc(100%% - %dpx), calc(100%% - %dpx) 100%%, 0 100%%, 0 %dpx)' % (c, c, c, c)
    return ('<div style="width:%s; height:%s; box-sizing:border-box; background:%s; clip-path:%s; padding:1px; %s">'
            '<div style="width:100%%; height:100%%; box-sizing:border-box; background:%s; clip-path:%s">%s</div></div>') % (
                w, h, edge, poly, extra, fill, poly, inner)


def option_b():
    T = (1.2, 960, 590)
    o = ['<div style="width:1920px; height:1080px; box-sizing:border-box; position:relative; overflow:hidden; background:%s; color:%s; font-family:%s; font-size:14px; line-height:22px">' % (INK, BONE, FONT)]
    o.append(scene(T, 1920, 1080, lane_w=1.5, lane_a=0.22, next_w=2.5))
    for n in NODES:
        x, y = tf(T, n[4], n[5])
        st = n[6]
        R = 20
        inner = []
        ring = ''
        if n[3] and st != 'current':
            circ = 2 * math.pi * 24
            colr = ALERT if n[7] else EMBER
            frac = 1.0 if n[7] else n[3] / 4.0
            ring = ('<svg width="56" height="56" viewBox="0 0 56 56" aria-hidden="true" style="position:absolute; left:-8px; top:-8px; display:block">'
                    '<circle cx="28" cy="28" r="24" fill="none" stroke="%s" stroke-width="3"/>'
                    '<circle cx="28" cy="28" r="24" fill="none" stroke="%s" stroke-width="3" stroke-dasharray="%.1f %.1f" transform="rotate(-90 28 28)"/></svg>') % (
                        IRON3, colr, circ * frac, circ)
        inner.append(ring)
        edge = LIME if st in ('next', 'current') else '#3a463a'
        fillc = LIME if st == 'current' else '#0d110d'
        gcol = ON_LIME if st == 'current' else (BONE if st == 'next' else BONE2)
        inner.append('<span style="display:flex; align-items:center; justify-content:center; width:40px; height:40px; box-sizing:border-box; border-radius:50%%; background:%s; border:2px solid %s">%s</span>' % (
            fillc, edge, glyph(n[2], 18, gcol, 1.6)))
        if st in ('next', 'current'):
            sub = 'Your fleet' if st == 'current' else (DANGER[n[3]] if n[3] else 'Event')
            inner.append('<span style="position:absolute; left:50%%; top:54px; transform:translateX(-50%%); white-space:nowrap; background:#080a08; padding:4px 10px; text-align:center">'
                         '<span style="font-size:14px; line-height:18px; font-weight:600; color:%s">%s</span>'
                         '<span style="margin-left:10px; font-size:12px; line-height:18px; color:%s">%s</span></span>' % (BONE, n[1], BONE2, sub))
        if st == 'ahead':
            inner.append(tip(n, 'left:34px; top:34px;'))
        o.append('<button class="stop" aria-label="%s" style="position:absolute; left:%.1fpx; top:%.1fpx; width:40px; height:40px; padding:0; border:0; background:transparent; '
                 'cursor:pointer; color:%s; font-family:%s">%s</button>' % (n[1], x - R, y - R, BONE, FONT, ''.join(inner)))
    hx, hy = tf(T, BY['HOLD'][4], BY['HOLD'][5])
    o.append(CURSOR % (hx + 6, hy + 6))

    # header
    o.append('<div style="position:absolute; left:40px; top:32px">')
    o.append('<div style="font-size:34px; line-height:40px; font-weight:700; letter-spacing:0.14em; text-transform:uppercase">Sector I: Old Battlefield</div>')
    o.append('<div style="margin-top:6px; display:flex; gap:28px; align-items:baseline; font-size:14px; line-height:22px; color:%s">'
             '<span>Jump <span style="font-family:%s; color:%s">1/8</span></span><span>Held by Ashfall Hullbreakers</span>'
             '<span style="color:%s">Ion season: shields recharge 25%% slower</span></div>' % (
                 BONE2, MONO, BONE, EMBER))
    o.append('</div>')
    btn = ('<button style="height:36px; padding:0 14px; border:1px solid rgba(200,245,58,0.28); background:#0a0d0a; color:%s; cursor:pointer; font-family:%s; font-size:14px; '
           'font-weight:600; display:flex; align-items:center; gap:10px">%s<span>%s</span></button>')
    o.append('<div style="position:absolute; right:24px; top:32px; display:flex; gap:12px">%s%s</div>' % (
        btn % (BONE, FONT, keycap('K'), 'Map key'), btn % (BONE, FONT, keycap('Esc'), 'Save and quit')))

    # the callout on the picked stop
    rx, ry = tf(T, BY['REL'][4], BY['REL'][5])
    cw, ch, cx0, cy0 = 328, 210, 56, 168
    o.append('<svg width="1920" height="1080" viewBox="0 0 1920 1080" aria-hidden="true" style="position:absolute; left:0; top:0; display:block; pointer-events:none">'
             '<line x1="%.0f" y1="%.0f" x2="%.0f" y2="%.0f" stroke="%s" stroke-width="1.5"/></svg>' % (rx, ry - 30, rx, cy0 + ch, LIME))
    card = ['<div style="padding:16px 18px; box-sizing:border-box; height:100%; display:flex; flex-direction:column">']
    card.append(caps('Next jump', LIME))
    card.append('<div style="margin-top:6px; display:flex; justify-content:space-between; align-items:baseline"><div style="font-size:22px; line-height:28px; font-weight:600">Relay</div>'
                '<div style="font-size:13px; color:%s">%s<span style="margin-left:8px">Easy</span></div></div>' % (BONE2, pips(1, EMBER)))
    card.append('<div style="margin-top:4px; font-size:14px; line-height:20px; color:%s">Glasswrights picket. Break their fleet; it flees at two thirds lost.</div>' % BONE2)
    card.append('<div style="margin-top:6px; font-size:13px; line-height:18px; color:%s">Reward <span style="color:%s">Repairs</span><span style="margin-left:16px">Leads to <span style="color:%s">Shipyard</span></span></div>' % (BONE3, BONE, BONE))
    card.append('<button style="margin-top:auto; height:40px; border:0; background:%s; color:%s; cursor:pointer; display:flex; align-items:center; justify-content:space-between; padding:0 14px; '
                'font-family:%s; font-size:14px; font-weight:700; letter-spacing:0.12em; text-transform:uppercase"><span>Jump</span>%s</button>' % (LIME, ON_LIME, FONT, keycap('Enter', True)))
    card.append('</div>')
    o.append('<div style="position:absolute; left:%dpx; top:%dpx">%s</div>' % (cx0, cy0, chamfer('%dpx' % cw, '%dpx' % ch, ''.join(card), 'rgba(200,245,58,0.5)')))

    # the dock
    d = ['<div style="height:100%; box-sizing:border-box; display:flex; align-items:stretch; padding:0 24px">']
    # nemesis
    d.append('<div style="width:500px; flex:none; display:flex; gap:18px; align-items:center; padding-right:24px">'
             '<img src="%s" alt="High Nadir Essane" width="96" height="96" style="display:block; width:96px; height:96px; object-fit:cover; flex:none; outline:2px solid %s; outline-offset:-2px">'
             '<div style="min-width:0">%s'
             '<div style="margin-top:4px; font-size:19px; line-height:24px; font-weight:600">High Nadir Essane <span style="font-size:13px; font-weight:400; color:%s; margin-left:6px">Eclipse</span></div>'
             '<div style="font-size:13px; line-height:18px; color:%s">Cruel: finishes crippled ships first. Meets you at the red-ringed stops.</div>'
             '<div style="margin-top:6px; display:flex; align-items:center; gap:10px; font-size:13px; line-height:16px; color:%s"><span>Hunt clock</span>%s<span style="font-family:%s; color:%s">0/4</span></div>'
             '</div></div>' % (NEM, ALERT, caps('Nemesis', ALERT), BONE2, BONE2, BONE2, pips(0, ALERT, IRON3, 14, 6), MONO, BONE))
    d.append('<div style="width:1px; background:rgba(200,245,58,0.12); margin:18px 0"></div>')
    # fleet
    d.append('<div style="flex:1; min-width:0; padding:16px 24px 0 24px">%s<div style="margin-top:10px; display:grid; grid-template-columns:repeat(3, minmax(0, 1fr)); gap:24px">' % caps('Fleet', LIME))
    for name, cls, hp, mx, flag in FLEET:
        d.append('<div><div style="display:flex; justify-content:space-between; align-items:baseline"><div style="font-size:15px; line-height:20px; font-weight:600">%s%s</div>'
                 '<div style="font-family:%s; font-size:13px; line-height:20px; color:%s">%s<span style="color:%s">/%s</span></div></div>'
                 '<div style="margin-top:6px; height:4px; background:#2b2a20"><div style="height:4px; width:100%%; background:#ffad3b"></div></div>'
                 '<div style="margin-top:6px; font-size:13px; line-height:18px; color:%s">%s</div></div>' % (
                     (STAR % BONE) if flag else '', name, MONO, '#ffad3b', hp, BONE3, mx, BONE2, cls))
    d.append('</div></div>')
    d.append('<div style="width:1px; background:rgba(200,245,58,0.12); margin:18px 0"></div>')
    # resources and actions
    d.append('<div style="width:236px; flex:none; padding:16px 0 0 24px; display:grid; grid-template-columns:repeat(2, minmax(0, 1fr)); gap:12px; align-content:start">')
    for lab, val, dim in (('Credits', '120', ''), ('Command', '6', '/10')):
        d.append('<div>%s<div style="margin-top:8px; font-family:%s; font-size:28px; line-height:32px; font-weight:700">%s<span style="color:%s; font-weight:500">%s</span></div></div>' % (
            caps(lab, LIME), MONO, val, BONE3, dim))
    d.append('</div>')
    ob = ('<button style="height:40px; width:100%%; border:1px solid rgba(200,245,58,0.28); background:transparent; color:%s; cursor:pointer; font-family:%s; font-size:14px; font-weight:600; '
          'display:flex; align-items:center; justify-content:space-between; padding:0 12px"><span>%s</span>%s</button>')
    d.append('<div style="width:268px; flex:none; padding-left:24px; display:flex; flex-direction:column; justify-content:center; gap:10px">%s%s</div>' % (
        ob % (BONE, FONT, 'Fleet and refits', keycap('F')),
        ob % (BONE, FONT, 'Keep the dawn watch', '<span style="font-family:%s; font-size:13px; color:%s">40</span>' % (MONO, BONE2))))
    d.append('</div>')
    o.append('<div style="position:absolute; left:12px; top:936px">%s</div>' % chamfer('1896px', '132px', ''.join(d)))
    # the slab's two bracket marks
    for pos, brd in (('left:6px; top:1050px', 'border-left:2px solid; border-bottom:2px solid'), ('left:1896px; top:930px', 'border-right:2px solid; border-top:2px solid')):
        o.append('<div style="position:absolute; %s; width:18px; height:18px; box-sizing:border-box; %s; border-color:%s"></div>' % (pos, brd, LIME))
    o.append('</div>')
    return wrap('Option B: war table', ''.join(o))


# ---------------------------------------------------------------------------------------------------------
# Option C: briefing. A numbered route list on the left, large type, the map only marks 1, 2 and 3.
# ---------------------------------------------------------------------------------------------------------
def option_c():
    LW = 480
    T = (1.06, 1210 - LW, 640)
    MW = 1920 - LW
    o = ['<div style="width:1920px; height:1080px; box-sizing:border-box; position:relative; overflow:hidden; background:%s; color:%s; font-family:%s; font-size:15px; line-height:22px">' % (INK, BONE, FONT)]
    o.append('<div style="position:absolute; left:%dpx; top:0; width:%dpx; height:1080px; overflow:hidden">' % (LW, MW))
    o.append(scene(T, MW, 1080, lane_w=1.0, lane_a=0.18, next_w=2.5, stars=70, seed=11))
    order = {'REL': '1', 'BRK1': '2', 'UNK1': '3'}
    for n in NODES:
        x, y = tf(T, n[4], n[5])
        st = n[6]
        inner = []
        if st == 'current':
            inner.append('<span style="display:block; width:14px; height:14px; background:%s; transform:rotate(45deg)"></span>' % BONE)
            inner.append('<span style="position:absolute; left:50%%; top:36px; transform:translateX(-50%%); white-space:nowrap; text-align:center; font-size:14px; line-height:18px; color:%s; %s">'
                         '<span style="display:block; font-size:18px; line-height:24px; font-weight:600; color:%s">Engagement</span>Your fleet is here</span>' % (BONE2, HALO, BONE))
        elif st == 'next':
            sel = n[0] == 'REL'
            inner.append('<span style="display:flex; align-items:center; justify-content:center; width:34px; height:34px; box-sizing:border-box; background:%s; border:2px solid %s; '
                         'font-family:%s; font-size:17px; font-weight:700; color:%s">%s</span>' % (LIME if sel else INK, LIME, MONO, ON_LIME if sel else LIME, order[n[0]]))
            side = 'right:48px; text-align:right' if n[0] == 'BRK1' else 'left:48px; text-align:left'
            inner.append('<span style="position:absolute; %s; top:50%%; transform:translateY(-50%%); white-space:nowrap; font-size:20px; line-height:26px; font-weight:600; color:%s; %s">%s</span>' % (
                side, BONE, HALO, n[1]))
        else:
            inner.append(glyph(n[2], 14, BONE3, 1.4))
            inner.append(tip(n))
        if n[7]:
            inner.append('<span style="position:absolute; left:50%%; top:-8px; width:8px; height:8px; margin-left:-4px; background:%s; transform:rotate(45deg)"></span>' % ALERT)
        o.append('<button class="stop" aria-label="%s" style="position:absolute; left:%.1fpx; top:%.1fpx; width:34px; height:34px; padding:0; border:0; background:transparent; '
                 'cursor:pointer; display:flex; align-items:center; justify-content:center; color:%s; font-family:%s">%s</button>' % (n[1], x - 17, y - 17, BONE, FONT, ''.join(inner)))
    hx, hy = tf(T, BY['HOLD'][4], BY['HOLD'][5])
    o.append(CURSOR % (hx + 2, hy + 2))
    o.append('<div style="position:absolute; right:48px; top:44px; display:flex; gap:36px; font-size:15px; line-height:22px">'
             '<button class="plain" style="padding:0; border:0; background:transparent; color:%s; cursor:pointer">Map key</button>'
             '<button class="plain" style="padding:0; border:0; background:transparent; color:%s; cursor:pointer">Save and quit</button></div>' % (BONE2, BONE2))
    # one resource line, bottom right of the map
    o.append('<div style="position:absolute; right:48px; bottom:40px; display:flex; gap:48px; align-items:baseline">')
    for lab, val, dim in (('Credits', '120', ''), ('Command points', '6', '/10')):
        o.append('<div style="display:flex; gap:12px; align-items:baseline"><span style="font-size:14px; color:%s">%s</span><span style="font-family:%s; font-size:28px; line-height:32px; font-weight:700">%s<span style="color:%s; font-weight:500">%s</span></span></div>' % (
            BONE2, lab, MONO, val, BONE3, dim))
    o.append('</div>')
    o.append('</div>')

    # the briefing column
    c = ['<div style="position:absolute; left:0; top:0; width:%dpx; height:1080px; box-sizing:border-box; background:%s; border-right:1px solid %s; padding:40px 0 32px 0; display:flex; flex-direction:column">' % (LW, COL, HAIR)]
    c.append('<div style="padding:0 40px">')
    c.append('<div style="font-family:%s; font-size:13px; line-height:16px; color:%s">SECTOR I OF III<span style="margin-left:24px">JUMP 1 OF 8</span></div>' % (MONO, BONE2))
    c.append('<div style="margin-top:10px; font-size:40px; line-height:44px; font-weight:700; letter-spacing:0.04em; text-transform:uppercase">Old Battlefield</div>')
    c.append('<div style="margin-top:10px; color:%s">Held by Ashfall Hullbreakers. Ion season: shields recharge 25%% slower on both sides.</div>' % BONE2)
    c.append('</div>')
    c.append('<div style="margin-top:28px; padding:0 40px">%s</div>' % caps('Routes from Engagement', BONE2, 13, '0.14em'))
    rows = [('1', 'Relay', 'Fight against a Glasswrights picket', 1, 'Repairs', 'Shipyard', True),
            ('2', 'Breakthrough', 'Fight against Ashfall Hullbreakers', 1, 'Credits', 'Shipyard or Decapitation', False),
            ('3', 'Unknown signal', 'Event: anything can happen', 0, 'Unknown', 'Decapitation', False)]
    c.append('<div style="margin-top:10px">')
    for num, name, what, dg, rew, nxt, sel in rows:
        dtxt = ('%s<span style="margin-left:8px">%s</span>' % (pips(dg), DANGER[dg])) if dg else '<span style="color:%s">No fight</span>' % BONE2
        c.append('<button style="display:flex; gap:20px; width:100%%; box-sizing:border-box; padding:14px 40px; border:0; text-align:left; cursor:pointer; background:%s; color:%s; font-family:%s">'
                 '<span style="font-family:%s; font-size:30px; line-height:36px; font-weight:700; width:24px; flex:none; color:%s">%s</span>'
                 '<span style="flex:1; min-width:0; display:block">'
                 '<span style="display:flex; justify-content:space-between; align-items:baseline"><span style="font-size:22px; line-height:28px; font-weight:600">%s</span>'
                 '<span style="font-size:14px; line-height:20px">%s</span></span>'
                 '<span style="display:block; font-size:15px; line-height:22px; color:%s">%s</span>'
                 '<span style="display:block; font-size:14px; line-height:20px; color:%s">Reward <span style="color:%s">%s</span><span style="margin-left:20px">Then <span style="color:%s">%s</span></span></span>'
                 '</span></button>' % ('#161c16' if sel else 'transparent', BONE, FONT, MONO, LIME if sel else BONE3, num, name, dtxt, BONE2, what, BONE3, BONE, rew, BONE, nxt))
    c.append('</div>')
    c.append('<div style="padding:16px 40px 0 40px"><button style="width:100%%; height:56px; border:0; background:%s; color:%s; cursor:pointer; display:flex; align-items:center; justify-content:space-between; padding:0 20px; '
             'font-family:%s; font-size:17px; font-weight:700; letter-spacing:0.12em; text-transform:uppercase"><span>Jump to Relay</span>%s</button></div>' % (LIME, ON_LIME, FONT, keycap('Enter', True)))
    # nemesis
    c.append('<div style="margin:28px 40px 0 40px; padding-top:24px; border-top:1px solid %s; display:flex; gap:20px; align-items:flex-start">'
             '<img src="%s" alt="High Nadir Essane" width="88" height="88" style="display:block; width:88px; height:88px; object-fit:cover; flex:none">'
             '<div style="min-width:0"><div style="display:flex; justify-content:space-between; align-items:baseline">%s'
             '<button class="plain" style="padding:0; border:0; background:transparent; color:%s; cursor:pointer; font-size:14px; line-height:16px">Dossier</button></div>'
             '<div style="margin-top:4px; font-size:20px; line-height:26px; font-weight:600">High Nadir Essane</div>'
             '<div style="font-size:14px; line-height:20px; color:%s">Eclipse. Cruel: finishes crippled ships first.</div>'
             '<div style="margin-top:8px; display:flex; align-items:center; gap:10px; font-size:14px; line-height:16px; color:%s"><span>Hunt clock</span>%s<span style="font-family:%s; color:%s">0/4</span></div>'
             '</div></div>' % (HAIR, NEM, caps('Nemesis', ALERT, 13, '0.14em'), BONE2, BONE2, BONE2, pips(0, ALERT, IRON3, 16, 6), MONO, BONE))
    # fleet
    c.append('<div style="margin:auto 40px 0 40px; padding-top:24px; border-top:1px solid %s">' % HAIR)
    c.append('<div style="display:flex; justify-content:space-between; align-items:baseline">%s'
             '<button class="plain" style="padding:0; border:0; background:transparent; color:%s; cursor:pointer; font-size:14px; line-height:16px">Fleet and refits</button></div>' % (caps('Fleet', BONE2, 13, '0.14em'), BONE2))
    for name, cls, hp, mx, flag in FLEET:
        c.append('<div style="margin-top:10px; display:flex; align-items:center; gap:16px">'
                 '<div style="flex:1; min-width:0; font-size:16px; line-height:22px; font-weight:600">%s%s<span style="margin-left:10px; font-size:14px; font-weight:400; color:%s">%s</span></div>'
                 '<div style="width:72px; height:3px; background:%s; flex:none"><div style="height:3px; width:100%%; background:%s"></div></div>'
                 '<div style="width:64px; flex:none; text-align:right; font-family:%s; font-size:14px; line-height:22px">%s<span style="color:%s">/%s</span></div></div>' % (
                     (STAR % BONE) if flag else '', name, BONE3, cls, IRON3, BONE2, MONO, hp, BONE3, mx))
    c.append('<div style="margin-top:14px; display:flex; justify-content:space-between; align-items:baseline; font-size:14px; line-height:20px; color:%s"><span>Faction action: <span style="color:%s">Keep the dawn watch</span></span>'
             '<span style="font-family:%s">40 credits</span></div>' % (BONE2, BONE, MONO))
    c.append('</div></div>')
    o.append(''.join(c))
    o.append('</div>')
    return wrap('Option C: briefing', ''.join(o))


files = {'Main.dc.html': option_a(), 'OptionB.dc.html': option_b(), 'OptionC.dc.html': option_c()}
for name, (dc, pv) in files.items():
    open(os.path.join(OUT, name), 'w').write(dc)
    open(os.path.join(PREV, name.replace('.dc.html', '.html')), 'w').write(pv)
    print(name, len(dc))

now = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.000Z')
canvas = {"v": 3, "createdOnFiles": {"v": 1, "at": now}, "title": "Campaign map: three design options",
          "launch": {"view": "canvas"}, "pages": [],
          "boards": {"Main.dc.html": {"x": 0, "y": 0, "w": 1920, "h": 1080, "title": "A: Star chart", "is_interactive": True},
                     "OptionB.dc.html": {"x": 2000, "y": 0, "w": 1920, "h": 1080, "title": "B: War table", "is_interactive": True},
                     "OptionC.dc.html": {"x": 4000, "y": 0, "w": 1920, "h": 1080, "title": "C: Briefing", "is_interactive": True}},
          "order": ["Main.dc.html", "OptionB.dc.html", "OptionC.dc.html"], "notes": {}, "designSystems": []}
json.dump(canvas, open(os.path.join(OUT, 'canvas.json'), 'w'), indent=1)
