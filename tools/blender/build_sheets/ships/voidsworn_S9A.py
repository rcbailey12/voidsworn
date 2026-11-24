"""Blind Astra build of the Sunward Warden. +X is forward, +Y port and +Z dorsal."""
CODE = 'voidsworn_S9A'
NAME = 'Warden | Astra'
KIT = 'voidsworn'
FACTION = 'Sunward Crusade (voidsworn)'
CLASS = 'Frigate'
LENGTH = 6.5
GAME = 'data.js warden (Godot warden, Frigate)'
BEAUTY = 'docs/ship_pipeline/build_sheets/voidsworn_S9/concept_beauty.jpg'
CONCEPT_SHEET = BEAUTY.replace('beauty', 'sheet')
CONCEPT_VIEWS = dict(top=dict(box=(180, 300, 1660, 615), largest=True, flip=False),
                     side=dict(box=(15, 780, 1270, 1070), largest=True, flip=False))
SHEET = dict(version=1, round='blind build 2', date='2026-11-24', blend='S9A',
             px_per_unit=180, view_pad=.25)
# Bow to stern: x, maximum half-beam, deck height and sole height.
STATIONS = [(3.25, .009, .009, -.009), (2.94, .120, .068, -.054),
            (2.38, .272, .158, -.123), (1.86, .401, .213, -.177),
            (1.15, .532, .248, -.220), (.22, .643, .268, -.262),
            (-.65, .709, .268, -.284), (-1.43, .735, .268, -.288),
            (-2.17, .717, .262, -.279), (-2.81, .680, .249, -.258)]


def section(x):
    for a, b in zip(STATIONS, STATIONS[1:]):
        if a[0] >= x >= b[0]:
            fraction = (a[0] - x) / (a[0] - b[0])
            return tuple(u + fraction * (v - u) for u, v in zip(a[1:], b[1:]))
    raise ValueError(f'station outside hull: {x}')


def ring(x):
    w, top, bottom = section(x)
    half = [(0, top), (.56*w, top), (.66*w, .88*top), (.97*w, .32*top),
            (w, .17*top), (w, .30*bottom), (.93*w, .46*bottom),
            (.56*w, .92*bottom), (.43*w, bottom), (0, bottom)]
    return [(x, y, z) for y, z in half + [(-y, z) for y, z in reversed(half[1:-1])]]


def shoulder(x, side, fraction):
    from mathutils import Vector
    a, b = [Vector(p) for p in ring(x)[2:4]]
    p = a.lerp(b, fraction)
    n = Vector((0, a.z-b.z, b.y-a.y)).normalized()
    p.y *= side
    n.y *= side
    return p, n


def plate(K, kit, name, rings, faces, pitch, triangular=False):
    def reserved(p, reach):
        return any((p-c).length < r + reach*.42 for c, r in K.keepouts)

    fields, rivets, count = kit.forged_plates(
        rings, faces, pitch, (.005, .011), {'siron': 5, 'siron2': 2}, seed=31,
        tri=triangular, rr=.0045, keep=reserved, unit=.20)
    if count:
        for material, mesh in fields.items():
            K.hull_detail(name + '_' + material, mesh, material)
        K.hull_detail(name + '_studs', rivets, 'sworn')
        K.mark('armour', 'plate', ['slab', 'step', 'bevel', 'rivet'], fid=name)


