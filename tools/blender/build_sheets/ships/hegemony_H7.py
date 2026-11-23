# hegemony_H7: the Picket frigate, the Meridian Directorate Navy's smallest escort (godot/rules/data/tables.json h_picket,
# "Directorate picket", class Frigate, 6.5 world units). Issue 1412. Shape of record: Muse run 3 (PR 1707):
# contrib/muse/design/class_family_hegemony_2026_11/picket_sheet.webp and picket_beauty.webp (copies in
# docs/ship_pipeline/build_sheets/hegemony_H7/concept_*.jpg). Rules: laser F (the Plasma cannon, 2 shots), flak T (Picket
# lasers, 3 shots); ability evasive; no hangar.
# Version 2, the merged Picket (Ryan, Nov 23 2026, R442): "i like the extra detail and additional plates/bumps/lights/ship
# accessories on opus but the shape and detail on astra with the engines, the radiator grills, the deep line cutouts in the
# ship for plates are much better". So the base is Astra's blind build (contrib/codex/picket_astra_1122/hegemony_H7A.py,
# PR 1745): its nine lofted cross-sections, the deep plate-line cuts, the paired nozzle pods, the slatted belly coolers with
# the removable centreline covers, the segmented light races broken at the boarding doors, its joints and insides (R443).
# On top sit the Opus H7 fittings (PR 1716): the bow face armour plates, retro and attitude thrusters, flush drone doors with
# guide lamps, window slits, module latch rows, deck hatches, capacitor louvres and the raised flak barbette plinth.
# +X bow, +Y port, +Z up. Bow face x = +3.22, nozzle exits x = -3.25.

CODE = 'hegemony_H7'
NAME = 'Picket frigate (Meridian Directorate Navy escort)'
FACTION = 'Meridian Directorate (hegemony)'
CLASS = 'Frigate'
LENGTH = 6.5
GAME = "data.js h_picket (cls 'Frigate', 'Directorate picket'; the Godot rules table godot/rules/data/tables.json carries it); length from godot/render/hull_table.gd CLS_LEN['Frigate'] = 6.5; game folder H7_23 (AI_HULLS hegemony|Frigate)"
BEAUTY = 'docs/ship_pipeline/build_sheets/hegemony_H7/concept_beauty.jpg'
KIT = 'hegemony'
CONCEPT_SHEET = 'docs/ship_pipeline/build_sheets/hegemony_H7/concept_sheet.jpg'
CONCEPT_VIEWS = dict(top=dict(box=(1290, 45, 1700, 1180), largest=True, flip=False, rot=90), side=dict(box=(80, 735, 1100, 950), largest=True, flip=False))
CROPS = [('bow (the blunt face and the casemate)', (380, 620, 1000, 950)), ('midships (the receiver and the barbette)', (650, 380, 1300, 850)),
         ('stern (the taper and the nozzle pods)', (1100, 280, 1600, 700))]
SHEET = dict(version=2, round='merged build (R442)', date='2026-11-23', blend='opus1412m',
             blend_where='rendered in the issue 1412 cloud copy (Blender 4.5 as the bpy module, Cycles CPU); `build.py hegemony_H7 <out> render` rebuilds it from this file',
             before='Astra hull, Opus fittings', before_note='Astra\'s blind Picket hull with the Opus fittings laid on it, run through the fit check before any fix.',
             during='The table above is every finding, in the order the check made them.')

# Astra's loft (station x, half beam, deck height), stern first. The last two strips turn in to show the drive pods; every
# lower chine ends on the same belly datum.
STATIONS = [
    (-2.89, .87, .31), (-2.38, 1.06, .35), (-1.65, 1.135, .38),
    (-.52, 1.15, .38), (.38, 1.145, .36), (1.12, 1.06, .32),
    (1.92, .88, .26), (2.59, .68, .20), (3.22, .465, .15),
]
SOLE = -.33
SEAMS = (-1.76, 1.57)
SHELL = .041
FACE = 3.22
BARB = (-.81, .08, .36)          # the flak barbette plinth: x, height, radius


def station(x):
    for a, b in zip(STATIONS, STATIONS[1:]):
        if x <= b[0]:
            u = max(0, (x - a[0]) / (b[0] - a[0]))
            return tuple(a[i] + u * (b[i] - a[i]) for i in (1, 2))
    return STATIONS[-1][1:]


def deck_z(x):
    return station(x)[1]


