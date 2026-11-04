"""Make issue 61 review sheets and GIFs from station_kit.py renders. Needs Pillow."""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont


def font(size):
    return ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', size)


def panel(canvas, image, xy, size):
    tile = image.convert('RGB')
    tile.thumbnail(size, Image.Resampling.LANCZOS)
    canvas.paste(tile, (xy[0] + (size[0] - tile.width) // 2,
                        xy[1] + (size[1] - tile.height) // 2))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('out', type=Path)
    out = parser.parse_args().out
    report = json.loads((out / 'blockout_audit.json').read_text())
    for variant in ('fleet', 'refinery'):
        frames = [Image.open(p).convert('RGB') for p in sorted((out / (variant + '_turntable')).glob('*.png'))]
        assert len(frames) == 24, (variant, len(frames))
        frames[0].save(out / (variant + '_turntable.gif'), save_all=True,
                       append_images=frames[1:], duration=125, loop=0)
        sheet = Image.new('RGB', (1800, 1340), '#171f2b')
        draw = ImageDraw.Draw(sheet)
        draw.text((25, 15), variant.upper() + ' STATION: BLOCKOUT REVIEW', fill='white', font=font(32))
        draw.text((25, 62), 'Shared 46-unit spine. Shape review only. Detail and live swap await owner approval.',
                  fill='#bac8d8', font=font(21))
        for i, (name, label) in enumerate((('working', 'Working face'), ('service', 'Service face'),
                                          ('ships_4k', '46 units, real Battleship 33.6 and Frigate 10.4'),
                                          ('compact_ships_4k', '30-unit compact, same ships and camera'))):
            x, y = (i % 2) * 900, 110 + (i // 2) * 590
            panel(sheet, Image.open(out / (variant + '_' + name + '.png')), (x, y + 40), (900, 530))
            draw.text((x + 20, y), label, fill='white', font=font(22))
        draw.text((25, 1300), 'Compact cradle is 23.5 units: the 33.6-unit Battleship overhang is intentional and visible.',
                  fill='#f0c68c', font=font(21))
        sheet.save(out / (variant + '_review.jpg'), quality=94)

        sweep = Image.new('RGB', (1560, 1170), '#171f2b')
        sd = ImageDraw.Draw(sweep)
        sd.text((20, 10), variant.upper() + ': END A / SPINE / END B, TOP / SIDE / BELOW', fill='white', font=font(26))
        for row, view in enumerate(('top', 'side', 'below')):
            src = Image.open(out / (variant + '_' + view + '.png')).convert('RGB')
            bg = Image.new('RGB', src.size, src.getpixel((0, 0)))
            mask = ImageChops.difference(src, bg).convert('L').point(lambda v: 255 if v > 12 else 0)
            bounds = mask.getbbox()
            assert bounds, (variant, view)
            src = src.crop(bounds)
            for col, region in enumerate(('end A', 'spine', 'end B')):
                piece = src.crop((src.width * col // 3, 0, src.width * (col + 1) // 3, src.height))
                x, y = col * 520, 65 + row * 360
                sd.text((x + 15, y), view + ' / ' + region, fill='white', font=font(22))
                panel(sweep, piece, (x + 5, y + 40), (510, 305))
        sweep.save(out / (variant + '_sweep.jpg'), quality=94)
    both = Image.new('RGB', (1800, 1280), '#171f2b')
    d = ImageDraw.Draw(both)
    d.text((25, 15), 'ONE KIT, TWO STATIONS: BLOCKOUT TURNTABLE REVIEW', fill='white', font=font(32))
    for row, variant in enumerate(('fleet', 'refinery')):
        d.text((25, 75 + row * 590), variant.upper() + ' / 46 units / real ships at their shipped sizes', fill='white', font=font(25))
        panel(both, Image.open(out / (variant + '_ships_4k.png')), (0, 115 + row * 590), (1800, 540))
    both.save(out / 'stations_comparison.jpg', quality=94)
    print('[station-sheets] PASS: 2 turntables, 2 review sheets, 2 sweep sheets, comparison')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
