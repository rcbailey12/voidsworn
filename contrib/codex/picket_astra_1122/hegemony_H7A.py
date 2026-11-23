"""Astra's Meridian Picket. Dimensions are game units, +X bow and +Z up."""

CODE = 'hegemony_H7A'
NAME = 'Picket'
KIT = 'hegemony'
FACTION = 'Meridian Directorate'
CLASS = 'Frigate'
GAME = 'data.js h_picket (Godot Frigate)'
LENGTH = 6.5
BEAUTY = 'contrib/muse/design/class_family_hegemony_2026_11/picket_beauty.webp'
CONCEPT_SHEET = BEAUTY.replace('beauty', 'sheet')

# Independently lofted from the top view. The last two strips turn inward to
# expose the drive pods. Every lower chine ends on the same belly datum.
# Station, half beam, deck height.
STATIONS = [
    (-2.89, .87, .31), (-2.38, 1.06, .35), (-1.65, 1.135, .38),
    (-.52, 1.15, .38), (.38, 1.145, .36), (1.12, 1.06, .32),
    (1.92, .88, .26), (2.59, .68, .20), (3.22, .465, .15),
]
SOLE = -.33
SEAMS = (-1.76, 1.57)
SHELL = .041


def station(x):
    for a, b in zip(STATIONS, STATIONS[1:]):
        if x <= b[0]:
            u = max(0, (x - a[0]) / (b[0] - a[0]))
            return tuple(a[i] + u * (b[i] - a[i]) for i in (1, 2))
    return STATIONS[-1][1:]


def ring(x):
    w, z = station(x)
    return [(x, y, h) for y, h in (
        (-.83*w, z), (.83*w, z), (w, .036), (w, -.09),
        (.87*w, SOLE + .055), (.77*w, SOLE), (-.77*w, SOLE),
        (-.87*w, SOLE + .055), (-w, -.09), (-w, .036))]


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


def shell(K):
    from kit import HP
    K.hull_sections = [(x,w,w,SOLE,z,.07,.07) for x,w,z in reversed(STATIONS)]
    # Stop the nose at the gun backplate. Continue its sides around the real
    # opening as an uncapped sleeve. This leaves a visible recess at the muzzle.
    socket = 2.94
    for label, left, right in [('drive', STATIONS[0][0], SEAMS[0]),
                               ('mission', *SEAMS), ('fore', SEAMS[1], socket),
                               ('casemate', socket, STATIONS[-1][0])]:
        xs = [left] + [x for x,_,_ in STATIONS if left < x < right] + [right]
        ob = K.loft_rings('shell_'+label, [ring(x) for x in xs], 'hgrey2',
                          cap=label != 'casemate')
        skin = ob.modifiers.new('shell', 'SOLIDIFY')
        skin.thickness = SHELL
        skin.offset = -1
        K.mass(label, ob, 'chamfered pressure hull')
        # Leave deliberate land around the two access trunks and the waist light.
        grid = [left]
        for a,b in zip(xs,xs[1:]):
            count = max(1, round((b-a) / .32))
            grid.extend(a + (b-a)*i/count for i in range(1,count+1))
        def reserved(p, radius):
            return (p.z < -.31 and abs(p.y) < .18 and -2.6 < p.x < 2.45
                    or p.z > .14 and abs(p.y) < .10+radius and abs(p.x-1.10) < .22+radius
                    or p.z > .14 and abs(p.y) < .31 and abs(p.x+.81) < .44)
        panels, _ = HP.module_panels([ring(x) for x in grid], (0,1,3,4,5,6,7,9),
                                      pv=.29, gap=.009, unit=.31, t_big=.015,
                                      t_small=.011, keep=reserved)
        for material,(verts,faces) in panels.items():
            if faces:
                K._obj(label+'_panels_'+material, verts, faces, material)
        for side in (-1,1):
            runs = [(left,right)] if label != 'mission' else [(left,-.15),(.19,right)]
            for n,(start,end) in enumerate(runs):
                run = [start+.014] + [x for x in xs if start < x < end] + [end-.014]
                pts = [(x, side*(station(x)[0]+.003), -.028) for x in run]
                normal = [(0,side,0)] * len(pts)
                tag = '%d_%d' % (side,n)
                K.strip(label+'_race_'+tag, pts, .081, .008, normal, 'htrim')
                K.strip(label+'_light_'+tag,
                        [(x,y+side*.008,z) for x,y,z in pts], .023, .004, normal, 'hblue')
    # Two cheek webs and a sill and lintel close the cut face around the kit mouth.
    outline = ring(3.22)
    inner = [(-.265,.070),(.265,.070),(.275,.060),(.275,-.125),(.265,-.14),
             (.245,-.14),(-.245,-.14),(-.265,-.14),(-.275,-.125),(-.275,.060)]
    verts = outline + [(3.22,y,z) for y,z in inner]
    faces = [(i,(i+1)%10,10+(i+1)%10,10+i) for i in range(10)]
    K._obj('gun_face', verts, faces, 'hgrey')
    for index, joint in enumerate(SEAMS):
        for tag, offset, span, lift, material in (
                ('bandseam',0,.040,.016,'hgrey2'),
                ('band',-.032,.018,.024,'htrim'), ('band',.032,.018,.024,'htrim')):
            rings = []
            for x in (joint+offset-span/2, joint+offset+span/2):
                rings.append([(x,y*(1+lift),z*(1+lift*3)) for _,y,z in ring(x)])
            K.loft_rings('joint%d_%s_%s' % (index,tag,offset), rings, material, cap=False)


