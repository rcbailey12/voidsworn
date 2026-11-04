"""Keep native AI topology without putting 20M-face parts through BMesh.

Adds smooth normals and shared trim UVs with bounded array scratch space.
There is no remesh, triangle target, decimation or copied AI texture.
"""
import argparse
from contextlib import contextmanager
import json
import os
from pathlib import Path
import struct
import time

import numpy as np


@contextmanager
def packing_lock(work):
    # Windows releases this lock if a watchdog ends a crashed worker. A
    # second queued run can then recover without deleting a stale lock file.
    import msvcrt
    with (work/'.pack.lock').open('a+b') as handle:
        if handle.tell()==0:handle.write(b'0');handle.flush()
        waiting=False
        while True:
            try:
                handle.seek(0);msvcrt.locking(handle.fileno(),msvcrt.LK_NBLCK,1)
                break
            except OSError:
                if not waiting:print('[repair129] waiting for the active native packer',flush=True)
                waiting=True;time.sleep(2)
        try:yield
        finally:
            handle.seek(0);msvcrt.locking(handle.fileno(),msvcrt.LK_UNLCK,1)


def read_glb(path):
    with path.open('rb') as stream:
        assert stream.read(4)==b'glTF'
        stream.seek(12);length=struct.unpack('<I',stream.read(4))[0]
        stream.seek(20);doc=json.loads(stream.read(length))
    binary=20+length+8
    def accessor(index):
        a=doc['accessors'][index];view=doc['bufferViews'][a['bufferView']]
        dtype={5126:'<f4',5125:'<u4',5123:'<u2'}[a['componentType']]
        width={'VEC3':3,'SCALAR':1}[a['type']]
        assert view.get('byteStride',np.dtype(dtype).itemsize*width)==np.dtype(dtype).itemsize*width
        shape=(a['count'],width) if width>1 else (a['count'],)
        return np.memmap(path,mode='r',dtype=dtype,shape=shape,
                         offset=binary+view.get('byteOffset',0)+a.get('byteOffset',0))
    primitive=doc['meshes'][0]['primitives'][0]
    return accessor(primitive['attributes']['POSITION']),accessor(primitive['indices']).reshape(-1,3)


