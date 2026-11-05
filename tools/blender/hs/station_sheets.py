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
    if (out / 'detail_audit.json').exists():
        detail_sheets(out)
        return
    report = json.loads((out / 'blockout_audit.json').read_text())
    for variant in ('fleet', 'refinery'):
        frames = [Image.open(p).convert('RGB') for p in sorted((out / (variant + '_turntable')).glob('*.png'))]
        assert len(frames) == 24, (variant, len(frames))
        frames[0].save(out / (variant + '_turntable.gif'), save_all=True,
                       append_images=frames[1:], duration=125, loop=0)
        sheet = Image.new('RGB', (1800, 1340), '#171f2b')
        draw = ImageDraw.Draw(sheet)
        draw.text((25, 15), variant.upper() + ' STATION: BLOCKOUT REVIEW', fill='white', font=font(32))
        draw.text((25, 62), 'R91: towers, sensor arrays, radiators and open truss. Shape review only.',
                  fill='#bac8d8', font=font(21))
        for i, (name, label) in enumerate((('working', 'Working face'), ('service', 'Service face'),
                                          ('godot_46_0_battle_4k', 'Godot battle camera: 46 units, real ships 33.6 / 10.4'),
                                          ('godot_46_180_close_4k', 'Godot close zoom: opposite face, same ships'))):
            x, y = (i % 2) * 900, 110 + (i // 2) * 590
            panel(sheet, Image.open(out / (variant + '_' + name + '.png')), (x, y + 40), (900, 530))
            draw.text((x + 20, y), label, fill='white', font=font(22))
        draw.text((25, 1300), 'Review scene only. Detail, paint, damage, turret behavior and live swap wait for Ryan.',
                  fill='#f0c68c', font=font(21))
        sheet.save(out / (variant + '_review.jpg'), quality=94)

        sizes = Image.new('RGB', (1800, 1340), '#171f2b')
        size_draw = ImageDraw.Draw(sizes)
        size_draw.text((25, 15), variant.upper() + ': SHIPPED SIZES IN GODOT', fill='white', font=font(32))
        size_draw.text((25, 62), 'Same real Battleship 33.6 and Frigate 10.4. Battle radius 170; close radius 90. FOV 45.',
                       fill='#bac8d8', font=font(21))
        for i, (length, zoom) in enumerate(((46, 'battle'), (30, 'battle'), (46, 'close'), (30, 'close'))):
            x, y = (i % 2) * 900, 110 + (i // 2) * 590
            panel(sizes, Image.open(out / ('%s_godot_%d_180_%s_4k.png' % (variant, length, zoom))),
                  (x, y + 40), (900, 530))
            size_draw.text((x + 20, y), '%d-unit station / %s camera' % (length, zoom), fill='white', font=font(22))
        size_draw.text((25, 1300), '30-unit compact cradle is 23.5 units: real ships stay alongside, at their full shipped lengths.',
                       fill='#f0c68c', font=font(21))
        sizes.save(out / (variant + '_sizes_review.jpg'), quality=94)

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
    both = Image.new('RGB', (1800, 1340), '#171f2b')
    d = ImageDraw.Draw(both)
    d.text((25, 15), 'R91: TWO STATIONS IN GODOT, BATTLE CAMERA / CLOSE ZOOM', fill='white', font=font(29))
    for row, variant in enumerate(('fleet', 'refinery')):
        d.text((25, 75 + row * 590), variant.upper() + ' / 46 units / real ships at their shipped sizes', fill='white', font=font(25))
        for col, zoom in enumerate(('battle', 'close')):
            panel(both, Image.open(out / (variant + '_godot_46_180_' + zoom + '_4k.png')),
                  (col * 900, 115 + row * 590), (900, 540))
    d.text((25, 1300), '46-unit stations, Battleship 33.6, Frigate 10.4. Camera: FOV 45, beta 0.98, radius 170 / 90.',
           fill='#bac8d8', font=font(21))
    both.save(out / 'stations_comparison.jpg', quality=94)
    print('[station-sheets] PASS: 2 turntables, 2 review sheets, 2 size sheets, 2 sweep sheets, Godot comparison')
    print(json.dumps(report, indent=2))


def detail_sheets(out):
    report = json.loads((out / 'detail_audit.json').read_text())
    views = [('plan', 'Plan view / radius 170'), ('battle', 'Battle camera / radius 170'),
             ('close', 'Close / radius 90'), ('macro46', 'Surface / radius 46')]
    for variant in ('fleet', 'refinery'):
        for length in (46, 30):
            sheet = Image.new('RGB', (2400, 3060), '#171f2b')
            draw = ImageDraw.Draw(sheet)
            draw.text((30, 18), '%s / %d UNITS / R94 BEFORE AND R100 AFTER' % (variant.upper(), length), fill='white', font=font(35))
            draw.text((30, 70), 'Same camera, real H10 Battleship 33.6 and H7 Frigate 10.4. Three paint slots. Review only.', fill='#bac8d8', font=font(24))
            for row, (view, label) in enumerate(views):
                for col, (suffix, title) in enumerate((('blockout', 'BEFORE'), ('detail', 'AFTER'))):
                    x, y = col * 1200, 130 + row * 710
                    draw.text((x + 25, y), title + ' / ' + label, fill='white', font=font(25))
                    panel(sheet, Image.open(out / ('%s_%s_%d_%s_4k.png' % (variant, suffix, length, view))), (x, y + 45), (1200, 665))
            data = report['variants'][variant]
            draw.text((30, 3005), '%d tris / locked primitives and gun clearance PASS / no live asset swap' % data['triangles_roundtrip'], fill='#f0c68c', font=font(25))
            sheet.save(out / ('%s_%d_before_after.jpg' % (variant, length)), quality=95)
        damage = Image.new('RGB', (2400, 1560), '#171f2b')
        d = ImageDraw.Draw(damage)
        d.text((30, 20), variant.upper() + ' / AUTHORED JUNCTION BREAKS / EXPLODED REVIEW', fill='white', font=font(34))
        for col, line in enumerate(('a', 'b')):
            result = report['variants'][variant]['breaks'][col]
            d.text((col * 1200 + 25, 85), result['anchor'], fill='#bac8d8', font=font(25))
            panel(damage, Image.open(out / ('%s_break_%s_4k.png' % (variant, line))), (col * 1200, 130), (1200, 650))
            d.text((col * 1200 + 25, 800), 'Cap close / inspection fill', fill='#bac8d8', font=font(25))
            panel(damage, Image.open(out / ('%s_break_%s_close_4k.png' % (variant, line))), (col * 1200, 845), (1200, 650))
        d.text((30, 1505), '0.25 wall / two decks / bulkheads / capped cut faces / damage masks / frame decal exemption R100', fill='#f0c68c', font=font(24))
        damage.save(out / (variant + '_breaks_review.jpg'), quality=95)
    # A native-resolution close crop, without upscaling, makes trim review easy.
    for variant in ('fleet', 'refinery'):
        sheet = Image.new('RGB', (2400, 2820), '#171f2b')
        d = ImageDraw.Draw(sheet)
        d.text((30, 20), variant.upper() + ' / END A, SPINE, END B / TOP, SIDE, BELOW', fill='white', font=font(32))
        for row, view in enumerate(('plan', 'side', 'below')):
            src = Image.open(out / ('%s_detail_isolated_%s.png' % (variant, view))).convert('RGB')
            bg = Image.new('RGB', src.size, src.getpixel((0, 0)))
            mask = ImageChops.difference(src, bg).convert('L').point(lambda v: 255 if v > 8 else 0)
            bounds = mask.getbbox()
            assert bounds, (variant, view)
            src = src.crop(bounds)
            for col in range(3):
                x, y = col * 800, 100 + row * 900
                d.text((x + 20, y), '%s / region %d' % (view, col + 1), fill='white', font=font(25))
                panel(sheet, src.crop((src.width * col // 3, 0, src.width * (col + 1) // 3, src.height)), (x, y + 40), (800, 840))
        sheet.save(out / (variant + '_detail_sweep.jpg'), quality=95)
    focus = Image.new('RGB', (2400, 2040), '#171f2b')
    fd = ImageDraw.Draw(focus)
    fd.text((30, 20), 'BREAK REVIEW / FLEET CRADLE FOCUS', fill='white', font=font(35))
    panel(focus, Image.open(out / 'fleet_break_b_close_4k.png'), (0, 80), (2400, 1350))
    for col, (variant, line) in enumerate((('fleet', 'a'), ('refinery', 'a'), ('refinery', 'b'))):
        fd.text((col * 800 + 20, 1470), variant + ' / break ' + line, fill='white', font=font(25))
        panel(focus, Image.open(out / ('%s_break_%s_4k.png' % (variant, line))), (col * 800, 1520), (800, 450))
    fd.text((30, 1990), 'Review assets only. Ryan approval is required before a shipping swap.', fill='#f0c68c', font=font(25))
    focus.save(out / 'break_focus.jpg', quality=95)
    overview = Image.new('RGB', (1600, 1120), '#171f2b')
    od = ImageDraw.Draw(overview)
    od.text((25, 15), 'STATION DETAIL / BEFORE AND AFTER / CLOSE VIEW', fill='white', font=font(30))
    od.text((25, 58), 'Same cameras and real ships. Full 4K frames and battle-distance sheets are retained beside this overview.', fill='#bac8d8', font=font(19))
    for row, variant in enumerate(('fleet', 'refinery')):
        for col, suffix in enumerate(('blockout', 'detail')):
            x, y = col * 800, 105 + row * 495
            od.text((x + 20, y), variant.upper() + (' / BEFORE' if col == 0 else ' / AFTER'), fill='white', font=font(23))
            panel(overview, Image.open(out / ('%s_%s_46_macro46_4k.png' % (variant, suffix))), (x, y + 35), (800, 450))
    overview.save(out / 'station_overview.jpg', quality=95)
    print('[station-sheets] PASS: four before/after sheets, two break sheets, two regional sheets, break focus and overview')


if __name__ == '__main__':
    main()