def ring(x):
    w, z = station(x)
    return [(x, y, h) for y, h in (
        (-.83*w, z), (.83*w, z), (w, .036), (w, -.09),
        (.87*w, SOLE + .055), (.77*w, SOLE), (-.77*w, SOLE),
        (-.87*w, SOLE + .055), (-w, -.09), (-w, .036))]


def facet(x, side, frac=.5):
    """a point on the upper facet (deck edge to the flank band) at x, frac 0 at the deck edge, and its outward normal"""
    from mathutils import Vector
    w, z = station(x)
    ya, za, yb, zb = .83*w, z, w, .036
    p = Vector((x, side*(ya + (yb-ya)*frac), za + (zb-za)*frac))
    n = Vector((0, side*(za-zb), yb-ya)).normalized()
    return p, n


def frame(K, name, x, width, inside):
    """A transverse frame with a clear passage all the way through."""
    outer = [(y * .93, z * .89) for _, y, z in ring(x)]
    inner = [(y * .83, z * .75) for y, z in outer]
    n = len(outer)
    verts = [(u, y, z) for u in (x-width/2, x+width/2)
             for loop in (outer, inner) for y, z in loop]
    faces = []
    for i in range(n):
        j = (i + 1) % n
        faces.extend([(i, j, 2*n+j, 2*n+i), (n+j, n+i, 3*n+i, 3*n+j),
                      (j, i, n+i, n+j), (2*n+i, 2*n+j, 3*n+j, 3*n+i)])
    return K._obj(name, verts, faces, 'hrack', inside=inside)


def shell(K, plate_jobs):
    K.hull_sections = [(x, w, w, SOLE, z, .07, .07) for x, w, z in reversed(STATIONS)]
    # Stop the nose at the gun backplate. Continue its sides around the real opening as an uncapped sleeve: a visible recess
    # at the muzzle.
    socket = 2.94
    for label, left, right in [('drive', STATIONS[0][0], SEAMS[0]),
                               ('mission', *SEAMS), ('fore', SEAMS[1], socket),
                               ('casemate', socket, STATIONS[-1][0])]:
        xs = [left] + [x for x, _, _ in STATIONS if left < x < right] + [right]
        ob = K.loft_rings('shell_'+label, [ring(x) for x in xs], 'hgrey2', cap=label != 'casemate')
        skin = ob.modifiers.new('shell', 'SOLIDIFY')
        skin.thickness = SHELL
        skin.offset = -1
        K.mass(('Hull: the dart, %s module' if label == 'mission' else 'Dart: %s module') % label, ob, 'chamfered pressure hull')
        grid = [left]
        for a, b in zip(xs, xs[1:]):
            count = max(1, round((b-a) / .32))
            grid.extend(a + (b-a)*i/count for i in range(1, count+1))
        plate_jobs.append((label, [ring(x) for x in grid]))
        for side in (-1, 1):
            runs = [(left, right)] if label != 'mission' else [(left, -.15), (.19, right)]
            for n, (start, end) in enumerate(runs):
                run = [start+.014] + [x for x in xs if start < x < end] + [end-.014]
                pts = [(x, side*(station(x)[0]+.003), -.028) for x in run]
                normal = [(0, side, 0)] * len(pts)
                tag = '%d_%d' % (side, n)
                K.strip(label+'_race_'+tag, pts, .081, .008, normal, 'htrim')
                K.strip(label+'_light_'+tag, [(x, y+side*.008, z) for x, y, z in pts], .023, .004, normal, 'hblue')
    K.mark('dart', 'hull', ['facet', 'step', 'chamfer'])
    K.mark('blue_line', 'band', ['band', 'seam', 'strip'])
    # Two cheek webs and a sill and lintel close the cut face around the kit mouth.
    outline = ring(FACE)
    inner = [(-.265, .070), (.265, .070), (.275, .060), (.275, -.125), (.265, -.14),
             (.245, -.14), (-.245, -.14), (-.265, -.14), (-.275, -.125), (-.275, .060)]
    verts = outline + [(FACE, y, z) for y, z in inner]
    faces = [(i, (i+1) % 10, 10+(i+1) % 10, 10+i) for i in range(10)]
    K._obj('gun_face', verts, faces, 'hgrey')
    # Opus: armour plates on the face above and below the casemate mouth
    for k, (y0, y1, z0, z1) in enumerate(((-.3, .3, .085, .13), (-.3, .3, -.29, -.165))):
        K.box('H7_bowplate_%d' % k, FACE - .005, FACE + .022, y0, y1, z0, z1, 'hpanel', ch=.008, grp='hull')
    K.mark('bow_face', 'hull', ['facet', 'step', 'chamfer'])
    for index, joint in enumerate(SEAMS):
        for tag, offset, span, lift, material in (
                ('bandseam', 0, .040, .016, 'hgrey2'),
                ('band', -.032, .018, .024, 'htrim'), ('band', .032, .018, .024, 'htrim')):
            rings = []
            for x in (joint+offset-span/2, joint+offset+span/2):
                rings.append([(x, y*(1+lift), z*(1+lift*3)) for _, y, z in ring(x)])
            K.loft_rings('joint%d_%s_%s' % (index, tag, offset), rings, material, cap=False)
    K.mark('module_bands', 'band', ['band', 'seam', 'strip'])


