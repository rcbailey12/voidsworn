"""R01 source remix and scanned-rock conversion. CPU only, no Blender or GPU.

Pillow and NumPy are already installed in the PC's recorded Python.
Inputs and source receipts are made by planet369_download.bat. No deletion.
"""
import sys
from pathlib import Path as _PicturePath
sys.dont_write_bytecode = True
sys.path.insert(0, str(_PicturePath(__file__).resolve().parents[3] / 'tools'))
from picture_provenance import save_picture

import argparse
import hashlib
import json
import os
from pathlib import Path
import struct
import time

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[3]
ROCKDIR = ROOT / 'godot/world/rocks'
CACHE = Path(os.environ['TEMP']) / 'voidsworn_issue369_sources'
OUT = ROCKDIR / 'r01'


def sample(a, u, v):
    """Bilinear sample: longitude wraps, latitude clamps."""
    h, w = a.shape[:2]
    x = (u % 1) * w - 0.5
    y = np.clip(v * h - 0.5, 0, h - 1)
    ix, iy = np.floor(x).astype(int), np.floor(y).astype(int)
    fx, fy = x - ix, y - iy
    if a.ndim == 3:
        fx, fy = fx[..., None], fy[..., None]
    return ((a[iy, ix % w] * (1-fx) + a[iy, (ix+1) % w] * fx) * (1-fy)
            + (a[np.minimum(iy+1, h-1), ix % w] * (1-fx)
               + a[np.minimum(iy+1, h-1), (ix+1) % w] * fx) * fy)


def remap(d, phase):
    # Continuous on the sphere, including the date line and both poles.
    # Strong non-rigid warp plus a second independent rotation destroys the
    # source globe's arrangement. Colour is rebuilt, never copied RGB.
    x, y, z = d
    q = np.stack([x + .23*np.sin(y*3.3 + z*2.7 + phase),
                  y + .21*np.sin(z*3.1 + x*2.3 + phase*1.7),
                  z + .24*np.sin(x*3.7 + y*2.1 - phase)])
    q /= np.maximum(np.linalg.norm(q, axis=0), 1e-5)
    return np.arctan2(q[0], -q[2])/(2*np.pi)+.5, np.arccos(np.clip(q[1], -1, 1))/np.pi


