"""Build and render the station_T2 review sheet, CPU only.

blender -b -t 8 --python-exit-code 1 -P review.py -- --out DIR [--no-render]
Outputs are review assets. This script has no install or live-swap operation.
"""
import argparse
import json
import math
import os
import random
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
    move=empty('T2_hanging_radiator',root,D.MOTION['pivot'])
    move['period_seconds']=D.MOTION['period']; move['swing_period_seconds']=D.MOTION['swing_period']
    move['swing_degrees']=D.MOTION['swing_degrees']
    p=Parts(stack.materials())
    c=D.CORE
    for i,drum in enumerate(D.DRUMS):
        z=drum['bottom']; radius=drum['radius']; height=drum['height']
        p.record('core_%02d'%(i+1),'deck_drum',
                 ['command','medical','stores','power distribution','machinery',
                  'coolant plant','habitat support','stores','upper service deck'][i])
        p.damaged_drum(radius,z,height,hole=D.BREACHES.get(i),top_tear=i==8,
                       viewport=D.VIEWPORT if i==D.VIEWPORT['deck'] else None)
        # Eight distinct inter-module bulkhead joints.
        if i<8:
            neck=min(radius,D.DRUMS[i+1]['radius'])-.15
            p.band(neck-.18,neck,z+height-.08,D.DRUMS[i+1]['bottom']+.08,steps=64,zone='trim')
        empty('joint_core_%02d'%(i+1),root,(0,0,z+height+.10))
        # EVA pressure doors belong to occupied drums. Pipe risers connect
        # successive shoulder manifolds; there are no generic pallet blocks.
        for j in range(6):
            a=math.tau*j/6+.04*(i%2)
            hole=D.BREACHES.get(i,(-70,4.8) if i==8 else None)
            if hole and abs(math.atan2(math.sin(a-math.radians(hole[0])),math.cos(a-math.radians(hole[0]))))*radius < hole[1]*.65: continue
            if i==D.VIEWPORT['deck'] and abs(math.atan2(math.sin(a-math.radians(D.VIEWPORT['angle'])),math.cos(a-math.radians(D.VIEWPORT['angle'])))) < math.radians(D.VIEWPORT['degrees']/2+8): continue
            old=p.matrix.copy()
            p.matrix=Matrix.Translation(Vector(((radius+.10)*math.cos(a),(radius+.10)*math.sin(a),z+height*.38))) @ Matrix.Rotation(a+math.pi/2,4,'Z') @ Matrix.Rotation(math.pi/2,4,'X')
            p.airlock(.55 if height<2 else .72)
            p.matrix=old
        with p.detail('service_pipe','core drum service risers, return elbows and shoulder manifolds'):
            for j in range(8):
                a=math.tau*(j+.5)/8
                hole=D.BREACHES.get(i,(-70,4.8) if i==8 else None)
                if hole and abs(math.atan2(math.sin(a-math.radians(hole[0])),math.cos(a-math.radians(hole[0]))))*radius < hole[1]*.65: continue
                for delta in (-.055,.055):
                    aa=a+delta; rr=radius+.15
                    if i==D.VIEWPORT['deck'] and abs(math.atan2(math.sin(aa-math.radians(D.VIEWPORT['angle'])),math.cos(aa-math.radians(D.VIEWPORT['angle'])))) < math.radians(D.VIEWPORT['degrees']/2+4): continue
                    p.rod((rr*math.cos(aa),rr*math.sin(aa),z+.15),
                          (rr*math.cos(aa),rr*math.sin(aa),z+height-.22),.045,'trim')
                    p.rod(((radius-.05)*math.cos(aa),(radius-.05)*math.sin(aa),z+.15),
                          (rr*math.cos(aa),rr*math.sin(aa),z+.15),.045,'edge')
    p.record('observation_window','viewport','one large lit curved observation pane in its pressure-frame reveal')
    p.observation_window(D.DRUMS[D.VIEWPORT['deck']],D.VIEWPORT)
    r=D.RING
    for i in range(r['slots']):
        p.record('bearing_%02d'%i,'bearing_track','seized bearing slot; supports habitat module %d'%(i//2+1))
        start=r['service_angle']+r['seized_offset']+r['gap_degrees']/2
        a0=math.radians(start+i*320/11)+.012; a1=math.radians(start+(i+1)*320/11)-.012
        z=r['bottom']; top=z+r['height']
        p.band(r['inner'],r['outer'],z-.20,z, a0,a1,10,'edge',torn=i in (0,10))
        p.band(r['inner'],r['outer'],top,top+.16,a0,a1,10,'edge',torn=i in (0,10))
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
                if j!=4 or radius!=r['outer']:
                    p.box((radius*math.cos(a),radius*math.sin(a),z+1.2),(.09,.32,.40),
                          'glazing',rotation=a)
                if j==4 and radius==r['outer']:
                    old=p.matrix.copy()
                    p.matrix=Matrix.Translation(Vector(((radius+.12)*math.cos(a),(radius+.12)*math.sin(a),z+.78))) @ Matrix.Rotation(a+math.pi/2,4,'Z') @ Matrix.Rotation(math.pi/2,4,'X')
                    p.airlock(.70)
                    p.matrix=old
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
        # Curved supply/return ducts and maintenance rails stop at the real gap.
        with p.detail('service_pipe','habitat supply and return ducts following occupied ring sectors'):
            for radius in (r['inner']+.25,r['outer']-.30):
                p.band(radius-.055,radius+.055,top+.12,top+.23,a0,a1,16,'trim')
        with p.detail('handrail','paired ring walkway rails, posts and EVA tether points'):
            for radius in (r['inner']+.10,r['outer']-.10):
                p.band(radius-.025,radius+.025,top+.65,top+.70,a0,a1,16,'trim')
                for j in range(8):
                    a=a0+(a1-a0)*j/7
                    p.rod((radius*math.cos(a),radius*math.sin(a),top+.15),
                          (radius*math.cos(a),radius*math.sin(a),top+.68),.025,'edge',n=6)
        for j in range(3):
            a=a0+(a1-a0)*(j+.5)/3
            old=p.matrix.copy()
            p.matrix=Matrix.Translation(Vector((rm*math.cos(a),rm*math.sin(a),top+.18))) @ Matrix.Rotation(a+math.pi/2,4,'Z')
            p.hatch(.35)
            p.matrix=old
        empty('joint_ring_%02d'%i,root,(rm*math.cos(a0),rm*math.sin(a0),z))
        # Sprung bearing joint plates are physically lifted from the track.
        if i in (0,2,5,8,10):
            old=p.matrix.copy()
            p.matrix=Matrix.Translation(Vector((rm*math.cos(a0),rm*math.sin(a0),top+.3))) @ Matrix.Rotation(a0,4,'Z') @ Matrix.Rotation(.7 if i%2 else -.6,4,'X')
            p.box((0,0,.25),(r['outer']-r['inner'],.8,.15),'edge')
            p.matrix=old
    for i,a in enumerate(D.SPOKES):
        p.record('spoke_%d'%(i+1),'spoke','bearing support and service corridor; buckled' if i==2 else 'bearing support and service corridor')
        old=p.matrix.copy(); p.matrix=Matrix.Rotation(math.radians(a),4,'Z') @ Matrix.Translation(Vector((6.3,0,0)))
        if i==2:
            p.rod((0,0,0),(3.7,-1.4,-1.8),.40,'liner',n=12,inside=True)
            p.rod((3.7,-1.4,-1.8),(8.1,0,0),.40,'liner',n=12,inside=True)
            for s in (-1,1):
                p.rod((0,s*.42,.15),(3.7,-1.4+s*.42,-1.6),.10)
                p.rod((3.7,-1.4+s*.42,-1.6),(8.1,s*.42,.15),.10)
            for k in range(10):
                x=k*.81; f=(x/3.7 if x<3.7 else (8.1-x)/4.4); zz=-1.8*f
                p.box((x,-1.4*f,zz),(.55,.9,.12),'plate2')
        else:
            p.arm(8.1,1.1,4,cap=False)
        p.matrix=old
    for i,arm in enumerate(D.ARMS):
        p.record('arm_%d'%(i+1),'docking_arm','dead berth corridor' if i<3 else 'torn arm root; exposed deck and rack rows')
        a=math.radians(arm['angle'])
        p.matrix=Matrix.Rotation(a,4,'Z') @ Matrix.Translation(Vector((arm['root'],0,arm['z'])))
        if i==3: p.bent_stub(arm['tip']-arm['root'],arm['width'])
        else: p.arm(arm['tip']-arm['root']-1.2,arm['width'],arm['modules'],cap=True)
        arm_xf=p.matrix.copy()
        if i in (0,2):
            # Cargo handling is at berths, above the held pods, with a visible
            # slew base on the arm rather than on an unrelated habitat roof.
            p.matrix=arm_xf @ Matrix.Translation(Vector((11.0,0,arm['width']*.31+.15)))
            p.crane(3.4)
        if i==2:
            p.matrix=arm_xf @ Matrix.Translation(Vector((10.0,arm['width']*.53,0))) @ Matrix.Rotation(-math.pi/2,4,'X')
            p.hangar_door()
        p.matrix=arm_xf
        for j in range(arm['modules']):
            x=arm['root']+j*(arm['tip']-arm['root'])/arm['modules']
            empty('joint_arm_%d_%d'%(i+1,j),root,(x*math.cos(a),x*math.sin(a),arm['z']))
        p.matrix=Matrix.Identity(4)
    # Every short finger is a panel truss; no featureless block on its end.
    for i,finger in enumerate(D.SERVICE_ARMS):
        p.record('service_finger_%d'%(i+1),'service_finger','trussed cold radiator comb' if finger['cooling'] else 'trussed solar cell wing')
        a=math.radians(finger['angle']); old=p.matrix.copy()
        p.matrix=Matrix.Rotation(a,4,'Z') @ Matrix.Translation(Vector((r['outer']-.25,0,.45)))
        with p.detail('maintenance_truss','triangulated panel outrigger with supply lines to ring'):
            for side in (-1,1):
                p.rod((0,side*.28,0),(finger['length'],side*.28,0),.055,'edge')
                p.rod((0,side*.28,-.5),(finger['length'],side*.28,0),.055,'trim')
                for j in range(4):
                    x=finger['length']*j/4
                    p.rod((x,-.28,0),(x+finger['length']/4,.28,0),.035,'edge')
        if finger['cooling']:
            with p.detail('cold_radiator','grooved cold radiator fins with a connected supply and return header'):
                for j in range(10):
                    x=.4+j*(finger['length']-.65)/9
                    p.box((x,0,-.85),(.065,1.55,1.1),'edge')
                for yy in (-.15,.15):
                    p.rod((0,yy,-.3),(finger['length'],yy,-.3),.065,'trim')
        else: p.solar_wing(finger['length'])
        p.matrix=old
    p.record('ring_attitude_control','thruster_quad','four ring-mounted attitude quads, dark deep nozzles; no main engine axis')
    for angle in (18,125,195,330):
        a=math.radians(angle); old=p.matrix.copy()
        p.matrix=Matrix.Translation(Vector(((r['outer']+.16)*math.cos(a),(r['outer']+.16)*math.sin(a),.35))) @ Matrix.Rotation(a,4,'Z') @ Matrix.Rotation(math.pi/2,4,'Y')
        p.thruster_quad()
        p.matrix=old
    # Every tower has a radial structural bridge and individual pedestal.
    p.record('equipment_deck','platform','five separate radial tower bridges with core and ring connections')
    for t in D.TOWERS:
        a=math.atan2(t['y'],t['x']); old=p.matrix.copy()
        p.matrix=Matrix.Rotation(a,4,'Z') @ Matrix.Translation(Vector((5.9,0,t['base']-.65)))
        length=r['inner']-5.9
        p.box((length/2,0,0),(length,1.7,.23),'plate2')
        for yy in (-.68,.68):
            p.rod((0,yy,-.4),(length,yy,-.4),.10,'trim')
            p.rod((0,yy,-.4),(length/2,yy,.05),.08,'edge')
            p.rod((length/2,yy,.05),(length,yy,-.4),.08,'edge')
        with p.detail('maintenance_truss','tower access bridge with diagonal load paths to core and bearing track'):
            for yy in (-.68,.68):
                p.rod((0,yy,-.4),(length,yy,-.4),.055,'trim')
        p.matrix=old @ Matrix.Rotation(a,4,'Z') @ Matrix.Translation(Vector((5.9,0,t['base']-.50)))
        p.handrail(length,1.55)
        p.matrix=old @ Matrix.Rotation(a,4,'Z') @ Matrix.Translation(Vector((5.9,-.38,t['base']-.48)))
        p.pipe_pair(length)
        p.matrix=old
    for i,t in enumerate(D.TOWERS):
        p.record('tower_%d'%(i+1),'tower_cap',t['cap']+'; dead; whole machine on its module joint')
        old=p.matrix.copy()
        p.matrix=Matrix.Translation(Vector((t['x'],t['y'],t['base']))) @ Matrix.Rotation(t['lean'],4,'Y')
        h=t['height']; rad=.85 if i!=0 else 1.05
        # The exported axis empties are measured by check.py, so the tilt
        # result follows the authored tower transform rather than its AABB.
        for name,local in (('base',(0,0,0)),('tip',(0,0,h))):
            empty('tower_axis_%d_%s'%(i+1,name),root,p.matrix @ Vector(local))
        # A visible pedestal reaches the support, including the outboard dome
        # tower whose base is beyond the equipment deck edge.
        p.band(.30,rad*1.2,-.55,.14,steps=32,zone='trim')
        # Stepped mast with repeated equipment rings and internal cable trunk.
        for j in range(4):
            rr=rad*(1-.085*j)
            p.drum(rr,j*h/4,h/4-.12,decks=True,breach=i==0 and j==0)
            for a in (0,math.pi/2,math.pi,math.pi*1.5):
                p.rod((rr*math.cos(a),rr*math.sin(a),j*h/4+.15),
                      (rr*math.cos(a),rr*math.sin(a),(j+1)*h/4-.25),.045,'trim')
            p.band(rr-.10,rr+.20,j*h/4+.10,j*h/4+.26,steps=32,zone='plate2')
        p.band(.2,rad*1.1,h-.08,h+.10,steps=32,zone='edge')
        saved=p.matrix.copy()
        with p.detail('sensor_mast','tower-mounted crossed dipole antennas on visible stand-offs'):
            for side in (-1,1):
                zz=h*.74
                p.rod((side*rad*.8,0,zz),(side*(rad+.5),0,zz),.055,'trim')
                p.rod((side*(rad+.5),0,zz),(side*(rad+.5),0,zz+1.15),.035,'edge')
                for dz in (.45,.85):
                    p.rod((side*(rad+.5),-.35,zz+dz),(side*(rad+.5),.35,zz+dz),.025,'edge',n=6)
        if t['cap']=='pad':
            # Landing pad split across two buckled plates, not an intact array.
            p.box((-.85,0,h+.22),(1.7,3.1,.16),'edge')
            saved=p.matrix.copy()
            p.matrix=saved @ Matrix.Translation(Vector((0,0,h+.22))) @ Matrix.Rotation(.30,4,'Y')
            p.box((.85,0,0),(1.6,3.1,.16),'plate2')
            for yy in (-1.2,0,1.2): p.rod((-.6,yy,-.22),(1.6,yy,-.22),.07,'frame')
            p.matrix=saved
        elif t['cap']=='dishes':
            p.rod((-1.1,0,h+.1),(1.1,0,h+.1),.12)
            for x in (-1.1,0,1.1): p.dish((x,0,h+.35),.68,.7)
        elif t['cap']=='dome':
            for j in range(6):
                rr=rad*math.sqrt(max(.01,1-(j/6)**2))
                p.band(max(.02,rr-.10),rr,h+j*.15,h+(j+1)*.15,
                       start=.18+j*.04,end=math.tau-.13-j*.035,steps=24,zone='plate2',torn=True)
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
            # Beacon lenses are dark recesses; no emission on any dead cap.
            for zz in (.1,.45,.8): p.band(.6,1.2,h+zz,h+zz+.11,steps=32,zone='trim')
            for a in range(8):
                x=.8*math.cos(a*math.tau/8); y=.8*math.sin(a*math.tau/8)
                p.rod((x,y,h),(x,y,h+1.6),.025)
        p.matrix=old
    for i,rad in enumerate(D.RADIATORS):
        p.record('radiator_%d'%(i+1),'radiator','cold grooved bank; single surviving hinge' if i==3 else 'cold grooved bank and header',
                 inside='header channels and manifold')
        a=math.radians(rad['angle']); h=rad['top']-rad['bottom']
        xf=Matrix.Rotation(a,4,'Z') @ Matrix.Translation(Vector((rad['radius'],0,rad['top'])))
        p.matrix=xf
        with p.detail('coolant_manifold','radiator header, flanged circulation pump and paired pipes into the lower core'):
            p.rod((0,-rad['width']/2,0),(0,rad['width']/2,0),.18,'trim')
            p.rod((0,0,.18),(0,0,.65),.21,'edge')
            for zz in (.18,.52): p.band(.03,.32,zz,zz+.08,steps=24,zone='trim')
            for yy in (-.16,.16):
                p.rod((0,yy,0),(c['radius']-rad['radius'],yy,1.0),.065,'trim')
        with p.detail('maintenance_truss','radiator suspension struts tied to core shell and header ends'):
            for yy in (-rad['width']/2,rad['width']/2):
                p.rod((0,yy,0),(c['radius']-rad['radius'],0,1.0),.07,'edge')
        if i==3:
            p.rod((0,-rad['width']/2-.18,0),(0,-rad['width']/2+.18,0),.25,'edge')
            p.moving=True
            # Pivot is in the station frame; geometry is local to that hinge.
            p.matrix=Matrix.Rotation(a,4,'Z') @ Matrix.Rotation(math.radians(D.MOTION['rest_degrees']),4,'Y') @ Matrix.Rotation(.22,4,'X') @ Matrix.Translation(Vector((0,rad['width']/2,0)))
        with p.detail('radiator' if i<3 else 'hanging_radiator', 'cold thermal panel, longitudinal coolant channels and edge frame'):
            p.box((0,0,-h/2),(.16,rad['width'],h),'trim')
            for y in (-rad['width']/2,rad['width']/2):
                p.rod((0,y,-h),(0,y,0),.08,'edge')
            for j in range(34):
                y=(j/33-.5)*(rad['width']-.2)
                p.box((.10,y,-h/2),(.055,.025,h-.2),'edge')
        for yy in (-.12,.12):
            p.rod((0,-rad['width']/2,yy-.35),(0,rad['width']/2,yy-.35),.055,'liner',inside=True)
        p.matrix=Matrix.Identity(4); p.moving=False
    # Held debris makes the arm cradle and ring edge visibly wider in plan.
    for i,(x,y,z,angle) in enumerate(((18,2.7,3.2,12),(20.3,3.2,3.4,-18),(-17.6,-3,1.0,65))):
        p.record('cargo_%d'%(i+1),'cargo_pod','held dead cargo: arm cradle' if i<2 else 'held against ring outer face')
        old=p.matrix.copy(); p.matrix=Matrix.Translation(Vector((x,y,z))) @ Matrix.Rotation(math.radians(angle),4,'Z')
        with p.detail('cargo_pod','held cargo container with structural transport ribs'):
            p.box((0,0,0),(2.8,1.6,1.7),'plate2')
            for j in range(5): p.box(((j-2)*.56,0,0),(.09,1.72,1.82),'trim')
        p.matrix=old
        p.rod((x,y,z-.8),(x,y-1.9,z-1.2),.11,'frame')
    p.record('folded_plate','debris','one torn plate folded over arm walkway; two thick bent leaves',inside='torn frame')
    p.box((-12.5,-1.8,3.7),(3.0,2.0,.16),'edge',rotation=.18)
    old=p.matrix.copy(); p.matrix=Matrix.Translation(Vector((-12.4,-2.6,3.65))) @ Matrix.Rotation(-.95,4,'X')
    p.box((0,-.8,-.12),(2.7,1.8,.16),'edge')
    p.matrix=old
    p.record('emergency_lights','lights','90 implant-blue markers in six scattered clusters; five dull battery strips',inside='module-local batteries')
    rng=random.Random(373)
    for cl in D.LIGHT_CLUSTERS:
        for j in range(cl['count']):
            # Jittered two-dimensional clusters, never a dotted running row.
            if cl['kind']=='core':
                a=math.radians(cl['angle']+rng.uniform(-8,8))
                drum=D.DRUMS[cl['deck']]
                z=drum['bottom']+drum['height']*(.69+rng.uniform(0,.10))
                rr=drum['radius']+.11
                p.box((rr*math.cos(a),rr*math.sin(a),z),(.11,.17,.17),'blue',rotation=a)
            elif cl['kind']=='ring':
                a=math.radians(cl['angle']+rng.uniform(-7,7))
                rr=r['outer']+.10; z=r['bottom']+rng.uniform(.35,2.4)
                p.box((rr*math.cos(a),rr*math.sin(a),z),(.11,.17,.17),'blue',rotation=a)
            else:
                a=math.radians(155+rng.uniform(-4,4)); rr=r['inner']-.10
                p.box((rr*math.cos(a),rr*math.sin(a),r['bottom']+rng.uniform(.3,1.5)),(.12,.18,.14),'blue',rotation=a)
    for pos in D.BATTERIES: p.box(pos,(.65,.12,.10),'battery')
    objs=p.finish(root,move)
    # Passive animation only, with a separate transform preserved in the export.
    move.rotation_mode='XYZ'
    fps=24; bpy.context.scene.render.fps=fps
    period=int(D.MOTION['period'])
    # One unpowered radiator swings +/-3 degrees, returning without a snap.
    for seconds in range(0,period+1,5):
        move.rotation_euler.y=math.radians(D.MOTION['swing_degrees'])*math.sin(seconds*math.tau/period)
        move.keyframe_insert(data_path='rotation_euler',index=1,frame=seconds*fps+1)
    if move.animation_data:
        move.animation_data.action.name='T2_radiator_swing'
        for curve in move.animation_data.action.fcurves:
            for key in curve.keyframe_points: key.interpolation='LINEAR'
    bpy.context.scene.frame_set(1)
    return root,move,objs,p.rows,p.details


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
    fixed_v=[]; fixed_f=[]; move_v=[]; move_f=[]; modules={}; shells={}
    for ob in objects:
        ev=ob.evaluated_get(deps); me=ev.to_mesh(); me.calc_loop_triangles()
        vv=[ob.matrix_world@v.co for v in me.vertices]
        entry=modules.setdefault(ob['module'],dict(vertices=0,inside_triangles=0,outside_vertices=0,
                                                 source_footprint_outside_vertices=0,
                                                 min=[1e9]*3,max=[-1e9]*3))
        entry['vertices']+=len(vv)
        entry['inside_triangles']+=len(me.loop_triangles) if ob['inside'] else 0
        entry['outside_vertices']+=outside(vv)
        entry['source_footprint_outside_vertices']+=outside(vv,uniform_scale)
        for axis in range(3):
            entry['min'][axis]=min(entry['min'][axis],min(v[axis] for v in vv))
            entry['max'][axis]=max(entry['max'][axis],max(v[axis] for v in vv))
        if ob['module'].startswith('core_') and ob['zone'] in ('plate','plate2','liner'):
            verts0,faces0=shells.setdefault(ob['module'],([],[]))
            off=len(verts0); verts0.extend(vv)
            faces0.extend(tuple(off+i for i in t.vertices) for t in me.loop_triangles)
        if ob.parent==moving:
            vv=[moving.matrix_world.inverted()@v for v in vv]; verts,faces=move_v,move_f
        elif ob['module']=='radiator_4':
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
        samples.append(dict(seconds=seconds,tracked_vertex=list(vv[0]),
                            intersecting_triangle_pairs=len(overlaps),outside_vertices=outside(vv),
                            source_footprint_outside_vertices=outside(vv,uniform_scale)))
        envelope.extend(vv)
    scene.frame_set(1); bpy.context.view_layer.update()
    # Cast through the actual shell at each authored opening. Decks/racks behind
    # the removed shell are measured separately as inside triangles, not a cap.
    apertures=[]
    for deck,hole in list(D.BREACHES.items())+[(8,(-70,4.8))]:
        tree=BVHTree.FromPolygons(*shells['core_%02d'%(deck+1)],all_triangles=True)
        drum=D.DRUMS[deck]; radius=drum['radius']
        angle=math.radians(hole[0]); z=drum['bottom']+drum['height']*(.8 if deck==8 else .53)
        a=Vector(((radius+.5)*math.cos(angle),(radius+.5)*math.sin(angle),z))*uniform_scale
        direction=Vector((-math.cos(angle),-math.sin(angle),0))
        hit=tree.ray_cast(a,direction,.9*uniform_scale)[0]
        apertures.append(dict(module='core_%02d'%(deck+1),open_through_shell=hit is None,
                              nominal_width=hole[1]*uniform_scale,top_tear=deck==8))
    return dict(modules=modules,motion_samples=samples,damage_apertures=apertures,
                motion_envelope=dict(min=[min(v[i] for v in envelope) for i in range(3)],
                                     max=[max(v[i] for v in envelope) for i in range(3)]),
                note='Built triangles, 49 poses across 240 seconds; radiator hinge contact allowed. '
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


def export(root,move,objs,out,vertex_colour=None):
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
        if ob.name in ('T2_moving_mesh','T2_structure') or ob.name.startswith('tower_axis_'): ob.select_set(True)
    bpy.context.scene.frame_end=int(D.MOTION['period']*bpy.context.scene.render.fps)+1
    colour_options = {} if vertex_colour is None else dict(
        export_vertex_color='NAME', export_vertex_color_name=vertex_colour,
        export_all_vertex_colors=False)
    bpy.ops.export_scene.gltf(filepath=str(out/'station_T2_review.glb'),export_format='GLB',
        use_selection=True,export_extras=True,export_yup=True,export_animations=True,
        export_frame_range=True,export_animation_mode='ACTIONS',export_materials='EXPORT',
        **colour_options)


def main():
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    ap=argparse.ArgumentParser(); ap.add_argument('--out',required=True)
    ap.add_argument('--no-render',action='store_true'); a=ap.parse_args(args)
    out=Path(a.out); out.mkdir(parents=True,exist_ok=True)
    inputs=json.loads((out/'game_inputs.json').read_text(encoding='utf-8'))
    root,move,objs,rows,details=build()
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
                  modules=rows,joints=joints,towers=D.TOWERS,drums=D.DRUMS,viewport=D.VIEWPORT,
                  detail_geometry=details,
                  lights=dict(blue=sum(c['count'] for c in D.LIGHT_CLUSTERS),
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
               ('threequarter',(110,-175,125),(0,0,7),None),
               ('concept_beauty',(-95,-150,105),(0,0,8),None),
               ('damage_detail',(65,-100,70),(0,0,15),None)]
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
