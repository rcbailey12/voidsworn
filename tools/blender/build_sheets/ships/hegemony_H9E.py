"""Spineguard, the Directorate cruiser. +X bow, +Y port, +Z deck."""

from ships.hegemony_H8 import offset_loop, tube
from ships.hegemony_H10 import ion_trench

CODE = 'hegemony_H9E'
NAME = 'H9E Spineguard | Vanguard cruiser'
FACTION = 'Meridian Directorate (hegemony)'
CLASS = 'Cruiser'
LENGTH = 14.5
GAME = 'data.js h_vanguard (Godot rules table), Cruiser length and H9_23 from hull_table.gd'
KIT = 'hegemony'
BEAUTY = 'docs/ship_pipeline/build_sheets/hegemony_H9E/concept_beauty.png'
CONCEPT_SHEET = 'docs/shots/issue-2094-codex/vanguard_sheet_e.png'
CONCEPT_VIEWS = dict(top=dict(box=(114, 187, 565, 354), largest=True, flip=False),
                     side=dict(box=(114, 418, 565, 549), largest=True, flip=False))
SHEET = dict(version=1, round='2094 run 4', date='2026-11-27', blend='generated from recipe sheet')

BOW = LENGTH / 2
STERN = -LENGTH / 2
TRANSOM = STERN + 0.41
JOINTS = (0.55, -3.35)
HOOPS = (4.65, 2.35, -0.42, -2.32)
SHELL = 0.15
BORE_ROOT = 6.40
BORE_Z = 0.74
BORE_HALF = (0.53, 0.35)

# Station, half beam, deck, belly. One saddle closes the space below the gun.
KEYS = (
    (6.63, 0.99, 0.29, -0.54),
    (6.29, 1.21, 0.35, -0.71),
    (4.78, 1.86, 0.50, -0.86),
    (2.72, 2.52, 0.65, -1.04),
    (1.80, 2.52, 0.65, -1.04),
    (-0.78, 1.80, 0.61, -0.93),
    (-1.75, 1.80, 0.61, -0.89),
    (-3.20, 2.12, 0.73, -0.86),
    (-4.47, 2.30, 0.84, -0.80),
    (-6.54, 2.30, 0.84, -0.80),
    (TRANSOM, 2.18, 0.78, -0.72),
)
SECTIONS = [(x, w, w, b, d, 0.0, 0.0, 0.0) for x, w, d, b in KEYS]


def section(x):
    for a, b in zip(KEYS, KEYS[1:]):
        if a[0] >= x >= b[0]:
            t = (a[0] - x) / (a[0] - b[0])
            return tuple(p + (q - p) * t for p, q in zip(a[1:], b[1:]))
    return (KEYS[0] if x > KEYS[0][0] else KEYS[-1])[1:]


def ring(x):
    w, d, b = section(x)
    half = [(0, d), (w - 0.32, d), (w, d - 0.28),
            (w, b + 0.32), (w - 0.35, b), (0, b)]
    return [(x, y, z) for y, z in half + [(-y, z) for y, z in reversed(half[1:-1])]]


def stations(hi, lo):
    """Keep the authored corners when subdividing the surface for strips and panels."""
    return sorted({hi, lo, *(row[0] for row in KEYS if lo < row[0] < hi)}, reverse=True)


def collar(K, HP):
    hw, hh = BORE_HALF
    # The outside is chamfered, but the bore walls meet the standard trench liner.
    profiles = ((BORE_ROOT, 0.85, 0.67), (6.54, 0.99, 0.74),
                (7.10, 0.99, 0.74), (BOW, 0.87, 0.64))
    outer = [HP.octa(w, h, 0.20) for _, w, h in profiles]
    # Follow the octagon's vertex order on the inside so each annulus is closed.
    inner = [(y / max(abs(y) / hw, abs(z) / hh),
              z / max(abs(y) / hw, abs(z) / hh)) for y, z in outer[-1]]
    loops = [(x, loop) for (x, _, _), loop in zip(profiles, outer)]
    loops += [(BOW, inner), (BORE_ROOT, inner)]
    verts = [(x, y, z + BORE_Z) for x, loop in loops for y, z in loop]
    faces = [(8 * k + i, 8 * k + (i + 1) % 8, 8 * ((k + 1) % len(loops)) + (i + 1) % 8,
              8 * ((k + 1) % len(loops)) + i) for k in range(len(loops)) for i in range(8)]
    ob = K._obj('H9E_bow_collar', verts, faces, 'hgrey', grp='hull')
    K.mass('Bow collar', ob, 'pale plate', note='chamfered external frame, recessed kit accelerator')
    ion_trench(K, (BORE_ROOT, 0, BORE_Z), BOW - BORE_ROOT, 2 * hw, 2 * hh, coils=2, r=0.29)