def planet(width):
    start = time.perf_counter()
    OUT.mkdir(exist_ok=True)
    receipt = json.loads((ROCKDIR / 'SOURCES_369.json').read_text())
    assert len(receipt['sources']) == 10, 'Download and credit every source first'
    lunar_image = Image.open(CACHE / 'lroc_color_poles_8k.tif').convert('L')
    lunar = np.asarray(lunar_image, dtype=np.float32)/255
    # Remove the recognizable broad maria before remixing the small geology.
    # The source terrain stays crisp, without folding it into fluid-looking
    # streaks to hide the source globe's continents and large basins.
    broad = lunar_image.resize((2048,1024)).filter(ImageFilter.GaussianBlur(32)).resize(lunar_image.size)
    lunar = np.clip(.48+(lunar-np.asarray(broad,dtype=np.float32)/255)*1.7,0,1)
    dem = np.asarray(Image.open(CACHE / 'ldem_16_uint.tif'), dtype=np.float32)
    # The NASA half-metre DEM is normalized once, before spherical resampling.
    low, high = np.percentile(dem, [1, 99])
    dem = np.clip((dem-low)/(high-low), 0, 1)
    height = width//2
    colour = np.empty((height, width, 3), dtype=np.uint8)
    packed = np.empty((height, width, 4), dtype=np.uint8)
    u = (np.arange(width, dtype=np.float32)+.5)/width
    phi = (u-.5)*2*np.pi
    for y0 in range(0, height, 64):
        v = (np.arange(y0, min(y0+64, height), dtype=np.float32)+.5)/height
        th = v[:, None]*np.pi
        d = [np.sin(th)*np.sin(phi), np.cos(th)+np.zeros_like(phi), -np.sin(th)*np.cos(phi)]
        ua, va = remap(d, 3.69)
        ub, vb = remap([d[2], -d[0], -d[1]], 8.17)
        c = sample(lunar, ua, va)
        h1 = sample(dem, ub, vb)
        h2 = sample(dem, (ua+.317) % 1, va)
        relief = np.clip(.16+.52*h1+.24*h2+.12*(c-.45), 0, 1)
        # All source colour is discarded. Mineral provinces come from both
        # independent instrument fields, with fresh ridges and basalt lows.
        mineral = np.clip((.67*c+.33*h1-.28)*2.4, 0, 1)
        dark = np.array([.14, .145, .15])
        rust = np.array([.57, .31, .17])
        alb = dark+(rust-dark)*mineral[..., None]
        ridge = np.clip((relief-.55)*1.5, 0, .35)
        alb = alb*(1-ridge[..., None]) + np.array([.69,.57,.39])*ridge[..., None]
        alb *= (.74+.48*c)[..., None]
        colour[y0:y0+len(v)] = (np.clip(alb, 0, 1)*255+.5).astype(np.uint8)
        h16 = (relief*65535+.5).astype(np.uint16)
        # RG is 16-bit relief, B is roughness, A is the moving cloud mask.
        packed[y0:y0+len(v), :, 0] = (h16 >> 8).astype(np.uint8)
        packed[y0:y0+len(v), :, 1] = (h16 & 255).astype(np.uint8)
        roughness = np.clip(.91-.22*mineral+.06*(1-h1), .58, .97)
        packed[y0:y0+len(v), :, 2] = (roughness*255+.5).astype(np.uint8)
        x, y, z = d
        wisps = (np.sin(x*18+y*13+np.sin(z*11)*2.1)
                 +.6*np.sin(z*31-x*9+y*7) + .35*np.sin(y*53+z*19+x*11))
        cloud = np.clip((wisps-.65)*.45, 0, .68)*np.clip((h2-.18)*2, 0, 1)
        packed[y0:y0+len(v), :, 3] = (cloud*255+.5).astype(np.uint8)
    # Colour is sRGB. Relief/roughness/clouds are linear, not colour textures.
    # Full PNGs are scratch inputs to the WebP resource packer. Never
    # ship an oversized PNG or reduce the height field to meet a file limit.
    raw = CACHE / 'r01_remix'
    raw.mkdir(exist_ok=True)
    Image.fromarray(colour).save(raw/'colour.png', compress_level=6)
    Image.fromarray(packed).save(raw/'relief.png', compress_level=6)
    Image.fromarray(packed[:, :, 2]).save(raw/'roughness.png', compress_level=6)
    metadata = {'code': 'R01', 'size': [width, height], 'source_receipt': '../SOURCES_369.json',
                'source_datasets': ['LROC WAC natural colour mosaic', 'LRO LOLA gridded laser altimetry'],
                'seed': [3.69, 8.17], 'script': 'tools/pc/jobs/planet369_remix.py',
                'relief_channels': {'r': 'height high byte', 'g': 'height low byte', 'b': 'roughness', 'a': 'cloud opacity'},
                'cold_remix_seconds': time.perf_counter()-start,
                'storage': 'Set by planet369_pack.bat after encoding',
                'pack_script': 'tools/pc/jobs/planet369_pack.py and planet369_pack.gd',
                'pixel_loss': 'Set by planet369_pack.bat after encoding', 'files': {}}
    (OUT/'bake.json').write_text(json.dumps(metadata, indent=2)+'\n', encoding='ascii')
    # One named image at <=720 high, each original beside the authored result.
    sheet = Image.new('RGB', (1280, 670), '#171717')
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 22)
    for i, (label, im) in enumerate([
        ('LROC WAC / source A', Image.open(CACHE/'lroc_color_poles_8k.tif').convert('RGB')),
        ('LOLA / source B', Image.fromarray((dem*255).astype(np.uint8)).convert('RGB')),
        ('R01 / warped mineral terrain', Image.fromarray(colour))]):
        x0 = 12+i*424
        draw.text((x0, 12), label, fill='white', font=font)
        full = im.copy()
        full.thumbnail((408, 204))
        sheet.paste(full, (x0, 48))
        w, h = im.size
        detail = im.crop((int(w*.36), int(h*.34), int(w*.49), int(h*.60)))
        detail = detail.resize((408, 360), Image.Resampling.LANCZOS)
        sheet.paste(detail, (x0, 290))
        draw.text((x0, 260), 'Terrain detail', fill='white', font=font)
    dest = ROOT/'docs/shots/look_bench/planets'
    dest.mkdir(parents=True, exist_ok=True)
    save_picture(sheet, dest/'R01_sources.jpg', 'sheet built', quality=93)
    print('R01', metadata['size'], 'cold CPU remix seconds', metadata['cold_remix_seconds'], flush=True)


