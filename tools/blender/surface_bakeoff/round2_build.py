"""Issue 111. Authored armour, filtered donor bakes, and small donor kit parts.

Run only through round2_run.py on GPU lane A. Outputs stay in TEMP.
Blender frame: +X bow, +Y port, +Z up. No source paint is read.
"""
import argparse
import json
import math
import sys
import time
from pathlib import Path

import bpy
import bmesh
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).parent))
import build as lib

PARTS = []
CONTACTS = []
GUNS = []
RNG = np.random.default_rng(111)
MAT = None
TREE = None
CORE = None
PALETTE = np.array([[.37,.31,.21], [.19,.064,.027], [.25,.21,.145],
                    [.045,.052,.056], [.12,.14,.145], [.014,.018,.021],
                    [.32,.19,.033], [.42,.025,.006]])


def finish(obj, band=0, bevel=.0009):
    # Retain the round 1 trim convention, but use physical bevels and weighted
    # normals. UVs are different from the shape normals; paint is never a grid.
    # Direct mesh work avoids thousands of context-wide operator updates.
    bm=bmesh.new();bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    if bevel:
        bmesh.ops.bevel(bm,geom=list(bm.edges),offset=bevel,segments=2,
                        affect='EDGES',clamp_overlap=True)
    bm.to_mesh(obj.data);bm.free();obj.data.update()
    uv=obj.data.uv_layers.new(name='trim')
    for p in obj.data.polygons:
        axis=np.argmax(np.abs(p.normal[:]))
        axes=[i for i in range(3) if i!=axis]
        co=np.array([[obj.data.vertices[obj.data.loops[li].vertex_index].co[i] for i in axes] for li in p.loop_indices])
        q=(co-co.min(0))/np.maximum(np.ptp(co,axis=0),1e-7)
        for li,c in zip(p.loop_indices,q):uv.data[li].uv=(.012+c[0]*.976,(band+.07+c[1]*.86)/8)
    obj.data.materials.append(MAT)
    for p in obj.data.polygons:
        p.use_smooth = True
    obj.data.set_sharp_from_angle(angle=math.radians(35))
    PARTS.append(obj)
    return obj


def box(name, at, size, band=0, bevel=.0009):
    x,y,z=[s/2 for s in size]
    obj=lib.mesh(name,[(-x,-y,-z),(x,-y,-z),(x,y,-z),(-x,y,-z),
                       (-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z)],
                      [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])
    obj.location=at
    return finish(obj, band, bevel)


def cyl(name, at, radius, depth, direction=(0,0,1), band=3, sides=16):
    v=[(radius*math.cos(i*math.tau/sides),radius*math.sin(i*math.tau/sides),z)
       for z in [-depth/2,depth/2] for i in range(sides)]
    faces=[tuple(reversed(range(sides))),tuple(range(sides,sides*2))]
    faces += [(i,(i+1)%sides,(i+1)%sides+sides,i+sides) for i in range(sides)]
    obj=lib.mesh(name,v,faces);obj.location=at
    obj.rotation_euler = Vector(direction).to_track_quat('Z','Y').to_euler()
    return finish(obj, band, min(.00065,radius*.2))


def link(name, a, b, radius=.0018, band=3):
    a,b = Vector(a),Vector(b)
    return cyl(name,(a+b)/2,radius,(b-a).length,(b-a).normalized(),band,12)


def trim(folder, res=2048):
    folder.mkdir(parents=True, exist_ok=True)
    y,x = np.mgrid[0:res,0:res].astype(np.float32)/(res-1)
    band=np.minimum(7,(y*8).astype(int)); v=np.mod(y*8,1)
    n=lib.noise(x*11,y*11,x*0); micro=lib.noise(x*137,y*137,x*0)
    base=PALETTE[band]*(.83+n*.19+micro*.06)[:,:,None]
    # Irregular chips and grime follow the trim borders. No panel grid in paint.
    edge=np.minimum(v,1-v)
    chip=(edge < .08+.055*n)&(micro>.50)
    base[chip]=np.array([.22,.23,.22])*(.75+micro[chip,None]*.35)
    rust=(edge < .17)&(n>.48)&~chip
    base[rust]=np.array([.105,.034,.014])*(.65+micro[rust,None]*.5)
    groove=((abs(v-.18)<.014)|(abs(v-.82)<.014))
    base[groove]*=.30
    streak=np.exp(-np.square(np.sin(x*143+np.sin(x*31)*2)*14))*(v>.20)*(v<.68)
    base*=1-streak[:,:,None]*.18
    vent=(band==5)&(np.mod(x*71,1)>.30)
    base[vent]=(.075,.083,.085)
    hazard=(band==6)&(np.mod(x*13+y*23,1)>.5)
    base[hazard]=(.016,.018,.019)
    rough=.58+micro*.20; metal=np.where(chip,.78,.24)
    normal=np.zeros_like(base)+(.5,.5,1)
    normal[:,:,1]+=(np.exp(-((v-.18)/.018)**2)-np.exp(-((v-.82)/.018)**2))*.12
    normal[:,:,:2]+=(micro-.5)[:,:,None]*.018
    vec=normal*2-1; vec/=np.linalg.norm(vec,axis=2,keepdims=True)
    emission=np.zeros_like(base)
    emission[(band==7)&(v>.23)&(v<.77)]=(.75,.025,.004)
    for name,rgb,color in [('base',base,True),('normal',vec*.5+.5,False),
            ('orm',np.stack([np.where(groove,.6,1),rough,metal],2),False),('emission',emission,True)]:
        lib.save_image(folder/('trim_'+name+'.png'),np.clip(rgb,0,1),color)


