"""Issue 982: compare stamped, fixed-pose native 4K captures without colour edits."""
import argparse
import json
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageChops, ImageStat

p = argparse.ArgumentParser()
p.add_argument('--repo', type=Path, required=True)
p.add_argument('--shots', type=Path, required=True)
a = p.parse_args()
sys.path.insert(0, str(a.repo / 'tools'))
from picture_provenance import Review

font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 20)
small = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 16)
differences = []
for radius in [170, 60]:
    for state in ['calm', 'bolt']:
        review = Review('installed in game')
        sheet = Image.new('RGB', (1280, 720), '#10151e')
        draw = ImageDraw.Draw(sheet)
        originals = []
        for col, run in enumerate(['before', 'after']):
            image = review.open(a.shots / run / f'storm_max_c{radius}_{state}.jpg')
            originals.append(image)
            x = col * 640
            draw.text((x + 10, 5), f'STORM982 | {run} | max c{radius} | {state}', font=font, fill='#f1e8d9')
            sheet.paste(image.resize((640, 360), Image.Resampling.LANCZOS), (x, 36))
            # Same pixels in each column, at native size, to expose detail changes.
            crop = (1600, 850, 2240, 1010)
            if state == 'bolt':
                crop = (1400, 700, 2040, 860) if radius == 170 else (900, 100, 1540, 260)
            sheet.paste(image.crop(crop), (x, 428))
            draw.text((x + 10, 402), 'Native 4K bolt detail' if state == 'bolt' else 'Native 4K cloud detail', font=small, fill='#dcc7a8')
        diff = ImageChops.difference(*originals)
        # Exclude only the provenance strip, whose revisions necessarily differ.
        region = diff.crop((0, 0, 3840, 1950))
        differences.append({'camera': radius, 'state': state, 'mean_absolute_rgb_255': ImageStat.Stat(region).mean})
        review.save(sheet, a.shots / f'STORM982_c{radius}_{state}.jpg', quality=95)
for radius in [170, 60]:
    review = Review('installed in game')
    sheet = Image.new('RGB', (1280, 720), '#10151e')
    draw = ImageDraw.Draw(sheet)
    for col, tier in enumerate(['max', 'low']):
        image = review.open(a.shots / 'after' / f'storm_{tier}_c{radius}_bolt.jpg')
        x = col * 640
        draw.text((x + 10, 5), f'STORM982 | {tier} c{radius} | bolt', font=font, fill='#f1e8d9')
        sheet.paste(image.resize((640, 360), Image.Resampling.LANCZOS), (x, 36))
        sheet.paste(image.crop((1600, 850, 2240, 1010)), (x, 428))
        draw.text((x + 10, 402), 'Native 4K detail of this view', font=small, fill='#dcc7a8')
    review.save(sheet, a.shots / f'STORM982_c{radius}_quality.jpg', quality=95)
(a.shots / 'image_difference.json').write_text(json.dumps(differences, indent=2) + '\n')
