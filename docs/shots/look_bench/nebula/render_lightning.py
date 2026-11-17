"""Refs #368 run 5: compose real, stamped game captures without retouching."""
import argparse
import json
from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / 'tools'))
from picture_provenance import Review


def font(size):
    return ImageFont.truetype('C:/Windows/Fonts/arial.ttf', size)


def panel(sheet, image, x, label, box):
    draw = ImageDraw.Draw(sheet)
    draw.text((x + 10, 52), label, font=font(20), fill='white')
    sheet.paste(image.resize((426, 240), Image.Resampling.LANCZOS), (x, 85))
    # Native pixels, with the ship and raised storm cloud both in view.
    sheet.paste(image.crop(box), (x, 348))
    draw.text((x + 10, 326), 'Native 1080p pixels', font=font(17), fill='#b8b8c0')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', required=True, type=Path)
    parser.add_argument('--deliver', type=Path, default=Path(__file__).parent)
    args = parser.parse_args()
    before, after = [args.source / name for name in ['before_keep', 'after_keep']]
    args.deliver.mkdir(parents=True, exist_ok=True)
    for radius in [170, 60]:
        review = Review('installed in game')
        images = [review.open(path) for path in [before / f'storm_c{radius}_peak.png',
                  after / f'storm_c{radius}_peak.png', after / f'neb_c{radius}_peak.png']]
        sheet = Image.new('RGB', (1280, 720), '#0b0d12')
        draw = ImageDraw.Draw(sheet)
        name = f'N368A_R5_lightning_c{radius}'
        draw.text((14, 12), f'{name} | installed in game | Ryan approval pending', font=font(24), fill='white')
        boxes = [(747, 215, 1173, 555)] * 3 if radius == 170 else [
            (747, 120, 1173, 460), (1120, 170, 1546, 510), (747, 360, 1173, 700)]
        for x, image, label, box in zip([0, 426, 852], images, ['Run 4 storm', 'Run 5 storm', 'Nebula unchanged; storm beyond'], boxes):
            panel(sheet, image, x, label, box)
        review.save(sheet, args.deliver / (name + '.jpg'), quality=94)
    if all((args.source / name).exists() for name in ['high_keep', 'low_keep']):
        review = Review('installed in game')
        sheet = Image.new('RGB', (1280, 720), '#0b0d12')
        draw = ImageDraw.Draw(sheet)
        name = 'N368A_R5_quality_tiers'
        draw.text((14, 12), f'{name} | same real board | all three Graphics settings', font=font(24), fill='white')
        for row, radius in enumerate([170, 60]):
            for col, (folder, label) in enumerate([('after_keep', 'Max: fog'), ('high_keep', 'High: cards'), ('low_keep', 'Low: cards')]):
                image = review.open(args.source / folder / f'storm_c{radius}_peak.png')
                x, y = col * 426, 58 + row * 265
                draw.text((x + 10, y), f'{label} | camera {radius}', font=font(20), fill='white')
                sheet.paste(image.resize((426, 240), Image.Resampling.LANCZOS), (x, y + 25))
        review.save(sheet, args.deliver / (name + '.jpg'), quality=94)
    for radius in [170, 60]:
        review = Review('installed in game')
        sheet = Image.new('RGB', (1280, 720), '#0b0d12')
        draw = ImageDraw.Draw(sheet)
        name = f'N368A_R5_strike_c{radius}'
        draw.text((14, 12), f'{name} | six frames through one production storm burst', font=font(24), fill='white')
        samples = json.loads((after / 'lightning_metadata.json').read_text())['samples']
        first_strike = min(row['time'] - bolt['age'] for row in samples for bolt in row['bolts'] if -1 < bolt['age'] < 2)
        for index, sample in enumerate(samples):
            image = review.open(after / f'storm_c{radius}_strike_{index:02d}.png')
            x, y = (index % 3) * 426, 65 + (index // 3) * 310
            # The same crop for every frame; no enlargement, sharpening or recolouring.
            box = (747, 245, 1173, 525) if radius == 170 else (1120, 170, 1546, 450)
            sheet.paste(image.crop(box), (x, y + 25))
            draw.text((x + 10, y), f'{sample["time"] - first_strike:+.2f} s from first strike', font=font(20), fill='white')
        review.save(sheet, args.deliver / (name + '.jpg'), quality=94)
    # Pixel measurements read the original pixels recovered from provenance.
    import numpy as np
    rows = []
    for radius in [170, 60]:
        review = Review('installed in game')
        a = np.asarray(review.open(before / f'neb_c{radius}_peak.png').convert('RGB')).astype(float)
        b = np.asarray(review.open(after / f'neb_c{radius}_peak.png').convert('RGB')).astype(float)
        rows.append({'camera': radius, 'nebula_mean_abs_rgb_delta_255': float(np.abs(a-b).mean()),
                     'nebula_p99_abs_rgb_delta_255': float(np.percentile(np.abs(a-b), 99))})
    (args.deliver / 'lightning_pixels.json').write_text(json.dumps(rows, indent=2) + '\n')


if __name__ == '__main__':
    main()
