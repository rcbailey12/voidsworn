# Issue 209 round 2: flat-shaded views (Workbench, single grey, studio light, transparent background) for the structure compare.
# usage: blender -b -P flat_views.py -- BLEND OUTPREFIX [views]   (round 4 adds 'concept', the concept's fitted camera)   (or python3.11 with the bpy module; Workbench runs on the CPU)
import sys, math, bpy
from mathutils import Vector
a=sys.argv[sys.argv.index('--')+1:]; bpy.ops.wm.open_mainfile(filepath=a[0]); OUT=a[1]
views=a[2].split(',') if len(a)>2 else ['hero','side','top','below','front','back']
sc=bpy.context.scene; sc.render.engine='BLENDER_WORKBENCH'; sh=sc.display.shading
sh.light='STUDIO'; sh.color_type='SINGLE'; sh.single_color=(.62,.62,.62); sh.show_cavity=False; sh.show_object_outline=False
sc.render.film_transparent=True; sc.render.image_settings.color_mode='RGBA'
w=bpy.data.worlds.new('w') if not sc.world else sc.world; sc.world=w
for o in sc.objects:
    if o.type=='MESH':
        for m in o.modifiers: pass
def cam(loc, look, ortho=None, lens=50, res=(1600,900), roll=None):
    c=bpy.data.cameras.new('c'); o=bpy.data.objects.new('c',c); sc.collection.objects.link(o); o.location=loc
    o.rotation_euler=(Vector(look)-Vector(loc)).to_track_quat('-Z','Y').to_euler()
    if ortho: c.type='ORTHO'; c.ortho_scale=ortho
    else: c.lens=lens
    c.clip_start=.01; c.clip_end=50; sc.camera=o; sc.render.resolution_x,sc.render.resolution_y=res; sc.render.resolution_percentage=100; return o
t=Vector((0,0,-.01))
V={'hero':dict(loc=(1.22,1.62,.80),look=t,lens=50,res=(1600,900)),
   'side':dict(loc=(0,3,-.01),look=(0,0,-.01),ortho=1.2,res=(2400,1200)),
   'top':dict(loc=(0,0,3),look=(0,0,0),ortho=1.2,res=(2400,1200)),
   'below':dict(loc=(0,0,-3),look=(0,0,0),ortho=1.2,res=(2400,1200)),
   'front':dict(loc=(3,0,-.01),look=(0,0,-.01),ortho=.75,res=(1200,1200)),
   'back':dict(loc=(-3,0,-.01),look=(0,0,-.01),ortho=.75,res=(1200,1200)),
   'qback':dict(loc=(-1.22,1.62,.80),look=t,lens=50,res=(1600,900)),
   'low':dict(loc=(1.0,1.7,-.7),look=t,lens=50,res=(1600,900))}
import os, json
CAMJ=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','..','..','docs','shots','ship_pipeline','route209','round4','concept_camera.json')
def concept_cam():  # round 4: the concept's own fitted camera (same as render.py), 1024 px square
    p=json.load(open(CAMJ))['camera']; az,el=math.radians(p['az']),math.radians(p['el']); tt=Vector(p.get('target',(0,0,-.01)))
    d=Vector((math.cos(el)*math.cos(az),math.cos(el)*math.sin(az),math.sin(el))); o=cam(tt+d*p['dist'],tt,lens=p['focal']/1024*36,res=(1024,1024))
    from mathutils import Matrix
    o.rotation_euler=(o.rotation_euler.to_matrix()@Matrix.Rotation(math.radians(p['roll']),3,'Z')).to_euler()
    o.data.sensor_fit='HORIZONTAL'; o.data.sensor_width=36; o.data.shift_x=-(p['cx']-512)/1024; o.data.shift_y=(p['cy']-512)/1024; return o
for n in views:
    o=concept_cam() if n=='concept' else cam(**V[n])
    if n=='top': o.rotation_euler=(0,0,math.radians(180))
    if n=='below': o.rotation_euler=(math.radians(180),0,0)
    sc.render.filepath=f'{OUT}_{n}.png'; bpy.ops.render.render(write_still=True)
