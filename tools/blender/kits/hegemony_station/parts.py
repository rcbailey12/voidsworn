"""Hegemony station parts, built for the T2 sheet and reusable by T1 later.

No hull or part shape is borrowed from another faction. Geometry is accumulated
per module and material, so fittings keep their identity without one draw each.
All shells have an outer skin and an inner skin. Open damage has torn rims.
"""
import math
import random
from contextlib import contextmanager
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
        self.details = []
        self.active_detail = None

    @contextmanager
    def detail(self, kind, purpose):
        """Inventory the geometry actually emitted by a named working fitting."""
        previous = self.active_detail
        row = dict(kind=kind, purpose=purpose, module=self.group, vertices=0,
                   triangles=0, min=[float('inf')]*3, max=[-float('inf')]*3, anchors=[])
        self.active_detail = row
        yield
        self.active_detail = previous
        if row['vertices']:
            self.details.append(row)

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
        points = [tuple(self.matrix @ Vector(v)) for v in verts]
        vv.extend(points)
        ff.extend(tuple(offset + j for j in f) for f in faces)
        if self.active_detail is not None:
            row = self.active_detail
            row['vertices'] += len(points)
            row['triangles'] += sum(len(f)-2 for f in faces)
            for i in range(3):
                row['min'][i] = min(row['min'][i], min(v[i] for v in points))
                row['max'][i] = max(row['max'][i], max(v[i] for v in points))
            # Actual face centres, rather than a union-box centre that may lie
            # in empty air between paired rails or inside a radiator header.
            if len(row['anchors'])<384:
                for face in faces[::max(1,len(faces)//6)][:6]:
                    row['anchors'].append([sum(points[j][i] for j in face)/len(face) for i in range(3)])

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
        with self.detail('dish_array', 'tower parabolic communications dish, feed struts and pitted reflector'):
            self._dish(pos, radius, rotation)

    def _dish(self, pos, radius, rotation=0):
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
            # Radial clamp jaws hold a visiting pressure collar; the dark
            # inset guide lenses are dead on this abandoned station.
            with self.detail('docking_port', 'berth clamp jaw and unpowered blue guide lens at arm end'):
                self.box((radius*math.cos(a),radius*math.sin(a),depth*.5),(.20,.24,.36),'plate2',rotation=a)
                self.box(((radius+.02)*math.cos(a),(radius+.02)*math.sin(a),depth+.06),(.14,.18,.07),'glazing',rotation=a)
        # Segmented closed pressure door, well inside the dark bore.
        self.band(.02,radius*.71,-1.64,-1.57,steps=48,zone='recess',inside=True)
        self.matrix=old

    def hatch(self, radius=.32):
        """Pressure access hatch, local +Z outward, with wheel and two hinges."""
        with self.detail('maintenance_hatch', 'round pressure hatch with handwheel and hinge pair'):
            self.band(.02,radius,0,.065,steps=24,zone='recess')
            self.band(radius*.80,radius*1.12,.03,.11,steps=24,zone='edge')
            self.band(radius*.27,radius*.40,.13,.17,steps=16,zone='trim')
            for a in (0,TAU/3,2*TAU/3):
                self.rod((0,0,.15),(radius*.34*math.cos(a),radius*.34*math.sin(a),.15),.018,'edge',n=6)
            for x in (-radius*.60,radius*.60):
                self.rod((x,radius*.90,.06),(x,radius*1.16,.06),.045,'trim')

    def airlock(self, width=.65):
        """Vertical pressure door in local XY; outward is +Z, head is +Y."""
        with self.detail('airlock', 'habitat EVA airlock; twin pressure leaves, frame, hinges and wheel'):
            self.box((0,0,.015),(width,1.65*width,.055),'recess')
            for side in (-1,1):
                self.box((side*width*.23,0,.06),(width*.43,width*1.5,.07),'plate2')
                self.box((side*width*.55,0,.07),(.07,width*1.85,.15),'edge')
                self.box((0,side*width*.86,.07),(width*1.15,.07,.15),'edge')
                for y in (-.5,.5):
                    self.rod((side*width*.48,y*width-.08,.14),(side*width*.48,y*width+.08,.14),.04,'trim')
            self.band(.08,.13,.12,.17,steps=16,zone='trim')
            self.rod((-.12,0,.145),(.12,0,.145),.025,'edge')

    def handrail(self, length, width):
        with self.detail('handrail', 'EVA maintenance walkway edge rails and tether posts'):
            for side in (-1,1):
                yy=side*width/2
                self.rod((0,yy,.45),(length,yy,.45),.025,'trim',n=6)
                for j in range(max(2,int(length/.9)+1)):
                    x=length*j/max(1,int(length/.9))
                    self.rod((x,yy,0),(x,yy,.45),.025,'edge',n=6)

    def pipe_pair(self, length, separation=.14):
        with self.detail('service_pipe', 'paired supply and return pipes joining module pressure collars'):
            for side in (-1,1):
                y=side*separation/2
                self.rod((0,y,.12),(length,y,.12),.045,'trim',n=8)
                for x in (0,length):
                    self.rod((x,y,.12),(x,y,-.04),.045,'edge',n=8)
                for j in range(int(length)+1):
                    x=length*j/max(1,int(length))
                    self.rod((x,y-.06,.12),(x,y+.06,.12),.025,'edge',n=6)

    def crane(self, length=2.8):
        with self.detail('cargo_crane', 'docking-arm cargo manipulator; trussed jib, winch and capture grapple'):
            self.band(.12,.38,0,.18,steps=24,zone='trim')
            self.rod((0,0,.15),(0,0,1.1),.12,'edge')
            for side in (-1,1):
                self.rod((0,side*.14,1.1),(length,side*.12,1.55),.055,'edge')
                self.rod((0,side*.14,1.55),(length,side*.12,1.55),.045,'trim')
                for j in range(5):
                    x=length*j/5
                    self.rod((x,side*.14,1.1+.45*j/5),(x+length/5,side*.12,1.55),.025,'edge',n=6)
            self.rod((length,0,1.55),(length,0,.55),.025,'trim',n=6)
            for side in (-1,1):
                self.rod((length,0,.55),(length,side*.22,.35),.035,'edge')
                self.rod((length,side*.22,.35),(length,side*.12,.22),.035,'edge')

    def thruster_quad(self):
        with self.detail('thruster_quad', 'ring attitude-control quad; four recessed cold nozzles on a bolted mount'):
            self.box((0,0,-.10),(.85,.85,.20),'trim')
            for x in (-.23,.23):
                for y in (-.23,.23):
                    saved=self.matrix.copy()
                    self.matrix=saved @ Matrix.Translation(Vector((x,y,0)))
                    self.band(.10,.17,0,.25,steps=16,zone='edge')
                    self.band(.02,.105,-.08,-.06,steps=16,zone='recess')
                    self.band(.16,.21,.22,.28,steps=16,zone='trim')
                    self.matrix=saved

    def solar_wing(self, length):
        with self.detail('solar_panel', 'dark solar cells on paired triangulated outrigger supports'):
            for side in (-1,1):
                y=side*.85
                self.rod((.1,0,-.2),(length,y,-.2),.055,'trim')
                self.rod((.1,0,-.2),(length*.55,y,-.2),.045,'edge')
                self.box((length*.55,y,0),(length*.85,.90,.075),'recess')
                for j in range(10):
                    x=length*(.15+.08*j)
                    self.box((x,y,.05),(length*.07,.83,.025),'glazing')
                for yy in (-.48,.48):
                    self.rod((length*.12,y+yy,.025),(length*.98,y+yy,.025),.025,'edge',n=6)

    def hangar_door(self):
        with self.detail('hangar_door', 'closed cargo handling bay; recessed segmented pressure door and lintel tracks'):
            self.box((0,0,0),(3.15,1.9,.08),'recess')
            for j in range(8):
                self.box(((j-3.5)*.36,0,.045),(.33,1.65,.065),'plate2')
            for side in (-1,1):
                self.box((side*1.57,0,.11),(.12,2.05,.27),'edge')
                self.box((0,side*.96,.12),(3.25,.12,.28),'trim')
            self.box((0,0,.10),(.06,1.7,.04),'recess')

    def damaged_drum(self, radius, bottom, height, hole=None, top_tear=False, viewport=None):
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
                if viewport:
                    delta=abs(math.atan2(math.sin(a-math.radians(viewport['angle'])),
                                         math.cos(a-math.radians(viewport['angle']))))
                    if delta < math.radians(viewport['degrees']/2) and k in (2,3,4): continue
                self.band(radius-.22,radius,lo,hi,a0,a1,1,'liner',True)
                self.band(radius,radius+.075,lo+.025,hi-.025,a0+.003,a1-.003,1,
                          'glazing' if k==4 else ('plate2' if j%7==0 else 'plate'))
                if k==4:
                    self.rod((radius*math.cos(a0),radius*math.sin(a0),lo),
                             (radius*math.cos(a0),radius*math.sin(a0),hi),.035,'edge',n=6)
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

    def observation_window(self, drum, viewport):
        with self.detail('viewport', 'one continuous observation pane and its sealed pressure-frame reveal'):
            self._observation_window(drum, viewport)

    def _observation_window(self, drum, viewport):
        """Exactly one broad, continuous curved pane in a sealed stepped reveal."""
        r=drum['radius']; z=drum['bottom']; h=drum['height']
        a0=math.radians(viewport['angle']-viewport['degrees']/2)
        a1=math.radians(viewport['angle']+viewport['degrees']/2)
        lo=z+h/3; hi=z+h*5/6
        self.band(r-.12,r+.03,lo,hi,a0,a1,16,'viewport')
        for zz in (lo-.10,hi+.10):
            self.band(r-.24,r+.19,zz-.08,zz+.08,a0-.035,a1+.035,20,'edge')
        for a in (a0-.025,a1+.025):
            self.rod(((r+.10)*math.cos(a),(r+.10)*math.sin(a),lo-.16),
                     ((r+.10)*math.cos(a),(r+.10)*math.sin(a),hi+.16),.11,'trim')

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
            old=self.matrix.copy()
            self.matrix=old @ Matrix.Translation(Vector((x,0,h*.5+.06)))
            self.hatch(min(.32,width*.27))
            self.matrix=old
            for side in (-1,1):
                for tier in (0,1):
                    self.rod((k*step+.15,side*width*.57,-h*.1+tier*.18),
                             ((k+1)*step-.15,side*width*.57,-h*.1+tier*.18),.04,'edge',n=6)
            self.box((k*step,0,0),(.12,width*.94,h*.9),'frame',True)
            for side in (-1,1):
                self.box((x,side*width*.28,-h*.07),(.50,.35,h*.40),'rack',True)
            for side in (-1,1):
                self.rod((k*step,side*width*.55,-h*.5),(k*step,side*width*.55,h*.5),.065)
                self.rod((k*step+.12,side*width*.54,-h*.32),
                         ((k+1)*step-.12,side*width*.54,-h*.32),.065,'trim')
        saved=self.matrix.copy()
        self.matrix=saved @ Matrix.Translation(Vector((0,-width*.30,h*.5+.06)))
        self.pipe_pair(length)
        self.matrix=saved @ Matrix.Translation(Vector((0,0,h*.5+.06)))
        self.handrail(length,width*.84)
        self.matrix=saved
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