def gltf_arrays(folder):
    doc = json.loads((folder/'source.gltf').read_text())
    buffers = [(folder/b['uri']).read_bytes() for b in doc['buffers']]
    types = {5120:'i1', 5121:'u1', 5122:'<i2', 5123:'<u2', 5125:'<u4', 5126:'<f4'}
    components = {'SCALAR':1, 'VEC2':2, 'VEC3':3, 'VEC4':4}

    def accessor(idx):
        a = doc['accessors'][idx]
        view = doc['bufferViews'][a['bufferView']]
        dtype = np.dtype(types[a['componentType']])
        n = components[a['type']]
        offset = view.get('byteOffset',0)+a.get('byteOffset',0)
        ar = np.ndarray((a['count'], n), dtype, buffers[view['buffer']], offset,
                        strides=(view.get('byteStride', dtype.itemsize*n), dtype.itemsize)).copy()
        if a.get('normalized'):
            ar = ar.astype(np.float32)/np.iinfo(dtype).max
        return ar

    vertices, indices, colours = [], [], []

    def visit(idx, parent):
        node = doc['nodes'][idx]
        if 'matrix' in node:
            xf = np.array(node['matrix']).reshape(4,4).T
        else:
            x,y,z,w = node.get('rotation',[0,0,0,1])
            rot = np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],
                            [2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],
                            [2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])
            xf = np.eye(4)
            xf[:3,:3] = rot @ np.diag(node.get('scale',[1,1,1]))
            xf[:3,3] = node.get('translation',[0,0,0])
        xf = parent @ xf
        if 'mesh' in node:
            for prim in doc['meshes'][node['mesh']]['primitives']:
                assert prim.get('mode',4) == 4, 'Only triangle scans supported'
                p = accessor(prim['attributes']['POSITION'])
                p = p @ xf[:3,:3].T + xf[:3,3]
                ii = accessor(prim['indices']).reshape(-1,3).astype(np.uint32)
                if np.linalg.det(xf[:3,:3]) < 0:
                    ii = ii[:,[0,2,1]]
                uv = accessor(prim['attributes']['TEXCOORD_0'])
                name = folder.name
                diffuse = np.asarray(Image.open(folder/'textures'/f'{name}_diff_1k.jpg').convert('L'), dtype=np.float32)/255
                arm = np.asarray(Image.open(folder/'textures'/f'{name}_arm_1k.jpg').convert('RGB'), dtype=np.float32)/255
                luminance = sample(diffuse, uv[:,0], uv[:,1])
                ao_rough = sample(arm, uv[:,0], uv[:,1])
                # The existing biome shader consumes cavity, crater, fracture,
                # and mineral brightness. Mark scans with G=0.999, a value
                # reserved by the new shader, and keep the scan's measured AO.
                cc = np.stack([ao_rough[:,0], np.full(len(p),.999),
                               1-ao_rough[:,1], luminance], axis=1)
                indices.append(ii+sum(len(v) for v in vertices))
                vertices.append(p)
                colours.append(cc)
        for child in node.get('children',[]):
            visit(child, xf)

    for idx in doc['scenes'][doc.get('scene',0)]['nodes']:
        visit(idx, np.eye(4))
    p, ii, cc = np.concatenate(vertices), np.concatenate(indices), np.concatenate(colours)
    p -= (p.min(axis=0)+p.max(axis=0))*.5
    p /= np.linalg.norm(p, axis=1).max()
    return p.astype(np.float32), ii, cc.astype(np.float32)


