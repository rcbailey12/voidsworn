"""Round 4 materials, native cleanup, and a reference-authored dense ship."""
import argparse
import importlib.util
import json
import math
from pathlib import Path
import struct
import sys
import time

import bpy
import bmesh
import numpy as np
from mathutils import Vector, Matrix

sys.dont_write_bytecode=True
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
import round4_material as paint
sys.path.insert(0,str(HERE.parent/'surface_bakeoff'))
import round2_build as kit
lib=kit.lib
spec=importlib.util.spec_from_file_location('repair129_build',HERE/'build.py')
repair=importlib.util.module_from_spec(spec);spec.loader.exec_module(repair)


def assign(objects,pc,mode):
    cache={};counts={}
    for obj in objects:
        me=obj.data
        old=list(me.materials);uv=me.uv_layers.active
        indices=[]
        for poly in me.polygons:
            original=old[poly.material_index] if old else None
            if original and 'round4_band' in original:
                band=int(original['round4_band']);variation=int(original.get('variation',1))
            elif mode=='V1' and uv:
                oldband=int(np.mean([uv.data[i].uv.y for i in poly.loop_indices])*8)%8
                band=[0,0,1,3,4,1,6,8][oldband]
                variation=poly.material_index%4
                if band==0 and variation in [1,2]:band=1
                if band==0 and 'retained' in obj.name:
                    c=obj.matrix_world@poly.center
                    if (c.x<-.15 and c.z>-.06) or (-.03<c.x<.18 and c.z>.01) or (c.y>.08 and c.z>-.08):band=1
                if band==8 and (obj.matrix_world@poly.center).x<-.35:band=12
            else:
                centre=obj.matrix_world@poly.center
                band=0 if centre.z>-.07 else 1
                variation=abs(int(centre.x*27)+int(centre.y*43))%4
                if abs(centre.y)>.13 and -.04<centre.x<.04:band=5
            key=(band,variation)
            if key not in cache:
                cache[key]=paint.make_material(pc,band,variation)[0]
            indices.append(key);counts[band]=counts.get(band,0)+1
        me.materials.clear();local={}
        for key in dict.fromkeys(indices):local[key]=len(me.materials);me.materials.append(cache[key])
        me.polygons.foreach_set('material_index',np.array([local[k] for k in indices],np.int32))
    return counts


def marks(core,pc):
    """Thin surface stencils and recessed red strips, placed by actual ray hits."""
    kit.PARTS.clear();kit.CORE=core;kit.TREE=kit.tree(core)
    for x,y,band in [(-.10,.06,9),(.25,-.17,10),(.33,.03,11)]:
        p,n=kit.hit(x,y)
        if p is None:continue
        o,_,_=kit.mounted('faded_faction_trophy_plate',p,n,(.043,.025,.0008),0,.0001)
        o.data.materials.clear();m=bpy.data.materials.new('trophy');m['round4_band']=band;m['variation']=1;o.data.materials.append(m)
    for x,y in [(.23,.05),(-.07,.07),(.08,-.16)]:
        p,n=kit.hit(x,y)
        if p is None:continue
        for k in range(4):
            q,normal,_,gap=kit.TREE.find_nearest(p+Vector((k*.004,0,0)))
            if q is None:continue
            o,_,_=kit.mounted('faded_hull_tally',q,normal,(.0014,.011,.00025),4,.00003)
            o.data.materials.clear();m=bpy.data.materials.new('tally');m['round4_band']=6;m['variation']=2;o.data.materials.append(m)
    for side in [-1,1]:
        for x in [.12,.27,.35]:
            p,n=kit.hit(x,-.035,axis=1,sign=side)
            if p is None:continue
            bezel,_,_=kit.mounted('running_light_recess',p,n,(.022,.008,.002),3,.0004)
            lamp=kit.box('red_running_light',p+n*.0020,(.012,.0021,.0005),7,.00015)
            lamp.rotation_euler=bezel.rotation_euler
            lamp.data.materials.clear();m=bpy.data.materials.new('red_lamp');m['round4_band']=8;m['variation']=0;lamp.data.materials.append(m)
    return kit.PARTS[:]