def interiors(K):
    # Split the decks at the bow joint. The centre aisle and narrow gallery rooms
    # leave the lower edge of the weapon band free to tear away.
    for label, aft, fore, z in [('magazine', 1.26, 2.63, -.020),
                                 ('gallery', -2.36, 1.03, -.045),
                                 ('drive', -2.78, -2.48, -.060)]:
        widths = [x for x, *_ in STATIONS if aft < x < fore]
        deck = []
        for x in [fore, *widths, aft]:
            w = section(x)[0]*.77
            deck.append([(x,w,z), (x,w,z-.022), (x,-w,z-.022), (x,-w,z)])
        K.loft_rings('in_deck_'+label, deck, 'deck', inside=True)
        K.inside.append(dict(kind='deck', name=label, z=z, x=(aft,fore)))
    # Each frame is an open hoop, with a clear passage down its centre.
    for i, x in enumerate((2.55, 2.11, 1.55, .95, .46, -.08, -.85, -1.46, -2.17, -2.66)):
        outer = [(y*.85, z*.72) for _, y, z in ring(x)]
        inner = [(y*.87, z*.74) for y, z in outer]
        for j, (a, b) in enumerate(zip(outer, outer[1:]+outer[:1])):
            c, d = inner[(j+1)%len(inner)], inner[j]
            K.loft_rings(f'in_frame_{i}_{j}', [[(s,y,z) for y,z in (a,b,c,d)]
                         for s in (x+.013,x-.013)], 'frame', inside=True)
        K.inside.append(dict(kind='bulkhead', name=f'Web {i+1}', x=x))
    rooms = [('breech', 'magazine', 1.32, 2.51, -.115, .115, .014, .095),
             ('forward_stores', 'hold', .36, .90, -.26, .26, .008, .14),
             ('berths', 'crew', -.41, .27, -.21, .21, .004, .17),
             ('command', 'bridge', -1.00, -.52, -.19, .19, .020, .18),
             ('reactor', 'core', -1.84, -1.11, -.24, .24, -.026, .145),
             ('pump_room', 'machinery', -2.34, -1.93, -.32, .32, -.026, .14),
             ('drive_feeds', 'engroom', -2.74, -2.50, -.35, .35, -.03, .13)]
    for name, kind, *bounds in rooms:
        K.room(name, kind, *bounds)
    for s in (1, -1):
        y0, y1 = sorted((s*.33,s*.46))
        K.room('flank_gallery_'+str(s), 'gallery', -1.91, .39, y0, y1, .004, .105)
        K.cyl('in_coolant_'+str(s), (-2.32,s*.27,.15), (-1.12,s*.27,.15),
              .030, 'machinery', n=10, inside=True)
    K.armour('Pressure shell', .034, 'Iron liner inside the forged plates')