def cluster(p, ii, cc, grid):
    # Vertex clustering produces an explicit far mesh without dropping faces
    # randomly or keeping references to absent high-detail buffers.
    keys = np.floor((p+1)*grid).astype(np.int32)
    _, inv = np.unique(keys, axis=0, return_inverse=True)
    count = np.bincount(inv)
    ps = np.stack([np.bincount(inv, weights=p[:,i])/count for i in range(3)], axis=1)
    cs = np.stack([np.bincount(inv, weights=cc[:,i])/count for i in range(4)], axis=1)
    tris = inv[ii]
    valid = (tris[:,0]!=tris[:,1]) & (tris[:,1]!=tris[:,2]) & (tris[:,0]!=tris[:,2])
    tris = tris[valid]
    # The full scan remains at unit radius; the far silhouette uses its actual
    # reduced geometry, never an independently generated rock.
    return ps.astype(np.float32), tris.astype(np.uint32), cs.astype(np.float32)


def write_glb(path, p, ii, cc, source):
    normals = np.zeros_like(p)
    face = np.cross(p[ii[:,1]]-p[ii[:,0]], p[ii[:,2]]-p[ii[:,0]])
    for k in range(3):
        np.add.at(normals, ii[:,k], face)
    normals /= np.maximum(np.linalg.norm(normals,axis=1,keepdims=True),1e-9)
    assert len(ii)>0 and np.isfinite(normals).all()
    arrays = [p.astype('<f4'), normals.astype('<f4'), cc.astype('<f4'), ii.astype('<u4')]
    parts, views, accessors = [], [], []
    offset = 0
    for i, ar in enumerate(arrays):
        blob = ar.tobytes()
        views.append({'buffer':0, 'byteOffset':offset, 'byteLength':len(blob), 'target':34963 if i==3 else 34962})
        a = {'bufferView':i, 'componentType':5125 if i==3 else 5126,
             'count':int(ar.size if i==3 else len(ar)), 'type':'SCALAR' if i==3 else ('VEC4' if i==2 else 'VEC3')}
        if i==0:
            a.update(min=p.min(axis=0).tolist(),max=p.max(axis=0).tolist())
        accessors.append(a)
        parts.append(blob)
        offset += len(blob)
    doc = {'asset':{'version':'2.0','generator':'Voidsworn scan conversion issue369'},
           'scene':0,'scenes':[{'nodes':[0]}], 'nodes':[{'mesh':0}],
           'meshes':[{'primitives':[{'attributes':{'POSITION':0,'NORMAL':1,'COLOR_0':2},'indices':3}]}],
           'accessors':accessors,'bufferViews':views,'buffers':[{'byteLength':offset}],
           'extras':{'source':source, 'credit_receipt':'SOURCES_369.json','unit_radius':1.0}}
    js = json.dumps(doc,separators=(',',':')).encode('ascii')
    js += b' '*((-len(js))%4)
    data = b''.join(parts)
    data += b'\0'*((-len(data))%4)
    glb = struct.pack('<III',0x46546c67,2,28+len(js)+len(data))
    glb += struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(data),0x004e4942)+data
    path.write_bytes(glb)


def rocks():
    from planet369_download import ROCKS
    manifest = {'rocks':[], 'source_receipt':'SOURCES_369.json', 'script':'tools/pc/jobs/planet369_remix.py'}
    # Issue 1361: only the six crisp scans ship (scan_06 and scan_07 retired); after a rerun, re-bake the fresh-face
    # channel with godot/world/tools/scan_facet.py and refresh the hashes in scans.json.
    for i, source in enumerate(ROCKS[:6]):
        p, ii, cc = gltf_arrays(CACHE/source)
        name = 'scan_%02d' % i
        low = cluster(p, ii, cc, 13)
        files = []
        for suffix, arrays in [('',(p,ii,cc)),('_lo',low)]:
            path = ROCKDIR/(name+suffix+'.glb')
            write_glb(path,*arrays,source)
            files.append({'file':path.name,'triangles':len(arrays[1]),'vertices':len(arrays[0]),
                          'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
        manifest['rocks'].append({'name':name,'source':source,'family':'scan',
                                  'ext':np.ptp(p,axis=0).tolist(), 'files':files})
        print(name, source, 'triangles', len(ii), 'far', len(low[1]), flush=True)
    (ROCKDIR/'scans.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='ascii')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--only',choices=['planet','rocks','all'],default='all')
    parser.add_argument('--size', type=int, default=8192)
    args = parser.parse_args()
    if args.size != 8192:
        parser.error('The shipped R01 set must be 8192x4096')
    if args.only in ['planet','all']:
        planet(args.size)
    if args.only in ['rocks','all']:
        rocks()