def pack(path,out,shape,band):
    start=time.perf_counter();pos,faces=read_glb(path)
    raw_lo,raw_hi=pos.min(0),pos.max(0)
    # The input was conditioned at Pixal azimuth 90: image-right is -Z.
    # Seat that longitudinal axis along the ship's +X before fitting.
    lo=np.array([-raw_hi[2],raw_lo[1],raw_lo[0]])
    hi=np.array([-raw_lo[2],raw_hi[1],raw_hi[0]])
    uniform_scale=float(np.min(np.array(shape)/np.maximum(hi-lo,1e-9)))
    actual_dimensions=(hi-lo)*uniform_scale
    sample=np.asarray(faces[::max(1,len(faces)//200000)])
    centre=(raw_lo+raw_hi)/2
    a,b,c=[np.asarray(pos[sample[:,i]],dtype=np.float64)-centre for i in range(3)]
    signed_volume=float(np.einsum('ij,ij->i',a,np.cross(b,c)).sum()/6)
    reverse=signed_volume<0
    fitted=np.memmap(out.with_suffix('.positions'),mode='w+',dtype='<f4',shape=pos.shape)
    step=500000
    for begin in range(0,len(pos),step):
        chunk=pos[begin:begin+step]
        oriented=np.stack([-chunk[:,2],chunk[:,1],chunk[:,0]],1)
        fitted[begin:begin+step]=(oriented-(lo+hi)/2)*uniform_scale
    normal=np.zeros_like(fitted)
    valid_faces=np.memmap(out.with_suffix('.indices'),mode='w+',dtype='<u4',shape=faces.shape)
    count=0
    for begin in range(0,len(faces),step):
        f=faces[begin:begin+step]
        if reverse:f=f[:,[0,2,1]]
        a=fitted[f[:,0]];b=fitted[f[:,1]];c=fitted[f[:,2]]
        n=np.cross(b-a,c-a)
        good=np.linalg.norm(n,axis=1)>1e-14
        f=f[good];n=n[good]
        valid_faces[count:count+len(f)]=f;count+=len(f)
        for j in range(3):np.add.at(normal,f[:,j],n)
    uv=np.memmap(out.with_suffix('.uv'),mode='w+',dtype='<f4',shape=(len(pos),2))
    for begin in range(0,len(pos),step):
        sl=slice(begin,begin+step);n=normal[sl]
        magnitude=np.linalg.norm(n,axis=1,keepdims=True)
        n/=np.maximum(magnitude,1e-20)
        n[magnitude[:,0]<1e-20]=(0,1,0)
        uv[sl,0]=np.mod(fitted[sl,0]*11+.5,.96)+.02
        # Blender's trim convention starts at the image bottom. glTF UVs
        # start at the top, so direct array exports must flip V explicitly.
        uv[sl,1]=1-(band+.25+np.mod((fitted[sl,1]+fitted[sl,2])*13+.5,.48))/8
    arrays=[fitted,normal,uv,valid_faces[:count]]
    views=[];offset=0
    for array in arrays:
        views.append(dict(buffer=0,byteOffset=offset,byteLength=array.nbytes))
        offset+=array.nbytes
    doc=dict(asset=dict(version='2.0',generator='Voidsworn issue 129 native topology trim packer'),
        buffers=[dict(byteLength=offset)],bufferViews=views,
        accessors=[dict(bufferView=0,componentType=5126,count=len(pos),type='VEC3',
                        min=fitted.min(0).tolist(),max=fitted.max(0).tolist()),
                   dict(bufferView=1,componentType=5126,count=len(pos),type='VEC3'),
                   dict(bufferView=2,componentType=5126,count=len(pos),type='VEC2'),
                   dict(bufferView=3,componentType=5125,count=count*3,type='SCALAR')],
        images=[dict(uri='../shared/trim_'+name+'.png') for name in ['base','normal','orm']],
        textures=[dict(source=i) for i in range(3)],
        materials=[dict(name='native_AI_shared_trim',pbrMetallicRoughness=dict(
            baseColorTexture=dict(index=0),metallicRoughnessTexture=dict(index=2),
            metallicFactor=1,roughnessFactor=1),normalTexture=dict(index=1),occlusionTexture=dict(index=2))],
        meshes=[dict(primitives=[dict(attributes=dict(POSITION=0,NORMAL=1,TEXCOORD_0=2),indices=3,material=0)])],
        nodes=[dict(mesh=0)],scenes=[dict(nodes=[0])],scene=0)
    encoded=json.dumps(doc,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4)
    with out.open('wb') as stream:
        stream.write(struct.pack('<4sII',b'glTF',2,12+8+len(encoded)+8+offset))
        stream.write(struct.pack('<I4s',len(encoded),b'JSON'));stream.write(encoded)
        stream.write(struct.pack('<I4s',offset,b'BIN\0'))
        for array in arrays:stream.write(memoryview(array).cast('B'))
    return dict(packed_mesh=str(out),triangles=count,raw_triangles=len(faces),
                source_mesh=str(path),pack_version=3,
                source_sample_signed_volume=signed_volume,reversed_inward_source=reverse,
                zero_area_removed=len(faces)-count,vertices=len(pos),
                source_dimensions=(raw_hi-raw_lo).tolist(),oriented_dimensions=(hi-lo).tolist(),
                orientation='X=-source Z; Y=source Y; Z=source X',
                fitted_godot_dimensions=actual_dimensions.tolist(),
                target_limits=shape,uniform_scale=uniform_scale,
                cleanup_seconds=time.perf_counter()-start,no_decimation=True)


def pack_all(work):
    rows=json.loads((work/'parts.json').read_text())
    path=work/'packed.json'
    packed=json.loads(path.read_text()) if path.exists() else {}
    shapes={'engine':[.072,.10,.125],'gun':[.045,.036,.034],
            'bridge':[.15,.073,.078],'midships':[.12,.21,.20]}
    for name,row in rows.items():
        if 'mesh' not in row:
            print('[repair129] waiting for native part',name,flush=True)
            continue
        old=packed.get(name,{})
        if old.get('pack_version')==3 and old.get('source_mesh')==row['mesh'] and Path(old['packed_mesh']).exists():continue
        result=pack(Path(row['mesh']),work/(name+'_packed.glb'),shapes[name],
                    3 if name in ['engine','gun'] else 1)
        packed[name]=result;path.write_text(json.dumps(packed,indent=2)+'\n')
        print('[repair129] native part packed',name,result['triangles'],flush=True)


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--work',type=Path,required=True);a=ap.parse_args()
    assert a.work.resolve().is_relative_to(Path(os.environ['TEMP']).resolve())
    with packing_lock(a.work):pack_all(a.work)


if __name__=='__main__':main()
