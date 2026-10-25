# A2 max-detail ships: pack the glTF binary from what the Blender step wrote (CODE_mesh.npz, CODE_meta.json and the baked PNG maps), and
# run the structural check. Needs numpy and PIL: on the PC this runs in ComfyUI's Python (Blender 4.5's bundled Python has no PIL).
#   python pack_glb.py OUT_DIR/CODE_meta.json [...]        also: python pack_glb.py --sheets CHECK_DIR CODE [...]   (contact sheets)
import sys, os, json
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path: sys.path.insert(0, HERE)
import numpy as np
import hullio


def pack(meta_path):
    m = json.load(open(meta_path)); d = np.load(meta_path.replace('_meta.json', '_mesh.npz')); mp = m['maps']
    imgs = dict(base=(mp['albedo'], 'jpg_hq'), orm=(mp['orm'], 'jpg_hq'), normal=(mp['normal'], 'png'), emissive=(mp['emit'], 'jpg_hq'))
    hullio.write_glb(m['glb'], m['name'], d['pos'], d['nor'], d['idx'], d['uv'], tangent=d['tan'], images=imgs,
                     mat=dict(metallicFactor=1.0, roughnessFactor=1.0, emissiveFactor=[1, 1, 1], occlusionStrength=1.0), extras=m.get('extras'))
    chk = hullio.check_glb(m['glb']); print('packed', m['glb'], chk['mb'], 'MB, tris', chk['tris'], 'images', chk['images'], 'problems', chk['problems'] or 'none', flush=True)
    rep = meta_path.replace('_meta.json', '_report.json')
    if os.path.exists(rep):
        r = json.load(open(rep)); r['glb_check'] = chk; r['glb_mb'] = chk['mb']; r['tris_after'] = chk['tris']; json.dump(r, open(rep, 'w'), indent=1)
    return chk


def sheets(chk_dir, code, title_extra=''):
    """contact sheets from the renders in CHECK_DIR/_r_CODE (views and 9-cell sweeps, clay and painted)"""
    import checks_sheet as S
    S.make_barge(chk_dir) if code == 'C19_51' else S.make(chk_dir, code)


if __name__ == '__main__':
    a = sys.argv[1:]
    if a and a[0] == '--sheets':
        for c in a[2:]: sheets(a[1], c)
    else:
        for p in a: pack(p)
