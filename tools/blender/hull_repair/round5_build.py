"""Repaint cached round 4 geometry. No generator and no V3 entry point."""
import argparse
import json
from pathlib import Path
import sys
import time

sys.dont_write_bytecode=True
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
import round4_build as prior
import round5_material as paint
import bpy
import numpy as np


def assign(objects,pc,mode):
    cache={};counts={}
    for obj in objects:
        me=obj.data;old=list(me.materials);uv=me.uv_layers.active
        vertices=np.array([v.co[:] for v in me.vertices],np.float32)
        me.calc_loop_triangles()
        faces=np.array([t.vertices for t in me.loop_triangles],np.int32)
        _,labels,_,_=prior.repair.regions(vertices,faces)
        # Region analysis only measures. Its flattened output is discarded.
        cross=np.cross(vertices[faces[:,1]]-vertices[faces[:,0]],vertices[faces[:,2]]-vertices[faces[:,0]])
        areas=np.linalg.norm(cross,axis=1)*.5
        region_area=np.bincount(labels,weights=areas)
        poly_regions=np.zeros(len(me.polygons),np.int32)
        for tri,label in zip(me.loop_triangles,labels):poly_regions[tri.polygon_index]=label
        indices=[]
        for poly,rid in zip(me.polygons,poly_regions):
            original=old[poly.material_index] if old else None
            authored=original and 'round4_band' in original and not original.name.startswith('generated_panel')
            hashed=(int(rid)*2654435761+sum(obj.name.encode())*97)&0xffffffff
            variation=hashed%5
            band=1 if (hashed>>5)%3==0 else 0
            # Only modest physical surface regions can become red trim plates.
            if .00012<region_area[rid]<.0035 and (hashed>>9)%11==0:band=2
            if authored:
                band=int(original['round4_band']);variation=int(original.get('variation',1))
            elif mode=='V1' and uv and 'retained' not in obj.name:
                oldband=int(np.mean([uv.data[i].uv.y for i in poly.loop_indices])*8)%8
                if oldband==7:band=12 if (obj.matrix_world@poly.center).x<-.35 else 8
                elif oldband in [4,5]:band=3 if oldband==4 else 1
            key=(band,variation)
            if key not in cache:cache[key]=paint.make_material(pc,*key)[0]
            indices.append(key);counts[band]=counts.get(band,0)+1
        me.materials.clear();local={}
        for key in dict.fromkeys(indices):local[key]=len(me.materials);me.materials.append(cache[key])
        me.polygons.foreach_set('material_index',np.array([local[k] for k in indices],np.int32))
    return counts


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--pc',type=Path,required=True)
    ap.add_argument('--work',type=Path,required=True);ap.add_argument('--route',choices=['V1','V2'],required=True)
    a=ap.parse_args(sys.argv[sys.argv.index('--')+1:]);start=time.perf_counter()
    folder=a.work/'C19_51'/a.route;folder.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    prior.paint=paint;prior.assign=assign
    objects,meta=(prior.variant1 if a.route=='V1' else prior.variant2)(a,folder)
    result=prior.lib.export(objects,folder,a.route);result.update(meta)
    result.update(route=a.route,seconds=time.perf_counter()-start,projected_paint=False,
                  round=5,geometry_regenerated=False,recipe_sha256=prior.lib.sha(HERE/'round5_material.py'),
                  builder_sha256=prior.lib.sha(__file__))
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/'prototype.blend'))
    (folder/'build.json').write_text(json.dumps(result,indent=2)+'\n')
    print('[round5] BUILD PASS',a.route,result['triangles'],flush=True)


if __name__=='__main__':main()
