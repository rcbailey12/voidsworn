# A4 pack: the Godot-ready files for one ship from what a4_ship.py wrote (CODE_meta.json, CODE_ship.npz, CODE_wreck.npz, baked PNG maps).
# Needs numpy and PIL (on the PC: ComfyUI's Python; Blender 4.5's has no PIL).
#   python pack.py OUT/CODE_meta.json GODOT_DIR [--res 2048] [--hi HI_DIR --hires 4096]
# writes GODOT_DIR/CODE/: CODE.glb (hull + hard point nodes), CODE_wreck.glb (chunk nodes), CODE_base.jpg, CODE_orm.jpg, CODE_normal.png,
# CODE_emissive.jpg (shared by both glbs, referenced by relative URI), and updates GODOT_DIR/ships.json (the fleet manifest).
import sys, os, json, shutil
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path: sys.path.insert(0, HERE)
import numpy as np
import gio

EMIT_STRENGTH = 4.0  # the A2/A3 max-detail emissive gain (contrib/opus/enginetest: maps baked 0..1, strength 4 in both engines)


def fix_tangents(nor, tg):
    tg = tg.copy(); t = tg[:, :3]; t -= nor * (t * nor).sum(1, keepdims=True); L = np.linalg.norm(t, axis=1); bad = L < 1e-4
    if bad.any():
        a = np.where(np.abs(nor[bad, 0:1]) < .9, np.array([[1., 0, 0]]), np.array([[0., 1, 0]])); a = a - nor[bad] * (a * nor[bad]).sum(1, keepdims=True)
        t[bad] = a; L[bad] = np.linalg.norm(a, axis=1)
    tg[:, :3] = t / L[:, None]; tg[:, 3] = np.where(tg[:, 3] < 0, -1., 1.); return tg.astype(np.float32)


def unit(n):
    n = np.asarray(n, np.float32); return (n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-9)).astype(np.float32)


def write_textures(meta, d, code, res):
    mp = meta['maps']; files = {}
    # normal maps as high-quality JPEG too: Godot re-compresses every texture to a VRAM format on import anyway, and a PNG normal map is 4
    # to 5 times the size in the repo
    for slot, key, kind, q in (('base', 'albedo', 'jpg', 90), ('orm', 'orm', 'jpg', 90), ('normal', 'normal', 'jpg', 95), ('emissive', 'emit', 'jpg', 90)):
        fn = f'{code}_{slot}.{kind}'; open(os.path.join(d, fn), 'wb').write(gio.img_bytes(mp[key], kind, quality=q, size=res)); files[slot] = fn
    return files


def materials(G, code, files):
    t = {k: G.image(uri=v, name=f'{code}_{k}') for k, v in files.items()}
    hull = G.material({'name': f'{code}_hull', 'pbrMetallicRoughness': {'baseColorTexture': {'index': t['base']}, 'metallicRoughnessTexture': {'index': t['orm']},
                                                                          'metallicFactor': 1.0, 'roughnessFactor': 1.0},
                       'normalTexture': {'index': t['normal'], 'scale': 1.0}, 'occlusionTexture': {'index': t['orm'], 'strength': 1.0},
                       'emissiveTexture': {'index': t['emissive']}, 'emissiveFactor': [1, 1, 1], 'extensions': {'KHR_materials_emissive_strength': {'emissiveStrength': EMIT_STRENGTH}}})
    return hull