def loft(name, sections, yc, band=0):
    # Explicit flat belly and vertical bow face, with two chines. Width tapers
    # in plan only: the bow does not rake upward like a boat's stem.
    ring=[(-.70,1),(.70,1),(1,.48),(1,-.48),(.70,-1),(-.70,-1),(-1,-.48),(-1,.48)]
    verts=[(x,yc+w*a,zc+h*b) for x,w,zc,h in sections for a,b in ring]
    faces=[tuple(reversed(range(8))),tuple(range((len(sections)-1)*8,len(sections)*8))]
    for k in range(len(sections)-1):
        for j in range(8):
            faces.append((k*8+j,k*8+(j+1)%8,(k+1)*8+(j+1)%8,(k+1)*8+j))
    obj=finish(lib.mesh(name,verts,faces),band,.0020)
    # Large hull faces use the quiet centre of the shared trim. Stretching
    # its edge grooves across a whole flank creates a naval-looking deck line.
    uv=obj.data.uv_layers.active.data
    for p in obj.data.polygons:
        if p.area>.0015:
            for li in p.loop_indices:
                q=(uv[li].uv.y*8-band-.07)/.86
                uv[li].uv.y=(band+.24+q*.52)/8
    return obj


def join(objects,name):
    lib.active(objects[0])
    for o in objects:o.select_set(True)
    bpy.ops.object.join()
    obj=bpy.context.object; obj.name=name
    # A joined kit otherwise inherits its first mount's rotated local frame.
    # Godot transforms that frame's AABB conservatively, enlarging empty bounds
    # and shrinking the displayed ship. Export real hull-frame bounds instead.
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    return obj


def weighted(obj):
    mod=obj.modifiers.new('weighted_manufactured_normals','WEIGHTED_NORMAL')
    mod.keep_sharp=True;mod.weight=50
    lib.apply(obj,mod)


def shell():
    # Four donor masses, from a4/ships.py compose placements and the retained
    # donor's measured extents. Round 1 incorrectly moved the upper hull sideways.
    main=loft('carrier_armoured_body',[
        (-.46,.080,-.057,.080),(-.35,.105,-.057,.094),
        (-.15,.112,-.057,.094),(.12,.112,-.057,.094),
        (.31,.100,-.057,.089),(.43,.070,-.057,.078),(.495,.032,-.057,.067)],0,0)
    port=loft('captured_port_hull',[
        (-.44,.042,-.055,.052),(-.34,.067,-.055,.062),
        (.10,.067,-.055,.062),(.29,.053,-.055,.057),(.37,.020,-.055,.048)],.17,1)
    star=loft('captured_starboard_hull',[
        (-.19,.037,-.100,.048),(-.12,.063,-.100,.060),
        (.24,.063,-.100,.060),(.35,.046,-.100,.050),(.405,.018,-.100,.043)],-.18,2)
    upper=loft('captured_upper_hull',[
        (-.40,.033,.102,.047),(-.33,.061,.102,.053),
        (-.08,.061,.102,.053),(.09,.047,.102,.048),(.17,.017,.102,.038)],0,1)
    box('upper_load_saddle',(-.14,0,.041),(.36,.076,.043),3)
    box('port_weld_beam',(-.04,.111,-.064),(.64,.056,.055),3)
    box('starboard_weld_beam',(.08,-.118,-.092),(.39,.056,.065),3)
    obj=join(PARTS[:],'clean_four_mass_shell')
    weighted(obj)
    PARTS.clear(); PARTS.append(obj)
    return obj


