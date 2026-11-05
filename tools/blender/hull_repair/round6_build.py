"""Rebuild round 4 V3 with measured detail removal; repaint cached V1."""
import argparse
import collections
import json
import re
from pathlib import Path
import sys
import time

sys.dont_write_bytecode=True
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
import round4_build as prior
import round6_material as paint
import bpy
import numpy as np

CUT={}


def trim(objects):
    """Delete whole small fittings and the second scatter, never collapse heroes."""
    before=prior.lib.triangles(objects)
    removed=[];kept=[]
    for obj in objects:
        obj.data.calc_loop_triangles();tris=len(obj.data.loop_triangles)
        extent=max(np.ptp(np.array([v.co[:] for v in obj.data.vertices]),axis=0))
        reason=None
        if obj.get('round6_detail_pass',0)==2:reason='duplicate second detail scatter'
        elif obj.get('round6_detail_pass',0)==1 and re.match(r'^(fp-?\d|dk|bs|sp).*e$',obj.name.split('.')[0]):reason='subpixel weld bead and rivet row'
        elif extent*41.6<.5 and not any(x in obj.name for x in ['slit','throat','running_light','chain_link']):reason='under 0.5 game units'
        elif any(x in obj.name for x in ['pipe','cooling_rib','feed_union','armoured_cable']):
            # A long pipe can exceed the length threshold while its diameter
            # remains below a battle pixel. Measure in its principal frame.
            coords=np.array([v.co[:] for v in obj.data.vertices]);coords-=coords.mean(0)
            _,axes=np.linalg.eigh(coords.T@coords)
            cross_section=np.sort(np.ptp(coords@axes,axis=0))[1]*41.6
            if cross_section<.5:reason='pipe diameter under 0.5 game units'
        if reason:
            removed.append(dict(name=obj.name,triangles=tris,max_extent_game=float(extent*41.6),reason=reason))
        else:kept.append(obj)
    # Removal must be auditable, including exactly what was sacrificed.
    for obj in objects:
        if obj not in kept:bpy.data.objects.remove(obj,do_unlink=True)
    objects[:]=kept
    after=prior.lib.triangles(objects)
    CUT.update(before_triangles=before,after_triangles=after,removed_triangles=before-after,
               removed_objects=removed,remaining_objects=len(objects),method='Whole-object deletion before merge; no mesh decimation')
    print('[round6] CUT',before,'to',after,flush=True)
    summary=collections.Counter()
    for obj in kept:summary[obj.name.split('.')[0]]+=len(obj.data.loop_triangles)
    print('[round6] REMAINING',json.dumps(summary.most_common(45)),flush=True)
    assert after<=304380,'V3 cannot reach the 306k ceiling with this detail cut; stop rather than damage heroes'