def machinery(K):
    import math
    from kit import HP
    K.gun('bow', (2.94, 0, -.035), 0, 0, slot='F', weapon='laser', barrels=2, cal=.052, fixed=True, inv='casemate',
          part=HP.casemate(.28, w=.55, h=.21, cal=.052, out=.025),
          note='the Plasma cannon (laser F, 2 shots): two short bores in a lined recess in the blunt bow face')
    K.features[-1]['what'] = 'plasma cannon, twin casemate in the bow face (fixed)'
    # Opus: a low eight-sided plinth under the flak turret
    bx, bh, br = BARB
    zd = deck_z(bx)
    oct_ = [(bx + br*math.cos(math.pi/8 + k*math.pi/4), br*math.sin(math.pi/8 + k*math.pi/4)) for k in range(8)]
    pv, pf = HP._poly_prism(oct_, zd - .04, zd + bh, inset=.03)
    K.mass('Flak barbette plinth', K._obj('H7_barbette', pv, pf, 'hgrey2', grp='hull'), 'recessed grey', note='the low faceted barbette the Picket lasers turn on')
    pv, pf = HP._poly_prism([(bx + (x-bx)*1.02, y*1.02) for (x, y) in oct_], zd + bh*.4, zd + bh*.6)
    K._obj('H7_barbetteband', pv, pf, 'htrim', grp='hull')
    K.mark('barbette', 'tier', ['face', 'roof', 'opening'], fid='barbette_plinth')
    K.gun('dorsal', (bx, 0, zd + bh), 0, 5, slot='T', weapon='flak', barrels=3, cal=.035, blen=.25, size=.75, inv='barbette',
          note='the Picket lasers (flak T, 3 shots over 3 emitters) on the raised dorsal barbette')
    K._surface_part('receiver', HP.antenna(.12, L=.38, t=.075), (1.10, 0, deck_z(1.10)+.008), (0, 0, 1), (1, 0, 0),
                    'sensor_fin', 'low swept sensor', 'antenna', 'picture', 'the one low sensor receiver, ahead of the barbette')
    for i, side in enumerate((-1, 1)):
        sn = 'p' if side > 0 else 's'
        y = side * .485
        K.engine('drive'+str(i), (-3.25, y, -.004), .245, .65, bell=1, kw=dict(w=.50, h=.49), inv='engines',
                 note='rectangular nozzle pod seated in the stern')
        K.features[-1]['what'] = 'engine, rectangular nozzle 0.50 x 0.49'
        K.vent('intake'+str(i), (-2.35, y, deck_z(-2.35)+.019), (0, 0, 1), .27, .45, slats=6, inv='vents', note='drive feed louvre')
        K.hatch('transfer'+str(i), (.02, side*station(.02)[0], -.035), (0, side, 0), .21, .19, inv='hatches',
                note='boarding door: the waist light breaks round it')
        for j, x in enumerate((-2.22, -1.17, .02, 1.10, 2.12)):
            K.vent('cooler%d_%d' % (i, j), (x, side*station(x)[0]*.49, SOLE-.015), (0, 0, -1), .19, .32, slats=5, inv='coolers',
                   note='slatted cooler cassette on the belly')
        # ---- Opus fittings ----
        K.thruster('Q1'+sn, (FACE+.004, side*.395, -.035), (1, 0, 0), inv='thrusters', r=.05,
                   note='retro thruster on the bow face beside the casemate (lore 3.4; the evasive burn)')
        K.features[-1]['what'] = 'retro thruster, two rectangular nozzles'
        for q, x in (('Q2', 2.3), ('Q3', -2.6)):
            p, nrm = facet(x, side, .5)
            K.thruster(q+sn, tuple(p + nrm*.004), tuple(nrm), inv='thrusters', r=.08, note='attitude thruster on the upper facet')
            K.features[-1]['what'] = 'attitude thruster, two rectangular nozzles'
        p, nrm = facet(-1.2, side, .5)
        K._surface_part('D1'+sn, HP.bay(.14, .4), tuple(p + nrm*.025), tuple(nrm), (1, 0, 0), 'drone_doors', 'flush drone doors 0.4 x 0.14', 'bay', 'picture',
                        'the faction\'s small drone bay: flush armoured doors on the upper facet; no hangar in the rules, so no craft fly', aperture=.6)
        for k, x in enumerate((.6, .88, -.48, 1.82)):
            p, nrm = facet(x, side, .78)
            K.slit('W%d%s' % (k+1, sn), tuple(p + nrm*.014), tuple(nrm), .14, .04, inv='windows', note='blue-white crew deck window above the light race')
        K.vent('V1'+sn, (2.12, side*.24, deck_z(2.12)+.004), (0, 0, 1), .14, .3, slats=5, inv='vents', note='heat louvre over the cannon\'s capacitors')
        for k, xs in enumerate(SEAMS):
            for d in (.2, -.2):
                x = xs + d
                K.organ('LW%d%s%s' % (k, sn, 'f' if d > 0 else 'a'), HP.latch(n=3, pitch=.12, w=.07), (x, side*.42, deck_z(x)+.004), (0, 0, 1),
                        fwd=(1, 0, 0), inv='latches', what='module latch row (3 clamps)', kind='latch', note='locks two hull modules together across the joint')
    K.hatch('H1', (2.45, 0, deck_z(2.45)+.004), (0, 0, 1), .26, .2, inv='hatches', note='deck hatch over the cannon room')
    K.hatch('H2', (.3, 0, deck_z(.3)+.004), (0, 0, 1), .26, .2, inv='hatches', note='deck hatch to the control deck')
    K.hatch('H3', (-2.55, 0, deck_z(-2.55)+.004), (0, 0, 1), .26, .2, inv='hatches', note='deck hatch to the drive room')
    # A flat, bolted race cover between the paired heat exchangers (Astra).
    for j, (a, b) in enumerate(((-2.65, -1.80), (-1.72, -.61), (-.57, .53), (.57, 1.53), (1.61, 2.48))):
        K.box('belly_spine_'+str(j), a, b, -.115, .115, SOLE-.032, SOLE+.01, 'htrim', ch=.022)
        for side in (-1, 1):
            K.box('sole_runner_%d_%d' % (j, side), a+.035, b-.035, side*.095-.012, side*.095+.012, SOLE-.041, SOLE-.026, 'hmetal', ch=.004)
    K.mark('belly_floor', 'hull', ['facet', 'step', 'chamfer'])


