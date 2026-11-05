"""Native-pixel R105 blur sheets, geometry equality and paint measurements.

Run with the PC's installed ComfyUI Python (Pillow, NumPy), after the review
captures. No beauty image is brightened, sharpened, or recoloured here.
"""
import argparse
import ast
import hashlib
import json
import struct
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

LUMA = np.array([.2126, .7152, .0722])
BG = '#171f2b'


def font(size):
    return ImageFont.truetype('C:/Windows/Fonts/arial.ttf', size)


def label(im, xy, text, size=21, color='#c3ceda'):
    ImageDraw.Draw(im).text(xy, text, font=font(size), fill=color)


def glb_geometry(path):
    raw = path.read_bytes()
    length = struct.unpack_from('<I', raw, 12)[0]
    doc = json.loads(raw[20:20 + length])
    binary = raw[28 + length:]

    def digest(index):
        a = doc['accessors'][index]
        view = doc['bufferViews'][a['bufferView']]
        width = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}[a['componentType']]
        width *= {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[a['type']]
        start = view.get('byteOffset', 0) + a.get('byteOffset', 0)
        stride = view.get('byteStride', width)
        content = b''.join(binary[start + i * stride:start + i * stride + width] for i in range(a['count']))
        return [a['count'], a['componentType'], a['type'], hashlib.sha256(content).hexdigest()]

    meshes = []
    triangles = 0
    for mesh in doc['meshes']:
        primitives = []
        for p in mesh['primitives']:
            attrs = {k: digest(v) for k, v in p['attributes'].items()}
            attrs['indices'] = digest(p['indices'])
            attrs['material'] = p.get('material')
            triangles += doc['accessors'][p['indices']]['count'] // 3
            primitives.append(attrs)
        meshes.append(primitives)
    # Preserve transforms, names, mesh ownership and the four battery nodes.
    return {'nodes': doc['nodes'], 'meshes': meshes, 'triangles': triangles,
            'materials': len(doc['materials']), 'textures': len(doc.get('textures', [])),
            'images': len(doc.get('images', []))}


def grey(im):
    return Image.fromarray(np.clip(np.asarray(im.convert('RGB')) @ LUMA, 0, 255).round().astype('uint8'))


def frame(out, variant, suffix, length, shot, height=1080):
    return out / f'{variant}_{suffix}_{length}_{shot}_{height}p.png'


def mask_bounds(path, padding):
    mask = Image.open(path).convert('L').point(lambda v: 255 if v > 127 else 0)
    x0, y0, x1, y1 = mask.getbbox()
    return (max(0, x0 - padding), max(0, y0 - padding), min(mask.width, x1 + padding), min(mask.height, y1 + padding))


def metrics(out, variant, suffix, length, height):
    path = frame(out, variant, suffix, length, 'battle', height)
    rgb = np.asarray(Image.open(path.with_stem(path.stem + '_isolated')).convert('RGB')).astype(float)
    mask = np.asarray(Image.open(path.with_stem(path.stem + '_mask')).convert('L')) > 127
    values = rgb[mask]
    luma = values @ LUMA
    r, g, b = values.T
    gold = (r > b * 1.15) & (g > b * 1.1) & (luma > 70)
    mint = (g > r * 1.1) & (g > b * 1.06) & (luma > 90)
    # Same sRGB nearest-anchor method as round 5, with station metal instead of
    # Hullbreaker rust/red anchors. Gold and mint gates reject neutral lighting.
    anchors = np.array([[48, 62, 73], [96, 114, 127], [148, 163, 172]])
    classes = ((values[:, None] - anchors) ** 2).sum(axis=2).argmin(axis=1)
    return {'variant': variant, 'paint': suffix, 'length': length, 'height': height,
            'station_pixels': int(mask.sum()), 'median_srgb_luma': round(float(np.median(luma)), 3),
            'luma_p10_p90': np.percentile(luma, [10, 90]).round(3).tolist(),
            'nearest_metal_tone_percent': [round(float((classes == k).mean() * 100), 3) for k in range(3)],
            'dark_under_96_percent': round(float((luma < 96).mean() * 100), 3),
            'gold_trim_percent': round(float(gold.mean() * 100), 3),
            'mint_light_proxy_percent': round(float(mint.mean() * 100), 3),
            'neutral_over_180_percent': round(float(((luma > 180) & ~gold & ~mint).mean() * 100), 3),
            'S10': 'PENDING: no approved dark-metal station art reference. R104 rejects the old white station mass.'}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    out = args.out
    report = {'geometry': {}, 'measurements': [],
              'blur': {'luma': 'Rec.709 on 8-bit sRGB', '1080p_radius': 7.5, '2160p_radius': 15,
                       'scale': '1:1 pixels; no resizing in blur sheets', 'approval': 'Ryan review pending'},
              'S10': 'Pending an approved dark station reference, not a numeric pass.'}
    for variant in ('fleet', 'refinery'):
        before = glb_geometry(out / (variant + '_before.glb'))
        after = glb_geometry(out / (variant + '_detail.glb'))
        assert before == after, f'Geometry, transforms, UVs, material or image counts changed: {variant}'
        report['geometry'][variant] = {'result': 'PASS: exact exported positions, indices, normals, UVs and nodes',
                                      'triangles': after['triangles'], 'materials': after['materials'],
                                      'textures': after['textures'], 'images': after['images']}
        for length in (46, 30):
            for height, radius in ((1080, 7.5), (2160, 15)):
                path = frame(out, variant, 'detail', length, 'battle', height)
                bounds = mask_bounds(path.with_stem(path.stem + '_mask'), round(radius * 4))
                width, cell = bounds[2] - bounds[0], bounds[3] - bounds[1]
                sheet = Image.new('RGB', (max(1100, width * 2 + 80), 255 + (cell + 50) * 3), BG)
                label(sheet, (25, 18), f'{variant.upper()} / LENGTH {length} / NATIVE {height}p / r=170', 28, 'white')
                label(sheet, (25, 60), f'1:1 pixels. Rec.709 greyscale. Gaussian radius {radius}px. Same construction and camera.')
                label(sheet, (25, 95), 'BEFORE: approved detail shapes, rejected paint', 19)
                right = sheet.width // 2 + 15
                label(sheet, (right, 95), 'AFTER: metal repaint, Ryan review pending', 19)
                for col, suffix in enumerate(('before', 'detail')):
                    source = frame(out, variant, suffix, length, 'battle', height)
                    color = Image.open(source.with_stem(source.stem + '_isolated')).convert('RGB')
                    mono = grey(color)
                    blur = mono.filter(ImageFilter.GaussianBlur(radius))
                    blur.save(out / f'{variant}_{suffix}_{length}_blur_{height}p.png')
                    for row, (image, text) in enumerate(((color, 'Colour'), (mono, 'Greyscale'), (blur, 'Blurred greyscale'))):
                        x, y = col * (sheet.width // 2) + 20, 145 + row * (cell + 50)
                        label(sheet, (x, y), text, 19)
                        sheet.paste(image.crop(bounds), (x + (sheet.width // 2 - 40 - width) // 2, y + 30))
                    report['measurements'].append(metrics(out, variant, suffix, length, height))
                label(sheet, (25, sheet.height - 54), 'Structure review: large masses, calm open faces, accents kept small. S10 reference still pending.', 19)
                sheet.save(out / f'{variant}_{length}_blur_{height}p.png')
            # Real ships remain in these shots. The battle row stays at native
            # 1080p pixels; larger close captures are fitted without upscaling.
            sheet = Image.new('RGB', (2000, 2010), BG)
            label(sheet, (25, 15), f'{variant.upper()} / LENGTH {length} / SAME SHAPES, NEW METAL', 32, 'white')
            label(sheet, (25, 60), 'Real H10 Battleship 33.6 and H7 Frigate 10.4. Battle lights. Review assets only.')
            for row, shot in enumerate(('battle', 'close', 'service', 'below')):
                for col, suffix in enumerate(('before', 'detail')):
                    path = frame(out, variant, suffix, length, shot, 1080 if shot == 'battle' else 2160)
                    image = Image.open(path).convert('RGB')
                    nonblack = image.convert('L').point(lambda v: 255 if v > 10 else 0).getbbox()
                    image = image.crop(nonblack)
                    image.thumbnail((960, 410), Image.Resampling.LANCZOS)
                    x, y = col * 1000 + 20, row * 465 + 110
                    label(sheet, (x, y), ('BEFORE' if col == 0 else 'AFTER') + f' / {shot} / r={170 if shot == "battle" else 90}', 23)
                    sheet.paste(image, (x + (960 - image.width) // 2, y + 35 + (410 - image.height) // 2))
            sheet.save(out / f'{variant}_{length}_paint_review.jpg', quality=96)
    overview = Image.new('RGB', (1600, 1130), BG)
    label(overview, (25, 15), 'STATION REPAINT / SAME DETAIL SHAPES / CLOSE VIEW', 30, 'white')
    label(overview, (25, 58), 'Dark steel, three broad coats, sparse faction accents. No shipping swap. Ryan review pending.', 21)
    for row, variant in enumerate(('fleet', 'refinery')):
        for col, suffix in enumerate(('before', 'detail')):
            image = Image.open(frame(out, variant, suffix, 46, 'macro46', 2160)).convert('RGB')
            image.thumbnail((800, 450), Image.Resampling.LANCZOS)
            x, y = col * 800, 105 + row * 495
            label(overview, (x + 20, y), variant.upper() + (' / BEFORE' if col == 0 else ' / AFTER'), 23, 'white')
            overview.paste(image, (x, y + 35))
    overview.save(out / 'station_paint_overview.jpg', quality=96)
    # The original builders and all their audit asserts must match HEAD.
    source = Path(__file__).with_name('station_kit.py')
    old = subprocess.check_output(['git', 'show', 'HEAD:tools/blender/hs/station_kit.py'], text=True)
    def functions(text):
        return {n.name: ast.dump(n) for n in ast.parse(text).body if isinstance(n, ast.FunctionDef)}
    old_funcs, new_funcs = functions(old), functions(source.read_text())
    names = list(old_funcs)[:list(old_funcs).index('process_pipe')]
    assert all(old_funcs[k] == new_funcs[k] for k in names), 'Original builder or audit changed'
    report['locked_builder_functions'] = {'result': 'PASS', 'names': names}
    coat_luma = np.array([[48, 62, 73], [96, 114, 127], [148, 163, 172]]) @ LUMA
    report['coat_srgb_luma'] = coat_luma.round(3).tolist()
    report['coat_luma_steps'] = np.diff(coat_luma).round(3).tolist()
    report['coat_steps_note'] = 'Albedo design values only; rendered local samples and blur sheets remain the test.'
    if (out / 'before_gpu.json').exists() and (out / 'detail_gpu.json').exists():
        old_gpu = json.loads((out / 'before_gpu.json').read_text())
        new_gpu = json.loads((out / 'detail_gpu.json').read_text())
        report['performance'] = []
        for old_row, new_row in zip(old_gpu['rows'], new_gpu['rows']):
            def wall(row):
                return float(np.median([p['frame_delta_ms'] for p in row['pairs']]))
            a, b = old_row['paired_range_ms'], new_row['paired_range_ms']
            report['performance'].append({
                'variant': old_row['variant'],
                'before_gpu_addition_ms': old_row['median_delta_ms'],
                'after_gpu_addition_ms': new_row['median_delta_ms'],
                'paint_change_gpu_ms': new_row['median_delta_ms'] - old_row['median_delta_ms'],
                'before_frame_addition_ms': wall(old_row), 'after_frame_addition_ms': wall(new_row),
                'before_gpu_range_ms': a, 'after_gpu_range_ms': b,
                'ranges_overlap': max(a[0], b[0]) <= min(a[1], b[1]),
                'note': 'Five alternating visible/hidden pairs per paint, 100 warm-up and 180 measured frames per state. Noise is not a speedup.'})
    (out / 'paint_validation.json').write_text(json.dumps(report, indent=2) + '\n')
    print('[station-paint-sheets] PASS: exact geometry, native blur sheets, real-ship comparisons and measurements')


if __name__ == '__main__':
    main()
