# A4: the fleet manifest for the repo (coordinator, Oct 26 2026): the full glb files stay on Ryan's PC (about 10 MB each, out of git until
# Ryan decides on large-file storage); the repo carries godot/assets/ships/manifest.json (code, files, sizes, sha256, hard points, breach
# count) and small preview images, so anyone can check the PC copy matches what was reviewed.
#   python manifest.py GODOT_DIR OUT_DIR DEST_DIR      (GODOT_DIR = voidsworn_test\a4\godot, OUT_DIR = voidsworn_test\a4\out)
# writes DEST_DIR/manifest.json and DEST_DIR/previews/<CODE>.jpg (studio views) and <CODE>_damage.jpg (breach review), about 100 KB each.
import sys, os, json, hashlib
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path: sys.path.insert(0, HERE)
import gio


def sha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''): h.update(b)
    return h.hexdigest()


def preview(src, dst, w=1100):
    from PIL import Image
    im = Image.open(src).convert('RGB'); im = im.resize((w, int(im.size[1] * w / im.size[0])), Image.LANCZOS); im.save(dst, quality=82)


def main(gdir, odir, dest):
    os.makedirs(os.path.join(dest, 'previews'), exist_ok=True); man = {}
    for code in sorted(os.listdir(gdir)):
        d = os.path.join(gdir, code)
        if not os.path.isdir(d) or not os.path.exists(os.path.join(d, f'{code}.glb')): continue
        files = {f: dict(bytes=os.path.getsize(os.path.join(d, f)), sha256=sha(os.path.join(d, f))) for f in sorted(os.listdir(d)) if not f.endswith('.import')}
        js, _ = gio.read_glb(os.path.join(d, f'{code}.glb')); names = [n.get('name', '') for n in js['nodes']]
        ex = next((n.get('extras', {}) for n in js['nodes'] if n.get('name') == code), {})
        hp = {}
        for n in js['nodes']:
            if n.get('name', '').startswith('hp_'):
                k = n.get('extras', {}).get('kind', '?'); hp[k] = hp.get(k, 0) + 1
        dmg = os.path.join(d, f'{code}_damage.glb'); nb = 0
        if os.path.exists(dmg):
            jd, _ = gio.read_glb(dmg); nb = len([n for n in jd['nodes'] if n.get('name', '').endswith('_hole')])
        man[code] = dict(name=ex.get('name', code), faction=ex.get('faction'), cls=ex.get('cls'), band=ex.get('band'), length_world=ex.get('length_world'),
                         hardpoints=hp, breaches=nb, skins=len([x for x in names if x.startswith('skin_')]), files=files,
                         pc_path=f'Downloads\\voidsworn_test\\build\\godot\\assets\\ships\\{code}\\')
        v = os.path.join(odir, code, 'checks', f'{code}_views.webp')
        if os.path.exists(v): preview(v, os.path.join(dest, 'previews', f'{code}.jpg')); man[code]['preview'] = f'previews/{code}.jpg'
        dv = os.path.join(odir, code, 'dmg', f'{code}_damage.png')
        if os.path.exists(dv): preview(dv, os.path.join(dest, 'previews', f'{code}_damage.jpg')); man[code]['damage_preview'] = f'previews/{code}_damage.jpg'
    json.dump(dict(note='A4 ships: the glb files and maps live on Ryan\'s PC (pc_path, copied there by every ship job) and stay out of git '
                        'until large-file storage is decided; sizes and sha256 here identify the reviewed build.', ships=man),
              open(os.path.join(dest, 'manifest.json'), 'w'), indent=1)
    print('manifest', len(man), 'ships ->', dest)


if __name__ == '__main__':
    main(*sys.argv[1:4])