def tree(obj):
    bpy.context.view_layer.update()
    return BVHTree.FromObject(obj,bpy.context.evaluated_depsgraph_get())


def hit(x,y,axis=2,sign=1):
    if axis==2:
        start=Vector((x,y,sign*1.2))
    else:
        start=Vector((x,sign*1.2,y))
    d=Vector((0,0,0));d[axis]=-sign
    p,n,_,_=TREE.ray_cast(start,d,3)
    return (p,n) if p is not None else (None,None)


def mounted(name,p,n,size,band=3,bevel=.0008):
    # Local XY lies on the mounting plane. The bottom is set .00025 into the
    # host so visible bevels do not open a gap after export.
    p,n=Vector(p),Vector(n).normalized()
    obj=box(name,p+n*(size[2]*.5-.00025),size,band,bevel)
    tangent=Vector((1,0,0));tangent=(tangent-n*tangent.dot(n)).normalized()
    bitangent=n.cross(tangent)
    obj.rotation_euler=Matrix([tangent,bitangent,n]).transposed().to_euler()
    gap=TREE.find_nearest(p)[3]
    assert gap<.0001
    CONTACTS.append(dict(part=obj.name,host=CORE.name,anchor=list(p),normal=list(n),gap=float(gap)))
    return obj,tangent,bitangent


def mounted_top(name,x,y,size,band=3):
    p,n=hit(x,y)
    assert p is not None
    return mounted(name,p,n,size,band)[0]


def heroes():
    # Each root uses a raycast onto the final clean shell, with a visible plate.
    # Turrets fire +X and outboard, never through the hull.
    for x in [-.19,.11]:
        for s in [-1,1]:
            p,n=hit(x,-.075,1,s)
            if p is None:continue
            base,_,_=mounted('gun_mount_flange',p,n,(.062,.043,.012),3)
            c=p+n*.008
            cyl('gun_trunnion',c,.020,.018,(0,s,0),4)
            d=Vector((.78,s*.62,.04)).normalized()
            for dz in [-.007,.007]:
                start=c+Vector((.005,s*.006,dz))
                cyl('forward_outward_barrel',start+d*.012,.0037,.032,d,3)
                cyl('muzzle_collar',start+d*.027,.0054,.009,d,4)
                GUNS.append(list(d))
    for x in [-.24,-.03]:
        p,n=hit(x,0)
        mounted('equipment_raft',p,n,(.09,.070,.012),3)
        box('command_equipment',p+Vector((0,0,.022)),(.061,.048,.032),0,.002)
        box('sensor_crown',p+Vector((0,0,.043)),(.046,.035,.009),4)
        box('sensor_glass',p+Vector((.026,0,.027)),(.002,.031,.009),5,.0003)
        if x<-.1:
            for dy in [-.017,.017]:
                cyl('antenna_root',p+Vector((0,dy,.050)),.003,.012,(0,0,1),3,12)
                cyl('short_antenna',p+Vector((0,dy,.062)),.0012,.018,(0,0,1),4,8)
    p,n=hit(.28,0)
    mounted('launcher_raft',p,n,(.103,.071,.012),3)
    for y in [-.022,0,.022]:
        for z in [.020,.039]:
            cyl('forward_launcher',p+Vector((0,y,z)),.0095,.092,(1,0,0),4)
            cyl('launcher_dark_mouth',p+Vector((.0465,y,z)),.007,.001,(1,0,0),5)
            GUNS.append([1,0,0])
    for x,y in [(-.32,0),(-.26,.17),(.09,-.18)]:
        p,n=hit(x,y)
        mounted('radiator_mount',p,n,(.065,.046,.009),3)
        for dx in [-.022,-.011,0,.011,.022]:
            box('heat_radiator_fin',p+Vector((dx,0,.024)),(.004,.043,.041),5,.0004)
        link('radiator_coolant',p+Vector((-.027,-.020,.008)),p+Vector((.027,-.020,.008)),.002,4)
    # Six engine bells, supported by the actual stern faces, not naval funnels.
    for x,y,z,r in [(-.46,-.044,-.035,.030),(-.46,.044,-.035,.030),
            (-.46,0,-.108,.023),(-.44,.17,-.055,.032),
            (-.19,-.18,-.100,.028),(-.40,0,.102,.026)]:
        cyl('engine_mount', (x+.003,y,z),r*1.19,.020,(-1,0,0),3)
        # Hollow bells with rings, throat and dark cavity.
        cyl('engine_bell',(x-.012,y,z),r,.026,(-1,0,0),4)
        cyl('engine_cavity',(x-.026,y,z),r*.79,.001,(-1,0,0),5)
        cyl('engine_hot_throat',(x-.027,y,z),r*.41,.001,(-1,0,0),7)
        for a in np.linspace(0,2*math.pi,8,endpoint=False):
            at=Vector((x-.014,y+r*math.cos(a),z+r*math.sin(a)))
            link('engine_collar_rib',at+Vector((-.012,0,0)),at+Vector((.014,0,0)),.0017,3)
    # Larger service trunks give the salvage masses a mechanical connection,
    # rather than relying on tiny hatches to dress long uninterrupted decks.
    for y,xs in [(-.074,[-.37,-.27,-.16,-.05]),(.074,[-.37,-.27,-.16,-.05]),
                 (.197,[-.35,-.23,-.10,.03,.16]),(-.207,[-.09,.02,.13,.24])]:
        for x0,x1 in zip(xs,xs[1:]):
            p,n=hit(x0,y);q,m=hit(x1,y)
            if p is None or q is None or min(n.z,m.z)<.85:continue
            for at,n0 in [(p,n),(q,m)]:
                mounted('service_trunk_saddle',at,n0,(.014,.028,.006),3)
            for dy in [-.0075,.0075]:
                offset=Vector((0,dy,.010))
                link('exposed_service_trunk',p+offset,q+offset,.0031,4)
                for at in [p,q]:
                    cyl('pipe_union',at+offset,.0042,.008,(1,0,0),3,12)
    for x,y in [(-.27,0),(.31,0),(.12,-.18),(-.15,.17)]:
        p,n=hit(x,y,2,-1)
        if p is None or n.z>-.85:continue
        mounted('ventral_thruster_armour',p,n,(.046,.038,.008),3)
        cyl('ventral_thruster_bell',p+n*.012,.014,.020,n,4)
        cyl('ventral_thruster_cavity',p+n*.023,.011,.002,n,5)
        cyl('ventral_thruster_core',p+n*.0242,.005,.001,n,7)