def pack(meta_path, gdir, res=2048, tangents=False):
    """tangents=False leaves TANGENT out: Godot's importer generates MikkTSpace tangents (the same method the bake used), a third less file"""
    meta = json.load(open(meta_path)); code = meta['code']; base = os.path.dirname(meta_path)
    d = os.path.join(gdir, code); os.makedirs(d, exist_ok=True)
    files = write_textures(meta, d, code, res)
    # ship
    m = dict(np.load(meta['mesh'] if os.path.exists(meta['mesh']) else os.path.join(base, os.path.basename(meta['mesh']))))
    G = gio.GLB(); mat = materials(G, code, files)
    nor = unit(m['nor']); tan = fix_tangents(nor, m['tan'])
    mesh = G.mesh(code, [dict(pos=m['pos'], nor=nor, idx=m['idx'], uv=m['uv'], tan=tan if tangents else None, mat=mat)])
    kids = []
    for h in meta['hardpoints']:
        kids.append(G.node({'name': h['name'], 'translation': [round(float(v), 6) for v in h['p']], 'rotation': gio.basis_quat(h['fwd'], h['up']), 'extras': h['extras']}))
    extras = dict(code=code, faction=meta['faction'], cls=meta['cls'], band=meta['band'], length_world=meta['length_world'], palette=meta['palette'],
                  frame=meta['frame'], name=meta.get('name', code), wreck=f'{code}_wreck.glb', source='tools/blender/a4 (A4 kit rollout)')
    root = G.node({'name': code, 'mesh': mesh, 'children': kids, 'extras': extras})
    G.save(os.path.join(d, f'{code}.glb'), [root], extras=extras)
    # wreck
    W = dict(np.load(os.path.join(base, f'{code}_wreck.npz'))); G2 = gio.GLB(); mat2 = materials(G2, code, files)
    inner = G2.material({'name': 'wreck_interior', 'pbrMetallicRoughness': {'baseColorFactor': [.045, .035, .03, 1], 'metallicFactor': .3, 'roughnessFactor': .9},
                         'emissiveFactor': [.55, .16, .04], 'extensions': {'KHR_materials_emissive_strength': {'emissiveStrength': 1.0}}})
    chunks = []
    for c in meta['wreck']:
        i = c['i']; pre = f'c{i}_body_'
        if pre + 'pos' not in W: continue
        prims = [dict(pos=W[pre + 'pos'], nor=unit(W[pre + 'nor']), idx=W[pre + 'idx'], uv=W.get(pre + 'uv'), tan=fix_tangents(unit(W[pre + 'nor']), W[pre + 'tan']) if (tangents and pre + 'tan' in W) else None, mat=mat2)]
        if f'c{i}_cap_pos' in W: prims.append(dict(pos=W[f'c{i}_cap_pos'], nor=unit(W[f'c{i}_cap_nor']), idx=W[f'c{i}_cap_idx'], mat=inner))
        mi = G2.mesh(f'{code}_chunk{len(chunks):02d}', prims)
        chunks.append(G2.node({'name': f'chunk_{len(chunks):02d}', 'mesh': mi, 'translation': [round(float(v), 6) for v in c['centre']], 'extras': dict(volume=c['volume'], tris=c['tris'])}))
    wroot = G2.node({'name': f'{code}_wreck', 'children': chunks, 'extras': dict(code=code, chunks=len(chunks), note='each chunk origin is its centre of mass; caps use wreck_interior')})
    G2.save(os.path.join(d, f'{code}_wreck.glb'), [wroot], extras=dict(code=code))
    c1 = gio.check(os.path.join(d, f'{code}.glb')); c2 = gio.check(os.path.join(d, f'{code}_wreck.glb'))
    print('packed', code, 'ship', c1['mb'], 'MB', c1['tris'], 'tris', c1['hardpoints'], 'hard points', 'problems', c1['problems'] or 'none', flush=True)
    print('packed', code, 'wreck', c2['mb'], 'MB', c2['tris'], 'tris', len(chunks), 'chunks', 'problems', c2['problems'] or 'none', flush=True)
    tex_mb = round(sum(os.path.getsize(os.path.join(d, f)) for f in files.values()) / 1e6, 2)
    # fleet manifest
    mpath = os.path.join(gdir, 'ships.json'); man = json.load(open(mpath)) if os.path.exists(mpath) else {}
    hp = {}
    for h in meta['hardpoints']: hp[h['extras']['kind']] = hp.get(h['extras']['kind'], 0) + 1
    man[code] = dict(name=meta.get('name', code), faction=meta['faction'], cls=meta['cls'], band=meta['band'], length_world=meta['length_world'],
                     ship=f'{code}/{code}.glb', wreck=f'{code}/{code}_wreck.glb', tris=c1['tris'], wreck_chunks=len(chunks), hardpoints=hp, textures=res, texture_mb=tex_mb)
    json.dump(dict(sorted(man.items())), open(mpath, 'w'), indent=1)
    return c1, c2


if __name__ == '__main__':
    a = sys.argv[1:]
    res = int(a[a.index('--res') + 1]) if '--res' in a else 2048
    c1, c2 = pack(a[0], a[1], res)
    if '--hi' in a:
        hres = int(a[a.index('--hires') + 1]) if '--hires' in a else 4096
        pack(a[0], a[a.index('--hi') + 1], hres, tangents=True)