def interior(K):
    for n, (a, b) in enumerate(zip((-2.80, *SEAMS), (*SEAMS, 2.88))):
        K.deck(str(n), -.145, a+.032, b-.032, inset=.25, t=.034)
    for i, x in enumerate((-2.6, SEAMS[0], -.70, .45, SEAMS[1], 2.51)):
        frame(K, 'in_frame_'+str(i), x, .068, True)
    for j, (x, room) in enumerate(((-2.27, 'drive'), (-1.25, 'reactor'), (-.25, 'control'),
                                   (.73, 'sensors'), (1.88, 'capacitors'), (2.52, 'feed'))):
        width = station(x)[0]
        for s in (-1, 1):
            y = s*.52*width
            K.room(room+str(s), 'hrack', x-.18, x+.18, y-.10, y+.10, -.13, .072)
            for k in range(4):
                u = x-.15+k*.09
                K.box('in_'+room+'_blade%d_%d' % (s, k), u, u+.037, y-.082, y+.082, .062, .15, 'hcorr', inside=True)
            K.box('in_'+room+'_light'+str(s), x-.16, x+.16, y-.016, y+.016, .145, .158, 'hemerg', inside=True)
    K.inside.append(dict(kind='note', name='insides', note='Insides through the hull, hidden until a piece breaks: feed racks and capacitor banks forward, sensors, control and the reactor midships, the drive racks aft, a deck through each module, open frames, blue emergency strips on the racks. The Navy breaks in modules at its joints (factions.md).'))
    K.armour('belly', SHELL, 'Flat sole, chamfered bilges and replaceable cooler cassettes.')
    for n, (x, side, section) in enumerate(zip(SEAMS, (-1, 1), ('eng', 'prow'))):
        w = station(x)[0]
        K.break_line('ring'+str(n), x, 'Navy module joint at an open transverse frame.',
                     path=[(x, -w), (x+.035, -w*.4), (x-.024, w*.4), (x, w)])
        K.point('breach', 'hp_breach_'+str(n), (x, side*w, -.05), side='P' if side > 0 else 'S', section=section)
    for n, side in enumerate((-1, 1)):
        tag = 'P' if side > 0 else 'S'
        K.point('rcs', 'hp_rcs_'+str(n), (FACE+.05, side*.395, -.035), side=tag)
        K.point('board', 'hp_board_'+str(n), (.02, side*station(.02)[0], -.035), side=tag)
    K.point('core', 'hp_core', (-1.25, 0, -.04))