def surface_details(density=1.0):
    count=0
    # Jittered, unequal rows distribute parts. The final raycast tests the real
    # surface, including chines. Alternating sizes stop the old paint grid read.
    for axis,sign in [(2,1),(2,-1),(1,1),(1,-1)]:
        for x in np.arange(-.405,.415,.048):
            vs=np.arange(-.23,.24,.041) if axis==2 else np.arange(-.137,.135,.040)
            for v in vs:
                if RNG.random()>.80*density:continue
                xx=x+RNG.uniform(-.012,.012);vv=v+RNG.uniform(-.009,.009)
                p,n=hit(xx,vv,axis,sign)
                if p is None or n[axis]*sign<.82:continue
                if axis==2 and sign==1 and abs(vv)<.041 and (-.37<xx<.02 or .22<xx<.35):continue
                w=RNG.uniform(.025,.049);h=RNG.uniform(.023,.039)
                obj,t,b=mounted('welded_salvage_plate',p,n,(w,h,.0038),int(RNG.choice([0,0,0,1,1,2,3,4])))
                # Four physical fasteners per large plate, on the actual plate.
                top=p+n*.004
                for a,c in [(-1,-1),(1,-1),(-1,1),(1,1)]:
                    cyl('plate_bolt',top+t*(a*w*.39)+b*(c*h*.35),.00115,.0016,n,4,8)
                if count%4==0:
                    c=top+n*.003
                    mounted_obj=box('service_hatch',c,(w*.52,h*.62,.004),3,.0006)
                    mounted_obj.rotation_euler=obj.rotation_euler
                    link('hatch_handle',c+n*.003-t*.004,c+n*.003+t*.004,.0009,4)
                elif count%4==1:
                    for i in range(4):
                        a=top+t*((i-1.5)*w*.16)+n*.002
                        link('vent_louvre',a-b*h*.28,a+b*h*.28,.0015,5)
                elif count%4==2:
                    a=top-t*w*.35-b*h*.25+n*.002
                    c=top+t*w*.23-b*h*.25+n*.002
                    e=c+b*h*.42
                    link('conduit_run',a,c,.0019,4)
                    link('conduit_elbow',c,e,.0019,4)
                if count%9==0:
                    # Bone registration bars. Separate decal-like thin faces,
                    # attached to the plate, without projected concept imagery.
                    for i in range(3):
                        mark=box('registration_decal',top+n*.001+t*((i-1)*.004),(.002,.010,.0005),0,.0001)
                        mark.rotation_euler=obj.rotation_euler
                count+=1
    return count


