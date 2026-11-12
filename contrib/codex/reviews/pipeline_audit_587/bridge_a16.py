# Audit-only format adapter for issue 587. No ship design or production change.
# Blender: open the rebuilt sheet, then -P bridge_a16.py -- REPO TASK_ROOT
import bpy, sys, json, math, os
from mathutils import Matrix, Vector
repo, out = sys.argv[sys.argv.index('--')+1:]
m=json.load(open(os.path.join(out,'sheet','corsair_A16_model.json')))
sc=bpy.context.scene
scale=1.0/m['model_length']
# The sheet uses world units. The recipe contract uses a length-one Blender hull.
parents={o.name:o.parent for o in sc.objects if o.type=='MESH' and o.parent is not None}
pivots={o.name:o.matrix_world.copy() for o in sc.objects if o.type=='EMPTY' and o.get('turret')}
for ob in list(sc.objects):
    if ob.type!='MESH': continue
    xf=Matrix.Scale(scale,4) @ ob.matrix_world
    ob.parent=None
    ob.data.transform(xf)
    ob.matrix_world=Matrix.Identity(4)
    if ob.get('inside'):
        ob['role']='interior'; ob.hide_render=False; ob.hide_set(False)
    sk=ob.modifiers.get('shell')
    if sk: sk.name='skin'; sk.thickness*=scale
    # Derived whole-object size only, not an authored small-part LOD policy.
    ob['size']=max(ob.dimensions)
# Preserve the source turret hierarchy while normalising the visible geometry.
# This lets the export test establish where the pivots are actually lost.
for name,xf in pivots.items():
    xf.translation*=scale
    bpy.data.objects[name].matrix_world=xf
for name,parent in parents.items():
    ob=bpy.data.objects[name]
    ob.parent=parent
    ob.matrix_parent_inverse=Matrix.Identity(4)
    ob.matrix_world=Matrix.Identity(4)
bpy.context.view_layer.update()
sc['r209_t_lines']=sorted(r['x']*scale for r in m['inside'] if r['kind']=='break' and r.get('orient')=='trans')
# Do not invent a longitudinal seam the approved sheet does not contain.
sc['r209_l_line']=[]
# Recover precise rack aperture centres from its existing kit emitter. No geometry changes.
sys.path.insert(0,os.path.join(repo,'tools','blender','build_sheets'))
import kit
import importlib.util
sp=importlib.util.spec_from_file_location('a16_design',os.path.join(repo,'tools','blender','build_sheets','ships','corsair_A16.py'))
design=importlib.util.module_from_spec(sp); sp.loader.exec_module(design)
# Use a separate temporary scene to recover the emitter's existing fit records.
original=sc
extra=bpy.data.scenes.new('audit_registry_only'); bpy.context.window.scene=extra
K=kit.Kit('audit_registry_only',design.LENGTH); design.build(K)
fit={f['id']:f for f in K.fitdata}
bpy.context.window.scene=original
hp=dict(muzzles=[],engines=[],bays=[]); guns=[]; parts=[]
slot_ids={'P':0,'S':1,'F':2,'T':3}
for f in m['features']:
    fid=f['id']; kind=f['kind']
    if kind in ('gun','launcher'):
        fd=fit[fid]
        if kind=='gun':
            yaw,pitch=map(math.radians,f['aim']); sign=-1 if f['normal'][2]<-.5 else 1
            aim=[math.cos(yaw)*math.cos(pitch),math.sin(yaw)*math.cos(pitch),sign*math.sin(pitch)]
            normal=f['normal']; mouths=fd['muzzles']; radius=fd['cal']/2
        else:
            aim=fd['apertures'][0]['dir']; normal=[0,0,1]; mouths=[e['pos'] for e in fd['apertures']]; radius=0.2
        parts.append(dict(name=fid,part='turret' if kind=='gun' else 'drum_rack',slot=slot_ids[f['slot']]))
        for i,p in enumerate(mouths):
            hp['muzzles'].append(dict(name=fid+'_'+str(i),socket=fid,tip=[v*scale for v in p],aim=list(aim),normal=normal,radius=radius*scale,slot=slot_ids[f['slot']],part=parts[-1]['part']))
        guns.append([fid,list(aim),normal])
    elif kind=='engine':
        hp['engines'].append(dict(name=fid,pos=[v*scale for v in f['exit']],dir=[-1,0,0],radius=f['radius']*scale))
    elif kind=='bay':
        hp['bays'].append(dict(name=fid,pos=[v*scale for v in f['pos']],dir=[0,0,-1],hangar=2))
sc['r209_hp']=json.dumps(hp); sc['r209_guns']=json.dumps(guns)
ship=json.load(open(os.path.join(out,'ship.json')));ship['parts']=parts
json.dump(ship,open(os.path.join(out,'ship.json'),'w'),indent=1)
record=dict(scale=scale,seams=list(sc['r209_t_lines']),longitudinal=[],hp=hp,
  source_turrets=[o.name for o in sc.objects if o.get('turret') and o.type=='EMPTY'],
  source_turret_children={name:len(bpy.data.objects[name].children) for name in pivots},
  interior_objects=sum(o.type=='MESH' and o.get('role')=='interior' for o in sc.objects),
  changes=['length-one geometry','inside role and visibility','shell to skin','scene registries from unchanged sheet emitters','numeric weapon slots from c_boss order'])
json.dump(record,open(os.path.join(out,'bridge_record.json'),'w'),indent=1)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out,'a16_bridged.blend'))
print('AUDIT_BRIDGE',json.dumps({k:v for k,v in record.items() if k!='hp'}))

