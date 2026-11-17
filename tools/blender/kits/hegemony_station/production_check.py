"""Refs #975. Read the actual GLB; reject lost paint, shape or texture density."""
import argparse
import json
from pathlib import Path
import struct
import sys
import hashlib
import io
from PIL import Image
import numpy as np
from check import glb_json, exported_bounds


def inspect(path):
    doc = glb_json(path)
    raw = path.read_bytes()
    length = struct.unpack_from('<I', raw, 12)[0]
    binary = raw[28+length:]

    def values(index):
        acc = doc['accessors'][index]
        view = doc['bufferViews'][acc['bufferView']]
        n = dict(SCALAR=1,VEC2=2,VEC3=3,VEC4=4)[acc['type']]
        dtype = {5121:'u1',5123:'<u2',5125:'<u4',5126:'<f4'}[acc['componentType']]
        start = view.get('byteOffset',0) + acc.get('byteOffset',0)
        stride = view.get('byteStride',np.dtype(dtype).itemsize*n)
        return np.ndarray((acc['count'],n), dtype=dtype, buffer=binary,
                          offset=start,strides=(stride,np.dtype(dtype).itemsize)).copy()

    primitives = [p for m in doc['meshes'] for p in m['primitives']]
    triangles = sum(doc['accessors'][p['indices']]['count']//3 for p in primitives)
    # All exported mesh nodes share the kit's uniform scale at the root.
    scale = next(n['scale'][0] for n in doc['nodes'] if n.get('name') == 'station_T2')
    density = []
    resolutions = {}
    def texture_size(index):
        image_index = doc['textures'][index]['source']
        if image_index not in resolutions:
            view = doc['bufferViews'][doc['images'][image_index]['bufferView']]
            start = view.get('byteOffset',0)
            with Image.open(io.BytesIO(binary[start:start+view['byteLength']])) as image:
                resolutions[image_index] = image.size
        return resolutions[image_index]
    for p in primitives:
        mat = doc['materials'][p['material']]
        if not mat['name'].startswith('T2_painted_'): continue
        pbr = mat['pbrMetallicRoughness']
        assert 'baseColorTexture' in pbr, 'lost albedo: '+mat['name']
        assert 'metallicRoughnessTexture' in pbr, 'lost ORM: '+mat['name']
        assert 'normalTexture' in mat, 'lost detail normal: '+mat['name']
        assert 'COLOR_0' in p['attributes'], 'lost geometry wear: '+mat['name']
        width,height = texture_size(pbr['baseColorTexture']['index'])
        xyz = values(p['attributes']['POSITION']) * scale
        uv = values(p['attributes']['TEXCOORD_0'])
        idx = values(p['indices']).reshape(-1,3)
        a = xyz[idx]
        area = np.linalg.norm(np.cross(a[:,1]-a[:,0],a[:,2]-a[:,0]),axis=1)/2
        q = uv[idx]
        delta1, delta2 = q[:,1]-q[:,0], q[:,2]-q[:,0]
        ua = np.abs(delta1[:,0]*delta2[:,1]-delta1[:,1]*delta2[:,0])/2
        valid = area > 1e-9
        tpu = np.sqrt(ua[valid]*width*height/area[valid])
        density.append(dict(material=mat['name'], surface_area=float(area.sum()),
              texture_resolution=[width,height],
              texels_per_unit=float(np.sqrt(ua.sum()*width*height/area.sum())),
              minimum_triangle_texels_per_unit=float(tpu.min())))
    assert density, 'no painted primitives'
    return dict(triangles=triangles,surfaces=len(primitives),materials=len(doc['materials']),
                glb_sha256=hashlib.sha256(raw).hexdigest(),
                mesh_nodes=sum('mesh' in n for n in doc['nodes']),bytes=path.stat().st_size,
                bounds=exported_bounds(doc),density=density,
                animations=[a.get('name') for a in doc.get('animations',[])])


def geometry(path):
    """Canonical world-space triangles, independent of UV and material splits."""
    doc = glb_json(path)
    raw = path.read_bytes()
    binary = raw[28+struct.unpack_from('<I',raw,12)[0]:]
    def values(index):
        a = doc['accessors'][index]
        v = doc['bufferViews'][a['bufferView']]
        count = dict(SCALAR=1,VEC3=3)[a['type']]
        dtype = np.dtype({5121:'u1',5123:'<u2',5125:'<u4',5126:'<f4'}[a['componentType']])
        return np.ndarray((a['count'],count),dtype=dtype,buffer=binary,
              offset=v.get('byteOffset',0)+a.get('byteOffset',0),
              strides=(v.get('byteStride',dtype.itemsize*count),dtype.itemsize)).copy()
    def transform(n):
        if 'matrix' in n: return np.array(n['matrix']).reshape(4,4).T
        x,y,z,w = n.get('rotation',[0,0,0,1])
        m = np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),0],
                      [2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),0],
                      [2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y),0],[0,0,0,1]],float)
        m[:3,:3] *= n.get('scale',[1,1,1])
        m[:3,3] = n.get('translation',[0,0,0])
        return m
    rows = []
    def visit(index,parent):
        node = doc['nodes'][index]
        matrix = parent @ transform(node)
        if 'mesh' in node:
            for p in doc['meshes'][node['mesh']]['primitives']:
                xyz = values(p['attributes']['POSITION']) @ matrix[:3,:3].T + matrix[:3,3]
                idx = values(p['indices']).reshape(-1,3)
                tris = np.rint(xyz[idx]*10000).astype(np.int64)
                # Sort each triangle's vertices, then the complete triangle list.
                order = np.lexsort((tris[:,:,2],tris[:,:,1],tris[:,:,0]),axis=1)
                tris = np.take_along_axis(tris,order[:,:,None],axis=1)
                rows.append(tris.reshape(-1,9))
        for child in node.get('children',[]): visit(child,matrix)
    for node in doc['scenes'][doc.get('scene',0)]['nodes']: visit(node,np.eye(4))
    rows = np.concatenate(rows)
    order = np.lexsort(tuple(rows[:,i] for i in range(8,-1,-1)))
    return rows[order]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--gate', action='store_true')
    ap.add_argument('--baseline', type=Path)
    a = ap.parse_args()
    out = Path(a.out)
    shape = json.loads((out/'shape_preservation.json').read_text())
    baseline = json.loads((Path(__file__).resolve().parents[4]/'docs/shots/look_bench/station/cost.json').read_text())
    report = inspect(out/'station_T2.glb')
    manifest = json.loads((out/'production_manifest.json').read_text())
    here = Path(__file__).resolve().parent
    for name, expected in manifest['source_hashes'].items():
        source = (here.parent/'hegemony'/name if name == 'stack.py' else
                  here.parent/'shared'/name if name == 'paint_stack.py' else here/name)
        assert hashlib.sha256(source.read_bytes()).hexdigest() == expected, 'stale painted source: '+name
    cruiser = json.loads((out/'cruiser_density.json').read_text())
    assert shape['pass_unchanged'], 'changed evaluated geometry'
    assert report['triangles'] == shape['triangles'] == baseline['triangles'], 'lost source triangles'
    assert report['animations'], 'lost hanging-radiator motion'
    # Compare like measurements: surface-area weighted density on every material
    # against even the cruiser's finest triangle. Original bevels contain near
    # zero-width slivers; their per-triangle minima remain reported above.
    minimum = min(r['texels_per_unit'] for r in report['density'])
    assert minimum >= cruiser['max_triangle_texels_per_unit'], 'station is coarser than cruiser'
    report['cruiser'] = cruiser
    report['lowest_surface_texels_per_unit'] = minimum
    report['density_vs_cruiser_mean'] = minimum/cruiser['texels_per_unit']
    report['pass'] = True
    if a.baseline:
        old = geometry(a.baseline)
        new = geometry(out/'station_T2.glb')
        assert np.array_equal(old,new), 'exported world-space shape differs from PR 700 review GLB'
        def breaks(path):
            doc = glb_json(path)
            node = next(n for n in doc['nodes'] if n.get('name') == 'station_T2')
            return json.loads(node['extras']['joints_json'])
        assert breaks(a.baseline) == breaks(out/'station_T2.glb'), 'authored joint metadata differs from PR 700'
        report['baseline_geometry'] = dict(pass_=True,triangles=len(old),
            authored_joints_unchanged=True,
            precision_world_units=.0001,baseline_sha256=hashlib.sha256(a.baseline.read_bytes()).hexdigest(),
            canonical_geometry_sha256=hashlib.sha256(old.tobytes()).hexdigest())
    if a.gate:
        gate = json.loads((out/'gate/scene_gate.json').read_text())
        assert gate['map'] == 'station', 'timing did not use a station map'
        assert gate.get('station_T2_instances', 0) >= 1, 'timing did not load the installed T2'
        assert gate['renderer'] == 'forward_plus', 'timing used the dummy renderer'
        assert len(gate['modes']['base']) == len(gate['modes']['res_2160']) == 3, 'incomplete gate'
        base = [r['frame_median'] for r in gate['modes']['base']]
        gpu4k = [r['gpu_median'] for r in gate['modes']['res_2160']]
        assert max(base) <= 12.5, '1080p frame median exceeds 12.5 ms: '+str(base)
        assert max(gpu4k) <= 12.5, '4K GPU median exceeds 12.5 ms: '+str(gpu4k)
        report['frame_gate'] = dict(pass_=True, frame1080_ms=base, gpu4k_ms=gpu4k,
                                    source='gate/scene_gate.json')
    (out/'production_checks.json').write_text(json.dumps(report,indent=2)+'\n')
    print('T2 PRODUCTION CHECK PASS:',report['triangles'],'triangles;',report['surfaces'],
          'surfaces; lowest surface mean',round(minimum,2),'texels/u; cruiser mean',round(cruiser['texels_per_unit'],2))


if __name__ == '__main__': main()
