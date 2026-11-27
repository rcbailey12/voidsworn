"""Spineguard, the Directorate cruiser. +X bow, +Y port, +Z deck."""

from ships.hegemony_H8 import offset_loop, tube

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
SHEET = dict(version=2, round='2094 run 5', date='2026-11-27', blend='built from recipe sheet')

BOW = LENGTH / 2
STERN = -LENGTH / 2
TRANSOM = STERN + 0.41
JOINTS = (0.55, -3.35)
HOOPS = (4.65, 1.27, -0.42, -2.32)  # The second clamp sits aft of the lance sweep envelope.
SHELL = 0.15
BORE_ROOT = 6.40
BORE_Z = 0.74
BORE_HALF = (0.78, 0.66)
JACKET_Z = 0.73
JACKET_SECTION = (0.85, 0.70, 0.32)
HOOP_HALF_LENGTH = 0.30
SADDLE_SEAT = 0.62  # Compress the buried half so neither clamp nor jacket cuts into the rooms.

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


def octagon(HP, x, w, h, chamfer, z, lower_scale=1):
    return [(x, y, z + (p * lower_scale if p < 0 else p)) for y, p in HP.octa(w, h, chamfer)]


def annulus(HP, profiles, z=0, lower_scale=1):
    """A closed swept octagon. Profiles go along the exterior, then back through the bore."""
    verts = [v for profile in profiles for v in octagon(HP, *profile, z, lower_scale)]
    faces = []
    for i in range(len(profiles)):
        a, b = 8 * i, 8 * ((i + 1) % len(profiles))
        faces.extend((a + j, a + (j + 1) % 8, b + (j + 1) % 8, b + j) for j in range(8))
    return verts, faces


def collar(K, HP):
    from mathutils import Vector

    hw, hh = BORE_HALF
    shell = ((6.18, 0.84, 0.69, 0.32), (6.29, 1.02, 0.87, 0.43),
             (6.49, 1.17, 0.98, 0.46), (7.06, 1.17, 0.98, 0.46),
             (BOW, 1.04, 0.85, 0.40), (BOW, hw, hh, 0.34),
             (7.13, 0.72, 0.60, 0.31), (6.48, 0.67, 0.54, 0.26), (6.18, 0.65, 0.52, 0.26))
    v, f = annulus(HP, shell, BORE_Z)
    ob = K._obj('H9E_bow_collar', v, f, 'hgrey', grp='hull')
    K.mass('Bow collar', ob, 'pale plate', note='heavy chamfered octagon around a deep concentric bore')

    # Retain the kit's emitter, lens, and I1 attachment and aim contract. The kit's
    # rectangular trench walls and coils give way to closed octagonal liner rings.
    root = (BORE_ROOT, 0, BORE_Z)
    depth = BOW - BORE_ROOT
    part = HP.spinal(depth, 0.29, w=2 * hw, h=2 * hh, coils=0)
    part.comps = [c for c in part.comps if c['name'].startswith(('emitter', 'lens'))]

    def liner(name, role, material, profiles):
        part.add(name, role, material, annulus(HP, [(x - BORE_ROOT, w, h, ch) for x, w, h, ch in profiles]))

    liner('liner', 'mount', 'hgrey2', (
        (6.57, 0.70, 0.57, 0.27), (7.17, 0.75, 0.63, 0.32),
        (7.17, 0.69, 0.57, 0.30), (7.09, 0.65, 0.53, 0.29),
        (6.57, 0.50, 0.40, 0.21)))
    for i, (x, w, h) in enumerate(((6.72, 0.57, 0.46), (6.84, 0.60, 0.49),
                                   (6.96, 0.63, 0.52), (7.06, 0.66, 0.55))):
        liner(f'coil{i}', 'body', 'htrim', (
            (x - 0.04, w + 0.03, h + 0.03, 0.29), (x + 0.03, w + 0.03, h + 0.03, 0.29),
            (x + 0.038, w - 0.035, h - 0.035, 0.25), (x - 0.04, w - 0.055, h - 0.055, 0.23)))
        if i < 3:
            liner(f'coilglow{i}', 'body', 'hblue' if i == 1 else 'hlining', (
                (x - 0.025, w - 0.048, h - 0.048, 0.24), (x - 0.01, w - 0.039, h - 0.039, 0.24),
                (x - 0.01, w - 0.057, h - 0.057, 0.23), (x - 0.025, w - 0.062, h - 0.062, 0.23)))

    part = K.emit('I1', part, HP.frame(Vector(root), (1, 0, 0), (0, 0, 1)), 'ion_trench', keep=False)
    fd = part.fit
    for ob in K.coll.objects:
        if ob.get('grp') == 'I1' and ob.get('role') != 'mount':
            ob['gun_fixed'] = 1
            ob['turret'] = 0
    muzzles = [tuple(m[1]) for m in fd['muzzles']]
    lane = dict(apex=tuple(fd['lane_from'][1]), dir=(1, 0, 0), u=(0, 1, 0), w=(0, 0, 1),
                hu=hw, hw=hh, half=4.0, length=K.length * 0.8, what='firing lane')
    K.fitdata.append(dict(id='I1', kind='gun', slot='F', pivot=tuple(fd['pivot'][1]), up=(0, 0, 1), mount='spinal',
                         ring=root, rest_yaw=0.0, reach=fd['reach'], band=(-10, 0, 10, 20), muzzles=muzzles,
                         cal=0.29, hous_r=fd['radius'], rest_pitch=0.0, lanes=[lane], aim=tuple(fd['aim'][1]), bore=fd['bore']))
    K.features.append(dict(id='I1', kind='gun', what='ion cannon, concentric recessed accelerator', count=1,
                           pos=root, aim=(0.0, 0.0), slot='F', weapon='ion', src='picture',
                           note='shared emitter and lens behind a stepped octagonal liner', muzzle=muzzles,
                           normal=(1, 0, 0), fixed=True, inv=['ion_trench']))


