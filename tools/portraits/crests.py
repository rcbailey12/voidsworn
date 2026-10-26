# Admiral crests (R37: crest symbols instead of portraits for now; R40: crests for every admiral without a painting).
# One SVG per admiral in godot/portraits/crests/<id>.svg (512 x 512, transparent outside the crest; Godot imports SVG
# directly), built from: the faction's frame shape and colours (data.js FACTIONS hull/trim/glow) + a glyph for the
# admiral's Command (barrage, hunt, scramble, iron, surge, restore), drawn in the faction's line style.
# No text, no lettering. Run: python3 tools/portraits/crests.py  (also writes the crest contact sheet when cairosvg is present)
import math, os, random, re, json
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(REPO, 'godot', 'portraits', 'crests')

FAC = {  # data.js FACTIONS colours; field = a dark tint of the hull colour so every crest reads on dark UI
 'voidsworn': dict(hull='#4a4440', trim='#c8501f', glow='#ff7a2a', field=('#2a2420', '#120e0c')),
 'hegemony':  dict(hull='#c4ccd5', trim='#3a78d0', glow='#5fa0ff', field=('#1d2836', '#0b1018')),
 'corsair':   dict(hull='#6a2c22', trim='#b8402a', glow='#e0402c', field=('#2e1612', '#120806')),
 'chorus':    dict(hull='#57364c', trim='#a4913a', glow='#d6d24a', field=('#34202e', '#140a12')),
 'ithar':     dict(hull='#eef3f1', trim='#d7c88a', glow='#9fffd2', field=('#1c2a2a', '#0a1212')),
 'deathless': dict(hull='#1d2220', trim='#1fbf4a', glow='#3dff6a', field=('#141a17', '#060808')),
}
# admiral -> (faction, command id), from data.js ADMIRALS
ADM = {
 'vex': ('voidsworn', 'barrage'), 'malek': ('voidsworn', 'hunt'), 'ashgrove': ('voidsworn', 'scramble'), 'thale': ('voidsworn', 'iron'),
 'kassar': ('hegemony', 'barrage'), 'vorn': ('hegemony', 'hunt'), 'reyes': ('hegemony', 'scramble'), 'maren': ('hegemony', 'iron'),
 'grax': ('corsair', 'surge'), 'sable': ('corsair', 'hunt'), 'mott': ('corsair', 'scramble'), 'vesh': ('corsair', 'restore'),
 'matriarch': ('chorus', 'scramble'), 'razormaw': ('chorus', 'surge'), 'mending': ('chorus', 'restore'), 'voice': ('chorus', 'barrage'),
 'aelith': ('ithar', 'scramble'), 'vaelen': ('ithar', 'barrage'), 'thorne': ('ithar', 'surge'), 'mirelle': ('ithar', 'iron'),
 'nekhet': ('deathless', 'restore'), 'sekhmar': ('deathless', 'barrage'), 'anuket': ('deathless', 'hunt'), 'khepra': ('deathless', 'iron'),
}
NAMES = {'vex': 'Castellan Vex', 'malek': 'Malek Draven', 'ashgrove': 'Sera Ashgrove', 'thale': 'Oryn Thale', 'kassar': 'Ilsa Kassar',
 'vorn': 'Dace Vorn', 'reyes': 'Corin Reyes', 'maren': 'Oskar Maren', 'grax': 'Grax Ironjaw', 'sable': 'Sable Venn', 'mott': 'Old Mott',
 'vesh': 'Vesh the Collector', 'matriarch': 'The Matriarch', 'razormaw': 'Razormaw', 'mending': 'The Mending Choir', 'voice': 'Voice of the Deep',
 'aelith': 'Aelith Dawnsail', 'vaelen': 'Seraph Vaelen', 'thorne': 'Thorne of the Veil', 'mirelle': 'Mirelle Starwarden',
 'nekhet': 'Nekhet the Undying', 'sekhmar': 'Sekhmar the Reaper', 'anuket': 'Cryptlord Anuket', 'khepra': 'Khepra the Patient'}
# line style per faction: stroke width, caps, joins, jitter (px, for hand-made or grown looks)
STY = {
 'voidsworn': dict(w=17, cap='butt', join='miter', jit=0), 'hegemony': dict(w=13, cap='butt', join='miter', jit=0),
 'corsair': dict(w=17, cap='square', join='bevel', jit=5), 'chorus': dict(w=21, cap='round', join='round', jit=7),
 'ithar': dict(w=9, cap='round', join='round', jit=0), 'deathless': dict(w=13, cap='square', join='miter', jit=0),
}
C = 256

