"""Compose genuine camera-170 cells at source pixel size, with measured timing."""
import argparse
import json
from pathlib import Path
import statistics
from PIL import Image, ImageDraw, ImageFont


def font(size):
    return ImageFont.truetype('C:/Windows/Fonts/arial.ttf', size)


def load(folder):
    report = json.loads((folder / 'bench.json').read_text())
    return {r['id']: r for r in report['stills']}


def cell(folder, row, time):
    index = min(range(len(row['cells'])), key=lambda i: abs(row['cells'][i]['t'] - time))
    with Image.open(folder / row['file']) as strip:
        width = strip.width // len(row['cells'])
        return strip.crop((index*width, 0, (index+1)*width, strip.height)), row['cells'][index]['t']


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--before', type=Path, required=True)
    p.add_argument('--after', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--before-strokes', type=Path)
    a = p.parse_args()
    a.out.mkdir(parents=True, exist_ok=True)
    before, after = load(a.before), load(a.after)
    if a.before_strokes:
        fixture = json.loads(a.before_strokes.read_text())
        hashes = json.loads((a.before / 'source_hashes.json').read_text())
        assert fixture['source_sha256'] == hashes.get('fx\\fx_weapons.gd', hashes.get('fx/fx_weapons.gd'))
        for row in before.values():
            row['strokes'] = fixture['strokes']
    measured = {}
    for name, records in [('before', before), ('after', after)]:
        values = records['t10_perf']['frame_ms']
        measured[name] = dict(frame_median_ms=statistics.median(values),
            frame_p95_ms=sorted(values)[int(len(values)*.95)], frame_max_ms=max(values),
            samples=len(values), fires=records['t10']['fires'], strokes=records['t10'].get('strokes', []))
    for row_id, label in [('t10', 'T10'), ('t10_calm', 'T10 CALM')]:
        sheet = Image.new('RGB', (1280, 720), '#101318')
        d = ImageDraw.Draw(sheet)
        d.text((16, 10), label + ' | crews firing in clumps and gaps', fill='#ff9a55', font=font(25))
        d.text((16, 43), 'Camera 170 | V16_37 Sunward cruiser broadside | seed 11 | source pixels, no enlargement', fill='#d7dce3', font=font(17))
        for folder, records, name, y in [(a.before, before, 'Before', 66), (a.after, after, 'After', 346)]:
            d.text((16, y), name, fill='#eeeeee', font=font(20))
            for col, time in enumerate([.2833, .5000, .7000]):
                image, at = cell(folder, records[row_id], time)
                # Only trim sky. Kept hulls and strokes retain their source pixels.
                image = image.crop((112, 65, 512, 285))
                x = 16 + col*416
                sheet.paste(image, (x, y+27))
                d.text((x+4, y+248), f'{at:.3f} s', fill='#bfc9d7', font=font(17))
        for name, row, y in [('Before', before[row_id], 640), ('After', after[row_id], 675)]:
            d.text((16, y-7), name, fill='#eeeeee', font=font(17))
            d.line((114, y+3, 1214, y+3), fill='#4a515d', width=2)
            for i, fire in enumerate(row['fires']):
                x = 114 + fire * 1100
                strokes = row.get('strokes', [])
                radius = max(3, float(strokes[i]['width_px']) * 1.4) if i < len(strokes) else 5.6
                d.ellipse((x-radius, y-radius, x+radius, y+radius), fill='#ffb477')
            d.text((1050, y-18), '1 s timeline', fill='#aeb8c7', font=font(16))
        b, c = measured['before'], measured['after']
        d.text((16, 695), f'No-readback frame median: {b["frame_median_ms"]:.3f} -> {c["frame_median_ms"]:.3f} ms | RTX 5080, 1080p Forward+ | 149 frames each', fill='#d7dce3', font=font(17))
        sheet.save(a.out / (row_id + '_strip.png'))
    frames = []
    for index in range(0, 84, 2):
        time = before['t10']['cells'][index]['t']
        frame = Image.new('RGB', (1280, 424), '#101318')
        draw = ImageDraw.Draw(frame)
        for x, folder, records, label in [(0, a.before, before, 'Before'), (640, a.after, after, 'After')]:
            image, at = cell(folder, records['t10'], time)
            frame.paste(image, (x, 30))
            draw.text((x+12, 5), f'T10 | {label} | camera 170 | {at:.3f} s', fill='#ffad71', font=font(18))
        draw.text((16, 397), 'Same seed, same hit results. Firing times and stroke weight vary inside the salvo.', fill='#d7dce3', font=font(18))
        frames.append(frame.convert('P', palette=Image.Palette.ADAPTIVE, colors=96))
    frames[0].save(a.out / 't10_motion.gif', save_all=True, append_images=frames[1:], duration=33, loop=0)
    (a.out / 'measurements.json').write_text(json.dumps(measured, indent=2))


if __name__ == '__main__':
    main()