def assign(objects,pc,mode):
    if mode=='V3' and len(objects)>100:trim(objects)
    mats={};counts=collections.Counter()
    core=next((o for o in objects if 'reference_primary_masses' in o.name),None)
    tree=prior.kit.tree(core) if core else None
    for obj in objects:
        me=obj.data;old=list(me.materials);uv=me.uv_layers.active
        ids=[]
        # The retained AI surface gets broad connected geometric zones. We
        # discard the repair helper's flattened positions and keep all vertices.
        labels=None
        if mode=='V1' and 'retained' in obj.name:
            v=np.array([p.co[:] for p in me.vertices],np.float32);me.calc_loop_triangles()
            f=np.array([t.vertices for t in me.loop_triangles],np.int32)
            _,reg,_,_=prior.repair.regions(v,f)
            area=np.linalg.norm(np.cross(v[f[:,1]]-v[f[:,0]],v[f[:,2]]-v[f[:,0]]),axis=1)*.5
            weights=np.bincount(reg,weights=area);centres=v[f].mean(1)
            means=np.stack([np.bincount(reg,weights=area*centres[:,k])/np.maximum(weights,1e-12) for k in range(3)],1)
            labels=np.zeros(len(me.polygons),np.int32)
            for t,r in zip(me.loop_triangles,reg):labels[t.polygon_index]=r
            # Sub-floor surface patches inherit the nearest large plane's
            # coat instead of creating a new value island on every bump.
            lower=np.full((len(weights),3),np.inf);upper=np.full((len(weights),3),-np.inf)
            np.minimum.at(lower,reg,v[f].min(1));np.maximum.at(upper,reg,v[f].max(1))
            widths=np.sort(upper-lower,axis=1)
            large=np.where((weights>=(2/41.6)**2)&(widths[:,1]*41.6>=2))[0]
            assert len(large),'No major surface zones in retained hull'
            owners=large[np.square(means[:,None,:]-means[large][None,:,:]).sum(2).argmin(1)]
        widths_game=np.sort(np.ptp(np.array([v.co[:] for v in me.vertices]),axis=0))*41.6
        inherited=1
        if tree and obj!=core:
            centre=obj.matrix_world@(sum((v.co for v in me.vertices),prior.kit.Vector())/len(me.vertices))
            _,_,face,_=tree.find_nearest(centre)
            if face is not None:
                p=core.data.polygons[face];inherited=int(core.data.materials[p.material_index]['round4_band'])
        for poly in me.polygons:
            original=old[poly.material_index] if old else None
            oldband=int(original.get('round4_band',0)) if original else 0
            c=obj.matrix_world@poly.center
            name=obj.name
            band=0
            if labels is not None:
                centre=means[owners[labels[poly.index]]]
                # Few broad masses, with the lowest hull and gaps darkest.
                band=0 if centre[2]<-.065 else (1 if centre[0]<.08 else 3)
            elif oldband in [8,12] or any(s in name for s in ['slit','throat','red_running_light']):band=oldband if oldband in [8,12] else 8
            elif mode=='V1' and uv and 'retained' not in name and not (original and 'round4_band' in original):
                oldtrim=int(np.mean([uv.data[i].uv.y for i in poly.loop_indices])*8)%8
                band=12 if oldtrim==7 and c.x<-.35 else (8 if oldtrim==7 else (3 if oldtrim==4 else 1))
            elif 'trophy_plate' in name:band=2
            elif 'overlapping_hood' in name:band=2 if c.x<.26 else 1
            elif 'reference_primary' in name:band=3 if oldband==0 else (0 if poly.normal.z<-.5 else 1)
            elif any(s in name for s in ['recess','glazing','rocket_armoured_case','radiator']):band=0 if oldband!=1 else 1
            elif any(s in name for s in ['hood','armour','service_bank','housing','scoop']):band=3 if c.x>.08 else 1
            else:band=1 if oldband in [0,1,2,5,6,7,9,10,11] else 3
            if mode=='V3' and widths_game[1]<2 and band not in [2,8,12] and not any(s in name for s in ['recess','glazing']):
                # The attached hull mass owns the coat of small fittings.
                # Fitting normals and actual cavities still describe depth.
                band=inherited
            # Tiny running lights are paint in this pass. The true engine
            # banks remain the one grouped light feature at the stern.
            if band==8:band=2
            if band not in mats:mats[band]=paint.make_material(pc,band)[0]
            ids.append(band);counts[band]+=1
        me.materials.clear();local={}
        for key in dict.fromkeys(ids):local[key]=len(me.materials);me.materials.append(mats[key])
        me.polygons.foreach_set('material_index',np.array([local[k] for k in ids],np.int32))
    return dict(counts)


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--pc',type=Path,required=True)
    ap.add_argument('--work',type=Path,required=True);ap.add_argument('--route',choices=['V1','V3'],required=True)
    a=ap.parse_args(sys.argv[sys.argv.index('--')+1:]);start=time.perf_counter()
    folder=a.work/'C19_51'/a.route;folder.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    prior.paint=paint;prior.assign=assign
    if a.route=='V1':objects,meta=prior.variant1(a,folder)
    else:
        sys.path.insert(0,str(HERE.parent/'hs'))
        import detail_lib as detail
        import hs_lib as hs
        original=detail.detail_pass;passes=0
        def measured_pass(*args,**kwargs):
            nonlocal passes
            passes+=1;before=set(hs.PARTS)
            result=original(*args,**kwargs)
            for obj in hs.PARTS:
                if obj not in before:obj['round6_detail_pass']=passes
            return result
        detail.detail_pass=measured_pass
        import round4_hand
        objects,meta=round4_hand.build(a,folder,prior.kit,prior.lib,paint,assign,prior.marks)
        meta['cut']=CUT
    result=prior.lib.export(objects,folder,a.route);result.update(meta)
    result.update(route=a.route,seconds=time.perf_counter()-start,projected_paint=False,round=6,
                  recipe_sha256=prior.lib.sha(HERE/'round6_material.py'),builder_sha256=prior.lib.sha(__file__))
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/'prototype.blend'))
    (folder/'build.json').write_text(json.dumps(result,indent=2)+'\n')
    print('[round6] BUILD PASS',a.route,result['triangles'],flush=True)


if __name__=='__main__':main()