def source(pc):
    path=pc/'a4/out/C19_51/C19_51_ship.npz'
    a=np.load(path)
    pos=np.stack([a['pos'][:,0],-a['pos'][:,2],a['pos'][:,1]],1)
    pos,remap=np.unique(np.round(pos,6),axis=0,return_inverse=True)
    idx=remap[a['idx']]
    _,unique=np.unique(np.sort(idx,axis=1),axis=0,return_index=True)
    idx=idx[np.sort(unique)]
    high=lib.mesh('donor_geometry_only',pos,idx)
    for p in high.data.polygons:p.use_smooth=True
    return high,path,pos,idx


def blur(a,steps=(1,2,4,8)):
    a=a.copy()
    for step in steps:
        a=(a+np.roll(a,step,0)+np.roll(a,-step,0)+np.roll(a,step,1)+np.roll(a,-step,1))/5
    return a


def flatten_trim(obj,shared,folder,res,cavity):
    """Raster shared trim UV1 into unique UV0 for Godot's material path."""
    obj.data.calc_loop_triangles()
    u0=obj.data.uv_layers[0].data;u1=obj.data.uv_layers[1].data
    coords=np.zeros((res,res,2),np.float32);mask=np.zeros((res,res),bool)
    for tri in obj.data.loop_triangles:
        t=np.array([u0[i].uv[:] for i in tri.loops])*(res-1)
        lo=np.maximum(0,np.floor(t.min(0)).astype(int));hi=np.minimum(res-1,np.ceil(t.max(0)).astype(int))
        xx,yy=np.meshgrid(np.arange(lo[0],hi[0]+1),np.arange(lo[1],hi[1]+1))
        den=np.cross(t[1]-t[0],t[2]-t[0]).item()
        if abs(den)<1e-7:continue
        qx,qy=xx-t[0,0],yy-t[0,1]
        a=(qx*(t[2,1]-t[0,1])-qy*(t[2,0]-t[0,0]))/den
        b=((t[1,0]-t[0,0])*qy-(t[1,1]-t[0,1])*qx)/den
        inside=(a>=-.001)&(b>=-.001)&(a+b<=1.001)
        px,py=xx[inside],yy[inside]
        q=np.array([u1[i].uv[:] for i in tri.loops])
        coords[py,px]=q[0]+a[inside,None]*(q[1]-q[0])+b[inside,None]*(q[2]-q[0])
        mask[py,px]=True
    for name,color in [('base',True),('orm',False),('emission',True)]:
        im=bpy.data.images.load(str(shared/('trim_'+name+'.png')))
        im.colorspace_settings.name='sRGB' if color else 'Non-Color'
        w,h=im.size;px=np.empty(w*h*4,np.float32);im.pixels.foreach_get(px)
        px=px.reshape(h,w,4)[:,:,:3]
        uv=np.clip(coords,0,1)*np.array([w-1,h-1])
        x0=np.floor(uv[:,:,0]).astype(int);y0=np.floor(uv[:,:,1]).astype(int)
        x1=np.minimum(x0+1,w-1);y1=np.minimum(y0+1,h-1)
        fx=(uv[:,:,0]-x0)[:,:,None];fy=(uv[:,:,1]-y0)[:,:,None]
        rgb=(px[y0,x0]*(1-fx)+px[y0,x1]*fx)*(1-fy)+(px[y1,x0]*(1-fx)+px[y1,x1]*fx)*fy
        if name=='orm':rgb[:,:,0]=cavity
        lib.save_image(folder/(name+'.png'),lib.dilate(rgb,mask,24),color)


