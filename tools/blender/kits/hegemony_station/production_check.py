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


def inspect(path, fault=None):
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
    paint_colours = []
    glass = []
    resolutions = {}
    pixels = {}
    detail = []
    module_samples = {}
    def texture_pixels(index):
        image_index = doc['textures'][index]['source']
        if image_index not in pixels:
            view = doc['bufferViews'][doc['images'][image_index]['bufferView']]
            start = view.get('byteOffset',0)
            with Image.open(io.BytesIO(binary[start:start+view['byteLength']])) as image:
                pixels[image_index] = np.asarray(image.convert('RGB')).copy()
        return pixels[image_index]
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
        name = mat['name']
        pbr = mat['pbrMetallicRoughness']
        if fault == 'missing_detail' and name == 'T2_painted_dark': mat.pop('normalTexture',None)
        for key,source in [('baseColorTexture',pbr),('metallicRoughnessTexture',pbr),('normalTexture',mat)]:
            assert key in source, 'missing '+key+' detail map: '+name
        albedo = texture_pixels(pbr['baseColorTexture']['index'])
        if fault == 'flat_albedo': albedo = np.full_like(albedo,64)
        normal = texture_pixels(mat['normalTexture']['index'])
        orm = texture_pixels(pbr['metallicRoughnessTexture']['index'])
        albedo_range = int(np.ptp(albedo.astype(np.int16),axis=(0,1)).max())
        normal_range = int(np.ptp(normal.astype(np.int16),axis=(0,1))[:2].max())
        rough_range = int(np.ptp(orm[...,1].astype(np.int16)))
        assert albedo_range > 1, 'flat albedo detail map: '+name
        assert normal_range > 1, 'flat normal detail map: '+name
        assert rough_range > 1, 'flat roughness detail map: '+name
        assert '_T2_MODULE' in p['attributes'], 'missing exported module identity: '+name
        module = values(p['attributes']['_T2_MODULE']).reshape(-1).astype(int)
        uv = values(p['attributes']['TEXCOORD_0'])
        indices = values(p['indices']).reshape(-1,3)
        colours = np.ones((len(uv),3))
        if 'COLOR_0' in p['attributes']:
            colours = values(p['attributes']['COLOR_0'])[:,:3]
            if colours.dtype.kind == 'u': colours = colours/np.iinfo(colours.dtype).max
        for ident in np.unique(module):
            triangles0 = indices[module[indices[:,0]] == ident]
            select = triangles0[np.linspace(0,len(triangles0)-1,min(3072,len(triangles0))).astype(int)]
            for weights in ((1/3,1/3,1/3),(.8,.1,.1),(.1,.8,.1),(.1,.1,.8)):
                q = (uv[select]*np.array(weights)[None,:,None]).sum(axis=1)
                c = (colours[select]*np.array(weights)[None,:,None]).sum(axis=1)
                if fault == 'flat_module' and ident == 1: q[:]=.125; c[:]=1
                h,w = albedo.shape[:2]
                sampled = albedo[(np.floor((1-q[:,1])*h).astype(int)%h),np.floor(q[:,0]*w).astype(int)%w]/255*c
                module_samples.setdefault((int(ident),name),[]).append(sampled)
        if name not in {r['material'] for r in detail}:
            detail.append(dict(material=name,albedo_range_8bit=albedo_range,
                               normal_xy_range_8bit=normal_range,roughness_range_8bit=rough_range))
        if mat['name'].startswith('T2_glass_'):
            assert 'baseColorTexture' in mat['pbrMetallicRoughness'], 'blank glass albedo'
            assert 'metallicRoughnessTexture' in mat['pbrMetallicRoughness'], 'lost reflective glazing'
            assert 'emissiveTexture' in mat, 'lost framed room/interior emission'
            glass.append(dict(material=mat['name'], triangles=doc['accessors'][p['indices']]['count']//3))
        if not mat['name'].startswith('T2_painted_'): continue
        assert 'baseColorTexture' in pbr, 'lost albedo: '+mat['name']
        assert 'metallicRoughnessTexture' in pbr, 'lost ORM: '+mat['name']
        assert 'normalTexture' in mat, 'lost detail normal: '+mat['name']
        assert 'COLOR_0' in p['attributes'], 'lost geometry wear: '+mat['name']
        colours = values(p['attributes']['COLOR_0'])[:,:3]
        if colours.dtype.kind == 'u': colours = colours / np.iinfo(colours.dtype).max
        assert not np.allclose(colours, 1), 'lost paint: white substitute COLOR_0 on '+mat['name']
        paint_colours.append(dict(material=mat['name'],
            vertex_rgb_p10=np.percentile(colours,10,axis=0).tolist(),
            vertex_rgb_p90=np.percentile(colours,90,axis=0).tolist()))
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
    module_detail = []
    for (ident,name),samples in sorted(module_samples.items()):
        sample = np.concatenate(samples)
        span = float(np.ptp(sample,axis=0).max())
        assert span > 1/255, f'flat albedo across module {ident}: {name}'
        module_detail.append(dict(module_id=ident,material=name,samples=len(sample),sampled_albedo_range=span))
    return dict(triangles=triangles,surfaces=len(primitives),materials=len(doc['materials']),
                glb_sha256=hashlib.sha256(raw).hexdigest(),
                mesh_nodes=sum('mesh' in n for n in doc['nodes']),bytes=path.stat().st_size,
                bounds=exported_bounds(doc),density=density, glass=glass, paint_colours=paint_colours,
                material_detail=detail,module_detail=module_detail,
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
    ap.add_argument('--selftest',action='store_true')
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
    assert shape['bounds_unchanged'], 'changed station bounds'
    assert set(shape['changed_objects']) <= set(shape['allowed_changed_objects']), 'unapproved geometry change'
    assert shape['inside_triangles'] == shape['baseline_inside_triangles'], 'changed inside geometry'
    assert report['glass'], 'missing textured station glazing'
    report['windows'] = manifest['windows']
    report['paint_direction'] = manifest['paint_direction']
    # The GLB tessellator retains 1,212 more triangles than Blender's source
    # loop-triangle reader. Compare deltas through the same readers, while
    # retaining the independently measured exported baseline cost.
    expected = baseline['triangles'] + shape['triangles']-shape['baseline_triangles']
    assert report['triangles'] == expected >= baseline['triangles'], 'lost source detail'
    report['geometry_repairs'] = dict(changed_objects=shape['changed_objects'],
        unchanged_objects=shape['unchanged_objects'],bounds_unchanged=True,
        inside_triangles=shape['inside_triangles'],baseline_triangles=shape['baseline_triangles'],
        source='original and repaired builds; only listed loose-piece source meshes may differ')
    counters = {}
    pieces = []
    for row in manifest['details']:
        if row['kind'] != 'attached_wreckage': continue
        module = row['module']
        counters[module] = counters.get(module,0)+1
        pieces.append(dict(piece=module+'/torn_%02d'%counters[module],module=module,
            source_pieces=2 if module == 'folded_plate' else 1,
            triangles_before_bevel=row['triangles'],min=row['min'],max=row['max']))
    assert len(pieces) == 18, 'missing attached wreckage repairs'
    report['geometry_repairs']['attached_wreckage'] = pieces
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
        # Run 3 expressly replaces loose squares. Compare the common geometry
        # and bound all removed source triangles by those exact source meshes.
        old_rows = old.view(np.dtype((np.void,old.dtype.itemsize*9))).ravel()
        new_rows = new.view(np.dtype((np.void,new.dtype.itemsize*9))).ravel()
        old_unique,old_counts = np.unique(old_rows,return_counts=True)
        new_unique,new_counts = np.unique(new_rows,return_counts=True)
        _,old_indices,new_indices = np.intersect1d(old_unique,new_unique,return_indices=True)
        common = int(np.minimum(old_counts[old_indices],new_counts[new_indices]).sum())
        repair_budget = sum(shape['baseline_objects'].get(k,{}).get('triangles',0) for k in shape['changed_objects'])
        assert len(old)-common <= repair_budget, 'export changes exceed scoped loose-piece source meshes'
        def breaks(path):
            doc = glb_json(path)
            node = next(n for n in doc['nodes'] if n.get('name') == 'station_T2')
            return json.loads(node['extras']['joints_json'])
        assert breaks(a.baseline) == breaks(out/'station_T2.glb'), 'authored joint metadata differs from PR 700'
        report['baseline_geometry'] = dict(pass_=True,triangles=len(old),common_triangles=common,
            loose_piece_source_triangle_budget=repair_budget,
            authored_joints_unchanged=True,
            precision_world_units=.0001,baseline_sha256=hashlib.sha256(a.baseline.read_bytes()).hexdigest(),
            canonical_geometry_sha256=hashlib.sha256(old.tobytes()).hexdigest())
    if a.selftest:
        rejected = []
        for fault in ('missing_detail','flat_albedo','flat_module'):
            try: inspect(out/'station_T2.glb',fault=fault)
            except AssertionError as error: rejected.append(dict(fault=fault,rejected=str(error)))
            else: raise AssertionError('checker accepted planted fault: '+fault)
        report['planted_faults'] = rejected
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
