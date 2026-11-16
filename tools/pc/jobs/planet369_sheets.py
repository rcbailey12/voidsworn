"""Keep run 2 captures and make review sheets from real pixels. No AI images."""
import json
import os
from pathlib import Path
import shutil

from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
SHOTS = Path(os.environ['USERPROFILE']) / 'Downloads/voidsworn_test/board/issue-369/shots'
DEST = ROOT / 'docs/shots/look_bench/planets'
FONT = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 22)


def run():
    DEST.mkdir(parents=True, exist_ok=True)
    for mode in ['before', 'after']:
        for name in ['home_c170', 'c170', 'c60', 'c26', 'board_top', 'planet', 'cloud_motion']:
            source = SHOTS / mode / 'run2' / ('R01_' + name + '.png')
            with Image.open(source) as im:
                assert im.size == (1280, 720), source
            shutil.copyfile(source, DEST / ('R01_' + mode + '_' + name + '.png'))
    for name in ['c170', 'c60', 'c26']:
        sheet = Image.new('RGB', (1280, 720), '#101010')
        draw = ImageDraw.Draw(sheet)
        for i, mode in enumerate(['before', 'after']):
            im = Image.open(SHOTS / mode / 'run2' / ('R01_' + name + '.png')).convert('RGB')
            # Same centre region, no resizing. The full original is kept too.
            sheet.paste(im.crop((320, 40, 960, 680)), (i*640, 64))
            label = 'BEFORE' if mode == 'before' else 'R01 / 8K WebP'
            draw.text((16+i*640, 12), label + ' / ' + name + ' / 1:1 crop', font=FONT, fill='white')
        file = 'R01_compare_' + name + '.jpg'
        sheet.save(DEST / file, quality=95)
        shutil.copyfile(DEST / file, SHOTS / file)
    reference = Path(os.environ['TEMP']) / 'planet369_lossless_reference/R01_after_c26.png'
    if reference.exists():
        sheet = Image.new('RGB', (1280, 720), '#101010')
        draw = ImageDraw.Draw(sheet)
        for i, (source, label) in enumerate([
                (reference, 'R01 / prior lossless'),
                (SHOTS / 'after/run2/R01_c26.png', 'R01 / WebP, 11-bit height')]):
            im = Image.open(source).convert('RGB')
            sheet.paste(im.crop((320, 40, 960, 680)), (i*640, 64))
            draw.text((16+i*640, 12), label + ' / c26 / 1:1', font=FONT, fill='white')
        file = 'R01_pack_compare_c26.jpg'
        sheet.save(DEST / file, quality=95)
        shutil.copyfile(DEST / file, SHOTS / file)
    for source in (SHOTS / 'showcase').glob('R01_*.png'):
        with Image.open(source) as im:
            assert im.size == (1280, 720), source
        shutil.copyfile(source, DEST / source.name)
    shutil.copyfile(DEST / 'R01_sources.jpg', SHOTS / 'R01_sources.jpg')
    for mode in ['before', 'after']:
        for name in ['m1_map', 'm5_sector2']:
            im = Image.open(SHOTS / mode / 'sector' / (name + '.png')).convert('RGB')
            im.thumbnail((1280, 720), Image.Resampling.LANCZOS)
            draw = ImageDraw.Draw(im)
            draw.rectangle((0, 0, im.width, 34), fill='#101010')
            draw.text((12, 3), 'R01 context | sector map | ' + mode + ' | ' + name, font=FONT, fill='white')
            file = 'R01_sector_' + mode + '_' + name + '.jpg'
            im.save(DEST / file, quality=95)
            shutil.copyfile(DEST / file, SHOTS / file)
    checks = {}
    for name, pair in {'cloud_motion': ['planet', 'cloud_motion'],
                       'isolated_shadow': ['shadows_on', 'shadows_off']}.items():
        a, b = [Image.open(SHOTS / 'after/run2' / ('R01_' + p + '.png')).convert('RGB') for p in pair]
        # Exclude the caption. The shadow pair has a held cloud field and a
        # hidden cloud shell; the two files keep the same camera and lighting.
        diff = ImageChops.difference(a, b).crop((0, 64, 1280, 720))
        hist = diff.convert('L').histogram()
        changed = sum(hist[1:])
        checks[name] = {'changed_pixels_below_caption': changed,
                        'max_channel_difference': max(v[1] for v in diff.getextrema()),
                        'inputs': ['after/run2/R01_' + p + '.png' for p in pair]}
        assert changed > 0, name + ' has no visible effect'
    (SHOTS / 'R01_visual_checks.json').write_text(json.dumps(checks, indent=2)+'\n', encoding='ascii')
    for source, name in [
            ('before/run2/R01_metrics.json', 'R01_before_metrics.json'),
            ('after/run2/R01_metrics.json', 'R01_after_metrics.json'),
            ('before/gate/scene_gate.json', 'R01_before_gate.json'),
            ('after/gate/scene_gate.json', 'R01_after_gate.json'),
            ('showcase/R01_scale.json', 'R01_scale.json'),
            ('R01_visual_checks.json', 'R01_visual_checks.json')]:
        shutil.copyfile(SHOTS / source, DEST / name)
    print(json.dumps(checks, indent=2))
    print('R01 review images kept from run2 in', DEST)


if __name__ == '__main__':
    run()