def f(v): return ('%.1f' % v).rstrip('0').rstrip('.')
def pts(P): return ' '.join(f(x) + ',' + f(y) for x, y in P)
def poly(P, close=False): return 'M' + ' L'.join(f(x) + ' ' + f(y) for x, y in P) + (' Z' if close else '')

def smooth_closed(P):
    # Catmull-Rom through the points, as cubic Beziers (organic outlines)
    n = len(P); d = 'M%s %s' % (f(P[0][0]), f(P[0][1]))
    for i in range(n):
        p0, p1, p2, p3 = P[i - 1], P[i], P[(i + 1) % n], P[(i + 2) % n]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6); c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d += ' C%s %s %s %s %s %s' % (f(c1[0]), f(c1[1]), f(c2[0]), f(c2[1]), f(p2[0]), f(p2[1]))
    return d + ' Z'

def frame(fac, rnd):
    """outer crest outline path (d) for the faction, plus extra decoration svg drawn behind/around"""
    if fac == 'voidsworn':   # gothic shield with a spire
        d = 'M256 58 Q352 70 420 116 L420 286 Q420 398 256 474 Q92 398 92 286 L92 116 Q160 70 256 58 Z'
        deco = '<path d="M256 14 L270 58 L242 58 Z" fill="{trim}"/><path d="M228 40 L284 40" stroke="{trim}" stroke-width="7"/>'
        return d, deco
    if fac == 'hegemony':    # clean wedge
        return 'M256 46 L430 118 L430 300 L256 470 L82 300 L82 118 Z', ''
    if fac == 'corsair':     # chipped, riveted plate (not symmetric on purpose)
        base = [(118, 70), (300, 54), (404, 92), (440, 230), (412, 352), (318, 452), (168, 464), (90, 380), (66, 214), (92, 120)]
        P = [(x + rnd.uniform(-6, 6), y + rnd.uniform(-6, 6)) for x, y in base]
        rv = ''.join('<circle cx="%s" cy="%s" r="6" fill="{trim}"/>' % (f(C + (x - C) * 0.9), f(C + (y - C) * 0.9)) for x, y in P[::2])
        return poly(P, True), rv
    if fac == 'chorus':      # grown membrane blob
        P = []
        for i in range(11):
            a = i / 11 * math.tau - math.pi / 2; r = 196 + rnd.uniform(-20, 16)
            P.append((C + r * math.cos(a) * 0.98, 262 + r * math.sin(a)))
        spores = ''.join('<circle cx="%s" cy="%s" r="%s" fill="{glow}" opacity="0.55"/>' % (f(C + 230 * math.cos(a)), f(262 + 226 * math.sin(a)), f(rnd.uniform(4, 9)))
                         for a in [rnd.uniform(0, math.tau) for _ in range(7)])
        return smooth_closed(P), spores
    if fac == 'ithar':       # tall lens with rays of light behind
        rays = ''.join('<path d="M256 262 L%s %s" stroke="{glow}" stroke-width="3" opacity="0.35" stroke-linecap="round"/>' % (f(C + 250 * math.cos(a)), f(262 + 250 * math.sin(a)))
                       for a in [math.radians(-90 + k * 22.5) for k in range(16)])
        return 'M256 24 C446 150 446 374 256 500 C66 374 66 150 256 24 Z', rays
    if fac == 'deathless':   # broken ring around a dark disc
        segs = ''
        for k in range(8):
            a0 = math.radians(k * 45 + 6); a1 = math.radians(k * 45 + 39); R = 218
            segs += '<path d="M%s %s A%d %d 0 0 1 %s %s" stroke="{trim}" stroke-width="12" fill="none"/>' % (
                f(C + R * math.cos(a0)), f(262 + R * math.sin(a0)), R, R, f(C + R * math.cos(a1)), f(262 + R * math.sin(a1)))
        return 'M256 66 A196 196 0 1 1 255.9 66 Z', segs
    raise KeyError(fac)

def J(P, rnd, j):
    return [(x + rnd.uniform(-j, j), y + rnd.uniform(-j, j)) for x, y in P] if j else P

