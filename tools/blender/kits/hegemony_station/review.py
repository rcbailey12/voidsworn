"""Build and render the station_T2 review sheet, CPU only.

blender -b -t 8 --python-exit-code 1 -P review.py -- --out DIR [--no-render]
Outputs are review assets. This script has no install or live-swap operation.
"""
import argparse
import json
import math
import os
from pathlib import Path
import sys
import hashlib

import bpy
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[3]
sys.path.insert(0,str(HERE))
import design as D
from parts import Parts
import stack
from scale import contract


def empty(name, parent=None, pos=(0,0,0)):
    ob=bpy.data.objects.new(name,None); bpy.context.collection.objects.link(ob)
    ob.parent=parent; ob.location=pos
    return ob


def build():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    root=empty(D.CODE)
    root['status']='BUILD SHEET - AWAITING BOARD REVIEW'
    root['station_kind']='fleet'; root['state']='T2 damaged'
    root['joints_json']=json.dumps(D.JOINTS)
    move=empty('T2_tethered_arm',root,D.MOTION['pivot'])
    move['period_seconds']=D.MOTION['period']; move['swing_period_seconds']=D.MOTION['swing_period']
    move['swing_degrees']=D.MOTION['swing_degrees']
    p=Parts(stack.materials())
    c=D.CORE
    for i in range(c['decks']):
        z=c['bottom']+i*c['pitch']
        p.record('core_%02d'%(i+1),'deck_drum',
                 ['command','medical','stores','power distribution','machinery',
                  'coolant plant','habitat support','stores','upper service deck'][i])
        p.drum(c['radius']*(1.0 if i<7 else .94),z,c['pitch']-.06,
               breach=i in (4,8))
        # Eight distinct inter-module bulkhead joints.
        if i<8:
            p.band(c['radius']-.1,c['radius']+.22,z+c['pitch']-.10,z+c['pitch']+.02,
                   steps=64,zone='trim')
        empty('joint_core_%02d'%(i+1),root,(0,0,z+c['pitch']))
    r=D.RING
    for i in range(r['slots']):
        if i==r['gap']: continue
        p.record('bearing_%02d'%i,'bearing_track','seized bearing slot; supports habitat module %d'%(i//2+1))
        a0=math.radians(i*30)+.012; a1=math.radians((i+1)*30)-.012
        z=r['bottom']; top=z+r['height']
        p.band(r['inner'],r['outer'],z-.20,z, a0,a1,10,'edge',torn=i in (9,11))
        p.band(r['inner'],r['outer'],top,top+.16,a0,a1,10,'edge',torn=i in (9,11))
        p.record('habitat_%d_slot_%02d'%(i//2+1,i),'habitat_arc',
                 'habitat module %d; corridor, cross frames, equipment racks'%(i//2+1))
        # Both walls, with separately modelled window recesses and flush plates.
        for radius in (r['inner'],r['outer']):
            p.band(radius-.11,radius,z,top,a0,a1,10,'liner',True,True)
            for j in range(10):
                aa=a0+(a1-a0)*j/10+.004; bb=a0+(a1-a0)*(j+1)/10-.004
                p.band(radius,radius+.055,z+.14,top-.14,aa,bb,1,
                       'plate2' if (i+j)%7==0 else 'plate')
                a=(aa+bb)*.5
                p.box((radius*math.cos(a),radius*math.sin(a),z+1.2),(.09,.32,.40),
                      'recess',rotation=a)
        for j in range(6):
            a=a0+(a1-a0)*j/5
            rm=(r['inner']+r['outer'])/2
            p.box((rm*math.cos(a),rm*math.sin(a),z+.12),
                  (r['outer']-r['inner']-.2,.13,.22),'frame',True,a)
            p.box((rm*math.cos(a),rm*math.sin(a),top+.24),
                  (r['outer']-r['inner']+.14,.12,.10),'trim',rotation=a)
            p.box(((rm+.45)*math.cos(a),(rm+.45)*math.sin(a),z+.70),
                  (.48,.65,.9),'rack',True,a)
        # Each half of an arc has its own corridor deck; the gap has no hidden cap.
        p.band(r['inner']+.12,r['outer']-.12,z+.2,z+.3,a0,a1,10,'deck',True)
        empty('joint_ring_%02d'%i,root,(rm*math.cos(a0),rm*math.sin(a0),z))
    for i,a in enumerate((32,138,225,322)):
        p.record('spoke_%d'%(i+1),'spoke','bearing support and service corridor; buckled' if i==3 else 'bearing support and service corridor')
        old=p.matrix.copy(); p.matrix=Matrix.Rotation(math.radians(a),4,'Z') @ Matrix.Translation(Vector((4.8,0,0)))
        if i==3:
            p.rod((0,0,0),(4.1,0,-1.3),.40,'liner',n=12,inside=True)
            p.rod((4.1,0,-1.3),(9.8,0,0),.40,'liner',n=12,inside=True)
            for s in (-1,1):
                p.rod((0,s*.42,.15),(4.1,s*.42,-1.1),.10)
                p.rod((4.1,s*.42,-1.1),(9.8,s*.42,.15),.10)
            for k in range(10):
                x=k*.98; zz=-1.3*(x/4.1 if x<4.1 else (9.8-x)/5.7)
                p.box((x,0,zz),(.55,.9,.12),'plate2')
        else:
            p.arm(9.8,1.1,4,cap=False)
        p.matrix=old
    for i,arm in enumerate(D.ARMS):
        p.record('arm_%d'%(i+1),'docking_arm','dead berth corridor' if i<3 else 'torn arm root; exposed deck and rack rows')
        a=math.radians(arm['angle'])
        p.matrix=Matrix.Rotation(a,4,'Z') @ Matrix.Translation(Vector((arm['root'],0,arm['z'])))
        p.arm(arm['tip']-arm['root']-1.2,arm['width'],arm['modules'],i==3,i<3)
        for j in range(arm['modules']):
            x=arm['root']+j*(arm['tip']-arm['root'])/arm['modules']
            empty('joint_arm_%d_%d'%(i+1,j),root,(x*math.cos(a),x*math.sin(a),arm['z']))
        p.matrix=Matrix.Identity(4)
    # The review uses the shorter, six-unit fall-back: no invented ring animation.
    p.record('tethered_arm','docking_arm','one passive moving section; no power',parent='arm_4')
    p.moving=True
    p.matrix=Matrix.Rotation(-math.pi/2,4,'Z')
    p.arm(D.MOTION['length']-1.2,1.65,2,broken=True)
    p.matrix=Matrix.Identity(4); p.moving=False
    p.record('tethers','conduits','torn flexible conduits joining the loose arm to its stub')
    for x in (-.38,.38):
        p.rod((x,-8.2,-2.7),(x,-10.0,-2.7),.045,'trim')
    # Towers are all on a connected equipment deck, supported down to the ring.
    p.record('equipment_deck','platform','connected tower bases; services and blue emergency cluster')
    p.box((-3.7,7.8,1.3),(15.5,4.2,.65),'plate2')
    for x in (-10,-5,0,3):
        p.rod((x,6.4,1.1),(x,4.4,.1),.18,'trim')
    for i,t in enumerate(D.TOWERS):
        p.record('tower_%d'%(i+1),'tower_cap',t['cap']+'; dead; whole machine on its module joint')
        old=p.matrix.copy()
        p.matrix=Matrix.Translation(Vector((t['x'],t['y'],t['base']))) @ Matrix.Rotation(t['lean'],4,'Y')
        h=t['height']; rad=.85 if i!=0 else 1.05
        # A visible pedestal reaches the support, including the outboard dome
        # tower whose base is beyond the equipment deck edge.
        p.band(.30,rad*1.2,-.55,.14,steps=32,zone='trim')
        if i==2:
            p.box((0,-1.2,-.35),(2.1,2.8,.35),'plate2')
        # Stepped mast with repeated equipment rings and internal cable trunk.
        for j in range(4):
            rr=rad*(1-.085*j)
            p.drum(rr,j*h/4,h/4-.12,decks=True,breach=i==0 and j==0)
            for a in (0,math.pi/2,math.pi,math.pi*1.5):
                p.rod((rr*math.cos(a),rr*math.sin(a),j*h/4+.15),
                      (rr*math.cos(a),rr*math.sin(a),(j+1)*h/4-.25),.045,'trim')
        p.band(.2,rad*1.1,h-.08,h+.10,steps=32,zone='edge')
        if t['cap']=='array':
            for j in range(7):
                yy=(j-3)*.42
                p.rod((-1.8,yy,h+.35),(1.8,yy,h+.35),.04)
            for x in (-1.5,0,1.5): p.rod((x,-1.6,h+.35),(x,1.6,h+.35),.045,'trim')
            p.rod((0,0,h),(0,0,h+1.2),.07,'trim')
        elif t['cap']=='dishes':
            p.rod((-1.1,0,h+.1),(1.1,0,h+.1),.12)
            for x in (-.95,.95): p.dish((x,0,h+.35),.78,.7)
        elif t['cap']=='dome':
            for j in range(6):
                rr=rad*math.sqrt(max(.01,1-(j/6)**2))
                p.band(max(.02,rr-.10),rr,h+j*.15,h+(j+1)*.15,steps=24,zone='plate2')
            for x in (-.7,.7): p.rod((x,0,h),(x,0,h+2),.035,'trim')
        elif t['cap']=='crane':
            # Station maintenance machinery, explicitly permitted by the station brief.
            for side in (-1,1):
                p.rod((0,side*.22,h+.3),(3.2,side*.15,h+2.0),.06)
                for j in range(5):
                    p.rod((j*.64,side*.22,h+.3+j*.34),
                          ((j+1)*.64,-side*.15,h+.3+(j+1)*.34),.03,'trim')
            p.rod((3.2,0,h+2),(3.2,0,h+.9),.025,'trim')
        else:
            for zz in (.1,.45,.8): p.band(.6,1.2,h+zz,h+zz+.11,steps=32,zone='trim')
            for a in range(8):
                x=.8*math.cos(a*math.tau/8); y=.8*math.sin(a*math.tau/8)
                p.rod((x,y,h),(x,y,h+1.6),.025)
        p.matrix=old
    for i,rad in enumerate(D.RADIATORS):
        p.record('radiator_%d'%(i+1),'radiator','cold grooved heat rejection bank, header and pump',
                 inside='header channels and manifold; no fire')
        a=math.radians(rad['angle']); h=rad['top']-rad['bottom']
        p.matrix=Matrix.Rotation(a,4,'Z') @ Matrix.Translation(Vector((rad['radius'],0,rad['bottom'])))
        p.box((0,0,h/2),(.16,rad['width'],h),'trim')
        for y in (-rad['width']/2,rad['width']/2):
            p.rod((0,y,0),(0,y,h),.08,'edge')
        for j in range(34):
            y=(j/33-.5)*(rad['width']-.2)
            p.box((.10,y,h/2),(.055,.025,h-.2),'edge')
        p.rod((0,-rad['width']/2,h),(0,rad['width']/2,h),.18,'trim')
        for yy in (-.12,.12):
            p.rod((0,-rad['width']/2,h+yy),(0,rad['width']/2,h+yy),.055,'liner',inside=True)
        p.box((0,0,h+.3),(.6,.7,.6),'rack')
        p.rod((0,0,h),(D.CORE['radius']-rad['radius'],0,h+1.0),.18,'trim')
        p.matrix=Matrix.Identity(4)
    # Two cargo pods. Neither is a live berth or a ship substitute.
    for i,(x,y,z) in enumerate(((20,1.9,3.0),(-8,-9,-1.4))):
        p.record('cargo_%d'%(i+1),'cargo_pod','dead cargo pod; one clamped and one lodged')
        p.box((x,y,z),(2.3,1.1,1.2),'plate2')
        for j in range(5): p.box((x+(j-2)*.43,y,z),(.07,1.18,1.3),'trim')
    p.record('lodged_debris','debris','twelve irregular torn structural remnants; no orbiting particles',inside='torn frames')
    for i in range(12):
        a=math.radians(205+i*5); rr=11+(i%3)*1.8
        pos=(rr*math.cos(a),rr*math.sin(a),-1.8+(i%4)*.28)
        # Folded two-panel shards carry thickness, not a single flat polygon.
        p.box(pos,(.65+(i%4)*.38,.55,.12),'edge',rotation=a+.3)
        p.rod(pos,(pos[0]+.6,pos[1]+.1,pos[2]+.5),.08,'frame')
    p.record('emergency_lights','lights','90 implant-blue lights in seven clusters; five static dull battery strips',inside='module-local batteries')
    for cl in D.LIGHT_CLUSTERS:
        for j in range(cl['count']):
            if cl['kind']=='core':
                a=math.radians(cl['angle']+(j%7-3)*4)
                z=c['bottom']+cl['deck']*c['pitch']+.65+(j//7)*.30
                rr=c['radius']+.11
                p.box((rr*math.cos(a),rr*math.sin(a),z),(.11,.16,.16),'blue',rotation=a)
            elif cl['kind']=='ring':
                a=math.radians(cl['slot']*30+5+(j%5)*4)
                rr=r['outer']+.10; z=-.25+(j//5)*.34
                p.box((rr*math.cos(a),rr*math.sin(a),z),(.11,.17,.17),'blue',rotation=a)
            else:
                p.box((-7+j*.7,5.67,1.30),(.20,.12,.14),'blue')
    for pos in D.BATTERIES: p.box(pos,(.65,.12,.10),'battery')
    objs=p.finish(root,move)
    # Passive animation only, with a separate transform preserved in the export.
    move.rotation_mode='XYZ'
    fps=24; bpy.context.scene.render.fps=fps
    period=int(D.MOTION['period'])
    for fr in (1,period*fps+1):
        move.rotation_euler.y=math.tau*(fr-1)/(period*fps)
        move.keyframe_insert(data_path='rotation_euler',index=1,frame=fr)
    for seconds in range(0,period+1,10):
        move.rotation_euler.x=math.radians(D.MOTION['swing_degrees'])*math.sin(seconds*math.tau/D.MOTION['swing_period'])
        move.keyframe_insert(data_path='rotation_euler',index=0,frame=seconds*fps+1)
    if move.animation_data:
        move.animation_data.action.name='T2_passive_tumble'
        for curve in move.animation_data.action.fcurves:
            for key in curve.keyframe_points: key.interpolation='LINEAR'
    bpy.context.scene.frame_set(1)
    return root,move,objs,p.rows


def bounds(objects):
    points=[ob.matrix_world @ Vector(v) for ob in objects for v in ob.bound_box]
    lo=Vector(tuple(min(p[i] for p in points) for i in range(3)))
    hi=Vector(tuple(max(p[i] for p in points) for i in range(3)))
    return dict(min=list(lo),max=list(hi),size=list(hi-lo))


def geometry_report(scene, objects, moving, inputs, uniform_scale):
    """Measure the built triangles, including the whole passive motion cycle.

    This is a review fit probe. The conduit attachment is intentionally allowed;
    intersections of the moving pressure module with other structure are not.
    Production tearing and the station-map frame gate remain separate work.
    """
    fp=inputs['footprint']; centre=fp['centre']; radius=fp['hex_radius']
    cells=[(c['x']-centre[0],-(c['z']-centre[2])) for c in fp['cells']]
    def in_cell(x,y,c):
        dx=abs(x-c[0]); dy=abs(y-c[1])
        return dx <= math.sqrt(3)*radius/2+.002 and dy <= radius+.002 and dx/math.sqrt(3)+dy <= radius+.002
    def outside(vertices, scale=1.0):
        return sum(not any(in_cell(v.x/scale,v.y/scale,c) for c in cells) for v in vertices)
    deps=bpy.context.evaluated_depsgraph_get()
    fixed_v=[]; fixed_f=[]; move_v=[]; move_f=[]; modules={}
    for ob in objects:
        ev=ob.evaluated_get(deps); me=ev.to_mesh(); me.calc_loop_triangles()
        vv=[ob.matrix_world@v.co for v in me.vertices]
        entry=modules.setdefault(ob['module'],dict(vertices=0,inside_triangles=0,outside_vertices=0,
                                                 source_footprint_outside_vertices=0))
        entry['vertices']+=len(vv)
        entry['inside_triangles']+=len(me.loop_triangles) if ob['inside'] else 0
        entry['outside_vertices']+=outside(vv)
        entry['source_footprint_outside_vertices']+=outside(vv,uniform_scale)
        if ob.parent==moving:
            vv=[moving.matrix_world.inverted()@v for v in vv]; verts,faces=move_v,move_f
        elif ob['module']=='tethers':
            ev.to_mesh_clear(); continue
        else: verts,faces=fixed_v,fixed_f
        offset=len(verts); verts.extend(vv)
        faces.extend(tuple(offset+i for i in t.vertices) for t in me.loop_triangles)
        ev.to_mesh_clear()
    fixed=BVHTree.FromPolygons(fixed_v,fixed_f,all_triangles=True)
    samples=[]; envelope=[]
    for seconds in range(0,int(D.MOTION['period'])+1,5):
        scene.frame_set(seconds*scene.render.fps+1)
        bpy.context.view_layer.update()
        vv=[moving.matrix_world@v for v in move_v]
        tree=BVHTree.FromPolygons(vv,move_f,all_triangles=True)
        overlaps=tree.overlap(fixed)
        samples.append(dict(seconds=seconds,intersecting_triangle_pairs=len(overlaps),outside_vertices=outside(vv),
                            source_footprint_outside_vertices=outside(vv,uniform_scale)))
        envelope.extend(vv)
    scene.frame_set(1); bpy.context.view_layer.update()
    return dict(modules=modules,motion_samples=samples,
                motion_envelope=dict(min=[min(v[i] for v in envelope) for i in range(3)],
                                     max=[max(v[i] for v in envelope) for i in range(3)]),
                note='Built triangles, 49 poses across 240 seconds; conduit contact allowed. '
                     'Discrete samples are not a continuous swept-volume certification.')


def camera(scene,name,position,target,ortho=None):
    data=bpy.data.cameras.new(name); cam=bpy.data.objects.new(name,data)
    scene.collection.objects.link(cam); cam.location=position
    cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
    if ortho: data.type='ORTHO'; data.ortho_scale=ortho
    else:
        # Godot uses vertical FOV. Blender's horizontal sensor fit needs the
        # aspect conversion or the camera170 sheet is almost twice too close.
        data.type='PERSP'; data.sensor_fit='HORIZONTAL'; data.lens_unit='FOV'
        aspect=scene.render.resolution_x/scene.render.resolution_y
        data.angle=2*math.atan(math.tan(math.radians(scene['review_fov'])/2)*aspect)
    scene.camera=cam
    return cam


def lighting(scene):
    scene.render.engine='CYCLES'; scene.cycles.device='CPU'; scene.cycles.samples=16
    scene.cycles.use_denoising=True
    scene.render.threads_mode='FIXED'; scene.render.threads=8
    scene.render.resolution_x=1280; scene.render.resolution_y=720
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG'
    scene.world.use_nodes=True
    scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.018,.024,.033,1)
    scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.4
    scene.view_settings.view_transform='AgX'
    for name,loc,power,size in [('key',(30,-40,60),85000,16),('fill',(-35,20,-30),18000,25)]:
        ld=bpy.data.lights.new(name,'AREA'); ld.energy=power; ld.shape='DISK'; ld.size=size
        ob=bpy.data.objects.new(name,ld); scene.collection.objects.link(ob); ob.location=loc
        ob.rotation_euler=(-ob.location).to_track_quat('-Z','Y').to_euler()


def export(root,move,objs,out):
    # Keep the source blend's per-module meshes and insides. Only export copies are joined.
    copies=[]
    for ob in objs:
        cp=ob.copy(); cp.data=ob.data.copy(); bpy.context.collection.objects.link(cp)
        copies.append(cp)
    groups=[[o for o in copies if (o.parent==move)==moving] for moving in (False,True)]
    for moving,group in zip((False,True),groups):
        bpy.ops.object.select_all(action='DESELECT')
        for o in group: o.select_set(True)
        bpy.context.view_layer.objects.active=group[0]
        bpy.ops.object.convert(target='MESH')
        bpy.ops.object.join()
        group[0].name='T2_moving_mesh' if moving else 'T2_structure'
    bpy.ops.object.select_all(action='DESELECT')
    root.select_set(True); move.select_set(True)
    for ob in bpy.context.scene.objects:
        if ob.name in ('T2_moving_mesh','T2_structure'): ob.select_set(True)
    bpy.context.scene.frame_end=int(D.MOTION['period']*bpy.context.scene.render.fps)+1
    bpy.ops.export_scene.gltf(filepath=str(out/'station_T2_review.glb'),export_format='GLB',
        use_selection=True,export_extras=True,export_yup=True,export_animations=True,
        export_frame_range=True,export_animation_mode='ACTIONS',export_materials='EXPORT')


def main():
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    ap=argparse.ArgumentParser(); ap.add_argument('--out',required=True)
    ap.add_argument('--no-render',action='store_true'); a=ap.parse_args(args)
    out=Path(a.out); out.mkdir(parents=True,exist_ok=True)
    inputs=json.loads((out/'game_inputs.json').read_text(encoding='utf-8'))
    root,move,objs,rows=build()
    bpy.context.view_layer.update()
    # R247: use the table's minimum long axis, preserving the concept's proportions.
    # The old seven-cell footprint remains measured, not silently enlarged.
    initial=bounds(objs)
    sizing=contract()
    uniform_scale=sizing['range'][0]/max(initial['size'])
    root.scale=(uniform_scale,)*3
    joints=dict(D.JOINTS,core=[z*uniform_scale for z in D.JOINTS['core']])
    root['joints_json']=json.dumps(joints)
    bpy.context.view_layer.update()
    bb=bounds(objs)
    deps=bpy.context.evaluated_depsgraph_get()
    counts={'exterior':0,'inside':0}
    for ob in objs:
        ev=ob.evaluated_get(deps); me=ev.to_mesh(); me.calc_loop_triangles()
        counts['inside' if ob.get('inside') else 'exterior']+=len(me.loop_triangles)
        ev.to_mesh_clear()
    counts['total']=sum(counts.values())
    fit=geometry_report(bpy.context.scene,objs,move,inputs,uniform_scale)
    (out/'fit.json').write_text(json.dumps(fit,indent=2)+'\n',encoding='utf-8')
    src=[HERE/n for n in ('design.py','parts.py','stack.py','review.py','inspect.gd','check.py','sheets.py','scale.py','capture.gd','range_selftest.py','review_run.bat')]
    manifest=dict(code=D.CODE,status='BUILD SHEET - NOT APPROVED FOR INSTALL',
                  station_kind='fleet',concept=D.CONCEPT,plan=D.PLAN,pack=D.PACK,
                  units='world units; Blender Z up; glTF Y up',bounds=bb,triangles=counts,
                  uniform_fit=dict(scale=uniform_scale,axes=[uniform_scale]*3,source_bounds=initial,
                                   contract=sizing,note='Uniform review scale. Live footprint integration pending; no swap.'),
                  modules=rows,joints=joints,lights=dict(blue=sum(c['count'] for c in D.LIGHT_CLUSTERS),
                  battery=len(D.BATTERIES)),motion=dict(D.MOTION,pivot=list(move.matrix_world.translation)),changes=D.CHANGES,
                  orthographic_scale=1.35*max(bb['size'][0],bb['size'][1]*16/9,bb['size'][2]*16/9),
                  method='hand-built station kit; schematic AO material; production mask/trim bake pending sheet approval',
                  scripts={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in src},
                  pending=['Board sheet review','live footprint integration at R247 scale','AI shape reference',
                           'production geometry-mask/trim paint bake','full fit and swept-volume audit',
                           'station-map 1080p and 4K scene gate','Ryan look before live swap'])
    (out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    print('T2 COST',json.dumps(counts),'BOUNDS',json.dumps(bb),flush=True)
    scene=bpy.context.scene; lighting(scene)
    # Preserve the same illumination after the uniform change of scale.
    for lamp in scene.objects:
        if lamp.type=='LIGHT':
            lamp.location*=uniform_scale
            lamp.data.energy*=uniform_scale**2
            lamp.data.size*=uniform_scale
    scene['review_fov']=inputs['camera']['fov']
    bpy.ops.wm.save_as_mainfile(filepath=str(out/'station_T2_sheet.blend'))
    if not a.no_render:
        # First image is at the battle camera's angular size. It is a studio render,
        # not an in-game capture; the comparison cruiser is added by the Godot probe.
        beta=inputs['camera']['beta']; rr=inputs['camera']['radius']
        ortho=manifest['orthographic_scale']; cz=(bb['min'][2]+bb['max'][2])/2
        views=[('camera170',(0,-rr*math.sin(beta),rr*math.cos(beta)),(0,0,0),None),
               ('top',(0,0,100),(0,0,0),ortho),
               ('side',(0,-100,cz),(0,0,cz),ortho),
               ('underside',(0,0,-100),(0,0,0),ortho),
               ('front',(100,0,cz),(0,0,cz),ortho),
               ('threequarter',(125,-160,105),(0,0,2),None)]
        for name,pos,target,ortho in views:
            camera(scene,name,pos,target,ortho)
            scene.render.filepath=str(out/(name+'.png')); bpy.ops.render.render(write_still=True)
            print('T2 VIEW',name,flush=True)
        # CPU studio comparison using actual, fitted ShipView mesh. This is not
        # a game capture or evidence for the GPU frame gate.
        bpy.ops.wm.obj_import(filepath=str(out/inputs['cruiser_mesh']),forward_axis='Y',up_axis='Z')
        cruiser=list(bpy.context.selected_objects)
        for ob in cruiser:
            ob.location+=Vector((0,-53,0))
            ob.data.materials.clear(); ob.data.materials.append(stack.materials()['plate2'])
        for name,pos,target in [('compare170',(0,-5-rr*math.sin(beta),rr*math.cos(beta)),(0,-5,0)),
                                ('compare_low',(140,-200,70),(0,-5,1))]:
            camera(scene,name,pos,target)
            scene.render.filepath=str(out/(name+'.png')); bpy.ops.render.render(write_still=True)
            print('T2 VIEW',name,flush=True)
        for ob in cruiser: ob.hide_render=True
        # Cutaway is a build check: the real decks, frame stations and rack rows.
        for ob in objs:
            ob.hide_render=not bool(ob.get('inside')) or ob.get('zone')=='liner'
        camera(scene,'inside',(110,-130,84+cz),(0,0,cz),manifest['orthographic_scale'])
        scene.view_settings.exposure=1.5
        scene.render.filepath=str(out/'inside.png'); bpy.ops.render.render(write_still=True)
        scene.view_settings.exposure=0
        for ob in objs: ob.hide_render=False
    export(root,move,objs,out)
    print('T2 REVIEW WRITTEN',out,flush=True)


if __name__=='__main__': main()