def spine(K, HP):
    from mathutils import Vector

    def profile(x):
        return octagon(HP, x, *JACKET_SECTION, JACKET_Z, SADDLE_SEAT)

    aft = [octagon(HP, -3.38, 0.77, 0.49, 0.25, 0.65),
           octagon(HP, -3.95, 0.66, 0.14, 0.12, 0.65)]
    ob = K.loft_rings('H9E_spinal_jacket', [profile(6.44), profile(-2.84), *aft], 'hgrey2', grp='hull')
    K.mass('Spinal jacket', ob, 'pale plate', note='faceted panelled jacket that tapers down into the saddle')

    # The jacket uses the same two-size machined plate relief as the saddle, on five
    # exposed facets. The structural hoop seats interrupt the plate rows.
    ends = [(6.28, HOOPS[0] + HOOP_HALF_LENGTH)]
    ends += [(hi - HOOP_HALF_LENGTH, lo + HOOP_HALF_LENGTH) for hi, lo in zip(HOOPS, HOOPS[1:])]
    ends += [(HOOPS[-1] - HOOP_HALF_LENGTH, -2.84)]
    for i, (hi, lo) in enumerate(ends):
        n = max(1, round((hi - lo) / 0.65))
        rings = [profile(hi + (lo - hi) * j / n) for j in range(n + 1)]
        if i == len(ends) - 1:
            rings.extend(aft)
        acc, _ = HP.module_panels(rings, (0, 1, 2, 3, 7), pv=0.49, gap=0.022, t_big=0.047, t_small=0.031)
        for material, (v, f) in acc.items():
            if v:
                K._obj(f'H9E_jacket_panels_{i}_{material}', v, f, material, grp='hull')
        for j in (1, 2):
            x0, y, z = profile(hi)[j]
            normal = Vector((0, y, z - JACKET_Z)).normalized()
            K.strip(f'H9E_jacket_rail_{i}_{j}', [(x0, y, z), (lo, y, z)], w=0.07, t=0.045,
                    normals=[normal] * 2, m='htrim', grp='hull')

    # Each hoop is one octagonal clamp with a recessed race between its bevelled
    # shoulders. Keep the lit contacts below the rim and off the edge breaks.
    rim = (1.12, 1.00, 0.40)
    race = (1.065, 0.94, 0.37)
    for i, x in enumerate(HOOPS, 1):
        end, inner = (0.96, 0.83, 0.35), (0.80, 0.66, 0.30)
        half_profile = ((HOOP_HALF_LENGTH, end), (0.22, rim), (0.09, rim), (0.061, race))
        profiles = [(x + d, *p) for d, p in half_profile]
        profiles += [(x - d, *p) for d, p in reversed(half_profile)]
        profiles += [(x - HOOP_HALF_LENGTH, *inner), (x + HOOP_HALF_LENGTH, *inner)]
        v, f = annulus(HP, profiles, JACKET_Z, SADDLE_SEAT)
        K._obj(f'H9E_capacitor_hoop_{i}', v, f, 'htrim', grp='hull')
        K.fitting(f'C{i}', 'armoured capacitor hoop', (x, 0, JACKET_Z + rim[1]), note='raised clamp with recessed contacts')
        loop = [Vector(p) for p in octagon(HP, x, *race, JACKET_Z, SADDLE_SEAT)]
        for j, t0, t1 in ((0, 0.18, 0.82), (1, 0.31, 0.69), (2, 0.18, 0.82),
                          (3, 0.62, 0.94), (7, 0.06, 0.38)):
            a, b = loop[j], loop[(j + 1) % 8]
            normal = (b - a).cross(Vector((1, 0, 0))).normalized()
            K.strip(f'H9E_hoop_contact_{i}_{j}', [a.lerp(b, t0) - normal * 0.004, a.lerp(b, t1) - normal * 0.004],
                    w=0.07, t=0.014, normals=[normal] * 2, m='hblue', grp='hull')


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
    K.change('Seat the octagonal cannon in the solid saddle.', 'Keep a clear muzzle and four distinct hoops in the Directorate trim.')
    K.change('Flatten the deep keel and segment the light line.', 'Picket and Cordon set the faceted belly and panel language.')
    K.change('Add launch origins to the two flush flank doors.', 'Both serve the one hangar already in the Vanguard rules.')