def bake_shell(high,low,folder,res):
    lib.gpu()
    lib.active(low)
    # Preserve shared trim coordinates on UV1; UV0 is unique for donor bakes.
    low.data.uv_layers.active.name='trim'
    low.data.uv_layers.new(name='bake',do_init=False)
    low.data.uv_layers.active_index=1
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(55),island_margin=.008)
    bpy.ops.object.mode_set(mode='OBJECT')
    # Reorder so glTF normal tangents are generated from the unique bake UVs.
    bake_uv=np.array([u.uv[:] for u in low.data.uv_layers['bake'].data])
    trim_uv=np.array([u.uv[:] for u in low.data.uv_layers['trim'].data])
    low.data.uv_layers['trim'].name='bake0'
    low.data.uv_layers['bake'].name='trim'
    for u,q in zip(low.data.uv_layers[0].data,bake_uv):u.uv=q
    for u,q in zip(low.data.uv_layers[1].data,trim_uv):u.uv=q
    low.data.uv_layers.active_index=0
    low.data.uv_layers[0].active_render=True
    mask=lib.atlas_positions(low,res)[2]
    mat=bpy.data.materials.new('bake_target');mat.use_nodes=True
    low.data.materials.clear();low.data.materials.append(mat)
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage');mat.node_tree.nodes.active=tex
    sc=bpy.context.scene
    sc.render.bake.use_selected_to_active=True
    sc.render.bake.cage_extrusion=.055
    sc.render.bake.max_ray_distance=.14
    sc.render.bake.margin=24
    results={}
    # Cycles pointiness is a geometry-curvature estimate on the donor mesh.
    # Bake it as emission so no light or old albedo can enter the map.
    curvature_mat=bpy.data.materials.new('donor_geometry_curvature')
    curvature_mat.use_nodes=True
    cnt=curvature_mat.node_tree;cnt.nodes.clear()
    geo=cnt.nodes.new('ShaderNodeNewGeometry')
    emit=cnt.nodes.new('ShaderNodeEmission')
    output=cnt.nodes.new('ShaderNodeOutputMaterial')
    cnt.links.new(geo.outputs['Pointiness'],emit.inputs['Color'])
    cnt.links.new(emit.outputs[0],output.inputs['Surface'])
    high.data.materials.clear();high.data.materials.append(curvature_mat)
    for typ in ['NORMAL','AO','EMIT']:
        im=bpy.data.images.new(typ,width=res,height=res,float_buffer=True)
        im.colorspace_settings.name='Non-Color';tex.image=im
        lib.active(low);high.select_set(True)
        sc.cycles.samples=16 if typ=='AO' else 1
        bpy.ops.object.bake(type=typ,normal_space='TANGENT')
        raw=np.empty(res*res*4,np.float32);im.pixels.foreach_get(raw)
        results[typ]=raw.reshape(res,res,4)[:,:,:3].copy()
    raw=results['NORMAL'];raw[~mask]=(.5,.5,1)
    raw=lib.dilate(raw,mask,28)
    lib.save_image(folder/'normal_raw.png',raw)
    vec=raw*2-1;vec/=np.maximum(np.linalg.norm(vec,axis=2,keepdims=True),1e-6)
    flat=np.array([0,0,1],np.float32)
    deviation=vec-flat
    slow=blur(deviation,(1,2,4,8,12,16))
    residual=(deviation-slow)*.52
    filtered=flat+residual
    filtered[:,:,2]=np.maximum(filtered[:,:,2],.5)
    tilt=np.linalg.norm(filtered[:,:,:2],axis=2)
    filtered[:,:,:2]*=np.minimum(1,.28/np.maximum(tilt,1e-6))[:,:,None]
    filtered/=np.linalg.norm(filtered,axis=2,keepdims=True)
    lib.save_image(folder/'normal.png',lib.dilate(filtered*.5+.5,mask))
    # AO is measured from donor geometry, then only its local cavity component
    # is used. The shared trim still determines colour/roughness/metal.
    ao=results['AO'].mean(2);ao[~mask]=1
    ao=lib.dilate(np.repeat(ao[:,:,None],3,2),mask,28)[:,:,0]
    cavity=np.clip(1-np.maximum(blur(ao)-ao,0)*1.8,.45,1)
    lib.save_image(folder/'ao_raw.png',np.repeat(ao[:,:,None],3,2))
    curve=results['EMIT'].mean(2);curve[~mask]=.5
    curve=lib.dilate(np.repeat(curve[:,:,None],3,2),mask,28)[:,:,0]
    lib.save_image(folder/'curvature_raw.png',np.repeat(curve[:,:,None],3,2))
    curvature=np.clip(.5+(curve-blur(curve))*2,0,1)
    lib.save_image(folder/'curvature.png',np.repeat(curvature[:,:,None],3,2))
    cavity*=1-np.maximum(.5-curvature,0)*.25
    lib.save_image(folder/'cavity.png',np.repeat(cavity[:,:,None],3,2))
    # Resample the same shared trim into UV0 so Godot's material importer
    # cannot silently substitute the wrong UV set for albedo or normals.
    flatten_trim(low,folder.parents[1]/'shared',folder,res,cavity)
    mat=lib.material(folder);mat.name='shared_trim_with_donor_cavity'
    nt=mat.node_tree
    group=bpy.data.node_groups.get('glTF Material Output')
    if group is None:
        group=bpy.data.node_groups.new('glTF Material Output','ShaderNodeTree')
        group.interface.new_socket(name='Occlusion',in_out='INPUT',socket_type='NodeSocketFloat')
    gn=nt.nodes.new('ShaderNodeGroup');gn.node_tree=group
    orm=next(n for n in nt.nodes if n.type=='TEX_IMAGE' and n.image.name.startswith('orm'))
    separate=nt.nodes.new('ShaderNodeSeparateColor')
    nt.links.new(orm.outputs['Color'],separate.inputs[0]);nt.links.new(separate.outputs['Red'],gn.inputs['Occlusion'])
    low.data.materials.clear();low.data.materials.append(mat)
    interior=mask.copy()
    for _ in range(3):
        interior&=np.roll(interior,1,0)&np.roll(interior,-1,0)&np.roll(interior,1,1)&np.roll(interior,-1,1)
    before=float(np.sqrt(np.mean(blur(deviation)[interior]**2)))
    after=float(np.sqrt(np.mean(blur(filtered-flat)[interior]**2)))
    return dict(gpu='OPTIX',occupied_texels=int(mask.sum()),
        normal_filter='normalize(flat + high_pass(normalize(raw)-flat)); flat=(0,0,1); 15.6 degree cap',
        low_frequency_rms_before=before,low_frequency_rms_after=after,
        normal_mean_z=float(filtered[:,:,2][mask].mean()),
        trim_mapping='shared trim UV1 resampled into bake UV0; every exported texture uses UV0',
        curvature_method='Cycles Geometry Pointiness on donor, selected-to-active EMIT bake, local residual',
        maps=['normal_raw.png','normal.png','ao_raw.png','curvature_raw.png','curvature.png','cavity.png'])


