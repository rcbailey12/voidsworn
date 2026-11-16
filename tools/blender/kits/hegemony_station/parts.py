"""Hegemony station parts, built for the T2 sheet and reusable by T1 later.

No hull or part shape is borrowed from another faction. Geometry is accumulated
per module and material, so fittings keep their identity without one draw each.
All shells have an outer skin and an inner skin. Open damage has torn rims.
"""
import math
import random
import bpy
from mathutils import Vector, Matrix

TAU = math.tau
MACHINES = {'tower_cap', 'pump', 'rack', 'berth_collar'}


class Parts:
    def __init__(self, materials):
        self.materials = materials
        self.meshes = {}
        self.rows = []
        self.group = 'core_01'
        self.matrix = Matrix.Identity(4)
        self.moving = False

    def record(self, group, kind, purpose, inside='deck, frames, service racks', parent=None):
        self.group = group
        self.rows.append(dict(id=group, kind=kind, route='hand-built',
                              kit='hegemony_station', purpose=purpose,
                              inside=inside, parent=parent))

    def mesh(self, name, verts, faces, zone='plate', inside=False):
        key = (self.group, zone, inside, self.moving)
        if key not in self.meshes:
            self.meshes[key] = ([], [])
        vv, ff = self.meshes[key]
        offset = len(vv)
        vv.extend(tuple(self.matrix @ Vector(v)) for v in verts)
        ff.extend(tuple(offset + j for j in f) for f in faces)

    def box(self, pos, size, zone='plate', inside=False, rotation=0):
        x, y, z = size
        rot = Matrix.Rotation(rotation, 4, 'Z')
        c = Vector(pos)
        vv = [c + rot @ Vector((a*x/2, b*y/2, d*z/2))
              for d in (-1, 1) for b in (-1, 1) for a in (-1, 1)]
        self.mesh('box', vv, [(0,2,3,1),(4,5,7,6),(0,1,5,4),
                             (2,6,7,3),(0,4,6,2),(1,3,7,5)], zone, inside)

    def rod(self, a, b, radius=0.08, zone='edge', n=8, inside=False):
        a, b = Vector(a), Vector(b)
        axis = (b-a).normalized()
        side = axis.cross(Vector((0,0,1)))
        if side.length < 0.1:
            side = axis.cross(Vector((0,1,0)))
        side.normalize()
        other = axis.cross(side)
        vv = [p + radius*(math.cos(TAU*i/n)*side+math.sin(TAU*i/n)*other)
              for p in (a,b) for i in range(n)]
        ff = [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
        ff += [tuple(reversed(range(n))), tuple(range(n,n*2))]
        self.mesh('rod',vv,ff,zone,inside)

    def band(self, ri, ro, bottom, top, start=0, end=TAU, steps=64,
             zone='plate', inside=False, torn=False):
        rng = random.Random(737)
        vv = []
        for i in range(steps+1):
            a = start+(end-start)*i/steps
            for r, z in ((ri,bottom),(ro,bottom),(ro,top),(ri,top)):
                if torn and i in (0,steps):
                    a1 = a + rng.uniform(-0.026,0.026)
                    z += rng.uniform(-0.24,0.24)
                else:
                    a1 = a
                vv.append((r*math.cos(a1),r*math.sin(a1),z))
        ff = []
        for i in range(steps):
            a=i*4; b=a+4
            # closed wall section, not a flat cap across the empty corridor
            ff += [(a,a+1,b+1,b),(a+1,a+2,b+2,b+1),
                   (a+2,a+3,b+3,b+2),(a+3,a,b,b+3)]
        ff += [(3,2,1,0), tuple(steps*4+j for j in range(4))]
        self.mesh('band',vv,ff,zone,inside)

    def dish(self, pos, radius, rotation=0):
        old = self.matrix.copy()
        self.matrix = old @ Matrix.Translation(Vector(pos)) @ Matrix.Rotation(rotation,4,'X')
        # Thick parabolic bowl, open toward +Z, with a rim and feed struts.
        steps=32; rings=5; vv=[]
        for side in (0,1):
            for j in range(rings):
                r=radius*(0.09+0.91*j/(rings-1))
                for i in range(steps):
                    a=TAU*i/steps
                    vv.append((r*math.cos(a),r*math.sin(a),0.42*r*r/radius+side*0.055))
        ff=[]
        for side in (0,1):
            off=side*rings*steps
            for j in range(rings-1):
                for i in range(steps):
                    a=off+j*steps+i; b=off+j*steps+(i+1)%steps
                    face=(a,b,b+steps,a+steps)
                    ff.append(face if side else tuple(reversed(face)))
        for j in (0,rings-1):
            for i in range(steps):
                a=j*steps+i; b=j*steps+(i+1)%steps
                ff.append((a,b,b+rings*steps,a+rings*steps))
        # Missing bowl cells and their inner/outer skins expose pitted dishes.
        # Keep the feed and rim as machinery, rather than painting dark spots.
        ff=[face for face in ff if not (len(face)==4 and
            any((index%steps) in (5,6,19) and (index//steps)%rings in (2,3)
                for index in face))]
        self.mesh('dish',vv,ff,'edge')
        for a in (0,TAU/3,TAU*2/3):
            self.rod((radius*0.8*math.cos(a),radius*0.8*math.sin(a),radius*.3),
                     (0,0,radius*.85),.035)
        self.rod((0,0,0),(0,0,radius*.9),.07,'trim')
        self.matrix = old

    def drum(self, radius, bottom, height, decks=True, breach=False):
        end=TAU-0.5 if breach else TAU
        # Liner behind external plates, rim bands above and below.
        self.band(radius-.22,radius,bottom,bottom+height,0,end,64,'liner',True,breach)
        for z in (bottom,bottom+height):
            self.band(radius-.25,radius+.14,z-.07,z+.07,0,end,64,'edge',torn=breach)
        for j in range(40):
            a0=TAU*j/40+.008; a1=TAU*(j+1)/40-.008
            if a1>end: continue
            zone='trim' if j%9==0 else ('plate2' if j%5==0 else 'plate')
            self.band(radius,radius+.075,bottom+.18,bottom+height-.18,a0,a1,2,zone)
            a=(a0+a1)*.5
            self.box((radius*math.cos(a),radius*math.sin(a),bottom+height*.48),
                     (.09,.30,.42),'recess',rotation=a)
            for z in (bottom+.3,bottom+height-.3):
                self.rod((radius*math.cos(a),radius*math.sin(a),z-.035),
                         ((radius+.13)*math.cos(a),(radius+.13)*math.sin(a),z),.045)
        if decks:
            # A corridor annulus leaves a service shaft rather than a solid disc.
            self.band(.9,radius-.24,bottom+.11,bottom+.22,0,TAU,64,'deck',True)
            self.band(.7,.9,bottom+.12,bottom+height-.1,0,TAU,32,'liner',True)
            for i in range(12):
                a=TAU*i/12
                self.box(((radius+1)*.5*math.cos(a),(radius+1)*.5*math.sin(a),bottom+height*.5),
                         (radius-1.2,.10,height-.3),'frame',True,a)
                self.box(((radius-.65)*math.cos(a+.1),(radius-.65)*math.sin(a+.1),bottom+.65),
                         (.45,.65,.85),'rack',True,a)

    def collar(self, x, radius, depth=1.2):
        old=self.matrix.copy()
        self.matrix=old @ Matrix.Translation(Vector((x,0,0))) @ Matrix.Rotation(math.pi/2,4,'Y')
        self.band(radius*.72,radius,0,depth,steps=48,zone='edge')
        self.band(radius*.70,radius*.73,-1.6,depth-.05,steps=48,zone='liner',inside=True)
        for z in (0,depth*.45,depth):
            self.band(radius*.96,radius*1.05,z-.045,z+.045,steps=48,zone='trim')
        for j in range(12):
            a=TAU*j/12
            self.box((radius*math.cos(a),radius*math.sin(a),depth*.5),(.20,.24,.36),'plate2',rotation=a)
        # Segmented closed pressure door, well inside the dark bore.
        self.band(.02,radius*.71,-1.64,-1.57,steps=48,zone='recess',inside=True)
        self.matrix=old

    def damaged_drum(self, radius, bottom, height, hole=None, top_tear=False):
        """Open thick shell with irregular missing cells and exposed deck structure.

        The holes remove plates AND liner. Nothing closes them with a dark disc.
        Sizes and positions come from the design, not a damage-coloured overlay.
        """
        centre=math.radians(hole[0] if hole else -70)
        width=hole[1] if hole else 4.8
        def missing(a, z):
            delta=abs(math.atan2(math.sin(a-centre),math.cos(a-centre)))
            if top_tear:
                return delta*radius < width*.5*(.85+.18*math.sin(a*29)) and z>bottom+height*.28
            return hole and (delta*radius/(width*.5))**2+((z-bottom-height*.53)/(height*.43))**2 < 1.0+.17*math.sin(a*41+z*13)
        steps=80; tiers=6
        for j in range(steps):
            a0=TAU*j/steps; a1=TAU*(j+1)/steps
            a=(a0+a1)/2
            for k in range(tiers):
                lo=bottom+k*height/tiers; hi=bottom+(k+1)*height/tiers
                if missing(a,(lo+hi)/2): continue
                self.band(radius-.22,radius,lo,hi,a0,a1,1,'liner',True)
                self.band(radius,radius+.075,lo+.025,hi-.025,a0+.003,a1-.003,1,
                          'plate2' if j%7==0 else 'plate')
            for z in (bottom,bottom+height):
                if missing(a,z): continue
                self.band(radius-.25,radius+.14,z-.07,z+.07,a0,a1,1,'edge')
            # Thin inward deck strips, with the top tear also cut through the deck lip.
            if not (top_tear and missing(a,bottom+height)):
                self.band(.9,radius-.24,bottom+.11,bottom+.22,a0,a1,1,'deck',True)
        self.band(.7,.9,bottom+.12,bottom+height-.1,steps=32,zone='liner',inside=True)
        for j in range(16):
            a=TAU*j/16
            self.rod((1.0*math.cos(a),1.0*math.sin(a),bottom+.3),
                     ((radius-.35)*math.cos(a),(radius-.35)*math.sin(a),bottom+.3),.085,'frame',inside=True)
            self.rod(((radius-.42)*math.cos(a),(radius-.42)*math.sin(a),bottom+.25),
                     ((radius-.42)*math.cos(a),(radius-.42)*math.sin(a),bottom+height-.2),.085,'frame',inside=True)
            self.box(((radius-1.0)*math.cos(a),(radius-1.0)*math.sin(a),bottom+.65),
                     (.45,.65,.85),'rack',True,a)
        if hole or top_tear:
            # Peeled teeth are thickness-bearing panels, with narrow bent ribs behind.
            for side in (-1,1):
                a=centre+side*width*.49/radius
                old=self.matrix.copy()
                self.matrix=old @ Matrix.Translation(Vector((radius*math.cos(a),radius*math.sin(a),bottom+height*.7))) @ Matrix.Rotation(a,4,'Z') @ Matrix.Rotation(side*.65,4,'Y')
                self.box((.35,0,0),(.9,.45,.13),'edge')
                self.matrix=old
            if top_tear:
                for j in range(5):
                    a=centre+(j-2)*.12
                    self.rod(((radius-.6)*math.cos(a),(radius-.6)*math.sin(a),bottom+.5),
                             ((radius+.4+j*.16)*math.cos(a),(radius+.4+j*.16)*math.sin(a),bottom+height+.5+j*.2),.09,'frame')

    def bent_stub(self, length, width):
        """Half arm with a sideways kink and a stripped, open frame at its end."""
        first=length*.58
        self.arm(first,width,2,cap=False)
        old=self.matrix.copy()
        self.matrix=old @ Matrix.Translation(Vector((first,0,-.15))) @ Matrix.Rotation(math.radians(24),4,'Z') @ Matrix.Rotation(.16,4,'Y')
        tail=length-first
        self.box((tail*.5,0,-width*.22),(tail,width*.88,.13),'deck',True)
        for side in (-1,1):
            for zz in (-width*.24,width*.24):
                self.rod((0,side*width*.45,zz),(tail+.25,side*width*.5,zz+.22*side),.10,'frame',inside=True)
            for j in range(4):
                x=j*tail/3
                self.rod((x,side*width*.45,-width*.24),(x,side*width*.45,width*.24),.08,'frame',inside=True)
            self.box((tail*.18,side*width*.48,0),(tail*.36,.12,width*.55),'edge')
        self.matrix=old

    def arm(self, length, width, modules, broken=False, cap=True):
        h=width*.62
        # Deck and side corridors are shared structure, broken shell stops at its own joint.
        self.box((length/2,0,-h*.30),(length,width*.9,.12),'deck',True)
        self.box((length/2,0,-h*.44),(length,width,.12),'liner',True)
        for side in (-1,1):
            self.box((length/2,side*width*.47,0),(length,.12,h),'liner',True)
        step=length/modules
        for k in range(modules):
            x=(k+.5)*step
            # Pressure module collars, with a dark rebate and a proud machined
            # lip. Their bore carries the corridor rather than a flat end disc.
            old=self.matrix.copy()
            self.matrix=old @ Matrix.Translation(Vector((k*step,0,0))) @ Matrix.Rotation(math.pi/2,4,'Y')
            self.band(width*.43,width*.57,-.06,.06,steps=16,zone='trim')
            self.matrix=old
            for side in (-1,1):
                for tier in (-1,1):
                    self.box((x,side*width*.52,tier*h*.25),(step-.09,.12,h*.43),
                             'trim' if (k+tier)%4==0 else 'plate')
                self.rod((x-step*.4,side*width*.53,-h*.15),
                         (x+step*.4,side*width*.53,-h*.15),.045,'edge')
            for t in range(3):
                self.box((x+(t-1)*step*.28,0,h*.5),
                         (step*.25,width*.98,.10),'plate2' if (k+t)%4==0 else 'plate')
            self.box((x,width*.1,h*.60),(step*.3,width*.35,.22),'trim')
            self.box((k*step,0,0),(.12,width*.94,h*.9),'frame',True)
            for side in (-1,1):
                self.box((x,side*width*.28,-h*.07),(.50,.35,h*.40),'rack',True)
            for side in (-1,1):
                self.rod((k*step,side*width*.55,-h*.5),(k*step,side*width*.55,h*.5),.065)
                self.rod((k*step+.12,side*width*.54,-h*.32),
                         ((k+1)*step-.12,side*width*.54,-h*.32),.065,'trim')
        if broken:
            # Ragged plates round an open corridor mouth, with its deck and racks visible.
            rng=random.Random(373)
            for side in (-1,1):
                for j in range(7):
                    xx=length+rng.uniform(-.35,.5)
                    self.rod((length-.45,side*width*.48,(j/6-.5)*h),
                             (xx,side*width*.52,(j/6-.5)*h+rng.uniform(-.2,.2)),.065,'edge')
        if cap: self.collar(length,width*.61)

    def finish(self, root, moving):
        result=[]
        for (group,zone,inside,is_moving),(vv,ff) in self.meshes.items():
            me=bpy.data.meshes.new(group+'_'+zone)
            me.from_pydata(vv,[],ff); me.update()
            ob=bpy.data.objects.new(me.name,me)
            bpy.context.collection.objects.link(ob)
            ob.data.materials.append(self.materials[zone])
            ob.parent=moving if is_moving else root
            ob['module']=group; ob['inside']=inside; ob['zone']=zone
            ob['route']='hand-built'; ob['kit']='hegemony_station'
            # Edge bevel geometry carries detail in the sheet. No texture projection.
            if zone in ('plate','plate2','trim'):
                mod=ob.modifiers.new('machined_edges','BEVEL'); mod.width=.025; mod.segments=1
                mod.affect='EDGES'
            result.append(ob)
        return result