def spine(K, HP):
    def profile(x, w, h, z):
        return [(x, y, p + z) for y, p in HP.octa(w, h, 0.18)]

    ob = K.loft_rings('H9E_spinal_jacket', [
        profile(6.46, 0.78, 0.51, 0.69), profile(6.13, 0.82, 0.55, 0.69),
        profile(-2.91, 0.82, 0.55, 0.69), profile(-3.32, 0.81, 0.49, 0.65),
        profile(-3.95, 0.76, 0.30, 0.70),
    ], 'hgrey', grp='hull')
    K.mass('Spinal jacket', ob, 'pale plate', note='a low, continuous jacket seated in the armour')
    for i, x in enumerate(HOOPS, 1):
        ob = K.loft_rings(f'H9E_capacitor_hoop_{i}', [
            profile(x + 0.19, 0.89, 0.57, 0.69), profile(x + 0.11, 0.99, 0.65, 0.69),
            profile(x - 0.11, 0.99, 0.65, 0.69), profile(x - 0.19, 0.89, 0.57, 0.69),
        ], 'htrim', grp='hull')
        K.fitting(f'C{i}', 'armoured capacitor hoop', (x, 0, 1.34), note='one low raised clamp over the jacket')
        K.box(f'H9E_hoop_contact_{i}', x - 0.073, x + 0.073, -0.24, 0.24, 1.329, 1.347,
              'hblue', ch=0.009, grp='hull')
        for side in (1, -1):
            K.strip(f'H9E_hoop_side_{i}_{side}', [(x, side * 0.986, 1.02), (x, side * 0.986, 1.11)],
                    w=0.07, t=0.014, normals=[(0, side, 0)] * 2, m='hblue', grp='hull')