def panels(K, plate_jobs):
    """Astra's deep-cut module plates, laid last so every Opus fitting has claimed its ground"""
    from kit import HP

    def reserved(p, radius):
        if (p.z < -.31 and abs(p.y) < .18 and -2.6 < p.x < 2.45
                or p.z > .14 and abs(p.y) < .10+radius and abs(p.x-1.10) < .22+radius
                or p.z > .14 and abs(p.y) < BARB[2]+.04 and abs(p.x-BARB[0]) < BARB[2]+.04):
            return True
        return any((p - c).length < r + radius*.6 for c, r in K.keepouts)
    laid_all = {'deck_panels': 0, 'flank_panels': 0, 'belly_panels': 0}
    for label, rings in plate_jobs:
        for inv, faces in (('deck_panels', (0,)), ('flank_panels', (1, 3, 4, 6, 7, 9)), ('belly_panels', (5,))):
            acc, laid = HP.module_panels(rings, faces, pv=.29, gap=.009, unit=.31, t_big=.015, t_small=.011, keep=reserved)
            laid_all[inv] += laid
            for material, (verts, faces_) in acc.items():
                if faces_:
                    K._obj('%s_%s_%s' % (label, inv, material), verts, faces_, material)
    for inv, laid in laid_all.items():
        K.built.append(dict(id='H7_'+inv, kind='plate', type='plate', inv=[inv], shaped=True, detailed=laid > 0, subs=['panel', 'seam', 'module']))


def build(K):
    import kit
    kit.MATS.update(kit.HP.MATS)
    K.hull_rounded = False
    plate_jobs = []
    shell(K, plate_jobs)
    machinery(K)
    interior(K)
    panels(K, plate_jobs)
    K.colour('Navy grey and steel-blue trim', -3.25, 3.25, 'outer armour and panel edges')
    K.colour('Implant blue', -2.89, 3.22, 'segmented flank race, drone door lamps, windows')
    K.colour('no rust, no warm light, no asymmetry', -3.25, 3.25, 'factions.md Never')
    K.change('The hull, its plate-line cuts, the nozzle pods, the belly coolers and covers, the light races and the joints are Astra\'s blind build (hegemony_H7A, PR 1745)',
             'Ryan, Nov 23 2026 (R442): Astra\'s shape, engines, radiator grills and deep plate-line cutouts are better; R443 adopts the method')
    K.change('The Opus fittings sit on that hull: bow face plates, retro and attitude thrusters, flush drone doors with guide lamps, window slits, latch rows at the joints, deck hatches, capacitor louvres and a raised barbette plinth',
             'Ryan, Nov 23 2026 (R442): he likes the extra plates, bumps, lights and accessories of the Opus build; every part has a job (R221)')
    K.change('Flat belly through all three modules', 'Ryan, Nov 22 2026: flatten the speedboat keel into a space hull (rule 4.1)')
    K.change('Three visible flak emitters on a low eight-sided plinth', 'designs.md: three emitters; the plinth lifts their firing plane over the receiver (R240)')
    K.change('Flush drone doors on the upper facets, kept with no craft', 'designs.md: flush flank doors only; the rules give the Picket no hangar')
    K.open_item('Stencil marks and the steel-blue trim tone are paint (the Hegemony stack), not modelled')


INV_NOTES = {}
