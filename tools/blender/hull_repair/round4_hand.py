"""Hand-built primary masses and fitted kit, traced from the new references.

No source AI mesh is loaded or measured here. Coordinate tables are the
normalised reference silhouette and landmark drawing recorded in the report.
The c19 kit conventions and detail_lib supply the established detail language.
"""
import json
import math
from pathlib import Path
import sys
import time

import bpy
import numpy as np
from mathutils import Vector, Matrix


def build(a,folder,kit,lib,paint,assign,marks):
    start=time.perf_counter()
    sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'hs'))
    import detail_lib as detail
    import hs_lib as hs
    kit.PARTS.clear();kit.CONTACTS.clear();kit.GUNS.clear();hs.PARTS.clear()
    palette={}
    def material(band,variation=1):
        key=(band,variation)
        if key not in palette:
            m=bpy.data.materials.new('authored_'+str(band)+'_'+str(variation))
            m['round4_band']=band;m['variation']=variation;palette[key]=m
        return palette[key]
    kit.MAT=material(0)
    def colour(obj,band,variation=1):
        obj.data.materials.clear();obj.data.materials.append(material(band,variation));return obj
    def box(name,at,size,band=0,bevel=.0007):
        return colour(kit.box(name,at,size,0,bevel),band)
    def cyl(name,at,r,depth,direction=(0,0,1),band=3,sides=16):
        return colour(kit.cyl(name,at,r,depth,direction,0,sides),band)
    def link(name,p,q,r=.0018,band=3):
        return colour(kit.link(name,p,q,r,0),band)
    # Reference tracing uses a vertical blunt bow and independent stepped pods.
    # Each tuple is (longitudinal station, half width, vertical centre, half height).
    tables={
        'spine':[(-.46,.052,-.025,.060),(-.34,.078,-.025,.071),(-.06,.092,-.025,.075),(.22,.087,-.025,.071),(.39,.068,-.025,.064),(.48,.055,-.025,.061)],
        'port':[(-.45,.035,-.040,.043),(-.34,.059,-.040,.052),(-.10,.061,-.040,.052),(.20,.057,-.040,.050),(.39,.042,-.040,.043)],
        'starboard':[(-.25,.034,-.082,.040),(-.15,.058,-.082,.047),(.13,.061,-.082,.048),(.31,.053,-.082,.045),(.42,.032,-.082,.039)],
        'upper':[(-.39,.032,.079,.036),(-.30,.051,.079,.040),(-.09,.052,.079,.040),(.12,.040,.079,.033),(.25,.028,.079,.029)]}
    for name,sections in tables.items():
        yc={'spine':0,'port':.146,'starboard':-.165,'upper':.004}[name]
        colour(kit.loft('reference_'+name,sections,yc,0),0 if name=='upper' else 1)
    for x in [-.30,-.12,.08,.25]:
        box('welded_cross_saddle',(x,0,-.02),(.047,.345,.035),3,.0011)
        for side in [-1,1]:
            box('salvage_saddle_cap',(x,side*.11,.018),(.062,.050,.028),0,.0013)
    core=kit.join(kit.PARTS[:],'reference_primary_masses');kit.weighted(core)
    kit.PARTS.clear();kit.CORE=core;kit.TREE=kit.tree(core)
    roots=[]
    def seat(name,x,y,size,band=3,axis=2,sign=1,z=0):
        if axis==0:
            p,n,_,_=kit.TREE.ray_cast(Vector((sign*1.2,y,z)),Vector((-sign,0,0)),3)
        else:p,n=kit.hit(x,y if axis==2 else z,axis,sign)
        if p is None:raise RuntimeError('Missing authored mount '+name)
        root,_,_=kit.mounted(name,p,n,size,0,.0006);colour(root,band)
        roots.append(dict(name=name,anchor=list(p),normal=list(n),gap=kit.CONTACTS[-1]['gap']))
        return p,n
    # Low bridge equipment, not a mast or conning tower.
    p,n=seat('bridge_visible_saddle',-.18,.004,(.16,.087,.008))
    for k in range(3):
        c=p+Vector((.010*k,0,.012+.010*k))
        box('bridge_armour_hood',c,(.148-.025*k,.082-.014*k,.017),0,.0011)
        for side in [-1,1]:
            box('bridge_dark_glazing',c+Vector((.025,side*(.041-.007*k),.003)),(.061,.0016,.004),1,.00025)
            box('bridge_red_slit',c+Vector((.015,side*(.042-.007*k),.003)),(.016,.0009,.0015),8,.00012)
        for x in [-.045,0,.045]:
            box('bridge_seam_plate',c+Vector((x,0,.009)),(.017,.065-.012*k,.0015),3,.0003)
    def tube(name,centre,direction,r,length,band=3):
        d=Vector(direction).normalized();t=d.orthogonal().normalized();b=d.cross(t)
        rings=[]
        for z,rad in [(-length/2,r),(length/2,r),(length/2,r*.70),(-length*.25,r*.70)]:
            rings.extend([Vector(centre)+d*z+(t*math.cos(i*math.tau/16)+b*math.sin(i*math.tau/16))*rad for i in range(16)])
        faces=[]
        for ring in range(3):
            for i in range(16):faces.append((ring*16+i,ring*16+(i+1)%16,(ring+1)*16+(i+1)%16,(ring+1)*16+i))
        obj=lib.mesh(name,rings,faces);kit.PARTS.append(obj);colour(obj,band)
        cyl(name+'_dark_recess',Vector(centre)-d*length*.20,r*.69,.0004,d,1,16)
        return obj
    # Six real open exhaust bells at the left stern, with cooling and feed pipes.
    for side in [-1,1]:
        for zoff in [-.024,.024]:
            p,n=seat('engine_bank_flange',-.43,side*.035,(.062,.054,.008),3,axis=0,sign=-1)
            c=Vector((-.485,side*.035,p.z+zoff))
            tube('open_engine_bell',c,(-1,0,0),.020,.034,3)
            cyl('emissive_engine_throat',c+Vector((.009,0,0)),.0135,.001,(-1,0,0),12,24)
            for k in range(8):
                angle=k*math.tau/8;offset=Vector((0,.021*math.cos(angle),.021*math.sin(angle)))
                link('bell_cooling_rib',c+offset+Vector((-.011,0,0)),c+offset+Vector((.015,0,0)),.0010,4)
        p,n=seat('aux_engine_flange',-.40,side*.145,(.053,.048,.008),3,axis=0,sign=-1,z=-.065)
        c=p+Vector((-.022,0,0));tube('aux_open_bell',c,(-1,0,0),.018,.027,3)
        cyl('aux_engine_throat',c+Vector((.006,0,0)),.011,.001,(-1,0,0),12,20)
    # Paired dense 4 by 3 and 3 by 3 rocket racks, all forward-facing.
    for side in [-1,1]:
        for rack,(x,y,nx,ny) in enumerate([(.21,side*.075,4,3),(.30,side*.165,3,3)]):
            p,n=seat('rocket_mount',x,y,(.078,.057,.007))
            c=p+Vector((0,0,.021));box('rocket_armoured_case',c,(.057,.057,.042),1,.0012)
            for iy in range(nx):
                for iz in range(ny):
                    q=c+Vector((.026,(iy-(nx-1)/2)*.012,(iz-(ny-1)/2)*.012))
                    tube('forward_rocket_tube',q,(1,0,0),.005,.028,3)
                    kit.GUNS.append([1,0,0])
            box('rack_overlapping_hood',c+Vector((0,0,.024)),(.063,.064,.0035),0,.0006)
            for z in [-.013,0,.013]:box('rack_service_seam',c+Vector((-.029,0,z)),(.001,.047,.001),3,.0002)
    for side in [-1,1]:
        for x in [.09,.32]:
            p,n=seat('gun_visible_mount',x,side*.17,(.058,.044,.008))
            c=p+Vector((0,0,.019));cyl('turret_bearing',c,.023,.017,(0,0,1),3,24)
            box('salvaged_turret',c+Vector((.002,0,.014)),(.044,.039,.023),0,.0015)
            d=Vector((.80,side*.60,.025)).normalized()
            for z in [-.005,.005]:
                q=c+Vector((.019,0,.014+z))+d*.016
                tube('short_forward_outward_gun',q,d,.0038,.041,3)
                cyl('barrel_armour_sleeve',q-d*.009,.0059,.019,d,4,16);kit.GUNS.append(list(d))
    # Listening dishes and sniffer scoops identify the refreshed faction design.
    for side in [-1,1]:
        p,n=seat('dish_visible_base',.25,side*.062,(.034,.030,.006))
        c=p+Vector((-.008,0,.044));link('dish_gimbal',p+n*.005,c,.004,3)
        d=Vector((.91,side*.15,.38)).normalized();t=d.orthogonal().normalized();b=d.cross(t)
        vertices=[c]
        for ring in range(1,7):
            r=.031*ring/6
            for i in range(32):
                angle=i*math.tau/32;vertices.append(c+(t*math.cos(angle)+b*math.sin(angle))*r+d*(r/.031)**2*.009)
        faces=[(0,1+i,1+(i+1)%32) for i in range(32)]
        for ring in range(5):
            for i in range(32):faces.append((1+ring*32+i,1+ring*32+(i+1)%32,1+(ring+1)*32+(i+1)%32,1+(ring+1)*32+i))
        dish=lib.mesh('shallow_listening_dish',vertices,faces);kit.PARTS.append(dish);colour(dish,3)
        solid=dish.modifiers.new('dish_plate_thickness','SOLIDIFY');solid.thickness=.0007;lib.apply(dish,solid)
        link('dish_receiver',c,c+d*.025,.0014,4)
        for k in range(4):
            angle=k*math.tau/4
            link('dish_rib',c+d*.001,c+(t*math.cos(angle)+b*math.sin(angle))*.029+d*.009,.0009,4)
        p,n=seat('wake_sniffer_mount',.41,side*.040,(.054,.034,.006))
        box('wake_sniffer_scoop',p+Vector((.008,0,.015)),(.056,.033,.024),1,.0011)
        for k in range(6):box('sniffer_louvre',p+Vector((.037,0,.005+k*.003)),(.003,.030,.0015),3,.0002)
    # Articulated claws fold alongside the forward modules on visible pads.
    for side in [-1,1]:
        p,n=seat('boarding_claw_socket',.29,0,(.042,.038,.008),3,axis=1,sign=side,z=-.065)
        q=p+Vector((.05,side*.025,-.015));r=q+Vector((.065,-side*.013,.008))
        link('claw_upper_arm',p,q,.007,0);link('claw_forearm',q,r,.0055,3)
        for c in [p,q,r]:cyl('claw_hinge',c,.010,.016,(0,side,0),4,20)
        for dz in [-.010,.010]:
            tip=r+Vector((.025,-side*.008,dz));link('claw_finger',r,tip,.0028,3)
            link('claw_hook',tip,tip+Vector((-.008,-side*.008,-dz*.5)),.0020,4)
    # Space radiators are short angled panels on support feet, never funnels.
    for side in [-1,1]:
        p,n=seat('radiator_saddle',-.32,side*.055,(.084,.039,.005))
        for k in range(3):
            c=p+Vector((k*.024-.024,0,.026))
            panel=box('heat_radiator',c,(.021,.005,.047),1,.0005)
            panel.rotation_euler.x=side*.28
            for j in range(10):box('radiator_fins',c+Vector((0,side*.003,(j-4.5)*.004)),(.018,.002,.0011),3,.0001)
            link('radiator_support',p+Vector((k*.024-.024,0,0)),c,.0020,3)
    # True alternating oval chain links, joining the exposed salvage saddles.
    for side in [-1,1]:
        for x0,x1 in [(-.30,-.12),(.08,.25)]:
            p0,_=kit.hit(x0,side*.105);p1,_=kit.hit(x1,side*.105)
            assert p0 is not None and p1 is not None
            for k in range(22):
                f=k/21;c=p0.lerp(p1,f)+Vector((0,0,.007-.015*math.sin(math.pi*f)))
                vertices=[]
                for i in range(16):
                    u=i*math.tau/16
                    for j in range(6):
                        v=j*math.tau/6
                        p=Vector(((.0046+.00085*math.cos(v))*math.cos(u),(.0030+.00085*math.cos(v))*math.sin(u),.00085*math.sin(v)))
                        if k%2:p=Vector((p.x,p.z,p.y))
                        vertices.append(c+p)
                faces=[]
                for i in range(16):
                    for j in range(6):faces.append((i*6+j,((i+1)%16)*6+j,((i+1)%16)*6+(j+1)%6,i*6+(j+1)%6))
                chain=lib.mesh('salvage_chain_link',vertices,faces);kit.PARTS.append(chain);colour(chain,4)
            for p in [p0,p1]:box('chain_anchor_lug',p+Vector((0,0,.004)),(.015,.017,.010),3,.0010)
    belly_start=len(kit.PARTS)
    for lane,y in enumerate([0,.146,-.165]):
        for i,x in enumerate(np.linspace(-.34,.36,9)):
            p,n=kit.hit(float(x),y,axis=2,sign=-1)
            if p is None or n.z>-.55:continue
            root,t,b=kit.mounted('belly_service_saddle',p,n,(.068,.038,.004),0,.0005);colour(root,3)
            c=p+n*.008
            body=box('belly_service_housing',c,(.049,.031,.012),1 if i%3 else 0,.0010)
            body.rotation_euler=root.rotation_euler
            if (i+lane)%2:
                for k in range(8):
                    fin=box('belly_vent_louvre',p+t*(-.020+k*.0057)+n*.015,(.0023,.028,.003),3,.0002)
                    fin.rotation_euler=root.rotation_euler
                for side in [-1,1]:
                    q=p+t*side*.024+n*.007
                    link('belly_feed_union',q,q+t*side*.012+b*.011,.0018,4)
            else:
                for k in range(3):
                    plate=box('belly_overlapping_armour',p+t*(-.004+k*.003)+n*(.014+k*.0025),(.052-k*.007,.034-k*.004,.003),0 if k%2 else 3,.0004)
                    plate.rotation_euler=root.rotation_euler
                for side in [-1,1]:
                    for q in [-1,1]:cyl('belly_plate_fastener',p+t*side*.017+b*q*.010+n*.022,.0011,.0015,n,4,8)
        for offset in [-.018,.018]:
            previous=None
            for x in np.linspace(-.37,.39,25):
                p,n=kit.hit(float(x),y+offset,axis=2,sign=-1)
                if p is None or n.z>-.55:previous=None;continue
                q=p+n*.006
                if previous is not None and (q-previous).length<.055:link('belly_pipe_bundle',previous,q,.0015,3)
                previous=q
    belly_count=len(kit.PARTS)-belly_start
    heroes=kit.PARTS[:]
    # Dense functional assemblies create intermediate masses between the
    # primary hulls and tiny rivets. Their roots all meet the authored hull.
    for side in [-1,1]:
        for i,x in enumerate(np.linspace(-.34,.38,11)):
            for j,z in enumerate([-.085,-.025,.045]):
                p,n=kit.hit(float(x),z,axis=1,sign=side)
                if p is None or abs(n.y)<.45:continue
                root,t,b=kit.mounted('machinery_mount',p,n,(.059,.028,.0035),0,.0005)
                colour(root,3);recipe=(i+j)%4
                def oriented(name,offset,size,band=0):
                    obj=box(name,p+t*offset[0]+b*offset[1]+n*offset[2],size,band,.00035)
                    obj.rotation_euler=root.rotation_euler;return obj
                if recipe==0:
                    for k in range(3):
                        oriented('overlapping_heavy_armour',(-.004+k*.004,-.003+k*.002,.004+k*.0024),(.057-k*.007,.025-k*.003,.003),0 if k!=1 else 1)
                    for k in range(6):
                        c=p+t*(-.023+k*.009)+b*.009+n*.011
                        cyl('stack_edge_fastener',c,.0009,.0014,n,4,8)
                elif recipe==1:
                    oriented('recessed_heat_exchanger',(0,0,.006),(.043,.023,.009),1)
                    for k in range(9):oriented('exchanger_fin',(-.018+k*.0045,0,.011),(.0017,.021,.003),3)
                    for k in [-1,1]:oriented('exchanger_frame',(k*.023,0,.008),(.0028,.027,.012),0)
                elif recipe==2:
                    for k in [-1,0,1]:
                        c=p+t*k*.015+n*.008
                        cyl('industrial_pressure_cell',c,.0065,.014,n,3,16)
                        cyl('cell_end_plate',c+n*.0075,.0053,.001,n,0,12)
                        for q in [-1,1]:link('cell_pipe_union',c+b*q*.006,c+b*q*.011,.0012,4)
                    oriented('pressure_cell_guard',(0,-.010,.012),(.054,.0025,.004),0)
                else:
                    oriented('junction_housing',(0,0,.007),(.036,.023,.011),0)
                    for k in range(4):oriented('housing_stepped_cap',(-.014+k*.009,0,.014),(.006,.022,.002),1)
                    for k in range(3):
                        c=p+t*(-.012+k*.012)-b*.012+n*.006
                        link('armoured_cable',c,c-b*.015-t*.008,.0014,3)
        for x in [-.25,-.08,.08,.25]:
            p,n=kit.hit(x,side*.038)
            if p is None:continue
            root,t,b=kit.mounted('roof_service_mount',p,n,(.072,.034,.004),0,.0005);colour(root,3)
            for k in range(3):
                cell=box('roof_service_bank',p+Vector((-.025+k*.025,0,.009)),(.018,.029,.013),0 if k%2 else 1,.0006)
                for q in range(5):box('roof_bank_rib',cell.location+Vector((0,-.011+q*.0055,.007)),(.016,.0012,.002),3,.00015)
    heroes=kit.PARTS[:]
    # Apply the established c19/detail_lib plate, pipe, seam and fitting pass.
    tagged=0
    def tag(rgb):
        nonlocal tagged
        bands=np.array(paint.PALETTE)
        band=int(np.square(bands-np.array(rgb)).sum(1).argmin())
        if band==8:band=0
        for obj in hs.PARTS[tagged:]:colour(obj,band,int(len(obj.name)%4))
        tagged=len(hs.PARTS)
    detail.detail_pass([core],heroes,tag,paint.PALETTE[0],(-.45,.47,-.12,.13),corsair=True,seed=146)
    tag(paint.PALETTE[0])
    detail.detail_pass([core],heroes+hs.PARTS[:],tag,paint.PALETTE[0],(-.45,.47,-.12,.13),corsair=True,seed=147)
    tag(paint.PALETTE[0])
    bpy.context.view_layer.update()
    dg=bpy.context.evaluated_depsgraph_get()
    for obj in hs.PARTS:
        if obj.modifiers:
            old=obj.data
            evaluated=bpy.data.meshes.new_from_object(obj.evaluated_get(dg),preserve_all_data_layers=True,depsgraph=dg)
            obj.modifiers.clear();obj.data=evaluated
            if old.users==0:bpy.data.meshes.remove(old)
    allobjects=[core]+heroes+hs.PARTS[:]
    # The top reference is about .32 widths per length. The working mount
    # layout is narrowed as a whole, including guns, dishes and weld saddles.
    bpy.context.view_layer.update()
    for o in allobjects:
        o.data.transform(o.matrix_world);o.matrix_world=Matrix.Identity(4)
        for vertex in o.data.vertices:vertex.co.y*=.74
        o.data.update()
    for root in roots:
        root['anchor'][1]*=.74
        n=Vector(root['normal']);n.y/=.74;root['normal']=list(n.normalized())
    for d in kit.GUNS:
        q=Vector((d[0],d[1]*.74,d[2])).normalized();d[:]=list(q)
    counts=assign(allobjects,a.pc,'V3')
    obj=kit.join(allobjects,'reference_authored_dense_barge')
    kit.weighted(obj)
    # Shared material language includes stencils and recessed running lamps.
    kit.MAT=material(0)
    accents=marks(obj,a.pc)
    if accents:
        assign(accents,a.pc,'V3');obj=kit.join([obj]+accents,'reference_authored_dense_barge')
    material_record=paint.bake(obj,a.pc,folder,lib)
    assert all(d[0]>=0 for d in kit.GUNS)
    reference=a.work/'reference/selection.json'
    return [obj],dict(source='hand construction from refreshed Qwen reference, no AI mesh input',
        hand_version=14605,belly_detail_objects=belly_count,
        reference_selection=json.loads(reference.read_text()),reference_sha256=lib.sha(reference),
        primary_sections=tables,primary_source='new reference side silhouette and top/front masses, manually traced',
        top_reference_width_per_length=.32,authored_lateral_scale=.74,
        construction_seconds=time.perf_counter()-start,material=material_record,new_materials=counts,
        mount_anchors=roots,gun_directions=kit.GUNS[:],
        kit_source=['tools/blender/hs/detail_lib.py','tools/blender/hs/c19_kit.py mount and trim conventions',
                    'tools/blender/surface_bakeoff/round2_build.py bevel and mounted primitives'],
        hero_objects=len(heroes),detail_objects=len(hs.PARTS))