def fittings(K, HP):
    for i, y in enumerate((1.92, -1.92), 1):
        x = 2.43
        deck = section(x)[1]
        K.cyl(f'H9E_lance_seat_{i}', (x, y, deck - 0.02), (x, y, deck + 0.20), 0.55,
              'hgrey2', r1=0.51, n=8, grp='hull')
        K.gun(f'T{i}', (x, y, deck + 0.325), 0, barrels=2, cal=0.085, blen=0.49,
              size=0.72, slot='T', weapon='turbo', inv='lance', note='one of the rules-listed Plasma lances')
    for i, y in enumerate((1.50, 0.50, -0.50, -1.50), 1):
        K.engine(f'E{i}', (STERN + 0.02, y, -0.02), 0.30, 0.70, bell=1.0, body_r=0.40,
                 kw=dict(w=0.74, h=0.62), inv='engines', note='rectangular blue-white nozzle in the transom row')
    x = -5.36
    K.organ('A1', HP.antenna(0.15, L=1.05, t=0.22), (x, 0, section(x)[1]), (0, 0, 1),
            kind='antenna', inv='sensor_fin', what='one low sensor fin')
    for side, tag in ((1, 'p'), (-1, 's')):
        x = -5.37
        w = section(x)[0]
        K._surface_part('D' + tag, HP.bay(0.37, 1.09), (x, side * w, 0.25), (0, side, 0), (1, 0, 0),
                        'drone_doors', 'flush drone doors', 'bay', 'picture', 'one hangar, mirrored exit doors')
        K.point('bay', 'hp_bay_' + tag, (x, side * (w + 0.064), 0.25), dir=(0, side, 0))
        x = 5.93
        K.thruster('Q' + tag, (x, side * section(x)[0], -0.12), (0.40, side * 0.92, 0),
                   inv='thrusters', r=0.10)
        for i, x in enumerate((1.27, -3.79), 1):
            slope = -0.28 if i == 1 else 0.14
            K.slit(f'W{i}{tag}', (x, side * (section(x)[0] + 0.018), -0.19), (slope, side, 0),
                   0.33, 0.065, inv='windows')
        x = -4.58
        K.vent('V1' + tag, (x, side * 0.84, section(x)[1]), (0, 0, 1), 0.27, 0.52, inv='vents')
        x = -1.26
        K.vent('V2' + tag, (x, side * 0.80, section(x)[2]), (0, 0, -1), 0.26, 0.51, inv='vents')
        for i, j in enumerate(JOINTS, 1):
            x = j - 0.24
            K.organ(f'L{i}{tag}', HP.latch(n=3, pitch=0.16, w=0.12), (x, side * 1.22, section(x)[1]),
                    (0, 0, 1), kind='latch', inv='latches', what='recessed joint latch row')
        K.point('rcs', 'hp_rcs_' + tag, (5.92, side * section(5.92)[0], 0), side='port' if side > 0 else 'stbd')
        K.point('board', 'hp_board_' + tag, (-1.50, side * section(-1.50)[0], 0), side='port' if side > 0 else 'stbd')
        for i, x in enumerate(JOINTS, 1):
            # Alternate the lip of each joint so the middle module has anchors too.
            anchor = x + 0.17 * (1 if side > 0 else -1)
            region = ('prow' if i == 1 else 'mid') if side > 0 else ('mid' if i == 1 else 'eng')
            K.point('breach', f'hp_breach_{i}{tag}', (anchor, side * section(anchor)[0], -0.16),
                    side='port' if side > 0 else 'stbd', section=region)
    for i, (x, direction) in enumerate(((-6.42, 1), (3.6, -1)), 1):
        z = section(x)[1 if direction > 0 else 2]
        K.hatch(f'H{i}', (x, 0, z), (0, 0, direction), 0.43, 0.34, inv='hatches')


def finish_shell(K, HP):
    for i, x in enumerate(JOINTS, 1):
        loop = [(y, z) for _, y, z in ring(x)]
        for j, (lo, hi) in enumerate(((x - 0.13, x - 0.036), (x + 0.036, x + 0.13))):
            tube(K, f'H9E_joint_{i}_{j}', lo, hi, offset_loop(loop, 0.066), offset_loop(loop, -0.09), 'htrim')
        tube(K, f'H9E_joint_recess_{i}', x - 0.038, x + 0.038,
             offset_loop(loop, 0.026), offset_loop(loop, -0.044), 'hgrey2')
    edges = (KEYS[0][0], *JOINTS, TRANSOM)
    for i, (hi, lo) in enumerate(zip(edges, edges[1:]), 1):
        for side in (1, -1):
            pts = [(x, side * (section(x)[0] + 0.003), -0.03)
                   for x in stations(hi - 0.25, lo + 0.23)]
            K.strip(f'H9E_line_{i}_{side}', pts, w=0.059, t=0.022, normals=[(0, side, 0)] * len(pts),
                    m='hblue', grp='hull')
        steps = int((hi - lo) / 0.45)
        grid = set(stations(hi - 0.15, lo + 0.15))
        grid.update(hi - 0.15 - j * (hi - lo - 0.30) / steps for j in range(1, steps))
        rings = [ring(x) for x in sorted(grid, reverse=True)]

        def keep(p, radius):
            # Reserve the spine's saddle and every kit mount before laying plate courses.
            return (abs(p.y) < 0.90 and -4.00 < p.x and p.z > 0.12
                    or any((p - c).length < r + radius * 0.6 for c, r in K.keepouts))

        for tag, faces in (('deck', (0, 9)), ('flank', (1, 3, 6, 8)), ('belly', (4, 5))):
            acc, _ = HP.module_panels(rings, faces, pv=0.32, keep=keep, unit=0.74)
            for material, (verts, faces_) in acc.items():
                if verts:
                    K._obj(f'H9E_{tag}_{i}_panels_{material}', verts, faces_, material, grp='hull')