def variant1(a,folder):
    source=a.work/'base_repair/C19_51/S5/prototype.blend'
    bpy.ops.wm.open_mainfile(filepath=str(source))
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
    core=next(o for o in objects if 'retained' in o.name)
    # Materials and atlas are replaced, with the stage 5 primary mesh retained.
    # A temporary trim is used only by primitive construction, never in paint.
    kit.MAT=objects[0].data.materials[0]
    objects+=marks(core,a.pc)
    counts=assign(objects,a.pc,'V1')
    obj=kit.join(objects,'stage5_with_real_materials')
    material=paint.bake(obj,a.pc,folder,lib)
    prior=json.loads(source.with_name('build.json').read_text())
    return [obj],dict(source=str(source),source_sha256=lib.sha(source),
        stage5_source_sha256=prior['source_sha256'],retained_stage5_triangles=prior['triangles'],
        new_materials=counts,material=material,mount_anchors=prior['mount_anchors'],gun_directions=prior['gun_directions'])


def variant2(a,folder):
    record=json.loads((a.work/'reference/mesh.json').read_text())
    # Read native coordinates explicitly. This avoids an imported parent or
    # stale Blender mesh cache silently normalising the transverse axis.
    sys.path.insert(0,str(HERE))
    from pack_parts import read_glb
    path=Path(record['low']);source_pos,source_faces=read_glb(path)
    with path.open('rb') as stream:
        stream.seek(12);length=struct.unpack('<I',stream.read(4))[0]
        stream.seek(20);doc=json.loads(stream.read(length))
    primitive=doc['meshes'][0]['primitives'][0]
    accessor=doc['accessors'][primitive['attributes']['TEXCOORD_0']]
    view=doc['bufferViews'][accessor['bufferView']]
    assert accessor['componentType']==5126 and view.get('byteStride',8)==8
    uv=np.memmap(path,mode='r',dtype='<f4',shape=(accessor['count'],2),
        offset=20+length+8+view.get('byteOffset',0)+accessor.get('byteOffset',0)).copy()
    uv[:,1]=1-uv[:,1]
    v=np.stack([source_pos[:,2],source_pos[:,0],source_pos[:,1]],1).copy()
    centre=(v.min(0)+v.max(0))/2;scale=1/float(np.ptp(v[:,0]));v=(v-centre)*scale
    cross=np.cross(v[source_faces[:,1]]-v[source_faces[:,0]],v[source_faces[:,2]]-v[source_faces[:,0]])
    valid=np.linalg.norm(cross,axis=1)>1e-12
    removed=int((~valid).sum());source_faces=np.asarray(source_faces)[valid]
    obj=lib.mesh('regenerated_300k',v,source_faces)
    obj.data.validate(verbose=True,clean_customdata=False);obj.data.update()
    clean_faces=np.array([p.vertices for p in obj.data.polygons],np.int32)
    layer=obj.data.uv_layers.new(name='surface')
    layer.data.foreach_set('uv',uv[clean_faces.ravel()].ravel())
    obj.data.polygons.foreach_set('use_smooth',np.ones(len(obj.data.polygons),bool))
    obj.data.set_sharp_from_angle(angle=math.radians(55))
    # Region labels provide per-panel variation without a triangle-colour speckle.
    obj.data.calc_loop_triangles();faces=np.array([t.vertices for t in obj.data.loop_triangles])
    _,labels,_,_=repair.regions(v,faces)
    centres=v[faces].mean(1)
    normals=np.cross(v[faces[:,1]]-v[faces[:,0]],v[faces[:,2]]-v[faces[:,0]])
    areas=np.linalg.norm(normals,axis=1);normals/=np.maximum(areas[:,None],1e-9)
    side=(normals[:,1]<-.65)&(abs(centres[:,0])<.25)
    weights=np.bincount(labels,weights=areas*side);chosen=int(weights.argmax())
    ids=(labels==chosen)&side
    target=(centres[ids]*areas[ids,None]).sum(0)/areas[ids].sum()
    direction=(normals[ids]*areas[ids,None]).sum(0);direction/=np.linalg.norm(direction)
    bands=np.mod(labels*17,4)
    placeholders=[]
    for i in range(4):
        m=bpy.data.materials.new('generated_panel_'+str(i));m['round4_band']=0 if i in [1,2] else 1;m['variation']=i;placeholders.append(m)
    obj.data.materials.clear()
    for m in placeholders:obj.data.materials.append(m)
    obj.data.polygons.foreach_set('material_index',bands.astype(np.int32))
    counts=assign([obj],a.pc,'V2')
    rawimage=bpy.data.images.load(record['normal']);rawimage.colorspace_settings.name='Non-Color'
    w,h=rawimage.size;assert (w,h)==(4096,4096)
    rgba=np.empty(w*h*4,np.float32);rawimage.pixels.foreach_get(rgba)
    raw=rgba.reshape(h,w,4)[:,:,:3];lib.save_image(folder/'normal_raw.png',raw)
    vec=raw*2-1;vec/=np.maximum(np.linalg.norm(vec,axis=2,keepdims=True),1e-7)
    flat=np.array([0,0,1],np.float32);deviation=vec-flat
    slow=kit.blur(deviation,(1,2,4,8,16,24))
    filtered=flat+(deviation-slow)*.65
    filtered[:,:,2]=np.maximum(filtered[:,:,2],.5)
    filtered/=np.maximum(np.linalg.norm(filtered,axis=2,keepdims=True),1e-7)
    lib.save_image(folder/'normal_filtered.png',filtered*.5+.5)
    before=float(np.sqrt(np.mean(kit.blur(deviation)[::4,::4]**2)))
    after=float(np.sqrt(np.mean(kit.blur(filtered-flat)[::4,::4]**2)))
    material=paint.bake(obj,a.pc,folder,lib,donor_normal=filtered,keep_uv=True)
    kit.MAT=obj.data.materials[0]
    accents=marks(obj,a.pc)
    for side in [-1,1]:
        p,n,_,_=kit.TREE.ray_cast(Vector((-1.2,side*.075,-.015)),Vector((1,0,0)),3)
        if p is None:continue
        lamp=kit.cyl('regenerated_engine_glow',p+n*.0005,.009,.001,n,7,20)
        lamp.data.materials.clear();m=bpy.data.materials.new('engine_glow');m['round4_band']=12;lamp.data.materials.append(m)
    accents=kit.PARTS[:]
    objects=[obj]
    if accents:
        assign(accents,a.pc,'V2');hardware=kit.join(accents,'material_decals_and_lights')
        detailfolder=folder/'accents';detailfolder.mkdir(exist_ok=True)
        paint.bake(hardware,a.pc,detailfolder,lib,res=2048)
        obj.data.uv_layers.active.name='surface'
        objects=[kit.join([obj,hardware],'regenerated_baked_with_marks')]
    return objects,dict(source=record['source'],source_sha256=lib.sha(record['source']),
        coordinate_conversion='native glTF to Blender: X=source Z, Y=source X, Z=source Y; uniform longitudinal scale',
        zero_area_faces_removed=removed,validated_native_geometry=True,
        cleanup=record['cleanup'],new_materials=counts,material=material,
        proof_target_godot=[float(target[0]),float(target[2]),float(-target[1])],
        proof_normal_godot=[float(direction[0]),float(direction[2]),float(-direction[1])],
        bake=dict(raw=str(folder/'normal_raw.png'),filtered=str(folder/'normal_filtered.png'),
            method='normalize(flat + .65*(deviation - blur(deviation))); flat=(0,0,1)',
            low_frequency_rms_before=before,low_frequency_rms_after=after,normal_mean_z=float(filtered[:,:,2].mean())))


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--pc',type=Path,required=True)
    ap.add_argument('--work',type=Path,required=True);ap.add_argument('--route',choices=['V1','V2','V3'],required=True)
    a=ap.parse_args(sys.argv[sys.argv.index('--')+1:]);start=time.perf_counter()
    folder=a.work/'C19_51'/a.route;folder.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if a.route=='V1':objects,meta=variant1(a,folder)
    elif a.route=='V2':objects,meta=variant2(a,folder)
    else:
        sys.path.insert(0,str(HERE))
        import round4_hand
        objects,meta=round4_hand.build(a,folder,kit,lib,paint,assign,marks)
    validation=[]
    for obj in objects:
        validation.append(dict(mesh=obj.name,changed=bool(obj.data.validate(verbose=True,clean_customdata=False))))
        obj.data.update()
    count_triangles=lib.triangles
    def measured_triangles(meshes):
        count=count_triangles(meshes);print('[round4] export/reimport triangle count',count,flush=True);return count
    lib.triangles=measured_triangles
    result=lib.export(objects,folder,a.route);result.update(meta);result['mesh_validation']=validation
    result.update(route=a.route,seconds=time.perf_counter()-start,projected_paint=False)
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/'prototype.blend'))
    (folder/'build.json').write_text(json.dumps(result,indent=2)+'\n')
    print('[round4] BUILD PASS',a.route,result['triangles'],flush=True)


if __name__=='__main__':main()