def machinery(K):
    from kit import HP
    # A fixed weapon uses the kit's two real bores and the Godot forward slot.
    K.gun('bow', (2.94,0,-.035), 0, 0, slot='F', weapon='laser', barrels=2,
          cal=.052, fixed=True, part=HP.casemate(.28,w=.55,h=.21,cal=.052,out=.025))
    K.gun('dorsal', (-.81,0,.385), 0, 5, slot='T', weapon='flak',
          barrels=3, cal=.035, blen=.25, size=.75)
    K._surface_part('receiver', HP.antenna(.12,L=.38,t=.075),
                    (1.10,0,station(1.10)[1]+.008), (0,0,1), (1,0,0),
                    'receiver','low swept sensor', 'antenna','picture','')
    for i, side in enumerate((-1,1)):
        y = side * .485
        K.engine('drive'+str(i), (-3.25,y,-.004), .245, .65, bell=1,
                 kw=dict(w=.50,h=.49), inv='drives')
        K.vent('intake'+str(i), (-2.35,y,station(-2.35)[1]+.019), (0,0,1),
               .27, .45, slats=6)
        K.hatch('transfer'+str(i), (.02,side*station(.02)[0],-.035),
                (0,side,0), .21,.19)
        for j,x in enumerate((-2.22,-1.17,.02,1.10,2.12)):
            K.vent('cooler%d_%d' % (i,j), (x,side*station(x)[0]*.49,SOLE-.015),
                   (0,0,-1), .19,.32, slats=5)
    # A flat, bolted race cover between the paired heat exchangers.
    for j,(a,b) in enumerate(((-2.65,-1.80),(-1.72,-.61),(-.57,.53),
                              (.57,1.53),(1.61,2.48))):
        K.box('belly_spine_'+str(j), a,b,-.115,.115,SOLE-.032,SOLE+.01,
              'htrim', ch=.022)
        for side in (-1,1):
            K.box('sole_runner_%d_%d'%(j,side), a+.035,b-.035,
                  side*.095-.012,side*.095+.012,SOLE-.041,SOLE-.026,'hmetal',ch=.004)


def interior(K):
    for n,(a,b) in enumerate(zip((-2.80,*SEAMS),(*SEAMS,2.88))):
        K.deck(str(n), -.145, a+.032,b-.032, inset=.25,t=.034)
    for i,x in enumerate((-2.6,SEAMS[0],-.70,.45,SEAMS[1],2.51)):
        frame(K, 'in_frame_'+str(i),x,.068,True)
    for j,(x,room) in enumerate(((-2.27,'drive'),(-1.25,'reactor'),(-.25,'control'),
                                (.73,'sensors'),(1.88,'capacitors'),(2.52,'feed'))):
        width = station(x)[0]
        for s in (-1,1):
            y = s*.52*width
            K.room(room+str(s), 'hrack', x-.18,x+.18,y-.10,y+.10,-.13,.072)
            for k in range(4):
                u = x-.15+k*.09
                K.box('in_'+room+'_blade%d_%d'%(s,k),u,u+.037,
                      y-.082,y+.082,.062,.15,'hcorr',inside=True)
            K.box('in_'+room+'_light'+str(s),x-.16,x+.16,y-.016,y+.016,
                  .145,.158,'hemerg',inside=True)
    K.armour('belly', SHELL, 'Flat sole, chamfered bilges and replaceable cooler cassettes.')
    for n,(x,side,section) in enumerate(zip(SEAMS,(-1,1),('eng','prow'))):
        w = station(x)[0]
        K.break_line('ring'+str(n),x,'Navy module joint at an open transverse frame.',
                     path=[(x,-w),(x+.035,-w*.4),(x-.024,w*.4),(x,w)])
        K.point('breach','hp_breach_'+str(n),(x,side*w,-.05),
                side='P' if side>0 else 'S',section=section)
    for n,side in enumerate((-1,1)):
        tag = 'P' if side>0 else 'S'
        K.point('rcs','hp_rcs_'+str(n),(3.22,side*.35,-.045),side=tag)
        K.point('board','hp_board_'+str(n),(.02,side*station(.02)[0],-.035),side=tag)
    K.point('core','hp_core',(-1.25,0,-.04))


def build(K):
    import kit
    kit.MATS.update(kit.HP.MATS)
    shell(K)
    machinery(K)
    interior(K)
    K.change('Flat belly through all three modules',
             'Ryan retained the dart and replaced the curved keel with a worked space hull.')
    K.change('Three visible flak lenses on a turning barbette',
             'The concept table calls for three emitters. Each has a muzzle in the flak slot.')
    K.colour('Navy grey and steel-blue trim',-3.25,3.25,'outer armour and panel edges')
    K.colour('Implant blue',-2.89,3.22,'segmented flank race')