def interior(K):
    for name, lo, hi in zip(('stern', 'midships', 'bow'),
                            (TRANSOM + 0.18, JOINTS[1] + 0.09, JOINTS[0] + 0.09),
                            (JOINTS[1] - 0.09, JOINTS[0] - 0.09, BORE_ROOT - 0.12)):
        K.deck(name + '_main', -0.23, lo, hi, inset=0.50)
        K.deck(name + '_service', -0.43, lo, hi, inset=0.59)
        for i, t in enumerate((0.08, 0.50, 0.92)):
            K.bulkhead(f'{name}_{i}', lo + (hi - lo) * t, inset=0.35, t=0.10)
        K.room(name + '_corridor', 'hcorr', lo + 0.13, hi - 0.13, -0.25, 0.25, -0.17, 0.14,
               note='pale crew corridor along the main deck')
        K.room(name + '_emergency', 'hemerg', lo + 0.15, hi - 0.15, -0.055, 0.055, 0.15, 0.18)
        for side, tag in ((1, 'p'), (-1, 's')):
            y0, y1 = sorted((side * 0.39, side * 0.74))
            K.room(name + '_racks_' + tag, 'hrack', lo + 0.25, (lo + hi) / 2, y0, y1, -0.16, 0.10)
    K.room('ion_capacitors', 'machinery', 3.56, 5.63, 0.34, 0.80, -0.16, 0.14)
    K.room('plasma_feed', 'magazine', 1.0, 2.85, -1.20, -0.35, -0.16, 0.20)
    K.room('plasma_distribution', 'magazine', -0.85, 0.30, 0.39, 0.88, -0.62, -0.47)
    K.room('reactor', 'core', -2.39, -0.92, -0.38, 0.38, -0.65, -0.45)
    K.room('engine_room', 'engroom', -6.60, -5.61, -1.08, 1.08, -0.15, 0.29)
    K.room('drone_handling', 'hold', -5.58, -4.03, -1.24, 1.24, -0.15, 0.29)
    K.point('core', 'hp_core', (-1.68, 0, -0.52))
    K.armour('saddle', SHELL, 'inward shell and dark liner, behind the plate grid')
    for i, x in enumerate(JOINTS, 1):
        K.break_line(f'B-{i}', x, 'module ring fails first, then the ragged interior frames tear',
                     path=[(x, 2.65), (x, 1.37), (x + 0.09, 0.59), (x - 0.09, 0.0),
                           (x + 0.07, -0.53), (x, -1.40), (x, -2.65)])


def build(K):
    import kit
    HP = kit.HP
    for name, material in HP.MATS.items():
        kit.MATS.setdefault(name, material)
    K.hull_sections = SECTIONS
    K.hull_rounded = False
    shell = K.loft_rings('H9E_saddle', [ring(row[0]) for row in KEYS], 'hgrey', grp='hull')
    md = shell.modifiers.new('shell', 'SOLIDIFY')
    md.thickness, md.offset, md.use_rim = SHELL, -1, True
    K.mass('Armoured saddle', shell, 'pale module plate',
           note='wide shoulders, pinched waist, solid transom and an armoured flat belly')
    spine(K, HP)
    collar(K, HP)
    fittings(K, HP)
    finish_shell(K, HP)
    interior(K)
    for name in HP.METALLIC:
        kit.mat(name).node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value = 0.35
    K.colour('Pale steel-grey', BOW, STERN, 'even hull panel grid')
    K.colour('Steel-blue trim', BOW, STERN, 'joint rings, capacitor hoops and drive lips')
    K.colour('Implant-blue', BOW, STERN, 'interrupted flank line, recessed contacts and drive throats')
    K.change('Lower the bow collar and run its gun into the solid saddle.', 'Use the family accelerator and keep the four low hoops.')
    K.change('Flatten the deep keel and segment the light line.', 'Picket and Cordon set the faceted belly and panel language.')
    K.change('Add launch origins to the two flush flank doors.', 'Both serve the one hangar already in the Vanguard rules.')