def build(K):
    import kit
    parts = kit.HP
    kit.MATS.update(parts.MATS)
    K.hull_sections = [(x,w,w,b,t,.13*w,.14*w) for x,w,t,b in STATIONS]
    K.hull_rounded = False
    rings = [ring(x) for x,*_ in STATIONS]
    hull = K.loft_rings(CODE+'_hull', rings, 'siron2')
    skin = hull.modifiers.new('shell','SOLIDIFY')
    skin.thickness, skin.offset = .034, -1
    K.mass('Knife hull', hull, 'Forged pressure hull')
    K.mark('blade','hull',['facet','step','chamfer'])

    # A level pedestal intersects the changing deck under the repeater footing.
    x = 3.25-.14*LENGTH
    seat = K.box('breech_saddle',x-.245,x+.14,-.155,.155,.12,.186,'siron2',ch=.035,taper=.030)
    K.mass('Breech saddle',seat,'Armour shoulder')
    gun = parts.gun(3,.020,.35,.38,'casemate',weapon='autocannon')
    K.gun('A1',(x,0,.187),0,barrels=3,cal=.020,blen=.35,size=.38,
          mount='casemate',slot='F',weapon='autocannon',fixed=True,part=gun,inv='repeater')
    # K.gun seats a fixed deck weapon correctly. Its generic fixed mount label
    # describes a spinal gun. This kit part is a casemate with a forward trunnion.
    K.fitdata[-1].update(mount='casemate', pivot=tuple(gun.fit['trunnion'][1]))
    K.features[-1]['what'] = 'Sear repeater, three-barrel forged bow casemate'

    # Raised feed line disappears into the foredeck before the command windows.
    xs = (1.52,1.40,1.15,.22,-.20,-.33)
    trunk = []
    for i, x in enumerate(xs):
        w = .024 if i in (0,len(xs)-1) else .049
        z = section(x)[1]
        trunk.append([(x,w,z-.009),(x,w,z+.015),(x,w*.58,z+.036),
                      (x,-w*.58,z+.036),(x,-w,z+.015),(x,-w,z-.009)])
    K.mass('Repeater feed rail',K.loft_rings('feed_rail',trunk,'siron'),'Feed armour')
    for i,x in enumerate((1.35,.99,.61,.23,-.15)):
        z = section(x)[1]
        K.box(f'rail_strap_{i}',x-.018,x+.018,-.054,.054,z,z+.043,'sworn',ch=.015)
    K.mark('feed','rib',['rib'])

    # A continuous carrier with a square window face and an aft taper.
    face = 3.25-.58*LENGTH
    roof = .407
    raft = []
    for x,w,h in [(face,.165,roof),(-.70,.185,roof),(-2.24,.17,roof),(-2.42,.106,.335)]:
        z = section(x)[1]-.014
        raft.append([(x,w,z),(x,w,h-.045),(x,w-.035,h),(x,-w+.035,h),
                     (x,-w,h-.045),(x,-w,z)])
    K.mass('Radiator carrier',K.loft_rings('spire_raft',raft,'siron'),'Common plenum')
    K.mark('raft','spine',['block','step','slit'])
    for i,y in enumerate((-.066,.066)):
        K.organ(f'W{i+1}', parts.slit(.094,.022,depth=.021,fr=.008), (face+.002,y,.341),
                (1,0,0),fwd=(0,0,-1),inv='bridge')
    for i,(station,h,profile) in enumerate(((.68,.46,3),(.76,.63,0),(.84,.51,1))):
        x = 3.25-LENGTH*station
        radiator = parts.radiator(h,.188,spread=.112,profile=profile,scale=.265,glow='slats')
        K.organ(f'R{i+1}',radiator,(x,0,roof),(0,0,1),inv='spires')
        K.mass(f'Radiator {i+1}',K.coll.objects[f'R{i+1}_body_embar'],'Heat exchanger')
    for side,suffix in ((1,'P'),(-1,'S')):
        x = 3.25-.60*LENGTH
        y = side*.520
        top = .281
        K.box('flak_saddle_'+suffix,x-.155,x+.155,y-.126,y+.126,.140,top,'siron',
              ch=.033,taper=.013)
        K.gun('F'+suffix,(x,y,top),side*9,34,barrels=2,cal=.016,blen=.18,size=.247,
              slot='T',weapon='flak',inv='flak')
        K.engine('E'+suffix,(-3.226,side*.40,-.015),.275,.30,bell=1,body_r=.218,
                 inv='drives',note='Deep-set drive, ember lining and throat')
        for i,x in enumerate((.73,.11,-1.18,-1.87)):
            w = section(x)[0]
            slope = (section(x+.01)[0] - section(x-.01)[0]) / .02
            bank = parts.vent(.29,.082,slats=4,depth=.023,fr=.007)
            K.organ(f'V{suffix}{i}',bank,(x,side*(w+.005),-.012),
                    (-slope,side,0),fwd=(0,0,1),inv='band',keep_r=.16)
        for i,x in enumerate((1.80,.43,-2.47)):
            p,n = shoulder(x,side,.45)
            K.organ(f'L{suffix}{i}',parts.lamp(.026),p+n*.009,n,inv='lights',keep_r=.045)
        x = 1.60
        p,n = shoulder(x,side,.60)
        K.organ('Q'+suffix,parts.thruster(.061),p+n*.009,n,inv='jets',keep_r=.08)
        K.point('rcs','hp_rcs_'+suffix,p,side=suffix,section='prow')
        x = -.16
        K.point('board','hp_board_'+suffix,(x,side*section(x)[0],.01),side=suffix,section='mid')
    for i,x in enumerate((1.64,.07,-1.92)):
        z = section(x)[2]
        K.hatch(f'H{i+1}',(x,0,z-.010),(0,0,-1),.13,round_=True,src='designed',inv='access')

    plate(K,parts,'point',rings[:4],(0,1,2,6,7,8,9,10,11,15,16,17),(.13,.29),True)
    plate(K,parts,'deck',rings[3:],(0,17),(.30,.75))
    plate(K,parts,'shoulder',rings[3:],(2,15),(.14,.38))
    plate(K,parts,'belt',rings,(3,4,5,12,13,14),(.08,.22))
    plate(K,parts,'lower',rings[3:],(6,7,8,9,10,11),(.19,.40))
    plate(K,parts,'plenum',raft,(0,1,3,4),(.08,.28))
    interiors(K)
    for name,x in [('B1',1.15),('B2',-2.43)]:
        K.break_line(name,x,'Staggered joint at the compartment ends',
                     path=[(x,.78),(x+.04,.38),(x-.035,.10),(x+.02,-.36),(x,-.78)])
    K.break_line('B3',0,'Lower flank tears lengthwise under the louvred belt',
                 path=[(1.07,-.114),(.29,-.120),(-1.1,-.136),(-2.29,-.130)],kind='long')
    K.break_line('B4',-1.54,'The three radiator sockets peel off together behind the flak rings',
                 path=[(-.86,.280),(-1.15,.282),(-1.88,.279),(-2.39,.275)],kind='long')
    K.point('core','hp_core',(-1.48,0,.06))
    for side,x,suffix,zone in ((1,1.93,'P','prow'),(-1,-2.23,'S','eng')):
        K.point('breach','hp_breach_'+suffix,(x,side*section(x)[0],-.038),side=suffix,section=zone)
    K.change('One flak pair and three radiators','Counts and stations follow the Warden table.')
    K.change('Tallest radiator is .63 above the carrier','R331 sets the height to 70 percent of .9.')
    K.change('Three underside covers follow the sole','Access to the feed, galleries and cooling pumps.')