def glyph(cmd, fac, rnd):
    """list of (kind, data) strokes in a box around (256, 266)"""
    s = STY[fac]; j = s['jit']; L = []  # ('line', pts) open polyline; ('fill', pts) closed filled; ('circle', (cx, cy, r)); ('arc', (cx, cy, r, a0, a1))
    y0 = 266
    if cmd == 'barrage':     # a volley: three beams fanning out from one battery
        for dx, top in ((-74, 176), (0, 150), (74, 176)):
            bx, by = C + dx * 0.35, y0 + 96; tx, ty = C + dx, y0 - (y0 - top) - 10
            L.append(('line', J([(bx, by), (tx, ty)], rnd, j)))
            ang = math.atan2(ty - by, tx - bx); h = 26
            tip = [(tx + h * math.cos(ang), ty + h * math.sin(ang)), (tx + 12 * math.cos(ang + 2.2), ty + 12 * math.sin(ang + 2.2)), (tx + 12 * math.cos(ang - 2.2), ty + 12 * math.sin(ang - 2.2))]
            L.append(('fill', J(tip, rnd, j * 0.5)))
        L.append(('line', J([(C - 70, y0 + 112), (C + 70, y0 + 112)], rnd, j)))
    elif cmd == 'hunt':      # crosshair and a blade through it
        L.append(('circle', (C, y0, 70)))
        for a in range(4):
            t = a * math.pi / 2; L.append(('line', [(C + 50 * math.cos(t), y0 + 50 * math.sin(t)), (C + 104 * math.cos(t), y0 + 104 * math.sin(t))]))
        bl = [(C - 96, y0 + 96), (C + 82, y0 - 82), (C + 104, y0 - 104), (C + 92, y0 - 70)]
        L.append(('fill', J([(C - 104, y0 + 104), (C + 70, y0 - 92), (C + 112, y0 - 112), (C + 92, y0 - 70)], rnd, j * 0.5)))
    elif cmd == 'scramble':  # wings launching: a swept chevron and a formation of craft
        L.append(('line', J([(C - 120, y0 + 70), (C, y0 - 10), (C + 120, y0 + 70)], rnd, j)))
        L.append(('line', J([(C - 84, y0 + 112), (C, y0 + 50), (C + 84, y0 + 112)], rnd, j)))
        for dx, dy in ((0, -110), (-46, -74), (46, -74), (-92, -38), (92, -38)):
            x, y = C + dx, y0 + dy
            L.append(('fill', J([(x, y - 16), (x + 11, y + 10), (x, y + 4), (x - 11, y + 10)], rnd, j * 0.4)))
    elif cmd == 'iron':      # shield wall: an arch over stacked plates
        L.append(('arc', (C, y0 - 10, 96, 180, 360)))
        for k, w in enumerate((96, 96, 80)):
            yy = y0 + 4 + k * 38
            L.append(('line', J([(C - w, yy), (C + w, yy)], rnd, j)))
        L.append(('line', J([(C - 96, y0 - 10), (C - 96, y0 + 4)], rnd, j))); L.append(('line', J([(C + 96, y0 - 10), (C + 96, y0 + 4)], rnd, j)))
    elif cmd == 'surge':     # full burn: stacked chevrons and burn trails
        for k in range(3):
            yy = y0 - 70 + k * 52
            L.append(('line', J([(C - 96, yy + 56), (C, yy), (C + 96, yy + 56)], rnd, j)))
        for dx in (-46, 0, 46):
            L.append(('line', J([(C + dx, y0 + 92), (C + dx, y0 + 128 - abs(dx) * 0.3)], rnd, j * 0.5)))
    elif cmd == 'restore':   # a broken ring knitting closed: the gap bridged by thread and crossed by stitches
        L.append(('arc', (C, y0, 88, -20, 250)))
        L.append(('dash', (C, y0, 88, 250, 340)))
        for k in range(4):
            a = math.radians(256 + k * 25); r0, r1 = 64, 112
            L.append(('line', J([(C + r0 * math.cos(a), y0 + r0 * math.sin(a)), (C + r1 * math.cos(a), y0 + r1 * math.sin(a))], rnd, j * 0.4)))
        L.append(('circle_fill', (C, y0, 26)))
    return L

def stroke_svg(L, color, w, cap, join, opacity=1.0):
    o = []
    att = 'stroke="%s" stroke-width="%s" stroke-linecap="%s" stroke-linejoin="%s" fill="none"%s' % (color, f(w), cap, join, '' if opacity >= 1 else ' opacity="%s"' % f(opacity))
    fat = 'fill="%s"%s' % (color, '' if opacity >= 1 else ' opacity="%s"' % f(opacity))
    for k, d in L:
        if k == 'line': o.append('<path d="%s" %s/>' % (poly(d), att))
        elif k == 'fill': o.append('<path d="%s" %s stroke="%s" stroke-width="%s" stroke-linejoin="%s"/>' % (poly(d, True), fat, color, f(w * 0.25), join))
        elif k == 'circle': o.append('<circle cx="%s" cy="%s" r="%s" %s/>' % (f(d[0]), f(d[1]), f(d[2]), att))
        elif k == 'circle_fill': o.append('<circle cx="%s" cy="%s" r="%s" %s/>' % (f(d[0]), f(d[1]), f(d[2] + w * 0.3), fat))
        elif k == 'dash':
            cx, cy, r, a0, a1 = d; a0, a1 = math.radians(a0), math.radians(a1)
            o.append('<path d="M%s %s A%s %s 0 0 1 %s %s" %s stroke-dasharray="%s %s"/>' % (f(cx + r * math.cos(a0)), f(cy + r * math.sin(a0)), f(r), f(r), f(cx + r * math.cos(a1)), f(cy + r * math.sin(a1)), att.replace('stroke-width="%s"' % f(w), 'stroke-width="%s"' % f(w * 0.45)), f(w * 0.8), f(w * 0.9)))
        elif k == 'arc':
            cx, cy, r, a0, a1 = d; a0, a1 = math.radians(a0), math.radians(a1)
            large = 1 if (a1 - a0) % math.tau > math.pi or (a1 - a0) >= math.tau * 0.75 else 0
            o.append('<path d="M%s %s A%s %s 0 %d 1 %s %s" %s/>' % (f(cx + r * math.cos(a0)), f(cy + r * math.sin(a0)), f(r), f(r), large, f(cx + r * math.cos(a1)), f(cy + r * math.sin(a1)), att))
    return '\n'.join(o)