def reused_parts(pos,idx):
    # Small hard parts only. Crop using all vertices inside the box, discard
    # tiny islands and the soft skin nearest the base, flatten a short mounting
    # skirt. No original material or large hull section is reused.
    boxes=[('sensor_cluster',(-.13,-.075,-.037,.037,.155,.205)),
           ('machinery_cluster',(-.29,-.265,-.020,.020,.130,.155)),
           ('engine_housing',(-.43,-.37,.135,.205,-.095,-.025)),
           ('service_cluster',(.02,.075,.145,.215,-.020,.040))]
    candidates=[]
    for name,(x0,x1,y0,y1,z0,z1) in boxes:
        inside=(pos[:,0]>x0)&(pos[:,0]<x1)&(pos[:,1]>y0)&(pos[:,1]<y1)&(pos[:,2]>z0)&(pos[:,2]<z1)
        faces=idx[np.all(inside[idx],axis=1)]
        if len(faces)<30:continue
        used,inv=np.unique(faces,return_inverse=True)
        v=pos[used].copy();v-=v.min(0)
        # Keep the source's fine shape, but only a short flat mounting skirt.
        v[v[:,2]<.004,2]=0
        candidates.append((name,v,inv.reshape(-1,3)))
    assert len(candidates)>=2,'Not enough suitable donor pieces'
    report=[]
    sites=[(-.36,.17),(-.21,.17),(-.05,.17),(.12,.17),(.26,.17),
           (-.11,-.18),(.03,-.18),(.22,-.18),(.32,-.18),
           (-.34,0),(-.13,.068),(.08,.065),(.18,-.065),(.36,0)]
    for i,(x,y) in enumerate(sites):
        p,n=hit(x,y)
        if p is None or n.z<.85:continue
        name,v,faces=candidates[i%len(candidates)]
        print('[surface111] reuse chunk',i,name,len(faces),flush=True)
        # Original chunks never exceed 7 percent of donor length.
        factor=min(1,.062/max(np.ptp(v,axis=0)))
        v=v*factor
        extent=np.ptp(v,axis=0)
        v[:,:2]-=extent[:2]/2
        base,_,_=mounted('reused_part_visible_mount',p,n,(extent[0]+.011,extent[1]+.011,.006),3)
        # Array-based cleaning avoids corrupt BMesh edge cycles in the donor.
        # Weld coincident vertices, remove collapsed triangles and small loose
        # islands, and construct a separate genuinely flat bottom face.
        v,remap=np.unique(np.round(v,6),axis=0,return_inverse=True)
        faces=remap[faces]
        ar=np.linalg.norm(np.cross(v[faces[:,1]]-v[faces[:,0]],v[faces[:,2]]-v[faces[:,0]]),axis=1)
        faces=faces[ar>1e-11]
        parent=np.arange(len(v))
        def root(q):
            while parent[q]!=q:parent[q]=parent[parent[q]];q=parent[q]
            return q
        for f in faces:
            for a,b in [(f[0],f[1]),(f[1],f[2])]:
                a,b=root(a),root(b)
                if a!=b:parent[b]=a
        groups=np.array([root(int(f[0])) for f in faces])
        keys,counts=np.unique(groups,return_counts=True)
        keep=keys[counts>=12]
        faces=faces[np.isin(groups,keep)]
        vertices=v.tolist()
        a=len(vertices);w,h=extent[:2]/2
        vertices += [[-w,-h,0],[-w,h,0],[w,h,0],[w,-h,0]]
        polygons=faces.tolist()+[[a,a+1,a+2,a+3]]
        obj=lib.mesh('AI_'+name,vertices,polygons)
        obj.data.materials.append(MAT)
        uv=obj.data.uv_layers.new(name='trim');band=[4,1,3,0][i%4]
        vmin=v.min(0);vsize=np.maximum(np.ptp(v,axis=0),1e-6)
        for poly in obj.data.polygons:
            poly.use_smooth=True
            axis=int(np.argmax(np.abs(poly.normal[:])))
            axes=[k for k in range(3) if k!=axis]
            for li in poly.loop_indices:
                co=np.array(obj.data.vertices[obj.data.loops[li].vertex_index].co)
                q=(co-vmin)/vsize
                uv.data[li].uv=(.012+q[axes[0]]*.976,(band+.07+q[axes[1]]*.86)/8)
        obj.data.set_sharp_from_angle(angle=math.radians(35))
        PARTS.append(obj)
        obj.location=p+n*.005
        obj.rotation_euler=n.to_track_quat('Z','Y').to_euler()
        # The skirt is given a real flat plate bonded to the cleaned cut face.
        skirt=box('AI_chunk_flat_base',p+n*.006,(extent[0],extent[1],.003),3,.0004)
        skirt.rotation_euler=base.rotation_euler
        report.append(dict(part=obj.name,source_box=name,source_triangles=len(faces),
                           largest_dimension=float(extent.max()),mount=base.name,flat_base=True))
    assert len(report)>=10
    return report


