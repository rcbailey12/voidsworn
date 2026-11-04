"""Stream the untouched generation for display without a huge Blender import."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import struct
import sys
import time

import numpy as np

sys.path.insert(0,str(Path(__file__).parent))
from pack_parts import read_glb


def main(work):
    start=time.perf_counter()
    source=Path(json.loads((work/'reference/mesh.json').read_text())['source'])
    pos,faces=read_glb(source)
    folder=work/'C19_51/Raw';folder.mkdir(parents=True,exist_ok=True)
    lo,hi=pos.min(0),pos.max(0);centre=(lo+hi)/2
    scale=1/float(hi[2]-lo[2])
    positions=np.memmap(folder/'positions.bin',mode='w+',dtype='<f4',shape=pos.shape)
    normals=np.memmap(folder/'normals.bin',mode='w+',dtype='<f4',shape=pos.shape);normals[:]=0
    indices=np.memmap(folder/'indices.bin',mode='w+',dtype='<u4',shape=faces.shape)
    sample=np.asarray(faces[::max(1,len(faces)//200000)])
    a,b,c=[np.asarray(pos[sample[:,i]],np.float64)-centre for i in range(3)]
    volume=float(np.einsum('ij,ij->i',a,np.cross(b,c)).sum()/6)
    for begin in range(0,len(pos),500000):
        p=(pos[begin:begin+500000]-centre)*scale
        positions[begin:begin+500000]=np.stack([p[:,2],p[:,1],-p[:,0]],1)
    for begin in range(0,len(faces),500000):
        f=np.asarray(faces[begin:begin+500000])
        if volume<0:f=f[:,[0,2,1]]
        indices[begin:begin+len(f)]=f
        n=np.cross(positions[f[:,1]]-positions[f[:,0]],positions[f[:,2]]-positions[f[:,0]])
        for j in range(3):np.add.at(normals,f[:,j],n)
    for begin in range(0,len(pos),500000):
        n=normals[begin:begin+500000]
        n/=np.maximum(np.linalg.norm(n,axis=1,keepdims=True),1e-20)
    arrays=[positions,normals,indices];views=[];offset=0
    for array in arrays:
        views.append(dict(buffer=0,byteOffset=offset,byteLength=array.nbytes));offset+=array.nbytes
    doc=dict(asset=dict(version='2.0',generator='Issue 146 raw presentation only'),
        buffers=[dict(byteLength=offset)],bufferViews=views,
        accessors=[dict(bufferView=0,componentType=5126,count=len(pos),type='VEC3',min=positions.min(0).tolist(),max=positions.max(0).tolist()),
                   dict(bufferView=1,componentType=5126,count=len(pos),type='VEC3'),
                   dict(bufferView=2,componentType=5125,count=indices.size,type='SCALAR')],
        materials=[dict(name='raw_generation_neutral_inspection',pbrMetallicRoughness=dict(baseColorFactor=[.16,.17,.18,1],metallicFactor=.18,roughnessFactor=.7))],
        meshes=[dict(primitives=[dict(attributes=dict(POSITION=0,NORMAL=1),indices=2,material=0)])],
        nodes=[dict(mesh=0)],scenes=[dict(nodes=[0])],scene=0)
    encoded=json.dumps(doc,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4)
    out=folder/'routeRaw.glb'
    with out.open('wb') as stream:
        stream.write(struct.pack('<4sII',b'glTF',2,12+8+len(encoded)+8+offset))
        stream.write(struct.pack('<I4s',len(encoded),b'JSON'));stream.write(encoded)
        stream.write(struct.pack('<I4s',offset,b'BIN\0'))
        for array in arrays:stream.write(memoryview(array).cast('B'))
    sha=lambda p:hashlib.file_digest(Path(p).open('rb'),'sha256').hexdigest()
    meta=dict(route='Raw',triangles=len(faces),source_triangles=len(faces),vertices=len(pos),
        source=str(source),source_sha256=sha(source),sha256=sha(out),bytes=out.stat().st_size,
        source_signed_volume=volume,display_winding_reversed=volume<0,
        presentation='uniform length/axis transform, outward smooth normals, neutral material; all source faces retained',
        geometry_cleanup=False,seconds=time.perf_counter()-start)
    (folder/'build.json').write_text(json.dumps(meta,indent=2)+'\n')
    print('[round4] RAW PASS',len(faces),flush=True)


if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--work',type=Path,required=True);a=ap.parse_args()
    assert a.work.resolve().is_relative_to(Path(os.environ['TEMP']).resolve());main(a.work.resolve())