def crest(aid):
    fac, cmd = ADM[aid]; c = FAC[fac]; s = STY[fac]; rnd = random.Random(aid)
    d, deco = frame(fac, rnd)
    G = glyph(cmd, fac, rnd)
    deco = deco.replace('{trim}', c['trim']).replace('{glow}', c['glow'])
    behind = deco if fac in ('ithar',) else ''
    front = '' if fac in ('ithar',) else deco
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
<defs><radialGradient id="g" cx="0.38" cy="0.4" r="0.75"><stop offset="0" stop-color="{c['field'][0]}"/><stop offset="1" stop-color="{c['field'][1]}"/></radialGradient>
<clipPath id="k"><path d="{d}"/></clipPath></defs>
{behind}
<path d="{d}" fill="url(#g)"/>
<g clip-path="url(#k)"><path d="M0 0 L300 0 L120 512 L0 512 Z" fill="{c['glow']}" opacity="0.05"/></g>
<path d="{d}" fill="none" stroke="{c['trim']}" stroke-width="10" stroke-linejoin="round"/>
<path d="{d}" fill="none" stroke="{c['glow']}" stroke-width="2.5" opacity="0.5" transform="translate(256 262) scale(0.9) translate(-256 -262)" stroke-linejoin="round"/>
{front}
<g clip-path="url(#k)">
{stroke_svg(G, c['glow'], s['w'] * 2.6, s['cap'], s['join'], 0.16)}
{stroke_svg(G, c['glow'], s['w'], s['cap'], s['join'])}
{stroke_svg(G, '#ffffff', max(2.0, s['w'] * 0.22), s['cap'], s['join'], 0.45)}
</g>
</svg>
'''
    return re.sub(r'\n\s*\n', '\n', svg)

def sheet(paths, out, cols=6, cell=300, title=None):
    from PIL import Image, ImageDraw, ImageFont
    import cairosvg, io
    rows = (len(paths) + cols - 1) // cols; W, H = cols * cell, rows * (cell + 34) + (50 if title else 0)
    im = Image.new('RGB', (W, H), (14, 14, 18)); dr = ImageDraw.Draw(im)
    try: font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 18); tf = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 26)
    except Exception: font = tf = ImageFont.load_default()
    y0 = 0
    if title: dr.text((16, 12), title, fill=(230, 230, 230), font=tf); y0 = 50
    for i, (p, label) in enumerate(paths):
        png = cairosvg.svg2png(url=p, output_width=cell - 30, output_height=cell - 30)
        t = Image.open(io.BytesIO(png)).convert('RGBA'); x, y = (i % cols) * cell, y0 + (i // cols) * (cell + 34)
        im.paste(t, (x + 15, y + 8), t)
        w = dr.textlength(label, font=font); dr.text((x + (cell - w) / 2, y + cell - 14), label, fill=(210, 210, 210), font=font)
    im.save(out, 'WEBP', quality=88); return out

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for aid in ADM:
        open(os.path.join(OUT, aid + '.svg'), 'w').write(crest(aid))
    json.dump({a: {'faction': ADM[a][0], 'command': ADM[a][1], 'file': 'crests/' + a + '.svg'} for a in ADM},
              open(os.path.join(OUT, 'index.json'), 'w'), indent=1)
    print('wrote', len(ADM), 'crests to', OUT)
    try:
        sd = os.path.join(REPO, 'godot', 'portraits', 'sheets'); os.makedirs(sd, exist_ok=True)
        print(sheet([(os.path.join(OUT, a + '.svg'), NAMES[a]) for a in ADM], os.path.join(sd, 'crests_all.webp'), title='Voidsworn admiral crests (one per admiral; glyph = Command)'))
    except ImportError as e: print('no sheet:', e)