def main():
    global MAT,TREE,CORE
    ap=argparse.ArgumentParser();ap.add_argument('--pc',type=Path,required=True)
    ap.add_argument('--work',type=Path,required=True)
    ap.add_argument('--route',choices=['Aplus','Bake','Reuse','trim'],required=True)
    ap.add_argument('--res',type=int,default=2048)
    args=ap.parse_args(sys.argv[sys.argv.index('--')+1:])
    start=time.perf_counter();bpy.ops.wm.read_factory_settings(use_empty=True)
    shared=args.work/'shared'
    if args.route=='trim':trim(shared,args.res);return
    MAT=lib.material(shared,'trim_');MAT.name='Hullbreaker_shared_trim'
    folder=args.work/'C19_51'/args.route;folder.mkdir(parents=True,exist_ok=True)
    CORE=shell();TREE=tree(CORE)
    print('[surface111] shell ready',args.route,flush=True)
    high,path,pos,idx=source(args.pc)
    meta=dict(source=str(path),source_sha256=lib.sha(path),source_triangles=len(idx),
              shared_trim_sha256={p.name:lib.sha(p) for p in shared.glob('*.png')})
    if args.route=='Bake':meta.update(bake_shell(high,CORE,folder,args.res))
    bpy.data.objects.remove(high,do_unlink=True)
    heroes()
    print('[surface111] hero kit ready',args.route,flush=True)
    meta['surface_clusters']=surface_details(.92 if args.route=='Aplus' else .65)
    print('[surface111] surface ready',args.route,meta['surface_clusters'],flush=True)
    if args.route=='Reuse':meta['reused_parts']=reused_parts(pos,idx)
    print('[surface111] assembly ready',args.route,flush=True)
    assert all(d[0]>=0 for d in GUNS)
    meta.update(contact_anchors=CONTACTS,contact_count=len(CONTACTS),backward_guns=0,gun_directions=GUNS,
                geometry='four clean donor-mass lofts, flat armoured belly, manufactured kit',parts=len(PARTS))
    # Joining by UV layout preserves the baked hull's two UV channels.
    objects=[CORE]
    rest=[o for o in PARTS if o!=CORE]
    if rest:
        kit=join(rest,'shared_trim_surface_kit');weighted(kit);objects.append(kit)
    meta.update(lib.export(objects,folder,args.route))
    meta.update(route=args.route,code='C19_51',seconds=time.perf_counter()-start)
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/'prototype.blend'))
    (folder/'build.json').write_text(json.dumps(meta,indent=2)+'\n')
    print('[surface111] BUILD PASS',args.route,meta['triangles'],flush=True)


if __name__=='__main__':main()
